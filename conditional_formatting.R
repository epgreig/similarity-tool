source('generate_similarity.R')

test_data <- table_with_scores[,c("Genderless", features_stats, features_size, features_misc),with=FALSE]
test_brks <- brks <- apply(test_data, 2, break_points)

Male.Ratio <- seq(0,100,length.out = 19)
Female.Ratio <- seq(0,100,length.out = 19)
test_brks <- cbind(test_brks,as.matrix(Male.Ratio),as.matrix(Female.Ratio))
colnames(test_brks) <- c("Dummy", features_stats, features_size, features_misc, "Male.Ratio", "Female.Ratio")
test_brks <- test_brks[,c("Dummy", features_stats, features_size, "Base.Happiness", "Male.Ratio", "Female.Ratio", "Catch.Rate")]

red_shade <- function(x) round(seq(0, 255, length.out = (length(x) + 1)/2), 0) %>% {paste0("rgb(255,", ., ",", ., ")")}
green_shade <- function(x) round(seq(255, 0, length.out = (length(x) + 1)/2), 0) %>% {paste0("rgb(", ., ",", "255,", ., ")")}

test_brks <- apply(test_data, 2, break_points)
red_clrs <- apply(test_brks, 2, red_shade)
green_clrs <- apply(test_brks, 2, green_shade)
test_clrs <- rbind(red_clrs,green_clrs)

rowCallback <- "function(row, data, displayNum, index){"

test_data <- t(test_data)
for(i in 1:ncol(test_data)){
  rowCallback <- c(
    rowCallback,
    sprintf("var value = data[%d];", i)
  )
  for(j in 1:nrow(test_data)){
    rowCallback <- c(
      rowCallback, 
      sprintf("if(index === %d){", j-1),
      sprintf("$('td:eq(%d)',row).css('background-color', %s);", 
              i, styleInterval(test_brks[,j], test_clrs[,j])),
      "}"
    )
  }
}