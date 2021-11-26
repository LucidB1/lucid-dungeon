
ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
lobbies = {}

function GetDungeonByLabel(name)
    for _,v in pairs(Config.Dungeons) do
        if(v.dungeonLabel == name)then
            return v, _
        end
    end
    return false
end

function SendLobbyData(lobbyId, isNil)
    local lobby = GetLobbyById(lobbyId)
    if(lobby)then
        for _,v in pairs(lobby.players) do
            TriggerClientEvent("lucid-dungeon:GetPlayerLobby", v.source, isNil and "nil" or lobby)
        end
    end
end

function SendLobbyDataToSource(lobbyId, isNil, source)
    local lobby = GetLobbyById(lobbyId)
    if(lobby)then
        for _,v in pairs(lobby.players) do
            if(tonumber(v.source) == tonumber(source)) then
                TriggerClientEvent("lucid-dungeon:GetPlayerLobby", v.source, isNil and "nil" or lobby)
            end
        end
    end
end

function GetLobbyById(lobbyId)
    for _, v in pairs(lobbies) do
        if(tonumber(v.id) == tonumber(lobbyId))then
            return v, _
        end
    end
    return false
end

function GetPlayerLobbyBySource(source)
    for _, v in pairs(lobbies) do
        for j, player in pairs(v.players) do
            if(tonumber(player.source) == tonumber(source)) then
                return v, _
            end
        end
    end
    return false
end

function CanJoinLobby(lobbyId)
    local lobby = GetLobbyById(lobbyId)
    if(lobby)then
        local playersAmount = GetLobbyPlayerCount(lobbyId)
        if(tonumber(playersAmount) < tonumber(lobby.maxPlayers))then
            return true
        end
    end         
    return false
end

function GetLobbyPlayerCount(lobbyId)
   local lobby = GetLobbyById(lobbyId)
    if(lobby)then
         return #lobby.players
    end
    return false
end

function IsPlayerLeaderOfLobby(lobbyId, source)
    local lobby = GetLobbyById(lobbyId)
    if(lobby)then
        for _,v in pairs(lobby.players) do
            if(tonumber(v.source) == tonumber(source))then
                return v.isLeader
            end
        end
    end
    return false
end

RegisterServerEvent('lucid-dungeon:createLobby')
AddEventHandler('lucid-dungeon:createLobby', function(lobbyName, lobbyPassword, maxPlayers, selectedDungeon)
    local src = source
    local targetDungeon, targetDungeonIndex = GetDungeonByLabel(selectedDungeon)
    if(targetDungeon)then
        local lobbyId = #lobbies == 0 and 1 or #lobbies + 1
        if(#lobbies < 63) then
            table.insert(lobbies, {
                id = lobbyId,
                label = lobbyName,
                dungeon = targetDungeon,
                dungeonIndex = targetDungeonIndex,
                lobbyPassword = lobbyPassword,
                lockedLobby = #lobbyPassword > 0 and true or false,
                maxPlayers = maxPlayers,
                inDungeon = false,
                players = {},
            })
            AddPlayerToLobby(lobbyId, true, src)

            SendLobbyData(lobbyId)
            TriggerClientEvent("lucid-dungeon:GetAllLobbies", -1, lobbies)
        else
            TriggerClientEvent('esx:showNotification', src, Config.Localization[Config.Locale]["LIMIT_REACHED"])
        end
    end
end)

RegisterServerEvent('lucid-dungeon:leaveFromLobby')
AddEventHandler('lucid-dungeon:leaveFromLobby', function(targetSrc)
    local src = targetSrc and targetSrc or source
    local lobby = GetPlayerLobbyBySource(src)
    if(lobby)then
        RemovePlayerFromLobby(lobby.id, src)
        Citizen.Wait(750)
        SendLobbyData(lobby.id)
        TriggerClientEvent("lucid-dungeon:GetAllLobbies", -1, lobbies)
    end
end)

RegisterServerEvent('lucid-dungeon:kickPlayer')
AddEventHandler('lucid-dungeon:kickPlayer', function(targetSrc)
    local src = source
    local lobby = GetPlayerLobbyBySource(src)
    if(lobby )then
        if(IsPlayerLeaderOfLobby(lobby.id, src))then
            RemovePlayerFromLobby(lobby.id, targetSrc)
            SendLobbyData(lobby.id)
            TriggerClientEvent("lucid-dungeon:GetAllLobbies", -1, lobbies)
        end
    end
end)

function CheckDungeonKeysDelete(lobbyId, item, amount)
    local lobby = GetLobbyById(lobbyId)
    local exist = true
    if(lobby) then
        for j, player in pairs(lobby.players) do
            local xPlayer = ESX.GetPlayerFromId(player.source)
            if xPlayer.getInventoryItem(item) then
                if xPlayer.getInventoryItem(item).count < amount then
                    exist = false             
                end
            else
                exist = false
            end
        end
        if(exist)then
            for j, player in pairs(lobby.players) do
                local xPlayer = ESX.GetPlayerFromId(player.source)
                if xPlayer.getInventoryItem(item) then
                    if xPlayer.getInventoryItem(item).count >= amount then
                        xPlayer.removeInventoryItem(item, amount)
                    end
                end
            end
        end
    end
    return exist
end


AddEventHandler("playerDropped", function (reason)
    local src = source
    TriggerEvent("lucid-dungeon:leaveFromLobby", src)
end)

RegisterServerEvent('lucid-dungeon:startDungeon')
AddEventHandler('lucid-dungeon:startDungeon', function()
    local src = source
    local lobby = GetPlayerLobbyBySource(src)
    if(lobby)then
        local dungeonData = Config.Dungeons[lobby.dungeonIndex] 
        if(CheckDungeonKeysDelete(lobby.id, dungeonData.requiredItem.item, dungeonData.requiredItem.amount))then
            if(IsPlayerLeaderOfLobby(lobby.id, src))then
                local coordsData = dungeonData.possibleBossLocations.coords
                local selectCoordsIndex = math.random(1, #coordsData)
                for j, player in pairs(lobby.players) do
                    player.insideDungeon = true
                    TriggerClientEvent("lucid-dungeon:client:startDungeonWithTeam", player.source, 2) -- selectCoordsIndex
                end
                Citizen.Wait(1500)
                lobby.inDungeon = true
                SendLobbyData(lobby.id)
                TriggerClientEvent("lucid-dungeon:GetAllLobbies", -1, lobbies)
                Citizen.Wait(1550)
                TriggerClientEvent("lucid-dungeon:client:SpawnSyncBossAndWalls", src)
            end
        else
            TriggerClientEvent('esx:showNotification', source, Config.Localization[Config.Locale]["ITEM_NOT_EXIST"])
            
        end
    end
end)

RegisterServerEvent('lucid-dungeon:ShareBoss')
AddEventHandler('lucid-dungeon:ShareBoss', function(syncData)
    local src = source
    local lobby = GetPlayerLobbyBySource(src)
    if(lobby)then
        for j, player in pairs(lobby.players) do
            TriggerClientEvent("lucid-dungeon:GetSharedBoss", player.source, syncData)
        end
    end
end)

RegisterServerEvent('lucid-dungeon:ShareWalls')
AddEventHandler('lucid-dungeon:ShareWalls', function(syncData)
    local src = source
    local lobby = GetPlayerLobbyBySource(src)
    if(lobby)then
        for j, player in pairs(lobby.players) do
            TriggerClientEvent("lucid-dungeon:GetSharedWalls", player.source, syncData)
        end
    end
end)

RegisterServerEvent('lucid-dungeon:passLeadership')
AddEventHandler('lucid-dungeon:passLeadership', function(targetSrc)
    local src = source
    local lobby = GetPlayerLobbyBySource(src)
    if(lobby )then
        if(IsPlayerLeaderOfLobby(lobby.id, src))then
            PassLeaderShip(lobby.id, targetSrc)
            SendLobbyData(lobby.id)
            TriggerClientEvent("lucid-dungeon:GetAllLobbies", -1, lobbies)
        end
    end
end)

RegisterServerEvent('lucid-dungeon:deleteLobby')
AddEventHandler('lucid-dungeon:deleteLobby', function()
    local src = source
    local lobby = GetPlayerLobbyBySource(src)
    if(lobby)then
        if(not lobby.inDungeon)then
            DeleteLobby(lobby.id)
            TriggerClientEvent("lucid-dungeon:GetAllLobbies", -1, lobbies)
        else
            TriggerClientEvent('esx:showNotification', src, Config.Localization[Config.Locale]["CANT_DELETE"])
        end
    end
end)

function PassLeaderShip(lobbyId, targetSrc)
    local lobby = GetLobbyById(lobbyId)
    if(lobby)then
        for _,v in pairs(lobby.players) do
            v.isLeader = false
        end

        for _,v in pairs(lobby.players) do
            if(tonumber(v.source) == tonumber(targetSrc))then
                v.isLeader = true
            end
        end
    end
end


function DeleteLobby(lobbyId)

    SendLobbyData(lobbyId, true)
    for _,v in pairs(lobbies) do
        if(tonumber(v.id) ==  tonumber(lobbyId))then
            table.remove(lobbies, _)
        end
    end
end

function RemovePlayerFromLobby(lobbyId, source)
    local lobby, lobbyIndex = GetLobbyById(lobbyId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if(lobby and xPlayer)then
        for _, v in pairs(lobbies[lobbyIndex].players) do
            if(tonumber(v.source) == tonumber(source))then
                if(v.isLeader)then
                    local randomPlayerIndex = math.random(1, #lobbies[lobbyIndex].players)
                    local randomPlayer = lobbies[lobbyIndex].players[randomPlayerIndex]
                    PassLeaderShip(lobbyId, randomPlayer.source)
                end
                SendLobbyDataToSource(lobbyId, true, source)
                table.remove(lobbies[lobbyIndex].players, _)
            end
        end
        if(#lobbies[lobbyIndex].players == 0)then
            DeleteLobby(lobbyId)
        end
    end
end

ESX.RegisterServerCallback("lucid-dungeon:JoinLobby", function(source, cb, lobbyId, password)
    local lobby, lobbyIndex = GetLobbyById(lobbyId)
    if(lobby)then
        if(not lobby.inDungeon)then
            if(lobby.lockedLobby)then
                if(tonumber(lobby.lobbyPassword))then
                    if(tonumber(lobby.lobbyPassword) == tonumber(password))then
                        if(CanJoinLobby(lobbyId))then
                            AddPlayerToLobby(lobbyId, false, source)
                            SendLobbyData(lobbyId)
                            TriggerClientEvent("lucid-dungeon:GetAllLobbies", -1, lobbies)
                            cb(true)

                            return
                        else
                            TriggerClientEvent('esx:showNotification', source, Config.Localization[Config.Locale]["LOBBY_FULL"])
                            return
                        end
                    end 
                end
                if(lobby.lobbyPassword == password)then
                    if(CanJoinLobby(lobbyId))then
                        AddPlayerToLobby(lobbyId, false, source)
                        SendLobbyData(lobbyId)
                        TriggerClientEvent("lucid-dungeon:GetAllLobbies", -1, lobbies)
                        cb(true)
                        return
                        
                    else
                        TriggerClientEvent('esx:showNotification', source, Config.Localization[Config.Locale]["LOBBY_FULL"])
                    end
                end
            else
                if(CanJoinLobby(lobbyId))then
                    AddPlayerToLobby(lobbyId, false, source)
                    SendLobbyData(lobbyId)
                    TriggerClientEvent("lucid-dungeon:GetAllLobbies", -1, lobbies)
                    cb(true)
                    return
                else
                    TriggerClientEvent('esx:showNotification', source, Config.Localization[Config.Locale]["LOBBY_FULL"])
                end
            end
        else
            TriggerClientEvent('esx:showNotification', source, Config.Localization[Config.Locale]["CANT_JOIN"])
            cb(false)
            return
        end
    end
    TriggerClientEvent('esx:showNotification', source, Config.Localization[Config.Locale]["WRONG_PASSWORD"])
    cb(false)
end)

function AddPlayerToLobby(lobbyId, isLeader, source)
    local lobby, lobbyIndex = GetLobbyById(lobbyId)
    local xPlayer = ESX.GetPlayerFromId(source)
    local dungeonData = Config.Dungeons[lobby.dungeonIndex] 
    if(lobby and xPlayer)then
        table.insert(lobby.players, {
            name = xPlayer.getName(),
            source = source,
            isLeader = isLeader,
            foundBoss = false,
            insideDungeon = false,
            remainHealth = Config.Dungeons[lobby.dungeonIndex].dungeonHealth,
            identifier = xPlayer.getIdentifier(),
        })
    end
end


RegisterServerEvent('lucid-dungeon:OnPlayerDeathInDungeon')
AddEventHandler('lucid-dungeon:OnPlayerDeathInDungeon', function()
    local src = source
    local lobby = GetPlayerLobbyBySource(src)

    if(lobby)then
        for _,v in pairs(lobby.players) do
            if(tonumber(v.source) == tonumber(src)) then
                TriggerClientEvent("lucid-dungeon:RevivePlayer", v.source)
                if(v.remainHealth == 0)then
                    TriggerClientEvent("lucid-dungeon:ResetPlayerDungeon", v.source)
                end
                v.remainHealth = v.remainHealth - 1
                SendLobbyData(lobby.id)
                TriggerClientEvent("lucid-dungeon:GetAllLobbies", -1, lobbies)
                return
            end
        end
    end
end)

RegisterServerEvent('lucid-dungeon:OnDungeonFinished')
AddEventHandler('lucid-dungeon:OnDungeonFinished', function()
    local src = source
    local lobby = GetPlayerLobbyBySource(src)
    local inDungeon = true
    local canResetDungeon = true
    if(lobby)then
        for _,v in pairs(lobby.players) do
            if(v.insideDungeon )then
                canResetDungeon = false
            end
        end
        for _,v in pairs(lobby.players) do
            if(v.source == src)then
                v.foundBoss = false
                v.remainHealth = Config.Dungeons[lobby.dungeonIndex].dungeonHealth
                v.insideDungeon = false
            end
        end   

        if(canResetDungeon)then
            lobby.inDungeon = false
            SendLobbyData(lobby.id)
            TriggerClientEvent("lucid-dungeon:GetAllLobbies", -1, lobbies)
        end
    end
end)

RegisterServerEvent('lucid-dungeon:ShareBossBrutalAttack')
AddEventHandler('lucid-dungeon:ShareBossBrutalAttack', function()
    local src = source
    local lobby = GetPlayerLobbyBySource(src)
    if(lobby)then
        for _,v in pairs(lobby.players) do
            TriggerClientEvent("lucid-dungeon:client:ShareBossBrutalAttack", v.source)
        end
    end
end)

RegisterServerEvent('lucid-dungeon:ShareBossGroundAttack')
AddEventHandler('lucid-dungeon:ShareBossGroundAttack', function()
    local src = source
    local lobby = GetPlayerLobbyBySource(src)
    if(lobby)then
        for _,v in pairs(lobby.players) do
    
            TriggerClientEvent("lucid-dungeon:client:ShareBossGroundAttack", v.source)
        end
    end
end)

RegisterServerEvent('onBossFoundServer')
AddEventHandler('onBossFoundServer', function()
    local src = source
    local lobby = GetPlayerLobbyBySource(src)
    local everyoneFound = true
    if(lobby)then
        for _,v in pairs(lobby.players) do
            if(tonumber(v.source) == tonumber(src)) then
                v.foundBoss = true
            end
        end
        for _,v in pairs(lobby.players) do

            if(not v.foundBoss)then
                everyoneFound = false
            end
        end
        if(everyoneFound)then
            for _,v in pairs(lobby.players) do
                TriggerClientEvent("onBossFound", tonumber(v.source))
            end
        end
    end
end)

RegisterServerEvent('lucid-dungeon:ShareAttack')
AddEventHandler('lucid-dungeon:ShareAttack', function(data)
    local src = source
    local lobby = GetPlayerLobbyBySource(src)
    if(lobby)then
        local attackType = math.random(1, 10)
        for _,v in pairs(lobby.players) do
            TriggerClientEvent("lucid-dungeon:GetSharedAttacks", v.source, attackType)
        end
    end
end)

function ChangeLobbyName(lobbyId, newName)
    local dungeon = GetLobbyById(lobbyId)
    if(dungeon)then
        dungeon.label = newName
    end
end

function ChangeLobbyPassword(lobbyId, newPassword)
    local dungeon = GetLobbyById(lobbyId)
    if(dungeon)then
        dungeon.lobbyPassword = newPassword
        dungeon.lockedLobby = #newPassword > 0 and true or false
    end
end


function ChangeSelectedDungeon(lobbyId, selectedDungeon)
    local dungeon = GetLobbyById(lobbyId)
    local targetDungeon, targetDungeonIndex = GetDungeonByLabel(selectedDungeon)

    if(dungeon and targetDungeon)then
        dungeon.dungeon = targetDungeon
        dungeon.dungeonIndex = targetDungeonIndex
    end
end

function ChangeMaxPlayersAmount(lobbyId, maxPlayersAmount)
    local dungeon = GetLobbyById(lobbyId)
    if(dungeon)then
        if(#dungeon.players < maxPlayersAmount) then
            dungeon.maxPlayers = maxPlayersAmount
        end
    end
end

RegisterServerEvent('lucid-dungeon:ChangeLobbySettings')
AddEventHandler('lucid-dungeon:ChangeLobbySettings', function(lobbyName, selectedDungeon, lobbyPassword, maxPlayersAmount)
    local lobby = GetPlayerLobbyBySource(source)
    if(lobby)then
        ChangeLobbyName(lobby.id, lobbyName)
        if(selectedDungeon ~= nil)then
            ChangeSelectedDungeon(lobby.id, selectedDungeon)
        end
        ChangeLobbyPassword(lobby.id, lobbyPassword)
        ChangeMaxPlayersAmount(lobby.id, maxPlayersAmount)
        Citizen.Wait(400)
        SendLobbyData(lobby.id)
        TriggerClientEvent("lucid-dungeon:GetAllLobbies", -1, lobbies)
    end
end)