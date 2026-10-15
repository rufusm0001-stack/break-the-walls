-- StarterPlayerScripts.WorldSpin: client-only spinning (no network cost).
--   parts tagged "Spin"      spin about their own centre, 6 s per turn
--   models tagged "SpinSlow" turn about their pivot; seconds per turn from the SpinSeconds attribute

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local FAST = math.rad(60)
local parts, models = {}, {}

local function trackPart(p)
	parts[p] = p.CFrame
end
local function trackModel(m)
	models[m] = { pivot = m:GetPivot(), speed = (2 * math.pi) / (m:GetAttribute("SpinSeconds") or 40) }
end

for _, p in ipairs(CollectionService:GetTagged("Spin")) do
	trackPart(p)
end
for _, m in ipairs(CollectionService:GetTagged("SpinSlow")) do
	trackModel(m)
end
CollectionService:GetInstanceAddedSignal("Spin"):Connect(trackPart)
CollectionService:GetInstanceAddedSignal("SpinSlow"):Connect(trackModel)
CollectionService:GetInstanceRemovedSignal("Spin"):Connect(function(p)
	parts[p] = nil
end)
CollectionService:GetInstanceRemovedSignal("SpinSlow"):Connect(function(m)
	models[m] = nil
end)

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	local fast = (t * FAST) % (math.pi * 2)
	for p, cf in pairs(parts) do
		p.CFrame = CFrame.new(cf.Position) * CFrame.Angles(0, fast, 0) * cf.Rotation
	end
	for m, info in pairs(models) do
		local angle = (t * info.speed) % (math.pi * 2)
		m:PivotTo(CFrame.new(info.pivot.Position) * CFrame.Angles(0, angle, 0) * info.pivot.Rotation)
	end
end)
