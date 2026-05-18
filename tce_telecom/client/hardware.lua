-- client/hardware.lua

-- Water Hazard Loop
Citizen.CreateThread(function()
    while true do
        Wait(2000) -- Check every 2 seconds to keep footprint low

        local ped = PlayerPedId()
        if IsPedSwimmingUnderWater(ped) then
            -- Note: In a full implementation, you would trigger a server callback
            -- here to check the player's inventory for a waterproof case.
            -- If no case is found, trigger a server event to update the phone metadata to `water_damaged = true`
        end
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
