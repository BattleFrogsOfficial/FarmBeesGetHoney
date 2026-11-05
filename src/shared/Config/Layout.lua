--!strict
-- Map and plot geometry in studs. Plot coordinates are local to the plot: x = left/right as you
-- face the wall from the bridge, y = up from the plot's ground, z = toward the hub (+) or toward
-- the back edge (-). The hive wall stands along the back edge facing +z.

return {
	plotCount = 6,
	ringRadius = 150, -- plot centers from the hub center
	plotSize = 120,
	hubRadius = 40,
	bridgeWidth = 12,
	groundThickness = 4,

	-- Hive wall: 10 x 10 slots
	slotSize = 4.6,
	wallZ = -44.8, -- box centers
	wallBackZ = -47.5, -- backboard center
	mergePoint = Vector3.new(0, 24, -30),
	promptPoint = Vector3.new(0, 8, -40), -- where the E prompt sits
	promptDistance = 80,
	dropHeight = 26, -- hives drop in from this far above their slot

	-- Conveyor: segment A runs behind the wall toward +x, segment B down the right side toward +z.
	beltTop = 1.5, -- belt surface height above the plot ground
	beltA = { from = Vector3.new(-26, 0, -56), to = Vector3.new(34, 0, -50) }, -- x/z corners
	beltB = { from = Vector3.new(34, 0, -56), to = Vector3.new(40, 0, -6) },
	beltEndZ = -6, -- a jar past this z (on segment B) has reached the end
	beltSpeed = 14, -- studs per second

	-- Pads: centers on the ground, square of `padSize`
	padSize = 8,
	pads = {
		Buy1 = Vector3.new(-12, 0, 18),
		Buy5 = Vector3.new(0, 0, 18),
		Buy25 = Vector3.new(12, 0, 18),
		Pickup = Vector3.new(37, 0, 4),
		Sell = Vector3.new(-36, 0, 10),
		Upgrade = Vector3.new(-50, 0, 10),
		Prestige = Vector3.new(0, 0, 34),
	},
	padHeight = 6, -- a player's root within this height above a pad counts as standing on it

	beekeeper = Vector3.new(-36, 0, -4), -- stand center (the NPC stands behind the counter)
	processor = Vector3.new(-50, 0, -4),
	flag = Vector3.new(14, 0, 54),
	spawn = Vector3.new(0, 3, 46),
	ownerSign = Vector3.new(-14, 0, 56),

	-- Wide view of the wall while standing on a Buy pad
	wallViewEye = Vector3.new(0, 30, 34),
	wallViewAt = Vector3.new(0, 22, -45),
	wallViewTween = 0.4,
}
