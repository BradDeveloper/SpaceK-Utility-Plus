local SharedModules = script:FindFirstAncestor("SharedModules")
local Signal = require(SharedModules.Signal)

local Checkbox = {}
Checkbox.__index = Checkbox

function Checkbox.new(box: TextButton, defaultState: boolean)
    local self = setmetatable({
        Box = box,
        Changed = Signal.new()
    }, Checkbox) 

    self.Connection = self.Box.MouseButton1Click:Connect(function()
        self:Toggle(not self.State)
        self.Changed:Fire(self.State)
    end)
    self:Toggle(defaultState or false)

    return self
end

function Checkbox:Toggle(state: boolean)
    self.State = state
    if state then
        self.Box.Text = "X"
    else
        self.Box.Text = ""
    end
end

function Checkbox:GetValue(): boolean
    return self.State
end

function Checkbox:Destroy()
    self.Connection:Disconnect()
    self.Changed:Destroy()
    self = nil
end

return Checkbox