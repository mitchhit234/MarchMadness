import lxml.html as lh
import requests
from bs4 import BeautifulSoup
from pprint import pprint
import sqlite3


#Individual Game Data
#Seed1, Team1, Sc1, Seed2, Team2, Score2, Location
class Game:
  def __init__(self, s1, t1, sc1, s2, t2, sc2, loc):
    self.seed1, self.team1, self.score1 = s1, t1, sc1
    self.seed2, self.team2, self.score2 = s2, t2, sc2
    self.location = loc

  def winner(self):
    return self.team1 if int(self.score1) > int(self.score2) else self.team2
      
  def margin_of_victory(self):
    return abs(self.score1-self.score2)

  def print(self):
    print("{0} seed {1} scored {2} pts".format(self.seed1,self.team1,self.score1))
    print("{0} seed {1} scored {2} pts".format(self.seed2,self.team2,self.score2))
    print("Location: {0}       Winner: {1}".format(self.location,self.winner()))

#Take HTML text and divide it into individual data points
def parse_bracket(bracket_text):
  divided = bracket_text.split('\n')
  parsed = []
  for cell in divided:
    if check(cell):
      parsed.append(cell)
  return parsed

#Used for parsing html, checks if string contains any information
def check(s):
  for i in s:
    if i.isdigit() or i.isalpha():
      return True
  return False

# Input parsed bracket text
# Outputs a list of all games
# Sorted by region then round (same as website)
def extract_game_data(bracket):
  raw_games = []
  for region in bracket:
    #Game Data comes in blocks of 7
    #Seed1, Team1, Sc1, Seed2, Team2, Score2, Location
    for i in range(7,len(region),7):
      seed1, seed2 = region[i-7], region[i-4]
      team1, team2 = region[i-6], region[i-3]
      score1, score2 = region[i-5], region[i-2]
      location = region[i-1]
      g = Game(seed1, team1, score1, seed2, team2, score2, location)
      raw_games.append(g)
  return raw_games


def index_of_winner(G,team):
  for i in range(len(G)):
    if G[i].winner() == team:
      return i
  return "Error"


def get_seed(G,name):
  for i in G:
    if i.team1 == name:
      return i.seed1
    elif i.team2 == name:
      return i.seed2
  return "Error"


def get_wins(G,name):
  current = 0
  for i in G:
    if i.winner() == name:
      current += 1
  return current
  

def web_specific_sort(G):
  N = []
  N.append(G.pop(0))

  index = 0
  while len(G) > 0:
    current = N[index]
    pop_index = index_of_winner(G,current.team1)
    N.append(G.pop(pop_index))
    pop_index = index_of_winner(G,current.team2)
    N.append(G.pop(pop_index))
    index += 1

  return N



# Resort games from extract_game_data output
# Games are sorted as a binary tree data structure,
# with championship game as the root node
def sort_games(raw_games):
  # Dividing our data into seperate arrays for each
  # Region and Final Four
  rounds = [[] for _ in range(5)]
  counter = 0
  for i in range(len(raw_games)-3):
    cur_bound = 15*counter
    if i < 8+cur_bound:
      rounds[4].append(raw_games[i])
    elif i < 12+cur_bound:
      rounds[3].append(raw_games[i])
    elif i < 14+cur_bound:
      rounds[2].append(raw_games[i])
    else:
      counter += 1
      rounds[1].append(raw_games[i])
  
  # Add the Final Four 
  for i in range(len(raw_games)-1,len(raw_games)-4,-1):
    rounds[0].append(raw_games[i])
  
  # Create a new array with our
  # games sorted as a binary tree
  games = []
  for rd in rounds:
    for game in rd:
      games.append(game)

  # Account for bizaree mistakes in
  # ordering on webpage

  games = web_specific_sort(games)
  
  return games




def database_insertion(B,G,Y,cur):
  Y = str(Y)
  ins = "INSERT INTO "
  vals = "VALUES ("
  table = "TEAM "
  n = "NULL, "
  s = ", "

  #TEAM Table Insetion
  #Done first for foreign key constriants
  d = ['Round of 64', 'Round of 32', 'Sweet 16', 'Elite 8','Final 4', 'Runner Up', 'Champion']
  start_64 = len(B)//2
  for i in range(start_64,len(B)):
    name = B[i]
    seed = str(get_seed(G,B[i]))
    wins = str(get_wins(G,B[i]))
    e = ins + table + vals + f'"{name}"' + s + Y + s
    e += seed + s + wins + s + f'"{d[int(wins)]}"' + ')'
    cur.execute(e)

  #Inserting games into GAME Table
  table = "GAME "
  for i in range(len(G)):
    g = G[i]
    e = ins + table + vals + str(i) + s + Y + s
    e += f'"{g.team1}"' + s + f'"{g.team2}"' + s
    e += str(g.score1) + s + str(g.score2) + s
    e += f'"{g.winner()}"' + ")"
    cur.execute(e)

  #Inserting teams into BRACKET table
  table = "BRACKET "
  for i in range(len(B)):
    name = B[i]
    e = ins + table + vals + str(i) + s 
    e += Y + s +  f'"{name}"' + ')'
    cur.execute(e) 



  #Finishing TEAM Table
  up = 'UPDATE TEAM SET seed = '
  w = 'wins = '
  p = 'placement = '
  wh = ' WHERE name = '





connection = sqlite3.connect('bracket_data.db')
cursor = connection.cursor()
cursor.execute("PRAGMA foreign_keys = ON")

all_years = []

year = 1985

while year < 2020:
  
  URL = 'https://www.sports-reference.com/cbb/postseason/'+str(year)+'-ncaa.html'
  page = requests.get(URL)

  soup = BeautifulSoup(page.content, 'html.parser')
  results = soup.find(id='brackets')
  raw_brackets = results.find_all('div', class_='team16')
  final_four = results.find('div', class_='team4')

  raw_bracket = []
  for i in raw_brackets:
    #Read in bracket by region
    raw_bracket.append(parse_bracket(i.text))
  raw_bracket.append(parse_bracket(final_four.text))

  #Transform data into game data
  raw_games = extract_game_data(raw_bracket)

  # Sort games, index i=0 is the championship game,
  # Play in games are indexes 2i+1 and 2i+2
  games = sort_games(raw_games)


  bracket = []
  for i in games:
    bracket.append(i.winner())

  for i in range(len(games)//2,len(games)):
    bracket.append(games[i].team1)
    bracket.append(games[i].team2)


  database_insertion(bracket,games,year,cursor)

  print(year)
  year += 1



connection.commit()