--!strict
-- Game passes. id = 0 means not created in Creator Hub yet (never prompted, never owned).
-- Ownership is checked live with MarketplaceService on join and on purchase; never saved.

return {
	Money2x = { id = 0, price = 19, launch = true, moneyMult = 2 },
	AutoCollect = { id = 0, price = 59, launch = true },
	LuckyJars = { id = 0, price = 49, launch = true, variantOddsMult = 3 },
	AutoMerge = { id = 0, price = 29, launch = false },
	BeeSpeed2x = { id = 0, price = 39, launch = false, jarIntervalMult = 0.5 },
	AutoBuy = { id = 0, price = 79, launch = false },
}
