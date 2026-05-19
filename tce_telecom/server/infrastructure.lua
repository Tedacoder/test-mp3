-- tce_telecom/server/infrastructure.lua

local BlackoutZones = {}

MySQL.ready(function()
    local zones = MySQL.query.await('SELECT pole_id, coords, radius FROM telecom_infrastructure WHERE is_broken = 1')
    if zones then
        for _, z in ipairs(zones) do
            table.insert(BlackoutZones, {
                id = z.pole_id,
                coords = json.decode(z.coords),
                radius = z.radius
            })
        end
    end
end)

RegisterNetEvent('tce_telecom:server:PoleDestroyed', function(coords)
    local src = source
    local ped = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(ped)

    -- Security: Validate the player is actually near the coordinates they claim to have destroyed
    local dist = #(playerCoords - coords)
    if dist > 30.0 then
        print("^1[TCE Telecom] WARNING: Player " .. src .. " attempted to trigger PoleDestroyed from too far away!^7")
        return
    end

    -- Security: Rate Limit / Deduplicate
    for _, zone in ipairs(BlackoutZones) do
        local zoneDist = #(vector3(zone.coords.x, zone.coords.y, zone.coords.z) - coords)
        if zoneDist < 10.0 then return end -- Already a blackout zone here, ignore spam
    end

    -- In a full implementation, you'd insert this into the database.
    local newZone = {
        id = #BlackoutZones + 1,
        coords = coords,
        radius = 150 -- default 150m outage
    }
    table.insert(BlackoutZones, newZone)

    -- Broadcast the new zone to all clients so they drop signal if nearby
    TriggerClientEvent('tce_telecom:client:UpdateNetworkZones', -1, BlackoutZones)

    -- Alert telecom job workers to go repair it
    -- TriggerClientEvent('tce_telecom:client:TelecomAlert', -1, coords)
end)
