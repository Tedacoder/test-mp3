RegisterNetEvent('adv_vehicles:client:AdminSpawnCar', function(model, plate)
    local hash = GetHashKey(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    local veh = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true, false)
    SetVehicleNumberPlateText(veh, plate)
    TaskWarpPedIntoVehicle(ped, veh, -1)
    SetModelAsNoLongerNeeded(hash)

    Framework.Notify("Admin gifted you this vehicle.", "success")
end)

-- Anti-exploit check for VIN tampering
RegisterNetEvent('adv_vehicles:client:ScratchVIN', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)

    if veh ~= 0 and Config.Theft.AllowVinTampering then
        Framework.Progress("scratch_vin", "Scratching VIN...", 10000, false, true, "mini@repair", "fixing_a_ped", 16, nil, function()
            -- Success
            local plate = GetVehicleNumberPlateText(veh)
            TriggerServerEvent('adv_vehicles:server:ScratchVIN', plate)
            Framework.Notify("VIN Scratched.", "success")
        end, function()
            -- Cancel
            Framework.Notify("Cancelled.", "error")
        end)
    end
end)
