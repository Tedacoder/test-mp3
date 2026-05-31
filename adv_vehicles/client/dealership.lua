local showroomVehicles = {
    {model = 'adder', price = 1000000, coords = vec4(-33.0, -1102.0, 26.42, 160.0)},
    {model = 't20', price = 2200000, coords = vec4(-35.0, -1105.0, 26.42, 160.0)}
}

local displayEntities = {}

CreateThread(function()
    -- Spawn showroom displays locally
    for i, data in ipairs(showroomVehicles) do
        local hash = GetHashKey(data.model)
        RequestModel(hash)
        while not HasModelLoaded(hash) do Wait(0) end

        local veh = CreateVehicle(hash, data.coords.x, data.coords.y, data.coords.z, data.coords.w, false, false)
        SetEntityInvincible(veh, true)
        FreezeEntityPosition(veh, true)
        SetVehicleDoorsLocked(veh, 2)
        SetModelAsNoLongerNeeded(hash)

        displayEntities[i] = veh

        if Config.UseOxTarget then
            exports.ox_target:addLocalEntity(veh, {
                {
                    name = 'buy_car_'..i,
                    icon = 'fas fa-money-bill',
                    label = 'Purchase ' .. data.model:upper() .. ' ($' .. data.price .. ')',
                    onSelect = function()
                        TriggerEvent('adv_vehicles:client:OpenPurchaseMenu', data)
                    end
                }
            })
        end
    end
end)

RegisterNetEvent('adv_vehicles:client:OpenPurchaseMenu', function(data)
    if Config.UseOxLib then
        lib.registerContext({
            id = 'purchase_menu',
            title = 'Dealership',
            options = {
                {
                    title = 'Buy Outright',
                    description = 'Cost: $' .. data.price,
                    onSelect = function()
                        lib.callback('adv_vehicles:server:PurchaseVehicle', false, function(success, msg, plate)
                            Framework.Notify(msg, success and "success" or "error")
                        end, data.model, data.price, false, 0)
                    end
                },
                {
                    title = 'Finance Vehicle',
                    description = '20% Down: $' .. math.floor(data.price * 0.20),
                    onSelect = function()
                        lib.callback('adv_vehicles:server:PurchaseVehicle', false, function(success, msg, plate)
                            Framework.Notify(msg, success and "success" or "error")
                        end, data.model, data.price, true, math.floor(data.price * 0.20))
                    end
                }
            }
        })
        lib.showContext('purchase_menu')
    end
end)

AddEventHandler('onResourceStop', function(resName)
    if resName == GetCurrentResourceName() then
        for _, veh in pairs(displayEntities) do
            if DoesEntityExist(veh) then DeleteEntity(veh) end
        end
    end
end)

-- Fix test drive cleanup to return vehicle to original spawn instead of deleting it permanently if needed, or simply delete test instance.
-- Current script already deletes test drive instances gracefully.
