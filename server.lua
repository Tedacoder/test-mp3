local inventory = {}
local currentTicket = {}

RegisterNetEvent('pos:server:addInventory')
AddEventHandler('pos:server:addInventory', function(item)
    inventory[item.name] = item.price
    TriggerClientEvent('pos:client:updateState', -1, inventory, currentTicket)
end)

RegisterNetEvent('pos:server:addToTicket')
AddEventHandler('pos:server:addToTicket', function(name)
    table.insert(currentTicket, name)
    TriggerClientEvent('pos:client:updateState', -1, inventory, currentTicket)
end)

RegisterNetEvent('pos:server:checkout')
AddEventHandler('pos:server:checkout', function(method)
    local src = source
    local total = 0
    for _, item in ipairs(currentTicket) do
        if inventory[item] then
            total = total + inventory[item]
        end
    end

    currentTicket = {}

    local msg = ""
    if method == "bank" then
        msg = string.format("Checkout successful. $%.2f deducted directly from customer bank.", total)
    else
        msg = string.format("Checkout successful. $%.2f paid in cash.", total)
    end

    TriggerClientEvent('pos:client:checkoutResponse', src, msg)
    TriggerClientEvent('pos:client:updateState', -1, inventory, currentTicket)
end)

RegisterNetEvent('pos:server:requestState')
AddEventHandler('pos:server:requestState', function()
    local src = source
    TriggerClientEvent('pos:client:updateState', src, inventory, currentTicket)
end)
