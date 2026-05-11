lib.locale()

-- Framework specific checking - adaptable for QBCore/ESX/Qbox
local function getPlayerJob(source)
    if Config.Framework == 'qbx' then
        local player = exports.qbx_core:GetPlayer(source)
        if player and player.PlayerData and player.PlayerData.job then
            return player.PlayerData.job.name
        end
    elseif Config.Framework == 'qbcore' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local player = QBCore.Functions.GetPlayer(source)
        if player and player.PlayerData and player.PlayerData.job then
            return player.PlayerData.job.name
        end
    elseif Config.Framework == 'esx' then
        local ESX = exports['es_extended']:getSharedObject()
        local player = ESX.GetPlayerFromId(source)
        if player and player.job then
            return player.job.name
        end
    end
    return nil
end

local function removeMoney(source, amount)
    if Config.Framework == 'qbx' then
        local player = exports.qbx_core:GetPlayer(source)
        return player.Functions.RemoveMoney('cash', amount, 'vehicle-inspection') or player.Functions.RemoveMoney('bank', amount, 'vehicle-inspection')
    elseif Config.Framework == 'qbcore' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local player = QBCore.Functions.GetPlayer(source)
        return player.Functions.RemoveMoney('cash', amount, 'vehicle-inspection') or player.Functions.RemoveMoney('bank', amount, 'vehicle-inspection')
    elseif Config.Framework == 'esx' then
        local ESX = exports['es_extended']:getSharedObject()
        local player = ESX.GetPlayerFromId(source)
        if player.getMoney() >= amount then
            player.removeMoney(amount)
            return true
        elseif player.getAccount('bank').money >= amount then
            player.removeAccountMoney('bank', amount)
            return true
        end
    end
    return false
end

local function giveItem(source, item, amount, metadata)
    if Config.Inventory == 'ox_inventory' then
        exports.ox_inventory:AddItem(source, item, amount, metadata)
        return true
    elseif Config.Inventory == 'qs-inventory' then
        exports['qs-inventory']:AddItem(source, item, amount, nil, metadata)
        return true
    elseif Config.Inventory == 'qb-inventory' or Config.Framework == 'qbx' or Config.Framework == 'qbcore' then
        if Config.Framework == 'qbx' then
            local player = exports.qbx_core:GetPlayer(source)
            player.Functions.AddItem(item, amount, false, metadata)
            TriggerClientEvent('inventory:client:ItemBox', source, exports.qbx_core:GetSharedItems()[item], "add")
            return true
        elseif Config.Framework == 'qbcore' then
            local QBCore = exports['qb-core']:GetCoreObject()
            local player = QBCore.Functions.GetPlayer(source)
            player.Functions.AddItem(item, amount, false, metadata)
            TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[item], "add")
            return true
        end
    elseif Config.Framework == 'esx' then
        local ESX = exports['es_extended']:getSharedObject()
        local player = ESX.GetPlayerFromId(source)
        player.addInventoryItem(item, amount)
        return true
    end
    return false
end

lib.callback.register('vehicle_inspection:checkJob', function(source, jobType)
    local job = getPlayerJob(source)
    if not job then return false end

    if jobType == 'mechanic' then
        return Config.MechanicJobs[job] == true
    elseif jobType == 'police' then
        return Config.PoliceJobs[job] == true
    end
    return false
end)

lib.callback.register('vehicle_inspection:checkSticker', function(source, plate)
    local result = MySQL.single.await('SELECT * FROM `vehicle_inspections` WHERE `plate` = ?', {plate})
    if result then
        if result.failed_parts then
            result.failed_parts = json.decode(result.failed_parts)
        end

        -- Pre-format dates on the server to prevent client-side os.date nil crashes
        result.formatted_expiry = result.expiry and os.date('%m/%d/%Y', result.expiry) or 'N/A'
        if result.failed_date then
            result.formatted_failed_date = os.date('%m/%d/%Y', result.failed_date)
            result.formatted_impound_date = os.date('%m/%d/%Y', result.failed_date + Config.Timeframes.GracePeriod)
        else
            result.formatted_failed_date = 'N/A'
            result.formatted_impound_date = 'N/A'
        end
        return result
    end
    return nil
end)

lib.callback.register('vehicle_inspection:submitInspection', function(source, plate, status, failedParts, targetServerId)
    local src = source
    local target = targetServerId or src

    if target ~= src then
        local srcPed = GetPlayerPed(src)
        local targetPed = GetPlayerPed(target)
        if srcPed ~= 0 and targetPed ~= 0 then
            local srcCoords = GetEntityCoords(srcPed)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(srcCoords - targetCoords)
            if distance > 5.0 then
                return false, "Target player is too far away."
            end
        else
            return false, "Target player not found."
        end
    end

    local currentTime = os.time()
    local shopId = getPlayerJob(src) -- or use an actual shop ID if available

    local result = MySQL.single.await('SELECT * FROM `vehicle_inspections` WHERE `plate` = ?', {plate})
    local fee = Config.Fees.Initial
    local isReInspection = false

    if status == 'Fake' then
        fee = Config.Fees.Fake
    elseif result then
        if result.status == 'Failed' and result.failed_date then
            if (currentTime - result.failed_date) <= Config.Timeframes.ReInspection then
                fee = Config.Fees.ReInspection
                isReInspection = true
            end
        end
    end

    if not removeMoney(target, fee) then
        return false, locale('not_enough_money')
    end

    local feeMsg = string.format(isReInspection and locale('inspection_refee') or locale('inspection_fee'), fee)

    local expiry = nil
    local failedDate = nil
    local failedPartsJson = '[]'

    if status == 'Passed' or status == 'Fake' then
        expiry = currentTime + Config.Timeframes.Expiry
        -- Give certificate item
        local metadata = {
            description = 'Vehicle Inspection Certificate',
            plate = plate,
            status = 'Passed', -- Certificate looks real
            expiryDate = os.date('%m/%d/%Y', expiry)
        }

        giveItem(target, Config.Items.Certificate, 1, metadata)
    else
        failedDate = currentTime
        failedPartsJson = json.encode(failedParts)
    end

    if result then
        MySQL.update.await('UPDATE `vehicle_inspections` SET `status` = ?, `expiry` = ?, `failed_date` = ?, `failed_parts` = ?, `last_shop` = ? WHERE `plate` = ?', {
            status, expiry, failedDate, failedPartsJson, shopId, plate
        })
    else
        MySQL.insert.await('INSERT INTO `vehicle_inspections` (`plate`, `status`, `expiry`, `failed_date`, `failed_parts`, `last_shop`) VALUES (?, ?, ?, ?, ?, ?)', {
            plate, status, expiry, failedDate, failedPartsJson, shopId
        })
    end

    return true, feeMsg
end)

-- Export for MDT integration
exports('GetVehicleInspection', function(plate)
    local result = MySQL.single.await('SELECT * FROM `vehicle_inspections` WHERE `plate` = ?', {plate})
    if result then
        local statusStr = result.status
        local expiryDate = result.expiry and os.date('%m/%d/%Y', result.expiry) or 'N/A'
        local failedDate = result.failed_date and os.date('%m/%d/%Y', result.failed_date) or 'N/A'
        local impoundDate = result.failed_date and os.date('%m/%d/%Y', result.failed_date + Config.Timeframes.GracePeriod) or 'N/A'

        local partsList = "None"
        if result.failed_parts then
            local decoded = json.decode(result.failed_parts)
            if type(decoded) == 'table' and #decoded > 0 then
                partsList = table.concat(decoded, ', ')
            end
        end

        local report = string.format("[VEHICLE REPORT - PLATE: %s]\nStatus: %s\n", plate, statusStr)
        if statusStr == 'Failed' then
            report = report .. string.format("Date of Failure: %s\nDefects: [%s]\nInstruction: Vehicle must be repaired and re-inspected by %s.", failedDate, partsList, impoundDate)
        else
            report = report .. string.format("Expiry Date: %s", expiryDate)
        end

        return {
            status = result.status,
            expiry = result.expiry,
            failed_date = result.failed_date,
            failed_parts = result.failed_parts,
            report_string = report
        }
    end
    return nil
end)

exports('RegisterNewVehicle', function(plate)
    if not plate then return false end
    plate = string.gsub(plate, '^%s*(.-)%s*$', '%1')

    local currentTime = os.time()
    local expiry = currentTime + Config.Timeframes.Expiry

    local result = MySQL.single.await('SELECT * FROM `vehicle_inspections` WHERE `plate` = ?', {plate})
    if result then
        MySQL.update.await('UPDATE `vehicle_inspections` SET `status` = ?, `expiry` = ?, `failed_date` = NULL, `failed_parts` = ? WHERE `plate` = ?', {
            'Passed', expiry, '[]', plate
        })
    else
        MySQL.insert.await('INSERT INTO `vehicle_inspections` (`plate`, `status`, `expiry`, `failed_date`, `failed_parts`) VALUES (?, ?, ?, NULL, ?)', {
            plate, 'Passed', expiry, '[]'
        })
    end
    return true
end)
