--!strict
-- Colors and looks for world objects (not the HUD: see Config/Hud). Adjust freely.

return {
	ground = Color3.fromRGB(106, 166, 74),
	hub = Color3.fromRGB(196, 186, 160),
	bridge = Color3.fromRGB(150, 110, 70),
	rail = Color3.fromRGB(110, 80, 50),
	backboard = Color3.fromRGB(120, 86, 52),
	belt = Color3.fromRGB(45, 45, 50),
	beltRail = Color3.fromRGB(90, 90, 96),

	pad = {
		Buy1 = Color3.fromRGB(70, 160, 230),
		Buy5 = Color3.fromRGB(70, 160, 230),
		Buy25 = Color3.fromRGB(70, 160, 230),
		Pickup = Color3.fromRGB(240, 180, 40),
		Sell = Color3.fromRGB(240, 140, 40),
		Upgrade = Color3.fromRGB(120, 200, 90),
		Prestige = Color3.fromRGB(180, 90, 220),
	},
	padOff = Color3.fromRGB(120, 120, 120), -- greyed out (can't afford / no room / not ready)
	signBoard = Color3.fromRGB(240, 235, 220),
	signText = Color3.fromRGB(30, 30, 30),

	-- Hive box color by tier: plain wood at 1 through a dark box at 12 (12 glows: Neon).
	hive = {
		Color3.fromRGB(196, 154, 98),
		Color3.fromRGB(184, 140, 86),
		Color3.fromRGB(170, 124, 76),
		Color3.fromRGB(152, 108, 68),
		Color3.fromRGB(134, 94, 62),
		Color3.fromRGB(116, 80, 58),
		Color3.fromRGB(100, 70, 58),
		Color3.fromRGB(86, 60, 62),
		Color3.fromRGB(72, 52, 66),
		Color3.fromRGB(58, 44, 70),
		Color3.fromRGB(46, 36, 66),
		Color3.fromRGB(40, 28, 60),
	},
	hiveNeonTier = 12,

	-- Prestige flag color, stepping every 5 prestiges; the last entry is for 25+.
	flagColors = {
		Color3.fromRGB(245, 245, 245), -- 0-4 white
		Color3.fromRGB(80, 190, 90), -- 5-9 green
		Color3.fromRGB(70, 130, 230), -- 10-14 blue
		Color3.fromRGB(150, 80, 210), -- 15-19 purple
		Color3.fromRGB(240, 190, 40), -- 20-24 gold
		Color3.fromRGB(220, 50, 50), -- 25+ red
	},
	flagStep = 5,

	-- Jar looks by tier band: { fromTier, honey color, lid color, extra }
	jarBands = {
		{ from = 1, honey = Color3.fromRGB(250, 196, 70), lid = Color3.fromRGB(170, 170, 170), extra = "" },
		{ from = 4, honey = Color3.fromRGB(235, 160, 30), lid = Color3.fromRGB(200, 60, 50), extra = "tag" },
		{ from = 7, honey = Color3.fromRGB(220, 130, 20), lid = Color3.fromRGB(240, 200, 60), extra = "" },
		{ from = 10, honey = Color3.fromRGB(200, 100, 20), lid = Color3.fromRGB(240, 200, 60), extra = "gem" },
	},
	-- Variant tint (mixed into the honey) and particle color
	variants = {
		Shiny = { tint = Color3.fromRGB(230, 230, 240), particle = Color3.fromRGB(235, 235, 255) },
		Golden = { tint = Color3.fromRGB(255, 215, 60), particle = Color3.fromRGB(255, 220, 90) },
		Rainbow = { tint = Color3.fromRGB(255, 120, 200), particle = Color3.fromRGB(255, 255, 255), rainbow = true },
		Quantum = { tint = Color3.fromRGB(150, 70, 230), particle = Color3.fromRGB(170, 90, 255) },
	},
}
