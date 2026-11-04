-- The merge rule: 3 -> 1 up the ladder, top tier never merges, wall rebuilt in ascending order.
return function(t)
	local Merge = t.require("src/shared/Merge")

	local function rep(tier, n)
		local out = {}
		for _ = 1, n do
			table.insert(out, tier)
		end
		return out
	end

	return {
		["design doc example: 10 Tier 1 hives -> [1, 3]"] = function()
			local r = Merge.run(rep(1, 10))
			t.eq(r.hives, { 1, 3 })
			t.eq(r.merges, 4) -- three into Tier 2, then one into Tier 3
			t.eq(r.highest, 3)
			t.eq(r.created, { [2] = 3, [3] = 1 })
		end,
		["nothing to merge leaves the wall sorted and unchanged in content"] = function()
			local r = Merge.run({ 3, 1, 2, 1 })
			t.eq(r.hives, { 1, 1, 2, 3 })
			t.eq(r.merges, 0)
			t.ok(not Merge.canMerge({ 3, 1, 2, 1 }))
		end,
		["cascades all the way: 3^11 Tier 1 hives make one Queen"] = function()
			local r = Merge.run(rep(1, 3 ^ 11))
			t.eq(r.hives, { 12 })
		end,
		["Tier 12 never merges"] = function()
			local r = Merge.run(rep(12, 5))
			t.eq(#r.hives, 5)
			t.ok(not Merge.canMerge(rep(12, 5)))
		end,
		["merging is idempotent once compacted"] = function()
			local once = Merge.run({ 1, 1, 1, 2, 2, 4, 4, 4, 1 }).hives
			t.eq(Merge.run(once).hives, once)
			t.ok(not Merge.canMerge(once))
		end,
		["leftovers keep count mod 3 at each tier"] = function()
			-- 7 x T1 -> 1 T1 + 2 T2; plus 2 existing T2 -> 4 T2 -> 1 T2 + 1 T3
			local hives = rep(1, 7)
			table.insert(hives, 2)
			table.insert(hives, 2)
			t.eq(Merge.run(hives).hives, { 1, 2, 3 })
		end,
		["canMerge spots any three of a tier"] = function()
			t.ok(Merge.canMerge({ 5, 5, 5 }))
			t.ok(not Merge.canMerge({}))
		end,
	}
end
