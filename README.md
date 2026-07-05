# Pokémon Similarity Tool

#### [https://epgreig.shinyapps.io/similarity-tool/](https://epgreig.shinyapps.io/similarity-tool/)

An interactive calculator that computes a similarity score between any two Pokémon, built from scratch as an R Shiny web app. Select any pair from all 1,238 included Pokémon and instantly see how alike they are — plus a stat-by-stat comparison grid, navigation buttons to explore neighbors in similarity space, and the ability to search for a target similarity percentage.

The app is hosted on shinyapps.io at the link above. Alternatively, you can clone this repo and run it locally:

```bash
Rscript -e 'shiny::runApp("app.R")'
```

## Pokémon Similarity Calculator

#### Eligible Pokémon
- Generations 1–9 (Kanto through Paldea), all evolutionary stages
- 1,238 Pokémon total, including:
  - Mega Evolutions and Primal forms
  - Regional forms (Alola, Galar, Hisui, Paldea)
  - Alternate forms with different stats or types (e.g. Deoxys forms, Rotom appliances, Aegislash-Blade)
- Excludes Gigantamax, Totem, and cosmetic-only forms

#### Features (45 dimensions)
- Base Stats: HP, Attack, Defense, Sp. Attack, Sp. Defense, Speed (6)
- Type(s): one-hot encoded across 18 types (18)
- Egg Group(s): one-hot encoded across 14 groups (14)
- Gender: Male Dominant, Female Dominant, Genderless (3)
- Height and Weight (2)
- Base Happiness and Catch Rate (2)

## Methodology

#### Data Sources
- **Data:** [PokeAPI CSV data dump](https://github.com/PokeAPI/pokeapi/tree/master/data/v2/csv) — 14 raw CSV files joined by `build_pokemon_data.py` into a single `pokemon_data.csv`
- **Images:** [PokeAPI sprites repo](https://github.com/PokeAPI/sprites), official artwork (`sprites/pokemon/other/official-artwork/`)

#### Data Processing
1. One-hot encode Type data (Primary and Secondary Types treated equivalently, producing 18 binary columns)
2. One-hot encode Egg Group data (Primary and Secondary Egg Groups treated equivalently, producing 14 binary columns)
3. Encode Gender Ratios into three binary variables: Male Dominant, Female Dominant, or Genderless
4. Center all features on the median and scale by standard deviation
5. Apply feature weighting: Base Stats at full weight (1x), all other features at 1/3x
6. Type features share a pooled standard deviation (so rarity of a type doesn't affect similarity — Fairy and Water are equally dissimilar from any other type). Same for Egg Groups.
7. Append a constant dummy feature to every vector (gives all pairs a shared component, softening extreme negative similarities)
8. Compute cosine similarity between each pair's feature vector

#### Why Cosine Similarity?
- Robust to extreme features (some Pokémon have z-scores as high as 9, which skew distance metrics like Euclidean or Manhattan)
- Captures the character of a Pokémon rather than the raw scale of its stats

**No machine learning necessary!** This is not a clustering problem — cosine similarity on well-chosen features works perfectly.

## Results

*One entry per evolutionary line; different species only for pairs.*

**Most Similar Pokémon Pairs**

1. Silcoon and Cascoon: 100.0%
2. Piplup and Popplio: 99.8%
3. Zigzagoon and Bunnelby: 99.6%
4. Metapod and Spewpa: 99.6%
5. Pidgey and Fletchling: 99.6%

**Most Similar Pokémon Who Don't Share a Type**

1. Zacian (Fairy) and Zamazenta (Fighting): 91.4%
2. Darkrai-Mega (Dark) and Magearna-Mega (Steel/Fairy): 88.7%
3. Deoxys-Attack (Psychic) and Pheromosa (Bug/Fighting): 88.2%
4. Mewtwo-Mega Y (Psychic) and Zeraora-Mega (Electric): 88.0%
5. Xerneas (Fairy) and Yveltal (Dark/Flying): 87.8%

**Most Dissimilar Pokémon Pairs**

1. Wynaut and Diancie-Mega: -69.7%
2. Sunkern and Arceus: -69.0%
3. Mewtwo-Mega X and Kricketot: -68.3%
4. Pichu and Terapagos-Stellar: -66.5%
5. Tyranitar-Mega and Wishiwashi-Solo: -66.1%

**Most Unique Pokémon** (lowest similarity with closest match)

1. Castform: closest match 61.5% w/ Audino
2. Nidoqueen: closest match 62.1% w/ Cresselia
3. Poipole: closest match 64.5% w/ Munkidori
4. Aegislash-Blade: closest match 67.5% w/ Blacephalon
5. Mimikyu-Disguised: closest match 68.3% w/ Misdreavus

**Most Generic Pokémon** (highest average similarity)

1. Golduck: average 24.3%
2. Stantler: average 23.9%
3. Watchog: average 23.7%
4. Dewott: average 23.6%
5. Dubwool: average 23.6%

**Least Generic Pokémon** (lowest average similarity)

1. Chansey: average 3.1%
2. Wishiwashi-Solo: average 4.3%
3. Pichu: average 4.8%
4. Cleffa: average 5.2%
5. Wobbuffet: average 5.4%

## Inspiration

Inspired by Dom Luszczyszyn's article in The Athletic, ["By the numbers: Finding the NHL's most unique players"](https://theathletic.com/1761077/2020/04/21/by-the-numbers-finding-the-nhls-most-unique-players/). He calculated similarity scores between all NHL players using age, size, and various usage stats, then defined the most unique players as those with the lowest similarity to their closest match.
