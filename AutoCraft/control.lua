local constants =
{
}

local function get_global(player)
    if not storage.AutoCraft then
        storage.AutoCraft = {}
    end

    if not storage.AutoCraft[player.name] then
        storage.AutoCraft[player.name] = {}
    end

    return storage.AutoCraft[player.name]
end

local function setup_player(player)
    if get_global(player).setup_done then return end
    get_global(player).setup_done = true
end

local function get_player()
    if #game.connected_players ~= 1 then return end
    local player = game.connected_players[1]
    if not player or not player.connected then return end
    local force = player.force
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
