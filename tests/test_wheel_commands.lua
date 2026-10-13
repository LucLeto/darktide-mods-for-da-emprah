local h = ...
local Env = h.Env

local COMMAND_VACUUM_CAPSULE = 2
local COMMAND_YES = 3
local COMMAND_NO = 4
local COMMAND_AMMO = 12
local COMMAND_NEED_AMMO = 22
local COMMAND_SORRY = 28
local APOLOGY_PREFIX = "response_for_friendly_fire_from_veteran_to_"

-- Local veteran with a zealot far away and a psyker close by.
local function setup_squad(ctx, rules)
    ctx.player_unit = "player"
    ctx.players = {
        { player_unit = "player" },
        { player_unit = "far_zealot" },
        { player_unit = "near_psyker" },
        { player_unit = nil },
    }
    ctx.alive.player, ctx.alive.far_zealot, ctx.alive.near_psyker = true, true, true
    ctx.positions.player = Env.vector(0, 0, 0)
    ctx.positions.far_zealot = Env.vector(30, 0, 0)
    ctx.positions.near_psyker = Env.vector(3, 0, 0)
    ctx.dialogue.player = Env.dialogue_extension("veteran", rules)
    ctx.dialogue.far_zealot = Env.dialogue_extension("zealot", {})
    ctx.dialogue.near_psyker = Env.dialogue_extension("psyker", {})
end

-- Switches a command's toggle on and sets its chat toggle (nil keeps the current value). A message also
-- switches "Customize Text" on.
local function configure(ctx, display_name, chat, message)
    ctx.settings[display_name .. "_enabled"] = true

    if chat ~= nil then
        ctx.settings["chat_" .. display_name] = chat
    end

    if message ~= nil then
        ctx.settings[display_name .. "_customize"] = true
        ctx.settings[display_name .. "_message"] = message
    end
end

return {
    {
        name = "Sorry keybind plays the apology for the nearest teammate without reading POSITION_LOOKUP",
        run = function()
            local ctx = Env.new()

            setup_squad(ctx, {
                [APOLOGY_PREFIX .. "zealot"] = true,
                [APOLOGY_PREFIX .. "psyker"] = true,
                [APOLOGY_PREFIX .. "ogryn"] = true,
            })
            configure(ctx, "option_sorry")

            local hud = ctx:new_hud()

            hud:update()
            ctx:clear_log()
            ctx:press_keybind(COMMAND_SORRY)
            h.same(ctx.log, { "vo local: " .. APOLOGY_PREFIX .. "psyker" }, "apology with the psyker nearest")

            ctx.dialogue.player = Env.dialogue_extension("veteran", { [APOLOGY_PREFIX .. "zealot"] = true })
            ctx:clear_log()
            ctx:press_keybind(COMMAND_SORRY)
            h.same(ctx.log, { "vo local: " .. APOLOGY_PREFIX .. "zealot" }, "apology when only the zealot rule exists")
        end,
    },
    {
        name = "keybinds do nothing before a HUD exists, while UI input is active or while their command is off",
        run = function()
            local ctx = Env.new()

            setup_squad(ctx, { [APOLOGY_PREFIX .. "psyker"] = true })
            configure(ctx, "option_sorry")
            ctx:press_keybind(COMMAND_SORRY)
            h.same(ctx.log, {}, "keybind before the HUD exists")

            local hud = ctx:new_hud()

            hud:update()
            ctx.ui_input = true
            ctx:press_keybind(COMMAND_SORRY)
            h.same(ctx.log, {}, "keybind while UI input is active")

            ctx.ui_input = false
            ctx.settings.option_sorry_enabled = false
            ctx:press_keybind(COMMAND_SORRY)
            h.same(ctx.log, {}, "keybind while Sorry is switched off")
        end,
    },
    {
        name = "gamepad wheel check runs (INSTANT_WHEEL_THRESHOLD is defined)",
        run = function()
            local ctx = Env.new({ gamepad = true })
            local hud = ctx:new_hud()
            local input_service = {
                get = function()
                    return Env.vector(1, 0, 0)
                end,
            }

            hud._com_wheel_context.camera_still_on_tag = true
            h.equal(hud:_should_draw_wheel_gamepad(input_service), true, "full stick deflection opens the wheel")

            hud._com_wheel_context.camera_still_on_tag = false
            h.equal(hud:_should_draw_wheel_gamepad(input_service), false, "camera moved since the press")
        end,
    },
    {
        name = "wheel picks follow each command's toggle and chat setting, and never send a mod key as a loc key",
        run = function()
            local ctx = Env.new()

            ctx.player_unit = "player"
            ctx:fill_wheel(6, { COMMAND_NO, COMMAND_VACUUM_CAPSULE, COMMAND_NEED_AMMO, COMMAND_SORRY, COMMAND_AMMO, COMMAND_YES })
            configure(ctx, "option_no", true)
            configure(ctx, "option_vacuum_capsule", false)
            configure(ctx, "option_ammo", true)
            -- Chat on, but the command itself is switched off, so its extras don't apply.
            ctx.settings.chat_option_yes = true

            local hud = ctx:new_hud()

            h.same(ctx:pick(hud, "option_no"), {
                "chat plain: L(option_no)",
                "vo: com_wheel_vo_no",
            }, "No with chat on goes through the mod and sends localized text")
            h.same(ctx:pick(hud, "option_vacuum_capsule"), {
                "vanilla wheel: option_vacuum_capsule",
                "vo: smart_tag_vo_pickup_container",
            }, "Vacuum Capsule with chat off stays on the vanilla path")
            h.same(ctx:pick(hud, "option_need_ammo"), {
                "vanilla wheel: option_need_ammo",
                "chat loc: loc_communication_wheel_need_ammo",
                "vo: com_wheel_vo_need_ammo",
            }, "vanilla Need Ammo keeps its stock line while switched off")
            h.same(ctx:pick(hud, "option_ammo"), {
                "vanilla wheel: option_ammo",
                "chat loc: loc_pickup_consumable_small_clip_01",
                "vo: smart_tag_vo_pickup_ammo",
            }, "Ammo uses its stock loc key on the vanilla path")
            h.same(ctx:pick(hud, "option_yes"), {
                "vanilla wheel: option_yes",
                "vo: com_wheel_vo_yes",
            }, "Yes is switched off, so its chat toggle doesn't apply")
            h.same(ctx:pick(hud, "option_sorry"), {}, "Sorry never reaches the vanilla callback")
        end,
    },
    {
        name = "custom messages replace the default, trimmed, and empty ones fall back to it",
        run = function()
            local ctx = Env.new()

            ctx.player_unit = "player"
            ctx:fill_wheel(3, { COMMAND_NO, COMMAND_AMMO, COMMAND_NEED_AMMO })
            configure(ctx, "option_no", true, "  Nope.  ")
            configure(ctx, "option_ammo", true, "   ")
            configure(ctx, "option_need_ammo", nil, "Out of ammo!")

            local hud = ctx:new_hud()

            hud:update()
            h.same(ctx:pick(hud, "option_no"), { "chat plain: Nope.", "vo: com_wheel_vo_no" }, "No with a custom message")
            h.same(ctx:pick(hud, "option_ammo"), {
                "vanilla wheel: option_ammo",
                "chat loc: loc_pickup_consumable_small_clip_01",
                "vo: smart_tag_vo_pickup_ammo",
            }, "a blank message falls back to the stock loc key")
            h.same(ctx:pick(hud, "option_need_ammo"), {
                "chat plain: Out of ammo!",
                "vo: com_wheel_vo_need_ammo",
            }, "a vanilla command with a custom message goes through the mod")

            ctx:clear_log()
            ctx:press_keybind(COMMAND_NO)
            h.same(ctx.log, { "chat plain: Nope.", "vo: com_wheel_vo_no" }, "the keybind sends the same custom message")

            -- With "Customize Text" off, the field's text is ignored and the default message is sent.
            ctx.settings.option_no_customize = false
            ctx.mod.on_setting_changed("option_no_customize")
            hud:update()
            h.equal(ctx.settings.option_no_message, "  Nope.  ", "the field keeps the player's text")
            h.same(ctx:pick(hud, "option_no"), { "chat plain: L(option_no)", "vo: com_wheel_vo_no" }, "No with customizing off")

            ctx.settings.chat_option_need_ammo = false
            ctx.mod.on_setting_changed("chat_option_need_ammo")
            hud:update()
            h.same(ctx:pick(hud, "option_need_ammo"), {
                "vanilla wheel: option_need_ammo",
                "vo: com_wheel_vo_need_ammo",
            }, "vanilla Need Ammo with its chat switched off")
        end,
    },
    {
        name = "changing any setting rebuilds the wheel on the next update",
        run = function()
            local ctx = Env.new()
            local mod = ctx.mod

            for _, setting_id in ipairs({ "plugin_wheel_3", "option_no_enabled", "chat_option_no", "option_no_message" }) do
                mod.setting_dirty = false
                mod.on_setting_changed(setting_id)
                h.equal(mod.setting_dirty, true, "dirty flag after changing " .. setting_id)
            end

            mod.setting_dirty = false
            ctx.player_unit = "player"
            ctx:fill_wheel(1, { COMMAND_NO })
            configure(ctx, "option_no", true)

            local hud = ctx:new_hud()

            hud:update()
            h.same(ctx:pick(hud, "option_no"), { "chat plain: L(option_no)", "vo: com_wheel_vo_no" }, "chat on")

            ctx.settings.option_no_enabled = false
            mod.on_setting_changed("option_no_enabled")
            hud:update()
            h.same(ctx:pick(hud, "option_no"), { "vanilla wheel: option_no", "vo: com_wheel_vo_no" }, "No switched off mid-mission")
        end,
    },
    {
        name = "command keybinds use the command's own chat toggle, whether or not it is on the wheel",
        run = function()
            local ctx = Env.new()

            setup_squad(ctx, { [APOLOGY_PREFIX .. "psyker"] = true })
            configure(ctx, "option_no", true)
            configure(ctx, "option_ammo", false)
            configure(ctx, "option_need_ammo")
            configure(ctx, "option_sorry", true)

            local hud = ctx:new_hud()

            hud:update()
            ctx:clear_log()
            ctx:press_keybind(COMMAND_NO)
            ctx:press_keybind(COMMAND_AMMO)
            ctx:press_keybind(COMMAND_NEED_AMMO)
            ctx:press_keybind(COMMAND_SORRY)
            h.same(ctx.log, {
                "chat plain: L(option_no)",
                "vo: com_wheel_vo_no",
                "vo: smart_tag_vo_pickup_ammo",
                "chat loc: loc_communication_wheel_need_ammo",
                "vo: com_wheel_vo_need_ammo",
                "chat plain: L(option_sorry)",
                "vo local: " .. APOLOGY_PREFIX .. "psyker",
            }, "No (chat on), Ammo (chat off), vanilla Need Ammo (stock chat), Sorry (chat on, not on the wheel)")
        end,
    },
}
