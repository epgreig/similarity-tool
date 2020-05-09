library('data.table')

source('generate_similarity.R')

table <- table_with_scores[,c("Name", "Image.Name", "most_similar", "most_dissimilar")]
diag(cosine_scores) <- 1

break_points <- function(x) stats::quantile(x, probs = seq(.05, .95, .05), na.rm = TRUE)
red_shade <- function(x) round(seq(255, 40, length.out = length(x) + 1), 0) %>% {paste0("rgb(255,", ., ",", ., ")")}

grid_data <- table[,c("Name")]
grid_data$Type <- ifelse(data$Secondary.Type=="", paste0(data$Primary.Type), paste0(data$Primary.Type, ", ", data$Secondary.Type))
grid_data$Health <- data$Health
grid_data$Attack <- data$Attack
grid_data$Defense <- data$Defense
grid_data$Special.Attack <- data$Special.Attack
grid_data$Special.Defense <- data$Special.Defense
grid_data$Speed <- data$Speed
grid_data$Height <- data$Height
grid_data$Weight <- data$Weight
grid_data$Base.Happiness <- data$Base.Happiness
grid_data$Male.Ratio <- data$Male.Ratio
grid_data$Female.Ratio <- data$Female.Ratio
grid_data$Catch.Rate <- data$Catch.Rate

grid_data$Name <- NULL
grid_data <- as.matrix(grid_data)

grid <- matrix(0, nrow = 13, ncol = 3)
grid[,2] <- c("Type", "Health", "Attack", "Defense", "Sp. Attack",
              "Sp. Defense", "Speed", "Height (m)", "Weight (kg)",
              "Happiness", "Male %", "Female %", "Catch Rate")

grid[,1] <- grid_data[99,]
grid[,3] <- grid_data[200,]