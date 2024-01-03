local Constants = require "Constants"

data:extend(
    {
        {
            type = "custom-input",
            name = Constants.ModName .. "-inventory",
            key_sequence = "CONTROL + I",
        },
    }
)
data:extend { { type = "font", name = "ingteb-font32", from = "default", size = 32 } }

data.raw["gui-style"].default["ingteb-big-tab"] = { type = "tab_style", font = "ingteb-font32" }

data.raw["gui-style"].default["ingteb-big-tab-disabled"] = {
    type = "tab_style",
    font = "ingteb-font32",
    default_graphical_set = { base = { position = { 208, 17 }, corner_size = 8 } },
}

data.raw["gui-style"].default["ingteb-flow-fill"] = { --
    type = "vertical_flow_style", --
    horizontally_stretchable = "on",
}

