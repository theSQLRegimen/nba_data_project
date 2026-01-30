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
where game_date = '2026-01-14'



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

where game_date = '2026-01-14'

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
WHERE game.game_date = '2026-01-14'

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
WHERE game.game_date = '2026-01-14'

ORDER BY 1, 6

/*4 Of all the players playing on a particular day who has the most average points for that particular team and the second most per team*/

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
WHERE game.game_date = '2026-01-14'

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
WHERE game.game_date = '2026-01-14'
)

select * from PlayerPointsTop
where Points_Rank in (1,2)
order by 4, 7 asc 

/*5. Number of times a Player over a particlar number amount*/

WITH PlayerCount AS (

select players.player_id , players.first_name, players.last_name, count(*) as 'Counts_Above_Value'   
from [nba_stat].[dbo].[nba_players] players
left join [nba_stat].[dbo].[nba_teams] teams on players.nba_team_id = teams.team_id
left join  [nba_stat].[dbo].[player_stats_individual] stat_player on players.player_id = stat_player.player_id
where pts > 25
group by players.player_id, first_name, last_name
),

PlayerCountTotal AS (
select players.player_id, players.first_name, players.last_name, count(*) as 'Total_Count'   
from [nba_stat].[dbo].[nba_players] players
left join [nba_stat].[dbo].[nba_teams] teams on players.nba_team_id = teams.team_id
left join  [nba_stat].[dbo].[player_stats_individual] stat_player on players.player_id = stat_player.player_id
group by players.player_id, first_name, last_name
)

select pc.player_id, pc.first_name, pc.last_name, pc.Counts_Above_value, pct.Total_Count, (CAST(pc.Counts_Above_value AS DECIMAL(10, 2)) / CAST(pct.Total_Count AS DECIMAL(10, 2)) * 100) as pct from PlayerCount pc
left join PlayerCountTotal pct on pc.player_id = pct.player_id
order by 6 desc





