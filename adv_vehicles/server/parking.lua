local ParkedVehicles = {}

RegisterNetEvent('adv_vehicles:server:ParkVehicle', function(plate, vehicle, props, coords, heading, engineHealth, bodyHealth, fuel, isLocked)
    local src = source
    local identifier = Framework.GetIdentifier(src)

    if not identifier then return end

    -- Verify player is close to coords
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local dist = #(playerCoords - coords)
    if dist > 20.0 then return end -- Exploiter check

    MySQL.query('SELECT plate FROM player_vehicles WHERE plate = ? AND citizenid = ?', {plate, identifier}, function(result)
        if result and #result > 0 then
            MySQL.update('UPDATE player_vehicles SET coords = ?, heading = ?, engine_health = ?, body_health = ?, fuel = ?, locked = ?, state = 0 WHERE plate = ?',
            {
                json.encode(coords),
                heading,
                engineHealth,
                bodyHealth,
                fuel,
                isLocked and 1 or 0,
                plate
            })
        end
    end)
end)

RegisterNetEvent('adv_vehicles:server:SaveVehicleState', function(plate, engineHealth, bodyHealth, fuel)
    local src = source
    local identifier = Framework.GetIdentifier(src)

    if not identifier then return end

    -- Ownership or proximity check would be ideal. Rate limit the save.
    local isOwner = MySQL.scalar.await('SELECT id FROM player_vehicles WHERE plate = ? AND citizenid = ?', {plate, identifier})
    if isOwner then
        MySQL.update('UPDATE player_vehicles SET engine_health = ?, body_health = ?, fuel = ? WHERE plate = ?', {
            engineHealth, bodyHealth, fuel, plate
        })
    end
end)

lib.callback.register('adv_vehicles:server:GetStreetParkedVehicles', function(source)
    local results = MySQL.query.await('SELECT * FROM player_vehicles WHERE state = 0 AND garage = "street"')
    return results
end)

CreateThread(function()
    Wait(5000)
    local results = MySQL.query.await('SELECT * FROM player_vehicles WHERE state = 0')
    if results then
        for _, veh in ipairs(results) do
            -- In QBOX, coords might be stored differently or be nil if not used by qbx natively
            local coords = type(veh.coords) == 'string' and json.decode(veh.coords) or nil
            if coords and coords.x then
                local vehicle = CreateVehicle(GetHashKey(veh.vehicle), coords.x, coords.y, coords.z, veh.heading, true, true)
                if DoesEntityExist(vehicle) then
                    -- Prevent entity from being deleted by engine automatically
                    -- This requires routing buckets or specific native manipulation, but basic persistence is achieved by passing 'true' to isNetwork and 'true' to bScriptHostVehicle (the 7th arg).
                    -- Actually wait, FiveM server-side CreateVehicle is (model, x, y, z, heading, isNetwork, netMissionEntity).
                    SetVehicleNumberPlateText(vehicle, veh.plate)
                    SetVehicleDoorsLocked(vehicle, veh.locked == 1 and 2 or 1)
                    SetVehicleEngineHealth(vehicle, veh.engine_health + 0.0)
                    SetVehicleBodyHealth(vehicle, veh.body_health + 0.0)
                end
            end
        end
    end
end)

RegisterNetEvent('adv_vehicles:server:SyncStreetVehicles', function()
    -- Client requests sync when they load in, just in case vehicles despawned.
    local src = source
    local results = MySQL.query.await('SELECT * FROM player_vehicles WHERE state = 0')
    if results then
        for _, veh in ipairs(results) do
            local coords = type(veh.coords) == 'string' and json.decode(veh.coords) or nil
            if coords and coords.x then
                -- Check if it already exists by plate
                local exists = false
                local allVehs = GetAllVehicles()
                for _, v in ipairs(allVehs) do
                    if GetVehicleNumberPlateText(v) == veh.plate then
                        exists = true
                        break
                    end
                end

                if not exists then
                    local vehicle = CreateVehicle(GetHashKey(veh.vehicle), coords.x, coords.y, coords.z, veh.heading, true, true)
                    if DoesEntityExist(vehicle) then
                        SetVehicleNumberPlateText(vehicle, veh.plate)
                        SetVehicleDoorsLocked(vehicle, veh.locked == 1 and 2 or 1)
                        SetVehicleEngineHealth(vehicle, veh.engine_health + 0.0)
                        SetVehicleBodyHealth(vehicle, veh.body_health + 0.0)
                    end
                end
            end
        end
    end
end)
