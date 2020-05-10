# Similarity Tool

This is a calculator which outputs a similarity score between two selected Pokemon. To visualize the results of this calculator I also created a web app, built from scratch using R Shiny.


## Inspiration

I was inspired by Dom Luszczyszyn's article in The Athletic called "By the numbers: Finding the NHL's most unique players" (https://theathletic.com/1761077/2020/04/21/by-the-numbers-finding-the-nhls-most-unique-players/). In this article, he calculated similarity scores between all NHL players using age, size, and various usage stats to represent offensive and defensive prowess. He defined the most unique players to the the ones who that the lowest similarity score with their respective closest match. These players were:

- John Carlsen (one-dimensional, elite offensive production)
- Zdeno Chara (tall, 42, and still effective)  
- Alex Ovechkin (true-talent 50-goal scorer – at any age)

## Pokemon Similarity Calculator

#### Eligible Pokemon
- First 4 Generations of Pokemon Only
- Fully-Evolved Pokemon Only
- No Megas/Special Forms
#### Features
- Type(s)
- Base Stats (Health, Attack, Defense, Sp.Attack, Sp. Defense, Speed)
- Height and Weight
- Base Happiness
- Gender Ratio
- Catch Rate (lower Catch Rate => More difficult to capture)

## Methodology

#### Data Processing
- One-hot encoding Type data (treating Primary and Secondary Types as equivalent)
- One-hot encoding Gender ratios into three binary variables: Male/Female Dominant (if gender ratio skews toward one or the other) or Genderless
- Standardize all data (average of 0, variance of 1)
- Similarity between 2 pkmn: Cosine of the angle between their corresponding 29-dimensional vectors

#### Reasons for using Cosine similarity
- Robust to extreme features (e.g. some Pokemon had features with z-scores as high as 9, and these features skewed distance metrics like Euclidean or Manhattan Distance)
- Captures the essence of the pkmn rather than the scale of their features

**No Machine Learning necessary! This is not a clustering problem, there is no reason to introduce ML into this problem when other statistical methods work perfectly well.