--!strict
-- The economy's formulas: pure functions of Config/Economy. The server decides with these and the
-- client previews with them (pad prices, processor readout); tools/econ_sim.py mirrors them.

local Config = require(script.Parent.Config.Economy)

local Economy = {}

function Economy.honeyPerJar(tier: number): number
	return Config.honeyBase ^ (tier - 1)
end

-- Highest tier created this run - offset, at least 1. highestTier 0 (empty wall) is shop tier 1.
function Economy.shopTier(highestTier: number): number
	return math.max(1, highestTier - Config.shopTierOffset)
end

-- Price of one bee at `shopTier` after `buys` purchases at that shop tier.
function Economy.beePrice(shopTier: number, buys: number): number
	return Config.beeBasePrice * Config.shopTierPriceMult ^ (shopTier - 1) * Config.priceGrowth ^ buys
end

-- Sum of the next `n` individual prices (what a Buy N pad charges). Money is kept unrounded
-- (cents and all); only the display rounds.
function Economy.padCost(shopTier: number, buys: number, n: number): number
	local total = 0
	for i = 0, n - 1 do
		total += Economy.beePrice(shopTier, buys + i)
	end
	return total
end

function Economy.processorRate(level: number): number
	return Config.processorRateBase ^ (level - 1)
end

-- Cost to go from `level` to `level + 1`.
function Economy.upgradeCost(level: number): number
	return Config.processorCostBase * Config.processorCostMult ^ (level - 1)
end

-- `prestige` = prestiges done so far; these describe the next one.
function Economy.prestigeTier(prestige: number): number
	return math.min(Config.maxTier, Config.prestigeTierBase + prestige + 1)
end

function Economy.prestigePrice(prestige: number): number
	return Config.prestigePriceBase * Config.prestigePriceMult ^ prestige
end

function Economy.canPrestige(prestige: number, highestTier: number, money: number): boolean
	return highestTier >= Economy.prestigeTier(prestige) and money >= Economy.prestigePrice(prestige)
end

function Economy.prestigeMultiplier(prestige: number): number
	return Config.prestigeMult ^ prestige
end

-- $ per honey processed: base x prestige multiplier x pass multiplier (1 without the pass).
function Economy.moneyPerHoney(prestige: number, passMult: number?): number
	return Config.moneyPerHoney * Economy.prestigeMultiplier(prestige) * (passMult or 1)
end

-- Rolls a jar variant from one uniform roll in [0, 1). luck multiplies every chance (Lucky Jars = 3).
-- Rarest first, so each band is exactly its chance. Returns the variant id ("" for none) and its multiplier.
function Economy.rollVariant(roll: number, luck: number?): (string, number)
	local l = luck or 1
	local acc = 0
	for i = #Config.variants, 1, -1 do
		local v = Config.variants[i]
		acc += v.chance * l
		if roll < acc then
			return v.id, v.mult
		end
	end
	return "", 1
end

function Economy.expectedVariantMult(luck: number?): number
	local l = luck or 1
	local e = 1
	for _, v in Config.variants do
		e += v.chance * l * (v.mult - 1)
	end
	return e
end

return Economy
