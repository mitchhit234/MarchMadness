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



SELECT bracket_position, TEAM.year, winning_team , losing_team, seed FROM GAME INNER JOIN TEAM 
ON (TEAM.name = GAME.winning_team AND TEAM.year = GAME.year AND TEAM.year = 1985)

SELECT bracket_position, TEAM.year, losing_team, seed FROM GAME INNER JOIN TEAM 
ON (TEAM.name = GAME.losing_team AND TEAM.year = GAME.year AND TEAM.year = 1985)


/*
SELECT * FROM TEAM
SELECT * FROM GAME
SELECT * FROM BRACKET 


DROP TABLE TEAM 
DROP TABLE GAME 
DROP TABLE BRACKET



