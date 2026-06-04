-- Wrapper for RegisterNUICallback
local function nui(event, func)
  RegisterNUICallback(event, function(data, cb)
    func(data, cb)
    if cb then cb('ok') end
  end)
end

local menuOpen = false

-- Shared toggle
local function toggleAdminMenu()
  if menuOpen then
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closePanel" })
    return
  end

  -- Check permission before opening
  local canOpen = lib.callback.await('admin:canOpenPanel', false)
  if not canOpen then
      SendNUIMessage({ type = "toast", message = "You do not have permission to open the admin panel." })
      return
  end

  menuOpen = true
  SetNuiFocus(true, true)
  SetNuiFocusKeepInput(false)
  SendNUIMessage({
      action = "openPanel",
      title = Config.PanelTitle or "Admin Panel"
  })
  TriggerServerEvent("admin:getActivePlayers")
  TriggerServerEvent("admin:getJobs")
  TriggerServerEvent("admin:getCheatAlerts")
  TriggerServerEvent("admin:getReports")
  TriggerServerEvent("admin:getAdminChat")
  TriggerServerEvent("admin:getLogsFeed")
end

RegisterCommand("toggleadmin", toggleAdminMenu)
RegisterKeyMapping("toggleadmin", "Toggle Admin Menu", "keyboard", "F10")
RegisterCommand("admin", toggleAdminMenu)

-- Emergency escape command to release NUI focus
RegisterCommand("adminfix", function()
  SetNuiFocus(false, false)
  menuOpen = false
  SendNUIMessage({ action = "closePanel" })
  print("^2[Admin Panel] NUI focus released!^0")
end)

-- ESC key handler
-- ESC key handler & control disabling
CreateThread(function()
  while true do
    Wait(0)
    if menuOpen then
      DisableControlAction(0, 322, true) -- ESC
      DisableControlAction(0, 200, true) -- ESC alternative
      DisableControlAction(0, 1, true) -- Mouse Pan
      DisableControlAction(0, 2, true) -- Mouse Tilt
      DisableControlAction(0, 24, true) -- Attack
      DisableControlAction(0, 25, true) -- Aim
      DisableControlAction(0, 30, true) -- Move L/R
      DisableControlAction(0, 31, true) -- Move U/D
      DisableControlAction(0, 32, true) -- W
      DisableControlAction(0, 33, true) -- S
      DisableControlAction(0, 34, true) -- A
      DisableControlAction(0, 35, true) -- D
      DisableControlAction(0, 288, true) -- F1
      DisableControlAction(0, 289, true) -- F2
      if IsDisabledControlJustPressed(0, 322) or IsDisabledControlJustPressed(0, 200) then
        toggleAdminMenu()
      end
    end
  end
end)

-- Reusable confirmation wrapper
local function confirmAction(text, callback, data)
  SendNUIMessage({
    action = "showConfirm",
    text = text,
    callback = callback,
    data = data
  })
end

-- NUI callbacks → execute actions directly (confirmation handled in UI)
nui("banPlayer", function(d) TriggerServerEvent("admin:banPlayer", d.targetId, d.reason, d.duration) end)
nui("kickPlayer", function(d) TriggerServerEvent("admin:kickPlayer", d.targetId, d.reason) end)
nui("warnPlayer", function(d) TriggerServerEvent("admin:warnPlayer", d.targetId, d.reason) end)
nui("removeItem", function(d) TriggerServerEvent("admin:removeItem", d.targetId, d.item, d.amount, d.silent, d.slot, d.metadata) end)
nui("removeVehicle", function(d) TriggerServerEvent("admin:removeVehicle", d.targetId, d.plate) end)
nui("freezePlayer", function(d) TriggerServerEvent("admin:freezePlayer", d.targetId) end)

-- Other direct actions (no confirmation needed)
nui("getActivePlayers", function() TriggerServerEvent("admin:getActivePlayers") end)
nui("getJobs", function() TriggerServerEvent("admin:getJobs") end)
nui("getPlayerInfo", function(d) TriggerServerEvent("admin:getPlayerInfo", d) end)
nui("getInventory", function(d)
    if GetResourceState('ox_lib') == 'started' then
        lib.callback('adminpanel:server:getInventory', false, function(items)
            SendNUIMessage({ type = "updateInventory", targetId = d.targetId, items = items })
        end, d.targetId)
    else
        TriggerServerEvent("admin:getInventory", d.targetId)
    end
end)
nui("addItem", function(d) TriggerServerEvent("admin:addItem", d.targetId, d.item, d.amount) end)
nui("addVehicle", function(d) TriggerServerEvent("admin:addVehicle", d.targetId, d.vehicleModel, d.plate, d.garage, d.preset) end)
nui("giveMoney", function(d) TriggerServerEvent("admin:giveMoney", d.targetId, d.account, d.amount) end)
nui("giveClothing", function(d) TriggerServerEvent("admin:giveClothing", d.targetId) end)
nui("setJob", function(d) TriggerServerEvent("admin:setJob", d.targetId, d.job, d.grade) end)
nui("removeJob", function(d) TriggerServerEvent("admin:removeJob", d.targetId) end)
nui("updatePermission", function(d) TriggerServerEvent("admin:updatePermission", d.targetId, d.permKey, d.value) end)
nui("resolveReport", function(d) TriggerServerEvent("admin:closeReport", d.reportId) end)
nui("claimReport", function(d) TriggerServerEvent("admin:claimReport", d.reportId) end)
nui("sendReportMessage", function(d) TriggerServerEvent("admin:sendReportMessage", d.reportId, d.message) end)
nui("sendAdminChat", function(d) TriggerServerEvent("admin:sendAdminChat", d.message) end)
nui("gotoPlayer", function(d) TriggerServerEvent("admin:gotoPlayer", d.targetId) end)
nui("bringPlayer", function(d) TriggerServerEvent("admin:bringPlayer", d.targetId) end)
nui("spectatePlayer", function(d) TriggerServerEvent("admin:spectatePlayer", d.targetId) end)
nui("healPlayer", function(d) TriggerServerEvent("admin:healPlayer", d.targetId) end)
nui("killPlayer", function(d) TriggerServerEvent("admin:killPlayer", d.targetId) end)
nui("bulkAction", function(d) TriggerServerEvent("admin:bulkAction", d) end)

-- Missing mappings from review
nui("admin:undoLastAction", function(d) TriggerServerEvent("admin:undoLastAction") end)
nui("admin:updateCooldowns", function(d) TriggerServerEvent("admin:updateCooldowns", d) end)
nui("admin:getCooldowns", function(d) TriggerServerEvent("admin:getCooldowns") end)
nui("getPermissions", function(d) TriggerServerEvent("admin:getPermissions", d.targetId) end)
nui("admin:getWhitelistItems", function(d) TriggerServerEvent("admin:getWhitelistItems", d) end)
nui("admin:addWhitelistItem", function(d) TriggerServerEvent("admin:addWhitelistItem", d) end)
nui("admin:removeWhitelistItem", function(d) TriggerServerEvent("admin:removeWhitelistItem", d) end)
nui("sendAnnouncement", function(d) TriggerServerEvent("admin:sendAnnouncement", d) end)

-- Close panel
nui("copyToClipboard", function(d) TriggerEvent("adminpanel:client:copyToClipboard", d.text) end)

nui("closeMenu", function(data, cb)
  SetNuiFocus(false, false)
  menuOpen = false
  SendNUIMessage({ action = "closePanel" })
end)

-- Server → UI updates
RegisterNetEvent("admin:notify", function(msg) SendNUIMessage({ type = "toast", message = msg }) end)
RegisterNetEvent("admin:receiveActivePlayers", function(players) SendNUIMessage({ type = "updatePlayerList", players = players }) end)
RegisterNetEvent("admin:openInventoryUI", function(targetId, items) SendNUIMessage({ type = "updateInventory", targetId = targetId, items = items }) end)
RegisterNetEvent("admin:receivePlayerVehicles", function(targetId, vehicles) SendNUIMessage({ type = "updateGarage", targetId = targetId, vehicles = vehicles }) end)
RegisterNetEvent("admin:receiveJobs", function(jobs) SendNUIMessage({ type = "jobsList", jobs = jobs }) end)
RegisterNetEvent("admin:receivePlayerInfo", function(info)
    if GetInGamePlayerMugshot then
        info.avatarUrl = GetInGamePlayerMugshot(info.id or info.source)
    end
    SendNUIMessage({ type = "playerInfo", info = info })
end)
RegisterNetEvent("admin:updateCheatAlerts", function(alerts) SendNUIMessage({ type = "updateCheatAlerts", alerts = alerts }) end)
RegisterNetEvent("admin:updateReports", function(reports) SendNUIMessage({ type = "updateReports", reports = reports }) end)
RegisterNetEvent("admin:updateAdminChat", function(messages) SendNUIMessage({ type = "updateAdminChat", messages = messages }) end)
RegisterNetEvent("admin:updateLogsFeed", function(lines) SendNUIMessage({ type = "updateLogsFeed", lines = lines }) end)
RegisterNetEvent("admin:updateAuditTrail", function(trail) SendNUIMessage({ type = "updateAuditTrail", trail = trail }) end)
RegisterNetEvent("admin:refreshPermissions", function(perms) SendNUIMessage({ type = "refreshPermissions", perms = perms }) end)
RegisterNetEvent("admin:updatePermissions", function(perms) SendNUIMessage({ type = "updatePermissions", permissions = perms }) end)
RegisterNetEvent("admin:updateCooldownsUI", function(cds) SendNUIMessage({ type = "updateCooldownsUI", cooldowns = cds }) end)
RegisterNetEvent("admin:updateAnnouncements", function(announcements) SendNUIMessage({ type = "updateAnnouncements", announcements = announcements }) end)
RegisterNetEvent("admin:showAnnouncement", function(msg) SendNUIMessage({ type = "showAnnouncement", message = msg }) end)
RegisterNetEvent("admin:updateWhitelistItems", function(data) SendNUIMessage(data) end)
RegisterNetEvent("admin:updatePlayerPreview", function(info)
    if GetInGamePlayerMugshot then
        info.avatarUrl = GetInGamePlayerMugshot(info.id)
    end
    SendNUIMessage({ type = "updatePlayerPreview", info = info })
end)

-- Player-side effects
RegisterNetEvent("admin:receiveWarning", function(text)
  SendNUIMessage({ type = "warning", text = text })
end)

RegisterNetEvent("admin:_heal", function()
  local ped = PlayerPedId()
  SetEntityHealth(ped, 200)
  AddArmourToPed(ped, 100)
end)

RegisterNetEvent("admin:_kill", function()
  local ped = PlayerPedId()
  SetEntityHealth(ped, 0)
end)

RegisterNetEvent("admin:teleportClient", function(coords)
  SetEntityCoords(PlayerPedId(), coords.x + 0.0, coords.y + 0.0, coords.z + 0.0, false, false, false, true)
end)



-- Freeze toggle (used in confirmation flow)
local frozen = false
RegisterNetEvent("admin:_toggleFreeze", function()
  local ped = PlayerPedId()
  frozen = not frozen
  FreezeEntityPosition(ped, frozen)
  SetEntityInvincible(ped, frozen)
end)

-- Developer Tools
local noclipActive = false
local godModeActive = false
local invisibleActive = false
local entityInspectorActive = false

-- Get coordinates
nui("getCoords", function()
  local ped = PlayerPedId()
  local coords = GetEntityCoords(ped)
  local heading = GetEntityHeading(ped)
  SendNUIMessage({
    type = "updateCoords",
    vector = string.format("vector3(%.2f, %.2f, %.2f)", coords.x, coords.y, coords.z),
    heading = string.format("%.2f", heading)
  })
end)

-- Entity Inspector
nui("toggleEntityInspector", function(d)
  entityInspectorActive = d.active
end)

CreateThread(function()
  while true do
    Wait(100)
    if entityInspectorActive then
      if IsControlJustPressed(0, 24) then -- Left click
        local entity = GetEntityPlayerIsFreeAimingAt(PlayerId())
        if entity and DoesEntityExist(entity) then
          inspectEntity(entity)
        end
      end
    end
  end
end)

function GetEntityPlayerIsFreeAimingAt(player)
  local entity = nil
  local ped = GetPlayerPed(player)
  if IsPlayerFreeAiming(player) then
    local hit, coords, surfaceNormal, entityHit = GetShapeTestResult(StartShapeTestRay(
      GetFinalRenderedCamCoord(),
      GetCoordsFromCam(1000.0),
      -1,
      ped,
      7
    ))
    if hit and entityHit and DoesEntityExist(entityHit) then
      entity = entityHit
    end
  end
  return entity
end

function GetCoordsFromCam(distance)
  local rot = GetGameplayCamRot(2)
  local coord = GetGameplayCamCoord()
  local x = coord.x - math.sin(math.rad(rot.z)) * distance * math.abs(math.cos(math.rad(rot.x)))
  local y = coord.y + math.cos(math.rad(rot.z)) * distance * math.abs(math.cos(math.rad(rot.x)))
  local z = coord.z - math.sin(math.rad(rot.x)) * distance
  return vector3(x, y, z)
end

function inspectEntity(entity)
  local entityType = GetEntityType(entity)
  local typeStr = "Unknown"
  if entityType == 1 then typeStr = "Ped"
  elseif entityType == 2 then typeStr = "Vehicle"
  elseif entityType == 3 then typeStr = "Object" end

  local model = GetEntityModel(entity)
  local coords = GetEntityCoords(entity)
  local heading = GetEntityHeading(entity)
  local health = GetEntityHealth(entity)
  local maxHealth = GetEntityMaxHealth(entity)
  local netId = NetworkGetNetworkIdFromEntity(entity)

  local info = {
    type = typeStr,
    entity = entity,
    model = GetHashKey(model),
    modelHash = model,
    coords = {x = math.floor(coords.x * 100) / 100, y = math.floor(coords.y * 100) / 100, z = math.floor(coords.z * 100) / 100},
    heading = math.floor(heading * 100) / 100,
    health = health,
    maxHealth = maxHealth,
    netId = netId
  }

  if entityType == 2 then -- Vehicle
    info.plate = GetVehicleNumberPlateText(entity)
    info.speed = math.floor(GetEntitySpeed(entity) * 2.236936)
  end

  if entityType == 1 then -- Ped
    info.isPlayer = IsPedAPlayer(entity)
  end

  SendNUIMessage({
    type = "updateEntityInfo",
    info = info
  })
end

nui("inspectClosestEntity", function()
  local ped = PlayerPedId()
  local coords = GetEntityCoords(ped)
  local entity = GetClosestObjectOfType(coords.x, coords.y, coords.z, 10.0, 0, false, false, false)
  if not entity or entity == 0 then
    entity = GetClosestVehicle(coords.x, coords.y, coords.z, 10.0, 0, 71)
  end
  if entity and entity ~= 0 and DoesEntityExist(entity) then
    inspectEntity(entity)
  else
    SendNUIMessage({ type = "toast", message = "No entity found nearby" })
  end
end)

-- Decor Detection
local commonDecors = {
  "lsv_plr_veh", "Player_Vehicle", "veh_modded_by_bennys", "MPBitset",
  "CreatedByPegasus", "PegasusVehicle", "IgnoredByQuickSave", "PlayerVehicle",
  "NPCLUA_DECOR", "IsElectrifiedVehicle", "Vehicle_ModdedBy_Player",
  "Vehicle_Clamp", "lsv_plr_veh_owned", "HAS_WANTED_DECOR"
}

nui("detectDecors", function(d)
  local entity = nil
  local ped = PlayerPedId()

  if d.target == "aimed" then
    entity = GetEntityPlayerIsFreeAimingAt(PlayerId())
  elseif d.target == "self" then
    entity = ped
  elseif d.target == "vehicle" then
    entity = GetVehiclePedIsIn(ped, false)
  end

  if not entity or not DoesEntityExist(entity) then
    SendNUIMessage({ type = "toast", message = "No valid entity found" })
    return
  end

  local decors = {}
  for _, decorName in ipairs(commonDecors) do
    if DecorExistOn(entity, decorName) then
      local decorType = DecorGetType(entity, decorName)
      local value = "N/A"
      local typeStr = "Unknown"

      if decorType == 1 then -- Float
        value = tostring(DecorGetFloat(entity, decorName))
        typeStr = "Float"
      elseif decorType == 2 then -- Bool
        value = tostring(DecorGetBool(entity, decorName))
        typeStr = "Bool"
      elseif decorType == 3 then -- Int
        value = tostring(DecorGetInt(entity, decorName))
        typeStr = "Int"
      elseif decorType == 4 then -- String (not directly accessible)
        typeStr = "String"
        value = "<string>"
      end

      table.insert(decors, {
        name = decorName,
        type = typeStr,
        value = value
      })
    end
  end

  SendNUIMessage({
    type = "updateDecorInfo",
    decors = decors
  })
end)

-- Noclip
nui("toggleNoclip", function()
  noclipActive = not noclipActive
  local ped = PlayerPedId()
  SetEntityVisible(ped, not noclipActive, 0)
  SetEntityInvincible(ped, noclipActive)
  SetEntityCollision(ped, not noclipActive, not noclipActive)
  FreezeEntityPosition(ped, noclipActive)
  if not noclipActive then
      SetEntityVelocity(ped, 0.0, 0.0, 0.0)
      ClearPedTasksImmediately(ped)
      local coords = GetEntityCoords(ped)
      local hasGround, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, true)
      if hasGround then
          SetEntityCoords(ped, coords.x, coords.y, groundZ, false, false, false, false)
      else
          SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
      end
      -- Grant a brief grace period of invincibility to prevent fall damage on exit
      SetEntityInvincible(ped, true)
      SetTimeout(2000, function()
          SetEntityInvincible(ped, false)
      end)
  end
  SendNUIMessage({ type = "toast", message = noclipActive and "Noclip enabled" or "Noclip disabled" })

  CreateThread(function()
    while noclipActive do
      Wait(0)
      local coords = GetEntityCoords(ped)
      local heading = GetEntityHeading(ped)
      local speed = 1.0
      if IsControlPressed(0, 21) then speed = 5.0 end -- Shift

      if IsControlPressed(0, 32) then coords = coords + GetEntityForwardVector(ped) * speed end -- W
      if IsControlPressed(0, 33) then coords = coords - GetEntityForwardVector(ped) * speed end -- S
      if IsControlPressed(0, 34) then heading = heading - 2.0 end -- A
      if IsControlPressed(0, 35) then heading = heading + 2.0 end -- D
      if IsControlPressed(0, 44) then coords = coords - vector3(0, 0, speed) end -- Q
      if IsControlPressed(0, 38) then coords = coords + vector3(0, 0, speed) end -- E

      SetEntityCoords(ped, coords.x, coords.y, coords.z, true, true, true, false)
      SetEntityHeading(ped, heading)
    end
    SetEntityVisible(ped, true, 0)
  end)
end)

-- God Mode
nui("toggleGodMode", function()
  godModeActive = not godModeActive
  local ped = PlayerPedId()
  SetEntityInvincible(ped, godModeActive)
  SetPlayerInvincible(PlayerId(), godModeActive)
  SendNUIMessage({ type = "toast", message = godModeActive and "God mode enabled" or "God mode disabled" })
end)

-- Invisible
nui("toggleInvisible", function()
  invisibleActive = not invisibleActive
  local ped = PlayerPedId()
  SetEntityVisible(ped, not invisibleActive, 0)
  SendNUIMessage({ type = "toast", message = invisibleActive and "Invisible enabled" or "Invisible disabled" })
end)

-- Fix Vehicle
nui("fixVehicle", function()
  local ped = PlayerPedId()
  local veh = GetVehiclePedIsIn(ped, false)
  if veh and veh ~= 0 then
    SetVehicleFixed(veh)

    -- Using the memory about FiveM vehicle repair limitations to properly repair everything
    for i = 0, 7 do
      FixVehicleWindow(veh, i)
    end
    for i = 0, 5 do
      SetVehicleTyreFixed(veh, i)
    end

    SetVehicleDeformationFixed(veh)
    SetVehicleUndriveable(veh, false)
    SetVehicleEngineOn(veh, true, true)
    SendNUIMessage({ type = "toast", message = "Vehicle fixed!" })
  else
    SendNUIMessage({ type = "toast", message = "You're not in a vehicle" })
  end
end)

-- Delete Aimed Entity
nui("deleteAimedEntity", function()
  local entity = GetEntityPlayerIsFreeAimingAt(PlayerId())
  if entity and DoesEntityExist(entity) then
    SetEntityAsMissionEntity(entity, true, true)
    DeleteEntity(entity)
    SendNUIMessage({ type = "toast", message = "Entity deleted!" })
  else
    SendNUIMessage({ type = "toast", message = "No entity aimed at" })
  end
end)

-- Spawn Vehicle
nui("spawnVehicleAtCoords", function(d)
  local model = GetHashKey(d.model)
  RequestModel(model)
  while not HasModelLoaded(model) do
    Wait(10)
  end
  local ped = PlayerPedId()
  local coords = GetEntityCoords(ped)
  local heading = GetEntityHeading(ped)
  local veh = CreateVehicle(model, coords.x, coords.y, coords.z, heading, true, false)
  SetPedIntoVehicle(ped, veh, -1)
  SetModelAsNoLongerNeeded(model)
  SendNUIMessage({ type = "toast", message = "Vehicle spawned!" })
end)

RegisterNUICallback('requestCoordCopy', function(data, cb)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    local outputString = ""

    if data.format == "vector3" then
        outputString = string.format("vec3(%.2f, %.2f, %.2f)", coords.x, coords.y, coords.z)
    elseif data.format == "vector4" then
        outputString = string.format("vec4(%.2f, %.2f, %.2f, %.2f)", coords.x, coords.y, coords.z, heading)
    elseif data.format == "table" then
        outputString = string.format("{x = %.2f, y = %.2f, z = %.2f, h = %.2f}", coords.x, coords.y, coords.z, heading)
    end

    if GetResourceState('ox_lib') == 'started' then
        lib.setClipboard(outputString)
        lib.notify({
            title = 'Developer Tools',
            description = 'Formatted coordinates copied to clipboard!',
            type = 'success'
        })
    else
        print(("^2[CLIPBOARD FALLBACK]^7 Copied Coords: %s"):format(outputString))
        SendNUIMessage({ type = "toast", message = "Coords copied (Check F8 Console)" })
    end

    cb({ status = true })
end)

function RotationToDirection(rotation)
    local adjustedRotation = vector3(
        (math.pi / 180) * rotation.x,
        (math.pi / 180) * rotation.y,
        (math.pi / 180) * rotation.z
    )
    local direction = vector3(
        -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.sin(adjustedRotation.x)
    )
    return direction
end
