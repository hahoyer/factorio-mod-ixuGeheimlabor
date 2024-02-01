local gui = require("__flib__.gui")
local Constants = require "Constants"
local query = require "core.query"
local Item = require "VirtualChest.Item"


local function Global(tags)
    local result = global
    for _, value in ipairs(tags) do
        if not result[value] then
            result[value] = {}
        end
        result = result[value]
    end
    return result
end

local function GetGuiLocation(player)
    return Global { "VirtualChest", "player", player.name, "Location" }
end

local function SetGuiLocation(player, location)
    Global { "VirtualChest", "player", player.name }.Location = location
end

local function DestroyFloatingFrame(player)
    local moduleName = "VirtualChest"
    local name = Constants.ModName .. "." .. moduleName
    if player.gui.screen[name] then player.gui.screen[name].destroy() end
end

---Create frame and add content
--- Provided actions: location_changed and closed
---@param moduleName string
---@param frame table LuaGuiElement where gui will be added
---@param content table flib.GuiBuildStructure
---@param caption any LocalisedString
---@param options table
--- buttons table[] flib.GuiBuildStructure
--- subModule string name of the subModule for location and actions
---@return table LuaGuiElement references and subtables, built based on the values of ref throughout the GuiBuildStructure.
local function CreateFrameWithContent(moduleName, frame, content, caption, options)
    if not options then options = {} end
    local buttons = options.buttons or {}
    local result = gui.build(
        frame, {
            {
                type = "frame",
                direction = "vertical",
                name = Constants.ModName .. "." .. moduleName .. (options.subModule or ""),
                ref = { "Main" },
                style_mods = { padding = 0 },
                actions = {
                    on_location_changed = {
                        module = moduleName,
                        subModule = options.subModule,
                        action = "Moved",
                    },
                    on_closed = {
                        module = moduleName,
                        subModule = options.subModule,
                        action = "Closed",
                    },
                },
                children = {
                    {
                        type = "flow",
                        name = "Header",
                        direction = "horizontal",
                        children = {
                            {
                                type = "label",
                                name = "Title",
                                caption = caption,
                                style = "frame_title",
                            },
                            {
                                type = "empty-widget",
                                name = "DragHandle",
                                style = "flib_titlebar_drag_handle",
                                ref = { "DragBar" },
                            },
                            {
                                type = "flow",
                                name = "Buttons",
                                direction = "horizontal",
                                children = buttons,
                            },
                            {
                                type = "sprite-button",
                                name = "CloseButtom",
                                sprite = 'utility/close_white',
                                hovered_sprite = 'utility/close_black',
                                clicked_sprite = 'utility/close_black',
                                tooltip = { "gui.close" },
                                actions = {
                                    on_click = {
                                        module = moduleName,
                                        subModule = options.subModule,
                                        action = "Closed",
                                    },
                                },
                                style = "frame_action_button",
                            },
                        },
                    },
                    content,
                },
            },
        }
    )

    if not frame.parent and frame.name == "screen" then result.DragBar.drag_target = result.Main end
    return result
end

---Create floating frame and add content
--- Provided actions: location_changed and closed
---@param self table ingteb-module
---@param content table flib.GuiBuildStructure
---@param caption any LocalisedString
---@return table LuaGuiElement references and subtables, built based on the values of ref throughout the GuiBuildStructure.
local function CreateFloatingFrameWithContent(player, content, caption)
    if not options then options = {} end
    local moduleName = "VirtualChest"

    local result = CreateFrameWithContent(
        moduleName, player.gui.screen, content, caption, options
    )
    player.opened = result.Main

    local location = GetGuiLocation(player)
    if next(location) then
        result.Main.location = location
    else
        result.Main.force_auto_center()
        SetGuiLocation(player, result.Main.location)
    end
    return result
end

---Create popup frame and add content
--- Provided actions: location_changed and closed
---@param self table ingteb-module
---@param content table flib.GuiBuildStructure
---@param caption any LocalisedString
---@param options table
--- buttons table[] flib.GuiBuildStructure
--- subModule string name of the subModule for location and actions
---@return table LuaGuiElement references and subtables, built based on the values of ref throughout the GuiBuildStructure.
local function CreatePopupFrameWithContent(self, content, caption, options)
    local parentScreen = self.Player.opened
    if parentScreen and parentScreen.valid and parentScreen.object_name == "LuaGuiElement" then
        self.ParentScreen = parentScreen
    end
    local isPopup = self.PlayerGlobal.IsPopup
    self.PlayerGlobal.IsPopup = true
    local result = CreateFloatingFrameWithContent(self, content, caption)
    self.PlayerGlobal.IsPopup = isPopup
    return result
end

---Create floating frame and add content
--- Provided actions: closed
---@param self table ingteb-module
---@param content table flib.GuiBuildStructure
---@param caption any LocalisedString
---@param options table
--- buttons table[] flib.GuiBuildStructure
--- subModule string name of the subModule for location and actions
---@return table LuaGuiElement references and subtables, built based on the values of ref throughout the GuiBuildStructure.
local function CreateLeftSideFrameWithContent(self, content, caption, --[[optioal]] options)
    if not options then options = {} end
    local moduleName = self.class.name
    local player = self.Player
    local result = CreateFrameWithContent(
        moduleName, mod_gui.get_frame_flow(player), content, caption, options
    )
    return result
end


local function get_goods_panel(item)
    return {
        type = "sprite-button",
        sprite = item.SpriteName,
        name = item.CommonKey,
        number = item.NumberOnSprite,
        tooltip = item.LocalisedName,
        actions = { on_click = { module = "VirtualChest", action = "Click" } },
    }
end


function get_subgroup_panel(group, columnCount)
    return group:select(
            function(subgroup)
                local goods = subgroup --
                    :select(function(goods) return get_goods_panel(goods) end)
                if not goods:any() then return end
                return { type = "table", column_count = columnCount, children = goods:get_values() }
            end
        ) --
        :clone(function(subgroup) return subgroup end)
end

local function get_gui(groups)
    return {
        type = "tabbed-pane",
        name = "Tabs",
        ref = { "GroupTabs" },
        tabs = groups.list:select(
            function(group, name)
                local subGroup = get_subgroup_panel(group, 10)
                local caption = "[item-group=" .. name .. "]"
                return {
                    tab = {
                        type = "tab",
                        name = name,
                        caption = caption,
                        style = subGroup:any() and "ingteb-big-tab" or "ingteb-big-tab-disabled",
                        tooltip = { "item-group-name." .. name },
                        ignored_by_interaction = not subGroup:any(),
                        actions = {
                            on_click = { module = "VirtualChest", action = "Select" },
                            on_gui_selected_tab_changed = { module = "VirtualChest", action = "SelectionChanged" }
                        },
                    },
                    content = {
                        type = "flow",
                        direction = "vertical",
                        children = {
                            {
                                type = "scroll-pane",
                                horizontal_scroll_policy = "never",
                                direction = "vertical",
                                children = {
                                    {
                                        type = "flow",
                                        direction = "vertical",
                                        style = "ingteb-flow-fill",
                                        children = subGroup:get_values()
                                        ,
                                    },
                                },
                            },
                        },
                    },
                }
            end
        ):get_values(),
        actions = { on_gui_selected_tab_changed = { module = "VirtualChest", action = "Select" } },
    }
end

local function create_item(item, player)
    local result = Item:new(item, player)
    if result.NumberOnSprite then return result end
end

local function create_group(group)
    local result = group
        :to_group(function(item) return { Key = item.Prototype.subgroup.name, Value = item } end)
    return result
end

local function get_groups(player)
    local list = query.from(game.item_prototypes)
        :select(function(item) return create_item(item, player) end)
        :clone(function(item) return item end)
        :to_group(function(value) return { Key = value.GroupName, Value = value } end)
        :select(function(group) return create_group(group) end)

    local result = {
        list = list,
        column_count = list:maximum(
            function(self)
                return self:maximum(function(self) return self:count() end).Value
            end
        ).Value
    }

    return result
end

local function SelectLastTab(tabbed_pane, selectedName)
    local selected_index = query.from(tabbed_pane.tabs)
        :index_where(function(tab) return tab.tab.name == selectedName end)
    tabbed_pane.selected_tab_index = selected_index or 1
end

local function CloseGui(player)
    DestroyFloatingFrame(player)
    Global { "VirtualChest", "player", player.name }.is_visible = false
end

local function UpdateGui(player)
    local moduleName = "VirtualChest"
    local name = Constants.ModName .. "." .. moduleName
    if not player.gui.screen[name] then return end
    local data = player.gui.screen[name]
    data.Tabs.destroy()
    local groups = get_groups(player)
    local template = get_gui(groups)
    local result = gui.build(data,{template})
    local selectedTab = Global { "VirtualChest", "player", player.name }.SelectedGroup
    SelectLastTab(result.GroupTabs, selectedTab)
end

local function OpenGui(player)
    local groups = get_groups(player)
    local template = get_gui(groups)
    local result = CreateFloatingFrameWithContent(player, template, { "VirtualChest.Main" })
    if result.Filter then result.Filter.focus() end
    local selectedTab = Global { "VirtualChest", "player", player.name }.SelectedGroup
    SelectLastTab(result.GroupTabs, selectedTab)
    Global { "VirtualChest", "player", player.name }.is_visible = true
end

local function OnGuiEvent(event)
    local player = game.players[event.player_index]
    local message = gui.read_action(event)
    if message.action == "Closed" then
        CloseGui(player)
    elseif message.action == "Moved" then
        SetGuiLocation(player, event.element.location)
    elseif message.action == "Click" then
        local commonKey = message.key or event.element.name
        local inventory = player.get_main_inventory()
        if not inventory then return end
        local stack, index = inventory.find_item_stack(commonKey)
        if not stack then return end
        local cursor = player.cursor_stack
        cursor.transfer_stack(stack)
    elseif message.action == "Select" then
        Global { "VirtualChest", "player", player.name }.SelectedGroup = event.element.name
    end
end

local function OnMainInventoryChanged(event)
    local player = game.players[event.player_index]
    if Global { "VirtualChest", "player", player.name }.is_visible then
        UpdateGui(player)
    end
end

script.on_event(Constants.ModName .. "-inventory", function(event)
    local player = game.players[event.player_index]
    if Global { "VirtualChest", "player", player.name }.is_visible then CloseGui(player) else OpenGui(player) end
end
)

script.on_event(defines.events.on_player_main_inventory_changed, OnMainInventoryChanged)
--script.on_event(defines.events.on_gui_selected_tab_changed, OnGuiEvent)


gui.hook_events(
    function(event)
        if event.element and event.element.get_mod() ~= script.mod_name then return end
        local message = gui.read_action(event)
        if message then
            if message.module then
                OnGuiEvent(event)
            else
                dassert()
            end
        elseif event.element and event.element.tags then
        else
            dassert(
                event.name == defines.events.on_gui_opened                  --
                or event.name == defines.events.on_gui_selected_tab_changed --
                or event.name == defines.events.on_gui_closed               --
            )
        end
    end
)
