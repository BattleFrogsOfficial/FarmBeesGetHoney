--!strict
-- Map and plot geometry in studs. Plot coordinates are local to the plot: x = left/right as you
-- face the hives from the bridge, y = up from the plot's ground, z = toward the hub (+) or toward
-- the back edge (-). The hive stack stands at the back facing +z, the conveyor runs in front of it.

return {
	plotCount = 6,
	-- Plot centers from the hub center. Neighbors are 60 degrees apart and each 120-stud square
	-- reaches 85 studs from its center at the corners, so 190 leaves a gap (the smoke test checks).
	ringRadius = 190,
	plotSize = 120,
	hubRadius = 40,
	bridgeWidth = 12,
	groundThickness = 4,

	-- Fence round each plot, open where the bridge arrives (front edge, centered)
	fence = { height = 3.5, thickness = 0.6, gap = 18 },

	-- Hives: a free-standing 10 x 10 stack of open-front boxes on a raised platform at the back,
	-- facing the conveyor (+z). The platform is taller than the belt and its rails, so the bottom
	-- row shows over them.
	slotSize = 6,
	wallZ = -52, -- box centers
	platform = { from = Vector3.new(-31, 0, -56), to = Vector3.new(31, 0, -47), height = 4.5 },
	mergePoint = Vector3.new(0, 30, -36),
	dropHeight = 30, -- hives drop in from this far above their slot

	-- Conveyor: segment A runs along the front of the hives toward +x (jars appear on it in front of
	-- each column), segment B runs down the right side toward +z to the pickup pad.
	beltTop = 1.5, -- belt surface height above the plot ground
	beltRail = 1.5, -- rail height above the belt (keep platform.height above beltTop + beltRail)
	beltA = { from = Vector3.new(-32, 0, -47), to = Vector3.new(38, 0, -41) }, -- x/z corners
	beltB = { from = Vector3.new(38, 0, -47), to = Vector3.new(44, 0, -6) },
	beltEndZ = -6, -- a jar past this z (on segment B) has reached the end
	beltSpeed = 14, -- studs per second

	-- Pads: centers on the ground, square of `padSize`. Buy 1 / 5 / 25 and Merge sit in a row right
	-- in front of the conveyor.
	padSize = 8,
	pads = {
		Buy1 = Vector3.new(-18, 0, -32),
		Buy5 = Vector3.new(-6, 0, -32),
		Buy25 = Vector3.new(6, 0, -32),
		Merge = Vector3.new(18, 0, -32),
		Pickup = Vector3.new(41, 0, 4),
		Sell = Vector3.new(-36, 0, 10),
		Upgrade = Vector3.new(-50, 0, 10),
		Prestige = Vector3.new(0, 0, -12),
	},
	padHeight = 6, -- a player's root within this height above a pad counts as standing on it
	padSignHeight = 3, -- pad signs stand behind their pad, low enough not to hide the hives

	beekeeper = Vector3.new(-36, 0, -4), -- stand center (the NPC stands behind the counter)
	processor = Vector3.new(-50, 0, -4),
	flag = Vector3.new(14, 0, 54),
	spawn = Vector3.new(0, 3, 40),
	ownerSign = Vector3.new(-16, 0, 56),

	-- Wide view of the hives while standing on a Buy pad
	wallViewEye = Vector3.new(0, 34, 20),
	wallViewAt = Vector3.new(0, 28, -52),
	wallViewTween = 0.4,
}
