lib.locale()

local function performInspection(vehicle)
    if not vehicle or vehicle == 0 then return end

    local isMechanic = lib.callback.await('vehicle_inspection:checkJob', false, 'mechanic')

    local plate = GetVehicleNumberPlateText(vehicle)
    if not plate then return end
    plate = string.gsub(plate, '^%s*(.-)%s*$', '%1') -- Trim whitespace

    -- Progress bar
    local animDict = 'missheistdockssetup1clipboard@base'
    local animClip = 'base'
    local duration = 5000
    local pLabel = locale('inspecting_progress')

    if not isMechanic then
        duration = 10000 -- takes longer to forge
        pLabel = locale('forging_progress')
        animDict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@'
        animClip = 'machinic_loop_mechandplayer'
    end

    if lib.progressBar({
        duration = duration,
        label = pLabel,
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
        anim = {
            dict = animDict,
            clip = animClip
        },
        prop = isMechanic and {
            model = `p_amb_clipboard_01`,
            bone = 18905,
            pos = vec3(0.10, 0.02, 0.08),
            rot = vec3(-80.0, 0.0, 0.0)
        } or nil,
    }) then
        local failedParts = {}
        local status = 'Passed'
        local result = true

        if isMechanic then
            -- Inspection Logic
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
            local lightStatus1, lightStatus2, lightStatus3 = GetVehicleLightsState(vehicle)
            local lightMultiplier = GetVehicleLightMultiplier(vehicle)
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

            result = #failedParts == 0
            status = result and 'Passed' or 'Failed'
        else
            -- Non-mechanic doing a fake inspection
            status = 'Fake'
            result = true
        end

        local closestPlayerId, closestDistance = lib.getClosestPlayer(GetEntityCoords(cache.ped), 3.0, false)
        local targetServerId = nil
        if closestPlayerId then
            targetServerId = GetPlayerServerId(closestPlayerId)
        end

        -- Send result to server
        local success, msg = lib.callback.await('vehicle_inspection:submitInspection', false, plate, status, failedParts, targetServerId)

        if success then
            if not isMechanic then
                lib.notify({
                    title = locale('inspect_vehicle'),
                    description = locale('fake_inspection_done'),
                    type = 'success'
                })
            elseif result then
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

-- Target for Mechanic Inspection
local function SetupMechanicTarget()
    local options = {
        {
            name = 'mechanic_inspect',
            icon = 'fa-solid fa-clipboard-check',
            label = locale('inspect_vehicle'),
            item = Config.Items.Clipboard, -- qb-target/qtarget uses item
            items = Config.Items.Clipboard, -- ox_target uses items
            action = function(entity)
                performInspection(entity)
            end,
            onSelect = function(data)
                performInspection(data.entity)
            end
        }
    }

    if Config.Target == 'ox_target' then
        exports.ox_target:addGlobalVehicle(options)
    elseif Config.Target == 'qb-target' then
        exports['qb-target']:AddGlobalVehicle({ options = options, distance = 3.0 })
    elseif Config.Target == 'qtarget' then
        exports.qtarget:Vehicle({ options = options, distance = 3.0 })
    end
end
SetupMechanicTarget()

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
            local expiryDate = data.formatted_expiry or 'N/A'

            local extraWarning = ''
            if data.status == 'Fake' then
                extraWarning = '\n' .. locale('sticker_fake_warning')
            end

            lib.notify({
                title = 'Inspection Sticker',
                description = string.format(locale('sticker_status_msg'), statusLocale, expiryDate, extraWarning),
                type = (data.status == 'Passed' or data.status == 'Fake') and 'success' or 'error',
                duration = 8000
            })

            if data.status == 'Failed' then
                local failedDate = data.formatted_failed_date or 'N/A'
                local impoundDate = data.formatted_impound_date or 'N/A'
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

-- Target for Police Sticker Check
local function SetupPoliceTarget()
    local options = {
        {
            name = 'police_check_sticker',
            icon = 'fa-solid fa-magnifying-glass',
            label = locale('check_sticker'),
            action = function(entity)
                checkSticker(entity)
            end,
            onSelect = function(data)
                checkSticker(data.entity)
            end
        }
    }

    if Config.Target == 'ox_target' then
        exports.ox_target:addGlobalVehicle(options)
    elseif Config.Target == 'qb-target' then
        exports['qb-target']:AddGlobalVehicle({ options = options, distance = 3.0 })
    elseif Config.Target == 'qtarget' then
        exports.qtarget:Vehicle({ options = options, distance = 3.0 })
    end
end
SetupPoliceTarget()

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

local function viewReport(vehicle)
    if not vehicle or vehicle == 0 then return end

    local isMechanic = lib.callback.await('vehicle_inspection:checkJob', false, 'mechanic')
    if not isMechanic then
        lib.notify({title = 'Error', description = 'You are not authorized.', type = 'error'})
        return
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    if not plate then return end
    plate = string.gsub(plate, '^%s*(.-)%s*$', '%1')

    if lib.progressBar({
        duration = 2000,
        label = locale('checking_report'),
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
            bone = 18905,
            pos = vec3(0.10, 0.02, 0.08),
            rot = vec3(-80.0, 0.0, 0.0)
        },
    }) then
        local data = lib.callback.await('vehicle_inspection:checkSticker', false, plate)
        if data and data.status then
            -- Let's open a context menu to show the details
            local partsOptions = {}
            local failedPartsTbl = {}
            if data.failed_parts and type(data.failed_parts) == 'table' then
                for _, part in ipairs(data.failed_parts) do
                    failedPartsTbl[part] = true
                end
            end

            local allParts = {
                locale('part_engine'),
                locale('part_body'),
                locale('part_tank'),
                locale('part_brakes'),
                locale('part_lighting'),
                locale('part_tires'),
                locale('part_windows'),
                locale('part_doors')
            }

            for _, part in ipairs(allParts) do
                local isFailed = failedPartsTbl[part]
                local icon = isFailed and 'fa-solid fa-xmark' or 'fa-solid fa-check'
                local color = isFailed and '#ff3333' or '#33cc33'
                local desc = isFailed and locale('status_failed') or locale('status_passed')

                table.insert(partsOptions, {
                    title = part,
                    description = desc,
                    icon = icon,
                    iconColor = color,
                })
            end

            lib.registerContext({
                id = 'inspection_report_menu',
                title = string.format(locale('report_title'), plate),
                options = partsOptions
            })

            lib.showContext('inspection_report_menu')
        else
            lib.notify({
                title = 'Diagnostic Report',
                description = locale('status_none'),
                type = 'inform'
            })
        end
    end
end

-- Target for Mechanic View Report
local function SetupViewReportTarget()
    local options = {
        {
            name = 'mechanic_view_report',
            icon = 'fa-solid fa-clipboard-list',
            label = locale('view_report'),
            item = Config.Items.Clipboard,
            items = Config.Items.Clipboard,
            action = function(entity)
                viewReport(entity)
            end,
            onSelect = function(data)
                viewReport(data.entity)
            end
        }
    }

    if Config.Target == 'ox_target' then
        exports.ox_target:addGlobalVehicle(options)
    elseif Config.Target == 'qb-target' then
        exports['qb-target']:AddGlobalVehicle({ options = options, distance = 3.0 })
    elseif Config.Target == 'qtarget' then
        exports.qtarget:Vehicle({ options = options, distance = 3.0 })
    end
end
SetupViewReportTarget()
