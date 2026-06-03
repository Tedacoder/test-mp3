local isHotwiring = false

RegisterNetEvent('adv_vehicles:client:StartHotwire', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)

    if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped then
        Framework.Notify("You must be in the driver's seat to hotwire.", "error")
        return
    end

    if GetIsVehicleEngineRunning(veh) then
        Framework.Notify("The engine is already running.", "error")
        return
    end

    if isHotwiring then return end
    isHotwiring = true

    -- Disable controls while UI is open
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openHotwire"
    })

    -- Play animation
    lib.requestAnimDict("veh@std@ds@base")
    TaskPlayAnim(ped, "veh@std@ds@base", "hotwire", 8.0, 8.0, -1, 1, 0, false, false, false)
end)

RegisterNUICallback('hotwireResult', function(data, cb)
    SetNuiFocus(false, false)
    isHotwiring = false
    ClearPedTasks(PlayerPedId())

    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)

    if data.success then
        Framework.Notify("Hotwire successful!", "success")
        SetVehicleEngineOn(veh, true, true, false)
        TriggerEvent('adv_vehicles:client:ForceEngineState', true)
        -- Set vehicle as stolen on server
        local plate = GetVehicleNumberPlateText(veh)
        TriggerServerEvent('adv_vehicles:server:SetVehicleStolen', plate)
    else
        Framework.Notify("Hotwire failed. The alarm was triggered!", "error")
        SetVehicleAlarm(veh, true)
        SetVehicleAlarmTimeLeft(veh, 30000)
    end
    cb('ok')
end)

-- Hotwire Input
CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            if GetPedInVehicleSeat(veh, -1) == ped then
                -- Keyboard: H or Controller: RB + A
                if IsControlJustPressed(0, 74) or (IsControlPressed(0, 227) and IsControlJustPressed(0, 73)) then
                    TriggerEvent('adv_vehicles:client:StartHotwire')
                end
            end
        else
            Wait(500)
        end
    end
end)
