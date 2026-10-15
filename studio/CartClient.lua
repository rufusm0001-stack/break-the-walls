-- Draws the brick mine cart behind every player, client-side only. It follows like a pet (no
-- collisions, so it never snags), sits on the ground, spins its wheels by distance travelled,
-- and shows 0-4 coal layers from the Cart / CartCapacity attributes the server sets on each
-- Player. Pieces come from ReplicatedStorage.Assets.CartTemplate, each with an Offset attribute
-- relative to the cart's bottom centre; the pull handle is at -Z, so the cart faces its owner.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local TEMPLATE = RS:WaitForChild("Assets"):WaitForChild("CartTemplate")
-- Behind and to the right, so the default camera (directly behind the player) never looks through it.
local FOLLOW_OFFSET = CFrame.new(4, 0, 1.5)
local WHEEL_RADIUS = 1.1

local carts = {}
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function buildCart(owner)
	local model = TEMPLATE:Clone()
	model.Name = owner.Name .. "_Cart"
	local cart = { model = model, pieces = {}, wheels = {}, layers = {}, spin = 0 }
	for _, piece in ipairs(model:GetChildren()) do
		if piece:IsA("BasePart") then
			local entry = { part = piece, offset = piece:GetAttribute("Offset") }
			if piece.Name:match("^Wheel_") then
				table.insert(cart.wheels, entry)
			else
				table.insert(cart.pieces, entry)
			end
			local layer = piece:GetAttribute("Layer")
			if layer then
				cart.layers[layer] = piece
			end
		end
	end
	model.Parent = workspace
	return cart
end

local function updateFill(cart, owner)
	local capacity = owner:GetAttribute("CartCapacity") or 1
	local fill = math.clamp((owner:GetAttribute("Cart") or 0) / math.max(capacity, 1), 0, 1)
	local shown = math.ceil(fill * #cart.layers)
	for layer, piece in pairs(cart.layers) do
		piece.Transparency = layer <= shown and 0 or 1
	end
end

local function track(owner)
	local function onCharacter(character)
		if carts[owner] then
			carts[owner].model:Destroy()
		end
		local cart = buildCart(owner)
		cart.character = character
		carts[owner] = cart
		updateFill(cart, owner)
	end
	owner.CharacterAdded:Connect(onCharacter)
	if owner.Character then
		onCharacter(owner.Character)
	end
	for _, attr in ipairs({ "Cart", "CartCapacity" }) do
		owner:GetAttributeChangedSignal(attr):Connect(function()
			if carts[owner] then
				updateFill(carts[owner], owner)
			end
		end)
	end
end

Players.PlayerAdded:Connect(track)
for _, p in ipairs(Players:GetPlayers()) do
	track(p)
end
Players.PlayerRemoving:Connect(function(p)
	if carts[p] then
		carts[p].model:Destroy()
		carts[p] = nil
	end
end)

RunService.RenderStepped:Connect(function(dt)
	local exclude = {}
	for _, cart in pairs(carts) do
		table.insert(exclude, cart.model)
		if cart.character then
			table.insert(exclude, cart.character)
		end
	end
	rayParams.FilterDescendantsInstances = exclude

	for _, cart in pairs(carts) do
		local root = cart.character and cart.character.Parent and cart.character:FindFirstChild("HumanoidRootPart")
		if root then
			local behind = root.CFrame * FOLLOW_OFFSET
			local from = cart.cframe and cart.cframe.Position or behind.Position
			local target = from:Lerp(behind.Position, math.clamp(dt * 6, 0, 1))
			-- teleports snap instead of dragging the cart across the map
			if (behind.Position - from).Magnitude > 40 then
				target = behind.Position
			end
			local hit = workspace:Raycast(target + Vector3.new(0, 4, 0), Vector3.new(0, -14, 0), rayParams)
			local groundY = hit and hit.Position.Y or (root.Position.Y - 3)
			local pos = Vector3.new(target.X, groundY, target.Z)
			local toward = Vector3.new(root.Position.X, groundY, root.Position.Z)
			local facing
			if (toward - pos).Magnitude > 0.2 then
				facing = CFrame.lookAt(pos, toward)
			else
				facing = CFrame.new(pos) * (cart.cframe and cart.cframe.Rotation or CFrame.identity)
			end
			local moved = cart.cframe and (pos - cart.cframe.Position).Magnitude or 0
			cart.cframe = facing
			cart.spin += moved / WHEEL_RADIUS
			for _, e in ipairs(cart.pieces) do
				e.part.CFrame = facing * e.offset
			end
			for _, e in ipairs(cart.wheels) do
				e.part.CFrame = facing * CFrame.new(e.offset.Position) * CFrame.Angles(-cart.spin, 0, 0) * e.offset.Rotation
			end
		end
	end
end)
