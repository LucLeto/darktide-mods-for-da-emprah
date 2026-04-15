local ChatManagerConstants = require("scripts/foundation/managers/chat/chat_manager_constants")
local HudElementSmartTaggingSettings = require("scripts/ui/hud/elements/smart_tagging/hud_element_smart_tagging_settings")
local InputDevice = require("scripts/managers/input/input_device")
local VOQueryConstants = require("scripts/settings/dialogue/vo_query_constants")
local Vo = require("scripts/utilities/vo")
local definitions = require("scripts/mods/ForDaEmprah/ForDaEmprah_definitions")

local mod = get_mod("ForDaEmprah")

local ChannelTags = ChatManagerConstants.ChannelTag
local HudElementSmartTagging_instance

local CLOCK_SLOTS = definitions.CLOCK_SLOTS
local CLOCK_WHEEL_SLOT_COUNT = #CLOCK_SLOTS
local wheel_settings = {}

for i, clock_slot in ipairs(CLOCK_SLOTS) do
    wheel_settings[i] = definitions.wheel_setting_id(clock_slot)
end

HudElementSmartTaggingSettings.wheel_slots = CLOCK_WHEEL_SLOT_COUNT

local function _item_tag(value, fallback)
    if type(value) ~= "string" then
        return fallback
    end

    if string.match(value, "^pup_") or string.match(value, "^station_") then
        return value
    end

    return fallback
end

local function _clone_command(command)
    if not command then
        return nil
    end

    local cloned_command = {}

    for key, value in pairs(command) do
        cloned_command[key] = value
    end

    return cloned_command
end

local vanilla_wheel_command_ids = {
    [1] = true,
    [22] = true,
    [23] = true,
    [24] = true,
    [25] = true,
    [26] = true,
    [27] = true,
}

local function _chat_setting_id(display_name)
    return display_name and "chat_" .. display_name or nil
end

-- Prefer stock loc keys where possible so players without the mod still resolve the chat line correctly.
local stock_chat_loc_keys_by_display_name = {
    option_ammo = "loc_pickup_consumable_small_clip_01",
    option_ammo_crate = "loc_pickup_pocketable_ammo_crate_01",
    option_cryonic_rod = "loc_pickup_luggable_control_rod_01",
    option_diamantine = "loc_pickup_small_platinum",
    option_following = "loc_reply_smart_tag_follow",
    option_grenade = "loc_pickup_consumable_small_grenade_01",
    option_grimoire = "loc_pickup_side_mission_pocketable_01",
    option_health_booster = "loc_pickup_pocketable_01",
    option_medipack = "loc_pickup_pocketable_medical_crate_01",
    option_medipack_down = "loc_pickup_deployable_medical_crate_01",
    option_mine = "loc_reply_smart_tag_dibs",
    option_plasteel = "loc_pickup_small_metal",
    option_power_cell = "loc_pickup_luggable_battery_01",
    option_relic = "loc_pickup_side_mission_consumable_01",
    option_scripture = "loc_pickup_side_mission_pocketable_02",
    option_yes = "loc_reply_smart_tag_ok",
}

local function _optional_chat_message_data(display_name)
    local stock_loc_key = stock_chat_loc_keys_by_display_name[display_name]

    return {
        channel = ChannelTags.MISSION,
        text = stock_loc_key or display_name,
    }
end

local function _chat_enabled_for_command(command)
    local chat_message_data = command and command.chat_message_data
    local setting_id = chat_message_data and chat_message_data.setting_id

    return not setting_id or mod:get(setting_id)
end


local commands = {
    [1] = {
        icon = "content/ui/materials/hud/communication_wheel/icons/for_the_emperor",
        display_name = "option_for_the_emperor",
        voice_event_data = {
            voice_tag_concept = VOQueryConstants.concepts.on_demand_com_wheel,
            voice_tag_id = VOQueryConstants.trigger_ids.com_wheel_vo_for_the_emperor,
        },
    },
    [2] = {
        icon = "content/ui/materials/icons/player_states/lugged",
        display_name = "option_vacuum_capsule",
        voice_event_data = {
            voice_tag_concept = VOQueryConstants.concepts.on_demand_vo_tag_item,
            voice_tag_id = VOQueryConstants.trigger_ids.smart_tag_vo_pickup_container,
        },
    },
    [3] = {
        icon = "content/ui/materials/hud/interactions/icons/default",
        display_name = "option_yes",
        voice_event_data = {
            voice_tag_concept = VOQueryConstants.concepts.on_demand_com_wheel,
            voice_tag_id = VOQueryConstants.trigger_ids.com_wheel_vo_yes,
        },
    },
    [4] = {
        icon = "content/ui/materials/icons/list_buttons/cross",
        display_name = "option_no",
        voice_event_data = {
            voice_tag_concept = VOQueryConstants.concepts.on_demand_com_wheel,
            voice_tag_id = VOQueryConstants.trigger_ids.com_wheel_vo_no,
        },
    },
    [5] = {
        icon = "content/ui/materials/icons/player_states/lugged",
        display_name = "option_cryonic_rod",
        voice_event_data = {
            voice_tag_concept = VOQueryConstants.concepts.on_demand_vo_tag_item,
            voice_tag_id = VOQueryConstants.trigger_ids.smart_tag_vo_pickup_control_rod,
        },
    },
    [6] = {
        icon = "content/ui/materials/icons/player_states/lugged",
        display_name = "option_power_cell",
        voice_event_data = {
            voice_tag_concept = VOQueryConstants.concepts.on_demand_vo_tag_item,
            voice_tag_id = VOQueryConstants.trigger_ids.smart_tag_vo_pickup_battery,
        },
    },
    [7] = {
        icon = "content/ui/materials/icons/pocketables/hud/scripture",
        display_name = "option_scripture",
        voice_event_data = {
            voice_tag_concept = VOQueryConstants.concepts.on_demand_vo_tag_item,
            voice_tag_id = VOQueryConstants.trigger_ids.smart_tag_vo_pickup_side_mission_tome,
        },
    },
    [8] = {
        icon = "content/ui/materials/icons/pocketables/hud/grimoire",
        display_name = "option_grimoire",
        voice_event_data = {
            voice_tag_concept = VOQueryConstants.concepts.on_demand_vo_tag_item,
            voice_tag_id = VOQueryConstants.trigger_ids.smart_tag_vo_pickup_side_mission_grimoire,
        },
    },
    [9] = {
        icon = "content/ui/materials/hud/interactions/icons/objective_side",
        display_name = "option_relic",
        voice_event_data = {
            voice_tag_concept = VOQueryConstants.concepts.on_demand_vo_tag_item,
            voice_tag_id = VOQueryConstants.trigger_ids.smart_tag_vo_pickup_side_mission_consumable,
        },
    },
    [10] = {
        icon = "content/ui/materials/hud/interactions/icons/pocketable_syringe_corruption",
        display_name = "option_health_booster",
        voice_event_data = {
            voice_tag_concept = VOQueryConstants.concepts.on_demand_vo_tag_item,
            voice_tag_id = _item_tag(VOQueryConstants.trigger_ids.smart_tag_vo_pickup_stimm_health, "pup_stimm_health"),
        },
    },
    [11] = {
        icon = "content/ui/materials/hud/interactions/icons/default",
        display_name = "option_mine",
        voice_event_data = {
            voice_tag_concept = VOQueryConstants.concepts.on_demand_com_wheel,
            voice_tag_id = VOQueryConstants.trigger_ids.com_wheel_vo_need_that,
        },
    },
    [12] = {
        icon = "content/ui/materials/hud/interactions/icons/ammunition",
        display_name = "option_ammo",
        voice_event_data = {
            voice_tag_concept = VOQueryConstants.concepts.on_demand_vo_tag_item,
            voice_tag_id = VOQueryConstants.trigger_ids.smart_tag_vo_pickup_ammo,
        },
    },
    [13] = {
        icon = "content/ui/materials/hud/interactions/icons/grenade",
        display_name = "option_grenade",
        voice_event_data = {
            voice_tag_concept = VOQueryConstants.concepts.on_demand_vo_tag_item,
            voice_tag_id = VOQueryConstants.trigger_ids.smart_tag_vo_small_grenade,
        },
    },
    [14] = {
        icon = "content/ui/materials/hud/interactions/icons/environment_generic",
        display_name = "option_plasteel",
        voice_event_data = {
            voice_tag_concept = VOQueryConstants.concepts.on_demand_vo_tag_item,
            voice_tag_id = VOQueryConstants.trigger_ids.smart_tag_vo_pickup_forge_metal,
        },
    },
    [15] = {
        icon = "content/ui/materials/hud/interactions/icons/environment_generic",
        display_name = "option_diamantine",
        voice_event_data = {
            voice_tag_concept = VOQueryConstants.concepts.on_demand_vo_tag_item,
            voice_tag_id = VOQueryConstants.trigger_ids.smart_tag_vo_pickup_platinum,
        },
    },
    [16] = {
        icon = "content/ui/materials/hud/communication_wheel/icons/location",
        display_name = "option_following",
        voice_event_data = {
            voice_tag_concept = VOQueryConstants.concepts.on_demand_com_wheel,
            voice_tag_id = VOQueryConstants.trigger_ids.com_wheel_vo_follow_you,
        },
    },
    [17] = {
        icon = "content/ui/materials/hud/interactions/icons/respawn",
        display_name = "option_medicae_station",
        voice_event_data = {
            voice_tag_concept = VOQueryConstants.concepts.on_demand_vo_tag_item,
            voice_tag_id = VOQueryConstants.trigger_ids.smart_tag_vo_station_health,
        },
    },
    [18] = {
        icon = "content/ui/materials/hud/interactions/icons/respawn",
        display_name = "option_uncharged_medicae",
        voice_event_data = {
            voice_tag_concept = VOQueryConstants.concepts.on_demand_vo_tag_item,
            voice_tag_id = VOQueryConstants.trigger_ids.smart_tag_vo_station_health_without_battery,
        },
    },
    [19] = {
        icon = "content/ui/materials/hud/interactions/icons/pocketable_medkit",
        display_name = "option_medipack",
        voice_event_data = {
            voice_tag_concept = VOQueryConstants.concepts.on_demand_vo_tag_item,
            voice_tag_id = VOQueryConstants.trigger_ids.smart_tag_vo_pickup_medical_crate,
        },
    },
    [20] = {
        icon = "content/ui/materials/hud/interactions/icons/pocketable_medkit",
        display_name = "option_medipack_down",
        voice_event_data = {
            voice_tag_concept = VOQueryConstants.concepts.on_demand_vo_tag_item,
            voice_tag_id = _item_tag(VOQueryConstants.trigger_ids.smart_tag_vo_pickup_deployed_medical_crate,
                "pup_deployed_medical_crate"),
        },
    },
    [21] = {
        icon = "content/ui/materials/hud/interactions/icons/pocketable_ammo",
        display_name = "option_ammo_crate",
        voice_event_data = {
            voice_tag_concept = VOQueryConstants.concepts.on_demand_vo_tag_item,
            voice_tag_id = _item_tag(VOQueryConstants.trigger_ids.smart_tag_vo_pickup_deployed_ammo_crate,
                "pup_deployed_ammo_crate"),
        },
    },
    [22] = {
        icon = "content/ui/materials/hud/communication_wheel/icons/ammo",
        display_name = "option_need_ammo",
        chat_message_data = {
            channel = ChannelTags.MISSION,
            text = "loc_communication_wheel_need_ammo",
        },
        voice_event_data = {
            voice_tag_concept = VOQueryConstants.concepts.on_demand_com_wheel,
            voice_tag_id = VOQueryConstants.trigger_ids.com_wheel_vo_need_ammo,
        },
    },
    [23] = {
        icon = "content/ui/materials/hud/communication_wheel/icons/health",
        display_name = "option_need_healing",
        chat_message_data = {
            channel = ChannelTags.MISSION,
            text = "loc_communication_wheel_need_health",
        },
        voice_event_data = {
            voice_tag_concept = VOQueryConstants.concepts.on_demand_com_wheel,
            voice_tag_id = VOQueryConstants.trigger_ids.com_wheel_vo_need_health,
        },
    },
    [24] = {
        icon = "content/ui/materials/hud/communication_wheel/icons/attention",
        display_name = "option_look_there",
        tag_type = "location_attention",
        voice_event_data = {
            voice_tag_concept = VOQueryConstants.concepts.on_demand_com_wheel,
            voice_tag_id = VOQueryConstants.trigger_ids.com_wheel_vo_over_here,
        },
    },
    [25] = {
        icon = "content/ui/materials/hud/communication_wheel/icons/location",
        display_name = "option_go_there",
        tag_type = "location_ping",
        voice_event_data = {
            voice_tag_concept = VOQueryConstants.concepts.on_demand_com_wheel,
            voice_tag_id = VOQueryConstants.trigger_ids.com_wheel_vo_lets_go_this_way,
        },
    },
    [26] = {
        icon = "content/ui/materials/hud/communication_wheel/icons/enemy",
        display_name = "option_enemy",
        tag_type = "location_threat",
        voice_event_data = {
            voice_tag_concept = VOQueryConstants.concepts.on_demand_com_wheel,
            voice_tag_id = VOQueryConstants.trigger_ids.com_wheel_vo_enemy_over_here,
        },
    },
    [27] = {
        icon = "content/ui/materials/hud/communication_wheel/icons/thanks",
        display_name = "option_thanks",
        chat_message_data = {
            channel = ChannelTags.MISSION,
            text = "loc_communication_wheel_thanks",
        },
        voice_event_data = {
            voice_tag_concept = VOQueryConstants.concepts.on_demand_com_wheel,
            voice_tag_id = VOQueryConstants.trigger_ids.com_wheel_vo_thank_you,
        },
    },
    [28] = {
        icon = "content/ui/materials/hud/interactions/icons/default",
        display_name = "option_sorry",
        -- Darktide does not expose a dedicated "sorry" bark in the current on-demand VO tables.
        use_apology_rule = true,
        use_custom_execution = true,
    },
}

local function _setup_optional_chat_messages()
    for command_id, command in pairs(commands) do
        if not vanilla_wheel_command_ids[command_id] and command.display_name then
            command.chat_message_data = _optional_chat_message_data(command.display_name)
            command.chat_message_data.setting_id = _chat_setting_id(command.display_name)
        end
    end
end

_setup_optional_chat_messages()

local function _active_wheel_options()
    local options = {}

    for i = 1, #wheel_settings do
        local command_id = mod:get(wheel_settings[i])

        if command_id and command_id > 0 then
            local command = _clone_command(commands[command_id])

            if command then
                if not _chat_enabled_for_command(command) then
                    command.chat_message_data = nil
                end

                options[#options + 1] = command
            end
        end
    end

    return options
end

local function _visible_wheel_entries(entries)
    local visible_entries = {}

    for i = 1, #entries do
        local entry = entries[i]

        if entry and entry.option then
            visible_entries[#visible_entries + 1] = entry
        end
    end

    return visible_entries
end

local function _clock_angle(position, visible_count)
    if visible_count <= 0 then
        return math.pi
    end

    local radians_per_entry = math.pi * 2 / visible_count

    return math.pi - (position - 1) * radians_per_entry
end

local function _screen_angle(x1, y1, x2, y2)
    return (math.pi * 2 - math.angle(x1, y1, x2, y2) - math.pi * 0.5) % (math.pi * 2)
end

local function _angle_distance(a, b)
    return (a - b + math.pi) % (math.pi * 2) - math.pi
end

local function _mouse_hover_angle(visible_count)
    if visible_count <= 0 then
        return 0
    end

    return math.max(math.rad(8), (math.pi * 2 / visible_count) - math.rad(1))
end

local function _gamepad_hover_angle(visible_count)
    if visible_count <= 0 then
        return 0
    end

    return math.min(math.pi * 2, (math.pi * 2 / visible_count) * 1.1)
end

local function _wheel_radius_bounds(visible_count)
    local extra_radius = math.max(visible_count - 8, 0) * 12

    return HudElementSmartTaggingSettings.min_radius + extra_radius,
        HudElementSmartTaggingSettings.max_radius + extra_radius
end


local function _chat_channel(channel_tag)
    local chat_manager = Managers.chat

    if not chat_manager then
        return nil
    end

    local channels = chat_manager:connected_chat_channels()

    if not channels then
        return nil
    end

    for channel_handle, channel in pairs(channels) do
        if channel.tag == channel_tag then
            return channel_handle
        end
    end

    return nil
end

local function _send_chat_message(chat_message_data)
    if not chat_message_data then
        return
    end

    local setting_id = chat_message_data.setting_id

    if setting_id and not mod:get(setting_id) then
        return
    end

    local chat_manager = Managers.chat
    local channel_handle = _chat_channel(chat_message_data.channel)

    if not chat_manager or not channel_handle then
        return
    end

    if chat_message_data.localized == false then
        local text = chat_message_data.text

        if chat_message_data.localize_text then
            text = mod:localize(text)
        end

        chat_manager:send_channel_message(channel_handle, text)
    else
        chat_manager:send_loc_channel_message(channel_handle, chat_message_data.text, chat_message_data.context)
    end
end

local function _player_unit()
    local instance = HudElementSmartTagging_instance
    local parent = instance and instance._parent

    return parent and parent:player_unit() or nil
end

local function _dialogue_extension(unit)
    if not unit then
        return nil
    end

    return ScriptUnit.has_extension(unit, "dialogue_system")
end

local function _player_class(unit)
    local dialogue_extension = _dialogue_extension(unit)

    if not dialogue_extension then
        return nil
    end

    if dialogue_extension.vo_class_name then
        return dialogue_extension:vo_class_name()
    end

    local context = dialogue_extension.get_context and dialogue_extension:get_context()

    return context and context.class_name or nil
end

local function _append_unique_class(list, seen, class_name)
    if class_name and not seen[class_name] then
        seen[class_name] = true
        list[#list + 1] = class_name
    end
end

local function _ordered_teammate_classes(player_unit)
    local player_unit_spawn_manager = Managers.state.player_unit_spawn
    local alive_players = player_unit_spawn_manager and player_unit_spawn_manager:alive_players()

    if not player_unit or not alive_players or not ALIVE[player_unit] then
        return {}
    end

    local player_position = POSITION_LOOKUP[player_unit]

    if not player_position then
        return {}
    end

    local teammates = {}
    local ordered_classes = {}
    local seen_classes = {}

    for i = 1, #alive_players do
        local other_player = alive_players[i]
        local other_unit = other_player and other_player.player_unit

        if other_unit and other_unit ~= player_unit and ALIVE[other_unit] then
            local other_position = POSITION_LOOKUP[other_unit]

            if other_position then
                teammates[#teammates + 1] = {
                    class_name = _player_class(other_unit),
                    distance = Vector3.distance_squared(player_position, other_position),
                }
            end
        end
    end

    table.sort(teammates, function(a, b)
        return a.distance < b.distance
    end)

    for i = 1, #teammates do
        _append_unique_class(ordered_classes, seen_classes, teammates[i].class_name)
    end

    return ordered_classes
end

local function _available_apology_target_classes(dialogue_extension, speaker_class)
    local voice_choices = dialogue_extension and dialogue_extension._vo_choice

    if not voice_choices or not speaker_class then
        return {}
    end

    local pattern = string.format("^response_for_friendly_fire_from_%s_to_(.+)$", speaker_class)
    local target_classes = {}
    local seen_classes = {}

    for rule_name in pairs(voice_choices) do
        local target_class = string.match(rule_name, pattern)

        _append_unique_class(target_classes, seen_classes, target_class)
    end

    table.sort(target_classes)

    return target_classes
end

local function _apology_rule_name(player_unit)
    local dialogue_extension = _dialogue_extension(player_unit)
    local speaker_class = _player_class(player_unit)

    if not dialogue_extension or not speaker_class then
        return nil
    end

    local target_classes = {}
    local seen_classes = {}
    local nearby_target_classes = _ordered_teammate_classes(player_unit)
    local available_target_classes = _available_apology_target_classes(dialogue_extension, speaker_class)

    for i = 1, #nearby_target_classes do
        _append_unique_class(target_classes, seen_classes, nearby_target_classes[i])
    end

    for i = 1, #available_target_classes do
        _append_unique_class(target_classes, seen_classes, available_target_classes[i])
    end

    for i = 1, #target_classes do
        local rule_name = string.format("response_for_friendly_fire_from_%s_to_%s", speaker_class, target_classes[i])

        if dialogue_extension:has_dialogue(rule_name) then
            return rule_name
        end
    end

    return nil
end

local function _trigger_apology_voice(player_unit)
    local rule_name = _apology_rule_name(player_unit)

    if not rule_name then
        return false
    end

    Vo.play_local_vo_event(player_unit, rule_name, 0)

    return true
end

local function _trigger_location_tag(command)
    local instance = HudElementSmartTagging_instance

    if not instance or not command.tag_type then
        return
    end

    local raycast_data = instance:_find_raycast_targets(true)
    local hit_position = raycast_data and raycast_data.static_hit_position

    if hit_position then
        instance:_trigger_smart_tag(command.tag_type, nil, Vector3Box.unbox(hit_position))
    end
end

local function _trigger_voice_event(command, player_unit)
    local voice_event_data = command.voice_event_data

    if voice_event_data and player_unit then
        Vo.on_demand_vo_event(player_unit, voice_event_data.voice_tag_concept, voice_event_data.voice_tag_id)
    end
end

local function _execute_command(command, player_unit)
    if not command then
        return
    end

    player_unit = player_unit or _player_unit()

    _trigger_location_tag(command)
    _send_chat_message(command.chat_message_data)

    if command.use_apology_rule then
        _trigger_apology_voice(player_unit)
    else
        _trigger_voice_event(command, player_unit)
    end
end

mod:hook("HudElementSmartTagging", "_populate_wheel", function(func, self, options)
    local active_options = _active_wheel_options()

    self._mod_active_wheel_option_count = #active_options

    func(self, active_options)
end)

mod:hook("HudElementSmartTagging", "_update_widget_locations", function(func, self)
    local entries = self._entries
    local visible_entries = _visible_wheel_entries(entries)
    local visible_count = #visible_entries
    local active_progress = self._wheel_active_progress
    local anim_progress = math.smoothstep(active_progress, 0, 1)
    local min_radius, max_radius = _wheel_radius_bounds(visible_count)
    local radius = min_radius + anim_progress * (max_radius - min_radius)

    for i = 1, #entries do
        local entry = entries[i]

        if entry and not entry.option then
            local widget = entry.widget
            local offset = widget.offset

            widget.content.angle = math.pi
            widget.content.hotspot.force_hover = false
            offset[1] = 0
            offset[2] = 0
        end
    end

    for i = 1, visible_count do
        local entry = visible_entries[i]
        local widget = entry.widget
        local angle = _clock_angle(i, visible_count)
        local offset = widget.offset

        widget.content.angle = angle
        offset[1] = math.sin(angle) * radius
        offset[2] = math.cos(angle) * radius
    end
end)

mod:hook("HudElementSmartTagging", "_update_wheel_presentation",
    function(func, self, dt, t, ui_renderer, render_settings, input_service)
        local screen_width, screen_height = RESOLUTION_LOOKUP.width, RESOLUTION_LOOKUP.height
        local scale = render_settings.scale
        local cursor = input_service and input_service:get("cursor")

        if input_service and InputDevice.gamepad_active then
            cursor = input_service:get("navigate_controller_right")
            cursor[1] = screen_width * 0.5 + cursor[1] * screen_width * 0.5
            cursor[2] = screen_height * 0.5 - cursor[2] * screen_height * 0.5
        end

        if not cursor then
            return
        end

        local cursor_distance_from_center = math.distance_2d(screen_width * 0.5, screen_height * 0.5, cursor[1],
            cursor[2])
        local cursor_visual_angle = math.angle(screen_width * 0.5, screen_height * 0.5, cursor[1], cursor[2]) -
            math.pi * 0.5
        local cursor_selection_angle = _screen_angle(screen_width * 0.5, screen_height * 0.5, cursor[1], cursor[2])
        local visible_count = self._mod_active_wheel_option_count or 0
        local entry_hover_degrees_half = _mouse_hover_angle(visible_count) * 0.5
        local any_hover = false
        local hovered_entry
        local entries = self._entries

        for i = 1, #entries do
            local entry = entries[i]
            local widget = entry.widget
            local is_hover = false

            if entry.option and cursor_distance_from_center > 130 * scale then
                local widget_angle = _screen_angle(0, 0, widget.offset[1], widget.offset[2])
                local angle_diff = math.abs(_angle_distance(widget_angle, cursor_selection_angle))

                if angle_diff <= entry_hover_degrees_half then
                    is_hover = true
                    any_hover = true
                    hovered_entry = entry
                end
            end

            widget.content.hotspot.force_hover = is_hover
        end

        local wheel_background_widget = self._widgets_by_name.wheel_background

        wheel_background_widget.content.angle = cursor_visual_angle
        wheel_background_widget.content.force_hover = any_hover
        wheel_background_widget.content.text = ""
        wheel_background_widget.style.mark.color[1] = any_hover and 255 or 0

        if hovered_entry then
            wheel_background_widget.content.text = Localize(hovered_entry.option.display_name)
        end
    end)

mod:hook("HudElementSmartTagging", "_should_draw_wheel_gamepad", function(func, self, input_service)
    local look_delta = input_service:get("look_raw_controller") * INSTANT_WHEEL_THRESHOLD * 2
    local is_dragging = Vector3.length(look_delta) > INSTANT_WHEEL_THRESHOLD
    local wheel_context = self._com_wheel_context

    if not wheel_context.camera_still_on_tag then
        return false
    end

    if not wheel_context.instant_drew and is_dragging then
        local entries = self._entries
        local look_angle = _screen_angle(0, 0, look_delta[1], look_delta[2])
        local half_entry_hover_angle = _gamepad_hover_angle(self._mod_active_wheel_option_count or 0) * 0.5

        for i = 1, #entries do
            local entry = entries[i]

            if entry.option then
                local widget_angle = _screen_angle(0, 0, entry.widget.offset[1], entry.widget.offset[2])
                local angle_diff = math.abs(_angle_distance(widget_angle, look_angle))

                if angle_diff < half_entry_hover_angle then
                    wheel_context.instant_drew = true

                    break
                end
            end
        end
    end

    return is_dragging
end)

mod:hook("HudElementSmartTagging", "_on_com_wheel_stop_callback",
    function(func, self, t, ui_renderer, render_settings, input_service)
        local wheel_hovered_entry = self._wheel_active and self:_is_wheel_entry_hovered(t)
        local command = wheel_hovered_entry and wheel_hovered_entry.option

        if command and command.use_custom_execution then
            local parent = self._parent
            local player_unit = parent and parent:player_unit() or nil
            local wheel_context = self._com_wheel_context

            _execute_command(command, player_unit)

            wheel_context.input_stop_time = t
            wheel_context.input_start_time = nil
            wheel_context.is_double_tap = nil
            wheel_context.instant_drew = nil
            wheel_context.camera_still_on_tag = nil
            wheel_context.simultaneous_press = nil

            Managers.event:trigger("event_set_communication_wheel_state", "inactive")

            return
        end

        func(self, t, ui_renderer, render_settings, input_service)
    end)

local function setup_keybind_functions()
    for key, command in ipairs(commands) do
        mod["keybind_" .. key] = function()
            if Managers.input:cursor_active() or Managers.ui:using_input() then
                return
            end

            _execute_command(command)
        end
    end
end

mod:hook_safe("HudElementSmartTagging", "update", function(self)
    if HudElementSmartTagging_instance ~= self then
        HudElementSmartTagging_instance = self
        setup_keybind_functions()
    end

    if #self._entries ~= CLOCK_WHEEL_SLOT_COUNT then
        self:_setup_entries(CLOCK_WHEEL_SLOT_COUNT)
        self:_populate_wheel()
    end

    if mod.setting_dirty then
        self:_populate_wheel()
        mod.setting_dirty = false
    end
end)

mod:hook_safe("HudElementSmartTagging", "destroy", function(self)
    if HudElementSmartTagging_instance == self then
        HudElementSmartTagging_instance = nil
    end
end)

mod.on_setting_changed = function(setting_id)
    if string.find(setting_id, "plugin_wheel_", 1, true) then
        mod.setting_dirty = true
    end
end

local function init_keybind_functions()
    local noop = function()
        return
    end

    for key in ipairs(commands) do
        mod["keybind_" .. key] = noop
    end
end

init_keybind_functions()
