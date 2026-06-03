local ox_inventory = exports.ox_inventory
local engines = {"engine", "engine_a", "bumper_f"}

local function Alerts(text, type)
    lib.notify({title = 'Food Trucks', description = text, type = type, duration = 5000})
end

local function GetCitizenId()
    local citizenid = nil
    if GetResourceState('qbx_core') == 'started' then
        local PlayerData = exports.qbx_core:GetPlayerData()
        if PlayerData then citizenid = PlayerData.citizenid end
    elseif GetResourceState('qb-core') == 'started' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local PlayerData = QBCore.Functions.GetPlayerData()
        if PlayerData then citizenid = PlayerData.citizenid end
    end
    return citizenid
end

local function IsVehicleWhitelisted(vehicle)
    if not vehicle or vehicle == 0 or not IsEntityAVehicle(vehicle) then return false end
    local vehicleModel = GetEntityModel(vehicle)
    for _, model in ipairs(Config.Whitelist.model) do
        if vehicleModel == GetHashKey(model) then return true end
    end
    return false
end

local function IsOwner(plate)
    local truckOwner = lib.callback.await('env_foodtrucks:server:getOwner', false, plate)
    local citizenid = GetCitizenId()
    if citizenid and citizenid == truckOwner then
        return true
    end
    return false
end

local function IsEmployee(plate)
    local employeeList = lib.callback.await('env_foodtrucks:server:getEmployees', false, plate)
    if employeeList then
        for _, id in ipairs(employeeList) do
            if id == cache.serverId then
                return true
            end
        end
    end
    return false
end

local function OpenEmployeeMenu(plate)
    local options = {}
    local employeeList = lib.callback.await('env_foodtrucks:server:getEmployees', false, plate)
    local isOwner = IsOwner(plate)

    if employeeList then
        for _, id in ipairs(employeeList) do
            options[#options + 1] = {
                title = 'Server ID #'..id,
                description = 'Select to manage employee.',
                icon = 'fa-solid fa-user',
                onSelect = function()
                    local empOptions = {
                        {
                            title = 'Fire Employee',
                            description = 'Remove from session.',
                            icon = 'fa-solid fa-user-minus',
                            onSelect = function()
                                TriggerServerEvent('env_foodtrucks:server:handleEmployee', plate, id, 'remove')
                                Wait(100)
                                OpenEmployeeMenu(plate)
                            end
                        }
                    }
                    if isOwner then
                        empOptions[#empOptions + 1] = {
                            title = 'Pay Employee',
                            description = 'Transfer funds.',
                            icon = 'fa-solid fa-money-bill-transfer',
                            onSelect = function()
                                local input = lib.inputDialog('Pay Employee #'..id, {
                                    {type = 'number', label = 'Amount', min = 1, default = 100}
                                })
                                if input and input[1] then
                                    TriggerServerEvent('env_foodtrucks:server:payEmployee', plate, id, input[1])
                                end
                            end
                        }
                    end
                    lib.registerContext({
                        id = 'food_truck_employee_manage_'..id,
                        title = 'Manage Employee #'..id,
                        menu = 'food_truck_employees',
                        options = empOptions
                    })
                    lib.showContext('food_truck_employee_manage_'..id)
                end
            }
        end
    end

    lib.registerContext({
        id = 'food_truck_employees',
        title = 'Manage Employees',
        menu = 'foodtruck_main_menu',
        options = options
    })
    lib.showContext('food_truck_employees')
end

local function ExecuteCraftStep(step, plate, recipeId, stepId)
    for _, ing in pairs(step.ingredients) do
        local count = lib.callback.await('env_foodtrucks:server:stashCount', false, ing.item, plate)
        if count < ing.count then
            Alerts('Missing ' .. ing.item .. ' in cooler.', 'error')
            return
        end
    end

    if lib.progressBar({
        duration = step.time,
        label = step.label,
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
        anim = step.anim,
        prop = step.prop
    }) then
        lib.callback.await('env_foodtrucks:server:handleCraft', false, recipeId, stepId, plate)
    else
        Alerts('Crafting cancelled.', 'error')
    end
end

local function OpenCraftingMenu(plate)
    local options = {}
    local dynamicMenu = lib.callback.await('env_foodtrucks:server:getMenuConfig', false, plate) or {}

    -- Single Step Menu Items
    for key, item in pairs(Config.Menu) do
        local canSee = true
        local currentLabel = item.label
        if dynamicMenu[key] then
            if dynamicMenu[key].enabled == false then canSee = false end
            if dynamicMenu[key].label then currentLabel = dynamicMenu[key].label end
        end

        if item.requiresLicense and canSee then
            canSee = false
            local licenses = ox_inventory:Search('slots', 'liquor_license')
            if licenses and #licenses > 0 then
                for _, lic in ipairs(licenses) do
                    if lic.metadata and lic.metadata.expiry then
                        if lic.metadata.expiry > os.time() then
                            canSee = true
                            break
                        end
                    end
                end
            end
        end

        if canSee then
            local metadata = {}
            for _, ing in pairs(item.ingredients) do
                metadata[#metadata + 1] = {label = ing.item, value = ing.count}
            end
            if dynamicMenu[key] and dynamicMenu[key].price then
                metadata[#metadata + 1] = {label = 'Price', value = '$' .. dynamicMenu[key].price}
            end

            options[#options + 1] = {
                title = currentLabel,
                description = 'Cook ' .. currentLabel,
                metadata = metadata,
                onSelect = function()
                    ExecuteCraftStep({
                        label = 'Cooking ' .. currentLabel,
                        time = item.time,
                        ingredients = item.ingredients,
                        output = item.item,
                        anim = item.anim,
                        prop = item.prop
                    }, plate, key, nil)
                end
            }
        end
    end

    -- Multi-Step Recipes
    for key, recipe in pairs(Config.MultiStepRecipes) do
        local canSee = true
        local currentLabel = recipe.label

        if dynamicMenu[key] then
            if dynamicMenu[key].enabled == false then canSee = false end
            if dynamicMenu[key].label then currentLabel = dynamicMenu[key].label end
        end

        if canSee then
            local desc = 'Multi-step preparation'
            if dynamicMenu[key] and dynamicMenu[key].price then
                desc = desc .. ' | Price: $' .. dynamicMenu[key].price
            end

            options[#options + 1] = {
                title = currentLabel,
                description = desc,
                icon = 'fa-solid fa-layer-group',
                onSelect = function()
                    local stepOptions = {}
                    for i, step in ipairs(recipe.steps) do
                        local metadata = {}
                        for _, ing in pairs(step.ingredients) do
                            metadata[#metadata + 1] = {label = ing.item, value = ing.count}
                        end

                        stepOptions[#stepOptions + 1] = {
                            title = 'Step ' .. i .. ': ' .. step.label,
                            description = 'Requires specific items to execute.',
                            metadata = metadata,
                            onSelect = function()
                                ExecuteCraftStep(step, plate, key, step.id)
                                lib.showContext('foodtruck_crafting_steps_' .. key)
                            end
                        }
                    end

                    lib.registerContext({
                        id = 'foodtruck_crafting_steps_' .. key,
                        title = currentLabel .. ' Steps',
                        menu = 'foodtruck_crafting',
                        options = stepOptions
                    })
                    lib.showContext('foodtruck_crafting_steps_' .. key)
                end
            }
        end
    end

    lib.registerContext({
        id = 'foodtruck_crafting',
        title = 'Kitchen Station',
        menu = 'foodtruck_main_menu',
        options = options
    })
    lib.showContext('foodtruck_crafting')
end

local function OpenTruckMenu(entity)
    local plate = GetVehicleNumberPlateText(entity)
    local isOwner = IsOwner(plate)
    local options = {}

    if isOwner then
        options[#options + 1] = {
            title = 'Manage Employees',
            description = 'Hire, fire, or pay employees.',
            icon = 'fa-solid fa-people-group',
            onSelect = function() OpenEmployeeMenu(plate) end
        }
        options[#options + 1] = {
            title = 'Open Safe',
            description = 'Owner-only vehicle safe.',
            icon = 'fa-solid fa-piggy-bank',
            onSelect = function()
                ox_inventory:openInventory('stash', {id='food_truck_safe_'..plate})
            end
        }
    end

    options[#options + 1] = {
        title = 'Open Cooler',
        description = 'Shared ingredient stash.',
        icon = 'fa-solid fa-snowflake',
        onSelect = function()
            ox_inventory:openInventory('stash', {id='food_truck_stash_'..plate})
        end
    }

    options[#options + 1] = {
        title = 'Cooking Station',
        description = 'Prepare and cook meals.',
        icon = 'fa-solid fa-fire-burner',
        onSelect = function() OpenCraftingMenu(plate) end
    }

    lib.registerContext({
        id = 'foodtruck_main_menu',
        title = 'Food Truck Management',
        options = options
    })
    lib.showContext('foodtruck_main_menu')
end

-- ox_target: Food Truck Interaction
exports.ox_target:addGlobalVehicle({
    {
        name = 'open_foodtruck',
        icon = 'fa-solid fa-list-check',
        label = 'Food Truck Kitchen',
        canInteract = function(entity)
            return IsVehicleWhitelisted(entity)
        end,
        onSelect = function(data)
            local entity = data.entity
            local plate = GetVehicleNumberPlateText(entity)
            local hasKitchen = lib.callback.await('env_foodtrucks:server:hasKitchen', false, plate)

            if hasKitchen then
                local owner = IsOwner(plate)
                local employee = IsEmployee(plate)
                if owner or employee then
                    OpenTruckMenu(entity)
                else
                    Alerts('You do not have access to this truck.', 'error')
                end
            else
                Alerts('No kitchen installed in this vehicle.', 'error')
            end
        end
    },
    {
        name = 'open_counter',
        icon = 'fa-solid fa-utensils',
        label = 'Service Counter',
        canInteract = function(entity)
            return IsVehicleWhitelisted(entity)
        end,
        onSelect = function(data)
            local entity = data.entity
            local plate = GetVehicleNumberPlateText(entity)
            local hasKitchen = lib.callback.await('env_foodtrucks:server:hasKitchen', false, plate)

            if hasKitchen then
                ox_inventory:openInventory('stash', {id='food_truck_counter_'..plate})
            else
                Alerts('No kitchen installed.', 'error')
            end
        end
    }
})

-- ox_target: Global Player for Hiring
exports.ox_target:addGlobalPlayer({
    {
        name = 'hire_foodtruck_employee',
        icon = 'fa-solid fa-user-plus',
        label = 'Hire as Food Truck Employee',
        canInteract = function(entity, distance, coords, name, bone)
            local playerPed = cache.ped
            local vehicle = GetVehiclePedIsIn(playerPed, true) -- Last vehicle they were in
            if vehicle and vehicle ~= 0 and IsVehicleWhitelisted(vehicle) then
                return true
            end

            local nearestVehicle = lib.getClosestVehicle(GetEntityCoords(playerPed), 10.0, false)
            if nearestVehicle and IsVehicleWhitelisted(nearestVehicle) then
                return true
            end

            return false
        end,
        onSelect = function(data)
            local targetPlayer = NetworkGetPlayerIndexFromPed(data.entity)
            local targetServerId = GetPlayerServerId(targetPlayer)

            local playerPed = cache.ped
            local vehicle = GetVehiclePedIsIn(playerPed, true)
            if not vehicle or vehicle == 0 or not IsVehicleWhitelisted(vehicle) then
                vehicle = lib.getClosestVehicle(GetEntityCoords(playerPed), 10.0, false)
            end

            if vehicle and IsVehicleWhitelisted(vehicle) then
                local plate = GetVehicleNumberPlateText(vehicle)
                local hasKitchen = lib.callback.await('env_foodtrucks:server:hasKitchen', false, plate)
                if hasKitchen then
                    local isOwner = IsOwner(plate)
                    if isOwner then
                        TriggerServerEvent('env_foodtrucks:server:handleEmployee', plate, targetServerId, 'insert')
                    else
                        Alerts('Only the truck owner can hire employees.', 'error')
                    end
                else
                    Alerts('This vehicle does not have a kitchen.', 'error')
                end
            else
                Alerts('You are not near your food truck.', 'error')
            end
        end
    }
})


-- Target: Wholesale Depot
exports.ox_target:addBoxZone({
    coords = Config.WholesaleDepot.coords,
    size = vec3(2, 2, 2),
    rotation = Config.WholesaleDepot.heading,
    debug = false,
    options = {
        {
            name = 'foodtruck_wholesale',
            icon = 'fa-solid fa-box',
            label = 'Wholesale Supplies',
            onSelect = function()
                local options = {}
                for _, item in ipairs(Config.WholesaleDepot.items) do
                    options[#options + 1] = {
                        title = item.item,
                        description = 'Price: $' .. item.price,
                        onSelect = function()
                            local input = lib.inputDialog('Buy ' .. item.item, {
                                {type = 'number', label = 'Amount', min = 1, default = 1}
                            })
                            if input and input[1] then
                                TriggerServerEvent('env_foodtrucks:server:buyWholesale', item.item, input[1])
                            end
                        end
                    }
                end
                lib.registerContext({
                    id = 'foodtruck_wholesale_menu',
                    title = 'Wholesale Depot',
                    options = options
                })
                lib.showContext('foodtruck_wholesale_menu')
            end
        }
    }
})

-- Target: City Hall License
exports.ox_target:addBoxZone({
    coords = Config.CityHall.coords,
    size = vec3(2, 2, 2),
    rotation = Config.CityHall.heading,
    debug = false,
    options = {
        {
            name = 'cityhall_liquor_license',
            icon = 'fa-solid fa-certificate',
            label = 'Purchase Liquor License',
            onSelect = function()
                local alert = lib.alertDialog({
                    header = 'Liquor License',
                    content = 'Purchase a liquor license for $' .. Config.LiquorLicense.cost .. '?\nExpires in ' .. Config.LiquorLicense.expiryDays .. ' days.',
                    centered = true,
                    cancel = true
                })
                if alert == 'confirm' then
                    TriggerServerEvent('env_foodtrucks:server:buyLiquorLicense')
                end
            end
        }
    }
})

-- Target: NPC Sales Logic
if Config.AllowNPCSales then
    exports.ox_target:addGlobalPed({
        {
            name = 'sell_food_npc',
            icon = 'fa-solid fa-burger',
            label = 'Sell Food',
            canInteract = function(entity)
                if IsPedAPlayer(entity) or IsPedDeadOrDying(entity, true) then return false end

                -- Check if player is near or inside their food truck
                local playerPed = cache.ped
                local vehicle = GetVehiclePedIsIn(playerPed, true)
                if not vehicle or vehicle == 0 or not IsVehicleWhitelisted(vehicle) then
                    vehicle = lib.getClosestVehicle(GetEntityCoords(playerPed), 15.0, false)
                end

                if vehicle and IsVehicleWhitelisted(vehicle) then
                    -- Allow interaction if they are near their truck
                    return true
                end
                return false
            end,
            onSelect = function(data)
                local options = {}
                -- Add single step
                for k, v in pairs(Config.Menu) do
                    options[#options + 1] = {
                        title = 'Sell ' .. v.label,
                        onSelect = function()
                            TriggerServerEvent('env_foodtrucks:server:sellToNPC', k)
                        end
                    }
                end
                -- Add multi step outputs
                for k, v in pairs(Config.MultiStepRecipes) do
                    options[#options + 1] = {
                        title = 'Sell ' .. v.label,
                        onSelect = function()
                            TriggerServerEvent('env_foodtrucks:server:sellToNPC', k)
                        end
                    }
                end

                lib.registerContext({
                    id = 'foodtruck_npc_sale_menu',
                    title = 'Offer Food',
                    options = options
                })
                lib.showContext('foodtruck_npc_sale_menu')
            end
        }
    })
end

-- Export: Install Kitchen
exports('install', function(data, slot)
    local playerPed = cache.ped
    local playerCoords = GetEntityCoords(playerPed)
	if cache.vehicle then
        Alerts("You cannot do this in the vehicle!", 'error')
		return
    end

    local vehicle = lib.getClosestVehicle(playerCoords, 5.0, false)
    if IsVehicleWhitelisted(vehicle) then
        local engine = nil
        for i=1, #engines do
            local getEngineIndex = GetEntityBoneIndexByName(vehicle, engines[i])
            if getEngineIndex ~= -1 then
                engine = getEngineIndex
                break
            end
        end
        if #(playerCoords - GetWorldPositionOfEntityBone(vehicle, engine)) <= 2.3 then
            if DoesEntityExist(vehicle) then
                SetVehicleDoorOpen(vehicle, 4, 0, 0)
                TaskStartScenarioInPlace(playerPed, "PROP_HUMAN_BUM_BIN", 0, true)
                ox_inventory:useItem(data, function(data)
                    if lib.progressBar({
                        duration = 5000,
                        label = 'Installing Kitchen Equipment',
                        useWhileDead = false,
                        canCancel = true,
                        disable = {
                            car = true,
                        },
                    }) then
                        Wait(2000)
                        local citizenid = GetCitizenId()
                        if citizenid then
                            TriggerServerEvent("env_foodtruck:server:kitchenAdd", GetVehicleNumberPlateText(vehicle), citizenid)
                            Alerts("Food kitchen installed.", 'success')
                        else
                            Alerts("Could not determine your ID.", 'error')
                        end
                        ClearPedTasksImmediately(playerPed)
                        SetVehicleDoorShut(vehicle, 4, 0)
                    else
                        ClearPedTasksImmediately(playerPed)
                    end
                end)
            end
        else
            Alerts("You are too far from engine!", 'error')
        end
    else
        Alerts("You cannot install a kitchen on this vehicle.", 'error')
    end
end)

-- Export: Open Tablet Manager
exports('openTabletManager', function(plate)
    if not plate then
        local playerPed = cache.ped
        local vehicle = GetVehiclePedIsIn(playerPed, true)
        if not vehicle or vehicle == 0 then
            vehicle = lib.getClosestVehicle(GetEntityCoords(playerPed), 10.0, false)
        end
        if vehicle and IsVehicleWhitelisted(vehicle) then
            plate = GetVehicleNumberPlateText(vehicle)
        else
            Alerts('No truck found nearby to manage.', 'error')
            return
        end
    end

    if not IsOwner(plate) then
        Alerts('Only the owner can access the tablet.', 'error')
        return
    end

    local options = {}
    for key, item in pairs(Config.Menu) do
        options[#options + 1] = {
            title = 'Manage ' .. item.label,
            onSelect = function()
                local input = lib.inputDialog('Manage ' .. item.label, {
                    {type = 'input', label = 'Rename', default = item.label},
                    {type = 'number', label = 'Price', min = 1, default = 10},
                    {type = 'checkbox', label = 'Enabled', checked = true}
                })
                if input then
                    if input[1] ~= item.label then
                        TriggerServerEvent('env_foodtrucks:server:tabletMenuUpdate', plate, 'rename', {recipeId = key, newName = input[1]})
                    end
                    TriggerServerEvent('env_foodtrucks:server:tabletMenuUpdate', plate, 'price', {recipeId = key, price = input[2]})
                    TriggerServerEvent('env_foodtrucks:server:tabletMenuUpdate', plate, 'toggle', {recipeId = key, enabled = input[3]})
                end
            end
        }
    end
    for key, recipe in pairs(Config.MultiStepRecipes) do
        options[#options + 1] = {
            title = 'Manage ' .. recipe.label,
            onSelect = function()
                local input = lib.inputDialog('Manage ' .. recipe.label, {
                    {type = 'input', label = 'Rename', default = recipe.label},
                    {type = 'number', label = 'Price', min = 1, default = 25},
                    {type = 'checkbox', label = 'Enabled', checked = true}
                })
                if input then
                    if input[1] ~= recipe.label then
                        TriggerServerEvent('env_foodtrucks:server:tabletMenuUpdate', plate, 'rename', {recipeId = key, newName = input[1]})
                    end
                    TriggerServerEvent('env_foodtrucks:server:tabletMenuUpdate', plate, 'price', {recipeId = key, price = input[2]})
                    TriggerServerEvent('env_foodtrucks:server:tabletMenuUpdate', plate, 'toggle', {recipeId = key, enabled = input[3]})
                end
            end
        }
    end

    lib.registerContext({
        id = 'foodtruck_tablet_manager',
        title = 'Digital Menu Manager',
        options = options
    })
    lib.showContext('foodtruck_tablet_manager')
end)