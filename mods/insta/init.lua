local S = minetest.get_translator("insta")

local insta = {
    changed = true,
}

_G.insta = insta

-- #################### LIFE CYCLE STUFF ####################

local build_time = 300 -- 5 minutes

local goal_costs = 17000 -- less than is better
local goal_co2 = 1000 -- less than is better
local goal_population = 1000 -- more than is better
_G.insta.goal_costs = goal_costs
_G.insta.goal_co2 = goal_co2
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

local function build(building_type, max_level, pointed_thing, player)
    local pos = pointed_thing.under
    pos.y = 9
    local current = minetest.get_node(pos)

    -- level 1 on plain ground only if street is nearby:
    if current.name == "air" then
        local road = logistics.node_near(pos, player, "street")
        if not road then
            return false
        else
            if logistics.place(city.buildings[building_type][1].."_off", pos, player) then
                _G.builda.AddPoints4Green(player, 0, 1)
            end
        end
    end

    local item_def = minetest.registered_items[current.name:sub(1,#("city:"..building_type.."_n"))]
    if current.name:sub(1,#("city:"..building_type)) == "city:"..building_type and
        item_def.level and item_def.level < max_level then
        if logistics.place(city.buildings[building_type][item_def.level + 1].."_off", pos, player) then
            _G.builda.AddPoints4Green(player, item_def.level, item_def.level + 1)
        end
    end
end

local function unbuild(building_type, pointed_thing, player)
    local pos = pointed_thing.under
    pos.y = 9
    local current = minetest.get_node(pos)

    -- level 1 on plain ground only if street is nearby:
    if current.name == "air" then
        return false
    end

    -- level is 2 or higher on plain ground only if street is nearby:
    local item_def = minetest.registered_items[current.name:sub(1,#("city:"..building_type.."_n"))]
    if current.name:sub(1,#("city:"..building_type)) == "city:"..building_type and item_def.level then
        if item_def.level > 1 then
            if logistics.place(city.buildings[building_type][item_def.level - 1].."_off", pos, player) then
                _G.builda.AddPoints4Green(player, item_def.level, item_def.level - 1)
            end
        elseif item_def.level == 1 then
            if logistics.remove(pos, player) then
                _G.builda.AddPoints4Green(player, item_def.level, 0)
            end
        end
    end
end

function insta.build_green(pointed_thing, builder)
    build("green", 2, pointed_thing, builder)
end

function insta.build_residential_concrete(pointed_thing, builder)
    build("residential_concrete", 4, pointed_thing, builder)
end

function insta.unbuild_residential_concrete(pointed_thing, builder)
    unbuild("residential_concrete", pointed_thing, builder)
end

function insta.build_residential_brick(pointed_thing, builder)
    build("residential_brick", 4, pointed_thing, builder)
end


function insta.unbuild_residential_brick(pointed_thing, builder)
    unbuild("residential_brick", pointed_thing, builder)
end


function insta.build_residential_wood(pointed_thing, builder)
    build("residential_wood", 2, pointed_thing, builder)
end


function insta.unbuild_residential_wood(pointed_thing, builder)
    unbuild("residential_wood", pointed_thing, builder)
end