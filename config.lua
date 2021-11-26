Config = {}
Config.Locale = "en"
Config.Localization = {
	["en"] = {
		["ENTER_DUNGEON_MENU_TITLE"] = "Select a dungeon to enter",
		["DUNGEON_LABEL"] = "%s - Required (%sx) %s",
		["NOT_ENOUGH_ITEM"] = "You don't have enough item to enter dungeon",
		["LOOT"] = "~b~ E ~s~ Loot",
		["EXIT_DUNGEON"] = "Press E to exit from dungeon",
		["LOBBIES"] = "Lobbies",
		["CREATE_LOBBY"] = "Create Lobby",
		["LEAVE"] = "Leave",
		["DELETE"] = "Delete lobby",
		["JOIN"] = "Join",
		["NO_LOBBY"] = " Looks like none has created a lobby yet.",
		["KICK"] = "Kick",
		["PASS_LEADERSHIP"] = "Pass Leadership",
		["CLOSE"] = "Close",
		["SELECT"] = "Select",
		["START"] = "Start",
		["PASSWORD_INFO"] = "Enter correct password to join lobby",
		["PASSWORD"] = "Password",
		["CONFIRM"] = "Confirm",
		["CANCEL"] = "Cancel",
		["CREATE_LOBBY_INFO"] = "In order to create a lobby you need a key. Also players in the lobby should have the key card otherwise you can't start the dungeon",
		["LOBBY_NAME"] = "Lobby Name",
		["LOBBY_PASSWORD"] = "Lobby Password",
		["PASSWORD_INFO"] = "Leave it empty if you want this lobby accessible to everyone",
		["MAX_PLAYERS"] = "Max Players",
		["MAX_PLAYERS_INFO"] = "Set the maximum lobby players amount between 1-4 this can be changed later",
		["SELECT_DUNGEON"] = "Select a dungeon",
		["LOBBY_FULL"] = "Lobby is full",
		["WRONG_PASSWORD"] = "Wrong Password",
		["ITEM_NOT_EXIST"] = "You can't start the dungeon because doesn't have everyone required item",
		["MISSING_FIELDS"] = "Insufficient information",
		["LOBBY_SETTINGS"] = "Settings",
		["CHANGE_SETTINGS"] = "Change Settings",
		["CHANGE"] = "Change",
		["YOU_FOUND"] = "You found (%sx) %s",
		["FOUND_NOTHING"] = "You found nothing",
		["CANT_OPEN_UI"] = "You can't open the ui while you're in game",
		["CANT_DELETE"] = "You can't delete lobby while lobby in dungeon",
		["CANT_JOIN"] = "You can't join lobby while lobby in dungeon",
		["LIMIT_REACHED"] = "Lobbies number reached to limit you can't create lobby",
        ["REMAIN_HEALTH"] = "Remain Health"
	}
} 

Config.DefaultBossHealth = 1800

-- Trigger your xp handler here if you want to player get xp when kills a zombie
Config.xp = function()
	local xp = math.random(100, 200)
    --TriggerServerEvent('QBCore:Server:AddXp',xp)
end

Config.ZombieAttackDistance =  2.0 -- Zombie attacks the player after this amount of distance
Config.ZombieModels = { -- Default zombie models
    "u_m_y_zombie_01", 
}

Config.ZombieWalks = { -- Default zombie walk types
	"move_m@drunk@verydrunk",
	"move_m@drunk@moderatedrunk",
	"move_m@drunk@a",
	"anim_group_move_ballistic",
	"move_lester_CaneUp",
}






Config.Dungeons = {
	[1] = {
		dungeonLabel = "Facility Dungeon", -- Dungeon label to display on the menu
		spawnCoords = vector4(895.232, -3246.2, -98.255, 83.02), -- First spawn position after the player starts the dungeon, x,y,z,heading
		dungeonHealth = 2,
 		zombieAmounts = 20, -- The amount of zombies to spawn after the player breaks a wall
		requiredItem = { -- Required item to enter the dungeon
			label = "Key", -- Item label to display on the menu
			item = 'bandage', -- Actual item that registered in the database/inventory config
			amount = 2, -- Required item amount to enter the dungeon
		},
		walls = { -- Spawned walls
			[1] = {
				model = GetHashKey("xs_prop_arena_wall_01a"), -- Model of wall
				coords = vector3(896.864, -3245.7, -99.5), -- Coords of wall
				heading = 89.5, -- Heading of wall
				spawnZombiesAfterWallBreaks = true, -- Set this true if you want to spawn zombies after this wall breaks
				netId = nil, -- Don't touch 
				zombiesBaseSpawnCoords = vector3(901.187, -3237.4, -98.294), -- Spawn the zombies in this location after the wall breaks
			},
			[2] = {
				model = GetHashKey("xs_prop_arena_wall_01a"),
				coords = vector3(885.887, -3235.1, -99.5),
				spawnZombiesAfterWallBreaks = true, -- Set this true if you want to spawn zombies after this wall breaks
				netId = nil,
				zombiesBaseSpawnCoords = vector3(882.435, -3244.1, -98.150), -- Spawn the zombies in this location after the wall breaks

				placeGroundAutomaticly = true,
				heading = 279.1,
			},
			[3] = {
				model = GetHashKey("xs_prop_arena_wall_01a"),
				coords = vector3(860.45, -3243.85, -99.5),
				netId = nil,
				placeGroundAutomaticly = true,
				spawnZombiesAfterWallBreaks = false, -- Set this true if you want to spawn zombies after this wall breaks
				heading = 275.29,
			},
			[4] = {
				model = GetHashKey("xs_prop_arena_wall_01a"),
				coords = vector3(873.1398, -3235.767, -99.5),
				netId = nil,
				placeGroundAutomaticly = true,
				spawnZombiesAfterWallBreaks = true, -- Set this true if you want to spawn zombies after this wall breaks
				zombiesBaseSpawnCoords = vector3(868.1707, -3229.592, -98.294), -- Spawn the zombies in this location after the wall breaks
				heading = 181.02,
			},
			[5] = {
				model = GetHashKey("xs_prop_arena_wall_01a"),
				coords = vector3(907.373, -3242.3, -97.330),
				netId = nil,
				placeGroundAutomaticly = true,
				spawnZombiesAfterWallBreaks = true, -- Set this true if you want to spawn zombies after this wall breaks
				zombiesBaseSpawnCoords = vector3(910.323, -3237.2, -98.294), -- Spawn the zombies in this location after the wall breaks
				heading = 82.41,
			},
			[6] = {
				
				model = GetHashKey("xs_prop_arena_wall_01a"),
				coords = vector3(909.879, -3217.8, -99.5),
				netId = nil,
				placeGroundAutomaticly = true,
				spawnZombiesAfterWallBreaks = true, -- Set this true if you want to spawn zombies after this wall breaks
				zombiesBaseSpawnCoords = vector3(911.631, -3225.8, -98.279), -- Spawn the zombies in this location after the wall breaks
				heading = 277.8,
			},
			[7] = {
				
				model = GetHashKey("xs_prop_arena_wall_01a"),
				coords = vector3(909.888, -3218.6, -99.5),
				netId = nil,
				placeGroundAutomaticly = false,
				spawnZombiesAfterWallBreaks = true, -- Set this true if you want to spawn zombies after this wall breaks
				zombiesBaseSpawnCoords = vector3(913.282, -3213.5, -98.248), -- Spawn the zombies in this location after the wall breaks
				heading = 91.55,
			},
			
			[8] = {
				
				model = GetHashKey("xs_prop_arena_wall_01a"),
				coords = vector3(876.325, -3182.40, -97.752),
				netId = nil,
				placeGroundAutomaticly = false,
				spawnZombiesAfterWallBreaks = false, -- Set this true if you want to spawn zombies after this wall breaks
				heading = 269.17,
			},
			[9] = {
				
				model = GetHashKey("xs_prop_arena_wall_01a"),
				coords = vector3(858.776, -3220.3, -99.360),
				netId = nil,
				placeGroundAutomaticly = false,
				spawnZombiesAfterWallBreaks = true, -- Set this true if you want to spawn zombies after this wall breaks
				zombiesBaseSpawnCoords = vector3(912.242, -3217.2, -99.057), -- Spawn the zombies in this location after the wall breaks
				heading = 91.55,
			},	
		},
		boss = {
			model = GetHashKey('hulk'), -- Boss model
			coords = nil, -- Don't touch it'll automaticly select between the coords in "possibleBossLocations" table
			looted = false, -- State of if boss looted or not
			netId = nil, -- Don't touch 
			foundLocation = false, -- State of if boss location found or not
		},
		possibleBossLocations = {
			coords = { -- Possible boss locations after the player start the dungeon
				vector4(834.813, -3236.4, -99.699, 0.0), -- x,y,z,heading 
				vector4(945.246, -3217.3, -99.284, 0.0),
			},
		}
	},
}


Config.loot = {
    minItem = 1,
    maxItem = 4,
    items = {
		-- Change with your items
        [1] = {
            item = "bandage",
            itemlabel = "Bandage",
            minamount = 1,
            maxamount = 2,
            iteminfo = {}, 
            type = "zombie"
        },
       [2] = {
            item = "bandage",
            itemlabel = "Bandage",
            minamount = 1,
            maxamount = 2,
            iteminfo = {}, 
            type = "zombie"
        },
    
        [3] = {
            item = "bandage",
            itemlabel = "Bandage",
            minamount = 1,
            maxamount = 2,
            iteminfo = {}, 
            type = "zombie"
        }, 

        [4] = {
            item = "bandage",
            itemlabel = "Binoculars",
            minamount = 1,
            maxamount = 1,
            iteminfo = {}, 
            type = "zombie"
        },        
        [5] = {
            item = "bandage",
            itemlabel = "bandage",
            minamount = 1,
            maxamount = 1,
            iteminfo = {}, 
            type = "zombie"
        },
        [6] = {
            item = "bandage",
            itemlabel = "Bandage",
            minamount = 1,
            maxamount = 2,
            iteminfo = {}, 
            type = "zombie"
        },
        [7] = {
            item = "bandage",
            itemlabel = "Bandage",
            minamount = 1,
            maxamount = 2,
            iteminfo = {}, 
            type = "zombie"

        },
        [8] = {
            item = "bandage",
            itemlabel = "Bandage",
            minamount = 1,
            maxamount = 2,
            iteminfo = {}, 
            type = "zombie"
        },
        [9] = {
            item = "bandage",
            itemlabel = "Bandage",
            minamount = 1,
            maxamount = 2,
            iteminfo = {}, 
            type = "zombie"
        },





        --- Boss Items

        [10] = {
            item = "bandage",
            itemlabel = "Bandage",
            minamount = 1,
            maxamount = 2,
            iteminfo = {}, 
            type = "boss"
        },
       [11] = {
                item = "bandage",
            itemlabel = "Bandage",
            minamount = 1,
            maxamount = 2,
            iteminfo = {}, 
            type = "boss"
        },
    
        [12] = {
            item = "bandage",
            itemlabel = "Bandage",
            minamount = 1,
            maxamount = 2,
            iteminfo = {}, 
            type = "boss"
        }, 

        [13] = {
            item = "bandage",
            itemlabel = "Binoculars",
            minamount = 1,
            maxamount = 1,
            iteminfo = {}, 
            type = "boss"
        },        
        [14] = {
            item = "bandage",
            itemlabel = "bandage",
            minamount = 1,
            maxamount = 1,
            iteminfo = {}, 
            type = "boss"
        },
        [15] = {
            item = "bandage",
            itemlabel = "Bandage",
            minamount = 1,
            maxamount = 2,
            iteminfo = {}, 
            type = "boss"
        },
        [16] = {
            item = "bandage",
            itemlabel = "Bandage",
            minamount = 1,
            maxamount = 2,
            iteminfo = {}, 
            type = "boss"


        },
        [17] = {
            item = "bandage",
            itemlabel = "Bandage",
            minamount = 1,
            maxamount = 2,
            iteminfo = {}, 
            type = "boss"
        },
        [18] = {
            item = "bandage",
            itemlabel = "Bandage",
            minamount = 1,
            maxamount = 2,
            iteminfo = {}, 
            type = "boss"
        }

    }
}