

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
        paramtype2 = "colorfacedir",
        logistics = {
            network = "city",
        },
        connects_to = "group:street",
        resources = function(pos)
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
        tiles = city.load_material("city", def.mesh..".mtl"),
        kind = kind,
        level = def.level,
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

    --replace lit windows with dark windows
    for i,v in ipairs(decayed_node_def.tiles) do
        if v.color.window then
            decayed_node_def.tiles[i].color = 0xFF1D2222
        end
    end

    local suffix = "_off"
    node_def.groups["consumer"] = 1

    minetest.register_node(name, node_def)
    minetest.register_node(name..suffix, decayed_node_def)
end

city.register_building("city:house_long_a", {
    mesh = "city_house_long_a",
    width = 2,
    height = 0.75,
    self_sufficient = true, 
    kind = "house",
})
city.register_building("city:house_long_b", {
    mesh = "city_house_long_b",
    width = 2,
    height = 0.75,
    self_sufficient = true, 
    kind = "house",
})
city.register_building("city:house_long_c", {
    mesh = "city_house_long_c",
    width = 2,
    height = 0.75,
    kind = "house",
})
city.register_building("city:house_long_d", {
    mesh = "city_house_long_d",
    width = 2,
    height = 0.75,
    kind = "house",
})
city.register_building("city:house_long_e", {
    mesh = "city_house_long_e",
    width = 2,
    height = 0.75,
    kind = "house",
})

--TODO maybe load this information from the file-structure?

city.register_building("city:house_a", {height = 0.75, mesh = "city_house_a", kind = "house"})
city.register_building("city:house_b", {height = 0.6, mesh = "city_house_b", kind = "house"})
city.register_building("city:house_c", {height = 0.8, mesh = "city_house_c", kind = "house"})
city.register_building("city:house_d", {height = 0.5, mesh = "city_house_d", kind = "house"})
city.register_building("city:house_e", {height = 0.5, mesh = "city_house_e", kind = "house"})
city.register_building("city:house_f", {height = 0.7, mesh = "city_house_f", kind = "house", self_sufficient = true})
city.register_building("city:house_g", {height = 0.7, mesh = "city_house_g", kind = "house"})
city.register_building("city:house_h", {height = 0.6, mesh = "city_house_h", kind = "house", self_sufficient = true})
city.register_building("city:house_i", {height = 0.65, mesh = "city_house_i", kind = "house"})
city.register_building("city:house_j", {height = 0.7, mesh = "city_house_j", kind = "house"})
city.register_building("city:house_k", {height = 0.7, mesh = "city_house_k", kind = "house"})
city.register_building("city:house_l", {height = 0.7, mesh = "city_house_l", kind = "house"})
city.register_building("city:house_m", {height = 0.7, mesh = "city_house_m", kind = "house"})
city.register_building("city:house_n", {height = 0.6, mesh = "city_house_n", kind = "house"})
city.register_building("city:house_o", {height = 0.8, mesh = "city_house_o", kind = "house"})
city.register_building("city:house_p", {height = 0.62, mesh = "city_house_p", kind = "house"})

city.register_building("city:skyscraper_a", {height = 2.31, mesh = "city_skyscraper_a", kind = "skyscraper"})
city.register_building("city:skyscraper_b", {height = 3.6, mesh = "city_skyscraper_b", kind = "skyscraper"})
city.register_building("city:skyscraper_c", {height = 2.9, mesh = "city_skyscraper_c", kind = "skyscraper"})
city.register_building("city:skyscraper_d", {height = 4.23, mesh = "city_skyscraper_d", kind = "skyscraper"})
city.register_building("city:skyscraper_e", {height = 2, mesh = "city_skyscraper_e", kind = "skyscraper"})
city.register_building("city:skyscraper_f", {height = 3.28, mesh = "city_skyscraper_f", kind = "skyscraper"})

city.register_building("city:shop_a", {height = 0.75, mesh = "city_shop_a", kind = "shop"})
city.register_building("city:shop_b", {height = 0.75, mesh = "city_shop_b", kind = "shop"})
city.register_building("city:shop_c", {height = 0.75, mesh = "city_shop_c", kind = "shop"})
city.register_building("city:shop_d", {height = 0.75, mesh = "city_shop_d", kind = "shop"})
city.register_building("city:shop_e", {height = 0.75, mesh = "city_shop_e", kind = "shop", width = 2})
city.register_building("city:shop_f", {height = 0.75, mesh = "city_shop_e", kind = "shop", width = 2})


city.register_building("city:mall_a", {height = 1, mesh = "city_mall_a", kind = "mall", width = 2})
city.register_building("city:mall_b", {height = 1, mesh = "city_mall_b", kind = "mall"})
city.register_building("city:mall_c", {height = 1, mesh = "city_mall_c", kind = "mall"})
city.register_building("city:mall_d", {height = 1, mesh = "city_mall_d", kind = "mall"})
city.register_building("city:mall_e", {height = 1, mesh = "city_mall_e", kind = "mall"})
city.register_building("city:mall_f", {height = 1, mesh = "city_mall_f", kind = "mall", width = 2})

city.register_building("city:green_1", {
    height = 0.6,
    mesh = "green_1",
    kind = "green",
    level = 1
})
city.register_building("city:green_2", {
    height = 0.6,
    mesh = "green_2",
    kind = "green",
    level = 2
})
city.register_building("city:residential_concrete_1", {
    height = 0.6,
    mesh = "insta_residential_concrete_1",
    kind = "residential_concrete",
    level = 1
})
city.register_building("city:residential_concrete_2", {
    height = 0.8,
    mesh = "insta_residential_concrete_2",
    kind = "residential_concrete",
    level = 2
})
city.register_building("city:residential_concrete_3", {
    height = 1,
    mesh = "insta_residential_concrete_3",
    kind = "residential_concrete",
    level = 3
})
city.register_building("city:residential_concrete_4", {
    height = 2,
    mesh = "insta_residential_concrete_4",
    kind = "residential_concrete",
    level = 4
})

city.register_building("city:residential_brick_1", {
    height = 0.6,
    mesh = "insta_residential_brick_1",
    kind = "residential_brick",
    level = 1
})
city.register_building("city:residential_brick_2", {
    height = 0.8,
    mesh = "insta_residential_brick_2",
    kind = "residential_brick",
    level = 2
})
city.register_building("city:residential_brick_3", {
    height = 1,
    mesh = "insta_residential_brick_3",
    kind = "residential_brick",
    level = 3
})
city.register_building("city:residential_brick_4", {
    height = 2,
    mesh = "insta_residential_brick_4",
    kind = "residential_brick",
    level = 4
})

city.register_building("city:residential_wood_1", {
    height = 0.6,
    mesh = "insta_residential_wood_1",
    kind = "residential_wood",
    level = 1
})
city.register_building("city:residential_wood_2", {
    height = 0.8,
    mesh = "insta_residential_wood_2",
    kind = "residential_wood",
    level = 2
})
-- city.register_building("city:residential_wood_3", {
--     height = 1,
--     mesh = "city_residential_wood_3",
--     kind = "residential_wood",
--     level = 3
-- })
-- city.register_building("city:residential_wood_4", {
--     height = 2,
--     mesh = "city_residential_wood_4",
--     kind = "residential_wood",
--     level = 4
-- })
