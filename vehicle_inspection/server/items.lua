local qbox = GetResourceState('qbx_core') == 'started'
local qb = GetResourceState('qb-core') == 'started'
local esx = GetResourceState('es_extended') == 'started'

if qbox or qb then
    local core = qbox and exports.qbx_core or exports['qb-core']:GetCoreObject()

    core.Functions.CreateUseableItem('cosmetic_part', function(source, item)
        TriggerClientEvent('vehicle_inspection:client:repairWindows', source)
    end)

    core.Functions.CreateUseableItem('tyre_replacement', function(source, item)
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
end

RegisterNetEvent('vehicle_inspection:server:removeItem', function(item)
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
end)
