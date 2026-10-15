-- ServerStorage.DevTools.BuildWorld: builds Zones 1-3 of Break The Walls from code.
-- Usage from execute_luau (Edit mode), one zone per call so Studio never freezes:
--   local B = require(game.ServerStorage.DevTools.BuildWorld:Clone())
--   B.init(require(game.ServerStorage.DevTools.StudKit:Clone()), require(game.ReplicatedStorage.BTW.Config:Clone()))
--   B.lighting(); B.zone1(); B.zone2(); B.zone3()
-- Layout runs along -Z. Floor top is Y = 0. Palette is docs/STYLE_BIBLE.md (facility), NOT the skill defaults.
-- Placeholders: every machine is a Model "<Name>_Placeholder" with a "Visual" model (swap for a mesh later)
-- and a "Function" folder (trigger zones / anchors that scripts use). Keep the Function parts when swapping.

local Lighting = game:GetService("Lighting")

local B = {}
local K, C
local hex

local P = {} -- palette, filled in init
local rng = Random.new(20261015)

function B.init(studKit, config)
	K, C = studKit, config
	hex = K.hex
	P = {
		tileL = hex("B8BEC8"), tileD = hex("8E99A8"), panel = hex("6B7280"), pillar = hex("565C68"),
		ceiling = hex("4A505C"), yellow = hex("FFC627"), black = hex("1E1E24"), metal = hex("3A3F4B"),
		screen = hex("1FA7E0"), lightPanel = hex("E8ECF2"), walk = hex("7A8494"),
		green = hex("3FD45B"), red = hex("E5322D"), amber = hex("FFB000"), amberLight = hex("FFC46B"),
		rock = { hex("6B4B3A"), hex("553A2D"), hex("634536") }, dirt = { hex("8A6A4F"), hex("7E6047") },
		wood = hex("8B5A2B"), woodDark = hex("6E4A26"), railSteel = hex("9AA0A8"),
		steel = hex("4E6A8A"), tileVault = hex("6F7A8A"), cardboard = hex("C9A26B"), plant = hex("4CAF50"),
		pot = hex("D9483B"), lanternGlow = hex("FF9A00"), -- FFB000 neon rendered lemon yellow
	}
end

-- ===== small helpers =====

local function part(parent, size, cf, color, opts)
	return K.part(parent, size, cf, color, opts)
end

-- box from min/max corners (axis aligned)
local function box(parent, x0, y0, z0, x1, y1, z1, color, opts)
	local lo = Vector3.new(math.min(x0, x1), math.min(y0, y1), math.min(z0, z1))
	local hi = Vector3.new(math.max(x0, x1), math.max(y0, y1), math.max(z0, z1))
	return part(parent, hi - lo, CFrame.new((lo + hi) / 2), color, opts)
end

local function folder(parent, name)
	return parent:FindFirstChild(name) or K.folder(parent, name)
end

local function surfaceLight(p, color, range, brightness, face)
	local l = Instance.new("SurfaceLight")
	l.Face = face or Enum.NormalId.Bottom
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Angle = 120
	l.Shadows = false
	l.Parent = p
	return l
end

local function cylinder(parent, radius, height, pos, color, opts)
	opts = opts or {}
	opts.shape = Enum.PartType.Cylinder
	opts.top = false
	-- cylinder axis is X; turn it upright
	return part(parent, Vector3.new(height, radius * 2, radius * 2), CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), color, opts)
end

-- ===== rooms =====
-- spec: name, x0 < x1, zA (back, larger z) > zB (front), h, style "facility"|"cave"|"vault",
-- walls = { back = {t=, openings={{a,b,top}}, noJitter=bool} or false, front=..., left=..., right=... }
local SIDES = {
	back = { along = "X", out = 1 }, front = { along = "X", out = -1 },
	left = { along = "Z", out = -1 }, right = { along = "Z", out = 1 },
}

local function sideInner(spec, side)
	if side == "back" then return spec.zA elseif side == "front" then return spec.zB
	elseif side == "left" then return spec.x0 else return spec.x1 end
end

-- one wall slab: along-range a..b, height y0..y1, depth d0..d1 measured outward from the inner face
local function slab(parent, spec, side, a, b, y0, y1, d0, d1, color, opts)
	local s = SIDES[side]
	local inner = sideInner(spec, side)
	local n0, n1 = inner + s.out * d0, inner + s.out * d1
	if s.along == "X" then
		return box(parent, a, y0, n0, b, y1, n1, color, opts)
	else
		return box(parent, n0, y0, a, n1, y1, b, color, opts)
	end
end

local function alongRange(spec, side)
	local w = spec.walls
	if SIDES[side].along == "X" then
		return spec.x0, spec.x1
	end
	-- side walls cover the corners of back/front walls that exist
	local tb = w.back and w.back.t or 0
	local tf = w.front and w.front.t or 0
	return spec.zB - tf, spec.zA + tb
end

-- splits [a,b] into solid pieces (full height) and opening pieces (top..h)
local function pieces(a, b, openings, h)
	local cuts = {}
	for _, o in ipairs(openings or {}) do
		table.insert(cuts, { math.min(o[1], o[2]), math.max(o[1], o[2]), o[3] })
	end
	table.sort(cuts, function(p, q) return p[1] < q[1] end)
	local out, x = {}, a
	for _, c in ipairs(cuts) do
		if c[1] > x then table.insert(out, { x, c[1], -1, h }) end
		table.insert(out, { c[1], c[2], -1, 0, sill = true }) -- floor through the opening
		if c[3] < h then table.insert(out, { c[1], c[2], c[3], h }) end
		x = c[2]
	end
	if x < b then table.insert(out, { x, b, -1, h }) end
	return out
end

local function inOpening(v, openings, y)
	for _, o in ipairs(openings or {}) do
		if v > math.min(o[1], o[2]) - 0.01 and v < math.max(o[1], o[2]) + 0.01 and (y == nil or y < o[3]) then
			return true
		end
	end
	return false
end

local function facilityWall(f, spec, side, wall, accent)
	local a, b = alongRange(spec, side)
	local h = spec.h
	local panel = spec.style == "vault" and P.panel or P.panel
	for _, pc in ipairs(pieces(a, b, wall.openings, h)) do
		slab(f, spec, side, pc[1], pc[2], pc[3], pc[4], 0, wall.t, pc.sill and P.tileD or panel, { name = pc.sill and "Sill" or "Wall" })
	end
	-- pillars every 12 along the interior span, plus a hazard band between them
	local ia, ib = (SIDES[side].along == "X") and spec.x0 or spec.zB, (SIDES[side].along == "X") and spec.x1 or spec.zA
	local pillarsAt = {}
	local v = ia + 6
	while SIDES[side].along == "Z" and v < ib - 3 do -- pillars on side walls only (back/front walls carry boards)
		if not inOpening(v, wall.openings) and not inOpening(v - 1.5, wall.openings) and not inOpening(v + 1.5, wall.openings) then
			local pc = spec.style == "vault" and P.steel or P.pillar
			slab(f, spec, side, v - 1, v + 1, 0, h, -1, 0, pc, { name = "Pillar" })
			table.insert(pillarsAt, v)
			if accent and spec.style == "vault" then
				-- red alarm beacon on every vault pillar
				local beacon = slab(f, spec, side, v - 0.6, v + 0.6, 18, 19.2, -1.8, -1, P.red, { name = "AlarmBeacon", material = Enum.Material.Neon, top = false })
				K.light(beacon, P.red, 7, 0.5) -- stronger washed the vault walls pink
			end
		end
		v += 12
	end
	-- hazard band (yellow / black, 2-stud stripes) at y 2..3.5
	local i = 0
	local endInset = SIDES[side].along == "X" and 0.4 or 0 -- side-wall bands own the corners
	local x = ia + endInset
	local bandEnd = ib - endInset
	while x < bandEnd - 0.01 do
		local x2 = math.min(x + 2, bandEnd)
		local blocked = inOpening((x + x2) / 2, wall.openings, 3)
		for _, r in ipairs(wall.noBand or {}) do
			if x2 > r[1] and x < r[2] then blocked = true end
		end
		for _, pv in ipairs(pillarsAt) do
			if x2 > pv - 1 and x < pv + 1 then blocked = true end
		end
		if not blocked then
			slab(f, spec, side, x, x2, 2, 3.5, -0.4, 0, (i % 2 == 0) and P.yellow or P.black, { name = "Hazard", top = false })
		end
		i += 1
		x = x2
	end
end

local function caveWall(f, spec, side, wall)
	local a, b = alongRange(spec, side)
	local h = spec.h
	for _, pc in ipairs(pieces(a, b, wall.openings, h)) do
		if pc.sill then
			slab(f, spec, side, pc[1], pc[2], -1, 0, 0, wall.t, P.dirt[1], { name = "TunnelFloor" })
			continue
		end
		local x = pc[1]
		while x < pc[2] - 0.01 do
			local x2 = math.min(x + 4, pc[2])
			local y = pc[3]
			while y < pc[4] - 0.01 do
				local y2 = math.min(y + 4, pc[4])
				local mid = (x + x2) / 2
				-- no jitter at slab ends next to openings/corners, or where a sign hangs
				local edge = (x == pc[1] or x2 == pc[2])
				if SIDES[side].along == "Z" and (mid < spec.zB + 4 or mid > spec.zA - 4) then edge = true end
				local j = (wall.noJitter or edge) and 0 or ({ 0, 0, 0.5, 1, 1.5 })[rng:NextInteger(1, 5)]
				if wall.noJitter and type(wall.noJitter) == "table" then
					j = (mid > wall.noJitter[1] and mid < wall.noJitter[2]) and 0 or j
				end
				local col = P.rock[rng:NextInteger(1, #P.rock)]
				-- a jittered block must not dip into the floor slab (y -1..0) or their faces fight
				slab(f, spec, side, x, x2, (j > 0 and y < 0) and 0 or y, y2, -j, wall.t, col, { name = "Rock" })
				y = y2
			end
			x = x2
		end
	end
end

local function room(parent, spec)
	local f = folder(parent, spec.name)
	local shell = folder(f, "Shell")
	local w = spec.walls
	-- floor
	local tile = spec.style == "cave" and 4 or 8
	local x = spec.x0
	local ix = 0
	while x < spec.x1 - 0.01 do
		local x2 = math.min(x + tile, spec.x1)
		local z = spec.zA
		local iz = 0
		while z > spec.zB + 0.01 do
			local z2 = math.max(z - tile, spec.zB)
			local col
			if spec.style == "cave" then
				col = P.dirt[rng:NextInteger(1, #P.dirt)]
			elseif spec.style == "vault" then
				col = ((ix + iz) % 2 == 0) and P.tileD or P.tileVault
			else
				col = ((ix + iz) % 2 == 0) and P.tileL or P.tileD
			end
			box(shell, x, -1, z, x2, 0, z2, col, { name = "Floor" })
			z = z2
			iz += 1
		end
		x = x2
		ix += 1
	end
	-- walls
	for side, wall in pairs(w) do
		if wall then
			if spec.style == "cave" then
				caveWall(shell, spec, side, wall)
			else
				facilityWall(shell, spec, side, wall, true)
			end
		end
	end
	-- ceiling (covers the walls too)
	local tl = w.left and w.left.t or 0
	local tr = w.right and w.right.t or 0
	local tb = w.back and w.back.t or 0
	local tf = w.front and w.front.t or 0
	box(shell, spec.x0 - tl, spec.h, spec.zB - tf, spec.x1 + tr, spec.h + 1,
		spec.zA + tb, spec.style == "cave" and P.rock[2] or P.ceiling, { name = "Ceiling", top = false })
	return f
end

-- ceiling light panels (facility / vault)
local function ceilingLights(parent, xs, zs, h)
	local f = folder(parent, "Lights")
	for _, x in ipairs(xs) do
		for _, z in ipairs(zs) do
			local p = box(f, x - 5, h - 0.4, z - 1, x + 5, h, z + 1, P.lightPanel, { name = "LightPanel", material = Enum.Material.Neon, top = false, shadow = false })
			surfaceLight(p, hex("F2F4F8"), 20, 0.32)
		end
	end
end

-- hanging cave lantern (chain + amber lantern)
local function lantern(parent, x, z, yTop)
	local m = K.model(parent, "Lantern")
	box(m, x - 0.15, yTop - 3, z - 0.15, x + 0.15, yTop, z + 0.15, P.black, { name = "Chain", top = false })
	box(m, x - 0.9, yTop - 3.4, z - 0.9, x + 0.9, yTop - 3, z + 0.9, P.woodDark, { name = "Cap", top = false })
	local head = box(m, x - 0.7, yTop - 5.2, z - 0.7, x + 0.7, yTop - 3.4, z + 0.7, P.lanternGlow, { name = "Glow", material = Enum.Material.Neon, top = false })
	box(m, x - 0.9, yTop - 5.6, z - 0.9, x + 0.9, yTop - 5.2, z + 0.9, P.woodDark, { name = "Base", top = false })
	K.light(head, P.amberLight, 16, 0.6) -- brighter lanterns turned the whole cave orange
	return m
end

-- ===== breakable walls =====
-- fills x0..x0+w*s, y 0..h*s, z from zFace going -Z for d cubes (s = C.CUBE_SIZE)
-- Walls draw colours from their own seeded Random so a wall rebuild never shifts the rest of the layout.
local wallRng = Random.new(20261016)
local function breakable(parent, zone, x0, zFace, wCubes, hCubes, dCubes, opts)
	opts = opts or {}
	local f = folder(parent, opts.name or "BreakableWall")
	local cube = C.Zones[zone].cube
	local s = C.CUBE_SIZE
	local n = 0
	for ix = 0, wCubes - 1 do
		if ix % 4 == 3 then task.wait() end -- thousands of parts: yield so Studio never freezes
		for iy = 0, hCubes - 1 do
			for iz = 0, dCubes - 1 do
				local colHex = cube.colors[wallRng:NextInteger(1, #cube.colors)]
				local p = part(f, Vector3.new(s, s, s),
					CFrame.new(x0 + ix * s + s / 2, (opts.y0 or 0) + iy * s + s / 2, zFace - iz * s - s / 2), hex(colHex), { name = "Cube" })
				p:SetAttribute("Zone", zone)
				p:SetAttribute("Hits", cube.hits)
				p:SetAttribute("Value", cube.value)
				if opts.hidden then p:SetAttribute("HiddenPassage", true) end
				n += 1
			end
		end
	end
	f:SetAttribute("Zone", zone)
	f:SetAttribute("CubeCount", n)
	return f
end

-- Each zone's main breakable wall fills its 32 x 20 doorway at zFace; layers past the 4-stud doorway wall reach
-- into the corridor behind (that corridor's hazard band leaves a gap there, see CORRIDOR_NOBAND).
local MAIN_WALL = { { x0 = -16, zFace = -48 }, { x0 = -16, zFace = -152 }, { x0 = -16, zFace = -268 } }
local function mainWall(Z, zone)
	local m = MAIN_WALL[zone]
	return breakable(Z, zone, m.x0, m.zFace, C.WALL_CUBES.w, C.WALL_CUBES.h, C.Zones[zone].wallDepth)
end
local function corridorNoBand(zone)
	local m = MAIN_WALL[zone]
	local back = m.zFace - C.Zones[zone].wallDepth * C.CUBE_SIZE
	return { { back - 2, m.zFace } }
end
-- the Zone 2 ore vein: an 8 x 6 x 4 stud cluster in the left tunnel
local function veinWall(leftEnd)
	local s = C.CUBE_SIZE
	return breakable(leftEnd, 2, -26, -124, math.round(8 / s), math.round(6 / s), math.round(4 / s), { name = "HiddenVein", hidden = true })
end

-- Rebuild only the breakable walls of zone n (after a CUBE_SIZE / depth change), without touching the rest.
-- Removes hazard stripes that now sit inside the deeper wall. Run Play-stopped, one zone per call.
function B.rebuildWalls(n)
	local Z = workspace.World:FindFirstChild("Zone" .. n)
	assert(Z, "no Zone" .. n)
	local old = Z:FindFirstChild("BreakableWall")
	if old then old:Destroy() end
	local m = MAIN_WALL[n]
	local d = C.Zones[n].wallDepth * C.CUBE_SIZE
	local box = CFrame.new(m.x0 + C.WALL_CUBES.w * C.CUBE_SIZE / 2, C.WALL_CUBES.h * C.CUBE_SIZE / 2, m.zFace - d / 2)
	local size = Vector3.new(C.WALL_CUBES.w * C.CUBE_SIZE - 0.1, C.WALL_CUBES.h * C.CUBE_SIZE - 0.1, d - 0.1)
	local removed = 0
	for _, p in ipairs(workspace:GetPartBoundsInBox(box, size)) do
		if p.Name == "Hazard" and p:IsDescendantOf(Z) then
			p:Destroy()
			removed += 1
		end
	end
	local f = mainWall(Z, n)
	if n == 2 then
		local leftEnd = Z:FindFirstChild("LeftTunnel")
		local vein = leftEnd and leftEnd:FindFirstChild("HiddenVein")
		if vein then vein:Destroy() end
		if leftEnd then veinWall(leftEnd) end
	end
	return f:GetAttribute("CubeCount"), removed
end

-- ===== placeholders (Visual + Function) =====

local function placeholder(parent, name)
	local m = K.model(parent, name .. "_Placeholder")
	local vis = K.model(m, "Visual")
	local fn = K.folder(m, "Function")
	return m, vis, fn
end

local function trigger(parent, name, size, cf, zone)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = true
	p.Transparency = 1
	p.Size = size
	p.CFrame = cf
	p:SetAttribute("Zone", zone)
	p.Parent = parent
	return p
end

-- cf: base centre on the floor; the machine's front faces cf.LookVector
function B.depositMachine(parent, cf, zone, accent, body)
	local m, vis, fn = placeholder(parent, "DepositMachine")
	body = body or P.metal
	local function at(x, y, z) return cf * CFrame.new(x, y, z) end
	part(vis, Vector3.new(10, 6, 7), at(0, 3, 1.5), body, { name = "Housing" })
	-- intake ramp (belt) rising from the front into the housing
	local rise, run = 5, 7
	local len = math.sqrt(rise * rise + run * run)
	local ang = math.atan2(rise, run) -- applied as -ang: the belt rises from the low front lip up into the housing
	local beltCf = at(0, 0.6 + rise / 2, -2 - run / 2) * CFrame.Angles(-ang, 0, 0)
	part(vis, Vector3.new(6, 0.6, len), beltCf, P.metal, { name = "Belt", top = false }) -- black read as a void up close
	for i = -3, 3 do
		part(vis, Vector3.new(5.6, 0.2, 0.5), beltCf * CFrame.new(0, 0.4, i * len / 8), P.pillar, { name = "Tread", top = false })
	end
	for _, sx in ipairs({ -3.3, 3.3 }) do
		part(vis, Vector3.new(0.6, 1.2, len), at(sx, 0.9 + rise / 2, -2 - run / 2) * CFrame.Angles(-ang, 0, 0), accent, { name = "Rail", material = Enum.Material.Neon, top = false })
	end
	-- cubes riding the belt
	for i = 1, 3 do
		local t = i / 4
		part(vis, Vector3.new(1.2, 1.2, 1.2), beltCf * CFrame.new(rng:NextNumber(-1.5, 1.5), 0.95, (t - 0.5) * len),
			hex(C.Zones[zone].cube.colors[1]), { name = "RidingCube" })
	end
	-- neon corner strips on the housing
	for _, sx in ipairs({ -5.2, 5.2 }) do
		part(vis, Vector3.new(0.4, 6, 0.4), at(sx, 3, -2.2), accent, { name = "Strip", material = Enum.Material.Neon, top = false })
	end
	-- screen on top
	-- screen on a short neck, raised so the front neon never crosses its text
	part(vis, Vector3.new(3, 1.5, 1), at(0, 6.75, 3), body, { name = "ScreenNeck" })
	part(vis, Vector3.new(9, 4, 1), at(0, 9.5, 3), body, { name = "ScreenFrame" })
	local screen = part(fn, Vector3.new(8, 3, 0.4), at(0, 9.5, 2.3), hex("16324A"), { name = "CounterScreen", top = false })
	K.boardText(screen, Enum.NormalId.Front, "DEPOSIT", { color = accent, stroke = P.black })
	trigger(fn, "DepositZone", Vector3.new(10, 8, 8), at(0, 4, -6), zone)
	m:SetAttribute("Zone", zone)
	return m
end

function B.toolPodium(parent, cf, zone, accent)
	local m, vis, fn = placeholder(parent, "ToolPodium")
	local function at(x, y, z) return cf * CFrame.new(x, y, z) end
	part(vis, Vector3.new(6, 3, 6), at(0, 1.5, 0), P.pillar, { name = "Pedestal" })
	part(vis, Vector3.new(6.4, 0.4, 6.4), at(0, 3.2, 0), P.yellow, { name = "Trim" })
	-- hammer on display (placeholder)
	local anchor = trigger(fn, "DisplayAnchor", Vector3.new(1, 1, 1), at(0, 6, 0), zone)
	anchor.CanTouch = false
	part(vis, Vector3.new(0.6, 3.6, 0.6), at(0, 5.4, 0) * CFrame.Angles(0, 0, math.rad(12)), P.wood, { name = "HammerHandle", top = false })
	part(vis, Vector3.new(2.8, 1.4, 1.4), at(-0.4, 7.1, 0) * CFrame.Angles(0, 0, math.rad(12)), P.metal, { name = "HammerHead", top = false })
	-- sign behind
	for _, sx in ipairs({ -3.5, 3.5 }) do
		part(vis, Vector3.new(0.6, 10, 0.6), at(sx, 5, 3.6), P.metal, { name = "SignPost", top = false })
	end
	local board = part(vis, Vector3.new(8, 2.4, 0.6), at(0, 11.2, 3.6), accent, { name = "SignBoard", top = false })
	K.boardText(board, Enum.NormalId.Front, "TOOLS", { stroke = K.darker(accent, 0.6) })
	trigger(fn, "BuyZone", Vector3.new(8, 6, 8), at(0, 3, -2), zone)
	m:SetAttribute("Zone", zone)
	return m
end

-- wall-mounted board; cf = centre of the board's back face on the wall, LookVector = out of the wall
function B.upgradeBoard(parent, cf, zone, width)
	width = width or 16
	local m, vis, fn = placeholder(parent, "UpgradeBoard")
	part(vis, Vector3.new(width + 1, 9, 1), cf * CFrame.new(0, 0, -0.5) * CFrame.Angles(0, math.pi, 0), P.metal, { name = "Frame", top = false })
	local screen = part(fn, Vector3.new(width, 8, 0.4), cf * CFrame.new(0, 0, -1.2) * CFrame.Angles(0, math.pi, 0), P.screen, { name = "Screen", top = false })
	-- after the 180 turn the board's Back face points out of the wall
	K.boardText(screen, Enum.NormalId.Back, "UPGRADES", { stroke = hex("0B3A55") })
	trigger(fn, "PromptPart", Vector3.new(width, 8, 6), cf * CFrame.new(0, -2, -4), zone)
	m:SetAttribute("Zone", zone)
	return m
end

-- sign board on a wall face; cf as for upgradeBoard
local function wallSign(parent, cf, w, h, text, color, textColor)
	local m = K.model(parent, "Sign")
	part(m, Vector3.new(w + 1, h + 1, 0.4), cf * CFrame.new(0, 0, -0.2), K.darker(color, 0.5), { name = "Trim", top = false })
	local b = part(m, Vector3.new(w, h, 0.6), cf * CFrame.new(0, 0, -0.7) * CFrame.Angles(0, math.pi, 0), color, { name = "Board", top = false })
	K.boardText(b, Enum.NormalId.Back, text, { color = textColor or Color3.new(1, 1, 1), stroke = K.darker(color, 0.6) })
	return m
end

local function spawnPad(parent, pos, zone, accent, enabled)
	local s = Instance.new("SpawnLocation")
	s.Name = "Spawn_Zone" .. zone
	s.Anchored = true
	s.Size = Vector3.new(8, 0.6, 8)
	s.CFrame = CFrame.new(pos.X, 0.3, pos.Z)
	s.Color = accent
	s.Material = Enum.Material.Plastic
	s.TopSurface = Enum.SurfaceType.Studs
	s.Neutral = true
	s.Duration = 0
	s.Enabled = enabled
	s:SetAttribute("Zone", zone)
	local decal = s:FindFirstChildOfClass("Decal")
	if decal then decal:Destroy() end
	s.Parent = parent
	return s
end

-- ===== props =====

local function crate(parent, x, z, size, yaw, y0)
	local m = K.model(parent, "Crate")
	local cf = CFrame.new(x, (y0 or 0) + size / 2, z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	part(m, Vector3.new(size, size, size), cf, P.cardboard, { name = "Box" })
	part(m, Vector3.new(size * 0.3, 0.1, size + 0.1), cf * CFrame.new(0, size / 2 + 0.05, 0), hex("A9844E"), { name = "Tape", top = false })
	return m
end

local function crateCluster(parent, x, z)
	crate(parent, x, z, 4, rng:NextNumber(-12, 12))
	crate(parent, x + 4.2, z + rng:NextNumber(-0.6, 0.6), 3, rng:NextNumber(-12, 12))
	crate(parent, x + 0.3, z, 2.6, rng:NextNumber(-15, 15), 4)
end

local function plant(parent, x, z)
	local m = K.model(parent, "Plant")
	part(m, Vector3.new(3, 2.4, 3), CFrame.new(x, 1.2, z), P.pot, { name = "Pot" })
	part(m, Vector3.new(2.4, 0.2, 2.4), CFrame.new(x, 2.5, z), hex("6B4226"), { name = "Soil", top = false })
	part(m, Vector3.new(3.4, 3, 3.4), CFrame.new(x, 4.1, z), P.plant, { name = "Leaves" })
	part(m, Vector3.new(2.2, 1.8, 2.2), CFrame.new(x, 6.5, z) * CFrame.Angles(0, 0.5, 0), hex("5DBE60"), { name = "Leaves" })
	return m
end

local function barrel(parent, x, z, color)
	local m = K.model(parent, "Barrel")
	cylinder(m, 1.4, 3.6, Vector3.new(x, 1.8, z), color or P.wood, { name = "Body" })
	cylinder(m, 1.5, 0.4, Vector3.new(x, 2.6, z), P.black, { name = "Hoop" })
	m.WorldPivot = CFrame.new(x, 0, z) -- upright pivot, or bounds use the cylinder's turned axes
	return m
end

local function crystal(parent, x, z, s)
	local m = K.model(parent, "CrystalCluster")
	part(m, Vector3.new(1.4, 4, 1.4) * s, CFrame.new(x, 2 * s, z) * CFrame.Angles(0, 0.3, math.rad(8)), hex("E07A2E"), { name = "Crystal", material = Enum.Material.Neon, top = false })
	part(m, Vector3.new(1, 2.6, 1) * s, CFrame.new(x + 1.2 * s, 1.3 * s, z + 0.4) * CFrame.Angles(0, 0.8, math.rad(-18)), hex("F2A04A"), { name = "Crystal", top = false })
	part(m, Vector3.new(0.9, 2, 0.9) * s, CFrame.new(x - 1 * s, 1 * s, z - 0.6) * CFrame.Angles(0, 1.2, math.rad(15)), hex("D96A1E"), { name = "Crystal", top = false })
	m.WorldPivot = CFrame.new(x, 0, z)
	return m
end

local function mineCart(parent, x, z)
	local m, vis = placeholder(parent, "MineCart")
	part(vis, Vector3.new(4, 2.6, 5.6), CFrame.new(x, 2.3, z), hex("5D626B"), { name = "Bucket" })
	part(vis, Vector3.new(3.2, 0.4, 4.8), CFrame.new(x, 3.8, z), hex("E07A2E"), { name = "OreLoad" })
	for _, dz in ipairs({ -1.8, 1.8 }) do
		cylinder(vis, 0.6, 4.6, Vector3.new(x, 0.9, z + dz), P.black, { name = "Wheels" }).CFrame =
			CFrame.new(x, 0.95, z + dz)
	end
	m.WorldPivot = CFrame.new(x, 0, z)
	vis.WorldPivot = CFrame.new(x, 0, z)
	return m
end

local function serverRack(parent, x, z, yaw)
	local m = K.model(parent, "ServerRack")
	local cf = CFrame.new(x, 4.5, z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	part(m, Vector3.new(3, 9, 3), cf, P.metal, { name = "Rack" })
	for i = 0, 3 do
		part(m, Vector3.new(2.2, 0.4, 0.2), cf * CFrame.new(0, -3 + i * 2, -1.6), P.screen,
			{ name = "Leds", material = Enum.Material.Neon, top = false })
	end
	return m
end

-- wall decor: screen, vent, alarm light, camera. cf on wall surface, LookVector out of the wall
local function wallScreen(parent, cf)
	local m = K.model(parent, "WallScreen")
	part(m, Vector3.new(6, 4, 0.6), cf * CFrame.new(0, 0, -0.3), P.metal, { name = "Frame", top = false })
	part(m, Vector3.new(5, 3, 0.2), cf * CFrame.new(0, 0, -0.7), P.screen, { name = "Screen", material = Enum.Material.Neon, top = false })
	return m
end

local function vent(parent, cf)
	local m = K.model(parent, "Vent")
	part(m, Vector3.new(5, 3, 0.4), cf * CFrame.new(0, 0, -0.2), P.metal, { name = "Frame", top = false })
	for i = -1, 1 do
		part(m, Vector3.new(4.2, 0.4, 0.3), cf * CFrame.new(0, i * 0.8, -0.55), P.pillar, { name = "Slat", top = false })
	end
	return m
end

local function alarmLight(parent, cf)
	local m = K.model(parent, "AlarmLight")
	part(m, Vector3.new(1.6, 0.6, 0.6), cf * CFrame.new(0, -0.6, -0.3), P.metal, { name = "Base", top = false })
	local g = part(m, Vector3.new(1.2, 1.2, 1), cf * CFrame.new(0, 0.3, -0.5), P.red, { name = "Glow", material = Enum.Material.Neon, top = false })
	K.light(g, P.red, 6, 0.6)
	return m
end

local function securityCam(parent, cf)
	local m = K.model(parent, "SecurityCam")
	part(m, Vector3.new(1, 1, 1.2), cf * CFrame.new(0, 0, -0.6), P.metal, { name = "Mount", top = false })
	part(m, Vector3.new(1.4, 1.2, 2.6), cf * CFrame.new(0, -0.6, -2) * CFrame.Angles(math.rad(-20), 0, 0), hex("D6DAE0"), { name = "Body", top = false })
	part(m, Vector3.new(0.5, 0.5, 0.2), cf * CFrame.new(0, -1.1, -3.3) * CFrame.Angles(math.rad(-20), 0, 0), P.red, { name = "Lens", material = Enum.Material.Neon, top = false })
	return m
end

local WALL_L = CFrame.Angles(0, math.rad(-90), 0) -- on a left wall (x0), looking +X
local WALL_R = CFrame.Angles(0, math.rad(90), 0) -- on a right wall (x1), looking -X
local WALL_BACK = CFrame.Angles(0, 0, 0) -- on a back wall (zA), looking -Z
local WALL_FRONT = CFrame.Angles(0, math.pi, 0) -- on a front wall (zB), looking +Z

-- walkway overlay with yellow edge lines (z from zA to zB, centred on x)
local function walkway(parent, x, zA, zB, w)
	local f = folder(parent, "Walkway")
	box(f, x - w / 2, 0, zB, x + w / 2, 0.2, zA, P.walk, { name = "Walk", top = false })
	box(f, x - w / 2 - 0.6, 0, zB, x - w / 2, 0.2, zA, P.yellow, { name = "Edge", top = false })
	box(f, x + w / 2, 0, zB, x + w / 2 + 0.6, 0.2, zA, P.yellow, { name = "Edge", top = false })
end

-- ===== lighting (neutral, cool: STYLE_BIBLE) =====
function B.lighting()
	-- tuned in Studio 2026-10-15: indoors, the SurfaceLights do most of the work; more ambient washes the floor white
	Lighting.Ambient = Color3.fromRGB(148, 152, 160)
	Lighting.OutdoorAmbient = Color3.fromRGB(128, 132, 140)
	Lighting.Brightness = 1
	Lighting.ClockTime = 13
	Lighting.ColorShift_Top = hex("DCE0E6")
	Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
	Lighting.EnvironmentDiffuseScale = 0.25
	Lighting.EnvironmentSpecularScale = 0.2
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.3
	Lighting.ExposureCompensation = 0
	Lighting.FogColor = hex("9AA0AA")
	Lighting.FogStart = 200
	Lighting.FogEnd = 600
	for _, e in ipairs(Lighting:GetChildren()) do
		if e:IsA("Atmosphere") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") or e:IsA("SunRaysEffect") then
			e:Destroy()
		end
	end
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
	cc.Name = "BaseColorCorrection"
	cc.Brightness, cc.Contrast, cc.Saturation, cc.TintColor = 0, 0.15, 0.05, Color3.new(1, 1, 1)
	cc.Parent = Lighting
end

local function zoneFolder(n)
	local root = folder(workspace, "World")
	local f = root:FindFirstChild("Zone" .. n)
	if f then f:Destroy() end
	f = K.folder(root, "Zone" .. n)
	return f, folder(f, "Props"), folder(f, "WallDecor"), folder(f, "Machines")
end

-- ===== Zone 1: Stone Facility =====
function B.zone1()
	local Z, props, decor, machines = zoneFolder(1)
	local accent = P.green
	room(Z, { name = "SpawnHall", x0 = -32, x1 = 32, zA = 0, zB = -48, h = 24, style = "facility", walls = {
		back = { t = 2 }, front = { t = 4, openings = { { -16, 16, 20 } } }, left = { t = 2 }, right = { t = 2 },
	} })
	room(Z, { name = "Corridor", x0 = -16, x1 = 16, zA = -52, zB = -60, h = 24, style = "facility", walls = {
		back = false, front = false, left = { t = 2, noBand = corridorNoBand(1) }, right = { t = 2, noBand = corridorNoBand(1) },
	} })
	mainWall(Z, 1)
	ceilingLights(Z, { -16, 0, 16 }, { -8, -24, -40 }, 24)
	ceilingLights(Z, { 0 }, { -56 }, 24)
	spawnPad(Z, Vector3.new(0, 0, -8), 1, accent, true)
	walkway(Z, 0, -12.5, -47.5, 10)
	B.depositMachine(machines, CFrame.new(-23, 0, -22) * CFrame.Angles(0, math.rad(-90), 0), 1, accent)
	B.toolPodium(machines, CFrame.new(23, 0, -22) * CFrame.Angles(0, math.rad(90), 0), 1, accent)
	B.upgradeBoard(machines, CFrame.new(0, 9, 0) * WALL_BACK, 1, 16)
	local frame = K.model(decor, "BoardHazardFrame")
	box(frame, -9.5, 13.5, 0, 9.5, 14.5, -0.4, P.yellow, { name = "Top", top = false })
	box(frame, -9.5, 3.5, 0, 9.5, 4.5, -0.4, P.yellow, { name = "Bottom", top = false })
	box(frame, -9.5, 4.5, 0, -8.5, 13.5, -0.4, P.black, { name = "Side", top = false })
	box(frame, 8.5, 4.5, 0, 9.5, 13.5, -0.4, P.black, { name = "Side", top = false })
	wallScreen(decor, CFrame.new(-16, 10, 0) * WALL_BACK)
	wallScreen(decor, CFrame.new(16, 10, 0) * WALL_BACK)
	vent(decor, CFrame.new(-25, 16, 0) * WALL_BACK)
	vent(decor, CFrame.new(25, 16, 0) * WALL_BACK)
	wallSign(decor, CFrame.new(0, 22, -48) * WALL_FRONT, 14, 3, "ZONE 1", accent)
	-- props: clusters along the side walls, low near the machines
	crateCluster(props, -28, -40)
	crateCluster(props, 22, -42)
	crate(props, 27.5, -6, 4, 8)
	plant(props, -28, -4)
	plant(props, 28.5, -32)
	wallScreen(decor, CFrame.new(-32, 8, -36) * WALL_L)
	wallScreen(decor, CFrame.new(32, 8, -12) * WALL_R)
	vent(decor, CFrame.new(32, 16, -36) * WALL_R)
	vent(decor, CFrame.new(-32, 16, -12) * WALL_L)
	alarmLight(decor, CFrame.new(-18.5, 17, -48) * WALL_FRONT)
	alarmLight(decor, CFrame.new(18.5, 17, -48) * WALL_FRONT)
	return Z
end

-- ===== Zone 2: Mine Cave (left / right maze) =====
function B.zone2()
	local Z, props, decor, machines = zoneFolder(2)
	local accent = P.amber
	-- hub: entered from the Zone 1 corridor; its front is a 24-deep rock mass with two tunnels
	room(Z, { name = "Hub", x0 = -32, x1 = 32, zA = -62, zB = -104, h = 24, style = "cave", walls = {
		back = { t = 2, openings = { { -16, 16, 24 } }, noJitter = { -33, -15 } },
		front = { t = 24, openings = { { -28, -16, 18 }, { 16, 28, 18 } }, noJitter = { -16, 16 } },
		left = { t = 2 }, right = { t = 2 },
	} })
	-- left tunnel ends in an ore vein (a hidden way into the chamber) under a rock plug
	local leftEnd = folder(Z, "LeftTunnel")
	box(leftEnd, -28, 10, -128, -16, 18, -124, P.rock[1], { name = "Plug" })
	box(leftEnd, -28, 0, -128, -26, 10, -124, P.rock[2], { name = "Plug" })
	box(leftEnd, -18, 0, -128, -16, 10, -124, P.rock[3], { name = "Plug" })
	box(leftEnd, -26, 6, -128, -18, 10, -124, P.rock[1], { name = "Plug" })
	-- a small ore cluster (8 x 6 studs): break it and it opens a crawl-through into the chamber
	veinWall(leftEnd)
	for _, sx in ipairs({ -27, -17 }) do
		box(leftEnd, sx - 1, 0, -122, sx + 1, 12, -120, P.wood, { name = "Post" })
	end
	box(leftEnd, -28, 12, -122, -16, 13.5, -120, P.woodDark, { name = "Beam" })
	-- chamber behind the rock mass with the real ore wall
	room(Z, { name = "Chamber", x0 = -32, x1 = 32, zA = -128, zB = -152, h = 24, style = "cave", walls = {
		back = false, front = { t = 4, openings = { { -16, 16, 20 } }, noJitter = { -17, 17 } }, left = { t = 2 }, right = { t = 2 },
	} })
	-- the right tunnel opens straight into the chamber; block the far end of the LEFT tunnel only (vein above)
	mainWall(Z, 2)
	room(Z, { name = "Corridor", x0 = -16, x1 = 16, zA = -156, zB = -164, h = 24, style = "cave", walls = {
		back = false, front = false, left = { t = 2 }, right = { t = 2 },
	} })
	spawnPad(Z, Vector3.new(0, 0, -70), 2, accent, false)
	-- mine supports with lanterns
	local sup = folder(Z, "Supports")
	for _, z in ipairs({ -72, -92, -138 }) do
		for _, sx in ipairs({ -27, 27 }) do
			box(sup, sx - 1, 0, z - 1, sx + 1, 22, z + 1, P.wood, { name = "Post" })
		end
		box(sup, -28, 22, z - 1, 28, 24, z + 1, P.woodDark, { name = "Beam", top = false })
		lantern(sup, -12, z, 22)
		lantern(sup, 12, z, 22)
	end
	for _, z in ipairs({ -110, -118 }) do
		lantern(sup, -22, z, 18)
		lantern(sup, 22, z, 18)
	end
	-- landmark: the big wooden sign between the tunnels
	local lm = K.model(decor, "CaveSign_Landmark")
	for _, sx in ipairs({ -11, 11 }) do
		box(lm, sx - 1, 0, -104, sx + 1, 15, -102, P.wood, { name = "Post" })
		local g = box(lm, sx - 1, 15, -104, sx + 1, 17.4, -102, P.lanternGlow, { name = "Lantern", material = Enum.Material.Neon, top = false })
		K.light(g, P.amberLight, 12, 0.5)
		box(lm, sx - 1.2, 17.4, -104, sx + 1.2, 17.8, -102, P.woodDark, { name = "Cap", top = false })
	end
	local board = box(lm, -12, 7, -102, 12, 14, -101.2, hex("B5713B"), { name = "Board", top = false })
	K.boardText(board, Enum.NormalId.Back, "NOT EVERY ROOM IS\nSTRAIGHT FORWARD", { color = Color3.new(1, 1, 1), stroke = P.woodDark })
	-- the board's Back face (+Z) faces the hub; Front would face the rock
	local tip = folder(Z, "TunnelSigns")
	local dead = box(tip, -28, 8.5, -118, -27.4, 11.5, -110, P.amber, { name = "DeadEndSign", top = false })
	K.boardText(dead, Enum.NormalId.Right, "DEAD END...?", { stroke = P.woodDark })
	-- rails from the hub into the right tunnel and chamber
	local rails = folder(Z, "Rails")
	local z = -90 -- starts past the tool podium (it used to run through it)
	while z > -140 do
		box(rails, 19, 0, z - 0.5, 25, 0.3, z + 0.5, P.woodDark, { name = "Sleeper", top = false })
		z -= 2.5
	end
	box(rails, 20.2, 0.3, -140, 20.8, 0.7, -89.5, P.railSteel, { name = "Rail", top = false })
	box(rails, 23.2, 0.3, -140, 23.8, 0.7, -89.5, P.railSteel, { name = "Rail", top = false })
	box(rails, 19, 0, -89.5, 25, 1.2, -88.5, P.yellow, { name = "Buffer" })
	mineCart(props, 22, -97)
	-- machines
	B.depositMachine(machines, CFrame.new(-23, 0, -82) * CFrame.Angles(0, math.rad(-90), 0), 2, accent, hex("5A4636"))
	B.toolPodium(machines, CFrame.new(14, 0, -82) * CFrame.Angles(0, math.rad(90), 0), 2, accent)
	B.upgradeBoard(machines, CFrame.new(-24, 9, -62) * WALL_BACK, 2, 12)
	wallSign(decor, CFrame.new(0, 22, -152) * WALL_FRONT, 14, 3, "ZONE 2", accent, P.black)
	-- props
	barrel(props, -28, -98)
	barrel(props, -25, -99.5)
	barrel(props, 29, -132)
	crystal(props, -28.5, -66, 1)
	crystal(props, 28, -146, 1.3)
	crystal(props, -27, -146, 1.1)
	crystal(props, -26, -121, 0.8)
	crateCluster(props, -27, -133) -- kept to the side so the ore wall stays clear
	return Z
end

-- ===== Zone 3: Security Vault (PROVISIONAL, boss room) =====
function B.zone3()
	local Z, props, decor, machines = zoneFolder(3)
	local accent = P.red
	room(Z, { name = "SpawnHall", x0 = -32, x1 = 32, zA = -166, zB = -200, h = 24, style = "vault", walls = {
		back = { t = 2, openings = { { -16, 16, 24 } } }, front = false, left = { t = 2 }, right = { t = 2 },
	} })
	room(Z, { name = "Arena", x0 = -32, x1 = 32, zA = -204, zB = -268, h = 34, style = "vault", walls = {
		back = { t = 4, openings = { { -10, 10, 16 } } },
		front = { t = 4, openings = { { -16, 16, 20 } }, noBand = { { -20, -16 }, { 16, 20 } } }, -- vault jambs stand there
		left = { t = 2 }, right = { t = 2 },
	} })
	room(Z, { name = "ExitCorridor", x0 = -16, x1 = 16, zA = -272, zB = -284, h = 24, style = "vault", walls = {
		back = false, front = { t = 2 }, left = { t = 2, noBand = corridorNoBand(3) }, right = { t = 2, noBand = corridorNoBand(3) },
	} })
	mainWall(Z, 3)
	ceilingLights(Z, { -16, 16 }, { -174, -190 }, 24)
	ceilingLights(Z, { -18, 0, 18 }, { -214, -236, -256 }, 34)
	ceilingLights(Z, { 0 }, { -278 }, 24)
	spawnPad(Z, Vector3.new(0, 0, -174), 3, accent, false)
	walkway(Z, 0, -178.5, -199.5, 10)
	-- arena ring (red) on the floor
	local ring = folder(Z, "ArenaRing")
	-- a 1.6-wide red band (segments), so the checker floor still shows inside it
	local segs = 48
	for i = 0, segs - 1 do
		local a = i / segs * math.pi * 2
		local len = 2 * math.pi * 27 / segs + 0.25
		part(ring, Vector3.new(1.6, 0.2, len), CFrame.new(0, 0.1, -236) * CFrame.Angles(0, a, 0) * CFrame.new(27, 0, 0), accent,
			{ name = "RingSegment", top = false })
	end
	-- gate frame (red) on the arena's back wall, facing the spawn hall
	local gate = K.model(decor, "GateFrame")
	box(gate, -12, 0, -200, -10, 18, -198, accent, { name = "Jamb" })
	box(gate, 10, 0, -200, 12, 18, -198, accent, { name = "Jamb" })
	box(gate, -10, 16, -200, 10, 18, -198, accent, { name = "Lintel" })
	wallSign(decor, CFrame.new(0, 20.5, -200) * WALL_BACK * CFrame.Angles(0, math.pi, 0), 14, 3, "WARDEN ACTIVE", P.yellow, P.black)
	-- landmark: the vault door frame around the breakable wall
	local vault = K.model(decor, "VaultFrame_Landmark")
	-- thick red jambs and a steel lintel, steel bands on the jambs
	box(vault, -20, 0, -268, -16, 24, -264, accent, { name = "Jamb" })
	box(vault, 16, 0, -268, 20, 24, -264, accent, { name = "Jamb" })
	box(vault, -16, 20, -268, 16, 24, -264, P.steel, { name = "Lintel" })
	for _, y in ipairs({ 5, 13 }) do
		box(vault, -20, y, -264, -16, y + 1.6, -263.6, P.steel, { name = "Band", top = false })
		box(vault, 16, y, -264, 20, y + 1.6, -263.6, P.steel, { name = "Band", top = false })
	end
	-- round vault-door emblem above the lintel (34-tall room)
	local emblem = part(vault, Vector3.new(1, 9, 9), CFrame.new(0, 28.8, -266.5) * CFrame.Angles(0, math.rad(90), 0), accent,
		{ name = "Emblem", shape = Enum.PartType.Cylinder, top = false })
	part(vault, Vector3.new(1, 6, 6), CFrame.new(0, 28.8, -265.9) * CFrame.Angles(0, math.rad(90), 0), P.steel,
		{ name = "EmblemCore", shape = Enum.PartType.Cylinder, top = false })
	for i = 0, 3 do
		part(vault, Vector3.new(0.6, 5.2, 0.6), CFrame.new(0, 28.8, -265.2) * CFrame.Angles(0, 0, i * math.pi / 4), P.metal,
			{ name = "EmblemSpoke", top = false })
	end
	K.light(emblem, accent, 10, 0.6)
	-- the boss (placeholder)
	local boss, bvis, bfn = placeholder(machines, "Boss")
	local bc = CFrame.new(0, 0, -236)
	local function at(x, y, z) return bc * CFrame.new(x, y, z) end
	part(bvis, Vector3.new(2.6, 5, 2.6), at(-1.8, 2.5, 0), P.metal, { name = "Leg" })
	part(bvis, Vector3.new(2.6, 5, 2.6), at(1.8, 2.5, 0), P.metal, { name = "Leg" })
	part(bvis, Vector3.new(8, 6, 4.4), at(0, 8, 0), P.steel, { name = "Torso" })
	part(bvis, Vector3.new(2.2, 6, 2.2), at(-5.2, 7.6, 0), P.metal, { name = "Arm" })
	part(bvis, Vector3.new(2.2, 6, 2.2), at(5.2, 7.6, 0), P.metal, { name = "Arm" })
	part(bvis, Vector3.new(4.4, 3.2, 3.6), at(0, 12.6, 0), hex("D6DAE0"), { name = "Head" })
	local visor = part(bvis, Vector3.new(3.4, 0.9, 0.3), at(0, 12.8, 1.9), accent, { name = "Visor", material = Enum.Material.Neon, top = false })
	K.light(visor, accent, 8, 0.6)
	local hit = trigger(bfn, "Hitbox", Vector3.new(11, 14.5, 5), at(0, 7.25, 0), 3)
	hit.CanQuery = true
	hit:SetAttribute("BossName", C.Zones[3].boss.name)
	hit:SetAttribute("MaxHP", C.Zones[3].boss.hp)
	boss:SetAttribute("Zone", 3)
	-- machines in the spawn hall
	B.depositMachine(machines, CFrame.new(-23, 0, -186) * CFrame.Angles(0, math.rad(-90), 0), 3, accent)
	B.toolPodium(machines, CFrame.new(23, 0, -186) * CFrame.Angles(0, math.rad(90), 0), 3, accent)
	B.upgradeBoard(machines, CFrame.new(24, 9, -166) * WALL_BACK, 3, 12)
	wallSign(decor, CFrame.new(0, 22, -264) * WALL_FRONT, 16, 3, "ZONE 3", P.steel)
	wallSign(decor, CFrame.new(0, 12, -284) * WALL_FRONT, 18, 4, "ZONE 4 - COMING SOON", P.yellow, P.black)
	-- props
	serverRack(props, -29.5, -172, -90) -- LEDs face into the room
	serverRack(props, -29.5, -176, -90)
	serverRack(props, 29.5, -196, 90)
	crateCluster(props, -28, -258)
	crateCluster(props, 22, -260)
	crate(props, 27, -210, 4, 10)
	securityCam(decor, CFrame.new(-32, 20, -206) * WALL_L * CFrame.Angles(0, math.rad(-30), 0))
	securityCam(decor, CFrame.new(32, 20, -206) * WALL_R * CFrame.Angles(0, math.rad(30), 0))
	wallScreen(decor, CFrame.new(-32, 9, -190) * WALL_L)
	vent(decor, CFrame.new(32, 16, -176) * WALL_R)
	return Z
end

return B
