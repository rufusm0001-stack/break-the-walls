-- The diamond-found moment, played for every player from RunEvent "DiamondFound" {Position, Finder}:
-- brick debris burst, a big glowing diamond rising and spinning with sparkles, a light beam
-- shooting up out of the mountain (visible from town), and a short camera swing to it.
-- The banner text itself is shown by HUDClient.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Remotes = RS.RemoteEvents
local player = Players.LocalPlayer
local DIAMOND = Color3.fromHex("7FE8FF")
local DIAMOND_LIGHT = Color3.fromHex("E8FBFF")

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do p[k] = v end
	p.Parent = workspace
	return p
end

local function burst(at)
	for i = 1, 18 do
		local c = part({
			Size = Vector3.new(1, 1, 1),
			Color = (i % 5 == 0) and Color3.fromHex("F5B800") or Color3.fromHex("3A3A4A"),
			Position = at + Vector3.new(math.random() - 0.5, math.random(), math.random() - 0.5) * 2,
			Anchored = false,
		})
		c.TopSurface = Enum.SurfaceType.Studs
		c.AssemblyLinearVelocity = Vector3.new((math.random() - 0.5) * 40, 25 + math.random() * 20, (math.random() - 0.5) * 40)
		c.AssemblyAngularVelocity = Vector3.new(math.random() * 10, math.random() * 10, math.random() * 10)
		TweenService:Create(c, TweenInfo.new(1.4), { Size = Vector3.new(0.1, 0.1, 0.1) }):Play()
		Debris:AddItem(c, 1.5)
	end
end

local function buildDiamond(at)
	local model = Instance.new("Model")
	model.Name = "FoundDiamond"
	-- a chunky octahedron-ish gem from two stacked wedge rings
	local core = part({ Size = Vector3.new(3, 3, 3), Color = DIAMOND, Material = Enum.Material.Glass, Transparency = 0.15, CFrame = CFrame.new(at) * CFrame.Angles(math.rad(45), 0, math.rad(45)) })
	core.Name = "Core"
	core.Parent = model
	local shine = part({ Size = Vector3.new(1.6, 1.6, 1.6), Color = DIAMOND_LIGHT, Material = Enum.Material.Neon, CFrame = core.CFrame })
	shine.Name = "Shine"
	shine.Parent = model
	model.PrimaryPart = core
	local light = Instance.new("PointLight")
	light.Color = DIAMOND
	light.Range = 30
	light.Brightness = 4
	light.Parent = core
	local att = Instance.new("Attachment")
	att.Parent = core
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkle.Color = ColorSequence.new(DIAMOND_LIGHT, DIAMOND)
	sparkle.LightEmission = 1
	sparkle.Size = NumberSequence.new(0.6, 0)
	sparkle.Lifetime = NumberRange.new(0.6, 1.2)
	sparkle.Speed = NumberRange.new(3, 7)
	sparkle.SpreadAngle = Vector2.new(180, 180)
	sparkle.Rate = 40
	sparkle.Parent = att
	model.Parent = workspace
	return model, core, shine
end

local function beam(at, duration)
	local height = 400
	local pillar = part({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, 12, 12),
		CFrame = CFrame.new(at + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = DIAMOND,
		Material = Enum.Material.Neon,
		Transparency = 1,
		CastShadow = false,
	})
	pillar.Name = "DiamondBeam"
	TweenService:Create(pillar, TweenInfo.new(0.6), { Transparency = 0.2 }):Play()
	task.delay(duration, function()
		TweenService:Create(pillar, TweenInfo.new(1.5), { Transparency = 1, Size = Vector3.new(height, 0.5, 0.5) }):Play()
		Debris:AddItem(pillar, 1.6)
	end)
end

local function cameraSwing(target, seconds)
	local camera = workspace.CurrentCamera
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - target).Magnitude > 200 then
		return -- far away (e.g. up in town): the beam is the signal, don't yank the camera
	end
	local previous = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable
	local startAngle = math.atan2(camera.CFrame.Position.Z - target.Z, camera.CFrame.Position.X - target.X)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character, workspace:FindFirstChild("FoundDiamond") }
	local focus = target + Vector3.new(0, 4, 0)
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local a = startAngle + t * 0.6
		local want = target + Vector3.new(math.cos(a) * 16, 6 + t * 0.8, math.sin(a) * 16)
		-- pull the camera in front of any wall between it and the diamond, so caves never clip
		local hit = workspace:Raycast(focus, want - focus, rayParams)
		local pos = hit and (hit.Position + (focus - hit.Position).Unit * 1.5) or want
		camera.CFrame = CFrame.lookAt(pos, focus)
		if t >= seconds then
			conn:Disconnect()
			camera.CameraType = previous
		end
	end)
end

Remotes.RunEvent.OnClientEvent:Connect(function(kind, info)
	if kind ~= "DiamondFound" or not info or typeof(info.Position) ~= "Vector3" then
		return
	end
	-- rise toward the open side (where the finder stood), not into the cave wall behind the rock
	local at = info.Position
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if typeof(info.FinderPosition) == "Vector3" then
		local toward = Vector3.new(info.FinderPosition.X - at.X, 0, info.FinderPosition.Z - at.Z)
		if toward.Magnitude > 1 then
			at += toward.Unit * math.min(4, toward.Magnitude * 0.5)
		end
	end
	burst(info.Position)
	local model, core, shine = buildDiamond(at)
	beam(at, (info.RegenerateIn or 15) - 3)
	cameraSwing(at, 4)
	-- rise, then hover and spin until the run resets
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not model.Parent then
			conn:Disconnect()
			return
		end
		local t = os.clock() - t0
		local rise = math.min(t / 1.2, 1)
		local y = 6 * (1 - (1 - rise) ^ 3) + math.sin(t * 2) * 0.4
		local cf = CFrame.new(at + Vector3.new(0, y, 0)) * CFrame.Angles(0, t * 1.5, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45))
		core.CFrame = cf
		shine.CFrame = cf
	end)
	Debris:AddItem(model, (info.RegenerateIn or 15) - 1)
end)
