local parkedVehiclesCache = {}
local isEngineOn = false
local seatbeltOn = false

-- Controller & Keyboard Input Thread
CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            local driver = GetPedInVehicleSeat(veh, -1) == ped

            if driver then
                -- Keyboard: G or Controller: D-Pad Right -> Engine
                if IsControlJustPressed(0, 47) or IsControlJustPressed(0, 175) then
                    TriggerEvent('adv_vehicles:client:ToggleEngine')
                end

                -- Keyboard: L or Controller: D-Pad Left -> Lock
                if IsControlJustPressed(0, 182) or IsControlJustPressed(0, 174) then
                    TriggerEvent('adv_vehicles:client:ToggleLocks')
                end
            end

            -- Track actual native engine state to prevent sync fighting
            if GetIsVehicleEngineRunning(veh) and not isEngineOn then
                -- This allows hotwires and native key exports to work without the script overriding them
                isEngineOn = true
            elseif not GetIsVehicleEngineRunning(veh) and isEngineOn then
                isEngineOn = false
            end
        else
            Wait(500)
        end
    end
end)

RegisterNetEvent('adv_vehicles:client:ToggleEngine', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        local plate = GetVehicleNumberPlateText(veh)
        lib.callback('adv_vehicles:server:HasKeys', false, function(hasKey)
            if hasKey then
                isEngineOn = not isEngineOn
                SetVehicleEngineOn(veh, isEngineOn, false, true)
                Framework.Notify(isEngineOn and "Engine turned ON" or "Engine turned OFF", "success")
            else
                Framework.Notify("You do not have keys for this vehicle.", "error")
            end
        end, plate)
    end
end)

RegisterNetEvent('adv_vehicles:client:ParkVehicle', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        local plate = GetVehicleNumberPlateText(veh)
        local vehicle = GetEntityModel(veh)
        -- Assume we get properties using core exports or a local function
        local props = {}
        local coords = GetEntityCoords(veh)
        local heading = GetEntityHeading(veh)
        local engineHealth = GetVehicleEngineHealth(veh)
        local bodyHealth = GetVehicleBodyHealth(veh)
        local fuel = GetVehicleFuelLevel(veh)
        local isLocked = GetVehicleDoorLockStatus(veh) == 2

        TriggerServerEvent('adv_vehicles:server:ParkVehicle', plate, vehicle, props, coords, heading, engineHealth, bodyHealth, fuel, isLocked)
        Framework.Notify("Vehicle parked on the street.", "success")

        TaskLeaveVehicle(ped, veh, 0)
        Wait(2000)
        DeleteEntity(veh)
    else
        Framework.Notify("You must be inside a vehicle to park it.", "error")
    end
end)

-- Command to test parking
RegisterCommand('park', function()
    TriggerEvent('adv_vehicles:client:ParkVehicle')
end)

-- EV vs Gas Logic Addition to existing loop
-- To keep it clean, replace the simple consumption logic with EV logic checking vehicle classes
CreateThread(function()
    while true do
        Wait(10000)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            if GetPedInVehicleSeat(veh, -1) == ped and GetIsVehicleEngineRunning(veh) then
                local fuel = GetVehicleFuelLevel(veh)
                local speed = GetEntitySpeed(veh)
                local class = GetVehicleClass(veh)

                -- Class 18 is generally Emergency but can be hybrid. Let's use generic logic for all.
                -- However, for EV, GTA natively doesn't use fuel, but we simulate battery.
                local consumptionRate = 0.05
                if speed > 10.0 then consumptionRate = 0.2 end
                if speed > 30.0 then consumptionRate = 0.5 end

                -- EVs consume less "fuel" per tick
                local vehicle = GetEntityModel(veh)
                if GetVehicleHandlingFloat(veh, 'CHandlingData', 'fInitialDriveForce') > 0.3 then -- Rough heuristic or specific EV list
                    consumptionRate = consumptionRate * 0.5
                end

                if fuel > 0 then
                    SetVehicleFuelLevel(veh, fuel - consumptionRate)
                else
                    SetVehicleEngineOn(veh, false, true, true)
                end
            end
        else
            Wait(2000)
        end
    end
end)

RegisterNetEvent('adv_vehicles:client:ForceEngineState', function(state)
    isEngineOn = state
end)
