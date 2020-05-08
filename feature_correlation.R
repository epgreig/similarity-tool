library('corrplot')

source('generate_similarity.R')

corr_plot <- corrplot(cor(table_numeric), method="circle", type="upper", tl.col="black", diag=FALSE, tl.srt=60, tl.cex = 0.6)

# Notable correlations
corr_plot["Height", "Weight"]
corr_plot["Height", "Health"]
corr_plot["Type_Psychic","Special.Attack"]
corr_plot["Type_Normal","Special.Attack"]
corr_plot["Type_Rock","Defense"]
corr_plot["Type_Rock","Speed"]
corr_plot["Type_Fighting","Male.Dominant"]
corr_plot["Type_Fairy","Female.Dominant"]
corr_plot["Type_Dark","Base.Happiness"]
corr_plot["Base.Happiness", "Weight"]
corr_plot["Base.Happiness", "Female.Dominant"]
corr_plot["Catch.Rate","Special.Attack"]
corr_plot["Catch.Rate","Genderless"]