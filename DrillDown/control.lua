require "core.debugSupport"
local Constants = require "Constants"



local core = {
    class = require "core.class",
    EventManager = require "core.EventManager"
}

local query = require "database.query"

local EventManager = core.class:new(
    "EventManager", core.EventManager, {
    }
)

function EventManager:OnInitialise(event)
    global.sublevel_data = { map = {}, list = {} }
end

---Create the random generator for this sublevel
---@param stack_name string the name of the stack - actually the name of the top surface
---@param index number the sublevel. 0 is toplevel (named stack_name)
---@return table then name of the surface created
local function create_random_generator(stack_name, index)
    local above_level_name = index == 1 and stack_name or global.sublevel_data.list[stack_name][index - 1].name
    local seed = game.surfaces[above_level_name].map_gen_settings.seed
    return game.create_random_generator(seed)
end

---Create the map-gen settings for that sublevel
---@param stack_name string the name of the stack - actually the name of the top surface
---@param index number the sublevel. 0 is toplevel (named stack_name)
---@param seed number
---@return table the settings
local function initialize_map_gen_settings(stack_name, index, seed)
    local result = game.surfaces[stack_name].map_gen_settings
    result.seed = seed
    result.water = "none"
    result.autoplace_controls.stone.size = 100
    result.autoplace_controls.stone.frequency = 100
    result.autoplace_controls.trees.frequency = 0

    return result
end

---Create the surface and do some special modifications
---@param name string
---@param settings table the map-gen settings
local function create_surface(name, settings)
    local surface = game.create_surface(name, settings)

    -- setup as dungeon: starless and bible black
    surface.show_clouds = false
    surface.wind_speed = 0
    surface.dusk = 0
    surface.evening = 0.00001
    surface.dawn = 1
    surface.morning = 1 - 0.00001
end

---Create a sublevel - a surface - and setup global data
---@param stack_name string the name of the stack - actually the name of the top surface
---@param index number the sublevel. 0 is toplevel (named stack_name)
---@return string then name of the surface created
local function CreateSubLevel(stack_name, index)
    dassert(index > 0)

    local name = Constants.ModName .. "." .. stack_name .. ".Sublevel-" .. index
    local random_generator = create_random_generator(stack_name, index)
    local settings = initialize_map_gen_settings(stack_name, index, random_generator() * math.pow(2, 32))
    create_surface(name, settings)

    global.sublevel_data.list[stack_name][index] = { name = name }
    global.sublevel_data.map[name] = { stack_name = stack_name, index = index }

    return name
end

---Ensures that a targeted sublevel exists. If necessary sublevels above are created also
---@param stack_name string
---@param index number
---@return any surface name of the sublevel
local function EnsureSublevel(stack_name, index)
    local sublevels = global.sublevel_data.list[stack_name]
    if not sublevels then
        sublevels = {}
        global.sublevel_data.list[stack_name] = sublevels
    end

    if index <= 0 then return stack_name end

    local sublevel_data = sublevels[index]
    if sublevel_data then return sublevel_data.name end
    EnsureSublevel(stack_name, index - 1)
    return CreateSubLevel(stack_name, index)
end

--- Changes the (sub-)level of a player anywhere.
--- The target sublevel and each intermediate sublevels are created if necessary
---@param player_index number
---@param delta number number of levels to travel. Negative means down.
local function elevator_travel(player_index, delta)
    if delta == 0 then return end

    local player = game.players[player_index]
    local sublevel_data = global.sublevel_data.map[player.surface.name]

    if not sublevel_data then
        sublevel_data = { stack_name = player.surface.name, index = 0 }
        global.sublevel_data.map[player.surface.name] = sublevel_data
    end

    local target_level = EnsureSublevel(sublevel_data.stack_name, sublevel_data.index - delta)

    if target_level == player.surface.name then return end

    player.teleport(player.position, target_level)
end

function EventManager:OnUpKey(event)
    elevator_travel(event.player_index, 1)
end

function EventManager:OnDownKey(event)
    elevator_travel(event.player_index, -1)
end

function EventManager:new()
    local self = self:adopt {}
    self:SetHandler("on_init", self.OnInitialise)
    self:SetHandler(Constants.Key.Down, self.OnDownKey)
    self:SetHandler(Constants.Key.Up, self.OnUpKey)
end

return EventManager:new()
