--!strict
-- Shared types. Profile is what ProfileStore saves (template in DataService).

export type Stats = {
	lifetimeHoney: number,
	lifetimeMoney: number,
	jarsMade: number,
	merges: number,
	bestVariant: string,
}

export type Profile = {
	version: number,
	money: number,
	prestige: number,
	hives: { number }, -- tiers in wall order, bottom-left first
	highestTier: number, -- this run
	shopBuys: number, -- purchases at the current shop tier
	processorLevel: number,
	queuedHoney: number, -- honey waiting in the processor
	padHoney: number, -- honey waiting on the pickup pad
	stats: Stats,
}

-- What the client gets: the profile's fields plus derived numbers it would otherwise recompute.
export type Snapshot = {
	money: number,
	prestige: number,
	hives: { number },
	highestTier: number,
	shopTier: number,
	shopBuys: number,
	processorLevel: number,
	queuedHoney: number,
	padHoney: number,
	canMerge: boolean,
	passes: { [string]: boolean },
}

return {}
