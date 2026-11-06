--!strict
-- Builds every hive's bee on this client and flies it around inside its box (BeeFlight). The
-- server only replicates the boxes; bees are local, anchored and moved with BulkMoveTo, and only
-- the ones within Game.beeAnimateDistance of the camera are animated each frame.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BeeModel = require(ReplicatedStorage.Shared.BeeModel)
local BeeFlight = require(ReplicatedStorage.Shared.BeeFlight)
local HiveModel = require(ReplicatedStorage.Shared.HiveModel)
local Styles = require(ReplicatedStorage.Shared.Config.BeeStyle)
local GameConfig = require(ReplicatedStorage.Shared.Config.Game)

local BeeController = {}

type Wing = { index: number, pivot: CFrame, rest: CFrame, side: number }
type Bee = {
	root: BasePart,
	model: Model,
	parts: { BasePart },
	offsets: { CFrame },
	wings: { Wing },
	range: BeeFlight.Range,
	seed: number,
}

local bees: { [Instance]: Bee } = {}
local folder: Folder
local seedCounter = 0

local function remove(hive: Instance)
	local bee = bees[hive]
	if bee then
		bees[hive] = nil
		bee.model:Destroy()
	end
end

local function add(hive: Instance)
	if bees[hive] or not hive:IsA("Model") then
		return
	end
	local root = hive:WaitForChild("Root", 10) :: BasePart?
	local tier = hive:GetAttribute("Tier") :: number?
	if not root or not tier or not hive.Parent then
		return
	end
	local style = Styles[tier]
	local model = BeeModel.build(tier, CFrame.identity)
	local parts, offsets, wings = {}, {}, {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			table.insert(parts, d)
			table.insert(offsets, d.CFrame) -- built at the identity, so this is the offset
			if d.Name == "Wing" then
				local side = if d.CFrame.Position.X > 0 then 1 else -1
				local s = style.scale
				table.insert(wings, {
					index = #parts,
					pivot = CFrame.new(0.15 * side * s, 0.55 * s, 0.25 * s),
					rest = d.CFrame,
					side = side,
				})
			end
		end
	end
	seedCounter += 1
	bees[hive] = {
		root = root,
		model = model,
		parts = parts,
		offsets = offsets,
		wings = wings,
		range = BeeFlight.range(style.scale, HiveModel.inner()),
		seed = seedCounter * 1.37 + tier,
	}
	model.Parent = folder
	-- Place it once right away, even if it is out of animation range.
	local cframes = table.create(#parts)
	for i, offset in offsets do
		cframes[i] = root.CFrame * offset
	end
	workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
end

local function watchHives(hives: Instance)
	for _, hive in hives:GetChildren() do
		task.spawn(add, hive)
	end
	hives.ChildAdded:Connect(function(hive)
		task.spawn(add, hive)
	end)
	hives.ChildRemoved:Connect(remove)
end

local function step()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local eye = camera.CFrame.Position
	local now = os.clock()
	local far = GameConfig.beeAnimateDistance
	local allParts, allFrames = {}, {}
	for hive, bee in bees do
		if not bee.root.Parent then
			remove(hive)
		elseif (bee.root.Position - eye).Magnitude <= far then
			local x, y, z, yaw, flap = BeeFlight.at(now, bee.seed, bee.range)
			local body = bee.root.CFrame * CFrame.new(x, y, z) * CFrame.Angles(0, yaw, 0)
			local frames = table.create(#bee.parts)
			for i, offset in bee.offsets do
				frames[i] = body * offset
			end
			for _, wing in bee.wings do
				local hinge = wing.pivot * CFrame.Angles(0, 0, flap * wing.side) * wing.pivot:Inverse()
				frames[wing.index] = body * hinge * wing.rest
			end
			table.move(bee.parts, 1, #bee.parts, #allParts + 1, allParts)
			table.move(frames, 1, #frames, #allFrames + 1, allFrames)
		end
	end
	if #allParts > 0 then
		workspace:BulkMoveTo(allParts, allFrames, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

function BeeController.Init()
	folder = Instance.new("Folder")
	folder.Name = "LocalBees"
	folder.Parent = workspace
end

function BeeController.Start()
	local map = workspace:WaitForChild("Map")
	local function watchPlot(child: Instance)
		if child:IsA("Model") and string.sub(child.Name, 1, 4) == "Plot" then
			task.spawn(function()
				local hives = child:WaitForChild("Hives", 10)
				if hives then
					watchHives(hives)
				end
			end)
		end
	end
	for _, child in map:GetChildren() do
		watchPlot(child)
	end
	map.ChildAdded:Connect(watchPlot)
	RunService.RenderStepped:Connect(step)
end

return BeeController
