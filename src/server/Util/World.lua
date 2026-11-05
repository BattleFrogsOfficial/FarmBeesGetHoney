--!strict
-- Builds the map in code: a hub with six plots in a ring, each joined by a bridge. Every plot has
-- the hive wall, the conveyor behind it, the pads, the beekeeper stand, the processor and a flag.
-- Geometry lives in Config/Layout (plot-local coordinates), colors in Config/Visuals.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Layout = require(ReplicatedStorage.Shared.Config.Layout)
local Visuals = require(ReplicatedStorage.Shared.Config.Visuals)
local Wall = require(ReplicatedStorage.Shared.Wall)

local World = {}

export type Pad = { name: string, part: BasePart, title: TextLabel, detail: TextLabel, center: Vector3 }
export type Plot = {
	index: number,
	cframe: CFrame, -- plot center on the ground; local +z points to the hub
	model: Model,
	hives: Folder,
	jars: Folder,
	pads: { [string]: Pad },
	pickupLabel: TextLabel,
	processorLabel: TextLabel,
	honeyLevel: BasePart,
	flag: BasePart,
	flagLabels: { TextLabel },
	ownerLabel: TextLabel,
	promptPart: BasePart,
	beltA: BasePart,
	beltB: BasePart,
}

local ROT180 = CFrame.Angles(0, math.pi, 0)

local function block(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function label(gui: SurfaceGui, position: UDim2, size: UDim2, text: string, color: Color3?): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = position
	l.Size = size
	l.Font = Enum.Font.GothamBold
	l.TextScaled = true
	l.TextColor3 = color or Visuals.signText
	l.Text = text
	l.Parent = gui
	return l
end

local function surface(part: BasePart, face: Enum.NormalId, pixelsPerStud: number?): SurfaceGui
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = pixelsPerStud or 40
	gui.LightInfluence = 0
	gui.Parent = part
	return gui
end

-- A flat sign; `cf` faces its readers (its Front face points along LookVector).
local function sign(parent: Instance, name: string, size: Vector3, cf: CFrame, text: string): (Part, TextLabel)
	local board = block(parent, name, size, cf, Visuals.signBoard)
	board.CanCollide = false
	local gui = surface(board, Enum.NormalId.Front)
	local l = label(gui, UDim2.fromScale(0.04, 0.08), UDim2.fromScale(0.92, 0.84), text)
	return board, l
end

-- Plot-local point -> world CFrame facing the hub side (+z local).
local function front(plot: CFrame, x: number, y: number, z: number): CFrame
	return plot * CFrame.new(x, y, z) * ROT180
end

-- A box between two plot-local corners (x/z) with a given bottom and height.
local function span(
	parent: Instance,
	name: string,
	plot: CFrame,
	a: Vector3,
	b: Vector3,
	bottom: number,
	height: number,
	color: Color3,
	material: Enum.Material?
): Part
	local size = Vector3.new(math.abs(b.X - a.X), height, math.abs(b.Z - a.Z))
	local center = Vector3.new((a.X + b.X) / 2, bottom + height / 2, (a.Z + b.Z) / 2)
	return block(parent, name, size, plot * CFrame.new(center), color, material)
end

function World.slotCFrame(plot: Plot, index: number): CFrame
	local column, row = Wall.position(index)
	local x = (column - 5.5) * Layout.slotSize
	local y = Layout.platform.height + (row - 0.5) * Layout.slotSize
	return front(plot.cframe, x, y, Layout.wallZ)
end

function World.toWorld(plot: Plot, v: Vector3): Vector3
	return plot.cframe:PointToWorldSpace(v)
end

function World.toLocal(plot: Plot, v: Vector3): Vector3
	return plot.cframe:PointToObjectSpace(v)
end

function World.isOnPad(plot: Plot, pad: Pad, position: Vector3): boolean
	local p = World.toLocal(plot, position)
	local half = Layout.padSize / 2
	return math.abs(p.X - pad.center.X) <= half
		and math.abs(p.Z - pad.center.Z) <= half
		and p.Y >= -1
		and p.Y <= Layout.padHeight
end

function World.isOnPlot(plot: Plot, position: Vector3): boolean
	local p = World.toLocal(plot, position)
	local half = Layout.plotSize / 2
	return math.abs(p.X) <= half and math.abs(p.Z) <= half and p.Y > -10 and p.Y < 80
end

-- Where a hive's jar appears: on the belt right in front of its column.
function World.jarSpawn(plot: Plot, index: number): Vector3
	local column = Wall.position(index)
	local x = (column - 5.5) * Layout.slotSize
	local z = (Layout.beltA.from.Z + Layout.beltA.to.Z) / 2
	return World.toWorld(plot, Vector3.new(x, Layout.beltTop + 1.3, z))
end

function World.beltDone(plot: Plot, position: Vector3): boolean
	local p = World.toLocal(plot, position)
	return p.Z > Layout.beltEndZ or p.Y < -8
end

local function buildBeekeeper(parent: Instance, base: CFrame): Model
	local npc = Instance.new("Model")
	npc.Name = "Beekeeper"
	local suit = Color3.fromRGB(240, 240, 232)
	local skin = Color3.fromRGB(234, 190, 150)
	local function at(x: number, y: number, z: number): CFrame
		return base * CFrame.new(x, y, z)
	end
	for _, side in { -1, 1 } do
		block(npc, "Leg", Vector3.new(0.9, 2.2, 0.9), at(0.5 * side, 1.1, 0), suit)
	end
	local torso = block(npc, "Torso", Vector3.new(2, 2.2, 1.1), at(0, 3.3, 0), suit)
	npc.PrimaryPart = torso
	block(npc, "LeftArm", Vector3.new(0.75, 2.1, 0.75), at(-1.4, 3.3, 0), suit)
	block(npc, "RightArm", Vector3.new(0.75, 2.1, 0.75), at(1.4, 3.3, 0), suit)
	local head = block(npc, "Head", Vector3.new(1.3, 1.3, 1.3), at(0, 5.05, 0), skin)
	head.Shape = Enum.PartType.Ball
	local veil = block(
		npc,
		"Veil",
		Vector3.new(1.3, 1.9, 1.9),
		at(0, 5.1, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(40, 40, 40)
	)
	veil.Shape = Enum.PartType.Cylinder
	veil.Transparency = 0.65
	veil.CanCollide = false
	local brim =
		block(npc, "HatBrim", Vector3.new(0.15, 2.8, 2.8), at(0, 5.85, 0) * CFrame.Angles(0, 0, math.rad(90)), suit)
	brim.Shape = Enum.PartType.Cylinder
	local crown =
		block(npc, "HatTop", Vector3.new(0.7, 1.4, 1.4), at(0, 6.2, 0) * CFrame.Angles(0, 0, math.rad(90)), suit)
	crown.Shape = Enum.PartType.Cylinder
	for _, d in npc:GetChildren() do
		if d:IsA("BasePart") then
			d.CanCollide = false
		end
	end
	npc.Parent = parent
	return npc
end

local function buildPlot(index: number, parent: Instance): Plot
	local angle = (index - 1) * (2 * math.pi / Layout.plotCount)
	local center = Vector3.new(math.cos(angle) * Layout.ringRadius, 0, math.sin(angle) * Layout.ringRadius)
	local outward = center.Unit
	local P = CFrame.lookAt(center, center + outward) -- LookVector away from the hub: local +z = toward it
	local model = Instance.new("Model")
	model.Name = "Plot" .. index
	model:SetAttribute("Index", index)
	model:SetAttribute("OwnerUserId", 0)
	model:SetAttribute("WallViewEye", P:PointToWorldSpace(Layout.wallViewEye))
	model:SetAttribute("WallViewAt", P:PointToWorldSpace(Layout.wallViewAt))
	model:SetAttribute("Origin", P)

	local size = Layout.plotSize
	local ground = block(
		model,
		"Ground",
		Vector3.new(size, Layout.groundThickness, size),
		P * CFrame.new(0, -Layout.groundThickness / 2, 0),
		Visuals.ground,
		Enum.Material.Grass
	)
	model.PrimaryPart = ground

	-- Hive platform: the boxes stack on it (no wall behind them)
	local pf = Layout.platform
	span(model, "HivePlatform", P, pf.from, pf.to, 0, pf.height, Visuals.platform, Enum.Material.Concrete)
	local promptPart =
		block(model, "MergePrompt", Vector3.new(1, 1, 1), P * CFrame.new(Layout.promptPoint), Color3.new(1, 1, 1))
	promptPart.Transparency = 1
	promptPart.CanCollide = false
	promptPart.CanQuery = false

	-- Conveyor
	local A, B = Layout.beltA, Layout.beltB
	local beltA = span(model, "BeltA", P, A.from, A.to, 0, Layout.beltTop, Visuals.belt)
	beltA.AssemblyLinearVelocity = P.RightVector * Layout.beltSpeed
	local beltB = span(model, "BeltB", P, B.from, B.to, 0, Layout.beltTop, Visuals.belt)
	beltB.AssemblyLinearVelocity = -P.LookVector * Layout.beltSpeed
	local railH, railT = 2.5, 0.5
	local top = Layout.beltTop
	-- Belt A's rails stay low so the bottom row of hives shows over them.
	local function rail(a: Vector3, b: Vector3, height: number?)
		local r = span(model, "BeltRail", P, a, b, top, height or railH, Visuals.beltRail, Enum.Material.Metal)
		r.Transparency = 0.3
	end
	local low = 1.5
	rail(Vector3.new(A.from.X - railT, 0, A.from.Z - railT), Vector3.new(B.to.X + railT, 0, A.from.Z), low) -- hive side
	rail(Vector3.new(A.from.X, 0, A.to.Z), Vector3.new(A.to.X, 0, A.to.Z + railT), low) -- player side
	rail(Vector3.new(A.from.X - railT, 0, A.from.Z), Vector3.new(A.from.X, 0, A.to.Z + railT), low) -- left end
	rail(Vector3.new(B.to.X, 0, B.from.Z), Vector3.new(B.to.X + railT, 0, B.to.Z)) -- outer side of B
	rail(Vector3.new(B.from.X - railT, 0, A.to.Z), Vector3.new(B.from.X, 0, B.to.Z)) -- inner side of B
	span(
		model,
		"Bin",
		P,
		Vector3.new(B.from.X, 0, B.to.Z),
		Vector3.new(B.to.X, 0, B.to.Z + 3),
		0,
		0.6,
		Visuals.beltRail,
		Enum.Material.Metal
	)

	-- Pads
	local pads: { [string]: Pad } = {}
	local padTitles = {
		Buy1 = "BUY 1",
		Buy5 = "BUY 5",
		Buy25 = "BUY 25",
		Pickup = "PICK UP HONEY",
		Sell = "HAND IN HONEY",
		Upgrade = "UPGRADE PROCESSOR",
		Prestige = "PRESTIGE",
	}
	for name, c in Layout.pads do
		local part = block(
			model,
			"Pad_" .. name,
			Vector3.new(Layout.padSize, 0.4, Layout.padSize),
			P * CFrame.new(c.X, 0.2, c.Z),
			Visuals.pad[name]
		)
		part:SetAttribute("Pad", name)
		local board = block(
			model,
			"PadSign_" .. name,
			Vector3.new(Layout.padSize, 3, 0.3),
			front(P, c.X, 5.2, c.Z - Layout.padSize / 2 - 0.4),
			Visuals.signBoard
		)
		board.CanCollide = false
		local gui = surface(board, Enum.NormalId.Front)
		local title = label(gui, UDim2.fromScale(0.04, 0.04), UDim2.fromScale(0.92, 0.42), padTitles[name])
		local detail = label(gui, UDim2.fromScale(0.04, 0.5), UDim2.fromScale(0.92, 0.44), "")
		pads[name] = { name = name, part = part, title = title, detail = detail, center = c }
	end
	local _, pickupLabel = sign(
		model,
		"PickupCounter",
		Vector3.new(9, 2, 0.3),
		front(P, Layout.pads.Pickup.X, 8.6, Layout.pads.Pickup.Z - Layout.padSize / 2 - 0.4),
		"Honey: 0 — walk here"
	)

	-- Beekeeper stand
	local bk = Layout.beekeeper
	block(
		model,
		"Counter",
		Vector3.new(10, 3, 2.5),
		P * CFrame.new(bk.X, 1.5, bk.Z),
		Color3.fromRGB(170, 120, 70),
		Enum.Material.WoodPlanks
	)
	block(
		model,
		"StandRoof",
		Vector3.new(11, 0.5, 7),
		P * CFrame.new(bk.X, 9, bk.Z - 2.5),
		Color3.fromRGB(240, 190, 50)
	)
	for _, sx in { -5, 5 } do
		block(
			model,
			"StandPost",
			Vector3.new(0.5, 9, 0.5),
			P * CFrame.new(bk.X + sx, 4.5, bk.Z - 0.8),
			Color3.fromRGB(150, 100, 60),
			Enum.Material.WoodPlanks
		)
	end
	sign(model, "StandSign", Vector3.new(8, 1.6, 0.3), front(P, bk.X, 10.2, bk.Z + 0.9), "BEEKEEPER")
	buildBeekeeper(model, front(P, bk.X, 0, bk.Z - 3))

	-- Processor
	local pr = Layout.processor
	block(
		model,
		"Processor",
		Vector3.new(8, 6, 6),
		P * CFrame.new(pr.X, 3, pr.Z),
		Color3.fromRGB(150, 155, 165),
		Enum.Material.Metal
	)
	local hopper = block(
		model,
		"Hopper",
		Vector3.new(6, 2, 4),
		P * CFrame.new(pr.X, 7, pr.Z) * CFrame.Angles(0, 0, 0),
		Color3.fromRGB(120, 125, 135),
		Enum.Material.Metal
	)
	hopper.Shape = Enum.PartType.Block
	local glass = block(
		model,
		"Window",
		Vector3.new(6, 4.2, 0.2),
		P * CFrame.new(pr.X, 3, pr.Z + 3.05),
		Color3.fromRGB(200, 230, 255),
		Enum.Material.Glass
	)
	glass.Transparency = 0.6
	local honeyLevel = block(
		model,
		"HoneyLevel",
		Vector3.new(5.6, 0.1, 0.3),
		P * CFrame.new(pr.X, 1, pr.Z + 2.8),
		Color3.fromRGB(240, 170, 30),
		Enum.Material.SmoothPlastic
	)
	honeyLevel.CanCollide = false
	local _, processorLabel =
		sign(model, "ProcessorReadout", Vector3.new(10, 2, 0.3), front(P, pr.X, 10, pr.Z + 1), "Queue: 0 honey — 1/s")

	-- Flag
	local fl = Layout.flag
	local pole = block(
		model,
		"FlagPole",
		Vector3.new(14, 0.5, 0.5),
		P * CFrame.new(fl.X, 7, fl.Z) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(200, 200, 200),
		Enum.Material.Metal
	)
	pole.Shape = Enum.PartType.Cylinder
	local flag = block(
		model,
		"Flag",
		Vector3.new(4, 2.6, 0.15),
		P * CFrame.new(fl.X + 2.25, 12.6, fl.Z),
		Visuals.flagColors[1],
		Enum.Material.Fabric
	)
	flag.CanCollide = false
	local flagLabels = {}
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		table.insert(
			flagLabels,
			label(surface(flag, face), UDim2.fromScale(0.05, 0.1), UDim2.fromScale(0.9, 0.8), "P0")
		)
	end

	local _, ownerLabel = sign(
		model,
		"OwnerSign",
		Vector3.new(12, 2.5, 0.4),
		front(P, Layout.ownerSign.X, 3.2, Layout.ownerSign.Z),
		"FREE PLOT"
	)

	local hives = Instance.new("Folder")
	hives.Name = "Hives"
	hives.Parent = model
	local jars = Instance.new("Folder")
	jars.Name = "Jars"
	jars.Parent = model
	model.Parent = parent

	return {
		index = index,
		cframe = P,
		model = model,
		hives = hives,
		jars = jars,
		pads = pads,
		pickupLabel = pickupLabel,
		processorLabel = processorLabel,
		honeyLevel = honeyLevel,
		flag = flag,
		flagLabels = flagLabels,
		ownerLabel = ownerLabel,
		promptPart = promptPart,
		beltA = beltA,
		beltB = beltB,
	}
end

export type Hub = { leaderboard: TextLabel, shopBoard: BasePart }

local function buildHub(parent: Instance): Hub
	local hub = Instance.new("Model")
	hub.Name = "Hub"
	local disk = block(
		hub,
		"HubFloor",
		Vector3.new(4, Layout.hubRadius * 2, Layout.hubRadius * 2),
		CFrame.new(0, -2, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Visuals.hub,
		Enum.Material.Cobblestone
	)
	disk.Shape = Enum.PartType.Cylinder
	hub.PrimaryPart = disk

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 0.4, 8)
	spawn.CFrame = CFrame.new(0, 0.2, 0)
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = Color3.fromRGB(240, 200, 60)
	spawn.Parent = hub

	-- Boards sit between bridges, facing the hub center.
	local function boardAt(degrees: number): CFrame
		local a = math.rad(degrees)
		local pos = Vector3.new(math.cos(a) * (Layout.hubRadius - 8), 6, math.sin(a) * (Layout.hubRadius - 8))
		return CFrame.lookAt(pos, Vector3.new(0, 6, 0))
	end
	local shopBoard, _ = sign(
		hub,
		"ShopBoard",
		Vector3.new(14, 8, 0.5),
		boardAt(30),
		"PASS SHOP\n2x Money · Auto Collect · Lucky Jars\nPress E here or SHOP (bottom right)"
	)
	shopBoard.CanCollide = true
	local board, leaderboard = sign(hub, "Leaderboard", Vector3.new(14, 12, 0.5), boardAt(210), "TOP HONEY\n(loading)")
	board.CanCollide = true
	leaderboard.TextYAlignment = Enum.TextYAlignment.Top
	hub.Parent = parent
	return { leaderboard = leaderboard, shopBoard = shopBoard }
end

local function buildBridge(parent: Instance, plot: Plot)
	local center = plot.cframe.Position
	local dir = center.Unit
	local from = dir * (Layout.hubRadius - 2)
	local to = center - dir * (Layout.plotSize / 2 - 2)
	local length = (to - from).Magnitude
	local mid = (from + to) / 2
	local cf = CFrame.lookAt(Vector3.new(mid.X, -0.55, mid.Z), Vector3.new(to.X, -0.55, to.Z))
	block(
		parent,
		"Bridge" .. plot.index,
		Vector3.new(Layout.bridgeWidth, 1, length),
		cf,
		Visuals.bridge,
		Enum.Material.WoodPlanks
	)
	for _, side in { -1, 1 } do
		block(
			parent,
			"BridgeRail",
			Vector3.new(0.6, 3, length),
			cf * CFrame.new(side * (Layout.bridgeWidth / 2 - 0.3), 2, 0),
			Visuals.rail,
			Enum.Material.WoodPlanks
		)
	end
end

-- Builds everything under workspace.Map. Returns the plots (index order) and the hub.
function World.build(parent: Instance): ({ Plot }, Hub)
	local map = Instance.new("Folder")
	map.Name = "Map"
	local hub = buildHub(map)
	local plots = {}
	for i = 1, Layout.plotCount do
		local plot = buildPlot(i, map)
		buildBridge(map, plot)
		table.insert(plots, plot)
	end
	map.Parent = parent
	return plots, hub
end

return World
