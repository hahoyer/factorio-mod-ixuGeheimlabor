-- require "core.query-test"
-- require "DrillDown.control"
-- require "extended-pumpjack.control"
-- require "Inventory.control"
require "PersonalRobots.control"

script.on_init(function()
    if remote.interfaces.freeplay then
       remote.call("freeplay", "set_disable_crashsite", true)
    end
end)
