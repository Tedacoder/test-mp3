Config = {}

-- Jobs that can perform inspections
Config.MechanicJobs = {
    ['mechanic'] = true,
    ['tuner'] = true
}

-- Jobs that can check inspections
Config.PoliceJobs = {
    ['police'] = true,
    ['sheriff'] = true
}

-- Economy Settings
Config.Fees = {
    Initial = 500,     -- Cost of the first inspection
    ReInspection = 200 -- Cost if re-inspected within ReInspectionTimeframe
}

-- Timeframes
Config.Timeframes = {
    GracePeriod = 48 * 60 * 60, -- 48 hours in seconds (grace period after failing before impound)
    ReInspection = 24 * 60 * 60, -- 24 hours in seconds (timeframe for cheaper re-inspection)
    Expiry = 30 * 24 * 60 * 60 -- 30 days in seconds (how long a pass is valid for)
}

-- Health Thresholds (0.0 to 1000.0)
-- A part fails if its health drops BELOW this value.
Config.Thresholds = {
    Engine = 800.0,       -- Checks engine health
    Body = 800.0,         -- Checks body health
    Brakes = 800.0,       -- Checks wheel health
    Tank = 800.0,         -- Checks petrol tank health
    Tires = true,         -- Set to true to check if any tires are burst
    Windows = true,       -- Set to true to check if any windows are smashed
    Doors = true          -- Set to true to check if any doors are missing
}

-- Items
Config.Items = {
    Clipboard = 'diagnostic_clipboard',
    Certificate = 'inspection_certificate'
}

-- Custom License Plate Style
-- Set to false to disable enforcing a plate style.
-- Set to a number (e.g., 3) to enforce that texture ID from vehshare.ytd.
Config.PlateStyle = 3
