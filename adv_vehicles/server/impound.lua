CreateThread(function()
    -- Impound stolen or abandoned vehicles on restart (or periodically)
    if Config.Impound.StolenAutoImpound then
        -- Find all stolen vehicles out on street
        MySQL.update('UPDATE player_vehicles SET state = 2, garage = "impound", impounded = 1, stolen = 0 WHERE state = 0 AND stolen = 1')
    end

    -- Abandoned logic (simplistic: all street vehicles not updated recently in a real env,
    -- here we just impound anything left out on start if desired, or let them persist)
    -- For persistence, we leave state = 0 and spawn them via client on load.
end)

lib.callback.register('adv_vehicles:server:RecoverImpound', function(source, plate)
    local src = source
    local identifier = Framework.GetIdentifier(src)

    local vehicle = MySQL.query.await('SELECT impound_fee, insurance_tier FROM player_vehicles WHERE plate = ? AND citizenid = ? AND impounded = 1', {plate, identifier})
    if vehicle and vehicle[1] then
        local fee = Config.Impound.BaseFee
        if vehicle[1].insurance_tier == "Premium" then fee = math.floor(fee * 0.5) end

        if Framework.RemoveMoney(src, 'bank', fee, "impound-fee") then
            MySQL.update('UPDATE player_vehicles SET impounded = 0, state = 1, garage = "legionsquare" WHERE plate = ?', {plate})
            return true, "Vehicle recovered."
        else
            return false, "Not enough money in bank. Fee: $"..fee
        end
    end
    return false, "Vehicle not found in impound."
end)

RegisterNetEvent('adv_vehicles:server:SetVehicleStolen', function(plate)
    MySQL.update('UPDATE player_vehicles SET stolen = 1 WHERE plate = ?', {plate})
end)
