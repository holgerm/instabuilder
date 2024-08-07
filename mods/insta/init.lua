local S = minetest.get_translator("insta")

local insta = {
    changed = true,
}

_G.insta = insta

-- #################### LIFE CYCLE STUFF ####################

local build_time = 300 -- 5 minutes

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

function _G.insta.build(building_type, max_level, pointed_thing, player)
    local pos = pointed_thing.under
    pos.y = 9
    local current = minetest.get_node(pos)

    -- level 1 on plain ground only if street is nearby:
    if current.name == "air" then
        local road = logistics.node_near(pos, player, "street")
        if not road then
            _G.forms.ShowTipp(player, "streets")
            return false
        else
            if logistics.place(city.buildings[building_type][1].."_off", pos, player) then
                _G.status.AddPoints(player, building_type, 0, 1)
                _G.status.hasBuilt = true -- for tipps
                minetest.after(_G.forms.help.level_up.after or 20, function()
                    if _G.status.hasBuilt and not _G.status.hasLeveledUp then
                        _G.forms.ShowTipp(player, "level_up")
                    end
                end)
            end
        end
    end

    local item_def = minetest.registered_items[current.name:sub(1,#("city:"..building_type.."_n"))]
    if current.name:sub(1,#("city:"..building_type)) == "city:"..building_type and
        item_def.level and item_def.level < max_level then
        if logistics.place(city.buildings[building_type][item_def.level + 1].."_off", pos, player) then
            _G.status.AddPoints(player, building_type, item_def.level, item_def.level + 1)
            _G.status.hasLeveledUp = true -- for tipps
        end
    end
end

function _G.insta.unbuild(building_type, pointed_thing, player)
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
                _G.status.AddPoints(player, building_type, item_def.level, item_def.level - 1)
            end
        elseif item_def.level == 1 then
            if logistics.remove(pos, player) then
                _G.status.AddPoints(player, building_type, item_def.level, 0)
            end
        end
    end
end
