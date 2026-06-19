RegisterNetEvent('adv_vehicles:client:ToggleLocks', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)

    if veh == 0 then
        -- Try to find vehicle in front
        local coords = GetEntityCoords(ped)
        veh = lib.getClosestVehicle(coords, 5.0, true)
    end

    if veh and veh ~= 0 then
        local plate = GetVehicleNumberPlateText(veh)
        lib.callback('adv_vehicles:server:HasKeys', false, function(hasKey)
            if hasKey then
                local lockStatus = GetVehicleDoorLockStatus(veh)
                local newStatus = lockStatus == 1 and 2 or 1

                SetVehicleDoorsLocked(veh, newStatus)
                TriggerServerEvent('adv_vehicles:server:SetVehicleLock', plate, newStatus == 2)

                -- Animation
                TaskPlayAnim(ped, "anim@mp_player_intmenu@key_fob@", "fob_click", 8.0, 8.0, -1, 48, 1, false, false, false)

                -- Sound and Lights
                SetVehicleLights(veh, 2)
                Wait(200)
                SetVehicleLights(veh, 0)
                Wait(200)
                SetVehicleLights(veh, 2)
                Wait(200)
                SetVehicleLights(veh, 0)

                if newStatus == 2 then
                    Framework.Notify("Vehicle Locked", "error")
                else
                    Framework.Notify("Vehicle Unlocked", "success")
                end
            else
                Framework.Notify("You do not have keys for this vehicle.", "error")
            end
        end, plate)
    end
end)

RegisterNetEvent('adv_vehicles:client:SetVehicleLockState', function(plate, locked)
    local vehicles = GetGamePool('CVehicle')
    for _, veh in ipairs(vehicles) do
        if GetVehicleNumberPlateText(veh) == plate then
            SetVehicleDoorsLocked(veh, locked and 2 or 1)
            break
        end
    end
end)
