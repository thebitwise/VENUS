--$$\        $$$$$$\  $$\   $$\  $$$$$$\  $$$$$$$$\ 
--$$ |      $$  __$$\ $$$\  $$ |$$  __$$\ $$  _____|
--$$ |      $$ /  $$ |$$$$\ $$ |$$ /  \__|$$ |      
--$$ |      $$$$$$$$ |$$ $$\$$ |$$ |      $$$$$\    
--$$ |      $$  __$$ |$$ \$$$$ |$$ |      $$  __|   
--$$ |      $$ |  $$ |$$ |\$$$ |$$ |  $$\ $$ |      
--$$$$$$$$\ $$ |  $$ |$$ | \$$ |\$$$$$$  |$$$$$$$$\ 
--\________|\__|  \__|\__|  \__| \______/ \________|
-- coded by Lance/stonerchrist on Discord

util.require_natives("2944a", "g")

local root = menu.my_root()

local venus_info = true
local venus_bone = 31086
local venus_paint = true
local venus_targetnpcs = false  
local venus_targetplayers = true
local venus_targetfriends = false
local venus_showtarget = true
local venus_usefov = true
local venus_fov = 5
local venus = false
local venus_internalmode = "closest"
local venus_sneak_bullets = 1

local temp_ptr = memory.alloc(13*8)
local function pid_to_handle(pid)
    NETWORK_HANDLE_FROM_PLAYER(pid, temp_ptr, 13)
    return temp_ptr
end

local function get_aimbot_target()
    local dist = 1000000000
    local cur_tar = 0
    for k,v in pairs(entities.get_all_peds_as_handles()) do
        local target_this = true
        local player_pos = players.get_position(players.user())
        local ped_pos = GET_ENTITY_COORDS(v, true)
        local this_dist = GET_DISTANCE_BETWEEN_COORDS(player_pos['x'], player_pos['y'], player_pos['z'], ped_pos['x'], ped_pos['y'], ped_pos['z'], true)
        if players.user_ped() ~= v and not IS_ENTITY_DEAD(v) then
            if not venus_targetplayers then
                if IS_PED_A_PLAYER(v) then
                    target_this = false
                end
            end
            if not venus_targetnpcs then
                if not IS_PED_A_PLAYER(v) then
                    target_this = false
                end
            end
            if not HAS_ENTITY_CLEAR_LOS_TO_ENTITY(players.user_ped(), v, 17) then
                target_this = false
            end
            if venus_usefov then
                if not IS_PED_FACING_PED(players.user_ped(), v, venus_fov) then
                    target_this = false
                end
            end
            if not venus_targetfriends and venus_targetplayers then
                if IS_PED_A_PLAYER(v) then
                    local pid = NETWORK_GET_PLAYER_INDEX_FROM_PED(v)
                    local hdl = pid_to_handle(pid)
                    if NETWORK_IS_FRIEND(hdl) then
                        target_this = false 
                    end
                end
            end
            if venus_internalmode == "closest" then
                if this_dist <= dist then
                    if target_this then
                        dist = this_dist
                        cur_tar = v
                    end
                end
            end 
        end
    end
    return cur_tar
end

local ped_model_cache = {}
root:toggle_loop("Venus aim enhancement", {'venuson'}, '', function(on)
    if venus_info then 
        util.draw_debug_text('VENUS Active')
    end
    local target = get_aimbot_target()
    if target ~= 0 then
        --local t_pos = GET_ENTITY_COORDS(target, true)
        local veh = GET_VEHICLE_PED_IS_IN(target, true)
        local t_pos = GET_PED_BONE_COORDS(target, venus_bone, 0, 0, 0)
        local t_pos2 = GET_PED_BONE_COORDS(target, venus_bone, -0.01, 0, 0)
        if venus_paint then
            DRAW_MARKER_SPHERE(t_pos.x, t_pos.y, t_pos.z, 0.09, 255, 0, 0, 100)
        end
        if venus_info then 
            if IS_PED_A_PLAYER(target) then 
                util.draw_debug_text('Target: ' .. GET_PLAYER_NAME(NETWORK_GET_PLAYER_INDEX_FROM_PED(target)))
            else
                local mdl = GET_ENTITY_MODEL(target)
                if not table.contains(ped_model_cache, mdl) then 
                    ped_model_cache[mdl] = util.reverse_joaat(mdl)
                end
                util.draw_debug_text('Target: ' .. ped_model_cache[mdl] .. ' (NPC)')
            end
            util.draw_debug_text(GET_ENTITY_HEALTH(target) .. '/' .. GET_ENTITY_MAX_HEALTH(target) .. ' HP')
        end
        if IS_PED_SHOOTING(players.user_ped()) then
            local wep = GET_SELECTED_PED_WEAPON(players.user_ped())
            local dmg = GET_WEAPON_DAMAGE(wep, 0)
            local veh = GET_VEHICLE_PED_IS_IN(target, true)
            for i=1, venus_sneak_bullets do
                SHOOT_SINGLE_BULLET_BETWEEN_COORDS(t_pos.x, t_pos.y, t_pos.z, t_pos2.x, t_pos2.y, t_pos2.z, dmg, true, wep, players.user_ped(), true, false, 100.0)
            end
            util.yield(GET_WEAPON_TIME_BETWEEN_SHOTS(wep) * 1000)
        end
    end
end)

root:toggle("HUD", {'venusinfo'}, '', function(on)
    venus_info = on
end, true)

root:slider("Bullet count", {'venusbullets'}, "", 1, 100, 1, 1, function(s)
    venus_sneak_bullets = s
end)

root:divider('FOV')
root:toggle("Use FOV", {'venususefov'}, 'If this is off, targets will be selected based on proximity to you', function(on)
    venus_usefov = on
end, true)

root:slider("Targeting FOV", {'venusfov'}, "", 1, 270, 5, 1, function(s)
    venus_fov = s
end)

root:toggle("Paint target", {'venuspaint'}, '', function(on)
    venus_paint = on
end, true)

root:divider('Targets')

root:toggle('Friends', {'venusfriends'}, "", function(on)
    venus_targetfriends = on
end, false)

root:toggle("NPC\'s", {'venusnpcs'}, '', function(on)
    venus_targetnpcs = on 
end, false)

root:toggle('Players', {'venusplayers'}, "", function(on)
    venus_targetplayers = on
end, true)

root:textslider("Aim for", {'venuson'}, '', {'Head', 'Neck', 'Jaw', 'Spine', 'Pelvis', 'Left foot'}, function(x, option)
    switch option do 
        case "Head":
            venus_bone = 31086
            break
        case "Neck":
            venus_bone = 39317
            break 
        case "Jaw":
            venus_bone = 46240
            break
        case "Spine":
            venus_bone = 24817
            break 
        case "Pelvis":
            venus_bone = 11816
            break
        case "Left foot":
            venus_bone = 57717
            break
        case "Right foot":
            venus_bone = 24806
            break
    end
end)

menu.my_root():hyperlink('Join Discord', 'https://discord.gg/zZ2eEjj88v', '')
