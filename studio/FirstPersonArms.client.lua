-- StarterPlayerScripts.FirstPersonArms: your own avatar's arms held in front of the first-person camera.
-- The R15 arm meshes (UpperArm, LowerArm, Hand) are cloned from your character with your shirt and body colours
-- (a Humanoid inside the viewmodel applies the Shirt), scaled up a little and angled in toward the crosshair.
-- R6 or missing parts fall back to blocky arms in your body colours. Knuckle dusters will attach to "RightHand".
-- The jab plays on every real punch (ClientState.Jab). With slot 2 equipped the right hand holds the Vacuum,
-- which shakes and spins its mouth while sucking; its mouth CFrame is published as ClientState.nozzle.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local State = require(RS:WaitForChild("BTW"):WaitForChild("ClientState"))

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local ARM_SCALE = 1.1 -- a touch thicker than the real avatar arm so it reads well in first person
-- arm pose (studs / degrees, camera space). Any of these can be overridden live by setting the same-named
-- attribute on Camera.ViewModel, which is how the pose was tuned in Play.
local POSE = { x = 2.0, y = -2.3, z = 0.5, pitch = 26, yaw = 16, roll = 18, vacYaw = 4 }
local SEGMENTS = { "UpperArm", "LowerArm", "Hand" }

local vm = Instance.new("Model")
vm.Name = "ViewModel"
local hum = Instance.new("Humanoid") -- applies the cloned Shirt to the R15-named parts
hum.RigType = Enum.HumanoidRigType.R15
hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
hum.EvaluateStateMachine = false
hum.Parent = vm
vm.Parent = camera

local function prep(p)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Massless = true
end

local function block(name, size, color, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	prep(p)
	p.Parent = parent or vm
	return p
end

-- arms[side] = { side, parts = { {part, len} ... } in shoulder-to-hand order, reach (total length), punch }
local arms = {}

local function clearArms()
	for _, a in pairs(arms) do
		for _, seg in ipairs(a.parts) do
			seg.part:Destroy()
		end
	end
	arms = {}
	for _, c in ipairs(vm:GetChildren()) do
		if c:IsA("Shirt") or c:IsA("BodyColors") then c:Destroy() end
	end
end

local function buildArms(char)
	clearArms()
	local shirt = char:FindFirstChildOfClass("Shirt")
	if shirt then shirt:Clone().Parent = vm end
	local colors = char:FindFirstChildOfClass("BodyColors")
	if colors then colors:Clone().Parent = vm end
	for _, side in ipairs({ -1, 1 }) do
		local prefix = side < 0 and "Left" or "Right"
		local a = { side = side, parts = {}, reach = 0, punch = 0 }
		local ok = true
		for _, seg in ipairs(SEGMENTS) do
			if not char:FindFirstChild(prefix .. seg) then ok = false end
		end
		if ok then
			for _, seg in ipairs(SEGMENTS) do
				local src = char[prefix .. seg]
				local p = src:Clone()
				for _, c in ipairs(p:GetChildren()) do
					if not (c:IsA("SurfaceAppearance") or c:IsA("SpecialMesh")) then c:Destroy() end
				end
				p.Size = src.Size * ARM_SCALE
				prep(p)
				p.LocalTransparencyModifier = 0
				p.Parent = vm
				table.insert(a.parts, { part = p, len = p.Size.Y })
				a.reach += p.Size.Y
			end
		else -- R6 / unusual rigs: classic blocky arm in the body colour, with a sleeve in the shirt-ish torso colour
			local skin = colors and (side < 0 and colors.LeftArmColor3 or colors.RightArmColor3) or Color3.fromHex("F5CD30")
			local sleeve = colors and colors.TorsoColor3 or Color3.fromHex("565C68")
			local s = ARM_SCALE
			local up = block(prefix .. "UpperArm", Vector3.new(1, 1.2, 1) * s, sleeve)
			local low = block(prefix .. "LowerArm", Vector3.new(1, 1, 1) * s, skin)
			local hand = block(prefix .. "Hand", Vector3.new(1, 0.5, 1) * s, skin)
			for _, p in ipairs({ up, low, hand }) do
				table.insert(a.parts, { part = p, len = p.Size.Y })
				a.reach += p.Size.Y
			end
		end
		arms[side] = a
	end
end

local function onCharacter(char)
	if not player:HasAppearanceLoaded() then
		player.CharacterAppearanceLoaded:Wait()
	end
	char:WaitForChild("Humanoid")
	task.wait(0.1) -- let the shirt and body colours settle
	if player.Character == char then buildArms(char) end
end
player.CharacterAdded:Connect(onCharacter)
if player.Character then task.spawn(onCharacter, player.Character) end

-- Vacuum: offsets are relative to the right hand grip (palette: dark metal body, hazard-yellow nozzle, blue tank).
-- Placeholder until the Meshy model (art/MESHY_PROMPTS.md, Vacuum_Basic) is in.
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
vac.Parent = camera

-- wind streaks rushing back into the mouth while sucking: a box of emitters ahead of the nozzle
local windShell = Instance.new("Part")
windShell.Name = "WindShell"
windShell.Size = Vector3.new(3, 3, 0.2)
windShell.Transparency = 1
prep(windShell)
windShell.Parent = vac
local wind = Instance.new("ParticleEmitter")
wind.Name = "Wind"
wind.Enabled = false
wind.Rate = 90
wind.Lifetime = NumberRange.new(0.12, 0.2)
wind.Speed = NumberRange.new(26, 34)
wind.EmissionDirection = Enum.NormalId.Back -- +Z of the shell = back toward the nozzle
wind.SpreadAngle = Vector2.new(6, 6)
wind.Shape = Enum.ParticleEmitterShape.Box
wind.Orientation = Enum.ParticleOrientation.VelocityParallel
wind.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(1, 0.02) })
wind.Squash = NumberSequence.new(-3) -- stretched into thin streaks
wind.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.4),
	NumberSequenceKeypoint.new(1, 1) })
wind.Color = ColorSequence.new(Color3.new(1, 1, 1))
wind.LightEmission = 0.4
wind.Parent = windShell

local bob = 0
local nextArm = 1
local spin = 0

State.Jab.Event:Connect(function()
	if State.equipped ~= 1 then return end
	local a = arms[nextArm == 1 and -1 or 1]
	if a then a.punch = 1 end
	nextArm = nextArm % 2 + 1
end)

-- lay one arm's segments from the shoulder forward along root's -Z, knuckles-forward, back of the hand up
local function layArm(a, root, visible)
	local along = 0
	for _, seg in ipairs(a.parts) do
		local mid = along + seg.len / 2
		seg.part.CFrame = root * CFrame.new(0, 0, -mid) * CFrame.Angles(0, 0, math.rad(a.side * 90)) * CFrame.Angles(math.rad(90), 0, 0)
		seg.part.LocalTransparencyModifier = 0
		seg.part.Transparency = visible and 0 or 1
		along += seg.len
	end
end

RunService:BindToRenderStep("FirstPersonArms", Enum.RenderPriority.Camera.Value + 1, function(dt)
	-- camera kick from punches (applied after the camera script has placed the camera)
	if State.shake > 0.001 then
		local s = State.shake
		camera.CFrame *= CFrame.Angles((math.random() - 0.5) * s * 0.04, (math.random() - 0.5) * s * 0.04, 0)
		State.shake = s * math.exp(-dt * 18)
	end
	local char = player.Character
	local h = char and char:FindFirstChildOfClass("Humanoid")
	local moving = h and h.MoveDirection.Magnitude > 0.1
	bob += dt * (moving and 9 or 2)
	local amp = moving and 0.06 or 0.015
	local inFirst = (camera.CFrame.Position - camera.Focus.Position).Magnitude < 1.5
	local holdingVac = State.equipped == 2 and inFirst
	local grip
	for side, a in pairs(arms) do
		a.punch = math.max(0, a.punch - dt * 6)
		local jab = math.sin(a.punch * math.pi) * 1.1
		-- shoulder sits low and wide; the arm angles up and in toward the crosshair
		local P = POSE
		local function tv(k) return vm:GetAttribute(k) or P[k] end
		local inward = tv("yaw") + (side > 0 and holdingVac and tv("vacYaw") or 0)
		local root = camera.CFrame
			* CFrame.new(side * tv("x"), tv("y") + math.sin(bob + side) * amp, tv("z") - jab)
			* CFrame.Angles(math.rad(tv("pitch") + jab * 6), math.rad(side * inward), math.rad(-side * tv("roll")))
		layArm(a, root, inFirst)
		if side > 0 then
			grip = root * CFrame.new(0, 0.1, -(a.reach - 0.35))
		end
	end
	-- vacuum in the right hand
	if not grip then
		grip = camera.CFrame * CFrame.new(1.2, -1.4, -2.4)
	end
	local shake = State.vacuuming and CFrame.new((math.random() - 0.5) * 0.03, (math.random() - 0.5) * 0.03, 0) or CFrame.new()
	spin += dt * (State.vacuuming and 14 or 0)
	-- undo most of the arm's pitch and roll so the vacuum points level at the crosshair, and sit it lower
	local base = grip * CFrame.Angles(0, 0, math.rad(18)) * CFrame.Angles(math.rad(-22), math.rad(6), 0)
		* CFrame.new(0, -0.35, 0.3) * shake
	for name, v in pairs(vacParts) do
		local cf = base * v.offset
		if name == "Mouth" then
			cf *= CFrame.Angles(0, 0, spin)
			State.nozzle = cf
		end
		v.part.CFrame = cf
		v.part.Transparency = holdingVac and 0 or 1
	end
	windShell.CFrame = base * CFrame.new(0, 0.3, -7)
	wind.Enabled = holdingVac and State.vacuuming
	if not holdingVac then State.nozzle = nil end
end)
