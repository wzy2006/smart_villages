smart_villages.animation_frames = {
	STAND     = { x=  0, y= 79, },
	LAY       = { x=162, y=166, },
	WALK      = { x=168, y=187, },
	MINE      = { x=189, y=198, },
	WALK_MINE = { x=200, y=219, },
	SIT       = { x= 81, y=160, },
}

smart_villages.registered_villagers = {}

smart_villages.registered_jobs = {}

smart_villages.registered_eggs = {}

-- smart_villages.is_job reports whether a item is a job item by the name.
function smart_villages.is_job(item_name)
	if smart_villages.registered_jobs[item_name] then
		return true
	end
	return false
end

-- smart_villages.is_villager reports whether a name is villager's name.
function smart_villages.is_villager(name)
	if smart_villages.registered_villagers[name] then
		return true
	end
	return false
end

---------------------------------------------------------------------

-- smart_villages.villager represents a table that contains common methods
-- for villager object.
-- this table must be contains by a metatable.__index of villager self tables.
-- minetest.register_entity set initial properties as a metatable.__index, so
-- this table's methods must be put there.
smart_villages.villager = {}

-- smart_villages.villager.get_inventory returns a inventory of a villager.
function smart_villages.villager:get_inventory()
	return minetest.get_inventory {
		type = "detached",
		name = self.inventory_name,
	}
end

-- smart_villages.villager.get_job_name returns a name of a villager's current job.
function smart_villages.villager:get_job_name()
	local inv = self:get_inventory()
	return inv:get_stack("job", 1):get_name()
end

-- smart_villages.villager.get_job returns a villager's current job definition.
function smart_villages.villager:get_job()
	local name = self:get_job_name()
	if name ~= "" then
		return smart_villages.registered_jobs[name]
	end
	return nil
end

-- smart_villages.villager.get_nearest_player returns a player object who
-- is the nearest to the villager.
function smart_villages.villager:get_nearest_player(range_distance)
	local player, min_distance = nil, range_distance
	local position = self.object:getpos()

	local all_objects = minetest.get_objects_inside_radius(position, range_distance)
	for _, object in pairs(all_objects) do
		if object:is_player() then
			local player_position = object:getpos()
			local distance = vector.distance(position, player_position)

			if distance < min_distance then
				min_distance = distance
				player = object
			end
		end
	end
	return player
end

-- woriking_villages.villager.get_nearest_item_by_condition returns the position of
-- an item that returns true for the condition
function smart_villages.villager:get_nearest_item_by_condition(cond, range_distance)
	local max_distance=range_distance
	if type(range_distance) == "table" then
		max_distance=math.max(math.max(range_distance.x,range_distance.y),range_distance.z)
	end
	local item = nil
	local min_distance = max_distance
	local position = self.object:getpos()

	local all_objects = minetest.get_objects_inside_radius(position, max_distance)
	for _, object in pairs(all_objects) do
		if not object:is_player() and object:get_luaentity() and object:get_luaentity().name == "__builtin:item" then
			local found_item = ItemStack(object:get_luaentity().itemstring):to_table()
			if found_item then
				if cond(found_item) then
					local item_position = object:getpos()
					local distance = vector.distance(position, item_position)

					if distance < min_distance then
						min_distance = distance
						item = object
					end
				end
			end
		end
	end
	return item;
end

-- smart_villages.villager.get_front returns a position in front of the villager.
function smart_villages.villager:get_front()
	local direction = self:get_look_direction()
	if math.abs(direction.x) >= 0.5 then
		if direction.x > 0 then	direction.x = 1	else direction.x = -1 end
	else
		direction.x = 0
	end

	if math.abs(direction.z) >= 0.5 then
		if direction.z > 0 then	direction.z = 1	else direction.z = -1 end
	else
		direction.z = 0
	end

	--direction.y = direction.y - 1

	return vector.add(vector.round(self.object:getpos()), direction)
end

-- smart_villages.villager.get_front_node returns a node that exists in front of the villager.
function smart_villages.villager:get_front_node()
	local front = self:get_front()
	return minetest.get_node(front)
end

-- smart_villages.villager.get_back returns a position behind the villager.
function smart_villages.villager:get_back()
	local direction = self:get_look_direction()
	if math.abs(direction.x) >= 0.5 then
		if direction.x > 0 then	direction.x = -1
		else direction.x = 1 end
	else
		direction.x = 0
	end

	if math.abs(direction.z) >= 0.5 then
		if direction.z > 0 then	direction.z = -1
		else direction.z = 1 end
	else
		direction.z = 0
	end

	--direction.y = direction.y - 1

	return vector.add(vector.round(self.object:getpos()), direction)
end

-- smart_villages.villager.get_back_node returns a node that exists behind the villager.
function smart_villages.villager:get_back_node()
	local back = self:get_back()
	return minetest.get_node(back)
end

-- smart_villages.villager.get_look_direction returns a normalized vector that is
-- the villagers's looking direction.
function smart_villages.villager:get_look_direction()
	local yaw = self.object:getyaw()
	return vector.normalize{x = -math.sin(yaw), y = 0.0, z = math.cos(yaw)}
end

-- smart_villages.villager.set_animation sets the villager's animation.
-- this method is wrapper for self.object:set_animation.
function smart_villages.villager:set_animation(frame)
	self.object:set_animation(frame, 15, 0)
	if frame == smart_villages.animation_frames.LAY then
		local dir = self:get_look_direction()
		local dirx = math.abs(dir.x)*0.5
		local dirz = math.abs(dir.z)*0.5
		self.object:set_properties({collisionbox={-0.5-dirx, 0, -0.5-dirz, 0.5+dirx, 0.5, 0.5+dirz}})
	else
		self.object:set_properties({collisionbox={-0.25, 0, -0.25, 0.25, 1.75, 0.25}})
	end
end

-- smart_villages.villager.set_yaw_by_direction sets the villager's yaw
-- by a direction vector.
function smart_villages.villager:set_yaw_by_direction(direction)
	self.object:setyaw(math.atan2(direction.z, direction.x) - math.pi / 2)
end

-- smart_villages.villager.get_wield_item_stack returns the villager's wield item's stack.
function smart_villages.villager:get_wield_item_stack()
	local inv = self:get_inventory()
	return inv:get_stack("wield_item", 1)
end

-- smart_villages.villager.set_wield_item_stack sets villager's wield item stack.
function smart_villages.villager:set_wield_item_stack(stack)
	local inv = self:get_inventory()
	inv:set_stack("wield_item", 1, stack)
end

-- smart_villages.villager.add_item_to_main add item to main slot.
-- and returns leftover.
function smart_villages.villager:add_item_to_main(stack)
	local inv = self:get_inventory()
	return inv:add_item("main", stack)
end

-- smart_villages.villager.move_main_to_wield moves itemstack from main to wield.
-- if this function fails then returns false, else returns true.
function smart_villages.villager:move_main_to_wield(pred)
	local inv = self:get_inventory()
	local main_size = inv:get_size("main")

	for i = 1, main_size do
		local stack = inv:get_stack("main", i)
		if pred(stack:get_name()) then
			local wield_stack = inv:get_stack("wield_item", 1)
			inv:set_stack("wield_item", 1, stack)
			inv:set_stack("main", i, wield_stack)
			return true
		end
	end
	return false
end

-- smart_villages.villager.is_named reports the villager is still named.
function smart_villages.villager:is_named()
	return self.nametag ~= ""
end

-- smart_villages.villager.has_item_in_main reports whether the villager has item.
function smart_villages.villager:has_item_in_main(pred)
	local inv = self:get_inventory()
	local stacks = inv:get_list("main")

	for _, stack in ipairs(stacks) do
		local itemname = stack:get_name()
		if pred(itemname) then
			return true
		end
	end
end

-- smart_villages.villager.change_direction change direction to destination and velocity vector.
function smart_villages.villager:change_direction(destination)
	local position = self.object:getpos()
	local direction = vector.subtract(destination, position)
	direction.y = 0
	local velocity = vector.multiply(vector.normalize(direction), 1.5)

	self.object:setvelocity(velocity)
	self:set_yaw_by_direction(direction)
end

-- smart_villages.villager.change_direction_randomly change direction randonly.
function smart_villages.villager:change_direction_randomly()
	local direction = {
		x = math.random(0, 5) * 2 - 5,
		y = 0,
		z = math.random(0, 5) * 2 - 5,
	}
	local velocity = vector.multiply(vector.normalize(direction), 1.5)
	self.object:setvelocity(velocity)
	self:set_yaw_by_direction(direction)
	self:set_animation(smart_villages.animation_frames.WALK)
end

-- smart_villages.villager.get_timer get the value of a counter.
function smart_villages.villager:get_timer(timerId)
	return self.time_counters[timerId]
end

-- smart_villages.villager.set_timer set the value of a counter.
function smart_villages.villager:set_timer(timerId,value)
	assert(type(value)=="number","timers need to be countable")
	self.time_counters[timerId]=value
end

-- smart_villages.villager.clear_timers set all counters to 0.
function smart_villages.villager:clear_timers()
	for timerId,_ in pairs(self.time_counters) do
		self.time_counters[timerId] = 0
	end
end

-- smart_villages.villager.count_timer count a counter up by 1.
function smart_villages.villager:count_timer(timerId)
	if not self.time_counters[timerId] then
		minetest.log("info","timer \""..timerId.."\" was not initialized")
		self.time_counters[timerId] = 0
	end
	self.time_counters[timerId] = self.time_counters[timerId] + 1
end

-- smart_villages.villager.count_timers count all counters up by 1.
function smart_villages.villager:count_timers()
	for id, counter in pairs(self.time_counters) do
		self.time_counters[id] = counter + 1
	end
end

-- smart_villages.villager.timer_exceeded if a timer exceeds the limit it will be reset and true is returned
function smart_villages.villager:timer_exceeded(timerId,limit)
	if self:get_timer(timerId)>=limit then
		self:set_timer(timerId,0)
		return true
	else
		return false
	end
end

-- smart_villages.villager.update_infotext updates the infotext of the villager.
function smart_villages.villager:update_infotext()
	local infotext = ""
	local job_name = self:get_job()

	if job_name ~= nil then
		job_name = job_name.description
		infotext = infotext .. job_name .. "\n"
	else
		infotext = infotext .. "this villager is inactive\nNo job\n"
	end
	infotext = infotext .. "[Owner] : " .. self.owner_name
	if self.pause=="resting" then
		infotext = infotext .. "\nthis villager is resting"
	elseif self.pause=="sleeping" then
		infotext = infotext .. "\nthis villager is sleeping"
	elseif self.pause=="active" then
		infotext = infotext .. "\nthis villager is active"
	end
	self.object:set_properties{infotext = infotext}
end

-- smart_villages.villager.is_near checks if the villager is withing the radius of a position
function smart_villages.villager:is_near(pos, distance)
	local p = self.object:getpos()
	p.y = p.y + 0.5
	return vector.distance(p, pos) < distance
end

--smart_villages.villager.handle_obstacles(ignore_fence,ignore_doors)
--if the villager hits a walkable he wil jump
--if ignore_fence is false and the villager hits a door he opens it
--if ignore_fence is false the villager will not jump over fences
function smart_villages.villager:handle_obstacles(ignore_fence,ignore_doors)
	local velocity = self.object:getvelocity()
	--local inside_node = minetest.get_node(self.object:getpos())
	--if string.find(inside_node.name,"doors:door") and not ignore_doors then
	--	self:change_direction(vector.round(self.object:getpos()))
	--end
	if velocity.y == 0 then
		local front_node = self:get_front_node()
		local above_node = self:get_front()
		above_node = vector.add(above_node,{x=0,y=1,z=0})
		above_node = minetest.get_node(above_node)
		if minetest.get_item_group(front_node.name, "fence") > 0 and not(ignore_fence) then
			self:change_direction_randomly()
		elseif string.find(front_node.name,"doors:door") and not(ignore_doors) then
			local door = doors.get(self:get_front())
			door:open()
		elseif minetest.registered_nodes[front_node.name].walkable
			and not(minetest.registered_nodes[above_node.name].walkable) then

			self.object:setvelocity{x = velocity.x, y = 6, z = velocity.z}
		end
		if not ignore_doors then
			local back_pos = self:get_back()
			if string.find(minetest.get_node(back_pos).name,"doors:door") then
				local door = doors.get(back_pos)
				door:close()
			end
		end
	end
end

-- smart_villages.villager.pickup_item pickup items placed and put it to main slot.
function smart_villages.villager:pickup_item()
	local pos = self.object:getpos()
	local radius = 1.0
	local all_objects = minetest.get_objects_inside_radius(pos, radius)

	for _, obj in ipairs(all_objects) do
		if not obj:is_player() and obj:get_luaentity() and obj:get_luaentity().itemstring then
			local itemstring = obj:get_luaentity().itemstring
			local stack = ItemStack(itemstring)
			if stack and stack:to_table() then
				local name = stack:to_table().name

				if minetest.registered_items[name] ~= nil then
					local inv = self:get_inventory()
					local leftover = inv:add_item("main", stack)

					minetest.add_item(obj:getpos(), leftover)
					obj:get_luaentity().itemstring = ""
					obj:remove()
				end
			end
		end
	end
end

-- smart_villages.villager.is_active check if the villager is paused.
function smart_villages.villager:is_active()
	return self.pause == "active"
end

dofile(smart_villages.modpath.."/async_actions.lua") --load states

function smart_villages.villager:set_state(id) --deprecated
	if id == "idle" then
		print("the idle state is deprecated")
	elseif id == "goto_dest" then
		print("use self:go_to(pos) instead of self:set_state(\"goto\")")
		self:go_to(self.destination)
	elseif id == "job" then
		print("the job state is not nessecary anymore")
	elseif id == "dig_target" then
		print("use self:dig(pos) instead of self:set_state(\"dig_target\")")
		self:dig(self.target)
	elseif id == "place_wield" then
		print("use self:place(itemname,pos) instead of self:set_state(\"place_wield\")")
		local wield_stack = self:get_wield_item_stack()
		self:place(wield_stack:get_name(),self.target)
	end
end

---------------------------------------------------------------------

-- smart_villages.manufacturing_data represents a table that contains manufacturing data.
-- this table's keys are product names, and values are manufacturing numbers
-- that has been already manufactured.
smart_villages.manufacturing_data = (function()
	local file_name = minetest.get_worldpath() .. "/smart_villages_data"

	minetest.register_on_shutdown(function()
		local file = io.open(file_name, "w")
		file:write(minetest.serialize(smart_villages.manufacturing_data))
		file:close()
	end)

	local file = io.open(file_name, "r")
	if file ~= nil then
		local data = file:read("*a")
		file:close()
		return minetest.deserialize(data)
	end
	return {}
end) ()

--------------------------------------------------------------------

-- register empty item entity definition.
-- this entity may be hold by villager's hands.
do
	minetest.register_craftitem("smart_villages:dummy_empty_craftitem", {
		wield_image = "smart_villages_dummy_empty_craftitem.png",
	})

	local function on_activate(self)
		-- attach to the nearest villager.
		local all_objects = minetest.get_objects_inside_radius(self.object:getpos(), 0.1)
		for _, obj in ipairs(all_objects) do
			local luaentity = obj:get_luaentity()

			if smart_villages.is_villager(luaentity.name) then
				self.object:set_attach(obj, "Arm_R", {x = 0.065, y = 0.50, z = -0.15}, {x = -45, y = 0, z = 0})
				self.object:set_properties{textures={"smart_villages:dummy_empty_craftitem"}}
				return
			end
		end
	end

	local function on_step(self)
		local all_objects = minetest.get_objects_inside_radius(self.object:getpos(), 0.1)
		for _, obj in ipairs(all_objects) do
			local luaentity = obj:get_luaentity()

			if smart_villages.is_villager(luaentity.name) then
				local stack = luaentity:get_wield_item_stack()

				if stack:get_name() ~= self.itemname then
					if stack:is_empty() then
						self.itemname = ""
						self.object:set_properties{textures={"smart_villages:dummy_empty_craftitem"}}
					else
						self.itemname = stack:get_name()
						self.object:set_properties{textures={self.itemname}}
					end
				end
				return
			end
		end
		-- if cannot find villager, delete empty item.
		self.object:remove()
		return
	end

	minetest.register_entity("smart_villages:dummy_item", {
		hp_max		    = 1,
		visual		    = "wielditem",
		visual_size	  = {x = 0.025, y = 0.025},
		collisionbox	= {0, 0, 0, 0, 0, 0},
		physical	    = false,
		textures	    = {"air"},
		on_activate	  = on_activate,
		on_step       = on_step,
		itemname      = "",
	})
end

---------------------------------------------------------------------

-- smart_villages.register_job registers a definition of a new job.
function smart_villages.register_job(job_name, def, recipe)
	smart_villages.registered_jobs[job_name] = def
	minetest.register_tool(job_name, {
		stack_max       = 1,
		description     = def.description,
		inventory_image = def.inventory_image,
	})
	if recipe ~= nil then
	    minetest.register_craft({
		    output = job_name,
		    recipe = recipe
		})
	end
end

-- smart_villages.register_egg registers a definition of a new egg.
function smart_villages.register_egg(egg_name, def)
	smart_villages.registered_eggs[egg_name] = def

	minetest.register_tool(egg_name, {
		description     = def.description,
		inventory_image = def.inventory_image,
		stack_max       = 1,

		on_use = function(itemstack, user, pointed_thing)
			if pointed_thing.above ~= nil and def.product_name ~= nil then
				-- set villager's direction.
				local new_villager = minetest.add_entity(pointed_thing.above, def.product_name)
				new_villager:get_luaentity():set_yaw_by_direction(
					vector.subtract(user:getpos(), new_villager:getpos())
				)
				new_villager:get_luaentity().owner_name = user:get_player_name()
				new_villager:get_luaentity():update_infotext()

				itemstack:take_item()
				return itemstack
			end
			return nil
		end,
	})
end

-- smart_villages.register_villager registers a definition of a new villager.
function smart_villages.register_villager(product_name, def)
	smart_villages.registered_villagers[product_name] = def

	-- initialize manufacturing number of a new villager.
	if smart_villages.manufacturing_data[product_name] == nil then
		smart_villages.manufacturing_data[product_name] = 0
	end

	-- create_inventory creates a new inventory, and returns it.
	local function create_inventory(self)
		self.inventory_name = self.product_name .. "_" .. tostring(self.manufacturing_number)
		local inventory = minetest.create_detached_inventory(self.inventory_name, {
			on_put = function(_, listname, _, stack) --inv, listname, index, stack, player
				if listname == "job" then
					local job_name = stack:get_name()
					local job = smart_villages.registered_jobs[job_name]
					if type(job.on_start)=="function" then
						job.on_start(self)
						self.job_thread = coroutine.create(job.on_step)
					elseif type(job.jobfunc)=="function" then
						self.job_thread = coroutine.create(job.jobfunc)
					end
					self:update_infotext()
				end
			end,

			allow_put = function(_, listname, _, stack) --inv, listname, index, stack, player
				-- only jobs can put to a job inventory.
				if listname == "main" then
					return stack:get_count()
				elseif listname == "job" and smart_villages.is_job(stack:get_name()) then
					return stack:get_count()
				elseif listname == "wield_item" then
					return 0
				end
				return 0
			end,

			on_take = function(_, listname, _, stack) --inv, listname, index, stack, player
				if listname == "job" then
					local job_name = stack:get_name()
					local job = smart_villages.registered_jobs[job_name]
					self.time_counters = {}
					if job then
						if type(job.on_stop)=="function" then
							job.on_stop(self)
						elseif type(job.jobfunc)=="function" then
							self.job_thread = false
						end
					end
					self:update_infotext()
				end
			end,

			allow_take = function(_, listname, _, stack) --inv, listname, index, stack, player
				if listname == "wield_item" then
					return 0
				end
				return stack:get_count()
			end,

			on_move = function(inv, from_list, _, to_list, to_index)
				--inv, from_list, from_index, to_list, to_index, count, player
				if to_list == "job" or from_list == "job" then
					local job_name = inv:get_stack(to_list, to_index):get_name()
					local job = smart_villages.registered_jobs[job_name]

					if to_list == "job" then
						if type(job.on_start)=="function" then
							job.on_start(self)
							self.job_thread = coroutine.create(job.on_step)
						elseif type(job.jobfunc)=="function" then
							self.job_thread = coroutine.create(job.jobfunc)
						end
					elseif from_list == "job" then
						if type(job.on_stop)=="function" then
							job.on_stop(self)
						elseif type(job.jobfunc)=="function" then
							self.job_thread = false
						end
					end

					self:update_infotext()
				end
			end,

			allow_move = function(inv, from_list, from_index, to_list, _, count)
				--inv, from_list, from_index, to_list, to_index, count, player
				if to_list == "wield_item" then
					return 0
				end

				if to_list == "main" then
					return count
				elseif to_list == "job" and smart_villages.is_job(inv:get_stack(from_list, from_index):get_name()) then
					return count
				end

				return 0
			end,
		})

		inventory:set_size("main", 16)
		inventory:set_size("job",  1)
		inventory:set_size("wield_item", 1)

		return inventory
	end

	-- on_activate is a callback function that is called when the object is created or recreated.
	local function on_activate(self, staticdata)
		-- parse the staticdata, and compose a inventory.
		if staticdata == "" then
			self.product_name = product_name
			self.manufacturing_number = smart_villages.manufacturing_data[product_name]
			smart_villages.manufacturing_data[product_name] = smart_villages.manufacturing_data[product_name] + 1
			create_inventory(self)

			-- attach dummy item to new villager.
			minetest.add_entity(self.object:getpos(), "smart_villages:dummy_item")
		else
			-- if static data is not empty string, this object has beed already created.
			local data = minetest.deserialize(staticdata)

			self.product_name = data["product_name"]
			self.manufacturing_number = data["manufacturing_number"]
			self.nametag = data["nametag"]
			self.owner_name = data["owner_name"]
			self.pause = data["pause"]

			local inventory = create_inventory(self)
			for list_name, list in pairs(data["inventory"]) do
				inventory:set_list(list_name, list)
			end
		end

		self:update_infotext()

		self.object:set_nametag_attributes{
			text = self.nametag
		}

		self.object:setvelocity{x = 0, y = 0, z = 0}
		self.object:setacceleration{x = 0, y = -10, z = 0}

		local job = self:get_job()
		if job ~= nil then
			if type(job.on_start)=="function" then
				job.on_start(self)
				self.job_thread = coroutine.create(job.on_step)
			elseif type(job.jobfunc)=="function" then
				self.job_thread = coroutine.create(job.jobfunc)
			end
			if self.pause == "resting" then
				if type(job.on_pause)=="function" then
					job.on_pause(self)
				end
			end
		end
	end

	-- get_staticdata is a callback function that is called when the object is destroyed.
	local function get_staticdata(self)
		local inventory = self:get_inventory()
		local data = {
			["product_name"] = self.product_name,
			["manufacturing_number"] = self.manufacturing_number,
			["nametag"] = self.nametag,
			["owner_name"] = self.owner_name,
			["inventory"] = {},
			["pause"] = self.pause,
		}

		-- set lists.
		for list_name, list in pairs(inventory:get_lists()) do
			data["inventory"][list_name] = {}

			for i, item in ipairs(list) do
				data["inventory"][list_name][i] = item:to_string()
			end
		end

		return minetest.serialize(data)
	end

	-- on_step is a callback function that is called every delta times.
	local function on_step(self, dtime)
		--upate old pause state
		if self.pause==true then
			self.pause="resting"
		elseif self.pause == false then
			self.pause="active"
		end

		--[[ if owner didn't login, the villager does nothing.
		if not minetest.get_player_by_name(self.owner_name) then
			return
		end--]]

		-- pickup surrounding item.
		self:pickup_item()

		if self.pause ~= "active" and self.pause ~= "sleeping" then
			return
		end

		local job = self:get_job()
		if not job then return end
		if not self.job_thread and job.on_step then
			job.on_start(self)
			self.job_thread = coroutine.create(job.on_step)
		end
		if coroutine.status(self.job_thread) == "dead" then
			if job.jobfunc then
				self.job_thread = coroutine.create(job.jobfunc)
			else
				self.job_thread = coroutine.create(job.on_step)
			end
		end
		if coroutine.status(self.job_thread) == "suspended" then
			local state, err = coroutine.resume(self.job_thread, self, dtime)
			if state == false then
				error("error in job_thread " .. err)
			end
		end
	end

	-- on_rightclick is a callback function that is called when a player right-click them.
	local function on_rightclick(self, clicker)
		local wielded_stack = clicker:get_wielded_item()
		if wielded_stack:get_name() == "smart_villages:commanding_sceptre"
			and clicker:get_player_name() == self.owner_name then

			smart_villages.forms.show_inv_formspec(self, clicker:get_player_name())
		else
			smart_villages.forms.show_talking_formspec(self, clicker:get_player_name())
		end
		self:update_infotext()
	end

	-- on_punch is a callback function that is called when a player punch then.
	local function on_punch()--self, puncher, time_from_last_punch, tool_capabilities, dir
		--TODO: aggression
	end

	-- register a definition of a new villager.

	local villager_def = table.copy(smart_villages.villager)
	-- basic initial properties
	villager_def.hp_max               = def.hp_max
	villager_def.weight               = def.weight
	villager_def.mesh                 = def.mesh
	villager_def.textures             = def.textures

	villager_def.physical             = true
	villager_def.visual               = "mesh"
	villager_def.visual_size          = {x = 1, y = 1}
	villager_def.collisionbox         = {-0.25, 0, -0.25, 0.25, 1.75, 0.25}
	villager_def.is_visible           = true
	villager_def.makes_footstep_sound = true
	villager_def.infotext             = ""
	villager_def.nametag              = ""

	-- extra initial properties
	villager_def.pause                = "active"
	villager_def.state                = "job"
	villager_def.job_thread           = false
	villager_def.product_name         = ""
	villager_def.manufacturing_number = -1
	villager_def.owner_name           = ""
	villager_def.time_counters        = {}
	villager_def.destination          = vector.new(0,0,0)

	-- callback methods
	villager_def.on_activate          = on_activate
	villager_def.on_step              = on_step
	villager_def.on_rightclick        = on_rightclick
	villager_def.on_punch             = on_punch
	villager_def.get_staticdata       = get_staticdata

	-- home methods
	villager_def.get_home             = smart_villages.get_home
	villager_def.has_home             = smart_villages.is_valid_home


	minetest.register_entity(product_name, villager_def)

	-- register villager egg.
	smart_villages.register_egg(product_name .. "_egg", {
		description     = product_name .. " egg",
		inventory_image = def.egg_image,
		product_name    = product_name,
	})
end
function smart_villages.random_texture(...)
	math.randomseed(os.time())
	local args = { ... }
	return args[math.random(1, #args)]
	-- body
end