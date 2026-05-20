local QBCore = nil
local ESX = nil

if Config.Framework == 'qbox' or Config.Framework == 'qbcore' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
end

local spawnedProps = {}

-- Helper function to spawn cooking prop physically on the entity
local function SpawnCookingProp(propName, entity)
    local propData = Config.CookingProps[propName]
    if not propData then return nil end

    lib.requestModel(propData.hash)

    local coords = GetEntityCoords(entity)
    local obj = CreateObject(propData.hash, coords.x, coords.y, coords.z + propData.offset.z, false, true, false)

    SetEntityRotation(obj, propData.rot.x, propData.rot.y, propData.rot.z, 2, true)
    FreezeEntityPosition(obj, true)

    SetModelAsNoLongerNeeded(propData.hash)

    local ptfx = nil
    local soundId = nil

    if Config.Effects.enabled then
        -- Play Audio
        soundId = GetSoundId()
        PlaySoundFromEntity(soundId, Config.Effects.audio.soundName, obj, Config.Effects.audio.soundDict, false, 0)

        -- Play PTFX Steam
        lib.requestNamedPtfxAsset(Config.Effects.particle.dict)
        UseParticleFxAssetNextCall(Config.Effects.particle.dict)
        ptfx = StartParticleFxLoopedOnEntity(Config.Effects.particle.name, obj, Config.Effects.particle.offset.x, Config.Effects.particle.offset.y, Config.Effects.particle.offset.z, 0.0, 0.0, 0.0, Config.Effects.particle.scale, false, false, false)
        RemoveNamedPtfxAsset(Config.Effects.particle.dict)
    end

    return obj, ptfx, soundId
end

-- Cleanup spawned prop
local function CleanupProp(obj, ptfx, soundId)
    if ptfx then
        StopParticleFxLooped(ptfx, 0)
    end

    if soundId then
        StopSound(soundId)
        ReleaseSoundId(soundId)
    end

    if obj and DoesEntityExist(obj) then
        DeleteEntity(obj)
    end
end

-- Event triggered when player uses the item from inventory
RegisterNetEvent('ts-lets-eat:client:ConsumeFood', function(itemName)
    -- Play eating animation
    lib.requestAnimDict('mp_player_inteat@burger')
    TaskPlayAnim(PlayerPedId(), 'mp_player_inteat@burger', 'mp_player_int_eat_burger_fp', 8.0, -8.0, 3000, 49, 0, false, false, false)

    if lib.progressBar({
        duration = 3000,
        label = 'Eating ' .. Config.Items[itemName].label,
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            car = false,
            combat = true,
            mouse = false
        }
    }) then
        ClearPedTasks(PlayerPedId())
        TriggerServerEvent('ts-lets-eat:server:ConsumeItem', itemName)
    else
        ClearPedTasks(PlayerPedId())
    end
end)

-- Event to handle applying a buff locally
RegisterNetEvent('ts-lets-eat:client:ApplyBuff', function(buffData)
    -- Logically apply the buff
    lib.notify({
        title = 'Buff Applied',
        description = buffData.label,
        type = 'info'
    })

    if buffData.type == 'regen' then
        -- Implementation for health/stamina regen depending on framework
        local ped = PlayerPedId()
        SetEntityHealth(ped, math.min(GetEntityMaxHealth(ped), math.floor(GetEntityHealth(ped) * buffData.healthMultiplier)))
        RestorePlayerStamina(PlayerId(), 1.0)
    elseif buffData.type == 'stress' then
        -- Trigger event to reduce stress
        if Config.Framework == 'qbcore' or Config.Framework == 'qbox' then
            TriggerServerEvent('hud:server:RelieveStress', buffData.stressRelief)
        elseif Config.Framework == 'esx' then
            TriggerEvent('esx_status:remove', 'stress', buffData.stressRelief * 10000)
        end
    elseif buffData.type == 'speed' then
        SetRunSprintMultiplierForPlayer(PlayerId(), buffData.speedMultiplier)
        SetTimeout(Config.Buffs.duration, function()
            SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
        end)
    elseif buffData.type == 'satiation' then
        if Config.Framework == 'esx' then
            local addHunger = 200000 * (buffData.hungerMultiplier or 1.0)
            local addThirst = 100000 * (buffData.thirstMultiplier or 1.0)
            TriggerEvent('esx_status:add', 'hunger', addHunger)
            TriggerEvent('esx_status:add', 'thirst', addThirst)
        end
    elseif buffData.type == 'thirst' then
        if Config.Framework == 'esx' then
            local addThirst = 200000 * (buffData.thirstMultiplier or 1.0)
            TriggerEvent('esx_status:add', 'thirst', addThirst)
        end
    elseif buffData.type == 'armor' then
        local ped = PlayerPedId()
        local newArmor = math.min(100, GetPedArmour(ped) + (buffData.armorAdd or 10))
        SetPedArmour(ped, newArmor)
    end
end)

-- Main cooking interaction
local function StartCooking(recipeName, portionSize, entity)
    local recipe = Config.Recipes[recipeName]
    local portion = recipe.portions[portionSize]

    -- Client-side ingredient check for UX
    local hasIngredients = true
    for item, amount in pairs(portion.ingredients) do
        if Config.Inventory == 'ox' then
            local count = exports.ox_inventory:GetItemCount(item)
            if type(count) == 'number' and count < amount then hasIngredients = false end
        elseif Config.Inventory == 'qb' or Config.Inventory == 'qs' then
            -- qb/qs client side counts are trickier to get synchronously without callbacks
            -- but for ox_inventory we can immediately prevent it.
            -- Frameworks can use standard callbacks here if needed.
        end
    end

    if Config.Inventory == 'ox' and not hasIngredients then
        lib.notify({
            title = 'Missing Ingredients',
            description = 'You do not have the required ingredients to cook this.',
            type = 'error'
        })
        return
    end

    local animData = Config.Animations[recipe.anim]
    lib.requestAnimDict(animData.dict)

    local cookingPropObj, ptfx, soundId = SpawnCookingProp(recipe.prop, entity)

    TaskPlayAnim(PlayerPedId(), animData.dict, animData.anim, 8.0, -8.0, portion.time, animData.flags, 0, false, false, false)

    if lib.progressBar({
        duration = portion.time,
        label = 'Cooking ' .. recipeName .. ' (' .. portionSize .. ')',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = false
        }
    }) then
        -- Completed successfully
        ClearPedTasks(PlayerPedId())
        CleanupProp(cookingPropObj, ptfx, soundId)

        local propCoords = GetEntityCoords(entity)
        TriggerServerEvent('ts-lets-eat:server:FinishCooking', recipeName, portionSize, propCoords)
    else
        -- Cancelled
        ClearPedTasks(PlayerPedId())
        CleanupProp(cookingPropObj, ptfx, soundId)
        lib.notify({
            title = 'Cancelled',
            description = 'You stopped cooking.',
            type = 'error'
        })
    end
end

-- Open recipe menu
local function OpenCookingMenu(entity)
    local options = {}

    for recipeName, data in pairs(Config.Recipes) do
        table.insert(options, {
            title = recipeName,
            description = 'Category: ' .. data.category,
            menu = 'recipe_portions_' .. recipeName
        })

        -- Register submenu for portions
        lib.registerContext({
            id = 'recipe_portions_' .. recipeName,
            title = recipeName .. ' Portions',
            menu = 'cooking_main_menu',
            options = {
                {
                    title = 'Single Meal',
                    description = 'Cooks 1 serving.',
                    onSelect = function()
                        StartCooking(recipeName, 'single', entity)
                    end
                },
                {
                    title = 'Family Style',
                    description = 'Cooks 10 servings.',
                    onSelect = function()
                        StartCooking(recipeName, 'family', entity)
                    end
                }
            }
        })
    end

    lib.registerContext({
        id = 'cooking_main_menu',
        title = 'Kitchen Stove',
        options = options
    })

    lib.showContext('cooking_main_menu')
end

-- Setup target interactions using ox_target
CreateThread(function()
    if Config.Target == 'ox_target' then
        local models = {}
        for hash, _ in pairs(Config.KitchenProps) do
            table.insert(models, hash)
        end

        exports.ox_target:addModel(models, {
            {
                name = 'ts_lets_eat_cook',
                icon = 'fas fa-utensils',
                label = 'Cook Food',
                onSelect = function(data)
                    OpenCookingMenu(data.entity)
                end
            }
        })

        local fridgeModels = {}
        for hash, _ in pairs(Config.RefrigeratorProps) do
            table.insert(fridgeModels, hash)
        end

        exports.ox_target:addModel(fridgeModels, {
            {
                name = 'ts_lets_eat_fridge',
                icon = 'fas fa-snowflake',
                label = 'Open Refrigerator',
                onSelect = function(data)
                    local coords = GetEntityCoords(data.entity)
                    local fridgeId = 'fridge_' .. math.floor(coords.x) .. '_' .. math.floor(coords.y)

                    TriggerServerEvent('ts-lets-eat:server:OpenFridge', fridgeId)

                    -- Slight delay to ensure server registered stash
                    SetTimeout(200, function()
                        if Config.Inventory == 'ox' then
                            exports.ox_inventory:openInventory('stash', fridgeId)
                        elseif Config.Inventory == 'qb' then
                            TriggerServerEvent('inventory:server:OpenInventory', 'stash', fridgeId, {
                                maxweight = 100000,
                                slots = 50,
                            })
                            TriggerEvent('inventory:client:SetCurrentStash', fridgeId)
                        elseif Config.Inventory == 'qs' then
                            exports['qs-inventory']:openInventory('stash', fridgeId)
                        end
                    end)
                end
            }
        })
    end

    -- Setup Wholesale Sourcing Peds
    if Config.BusinessSourcing.enabled then
        lib.requestModel(Config.BusinessSourcing.pedModel)

        for _, coords in ipairs(Config.BusinessSourcing.locations) do
            local ped = CreatePed(0, Config.BusinessSourcing.pedModel, coords.x, coords.y, coords.z - 1.0, 0.0, false, false)
            FreezeEntityPosition(ped, true)
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)

            if Config.Target == 'ox_target' then
                exports.ox_target:addLocalEntity(ped, {
                    {
                        name = 'ts_lets_eat_wholesale',
                        icon = 'fas fa-box',
                        label = 'Purchase Wholesale Ingredients',
                        onSelect = function()
                            OpenWholesaleMenu()
                        end
                    }
                })
            end
        end
        SetModelAsNoLongerNeeded(Config.BusinessSourcing.pedModel)
    end
end)

function OpenWholesaleMenu()
    local options = {}

    for itemName, itemData in pairs(Config.Items) do
        if itemData.type == 'ingredient' then
            table.insert(options, {
                title = itemData.label,
                description = 'Purchase wholesale box (x50)',
                onSelect = function()
                    local input = lib.inputDialog('Wholesale Order', {
                        {type = 'number', label = 'Quantity of boxes (x50)', default = 1, min = 1, max = 10}
                    })
                    if not input then return end

                    local boxes = input[1]

                    TriggerServerEvent('ts-lets-eat:server:PurchaseWholesale', itemName, boxes)
                end
            })
        end
    end

    lib.registerContext({
        id = 'wholesale_menu',
        title = 'Wholesale Market',
        options = options
    })

    lib.showContext('wholesale_menu')
end

-- Management Menu
function OpenStorefrontManagementMenu(restId, data)
    local items = lib.callback.await('ts-lets-eat:server:GetStorefrontItems', 200, restId)

    local options = {
        {
            title = 'Add / Update Item',
            description = 'Add a new item to the menu or update an existing price.',
            icon = 'plus',
            onSelect = function()
                local input = lib.inputDialog('Add Menu Item', {
                    {type = 'input', label = 'Item Spawn Name (e.g., bologna_sandwich)', required = true},
                    {type = 'number', label = 'Price ($)', default = 10, min = 1, required = true}
                })
                if not input then return end

                TriggerServerEvent('ts-lets-eat:server:AddStorefrontItem', restId, input[1], input[2])
            end
        }
    }

    for i, itemData in ipairs(items) do
        local configItem = Config.Items[itemData.name]
        if configItem then
            table.insert(options, {
                title = 'Remove ' .. configItem.label,
                description = 'Currently listed for $' .. itemData.price,
                icon = 'trash',
                onSelect = function()
                    local alert = lib.alertDialog({
                        header = 'Remove Item',
                        content = 'Are you sure you want to remove ' .. configItem.label .. ' from the menu?',
                        centered = true,
                        cancel = true
                    })

                    if alert == 'confirm' then
                        TriggerServerEvent('ts-lets-eat:server:RemoveStorefrontItem', restId, itemData.name)
                    end
                end
            })
        end
    end

    lib.registerContext({
        id = 'storefront_manage_' .. restId,
        title = 'Manage ' .. data.label,
        options = options
    })

    lib.showContext('storefront_manage_' .. restId)
end


-- Storefront Interaction Menu
local function OpenStorefrontMenu(restId, data)
    local items = lib.callback.await('ts-lets-eat:server:GetStorefrontItems', 200, restId)
    local options = {}

    for i, itemData in ipairs(items) do
        local configItem = Config.Items[itemData.name]
        if configItem then
            table.insert(options, {
                title = configItem.label,
                description = 'Price: $' .. itemData.price,
                onSelect = function()
                    local input = lib.inputDialog('Purchase ' .. configItem.label, {
                        {type = 'number', label = 'Quantity', default = 1, min = 1, max = 20}
                    })
                    if not input then return end

                    local quantity = input[1]
                    TriggerServerEvent('ts-lets-eat:server:PurchaseStorefrontItem', restId, i, quantity)
                end
            })
        end
    end

    lib.registerContext({
        id = 'storefront_menu_' .. restId,
        title = data.label .. ' Menu',
        options = options
    })

    lib.showContext('storefront_menu_' .. restId)
end

-- Setup Restaurant Storefronts
CreateThread(function()
    if not Config.Restaurants then return end
    for restId, data in pairs(Config.Restaurants) do
        if data.storefront and data.storefront.enabled then
            lib.requestModel(data.storefront.pedModel)

            local coords = data.storefront.coords
            local ped = CreatePed(0, data.storefront.pedModel, coords.x, coords.y, coords.z - 1.0, coords.w, false, false)
            FreezeEntityPosition(ped, true)
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)

            if Config.Target == 'ox_target' then
                exports.ox_target:addLocalEntity(ped, {
                    {
                        name = 'ts_lets_eat_storefront_' .. restId,
                        icon = 'fas fa-cash-register',
                        label = 'Browse Menu',
                        onSelect = function()
                            OpenStorefrontMenu(restId, data)
                        end
                    },
                    {
                        name = 'ts_lets_eat_manage_storefront_' .. restId,
                        icon = 'fas fa-cog',
                        label = 'Manage Storefront',
                        canInteract = function()
                            -- Since jobs sync can be complex across frameworks purely on client,
                            -- we check visually. Proper security is server-side.
                            return true
                        end,
                        onSelect = function()
                            OpenStorefrontManagementMenu(restId, data)
                        end
                    }
                })
            end

            SetModelAsNoLongerNeeded(data.storefront.pedModel)
        end

        -- Custom Cooking Stations (Zones)
        if data.cookingStations and type(data.cookingStations) == 'table' then
            for i, station in ipairs(data.cookingStations) do
                if Config.Target == 'ox_target' then
                    exports.ox_target:addSphereZone({
                        coords = station.coords,
                        radius = station.radius or 1.0,
                        debug = false,
                        options = {
                            {
                                name = 'ts_lets_eat_custom_cook_' .. restId .. '_' .. i,
                                icon = 'fas fa-utensils',
                                label = 'Cook Food (' .. data.label .. ')',
                                groups = data.job,
                                onSelect = function()
                                    -- Using the coords of the station as the dummy entity coords for prop spawning
                                    local dummyEntity = CreateObject(`prop_cs_rub_binbag_01`, station.coords.x, station.coords.y, station.coords.z, false, false, false)
                                    SetEntityVisible(dummyEntity, false)
                                    FreezeEntityPosition(dummyEntity, true)

                                    OpenCookingMenu(dummyEntity)

                                    -- Cleanup dummy entity after menu closes/cooking finishes
                                    SetTimeout(60000, function()
                                        if DoesEntityExist(dummyEntity) then DeleteEntity(dummyEntity) end
                                    end)
                                end
                            }
                        }
                    })
                end
            end
        end
    end
end)
