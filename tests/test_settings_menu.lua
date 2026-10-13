local h = ...
local Env = h.Env

local VANILLA_COMMANDS = { [1] = true, [22] = true, [23] = true, [24] = true, [25] = true, [26] = true, [27] = true }
local STOCK_CHAT_COMMANDS = { [22] = true, [23] = true, [27] = true }

local function walk_setting_ids(widgets, seen)
    for _, widget in ipairs(widgets) do
        h.check(not seen[widget.setting_id], "setting_id used twice: " .. widget.setting_id)
        seen[widget.setting_id] = true
        walk_setting_ids(widget.sub_widgets or {}, seen)
    end
end

return {
    {
        name = "Wheel Slots holds the 12 slot dropdowns with their saved setting ids",
        run = function()
            local ctx = Env.new()
            local widgets = ctx.data.options.widgets

            h.equal(#widgets, 2, "top-level widgets (DMF shows each as a tab)")
            h.equal(widgets[1].setting_id, "plugin_wheel_slots", "first tab")
            h.equal(widgets[2].setting_id, "plugin_commands", "second tab")
            h.equal(#widgets[1].sub_widgets, #Env.CLOCK_SLOTS, "slot dropdowns")

            for i, clock_slot in ipairs(Env.CLOCK_SLOTS) do
                local dropdown = widgets[1].sub_widgets[i]

                h.equal(dropdown.type, "dropdown", clock_slot .. " o'clock: type")
                h.equal(dropdown.setting_id, "plugin_wheel_" .. clock_slot, clock_slot .. " o'clock: setting_id")
                h.equal(dropdown.sub_widgets, nil, clock_slot .. " o'clock: no sub widgets")
            end
        end,
    },
    {
        name = "each command has a toggle with its keybind, and its chat toggle and message where it has chat",
        run = function()
            local ctx = Env.new()
            local command_widgets = ctx.data.options.widgets[2].sub_widgets

            h.equal(#command_widgets, 28, "command toggles")

            for _, toggle in ipairs(command_widgets) do
                local name = toggle.title
                local keybind = toggle.sub_widgets[1]
                local command_id = tonumber(keybind.function_name:match("^keybind_(%d+)$"))

                h.equal(toggle.type, "checkbox", name .. ": toggle type")
                h.equal(toggle.setting_id, name .. "_enabled", name .. ": toggle setting_id")
                h.equal(toggle.default_value, false, name .. ": toggle default")

                h.equal(keybind.type, "keybind", name .. ": keybind type")
                h.equal(keybind.setting_id, name, name .. ": keybind setting_id (unchanged, keeps saved bindings)")
                h.equal(type(ctx.mod[keybind.function_name]), "function", name .. ": keybind function exists")

                if VANILLA_COMMANDS[command_id] and not STOCK_CHAT_COMMANDS[command_id] then
                    h.equal(#toggle.sub_widgets, 1, name .. ": only a keybind (no chat line)")
                else
                    local chat = toggle.sub_widgets[2]
                    local customize = chat.sub_widgets[1]
                    local message = customize.sub_widgets[1]

                    h.equal(#toggle.sub_widgets, 2, name .. ": keybind and chat")
                    h.equal(chat.type, "checkbox", name .. ": chat type")
                    h.equal(chat.setting_id, "chat_" .. name, name .. ": chat setting_id")
                    h.equal(chat.default_value, STOCK_CHAT_COMMANDS[command_id] == true, name .. ": chat default")
                    h.equal(#chat.sub_widgets, 1, name .. ": chat children")
                    h.equal(customize.type, "checkbox", name .. ": customize type")
                    h.equal(customize.setting_id, name .. "_customize", name .. ": customize setting_id")
                    h.equal(customize.default_value, false, name .. ": customize default")
                    h.equal(#customize.sub_widgets, 1, name .. ": customize children")
                    h.equal(message.type, "text", name .. ": message type")
                    h.equal(message.setting_id, name .. "_message", name .. ": message setting_id")
                    h.equal(message.default_value, "", name .. ": message default")
                    h.equal(message.max_length, 200, name .. ": message max length (game chat box limit)")
                end
            end

            walk_setting_ids(ctx.data.options.widgets, {})
        end,
    },
    {
        name = "fresh profiles start with every command off and only stock chat lines on",
        run = function()
            local ctx = Env.new()

            for _, toggle in ipairs(ctx.data.options.widgets[2].sub_widgets) do
                h.equal(ctx.settings[toggle.setting_id], false, toggle.setting_id)
            end

            h.equal(ctx.settings.chat_option_need_ammo, true, "Need Ammo chat")
            h.equal(ctx.settings.chat_option_thanks, true, "Thanks chat")
            h.equal(ctx.settings.chat_option_no, false, "No chat")
            h.equal(ctx.settings.option_no_customize, false, "No customize")
            h.equal(ctx.settings.plugin_wheel_12, 25, "12 o'clock default (Go There)")
        end,
    },
    {
        name = "message fields start out as the default message in the player's language",
        run = function()
            local ctx = Env.new()

            h.equal(ctx.settings.option_no_message, "L(option_no)", "mod-localized default (No)")
            h.equal(ctx.settings.option_ammo_message, "T(loc_pickup_consumable_small_clip_01)", "stock pickup line (Ammo)")
            h.equal(ctx.settings.option_need_ammo_message, "T(loc_communication_wheel_need_ammo)", "stock wheel line (Need Ammo)")
            h.equal(ctx.settings.option_enemy_message, nil, "Enemy has no chat line, so no message")
        end,
    },
    {
        name = "message fields fill once the game's localization is ready, and never replace the player's text",
        run = function()
            local ctx = Env.new({
                localization_ready = false,
                settings = {
                    option_no_message = "My own text",
                    option_ammo_customize = true,
                },
            })
            local settings = ctx.settings

            h.equal(settings.option_need_ammo_message, "", "stock line before the game's strings are loaded")
            h.equal(settings.option_no_message, "My own text", "existing text is kept")

            ctx.localization_ready = true
            ctx:update_mod()
            h.equal(settings.option_need_ammo_message, "T(loc_communication_wheel_need_ammo)", "filled on a later frame")
            h.equal(settings.option_ammo_message, "", "a customized command's empty field stays empty")
            h.equal(settings.option_no_message, "My own text", "existing text is still kept")

            -- Switching "Customize Text" off with an empty field brings the default text back.
            settings.option_ammo_customize = false
            ctx.mod.on_setting_changed("option_ammo_customize")
            h.equal(settings.option_ammo_message, "T(loc_pickup_consumable_small_clip_01)", "refilled after customizing is switched off")
        end,
    },
}
