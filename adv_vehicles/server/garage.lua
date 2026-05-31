lib.callback.register('adv_vehicles:server:GetPlayerVehicles', function(source)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    if not identifier then return {} end

    local vehicles = MySQL.query.await('SELECT * FROM player_vehicles WHERE citizenid = ?', {identifier})
    return vehicles
end)

RegisterNetEvent('adv_vehicles:server:StoreVehicle', function(plate, garageName, engineHealth, bodyHealth, fuel)
    local src = source
    local identifier = Framework.GetIdentifier(src)

    local isOwner = MySQL.scalar.await('SELECT id FROM player_vehicles WHERE plate = ? AND citizenid = ?', {plate, identifier})
    if isOwner then
        MySQL.update('UPDATE player_vehicles SET state = 1, garage = ?, engine_health = ?, body_health = ?, fuel = ? WHERE plate = ?', {
            garageName, engineHealth, bodyHealth, fuel, plate
        })
    end
end)

RegisterNetEvent('adv_vehicles:server:SetVehicleState', function(plate, state)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    local isOwner = MySQL.scalar.await('SELECT id FROM player_vehicles WHERE plate = ? AND citizenid = ?', {plate, identifier})
    if not isOwner then return end
    MySQL.update('UPDATE player_vehicles SET state = ? WHERE plate = ?', {state, plate})
end)

RegisterNetEvent('adv_vehicles:server:RenameVehicle', function(plate, newName)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    local isOwner = MySQL.scalar.await('SELECT id FROM player_vehicles WHERE plate = ? AND citizenid = ?', {plate, identifier})
    if isOwner then
        -- We repurpose vehicle string as alias for UI purposes
        MySQL.update('UPDATE player_vehicles SET alias = ? WHERE plate = ?', {newName, plate})
    end
end)
