--!strict
-- The pass and cash-pack shop: one plain panel, opened from the HUD button or the hub board.
-- Robux prompts only; the server grants (MonetizationService). Ids of 0 = not on sale yet.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hud = require(ReplicatedStorage.Shared.Config.Hud)
local Passes = require(ReplicatedStorage.Shared.Config.Passes)
local Products = require(ReplicatedStorage.Shared.Config.Products)
local StateController = require(script.Parent.StateController)
local HudController = require(script.Parent.HudController)
local UI = require(script.Parent.Parent.UI)

local ShopController = {}

local PASS_TEXT: { [string]: string } = {
	Money2x = "2x Money: doubles money from the processor",
	AutoCollect = "Auto Collect: belt honey goes straight to the processor",
	LuckyJars = "Lucky Jars: jar variant odds x3",
	AutoMerge = "Auto Merge: merges for you every 10 s",
	BeeSpeed2x = "2x Bee Speed: jars every 4 s instead of 8",
	AutoBuy = "Auto Buy: buys a bee every 5 s while you're off the pads",
}
local PASS_ORDER = { "Money2x", "AutoCollect", "LuckyJars", "AutoMerge", "BeeSpeed2x", "AutoBuy" }
local PRODUCT_ORDER = { "CashSmall", "CashMedium", "CashLarge" }

local panel: Frame
local passButtons: { [string]: TextButton } = {}

local function refresh()
	local owned = StateController.snapshot and StateController.snapshot.passes or {}
	for name, button in passButtons do
		local pass = Passes[name]
		button.Text = if owned[name] then "OWNED" else "R$ " .. pass.price
		button.BackgroundColor3 = if owned[name] then Hud.buttonOff else Hud.buttonColor
	end
end

function ShopController.toggle()
	panel.Visible = not panel.Visible
	refresh()
end

function ShopController.Init()
	local gui = HudController.gui :: ScreenGui
	panel = UI.frame(gui, "ShopPanel", Hud.shopPanel.size, UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
	panel.Visible = false
	panel.BackgroundTransparency = 0.05
	UI.text(panel, "Title", UDim2.new(1, -60, 0, 32), UDim2.fromOffset(10, 4), "SHOP")
	local close = UI.button(panel, "Close", UDim2.fromOffset(36, 28), UDim2.new(1, -42, 0, 6), "X")
	close.Activated:Connect(ShopController.toggle)

	local h = Hud.shopPanel.rowHeight
	local y = 40
	local function row(text: string, buttonText: string, onClick: () -> ()): TextButton
		UI.text(panel, "Row", UDim2.new(1, -130, 0, h - 4), UDim2.fromOffset(10, y), text, Hud.smallTextSize).TextWrapped =
			true
		local b = UI.button(panel, "Buy", UDim2.fromOffset(100, h - 8), UDim2.new(1, -110, 0, y + 2), buttonText)
		b.Activated:Connect(onClick)
		y += h
		return b
	end
	local player = Players.LocalPlayer :: Player
	for _, name in PASS_ORDER do
		local pass = Passes[name]
		passButtons[name] = row(PASS_TEXT[name], "R$ " .. pass.price, function()
			local owned = StateController.snapshot and StateController.snapshot.passes or {}
			if owned[name] then
				return
			elseif pass.id == 0 then
				HudController.toast("Not on sale yet")
			else
				MarketplaceService:PromptGamePassPurchase(player, pass.id)
			end
		end)
	end
	for _, name in PRODUCT_ORDER do
		local product = Products[name]
		row(string.format("Cash pack: %d bees' worth of money", product.bees), "R$ " .. product.price, function()
			if product.id == 0 then
				HudController.toast("Not on sale yet")
			else
				MarketplaceService:PromptProductPurchase(player, product.id)
			end
		end)
	end
	HudController.onShop = ShopController.toggle
end

function ShopController.Start()
	StateController.Changed:Connect(refresh)
	-- The hub's shop board opens the panel too.
	task.spawn(function()
		local map = workspace:WaitForChild("Map")
		local hub = map:WaitForChild("Hub")
		local board = hub:WaitForChild("ShopBoard") :: BasePart
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Open shop"
		prompt.ObjectText = "Pass shop"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt.Triggered:Connect(function()
			if not panel.Visible then
				ShopController.toggle()
			end
		end)
		prompt.Parent = board
	end)
end

return ShopController
