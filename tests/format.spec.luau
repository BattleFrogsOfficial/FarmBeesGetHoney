return function(t)
	local Format = t.require("src/shared/Format")
	return {
		["short numbers"] = function()
			t.eq(Format.number(950), "950")
			t.eq(Format.number(1234), "1.2K")
			t.eq(Format.number(12450), "12.4K")
			t.eq(Format.number(1_200_000), "1.2M")
			t.eq(Format.money(12), "$12")
		end,
	}
end
