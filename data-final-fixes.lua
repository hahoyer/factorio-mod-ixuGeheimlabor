if data.raw.character["miku-bikini-swimsuit-skin"] then
    data.raw.character["character"] = data.raw.character["miku-bikini-swimsuit-skin"]
    data.raw.character["character"].name = "character"
    data.raw.character["miku-bikini-swimsuit-skin"] = nil
end

if data.raw.recipe.flask and data.raw.recipe.flask.results[1][1] == "flask" then
    data.raw.recipe.flask.results[1][2] = 20
end