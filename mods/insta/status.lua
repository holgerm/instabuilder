_G.status = {}

function _G.status.show_info()
    minetest.debug("Hi, here is the ".. minetest.get_current_modname() .. " mod!")
end

dofile(minetest.get_modpath("insta").."/util.lua")









local StatusBar = {}
StatusBar.__index = StatusBar

function StatusBar.new(player, name, goal)
    local self = setmetatable({}, StatusBar)
    self.player = player
    self.name = name
    self.goal = goal
    self.hud_id = nil
    self.hud_elem_type = "statbar"
    self.position = {x=1, y=0}
    self.text = "cost.png"
    self.number = 2
    self.size = {x=64, y=64}
    self.offset = {x=-64-10, y=5}
    return self
end

function StatusBar:show()
    self.player:hud_add({
        hud_elem_type = "image",
        position = {x=1, y=0},
        text = "grey.png",
        offset = {x=-137, y=64+31},
        scale = {x = 5, y = 1},
    })

    self.hud_id = self.player:hud_add({
        hud_elem_type = self.hud_elem_type,
        position = self.position,
        text = self.text,
        number = self.number,
        size = self.size,
        offset = self.offset,
    })

    self.hud_id_bar = self.player:hud_add({
        hud_elem_type = "image",
        position = {x=1, y=0},
        text = "red.png",
        offset = {x=-36, y=64+40},
        scale = {x = 1, y = 1},
    })
    self.hud_id_text = self.player:hud_add({
        hud_elem_type = "text",
        position = {x=1, y=0},
        text = math.floor(self.player:get_meta():get_float(self.name)+0.5) .. " / " .. self.goal,
        number = 0xffffff,
        size = {x=3, y=3+5},
        offset = {x=-90, y=64+5},
        alignment = {x=-1, y=1},
    })
    self.hud_id_icon = self.player:hud_add({
        hud_elem_type = "statbar",
        position = {x=1, y=0},
        text = self.name .. ".png",
        number = 2,
        size = {x=48, y=48+5},
        offset = {x=-64, y=64+7},
    })
end

function StatusBar:add(delta)
    if not delta or delta == 0 then
        return
    end

    local oldVal = self.player:get_meta():get_int(self.name)
    self.player:get_meta():set_int(self.name, oldVal + delta);

    self.player:hud_change(self.hud_id_text, "text", self.player:get_meta():get_int(self.name) ..
        " / " ..self.goal)
    if self.player:get_meta():get_int(self.name) > self.goal then
        -- Change the text color to red
        self.player:hud_change(self.hud_id, "number", 0xFF0000)
        self.player:hud_change(self.hud_id_icon, "text", self.name .. "_red.png")
    else
        -- Change the text color to white
        self.player:hud_change(self.hud_id, "number", 0xFFFFFF)
        self.player:hud_change(self.hud_id_icon, "text", self.name .. ".png")
    end

    self.player:hud_change(self.hud_id_text, "text", math.floor(self.player:get_meta():get_float(self.name)+0.5)..
        " / " .. self.goal)
    self.player:hud_change(self.hud_id_bar, "text", "red.png") -- TODO
    self.player:hud_change(self.hud_id, "text", "cost.png")
end

function StatusBar:reset()
    self.player:get_meta():set_int(self.name, 0)
    self.player:hud_change(self.hud_id_text, "text", math.floor(self.player:get_meta():get_float(self.name)+0.5)..
        " / " .. self.goal)
    self.player:hud_change(self.hud_id_bar, "text",self.name ..  "red.png") -- TODO
    self.player:hud_change(self.hud_id_icon, "text", self.name .. ".png")
end

local StatusManager = {}
local statusManagers = {}

local instance = nil

-- Creates a new instance of StatusManager for a given player
function StatusManager.new(player)
    -- if statusManagers[player:get_player_name()] then
    --     return statusManagers[player:get_player_name()]
    -- end

    -- local sm  = {}
    -- sm.player = player
    -- sm.bars = {}

    -- statusManagers[player:get_player_name()] = sm
    -- return sm
end

--- Adds a status bar for a player.
function StatusManager.addStatusBar(player, name, goal)
    if instance == nil then
        instance = StatusManager.new()
    end

    instance.bars[name] = StatusBar.new(instance.player, name, goal)
    instance.bars[name]:show()
end

--- Resets the status manager.
function StatusManager.reset(player)
    if statusManagers[player:get_player_name()] == nil then
        instance = StatusManager.new()
    end

    for _, bar in pairs(instance.bars) do
        bar:reset()
    end
end

function StatusManager.getStatusBar(player, name)
    if instance == nil then
        instance = StatusManager.new(player)
    end

    return instance.bars[name]
end

_G.status.StatusManager = StatusManager

local hud_id_money
local hud_id_money_icon
local hud_id_population
local hud_id_population_icon

local function reset_state()
    -- for _, player in ipairs(minetest.get_connected_players()) do

    --     player:get_meta():set_int("costs", 0)
    --     player:get_meta():set_int("population", 0)
    --     player:get_meta():set_int("co2", 0)
    --     player:hud_change(hud_id_money, "text", 0 .. " / " .. _G.insta.goal_money)
    --     player:hud_change(hud_id_population, "text", 0 .. " / " .. _G.insta.goal_population)
    --     -- Change the text color to red
    --     player:hud_change(hud_id_population, "number", 0xFF0000)
    --     player:hud_change(hud_id_population_icon, "text", "population_red.png")
    -- end
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
        text = player:get_meta():get_int("costs") .. " / " .. _G.insta.goal_money,
        number = 0xffffff,
        size = {x=3, y=3},
        offset = {x=-90, y=10},
        alignment = {x=-1, y=1},
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

_G.builda.Init_status_hud = init_status_hud



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