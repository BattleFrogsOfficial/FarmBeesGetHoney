--!strict
-- The hive wall's slot layout: a fixed grid filled bottom row left to right, then the row above
-- starting again at the left. Slot 1 is bottom-left.

local Config = require(script.Parent.Config.Economy)

local Wall = {}

Wall.slots = Config.wallColumns * Config.wallRows

-- Slot index -> column (1 = left) and row (1 = bottom).
function Wall.position(index: number): (number, number)
	local i = index - 1
	return i % Config.wallColumns + 1, i // Config.wallColumns + 1
end

function Wall.index(column: number, row: number): number
	return (row - 1) * Config.wallColumns + column
end

function Wall.free(hives: { number }): number
	return Wall.slots - #hives
end

-- Buy pads are off when fewer than `n` slots are free.
function Wall.hasRoom(hives: { number }, n: number): boolean
	return Wall.free(hives) >= n
end

return Wall
