local StudioService = game:GetService("StudioService")

local PluginManagerFile = script:FindFirstAncestor("PluginManager")
local PluginManager = require(PluginManagerFile)

local SharedModules = PluginManagerFile.SharedModules
local Signal = require(SharedModules.Signal)

local CLICK_EPSILON = 0.23

local function createInputFrame(gui): TextBox
    local input = Instance.new("TextBox")
    input.AnchorPoint = Vector2.new(0.5, 0)
    input.Position = UDim2.fromScale(0.5, 0)
    input.Size = UDim2.fromScale(0.5, 1)
    input.ClearTextOnFocus = false
    input.BackgroundTransparency = 0.3
    input.TextStrokeTransparency = 1
    input.TextTransparency = 0.2
    input.TextColor3 = Color3.new(1, 1, 1)
    input.FontFace = Font.fromEnum(Enum.Font.GothamBlack)
    input.Text = gui.Value.Text
    input.TextScaled = true
    input.Parent = gui.Value
    return input
end

local function roundTo(x: number, n: number): number
    if x > 0 then
        return math.ceil(x / n) * n
    elseif x < 0 then
        return math.floor(x / n) * n
    else
        return x
    end
end

local Slider = {}
Slider.__index = Slider

function Slider.new(inputSink, maid, gui, range)
    local self = setmetatable({
        Value = 0,

        ValueMin = range.ValueMin,
        ValueMax = range.ValueMax,
        BarMin = range.BarMin,
        BarMax = range.BarMax,

        Gui = gui,
        Changed = Signal.new()
    }, Slider)

    local lastClick = 0
    local function beginInput()
        inputSink.Visible = true

        if os.clock() - lastClick <= CLICK_EPSILON then
            lastClick = 0
            inputSink.Visible = false
            
            local input = createInputFrame(gui)
            input:CaptureFocus()
            input.SelectionStart = 1
            input.CursorPosition = string.len(input.Text)+1

            gui.Value.TextTransparency = 1
            input.FocusLost:Once(function()
                input:Destroy()
                local value = tonumber(input.Text)
                if value then
                    self:SetValue(value)
                end
                gui.Value.TextTransparency = 0.62
            end)

            return
        end
        lastClick = os.clock()

        local startPosition = PluginManager.Widget:GetRelativeMousePosition()
        self:SetValueFromPosition(startPosition)

        local event = inputSink.InputChanged:Connect(function(inputObject: InputObject)
            if inputObject.UserInputType ~= Enum.UserInputType.MouseMovement then
                return
            end
            self:SetValueFromPosition(inputObject.Position)
        end)

        local leaveEvent, buttonEvent
        local function ended()
            inputSink.Visible = false
            event:Disconnect()
            buttonEvent:Disconnect()
            leaveEvent:Disconnect()
        end
        leaveEvent = inputSink.MouseLeave:Once(ended)
        buttonEvent = inputSink.MouseButton1Up:Once(ended)
    end
    maid:GiveTask(gui.MouseButton1Down:Connect(beginInput))

    self:SetValue(range.Default, true)
    return self
end

function Slider:SetValueFromPosition(pos: (Vector2 | Vector3))
    local barPos = self.Gui.AbsolutePosition.X
    local barSize = self.Gui.AbsoluteSize.X

    local x = math.clamp(pos.X - barPos, 0, barSize) / barSize
    local value = self.BarMin + (self.BarMax - self.BarMin) * x
    self:SetValue(value)
end

function Slider:SetValue(value: number, override: boolean)
    value = math.clamp(value, self.ValueMin, self.ValueMax)

    local step = StudioService.GridSize
    if math.floor(value) ~= value then
        value = roundTo(value, step)
    end

    --natural debounce
    if not override then
        if value == self.Value then
            return
        end
    end
    self.Value = value

    local alpha = (value - self.BarMin) / (self.BarMax - self.BarMin)

    --Value Label
    self.Gui.Value.Text = string.format("%0.3f", value)

    --Fill Line
    local fillAlpha = math.clamp(0.5 * alpha, -0.5, 0.5)
    self.Gui.Fill.Gradient.Offset = Vector2.new(fillAlpha, 0)

    self.Changed:Fire()
end

function Slider:GetValue()
    return self.Value
end

function Slider:Destroy()
    self.Changed:Destroy()
    self = nil
end

return Slider
