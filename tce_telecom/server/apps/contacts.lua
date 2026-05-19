-- tce_telecom/server/apps/contacts.lua

-- Fetch Contacts for a specific IMEI
lib.callback.register('tce_telecom:server:GetContacts', function(source, imei)
    if not imei then return {} end

    local contacts = MySQL.query.await('SELECT id, name, number FROM telecom_contacts WHERE imei = ?', {imei})
    return contacts or {}
end)

-- Add Contact
lib.callback.register('tce_telecom:server:AddContact', function(source, imei, name, number)
    if not imei or not name or not number then return false end

    local id = MySQL.insert.await('INSERT INTO telecom_contacts (imei, name, number) VALUES (?, ?, ?)', {
        imei, name, number
    })

    return id > 0
end)

-- Delete Contact
lib.callback.register('tce_telecom:server:DeleteContact', function(source, id)
    if not id then return false end

    local affected = MySQL.update.await('DELETE FROM telecom_contacts WHERE id = ?', {id})
    return affected > 0
end)
