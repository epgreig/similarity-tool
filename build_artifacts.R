# build_artifacts.R — runs the similarity pipeline once and exports the
# static-site data artifacts into docs/data/. Run after any data or
# algorithm change:
#   Rscript build_artifacts.R
#
# Outputs:
#   docs/data/similarity_i16.bin  score*10000 as little-endian int16,
#                                 row-major over the pokemon.json order
#                                 (matrix is symmetric so row/column major
#                                 are equivalent)
#   docs/data/pokemon.json        one object per Pokemon, same order as
#                                 the similarity matrix rows
#   docs/data/breakpoints.json    40 grid colors + 39 quantile cuts per
#                                 colored stat row

library('jsonlite')

source('generate_similarity.R')  # defines data, cosine_scores, features_*

dir.create("docs/data", showWarnings = FALSE, recursive = TRUE)

# --- similarity matrix ---
scores_i16 <- as.integer(round(cosine_scores * 10000))
stopifnot(all(scores_i16 >= -10000 & scores_i16 <= 10000))
con <- file("docs/data/similarity_i16.bin", "wb")
writeBin(scores_i16, con, size = 2, endian = "little")
close(con)

# --- pokemon index ---
region_to_gen <- c(Kanto=1, Johto=2, Hoenn=3, Sinnoh=4, Unova=5,
                   Kalos=6, Alola=7, Galar=8, Hisui=8, Paldea=9)

pokemon <- data.frame(
  id        = data$Pokemon.Id,      # sprite filename: images/{id}.png
  dex       = data$Pokedex,
  name      = data$Name,
  region    = as.character(data$Region.of.Origin),
  gen       = unname(region_to_gen[as.character(data$Region.of.Origin)]),
  height    = data$Height,
  weight    = data$Weight,
  type1     = as.character(data$Primary.Type),
  type2     = as.character(data$Secondary.Type),
  egg1      = sub("^Undiscovered$", "Unknown", data$Primary.Egg.Group),
  egg2      = as.character(data$Secondary.Egg.Group),
  maleRatio   = data$Male.Ratio,
  femaleRatio = data$Female.Ratio,
  hp        = data$Health.Stat,
  attack    = data$Attack.Stat,
  defense   = data$Defense.Stat,
  spAttack  = data$Special.Attack.Stat,
  spDefense = data$Special.Defense.Stat,
  speed     = data$Speed.Stat,
  happiness = data$Base.Happiness,
  catchRate = data$Catch.Rate
)
write_json(pokemon, "docs/data/pokemon.json", dataframe = "rows", digits = NA)

# --- grid color breakpoints ---
# 39 cuts per colored grid row; stats and weight use empirical quantiles,
# height/happiness/catch rate use fixed scales tuned for display
num_brks <- 40
qcuts <- function(x) unname(quantile(x, probs = seq(1/num_brks, 1 - 1/num_brks, 1/num_brks), na.rm = TRUE))

cuts <- list(
  hp        = qcuts(data$Health.Stat),
  attack    = qcuts(data$Attack.Stat),
  defense   = qcuts(data$Defense.Stat),
  spAttack  = qcuts(data$Special.Attack.Stat),
  spDefense = qcuts(data$Special.Defense.Stat),
  speed     = qcuts(data$Speed.Stat),
  height    = seq(0, 3, length.out = num_brks - 1),
  weight    = qcuts(data$Weight),
  happiness = seq(0, 140, length.out = num_brks - 1),
  catchRate = c(seq(0, 45, length.out = num_brks/2), seq(45, 255, length.out = num_brks/2 - 1))
)

# red-to-green ramp through near-white at the middle
ramp <- round(seq(70, 235, length.out = num_brks/2), 0)
clrs <- c(paste0("rgb(255,", ramp, ",", ramp, ")"),
          paste0("rgb(", rev(ramp), ",255,", rev(ramp), ")"))
clrs[num_brks/2]     <- "rgb(255,255,235)"
clrs[num_brks/2 + 1] <- "rgb(255,255,235)"

write_json(list(colors = clrs, cuts = cuts), "docs/data/breakpoints.json", digits = NA)

cat("Wrote docs/data/: similarity_i16.bin (", nrow(cosine_scores), "x",
    ncol(cosine_scores), "int16 ),", nrow(pokemon), "pokemon,",
    length(cuts), "breakpoint sets\n")
