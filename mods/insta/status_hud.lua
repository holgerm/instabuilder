_G.status_hud = {}

function _G.status_hud.show_info()
    minetest.debug("Hi, here is the ".. minetest.get_current_modname() .. " mod!")
end

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
        player:hud_change(hud_id_money, "text", 0 .. " / " .. _G.insta.goal_money)
        player:hud_change(hud_id_co2, "text", 0 .. " / " .. _G.insta.goal_co2)
        player:hud_change(hud_id_population, "text", 0 .. " / " .. _G.insta.goal_population)
        -- Change the text color to red
        player:hud_change(hud_id_population, "number", 0xFF0000)
        player:hud_change(hud_id_population_icon, "text", "population_red.png")
    end
end

_G.builda.Reset_state = reset_state

local set_status_hud = function(player)
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
        text = player:get_meta():get_int("costs") .. " / " .. _G.insta.goal_money,
        number = 0xffffff,
        size = {x=3, y=3},
        offset = {x=-90, y=10},
        alignment = {x=-1, y=1},
    })
    --CO2 Count
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
    --CO2 Icon
    hud_id_co2_icon = player:hud_add({
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

_G.builda.set_status_hud = set_status_hud



--returns true if the player can afford.
local AddPlayerCosts = function(player, coins)
    player:get_meta():set_int("costs", player:get_meta():get_int("costs") + coins);
    if player:get_meta():get_int("costs") < 0 then
        player:get_meta():set_int("costs", 0)
        return false
    end
    if hud_id_money then
        player:hud_change(hud_id_money, "text", player:get_meta():get_int("costs") .. " / " .. _G.insta.goal_money)
        if player:get_meta():get_int("costs") > _G.insta.goal_money then
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


local AddPlayerCO2 = function(player, coins)
    player:get_meta():set_int("co2", player:get_meta():get_int("co2") + coins);
    if hud_id_co2 then
        player:hud_change(hud_id_co2, "text", player:get_meta():get_int("co2") ..
            " / " .. _G.insta.goal_co2)
        if player:get_meta():get_int("co2") > _G.insta.goal_co2 then
            -- Change the text color to red
            player:hud_change(hud_id_co2, "number", 0xFF0000)
            player:hud_change(hud_id_co2_icon, "text", "co2_red.png")
        else
            -- Change the text color to white
            player:hud_change(hud_id_co2, "number", 0xFFFFFF)
            player:hud_change(hud_id_co2_icon, "text", "co2.png")
        end
    end
    return true
end

_G.builda.AddPlayerCO2 = AddPlayerCO2