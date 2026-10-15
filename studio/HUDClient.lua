-- HUD built from ToyUI at the UI_RULES size budget (1280x720 design size).
-- Top right: money pill + shards pill. Top centre: mine progress. Top left: zone list (mine only).
-- Bottom centre: cart bar above the hotbar. Run banners in the middle.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local ToyUI = require(RS.Modules.ToyUI)
local Icons = require(RS.Modules.Icons)
local Remotes = RS.RemoteEvents
local progress = RS:WaitForChild("MineProgress")
local player = Players.LocalPlayer
local T = ToyUI.Theme

local function withCommas(n)
	local s = tostring(math.floor(n))
	return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end
local function short(n)
	if n >= 1e6 then return string.format("%.1fM", n / 1e6) end
	if n >= 1e4 then return string.format("%.1fK", n / 1e3) end
	return withCommas(n)
end

local gui = ToyUI.root("HUD", player:WaitForChild("PlayerGui"))

-- MONEY (top right) --------------------------------------------------------------
local moneyRoot, moneyFace = ToyUI.block({
	Parent = gui, Name = "Money", Size = UDim2.fromOffset(192, 48),
	Position = UDim2.new(1, -16, 0, 12), AnchorPoint = Vector2.new(1, 0), color = T.gold, depth = 4,
})
ToyUI.icon(moneyRoot, Icons.Coin, UDim2.fromOffset(44, 44), UDim2.fromOffset(-18, -1), 8)
local moneyText = ToyUI.label(moneyFace, {
	Text = "$0", TextSize = 28, Size = UDim2.new(1, -40, 1, 0), Position = UDim2.fromOffset(30, 0),
	TextXAlignment = Enum.TextXAlignment.Right,
})
local pipeText = ToyUI.label(gui, {
	Text = "", TextSize = 14, Font = Enum.Font.BuilderSansBold, Size = UDim2.fromOffset(192, 18),
	Position = UDim2.new(1, -16, 0, 62), AnchorPoint = Vector2.new(1, 0),
	TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = T.gold,
})

-- SHARDS ---------------------------------------------------------------------------
local _, shardFace = ToyUI.block({
	Parent = gui, Name = "Shards", Size = UDim2.fromOffset(144, 36),
	Position = UDim2.new(1, -16, 0, 84), AnchorPoint = Vector2.new(1, 0), color = T.cyan, depth = 3,
})
local gem = Instance.new("Frame")
gem.Size = UDim2.fromOffset(14, 14)
gem.Position = UDim2.fromOffset(14, 8)
gem.Rotation = 45
gem.BackgroundColor3 = Color3.fromHex("E8FBFF")
gem.ZIndex = 6
gem.Parent = shardFace
local gs = Instance.new("UIStroke")
gs.Color = T.outline
gs.Thickness = 2
gs.Parent = gem
local shardText = ToyUI.label(shardFace, {
	Text = "0", TextSize = 20, Size = UDim2.new(1, -44, 1, 0), Position = UDim2.fromOffset(34, 0),
	TextXAlignment = Enum.TextXAlignment.Right,
})

-- MINE PROGRESS (top centre) -----------------------------------------------------------
local _, progressFace = ToyUI.block({
	Parent = gui, Name = "Progress", Size = UDim2.fromOffset(288, 48),
	Position = UDim2.new(0.5, 0, 0, 12), AnchorPoint = Vector2.new(0.5, 0), color = T.cream, depth = 3, studs = 0.82,
})
local progressText = ToyUI.label(progressFace, {
	Text = "Mine searched 0%", TextSize = 16, Size = UDim2.new(1, -24, 0, 22), Position = UDim2.fromOffset(12, 3),
})
local _, pFill = ToyUI.bar(progressFace, UDim2.new(1, -24, 0, 10), UDim2.new(0, 12, 1, -16), T.cyan, 6)

-- ZONES (top left, only inside the mine) -----------------------------------------------
local zoneRoot, zoneFace = ToyUI.block({
	Parent = gui, Name = "Zones", Size = UDim2.fromOffset(216, 60),
	Position = UDim2.fromOffset(16, 12), color = T.cream, depth = 3, studs = 0.82,
})
zoneRoot.Visible = false
ToyUI.label(zoneFace, {
	Text = "MINE ZONES", TextSize = 16, Size = UDim2.new(1, -24, 0, 22), Position = UDim2.fromOffset(12, 6),
	TextXAlignment = Enum.TextXAlignment.Left,
})
local zoneList = Instance.new("Frame")
zoneList.BackgroundTransparency = 1
zoneList.Position = UDim2.fromOffset(12, 32)
zoneList.Size = UDim2.new(1, -24, 1, -38)
zoneList.ZIndex = 5
zoneList.Parent = zoneFace
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 4)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = zoneList
local zoneRows = {}

local function rebuildZones()
	for _, r in pairs(zoneRows) do r.row:Destroy() end
	zoneRows = {}
	local keys = {}
	for attr, value in pairs(progress:GetAttributes()) do
		local key = attr:match("^ZoneName_(.+)$")
		if key then table.insert(keys, { key = key, name = value }) end
	end
	table.sort(keys, function(a, b) return a.name < b.name end)
	for i, k in ipairs(keys) do
		local row = Instance.new("Frame")
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, 0, 0, 18)
		row.LayoutOrder = i
		row.ZIndex = 5
		row.Parent = zoneList
		local name = ToyUI.label(row, {
			Text = k.name, TextSize = 14, Font = Enum.Font.BuilderSansBold, Size = UDim2.new(0.56, 0, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		local _, fill = ToyUI.bar(row, UDim2.new(0.42, 0, 0, 10), UDim2.new(0.58, 0, 0.5, -5), T.green, 6)
		zoneRows[k.key] = { row = row, name = name, fill = fill }
	end
	zoneRoot.Size = UDim2.fromOffset(216, 44 + #keys * 22)
end

local function refresh()
	local total = progress:GetAttribute("Total") or 1
	local mined = progress:GetAttribute("Mined") or 0
	local pct = mined / math.max(total, 1) * 100
	if progress:GetAttribute("DiamondFound") then
		progressText.set("THE DIAMOND HAS BEEN FOUND!")
	else
		progressText.set(string.format(pct < 10 and "Mine searched %.2f%%" or "Mine searched %.1f%%", pct))
	end
	pFill.Size = UDim2.fromScale(math.clamp(pct / 100, 0, 1), 1)
	for key, r in pairs(zoneRows) do
		local t = progress:GetAttribute("Z_" .. key .. "_Total") or 1
		local m = progress:GetAttribute("Z_" .. key .. "_Mined") or 0
		r.fill.Size = UDim2.fromScale(math.clamp(m / math.max(t, 1), 0, 1), 1)
	end
end
progress.AttributeChanged:Connect(function(attr)
	if attr:match("^ZoneName_") then rebuildZones() end
	refresh()
end)
rebuildZones()
refresh()

task.spawn(function()
	while true do
		task.wait(0.5)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local current
		if root then
			local best = 40
			for _, node in ipairs(CollectionService:GetTagged("CoalNode")) do
				local hb = node.PrimaryPart
				if hb then
					local d = (hb.Position - root.Position).Magnitude
					if d < best then
						best = d
						current = (string.gsub(node:GetAttribute("Zone") or "", "[^%w]", "_"))
					end
				end
			end
		end
		zoneRoot.Visible = current ~= nil
		for key, r in pairs(zoneRows) do
			r.name.color(key == current and T.gold or T.white)
		end
	end
end)

-- CART BAR (above the hotbar) ---------------------------------------------------------------
local cartRoot, cartFace = ToyUI.block({
	Parent = gui, Name = "Cart", Size = UDim2.fromOffset(312, 36),
	Position = UDim2.new(0.5, 0, 1, -88), AnchorPoint = Vector2.new(0.5, 1), color = T.cream, depth = 3, studs = 0.82,
})
ToyUI.icon(cartRoot, Icons.Cart, UDim2.fromOffset(40, 40), UDim2.fromOffset(-16, -4), 8)
local cartTrack, cartFill = ToyUI.bar(cartFace, UDim2.new(1, -44, 0, 20), UDim2.new(0, 34, 0.5, -10), T.coal, 6)
local cartText = ToyUI.label(cartTrack, { Text = "0 / 250", TextSize = 14, ZIndex = 9 })

-- DATA -----------------------------------------------------------------------------
local shownMoney = 0
Remotes.UpdateHUDEvent.OnClientEvent:Connect(function(d)
	if not d then return end
	local full = d.Cart >= d.CartCapacity
	cartFill.Size = UDim2.fromScale(math.clamp(d.Cart / math.max(d.CartCapacity, 1), 0, 1), 1)
	cartFill.BackgroundColor3 = full and T.red or T.coal
	cartText.set(full and "FULL - go to the furnace!" or (withCommas(d.Cart) .. " / " .. withCommas(d.CartCapacity)))
	pipeText.set(d.PipeMoney >= 1 and ("$" .. short(d.PipeMoney) .. " waiting at the pad") or "")
	shardText.set(short(d.Shards))
	if d.Money ~= shownMoney then
		local from = shownMoney
		shownMoney = d.Money
		local v = Instance.new("NumberValue")
		v.Value = from
		v.Changed:Connect(function(x) moneyText.set("$" .. short(x)) end)
		TweenService:Create(v, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Value = d.Money }):Play()
		task.delay(0.6, function() v:Destroy() end)
	end
end)

-- RUN BANNERS ---------------------------------------------------------------------------
local function banner(title, sub, color)
	local root, face = ToyUI.block({
		Parent = gui, Name = "Banner", Size = UDim2.fromOffset(480, 108),
		Position = UDim2.fromScale(0.5, 0.3), AnchorPoint = Vector2.new(0.5, 0.5), color = color, depth = 5, ZIndex = 20,
	})
	ToyUI.label(face, { Text = title, TextSize = 32, Size = UDim2.new(1, -40, 0, 44), Position = UDim2.fromOffset(20, 12), ZIndex = 26 })
	ToyUI.label(face, { Text = sub, TextSize = 18, Font = Enum.Font.BuilderSansBold, Size = UDim2.new(1, -40, 0, 28), Position = UDim2.fromOffset(20, 60), ZIndex = 26 })
	local pop = Instance.new("UIScale")
	pop.Scale = 0.3
	pop.Parent = root
	TweenService:Create(pop, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(6, function()
		TweenService:Create(pop, TweenInfo.new(0.15), { Scale = 0 }):Play()
		task.wait(0.2)
		root:Destroy()
	end)
end

Remotes.RunEvent.OnClientEvent:Connect(function(kind, info)
	if kind == "DiamondFound" then
		banner(info.Finder .. " FOUND THE DIAMOND!", "+" .. info.ShardsEarned .. " shards  ·  back to town in " .. info.RegenerateIn .. "s", T.cyan)
	elseif kind == "RunStarted" then
		banner("A NEW DIAMOND IS HIDDEN", "Somewhere in a million pieces of coal...", T.gold)
	end
end)
