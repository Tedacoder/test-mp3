local currentGarage = nil

RegisterNetEvent('adv_vehicles:client:OpenGarage', function(garageName)
    currentGarage = garageName
    lib.callback('adv_vehicles:server:GetPlayerVehicles', false, function(vehicles)
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "openGarage",
            garage = garageName,
            vehicles = vehicles
        })
    end)
end)

RegisterNUICallback('closeGarage', function(data, cb)
    SetNuiFocus(false, false)
    currentGarage = nil
    cb('ok')
end)

RegisterNUICallback('spawnVehicle', function(data, cb)
    SetNuiFocus(false, false)
    local plate = data.plate
    local model = data.model

    -- Request model and spawn logic
    local hash = GetHashKey(model)
    if not IsModelInCdimage(hash) then
        Framework.Notify("Invalid vehicle model in database.", "error")
        return
    end
    RequestModel(hash)
    local timeout = 5000
    while not HasModelLoaded(hash) and timeout > 0 do
        Wait(10)
        timeout = timeout - 10
    end
    if not HasModelLoaded(hash) then
        Framework.Notify("Failed to load vehicle model.", "error")
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    local veh = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true, false)
    SetVehicleNumberPlateText(veh, plate)
    TaskWarpPedIntoVehicle(ped, veh, -1)

    -- Update state
    TriggerServerEvent('adv_vehicles:server:SetVehicleState', plate, 0)
    Framework.Notify("Vehicle retrieved.", "success")
    cb('ok')
end)

-- Example ox_target setup for a garage ped
CreateThread(function()
    if Config.UseOxTarget then
        exports.ox_target:addModel('s_m_m_autoshop_01', {
            {
                name = 'adv_garage',
                icon = 'fas fa-car',
                label = 'Open Garage',
                onSelect = function()
                    TriggerEvent('adv_vehicles:client:OpenGarage', 'Legion Square')
                end
            }
        })
    end
end)

RegisterNUICallback('recoverImpound', function(data, cb)
    SetNuiFocus(false, false)
    local plate = data.plate
    lib.callback('adv_vehicles:server:RecoverImpound', false, function(success, msg)
        Framework.Notify(msg, success and "success" or "error")
    end, plate)
    cb('ok')
end)

RegisterNUICallback('duplicateKeyNui', function(data, cb)
    SetNuiFocus(false, false)
    TriggerEvent('adv_vehicles:client:DuplicateKeys', data.plate)
    cb('ok')
end)

RegisterNUICallback('renameVehicle', function(data, cb)
    SetNuiFocus(false, false)
    local input = lib.inputDialog('Rename Vehicle', {
        {type = 'input', label = 'New Name (Model/Alias)', required = true}
    })
    if input and input[1] then
        TriggerServerEvent('adv_vehicles:server:RenameVehicle', data.plate, input[1])
        Framework.Notify("Vehicle renamed.", "success")
    end
    cb('ok')
end)
