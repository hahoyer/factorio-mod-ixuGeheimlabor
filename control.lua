local context = {
    --- core.EventManager
    EventManager = require "core.EventManager"
}

-- require "core.query-test"
-- require "DrillDown.control"
-- require "extended-pumpjack.control"
-- require "Inventory.control"
require "PersonalRobots.control".init(context)

context.EventManager:SetHandler
(
    "on_init",
    function(self)
        if remote.interfaces.freeplay then
            remote.call("freeplay", "set_disable_crashsite", true)
        end
    end,
    "crashsite"
)
