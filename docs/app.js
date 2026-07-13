'use strict';

const ROMAN = ['', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX'];
const IMG_SIZE = 300;

const TYPE_COLORS = {
  Normal: '#A8A878', Fighting: '#C03028', Flying: '#A890F0', Poison: '#A040A0',
  Ground: '#E0C068', Rock: '#B8A038', Bug: '#A8B820', Ghost: '#705898',
  Steel: '#B8B8D0', Fire: '#F08030', Water: '#6890F0', Grass: '#78C850',
  Electric: '#F8D030', Psychic: '#F85888', Ice: '#98D8D8', Dragon: '#7038F8',
  Dark: '#705848', Fairy: '#EE99AC',
};
const DARK_TEXT_TYPES = new Set(['Electric', 'Ice', 'Ground', 'Steel', 'Fairy']);

let pokemon = [];        // docs/data/pokemon.json, same order as matrix rows
let scores = null;       // Int16Array, score(i,j) = scores[i*N+j] / 10000
let N = 0;
let breakpoints = null;  // { colors: [...40], cuts: { hp: [...39], ... } }

const state = { p1: 0, p2: 0, fixedSide: 1, scaleImages: false };
const rankCache = new Map();

const $ = (id) => document.getElementById(id);

function score(i, j) { return scores[i * N + j] / 10000; }

// Indices sorted by similarity to i, descending; stable like R's order()
function ranking(i) {
  let r = rankCache.get(i);
  if (!r) {
    r = Array.from({ length: N }, (_, j) => j)
      .sort((a, b) => (scores[i * N + b] - scores[i * N + a]) || (a - b));
    rankCache.set(i, r);
  }
  return r;
}

function genderSummary(p) {
  if (p.maleRatio === 50) return '50/50';
  if (p.maleRatio > p.femaleRatio) return Math.round(p.maleRatio) + '% Male';
  if (p.femaleRatio > p.maleRatio) return Math.round(p.femaleRatio) + '% Female';
  return 'Genderless';
}

// DT::styleInterval semantics: value <= cuts[k] -> colors[k], else last color
function colorFor(key, value) {
  const cuts = breakpoints.cuts[key];
  for (let k = 0; k < cuts.length; k++) {
    if (value <= cuts[k]) return breakpoints.colors[k];
  }
  return breakpoints.colors[cuts.length];
}

const GRID_ROWS = [
  { label: 'Type',        chips: (p) => [p.type1, p.type2].filter(Boolean) },
  { label: 'Health',      key: 'hp' },
  { label: 'Attack',      key: 'attack' },
  { label: 'Defense',     key: 'defense' },
  { label: 'Sp. Attack',  key: 'spAttack' },
  { label: 'Sp. Defense', key: 'spDefense' },
  { label: 'Speed',       key: 'speed' },
  { label: 'Egg Group',   text: (p) => p.egg2 ? p.egg1 + ',\n' + p.egg2 : p.egg1 },
  { label: 'Height (m)',  key: 'height' },
  { label: 'Weight (kg)', key: 'weight' },
  { label: 'Gender',      text: genderSummary },
  { label: 'Happiness',   key: 'happiness' },
  { label: 'Catch Rate',  key: 'catchRate' },
];

// --- searchable dropdown ---------------------------------------------------

function makeDropdown(containerId, getSelected, onSelect) {
  const wrap = $(containerId);
  const input = document.createElement('input');
  input.className = 'select-input';
  input.autocomplete = 'off';
  input.spellcheck = false;
  const menu = document.createElement('div');
  menu.className = 'select-menu';
  menu.hidden = true;
  wrap.append(input, menu);

  const options = pokemon.map((p, idx) => {
    const opt = document.createElement('div');
    opt.className = 'select-option';
    const dex = document.createElement('span');
    dex.className = 'opt-dex';
    dex.textContent = '#' + p.dex;
    const name = document.createElement('span');
    name.className = 'opt-name';
    name.textContent = p.name;
    const gen = document.createElement('span');
    gen.className = 'opt-gen';
    gen.textContent = ROMAN[p.gen] || '';
    opt.append(dex, name, gen);
    opt.addEventListener('mousedown', (e) => {
      e.preventDefault(); // don't blur the input first
      choose(idx);
    });
    menu.appendChild(opt);
    return opt;
  });

  let visible = [];
  let active = -1;

  function filter(q) {
    q = q.trim().toLowerCase();
    visible = [];
    pokemon.forEach((p, idx) => {
      const show = !q || p.name.toLowerCase().includes(q);
      options[idx].hidden = !show;
      if (show) visible.push(idx);
    });
    setActive(visible.length ? 0 : -1, false);
  }

  function setActive(vPos, scroll = true) {
    options.forEach((o) => o.classList.remove('active'));
    active = vPos;
    if (vPos >= 0 && vPos < visible.length) {
      const el = options[visible[vPos]];
      el.classList.add('active');
      if (scroll) el.scrollIntoView({ block: 'nearest' });
    }
  }

  function open() {
    menu.hidden = false;
    input.value = '';
    filter('');
    const vPos = visible.indexOf(getSelected());
    setActive(vPos >= 0 ? vPos : 0);
  }

  function close() {
    menu.hidden = true;
    input.value = pokemon[getSelected()].name;
  }

  function choose(idx) {
    onSelect(idx);
    close();
    input.blur();
  }

  input.addEventListener('focus', open);
  input.addEventListener('blur', close);
  input.addEventListener('input', () => filter(input.value));
  input.addEventListener('keydown', (e) => {
    if (menu.hidden) return;
    if (e.key === 'ArrowDown') { e.preventDefault(); setActive(Math.min(active + 1, visible.length - 1)); }
    else if (e.key === 'ArrowUp') { e.preventDefault(); setActive(Math.max(active - 1, 0)); }
    else if (e.key === 'Enter') { e.preventDefault(); if (active >= 0) choose(visible[active]); }
    else if (e.key === 'Escape') { input.blur(); }
  });

  return { refresh: close };
}

// --- rendering ---------------------------------------------------------------

let dropdown1, dropdown2;
let lastShownPct = null;
let scoreAnim = null;

// -70% (observed floor) -> red, 100% -> green
function scoreColor(pct) {
  const t = Math.max(0, Math.min(1, (pct + 70) / 170));
  return 'hsl(' + Math.round(130 * t) + ', 62%, 38%)';
}

function showScore(pct) {
  $('similarity').textContent = Math.round(pct) + '%';
  $('similarity').style.color = scoreColor(pct);
}

function animateScore(toPct) {
  if (scoreAnim) cancelAnimationFrame(scoreAnim);
  if (lastShownPct === null) {
    showScore(toPct);
  } else {
    const fromPct = lastShownPct;
    const start = performance.now();
    const dur = 400;
    const tick = (now) => {
      const t = Math.min(1, (now - start) / dur);
      const eased = 1 - Math.pow(1 - t, 3);
      showScore(fromPct + (toPct - fromPct) * eased);
      if (t < 1) scoreAnim = requestAnimationFrame(tick);
    };
    scoreAnim = requestAnimationFrame(tick);
  }
  lastShownPct = toPct;
}

function makeTypeChip(type) {
  const chip = document.createElement('span');
  chip.className = 'type-chip';
  chip.textContent = type;
  chip.style.backgroundColor = TYPE_COLORS[type] || '#888';
  chip.style.color = DARK_TEXT_TYPES.has(type) ? '#3a3a2e' : 'white';
  return chip;
}

function renderCaption(side, p) {
  const cap = $('caption' + side);
  cap.textContent = p.name + ' ';
  const dex = document.createElement('span');
  dex.className = 'cap-dex';
  dex.textContent = '#' + p.dex;
  cap.appendChild(dex);
}

function render() {
  const p1 = pokemon[state.p1];
  const p2 = pokemon[state.p2];

  // badge (matches Shiny: whole-percent rounding)
  const s = score(state.p1, state.p2);
  animateScore(s * 100);

  // images, optionally scaled by height ratio; width is a percentage of
  // the img-box so the proportion holds when the box shrinks on mobile
  const ratio = p1.height / p2.height;
  let size1 = IMG_SIZE, size2 = IMG_SIZE;
  if (state.scaleImages) {
    if (ratio < 1) size1 = Math.round(IMG_SIZE * ratio);
    else if (ratio > 1) size2 = Math.round(IMG_SIZE / ratio);
  }
  for (const [img, p, size] of [[$('image1'), p1, size1], [$('image2'), p2, size2]]) {
    img.src = 'images/' + p.id + '.png';
    img.alt = p.name;
    img.style.width = (100 * size / IMG_SIZE) + '%';
  }
  renderCaption(1, p1);
  renderCaption(2, p2);

  // stat grid
  const grid = $('grid');
  grid.textContent = '';
  for (const row of GRID_ROWS) {
    const tr = document.createElement('tr');
    for (const p of [p1, null, p2]) {
      const td = document.createElement('td');
      if (p === null) {
        td.className = 'lbl';
        td.textContent = row.label;
      } else if (row.chips) {
        td.className = 'val';
        for (const type of row.chips(p)) td.appendChild(makeTypeChip(type));
      } else if (row.key) {
        td.className = 'val';
        td.textContent = p[row.key];
        td.style.backgroundColor = colorFor(row.key, p[row.key]);
      } else {
        td.className = 'val txt';
        td.textContent = row.text(p);
      }
      tr.appendChild(td);
    }
    grid.appendChild(tr);
  }

  // dropdowns, nav tooltips, fix-side buttons
  dropdown1.refresh();
  dropdown2.refresh();
  for (const [side, name] of [[1, p1.name], [2, p2.name]]) {
    $('most_similar' + side).title = 'Most Similar to ' + name;
    $('next_similar' + side).title = 'More Similar to ' + name;
    $('next_dissimilar' + side).title = 'Less Similar to ' + name;
    $('most_dissimilar' + side).title = 'Least Similar to ' + name;
  }
  $('fix_left').textContent = p1.name;
  $('fix_right').textContent = p2.name;
  $('fix_left').classList.toggle('fix-active', state.fixedSide === 1);
  $('fix_right').classList.toggle('fix-active', state.fixedSide === 2);
}

function setPokemon(side, idx) {
  if (side === 1) state.p1 = idx; else state.p2 = idx;
  render();
}

// --- navigation --------------------------------------------------------------

// side = which Pokemon anchors the ranking; the *other* side gets changed
function navigate(side, step) {
  const anchor = side === 1 ? state.p1 : state.p2;
  const other = side === 1 ? state.p2 : state.p1;
  const r = ranking(anchor);
  let target;
  if (step === 'most') {
    target = r[0] === anchor ? r[1] : r[0];
  } else if (step === 'least') {
    target = r[N - 1];
  } else {
    const pos = r.indexOf(other);
    target = r[Math.max(0, Math.min(N - 1, pos + step))];
  }
  setPokemon(side === 1 ? 2 : 1, target);
}

// --- similarity edit mode ------------------------------------------------------

function showEdit() {
  $('similarity-display').hidden = true;
  $('find-match-row').hidden = true;
  $('similarity-edit').hidden = false;
  const inp = $('target_score');
  inp.value = '';
  inp.focus();
}

function hideEdit() {
  $('similarity-edit').hidden = true;
  $('similarity-display').hidden = false;
  $('find-match-row').hidden = false;
}

function findMatch() {
  const target = parseFloat($('target_score').value.replace(/[^0-9.\-]/g, '')) / 100;
  if (isNaN(target)) return;
  const fixed = state.fixedSide === 1 ? state.p1 : state.p2;
  let best = -1, bestDiff = Infinity;
  for (let j = 0; j < N; j++) {
    if (j === fixed) continue;
    const d = Math.abs(score(fixed, j) - target);
    if (d < bestDiff) { bestDiff = d; best = j; }
  }
  setPokemon(state.fixedSide === 1 ? 2 : 1, best);
  hideEdit();
}

// --- init ---------------------------------------------------------------------

async function init() {
  const [pokemonRes, breakpointsRes, binRes] = await Promise.all([
    fetch('data/pokemon.json'),
    fetch('data/breakpoints.json'),
    fetch('data/similarity_i16.bin'),
  ]);
  pokemon = await pokemonRes.json();
  breakpoints = await breakpointsRes.json();
  scores = new Int16Array(await binRes.arrayBuffer());
  N = pokemon.length;
  if (scores.length !== N * N) throw new Error('similarity matrix size mismatch');

  state.p1 = pokemon.findIndex((p) => p.name === 'Charizard');
  state.p2 = pokemon.findIndex((p) => p.name === 'Blastoise');

  dropdown1 = makeDropdown('select1', () => state.p1, (idx) => setPokemon(1, idx));
  dropdown2 = makeDropdown('select2', () => state.p2, (idx) => setPokemon(2, idx));

  $('random1').addEventListener('click', () => setPokemon(1, Math.floor(Math.random() * N)));
  $('random2').addEventListener('click', () => setPokemon(2, Math.floor(Math.random() * N)));

  for (const side of [1, 2]) {
    $('most_similar' + side).addEventListener('click', () => navigate(side, 'most'));
    $('next_similar' + side).addEventListener('click', () => navigate(side, -1));
    $('next_dissimilar' + side).addEventListener('click', () => navigate(side, +1));
    $('most_dissimilar' + side).addEventListener('click', () => navigate(side, 'least'));
  }

  $('scale_images').addEventListener('change', (e) => {
    state.scaleImages = e.target.checked;
    render();
  });

  $('similarity-display').addEventListener('click', (e) => { e.stopPropagation(); showEdit(); });
  $('find_match_toggle').addEventListener('click', (e) => { e.stopPropagation(); showEdit(); });
  $('fix_left').addEventListener('click', () => { state.fixedSide = 1; render(); });
  $('fix_right').addEventListener('click', () => { state.fixedSide = 2; render(); });
  $('find_match').addEventListener('click', findMatch);
  $('target_score').addEventListener('keydown', (e) => {
    if (e.key === 'Enter') { e.preventDefault(); findMatch(); }
    else if (e.key === 'Escape') { e.preventDefault(); hideEdit(); }
  });
  document.addEventListener('click', (e) => {
    if (!$('similarity-edit').hidden && !e.target.closest('#similarity-edit')) hideEdit();
  });

  $('loading').hidden = true;
  $('app').hidden = false;
  render();
}

init().catch((err) => {
  $('loading').textContent = 'Failed to load data: ' + err.message;
});
