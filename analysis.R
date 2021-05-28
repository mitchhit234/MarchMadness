# March Madness Analysis

library(RSQLite)
library(ggplot2)
library(GGally)
library(ISLR)
library(stringr)
library(pscl)

#Returns the opposite of the result
flip_result <- function(diff) {
  return((diff+1)%%2)
}

#Calculate the log loss of an individual prediction
#given the prediction probability and the actual result val
log_loss <- function(prediction,val) {
  p1 <- val * log(prediction,exp(1))
  p2 <- (1-val) * log((1-prediction),exp(1))
  return(p1+p2)
}

#Bind lists to a data frame
#All must have the same number of columns
#Makes all frames have the column names of f1
bind <- function(f1,l1,l2,p) {
  t1 <- data.frame(l1)
  t2 <- data.frame(l2)
  colnames(t1) <- p
  colnames(t2) <- p 
  t1 <- rbind(t1,t2)
  f1 <- rbind(f1,t1)
  return(f1)
}


#Used to visualize the probabilities of each 
#Seed match up based on historical data 
probability_matrix <- function(game_table) {
  
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
        #When i and j are equal, and games have 
        #existed where i == j, then we just
        #default the winrate to 50%
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
  return(prob_mat)

}

#Returns dataframe containing log loss per year
#Over the time period specified from beg to end inclusive
loss_over_period <- function(model, beg, end, conn) {
  for (t in beg:end) {
    temp <- dbGetQuery(conn, paste("SELECT seed_diff FROM v3 WHERE year = ", toString(t)))
    cur <- 0

    for(i in temp$seed_diff) {
      p <- predict(log_model, data.frame(seed_diff=i), type="response")
      #All games in database are recorded such that result is 1
      loss <- log_loss(p,1)
      cur <- cur + loss
    }
    #Total average log loss for year t
    tot <- cur / length(temp$seed_diff)

    #Create the data frame if first year calculated
    #Otherwise append to already created frame
    if (t == beg) {
      output <- data.frame(tot)
    }
    else {
      output <- rbind(output,data.frame(tot))
    }
  }
  row.names(output) <- beg:end
  return(output)
}


#The output of this function will provide the 
#data needed for our multipule logisitc regression model
model_dataframe <- function(query) {
  #Initializing the dataframe and column names
  #Each column represents the difference between
  #The winner's rank and loser's rank
  predictors <- list()
  for(i in 1:length(colnames(m))/2) {
    parsed <- str_sub(colnames(m)[i],9)
    predictors[i] = parsed
  }
  predictors[(length(colnames(m))/2)+1] = "result"

  output <- data.frame(matrix(ncol=length(predictors),nrow=0))
  colnames(output) <- predictors

  #Append to our data frame row by row
  #Append a copy to the frame for each row in the 
  #database, one whos result is 1 and another whos is 0
  n <- length(m[,1])
  step <- length(query)/2

  for (i in 1:n) {
    t1 <- list()
    t2 <- list()
    for (j in 1:step) {
      t1[j] <- query[i,j] - query[i,j+step]
      t2[j] <- query[i,j+step] - query[i,j]
    }
    t1[step+1] <- 1
    t2[step+1] <- 0

    output <- bind(output,t1,t2,predictors)
  }
  return(output)
}

#Returns the percentage of games that are predicted 
#correctly, does not account for predicting games
#derived from the current game correctly
games_correct <- function(model, frame) {
  prob <- predict(model, type='response')
  correct <- 0
  for (i in 1:length(prob)) {
    t <- 1
    if (prob[i] < 0.5) {
      t <- 0
    }
    if (t == frame[i,]$result) {
      correct <- correct + 1
    }
  }
  return(correct/length(prob))
}





#Main
conn <- dbConnect(RSQLite::SQLite(), "bracket_data.db")

#Export data from the database needed for our probability matrix
#and our simple logistic regression model
game_table = dbGetQuery(conn, "SELECT winning_seed, losing_seed FROM v3")
r <- dbGetQuery(conn, "SELECT seed_diff, result FROM v3 where year > 2009")

prob_mat <- probability_matrix(game_table)

#All database results are 1, we need to add inverse 
#rows with result 0 as well so the regression model
#doesn't just always output 1
for (i in 1:length(r$seed_diff)) {
  de <- data.frame(-(r[i,1]),flip_result(r[i,2]))
  names(de) <- c("seed_diff","result")
  r <- rbind(r,de)
}

#Model using only seed difference
log_model <- glm(result ~ seed_diff,data=r, family=binomial)

#Plotting our simple logistic regression model
#Can only plot because we have one predictor, won't
#be possible later
M.df <- data.frame(seed_diff = seq(-15,15,0.1))
M.df$result <- predict(log_model,newdata=M.df, type="response")
ggplot(M.df, aes(x=seed_diff,y=result)) + geom_line()
#predict(log_model, data.frame(seed_diff=15), type="response")

#Dataframe formatted in the correct way for our extended model
#Each row represents a game and the columns represent the difference 
#In ranking between the two teams
m <- dbGetQuery(conn, "SELECT * FROM model")
df <- model_dataframe(m)

#Create and inspect the extended model
improved_model <- glm(result~., data=df, family=binomial)
anova(improved_model, test="Chisq")
#test_model <- glm(result~dol+pgh+cng+pom+cng, data=df, family=binomial)
