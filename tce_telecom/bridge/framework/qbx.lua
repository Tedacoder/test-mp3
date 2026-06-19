-- Qbox Bridge
if Config.Framework ~= 'qbx' then return end

local qbx = exports.qbx_core

Bridge = Bridge or {}
Bridge.Framework = {
    GetPlayerIdentifier = function(source)
        local player = qbx:GetPlayer(source)
        return player and player.PlayerData.citizenid or nil
    end,

    GetPlayerPhone = function(source)
        local player = qbx:GetPlayer(source)
        return player and player.PlayerData.charinfo.phone or nil
    end,

    RegisterUsableItem = function(itemName, callback)
        -- Qbox specific registration without using .Functions table
        qbx:CreateUseableItem(itemName, function(source, item)
            callback(source, item)
        end)
    end,

    GetSharedItems = function()
        -- Memory: Use GetSharedItems() for qbx_core
        return qbx:GetSharedItems()
    end,

    -- Returns correctly formatted server-side time/date since os.date fails on modern clients
    GetServerTime = function()
        return os.date('%Y-%m-%d %H:%M:%S')
    end,

    GetAvailableJobs = function()
        -- In a real scenario, this would query qbx_core.Shared.Jobs, but we mock a configured list for the app
        return {
            { id = "police", name = "LSPD Officer", salary = 150 },
            { id = "ambulance", name = "EMS Paramedic", salary = 120 },
            { id = "mechanic", name = "Benny's Mechanic", salary = 100 },
            { id = "telecom", name = "TCE Field Technician", salary = 95 },
            { id = "taxi", name = "Cab Driver", salary = 80 }
        }
    end,

    SetPlayerJob = function(source, job_id)
        local player = qbx:GetPlayer(source)
        if not player then return false end
        return player.Functions.SetJob(job_id, 0)
    end
}
