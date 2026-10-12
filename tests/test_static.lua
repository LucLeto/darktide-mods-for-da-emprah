local h = ...
local mod_dir = h.mod_dir

local LANGUAGES = { "en", "fr", "de", "it", "es", "pl", "pt-br", "ru", "ja", "ko", "zh-cn", "zh-tw" }

-- Engine/game globals the mod may read. Anything else is most likely a vanilla file-local (see INSTANT_WHEEL_THRESHOLD).
local ALLOWED_GLOBALS = {
    ALIVE = true,
    Managers = true,
    RESOLUTION_LOOKUP = true,
    ScriptUnit = true,
    Unit = true,
    Vector3 = true,
    Vector3Box = true,
    get_mod = true,
    ipairs = true,
    math = true,
    pairs = true,
    require = true,
    string = true,
    table = true,
    type = true,
}

local function read_file(path)
    local file = assert(io.open(path, "rb"))
    local text = file:read("*a")

    file:close()

    return text
end

local function global_accesses(path)
    local bc = h.real_require("jit.bc")
    local chunks = {}
    local sink = {
        write = function(_, ...)
            for i = 1, select("#", ...) do
                chunks[#chunks + 1] = select(i, ...)
            end
        end,
        flush = function() end,
    }

    bc.dump(assert(loadfile(path)), sink, true)

    local reads, writes = {}, {}

    for op, name in table.concat(chunks):gmatch("(G[GS]ET)%s+[^\n]-\"([%w_]+)\"") do
        if op == "GGET" then
            reads[name] = true
        else
            writes[name] = true
        end
    end

    return reads, writes
end

local function dropdown_options()
    local block = read_file(mod_dir .. "/ForDaEmprah_data.lua"):match("DROPDOWN_OPTIONS = (%b{})")
    local options = {}

    for key, command in block:gmatch("text%s*=%s*\"([%w_]+)\",%s*value%s*=%s*COMMAND%.([%u_]+)") do
        options[#options + 1] = { key = key, command = command }
    end

    return options
end

return {
    {
        name = "localization has every key in all 12 languages and no unused keys",
        run = function()
            local localization = dofile(mod_dir .. "/ForDaEmprah_localization.lua")
            local data_source = read_file(mod_dir .. "/ForDaEmprah_data.lua")
            local main_source = read_file(mod_dir .. "/ForDaEmprah.lua")
            local needed = { mod_title = true, mod_description = true, plugin_chat_messages = true, plugin_keybinds = true }

            for clock_slot in data_source:match("CLOCK_SLOTS = (%b{})"):gmatch("\"(%d+)\"") do
                needed["plugin_wheel_" .. clock_slot] = true
            end

            for key in data_source:gmatch("text%s*=%s*\"([%w_]+)\"") do
                needed[key] = true
            end

            for key in main_source:gmatch("display_name%s*=%s*\"([%w_]+)\"") do
                needed[key] = true
            end

            for key in pairs(needed) do
                local entry = localization[key]

                h.check(entry ~= nil, "missing localization key " .. key)

                for _, language in ipairs(LANGUAGES) do
                    h.check(type(entry[language]) == "string" and entry[language] ~= "", "missing " .. language .. " for " .. key)
                end
            end

            for key in pairs(localization) do
                h.check(needed[key], "unused localization key " .. key)
            end
        end,
    },
    {
        name = "mod files read only known game globals and write none",
        run = function()
            for _, file in ipairs({ "ForDaEmprah.lua", "ForDaEmprah_data.lua", "ForDaEmprah_localization.lua" }) do
                local reads, writes = global_accesses(mod_dir .. "/" .. file)

                for name in pairs(reads) do
                    h.check(ALLOWED_GLOBALS[name], file .. " reads unexpected global " .. name)
                end

                for name in pairs(writes) do
                    h.check(false, file .. " writes global " .. name)
                end
            end
        end,
    },
    {
        name = "command dropdown is sorted by key and lists every command once",
        run = function()
            local options = dropdown_options()
            local data_source = read_file(mod_dir .. "/ForDaEmprah_data.lua")
            local seen = {}

            h.equal(options[1] and options[1].key, "option_nil", "first dropdown entry")

            for i = 2, #options do
                local option = options[i]

                h.check(not seen[option.command], "command listed twice: " .. option.command)

                if i > 2 then
                    h.check(options[i - 1].key < option.key, option.key .. " is out of order after " .. options[i - 1].key)
                end

                seen[option.command] = true
            end

            for command in data_source:match("local COMMAND = (%b{})"):gmatch("([%u_]+)%s*=%s*%d+") do
                h.check(command == "NONE" or seen[command], "command missing from dropdown: " .. command)
            end
        end,
    },
}
