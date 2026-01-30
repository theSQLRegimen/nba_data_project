/*1. The object of this store procedure is to display all players points and 
PRA stats.It will do it in order where the defenses  that has given up the most points comes first.
The procedure will display the PRA (points rebound assist) totals for the players playing 
those teams. A column to include  what is 25% less then that total. */



--CREATE PROCEDURE dbo.sp_get_pra_analysis

ALTER PROCEDURE dbo.sp_get_pra_analysis
    @target_date varchar(45)          -- Input parameter 1
   
AS
BEGIN
    -- Best practice: Prevents "x rows affected" messages from being returned
    SET NOCOUNT ON;

    -- Procedure logic

    WITH TeamAverages AS (
    SELECT 
        def_stat.nba_team_id, 
        team.team_name,
        AVG(def_stat.pts_allowed) AS AvgPtsAllowed
    FROM [nba_stat].[dbo].[defensive_stats] def_stat
    JOIN [nba_stat].[dbo].[nba_teams] team ON team.team_id = def_stat.nba_team_id 
    GROUP BY def_stat.nba_team_id, team.team_name
), 

PlayerPointsTop AS (
SELECT 
    game.nba_team_home_id 'Team_ID_Combined',
    game.game_date as 'Game Date',
    game.game_time as 'Game Time',
    game.game as 'Game Description',
    'Name: ' + players.first_name + ' ' + players.last_name + ' -- ' + home.team_name as 'Player Information',
    stat.pts as 'Points',
    stat.assists as 'Assists',
    stat.rebounds as 'Rebounds',
    stat.pts +  stat.assists + stat.rebounds as 'PRAs',
   (stat.pts + stat.assists + stat.rebounds) - (stat.pts +  stat.assists + stat.rebounds) *.25 as 'PRA 25% contingent',

    RANK() OVER (
        PARTITION BY nba_team_home_id -- Resets the rank for each group in 'grouping_column'
        ORDER BY stat.pts DESC -- Orders the data within each partition (descending for highest value first)
    ) AS 'Points_Rank', away.team_id as 'ID_Team_Player_Playing_Against', away.team_name as 'Team Player Playing Against'
    

FROM [nba_stat].[dbo].[game_schedule] game
LEFT JOIN [nba_stat].[dbo].[nba_teams] home 
    ON game.nba_team_home_id = home.team_id
LEFT JOIN [nba_stat].[dbo].[nba_teams] away 
    ON game.nba_teams_away_id = away.team_id
LEFT JOIN [nba_stat].[dbo].[nba_players] players 
    ON players.nba_team_id = home.team_id
LEFT JOIN [nba_stat].[dbo].[player_stats_agg] stat on players.player_id = stat.player_id
WHERE game.game_date =  @target_date 

union 

SELECT 
    game.nba_teams_away_id,
    game.game_date as 'Game Date',
    game.game_time as 'Game Time',
    game.game as 'Game Description',
    'Name: ' + players.first_name + ' ' + players.last_name + ' -- ' + away.team_name as 'Player Information',
    stat.pts as 'Points',
    stat.assists as 'Assists',
    stat.rebounds as 'Rebounds',
    stat.pts +  stat.assists + stat.rebounds as 'PRAs',
    (stat.pts + stat.assists + stat.rebounds) - (stat.pts +  stat.assists + stat.rebounds) *.25 as 'PRAs 25% contingent',


    
    RANK() OVER (
        PARTITION BY nba_teams_away_id -- Resets the rank for each group in 'grouping_column'
        ORDER BY stat.pts DESC -- Orders the data within each partition (descending for highest value first)
    ) AS 'Points_Rank',   home.team_id as 'ID_Team_Player_Playing_Against', home.team_name as 'Team Player Playing Against'
    
FROM [nba_stat].[dbo].[game_schedule] game
LEFT JOIN [nba_stat].[dbo].[nba_teams] home 
    ON game.nba_team_home_id = home.team_id
LEFT JOIN [nba_stat].[dbo].[nba_teams] away 
    ON game.nba_teams_away_id = away.team_id
LEFT JOIN [nba_stat].[dbo].[nba_players] players 
    ON players.nba_team_id = away.team_id
LEFT JOIN [nba_stat].[dbo].[player_stats_agg] stat on players.player_id = stat.player_id
WHERE game.game_date =  @target_date
)

select [Player Information], 
        Points, 
        Points_Rank,
        PRAs,
        [PRA 25% contingent],
        [Game Description],
        [Team Player Playing Against],
        AvgPtsAllowed
     


from PlayerPointsTop p
join TeamAverages t on t.nba_team_id = p.ID_Team_Player_Playing_Against
where p.Points_Rank in (1,2) 
order by AvgPtsAllowed desc, Points_Rank asc 

      
END
GO