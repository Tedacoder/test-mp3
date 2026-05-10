local function GetClosestVehicle(coords)
    local vehicles = GetGamePool('CVehicle')
    local closestDistance = -1
    local closestVehicle = -1
    local coords = coords or GetEntityCoords(cache.ped)

    for i = 1, #vehicles do
        local vehicleCoords = GetEntityCoords(vehicles[i])
        local distance = #(vehicleCoords - coords)

        if closestDistance == -1 or distance < closestDistance then
            closestVehicle = vehicles[i]
            closestDistance = distance
        end
    end

    if closestDistance ~= -1 and closestDistance <= 5.0 then
        return closestVehicle
    end

    return nil
end

RegisterNetEvent('vehicle_inspection:client:repairWindows', function()
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local vehicle = GetClosestVehicle(coords)

    if not vehicle or vehicle == 0 then
        lib.notify({
            title = 'Error',
            description = locale('no_vehicle_found'),
            type = 'error'
        })
        return
    end

    -- Face the vehicle
    TaskTurnPedToFaceEntity(ped, vehicle, 1000)
    Wait(1000)

    if lib.progressBar({
        duration = 5000,
        label = 'Replacing Windows...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
        anim = {
            dict = 'mini@repair',
            clip = 'fixing_a_ped'
        },
    }) then
        for i=0, 7 do
            FixVehicleWindow(vehicle, i)
        end
        lib.notify({
            title = 'Repair Successful',
            description = 'Vehicle windows have been replaced.',
            type = 'success'
        })
        TriggerServerEvent('vehicle_inspection:server:removeItem', 'cosmetic_part') -- Assuming cosmetic_part or similar is used for windows
    else
        lib.notify({
            title = 'Cancelled',
            type = 'error'
        })
    end
end)

RegisterNetEvent('vehicle_inspection:client:repairTires', function()
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local vehicle = GetClosestVehicle(coords)

    if not vehicle or vehicle == 0 then
        lib.notify({
            title = 'Error',
            description = locale('no_vehicle_found'),
            type = 'error'
        })
        return
    end

    TaskTurnPedToFaceEntity(ped, vehicle, 1000)
    Wait(1000)

    if lib.progressBar({
        duration = 5000,
        label = 'Replacing Tires...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
        anim = {
            dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
            clip = 'machinic_loop_mechandplayer'
        },
    }) then
        local numWheels = GetVehicleNumberOfWheels(vehicle)
        for i=0, numWheels-1 do
            SetVehicleTyreFixed(vehicle, i)
        end
        lib.notify({
            title = 'Repair Successful',
            description = 'Vehicle tires have been replaced.',
            type = 'success'
        })
        TriggerServerEvent('vehicle_inspection:server:removeItem', 'tyre_replacement')
    else
        lib.notify({
            title = 'Cancelled',
            type = 'error'
        })
    end
end)
