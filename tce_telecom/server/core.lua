-- server/core.lua
print("^2[TCE Telecom]^7 Initializing Core...")

-- Setup callback for client to get server time
lib.callback.register('tce_telecom:server:GetTime', function(source)
    return Bridge.Framework.GetServerTime()
end)
