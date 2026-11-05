--!strict
-- What the game passes change, as pure functions of the owned-pass set ({ [passId] = true }).

local Passes = require(script.Parent.Config.Passes)
local Economy = require(script.Parent.Economy)
local EconomyConfig = require(script.Parent.Config.Economy)

local Perks = {}

export type Owned = { [string]: boolean }

function Perks.moneyPerHoney(prestige: number, owned: Owned): number
	local mult = if owned.Money2x then Passes.Money2x.moneyMult else 1
	return Economy.moneyPerHoney(prestige, mult)
end

function Perks.luck(owned: Owned): number
	return if owned.LuckyJars then Passes.LuckyJars.variantOddsMult else 1
end

function Perks.jarInterval(owned: Owned): number
	local mult = if owned.BeeSpeed2x then Passes.BeeSpeed2x.jarIntervalMult else 1
	return EconomyConfig.jarInterval * mult
end

return Perks
