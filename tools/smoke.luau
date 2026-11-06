-- Builds the real world and every hive / bee / jar under Lune's Roblox library and checks them:
-- no errors, part budgets (bee < 20 parts, jar <= 3), bees fit their slot, pads and belt sit on
-- the plot. Usage: rojo build default.project.json -o build/FarmBeesGetHoney.rbxl
--                  lune run tools/smoke -- build/FarmBeesGetHoney.rbxl
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local placePath = process.args[1] == "--" and process.args[2] or process.args[1] or "build/FarmBeesGetHoney.rbxl"
local game = roblox.deserializePlace(fs.readFile(placePath))
local workspace = game:GetService("Workspace")

local cache = {}
local env
local function requireModule(module)
	if cache[module] ~= nil then
		return cache[module]
	end
	local e = table.clone(env)
	e.script = module
	local chunk = luau.load(module.Source, { debugName = module:GetFullName(), environment = e })
	local result = chunk()
	cache[module] = result
	return result
end

env = {
	game = game,
	workspace = workspace,
	require = requireModule,
	Instance = roblox.Instance,
	Vector3 = roblox.Vector3,
	Vector2 = roblox.Vector2,
	CFrame = roblox.CFrame,
	Color3 = roblox.Color3,
	UDim = roblox.UDim,
	UDim2 = roblox.UDim2,
	Enum = roblox.Enum,
	NumberSequence = roblox.NumberSequence,
	ColorSequence = roblox.ColorSequence,
	ColorSequenceKeypoint = roblox.ColorSequenceKeypoint,
	NumberRange = roblox.NumberRange,
	PhysicalProperties = roblox.PhysicalProperties,
	typeof = typeof,
}

local failures = 0
local function check(ok, message)
	if not ok then
		failures += 1
		print("FAIL " .. message)
	end
end

local function parts(root)
	local n = 0
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			n += 1
		end
	end
	return n
end

local RS = game.ReplicatedStorage
local World = requireModule(game.ServerScriptService.Server.Util.World)
local HiveModel = requireModule(RS.Shared.HiveModel)
local JarModel = requireModule(RS.Shared.JarModel)
local Layout = requireModule(RS.Shared.Config.Layout)

local plots, hub = World.build(workspace)
check(#plots == 6, "six plots")
check(hub.leaderboard ~= nil, "hub leaderboard")
print(string.format("map: %d parts", parts(workspace.Map)))

-- Two plot squares (rotated) are apart if some edge normal separates them by `gap` (SAT in 2D).
local function corners(cf)
	local h = Layout.plotSize / 2
	local out = {}
	for _, c in { { -h, -h }, { h, -h }, { h, h }, { -h, h } } do
		local w = cf:PointToWorldSpace(roblox.Vector3.new(c[1], 0, c[2]))
		table.insert(out, { w.X, w.Z })
	end
	return out
end
local function separated(a, b, gap)
	for _, poly in { a, b } do
		for i = 1, 4 do
			local p, q = poly[i], poly[i % 4 + 1]
			local nx, nz = -(q[2] - p[2]), q[1] - p[1]
			local len = math.sqrt(nx * nx + nz * nz)
			nx, nz = nx / len, nz / len
			local amin, amax, bmin, bmax = math.huge, -math.huge, math.huge, -math.huge
			for _, c in a do
				local d = c[1] * nx + c[2] * nz
				amin, amax = math.min(amin, d), math.max(amax, d)
			end
			for _, c in b do
				local d = c[1] * nx + c[2] * nz
				bmin, bmax = math.min(bmin, d), math.max(bmax, d)
			end
			if amax + gap <= bmin or bmax + gap <= amin then
				return true
			end
		end
	end
	return false
end

-- Plots don't overlap each other (at least 10 studs apart) or the hub.
for i, a in plots do
	local pa = a.cframe.Position
	check(pa.Magnitude - Layout.plotSize / 2 > Layout.hubRadius + 10, "plot " .. i .. " clear of the hub")
	for j, b in plots do
		if i < j then
			check(separated(corners(a.cframe), corners(b.cframe), 10), "plots " .. i .. "/" .. j .. " overlap or touch")
		end
	end
	-- Fence: four sides, the front open where the bridge arrives
	local fences = {}
	for _, d in a.model:GetChildren() do
		if d.Name == "Fence" then
			table.insert(fences, d)
		end
	end
	check(#fences == 5, "plot " .. i .. " has 5 fence pieces")
	for _, fpart in fences do
		local p = World.toLocal(a, fpart.CFrame.Position)
		local onFront = p.Z > Layout.plotSize / 2 - 2
		if onFront then
			check(math.abs(p.X) - fpart.Size.X / 2 >= Layout.fence.gap / 2 - 0.01, "fence leaves the bridge gap")
		end
	end
	check(Layout.fence.gap > Layout.bridgeWidth, "the gap is wider than the bridge")
	-- Every pad inside the plot, none overlapping another
	local names = {}
	for name, pad in a.pads do
		check(math.abs(pad.center.X) + Layout.padSize / 2 < Layout.plotSize / 2, name .. " inside plot")
		check(
			World.isOnPad(a, pad, World.toWorld(a, pad.center + roblox.Vector3.new(0, 2, 0))),
			name .. " detects its center"
		)
		table.insert(names, pad)
	end
	for x = 1, #names do
		for y = x + 1, #names do
			local p, q = names[x].center, names[y].center
			local apart = math.abs(p.X - q.X) >= Layout.padSize or math.abs(p.Z - q.Z) >= Layout.padSize
			check(apart, names[x].name .. " / " .. names[y].name .. " overlap")
		end
	end
	-- Slots: slot 1 bottom-left, 100 top-right as seen from the front, above the ground.
	local s1 = World.toLocal(a, World.slotCFrame(a, 1).Position)
	local s100 = World.toLocal(a, World.slotCFrame(a, 100).Position)
	check(s1.X < s100.X and s1.Y < s100.Y, "slot order")
	check(s1.Y - (Layout.slotSize - 0.2) / 2 > 0, "bottom row above ground")
	-- The jar spawn of every column is over belt A
	for i2 = 1, 10 do
		local p = World.toLocal(a, World.jarSpawn(a, i2))
		check(p.X > Layout.beltA.from.X and p.X < Layout.beltA.to.X, "jar spawn over belt A, column " .. i2)
		check(not World.beltDone(a, World.jarSpawn(a, i2)), "fresh jar not done")
	end
	-- Belt speed direction: A along +x local, B along +z local
	local va = a.cframe:VectorToObjectSpace(a.beltA.AssemblyLinearVelocity)
	local vb = a.cframe:VectorToObjectSpace(a.beltB.AssemblyLinearVelocity)
	check(va.X > 1 and math.abs(va.Z) < 0.01, "belt A moves +x")
	check(vb.Z > 1 and math.abs(vb.X) < 0.01, "belt B moves toward the front")
end

-- Every tier's hive: five panels + root (the bee is client-side), and the bee fits its box at
-- every point of its flight.
local BeeModel = requireModule(RS.Shared.BeeModel)
local BeeFlight = requireModule(RS.Shared.BeeFlight)
local Styles = requireModule(RS.Shared.Config.BeeStyle)
local plot = plots[1]
local inner = HiveModel.inner()
for tier = 1, 12 do
	local cf = World.slotCFrame(plot, 45)
	local hive = HiveModel.build(tier, cf)
	local hiveParts = parts(hive)
	check(hiveParts == 6, string.format("tier %d hive has %d parts", tier, hiveParts))
	for _, name in { "Back", "Top", "Bottom", "Left", "Right" } do
		check(hive:FindFirstChild(name) ~= nil, "hive panel " .. name)
	end
	check(hive:FindFirstChild("Front") == nil, "hive front is open")
	check(hive.PrimaryPart:FindFirstChild("Label") ~= nil, "hive label")
	local bee = BeeModel.build(tier, roblox.CFrame.new())
	local beeParts = parts(bee)
	check(beeParts < 20, string.format("tier %d bee has %d parts", tier, beeParts))
	-- The real bee's extents stay within BeeFlight's assumed reach (so the wander test holds).
	local s = Styles[tier].scale
	for _, d in bee:GetDescendants() do
		if d:IsA("BasePart") then
			local p = d.CFrame.Position
			local r = math.max(d.Size.X, d.Size.Y, d.Size.Z) / 2 * 0.5
			local horizontal = math.max(math.abs(p.X), math.abs(p.Z)) + r
			check(
				horizontal <= BeeFlight.HALF_LENGTH * s + 0.05,
				string.format("tier %d %s reaches %.2f past HALF_LENGTH", tier, d.Name, horizontal)
			)
			check(
				math.abs(p.Y) + r <= BeeFlight.HALF_HEIGHT * s + 0.25,
				string.format("tier %d %s too tall (%.2f)", tier, d.Name, math.abs(p.Y) + r)
			)
		end
	end
	local range = BeeFlight.range(s, inner)
	check(range.x > 0.3 and range.y > 0.3, "tier " .. tier .. " has room to fly")
	print(
		string.format(
			"tier %2d: hive %d parts, bee %d parts, flies +-%.1f x +-%.1f",
			tier,
			hiveParts,
			beeParts,
			range.x,
			range.y
		)
	)
end
-- The hive platform is higher than belt A's rails, so the bottom row is never hidden.
check(Layout.platform.height > Layout.beltTop + Layout.beltRail, "hive platform above the belt rails")
check(Layout.pads.Merge ~= nil, "merge pad")

-- Jars appear on belt A, in front of the hives (between the stack and the pads)
for i = 1, 10 do
	local p = World.toLocal(plot, World.jarSpawn(plot, i))
	check(p.Z > Layout.wallZ + Layout.slotSize / 2, "jar spawns in front of the hives")
end

for tier = 1, 12 do
	for _, variant in { "", "Shiny", "Golden", "Rainbow", "Quantum" } do
		local jar = JarModel.build(tier, variant, roblox.Vector3.new(0, 10, 0))
		check(1 + parts(jar) <= 3, "jar part budget")
	end
end

print(failures == 0 and "smoke: ok" or string.format("smoke: %d failures", failures))
process.exit(failures == 0 and 0 or 1)
