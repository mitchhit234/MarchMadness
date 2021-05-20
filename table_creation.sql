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
	team1 TINYTEXT NOT NULL,
	team2 TINYTEXT NOT NULL,
	score1 TINYINT UNSIGNED NOT NULL,
	score2 TINYINT UNSIGNED NOT NULL,
	winner BIT NOT NULL,
	CONSTRAINT FK_GAME_TEAM_1 FOREIGN KEY (team1,year) REFERENCES TEAM(name,year),
	CONSTRAINT FK_GAME_TEAM_2 FOREIGN KEY (team2,year) REFERENCES TEAM(name,year),
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





/*SELECT * FROM TEAM
SELECT * FROM GAME
SELECT * FROM BRACKET 
*/