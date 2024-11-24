_G.status = {}

local function show_info()
    minetest.debug("Hi, here is the ".. minetest.get_current_modname() .. " mod!")
end

_G.status.ShowInfo = show_info

dofile(minetest.get_modpath("insta").."/util.lua")

local costs = {
    green = { 20, 30, 50,},
    residential_concrete = { 300, 600, 1000, 2000,},
    residential_brick = { 350, 700, 1200, 2500,},
    residential_wood = { 400, 800, },
}

local co2 = {
    green = { -80, -140, -250,},
    residential_concrete = { 100, 200, 400, 800, },
    residential_brick = { 60, 120, 240, 480, },
    residential_wood = { 20, 40, },
}

local population = {
    green = { 0, 0, 0, },
    residential_concrete = { 4, 15, 40, 160, },
    residential_brick = { 4, 12, 25, 60, },
    residential_wood = { 6, 20, },
}



_G.status.goal_costs = 17000 -- should be less
_G.status.goal_co2 = 1000 -- should be less
_G.status.goal_population = 1000 -- more

_G.status.hasBuilt = false
_G.status.hasLeveledUp = false

-- local hud_id_costs
local hud_id_costs_bar
-- local hud_id_co2
local hud_id_co2_bar
-- local hud_id_population
local hud_id_population_bar
local bar_length = 15
local bar_value_per_unit = {
    costs = _G.status.goal_costs / bar_length,
    co2 = _G.status.goal_co2 / bar_length,
    population = _G.status.goal_population / bar_length,
}

_G.builda.Init_status_hud = function(player)
    local costY = 7
    -- Cost Icon
    player:hud_add({
        hud_elem_type = "statbar",
        position = {x=1, y=0},
        text = "cost.png",
        number = 2,
        size = {x=64, y=64},
        offset = {x=-64-10, y=5},
    })
    -- background of the cost bar
    player:hud_add({
        hud_elem_type = "statbar",
        position = {x=1, y=0},
        text = "red.png",
        number = bar_length,
        size = {x=48, y=48+5},
        offset = {x=5-(30 * bar_length), y=costY},
    })
    -- cost value bar
    hud_id_costs_bar = player:hud_add({
        hud_elem_type = "statbar",
        position = {x=1, y=0},
        text = "green.png",
        number = bar_length,
        size = {x=48, y=48+5},
        offset = {x=5-(30 * bar_length), y=costY},
    })
    -- -- Cost Count
    -- hud_id_costs = player:hud_add({
    --     name = "coins",
    --     hud_elem_type = "text",
    --     position = {x=1, y=0},
    --     text = player:get_meta():get_int("costs") .. " / " .. _G.status.goal_costs,
    --     number = 0xffffff,
    --     size = {x=3, y=3},
    --     offset = {x=-90, y=costY},
    --     alignment = {x=-1, y=1},
    -- })

    -- Co2 Icon
    local co2Y = 64+7
    player:hud_add({
        hud_elem_type = "statbar",
        position = {x=1, y=0},
        text = "co2.png",
        number = 2,
        size = {x=48, y=48+5},
        offset = {x=-64, y=co2Y},
    })
    -- background of the Co2 bar
    player:hud_add({
        hud_elem_type = "statbar",
        position = {x=1, y=0},
        text = "red.png",
        number = bar_length,
        size = {x=48, y=48+5},
        offset = {x=5-(30 * bar_length), y=co2Y},
    })
    -- Co2 value bar
    hud_id_co2_bar = player:hud_add({
        hud_elem_type = "statbar",
        position = {x=1, y=0},
        text = "green.png",
        number = bar_length,
        size = {x=48, y=48+5},
        offset = {x=5-(30 * bar_length), y=co2Y},
    })
    -- Co2 Count
    -- hud_id_co2 = player:hud_add({
    --     name = "co2",
    --     hud_elem_type = "text",
    --     position = {x=1, y=0},
    --     text = math.floor(player:get_meta():get_float("co2")+0.5) .. " / " .. _G.status.goal_co2,
    --     number = 0xffffff,
    --     size = {x=3, y=3+5},
    --     offset = {x=-90, y=co2Y},
    --     alignment = {x=-1, y=1},
    -- })

    -- Population Icon
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
    -- population value bar
    hud_id_population_bar = player:hud_add({
        hud_elem_type = "statbar",
        position = {x=1, y=0},
        text = "red.png",
        number = bar_length,
        size = {x=48, y=48+5},
        offset = {x=5-(30 * bar_length), y=populationY},
    })
    -- -- Population Count
    -- hud_id_population = player:hud_add({
    --     name = "population",
    --     hud_elem_type = "text",
    --     position = {x=1, y=0},
    --     text = math.floor(player:get_meta():get_float("population")+0.5) .. " / " .. _G.status.goal_population,
    --     number = 0xffffff,
    --     size = {x=3, y=3+5},
    --     offset = {x=-90, y=populationY},
    --     alignment = {x=-1, y=1},
    -- })
end




local function show_bar_value(player, hud_bar_id, value_name, goal)
    local curValue = player:get_meta():get_int(value_name)
    if curValue < 0 then
        player:get_meta():set_int(value_name, 0)
        curValue = 0
    end
 --   if hud_num_id then
    -- player:hud_change(hud_num_id, "text", curValue ..
    --     " / " .. goal)
    local value_missing = goal - curValue
    if (value_missing < 0) then
        value_missing = 0
    end
    local curNumber = math.floor(value_missing / bar_value_per_unit[value_name])
    if curNumber < 1 and value_missing > 0 then
        curNumber = 1
    end
    if curValue < bar_value_per_unit[value_name] / 2 then
        curNumber = bar_length -- fill completely if value is zero
    end
    player:hud_change(hud_bar_id, "number", curNumber)
 --   end
    return true
end

--returns true if the player can afford.
local AddPlayerCosts = function(player, coins)
    player:get_meta():set_int("costs", player:get_meta():get_int("costs") + coins);
    show_bar_value(player, hud_id_costs_bar, "costs", _G.status.goal_costs)

    -- if player:get_meta():get_int("costs") < 0 then
    --     player:get_meta():set_int("costs", 0)
    --     return false
    -- end
    -- if hud_id_costs then
    --     player:hud_change(hud_id_costs, "text", player:get_meta():get_int("costs") .. " / " .. _G.status.goal_costs)
    --     if player:get_meta():get_int("costs") > _G.status.goal_costs then
    --         -- Change the text color to red
    --         player:hud_change(hud_id_costs, "number", 0xFF0000)
    --         player:hud_change(hud_id_costs_icon, "text", "cost_red.png")

    --     else
    --         -- Change the text color to white
    --         player:hud_change(hud_id_costs, "number", 0xFFFFFF)
    --         player:hud_change(hud_id_costs_icon, "text", "cost.png")
    --     end
    -- end

    return true
end

_G.builda.AddPlayerCosts = AddPlayerCosts

local addPlayerCo2 = function(player, delta)
    player:get_meta():set_int("co2", player:get_meta():get_int("co2") + delta);
    show_bar_value(player, hud_id_co2_bar, "co2", _G.status.goal_co2)
end

_G.status.AddPlayerCo2 = addPlayerCo2

local addPlayerPopulation = function(player, delta)
    player:get_meta():set_int("population", player:get_meta():get_int("population") + delta);
    show_bar_value(player, hud_id_population_bar, "population", _G.status.goal_population)
end

_G.status.AddPoints = function(user, building_type, from_level, to_level)
    AddPlayerCosts(user, (costs[building_type][to_level] or 0) - (costs[building_type][from_level] or 0))
    addPlayerCo2(user, (co2[building_type][to_level] or 0) - (co2[building_type][from_level] or 0))
    addPlayerPopulation(user, (population[building_type][to_level] or 0) - (population[building_type][from_level] or 0))
end

_G.builda.Reset_state = function()
    for _, player in ipairs(minetest.get_connected_players()) do
        player:get_meta():set_int("costs", 0)
        show_bar_value(player, hud_id_costs_bar, "costs", _G.status.goal_population)

        player:get_meta():set_int("population", 0)
        show_bar_value(player, hud_id_population_bar, "population", _G.status.goal_population)
        player:get_meta():set_int("co2", 0)
        show_bar_value(player, hud_id_co2_bar, "costs", _G.status.goal_population)
    end
end

