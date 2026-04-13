local ChatManagerConstants = require("scripts/foundation/managers/chat/chat_manager_constants")
local VOQueryConstants = require("scripts/settings/dialogue/vo_query_constants")
local Vo = require("scripts/utilities/vo")

local mod = get_mod("ForDaEmprah")

local ChannelTags = ChatManagerConstants.ChannelTag
local HudElementSmartTagging_instance

local POS_BOTTOM = 1
local POS_BOTTOM_RIGHT = 2
local POS_RIGHT = 3
local POS_TOP_RIGHT = 4
local POS_TOP = 5
local POS_TOP_LEFT = 6
local POS_LEFT = 7
local POS_BOTTOM_LEFT = 8

local localized_strings = {
	option_ammo = "Ammo",
	option_ammo_crate = "Ammo Crate",
	option_cryonic_rod = "Cryonic Rod",
	option_diamantine = "Diamantine",
	option_enemy = "Enemy",
	option_following = "Following",
	option_for_the_emperor = "For The Emperor!",
	option_go_there = "Go There",
	option_grenade = "Grenade",
	option_grimoire = "Grimoire",
	option_health_booster = "Med Stimm",
	option_look_there = "Look There",
	option_medicae_station = "Medicae Station",
	option_medipack = "Medipack",
	option_medipack_down = "Medipack Down",
	option_mine = "Mine",
	option_need_ammo = "Need Ammo",
	option_need_healing = "Need Healing",
	option_no = "No",
	option_plasteel = "Plasteel",
	option_power_cell = "Power Cell",
	option_relic = "Relic",
	option_scripture = "Scripture",
	option_sorry = "Sorry",
	option_thanks = "Thanks",
	option_uncharged_medicae = "Uncharged Medicae",
	option_vacuum_capsule = "Vacuum Capsule",
	option_yes = "Yes",
}

local function _item_tag(value, fallback)
	if type(value) ~= "string" then
		return fallback
	end

	if string.match(value, "^pup_") or string.match(value, "^station_") then
		return value
	end

	return fallback
end

local commands = {
	[1] = {
		icon = "content/ui/materials/icons/system/escape/achievements",
		display_name = "option_for_the_emperor",
		voice_event_data = {
			voice_tag_concept = VOQueryConstants.concepts.on_demand_com_wheel,
			voice_tag_id = VOQueryConstants.trigger_ids.com_wheel_vo_for_the_emperor,
		},
	},
	[2] = {
		icon = "content/ui/materials/hud/interactions/icons/training_grounds",
		display_name = "option_vacuum_capsule",
		voice_event_data = {
			voice_tag_concept = VOQueryConstants.concepts.on_demand_vo_tag_item,
			voice_tag_id = VOQueryConstants.trigger_ids.smart_tag_vo_pickup_container,
		},
	},
	[3] = {
		icon = "content/ui/materials/icons/pocketables/hud/scripture",
		display_name = "option_yes",
		voice_event_data = {
			voice_tag_concept = VOQueryConstants.concepts.on_demand_com_wheel,
			voice_tag_id = VOQueryConstants.trigger_ids.com_wheel_vo_yes,
		},
	},
	[4] = {
		icon = "content/ui/materials/icons/system/settings/category_interface",
		display_name = "option_no",
		voice_event_data = {
			voice_tag_concept = VOQueryConstants.concepts.on_demand_com_wheel,
			voice_tag_id = VOQueryConstants.trigger_ids.com_wheel_vo_no,
		},
	},
	[5] = {
		icon = "content/ui/materials/hud/interactions/icons/training_grounds",
		display_name = "option_cryonic_rod",
		voice_event_data = {
			voice_tag_concept = VOQueryConstants.concepts.on_demand_vo_tag_item,
			voice_tag_id = VOQueryConstants.trigger_ids.smart_tag_vo_pickup_control_rod,
		},
	},
	[6] = {
		icon = "content/ui/materials/hud/interactions/icons/training_grounds",
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
		icon = "content/ui/materials/icons/pocketables/hud/grimoire",
		display_name = "option_relic",
		voice_event_data = {
			voice_tag_concept = VOQueryConstants.concepts.on_demand_vo_tag_item,
			voice_tag_id = VOQueryConstants.trigger_ids.smart_tag_vo_pickup_side_mission_consumable,
		},
	},
	[10] = {
		icon = "content/ui/materials/hud/interactions/icons/pocketable_medkit",
		display_name = "option_health_booster",
		voice_event_data = {
			voice_tag_concept = VOQueryConstants.concepts.on_demand_vo_tag_item,
			voice_tag_id = _item_tag(VOQueryConstants.trigger_ids.smart_tag_vo_pickup_stimm_health, "pup_stimm_health"),
		},
	},
	[11] = {
		icon = "content/ui/materials/hud/interactions/icons/pocketable_default",
		display_name = "option_mine",
		voice_event_data = {
			voice_tag_concept = VOQueryConstants.concepts.on_demand_com_wheel,
			voice_tag_id = VOQueryConstants.trigger_ids.com_wheel_vo_need_that,
		},
	},
	[12] = {
		icon = "content/ui/materials/hud/interactions/icons/pocketable_ammo",
		display_name = "option_ammo",
		voice_event_data = {
			voice_tag_concept = VOQueryConstants.concepts.on_demand_vo_tag_item,
			voice_tag_id = VOQueryConstants.trigger_ids.smart_tag_vo_pickup_ammo,
		},
	},
	[13] = {
		icon = "content/ui/materials/hud/interactions/icons/pocketable_default",
		display_name = "option_grenade",
		voice_event_data = {
			voice_tag_concept = VOQueryConstants.concepts.on_demand_vo_tag_item,
			voice_tag_id = VOQueryConstants.trigger_ids.smart_tag_vo_small_grenade,
		},
	},
	[14] = {
		icon = "content/ui/materials/hud/interactions/icons/pocketable_default",
		display_name = "option_plasteel",
		voice_event_data = {
			voice_tag_concept = VOQueryConstants.concepts.on_demand_vo_tag_item,
			voice_tag_id = VOQueryConstants.trigger_ids.smart_tag_vo_pickup_forge_metal,
		},
	},
	[15] = {
		icon = "content/ui/materials/hud/interactions/icons/pocketable_default",
		display_name = "option_diamantine",
		voice_event_data = {
			voice_tag_concept = VOQueryConstants.concepts.on_demand_vo_tag_item,
			voice_tag_id = VOQueryConstants.trigger_ids.smart_tag_vo_pickup_platinum,
		},
	},
	[16] = {
		icon = "content/ui/materials/icons/pocketables/hud/scripture",
		display_name = "option_following",
		voice_event_data = {
			voice_tag_concept = VOQueryConstants.concepts.on_demand_com_wheel,
			voice_tag_id = VOQueryConstants.trigger_ids.com_wheel_vo_follow_you,
		},
	},
	[17] = {
		icon = "content/ui/materials/hud/interactions/icons/pocketable_medkit",
		display_name = "option_medicae_station",
		voice_event_data = {
			voice_tag_concept = VOQueryConstants.concepts.on_demand_vo_tag_item,
			voice_tag_id = VOQueryConstants.trigger_ids.smart_tag_vo_station_health,
		},
	},
	[18] = {
		icon = "content/ui/materials/hud/interactions/icons/pocketable_medkit",
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
			voice_tag_id = _item_tag(VOQueryConstants.trigger_ids.smart_tag_vo_pickup_deployed_medical_crate, "pup_deployed_medical_crate"),
		},
	},
	[21] = {
		icon = "content/ui/materials/hud/interactions/icons/pocketable_ammo",
		display_name = "option_ammo_crate",
		voice_event_data = {
			voice_tag_concept = VOQueryConstants.concepts.on_demand_vo_tag_item,
			voice_tag_id = _item_tag(VOQueryConstants.trigger_ids.smart_tag_vo_pickup_deployed_ammo_crate, "pup_deployed_ammo_crate"),
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
		icon = "content/ui/materials/hud/communication_wheel/icons/thanks",
		display_name = "option_sorry",
		chat_message_data = {
			channel = ChannelTags.MISSION,
			localized = false,
			text = "Sorry",
		},
		-- Darktide does not expose a dedicated "sorry" bark in the current on-demand VO tables.
		use_apology_rule = true,
		use_custom_execution = true,
	},
}

local wheel_settings = {
	[POS_BOTTOM] = "plugin_wheel_bottom",
	[POS_BOTTOM_RIGHT] = "plugin_wheel_bottom_right",
	[POS_RIGHT] = "plugin_wheel_right",
	[POS_TOP_RIGHT] = "plugin_wheel_top_right",
	[POS_TOP] = "plugin_wheel_top",
	[POS_TOP_LEFT] = "plugin_wheel_top_left",
	[POS_LEFT] = "plugin_wheel_left",
	[POS_BOTTOM_LEFT] = "plugin_wheel_bottom_left",
}

mod:hook(LocalizationManager, "localize", function(func, self, key, no_cache, context)
	if not self._string_cache.option_sorry then
		for localization_key, localized_string in pairs(localized_strings) do
			self._string_cache[localization_key] = localized_string
		end
	end

	return func(self, key, no_cache, context)
end)

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

	local chat_manager = Managers.chat
	local channel_handle = _chat_channel(chat_message_data.channel)

	if not chat_manager or not channel_handle then
		return
	end

	if chat_message_data.localized == false then
		chat_manager:send_channel_message(channel_handle, chat_message_data.text)
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
	options = options or {}

	for position, setting_id in pairs(wheel_settings) do
		local command_id = mod:get(setting_id)

		if command_id and command_id > 0 then
			options[position] = commands[command_id]
		end
	end

	func(self, options)
end)

mod:hook("HudElementSmartTagging", "_on_com_wheel_stop_callback", function(func, self, t, ui_renderer, render_settings, input_service)
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
