require "DrillDown.data"
require "extended-pumpjack.data"
local signals = require "Signals"
signals.data()

-- require "evo.data"
for _, character in pairs(data.raw["character"]) do
    character.build_distance = 10000
    character.reach_distance = 10000
    character.reach_resource_distance = 10000
    character.drop_item_distance = 10000
    character.inventory_size = 240
end
