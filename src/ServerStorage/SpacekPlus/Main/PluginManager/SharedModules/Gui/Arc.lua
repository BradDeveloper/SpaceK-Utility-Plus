local PluginManagerFile = script:FindFirstAncestor("PluginManager")
local PluginManager = require(PluginManagerFile)

local SharedModules = PluginManagerFile.SharedModules
local Signal = require(SharedModules.Signal)

local PI = math.pi
local HALF_PI = PI/2

local ARC_VECT = Vector2.yAxis
local RESET_EPSILON = 0.01

local DEGREE_SYMBOL = utf8.char(0xB0)

local Arc = {}
Arc.__index = Arc

function Arc.new(inputSink, maid, gui)
    local self = setmetatable({
        Rotation = 0,
        ValueGui = gui.Value,
        InputGui = gui.Input,
        ArcLeftGui = gui.Arc.Left.Image.Gradient,
        ArcRightGui = gui.Arc.Right.Image.Gradient,
    }, Arc)

    self.Button = self.InputGui.Rot.Button

    local function beginInput()
        inputSink.Visible = true

        local startPosition = PluginManager.Widget:GetRelativeMousePosition()
        local startRotation = self:GetRotationFromInput(startPosition)
        self:SetRotation(startRotation)

        local event = inputSink.InputChanged:Connect(function(inputObject: InputObject)
            if inputObject.UserInputType ~= Enum.UserInputType.MouseMovement then
                return
            end
            local rotation = self:GetRotationFromInput(inputObject.Position)
            self:SetRotation(rotation)
        end)

        inputSink.MouseButton1Up:Once(function()
            inputSink.Visible = false
            event:Disconnect()
        end)
    end
    maid:GiveTask(self.Button.MouseButton1Down:Connect(beginInput))
    maid:GiveTask(gui.Arc.MouseButton1Down:Connect(beginInput))

    maid:GiveTask(self.ValueGui.FocusLost:Connect(function()
        local deg = tonumber(self.ValueGui.Text)
        if deg then
            deg = math.clamp(math.round(deg), -90, 90)
            self:SetRotation(deg, true)
        else
            self:SetRotation(self.Rotation, true)
        end
    end))

    self:SetRotation(0, true)
    self.Changed = Signal.new()
    return self
end

function Arc:SetRotation(angle: number, override: boolean?)
    if self.Rotation == angle and not override then
        return
    end
    self.Rotation = angle

    --Text
    self.ValueGui.Text = `{angle}{DEGREE_SYMBOL}`

    --Arc Button
    self.InputGui.Rot.Rotation = angle

    --Arc Gradient
    if angle > 0 then
        self.ArcLeftGui.Rotation = 180
        self.ArcRightGui.Rotation = angle
    else
        self.ArcLeftGui.Rotation = 180 + angle
        self.ArcRightGui.Rotation = 0
    end
    
    if self.Changed then
        self.Changed:Fire()
    end
end

function Arc:GetRotationFromInput(position: Vector3)
    local mouseP = Vector2.new(position.X, position.Y)

    local arcPos = self.InputGui.AbsolutePosition
    local arcSize = self.InputGui.AbsoluteSize
    local centerPoint = Vector2.new(
        arcPos.X + arcSize.X*0.5,
        arcPos.Y + arcSize.Y
    )

    local mouseVect = mouseP - centerPoint
    local dirVect = mouseVect - ARC_VECT

    local angle = math.atan2(dirVect.X, dirVect.Y)
    local sign = math.sign(angle)
    if angle < 0 then
        angle = sign * (PI+angle)
    else
        angle = sign * (PI-angle)
    end

    if sign*angle <= RESET_EPSILON then
        angle = 0
    end

    angle = math.clamp(angle, -HALF_PI, HALF_PI)
    return math.round(math.deg(angle))
end

function Arc:GetValue()
    return self.Rotation
end

function Arc:Destroy()
    self.Changed:Destroy()
    self = nil
end

return Arc