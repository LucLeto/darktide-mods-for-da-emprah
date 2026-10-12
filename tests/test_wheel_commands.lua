local h = ...
local Env = h.Env

local COMMAND_VACUUM_CAPSULE = 2
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
        name = "keybinds do nothing before a HUD exists or while UI input is active",
        run = function()
            local ctx = Env.new()

            setup_squad(ctx, { [APOLOGY_PREFIX .. "psyker"] = true })
            ctx:press_keybind(COMMAND_SORRY)
            h.same(ctx.log, {}, "keybind before the HUD exists")

            local hud = ctx:new_hud()

            hud:update()
            ctx.ui_input = true
            ctx:press_keybind(COMMAND_SORRY)
            h.same(ctx.log, {}, "keybind while UI input is active")
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
        name = "wheel picks never send a mod-only chat line as a stock loc key",
        run = function()
            local ctx = Env.new()

            ctx.player_unit = "player"
            ctx:fill_wheel(5, { COMMAND_NO, COMMAND_VACUUM_CAPSULE, COMMAND_NEED_AMMO, COMMAND_SORRY, COMMAND_AMMO })
            ctx.settings.chat_option_no = true
            ctx.settings.chat_option_vacuum_capsule = false
            ctx.settings.chat_option_ammo = true

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
            }, "vanilla Need Ammo is untouched")
            h.same(ctx:pick(hud, "option_ammo"), {
                "vanilla wheel: option_ammo",
                "chat loc: loc_pickup_consumable_small_clip_01",
                "vo: smart_tag_vo_pickup_ammo",
            }, "Ammo uses its stock loc key on the vanilla path")
            h.same(ctx:pick(hud, "option_sorry"), {}, "Sorry never reaches the vanilla callback")
        end,
    },
    {
        name = "changing a chat toggle rebuilds the wheel on the next update",
        run = function()
            local ctx = Env.new()
            local mod = ctx.mod

            for setting_id, expected in pairs({
                chat_option_no = true,
                plugin_wheel_3 = true,
                option_no = false,
                plugin_chat_messages = false,
            }) do
                mod.setting_dirty = false
                mod.on_setting_changed(setting_id)
                h.equal(mod.setting_dirty == true, expected, "dirty flag after changing " .. setting_id)
            end

            mod.setting_dirty = false
            ctx.player_unit = "player"
            ctx:fill_wheel(1, { COMMAND_NO })
            ctx.settings.chat_option_no = true

            local hud = ctx:new_hud()

            hud:update()
            h.same(ctx:pick(hud, "option_no"), { "chat plain: L(option_no)", "vo: com_wheel_vo_no" }, "chat on")

            ctx.settings.chat_option_no = false
            mod.on_setting_changed("chat_option_no")
            hud:update()
            h.same(ctx:pick(hud, "option_no"), { "vanilla wheel: option_no", "vo: com_wheel_vo_no" }, "chat turned off mid-mission")
        end,
    },
}
