-- StarterPlayerScripts.HUD: the minimal core-loop HUD, built only with ToyUI (docs/UI_RULES.md, 1280x720 budget).
-- Top right: Money pill (counts up), left of the settings gear (SettingsUI). Bottom centre: Storage bar above a
-- 2-slot hotbar (1 Fists, 2 Vacuum). Toasts at the top. +$ popups float out of the deposit machine.
-- A small white centre dot (own inset-free ScreenGui) marks the exact aim; the punch grid preview shows the hit.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")

local BTW = RS:WaitForChild("BTW")
local Config = require(BTW.Config)
local State = require(BTW.ClientState)
local ToyUI = require(RS:WaitForChild("Modules"):WaitForChild("ToyUI"))
local Icons = require(RS.Modules:WaitForChild("Icons"))
local Remotes = BTW:WaitForChild("Remotes")
local T = ToyUI.Theme
local player = Players.LocalPlayer

local function withCommas(n)
	local s = tostring(math.floor(n))
	return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end
local function short(n)
	if n >= 1e9 then return string.format("%.1fB", n / 1e9) end
	if n >= 1e6 then return string.format("%.1fM", n / 1e6) end
	if n >= 1e4 then return string.format("%.1fK", n / 1e3) end
	return withCommas(n)
end

local gui = ToyUI.root("HUD", player:WaitForChild("PlayerGui"))

-- MONEY (top right) -------------------------------------------------------------------
local moneyRoot, moneyFace = ToyUI.block({
	Parent = gui, Name = "Money", Size = UDim2.fromOffset(192, 48),
	Position = UDim2.new(1, -16 - 48 - 12, 0, 12), AnchorPoint = Vector2.new(1, 0), color = T.gold, depth = 4,
})
local moneyText
if Icons.Coin then -- the coin hangs off the left end of the pill, like the reference HUDs
	ToyUI.icon(moneyRoot, Icons.Coin, UDim2.fromOffset(52, 52), UDim2.fromOffset(-22, -4), 8)
	moneyText = ToyUI.label(moneyFace, {
		Text = "$0", TextSize = 30, Size = UDim2.new(1, -46, 1, 0), Position = UDim2.fromOffset(34, 0),
	})
else
	moneyText = ToyUI.label(moneyFace, {
		Text = "$0", TextSize = 30, Size = UDim2.new(1, -24, 1, 0), Position = UDim2.fromOffset(12, 0),
	})
end
local moneyPop = Instance.new("UIScale")
moneyPop.Parent = moneyRoot

local shown, target = 0, 0
local function setMoney(v)
	if v > target then
		moneyPop.Scale = 1.12
		TweenService:Create(moneyPop, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
	target = v
end
RunService.RenderStepped:Connect(function(dt)
	if shown ~= target then
		local step = math.max(1, math.abs(target - shown) * math.min(1, dt * 8))
		shown = shown < target and math.min(target, shown + step) or math.max(target, shown - step)
		moneyText.set("$" .. short(shown))
	end
end)
task.spawn(function()
	local money = player:WaitForChild("leaderstats"):WaitForChild("Money")
	shown = money.Value
	target = money.Value
	moneyText.set("$" .. short(shown))
	money.Changed:Connect(setMoney)
end)

-- HOTBAR + STORAGE (bottom centre) ----------------------------------------------------
local SLOT, GAP = 60, 12
local bottom = Instance.new("Frame")
bottom.Name = "Bottom"
bottom.BackgroundTransparency = 1
bottom.AnchorPoint = Vector2.new(0.5, 1)
bottom.Position = UDim2.new(0.5, 0, 1, -16)
bottom.Size = UDim2.fromOffset(312, 36 + 12 + SLOT + 6)
bottom.Parent = gui

-- slate facility panel with a dark inset well; the fill gets a gloss strip and 10% ticks so it reads as a gauge
local storageRoot, storageFace = ToyUI.block({
	Parent = bottom, Name = "Storage", Size = UDim2.fromOffset(312, 36), color = T.slate, depth = 3, studs = 0.85,
})
local track, fill = ToyUI.bar(storageFace, UDim2.new(1, -104, 0, 20), UDim2.new(0, 94, 0.5, -10), T.green, 6)
track.BackgroundColor3 = T.well
-- the kit's fill gradient is tinted with the starting colour and would multiply over orange/red; make it neutral
fill:FindFirstChildOfClass("UIGradient").Color = ColorSequence.new(T.white, T.white:Lerp(T.grey, 0.35))
local gloss = Instance.new("Frame")
gloss.Name = "Gloss"
gloss.BackgroundColor3 = T.white
gloss.BackgroundTransparency = 0.6
gloss.BorderSizePixel = 0
gloss.Position = UDim2.fromOffset(0, 2)
gloss.Size = UDim2.new(1, 0, 0, 5) -- scale width + clipping: a negative offset width would render mirrored
fill.ClipsDescendants = true
gloss.ZIndex = 8
gloss.Parent = fill
local gc = Instance.new("UICorner")
gc.CornerRadius = UDim.new(0, 2)
gc.Parent = gloss
for i = 1, 9 do
	local tick = Instance.new("Frame")
	tick.Name = "Tick"
	tick.BackgroundColor3 = T.well
	tick.BackgroundTransparency = 0.45
	tick.BorderSizePixel = 0
	tick.AnchorPoint = Vector2.new(0.5, 0)
	tick.Position = UDim2.new(i / 10, 0, 0, 3)
	tick.Size = UDim2.new(0, 2, 1, -6)
	tick.ZIndex = 8
	tick.Parent = track
end
ToyUI.label(storageFace, {
	Text = "STORAGE", TextSize = 16, Size = UDim2.fromOffset(80, 33), Position = UDim2.fromOffset(10, 0), ZIndex = 8,
	TextXAlignment = Enum.TextXAlignment.Left,
})
local storageText = ToyUI.label(track, { Text = "0 / 50", TextSize = 14, ZIndex = 10 })
local storagePop = Instance.new("UIScale")
storagePop.Parent = storageRoot

local lastCount = 0
local function refreshStorage()
	local c = player:GetAttribute("StorageCount") or 0
	local m = player:GetAttribute("StorageMax") or Config.Storage.start
	local full = c >= m
	storageText.set(full and "FULL - DEPOSIT!" or (c .. " / " .. m))
	local frac = math.clamp(c / m, 0, 1)
	TweenService:Create(fill, TweenInfo.new(0.15), {
		Size = UDim2.fromScale(frac, 1),
		BackgroundColor3 = full and T.red or (frac >= 0.7 and T.orange or T.green),
	}):Play()
	if c > lastCount then
		storagePop.Scale = 1.06
		TweenService:Create(storagePop, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
	lastCount = c
end
player:GetAttributeChangedSignal("StorageCount"):Connect(refreshStorage)
player:GetAttributeChangedSignal("StorageMax"):Connect(refreshStorage)
refreshStorage()

local bar = Instance.new("Frame")
bar.Name = "Hotbar"
bar.BackgroundTransparency = 1
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Position = UDim2.new(0.5, 0, 1, 0)
bar.Size = UDim2.fromOffset(SLOT * 2 + GAP, SLOT)
bar.Parent = bottom

-- the gold selector sits behind the equipped slot
local selector = ToyUI.block({
	Parent = bar, Name = "Selector", Size = UDim2.fromOffset(SLOT + 12, SLOT + 12),
	Position = UDim2.fromOffset(-6, -6), color = T.gold, depth = 4, studs = false,
})

-- icons are tiny 3D renders of the actual held models (no emoji or letters)
local function viewport(face, parts, camCF)
	local vp = Instance.new("ViewportFrame")
	vp.BackgroundTransparency = 1
	vp.Size = UDim2.fromOffset(44, 44)
	vp.Position = UDim2.new(0.5, -22, 0.5, -24)
	vp.ZIndex = face.ZIndex + 3
	vp.LightColor = Color3.new(1, 1, 1)
	vp.Ambient = Color3.fromRGB(170, 170, 180)
	vp.LightDirection = Vector3.new(-1, -1.5, -1)
	for _, d in ipairs(parts) do
		local p = Instance.new("Part")
		p.Size, p.Color, p.CFrame = d[1], Color3.fromHex(d[2]), d[3]
		p.Material = Enum.Material.SmoothPlastic
		p.Parent = vp
	end
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	cam.CFrame = camCF
	cam.Parent = vp
	vp.CurrentCamera = cam
	vp.Parent = face
end

local SLOTS = {
	{ name = "FISTS", icons = Icons.Fist, tierAttr = "FistTier", parts = {
		{ Vector3.new(1.4, 1.4, 1.4), "3A3F4B", CFrame.new(0, 0, 0) },
		{ Vector3.new(1.2, 1.2, 0.5), "D9A066", CFrame.new(0, 0, 0.95) },
		{ Vector3.new(1.1, 1.1, 1.4), "565C68", CFrame.new(0, 0, 1.9) },
	}, cam = CFrame.lookAt(Vector3.new(4.5, 3, -4.5), Vector3.new(0, 0, 0.6)) },
	{ name = "VACUUM", icons = Icons.Vacuum, tierAttr = "VacuumTier", parts = {
		{ Vector3.new(0.75, 0.75, 1.5), "3A3F4B", CFrame.new(0, 0, 0.6) },
		{ Vector3.new(0.4, 0.55, 0.9), "1FA7E0", CFrame.new(0.55, 0, 0.7) },
		{ Vector3.new(0.8, 0.8, 0.2), "FFC627", CFrame.new(0, 0, -0.2) },
		{ Vector3.new(0.45, 0.45, 1.4), "FFC627", CFrame.new(0, 0, -0.95) },
		{ Vector3.new(0.85, 0.85, 0.3), "565C68", CFrame.new(0, 0, -1.75) },
	}, cam = CFrame.lookAt(Vector3.new(5.5, 3, -2.5), Vector3.new(0, 0.1, -0.2)) },
}

local slotRoots = {}
for i, s in ipairs(SLOTS) do
	local root, face, hit = ToyUI.button({
		Parent = bar, Name = "Slot" .. i, Size = UDim2.fromOffset(SLOT, SLOT),
		Position = UDim2.fromOffset((i - 1) * (SLOT + GAP), 0), color = T.sky, depth = 4, studs = 0.8, ZIndex = 3,
	})
	if s.icons and s.icons[0] then
		-- generated icon for the tool's current tier (FistTier 0-5 / VacuumTier 0-5 attribute, 0 = starter)
		local icon = ToyUI.icon(face, s.icons[0], UDim2.fromOffset(48, 48), UDim2.fromOffset(6, 2), 8)
		local shadow = face:FindFirstChild("IconShadow")
		local function showTier()
			local tier = player:GetAttribute(s.tierAttr) or 0
			local img = s.icons[tier] or s.icons[0]
			icon.Image = img
			if shadow then shadow.Image = img end
		end
		player:GetAttributeChangedSignal(s.tierAttr):Connect(showTier)
		showTier()
	else
		viewport(face, s.parts, s.cam)
	end
	ToyUI.label(face, {
		Text = tostring(i), TextSize = 14, Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(4, 2), ZIndex = 12,
	})
	hit.Activated:Connect(function()
		State.Sfx:Fire("click")
		State.equip(i)
	end)
	slotRoots[i] = root
end

local nameTag = ToyUI.label(gui, {
	Text = "", TextSize = 22, Size = UDim2.fromOffset(300, 28),
	Position = UDim2.new(0.5, 0, 1, -(16 + 36 + 12 + SLOT + 18)), AnchorPoint = Vector2.new(0.5, 1),
})
local tagToken = 0
local function showEquipped(slot)
	selector.Position = UDim2.fromOffset((slot - 1) * (SLOT + GAP) - 6, -6)
	nameTag.set(SLOTS[slot].name)
	nameTag.text.TextTransparency, nameTag.shadow.TextTransparency = 0, 0
	for _, st in ipairs(nameTag.frame:GetDescendants()) do
		if st:IsA("UIStroke") then st.Transparency = 0 end
	end
	tagToken += 1
	local my = tagToken
	task.delay(1.2, function()
		if my ~= tagToken then return end
		local info = TweenInfo.new(0.4)
		TweenService:Create(nameTag.text, info, { TextTransparency = 1 }):Play()
		TweenService:Create(nameTag.shadow, info, { TextTransparency = 1 }):Play()
		for _, st in ipairs(nameTag.frame:GetDescendants()) do
			if st:IsA("UIStroke") then TweenService:Create(st, info, { Transparency = 1 }):Play() end
		end
	end)
end
State.EquipChanged.Event:Connect(showEquipped)
showEquipped(State.equipped)

-- CENTRE DOT (own ScreenGui with no inset, so it sits on the true screen centre the camera aims through) ---
local dotGui = Instance.new("ScreenGui")
dotGui.Name = "CenterDot"
dotGui.IgnoreGuiInset = true
dotGui.ScreenInsets = Enum.ScreenInsets.None
dotGui.ResetOnSpawn = false
dotGui.DisplayOrder = 5
dotGui.Parent = player.PlayerGui
local dot = Instance.new("Frame")
dot.Name = "Dot"
dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.Position = UDim2.fromScale(0.5, 0.5)
dot.Size = UDim2.fromOffset(6, 6)
dot.BackgroundColor3 = T.white
dot.Parent = dotGui
local dc = Instance.new("UICorner")
dc.CornerRadius = UDim.new(1, 0)
dc.Parent = dot
local ds = Instance.new("UIStroke")
ds.Color = T.outline
ds.Thickness = 1.5
ds.Transparency = 0.2
ds.Parent = dot

-- TOOL SHOP PROMPTS: relabel the podium prompts with this player's next tier and price ---------------------
local function relabelShop()
	for _, pp in ipairs(workspace:GetDescendants()) do
		local kind = pp:IsA("ProximityPrompt") and pp:GetAttribute("Shop")
		if kind then
			local tier = (player:GetAttribute(kind == "Fist" and "FistTier" or "VacuumTier") or 0) + 1
			local item = (kind == "Fist" and Config.Knuckles or Config.Vacuums)[tier]
			pp.ActionText = item and ("Buy " .. item.name) or "Maxed out"
			pp.ObjectText = item and ("$" .. short(item.price)) or ""
			pp.Enabled = item ~= nil
		end
	end
end
player:GetAttributeChangedSignal("FistTier"):Connect(relabelShop)
player:GetAttributeChangedSignal("VacuumTier"):Connect(relabelShop)
task.delay(3, relabelShop)
workspace.DescendantAdded:Connect(function(d)
	if d:IsA("ProximityPrompt") and d:GetAttribute("Shop") then relabelShop() end
end)

-- TOASTS ------------------------------------------------------------------------------
local toastRoot, toastFace = ToyUI.block({
	Parent = gui, Name = "Toast", Size = UDim2.fromOffset(480, 48),
	Position = UDim2.new(0.5, 0, 0, 84), AnchorPoint = Vector2.new(0.5, 0), color = T.green, depth = 4,
})
local toastText = ToyUI.label(toastFace, { Text = "", TextSize = 22, Size = UDim2.new(1, -24, 1, 0), Position = UDim2.fromOffset(12, 0) })
toastRoot.Visible = false
local toastToken = 0
Remotes.Toast.OnClientEvent:Connect(function(text)
	toastText.set(text)
	toastRoot.Visible = true
	toastToken += 1
	local my = toastToken
	task.delay(3.5, function()
		if my == toastToken then toastRoot.Visible = false end
	end)
end)

-- +$ POPUPS (in the world, out of the deposit machine) ----------------------------------
Remotes.DepositPaid.OnClientEvent:Connect(function(amount, pos)
	local anchor = Instance.new("Part")
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
	anchor.Position = pos + Vector3.new((math.random() - 0.5) * 4, 3 + math.random() * 1.5, (math.random() - 0.5) * 2)
	anchor.Parent = workspace.CurrentCamera
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(5, 1.6)
	bb.LightInfluence = 0
	bb.MaxDistance = 80
	bb.Adornee = anchor
	bb.Parent = anchor
	local lbl = ToyUI.label(bb, { Text = "+$" .. short(amount), TextSize = 40, TextColor3 = T.gold })
	lbl.text.TextScaled, lbl.shadow.TextScaled = true, true
	TweenService:Create(anchor, TweenInfo.new(1.1, Enum.EasingStyle.Quad), { Position = anchor.Position + Vector3.new(0, 4, 0) }):Play()
	task.delay(0.6, function()
		local info = TweenInfo.new(0.5)
		TweenService:Create(lbl.text, info, { TextTransparency = 1 }):Play()
		TweenService:Create(lbl.shadow, info, { TextTransparency = 1 }):Play()
		for _, s in ipairs(bb:GetDescendants()) do
			if s:IsA("UIStroke") then TweenService:Create(s, info, { Transparency = 1 }):Play() end
		end
	end)
	task.delay(1.2, function()
		anchor:Destroy()
	end)
end)
