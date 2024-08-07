_G.forms = {}

local hud_id_image

local hudform = {
    "formspec_version[4]",
    "size[0,0]",
    "image[0,0;20,13;transparent.png]",
    "modal[]",
}

local hud_id_help_image

local hud_state = {
    wait = false,
    tipp = false,
    helpOverview = false,
    intro = false,
    result = false,
}


local function showTippHUD(player, tippName)
    if hud_id_help_image then
        -- remove any other hud tipp shown currently:
        player:hud_remove(hud_id_help_image)
    end


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

    if player then
        -- Add the image
        hud_id_help_image = player:hud_add({
            hud_elem_type = "image",
            position = image_position, --{x = 0.026, y = 0.0042},
            scale = {x = 0.8, y = 0.8} ,
            text = "tipp_" .. tippName .. ".png",
            alignment = {x = 0, y = 0},
        })

        hud_state.tipp = true
    end
end

local function hideTippHUD(player)
    if player then
        if hud_id_help_image then
            player:hud_remove(hud_id_help_image)
            minetest.after(0.5, function()
                hud_state.tipp = false
            end)
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
            if hud_state.tipp then
                hud_key_stroked()
                hideTippHUD(player)
            end
            if hud_state.intro then
                hud_key_stroked()
                _G.forms.hideIntroHUD(player)
            end
            if hud_state.result then
                hud_key_stroked()
                _G.forms.hideResultHUD(player)
            end
            if hud_state.helpOverview then
                hud_key_stroked()
                _G.forms.hideHelpOverviewHUD(player)
            end
            if not hud_state.tipp and not hud_state.intro and not hud_state.result and not hud_state.helpOverview then
                hud_key_stroked()
                _G.forms.ShowInfoTabs(player)
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

_G.forms.help = {
    streets = {
        show = 3,
    },
    level_up = {
        after = 20,
        show = 1,
    },
    point_at = {
        after = 10,
        show = 1,
    },
}

local _help = deepcopy(_G.forms.help)

local function reset_help()
    _help = deepcopy(_G.forms.help)
end

function _G.forms.ShowTipp(player, tippName)
    if _help[tippName] and _help[tippName].show > 0 then
        _help[tippName].show = _help[tippName].show - 1
        showTippHUD(player, tippName)
    end
end


function _G.forms.showIntroHUD(player)
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

function _G.forms.hideIntroHUD(player)
    if not player or not hud_id_image then return end

    player:hud_remove(hud_id_image)
    hud_state.intro = false
    minetest.after(_G.forms.help.point_at.after or 10, function()
        if not _G.status.hasBuilt then
            _G.forms.ShowTipp(player, "point_at")
        end
    end)

end

function _G.forms.showResultHUD(player)
    -- select the appropriate image
    local mediumFailureLimit = 25.0 -- percent deviation in wrong direction
    local imageFilePrefix = "screen_"
    local imageFile = "allSuccess.png"

    local lackInPopulation = ((_G.status.goal_population - player:get_meta():get_float("population")) * 100.0)
        /  _G.status.goal_population
    local excessInCo2 = ((player:get_meta():get_float("co2") - _G.status.goal_co2) * 100)
        / _G.status.goal_co2
    local excessInCosts = ((player:get_meta():get_int("costs") - _G.status.goal_costs) * 100)
        / _G.status.goal_costs
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
        hideTippHUD(player)

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

function _G.forms.hideResultHUD(player)
    if player then
        if hud_id_image then
            player:hud_remove(hud_id_image)

            hud_state.result = false
        end
    end
end

function _G.forms.showHelpOverviewHUD(player)
    local imageFile = "TabHilfe.png"
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

function _G.forms.hideHelpOverviewHUD(player)
    if player then
        if hud_id_image then
            player:hud_remove(hud_id_image)
            minetest.after(0.1, function()
                hud_state.helpOverview = false
            end)
        end
    end
end

function _G.forms.ShowInfoTabs(player)
    local current_tab = 1  -- The currently selected tab

    local function show_formspec(tab)
        local image = "TabHilfe.png"  -- The default image
        if tab == 2 then
            image = "TabWerte.png"
        elseif tab == 3 then
            image = "TabLizenzen.png"
        elseif tab == 4 then
            image = "TabImpressum.png"
        end

        local formspec =
            "size[14.8,11.7]" ..
            "tabheader[0,0;tabs;Steuerung,Werte,Lizenzen,Impressum;" .. tab .. ";true;false]" ..
            "image[0.1,0.1;18,13.5;" .. image .. "]"

        minetest.show_formspec(player:get_player_name(), "insta:info", formspec)
    end

    minetest.register_on_player_receive_fields(function(_user, formname, fields)
        if formname == "insta:info" and fields.tabs then
            local tab = tonumber(fields.tabs)
            if tab and tab ~= current_tab then
                current_tab = tab
                show_formspec(tab)
            end
        end
    end)

    show_formspec(current_tab)
end



minetest.register_on_player_receive_fields(function(player, formname, _fields)
    if (formname == "insta:start") then
        minetest.set_timeofday(0.5)
        _G.worksaver.Reset_world()
        reset_help()
        _G.insta.start_countdown()
        _G.forms.hideIntroHUD(player)
    end

    if (formname == "insta:result") then
        _G.forms.hideResultHUD(player)
        minetest.after(0.1, function()
            _G.forms.showIntroHUD(player)
        end)
    end

 --   if (formname == "insta:help") then
 --       hideTippHUD(player)
 --   end

    if (formname == "insta:helpOverview") then
        _G.forms.hideHelpOverviewHUD(player)
    end
end)

return _G.forms