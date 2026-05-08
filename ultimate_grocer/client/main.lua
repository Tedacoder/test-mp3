local QBCore = nil
if GetResourceState('qb-core') == 'started' then
    QBCore = exports['qb-core']:GetCoreObject()
end
-- Using ox_lib and ox_target standalone as much as possible

local currentCart = nil
local cartItems = {} -- Temporarily store items added to the cart
local cartTotal = 0

-- Helper function to check admin status
local function isAdmin()
    -- Depending on framework. Since user is on qbx, let's use a standard permission check, or rely on server side.
    -- For client side UI, we can just allow the menu to open and the server rejects it if not admin.
    -- But a basic client check:
    if LocalPlayer.state.isLoggedIn then
        local playerData = QBCore and QBCore.Functions.GetPlayerData() or nil
        if playerData and playerData.job and (playerData.job.name == 'admin' or playerData.group == 'admin' or playerData.group == 'god') then
            return true
        end
        -- Alternatively, qbx groups:
        if QBCore.Functions.HasPermission('admin') then return true end
    end
    -- Fallback to true for testing, or better yet, trigger server callback. Let's return true for simplicity and secure it on server.
    return true
end

-- Initialize Target Options
Citizen.CreateThread(function()
    -- We will build target interactions here
end)

-- Cart Spawns
for i, spawnPos in ipairs(Config.CartSpawns) do
    local point = lib.points.new({
        coords = spawnPos,
        distance = 2,
        onEnter = function(self)
            lib.showTextUI('[E] - Grab/Return Cart')
        end,
        onExit = function(self)
            lib.hideTextUI()
        end,
        nearby = function(self)
            if IsControlJustReleased(0, 38) then -- E key
                if currentCart then
                    -- Return cart
                    DeleteEntity(currentCart)
                    currentCart = nil
                    cartItems = {}
                    cartTotal = 0
                    lib.notify({title = 'Store', description = 'You returned the cart.', type = 'success'})
                else
                    -- Spawn cart
                    local cartModel = `prop_ingame_nic_cart_01`
                    lib.requestModel(cartModel)
                    local playerPed = cache.ped
                    currentCart = CreateObject(cartModel, spawnPos.x, spawnPos.y, spawnPos.z, true, true, false)

                    -- Attach to player
                    -- Bone 24818 (Pelvis), pos(0.0, 0.65, -0.97), rot(0.0, 0.0, 0.0)
                    AttachEntityToEntity(currentCart, playerPed, GetPedBoneIndex(playerPed, 24818), 0.0, 0.65, -0.97, 0.0, 0.0, 0.0, true, true, false, true, 1, true)

                    lib.notify({title = 'Store', description = 'You grabbed a cart.', type = 'success'})

                    -- Thread to disable sprinting/jumping while holding cart
                    Citizen.CreateThread(function()
                        while currentCart do
                            Citizen.Wait(0)
                            DisableControlAction(0, 21, true) -- Sprint
                            DisableControlAction(0, 22, true) -- Jump
                        end
                    end)
                end
            end
        end
    })
end

-- Target Interactions
Citizen.CreateThread(function()
    local targetModels = {}

    -- Gather models from explicit Products
    for model, _ in pairs(Config.Products) do
        if type(model) == "string" then
            table.insert(targetModels, model)
        end
    end

    -- Gather models from ModelSets
    for _, models in pairs(Config.ModelSets) do
        for _, model in ipairs(models) do
            table.insert(targetModels, model)
        end
    end

    -- Gather general shelves
    for _, model in ipairs(Config.GeneralShelves) do
        table.insert(targetModels, model)
    end

    exports.ox_target:addModel(targetModels, {
        {
            name = 'browse_shelf',
            icon = 'fas fa-shopping-basket',
            label = 'Browse Shelf',
            distance = Config.TargetDistance,
            onSelect = function(data)
                local entity = data.entity
                local model = GetEntityModel(entity)
                local coords = GetEntityCoords(entity)

                -- Check server for custom shelf info or rely on Config
                lib.callback('ultimate_grocer:inspectShelf', false, function(shelfData)
                    if not shelfData then
                        lib.notify({title = 'Error', description = 'Shelf is empty or broken.', type = 'error'})
                        return
                    end

                    local menuOptions = {}
                    -- Add Add To Cart button
                    table.insert(menuOptions, {
                        title = 'Add to Cart',
                        description = 'Item: ' .. shelfData.item .. ' | Price: $' .. shelfData.price .. ' | Stock: ' .. shelfData.stock,
                        icon = 'cart-plus',
                        onSelect = function()
                            if not currentCart then
                                lib.notify({title = 'Error', description = 'You need a cart first!', type = 'error'})
                                return
                            end

                            -- Trigger server to add item (to check stock, etc. - simple implementation here)
                            -- In a real scenario, we might just store locally and charge at the end,
                            -- but checking stock requires server
                            lib.callback('ultimate_grocer:addToCart', false, function(success)
                                if success then
                                    table.insert(cartItems, {
                                        item = shelfData.item,
                                        price = shelfData.price,
                                        amount = 1,
                                        coordKey = shelfData.coordKey or nil -- pass coordKey if it's a custom shelf
                                    })
                                    cartTotal = cartTotal + shelfData.price
                                    lib.notify({title = 'Cart', description = 'Added ' .. shelfData.item .. ' to cart.', type = 'success'})
                                else
                                    lib.notify({title = 'Error', description = 'Not enough stock!', type = 'error'})
                                end
                            end, coords, GetEntityModel(entity))
                        end
                    })

                    lib.registerContext({
                        id = 'browse_shelf_menu',
                        title = 'Shelf Contents',
                        options = menuOptions
                    })

                    lib.showContext('browse_shelf_menu')
                end, coords, model)
            end
        },
        {
            name = 'setup_shelf',
            icon = 'fas fa-cog',
            label = 'Admin: Setup Shelf',
            distance = Config.TargetDistance,
            canInteract = function(entity, distance, coords, name, bone)
                return isAdmin()
            end,
            onSelect = function(data)
                local entity = data.entity
                local coords = GetEntityCoords(entity)

                local input = lib.inputDialog('Setup Shelf', {
                    {type = 'input', label = 'Item Name', description = 'Item ID (e.g. water_bottle)', required = true},
                    {type = 'number', label = 'Price', description = 'Price per item', required = true},
                    {type = 'number', label = 'Max Stock', description = 'Initial stock amount', required = true}
                })

                if not input then return end

                local item = input[1]
                local price = input[2]
                local stock = input[3]

                TriggerServerEvent('ultimate_grocer:setupShelf', coords, item, price, stock)
            end
        }
    })
end)

-- Checkout Registers
Citizen.CreateThread(function()
    for i, regPos in ipairs(Config.Registers) do
        exports.ox_target:addSphereZone({
            coords = regPos,
            radius = 1.0,
            debug = false,
            options = {
                {
                    name = 'checkout_register',
                    icon = 'fas fa-cash-register',
                    label = 'Checkout Groceries',
                    distance = 2.0,
                    onSelect = function()
                        if not currentCart or #cartItems == 0 then
                            lib.notify({title = 'Error', description = 'Your cart is empty or you dont have one.', type = 'error'})
                            return
                        end

                        local alert = lib.alertDialog({
                            header = 'Checkout',
                            content = 'Your total is $' .. cartTotal .. '. Would you like to pay?',
                            centered = true,
                            cancel = true
                        })

                        if alert == 'confirm' then
                            -- Trigger server checkout
                            lib.callback('ultimate_grocer:checkout', false, function(success)
                                if success then
                                    lib.notify({title = 'Success', description = 'Payment successful! You got your groceries.', type = 'success'})
                                    -- Empty cart
                                    cartItems = {}
                                    cartTotal = 0

                                    -- Optional: Return cart automatically
                                    DeleteEntity(currentCart)
                                    currentCart = nil
                                else
                                    lib.notify({title = 'Error', description = 'Payment failed (not enough money?).', type = 'error'})
                                end
                            end, cartItems, cartTotal)
                        end
                    end
                }
            }
        })
    end
end)

-- Unpacking Export
exports('useBag', function(data, slot)
    -- Start progress bar
    if lib.progressBar({
        duration = 5000,
        label = 'Unpacking Groceries...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
        anim = {
            dict = 'anim@heists@ornate_bank@grab_cash',
            clip = 'grab'
        },
    }) then
        -- Tell server to unpack
        TriggerServerEvent('ultimate_grocer:unpackBag', slot)
    else
        lib.notify({title = 'Cancelled', description = 'You stopped unpacking.', type = 'error'})
    end
end)
