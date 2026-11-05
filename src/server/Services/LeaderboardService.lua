--!strict
-- leaderstats (Prestige, lifetime Honey) and the hub board of top lifetime honey, from an
-- OrderedDataStore. Without DataStore access (Studio, unpublished) the board says so.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local Format = require(ReplicatedStorage.Shared.Format)
local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
local Types = require(ReplicatedStorage.Shared.Types)

local LeaderboardService = {}

local MAX_VALUE = 2 ^ 53
local names: { [number]: string } = {}

local function stats(player: Player): (NumberValue?, NumberValue?)
	local folder = player:FindFirstChild("leaderstats")
	if not folder then
		return nil, nil
	end
	return folder:FindFirstChild("Prestige") :: NumberValue?, folder:FindFirstChild("Honey") :: NumberValue?
end

local function updateStats(player: Player, data: Types.Profile)
	local prestige, honey = stats(player)
	if prestige and honey then
		prestige.Value = data.prestige
		honey.Value = math.floor(data.stats.lifetimeHoney)
	end
end

local function nameOf(userId: number): string
	if names[userId] then
		return names[userId]
	end
	local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
	names[userId] = if ok then name else "Player " .. userId
	return names[userId]
end

function LeaderboardService.Init() end

function LeaderboardService.Start()
	DataService.Loaded:Connect(function(player, data)
		local folder = Instance.new("Folder")
		folder.Name = "leaderstats"
		local prestige = Instance.new("NumberValue")
		prestige.Name = "Prestige"
		prestige.Parent = folder
		local honey = Instance.new("NumberValue")
		honey.Name = "Honey"
		honey.Parent = folder
		folder.Parent = player
		updateStats(player, data)
	end)
	DataService.Changed:Connect(updateStats)

	local ok, store = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, "LifetimeHoney_v1")
	local board = PlotService.hub and PlotService.hub.leaderboard
	if not ok or not board then
		return
	end
	while true do
		for player, data in DataService.players() do
			pcall(
				store.SetAsync,
				store,
				tostring(player.UserId),
				math.floor(math.min(data.stats.lifetimeHoney, MAX_VALUE))
			)
		end
		local fetched, pages = pcall(store.GetSortedAsync, store, false, GameConfig.leaderboardSize)
		if fetched then
			local lines = { "TOP HONEY" }
			for rank, entry in pages:GetCurrentPage() do
				table.insert(
					lines,
					string.format("%d. %s  %s", rank, nameOf(tonumber(entry.key) or 0), Format.number(entry.value))
				)
			end
			board.Text = table.concat(lines, "\n")
		else
			board.Text = "TOP HONEY\n(needs a published place with API access)"
		end
		task.wait(GameConfig.leaderboardSeconds)
	end
end

return LeaderboardService
