Config = Config or {}

-- Panel Settings
Config.PanelTitle = "HARD STREETZ OF PHILLY V2"

-- Gods: full access (add your staff hexes)
Config.Gods = {
    ["steam:11000016e16bfb7"] = true
}

-- Discord webhook for logs (optional)
Config.AdminLogWebhook = ""

-- Clothing integration note:
-- We use /pedmenu <cid> for gods via the admin panel button.

-- Default per-admin permissions (non-gods).
-- These are the "base" defaults; DB overrides at runtime for each admin.
Config.AdminPermissions = {
  -- ["steam:1100001ABCDEF01"] = {
  --   viewPlayers=true,
  --   viewInventory=true, removeItems=true, giveItems=true,
  --   manageVehicles=true,
  --   warnPlayers=true, kickPlayers=true, banPlayers=true,
  --   healPlayers=true, killPlayers=true, teleportPlayers=true, spectatePlayers=true,
  --   giveMoney=true, giveClothing=true, manageJobs=true,
  --   viewReports=true, messagePlayers=true,
  --   viewCheatAlerts=true, freezePlayers=true,
  --   viewAdminChat=true
  -- }
}

-- Action cooldowns (seconds)
Config.Cooldowns = {
  removeItem=2, addItem=2,
  addVehicle=3, removeVehicle=3,
  kick=2, ban=3, warn=1,
  heal=2, kill=2, bring=2, teleportTo=2,
  giveMoney=2, setJob=2, removeJob=2
}

-- Vehicle presets (example)
Config.VehiclePresets = {
  superfast = { engine=3, brakes=2, transmission=2, turbo=true },
  offroad   = { suspension=2, tires="offroad", armor=3 }
}

-- UI Color Themes (customizable by admins)
-- Admins can change these colors to match their server branding
Config.UIThemes = {
  default = {
    primary = "#e67e22",        -- Orange (buttons, accents)
    secondary = "#34495e",      -- Dark blue-grey (button backgrounds)
    background = "#23272a",     -- Dark grey (main background)
    sidebar = "#2c3e50",        -- Blue-grey (sidebar)
    hover = "#f39c12",          -- Light orange (hover state)
    active = "#e67e22",         -- Orange (active/pressed state)
    text = "#ffffff",           -- White text
    textDim = "#aaaaaa"         -- Dimmed text
  },
  blue = {
    primary = "#3498db",
    secondary = "#2c3e50",
    background = "#1a1a2e",
    sidebar = "#16213e",
    hover = "#5dade2",
    active = "#2980b9",
    text = "#ffffff",
    textDim = "#95a5a6"
  },
  purple = {
    primary = "#9b59b6",
    secondary = "#34495e",
    background = "#1e1e2f",
    sidebar = "#2c2c54",
    hover = "#bb8fce",
    active = "#8e44ad",
    text = "#ffffff",
    textDim = "#a29bfe"
  },
  green = {
    primary = "#27ae60",
    secondary = "#2c3e50",
    background = "#1e2a1e",
    sidebar = "#263829",
    hover = "#52be80",
    active = "#229954",
    text = "#ffffff",
    textDim = "#a9dfbf"
  },
  red = {
    primary = "#e74c3c",
    secondary = "#34495e",
    background = "#2a1e1e",
    sidebar = "#3b2626",
    hover = "#ec7063",
    active = "#c0392b",
    text = "#ffffff",
    textDim = "#f1948a"
  }
}

-- Default theme (change this to switch themes globally)
Config.DefaultTheme = "default"
