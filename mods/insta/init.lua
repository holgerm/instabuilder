local S = minetest.get_translator("insta")

local insta = {
    changed = true,
}

_G.insta = insta

-- #################### LIFE CYCLE STUFF ####################

local build_time = 120 -- 7 minutes

local goal_money = 300 -- less than is better
_G.insta.goal_money = goal_money
local goal_co2 = 10000 -- less than is better
_G.insta.goal_co2 = goal_co2
local goal_population = 1000 -- more than is better
_G.insta.goal_population = goal_population

local forms = dofile(minetest.get_modpath("insta").."/forms.lua")

function insta.start_countdown()
    local players = minetest.get_connected_players()

    local function on_end(player)
        forms.showResultHUD(player)
    end

    local function on_warn(_player)
        _G.countdown.set_color(0xFF22AA) -- set text to red
    end

    _G.countdown.set_color(0xFFFFFF) -- set text to white
    _G.countdown.start(players[1], "Verbleibende Zeit: ",build_time, on_end, 60, on_warn)
end

minetest.register_on_joinplayer(function(player)
    forms.showIntroHUD(player)
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


function insta.build_green(pointed_thing, builder)
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
            print("No road")
            return false
        else
            if logistics.place(city.buildings["green"][1].."_off", pos, builder) then
                _G.builda.AddPoints4Green(builder, 0, 1)
            end
        end
    end

    local building_type = "green"
    local item_def = minetest.registered_items[current.name:sub(1,#"city:green_n")]
    if current.name:sub(1,#"city:green") == "city:green" and item_def.level and item_def.level < 2 then
        if logistics.place(city.buildings[building_type][item_def.level + 1].."_off", pos, builder) then
            _G.builda.AddPoints4Green(builder, item_def.level, item_def.level + 1)
        end
    end
end

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
            print("No road")
            return false
        else
            if logistics.place(city.buildings["residential_concrete"][1].."_off", pos, builder) then
                _G.builda.AddPoints4ResidentialConcrete(builder, 0, 1)
            end
        end
    end


    -- level is 2 or higher on plain ground only if street is nearby:
    local building_type = "residential_concrete"
    local item_def = minetest.registered_items[current.name:sub(1,#"city:residential_concrete_n")]
    if current.name:sub(1,#"city:residential_concrete") == "city:residential_concrete" and item_def.level and item_def.level < 4 then
        if logistics.place(city.buildings[building_type][item_def.level + 1].."_off", pos, builder) then
            _G.builda.AddPoints4ResidentialConcrete(builder, item_def.level, item_def.level + 1)
        end
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
            if logistics.place(city.buildings[building_type][item_def.level - 1].."_off", pos, builder) then
                _G.builda.AddPoints4ResidentialConcrete(builder, item_def.level, item_def.level - 1)
            end
        elseif item_def.level == 1 then
            if logistics.remove(pos, builder) then
                _G.builda.AddPoints4ResidentialConcrete(builder, item_def.level, 0)
            end
        end
    end
end

function insta.build_residential_brick(pointed_thing, builder)
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
            return logistics.place(city.buildings["residential_brick"][1].."_off", pos, builder)
        end
    end
    -- level is 2 or higher on plain ground only if street is nearby:
    local building_type = "residential_brick"
    local item_def = minetest.registered_items[current.name:sub(1,#"city:residential_brick_n")]
    if current.name:sub(1,#"city:residential_brick") == "city:residential_brick" and item_def.level and item_def.level < 4 then
        return logistics.place(city.buildings[building_type][item_def.level + 1].."_off", pos, builder)
    end
end


function insta.unbuild_residential_brick(pointed_thing, builder)
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
    local building_type = "residential_brick"
    local item_def = minetest.registered_items[current.name:sub(1,#"city:residential_brick_n")]
    if current.name:sub(1,#"city:residential_brick") == "city:residential_brick" and item_def.level then
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


