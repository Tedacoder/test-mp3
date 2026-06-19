-- client/core.lua
local isPhoneOpen = false

RegisterNetEvent('tce_telecom:client:OpenPhone', function(phoneData)
    if isPhoneOpen then return end

    isPhoneOpen = true
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = "openPhone",
        data = phoneData
    })

    -- Play phone animation here
end)

RegisterNUICallback('closePhone', function(data, cb)
    isPhoneOpen = false
    SetNuiFocus(false, false)
    -- Stop phone animation here
    cb('ok')
end)

RegisterNetEvent('tce_telecom:client:Notify', function(msg, type)
    lib.notify({
        title = 'Phone',
        description = msg,
        type = type or 'inform'
    })
end)
