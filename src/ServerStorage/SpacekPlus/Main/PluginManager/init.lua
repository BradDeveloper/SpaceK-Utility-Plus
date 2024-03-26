local StudioService = game:GetService("StudioService")
local Maid

local plugin, gui, storage

local PluginManager = {
	Enabled = false,
	Widget = nil
}

function PluginManager:init(_widget: DockWidgetPluginGui, _plugin: Plugin, _gui: Frame, _storage: Folder)
	PluginManager.Widget = _widget
	plugin = _plugin
	gui = _gui
	storage = _storage

	Maid = require(script.SharedModules.Maid).new()

	local SpaceKSpline = require(script.SharedModules.SpaceKSpline).new()
	Maid.SplineClass = SpaceKSpline
end

function PluginManager:GetMaid()
	return Maid
end

function PluginManager:GetPlugin()
	return plugin
end

function PluginManager:GetMouse()
	return plugin:GetMouse()
end

function PluginManager:GetGui()
	return gui
end

function PluginManager:GetSettings()

end

function PluginManager:GetStorage()
	return storage
end

function PluginManager:GetLocalUserId()
	return StudioService:GetUserId()
end

function PluginManager:GetData(key)
	local success, data = pcall(function()
		return plugin:GetSetting(key)
	end)
	if success then
		return data
	else
		return nil
	end
end

function PluginManager:SetData(key, value)
	local success = pcall(function()
		plugin:SetSetting(key, value)
	end)
	return success
end

function PluginManager:Unload()
	Maid:DoCleaning()
end

return PluginManager