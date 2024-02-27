local forms = {}

local hud_id_intro_text_title
local hud_id_intro_text
local hud_id_intro_image

local hudform = {
    "formspec_version[4]",
    "size[0,0]",
    "image[0,0;20,13;transparent.png]",
    "modal[]",
}

local hudhelpform = {
    "formspec_version[4]",
    "size[0.1,0.1]",
    "position[10,10]",
}

-- #################### HELP FLAGS, HUDS and FORMS ####################

local hud_id_help_image
local hud_id_help_text

local function showHelpHUD(player, helptext)

    local screen_width = 1920 -- get the screen's width
    local screen_height = 1200 -- get the screen's height

    local distance_from_left = -40 -- the distance from the left border
    local distance_from_top = -20 -- the distance from the top border

    local help_image_width = 663
    local help_image_height = 361

    local image_position = {
        x = (distance_from_left + (help_image_width / 2)) / screen_width,
        y = (distance_from_top + (help_image_height / 2)) / screen_height,
    }

    local text_position = {
        x = (distance_from_left + (0.5 * help_image_width) - 130) / screen_width,
        y = (distance_from_top + (0.5 * help_image_height) - 72) / screen_height,
    }

    if player then
        -- Add the image
        hud_id_help_image = player:hud_add({
            hud_elem_type = "image",
            position = image_position, --{x = 0.026, y = 0.0042},
            scale = {x = 0.8, y = 0.8} ,
            text = "help_blank.png",
            alignment = {x = 0, y = 0},
        })

        -- Add the text
        hud_id_help_text = player:hud_add({
            hud_elem_type = "text",
            position = image_position,
            scale = 1,
            size = {x = 2.6, y = 2.6},
            text = helptext,
            number = 0x000000,  -- Text color: black
            alignment = {x = 0, y = 0},
        })

        --minetest.show_formspec(player:get_player_name(), "insta:help", table.concat(hudhelpform, ""))
    end
end

local function hideHelpHUD(player)
    if player then
        if hud_id_help_image then
            player:hud_remove(hud_id_help_image)
        end
        if hud_id_help_text then
            player:hud_remove(hud_id_help_text)
        end
    end
end

minetest.register_globalstep(function()
    for _, player in ipairs(minetest.get_connected_players()) do
        local controls = player:get_player_control()
        if controls.aux1 then
            -- The aux1 key is being pressed
            hideHelpHUD(player)
            forms.hideIntroHUD(player)
            forms.hideResultHUD(player)
            end
    end
end)


local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local help_default = {
    start = {
        show = 1,
        text = "Am besten baust du erst\nein paar Strassen.\nDenn Gebäude müssen an\nStrassen liegen."
    }
}

local help = deepcopy(help_default)

local function reset_help()
    help = deepcopy(help_default)
end

function forms.show_help(player, flag)
    if help[flag] and help[flag].show > 0 then
        help[flag].show = help[flag].show - 1
        showHelpHUD(player, help[flag].text)
    end
end


function forms.showIntroHUD(player)
    if player then
        -- Add the image
        hud_id_intro_image = player:hud_add({
            hud_elem_type = "image",
            position = {x = 0.5, y = 0.5},
            scale = {x = 1, y = 1},
            text = "intro_hud_image.png",
        })

        -- Add the text title
        hud_id_intro_text_title = player:hud_add({
            hud_elem_type = "text",
            position = {x = 0.5, y = 0.28},
            scale = {x = 1, y = 1},
            size = {x = 3, y = 2},
            text = "Deine Aufgabe: Baue eine Stadt",
            number = 0x000000,  -- Text color: black
            alignment = {x = 0, y = 0},
        })

        -- Add the text
        hud_id_intro_text = player:hud_add({
            hud_elem_type = "text",
            position = {x = 0.5, y = 0.4},
            scale = {x = 1, y = 1},
            size = {x = 2.5, y = 1.5},
            text = "für mindestens " .. _G.insta.goal_population .. " Menschen\n" ..
                "mit maximal " .. _G.insta.goal_co2 .. "t CO2 Footprint\n" ..
                "für höchtens " .. _G.insta.goal_money .. " Millionen € Kosten.",
            number = 0x000000,  -- Text color: black
            alignment = {x = 0, y = 0},
        })

        minetest.show_formspec(player:get_player_name(), "insta:start", table.concat(hudform, ""))
    end
end

function forms.hideIntroHUD(player)
    if player then
        if hud_id_intro_text_title then
            player:hud_remove(hud_id_intro_text_title)
        end
        if hud_id_intro_text then
            player:hud_remove(hud_id_intro_text)
        end
        if hud_id_intro_image then
            player:hud_remove(hud_id_intro_image)
        end

        minetest.after(5, function()
            forms.show_help(player, "start")
        end)
    end
end

function forms.showResultHUD(player)
    if player then
        hideHelpHUD(player)

        -- Add the image
        hud_id_intro_image = player:hud_add({
            hud_elem_type = "image",
            position = {x = 0.5, y = 0.5},
            scale = {x = 1, y = 1},
            text = "intro_hud_image.png",
        })

        local title = "Deine Stadt ist fertig!"

        -- Add the text title
        hud_id_intro_text_title = player:hud_add({
            hud_elem_type = "text",
            position = {x = 0.5, y = 0.28},
            scale = {x = 1, y = 1},
            size = {x = 3, y = 2},
            text = title,
            number = 0x000000,  -- Text color: black
            alignment = {x = 0, y = 0},
        })

        -- Add the text
        hud_id_intro_text = player:hud_add({
            hud_elem_type = "text",
            position = {x = 0.5, y = 0.4},
            scale = {x = 1, y = 1},
            size = {x = 2.5, y = 1.5},
            text = "Hier leben " .. 
                math.floor(player:get_meta():get_float("population")+0.5) .. " Menschen.\n" ..
                "Du hast " .. 
                math.floor(player:get_meta():get_float("co2")+0.5) .. "t CO2 verbraucht und\n" ..
                player:get_meta():get_int("costs") .. " Millionen € ausgegeben.",
            number = 0x000000,  -- Text color: black
            alignment = {x = 0, y = 0},
        })

        minetest.show_formspec(player:get_player_name(), "insta:result", table.concat(hudform, ""))
    end
end

function forms.hideResultHUD(player)
    if player then
        if hud_id_intro_text_title then
            player:hud_remove(hud_id_intro_text_title)
        end
        if hud_id_intro_text then
            player:hud_remove(hud_id_intro_text)
        end
        if hud_id_intro_image then
            player:hud_remove(hud_id_intro_image)
        end
    end
end



minetest.register_on_player_receive_fields(function(player, formname, _fields)
    if (formname == "insta:start") then
        _G.worksaver.Reset_world()
        reset_help()
        _G.insta.start_countdown()
        forms.hideIntroHUD(player)
    end

    if (formname == "insta:result") then
        forms.hideResultHUD(player)
        minetest.after(0.1, function()
            forms.showIntroHUD(player)
        end)
    end

    if (formname == "insta:help") then
        hideHelpHUD(player)
    end

end)


return forms