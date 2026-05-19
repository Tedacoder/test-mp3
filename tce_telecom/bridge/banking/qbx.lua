-- tce_telecom/bridge/banking/qbx.lua
if Config.Framework ~= 'qbx' then return end

local qbx = exports.qbx_core

Bridge = Bridge or {}
Bridge.Banking = {
    GetBalance = function(source)
        local player = qbx:GetPlayer(source)
        if not player then return 0 end

        -- In QBCore/Qbox, balances are typically stored in PlayerData.money.bank
        return player.PlayerData.money.bank or 0
    end,

    GetAccountName = function(source)
        local player = qbx:GetPlayer(source)
        if not player then return "Unknown" end
        return player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname
    end,

    GetTransactions = function(source)
        -- Complex transaction history is highly dependent on specific resources (e.g. okokBanking, qb-banking)
        -- So we will stub this out for the generic qbx bridge wrapper.
        return {
            { type = "in", amount = 1500, label = "Paycheck", date = os.date('%Y-%m-%d') },
            { type = "out", amount = 50, label = "24/7 Store", date = os.date('%Y-%m-%d') },
            { type = "out", amount = 200, label = "TCE Telecom Bill", date = os.date('%Y-%m-%d') }
        }
    end
}
