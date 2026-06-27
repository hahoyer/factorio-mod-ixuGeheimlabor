local class = require("core.class")
local UI = require("core.UI")
local query = require "core.query"

-- __DebugAdapter.breakpoint(mesg:LocalisedString)
local Class = class:new("core.EventManager")

Class.system.Abstract = true

Class.EventDefinesByIndex = query.from(defines.events)                           --
    :to_dictionary(function(value, key) return { Key = value, Value = key } end) --
    :solve()

Class.Events = {
    Register = function(eventId, handler)
        if eventId == "on_init" then
            script.on_init(handler)
        elseif eventId == "on_load" then
            script.on_load(handler)
        elseif eventId == "on_configuration_changed" then
            script.on_configuration_changed(handler)
        else
            script.on_event(defines.events[eventId], handler)
        end
    end
}

function Class:Execute(eventId, eventName)
    return function(...)
        local handlers = self.Handlers[eventName]
        for identifier, handler in pairs(handlers) do
            self:Enter(eventName, eventId, identifier)
            local result = handler.Handler(handler.Instance, ...)
            self:Leave()
            if result == false then handlers[identifier] = nil end
        end

        self:RemoveIfEmpty(handlers, eventId)
    end
end

function Class:RemoveIfEmpty(handlers, eventId)
    if not next(handlers) then
        local eventRegistrar = self.Events[eventId]
        if eventRegistrar then
            eventRegistrar(nil)
        else
            self.Events.Register(eventId, nil)
        end
    end
end

function FormatData(data)
    return tostring(data[1]) .. "/" .. tostring(data[2]) .. "/" .. tostring(data[3])
end

function Class:Enter(eventName, eventId, identifier)
    local data = { eventName, eventId, identifier }
    --ilog(">>>EnterEvent " .. FormatData(data))
    local oldIndent = nil --AddIndent()
    self.Active = { data, self.Active, oldIndent }
end

function Class:Leave()
    --indent = self.Active[3]
    --ilog("<<<LeaveEvent " .. FormatData(self.Active[1]))
    self.Active = self.Active[2]
end

---comment
---@param eventId any a number or string that identifies the event
---@param handler function a function with self as first argument and more arguments according to eventId. If function returns false the handler is removed after execution
---@param identifier string a name that identifies the event registration. Has to be set if you need more than one handler for an event. Must not be "default" to achieve this.
function Class:SetHandler(eventId, handler, identifier)
    if not Class.Handlers then Class.Handlers = {} end
    if not identifier then identifier = "default" end

    local eventName =                                                       --
        type(eventId) == "number" and Class.EventDefinesByIndex[eventId] or --
        eventId == 0 and "on_tick" or                                       --
        eventId

    local handlers = Class.Handlers[eventName]
    dassert(
        not handlers or identifier ~= "default",
        "handler for event " .. eventName .. " already registered. Use identifier"
    )

    if not handlers then
        handlers = {}
        Class.Handlers[eventName] = handlers

        local watchedEvent = Class:Execute(eventId, eventName)
        local eventRegistrar = self.Events[eventId]
        if eventRegistrar then
            eventRegistrar(watchedEvent)
        else
            self.Events.Register(eventId, watchedEvent)
        end
    end

    dassert(not handlers[identifier] or handlers[identifier] == handler or handler == nil) -- another handler with the same identifier is already installed for that event

    handlers[identifier] = { Instance = self, Handler = handler }

    Class:RemoveIfEmpty(handlers, eventId)
end

return Class
