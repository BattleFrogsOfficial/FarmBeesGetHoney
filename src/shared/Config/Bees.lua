--!strict
-- The twelve bee tiers, in ladder order. Honey per jar comes from Economy (honeyBase ^ (tier - 1));
-- `label` / `color`: the colored floating text over each hive (white "Level N" goes under it).
-- `look` is the brief for the model (Config/BeeStyle).

export type Bee = { tier: number, id: string, name: string, label: string, color: Color3, look: string }

local list: { Bee } = {
	{
		tier = 1,
		id = "Honey",
		name = "Honey Bee",
		label = "Basic",
		color = Color3.fromRGB(220, 220, 220),
		look = "Small, classic yellow and black",
	},
	{
		tier = 2,
		id = "Bumble",
		name = "Bumble Bee",
		label = "Bumble Bee",
		color = Color3.fromRGB(120, 220, 90),
		look = "Round, fuzzy, bigger",
	},
	{
		tier = 3,
		id = "Carpenter",
		name = "Carpenter Bee",
		label = "Carpenter Bee",
		color = Color3.fromRGB(80, 150, 255),
		look = "Glossy black, blue sheen",
	},
	{
		tier = 4,
		id = "Mason",
		name = "Mason Bee",
		label = "Mason Bee",
		color = Color3.fromRGB(60, 200, 120),
		look = "Metallic green",
	},
	{
		tier = 5,
		id = "Sweat",
		name = "Sweat Bee",
		label = "Sweat Bee",
		color = Color3.fromRGB(60, 220, 220),
		look = "Metallic teal, slim",
	},
	{
		tier = 6,
		id = "Leafcutter",
		name = "Leafcutter Bee",
		label = "Leafcutter Bee",
		color = Color3.fromRGB(150, 230, 60),
		look = "Carries a leaf",
	},
	{
		tier = 7,
		id = "Mining",
		name = "Mining Bee",
		label = "Mining Bee",
		color = Color3.fromRGB(240, 160, 60),
		look = "Hard hat, dusty brown",
	},
	{
		tier = 8,
		id = "Orchid",
		name = "Orchid Bee",
		label = "Orchid Bee",
		color = Color3.fromRGB(190, 110, 255),
		look = "Iridescent purple",
	},
	{
		tier = 9,
		id = "Cuckoo",
		name = "Cuckoo Bee",
		label = "Cuckoo Bee",
		color = Color3.fromRGB(255, 80, 80),
		look = "Red and black, spiky",
	},
	{
		tier = 10,
		id = "Giant",
		name = "Giant Bee",
		label = "Giant Bee",
		color = Color3.fromRGB(255, 200, 40),
		look = "Double size, armored",
	},
	{
		tier = 11,
		id = "Royal",
		name = "Royal Bee",
		label = "Royal Bee",
		color = Color3.fromRGB(255, 110, 200),
		look = "Cape and crest",
	},
	{
		tier = 12,
		id = "Queen",
		name = "Queen Bee",
		label = "Queen Bee",
		color = Color3.fromRGB(255, 225, 90),
		look = "Crown, glow, largest",
	},
}

return { list = list }
