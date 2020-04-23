function smart_villages.func.validate_pos(pos)
  local resultp = vector.round(pos)
  local node = minetest.get_node(resultp)
  if minetest.registered_nodes[node.name].walkable then
    resultp = vector.subtract(pos, resultp)
    resultp = vector.round(resultp)
    resultp = vector.add(pos, resultp)
    return vector.round(resultp)
  else
    return resultp
  end
end

function smart_villages.func.clear_pos(pos)
	local node=minetest.get_node(pos)
	local above_node=minetest.get_node({x=pos.x,y=pos.y+1,z=pos.z})
	return not(smart_villages.pathfinder.walkable(node) or smart_villages.pathfinder.walkable(above_node))
end

function smart_villages.func.walkable_pos(pos)
	local node=minetest.get_node(pos)
	return smart_villages.pathfinder.walkable(node)
end

function smart_villages.func.find_adjacent_clear(pos)
	local found = smart_villages.func.find_adjacent_pos(pos,smart_villages.func.clear_pos)
	if found~=false then
		return found
	end
	found = vector.add(pos,{x=0,y=-2,z=0})
	if smart_villages.func.clear_pos(found) then
		return found
	end
	return false

end

local find_adjacent_clear = smart_villages.func.find_adjacent_clear

function smart_villages.func.search_surrounding(pos, pred, searching_range)
	pos = vector.round(pos)
	local max_xz = math.max(searching_range.x, searching_range.z)
	local mod_y
	if searching_range.h == nil then
		if searching_range.y > 3 then
			mod_y = 2
		else
			mod_y = 0
		end
	else
		mod_y = searching_range.h
	end

	for j = mod_y - searching_range.y, searching_range.y do
		local p = vector.add({x = 0, y = j, z = 0}, pos)
		if pred(p) and find_adjacent_clear(p)~=false then
			return p
		end
	end

	for i = 0, max_xz do
		for j = mod_y - searching_range.y, searching_range.y do
			for k = -i, i do
				if searching_range.x >= k and searching_range.z >= i then
					local p = vector.add({x = k, y = j, z = i}, pos)
					if pred(p) and find_adjacent_clear(p)~=false then
						return p
					end

					p = vector.add({x = k, y = j, z = -i}, pos)
					if pred(p) and find_adjacent_clear(p)~=false then
						return p
					end
				end

				if searching_range.z >= i and searching_range.z >= k then
					if i ~= k then
						local p = vector.add({x = i, y = j, z = k}, pos)
						if pred(p) and find_adjacent_clear(p)~=false then
							return p
						end
					end

					if -i ~= k then
						local p = vector.add({x = -i, y = j, z = k}, pos)
						if pred(p) and find_adjacent_clear(p)~=false then
							return p
						end
					end
				end
			end
		end
	end
	return nil
end

function smart_villages.func.find_adjacent_pos(pos,pred)
	local dest_pos
	if pred(pos) then
		return pos
	end
	dest_pos = vector.add(pos,{x=0,y=1,z=0})
	if pred(dest_pos) then
		return dest_pos
	end
	dest_pos = vector.add(pos,{x=0,y=-1,z=0})
		if pred(dest_pos) then
		return dest_pos
	end
	dest_pos = vector.add(pos,{x=1,y=0,z=0})
	if pred(dest_pos) then
		return dest_pos
	end
	dest_pos = vector.add(pos,{x=-1,y=0,z=0})
	if pred(dest_pos) then
		return dest_pos
	end
	dest_pos = vector.add(pos,{x=0,y=0,z=1})
	if pred(dest_pos) then
		return dest_pos
	end
	dest_pos = vector.add(pos,{x=0,y=0,z=-1})
	if pred(dest_pos) then
		return dest_pos
	end
	return false
end