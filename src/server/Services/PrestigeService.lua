--!strict
-- The Prestige pad: when the run's required tier is reached and the price can be paid, reset the
-- run for a permanent x1.5 money multiplier, and raise the plot's flag.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local HiveService = require(script.Parent.HiveService)
local HoneyService = require(script.Parent.HoneyService)
local Net = require(script.Parent.Parent.Util.Net)
local Economy = require(ReplicatedStorage.Shared.Economy)
local Format = require(ReplicatedStorage.Shared.Format)
local Prestige = require(ReplicatedStorage.Shared.Prestige)

local PrestigeService = {}

function PrestigeService.Init() end

function PrestigeService.Start()
	PlotService.onPad("Prestige", function(player, data)
		if HiveService.busy(player) then
			return
		end
		local status = Prestige.status(data)
		if not status.ready then
			Net.notify(
				player,
				string.format(
					"Prestige %d needs a Tier %d bee and %s",
					data.prestige + 1,
					status.tier,
					Format.money(status.price)
				)
			)
			return
		end
		Prestige.apply(data)
		HoneyService.clear(player, true)
		HiveService.reset(player, data)
		PlotService.updateFlag(player, data)
		DataService.changed(player)
		Net.notify(
			player,
			string.format("Prestige %d! Money x%.1f forever", data.prestige, Economy.prestigeMultiplier(data.prestige)),
			"success"
		)
	end)
end

return PrestigeService
