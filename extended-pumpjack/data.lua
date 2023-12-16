function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local pumpjack = deepcopy(data.raw["mining-drill"]["pumpjack"])
pumpjack.name = pumpjack.name .. "-alternate"
pumpjack.output_fluid_box.pipe_connections = { { positions = { { -1, -2 }, { 2, 1 }, { 1, 2 }, { -2, -1 } }, type = "output" } }
--                                               positions = { {  1, -2 }, { 2, -1 }, {-1, 2 }, { -2, 1 } }
pumpjack.items_to_place_this = { "pupmjack" }

data:extend { pumpjack }

data:extend
{
    {
        type = "custom-input",
        name = "flip-pumpjack",
        key_sequence = "G",
        include_selected_prototype = true,
    },
}
