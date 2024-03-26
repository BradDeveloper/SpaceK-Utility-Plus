local PluginManagerFile = script:FindFirstAncestor("PluginManager")
local PluginManager = require(PluginManagerFile)

local SharedModules = PluginManagerFile.SharedModules
local Checkbox = require(SharedModules.Gui.Checkbox)
local Slider = require(SharedModules.Gui.Slider)
local Arc = require(SharedModules.Gui.Arc)
local BezierUtility = require(SharedModules.BezierUtility)
local Bezier = require(SharedModules.Bezier)

local NUM_VISUALS = 10

local Helix = {}

function Helix:Show(gui, sessionMaid)
    local inputSink = gui:FindFirstAncestor("GUI").InputSink

    local pluginMaid = PluginManager:GetMaid()
    local visualFolder, enabledState, rollState, heightState, radiusState, turnState

    local sessionBezier = Bezier.new()
    sessionMaid:GiveTask(sessionBezier)

    local function createVisualFolder()
        visualFolder = Instance.new("Folder")
        visualFolder.Name = "HelixVisual"
        for i = 1, NUM_VISUALS do
            local t = Instance.new("ConeHandleAdornment")
            t.Name = i
            t.ZIndex = 1
            t.AlwaysOnTop = true
            t.Transparency = 0.25
            t.Color3 = Color3.fromRGB(0, 132, 255)
            t.Radius = 0.75
            t.Height = 2
            t.Parent = visualFolder
        end
        visualFolder.Parent = PluginManager:GetStorage()
        sessionMaid:GiveTask(visualFolder)
    end

    local function draw()
        local spline = pluginMaid.SplineClass:GetLastTrackSegment()

        local showPreview = if not spline then false else enabledState:GetValue()
        for _, v in visualFolder:GetChildren() do
            v.Visible = showPreview
        end

        if not spline or not showPreview then
            return
        end

        local startPoint = spline.C4
        for _, v in visualFolder:GetChildren() do
            v.Adornee = startPoint
        end

        local includeRoll = rollState:GetValue()
        local height = heightState:GetValue()
        local radius = radiusState:GetValue()
        local turnAngle = -1 * math.rad(turnState:GetValue())

        if radius == 0 then
            return
        end

        local controlPoints = BezierUtility:GetHelixControlPoints(startPoint, includeRoll, height, radius, turnAngle)
        local objectCF = startPoint.CFrame

        Bezier:SetPoints(controlPoints)
        for n = 1, NUM_VISUALS do
            local t = n/NUM_VISUALS

            local tangentPoint = visualFolder[n]
            local point = Bezier:GetPointFromT(t)
            local nextPoint = Bezier:GetPointFromT(t+0.001)
            local tangent = objectCF:PointToObjectSpace(nextPoint)
            local pos = objectCF:PointToObjectSpace(point)
            local cf = CFrame.lookAt(pos, tangent)

            tangentPoint.CFrame = cf
        end
    end

    local db = false
    local function moveSegment(segment)
        if db or not enabledState:GetValue() then
            return
        end
        db = true

        local startPoint = segment.C1
        local includeRoll = rollState:GetValue()
        local height = heightState:GetValue()
        local radius = radiusState:GetValue()
        local turnAngle = -1 * math.rad(turnState:GetValue())

        local controlPoints = BezierUtility:GetHelixControlPoints(startPoint, includeRoll, height, radius, turnAngle)
        segment.C1.Position = controlPoints[1]
        segment.C4.Position = controlPoints[4]

        task.defer(function()
            segment.C2.Position = controlPoints[2]
            segment.C3.Position = controlPoints[3]

            db = false
        end)
    end

    createVisualFolder()

    enabledState = Checkbox.new(gui.Enabled.Button, true)
    sessionMaid:GiveTask(enabledState)
    enabledState.Changed:Connect(draw)

    rollState = Checkbox.new(gui.FollowRoll.Button, false)
    sessionMaid:GiveTask(rollState)
    rollState.Changed:Connect(draw)

    heightState = Slider.new(inputSink, sessionMaid, gui.Height.Button, {Default = 0, BarMin = -50, BarMax = 50, ValueMin = -2048, ValueMax = 2048})
    sessionMaid:GiveTask(heightState)
    heightState.Changed:Connect(draw)

    radiusState = Slider.new(inputSink, sessionMaid, gui.Radius.Button, {Default = 25, BarMin = 0, BarMax = 100, ValueMin = 0, ValueMax = 2048})
    sessionMaid:GiveTask(radiusState)
    radiusState.Changed:Connect(draw)

    turnState = Arc.new(inputSink, sessionMaid, gui.Turn)
    sessionMaid:GiveTask(turnState)
    turnState.Changed:Connect(draw)

    sessionMaid:GiveTask(pluginMaid.SplineClass.Changed:Connect(function(added: boolean)
        if added then
            local segment = pluginMaid.SplineClass:GetLastTrackSegment()
            moveSegment(segment)
        end
        draw()
    end))
    draw()
end

return Helix