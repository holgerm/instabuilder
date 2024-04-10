_G.util = {}

function _G.status.show_info()
    minetest.debug("Hi, here is the ".. minetest.get_current_modname() .. " mod!")
end

local function print_table(t, maxDepth, ind)
    if not t then
        print("nil")
        return
    end

    ind = ind or 0
    maxDepth = maxDepth or 5
    if maxDepth == 0 then
        return
    end

    local indent = ''
    for _ = 0, ind do
        indent = indent .. '  '
    end
    for key, value in pairs(t) do
        if type(value) == "table" then
            print(indent .. key .. ":")
            print_table(value, maxDepth - 1, ind + 1)
        else
            print(indent .. key .. ": " .. tostring(value) .. " (type: " .. type(value) .. ")")
        end
    end
end

_G.util.PrintTable = print_table