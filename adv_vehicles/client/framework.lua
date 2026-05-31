Framework = {}

local coreObj = nil
if Config.Framework == "QBOX" then
    -- QBOX client is somewhat standalone but uses some core exports if needed
elseif Config.Framework == "QB" then
    coreObj = exports['qb-core']:GetCoreObject()
elseif Config.Framework == "ESX" then
    coreObj = exports['es_extended']:getSharedObject()
end

function Framework.Notify(msg, type)
    if Config.UseOxLib then
        lib.notify({
            title = 'Vehicles',
            description = msg,
            type = type or 'inform'
        })
    elseif Config.Framework == "QBOX" or Config.Framework == "QB" then
        TriggerEvent('QBCore:Notify', msg, type)
    elseif Config.Framework == "ESX" then
        coreObj.showNotification(msg)
    else
        SetNotificationTextEntry('STRING')
        AddTextComponentString(msg)
        DrawNotification(0,1)
    end
end

function Framework.Progress(name, label, duration, useWhileDead, canCancel, dict, anim, flag, task, done, cancel)
    if Config.UseOxLib then
        if lib.progressBar({
            duration = duration,
            label = label,
            useWhileDead = useWhileDead,
            canCancel = canCancel,
            anim = {
                dict = dict,
                clip = anim,
                flag = flag
            },
            disable = {
                car = true,
                move = true
            }
        }) then
            if done then done() end
        else
            if cancel then cancel() end
        end
    elseif Config.Framework == "QBOX" or Config.Framework == "QB" then
        coreObj = exports['qb-core']:GetCoreObject() -- QBOX might still use QBCore functions for progressbar on some builds
        coreObj.Functions.Progressbar(name, label, duration, useWhileDead, canCancel, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {
            animDict = dict,
            anim = anim,
            flags = flag,
        }, {}, {}, function() -- Done
            if done then done() end
        end, function() -- Cancel
            if cancel then cancel() end
        end)
    end
end
