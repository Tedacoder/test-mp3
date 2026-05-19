-- tce_telecom/server/apps/directory.lua

lib.callback.register('tce_telecom:server:GetDirectory', function(source)
    -- Fetch the global directory (e.g. emergency services, registered businesses)
    -- In a full implementation, this might join multiple tables (businesses, jobs, and unlisted players)

    local directory = {
        { name = "Los Santos Police Department", number = "911", is_emergency = true },
        { name = "Pillbox Medical Services", number = "911", is_emergency = true },
        { name = "Downtown Cab Co.", number = "555-0199", is_emergency = false },
        { name = "Benny's Original Motor Works", number = "555-0100", is_emergency = false },
        { name = "TCE Telecommunications", number = "555-0001", is_emergency = false }
    }

    -- Here we would also append active landline numbers from `telecom_landlines` where `is_unlisted` = 0

    return directory
end)
