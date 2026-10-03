local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local EffectsConfig = require(Shared.Config.Effects)
local Settings = require(script.Parent.Settings)

local Audio = {}

local sounds = ReplicatedStorage:WaitForChild(Names.Effects.Folder):WaitForChild(Names.Effects.Sounds)
local recent = {}
local groupTimes = {}
local lastPlayed = {}
local anchor

local function template(name)
	local sound = sounds:FindFirstChild(name)
	if not sound or sound.SoundId == "" then
		return nil
	end
	return sound
end

local function allowed(name)
	local def = EffectsConfig.Sounds[name]
	local now = os.clock()
	if now - (lastPlayed[name] or -math.huge) < EffectsConfig.SoundRepeatGap then
		return false
	end
	lastPlayed[name] = now
	local group = def and def.Group
	if group then
		if now - (groupTimes[group] or -math.huge) < EffectsConfig.SoundGroupGap then
			return false
		end
		groupTimes[group] = now
	end
	local limit = def and def.MaxPerSecond
	if not limit then
		return true
	end
	local list = recent[name] or {}
	recent[name] = list
	while list[1] and now - list[1] > 1 do
		table.remove(list, 1)
	end
	if #list >= limit then
		return false
	end
	table.insert(list, now)
	return true
end

function Audio.Play(name, pitch, volumeScale)
	if not Settings:Get("Sfx") or not allowed(name) then
		return nil
	end
	local source = template(name)
	if not source then
		return nil
	end
	local sound = source:Clone()
	sound.PlaybackSpeed = pitch or 1
	sound.Volume = source.Volume * (volumeScale or 1)
	sound.Parent = SoundService
	sound:Play()
	Debris:AddItem(sound, math.max(sound.TimeLength, 2) / sound.PlaybackSpeed + 0.5)
	return sound
end

function Audio.PlayAt(name, position, pitch)
	if not Settings:Get("Sfx") or not allowed(name) then
		return nil
	end
	local source = template(name)
	if not source then
		return nil
	end
	if not anchor or not anchor.Parent then
		anchor = Instance.new("Part")
		anchor.Name = "SoundAnchor"
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanQuery = false
		anchor.CanTouch = false
		anchor.Transparency = 1
		anchor.Size = Vector3.one
		anchor.Parent = Workspace
	end
	local attachment = Instance.new("Attachment")
	attachment.WorldPosition = position
	attachment.Parent = anchor
	local sound = source:Clone()
	sound.PlaybackSpeed = pitch or 1
	sound.Parent = attachment
	sound:Play()
	Debris:AddItem(attachment, math.max(sound.TimeLength, 2) / sound.PlaybackSpeed + 0.5)
	return sound
end

function Audio.Track(name)
	local source = template(name)
	if not source then
		return nil
	end
	local sound = source:Clone()
	sound.Looped = false
	sound.Parent = SoundService
	return sound
end

function Audio.Loop(name)
	local source = template(name)
	if not source then
		return nil
	end
	local sound = source:Clone()
	sound.Looped = true
	sound.Parent = SoundService
	return sound
end

return Audio
