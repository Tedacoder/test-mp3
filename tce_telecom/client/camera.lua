-- tce_telecom/client/camera.lua

-- NUI Callback to handle the photo capture event
RegisterNUICallback('capturePhoto', function(data, cb)
    local filter = data.filter or "none"

    -- Stub logic for screenshot-basic integration
    -- Since the actual screenshot-basic resource requires FiveM Natives (GetConvar),
    -- we cannot fully mock it in this vanilla lua stub without throwing errors.
    print("^2[TCE Telecom]^7 Capturing photo with filter: " .. filter)

    TriggerEvent('tce_telecom:client:Notify', "Photo captured! (Filter: " .. filter .. ")", "success")

    -- In full implementation:
    -- exports['screenshot-basic']:requestScreenshotUpload(webhookUrl, "files[]", function(data)
    --     local image = json.decode(data)
    --     TriggerServerEvent('tce_telecom:server:SavePhoto', image.attachments[1].proxy_url)
    -- end)

    cb('ok')
end)
