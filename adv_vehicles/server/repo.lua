lib.callback.register('adv_vehicles:server:GetRepoVehicles', function(source)
    local src = source
    local player = Framework.GetPlayer(src)
    if not player then return {} end

    if not IsPlayerAceAllowed(src, "job.repo") and not (player.PlayerData and player.PlayerData.job and player.PlayerData.job.name == "repo") then
        return {}
    end

    local vehicles = MySQL.query.await('SELECT plate, vehicle, coords FROM player_vehicles WHERE finance_missed >= 3 AND state = 0')
    return vehicles
end)

RegisterNetEvent('adv_vehicles:server:RepoVehicle', function(plate, vehicleCoords, netId)
    local src = source
    local player = Framework.GetPlayer(src)
    if not player then return end

    if not IsPlayerAceAllowed(src, "job.repo") and not (player.PlayerData and player.PlayerData.job and player.PlayerData.job.name == "repo") then
        print(("Player %s attempted to exploit repo vehicle."):format(GetPlayerName(src)))
        return
    end

    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local dist = #(playerCoords - vec3(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z))

    if dist > 20.0 then
        print(("Player %s attempted to repo vehicle from too far away."):format(GetPlayerName(src)))
        return
    end

    local vehicle = MySQL.query.await('SELECT id FROM player_vehicles WHERE plate = ? AND finance_missed >= 3 AND state = 0', {plate})
    if not vehicle or not vehicle[1] then return end

    MySQL.update('UPDATE player_vehicles SET state = 2, garage = "impound", impounded = 1 WHERE plate = ?', {plate})
    Framework.AddMoney(src, 'cash', 500, "repo-job")
    if netId then TriggerClientEvent('adv_vehicles:client:DeleteRepoVehicle', -1, netId) end
end)
