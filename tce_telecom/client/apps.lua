-- tce_telecom/client/apps.lua

-- NUI Callback: Get Contacts
RegisterNUICallback('getContacts', function(data, cb)
    -- We assume the currentPhoneIMEI is tracked locally in client/core.lua
    -- For now, we will pass it back to server. In a full implementation, the client remembers the open IMEI.
    local imei = data.imei or "1234567890"

    local contacts = lib.callback.await('tce_telecom:server:GetContacts', false, imei)
    cb(contacts)
end)

-- NUI Callback: Add Contact
RegisterNUICallback('addContact', function(data, cb)
    local imei = data.imei or "1234567890"
    local success = lib.callback.await('tce_telecom:server:AddContact', false, imei, data.name, data.number)
    cb({ success = success })
end)

-- NUI Callback: Delete Contact
RegisterNUICallback('deleteContact', function(data, cb)
    local success = lib.callback.await('tce_telecom:server:DeleteContact', false, data.id)
    cb({ success = success })
end)

-- NUI Callback: Get Bank Balance (Will be handled by bank.lua bridge)
RegisterNUICallback('getBankData', function(data, cb)
    local bankData = lib.callback.await('tce_telecom:server:GetBankData', false)
    cb(bankData)
end)

-- NUI Callback: Get Directory
RegisterNUICallback('getDirectory', function(data, cb)
    local directory = lib.callback.await('tce_telecom:server:GetDirectory', false)
    cb(directory)
end)
