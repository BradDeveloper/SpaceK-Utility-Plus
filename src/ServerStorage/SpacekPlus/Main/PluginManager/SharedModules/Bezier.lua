---@diagnostic disable: undefined-type
--@Brad_Devleoper
--De Casteljau's Algorithm Implementation
local Bezier = {__type = "bezier"}

local function GetAlphaAtLength(arcPoints, length)
	for p = 2, #arcPoints do
		local thisPoint = arcPoints[p]
		if thisPoint.Length == length then
			return thisPoint.Alpha
		end

		local lastPoint = arcPoints[p-1]
		if length > lastPoint.Length and length < thisPoint.Length then
			local lenAlpha = (length - lastPoint.Length) / (thisPoint.Length - lastPoint.Length)
			local newAlpha = lastPoint.Alpha + lenAlpha*(thisPoint.Alpha - lastPoint.Alpha)
			return newAlpha
		end
	end
end

local function getFactorial(n: number): number
	--4! = 4 * 3 * 2 * 1
	local f = n
	for i = 1,n-1 do
		f *= i
	end
	return f
end

local function linearBezier(self: Bezier, t: number): Vector3
	local p = self.Points
	return p[1]:Lerp(p[2],t)
end

local function quadraticBezier(self: Bezier, t: number): Vector3
	local p = self.Points
	return (1-t)^2*p[1]+2*(1-t)*t*p[2]+t^2*p[3]
end

local function cubicBezier(self: Bezier, t: number): Vector3
	local p = self.Points
	return (1-t)^3*p[1]+3*(1-t)^2*t*p[2]+3*(1-t)*t^2*p[3]+t^3*p[4]
end

local function complexBezier(self: Bezier, t: number): Vector3
	local n = self.Len
	local nf = getFactorial(n)

	local function getBiCoeff(i)
		--t^0 = 1
		if i == 0 then
			return 1
		end
		return nf/(getFactorial(i)*getFactorial(n-i))
	end

	local sum: Vector3 = Vector3.new(0, 0)
	--Bi,n(t) = (n choose i)*t^i*(1-t)^n-i
	--B(t) = SUM (t) * P[i]
	for i = 0, n-1 do
		local p: Vector3 = self.Points[i+1]--Lua start index = 1, not 0
		local _t = 1-t
		if i ~= n then
			_t ^= n-i
		end
		sum += (getBiCoeff(i)*t^i*_t)*p
	end
	sum+=t^n*self.Points[n]

	return sum
end

Bezier.__index = Bezier

function Bezier.new(points: {Vector3}?)
	local self = setmetatable({}, Bezier)
	if points then
		self:SetPoints(points)
	end
	return self
end

local ARC_LENGTH_COMPILE = 10
function Bezier:ComputeArcLength(): number
	local lut = {}
    local totalArcLength = 0
    local lastPoint
    for i = 0, ARC_LENGTH_COMPILE do
        local alpha = i/ARC_LENGTH_COMPILE
        local point = self:GetPointFromT(alpha)
        if lastPoint then
            totalArcLength += (point-lastPoint).Magnitude
        end
		table.insert(lut, {
			Alpha = alpha,
			Length = totalArcLength,
		})
        lastPoint = point
    end
    return totalArcLength, lut
end

function Bezier:GetArcPoints(gap: number): {number}
	local totalArcLength, arcLengthPoints = self:ComputeArcLength()
    local length = gap / totalArcLength

	--Map Length To Evenly Spaced Alphas
	local alphaMap = table.create(1/length)
	table.insert(alphaMap, 0)
	for l = gap, totalArcLength, gap do
		table.insert(alphaMap, GetAlphaAtLength(arcLengthPoints, l))
	end

	return alphaMap
end

function Bezier:GetFrenetFrame(t)
	local a = self:GetDerivative(t).Unit
	local b = (a+self:GetSecondDerivative()).Unit
	local r = b:Cross(a).Unit
	return {
		o = self:GetPointFromT(t),
		t = a,
		r = r,
		n = r:Cross(a).Unit,
	}
end

function Bezier:GenerateRMFrame(alphaMap)
	local frentFrames = table.create(#alphaMap)
	for i, f in alphaMap do
		frentFrames[i] = self:GetFrenetFrame(f)
	end

	local n = #alphaMap

	local frames = {}

	for i = 1, n-1 do
		local x0 = frentFrames[i]
		local x1 = frentFrames[i+1]

		local v1 = x1.o - x0.o
		local c1 = v1:Dot(v1)

		local riL = x0.r - (2/c1) * v1:Dot(x0.r) * v1
		local tiL = x0.t - (2/c1) * v1:Dot(x0.t) * v1

		local v2 = x1.t - tiL
		local c2 = v2:Dot(v2)

		x1.r = riL - (2/c2) * v2:Dot(riL) * v2
		x1.n = x1.r:Cross(x1.t)

		table.insert(frames, i, x1)
	end
	return frames
end

function Bezier:GetEvenPoints(gap: number): {CFrame}
	local alphaMap = self:GetArcPoints(gap)
	local points = table.create(#alphaMap)
	local frames = self:GenerateRMFrame(alphaMap)
	for _, f in frames do
		table.insert(points, CFrame.fromMatrix(f.o, f.t, Vector3.new(0, 1, 0)))
	end
    return points
end

function Bezier:GetDerivative(t: number): number
	if t == 1 then
		return self:GetDerivative(t-0.001)
	end

	local n = self.Len-1
	local nf = getFactorial(n)

	local function getBiCoeff(i)
		--t^0 = 1
		if i == 0 then
			return 1
		end
		return nf/(getFactorial(i)*getFactorial(n-i))
	end

	local sum: Vector3 = Vector3.new(0, 0)
	--B'(t) = n SUM bi, n-1 (t)(P[i+1]-P[i])
	for i = 0, n-1 do
		local _t = 1-t
		if i ~= n then
			_t ^= n-i
		end

		--Lua start index = 1, not 0
		local p0: Vector3 = self.Points[i+1]
		local p1: Vector3 = self.Points[i+2]
		--(t)(p1-p0)
		sum += (getBiCoeff(i)*t^i*_t)*(p1-p0)
	end
	sum *= n

	return sum
end

function Bezier:GetSecondDerivative()
	return 2*(self.Points[3]-2*self.Points[2]+self.Points[1])
end

function Bezier:SetPoints(points: {Vector3})
	local n = #points
	self.Points = points
	self.Len = n

	--use explicit bezier depending on complexity for performance
	if n < 2 then
		warn("2 Or More Control Points Required")
	elseif n == 2 then--2 control points = just linear interpolation
		self.GetPointFromT = linearBezier
	elseif n == 3 then--3 control points
		self.GetPointFromT = quadraticBezier
	elseif n == 4 then--4 control points
		self.GetPointFromT = cubicBezier
	else--5 or more control points
		self.GetPointFromT = complexBezier
	end
end

function Bezier:Destroy()
	self = nil
end

return Bezier