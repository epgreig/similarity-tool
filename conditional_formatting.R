library('shiny')
library('DT')

source('generate_similarity.R')

data <- read.csv('pokemon_data.csv')
data <- data.table(data)
test_data <- data[,c("Base.Stat.Total", features_stats, "Base.Stat.Total", features_size, "Base.Happiness", "Male.Ratio", "Female.Ratio", "Catch.Rate"),with=FALSE]
test_data <- t(test_data)

num_brks <- 40
break_points <- function(x) stats::quantile(x, probs = seq(1/num_brks, 1-1/num_brks, 1/1/num_brks), na.rm = TRUE)

brks <- apply(test_data, 1, break_points)

brks[,"Male.Ratio"] <- seq(0,100,length.out = num_brks-1)
brks[,"Female.Ratio"] <- seq(0,100,length.out = num_brks-1)
brks[,"Height"] <- seq(0,3,length.out = num_brks-1)
brks[,"Base.Happiness"] <- seq(0,140,length.out = num_brks-1)

red_clrs_green_seq <- round(seq(70, 235, length.out = num_brks/2), 0)
red_clrs_blue_seq <- round(seq(70, 235, length.out = num_brks/2), 0)
red_clrs <- paste0("rgb(255,", red_clrs_green_seq, ",", red_clrs_blue_seq, ")")

green_clrs_red_seq <- round(seq(235, 70, length.out = num_brks/2), 0)
green_clrs_blue_seq <- round(seq(235, 70, length.out = num_brks/2), 0)
green_clrs <- paste0("rgb(", green_clrs_red_seq, ",", "255,", green_clrs_blue_seq, ")")

clrs <- c(red_clrs,green_clrs)
clrs[num_brks/2] <- "rgb(255,255,240)"
clrs[num_brks/2+1] <- "rgb(255,255,240)"

rowCallback <- "function(row, data, displayNum, index){"

for(i in c(0,1,2)){
  rowCallback <- c(
    rowCallback,
    sprintf("var value = data[%d];", i)
  )
  for(j in 1:nrow(test_data)){
    rowCallback <- c(
      rowCallback,
      sprintf("if(index === %d){", j-1),
      if (j %in% c(1,8))
      {
        sprintf("$('td:eq(%d)',row).css('border-top', '1px solid Gainsboro').css('background-color', %s).css('font-size', '10pt');", 
                i, styleInterval(brks[,j], clrs))
      }
      else if (j != nrow(test_data))
      {
        sprintf("$('td:eq(%d)',row).css('border-top', '1px solid Gainsboro').css('background-color', %s).css('font-size', '11pt');", 
                i, styleInterval(brks[,j], clrs))
      }
      else
      {
        sprintf("$('td:eq(%d)',row).css('border-top', '1px solid Gainsboro').css('border-bottom', '1px solid Gainsboro').css('background-color', %s).css('font-size', '11pt');", 
                i, styleInterval(brks[,j], clrs))
      },
      "}"
    )
  }
}

rowCallback <- c(rowCallback, "}")