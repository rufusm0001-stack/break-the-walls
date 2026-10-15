-- ServerScriptService.GameServer: the core loop, server-authoritative.
-- punch (cross pattern on wall cubes) -> loose cubes -> vacuum into storage -> deposit machine pays Value -> Money.
-- Also: leaderstats, DataStore saving (Studio-safe), and zone checkpoints when a wall has a passable hole.
-- Every number comes from ReplicatedStorage.BTW.Config.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local PhysicsService = game:GetService("PhysicsService")
local RS = game:GetService("ReplicatedStorage")

local BTW = RS:WaitForChild("BTW")
local Config = require(BTW.Config)
local WallGrid = require(BTW.WallGrid)
local World = workspace:WaitForChild("World")

-- Remotes --------------------------------------------------------------------------------
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
local function remote(name)
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotes
	return r
end
local PunchRE = remote("Punch") -- client -> (cube, normal)
local VacuumRE = remote("Vacuum") -- client -> (on, lookVector)
local EquipRE = remote("Equip") -- client -> (slot)
local DepositRE = remote("DepositPaid") -- server -> (amount, worldPos)
local ToastRE = remote("Toast") -- server -> (text, colorName)
local SettingsRE = remote("Settings") -- client -> ({ sensitivity, music, sfx })
remotes.Parent = BTW

-- Collision: loose cubes never shove players around ---------------------------------------
pcall(function()
	PhysicsService:RegisterCollisionGroup("Loose")
	PhysicsService:RegisterCollisionGroup("Players")
end)
PhysicsService:CollisionGroupSetCollidable("Loose", "Players", false)

-- Player data -----------------------------------------------------------------------------
local store
do
	local ok, ds = pcall(function()
		return DataStoreService:GetDataStore(Config.Save.store)
	end)
	store = ok and ds or nil
end
local data = {} -- player -> { money, checkpoint, storageCount, storageValue, settings, loaded, reserved }
local DEFAULT = { money = 0, checkpoint = 1, storageCount = 0, storageValue = 0 }

local function cleanSettings(t)
	local out = {}
	for k, spec in pairs(Config.Settings) do
		local v = type(t) == "table" and t[k]
		out[k] = (type(v) == "number" and v == v) and math.clamp(v, spec.min, spec.max) or spec.default
	end
	return out
end

local function fresh()
	local d = table.clone(DEFAULT)
	d.settings = cleanSettings(nil)
	return d
end

local function loadData(player)
	if not store then return fresh(), false end
	for attempt = 1, 3 do
		local ok, res = pcall(function()
			return store:GetAsync("u_" .. player.UserId)
		end)
		if ok then
			local d = fresh()
			if type(res) == "table" then
				for k in pairs(DEFAULT) do
					if type(res[k]) == "number" then d[k] = res[k] end
				end
				d.settings = cleanSettings(res.settings)
			end
			return d, true
		end
		if RunService:IsStudio() and tostring(res):find("access") then
			-- Studio with "Enable Studio Access to API Services" off: play without saving.
			print("[BTW] DataStore unavailable in this Studio session; progress won't save.")
			return fresh(), false
		end
		task.wait(attempt)
	end
	return fresh(), false -- don't save over data we failed to read
end

local function saveData(player)
	local d = data[player]
	if not (store and d and d.loaded) then return end
	local payload = {
		money = d.money, checkpoint = d.checkpoint, storageCount = d.storageCount, storageValue = d.storageValue,
		settings = d.settings,
	}
	local ok, err = pcall(function()
		store:UpdateAsync("u_" .. player.UserId, function()
			return payload
		end)
	end)
	if not ok then
		print("[BTW] save failed for " .. player.Name .. ": " .. tostring(err))
	end
end

local function pushStats(player)
	local d = data[player]
	if not d then return end
	local ls = player:FindFirstChild("leaderstats")
	if ls then ls.Money.Value = d.money end
	player:SetAttribute("StorageCount", d.storageCount)
	player:SetAttribute("StorageMax", Config.Storage.start)
	for k, v in pairs(d.settings) do
		player:SetAttribute("Set_" .. k, v)
	end
end

SettingsRE.OnServerEvent:Connect(function(player, t)
	local d = data[player]
	if not d or type(t) ~= "table" then return end
	d.settings = cleanSettings(t)
	for k, v in pairs(d.settings) do
		player:SetAttribute("Set_" .. k, v)
	end
end)

-- Checkpoints -----------------------------------------------------------------------------
local function zoneFolder(n)
	return World:FindFirstChild("Zone" .. n)
end
local function spawnOf(n)
	local z = zoneFolder(n)
	return z and z:FindFirstChild("Spawn_Zone" .. n)
end

local function zoneAt(pos)
	for _, z in ipairs(Config.Zones) do
		if pos.Z <= z.zMax and pos.Z > z.zMin then return z.id end
	end
	return nil
end

-- Wall cube index and hole tracking -------------------------------------------------------
local index = WallGrid.index(World)
local walls = {} -- zone id -> { cells = {{x,y}}, depths, xs, ys, open }
for _, z in ipairs(Config.Zones) do
	local folder = zoneFolder(z.id) and zoneFolder(z.id):FindFirstChild("BreakableWall")
	if folder then
		local xs, ys, ds = {}, {}, {}
		for _, c in ipairs(folder:GetChildren()) do
			if c:IsA("BasePart") then
				xs[math.round(c.Position.X)] = true
				ys[math.round(c.Position.Y)] = true
				ds[math.round(c.Position.Z)] = true
			end
		end
		local function sorted(t)
			local a = {}
			for k in pairs(t) do table.insert(a, k) end
			table.sort(a)
			return a
		end
		walls[z.id] = { folder = folder, xs = sorted(xs), ys = sorted(ys), ds = sorted(ds), open = false }
	end
end

local function cellOpen(w, x, y)
	for _, d in ipairs(w.ds) do
		if index[string.format("%d,%d,%d", x, y, d)] then return false end
	end
	return true
end

local function checkHole(zoneId)
	local w = walls[zoneId]
	if not w or w.open then return end
	local cp = Config.Checkpoint
	for i = 1, #w.xs - cp.holeW + 1 do
		for j = 1, math.min(cp.maxStartRow + 1, #w.ys - cp.holeH + 1) do
			local ok = true
			for a = 0, cp.holeW - 1 do
				for b = 0, cp.holeH - 1 do
					if not cellOpen(w, w.xs[i + a], w.ys[j + b]) then
						ok = false
						break
					end
				end
				if not ok then break end
			end
			if ok then
				w.open = true
				local nextSpawn = spawnOf(zoneId + 1)
				if nextSpawn then
					nextSpawn.Enabled = true
					ToastRE:FireAllClients("ZONE " .. (zoneId + 1) .. " IS OPEN!  CHECKPOINT UNLOCKED", "green")
				else
					ToastRE:FireAllClients("WALL BROKEN!  MORE ZONES COMING SOON", "green")
				end
				return
			end
		end
	end
end

-- Loose cubes -----------------------------------------------------------------------------
local looseFolder = Instance.new("Folder")
looseFolder.Name = "Loose"
looseFolder.Parent = workspace
local loose = {} -- ordered oldest -> newest
looseFolder.ChildRemoved:Connect(function(p) -- e.g. fell out of the world
	local i = table.find(loose, p)
	if i then table.remove(loose, i) end
end)

local function removeLoose(p)
	local i = table.find(loose, p)
	if i then table.remove(loose, i) end
	p:Destroy()
end

local function dropLoose(fromCube, normal)
	local pos = fromCube.Position
	local value = fromCube:GetAttribute("Value") or 1
	if #loose >= Config.Loose.maxCount then
		local best, bestD = nil, Config.Loose.mergeRadius
		for _, p in ipairs(loose) do
			local dd = (p.Position - pos).Magnitude
			if dd < bestD and not p:GetAttribute("SuckedBy") then best, bestD = p, dd end
		end
		if best then
			best:SetAttribute("Count", best:GetAttribute("Count") + 1)
			best:SetAttribute("Value", best:GetAttribute("Value") + value)
			return
		end
		for _, old in ipairs(loose) do -- recycle the oldest one that isn't mid-flight
			if not old:GetAttribute("SuckedBy") then
				removeLoose(old)
				break
			end
		end
	end
	local s = Config.Loose.size
	local p = Instance.new("Part")
	p.Name = "LooseCube"
	p.Size = Vector3.new(s, s, s)
	p.Color = fromCube:GetAttribute("OriginalColor") or fromCube.Color
	p.Material = Enum.Material.Plastic
	p.TopSurface = Enum.SurfaceType.Studs
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CollisionGroup = "Loose"
	p.CFrame = CFrame.new(pos + normal * 0.6) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
	p:SetAttribute("Count", 1)
	p:SetAttribute("Value", value)
	p.Parent = looseFolder
	p:SetNetworkOwner(nil)
	p.AssemblyLinearVelocity = normal * (6 + math.random() * 6) + Vector3.new(math.random() * 4 - 2, 6, math.random() * 4 - 2)
	table.insert(loose, p)
end

-- Punch -----------------------------------------------------------------------------------
local lastPunch = {}
local DARK = Color3.fromHex("3A3F4B")

local function damageCube(cube, amount, normal, zonesHit)
	local hits = cube:GetAttribute("Hits")
	local dmg = (cube:GetAttribute("Damage") or 0) + amount
	if not cube:GetAttribute("OriginalColor") then
		cube:SetAttribute("OriginalColor", cube.Color)
	end
	if dmg >= hits - 1e-6 then
		zonesHit[cube:GetAttribute("Zone") or 0] = true
		dropLoose(cube, normal)
		index[WallGrid.key(cube.Position)] = nil
		cube:Destroy()
	else
		cube:SetAttribute("Damage", dmg)
		cube.Color = cube:GetAttribute("OriginalColor"):Lerp(DARK, 0.45 * dmg / hits)
	end
end

PunchRE.OnServerEvent:Connect(function(player, cube, normal)
	if player:GetAttribute("Equipped") ~= Config.Fists.slot then return end
	if typeof(normal) ~= "Vector3" or normal.Magnitude < 0.5 or normal.Magnitude ~= normal.Magnitude then return end
	if not WallGrid.isBreakable(cube) or index[WallGrid.key(cube.Position)] ~= cube then return end
	local now = os.clock()
	if now - (lastPunch[player] or 0) < Config.Fists.cooldown * 0.85 then return end
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not head or not hum or hum.Health <= 0 then return end
	normal = WallGrid.snap(normal)
	local toHead = head.Position - cube.Position
	if toHead.Magnitude > Config.Fists.range + 3 then return end -- range from the cube centre, plus slack
	if toHead:Dot(normal) <= 0 then return end -- the face must point at the player
	-- line of sight: nothing solid between the head and the cube (neighbouring wall cubes are fine)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char, looseFolder }
	local res = workspace:Raycast(head.Position, cube.Position - head.Position, params)
	if res and res.Instance ~= cube then
		if not (WallGrid.isBreakable(res.Instance) and (res.Instance.Position - cube.Position).Magnitude < 3) then
			return
		end
	end
	lastPunch[player] = now
	local zonesHit = {}
	for _, cell in ipairs(WallGrid.cells(cube.Position, normal, Config.Fists.pattern, Config.Fists.ringDamage)) do
		local c = index[WallGrid.key(cell.pos)]
		if c then
			damageCube(c, Config.Fists.damage * cell.mul, normal, zonesHit)
		end
	end
	for z in pairs(zonesHit) do
		checkHole(z)
	end
end)

-- Equip -----------------------------------------------------------------------------------
local vac = {} -- player -> { on, look }
EquipRE.OnServerEvent:Connect(function(player, slot)
	if slot ~= Config.Fists.slot and slot ~= Config.Vacuum.slot then return end
	player:SetAttribute("Equipped", slot)
	vac[player] = nil
end)

VacuumRE.OnServerEvent:Connect(function(player, on, look)
	if type(on) ~= "boolean" then return end
	if on and (typeof(look) ~= "Vector3" or look.Magnitude < 0.5 or look.Magnitude ~= look.Magnitude) then return end
	vac[player] = on and { look = look.Unit } or nil
end)

-- Vacuum + deposit loop -------------------------------------------------------------------
local depositZones = {}
for _, z in ipairs(Config.Zones) do
	local zf = zoneFolder(z.id)
	local m = zf and zf:FindFirstChild("DepositMachine_Placeholder", true)
	local dz = m and m:FindFirstChild("Function") and m.Function:FindFirstChild("DepositZone")
	if dz then table.insert(depositZones, dz) end
end

local function inZone(part, pos)
	local rel = part.CFrame:PointToObjectSpace(pos)
	local h = part.Size / 2
	return math.abs(rel.X) <= h.X and math.abs(rel.Y) <= h.Y + 3 and math.abs(rel.Z) <= h.Z
end

-- Claim a loose cube for a player's vacuum: it stops being physics, every client flies it into the nozzle,
-- and it is banked when the flight ends. Storage space is reserved at claim time.
local function claim(player, d, p, dist)
	local free = Config.Storage.start - d.storageCount - (d.reserved or 0)
	if free <= 0 then return false end
	local count, value = p:GetAttribute("Count"), p:GetAttribute("Value")
	local take = math.min(count, free)
	local takeValue = take == count and value or math.floor(value * take / count + 0.5)
	if take < count then -- split: the rest stays on the floor as its own cube
		p:SetAttribute("Count", count - take)
		p:SetAttribute("Value", value - takeValue)
		local rest = p
		p = rest:Clone()
		p:SetAttribute("Count", take)
		p:SetAttribute("Value", takeValue)
		p.Parent = looseFolder
		table.insert(loose, p)
	end
	local V = Config.Vacuum
	local dur = math.clamp(dist / V.pullSpeed, V.minFlight, V.maxFlight)
	d.reserved = (d.reserved or 0) + take
	p.Anchored = true
	p.CanCollide = false
	p:SetAttribute("SuckDur", dur)
	p:SetAttribute("SuckStart", workspace:GetServerTimeNow())
	p:SetAttribute("SuckedBy", player.UserId)
	task.delay(dur, function()
		d.reserved -= take
		if p.Parent then removeLoose(p) end
		if data[player] == d then
			d.storageCount = math.min(Config.Storage.start, d.storageCount + take)
			d.storageValue += takeValue
			pushStats(player)
		end
	end)
	return true
end

local vacAcc, depAcc = 0, 0
RunService.Heartbeat:Connect(function(dt)
	vacAcc += dt
	if vacAcc >= Config.Vacuum.tick then
		vacAcc = 0
		local V = Config.Vacuum
		for player, v in pairs(vac) do
			local d = data[player]
			local char = player.Character
			local head = char and char:FindFirstChild("Head")
			if d and head and player:GetAttribute("Equipped") == V.slot
				and d.storageCount + (d.reserved or 0) < Config.Storage.start then
				local origin = head.Position
				for i = #loose, 1, -1 do
					local p = loose[i]
					if p and p.Parent and not p:GetAttribute("SuckedBy") then
						local off = p.Position - origin
						local dist = off.Magnitude
						if dist <= V.collectRadius or (dist <= V.range and off.Unit:Dot(v.look) >= V.coneDot) then
							if not claim(player, d, p, dist) then break end
						end
					end
				end
			end
		end
	end

	depAcc += dt
	if depAcc >= Config.Deposit.tick then
		depAcc = 0
		for player, d in pairs(data) do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root and d.storageCount > 0 then
				for _, dz in ipairs(depositZones) do
					if inZone(dz, root.Position) then
						local batch = math.min(Config.Deposit.batch, d.storageCount)
						local pay = batch == d.storageCount and d.storageValue
							or math.floor(d.storageValue * batch / d.storageCount + 0.5)
						d.storageCount -= batch
						d.storageValue -= pay
						d.money += pay
						pushStats(player)
						DepositRE:FireClient(player, pay, dz.Position)
						break
					end
				end
			end
		end
	end
end)

-- Checkpoint progress: entering an open zone saves it as your respawn ---------------------
task.spawn(function()
	while true do
		task.wait(0.5)
		for player, d in pairs(data) do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local z = root and zoneAt(root.Position)
			local sp = z and spawnOf(z)
			if z and z > d.checkpoint and sp and sp.Enabled then
				d.checkpoint = z
				player.RespawnLocation = sp
				ToastRE:FireClient(player, "CHECKPOINT: ZONE " .. z, "green")
			end
		end
	end
end)

-- Join / leave ----------------------------------------------------------------------------
Players.CharacterAutoLoads = false

local function onCharacter(player, char)
	for _, p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") then p.CollisionGroup = "Players" end
	end
	char.DescendantAdded:Connect(function(p)
		if p:IsA("BasePart") then p.CollisionGroup = "Players" end
	end)
	local hum = char:WaitForChild("Humanoid")
	hum.Died:Connect(function()
		task.wait(Players.RespawnTime)
		if player.Parent then player:LoadCharacter() end
	end)
end

local function onJoin(player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Parent = ls
	ls.Parent = player
	player:SetAttribute("Equipped", Config.Fists.slot)

	local d, loaded = loadData(player)
	if not player.Parent then return end
	d.loaded = loaded
	d.checkpoint = math.clamp(math.floor(d.checkpoint), 1, #Config.Zones)
	data[player] = d
	pushStats(player)

	local sp = spawnOf(d.checkpoint) or spawnOf(1)
	sp.Enabled = true
	player.RespawnLocation = sp
	player.CharacterAdded:Connect(function(char)
		onCharacter(player, char)
	end)
	player:LoadCharacter()
end

Players.PlayerAdded:Connect(onJoin)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(onJoin, p)
end

Players.PlayerRemoving:Connect(function(player)
	saveData(player)
	data[player] = nil
	vac[player] = nil
	lastPunch[player] = nil
end)

task.spawn(function()
	while true do
		task.wait(Config.Save.autosave)
		for player in pairs(data) do
			task.spawn(saveData, player)
		end
	end
end)

game:BindToClose(function()
	local pending = 0
	for player in pairs(data) do
		pending += 1
		task.spawn(function()
			saveData(player)
			pending -= 1
		end)
	end
	local t = os.clock()
	while pending > 0 and os.clock() - t < 20 do
		task.wait(0.1)
	end
end)
