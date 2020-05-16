library('shiny')
library('DT')

source('generate_similarity.R')

data <- read.csv('pokemon_data.csv')
data <- data.table(data)
test_data <- data[,c("Base.Stat.Total", features_stats, "Base.Stat.Total", features_size, "Base.Happiness", "Male.Ratio", "Female.Ratio", "Catch.Rate"),with=FALSE]
test_data <- t(test_data)

break_points <- function(x) stats::quantile(x, probs = seq(.05, .95, .05), na.rm = TRUE)

red_shade <- function(x) round(seq(100, 255, length.out = (length(x) + 1)/2), 0) %>% {paste0("rgb(255,", ., ",", ., ")")}
green_shade <- function(x) round(seq(255, 100, length.out = (length(x) + 1)/2), 0) %>% {paste0("rgb(", ., ",", "255,", ., ")")}

brks <- apply(test_data, 1, break_points)

brks[,"Male.Ratio"] <- seq(0,100,length.out = 19)
brks[,"Female.Ratio"] <- seq(0,100,length.out = 19)
brks[,"Height"] <- seq(0,3,length.out = 19)
brks[,"Base.Happiness"] <- seq(0,140,length.out = 19)

red_clrs <- apply(brks, 2, red_shade)
green_clrs <- apply(brks, 2, green_shade)
clrs <- rbind(red_clrs,green_clrs)

rowCallback <- "function(row, data, displayNum, index){"

for(i in 0:ncol(test_data)){
  rowCallback <- c(
    rowCallback,
    sprintf("var value = data[%d];", i)
  )
  for(j in 1:nrow(test_data)){
    rowCallback <- c(
      rowCallback, 
      sprintf("if(index === %d){", j-1),
      sprintf("$('td:eq(%d)',row).css('background-color', %s);", 
              i, styleInterval(brks[,j], clrs[,j])),
      "}"
    )
  }
}

rowCallback <- c(rowCallback, "}")