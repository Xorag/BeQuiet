version = "v10.1.7.2"

WL_DEFAULT = {
	"Temple of Fal'adora",
	"Falanaar Tunnels",
	"Shattered Locus",
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
	"Torghast, Tower of the Damned"
}

BL_DEFAULT = {}

--Initialize config variables if they are not saved
if ENABLED == nil then
	ENABLED = 1
end

if VO_ENABLED == nil then
	VO_ENABLED = 0
end

if VERBOSE == nil then
	VERBOSE = 1
end

--Default whitelist includes the withered army training zones from legion and island expeditions from BFA
if WHITELIST == nil then
	WHITELIST = WL_DEFAULT
end

-- BLACKLIST defaults to empty. This preserves off behavior from before.
if BLACKLIST == nil then
	BLACKLIST = BL_DEFAULT
end

--Create the frame
local f = CreateFrame("Frame")

function close_head()
	--Query current zone and subzone when talking head is triggered
	subZoneName = GetSubZoneText();
	zoneName = GetZoneText();
	--Only run this logic if the functionality is turned on
	if ENABLED == 1 then
		--Block the talking head unless its in the whitelist
		if (has_value(WHITELIST, subZoneName) ~= true and has_value(WHITELIST, zoneName) ~= true) then
			block_head();
		end
	--If disabled, check blacklist
	elseif (has_value(BLACKLIST, subZoneName) or has_value(BLACKLIST, zoneName)) then
		block_head();
	end
end

function block_head()
	--Close the talking head
	--TalkingHeadFrame:CloseImmediately(); pre 10.0.7
	TalkingHeadFrame:Hide()
	if TalkingHeadFrame.voHandle ~= nil and VO_ENABLED == 0 then
		--C_Timer.After(0.025, function() StopSound(TalkingHeadFrame.voHandle) end);
		C_Timer.After(0.025, function() if TalkingHeadFrame.voHandle then StopSound(TalkingHeadFrame.voHandle) end end);
	end
	if VERBOSE == 1 then
		print("BeQuiet blocked a talking head! /bq verbose to turn this alert off.")
	end
end

--Main function
function f:OnEvent(event, ...)
	if event == "PLAYER_LOGIN" then
		hooksecurefunc(TalkingHeadFrame, "PlayCurrent", close_head);
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

--Slash command function
function MyAddonCommands(args)
	allow_msg = 'BeQuiet disabled - now allowing talking heads except for blacklisted zones.'
	block_msg = 'BeQuiet enabled - now blocking talking heads except for whitelisted zones.'

	if args == 'off' then
		ENABLED = 0
		print(allow_msg)
	end

	if args == 'on' then
		ENABLED = 1
		print(block_msg)
	end

	if args == 'toggle' then
		if ENABLED == 0 then
			ENABLED = 1
			print(block_msg)
		elseif ENABLED == 1 then
			ENABLED = 0
			print(allow_msg)
		end
	end

	if args == 'whitelist currentzone' then
		zone = GetZoneText()
		if has_value(WHITELIST, zone) then
			removeFirst(WHITELIST, zone)
			print(zone .. ' removed from the whitelist.')
		else
			table.insert(WHITELIST, zone)
			print(zone .. ' added to the whitelist.')
		end
	end

	if args == 'whitelist currentsubzone' then
		zone = GetSubZoneText()
		if has_value(WHITELIST, zone) then
			removeFirst(WHITELIST, zone)
			print(zone .. ' removed from the whitelist.')
		else
			table.insert(WHITELIST, zone)
			print(zone .. ' added to the whitelist.')
		end
	end
	
	if args == 'blacklist currentzone' then
		zone = GetZoneText()
		if has_value(BLACKLIST, zone) then
			removeFirst(BLACKLIST, zone)
			print(zone .. ' removed from the blacklist.')
		else
			table.insert(BLACKLIST, zone)
			print(zone .. ' added to the blacklist.')
		end
	end

	if args == 'blacklist currentsubzone' then
		zone = GetSubZoneText()
		if has_value(BLACKLIST, zone) then
			removeFirst(BLACKLIST, zone)
			print(zone .. ' removed from the blacklist.')
		else
			table.insert(BLACKLIST, zone)
			print(zone .. ' added to the blacklist.')
		end
	end

	if args == 'delete' then
		WHITELIST = {}
		BLACKLIST = {}
		print('Whitelist and blacklist have been deleted.')
	end

	if args == 'reset' then
		WHITELIST = WL_DEFAULT
		BLACKLIST = BL_DEFAULT
		print('Whitelist and blacklist have been reset to default.')
	end

	if args == 'show' then
		print('whitelist: ' .. table.concat(WHITELIST, ', '))
		print('blacklist: ' .. table.concat(BLACKLIST, ', '))
	end

	if args == 'verbose' then
		if VERBOSE == 0 then
			VERBOSE = 1
			print('Verbose mode enabled. A chat message will print when a talking head is blocked.')
		elseif VERBOSE == 1 then
			VERBOSE = 0
			print('Verbose mode disabled.')
		end
	end
	
	if args == 'vo on' then
		VO_ENABLED = 1
		print('VoiceOver enabled when talking head frame hidden')
	end

	if args == 'vo off' then
		VO_ENABLED = 0
		print('VoiceOver disabled when talking head frame hidden')
	end

	if args == 'vo toggle' then
		if VO_ENABLED == 1 then
			VO_ENABLED = 0
			print('VoiceOver disabled when talking head frame hidden')
		else
			VO_ENABLED = 1
			print('VoiceOver enabled when talking head frame hidden')
		end
	end

	if args == 'whitelist' then
		print('whitelist (currentzone | currentsubzone) - toggle whitelisting for the current major zone (Orgrimmar) or sub-zone (Valley of Strength).')
	end

	if args == 'blacklist' then
		print('blacklist (currentzone | currentsubzone) - toggle blacklisting for the current major zone (Orgrimmar) or sub-zone (Valley of Strength).')
	end

	if args == 'vo' then
		print ('vo (on | off | toggle) - enable or disable removal of vo seperate from hiding talking head ui')
	end

	if args == '' then
		print('BeQuiet version ' .. version)
		print('Options: on | off | toggle | verbose | whitelist | blacklist | reset | delete | show | vo')
		print('-----')
		if ENABLED == 1 then
			print('BeQuiet is currently enabled.')
		elseif ENABLED == 0 then
			print('BeQuiet is currently disabled.')
		end
		if VERBOSE == 1 then
			print('Verbose mode is currently enabled.')
		elseif VERBOSE == 0 then
			print('Verbose mode is currently disabled.')
		end
	end
end

--Add /bq to slash command list and register its function
SLASH_BQ1 = '/bq'
SlashCmdList["BQ"] = MyAddonCommands

f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", f.OnEvent)
