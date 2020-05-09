library('shiny')
library('DT')

source('generate_similarity.R')

data <- read.csv('pokemon_data.csv')
data <- data.table(data)
test_data <- data[,c("Base.Stat.Total", features_stats, features_size, "Base.Happiness", "Male.Ratio", "Female.Ratio", "Catch.Rate"),with=FALSE]

break_points <- function(x) stats::quantile(x, probs = seq(.05, .95, .05), na.rm = TRUE)

red_shade <- function(x) round(seq(0, 255, length.out = (length(x) + 1)/2), 0) %>% {paste0("rgb(255,", ., ",", ., ")")}
green_shade <- function(x) round(seq(255, 0, length.out = (length(x) + 1)/2), 0) %>% {paste0("rgb(", ., ",", "255,", ., ")")}

test_data <- t(test_data)
test_brks <- apply(test_data, 1, break_points)

test_brks[,"Male.Ratio"] <- seq(0,100,length.out = 19)
test_brks[,"Female.Ratio"] <- seq(0,100,length.out = 19)
test_brks[,"Height"] <- seq(0,3,length.out = 19)

red_clrs <- apply(test_brks, 2, red_shade)
green_clrs <- apply(test_brks, 2, green_shade)
test_clrs <- rbind(red_clrs,green_clrs)

rowCallback <- "function(row, data, displayNum, index){"

for(i in 1:ncol(test_data)){
  rowCallback <- c(
    rowCallback,
    sprintf("var value = test_data[%d];", i)
  )
  for(j in 1:nrow(test_data)){
    rowCallback <- c(
      rowCallback, 
      sprintf("if(index === %d){", j),
      sprintf("$('td:eq(%d)',row).css('background-color', %s);", 
              i, styleInterval(test_brks[,j], test_clrs[,j])),
      "}"
    )
  }
}

rowCallback <- c(rowCallback, "}")