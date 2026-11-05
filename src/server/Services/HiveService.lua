--!strict
-- The hive wall: Buy pads, merging (E prompt / Merge intent / Auto Merge), Auto Buy, and the hive
-- models with their drop-in and merge animations. Also owns each hive's jar timer.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local World = require(script.Parent.Parent.Util.World)
local Net = require(script.Parent.Parent.Util.Net)
local Belt = require(ReplicatedStorage.Shared.Belt)
local Format = require(ReplicatedStorage.Shared.Format)
local HiveModel = require(ReplicatedStorage.Shared.HiveModel)
local Merge = require(ReplicatedStorage.Shared.Merge)
local Perks = require(ReplicatedStorage.Shared.Perks)
local Shop = require(ReplicatedStorage.Shared.Shop)
local Wall = require(ReplicatedStorage.Shared.Wall)
local Bees = require(ReplicatedStorage.Shared.Config.Bees)
local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Layout = require(ReplicatedStorage.Shared.Config.Layout)
local Types = require(ReplicatedStorage.Shared.Types)

local HiveService = {}

type State = { models: { Model }, timers: { number }, busy: boolean }
local states: { [Player]: State } = {}
local rng = Random.new()

function HiveService.timers(player: Player): { number }?
	local s = states[player]
	return s and s.timers
end

function HiveService.busy(player: Player): boolean
	local s = states[player]
	return s ~= nil and s.busy
end

local function interval(player: Player): number
	return Perks.jarInterval(DataService.owned(player))
end

local function tween(
	part: BasePart,
	seconds: number,
	cf: CFrame,
	style: Enum.EasingStyle?,
	direction: Enum.EasingDirection?
)
	TweenService:Create(
		part,
		TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
		{ CFrame = cf }
	):Play()
end

local function dust(at: Vector3)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.CFrame = CFrame.new(at)
	local fx = Instance.new("ParticleEmitter")
	fx.Color = ColorSequence.new(Color3.fromRGB(200, 180, 140))
	fx.Size = NumberSequence.new(0.6, 0)
	fx.Lifetime = NumberRange.new(0.3, 0.6)
	fx.Speed = NumberRange.new(4, 7)
	fx.SpreadAngle = Vector2.new(180, 30)
	fx.Rate = 0
	fx.Parent = anchor
	anchor.Parent = workspace
	fx:Emit(10)
	Debris:AddItem(anchor, 1)
end

local function flash(at: Vector3)
	local ball = Instance.new("Part")
	ball.Shape = Enum.PartType.Ball
	ball.Anchored = true
	ball.CanCollide = false
	ball.CanQuery = false
	ball.Material = Enum.Material.Neon
	ball.Color = Color3.fromRGB(255, 230, 120)
	ball.Size = Vector3.new(2, 2, 2)
	ball.CFrame = CFrame.new(at)
	ball.Parent = workspace
	TweenService:Create(ball, TweenInfo.new(0.25), { Size = Vector3.new(9, 9, 9), Transparency = 1 }):Play()
	Debris:AddItem(ball, 0.3)
end

local function clearModels(s: State)
	for _, m in s.models do
		m:Destroy()
	end
	s.models = {}
end

-- Builds the wall from the profile with no animation (join, after prestige).
local function rebuild(player: Player, data: Types.Profile)
	local s = states[player]
	local plot = PlotService.get(player)
	if not s or not plot then
		return
	end
	clearModels(s)
	for i, tier in data.hives do
		local model = HiveModel.build(tier, World.slotCFrame(plot, i))
		model.Parent = plot.hives
		s.models[i] = model
	end
	s.timers = Belt.stagger(#data.hives, os.clock(), interval(player), function()
		return rng:NextNumber()
	end)
end

function HiveService.reset(player: Player, data: Types.Profile)
	rebuild(player, data)
end

function HiveService.buy(player: Player, data: Types.Profile, n: number, quiet: boolean?): boolean
	local s = states[player]
	local plot = PlotService.get(player)
	if not s or not plot or s.busy then
		return false
	end
	local reason, first, tier = Shop.buy(data, n)
	if reason ~= "ok" then
		if not quiet then
			if reason == "full" then
				Net.notify(player, "Wall full — press E to merge")
			elseif reason == "room" then
				Net.notify(player, string.format("Only room for %d more", Wall.free(data.hives)))
			else
				Net.notify(player, "Need " .. Format.money((Shop.quote(data, n))))
			end
		end
		return false
	end
	local now = os.clock()
	for i = first, first + n - 1 do
		local target = World.slotCFrame(plot, i)
		local model = HiveModel.build(tier, CFrame.new(0, Layout.dropHeight, 0) * target)
		model.Parent = plot.hives
		s.models[i] = model
		s.timers[i] = now + interval(player)
		local delayBy = (i - first) * 0.03
		task.delay(delayBy, function()
			if model.Parent and model.PrimaryPart then
				tween(model.PrimaryPart, GameConfig.dropSeconds, target, Enum.EasingStyle.Bounce)
				task.delay(GameConfig.dropSeconds * 0.6, dust, target.Position - Vector3.new(0, Layout.slotSize / 2, 0))
			end
		end)
	end
	DataService.changed(player)
	return true
end

function HiveService.merge(player: Player, data: Types.Profile): boolean
	local s = states[player]
	local plot = PlotService.get(player)
	if not s or not plot or s.busy or not Merge.canMerge(data.hives) then
		return false
	end
	s.busy = true
	local before = data.highestTier
	local result, moves, consumed = Merge.plan(data.hives)
	data.hives = result.hives
	Shop.noteTier(data, result.highest)
	data.stats.merges += result.merges
	DataService.changed(player)
	if data.highestTier > before then
		local bee = Bees.list[data.highestTier]
		Net.notify(player, string.format("New bee: %s (Tier %d)!", bee.name, bee.tier), "success")
	end

	-- Animation, under Game.mergeAnimationMax: consumed hives fly in, flash, then the wall rebuilds.
	local mergePoint = World.toWorld(plot, Layout.mergePoint)
	local old = s.models
	for _, i in consumed do
		local box = old[i] and old[i].PrimaryPart
		if box then
			tween(
				box,
				0.4,
				CFrame.new(mergePoint) * box.CFrame.Rotation,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.In
			)
		end
	end
	task.wait(0.4)
	for _, i in consumed do
		if old[i] then
			old[i]:Destroy()
		end
	end
	flash(mergePoint)
	local models: { Model } = {}
	for i, move in moves do
		local target = World.slotCFrame(plot, i)
		local model = if move.from then old[move.from] else nil
		if not model then
			model = HiveModel.build(move.tier, CFrame.new(mergePoint) * target.Rotation)
			model.Parent = plot.hives
		end
		models[i] = model
		if model.PrimaryPart then
			tween(model.PrimaryPart, 0.55, target, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		end
	end
	s.models = models
	s.timers = Belt.stagger(#data.hives, os.clock(), interval(player), function()
		return rng:NextNumber()
	end)
	task.wait(0.6)
	s.busy = false
	return true
end

function HiveService.Init() end

function HiveService.Start()
	PlotService.Claimed:Connect(function(player, _plot, data)
		states[player] = { models = {}, timers = {}, busy = false }
		rebuild(player, data)
	end)
	Players.PlayerRemoving:Connect(function(player)
		local s = states[player]
		states[player] = nil
		if s then
			clearModels(s)
		end
	end)
	for _, n in { 1, 5, 25 } do
		PlotService.onPad("Buy" .. n, function(player, data, _plot, again)
			HiveService.buy(player, data, n, again)
		end, GameConfig.buyRepeatSeconds)
	end
	Net.on("Merge", function(player, data)
		HiveService.merge(player, data)
	end)

	-- Auto Merge and Auto Buy passes
	task.spawn(function()
		while true do
			task.wait(GameConfig.autoMergeSeconds)
			for player, data in DataService.players() do
				if DataService.hasPass(player, "AutoMerge") then
					task.spawn(HiveService.merge, player, data)
				end
			end
		end
	end)
	while true do
		task.wait(GameConfig.autoBuySeconds)
		for player, data in DataService.players() do
			local pad = PlotService.currentPad(player)
			local onBuyPad = pad ~= nil and string.sub(pad, 1, 3) == "Buy"
			if DataService.hasPass(player, "AutoBuy") and not onBuyPad then
				HiveService.buy(player, data, 1, true)
			end
		end
	end
end

return HiveService
