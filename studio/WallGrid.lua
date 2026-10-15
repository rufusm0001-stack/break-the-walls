-- ReplicatedStorage.BTW.WallGrid: shared by server and client so the predicted and the real hit pattern match.
-- Breakable cubes are BaseParts under Workspace.World with a Hits attribute, on a Config.CUBE_SIZE grid.
-- 1-stud cubes have half-stud centres (e.g. -15.5), so keys are counted in half studs: rounding a
-- half-integer to a whole stud is ambiguous with float noise, rounding x*2 never is.
local Config = require(script.Parent.Config)

local WallGrid = {}

function WallGrid.key(pos)
	return string.format("%d,%d,%d", math.round(pos.X * 2), math.round(pos.Y * 2), math.round(pos.Z * 2))
end

-- Snap one coordinate to the half-stud grid (for building key lists from positions).
function WallGrid.q(n)
	return math.round(n * 2) / 2
end

function WallGrid.isBreakable(inst)
	return typeof(inst) == "Instance" and inst:IsA("BasePart") and inst:GetAttribute("Hits") ~= nil
		and inst:IsDescendantOf(workspace:FindFirstChild("World") or workspace)
end

-- Snap any vector to its dominant axis (a face normal).
function WallGrid.snap(v)
	local ax, ay, az = math.abs(v.X), math.abs(v.Y), math.abs(v.Z)
	if ax >= ay and ax >= az then
		return Vector3.new(math.sign(v.X), 0, 0)
	elseif ay >= az then
		return Vector3.new(0, math.sign(v.Y), 0)
	end
	return Vector3.new(0, 0, math.sign(v.Z))
end

-- The two in-plane axes for a face normal.
function WallGrid.axes(normal)
	if normal.X ~= 0 then
		return Vector3.new(0, 0, 1), Vector3.new(0, 1, 0)
	elseif normal.Y ~= 0 then
		return Vector3.new(1, 0, 0), Vector3.new(0, 0, 1)
	end
	return Vector3.new(1, 0, 0), Vector3.new(0, 1, 0)
end

-- Cells of a pattern centred on a cube position: { pos, mul, ring }.
function WallGrid.cells(centre, normal, patternName, ringMul)
	local u, v = WallGrid.axes(normal)
	local step = Config.CUBE_SIZE
	local out = {}
	for _, c in ipairs(Config.Patterns[patternName] or Config.Patterns.cross5) do
		table.insert(out, {
			pos = centre + u * (c[1] * step) + v * (c[2] * step),
			mul = c[3] and ringMul or 1,
			ring = c[3],
		})
	end
	return out
end

-- Live index of breakable cubes: key -> part. Keeps itself current as cubes are destroyed.
function WallGrid.index(root)
	local idx = {}
	local function add(d)
		if WallGrid.isBreakable(d) then
			idx[WallGrid.key(d.Position)] = d
		end
	end
	for _, d in ipairs(root:GetDescendants()) do
		add(d)
	end
	root.DescendantAdded:Connect(add)
	root.DescendantRemoving:Connect(function(d)
		if d:IsA("BasePart") and d:GetAttribute("Hits") ~= nil then
			local k = WallGrid.key(d.Position)
			if idx[k] == d then
				idx[k] = nil
			end
		end
	end)
	return idx
end

return WallGrid
