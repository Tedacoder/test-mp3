local seatbeltOn = false
local lastSpeed = 0.0

-- Vehicle Operations (Seatbelt, Damage Stalling, Doors/Windows)
CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            local speed = GetEntitySpeed(veh)
            local engineHealth = GetVehicleEngineHealth(veh)

            -- Damage Stalling Logic
            if engineHealth < 400.0 then
                SetVehicleEngineOn(veh, false, true, true)
                if math.random(1, 100) > 95 then
                    Framework.Notify("Engine stalled due to damage.", "error")
                end
                Wait(5000) -- Prevent immediate restart spam
            end

            -- Seatbelt ejection logic on high impact
            if not seatbeltOn and speed < (lastSpeed - 20.0) then
                local fwd = GetEntityForwardVector(veh)
                local coords = GetEntityCoords(ped)
                TaskLeaveVehicle(ped, veh, 4160)
                SetEntityCoords(ped, coords.x + fwd.x * 5.0, coords.y + fwd.y * 5.0, coords.z + 1.0)
                SetPedToRagdoll(ped, 5000, 5000, 0, 0, 0, 0)
                ApplyDamageToPed(ped, math.floor((lastSpeed - speed) * 2), false)
            end

            lastSpeed = speed

            -- Seatbelt Toggle (B key or D-Pad Down)
            if IsControlJustPressed(0, 29) or IsControlJustPressed(0, 187) then
                seatbeltOn = not seatbeltOn
                Framework.Notify(seatbeltOn and "Seatbelt Fastened" or "Seatbelt Unfastened", seatbeltOn and "success" or "error")
            end

            -- Prevent exiting if seatbelt is on
            if seatbeltOn then
                DisableControlAction(0, 75, true) -- Disable 'F'
            end
        else
            seatbeltOn = false
            lastSpeed = 0.0
            Wait(500)
        end
    end
end)

-- Interaction Menu for Doors/Windows/Hood/Trunk
RegisterNetEvent('adv_vehicles:client:VehicleInteraction', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        local coords = GetEntityCoords(ped)
        veh = lib.getClosestVehicle(coords, 5.0, true)
    end

    if veh == 0 then return end

    lib.registerContext({
        id = 'veh_interaction',
        title = 'Vehicle Controls',
        options = {
            {
                title = 'Toggle Hood',
                onSelect = function()
                    if GetVehicleDoorAngleRatio(veh, 4) > 0.0 then
                        SetVehicleDoorShut(veh, 4, false)
                    else
                        SetVehicleDoorOpen(veh, 4, false, false)
                    end
                end
            },
            {
                title = 'Toggle Trunk',
                onSelect = function()
                    if GetVehicleDoorAngleRatio(veh, 5) > 0.0 then
                        SetVehicleDoorShut(veh, 5, false)
                    else
                        SetVehicleDoorOpen(veh, 5, false, false)
                    end
                end
            },
            {
                title = 'Roll Down Windows',
                onSelect = function() RollDownWindows(veh) end
            },
            {
                title = 'Roll Up Windows',
                onSelect = function()
                    RollUpWindow(veh, 0)
                    RollUpWindow(veh, 1)
                    RollUpWindow(veh, 2)
                    RollUpWindow(veh, 3)
                end
            }
        }
    })
    lib.showContext('veh_interaction')
end)

RegisterCommand('vehcontrol', function()
    TriggerEvent('adv_vehicles:client:VehicleInteraction')
end)
