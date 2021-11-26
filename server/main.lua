

ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)





function generateLoot(type)
    local maxItem = math.random(Config.loot.minItem, Config.loot.maxItem)
    local items = {}

    for i=1, maxItem, 1 do 
        local rndItem = math.random(1, #Config.loot.items)
        local item = Config.loot.items[rndItem]
        if item.type ~= type then
            local keepLoop = true
            while keepLoop do
                Citizen.Wait(200)
                if item.type == type then
                    keepLoop = false
                else
                    rndItem =  math.random(1, #Config.loot.items)
                    item = Config.loot.items[rndItem]
                end
            end
        end
 
        if item.type == type then
            item.amount = math.random(item.minamount, item.maxamount)
            table.insert(items, item)
        end
    end
    return items
end

RegisterServerEvent('lucid-dungeon:server:loot')
AddEventHandler('lucid-dungeon:server:loot', function(type)
    local src = source
    local lootItems = generateLoot(type)
    local ply = ESX.GetPlayerFromId(src)
    if(ply)then
        if next(lootItems) ~= nil then
            for k,v in pairs(lootItems) do
                print("itemData.item : ", v.item)
                if(ply)then
                    ply.addInventoryItem(v.item,v.amount)
                    TriggerClientEvent('esx:showNotification', src, string.format(Config.Localization[Config.Locale]["YOU_FOUND"], v.amount,  v.itemlabel))
                end
            end
        else    
            TriggerClientEvent('esx:showNotification', src, Config.Localization[Config.Locale]["FOUND_NOTHING"])    
        end
    end

end)



ESX.RegisterServerCallback('lucid-dungeon:CheckPlayerItemAndRemove', function(source, cb, itemData)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if xPlayer.getInventoryItem(itemData.item) then
        if xPlayer.getInventoryItem(item).count >= itemData.amount then
            xPlayer.removeInventoryItem(itemData.item, itemData.amount)
            cb(true)
        end
    end
    cb(true)
end)
