local mod = get_mod("ForDaEmprah")
local definitions = require("scripts/mods/ForDaEmprah/ForDaEmprah_definitions")

local ipairs = ipairs

local CLOCK_SLOTS = definitions.CLOCK_SLOTS
local OPTIONS = definitions.OPTIONS
local DEFAULT_WHEEL_VALUES = definitions.DEFAULT_WHEEL_VALUES

local function get_wheel_widgets()
    local widgets = {}

    for i, clock_slot in ipairs(CLOCK_SLOTS) do
        local setting_id = definitions.wheel_setting_id(clock_slot)

        widgets[i] = {
            setting_id = setting_id,
            type = "dropdown",
            default_value = DEFAULT_WHEEL_VALUES[setting_id] or 0,
            options = OPTIONS,
        }
    end

    return widgets
end

local function get_chat_toggle_widgets()
    local widgets = {}

    for _, option in ipairs(OPTIONS) do
        if option.value > 0 and option.vanilla ~= true then
            widgets[#widgets + 1] = {
                setting_id = "chat_" .. option.text,
                title = option.text,
                type = "checkbox",
                default_value = false,
            }
        end
    end

    return widgets
end

local function get_keybind_widgets()
    local widgets = {}

    for i, option in ipairs(OPTIONS) do
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

local function get_widgets()
    local widgets = get_wheel_widgets()

    widgets[#widgets + 1] = {
        setting_id = "plugin_chat_messages",
        type = "group",
        sub_widgets = get_chat_toggle_widgets(),
    }

    widgets[#widgets + 1] = {
        setting_id = "plugin_keybinds",
        type = "group",
        sub_widgets = get_keybind_widgets(),
    }

    return widgets
end

return {
    name = mod:localize("mod_title"),
    description = mod:localize("mod_description"),
    is_togglable = true,
    options = {
        widgets = get_widgets(),
    },
}
