--non-monotonic lerp method
--v=0.5 a=0 b=10 == 5
local function lerp(t, a, b)
	return (1 - t) * a + t * b
end

local PI = math.pi

--Module Code
local Bezier = {}

function Bezier:GetCenter(s: Vector3, b: Vector3, e: Vector3): Vector3
    local d1 = (s-b).Magnitude
    local d2 = (e-b).Magnitude
    local t = d1/(d1+d2)
    local u = ((1-t)^2)/(t^2+(1-t)^2)
    local c = u*s+(1-u)*e
    local r1 = t^2+(1-t)^2
    local r = math.abs((r1-1)/r1)
    return b+((b-c)/r)
end

--theta in radians
function Bezier:GetCurvePoints(radius: number, theta: number): {Vector2}
    assert(tonumber(theta) and theta >= -math.pi and theta <= math.pi, theta)
    local flip = theta >= 0
    theta = math.abs(theta)

    local k = (4/3) * math.tan(theta/4)
    local s = math.sin(theta)
    local c = math.cos(theta)
    if flip then
        return {
            Vector2.zero,
            radius*k*Vector2.yAxis,
            radius*Vector2.new(1-(c+k*s), s-k*c),
            radius*Vector2.new(1-c, s)
        }
    else
        return {
            Vector2.zero,
            radius*k*Vector2.yAxis,
            radius*Vector2.new((c+k*s)-1, s-k*c),
            radius*Vector2.new(c-1, s)
        }
    end
end

function Bezier:GetRelativeCurveControlPoints(o: CFrame, turnAxis: string, radius: number, theta: number): {Vector3}
    local uPoints = Bezier:GetCurvePoints(radius, theta)

    local function transformVector(v: Vector2): Vector3
        return (Vector3.xAxis*v.X) + (Vector3[turnAxis]*v.Y)
    end

    local p = {}
    for i = 1, 4 do
        local v = transformVector(uPoints[i])
        local w = o:PointToWorldSpace(-v)
        p[i] = w
    end
    return p
end

--"angle" takes in radians
function Bezier:GetHelixControlPoints(endpoint: BasePart, includeRoll: boolean, height: number, radius: number, angle: number): {Vector3}
    --print(endpoint, includeRoll, height, radius, angle)
    local cf = endpoint.CFrame
    local pitch, yaw, roll = cf:ToOrientation()
    if not includeRoll then
        roll = 0
    end

    local startCFrame = (cf * cf.Rotation:Inverse()) * CFrame.fromOrientation(pitch, yaw, roll)
    local points

    if angle == 0 then
        local startPos = startCFrame.Position
        local finalPos = (startCFrame * CFrame.new(0, 0, -radius)).Position
        points = {
            startPos,
            startPos:Lerp(finalPos, 0.333),
            startPos:Lerp(finalPos, 0.666),
            finalPos,
        }
    else
        radius = (1/math.abs(angle)) * radius
        points = Bezier:GetRelativeCurveControlPoints(cf, "zAxis", radius, angle)
    end

    local heightDiff = height/4
    if heightDiff ~= 0 then
        print("height")
    end

    return points
end

return Bezier