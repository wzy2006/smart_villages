local function is_night() return minetest.get_timeofday() < 0.2 or minetest.get_timeofday() > 0.76 end
local function find_snow(p) return minetest.get_node(p).name == "default:snow" end
local searching_range = {x = 10, y = 3, z = 10}

smart_villages.register_job("smart_villages:job_snowclearer", {
	description      = "smart_villages job : snowclearer",
	inventory_image  = "default_paper.png^memorandum_letters.png",
	jobfunc = function(self)
		if is_night() then
			self:goto_bed()
		else
			self:count_timer("snowclearer:search")
			self:count_timer("snowclearer:change_dir")
			self:handle_obstacles()
			if self:timer_exceeded("snowclearer:search",20) then
				local target = smart_villages.func.search_surrounding(self.object:getpos(), find_snow, searching_range)
				if target ~= nil then
					local destination = smart_villages.func.find_adjacent_clear(target)
					if destination==false then
						print("failure: no adjacent walkable found")
						destination = target
					end
					self:go_to(destination)
					self:dig(target)
				end
			elseif self:timer_exceeded("snowclearer:change_dir",50) then
				self:count_timer("snowclearer:search")
				self:change_direction_randomly()
			end
		end
	end,
})