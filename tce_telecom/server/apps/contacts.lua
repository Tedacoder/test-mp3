-- tce_telecom/server/apps/contacts.lua

-- Security Helper: Verify player owns the device
local function verifyDeviceOwnership(source, imei)
    local citizenid = Bridge.Framework.GetPlayerIdentifier(source)
    if not citizenid then return false end
    local device = MySQL.query.await('SELECT imei FROM telecom_devices WHERE imei = ? AND citizenid = ?', {imei, citizenid})
    return device and #device > 0
end

-- Fetch Contacts for a specific IMEI
lib.callback.register('tce_telecom:server:GetContacts', function(source, imei)
    if not imei or not verifyDeviceOwnership(source, imei) then return {} end

    local contacts = MySQL.query.await('SELECT id, name, number FROM telecom_contacts WHERE imei = ?', {imei})
    return contacts or {}
end)

-- Add Contact
lib.callback.register('tce_telecom:server:AddContact', function(source, imei, name, number)
    if not imei or not name or not number or not verifyDeviceOwnership(source, imei) then return false end

    local id = MySQL.insert.await('INSERT INTO telecom_contacts (imei, name, number) VALUES (?, ?, ?)', {
        imei, name, number
    })

    return id > 0
end)

-- Delete Contact
lib.callback.register('tce_telecom:server:DeleteContact', function(source, id, imei)
    if not id or not imei or not verifyDeviceOwnership(source, imei) then return false end

    -- Ensure the contact actually belongs to the verified IMEI
    local affected = MySQL.update.await('DELETE FROM telecom_contacts WHERE id = ? AND imei = ?', {id, imei})
    return affected > 0
end)
