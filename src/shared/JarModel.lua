--!strict
-- A honey jar: a physics cylinder (rolls, never jams) with a welded lid, plus a tag or gem by tier
-- band and a tint + particles for a variant. At most 3 parts; the body is the assembly root.

local Visuals = require(script.Parent.Config.Visuals)

local JarModel = {}

local HEIGHT, WIDTH = 2.0, 1.5

local function band(tier: number)
	local chosen = Visuals.jarBands[1]
	for _, b in Visuals.jarBands do
		if tier >= b.from then
			chosen = b
		end
	end
	return chosen
end

local function attach(body: BasePart, p: BasePart)
	p.Anchored = false
	p.CanCollide = false
	p.Massless = true
	p.CanQuery = false
	p.CanTouch = false
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = body
	weld.Part1 = p
	weld.Parent = p
	p.Parent = body
end

local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
	ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 220, 60)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 220, 90)),
	ColorSequenceKeypoint.new(0.75, Color3.fromRGB(60, 140, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 70, 255)),
})

-- `position`: where the jar's center starts (upright). variant: "" or a variant id.
function JarModel.build(tier: number, variant: string, position: Vector3): BasePart
	local look = band(tier)
	local style = Visuals.variants[variant]
	local honey = if style then look.honey:Lerp(style.tint, 0.55) else look.honey

	-- A cylinder's axis is its x; turn it upright.
	local upright = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	local body = Instance.new("Part")
	body.Name = "Jar"
	body.Shape = Enum.PartType.Cylinder
	body.Size = Vector3.new(HEIGHT, WIDTH, WIDTH)
	body.CFrame = upright
	body.Color = honey
	body.Material = Enum.Material.Glass
	body.Transparency = 0.15
	body.CustomPhysicalProperties = PhysicalProperties.new(0.7, 1, 0, 1, 1)
	body.TopSurface = Enum.SurfaceType.Smooth
	body.BottomSurface = Enum.SurfaceType.Smooth
	body:SetAttribute("Tier", tier)
	body:SetAttribute("Variant", variant)

	local lid = Instance.new("Part")
	lid.Name = "Lid"
	lid.Shape = Enum.PartType.Cylinder
	lid.Size = Vector3.new(0.35, WIDTH + 0.1, WIDTH + 0.1)
	lid.CFrame = upright * CFrame.new(HEIGHT / 2 + 0.1, 0, 0)
	lid.Color = look.lid
	lid.Material = if tier >= 7 then Enum.Material.Foil else Enum.Material.SmoothPlastic
	attach(body, lid)

	if look.extra == "tag" then
		local tag = Instance.new("Part")
		tag.Name = "Tag"
		tag.Size = Vector3.new(0.7, 0.05, 0.5)
		tag.CFrame = upright * CFrame.new(0.1, 0, -WIDTH / 2 - 0.02) * CFrame.Angles(math.rad(90), 0, 0)
		tag.Color = Color3.fromRGB(245, 240, 225)
		tag.Material = Enum.Material.SmoothPlastic
		attach(body, tag)
	elseif look.extra == "gem" then
		local gem = Instance.new("Part")
		gem.Name = "Gem"
		gem.Shape = Enum.PartType.Ball
		gem.Size = Vector3.new(0.45, 0.45, 0.45)
		gem.CFrame = upright * CFrame.new(HEIGHT / 2 + 0.35, 0, 0)
		gem.Color = Color3.fromRGB(80, 220, 255)
		gem.Material = Enum.Material.Neon
		attach(body, gem)
	end

	if style then
		local fx = Instance.new("ParticleEmitter")
		fx.Name = "VariantFx"
		fx.Color = if style.rainbow then RAINBOW else ColorSequence.new(style.particle)
		fx.LightEmission = 0.6
		fx.Size = NumberSequence.new(0.25, 0)
		fx.Lifetime = NumberRange.new(0.4, 0.8)
		fx.Rate = if variant == "Quantum" then 40 else 14
		fx.Speed = NumberRange.new(1, 2)
		fx.SpreadAngle = Vector2.new(180, 180)
		fx.Parent = body
	end
	return body
end

return JarModel
