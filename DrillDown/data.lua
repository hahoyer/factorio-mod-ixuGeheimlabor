local Constants = require "Constants"

data:extend(
    {
        {
            type = "custom-input",
            name = Constants.Key.Up,
            key_sequence = "CONTROL + M",
        },
        {
            type = "custom-input",
            name = Constants.Key.Down,
            key_sequence = "CONTROL + SHIFT + M",
        }
    }
)
