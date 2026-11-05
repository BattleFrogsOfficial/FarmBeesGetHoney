--!strict
-- Game passes (checked live on join and on purchase, never saved) and the cash-pack developer
-- products (granted once per PurchaseId, saved before Roblox is told it was granted).
-- Config ids of 0 are skipped: create the item in Creator Hub and put its id in Config.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DataService = require(script.Parent.DataService)
local Net = require(script.Parent.Parent.Util.Net)
local Format = require(ReplicatedStorage.Shared.Format)
local Shop = require(ReplicatedStorage.Shared.Shop)
local Passes = require(ReplicatedStorage.Shared.Config.Passes)
local Products = require(ReplicatedStorage.Shared.Config.Products)
local GameConfig = require(ReplicatedStorage.Shared.Config.Game)

local MonetizationService = {}

local MAX_RECEIPTS = 50

local function grantPass(player: Player, name: string)
	local owned = DataService.passes[player]
	if not owned or owned[name] then
		return
	end
	owned[name] = true
	local data = DataService.get(player)
	if data and name == "AutoCollect" and data.padHoney > 0 then
		data.queuedHoney += data.padHoney
		data.padHoney = 0
	end
	DataService.changed(player)
end

local function checkPasses(player: Player)
	-- Studio says the place's creator owns every pass: test the free game unless asked not to.
	if RunService:IsStudio() and not GameConfig.studioPasses then
		return
	end
	for name, pass in Passes do
		if pass.id ~= 0 then
			local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.id)
			if ok and owns then
				grantPass(player, name)
			end
		end
	end
end

local function pruneReceipts(receipts: { [string]: number })
	local list = {}
	for id, at in receipts do
		table.insert(list, { id = id, at = at })
	end
	if #list <= MAX_RECEIPTS then
		return
	end
	table.sort(list, function(a, b)
		return a.at < b.at
	end)
	for i = 1, #list - MAX_RECEIPTS do
		receipts[list[i].id] = nil
	end
end

local function processReceipt(info): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(info.PlayerId)
	local data = player and DataService.get(player)
	if not player or not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local id = tostring(info.PurchaseId)
	if data.receipts[id] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local product = nil
	for _, p in Products do
		if p.id ~= 0 and p.id == info.ProductId then
			product = p
		end
	end
	if not product then
		warn("[MonetizationService] unknown product", info.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local money = Shop.cashPack(data, product.bees)
	data.money += money
	data.receipts[id] = os.time()
	pruneReceipts(data.receipts)
	DataService.changed(player)
	Net.notify(player, "+" .. Format.money(money) .. "!", "success")
	if DataService.saveNow(player) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function MonetizationService.Init()
	MarketplaceService.ProcessReceipt = processReceipt
end

function MonetizationService.Start()
	if RunService:IsStudio() then
		for name, pass in Passes do
			if pass.id == 0 then
				print("[Monetization] pass not linked yet (id 0):", name)
			end
		end
		for name, product in Products do
			if product.id == 0 then
				print("[Monetization] product not linked yet (id 0):", name)
			end
		end
	end
	DataService.Loaded:Connect(function(player)
		checkPasses(player)
	end)
	for player in DataService.players() do
		task.spawn(checkPasses, player)
	end
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		for name, pass in Passes do
			if pass.id ~= 0 and pass.id == passId then
				grantPass(player, name)
				Net.notify(player, "Thanks! Pass active.", "success")
			end
		end
	end)
end

return MonetizationService
