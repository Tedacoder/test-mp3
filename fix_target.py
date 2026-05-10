with open('vehicle_inspection/client/main.lua', 'r') as f:
    content = f.read()

import re

# We need to replace the exports.ox_target:addGlobalVehicle blocks with dynamic logic.

# First block: mechanic_inspect
old_target_1 = """-- Ox Target for Mechanic Inspection
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
})"""

new_target_1 = """-- Target for Mechanic Inspection
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
SetupMechanicTarget()"""

content = content.replace(old_target_1, new_target_1)

# Second block: police_check_sticker
old_target_2 = """-- Ox Target for Police Sticker Check
exports.ox_target:addGlobalVehicle({
    {
        name = 'police_check_sticker',
        icon = 'fa-solid fa-magnifying-glass',
        label = locale('check_sticker'),
        onSelect = function(data)
            checkSticker(data.entity)
        end
    }
})"""

new_target_2 = """-- Target for Police Sticker Check
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
SetupPoliceTarget()"""

content = content.replace(old_target_2, new_target_2)

# Third block: mechanic_view_report
old_target_3 = """-- Ox Target for Mechanic View Report
exports.ox_target:addGlobalVehicle({
    {
        name = 'mechanic_view_report',
        icon = 'fa-solid fa-clipboard-list',
        label = locale('view_report'),
        items = Config.Items.Clipboard,
        onSelect = function(data)
            viewReport(data.entity)
        end
    }
})"""

new_target_3 = """-- Target for Mechanic View Report
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
SetupViewReportTarget()"""

content = content.replace(old_target_3, new_target_3)

with open('vehicle_inspection/client/main.lua', 'w') as f:
    f.write(content)
