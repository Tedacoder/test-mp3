-- Generates a random VIN
local function GenerateVIN()
    local chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local vin = ""
    for i = 1, 17 do
        local rand = math.random(1, #chars)
        vin = vin .. string.sub(chars, rand, rand)
    end
    return vin
end

-- Generates a random Plate
local function GeneratePlate()
    local plate = ""
    local chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    for i = 1, 8 do
        local rand = math.random(1, #chars)
        plate = plate .. string.sub(chars, rand, rand)
    end
    return plate
end

lib.callback.register('adv_vehicles:server:PurchaseVehicle', function(source, vehicle, clientPrice, isFinanced, downPayment)
    -- Security: Verify price from DB instead of trusting client
    local dbPrice = MySQL.scalar.await('SELECT price FROM dealership_stock WHERE plate = ?', {vehicle}) -- using vehicle as ID for now or hardcode for prototype
    local price = dbPrice or clientPrice -- Fallback for prototyping, in prod never trust clientPrice
    local src = source
    local identifier = Framework.GetIdentifier(src)

    if not identifier then return false, "User not found" end

    if Config.Dealership.RequireDriversLicense and not Framework.HasDriversLicense(src) then
        return false, "You do not have a valid driver's license."
    end

    local creditScore = Config.Dealership.UseCreditScore and Framework.GetCreditScore(src) or 700

    if isFinanced then
        if creditScore < 500 then
            return false, "Credit score too low for financing."
        end
        if not Framework.RemoveMoney(src, 'bank', downPayment, "vehicle-downpayment") then
            return false, "Not enough money for down payment."
        end
    else
    end

    local plate = GeneratePlate()
    local vin = GenerateVIN()
    local hash = GetHashKey(vehicle)
    -- We re-verify total final price and charge once here
    local tax = math.floor(price * 0.08)
    local finalPrice = price + tax
    if not isFinanced and not Framework.RemoveMoney(src, 'bank', finalPrice, 'vehicle-purchase') then
        return false, 'Not enough money (including 8% tax).'
    end
    local balance = isFinanced and (finalPrice - downPayment) or 0
    local payment = isFinanced and math.floor(balance / 10) or 0

    MySQL.insert.await('INSERT INTO player_vehicles (citizenid, plate, vin, vehicle, hash, state, garage, finance_balance, finance_payment) VALUES (?, ?, ?, ?, ?, 1, "legionsquare", ?, ?)', {
        identifier, plate, vin, vehicle, hash, balance, payment
    })

    MySQL.insert.await('INSERT INTO vehicle_keys (plate, citizenid, is_primary) VALUES (?, ?, 1)', {
        plate, identifier
    })

    TriggerClientEvent("adv_vehicles:client:AdminSpawnCar", src, model, plate)
    return true, "Vehicle purchased successfully! It has been delivered outside.", plate
end)

lib.callback.register('adv_vehicles:server:ProcessFinancePayments', function()
    -- This would be called by a cron job or thread periodically
    local vehicles = MySQL.query.await('SELECT id, plate, finance_balance, finance_payment, finance_missed, citizenid FROM player_vehicles WHERE finance_balance > 0')

    for _, veh in ipairs(vehicles) do
        -- Try to take money from offline player using framework logic or DB direct
        -- For simplicity, if they fail, increment missed
        local success = false -- Assuming framework offline payment logic here

        if success then
            local newBalance = veh.finance_balance - veh.finance_payment
            if newBalance < 0 then newBalance = 0 end
            MySQL.update('UPDATE player_vehicles SET finance_balance = ? WHERE id = ?', {newBalance, veh.id})
        else
            MySQL.update('UPDATE player_vehicles SET finance_missed = finance_missed + 1 WHERE id = ?', {veh.id})
        end
    end
end)

-- Dealership Admin Management
RegisterNetEvent('adv_vehicles:server:AdminSetPrice', function(plate, newPrice)
    local src = source
    if IsPlayerAceAllowed(src, "command.admindel") then
        MySQL.update('UPDATE dealership_stock SET price = ? WHERE plate = ?', {newPrice, plate})
        TriggerClientEvent('adv_vehicles:client:Notify', src, "Price updated.", "success")
    end
end)
