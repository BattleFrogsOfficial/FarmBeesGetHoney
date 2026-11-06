-- Builds the real world under Lune, fills plot 1 with a showcase wall (every tier, jars on the
-- belt) and exports the parts for render.mjs:
--   lune run tools/preview/export -- build/FarmBeesGetHoney.rbxl build/scene.json
--   node tools/preview/render.mjs build/scene.json build/shots
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local args = {}
for _, a in process.args do
	if a ~= "--" then
		table.insert(args, a)
	end
end
local placePath, outPath = args[1] or "build/FarmBeesGetHoney.rbxl", args[2] or "build/scene.json"
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

local RS = game.ReplicatedStorage
local World = requireModule(game.ServerScriptService.Server.Util.World)
local HiveModel = requireModule(RS.Shared.HiveModel)
local JarModel = requireModule(RS.Shared.JarModel)
local Layout = requireModule(RS.Shared.Config.Layout)
local plots = World.build(workspace)
local plot = plots[1]
-- Showcase wall: each tier twice along the bottom rows, then Tier 1s filling the rest of row 3-4.
local hives = {}
for tier = 1, 12 do
	table.insert(hives, tier)
	table.insert(hives, tier)
end
for _ = 1, 16 do
	table.insert(hives, 1)
end
local BeeFlightP = requireModule(RS.Shared.BeeFlight)
local BeeModelP = requireModule(RS.Shared.BeeModel)
local StylesP = requireModule(RS.Shared.Config.BeeStyle)
for i, tier in hives do
	local cf = World.slotCFrame(plot, i)
	HiveModel.build(tier, cf).Parent = plot.hives
	-- The bee where the client would fly it at t = 3 (clients build bees; the server doesn't).
	local x, y, z, yaw = BeeFlightP.at(3, i * 1.37 + tier, BeeFlightP.range(StylesP[tier].scale, HiveModel.inner()))
	BeeModelP.build(tier, cf * roblox.CFrame.new(x, y, z) * roblox.CFrame.Angles(0, yaw, 0)).Parent = plot.hives
end
-- Jars along the belt: every band and variant
local variants = { "", "Shiny", "Golden", "Rainbow", "Quantum" }
for i = 1, 12 do
	local p = World.jarSpawn(plot, ((i - 1) % 10) + 1)
	local offset = roblox.Vector3.new(0, -1.3 + 1.0, 0)
	JarModel.build(
		i,
		variants[(i % 5) + 1],
		p + offset + (if i > 10 then roblox.Vector3.new(0, 0, 0) else roblox.Vector3.new(0, 0, 0))
	).Parent =
		plot.jars
end
plot.ownerLabel.Text = "PLAYER'S FARM"

-- A bee lineup on the hub for a close look: tiers 1-12, side-on.
local BeeModel = requireModule(RS.Shared.BeeModel)
for tier = 1, 12 do
	local origin = roblox.CFrame.new(-24 + tier * 3.8 - 1.9, 3, 12) * roblox.CFrame.Angles(0, math.rad(-90), 0)
	BeeModel.build(tier, origin).Parent = workspace
end

local parts = {}
local function colorHex(c)
	return string.format(
		"#%02x%02x%02x",
		math.floor(c.R * 255 + 0.5),
		math.floor(c.G * 255 + 0.5),
		math.floor(c.B * 255 + 0.5)
	)
end
for _, inst in workspace:GetDescendants() do
	if inst:IsA("BasePart") and inst.Transparency < 1 then
		local kind = if inst:IsA("Part") then inst.Shape.Name else "Block"
		local mesh = inst:FindFirstChildOfClass("SpecialMesh")
		if mesh and mesh.MeshType == roblox.Enum.MeshType.Sphere then
			kind = "Ellipsoid"
		end
		table.insert(parts, {
			kind = kind,
			size = { inst.Size.X, inst.Size.Y, inst.Size.Z },
			cf = { inst.CFrame:GetComponents() },
			color = colorHex(inst.Color),
			material = inst.Material.Name,
			transparency = inst.Transparency,
			reflectance = inst.Reflectance,
		})
	end
end
local texts = {}
for _, gui in workspace:GetDescendants() do
	if gui:IsA("SurfaceGui") then
		local part = gui.Parent
		for _, label in gui:GetChildren() do
			if label:IsA("TextLabel") and part and part:IsA("BasePart") and label.Text ~= "" then
				table.insert(texts, {
					face = gui.Face.Name,
					text = label.Text,
					color = colorHex(label.TextColor3),
					rotation = 0,
					size = { part.Size.X, part.Size.Y, part.Size.Z },
					cf = { part.CFrame:GetComponents() },
				})
				break
			end
		end
	end
end
fs.writeFile(outPath, serde.encode("json", { parts = parts, texts = texts }))
print(string.format("exported %d parts", #parts))
