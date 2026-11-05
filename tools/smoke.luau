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

-- Plots don't overlap each other or the hub.
for i, a in plots do
	local pa = a.cframe.Position
	check(pa.Magnitude - Layout.plotSize / 2 > Layout.hubRadius + 10, "plot " .. i .. " clear of the hub")
	for j, b in plots do
		if i < j then
			check((pa - b.cframe.Position).Magnitude > Layout.plotSize * 1.1, "plots " .. i .. "/" .. j .. " apart")
		end
	end
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

-- Every tier's hive: bee within budget and inside its slot's footprint
local plot = plots[1]
for tier = 1, 12 do
	local cf = World.slotCFrame(plot, 45)
	local hive = HiveModel.build(tier, cf)
	local bee = hive:FindFirstChildOfClass("Model")
	local beeParts = parts(bee)
	check(beeParts < 20, string.format("tier %d bee has %d parts", tier, beeParts))
	local half = Layout.slotSize / 2
	for _, d in bee:GetDescendants() do
		if d:IsA("BasePart") then
			local p = cf:PointToObjectSpace(d.CFrame.Position)
			local r = math.max(d.Size.X, d.Size.Y, d.Size.Z) / 2
			check(
				math.abs(p.X) + r * 0.6 <= half + 0.4 and math.abs(p.Y) + r * 0.6 <= half + 0.6,
				string.format("tier %d bee part %s outside its slot (%.1f, %.1f)", tier, d.Name, p.X, p.Y)
			)
			check(d.Anchored == false and d:FindFirstChildOfClass("WeldConstraint") ~= nil, "bee part welded")
		end
	end
	print(string.format("tier %2d: hive %d parts", tier, parts(hive)))
end

for tier = 1, 12 do
	for _, variant in { "", "Shiny", "Golden", "Rainbow", "Quantum" } do
		local jar = JarModel.build(tier, variant, roblox.Vector3.new(0, 10, 0))
		check(1 + parts(jar) <= 3, "jar part budget")
	end
end

print(failures == 0 and "smoke: ok" or string.format("smoke: %d failures", failures))
process.exit(failures == 0 and 0 or 1)
