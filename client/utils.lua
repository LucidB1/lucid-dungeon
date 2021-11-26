function DrawText3D(x, y, z, text)
	SetTextScale(0.27, 0.26)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    --DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end


function RequestEntityModel(model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(0)
    end
end

function IsPlayerDungeonValid()
    if(currentDungeonIndex)then
        local dungeonData = Config.Dungeons[currentDungeonIndex] 
        if(dungeonData)then
            return true
        end
    end
    return false
end

function ParticleEffect(dict, particleName, scale, time, ped)
    RequestNamedPtfxAsset(dict)
    while not HasNamedPtfxAssetLoaded(dict) do
        Citizen.Wait(0)
    end
	UseParticleFxAssetNextCall(dict)
    local particleHandle = StartNetworkedParticleFxLoopedOnEntity(particleName, ped, 0.0, 0.0, -3.0, 0.0, 0.0, 0.0, scale, false, false, false)
	SetParticleFxLoopedColour(particleHandle, 0, 255, 0 ,0)
    Citizen.Wait(time)
	StopParticleFxLooped(particleHandle, false)
	return particleHandle
end


function DrawTimerBar(title, text, barIndex)
	local width = 0.13
	local hTextMargin = 0.003
	local rectHeight = 0.038
	local textMargin = 0.008
	
	local rectX = GetSafeZoneSize() - width + width / 2
	local rectY = GetSafeZoneSize() - rectHeight + rectHeight / 2 - (barIndex - 1) * (rectHeight + 0.005)
	
	DrawSprite("timerbars", "all_black_bg", rectX, rectY, width, 0.038, 0, 0, 0, 0, 128)
	
	Draw(title, GetSafeZoneSize() - width + hTextMargin, rectY - textMargin, 0.32)
	Draw(string.upper(text), GetSafeZoneSize() - hTextMargin, rectY - 0.0175, 0.5, true, width / 2)
end

function Draw(text, x, y, scale, right, width)
	SetTextFont(0)
	SetTextScale(scale, scale)
	SetTextColour(254, 254, 254, 255)

	if right then
		SetTextWrap(x - width, x)
		SetTextRightJustify(true)
	end
	
	BeginTextCommandDisplayText("STRING")	
	AddTextComponentSubstringPlayerName(text)
	EndTextCommandDisplayText(x, y)
end

function GetWallDataFromCoords(coords)
    if(IsPlayerDungeonValid())then
        local dungeonData = Config.Dungeons[currentDungeonIndex]
        for j, wallData in pairs(dungeonData.walls) do
            if(NetworkDoesNetworkIdExist(tonumber(wallData.netId))) then
                if(DoesEntityExist(NetworkGetEntityFromNetworkId(tonumber(wallData.netId))))then
                    local entityCoords = GetEntityCoords(NetworkGetEntityFromNetworkId(tonumber(wallData.netId)))
                    if(entityCoords.x == coords.x and entityCoords.y == coords.y and entityCoords.z and coords.z)then
                        return wallData
                    end
                end
            end
        end
    end
    return false
end

function GetPlayerDistanceToBossInCurrentDungeon()
    if(IsPlayerDungeonValid())then
        local dungeonData = Config.Dungeons[currentDungeonIndex] 
        local bossData = dungeonData.boss   
        local playerCoords = GetEntityCoords(PlayerPedId())
        if(NetworkDoesNetworkIdExist(tonumber(dungeonData.boss.netId)))then
            if(DoesEntityExist(NetworkGetEntityFromNetworkId((tonumber(dungeonData.boss.netId)))))then
                local dist = #(playerCoords - GetEntityCoords(NetworkGetEntityFromNetworkId((tonumber(dungeonData.boss.netId))))) 
                return dist
            end
        end
    end
    return false
end
