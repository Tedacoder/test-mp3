if not IsDuplicityVersion() then
    -- CLIENT SIDE
    local spectateCam = nil
    local spectatingPlayer = nil

    RegisterNetEvent("adminpanel:client:startSpectate", function(targetId, targetCoords)
        local target = GetPlayerFromServerId(targetId)
        local targetPed = GetPlayerPed(target)

        if not targetPed or targetPed == 0 or not DoesEntityExist(targetPed) then
            -- Use coords if ped isn't loaded (OneSync scope issue)
            if targetCoords then
                SetEntityCoords(PlayerPedId(), targetCoords.x, targetCoords.y, targetCoords.z + 50.0, false, false, false, false)
                Wait(500)
                target = GetPlayerFromServerId(targetId)
                targetPed = GetPlayerPed(target)
            else
                lib.notify({ title = "Error", description = "Player not found or out of scope.", type = "error" })
                return
            end
        end

        local playerPed = PlayerPedId()

        if spectatingPlayer == targetId then return end

        if not spectateCam then
            spectateCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        end

        local oldCam = spectateCam
        local newCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)

        local offset = GetOffsetFromEntityInWorldCoords(targetPed, 0.0, -3.0, 1.0)
        SetCamCoord(newCam, offset.x, offset.y, offset.z)
        PointCamAtEntity(newCam, targetPed, 0, 0, 0, true)
        AttachCamToEntity(newCam, targetPed, 0.0, -3.0, 1.0, true)

        if spectatingPlayer then
            SetCamActiveWithInterp(newCam, oldCam, 1500, 1, 1)
            Wait(1500)
            DestroyCam(oldCam, false)
        else
            SetCamActive(newCam, true)
            RenderScriptCams(true, false, 0, true, true)
        end

        spectateCam = newCam
        spectatingPlayer = targetId
        NetworkSetInSpectatorMode(true, targetPed)

        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(true)
        SetNuiFocusKeepInput(true) -- Enable cursor for 3D ESP
        SetNuiFocusKeepInput(true)

        lib.notify({ title = 'Spectating', description = 'Spectating ID: ' .. targetId .. '. Right click to free cursor, click players for ESP. F3 to stop.', type = 'success' })



        CreateThread(function()
            while spectatingPlayer do
                Wait(0)
                if IsControlJustPressed(0, 177) or IsControlJustPressed(0, 200) then -- ESC or Right Click
                    SetNuiFocus(false, false)
                                    end

                -- Raycast on Click
                if IsControlJustPressed(0, 24) then -- Left Click
                    local hit, entity = RayCastCamera(100.0, spectateCam)
                    if hit and IsEntityAPed(entity) and IsPedAPlayer(entity) then
                        local hitPlayer = NetworkGetPlayerIndexFromPed(entity)
                        local hitServerId = GetPlayerServerId(hitPlayer)
                        if hitServerId and hitServerId > 0 then
                            ShowAdminContextMenu(hitServerId)
                        end
                    end
                end
            end
        end)
    end)

    RegisterNetEvent("adminpanel:client:stopSpectate", function()
        if spectatingPlayer then
            NetworkSetInSpectatorMode(false, 0)
            RenderScriptCams(false, true, 1000, true, true)
            if spectateCam then DestroyCam(spectateCam, false) end
            spectateCam = nil
            spectatingPlayer = nil
            SetNuiFocus(false, false)
                                lib.notify({ title = 'Spectating', description = 'Spectate stopped.', type = 'inform' })
        end
    end)

    RegisterCommand("stopspec", function()
        TriggerEvent("adminpanel:client:stopSpectate")
    end)
    RegisterKeyMapping("stopspec", "Stop Spectating", "keyboard", "F3")


    function ShowAdminContextMenu(targetId)
        lib.registerContext({
            id = 'admin_esp_menu_' .. targetId,
            title = 'Admin Actions (ID: ' .. targetId .. ')',
            options = {
                {
                    title = 'View Inventory',
                    icon = 'box-open',
                    onSelect = function()
                        ExecuteCommand('admin')
                        Wait(500)
                        SendNUIMessage({ type = "toast", message = "Select View Inventory in Player Actions!" })
                    end
                },
                {
                    title = 'Freeze / Unfreeze',
                    icon = 'snowflake',
                    serverEvent = 'admin:freezePlayer',
                    args = targetId
                },
                {
                    title = 'Heal',
                    icon = 'heart',
                    serverEvent = 'admin:healPlayer',
                    args = targetId
                },
                {
                    title = 'Warn',
                    icon = 'exclamation-triangle',
                    onSelect = function()
                        local input = lib.inputDialog('Warn Player', {'Reason'})
                        if input and input[1] then
                            TriggerServerEvent('admin:warnPlayer', targetId, input[1])
                        end
                    end
                },
                {
                    title = 'Kick',
                    icon = 'user-slash',
                    onSelect = function()
                        local input = lib.inputDialog('Kick Player', {'Reason'})
                        if input and input[1] then
                            TriggerServerEvent('admin:kickPlayer', targetId, input[1])
                        end
                    end
                },
                {
                    title = 'Ban',
                    icon = 'gavel',
                    onSelect = function()
                        local input = lib.inputDialog('Ban Player', {'Reason', 'Duration (seconds)'})
                        if input and input[1] then
                            TriggerServerEvent('admin:banPlayer', targetId, input[1], tonumber(input[2]) or 0)
                        end
                    end
                }
            }
        })
        lib.showContext('admin_esp_menu_' .. targetId)
    end

    function RayCastCamera(distance)
        local cursorX, cursorY = GetNuiCursorPosition()
        local resX, resY = GetActiveScreenResolution()

        -- Fallback to center screen if no cursor
        if not cursorX or cursorX == 0 then
            cursorX, cursorY = resX / 2, resY / 2
        end

        local rx = (cursorX / resX) * 2.0 - 1.0
        local ry = (cursorY / resY) * 2.0 - 1.0

        local camRot = GetCamRot(spectateCam, 2)
        local camPos = GetCamCoord(spectateCam)
        local fwd = RotationToDirection(camRot)

        -- Simplified projection (assumes roughly 90 FOV)
        local right = RotationToDirection(camRot - vector3(0, 0, 90))
        local up = RotationToDirection(camRot + vector3(90, 0, 0))

        local rayDir = fwd + (right * rx) - (up * ry)

        local destination = camPos + (rayDir * distance)
        local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(camPos.x, camPos.y, camPos.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
        return b == 1, e
    end

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
end
