Framework = {}

local coreObj = nil
if Config.Framework == "QBOX" then
    coreObj = exports.qbx_core
elseif Config.Framework == "QB" then
    coreObj = exports['qb-core']:GetCoreObject()
elseif Config.Framework == "ESX" then
    coreObj = exports['es_extended']:getSharedObject()
end

function Framework.GetPlayer(source)
    if Config.Framework == "QBOX" or Config.Framework == "QB" then
        return coreObj:GetPlayer(source)
    elseif Config.Framework == "ESX" then
        return coreObj.GetPlayerFromId(source)
    end
    return nil
end

function Framework.GetIdentifier(source)
    local player = Framework.GetPlayer(source)
    if not player then return nil end

    if Config.Framework == "QBOX" or Config.Framework == "QB" then
        return player.PlayerData.citizenid
    elseif Config.Framework == "ESX" then
        return player.identifier
    end
    return nil
end

function Framework.HasItem(source, item, amount)
    amount = amount or 1
    if Config.Framework == "QBOX" then
        return exports.ox_inventory:Search(source, 'count', item) >= amount
    elseif Config.Framework == "QB" then
        local player = Framework.GetPlayer(source)
        local itemData = player.Functions.GetItemByName(item)
        return itemData and itemData.amount >= amount
    elseif Config.Framework == "ESX" then
        local player = Framework.GetPlayer(source)
        local itemData = player.getInventoryItem(item)
        return itemData and itemData.count >= amount
    end
    return false
end

function Framework.HasDriversLicense(source)
    local player = Framework.GetPlayer(source)
    if not player then return false end

    -- Check physical item first (Universal fallback)
    if Framework.HasItem(source, "driver_license", 1) then
        return true
    end

    if Config.Framework == "QBOX" or Config.Framework == "QB" then
        -- QBCore / Qbox handles metadata licenses
        -- Some versions spell it 'licenses', others 'licences'
        local meta = player.PlayerData.metadata
        local licenseData = meta['licences'] or meta['licenses']

        if licenseData and (licenseData.drive or licenseData.driver) then
            return true
        end
        return false
    elseif Config.Framework == "ESX" then
        local hasLicense = false
        local p = promise.new()
        TriggerEvent('esx_license:checkLicense', source, 'drive', function(has)
            hasLicense = has
            p:resolve()
        end)
        Citizen.Await(p)
        return hasLicense
    end

    return true -- Standalone assumes true unless item system implemented
end

function Framework.GetCreditScore(source)
    -- Stub for external banking connection like Prism Banking if used.
    -- Default to a good score if not implemented.
    return 700
end

function Framework.AddMoney(source, type, amount, reason)
    local player = Framework.GetPlayer(source)
    if not player then return false end

    if Config.Framework == "QBOX" or Config.Framework == "QB" then
        return player.Functions.AddMoney(type, amount, reason)
    elseif Config.Framework == "ESX" then
        if type == "cash" then type = "money" end
        player.addAccountMoney(type, amount, reason)
        return true
    end
    return true
end

function Framework.RemoveMoney(source, type, amount, reason)
    local player = Framework.GetPlayer(source)
    if not player then return false end

    -- Handle Prism Banking integration if active
    if type == 'bank' and GetResourceState('prism-banking') == 'started' then
        local success = exports['prism-banking']:RemoveMoney(source, amount, reason)
        return success -- DO NOT FALL BACK if Prism is running to prevent double charge or bypass
    end

    if Config.Framework == "QBOX" or Config.Framework == "QB" then
        return player.Functions.RemoveMoney(type, amount, reason)
    elseif Config.Framework == "ESX" then
        if type == "cash" then type = "money" end
        local balance = player.getAccount(type).money
        if balance >= amount then
            player.removeAccountMoney(type, amount, reason)
            return true
        end
        return false
    end
    return true
end
