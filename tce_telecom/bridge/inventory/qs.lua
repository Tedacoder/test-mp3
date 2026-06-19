-- Quasar Inventory Bridge
if Config.Inventory ~= 'qs' then return end

Bridge = Bridge or {}
Bridge.Inventory = {
    GetItemMetadata = function(source, slot)
        local item = exports['qs-inventory']:GetItemBySlot(source, slot)
        return item and item.info or {}
    end,

    RegisterUsableItem = function(itemName, callback)
        -- Memory: Note the spelling "CreateUsableItem" for QS vs "CreateUseableItem" for QB
        exports['qs-inventory']:CreateUsableItem(itemName, function(source, item)
            callback(source, item)
        end)
    end,

    HasItem = function(source, itemName)
        local count = exports['qs-inventory']:GetItemTotalAmount(source, itemName)
        return count > 0
    end
}
