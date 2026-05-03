local isUiOpen = false

-- Command to open the POS UI
RegisterCommand('register', function()
    SetDisplay(true)
end, false)

function SetDisplay(bool)
    isUiOpen = bool
    SetNuiFocus(bool, bool)
    SendNUIMessage({
        type = "ui",
        status = bool,
        storeName = Config.StoreName
    })

    if bool then
        TriggerServerEvent('pos:server:requestState')
    end
end

RegisterNUICallback('close', function(data, cb)
    SetDisplay(false)
    cb('ok')
end)

RegisterNUICallback('addInventory', function(data, cb)
    TriggerServerEvent('pos:server:addInventory', data)
    cb('ok')
end)

RegisterNUICallback('addToTicket', function(data, cb)
    TriggerServerEvent('pos:server:addToTicket', data.name)
    cb('ok')
end)

RegisterNUICallback('checkout', function(data, cb)
    TriggerServerEvent('pos:server:checkout', data.payment_method)
    cb('ok')
end)

RegisterNetEvent('pos:client:updateState')
AddEventHandler('pos:client:updateState', function(inventory, ticket)
    if isUiOpen then
        SendNUIMessage({
            type = "updateState",
            inventory = inventory,
            ticket = ticket
        })
    end
end)

RegisterNetEvent('pos:client:checkoutResponse')
AddEventHandler('pos:client:checkoutResponse', function(msg)
    if isUiOpen then
        SendNUIMessage({
            type = "checkoutResponse",
            message = msg
        })
    end
end)
