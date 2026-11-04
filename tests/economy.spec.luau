-- The economy formulas against the design doc's numbers.
return function(t)
	local Economy = t.require("src/shared/Economy")
	local Config = t.require("src/shared/Config/Economy")

	return {
		["honey per jar is 5^(tier-1)"] = function()
			t.eq(Economy.honeyPerJar(1), 1)
			t.eq(Economy.honeyPerJar(2), 5)
			t.eq(Economy.honeyPerJar(6), 3125)
			t.eq(Economy.honeyPerJar(12), 48828125)
		end,
		["shop tier = highest - 4, min 1"] = function()
			t.eq(Economy.shopTier(0), 1)
			t.eq(Economy.shopTier(5), 1)
			t.eq(Economy.shopTier(6), 2)
			t.eq(Economy.shopTier(12), 8)
		end,
		["bee price: $5 x 5^(shop-1) x 1.01^buys"] = function()
			t.eq(Economy.beePrice(1, 0), 5)
			t.eq(Economy.beePrice(2, 0), 25)
			t.near(Economy.beePrice(1, 100), 5 * 1.01 ^ 100, 1e-9)
		end,
		["pad cost is the sum of the next N prices"] = function()
			t.near(Economy.padCost(1, 0, 5), 5 * (1 + 1.01 + 1.01 ^ 2 + 1.01 ^ 3 + 1.01 ^ 4), 1e-9)
			t.eq(Economy.padCost(1, 3, 1), Economy.beePrice(1, 3))
		end,
		["processor: rate 2.5^(L-1), upgrade $100 x 3^(L-1)"] = function()
			t.eq(Economy.processorRate(1), 1)
			t.near(Economy.processorRate(7), 244.140625, 1e-9)
			t.near(Economy.processorRate(13), 59604.64, 0.01)
			t.eq(Economy.upgradeCost(1), 100)
			t.eq(Economy.upgradeCost(2), 300)
			t.eq(Economy.upgradeCost(4), 2700)
		end,
		["prestige: tier 5 + n capped at 12, price $10K x10"] = function()
			t.eq(Economy.prestigeTier(0), 6)
			t.eq(Economy.prestigeTier(1), 7)
			t.eq(Economy.prestigeTier(6), 12)
			t.eq(Economy.prestigeTier(20), 12)
			t.eq(Economy.prestigePrice(0), 10_000)
			t.eq(Economy.prestigePrice(2), 1_000_000)
			t.ok(Economy.canPrestige(0, 6, 10_000))
			t.ok(not Economy.canPrestige(0, 5, 1e9))
			t.ok(not Economy.canPrestige(0, 6, 9_999))
		end,
		["prestige multiplier stacks 1.5x (P5 = 7.6x, P10 = 58x)"] = function()
			t.near(Economy.prestigeMultiplier(5), 7.59, 0.01)
			t.near(Economy.prestigeMultiplier(10), 57.67, 0.01)
			t.near(Economy.moneyPerHoney(1, 2), 3, 1e-9)
		end,
		["variant roll bands match their chances, rarest first"] = function()
			t.eq(select(1, Economy.rollVariant(0)), "Quantum")
			t.eq(select(1, Economy.rollVariant(0.00004)), "Quantum")
			t.eq(select(1, Economy.rollVariant(0.00006)), "Rainbow")
			t.eq(select(1, Economy.rollVariant(0.0004)), "Rainbow")
			t.eq(select(1, Economy.rollVariant(0.001)), "Golden")
			t.eq(select(1, Economy.rollVariant(0.006)), "Shiny")
			t.eq(select(1, Economy.rollVariant(0.03)), "")
			local _, mult = Economy.rollVariant(0.5)
			t.eq(mult, 1)
			-- Lucky Jars (x3): the Shiny band ends at 3 x 2.555% instead of 2.555%.
			t.eq(select(1, Economy.rollVariant(0.05, 3)), "Shiny")
			t.eq(select(1, Economy.rollVariant(0.08, 3)), "")
			local sum = 0
			for _, v in Config.variants do
				sum += v.chance
			end
			t.near(sum, 0.02555, 1e-12)
		end,
		["expected variant multiplier"] = function()
			t.near(Economy.expectedVariantMult(), 1 + 0.02 + 0.02 + 0.0095 + 0.00495, 1e-12)
		end,
	}
end
