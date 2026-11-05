--!strict
-- Which hives drop a jar now. Each hive has a timer (when its next jar is due). A due hive whose
-- jar would go over the belt cap holds it until a jar leaves; the longest-waiting go first.

local Belt = {}

-- timers[i] = when hive i's jar is due. Returns up to `free` hive indices, oldest due first.
function Belt.due(timers: { number }, now: number, free: number): { number }
	if free <= 0 then
		return {}
	end
	local due = {}
	for i, at in timers do
		if at <= now then
			table.insert(due, i)
		end
	end
	table.sort(due, function(a, b)
		if timers[a] == timers[b] then
			return a < b
		end
		return timers[a] < timers[b]
	end)
	while #due > free do
		table.remove(due)
	end
	return due
end

-- Fresh timers for a wall of `count` hives, staggered across one interval so jars don't arrive in
-- bursts. `offset(i)` gives a value in [0, 1) (random in the game, fixed in tests).
function Belt.stagger(count: number, now: number, interval: number, offset: (number) -> number): { number }
	local timers = table.create(count, 0)
	for i = 1, count do
		timers[i] = now + interval * offset(i)
	end
	return timers
end

return Belt
