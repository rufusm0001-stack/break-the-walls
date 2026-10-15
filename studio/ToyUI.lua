-- ToyUI: the one place every screen is built from (docs/UI_RULES.md).
-- Lives in Studio at ReplicatedStorage.Modules.ToyUI; this file is the versioned copy.
--
-- Toy stack per element: slab (darker, outlined) + raised face (gradient, inner rim) + stud tile
-- + text with stroke and hard shadow. Sizes are offsets at a 1280x720 design size; ToyUI.root
-- adds the UIScale that maps them to the real screen.

local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Icons = require(RS.Modules.Icons)

local ToyUI = {}

local function hex(h)
	return Color3.fromHex(h)
end

local OUTLINE = hex("1E1A2E")
local WHITE = Color3.new(1, 1, 1)

-- Slab colour: darker and nudged toward blue, per the tutorials.
local function slabOf(c)
	local h, s, v = c:ToHSV()
	local towardBlue = h + ((0.66 - h) * 0.08)
	return Color3.fromHSV(towardBlue % 1, math.clamp(s * 1.05, 0, 1), v * 0.62)
end

local function rimOf(c)
	return c:Lerp(WHITE, 0.45)
end

ToyUI.Theme = {
	outline = OUTLINE,
	white = WHITE,
	cream = hex("FFF4D6"),
	track = hex("D8CCB0"),
	gold = hex("FFC93C"),
	green = hex("5CC93E"),
	blue = hex("3FA2F7"),
	red = hex("F2544B"),
	cyan = hex("5FE0F5"),
	grey = hex("9AA0AA"),
	coal = hex("3A3A4A"),
	purple = hex("9B5CFF"),
	stud = 12, -- one stud in px; every size is a whole number of studs
	radius = 4,
	pad = 20,
	gap = 16,
	font = Enum.Font.FredokaOne,
}
local T = ToyUI.Theme
ToyUI.slabOf = slabOf

local function corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or T.radius)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness, inner)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.LineJoinMode = Enum.LineJoinMode.Round
	pcall(function()
		s.BorderStrokePosition = inner and Enum.BorderStrokePosition.Inner or Enum.BorderStrokePosition.Outer
	end)
	s.Parent = parent
	return s
end

-- Text with a dark stroke and a hard (unblurred) drop shadow.
function ToyUI.label(parent, props)
	props = props or {}
	local size = props.TextSize or 18
	local holder = Instance.new("Frame")
	holder.Name = props.Name or "Label"
	holder.BackgroundTransparency = 1
	holder.Size = props.Size or UDim2.fromScale(1, 1)
	holder.Position = props.Position or UDim2.new()
	holder.AnchorPoint = props.AnchorPoint or Vector2.zero
	holder.ZIndex = props.ZIndex or 5
	holder.Parent = parent

	local function make(name, color, offset, z)
		local t = Instance.new("TextLabel")
		t.Name = name
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1, 1)
		t.Position = UDim2.fromOffset(0, offset)
		t.Font = props.Font or T.font
		t.TextSize = size
		t.TextColor3 = color
		t.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Center
		t.TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center
		t.TextTruncate = Enum.TextTruncate.AtEnd
		t.Text = props.Text or ""
		t.ZIndex = z
		t.Parent = holder
		return t
	end
	local shadowOffset = size >= 28 and 3 or 2
	local shadow = make("Shadow", OUTLINE, shadowOffset, holder.ZIndex)
	local text = make("Text", props.TextColor3 or WHITE, 0, holder.ZIndex + 1)
	local s = Instance.new("UIStroke")
	s.Color = OUTLINE
	s.Thickness = size >= 28 and 3 or 2
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = text
	local ss = s:Clone()
	ss.Parent = shadow

	-- set(text) keeps label and shadow in sync
	local api = { frame = holder, text = text, shadow = shadow }
	function api.set(value)
		text.Text = value
		shadow.Text = value
	end
	function api.color(c)
		text.TextColor3 = c
	end
	return api
end

-- Title text in the "Anime Outfits" style: chunky font, multi-colour gradient fill, thick dark
-- stroke, 3D extrusion (stacked darker copies offset down-right) and a hard shadow, with an
-- optional tilt. Works inside ScreenGui, SurfaceGui and BillboardGui.
-- props: Text, TextSize, Size, Position, AnchorPoint, Colors = {top, bottom} or a ColorSequence,
-- Depth (extrusion layers, default 4), Rotation (deg), Font, Stroke (px), ZIndex, Name
ToyUI.TitlePresets = {
	gold = { hex("FFF27A"), hex("FFB21A") },
	cyan = { hex("B8FBFF"), hex("2FA8FF") },
	pink = { hex("FFB3F0"), hex("B44CFF") },
	lime = { hex("E9FF7A"), hex("3CCB3C") },
	fire = { hex("FFE066"), hex("FF4A2B") },
	white = { hex("FFFFFF"), hex("D7E9FF") },
}

function ToyUI.title(parent, props)
	props = props or {}
	local size = props.TextSize or 36
	local depth = props.Depth or 4
	local strokePx = props.Stroke or math.max(3, math.floor(size / 10))
	local colors = props.Colors or ToyUI.TitlePresets.gold
	local seq = typeof(colors) == "ColorSequence" and colors or ColorSequence.new(colors[1], colors[2])
	local bottomColor = seq.Keypoints[#seq.Keypoints].Value
	local extrudeColor = slabOf(bottomColor)
	local z = props.ZIndex or 5

	local holder = Instance.new("Frame")
	holder.Name = props.Name or "Title"
	holder.BackgroundTransparency = 1
	holder.Size = props.Size or UDim2.fromScale(1, 1)
	holder.Position = props.Position or UDim2.new()
	holder.AnchorPoint = props.AnchorPoint or Vector2.zero
	holder.Rotation = props.Rotation or 0
	holder.ZIndex = z
	holder.Parent = parent

	local labels = {}
	local function layer(name, color, dx, dy, zz)
		local t = Instance.new("TextLabel")
		t.Name = name
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1, 1)
		t.Position = UDim2.fromOffset(dx, dy)
		t.Font = props.Font or T.font
		t.TextSize = size
		t.TextScaled = props.TextScaled or false
		t.TextColor3 = color
		t.Text = props.Text or ""
		t.ZIndex = zz
		t.Parent = holder
		local s = Instance.new("UIStroke")
		s.Color = OUTLINE
		s.Thickness = strokePx
		s.LineJoinMode = Enum.LineJoinMode.Round
		s.Parent = t
		table.insert(labels, t)
		return t
	end
	-- hard shadow, then extrusion layers from the back forward, then the gradient face
	layer("Shadow", OUTLINE, depth + 2, depth + 3, z)
	for i = depth, 1, -1 do
		layer("Depth" .. i, extrudeColor, i, i, z + (depth - i) + 1)
	end
	local face = layer("Face", WHITE, 0, 0, z + depth + 2)
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = seq
	g.Parent = face

	local api = { frame = holder, face = face }
	function api.set(text)
		for _, t in ipairs(labels) do
			t.Text = text
		end
	end
	return api
end

-- In-world sign surface for titles: crisp, unlit, sized in studs.
function ToyUI.worldSign(part, face, pixelsPerStud)
	local sg = Instance.new("SurfaceGui")
	sg.Face = face or Enum.NormalId.Front
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = pixelsPerStud or 50
	sg.LightInfluence = 0
	sg.AlwaysOnTop = false
	sg.Parent = part
	return sg
end

local function studs(parent, transparency, r)
	local img = Instance.new("ImageLabel")
	img.Name = "Studs"
	img.BackgroundTransparency = 1
	img.Size = UDim2.fromScale(1, 1)
	img.Image = Icons.StudTile or ""
	img.ScaleType = Enum.ScaleType.Tile
	img.TileSize = UDim2.fromOffset(T.stud, T.stud)
	img.ImageTransparency = transparency
	img.ZIndex = parent.ZIndex + 1
	corner(img, r)
	img.Parent = parent
	return img
end

-- The core block: slab + raised face. Returns the outer Frame and the face to put content in.
-- opts: Size (UDim2, offsets), Position, AnchorPoint, color, depth (3 or 5), studs (0..1 transparency or false),
-- radius, Parent, ZIndex, Name
function ToyUI.block(opts)
	local depth = opts.depth or 3
	local r = opts.radius or T.radius
	local color = opts.color or T.cream
	local z = opts.ZIndex or 1

	local root = Instance.new("Frame")
	root.Name = opts.Name or "Block"
	root.BackgroundTransparency = 1
	root.Size = opts.Size
	root.Position = opts.Position or UDim2.new()
	root.AnchorPoint = opts.AnchorPoint or Vector2.zero
	root.ZIndex = z
	root.Parent = opts.Parent

	local slab = Instance.new("Frame")
	slab.Name = "Slab"
	slab.Size = UDim2.fromScale(1, 1)
	slab.BackgroundColor3 = slabOf(color)
	slab.ZIndex = z
	slab.Parent = root
	corner(slab, r)
	stroke(slab, OUTLINE, opts.outline or 3, false)

	local face = Instance.new("Frame")
	face.Name = "Face"
	face.Size = UDim2.new(1, 0, 1, -depth)
	face.BackgroundColor3 = WHITE
	face.ZIndex = z + 1
	face.Parent = root
	corner(face, r)
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new(color:Lerp(WHITE, 0.18), color)
	g.Parent = face
	stroke(face, rimOf(color), 3, true)
	if opts.studs ~= false then
		studs(face, opts.studs or 0.65, r)
	end
	return root, face
end

-- Clickable toy button with hover/press feel. Returns root (TextButton), face, setLabel.
function ToyUI.button(opts)
	local root, face = ToyUI.block(opts)
	local hit = Instance.new("TextButton")
	hit.Name = "Hit"
	hit.Text = ""
	hit.AutoButtonColor = false
	hit.BackgroundTransparency = 1
	hit.Size = UDim2.fromScale(1, 1)
	hit.ZIndex = (opts.ZIndex or 1) + 10
	hit.Parent = root
	local pop = Instance.new("UIScale")
	pop.Parent = root
	local info = TweenInfo.new(0.12, Enum.EasingStyle.Quad)
	hit.MouseEnter:Connect(function()
		TweenService:Create(pop, info, { Scale = 1.05 }):Play()
	end)
	hit.MouseLeave:Connect(function()
		TweenService:Create(pop, info, { Scale = 1 }):Play()
	end)
	hit.MouseButton1Down:Connect(function()
		TweenService:Create(pop, info, { Scale = 0.95 }):Play()
	end)
	hit.MouseButton1Up:Connect(function()
		TweenService:Create(pop, info, { Scale = 1.05 }):Play()
	end)
	local lbl
	if opts.Text then
		lbl = ToyUI.label(face, {
			Text = opts.Text,
			TextSize = opts.TextSize or 20,
			Size = UDim2.new(1, -12, 1, 0),
			Position = UDim2.fromOffset(6, 0),
			ZIndex = (opts.ZIndex or 1) + 4,
		})
	end
	return root, face, hit, lbl
end

-- Progress bar inside a face. Returns track, fill.
function ToyUI.bar(parent, size, position, fillColor, z)
	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Size = size
	track.Position = position
	track.BackgroundColor3 = T.track
	track.ZIndex = z or 4
	track.Parent = parent
	corner(track, 3)
	stroke(track, OUTLINE, 2, false)
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = fillColor
	fill.ZIndex = (z or 4) + 1
	fill.Parent = track
	corner(fill, 3)
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new(fillColor:Lerp(WHITE, 0.25), fillColor)
	g.Parent = fill
	return track, fill
end

-- Icon with a hard shadow (outline is baked into the PNG).
function ToyUI.icon(parent, image, size, position, z)
	local function make(name, tint, offset, zz)
		local i = Instance.new("ImageLabel")
		i.Name = name
		i.BackgroundTransparency = 1
		i.Image = image
		i.ImageColor3 = tint
		i.Size = size
		i.Position = position + UDim2.fromOffset(0, offset)
		i.ScaleType = Enum.ScaleType.Fit
		i.ZIndex = zz
		i.Parent = parent
		return i
	end
	make("IconShadow", OUTLINE, 2, (z or 6))
	return make("Icon", WHITE, 0, (z or 6) + 1)
end

-- ScreenGui with the root UIScale: min(vw/1280, vh/720), x1.7 on small screens, never above 1.
function ToyUI.root(name, playerGui)
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.Parent = playerGui
	local scale = Instance.new("UIScale")
	scale.Parent = gui
	local function rescale()
		local v = workspace.CurrentCamera.ViewportSize
		local s = math.min(v.X / 1280, v.Y / 720)
		if math.min(v.X, v.Y) < 500 then
			s *= 1.7
		end
		scale.Scale = math.clamp(s, 0.5, 1)
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	rescale()
	return gui
end

return ToyUI
