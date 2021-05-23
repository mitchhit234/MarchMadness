# March Madness Analysis

library(RSQLite)
library(ggplot2)
library(GGally)
library(ISLR)

flip_result <- function(diff) {
  return((diff+1)%%2)
}

log_loss <- function(prediction,val) {
  p1 <- val * log(prediction,exp(1))
  p2 <- (1-val) * log((1-prediction),exp(1))
  return(p1+p2)
}

conn <- dbConnect(RSQLite::SQLite(), "bracket_data.db")

dbListTables(conn)

game_table = dbGetQuery(conn, "SELECT winning_seed, losing_seed FROM v3")
t <- dbGetQuery(conn, "SELECT wins, seed FROM TEAM")
r <- dbGetQuery(conn, "SELECT seed_diff, result FROM v3")
o <- dbGetQuery(conn, "SELECT seed_diff FROM v3 WHERE year = 2018")




for (i in 1:length(r$seed_diff)) {
  de <- data.frame(-(r[i,1]),flip_result(r[i,2]))
  names(de) <- c("seed_diff","result")
  r <- rbind(r,de)
}


#ggpairs(t,upper = list(continuous = wrap('cor', size=4)))


log_model <- glm(result ~ seed_diff,data=r, family=binomial)



M.df <- data.frame(seed_diff = seq(-15,15,0.1))

M.df$result <- predict(log_model,newdata=M.df, type="response")

ggplot(M.df, aes(x=seed_diff,y=result)) + geom_line()




predict(log_model, data.frame(seed_diff=15), type="response")




total = 0
total_prob = 0
for (i in 2:16) {
  tot = mat[i,i-1] + mat[i-1,i]
  prob = prob_mat[i,i-1]
  if (!(is.na(prob))){
    total = total + tot
    total_prob = total_prob + (prob * tot)
  }
}

print(total_prob/total)




c <- dbGetQuery(conn, "SELECT seed_diff, result FROM v3")





a <- predict(log_model, data.frame(seed_diff=-11), type="response")


for (t in 1985:2019) {
  o <- dbGetQuery(conn, paste("SELECT seed_diff FROM v3 WHERE year =", toString(t)))
  
  cur <- 0
  for (i in o$seed_diff) {
    p <- predict(log_model, data.frame(seed_diff=i), type="response")
    a <- log_loss(p,1)
    cur <- cur + a
  }
  
  print(t)
  print(cur/length(o$seed_diff))
  
}


























if(FALSE){
  count = 0
  for (i in 1:length(game_table$winning_seed)) {
    if (game_table$winning_seed[i] < game_table$losing_seed[i]) {
      count = count + 1
    }
  }
  print(count/length(game_table$winning_seed))
  
  
  mat <- matrix (0,nrow = 16, ncol = 16)
  
  
  winners = game_table$winning_seed
  losers = game_table$losing_seed
  
  for (i in 1:length(winners)) {
    mat[winners[i],losers[i]] = mat[winners[i],losers[i]] + 1
  }
  
  prob_mat <- matrix(, nrow = 16, ncol = 16)
  
  for(row in 1:16){
    for(col in 1:16){
      if (row == col){
        if (mat[row,col] > 0){
          prob_mat[row,col] = 0.5
        }
      }
      else {
        i = mat[row,col]
        tot = i + mat[col,row]
        if (tot > 0){
          prob_mat[row,col] = round(i/(tot), digits=3)
        }
      }
    }
  }
  
}
