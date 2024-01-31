local builda = {
    changed = true,
}

_G.builda = builda

print("Init mods/builda/init.lua")

dofile(minetest.get_modpath("insta").."/countdown.lua")

--builda implements the gameplay logic of Builda City.
--In this gamemode, players have energy and are required to build
--cities so that they can collect coins and profit from the global
--energy supply infrastructure.

local S = minetest.get_translator("builda")

local hud_id_money
local hud_id_co2
local hud_id_population

local AddPlayerEnergy = function(player, energy)
    player:get_meta():set_float("energy", player:get_meta():get_float("energy")+energy)
    player:hud_change(hud_id_co2, "text", math.floor(0.5+player:get_meta():get_float("energy")))
end

local function reset_state() 
    for _, player in ipairs(minetest.get_connected_players()) do
        player:get_meta():set_int("costs", 0)
        player:get_meta():set_int("population", 0)
        player:get_meta():set_int("co2", 0)
        player:hud_change(hud_id_money, "text", 0)
        player:hud_change(hud_id_co2, "text", 0)
        player:hud_change(hud_id_population, "text", 0)
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
        player:hud_change(hud_id_money, "text", player:get_meta():get_int("costs"))
    end
    return true
end

local AddPlayerPopulation = function(player, coins)
    player:get_meta():set_int("population", player:get_meta():get_int("population") + coins);
    if player:get_meta():get_int("population") < 0 then
        player:get_meta():set_int("population", 0)
        return false
    end
    if hud_id_population then
        player:hud_change(hud_id_population, "text", player:get_meta():get_int("population"))
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
        player:hud_change(hud_id_co2, "text", player:get_meta():get_int("co2"))
    end
    return true
end


local PlayerCanAfford = function(player, coins)
    return player:get_meta():get_int("coins") >= coins
end

local PlayerHasEnergy = function(player, energy)
    return player:get_meta():get_float("energy") >= energy
end

minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
    if PlayerHasEnergy(puncher, 1) and city.power(pos) then
        local income = 1
        if string.match(node.name,"shop") then
            income = 2
        end
        if string.match(node.name,"mall") then
            income = 5
        end
        if string.match(node.name,"skyscraper") then
            income = 10
        end
        local height = minetest.get_item_group(node.name, "height")
        if height == 0 then
            height = 1
        end
        AddPlayerCosts(puncher, income)
        minetest.sound_play("builda_income", {pos = pos, max_hear_distance = 20})
        minetest.add_particle({
            pos={x=pos.x, y=pos.y-(2.9-height), z=pos.z},
            velocity={x=0, y=16, z=0},
            acceleration={x=0,y=-42,z=0},
            texture = "builda_coin.png",
            size = 8,
            playername = puncher:get_player_name(),
        })
        AddPlayerEnergy(puncher, -1)
    end
    local energy = minetest.get_item_group(node.name, "energy_source")
    if energy > 0 then
        if node.name == "city:wind_turbine" then 
            energy = energy * (pos.y-8) --energy is proportional to height (wind)
        end
        if city.disable(pos) then
            minetest.after(1, function(energy)
                AddPlayerEnergy(puncher, energy) 
            end, energy)
            minetest.sound_play("builda_charge", {pos = pos, max_hear_distance = 20})
        end
    end
    if string.match(node.name, "city:.*_disabled") then
        minetest.sound_play("builda_broken", {pos = pos, max_hear_distance = 20})
        minetest.add_particlespawner({
            amount = 20,
            time = 0.3,
            minpos={x=pos.x-0.5, y=pos.y-0.5, z=pos.z-0.5},
            maxpos={x=pos.x+0.5, y=pos.y-0.5, z=pos.z+0.5},
            minvel={x=-4, y=2, z=-4},
            maxvel={x=4, y=4, z=4},
            texture = "builda_energy.png",
            minsize = 1,
            maxsize = 1,
            minexptime = 0.2,
            maxexptime = 0.2,
        })
    end
end)

minetest.hud_replace_builtin("health", nil)

local last_inventory_update = 0

minetest.register_globalstep(function(dt)
    for _, player in ipairs(minetest.get_connected_players()) do
        if player:get_hp() > 0 then
            local controls = player:get_player_control() 
            if controls.aux1 then
                player:set_physics_override({
                    speed = 8,
                })
            else 
                player:set_physics_override({
                    speed = 1,
                })
            end
        end

        last_inventory_update = last_inventory_update + dt
        if last_inventory_update > 1 then
            last_inventory_update = 0

            local pos = player:get_pos()
            if pos.y > 10 then
                pos.y = 10
            end

            if true then
                city.guide(player)
                return
            end

            --FIXME how to show city info?

            
        end
    end
end)

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
        "builda:info 1",
        "builda:road 1",
        "builda:residential_concrete 1",
        "builda:residential_wood 1",
        "builda:destroyer 1",
    }

    --Initialise the buildbar (hotbar).
    player:get_inventory():set_list("main", list)
    player:hud_set_hotbar_itemcount(#list)

    --Remove default HUD elements.
    player:hud_set_flags({healthbar=false, breathbar=false, wielditem=false})
    player:hud_set_hotbar_image("builda_empty.png")

    --Brain Icon.
    player:hud_add({
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
        text = player:get_meta():get_int("costs"),
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
        text = math.floor(player:get_meta():get_float("co2")+0.5),
        number = 0xffffff,
        size = {x=3, y=3+5},
        offset = {x=-90, y=64+5},
        alignment = {x=-1, y=1},
    })
    --Energy Icon
    player:hud_add({
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
        text = math.floor(player:get_meta():get_float("population")+0.5),
        number = 0xffffff,
        size = {x=3, y=3+5},
        offset = {x=-90, y=64+5+64},
        alignment = {x=-1, y=1},
    })
    -- Population Icon
    player:hud_add({
        hud_elem_type = "statbar",
        position = {x=1, y=0},
        text = "population.png",
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
--[[minetest.register_decoration({
    name = "builda:tree",
    deco_type = "simple",
    place_on = {"polymap:grass"},
    fill_ratio = 0.05,
    biomes = {"grassland"},
    y_max = 31000,
    y_min = 0,
    decoration = "city:tree_a",
})]]

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



minetest.register_item("builda:info", {
    description = S("Info"),
    inventory_image = "builda_info.png",
    type = "tool",
    on_place = function(itemstack, user, pointed_thing)
        if not pointed_thing.under then
            minetest.show_formspec(user:get_player_name(), "builda:guide", city.guide(user))
            return
        end

        local pos = pointed_thing.under
        local node = minetest.get_node_or_nil(pos)
        if string.match(node.name,"city") then
            local index = logistics.index(pos)
            local resources = logistics.at(pos)

            if index == 0 then
                minetest.show_formspec(user:get_player_name(), "builda:guide", city.guide(user))
                return
            end

            local founder = city.get_string(index, "founder")
            if founder == user:get_player_name() then
                founder = "you"
            end

            local population = resources.population or 0

            local stats = city.get_string(index, "name").."\n("..founder.." founded this city)"..
                "\n\nPopulation: "..population

            minetest.show_formspec(user:get_player_name(), "builda:city_stats",
                "size[8,7.2,false]"..
                "hypertext[0.5,0;4.75,8.5;stats;"..stats.."]"..
                "button_exit[1.3,6.2;1.5,0.8;close;OK]"
            )
        else
            minetest.show_formspec(user:get_player_name(), "builda:guide", city.guide(user))
        end
    end
})

minetest.register_item("builda:road", {
    description = S("Road"),
    inventory_image = "builda_road.png",
    type = "tool",
    on_place = function(itemstack, user, pointed_thing)
        _G.worksaver.update_area(pointed_thing.above)
        _G.worksaver.print_area()
        if pointed_thing.type == "node" then
            if logistics.place("city:street_off", pointed_thing.above, user) then
                AddPlayerCosts(user, 3)
                AddPlayerCO2(user, 5)
                minetest.sound_play("builda_pay", {pos = pointed_thing.above, max_hear_distance = 20})
            end
        end
    end
})

minetest.register_item("builda:residential_concrete", {
    description = S("Residential Concrete House"),
    inventory_image = "builda_residential_concrete.png",
    type = "tool",
    on_place = function(itemstack, user, pointed_thing)
        if pointed_thing.type == "node" then
            if insta.build_residential_concrete(pointed_thing, user) then
                AddPlayerCosts(user, 10)
                AddPlayerPopulation(user, 13)
                AddPlayerCO2(user, 70)
                minetest.sound_play("builda_pay", {pos = pointed_thing.above, max_hear_distance = 20})
            end
        end
    end,
    on_use = function(itemstack, user, pointed_thing)
        minetest.debug("on_use: node type: " .. pointed_thing.type)
        if pointed_thing.type == "node" then
            if insta.unbuild_residential_concrete(pointed_thing, user) then
                AddPlayerCosts(user, -10)
                AddPlayerPopulation(user, -13)
                AddPlayerCO2(user, -70)
                minetest.sound_play("builda_pay", {pos = pointed_thing.above, max_hear_distance = 20})
            end
        end
    end

})

minetest.register_item("builda:residential_wood", {
    description = S("Residential Wooden House"),
    inventory_image = "builda_residential_wood.png",
    type = "tool",
    on_place = function(itemstack, user, pointed_thing)
        if pointed_thing.type == "node" then
            if insta.build_residential_wood(pointed_thing, user) then
                AddPlayerCosts(user, 10)
                AddPlayerPopulation(user, 6)
                AddPlayerCO2(user, 20)
                minetest.sound_play("builda_pay", {pos = pointed_thing.above, max_hear_distance = 20})
            end
        end
    end,
    on_use = function(itemstack, user, pointed_thing)
        if pointed_thing.type == "node" then
            if PlayerCanAfford(user, 1) then
                if insta.unbuild_residential_wood(pointed_thing, user) then
                    AddPlayerCosts(user, -10)
                    AddPlayerPopulation(user, -6)
                    AddPlayerCO2(user, -20)
                    minetest.sound_play("builda_pay", {pos = pointed_thing.above, max_hear_distance = 20})
                end
            end
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

            if minetest.is_protected(pos, user:get_player_name()) then
                minetest.record_protection_violation(pos, user:get_player_name())
                minetest.sound_play("builda_error", {pos = pointed_thing.below, max_hear_distance = 20})
                return
            end

            local node = minetest.get_node(pos)
            if PlayerHasEnergy(user, 5) and minetest.get_item_group(node.name, "consumer") > 0 and logistics.remove(pos) then
                AddPlayerEnergy(user, -5)

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
            else
                minetest.sound_play("builda_error", {pos = pointed_thing.below, max_hear_distance = 20})
            end
        end
    end
})


local modpath = minetest.get_modpath("builda")
dofile(modpath.."/guide.lua")