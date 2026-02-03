local ADDON_NAME, BQ = ...

BQ.RED = "|cffff3333"

function msg_user(msg)
	print(BQ.RED..ADDON_NAME.."|r: "..(msg or ""))
end

-- 12.0.0 Historically we never properly waited for the addon to load before handling variables so do it now
local var_frame = CreateFrame("Frame")
var_frame:RegisterEvent("ADDON_LOADED")
var_frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "BeQuiet" then
		WL_DEFAULT = {
			-- Withered army training
			"Temple of Fal'adora",
			"Falanaar Tunnels",
			"Shattered Locus",
			-- Island Expeditions
			"Crestfall",
			"Snowblossom Village",
			"Havenswood",
			"Jorundall",
			"Molten Cay",
			"Un'gol Ruins",
			"The Rotting Mire",
			"Whispering Reef",
			"Verdant Wilds",
			"The Dread Chain",
			"Skittering Hollow",
			-- Choreghast
			"Torghast, Tower of the Damned",
			-- Main cities for new content launches
			"Stormwind City",
			"Orgrimmar",
			"Valdrakken",
			"Dornogal"
		}

		table.sort(WL_DEFAULT)

		BL_DEFAULT = {}

		--Initialize config variables if they are not saved
		if ENABLED == nil then
			ENABLED = 1
		end

		if VO_ENABLED == nil then
			VO_ENABLED = 0
		end

		if BQ_SHOW_HEADS == nil then
			BQ_SHOW_HEADS = true
		end

		if VERBOSE == nil then
			VERBOSE = 1
		end

		if BQ_SUPPRESS_INSTANCES == nil then
			BQ_SUPPRESS_INSTANCES = false
		end

		--Default whitelist includes the withered army training zones from legion and island expeditions from BFA
		if WHITELIST == nil then
			WHITELIST = WL_DEFAULT
		end

		-- BLACKLIST defaults to empty. This preserves off behavior from before.
		if BLACKLIST == nil then
			BLACKLIST = BL_DEFAULT
		end

		if BQ_ENABLE_ESCAPE == nil then
			BQ_ENABLE_ESCAPE = false
		end

		_G["BINDING_NAME_BeQuiet_CloseTalkingHead"] = ADDON_NAME .. " - Close Talking Head" -- see Bindings.xml

		BQ.versionLabel = "v" .. (C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "1")
	end
end)

-------------------------------------------------------------------------------
-- Keybinding to let the use manually close the talking head
-------------------------------------------------------------------------------

local keyNameToBind  = "Escape" -- will be temporarily stolen then restored to any existing bindings
local isBound

function add_tmp_keybind_that_closes()
	if not BQ_ENABLE_ESCAPE then return end

	if not isBound then
		if InCombatLockdown() then return end
		SetOverrideBinding(TalkingHeadFrame, true, keyNameToBind, "BeQuiet_CloseTalkingHead") -- see Bindings.xml
		isBound = true
	end
end

function remove_tmp_keybind_that_closes()
	-- debug output to prove this is being called and by whom: all 3 Close* methods
	--print("remove_tmp_keybind_that_closes() isBound =",isBound, "called by:")
	--local stack = debugstack(1,3,0)
	--DevTools_Dump(stack)

	if InCombatLockdown() then return end
	SetOverrideBinding(TalkingHeadFrame, true, keyNameToBind, nil)
	isBound = false
end

function close_head_immediately()
	TalkingHeadFrame:CloseImmediately()
end

GLOBAL_BeQuiet_CloseTalkingHead = close_head_immediately -- export into the global namespace for use by Bindings.xml

-------------------------------------------------------------------------------
--Create the frame
local f = CreateFrame("Frame")

-------------------------------------------------------------------------------
-- Logic based on config options - decide if we're going to close the talking head
-------------------------------------------------------------------------------

function close_head()
	local iDidItAll

	-- TODO: work in logic for instances - BQ_SUPPRESS_INSTANCES - boolean true and false
	local inInstance, instanceType = IsInInstance()
	if BQ_SUPPRESS_INSTANCES == true and inInstance == true then
		iDidItAll = block_head();
	end

	--Query current zone and subzone when talking head is triggered
	subZoneName = GetSubZoneText();
	zoneName = GetZoneText();
	--Only run this logic if the functionality is turned on
	if ENABLED == 1 then
		--Block the talking head unless its in the whitelist
		if (has_value(WHITELIST, subZoneName) ~= true and has_value(WHITELIST, zoneName) ~= true) then
			iDidItAll = block_head();
		end
	--If disabled, check blacklist
	elseif (has_value(BLACKLIST, subZoneName) or has_value(BLACKLIST, zoneName)) then
		iDidItAll = block_head();
	end

	if not iDidItAll then
		add_tmp_keybind_that_closes()
		-- note: the user's configured keybind will always be available
	end
end

---@return boolean true if all possible actions were performed
function block_head()
	local c = 0

	--Close the talking head
	--TalkingHeadFrame:CloseImmediately(); pre 10.0.7
	if not is_true(BQ_SHOW_HEADS) then
		TalkingHeadFrame:Hide()
		c = c + 1
	end
	if TalkingHeadFrame.voHandle ~= nil and VO_ENABLED == 0 then
		--C_Timer.After(0.025, function() StopSound(TalkingHeadFrame.voHandle) end);
		C_Timer.After(0.025, function() if TalkingHeadFrame.voHandle then StopSound(TalkingHeadFrame.voHandle) end end);
		c = c + 1
	end
	if VERBOSE == 1 then
		local blockedNothing = is_true(VO_ENABLED) and is_true(BQ_SHOW_HEADS)
		if not blockedNothing then
			msg_user("blocked a talking head! /bq verbose to turn this alert off.")
		end
	end

	return c == 2
end

--Main function
function f:OnEvent(event, ...)
	if event == "PLAYER_LOGIN" then
		hooksecurefunc(TalkingHeadFrame, "PlayCurrent", close_head);
		hooksecurefunc(TalkingHeadFrame, "Close",            remove_tmp_keybind_that_closes);
		hooksecurefunc(TalkingHeadFrame, "CloseImmediately", remove_tmp_keybind_that_closes);
		hooksecurefunc(TalkingHeadFrame, "Close_OnFinished", remove_tmp_keybind_that_closes);

		BQ.Options:init()
	end
end

function removeFirst(tbl, val)
	for i, v in ipairs(tbl) do
		if v == val then
			return table.remove(tbl, i)
		end
	end
end

--Function to check if value in array
function has_value (tab, val)
	for _, value in ipairs(tab) do
		if value == val then
			return true
		end
	end
	return false
end

function is_empty(s)
	return s == nil or s == ''
end

function is_true(val_0_or_1)
	return val_0_or_1 == 1
end

function convertTo0or1(isTrue)
	return isTrue and 1 or 0
end

function is_mode_not_blacklist()
	return is_true(ENABLED)
end

function is_mode_not_whitelist()
	return not is_true(ENABLED)
end

function make_btn_text_for_toggle_current_zone(list, list_name)
	local zone = GetZoneText()
	return make_btn_text_for_zone_toggle(zone, list, list_name)
end

function make_btn_text_for_toggle_current_subzone(list, list_name)
	local zone = GetSubZoneText()
	return make_btn_text_for_zone_toggle(zone, list, list_name)
end

function make_btn_text_for_zone_toggle(zone, list, name)
	if is_empty(zone) then
		return nil
	end
	local verb
	if has_value(list, zone) then
		verb = "Remove"
	else
		verb = "Add"
	end
	return verb .." ".. zone
end

function toggle_current_zone(list, name)
	local zone = GetZoneText()
	toggle_current_zone_or_subzone(zone, "subzone", list, name)
end

function toggle_current_subzone(list, name)
	local zone = GetSubZoneText()
	toggle_current_zone_or_subzone(zone, "subzone", list, name)
end

function toggle_current_zone_or_subzone(zone, zone_type, list, name)
	if is_empty(zone) then
		msg_user("The current ".. zone_type .." doesn't have a name.")
		return
	end
	if has_value(list, zone) then
		removeFirst(list, zone)
		msg_user(zone .. ' removed from the '..name..'list.')
	else
		table.insert(list, zone)
		msg_user(zone .. ' added to the '..name..'list.')
	end
	table.sort(list)
end

-- because WHITELIST = WL_DEFAULT makes both arrays point to the same memory location
-- after which, altering one alters both simultaneously
-- and you are no longer able to use WL_DEFAULT as an original, unchanged value
function replace_array(src, target)
	for i, v in ipairs(target) do
		--msg_user("erasing",i,v)
		target[i] = nil
	end

	for i, v in ipairs(src) do
		--msg_user("adding",i,v)
		target[i] = v
	end
end

--Slash command function
function MyAddonCommands(args)
	allow_msg = 'disabled - now allowing talking heads except for blacklisted zones.'
	block_msg = 'enabled - now blocking talking heads except for whitelisted zones.'

	if args == 'config' then
		Settings.OpenToCategory(ADDON_NAME)
	end

	if args == 'off' then
		ENABLED = 0
		msg_user(allow_msg)
	end

	if args == 'on' then
		ENABLED = 1
		msg_user(block_msg)
	end

	if args == 'toggle' then
		if ENABLED == 0 then
			ENABLED = 1
			msg_user(block_msg)
		elseif ENABLED == 1 then
			ENABLED = 0
			msg_user(allow_msg)
		end
	end

	if args == 'whitelist currentzone' then
		toggle_current_zone(WHITELIST, "white")
	end

	if args == 'whitelist currentsubzone' then
		toggle_current_subzone(WHITELIST, "white")
	end
	
	if args == 'blacklist currentzone' then
		toggle_current_zone(BLACKLIST, "black")
	end

	if args == 'blacklist currentsubzone' then
		toggle_current_subzone(BLACKLIST, "black")
	end

	if args == 'delete' then
		WHITELIST = {}
		BLACKLIST = {}
		msg_user('Whitelist and blacklist have been deleted.')
	end

	if args == 'reset' then
		WHITELIST = WL_DEFAULT
		BLACKLIST = BL_DEFAULT
		msg_user('Whitelist and blacklist have been reset to default.')
	end

	if args == 'show' then
		msg_user('whitelist: ' .. table.concat(WHITELIST, ', '))
		msg_user('blacklist: ' .. table.concat(BLACKLIST, ', '))
	end

	if args == 'verbose' then
		if VERBOSE == 0 then
			VERBOSE = 1
			msg_user('Verbose mode enabled. A chat message will print when a talking head is blocked.')
		elseif VERBOSE == 1 then
			VERBOSE = 0
			msg_user('Verbose mode disabled.')
		end
	end
	
	if args == 'vo on' then
		VO_ENABLED = 1
		msg_user('VoiceOver enabled when talking head frame hidden')
	end

	if args == 'vo off' then
		VO_ENABLED = 0
		msg_user('VoiceOver disabled when talking head frame hidden')
	end

	if args == 'vo toggle' then
		if VO_ENABLED == 1 then
			VO_ENABLED = 0
			msg_user('VoiceOver disabled when talking head frame hidden')
		else
			VO_ENABLED = 1
			msg_user('VoiceOver enabled when talking head frame hidden')
		end
	end

	-- ESCAPE KEY --

	local escOriginal = BQ_ENABLE_ESCAPE

	if args == 'esc' then
		msg_user ('esc (on | off | toggle) - allow the escape key to close the talking head or not')
	elseif args == 'esc on' then
		BQ_ENABLE_ESCAPE = true
	elseif args == 'esc off' then
		BQ_ENABLE_ESCAPE = false
	elseif args == 'esc toggle' then
		BQ_ENABLE_ESCAPE = not BQ_ENABLE_ESCAPE
	end

	if escOriginal ~= BQ_ENABLE_ESCAPE then
		local msgOnOrOff = BQ_ENABLE_ESCAPE and "enabled to close" or "disabled from closing"
		msg_user('Escape key is now ' ..msgOnOrOff.. ' the talking head frame')
	end

	if args == 'whitelist' then
		msg_user('whitelist (currentzone | currentsubzone) - toggle whitelisting for the current major zone (Orgrimmar) or sub-zone (Valley of Strength).')
	end

	if args == 'blacklist' then
		msg_user('blacklist (currentzone | currentsubzone) - toggle blacklisting for the current major zone (Orgrimmar) or sub-zone (Valley of Strength).')
	end

	if args == 'vo' then
		print ('vo (on | off | toggle) - enable or disable removal of vo seperate from hiding talking head ui')
	end

	if args == '' then
		msg_user('version ' .. BQ.versionLabel)
		msg_user('Options: config | on | off | toggle | verbose | whitelist | blacklist | reset | delete | show | vo | esc')
		msg_user('-----')
		if ENABLED == 1 then
			msg_user('is currently enabled.')
		elseif ENABLED == 0 then
			msg_user('is currently disabled.')
		end
		if VERBOSE == 1 then
			msg_user('Verbose mode is currently enabled.')
		elseif VERBOSE == 0 then
			msg_user('Verbose mode is currently disabled.')
		end

		msg_user("Talking heads are currently " .. (BQ_SHOW_HEADS and "shown." or "hidden."))
	end
end

--Add /bq to slash command list and register its function
SLASH_BQ1 = '/bq'
SlashCmdList["BQ"] = MyAddonCommands

f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", f.OnEvent)
