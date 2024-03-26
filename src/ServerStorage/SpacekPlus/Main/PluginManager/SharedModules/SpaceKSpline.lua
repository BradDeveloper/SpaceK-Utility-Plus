local PluginManagerFile = script:FindFirstAncestor("PluginManager")
local PluginManager = require(PluginManagerFile)

local Signal = require(script.Parent.Signal)
local Maid = require(script.Parent.Maid)

local SpaceKSpline = {}
SpaceKSpline.__index = SpaceKSpline

function SpaceKSpline.new(model: Model)
    local self = setmetatable({
        Changed = Signal.new(),
        Maid = Maid.new()
    }, SpaceKSpline)

    if model then
        self.Spline = self:SetSpline(model)
    end

    return self
end

function SpaceKSpline:SetSpline(model: Model?)
    if type(model) ~= "userdata" or model.ClassName ~= "Model" then
        return false
    end
    
    local lastSpline = self.Spline
    self.Spline = model

    --test to see if has segment
    local seg1 = self:GetTrackSegment(1)
    if not seg1.C1 then
        self.Spline = lastSpline
        return false
    end

    local function changed(child)
        if string.find(child.Name, "Curve") then
            self.Changed:Fire()

            if self.Maid.LastMoved then
                self.Maid.LastMoved:Disconnect()
            end

            local lastSeg = self:GetLastTrackSegment()
            if lastSeg then
                self.Maid.LastMoved = lastSeg.C4:GetPropertyChangedSignal("CFrame"):Connect(function()
                    if PluginManager.Enabled then
                        self.Changed:Fire()
                    end
                end)
            end
        end
    end

    self.Maid:DoCleaning()
    self.Maid:GiveTask(model.ChildAdded:Connect(changed))
    self.Maid:GiveTask(model.ChildRemoved:Connect(changed))

    local curve1 = model:FindFirstChild("Curve1")
    if curve1 then
        changed(curve1)
    else
        self.Changed:Fire()
    end
    return true
end

function SpaceKSpline:GetTotalSegments(): number
    local total = 0
    for _, v in self.Spline:GetChildren() do
        if string.find(v.Name, "Curve") then
            total += 1
        end
    end
    return total
end

function SpaceKSpline:GetTrackSegment(n: number): table
    return {
        Points = self.Spline:FindFirstChild("Curve"..n),
        Roll = self.Spline:FindFirstChild("RollPoint"..n),
        C1 = self.Spline:FindFirstChild("Endpoint"..n-1),
        C2 = self.Spline:FindFirstChild("ControlPointA"..n),
        C3 = self.Spline:FindFirstChild("ControlPointB"..n),
        C4 = self.Spline:FindFirstChild("Endpoint"..n)
    }
end

function SpaceKSpline:GetLastTrackSegment(): table?
    local totalSegments = self:GetTotalSegments()
    if totalSegments == 0 then
        return
    end
    return self:GetTrackSegment(totalSegments)
end

function SpaceKSpline:Destroy()
    self.Maid:DoCleaning()
    self = nil --force gc
end

return SpaceKSpline