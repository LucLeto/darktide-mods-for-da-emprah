local mod = get_mod("ForDaEmprah")

local function get_options()
	return {
		{ text = "option_nil", value = 0 },
		{ text = "option_ammo", value = 12 },
		{ text = "option_ammo_crate", value = 21 },
		{ text = "option_cryonic_rod", value = 5 },
		{ text = "option_diamantine", value = 15 },
		{ text = "option_enemy", value = 26 },
		{ text = "option_following", value = 16 },
		{ text = "option_for_the_emperor", value = 1 },
		{ text = "option_go_there", value = 25 },
		{ text = "option_grenade", value = 13 },
		{ text = "option_grimoire", value = 8 },
		{ text = "option_health_booster", value = 10 },
		{ text = "option_look_there", value = 24 },
		{ text = "option_medicae_station", value = 17 },
		{ text = "option_medipack", value = 19 },
		{ text = "option_medipack_down", value = 20 },
		{ text = "option_mine", value = 11 },
		{ text = "option_need_ammo", value = 22 },
		{ text = "option_need_healing", value = 23 },
		{ text = "option_no", value = 4 },
		{ text = "option_sorry", value = 28 },
		{ text = "option_plasteel", value = 14 },
		{ text = "option_power_cell", value = 6 },
		{ text = "option_relic", value = 9 },
		{ text = "option_scripture", value = 7 },
		{ text = "option_thanks", value = 27 },
		--{ text = "option_uncharged_medicae", value = 18 },
		{ text = "option_vacuum_capsule", value = 2 },
		{ text = "option_yes", value = 3 },
	}
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
			{
				setting_id = "plugin_wheel_top_left",
				type = "dropdown",
				default_value = 0,
				options = get_options(),
			},
			{
				setting_id = "plugin_wheel_top",
				type = "dropdown",
				default_value = 0,
				options = get_options(),
			},
			{
				setting_id = "plugin_wheel_top_right",
				type = "dropdown",
				default_value = 0,
				options = get_options(),
			},
			{
				setting_id = "plugin_wheel_left",
				type = "dropdown",
				default_value = 0,
				options = get_options(),
			},
			{
				setting_id = "plugin_wheel_right",
				type = "dropdown",
				default_value = 0,
				options = get_options(),
			},
			{
				setting_id = "plugin_wheel_bottom_left",
				type = "dropdown",
				default_value = 0,
				options = get_options(),
			},
			{
				setting_id = "plugin_wheel_bottom",
				type = "dropdown",
				default_value = 0,
				options = get_options(),
			},
			{
				setting_id = "plugin_wheel_bottom_right",
				type = "dropdown",
				default_value = 0,
				options = get_options(),
			},
			{
				setting_id = "plugin_keybinds",
				type = "group",
				sub_widgets = get_keybind_widgets(),
			},
		},
	},
}
