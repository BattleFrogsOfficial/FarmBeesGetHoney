-- Shop, merge plan, belt queue, processor, prestige and pass perks.
return function(t)
	local Shop = t.require("src/shared/Shop")
	local Merge = t.require("src/shared/Merge")
	local Belt = t.require("src/shared/Belt")
	local Processor = t.require("src/shared/Processor")
	local Prestige = t.require("src/shared/Prestige")
	local Perks = t.require("src/shared/Perks")
	local Economy = t.require("src/shared/Economy")

	local function profile(overrides)
		local p = {
			version = 1,
			money = 12,
			prestige = 0,
			hives = {},
			highestTier = 0,
			shopBuys = 0,
			processorLevel = 1,
			queuedHoney = 0,
			padHoney = 0,
			carriedHoney = 0,
			receipts = {},
			stats = { lifetimeHoney = 0, lifetimeMoney = 0, jarsMade = 0, merges = 0, bestVariant = "" },
		}
		for k, v in overrides or {} do
			p[k] = v
		end
		return p
	end

	local function rep(tier, n)
		local out = {}
		for _ = 1, n do
			table.insert(out, tier)
		end
		return out
	end

	return {
		["buy: first bee is Tier 1 for $5, from the starting $12"] = function()
			local p = profile()
			local reason, first, tier = Shop.buy(p, 1)
			t.eq(reason, "ok")
			t.eq(first, 1)
			t.eq(tier, 1)
			t.eq(p.hives, { 1 })
			t.near(p.money, 7, 1e-9)
			t.eq(p.shopBuys, 1)
			t.eq(p.highestTier, 1)
		end,
		["buy: refuses without money, room, or on a full wall"] = function()
			t.eq((select(2, Shop.quote(profile({ money = 4 }), 1))), "money")
			t.eq((select(2, Shop.quote(profile({ money = 1e9, hives = rep(1, 96) }), 5))), "room")
			t.eq((select(2, Shop.quote(profile({ money = 1e9, hives = rep(1, 100) }), 1))), "full")
			local p = profile({ money = 4 })
			t.eq((Shop.buy(p, 1)), "money")
			t.eq(p.hives, {})
		end,
		["buy 25 charges the sum of 25 prices"] = function()
			local p = profile({ money = 1e6 })
			local cost = Shop.quote(p, 25)
			Shop.buy(p, 25)
			t.near(p.money, 1e6 - cost, 1e-6)
			t.eq(#p.hives, 25)
		end,
		["shop tier rises with the highest tier and resets the buy count"] = function()
			local p = profile({ highestTier = 5, shopBuys = 40 })
			Shop.noteTier(p, 5)
			t.eq(p.shopBuys, 40)
			Shop.noteTier(p, 6)
			t.eq(p.highestTier, 6)
			t.eq(p.shopBuys, 0)
			t.eq(Economy.shopTier(p.highestTier), 2)
			p.shopBuys = 7
			Shop.noteTier(p, 4) -- lower: nothing
			t.eq(p.shopBuys, 7)
		end,
		["cash pack pays N shop-tier bees at the current price"] = function()
			local p = profile({ highestTier = 7, shopBuys = 3 })
			t.near(Shop.cashPack(p, 10), Economy.padCost(3, 3, 10), 1e-9)
		end,
		["merge plan: moves rebuild the wall and account for every old hive"] = function()
			local old = { 2, 1, 1, 3, 1, 1, 2 } -- 4 x T1, 2 x T2, 1 x T3
			local result, moves, consumed = Merge.plan(old)
			-- 4 T1 -> 1 T1 + 1 T2; 3 T2 -> 1 T3; 2 T3 stay.
			t.eq(result.hives, { 1, 3, 3 })
			t.eq(#moves, 3)
			for i, m in moves do
				t.eq(m.tier, result.hives[i])
			end
			t.eq(moves[1].from, 2) -- the first T1 in wall order is kept
			t.eq(moves[2].from, 4) -- the old T3 is kept
			t.eq(moves[3].from, nil) -- the new T3
			local seen = {}
			for _, m in moves do
				if m.from then
					seen[m.from] = true
				end
			end
			for _, i in consumed do
				t.ok(not seen[i], "consumed hive also kept: " .. i)
				seen[i] = true
			end
			for i = 1, #old do
				t.ok(seen[i], "hive " .. i .. " unaccounted")
			end
		end,
		["merge plan with nothing to merge keeps every hive"] = function()
			local _, moves, consumed = Merge.plan({ 1, 2, 1 })
			t.eq(#consumed, 0)
			t.eq(moves, { { tier = 1, from = 1 }, { tier = 1, from = 3 }, { tier = 2, from = 2 } })
		end,
		["belt: due hives in waiting order, capped by free space"] = function()
			local timers = { 5, 1, 9, 1, 3 }
			t.eq(Belt.due(timers, 4, 10), { 2, 4, 5 })
			t.eq(Belt.due(timers, 4, 2), { 2, 4 })
			t.eq(Belt.due(timers, 4, 0), {})
			t.eq(Belt.due(timers, 0, 10), {})
		end,
		["belt: stagger spreads timers over one interval"] = function()
			local timers = Belt.stagger(4, 100, 8, function(i)
				return (i - 1) / 4
			end)
			t.eq(timers, { 100, 102, 104, 106 })
		end,
		["processor: converts at its rate, never more than queued"] = function()
			local p = profile({ queuedHoney = 10, processorLevel = 2 }) -- 2.5/s
			local honey, money = Processor.step(p, 1, 3)
			t.near(honey, 2.5, 1e-9)
			t.near(money, 7.5, 1e-9)
			t.near(p.queuedHoney, 7.5, 1e-9)
			t.near(p.money, 12 + 7.5, 1e-9)
			t.near(p.stats.lifetimeMoney, 7.5, 1e-9)
			Processor.step(p, 100, 1)
			t.eq(p.queuedHoney, 0)
			t.eq((Processor.step(p, 1, 1)), 0)
		end,
		["processor: upgrade costs $100 x 3^(L-1)"] = function()
			local p = profile({ money = 399 })
			t.ok(Processor.upgrade(p))
			t.eq(p.processorLevel, 2)
			t.near(p.money, 299, 1e-9)
			t.ok(not Processor.upgrade(p)) -- 300 needed
		end,
		["hand in moves carried honey to the queue"] = function()
			local p = profile({ carriedHoney = 40, queuedHoney = 2 })
			t.eq(Processor.handIn(p), 40)
			t.eq(p.queuedHoney, 42)
			t.eq(p.carriedHoney, 0)
		end,
		["prestige: needs the tier and the price, resets the run"] = function()
			local p = profile({ money = 9_999, highestTier = 6 })
			t.ok(not Prestige.status(p).ready)
			t.ok(not Prestige.apply(p))
			p.money = 10_000
			p.highestTier = 5
			t.ok(not Prestige.apply(p))
			p.highestTier = 6
			p.hives = { 6, 3 }
			p.processorLevel = 9
			p.padHoney, p.carriedHoney, p.queuedHoney = 1, 2, 3
			p.stats.merges = 50
			t.ok(Prestige.apply(p))
			t.eq(p.prestige, 1)
			t.eq(p.money, 12)
			t.eq(p.hives, {})
			t.eq(p.highestTier, 0)
			t.eq(p.processorLevel, 1)
			t.eq(p.padHoney + p.carriedHoney + p.queuedHoney, 0)
			t.eq(p.stats.merges, 50)
			local s = Prestige.status(p)
			t.eq(s.tier, 7)
			t.eq(s.price, 220e3)
		end,
		["flag color steps every 5 prestiges, red from 25"] = function()
			t.eq(Prestige.flagIndex(0, 5, 6), 1)
			t.eq(Prestige.flagIndex(4, 5, 6), 1)
			t.eq(Prestige.flagIndex(5, 5, 6), 2)
			t.eq(Prestige.flagIndex(24, 5, 6), 5)
			t.eq(Prestige.flagIndex(25, 5, 6), 6)
			t.eq(Prestige.flagIndex(90, 5, 6), 6)
		end,
		["perks: passes change money, luck and jar interval"] = function()
			t.eq(Perks.moneyPerHoney(0, {}), 1)
			t.eq(Perks.moneyPerHoney(0, { Money2x = true }), 2)
			t.near(Perks.moneyPerHoney(2, { Money2x = true }), 4.5, 1e-9)
			t.eq(Perks.luck({}), 1)
			t.eq(Perks.luck({ LuckyJars = true }), 3)
			t.eq(Perks.jarInterval({}), 8)
			t.eq(Perks.jarInterval({ BeeSpeed2x = true }), 4)
		end,
	}
end
