local query = {
    Next =
    {
        from = function(self, index)
            return pairs(self.Target)(self.Target, index)
        end,

        clone = function(self, index)
            while true do
                local newIndex, value = self.Target:next(index)
                if not newIndex then return end
                if not self.Condition or self.Condition(value, newIndex) then return newIndex, value end
                index = newIndex
            end
        end,

        select = function(self, index)
            local index, value = self.Target:next(index)
            if index then
                return index, self.Transformation(value, index)
            end
        end,

        flatten = function(self, index)
            if not index then index = {} end
            while true do
                local newIndex, value = self.Target:next(index[1])
                if not newIndex then return end
                local newSubIndex, subValue = value:next(index[2])
                if newSubIndex then
                    return { index[1], newSubIndex }, subValue
                end
                index = { newIndex }
            end
        end,

        intersection_many = function(self, index)
            local mainIndex, mainSet = self.Target:next()
            if not mainIndex then return end
            while true do
                local newIndex, value = mainSet:next(index)
                if not newIndex then return end

                function AllOtherContainsAlso(index)
                    while true do
                        local nextIndex, otherSet = self.Target:next(index)
                        if not nextIndex then return true end
                        if not otherSet:contains(value) then return end
                        index = nextIndex
                    end
                end

                if AllOtherContainsAlso(mainIndex) then
                    return newIndex, value
                end
                index = newIndex
            end
        end,

        append = function(self, index)
            if not index then index = { true } end
            if index[1] then
                local nextIndex, value = self.Target:next(index[2])
                if nextIndex then
                    return { true, nextIndex }, value
                end
                index = { false }
            end

            local index, value = next(self.Values, index[2])
            return { false, index }, value
        end,

        skip_until = function(self, index)
            if index then return self.Target:next(index) end
            while true do
                local newIndex, value = self.Target:next(index)
                if not newIndex then return end
                if self.Index == index then return newIndex, value end
                index = newIndex
            end
        end,
    }
}

function query:next(index)
    return self.Next[self.Function](self, index)
end

function query:new(target)
    local result = target
    self.object_name = "query"
    setmetatable(result, self)
    self.__index = self
    return result
end

function query:clone(condition)
    return query:new { Function = "clone", Condition = condition, Target = self }
end

function query:intersection(other)
    return other:Where(function(entry) return self:contains(entry) end)
end

function query:union(other)
    return other:concat(other:where(function(entry) return not self:contains(entry) end))
end

function query:except(other)
    return self:where(function(entry) return not other:contains(entry) end)
end

function query:except_keys(other)
    return self:where(function(_, key) return not other[key] end)
end

function query:intersection_many()
    return query:new { Function = "intersection_many", Target = self }
end

function query:union_many()
    local dictionary = {}
    self:flatten():foreach(function(entry)
        dictionary[entry] = true
    end)
    return query.from(dictionary):select(function(_, value) return value end)
end

function query:select(transformation)
    return query:new { Function = "select", Transformation = transformation, Target = self }
end

function query:foreach(transformation)
    for key, value in self.next, self do
        transformation(value, key)
    end
end

function query:to_dictionary(getPair, on_dupkey)
    local dictionary = {}
    self:foreach(function(entry, key)
        local pair = getPair(entry, key)
        if on_dupkey then
            local current = dictionary[pair.Key]
            if current then
                pair.Value = on_dupkey(current, pair.value)
            end
        end
        dictionary[pair.Key] = pair.Value
    end)
    return query.from(dictionary)
end

function query:to_group(getPair)
    local dictionary = {}
    self:foreach(function(entry, key)
        local pair = getPair(entry, key)
        local current = dictionary[pair.Key] or query.from {}
        current:append(pair.Value)
        dictionary[pair.Key] = current
    end)
    return query.from(dictionary)
end

function query:append(entry)
    if self.Function == "from" then
        table.insert(self.Target, entry)
    elseif self.Function == "append" then
        table.insert(self.Values, entry)
    else
        self = self:new { Function = "append", Values = { entry }, Target = self }
    end
end

function query:select_many(transformation)
    return query:flatten():select(transformation)
end

function query:flatten()
    return query:new { Function = "flatten", Target = self }
end

function query:contains(item)
    return query:any(function(value) return value == item end)
end

function query:any(condition)
    if condition then
        for key, value in self.next, self do
            if condition(value, key) then return true end
        end
    else
        return self:next() ~= nil
    end
end

function query:count(condition)
    local result = 0
    for key, value in self.next, self do
        if not condition or condition(value, key) then result = result + 1 end
    end
    return result
end

function query:from_number(number)
    local target = {}
    for index = 1, number do table.insert(target, index) end
    return query.from(result)
end

--- Get the first element
---@param allowEmpty boolean optional default: true
---@param allowMultiple boolean optional default: true
---@param onEmpty any error message function, optional
---@param onMultiple any error message function, optional
function query:top(allowEmpty, allowMultiple, onEmpty, onMultiple)
    local result
    for key, value in self.next, self do
        if allowMultiple ~= false then return { Key = key, Value = value } end
        if result then
            error(onMultiple and onMultiple(#self) or "More than one element found: (" ..
                #self .. ").", 1)
        end
        result = { Key = key, Value = value }
    end

    if result then return result end

    if allowEmpty == false or onEmpty then
        error(onEmpty and onEmpty() or "No elements found.", 1)
    end
end

function query:all(condition)
    for key, value in self.next, self do
        if not condition(value, key) then return end
    end
    return true
end

function query:solve(compact)
    local result = {}
    local index = 1
    for key, value in self.next, self do
        if compact ~= false and type(key) == "number" then
            key = index
            index = index+1
        end
        result[key] = value
    end
    return result
end

function query:aggregate(seed, combine)
    local result = seed
    for key, value in self.next, self do
        result = combine(result, value, key)
    end
    return result
end

function query:sum()
    return self:aggregate(0, function(current, next) return current + next end)
end

function query:minimum(selector)
    if not selector then selector = function(value, _) return value end end
    return self:aggregate(nil, function(current, nextValue, nextKey)
        if current and selector(current.Value, current.Key) <= selector(nextValue, nextKey)
        then
            return current
        else
            return { Value = nextValue, Key = nextKey }
        end
    end)
end

function query:maximum(selector)
    if not selector then selector = function(value, _) return value end end
    return self:aggregate(nil, function(current, nextValue, nextKey)
        if current and selector(current.Value, current.Key) >= selector(nextValue, nextKey)
        then
            return current
        else
            return { Value = nextValue, Key = nextKey }
        end
    end)
end

function query:index_where(condition, index)
    return query:skip_until(index):where(condition):top().Key
end

function query:skip_until(index)
    return query:new { Function = "skip_until", Index = index, Target = self }
end

function query.from(target)
    return query:new { Function = "from", Target = target or {} }
end

return query
