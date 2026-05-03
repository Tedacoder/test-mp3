lib.locale()

local function performInspection(vehicle)
    if not vehicle or vehicle == 0 then return end

    local isMechanic = lib.callback.await('vehicle_inspection:checkJob', false, 'mechanic')
    if not isMechanic then
        lib.notify({title = 'Error', description = 'You are not authorized.', type = 'error'})
        return
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    if not plate then return end
    plate = string.gsub(plate, '^%s*(.-)%s*$', '%1') -- Trim whitespace

    -- Progress bar
    if lib.progressBar({
        duration = 5000,
        label = locale('inspecting_progress'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
        anim = {
            dict = 'missheistdockssetup1clipboard@base',
            clip = 'base'
        },
        prop = {
            model = `p_amb_clipboard_01`,
            pos = vec3(0.03, 0.08, 0.02),
            rot = vec3(-90.0, 0.0, 0.0)
        },
    }) then
        -- Inspection Logic
        local failedParts = {}

        -- Engine/Steering
        if GetVehicleEngineHealth(vehicle) < Config.Thresholds.Engine then
            table.insert(failedParts, locale('part_engine'))
        end

        -- Body/Suspension
        if GetVehicleBodyHealth(vehicle) < Config.Thresholds.Body then
            table.insert(failedParts, locale('part_body'))
        end

        -- Fuel Tank
        if GetVehiclePetrolTankHealth(vehicle) < Config.Thresholds.Tank then
            table.insert(failedParts, locale('part_tank'))
        end


        -- Brakes (Wheel Health)
        local numWheels = GetVehicleNumberOfWheels(vehicle)
        local brakeIssue = false
        for i=0, numWheels-1 do
            if GetVehicleWheelHealth(vehicle, i) < Config.Thresholds.Brakes then
                brakeIssue = true
                break
            end
        end
        if brakeIssue then
            table.insert(failedParts, locale('part_brakes'))
        end

        -- Lighting
        -- In GTA, you can check damage status. For simplicity, we check headlights.
        local lightStatus1, lightStatus2, lightStatus3 = GetVehicleLightsState(vehicle)
        local lightMultiplier = GetVehicleLightMultiplier(vehicle)
        -- Also check if they are smashed
        local leftLight = GetIsLeftVehicleHeadlightDamaged(vehicle)
        local rightLight = GetIsRightVehicleHeadlightDamaged(vehicle)

        if leftLight or rightLight or lightMultiplier < 0.8 then
            table.insert(failedParts, locale('part_lighting'))
        end

        -- Tires
        if Config.Thresholds.Tires then
            local numWheels = GetVehicleNumberOfWheels(vehicle)
            local burst = false
            for i=0, numWheels-1 do
                if IsVehicleTyreBurst(vehicle, i, false) then
                    burst = true
                    break
                end
            end
            if burst then
                table.insert(failedParts, locale('part_tires'))
            end
        end

        -- Windows
        if Config.Thresholds.Windows then
            local smashed = false
            for i=0, 7 do
                if not IsVehicleWindowIntact(vehicle, i) then
                    smashed = true
                    break
                end
            end
            if smashed then
                table.insert(failedParts, locale('part_windows'))
            end
        end

        -- Doors
        if Config.Thresholds.Doors then
            local missing = false
            for i=0, 5 do
                if IsVehicleDoorDamaged(vehicle, i) then
                    missing = true
                    break
                end
            end
            if missing then
                table.insert(failedParts, locale('part_doors'))
            end
        end

        local result = #failedParts == 0
        local status = result and 'Passed' or 'Failed'

        local closestPlayerId, closestDistance = lib.getClosestPlayer(GetEntityCoords(cache.ped), 3.0, false)
        local targetServerId = nil
        if closestPlayerId then
            targetServerId = GetPlayerServerId(closestPlayerId)
        end

        -- Send result to server
        local success, msg = lib.callback.await('vehicle_inspection:submitInspection', false, plate, status, failedParts, targetServerId)

        if success then
            if result then
                lib.notify({
                    title = locale('inspect_vehicle'),
                    description = locale('inspection_passed'),
                    type = 'success'
                })
            else
                local failedStr = table.concat(failedParts, ', ')
                lib.notify({
                    title = locale('inspect_vehicle'),
                    description = string.format(locale('inspection_failed'), failedStr),
                    type = 'error'
                })
            end
            if msg then
                lib.notify({
                    title = 'Fee',
                    description = msg,
                    type = 'inform'
                })
            end
        else
            if msg then
                lib.notify({
                    title = 'Error',
                    description = msg,
                    type = 'error'
                })
            end
        end

    else
        -- Cancelled
        lib.notify({
            title = 'Cancelled',
            type = 'error'
        })
    end
end

-- Ox Target for Mechanic Inspection
exports.ox_target:addGlobalVehicle({
    {
        name = 'mechanic_inspect',
        icon = 'fa-solid fa-clipboard-check',
        label = locale('inspect_vehicle'),
        items = Config.Items.Clipboard,
        onSelect = function(data)
            performInspection(data.entity)
        end
    }
})

local function checkSticker(vehicle)
    if not vehicle or vehicle == 0 then return end

    local isPolice = lib.callback.await('vehicle_inspection:checkJob', false, 'police')
    if not isPolice then
        lib.notify({title = 'Error', description = 'You are not authorized.', type = 'error'})
        return
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    if not plate then return end
    plate = string.gsub(plate, '^%s*(.-)%s*$', '%1')

    if lib.progressBar({
        duration = 3000,
        label = locale('checking_sticker'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
        anim = {
            dict = 'anim@amb@board_room@whiteboard@',
            clip = 'think_01_hi_am_amy'
        },
    }) then
        local data = lib.callback.await('vehicle_inspection:checkSticker', false, plate)
        if data then
            local statusLocale = locale('status_' .. string.lower(data.status)) or data.status
            local expiryDate = data.expiry and os.date('%m/%d/%Y', data.expiry) or 'N/A'

            lib.notify({
                title = 'Inspection Sticker',
                description = string.format(locale('sticker_status_msg'), statusLocale, expiryDate),
                type = data.status == 'Passed' and 'success' or 'error',
                duration = 8000
            })

            if data.status == 'Failed' then
                local failedDate = data.failed_date and os.date('%m/%d/%Y', data.failed_date) or 'N/A'
                local impoundDate = data.failed_date and os.date('%m/%d/%Y', data.failed_date + Config.Timeframes.GracePeriod) or 'N/A'
                local parts = type(data.failed_parts) == 'table' and table.concat(data.failed_parts, ', ') or data.failed_parts

                -- Print to chat as a report for police
                TriggerEvent('chat:addMessage', {
                    color = {255, 0, 0},
                    multiline = true,
                    args = {'MDT Report', string.format(locale('mdt_report'), plate, statusLocale, failedDate, parts, impoundDate)}
                })
            end
        else
            lib.notify({
                title = 'Inspection Sticker',
                description = locale('status_none'),
                type = 'inform'
            })
        end
    end
end

-- Ox Target for Police Sticker Check
exports.ox_target:addGlobalVehicle({
    {
        name = 'police_check_sticker',
        icon = 'fa-solid fa-magnifying-glass',
        label = locale('check_sticker'),
        onSelect = function(data)
            checkSticker(data.entity)
        end
    }
})

-- Enforce Custom Plate Style
if Config.PlateStyle then
    CreateThread(function()
        while true do
            Wait(2500) -- Check every 2.5 seconds to keep resmon low

            local vehicles = GetGamePool('CVehicle')
            for i = 1, #vehicles do
                local vehicle = vehicles[i]
                if DoesEntityExist(vehicle) then
                    local currentPlateStyle = GetVehicleNumberPlateTextIndex(vehicle)
                    if currentPlateStyle ~= Config.PlateStyle then
                        SetVehicleNumberPlateTextIndex(vehicle, Config.PlateStyle)
                    end
                end
            end
        end
    end)
end
