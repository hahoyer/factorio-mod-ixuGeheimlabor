local constants =
{
    robot_count = 32,
    start_robot_count = 8,
    grace_period = 3600 * 5,
    robot = "robot_von_ixu",
    max_robot_count_validity =
    {
        minimum = 3600,
        maximum = 3600 * 3,
    },
}

local function get_global(player)
    if not storage.PersonalRobots then
        storage.PersonalRobots = {}
    end

    if not storage.PersonalRobots[player.name] then
        storage.PersonalRobots[player.name] = {
            last_robot_count = 0,
            last_maximum_tick = 0
        }
    end

    return storage.PersonalRobots[player.name]
end

local function setup_player(player)
    if get_global(player).setup_done then return end
    get_global(player).setup_done = true

    local armor = { name = "modular-armor", count = 1 }
    player.insert(armor)
    local grid = player.character.grid
    local rp = grid.put { name = "roboport_von_ixu" }
    rp.energy = rp.max_energy / 2
    for count = 1, 21 do
        grid.put { name = "solarpanel_von_ixu" }
    end
end

script.on_event(defines.events.on_player_joined_game, function(event)
    local player = game.players[event.player_index]
    if player.character then
        setup_player(player)
        return
    end
end)

local function get_player()
    if #game.connected_players ~= 1 then return end
    local player = game.connected_players[1]
    if not player or not player.connected then return end
    local force = player.force
    local technology = force.technologies["construction-robotics"]
    if technology.researched then return end
    local inventory = player.get_main_inventory()
    if not inventory then return end
    setup_player(player)
    return player
end


local function get_robot_count(player)
    local inventory = player.get_main_inventory()
    local count = 0
    for index = 1, #inventory do
        local value = inventory[index]
        if value.valid_for_read and value.name == constants.robot and value.quality.name == "normal" then
            count = count + value.count
        end
    end
    return count
end


script.on_nth_tick(60, function(event_data)
    local player = get_player()
    if not player then return end

    local count = get_robot_count(player)
    local global = get_global(player)

    if event_data.tick > global.last_maximum_tick + constants.max_robot_count_validity.maximum
        or global.last_robot_count < count
    then
        global.last_robot_count = count
        global.last_maximum_tick = event_data.tick
    end

    if event_data.tick > global.last_maximum_tick + constants.max_robot_count_validity.minimum
        and count < constants.robot_count
        or
        event_data.tick < constants.grace_period
        and count < constants.start_robot_count
    then
        player.insert { name = constants.robot, count = 1 }
        global.last_robot_count = count + 1
        global.last_maximum_tick = event_data.tick
    end
end)
