-- tools/econ_sim.py keeps its own copy of the economy knobs: they must match Config/Economy.
return function(t)
	local fs = require("@lune/fs")
	local Config = t.require("src/shared/Config/Economy")

	local py = fs.readFile("tools/econ_sim.py")
	local function knob(name: string): number
		local raw = py:match("\n" .. name .. " = ([%d%._]+)")
		assert(raw, "econ_sim.py has no " .. name)
		return tonumber((raw:gsub("_", ""))) :: number
	end

	local PAIRS = {
		STARTING_MONEY = Config.startingMoney,
		BEE_BASE_PRICE = Config.beeBasePrice,
		SHOP_TIER_PRICE_MULT = Config.shopTierPriceMult,
		PRICE_GROWTH = Config.priceGrowth,
		SHOP_TIER_OFFSET = Config.shopTierOffset,
		MAX_TIER = Config.maxTier,
		MERGE_SIZE = Config.mergeSize,
		JAR_INTERVAL = Config.jarInterval,
		HONEY_BASE = Config.honeyBase,
		PROCESSOR_RATE_BASE = Config.processorRateBase,
		PROCESSOR_COST_BASE = Config.processorCostBase,
		PROCESSOR_COST_MULT = Config.processorCostMult,
		BELT_CAP = Config.beltCap,
		BELT_SECONDS = Config.beltSeconds,
		PRESTIGE_MULT = Config.prestigeMult,
		PRESTIGE_PRICE_TAIL = Config.prestigePriceTail,
		PRESTIGE_TIER_BASE = Config.prestigeTierBase,
	}

	return {
		["econ_sim.py knobs match Config/Economy"] = function()
			for name, value in PAIRS do
				t.eq(knob(name), value, name)
			end
			t.eq(knob("WALL_SLOTS"), Config.wallColumns * Config.wallRows, "WALL_SLOTS")
		end,
		["econ_sim.py prestige prices match"] = function()
			local block = py:match("PRESTIGE_PRICES = (%b[])")
			local i = 0
			for raw in block:gmatch("([%d%.e]+),") do
				i += 1
				t.eq(tonumber(raw), Config.prestigePrices[i], "prestige price " .. i)
			end
			t.eq(i, #Config.prestigePrices)
		end,
		["econ_sim.py variants match"] = function()
			local block = py:match("VARIANTS = (%b[])")
			local i = 0
			for chance, mult in block:gmatch("%(([%d%.]+), (%d+)%)") do
				i += 1
				t.eq(tonumber(chance), Config.variants[i].chance, "variant chance " .. i)
				t.eq(tonumber(mult), Config.variants[i].mult, "variant mult " .. i)
			end
			t.eq(i, #Config.variants)
		end,
		["bees: twelve tiers in order"] = function()
			local Bees = t.require("src/shared/Config/Bees")
			t.eq(#Bees.list, Config.maxTier)
			for i, bee in Bees.list do
				t.eq(bee.tier, i)
			end
		end,
	}
end
