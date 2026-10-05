local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PropsConfig = require(Shared.Config.Props)
local EffectsConfig = require(Shared.Config.Effects)
local Names = require(Shared.Config.Names)

local Settings = require(script.Parent.Parent.Util.Settings)

local AmbientController = {
	Wobblers = {},
	Wanderers = {},
	Clouds = {},
	Swayers = {},
	Streaks = {},
	Foams = {},
	Rigs = {},
	CartParts = {},
	Bottles = {},
	Posed = {},
	Lookers = {},
	Rattles = {},
	Belts = {},
}

local WIND = EffectsConfig.Wind
local WATER = EffectsConfig.Water
local RIG = EffectsConfig.GooseRig
local CART = EffectsConfig.QuarryCart
local POTION = EffectsConfig.Potions
local LOOK = EffectsConfig.NPCLook
local POSED = PropsConfig.PosedRig
local RATTLE = EffectsConfig.Rattle
local BELT = EffectsConfig.Belt
local MapConfigScenery = require(Shared.Config.Map).Scenery
local EffectController
local lowEnd = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local windDirection = WIND.Direction.Unit
local swayAxis = Vector3.new(windDirection.Z, 0, -windDirection.X)
local templates
local leaves
local lastStreak = 0

local CULL = 260
local camera = Workspace.CurrentCamera
local random = Random.new()

local function angles(list)
	return list and CFrame.Angles(math.rad(list[1]), math.rad(list[2]), math.rad(list[3])) or CFrame.identity
end

function AmbientController:Init(modules)
	EffectController = modules.EffectController
end

function AmbientController:Start()
	if lowEnd then
		local Lighting = game:GetService("Lighting")
		for _, name in { "SceneryDepth" } do
			local effect = Lighting:FindFirstChild(name)
			if effect then
				effect.Enabled = false
			end
		end
		local rays = Lighting:FindFirstChildOfClass("SunRaysEffect")
		if rays then
			rays.Enabled = false
		end
	end
	local function addWobble(model)
		if model:IsA("Model") then
			self.Wobblers[model] = { Base = model:GetPivot(), Phase = random:NextNumber(0, math.pi * 2) }
		end
	end
	local function addWander(model)
		if model:IsA("Model") then
			local pivot = model:GetPivot()
			self.Wanderers[model] = {
				Position = pivot.Position,
				Facing = pivot.Rotation,
				Home = model:GetAttribute("Home") or pivot.Position,
				Spread = model:GetAttribute("Spread") or 10,
				Speed = model:GetAttribute("Speed") or 4,
				Yaw = math.rad(model:GetAttribute("Yaw") or 0),
				Target = nil,
				PauseUntil = os.clock() + random:NextNumber(0, 3),
				Phase = random:NextNumber(0, math.pi * 2),
			}
		end
	end
	for _, model in CollectionService:GetTagged("Wobble") do
		addWobble(model)
	end
	for _, model in CollectionService:GetTagged("Wander") do
		addWander(model)
	end
	local function addPosed(npc)
		local names = {}
		for name in POSED.Pose do
			names[name] = true
		end
		for name in POSED.Motion do
			names[name] = true
		end
		for _, gesture in POSED.Gestures.List do
			for name in gesture.Pose do
				names[name] = true
			end
		end
		local joints = {}
		for name in names do
			local joint = npc:FindFirstChild(name, true)
			local pose = angles(POSED.Pose[name])
			if joint and joint:IsA("AnimationConstraint") then
				joints[name] = { Joint = joint, Rest = CFrame.identity, Base = pose }
			elseif joint and joint:IsA("Motor6D") then
				joints[name] = { Joint = joint, Rest = joint.C0 * pose:Inverse(), Base = joint.C0, Motor = true }
			end
		end
		local every = POSED.Gestures.Every
		self.Posed[npc] = { Joints = joints, Phase = random:NextNumber(0, math.pi * 2), NextGesture = os.clock() + random:NextNumber(every[1], every[2]) }
	end
	local function addLook(npc)
		local root = npc:FindFirstChild("HumanoidRootPart")
		local head = npc:FindFirstChild("Head")
		if not root or not head or head.Transparency >= 1 then
			return
		end
		local joints = {}
		for _, name in { "Neck", "Waist" } do
			local joint = npc:FindFirstChild(name, true)
			if joint and joint:IsA("AnimationConstraint") and joint.Attachment0 then
				joints[name] = { Joint = joint, Attachment = joint.Attachment0, Base = joint.Attachment0.CFrame }
			elseif joint and joint:IsA("Motor6D") then
				joints[name] = { Joint = joint, Base = joint.C0 }
			end
		end
		if joints.Neck then
			self.Lookers[npc] = { Root = root, Head = head, Joints = joints, Offsets = {}, Posed = npc:GetAttribute("Posed") == true, Yaw = 0, Pitch = 0 }
		end
	end
	local function addNPC(npc)
		addLook(npc)
		if npc:GetAttribute("Posed") then
			addPosed(npc)
			return
		end
		local humanoid = npc:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and (humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator", 5))
		if not animator or PropsConfig.NPCIdleAnimation == "" then
			return
		end
		local animation = Instance.new("Animation")
		animation.AnimationId = PropsConfig.NPCIdleAnimation
		local ok, track = pcall(animator.LoadAnimation, animator, animation)
		if ok and track then
			track.Looped = true
			track:Play()
		end
		local emotes = PropsConfig.NPCEmotes and PropsConfig.NPCEmotes[npc.Name]
		if not emotes then
			return
		end
		local tracks = {}
		for _, id in emotes.Emotes do
			local emote = Instance.new("Animation")
			emote.AnimationId = id
			local loaded, emoteTrack = pcall(animator.LoadAnimation, animator, emote)
			if loaded and emoteTrack then
				emoteTrack.Looped = false
				emoteTrack.Priority = Enum.AnimationPriority.Action
				table.insert(tracks, emoteTrack)
			end
		end
		task.spawn(function()
			while npc.Parent and #tracks > 0 do
				task.wait(random:NextNumber(emotes.Every[1], emotes.Every[2]))
				if npc.Parent and (npc:GetPivot().Position - camera.CFrame.Position).Magnitude < CULL then
					local pick = tracks[random:NextInteger(1, #tracks)]
					pick:Play(0.25)
					task.wait(math.max(pick.Length, 1))
				end
			end
		end)
	end
	for _, npc in CollectionService:GetTagged("NPC") do
		task.spawn(addNPC, npc)
	end
	CollectionService:GetInstanceAddedSignal("NPC"):Connect(addNPC)
	CollectionService:GetInstanceAddedSignal("Wobble"):Connect(addWobble)
	CollectionService:GetInstanceAddedSignal("Wander"):Connect(addWander)
	local function addCloud(model)
		if model:IsA("Model") then
			self.Clouds[model] = { Base = model:GetPivot(), Drift = model:GetAttribute("Drift") or 2, Phase = random:NextNumber(0, math.pi * 2) }
		end
	end
	for _, model in CollectionService:GetTagged("Cloud") do
		addCloud(model)
	end
	CollectionService:GetInstanceAddedSignal("Cloud"):Connect(addCloud)
	local function addSway(model)
		if model:IsA("Model") then
			local base = model:GetPivot()
			local _, size = model:GetBoundingBox()
			local leaves
			if model:GetAttribute("SwayLeaves") then
				leaves = { Parts = {} }
				local lowest = math.huge
				for _, part in model:GetChildren() do
					local role = part:GetAttribute("Role")
					if part:IsA("BasePart") and role and role:find("^Leaf") then
						table.insert(leaves.Parts, { Part = part, Base = part.CFrame, Light = role == "LeafLight" })
						lowest = math.min(lowest, part.Position.Y - part.Size.Y / 2)
					end
				end
				leaves.Pivot = CFrame.new(base.Position.X, lowest, base.Position.Z)
			end
			self.Swayers[model] = {
				Base = base,
				Amp = math.rad(model:GetAttribute("Sway") or 2),
				Phase = (base.Position.X + base.Position.Z) * 0.025 + random:NextNumber(0, 0.6),
				Speed = WIND.SwaySpeed * random:NextNumber(0.85, 1.15),
				Small = size.Y < WIND.SmallSize,
				Leaves = leaves,
				Gust = model:GetAttribute("Gust") and { At = -math.huge, Next = os.clock() + random:NextNumber(WIND.Gust.Every[1], WIND.Gust.Every[2]) } or nil,
			}
		end
	end
	for _, model in CollectionService:GetTagged("Sway") do
		addSway(model)
	end
	CollectionService:GetInstanceAddedSignal("Sway"):Connect(addSway)
	self.Ripples = {}
	local function addRipple(part)
		if part:IsA("BasePart") then
			self.Ripples[part] = { Size = part.Size, Phase = part:GetAttribute("Phase") or 0, Sprite = part:FindFirstChildOfClass("Decal") }
		end
	end
	for _, part in CollectionService:GetTagged("Ripple") do
		addRipple(part)
	end
	CollectionService:GetInstanceAddedSignal("Ripple"):Connect(addRipple)
	local function addFoam(part)
		local sprite = part:IsA("BasePart") and part:FindFirstChildOfClass("Decal")
		if sprite then
			self.Foams[part] = { Base = part.CFrame, Phase = part:GetAttribute("Phase") or 0, Sprite = sprite }
		end
	end
	for _, part in CollectionService:GetTagged("Foam") do
		addFoam(part)
	end
	CollectionService:GetInstanceAddedSignal("Foam"):Connect(addFoam)
	local function addRig(part)
		if part:IsA("BasePart") then
			self.Rigs[part] = { Part = part, Phase = random:NextNumber(0, math.pi * 2), FlapAt = -math.huge, NextFlap = os.clock() + random:NextNumber(RIG.Flap.Every[1], RIG.Flap.Every[2]) }
		end
	end
	for _, part in CollectionService:GetTagged(RIG.Tag) do
		addRig(part)
	end
	CollectionService:GetInstanceAddedSignal(RIG.Tag):Connect(addRig)
	self.Cart = { Offset = 0, From = 0, To = 0, Start = 0, Next = os.clock() + random:NextNumber(CART.Every[1], CART.Every[2]) }
	local function addCartPart(part)
		if part:IsA("BasePart") then
			self.CartParts[part] = part.CFrame - CART.Axis * self.Cart.Offset
		end
	end
	for _, part in CollectionService:GetTagged(CART.Tag) do
		addCartPart(part)
	end
	CollectionService:GetInstanceAddedSignal(CART.Tag):Connect(addCartPart)
	self.PotionShow = { Next = os.clock() + random:NextNumber(POTION.Every[1], POTION.Every[2]) }
	local function addBottlePart(part)
		if part:IsA("BasePart") then
			local id = part:GetAttribute("Phase") or 0
			local bottle = self.Bottles[id] or { Parts = {} }
			bottle.Parts[part] = part.CFrame
			self.Bottles[id] = bottle
		end
	end
	for _, part in CollectionService:GetTagged(POTION.Tag) do
		addBottlePart(part)
	end
	CollectionService:GetInstanceAddedSignal(POTION.Tag):Connect(addBottlePart)
	templates = ReplicatedStorage:WaitForChild(Names.Templates.Folder)
	local leafTemplate = templates:FindFirstChild("WindLeaves")
	if leafTemplate then
		leaves = leafTemplate:Clone()
		leaves.Parent = Workspace.CurrentCamera
	end
	local function addRattle(part)
		if not part:IsA("BasePart") then
			return
		end
		local group
		for _, existing in self.Rattles do
			if (existing.Center - part.Position).Magnitude < RATTLE.Group then
				group = existing
				break
			end
		end
		if not group then
			group = { Center = part.Position, Pivot = CFrame.new(part.Position - Vector3.new(0, part.Size.Y / 2, 0)), Parts = {}, At = -math.huge, Next = os.clock() + random:NextNumber(RATTLE.Every[1], RATTLE.Every[2]) }
			table.insert(self.Rattles, group)
		end
		group.Parts[part] = part.CFrame
	end
	for _, part in CollectionService:GetTagged(RATTLE.Tag) do
		addRattle(part)
	end
	CollectionService:GetInstanceAddedSignal(RATTLE.Tag):Connect(addRattle)
	local function addBelt(belt)
		if belt:IsA("BasePart") then
			self.Belts[belt] = { Ribs = {}, Length = belt.Size.Z * MapConfigScenery.BeltRibs.Span, Speed = 0, Travel = 0, Scanned = -math.huge }
		end
	end
	for _, belt in CollectionService:GetTagged(BELT.Tag) do
		addBelt(belt)
	end
	CollectionService:GetInstanceAddedSignal(BELT.Tag):Connect(addBelt)
	RunService.Heartbeat:Connect(function(dt)
		self:Step(dt)
	end)
end

function AmbientController:StepBelts(dt, cameraPosition)
	local localCharacter = Players.LocalPlayer.Character
	local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
	local runners = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and character:GetAttribute(Names.Attributes.Training) == "Speed" then
			table.insert(runners, root.Position)
		end
	end
	local now = os.clock()
	for belt, state in self.Belts do
		if (not state.Pad or #state.Ribs < MapConfigScenery.BeltRibs.Count) and now - state.Scanned > BELT.Rescan and belt.Parent then
			state.Scanned = now
			local kit = belt.Parent
			state.Pad = kit.Parent and kit.Parent:FindFirstChild(Names.World.Pad)
			table.clear(state.Ribs)
			for _, rib in kit:GetChildren() do
				if rib.Name == "BeltRib" then
					table.insert(state.Ribs, { Part = rib, Rel = belt.CFrame:ToObjectSpace(rib.CFrame) })
				end
			end
		end
		if not belt.Parent then
			self.Belts[belt] = nil
		elseif state.Pad and (state.Speed > 0 or #runners > 0) and ((belt.Position - cameraPosition).Magnitude < BELT.Radius or (localRoot and (belt.Position - localRoot.Position).Magnitude < BELT.Radius)) then
			local active = false
			for _, position in runners do
				local flat = Vector3.new(position.X - state.Pad.Position.X, 0, position.Z - state.Pad.Position.Z)
				if flat.Magnitude < BELT.ActiveRange then
					active = true
					break
				end
			end
			local goal = active and BELT.Speed or 0
			state.Speed = math.abs(goal - state.Speed) < 0.05 and goal or state.Speed + (goal - state.Speed) * math.min(1, dt * BELT.Accel)
			state.Travel = (state.Travel + state.Speed * dt) % state.Length
			for _, rib in state.Ribs do
				local z = (rib.Rel.Position.Z + state.Length / 2 + state.Travel) % state.Length - state.Length / 2
				rib.Part.CFrame = belt.CFrame * CFrame.new(rib.Rel.Position.X, rib.Rel.Position.Y, z) * rib.Rel.Rotation
			end
		end
	end
end

function AmbientController:StepRattles(t, cameraPosition)
	for _, group in self.Rattles do
		if (group.Center - cameraPosition).Magnitude < RATTLE.Radius then
			if t >= group.Next then
				group.At = t
				group.Next = t + RATTLE.Time + random:NextNumber(RATTLE.Every[1], RATTLE.Every[2])
				group.Puffed = false
			end
			local elapsed = t - group.At
			if elapsed <= RATTLE.Time + 0.1 then
				local envelope = math.sin(math.clamp(elapsed / RATTLE.Time, 0, 1) * math.pi)
				local hop = math.abs(math.sin(elapsed * RATTLE.HopSpeed)) * RATTLE.Hop * envelope
				local tilt = math.sin(elapsed * RATTLE.ShakeSpeed) * math.rad(RATTLE.Shake) * envelope
				local move = group.Pivot * CFrame.new(0, hop, 0) * CFrame.Angles(tilt * 0.6, 0, tilt) * group.Pivot:Inverse()
				for part, base in group.Parts do
					if part.Parent then
						part.CFrame = move * base
					end
				end
				if not group.Puffed and elapsed > RATTLE.Time * 0.5 then
					group.Puffed = true
					EffectController:Vfx("Rattle", group.Pivot.Position)
				end
			end
		end
	end
end

local swayAccumulator = 0
local rigAccumulator = 0

local function rigBones(rig)
	local bones = {}
	for _, bone in rig.Part:GetDescendants() do
		if bone:IsA("Bone") then
			bones[bone.Name] = bone
		end
	end
	if not (bones.Body and bones.Head) then
		return false
	end
	local forward = (bones.Head.WorldPosition - bones.Body.WorldPosition) * Vector3.new(1, 0, 1)
	forward = forward.Magnitude > 1e-3 and forward.Unit or rig.Part.CFrame.LookVector
	local side = forward:Cross(Vector3.yAxis)
	rig.Axes = {}
	for name, bone in bones do
		local rest = bone.WorldCFrame.Rotation
		rig.Axes[name] = { Up = rest:VectorToObjectSpace(Vector3.yAxis), Side = rest:VectorToObjectSpace(side), Forward = rest:VectorToObjectSpace(forward) }
	end
	rig.WingSign = bones.WingL and (bones.WingL.WorldPosition - bones.Body.WorldPosition):Dot(side) > 0 and 1 or -1
	rig.Forward = forward
	rig.LookYaw = 0
	rig.LookWeight = 0
	rig.Bones = bones
	return true
end

local function turn(axis, degrees)
	return CFrame.fromAxisAngle(axis, math.rad(degrees))
end

function AmbientController:StepRigs(dt, t, cameraPosition)
	if lowEnd then
		rigAccumulator += dt
		if rigAccumulator < RIG.MobileInterval then
			return
		end
		rigAccumulator = 0
	end
	local character = Players.LocalPlayer.Character
	local target = character and character:FindFirstChild("Head")
	for part, rig in self.Rigs do
		if not part.Parent then
			self.Rigs[part] = nil
		elseif (part.Position - cameraPosition).Magnitude < RIG.Radius and (rig.Bones or rigBones(rig)) then
			local bones, axes, phase = rig.Bones, rig.Axes, rig.Phase
			local lookYaw, lookWeight = 0, 0
			local toTarget = target and (target.Position - bones.Head.WorldPosition) * Vector3.new(1, 0, 1)
			if toTarget and toTarget.Magnitude < RIG.Look.Radius and toTarget.Magnitude > 0.1 then
				local raw = math.deg(math.atan2(rig.Forward:Cross(toTarget.Unit).Y, rig.Forward:Dot(toTarget.Unit)))
				if math.abs(raw) < LOOK.Behind then
					lookYaw, lookWeight = math.clamp(raw, -RIG.Look.MaxYaw, RIG.Look.MaxYaw), 1
				end
			end
			local blend = math.min(1, dt * LOOK.Speed)
			rig.LookYaw += (lookYaw - rig.LookYaw) * blend
			rig.LookWeight += (lookWeight - rig.LookWeight) * blend
			local idle = 1 - RIG.Look.IdleDamp * rig.LookWeight
			local breath = math.sin(t * RIG.Breath.Speed + phase)
			bones.Body.Transform = CFrame.new(axes.Body.Up * breath * RIG.Breath.Lift) * turn(axes.Body.Side, breath * RIG.Breath.Tilt)
			local headShare = bones.Neck and 1 - RIG.Look.NeckShare or 1
			if bones.Neck then
				bones.Neck.Transform = turn(axes.Neck.Up, math.sin(t * RIG.Neck.Speed + phase) * RIG.Neck.Yaw * idle + rig.LookYaw * RIG.Look.NeckShare) * turn(axes.Neck.Side, math.sin(t * RIG.Neck.Speed * 1.7 + phase) * RIG.Neck.Pitch)
			end
			bones.Head.Transform = turn(axes.Head.Up, math.sin(t * RIG.Head.Speed + phase * 1.3) * RIG.Head.Yaw * idle + rig.LookYaw * headShare) * turn(axes.Head.Side, math.sin(t * RIG.Head.NodSpeed + phase) * RIG.Head.Nod)
			if bones.Tail then
				bones.Tail.Transform = turn(axes.Tail.Up, math.sin(t * RIG.Tail.Speed + phase) * RIG.Tail.Yaw)
			end
			if t >= rig.NextFlap then
				rig.FlapAt = t
				rig.NextFlap = t + RIG.Flap.Time + random:NextNumber(RIG.Flap.Every[1], RIG.Flap.Every[2])
			end
			local k = (t - rig.FlapAt) / RIG.Flap.Time
			local lift = (k >= 0 and k <= 1) and math.abs(math.sin(k * math.pi * RIG.Flap.Beats)) * RIG.Flap.Angle or 0
			for name, sign in { WingL = rig.WingSign, WingR = -rig.WingSign } do
				if bones[name] then
					bones[name].Transform = turn(axes[name].Forward, -sign * lift)
				end
			end
		end
	end
end

local function ease(alpha)
	return 0.5 - math.cos(math.clamp(alpha, 0, 1) * math.pi) / 2
end

local WIGGLE_AXES = { X = Vector3.xAxis, Y = Vector3.yAxis, Z = Vector3.zAxis }

function AmbientController:StepPosed(t, cameraPosition)
	local gestures = POSED.Gestures
	for npc, state in self.Posed do
		if not npc.Parent then
			self.Posed[npc] = nil
		elseif (npc:GetPivot().Position - cameraPosition).Magnitude < CULL then
			if not state.Gesture and t >= state.NextGesture then
				state.Gesture = gestures.List[random:NextInteger(1, #gestures.List)]
				state.GestureAt = t
			end
			local gesture, weight = state.Gesture, 0
			if gesture then
				local elapsed = t - state.GestureAt
				if elapsed >= gesture.Time then
					state.Gesture = nil
					state.NextGesture = t + random:NextNumber(gestures.Every[1], gestures.Every[2])
					gesture = nil
				else
					weight = ease(math.min(elapsed, gesture.Time - elapsed) / gestures.Blend)
				end
			end
			local looker = self.Lookers[npc]
			for name, entry in state.Joints do
				local m = POSED.Motion[name]
				local offset = CFrame.identity
				if m then
					local phase = state.Phase + (m.Phase or 0)
					local wave = math.sin(t * m.Speed + phase)
					local pitch = (m.Pitch or 0) * wave
					if m.Tap then
						pitch -= m.Tap * math.max(0, wave) ^ 2 * math.clamp(math.sin(t * m.Burst + phase) * 3, 0, 1)
					end
					offset = CFrame.Angles(math.rad(pitch), math.rad(m.Yaw or 0) * math.sin(t * m.Speed * 0.7 + phase), math.rad(m.Roll or 0) * wave)
				end
				local base = entry.Base
				local target = gesture and gesture.Pose[name]
				if target then
					local pose = entry.Rest * angles(target)
					local wiggle = gesture.Wiggle
					if wiggle and wiggle.Joint == name then
						pose *= CFrame.fromAxisAngle(WIGGLE_AXES[wiggle.Axis], math.rad(wiggle.Angle) * math.sin(t * wiggle.Speed))
					end
					base = base:Lerp(pose, weight)
				end
				if entry.Motor then
					entry.Joint.C0 = base * offset * (looker and looker.Offsets[name] or CFrame.identity)
				else
					entry.Joint.Transform = base * offset
				end
			end
		end
	end
end

function AmbientController:StepCart(t, cameraPosition)
	local cart = self.Cart
	local anchor = next(self.CartParts)
	if not cart or not anchor or (anchor.Position - cameraPosition).Magnitude > CART.Radius then
		return
	end
	if t >= cart.Next then
		cart.From = cart.Offset
		local to = random:NextNumber(CART.Range[1], CART.Range[2])
		if math.abs(to - cart.From) < CART.MinTravel then
			to = cart.From + (cart.From > (CART.Range[1] + CART.Range[2]) / 2 and -CART.MinTravel or CART.MinTravel)
		end
		cart.To = math.clamp(to, CART.Range[1], CART.Range[2])
		cart.Start = t
		cart.Next = t + CART.Time + random:NextNumber(CART.Every[1], CART.Every[2])
		cart.Rolling = true
		EffectController:Vfx("CartDust", anchor.Position - Vector3.new(0, CART.DustDrop, 0))
	end
	local alpha = (t - cart.Start) / CART.Time
	if alpha > 1 and cart.Offset == cart.To then
		return
	end
	if alpha >= 1 and cart.Rolling then
		cart.Rolling = false
		EffectController:Vfx("CartDust", anchor.Position - Vector3.new(0, CART.DustDrop, 0))
	end
	cart.Offset = cart.From + (cart.To - cart.From) * ease(alpha)
	local rumble = Vector3.new(0, math.abs(math.sin(t * CART.RumbleSpeed)) * CART.Rumble * math.sin(math.clamp(alpha, 0, 1) * math.pi), 0)
	for part, base in self.CartParts do
		if part.Parent then
			part.CFrame = base + CART.Axis * cart.Offset + rumble
		else
			self.CartParts[part] = nil
		end
	end
end

local potionRay = RaycastParams.new()
potionRay.FilterType = Enum.RaycastFilterType.Exclude

local function placeBottle(bottle, transform)
	for part, base in bottle.Parts do
		if part.Parent then
			part.CFrame = transform * base
		end
	end
end

function AmbientController:StartPotion(bottle)
	local lowest, center, count = math.huge, Vector3.zero, 0
	for part, base in bottle.Parts do
		lowest = math.min(lowest, base.Position.Y - part.Size.Y / 2)
		center += base.Position
		count += 1
	end
	center /= count
	local angle = random:NextNumber(0, math.pi * 2)
	local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
	local radius = 0.4
	local pivot = Vector3.new(center.X, lowest, center.Z) + direction * radius
	local axis = direction:Cross(Vector3.yAxis).Unit
	local ignore = { self.PotionIgnore }
	for part in bottle.Parts do
		table.insert(ignore, part)
	end
	potionRay.FilterDescendantsInstances = ignore
	local landing = pivot + direction * 1.4
	local hit = Workspace:Raycast(landing + Vector3.new(0, 2, 0), Vector3.new(0, -60, 0), potionRay)
	local drop = hit and math.max(0, pivot.Y - hit.Position.Y) or 0
	bottle.Show = { Start = os.clock(), Pivot = pivot, Axis = axis, Direction = direction, Drop = drop, Landing = Vector3.new(0, -drop, 0) + direction * 1.4, Sparkle = 0 }
end

function AmbientController:StepPotions(t, cameraPosition)
	local show = self.PotionShow
	if not show then
		return
	end
	local active = show.Active
	if not active then
		if t < show.Next then
			return
		end
		show.Next = t + random:NextNumber(POTION.Every[1], POTION.Every[2])
		local ids = {}
		for id, bottle in self.Bottles do
			local part = next(bottle.Parts)
			if part and part.Parent and (part.Position - cameraPosition).Magnitude < POTION.Radius then
				table.insert(ids, id)
			end
		end
		if #ids == 0 then
			return
		end
		active = self.Bottles[ids[random:NextInteger(1, #ids)]]
		show.Active = active
		self.PotionIgnore = Players.LocalPlayer.Character
		self:StartPotion(active)
	end
	local state = active.Show
	local elapsed = t - state.Start
	local tipEnd = POTION.TipTime
	local fallEnd = tipEnd + POTION.FallTime
	local restEnd = fallEnd + POTION.RestTime
	local floatEnd = restEnd + POTION.FloatTime
	local tipped = CFrame.new(state.Pivot) * CFrame.fromAxisAngle(state.Axis, -math.pi / 2) * CFrame.new(-state.Pivot)
	local lying = CFrame.new(state.Landing) * tipped
	if elapsed < tipEnd then
		local a = elapsed / tipEnd
		placeBottle(active, CFrame.new(state.Pivot) * CFrame.fromAxisAngle(state.Axis, -math.pi / 2 * a * a) * CFrame.new(-state.Pivot))
	elseif elapsed < fallEnd then
		local a = (elapsed - tipEnd) / POTION.FallTime
		local hop = a > 0.8 and math.sin((a - 0.8) / 0.2 * math.pi) * POTION.Bounce or 0
		placeBottle(active, CFrame.new(state.Landing * a * a + Vector3.new(0, hop, 0)) * tipped)
		if not state.Landed and a > 0.8 then
			state.Landed = true
			if EffectController then
				EffectController:Vfx("PotionLand", state.Pivot + state.Landing)
			end
		end
	elseif elapsed < restEnd then
		placeBottle(active, lying)
	elseif elapsed < floatEnd then
		local a = ease((elapsed - restEnd) / POTION.FloatTime)
		local lift = math.sin(a * math.pi) * POTION.FloatHeight
		local position = state.Landing:Lerp(Vector3.zero, a) + Vector3.new(0, lift, 0)
		local turn = CFrame.new(state.Pivot) * CFrame.fromAxisAngle(state.Axis, -math.pi / 2 * (1 - a)) * CFrame.Angles(0, a * math.pi * 2 * POTION.Spin * (1 - a), 0) * CFrame.new(-state.Pivot)
		placeBottle(active, CFrame.new(position) * turn)
		if EffectController and t - state.Sparkle > POTION.SparkleEvery then
			state.Sparkle = t
			EffectController:Vfx("PotionMagic", state.Pivot + position + Vector3.new(0, 0.6, 0))
		end
	else
		placeBottle(active, CFrame.identity)
		if EffectController then
			EffectController:Vfx("PotionSettle", state.Pivot + Vector3.new(0, 0.8, 0))
		end
		active.Show = nil
		show.Active = nil
	end
end

function AmbientController:StepWind(dt, t, cameraPosition)
	local enabled = Settings:EffectScale() > 0
	swayAccumulator += dt
	local swayNow = swayAccumulator >= (lowEnd and WIND.MobileSwayInterval or 0)
	if swayNow then
		swayAccumulator = 0
	end
	if leaves then
		leaves.CFrame = CFrame.new(cameraPosition + Vector3.new(0, WIND.LeafHeight, 0))
		leaves.Leaves.Enabled = enabled
	end
	for model, state in swayNow and self.Swayers or {} do
		if not model.Parent then
			self.Swayers[model] = nil
		else
			local distance = (state.Base.Position - cameraPosition).Magnitude
			local radius = state.Small and WIND.SmallRadius or WIND.SwayRadius
			if distance < (lowEnd and radius * WIND.MobileRadiusScale or radius) then
				local wave = math.sin(t * state.Speed + state.Phase) * 0.7 + math.sin(t * state.Speed * 2.3 + state.Phase * 1.7) * 0.3
				local gust = state.Gust
				if gust then
					local g = WIND.Gust
					if t >= gust.Next then
						gust.At = t
						gust.Next = t + g.Rise + g.Hold + g.Fall + random:NextNumber(g.Every[1], g.Every[2])
					end
					local elapsed = t - gust.At
					local level = elapsed < g.Rise and ease(elapsed / g.Rise) or elapsed < g.Rise + g.Hold and 1 or 1 - ease((elapsed - g.Rise - g.Hold) / g.Fall)
					wave = (0.35 + wave) * (g.Calm + (1 - g.Calm) * level) - 0.35
				end
				if state.Leaves then
					local pivot = state.Leaves.Pivot
					for _, leaf in state.Leaves.Parts do
						local flutter = leaf.Light and math.sin(t * state.Speed * 3.1 + state.Phase * 2.3) * 0.35 or 0
						local rotation = CFrame.fromAxisAngle(swayAxis, state.Amp * (0.35 + wave + flutter))
						leaf.Part.CFrame = pivot * rotation * pivot:Inverse() * leaf.Base
					end
				else
					model:PivotTo(state.Base * CFrame.fromAxisAngle(state.Base.Rotation:VectorToObjectSpace(swayAxis), state.Amp * (0.35 + wave)))
				end
			end
		end
	end
	for streak, state in self.Streaks do
		local age = t - state.Born
		if age > WIND.StreakLife then
			streak:Destroy()
			self.Streaks[streak] = nil
		else
			local along = state.Origin + windDirection * WIND.StreakSpeed * age
			local lift = math.sin(age * 4 + state.Phase) * WIND.StreakWave
			local curl = math.cos(age * 3 + state.Phase) * WIND.StreakWave * 0.6
			local position = along + Vector3.new(0, lift, 0) + swayAxis * curl
			if streak:IsA("Model") then
				streak:PivotTo(CFrame.lookAt(position, position + windDirection) * state.Roll)
			else
				streak.CFrame = CFrame.new(position)
			end
		end
	end
	if enabled and templates and t - lastStreak > WIND.StreakInterval then
		lastStreak = t
		local count = 0
		for _ in self.Streaks do
			count += 1
		end
		local gusts = templates:FindFirstChild("WindGusts")
		local options = gusts and gusts:GetChildren() or {}
		local template = #options > 0 and options[random:NextInteger(1, #options)] or templates:FindFirstChild("WindStreak")
		if template and count < WIND.StreakMax then
			local angle = random:NextNumber(0, math.pi * 2)
			local radius = random:NextNumber(WIND.StreakRing[1], WIND.StreakRing[2])
			local origin = cameraPosition * Vector3.new(1, 0, 1) + Vector3.new(math.cos(angle) * radius, random:NextNumber(WIND.StreakHeight[1], WIND.StreakHeight[2]), math.sin(angle) * radius) - windDirection * WIND.StreakSpeed * WIND.StreakLife * 0.5
			local streak = template:Clone()
			local roll = CFrame.Angles(0, 0, random:NextNumber(-0.6, 0.6))
			if streak:IsA("Model") then
				streak:ScaleTo(random:NextNumber(WIND.GustScale[1], WIND.GustScale[2]))
				streak:PivotTo(CFrame.lookAt(origin, origin + windDirection) * roll)
			else
				streak.CFrame = CFrame.new(origin)
			end
			streak.Parent = Workspace.CurrentCamera
			self.Streaks[streak] = { Born = t, Origin = origin, Phase = random:NextNumber(0, math.pi * 2), Roll = roll }
		end
	end
end

function AmbientController:StepLook(dt, cameraPosition)
	local character = Players.LocalPlayer.Character
	local target = character and character:FindFirstChild("Head")
	for npc, state in self.Lookers do
		if not npc.Parent or not state.Head.Parent then
			self.Lookers[npc] = nil
		elseif (state.Root.Position - cameraPosition).Magnitude < CULL then
			local yaw, pitch = 0, 0
			if target then
				local offset = state.Root.CFrame:VectorToObjectSpace(target.Position - state.Head.Position)
				if offset.Magnitude < LOOK.Radius then
					local raw = math.deg(math.atan2(-offset.X, -offset.Z))
					if math.abs(raw) < LOOK.Behind then
						yaw = math.clamp(raw, -LOOK.MaxYaw, LOOK.MaxYaw)
						pitch = math.clamp(math.deg(math.atan2(offset.Y, math.sqrt(offset.X * offset.X + offset.Z * offset.Z))), -LOOK.MaxPitch, LOOK.MaxPitch)
					end
				end
			end
			local blend = math.min(1, dt * LOOK.Speed)
			state.Yaw += (yaw - state.Yaw) * blend
			state.Pitch += (pitch - state.Pitch) * blend
			local share = state.Joints.Waist and LOOK.WaistShare or 0
			state.Offsets.Waist = CFrame.Angles(0, math.rad(state.Yaw * share), 0)
			state.Offsets.Neck = CFrame.Angles(0, math.rad(state.Yaw * (1 - share)), 0) * CFrame.Angles(math.rad(state.Pitch), 0, 0)
			for name, joint in state.Joints do
				if joint.Attachment then
					joint.Attachment.CFrame = joint.Base * state.Offsets[name]
				elseif not state.Posed then
					joint.Joint.C0 = joint.Base * state.Offsets[name]
				end
			end
		end
	end
end

function AmbientController:Step(dt)
	local t = os.clock()
	local cameraPosition = camera.CFrame.Position
	for part, state in self.Ripples or {} do
		if not part.Parent then
			self.Ripples[part] = nil
		elseif (part.Position - cameraPosition).Magnitude < WIND.RippleRadius then
			local p = (t / WIND.RipplePeriod + state.Phase / 3) % 1
			local grow = 0.55 + 0.75 * p
			part.Size = Vector3.new(state.Size.X * grow, state.Size.Y, state.Size.Z * grow)
			if state.Sprite then
				state.Sprite.Transparency = 0.2 + 0.8 * p
			else
				part.Transparency = 0.2 + 0.8 * p
			end
		end
	end
	for part, state in self.Foams do
		if not part.Parent then
			self.Foams[part] = nil
		elseif (part.Position - cameraPosition).Magnitude < WIND.RippleRadius then
			part.CFrame = state.Base * CFrame.Angles(0, t * WATER.FoamSpin + state.Phase, 0)
			state.Sprite.Transparency = WATER.FoamBase + WATER.FoamPulse * (0.5 + 0.5 * math.sin(t * WATER.FoamPulseSpeed + state.Phase))
		end
	end
	self:StepRigs(dt, t, cameraPosition)
	self:StepCart(t, cameraPosition)
	self:StepPotions(t, cameraPosition)
	self:StepLook(dt, cameraPosition)
	self:StepPosed(t, cameraPosition)
	self:StepRattles(t, cameraPosition)
	self:StepBelts(dt, cameraPosition)
	self:StepWind(dt, t, cameraPosition)
	local display = PropsConfig.Displays
	for model, state in self.Wobblers do
		if not model.Parent then
			self.Wobblers[model] = nil
		elseif (state.Base.Position - cameraPosition).Magnitude < CULL then
			local angle = math.rad(display.WobbleDegrees)
			local wobble = CFrame.Angles(math.sin(t * display.WobbleSpeed + state.Phase) * angle, t * 0.6 + state.Phase, math.cos(t * display.WobbleSpeed * 1.3 + state.Phase) * angle * 0.6)
			model:PivotTo(state.Base * wobble)
		end
	end
	for model, state in self.Clouds do
		if not model.Parent then
			self.Clouds[model] = nil
		else
			local sway = math.sin(t * 0.03 * state.Drift + state.Phase) * PropsConfig.CloudSway
			model:PivotTo(state.Base * CFrame.new(sway, math.sin(t * 0.2 + state.Phase) * 1.5, 0))
		end
	end
	for model, state in self.Wanderers do
		if not model.Parent then
			self.Wanderers[model] = nil
		elseif (state.Position - cameraPosition).Magnitude < CULL then
			local moving = false
			if t >= state.PauseUntil then
				if not state.Target then
					local home = state.Home
					state.Target = Vector3.new(home.X + random:NextNumber(-state.Spread, state.Spread), state.Position.Y, home.Z + random:NextNumber(-state.Spread, state.Spread))
				end
				local delta = state.Target - state.Position
				local flat = Vector3.new(delta.X, 0, delta.Z)
				if flat.Magnitude < 0.3 then
					state.Target = nil
					state.PauseUntil = t + random:NextNumber(PropsConfig.WanderPause[1], PropsConfig.WanderPause[2])
				else
					moving = true
					local step = math.min(flat.Magnitude, state.Speed * dt)
					state.Position += flat.Unit * step
					local goal = CFrame.lookAt(Vector3.zero, flat.Unit) * CFrame.Angles(0, state.Yaw, 0)
					state.Facing = state.Facing:Lerp(goal.Rotation, math.min(1, dt * 8))
				end
			end
			local hop = moving and math.abs(math.sin(t * 12 + state.Phase)) * PropsConfig.WanderHop or 0
			local peck = not moving and math.max(0, math.sin(t * 3 + state.Phase)) ^ 8 * 0.35 or 0
			model:PivotTo(CFrame.new(state.Position + Vector3.new(0, hop, 0)) * state.Facing * CFrame.Angles(0, 0, -peck))
		end
	end
end

return AmbientController
