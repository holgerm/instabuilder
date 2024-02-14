local builda = {
    changed = true,
}

_G.builda = builda

dofile(minetest.get_modpath("insta").."/countdown.lua")

--builda implements the gameplay logic of Builda City.
--In this gamemode, players have energy and are required to build
--cities so that they can collect coins and profit from the global
--energy supply infrastructure.

local S = minetest.get_translator("builda")

local hud_id_money
local hud_id_money_icon
local hud_id_co2
local hud_id_co2_icon
local hud_id_population
local hud_id_population_icon

local function reset_state()
    for _, player in ipairs(minetest.get_connected_players()) do
        player:get_meta():set_int("costs", 0)
        player:get_meta():set_int("population", 0)
        player:get_meta():set_int("co2", 0)
        player:hud_change(hud_id_money, "text", 0 .. " / " .. _G.insta.goal_money)
        player:hud_change(hud_id_co2, "text", 0 .. " / " .. _G.insta.goal_co2)
        player:hud_change(hud_id_population, "text", 0 .. " / " .. _G.insta.goal_population)
        -- Change the text color to red
        player:hud_change(hud_id_population, "number", 0xFF0000)
        player:hud_change(hud_id_population_icon, "text", "population_red.png")
    end
end

_G.builda.Reset_state = reset_state

--returns true if the player can afford.
local AddPlayerCosts = function(player, coins)
    player:get_meta():set_int("costs", player:get_meta():get_int("costs") + coins);
    if player:get_meta():get_int("costs") < 0 then
        player:get_meta():set_int("costs", 0)
        return false
    end
    if hud_id_money then
        player:hud_change(hud_id_money, "text", player:get_meta():get_int("costs") .. " / " .. _G.insta.goal_money)
        if player:get_meta():get_int("costs") > _G.insta.goal_money then
            -- Change the text color to red
            player:hud_change(hud_id_money, "number", 0xFF0000)
            player:hud_change(hud_id_money_icon, "text", "cost_red.png")

        else
            -- Change the text color to white
            player:hud_change(hud_id_money, "number", 0xFFFFFF)
            player:hud_change(hud_id_money_icon, "text", "cost.png")
        end
    end

    return true
end

local AddPlayerPopulation = function(player, coins)
    player:get_meta():set_int("population", player:get_meta():get_int("population") + coins);
    if player:get_meta():get_int("population") < 0 then
        player:get_meta():set_int("population", 0)
        -- Change the text color to red
        player:hud_change(hud_id_population, "number", 0xFF0000)
        return false
    end
    if hud_id_population then
        player:hud_change(hud_id_population, "text", player:get_meta():get_int("population") .. 
            " / " .. _G.insta.goal_population)
        if player:get_meta():get_int("population") < _G.insta.goal_population then
            -- Change the text color to red
            player:hud_change(hud_id_population, "number", 0xFF0000)
            player:hud_change(hud_id_population_icon, "text", "population_red.png")
        else
            player:hud_change(hud_id_population, "number", 0xFFFFFF)
            player:hud_change(hud_id_population_icon, "text", "population.png")
        end
    end
    return true
end

local AddPlayerCO2 = function(player, coins)
    player:get_meta():set_int("co2", player:get_meta():get_int("co2") + coins);
    if player:get_meta():get_int("co2") < 0 then
        player:get_meta():set_int("co2", 0)
        return false
    end
    if hud_id_co2 then
        player:hud_change(hud_id_co2, "text", player:get_meta():get_int("co2") ..
            " / " .. _G.insta.goal_co2)
        if player:get_meta():get_int("co2") > _G.insta.goal_co2 then
            -- Change the text color to red
            player:hud_change(hud_id_co2, "number", 0xFF0000)
            player:hud_change(hud_id_co2_icon, "text", "co2_red.png")
        else
            -- Change the text color to white
            player:hud_change(hud_id_co2, "number", 0xFFFFFF)
            player:hud_change(hud_id_co2_icon, "text", "co2.png")
        end
    end
    return true
end


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
        AddPlayerCosts(player, 0)
    end

    local list = {
        "builda:road 1",
        "builda:residential_concrete 1",
        "builda:residential_brick 1",
        "builda:residential_wood 1",
    }

    --Initialise the buildbar (hotbar).
    player:get_inventory():set_list("main", list)
    player:hud_set_hotbar_itemcount(#list)

    --Remove default HUD elements.
    player:hud_set_flags({healthbar=false, breathbar=false, wielditem=false})
    player:hud_set_hotbar_image("builda_empty.png")

    --Brain Icon.
    hud_id_money_icon = player:hud_add({
        hud_elem_type = "statbar",
        position = {x=1, y=0},
        text = "cost.png",
        number = 2,
        size = {x=64, y=64},
        offset = {x=-64-10, y=5},
    })
    --Brain Count
    hud_id_money = player:hud_add({
        name = "coins",
        hud_elem_type = "text",
        position = {x=1, y=0},
        text = player:get_meta():get_int("costs") .. " / " .. _G.insta.goal_money,
        number = 0xffffff,
        size = {x=3, y=3},
        offset = {x=-90, y=10},
        alignment = {x=-1, y=1},
    })
    --Energy Count
    hud_id_co2 = player:hud_add({
        name = "co2",
        hud_elem_type = "text",
        position = {x=1, y=0},
        text = math.floor(player:get_meta():get_float("co2")+0.5) .. " / " .. _G.insta.goal_co2,
        number = 0xffffff,
        size = {x=3, y=3+5},
        offset = {x=-90, y=64+5},
        alignment = {x=-1, y=1},
    })
    --Energy Icon
    hud_id_co2_icon = player:hud_add({
        hud_elem_type = "statbar",
        position = {x=1, y=0},
        text = "co2.png",
        number = 2,
        size = {x=48, y=48+5},
        offset = {x=-64, y=64+7},
    })
    -- Population Count
    hud_id_population = player:hud_add({
        name = "population",
        hud_elem_type = "text",
        position = {x=1, y=0},
        text = math.floor(player:get_meta():get_float("population")+0.5) .. " / " .. _G.insta.goal_population,
        number = 0xffffff,
        size = {x=3, y=3+5},
        offset = {x=-90, y=64+5+64},
        alignment = {x=-1, y=1},
    })
    -- Population Icon
    hud_id_population_icon = player:hud_add({
        hud_elem_type = "statbar",
        position = {x=1, y=0},
        text = "population_red.png",
        number = 2,
        size = {x=48, y=48+5},
        offset = {x=-64, y=64+7+64},
    })


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




local road_cost = 3
local road_co2 = 5

local residential_concrete_cost = 8
local residential_concrete_co2 = 13
local residential_concrete_population = 12

local residential_brick_cost = 6
local residential_brick_co2 = 5
local residential_brick_population = 8

local residential_wood_cost = 4
local residential_wood_co2 = 2
local residential_wood_population = 4

minetest.register_item("builda:road", {
    description = S("Road"),
    inventory_image = "builda_road.png",
    type = "tool",
    on_place = function(itemstack, user, pointed_thing)
        _G.worksaver.update_area(pointed_thing.above)
        _G.worksaver.print_area()
        if pointed_thing.type == "node" then
            if logistics.place("city:street_off", pointed_thing.above, user) then
                AddPlayerCosts(user, road_cost)
                AddPlayerCO2(user, road_co2)
            end
        end
    end
})

minetest.register_item("builda:residential_concrete", {
    description = S("Residential Concrete House"),
    inventory_image = "house_concrete.png",
    type = "tool",
    on_place = function(itemstack, user, pointed_thing)
        if pointed_thing.type == "node" then
            if insta.build_residential_concrete(pointed_thing, user) then
                AddPlayerCosts(user, residential_concrete_cost)
                AddPlayerPopulation(user, residential_concrete_population)
                AddPlayerCO2(user, residential_concrete_co2)
            end
        end
    end,
    on_use = function(itemstack, user, pointed_thing)
        if pointed_thing.type == "node" then
            if insta.unbuild_residential_concrete(pointed_thing, user) then
                AddPlayerCosts(user, -residential_concrete_cost)
                AddPlayerPopulation(user, -residential_concrete_population)
                AddPlayerCO2(user, -residential_concrete_co2)
            end
        end
    end

})

minetest.register_item("builda:residential_brick", {
    description = S("Residential Brick House"),
    inventory_image = "house_brick.png",
    type = "tool",
    on_place = function(itemstack, user, pointed_thing)
        if pointed_thing.type == "node" then
            if insta.build_residential_brick(pointed_thing, user) then
                AddPlayerCosts(user, residential_brick_cost)
                AddPlayerPopulation(user, residential_brick_population)
                AddPlayerCO2(user, residential_brick_co2)
            end
        end
    end,
    on_use = function(itemstack, user, pointed_thing)
        if pointed_thing.type == "node" then
            if insta.unbuild_residential_brick(pointed_thing, user) then
                AddPlayerCosts(user, -residential_brick_cost)
                AddPlayerPopulation(user, -residential_brick_population)
                AddPlayerCO2(user, -residential_brick_co2)
            end
        end
    end
})

minetest.register_item("builda:residential_wood", {
    description = S("Residential Wooden House"),
    inventory_image = "house_wood.png",
    type = "tool",
    on_place = function(itemstack, user, pointed_thing)
        if pointed_thing.type == "node" then
            if insta.build_residential_wood(pointed_thing, user) then
                AddPlayerCosts(user, residential_wood_cost)
                AddPlayerPopulation(user, residential_wood_population)
                AddPlayerCO2(user, residential_wood_co2)
            end
        end
    end,
    on_use = function(itemstack, user, pointed_thing)
        if pointed_thing.type == "node" then
            if insta.unbuild_residential_wood(pointed_thing, user) then
                AddPlayerCosts(user, -residential_wood_cost)
                AddPlayerPopulation(user, - residential_wood_population)
                AddPlayerCO2(user, -residential_wood_co2)
            end
        end
    end
})

local modpath = minetest.get_modpath("builda")
dofile(modpath.."/guide.lua")