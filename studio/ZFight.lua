-- ServerStorage.DevTools.ZFight: finds (and optionally fixes) z-fighting in a folder.
-- A z-fight = two block parts with a face on the same plane (within TOL), facing the same way,
-- overlapping with real area, and looking different (colour or material). That's the flicker.
--   local Z = require(game.ServerStorage.DevTools.ZFight:Clone())
--   local pairs = Z.scan(workspace.GameHub)   -- { {a=, b=, axis=, sign=}, ... }
--   Z.fix(pairs)                               -- pulls the smaller part's face 0.05 inward

local M = {}

local TOL = 0.02
local NUDGE = 0.05

local function isBlock(p)
	return p:IsA("Part") and p.Shape == Enum.PartType.Block
end

-- the 6 faces of a block: normal, plane offset, centre, in-plane axes and half extents
local function faces(p)
	local cf, h = p.CFrame, p.Size / 2
	local ax = { { cf.RightVector, h.X }, { cf.UpVector, h.Y }, { cf.LookVector, h.Z } }
	local out = {}
	for i = 1, 3 do
		local j, k = i % 3 + 1, (i + 1) % 3 + 1
		for _, sgn in ipairs({ 1, -1 }) do
			local n = ax[i][1] * sgn
			local centre = cf.Position + n * ax[i][2]
			table.insert(out, {
				axis = i,
				sign = sgn,
				n = n,
				d = n:Dot(centre),
				c = centre,
				u = ax[j][1],
				hu = ax[j][2],
				v = ax[k][1],
				hv = ax[k][2],
			})
		end
	end
	return out
end

local function looksDifferent(a, b)
	if a.Material ~= b.Material then
		return true
	end
	local ca, cb = a.Color, b.Color
	return math.abs(ca.R - cb.R) + math.abs(ca.G - cb.G) + math.abs(ca.B - cb.B) > 0.03
end

local function overlapArea(fa, fb)
	local c = fb.c - fa.c
	local bu = math.abs(fb.u:Dot(fa.u)) * fb.hu + math.abs(fb.v:Dot(fa.u)) * fb.hv
	local bv = math.abs(fb.u:Dot(fa.v)) * fb.hu + math.abs(fb.v:Dot(fa.v)) * fb.hv
	local ou = math.min(c:Dot(fa.u) + bu, fa.hu) - math.max(c:Dot(fa.u) - bu, -fa.hu)
	local ov = math.min(c:Dot(fa.v) + bv, fa.hv) - math.max(c:Dot(fa.v) - bv, -fa.hv)
	if ou <= 0.01 or ov <= 0.01 then
		return 0
	end
	return ou * ov
end

function M.scan(root)
	local parts = {}
	for _, d in ipairs(root:GetDescendants()) do
		if isBlock(d) and d.Transparency < 1 then
			table.insert(parts, d)
		end
	end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { root }
	local id, seen, found = {}, {}, {}
	for i, p in ipairs(parts) do
		id[p] = i
	end
	local fcache = {}
	local function F(p)
		fcache[p] = fcache[p] or faces(p)
		return fcache[p]
	end
	for _, a in ipairs(parts) do
		local near = workspace:GetPartBoundsInBox(a.CFrame, a.Size + Vector3.new(0.1, 0.1, 0.1), params)
		for _, b in ipairs(near) do
			local ia, ib = id[a], id[b]
			if ib and ia < ib and looksDifferent(a, b) then
				local key = ia * 100000 + ib
				if not seen[key] then
					seen[key] = true
					for _, fa in ipairs(F(a)) do
						for _, fb in ipairs(F(b)) do
							-- downward faces sit on the ground and are never seen
							if fa.n.Y > -0.99 and fa.n:Dot(fb.n) > 0.999 and math.abs(fa.d - fb.d) < TOL then
								local area = overlapArea(fa, fb)
								if area > 0 then
									table.insert(found, { a = a, b = b, fa = fa, fb = fb, area = area })
								end
							end
						end
					end
				end
			end
		end
	end
	return found
end

-- Pull the smaller part's offending face inward by NUDGE (size shrinks, centre shifts).
function M.fix(found)
	local fixed = 0
	for _, z in ipairs(found) do
		local small, f = z.a, z.fa
		if z.b.Size.Magnitude < z.a.Size.Magnitude then
			small, f = z.b, z.fb
		end
		local s = small.Size
		local axisSize = ({ s.X, s.Y, s.Z })[f.axis]
		if axisSize > NUDGE * 2 then
			local shrink = Vector3.new(f.axis == 1 and NUDGE or 0, f.axis == 2 and NUDGE or 0, f.axis == 3 and NUDGE or 0)
			local cf = small.CFrame
			small.Size = s - shrink
			small.CFrame = cf - f.n * (NUDGE / 2)
			fixed += 1
		end
	end
	return fixed
end

function M.report(found, limit)
	local lines = {}
	for i = 1, math.min(limit or 15, #found) do
		local z = found[i]
		table.insert(lines, string.format("%s <> %s (area %.1f)", z.a:GetFullName():gsub("Workspace%.GameHub%.", ""),
			z.b:GetFullName():gsub("Workspace%.GameHub%.", ""), z.area))
	end
	return table.concat(lines, "\n")
end

return M
