local result = {}
result.data = function()
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

        function getIconSize(target, indent)
            indent = indent or ""
            if target.icon_size then return target.icon_size end

            local result = { 0, 0 }
            for _, icon in ipairs(target.icons) do
                local size = icon.icon_size or 64
                local span = { size, size }
                if icon.shift then
                    span[1] = span[1] + icon.shift[1]
                    span[2] = span[2] + icon.shift[2]
                end
                if result[1] < span[1] then result[1] = span[1] end
                if result[2] < span[2] then result[2] = span[2] end
            end
            return math.max(result[1], result[2])
        end

        local iconSize = getIconSize(target)
        local shift = iconSize * OverlayShift
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
