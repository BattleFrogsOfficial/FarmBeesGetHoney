--!strict
-- Honey jars: every hive drops a jar on its timer (held while the belt is at its cap), jars ride
-- the conveyor (a moving surface, no per-jar scripting) and count when they reach the end.
-- Counted honey waits on the pickup pad, or goes straight to the processor with Auto Collect.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local HiveService = require(script.Parent.HiveService)
local World = require(script.Parent.Parent.Util.World)
local Net = require(script.Parent.Parent.Util.Net)
local Belt = require(ReplicatedStorage.Shared.Belt)
local Economy = require(ReplicatedStorage.Shared.Economy)
local Format = require(ReplicatedStorage.Shared.Format)
local JarModel = require(ReplicatedStorage.Shared.JarModel)
local Perks = require(ReplicatedStorage.Shared.Perks)
local EconomyConfig = require(ReplicatedStorage.Shared.Config.Economy)
local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Types = require(ReplicatedStorage.Shared.Types)

local HoneyService = {}

type Jar = { part: BasePart, honey: number, born: number }
local live: { [Player]: { Jar } } = {}
local rng = Random.new()

local VARIANT_RANK: { [string]: number } = { [""] = 0 }
for i, v in EconomyConfig.variants do
	VARIANT_RANK[v.id] = i
end

local function deliver(player: Player, data: Types.Profile, honey: number)
	data.stats.lifetimeHoney += honey
	if DataService.hasPass(player, "AutoCollect") then
		data.queuedHoney += honey
	else
		data.padHoney += honey
	end
	DataService.changed(player)
end

-- Removes every jar on the belt. Counted into the profile unless `discard` (prestige).
function HoneyService.clear(player: Player, discard: boolean?, profile: Types.Profile?)
	local jars = live[player]
	local data = profile or DataService.get(player)
	if not jars then
		return
	end
	for _, jar in jars do
		if not discard and data then
			deliver(player, data, jar.honey)
		end
		jar.part:Destroy()
	end
	live[player] = {}
end

local function spawnJars(player: Player, data: Types.Profile, plot: World.Plot, now: number)
	local jars = live[player]
	local timers = HiveService.timers(player)
	if not jars or not timers or HiveService.busy(player) then
		return
	end
	local owned = DataService.owned(player)
	local due = Belt.due(timers, now, EconomyConfig.beltCap - #jars)
	for _, i in due do
		local tier = data.hives[i]
		if tier then
			local variant, mult = Economy.rollVariant(rng:NextNumber(), Perks.luck(owned))
			local honey = Economy.honeyPerJar(tier) * mult
			local part =
				JarModel.build(tier, variant, World.jarSpawn(plot, i) + Vector3.new(rng:NextNumber(-0.3, 0.3), 0, 0))
			part.Parent = plot.jars
			pcall(function()
				part:SetNetworkOwner(nil)
			end)
			table.insert(jars, { part = part, honey = honey, born = now })
			data.stats.jarsMade += 1
			if VARIANT_RANK[variant] > (VARIANT_RANK[data.stats.bestVariant] or 0) then
				data.stats.bestVariant = variant
			end
			if variant ~= "" and VARIANT_RANK[variant] >= 3 then
				Net.notify(player, string.format("%s jar! x%d honey", variant, mult), "success")
			end
		end
		timers[i] = now + Perks.jarInterval(owned)
	end
end

local function settleJars(player: Player, data: Types.Profile, plot: World.Plot, now: number)
	local jars = live[player]
	if not jars then
		return
	end
	local keep = {}
	for _, jar in jars do
		local part = jar.part
		if part.Parent == nil or World.beltDone(plot, part.Position) or now - jar.born > GameConfig.jarMaxAge then
			deliver(player, data, jar.honey)
			part:Destroy()
		else
			table.insert(keep, jar)
		end
	end
	live[player] = keep
end

function HoneyService.Init()
	-- Jars still on the belt when you leave are counted straight into the pickup pad.
	DataService.onRelease(function(player, data)
		HoneyService.clear(player, false, data)
		live[player] = nil
	end)
end

function HoneyService.Start()
	PlotService.Claimed:Connect(function(player)
		live[player] = {}
	end)
	Players.PlayerRemoving:Connect(function(player)
		-- DataService's release hook counts them first when it runs; this only cleans up parts.
		task.defer(function()
			local jars = live[player]
			if jars then
				for _, jar in jars do
					jar.part:Destroy()
				end
				live[player] = nil
			end
		end)
	end)
	PlotService.onPad("Pickup", function(player, data)
		if data.padHoney <= 0 then
			return
		end
		local honey = data.padHoney
		data.carriedHoney += honey
		data.padHoney = 0
		DataService.changed(player)
		Net.notify(player, string.format("Picked up %s honey. Hand it to the beekeeper!", Format.number(honey)))
	end)

	-- Pickup counter sign
	task.spawn(function()
		while true do
			task.wait(GameConfig.signTick)
			for player, data in DataService.players() do
				local plot = PlotService.get(player)
				if plot then
					plot.pickupLabel.Text = if DataService.hasPass(player, "AutoCollect")
						then "Auto Collect: honey goes straight to the processor"
						else string.format("Honey: %s — walk here", Format.number(data.padHoney))
				end
			end
		end
	end)

	while true do
		task.wait(GameConfig.honeyTick)
		local now = os.clock()
		for player, data in DataService.players() do
			local plot = PlotService.get(player)
			if plot and live[player] then
				settleJars(player, data, plot, now)
				spawnJars(player, data, plot, now)
			end
		end
	end
end

return HoneyService
