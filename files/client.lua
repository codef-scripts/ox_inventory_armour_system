local QBCore = exports['qb-core']:GetCoreObject()
local isMonitoringArmor = false

local function HasArmorVest()
    local Player = QBCore.Functions.GetPlayerData()
    local hasVest = QBCore.Functions.HasItem(Config.RequiredVest)
    return hasVest
end

local function HasArmorVestInSlot2()
    -- Method 1: GetSlots (client-side)
    local success1, slots = pcall(function()
        return exports.ox_inventory:GetSlots()
    end)
    
    if success1 and slots and slots[2] then
        if slots[2].name == Config.RequiredVest then
            return true
        end
    end
    
    -- Method 2: GetCurrentInventory
    local success2, inventory = pcall(function()
        return exports.ox_inventory:GetCurrentInventory()
    end)
    
    if success2 and inventory and inventory.items and inventory.items[2] then
        if inventory.items[2].name == Config.RequiredVest then
            return true
        end
    end
    
    -- Method 3: Server callback as fallback
    local hasEquippedArmor = false
    local callbackReceived = false
    
    QBCore.Functions.TriggerCallback('armor:server:checkSpecificSlot', function(equipped)
        hasEquippedArmor = equipped
        callbackReceived = true
    end, 2, Config.RequiredVest)
    
    local timeout = 0
    while not callbackReceived and timeout < 50 do
        Wait(10)
        timeout = timeout + 1
    end
    
    return hasEquippedArmor
end

local function CanUseArmorType(armorType)
    local Player = QBCore.Functions.GetPlayerData()
    local jobName = Player.job.name
    
    if Config.ArmorPlates[armorType].jobs == nil then
        return true
    end
    
    return Config.ArmorPlates[armorType].jobs[jobName] == true
end

local function ApplyArmorPlate(plateType)
    local armorConfig = Config.ArmorPlates[plateType]
    
    if not HasArmorVestInSlot2() then
        lib.notify({
            title = 'Error',
            description = 'You need an armor vest equipped',
            type = 'error'
        })
        return
    end
    
    if not CanUseArmorType(plateType) then
        lib.notify({
            title = 'Error',
            description = 'You cannot use this type of armor plate',
            type = 'error'
        })
        return
    end
    
    local currentArmor = GetPedArmour(PlayerPedId())
    if currentArmor >= armorConfig.maxArmor then
        lib.notify({
            title = 'Error',
            description = 'Maximum armor capacity reached',
            type = 'error'
        })
        return
    end
    
    if lib.progressBar({
        duration = armorConfig.useTime,
        label = 'Applying Armor Plate',
        useWhileDead = false,
        canCancel = true,
        
        disable = {
            car = false,
            move = false,
            combat = false,
        },
        anim = {
            dict = 'clothingshirt',
            clip = 'try_shirt_positive_d',
            flag = 49
        },
    }) then
        local newArmor = math.min(currentArmor + armorConfig.armorIncrease, armorConfig.maxArmor)
        SetPedArmour(PlayerPedId(), newArmor)
        TriggerServerEvent('ox_inventory_armour_system:server:removePlate', armorConfig.item)
        lib.notify({
            title = 'Success',
            description = 'Armor plate applied successfully!',
            type = 'success'
        })
    else
        lib.notify({
            title = 'Cancelled',
            description = 'Cancelled applying armor plate!',
            type = 'error'
        })
    end
end

local function SaveArmorToVest()
    local currentArmor = GetPedArmour(PlayerPedId())
    TriggerServerEvent('ox_inventory_armour_system:server:saveArmorToVest', currentArmor)
end

local function MonitorArmorVestSlot()
    if isMonitoringArmor then return end
    isMonitoringArmor = true
    
    CreateThread(function()
        local lastVestState = HasArmorVestInSlot2()
        local lastArmor = GetPedArmour(PlayerPedId())
        
        while true do
            Wait(1000)
            
            local currentVestState = HasArmorVestInSlot2()
            local currentArmor = GetPedArmour(PlayerPedId())
            
            -- Vest was removed
            if lastVestState and not currentVestState then
                SaveArmorToVest()
                SetPedArmour(PlayerPedId(), 0)
                lib.notify({
                    title = 'Armor Removed',
                    description = 'Armor vest unequipped',
                    type = 'info'
                })
            end
            
            -- Vest was equipped
            if not lastVestState and currentVestState then
                TriggerServerEvent('ox_inventory_armour_system:server:loadArmorFromVest')
            end
            
            -- Armor changed while vest is equipped
            if currentVestState and currentArmor ~= lastArmor then
                SaveArmorToVest()
            end
            
            lastVestState = currentVestState
            lastArmor = currentArmor
        end
    end)
end

RegisterNetEvent('ox_inventory_armour_system:client:useArmor', function(plateType)
    ApplyArmorPlate(plateType)
end)

RegisterNetEvent('ox_inventory_armour_system:client:setArmor', function(armorValue)
    SetPedArmour(PlayerPedId(), armorValue)
    lib.notify({
        title = 'Armor Equipped',
        description = 'Armor vest equipped with ' .. armorValue .. '% armor',
        type = 'success'
    })
end)

CreateThread(function()
    Wait(2000)
    MonitorArmorVestSlot()
end)