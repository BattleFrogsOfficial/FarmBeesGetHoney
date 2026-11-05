--!strict
-- A hive: one anchored box (colored by tier) with its bee in front and the tier number on it.
-- Moving the box's CFrame moves the bee (it is welded), so tweens only touch the box.

local BeeModel = require(script.Parent.BeeModel)
local Visuals = require(script.Parent.Config.Visuals)
local Layout = require(script.Parent.Config.Layout)

local HiveModel = {}

-- `cf` faces out of the wall (LookVector toward the player).
function HiveModel.build(tier: number, cf: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "Hive"
	model:SetAttribute("Tier", tier)
	local size = Layout.slotSize - 0.2
	local box = Instance.new("Part")
	box.Name = "Box"
	box.Size = Vector3.new(size, size, size)
	box.CFrame = cf
	box.Anchored = true
	box.Color = Visuals.hive[tier]
	box.Material = if tier >= Visuals.hiveNeonTier then Enum.Material.Neon else Enum.Material.WoodPlanks
	box.TopSurface = Enum.SurfaceType.Smooth
	box.BottomSurface = Enum.SurfaceType.Smooth
	box.Parent = model
	model.PrimaryPart = box

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(100, 100)
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromOffset(34, 30)
	label.Position = UDim2.fromOffset(4, 2)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Text = tostring(tier)
	label.Parent = gui
	gui.Parent = box

	-- The bee sits on the front of the box, turned so you see it side-on.
	local beeOrigin = cf * CFrame.new(0, -0.2, -(size / 2 + 0.7)) * CFrame.Angles(0, math.rad(-65), 0)
	local bee = BeeModel.build(tier, beeOrigin)
	BeeModel.weldTo(bee, box)
	bee.Parent = model
	return model
end

return HiveModel
