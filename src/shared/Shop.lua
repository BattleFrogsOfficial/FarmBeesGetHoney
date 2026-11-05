--!strict
-- Buying bees and tracking the run's highest tier. Mutates the profile; the server calls these,
-- the client only uses quote() to preview pad prices.

local Economy = require(script.Parent.Economy)
local Wall = require(script.Parent.Wall)
local Types = require(script.Parent.Types)

local Shop = {}

export type Reason = "ok" | "full" | "room" | "money"

-- Cost of the next `n` bees and whether they can be bought now.
function Shop.quote(data: Types.Profile, n: number): (number, Reason)
	local cost = Economy.padCost(Economy.shopTier(data.highestTier), data.shopBuys, n)
	if Wall.free(data.hives) == 0 then
		return cost, "full"
	elseif not Wall.hasRoom(data.hives, n) then
		return cost, "room"
	elseif data.money < cost then
		return cost, "money"
	end
	return cost, "ok"
end

-- A tier was created this run (bought or merged). Raising the shop tier resets its purchase count.
function Shop.noteTier(data: Types.Profile, tier: number)
	if tier <= data.highestTier then
		return
	end
	local before = Economy.shopTier(data.highestTier)
	data.highestTier = tier
	if Economy.shopTier(tier) ~= before then
		data.shopBuys = 0
	end
end

-- Buys `n` bees of the shop tier. Returns the reason, the first new slot index and the tier.
function Shop.buy(data: Types.Profile, n: number): (Reason, number, number)
	local cost, reason = Shop.quote(data, n)
	local tier = Economy.shopTier(data.highestTier)
	if reason ~= "ok" then
		return reason, 0, tier
	end
	data.money -= cost
	local first = #data.hives + 1
	for _ = 1, n do
		table.insert(data.hives, tier)
	end
	data.shopBuys += n
	Shop.noteTier(data, tier)
	return "ok", first, tier
end

-- Money a cash pack pays: `bees` shop-tier bees at the current price.
function Shop.cashPack(data: Types.Profile, bees: number): number
	return Economy.padCost(Economy.shopTier(data.highestTier), data.shopBuys, bees)
end

return Shop
