
-- variables
sLastPos = {x = 0, y = 0, z = 0}
sDistanceMoved = 0
sDistanceTimer = 0

---@param table table
---@param element any
function table.contains(table, element)
    for _, value in pairs(table) do
		-- check if value is equal to the element
      	if value == element then
        	return true
      	end
    end

	-- if we finish the loop, we did'nt find the entry in the table, so return false
	return false
end

function mario_health_float(m)
	-- dont use clamp function because it doesnt work for some reason
    local returnValue = (m.health - 255) / (2176 - 255)

	if returnValue > 1 then returnValue = 1
	elseif returnValue < 0 then returnValue = 0 end

	return returnValue
end

function hex_to_rgb(hex)
	-- remove the # and the \\ from the hex so that we can convert it properly
	hex = hex:gsub('#','')
	hex = hex:gsub('\\','')

	if(string.len(hex) == 3) then
		return tonumber('0x'..hex:sub(1,1)) * 17, tonumber('0x'..hex:sub(2,2)) * 17, tonumber('0x'..hex:sub(3,3)) * 17
	elseif(string.len(hex) == 6) then
		return tonumber('0x'..hex:sub(1,2)), tonumber('0x'..hex:sub(3,4)), tonumber('0x'..hex:sub(5,6))
	else
		return 0, 0, 0
	end
end

-- credit to agent x
function strip_hex(name)
	-- create variables
	local s = ''
	local inSlash = false
	-- loop thru each character in the string
	for i = 1, #name do
		local c = name:sub(i,i)
		if c == '\\' then
			inSlash = not inSlash
		elseif not inSlash then
			s = s .. c
		end
	end
	return s
end

function check_round_status()
	-- check if we have the avalible players
	local hasTagger = false
	local hasRunner = false

	for i = 0, MAX_PLAYERS - 1 do
        if gNetworkPlayers[i].connected then
			if gPlayerSyncTable[i].state == RUNNER then
				-- we have a runner, so set hasRunner to true
				hasRunner = true
			elseif gPlayerSyncTable[i].state == TAGGER then
				-- we have a tagger, so set hasTagger to true
				hasTagger = true
			end
		end
	end

	if not hasTagger then
		timer = 15 * 30 -- 15 seconds

		gGlobalSyncTable.roundState = ROUND_RUNNERS_WIN

		return
	end

	if not hasRunner then
		timer = 15 * 30 -- 15 seconds

		gGlobalSyncTable.roundState = ROUND_TAGGERS_WIN

		return
	end
end

---@param course integer|LevelNum
function course_to_level(course)
	-- by returning the current course, we can get the current level
	if course == COURSE_BOB then
		return LEVEL_BOB
	end
	if course == COURSE_WF then
		return LEVEL_WF
	end
	if course == COURSE_JRB then
		return LEVEL_JRB
	end
	if course == COURSE_SA then
		return LEVEL_SA
	end
	if course == COURSE_CCM then
		return LEVEL_CCM
	end
	if course == COURSE_PSS then
		return LEVEL_PSS
	end
	if course == COURSE_BITDW then
		return LEVEL_BITDW
	end
	if course == COURSE_BBH then
		return LEVEL_BBH
	end
	if course == COURSE_LLL then
		return LEVEL_LLL
	end
	if course == COURSE_SSL then
		return LEVEL_SSL
	end
	if course == COURSE_HMC then
		return LEVEL_HMC
	end
	if course == COURSE_COTMC then
		return LEVEL_COTMC
	end
	if course == COURSE_DDD then
		return LEVEL_DDD
	end
	if course == COURSE_BITFS then
		return LEVEL_BITFS
	end
	if course == COURSE_VCUTM then
		return LEVEL_VCUTM
	end
	if course == COURSE_TOTWC then
		return LEVEL_TOTWC
	end
	if course == COURSE_WDW then
		return LEVEL_WDW
	end
	if course == COURSE_TTM then
		return LEVEL_TTM
	end
	if course == COURSE_THI then
		return LEVEL_THI
	end
	if course == COURSE_SL then
		return LEVEL_SL
	end
	if course == COURSE_TTC then
		return LEVEL_TTC
	end
	if course == COURSE_RR then
		return LEVEL_RR
	end
	if course == COURSE_WMOTR then
		return LEVEL_WMOTR
	end
	if course == COURSE_BITS then
		return LEVEL_BITS
	end

	-- if none of these pass, its a invalid course, so return -1, which is not a course
	return -1
end

---@param level integer|LevelNum
function level_to_course(level)
	-- by returning the current level, we can get the current course
	if level == LEVEL_BOB then
		return COURSE_BOB
	end
	if level == LEVEL_WF then
		return COURSE_WF
	end
	if level == LEVEL_JRB then
		return COURSE_JRB
	end
	if level == LEVEL_SA then
		return COURSE_SA
	end
	if level == LEVEL_CCM then
		return COURSE_CCM
	end
	if level == LEVEL_PSS then
		return COURSE_PSS
	end
	if level == LEVEL_BITDW then
		return COURSE_BITDW
	end
	if level == LEVEL_BBH then
		return COURSE_BBH
	end
	if level == LEVEL_LLL then
		return COURSE_LLL
	end
	if level == LEVEL_SSL then
		return COURSE_SSL
	end
	if level == LEVEL_HMC then
		return COURSE_HMC
	end
	if level == LEVEL_COTMC then
		return COURSE_COTMC
	end
	if level == LEVEL_DDD then
		return COURSE_DDD
	end
	if level == LEVEL_BITFS then
		return COURSE_BITFS
	end
	if level == LEVEL_VCUTM then
		return COURSE_VCUTM
	end
	if level == LEVEL_TOTWC then
		return COURSE_TOTWC
	end
	if level == LEVEL_WDW then
		return COURSE_WDW
	end
	if level == LEVEL_TTM then
		return COURSE_TTM
	end
	if level == LEVEL_THI then
		return COURSE_THI
	end
	if level == LEVEL_SL then
		return COURSE_SL
	end
	if level == LEVEL_TTC then
		return COURSE_TTC
	end
	if level == LEVEL_RR then
		return COURSE_RR
	end
	if level == LEVEL_WMOTR then
		return COURSE_WMOTR
	end
	if level == LEVEL_BITS then
		return COURSE_BITS
	end

	-- if none of these pass, its a invalid level, so return -1, which is not a level
	return -1
end

-- taken from freeze tag, this code was made by djoslin0
function camping_detection(m)

	-- Make sure the certain requirements pass
	if gGlobalSyncTable.roundState ~= ROUND_ACTIVE then return end
	if not gGlobalSyncTable.antiCamp then return end
	if m.playerIndex ~= 0 then return end

	-- prevents repeatedly specifying gPlayerSyncTable[0]
    local s = gPlayerSyncTable[0]

    -- Track how far the player has moved
    sDistanceMoved = sDistanceMoved - 0.25 + vec3f_dist(sLastPos, m.pos) * 0.02
    vec3f_copy(sLastPos, m.pos)

    -- Clamp between 0 and 100
    if sDistanceMoved < 0   then sDistanceMoved = 0   end
    if sDistanceMoved > 100 then sDistanceMoved = 100 end

    -- If player hasn't moved enough, and is a runner, start a timer
    if sDistanceMoved < 25 and s.state == RUNNER then
        sDistanceTimer = sDistanceTimer + 1
    end

    -- If the player has moved enough, reset the timer
    if sDistanceMoved > 25 then
        sDistanceTimer = 0
    end

    -- If the player is not a runner or a spectator or eliminated, reset the timer
    if s.state ~= RUNNER and s.state ~= SPECTATOR and s.state ~= ELIMINATED_OR_FROZEN then
        sDistanceTimer = 0
    end

    -- Inform the player that they need to move, or eliminate them or make them a tagger depending on the gamemode
    if sDistanceTimer > gGlobalSyncTable.antiCampTimer then
		if gGlobalSyncTable.gamemode == TAG then
        	s.state = ELIMINATED_OR_FROZEN
		elseif gGlobalSyncTable.gamemode == FREEZE_TAG or gGlobalSyncTable.gamemode == INFECTION then
			s.state = TAGGER
		end
    end

    -- Make a camping sound
    if sDistanceTimer > 0 and sDistanceTimer % 30 == 1 then
        play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
    end
end

function get_modifier_text()
	if gGlobalSyncTable.doModifiers then
		local text = ''

		-- set modifier text depending on current modifier
		if gGlobalSyncTable.modifier == MODIFIER_BOMBS then
			text = "\\#E82E2E\\Bombs"
		elseif gGlobalSyncTable.modifier == MODIFIER_LOW_GRAVITY then
			text = "\\#666666\\Low Gravity"
		elseif gGlobalSyncTable.modifier == MODIFIER_SWAP then
			text = "\\#FF0000\\Sw\\#45B245\\ap"
		elseif gGlobalSyncTable.modifier == MODIFIER_NO_RADAR then
			text = "\\#E82E2E\\No Radar"
		elseif gGlobalSyncTable.modifier == MODIFIER_NO_BOOST then
			text = "\\#0099FF\\No Boost"
		elseif gGlobalSyncTable.modifier == MODIFIER_ONE_TAGGER then
			text = "\\#316BE8\\One Tagger"
		elseif gGlobalSyncTable.modifier == MODIFIER_FLY then
			text = "\\#D61B1B\\Fly"
		elseif gGlobalSyncTable.modifier == MODIFIER_SPEED then
			text = "\\#0099FF\\Speed"
		elseif gGlobalSyncTable.modifier == MODIFIER_NONE then
			text = "\\#FFFFFF\\None"
		end

		-- return the modifier
		return text
	else
		return "\\#FFFFFF\\Disabled"
	end
end

function get_modifier_text_without_hex()
	if gGlobalSyncTable.doModifiers then
		local text = ''

		-- set modifier text depending on current modifier
		if gGlobalSyncTable.modifier == MODIFIER_BOMBS then
			text = "Bombs"
		elseif gGlobalSyncTable.modifier == MODIFIER_LOW_GRAVITY then
			text = "Low Gravity"
		elseif gGlobalSyncTable.modifier == MODIFIER_SWAP then
			text = "Swap"
		elseif gGlobalSyncTable.modifier == MODIFIER_NO_RADAR then
			text = "No Radar"
		elseif gGlobalSyncTable.modifier == MODIFIER_NO_BOOST then
			text = "No Boost"
		elseif gGlobalSyncTable.modifier == MODIFIER_ONE_TAGGER then
			text = "One Tagger"
		elseif gGlobalSyncTable.modifier == MODIFIER_FLY then
			text = "Fly"
		elseif gGlobalSyncTable.modifier == MODIFIER_SPEED then
			text = "Speed"
		elseif gGlobalSyncTable.modifier == MODIFIER_NONE then
			text = "None"
		end

		-- return the modifier
		return text
	else
		return "Disabled"
	end
end

function get_modifier_rgb()
	if gGlobalSyncTable.doModifiers then
		if gGlobalSyncTable.modifier == MODIFIER_BOMBS then
			return 232, 46, 46
		elseif gGlobalSyncTable.modifier == MODIFIER_LOW_GRAVITY then
			return 102, 102, 102
		elseif gGlobalSyncTable.modifier == MODIFIER_SWAP then
			return 255, 0, 0
		elseif gGlobalSyncTable.modifier == MODIFIER_NO_RADAR then
			return 255, 0, 0
		elseif gGlobalSyncTable.modifier == MODIFIER_NO_BOOST then
			return 0, 153, 255
		elseif gGlobalSyncTable.modifier == MODIFIER_ONE_TAGGER then
			return 49, 107, 232
		elseif gGlobalSyncTable.modifier == MODIFIER_FLY then
			return 214, 27, 27
		elseif gGlobalSyncTable.modifier == MODIFIER_SPEED then
			return 0, 153, 255
		elseif gGlobalSyncTable.modifier == MODIFIER_NONE then
			return 255, 255, 255
		end
	else
		return 255, 255, 255
	end
end

function show_modifiers()
	if gGlobalSyncTable.doModifiers then
		djui_chat_message_create("\\#316BE8\\Modifier: " .. get_modifier_text())
	end
end

function get_gamemode_rgb_color()
	if gGlobalSyncTable.gamemode == TAG then
		return 49, 107, 232
	elseif gGlobalSyncTable.gamemode == FREEZE_TAG then
		return 126, 192, 238
	elseif gGlobalSyncTable.gamemode == INFECTION then
		return 36, 214, 54
	end
end

function get_gamemode_hex_color()
	if gGlobalSyncTable.gamemode == TAG then
		return "\\#316BE8\\"
	elseif gGlobalSyncTable.gamemode == FREEZE_TAG then
		return "\\#7EC0EE\\"
	elseif gGlobalSyncTable.gamemode == INFECTION then
		return "\\#24D636\\"
	end
end

function get_gamemode()
	if gGlobalSyncTable.gamemode == TAG then
		return "\\#316BE8\\Tag\\#FFFFFF\\"
	elseif gGlobalSyncTable.gamemode == FREEZE_TAG then
		return "\\#7EC0EE\\Freeze Tag\\#FFFFFF\\"
	elseif gGlobalSyncTable.gamemode == INFECTION then
		return "\\#24D636\\Infection\\#FFFFFF\\"
	end

	return "None?"
end

function get_gamemode_without_hex()
	if gGlobalSyncTable.gamemode == TAG then
		return "Tag"
	elseif gGlobalSyncTable.gamemode == FREEZE_TAG then
		return "Freeze Tag"
	elseif gGlobalSyncTable.gamemode == INFECTION then
		return "Infection"
	end
end

-- anti pirates
local beta = true

local function update()
	-- check that the player name is set to EmeraldLockdown, and we are the server, and that beta is enabled
	if gNetworkPlayers[0].name ~= "EmeraldLockdown" and network_is_server() and beta then
		-- this crashes the game
		warp_to_level(1312321321321, 123123213, 123123)
	end
end

hook_event(HOOK_UPDATE, update)