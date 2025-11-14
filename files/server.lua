local QBCore = exports['qb-core']:GetCoreObject()

for plateType, config in pairs(Config.ArmorPlates) do
    QBCore.Functions.CreateUseableItem(config.item, function(source)
        TriggerClientEvent('ox_inventory_armour_system:client:useArmor', source, plateType)
    end)
end

RegisterNetEvent('ox_inventory_armour_system:server:removePlate', function(itemName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    Player.Functions.RemoveItem(itemName, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], "remove")
end)

QBCore.Functions.CreateCallback('armor:server:checkSpecificSlot', function(source, cb, slotNumber, itemName)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        cb(false)
        return 
    end
    
    local success, inventory = pcall(function()
        return exports.ox_inventory:GetInventory(source, false)
    end)
    
    if success and inventory and inventory.items then
        local targetSlot = inventory.items[slotNumber]
        if targetSlot and targetSlot.name == itemName then
            cb(true)
            return
        end
    end
    
    cb(false)
end)

RegisterNetEvent('ox_inventory_armour_system:server:saveArmorToVest', function(armorValue)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local success, inventory = pcall(function()
        return exports.ox_inventory:GetInventory(src, false)
    end)
    
    if success and inventory and inventory.items then
        local vestSlot = inventory.items[Config.RequiredVestSlot]
        if vestSlot and vestSlot.name == Config.RequiredVest then
            exports.ox_inventory:SetMetadata(src, vestSlot.slot, {
                armor = armorValue,
                description = 'Armor: ' .. armorValue .. '%'
            })
        end
    end
end)

RegisterNetEvent('ox_inventory_armour_system:server:loadArmorFromVest', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local success, inventory = pcall(function()
        return exports.ox_inventory:GetInventory(src, false)
    end)
    
    if success and inventory and inventory.items then
        local vestSlot = inventory.items[Config.RequiredVestSlot]
        if vestSlot and vestSlot.name == Config.RequiredVest then
            local armorValue = 0
            if vestSlot.metadata and vestSlot.metadata.armor then
                armorValue = vestSlot.metadata.armor
            end
            TriggerClientEvent('ox_inventory_armour_system:client:setArmor', src, armorValue)
        end
    end
end)
