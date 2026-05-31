-- Command for Upper Admins
RegisterCommand('admingivecar', function(source, args)
    local src = source
    if not IsPlayerAceAllowed(src, "command.admingivecar") then
        return
    end

    local targetId = tonumber(args[1])
    local model = args[2]

    if not targetId or not model then return end

    local identifier = Framework.GetIdentifier(targetId)
    if not identifier then return end

    local plate = "ADM" .. math.random(10000, 99999)
    local vin = "ADMIN" .. math.random(1000000000, 9999999999)
    local hash = GetHashKey(model)

    MySQL.insert.await('INSERT INTO player_vehicles (citizenid, plate, vin, model, hash, state, garage) VALUES (?, ?, ?, ?, ?, 1, "legionsquare")', {
        identifier, plate, vin, model, hash
    })

    MySQL.insert.await('INSERT INTO vehicle_keys (plate, citizenid, is_primary) VALUES (?, ?, 1)', {
        plate, identifier
    })

    TriggerClientEvent('adv_vehicles:client:AdminSpawnCar', targetId, model, plate)
end, true)
-- Complete anti-exploit for scratching VIN missing from previous admin.lua server script
RegisterNetEvent('adv_vehicles:server:ScratchVIN', function(plate)
    -- Verify vehicle exists and is owned/stolen to scratch VIN.
    MySQL.update('UPDATE player_vehicles SET vin = "SCRATCHED" WHERE plate = ?', {plate})
end)
