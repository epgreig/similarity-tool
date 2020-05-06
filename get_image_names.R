library(data.table)

# Import Data
data <- read.csv('pokemon_data.csv')
table <- data.table(data)
table <- table[,c("Pokedex", "Name")]

get_image_name <- function(pokedex, name) {
  suffix <- tolower(sub("^[^-]*", "", name))
  image_name <- paste0(pokedex, suffix, ".png")
  return(image_name)
}

table$Image.Name <- get_image_name(table$Pokedex, table$Name)

#for (filename in table$Image.Name)
#  file.copy(paste0("images/", filename), "images_temp")