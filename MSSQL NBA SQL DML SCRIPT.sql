/* Sample queries against NBA Stat */

/* 1. Basic Query joining the Players to their respective Teams. */

select first_name as 'First Name', 
	   last_name as 'Last Name',
	   jersey_number as 'Jersye Number',
	   team_name as 'Team',
	   team_name_short as 'Team Abbreviated Name'
	  
from [nba_stat].[dbo].[nba_players] players
left join [nba_stat].[dbo].[nba_teams] teams on players.nba_team_id = teams.team_id
order by team_name, last_name asc



