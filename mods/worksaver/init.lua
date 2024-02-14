_G.worksaver = {}

function _G.worksaver.show_info()
    minetest.debug("Hi, here is the ".. minetest.get_current_modname() .. " mod!")
end

local x_min
local x_max
local y_min
local y_max
local z_min
local z_max

function _G.worksaver.update_area(pos)
    if x_min == nil then
        x_min = pos.x
        x_max = pos.x
        y_min = pos.y
        y_max = pos.y
        z_min = pos.z
        z_max = pos.z
    end
    if pos.x < x_min then
        x_min = pos.x
    end
    if pos.x > x_max then
        x_max = pos.x
    end
    if pos.y < y_min then
        y_min = pos.y
    end
    if pos.y > y_max then
        y_max = pos.y
    end
    if pos.z < z_min then
        z_min = pos.z
    end
    if pos.z > z_max then
        z_max = pos.z
    end
end

function _G.worksaver.print_area()
    local size = 0
    if x_max ~= nil then
        size = (x_max - x_min + 1) * (y_max - y_min + 1) * (z_max - z_min + 1)
    end
end

function _G.worksaver.save_area_to_file(min_pos, max_pos)
    local pos1 = min_pos or {x = x_min, y = y_min, z = z_min}
    local pos2 = max_pos or {x = x_max, y = y_max, z = z_max}
    local modpath = minetest.get_modpath("worksaver")
    local date = os.date("%Y-%m-%d_%H-%M-%S")
    local filename = ""
    if min_pos then
        filename = min_pos.x .. "_" .. min_pos.z .. ".mts"
    else
        filename = date .. ".mts"
    end
    local filepath = modpath .. "/schematics/" .. filename
    minetest.create_schematic(pos1, pos2, nil, filepath)
    -- minetest.debug("Area saved to file: " .. filename .. " from " ..
    --     minetest.pos_to_string(pos1) .. " to " .. minetest.pos_to_string(pos2))
end

minetest.register_chatcommand("savearea", {
    description = "Save the specified area to a file",
    func = function(name, radius)
        if radius and radius ~= "" then
            local player = minetest.get_player_by_name(name)
            if player then
                local pos = player:get_pos()
                if pos then
                    local min_pos = {x = math.floor(pos.x + 0.5 - radius), y = 9, z = math.floor(pos.z + 0.5 - radius)}
                    local max_pos = {x = math.floor(pos.x + 0.5 + radius), y = 9, z = math.floor(pos.z + 0.5 + radius)}
                    _G.worksaver.save_area_to_file(min_pos, max_pos)
                else
                    return false, "No player position obtained."
                end
            else
                return false, "Player not found."
            end
        else
            -- The player did not use a parameter.
            _G.worksaver.save_area_to_file()
            return true, "Worked area saved to file."
        end
    end
})

local function split_string(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

local function reset_world()
    local x_my = -135
    local z_my = -56
    local radius = 50
    _G.worksaver.load_area_from_file(tostring(x_my).."_"..tostring(z_my)) -- manually saved world "Startwelt"
    _G.builda.Reset_state()
    local player = minetest.get_connected_players()[1]
    player:set_pos({x = x_my + radius, y = 12, z = z_my + radius - 9})
    player:set_look_horizontal(0)
    player:set_look_vertical((math.pi)/7)
end

_G.worksaver.Reset_world = reset_world


function _G.worksaver.load_area_from_file(filename)
    local xz_coords = split_string(filename, "_")
    local x_min = tonumber(xz_coords[1])
    local z_min = tonumber(xz_coords[2])
    local schematic_path = minetest.get_modpath("worksaver") .. "/schematics/"..filename..".mts"
    local schematic = minetest.read_schematic(schematic_path, "mts")
    local pos = {x = x_min, y = 9, z = z_min}
    minetest.place_schematic(pos, schematic)
end

minetest.register_chatcommand("loadarea", {
    description = "Loads an area from a schematic file and places it at the given position",
    func = function(name, filename)
        if filename then
            _G.worksaver.load_area_from_file(filename)
            return true, "Area loaded from file."
        else
            return false, "No filename given to load from"
        end
    end,
})



--- ####### TEST HTTP #######

local http = minetest.request_http_api()

local function testhttp()
    if not http then
        minetest.debug("HTTP rather not supported")
        return
    else
        minetest.debug("HTTP still supported")
    end
    local url = "https://opensoftwork.de/" -- "http://localhost:8080"
    local data = "test"
    http.fetch({
        url = url,
        post_data = data,
    }, function(response)
        if response.succeeded then
            minetest.debug("HTTP request succeeded")
            minetest.debug("Response code: " .. response.code)
            minetest.debug("Response data: " .. response.data)
        else
            minetest.debug("HTTP request failed: " .. response.code)
        end
    end)
end

minetest.register_chatcommand("http", {
    description = "Save the specified area to a file",
    func = function(name, param)
        testhttp()
        return true, "HTTP request sent."
    end,
})
