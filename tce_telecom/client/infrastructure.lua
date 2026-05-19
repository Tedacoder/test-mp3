-- tce_telecom/client/infrastructure.lua

-- Targetable/Destructible Telephone Poles
local poleModels = {
    `prop_utility_pole_01a`,
    `prop_utility_pole_02`
}

-- Network outage tracking
local inBlackoutZone = false

Citizen.CreateThread(function()
    -- Thread to check for broken entities (fake/stubbed for grid system)
    -- In a real scenario, we might use GetEntityHealth or rely on an event.
    while true do
        Wait(5000)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        for _, model in ipairs(poleModels) do
            local pole = GetClosestObjectOfType(coords.x, coords.y, coords.z, 20.0, model, false, false, false)
            if pole ~= 0 then
                -- Check if pole is destroyed/broken
                if HasEntityBeenDamagedByWeapon(pole, 0, 2) or GetEntityHealth(pole) <= 0 then
                    -- Only trigger if this specific entity hasn't already been reported
                    if not Entity(pole).state.isDestroyed then
                        local poleCoords = GetEntityCoords(pole)
                        TriggerServerEvent('tce_telecom:server:PoleDestroyed', poleCoords)

                        -- Set local statebag to prevent endless spam
                        Entity(pole).state:set('isDestroyed', true, false)
                        ClearEntityLastDamageEntity(pole)
                    end
                end
            end
        end
    end
end)

-- Receive blackout zones from server
RegisterNetEvent('tce_telecom:client:UpdateNetworkZones', function(zones)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local wasInZone = inBlackoutZone
    inBlackoutZone = false

    for _, zone in ipairs(zones) do
        local dist = #(coords - vector3(zone.coords.x, zone.coords.y, zone.coords.z))
        if dist <= zone.radius then
            inBlackoutZone = true
            break
        end
    end

    if inBlackoutZone and not wasInZone then
        TriggerEvent('tce_telecom:client:Notify', "Network Signal Lost", "error")
        SendNUIMessage({ action = "networkState", hasSignal = false })
    elseif not inBlackoutZone and wasInZone then
        TriggerEvent('tce_telecom:client:Notify', "Network Signal Restored", "success")
        SendNUIMessage({ action = "networkState", hasSignal = true })
    end
end)
