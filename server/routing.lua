local instances = {}
 
RegisterServerEvent("instance:set")
AddEventHandler("instance:set", function(set)
 
    local src = source
 
    local instanceSource = 0
    if set then
        if set == 0 then
            for k,v in pairs(instances) do
                for k2,v2 in pairs(v) do
                    if v2 == src then
                        table.remove(v, k2)
                        if #v == 0 then
                            instances[k] = nil
                        end
                    end
                end
            end
        end
        instanceSource = set
    else
 
        instanceSource = math.random(1, 63)
 
        while instances[instanceSource] and #instances[instanceSource] >= 1 do
            instanceSource = math.random(1, 63)
            Citizen.Wait(1)
        end
    end
 
 
    if instanceSource ~= 0 then
        if not instances[instanceSource] then
            instances[instanceSource] = {}
        end
 
        table.insert(instances[instanceSource], src)
    end
 
    SetPlayerRoutingBucket(
        src --[[ string ]], 
        instanceSource
    )
end)
 
Namedinstances = {}
 
 
RegisterServerEvent("instance:setNamed")
AddEventHandler("instance:setNamed", function(setName)
 
    local src = source
    local instanceSource = nil
 
    TriggerClientEvent('DoTheBigRefreshYmaps', src)
 
    if setName == 0 then
            for k,v in pairs(Namedinstances) do
                for k2,v2 in pairs(v.people) do
                    if v2 == src then
                        table.remove(v.people, k2)
                    end
                end
                if #v.people == 0 then
                    Namedinstances[k] = nil
                end
            end
        instanceSource = setName
 
    else
        for k,v in pairs(Namedinstances) do
            if v.name == setName then
                instanceSource = k
            end
        end
 
        if instanceSource == nil then
            instanceSource = math.random(1, 63)
 
            while Namedinstances[instanceSource] and #Namedinstances[instanceSource] >= 1 do
                instanceSource = math.random(1, 63)
                Citizen.Wait(1)
            end
        end
    end
 
    if instanceSource ~= 0 then
 
        if not Namedinstances[instanceSource] then
            Namedinstances[instanceSource] = {
                name = setName,
                people = {}
            }
        end
 
        table.insert(Namedinstances[instanceSource].people, src)
 
    end
 
    SetPlayerRoutingBucket(
        src --[[ string ]], 
        instanceSource
    )
end)