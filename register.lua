working_villages.register_villager("working_villages:villager_male", {
	hp_max     = 30,
	weight     = 20,
	mesh       = "character.b3d",
	textures   = {working_villages.random_texture("villager_male.png")},
	egg_image  = "villager_male_egg.png",
})
working_villages.register_villager("working_villages:villager_female", {
	hp_max     = 20,
	weight     = 20,
	mesh       = "character.b3d",
	textures   = {working_villages.random_texture("villager_female.png","character_castaway_female.png","character_farmer_female.png","character_princess.png", "character_rogue_female.png")},
	egg_image  = "villager_female_egg.png",
})
