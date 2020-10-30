# Similarity Tool

#### Link: [https://epgreig.shinyapps.io/similarity-tool/](https://epgreig.shinyapps.io/similarity-tool/?_ga=2.21943161.313882230.1588985783-2134019159.1588985783)
This is a calculator which outputs a similarity score between two selected Pokemon. To visualize the results of this calculator I also created a web app, built from scratch using R Shiny.

The link above is to the web app hosted on shinyapps.io (free account, 25 hours of usage per month). Alternatively, you can clone this repo, open the App.R file in R Studio with the codebase directory as your working directory and click "Run App".

## Inspiration

I was inspired by Dom Luszczyszyn's article in The Athletic called "By the numbers: Finding the NHL's most unique players" (https://theathletic.com/1761077/2020/04/21/by-the-numbers-finding-the-nhls-most-unique-players/). In this article, he calculated similarity scores between all NHL players using age, size, and various usage stats to represent offensive and defensive prowess. He defined the most unique players to the the ones who that the lowest similarity score with their respective closest match. These players were:

- John Carlson (one-dimensional, elite offensive production)
- Zdeno Chara (tall, 42, and still effective)  
- Alex Ovechkin (true-talent 50-goal scorer – at any age)

## Pokemon Similarity Calculator

#### Eligible Pokemon
- First 8 Generations of Pokemon
- Fully-Evolved Pokemon Only
- Includes Megas and alternate forms if stats are different
- No Gigantamax Forms

#### Features
- Type(s)
- Base Stats (Health, Attack, Defense, Sp.Attack, Sp. Defense, Speed)
- Height and Weight
- Egg Group
- Base Happiness
- Gender Ratio
- Catch Rate (lower Catch Rate => More difficult to capture)

## Methodology

#### Data Sources
- Data: https://www.kaggle.com/mrdew25/pokemon-database
- Images: https://www.kaggle.com/kvpratama/pokemon-images-dataset (Gen 1-6), https://www.kaggle.com/adityamhatre/pokemon-transparent-images-dataset (Gen 7), https://projectpokemon.org/docs/spriteindex_148/home-sprites-gen-8-r135/ (Gen 8)

#### Data Processing
- One-hot encoding Type data (treating Primary and Secondary Types as equivalent)
- One-hot encoding Egg Group data (treating Primary and Secondary Egg Groups as equivalent)
- One-hot encoding Gender ratios into three binary variables: Male/Female Dominant (if gender ratio skews toward one or the other) or Genderless
- Standardize all features: centering on the <ins>median</ins>, and with standard deviation of 1 for the six Stat features, 1/3 for the Type and Egg Group features, and 1/3 for the remaining features (I want to weigh the Base Stats of the pokemon more than anything else for similarity)
- Note: the one-hot encoded Type features were scaled together so that the rarity of a type was not considered in similarity (e.g. Fairy is more rare than Water but I want to consider them equally dissimilar from any other type). This was also done for Egg Groups.
- Similarity between 2 pkmn: Cosine of the angle between their corresponding 45-dimensional vectors

#### Reasons for using Cosine similarity
- Robust to extreme features (e.g. some Pokemon had features with z-scores as high as 9, and these features skewed distance metrics like Euclidean or Manhattan Distance)
- Captures the essence of the pkmn rather than the scale of their features

**No Machine Learning necessary! This is not a clustering problem, there is no reason to introduce ML into this problem when other statistical methods work perfectly well.


## Results

**Most Similar Pokemon Pairs**

1. Lycanroc and Lycanroc-Dusk: 99.9%
2. Purugly and Cinccino: 98.4%
3. Hitmonchan and Hitmontop: 97.8%
4. Plusle and Minun: 97.6%
5. Gourgeist and Gourgeist-Small: 97.6%
6. Furret and Linoone: 97.4%

**Most Similar Pokemon Pairs Who Don't Share a Type**

1. Darmanitan (Fire type) and Darmanitan-Galar (Ice type): 89.3%
2. Zacian (Fairy) and Zamazenta (Fighting): 89.2%
2. Deoxys-Attack (Psychic) and Pheromosa (Bug/Fighting): 89.2%


**Most Dissimilar Pokemon Pairs**

1. Shuckle and Deoxys-Attack: -72.3%
2. Deoxys-Attack and Pyukumuku: -71.8%
3. Pyukumuku and Pheromosa: -71.0%
4. Mewtwo-Mega-X and Smeargle: -68.0%

**Most Unique Pokemon** (measured by lowest similarity score for closest match)

1. Nidoqueen: closest match 54.4% w/ Nidoking
2. Decidueye: closest match 55.8% w/ Dhelmise
3. Garbodor: closest match 57.9% w/ Solrock

**Least Unique Pokemon** (measured by highest similarity score for furthest match)

1. Phione: furthest match -3.8% w/ Rayquaza-Mega
2. Flygon: furthest match -7.5% w/ Pincurchin
3. Glalie: furthest match -7.5% w/ Diancie-Mega
 
**Most Generic Pokemon** (measure by highest average similarity score with all other Pokemon)

1. Samurott: average match 23.6%

**Least Generic Pokemon** (measure by lowest average similarity score with all other Pokemon)

1. Shedinja: average match 1.7%

