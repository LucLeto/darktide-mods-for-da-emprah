-- Offline test suite for ForDaEmprah. Runs outside the game against stubbed Darktide and DMF APIs.
--
-- Usage, from the repository root:
--   luajit tests/run_tests.lua [path/to/Darktide-Source-Code]
--
-- With a Darktide source checkout (as the argument or in DARKTIDE_SOURCE), the wheel scaling tests also
-- run against the game's real smart tagging widget definitions; without one, those tests are skipped.
-- Exits with 1 when any test fails.

local real_require = require
local tests_dir = arg[0]:match("^(.*)[/\\][^/\\]+$") or "."
local mod_dir = tests_dir .. "/../ForDaEmprah/scripts/mods/ForDaEmprah"
local darktide_source = arg[1] or os.getenv("DARKTIDE_SOURCE")

if darktide_source == "" then
    darktide_source = nil
end

if darktide_source then
    local probe = io.open(darktide_source .. "/scripts/managers/ui/ui_widget.lua")

    if not probe then
        io.stderr:write("Darktide source not found at " .. darktide_source .. "\n")
        os.exit(2)
    end

    probe:close()
end

local Env = dofile(tests_dir .. "/support/env.lua")

Env.mod_dir = mod_dir

local function describe(value)
    return type(value) == "string" and string.format("%q", value) or tostring(value)
end

local h = {
    Env = Env,
    mod_dir = mod_dir,
    darktide_source = darktide_source,
    real_require = real_require,
}

function h.check(condition, message)
    if not condition then
        error(message, 2)
    end
end

function h.equal(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", label, describe(expected), describe(actual)), 2)
    end
end

function h.near(actual, expected, label, tolerance)
    if type(actual) ~= "number" or math.abs(actual - expected) > (tolerance or 1e-6) then
        error(string.format("%s: expected %s, got %s", label, describe(expected), describe(actual)), 2)
    end
end

function h.same(actual, expected, label)
    local actual_text = table.concat(actual, " | ")
    local expected_text = table.concat(expected, " | ")

    if actual_text ~= expected_text then
        error(string.format("%s:\n      expected: %s\n      got:      %s", label, expected_text, actual_text), 2)
    end
end

function h.skip(reason)
    error({ skip = reason }, 0)
end

local test_files = {
    "test_static.lua",
    "test_wheel_commands.lua",
    "test_mod_toggle.lua",
    "test_wheel_scale.lua",
}
local passed, failed, skipped = 0, 0, 0

for _, file in ipairs(test_files) do
    print(file)

    local tests = assert(loadfile(tests_dir .. "/" .. file))(h)

    for _, test in ipairs(tests) do
        local ok, err = xpcall(test.run, function(e)
            if type(e) == "table" then
                return e
            end

            return debug.traceback(tostring(e), 2)
        end)

        if ok then
            passed = passed + 1
            print("  PASS  " .. test.name)
        elseif type(err) == "table" and err.skip then
            skipped = skipped + 1
            print("  SKIP  " .. test.name .. " (" .. err.skip .. ")")
        else
            failed = failed + 1
            print("  FAIL  " .. test.name)
            print("        " .. tostring(err):gsub("\n", "\n        "))
        end
    end
end

print(string.format("\n%d passed, %d failed, %d skipped", passed, failed, skipped))
os.exit(failed > 0 and 1 or 0)
