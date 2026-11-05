--!strict
-- Builds a bee of any tier from primitive parts (Config/BeeStyle). The bee faces `origin`'s
-- LookVector, centered on its thorax. Parts are unanchored, massless and non-colliding so the bee
-- can be welded to a hive box and moved with it.

local Styles = require(script.Parent.Config.BeeStyle)

local BeeModel = {}

BeeModel.MAX_PARTS = 20

local function part(
	model: Model,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material
): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

local function ellipsoid(
	model: Model,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material
): BasePart
	local p = part(model, name, size, cf, color, material)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

-- Builds the bee for `tier` at `origin`. Returns the model; its PrimaryPart is the thorax.
function BeeModel.build(tier: number, origin: CFrame): Model
	local style = Styles[tier]
	assert(style, "no bee style for tier " .. tostring(tier))
	local s = style.scale
	local model = Instance.new("Model")
	model.Name = "Bee" .. tier
	local mat = style.material
	-- Local frame: -z is forward (the head), +y up, +x right.
	local function at(x: number, y: number, z: number): CFrame
		return origin * CFrame.new(x * s, y * s, z * s)
	end

	local thorax = ellipsoid(model, "Thorax", Vector3.new(1, 1, 1) * s, at(0, 0.05, 0), style.thorax, mat)
	thorax.Reflectance = style.reflectance
	model.PrimaryPart = thorax

	local abd = Vector3.new(1.3, 1.2, 1.7) * style.abdomen * s
	local abdZ = 1.05 + (abd.Z / s - 1.7) / 2
	local abdomen = ellipsoid(model, "Abdomen", abd, at(0, 0, abdZ), style.body, mat)
	abdomen.Reflectance = style.reflectance
	-- Stripes: thin bands around the abdomen, sized to its cross-section where they sit.
	local half = abd.Z / 2
	for i = 1, style.stripes do
		local d = (i - (style.stripes + 1) / 2) * 0.42 * s
		local k = math.sqrt(math.max(0.2, 1 - (d / half) ^ 2)) * 1.06
		ellipsoid(
			model,
			"Stripe",
			Vector3.new(abd.X * k, abd.Y * k, 0.24 * s),
			at(0, 0, abdZ + d / s),
			style.stripe,
			mat
		)
	end
	ellipsoid(
		model,
		"Stinger",
		Vector3.new(0.18, 0.18, 0.5) * s,
		at(0, -0.05, abdZ + abd.Z / s / 2 + 0.1),
		style.stripe,
		mat
	)

	local head = ellipsoid(model, "Head", Vector3.new(0.82, 0.8, 0.78) * s, at(0, 0.05, -0.78), style.head, mat)
	head.Reflectance = style.reflectance
	for _, side in { -1, 1 } do
		local eye = ellipsoid(
			model,
			"Eye",
			Vector3.new(0.24, 0.36, 0.26) * s,
			at(0.3 * side, 0.12, -1.0),
			style.eye,
			Enum.Material.SmoothPlastic
		)
		eye.Reflectance = 0.3
		part(
			model,
			"Antenna",
			Vector3.new(0.07, 0.07, 0.62) * s,
			at(0.18 * side, 0.55, -1.08) * CFrame.Angles(math.rad(-50), math.rad(-15 * side), 0),
			style.head,
			Enum.Material.SmoothPlastic
		)
		local wing = part(
			model,
			"Wing",
			Vector3.new(1.4, 0.05, 0.85) * s,
			at(0.72 * side, 0.58, 0.25) * CFrame.Angles(0, math.rad(12 * side), math.rad(18 * side)),
			style.wing,
			Enum.Material.SmoothPlastic
		)
		wing.Transparency = style.wingTransparency
	end

	for _, extra in style.extras do
		if extra == "leaf" then
			ellipsoid(
				model,
				"Leaf",
				Vector3.new(1.2, 0.06, 0.7) * s,
				at(0, -0.5, -1.1) * CFrame.Angles(0, 0, math.rad(10)),
				Color3.fromRGB(70, 170, 60),
				Enum.Material.SmoothPlastic
			)
		elseif extra == "hardhat" then
			local yellow = Color3.fromRGB(250, 200, 30)
			ellipsoid(
				model,
				"HardHat",
				Vector3.new(0.9, 0.55, 0.9) * s,
				at(0, 0.42, -0.78),
				yellow,
				Enum.Material.SmoothPlastic
			)
			local brim = part(
				model,
				"HatBrim",
				Vector3.new(0.08, 1.15, 1.15) * s,
				at(0, 0.3, -0.78) * CFrame.Angles(0, 0, math.rad(90)),
				yellow,
				Enum.Material.SmoothPlastic
			)
			brim.Shape = Enum.PartType.Cylinder
		elseif extra == "tongue" then
			part(
				model,
				"Tongue",
				Vector3.new(0.06, 0.06, 0.7) * s,
				at(0, -0.3, -1.4) * CFrame.Angles(math.rad(25), 0, 0),
				Color3.fromRGB(60, 30, 80),
				Enum.Material.SmoothPlastic
			)
		elseif extra == "spikes" then
			for i = 1, 4 do
				part(
					model,
					"Spike",
					Vector3.new(0.22, 0.22, 0.22) * s,
					at(0, abd.Y / s / 2 + 0.05, abdZ - 0.6 + i * 0.3) * CFrame.Angles(math.rad(45), 0, math.rad(45)),
					style.stripe,
					Enum.Material.SmoothPlastic
				)
			end
		elseif extra == "armor" then
			local metal = Color3.fromRGB(150, 155, 165)
			part(model, "Armor", Vector3.new(1.1, 0.14, 0.9) * s, at(0, 0.52, 0), metal, Enum.Material.Metal)
			part(model, "Armor", Vector3.new(1.2, 0.14, 1.0) * s, at(0, 0.6, abdZ), metal, Enum.Material.Metal)
			ellipsoid(model, "Helmet", Vector3.new(0.88, 0.5, 0.84) * s, at(0, 0.3, -0.78), metal, Enum.Material.Metal)
		elseif extra == "cape" then
			part(
				model,
				"Cape",
				Vector3.new(1.25, 0.08, 1.7) * s,
				at(0, 0.66, 0.75) * CFrame.Angles(math.rad(-8), 0, 0),
				Color3.fromRGB(170, 30, 40),
				Enum.Material.Fabric
			)
		elseif extra == "crest" then
			part(
				model,
				"Crest",
				Vector3.new(0.08, 0.4, 0.55) * s,
				at(0, 0.55, -0.72),
				Color3.fromRGB(240, 190, 40),
				Enum.Material.Foil
			)
		elseif extra == "crown" then
			local gold = Color3.fromRGB(245, 195, 40)
			local ring = part(
				model,
				"Crown",
				Vector3.new(0.25, 0.7, 0.7) * s,
				at(0, 0.5, -0.78) * CFrame.Angles(0, 0, math.rad(90)),
				gold,
				Enum.Material.Foil
			)
			ring.Shape = Enum.PartType.Cylinder
			for i = 1, 3 do
				local a = (i - 2) * 0.45
				part(
					model,
					"CrownSpike",
					Vector3.new(0.12, 0.3, 0.12) * s,
					at(math.sin(a) * 0.3, 0.75, -0.78 - math.cos(a) * 0.3 + 0.1),
					gold,
					Enum.Material.Foil
				)
			end
			local gem = ellipsoid(
				model,
				"CrownGem",
				Vector3.new(0.14, 0.14, 0.14) * s,
				at(0, 0.55, -1.12),
				Color3.fromRGB(230, 40, 80),
				Enum.Material.Neon
			)
			gem.CastShadow = false
		elseif extra == "glow" then
			local light = Instance.new("PointLight")
			light.Range = 8
			light.Brightness = 0.5
			light.Color = Color3.fromRGB(255, 220, 120)
			light.Parent = thorax
		end
	end
	return model
end

-- Welds every part of a bee to `root` (anchored or not) so it moves with it.
function BeeModel.weldTo(model: Model, root: BasePart)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = d
			weld.Parent = d
		end
	end
end

return BeeModel
