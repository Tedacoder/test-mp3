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
    local vehicle = data.vehicle

    -- Request vehicle and spawn logic
    local hash = GetHashKey(vehicle)
    if not IsModelInCdimage(hash) then
        Framework.Notify("Invalid vehicle vehicle in database.", "error")
        return
    end
    RequestModel(hash)
    local timeout = 5000
    while not HasModelLoaded(hash) and timeout > 0 do
        Wait(10)
        timeout = timeout - 10
    end
    if not HasModelLoaded(hash) then
        Framework.Notify("Failed to load vehicle vehicle.", "error")
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    local veh = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true, false)
    SetVehicleNumberPlateText(veh, plate)
    TaskWarpPedIntoVehicle(ped, veh, -1)

    -- Ensure state matches the spawn (0 = street)
    TriggerServerEvent('adv_vehicles:server:SetVehicleState', plate, 0)

    -- Hand over keys natively so they don't have to hotwire their own car pulled from garage
    if GetResourceState('qbx_vehiclekeys') == 'started' or GetResourceState('qb-vehiclekeys') == 'started' then
        TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
        TriggerEvent('vehiclekeys:client:SetOwner', plate)
    end

    -- Force engine on
    SetVehicleEngineOn(veh, true, true, false)
    TriggerEvent('adv_vehicles:client:ForceEngineState', true)

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

-- Ensure the ped actually exists for players to target
CreateThread(function()
    local hash = GetHashKey("s_m_m_autoshop_01")
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end

    -- Example coords for a generic garage at Legion Square
    local ped = CreatePed(4, hash, 215.0, -810.0, 30.73, 250.0, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
end)

RegisterNUICallback('locateVehicle', function(data, cb)
    SetNuiFocus(false, false)
    if data.coords and data.coords ~= "null" then
        local coords = json.decode(data.coords)
        if coords and coords.x and coords.y then
            SetNewWaypoint(coords.x, coords.y)
            Framework.Notify("Vehicle location set on GPS.", "success")
        else
            Framework.Notify("Location data is corrupt or missing.", "error")
        end
    else
        Framework.Notify("Location data is missing.", "error")
    end
    cb('ok')
end)

-- Storing Vehicles
CreateThread(function()
    -- Garage coords for Legion Square generic setup
    local storeCoords = vec3(215.0, -810.0, 30.73)

    if Config.UseOxTarget then
        exports.ox_target:addBoxZone({
            coords = storeCoords,
            size = vec3(5.0, 5.0, 3.0),
            rotation = 250.0,
            debug = false,
            options = {
                {
                    name = 'store_veh_adv',
                    icon = 'fas fa-parking',
                    label = 'Store Vehicle',
                    canInteract = function(entity, distance, coords, name)
                        return IsPedInAnyVehicle(PlayerPedId(), false)
                    end,
                    onSelect = function()
                        local ped = PlayerPedId()
                        local veh = GetVehiclePedIsIn(ped, false)
                        if veh ~= 0 then
                            local plate = GetVehicleNumberPlateText(veh)
                            local engineHealth = GetVehicleEngineHealth(veh)
                            local bodyHealth = GetVehicleBodyHealth(veh)
                            local fuel = GetVehicleFuelLevel(veh)

                            lib.callback('adv_vehicles:server:StoreVehicle', false, function(success)
                                if success then
                                    TaskLeaveVehicle(ped, veh, 0)
                                    Wait(1500)
                                    DeleteEntity(veh)
                                    Framework.Notify("Vehicle stored in garage.", "success")
                                else
                                    Framework.Notify("You do not own this vehicle.", "error")
                                end
                            end, plate, 'Legion Square', engineHealth, bodyHealth, fuel)
                        end
                    end
                }
            }
        })
    end
end)

-- Failsafe for NUI Focus locking steering
RegisterCommand('fixui', function()
    SetNuiFocus(false, false)
    ClearPedTasks(PlayerPedId())
    Framework.Notify("UI Focus forcefully cleared.", "inform")
end)
