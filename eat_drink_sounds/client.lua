-- Keep track of players that are currently playing a sound to avoid spamming
local activeSounds = {}

-- List of known eating and drinking animations in GTA V
-- These format as {dictionary, animation_name, type}
local animations = {
    -- Eating
    {"mp_player_inteat@burger", "mp_player_int_eat_burger_fp", "eat"},
    {"mp_player_inteat@burger", "mp_player_int_eat_burger", "eat"},
    {"mp_player_inteat@candy", "mp_player_int_eat_candy_fp", "eat"},
    {"mp_player_inteat@candy", "mp_player_int_eat_candy", "eat"},
    {"mp_player_inteat@hotdog", "mp_player_int_eat_hotdog_fp", "eat"},
    {"mp_player_inteat@hotdog", "mp_player_int_eat_hotdog", "eat"},
    -- Drinking
    {"mp_player_intdrink", "loop_bottle", "drink"},
    {"mp_player_intdrink", "loop_can", "drink"},
    {"amb@world_human_drinking@coffee@male@idle_a", "idle_c", "drink"},
    {"amb@world_human_drinking@coffee@female@idle_a", "idle_c", "drink"},
    {"amb@world_human_drinking@beer@male@idle_a", "idle_a", "drink"},
    {"amb@world_human_drinking@beer@female@idle_a", "idle_a", "drink"}
}

-- How far away we should hear the sound
local maxDistance = 15.0

CreateThread(function()
    while true do
        Wait(500) -- Check twice a second

        local localPed = PlayerPedId()
        local localCoords = GetEntityCoords(localPed)

        -- Get all players
        for _, player in ipairs(GetActivePlayers()) do
            local playerPed = GetPlayerPed(player)

            if DoesEntityExist(playerPed) and not IsEntityDead(playerPed) then
                local playerCoords = GetEntityCoords(playerPed)
                local distance = #(localCoords - playerCoords)

                -- Only check if they are close enough
                if distance <= maxDistance then
                    local foundAnim = false
                    local animType = nil

                    for i = 1, #animations do
                        local dict = animations[i][1]
                        local anim = animations[i][2]
                        local type = animations[i][3]

                        if IsEntityPlayingAnim(playerPed, dict, anim, 3) then
                            foundAnim = true
                            animType = type
                            break
                        end
                    end

                    local playerId = GetPlayerServerId(player)

                    if foundAnim and not activeSounds[playerId] then
                        activeSounds[playerId] = true

                        -- Calculate 3D audio volume/pan based on distance and relative position
                        -- Since we are doing this locally, we can just pass the distance to NUI
                        -- Or better yet, pass the coords and let NUI do panning, but NUI Audio API is simpler with just volume based on distance for now.
                        -- Actually, a simple volume dropoff is fine for an MVP without needing Howler.js or similar.
                        local volume = 1.0 - (distance / maxDistance)
                        if volume < 0.0 then volume = 0.0 end
                        if volume > 1.0 then volume = 1.0 end

                        -- Tell NUI to play the sound
                        SendNUIMessage({
                            type = "playSound",
                            soundType = animType,
                            volume = volume
                        })

                        -- Prevent playing sound too often for this specific player
                        SetTimeout(3000, function()
                            activeSounds[playerId] = false
                        end)
                    end
                end
            end
        end
    end
end)
