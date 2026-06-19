-- tce_telecom/server/apps/jobs.lua

Citizen.CreateThread(function()
    while not Bridge or not Bridge.Framework do Wait(100) end

    lib.callback.register('tce_telecom:server:GetJobs', function(source)
        return Bridge.Framework.GetAvailableJobs()
    end)

    lib.callback.register('tce_telecom:server:ApplyForJob', function(source, jobId)
        local availableJobs = Bridge.Framework.GetAvailableJobs()
        local isAllowed = false

        for _, job in ipairs(availableJobs) do
            if job.id == jobId then
                isAllowed = true
                break
            end
        end

        if not isAllowed then
            print("^1[TCE Telecom] WARNING: Player " .. source .. " attempted to exploit restricted job assignment: " .. tostring(jobId) .. "^7")
            return false
        end

        return Bridge.Framework.SetPlayerJob(source, jobId)
    end)
end)
