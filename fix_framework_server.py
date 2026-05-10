with open('vehicle_inspection/server/main.lua', 'r') as f:
    content = f.read()

# Replace getPlayerJob
old_get_player_job = """local function getPlayerJob(source)
    local qb = GetResourceState('qb-core') == 'started'
    local esx = GetResourceState('es_extended') == 'started'
    local qbox = GetResourceState('qbx_core') == 'started'

    if qbox then
        local player = exports.qbx_core:GetPlayer(source)
        if player and player.PlayerData and player.PlayerData.job then
            return player.PlayerData.job.name
        end
    elseif qb then
        local QBCore = exports['qb-core']:GetCoreObject()
        local player = QBCore.Functions.GetPlayer(source)
        if player and player.PlayerData and player.PlayerData.job then
            return player.PlayerData.job.name
        end
    elseif esx then
        local ESX = exports['es_extended']:getSharedObject()
        local player = ESX.GetPlayerFromId(source)
        if player and player.job then
            return player.job.name
        end
    end

    return nil
end"""

new_get_player_job = """local function getPlayerJob(source)
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
end"""

content = content.replace(old_get_player_job, new_get_player_job)

# Replace removeMoney
old_remove_money = """local function removeMoney(source, amount)
    local qb = GetResourceState('qb-core') == 'started'
    local esx = GetResourceState('es_extended') == 'started'
    local qbox = GetResourceState('qbx_core') == 'started'

    if qbox then
        local player = exports.qbx_core:GetPlayer(source)
        return player.Functions.RemoveMoney('cash', amount, 'vehicle-inspection') or player.Functions.RemoveMoney('bank', amount, 'vehicle-inspection')
    elseif qb then
        local QBCore = exports['qb-core']:GetCoreObject()
        local player = QBCore.Functions.GetPlayer(source)
        return player.Functions.RemoveMoney('cash', amount, 'vehicle-inspection') or player.Functions.RemoveMoney('bank', amount, 'vehicle-inspection')
    elseif esx then
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
end"""

new_remove_money = """local function removeMoney(source, amount)
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
end"""

content = content.replace(old_remove_money, new_remove_money)

# Replace giveItem
old_give_item = """local function giveItem(source, item, amount, metadata)
    -- Attempt ox_inventory first as it's typically preferred if running
    if GetResourceState('ox_inventory') == 'started' then
        exports.ox_inventory:AddItem(source, item, amount, metadata)
        return true
    end

    local qb = GetResourceState('qb-core') == 'started'
    local esx = GetResourceState('es_extended') == 'started'
    local qbox = GetResourceState('qbx_core') == 'started'

    if qbox then
        local player = exports.qbx_core:GetPlayer(source)
        player.Functions.AddItem(item, amount, false, metadata)
        TriggerClientEvent('inventory:client:ItemBox', source, exports.qbx_core:GetCoreObject().Shared.Items[item], "add")
        return true
    elseif qb then
        local QBCore = exports['qb-core']:GetCoreObject()
        local player = QBCore.Functions.GetPlayer(source)
        player.Functions.AddItem(item, amount, false, metadata)
        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[item], "add")
        return true
    elseif esx then
        local ESX = exports['es_extended']:getSharedObject()
        local player = ESX.GetPlayerFromId(source)
        player.addInventoryItem(item, amount)
        return true
    end

    return false
end"""

new_give_item = """local function giveItem(source, item, amount, metadata)
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
            TriggerClientEvent('inventory:client:ItemBox', source, exports.qbx_core:GetCoreObject().Shared.Items[item], "add")
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
end"""

content = content.replace(old_give_item, new_give_item)

with open('vehicle_inspection/server/main.lua', 'w') as f:
    f.write(content)
