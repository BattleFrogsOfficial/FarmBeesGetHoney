--!strict
-- Non-economy settings: server, saving, networking, timings of the loop.

return {
	maxPlayers = 6, -- set in Creator Hub (Places > Max Players); plots are built for this many
	plotCount = 6,
	autoSaveSeconds = 60,
	stateFlushInterval = 0.2, -- batch state pushes to the client
	remoteCallsPerSecond = 10,
	autoMergeSeconds = 10, -- Auto Merge pass
	autoBuySeconds = 5, -- Auto Buy pass
	mergeAnimationMax = 1.5, -- seconds; the whole merge presentation fits in this
	padCheckInterval = 0.1, -- how often the server checks who stands on which pad
	buyRepeatSeconds = 0.5, -- Buy pads buy again every this many seconds while you stand on them
	honeyTick = 0.1, -- jar spawning / belt checks
	processorTick = 0.25,
	signTick = 0.5, -- world signs (pickup counter, processor readout)
	jarMaxAge = 30, -- a jar stuck this long is counted and removed
	leaderboardSeconds = 120,
	leaderboardSize = 10,
	dropSeconds = 0.35, -- a bought hive's fall into its slot
	studioPasses = false, -- true: Studio sessions keep the passes you own (otherwise Studio tests the free game)
}
