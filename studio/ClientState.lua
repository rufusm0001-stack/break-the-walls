-- ReplicatedStorage.BTW.ClientState: client-only shared state between ToolsClient, FirstPersonArms, HUD and Audio.
-- (Each client requires its own copy, so these BindableEvents never cross the network.)
local ClientState = {
	equipped = 1, -- 1 Fists, 2 Vacuum
	vacuuming = false,
	menuOpen = false, -- settings panel open (mouse is free)
	nozzle = nil, -- world CFrame of the held vacuum's mouth, set by FirstPersonArms every frame
	shake = 0, -- camera shake amount, decays in FirstPersonArms
	Jab = Instance.new("BindableEvent"), -- fired on every real punch
	EquipChanged = Instance.new("BindableEvent"),
	Sfx = Instance.new("BindableEvent"), -- Sfx:Fire(name, worldPos?) -> Audio plays it
}

function ClientState.equip(slot)
	if slot == ClientState.equipped then return end
	ClientState.equipped = slot
	ClientState.vacuuming = false
	ClientState.EquipChanged:Fire(slot)
end

function ClientState.kick(amount)
	ClientState.shake = math.max(ClientState.shake, amount)
end

return ClientState
