-- tce_telecom/server/apps/social.lua

Citizen.CreateThread(function()
    while not Bridge or not Bridge.Framework do Wait(100) end

    -- Fetch Social Posts (Chirps/FaceSpace)
    lib.callback.register('tce_telecom:server:GetSocialPosts', function(source)
        -- In a full implementation, this joins `telecom_social_posts` and `telecom_social_accounts`
        local posts = MySQL.query.await([[
            SELECT p.id, p.content, p.timestamp, a.display_name, a.username
            FROM telecom_social_posts p
            LEFT JOIN telecom_social_accounts a ON p.account_id = a.id
            ORDER BY p.timestamp DESC LIMIT 20
        ]])

        return posts or {}
    end)

    -- Create a Social Post
    lib.callback.register('tce_telecom:server:CreateSocialPost', function(source, content)
        local citizenid = Bridge.Framework.GetPlayerIdentifier(source)
        if not citizenid or not content then return false end

        -- First find the account ID for this player.
        local account = MySQL.query.await('SELECT id FROM telecom_social_accounts WHERE citizenid = ?', {citizenid})

        -- If no account, they can't post. In a real script, they'd make an account first.
        if not account or #account == 0 then return false end

        local accountId = account[1].id

        local id = MySQL.insert.await('INSERT INTO telecom_social_posts (account_id, content) VALUES (?, ?)', {
            accountId, content
        })

        return id > 0
    end)
end)
