local hasKitchen = {}
local tempEmployees = {}
local truckOwner = {}
local dynamicMenus = {} -- Store tablet configurations per plate
local ox_inventory = exports.ox_inventory

-- Utility function to handle custom notifications
local function Alerts(source, text, type)
    lib.notify(source, {title = 'Food Trucks', description = text, type = type, duration = 5000})
end

local function GetCitizenIdFromSource(src)
    if GetResourceState('qbx_core') == 'started' then
        local Player = exports.qbx_core:GetPlayer(src)
        if Player then return Player.PlayerData.citizenid end
    elseif GetResourceState('qb-core') == 'started' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then return Player.PlayerData.citizenid end
    end
    return nil
end

-- Initialize Food Trucks on Server Start
CreateThread(function()
    Wait(1000)
    MySQL.query('SELECT plate, citizenid FROM player_vehicles WHERE foodtruck = ?', {'1'}, function(result)
        if result and #result > 0 then
            for i=1, #result do
                local plate = result[i].plate
                hasKitchen[plate] = true
                tempEmployees[plate] = {}
                truckOwner[plate] = result[i].citizenid
                dynamicMenus[plate] = {} -- initialize empty dynamic state
                ox_inventory:RegisterStash('food_truck_stash_'..plate, 'Cooking Stash', 200, 100000, false)
                ox_inventory:RegisterStash('food_truck_safe_'..plate, 'Truck Safe', 50, 50000, false)
                ox_inventory:RegisterStash('food_truck_counter_'..plate, 'Service Counter', 50, 50000, false)
            end
        end
    end)
end)

-- Event: Install Kitchen
RegisterNetEvent('env_foodtruck:server:kitchenAdd', function(plate, citizenid)
    hasKitchen[plate] = true
    tempEmployees[plate] = {}
    truckOwner[plate] = citizenid
    dynamicMenus[plate] = {}

    MySQL.update('UPDATE player_vehicles SET foodtruck = 1 WHERE plate = @plate',{
        ['@plate'] = plate,
    })
    ox_inventory:RegisterStash('food_truck_stash_'..plate, 'Cooking Stash', 200, 100000, false)
    ox_inventory:RegisterStash('food_truck_safe_'..plate, 'Truck Safe', 50, 50000, false)
    ox_inventory:RegisterStash('food_truck_counter_'..plate, 'Service Counter', 50, 50000, false)
end)

-- Callback: Check if vehicle has a kitchen
lib.callback.register('env_foodtrucks:server:hasKitchen', function(source, plate)
    return hasKitchen[plate] or false
end)

-- Callback: Check stash count for an item
lib.callback.register('env_foodtrucks:server:stashCount', function(source, item, plate)
    return ox_inventory:Search('food_truck_stash_'..plate, 'count', item)
end)

-- Callback: Get truck owner
lib.callback.register('env_foodtrucks:server:getOwner', function(source, plate)
    if truckOwner[plate] ~= nil then return truckOwner[plate] end

    local owner = nil
    local result = MySQL.query.await('SELECT citizenid FROM player_vehicles WHERE plate = ?', {plate})
    if result and #result > 0 then
        owner = result[1].citizenid
    end

    truckOwner[plate] = owner
    return owner
end)

-- Callback: Get truck employees
lib.callback.register('env_foodtrucks:server:getEmployees', function(source, plate)
    return tempEmployees[plate]
end)

-- Callback: Get dynamic menu configuration
lib.callback.register('env_foodtrucks:server:getMenuConfig', function(source, plate)
    return dynamicMenus[plate] or {}
end)

-- Event: Handle Employee Hiring/Firing
RegisterNetEvent('env_foodtrucks:server:handleEmployee', function(plate, empId, task)
    local src = source
    local empName = GetPlayerName(empId)
    if not empName then
        Alerts(src, 'Player not online!', 'error')
        return
    end

    if task == 'insert' then
        if tempEmployees[plate] then
            for _, v in ipairs(tempEmployees[plate]) do
                if v == empId then
                    Alerts(src, 'Employee already hired!', 'error')
                    return
                end
            end
        end
        table.insert(tempEmployees[plate], empId)
        Alerts(src, 'Hired ' .. empName .. ' as an employee.', 'success')
        Alerts(empId, 'You have been hired to a food truck!', 'success')
    elseif task == 'remove' then
        if tempEmployees[plate] then
            local indexToRemove = nil
            for i, v in ipairs(tempEmployees[plate]) do
                if v == empId then
                    indexToRemove = i
                    break
                end
            end
            if indexToRemove then
                table.remove(tempEmployees[plate], indexToRemove)
                Alerts(src, 'Fired ' .. empName .. '.', 'info')
                Alerts(empId, 'You were released from your food truck duties.', 'info')
            end
        end
    end
end)

-- Event: Handle Manual Payout to Employee
RegisterNetEvent('env_foodtrucks:server:payEmployee', function(plate, empId, amount)
    local src = source
    if type(amount) ~= "number" or amount <= 0 or math.floor(amount) ~= amount then
        Alerts(src, 'Invalid payment amount.', 'error')
        return
    end

    local empName = GetPlayerName(empId)
    if not empName then
        Alerts(src, 'Employee is not online!', 'error')
        return
    end

    -- Ensure source is owner
    local isOwner = false
    local citizenid = GetCitizenIdFromSource(src)
    if citizenid and citizenid == truckOwner[plate] then
        isOwner = true
    end

    if not isOwner then
        Alerts(src, 'Only the truck owner can authorize payouts.', 'error')
        return
    end

    -- Check owner funds and transfer
    local hasMoney = ox_inventory:Search(src, 'count', 'money')
    if hasMoney >= amount then
        if ox_inventory:RemoveItem(src, 'money', amount) then
            if ox_inventory:AddItem(empId, 'money', amount) then
                Alerts(src, 'Paid ' .. empName .. ' $' .. amount, 'success')
                Alerts(empId, 'You received a payout of $' .. amount, 'success')
            else
                -- Rollback if adding fails
                ox_inventory:AddItem(src, 'money', amount)
                Alerts(src, 'Failed to give money to employee.', 'error')
            end
        else
            Alerts(src, 'Failed to remove money.', 'error')
        end
    else
        Alerts(src, 'You do not have enough money.', 'error')
    end
end)


-- Callback: Handle Crafting/Step Execution
lib.callback.register('env_foodtrucks:server:handleCraft', function(source, recipeId, stepId, plate)
    local src = source

    local expectedIngredients = nil
    local expectedOutput = nil

    if stepId == nil then
        local recipe = Config.Menu[recipeId]
        if not recipe then return false end
        expectedIngredients = recipe.ingredients
        expectedOutput = recipe.item
    else
        local recipe = Config.MultiStepRecipes[recipeId]
        if not recipe then return false end

        for _, step in ipairs(recipe.steps) do
            if step.id == stepId then
                expectedIngredients = step.ingredients
                expectedOutput = step.output
                break
            end
        end
        if not expectedIngredients then return false end
    end

    for _, v in pairs(expectedIngredients) do
        local count = ox_inventory:Search('food_truck_stash_'..plate, 'count', v.item)
        if count < v.count then
            Alerts(src, 'Missing ingredients in cooler.', 'error')
            return false
        end
    end

    for _, v in pairs(expectedIngredients) do
        local success = ox_inventory:RemoveItem('food_truck_stash_'..plate, v.item, v.count)
        if not success then
            Alerts(src, 'Failed to remove ' .. v.item, 'error')
            return false
        end
    end

    -- Deposit to counter
    local added = ox_inventory:AddItem('food_truck_counter_'..plate, expectedOutput, 1)
    if added then
        Alerts(src, 'Order on the counter: ' .. expectedOutput .. '!', 'success')
        return true
    end
    return false
end)

-- Event: Buy Liquor License from City Hall
RegisterNetEvent('env_foodtrucks:server:buyLiquorLicense', function()
    local src = source
    local cost = Config.LiquorLicense.cost

    local hasMoney = ox_inventory:Search(src, 'count', 'money')
    if hasMoney >= cost then
        if ox_inventory:RemoveItem(src, 'money', cost) then
            local expiryDate = os.time() + (Config.LiquorLicense.expiryDays * 86400)
            local metadata = { expiry = expiryDate, description = 'Expires: ' .. os.date('%Y-%m-%d', expiryDate) }
            ox_inventory:AddItem(src, 'liquor_license', 1, metadata)
            Alerts(src, 'Purchased Liquor License for $' .. cost, 'success')
        end
    else
        Alerts(src, 'Not enough money. Needs $' .. cost, 'error')
    end
end)

-- Event: Wholesale Depot Purchases
RegisterNetEvent('env_foodtrucks:server:buyWholesale', function(item, amount)
    local src = source

    -- Input validation
    if type(amount) ~= "number" or amount <= 0 or math.floor(amount) ~= amount then
        Alerts(src, 'Invalid amount.', 'error')
        return
    end

    local price = nil
    for _, configItem in ipairs(Config.WholesaleDepot.items) do
        if configItem.item == item then
            price = configItem.price
            break
        end
    end

    if not price then
        Alerts(src, 'Invalid item.', 'error')
        return
    end

    local totalCost = amount * price

    local hasMoney = ox_inventory:Search(src, 'count', 'money')
    if hasMoney >= totalCost then
        if ox_inventory:CanCarryItem(src, item, amount) then
            -- Evaluate RemoveItem success
            if ox_inventory:RemoveItem(src, 'money', totalCost) then
                ox_inventory:AddItem(src, item, amount)
                Alerts(src, 'Purchased ' .. amount .. 'x ' .. item .. ' for $' .. totalCost, 'success')
            else
                Alerts(src, 'Transaction failed.', 'error')
            end
        else
            Alerts(src, 'Inventory full!', 'error')
        end
    else
        Alerts(src, 'Not enough money.', 'error')
    end
end)

-- Event: Handle NPC Sales
RegisterNetEvent('env_foodtrucks:server:sellToNPC', function(recipeId)
    local src = source
    if not Config.AllowNPCSales then
        Alerts(src, 'NPC sales are disabled.', 'error')
        return
    end

    -- Get recipe expected output item and default price
    local expectedOutput = nil
    local defaultPrice = 15 -- Default fallback price

    local recipe = Config.Menu[recipeId]
    if recipe then
        expectedOutput = recipe.item
    else
        recipe = Config.MultiStepRecipes[recipeId]
        if recipe then
            expectedOutput = recipe.steps[#recipe.steps].output
            defaultPrice = 25 -- Default higher price for multi-step
        end
    end

    if not expectedOutput then
        Alerts(src, 'Invalid item to sell.', 'error')
        return
    end

    -- Check if player actually has the item
    local hasItem = ox_inventory:Search(src, 'count', expectedOutput)
    if hasItem < 1 then
        Alerts(src, 'You do not have ' .. expectedOutput .. ' to sell.', 'error')
        return
    end

    -- Determine sale price (checking dynamic menu for overrides isn't feasible here without knowing the plate,
    -- but we can use a baseline or randomize. For simplicity, flat default price is used.)
    local salePrice = defaultPrice

    if ox_inventory:RemoveItem(src, expectedOutput, 1) then
        if ox_inventory:AddItem(src, 'money', salePrice) then
            Alerts(src, 'Sold ' .. expectedOutput .. ' for $' .. salePrice, 'success')
        else
            -- rollback
            ox_inventory:AddItem(src, expectedOutput, 1)
        end
    end
end)


-- Tati_Tablet integration logic
RegisterNetEvent('env_foodtrucks:server:tabletMenuUpdate', function(plate, action, data)
    local src = source

    -- Ensure only owner can update using proper framework check
    if truckOwner[plate] ~= nil then
        local citizenid = GetCitizenIdFromSource(src)
        if citizenid ~= truckOwner[plate] then
            Alerts(src, 'Unauthorized.', 'error')
            return
        end
    end

    if not dynamicMenus[plate] then dynamicMenus[plate] = {} end

    if action == 'rename' then
        if not dynamicMenus[plate][data.recipeId] then dynamicMenus[plate][data.recipeId] = {} end
        dynamicMenus[plate][data.recipeId].label = data.newName
        Alerts(src, 'Renamed item successfully.', 'success')

    elseif action == 'toggle' then
        if not dynamicMenus[plate][data.recipeId] then dynamicMenus[plate][data.recipeId] = {} end
        dynamicMenus[plate][data.recipeId].enabled = data.enabled
        Alerts(src, 'Toggled item availability.', 'success')

    elseif action == 'price' then
        if not dynamicMenus[plate][data.recipeId] then dynamicMenus[plate][data.recipeId] = {} end
        dynamicMenus[plate][data.recipeId].price = data.price
        Alerts(src, 'Adjusted item price.', 'success')
    end
end)