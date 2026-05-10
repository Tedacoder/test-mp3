with open('vehicle_inspection/server/items.lua', 'r') as f:
    content = f.read()

# Replace setup block
old_setup = """local qbox = GetResourceState('qbx_core') == 'started'
local qb = GetResourceState('qb-core') == 'started'
local esx = GetResourceState('es_extended') == 'started'

if qbox then
    exports.qbx_core:CreateUseableItem('cosmetic_part', function(source, item)
        TriggerClientEvent('vehicle_inspection:client:repairWindows', source)
    end)

    exports.qbx_core:CreateUseableItem('tyre_replacement', function(source, item)
        TriggerClientEvent('vehicle_inspection:client:repairTires', source)
    end)
elseif qb then
    local QBCore = exports['qb-core']:GetCoreObject()

    QBCore.Functions.CreateUseableItem('cosmetic_part', function(source, item)
        TriggerClientEvent('vehicle_inspection:client:repairWindows', source)
    end)

    QBCore.Functions.CreateUseableItem('tyre_replacement', function(source, item)
        TriggerClientEvent('vehicle_inspection:client:repairTires', source)
    end)
elseif esx then
    local ESX = exports['es_extended']:getSharedObject()

    ESX.RegisterUsableItem('cosmetic_part', function(source)
        TriggerClientEvent('vehicle_inspection:client:repairWindows', source)
    end)

    ESX.RegisterUsableItem('tyre_replacement', function(source)
        TriggerClientEvent('vehicle_inspection:client:repairTires', source)
    end)
else
    -- Fallback for ox_inventory standalone
    if GetResourceState('ox_inventory') == 'started' then
        exports('repairWindowsItem', function(event, item, inventory, slot, data)
            if event == 'usingItem' then
                TriggerClientEvent('vehicle_inspection:client:repairWindows', inventory.id)
                return true
            end
        end)
        exports('repairTiresItem', function(event, item, inventory, slot, data)
            if event == 'usingItem' then
                TriggerClientEvent('vehicle_inspection:client:repairTires', inventory.id)
                return true
            end
        end)
    end
end"""

new_setup = """if Config.Framework == 'qbx' then
    exports.qbx_core:CreateUseableItem('cosmetic_part', function(source, item)
        TriggerClientEvent('vehicle_inspection:client:repairWindows', source)
    end)
    exports.qbx_core:CreateUseableItem('tyre_replacement', function(source, item)
        TriggerClientEvent('vehicle_inspection:client:repairTires', source)
    end)
elseif Config.Framework == 'qbcore' then
    local QBCore = exports['qb-core']:GetCoreObject()
    QBCore.Functions.CreateUseableItem('cosmetic_part', function(source, item)
        TriggerClientEvent('vehicle_inspection:client:repairWindows', source)
    end)
    QBCore.Functions.CreateUseableItem('tyre_replacement', function(source, item)
        TriggerClientEvent('vehicle_inspection:client:repairTires', source)
    end)
elseif Config.Framework == 'esx' then
    local ESX = exports['es_extended']:getSharedObject()
    ESX.RegisterUsableItem('cosmetic_part', function(source)
        TriggerClientEvent('vehicle_inspection:client:repairWindows', source)
    end)
    ESX.RegisterUsableItem('tyre_replacement', function(source)
        TriggerClientEvent('vehicle_inspection:client:repairTires', source)
    end)
end

if Config.Inventory == 'ox_inventory' then
    exports('repairWindowsItem', function(event, item, inventory, slot, data)
        if event == 'usingItem' then
            TriggerClientEvent('vehicle_inspection:client:repairWindows', inventory.id)
            return true
        end
    end)
    exports('repairTiresItem', function(event, item, inventory, slot, data)
        if event == 'usingItem' then
            TriggerClientEvent('vehicle_inspection:client:repairTires', inventory.id)
            return true
        end
    end)
elseif Config.Inventory == 'qs-inventory' then
    exports['qs-inventory']:CreateUsableItem('cosmetic_part', function(source, item)
        TriggerClientEvent('vehicle_inspection:client:repairWindows', source)
    end)
    exports['qs-inventory']:CreateUsableItem('tyre_replacement', function(source, item)
        TriggerClientEvent('vehicle_inspection:client:repairTires', source)
    end)
end"""

content = content.replace(old_setup, new_setup)

# Replace removeItem
old_remove_item = """RegisterNetEvent('vehicle_inspection:server:removeItem', function(item)
    local src = source
    if GetResourceState('ox_inventory') == 'started' then
        exports.ox_inventory:RemoveItem(src, item, 1)
    elseif qbox then
        local player = exports.qbx_core:GetPlayer(src)
        player.Functions.RemoveItem(item, 1)
    elseif qb then
        local QBCore = exports['qb-core']:GetCoreObject()
        local player = QBCore.Functions.GetPlayer(src)
        player.Functions.RemoveItem(item, 1)
    elseif esx then
        local ESX = exports['es_extended']:getSharedObject()
        local player = ESX.GetPlayerFromId(src)
        player.removeInventoryItem(item, 1)
    end
end)"""

new_remove_item = """RegisterNetEvent('vehicle_inspection:server:removeItem', function(item)
    local src = source
    if Config.Inventory == 'ox_inventory' then
        exports.ox_inventory:RemoveItem(src, item, 1)
    elseif Config.Inventory == 'qs-inventory' then
        exports['qs-inventory']:RemoveItem(src, item, 1)
    elseif Config.Inventory == 'qb-inventory' or Config.Framework == 'qbx' or Config.Framework == 'qbcore' then
        if Config.Framework == 'qbx' then
            local player = exports.qbx_core:GetPlayer(src)
            player.Functions.RemoveItem(item, 1)
        elseif Config.Framework == 'qbcore' then
            local QBCore = exports['qb-core']:GetCoreObject()
            local player = QBCore.Functions.GetPlayer(src)
            player.Functions.RemoveItem(item, 1)
        end
    elseif Config.Framework == 'esx' then
        local ESX = exports['es_extended']:getSharedObject()
        local player = ESX.GetPlayerFromId(src)
        player.removeInventoryItem(item, 1)
    end
end)"""

content = content.replace(old_remove_item, new_remove_item)

with open('vehicle_inspection/server/items.lua', 'w') as f:
    f.write(content)
