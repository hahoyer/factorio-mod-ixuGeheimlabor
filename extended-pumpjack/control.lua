script.on_event("flip-pumpjack", function(event)
    local selection = event.selected_prototype
    if not selection or selection.derived_type ~= "mining-drill" then return end
    function replace(replacement)
        local surface = game.players[event.player_index].surface
        local position = event.cursor_position
        local old_entity = surface.find_entity(selection.name, position)
        local new_entity = surface.create_entity {
            name = replacement,
            position = old_entity.position,
            fast_replace = true,
            force = old_entity.force
        }
    end

    if selection.name == "pumpjack" then
        replace("pumpjack-alternate")
    elseif selection.name == "pumpjack-alternate" then
        replace("pumpjack")
    end
end
)
