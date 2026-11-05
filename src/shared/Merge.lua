--!strict
-- The merge rule, a pure function on the wall's list of hive tiers (wall order, bottom-left first).
-- Three same-tier hives become one of the next tier, repeated up the ladder; the top tier never
-- merges. The result is rebuilt in ascending tier order.

local Config = require(script.Parent.Config.Economy)

local Merge = {}

export type Result = {
	hives: { number }, -- the new wall, ascending tiers
	merges: number, -- how many 3 -> 1 merges happened
	created: { [number]: number }, -- tier -> hives of that tier made by this merge
	highest: number, -- highest tier on the new wall (0 if empty)
}

function Merge.counts(hives: { number }): { number }
	local counts = table.create(Config.maxTier, 0)
	for _, tier in hives do
		counts[tier] += 1
	end
	return counts
end

function Merge.canMerge(hives: { number }): boolean
	local counts = Merge.counts(hives)
	for tier = 1, Config.maxTier - 1 do
		if counts[tier] >= Config.mergeSize then
			return true
		end
	end
	return false
end

function Merge.run(hives: { number }): Result
	local counts = Merge.counts(hives)
	local created = {}
	local merges = 0
	for tier = 1, Config.maxTier - 1 do
		local up = counts[tier] // Config.mergeSize
		if up > 0 then
			counts[tier + 1] += up
			counts[tier] -= up * Config.mergeSize
			created[tier + 1] = up
			merges += up
		end
	end
	local out = {}
	local highest = 0
	for tier = 1, Config.maxTier do
		for _ = 1, counts[tier] do
			table.insert(out, tier)
		end
		if counts[tier] > 0 then
			highest = tier
		end
	end
	return { hives = out, merges = merges, created = created, highest = highest }
end

export type Move = { tier: number, from: number? } -- from = old slot index, nil for a new hive

-- The merge as moves for the animation: where each hive of the new wall comes from. Per tier, the
-- first old hives (in wall order) are kept up to that tier's leftover count; the rest are consumed
-- into merges, and leftovers beyond the kept ones are new hives made by the merge.
function Merge.plan(hives: { number }): (Result, { Move }, { number })
	local result = Merge.run(hives)
	local finalCounts = Merge.counts(result.hives)
	local byTier: { { number } } = {}
	for tier = 1, Config.maxTier do
		byTier[tier] = {}
	end
	for i, tier in hives do
		table.insert(byTier[tier], i)
	end
	local moves: { Move } = {}
	local consumed: { number } = {}
	for tier = 1, Config.maxTier do
		local olds = byTier[tier]
		local keep = math.min(#olds, finalCounts[tier])
		for k = 1, keep do
			table.insert(moves, { tier = tier, from = olds[k] })
		end
		for k = keep + 1, #olds do
			table.insert(consumed, olds[k])
		end
		for _ = keep + 1, finalCounts[tier] do
			table.insert(moves, { tier = tier })
		end
	end
	return result, moves, consumed
end

return Merge
