--!strict
-- Builds the map, gives each joining player the first free plot (per session), spawns them on it,
-- and detects who stands on which pad. Other services register pad handlers with onPad().
-- Also keeps the plot's signs (pad prices, owner name, flag) in sync with the owner's profile.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local World = require(script.Parent.Parent.Util.World)
local Net = require(script.Parent.Parent.Util.Net)
local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Layout = require(ReplicatedStorage.Shared.Config.Layout)
local Visuals = require(ReplicatedStorage.Shared.Config.Visuals)
local Economy = require(ReplicatedStorage.Shared.Economy)
local Format = require(ReplicatedStorage.Shared.Format)
local Merge = require(ReplicatedStorage.Shared.Merge)
local Prestige = require(ReplicatedStorage.Shared.Prestige)
local Shop = require(ReplicatedStorage.Shared.Shop)
local Signal = require(ReplicatedStorage.Shared.Signal)
local Types = require(ReplicatedStorage.Shared.Types)

local PlotService = {}

PlotService.Claimed = Signal.new() -- (player, plot, data) after a plot is assigned
PlotService.plots = {} :: { World.Plot }
PlotService.hub = nil :: World.Hub?

type Handler = (player: Player, data: Types.Profile, plot: World.Plot, again: boolean) -> ()
local handlers: { [string]: { fn: Handler, repeatEvery: number? } } = {}
local owners: { [Player]: World.Plot } = {}
local standing: { [Player]: { pad: string?, plot: number?, last: number } } = {}

-- Register what a pad does. `repeatEvery`: call again (again = true) while the owner stays on it.
function PlotService.onPad(name: string, fn: Handler, repeatEvery: number?)
	handlers[name] = { fn = fn, repeatEvery = repeatEvery }
end

function PlotService.get(player: Player): World.Plot?
	return owners[player]
end

function PlotService.currentPad(player: Player): string?
	local s = standing[player]
	return s and s.pad
end

local function setPad(pad: World.Pad, detail: string, on: boolean)
	pad.detail.Text = detail
	pad.part.Color = if on then Visuals.pad[pad.name] else Visuals.padOff
end

-- Prices, greys and texts on the owner's pads. Cheap; runs after every state push.
function PlotService.refreshSigns(player: Player, data: Types.Profile)
	local plot = owners[player]
	if not plot then
		return
	end
	for _, n in { 1, 5, 25 } do
		local pad = plot.pads["Buy" .. n]
		local cost, reason = Shop.quote(data, n)
		local tier = Economy.shopTier(data.highestTier)
		if reason == "full" then
			setPad(pad, "Wall full: step on Merge", false)
		elseif reason == "room" then
			setPad(pad, "Not enough room", false)
		else
			setPad(pad, string.format("Tier %d · %s", tier, Format.money(cost)), reason == "ok")
		end
	end
	local canMerge = Merge.canMerge(data.hives)
	setPad(plot.pads.Merge, if canMerge then "Ready: stand here" else "Need 3 of a kind", canMerge)
	local upgrade = Economy.upgradeCost(data.processorLevel)
	setPad(
		plot.pads.Upgrade,
		string.format("L%d → L%d: %s", data.processorLevel, data.processorLevel + 1, Format.money(upgrade)),
		data.money >= upgrade
	)
	local status = Prestige.status(data)
	setPad(
		plot.pads.Prestige,
		string.format(
			"P%d: Tier %d%s · %s%s",
			data.prestige + 1,
			status.tier,
			if status.hasTier then " (done)" else "",
			Format.money(status.price),
			if status.hasMoney then " (done)" else ""
		),
		status.ready
	)
	setPad(plot.pads.Pickup, "Collect what the belt brought", data.padHoney > 0)
	setPad(plot.pads.Sell, "Carrying " .. Format.number(data.carriedHoney), data.carriedHoney > 0)
end

function PlotService.updateFlag(player: Player, data: Types.Profile)
	local plot = owners[player]
	if not plot then
		return
	end
	local i = Prestige.flagIndex(data.prestige, Visuals.flagStep, #Visuals.flagColors)
	plot.flag.Color = Visuals.flagColors[i]
	for _, l in plot.flagLabels do
		l.Text = "P" .. data.prestige
	end
end

local function resetPlot(plot: World.Plot)
	plot.model:SetAttribute("OwnerUserId", 0)
	plot.ownerLabel.Text = "FREE PLOT"
	plot.flag.Color = Visuals.flagColors[1]
	for _, l in plot.flagLabels do
		l.Text = ""
	end
	for _, pad in plot.pads do
		setPad(pad, "", false)
	end
	plot.pickupLabel.Text = ""
	plot.processorLabel.Text = ""
end

local function spawnOnPlot(player: Player, character: Model)
	local plot = owners[player]
	if not plot then
		return
	end
	local root = character:WaitForChild("HumanoidRootPart", 5)
	if root then
		task.wait() -- let the default spawn finish first
		character:PivotTo(plot.cframe * CFrame.new(Layout.spawn)) -- facing the wall
	end
end

local function claim(player: Player, data: Types.Profile)
	if owners[player] then
		return
	end
	local used = {}
	for _, plot in owners do
		used[plot] = true
	end
	for _, plot in PlotService.plots do
		if not used[plot] then
			owners[player] = plot
			plot.model:SetAttribute("OwnerUserId", player.UserId)
			plot.ownerLabel.Text = string.upper(player.DisplayName) .. "'S FARM"
			standing[player] = { last = 0 }
			PlotService.updateFlag(player, data)
			PlotService.refreshSigns(player, data)
			PlotService.Claimed:Fire(player, plot, data)
			if player.Character then
				task.spawn(spawnOnPlot, player, player.Character)
			end
			return
		end
	end
	warn("[PlotService] no free plot for", player.Name)
end

function PlotService.release(player: Player)
	local plot = owners[player]
	owners[player] = nil
	standing[player] = nil
	if plot then
		resetPlot(plot)
	end
end

local function checkPads()
	local now = os.clock()
	for player, s in standing do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local onPad: string?, onPlot: World.Plot? = nil, nil
		if root then
			for _, plot in PlotService.plots do
				if World.isOnPlot(plot, root.Position) then
					for name, pad in plot.pads do
						if World.isOnPad(plot, pad, root.Position) then
							onPad, onPlot = name, plot
							break
						end
					end
					break
				end
			end
		end
		local entered = onPad ~= nil and (onPad ~= s.pad or (onPlot and onPlot.index) ~= s.plot)
		s.pad = onPad
		s.plot = onPlot and onPlot.index
		if onPad and onPlot then
			local data = DataService.get(player)
			local handler = handlers[onPad]
			if data and handler then
				if owners[player] ~= onPlot then
					if entered then
						Net.notify(player, "Not your plot")
					end
				elseif entered then
					s.last = now
					task.spawn(handler.fn, player, data, onPlot, false)
				elseif handler.repeatEvery and now - s.last >= handler.repeatEvery then
					s.last = now
					task.spawn(handler.fn, player, data, onPlot, true)
				end
			end
		end
	end
end

function PlotService.Init()
	-- A new Baseplate place brings its own floor and spawn: the map replaces them.
	for _, name in { "Baseplate", "SpawnLocation" } do
		local old = workspace:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
	local plots, hub = World.build(workspace)
	PlotService.plots = plots
	PlotService.hub = hub
	for _, plot in plots do
		resetPlot(plot)
	end
end

function PlotService.Start()
	DataService.Loaded:Connect(claim)
	for player, data in DataService.players() do
		claim(player, data)
	end
	DataService.Changed:Connect(PlotService.refreshSigns)
	Players.PlayerRemoving:Connect(PlotService.release)
	local function watch(player: Player)
		player.CharacterAdded:Connect(function(character)
			spawnOnPlot(player, character)
		end)
	end
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerAdded:Connect(watch)
	while true do
		task.wait(GameConfig.padCheckInterval)
		checkPads()
	end
end

return PlotService
