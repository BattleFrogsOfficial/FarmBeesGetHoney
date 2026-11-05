--!strict
-- A hive: a five-sided box (back, top, bottom, left, right; the front is open and faces the
-- conveyor) with its bee living inside, and the tier number on the back wall. An invisible
-- anchored root at the box center carries everything (welded), so tweens only move the root.

local BeeModel = require(script.Parent.BeeModel)
local Styles = require(script.Parent.Config.BeeStyle)
local Visuals = require(script.Parent.Config.Visuals)
local Layout = require(script.Parent.Config.Layout)

local HiveModel = {}

HiveModel.WALL = 0.25 -- panel thickness

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
	local back = panel(model, root, "Back", Vector3.new(size, size, t), cf * CFrame.new(0, 0, half - t / 2), tier)
	panel(model, root, "Top", Vector3.new(size, t, size), cf * CFrame.new(0, half - t / 2, 0), tier)
	panel(model, root, "Bottom", Vector3.new(size, t, size), cf * CFrame.new(0, -half + t / 2, 0), tier)
	panel(model, root, "Left", Vector3.new(t, size - 2 * t, size), cf * CFrame.new(-half + t / 2, 0, 0), tier)
	panel(model, root, "Right", Vector3.new(t, size - 2 * t, size), cf * CFrame.new(half - t / 2, 0, 0), tier)

	-- Tier number on the inside of the back wall, top-left (seen through the open front).
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(100, 100)
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromOffset(30, 26)
	label.Position = UDim2.fromOffset(6, 6)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Text = tostring(tier)
	label.Parent = gui
	gui.Parent = back -- the back panel's Front face looks into the box, out through the opening

	-- The bee lives inside, turned side-on so you see its profile, centered on its body length.
	local s = Styles[tier].scale
	local floor = -half + t
	local beeOrigin = cf
		* CFrame.new(0, floor + 0.75 * s + 0.15, 0.2)
		* CFrame.Angles(0, math.rad(-72), 0)
		* CFrame.new(0, 0, -0.5 * s)
	local bee = BeeModel.build(tier, beeOrigin)
	BeeModel.weldTo(bee, root)
	bee.Parent = model
	return model
end

return HiveModel
