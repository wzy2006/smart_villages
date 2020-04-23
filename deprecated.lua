local func = smart_villages.func
smart_villages.hasbasic_materials = false
for key, value in ipairs(minetest.get_modnames()) do
	if(value=="basic_materials") then
		smart_villages.hasbasic_materials = true
	end
end

function smart_villages.func.villager_state_machine_job(job_name,job_description,actions, sprop)
	minetest.log("warning","old util jobdef should be replaced by jobfunc registration")
	minetest.log("warning","old util jobdef: "..job_name)

	--special properties
	if sprop.night_active ~= true then
		sprop.night_active = false
	end
	if sprop.search_idle ~= true then
		sprop.search_idle = false
	end
	if sprop.searching_range == nil or sprop.searching_range == {} then
		sprop.searching_range = {x = 10, y = 3, z = 10}
	end

	--controlling state
	local function walk_randomly(self)
		local CHANGE_DIRECTION_TIME_INTERVAL = 50
		if self:timer_exceeded(1,20) then
			self:count_timer(2)
			local myJob = self:get_job()
			if myJob.states.WALK_HOME and myJob.states.WALK_HOME.self_condition(self) then
				myJob.states.WALK_HOME.to_state(self)
				self.job_state=myJob.states.WALK_HOME
				return
			end
			for _,search_state in pairs(myJob.states) do
				local self_cond = false
				if search_state.self_condition then
					if search_state.self_condition(self) then
						self_cond=true
					end
				elseif search_state.search_condition ~= nil or search_state.target_getter ~= nil then
					self_cond=true
				end
				if search_state.search_condition ~= nil and self_cond then
					local target = smart_villages.func.search_surrounding(
						self.object:getpos(), search_state.search_condition, sprop.searching_range)
					if target ~= nil then
						local destination = func.find_adjacent_clear(target)
						if destination==false then
							print("failure: no adjacent walkable found")
							destination = target
						end
						local val_pos = smart_villages.func.validate_pos(self.object:getpos())
						if smart_villages.debug_logging then
							minetest.log("info","looking for a path from " .. minetest.pos_to_string(val_pos) ..
								" to " .. minetest.pos_to_string(destination))
						end
						if smart_villages.pathfinder.get_reachable(val_pos,destination,self) then
							--print("path found to: " .. minetest.pos_to_string(destination))
							if search_state.to_state then
								search_state.to_state(self, destination, target)
							end
							self.job_state=search_state
							return
						end
					end
				elseif search_state.target_getter ~= nil and self_cond then
					local target = search_state.target_getter(self, sprop.searching_range)
					if target ~= nil then
						local distance = vector.subtract(target, self.object:getpos())
						if distance.x<=sprop.searching_range.x
								and distance.y<=sprop.searching_range.y
								and distance.z<=sprop.searching_range.z then

							local destination = smart_villages.func.validate_pos(target)
							local val_pos = smart_villages.func.validate_pos(self.object:getpos())
							if smart_villages.debug_logging then
								minetest.log("info","looking for a path from " .. minetest.pos_to_string(val_pos) ..
									" to " .. minetest.pos_to_string(destination))
							end
							if smart_villages.pathfinder.get_reachable(val_pos,destination,self) then
								--print("path found to: " .. minetest.pos_to_string(destination))
								if search_state.to_state then
									search_state.to_state(self, destination, target)
								end
								self.job_state=search_state
								return
							end
						end
					end
				elseif self_cond then
					if search_state.to_state then
						search_state.to_state(self)
					end
					self.job_state=search_state
					return
				end
			end
		elseif self:timer_exceeded(2,CHANGE_DIRECTION_TIME_INTERVAL) then
			self:count_timer(1)
			self:change_direction_randomly()
			return
		else
			self:count_timer(1)
			self:count_timer(2)

			self:handle_obstacles()
			return
		end
	end

	local function to_walk_randomly(self)
		self:set_timer(1,20)
		self:set_timer(2,0)
		self:set_animation(smart_villages.animation_frames.WALK)
	end

	local function s_search_idle(self)
		if self:timer_exceeded(1,20) then
			self:set_timer(1,0)
			local myJob = self:get_job()
			for _,search_state in pairs(myJob.states) do
				local self_cond = false
				if search_state.self_condition then
					if search_state.self_condition(self) then
						self_cond=true
					end
				elseif search_state.search_condition ~= nil then
					self_cond=true
				end
				if search_state.search_condition ~= nil and self_cond then
					local target = smart_villages.func.search_surrounding(self.object:getpos(),
						search_state.search_condition, sprop.searching_range)
					if target ~= nil then
						local destination = func.find_adjacent_clear(target)
						if not(destination) then
							destination = target
						end
						local val_pos = smart_villages.func.validate_pos(self.object:getpos())
						if smart_villages.pathfinder.get_reachable(val_pos,destination,self) then
							if search_state.to_state then
								search_state.to_state(self, destination, target)
							end
							self.job_state=search_state
							return
						end
					end
				elseif self_cond then
					if search_state.to_state then
						search_state.to_state(self)
					end
					self.job_state=search_state
					return
				end
			end
		else
			self:count_timer(1)
			return
		end
	end

	local function to_search_idle(self)
		self:set_timer(1,0)
		self:set_timer(2,0)
		self.object:setvelocity{x = 0, y = 0, z = 0}
		self:set_animation(smart_villages.animation_frames.STAND)
	end

	--sleeping states
	local function s_sleep(self)
		if not(minetest.get_timeofday() < 0.2 or minetest.get_timeofday() > 0.76) then
			local pos=self.object:getpos()
			self.object:setpos({x=pos.x,y=pos.y+0.5,z=pos.z})
			minetest.log("action","a villager gets up")
			self:set_animation(smart_villages.animation_frames.STAND)
			self.pause="active"
			self:update_infotext()
			return true
		end
		return false
	end
	local function to_sleep(self)
		minetest.log("action","a villager is laying down")
		self.object:setvelocity{x = 0, y = 0, z = 0}
		local bed_pos=self:get_home():get_bed()
		local bed_top = smart_villages.func.find_adjacent_pos(bed_pos,
			function(p) return string.find(minetest.get_node(p).name,"_top") end)
		local bed_bottom = smart_villages.func.find_adjacent_pos(bed_pos,
			function(p) return string.find(minetest.get_node(p).name,"_bottom") end)
		if bed_top and bed_bottom then
			self:set_yaw_by_direction(vector.subtract(bed_bottom, bed_top))
		else
			minetest.log("info","no bed found")
		end
		self:set_animation(smart_villages.animation_frames.LAY)
		self.object:setpos(vector.add(bed_pos,{x=0,y=1.5,z=0}))
		self.pause="sleeping"
		self:update_infotext()
	end
	local function to_walk_home(self)
		if smart_villages.debug_logging then
			minetest.log("action","a villager is going home")
		end
		self.destination=self:get_home():get_bed()
		if not self.destination then
			minetest.log("warning","villager couldn't find his bed")
			return
		end
		if smart_villages.debug_logging then
			minetest.log("info","his bed is at:" .. self.destination.x .. ",".. self.destination.y .. ",".. self.destination.z)
		end
		self:set_state("goto_dest")
	end
	--list all states
	local newStates={}
	if sprop.search_idle then
		newStates.SEARCH = {number=0,
				func=s_search_idle,
				to_state=to_search_idle}
	else
		newStates.SEARCH = {number=0,
				func=walk_randomly,
				to_state=to_walk_randomly}
	end
	local i = 0
	if not sprop.night_active then
		newStates.GO_OUT	= {number=1,
					func=function() return true end,
					to_state=function(self)
						if smart_villages.debug_logging then
							minetest.log("action","a villager stood up and is going outside")
						end
						self.destination=self:get_home():get_door()
						self:set_state("goto_dest")
					end,
					next_state=newStates.SEARCH}
		newStates.SLEEP         = {number=2,
					func=s_sleep,
					to_state=to_sleep,
					next_state=newStates.GO_OUT}
		newStates.WALK_HOME	= {number=3,
					func=function() return true end,
					self_condition = function (self)
						if self:has_home() then
							if not self:get_home():get_bed()  then
								return false
							end
						else
							return false
						end
						if minetest.get_timeofday() < 0.2 or minetest.get_timeofday() > 0.76 then
							return true
						else
							return false
						end
					end,
					to_state=to_walk_home,
					next_state=newStates.SLEEP}
		i = 3
	end
        for k, v in pairs(actions) do
		i = i + 1
		newStates[k] = v
		newStates[k].number = i
	end
	--job definitions
	local function on_start(self)
		self.object:setacceleration{x = 0, y = -10, z = 0}
		self.object:setvelocity{x = 0, y = 0, z = 0}
		self.job_state = self:get_job().states.SEARCH
		self.time_counters = {}
		self.path = nil
		self:get_job().states.SEARCH.to_state(self)
	end
	local function on_stop(self)
		self.object:setvelocity{x = 0, y = 0, z = 0}
		self.job_state = nil
		self.time_counters = nil
		self.path = nil
		self:set_animation(smart_villages.animation_frames.STAND)
	end
	local function on_resume(self)
		local job = self:get_job()
		self.object:setacceleration{x = 0, y = -10, z = 0}
		self.object:setvelocity{x = 0, y = 0, z = 0}
		self.job_state = job.states.SEARCH
		job.states.SEARCH.to_state(self)
	end
	local function on_pause(self)
		self.object:setvelocity{x = 0, y = 0, z = 0}
		self.job_state = nil
		self:set_animation(smart_villages.animation_frames.STAND)
	end
	local function on_step(self)
		if self.job_state.next_state ~= nil then
			if self.job_state.func==nil or self.job_state.func(self) then
				self.job_state=self.job_state.next_state
				if self.job_state.to_state ~= nil then
					self.job_state.to_state(self)
				end
			end
		else
			if self.job_state.func==nil or self.job_state.func(self) then
				smart_villages.func.get_back_to_searching(self)
			end
		end
	end
	smart_villages.register_job("smart_villages:"..job_name, {
		description      = "smart_villages job : "..job_description,
		inventory_image  = "default_paper.png^memorandum_letters.png",
		on_start         = on_start,
		on_stop          = on_stop,
		on_resume        = on_resume,
		on_pause         = on_pause,
		on_step          = on_step,
		states           = newStates
	})
end

function smart_villages.func.get_back_to_searching(self)
	local myJob = self:get_job()
	if myJob and myJob.states and myJob.states.SEARCH then
		self.job_state = myJob.states.SEARCH
		if myJob.states.SEARCH.to_state then
			myJob.states.SEARCH.to_state(self)
		end
	end
end