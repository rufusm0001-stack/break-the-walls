-- StarterPlayerScripts.SettingsUI: the gear button (top right, key M) and the Settings panel, built with ToyUI.
-- Sliders: mouse sensitivity (UserInputService.MouseDeltaSensitivity), music volume, sound effects volume.
-- Values live in the player attributes Set_<key>: the server loads them from the save and echoes changes back;
-- this script previews them locally while dragging and sends them on release (Remotes.Settings).
-- There is no cursor in first person. Hold Left Alt, or open the panel, to free the mouse (a visible Modal button
-- unlocks it).
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")

local BTW = RS:WaitForChild("BTW")
local Config = require(BTW.Config)
local State = require(BTW.ClientState)
local ToyUI = require(RS:WaitForChild("Modules"):WaitForChild("ToyUI"))
local Icons = require(RS.Modules:WaitForChild("Icons"))
local Remotes = BTW:WaitForChild("Remotes")
local T = ToyUI.Theme
local player = Players.LocalPlayer

local gui = ToyUI.root("Settings", player:WaitForChild("PlayerGui"))
gui.DisplayOrder = 5

-- MOUSE ------------------------------------------------------------------------------------
local modal = Instance.new("TextButton")
modal.Name = "MouseFree"
modal.Modal = true
modal.Text = ""
modal.BackgroundTransparency = 1
modal.Size = UDim2.fromOffset(1, 1)
modal.Visible = false
modal.Parent = gui
local altHeld = false
local function refreshMouse()
	local free = altHeld or State.menuOpen
	modal.Visible = free
	UserInputService.MouseIconEnabled = free
end

-- GEAR -------------------------------------------------------------------------------------
local gearRoot, gearFace, gearHit = ToyUI.button({
	Parent = gui, Name = "Gear", Size = UDim2.fromOffset(48, 48),
	Position = UDim2.new(1, -16, 0, 12), AnchorPoint = Vector2.new(1, 0), color = T.blue, depth = 5, studs = 0.75,
})
if Icons.Gear then
	ToyUI.icon(gearFace, Icons.Gear, UDim2.fromOffset(36, 36), UDim2.new(0.5, -18, 0.5, -20), 8)
else -- a 3D gear built from parts, used when the generated icon is missing
	local vp = Instance.new("ViewportFrame")
	vp.BackgroundTransparency = 1
	vp.Size = UDim2.fromOffset(36, 36)
	vp.Position = UDim2.new(0.5, -18, 0.5, -19)
	vp.ZIndex = gearFace.ZIndex + 3
	vp.Ambient = Color3.fromRGB(190, 190, 200)
	vp.LightDirection = Vector3.new(-1, -1, -1)
	local function add(size, hex, cf, shape)
		local p = Instance.new("Part")
		p.Size, p.Color, p.CFrame = size, Color3.fromHex(hex), cf
		p.Material = Enum.Material.SmoothPlastic
		if shape then p.Shape = shape end
		p.Parent = vp
	end
	add(Vector3.new(0.5, 2, 2), "E6EAF0", CFrame.new(), Enum.PartType.Cylinder)
	add(Vector3.new(0.56, 0.8, 0.8), "3A3F4B", CFrame.new(), Enum.PartType.Cylinder)
	for i = 0, 7 do
		add(Vector3.new(0.5, 0.6, 0.55), "E6EAF0", CFrame.Angles(math.rad(i * 45), 0, 0) * CFrame.new(0, 1.15, 0))
	end
	local cam = Instance.new("Camera")
	cam.FieldOfView = 40
	cam.CFrame = CFrame.lookAt(Vector3.new(5.2, 0.6, 0.4), Vector3.zero)
	cam.Parent = vp
	vp.CurrentCamera = cam
	vp.Parent = gearFace
end
ToyUI.label(gearFace, { Text = "M", TextSize = 14, Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(3, 1), ZIndex = 12 })

-- PANEL ------------------------------------------------------------------------------------
local panel, panelFace = ToyUI.block({
	Parent = gui, Name = "Panel", Size = UDim2.fromOffset(480, 336), Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5), color = T.cream, depth = 5, studs = 0.8, ZIndex = 20,
})
panel.Visible = false
local panelScale = Instance.new("UIScale")
panelScale.Parent = panel
local _, headerFace = ToyUI.block({
	Parent = panel, Name = "Header", Size = UDim2.fromOffset(264, 60), Position = UDim2.new(0.5, 0, 0, -30),
	AnchorPoint = Vector2.new(0.5, 0), color = T.blue, depth = 5, ZIndex = 30,
})
ToyUI.label(headerFace, { Text = "SETTINGS", TextSize = 40, ZIndex = 36 })
local _, closeFace, closeHit = ToyUI.button({
	Parent = panel, Name = "Close", Size = UDim2.fromOffset(48, 48), Position = UDim2.new(1, 12, 0, -12),
	AnchorPoint = Vector2.new(1, 0), color = T.red, depth = 5, studs = false, ZIndex = 30,
})
for _, r in ipairs({ 45, -45 }) do -- a drawn cross, not a letter
	local bar = Instance.new("Frame")
	bar.Size = UDim2.fromOffset(26, 6)
	bar.AnchorPoint = Vector2.new(0.5, 0.5)
	bar.Position = UDim2.fromScale(0.5, 0.5)
	bar.Rotation = r
	bar.BackgroundColor3 = T.white
	bar.ZIndex = 40
	bar.Parent = closeFace
	local st = Instance.new("UIStroke")
	st.Color = T.outline
	st.Thickness = 2
	st.Parent = bar
end

-- SLIDERS ----------------------------------------------------------------------------------
local ROWS = {
	{ key = "sensitivity", label = "MOUSE SENSITIVITY", icon = Icons.Mouse, fmt = function(v) return string.format("%.2f", v) end },
	{ key = "music", label = "MUSIC", icon = Icons.Music, fmt = function(v) return math.floor(v * 100 + 0.5) .. "%" end },
	{ key = "sfx", label = "SOUND EFFECTS", icon = Icons.Speaker, fmt = function(v) return math.floor(v * 100 + 0.5) .. "%" end },
}
local dragging
for i, row in ipairs(ROWS) do
	local spec = Config.Settings[row.key]
	local y = 52 + (i - 1) * 88
	local labelX = 28
	if row.icon then
		ToyUI.icon(panelFace, row.icon, UDim2.fromOffset(32, 32), UDim2.fromOffset(26, y - 5), 27)
		labelX = 66
	end
	ToyUI.label(panelFace, {
		Text = row.label, TextSize = 20, Size = UDim2.fromOffset(300, 24), Position = UDim2.fromOffset(labelX, y),
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 26,
	})
	local valueText = ToyUI.label(panelFace, {
		Text = "", TextSize = 20, Size = UDim2.fromOffset(96, 24), Position = UDim2.new(1, -124, 0, y),
		TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 26,
	})
	local track, fill = ToyUI.bar(panelFace, UDim2.new(1, -64, 0, 18), UDim2.fromOffset(32, y + 36), T.green, 26)
	local knob = ToyUI.block({
		Parent = track, Name = "Knob", Size = UDim2.fromOffset(24, 30), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5), color = T.gold, depth = 3, studs = false, ZIndex = 30,
	})
	local hit = Instance.new("TextButton")
	hit.Name = "Drag"
	hit.Text = ""
	hit.BackgroundTransparency = 1
	hit.Size = UDim2.new(1, 24, 0, 40)
	hit.Position = UDim2.new(0, -12, 0.5, -20)
	hit.ZIndex = 40
	hit.Parent = track
	local sl = {}
	function sl.setFromX(x)
		local f = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		player:SetAttribute("Set_" .. row.key, spec.min + f * (spec.max - spec.min)) -- local preview
	end
	hit.MouseButton1Down:Connect(function(x)
		dragging = sl
		sl.setFromX(x)
	end)
	local function sync()
		local v = player:GetAttribute("Set_" .. row.key) or spec.default
		local f = (v - spec.min) / (spec.max - spec.min)
		fill.Size = UDim2.fromScale(f, 1)
		knob.Position = UDim2.fromScale(f, 0.5)
		valueText.set(row.fmt(v))
	end
	player:GetAttributeChangedSignal("Set_" .. row.key):Connect(sync)
	sync()
end

local function sendSettings()
	local t = {}
	for k, spec in pairs(Config.Settings) do
		t[k] = player:GetAttribute("Set_" .. k) or spec.default
	end
	Remotes.Settings:FireServer(t)
end

-- sensitivity applies live
local function applySensitivity()
	UserInputService.MouseDeltaSensitivity = player:GetAttribute("Set_sensitivity") or Config.Settings.sensitivity.default
end
player:GetAttributeChangedSignal("Set_sensitivity"):Connect(applySensitivity)
applySensitivity()

-- OPEN / CLOSE -----------------------------------------------------------------------------
local function setMenu(open)
	if State.menuOpen == open then return end
	State.menuOpen = open
	State.Sfx:Fire("click")
	if open then
		panel.Visible = true
		panelScale.Scale = 0.9
		TweenService:Create(panelScale, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	else
		TweenService:Create(panelScale, TweenInfo.new(0.1), { Scale = 0.9 }):Play()
		task.delay(0.1, function()
			if not State.menuOpen then panel.Visible = false end
		end)
		sendSettings()
	end
	refreshMouse()
end
gearHit.Activated:Connect(function()
	setMenu(not State.menuOpen)
end)
closeHit.Activated:Connect(function()
	setMenu(false)
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if input.KeyCode == Enum.KeyCode.LeftAlt then
		altHeld = true
		refreshMouse()
	elseif not processed and input.KeyCode == Enum.KeyCode.M then
		setMenu(not State.menuOpen)
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		dragging.setFromX(input.Position.X)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if dragging then
			dragging = nil
			sendSettings()
		end
	elseif input.KeyCode == Enum.KeyCode.LeftAlt then
		altHeld = false
		refreshMouse()
	end
end)
player.CharacterAdded:Connect(refreshMouse)
refreshMouse()
