local h = ...
local Env = h.Env

local FULL_WHEEL_SCALE = 238 / 190

-- Commands 17-28 include Sorry, which has no voice_event_data and would break the vanilla wheel callback.
local function fill_full_wheel(ctx)
    local command_ids = {}

    for i = 1, 12 do
        command_ids[i] = 16 + i
    end

    ctx:fill_wheel(12, command_ids)
end

local function wheel_state(ctx, hud)
    local visible, vanilla = 0, 0

    for _, entry in ipairs(hud._entries) do
        local option = entry.option

        if option then
            visible = visible + 1

            if option.display_name:find("loc_communication_wheel_display_name_", 1, true) == 1 then
                vanilla = vanilla + 1
            end
        end
    end

    return {
        slots = ctx.hud_settings.wheel_slots,
        entries = #hud._entries,
        visible = visible,
        vanilla = vanilla,
        background = hud._ui_scenegraph.background.size[1],
        mark_offset = hud._widgets_by_name.wheel_background.style.mark.offset[2],
    }
end

local function expect_modded(ctx, hud, label)
    local state = wheel_state(ctx, hud)

    h.equal(state.slots, 12, label .. ": wheel_slots")
    h.equal(state.entries, 12, label .. ": entries")
    h.equal(state.visible, 12, label .. ": visible options")
    h.equal(state.vanilla, 0, label .. ": vanilla options")
    h.near(state.background, 250 * FULL_WHEEL_SCALE, label .. ": centre circle size")
    h.near(state.mark_offset, -133 * FULL_WHEEL_SCALE, label .. ": arrow offset")
end

local function expect_vanilla(ctx, hud, label)
    local state = wheel_state(ctx, hud)

    h.equal(state.slots, 8, label .. ": wheel_slots")
    h.equal(state.entries, 8, label .. ": entries")
    h.equal(state.visible, 7, label .. ": visible options")
    h.equal(state.vanilla, 7, label .. ": vanilla options")
    h.near(state.background, 250, label .. ": centre circle size")
    h.near(state.mark_offset, -133, label .. ": arrow offset")

    -- Every restored option must survive the vanilla callback (it indexes voice_event_data unconditionally).
    for _, entry in ipairs(hud._entries) do
        if entry.option then
            ctx:pick(hud, entry.option.display_name)
        end
    end
end

return {
    {
        name = "disabling mid-mission restores the vanilla wheel, re-enabling brings the mod wheel back",
        run = function()
            local ctx = Env.new()

            fill_full_wheel(ctx)

            local hud = ctx:new_hud()

            hud:update()
            expect_modded(ctx, hud, "mission start")

            ctx:set_enabled(false, false)
            expect_vanilla(ctx, hud, "disabled mid-mission")

            hud:update()
            expect_vanilla(ctx, hud, "next frame while disabled")

            ctx:set_enabled(true, false)
            hud:update()
            expect_modded(ctx, hud, "re-enabled")

            ctx:set_enabled(false, false)
            expect_vanilla(ctx, hud, "disabled again")
        end,
    },
    {
        name = "starting disabled keeps the vanilla wheel until the mod is enabled",
        run = function()
            local ctx = Env.new({ enabled = false })

            fill_full_wheel(ctx)
            h.equal(ctx.hud_settings.wheel_slots, 8, "wheel_slots after the initial on_disabled")

            local hud = ctx:new_hud()

            hud:update()
            expect_vanilla(ctx, hud, "mission start while disabled")

            ctx:set_enabled(true, false)
            hud:update()
            expect_modded(ctx, hud, "enabled mid-mission")

            ctx:set_enabled(false, false)
            expect_vanilla(ctx, hud, "disabled again")

            expect_vanilla(ctx, ctx:new_hud(), "next mission while disabled")
        end,
    },
}
