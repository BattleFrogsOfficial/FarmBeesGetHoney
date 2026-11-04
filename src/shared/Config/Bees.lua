--!strict
-- The twelve bee tiers, in ladder order. Honey per jar comes from Economy (honeyBase ^ (tier - 1));
-- `look` is the brief for the model built in milestone 5.

export type Bee = { tier: number, id: string, name: string, look: string }

local list: { Bee } = {
	{ tier = 1, id = "Honey", name = "Honey Bee", look = "Small, classic yellow and black" },
	{ tier = 2, id = "Bumble", name = "Bumble Bee", look = "Round, fuzzy, bigger" },
	{ tier = 3, id = "Carpenter", name = "Carpenter Bee", look = "Glossy black, blue sheen" },
	{ tier = 4, id = "Mason", name = "Mason Bee", look = "Metallic green" },
	{ tier = 5, id = "Sweat", name = "Sweat Bee", look = "Metallic teal, slim" },
	{ tier = 6, id = "Leafcutter", name = "Leafcutter Bee", look = "Carries a leaf" },
	{ tier = 7, id = "Mining", name = "Mining Bee", look = "Hard hat, dusty brown" },
	{ tier = 8, id = "Orchid", name = "Orchid Bee", look = "Iridescent purple" },
	{ tier = 9, id = "Cuckoo", name = "Cuckoo Bee", look = "Red and black, spiky" },
	{ tier = 10, id = "Giant", name = "Giant Bee", look = "Double size, armored" },
	{ tier = 11, id = "Royal", name = "Royal Bee", look = "Cape and crest" },
	{ tier = 12, id = "Queen", name = "Queen Bee", look = "Crown, glow, largest" },
}

return { list = list }
