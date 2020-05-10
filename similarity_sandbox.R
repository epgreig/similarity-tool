library('mltools')
library('data.table')
library('corrplot')

data <- read.csv('pokemon_data.csv')

# Import Data
table <- data.table(data)
types <- c(as.character(unique(table$Primary.Type)), "Flying")

# One-Hot
table <- one_hot(table, c("Legendary.Type", "Primary.Type", "Secondary.Type"))

# Combine Type Features
table$Primary.Type_Flying <- 0
table$Secondary.Type_Normal <- 0
primary_col_names <- paste0("Primary.Type_",types)
secondary_col_names <- paste0("Secondary.Type_",types)
combined_col_names <- paste0("Type_",types)
for (i in 1:length(types))
{
  table[, eval(quote(combined_col_names[i]))] <- table[,eval(quote(primary_col_names[i])), with=FALSE] + table[,eval(quote(secondary_col_names[i])), with=FALSE]
  table[,eval(quote(primary_col_names[i]))] <- NULL
  table[,eval(quote(secondary_col_names[i]))] <- NULL
}

# Gender Features
table$Male.Dominant <- table$Male.Ratio > 50
table$Female.Dominant <- table$Female.Ratio > 50
table$Genderless <- table$Female.Ratio == 0 & table$Male.Ratio == 0

# Legendary = Legendary + Mythical
table$Legendary.Type_Legendary <- table$Legendary.Type_Legendary + table$Legendary.Type_Mythical

# Replace FALSE/TRUE with 0/1
(to.replace <- names(which(sapply(table, is.logical))))
for (var in to.replace) table[, (var):= as.numeric(get(var))]

# Drop useless columns
table$Legendary.Type_ <- NULL
table$Legendary.Type_Mythical <- NULL
table$Secondary.Type_ <- NULL
table$Base.Stat.Total <- NULL
table$Male.Ratio <- NULL
table$Female.Ratio <- NULL

# Identify numeric fields
non_scaling_columns <- c("Name","Pokedex","Region.of.Origin")
table_scaled <- cbind(table[, non_scaling_columns, with=FALSE], scale(table[, -non_scaling_columns, with=FALSE]))
table_numeric <- table_scaled[, -non_scaling_columns, with=FALSE]

# Define feature groupings
features_size <- c("Height", "Weight")
features_stats <- c("Health", "Attack", "Defense", "Special.Attack", "Special.Defense", "Speed")
features_types <- combined_col_names
features_gender <- c("Male.Dominant", "Female.Dominant")
features_misc <- c("Base.Happiness", "Catch.Rate")

# Generate correlation matrix
table_numeric <- table_numeric[, c(features_size, features_stats, features_types, features_gender, features_misc), with=FALSE]
corr_matrix <- corrplot(cor(table_numeric), method="circle", type="upper", tl.col="black", diag=FALSE, tl.srt=60, tl.cex = 0.7)

# Notable correlations
corr_matrix["Height", "Weight"]
corr_matrix["Height", "Health"]
corr_matrix["Type_Psychic","Special.Attack"]
corr_matrix["Type_Normal","Special.Attack"]
corr_matrix["Type_Rock","Defense"]
corr_matrix["Type_Rock","Speed"]
corr_matrix["Type_Fighting","Male.Dominant"]
corr_matrix["Type_Fairy","Female.Dominant"]
corr_matrix["Type_Dark","Base.Happiness"]
corr_matrix["Base.Happiness", "Weight"]
corr_matrix["Base.Happiness", "Female.Dominant"]
corr_matrix["Catch.Rate","Special.Attack"]
#corr_matrix["Catch.Rate","Genderless"]

# Factor Re-Weighting
#table_numeric[,"Weight"] <- table_numeric[,"Weight"] / 2
#table_numeric[,"Genderless"] <- table_numeric[,"Genderless"] / 2

# Euclidean Distance
distances <- as.matrix(dist(table_numeric, method = "minkowski", upper=TRUE, p=1))
diag(distances) <- rowMeans(distances)
log_distances <- log(distances)

most_similar <- max.col(-distances)
most_different <- max.col(distances)

length(unique(most_similar))

# Manhattan
# most_differents: Shuckle, Giratina-Origin
# length(unique(most_similar)): 165

# Euclidean
# most_differents: Shuckle, Wailord, Giratina-Origin
# length(unique(most_similar)): 164

# Minkowski 0.5
# most_differents: Shuckle, Wailord, Giratina-Origin
# length(unique(most_similar)): 164

# Minkowski 0.1
# most_differents: Giratina-Origin, Azurill
# length(unique(most_similar)): 168

# Most Alike
match(min(distances), distances)
# 1. Euclidean/Manhattan/Cosine 12389 = Hitmonchan (45), Hitmontop (113)
distances[12389] <- 10
distances[31293] <- 10
match(min(distances), distances)
# 2. Euclidean/Manhattan/Cosine 41442 = Plusle (149), Minun (150)
distances[41442] <- 10
distances[41720] <- 10
match(min(distances), distances)
# 3. Euclidean: 5707 = Persian (21), Linoone (127)
distances[5707] <- 10
distances[35175] <- 10
match(min(distances), distances)
# 4. Euclidean: 51242 = Huntail (184), Gorebyss (185)

# 3. Manhattan: 51242 = Huntail (184), Gorebyss (185)
distances[51242] <- 10
distances[51520] <- 10
match(min(distances), distances)
# 4. Manhattan: 12042 = Hitmonlee (44), Hitmonchan (45)
distances[12042] <- 10
distances[12320] <- 10
match(min(distances), distances)
# 5. Manhattan: 5707 = Persian (21), Linoone (127)

# 3. Cosine: 12042 = Hitmonlee (44), Hitmonchan (45)
#distances[12042] <- 0
#distances[12320] <- 0
# 4. Cosine: 7062 = Alakazam (26), Espeon (87)
#distances[12042] <- 0
#distances[12320] <- 0


# 1. Minkowski 0.1: 350 = Charizard (2), Typhlosion (71)


# Most Unlike
# Euclidean: Shuckle (99) and Wailord (155)
# Manhattan: Shuckle (99) and Giratina-Origin (272)
# Minkowski 0.1: Azurill (142) and Giratina-Origin (272)
# Cosine: Shuckle (99) and Deoxys-Attack (200)

#most_similar examples
# Minko 0.1
#table[c(4,5,6,7,8,9,128,129,173,127,206,164),]
# Manhattan
#table[c(4,5,6,7,8,9,128,129,206,127,34,164),]

# Scores
log_scores <- (mean(log_distances)-log_distances)/mean(log_distances)
min(log_scores)
max(log_scores)

sim <- table_numeric / sqrt(rowSums(table_numeric * table_numeric))
cosine_scores <- as.matrix(sim) %*% t(as.matrix(sim))
diag(cosine_scores) <- rowMeans(cosine_scores)

most_similar <- max.col(cosine_scores)
length(unique(most_similar))
most_dissimilar <- max.col(-cosine_scores)
length(unique(most_dissimilar))

x <- 1:nrow(table)
for (i in 1:nrow(table)){
  x[i] <- cosine_scores[i,most_similar[i]]
}

#Finding Closest Pairs

max(x)
match(max(x),x) # Hitmonchan (45)
x[45] <- 0.5
match(max(x),x) # Hitmontop (114)
x[114] <- 0.5
match(max(x),x) # Plusle (149)
x[149]
x[149]<- 0.5
match(max(x),x) # Minun (150)
x[150] <- 0.5
max(x)
match(max(x),x) # Hitmonlee (44)
x[44] <- 0.5
max(x)
match(max(x),x) # Alakazam (26), Espeon (87)
