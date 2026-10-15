-- ReplicatedStorage.BTW.ClientState: client-only shared state between ToolsClient, FirstPersonArms and HUD.
-- (Each client requires its own copy, so these BindableEvents never cross the network.)
local ClientState = {
	equipped = 1, -- 1 Fists, 2 Vacuum
	vacuuming = false,
	Jab = Instance.new("BindableEvent"), -- fired on every real punch
	EquipChanged = Instance.new("BindableEvent"),
}

function ClientState.equip(slot)
	if slot == ClientState.equipped then return end
	ClientState.equipped = slot
	ClientState.vacuuming = false
	ClientState.EquipChanged:Fire(slot)
end

return ClientState
