--!strict
-- Prestige: the requirement check, the reset and the flag.

local Economy = require(script.Parent.Economy)
local EconomyConfig = require(script.Parent.Config.Economy)
local Types = require(script.Parent.Types)

local Prestige = {}

export type Status = { tier: number, price: number, hasTier: boolean, hasMoney: boolean, ready: boolean }

function Prestige.status(data: Types.Profile): Status
	local tier = Economy.prestigeTier(data.prestige)
	local price = Economy.prestigePrice(data.prestige)
	local hasTier = data.highestTier >= tier
	local hasMoney = data.money >= price
	return { tier = tier, price = price, hasTier = hasTier, hasMoney = hasMoney, ready = hasTier and hasMoney }
end

-- Resets the run and adds one prestige. Keeps prestige count, stats (lifetime) and receipts.
-- Honey anywhere in the loop (pad, carried, queued) goes with the run.
function Prestige.apply(data: Types.Profile): boolean
	if not Prestige.status(data).ready then
		return false
	end
	data.prestige += 1
	data.money = EconomyConfig.startingMoney
	data.hives = {}
	data.highestTier = 0
	data.shopBuys = 0
	data.processorLevel = 1
	data.queuedHoney = 0
	data.padHoney = 0
	data.carriedHoney = 0
	return true
end

-- Which flag color (1-based index into Visuals.flagColors) a prestige count flies.
function Prestige.flagIndex(prestige: number, step: number, colors: number): number
	return math.min(colors, prestige // step + 1)
end

return Prestige
