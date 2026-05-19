-- tce_telecom/server/infrastructure.lua

local BlackoutZones = {}

MySQL.ready(function()
    local zones = MySQL.query.await('SELECT id, coords, radius FROM telecom_infrastructure WHERE is_broken = 1')
    if zones then
        for _, z in ipairs(zones) do
            table.insert(BlackoutZones, {
                id = z.id,
                coords = json.decode(z.coords),
                radius = z.radius
            })
        end
    end
end)

RegisterNetEvent('tce_telecom:server:PoleDestroyed', function(coords)
    local source = source

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
