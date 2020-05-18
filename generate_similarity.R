library('mltools')
library('data.table')

# Import Data
data <- read.csv('pokemon_data.csv')
data <- data.table(data)

# One-Hot
types <- c(as.character(unique(data$Primary.Type)))
egg_groups <- c(as.character(unique(data$Primary.Egg.Group)))
table <- one_hot(data, c("Primary.Type", "Secondary.Type", "Primary.Egg.Group","Secondary.Egg.Group"))

# Combine Primary and Secondary Type Features
primary_type_cols <- paste0("Primary.Type_",types)
secondary_type_cols <- paste0("Secondary.Type_",types)
combined_type_cols <- paste0("Type_",types)
for (i in 1:length(types))
{
  table[, eval(quote(combined_type_cols[i]))] <- table[,eval(quote(primary_type_cols[i])), with=FALSE] + table[,eval(quote(secondary_type_cols[i])), with=FALSE]
  table[,eval(quote(primary_type_cols[i]))] <- NULL
  table[,eval(quote(secondary_type_cols[i]))] <- NULL
}

# Combine Primary and Secondary Egg Group Features
table$Secondary.Egg.Group_Undiscovered <- 0
table$Secondary.Egg.Group_Ditto <- 0
primary_egg_cols <- paste0("Primary.Egg.Group_",egg_groups)
secondary_egg_cols <- paste0("Secondary.Egg.Group_",egg_groups)
combined_egg_cols <- paste0("Egg.Group_",egg_groups)
for (i in 1:length(egg_groups))
{
  table[, eval(quote(combined_egg_cols[i]))] <- table[,eval(quote(primary_egg_cols[i])), with=FALSE] + table[,eval(quote(secondary_egg_cols[i])), with=FALSE]
  table[,eval(quote(primary_egg_cols[i]))] <- NULL
  table[,eval(quote(secondary_egg_cols[i]))] <- NULL
}

# Gender Features
table$Male.Dominant <- table$Male.Ratio > 50
table$Female.Dominant <- table$Female.Ratio > 50
table$Genderless <- table$Female.Ratio == 0 & table$Male.Ratio == 0

# Replace FALSE/TRUE with 0/1
(to.replace <- names(which(sapply(table, is.logical))))
for (var in to.replace) table[, (var):= as.numeric(get(var))]

# Drop useless columns
table$Secondary.Type_ <- NULL
table$Secondary.Egg.Group_ <- NULL
table$Egg.Group_Undiscovered <- NULL
table$Base.Stat.Total <- NULL
combined_egg_cols <- combined_egg_cols[combined_egg_cols != "Egg.Group_Undiscovered"]

# Define similarity feature groupings
features_size <- c("Height", "Weight")
features_stats <- c("Health.Stat", "Attack.Stat", "Defense.Stat", "Special.Attack.Stat", "Special.Defense.Stat", "Speed.Stat")
features_types <- combined_type_cols
features_egg_groups <- combined_egg_cols
features_gender <- c("Male.Dominant", "Female.Dominant", "Genderless")
features_misc <- c("Base.Happiness", "Catch.Rate")

# Center and Scale
non_scaling_columns <- c("Name","Pokedex","Region.of.Origin")
medians <- apply(table[, -non_scaling_columns, with=FALSE], 2, median)
std_devs <- apply(table[, -non_scaling_columns, with=FALSE], 2, sd)
std_devs[features_types] <- sd(as.matrix(table[, features_types, with=FALSE]))
std_devs[features_egg_groups] <- sd(as.matrix(table[, features_egg_groups, with=FALSE]))

table_scaled <- cbind(table[, non_scaling_columns, with=FALSE], scale(table[, -non_scaling_columns, with=FALSE], center=medians, scale=std_devs))
table_numeric <- table_scaled[, -non_scaling_columns, with=FALSE]

table_numeric <- table_numeric[, c(features_size, features_stats, features_types, features_egg_groups, features_gender, features_misc), with=FALSE]

# Scale down less important categories
features_categorical <- c(features_types, features_egg_groups)
table_numeric[, features_categorical] <- table_numeric[, features_categorical, with=FALSE] / 2
features_scale_down <- c(features_size, features_gender, features_misc)
table_numeric[, features_scale_down] <- table_numeric[, features_scale_down, with=FALSE] / 4

distances <- as.matrix(dist(table_numeric, method = "manhattan", upper=TRUE))
# Calculate Scores and Most Similar
sim <- table_numeric / sqrt(rowSums(table_numeric * table_numeric))
cosine_scores <- as.matrix(sim) %*% t(as.matrix(sim))
diag(cosine_scores) <- rowMeans(cosine_scores)

most_similar <- max.col(cosine_scores)
most_dissimilar <- max.col(-cosine_scores)

# Get Image Names
get_image_name <- function(pokedex, name) {
  suffix <- gsub(" ", "-", tolower(sub("^[^-]*", "", name)))
  image_name <- paste0("images/", pokedex, suffix, ".png")
  return(image_name)
}

table$Image.Name <- get_image_name(table$Pokedex, table$Name)

# Combine into one table
table_with_scores <- cbind(table, most_similar, most_dissimilar)

# for (filename in table$Image.Name)
#   file.copy(paste0("images/", filename), "images_temp")

#for (filename in table$Image.Name) {
#    file.copy(filename, "images_temp")
# }
