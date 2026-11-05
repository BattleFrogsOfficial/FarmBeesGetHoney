--!strict
-- Tiny helpers for the bare-bones UI: flat frames, plain text, flat buttons. Styling comes from
-- Config/Hud so the look can change without touching the controllers.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hud = require(ReplicatedStorage.Shared.Config.Hud)

local UI = {}

function UI.frame(parent: Instance, name: string, size: UDim2, position: UDim2, anchor: Vector2?): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size
	f.Position = position
	f.AnchorPoint = anchor or Vector2.zero
	f.BackgroundColor3 = Hud.panelColor
	f.BackgroundTransparency = Hud.panelTransparency
	f.BorderSizePixel = 0
	f.Parent = parent
	return f
end

function UI.text(
	parent: Instance,
	name: string,
	size: UDim2,
	position: UDim2,
	text: string,
	textSize: number?
): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Size = size
	l.Position = position
	l.BackgroundTransparency = 1
	l.Font = Hud.font
	l.TextColor3 = Hud.textColor
	l.TextSize = textSize or Hud.textSize
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = text
	l.Parent = parent
	return l
end

function UI.button(
	parent: Instance,
	name: string,
	size: UDim2,
	position: UDim2,
	text: string,
	anchor: Vector2?
): TextButton
	local b = Instance.new("TextButton")
	b.Name = name
	b.Size = size
	b.Position = position
	b.AnchorPoint = anchor or Vector2.zero
	b.BackgroundColor3 = Hud.buttonColor
	b.BorderSizePixel = 0
	b.AutoButtonColor = true
	b.Font = Hud.font
	b.TextColor3 = Hud.textColor
	b.TextSize = Hud.textSize
	b.Text = text
	b.Parent = parent
	return b
end

return UI
