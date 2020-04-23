smart_villages.register_job("smart_villages:job_empty", {
	description      = "smart_villages job : empty",
	inventory_image  = "default_paper.png",
	on_start         = function() end,
	on_stop          = function() end,
	on_resume        = function() end,
	on_pause         = function() end,
	on_step          = function() end,
})

-- only a recipe of the empty job is registered.
-- other job is created by writing on the empty job.
minetest.register_craft{
	output = "smart_villages:job_empty",
	recipe = {
		{"default:paper", "default:obsidian"},
	},
}
