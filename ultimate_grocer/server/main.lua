local ox_inventory = exports.ox_inventory
local CustomShelves = {}
local dataFile = 'data/data.json'

local function isAdmin(src)
    -- Use ox_lib's built-in ace permission check
    if IsPlayerAceAllowed(src, 'command') then return true end
    if GetResourceState('qb-core') == 'started' then
        return exports['qb-core']:HasPermission(src, 'admin') or exports['qb-core']:HasPermission(src, 'god')
    end
    return false
end

-- Initialize server
Citizen.CreateThread(function()
    -- Load data
end)

-- Load Data
Citizen.CreateThread(function()
    local loadFile = LoadResourceFile(GetCurrentResourceName(), dataFile)
    if loadFile then
        CustomShelves = json.decode(loadFile) or {}
    else
        CustomShelves = {}
    end
end)

-- Save Data Helper
local function SaveCustomShelves()
    SaveResourceFile(GetCurrentResourceName(), dataFile, json.encode(CustomShelves, {indent = true}), -1)
end

-- Admin Setup Event
RegisterNetEvent('ultimate_grocer:setupShelf', function(coords, item, price, stock)
    local src = source
    if not isAdmin(src) then return end

    -- Format coords for a simple key string (e.g. "x_y_z")
    -- rounding to 1 decimal place to handle slight variations
    local coordKey = string.format("%.1f_%.1f_%.1f", coords.x, coords.y, coords.z)

    CustomShelves[coordKey] = {
        item = item,
        price = price,
        stock = stock
    }

    SaveCustomShelves()
    TriggerClientEvent('ox_lib:notify', src, {title = 'Admin', description = 'Shelf configured for '..item, type = 'success'})
end)

-- Inspect Shelf Callback
lib.callback.register('ultimate_grocer:inspectShelf', function(source, coords, entityModelHash)
    local coordKey = string.format("%.1f_%.1f_%.1f", coords.x, coords.y, coords.z)

    -- Check if it's a custom shelf first
    if CustomShelves[coordKey] then
        local data = CustomShelves[coordKey]
        data.coordKey = coordKey
        return data
    end

    -- If no custom shelf, fallback to Config.Products
    -- Since we only have the model hash from the client, we need to iterate over Config.Products
    -- and Config.ReverseModelSets to find a matching product.
    for modelName, productData in pairs(Config.Products) do
        if GetHashKey(modelName) == entityModelHash then
            return productData
        end
    end

    -- Check if the model belongs to a model set
    for modelName, setName in pairs(Config.ReverseModelSets) do
        if GetHashKey(modelName) == entityModelHash then
            -- Find product data by set name
            if Config.Products[setName] then
                return Config.Products[setName]
            end

            -- If no specific set config, we can try to fall back or return empty
        end
    end

    return nil
end)

-- Add to cart callback to check stock
lib.callback.register('ultimate_grocer:addToCart', function(source, coords, entityModelHash)
    local coordKey = string.format("%.1f_%.1f_%.1f", coords.x, coords.y, coords.z)
    if CustomShelves[coordKey] then
        if CustomShelves[coordKey].stock > 0 then
            CustomShelves[coordKey].stock = CustomShelves[coordKey].stock - 1
            SaveCustomShelves()
            return true
        end
        return false
    end
    return true -- Config items are infinite stock for this example unless configured otherwise
end)

-- Checkout Callback
lib.callback.register('ultimate_grocer:checkout', function(source, cartItems, cartTotal)
    local src = source

    local computedTotal = 0
    local validItems = {}

    for _, itemData in ipairs(cartItems) do
        local priceToUse = itemData.price
        computedTotal = computedTotal + priceToUse
        table.insert(validItems, {
            item = itemData.item,
            amount = 1 -- force to 1 per entry
        })
    end

    if computedTotal ~= cartTotal then
        print(('Player %s attempted checkout with invalid total! computed: %s, given: %s'):format(src, computedTotal, cartTotal))
        return false
    end

    -- Check if player has enough money
    -- Use ox_inventory for standalone inventory check
    local moneyCount = ox_inventory:Search(src, 'count', 'money')

    if moneyCount >= cartTotal then
        -- Remove money
        ox_inventory:RemoveItem(src, 'money', cartTotal)

        -- Build metadata for bag
        local bagMetadata = {
            description = 'Contains your purchased groceries.',
            items = validItems
        }

        -- Give plastic grocery bag with metadata
        ox_inventory:AddItem(src, 'plastic_grocery_bag', 1, bagMetadata)

        return true
    else
        return false
    end
end)

-- Unpack Bag Event
RegisterNetEvent('ultimate_grocer:unpackBag', function(slot)
    local src = source

    -- Get item from slot
    local itemInfo = ox_inventory:GetSlot(src, slot)

    if itemInfo and itemInfo.name == 'plastic_grocery_bag' then
        if itemInfo.metadata and itemInfo.metadata.items then
            local items = itemInfo.metadata.items

            -- Remove bag
            ox_inventory:RemoveItem(src, 'plastic_grocery_bag', 1, nil, slot)

            -- Add items
            for i, itemData in ipairs(items) do
                ox_inventory:AddItem(src, itemData.item, itemData.amount)
            end

            TriggerClientEvent('ox_lib:notify', src, {title = 'Unpacked', description = 'You unpacked your groceries.', type = 'success'})
        else
            TriggerClientEvent('ox_lib:notify', src, {title = 'Error', description = 'Bag is empty or corrupt.', type = 'error'})
        end
    end
end)
