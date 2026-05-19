-- tce_telecom/server/apps/store.lua

lib.callback.register('tce_telecom:server:GetStoreItems', function(source)
    -- In a real environment, this might fetch from a dynamic database table.
    -- For now, we return the hardcoded retail store stock.
    return {
        { name = "iTones Pro Max", price = 1200, icon = "fa-mobile-screen" },
        { name = "Star Galaxy Fold", price = 1150, icon = "fa-mobile-screen-button" },
        { name = "Heavy Duty Case", price = 45, icon = "fa-shield-halved" },
        { name = "Waterproof Case", price = 80, icon = "fa-water" },
        { name = "Power Bank", price = 60, icon = "fa-battery-full" },
        { name = "Screen Protector", price = 25, icon = "fa-mobile-screen" }
    }
end)
