local query = require "core.query"
require "core.debugSupport"

local test = {}

local function getAllRecipesThatUseItem(target)
    local relation = { game, "recipe_prototypes", "*", "ingredients", "*", "name" }
    return query.from(game.recipe_prototypes)
        :clone
        (
            function(p)
                return query.from(p.ingredients):any
                    (
                        function(i)
                            return i.type == "item" and i.name == target
                        end
                    )
            end
        )
        :solve()
end

function test.index_where()
    local target = query.from { 2, 4, x = "x", 8, 4 }
    local result = target:index_where(function(value, key) return value == key end)
    dassert (result == 4) -- since numbers are considered first
end

function test.solve()
    local target = query.from { 2, 4, 6, 8 }
    local result = target:solve()
    dassert(table.concat(result, ",") == "2,4,6,8")
end

function test.SkipUntil()
    local target = query.from { 2, 4, 6, 8 }
    local result = target:skip_until(2):solve()
    dassert(table.concat(result, ",") == "6,8")
end

function test.Clone_array()
    local target = query.from { 2, 4, 6, 8 }
    local result = target
        :clone(function(value, key) return key == 1 or key == 3 end)
        :solve()
    dassert(table.concat(result, ",") == "2,6")
end

function test.Clone_mixed()
    local target = query.from { 2, 4, x = 6, 8 }
    local result = target
        :clone(function(value, key) return key == 1 or key == 3 end)
        :solve()
    dassert(table.concat(result, ",") == "2,8")
end

function test.Clone_mixed2()
    local target = query.from { 2, 4, x = 6, 8 }
    local result = target
        :clone(function(value, key) return key ~= 1 and key ~= 2 end)
        :solve()
    dassert(serpent.block(result) == serpent.block { 8, x = 6 })
end

function test.Concat()
    local target1 = query.from { 8 }
    local target2 = query.from { 2, }
    local result = target1:concat(target2)
    local result = result:solve()
    dassert(serpent.block(result) == serpent.block { 8, 2 })
end

function test.Concat2()
    local target1 = query.from { 2, 4, x = 6, 8 }
    local target2 = query.from { 2, 4, x = 6, 8 }
    local result = target1:concat(target2)
    local result = result:solve()
    dassert(serpent.block(result) == serpent.block { 2, 4, x = 6, 8, 2, 4, 8 })
end

function test.Select()
    local target = query.from { 2, 4, x = 6, 8 }
    local result = target:select(function(value) return value + 1 end)
    local result = result:solve()
    dassert(serpent.block(result) == serpent.block { 3, 5, x = 7, 9 })
end

function test.Select2()
    local target = query.from { 2, 4, x = 6, 8 }
    local result = target:select(function(value, key) return key .. value end)
    local result = result:solve()
    dassert(serpent.block(result) == serpent.block { "12", "24", x = "x6", "38" })
end


function test.index_where1()
    local target = query.from { 2, 4, x = 3, 8, 4 }
    local result = target:index_where(function(value, key) return value == key end)
    dassert(result == 4)
end

function test.index_where2()
    local target = query.from { 2, 4, x = "x", 8, 4 }
    local result = target:index_where(function(value) return value == 12 end)
    dassert(not result)
end

function AllTests(test)
    for key, value in pairs(test) do
        value()
    end
end

AllTests(test)
