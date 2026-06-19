-- tce_telecom/server/apps/bank.lua

Citizen.CreateThread(function()
    while not Bridge or not Bridge.Banking do Wait(100) end

    lib.callback.register('tce_telecom:server:GetBankData', function(source)
        return {
            balance = Bridge.Banking.GetBalance(source),
            accountName = Bridge.Banking.GetAccountName(source),
            transactions = Bridge.Banking.GetTransactions(source)
        }
    end)
end)
