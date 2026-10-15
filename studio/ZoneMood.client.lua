-- StarterPlayerScripts.ZoneMood: per-corridor colour mood on the client. Lighting is global, so the
-- mood follows the local player: inside BEST HORROR the scene tints ember-dark with a close fog.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local S, HALF_W = 92, 36 -- corridor start and half width incl. walls (studio/BuildHub.lua)
local KEYS = { "TOP_PLAYED", "RECOMMENDED", "HORROR", "OBBYS", "NEW_GAMES" }
local DIRS = {}
for i = 1, #KEYS do
	local a = math.rad(90 - 72 * (i - 1))
	DIRS[i] = Vector3.new(math.sin(a), 0, -math.cos(a))
end

local DEFAULT = { tint = Color3.new(1, 1, 1), bright = 0, sat = 0.15, fog = Color3.fromRGB(200, 170, 250), fogEnd = 2500 }
local MOODS = {
	HORROR = { tint = Color3.fromRGB(255, 196, 170), bright = -0.08, sat = 0.25, fog = Color3.fromRGB(70, 30, 45), fogEnd = 320 },
}

local function zoneAt(pos)
	local flat = Vector3.new(pos.X, 0, pos.Z)
	for i, dir in ipairs(DIRS) do
		local d = flat:Dot(dir)
		if d > S - 4 and (flat - dir * d).Magnitude < HALF_W then
			return KEYS[i]
		end
	end
	return nil
end

local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
while not cc do
	Lighting.ChildAdded:Wait()
	cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
end

local current = false
local info = TweenInfo.new(1.2, Enum.EasingStyle.Sine)
while true do
	local char = Players.LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local zone = root and zoneAt(root.Position)
	if zone ~= current then
		current = zone
		local m = MOODS[zone] or DEFAULT
		TweenService:Create(cc, info, { TintColor = m.tint, Brightness = m.bright, Saturation = m.sat }):Play()
		TweenService:Create(Lighting, info, { FogColor = m.fog, FogEnd = m.fogEnd }):Play()
	end
	task.wait(0.3)
end
