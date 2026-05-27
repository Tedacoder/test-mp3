-- Client and Server bridge for garages

if IsDuplicityVersion() then
    -- SERVER SIDE
    function SaveVehicleToGarage(targetSource, vehicleModel)
        local Player = getPlayerSafe(targetSource)
        if not Player then return false end

        local citizenid = Player.PlayerData.citizenid
        local plate = generatePlate()

        local defaultMods = json.encode({ model = vehicleModel, plate = plate })

        if Config.GarageType == "qbx" or Config.GarageType == "qbcore" then
            MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state) VALUES (?, ?, ?, ?, ?, ?, ?)', {
                Player.PlayerData.license,
                citizenid,
                vehicleModel,
                GetHashKey(vehicleModel),
                defaultMods,
                plate,
                1
            }, function(id)
                if id then
                    TriggerClientEvent('adminpanel:client:copyToClipboard', targetSource, vehicleModel)
                end
            end)

        elseif Config.GarageType == "jg-advanced" then
            exports['jg-advancedgarages']:AddVehicleToPlayer(citizenid, vehicleModel, plate, "spawned_by_admin")
            TriggerClientEvent('adminpanel:client:copyToClipboard', targetSource, vehicleModel)

        elseif Config.GarageType == "cd" then
            MySQL.insert('INSERT INTO player_vehicles (citizenid, plate, vehicle, hash, mods, state) VALUES (?, ?, ?, ?, ?, ?)', {
                citizenid,
                plate,
                vehicleModel,
                GetHashKey(vehicleModel),
                defaultMods,
                'stored'
            }, function(id)
                if id then
                    TriggerClientEvent('adminpanel:client:copyToClipboard', targetSource, vehicleModel)
                end
            end)

        elseif Config.GarageType == "custom" then
            print(("^3[Admin Panel Warning] Custom garage selected. Implement custom logic for model: %s^7"):format(vehicleModel))
        end

        return plate
    end
else
    -- CLIENT SIDE
    RegisterNetEvent('adminpanel:client:copyToClipboard', function(text)
        if GetResourceState('ox_lib') == 'started' then
            lib.setClipboard(text)
            lib.notify({ title = 'Admin Panel', description = 'Copied '..text..' to clipboard!', type = 'success' })
        else
            SendNUIMessage({ type = "toast", message = 'Copied '..text..' to clipboard!' })
        end
    end)

    RegisterNetEvent('adminpanel:client:spawnAllocatedVehicle', function(model, plate)
        local hash = GetHashKey(model)

        if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then return end

        if GetResourceState('ox_lib') == 'started' then
            lib.requestModel(hash, 5000)
        else
            RequestModel(hash)
            while not HasModelLoaded(hash) do Wait(10) end
        end

        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)

        local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true, false)

        SetVehicleHasBeenOwnedByPlayer(vehicle, true)
        SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(vehicle), true)
        SetVehicleNumberPlateText(vehicle, plate)
        TaskWarpPedIntoVehicle(playerPed, vehicle, -1)

        if GetResourceState('ox_lib') == 'started' then
            lib.setClipboard(model)
        end

        SetModelAsNoLongerNeeded(hash)
    end)
end
