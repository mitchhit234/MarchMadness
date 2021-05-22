# March Madness Analysis

library(RSQLite)

conn <- dbConnect(RSQLite::SQLite(), "bracket_data.db")

dbListTables(conn)

game_table = dbGetQuery(conn, "SELECT winning_seed, losing_seed FROM v3")

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





