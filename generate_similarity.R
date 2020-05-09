library('mltools')
library('data.table')

# Import Data
data <- read.csv('pokemon_data.csv')
data <- data.table(data)

# One-Hot
types <- c(as.character(unique(data$Primary.Type)), "Flying")
table <- one_hot(data, c("Legendary.Type", "Primary.Type", "Secondary.Type"))

# Combine Primary and Secondary Type Features
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

# Identify non-numeric fields
non_scaling_columns <- c("Name","Pokedex","Region.of.Origin")
table_scaled <- cbind(table[, non_scaling_columns, with=FALSE], scale(table[, -non_scaling_columns, with=FALSE]))
table_numeric <- table_scaled[, -non_scaling_columns, with=FALSE]

# Define similarity feature groupings
features_size <- c("Height", "Weight")
features_stats <- c("Health", "Attack", "Defense", "Special.Attack", "Special.Defense", "Speed")
features_types <- combined_col_names
features_gender <- c("Male.Dominant", "Female.Dominant", "Genderless")
features_misc <- c("Base.Happiness", "Catch.Rate")

table_numeric <- table_numeric[, c(features_size, features_stats, features_types, features_gender, features_misc), with=FALSE]

# Calculate Scores and Most Similar
sim <- table_numeric / sqrt(rowSums(table_numeric * table_numeric))
cosine_scores <- as.matrix(sim) %*% t(as.matrix(sim))
diag(cosine_scores) <- rowMeans(cosine_scores)

most_similar <- max.col(cosine_scores)
most_dissimilar <- max.col(-cosine_scores)

# Get Image Names
get_image_name <- function(pokedex, name) {
  suffix <- tolower(sub("^[^-]*", "", name))
  image_name <- paste0("images/", pokedex, suffix, ".png")
  return(image_name)
}

table$Image.Name <- get_image_name(table$Pokedex, table$Name)

# Combine into one table
table_with_scores <- cbind(table, most_similar, most_dissimilar)
