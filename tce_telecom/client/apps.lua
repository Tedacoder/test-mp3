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
    local imei = data.imei or "1234567890"
    local success = lib.callback.await('tce_telecom:server:DeleteContact', false, data.id, imei)
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

-- NUI Callback: Get Jobs
RegisterNUICallback('getJobs', function(data, cb)
    local jobs = lib.callback.await('tce_telecom:server:GetJobs', false)
    cb(jobs)
end)

-- NUI Callback: Apply for Job
RegisterNUICallback('applyForJob', function(data, cb)
    local success = lib.callback.await('tce_telecom:server:ApplyForJob', false, data.id)
    cb({ success = success })
end)

-- NUI Callback: Get Social Posts
RegisterNUICallback('getSocialPosts', function(data, cb)
    local posts = lib.callback.await('tce_telecom:server:GetSocialPosts', false)
    cb(posts)
end)

-- NUI Callback: Create Social Post
RegisterNUICallback('createSocialPost', function(data, cb)
    local success = lib.callback.await('tce_telecom:server:CreateSocialPost', false, data.content)
    cb({ success = success })
end)

-- NUI Callback: Get Store Items
RegisterNUICallback('getStoreItems', function(data, cb)
    local items = lib.callback.await('tce_telecom:server:GetStoreItems', false)
    cb(items)
end)
