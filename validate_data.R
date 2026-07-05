# validate_data.R — sanity checks for the data pipeline.
# Run after rebuilding pokemon_data.csv or changing the similarity code:
#   Rscript validate_data.R
# Exits non-zero on the first failed check.

fail <- function(...) stop(paste0("FAIL: ", ...), call. = FALSE)
pass <- function(...) cat("ok:", ..., "\n")

# --- pokemon_data.csv ---
raw <- read.csv("pokemon_data.csv", check.names = FALSE)

if (nrow(raw) < 1000) fail("only ", nrow(raw), " rows in pokemon_data.csv")
pass(nrow(raw), "rows in pokemon_data.csv")

dupes <- raw$Name[duplicated(raw$Name)]
if (length(dupes) > 0) fail("duplicate names: ", paste(dupes, collapse = ", "))
pass("no duplicate names")

dupe_ids <- raw$`Pokemon Id`[duplicated(raw$`Pokemon Id`)]
if (length(dupe_ids) > 0) fail("duplicate Pokemon Ids: ", paste(dupe_ids, collapse = ", "))
pass("no duplicate Pokemon Ids")

required_numeric <- c("Height", "Weight", "Health Stat", "Attack Stat", "Defense Stat",
                      "Special Attack Stat", "Special Defense Stat", "Speed Stat",
                      "Base Happiness", "Catch Rate", "Male Ratio", "Female Ratio")
for (col in required_numeric) {
  if (any(is.na(raw[[col]]))) fail("NA values in column: ", col)
}
pass("no NAs in numeric columns")

stat_cols <- grep(" Stat$", required_numeric, value = TRUE)
if (any(raw[stat_cols] <= 0)) fail("non-positive base stat found")
pass("all base stats positive")

if (any(raw$`Primary Type` == "" | is.na(raw$`Primary Type`))) fail("row with missing Primary Type")
pass("every row has a Primary Type")

# --- sprites ---
expected_images <- paste0("images/", raw$`Pokemon Id`, ".png")
missing <- expected_images[!file.exists(expected_images)]
if (length(missing) > 0) fail(length(missing), " missing sprites: ", paste(head(missing, 5), collapse = ", "))
pass("a sprite exists for every Pokemon Id")

# --- similarity matrix ---
source("generate_similarity.R")

if (nrow(cosine_scores) != nrow(raw)) fail("score matrix is ", nrow(cosine_scores), "x", ncol(cosine_scores), " but CSV has ", nrow(raw), " rows")
pass("score matrix dimensions match CSV")

if (any(is.na(cosine_scores))) fail("NA values in cosine_scores")
pass("no NAs in score matrix")

asym <- max(abs(cosine_scores - t(cosine_scores)))
if (asym > 1e-8) fail("score matrix not symmetric (max deviation ", asym, ")")
pass("score matrix symmetric")

if (max(abs(diag(cosine_scores) - 1)) > 1e-8) fail("self-similarity is not 1")
pass("self-similarity is 1 for all Pokemon")

if (max(cosine_scores) > 1 + 1e-8 || min(cosine_scores) < -1 - 1e-8) {
  fail("scores outside [-1, 1]: range ", min(cosine_scores), " to ", max(cosine_scores))
}
pass("all scores within [-1, 1]")

# Top-ranked entry for each row must carry that row's maximum score
# (ties are fine: some pairs, e.g. Silcoon/Cascoon, have identical features)
rank1 <- apply(cosine_scores, 1, which.max)
top_of_ranking <- t(apply(cosine_scores, 1, order, decreasing = TRUE))[, 1]
row_idx <- seq_len(nrow(cosine_scores))
if (any(abs(cosine_scores[cbind(row_idx, top_of_ranking)] -
            cosine_scores[cbind(row_idx, rank1)]) > 1e-12)) {
  fail("ranking order disagrees with score matrix")
}
pass("rankings consistent with score matrix")

cat("\nAll checks passed:", nrow(raw), "Pokemon.\n")
