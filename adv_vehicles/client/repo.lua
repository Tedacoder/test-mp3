RegisterNetEvent('adv_vehicles:client:StartRepoJob', function()
    lib.callback('adv_vehicles:server:GetRepoVehicles', false, function(vehicles)
        if #vehicles == 0 then
            Framework.Notify("No vehicles currently require repossession.", "inform")
            return
        end

        local options = {}
        for _, veh in ipairs(vehicles) do
            local coords = json.decode(veh.coords)
            table.insert(options, {
                title = 'Repo: ' .. veh.model:upper(),
                description = 'Plate: ' .. veh.plate,
                onSelect = function()
                    SetNewWaypoint(coords.x, coords.y)
                    Framework.Notify("Waypoint set to vehicle location.", "success")
                end
            })
        end

        lib.registerContext({
            id = 'repo_menu',
            title = 'Repo Targets',
            options = options
        })
        lib.showContext('repo_menu')
    end)
end)

RegisterNetEvent('adv_vehicles:client:ExecuteRepo', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local veh = lib.getClosestVehicle(coords, 5.0, true)

    if veh and veh ~= 0 then
        local plate = GetVehicleNumberPlateText(veh)
        local vehCoords = GetEntityCoords(veh)
        TriggerServerEvent('adv_vehicles:server:RepoVehicle', plate, vehCoords)
        TriggerServerEvent('adv_vehicles:server:RepoVehicle', plate, vehCoords, NetworkGetNetworkIdFromEntity(veh))
        Framework.Notify("Vehicle repossessed.", "success")
    else
        Framework.Notify("No vehicle nearby.", "error")
    end
end)

RegisterCommand('repo', function()
    TriggerEvent('adv_vehicles:client:StartRepoJob')
end)
RegisterCommand('repo_execute', function()
    TriggerEvent('adv_vehicles:client:ExecuteRepo')
end)

RegisterNetEvent('adv_vehicles:client:DeleteRepoVehicle', function(netId)
    local veh = NetToVeh(netId)
    if veh and veh ~= 0 then
        TriggerServerEvent('adv_vehicles:server:RepoVehicle', plate, vehCoords, NetworkGetNetworkIdFromEntity(veh))
    end
end)
