-- StudKit: the proven world-building kit for the stud-toy style (extracted from GameHub's BuildHub, Oct 2026).
-- Put it in ServerStorage.DevTools.StudKit and require a CLONE from execute_luau:
--   local K = require(game.ServerStorage.DevTools.StudKit:Clone())
--   K.applyCartoonLighting()
--   local p = K.part(folder, Vector3.new(8, 1, 8), CFrame.new(0, 0.5, 0), K.hex("6CC24A"))
--   K.lamp(folder, Vector3.new(10, 0, 0), K.hex("FFB347"), K.hex("FFC46B"))       -- tall plaza lamp
--   K.lamp(folder, pos, head, light, "lantern", 3)                                 -- short lantern
--   K.boardText(boardPart, Enum.NormalId.Front, "SHOP")                           -- sign text, sized right
--   local kit = K.letterKit(); K.meshText(parent, kit, "HELLO", cf, 5, colors, Random.new(1))
-- Rules baked in (see references/LESSONS_GAMEHUB.md): Plastic, studs on TOP only, smooth sides;
-- boardText scales PixelsPerStud because TextScaled caps at 100 px; Top-face text runs along the part's Z axis.

local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")

local function hex(h)
	return Color3.fromHex(h)
end

local OUTLINE = hex("1E1A2E")
local WHITE = Color3.new(1, 1, 1)
local DARK_METAL = hex("2E3550")
local WOOD, WOOD_DARK = hex("B5713B"), hex("7A4A26")

-- ===== primitives =====

local SIDES = { "Front", "Back", "Left", "Right" }

-- Plastic, studs on top only (sides smooth). Big walls: same, studs only on their top.
local function part(parent, size, cf, color, opts)
	opts = opts or {}
	local p = Instance.new("Part")
	p.Name = opts.name or "Brick"
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = opts.material or Enum.Material.Plastic
	p.TopSurface = opts.top == false and Enum.SurfaceType.Smooth or Enum.SurfaceType.Studs
	p.BottomSurface = Enum.SurfaceType.Smooth
	for _, s in ipairs(SIDES) do
		p[s .. "Surface"] = Enum.SurfaceType.Smooth
	end
	if opts.shadow == false then
		p.CastShadow = false
	end
	if opts.shape then
		p.Shape = opts.shape
	end
	p.Parent = parent
	return p
end

local function folder(parent, name)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function model(parent, name)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

local function light(p, color, range, brightness)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = false
	l.Parent = p
	return l
end

local function darker(c, k)
	return c:Lerp(Color3.new(0, 0, 0), k or 0.4)
end

-- SurfaceGui text on a 3D board (MAP_AND_TEXT_FINDINGS §5 text rules 4 and 6)
local function boardText(p, face, text, opts)
	opts = opts or {}
	local g = Instance.new("SurfaceGui")
	g.Name = "Gui" .. face.Name
	g.Face = face
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	-- TextScaled caps at 100 px, so big boards need fewer pixels per stud or the text stays small
	local faceH = (face == Enum.NormalId.Top or face == Enum.NormalId.Bottom) and p.Size.X or p.Size.Y
	g.PixelsPerStud = math.clamp(110 / (faceH * 0.8), 18, 60)
	g.LightInfluence = 0
	g.MaxDistance = 250
	g.Parent = p
	local t = Instance.new("TextLabel")
	t.Name = opts.labelName or "Text"
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = opts.color or WHITE
	t.Text = text
	t.Parent = g
	local pad = Instance.new("UIPadding")
	local px = opts.pad or 0.1
	pad.PaddingTop, pad.PaddingBottom = UDim.new(px, 0), UDim.new(px, 0)
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0.04, 0), UDim.new(0.04, 0)
	pad.Parent = t
	local s = Instance.new("UIStroke")
	s.Color = opts.stroke or OUTLINE
	s.Thickness = opts.strokeWidth or 5
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = t
	return g, t
end

-- A round disc: one cylinder standing on its end (smooth top).
local function disc(parent, radius, height, topY, color, opts)
	return part(parent, Vector3.new(height, radius * 2, radius * 2),
		CFrame.new(0, topY - height / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), color,
		{ name = (opts and opts.name) or "Disc", top = false, shape = Enum.PartType.Cylinder })
end

-- ===== prop kit (one kit, varied; DESIGN_FEEDBACK §2) =====

-- poleLen 8 = tall plaza lamp; 3 = short runway lantern that stays below the booth screens
local function lamp(parent, pos, headColor, lightColor, style, poleLen)
	local L = poleLen or 8
	local hb = 0.8 + L -- head bottom
	local m = model(parent, "Lamp")
	local function at(y)
		return CFrame.new(pos + Vector3.new(0, y, 0))
	end
	part(m, Vector3.new(1.6, 0.8, 1.6), at(0.4), DARK_METAL, { name = "Base" })
	part(m, Vector3.new(0.7, L, 0.7), at(0.8 + L / 2), DARK_METAL, { name = "Pole", top = false })
	local head
	if style == "lantern" then
		head = part(m, Vector3.new(1.8, 2.4, 1.8), at(hb + 1.2), headColor, { name = "Head", material = Enum.Material.Neon, top = false })
		part(m, Vector3.new(2.2, 0.4, 2.2), at(hb + 2.6), hex("D9483B"), { name = "Cap", top = false })
		part(m, Vector3.new(2.2, 0.4, 2.2), at(hb - 0.25), hex("D9483B"), { name = "Cap", top = false })
	else
		head = part(m, Vector3.new(1.8, 1.8, 1.8), at(hb + 0.9), headColor, { name = "Head", material = Enum.Material.Neon, top = false })
		part(m, Vector3.new(2.4, 0.5, 2.4), at(hb + 2.05), DARK_METAL, { name = "Cap" })
	end
	light(head, lightColor, L > 4 and 20 or 14, 1.4)
	return m
end

local function bench(parent, cf)
	local m = model(parent, "Bench")
	part(m, Vector3.new(5, 0.5, 1.8), cf * CFrame.new(0, 1.45, 0), WOOD, { name = "Seat" })
	part(m, Vector3.new(5, 1.8, 0.4), cf * CFrame.new(0, 2.6, 0.75), WOOD, { name = "Back", top = false })
	for _, x in ipairs({ -2, 2 }) do
		part(m, Vector3.new(0.5, 1.2, 1.6), cf * CFrame.new(x, 0.6, 0), DARK_METAL, { name = "Leg", top = false })
	end
	return m
end

local function tree(parent, pos, leaf, scale)
	scale = scale or 1
	local m = model(parent, "Tree")
	local trunkH = 10 * scale
	part(m, Vector3.new(3 * scale, trunkH, 3 * scale), CFrame.new(pos + Vector3.new(0, trunkH / 2, 0)), WOOD_DARK, { name = "Trunk" })
	part(m, Vector3.new(12, 6, 12) * scale, CFrame.new(pos + Vector3.new(0, trunkH + 3 * scale, 0)), leaf, { name = "Leaves" })
	part(m, Vector3.new(8, 4, 8) * scale, CFrame.new(pos + Vector3.new(0, trunkH + 8 * scale, 0)) * CFrame.Angles(0, math.rad(20), 0),
		leaf:Lerp(WHITE, 0.15), { name = "Leaves" })
	return m
end

local FLOWER_COLORS = { hex("FF5FA8"), hex("FFD23F"), hex("FFFFFF"), hex("F2544B"), hex("B48CFF") }

local function planter(parent, cf, w, d, boxColor, filling, rng)
	local m = model(parent, "Planter")
	part(m, Vector3.new(w, 1.4, d), cf * CFrame.new(0, 0.7, 0), boxColor, { name = "Box" })
	part(m, Vector3.new(w - 1, 0.3, d - 1), cf * CFrame.new(0, 1.45, 0), hex("6B4226"), { name = "Soil", top = false })
	if filling == "flowers" then
		for _ = 1, math.floor(w * d / 8) do
			local x, z = rng:NextNumber(-(w - 2) / 2, (w - 2) / 2), rng:NextNumber(-(d - 2) / 2, (d - 2) / 2)
			local s = rng:NextNumber(0.7, 1.1)
			part(m, Vector3.new(s, s, s), cf * CFrame.new(x, 1.6 + s / 2, z) * CFrame.Angles(0, rng:NextNumber(0, 1.5), 0),
				FLOWER_COLORS[rng:NextInteger(1, #FLOWER_COLORS)], { name = "Flower" })
		end
	elseif filling == "bush" then
		part(m, Vector3.new(w - 1.6, 2.6, d - 1.6), cf * CFrame.new(0, 2.9, 0), hex("5DB33F"), { name = "Bush" })
		part(m, Vector3.new(w - 3, 1.6, d - 3), cf * CFrame.new(0, 4.6, 0) * CFrame.Angles(0, 0.4, 0), hex("6CC24A"), { name = "Bush" })
	elseif filling == "blossom" then
		part(m, Vector3.new(w - 1.6, 2.6, d - 1.6), cf * CFrame.new(0, 2.9, 0), hex("FF8AD8"), { name = "Bush" })
		part(m, Vector3.new(w - 3, 1.6, d - 3), cf * CFrame.new(0, 4.6, 0) * CFrame.Angles(0, 0.4, 0), hex("FFB3E6"), { name = "Bush" })
	elseif typeof(filling) == "Color3" then
		local t = tree(m, (cf * CFrame.new(0, 1.6, 0)).Position, filling, 0.8)
		t.Parent = m
	end
	return m
end

local function fence(parent, cf, w, d, color)
	local m = model(parent, "Fence")
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			part(m, Vector3.new(0.6, 2.2, 0.6), cf * CFrame.new(sx * w / 2, 1.1, sz * d / 2), color, { name = "Post" })
		end
	end
	for _, sz in ipairs({ -1, 1 }) do
		part(m, Vector3.new(w - 0.6, 0.4, 0.3), cf * CFrame.new(0, 1.5, sz * d / 2), color, { name = "Rail", top = false })
	end
	for _, sx in ipairs({ -1, 1 }) do
		part(m, Vector3.new(0.3, 0.4, d - 0.6), cf * CFrame.new(sx * w / 2, 1.5, 0), color, { name = "Rail", top = false })
	end
	return m
end

local function signpost(parent, cf, text, color)
	local m = model(parent, "Signpost")
	part(m, Vector3.new(0.8, 7, 0.8), cf * CFrame.new(0, 3.5, 0), WOOD_DARK, { name = "Post" })
	local board = part(m, Vector3.new(11, 2.6, 0.6), cf * CFrame.new(0, 6.2, -0.7), color, { name = "Board" })
	boardText(board, Enum.NormalId.Front, text, { stroke = darker(color, 0.55) })
	boardText(board, Enum.NormalId.Back, text, { stroke = darker(color, 0.55) })
	return m
end

-- ===== 3D mesh letters (MAP_AND_TEXT_FINDINGS §4 method 1) =====

local function letterKit()
	local kit = ServerStorage:FindFirstChild("SignLetters")
	local metrics = ServerStorage:FindFirstChild("DevTools") and ServerStorage.DevTools:FindFirstChild("LetterMetrics")
	if not (kit and metrics) then
		return nil
	end
	local ok, m = pcall(require, metrics:Clone())
	if not ok then
		return nil
	end
	local byName = {}
	for _, d in ipairs(kit:GetDescendants()) do
		if d:IsA("MeshPart") then
			byName[d.Name] = d
		end
	end
	return { metrics = m, meshes = byName }
end

-- Lays out `text` centred at `cf` (letters face cf.LookVector * -1, i.e. the Front of cf), cap height `h` studs.
-- Returns the Model, or nil when the alphabet hasn't been imported yet.
local function meshText(parent, kit, text, cf, h, colors, rng)
	if not kit then
		return nil
	end
	local m = model(parent, "Letters")
	local met = kit.metrics
	local s = h / met.capHeight
	local track = 0.07
	local total = 0
	for ch in text:gmatch(".") do
		local g = met.glyphs[ch]
		total += g and (g.width + track) or met.spaceWidth
	end
	total = (total - track) * s
	local x = -total / 2
	local i = 0
	for ch in text:gmatch(".") do
		local g = met.glyphs[ch]
		if not g then
			x += met.spaceWidth * s
		else
			i += 1
			local src = kit.meshes[g.name]
			if src then
				local L = src:Clone()
				L.Anchored = true
				L.CanCollide = false
				L.Material = Enum.Material.SmoothPlastic
				L.Color = colors[(i - 1) % #colors + 1]
				L.Size = Vector3.new(g.width, g.height, g.depth) * s
				local jitterRot = math.rad(rng:NextNumber(-5, 5))
				local jitterY = rng:NextNumber(-0.1, 0.1) * s
				-- glyph fronts face local +Z, so turn 180° to face cf's Front; reading direction is then +X
				L.CFrame = cf * CFrame.Angles(0, math.pi, 0) * CFrame.new(x + g.width * s / 2, g.centerY * s + jitterY, 0)
					* CFrame.Angles(0, 0, jitterRot)
				L.Parent = m
			end
			x += (g.width + track) * s
		end
	end
	local hl = Instance.new("Highlight")
	hl.FillTransparency = 1
	hl.OutlineColor = OUTLINE
	hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.Parent = m
	return m
end


-- Cartoony preset (references/map_and_text_findings.md §2.5), tuned on GameHub: the raw preset
-- (Brightness 2.5, CC brightness 0.05) washed pale floors out to white, so Brightness is 2.0,
-- Ambient a bit darker and CC brightness 0. Lighting.Technology can't be read or set by scripts:
-- set it to ShadowMap by hand.
local function applyCartoonLighting()
	Lighting.Ambient = Color3.fromRGB(165, 135, 190)
	Lighting.Brightness = 2.0
	Lighting.ColorShift_Top = Color3.fromRGB(215, 190, 135)
	Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
	Lighting.EnvironmentDiffuseScale = 0.4
	Lighting.EnvironmentSpecularScale = 0.5
	Lighting.GlobalShadows = true
	Lighting.OutdoorAmbient = Color3.fromRGB(125, 100, 150)
	Lighting.ShadowSoftness = 0.2
	Lighting.ClockTime = 14
	Lighting.GeographicLatitude = 40
	Lighting.ExposureCompensation = 0
	Lighting.FogColor = Color3.fromRGB(200, 170, 250)
	Lighting.FogStart = 0
	Lighting.FogEnd = 2500
	pcall(function()
		Lighting.Technology = Enum.Technology.ShadowMap
	end)
	for _, class in ipairs({ "Atmosphere", "BloomEffect", "DepthOfFieldEffect", "SunRaysEffect" }) do
		for _, e in ipairs(Lighting:GetChildren()) do
			if e:IsA(class) then
				e:Destroy()
			end
		end
	end
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
	cc.Brightness, cc.Contrast, cc.Saturation, cc.TintColor = 0, 0.1, 0.15, WHITE
	cc.Parent = Lighting
end


return {
	hex = hex,
	OUTLINE = OUTLINE,
	WHITE = WHITE,
	DARK_METAL = DARK_METAL,
	WOOD = WOOD,
	WOOD_DARK = WOOD_DARK,
	FLOWER_COLORS = FLOWER_COLORS,
	part = part,
	folder = folder,
	model = model,
	light = light,
	darker = darker,
	boardText = boardText,
	disc = disc,
	lamp = lamp,
	bench = bench,
	tree = tree,
	planter = planter,
	fence = fence,
	signpost = signpost,
	letterKit = letterKit,
	meshText = meshText,
	applyCartoonLighting = applyCartoonLighting,
}
