local function find_tree(p)
	local adj_node = minetest.get_node(p)
	if minetest.get_item_group(adj_node.name, "tree") > 0 then
		return true
	end
	return false
end

actions={}
actions.WALK_TO_PLANT = {to_state=function(self, path, destination, target)
				--print("found place to plant at: " .. destination.x .. "," .. destination.y .. "," .. destination.z)
				self.path = path
				self.destination = destination
				self.target = target
				self.time_counters[1] = 0 -- find path interval
				self.time_counters[2] = 0
				if self.path ~= nil then
					self:change_direction(self.path[1])
				else
					self:change_direction(self.destination)
				end
				self:set_animation(working_villages.animation_frames.WALK)
			end,
			func = function(self)
				if working_villages.func.is_near(self, {x=self.destination.x,y=self.object:getpos().y,z=self.destination.z}, 1.5) then
					return true
				end
				local MAX_WALK_TIME = 800
				local FIND_PATH_TIME_INTERVAL = 50
				if self.time_counters[2] >= MAX_WALK_TIME then -- time over.
					self.state = working_villages.registered_jobs["working_villages:job_woodcutter"].states.SEARCH
					working_villages.registered_jobs["working_villages:job_woodcutter"].states.SEARCH.to_state(self)
					return
				end

				self.time_counters[1] = self.time_counters[1] + 1
				self.time_counters[2] = self.time_counters[2] + 1

				if self.time_counters[1] >= FIND_PATH_TIME_INTERVAL then
					self.time_counters[1] = 0
					local val_pos = working_villages.func.validate_pos(self.object:getpos())
					local path = minetest.find_path(val_pos, self.destination, 10, 1, 1, "A*")
					if path == nil then
						path = minetest.find_path(val_pos, {x=self.destination.x,y=val_pos.y,z=self.destination.z}, 10, 1, 1, "A*")
					end
					if path == nil then
						self.state = working_villages.registered_jobs["working_villages:job_woodcutter"].states.SEARCH
						working_villages.registered_jobs["working_villages:job_woodcutter"].states.SEARCH.to_state(self)
						return
					end
					self.path = path
				end

				-- follow path
				if self.path == nil then
					self.path={}
					self.path[1]=self.destination
				end
				if working_villages.func.is_near(self, self.path[1], 0.5) then
					table.remove(self.path, 1)

					if #self.path == 0 then -- end of path
						return true
					else -- else next step, follow next path.
						self:change_direction(self.path[1])
						self.time_counters[1] = 0
					end
				else
					-- if villager is stopped by obstacles, the villager must jump.
					local velocity = self.object:getvelocity()
					if velocity.y == 0 then
						local front_node = self:get_front_node()
						if front_node.name ~= "air" and minetest.registered_nodes[front_node.name] ~= nil
						and minetest.registered_nodes[front_node.name].walkable
						and not (minetest.get_item_group(front_node.name, "fence") > 0) then
							self.object:setvelocity{x = velocity.x, y = 6, z = velocity.z}
						end
					end
				end
			end,
			self_condition=function(self)
				local wield_stack = self:get_wield_item_stack()
				if minetest.get_item_group(wield_stack:get_name(), "sapling") > 0
				or self:move_main_to_wield(function(itemname)	return (minetest.get_item_group(itemname, "sapling") > 0) end) then
					return true
				end
				return false
			end,
			search_condition=function(pos)
				local node = minetest.get_node(pos)
				local lpos = vector.add(pos, {x = 0, y = -1, z = 0})
				local lnode = minetest.get_node(lpos)
				local light_level = minetest.get_node_light(pos)
				if node.name == "air" 
				and minetest.get_item_group(lnode.name, "soil") > 0
				and light_level > 12 then
					return true
				end
				return false
			end,}
actions.WALK_TO_CUT = {to_state=function(self, path, destination,target)
				--print("found place to cut at: " .. destination.x .. "," .. destination.y .. "," .. destination.z)
				self.path = path
				self.destination = destination
				self.target = target
				self.time_counters[1] = 0 -- folow path interval
				self.time_counters[2] = 0
				if self.path ~= nil then
					self:change_direction(self.path[1])
				else
					self:change_direction(self.destination)
				end
				self:set_animation(working_villages.animation_frames.WALK)
			end,
			func = function(self)
				if working_villages.func.is_near(self, {x=self.destination.x,y=self.object:getpos().y,z=self.destination.z}, 1.5) then
					return true
				end
				local MAX_WALK_TIME = 800
				local FIND_PATH_TIME_INTERVAL = 50
				if self.time_counters[2] >= MAX_WALK_TIME then 
					--print("time over: back to searching")
					self.state = working_villages.registered_jobs["working_villages:job_woodcutter"].states.SEARCH
					working_villages.registered_jobs["working_villages:job_woodcutter"].states.SEARCH.to_state(self)
					return
				end

				self.time_counters[1] = self.time_counters[1] + 1
				self.time_counters[2] = self.time_counters[2] + 1

				if self.time_counters[1] >= FIND_PATH_TIME_INTERVAL then
					self.time_counters[1] = 0
					--print("looking for a new path")
					local val_pos = working_villages.func.validate_pos(self.object:getpos())
					local path = minetest.find_path(val_pos, self.destination, 10, 1, 1, "A*")
					if path == nil then
						path = minetest.find_path(val_pos, {x=self.destination.x,y=val_pos.y,z=self.destination.z}, 10, 1, 1, "A*")
					end
					if path == nil then
						--print("no new path found: back to searching")
						self.state = working_villages.registered_jobs["working_villages:job_woodcutter"].states.SEARCH
						working_villages.registered_jobs["working_villages:job_woodcutter"].states.SEARCH.to_state(self)
						return
					end
					self.path = path
				end

				-- follow path

				if self.path == nil then
					self.path={}
					self.path[1]=self.destination
				end
				if working_villages.func.is_near(self, self.path[1], 0.5) then
					table.remove(self.path, 1)

					if #self.path == 0 then -- end of path
						return true
					else -- else next step, follow next path.
						self:change_direction(self.path[1])
						self.time_counters[1] = 0
					end

				else
					-- if villager is stopped by obstacles, the villager must jump.
					local velocity = self.object:getvelocity()
					if velocity.y == 0 then
						local front_node = self:get_front_node()
						if front_node.name ~= "air" and minetest.registered_nodes[front_node.name] ~= nil
						and minetest.registered_nodes[front_node.name].walkable
						and not (minetest.get_item_group(front_node.name, "fence") > 0) then
							self.object:setvelocity{x = velocity.x, y = 6, z = velocity.z}
						end
					end
				end
			end,
			search_condition = find_tree,}
actions.PLANT = {to_state=function(self)
			local wield_stack = self:get_wield_item_stack()
			if minetest.get_item_group(wield_stack:get_name(), "sapling") > 0
			or self:move_main_to_wield(function(itemname)	return (minetest.get_item_group(itemname, "sapling") > 0) end) then
				self.time_counters[1] = 0
				self.object:setvelocity{x = 0, y = 0, z = 0}
				self:set_animation(working_villages.animation_frames.MINE)
				self:set_yaw_by_direction(vector.subtract(self.target, self.object:getpos()))
				return
			else
				self.state = working_villages.registered_jobs["working_villages:job_woodcutter"].states.SEARCH
				working_villages.registered_jobs["working_villages:job_woodcutter"].states.SEARCH.to_state(self)
				return
			end
		end,
		func = function(self, dtime)
			if self.time_counters[1] >= 15 then
				local stack = self:get_wield_item_stack()
				local itemname = stack:get_name()
				local pointed_thing = {
					type = "node",
					under = vector.add(self.target, {x = 0, y = -1, z = 0}),
					above = self.target,
				}
				--minetest.item_place(stack, minetest.get_player_by_name(self.owner_name), pointed_thing)
				minetest.set_node(pointed_thing.above,{name = itemname})
				stack:take_item(1)
				self:set_wield_item_stack(stack)
				self.state = working_villages.registered_jobs["working_villages:job_woodcutter"].states.SEARCH
				working_villages.registered_jobs["working_villages:job_woodcutter"].states.SEARCH.to_state(self)
			else
				self.time_counters[1] = self.time_counters[1] + 1
			end
		end,}
actions.CUT = {to_state=function(self)
			self.time_counters[1] = 0
			self.object:setvelocity{x = 0, y = 0, z = 0}
			self:set_animation(working_villages.animation_frames.MINE)
			self:set_yaw_by_direction(vector.subtract(self.target, self.object:getpos()))
		end,
		func = function(self, dtime)
			if self.time_counters[1] >= 30 then
				local destnode = minetest.get_node(self.target)
				minetest.remove_node(self.target)
				local stacks = minetest.get_node_drops(destnode.name)
				for _, stack in ipairs(stacks) do
					local leftover = self:add_item_to_main(stack)
					minetest.add_item(self.target, leftover)
				end
				local sounds = minetest.registered_nodes[destnode.name].sounds
				if sounds then
					local sound = sounds.dug
					if sound then
						minetest.sound_play(sound,{object=self.object, max_hear_distance = 10})
					end
				end
				self.state = working_villages.registered_jobs["working_villages:job_woodcutter"].states.SEARCH
				working_villages.registered_jobs["working_villages:job_woodcutter"].states.SEARCH.to_state(self)
				return
			else
				self.time_counters[1] = self.time_counters[1] + 1
			end
		end,}
actions.WALK_TO_PLANT.next_state = actions.PLANT
actions.WALK_TO_CUT.next_state = actions.CUT
local woodcutter_prop = {
	searching_range = {x = 10, y = 10, z = 10}
}

working_villages.func.villager_state_machine_job("job_woodcutter","woodcutter",actions,woodcutter_prop)