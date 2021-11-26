ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

currentDungeonIndex = nil
insideDungeon = false
Zombies = {}
inCam = false
playerLobby = {}
inLobby = false
lobbies = {}
playerCam = nil
insideWithTeam = false
received = true
playerPrevLocation = nil
isPlayerDead = false


RegisterNetEvent("playerSpawned")
AddEventHandler("playerSpawned", function()
    isPlayerDead = false
end)

AddEventHandler('esx:onPlayerDeath', function(data)
    isPlayerDead = true

end)

function CreationCamHead()
	playerCam = CreateCam('DEFAULT_SCRIPTED_CAMERA')
	local coordsCam = GetOffsetFromEntityInWorldCoords(PlayerPedId(), -1.5, 1.3, 0.65)
	local coordsPly = GetEntityCoords(PlayerPedId())
	SetCamCoord(playerCam, coordsCam)
	PointCamAtCoord(playerCam, coordsPly['x'], coordsPly['y'], coordsPly['z']+0.35)
	SetCamActive(playerCam, true)
	RenderScriptCams(true, true, 1500, true, true)
end

RegisterNUICallback("ready", function(data, cb)
    received = false
end)

Citizen.CreateThread(function()
    while received do
        Citizen.Wait(1000)
        AddRelationshipGroup("dungeon_zombies")
        AddRelationshipGroup("dungeon_boss")
        SetRelationshipBetweenGroups(0, GetHashKey("dungeon_zombies"), GetHashKey("PLAYER"))
        SetRelationshipBetweenGroups(5, GetHashKey("PLAYER"), GetHashKey("dungeon_zombies"))
        SetRelationshipBetweenGroups(0, GetHashKey("dungeon_boss"), GetHashKey("dungeon_zombies"))
        SetRelationshipBetweenGroups(0, GetHashKey("dungeon_zombies"), GetHashKey("dungeon_boss"))
        SetRelationshipBetweenGroups(0, GetHashKey("dungeon_boss"), GetHashKey("PLAYER"))
        SetRelationshipBetweenGroups(5, GetHashKey("PLAYER"), GetHashKey("dungeon_boss"))
        SendNUIMessage({
            type = "SEND_LOCALIZATION",
            localization = Config.Localization[Config.Locale]
        })
    end
end)       

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
         ResetDungeon()
    end
end)

function DeleteDungeonWalls()
    if(IsPlayerDungeonValid())then
        local dungeonData = Config.Dungeons[currentDungeonIndex] 
        for _, wallData in pairs(dungeonData.walls) do
            if NetworkDoesNetworkIdExist(tonumber(wallData.netId))then
                if(DoesEntityExist(NetworkGetEntityFromNetworkId(tonumber(wallData.netId))))then
                    DeleteEntity(NetworkGetEntityFromNetworkId(tonumber(wallData.netId)))
                end
            end
            wallData.netId = nil
        end
    end
end

function CreateDungeonPed(ped)
    while not HasModelLoaded(ped.model) do
        RequestModel(ped.model)
        Citizen.Wait(1) 
    end
    local createdPed = CreatePed(4, ped.model, ped.coords.x, ped.coords.y, ped.coords.z - 1.0, false, true)
    SetEntityHeading(createdPed, ped.heading)
    FreezeEntityPosition(createdPed, true)
    SetEntityInvincible(createdPed, true)
    SetBlockingOfNonTemporaryEvents(createdPed, true)
    ped.ped_handler = createdPed
    SetModelAsNoLongerNeeded(ped.model)
end

function DeletePed(ped)
    if DoesEntityExist(ped.ped_handler) then
        DeleteEntity(ped.ped_handler)
        ped.ped_handler = nil
    end
end

local set = false
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2500)
        if((IsPedDeadOrDying(PlayerPedId()) or isPlayerDead) and not set  and insideDungeon) then
            TriggerServerEvent("lucid-dungeon:OnPlayerDeathInDungeon")
            set = true
        end
    end
end)


RegisterNetEvent("lucid-dungeon:RevivePlayer")
AddEventHandler("lucid-dungeon:RevivePlayer", function()
    Citizen.Wait(4750)
    TriggerEvent("esx_ambulancejob:revive")
    Citizen.Wait(1000)
    if(IsPlayerDungeonValid())then
        local dungeonData = Config.Dungeons[playerLobby.dungeonIndex] 
        SetEntityCoords(PlayerPedId(), dungeonData.spawnCoords.x, dungeonData.spawnCoords.y, dungeonData.spawnCoords.z )
        SetEntityHeading(PlayerPedId(), dungeonData.spawnCoords.w)
    end
    Citizen.Wait(3500)
    set = false
end)

RegisterNetEvent("lucid-dungeon:ResetPlayerDungeon")
AddEventHandler("lucid-dungeon:ResetPlayerDungeon", function()
    ResetAndExitDungeon()
    set = false

end)

local waitTime = 2000
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(waitTime)
        if(IsPlayerDungeonValid())then
            waitTime = 0
            local src =  GetPlayerServerId(PlayerId())
            local player = GetPlayerLobbyInLobby(src)
            if(player)then
                DrawTimerBar(Config.Localization[Config.Locale]["REMAIN_HEALTH"], player.remainHealth, 1)
            end
        else
            waitTime = 2000
        end
    end
end)

function CreateDungeonWalls(isSync)
    Citizen.CreateThread(function()
        if(IsPlayerDungeonValid())then
            local syncData = {}
            local dungeonData = Config.Dungeons[currentDungeonIndex] 
            for j, wallData in pairs(dungeonData.walls) do
                RequestEntityModel(wallData.model)
                local obj = CreateObject(wallData.model, wallData.coords, true, false, false)
                while not DoesEntityExist(obj) do
                    Citizen.Wait(50)
                end
                Citizen.Wait(100)
                local netid = NetworkGetNetworkIdFromEntity(obj)
                NetworkRegisterEntityAsNetworked(obj)
                SetEntityAsMissionEntity(obj, true, true)
                SetNetworkIdCanMigrate(netid,true)
                SetNetworkIdExistsOnAllMachines(netid,true)
                NetworkRequestControlOfEntity(obj)
                while not NetworkDoesNetworkIdExist(netid) do
                    Citizen.Wait(50)
                    netid = NetworkGetNetworkIdFromEntity(obj)
                    NetworkRegisterEntityAsNetworked(obj)
                    SetEntityAsMissionEntity(obj, true, true)
                    SetNetworkIdCanMigrate(netid,true)
                    SetNetworkIdExistsOnAllMachines(netid,true)
                    NetworkRequestControlOfEntity(obj)
                end
                netid = NetworkGetNetworkIdFromEntity(obj)
                table.insert(syncData, {netID = netid, heading = wallData.heading, wallDataIndex = j})
            end
            Citizen.Wait(1700)
     
            TriggerServerEvent("lucid-dungeon:ShareWalls", syncData)
        end
    end)

end

RegisterNetEvent("lucid-dungeon:GetSharedWalls")
AddEventHandler("lucid-dungeon:GetSharedWalls", function(syncData)

    if(IsPlayerDungeonValid())then
        local dungeonData = Config.Dungeons[currentDungeonIndex] 
        if(dungeonData)then
            for _,v in pairs(syncData) do
                if NetworkDoesNetworkIdExist(tonumber(v.netID))then
                    dungeonData.walls[v.wallDataIndex].netId = tonumber(v.netID) 
                    SetEntityHeading(NetworkGetEntityFromNetworkId((tonumber(v.netID))), v.heading)
                    if(dungeonData.walls[v.wallDataIndex].placeGroundAutomaticly)then
                        PlaceObjectOnGroundProperly(NetworkGetEntityFromNetworkId((tonumber(v.netID))))
                    end
                    Citizen.Wait(75)
                end
            end
        end
    end

end)

function SelectBossPosition(bossPositionIndex)
    if(IsPlayerDungeonValid())then
        local dungeonData = Config.Dungeons[currentDungeonIndex] 
        local coordsData = dungeonData.possibleBossLocations.coords
        local selectCoordsIndex = math.random(1, #coordsData)
        local selectedCoords = coordsData[bossPositionIndex and bossPositionIndex or selectCoordsIndex]
        dungeonData.boss.coords = selectedCoords
    end
end

function EnterDungeonAlone(dungeonIndex)
    if(IsPlayerDungeonValid())then
        local dungeonData = Config.Dungeons[dungeonIndex] 
        if(dungeonData)then
            currentDungeonIndex = dungeonIndex
            insideDungeon = true
            SelectBossPosition()
            CreateDungeonWalls()
            SpawnBoss()
            playerPrevLocation = GetEntityCoords(PlayerPedId())
            SetEntityCoords(PlayerPedId(),dungeonData.spawnCoords.x, dungeonData.spawnCoords.y, dungeonData.spawnCoords.z )
            SetEntityHeading(PlayerPedId(), dungeonData.spawnCoords.w)
        end
    end
end

function CreateBossCamera(bossCoords)
    inCam = true
    local cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", bossCoords.x - 5.0, bossCoords.y , bossCoords.z, 0.00, 0.00, -90.00, 50.00, false, 0)
    local cam2 = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", GetEntityCoords(PlayerPedId()).x- 1.9, GetEntityCoords(PlayerPedId()).y ,GetEntityCoords(PlayerPedId()).z + 0.5 ,-10.00,0.00, -90.00, 50.00, false, 0)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 500, true, true)
    SetCamActiveWithInterp(cam2, cam, 6000, true, true)
    Citizen.Wait(5500)  
    RenderScriptCams(false, false, 500, true, true)
    SetCamActive(cam, false)
    DestroyCam(cam, true)
    SetCamActive(cam2, false)
    DestroyCam(cam2, true)
    inCam = false
end

function SpawnZombies(coords)
    if(IsPlayerDungeonValid())then
        local dungeonData = Config.Dungeons[currentDungeonIndex] 
        local player = PlayerPedId()
        for i = 1, dungeonData.zombieAmounts, 1 do
            local randomPed = math.random(1, #Config.ZombieModels)
            local hash = GetHashKey(Config.ZombieModels[randomPed])
            while not HasModelLoaded(hash) do
                RequestModel(hash)  
                Citizen.Wait(50)
            end
            local walk = Config.ZombieWalks[math.random(1, #Config.ZombieWalks)]
            RequestAnimSet(walk)
            while not HasAnimSetLoaded(walk) do
                Citizen.Wait(1)
            end 
            local posX = coords.x
            local posY = coords.y
            local posZ = coords.z 
            if #Zombies < dungeonData.zombieAmounts  then
                local Zombie = CreatePed(4, hash, posX, posY, posZ, 0.0, false, false)
                while not DoesEntityExist(Zombie) do
                    Citizen.Wait(0)
                end
                if DoesEntityExist(Zombie) then  
                    SetPedRagdollBlockingFlags(Zombie, 1)
                    SetRagdollBlockingFlags(Zombie, 1)
                    SetPedSuffersCriticalHits(Zombie, true)
                    TaskSetBlockingOfNonTemporaryEvents(Zombie, true)   
                    SetBlockingOfNonTemporaryEvents(Zombie, true)   
                    SetPedCanRagdollFromPlayerImpact(Zombie, false)
                    SetPedMovementClipset(Zombie, walk, 1.0)
                    TaskWanderStandard(Zombie, 1.0, 10)
                    SetCanAttackFriendly(Zombie, true, true)
                    SetPedCanEvasiveDive(Zombie, false)
                    SetPedRelationshipGroupHash(Zombie, GetHashKey("dungeon_zombies"))
                    SetPedCombatAbility(Zombie, 0)
                    SetPedCombatRange(Zombie,0)
                    SetPedCombatMovement(Zombie, 3)
                    SetPedAlertness(Zombie,3)
                    SetPedIsDrunk(Zombie, true)
                    SetPedConfigFlag(Zombie,100,1)
                    SetPedCanSwitchWeapon(Zombie, false)
                    SetPedAccuracy(Zombie, 70)
                    DisablePedPainAudio(Zombie, true)
                    StopPedSpeaking(Zombie,true)
                    SetPedSeeingRange(Zombie, 1000000.0)
                    SetPedHearingRange(Zombie, 1000000.0)
                    SetEntityInvincible(Zombie, false)
                    SetEntityVisible(Zombie, true)
                    ApplyPedDamagePack(Zombie,"BigHitByVehicle", 0.0, 9.0)
                    ApplyPedDamagePack(Zombie,"SCR_Dumpster", 0.0, 9.0)
                    ApplyPedDamagePack(Zombie,"SCR_Torture", 0.0, 9.0)
                    SetPedCombatAttributes(Zombie, 46, true)
                    TaskGoToEntity(Zombie,player, -1, 0.0, 3.5, 1073741824, 0)
                    table.insert(Zombies, Zombie)
                end
            end
        end
    end
end



function SpawnBoss()
    Citizen.CreateThread(function()
        if(IsPlayerDungeonValid())then
            local syncData = {}
            local dungeonData = Config.Dungeons[currentDungeonIndex]
            local coords = dungeonData.boss.coords
            local hash = dungeonData.boss.model 
            local player = PlayerPedId()
            while not HasModelLoaded(hash) do
                RequestModel(hash)
                Citizen.Wait(1) 
            end
            Citizen.Wait(100)

            local boss = CreatePed(0, hash, coords.x, coords.y, coords.z, 0, true, false)
            while not DoesEntityExist(boss) do
                Citizen.Wait(50)
            end
            local netid = NetworkGetNetworkIdFromEntity(boss)
            NetworkRegisterEntityAsNetworked(boss)
            SetNetworkIdCanMigrate(netid,true)
            SetNetworkIdExistsOnAllMachines(netid,true)
            NetworkRequestControlOfEntity(boss)
            while not NetworkDoesNetworkIdExist(netid)  do
                Citizen.Wait(50)
                netid = NetworkGetNetworkIdFromEntity(boss)
                NetworkRegisterEntityAsNetworked(boss)
    
                SetNetworkIdCanMigrate(netid,true)
                SetNetworkIdExistsOnAllMachines(netid,true)
                NetworkRequestControlOfEntity(boss)
            end


            Citizen.Wait(1700)
            SetPedRagdollBlockingFlags(boss, 1)
            SetRagdollBlockingFlags(boss, 1)
            SetPedSuffersCriticalHits(boss, false)
            TaskSetBlockingOfNonTemporaryEvents(boss, true)   
            SetBlockingOfNonTemporaryEvents(boss, true)   
            SetPedCanRagdollFromPlayerImpact(boss, false)
            SetCanAttackFriendly(boss, true, true)
            SetPedCanEvasiveDive(boss, false)
            SetPedRelationshipGroupHash(boss, GetHashKey("dungeon_zombies"))
            SetPedCombatAbility(boss, 0)
            SetPedCombatRange(boss,0)
            SetPedCombatMovement(boss, 3)
            SetPedAlertness(boss,3)
            SetPedIsDrunk(boss, true)
            SetPedConfigFlag(boss,100,1)
            SetPedCanSwitchWeapon(boss, false)
            SetPedAccuracy(boss, 70)
            DisablePedPainAudio(boss, true)
            StopPedSpeaking(boss,true)
            SetPedSeeingRange(boss, 1000000.0)
            SetPedHearingRange(boss, 1000000.0)
            SetEntityInvincible(boss, false)
            SetPedCanRagdoll(boss, false)
            SetEntityVisible(boss, true)
            ApplyPedDamagePack(boss,"BigHitByVehicle", 0.0, 9.0)
            ApplyPedDamagePack(boss,"SCR_Dumpster", 0.0, 9.0)
            ApplyPedDamagePack(boss,"SCR_Torture", 0.0, 9.0)
            SetPedCombatAttributes(boss, 46, true)
            SetEntityMaxHealth(boss, Config.DefaultBossHealth * #playerLobby.players)
            SetEntityHealth(boss, Config.DefaultBossHealth * #playerLobby.players)
            FreezeEntityPosition(boss, true)
            netid = NetworkGetNetworkIdFromEntity(boss)
            syncData = {netID = netid, heading =  coords.w}
            TriggerServerEvent("lucid-dungeon:ShareBoss", syncData)
            
        end
    end)
  
end

RegisterNetEvent('lucid-dungeon:GetSharedBoss')
AddEventHandler('lucid-dungeon:GetSharedBoss', function(syncData)

    local dungeonData = Config.Dungeons[currentDungeonIndex]
    if(dungeonData)then
        if NetworkDoesNetworkIdExist(tonumber(syncData.netID))then
            dungeonData.boss.netId =  tonumber(syncData.netID)
            local boss = NetworkGetEntityFromNetworkId(tonumber(syncData.netID))
            SetPedRagdollBlockingFlags(boss, 1)
            SetRagdollBlockingFlags(boss, 1)
            SetPedSuffersCriticalHits(boss, false)
            TaskSetBlockingOfNonTemporaryEvents(boss, true)   
            SetBlockingOfNonTemporaryEvents(boss, true)   
            SetPedCanRagdollFromPlayerImpact(boss, false)
            SetCanAttackFriendly(boss, true, true)
            SetPedCanEvasiveDive(boss, false)
            SetPedRelationshipGroupHash(boss, GetHashKey("dungeon_zombies"))
            SetPedCombatAbility(boss, 0)
            SetPedCombatRange(boss,0)
            SetPedCombatMovement(boss, 3)
            SetPedAlertness(boss,3)
            SetPedIsDrunk(boss, true)
            SetPedConfigFlag(boss,100,1)
            SetPedCanSwitchWeapon(boss, false)
            SetPedAccuracy(boss, 70)
            DisablePedPainAudio(boss, true)
            StopPedSpeaking(boss,true)
            SetPedSeeingRange(boss, 1000000.0)
            SetPedHearingRange(boss, 1000000.0)
            SetEntityInvincible(boss, false)
            SetPedCanRagdoll(boss, false)
            SetEntityVisible(boss, true)
            ApplyPedDamagePack(boss,"BigHitByVehicle", 0.0, 9.0)
            ApplyPedDamagePack(boss,"SCR_Dumpster", 0.0, 9.0)
            ApplyPedDamagePack(boss,"SCR_Torture", 0.0, 9.0)
            SetPedCombatAttributes(boss, 46, true)
            SetEntityMaxHealth(boss, Config.DefaultBossHealth * #playerLobby.players)
            SetEntityHealth(boss, Config.DefaultBossHealth * #playerLobby.players)
            
            FreezeEntityPosition(boss, true)
        end
        Citizen.Wait(5000)
        TriggerEvent("lucid-dungeon:SetDungeonLoaded", true)
    end
end)

function DeleteDungeonZombies()
    for _, v in pairs(Zombies) do
        if(v)then
            if(DoesEntityExist(v))then
                DeleteEntity(v)
            end
        end
    end
    Zombies = {}
end

function DeleteDungeonBoss()
    if(IsPlayerDungeonValid())then
        local dungeonData = Config.Dungeons[currentDungeonIndex] 
        local bossEntity = NetworkGetEntityFromNetworkId(tonumber(dungeonData.boss.netId )) 
        dungeonData.boss.foundLocation = false
        dungeonData.boss.netId = nil
        dungeonData.boss.looted = false
        dungeonData.boss.coords = nil

        if(bossEntity)then
            DeleteEntity(bossEntity)
        end
    end
end

function ResetDungeon()
    if(IsPlayerDungeonValid())then
        DeleteDungeonWalls()
        DeleteDungeonZombies()
        DeleteDungeonBoss()
        insideWithTeam = false
        currentDungeonIndex = nil
        insideDungeon = false
        playerPrevLocation = nil
        TriggerServerEvent("lucid-dungeon:OnDungeonFinished")
        TriggerServerEvent('instance:setNamed', 0) 
    end
end

function ExitDungeon()
    if(IsPlayerDungeonValid())then
        DoScreenFadeOut(10)
        SetEntityCoords(PlayerPedId(), playerPrevLocation and playerPrevLocation or vector3(105.360, -638.24, 31.6325))
        Citizen.Wait(1900)
        DoScreenFadeIn(10)
    end
end

function ResetAndExitDungeon()
    ExitDungeon()
    Citizen.Wait(500)
    ResetDungeon()
    NetworkSetFriendlyFireOption(true)
end

function BrutalAttack(entity)
    local pedPos = GetEntityCoords(PlayerPedId())
    local bossPos = GetEntityCoords(entity)
    local dist = #(bossPos - pedPos)
    if(dist > Config.ZombieAttackDistance)then
        local keepLoop = true
        local breakLoop = 25
        while keepLoop do
            Citizen.Wait(300)    
            if(breakLoop == 0)then
                keepLoop = false
            end
            breakLoop = breakLoop - 1
            pedPos = GetEntityCoords(PlayerPedId())                            
            bossPos = GetEntityCoords(entity)      
            if IsPedStill(entity) or IsPedStopped(entity) then
                TaskGoToEntity(entity, PlayerPedId(), -1, Config.ZombieAttackDistance, 1.6, 1073741824.0, 0)
            end                         
            dist = #(bossPos - pedPos)                       
            if dist < Config.ZombieAttackDistance  then
                if not IsEntityDead(entity) then
            
                    TriggerServerEvent("lucid-dungeon:ShareBossBrutalAttack")
                    if not IsPedInAnyVehicle(PlayerPedId(), false) then
                        Citizen.Wait(550)
                    
                        ApplyDamageToPed(PlayerPedId(), 6, false) 

                        local luck = math.random(1, 100)
                        if(luck <= 70)then
                    
                           SetPedToRagdoll(PlayerPedId(), 1000, 1000, 0, 0, 0, 0)
                           SetEntityVelocity(PlayerPedId(), GetEntityForwardVector(entity) * 25.0)
                        end
                    end
                    keepLoop = false
                    Citizen.Wait(1850)                   
                end
            end
        end
    else
        if not IsEntityDead(entity) then
       
            TriggerServerEvent("lucid-dungeon:ShareBossBrutalAttack")
            if not IsPedInAnyVehicle(PlayerPedId(), false) then
                Citizen.Wait(550)

                ApplyDamageToPed(PlayerPedId(), 6, false) 
                local luck = math.random(1, 100)
                if(luck <= 70)then
                
                   SetPedToRagdoll(PlayerPedId(), 1000, 1000, 0, 0, 0, 0)
                   SetEntityVelocity(PlayerPedId(), GetEntityForwardVector(entity) * 25.0)
                end
            end
            Citizen.Wait(1850)
        end
    end
end

RegisterNetEvent("lucid-dungeon:client:ShareBossBrutalAttack")
AddEventHandler("lucid-dungeon:client:ShareBossBrutalAttack", function()
    if(IsPlayerDungeonValid())then

        local dungeonData = Config.Dungeons[currentDungeonIndex] 

        if(not HasAnimDictLoaded("melee@unarmed@streamed_core"))then
            RequestAnimDict("melee@unarmed@streamed_core")
            while not HasAnimDictLoaded("melee@unarmed@streamed_core") do
                Wait(0)
            end
        end
        if NetworkDoesNetworkIdExist(tonumber(dungeonData.boss.netId))then
            TaskPlayAnim(NetworkGetEntityFromNetworkId((tonumber(dungeonData.boss.netId))), "melee@unarmed@streamed_core","light_finishing_punch", 8.0, 1.0, -1, 48, 0.001, false, false, false)
        end
    end

end)


RegisterNetEvent("lucid-dungeon:client:ShareBossGroundAttack")
AddEventHandler("lucid-dungeon:client:ShareBossGroundAttack", function()
    if(IsPlayerDungeonValid())then

        local dungeonData = Config.Dungeons[currentDungeonIndex] 
        local dict = 'melee@unarmed@streamed_core_psycho'
        local anim = 'ground_attack_0_long_psycho'
        if(not HasAnimDictLoaded(dict))then
            RequestAnimDict(dict)
            while not HasAnimDictLoaded(dict) do
                Wait(0)
            end
        end
        if NetworkDoesNetworkIdExist(tonumber(dungeonData.boss.netId))then
            TaskPlayAnim(NetworkGetEntityFromNetworkId((tonumber(dungeonData.boss.netId))), dict, anim, 8.0, 1.0, -1, 48, 0.001, false, false, false)
        end
    end
end)

function GroundAttack(entity)
    TriggerServerEvent("lucid-dungeon:ShareBossGroundAttack")

    if not IsPedInAnyVehicle(PlayerPedId(), false) then
        if(not IsPedJumping(PlayerPedId()))then
           SetPedToRagdoll(PlayerPedId(), 1000, 1000, 0, 0, 0, 0)
           ApplyDamageToPed(PlayerPedId(), 6, false) 
        end
        ParticleEffect('core', 'ent_dst_rocks', 10.0, 1000, entity)
        ParticleEffect('core', 'env_smoke_fbi', 200.0, 1000, entity)
        Citizen.Wait(2800)
    end
end

function OpenDungeonMenu()
    ESX.UI.Menu.CloseAll()
    local elements = {}
    for _, v in pairs(Config.Dungeons) do
        table.insert(elements, {
            label = string.format(Config.Localization[Config.Locale]["DUNGEON_LABEL"], v.dungeonLabel, v.requiredItem.amount, v.requiredItem.label),
            dungeonIndex = _,
        })
    end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'enter_dungeon', {
		title    = Config.Localization[Config.Locale]["ENTER_DUNGEON_MENU_TITLE"],
		align    = 'center',
		elements = elements
	}, function(data, menu)
        local currentDungeonIndex = data.current.dungeonIndex
        if(currentDungeonIndex)then
            local currentDungeonData = Config.Dungeons[currentDungeonIndex]
            if(currentDungeonData)then
                ESX.TriggerServerCallback("lucid-dungeon:CheckPlayerItemAndRemove", function(success) 
                    if(success)then
                        EnterDungeonAlone(currentDungeonIndex)
                    else
                        ESX.ShowNotification(Config.Localization[Config.Locale]["NOT_ENOUGH_ITEM"])
                    end
                end, currentDungeonData.requiredItem)
            end   
        end
	end, function(data, menu)
		menu.close()
	end)
end


local time = 750
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(time)
        if(insideDungeon)then
            if(IsPlayerDungeonValid())then
                local dungeonData = Config.Dungeons[currentDungeonIndex] 
                if NetworkDoesNetworkIdExist(tonumber(dungeonData.boss.netId))then
                    if( dungeonData.boss.foundLocation)then
                        BossAttack(NetworkGetEntityFromNetworkId((tonumber(dungeonData.boss.netId))))
                    end
                end
            end
        end
    end
end)


function BossAttack(bossEntity)

    if(not IsEntityDead(PlayerPedId()) and not isPlayerDead and IsPlayerDungeonValid())then
        local dungeonData = Config.Dungeons[currentDungeonIndex] 
        if(dungeonData)then
            if bossEntity ~= nil and not inCam  then
                time = 750
                local pedPos = GetEntityCoords(PlayerPedId())
                local bossPos = GetEntityCoords(bossEntity)
                if(not IsEntityDead(bossEntity))then
                    local dist = #(bossPos - pedPos)
                    if IsPedStill(bossEntity) or IsPedStopped(bossEntity) then
                        TaskGoToEntity(bossEntity, PlayerPedId(), -1, Config.ZombieAttackDistance, 1.6, 1073741824.0, 0)
                    end     
     
                    TriggerServerEvent("lucid-dungeon:ShareAttack")
                    Citizen.Wait(6550)
                else
                    time = 0
                    if(not dungeonData.boss.looted)then
                        DrawText3D(bossPos.x, bossPos.y, bossPos.z, Config.Localization[Config.Locale]["LOOT"])
                        if(IsControlJustPressed(0, 38))then
                            dungeonData.boss.looted = true
                            TriggerServerEvent('lucid-dungeon:server:loot', 'boss')
                            Citizen.Wait(600)

                        end
                    else
                        DrawText3D(pedPos.x, pedPos.y, pedPos.z, Config.Localization[Config.Locale]["EXIT_DUNGEON"])
                        if(IsControlJustPressed(0, 38))then
                            ResetAndExitDungeon()
                        end
                    end
                end
            else
                time = 750
            end
        end
    end
end

RegisterNetEvent('lucid-dungeon:GetSharedAttacks')
AddEventHandler('lucid-dungeon:GetSharedAttacks', function(attackType)
    if IsPlayerDungeonValid() then
        local dungeonData = Config.Dungeons[currentDungeonIndex] 
    
        if(attackType <= 7)then
            BrutalAttack(NetworkGetEntityFromNetworkId((tonumber(dungeonData.boss.netId))))
        else
            GroundAttack(NetworkGetEntityFromNetworkId((tonumber(dungeonData.boss.netId))))
        end
    end

end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(400)
        if(not IsEntityDead(PlayerPedId()) and not isPlayerDead)then
            for i = 1, #Zombies do
                if Zombies[i] ~= nil then
                    local distTarget = 40.0
                    local pedPos = GetEntityCoords(PlayerPedId())
                    local zombiePos = GetEntityCoords(Zombies[i])
                    local dist = #(zombiePos - pedPos)
                    if IsPedStill(Zombies[i]) or IsPedStopped(Zombies[i]) then
                       if dist < distTarget then
                           if dist >= Config.ZombieAttackDistance then
                                print("here")
                                TaskGoStraightToCoord(Zombies[i], pedPos.x, pedPos.y, pedPos.z, 2.0, -1, 0.0, 0.0)
                           end
                       else
                           if dist >= Config.ZombieAttackDistance  then
                                print("here 2")
                                TaskGoStraightToCoord(Zombies[i], pedPos.x, pedPos.y, pedPos.z, 2.0, -1, 0.0, 0.0)

                           end
                       end
                    end               
                    if dist < Config.ZombieAttackDistance  then
                        if not IsEntityPlayingAnim(Zombies[i],"melee@unarmed@streamed_core_fps", "ground_attack_0_psycho", 3) and not IsEntityDead(Zombies[i]) then
                            RequestAnimDict("melee@unarmed@streamed_core_fps")
                            while not HasAnimDictLoaded("melee@unarmed@streamed_core_fps") do
                                Wait(0)
                            end
                            TaskPlayAnim(Zombies[i],"melee@unarmed@streamed_core_fps","ground_attack_0_psycho", 8.0, 1.0, -1, 48, 0.001, false, false, false)
                            if not IsPedInAnyVehicle(PlayerPedId(), false) then
                                ApplyDamageToPed(PlayerPedId(), 6, false) 
                                Citizen.Wait(750)                                      
                            end
                        end
                   end
               end
           end
        end
    end    
end)

Citizen.CreateThread(function() 
    while true do
        Citizen.Wait(1000)
        for i = 1, #Zombies do
            if Zombies[i] ~= nil then
                local pedPos = GetEntityCoords(PlayerPedId())
                local zombiePos = GetEntityCoords(Zombies[i])
                local dist = #(pedPos - zombiePos)
                if IsPedDeadOrDying(Zombies[i]) then
                    SetEntityAsNoLongerNeeded(Zombies[i])
                    if DoesEntityExist(Zombies[i]) then
                        Citizen.Wait(10000)
                        DeleteEntity(Zombies[i])
                    end
            
                    if Zombies[i] ~= nil then
                        table.remove(Zombies, i)
                    end
                    Citizen.Wait(100)
                end
            end
        end
    end
end)

Citizen.CreateThread(function() 
    while true do
        Citizen.Wait(1000)
        for i = 1, #Zombies do
            if Zombies[i] ~= nil then
                local pedPos = GetEntityCoords(PlayerPedId())
                local zombiePos = GetEntityCoords(Zombies[i])
                local dist = #(pedPos - zombiePos)
                if IsPedFalling(Zombies[i]) then
                    SetEntityAsNoLongerNeeded(Zombies[i])
                    if DoesEntityExist(Zombies[i]) then
                        DeleteEntity(Zombies[i])
                    end
            
                    if Zombies[i] ~= nil then
                        table.remove(Zombies, i)
                    end
                end

            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2500)
        if(insideDungeon)then
            if(IsPlayerDungeonValid())then
                local dungeonData = Config.Dungeons[currentDungeonIndex] 
                local distToBoss = GetPlayerDistanceToBossInCurrentDungeon()
                if(distToBoss and not dungeonData.boss.foundLocation)then
                    if(distToBoss < 22.0)then
                        
                        if(NetworkDoesNetworkIdExist(tonumber(dungeonData.boss.netId)))then
                 
                            TriggerServerEvent("onBossFoundServer")
                        end
                    end
                end
            end
        end
    end
end)

local zombies_xp = {}


Citizen.CreateThread(function() -- Zombie Audio handler
    while true do
        Citizen.Wait(0)
        for i = 1, #Zombies do
            if Zombies[i] ~= nil then
                local pedPos = GetEntityCoords(PlayerPedId())
                local zombiePos = GetEntityCoords(Zombies[i])
                local dist = #(pedPos - zombiePos)
                if  IsPedDeadOrDying(Zombies[i]) then                  
                    if GetPedSourceOfDeath(Zombies[i]) == PlayerPedId() and not zombies_xp[Zombies[i]] then 
                        -- Triggery your xxp handler here
                        Config.xp()            
                        zombies_xp[Zombies[i]] = true
                    end
                end
                if IsPedDeadOrDying(Zombies[i]) and dist < 3.5 then
                    SetEntityAsNoLongerNeeded(Zombies[i])
                    DrawText3D(zombiePos.x, zombiePos.y, zombiePos.z,  Config.Localization[Config.Locale]["LOOT"])
                    if IsControlJustPressed(0, 38) then
                        DeleteEntity(Zombies[i])
                        table.remove(Zombies, i)
                        TriggerServerEvent('lucid-dungeon:server:loot', 'zombie')
                    
                        Citizen.Wait(1000)
                    end
                end
            end
        end
    end
end)


function IsPlayerLeaderOfLobby(source)
    if(playerLobby)then
        for _,v in pairs(playerLobby.players) do
            if(tonumber(v.source) == tonumber(source))then
                return v.isLeader
            end
        end
    end
    return false
end

function GetPlayerLobbyInLobby(source)
    if(playerLobby)then
        for _,v in pairs(playerLobby.players) do
            if(tonumber(v.source) == tonumber(source))then
                return v
            end
        end
    end
    return false
end


AddEventHandler('gameEventTriggered',function(eventName, data)
    if eventName == "CEventNetworkEntityDamage" then
        if(next(playerLobby) ~= nil)then
            if(IsPlayerDungeonValid())then
                local entity = tonumber(data[1])
                local attacker = tonumber(data[2])
                local dungeonData = Config.Dungeons[currentDungeonIndex]
                local src =  GetPlayerServerId(NetworkGetPlayerIndexFromPed(attacker))
                local isLeader = IsPlayerLeaderOfLobby(src)
                if(not isLeader)then

                    for wallIndex, wallData in pairs(dungeonData.walls) do
                        if(NetworkDoesNetworkIdExist(NetworkGetNetworkIdFromEntity(entity)))then
                            if(NetworkGetNetworkIdFromEntity(entity) == tonumber(wallData.netId))then
                                SetEntityHealth(entity, tonumber(GetEntityHealth(entity)) - 45)
                            end
                        end
                    end
                end

                if(NetworkDoesNetworkIdExist(NetworkGetNetworkIdFromEntity(entity)))then
                    if(NetworkGetNetworkIdFromEntity(entity) == tonumber(dungeonData.boss.netId))then
                        SetEntityHealth(entity, tonumber(GetEntityHealth(entity)) - 40)                          
                    end
                end
            end
        end
    end
 end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if(insideDungeon)then
            if(IsPlayerDungeonValid())then
                local dungeonData = Config.Dungeons[currentDungeonIndex] 
                for wallIndex, wallData in pairs(dungeonData.walls) do
                    if(wallData.netId ~= nil)then
                        
                        if(NetworkDoesNetworkIdExist(tonumber(wallData.netId)))then
                            
                            if(DoesEntityExist(NetworkGetEntityFromNetworkId((tonumber(wallData.netId)))))then

                                if(GetEntityHealth(NetworkGetEntityFromNetworkId((tonumber(wallData.netId)))) <= 0)then
                                    
                                    if(wallData.netId ~= nil)then
                         
                                        AddExplosion(GetEntityCoords(NetworkGetEntityFromNetworkId((tonumber(wallData.netId)))), 'EXPLOSION_SMOKEGRENADE', 20.0, true, false, 2.0)
                                        AddExplosion(GetEntityCoords(NetworkGetEntityFromNetworkId((tonumber(wallData.netId)))), 'EXPLOSION_SMOKEGRENADE', 20.0, true, false, 20.0)
                                        AddExplosion(GetEntityCoords(NetworkGetEntityFromNetworkId((tonumber(wallData.netId)))), 'EXPLOSION_SMOKEGRENADE', 20.0, true, false, 0.5)
                                        FreezeEntityPosition(NetworkGetEntityFromNetworkId((tonumber(wallData.netId))), false)
                                        TriggerEvent("onDungeonWallBreaks", wallIndex)
                                        Citizen.Wait(550)
                                        if(NetworkDoesNetworkIdExist(tonumber(wallData.netId)))then
                                            if(DoesEntityExist(NetworkGetEntityFromNetworkId((tonumber(wallData.netId)))))then
                                                DeleteEntity(NetworkGetEntityFromNetworkId((tonumber(wallData.netId))))
                                            end
                                        end
                                        wallData.netId = nil
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)





local hide = true
local forceHide = false
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local retval, entity = GetEntityPlayerIsFreeAimingAt(PlayerId())

        if insideDungeon then
            if(IsPlayerDungeonValid())then
                local dungeonData = Config.Dungeons[currentDungeonIndex] 
                if retval then
                    local foundZombie = false
                    for k,v in pairs(Config.ZombieModels) do
                        if (GetEntityModel(entity) == GetHashKey(v) ) then
                            foundZombie = true
                        end
                    end
                    local wallData = GetWallDataFromCoords(GetEntityCoords(entity))
                    if ((IsEntityAnObject(entity) and GetEntityModel(entity) == (wallData and wallData.model or nil)) or GetEntityModel(entity) == dungeonData.boss.model) or foundZombie and not IsPedDeadOrDying(entity) then
                        if(not IsEntityAnObject(entity))then
                            SendNUIMessage({
                                type= 'showHealth',
                                maxHealth = GetEntityMaxHealth(entity),
                                health = GetEntityHealth(entity) - 100
                            })
                        else
                            SendNUIMessage({
                                type= 'showHealth',
                                maxHealth = GetEntityMaxHealth(entity),
                                health = GetEntityHealth(entity)
                            })
                        end
                        hide = false
                        forceHide = true
                    end
                   
                    if not hide and ( GetEntityHealth(entity) <= 0) then
                        SendNUIMessage({
                            type= 'redColor',
                        })  
                        hide = true 
                     end
                else
                    if forceHide then
                        SendNUIMessage({
                            type= 'hideHealth',
                        }) 
                        forceHide = false 
                        hide = true
                    end
                    if not hide then
                        SendNUIMessage({
                            type= 'hideHealth',
                        })  
                        hide = true
                    end
                end
            end
        end
    end
end)





RegisterNetEvent('onBossFound')
AddEventHandler("onBossFound", function()
    if(IsPlayerDungeonValid())then
        local dungeonData = Config.Dungeons[currentDungeonIndex]
        if(NetworkDoesNetworkIdExist(tonumber(dungeonData.boss.netId)))then
            dungeonData.boss.foundLocation = true
            FreezeEntityPosition(PlayerPedId(), true) 
            FreezeEntityPosition(NetworkGetEntityFromNetworkId((tonumber(dungeonData.boss.netId))), true) 
            CreateBossCamera(vector3(dungeonData.boss.coords.x, dungeonData.boss.coords.y, dungeonData.boss.coords.z + 2.0))
            FreezeEntityPosition(PlayerPedId(), false) 
            FreezeEntityPosition(NetworkGetEntityFromNetworkId((tonumber(dungeonData.boss.netId))), false) 
            SetEntityInvincible(NetworkGetEntityFromNetworkId((tonumber(dungeonData.boss.netId))), false)
        end
    end
end)

AddEventHandler("onDungeonWallBreaks", function(wallIndex)
    if(IsPlayerDungeonValid())then

        local dungeonData = Config.Dungeons[currentDungeonIndex] 
        local wallData = dungeonData.walls[wallIndex]
        if(wallData)then
            if(wallData.spawnZombiesAfterWallBreaks)then

                SpawnZombies(wallData.zombiesBaseSpawnCoords)
            end
        end
    end
end)


RegisterNUICallback("createLobby", function(data, cb)
    local lobbyName = data.lobbyName
    local lobbyPassword = data.lobbyPassword
    local selectedDungeon = data.selectedDungeon
    local maxPlayersAmount = data.maxPlayersAmount

    if(#lobbyName > 0 and ' ' ~= lobbyName and selectedDungeon  ~= nil)then
        TriggerServerEvent("lucid-dungeon:createLobby", lobbyName, lobbyPassword, maxPlayersAmount, selectedDungeon)
        cb(true)
    else
        cb(false)
        ESX.ShowNotification(Config.Localization[Config.Locale]["MISSING_FIELDS"])
    end
end)

RegisterNUICallback("deleteLobby", function(data, cb)
    TriggerServerEvent("lucid-dungeon:deleteLobby")
end)

RegisterNUICallback("leaveFromLobby", function(data, cb)
    TriggerServerEvent("lucid-dungeon:leaveFromLobby")
end)

function OpenUI()
    TriggerScreenblurFadeIn(0)
    DisplayRadar(false)
    CreationCamHead()
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "SET_PLAYER_IDENTIFIER",
        identifer = ESX.GetPlayerData().identifier,
    })
    SendNUIMessage({
        type = "SET_DUNGEONS",
        dungeons = Config.Dungeons
    })
    SendNUIMessage({
        type = "OPEN_UI",
    })
end

RegisterCommand("dungeonui", function()
    if(not IsPlayerDungeonValid())then
        OpenUI()
    else
        ESX.ShowNotification(Config.Localization[Config.Locale]["CANT_OPEN_UI"])
    end
end)

function Close()
    TriggerScreenblurFadeOut(0)
    DisplayRadar(true)
    SetNuiFocus(false, false)
    if(playerCam)then
        SetCamActive(playerCam, false)
        RenderScriptCams(false, true, 1500, true, true)
        playerCam = nil
    end
end

RegisterNUICallback("close", function(data, cb)
    Close()
end)

RegisterNUICallback("kickPlayer", function(data, cb)
   TriggerServerEvent("lucid-dungeon:kickPlayer", data.source)
end)

RegisterNUICallback("passLeadership", function(data, cb)
    TriggerServerEvent("lucid-dungeon:passLeadership", data.source)
end)

RegisterNUICallback("joinLobby", function(data, cb)
    ESX.TriggerServerCallback("lucid-dungeon:JoinLobby", function(success) 
        cb(success)
    end, data.lobbyId, data.password)
end)
 
 
RegisterNUICallback("startDungeon", function(data, cb)
   TriggerServerEvent("lucid-dungeon:startDungeon")
end)

RegisterNUICallback("changeLobbySettings", function(data, cb)
    TriggerServerEvent("lucid-dungeon:ChangeLobbySettings", data.lobbyName, data.selectedDungeon, data.lobbyPassword, data.maxPlayersAmount)

end)
 
RegisterNetEvent("lucid-dungeon:GetAllLobbies")
AddEventHandler("lucid-dungeon:GetAllLobbies", function(newLobbies)
    lobbies = newLobbies
    SendNUIMessage({
        type = "SET_LOBBIES",
        lobbies = newLobbies,
    })
end)

RegisterNetEvent("lucid-dungeon:client:SpawnSyncBossAndWalls")
AddEventHandler("lucid-dungeon:client:SpawnSyncBossAndWalls", function()
    CreateDungeonWalls(true)
    SpawnBoss(true)
end)

loaded = false
RegisterNetEvent("lucid-dungeon:SetDungeonLoaded")
AddEventHandler("lucid-dungeon:SetDungeonLoaded", function(toggle)
    loaded = toggle
end)

RegisterNetEvent('lucid-dungeon:client:startDungeonWithTeam')
AddEventHandler('lucid-dungeon:client:startDungeonWithTeam', function(bossPositionIndex)
    local dungeonData = Config.Dungeons[playerLobby.dungeonIndex] 
    if(dungeonData)then
        DoScreenFadeOut(100)
        TriggerServerEvent('instance:setNamed', "dungeon-"..playerLobby.id) 
        SendNUIMessage({
            type = "CLOSE_UI",
        })
		NetworkSetFriendlyFireOption(false)
        Citizen.Wait(500)
        currentDungeonIndex = tonumber(playerLobby.dungeonIndex)
        insideDungeon = true
        insideWithTeam = true
        playerPrevLocation = GetEntityCoords(PlayerPedId())
        SelectBossPosition(bossPositionIndex)
        
        SetEntityCoords(PlayerPedId(), dungeonData.spawnCoords.x, dungeonData.spawnCoords.y, dungeonData.spawnCoords.z )
        SetEntityHeading(PlayerPedId(), dungeonData.spawnCoords.w)
        FreezeEntityPosition(PlayerPedId(), true)
        loaded = false
        while not loaded do
            Citizen.Wait(100)
        end
        DoScreenFadeIn(100)
        FreezeEntityPosition(PlayerPedId(), false)

    end
end)


RegisterNetEvent('lucid-dungeon:GetPlayerLobby')
AddEventHandler('lucid-dungeon:GetPlayerLobby', function(lobby)
    inLobby = true
    playerLobby = lobby

    if(lobby == 'nil')then
        SendNUIMessage({
            type = "CLOSE_UI",
        })
        playerLobby = {}
        inLobby = false
    end

    SendNUIMessage({
        type = "SET_PLAYER_LOBBY",
        playerLobby = playerLobby,
        inLobby = inLobby
    })
end)