-- StarterPlayerScripts.ToolsClient: input for the two tools, the punch grid preview and hit prediction.
-- Slot 1 Fists: click / hold LMB to punch the cube under the crosshair (cross pattern). The client predicts the
-- flash, shake and break; the server (GameServer) validates range, cooldown and line of sight, then applies it.
-- Slot 2 Vacuum: hold LMB to pull loose cubes into storage.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local RS = game:GetService("ReplicatedStorage")

local BTW = RS:WaitForChild("BTW")
local Config = require(BTW.Config)
local WallGrid = require(BTW.WallGrid)
local State = require(BTW.ClientState)
local Remotes = BTW:WaitForChild("Remotes")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local World = workspace:WaitForChild("World")
local index = WallGrid.index(World)

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

local ORANGE = Color3.fromHex("FF8A2B")
local WHITE = Color3.fromHex("F2F4F8")
local OUTLINE = Color3.fromHex("1E1E24")

-- Grid preview: a pool of thin cells laid on the face under the crosshair ----------------
local previewFolder = Instance.new("Folder")
previewFolder.Name = "PunchPreview"
previewFolder.Parent = camera
local maxCells = 0
for _, p in pairs(Config.Patterns) do
	maxCells = math.max(maxCells, #p)
end
local pool = {}
for i = 1, maxCells do
	local p = Instance.new("Part")
	p.Name = "Cell"
	p.Size = Vector3.new(Config.CUBE_SIZE - 0.04, Config.CUBE_SIZE - 0.04, 0.05)
	p.Transparency = 1
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 60
	sg.LightInfluence = 0
	sg.Parent = p
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, -8, 1, -8)
	f.Position = UDim2.fromOffset(4, 4)
	f.BackgroundTransparency = 0.82
	f.Parent = sg
	local st = Instance.new("UIStroke")
	st.Thickness = 5
	st.Parent = f
	p.Parent = previewFolder
	pool[i] = { part = p, frame = f, stroke = st }
end

local function hidePreview()
	for _, c in ipairs(pool) do
		c.part.Parent = nil
	end
end

-- Aim -----------------------------------------------------------------------------------
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function aim()
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	if not head then return nil end
	local filter = { char, camera, previewFolder }
	local looseF = workspace:FindFirstChild("Loose")
	if looseF then table.insert(filter, looseF) end
	rayParams.FilterDescendantsInstances = filter
	local cf = camera.CFrame
	local res = workspace:Raycast(cf.Position, cf.LookVector * (Config.Fists.range + 4), rayParams)
	if not res or not WallGrid.isBreakable(res.Instance) then return nil end
	if (head.Position - res.Instance.Position).Magnitude > Config.Fists.range + 2.5 then return nil end
	local normal = WallGrid.snap(res.Normal)
	return res.Instance, normal
end

-- Prediction ----------------------------------------------------------------------------
local predictedBroken = {} -- cube -> true while waiting for the server

local function flash(cube)
	local h = Instance.new("Highlight")
	h.Adornee = cube
	h.FillColor = WHITE
	h.FillTransparency = 0.35
	h.OutlineTransparency = 1
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Parent = camera
	TweenService:Create(h, TweenInfo.new(0.16), { FillTransparency = 1 }):Play()
	task.delay(0.18, function()
		h:Destroy()
	end)
	local home = cube.CFrame
	task.spawn(function()
		for i = 1, 4 do
			if not cube.Parent then return end
			local a = 0.12 * (1 - i / 5)
			cube.CFrame = home * CFrame.new((math.random() - 0.5) * a, (math.random() - 0.5) * a, (math.random() - 0.5) * a)
			task.wait(0.03)
		end
		if cube.Parent then cube.CFrame = home end
	end)
end

local function burst(cube, normal)
	for i = 1, 4 do
		local s = 0.35 + math.random() * 0.3
		local p = Instance.new("Part")
		p.Size = Vector3.new(s, s, s)
		p.Color = cube:GetAttribute("OriginalColor") or cube.Color
		p.Material = Enum.Material.Plastic
		p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = false, false, false, false
		p.CFrame = cube.CFrame * CFrame.new((math.random() - 0.5) * 1.4, (math.random() - 0.5) * 1.4, 0)
		p.AssemblyLinearVelocity = normal * (8 + math.random() * 8) + Vector3.new(math.random() * 8 - 4, 8, math.random() * 8 - 4)
		p.Parent = camera
		TweenService:Create(p, TweenInfo.new(0.5), { Transparency = 1, Size = Vector3.new(0.1, 0.1, 0.1) }):Play()
		task.delay(0.5, function()
			p:Destroy()
		end)
	end
end

local function predictBreak(cube, normal)
	predictedBroken[cube] = true
	local oldT = cube.LocalTransparencyModifier
	cube.LocalTransparencyModifier = 1
	cube.CanCollide = false
	burst(cube, normal)
	task.delay(1, function() -- the server said no: put it back
		predictedBroken[cube] = nil
		if cube.Parent then
			cube.LocalTransparencyModifier = oldT
			cube.CanCollide = true
		end
	end)
end

local lastPunch = 0
local function punch()
	local now = os.clock()
	if now - lastPunch < Config.Fists.cooldown then return end
	lastPunch = now
	State.Jab:Fire()
	local cube, normal = aim()
	if not cube or predictedBroken[cube] then return end
	for _, cell in ipairs(WallGrid.cells(cube.Position, normal, Config.Fists.pattern, Config.Fists.ringDamage)) do
		local c = index[WallGrid.key(cell.pos)]
		if c and not predictedBroken[c] then
			local dmg = (c:GetAttribute("Damage") or 0) + Config.Fists.damage * cell.mul
			if dmg >= c:GetAttribute("Hits") - 1e-6 then
				predictBreak(c, normal)
			else
				flash(c)
			end
		end
	end
	Remotes.Punch:FireServer(cube, normal)
end

-- Input ---------------------------------------------------------------------------------
local holding = false
local lastVacSend = 0

local function setVacuum(on)
	if State.vacuuming == on then return end
	State.vacuuming = on
	Remotes.Vacuum:FireServer(on, camera.CFrame.LookVector)
end

State.EquipChanged.Event:Connect(function(slot)
	Remotes.Equip:FireServer(slot)
	hidePreview()
	if slot ~= Config.Vacuum.slot then
		Remotes.Vacuum:FireServer(false)
	elseif holding then
		setVacuum(true)
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.One then
		State.equip(Config.Fists.slot)
	elseif input.KeyCode == Enum.KeyCode.Two then
		State.equip(Config.Vacuum.slot)
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		holding = true
		if State.equipped == Config.Fists.slot then
			punch()
		else
			setVacuum(true)
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		holding = false
		setVacuum(false)
	end
end)

RunService.RenderStepped:Connect(function()
	if State.equipped == Config.Fists.slot then
		if holding then punch() end
		local cube, normal = aim()
		if not cube then
			hidePreview()
		else
			local cells = WallGrid.cells(cube.Position, normal, Config.Fists.pattern, Config.Fists.ringDamage)
			for i, c in ipairs(pool) do
				local cell = cells[i]
				local target = cell and index[WallGrid.key(cell.pos)]
				if target and not predictedBroken[target] then
					local face = cell.pos + normal * (Config.CUBE_SIZE / 2 + 0.04)
					c.part.CFrame = CFrame.lookAt(face, face + normal, math.abs(normal.Y) > 0.5 and Vector3.zAxis or Vector3.yAxis)
					local col = cell.ring and WHITE or ORANGE
					c.stroke.Color = col
					c.frame.BackgroundColor3 = col
					c.part.Parent = previewFolder
				else
					c.part.Parent = nil
				end
			end
		end
	elseif State.vacuuming and os.clock() - lastVacSend > 0.15 then
		lastVacSend = os.clock()
		Remotes.Vacuum:FireServer(true, camera.CFrame.LookVector)
	end
end)

player.CharacterAdded:Connect(function()
	holding = false
	State.vacuuming = false
end)
