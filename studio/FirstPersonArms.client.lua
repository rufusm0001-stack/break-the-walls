-- StarterPlayerScripts.FirstPersonArms: blocky viewmodel arms (dark sleeves, tan cuffs, black gloves) held in front
-- of the first-person camera, like the reference. Placeholder visuals; the tool model will attach to "RightHand".
-- Click = a quick punch jab (visual only for now; the server punch logic comes with the core loop).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local SLEEVE = Color3.fromHex("565C68") -- near-black read as a void (map-critic)
local CUFF = Color3.fromHex("D9A066")
local GLOVE = Color3.fromHex("3A3F4B")

local vm = Instance.new("Model")
vm.Name = "ViewModel"

local function block(name, size, color)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Parent = vm
	return p
end

-- each arm: sleeve, cuff, fist; offsets are relative to the arm root
local arms = {}
for _, side in ipairs({ -1, 1 }) do
	local a = {
		side = side,
		sleeve = block(side < 0 and "LeftSleeve" or "RightSleeve", Vector3.new(0.55, 0.55, 1.6), SLEEVE),
		cuff = block(side < 0 and "LeftCuff" or "RightCuff", Vector3.new(0.62, 0.62, 0.25), CUFF),
		fist = block(side < 0 and "LeftHand" or "RightHand", Vector3.new(0.7, 0.7, 0.7), GLOVE),
		punch = 0,
	}
	table.insert(arms, a)
end
vm.Parent = camera

local bob = 0
local nextArm = 1

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		arms[nextArm].punch = 1
		nextArm = nextArm % 2 + 1
	end
end)

RunService:BindToRenderStep("FirstPersonArms", Enum.RenderPriority.Camera.Value + 1, function(dt)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local moving = hum and hum.MoveDirection.Magnitude > 0.1
	bob += dt * (moving and 9 or 2)
	local amp = moving and 0.06 or 0.015
	local inFirst = (camera.CFrame.Position - camera.Focus.Position).Magnitude < 1.5
	for _, a in ipairs(arms) do
		a.punch = math.max(0, a.punch - dt * 6)
		local jab = math.sin(a.punch * math.pi) * 0.9
		local root = camera.CFrame
			* CFrame.new(a.side * 1.3, -1.6 + math.sin(bob + a.side) * amp, -1.8 - jab)
			* CFrame.Angles(math.rad(14), math.rad(-a.side * 12), 0)
		a.sleeve.CFrame = root * CFrame.new(0, 0, 0.55)
		a.cuff.CFrame = root * CFrame.new(0, 0, -0.35)
		a.fist.CFrame = root * CFrame.new(0, 0, -0.8)
		local t = inFirst and 0 or 1
		a.sleeve.Transparency, a.cuff.Transparency, a.fist.Transparency = t, t, t
	end
end)
