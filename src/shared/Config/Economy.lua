--!strict
-- Every economy knob from the design doc's "Economy numbers" table. Tuning edits this file only.
-- tools/econ_sim.py holds a copy of these values: change both, then rerun the sim.

return {
	startingMoney = 12,

	-- Bees and the shop
	beeBasePrice = 5, -- $ for the first Tier 1 bee
	shopTierPriceMult = 5, -- each shop tier's bees cost 5x the tier below
	priceGrowth = 1.01, -- each purchase at the current shop tier costs 1% more (count resets on a shop tier change)
	shopTierOffset = 4, -- shop tier = highest tier created this run - 4, min 1
	pads = { 1, 5, 25 }, -- Buy 1 / Buy 5 / Buy 25

	-- Hives and merging
	maxTier = 12,
	mergeSize = 3, -- three same-tier hives make one of the next tier
	wallColumns = 10,
	wallRows = 10,

	-- Honey jars
	jarInterval = 8, -- seconds between jars, every tier
	honeyBase = 5, -- honey per jar = honeyBase ^ (tier - 1)
	beltCap = 50, -- live jars per plot (35 in the first draft; 50 since 2026-11-04)
	beltSeconds = 6, -- belt travel time, end to end
	-- One variant at most per jar, rolled at creation (rarest checked first). chance is 0..1.
	variants = {
		{ id = "Shiny", chance = 0.02, mult = 2 },
		{ id = "Golden", chance = 0.005, mult = 5 },
		{ id = "Rainbow", chance = 0.0005, mult = 20 },
		{ id = "Quantum", chance = 0.00005, mult = 100 },
	},

	-- Processor (honey -> money)
	moneyPerHoney = 1,
	processorRateBase = 2.5, -- honey/s at level L = base ^ (L - 1)
	processorCostBase = 100, -- upgrade L -> L+1 = base x mult ^ (L - 1)
	processorCostMult = 3,

	-- Prestige
	prestigeMult = 1.5, -- per prestige, stacking
	-- Price of each prestige (index 1 = P1). Tuned with tools/econ_sim.py so each run takes ~10% longer
	-- than the one before, starting at ~20 min (2026-11-04). P1-P7 climb ~13x each because the required
	-- tier still rises; from P8 the tier is capped at 12, so the price only has to outpace the x1.5 bonus.
	prestigePrices = {
		10e3, -- P1
		220e3, -- P2
		4.1e6, -- P3
		65e6, -- P4
		860e6, -- P5
		8.2e9, -- P6
		73e9, -- P7
		170e9, -- P8
		330e9, -- P9
		640e9, -- P10
		1.0e12, -- P11
		1.7e12, -- P12
		3.1e12, -- P13
		5.0e12, -- P14
		8.5e12, -- P15
		14e12, -- P16
		24e12, -- P17
		39e12, -- P18
		63e12, -- P19
		100e12, -- P20
	},
	prestigePriceTail = 1.65, -- after the table, each prestige costs this x the previous (x1.5 bonus x ~1.1 time)
	prestigeTierBase = 5, -- required tier = base + prestige number (1st = 6), capped at maxTier
}
