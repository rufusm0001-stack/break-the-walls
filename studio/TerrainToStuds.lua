-- Edit-time tool (put in ServerStorage.DevTools, require a CLONE of it from execute_luau):
-- rebuilds smooth Terrain as stud blocks. Only voxels that touch air/water become parts, and each
-- horizontal layer is greedily merged into rectangles so flat ground is a few big studded blocks.
-- Water stays terrain. Convert in 40x40-cell chunks, then clear the solid terrain you converted:
--   local T = require(game.ServerStorage.DevTools.TerrainToStuds:Clone())
--   T.convertChunk(Vector3.new(cx,-16,cz), Vector3.new(cx+39,63,cz+39), folder)
--   for mat in pairs(T.COLORS) do workspace.Terrain:ReplaceMaterial(region, 4, mat, Enum.Material.Air) end
-- Afterwards: recolour cave interiors (blocks with stud rock overhead) per zone, and re-ground props.

local M = {}

local RES = 4
local terrain = workspace.Terrain

local M_ = Enum.Material
M.COLORS = {
	[M_.Grass] = Color3.fromHex("6CC24A"),
	[M_.LeafyGrass] = Color3.fromHex("5DB33F"),
	[M_.Ground] = Color3.fromHex("B5713B"),
	[M_.Mud] = Color3.fromHex("8A5530"),
	[M_.Sand] = Color3.fromHex("F2D27A"),
	[M_.Sandstone] = Color3.fromHex("A87452"),
	[M_.Rock] = Color3.fromHex("8A8F99"),
	[M_.Slate] = Color3.fromHex("7A808C"),
	[M_.Basalt] = Color3.fromHex("5D626B"),
	[M_.Limestone] = Color3.fromHex("E6DCC0"),
	[M_.Pavement] = Color3.fromHex("A9AEB8"),
	[M_.Cobblestone] = Color3.fromHex("9EA3AD"),
	[M_.Concrete] = Color3.fromHex("AFB4BC"),
	[M_.Asphalt] = Color3.fromHex("5D626B"),
	[M_.Brick] = Color3.fromHex("D9483B"),
	[M_.Snow] = Color3.fromHex("F4F8FF"),
	[M_.Glacier] = Color3.fromHex("BFEFFF"),
	[M_.Ice] = Color3.fromHex("BFEFFF"),
	[M_.Salt] = Color3.fromHex("F4F0E6"),
	[M_.CrackedLava] = Color3.fromHex("FF7A1A"),
	[M_.WoodPlanks] = Color3.fromHex("B5713B"),
}
local FALLBACK = Color3.fromHex("8A8F99")

local function solidMat(mat, occ)
	return occ >= 0.5 and mat ~= M_.Air and mat ~= M_.Water
end

-- Converts the inclusive cell box [minCell, maxCell] (4-stud cells); returns parts made.
function M.convertChunk(minCell, maxCell, outFolder)
	local lo = Vector3.new(minCell.X - 1, minCell.Y - 1, minCell.Z - 1) * RES
	local hi = Vector3.new(maxCell.X + 2, maxCell.Y + 2, maxCell.Z + 2) * RES
	local region = Region3.new(lo, hi):ExpandToGrid(RES)
	local mats, occs = terrain:ReadVoxels(region, RES)
	local size = mats.Size
	local sx, sy, sz = size.X, size.Y, size.Z
	local origin = region.CFrame.Position - region.Size / 2

	local function solid(x, y, z)
		if x < 1 or y < 1 or z < 1 or x > sx or y > sy or z > sz then
			return false
		end
		return solidMat(mats[x][y][z], occs[x][y][z])
	end

	local made = 0
	for y = 2, sy - 1 do
		local exposed, any = {}, false
		for x = 2, sx - 1 do
			local col = {}
			for z = 2, sz - 1 do
				if solid(x, y, z) and not (solid(x + 1, y, z) and solid(x - 1, y, z) and solid(x, y + 1, z)
					and solid(x, y - 1, z) and solid(x, y, z + 1) and solid(x, y, z - 1)) then
					col[z] = mats[x][y][z]
					any = true
				end
			end
			exposed[x] = col
		end
		if any then
			for x = 2, sx - 1 do
				for z = 2, sz - 1 do
					local mat = exposed[x][z]
					if mat then
						local z2 = z
						while z2 + 1 <= sz - 1 and exposed[x][z2 + 1] == mat do
							z2 += 1
						end
						local x2 = x
						while x2 + 1 <= sx - 1 do
							local ok = true
							for zz = z, z2 do
								if exposed[x2 + 1][zz] ~= mat then
									ok = false
									break
								end
							end
							if not ok then
								break
							end
							x2 += 1
						end
						for xx = x, x2 do
							for zz = z, z2 do
								exposed[xx][zz] = nil
							end
						end
						local p = Instance.new("Part")
						p.Name = mat.Name
						p.Anchored = true
						p.Material = Enum.Material.Plastic
						p.Color = M.COLORS[mat] or FALLBACK
						p.Size = Vector3.new((x2 - x + 1) * RES, RES, (z2 - z + 1) * RES)
						p.Position = origin + Vector3.new((x - 1 + (x2 - x + 1) / 2) * RES, (y - 0.5) * RES, (z - 1 + (z2 - z + 1) / 2) * RES)
						p.TopSurface = Enum.SurfaceType.Studs
						p.FrontSurface = Enum.SurfaceType.Studs
						p.BackSurface = Enum.SurfaceType.Studs
						p.LeftSurface = Enum.SurfaceType.Studs
						p.RightSurface = Enum.SurfaceType.Studs
						p.BottomSurface = Enum.SurfaceType.Inlet
						p.Parent = outFolder
						made += 1
					end
				end
			end
		end
	end
	return made
end

return M
