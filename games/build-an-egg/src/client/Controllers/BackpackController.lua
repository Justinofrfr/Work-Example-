local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local GameConfig = require(Shared.Config.Game)

local Ui = require(script.Parent.Parent.Util.Ui)

local BackpackController = {
	Stacks = {},
}

local BP = GameConfig.Backpack
local A = Names.Attributes
local templates
local camera = Workspace.CurrentCamera

function BackpackController:Init()
	templates = ReplicatedStorage:WaitForChild(Names.Templates.Folder)
end

function BackpackController:Start()
	RunService.RenderStepped:Connect(function()
		self:Step()
	end)
end

function BackpackController:Clear(character)
	local stack = self.Stacks[character]
	if stack then
		stack.Root:Destroy()
		self.Stacks[character] = nil
	end
end

function BackpackController:Build(character, body)
	local root = templates[Names.Templates.StackPiece]:Clone()
	root.Name = "StackRoot"
	root.Transparency = 1
	root.Size = Vector3.new(0.2, 0.2, 0.2)
	local top = body.Size.Y / 2 + BP.StackLift
	root.CFrame = body.CFrame * CFrame.new(0, top, 0)
	local mount = body:FindFirstChild("Mount"):Clone()
	mount.Name = "StackMount"
	mount.Part0 = body
	mount.Part1 = root
	mount.C0 = CFrame.new(0, top, 0)
	mount.Parent = root
	root.Parent = Workspace
	local label = templates[Names.Templates.StackLabel]:Clone()
	label.Adornee = root
	label.Parent = root
	local stack = { Root = root, Mount = mount, Base = mount.C0, Pieces = {}, Label = label, Phase = math.random() * math.pi * 2, Shown = 0 }
	self.Stacks[character] = stack
	return stack
end

function BackpackController:Resize(stack, wanted)
	local pieces = stack.Pieces
	local template = templates[Names.Templates.StackPiece]
	while #pieces > wanted do
		table.remove(pieces):Destroy()
	end
	local added = 0
	while #pieces < wanted do
		local index = #pieces + 1
		local piece = template:Clone()
		piece.Name = "Piece"
		local offset = CFrame.new(0, (index - 0.5) * BP.PieceSpacing, 0) * CFrame.Angles(0, math.rad(index * BP.PieceTwist), 0)
		piece.CFrame = stack.Root.CFrame * offset
		local weld = stack.Mount:Clone()
		weld.Name = "Weld"
		weld.Part0 = stack.Root
		weld.Part1 = piece
		weld.C0 = offset
		weld.Parent = piece
		piece.Parent = stack.Root
		table.insert(pieces, piece)
		added += 1
		if added <= 6 then
			piece.Size = BP.PieceSize * 0.3
			Ui.Tween(piece, BP.PopTime, { Size = BP.PieceSize }, Enum.EasingStyle.Back)
		end
	end
	stack.Label.StudsOffset = Vector3.new(0, wanted * BP.PieceSpacing + BP.LabelOffset, 0)
end

function BackpackController:Step()
	local now = os.clock()
	local cameraPosition = camera.CFrame.Position
	local seen = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local backpack = character and character:FindFirstChild(Names.Templates.Backpack)
		local body = backpack and backpack.PrimaryPart
		local count = character and character:GetAttribute(A.CarryCount) or 0
		if body and count > 0 and (body.Position - cameraPosition).Magnitude < BP.CullDistance then
			seen[character] = true
			local stack = self.Stacks[character] or self:Build(character, body)
			local wanted = math.min(count, BP.MaxStack)
			if wanted ~= stack.Shown then
				stack.Shown = wanted
				self:Resize(stack, wanted)
			end
			stack.Label.Text.Text = tostring(count)
			local lean = math.rad(BP.Sway) * math.min(1, wanted / 60)
			stack.Mount.C0 = stack.Base * CFrame.Angles(math.sin(now * BP.SwaySpeed + stack.Phase) * lean, 0, math.sin(now * BP.SwaySpeed * 1.3 + stack.Phase) * lean)
		end
	end
	for character in self.Stacks do
		if not seen[character] then
			self:Clear(character)
		end
	end
end

return BackpackController
