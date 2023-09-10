-- Options
-- user defined configuration options

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, BQ = ...

---@class Options -- IntelliJ-EmmyLua annotation
---@field supportCombat boolean placate Bliz security rules of "don't SetAnchor() during combat"
---@field doCloseOnClick boolean close the flyout after the user clicks one of its buttons
---@field usePlaceHolders boolean eliminate the need for "Always Show Buttons" in Bliz UI "Edit Mode" config option for action bars
---@field clickers table germ behavior for various mouse clicks
local Options = { }
BQ.Options = Options

local EMPTY = {}

-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------

function Options:init()
    local whitelist_kill
    local blacklist_kill

    local optionsMenu = {
        name = ADDON_NAME,
        type = "group",
        args = {

            -------------------------------------------------------------------------------
            -- General
            -------------------------------------------------------------------------------

            description = {
                order = 5,
                type = 'description',
                name = "Hides and/or mutes the giant talking heads from NPCs when entering world quests or instances only leaving their text in the regular chat box. \r\r",
            },
            mute = {
                order = 50,
                name = "Mute",
                desc = "Silence the voiceover.",
                --width = "full",
                type = "toggle",
                set = function(optionsMenu, isMuted)
                    msg_user("Voiceovers are " .. (isMuted and "muted." or "allowed."))
                    VO_ENABLED = convertTo0or1(not isMuted)
                end,
                get = function()
                    return not is_true(VO_ENABLED)
                end,
            },
            hide = {
                order = 60,
                name = "Hide",
                desc = "Hide the talking head.",
                --width = "full",
                type = "toggle",
                set = function(optionsMenu, isHidden)
                    local doShow = not isHidden
                    msg_user("Talking heads will ".. (doShow and "appear." or "be hidden."))
                    BQ_SHOW_HEADS = convertTo0or1(doShow)
                end,
                get = function()
                    return not is_true(BQ_SHOW_HEADS)
                end,
            },
            warn_if_broke = {
                order = 70,
                hidden = function()
                    local warn = is_true(VO_ENABLED) and is_true(BQ_SHOW_HEADS)
                    local hide = not warn
                    return hide
                end,
                type = 'description',
                name = BQ_RED.."DISABLED! |r With neither Mute nor Hide, BeQuiet will effectively do nothing.",
            },

            -------------------------------------------------------------------------------
            -- Mode
            -------------------------------------------------------------------------------

            mode_header = {
                order = 149,
                name = "Mode",
                type = 'header',
            },
            mode_help = {
                order = 150,
                type = 'description',
                name = "There are two modes of BeQuiet: activate everywhere by default but permit specific zones;  Or suppress zone by zone. \r\r",
            },
            mode = {
                order = 170,
                name = "Mode",
                width = "full",
                type = "select",
                style = "radio", --"dropdown", "radio"
                values = {
                    [true] = "BeQuiet everywhere by default.  Zones in the Whitelist will not be suppressed.",
                    [false] = "BeQuiet nowhere by default.  Only zones in the Blacklist will be suppressed.",
                },
                sorting = { true,false },
                set = function(optionsMenu, val)
                    ENABLED = convertTo0or1(val)
                    --msg_user(val and allow_msg or block_msg)
                end,
                get = function()
                    return is_mode_not_blacklist()
                end,
            },

            -------------------------------------------------------------------------------
            -- Warnings
            -------------------------------------------------------------------------------

            warnings_linebreak = {
                order = 1000,
                type = 'description',
                name = "",
            },
            warnings = {
                order = 65,
                name = "Warnings",
                desc = "Display a message in your chat box when "..ADDON_NAME.." hides or mutes a talking head.",
                --width = "full",
                type = "toggle",
                set = function(optionsMenu, val)
                    VERBOSE = convertTo0or1(val)
                    msg_user("Warnings are " .. (val and "enabled." or "disabled."))
                end,
                get = function()
                    return is_true(VERBOSE)
                end,
            },

            -------------------------------------------------------------------------------
            -- Whitelist
            -------------------------------------------------------------------------------

            whitelist_header = {
                order = 200,
                hidden = is_mode_not_whitelist,
                name = "Whitelist",
                type = 'header',
            },
            whitelist_help = {
                order = 205,
                hidden = is_mode_not_whitelist,
                type = 'description',
                name = "Zones in the whitelist will be allowed to play the talking heads.",
            },
            whitelist_current_zone = {
                order = 210,
                hidden = is_mode_not_whitelist,
                name = function() return make_btn_text_for_toggle_current_zone(WHITELIST, "white") or "No Zone"  end, -- "Toggle Current Zone",
                desc = "Allow talking heads in your current major zone (e.g. Orgrimmar or Stormwind)",
                width = "double",
                type = "execute",
                func = function() toggle_current_zone(WHITELIST, "white")  end,
            },
            whitelist_current_subzone = {
                order = 220,
                hidden = is_mode_not_whitelist,
                name = function() return make_btn_text_for_toggle_current_subzone(WHITELIST, "white") or "No Subzone"  end, -- "Toggle Current Subzone",
                disabled = function() return nil == make_btn_text_for_toggle_current_subzone(WHITELIST, "white")  end,
                desc = "Allow talking heads in your current subzone (e.g. Valley of Strength or Old Town)",
                width = "double",
                type = "execute",
                func = function() toggle_current_subzone(WHITELIST, "white")  end,
            },
            whitelist_display = {
                -- NOT USED - replaced by hover text
                order = 229,
                hidden = true, -- use_mode_whitelist,
                disabled = true,
                name = "", -- "Current Whitelist",
                desc = "List of all zones currently in the whitelist.",
                width = "double",
                type = "input",
                multiline = 5,
                get = function()
                    return table.concat(WHITELIST, "\r")
                end,
            },
            whitelist_picker = {
                order = 230,
                hidden = is_mode_not_whitelist,
                name = "Current Whitelist",
                desc = table.concat(WHITELIST, "\r"),
                width = "double",
                type = "select",
                values = WHITELIST,
                get = function()
                    return whitelist_kill
                end,
                set = function(info, val)
                    whitelist_kill = val
                end
            },
            whitelist_listing_killer = {
                order = 230,
                hidden = is_mode_not_whitelist,
                name = "Delete Selection from Whitelist",
                desc = "Allow talking heads in your current subzone (e.g. Valley of Strength or Old Town)",
                width = "double",
                type = "execute",
                disabled = function()
                    return not (whitelist_kill and true or false)
                end,
                func = function()
                    --msg_user("WHITELIST",table.concat(WHITELIST,", "))
                    --msg_user("killing",whitelist_kill,val)
                    local val = WHITELIST[whitelist_kill]
                    --msg_user("killing",val)
                    removeFirst(WHITELIST, val)
                    --msg_user("result =", table.concat(WHITELIST,", "))
                    whitelist_kill = nil
                end,
            },
            whitelist_linebreak = {
                order = 235,
                hidden = is_mode_not_whitelist,
                type = 'description',
                name = "",
            },
            whitelist_RESET = {
                order = 250,
                hidden = is_mode_not_whitelist,
                name = "Reset Whitelist",
                desc = "This will ERASE the current whitelist and set it to the default:".. table.concat(WL_DEFAULT, ", "),
                --width = "double",
                type = "execute",
                confirm = true,
                func = function()
                    replace_array(WL_DEFAULT, WHITELIST)
                end,
            },
            whitelist_ERASE = {
                order = 240,
                hidden = is_mode_not_whitelist,
                name = "Erase Whitelist",
                desc = "This will ERASE the current whitelist.",
                disabled = function() return WHITELIST[1] == nil end,
                --width = "double",
                type = "execute",
                confirm = true,
                func = function()
                    replace_array(EMPTY, WHITELIST)
                end,
            },

            -------------------------------------------------------------------------------
            -- Blacklist
            -------------------------------------------------------------------------------

            blacklist_header = {
                order = 300,
                hidden = is_mode_not_blacklist,
                name = "Blacklist",
                type = 'header',
            },
            blacklist_help = {
                order = 305,
                hidden = is_mode_not_blacklist,
                type = 'description',
                name = "Zones in the blacklist will BeQuiet.",
            },
            blacklist_current_zone = {
                order = 310,
                hidden = is_mode_not_blacklist,
                name = function() return make_btn_text_for_toggle_current_zone(BLACKLIST, "black") or "No Zone"  end, -- "Toggle Current Zone",
                desc = "Block talking heads in your current major zone (e.g. Orgrimmar or Stormwind)",
                width = "double",
                type = "execute",
                func = function() toggle_current_zone(BLACKLIST, "black")  end,
            },
            blacklist_current_subzone = {
                order = 320,
                hidden = is_mode_not_blacklist,
                name = function() return make_btn_text_for_toggle_current_subzone(BLACKLIST, "black") or "No Subzone"  end, -- "Toggle Current Subzone",
                disabled = function() return nil == make_btn_text_for_toggle_current_subzone(BLACKLIST, "black")  end,
                desc = "Block talking heads in your current subzone (e.g. Valley of Strength or Old Town)",
                width = "double",
                type = "execute",
                func = function() toggle_current_subzone(BLACKLIST, "black")  end,
            },
            blacklist_display = {
                -- NOT USED - replaced by hover text
                order = 329,
                hidden = true, -- use_mode_blacklist,
                disabled = true,
                name = "", -- "Current Blacklist",
                desc = "List of all zones currently in the whitelist.",
                width = "double",
                type = "input",
                multiline = 5,
                get = function()
                    return table.concat(BLACKLIST, "\r")
                end,
            },
            blacklist_picker = {
                order = 330,
                hidden = is_mode_not_blacklist,
                name = "Current Blacklist",
                desc = table.concat(BLACKLIST, "\r"),
                width = "double",
                type = "select",
                values = BLACKLIST,
                get = function()
                    return blacklist_kill
                end,
                set = function(info, val)
                    blacklist_kill = val
                end
            },
            blacklist_listing_killer = {
                order = 330,
                hidden = is_mode_not_blacklist,
                name = "Delete Selection from Blacklist",
                desc = "Allow talking heads in your current subzone (e.g. Valley of Strength or Old Town)",
                width = "double",
                type = "execute",
                disabled = function()
                    return not (blacklist_kill and true or false)
                end,
                func = function()
                    --msg_user("BLACKLIST",table.concat(BLACKLIST,", "))
                    --msg_user("killing",blacklist_kill,val)
                    local val = BLACKLIST[blacklist_kill]
                    --msg_user("killing",val)
                    removeFirst(BLACKLIST, val)
                    --msg_user("result =", table.concat(BLACKLIST,", "))
                    blacklist_kill = nil
                end,
            },
            blacklist_linebreak = {
                order = 335,
                hidden = is_mode_not_blacklist,
                type = 'description',
                name = "",
            },
            blacklist_ERASE = {
                order = 340,
                hidden = is_mode_not_blacklist,
                name = "Erase Blacklist",
                desc = "This will ERASE the current blacklist.",
                disabled = function() return BLACKLIST[1] == nil end,
                --width = "double",
                type = "execute",
                confirm = true,
                func = function()
                    replace_array(BL_DEFAULT, BLACKLIST)
                end,
            },

            -------------------------------------------------------------------------------
            -- Instances Implicitly Blacklisted
            -------------------------------------------------------------------------------

            instance_linebreak = {
                order = 400,
                hidden = is_mode_not_blacklist,
                type = 'description',
                name = "",
            },
            instance = {
                order = 410,
                hidden = is_mode_not_blacklist,
                name = "Instances",
                desc = "Always BeQuiet in instances, dungeons, raids, etc.",
                --width = "full",
                type = "toggle",
                set = function(optionsMenu, val)
                    BQ_SUPPRESS_INSTANCES = val
                    msg_user("Instance are " .. (val and "supressed." or "free."))
                end,
                get = function()
                    return BQ_SUPPRESS_INSTANCES
                end,
            },

        },
    }

    -- init the message vars etc.
    MyAddonCommands()

    LibStub("AceConfig-3.0"):RegisterOptionsTable(ADDON_NAME, optionsMenu)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON_NAME, ADDON_NAME)

end

function BeQuiet_BlizCompartment_OnClick(addonName, mouseClick)
    Settings.OpenToCategory(ADDON_NAME)
end
