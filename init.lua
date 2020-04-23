local init = os.clock()
if minetest.settings:get_bool("log_mods") then
  minetest.log("action", "[MOD] "..minetest.get_current_modname()..": loading")
else
  print("[MOD] "..minetest.get_current_modname()..": loading")
end

smart_villages={
	modpath=minetest.get_modpath("smart_villages"),
	debug_logging=true,
	func = {}
}

--helpers
dofile(smart_villages.modpath.."/pathfinder.lua")
dofile(smart_villages.modpath.."/forms.lua")
dofile(smart_villages.modpath.."/homes.lua")

--base
dofile(smart_villages.modpath.."/api.lua")
dofile(smart_villages.modpath.."/register.lua")
dofile(smart_villages.modpath.."/commanding_sceptre.lua")

dofile(smart_villages.modpath.."/deprecated.lua")

--jobs
dofile(smart_villages.modpath.."/jobs/util.lua")
dofile(smart_villages.modpath.."/jobs/empty.lua")

dofile(smart_villages.modpath.."/jobs/follow_player.lua")
dofile(smart_villages.modpath.."/jobs/plant_collector.lua")
dofile(smart_villages.modpath.."/jobs/woodcutter.lua")
--testing jobs
dofile(smart_villages.modpath.."/jobs/torcher.lua")
dofile(smart_villages.modpath.."/jobs/snowclearer.lua")

--ready
local time_to_load= os.clock() - init
if minetest.settings:get_bool("log_mods") then
  minetest.log("action", string.format("[MOD] "..minetest.get_current_modname()..": loaded in %.4f s", time_to_load))
else
  print(string.format("[MOD] "..minetest.get_current_modname()..": loaded in %.4f s", time_to_load))
end
