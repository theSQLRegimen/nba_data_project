-- -----------------------------------------------------
-- Database: nba_stat Table to support NBA Stats. Can be used to query stats to determine the progress of players and top performer. 
-- TheSQLRegimen using sql and database design to power analysis
-- Last Updated: 01/09/2026
-- -----------------------------------------------------
-- CREATE DATABASE nba_stat;
-- GO
-- USE nba_stat;
-- GO


IF OBJECT_ID('dbo.player_stats_agg', 'U') IS NOT NULL
    DROP TABLE dbo.player_stats_agg;
GO

IF OBJECT_ID('dbo.player_stats_individual', 'U') IS NOT NULL
    DROP TABLE dbo.player_stats_individual;

GO

IF OBJECT_ID('dbo.defensive_stats', 'U') IS NOT NULL
    DROP TABLE dbo.defensive_stats;
GO

IF OBJECT_ID('dbo.game_schedule', 'U') IS NOT NULL
    DROP TABLE dbo.game_schedule;

GO

IF OBJECT_ID('dbo.nba_players', 'U') IS NOT NULL
    DROP TABLE dbo.nba_players;
GO 

IF OBJECT_ID('dbo.nba_teams', 'U') IS NOT NULL
    DROP TABLE dbo.nba_teams;
GO

CREATE TABLE dbo.nba_teams (
    team_id INT NOT NULL,
    team_name VARCHAR(45) NOT NULL,  -- Full Name Example: Sacramento Kings
    team_name_short VARCHAR(45) NOT NULL,  -- Example: SAC
    PRIMARY KEY (team_id)
);

GO

CREATE TABLE dbo.game_schedule (
    game_id INT NOT NULL,
    game VARCHAR(250) NULL,
    game_date DATE NULL,
    game_time TIME(0) NULL,
    nba_team_home_id INT NOT NULL,
    nba_team_away_id INT NOT NULL,
    PRIMARY KEY (game_id),  -- Changed: game_id is unique, sufficient as PK
    CONSTRAINT fk_game_schedule_nba_teams3 
        FOREIGN KEY (nba_team_home_id) 
        REFERENCES dbo.nba_teams(team_id),
    CONSTRAINT fk_game_schedule_nba_teams1 
        FOREIGN KEY (nba_team_away_id) 
        REFERENCES dbo.nba_teams(team_id)
);

GO

CREATE INDEX idx_game_schedule_home ON dbo.game_schedule(nba_team_home_id);
CREATE INDEX idx_game_schedule_away ON dbo.game_schedule(nba_team_away_id);

GO

CREATE TABLE dbo.nba_players (
    player_id INT NOT NULL,
    first_name VARCHAR(45) NOT NULL,
    last_name VARCHAR(45) NOT NULL,
    jersey_number INT NOT NULL,
    nba_team_id INT NULL,
    injury_status VARCHAR(45) NULL,
    injury_description VARCHAR(250) NULL,
    PRIMARY KEY (player_id),
    CONSTRAINT fk_nba_players_nba_teams 
        FOREIGN KEY (nba_team_id) 
        REFERENCES dbo.nba_teams(team_id)
);

GO

CREATE INDEX idx_nba_players_team ON dbo.nba_players(nba_team_id);

GO

CREATE TABLE dbo.defensive_stats (
    game_id INT NOT NULL,
    nba_team_id INT NOT NULL,
    pts_allowed INT NULL,
    pts INT NULL,
    rebounds INT NULL,
    rebound_allowed INT NULL,
    steals INT NULL,
    assists INT NULL,
    blocks INT NULL,  -- Changed from VARCHAR(45) to INT (blocks should be numeric)
    CONSTRAINT fk_defensive_stats_game_schedule1 
        FOREIGN KEY (game_id) 
        REFERENCES dbo.game_schedule(game_id),
    CONSTRAINT fk_defensive_stats_nba_teams1 
        FOREIGN KEY (nba_team_id) 
        REFERENCES dbo.nba_teams(team_id)
);

GO

CREATE INDEX idx_defensive_stats_team ON dbo.defensive_stats(nba_team_id);
CREATE INDEX idx_defensive_stats_game ON dbo.defensive_stats(game_id);

GO

CREATE TABLE dbo.player_stats_agg (
    player_id INT NOT NULL,
    games_total INT NOT NULL,
    games_started INT NOT NULL,
    pts DECIMAL (10, 2) NULL,
    rebounds DECIMAL (10, 2) NULL,
    steals DECIMAL (10, 2) NULL,
    assists DECIMAL (10, 2) NULL,
    blocks DECIMAL (10, 2) NULL,
    "3point_attempts" DECIMAL (10, 2) NULL,
    "3point_made" DECIMAL (10, 2) NULL,
    minutes_played DECIMAL (10, 2) NULL,
    CONSTRAINT fk_player_stats_nba_players1 
        FOREIGN KEY (player_id) 
        REFERENCES dbo.nba_players(player_id)
);

GO

CREATE TABLE dbo.player_stats_individual (
    player_id INT NOT NULL,
    game_description VARCHAR(250) NULL,
    game_date DATE NULL,
    pts INT NULL,
    rebounds INT  NULL,
    steals INT NULL,
    assists INT NULL,
    blocks INT NULL, 
    "3point_attempts" INT NULL,
    "3point_made" INT NULL,
    minutes_played TIME NULL,
    
    CONSTRAINT fk_player_stats_nba_players2 
        FOREIGN KEY (player_id) 
        REFERENCES dbo.nba_players(player_id)
);

GO

CREATE INDEX idx_player_stats_player ON dbo.player_stats_individual(player_id);
CREATE INDEX idx_player_stats_player2 ON dbo.player_stats_agg(player_id);


GO