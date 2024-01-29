print("This is the insta mod at mods/insta/init.lua")

local S = minetest.get_translator("insta")

insta = {
    changed = true,
}

-- #################### INTRO FORM ####################

local function showIntroForm_DE(player)
    local formspec = {
        "formspec_version[4]",
        "size[20,13]",
        "image_button[0.5,0.5;19,12;IntroGraphic.jpg;start;]",
        --"image_button[0.5,13.5;3,1;toEnglish.png;lang;]",
        --"button_exit[16.5,13.5;3,1;start;Los geht's]",
    }

    minetest.show_formspec(player:get_player_name(), "insta:welcomeDE", table.concat(formspec, ""))
end

local function showIntroForm_EN(player)
    local formspec = {
        "formspec_version[4]",
        "size[20,15]",
        "image_button[0.5,0.5;19,12.5;IntroGraphic.jpg;start;]",
        "image_button[0.5,13.5;3,1;toGerman.png;lang;]",
        "button_exit[16.5,13.5;3,1;start;Start Game]",
    }

    minetest.show_formspec(player:get_player_name(), "insta:welcomeEN", table.concat(formspec, ""))
end

minetest.register_on_joinplayer(function(player)
    print("insta:register_on_joinplayer()")
    showIntroForm_DE(player)
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if (formname == "insta:welcomeDE" or formname == "insta:welcomeEN") and fields.start then
        minetest.debug("Game should start now")
        minetest.show_formspec(player:get_player_name(), formname, "")
    elseif formname == "insta:welcomeDE" and fields.lang then
        showIntroForm_EN(player)
    elseif formname == "insta:welcomeEN" and fields.lang then
        showIntroForm_DE(player)
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
function insta.build_residential(pointed_thing, builder)
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
            return logistics.place(city.buildings["residential"][1].."_off", pos, builder)
        end
    end


    -- level is 2 or higher on plain ground only if street is nearby:
    local building_type = "residential"
    local item_def = minetest.registered_items[current.name:sub(1,#"city:residential_n")]
    if current.name:sub(1,#"city:residential") == "city:residential" and item_def.level and item_def.level < 4 then
        print("level is 2 or higher on plain ground only if street is nearby:")
        return logistics.place(city.buildings[building_type][item_def.level + 1].."_off", pos, builder)
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