library('data.table')

source('generate_similarity.R')

table <- table_with_scores[,c("Name", "Pokedex", "Image.Name", paste0("V", 1:nrow(table_with_scores))), with=FALSE]
diag(cosine_scores) <- 1

data <- read.csv('pokemon_data.csv')
data <- data.table(data)

# Replace Undiscovered Egg Group with Unknown
levels(data$Primary.Egg.Group) <- c(levels(data$Primary.Egg.Group), "Unknown")
data$Primary.Egg.Group[data$Primary.Egg.Group=="Undiscovered"] <- "Unknown"

# Define function for Gender description
get_gender_summary <- Vectorize(function(male_ratio, female_ratio) {
  if (male_ratio==50) {
    return("50/50")
  }
  else if (male_ratio > female_ratio) {
    return(paste0(round(male_ratio,0), "% Male"))
  }
  else if (female_ratio > male_ratio) {
    return(paste0(round(female_ratio,0), "% Female"))
  }
  else {
    return("Genderless")
  }
})

grid_data <- table[,c("Name")]
grid_data$Type <- ifelse(data$Secondary.Type=="", paste0(data$Primary.Type), paste0(data$Primary.Type, ",<br/>", data$Secondary.Type))
grid_data$Health <- data$Health
grid_data$Attack <- data$Attack
grid_data$Defense <- data$Defense
grid_data$Special.Attack <- data$Special.Attack
grid_data$Special.Defense <- data$Special.Defense
grid_data$Speed <- data$Speed
grid_data$Egg.Group <- ifelse(data$Secondary.Egg.Group=="", paste0(data$Primary.Egg.Group), paste0(data$Primary.Egg.Group, ",<br/>", data$Secondary.Egg.Group))
grid_data$Height <- data$Height
grid_data$Weight <- data$Weight
grid_data$Gender <- get_gender_summary(data$Male.Ratio, data$Female.Ratio)
grid_data$Base.Happiness <- data$Base.Happiness
grid_data$Catch.Rate <- data$Catch.Rate

grid_data$Name <- NULL
grid_data <- as.matrix(grid_data)

grid <- matrix(0, nrow = 13, ncol = 3)
grid[,2] <- c("Type", "Health", "Attack", "Defense", "Sp. Attack",
              "Sp. Defense", "Speed", "Egg Group", "Height (m)", "Weight (kg)",
              "Gender", "Happiness", "Catch Rate")
