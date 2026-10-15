-- StarterPlayerScripts.ZoneMood: Lighting is global, so tint the colour correction and fog per zone on the client
-- (Zone 2 mine cave is warmer). Zone bounds and moods come from ReplicatedStorage.BTW.Config.
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("BTW"):WaitForChild("Config"))

local player = Players.LocalPlayer
local cc = Lighting:WaitForChild("BaseColorCorrection")
local base = { tint = cc.TintColor, sat = cc.Saturation, fog = Lighting.FogColor }
local current

local function zoneAt(z)
	for _, zone in ipairs(Config.Zones) do
		if z <= zone.zMax and z > zone.zMin then return zone end
	end
end

local function apply(zone)
	local m = zone and zone.mood
	local info = TweenInfo.new(1.2)
	TweenService:Create(cc, info, {
		TintColor = m and Color3.fromHex(m.tint) or base.tint,
		Saturation = m and m.saturation or base.sat,
	}):Play()
	TweenService:Create(Lighting, info, { FogColor = m and Color3.fromHex(m.fogColor) or base.fog }):Play()
end

while true do
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root then
		local zone = zoneAt(root.Position.Z)
		if zone ~= current then
			current = zone
			apply(zone)
		end
	end
	task.wait(0.5)
end
