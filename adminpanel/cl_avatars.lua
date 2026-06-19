local PlayerPhotoCache = {}
local activeHandles = {}

function GetInGamePlayerMugshot(targetPlayerId)
    if not targetPlayerId then return "images/default_avatar.png" end
    if PlayerPhotoCache[targetPlayerId] then
        return PlayerPhotoCache[targetPlayerId]
    end

    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetPlayerId))
    if not DoesEntityExist(targetPed) then return "images/default_avatar.png" end

    -- Limit active handles to prevent pool crash (limit is ~34)
    if #activeHandles >= 30 then
        local oldestHandle = table.remove(activeHandles, 1)
        UnregisterPedheadshot(oldestHandle.handle)
        PlayerPhotoCache[oldestHandle.id] = nil
    end

    local handle = RegisterPedheadshotTransparent(targetPed)

    local timeout = 1000
    while not IsPedheadshotReady(handle) or not IsPedheadshotValid(handle) do
        Wait(10)
        timeout = timeout - 10
        if timeout <= 0 then break end
    end

    if IsPedheadshotReady(handle) then
        local txdString = GetPedheadshotTxdString(handle)
        local finalImgData = "https://nui-img/" .. txdString .. "/" .. txdString

        if targetPlayerId then
            table.insert(activeHandles, { handle = handle, id = targetPlayerId })
            PlayerPhotoCache[targetPlayerId] = finalImgData
        end
        return finalImgData
    end

    if IsPedheadshotValid(handle) then
        UnregisterPedheadshot(handle)
    end

    return "images/default_avatar.png"
end

RegisterNetEvent('adminpanel:client:updateAvatar', function(targetId)
    local avatar = GetInGamePlayerMugshot(targetId)
    SendNUIMessage({
        type = "updatePlayerPreview",
        info = { avatarUrl = avatar }
    })
end)
