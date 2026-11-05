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
	carriedHoney: number, -- picked up, not yet handed to the beekeeper
	receipts: { [string]: number }, -- developer product PurchaseIds already granted (-> unix time)
	stats: Stats,
}

-- What the client gets: the profile's fields plus derived numbers it would otherwise recompute.
export type Snapshot = {
	money: number,
	prestige: number,
	moneyMult: number, -- $ per honey right now (prestige x passes)
	hives: { number },
	highestTier: number,
	shopTier: number,
	shopBuys: number,
	processorLevel: number,
	processorRate: number,
	upgradeCost: number,
	queuedHoney: number,
	padHoney: number,
	carriedHoney: number,
	canMerge: boolean,
	wallFull: boolean,
	nextPrestige: { tier: number, price: number, ready: boolean },
	passes: { [string]: boolean },
}

return {}
