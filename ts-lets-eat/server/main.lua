local QBCore = nil
local ESX = nil

if Config.Framework == 'qbox' or Config.Framework == 'qbcore' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
end

-- Server-side helper to remove items using configured inventory
local function RemoveItems(src, ingredients)
    for item, amount in pairs(ingredients) do
        if Config.Inventory == 'ox' then
            exports.ox_inventory:RemoveItem(src, item, amount)
        elseif Config.Inventory == 'qb' then
            local Player = QBCore.Functions.GetPlayer(src)
            Player.Functions.RemoveItem(item, amount)
        elseif Config.Inventory == 'qs' then
            -- qs-inventory typically uses ox_inventory exports or ESX natively, fallback to ESX
            if Config.Framework == 'esx' then
                local xPlayer = ESX.GetPlayerFromId(src)
                xPlayer.removeInventoryItem(item, amount)
            end
        end
    end
end

-- Check if player has all required ingredients
local function HasIngredients(src, ingredients)
    for item, amount in pairs(ingredients) do
        if Config.Inventory == 'ox' then
            local count = exports.ox_inventory:GetItemCount(src, item)
            if count < amount then return false end
        elseif Config.Inventory == 'qb' then
            local Player = QBCore.Functions.GetPlayer(src)
            local itemData = Player.Functions.GetItemByName(item)
            if not itemData or itemData.amount < amount then return false end
        elseif Config.Inventory == 'qs' then
            if Config.Framework == 'esx' then
                local xPlayer = ESX.GetPlayerFromId(src)
                local itemData = xPlayer.getInventoryItem(item)
                if not itemData or itemData.count < amount then return false end
            end
        end
    end
    return true
end

-- Spoilage check helper
local function CalculateSpoilage(itemData)
    if not Config.Spoilage.enabled then return false end

    local creationTime = itemData.metadata and itemData.metadata.creationTime
    if not creationTime then return false end

    local itemConfig = Config.Items[itemData.name]
    if not itemConfig then return false end

    local rateHours = Config.Spoilage.rates[itemConfig.spoil_rate]
    if not rateHours then return false end

    local currentTime = os.time()
    local hoursPassed = (currentTime - creationTime) / 3600

    return hoursPassed > rateHours
end

-- Event to handle cooking completion
RegisterNetEvent('ts-lets-eat:server:FinishCooking', function(recipeName, portionSize, propCoords)
    local src = source

    if propCoords then
        local ped = GetPlayerPed(src)
        local pedCoords = GetEntityCoords(ped)
        if #(pedCoords - propCoords) > 5.0 then
            -- Player is too far away, likely exploiting
            return
        end
    end

    local recipe = Config.Recipes[recipeName]

    if not recipe then return end
    local portion = recipe.portions[portionSize]
    if not portion then return end

    if HasIngredients(src, portion.ingredients) then
        RemoveItems(src, portion.ingredients)

        -- Add the cooked meal with creation timestamp for spoilage tracking
        local metadata = { creationTime = os.time() }
        local infoData = { creationTime = os.time() } -- QBCore specifically uses 'info' for metadata internally

        if Config.Inventory == 'ox' then
            exports.ox_inventory:AddItem(src, recipe.output, portion.amount, metadata)
        elseif Config.Inventory == 'qb' then
            local Player = QBCore.Functions.GetPlayer(src)
            Player.Functions.AddItem(recipe.output, portion.amount, false, infoData)
        elseif Config.Inventory == 'qs' then
            if Config.Framework == 'esx' then
                local xPlayer = ESX.GetPlayerFromId(src)
                if xPlayer.addInventoryItem then
                    xPlayer.addInventoryItem(recipe.output, portion.amount, metadata)
                end
            end
        end

        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Success',
            description = 'You cooked ' .. portion.amount .. 'x ' .. recipeName,
            type = 'success'
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'You do not have the required ingredients.',
            type = 'error'
        })
    end
end)

-- Event to apply buffs when consuming a meal
RegisterNetEvent('ts-lets-eat:server:ConsumeItem', function(itemName)
    local src = source
    local item = Config.Items[itemName]

    if not item or item.type ~= 'meal' then return end

    -- Fetch metadata directly from inventory
    local serverMetadata = nil
    if Config.Inventory == 'ox' then
        local inv = exports.ox_inventory:GetInventoryItems(src)
        if inv then
            for _, v in pairs(inv) do
                if v.name == itemName then
                    serverMetadata = v.metadata
                    break
                end
            end
        end
    elseif Config.Inventory == 'qb' then
        local Player = QBCore.Functions.GetPlayer(src)
        local itemData = Player.Functions.GetItemByName(itemName)
        if itemData and itemData.info then
            serverMetadata = itemData.info
        end
    elseif Config.Inventory == 'qs' then
        if Config.Framework == 'esx' then
            local xPlayer = ESX.GetPlayerFromId(src)
            local itemData = xPlayer.getInventoryItem(itemName)
            if itemData and itemData.info then
                serverMetadata = itemData.info
            end
        elseif Config.Framework == 'qbox' or Config.Framework == 'qbcore' then
            local Player = QBCore.Functions.GetPlayer(src)
            local itemData = Player.Functions.GetItemByName(itemName)
            if itemData and itemData.info then
                serverMetadata = itemData.info
            end
        end
    end

    local isSpoiled = false
    if serverMetadata and serverMetadata.creationTime then
        isSpoiled = CalculateSpoilage({name = itemName, metadata = serverMetadata})
    end

    -- Remove the item and verify success FIRST
    -- (We must remove the item regardless of whether it is spoiled or not so players don't have infinite spoiled food)
    local removed = false
    if Config.Inventory == 'ox' then
        local success = exports.ox_inventory:RemoveItem(src, itemName, 1)
        if success then removed = true end
    elseif Config.Inventory == 'qb' then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player.Functions.RemoveItem(itemName, 1) then
            removed = true
        end
    elseif Config.Inventory == 'qs' then
        if Config.Framework == 'esx' then
            local xPlayer = ESX.GetPlayerFromId(src)
            local itemData = xPlayer.getInventoryItem(itemName)
            if itemData and itemData.count >= 1 then
                xPlayer.removeInventoryItem(itemName, 1)
                removed = true
            end
        elseif Config.Framework == 'qbox' or Config.Framework == 'qbcore' then
            local Player = QBCore.Functions.GetPlayer(src)
            if Player.Functions.RemoveItem(itemName, 1) then
                removed = true
            end
        end
    end

    if not removed then
        return
    end

    if isSpoiled then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Disgusting',
            description = 'This food has spoiled and tastes awful.',
            type = 'error'
        })
        -- Maybe apply sick buff
        return
    end

    local buffCategory = Config.Buffs.categories[item.category]
    if buffCategory and Config.Buffs.enabled then
        if Config.Framework == 'qbcore' or Config.Framework == 'qbox' then
            local Player = QBCore.Functions.GetPlayer(src)
            if Player then
                if buffCategory.type == 'satiation' then
                    local newHunger = math.min(100, Player.PlayerData.metadata['hunger'] + (20 * (buffCategory.hungerMultiplier or 1.0)))
                    local newThirst = math.min(100, Player.PlayerData.metadata['thirst'] + (10 * (buffCategory.thirstMultiplier or 1.0)))
                    Player.Functions.SetMetaData('hunger', newHunger)
                    Player.Functions.SetMetaData('thirst', newThirst)
                    TriggerClientEvent('hud:client:UpdateNeeds', src, newHunger, newThirst)
                elseif buffCategory.type == 'thirst' then
                    local newThirst = math.min(100, Player.PlayerData.metadata['thirst'] + (20 * (buffCategory.thirstMultiplier or 1.0)))
                    Player.Functions.SetMetaData('thirst', newThirst)
                    TriggerClientEvent('hud:client:UpdateNeeds', src, Player.PlayerData.metadata['hunger'], newThirst)
                end
            end
        end
        TriggerClientEvent('ts-lets-eat:client:ApplyBuff', src, buffCategory)
    end
end)

-- Event for business owners to source ingredients wholesale
RegisterNetEvent('ts-lets-eat:server:PurchaseWholesale', function(item, boxes)
    local src = source
    if not Config.BusinessSourcing.enabled then return end

    local itemData = Config.Items[item]
    if not itemData or itemData.type ~= 'ingredient' then return end

    -- Verify input is positive
    if type(boxes) ~= 'number' or boxes <= 0 then
        return
    end

    local amount = boxes * 50
    local cost = amount * Config.BusinessSourcing.wholesaleMarkup * 10

    -- Verify Job
    local hasJob = false
    if Config.Framework == 'qbox' or Config.Framework == 'qbcore' then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player and Player.PlayerData.job and Config.BusinessSourcing.allowedJobs[Player.PlayerData.job.name] then
            hasJob = true
        end
    elseif Config.Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer and xPlayer.job and Config.BusinessSourcing.allowedJobs[xPlayer.job.name] then
            hasJob = true
        end
    end

    if not hasJob then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Access Denied',
            description = 'You do not have the required business credentials to order wholesale.',
            type = 'error'
        })
        return
    end

    local hasMoney = false
    local accountType = Config.BusinessSourcing.accountType or 'bank'

    if Config.Framework == 'qbox' or Config.Framework == 'qbcore' then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player.PlayerData.money[accountType] >= cost then
            Player.Functions.RemoveMoney(accountType, cost, "wholesale-purchase")
            hasMoney = true
        end
    elseif Config.Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer.getAccount(accountType).money >= cost then
            xPlayer.removeAccountMoney(accountType, cost, "Wholesale purchase")
            hasMoney = true
        end
    end

    if not hasMoney then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Insufficient Funds',
            description = 'You cannot afford this wholesale order.',
            type = 'error'
        })
        return
    end

    if Config.Inventory == 'ox' then
        exports.ox_inventory:AddItem(src, item, amount)
    elseif Config.Inventory == 'qb' then
        local Player = QBCore.Functions.GetPlayer(src)
        Player.Functions.AddItem(item, amount)
    elseif Config.Inventory == 'qs' then
        if Config.Framework == 'esx' then
            local xPlayer = ESX.GetPlayerFromId(src)
            xPlayer.addInventoryItem(item, amount)
        end
    end

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Wholesale Delivery',
        description = 'Received ' .. amount .. 'x ' .. item,
        type = 'success'
    })
end)

-- Register usable items based on framework
CreateThread(function()
    for itemName, itemData in pairs(Config.Items) do
        if itemData.type == 'meal' then
            if Config.Framework == 'qbox' or Config.Framework == 'qbcore' then
                QBCore.Functions.CreateUseableItem(itemName, function(source, item)
                    local src = source
                    TriggerClientEvent('ts-lets-eat:client:ConsumeFood', src, itemName)
                end)
            elseif Config.Framework == 'esx' then
                ESX.RegisterUsableItem(itemName, function(source, item, itemInfo)
                    local src = source
                    TriggerClientEvent('ts-lets-eat:client:ConsumeFood', src, itemName)
                end)
            end
        end
    end
end)

-- Refrigerator System Logic
RegisterNetEvent('ts-lets-eat:server:OpenFridge', function(fridgeId)
    local src = source

    -- Validate fridgeId format to prevent stash injection
    if type(fridgeId) ~= 'string' or not string.match(fridgeId, '^fridge_%-?%d+_%-?%d+$') then
        return
    end

    if Config.Inventory == 'ox' then
        -- Register a stash for this specific fridge ID if it doesn't exist
        exports.ox_inventory:RegisterStash(fridgeId, 'Refrigerator', 50, 100000, false)
    elseif Config.Inventory == 'qs' then
        exports['qs-inventory']:RegisterStash(fridgeId, 50, 100000)
    end
    -- Client will then be triggered to open the inventory
    -- Note: For qb-inventory, opening is handled directly via `inventory:server:OpenInventory` on the client
end)

-- Storefront KVP Management
local function GetDynamicStorefrontItems(restId)
    local kvpString = GetResourceKvpString('storefront_' .. restId)
    if kvpString then
        return json.decode(kvpString)
    end
    -- Fallback to config defaults if nothing saved
    local restaurant = Config.Restaurants[restId]
    if restaurant and restaurant.storefront and restaurant.storefront.items then
        return restaurant.storefront.items
    end
    return {}
end

local function SaveDynamicStorefrontItems(restId, itemsTable)
    SetResourceKvp('storefront_' .. restId, json.encode(itemsTable))
end

lib.callback.register('ts-lets-eat:server:GetStorefrontItems', function(source, restId)
    return GetDynamicStorefrontItems(restId)
end)

-- Job/Admin verification helper for management
local function IsAuthorized(src, restId)
    local restaurant = Config.Restaurants[restId]
    if not restaurant then return false end

    if Config.Framework == 'qbox' or Config.Framework == 'qbcore' then
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return false end
        -- Check if admin
        if QBCore.Functions.HasPermission(src, 'admin') then return true end
        -- Check if boss of restaurant
        if Player.PlayerData.job.name == restaurant.job and Player.PlayerData.job.isboss then return true end
    elseif Config.Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return false end
        if xPlayer.getGroup() == 'admin' or xPlayer.getGroup() == 'superadmin' then return true end
        if xPlayer.job.name == restaurant.job and xPlayer.job.grade_name == 'boss' then return true end
    end

    return false
end

RegisterNetEvent('ts-lets-eat:server:AddStorefrontItem', function(restId, itemName, price)
    local src = source
    if not IsAuthorized(src, restId) then return end

    local configItem = Config.Items[itemName]
    if not configItem then
        TriggerClientEvent('ox_lib:notify', src, {title = 'Error', description = 'Item does not exist in Config.Items', type = 'error'})
        return
    end

    local items = GetDynamicStorefrontItems(restId)

    -- Check if it already exists, update price
    local exists = false
    for i, v in ipairs(items) do
        if v.name == itemName then
            items[i].price = price
            exists = true
            break
        end
    end

    if not exists then
        table.insert(items, { name = itemName, price = price })
    end

    SaveDynamicStorefrontItems(restId, items)
    TriggerClientEvent('ox_lib:notify', src, {title = 'Success', description = 'Added ' .. configItem.label .. ' for $' .. price, type = 'success'})
end)

RegisterNetEvent('ts-lets-eat:server:RemoveStorefrontItem', function(restId, itemName)
    local src = source
    if not IsAuthorized(src, restId) then return end

    local items = GetDynamicStorefrontItems(restId)
    for i, v in ipairs(items) do
        if v.name == itemName then
            table.remove(items, i)
            break
        end
    end

    SaveDynamicStorefrontItems(restId, items)
    TriggerClientEvent('ox_lib:notify', src, {title = 'Removed', description = 'Removed item from storefront.', type = 'success'})
end)


-- Storefront Purchasing Logic
RegisterNetEvent('ts-lets-eat:server:PurchaseStorefrontItem', function(restId, itemIndex, quantity)
    local src = source
    local restaurant = Config.Restaurants[restId]

    if not restaurant or not restaurant.storefront.enabled then return end

    -- Fetch the dynamic items from KVP rather than the static config
    local items = GetDynamicStorefrontItems(restId)
    local itemData = items[itemIndex]
    if not itemData then return end

    if type(quantity) ~= 'number' or quantity <= 0 then return end

    -- Verify Distance to prevent global purchasing exploits
    local ped = GetPlayerPed(src)
    local pedCoords = GetEntityCoords(ped)
    local storeCoords = vec3(restaurant.storefront.coords.x, restaurant.storefront.coords.y, restaurant.storefront.coords.z)

    if #(pedCoords - storeCoords) > 10.0 then
        return
    end

    local totalCost = itemData.price * quantity
    local hasMoney = false

    if Config.Framework == 'qbox' or Config.Framework == 'qbcore' then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player.Functions.RemoveMoney('cash', totalCost, "storefront-purchase") or Player.Functions.RemoveMoney('bank', totalCost, "storefront-purchase") then
            hasMoney = true
        end
    elseif Config.Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer.getMoney() >= totalCost then
            xPlayer.removeMoney(totalCost)
            hasMoney = true
        elseif xPlayer.getAccount('bank').money >= totalCost then
            xPlayer.removeAccountMoney('bank', totalCost)
            hasMoney = true
        end
    end

    if not hasMoney then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Insufficient Funds',
            description = 'You cannot afford ' .. quantity .. 'x ' .. Config.Items[itemData.name].label,
            type = 'error'
        })
        return
    end

    if Config.Inventory == 'ox' then
        exports.ox_inventory:AddItem(src, itemData.name, quantity)
    elseif Config.Inventory == 'qb' then
        local Player = QBCore.Functions.GetPlayer(src)
        Player.Functions.AddItem(itemData.name, quantity)
    elseif Config.Inventory == 'qs' then
        if Config.Framework == 'esx' then
            local xPlayer = ESX.GetPlayerFromId(src)
            if xPlayer.addInventoryItem then
                xPlayer.addInventoryItem(itemData.name, quantity)
            end
        elseif Config.Framework == 'qbox' or Config.Framework == 'qbcore' then
            local Player = QBCore.Functions.GetPlayer(src)
            Player.Functions.AddItem(itemData.name, quantity)
        end
    end

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Purchase Successful',
        description = 'You bought ' .. quantity .. 'x ' .. Config.Items[itemData.name].label .. ' for $' .. totalCost,
        type = 'success'
    })
end)

-- Hook for ox_inventory to check spoilage dynamically when accessing inventories (if applicable)
-- Alternatively, this can be handled via a recurring server thread that cleans up expired items.
CreateThread(function()
    if not Config.Spoilage.enabled or Config.Inventory ~= 'ox' then return end

    -- A simplistic periodic check could be implemented here to scrub inventories,
    -- but usually, it's better to calculate spoilage visually on the client side
    -- or right before an item is used.
end)
