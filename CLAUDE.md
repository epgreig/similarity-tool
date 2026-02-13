# CLAUDE.md - Project Guide for AI Agents

## What This Is

A Pokemon Similarity Calculator built in R Shiny. It computes cosine similarity across ~45 dimensions (stats, types, egg groups, size, gender, happiness, catch rate) for 1182 Pokemon (Gen 1-9, all evolutionary stages, plus alternate forms). Deployed on ShinyApps.io.

## Architecture & Data Flow

```
pokeapi_data/*.csv  -->  build_pokemon_data.py  -->  pokemon_data.csv
                                                          |
                                                          v
                                                  generate_similarity.R
                                                    (one-hot encoding, scaling, cosine similarity)
                                                          |
                                                          v
                                              conditional_formatting.R
                                                (color breakpoints for stat grid)
                                                          |
                                                          v
                                                  prepare_app_data.R
                                                    (grid display data, similarity rankings)
                                                          |
                                                          v
                                                      app.R  (Shiny UI/server)
```

## Key Files

| File | Role |
|------|------|
| `build_pokemon_data.py` | Joins PokeAPI CSVs into `pokemon_data.csv`. Python 3, no dependencies beyond stdlib. |
| `pokemon_data.csv` | Flat CSV with 1182 rows. Columns: Pokemon Id, Pokedex, Name, Height, Weight, types, stats, gender ratios, egg groups, etc. |
| `pokeapi_data/` | Raw CSV dump from [PokeAPI GitHub](https://github.com/PokeAPI/pokeapi/tree/master/data/v2/csv). 14 files. |
| `generate_similarity.R` | One-hot encodes types/egg groups, scales features, computes cosine similarity matrix. |
| `conditional_formatting.R` | Builds JS rowCallback for color-coding the stat comparison grid. |
| `prepare_app_data.R` | Sources generate_similarity.R, builds grid_data matrix and similarity rankings. |
| `app.R` | Shiny app. Two dropdowns, two images, stat grid, similarity percentage, navigation buttons. |
| `images/` | Sprites named by pokemon_id (e.g. `25.png` for Pikachu, `10034.png` for Charizard-Mega X). |

## Data Source

**Single source: PokeAPI CSV data dump.** No manual overrides or patches. If PokeAPI has errors (e.g. Ogerpon's gender_rate), we accept them. This was a deliberate design decision.

The CSVs were downloaded from `https://github.com/PokeAPI/pokeapi/tree/master/data/v2/csv`. To refresh, re-download and re-run `build_pokemon_data.py`.

## Sprites

Sourced from the [PokeAPI sprites repo](https://github.com/PokeAPI/sprites) (`sprites/pokemon/other/official-artwork/`). Downloaded via sparse git checkout into `pokeapi_sprites/` (gitignored), then copied to `images/{pokemon_id}.png`.

4 sprites are gray placeholders (unreleased Legends Z-A megas): 10309, 10318, 10322, 10323.

## How to Rebuild Everything

```bash
# 1. Build pokemon_data.csv from raw CSVs
python3 build_pokemon_data.py

# 2. Test the R pipeline
Rscript -e 'source("prepare_app_data.R"); cat("OK:", nrow(table), "Pokemon\n")'

# 3. Run the app
Rscript -e 'shiny::runApp("app.R")'
```

## R Dependencies

`shiny`, `shinyBS`, `DT`, `data.table`, `mltools`

## Important Technical Notes

- **R 4.0+ stringsAsFactors**: `generate_similarity.R` explicitly converts type/egg group columns to factors before calling `mltools::one_hot()`. Without this, one_hot produces empty column names.
- **Server-side selectize**: With 1182 Pokemon, the dropdowns use `updateSelectizeInput(..., server=TRUE)` in the server function (not choices in UI) to avoid performance warnings.
- **Image naming**: Uses `Pokemon Id` column (PokeAPI's pokemon_id), NOT the Pokedex number. This avoids collisions between base forms and alternate forms of the same species.
- **Form inclusion logic**: Megas (mega/mega-x/mega-y/primal), regional forms, and forms with different stats/types are included. Gigantamax, totems, and cosmetic-only forms are excluded. See `should_include_form()` and `INCLUDED_FORMS_BY_IDENTIFIER` in `build_pokemon_data.py`.
- **Display names**: `FORM_DISPLAY_NAMES` maps known form_identifiers to display suffixes. Unknown forms fall back to title-casing the pokemon identifier suffix (e.g. `garchomp-mega-z` becomes "Garchomp-Mega-Z").
- **Hisui species**: Species 899-905 are Gen 8 in PokeAPI but region is overridden to "Hisui".
- **prepare_app_data.R uses R's `$` partial matching**: `data$Health` matches `Health.Stat` column. This works because data.table inherits from data.frame for `$`.

## What's NOT in the Repo

- `.venv/` — Python virtual environment (gitignored)
- `pokeapi_sprites/` — Sparse git checkout of PokeAPI sprites repo (gitignored)
- `sprite_mapping.csv` — No longer used (gitignored)

## Similarity Algorithm Summary

1. One-hot encode types (18 types) and egg groups (15 groups) into binary columns
2. Combine primary + secondary into single set of type/egg group columns
3. Create binary gender features (Male.Dominant, Female.Dominant, Genderless)
4. Center all features by median, scale by standard deviation
5. Types and egg groups share pooled standard deviations within their groups
6. Weight: stats at 1x, types/egg groups at 1/3x, size/gender/misc at 1/9x
7. Compute cosine similarity between all pairs
