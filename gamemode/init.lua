AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( 'shared.lua' )

PlayerStuckTable = {}

-- Called when the game is initialised
function GM:initialize()
	timer.Create( "Round Timer" , 240 , 1 , RoundEnd( "HUNTED" ))
end

-- Allows user to pick teams
function GM:PlayerInitialSpawn( ply )
	ply:ConCommand( "team_menu" )
end

-- Assigns different weapons to players dependent on their team
function GM:PlayerLoadout( ply )

	ply:StripWeapons()

	ply:ChatPrint( "Player Loadout Function Called" )

	if ply:Team() ==  1 then
		ply:Give( "weapon_pistol" )
		ply:Give( "weapon_crowbar" )
	elseif ply:Team() == 2 then
		ply:Give( "weapon_ar2" )
		ply:GiveAmmo( 500 , "AR2" , false)
	end
end

-- Is called when a player takes damage
function GM:PlayerHurt(ply , atk)
	ply:SetHealth(100)

	if ply:Team() == 2 and atk:IsPlayer() and atk:Team() == 1 then -- HUNTED attacked by HUNTER
		MakePlayerStuck(ply)
	elseif atk:IsPlayer() and ply:Team() == 2 and atk:Team() == 2 then -- HUNTED attacked by HUNTED
		UnstickPlayer(ply)
	elseif ply:Team() == 1 then -- HUNTER takes damage
		DarkenScreen(ply)
	end
end

-- Switches player to team 1
function team_1(ply)
	ply:SetTeam(1)
	ply:Spawn()
	ply:ChatPrint( ply:Nick().." joined team HUNTERS" )
end
concommand.Add( "team_1" , team_1)

-- Switches player to team 2
function team_2(ply)
	ply:SetTeam(2)
	ply:Spawn()
	ply:ChatPrint( ply:Nick().." joined team HUNTED" )
end
concommand.Add( "team_2" , team_2)

-- Slows the player down massively
function MakePlayerStuck( ply )
	ply:SetWalkSpeed(20)
	ply:SetRunSpeed(20)
	PlayerStuckTable[ ply:UserID() ] = true
	if CheckForWin() then
			RoundEnd( "HUNTERS" )
	end
end
concommand.Add( "stick" , MakePlayerStuck)

-- Usticks  the player ressetting their speed to normal
function UnstickPlayer( ply )
	ply:SetWalkSpeed(250)
	ply:SetRunSpeed(500)
	PlayerStuckTable[ ply:UserID() ] = false
end
concommand.Add( "unstick" , UnstickPlayer)

-- Returns a boolean representative of whether the player is stuck
function IsPlayerStuck( ply )
	return PlayerStuckTable[ ply:UserID() ]
end
concommand.Add( "amistuck" , IsPlayerStuck)

-- Darkens the screen and slows speed when a hunter is hit
function DarkenScreen( ply )
	ply:ScreenFade(2 , Color(0,0,0,100) , 0.1 , 1.5)
	if ply:GetWalkSpeed() > 19 then  ply:SetWalkSpeed(ply:GetWalkSpeed() - 20) end
	if ply:GetRunSpeed() > 19 then  ply:SetRunSpeed(ply:GetRunSpeed() - 20) end
	timer.Create( "SpeedTimer" , 1 , (250 - ply:GetWalkSpeed()) / 5 , function() SpeedTimerCall(ply) end)
end
concommand.Add( "dark" , DarkenScreen )

-- Called to increase the run/walk speed
function SpeedTimerCall( ply )
	ply:SetWalkSpeed( ply:GetWalkSpeed() + 5)
	ply:SetRunSpeed( ply:GetRunSpeed() + 5)
	ply:ChatPrint(ply:GetWalkSpeed())
end

-- Checks if all of the HUNTED are stuck
function CheckForWin()
	for ply in pairs(PlayerStuckTable) do
		if ply == false then return false end
	end
	return true
end

-- Adds the Hunted players to a table with them being unstuck
function AddHuntedToTable(ply)
	table.insert(PlayerStuckTable , ply:UserID() , false)
end
concommand.Add( "AddHunted" , AddHuntedToTable )

-- Called when the round ends
function RoundEnd( winner )
	print( "Round End! "..winner.." Wins!!" )
	timer.Create( "PostGameTimer" , 10 , 1 , function() 
		for x , p in pairs(player.GetHumans()) do 
			SwitchTeam( p )
			UnstickPlayer( p ) 
		end
	end)
end

-- Switches the teams
function SwitchTeam( ply )
	if ply:Team() == 1 then 
		RunConsoleCommand( "team_2" )
	elseif ply:Team() == 2 then 
		RunConsoleCommand( "team_1" )
	end

	ply:ChatPrint( "Teams Switched!" )
end
concommand.Add( "switch" , SwitchTeam)
