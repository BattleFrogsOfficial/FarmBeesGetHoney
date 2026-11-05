--!strict
-- The bare-bones HUD: flat frames and plain text. Every size, position and color is here so the
-- look can be changed without touching the UI code.

return {
	font = Enum.Font.GothamBold,
	textColor = Color3.fromRGB(255, 255, 255),
	panelColor = Color3.fromRGB(30, 30, 36),
	panelTransparency = 0.25,
	buttonColor = Color3.fromRGB(60, 120, 200),
	buttonOff = Color3.fromRGB(90, 90, 90),
	textSize = 18,
	smallTextSize = 14,

	-- Stats panel (top-center)
	stats = { position = UDim2.new(0.5, 0, 0, 8), anchor = Vector2.new(0.5, 0), size = UDim2.fromOffset(420, 104) },
	-- Toast line under it
	toast = { position = UDim2.new(0.5, 0, 0, 120), size = UDim2.fromOffset(420, 32), seconds = 3 },
	-- Shop button (bottom-right) and panel (center)
	shopButton = { position = UDim2.new(1, -12, 1, -12), anchor = Vector2.new(1, 1), size = UDim2.fromOffset(110, 44) },
	shopPanel = { size = UDim2.fromOffset(460, 420), rowHeight = 40 },
}
