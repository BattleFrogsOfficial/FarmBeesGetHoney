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
	studioPasses = false, -- true: Studio sessions keep the passes you own (otherwise Studio tests the free game)
}
