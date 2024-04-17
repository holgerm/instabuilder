local builda = {
    changed = true,
}

_G.builda = builda

dofile(minetest.get_modpath("insta").."/countdown.lua")
dofile(minetest.get_modpath("insta").."/status.lua")

--builda implements the gameplay logic of Builda City.
--In this gamemode, players have energy and are required to build
--cities so that they can collect coins and profit from the global
--energy supply infrastructure.

local S = minetest.get_translator("builda")

minetest.hud_replace_builtin("health", nil)

minetest.item_drop = function() end

minetest.register_item(":", {
    type = "none",
    range = 10,
})

--We need to attach the Energy and Humans HUD counts.
--Humans is top left, Energy is top right.
minetest.register_on_joinplayer(function(player)

    --Give the player their starting coins.
    if player:get_meta():contains("costs") == false then
        _G.builda.AddPlayerCosts(player, 0)
    end

    local list = {
        "builda:road 1",
        "builda:green 1",
        "builda:residential_concrete 1",
        "builda:residential_brick 1",
        "builda:residential_wood 1",
        "builda:destroyer 1",
    }

    --Initialise the buildbar (hotbar).
    player:get_inventory():set_list("main", list)
    player:hud_set_hotbar_itemcount(#list)

    --Remove default HUD elements.
    player:hud_set_flags({healthbar=false, breathbar=false, wielditem=false})
    player:hud_set_hotbar_image("builda_empty.png")

    _G.builda.Init_status_hud(player)
    _G.builda.Reset_state()

    --Setup camera, the player is inside an energy distrubution craft
    --and is able to fly through single-node spaces.
    player:set_properties({
        eye_height = 0.2,
        collisionbox = {-0.3, 0.0, -0.3, 0.3, 0.3, 0.3},
        visual = "mesh",
        mesh = "builda_craft_default.obj",
        textures = {"builda_craft_default.png", "builda_craft_default_secondary.png", "builda_craft_default_highlight.png", "builda_craft_default_details.png"},
    })
    player:set_eye_offset(nil, {x=0,y=0,z=10})
    local name = player:get_player_name()
    local privs = minetest.get_player_privs(name)
    privs.fly = true
    minetest.set_player_privs(name, privs)
end)


--Wind turbines provided by BigPowerCorp.
--They only spawn on hills (we assume flat mapgen from polymap).
minetest.register_decoration({
    name = "builda:wind_turbine",
    deco_type = "schematic",
    place_on = {"polymap:grass"},
    sidelen = 2,
    noise_params = {
        offset = 0,
        scale = 0.005,
        spread = {x = 50, y = 50, z = 50},
        seed = 354,
        octaves = 3,
        persist = 0.5
    },
    biomes = {"grassland"},
    y_max = 31000,
    y_min = 9,
    height = 4,
    schematic = {
        size = {x = 1, y = 4, z = 2},
        data = {
            {name ="ignore"}, {name = "city:wind_turbine", param2 = 2},
            {name ="ignore"}, {name ="ignore"}, 
            {name ="ignore"}, {name ="ignore"},
            {name = "ignore"}, {name ="city:wind_turbine_blade", param2 = 5},
        },
    },
    flags = "force_placement",
})


--Roads are starting points, where a player can start building from.
minetest.register_decoration({
    name = "builda:road",
    deco_type = "simple",
    place_on = {"polymap:grass"},
    fill_ratio = 0.0005,
    biomes = {"grassland"},
    y_max = 8,
    y_min = 0,
    decoration = "city:street",
})




local street_cost = 75
local street_co2 = 2

local costs = {
    green = { 20, 30, },
    residential_concrete = { 300, 600, 1200, 2400,},
    residential_brick = { 350, 700, 1400, 2800,},
    residential_wood = { 400, 800, },
}

local co2 = {
    green = { -80, -140, },
    residential_concrete = { 100, 200, 400, 800, },
    residential_brick = { 60, 120, 240, 480, },
    residential_wood = { 20, 40, },
}

local population = {
    green = { 0, 0, },
    residential_concrete = { 4, 10, 40, 160, },
    residential_brick = { 4, 10, 25, 60, },
    residential_wood = { 4, 10, },
}

_G.builda.AddPoints = function(user, building_type, from_level, to_level)
    _G.builda.AddPlayerCosts(user, (costs[building_type][to_level] or 0) - (costs[building_type][from_level] or 0))
    _G.builda.AddPlayerCo2(user, (co2[building_type][to_level] or 0) - (co2[building_type][from_level] or 0))
    _G.builda.AddPlayerPopulation(user, (population[building_type][to_level] or 0) - (population[building_type][from_level] or 0))
end

minetest.register_item("builda:road", {
    description = S("Road"),
    inventory_image = "builda_road.png",
    type = "tool",
    on_place = function(_itemstack, user, pointed_thing)
        _G.worksaver.update_area(pointed_thing.above)
        if pointed_thing.type == "node" then
            if logistics.place("city:street_off", pointed_thing.above, user) then
                _G.builda.AddPlayerCosts(user, street_cost)
                _G.builda.AddPlayerCo2(user, street_co2)
            end
        end
    end
})

minetest.register_item("builda:green", {
    description = S("Green area in the city"),
    inventory_image = "nature.png",
    type = "tool",
    on_place = function(_itemstack, user, pointed_thing)
        if pointed_thing.type == "node" then
            _G.insta.build("green", 2, pointed_thing, user)
        end
    end,
})

minetest.register_item("builda:residential_concrete", {
    description = S("Residential Concrete House"),
    inventory_image = "house_concrete.png",
    type = "tool",
    on_place = function(_itemstack, user, pointed_thing)
        if pointed_thing.type == "node" then
            _G.insta.build("residential_concrete", 4, pointed_thing, user)
        end
    end,
    on_use = function(_itemstack, user, pointed_thing)
        if pointed_thing.type == "node" then
            _G.insta.unbuild("residential_concrete", pointed_thing, user)
        end
    end

})

minetest.register_item("builda:residential_brick", {
    description = S("Residential Brick House"),
    inventory_image = "house_brick.png",
    type = "tool",
    on_place = function(_itemstack, user, pointed_thing)
        if pointed_thing.type == "node" then
            _G.insta.build("residential_brick", 4, pointed_thing, user)
        end
    end,
    on_use = function(_itemstack, user, pointed_thing)
        if pointed_thing.type == "node" then
            _G.insta.unbuild("residential_brick", pointed_thing, user)
        end
    end
})

minetest.register_item("builda:residential_wood", {
    description = S("Residential Wooden House"),
    inventory_image = "house_wood.png",
    type = "tool",
    on_place = function(_itemstack, user, pointed_thing)
        if pointed_thing.type == "node" then
            _G.insta.build("residential_wood", 2, pointed_thing, user)
        end
    end,
    on_use = function(_itemstack, user, pointed_thing)
        if pointed_thing.type == "node" then
            _G.insta.unbuild("residential_wood", pointed_thing, user)
        end
    end
})

--Destroyer is used to destroy built nodes such as roads and buildings.
minetest.register_item("builda:destroyer", {
    description = S("Destroyer"),
    inventory_image = "builda_destroyer.png",
    type = "tool",
    on_place = function(itemstack, user, pointed_thing)
        if pointed_thing.type == "node" then
            local pos = pointed_thing.under

            local thing = minetest.get_node(pos)
            local item = minetest.registered_items[thing.name]
            if item then
                if thing.name == "city:street_off" then
                    _G.builda.AddPlayerCosts(user, -street_cost)
                else
                    _G.builda.AddPoints(user, item.kind, item.level, 0)
                end
            end

            if logistics.remove(pos) then
                --'explode' the node.
                minetest.add_particlespawner({
                    amount = 10,
                    time = 0.2,
                    minpos={x=pos.x-0.5, y=pos.y-0.5, z=pos.z-0.5},
                    maxpos={x=pos.x+0.5, y=pos.y-0.5, z=pos.z+0.5},
                    minvel={x=-4, y=2, z=-4},
                    maxvel={x=4, y=4, z=4},
                    texture = "builda_craft_default.png",
                    minsize = 1,
                    maxsize = 1,
                    minexptime = 0.2,
                    maxexptime = 0.2,
                })
                minetest.sound_play("builda_explode", {pos = pos, max_hear_distance = 20})
            end
        end
    end
})

local modpath = minetest.get_modpath("builda")
dofile(modpath.."/guide.lua")