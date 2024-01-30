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
    minetest.debug("update_area: " .. minetest.pos_to_string(pos))
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
    minetest.debug("size: " .. tostring(size)..
        "  x: "..(x_max - x_min + 1).." ("..x_min..", "..x_max..")"..
        "  y: "..(y_max - y_min + 1).." ("..y_min..", "..y_max..")"..
        "  z: "..(z_max - z_min + 1).." ("..z_min..", "..z_max..")")
end

function _G.worksaver.save_area_to_file()
    local pos1 = {x = x_min, y = y_min, z = z_min}
    local pos2 = {x = x_max, y = y_max, z = z_max}
    local modpath = minetest.get_modpath("worksaver")
    local date = os.date("%Y-%m-%d_%H-%M-%S")
    local filename = date .. ".mts"
    local filepath = modpath .. "/schematics/" .. filename
    minetest.create_schematic(pos1, pos2, nil, filepath)
    minetest.debug("Area saved to file: " .. filename .. " from " ..
        minetest.pos_to_string(pos1) .. " to " .. minetest.pos_to_string(pos2))
end

minetest.register_chatcommand("savearea", {
    description = "Save the specified area to a file",
    func = function(name, param)
        _G.worksaver.save_area_to_file()
        return true, "Area saved to file."
    end,
})

function _G.worksaver.load_area_from_file()
    local schematic_path = minetest.get_modpath("worksaver") .. "/schematics/2024-01-15_11-48-10.mts"
    local schematic = minetest.read_schematic(schematic_path, "mts")
    local pos = minetest.get_player_by_name("singleplayer"):get_pos()
    minetest.place_schematic(pos, schematic)
end

minetest.register_chatcommand("loadarea", {
    description = "Loads an area from a schematic file and places it at the given position",
    func = function(name, param)
        _G.worksaver.load_area_from_file()
        return true, "Area loaded from file."
    end,
})



--- ####### TEST HTTP #######

local http = minetest.request_http_api()
if not http then
    minetest.debug("HTTP not supported")
else
    minetest.debug("HTTP supported")
end

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
