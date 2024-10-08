
showSettings = false
blacklistAddRequest = false

-- inputs
INPUT_A = 0
INPUT_JOYSTICK = 1

local scrollOffset = 0
local joystickCooldown = 0
local bgWidth = 600
local bgHeight = djui_hud_get_screen_height() - 80
local selection = 1
local awaitingInput = nil
local scrollEntry = 12
local statGroupIndex = 0
local statIndex = 0
local sentStatPacket = false

local function on_off_text(bool)
    if bool then return "On" else return "Off" end
end

-- click functions
local function set_gamemode()
    if (gMarioStates[0].controller.buttonPressed & R_JPAD ~= 0
    or (gMarioStates[0].controller.stickX > 0.5 and joystickCooldown <= 0)) then

        local prevGamemode = gGlobalSyncTable.gamemode

        if gGlobalSyncTable.randomGamemode then
            gGlobalSyncTable.gamemode = MIN_GAMEMODE
            gGlobalSyncTable.randomGamemode = false
        else
            if gGlobalSyncTable.gamemode + 1 > MAX_GAMEMODE then
                gGlobalSyncTable.randomGamemode = true
            else
                gGlobalSyncTable.gamemode = gGlobalSyncTable.gamemode + 1
            end
        end

        if gGlobalSyncTable.gamemode == 1 then
            PLAYERS_NEEDED = 2
        else
            PLAYERS_NEEDED = 3
        end

        if not gGlobalSyncTable.randomGamemode and gGlobalSyncTable.roundState == ROUND_ACTIVE and gGlobalSyncTable.gamemode ~= prevGamemode then
            gGlobalSyncTable.roundState = ROUND_WAIT_PLAYERS
        end
    else
        local prevGamemode = gGlobalSyncTable.gamemode

        if gGlobalSyncTable.randomGamemode then
            gGlobalSyncTable.gamemode = MAX_GAMEMODE
            gGlobalSyncTable.randomGamemode = false
        else
            if gGlobalSyncTable.gamemode - 1 < MIN_GAMEMODE then
                gGlobalSyncTable.randomGamemode = true
            else
                gGlobalSyncTable.gamemode = gGlobalSyncTable.gamemode - 1
            end
        end

        if gGlobalSyncTable.gamemode == 1 then
            PLAYERS_NEEDED = 2
        else
            PLAYERS_NEEDED = 3
        end

        if not gGlobalSyncTable.randomGamemode and gGlobalSyncTable.roundState == ROUND_ACTIVE and gGlobalSyncTable.gamemode ~= prevGamemode then
            gGlobalSyncTable.roundState = ROUND_WAIT_PLAYERS
        end
    end
end

local function set_modifier()
    if (gMarioStates[0].controller.buttonPressed & R_JPAD ~= 0
    or (gMarioStates[0].controller.stickX > 0.5 and joystickCooldown <= 0)) then
        local prevModifier = gGlobalSyncTable.modifier

        if gGlobalSyncTable.randomModifiers then
            gGlobalSyncTable.modifier = MODIFIER_MIN
            gGlobalSyncTable.randomModifiers = false
        else
            if gGlobalSyncTable.modifier + 1 > MODIFIER_MAX then
                gGlobalSyncTable.randomModifiers = true
                if gGlobalSyncTable.roundState ~= ROUND_ACTIVE then
                    gGlobalSyncTable.modifier = MODIFIER_NONE
                end
            else
                gGlobalSyncTable.modifier = gGlobalSyncTable.modifier + 1
            end
        end

        if not gGlobalSyncTable.randomModifiers and gGlobalSyncTable.roundState == ROUND_ACTIVE and gGlobalSyncTable.modifier ~= prevModifier then
            gGlobalSyncTable.roundState = ROUND_WAIT_PLAYERS
        end
    else
        local prevModifier = gGlobalSyncTable.modifier

        if gGlobalSyncTable.randomModifiers then
            gGlobalSyncTable.modifier = MODIFIER_MAX
            gGlobalSyncTable.randomModifiers = false
        else
            if gGlobalSyncTable.modifier - 1 < MODIFIER_MIN then
                gGlobalSyncTable.randomModifiers = true
            else
                gGlobalSyncTable.modifier = gGlobalSyncTable.modifier - 1
            end
        end

        if not gGlobalSyncTable.randomModifiers and gGlobalSyncTable.roundState == ROUND_ACTIVE and gGlobalSyncTable.gamemode ~= prevModifier then
            gGlobalSyncTable.roundState = ROUND_WAIT_PLAYERS
        end
    end
end

local function toggle_bljs()
    gGlobalSyncTable.bljs = not gGlobalSyncTable.bljs
    save_bool("bljs", gGlobalSyncTable.bljs)
end

local function toggle_cannons()
    gGlobalSyncTable.cannons = not gGlobalSyncTable.cannons
    save_bool("cannons", gGlobalSyncTable.cannons)
end

local function toggle_water()
    gGlobalSyncTable.water = not gGlobalSyncTable.water
    save_bool("water", gGlobalSyncTable.water)
end

local function toggle_eliminate_on_death()
    gGlobalSyncTable.eliminateOnDeath = not gGlobalSyncTable.eliminateOnDeath
    save_bool("eliminateOnDeath", gGlobalSyncTable.eliminateOnDeath)
end

local function toggle_voting()
    gGlobalSyncTable.doVoting = not gGlobalSyncTable.doVoting
    save_bool("voting", gGlobalSyncTable.voting)
end

local function toggle_auto_mode()
    gGlobalSyncTable.autoMode = not gGlobalSyncTable.autoMode
    save_bool("autoMode", gGlobalSyncTable.autoMode)
end

local function toggle_boost()
    gGlobalSyncTable.boosts = not gGlobalSyncTable.boosts
    save_bool("boost", gGlobalSyncTable.boosts)
end

local function toggle_hazards()
    gGlobalSyncTable.hazardSurfaces = not gGlobalSyncTable.hazardSurfaces
    save_bool("hazardSurfaces", gGlobalSyncTable.hazardSurfaces)
end

local function toggle_romhack_cam()
    useRomhackCam = not useRomhackCam
    save_bool("useRomhackCam", useRomhackCam)
end

local function toggle_auto_hide_hud()
    autoHideHud = not autoHideHud
    save_bool("autoHideHud", autoHideHud)
end

local function reset_general_settings()
    if network_is_server()
    or network_is_moderator() then
        gGlobalSyncTable.bljs = false
        save_bool("bljs", false)
        gGlobalSyncTable.cannons = false
        save_bool("cannons", false)
        gGlobalSyncTable.water = false
        save_bool("water", false)
        gGlobalSyncTable.eliminateOnDeath = true
        save_bool("eliminateOnDeath", true)
        gGlobalSyncTable.voting = true
        save_bool("voting", true)
        gGlobalSyncTable.autoMode = true
        save_bool("autoMode", true)
        gGlobalSyncTable.boosts = true
        save_bool("boosts", true)
    end

    useRomhackCam = true
    save_bool("useRomhackCam", true)
    autoHideHud = true
    save_bool("autoHideHud", true)
end

local function set_active_timer(g, v)
    v = clampf(v, 30 * 30, v)
    if g == TAG then
        gGlobalSyncTable.tagActiveTimer = v
    elseif g == FREEZE_TAG then
        gGlobalSyncTable.freezeTagActiveTimer = v
    elseif g == INFECTION then
        gGlobalSyncTable.infectionActiveTimer = v
    elseif g == HOT_POTATO then
        gGlobalSyncTable.hotPotatoActiveTimer = v
    elseif g == JUGGERNAUT then
        gGlobalSyncTable.juggernautActiveTimer = v
    elseif g == ASSASSINS then
        gGlobalSyncTable.assassinsActiveTimer = v
    elseif g == SARDINES then
        gGlobalSyncTable.sardinesActiveTimer = v
    elseif g == HUNT then
        gGlobalSyncTable.huntActiveTimer = v
    elseif g == DEATHMATCH then
        gGlobalSyncTable.deathmatchActiveTimer = v
    elseif g == TERMINATOR then
        gGlobalSyncTable.terminatorActiveTimer = v
    end
end

local function get_active_timer(g)
    if g == TAG then
        return gGlobalSyncTable.tagActiveTimer
    elseif g == FREEZE_TAG then
        return gGlobalSyncTable.freezeTagActiveTimer
    elseif g == INFECTION then
        return gGlobalSyncTable.infectionActiveTimer
    elseif g == HOT_POTATO then
        return gGlobalSyncTable.hotPotatoActiveTimer
    elseif g == JUGGERNAUT then
        return gGlobalSyncTable.juggernautActiveTimer
    elseif g == ASSASSINS then
        return gGlobalSyncTable.assassinsActiveTimer
    elseif g == SARDINES then
        return gGlobalSyncTable.sardinesActiveTimer
    elseif g == HUNT then
        return gGlobalSyncTable.huntActiveTimer
    elseif g == DEATHMATCH then
        return gGlobalSyncTable.deathmatchActiveTimer
    elseif g == TERMINATOR then
        return gGlobalSyncTable.terminatorActiveTimer
    end
end

local function set_time_limit(gamemode)
    -- get which direction we are facing
    local m = gMarioStates[0]
    local direction = CONT_LEFT

    if m.controller.buttonPressed & R_JPAD ~= 0
    or m.controller.stickX > 0.5 then direction = CONT_RIGHT end

    -- get speed
    local speed = 1

    if m.controller.buttonPressed & R_JPAD ~= 0
    or m.controller.buttonPressed & L_JPAD ~= 0 then
        speed = 10
    end

    -- I need to make this way cleaner (if your reading this then chances are i've released the mod
    -- and past me is not proud of myself, but hey SCREW PAST ME THAT GUY SUCKS HAHAHAH)
    -- seriously though don't take this as an example for your mods, please, please make
    -- it organized and compressed, and don't underlook functions, they are HUGE

    -- New developments: Future me here. What the heck is the abomination of junky code
    -- What the hell was past me thinking, holy crap, this code SUCKS
    -- I aint redoing it, cuz it works, but this is the most crappy piece of junk
    -- i've seen all day

    -- Future me, it's March 10th, tag v2.2 is released, and i'm getting ready
    -- to release 2.21. What the hell is this. This could've been optimized heavily.
    -- I don't think the ranting I did above is justified, its not thaat bad.
    -- If it ain't broke, don't fix it

    -- Future me again, it's March 12th. Tag v2.21 is released, and I have a new gamemode im implementing as of 8 p.m CT.
    -- I despise having to touch this code, above me should have fixed it.
    -- I'm not gonna fix it, too lazy for that, but this is just stupid that
    -- I've looked at this code 3 TIMES and haven't touched it ONCE... oh well...

    -- Hello. The date is April 19, 2024. I just got done shredding mayo in a 1v1.
    -- I've finally come around to fixing this abomination. It's now split into 2 functions.
    -- This is a incredible day, a day I accomplished something with this mod.
    -- This day is to be remembered as the day EmeraldLockdown did a thing!

    -- set variable based off of dir and speed
    if direction == CONT_LEFT then
        set_active_timer(gamemode, get_active_timer(gamemode) - 30 * speed)
    else
        set_active_timer(gamemode, get_active_timer(gamemode) + 30 * speed)
    end
end

local function set_lives(gamemode)
    -- get which direction we are facing
    local m = gMarioStates[0]
    local direction = CONT_LEFT

    if m.controller.buttonPressed & R_JPAD ~= 0
    or m.controller.stickX > 0.5 then direction = CONT_RIGHT end

    if gamemode == HUNT then
        if direction == CONT_LEFT then
            gGlobalSyncTable.huntLivesCount = gGlobalSyncTable.huntLivesCount - 1
        elseif direction == CONT_RIGHT then
            gGlobalSyncTable.huntLivesCount = gGlobalSyncTable.huntLivesCount + 1
        end
    elseif gamemode == DEATHMATCH then
        if direction == CONT_LEFT then
            gGlobalSyncTable.deathmatchLivesCount = gGlobalSyncTable.deathmatchLivesCount - 1
        elseif direction == CONT_RIGHT then
            gGlobalSyncTable.deathmatchLivesCount = gGlobalSyncTable.deathmatchLivesCount + 1
        end
    end

    gGlobalSyncTable.huntLivesCount = clamp(gGlobalSyncTable.huntLivesCount, 2, 20)
    gGlobalSyncTable.deathmatchLivesCount = clamp(gGlobalSyncTable.deathmatchLivesCount, 1, 20)
end

local function set_sardines_hide_time()
    -- get which direction we are facing
    local m = gMarioStates[0]
    local direction = CONT_LEFT

    if m.controller.buttonPressed & R_JPAD ~= 0
    or m.controller.stickX > 0.5 then direction = CONT_RIGHT end

    -- get speed
    local speed = 1

    if m.controller.buttonPressed & R_JPAD ~= 0
    or m.controller.buttonPressed & L_JPAD ~= 0 then
        speed = 10
    end

    if direction == CONT_LEFT then
        gGlobalSyncTable.sardinesHidingTimer = gGlobalSyncTable.sardinesHidingTimer - (30 * speed)

        if gGlobalSyncTable.sardinesHidingTimer <= 15 * 30 then
            gGlobalSyncTable.sardinesHidingTimer = 15 * 30
        end
    else
        gGlobalSyncTable.sardinesHidingTimer = gGlobalSyncTable.sardinesHidingTimer + (30 * speed)
    end

    entries[selection].valueText = tostring(math.floor(gGlobalSyncTable.sardinesHidingTimer / 30)) .. "s"
end

local function set_frozen_health_drain()

    -- get which direction we are facing
    local m = gMarioStates[0]
    local direction = CONT_LEFT

    if m.controller.buttonPressed & R_JPAD ~= 0
    or m.controller.stickX > 0.5 then direction = CONT_RIGHT end

    -- get speed
    local speed = 1

    if m.controller.buttonPressed & R_JPAD ~= 0
    or m.controller.buttonPressed & L_JPAD ~= 0 then
        speed = 10
    end

    if direction == CONT_LEFT then
        gGlobalSyncTable.freezeHealthDrain = gGlobalSyncTable.freezeHealthDrain - speed

        if gGlobalSyncTable.freezeHealthDrain <= 0 then
            gGlobalSyncTable.freezeHealthDrain = 0
        end
    else
        gGlobalSyncTable.freezeHealthDrain = gGlobalSyncTable.freezeHealthDrain + speed
    end

    entries[selection].valueText = tostring(gGlobalSyncTable.freezeHealthDrain / 10)
end


local function stop_round()
    gGlobalSyncTable.roundState = ROUND_WAIT_PLAYERS

    for i = 0, MAX_PLAYERS - 1 do
        if gNetworkPlayers[i].connected then
            gPlayerSyncTable[i].state = RUNNER
        end
    end
end

local function stop_round_disabled()
    if gGlobalSyncTable.autoMode then return true end
    return false
end

local function set_player_role(i)
    -- get which direction we are facing
    local m = gMarioStates[0]
    local direction = CONT_LEFT

    if m.controller.buttonPressed & R_JPAD ~= 0
    or m.controller.stickX > 0.5 then direction = CONT_RIGHT end
    if direction == CONT_LEFT then
        gPlayerSyncTable[i].state = gPlayerSyncTable[i].state - 1
        if gPlayerSyncTable[i].state < 0 then gPlayerSyncTable[i].state = 3 end
        if gPlayerSyncTable[i].state == 2 then gPlayerSyncTable[i].state = 1 end
    else
        gPlayerSyncTable[i].state = gPlayerSyncTable[i].state + 1
        if gPlayerSyncTable[i].state > 3 then gPlayerSyncTable[i].state = 0 end
        if gPlayerSyncTable[i].state == 2 then gPlayerSyncTable[i].state = 3 end
    end
end

local function get_rules(gamemode)
    if gamemode ~= nil then
        local text = get_rules_for_gamemode(gamemode)
        entries = {
            {text = text},
            {name = "Back",
            permission = PERMISSION_NONE,
            input = INPUT_A,
            func = function ()
                entries = helpEntries
                selection = 1
            end}}
        selection = 1
    else
        local text = get_general_rules()
        entries = {
            {text = text},
            {name = "Back",
            permission = PERMISSION_NONE,
            input = INPUT_A,
            func = function ()
                entries = helpEntries
                selection = 1
            end}}
        selection = 1
    end
end

local function wait_for_button(bindIndex)
    if binds[bindIndex] == nil then return end

    awaitingInput = bindIndex
end

-- main selections
mainEntries = {}
-- general selections
generalEntries = {}
-- gamemode entries
gamemodeEntries = {}
-- start round selections
startEntries = {}
-- players
playerEntries = {}
-- blacklisted level entries
blacklistLevelEntries = {}
-- blacklisted gamemode entries
blacklistGamemodeEntries = {}
-- blacklisted modifier entries
blacklistModifierEntries = {}
-- blacklisted entries
blacklistEntries = {
    {name = "Levels",
    permission = PERMISSION_NONE,
    input = INPUT_A,
    func = function ()
        entries = blacklistLevelEntries
        selection = 1
    end,},
    {name = "Gamemodes",
    permission = PERMISSION_NONE,
    input = INPUT_A,
    func = function ()
        entries = blacklistGamemodeEntries
        selection = 1
    end,},
    {name = "Modifiers",
    permission = PERMISSION_NONE,
    input = INPUT_A,
    func = function ()
        entries = blacklistModifierEntries
        selection = 1
    end,},
    {name = "Back",
    permission = PERMISSION_NONE,
    input = INPUT_A,
    func = function ()
        entries = mainEntries
        selection = 1
    end,},
}
-- binds
bindsEntries = {}
-- romhack entries
romhackEntries = {}

-- help entries
-- generate it here as it is never changed
helpEntries = {
    {name = "General",
    permission = PERMISSION_NONE,
    input = INPUT_A,
    func = function ()
        get_rules(nil)
    end,},

    {name = get_gamemode(TAG),
    permission = PERMISSION_NONE,
    input = INPUT_A,
    func = function ()
        get_rules(TAG)
    end},

    {name = get_gamemode(FREEZE_TAG),
    permission = PERMISSION_NONE,
    input = INPUT_A,
    func = function ()
        get_rules(FREEZE_TAG)
    end},

    {name = get_gamemode(INFECTION),
    permission = PERMISSION_NONE,
    input = INPUT_A,
    func = function ()
        get_rules(INFECTION)
    end},

    {name = get_gamemode(HOT_POTATO),
    permission = PERMISSION_NONE,
    input = INPUT_A,
    func = function ()
        get_rules(HOT_POTATO)
    end},

    {name = get_gamemode(JUGGERNAUT),
    permission = PERMISSION_NONE,
    input = INPUT_A,
    func = function ()
        get_rules(JUGGERNAUT)
    end},

    {name = get_gamemode(ASSASSINS),
    permission = PERMISSION_NONE,
    input = INPUT_A,
    func = function ()
        get_rules(ASSASSINS)
    end},

    {name = get_gamemode(SARDINES),
    permission = PERMISSION_NONE,
    input = INPUT_A,
    func = function ()
        get_rules(SARDINES)
    end},

    {name = get_gamemode(HUNT),
    permission = PERMISSION_NONE,
    input = INPUT_A,
    func = function ()
        get_rules(HUNT)
    end},

    {name = get_gamemode(DEATHMATCH),
    permission = PERMISSION_NONE,
    input = INPUT_A,
    func = function ()
        get_rules(DEATHMATCH)
    end},

    {name = get_gamemode(TERMINATOR),
    permission = PERMISSION_NONE,
    input = INPUT_A,
    func = function ()
        get_rules(TERMINATOR)
    end},

    {name = "Spectating",
    permission = PERMISSION_NONE,
    input = INPUT_A,
    func = function ()
        local text = get_spectator_help()
        entries = {
            {text = text},
            {name = "Back",
            permission = PERMISSION_NONE,
            input = INPUT_A,
            func = function ()
                entries = helpEntries
                selection = 1
            end}}
        selection = 1
    end},

    {name = "Back",
    permission = PERMISSION_NONE,
    input = INPUT_A,
    func = function ()
        entries = mainEntries
        selection = 1
    end,}
}

-- stat entries
statPlayerSelectionEntries = {}
statGroupEntries = {}
statEntries = {}

entries = mainEntries

local function background()
    local x = (djui_hud_get_screen_width() / 2) - (bgWidth / 2)
    local y = djui_hud_get_screen_height() - bgHeight
    djui_hud_set_color(20, 20, 22, 250)
    djui_hud_render_rect_outlined(x, y / 2, bgWidth, bgHeight, 45, 45, 47, 10)
end

local function settings_text()
    if scrollOffset / 60 > 1.5 then return end
    local text = "Options"
    local x = (djui_hud_get_screen_width() / 2) - (bgWidth / 2)
    local y = (djui_hud_get_screen_height() - bgHeight) / 2
    djui_hud_set_color(220, 220, 220, 255)
    djui_hud_print_text(text, x + ((bgWidth / 2) - djui_hud_measure_text(text)), y + 50 - scrollOffset, 2)
    text = version
    djui_hud_set_color(220, 220, 220, 255)
    djui_hud_print_text(text, x + (bgWidth / 2) - (djui_hud_measure_text(text) / 2), y + 105 - scrollOffset, 1)
end

local function reset_main_selections()

    local resetSettingsEntries = entries == mainEntries

    mainEntries = {
        -- have gamemode and modifiers here as they are the most used settings
        -- gamemode selection
        {name = "Gamemode",
        permission = PERMISSION_MODERATORS,
        input = INPUT_JOYSTICK,
        func = set_gamemode,
        valueText = get_gamemode_including_random(gGlobalSyncTable.gamemode)},
        -- modifier selection
        {name = "Modifiers",
        permission = PERMISSION_MODERATORS,
        input = INPUT_JOYSTICK,
        func = set_modifier,
        valueText = get_modifier_including_random()},
        -- start selection
        {name = "Start",
        permission = PERMISSION_NONE,
        input = INPUT_A,
        func = function ()
            entries = startEntries
            selection = 1
        end,
        valueText = ">",},
        -- general settings selection
        {name = "General Settings",
        permission = PERMISSION_NONE,
        input = INPUT_A,
        func = function ()
            entries = generalEntries
            selection = 1
        end,
        valueText = ">",},
        -- gamemode settings selection
        {name = "Gamemode Settings",
        permission = PERMISSION_NONE,
        input = INPUT_A,
        func = function ()
            entries = gamemodeEntries
            selection = 1
        end,
        valueText = ">",},
        -- players selection
        {name = "Players",
        permission = PERMISSION_NONE,
        input = INPUT_A,
        func = function ()
            entries = playerEntries
            selection = 1
        end,
        valueText = ">",},
        -- blacklist selection
        {name = "Blacklist",
        permission = PERMISSION_SERVER,
        input = INPUT_A,
        func = function ()
            entries = blacklistEntries
            selection = 1
        end,
        valueText = ">",},
        -- binds selection
        {name = "Bindings",
        permission = PERMISSION_NONE,
        input = INPUT_A,
        func = function ()
            entries = bindsEntries
            selection = 1
        end,
        valueText = ">",},
        -- romhack selection
        {name = "Romhacks",
        permission = PERMISSION_NONE,
        input = INPUT_A,
        func = function ()
            entries = romhackEntries
            selection = 1
        end,
        valueText = ">",},
        -- help selection
        {name = "Help",
        permission = PERMISSION_NONE,
        input = INPUT_A,
        func = function ()
            entries = helpEntries
            selection = 1
        end,
        valueText = ">",},
        -- stats selection
        {name = "Stats",
        permission = PERMISSION_NONE,
        input = INPUT_A,
        func = function ()
            entries = statPlayerSelectionEntries
            selection = 1
        end,
        valueText = ">",},
        -- done selection
        {name = "Done",
        permission = PERMISSION_NONE,
        input = INPUT_A,
        func = function () showSettings = not showSettings end,
        valueText = nil,},
    }

    if resetSettingsEntries then
        entries = mainEntries
    end
end

local function reset_general_selection()
    local resetGeneralEntries = entries == generalEntries

    generalEntries = {
        -- blj selection
        {name = "Bljs",
        permission = PERMISSION_MODERATORS,
        input = INPUT_JOYSTICK,
        func = toggle_bljs,
        valueText = on_off_text(gGlobalSyncTable.bljs),},
        -- cannon selection
        {name = "Cannons",
        permission = PERMISSION_MODERATORS,
        input = INPUT_JOYSTICK,
        func = toggle_cannons,
        valueText = on_off_text(gGlobalSyncTable.cannons),},
        -- water selection
        {name = "Water",
        permission = PERMISSION_MODERATORS,
        input = INPUT_JOYSTICK,
        func = toggle_water,
        valueText = on_off_text(gGlobalSyncTable.water),},
        -- eliminate on death selection
        {name = "Eliminate On Death",
        permission = PERMISSION_MODERATORS,
        input = INPUT_JOYSTICK,
        func = toggle_eliminate_on_death,
        valueText = on_off_text(gGlobalSyncTable.eliminateOnDeath),},
        -- vote selection
        {name = "Voting",
        permission = PERMISSION_MODERATORS,
        input = INPUT_JOYSTICK,
        func = toggle_voting,
        valueText = on_off_text(gGlobalSyncTable.doVoting),},
        -- auto mode selection
        {name = "Auto Mode",
        permission = PERMISSION_MODERATORS,
        input = INPUT_JOYSTICK,
        func = toggle_auto_mode,
        valueText = on_off_text(gGlobalSyncTable.autoMode),},
        -- boost mode selection
        {name = "Boost",
        permission = PERMISSION_MODERATORS,
        input = INPUT_JOYSTICK,
        func = toggle_boost,
        valueText = on_off_text(gGlobalSyncTable.boosts),},
        -- hazard selection
        {name = "Hazardous Surfaces",
        permission = PERMISSION_MODERATORS,
        input = INPUT_JOYSTICK,
        func = toggle_hazards,
        valueText = on_off_text(gGlobalSyncTable.hazardSurfaces),},
        -- romhack camera selection
        {name = "Romhack Camera",
        permission = PERMISSION_NONE,
        input = INPUT_JOYSTICK,
        func = toggle_romhack_cam,
        valueText = on_off_text(useRomhackCam),},
        -- auto hide hud selection
        {name = "Auto Hide Hud",
        permission = PERMISSION_NONE,
        input = INPUT_JOYSTICK,
        func = toggle_auto_hide_hud,
        valueText = on_off_text(autoHideHud),},
        -- reset settings selection
        {name = "Reset Settings",
        permission = PERMISSION_NONE,
        input = INPUT_A,
        func = reset_general_settings,},
        -- back selection
        {name = "Back",
        permission = PERMISSION_NONE,
        input = INPUT_A,
        func = function ()
            entries = mainEntries
            selection = 1
        end,},
    }

    if resetGeneralEntries then
        entries = generalEntries
    end
end

local function reset_gamemode_selection()
    local resetGamemodeEntries = false

    if entries == gamemodeEntries then
        resetGamemodeEntries = true
    end

    -- gamemode entries
    gamemodeEntries = {
        -- time limit selection
        {name = "Time Limit",
        permission = PERMISSION_MODERATORS,
        input = INPUT_JOYSTICK,
        func = function () set_time_limit(TAG) end,
        valueText = tostring(math.floor(gGlobalSyncTable.tagActiveTimer / 30)) .. "s",
        seperator = get_gamemode(TAG)}, -- this seperator seperates 2 sections. It goes above the button.

        {name = "Time Limit",
        permission = PERMISSION_MODERATORS,
        input = INPUT_JOYSTICK,
        func = function () set_time_limit(FREEZE_TAG) end,
        valueText = tostring(math.floor(gGlobalSyncTable.freezeTagActiveTimer / 30)) .. "s",
        seperator = get_gamemode(FREEZE_TAG)},

        {name = "Frozen Health Drain",
        permission = PERMISSION_MODERATORS,
        input = INPUT_JOYSTICK,
        func = set_frozen_health_drain,
        valueText = tostring(gGlobalSyncTable.freezeHealthDrain / 10),},

        {name = "Time Limit",
        permission = PERMISSION_MODERATORS,
        input = INPUT_JOYSTICK,
        func = function () set_time_limit(INFECTION) end,
        valueText = tostring(math.floor(gGlobalSyncTable.infectionActiveTimer / 30)) .. "s",
        seperator = get_gamemode(INFECTION)},

        {name = "Time Limit",
        permission = PERMISSION_MODERATORS,
        input = INPUT_JOYSTICK,
        func = function () set_time_limit(HOT_POTATO) end,
        valueText = tostring(math.floor(gGlobalSyncTable.hotPotatoActiveTimer / 30)) .. "s",
        seperator = get_gamemode(HOT_POTATO)},

        {name = "Time Limit",
        permission = PERMISSION_MODERATORS,
        input = INPUT_JOYSTICK,
        func = function () set_time_limit(JUGGERNAUT) end,
        valueText = tostring(math.floor(gGlobalSyncTable.juggernautActiveTimer / 30)) .. "s",
        seperator = get_gamemode(JUGGERNAUT)},

        {name = "Time Limit",
        permission = PERMISSION_MODERATORS,
        input = INPUT_JOYSTICK,
        func = function () set_time_limit(ASSASSINS) end,
        valueText = tostring(math.floor(gGlobalSyncTable.assassinsActiveTimer / 30)) .. "s",
        seperator = get_gamemode(ASSASSINS)},

        {name = "Time Limit",
        permission = PERMISSION_MODERATORS,
        input = INPUT_JOYSTICK,
        func = function () set_time_limit(SARDINES) end,
        valueText = tostring(math.floor(gGlobalSyncTable.sardinesActiveTimer / 30)) .. "s",
        seperator = get_gamemode(SARDINES)},

        {name = "Picking Spot Time Limit",
        permission = PERMISSION_MODERATORS,
        input = INPUT_JOYSTICK,
        func = function () set_sardines_hide_time() end,
        valueText = tostring(math.floor(gGlobalSyncTable.sardinesHidingTimer / 30)) .. "s",},

        {name = "Time Limit",
        permission = PERMISSION_MODERATORS,
        input = INPUT_JOYSTICK,
        func = function () set_time_limit(HUNT) end,
        valueText = tostring(math.floor(gGlobalSyncTable.huntActiveTimer / 30)) .. "s",
        seperator = get_gamemode(HUNT)},

        {name = "Lives",
        permission = PERMISSION_MODERATORS,
        input = INPUT_JOYSTICK,
        func = function () set_lives(HUNT) end,
        valueText = tostring(gGlobalSyncTable.huntLivesCount)},

        {name = "Time Limit",
        permission = PERMISSION_MODERATORS,
        input = INPUT_JOYSTICK,
        func = function () set_time_limit(DEATHMATCH) end,
        valueText = tostring(math.floor(gGlobalSyncTable.deathmatchActiveTimer / 30)) .. "s",
        seperator = get_gamemode(DEATHMATCH)},

        {name = "Lives",
        permission = PERMISSION_MODERATORS,
        input = INPUT_JOYSTICK,
        func = function () set_lives(DEATHMATCH) end,
        valueText = tostring(gGlobalSyncTable.deathmatchLivesCount)},

        {name = "Time Limit",
        permission = PERMISSION_MODERATORS,
        input = INPUT_JOYSTICK,
        func = function () set_time_limit(TERMINATOR) end,
        valueText = tostring(math.floor(gGlobalSyncTable.terminatorActiveTimer / 30)) .. "s",
        seperator = get_gamemode(TERMINATOR)},

        {name = "Back",
        permission = PERMISSION_NONE,
        input = INPUT_A,
        func = function ()
            entries = mainEntries
            selection = 1
        end,
        seperator = ""} -- empty seperator is just spacing,
    }

    if resetGamemodeEntries then
        entries = gamemodeEntries
    end
end

local function reset_start_selection()

    local resetEntryVariable = false

    if entries == startEntries then
        resetEntryVariable = true
    end

    startEntries = {
        {name = "Random",
        permission = PERMISSION_MODERATORS,
        input = INPUT_A,
        func = function () start_command("") end,}
    }

    for i = 1, #levels do
        if not table.contains(badLevels, i) then
            table.insert(startEntries, {
                name = name_of_level(levels[i].level, levels[i].area, levels[i]),
                permission = PERMISSION_MODERATORS,
                input = INPUT_A,
                func = function ()
                    start_command(levels[i].name)
                end
            })
        end
    end

    table.insert(startEntries,
    {name = "Stop Round",
    permission = PERMISSION_MODERATORS,
    input = INPUT_A,
    disabled = stop_round_disabled,
    func = stop_round,
    })

    table.insert(startEntries,
    {name = "Back",
    permission = PERMISSION_NONE,
    input = INPUT_A,
    func = function ()
        entries = mainEntries
        selection = 1
    end,})

    if resetEntryVariable then
        entries = startEntries

        if selection > #entries then selection = #entries end
    end
end

local function reset_player_selection()

    local resetEntryVariable = false

    if entries == playerEntries then
        resetEntryVariable = true
    end

    playerEntries = {}

    for i = 0, MAX_PLAYERS - 1 do
        if gNetworkPlayers[i].connected then
            table.insert(playerEntries,
            {name = get_player_name(i),
            permission = PERMISSION_MODERATORS,
            input = INPUT_JOYSTICK,
            func = function() set_player_role(i) end,
            valueText = get_role_name(gPlayerSyncTable[i].state)})
        end
    end

    table.insert(playerEntries,
    {name = "Back",
    permission = PERMISSION_NONE,
    input = INPUT_A,
    func = function ()
        entries = mainEntries
        selection = 1
    end,})

    if resetEntryVariable then
        entries = playerEntries

        if selection > #entries then selection = #entries end
    end
end

local function reset_blacklist_levels_entries()

    local resetEntryVariable = entries == blacklistLevelEntries

    blacklistLevelEntries = {}

    for i = 1, #levels do
        table.insert(blacklistLevelEntries, {
            name = name_of_level(levels[i].level, levels[i].area, levels[i]),
            permission = PERMISSION_MODERATORS,
            input = INPUT_JOYSTICK,
            func = function ()
                blacklistedCourses[i] = not blacklistedCourses[i]
            end,
            valueText = on_off_text(not blacklistedCourses[i])
        })
    end

    table.insert(blacklistLevelEntries,
    {name = "Back",
    permission = PERMISSION_NONE,
    input = INPUT_A,
    func = function ()
        entries = blacklistEntries
        selection = 1
    end,})

    if resetEntryVariable then
        entries = blacklistLevelEntries

        if selection > #entries then selection = #entries end
    end
end

local function reset_blacklist_gamemode_entries()

    resetEntryVariable = entries == blacklistGamemodeEntries

    blacklistGamemodeEntries = {}

    for i = MIN_GAMEMODE, MAX_GAMEMODE do
        table.insert(blacklistGamemodeEntries, {
            name = get_gamemode(i),
            permission = PERMISSION_NONE,
            input = INPUT_JOYSTICK,
            valueText = on_off_text(not blacklistedGamemodes[i]),
            func = function ()
                blacklistedGamemodes[i] = not blacklistedGamemodes[i]
            end,
        })
    end

    table.insert(blacklistGamemodeEntries, {
        name = "Back",
        permission = PERMISSION_NONE,
        input = INPUT_A,
        func = function ()
            entries = blacklistEntries
            selection = 1
        end,
    })

    if resetEntryVariable then
        entries = blacklistGamemodeEntries
    end
end

local function reset_blacklist_modifier_entries()
    local resetEntryVariable = entries == blacklistModifierEntries

    blacklistModifierEntries = {}

    for i = MODIFIER_MIN + 1, MODIFIER_MAX do
        table.insert(blacklistModifierEntries, {
            name = get_modifier_text(i),
            permission = PERMISSION_NONE,
            input = INPUT_JOYSTICK,
            valueText = on_off_text(not blacklistedModifiers[i]),
            func = function ()
                blacklistedModifiers[i] = not blacklistedModifiers[i]
            end,
        })
    end

    table.insert(blacklistModifierEntries, {
        name = "Back",
        permission = PERMISSION_NONE,
        input = INPUT_A,
        func = function ()
            entries = blacklistEntries
            selection = 1
        end,
    })

    if resetEntryVariable then
        entries = blacklistModifierEntries
    end
end

local function reset_bind_entries()
    local resetBindEntries = false

    if entries == bindsEntries then
        resetBindEntries = true
    end

    bindsEntries = {}

    for i = 0, BIND_MAX do

        local bind = binds[i]
        local value = ""

        if i == awaitingInput then
            value = "Waiting for Press..."
        else
            value = button_to_text(bind.btn)
        end

        table.insert(bindsEntries,
        {name = bind.name,
        permission = PERMISSION_NONE,
        input = INPUT_A,
        func = function ()
            wait_for_button(i)
        end,
        valueText = value})
    end

    table.insert(bindsEntries,
        {name = "Back",
        permission = PERMISSION_NONE,
        input = INPUT_A,
        func = function ()
            entries = mainEntries
            selection = 1
        end}
    )

    if resetBindEntries then
        entries = bindsEntries
    end
end

local function reset_romhack_entries()
    local resetRomhackEntries = false

    if entries == romhackEntries then
        resetRomhack = true
    end

    romhackEntries = {}

    for i = 1, #romhacks do
        local romhack = romhacks[i]
        if romhack.shortName == "reg levels" then goto continue end

        table.insert(romhackEntries,
            {name = romhack.name,
            permission = PERMISSION_MODERATORS,
            input = INPUT_A,
            func = function ()
                -- set override level var
                gGlobalSyncTable.romhackOverride = i
                gGlobalSyncTable.roundState = ROUND_WAIT_PLAYERS
            end}
        )

        ::continue::
    end

    table.insert(romhackEntries,
        {name = "Back",
        permission = PERMISSION_NONE,
        input = INPUT_A,
        func = function ()
            entries = mainEntries
            selection = 1
        end}
    )

    if resetRomhackEntries then
        entries = romhackEntries
    end
end

local function reset_stat_player_selections_entries()
    local resetStatEntries = entries == statPlayerSelectionEntries
    statPlayerSelectionEntries = {}

    for i = 0, MAX_PLAYERS - 1 do
        if not gNetworkPlayers[i].connected then goto continue end
        local name = network_get_player_text_color_string(i) .. gNetworkPlayers[i].name
        table.insert(statPlayerSelectionEntries, {
            name = name,
            permission = PERMISSION_NONE,
            input = INPUT_A,
            func = function ()
                entries = statGroupEntries
                statIndex = i
                selection = 1
            end
        })

        ::continue::
    end

    table.insert(statPlayerSelectionEntries, {
        name = "Back",
        permission = PERMISSION_NONE,
        input = INPUT_A,
        func = function ()
            entries = mainEntries
            selection = 1
        end
    })

    if resetStatEntries then
        entries = statPlayerSelectionEntries
    end
end

local function reset_stat_group_entries()
    local resetStatEntries = entries == statGroupEntries

    statGroupEntries = {
        {name = "Global Stats",
        permission = PERMISSION_NONE,
        input = INPUT_A,
        func = function ()
            entries = statEntries
            statGroupIndex = -1
            selection = 1
        end,},
    }

    for i = MIN_GAMEMODE, MAX_GAMEMODE do
        table.insert(statGroupEntries, {
            name = get_gamemode(i),
            permission = PERMISSION_NONE,
            input = INPUT_A,
            func = function ()
                entries = statEntries
                statGroupIndex = i
                selection = 1
            end
        })
    end

    table.insert(statGroupEntries, {
        name = "Back",
        permission = PERMISSION_NONE,
        input = INPUT_A,
        func = function ()
            entries = statPlayerSelectionEntries
            selection = 1
        end
    })

    if resetStatEntries then
        entries = statGroupEntries
    end
end

local function reset_stat_entries()

    resetStatEntries = entries == statEntries
    statEntries = {}

    if statIndex ~= 0 then
        scopeStats = remoteStats
        if scopeStats == nil then
            table.insert(statEntries, {
                name = "Back",
                permission = PERMISSION_NONE,
                input = INPUT_A,
                func = function ()
                    entries = statGroupEntries
                    selection = 1
                end
            })

            if not sentStatPacket then
                sentStatPacket = true

                -- create packet
                local p = {
                    packetType = PACKET_TYPE_REQUEST_STATS,
                    globalIndex = network_global_index_from_local(0),
                    statIndex = statGroupIndex
                }

                -- send packet to player
                network_send_to(statIndex, true, p)
            end

            if resetStatEntries then entries = statEntries end

            return
        end
    end

    if statGroupIndex < 0 then
        local scopeStats = stats.globalStats

        if statIndex ~= 0 then
            scopeStats = remoteStats
        end

        statEntries = {
            {name = "Play Time",
            permission = PERMISSION_NONE,
            valueText = math.floor(scopeStats.playTime / 30 / 60) .. "m"},
            {name = "Runner Victories",
            permission = PERMISSION_NONE,
            valueText = scopeStats.runnerVictories},
            {name = "Tagger Victories",
            permission = PERMISSION_NONE,
            valueText = scopeStats.taggerVictories},
            {name = "Total Time As Runner",
            permission = PERMISSION_NONE,
            valueText = math.floor(scopeStats.totalTimeAsRunner / 30 / 60) .. "m"},
            {name = "Total Tags",
            permission = PERMISSION_NONE,
            valueText = scopeStats.totalTags},
            {name = "Back",
            permission = PERMISSION_NONE,
            input = INPUT_A,
            func = function ()
                entries = statGroupEntries
                selection = 1
            end,}
        }
    else
        local scopeStats = stats[statGroupIndex]
        if statIndex ~= 0 then
            scopeStats = remoteStats
        end
        if scopeStats == nil then goto continue end
        if scopeStats.playTime ~= nil then
            table.insert(statEntries, {
                name = "Play Time",
                permission = PERMISSION_NONE,
                valueText = math.floor(scopeStats.playTime / 30 / 60) .. "m"
            })
        end
        if scopeStats.runnerVictories ~= nil then
            table.insert(statEntries, {
                name = "Runner Victories",
                permission = PERMISSION_NONE,
                valueText = scopeStats.runnerVictories
            })
        end
        if scopeStats.taggerVictories ~= nil then
            local name = "Tagger Victories"
            if statGroupIndex == ASSASSINS
            or statGroupIndex == DEATHMATCH then name = "Victories" end
            table.insert(statEntries, {
                name = name,
                permission = PERMISSION_NONE,
                valueText = scopeStats.taggerVictories
            })
        end
        if scopeStats.totalTimeAsRunner ~= nil then
            local name = "Total Time As Runner"
            if statGroupIndex == SARDINES then name = "Total Time As Sardine" end
            table.insert(statEntries, {
                name = name,
                permission = PERMISSION_NONE,
                valueText = math.floor(scopeStats.totalTimeAsRunner / 30 / 60) .. "m"
            })
        end
        if scopeStats.totalTags ~= nil then
            local name = "Total Tags"
            if statGroupIndex == INFECTION then name = "Total Infections" end
            table.insert(statEntries, {
                name = name,
                permission = PERMISSION_NONE,
                valueText = scopeStats.totalTags
            })
        end

        table.insert(statEntries, {
            name = "Back",
            permission = PERMISSION_NONE,
            input = INPUT_A,
            func = function ()
                entries = statGroupEntries
                selection = 1
            end
        })

        ::continue::
    end

    if resetStatEntries then
        entries = statEntries
    else
        sentStatPacket = false
        remoteStats = nil
    end
end

local function hud_render()

    if not showSettings then
        entries = mainEntries
        selection = 1
        scrollOffset = 0
        return
    end

    djui_hud_set_font(FONT_NORMAL)
    djui_hud_set_resolution(RESOLUTION_DJUI)

    -- get entry to start scrolling at
    scrollEntry = 12
    for i = 1, #entries do
        if entries[i].seperator ~= nil then
            scrollEntry = scrollEntry - 0.4
        end
    end

    if selection >= math.ceil(scrollEntry) then
        scrollOffset = 60 * (selection - scrollEntry)
    else
        scrollOffset = 0
    end

    background()
    settings_text()
    -- reconstruct tables
    reset_main_selections()
    reset_general_selection()
    reset_gamemode_selection()
    reset_start_selection()
    reset_player_selection()
    reset_blacklist_levels_entries()
    reset_blacklist_gamemode_entries()
    reset_blacklist_modifier_entries()
    reset_bind_entries()
    reset_romhack_entries()
    reset_stat_player_selections_entries()
    reset_stat_group_entries()
    reset_stat_entries()

    local height = 90
    local x = (djui_hud_get_screen_width() / 2) - (bgWidth / 2)
    local y = (djui_hud_get_screen_height() - bgHeight) / 2

    for i = 1, #entries do
        if entries[i].seperator ~= nil then
            if i > math.ceil(scrollEntry + scrollOffset / 60)
            or i < math.floor((scrollOffset / 60) - 1) then
                height = height + 60
                goto continue
            end
            height = height + 45


            djui_hud_set_color(220, 220, 220, 255)
            djui_hud_print_colored_text(entries[i].seperator, x + 30, y + height + 4 - scrollOffset, 1)

            height = height + 45
        else
            height = height + 60
            if i > math.ceil(scrollEntry + scrollOffset / 60)
            or i < math.floor((scrollOffset / 60) - 1) then goto continue end
        end

        if entries[i].text ~= nil then
            -- appreciate the free labor chatgpt (ok I did a little bit of cleanup)
            local textAmount = 64
            if usingCoopDX then textAmount = 55 end
            local wrappedTextLines = wrap_text(entries[i].text, textAmount)

            for j, line in ipairs(wrappedTextLines) do
                if selection == i then
                    djui_hud_set_color(240, 240, 240, 255)
                else
                    djui_hud_set_color(200, 200, 200, 255)
                end

                djui_hud_print_text(line, x + 20, y + height - scrollOffset + (j - 1) * 28, 1)
            end

            for _ = 1, #wrappedTextLines do
                height = height + 25
            end

            goto continue
        end

        local outlineColor = 50

        if selection == i then
            djui_hud_set_color(40, 40, 40, 215)
            outlineColor = 60
        else
            djui_hud_set_color(32, 32, 32, 200)
        end

        djui_hud_render_rect_outlined(x + 20, y + height - scrollOffset, bgWidth - 40, 40, outlineColor, outlineColor, outlineColor, 3)

        if not has_permission(entries[i].permission)
        or (entries[i].disabled ~= nil and entries[i].disabled()) then
            djui_hud_set_color(150, 150, 150, 255)
        else
            djui_hud_set_color(220, 220, 220, 255)
        end

        djui_hud_print_colored_text(tostring(entries[i].name), x + 30, y + height + 4 - scrollOffset, 1)

        if entries[i].valueText ~= nil then
            djui_hud_set_color(220, 220, 220, 255)
            djui_hud_print_colored_text(tostring(entries[i].valueText), x + (bgWidth - 30) - djui_hud_measure_text(strip_hex(tostring(entries[i].valueText))), y + height + 4 - scrollOffset, 1)
        end

        ::continue::
    end
end

---@param m MarioState
local function mario_update(m)

    if m.playerIndex ~= 0 then return end
    if not showSettings then return end

    -- if our stick is at 0, then set joystickCooldown to 0
    if m.controller.stickX == 0 and m.controller.stickY == 0 then joystickCooldown = 0 end

    if m.controller.buttonPressed & U_JPAD ~= 0
    or (m.controller.stickY > 0.5 and joystickCooldown <= 0) then
        selection = selection - 1
        if selection < 1 then selection = #entries end
        play_sound(SOUND_MENU_MESSAGE_DISAPPEAR, gGlobalSoundSource)
        joystickCooldown = 0.2 * 30
        awaitingInput = nil
    elseif m.controller.buttonPressed & D_JPAD ~= 0
    or (m.controller.stickY < -0.5 and joystickCooldown <= 0) then
        selection = selection + 1
        if selection > #entries then selection = 1 end
        play_sound(SOUND_MENU_MESSAGE_DISAPPEAR, gGlobalSoundSource)
        joystickCooldown = 0.2 * 30
        awaitingInput = nil
    end

    if (m.controller.buttonPressed & R_JPAD ~= 0 or (m.controller.stickX > 0.5
    and joystickCooldown <= 0))
    and entries[selection].input == INPUT_JOYSTICK then
        if has_permission(entries[selection].permission) then
            if entries[selection].func ~= nil then
                entries[selection].func()
                play_sound(SOUND_MENU_MESSAGE_DISAPPEAR, gGlobalSoundSource)
            end
        else
            play_sound(SOUND_MENU_CAMERA_BUZZ, gGlobalSoundSource)
        end

        joystickCooldown = 0.2 * 30
    elseif (m.controller.buttonPressed & L_JPAD ~= 0 or (m.controller.stickX < -0.5
    and joystickCooldown <= 0))
    and entries[selection].input == INPUT_JOYSTICK then
        if has_permission(entries[selection].permission) then
            if entries[selection].func ~= nil then
                entries[selection].func()
                play_sound(SOUND_MENU_MESSAGE_DISAPPEAR, gGlobalSoundSource)
            end
        else
            play_sound(SOUND_MENU_CAMERA_BUZZ, gGlobalSoundSource)
        end

        joystickCooldown = 0.2 * 30
    end

    if joystickCooldown > 0 then joystickCooldown = joystickCooldown - 1 end

    if awaitingInput ~= nil then
        if m.controller.buttonPressed ~= 0 then
            if button_to_text(m.controller.buttonPressed) == "" then return end
            binds[awaitingInput].btn = m.controller.buttonPressed
            save_int("bind_" .. tostring(awaitingInput), binds[awaitingInput].btn)

            awaitingInput = nil
        end

        return
    end

    if m.controller.buttonPressed & A_BUTTON ~= 0
    and entries[selection].input == INPUT_A then
        if has_permission(entries[selection].permission)
        and (entries[selection].disabled == nil or
        (entries[selection].disabled ~= nil and not entries[selection].disabled())) then
            if entries[selection].func ~= nil then
                entries[selection].func()
                play_sound(SOUND_MENU_CLICK_FILE_SELECT, gGlobalSoundSource)
            end
        else
            play_sound(SOUND_MENU_CAMERA_BUZZ, gGlobalSoundSource)
        end
    end
end

hook_event(HOOK_ON_HUD_RENDER, hud_render)
hook_event(HOOK_MARIO_UPDATE, mario_update)