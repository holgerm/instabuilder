local forms = {}

local hud_id_image

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

local hud_state = {
    wait = false,
    help = false,
    helpOverview = false,
    intro = false,
    result = false,
}


local function showHelpHUD(player, helptext)

    local screen_width = 1920 -- get the screen's width
    local screen_height = 1080 -- get the screen's height

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
        hud_state.help = true
    end
end

local function hideHelpHUD(player)
    if player then
        if hud_id_help_image then
            player:hud_remove(hud_id_help_image)
            minetest.after(0.5, function()
                hud_state.help = false
            end)
        end

        if hud_id_help_text then
            player:hud_remove(hud_id_help_text)
        end
    end
end

local function hud_key_stroked()
    hud_state.wait = true
    minetest.after(0.5, function()
        hud_state.wait = false
    end)
end

--- React on "E" key press: Hide the help, intro, or result HUDs
minetest.register_globalstep(function()
    for _, player in ipairs(minetest.get_connected_players()) do
        local controls = player:get_player_control()
        if controls.aux1 then
            -- The aux1 key is being pressed, i.e. the E key
            if hud_state.wait then
                return
            end
            if hud_state.help then
                hud_key_stroked()
                hideHelpHUD(player)
            end
            if hud_state.intro then
                hud_key_stroked()
                forms.hideIntroHUD(player)
            end
            if hud_state.result then
                hud_key_stroked()
                forms.hideResultHUD(player)
            end
            if hud_state.helpOverview then
                hud_key_stroked()
                forms.hideHelpOverviewHUD(player)
            end
            if not hud_state.help and not hud_state.intro and not hud_state.result and not hud_state.helpOverview then
                hud_key_stroked()

                forms.showHelpOverviewHUD(player)
            end
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
    local imageFile = "screen_start.png"
    if player then
        -- Add the image
        hud_id_image = player:hud_add({
            hud_elem_type = "image",
            position = {x = 0.5, y = 0.5},
            scale = {x = 1, y = 1},
            text = imageFile,
        })
        minetest.show_formspec(player:get_player_name(), "insta:start", table.concat(hudform, ""))
    end
end

function forms.hideIntroHUD(player)
    if player then
        if hud_id_image then
            player:hud_remove(hud_id_image)
            hud_state.intro = false
        end


        minetest.after(5, function()
            forms.show_help(player, "start")
        end)
    end
end

function forms.showResultHUD(player)
    -- select the appropriate image
    local mediumFailureLimit = 25.0 -- percent deviation in wrong direction
    local imageFilePrefix = "screen_"
    local imageFile = "allSuccess.png"

    local lackInPopulation = ((_G.insta.goal_population - player:get_meta():get_float("population")) * 100.0) 
        /  _G.insta.goal_population
    local excessInCo2 = ((player:get_meta():get_float("co2") - _G.insta.goal_co2) * 100) 
        / _G.insta.goal_co2
    local excessInCosts = ((player:get_meta():get_int("costs") - _G.insta.goal_costs) * 100) 
        / _G.insta.goal_costs
    if lackInPopulation > excessInCo2 and lackInPopulation > excessInCo2 then
        if lackInPopulation > mediumFailureLimit then
            imageFile = "veryFewRoom.png"
        elseif lackInPopulation > 0 then
            imageFile = "fewRoom.png"
        end
    end
    if excessInCo2 > lackInPopulation and excessInCo2 > excessInCosts then
        if excessInCo2 > mediumFailureLimit then
            imageFile = "veryHarmful.png"
        elseif excessInCo2 > 0 then
            imageFile = "harmful.png"
        end
    end
    if excessInCosts > lackInPopulation and excessInCosts > excessInCo2 then
        if excessInCosts > mediumFailureLimit then
            imageFile = "veryCostly.png"
        elseif excessInCosts > 0 then
            imageFile = "costly.png"
        end
    end

    if player then
        hideHelpHUD(player)

        -- Add the image
        hud_id_image = player:hud_add({
            hud_elem_type = "image",
            position = {x = 0.5, y = 0.5},
            scale = {x = 1, y = 1},
            text = imageFilePrefix .. imageFile,
        })

        minetest.show_formspec(player:get_player_name(), "insta:result", table.concat(hudform, ""))
    end
end

function forms.hideResultHUD(player)
    if player then
        if hud_id_image then
            player:hud_remove(hud_id_image)

            hud_state.result = false
        end
    end
end

function forms.showHelpOverviewHUD(player)
    local imageFile = "screen_helpOverview.png"
    if player then
        -- Add the image
        hud_id_image = player:hud_add({
            hud_elem_type = "image",
            position = {x = 0.5, y = 0.5},
            scale = {x = 1, y = 1},
            text = imageFile,
        })
        minetest.show_formspec(player:get_player_name(), "insta:helpOverview", table.concat(hudform, ""))
        hud_state.helpOverview = true
    end
end

function forms.hideHelpOverviewHUD(player)
    if player then
        if hud_id_image then
            player:hud_remove(hud_id_image)
            minetest.after(0.1, function()
                hud_state.helpOverview = false
            end)
        end


        minetest.after(5, function()
            forms.show_help(player, "start")
        end)
    end
end



minetest.register_on_player_receive_fields(function(player, formname, _fields)
    if (formname == "insta:start") then
        minetest.set_timeofday(0.5)
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

    if (formname == "insta:helpOverview") then
        forms.hideHelpOverviewHUD(player)
    end
end)

return forms