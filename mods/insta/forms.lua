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
    end
end

function forms.showResultHUD(player)
    if player then
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


return forms