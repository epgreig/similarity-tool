#!/usr/bin/env Rscript
#
# Recalculates the Results stats in README.md from the current similarity matrix.
# Run after any change to pokemon_data.csv or the similarity pipeline.
#
# Usage: Rscript update_readme_stats.R

library('data.table')

cat("Building similarity matrix...\n")
source('generate_similarity.R')

data <- read.csv('pokemon_data.csv')
data <- data.table(data)
names <- as.character(table_with_scores$Name)
pokedex <- as.integer(data$Pokedex)
n <- length(names)

# Load evolution chain IDs: species_id -> evolution_chain_id
species <- read.csv('pokeapi_data/pokemon_species.csv')
chain_lookup <- setNames(species$evolution_chain_id, species$id)
chain_ids <- as.integer(chain_lookup[as.character(pokedex)])

# Zero out diagonal so self-similarity doesn't interfere
cs <- cosine_scores
diag(cs) <- NA

# Upper triangle for pair-based stats (avoids counting each pair twice)
cs_ut <- cs
cs_ut[!upper.tri(cs)] <- NA
top_idx <- order(cs_ut, decreasing = TRUE, na.last = NA)
bot_idx <- order(cs_ut, decreasing = FALSE, na.last = NA)

# --- Helpers ---
pct <- function(x) sprintf("%.1f%%", x * 100)

# Pick top entries from a ranked index, skipping same-species pairs and
# enforcing one entry per evolutionary line (each chain_id appears at most once
# across both sides of all selected pairs).
pick_pairs <- function(idx, count, filter_fn = NULL) {
  results <- list()
  seen_chains <- integer(0)
  for (k in idx) {
    i <- ((k - 1) %% n) + 1
    j <- ((k - 1) %/% n) + 1
    if (pokedex[i] == pokedex[j]) next
    ci <- chain_ids[i]; cj <- chain_ids[j]
    if (ci %in% seen_chains || cj %in% seen_chains) next
    if (!is.null(filter_fn) && !filter_fn(i, j)) next
    seen_chains <- c(seen_chains, ci, cj)
    results[[length(results) + 1]] <- list(i = i, j = j, val = cs[i, j])
    if (length(results) >= count) break
  }
  results
}

# Pick top entries from a per-Pokemon metric, one per evolutionary line.
pick_single <- function(ord, vals, match_idx, count) {
  results <- list()
  seen_chains <- integer(0)
  for (k in ord) {
    ci <- chain_ids[k]
    if (ci %in% seen_chains) next
    seen_chains <- c(seen_chains, ci)
    results[[length(results) + 1]] <- list(i = k, j = match_idx[k], val = vals[k])
    if (length(results) >= count) break
  }
  results
}

TOP_N <- 5
NOTE <- "_One entry per evolutionary line; different species only for pairs._"

# --- Most Similar Pairs ---
cat(sprintf("\n**Most Similar Pokemon Pairs**\n%s\n\n", NOTE))
pairs <- pick_pairs(top_idx, TOP_N)
for (k in seq_along(pairs)) {
  p <- pairs[[k]]
  cat(sprintf("%d. %s and %s: %s\n", k, names[p$i], names[p$j], pct(p$val)))
}

# --- Most Similar Pairs Who Don't Share a Type ---
no_shared_type <- function(i, j) {
  types_i <- c(as.character(data$Primary.Type[i]), as.character(data$Secondary.Type[i]))
  types_j <- c(as.character(data$Primary.Type[j]), as.character(data$Secondary.Type[j]))
  types_i <- types_i[types_i != ""]
  types_j <- types_j[types_j != ""]
  length(intersect(types_i, types_j)) == 0
}
cat(sprintf("\n**Most Similar Pokemon Who Don't Share a Type**\n%s\n\n", NOTE))
pairs <- pick_pairs(top_idx, TOP_N, filter_fn = no_shared_type)
for (k in seq_along(pairs)) {
  p <- pairs[[k]]
  types_i <- c(as.character(data$Primary.Type[p$i]), as.character(data$Secondary.Type[p$i]))
  types_j <- c(as.character(data$Primary.Type[p$j]), as.character(data$Secondary.Type[p$j]))
  type_str_i <- paste(types_i[types_i != ""], collapse = "/")
  type_str_j <- paste(types_j[types_j != ""], collapse = "/")
  cat(sprintf("%d. %s (%s) and %s (%s): %s\n", k,
              names[p$i], type_str_i, names[p$j], type_str_j, pct(p$val)))
}

# --- Most Dissimilar Pairs ---
cat(sprintf("\n**Most Dissimilar Pokemon Pairs**\n%s\n\n", NOTE))
pairs <- pick_pairs(bot_idx, TOP_N)
for (k in seq_along(pairs)) {
  p <- pairs[[k]]
  cat(sprintf("%d. %s and %s: %s\n", k, names[p$i], names[p$j], pct(p$val)))
}

# --- Most Unique (lowest max similarity with closest match) ---
closest_val <- apply(cs, 1, max, na.rm = TRUE)
closest_idx <- apply(cs, 1, which.max)
unique_ord <- order(closest_val)
cat(sprintf("\n**Most Unique Pokemon** (lowest similarity with closest match)\n%s\n\n", NOTE))
results <- pick_single(unique_ord, closest_val, closest_idx, TOP_N)
for (k in seq_along(results)) {
  r <- results[[k]]
  cat(sprintf("%d. %s: closest match %s w/ %s\n", k, names[r$i], pct(r$val), names[r$j]))
}

# --- Most Generic (highest average similarity) ---
avg_sim <- rowMeans(cs, na.rm = TRUE)
generic_ord <- order(avg_sim, decreasing = TRUE)
cat(sprintf("\n**Most Generic Pokemon** (highest average similarity)\n%s\n\n", NOTE))
results <- pick_single(generic_ord, avg_sim, closest_idx, TOP_N)
for (k in seq_along(results)) {
  r <- results[[k]]
  cat(sprintf("%d. %s: average %s\n", k, names[r$i], pct(r$val)))
}

# --- Least Generic (lowest average similarity) ---
least_generic_ord <- order(avg_sim)
cat(sprintf("\n**Least Generic Pokemon** (lowest average similarity)\n%s\n\n", NOTE))
results <- pick_single(least_generic_ord, avg_sim, closest_idx, TOP_N)
for (k in seq_along(results)) {
  r <- results[[k]]
  cat(sprintf("%d. %s: average %s\n", k, names[r$i], pct(r$val)))
}

cat(sprintf("\n---\nComputed from %d Pokemon\n", n))
