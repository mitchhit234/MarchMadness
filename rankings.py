import requests
from bs4 import BeautifulSoup
import sqlite3

#Some of the names that are used in the ranking
#webstie are different from the names we scrape from
#the bracket website, even though the teams are the same
#This is what will most likely cause errors in future years
#(A teams ranking in the db will be left NULL)
#If this happens, check name_translation.txt and input the 
#correct translation
def get_translations(filename):
  f = open(filename,'r')
  temp = f.readlines()
  trans = []
  base = []
  for i in temp:
    new = i[:-1].split(',')
    trans.append(new[0])
    base.append(new[1])
  return trans, base

#Some parsing functions used for scrapping and formatting
def remove_from(L,val):
  return [i for i in L if i != val]

def remove_redundant(L):
  return [i for i in L if (len(i) <= 3 or i == 'Rank,')]

def remove_strings(L):
  return [i for i in L if i.isdigit()]

def get_dict(p,L):
  ret = {}
  for i in range(len(p)):
    ret[p[i]] = L[i]
  return ret

#Clean ranking names for db column creation
def clean(e):
  ret = []
  for i in e:
    if i == 'Rank,':
      ret.append('rank')
    else:
      ret.append(i.lower())
  return ret

#All ranks that have data for every team are created as columns
def create_columns(ranks,cur):
  start = "ALTER TABLE TEAM ADD "
  end = " TINYINT UNSIGNED"

  for i in ranks:
    e = start + i + end
    cur.execute(e)

#Check if a team has been in a bracket 
#We don't need their data if they havent
def in_bracket(name,year,cur):
  start = "SELECT * FROM TEAM WHERE name = " + f'"{name}"'
  end = " AND year = " + year 
  e = start + end
  
  cur.execute(e)
  r = cur.fetchall()

  if len(r) > 0:
    return True
  return False


#Reference name_translation.txt if we don't
#immediatley see the team's name in our database
def check_translation(st,t,b):
  if st in b:
    index = b.index(st)
    return t[index]
  return st

#Insert all ranking values after our columns are added
#Don't insert ranking values for teams that arent already
#in the database, we only want teams that are in march madness
def database_insertion(name,year,rankings,p,t,b,cursor):
  year = str(year)
  name = check_translation(name,t,b)
  if in_bracket(name,year,cur):
    
    start = "UPDATE TEAM SET "
    end = " WHERE name = " + f'"{str(name)}"' + " AND year = " + year

    for i in p:
      col_val = rankings[i]
      e = start + i + " = " + col_val + end
      cur.execute(e)


def ranking_string(ranks,typ):
  current = ""
  for i in ranks:
    current += typ + i + ","
  return current

#Views are how we will be parsing the data in our
#datbase to obtain the value differences between two teams
#in a given game
def view_creation(p,year,t,cur):
  start = "CREATE VIEW temp_" + t + "(bracket_position, year, " + t + "_team," + t + "_seed,"
  p2 = ranking_string(p,t+"_")[:-1]
  p3 = ") AS SELECT bracket_position, TEAM.year," + t + "_team, seed,"
  p4 = ranking_string(p,'')[:-1]
  p5 = " FROM GAME INNER JOIN TEAM ON (TEAM.name = GAME." + t + "_team AND TEAM.year = GAME.year)"
  end = " WHERE GAME.year > " + str(year)
  e = start + p2 + p3 + p4 + p5 + end
  cur.execute(e)

#Final view that will have all of the information needed for our model
def model_view(p,t1,t2,cur):
  suffix = t1 + "_seed," 
  start = "CREATE VIEW model(" + suffix
  p2 = ranking_string(p,t1+"_")
  p3 = t2 + "_seed," + ranking_string(p,t2+"_")[:-1]
  p4 = ") AS SELECT " + suffix
  p5 = " FROM temp_" + t1 + " INNER JOIN " + "temp_" + t2
  p6 = " ON (temp_" + t1 + ".bracket_position = temp_" + t2 + ".bracket_position AND temp_" + t1 + ".year = temp_" + t2 + ".year)"
  e = start + p2 + p3 + p4 + p2 + p3 + p5 + p6
  cur.execute(e)



if __name__ == "__main__":

  connection = sqlite3.connect('bracket_data.db')
  cursor = connection.cursor()
  cursor.execute("PRAGMA foreign_keys = ON")

  all_team_names = []
  all_team_rankings = []
  all_p = []

  t,b = get_translations("name_translation.txt")

  for year in range(2010,2020):
    URL = "https://masseyratings.com/cb/arch/compare" + str(year) + "-18.htm"
    page = requests.get(URL)  
    soup = BeautifulSoup(page.content, 'html.parser')
    raw = soup.text

    #Parsing through the format of masseyratings
    start = raw.find('    \n\n ') + 7
    end = raw[start:].find('\n')

    p = raw[start:start+end].split(' ')
    p = remove_from(p,'')
    p = remove_redundant(p)
    
    #Often ranking at the last 7 columns are just left blank?
    #We only want rankings for which all teams have a value
    p = p[:-7]

    #Extracting data from masseyratings
    head = start+end
    tail = (raw[head:].find('---') + head)

    teams = soup.find_all("a", href=lambda href: href and "team.php" in href)

    raw_data = raw[head:tail].split('\n')
    raw_data = remove_from(raw_data,'')

    data = []

    for i in raw_data:
      temp = i.split(' ')
      temp = remove_from(temp,'')
      if temp[0].isdigit():
        temp = remove_strings(temp)
        data.append(temp)


    #Get team name values
    #store them by their overall (AP) ranking
    teams_raw = soup.find_all("a", href=lambda href: href and "team.php" in href)
    teams_raw = teams_raw[:len(data)]
    team_names = []

    for i in teams_raw:
      team_names.append(i.text)

    all_team_names.append(team_names)
    all_team_rankings.append(data)
    all_p.append(p)

  #Only use ranks that have values for every team 
  #These will be the only rankings that we can get for 
  #every team between 2010 and 2020
  elements_in_all = list(set.intersection(*map(set, all_p)))
  elements_in_all = clean(elements_in_all)

  #Start manipulating the SQL database
  create_columns(elements_in_all,cursor)

  #Database insetion by year
  for i in range(10):
    year = i + 2010
    for j in range(len(all_team_rankings[i])):
      ranking_dict = get_dict(elements_in_all,all_team_rankings[i][j])
      team_name = all_team_names[i][j]
      database_insertion(team_name,year,ranking_dict,elements_in_all,t,b,cursor)


  #Finish off with building our view to be used in our model
  t1, t2 = "winning", "losing"
  view_creation(elements_in_all,2009,t1,cursor)
  view_creation(elements_in_all,2009,t2,cursor)
  model_view(elements_in_all,t1,t2,cursor)


  connection.commit()