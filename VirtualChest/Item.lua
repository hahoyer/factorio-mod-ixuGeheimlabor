local Constants = require("Constants")
local class = require("core.class")

local Class = class:new("Item", nil, {
    GroupName = { get = function(self) return self.Prototype.group.name end },
    LocalisedName = { get = function(self) return self.Prototype.localised_name end, },
    SpriteName = { get = function(self) return "item/" .. self.Prototype.name end, },

    NumberOnSprite = {
        get = function(self)
            local number = self.Player.get_main_inventory().get_item_count(self.Name)
            if number > 0 then return number end
        end
    }
})

function Class:new(prototype, player)
    local self = self:adopt { Prototype = prototype, Player = player }
    self.Name = self.Prototype.name
    self.CommonKey = self.Name
    return self
end

return Class
