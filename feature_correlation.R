library('corrplot')

source('generate_pokemon_similarity.R')

corr_matrix <- corrplot(cor(table_numeric), method="circle", type="upper", tl.col="black", diag=FALSE, tl.srt=60, tl.cex = 0.6)

# Notable correlations
corr_matrix["Height", "Weight"]
corr_matrix["Height", "Health"]
corr_matrix["Type_Psychic","Special.Attack"]
corr_matrix["Type_Normal","Special.Attack"]
corr_matrix["Type_Rock","Defense"]
corr_matrix["Type_Rock","Speed"]
corr_matrix["Type_Fighting","Male.Dominant"]
corr_matrix["Type_Fairy","Female.Dominant"]
corr_matrix["Type_Dark","Base.Happiness"]
corr_matrix["Base.Happiness", "Weight"]
corr_matrix["Base.Happiness", "Female.Dominant"]
corr_matrix["Catch.Rate","Special.Attack"]
corr_matrix["Catch.Rate","Genderless"]