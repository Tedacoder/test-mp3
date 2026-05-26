local QBCore = exports['qb-core']:GetCoreObject()
Config = Config or {}

-- State
local actionCooldowns = {}
local adminChatMessages = {}
local cheatAlerts = {}
local reports = {}
local reportCounter = 0
local logsFeed = {}
local adminActionHistory = {} -- { [adminSrc] = { {type, target, details, undoData} } }

-- DB table names
local BAN_TABLE = "admin_bans"
local PERM_TABLE = "admin_permissions"
local WHITELIST_TABLE = "admin_whitelist_items" -- tattoos, skins, clothing

-- Utils
local function now() return os.time() end
local function sanitize(str, max)
  if not str then return "" end
  str = tostring(str):gsub("[%z\1-\31]", ""):gsub("[\r\n]", " ")
  return str:sub(1, max or 128)
end

-- Command to check your steam ID (helps with debugging permissions)
RegisterCommand('checksteam', function(source)
  local ids = {}
  for _, v in ipairs(GetPlayerIdentifiers(source)) do
    if v:find("steam:") then
      print("[Admin Panel] Player", source, "Steam ID:", v)
      TriggerClientEvent('chat:addMessage', source, { args = { 'Admin Panel', 'Your Steam ID: ' .. v } })
      return
    end
  end
  print("[Admin Panel] Player", source, "has no Steam ID!")
  TriggerClientEvent('chat:addMessage', source, { args = { 'Admin Panel', 'No Steam ID found!' } })
end)

local function getIds(src)
  local ids = { steam=nil, license=nil, discord=nil, ip=nil }
  for _, v in ipairs(GetPlayerIdentifiers(src)) do
    if v:find("steam:") then ids.steam = v
    elseif v:find("license:") then ids.license = v
    elseif v:find("discord:") then ids.discord = v
    elseif v:find("ip:") then ids.ip = v end
  end
  return ids
end
local function isGod(src)
  local ids = getIds(src)
  local result = ids.steam and Config.Gods[ids.steam] == true or false
  print("[Permission] isGod check for src:", src, "steam:", ids.steam, "result:", result)
  return result
end
local function hasPermission(src, perm)
  if isGod(src) then return true end
  local ids = getIds(src)
  local perms = ids.steam and Config.AdminPermissions[ids.steam]
  local result = perms and perms[perm] == true or false
  print("[Permission] hasPermission check for src:", src, "perm:", perm, "result:", result)
  return result
end
local function notify(src, msg)
  TriggerClientEvent("admin:notify", src, sanitize(msg, 180))
end
local function getPlayerSafe(targetId)
  if not targetId then return nil end
  -- Allow offline testing with dummy ID 999
  if tonumber(targetId) == 999 then
      return {
          PlayerData = {
              citizenid = "DUMMY123",
              license = "license:dummy123",
              job = { name = "unemployed", grade = { level = 0 } },
              money = { cash = 100, bank = 500 },
              gang = { name = "none" }
          },
          Functions = {
              SetJob = function(job, grade) print("[Dummy] Job set to", job, grade) end,
              AddMoney = function(type, amt, reason) print("[Dummy] Money added:", type, amt) end
          }
      }
  end
  return QBCore.Functions.GetPlayer(tonumber(targetId))
end
local function getName(src)
  if tonumber(src) == 999 then return "Test Dummy" end
  return sanitize(GetPlayerName(src) or "unknown", 64)
end
local function canDoAction(src, action)
  local s = tostring(src)
  actionCooldowns[s] = actionCooldowns[s] or {}
  local cd = (Config.Cooldowns and Config.Cooldowns[action]) or 0
  local last = actionCooldowns[s][action] or 0
  if cd > 0 and (now() - last) < cd then return false end
  actionCooldowns[s][action] = now()
  return true
end
local function pushLogLine(line)
  logsFeed[#logsFeed+1] = line
  if #logsFeed > 200 then table.remove(logsFeed, 1) end
end
local function logAdminAction(adminSrc, actionType, target, details)
  local adminIds = (adminSrc and getIds(adminSrc)) or {}
  local adminName = (adminSrc and getName(adminSrc)) or "SYSTEM"
  local targetName = (target and getName(target)) or "N/A"
  local targetIds = target and getIds(target) or {}
  local line = string.format("[%s] %s (%s) performed %s on %s (%s): %s",
    os.date("%Y-%m-%d %H:%M:%S"),
    adminName, adminIds.steam or "no-steam",
    sanitize(actionType, 64),
    targetName, (targetIds and targetIds.steam) or "no-steam",
    sanitize(details or "", 300)
  )
  -- Need to ensure logs folder exists to avoid error if resource directory structure doesn't have it, but for now:
  -- SaveResourceFile(GetCurrentResourceName(), "logs/admin_log.txt", (line .. "\n"), -1)
  pushLogLine(line)
  if Config.AdminLogWebhook and Config.AdminLogWebhook ~= "" then
    PerformHttpRequest(Config.AdminLogWebhook, function() end, "POST", json.encode({
      username = "Admin Logger",
      content = line
    }), { ["Content-Type"] = "application/json" })
  end

  -- Audit trail for sensitive actions
  local sensitive = {
    updatePermission = true,
    setJob = true,
    removeJob = true,
    ban = true,
    kick = true,
    addItem = true,
    removeItem = true
  }
  if sensitive[actionType] then
    _G.auditTrail = _G.auditTrail or {}
    table.insert(_G.auditTrail, {
      time = os.date("%Y-%m-%d %H:%M:%S"),
      admin = adminName,
      action = actionType,
      target = targetName,
      details = sanitize(details or "", 300)
    })
    if #_G.auditTrail > 100 then table.remove(_G.auditTrail, 1) end
  end

  -- Track action history for undo (inventory add/remove, ban)
  if adminSrc and (actionType == "addItem" or actionType == "removeItem" or actionType == "ban") then
    adminActionHistory[adminSrc] = adminActionHistory[adminSrc] or {}
    local entry = { type = actionType, target = target, details = details, time = now() }
    if actionType == "addItem" or actionType == "removeItem" then
      entry.undoData = details -- details contains item/amount
    elseif actionType == "ban" then
      entry.undoData = { target = target }
    end
    table.insert(adminActionHistory[adminSrc], entry)
    if #adminActionHistory[adminSrc] > 10 then table.remove(adminActionHistory[adminSrc], 1) end
  end
end

-- DB: permission persistence
local function loadPermissionsFromDB()
  local result = MySQL.query.await("SELECT steam_id, permissions FROM "..PERM_TABLE, {})
  if result and #result > 0 then
    for _, row in ipairs(result) do
      local perms = json.decode(row.permissions or "{}")
      if perms then
        Config.AdminPermissions[row.steam_id] = perms
      end
    end
    print(("[AdminPanel] Loaded %d admin permission sets from DB."):format(#result))
  end
end

local function savePermissionsToDB(steam, perms)
  MySQL.insert.await(
    "INSERT INTO "..PERM_TABLE.." (steam_id, permissions) VALUES (?, ?) ON DUPLICATE KEY UPDATE permissions = VALUES(permissions)",
    { steam, json.encode(perms) }
  )
end

CreateThread(function()
  -- Ensure tables exist (bans and permissions). You should also run the provided SQL manually.
  MySQL.query.await(("CREATE TABLE IF NOT EXISTS %s (id INT AUTO_INCREMENT PRIMARY KEY, identifier VARCHAR(64) NOT NULL, name VARCHAR(64) NOT NULL, reason VARCHAR(255), banned_by VARCHAR(64), expires INT, created_at INT)"):format(BAN_TABLE))
  MySQL.query.await(("CREATE TABLE IF NOT EXISTS %s (steam_id VARCHAR(32) PRIMARY KEY, permissions LONGTEXT NOT NULL)"):format(PERM_TABLE))
  MySQL.query.await(("CREATE TABLE IF NOT EXISTS %s (id INT AUTO_INCREMENT PRIMARY KEY, player_identifier VARCHAR(64) NOT NULL, item_type VARCHAR(32) NOT NULL, item_id VARCHAR(64) NOT NULL, granted_by VARCHAR(64) NOT NULL, granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)"):format(WHITELIST_TABLE))
  loadPermissionsFromDB()
end)

-- Bans
local function isIdentifierBanned(identifier)
  local rows = MySQL.query.await(
    "SELECT * FROM " .. BAN_TABLE .. " WHERE identifier = ? AND (expires IS NULL OR expires = 0 OR expires > ?)",
    { identifier, now() }
  )
  return rows and #rows > 0, rows and rows[1]
end
AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)
  deferrals.defer()
  local src = source
  Citizen.Wait(0)
  local ids = getIds(src)
  local id = ids.license or ids.steam or ids.discord
  if not id then deferrals.done("Unable to verify your identifier.") return end
  local banned, row = isIdentifierBanned(id)
  if banned then
    local untilStr = (row.expires and row.expires > 0) and os.date("%Y-%m-%d %H:%M:%S", row.expires) or "Permanent"
    deferrals.done(("You are banned. Reason: %s | Until: %s"):format(row.reason or "N/A", untilStr))
    return
  end
  deferrals.done()
end)
local function addBan(targetSrc, reason, durationSeconds, bannedBy)
  local ids = getIds(targetSrc)
  local ident = ids.license or ids.steam or ids.discord
  if not ident then return false, "No identifier" end
  local expires = (durationSeconds and durationSeconds > 0) and (now() + durationSeconds) or 0
  MySQL.insert.await("INSERT INTO " .. BAN_TABLE .. " (identifier, name, reason, banned_by, expires, created_at) VALUES (?, ?, ?, ?, ?, ?)", {
    ident, getName(targetSrc), sanitize(reason, 200), bannedBy or "system", expires, now()
  })
  return true
end

-- Active players list
RegisterNetEvent("admin:getActivePlayers", function()
  local src = source
  print("[Player List] Request from src:", src)
  if not hasPermission(src, "viewPlayers") and not isGod(src) then
    print("[Player List] Permission denied for src:", src)
    return
  end
  local players = {}
  -- Include ALL players including the admin themselves
  -- Wait a moment to ensure FiveM's native GetPlayers captures correctly
  local pList = GetPlayers()
  if not pList or #pList == 0 then
      -- Fallback to QBCore functions if native fails
      local qbPlayers = QBCore.Functions.GetPlayers()
      for _, id in ipairs(qbPlayers) do
        local numId = tonumber(id)
        players[#players+1] = { id = numId, name = GetPlayerName(numId) }
      end
  else
      for _, id in ipairs(pList) do
        local numId = tonumber(id)
        players[#players+1] = { id = numId, name = GetPlayerName(numId) }
        print("[Player List] Adding player:", numId, GetPlayerName(numId))
      end
  end

  -- Add a fake dummy player if running on a local test server for testing mechanics
  if GetConvar("sv_hostname", ""):lower():find("test") or GetConvar("sv_hostname", ""):lower():find("dev") or #players <= 1 then
      players[#players+1] = { id = 999, name = "Test Dummy (Offline)" }
  end
  print("[Player List] Sending", #players, "players to src:", src)
  TriggerClientEvent("admin:receiveActivePlayers", src, players)
end)

-- Player info panel
RegisterNetEvent("admin:getPlayerInfo", function(data)
  local src = source
  local targetId = tonumber(data and data.targetId)
  local Player = getPlayerSafe(targetId)
  if not Player then return end
  local coords = GetEntityCoords(GetPlayerPed(targetId)) or vector3(0, 0, 0)
  local info = {
    name = GetPlayerName(targetId),
    ping = GetPlayerPing(targetId),
    job = Player.PlayerData.job.name,
    grade = Player.PlayerData.job.grade.level,
    money = Player.PlayerData.money["cash"] + Player.PlayerData.money["bank"],
    cash = Player.PlayerData.money["cash"],
    bank = Player.PlayerData.money["bank"],
    location = string.format("%.1f, %.1f, %.1f", coords.x, coords.y, coords.z)
  }
  -- Send to management tab
  TriggerClientEvent("admin:receivePlayerInfo", src, info)

  -- Also send to dashboard preview
  local previewInfo = {
    id = targetId,
    name = info.name,
    job = info.job .. " [" .. info.grade .. "]",
    gang = Player.PlayerData.gang and Player.PlayerData.gang.name or "None",
    cash = info.cash,
    bank = info.bank
  }
  TriggerClientEvent("admin:updatePlayerPreview", src, previewInfo)
end)

-- Inventory (ox_inventory assumed)
RegisterNetEvent("admin:getInventory", function(targetId)
  local src = source
  if not hasPermission(src, "viewInventory") then return notify(src, "No permission.") end
  local Player = getPlayerSafe(targetId); if not Player then return notify(src, "Player not online.") end
  local items = exports.ox_inventory:GetInventoryItems(tonumber(targetId)) or {}
  TriggerClientEvent("admin:openInventoryUI", src, targetId, items)
  logAdminAction(src, "viewInventory", targetId, "Viewed inventory")
end)
RegisterNetEvent("admin:removeItem", function(targetId, item, amount, silent)
  local src = source
  if not hasPermission(src, "removeItems") then return notify(src, "No permission.") end
  if not canDoAction(src, "removeItem") then return notify(src, "Slow down.") end
  local Player = getPlayerSafe(targetId); if not Player then return notify(src, "Player not online.") end
  item = sanitize(item, 64); amount = tonumber(amount) or 0; if amount <= 0 then return notify(src, "Invalid amount.") end
  local silentAllowed = isGod(src) and (silent == true)
  exports.ox_inventory:RemoveItem(tonumber(targetId), item, amount, nil, silentAllowed)
  logAdminAction(src, "removeItem", targetId, ("Removed %sx %s (silent: %s)"):format(amount, item, tostring(silentAllowed)))
end)
RegisterNetEvent("admin:addItem", function(targetId, item, amount)
  local src = source
  if not hasPermission(src, "giveItems") then return notify(src, "No permission.") end
  if not canDoAction(src, "addItem") then return notify(src, "Slow down.") end
  local Player = getPlayerSafe(targetId); if not Player then return notify(src, "Player not online.") end
  item = sanitize(item, 64); amount = tonumber(amount) or 0; if amount <= 0 then return notify(src, "Invalid amount.") end
  exports.ox_inventory:AddItem(tonumber(targetId), item, amount)
  logAdminAction(src, "addItem", targetId, ("Gave %sx %s"):format(amount, item))
end)

-- Garage
RegisterNetEvent("admin:getPlayerVehicles", function(targetId)
  local src = source
  if not hasPermission(src, "manageVehicles") then return notify(src, "No permission.") end
  local Player = getPlayerSafe(targetId); if not Player then return notify(src, "Player not online.") end
  local result = MySQL.query.await('SELECT vehicle, plate, garage, mods FROM player_vehicles WHERE citizenid = ?', { Player.PlayerData.citizenid }) or {}
  TriggerClientEvent("admin:receivePlayerVehicles", src, targetId, result)
  logAdminAction(src, "viewGarage", targetId, "Viewed garage list")
end)
RegisterNetEvent("admin:addVehicle", function(targetId, vehicleModel, plate, garage, preset)
  local src = source
  if not hasPermission(src, "manageVehicles") then return notify(src, "No permission.") end
  if not canDoAction(src, "addVehicle") then return notify(src, "Slow down.") end
  local Player = getPlayerSafe(targetId); if not Player then return notify(src, "Player not online.") end
  vehicleModel = sanitize(vehicleModel, 40); plate = sanitize(plate or "", 12); garage = sanitize(garage or "pillboxgarage", 32)
  local plateText = (plate ~= "" and plate) or string.upper(QBCore.Shared.RandomStr(3) .. QBCore.Shared.RandomInt(3))
  local mods = (Config.VehiclePresets and Config.VehiclePresets[preset or ""]) or {}
  local hash = GetHashKey(vehicleModel)
  MySQL.insert.await('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
    Player.PlayerData.license, Player.PlayerData.citizenid, vehicleModel, hash, json.encode(mods), plateText, garage, 0
  })
  notify(src, ("Added %s [%s] to %s garage"):format(vehicleModel, plateText, garage))
  logAdminAction(src, "addVehicle", targetId, ("Added %s [%s] to %s (preset: %s)"):format(vehicleModel, plateText, garage, preset or "none"))
end)
RegisterNetEvent("admin:removeVehicle", function(targetId, plate)
  local src = source
  if not hasPermission(src, "manageVehicles") then return notify(src, "No permission.") end
  if not canDoAction(src, "removeVehicle") then return notify(src, "Slow down.") end
  local Player = getPlayerSafe(targetId); if not Player then return notify(src, "Player not online.") end
  plate = sanitize(plate or "", 12); if plate == "" then return notify(src, "Invalid plate.") end
  MySQL.update.await('DELETE FROM player_vehicles WHERE citizenid = ? AND plate = ?', { Player.PlayerData.citizenid, plate })
  notify(src, ("Removed vehicle [%s]"):format(plate))
  logAdminAction(src, "removeVehicle", targetId, ("Removed vehicle with plate %s"):format(plate))
end)

-- Jobs
RegisterNetEvent("admin:getJobs", function()
  local src = source
  if not (hasPermission(src, "manageJobs") or isGod(src)) then return notify(src, "No permission.") end
  TriggerClientEvent("admin:receiveJobs", src, QBCore.Shared.Jobs)
end)
RegisterNetEvent("admin:setJob", function(targetId, job, grade)
  local src = source
  if not hasPermission(src, "manageJobs") then return notify(src, "No permission.") end
  if not canDoAction(src, "setJob") then return notify(src, "Slow down.") end
  local Player = getPlayerSafe(targetId); if not Player then return notify(src, "Player not online.") end
  job = sanitize(job, 32); grade = tonumber(grade) or 0
  if not QBCore.Shared.Jobs[job] or not QBCore.Shared.Jobs[job].grades[grade] then return notify(src, "Invalid job/grade.") end
  Player.Functions.SetJob(job, grade)
  notify(src, ("Set job to %s grade %d"):format(job, grade))
  logAdminAction(src, "setJob", targetId, ("Set job to %s grade %d"):format(job, grade))
end)
RegisterNetEvent("admin:removeJob", function(targetId)
  local src = source
  if not hasPermission(src, "manageJobs") then return notify(src, "No permission.") end
  if not canDoAction(src, "removeJob") then return notify(src, "Slow down.") end
  local Player = getPlayerSafe(targetId); if not Player then return notify(src, "Player not online.") end
  Player.Functions.SetJob("unemployed", 0)
  notify(src, "Removed job (set to unemployed).")
  logAdminAction(src, "removeJob", targetId, "Set to unemployed")
end)

-- Player actions
RegisterNetEvent("admin:warnPlayer", function(targetId, reason)
  local src = source
  if not hasPermission(src, "warnPlayers") then return notify(src, "No permission.") end
  if not canDoAction(src, "warn") then return notify(src, "Slow down.") end
  local Player = getPlayerSafe(targetId); if not Player then return notify(src, "Player not online.") end
  reason = sanitize(reason or "Admin warning issued.", 200)
  TriggerClientEvent("admin:receiveWarning", targetId, reason)
  notify(src, "Warning sent.")
  logAdminAction(src, "warn", targetId, ("Reason: %s"):format(reason))
end)
RegisterNetEvent("admin:kickPlayer", function(targetId, reason)
  local src = source
  if not hasPermission(src, "kickPlayers") then return notify(src, "No permission.") end
  if not canDoAction(src, "kick") then return notify(src, "Slow down.") end
  local Player = getPlayerSafe(targetId); if not Player then return notify(src, "Player not online.") end
  reason = sanitize(reason or "Kicked by admin.", 200)
  logAdminAction(src, "kick", targetId, ("Reason: %s"):format(reason))
  DropPlayer(tonumber(targetId), reason)
end)
RegisterNetEvent("admin:banPlayer", function(targetId, reason, durationSeconds)
  local src = source
  if not hasPermission(src, "banPlayers") then return notify(src, "No permission.") end
  if not canDoAction(src, "ban") then return notify(src, "Slow down.") end
  local Player = getPlayerSafe(targetId); if not Player then return notify(src, "Player not online.") end
  reason = sanitize(reason or "Banned by admin.", 200)
  durationSeconds = tonumber(durationSeconds) or 0
  local success, err = addBan(targetId, reason, durationSeconds, getName(src))
  if not success then return notify(src, "Ban failed: " .. (err or "?")) end
  logAdminAction(src, "ban", targetId, ("Reason: %s | Duration: %s"):format(reason, durationSeconds > 0 and (durationSeconds .. "s") or "perm"))
  DropPlayer(tonumber(targetId), reason)

end)

-- Undo last action (inventory add/remove, ban)
RegisterNetEvent("admin:undoLastAction", function()
  local src = source
  local history = adminActionHistory[src]
  if not history or #history == 0 then return notify(src, "No actions to undo.") end
  local last = history[#history]
  if last.type == "addItem" then
    local targetId = last.target
    local item, amount = last.details:match("Gave (%d+)x ([^ ]+)")
    amount = tonumber(item)
    item = last.details:match("Gave %dx ([^ ]+)")
    if targetId and item and amount then
      exports.ox_inventory:RemoveItem(tonumber(targetId), item, amount, nil, false)
      notify(src, ("Undo: Removed %dx %s from %s"):format(amount, item, targetId))
    end
  elseif last.type == "removeItem" then
    local targetId = last.target
    local item, amount = last.details:match("Removed (%d+)x ([^ ]+) ")
    amount = tonumber(item)
    item = last.details:match("Removed %dx ([^ ]+) ")
    if targetId and item and amount then
      exports.ox_inventory:AddItem(tonumber(targetId), item, amount)
      notify(src, ("Undo: Added %dx %s to %s"):format(amount, item, targetId))
    end
  elseif last.type == "ban" then
    local targetId = last.target
    local ids = getIds(targetId)
    local ident = ids.license or ids.steam or ids.discord
    if ident then
      MySQL.update.await("DELETE FROM " .. BAN_TABLE .. " WHERE identifier = ?", { ident })
      notify(src, "Undo: Ban removed for " .. (ident or "unknown"))
    end
  else
    notify(src, "Cannot undo this action type.")
  end
  table.remove(history)
  end)
RegisterNetEvent("admin:healPlayer", function(targetId)
  local src = source
  if not hasPermission(src, "healPlayers") then return notify(src, "No permission.") end
  if not canDoAction(src, "heal") then return notify(src, "Slow down.") end
  local Player = getPlayerSafe(targetId); if not Player then return notify(src, "Player not online.") end
  TriggerClientEvent("admin:_heal", targetId)
  notify(src, "Healed player.")
  logAdminAction(src, "heal", targetId, "Healed player")
end)
RegisterNetEvent("admin:killPlayer", function(targetId)
  local src = source
  if not hasPermission(src, "killPlayers") then return notify(src, "No permission.") end
  if not canDoAction(src, "kill") then return notify(src, "Slow down.") end
  local Player = getPlayerSafe(targetId); if not Player then return notify(src, "Player not online.") end
  TriggerClientEvent("admin:_kill", targetId)
  notify(src, "Killed player.")
  logAdminAction(src, "kill", targetId, "Killed player")
end)
RegisterNetEvent("admin:bringPlayer", function(targetId)
  local src = source
  if not hasPermission(src, "teleportPlayers") then return notify(src, "No permission.") end
  if not canDoAction(src, "bring") then return notify(src, "Slow down.") end
  local Player = getPlayerSafe(targetId); if not Player then return notify(src, "Player not online.") end
  local coords = GetEntityCoords(GetPlayerPed(src))
  TriggerClientEvent("admin:teleportClient", targetId, { x=coords.x, y=coords.y, z=coords.z + 0.3 })
  notify(src, "Player brought to you.")
  logAdminAction(src, "bring", targetId, ("Brought to admin at %.2f, %.2f, %.2f"):format(coords.x, coords.y, coords.z))
end)
RegisterNetEvent("admin:gotoPlayer", function(targetId)
  local src = source
  if not hasPermission(src, "teleportPlayers") then return notify(src, "No permission.") end
  if not canDoAction(src, "teleportTo") then return notify(src, "Slow down.") end
  local Player = getPlayerSafe(targetId); if not Player then return notify(src, "Player not online.") end
  local coords = GetEntityCoords(GetPlayerPed(tonumber(targetId)))
  TriggerClientEvent("admin:teleportClient", src, { x=coords.x, y=coords.y, z=coords.z + 0.3 })
  notify(src, "Teleported to player.")
  logAdminAction(src, "goto", targetId, ("Teleported to %.2f, %.2f, %.2f"):format(coords.x, coords.y, coords.z))
end)

-- Spectate / Freeze
RegisterNetEvent("admin:spectatePlayer", function(targetId)
  local src = source
  if not hasPermission(src, "spectatePlayers") then return notify(src, "No permission.") end
  local Player = getPlayerSafe(targetId); if not Player then return notify(src, "Player not online.") end
  TriggerClientEvent("admin:_spectate", src, tonumber(targetId))
  logAdminAction(src, "spectate", targetId, "Started spectating player")
end)
RegisterNetEvent("admin:freezePlayer", function(targetId)
  local src = source
  if not hasPermission(src, "freezePlayers") then return notify(src, "No permission.") end
  TriggerClientEvent("admin:_toggleFreeze", tonumber(targetId))
  logAdminAction(src, "freeze", targetId, "Toggled freeze")
end)

-- Economy
RegisterNetEvent("admin:giveMoney", function(targetId, account, amount)
  local src = source
  if not hasPermission(src, "giveMoney") then return notify(src, "No permission.") end
  if not canDoAction(src, "giveMoney") then return notify(src, "Slow down.") end
  local Player = getPlayerSafe(targetId); if not Player then return notify(src, "Player not online.") end
  account = (account == "bank") and "bank" or "cash"
  amount = math.floor(tonumber(amount) or 0)
  if amount <= 0 then return notify(src, "Invalid amount.") end
  if amount > 10000000 then return notify(src, "Amount too high.") end
  Player.Functions.AddMoney(account, amount, "admin-give")
  notify(src, ("Gave %s $%d"):format(account, amount))
  logAdminAction(src, "giveMoney", targetId, ("Gave %s $%d"):format(account, amount))
end)

-- Clothing via /pedmenu <cid> (gods only)
RegisterNetEvent("admin:giveClothing", function(targetId)
  local src = source
  if not isGod(src) then return notify(src, "Only gods can open the ped menu.") end
  local Player = getPlayerSafe(targetId)
  if not Player then return notify(src, "Player not online.") end
  local cid = Player.PlayerData.citizenid
  -- Run /pedmenu <cid> as the admin (src)
  TriggerClientEvent("chat:executeCommand", src, ("pedmenu %s"):format(cid))
  notify(src, ("Opened /pedmenu for CID %s"):format(cid))
  logAdminAction(src, "giveClothing", targetId, ("Opened /pedmenu for CID %s"):format(cid))
end)

-- Permissions editor (DB persistent)
RegisterNetEvent("admin:updatePermission", function(targetId, permKey, value)
  local src = source
  if not isGod(src) then return notify(src, "Only gods can edit permissions.") end

  local tgt = tonumber(targetId)
  local steam
  if tgt then
    local ids = getIds(tgt)
    steam = ids and ids.steam
  else
    local Player = getPlayerSafe(targetId)
    local ids = Player and getIds(targetId)
    steam = ids and ids.steam
  end
  if not steam then return notify(src, "Target not online for permission sync.") end

  Config.AdminPermissions[steam] = Config.AdminPermissions[steam] or {}
  Config.AdminPermissions[steam][permKey] = (value == true)

  if tgt then
    TriggerClientEvent("admin:refreshPermissions", tgt, Config.AdminPermissions[steam])
  end
  notify(src, "Permission updated.")
  logAdminAction(src, "updatePermission", targetId, ("Set %s to %s"):format(permKey, tostring(value)))

  savePermissionsToDB(steam, Config.AdminPermissions[steam])
end)

-- Cooldown adjustment (gods only)
RegisterNetEvent("admin:updateCooldowns", function(data)
  local src = source
  if not isGod(src) then return notify(src, "Only gods can update cooldowns.") end
  if not data or not data.cooldowns then return notify(src, "Invalid cooldown data.") end
  for k, v in pairs(data.cooldowns) do
    Config.Cooldowns[k] = tonumber(v) or Config.Cooldowns[k]
  end
  notify(src, "Cooldowns updated.")
end)

RegisterNetEvent("admin:flagCheater", function(reason)
  local src = source
  local name = GetPlayerName(src)
  local alert = { id = src, name = name, reason = sanitize(reason, 200), time = os.date("%H:%M:%S") }
  cheatAlerts[#cheatAlerts+1] = alert
  for _, id in ipairs(GetPlayers()) do
    if hasPermission(id, "viewCheatAlerts") or isGod(id) then
      TriggerClientEvent("admin:updateCheatAlerts", id, cheatAlerts)
      TriggerClientEvent("admin:notify", id, ("[AC] %s flagged: %s"):format(name, reason))
    end
  end
  logAdminAction(0, "cheatFlag", src, ("Reason: %s"):format(reason))
end)
RegisterNetEvent("admin:getCheatAlerts", function()
  local src = source
  if not (hasPermission(src, "viewCheatAlerts") or isGod(src)) then return end
  TriggerClientEvent("admin:updateCheatAlerts", src, cheatAlerts)
end)

-- Player reports
RegisterNetEvent("admin:submitReport", function(reason)
  local src = source
  local name = GetPlayerName(src)
  reportCounter = reportCounter + 1
  local report = {
    id=reportCounter, playerId=src, playerName=name, reason=sanitize(reason, 300),
    time=os.date("%H:%M:%S"), status="open", claimedBy=nil, messages={}
  }
  reports[#reports+1] = report
  for _, id in ipairs(GetPlayers()) do
    if hasPermission(id, "viewReports") or isGod(id) then
      TriggerClientEvent("admin:notify", id, ("📢 New report from %s: %s"):format(name, reason))
      TriggerClientEvent("admin:updateReports", id, reports)
    end
  end
  logAdminAction(0, "playerReport", src, ("Report: %s"):format(reason))
end)
RegisterNetEvent("admin:getReports", function()
  local src = source
  if not (hasPermission(src, "viewReports") or isGod(src)) then return end
  TriggerClientEvent("admin:updateReports", src, reports)
end)
RegisterNetEvent("admin:claimReport", function(reportId)
  local src = source
  if not (hasPermission(src, "viewReports") or isGod(src)) then return end
  for _, r in ipairs(reports) do
    if r.id == reportId and r.status == "open" then r.claimedBy = getName(src); r.status = "claimed"; break end
  end
  TriggerClientEvent("admin:updateReports", -1, reports)
  logAdminAction(src, "claimReport", nil, ("Report ID %d claimed"):format(reportId))
end)
RegisterNetEvent("admin:closeReport", function(reportId)
  local src = source
  if not (hasPermission(src, "viewReports") or isGod(src)) then return end
  for _, r in ipairs(reports) do if r.id == reportId then r.status = "closed" break end end
  TriggerClientEvent("admin:updateReports", -1, reports)
  logAdminAction(src, "closeReport", nil, ("Report ID %d closed"):format(reportId))
end)
RegisterNetEvent("admin:sendReportMessage", function(reportId, message)
  local src = source
  if not (hasPermission(src, "viewReports") or isGod(src)) then return end
  message = sanitize(message, 300)
  for _, r in ipairs(reports) do
    if r.id == reportId then
      table.insert(r.messages, { from = getName(src), text = message, time = os.date("%H:%M:%S") })
      TriggerClientEvent("chat:addMessage", r.playerId, { args = { "^1ADMIN", message } })
      break
    end
  end
  TriggerClientEvent("admin:updateReports", -1, reports)
end)

-- Admin chat
RegisterNetEvent("admin:sendAdminChat", function(message)
  local src = source
  print("[Admin Chat] Received message from src:", src, "message:", message)
  if not (hasPermission(src, "viewAdminChat") or isGod(src)) then
    print("[Admin Chat] Permission denied for src:", src)
    return
  end
  message = sanitize(message, 300)
  local entry = { sender=getName(src), time=os.date("%H:%M:%S"), text=message }
  adminChatMessages[#adminChatMessages+1] = entry
  print("[Admin Chat] Broadcasting to all admins, total messages:", #adminChatMessages)
  -- Send updated chat to ALL admins (including sender)
  for _, id in ipairs(GetPlayers()) do
    local playerId = tonumber(id)
    if hasPermission(playerId, "viewAdminChat") or isGod(playerId) then
      print("[Admin Chat] Sending to player:", playerId)
      TriggerClientEvent("admin:updateAdminChat", playerId, adminChatMessages)
    end
  end
end)

-- Server Announcements
_G.announcementHistory = _G.announcementHistory or {}
RegisterNetEvent("admin:sendAnnouncement", function(data)
  local src = source
  if not isGod(src) then return notify(src, "Only gods can send announcements.") end
  local msg = sanitize(data and data.message, 300)
  if not msg or msg == "" then return end
  local entry = { time = os.date("%H:%M:%S"), admin = getName(src), message = msg }
  table.insert(_G.announcementHistory, 1, entry)
  if #_G.announcementHistory > 50 then table.remove(_G.announcementHistory) end
  for _, id in ipairs(GetPlayers()) do
    TriggerClientEvent("chat:addMessage", id, { args = { "^3ANNOUNCEMENT", msg } })
    TriggerClientEvent("admin:updateAnnouncements", id, _G.announcementHistory)
  end
end)
RegisterNetEvent("admin:getAdminChat", function()
  local src = source
  if not (hasPermission(src, "viewAdminChat") or isGod(src)) then return end
  TriggerClientEvent("admin:updateAdminChat", src, adminChatMessages)
end)

-- Logs feed for NUI
RegisterNetEvent("admin:getLogsFeed", function()
  local src = source
  if not (hasPermission(src, "viewReports") or isGod(src)) then return end
  TriggerClientEvent("admin:updateLogsFeed", src, logsFeed)
  TriggerClientEvent("admin:updateAuditTrail", src, _G.auditTrail or {})
end)

-- Whitelist check for tattoos, skins, clothing
local function getWhitelistedItems(player_identifier)
  local rows = MySQL.query.await("SELECT item_type, item_id FROM "..WHITELIST_TABLE.." WHERE player_identifier = ?", { player_identifier })
  local whitelist = { tattoo = {}, skin = {}, clothing = {}, hair = {} }
  for _, row in ipairs(rows or {}) do
    whitelist[row.item_type][row.item_id] = true
  end
  return whitelist
end

-- Check player items against whitelist (to be called on login and item change)
function CheckPlayerWhitelist(src, tattoos, skins, clothing)
  local ids = getIds(src)
  local identifier = ids.license or ids.steam or ids.discord
  if not identifier then return end
  local whitelist = getWhitelistedItems(identifier)
  local violations = { tattoo = {}, skin = {}, clothing = {} }
  for _, t in ipairs(tattoos or {}) do
    if not whitelist.tattoo[t] then table.insert(violations.tattoo, t) end
  end
  for _, s in ipairs(skins or {}) do
    if not whitelist.skin[s] then table.insert(violations.skin, s) end
  end
  for _, c in ipairs(clothing or {}) do
    if not whitelist.clothing[c] then table.insert(violations.clothing, c) end
  end
  if #violations.tattoo > 0 or #violations.skin > 0 or #violations.clothing > 0 then
    TriggerEvent("admin:whitelistViolation", src, violations)
  end
end

-- Example: Listen for player login or item change (to be hooked into player load or clothing/tattoo/skin change events)
--[[]
AddEventHandler("playerLoaded", function(src, tattoos, skins, clothing)
  CheckPlayerWhitelist(src, tattoos, skins, clothing)
end)

RegisterNetEvent("admin:playerItemChanged", function(tattoos, skins, clothing)
  local src = source
  CheckPlayerWhitelist(src, tattoos, skins, clothing)
end)
]]

-- Violation event: alert admins and log
RegisterNetEvent("admin:whitelistViolation", function(src, violations)
  local ids = getIds(src)
  local name = GetPlayerName(src)
  local msg = ("Whitelist violation by %s (%s): "):format(name, ids.steam or "unknown")
  local details = {}
  for typ, items in pairs(violations) do
    if #items > 0 then
      details[#details+1] = ("%s: %s"):format(typ, table.concat(items, ", "))
    end
  end
  msg = msg .. table.concat(details, " | ")
  -- Log to admin log
  logAdminAction(0, "whitelistViolation", src, msg)
  -- Notify all online admins
  for _, id in ipairs(GetPlayers()) do
    if hasPermission(id, "viewPlayers") or isGod(id) then
      TriggerClientEvent("admin:notify", id, msg)
      TriggerClientEvent("admin:whitelistViolationAlert", id, { player = name, steam = ids.steam, violations = violations })
    end
  end
end)

-- Enforcement options for non-whitelisted items
function EnforceWhitelist(src, violations)
  -- Only auto-remove non-whitelisted clothing
  if violations.clothing and #violations.clothing > 0 then
    TriggerClientEvent("admin:removeNonWhitelistedClothing", src, violations.clothing)
    notify(src, "Some clothing items have been removed because they are not whitelisted.")
    logAdminAction(0, "whitelistEnforcement", src, ("Auto-removed clothing: %s"):format(json.encode(violations.clothing)))
  end
  -- Tattoos, skins, hair: permitted, no enforcement or logging
end

-- Hook enforcement into violation event
AddEventHandler("admin:whitelistViolation", function(src, violations)
  EnforceWhitelist(src, violations)
end)

-- Whitelist management endpoints
RegisterNetEvent("admin:getWhitelistItems", function(data)
  local src = source
  if not (isGod(src) or hasPermission(src, "manageWhitelist")) then return notify(src, "No permission.") end
  local targetId = tonumber(data and data.targetId)
  local Player = getPlayerSafe(targetId)
  if not Player then return notify(src, "Player not online.") end
  local ids = getIds(targetId)
  local identifier = ids.license or ids.steam or ids.discord
  if not identifier then return notify(src, "No identifier.") end
  local rows = MySQL.query.await("SELECT item_type, item_id FROM "..WHITELIST_TABLE.." WHERE player_identifier = ?", { identifier })
  local whitelist = { tattoo = {}, skin = {}, clothing = {} }
  for _, row in ipairs(rows or {}) do
    table.insert(whitelist[row.item_type], row.item_id)
  end
  TriggerClientEvent("admin:updateWhitelistItems", src, { type = "updateWhitelistItems", whitelist = whitelist })
end)

RegisterNetEvent("admin:addWhitelistItem", function(data)
  local src = source
  if not (isGod(src) or hasPermission(src, "manageWhitelist")) then return notify(src, "No permission.") end
  local targetId = tonumber(data and data.targetId)
  local itemType = data and data.itemType
  local itemId = data and data.itemId
  if not targetId or not itemType or not itemId then return notify(src, "Missing data.") end
  local Player = getPlayerSafe(targetId)
  if not Player then return notify(src, "Player not online.") end
  local ids = getIds(targetId)
  local identifier = ids.license or ids.steam or ids.discord
  if not identifier then return notify(src, "No identifier.") end
  MySQL.insert.await("INSERT INTO "..WHITELIST_TABLE.." (player_identifier, item_type, item_id, granted_by) VALUES (?, ?, ?, ?)", { identifier, itemType, itemId, src })
  logAdminAction(src, "addWhitelistItem", targetId, ("Whitelisted %s '%s'"):format(itemType, itemId))
  notify(src, ("Whitelisted %s '%s' for player."):format(itemType, itemId))
  TriggerClientEvent("admin:notify", targetId, ("You have been whitelisted for %s: %s"):format(itemType, itemId))
end)

RegisterNetEvent("admin:removeWhitelistItem", function(data)
  local src = source
  if not (isGod(src) or hasPermission(src, "manageWhitelist")) then return notify(src, "No permission.") end
  local targetId = tonumber(data and data.targetId)
  local itemType = data and data.itemType
  local itemId = data and data.itemId
  if not targetId or not itemType or not itemId then return notify(src, "Missing data.") end
  local Player = getPlayerSafe(targetId)
  if not Player then return notify(src, "Player not online.") end
  local ids = getIds(targetId)
  local identifier = ids.license or ids.steam or ids.discord
  if not identifier then return notify(src, "No identifier.") end
  MySQL.query.await("DELETE FROM "..WHITELIST_TABLE.." WHERE player_identifier = ? AND item_type = ? AND item_id = ?", { identifier, itemType, itemId })
  logAdminAction(src, "removeWhitelistItem", targetId, ("Removed whitelist for %s '%s'"):format(itemType, itemId))
  notify(src, ("Removed whitelist for %s '%s'."):format(itemType, itemId))
  TriggerClientEvent("admin:notify", targetId, ("Whitelist removed for %s: %s"):format(itemType, itemId))
end)

-- Notify player when wearing a whitelisted item
function NotifyPlayerWhitelistedItem(src, itemType, itemId)
  TriggerClientEvent("admin:notify", src, ("You are wearing a whitelisted %s: %s"):format(itemType, itemId))
end
