local mod = get_mod("ForDaEmprah")

local function get_options()
	return {
        { text = "option_nil",             value = 0 },
        { text = "option_ammo",            value = 12 },
        { text = "option_ammo_crate",      value = 21 },
        { text = "option_cryonic_rod",     value = 5 },
        { text = "option_diamantine",      value = 15 },
        { text = "option_enemy",           value = 26 },
        { text = "option_following",       value = 16 },
        { text = "option_for_the_emperor", value = 1 },
        { text = "option_go_there",        value = 25 },
        { text = "option_grenade",         value = 13 },
        { text = "option_grimoire",        value = 8 },
        { text = "option_health_booster",  value = 10 },
        { text = "option_look_there",      value = 24 },
        { text = "option_medicae_station", value = 17 },
        { text = "option_medipack",        value = 19 },
        { text = "option_medipack_down",   value = 20 },
        { text = "option_mine",            value = 11 },
        { text = "option_need_ammo",       value = 22 },
        { text = "option_need_healing",    value = 23 },
        { text = "option_no",              value = 4 },
        { text = "option_sorry",           value = 28 },
        { text = "option_plasteel",        value = 14 },
        { text = "option_power_cell",      value = 6 },
        { text = "option_relic",           value = 9 },
        { text = "option_scripture",       value = 7 },
        { text = "option_thanks",          value = 27 },
        --{ text = "option_uncharged_medicae", value = 18 },
        { text = "option_vacuum_capsule",  value = 2 },
        { text = "option_yes",             value = 3 },
	}
end

local default_wheel_values = {
    -- Mirror the stock communication wheel layout so the extra entries stay additive by default.
    plugin_wheel_bottom = 1,
    plugin_wheel_bottom_right = 23,
    plugin_wheel_right = 27,
    plugin_wheel_top_right = 22,
    plugin_wheel_top = 26,
    plugin_wheel_top_left = 25,
    plugin_wheel_left = 24,
	plugin_wheel_bottom_left = 0,
}

local vanilla_wheel_command_ids = {
	[1] = true,
	[22] = true,
	[23] = true,
	[24] = true,
	[25] = true,
	[26] = true,
	[27] = true,
}

local function chat_setting_id(option_text)
	return "chat_" .. option_text
end

local function wheel_widget(setting_id)
	return {
		setting_id = setting_id,
        type = "dropdown",
        default_value = default_wheel_values[setting_id] or 0,
        options = get_options(),
	}
end

local function get_chat_toggle_widgets()
	local widgets = {}

	for _, option in ipairs(get_options()) do
		if option.value > 0 and not vanilla_wheel_command_ids[option.value] then
			widgets[#widgets + 1] = {
				setting_id = chat_setting_id(option.text),
				type = "checkbox",
				default_value = false,
			}
		end
	end

	return widgets
end

local function get_keybind_widgets()
    local widgets = {}

    for i, option in ipairs(get_options()) do
        if option.value > 0 then
            widgets[i - 1] = {
                setting_id = option.text,
                type = "keybind",
                keybind_trigger = "pressed",
                keybind_type = "function_call",
                function_name = "keybind_" .. option.value,
                default_value = {},
            }
        end
    end

    return widgets
end

return {
    name = mod:localize("mod_title"),
    description = mod:localize("mod_description"),
    is_togglable = true,
    options = {
        widgets = {
            wheel_widget("plugin_wheel_top_left"),
            wheel_widget("plugin_wheel_top"),
            wheel_widget("plugin_wheel_top_right"),
            wheel_widget("plugin_wheel_left"),
            wheel_widget("plugin_wheel_right"),
			wheel_widget("plugin_wheel_bottom_left"),
			wheel_widget("plugin_wheel_bottom"),
			wheel_widget("plugin_wheel_bottom_right"),
			{
				setting_id = "plugin_chat_messages",
				type = "group",
				sub_widgets = get_chat_toggle_widgets(),
			},
			{
				setting_id = "plugin_keybinds",
				type = "group",
                sub_widgets = get_keybind_widgets(),
            },
        },
    },
}
