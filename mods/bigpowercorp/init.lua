--bigpowercorp implements the gameplay logic of Build a City.
--In this gamemode, players have energy and are required to build
--cities so that they can collect coins and maintain bigpowercorp's
--electricity generation infrastructure.

local coins_count = 1;
local energy_count = 2;

local AddPlayerEnergy = function(player, energy)
    player:get_meta():set_float("energy", player:get_meta():get_float("energy")+energy)
    player:hud_change(energy_count, "text", math.floor(0.5+player:get_meta():get_float("energy")))
    if player:get_meta():get_float("energy") < 0 then
        player:set_hp(0, "out of energy")
    end
end

local AddPlayerCoins = function(player, coins)
    player:get_meta():set_int("coins", player:get_meta():get_int("coins") + coins);
    player:hud_change(coins_count, "text", player:get_meta():get_int("coins"))
end

local suffix_len = #"_decayed"

minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
    if string.match(node.name, "city:.*_decayed") then
        AddPlayerCoins(puncher, 1)
        minetest.set_node(pos, {name = string.sub(node.name, 0, #node.name-suffix_len), param2 = node.param2})
        minetest.sound_play("bigpowercorp_income", {pos = pos, max_hear_distance = 20})
        minetest.add_particle({
            pos={x=pos.x, y=pos.y, z=pos.z},
            velocity={x=0, y=16, z=0},
            acceleration={x=0,y=-42,z=0},
            texture = "bigpowercorp_coin.png",
            size = 8,
            playername = puncher:get_player_name(),
        })
        AddPlayerEnergy(puncher, -1)
    end
    local energy = minetest.get_item_group(node.name, "energy_source")
    if energy > 0 then
        minetest.after(1, function(energy)
            AddPlayerEnergy(puncher, energy)
        end, energy)
        minetest.sound_play("bigpowercorp_charge", {pos = pos, max_hear_distance = 20})
    end
end)

minetest.hud_replace_builtin("health", nil)

minetest.register_globalstep(function(dt)
    for _, player in ipairs(minetest.get_connected_players()) do
        if player:get_hp() > 0 then
            local controls = player:get_player_control() 
            if controls.aux1 then
                player:set_physics_override({
                    speed = 4,
                })
                AddPlayerEnergy(player,  - dt * 1)
            else 
                player:set_physics_override({
                    speed = 1,
                })
                AddPlayerEnergy(player,  - dt * 1/60)
            end
        end
    end
end)

minetest.item_drop = function() end

minetest.is_protected = function(pos, name)

    --Nodes can only be placed next to existing roads.
    local top = minetest.get_node({x=pos.x, y=pos.y, z=pos.z+1})
    local bot = minetest.get_node({x=pos.x, y=pos.y, z=pos.z-1})
    local left = minetest.get_node({x=pos.x-1, y=pos.y, z=pos.z})
    local right = minetest.get_node({x=pos.x+1, y=pos.y, z=pos.z})

    if string.match(top.name, "city:road.*") then 
        return false
    end
    if string.match(bot.name, "city:road.*") then 
        return false
    end
    if string.match(left.name, "city:road.*") then 
        return false
    end
    if string.match(right.name, "city:road.*") then 
        return false
    end

    return true
end

minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
    AddPlayerEnergy(placer, -minetest.get_item_group(newnode.name, "cost"))
    return true -- we don't have an inventory in this game, so we never remove items from the hotbar.
end)

minetest.register_item(":", {
    type = "none",
    range = 10,
})

minetest.register_on_respawnplayer(function(player)
    player:get_meta():set_int("coins", 0);
    player:hud_change(coins_count, "text", 0)
    AddPlayerEnergy(player, 50)
end)

--We need to attach the Energy and Humans HUD counts.
--Humans is top left, Energy is top right.
minetest.register_on_joinplayer(function(player)    
    --Give the player a reasonable amount of starting energy.
    if player:get_meta():contains("energy") == false then
        player:get_meta():set_float("energy", 100)
    end

    --Initialise the buildbar (hotbar).
    player:get_inventory():set_list("main", {
        "city:road 1",
        "city:skyscraper 1",
    })
    player:set_inventory_formspec("size[6,3]label[0.05,0.05;BigPowerCorp Employee Handbook]button_exit[0.8,2;1.5,0.8;close;Close]label[0.05,1.5;There is nothing here]")

    --Remove default HUD elements.
    player:hud_set_flags({healthbar=false, breathbar=false, wielditem=false})
    player:hud_set_hotbar_image("bigpowercorp_empty.png")

    --Brain Icon.
    player:hud_add({
        hud_elem_type = "statbar",
        position = {x=0, y=0},
        text = "bigpowercorp_coin.png",
        number = 2,
        size = {x=64, y=64},
        offset = {x=10, y=0},
    })
    --Brain Count
    player:hud_add({
        name = "coins",
        hud_elem_type = "text",
        position = {x=0, y=0},
        text = player:get_meta():get_int("coins"),
        number = 0xffffff,
        size = {x=3, y=3},
        offset = {x=90, y=5},
        alignment = {x=1, y=1},
    })
    --Energy Count
    player:hud_add({
        name = "energy",
        hud_elem_type = "text",
        position = {x=1, y=0},
        text = math.floor(player:get_meta():get_float("energy")+0.5),
        number = 0xffffff,
        size = {x=3, y=3},
        offset = {x=-80, y=5},
        alignment = {x=-1, y=1},
    })
    --Energy Icon
    player:hud_add({
        hud_elem_type = "statbar",
        position = {x=1, y=0},
        text = "bigpowercorp_energy.png",
        number = 2,
        size = {x=48, y=48},
        offset = {x=-64, y=7},
    })
    

    --Setup camera, the player is inside an energy distrubution craft
    --and is able to fly through single-node spaces.
    player:set_properties({
        eye_height = 0.2,
        collisionbox = {-0.3, 0.0, -0.3, 0.3, 0.3, 0.3},
        visual = "mesh",
        mesh = "bigpowercorp_craft_default.obj",
        textures = {"bigpowercorp_craft_default.png", "bigpowercorp_craft_default_highlight.png"},
    })
    player:set_eye_offset(nil, {x=0,y=0,z=10})
    local name = player:get_player_name()
    local privs = minetest.get_player_privs(name)
    privs.fly = true
    minetest.set_player_privs(name, privs)
    
end)

minetest.register_on_mapgen_init(function()
    minetest.set_mapgen_setting("mg_name", "flat", true)
    minetest.set_mapgen_setting("mg_flags", "noores,nocaves,nodungeons,light,decorations,biomes", true)
    minetest.set_mapgen_setting("mgflat_spflags", "hills,lakes,nocaverns", true)
    minetest.set_mapgen_setting("water_level", "8", true)

    local seed = math.random(0, 2^32-1)
    local existing = minetest.get_mapgen_setting_noiseparams("mgflat_np_terrain")
    if existing then
        seed = existing.seed
    end

    minetest.set_mapgen_setting_noiseparams("mgflat_np_terrain", {
        flags = "defaults",
        lacunarity = 2,
        persistence = 0.6,
        seed = seed,
        spread = {x=120,y=120,z=120},
        scale = 1,
        octaves = 5,
        offset = 0,
    }, true)

    minetest.set_mapgen_setting("mgflat_hill_threshold", "0.3", true)
    minetest.set_mapgen_setting("mgflat_hill_steepness", "10", true)
    minetest.set_mapgen_setting("mgflat_lake_threshold", "0", true)
end)

--Wind turbines provided by BigPowerCorp.
--Only spawn on hills.
minetest.register_decoration({
    name = "bigpowercorp:wind_turbine",
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
    name = "bigpowercorp:road",
    deco_type = "simple",
    place_on = {"polymap:grass"},
    fill_ratio = 0.0005,
    biomes = {"grassland"},
    y_max = 8,
    y_min = 0,
    decoration = "city:road",
})