local util = require "util"

local result = {}

local furnace = data.raw.furnace["stone-furnace"]
furnace.energy_source = {
    type = "heat",
    max_temperature = 1000,
    specific_heat = "1MJ",
    max_transfer = "200kW",
    min_working_temperature = 120,
    minimum_glow_temperature = 120,
    connections = {
        {position = {0, 0}, direction = defines.direction.north},
        {position = {0, 0}, direction = defines.direction.east},
        {position = {0, 0}, direction = defines.direction.south},
        {position = {0, 0}, direction = defines.direction.west},
    },
}

furnace.collision_box = {{-0.4, -0.4}, {0.4, 0.4}}
furnace.selection_box = {{-0.5, -0.5}, {0.5, 0.5}}
furnace.next_upgrade = nil

data:extend{
    {
        type = "item",
        name = "burner",
        icon = "__base__/graphics/icons/nuclear-reactor.png",
        icon_size = 64,
        icon_mipmaps = 4,
        subgroup = "energy",
        order = "a-a[reactor]",
        place_result = "burner",
        stack_size = 50,
    },
    {
        type = "recipe",
        name = "burner",
        energy_required = 8,
        enabled = true,
        ingredients = {{"iron-gear-wheel", 3}, {"copper-plate", 1}, {"iron-plate", 3}},
        result = "burner",
        requester_paste_multiplier = 1,
    },
    {type = "recipe-category", name = "burning"},
    {
        type = "reactor",
        name = "burner",
        icon = "__base__/graphics/icons/nuclear-reactor.png",
        icon_size = 64,
        icon_mipmaps = 4,
        flags = {"placeable-neutral", "player-creation"},
        minable = {mining_time = 0.1, result = "burner"},
        max_health = 100,
        --energy_usage = "100kW",
        --energy_consumption = "100kW",
        consumption = "100MW",
        --target_temperature = 350,
        energy_source = {
            type = "burner",
            fuel_category = "chemical",
            effectivity = 10,
            fuel_inventory_size = 1,
            emissions_per_minute = 30,
            light_flicker = {color = {0, 0, 0}, minimum_intensity = 0.6, maximum_intensity = 0.95},
            smoke = {
                {
                    name = "smoke",
                    north_position = util.by_pixel(-38, -47.5),
                    south_position = util.by_pixel(38.5, -32),
                    east_position = util.by_pixel(20, -70),
                    west_position = util.by_pixel(-19, -8.5),
                    frequency = 15,
                    starting_vertical_speed = 0.0,
                    starting_frame_deviation = 60,
                },
            },
        },
        heat_buffer = {
            max_temperature = 400,
            specific_heat = "1MJ",
            max_transfer = "100MW",
            minimum_glow_temperature = 100,
            connections = {
                {position = {0, 0}, direction = defines.direction.north},
                {position = {0, 0}, direction = defines.direction.east},
                {position = {0, 0}, direction = defines.direction.south},
                {position = {0, 0}, direction = defines.direction.west},

            },
        },
        collision_box = {{-0.4, -0.4}, {0.4, 0.4}},
        selection_box = {{-0.5, -0.5}, {0.5, 0.5}},

        picture = {
            layers = {
                {
                    filename = "__base__/graphics/entity/nuclear-reactor/reactor.png",
                    width = 154,
                    height = 158,
                    scale = 0.25,
                    shift = util.by_pixel(-6, -6),
                    hr_version = {
                        filename = "__base__/graphics/entity/nuclear-reactor/hr-reactor.png",
                        width = 302,
                        height = 318,
                        scale = 0.125,
                        shift = util.by_pixel(-5, -7),
                    },
                },
                {
                    filename = "__base__/graphics/entity/nuclear-reactor/reactor-shadow.png",
                    width = 263,
                    height = 162,
                    scale = 0.25,
                    shift = {1.625, 0},
                    draw_as_shadow = true,
                    hr_version = {
                        filename = "__base__/graphics/entity/nuclear-reactor/hr-reactor-shadow.png",
                        width = 525,
                        height = 323,
                        scale = 0.125,
                        shift = {1.625, 0},
                        draw_as_shadow = true,
                    },
                },
            },
        },

        working_light_picture = {
            filename = "__base__/graphics/entity/nuclear-reactor/reactor-lights-color.png",
            blend_mode = "additive",
            draw_as_glow = true,
            width = 160,
            height = 160,
            scale = 0.25,
            shift = {-0.03125, -0.1875},
            hr_version = {
                filename = "__base__/graphics/entity/nuclear-reactor/hr-reactor-lights-color.png",
                blend_mode = "additive",
                draw_as_glow = true,
                width = 320,
                height = 320,
                scale = 0.125,
                shift = {-0.03125, -0.1875},
            },
        },

        working_sound = {
            sound = {
                {filename = "__base__/sound/nuclear-reactor-1.ogg", volume = 0.55},
                {filename = "__base__/sound/nuclear-reactor-2.ogg", volume = 0.55},
            },
            -- idle_sound = { filename = "__base__/sound/idle1.ogg", volume = 0.3 },
            max_sounds_per_type = 3,
            fade_in_ticks = 4,
            fade_out_ticks = 20,
        },

    },

}
