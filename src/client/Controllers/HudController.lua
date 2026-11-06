--!strict
-- The bare-bones HUD: money, honey carried, prestige, shop tier, processor; one toast line; the
-- SHOP button. Layout and colors: Config/Hud.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Format = require(ReplicatedStorage.Shared.Format)
local Hud = require(ReplicatedStorage.Shared.Config.Hud)
local Bees = require(ReplicatedStorage.Shared.Config.Bees)
local Types = require(ReplicatedStorage.Shared.Types)
local StateController = require(script.Parent.StateController)
local UI = require(script.Parent.Parent.UI)

local HudController = {}

HudController.gui = nil :: ScreenGui?
HudController.onShop = nil :: (() -> ())?

local lines: { TextLabel } = {}
local toast: TextLabel
local toastId = 0

function HudController.toast(message: string)
	toastId += 1
	local id = toastId
	toast.Text = message
	toast.Parent.Visible = true
	task.delay(Hud.toast.seconds, function()
		if toastId == id then
			toast.Parent.Visible = false
		end
	end)
end

local function render(s: Types.Snapshot)
	local next = s.nextPrestige
	local top = s.highestTier > 0 and Bees.list[s.highestTier] or nil
	lines[1].Text = string.format("Money: %s", Format.money(s.money))
	lines[2].Text =
		string.format("Honey carried: %s   (on pad: %s)", Format.number(s.carriedHoney), Format.number(s.padHoney))
	lines[3].Text = string.format(
		"Prestige %d (x%.1f money)   Next: Tier %d + %s%s",
		s.prestige,
		s.moneyMult,
		next.tier,
		Format.money(next.price),
		if next.ready then "  READY" else ""
	)
	lines[4].Text = string.format(
		"Shop tier %d   Best bee: %s   Processor L%d (%s/s)%s",
		s.shopTier,
		if top then top.name else "none",
		s.processorLevel,
		Format.number(s.processorRate),
		if s.wallFull then "   WALL FULL: step on Merge" else ""
	)
end

function HudController.Init()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Hud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.Parent = (Players.LocalPlayer :: Player):WaitForChild("PlayerGui")
	HudController.gui = gui

	local panel = UI.frame(gui, "Stats", Hud.stats.size, Hud.stats.position, Hud.stats.anchor)
	for i = 1, 4 do
		lines[i] = UI.text(
			panel,
			"Line" .. i,
			UDim2.new(1, -16, 0, 24),
			UDim2.fromOffset(8, 4 + (i - 1) * 25),
			"",
			if i > 2 then Hud.smallTextSize else Hud.textSize
		)
	end

	local toastFrame = UI.frame(gui, "Toast", Hud.toast.size, Hud.toast.position, Vector2.new(0.5, 0))
	toastFrame.Visible = false
	toast = UI.text(toastFrame, "Text", UDim2.new(1, -16, 1, 0), UDim2.fromOffset(8, 0), "")
	toast.TextXAlignment = Enum.TextXAlignment.Center

	local shop = UI.button(gui, "Shop", Hud.shopButton.size, Hud.shopButton.position, "SHOP", Hud.shopButton.anchor)
	shop.Activated:Connect(function()
		if HudController.onShop then
			HudController.onShop()
		end
	end)
end

function HudController.Start()
	StateController.Changed:Connect(render)
	if StateController.snapshot then
		render(StateController.snapshot)
	end
	Remotes.get("Notify").OnClientEvent:Connect(function(message: string)
		HudController.toast(message)
	end)
end

return HudController
