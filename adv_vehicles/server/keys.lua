lib.callback.register('adv_vehicles:server:HasKeys', function(source, plate)
    local src = source
    local identifier = Framework.GetIdentifier(src)

    if not identifier then return false end
    if Framework.HasItem(src, Config.Keys.AdminKey, 1) then return true end

    local hasKey = MySQL.scalar.await('SELECT id FROM vehicle_keys WHERE plate = ? AND citizenid = ?', {plate, identifier})
    return hasKey ~= nil
end)

RegisterNetEvent('adv_vehicles:server:GiveKey', function(targetId, plate)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    local targetIdentifier = Framework.GetIdentifier(targetId)

    if not identifier or not targetIdentifier then return end

    -- Verify source actually owns the primary key or the car
    local isOwner = MySQL.scalar.await('SELECT is_primary FROM vehicle_keys WHERE plate = ? AND citizenid = ?', {plate, identifier})

    if isOwner and isOwner == 1 then
        MySQL.insert('INSERT INTO vehicle_keys (plate, citizenid, is_primary) VALUES (?, ?, 0)', {plate, targetIdentifier})
        -- Notify both
    end
end)

RegisterNetEvent('adv_vehicles:server:SetVehicleLock', function(plate, locked)
    -- In a full environment, broadcast to all clients or use routing buckets.
    TriggerClientEvent('adv_vehicles:client:SetVehicleLockState', -1, plate, locked)
    MySQL.update('UPDATE player_vehicles SET locked = ? WHERE plate = ?', {locked and 1 or 0, plate})
end)

-- Create item use logic for regular key fob
if Config.Framework == "QBOX" or Config.Framework == "QB" then
    if Config.Framework == "QBOX" then
        exports.qbx_core:CreateUseableItem(Config.Keys.ItemName, function(source, item)
            TriggerClientEvent('adv_vehicles:client:ToggleLocks', source)
        end)
    else
        local QBCore = exports['qb-core']:GetCoreObject()
        QBCore.Functions.CreateUseableItem(Config.Keys.ItemName, function(source, item)
            TriggerClientEvent('adv_vehicles:client:ToggleLocks', source)
        end)
    end
end
