_G.status = {}

local function show_info()
    minetest.debug("Hi, here is the ".. minetest.get_current_modname() .. " mod!")
end

_G.status.ShowInfo = show_info

dofile(minetest.get_modpath("insta").."/util.lua")

local goal_costs = 17000 -- less than is better
local goal_co2 = 1000 -- less than is better
local goal_population = 1000 -- more than is better

local hud_id_money
local hud_id_money_icon
local hud_id_co2
local hud_id_co2_icon
local hud_id_population
local hud_id_population_bar
local bar_length = 15
local population_bar_value_per_unit = goal_population / bar_length

local function reset_state()
    for _, player in ipairs(minetest.get_connected_players()) do

        player:get_meta():set_int("costs", 0)
        player:get_meta():set_int("population", 0)
        player:get_meta():set_int("co2", 0)
        player:hud_change(hud_id_money, "text", 0 .. " / " .. goal_costs)
        player:hud_change(hud_id_population, "text", 0 .. " / " .. goal_population)
        -- Change the text color to red
        --player:hud_change(hud_id_co2, "number", 0xFF0000)
        player:hud_change(hud_id_co2_icon, "text", "co2.png")
        player:hud_change(hud_id_co2, "text", 0 .. " / " .. goal_co2)
        -- Change the text color to red
        player:hud_change(hud_id_population, "number", 0xFF0000)
    end
end

_G.builda.Reset_state = reset_state

_G.builda.Init_status_hud = function(player)
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
        text = player:get_meta():get_int("costs") .. " / " .. goal_costs,
        number = 0xffffff,
        size = {x=3, y=3},
        offset = {x=-90, y=10},
        alignment = {x=-1, y=1},
    })
    -- Co2 Count
    hud_id_co2 = player:hud_add({
        name = "co2",
        hud_elem_type = "text",
        position = {x=1, y=0},
        text = math.floor(player:get_meta():get_float("co2")+0.5) .. " / " .. goal_co2,
        number = 0xffffff,
        size = {x=3, y=3+5},
        offset = {x=-90, y=64+5},
        alignment = {x=-1, y=1},
    })
    -- Co2 Icon
    hud_id_co2_icon = player:hud_add({
        hud_elem_type = "statbar",
        position = {x=1, y=0},
        text = "co2.png",
        number = 2,
        size = {x=48, y=48+5},
        offset = {x=-64, y=64+7},
    })
    -- Population Bar
    local populationY = 64+7+64
    player:hud_add({
        hud_elem_type = "statbar",
        position = {x=1, y=0},
        text = "population.png",
        number = 2,
        size = {x=48, y=48+5},
        offset = {x=-64, y=populationY},
    })
    -- background of the population bar
    player:hud_add({
        hud_elem_type = "statbar",
        position = {x=1, y=0},
        text = "green.png",
        number = bar_length,
        size = {x=48, y=48+5},
        offset = {x=5-(30 * bar_length), y=populationY},
    })
    hud_id_population_bar = player:hud_add({
        hud_elem_type = "statbar",
        position = {x=1, y=0},
        text = "red.png",
        number = bar_length,
        size = {x=48, y=48+5},
        offset = {x=5-(30 * bar_length), y=populationY},
    })
    -- Population Count
    hud_id_population = player:hud_add({
        name = "population",
        hud_elem_type = "text",
        position = {x=1, y=0},
        text = math.floor(player:get_meta():get_float("population")+0.5) .. " / " .. goal_population,
        number = 0xffffff,
        size = {x=3, y=3+5},
        offset = {x=-90, y=populationY},
        alignment = {x=-1, y=1},
    })
end


--returns true if the player can afford.
local AddPlayerCosts = function(player, coins)
    player:get_meta():set_int("costs", player:get_meta():get_int("costs") + coins);
    if player:get_meta():get_int("costs") < 0 then
        player:get_meta():set_int("costs", 0)
        return false
    end
    if hud_id_money then
        player:hud_change(hud_id_money, "text", player:get_meta():get_int("costs") .. " / " .. goal_costs)
        if player:get_meta():get_int("costs") > goal_costs then
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
            " / " .. goal_co2)
        if player:get_meta():get_int("co2") > goal_co2 then
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


local function show_bar_value(player, hud_num_id, hud_bar_id, value_name, goal)
    local curValue = player:get_meta():get_int(value_name)
    if curValue < 0 then
        player:get_meta():set_int(value_name, 0)
        curValue = 0
    end
    if hud_num_id then
        player:hud_change(hud_num_id, "text", curValue .. 
            " / " .. goal)
        local value_missing = goal - curValue
        if (value_missing < 0) then
            value_missing = 0
        end
        local curNumber = value_missing / population_bar_value_per_unit
        if curNumber < 1 and value_missing > 0 then
            curNumber = 1
        end
        if curValue == 0 then
            curNumber = bar_length -- fill completely if no population
        end
        player:hud_change(hud_bar_id, "number", curNumber)
    end
    return true
end

_G.builda.AddPlayerPopulation = function(player, delta)
    player:get_meta():set_int("population", player:get_meta():get_int("population") + delta);
    show_bar_value(player, hud_id_population, hud_id_population_bar, "population", goal_population)
end

