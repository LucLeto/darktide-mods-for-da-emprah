local definitions = {}

definitions.CLOCK_SLOTS = {
    "12",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "10",
    "11",
}

definitions.OPTIONS = {
    { text = "option_nil",               value = 0 },
    { text = "option_ammo",              value = 12 },
    { text = "option_ammo_crate",        value = 21 },
    { text = "option_cryonic_rod",       value = 5 },
    { text = "option_diamantine",        value = 15 },
    { text = "option_enemy",             value = 26, vanilla = true },
    { text = "option_following",         value = 16 },
    { text = "option_for_the_emperor",   value = 1,  vanilla = true },
    { text = "option_go_there",          value = 25, vanilla = true },
    { text = "option_grenade",           value = 13 },
    { text = "option_grimoire",          value = 8 },
    { text = "option_health_booster",    value = 10 },
    { text = "option_look_there",        value = 24, vanilla = true },
    { text = "option_medicae_station",   value = 17 },
    { text = "option_medipack",          value = 19 },
    { text = "option_medipack_down",     value = 20 },
    { text = "option_mine",              value = 11 },
    { text = "option_need_ammo",         value = 22, vanilla = true },
    { text = "option_need_healing",      value = 23, vanilla = true },
    { text = "option_no",                value = 4 },
    { text = "option_sorry",             value = 28 },
    { text = "option_plasteel",          value = 14 },
    { text = "option_power_cell",        value = 6 },
    { text = "option_relic",             value = 9 },
    { text = "option_scripture",         value = 7 },
    { text = "option_thanks",            value = 27, vanilla = true },
    { text = "option_uncharged_medicae", value = 18 },
    { text = "option_vacuum_capsule",    value = 2 },
    { text = "option_yes",               value = 3 },
}

definitions.DEFAULT_WHEEL_VALUES = {
    plugin_wheel_12 = 25,
    plugin_wheel_1 = 26,
    plugin_wheel_2 = 0,
    plugin_wheel_3 = 0,
    plugin_wheel_4 = 22,
    plugin_wheel_5 = 27,
    plugin_wheel_6 = 23,
    plugin_wheel_7 = 1,
    plugin_wheel_8 = 0,
    plugin_wheel_9 = 0,
    plugin_wheel_10 = 0,
    plugin_wheel_11 = 24,
}

function definitions.wheel_setting_id(clock_slot)
    return "plugin_wheel_" .. clock_slot
end

return definitions
