local h = ...
local Env = h.Env

local SLOT_COUNTS = { 12, 10, 8, 7, 5, 3 }

local function slice_style_ids(definitions)
    local entry_definition = definitions.entry_widget_definition
    local style_ids = {}

    for _, pass in ipairs(entry_definition.passes) do
        local value = pass.value_id and entry_definition.content[pass.value_id]

        if type(value) == "string" and value:find("/communication_wheel/slice_", 1, true) then
            style_ids[#style_ids + 1] = pass.style_id
        end
    end

    return style_ids
end

local function expected_scale(count)
    return (190 + math.max(count - 8, 0) * 12) / 190
end

local function check_wheel(ctx, hud, count, label, vanilla_entries)
    local definitions = ctx.definitions
    local style_ids = slice_style_ids(definitions)
    local base_styles = definitions.entry_widget_definition.style
    local scale = expected_scale(count)
    local width_scale = math.tan(math.pi / math.max(count, 4)) / math.tan(math.pi / 8)

    h.equal(#style_ids, 3, label .. ": slice passes in the entry definition")

    -- Vanilla entries are rebuilt by vanilla code, which never reads the mod's scale field.
    if not vanilla_entries then
        h.near(hud._mod_wheel_scale, scale, label .. ": wheel scale")
    end

    for _, entry in ipairs(hud._entries) do
        for _, style_id in ipairs(style_ids) do
            local base_size = base_styles[style_id].size
            local style = entry.widget.style[style_id]

            h.near(style.size[1], base_size[1] * scale * width_scale, label .. ": " .. style_id .. " width")
            h.near(style.size[2], base_size[2] * scale, label .. ": " .. style_id .. " height")

            -- Fresh vanilla styles leave the pivot empty; rotated_texture fills it from the size on first draw.
            if not (vanilla_entries and style.pivot[1] == nil and style.pivot[2] == nil) then
                h.near(style.pivot[1], style.size[1] * 0.5, label .. ": " .. style_id .. " pivot x")
                h.near(style.pivot[2], style.size[2] * 0.5, label .. ": " .. style_id .. " pivot y")
            end
        end
    end

    -- Horizontal scaling keeps the wedge edges radial, so the slice spans exactly one slot (at most 90 degrees).
    local slice_id = style_ids[#style_ids]
    local relative_width = hud._entries[1].widget.style[slice_id].size[1] / (base_styles[slice_id].size[1] * scale)
    local wedge_degrees = 2 * math.deg(math.atan(relative_width * math.tan(math.pi / 8)))

    h.near(wedge_degrees, 360 / math.max(count, 4), label .. ": wedge angle")

    local base_background = definitions.scenegraph_definition.background.size
    local base_mark = definitions.widget_definitions.wheel_background.style.mark
    local mark = hud._widgets_by_name.wheel_background.style.mark

    h.near(hud._ui_scenegraph.background.size[1], base_background[1] * scale, label .. ": centre circle width")
    h.near(hud._ui_scenegraph.background.size[2], base_background[2] * scale, label .. ": centre circle height")

    for _, field in ipairs({ "size", "pivot", "offset" }) do
        h.near(mark[field][1], base_mark[field][1] * scale, label .. ": arrow " .. field .. " x")
        h.near(mark[field][2], base_mark[field][2] * scale, label .. ": arrow " .. field .. " y")
    end
end

local function check_scaling(opts)
    local ctx = Env.new(opts)
    local untouched = Env.clone({
        entry_style = ctx.definitions.entry_widget_definition.style,
        background = ctx.definitions.scenegraph_definition.background.size,
        mark = ctx.definitions.widget_definitions.wheel_background.style.mark,
    })
    local hud = ctx:new_hud()

    hud:update()

    for _, count in ipairs(SLOT_COUNTS) do
        ctx:fill_wheel(count)
        hud:_populate_wheel()
        check_wheel(ctx, hud, count, count .. " slots")
    end

    ctx:fill_wheel(12)
    hud:_populate_wheel()
    hud:_populate_wheel()
    hud:_populate_wheel()
    check_wheel(ctx, hud, 12, "12 slots after repeated rebuilds")

    ctx:set_enabled(false, false)
    check_wheel(ctx, hud, 8, "after disabling", true)

    local after = Env.clone({
        entry_style = ctx.definitions.entry_widget_definition.style,
        background = ctx.definitions.scenegraph_definition.background.size,
        mark = ctx.definitions.widget_definitions.wheel_background.style.mark,
    })

    for _, style_id in ipairs(slice_style_ids(ctx.definitions)) do
        h.equal(after.entry_style[style_id].size[1], untouched.entry_style[style_id].size[1], style_id .. " definition width untouched")
        h.equal(after.entry_style[style_id].size[2], untouched.entry_style[style_id].size[2], style_id .. " definition height untouched")
    end

    h.equal(after.background[1], untouched.background[1], "background definition untouched")
    h.equal(after.mark.offset[2], untouched.mark.offset[2], "arrow definition untouched")
end

return {
    {
        name = "slices span exactly one slot and the wheel scales with the radius",
        run = function()
            check_scaling()
        end,
    },
    {
        name = "same, against the game's real smart tagging definitions",
        run = function()
            if not h.darktide_source then
                h.skip("pass a Darktide source path or set DARKTIDE_SOURCE")
            end

            check_scaling({ darktide_source = h.darktide_source })
        end,
    },
    {
        name = "hover starts outside the scaled centre circle",
        run = function()
            local ctx = Env.new()

            ctx:fill_wheel(12)

            local hud = ctx:new_hud()
            local cursor = { 960, 540 }
            local input_service = {
                get = function()
                    return cursor
                end,
            }

            hud:update()

            local function hovered_after_cursor_up(distance)
                cursor[1], cursor[2] = 960, 540 - distance
                hud:_update_wheel_presentation(0, 0, nil, { scale = 1 }, input_service)

                local hovered = {}

                for i, entry in ipairs(hud._entries) do
                    if entry.widget.content.hotspot.force_hover then
                        hovered[#hovered + 1] = tostring(i)
                    end
                end

                return hovered
            end

            -- The vanilla threshold is 130; at 12 slots the centre circle is 1.25x larger, so 150 is still inside it.
            h.same(hovered_after_cursor_up(150), {}, "cursor inside the scaled centre circle")
            h.same(hovered_after_cursor_up(200), { "1" }, "cursor on the 12 o'clock entry")
        end,
    },
}
