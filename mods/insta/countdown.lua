_G.countdown = {}

function _G.countdown.show_info()
    minetest.debug("Hi, here is the ".. minetest.get_current_modname() .. " mod!")
end

local function get_time_text(timer)
    local minutes = math.floor(timer / 60)
    local seconds = timer % 60
    return string.format(" %02d:%02d", minutes, seconds)
end

local color = 0xFFFFFF -- white is default color for the coutdown text

function _G.countdown.set_color(new_color)
    color = new_color
end

function _G.countdown.start(player, title, time, on_end, warn_time, on_warn)
    warn_time = warn_time or 0
    on_warn = on_warn or nil
    local id = player:hud_add({
        hud_elem_type = "text",
        position = {x = 0.5, y = 0},
        offset = {x = 10, y = 10},
        alignment = {x = 0, y = 1},
        text = title .. get_time_text(time),
        number = color,
        scale = {x = 1500, y = 1500},
        style = 4, -- monospaced
        size = {x = 3, y = 1.5},
    })

    local timer = time
    local update_timer
    update_timer = function()
        timer = timer - 1
        if timer == warn_time and on_warn then
            on_warn(player)
        end
        if timer >= 0 then
            player:hud_change(id, "text", title .. get_time_text(timer))
            player:hud_change(id, "number", color)
            minetest.after(1, update_timer)
        else
            player:hud_remove(id)
            if on_end then
                on_end(player)
            end
        end
    end
    minetest.after(1, update_timer)
end