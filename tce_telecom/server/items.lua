-- server/items.lua
-- Requires Bridge files to be loaded first via fxmanifest

Citizen.CreateThread(function()
    -- Ensure bridge is loaded
    while not Bridge or not Bridge.Framework do Wait(100) end

    -- Register Star Phone
    Bridge.Framework.RegisterUsableItem(Config.Items.PhoneStar, function(source, item)
        local metadata = item.info or {}

        if metadata.water_damaged then
            TriggerClientEvent('tce_telecom:client:Notify', source, "This phone is fried.", "error")
        end

        TriggerClientEvent('tce_telecom:client:OpenPhone', source, {
            brand = 'star',
            imei = metadata.imei,
            battery = metadata.battery,
            screenCracked = metadata.screen_cracked,
            waterDamaged = metadata.water_damaged
        })
    end)

    -- Register iTones Phone
    Bridge.Framework.RegisterUsableItem(Config.Items.PhoneITones, function(source, item)
        local metadata = item.info or {}

        if metadata.water_damaged then
            TriggerClientEvent('tce_telecom:client:Notify', source, "This phone is fried.", "error")
        end

        TriggerClientEvent('tce_telecom:client:OpenPhone', source, {
            brand = 'itones',
            imei = metadata.imei,
            battery = metadata.battery,
            screenCracked = metadata.screen_cracked,
            waterDamaged = metadata.water_damaged
        })
    end)
end)
