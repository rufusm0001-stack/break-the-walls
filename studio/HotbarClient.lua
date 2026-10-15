-- Custom hotbar from ToyUI: 60x60 brick slots with the item icon, key number and the tool's
-- DisplayName attribute (never the raw Tool name). 1-9 / click / tap to equip.

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")

local ToyUI = require(RS.Modules.ToyUI)
local Icons = require(RS.Modules.Icons)
local T = ToyUI.Theme
local player = Players.LocalPlayer

local SLOT = 60
local GAP = 12
local MAX_SLOTS = 9

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

local gui = ToyUI.root("Hotbar", player:WaitForChild("PlayerGui"))

local bar = Instance.new("Frame")
bar.Name = "Bar"
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Position = UDim2.new(0.5, 0, 1, -16)
bar.BackgroundTransparency = 1
bar.Size = UDim2.fromOffset(SLOT, SLOT)
bar.Parent = gui
local list = Instance.new("UIListLayout")
list.FillDirection = Enum.FillDirection.Horizontal
list.HorizontalAlignment = Enum.HorizontalAlignment.Center
list.Padding = UDim.new(0, GAP)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = bar

local nameTag = ToyUI.label(gui, {
	Text = "", TextSize = 22, Size = UDim2.fromOffset(300, 28),
	Position = UDim2.new(0.5, 0, 1, -132), AnchorPoint = Vector2.new(0.5, 1),
})
nameTag.frame.Visible = false

local slots = {}

local function makeSlot(i)
	local root, face, hit = ToyUI.button({
		Parent = bar, Name = "Slot" .. i, Size = UDim2.fromOffset(SLOT, SLOT), color = T.cream, depth = 4, studs = 0.8,
	})
	root.LayoutOrder = i
	local icon = ToyUI.icon(face, "", UDim2.fromOffset(42, 42), UDim2.fromOffset(9, 6), 8)
	local key = ToyUI.label(face, {
		Text = tostring(i), TextSize = 14, Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(4, 2), ZIndex = 12,
	})
	local slot = { root = root, face = face, icon = icon, tool = nil }
	hit.Activated:Connect(function()
		slot.toggle()
	end)
	return slot
end

local function currentTools()
	local tools = {}
	for _, container in ipairs({ player.Character, player:FindFirstChildOfClass("Backpack") }) do
		if container then
			for _, t in ipairs(container:GetChildren()) do
				if t:IsA("Tool") then table.insert(tools, t) end
			end
		end
	end
	table.sort(tools, function(a, b)
		local ta, tb = a:GetAttribute("Tier") or 0, b:GetAttribute("Tier") or 0
		return ta < tb or (ta == tb and a.Name < b.Name)
	end)
	return tools
end

local function paint(slot)
	local equipped = slot.tool and player.Character and slot.tool.Parent == player.Character
	local color = equipped and T.gold or T.cream
	slot.face.UIGradient.Color = ColorSequence.new(color:Lerp(T.white, 0.18), color)
	slot.root.Slab.BackgroundColor3 = ToyUI.slabOf(color)
end

local function refresh()
	local tools = currentTools()
	local count = math.min(#tools, MAX_SLOTS)
	for i, slot in ipairs(slots) do
		local tool = tools[i]
		slot.tool = tool
		slot.root.Visible = tool ~= nil
		if tool then
			local image = Icons[tool.Name] or tool.TextureId
			slot.icon.Image = image
			slot.icon.Parent:FindFirstChild("IconShadow").Image = image
			paint(slot)
		end
	end
	bar.Size = UDim2.fromOffset(count * SLOT + math.max(count - 1, 0) * GAP, SLOT)
end

local flashToken = 0
local function flashName(text)
	flashToken += 1
	local token = flashToken
	nameTag.set(text)
	nameTag.frame.Visible = true
	task.delay(1.6, function()
		if flashToken == token then nameTag.frame.Visible = false end
	end)
end

for i = 1, MAX_SLOTS do
	local slot = makeSlot(i)
	slot.root.Visible = false
	function slot.toggle()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not slot.tool or not humanoid then return end
		if slot.tool.Parent == character then
			humanoid:UnequipTools()
		else
			humanoid:EquipTool(slot.tool)
			flashName(slot.tool:GetAttribute("DisplayName") or slot.tool.Name)
		end
	end
	slots[i] = slot
end

local KEYS = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five,
	Enum.KeyCode.Six, Enum.KeyCode.Seven, Enum.KeyCode.Eight, Enum.KeyCode.Nine }
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	for i, code in ipairs(KEYS) do
		if input.KeyCode == code and slots[i] then slots[i].toggle() end
	end
end)

local function watch(container)
	container.ChildAdded:Connect(refresh)
	container.ChildRemoved:Connect(refresh)
end
local function onCharacter(character)
	watch(character)
	watch(player:WaitForChild("Backpack"))
	refresh()
end
player.CharacterAdded:Connect(onCharacter)
if player.Character then onCharacter(player.Character) end
