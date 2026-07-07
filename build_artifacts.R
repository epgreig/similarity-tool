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

source('prepare_app_data.R')       # runs generate_similarity.R once
source('conditional_formatting.R') # reuses its globals; computes brks/clrs

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
  region    = data$Region.of.Origin,
  gen       = unname(region_to_gen[data$Region.of.Origin]),
  height    = data$Height,
  weight    = data$Weight,
  type1     = data$Primary.Type,
  type2     = data$Secondary.Type,
  # conditional_formatting.R re-reads the CSV over prepare_app_data.R's
  # globals, so apply the Undiscovered -> Unknown rename here ourselves
  egg1      = sub("^Undiscovered$", "Unknown", data$Primary.Egg.Group),
  egg2      = data$Secondary.Egg.Group,
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
# test_data row layout in conditional_formatting.R:
# 1 spacer, 2-7 stats, 8 spacer, 9 Height, 10 Weight, 11 spacer,
# 12 Base.Happiness, 13 Catch.Rate
cut_cols <- c(hp = 2, attack = 3, defense = 4, spAttack = 5, spDefense = 6,
              speed = 7, height = 9, weight = 10, happiness = 12, catchRate = 13)
breakpoints <- list(
  colors = clrs,
  cuts = lapply(cut_cols, function(j) unname(brks[, j]))
)
write_json(breakpoints, "docs/data/breakpoints.json", digits = NA)

cat("Wrote docs/data/: similarity_i16.bin (", nrow(cosine_scores), "x",
    ncol(cosine_scores), "int16 ),", nrow(pokemon), "pokemon,",
    length(breakpoints$cuts), "breakpoint sets\n")
