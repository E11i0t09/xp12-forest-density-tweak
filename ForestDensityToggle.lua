--[[
  ForestDensityToggle.lua  -  part of XP12 Forest Density Tweak
  Version 1.0 (2026-10-13)   https://github.com/E11i0t09/xp12-forest-density-tweak

  In-sim switch between the dense (tweaked) forests and roughly the original
  density, without touching any files.

  How it works
    X-Plane multiplies the maximum density from the .for files by the art control
    "forest/density" (the vegetation slider writes 0.1 ... 1.0 into it).
    The tweak raised the maximum by 1/factor^2 (factor 0.7 -> ~2x trees).
    So:  density = slider value          -> dense, tweaked forests
         density = slider value * f^2    -> about the original density
    The factor is read from <X-Plane>\ForestDensityTweak\backup.log.

  Usage
    - Plugins > FlyWithLua > FlyWithLua Macros > "Forest density: ..."
    - or bind a key/button: Settings > Keyboard / Joystick, search "ForestDensity"
        FlyWithLua/ForestDensity/toggle
        FlyWithLua/ForestDensity/dense
        FlyWithLua/ForestDensity/original
    - Trees are placed when scenery tiles load. With AUTO_RELOAD = true the
      script reloads the scenery after switching (short pause, like changing
      location). Set it to false if the change already shows up without reload
      on your system, or to only affect newly loaded tiles.

  Install: copy this file to  X-Plane 12\Resources\plugins\FlyWithLua\Scripts\
  Requires FlyWithLua NG (2.7+) for X-Plane 12.
  Note: changing graphics settings resets the value to the slider setting.
]]

-- ---------------------------------------------------------------- settings
local AUTO_RELOAD       = true     -- reload scenery after switching
local FALLBACK_FACTOR   = 0.7      -- used if backup.log can't be read
local MESSAGE_SECONDS   = 4        -- on-screen info duration (0 = off)

-- ---------------------------------------------------------------- internals
local REF_NAME = "sim/private/controls/forest/density"

if XPLMFindDataRef(REF_NAME) == nil then
    logMsg("ForestDensityToggle: dataref " .. REF_NAME .. " not found - script disabled.")
    return
end

local function read_factor()
    local path = SYSTEM_DIRECTORY .. "ForestDensityTweak" .. DIRECTORY_SEPARATOR .. "backup.log"
    local f = io.open(path, "r")
    if not f then return nil end
    local factor = nil
    for line in f:lines() do
        local x = line:match('"x"%s*:%s*([%d%.]+)')
        if x then factor = tonumber(x) end      -- last entry wins (same as the tweak tool)
    end
    f:close()
    return factor
end

local factor = read_factor()
local factor_source = "backup.log"
if not factor or factor <= 0 or factor >= 1 then
    factor = FALLBACK_FACTOR
    factor_source = "fallback"
end

local dense_value = get(REF_NAME)
if dense_value == nil or dense_value <= 0 then dense_value = 1.0 end
local function original_value() return math.max(0.05, dense_value * factor * factor) end

local is_dense = true
local msg_text, msg_until = nil, 0

local function show(text)
    logMsg("ForestDensityToggle: " .. text)
    if MESSAGE_SECONDS > 0 then
        msg_text, msg_until = text, os.clock() + MESSAGE_SECONDS
    end
end

local function apply(dense)
    -- pick up a slider change made since the last switch
    local cur = get(REF_NAME)
    if is_dense and cur and cur > 0 and math.abs(cur - dense_value) > 0.001 then
        dense_value = cur
    end
    is_dense = dense
    local v = dense and dense_value or original_value()
    set(REF_NAME, v)
    show(string.format("Forests: %s (density %.2f, factor %.2f from %s)%s",
         dense and "DENSE" or "ORIGINAL", v, factor, factor_source,
         AUTO_RELOAD and " - reloading scenery" or ""))
    if AUTO_RELOAD then command_once("sim/operation/reload_scenery") end
end

function fdt_set_dense()    apply(true)  end
function fdt_set_original() apply(false) end
function fdt_toggle()       apply(not is_dense) end

create_command("FlyWithLua/ForestDensity/toggle",   "Forest density: toggle dense / original", "fdt_toggle()",       "", "")
create_command("FlyWithLua/ForestDensity/dense",    "Forest density: dense (tweaked)",         "fdt_set_dense()",    "", "")
create_command("FlyWithLua/ForestDensity/original", "Forest density: original",                "fdt_set_original()", "", "")

add_macro("Forest density: toggle dense / original", "fdt_toggle()")
add_macro("Forest density: dense", "fdt_set_dense()")
add_macro("Forest density: original", "fdt_set_original()")

function fdt_draw()
    if msg_text and os.clock() < msg_until then
        draw_string(30, SCREEN_HIGHT - 60, msg_text, "white")
    end
end
do_every_draw("fdt_draw()")

logMsg(string.format("ForestDensityToggle: ready (dense %.2f, original %.2f, factor %.2f from %s)",
       dense_value, original_value(), factor, factor_source))
