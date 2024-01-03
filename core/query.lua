local query = {
    Next =
    {
        from = function(self, index)
            if index then index = index.value end
            local index, value = pairs(self.Values)(self.Values, index)
            if index then return { value = index }, value end
        end,

        clone = function(self, index)
            while true do
                local newIndex, value = self.Target:next(index)
                if not newIndex then return end
                if not self.Condition or self.Condition(value, newIndex.value) then return newIndex, value end
                index = newIndex
            end
        end,

        select = function(self, index)
            local index, value = self.Target:next(index)
            if index then
                return  index, self.Transformation(value, index.value)
            end
        end,

        flatten = function(self, index)
            if not index then index = {} end
            while true do
                local newIndex, value = self.Target:next(index.main)
                if not newIndex then return end
                local newSubIndex, subValue = value:next(index.sub)
                if newSubIndex then
                    return { main = index.main, sub = newSubIndex, value = newSubIndex }, subValue
                end
                index = { main = newIndex }
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

        concat = function(self, index)
            local iterator = index or { is_at_target = true }
            if iterator.is_at_target then
                local nextIndex, value = self.Target:next { iterator = iterator.iterator, value = iterator.value }
                if nextIndex then
                    return { is_at_target = true, iterator = nextIndex.iterator, value = nextIndex.value }, value
                end
                iterator = { is_at_target = false }
            end

            local index, value = self.Other:next { iterator = iterator.iterator, value = iterator.value }
            return index and { is_at_target = false, iterator = index.iterator, value = index.value } or nil, value
        end,

        skip_until = function(self, index)
            if index then return self.Target:next(index) end
            while true do
                local newIndex, value = self.Target:next(index)
                if not newIndex then return end
                if index and self.Index == index.value then return newIndex, value end
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
    return other:concat(other:clone(function(entry) return not self:contains(entry) end))
end

function query:except(other)
    return self:clone(function(entry) return not other:contains(entry) end)
end

function query:except_keys(other)
    return self:clone(function(_, key) return not other[key] end)
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

function query:concat(other)
    return query:new { Function = "concat", Other = other, Target = self }
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
        table.insert(self.Values, entry)
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
        if allowMultiple ~= false then return { Key = key.value, Value = value } end
        if result then
            error(onMultiple and onMultiple(#self) or "More than one element found: (" ..
                #self .. ").", 1)
        end
        result = { Key = key.value, Value = value }
    end

    if result then return result end

    if allowEmpty == false or onEmpty then
        error(onEmpty and onEmpty() or "No elements found.", 1)
    end
    return {}
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
        local resultKey = key.value
        if compact ~= false and type(resultKey) == "number" then
            resultKey = index
            index = index + 1
        end
        result[resultKey] = value
    end
    return result
end

function query:get_values(compact)
    local result = {}
    local index = 1
    for _, value in self.next, self do
        if compact == false or value then
            result[index] = value
            index = index + 1
        end
    end
    return result
end

function query:get_keys()
    local result = {}
    local index = 1
    for key, _ in self.next, self do
        result[index] = key
        index = index + 1
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
        local value = selector(nextValue, nextKey)
        if current and current.Value <= value
        then
            return current
        else
            return { Value = value, Key = nextKey }
        end
    end)
end

function query:maximum(selector)
    if not selector then selector = function(value, _) return value end end
    return self:aggregate(nil, function(current, nextValue, nextKey)
        local value = selector(nextValue, nextKey)
        if current and current.Value >= value
        then
            return current
        else
            return { Value = value, Key = nextKey }
        end
    end)
end

function query:index_where(condition)
    return self:clone(condition):top().Key
end

function query:skip_until(index)
    return query:new { Function = "skip_until", Index = index, Target = self }
end

function query.from(target)
    if getmetatable(target) == query then target = target:solve() end
    return query:new { Function = "from", Values = target or {} }
end

return query
