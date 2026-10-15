-- ReplicatedStorage.Modules.Icons: uploaded image ids used by ToyUI and the HUD.
-- Icons: Gemini 2.5 Flash Image via art/gen_icons.py, cut PNGs in art/icons/, uploaded with the Studio MCP
-- upload_image (free). Tool icons are indexed by tier: 0 = starter (FistTier / VacuumTier attributes).
-- v2 (2026-10-15): fist tiers and vacuum tiers are image EDITS of fist_0 / vacuum_0, so each set matches,
-- then colour passes (--vivid, --vivid2, skin/yellow hue match + saturation in cut()) made them richer
-- (owner: pale yellow was boring; fist_0 and the music note were the target colours).
return {
	StudTile = "rbxassetid://126732731360060", -- art/stud_tile.png
	Coin = "rbxassetid://74868412677332", -- stack of gold coins with a $
	Gear = "rbxassetid://112816533716898",
	Aim = "rbxassetid://121146236940981", -- crosshair with arrows (aim sensitivity row)
	Mouse = "rbxassetid://86137731596028", -- old sensitivity icon, kept as a fallback
	Music = "rbxassetid://87879786202116",
	Speaker = "rbxassetid://123462587518089",
	Fist = {
		[0] = "rbxassetid://75999293751444", -- bare fist
		"rbxassetid://81546761404234", -- 1 bronze knuckles
		"rbxassetid://119621750896311", -- 2 iron knuckles
		"rbxassetid://83443846480928", -- 3 gold knuckles
		"rbxassetid://120618156762179", -- 4 diamond knuckles
		"rbxassetid://100867898562880", -- 5 energy knuckles
	},
	Vacuum = {
		[0] = "rbxassetid://125553534639703", -- basic
		"rbxassetid://76372746250379", -- 1 turbo
		"rbxassetid://91596072751482", -- 2 cyclone
		"rbxassetid://76649107480261", -- 3 mega (bigger from here on)
		"rbxassetid://131826125626867", -- 4 titan
		"rbxassetid://72586190807488", -- 5 vortex (cogs)
	},
}
