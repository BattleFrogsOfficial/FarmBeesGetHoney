--!strict
-- A hive: a five-sided box (back, top, bottom, left, right; the front is open and faces the
-- conveyor) with floating text: the bee type in its color ("Basic" ... "Queen Bee") over a white
-- "Level N". An invisible anchored root at the box center carries the panels (welded), so tweens
-- only move the root. The bee itself is built and flown by each client (BeeController), so the
-- server replicates 6 parts per hive.

local Bees = require(script.Parent.Config.Bees)
local Visuals = require(script.Parent.Config.Visuals)
local Layout = require(script.Parent.Config.Layout)
local GameConfig = require(script.Parent.Config.Game)

local HiveModel = {}

HiveModel.WALL = 0.25 -- panel thickness

function HiveModel.inner(): number
	return (Layout.slotSize - 0.2) / 2 - HiveModel.WALL
end

local function panel(model: Model, root: BasePart, name: string, size: Vector3, cf: CFrame, tier: number): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = Visuals.hive[tier]
	p.Material = if tier >= Visuals.hiveNeonTier then Enum.Material.Neon else Enum.Material.WoodPlanks
	p.Anchored = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = p
	weld.Parent = p
	p.Parent = model
	return p
end

local function text(parent: Instance, y: number, height: number, value: string, color: Color3): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = UDim2.fromScale(0, y)
	l.Size = UDim2.fromScale(1, height)
	l.Font = Enum.Font.GothamBold
	l.TextScaled = true
	l.TextColor3 = color
	l.TextStrokeTransparency = 0.2
	l.TextStrokeColor3 = Color3.new(0, 0, 0)
	l.Text = value
	l.Parent = parent
	return l
end

-- `cf` is the box center, facing out of the open side (LookVector toward the conveyor).
function HiveModel.build(tier: number, cf: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "Hive"
	model:SetAttribute("Tier", tier)
	local size = Layout.slotSize - 0.2
	local half = size / 2
	local t = HiveModel.WALL

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(0.2, 0.2, 0.2)
	root.CFrame = cf
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.Transparency = 1
	root.Parent = model
	model.PrimaryPart = root

	-- In `cf`'s frame the open front is -z (LookVector); the back panel is at +z.
	panel(model, root, "Back", Vector3.new(size, size, t), cf * CFrame.new(0, 0, half - t / 2), tier)
	panel(model, root, "Top", Vector3.new(size, t, size), cf * CFrame.new(0, half - t / 2, 0), tier)
	panel(model, root, "Bottom", Vector3.new(size, t, size), cf * CFrame.new(0, -half + t / 2, 0), tier)
	panel(model, root, "Left", Vector3.new(t, size - 2 * t, size), cf * CFrame.new(-half + t / 2, 0, 0), tier)
	panel(model, root, "Right", Vector3.new(t, size - 2 * t, size), cf * CFrame.new(half - t / 2, 0, 0), tier)

	-- Floating text inside the box, toward its top: bee type (colored) over "Level N" (white).
	local bee = Bees.list[tier]
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromScale(size * 0.9, size * 0.32)
	gui.StudsOffsetWorldSpace = Vector3.new(0, half * 0.55, 0)
	gui.LightInfluence = 0
	gui.MaxDistance = GameConfig.hiveLabelDistance
	gui.AlwaysOnTop = false
	text(gui, 0, 0.55, bee.label, bee.color)
	text(gui, 0.55, 0.45, "Level " .. tier, Color3.new(1, 1, 1))
	gui.Parent = root
	return model
end

return HiveModel
