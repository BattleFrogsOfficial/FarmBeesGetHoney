-- Bees wander inside their box and never leave it, at every tier's size.
return function(t)
	local BeeFlight = t.require("src/shared/BeeFlight")
	local Styles = t.require("src/shared/Config/BeeStyle")
	local Layout = t.require("src/shared/Config/Layout")

	local INNER = (Layout.slotSize - 0.2) / 2 - 0.25

	return {
		["every tier has room to fly"] = function()
			for tier, style in Styles do
				local r = BeeFlight.range(style.scale, INNER)
				t.ok(r.x > 0.3 and r.y > 0.3 and r.z > 0.2, "tier " .. tier .. " has no room to fly")
			end
		end,
		["the wander stays inside the box"] = function()
			for tier, style in Styles do
				local s = style.scale
				local r = BeeFlight.range(s, INNER)
				for step = 0, 400 do
					local x, y, z = BeeFlight.at(step * 0.37, tier * 7 + 3, r)
					local reach = BeeFlight.HALF_LENGTH * s
					t.ok(math.abs(x) + reach <= INNER + 1e-6, "x out at tier " .. tier)
					t.ok(math.abs(z) + reach <= INNER + 1e-6, "z out at tier " .. tier)
					t.ok(math.abs(y) + BeeFlight.HALF_HEIGHT * s <= INNER + 1e-6, "y out at tier " .. tier)
				end
			end
		end,
		["faces the way it flies"] = function()
			local r = { x = 1, y = 0, z = 0 }
			local x0 = BeeFlight.at(0, 1, r)
			local x1, _, _, yaw = BeeFlight.at(0.01, 1, r)
			local moving = x1 - x0
			-- look direction x = -sin(yaw): same sign as the motion
			t.ok((-math.sin(yaw)) * moving > 0, "yaw points along travel")
		end,
		["different seeds fly differently"] = function()
			local r = { x = 1, y = 1, z = 1 }
			local a = BeeFlight.at(2, 1, r)
			local b = BeeFlight.at(2, 2, r)
			t.ok(math.abs(a - b) > 1e-3)
		end,
	}
end
