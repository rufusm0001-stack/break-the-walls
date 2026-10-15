-- StarterPlayerScripts.Audio: background music playlist and every sound effect, all ids from BTW.Sounds.
-- Volumes follow the player's settings (Set_music, Set_sfx). Effects are fired through ClientState.Sfx.
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")

local BTW = RS:WaitForChild("BTW")
local Config = require(BTW.Config)
local State = require(BTW.ClientState)
local Sounds = require(BTW.Sounds)
local Remotes = BTW:WaitForChild("Remotes")
local player = Players.LocalPlayer

local musicGroup = Instance.new("SoundGroup")
musicGroup.Name = "BTW_Music"
musicGroup.Parent = SoundService
local sfxGroup = Instance.new("SoundGroup")
sfxGroup.Name = "BTW_SFX"
sfxGroup.Parent = SoundService

local function applyVolumes()
	musicGroup.Volume = player:GetAttribute("Set_music") or Config.Settings.music.default
	sfxGroup.Volume = player:GetAttribute("Set_sfx") or Config.Settings.sfx.default
end
player:GetAttributeChangedSignal("Set_music"):Connect(applyVolumes)
player:GetAttributeChangedSignal("Set_sfx"):Connect(applyVolumes)
applyVolumes()

-- one template Sound per effect; each play is a short-lived clone so overlaps never cut each other off
local templates = {}
for name, def in pairs(Sounds.sfx) do
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = def.id
	s.Volume = def.volume
	s.SoundGroup = sfxGroup
	s.Parent = SoundService
	templates[name] = s
end

State.Sfx.Event:Connect(function(name)
	local t = templates[name]
	if not t then return end
	local s = t:Clone()
	s.PlaybackSpeed = 0.92 + math.random() * 0.16
	s.Parent = SoundService
	s:Play()
	s.Ended:Once(function()
		s:Destroy()
	end)
	task.delay(4, function()
		if s.Parent then s:Destroy() end
	end)
end)

Remotes:WaitForChild("DepositPaid").OnClientEvent:Connect(function()
	State.Sfx:Fire("cash")
end)

-- vacuum suction loop: fades in while sucking
local suck = templates.suck:Clone()
suck.Name = "SuckLoop"
suck.Looped = true
suck.Volume = 0
suck.Parent = SoundService
local target = Sounds.sfx.suck.volume
RunService.RenderStepped:Connect(function(dt)
	local on = State.vacuuming and State.equipped == 2
	if on and not suck.IsPlaying then suck:Play() end
	suck.Volume += ((on and target or 0) - suck.Volume) * math.min(1, dt * 10)
	suck.PlaybackSpeed = 1.15
	if not on and suck.IsPlaying and suck.Volume < 0.01 then suck:Stop() end
end)

-- music: shuffled playlist, one track after another
local music = Instance.new("Sound")
music.Name = "Music"
music.Volume = 0.5
music.SoundGroup = musicGroup
music.Parent = SoundService
local order = table.clone(Sounds.music)
for i = #order, 2, -1 do
	local j = math.random(i)
	order[i], order[j] = order[j], order[i]
end
local idx = 0
local function nextTrack()
	idx = idx % #order + 1
	music.SoundId = order[idx]
	music.TimePosition = 0
	music:Play()
end
music.Ended:Connect(nextTrack)
task.delay(1, nextTrack)
