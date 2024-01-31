print("This is the insta mod at mods/insta/init.lua")

local S = minetest.get_translator("insta")

local insta = {
    changed = true,
}

_G.insta = insta

-- #################### INTRO FORM ####################

local function showIntroForm_DE(player, image)
    local formspec = {
        "formspec_version[4]",
        "size[20,13]",
        "image_button[0.5,0.5;19,12;"..image..";start;]",
    }

    minetest.show_formspec(player:get_player_name(), "insta:welcomeDE", table.concat(formspec, ""))
end

local function start_countdown()
    local players = minetest.get_connected_players()

    local function on_end(player)
        showIntroForm_DE(player, "IntroGraphic.jpg")
    end

    local function on_warn(player)
        _G.countdown.set_color(0xFF22AA) -- set text to red
        minetest.sound_play("eineMinute", {
            to_player = player:get_player_name()
        })
    end

    _G.countdown.set_color(0xFFFFFF) -- set text to white
    _G.countdown.start(players[1], "Verbleibende Zeit: ",420, on_end, 60, on_warn)
end

minetest.register_on_joinplayer(function(player)
    print("insta:register_on_joinplayer()")
    showIntroForm_DE(player, "IntroGraphic.jpg")
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if (formname == "insta:welcomeDE") and fields.start then
        _G.worksaver.Reset_world()
        start_countdown()
        minetest.show_formspec(player:get_player_name(), formname, "")
    end
end)


-- #################### BUILDING ####################

local function print_details(item_name)
    local item_def = minetest.registered_items[item_name]

    if item_def and item_def.groups then
        print("level: " .. (item_def.level or "none"))
        print("Groups for '"..item_name.."':")
        for group, rating in pairs(item_def.groups) do
            print(group .. " : " .. rating)
        end
    else
        print("Item '"..item_name.."' is not registered or does not belong to any groups.")
    end
end


--city.build builds a random kind building at position pos
--if builder is provided, acts like place_node.
function insta.build_residential_concrete(pointed_thing, builder)
    local pos = pointed_thing.above
    -- in case we have abuilding we pointed too high and adjust it here
    if pos.y == 10 then
        pos = pointed_thing.under
    end
    local current = minetest.get_node(pos)

    -- level 1 on plain ground only if street is nearby:
    if current.name == "air" then
        local road = logistics.node_near(pos, builder, "street")
        if not road then
            print("no house and no road")
            return false
        else
            return logistics.place(city.buildings["residential_concrete"][1].."_off", pos, builder)
        end
    end


    -- level is 2 or higher on plain ground only if street is nearby:
    local building_type = "residential_concrete"
    local item_def = minetest.registered_items[current.name:sub(1,#"city:residential_concrete_n")]
    if current.name:sub(1,#"city:residential_concrete") == "city:residential_concrete" and item_def.level and item_def.level < 4 then
        return logistics.place(city.buildings[building_type][item_def.level + 1].."_off", pos, builder)
    end
end

function insta.unbuild_residential_concrete(pointed_thing, builder)
    local pos = pointed_thing.above
    -- in case we have abuilding we pointed too high and adjust it here
    if pos.y > 9 then
        pos = pointed_thing.under
    end
    local current = minetest.get_node(pos)

    -- level 1 on plain ground only if street is nearby:
    if current.name == "air" then
        return false
    end

    -- level is 2 or higher on plain ground only if street is nearby:
    local building_type = "residential_concrete"
    local item_def = minetest.registered_items[current.name:sub(1,#"city:residential_concrete_n")]
    if current.name:sub(1,#"city:residential_concrete") == "city:residential_concrete" and item_def.level then
        if item_def.level > 1 then
            return logistics.place(city.buildings[building_type][item_def.level - 1].."_off", pos, builder)
        elseif item_def.level == 1 then
            return logistics.remove(pos, builder)
        end
    end
end

function insta.build_residential_wood(pointed_thing, builder)
    local pos = pointed_thing.above
    -- in case we have abuilding we pointed too high and adjust it here
    if pos.y == 10 then
        pos = pointed_thing.under
    end
    local current = minetest.get_node(pos)

    -- level 1 on plain ground only if street is nearby:
    if current.name == "air" then
        local road = logistics.node_near(pos, builder, "street")
        if not road then
            print("no house and no road")
            return false
        else
            return logistics.place(city.buildings["residential_wood"][1].."_off", pos, builder)
        end
    end
    -- level is 2 or higher on plain ground only if street is nearby:
    local building_type = "residential_wood"
    local item_def = minetest.registered_items[current.name:sub(1,#"city:residential_wood_n")]
    if current.name:sub(1,#"city:residential_wood") == "city:residential_wood" and item_def.level and item_def.level < 2 then
        return logistics.place(city.buildings[building_type][item_def.level + 1].."_off", pos, builder)
    end
end


function insta.unbuild_residential_wood(pointed_thing, builder)
    local pos = pointed_thing.above
    -- in case we have abuilding we pointed too high and adjust it here
    if pos.y > 9 then
        pos = pointed_thing.under
    end
    local current = minetest.get_node(pos)

    -- level 1 on plain ground only if street is nearby:
    if current.name == "air" then
        return false
    end

    -- level is 2 or higher on plain ground only if street is nearby:
    local building_type = "residential_wood"
    local item_def = minetest.registered_items[current.name:sub(1,#"city:residential_wood_n")]
    if current.name:sub(1,#"city:residential_wood") == "city:residential_wood" and item_def.level then
        if item_def.level > 1 then
            return logistics.place(city.buildings[building_type][item_def.level - 1].."_off", pos, builder)
        elseif item_def.level == 1 then
            return logistics.remove(pos, builder)
        end
    end
end


-- ################# GATHERING THE AREA WORKED ON #################
minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
    -- This code will be executed whenever a player places a node
    print(placer:get_player_name() .. " placed a " .. newnode.name .. " at " .. minetest.pos_to_string(pos))
end)

minetest.register_on_dignode(function(pos, oldnode, digger)
    -- This code will be executed whenever a player digs a node
    print(digger:get_player_name() .. " dug a " .. oldnode.name .. " at " .. minetest.pos_to_string(pos))
end)


