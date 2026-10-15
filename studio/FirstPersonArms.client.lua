-- StarterPlayerScripts.FirstPersonArms: blocky viewmodel arms (dark sleeves, tan cuffs, black gloves) held in front
-- of the first-person camera, like the reference. Placeholder visuals.
-- The jab plays on every real punch (ClientState.Jab, fired by ToolsClient). With slot 2 equipped the right hand
-- holds the Vacuum (built from parts below), which shakes and spins its nozzle while sucking.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local State = require(RS:WaitForChild("BTW"):WaitForChild("ClientState"))

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local SLEEVE = Color3.fromHex("565C68") -- near-black read as a void (map-critic)
local CUFF = Color3.fromHex("D9A066")
local GLOVE = Color3.fromHex("3A3F4B")

local vm = Instance.new("Model")
vm.Name = "ViewModel"

local function block(name, size, color, parent)
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
	p.Parent = parent or vm
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
-- Vacuum: offsets are relative to the right fist (palette: dark metal body, hazard-yellow nozzle, blue screen)
local vac = Instance.new("Model")
vac.Name = "Vacuum"
local VAC_PARTS = {
	{ "Grip", Vector3.new(0.35, 0.7, 0.35), "1E1E24", CFrame.new(0, -0.05, 0) },
	{ "Body", Vector3.new(0.75, 0.75, 1.5), "3A3F4B", CFrame.new(0, 0.3, -0.55) },
	{ "Tank", Vector3.new(0.4, 0.55, 0.9), "1FA7E0", CFrame.new(0.55, 0.3, -0.45) },
	{ "Stripe", Vector3.new(0.8, 0.8, 0.2), "FFC627", CFrame.new(0, 0.3, -1.35) },
	{ "Nozzle", Vector3.new(0.45, 0.45, 1.4), "FFC627", CFrame.new(0, 0.3, -2.1) },
	{ "Mouth", Vector3.new(0.85, 0.85, 0.3), "565C68", CFrame.new(0, 0.3, -2.9) },
}
local vacParts = {}
for _, d in ipairs(VAC_PARTS) do
	vacParts[d[1]] = { part = block(d[1], d[2], Color3.fromHex(d[3]), vac), offset = d[4] }
end
vac.Parent = vm
vm.Parent = camera

local bob = 0
local nextArm = 1
local spin = 0

State.Jab.Event:Connect(function()
	if State.equipped ~= 1 then return end
	arms[nextArm].punch = 1
	nextArm = nextArm % 2 + 1
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
	-- vacuum in the right hand
	local holdingVac = State.equipped == 2 and inFirst
	local right = arms[2].fist
	local shake = State.vacuuming and CFrame.new((math.random() - 0.5) * 0.03, (math.random() - 0.5) * 0.03, 0) or CFrame.new()
	spin += dt * (State.vacuuming and 14 or 0)
	local base = right.CFrame * CFrame.new(-0.2, -0.15, 0) * CFrame.Angles(math.rad(-6), math.rad(16), 0) * shake
	for name, v in pairs(vacParts) do
		local cf = base * v.offset
		if name == "Mouth" then cf *= CFrame.Angles(0, 0, spin) end
		v.part.CFrame = cf
		v.part.Transparency = holdingVac and 0 or 1
	end
end)
