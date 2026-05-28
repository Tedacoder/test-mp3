if IsDuplicityVersion() then
    -- SERVER SIDE
    function HealOrRevivePlayer(targetSource)
        local isQbox = (GetResourceState('qbx_core') == 'started')
        local isQBCore = (GetResourceState('qb-core') == 'started')

        if isQbox then
            exports.qbx_core:SetMetadata(targetSource, 'hunger', 100)
            exports.qbx_core:SetMetadata(targetSource, 'thirst', 100)
            exports.qbx_core:SetMetadata(targetSource, 'stress', 0)
        elseif isQBCore then
            local Player = exports['qb-core']:GetCoreObject().Functions.GetPlayer(targetSource)
            if Player then
                Player.Functions.SetMetaData('hunger', 100)
                Player.Functions.SetMetaData('thirst', 100)
                Player.Functions.SetMetaData('stress', 0)
            end
        end

        ExecuteCommand("revive " .. tostring(targetSource))
        if Config.MedicalSystem == "qbx_medical" then
            TriggerClientEvent('adminpanel:client:executeInternalHeal', targetSource, true)
        elseif Config.MedicalSystem == "qb-ambulance" then
            TriggerClientEvent('hospital:client:Revive', targetSource)
        elseif Config.MedicalSystem == "wasabi" then
            exports.wasabi_ambulance:RevivePlayer(targetSource)
        else
            TriggerClientEvent('adminpanel:client:executeInternalHeal', targetSource, false)
        end

        return true
    end
else
    -- CLIENT SIDE
    RegisterNetEvent('adminpanel:client:executeInternalHeal', function(useQbxMedical)
        local playerPed = PlayerPedId()

        if useQbxMedical and GetResourceState('qbx_medical') == 'started' then
            TriggerEvent('qbx_medical:client:heal')
        end

        local maxHealth = GetEntityMaxHealth(playerPed)
        SetEntityHealth(playerPed, maxHealth)
        SetPedArmour(playerPed, 100)

        ClearPedBloodDamage(playerPed)
        ResetPedVisibleDamage(playerPed)
        ClearPedLastWeaponDamage(playerPed)

        if IsPedRagdoll(playerPed) then
            SetPedToRagdoll(playerPed, 0, 0, 0, false, false, false)
        end

        NetworkResurrectLocalPlayer(GetEntityCoords(playerPed), GetEntityHeading(playerPed), true, false)

        if GetResourceState('ox_lib') == 'started' then
            lib.notify({
                title = 'System Updated',
                description = 'Your physical health, vitals, and states have been completely restored.',
                type = 'success'
            })
        else
            SendNUIMessage({ type = "toast", message = "Health completely restored." })
        end
    end)
end
