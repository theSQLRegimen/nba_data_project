/* Sample queries against NBA Stat */

/* 1. Basic Query joining the Players to their respective Teams. */

select first_name as 'First Name', 
	   last_name as 'Last Name',
	   jersey_number as 'Jersey Number',
	   team_name as 'Team',
	   team_name_short as 'Team Abbreviated Name'
	  
from [nba_stat].[dbo].[nba_players] players
left join [nba_stat].[dbo].[nba_teams] teams on players.nba_team_id = teams.team_id
order by team_name, last_name asc



/* 2. List of teams playing on a particular day */

select home.team_name as 'Home Team',
	   away.team_name as 'Away Team',
	   game.game_date as 'Game Date',
	   game_time as 'Game Time',
	   game as 'Game Description' 

from [nba_stat].[dbo].[game_schedule] game
left join [nba_stat].[dbo].[nba_teams] home on game.nba_team_home_id = home.team_id
left join [nba_stat].[dbo].[nba_teams] away on game.nba_teams_away_id = away.team_id
where game_date = '2026-01-12'



/* 3. List of teams playing on a particular day and the players playing for that date. */

select home.team_name as 'Home Team',
	   away.team_name as 'Away Team',
	   game.game_date as 'Game Date',
	   game_time as 'Game Time',
	   game as 'Game Description',
	   'Name: ' + players.first_name + ' ' + players.last_name +' -- ' + teams.team_name  as 'Player Information'

from [nba_stat].[dbo].[game_schedule] game
left join [nba_stat].[dbo].[nba_teams] home on game.nba_team_home_id = home.team_id
left join [nba_stat].[dbo].[nba_teams] away on game.nba_teams_away_id = away.team_id
left join [nba_stat].[dbo].[nba_players] players on players.nba_team_id = home.team_id or players.nba_team_id = away.team_id
left join [nba_stat].[dbo].[nba_teams] teams on players.nba_team_id = teams.team_id

where game_date = '2026-01-12'

order by home.team_name

/* 3a List of teams playing on a particular day and the players playing for that date. Performance improvement to query 3. */

SELECT 
    home.team_name as 'Home Team',
    away.team_name as 'Away Team',
    game.game_date as 'Game Date',
    game.game_time as 'Game Time',
    game.game as 'Game Description',
    'Name: ' + players.first_name + ' ' + players.last_name + ' -- ' + home.team_name as 'Player Information'
FROM [nba_stat].[dbo].[game_schedule] game
LEFT JOIN [nba_stat].[dbo].[nba_teams] home 
    ON game.nba_team_home_id = home.team_id
LEFT JOIN [nba_stat].[dbo].[nba_teams] away 
    ON game.nba_teams_away_id = away.team_id
LEFT JOIN [nba_stat].[dbo].[nba_players] players 
    ON players.nba_team_id = home.team_id
WHERE game.game_date = '2026-01-12'

UNION ALL

-- Away team players
SELECT 
    home.team_name,
    away.team_name,
    game.game_date,
    game.game_time,
    game.game,
    'Name: ' + players.first_name + ' ' + players.last_name + ' -- ' + away.team_name
FROM [nba_stat].[dbo].[game_schedule] game
LEFT JOIN [nba_stat].[dbo].[nba_teams] home 
    ON game.nba_team_home_id = home.team_id
LEFT JOIN [nba_stat].[dbo].[nba_teams] away 
    ON game.nba_teams_away_id = away.team_id
LEFT JOIN [nba_stat].[dbo].[nba_players] players 
    ON players.nba_team_id = away.team_id
WHERE game.game_date = '2026-01-12'

ORDER BY 1, 6

/*4 Of all the players playing on a particular day who has the most average points for that particular team*/

WITH PlayerPointsTop AS (
SELECT 
    game.nba_team_home_id 'Team_ID_Combined',
    game.game_date as 'Game Date',
    game.game_time as 'Game Time',
    game.game as 'Game Description',
    'Name: ' + players.first_name + ' ' + players.last_name + ' -- ' + home.team_name as 'Player Information',
    stat.pts as 'Points',
    RANK() OVER (
        PARTITION BY nba_team_home_id -- Resets the rank for each group in 'grouping_column'
        ORDER BY stat.pts DESC -- Orders the data within each partition (descending for highest value first)
    ) AS 'Points_Rank' 
    

FROM [nba_stat].[dbo].[game_schedule] game
LEFT JOIN [nba_stat].[dbo].[nba_teams] home 
    ON game.nba_team_home_id = home.team_id
LEFT JOIN [nba_stat].[dbo].[nba_teams] away 
    ON game.nba_teams_away_id = away.team_id
LEFT JOIN [nba_stat].[dbo].[nba_players] players 
    ON players.nba_team_id = home.team_id
LEFT JOIN [nba_stat].[dbo].[player_stats_agg] stat on players.player_id = stat.player_id
WHERE game.game_date = '2026-01-12'

union 

SELECT 
    game.nba_teams_away_id,
    game.game_date as 'Game Date',
    game.game_time as 'Game Time',
    game.game as 'Game Description',
    'Name: ' + players.first_name + ' ' + players.last_name + ' -- ' + away.team_name as 'Player Information',
    stat.pts as 'Points',
    RANK() OVER (
        PARTITION BY nba_teams_away_id -- Resets the rank for each group in 'grouping_column'
        ORDER BY stat.pts DESC -- Orders the data within each partition (descending for highest value first)
    ) AS 'Points_Rank' 
    
FROM [nba_stat].[dbo].[game_schedule] game
LEFT JOIN [nba_stat].[dbo].[nba_teams] home 
    ON game.nba_team_home_id = home.team_id
LEFT JOIN [nba_stat].[dbo].[nba_teams] away 
    ON game.nba_teams_away_id = away.team_id
LEFT JOIN [nba_stat].[dbo].[nba_players] players 
    ON players.nba_team_id = away.team_id
LEFT JOIN [nba_stat].[dbo].[player_stats_agg] stat on players.player_id = stat.player_id
WHERE game.game_date = '2026-01-12'
)

select * from PlayerPointsTop
where Points_Rank = 1
order by Team_ID_Combined, points desc


