#!/usr/bin/env python3
"""
Build pokemon_data.csv from PokeAPI CSV data dump.

Reads CSVs from pokeapi_data/ directory (downloaded from
https://github.com/PokeAPI/pokeapi/tree/master/data/v2/csv)
and joins them into a single flat CSV matching the project's format.

Includes: all Pokemon (fully evolved and NFE), Megas, and alternate forms
with different stats/types (regional forms, Deoxys, Rotom, etc.)
Excludes: Gigantamax forms, cosmetic-only forms.
"""

import csv
import sys
from collections import defaultdict

DATA_DIR = "pokeapi_data"
ENGLISH_LANG_ID = "9"  # language_id for English in PokeAPI

# --- Egg group ID -> CSV display name ---
EGG_GROUP_NAMES = {
    1: "Monster", 2: "Water 1", 3: "Bug", 4: "Flying", 5: "Field",
    6: "Fairy", 7: "Grass", 8: "Human-Like", 9: "Water 3", 10: "Mineral",
    11: "Amorphous", 12: "Water 2", 13: "Ditto", 14: "Dragon", 15: "Undiscovered",
}

# --- Generation ID -> Region name ---
# gen 8 maps to Galar by default; Hisui species are overridden below
GEN_REGION = {
    1: "Kanto", 2: "Johto", 3: "Hoenn", 4: "Sinnoh", 5: "Unova",
    6: "Kalos", 7: "Alola", 8: "Galar", 9: "Paldea",
}

# Species 899-905 are Gen 8 in PokeAPI but originated in Hisui
HISUI_SPECIES = {899, 900, 901, 902, 903, 904, 905}

# --- Stat ID -> name mapping ---
STAT_NAMES = {1: "hp", 2: "attack", 3: "defense", 4: "sp_atk", 5: "sp_def", 6: "speed"}

# --- Forms to EXCLUDE by form_identifier pattern ---
# Gigantamax, totems, cosmetic variants we don't want
EXCLUDED_FORM_PATTERNS = {"gmax", "totem", "starter", "original-cap", "partner-cap",
                           "world-cap", "alola-cap", "kalos-cap", "hoenn-cap",
                           "sinnoh-cap", "unova-cap", "battle-bond"}

# --- Forms to INCLUDE even if is_battle_only or other reasons ---
# These are forms with meaningfully different stats/types that we want
INCLUDED_FORMS_BY_IDENTIFIER = {
    # Deoxys forms
    "attack", "defense", "speed",
    # Rotom forms
    "heat", "wash", "frost", "fan", "mow",
    # Giratina, Shaymin, Tornadus/Thundurus/Landorus/Enamorus
    "origin", "sky", "therian",
    # Meowstic/Indeedee female
    "female",
    # Kyurem fusions
    "white", "black",
    # Aegislash
    "blade",
    # Meloetta
    "pirouette",
    # Hoopa
    "unbound",
    # Lycanroc
    "midnight", "dusk",
    # Wishiwashi
    "school",
    # Minior
    "core", "red-meteor",
    # Oricorio
    "pom-pom", "pau", "sensu",
    # Wormadam
    "sandy", "trash",
    # Gourgeist/Pumpkaboo
    "small", "large", "super",
    # Eiscue
    "noice",
    # Zygarde
    "10", "complete", "10-power-construct", "50-power-construct",
    # Necrozma
    "dusk-mane", "dawn-wings", "ultra",
    # Zacian/Zamazenta
    "crowned",
    # Greninja
    "ash",
    # Ogerpon masks
    "wellspring-mask", "hearthflame-mask", "cornerstone-mask",
    # Terapagos
    "terastal", "stellar",
    # Urshifu
    "rapid-strike",
    # Calyrex (form_identifier is "ice"/"shadow" in PokeAPI, not "ice-rider"/"shadow-rider")
    "ice", "shadow",
    # Ursaluna
    "bloodmoon",
    # Basculegion
    # (female has different stats)
    # Palafin
    "hero",
    # Paldean Tauros breeds
    "paldea-combat-breed", "paldea-blaze-breed", "paldea-aqua-breed",
}

# Regional form prefixes
REGIONAL_FORM_PREFIXES = {"alola", "galar", "hisui", "paldea"}

# Form identifier -> display suffix for Name column
FORM_DISPLAY_NAMES = {
    "mega": "Mega", "mega-x": "Mega X", "mega-y": "Mega Y",
    "primal": "Primal",
    "alola": "Alola", "galar": "Galar", "hisui": "Hisui", "paldea": "Paldea",
    "attack": "Attack", "defense": "Defense", "speed": "Speed",
    "heat": "Heat", "wash": "Wash", "frost": "Frost", "fan": "Fan", "mow": "Mow",
    "origin": "Origin", "sky": "Sky", "therian": "Therian",
    "white": "White", "black": "Black",
    "blade": "Blade", "pirouette": "Pirouette",
    "unbound": "Unbound",
    "midnight": "Midnight", "dusk": "Dusk",
    "school": "School",
    "core": "Core",
    "pom-pom": "Pom-Pom", "pau": "Pa'u", "sensu": "Sensu",
    "sandy": "Sandy", "trash": "Trash",
    "small": "Small", "large": "Large", "super": "Super",
    "noice": "Noice",
    "10": "0.1", "complete": "Complete",
    "10-power-construct": "0.1-Power-Construct", "50-power-construct": "Complete-Power-Construct",
    "dusk-mane": "Dusk Mane", "dawn-wings": "Dawn Wings", "ultra": "Ultra",
    "crowned": "Crowned",
    "ash": "Ash",
    "female": "Female",
    "wellspring-mask": "Wellspring", "hearthflame-mask": "Hearthflame",
    "cornerstone-mask": "Cornerstone",
    "terastal": "Terastal", "stellar": "Stellar",
    "rapid-strike": "Rapid Strike",
    "ice": "Ice Rider", "shadow": "Shadow Rider",
    "bloodmoon": "Bloodmoon",
    "hero": "Hero",
    "paldea-combat-breed": "Paldea", "paldea-blaze-breed": "Paldea-Blaze",
    "paldea-aqua-breed": "Paldea-Aqua",
}

# Region override for specific form identifiers
FORM_REGION_OVERRIDE = {
    "mega": "Kalos", "mega-x": "Kalos", "mega-y": "Kalos", "primal": "Kalos",
    "alola": "Alola", "galar": "Galar", "hisui": "Hisui", "paldea": "Paldea",
    "paldea-combat-breed": "Paldea", "paldea-blaze-breed": "Paldea",
    "paldea-aqua-breed": "Paldea",
    "bloodmoon": "Paldea",
    "wellspring-mask": "Paldea", "hearthflame-mask": "Paldea",
    "cornerstone-mask": "Paldea",
    "terastal": "Paldea", "stellar": "Paldea",
    "ice": "Galar", "shadow": "Galar",
    "rapid-strike": "Galar",
}



def load_csv(filename):
    """Load a CSV file and return a list of dicts."""
    with open(f"{DATA_DIR}/{filename}", "r") as f:
        return list(csv.DictReader(f))


def should_include_form(form_identifier, is_battle_only, is_mega):
    """Decide if an alternate form should be included in the dataset."""
    if not form_identifier:
        return True  # Default form, always include

    # Always exclude Gigantamax and other unwanted patterns
    if form_identifier in EXCLUDED_FORM_PATTERNS:
        return False
    for pattern in EXCLUDED_FORM_PATTERNS:
        if form_identifier.startswith(pattern):
            return False

    # Include Megas
    if is_mega == "1":
        return True

    # Include regional forms
    for prefix in REGIONAL_FORM_PREFIXES:
        if form_identifier == prefix or form_identifier.startswith(prefix + "-"):
            return True

    # Include explicitly listed forms
    if form_identifier in INCLUDED_FORMS_BY_IDENTIFIER:
        return True

    # Exclude everything else (cosmetic forms, battle-only forms we don't want)
    return False


def main():
    # --- Load all data ---
    print("Loading CSV data...")
    species_rows = load_csv("pokemon_species.csv")
    pokemon_rows = load_csv("pokemon.csv")
    stats_rows = load_csv("pokemon_stats.csv")
    types_rows = load_csv("pokemon_types.csv")
    egg_group_rows = load_csv("pokemon_egg_groups.csv")
    species_names_rows = load_csv("pokemon_species_names.csv")
    forms_rows = load_csv("pokemon_forms.csv")

    # --- Build lookup tables ---
    # English species names: species_id -> name
    species_names = {}
    for row in species_names_rows:
        if row["local_language_id"] == ENGLISH_LANG_ID:
            species_names[int(row["pokemon_species_id"])] = row["name"]

    # Species data: species_id -> row
    species = {}
    for row in species_rows:
        species[int(row["id"])] = row

    # Pokemon data: pokemon_id -> row
    pokemon = {}
    for row in pokemon_rows:
        pokemon[int(row["id"])] = row

    # Stats: pokemon_id -> {stat_id: base_stat}
    stats = defaultdict(dict)
    for row in stats_rows:
        stats[int(row["pokemon_id"])][int(row["stat_id"])] = int(row["base_stat"])

    # Types: pokemon_id -> [(slot, type_id)]
    types = defaultdict(list)
    for row in types_rows:
        types[int(row["pokemon_id"])].append((int(row["slot"]), int(row["type_id"])))

    # Egg groups: species_id -> [egg_group_id] (ordered)
    egg_groups = defaultdict(list)
    for row in egg_group_rows:
        egg_groups[int(row["species_id"])].append(int(row["egg_group_id"]))

    # Forms: pokemon_id -> form row
    forms = {}
    for row in forms_rows:
        forms[int(row["pokemon_id"])] = row

    # Type ID -> name
    type_names = {
        1: "Normal", 2: "Fighting", 3: "Flying", 4: "Poison", 5: "Ground",
        6: "Rock", 7: "Bug", 8: "Ghost", 9: "Steel", 10: "Fire", 11: "Water",
        12: "Grass", 13: "Electric", 14: "Psychic", 15: "Ice", 16: "Dragon",
        17: "Dark", 18: "Fairy",
    }

    # --- Build output rows ---
    output = []
    skipped_forms = []

    for poke_id, poke_row in sorted(pokemon.items()):
        species_id = int(poke_row["species_id"])
        spec = species.get(species_id)
        if not spec:
            continue

        # Check form inclusion
        form_row = forms.get(poke_id, {})
        form_identifier = form_row.get("form_identifier", "")
        is_battle_only = form_row.get("is_battle_only", "0")
        is_mega = form_row.get("is_mega", "0")

        if not should_include_form(form_identifier, is_battle_only, is_mega):
            skipped_forms.append(f"  skip: {poke_row['identifier']} (form: {form_identifier})")
            continue

        # --- Assemble row ---
        # Name: use pokemon identifier suffix for uniqueness, with custom display names where available
        base_name = species_names.get(species_id, spec["identifier"].title())
        pokemon_ident = poke_row["identifier"]
        species_ident = spec["identifier"]
        if pokemon_ident != species_ident and pokemon_ident.startswith(species_ident + "-"):
            form_suffix = pokemon_ident[len(species_ident) + 1:]  # e.g. "mega", "mega-z", "original-mega"
            if form_suffix in FORM_DISPLAY_NAMES:
                name = f"{base_name}-{FORM_DISPLAY_NAMES[form_suffix]}"
            else:
                # Generic fallback: title-case the suffix
                name = f"{base_name}-{form_suffix.replace('-', ' ').title().replace(' ', '-')}"
        else:
            name = base_name

        # Height & Weight (from pokemon table, form-specific)
        height = int(poke_row["height"]) / 10  # decimeters -> meters
        weight = int(poke_row["weight"]) / 10  # hectograms -> kg

        # Types (from pokemon_types, form-specific)
        poke_types = sorted(types.get(poke_id, []), key=lambda x: x[0])
        primary_type = type_names.get(poke_types[0][1], "") if len(poke_types) > 0 else ""
        secondary_type = type_names.get(poke_types[1][1], "") if len(poke_types) > 1 else ""

        # Stats (from pokemon_stats, form-specific)
        poke_stats = stats.get(poke_id, {})
        hp = poke_stats.get(1, 0)
        attack = poke_stats.get(2, 0)
        defense = poke_stats.get(3, 0)
        sp_atk = poke_stats.get(4, 0)
        sp_def = poke_stats.get(5, 0)
        speed = poke_stats.get(6, 0)
        total = hp + attack + defense + sp_atk + sp_def + speed

        # Gender (species-level)
        gender_rate = int(spec["gender_rate"])
        if gender_rate == -1:
            male_ratio, female_ratio = 0.0, 0.0
        else:
            female_ratio = (gender_rate / 8) * 100
            male_ratio = 100 - female_ratio

        # Base Happiness (species-level) — careful: 0 is valid, only default when truly empty
        bh = spec["base_happiness"]
        base_happiness = int(bh) if bh != "" else 50

        # Catch Rate (species-level)
        catch_rate = int(spec["capture_rate"]) if spec["capture_rate"] else 45

        # Egg Groups (species-level)
        egs = egg_groups.get(species_id, [])
        primary_egg = EGG_GROUP_NAMES.get(egs[0], "") if len(egs) > 0 else ""
        secondary_egg = EGG_GROUP_NAMES.get(egs[1], "") if len(egs) > 1 else ""

        # Region
        gen_id = int(spec["generation_id"])
        if species_id in HISUI_SPECIES:
            region = "Hisui"
        elif form_identifier in FORM_REGION_OVERRIDE:
            region = FORM_REGION_OVERRIDE[form_identifier]
        else:
            region = GEN_REGION.get(gen_id, f"gen-{gen_id}")

        row = {
            "Pokemon Id": poke_id,
            "Pokedex": species_id,
            "Name": name,
            "Height": height,
            "Weight": weight,
            "Primary Type": primary_type,
            "Secondary Type": secondary_type,
            "Male Ratio": male_ratio,
            "Female Ratio": female_ratio,
            "Base Happiness": base_happiness,
            "Region of Origin": region,
            "Health Stat": hp,
            "Attack Stat": attack,
            "Defense Stat": defense,
            "Special Attack Stat": sp_atk,
            "Special Defense Stat": sp_def,
            "Speed Stat": speed,
            "Base Stat Total": total,
            "Catch Rate": catch_rate,
            "Primary Egg Group": primary_egg,
            "Secondary Egg Group": secondary_egg,
        }


        output.append(row)

    # Sort by Pokedex number, then Name
    output.sort(key=lambda r: (r["Pokedex"], r["Name"]))

    # Write CSV
    fieldnames = [
        "Pokemon Id", "Pokedex", "Name", "Height", "Weight",
        "Primary Type", "Secondary Type",
        "Male Ratio", "Female Ratio", "Base Happiness", "Region of Origin",
        "Health Stat", "Attack Stat", "Defense Stat", "Special Attack Stat",
        "Special Defense Stat", "Speed Stat", "Base Stat Total", "Catch Rate",
        "Primary Egg Group", "Secondary Egg Group"
    ]

    with open("pokemon_data.csv", "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(output)

    print(f"\nWrote {len(output)} Pokemon to pokemon_data.csv")

    # Summary
    megas = sum(1 for r in output if "-Mega" in r["Name"])
    regionals = sum(1 for r in output if any(f"-{x}" in r["Name"]
                    for x in ["Alola", "Galar", "Hisui", "Paldea"]))
    base_forms = len(output) - megas - regionals
    other_forms = len(output) - base_forms - megas - regionals

    gen_counts = defaultdict(int)
    for r in output:
        gen_counts[r["Region of Origin"]] += 1

    print(f"\nBreakdown by region:")
    for region in ["Kanto", "Johto", "Hoenn", "Sinnoh", "Unova", "Kalos",
                    "Alola", "Galar", "Hisui", "Paldea"]:
        if region in gen_counts:
            print(f"  {region}: {gen_counts[region]}")

    if skipped_forms:
        print(f"\nSkipped {len(skipped_forms)} forms (Gmax, cosmetic, etc.)")


if __name__ == "__main__":
    main()
