

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
    if minetest.get_node(pos).name ~= "air" then
        return false
    end

    local building = city.buildings[kind][math.random(1, #city.buildings[kind])]

    if builder then
        if minetest.is_protected(pos, builder:get_player_name()) then
            minetest.record_protection_violation(pos, builder:get_player_name())
            return false
        end
    end

    local param2 = 0
    local road = city.get_road_near(pos, builder:get_pos())
    local dir = vector.subtract(pos, road)
    if road then
        param2 = minetest.dir_to_facedir(dir)
    end

    --If the building has a width greater than one, we need to check
    --that the nodes to the right (taking into account param2) 
    --are empty so that this building will fit. If it doesn't fit,  
    --we need to select a different building.
    local width = minetest.get_item_group(building, "width")
    while width and width > 1 do
        local left = vector.add(pos, {x=-dir.z, y=dir.y, z=dir.x})
        local node_right = minetest.get_node(vector.subtract(pos, {x=-dir.z, y=dir.y, z=dir.x}))
        local node_left = minetest.get_node(left)

        if node_right.name ~= "air" then
            if node_left.name == "air" then 
                pos = left --move left
                break
            else
                --change the building to a random width 1 building.
                building = city.buildings_by_width[kind][width-1][math.random(1, #city.buildings_by_width[kind][width-1])]
                width = minetest.get_item_group(building, "width")
            end
        else
            break
        end
    end

    minetest.set_node(pos, {name = building, param2 = param2})
    return true
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

    local node_def = {
        mesh = def.mesh..".obj",
        drawtype = "mesh",
        paramtype = "light",
        paramtype2 = "facedir",
        groups = {
            flammable = 1,
            width = def.width,
            height = def.height,
        },
        node_placement_prediction = "",
        tiles = city.load_material(def.mesh..".mtl")
    }

    def.height = def.height or 1

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

    if not def.self_sufficient then
        local decayed_node_def = table.copy(node_def)

        --replace lit windows with dark windows
        for i,v in ipairs(decayed_node_def.tiles) do
            if v.color.window then
                decayed_node_def.tiles[i].color = 0xFF1D2222
            end
        end

        node_def.on_timer = function(pos, elapsed)
            minetest.set_node(pos, {name = name.."_decayed", param2 = minetest.get_node(pos).param2})
        end

        minetest.register_node(name.."_decayed", decayed_node_def)
    end

    --setup a node timer that will decay the building
    --after a random amount of time.
    node_def.on_construct = function(pos, placer, itemstack, pointed_thing)
        minetest.get_node_timer(pos):start(math.random(1, 60*5))

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

    minetest.register_node(name, node_def)
end

city.register_building("city:house_long_a", {
    mesh = "city_house_long_a",
    width = 2,
    height = 0.75,
    self_sufficient = true, 
    kind = "house",
})
city.register_building("city:house_a", {height = 0.7, mesh = "city_house_a", kind = "house"})
city.register_building("city:house_b", {height = 0.6, mesh = "city_house_b", kind = "house"})
city.register_building("city:house_c", {height = 0.8, mesh = "city_house_c", kind = "house"})
city.register_building("city:skyscraper_a", {height = 2.9, mesh = "city_skyscraper_a", kind = "skyscraper"})