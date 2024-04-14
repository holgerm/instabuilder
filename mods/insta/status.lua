_G.status = {}

local function show_info()
    minetest.debug("Hi, here is the ".. minetest.get_current_modname() .. " mod!")
end

_G.status.ShowInfo = show_info

dofile(minetest.get_modpath("insta").."/util.lua")








local status_bars = {}
_G.status.Bars = status_bars

local function show(bar)
    bar.player:hud_add({
        hud_elem_type = "image",
        position = {x=1, y=0},
        text = "grey.png",
        offset = {x=-137, y=64+31},
        scale = {x = 5, y = 1},
    })

    bar.hud_id = bar.player:hud_add({
        hud_elem_type = bar.hud_elem_type,
        position = bar.position,
        text = bar.text,
        number = bar.number,
        size = bar.size,
        offset = bar.offset,
    })

    bar.hud_id_bar = bar.player:hud_add({
        hud_elem_type = "image",
        position = {x=1, y=0},
        text = "red.png",
        offset = {x=-36, y=64+40},
        scale = {x = 1, y = 1},
    })
    bar.hud_id_text = bar.player:hud_add({
        hud_elem_type = "text",
        position = {x=1, y=0},
        text = math.floor(bar.player:get_meta():get_float(bar.name)+0.5) .. " / " .. bar.goal,
        number = 0xffffff,
        size = {x=3, y=3+5},
        offset = {x=-90, y=64+5},
        alignment = {x=-1, y=1},
    })
    bar.hud_id_icon = bar.player:hud_add({
        hud_elem_type = "statbar",
        position = {x=1, y=0},
        text = bar.name .. ".png",
        number = 2,
        size = {x=48, y=48+5},
        offset = {x=-64, y=64+7},
    })
end

_G.status.Show = show

function _G.status.addStatusBar(player, name, goal)
    local sb = {}
    sb.player = player
    sb.name = name
    sb.goal = goal
    sb.hud_id = nil
    sb.hud_elem_type = "statbar"
    sb.position = {x=1, y=0}
    sb.text = "cost.png"
    sb.number = 2
    sb.size = {x=64, y=64}
    sb.offset = {x=-64-10, y=5}
    status_bars[player:get_player_name().."_"..name] = sb
    show(sb)
end

function _G.status.getBar(player, name)
    return status_bars[player:get_player_name().."_"..name]
end

local function add(bar, delta)
    if not delta or delta == 0 then
        return
    end

    local oldVal = bar.player:get_meta():get_int(bar.name)
    bar.player:get_meta():set_int(bar.name, oldVal + delta);

    bar.player:hud_change(bar.hud_id_text, "text", bar.player:get_meta():get_int(bar.name) ..
        " / " ..bar.goal)
    if bar.player:get_meta():get_int(bar.name) > bar.goal then
        -- Change the text color to red
        bar.player:hud_change(bar.hud_id, "number", 0xFF0000)
        bar.player:hud_change(bar.hud_id_icon, "text", bar.name .. "_red.png")
    else
        -- Change the text color to white
        bar.player:hud_change(bar.hud_id, "number", 0xFFFFFF)
        bar.player:hud_change(bar.hud_id_icon, "text", bar.name .. ".png")
    end

    bar.player:hud_change(bar.hud_id_text, "text", math.floor(bar.player:get_meta():get_float(bar.name)+0.5)..
        " / " .. bar.goal)
    bar.player:hud_change(bar.hud_id_bar, "text", "red.png") -- TODO
    bar.player:hud_change(bar.hud_id, "text", "cost.png")
end

_G.status.Add = add

local function reset(bar)
    bar.player:get_meta():set_int(bar.name, 0)
    bar.player:hud_change(bar.hud_id_text, "text", math.floor(bar.player:get_meta():get_float(bar.name)+0.5)..
        " / " .. bar.goal)
    bar.player:hud_change(bar.hud_id_bar, "text",bar.name ..  "red.png") -- TODO
    bar.player:hud_change(bar.hud_id_icon, "text", bar.name .. ".png")
end

_G.status.Reset = reset

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
        player:hud_change(hud_id_money, "text", 0 .. " / " .. _G.insta.goal_costs)
        player:hud_change(hud_id_population, "text", 0 .. " / " .. _G.insta.goal_population)
        -- Change the text color to red
        --player:hud_change(hud_id_co2, "number", 0xFF0000)
        player:hud_change(hud_id_co2_icon, "text", "co2.png")
        player:hud_change(hud_id_co2, "text", 0 .. " / " .. _G.insta.goal_co2)
        -- Change the text color to red
        player:hud_change(hud_id_population, "number", 0xFF0000)
        player:hud_change(hud_id_population_icon, "text", "population_red.png")
    end
end

_G.builda.Reset_state = reset_state

local init_status_hud = function(player)
    -- Cost Icon
    hud_id_money_icon = player:hud_add({
        hud_elem_type = "statbar",
        position = {x=1, y=0},
        text = "cost.png",
        number = 2,
        size = {x=64, y=64},
        offset = {x=-64-10, y=5},
    })
    -- Cost Count
    hud_id_money = player:hud_add({
        name = "coins",
        hud_elem_type = "text",
        position = {x=1, y=0},
        text = player:get_meta():get_int("costs") .. " / " .. _G.insta.goal_costs,
        number = 0xffffff,
        size = {x=3, y=3},
        offset = {x=-90, y=10},
        alignment = {x=-1, y=1},
    })
    -- Population Count
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
    -- Population Icon
    hud_id_co2_icon = player:hud_add({
        hud_elem_type = "statbar",
        position = {x=1, y=0},
        text = "co2.png",
        number = 2,
        size = {x=48, y=48+5},
        offset = {x=-64, y=64+7},
    })
    --sb.size = {x=64, y=64}
    --sb.offset = {x=-64-10, y=5}
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
end

_G.builda.Init_status_hud = init_status_hud



--returns true if the player can afford.
local AddPlayerCosts = function(player, coins)
    player:get_meta():set_int("costs", player:get_meta():get_int("costs") + coins);
    if player:get_meta():get_int("costs") < 0 then
        player:get_meta():set_int("costs", 0)
        return false
    end
    if hud_id_money then
        player:hud_change(hud_id_money, "text", player:get_meta():get_int("costs") .. " / " .. _G.insta.goal_costs)
        if player:get_meta():get_int("costs") > _G.insta.goal_costs then
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

_G.builda.AddPlayerCosts = AddPlayerCosts


local AddPlayerCo2 = function(player, coins)
    player:get_meta():set_int("co2", player:get_meta():get_int("co2") + coins);
    if player:get_meta():get_int("co2") < 0 then
        player:get_meta():set_int("co2", 0)
        -- Change the text color to red
        player:hud_change(hud_id_co2, "number", 0xFF0000)
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
            player:hud_change(hud_id_co2, "number", 0xFFFFFF)
            player:hud_change(hud_id_co2_icon, "text", "co2.png")
        end
    end
    return true
end

_G.builda.AddPlayerCo2 = AddPlayerCo2


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

_G.builda.AddPlayerPopulation = AddPlayerPopulation