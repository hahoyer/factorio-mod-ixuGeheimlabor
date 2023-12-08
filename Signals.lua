local result = {}
result.data = function ()
    local OverlayScale = 0.3
    local OverlayShift = 0.18

    local function patch(name, other)
        local target = data.raw["virtual-signal"][name]
        local otherTarget = data.raw["virtual-signal"][other]

        local icons = target.icons
        if not icons then
            icons =
            {
                { icon = target.icon, icon_size = target.icon_size, icon_mipmaps = target.icon_mipmaps }
            }
            target.icon = nil
            target.icons = icons
        end
        local shift = target.icon_size * OverlayShift
        if otherTarget.icon then
            table.insert(target.icons,
                {
                    icon = otherTarget.icon,
                    icon_size = otherTarget.icon_size,
                    icon_mipmaps = otherTarget.icon_mipmaps,
                    scale = OverlayScale,
                    shift = { shift, -shift }
                }
            )
        end
    end

    patch("signal-everything", "signal-A")
    patch("signal-anything", "signal-1")


end
return result