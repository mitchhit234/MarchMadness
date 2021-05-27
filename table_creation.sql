PRAGMA foreign_keys = ON;

CREATE TABLE TEAM (
	name TINYTEXT,
	year SMALLINT UNSIGNED,
	seed TINYINT UNSINGED,
	wins TINYINT UNSIGNED,
	placement TINYTEXT,
	CONSTRAINT CHK_TEAM CHECK (0 < seed < 17 AND wins < 7)
	PRIMARY KEY (name,year)
);


CREATE TABLE GAME (
	bracket_position TINYINT UNSIGNED,
	year SMALLINT UNSIGNED,
	winning_team TINYTEXT NOT NULL,
	losing_team TINYTEXT NOT NULL,
	winning_score TINYINT UNSIGNED NOT NULL,
	losing_score TINYINT UNSIGNED NOT NULL,
	CONSTRAINT FK_GAME_TEAM_1 FOREIGN KEY (winning_team,year) REFERENCES TEAM(name,year),
	CONSTRAINT FK_GAME_TEAM_2 FOREIGN KEY (losing_team,year) REFERENCES TEAM(name,year),
	CONSTRAINT CHK_GAME CHECK (0 <= bracket_position <= 62),
	PRIMARY KEY (bracket_position, year)
);


CREATE TABLE BRACKET (
	spot TINYINT UNSIGNED,
	year SMALLINT UNSIGNED,
	team_name TINYTEXT NOT NULL,
	CONSTRAINT FK_BRACKET_TEAM FOREIGN KEY (team_name,year) REFERENCES TEAM(name,year),
	CONSTRAINT CHK_BRACKET CHECK (spot < 127),
	PRIMARY KEY (spot,year)
);



/*
This part was only used for inital seed only model, not needed for final model 
The SQL for creating ranking columns is in rankings.py
Insertion is done through scripts

CREATE VIEW v1(bracket_position, year, winning_team, winning_seed, winning_bih)
AS
SELECT bracket_position, TEAM.year, winning_team, seed, TEAM.bih FROM GAME INNER JOIN TEAM 
ON (TEAM.name = GAME.winning_team AND TEAM.year = GAME.year) WHERE GAME.year > 2009

CREATE VIEW v2(bracket_position, year, losing_team, losing_seed, losing_bih)
AS
SELECT bracket_position, TEAM.year, losing_team, seed, TEAM.bih FROM GAME INNER JOIN TEAM 
ON (TEAM.name = GAME.losing_team AND TEAM.year = GAME.year) WHERE GAME.year > 2009

CREATE VIEW v3(year, winning_team, losing_team, 
winning_seed, losing_seed, winning_bih, losing_bih, seed_diff, result)
AS 
SELECT v1.year, winning_team, losing_team, winning_seed, 
losing_seed, winning_bih, losing_bih, (winning_seed - losing_seed), 1
FROM v1 INNER JOIN v2
ON (v1.bracket_position = v2.bracket_position AND v1.year = v2.year)
*/