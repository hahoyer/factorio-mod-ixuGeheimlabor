local query = require "database.query"
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

function test.AllTests()
    test.solve()
    test.SkipUntil()
    test.Clone_array()
    test.Clone_mixed()
    test.Clone_mixed2()
end

test.AllTests()
