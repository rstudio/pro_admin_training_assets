library(plumber)

m <- readRDS("trained.rds")

#* @apiTitle Predict MPG
#* @apiDescription Awesome model for predicting MPG

#* Predict mpg from hypothetical hp using linear model fitted on mtcars
#* @get /mpg
#* @param new_hp:numeric Horsepower of hypothetical car
#* @response 200 Predicted MPG for supplied HP value
#* @response 400 Bad HP value
#* @response default Predicted MPG for HP of 300
function(new_hp = 300) {
  new_hp = as.numeric(new_hp)
  predict(m, data.frame(hp = new_hp))  
}
