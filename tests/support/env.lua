-- Fake Darktide + DMF environment for loading ForDaEmprah outside the game.
-- Every Env.new() loads the mod files fresh, so module-level state never leaks between tests.

local Env = {}

Env.CLOCK_SLOTS = { "12", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11" }

local function clone(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}

    for key, inner in pairs(value) do
        copy[key] = clone(inner)
    end

    return setmetatable(copy, getmetatable(value))
end

Env.clone = clone

local vector_mt = {}

vector_mt.__mul = function(a, b)
    return setmetatable({ a[1] * b, a[2] * b, a[3] * b }, vector_mt)
end

function Env.vector(x, y, z)
    return setmetatable({ x, y, z or 0 }, vector_mt)
end

local identity_mt = {
    __index = function(_, key)
        return key
    end,
}

-- Same as scripts/foundation/utilities/math.lua.
math.angle = function(x1, y1, x2, y2)
    return math.atan2(y2 - y1, x2 - x1)
end

math.distance_2d = function(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1

    return math.sqrt(dx * dx + dy * dy)
end

math.smoothstep = function(value, min, max)
    local x = math.min(math.max((value - min) / (max - min), 0), 1)

    return x * x * x * (x * (x * 6 - 15) + 10)
end

local SLICE_MATERIAL = "content/ui/materials/hud/communication_wheel/slice_eighth"

-- Mirrors what UIWidget.create_definition builds from hud_element_smart_tagging_definitions.lua.
local function stub_definitions()
    local function slice_style()
        return { size = { 190, 140 }, pivot = {} }
    end

    return {
        entry_widget_definition = {
            passes = {
                { pass_type = "hotspot", content_id = "hotspot" },
                { pass_type = "texture", value_id = "icon", style_id = "style_id_2" },
                { pass_type = "rotated_texture", value_id = "value_id_3", style_id = "style_id_3" },
                { pass_type = "rotated_texture", value_id = "value_id_4", style_id = "style_id_4" },
                { pass_type = "rotated_texture", value_id = "value_id_5", style_id = "style_id_5" },
                { pass_type = "rect", style_id = "style_id_6" },
                { pass_type = "text", value_id = "text", style_id = "style_id_7" },
            },
            content = {
                hotspot = {},
                icon = "content/ui/materials/hud/communication_wheel/icons/enemy",
                value_id_3 = SLICE_MATERIAL .. "_line",
                value_id_4 = SLICE_MATERIAL .. "_highlight",
                value_id_5 = SLICE_MATERIAL,
                text = "Button",
            },
            style = {
                style_id_2 = { size = { 128, 128 } },
                style_id_3 = slice_style(),
                style_id_4 = slice_style(),
                style_id_5 = slice_style(),
                style_id_6 = {},
                style_id_7 = {},
            },
        },
        scenegraph_definition = {
            background = { size = { 250, 250 } },
        },
        widget_definitions = {
            wheel_background = {
                content = {},
                style = {
                    mark = {
                        size = { 20, 28 },
                        pivot = { 10, 147 },
                        offset = { 0, -133, 6 },
                        color = { 255, 255, 255, 255 },
                    },
                },
            },
        },
    }
end

-- Modules loaded from a Darktide source checkout so the definitions come from the game's real UIWidget.
local REAL_MODULES = {
    ["scripts/managers/ui/ui_widget"] = true,
    ["scripts/ui/default_pass_styles"] = true,
    ["scripts/ui/default_pass_values"] = true,
    ["scripts/ui/hud/elements/smart_tagging/hud_element_smart_tagging_definitions"] = true,
}

local function install_darktide_table_helpers()
    table.clone = clone
    table.merge = function(destination, source)
        for key, value in pairs(source) do
            destination[key] = value
        end

        return destination
    end
    table.merge_recursive = function(destination, source)
        for key, value in pairs(source) do
            if type(value) == "table" and type(destination[key]) == "table" then
                table.merge_recursive(destination[key], value)
            else
                destination[key] = value
            end
        end

        return destination
    end
    table.set = function(list)
        local set = {}

        for _, value in ipairs(list) do
            set[value] = true
        end

        return set
    end
    math.clamp01 = function(x)
        return math.min(math.max(x, 0), 1)
    end
    GuiMaterialFlag = {}
    PLATFORM = "win32"
    settings = function(_, settings_table)
        return settings_table
    end
end

-- Like DMF, only settings that are not saved yet get their default.
local function apply_widget_defaults(widgets, store)
    for _, widget in ipairs(widgets) do
        if widget.default_value ~= nil and store[widget.setting_id] == nil then
            store[widget.setting_id] = clone(widget.default_value)
        end

        if widget.sub_widgets then
            apply_widget_defaults(widget.sub_widgets, store)
        end
    end
end

-- The seven options vanilla HudElementSmartTagging.init builds and passes to _populate_wheel.
function Env.vanilla_wheel_options()
    local names = { "cheer", "need_health", "thanks", "need_ammo", "enemy", "location", "attention" }
    local options = {}

    for i, name in ipairs(names) do
        options[i] = {
            display_name = "loc_communication_wheel_display_name_" .. name,
            voice_event_data = { voice_tag_id = "com_wheel_vo_" .. name },
        }
    end

    return options
end

function Env.dialogue_extension(class_name, rules)
    return {
        _vo_choice = rules,
        vo_class_name = function()
            return class_name
        end,
        has_dialogue = function(_, rule_name)
            return rules[rule_name] == true
        end,
    }
end

-- opts.settings: saved settings the mod starts with (copied).
-- opts.localization_ready (default true): whether the game's Localize returns text yet.
-- opts.enabled (default true): mod state DMF applies right after loading.
-- opts.gamepad: InputDevice.gamepad_active.
-- opts.darktide_source: load the real smart tagging definitions from this checkout.
function Env.new(opts)
    opts = opts or {}

    local ctx = {
        log = {},
        settings = clone(opts.settings or {}),
        hooks = {},
        safe_hooks = {},
        hooks_active = true,
        players = {},
        alive = {},
        positions = {},
        dialogue = {},
        player_unit = nil,
        ui_input = false,
        localization_ready = opts.localization_ready ~= false,
    }
    local hooks, safe_hooks = ctx.hooks, ctx.safe_hooks

    local function record(entry)
        ctx.log[#ctx.log + 1] = entry
    end

    local hud_settings = { anim_speed = 8, cursor_tag_radius = 10, max_radius = 190, min_radius = 185, scan_delay = 0.2, wheel_slots = 8 }
    local vo = {
        on_demand_vo_event = function(_, _, trigger_id)
            record("vo: " .. tostring(trigger_id))
        end,
        play_local_vo_event = function(_, rule_name)
            record("vo local: " .. rule_name)
        end,
    }
    local stubs = {
        ["scripts/foundation/managers/chat/chat_manager_constants"] = { ChannelTag = { MISSION = "mission" } },
        ["scripts/ui/hud/elements/smart_tagging/hud_element_smart_tagging_settings"] = hud_settings,
        ["scripts/managers/input/input_device"] = { gamepad_active = opts.gamepad == true },
        ["scripts/settings/dialogue/vo_query_constants"] = {
            concepts = setmetatable({}, identity_mt),
            trigger_ids = setmetatable({}, identity_mt),
        },
        ["scripts/utilities/vo"] = vo,
    }
    local source_dir = opts.darktide_source

    if source_dir then
        install_darktide_table_helpers()

        local font = { text_color = { 255, 255, 255, 255 }, font_size = 20, font_type = "proxima_nova_bold" }

        stubs["scripts/managers/ui/ui_font_settings"] = setmetatable({}, {
            __index = function()
                return clone(font)
            end,
        })
        stubs["scripts/settings/ui/ui_sound_events"] = setmetatable({}, identity_mt)
        stubs["scripts/settings/ui/ui_workspace_settings"] = { screen = { size = { 1920, 1080 }, position = { 0, 0, 0 } } }
        stubs["scripts/settings/ui/ui_hud_settings"] = {
            get_hud_color = function()
                return { 255, 255, 255, 255 }
            end,
        }
        stubs["scripts/utilities/ui/colors"] = {}
        stubs["scripts/managers/ui/ui_passes"] = {}
        stubs["scripts/managers/ui/ui_scenegraph"] = {}
        stubs["scripts/managers/ui/ui_animation"] = {}
    else
        stubs["scripts/ui/hud/elements/smart_tagging/hud_element_smart_tagging_definitions"] = stub_definitions()
    end

    local loaded = {}

    require = function(path)
        local module = loaded[path]

        if module == nil then
            if source_dir and REAL_MODULES[path] then
                module = dofile(source_dir .. "/" .. path .. ".lua")
            else
                module = stubs[path]
            end

            assert(module ~= nil, "unexpected require: " .. path)
            loaded[path] = module
        end

        return module
    end

    -- DMF
    local mod = {}

    function mod:get(setting_id)
        return ctx.settings[setting_id]
    end

    function mod:set(setting_id, value)
        ctx.settings[setting_id] = value
    end

    function mod:localize(key)
        return "L(" .. key .. ")"
    end

    function mod:hook(_, method, handler)
        hooks[method] = handler
    end

    function mod:hook_safe(_, method, handler)
        safe_hooks[method] = handler
    end

    get_mod = function()
        return mod
    end

    -- Engine and game globals the mod touches
    Vector3 = {
        distance_squared = function(a, b)
            local dx, dy, dz = a[1] - b[1], a[2] - b[2], a[3] - b[3]

            return dx * dx + dy * dy + dz * dz
        end,
        length = function(v)
            return math.sqrt(v[1] * v[1] + v[2] * v[2] + v[3] * v[3])
        end,
    }
    Vector3Box = {
        unbox = function(box)
            return box
        end,
    }
    Unit = {
        world_position = function(unit)
            return assert(ctx.positions[unit], "no position for unit " .. tostring(unit))
        end,
    }
    ScriptUnit = {
        has_extension = function(unit, system_name)
            return system_name == "dialogue_system" and ctx.dialogue[unit] or nil
        end,
    }
    -- Its Vector3s are frame temporaries that are stale outside the gameplay update (keybind callbacks).
    POSITION_LOOKUP = setmetatable({}, {
        __index = function()
            error("POSITION_LOOKUP must not be read from mod callbacks")
        end,
    })
    ALIVE = ctx.alive
    RESOLUTION_LOOKUP = { width = 1920, height = 1080 }
    -- Like LocalizationManager.localize: "" until the game's strings are loaded.
    Localize = function(key)
        return ctx.localization_ready and "T(" .. key .. ")" or ""
    end
    Managers = {
        chat = {
            connected_chat_channels = function()
                return { channel_1 = { tag = "mission" } }
            end,
            send_channel_message = function(_, _, text)
                record("chat plain: " .. text)
            end,
            send_loc_channel_message = function(_, _, key)
                record("chat loc: " .. key)
            end,
        },
        event = {
            trigger = function() end,
        },
        input = {
            cursor_active = function()
                return false
            end,
        },
        ui = {
            using_input = function()
                return ctx.ui_input
            end,
        },
        state = {
            player_unit_spawn = {
                alive_players = function()
                    return ctx.players
                end,
            },
        },
    }

    -- dmf new_mod: data first (DMF writes the option defaults while initializing it), then the script.
    local mod_dir = assert(Env.mod_dir, "Env.mod_dir is not set")
    local data = dofile(mod_dir .. "/ForDaEmprah_data.lua")

    apply_widget_defaults(data.options.widgets, ctx.settings)
    dofile(mod_dir .. "/ForDaEmprah.lua")

    local definitions = require("scripts/ui/hud/elements/smart_tagging/hud_element_smart_tagging_definitions")

    ctx.mod = mod
    ctx.data = data
    ctx.hud_settings = hud_settings
    ctx.definitions = definitions

    -- Fake HudElementSmartTagging: vanilla behaviour, with DMF hooks applied while the mod is enabled.
    local Hud = {}

    Hud.__index = Hud

    local function new_widget(definition)
        return {
            content = clone(definition.content or {}),
            style = clone(definition.style or {}),
            offset = { 0, 0, 0 },
            passes = definition.passes,
        }
    end

    local function hookable(method, vanilla)
        Hud[method] = function(self, ...)
            local hook = ctx.hooks_active and hooks[method]

            if hook then
                return hook(vanilla, self, ...)
            end

            return vanilla(self, ...)
        end
    end

    hookable("_setup_entries", function(self, num_entries)
        local entries = {}

        for i = 1, num_entries do
            local widget = new_widget(definitions.entry_widget_definition)

            widget.content.hotspot = widget.content.hotspot or {}
            entries[i] = { widget = widget }
        end

        self._entries = entries
    end)

    hookable("_populate_wheel", function(self, options)
        for i = 1, hud_settings.wheel_slots do
            local entry = self._entries[i]

            entry.widget.content.visible = options[i] ~= nil
            entry.option = options[i]
        end
    end)

    hookable("_update_widget_locations", function() end)

    hookable("_update_wheel_presentation", function() end)

    hookable("_should_draw_wheel_gamepad", function()
        return false
    end)

    hookable("_is_wheel_entry_hovered", function(self)
        return self._hovered_entry
    end)

    hookable("_on_com_wheel_stop_callback", function(self, t)
        local entry = self._wheel_active and self:_is_wheel_entry_hovered(t)
        local option = entry and entry.option

        if not option then
            return
        end

        record("vanilla wheel: " .. option.display_name)

        if option.chat_message_data then
            Managers.chat:send_loc_channel_message("channel_1", option.chat_message_data.text, nil)
        end

        if option.voice_event_data then
            vo.on_demand_vo_event(ctx.player_unit, nil, option.voice_event_data.voice_tag_id)
        end

        -- Vanilla registers telemetry with option.voice_event_data.voice_tag_id unconditionally.
        if not option.voice_event_data then
            error("vanilla wheel callback indexed missing voice_event_data")
        end
    end)

    function Hud:update()
        self:_update_widget_locations()

        local hook = ctx.hooks_active and safe_hooks.update

        if hook then
            hook(self)
        end
    end

    function Hud:destroy()
        local hook = ctx.hooks_active and safe_hooks.destroy

        if hook then
            hook(self)
        end
    end

    function Hud:_set_scenegraph_size(id, width, height)
        local size = self._ui_scenegraph[id].size

        size[1] = width or size[1]
        size[2] = height or size[2]
    end

    function Hud:_find_raycast_targets()
        return { static_hit_position = "hit_position" }
    end

    function Hud:_trigger_smart_tag(tag_type)
        record("smart tag: " .. tag_type)
    end

    -- Vanilla HudElementSmartTagging.init
    function ctx:new_hud()
        local hud = setmetatable({}, Hud)

        hud._ui_scenegraph = { background = { size = clone(definitions.scenegraph_definition.background.size) } }
        hud._widgets_by_name = { wheel_background = new_widget(definitions.widget_definitions.wheel_background) }
        hud._com_wheel_context = {}
        hud._wheel_active_progress = 1
        hud._parent = {
            player_unit = function()
                return ctx.player_unit
            end,
        }

        hud:_setup_entries(hud_settings.wheel_slots)
        hud:_populate_wheel(Env.vanilla_wheel_options())

        return hud
    end

    -- dmf.set_mod_state: hooks are switched before the event runs.
    function ctx:set_enabled(enabled, initial_call)
        self.hooks_active = enabled

        if enabled then
            mod.on_enabled(initial_call)
        else
            mod.on_disabled(initial_call)
        end
    end

    -- DMF only calls function_call keybinds of enabled mods.
    function ctx:press_keybind(command_id)
        if self.hooks_active then
            mod["keybind_" .. command_id]()
        end
    end
    -- DMF calls mod.update every frame for enabled mods.
    function ctx:update_mod()
        if self.hooks_active and mod.update then
            mod.update(0)
        end
    end

    function ctx:clear_log()
        for i = #self.log, 1, -1 do
            self.log[i] = nil
        end
    end

    -- Fills the first `count` clock slots with the given command ids (or 1..count) and clears the rest.
    function ctx:fill_wheel(count, command_ids)
        for i, clock_slot in ipairs(Env.CLOCK_SLOTS) do
            self.settings["plugin_wheel_" .. clock_slot] = i <= count and (command_ids and command_ids[i] or i) or 0
        end
    end

    function ctx:pick(hud, display_name)
        for _, entry in ipairs(hud._entries) do
            if entry.option and entry.option.display_name == display_name then
                self:clear_log()
                hud._wheel_active = true
                hud._hovered_entry = entry
                hud:_on_com_wheel_stop_callback(0)

                return clone(self.log)
            end
        end

        error("no wheel entry for " .. display_name)
    end

    ctx:set_enabled(opts.enabled ~= false, true)

    return ctx
end

return Env
