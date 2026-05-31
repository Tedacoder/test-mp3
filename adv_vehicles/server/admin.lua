-- Command for Upper Admins
RegisterCommand('admingivecar', function(source, args)
    local src = source
    if not IsPlayerAceAllowed(src, "command.admingivecar") then
        return
    end

    local targetId = tonumber(args[1])
    local model = args[2]

    if not targetId or not model then return end

    local identifier = Framework.GetIdentifier(targetId)
    if not identifier then return end

    local plate = "ADM" .. math.random(10000, 99999)
    local vin = "ADMIN" .. math.random(1000000000, 9999999999)
    local hash = GetHashKey(model)

    MySQL.insert.await('INSERT INTO player_vehicles (citizenid, plate, vin, model, hash, state, garage) VALUES (?, ?, ?, ?, ?, 1, "legionsquare")', {
        identifier, plate, vin, model, hash
    })

    MySQL.insert.await('INSERT INTO vehicle_keys (plate, citizenid, is_primary) VALUES (?, ?, 1)', {
        plate, identifier
    })

    TriggerClientEvent('adv_vehicles:client:AdminSpawnCar', targetId, model, plate)
end, true)
-- Complete anti-exploit for scratching VIN missing from previous admin.lua server script
RegisterNetEvent('adv_vehicles:server:ScratchVIN', function(plate)
    local src = source
    local vehicle = MySQL.query.await('SELECT id, stolen FROM player_vehicles WHERE plate = ?', {plate})
    if vehicle and vehicle[1] and vehicle[1].stolen == 1 then
        MySQL.update('UPDATE player_vehicles SET vin = "SCRATCHED" WHERE plate = ?', {plate})
    else
        print(("Player %s attempted to scratch VIN on an unowned/unstolen car."):format(GetPlayerName(src)))
    end
end)

-- Helper on server start to ensure columns exist because SQL files require manual execution by the user, and they might have missed it or got an error.
CreateThread(function()
    Wait(2000)

    local success1 = pcall(function()
        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS `dealership_stock` (
                `plate` VARCHAR(15) NOT NULL,
                `price` INT NOT NULL,
                PRIMARY KEY (`plate`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])
    end)

    local success2 = pcall(function()
        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS `vehicle_keys` (
                `id` INT NOT NULL AUTO_INCREMENT,
                `plate` VARCHAR(15) NOT NULL,
                `citizenid` VARCHAR(50) NOT NULL,
                `is_primary` TINYINT(1) DEFAULT 0,
                PRIMARY KEY (`id`),
                KEY `plate` (`plate`),
                KEY `citizenid` (`citizenid`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])
    end)

    -- Inject columns safely via raw query and catching errors if they already exist
    local columns = {
        {"vin", "VARCHAR(50) DEFAULT NULL"},
        {"locked", "TINYINT(1) DEFAULT 1"},
        {"stolen", "TINYINT(1) DEFAULT 0"},
        {"impounded", "TINYINT(1) DEFAULT 0"},
        {"impound_fee", "INT DEFAULT 0"},
        {"finance_balance", "INT DEFAULT 0"},
        {"finance_payment", "INT DEFAULT 0"},
        {"finance_missed", "INT DEFAULT 0"},
        {"insurance_tier", "VARCHAR(20) DEFAULT 'Basic'"}
    }

    for _, col in ipairs(columns) do
        local colName, colDef = col[1], col[2]
        pcall(function()
            MySQL.query.await(("ALTER TABLE `player_vehicles` ADD COLUMN `%s` %s"):format(colName, colDef))
        end)
    end
    print("^2[adv_vehicles] Database verified.^7")
end)
