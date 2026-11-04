-- Hive wall layout: 10 x 10, slot 1 bottom-left, rows fill left to right then up.
return function(t)
	local Wall = t.require("src/shared/Wall")

	return {
		["100 slots"] = function()
			t.eq(Wall.slots, 100)
		end,
		["fill order"] = function()
			t.eq({ Wall.position(1) }, { 1, 1 })
			t.eq({ Wall.position(10) }, { 10, 1 })
			t.eq({ Wall.position(11) }, { 1, 2 })
			t.eq({ Wall.position(100) }, { 10, 10 })
			for i = 1, 100 do
				t.eq(Wall.index(Wall.position(i)), i)
			end
		end,
		["room for a pad"] = function()
			local hives = table.create(96, 1)
			t.eq(Wall.free(hives), 4)
			t.ok(Wall.hasRoom(hives, 1))
			t.ok(not Wall.hasRoom(hives, 5))
		end,
	}
end
