local plugin = plugin
local LOADED = false

local CREATE_STORAGE_FOLDER = true

local TOOLBAR_NAME = "Brad's Plugins"
local PLUGIN_NAME = "SpaceK+"
local PLUGIN_DESCRIPTION = "Extra SpaceK Streamline Tools"
local PLUGIN_ICON = "http://www.roblox.com/asset/?id=1521636846"
local CORE_WIDGET_INFO = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,
	true,
	250,
	150,
	250,
	150
)

local PluginManagerFile = script:WaitForChild("PluginManager")

local toolbar = plugin:CreateToolbar(TOOLBAR_NAME)
local button = toolbar:CreateButton(PLUGIN_NAME, PLUGIN_DESCRIPTION, PLUGIN_ICON)

local widget, gui, storage

local function toggle(state: boolean)
	button:SetActive(state)

	local Primary = require(script.PluginManager.Primary)
    if state then
        Primary:Show()
    else
        Primary:Hide()
    end
end

coroutine.wrap(function()
	local function createWidget()
		if widget then
			widget.Enabled = not widget.Enabled
			toggle(widget.Enabled)
			return
		end

		LOADED = true

		local name = PLUGIN_NAME.."_Handler"
		
		widget = plugin:CreateDockWidgetPluginGui(name, CORE_WIDGET_INFO)
		widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		widget.Name = name
		
		local n = PLUGIN_NAME.."_PLUGIN_VISUAL_STORAGE_FOLDER"
		storage = workspace.Camera:FindFirstChild(n)
		if CREATE_STORAGE_FOLDER and not storage then
			storage = Instance.new("Folder")
			storage.Archivable = false
			storage.Name = n
			storage.Parent = workspace.Camera
		end
		
		-------------------START MAIN PLUGIN CODE
		gui = script.Parent:WaitForChild("GUI"):Clone()
		gui.Size = UDim2.new(1,0,1,0)
		gui.Visible = true
		gui.Parent = widget
		
		--upt main scrollbar size
		local scroll = gui.Scroll
		local contentY = scroll.UIListLayout.AbsoluteContentSize.Y
		scroll.CanvasSize = UDim2.fromOffset(0, contentY)
		--
		
		local PluginManager = require(PluginManagerFile)
		PluginManager:init(widget, plugin, gui, storage)
		-------------------END MAIN PLUGIN CODE
		
		widget.Title = PLUGIN_NAME .. " Handler"
		widget.Enabled = false
		task.defer(function()
			widget.Enabled = true
			toggle(true)
		end)

		widget:BindToClose(function()
			widget.Enabled = false
			toggle(false)
		end)
	end
	
	local function open()
		createWidget()
	end
	local function forceUnload()
		if not LOADED then
			return
		end

		if widget then
			widget.Enabled = false
		end
		if storage then
			storage:Destroy()
		end
		require(script.PluginManager):Unload()
		toggle(false)
	end
	
	button.Click:Connect(open)
	plugin.Unloading:Connect(forceUnload)
end)()