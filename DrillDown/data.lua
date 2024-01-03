local Constants = require "Constants"

data:extend(
    {
        {
            type = "custom-input",
            name = Constants.ModName .."-up",
            key_sequence = "CONTROL + M",
        },
        {
            type = "custom-input",
            name = Constants.ModName .."-down",
            key_sequence = "CONTROL + SHIFT + M",
        }
    }
)
