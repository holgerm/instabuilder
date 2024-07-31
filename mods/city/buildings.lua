

city.buildings = {}
city.buildings_by_width = {}

minetest.register_node("city:space", {
    drawtype = "airlike",
    paramtype = "light",
    pointable = false,
    walkable = false,
    sunlight_propagates = true,
})

--city.build builds a random kind building at position pos
--if builder is provided, acts like place_node.
function city.build(kind, pos, builder) 
    if minetest.get_item_group(minetest.get_node({x=pos.x, y=pos.y-1, z=pos.z}).name, "ground") == 0 then
        return false
    end
    local current = minetest.get_node(pos)
    if current.name ~= "air" and minetest.get_item_group(current.name, "replaceable") == 0 then
        return false
    end

    local road = logistics.node_near(pos, builder, "street")
    if not road then
        return false
    end

    local building = city.buildings[kind][math.random(1, #city.buildings[kind])] 
    local dir = vector.subtract(pos, road)
    --local param2 = minetest.dir_to_facedir(dir)

    --If the building has a width greater than one, we need to check
    --that the nodes to the right (taking into account param2) 
    --are empty so that this building will fit. If it doesn't fit,  
    --we need to select a different building.
    local width = minetest.get_item_group(building, "width")
    while width and width > 1 do
        local left = vector.add(pos, {x=-dir.z, y=dir.y, z=dir.x})
        local right = vector.subtract(pos, {x=-dir.z, y=dir.y, z=dir.x})
        local node_right = minetest.get_node(right)
        local node_left = minetest.get_node(left)
        local node_under_right = minetest.get_node(vector.subtract(right, {x=0, y=1, z=0}))
        local node_under_left = minetest.get_node(vector.subtract(left, {x=0, y=1, z=0}))

        if node_right.name ~= "air" or minetest.get_item_group(node_under_right.name, "ground") == 0 then
            if node_left.name == "air" and minetest.get_item_group(node_under_left.name, "ground") > 0 then 
                pos = left --move left
                break
            else
                -- decrease the width of the building that we can place.
                building = city.buildings_by_width[kind][width-1][math.random(1, #city.buildings_by_width[kind][width-1])]
                width = minetest.get_item_group(building, "width")
            end
        else
            break
        end
    end

    return logistics.place(building.."_off", pos, builder)
end

--[[
    city.register_building registers a new building 
    {
        mesh = "meshname.obj",
        cost = 1,                -- construction cost.
        width = 1,               -- width of the building in blocks.
        kind = "house",          -- house/office/factory/store/etc.
        self_sufficient = false, -- if true, the building does not require energy.
    }
]]--
function city.register_building(name, def)
    local kind = def.kind or ""
    local width = def.width or 1
    def.height = def.height or 1

    if not city.buildings[kind] then
        city.buildings[kind] = {}
    end
    if not city.buildings_by_width[kind] then
        city.buildings_by_width[kind] = {}
    end
    if not city.buildings_by_width[kind][width] then
        city.buildings_by_width[kind][width] = {}
    end
    table.insert(city.buildings[kind], name)
    table.insert(city.buildings_by_width[kind][width], name)

    if not def.tiles then
        def.tiles = city.load_material("city", def.mesh..".mtl")
    end

    local node_def = {
        mesh = def.mesh..".obj",
        drawtype = "mesh",
        paramtype = "light",
        paramtype2 = "colorfacedir",
        logistics = {
            network = "city",
        },
        connects_to = "group:street",
        resources = function(_pos)
            return {
                population = 1,
            }
        end,
        groups = {
            flammable = 1,
            width = def.width,
            height = def.height,
        },
        node_placement_prediction = "",
        tiles = def.tiles,
        kind = kind,
        level = def.level,
    }

    node_def.selection_box = {
        type = "fixed",
        fixed = {
            {-0.5, -0.5, -0.5, -0.5+1*width, -0.5+1*def.height, 0.5},
        },
    }
    node_def.collision_box = {
        type = "fixed",
        fixed = {
            {-0.5, -0.5, -0.5, -0.5+1*width, -0.5+1*def.height, 0.5},
        },
    }

    node_def.on_construct = function(pos)
        if width > 1 then
            local dir = minetest.facedir_to_dir(minetest.get_node(pos).param2)
            minetest.set_node(vector.subtract(pos, {x=-dir.z, y=dir.y, z=dir.x}), {name = "city:space"})
        end
    end

    node_def.on_destruct = function(pos)
        if width > 1 then
            local dir = minetest.facedir_to_dir(minetest.get_node(pos).param2)
            minetest.set_node(vector.subtract(pos, {x=-dir.z, y=dir.y, z=dir.x}), {name = "air"})
        end
    end

    local decayed_node_def = table.copy(node_def)
    if not def.tiles then
        --replace lit windows with dark windows
        for i,v in ipairs(decayed_node_def.tiles) do
            if v.color.window then
                decayed_node_def.tiles[i].color = 0xFF1D2222
            end
        end
    end
    local suffix = "_off"
    node_def.groups["consumer"] = 1

    minetest.register_node(name, node_def)
    minetest.register_node(name..suffix, decayed_node_def)
end


city.register_building("city:green_1", {
    height = 0.6,
    mesh = "green_1",
    tiles = {"green_1.png"},
    drawtype = "mesh",
    use_texture_alpha = true,
    backface_culling = false,
    kind = "green",
    level = 1,
	selection_box = {
		type = 'fixed',
		fixed = {-.5, -.5, -.3, .5, .15, .4},
		},
	collision_box = {
		type = 'fixed',
		fixed = {-.5, -.5, -.3, .5, .15, .4},
		},
})
city.register_building("city:green_2", {
    height = 0.6,
    mesh = "green_2",
    tiles = {"green_2.png"},
    drawtype = "mesh",
    use_texture_alpha = true,
    backface_culling = false,
    kind = "green",
    level = 2,
	selection_box = {
		type = 'fixed',
		fixed = {-.5, -.5, -.3, .5, .15, .4},
		},
	collision_box = {
		type = 'fixed',
		fixed = {-.5, -.5, -.3, .5, .15, .4},
		},
})
city.register_building("city:green_3", {
    height = 0.6,
    mesh = "green_3",
    tiles = {"green_3.png"},
    drawtype = "mesh",
    use_texture_alpha = true,
    backface_culling = false,
    kind = "green",
    level = 3,
	selection_box = {
		type = 'fixed',
		fixed = {-.5, -.5, -.3, .5, .15, .4},
		},
	collision_box = {
		type = 'fixed',
		fixed = {-.5, -.5, -.3, .5, .15, .4},
		},
})
city.register_building("city:residential_concrete_1", {
    height = 1 ,
    mesh = "residential_concrete_1",
    tiles = {"residential_concrete_1.png"},
    drawtype = "mesh",
    use_texture_alpha = true,
    backface_culling = false,
    kind = "residential_concrete",
    level = 1
})
city.register_building("city:residential_concrete_2", {
    height = 1 ,
    mesh = "residential_concrete_2",
    tiles = {"residential_concrete_2.png"},
    drawtype = "mesh",
    use_texture_alpha = true,
    backface_culling = false,
    kind = "residential_concrete",
    level = 2
})
city.register_building("city:residential_concrete_3", {
    height = 1 ,
    mesh = "residential_concrete_3",
    tiles = {"residential_concrete_3.png"},
    drawtype = "mesh",
    use_texture_alpha = true,
    backface_culling = false,
    kind = "residential_concrete",
    level = 3
})
city.register_building("city:residential_concrete_4", {
    height = 1 ,
    mesh = "residential_concrete_4",
    tiles = {"residential_concrete_4.png"},
    drawtype = "mesh",
    use_texture_alpha = true,
    backface_culling = false,
    kind = "residential_concrete",
    level = 4
})

city.register_building("city:residential_brick_1", {
    height = 1 ,
    mesh = "residential_brick_1",
    tiles = {"residential_brick_1.png"},
    drawtype = "mesh",
    use_texture_alpha = true,
    backface_culling = false,
    kind = "residential_brick",
    level = 1
})
city.register_building("city:residential_brick_2", {
    height = 1 ,
    mesh = "residential_brick_2",
    tiles = {"residential_brick_2.png"},
    drawtype = "mesh",
    use_texture_alpha = true,
    backface_culling = false,
    kind = "residential_brick",
    level = 2
})
city.register_building("city:residential_brick_3", {
    height = 1 ,
    mesh = "residential_brick_3",
    tiles = {"residential_brick_3.png"},
    drawtype = "mesh",
    use_texture_alpha = true,
    backface_culling = false,
    kind = "residential_brick",
    level = 3
})
city.register_building("city:residential_brick_4", {
    height = 1 ,
    mesh = "residential_brick_4",
    tiles = {"residential_brick_4.png"},
    drawtype = "mesh",
    use_texture_alpha = true,
    backface_culling = false,
    kind = "residential_brick",
    level = 4
})

city.register_building("city:residential_wood_1", {
    height = 0.6,
    tiles = {"residential_wood_1.png"},
    drawtype = "mesh",
    use_texture_alpha = true,
    backface_culling = false,
    mesh = "residential_wood_1",
    kind = "residential_wood",
    level = 1
})
city.register_building("city:residential_wood_2", {
    height = 1,
    tiles = {"residential_wood_2.png"},
    drawtype = "mesh",
    use_texture_alpha = true,
    backface_culling = false,
    mesh = "residential_wood_2",
    kind = "residential_wood",
    level = 2
})