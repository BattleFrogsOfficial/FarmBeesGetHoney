--!strict
-- The beekeeper and the processor: hand in honey on the sell pad, the processor turns the queue
-- into money every tick, and the Upgrade pad buys processor levels.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local Net = require(script.Parent.Parent.Util.Net)
local Economy = require(ReplicatedStorage.Shared.Economy)
local Format = require(ReplicatedStorage.Shared.Format)
local Perks = require(ReplicatedStorage.Shared.Perks)
local Processor = require(ReplicatedStorage.Shared.Processor)
local GameConfig = require(ReplicatedStorage.Shared.Config.Game)

local ProcessorService = {}

function ProcessorService.Init() end

function ProcessorService.Start()
	PlotService.onPad("Sell", function(player, data)
		local honey = Processor.handIn(data)
		if honey > 0 then
			DataService.changed(player)
			Net.notify(player, string.format("Handed in %s honey", Format.number(honey)), "success")
		end
	end)
	PlotService.onPad("Upgrade", function(player, data)
		local cost = Processor.upgradeCost(data)
		if Processor.upgrade(data) then
			DataService.changed(player)
			Net.notify(
				player,
				string.format(
					"Processor level %d: %s honey/s",
					data.processorLevel,
					Format.number(Economy.processorRate(data.processorLevel))
				),
				"success"
			)
		else
			Net.notify(player, "Need " .. Format.money(cost))
		end
	end)

	-- Readout and honey level in the machine's window
	task.spawn(function()
		while true do
			task.wait(GameConfig.signTick)
			for player, data in DataService.players() do
				local plot = PlotService.get(player)
				if plot then
					local rate = Economy.processorRate(data.processorLevel)
					plot.processorLabel.Text =
						string.format("Queue: %s honey — %s/s", Format.number(data.queuedHoney), Format.number(rate))
					-- Fill shows the backlog in seconds of work: full at a minute or more.
					local fill = math.clamp(data.queuedHoney / math.max(rate * 60, 1), 0.02, 1)
					local level = plot.honeyLevel
					local height = 4 * fill
					local baseY = plot.cframe:PointToObjectSpace(level.Position).Y - level.Size.Y / 2
					level.Size = Vector3.new(level.Size.X, height, level.Size.Z)
					local p = plot.cframe:PointToObjectSpace(level.Position)
					level.CFrame = plot.cframe * CFrame.new(p.X, baseY + height / 2, p.Z)
				end
			end
		end
	end)

	local last = os.clock()
	while true do
		task.wait(GameConfig.processorTick)
		local now = os.clock()
		local dt = now - last
		last = now
		for player, data in DataService.players() do
			local honey = Processor.step(data, dt, Perks.moneyPerHoney(data.prestige, DataService.owned(player)))
			if honey > 0 then
				DataService.changed(player)
			end
		end
	end
end

return ProcessorService
