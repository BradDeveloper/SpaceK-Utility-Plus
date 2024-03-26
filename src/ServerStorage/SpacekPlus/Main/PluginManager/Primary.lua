local PluginManagerFile = script:FindFirstAncestor("PluginManager")
local PluginManager = require(PluginManagerFile)

local Selection = game:GetService("Selection")

local SharedModules = script.Parent.SharedModules
local MaidClass = require(SharedModules.Maid)
local Maid = MaidClass.new()
local WidgetMaid = MaidClass.new()

local Widgets = script.Parent.Widgets
local WidgetInfo = {
    "Helix"
}

local GuiStorage = script.Parent.GuiStorage

local Primary = {}

function Primary:Show()
    PluginManager.Enabled = true

    local gui = PluginManager:GetGui()
    local menu = gui.Scroll.Menu

    Maid:GiveTask(WidgetMaid)

    local function createMenuButton(index, name)
        local module = Widgets:FindFirstChild(name)
        if not module then
            error("Module Not Found: ", name)
        end

        local widgetGui = gui.Scroll:FindFirstChild(name)
        if not widgetGui then
            error("Widget Gui Not Found: ", name)
        end

        local item = GuiStorage.MenuItem:Clone()
        item.LayoutOrder = index
        item.Text = name
        item.Parent = menu

        Maid:GiveTask(item.MouseButton1Click:Connect(function()
            menu.Visible = false
            widgetGui.Visible = true

            require(module):Show(widgetGui, WidgetMaid)

            WidgetMaid:GiveTask(function()
                menu.Visible = true
                widgetGui.Visible = false
            end)
            widgetGui.BackButton.MouseButton1Click:Once(function()
                WidgetMaid:DoCleaning()
            end)
        end))
        Maid:GiveTask(item)
    end

    for i, w in WidgetInfo do
        createMenuButton(i, w)
    end

    local selection = gui.Selected
    Maid:GiveTask(selection.MouseButton1Click:Connect(function()
        local selected = Selection:Get()[1]
        local SplineClass = PluginManager:GetMaid().SplineClass
        local result = SplineClass:SetSpline(selected)
        if result then
            selection.Value.Text = selected.Name
            selection.Value.TextColor3 = Color3.new(0, 1, 0)
            gui.SelectLock.Visible = false
        else
            selection.Value.Text = "none"
            selection.Value.TextColor3 = Color3.new(1, 0, 0)
            gui.SelectLock.Visible = true
        end
    end))
end

function Primary:Hide()
    PluginManager.Enabled = false
    Maid:DoCleaning()
end

return Primary