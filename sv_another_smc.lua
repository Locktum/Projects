if CLIENT then return end

local folder1 = "another"
local folder2 = folder1 .. "/" .. "smc"

local function Another_SaveEntitiesInFile( ply, data, IsAuto )	
	if !file.Exists( folder1, "DATA" ) then file.CreateDir( folder1 ) end
	if !file.Exists( folder2, "DATA" ) then file.CreateDir( folder2 ) end
	if !file.Exists( folder2 .. "/" .. ply:SteamID64(), "DATA" ) then file.CreateDir( folder2 .. "/" .. ply:SteamID64() ) end
	
	local files, directories = file.Find( folder2 .. "/" .. ply:SteamID64() .. "/*.txt", "DATA" )
	if directories == nil then return end
	
	-- if files == nil then 
		-- file.Write( folder2 .. "/" .. ply:SteamID64() .. "/0.txt", data)
		-- return
	-- end
	
	local prefix = "M"
	
	if IsAuto then
		prefix = "A"
	end
	
	local filename = prefix .. "_-_" ..  os.date( "%Y_%m_%d_-_%H_%M_%S", os.time() )
	
	file.Write( folder2 .. "/" .. ply:SteamID64() .. "/" .. filename .. ".txt", data)
end

local function Another_GetEntitiesFromFile( ply, filename )
	
	if !file.Exists( folder1, "DATA" ) then file.CreateDir( folder1 ) end
	if !file.Exists( folder2, "DATA" ) then file.CreateDir( folder2 )	end
	if !file.Exists( folder2 .. "/" .. ply:SteamID64(), "DATA" ) then file.CreateDir( folder2 .. "/" .. ply:SteamID64() ) end
	
	local data = {}
	
	if filename then
		if file.Exists( filename , "DATA" ) then 
			data = file.Read( filename, "DATA" )
		end
	else
		local files, directories = file.Find( folder2 .. "/" .. ply:SteamID64() .. "/*.txt", "DATA" )
		if not (files or directories) then return data end
		
		data = file.Read( folder2 .. "/" .. ply:SteamID64() .. "/" .. #files - 1 .. ".txt", "DATA" )
	end
	return data
end

-- local function Another_GetLastFilePath( ply )
	
	-- if !file.Exists( folder1, "DATA" ) then file.CreateDir( folder1 ) end
	-- if !file.Exists( folder2, "DATA" ) then file.CreateDir( folder2 )	end
	-- if !file.Exists( folder2 .. "/" .. ply:SteamID64(), "DATA" ) then file.CreateDir( folder2 .. "/" .. ply:SteamID64() ) end
	
	-- local files, directories = file.Find( folder2 .. "/" .. ply:SteamID64() .. "/*.txt", "DATA" )
	-- if not (files or directories) then return end
	
	-- return folder2 .. "/" .. ply:SteamID64() .. "/" .. #files - 1 .. ".txt"
-- end

local saveMaxCount = CreateConVar("another_smc_maxsave", 5, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE}, "Nombre de sauvegarde par joueur.")
local constraints = {Weld=true,  Axis=true, Ballsocket=true, Elastic=true, Hydraulic=true, Motor=true, Muscle=true, Pulley=true, Rope=true, Slider=true, Winch=true}
local plytbl = {}

hook.Add("PlayerInitialSpawn", "Set Timer", function(player)
	player:SetNWInt("another_smc_save", CurTime())
end)

local function CollapseTableToArray( t )
		
	local array = {}
	local q = {}
	local min, max = 0, 0
	
	for k in pairs(t) do
		if not min and not max then min,max = k,k end
		min = (k < min) and k or min
		max = (k > max) and k or max	
	end
	for i=min, max do
		if t[i] then
			array[#array+1] = t[i]
		end
	end

	return array
end

local function PlayerCanDupeCPPI(ply, ent)
	return ent:CPPIGetOwner()==ply and duplicator.IsAllowed(ent:GetClass())
end

local function dummytrace(ent)
	local pos = ent:GetPos()
	return {
		FractionLeftSolid = 0,
		HitNonWorld       = true,
		Fraction          = 0,
		Entity            = ent,
		HitPos            = pos,
		HitNormal         = Vector(0,0,0),
		HitBox            = 0,
		Normal            = Vector(1,0,0),
		Hit               = true,
		HitGroup          = 0,
		MatType           = 0,
		StartPos          = pos,
		PhysicsBone       = 0,
		WorldToLocal      = Vector(0,0,0),
	}
end

local function PlayerCanDupeTool(ply, ent)
	if not duplicator.IsAllowed(ent:GetClass()) then return false end
	local trace = WireLib and dummytrace(ent) or { Entity = ent }
	return hook.Run( "CanTool", ply,  trace, "advdupe2" ) ~= false
end

local function Find(ply)
	local PPCheck = PlayerCanDupeCPPI or PlayerCanDupeTool
	local Entities = ents.GetAll()
	local EntTable = {}
	for _,ent in pairs(Entities) do
		if duplicator.IsAllowed(ent:GetClass()) then
			local trace = WireLib and dummytrace(ent) or { Entity = ent }
			if PPCheck(ply, ent) then
				EntTable[ent:EntIndex()] = ent
			end
		end
	end

	return EntTable
end

local function DoAutosave(ply, IsAuto)
	if (ply) then
		local Entities = Find(ply)
		
		if(table.Count(Entities) == 0)then return end
		
		ply.AnotherAutosave = {}
		ply.AnotherAutosave.HeadEnt = {}
		ply.AnotherAutosave.Entities = {}
		ply.AnotherAutosave.Constraints = {}
		ply.AnotherAutosave.HeadEnt.Index = table.GetFirstKey(Entities)
		ply.AnotherAutosave.HeadEnt.Z = 0
		ply.AnotherAutosave.HeadEnt.Pos = Entities[ply.AnotherAutosave.HeadEnt.Index]:GetPos()
		ply.AnotherAutosave.Entities, ply.AnotherAutosave.Constraints = AdvDupe2.duplicator.AreaCopy(Entities, ply.AnotherAutosave.HeadEnt.Pos, true)
		ply.AnotherAutosave.Constraints = CollapseTableToArray(ply.AnotherAutosave.Constraints)
		
		local stamp = {}
		stamp.name = ply:Nick()
		stamp.time = os.date("%I:%M %p")
		stamp.date = os.date("%d %B %Y")
		stamp.timezone = os.date("%z")
		
		hook.Call("AdvDupe2_StampGenerated",GAMEMODE,stamp)
		
		local Tab = {Entities = ply.AnotherAutosave.Entities, Constraints = ply.AnotherAutosave.Constraints, HeadEnt = ply.AnotherAutosave.HeadEnt, Description=""}
		
		AdvDupe2.Encode( Tab, stamp, function(data)
			Another_SaveEntitiesInFile( ply, data, IsAuto )
		end)

		if IsAuto then
			ply:SendLua([[print("[Another smc] - Sauvegarde Automatique")]])
		else
			ply:SendLua([[print("[Another smc] - Sauvegarde Manuelle")]])
		end
		
		-- PrintMessage(HUD_PRINTTALK, ply:Nick().." - Sauvegarde.")
	end
end

function AdvDupe2.CheckValidDupe(dupe, info)
	
	if not dupe.HeadEnt then return false, "Missing HeadEnt table" end
	if not dupe.HeadEnt.Index then return false, "Missing HeadEnt.Index" end
	if not dupe.HeadEnt.Pos then return false, "Missing HeadEnt.Pos" end
	if not dupe.Entities then return false, "Missing Entities table" end
	if not dupe.Entities[dupe.HeadEnt.Index] then return false, "Missing HeadEnt index from Entities table" end
	if not dupe.Entities[dupe.HeadEnt.Index].PhysicsObjects then return false, "Missing PhysicsObject table from HeadEnt Entity table" end
	if not dupe.Entities[dupe.HeadEnt.Index].PhysicsObjects[0] then return false, "Missing PhysicsObject[0] table from HeadEnt Entity table" end
	if not dupe.Entities[dupe.HeadEnt.Index].PhysicsObjects[0].Pos then return false, "Missing PhysicsObject[0].Pos from HeadEnt Entity table" end
	if not dupe.Entities[dupe.HeadEnt.Index].PhysicsObjects[0].Angle then return false, "Missing PhysicsObject[0].Angle from HeadEnt Entity table" end
	
	return true, dupe
	
end

local function waitQueue(ply, dupedata)
	if(ply.AdvDupe2.Queued)then
		timer.Simple(0.1, function() 
			waitQueue(ply, dupedata) 
		end)
	else
		ply.AdvDupe2 = dupedata
	end
end

local function LoadDupe(ply, filename)
	
	if not IsValid(ply) then return end
	if not Another_GetEntitiesFromFile( ply, filename ) then return end
	
	local data						=	Another_GetEntitiesFromFile( ply, filename )
	local tempdupe					=	ply.AdvDupe2
	local success, dupe, info		=	AdvDupe2.Decode(data)
	
	if not success then 
		PrintMessage(HUD_PRINTTALK, "Could not open ".. filename .." ("..dupe..")")
		return
	end
	
	ply.AnotherAutosave.Name		=	game.GetMap()
	ply.AnotherAutosave.Entities	=	dupe["Entities"]
	ply.AnotherAutosave.Constraints	=	dupe["Constraints"]
	ply.AnotherAutosave.HeadEnt 	=	dupe["HeadEnt"]
	
	if ( not ply.AnotherAutosave or not ply.AnotherAutosave.Entities ) then return false end
	
	local origin = ply.AnotherAutosave.HeadEnt.Pos
	
	ply.AnotherAutosave.HeadEnt.Z	=	origin.Z
	ply.AdvDupe2					=	ply.AnotherAutosave
	
	AdvDupe2.InitPastingQueue(ply, Vector(0,0,0), Angle(0,0,0), origin, true, true, false,true)
	timer.Simple(0.1, function() waitQueue(ply, tempdupe) end)
	
end

----

local math_max = math.max

timer.Remove( "another_smc_timer")
timer.Create( "another_smc_timer", 60, 0, function()
	for _, v in pairs(player.GetHumans())do
		if(CurTime()-v:GetNWInt("another_smc_save", CurTime()) > ( math_max(1, v:GetInfoNum("another_smc_time", 5))-1 ) * 60 && v:GetInfoNum("another_smc_enable", 1) == 1)then
			local files, directories = file.Find( folder2 .. "/" .. v:SteamID64() .. "/*.txt", "DATA" )
			
			
			
			if not files[1] or #files < 20 then
				v:SetNWInt("another_smc_save", CurTime())
				DoAutosave(v, true)
			elseif #files == 20 then
				
				local files, directories = file.Find( folder2 .. "/" .. v:SteamID64() .. "/a_-_*.txt", "DATA", "dateasc" )
				
				file.Delete( folder2 .. "/" .. v:SteamID64() .. "/" .. files[1] )
					
				v:SetNWInt("another_smc_save", CurTime())
				DoAutosave(v, true)
				
			end
		end
	end
end	)

concommand.Add("another_smc_save", function(ply)

	local files, directories = file.Find( folder2 .. "/" .. ply:SteamID64() .. "/*.txt", "DATA" )
	
	if not files[1] or #files < 20 then
		ply:SetNWInt("another_smc_save", CurTime())
		DoAutosave(ply, false)
	else
		return
	end
	
end)

concommand.Add("another_smc_load", function(ply, cmd, args) 

	ply:SendLua([[spawnmenu.ActivateTool("advdupe2")]])
	if(ply.AdvDupe2 && ply.AdvDupe2.Queued)then return end
	
	if(!ply.AdvDupe2)then
		ply.AdvDupe2 = {}
	end
	
	if(ply)then
		if(not ply.AnotherAutosave)then ply.AnotherAutosave = {} end
		
		if ( args and args[1] ) then
			local files, directories = file.Find( folder2 .. "/" .. ply:SteamID64() .. "/*.txt", "DATA" )
			local val = tonumber(args[1]) or  0
			
			if ( val < 1 ) or ( val > #files ) then
				-- ply:ConCommand( "another_smc_print" )
				ply:SendLua([[print("Vous devez mettre un numéro de sauvegarde valide !")]])
				
				return
			end
			
			if file.Exists( folder2 .. "/" .. ply:SteamID64() .. "/" .. files[val], "DATA" ) then 
				LoadDupe(ply, folder2 .. "/" .. ply:SteamID64() .. "/" .. files[val])
				
				-- ply:ConCommand( "another_smc_print" )
			else
				ply:SendLua([[print("Vous devez mettre un numéro de sauvegarde valide !")]])
				-- ply:ConCommand( "another_smc_print" )
			end
		else
			ply:SendLua([[print("Vous devez mettre le numéro de sauvegarde !")]])
			-- ply:ConCommand( "another_smc_print" )
		end
		
	end
	
end )

concommand.Add("another_smc_remove", function(ply, cmd, args) 
	if (ply) then
		if ( args and args[1] ) then
			local files, directories = file.Find( folder2 .. "/" .. ply:SteamID64() .. "/*.txt", "DATA" )
			
			if ( args[1] == "***" ) then
				
				for _, v in pairs(files) do
					file.Delete( folder2 .. "/" .. ply:SteamID64() .. "/" .. v )
				end
				
				-- ply:ConCommand( "another_smc_print" )
				ply:SendLua([[print("Les fichiers ont été supprimés !")]])
				
				return
			end
			
			local val = tonumber(args[1]) or 0
			
			if ( val < 1 ) or ( val > #files ) then
				-- ply:ConCommand( "another_smc_print" )
				ply:SendLua([[print("Vous devez mettre un numéro de sauvegarde valide !")]])
				
				return
			end
			
			if file.Exists( folder2 .. "/" .. ply:SteamID64() .. "/" .. files[val], "DATA" ) then 
				file.Delete( folder2 .. "/" .. ply:SteamID64() .. "/" .. files[val] )
				
				-- ply:ConCommand( "another_smc_print" )
			else
				ply:SendLua([[print("Vous devez mettre un numéro de sauvegarde valide !")]])
				-- ply:ConCommand( "another_smc_print" )
			end
		else
			ply:SendLua([[print("Vous devez mettre le numéro de sauvegarde !")]])
			-- ply:ConCommand( "another_smc_print" )
		end
	end
	
end )

concommand.Add("another_smc_print", function(ply) 

	if (ply) then
		local files, directories = file.Find( folder2 .. "/" .. ply:SteamID64() .. "/*.txt", "DATA" )

		if not files[1] then
			ply:SendLua([[print("Vous n'avez aucune sauvegarde.")]])
			return 
		end
		
		for k, v in pairs(files) do
			ply:SendLua([[print("[]] .. k ..[[] - ]] .. v .. [[")]])
		end
	end
	
end )