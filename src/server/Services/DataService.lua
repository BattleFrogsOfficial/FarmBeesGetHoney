--!strict
-- Owns player profiles (ProfileStore, session-locked so two servers never write one save) and
-- pushes state snapshots to clients. Saved every Config/Game.autoSaveSeconds and on leave.
-- Any field missing on load takes its template default (profile:Reconcile), so later versions add
-- fields without a migration.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileStore = require(ReplicatedStorage.Packages.ProfileStore)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Signal = require(ReplicatedStorage.Shared.Signal)
local Economy = require(ReplicatedStorage.Shared.Economy)
local Merge = require(ReplicatedStorage.Shared.Merge)
local EconomyConfig = require(ReplicatedStorage.Shared.Config.Economy)
local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Types = require(ReplicatedStorage.Shared.Types)
local Net = require(script.Parent.Parent.Util.Net)

local DataService = {}

DataService.Loaded = Signal.new() -- (player, data) profile ready
DataService.Changed = Signal.new() -- (player, data) after each batched snapshot push

local TEMPLATE: Types.Profile = {
	version = 1,
	money = EconomyConfig.startingMoney,
	prestige = 0,
	hives = {},
	highestTier = 0,
	shopBuys = 0,
	processorLevel = 1,
	queuedHoney = 0,
	padHoney = 0,
	stats = { lifetimeHoney = 0, lifetimeMoney = 0, jarsMade = 0, merges = 0, bestVariant = "" },
}

local store = ProfileStore.New("PlayerData_v1", TEMPLATE)
local profiles: { [Player]: any } = {}
local releasing: { [Player]: boolean } = {}
local dirty: { [Player]: boolean } = {}
local releaseHooks: { (Player, Types.Profile) -> () } = {}

-- Game pass ownership for this session only (MonetizationService fills it; never saved).
DataService.passes = {} :: { [Player]: { [string]: boolean } }

function DataService.get(player: Player): Types.Profile?
	local profile = profiles[player]
	return profile and profile.Data
end

function DataService.hasPass(player: Player, passId: string): boolean
	local owned = DataService.passes[player]
	return owned ~= nil and owned[passId] == true
end

-- Runs before the final save on leave (e.g. jars still on the belt go into padHoney).
function DataService.onRelease(fn: (Player, Types.Profile) -> ())
	table.insert(releaseHooks, fn)
end

function DataService.changed(player: Player)
	dirty[player] = true
end

local function snapshot(player: Player, data: Types.Profile): Types.Snapshot
	return {
		money = data.money,
		prestige = data.prestige,
		hives = data.hives,
		highestTier = data.highestTier,
		shopTier = Economy.shopTier(data.highestTier),
		shopBuys = data.shopBuys,
		processorLevel = data.processorLevel,
		queuedHoney = data.queuedHoney,
		padHoney = data.padHoney,
		canMerge = Merge.canMerge(data.hives),
		passes = DataService.passes[player] or {},
	}
end

local function finalize(player: Player, profile: any)
	if profile.finalized then
		return
	end
	profile.finalized = true
	for _, hook in releaseHooks do
		local ok, err = pcall(hook, player, profile.Data)
		if not ok then
			warn("[DataService] release hook failed:", err)
		end
	end
end

local function release(player: Player)
	local profile = profiles[player]
	if not profile then
		return
	end
	releasing[player] = true
	profiles[player] = nil
	dirty[player] = nil
	DataService.passes[player] = nil
	finalize(player, profile)
	profile:EndSession()
	releasing[player] = nil
end

local function onPlayerAdded(player: Player)
	local profile = store:StartSessionAsync(tostring(player.UserId), {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})
	if not profile then
		player:Kick("Couldn't load your farm. Please rejoin.")
		return
	end
	profile:AddUserId(player.UserId)
	profile:Reconcile()
	-- OnLastSave also covers server shutdown (ProfileStore's own BindToClose).
	profile.OnLastSave:Connect(function()
		finalize(player, profile)
	end)
	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		-- Only a session taken by another server needs a kick; not our own release or shutdown.
		if not releasing[player] and not ProfileStore.IsClosing and player.Parent == Players then
			player:Kick("Your farm was opened on another server. Please rejoin.")
		end
	end)
	if player.Parent ~= Players then
		profile:EndSession()
		return
	end
	profiles[player] = profile
	DataService.passes[player] = DataService.passes[player] or {}
	DataService.Loaded:Fire(player, profile.Data)
	DataService.changed(player)
end

function DataService.Init()
	ProfileStore.SetConstant("AUTO_SAVE_PERIOD", GameConfig.autoSaveSeconds)
	Net.setDataGetter(DataService.get)
end

function DataService.Start()
	Players.PlayerRemoving:Connect(release)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)

	-- Batch snapshot pushes so many changes in one frame send one message.
	local state = Remotes.get("State")
	while true do
		task.wait(GameConfig.stateFlushInterval)
		for player in dirty do
			dirty[player] = nil
			local data = DataService.get(player)
			if data then
				state:FireClient(player, snapshot(player, data))
				DataService.Changed:Fire(player, data)
			end
		end
	end
end

return DataService
