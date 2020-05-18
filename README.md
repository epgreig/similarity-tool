# Similarity Tool

#### Link: [https://epgreig.shinyapps.io/similarity-tool/](https://epgreig.shinyapps.io/similarity-tool/?_ga=2.21943161.313882230.1588985783-2134019159.1588985783)
This is a calculator which outputs a similarity score between two selected Pokemon. To visualize the results of this calculator I also created a web app, built from scratch using R Shiny.

The link above is to the web app hosted on shinyapps.io (free account, 25 hours of usage per month). Alternatively, you can clone this repo, open the App.R file in R Studio with the codebase directory as your working directory and click "Run App" (Takes 30-45 seconds to open, for data pre-processing)

## Inspiration

I was inspired by Dom Luszczyszyn's article in The Athletic called "By the numbers: Finding the NHL's most unique players" (https://theathletic.com/1761077/2020/04/21/by-the-numbers-finding-the-nhls-most-unique-players/). In this article, he calculated similarity scores between all NHL players using age, size, and various usage stats to represent offensive and defensive prowess. He defined the most unique players to the the ones who that the lowest similarity score with their respective closest match. These players were:

- John Carlsen (one-dimensional, elite offensive production)
- Zdeno Chara (tall, 42, and still effective)  
- Alex Ovechkin (true-talent 50-goal scorer – at any age)

## Pokemon Similarity Calculator

#### Eligible Pokemon
- First 8 Generations of Pokemon Only
- Fully-Evolved Pokemon Only
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
- One-hot encoding Gender ratios into three binary variables: Male/Female Dominant (if gender ratio skews toward one or the other) or Genderless
- Standardize all data (average of 0, variance of 1)
- Similarity between 2 pkmn: Cosine of the angle between their corresponding 29-dimensional vectors

#### Reasons for using Cosine similarity
- Robust to extreme features (e.g. some Pokemon had features with z-scores as high as 9, and these features skewed distance metrics like Euclidean or Manhattan Distance)
- Captures the essence of the pkmn rather than the scale of their features

**No Machine Learning necessary! This is not a clustering problem, there is no reason to introduce ML into this problem when other statistical methods work perfectly well.


## Results

**Most Similar Pokemon Pairs**

1. Hitmonchan and Hitmontop: 99.21%
2. Plusle and Minun: 99.19%
3. Hitmonlee and Hitmonchan: 98.1%
4. Alakazam and Espeon: 97.8%

**Among the pairs that don't share a type: highest is Mew and Shaymin: 52%

**Most Unique Pokemon** (measured by lowest similarity score for closest match)

1. Heatran: closest match 53% w/ Metagross
2. Umbreon: closest match 56% w/ Mightyena
3. Xatu: closest match 59% w/ Chimecho
 
**Least Generic Pokemon** (measure by lowest average similarity score with all other Pokemon)

1. Dialga: average match -3.1%

**Most Generic Pokemon** (measure by lowest average similarity score with all other Pokemon)

1. Bibarel: average match 3.2%
