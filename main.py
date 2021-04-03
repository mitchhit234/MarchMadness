import lxml.html as lh
import requests
from bs4 import BeautifulSoup
from pprint import pprint
#pip install mysql-connector-python
#https://computingforgeeks.com/how-to-install-mysql-8-on-fedora/
import mysql.connector

#Individual Game Data
#Seed1, Team1, Sc1, Seed2, Team2, Score2, Location
class Game:
  def __init__(self, s1, t1, sc1, s2, t2, sc2, loc):
    self.seed1, self.team1, self.score1 = s1, t1, sc1
    self.seed2, self.team2, self.score2 = s2, t2, sc2
    self.location = loc

  def winner(self):
    return self.team1 if self.score1 > self.score2 else self.team2
      
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
  
  return games


all_years = []

year = 2015
#while year < 2020:
  
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
# Sort games
games = sort_games(raw_games)

#
bracket = []
for i in games:
  bracket.append(i.winner())

for i in range(len(games)//2,len(games)):
  bracket.append(games[i].team1)
  bracket.append(games[i].team2)



year += 1

