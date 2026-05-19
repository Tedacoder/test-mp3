-- client/hardware.lua

-- Water Hazard Loop
Citizen.CreateThread(function()
    while true do
        Wait(2000) -- Check every 2 seconds to keep footprint low

        local ped = PlayerPedId()
        if IsPedSwimmingUnderWater(ped) then
            if math.random(1, 100) <= Config.WaterDamageChance then
                -- Trigger server to check for waterproof case item
                -- If no case, it sets water_damaged metadata to true on the phone item
                TriggerServerEvent('tce_telecom:server:ProcessWaterDamage')
            end
        end
    end
end)

-- High Speed Crash / Screen Cracking Loop
Citizen.CreateThread(function()
    local lastSpeed = 0
    while true do
        Wait(500)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            local currentSpeed = GetEntitySpeed(vehicle) * 2.236936 -- convert m/s to mph

            -- Detect rapid deceleration (crash)
            if lastSpeed > 60.0 and currentSpeed < 10.0 then
                -- 20% chance to crack screen on severe crash
                if math.random(1, 100) <= 20 then
                    TriggerServerEvent('tce_telecom:server:ProcessScreenDamage')
                end
            end
            lastSpeed = currentSpeed
        else
            lastSpeed = 0
        end
    end
end)

-- Battery Depletion Loop
Citizen.CreateThread(function()
    while true do
        -- Deplete every 60 seconds based on Config rate
        Wait(60000)
        TriggerServerEvent('tce_telecom:server:DepleteBattery', Config.BatteryDecayRate)
    end
end)

-- Star Brand Exclusives: Privacy Mode
local isPrivacyMode = false
RegisterNUICallback('togglePrivacyMode', function(data, cb)
    isPrivacyMode = not isPrivacyMode

    if isPrivacyMode then
        TriggerEvent('tce_telecom:client:Notify', "Privacy Screen Enabled", "success")
        -- Logic to swap the render target material of the attached phone prop to black/blurred
    else
        TriggerEvent('tce_telecom:client:Notify', "Privacy Screen Disabled", "error")
        -- Restore render target
    end

    cb({ status = isPrivacyMode })
end)
