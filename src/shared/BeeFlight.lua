--!strict
-- Where a bee is inside its box at time t: a slow wander (three sine waves at seeded speeds and
-- phases) that never leaves the box, facing the way it flies, with a wing flap angle. Pure math;
-- the client turns it into CFrames (BeeController), the preview uses it at t = 0.

local BeeFlight = {}

-- Rough bee extents per unit of BeeStyle.scale (from BeeModel's proportions).
BeeFlight.HALF_LENGTH = 2.5 -- thorax to the stinger tip (the longer way), checked by tools/smoke
BeeFlight.HALF_HEIGHT = 0.75 -- antennae / wings over, legs under
BeeFlight.MARGIN = 0.15

export type Range = { x: number, y: number, z: number }

-- How far the thorax may wander from the box center on each axis. `inner` = half the box interior.
function BeeFlight.range(scale: number, inner: number): Range
	local reach = BeeFlight.HALF_LENGTH * scale + BeeFlight.MARGIN
	local tall = BeeFlight.HALF_HEIGHT * scale + BeeFlight.MARGIN
	return {
		x = math.max(0, inner - reach),
		y = math.max(0, inner - tall),
		z = math.max(0, inner - reach) * 0.8,
	}
end

local function speeds(seed: number): (number, number, number, number, number, number)
	local a = (seed * 0.6180339887) % 1
	local b = (seed * 0.4142135624) % 1
	local c = (seed * 0.7320508076) % 1
	return 0.55 + a * 0.35, 0.8 + b * 0.5, 0.45 + c * 0.3, a * 6.283, b * 6.283, c * 6.283
end

-- Offset from the box center (box-local, -z = toward the opening), the yaw to face the direction
-- of travel, and the wing flap angle in radians.
function BeeFlight.at(t: number, seed: number, range: Range): (number, number, number, number, number)
	local wx, wy, wz, px, py, pz = speeds(seed)
	local x = range.x * math.sin(wx * t + px)
	local y = range.y * math.sin(wy * t + py)
	local z = range.z * math.sin(wz * t + pz)
	local dx = range.x * wx * math.cos(wx * t + px)
	local dz = range.z * wz * math.cos(wz * t + pz)
	-- A CFrame.Angles(0, yaw, 0) looks along (-sin yaw, 0, -cos yaw): solve for the travel direction.
	local yaw = if math.abs(dx) + math.abs(dz) > 1e-6 then math.atan2(-dx, -dz) else 0
	local flap = math.sin(t * 38 + px) * math.rad(35)
	return x, y, z, yaw, flap
end

return BeeFlight
