--!strict
-- Client-side plot touches: the E merge prompt on your wall ("Not your plot" on others), the
-- wide view of your wall while you stand on a Buy pad, and the beekeepers' idle animations.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Layout = require(ReplicatedStorage.Shared.Config.Layout)
local StateController = require(script.Parent.StateController)

local PlotController = {}

local player = Players.LocalPlayer :: Player
local prompts: { [Model]: ProximityPrompt } = {}
local merging = false

local function isMine(plot: Model): boolean
	return plot:GetAttribute("OwnerUserId") == player.UserId
end

local function refreshPrompts()
	local snap = StateController.snapshot
	for plot, prompt in prompts do
		if isMine(plot) then
			prompt.ActionText = "Merge hives"
			prompt.ObjectText = "Your wall"
			prompt.Enabled = snap ~= nil and snap.canMerge and not merging
		else
			prompt.ActionText = "Not your plot"
			prompt.ObjectText = ""
			prompt.Enabled = (plot:GetAttribute("OwnerUserId") or 0) ~= 0
		end
	end
end

local function addPrompt(plot: Model)
	local part = plot:WaitForChild("MergePrompt", 10) :: BasePart?
	if not part then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Layout.promptDistance
	prompt.RequiresLineOfSight = false
	prompt.Triggered:Connect(function()
		if isMine(plot) and not merging then
			merging = true
			refreshPrompts()
			Remotes.get("Merge"):FireServer()
			task.delay(1.5, function()
				merging = false
				refreshPrompts()
			end)
		end
	end)
	prompt.Parent = part
	prompts[plot] = prompt
	plot:GetAttributeChangedSignal("OwnerUserId"):Connect(refreshPrompts)
	refreshPrompts()
end

-- Wide wall view on a Buy pad
local viewing = false
local function myPlot(): Model?
	for plot in prompts do
		if isMine(plot) then
			return plot
		end
	end
	return nil
end

local function onBuyPad(plot: Model, position: Vector3): boolean
	local origin = plot:GetAttribute("Origin") :: CFrame?
	if not origin then
		return false
	end
	local p = origin:PointToObjectSpace(position)
	local half = Layout.padSize / 2
	for _, name in { "Buy1", "Buy5", "Buy25" } do
		local c = Layout.pads[name]
		if math.abs(p.X - c.X) <= half and math.abs(p.Z - c.Z) <= half and p.Y < Layout.padHeight then
			return true
		end
	end
	return false
end

local function updateCamera()
	local camera = workspace.CurrentCamera
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local plot = myPlot()
	local want = root ~= nil and plot ~= nil and onBuyPad(plot :: Model, (root :: BasePart).Position)
	if want and not viewing and plot then
		viewing = true
		local eye = plot:GetAttribute("WallViewEye") :: Vector3
		local at = plot:GetAttribute("WallViewAt") :: Vector3
		camera.CameraType = Enum.CameraType.Scriptable
		TweenService:Create(camera, TweenInfo.new(Layout.wallViewTween), { CFrame = CFrame.lookAt(eye, at) }):Play()
	elseif not want and viewing then
		viewing = false
		camera.CameraType = Enum.CameraType.Custom
	end
end

-- Beekeeper idle animations: wave, stretch, look around, wipe brow, every 4-8 s.
local function animateBeekeeper(npc: Model)
	local left = npc:WaitForChild("LeftArm") :: BasePart
	local right = npc:WaitForChild("RightArm") :: BasePart
	local head = npc:WaitForChild("Head") :: BasePart
	local headParts = {}
	for _, name in { "Head", "Veil", "HatBrim", "HatTop" } do
		local p = npc:FindFirstChild(name)
		if p and p:IsA("BasePart") then
			headParts[p] = p.CFrame
		end
	end
	local base = { [left] = left.CFrame, [right] = right.CFrame }
	local function shoulder(arm: BasePart): CFrame
		return base[arm] * CFrame.new(0, arm.Size.Y / 2 - 0.2, 0)
	end
	-- Rotates an arm about its shoulder; `x` raises it forward/up, `z` out to the side.
	local function pose(arm: BasePart, x: number, z: number, seconds: number)
		local pivot = shoulder(arm)
		local target = pivot * CFrame.Angles(math.rad(x), 0, math.rad(z)) * pivot:Inverse() * base[arm]
		TweenService:Create(arm, TweenInfo.new(seconds, Enum.EasingStyle.Sine), { CFrame = target }):Play()
	end
	local headBase = head.CFrame
	local function look(yaw: number, seconds: number)
		local pivot = headBase
		for part, cf in headParts do
			local target = pivot * CFrame.Angles(0, math.rad(yaw), 0) * pivot:Inverse() * cf
			TweenService:Create(part, TweenInfo.new(seconds, Enum.EasingStyle.Sine), { CFrame = target }):Play()
		end
	end
	local moves = {
		function() -- wave
			pose(right, 0, 160, 0.4)
			task.wait(0.4)
			for _ = 1, 3 do
				pose(right, 0, 135, 0.2)
				task.wait(0.2)
				pose(right, 0, 165, 0.2)
				task.wait(0.2)
			end
		end,
		function() -- stretch
			pose(left, 0, -170, 0.6)
			pose(right, 0, 170, 0.6)
			task.wait(1.2)
		end,
		function() -- look around
			look(40, 0.6)
			task.wait(0.8)
			look(-40, 0.8)
			task.wait(1)
		end,
		function() -- wipe brow
			pose(right, 140, -20, 0.5)
			task.wait(0.6)
			pose(right, 150, -35, 0.3)
			task.wait(0.4)
		end,
	}
	while npc.Parent do
		task.wait(4 + math.random() * 4)
		if not npc.Parent then
			break
		end
		moves[math.random(#moves)]()
		pose(left, 0, 0, 0.5)
		pose(right, 0, 0, 0.5)
		look(0, 0.5)
		task.wait(0.5)
	end
end

function PlotController.Init() end

function PlotController.Start()
	local map = workspace:WaitForChild("Map")
	local function watch(child: Instance)
		if child:IsA("Model") and string.sub(child.Name, 1, 4) == "Plot" then
			task.spawn(addPrompt, child)
			task.spawn(function()
				local npc = child:WaitForChild("Beekeeper", 10)
				if npc and npc:IsA("Model") then
					animateBeekeeper(npc)
				end
			end)
		end
	end
	for _, child in map:GetChildren() do
		watch(child)
	end
	map.ChildAdded:Connect(watch)
	StateController.Changed:Connect(refreshPrompts)
	RunService.Heartbeat:Connect(updateCamera)
end

return PlotController
