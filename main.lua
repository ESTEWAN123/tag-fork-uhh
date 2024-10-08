-- name: \\#316BE8\\Tag (v2.32)\\#dcdcdc\\
-- description: All Tag Related Gamemodes!\n\nThis mod contains Tag, Freeze Tag, Infection, Hot Potato, Juggernaut, Assassins, and more, with modifiers, and full romhack support!\n\nThis mod includes a blacklist command to blacklist bad levels in romhacks\n\nHave fun playing Tag!\n\nDeveloped by \\#a5ae8f\\EmeraldLockdown\\#dcdcdc\\\n\nSnippets of code taken from \\#f7b2f3\\EmilyEmmi\\#dcdcdc\\ and\\#ff7f00\\ Agent X\\#dcdcdc\\\n\nPainting textures taken from Shine Thief, by \\#f7b2f3\\EmilyEmmi\n\nRomhack Porters are in the romhacks.lua file.
-- incompatible: gamemode tag

-- if your trying to learn this code, I hope I've done a good job.
-- This file is pretty much (other than misc.lua) the most unorganized file of them all
-- threw so much crap in here that isn't even apart of the actual game loop or anything
-- anyways other than that, everything should be good, so
-- wish you luck on your journey!

-- constants

-- round states
ROUND_WAIT_PLAYERS                     = 0
ROUND_ACTIVE                           = 1
ROUND_WAIT                             = 2
ROUND_TAGGERS_WIN                      = 3
ROUND_RUNNERS_WIN                      = 4
ROUND_HOT_POTATO_INTERMISSION          = 5
ROUND_VOTING                           = 6
ROUND_HIDING_SARDINES                  = 7

-- roles (gamemode-specific roles specified in designated gamemode files, and replace the wildcard role)
RUNNER                                 = 0
TAGGER                                 = 1
WILDCARD_ROLE                          = 2
SPECTATOR                              = 3

-- gamemodes
MIN_GAMEMODE                           = 1
TAG                                    = 1
FREEZE_TAG                             = 2
INFECTION                              = 3
HOT_POTATO                             = 4
JUGGERNAUT                             = 5
ASSASSINS                              = 6
SARDINES                               = 7
HUNT                                   = 8
DEATHMATCH                             = 9
TERMINATOR                             = 10
MAX_GAMEMODE                           = 10

-- spectator states
SPECTATOR_STATE_MARIO                  = 0
SPECTATOR_STATE_FREECAM                = 1
SPECTATOR_STATE_FOLLOW                 = 2

-- players needed (it's only 2 if your on the tag gamemode, otherwise this variable is 3)
PLAYERS_NEEDED                         = 2

-- modifiers
MODIFIER_MIN                           = 0
MODIFIER_NONE                          = 0
MODIFIER_BOMBS                         = 1
MODIFIER_LOW_GRAVITY                   = 2
MODIFIER_NO_RADAR                      = 3
MODIFIER_NO_BOOST                      = 4
MODIFIER_ONE_TAGGER                    = 5
MODIFIER_FOG                           = 6
MODIFIER_SPEED                         = 7
MODIFIER_INCOGNITO                     = 8
MODIFIER_HIGH_GRAVITY                  = 9
MODIFIER_FLY                           = 10
MODIFIER_BLASTER                       = 11
MODIFIER_ONE_RUNNER                    = 12
MODIFIER_DOUBLE_JUMP                   = 13
MODIFIER_SHELL                         = 14
MODIFIER_BLJS                          = 15
MODIFIER_FRIENDLY_FIRE                 = 16
MODIFIER_MAX                           = 16

-- binds
BIND_BOOST = 0
BIND_BOMBS = 1
BIND_GUN = 2
BIND_DOUBLE_JUMP = 3
BIND_MAX = 3

-- textures
TEXTURE_TAG_LOGO = get_texture_info("logo")

-- globals and sync tables
-- this is the round state, this variable tells you what current round it is
gGlobalSyncTable.roundState            = ROUND_WAIT_PLAYERS
-- what the current gamemode is
gGlobalSyncTable.gamemode              = TAG
-- this is the currently selected modifier. If random modifiers are off (as in you've selected
-- one manually) then MODIFIER_NONE = Disabled
gGlobalSyncTable.modifier              = MODIFIER_NONE
-- dictates whether or not modifiers and gamemodes are random
gGlobalSyncTable.randomGamemode        = true
gGlobalSyncTable.randomModifiers       = true
-- toggles for bljs, cnanons, and water
gGlobalSyncTable.bljs                  = false
gGlobalSyncTable.cannons               = false
gGlobalSyncTable.water                 = false
-- display timer, used for all sorts of timers, timers from the top
-- of the screen, to timers in the vote menu
gGlobalSyncTable.displayTimer          = 1
-- the current selected level. When romhacks are enabled, this is set to the actual level
-- number (i.e LEVEL_BOB), otherwise, it's set to the level in the levels table (found below here)
gGlobalSyncTable.selectedLevel         = 1
-- max lives. Since this changes depending on player count, make it a global variable
gGlobalSyncTable.tagMaxLives           = 15
-- amount of time left in a round
gGlobalSyncTable.amountOfTime          = 120 * 30
-- ttc speed, because ttc syncing sucks
gGlobalSyncTable.ttcSpeed              = 0
-- toggles elimination on death
gGlobalSyncTable.eliminateOnDeath      = true
-- toggles vote level system
gGlobalSyncTable.doVoting              = true
-- all gamemode active timers
gGlobalSyncTable.tagActiveTimer        = 120 * 30
gGlobalSyncTable.freezeTagActiveTimer  = 180 * 30
gGlobalSyncTable.infectionActiveTimer  = 120 * 30
gGlobalSyncTable.hotPotatoActiveTimer  = 035 * 30
gGlobalSyncTable.juggernautActiveTimer = 120 * 30
gGlobalSyncTable.assassinsActiveTimer  = 120 * 30
gGlobalSyncTable.sardinesActiveTimer   = 120 * 30
gGlobalSyncTable.huntActiveTimer       = 180 * 30
gGlobalSyncTable.deathmatchActiveTimer = 180 * 30
gGlobalSyncTable.terminatorActiveTimer = 180 * 30
-- other timers
gGlobalSyncTable.sardinesHidingTimer   = 30  * 30
-- amount of lives for hunt
gGlobalSyncTable.huntLivesCount        = 3
-- amount of lives for deathmatch
gGlobalSyncTable.deathmatchLivesCount  = 3
-- auto mode
gGlobalSyncTable.autoMode              = true
-- enable tagger boosts or not
gGlobalSyncTable.boosts                = true
-- enable or disable hazardous surfaces
gGlobalSyncTable.hazardSurfaces        = false
-- override for romhacks
gGlobalSyncTable.romhackOverride        = nil

for i = 0, MAX_PLAYERS - 1 do -- set all states for every player on init if we are the server
    if network_is_server() then
        -- the player's role
        gPlayerSyncTable[i].state = RUNNER
        -- the player's invinc timer, I forgot why I use the player sync table, think for
        -- syincing it or something, anyways that's what it is so
        gPlayerSyncTable[i].invincTimer = 0
        -- amount of tags a player has gotten, and the amount of time a runner has
        -- been a runner, this is for the leaderboard
        gPlayerSyncTable[i].amountOfTags = 0
        gPlayerSyncTable[i].amountOfTimeAsRunner = 0
        -- amount of tags till death (used for juggernaut and hunt)
        gPlayerSyncTable[i].tagLives = 0
        -- the assassins's target and stun timer (stun as the shock action)
        gPlayerSyncTable[i].assassinTarget = -1
        gPlayerSyncTable[i].assassinStunTimer = -1
        -- what number you voted for in the level voting system
        gPlayerSyncTable[i].votingNumber = 0
        -- whether or not your boosting
        gPlayerSyncTable[i].boosting = false
        -- spectator state
        gPlayerSyncTable[i].spectatorState = SPECTATOR_STATE_MARIO
    end
end

-- server settings
gServerSettings.playerInteractions = PLAYER_INTERACTIONS_SOLID -- force player attacks to be on
gServerSettings.bubbleDeath = 0                                -- just.... no

-- level values
gLevelValues.disableActs = true

-- levels
levels = {}

-- if we are using coopdx or not
usingCoopDX = SM64COOPDX_VERSION ~= nil

-- initialized mh api for chat stuff
_G.mhApi = {}

-- variables
-- this is the local server timer used to set gGlobalSyncTable.displayTimer and other variables
timer = 0
-- if we are a romhack or not (checked in check_mods function)
isRomhack = false
-- if nametags are enabled or not (checked in check_mods function)
nametagsEnabled = false
-- blacklisted courses, gamemodes, and modifiers
blacklistedCourses = {}
blacklistedGamemodes = {
    [TAG] = false,
    [FREEZE_TAG] = false,
    [INFECTION] = false,
    [HOT_POTATO] = false,
    [JUGGERNAUT] = false,
    [ASSASSINS] = false,
    [SARDINES] = false,
    [HUNT] = false,
    [DEATHMATCH] = false,
    [TERMINATOR] = false,
}
blacklistedModifiers = {
    [MODIFIER_BOMBS] = false,
    [MODIFIER_LOW_GRAVITY] = false,
    [MODIFIER_NO_RADAR] = false,
    [MODIFIER_NO_BOOST] = false,
    [MODIFIER_ONE_TAGGER] = false,
    [MODIFIER_FOG] = false,
    [MODIFIER_BOMBS] = false,
    [MODIFIER_SPEED] = false,
    [MODIFIER_INCOGNITO] = false,
    [MODIFIER_HIGH_GRAVITY] = false,
    [MODIFIER_FLY] = false,
    [MODIFIER_BLASTER] = false,
    [MODIFIER_ONE_RUNNER] = false,
    [MODIFIER_DOUBLE_JUMP] = false,
    [MODIFIER_SHELL] = false,
    [MODIFIER_BLJS] = false,
    [MODIFIER_FRIENDLY_FIRE] = false,
}
-- the previous level, used for when the server selects levels to pick
prevLevel = 1 -- make it the same as the selected level so it selects a new level
-- These are levels that are failed to be warped to for romhacks
badLevels = {}
-- the global sound source, used for audio
gGlobalSoundSource = { x = 0, y = 0, z = 0 }
-- if we are paused or not, for custom pause menu
isPaused = false
-- whether or not to use romhack cam
useRomhackCam = true
-- auto hide hud option
autoHideHud = true
-- amount of times the pipe has been used
pipeUse = 0
-- how long it has been since we last entered a pipe
pipeTimer = 0
-- binds
binds = {}
-- boost bind
binds[BIND_BOOST] = {name = "Boost", btn = Y_BUTTON}
-- bomb bind
binds[BIND_BOMBS] = {name = "Bombs", btn = Y_BUTTON}
-- gun bind
binds[BIND_GUN] = {name = "Gun", btn = X_BUTTON}
-- double jump bind
binds[BIND_DOUBLE_JUMP] = {name = "Double Jump", btn = A_BUTTON}
-- stats
stats = {
    globalStats = {
        playTime = 0,
        totalTags = 0,
        totalTimeAsRunner = 0,
        runnerVictories = 0,
        taggerVictories = 0,
    },
    [TAG] = {
        playTime = 0,
        totalTags = 0,
        totalTimeAsRunner = 0,
        runnerVictories = 0,
        taggerVictories = 0,
    },
    [FREEZE_TAG] = {
        playTime = 0,
        totalTags = 0,
        totalTimeAsRunner = 0,
        runnerVictories = 0,
        taggerVictories = 0,
    },
    [INFECTION] = {
        playTime = 0,
        totalTags = 0,
        totalTimeAsRunner = 0,
        runnerVictories = 0,
        taggerVictories = 0,
    },
    [HOT_POTATO] = {
        playTime = 0,
        totalTags = 0,
        totalTimeAsRunner = 0,
        runnerVictories = 0,
        taggerVictories = 0,
    },
    [JUGGERNAUT] = {
        playTime = 0,
        totalTags = 0,
        totalTimeAsRunner = 0,
        runnerVictories = 0,
        taggerVictories = 0,
    },
    [ASSASSINS] = {
        playTime = 0,
        totalTags = 0,
        taggerVictories = 0,
    },
    [SARDINES] = {
        playTime = 0,
        totalTags = 0,
        totalTimeAsRunner = 0,
        taggerVictories = 0,
    },
    [HUNT] = {
        playTime = 0,
        totalTags = 0,
        totalTimeAsRunner = 0,
        runnerVictories = 0,
        taggerVictories = 0,
    },
    [DEATHMATCH] = {
        playTime = 0,
        totalTags = 0,
        taggerVictories = 0,
    },
    [TERMINATOR] = {
        playTime = 0,
        totalTags = 0,
        totalTimeAsRunner = 0,
        runnerVictories = 0,
        taggerVictories = 0,
    },
}

remoteStats = {
    playTime = 0,
    totalTags = 0,
    totalTimeAsRunner = 0,
    runnerVictories = 0,
    taggerVictories = 0,
}

-- speed boost timer handles boosting
local speedBoostTimer = 0
-- hot potato timer multiplier is when the timer
-- is faster if there's more people currently active
local hotPotatoTimerMultiplier = 1
-- hud fade
local hudFade = 255
-- previous romhack override
local prevRomhackOverride = nil
-- initialized save data
local initializedSaveData = false
-- room timer
local roomTimer = 0
-- water region values
local waterRegions = {}

-- just some global variables, honestly idk why the second one is there but it is so, uh, enjoy?
_G.tag = {}

-- just a action we can use, used for when the round ends and mario freezes
ACT_NOTHING = allocate_mario_action(ACT_FLAG_IDLE)

local function server_update()
    -- set some basic sync table vars
    for i = 0, MAX_PLAYERS - 1 do
        if not gNetworkPlayers[i].connected then
            gPlayerSyncTable[i].state = -1
            gPlayerSyncTable[i].amountOfTimeAsRunner = 0
            gPlayerSyncTable[i].amountOfTags = 0
            gPlayerSyncTable[i].tagLives = 0
        end
    end

    -- get number of players
    local numPlayers = 0

    for i = 0, MAX_PLAYERS - 1 do
        -- don't include spectators
        if gNetworkPlayers[i].connected and gPlayerSyncTable[i].state ~= SPECTATOR then
            numPlayers = numPlayers + 1
        end
    end

    if numPlayers < PLAYERS_NEEDED then
        gGlobalSyncTable.roundState = ROUND_WAIT_PLAYERS -- set round state to waiting for players

        if gGlobalSyncTable.randomGamemode and PLAYERS_NEEDED > 2 then
            -- set gamemode to tag so the game keeps going
            gGlobalSyncTable.gamemode = TAG

            -- default tag timer
            gGlobalSyncTable.amountOfTime = gGlobalSyncTable.tagActiveTimer

            PLAYERS_NEEDED = 2
            log_to_console("Tag: Attempted to keep tag going by setting the gamemode to tag")
        end
    elseif gGlobalSyncTable.roundState == ROUND_WAIT_PLAYERS then
        -- if we aren't in auto mode, then don't run this code, and run designated code in the if statemnt
        if not gGlobalSyncTable.autoMode then
            if timer >= 16 * 30 then
                for i = 0, MAX_PLAYERS - 1 do
                    if gPlayerSyncTable[i].state ~= SPECTATOR then
                        gPlayerSyncTable[i].state = RUNNER
                    end
                end
            end

            goto ifend
        end

        timer = 15 * 30 -- 15 seconds

        local level = levels[gGlobalSyncTable.selectedLevel]

        -- this long while loop is just to select a random level, ik, extremely hard to read
        while blacklistedCourses[gGlobalSyncTable.selectedLevel] == true or table.contains(badLevels, level.level) or gGlobalSyncTable.selectedLevel == prevLevel do
            gGlobalSyncTable.selectedLevel = math.random(1, #levels) -- select a random level

            if level.level == LEVEL_TTC and not isRomhack then
                gGlobalSyncTable.ttcSpeed = math.random(0, 3)
            end
        end

        prevLevel = gGlobalSyncTable.selectedLevel
        gGlobalSyncTable.roundState = ROUND_WAIT -- set round state to the intermission state

        log_to_console("Tag: Round State is now ROUND_WAIT")

        ::ifend::
    end

    if gGlobalSyncTable.roundState == ROUND_WAIT_PLAYERS then
        -- force state to be runner, so long as they aren't a spectator, and we are in auto mode
        for i = 0, MAX_PLAYERS - 1 do
            if gPlayerSyncTable[i].state ~= SPECTATOR and gGlobalSyncTable.autoMode then
                gPlayerSyncTable[i].state = RUNNER
            end
        end

        -- set timer to 15 seconds to prevent state being set constantly
        timer = 15 * 30
    elseif gGlobalSyncTable.roundState == ROUND_WAIT then
        -- select a modifier and gamemode if timer is at its highest point
        if timer == 15 * 30 then
            if gGlobalSyncTable.randomModifiers then
                -- see if we should use a modifier modifiers or not
                local selectModifier = math.random(1, 2) -- 50% chance

                if selectModifier == 2 then
                    ::selectmodifier::
                    -- select a random modifier
                    gGlobalSyncTable.modifier = math.random(MODIFIER_MIN + 1, MODIFIER_MAX) -- select random modifier, exclude MODIFIER_NONE

                    if  (gGlobalSyncTable.gamemode == ASSASSINS
                    or  gGlobalSyncTable.gamemode  == SARDINES
                    or  gGlobalSyncTable.gamemode  == JUGGERNAUT)
                    and (gGlobalSyncTable.modifier == MODIFIER_ONE_TAGGER
                    or  gGlobalSyncTable.modifier  == MODIFIER_INCOGNITO
                    or  gGlobalSyncTable.modifier  == MODIFIER_ONE_RUNNER) then
                        goto selectmodifier
                    end

                    if (levels[gGlobalSyncTable.selectedLevel].name == "ithi"
                    or levels[gGlobalSyncTable.selectedLevel].name == "lll"
                    or levels[gGlobalSyncTable.selectedLevel].name == "bitfs")
                    and not isRomhack
                    and gGlobalSyncTable.modifier == MODIFIER_FOG then
                        goto selectmodifier
                    end

                    if blacklistedModifiers[gGlobalSyncTable.modifier] == true then
                        goto selectmodifier
                    end
                else
                    gGlobalSyncTable.modifier = MODIFIER_NONE -- set the modifier to none
                end
            end

            -- if we select a random gamemode, select that random gamemode now
            if gGlobalSyncTable.randomGamemode then
                if numPlayers >= 3 then -- 3 is the minimum player count for random gamemodes
                    -- check if we have all gamemodes blacklisted
                    local gamemodesBlacklisted = MIN_GAMEMODE - 1
                    for i = MIN_GAMEMODE, MAX_GAMEMODE do
                        if blacklistedGamemodes[i] == true then
                            gamemodesBlacklisted = gamemodesBlacklisted + 1
                        end
                    end

                    -- if they all are, skip setting gamemode
                    if gamemodesBlacklisted == MAX_GAMEMODE then
                        goto amountoftime
                    end

                    ::selectgamemode::
                    gGlobalSyncTable.gamemode = math.random(MIN_GAMEMODE, MAX_GAMEMODE)

                    if blacklistedGamemodes[gGlobalSyncTable.gamemode] == true then
                        goto selectgamemode
                    end
                else
                    gGlobalSyncTable.gamemode = TAG -- set to tag explicitly
                end
            end

            -- set the amount of time var and players needed var
            ::amountoftime::
            if gGlobalSyncTable.gamemode == FREEZE_TAG then
                -- set freeze tag timer
                gGlobalSyncTable.amountOfTime = gGlobalSyncTable.freezeTagActiveTimer

                PLAYERS_NEEDED = 3
            elseif gGlobalSyncTable.gamemode == TAG then
                -- set tag timer
                gGlobalSyncTable.amountOfTime = gGlobalSyncTable.tagActiveTimer

                PLAYERS_NEEDED = 2
            elseif gGlobalSyncTable.gamemode == INFECTION then
                -- set infection timer
                gGlobalSyncTable.amountOfTime = gGlobalSyncTable.infectionActiveTimer

                PLAYERS_NEEDED = 3
            elseif gGlobalSyncTable.gamemode == HOT_POTATO then
                -- set hot potato timer
                gGlobalSyncTable.amountOfTime = gGlobalSyncTable.hotPotatoActiveTimer

                PLAYERS_NEEDED = 3
            elseif gGlobalSyncTable.gamemode == JUGGERNAUT then
                -- set juggernaut timer
                gGlobalSyncTable.amountOfTime = gGlobalSyncTable.juggernautActiveTimer

                PLAYERS_NEEDED = 3
            elseif gGlobalSyncTable.gamemode == ASSASSINS then
                -- set assassins timer
                gGlobalSyncTable.amountOfTime = gGlobalSyncTable.assassinsActiveTimer

                PLAYERS_NEEDED = 3
            elseif gGlobalSyncTable.gamemode == SARDINES then
                -- set sardines timer
                gGlobalSyncTable.amountOfTime = gGlobalSyncTable.sardinesActiveTimer

                PLAYERS_NEEDED = 3
            elseif gGlobalSyncTable.gamemode == HUNT then
                -- set hunt timer
                gGlobalSyncTable.amountOfTime = gGlobalSyncTable.huntActiveTimer

                PLAYERS_NEEDED = 3
            elseif gGlobalSyncTable.gamemode == DEATHMATCH then
                -- set deathmatch timer
                gGlobalSyncTable.amountOfTime = gGlobalSyncTable.deathmatchActiveTimer

                PLAYERS_NEEDED = 3
            elseif gGlobalSyncTable.gamemode == TERMINATOR then
                -- set terminator timer
                gGlobalSyncTable.amountOfTime = gGlobalSyncTable.terminatorActiveTimer

                PLAYERS_NEEDED = 3
            end

            log_to_console("Tag: Modifier is set to " ..
                get_modifier_text_without_hex() .. " and the gamemode is set to " .. get_gamemode_without_hex(gGlobalSyncTable.gamemode))
        end

        for i = 0, MAX_PLAYERS - 1 do
            if gPlayerSyncTable[i].state ~= SPECTATOR and gGlobalSyncTable.autoMode then
                gPlayerSyncTable[i].state = RUNNER -- set everyone's state to runner
            end

            local m = gMarioStates[i]

            if m.action == ACT_NOTHING then
                set_mario_action(m, ACT_IDLE, 0)
            end

            gPlayerSyncTable[i].tagLives = 0             -- reset tag lives
            gPlayerSyncTable[i].assassinTarget = -1      -- reset assassin target
            gPlayerSyncTable[i].amountOfTags = 0         -- reset amount of tags
            gPlayerSyncTable[i].amountOfTimeAsRunner = 0 -- reset amount of time as runner
        end

        timer = timer - 1                     -- subtract timer by one
        gGlobalSyncTable.displayTimer = timer -- set display timer to timer

        if timer <= 0 then
            -- set the amount of time var and players needed var
            if gGlobalSyncTable.gamemode == FREEZE_TAG then
                -- set freeze tag timer
                gGlobalSyncTable.amountOfTime = gGlobalSyncTable.freezeTagActiveTimer
            elseif gGlobalSyncTable.gamemode == TAG then
                -- set tag timer
                gGlobalSyncTable.amountOfTime = gGlobalSyncTable.tagActiveTimer
            elseif gGlobalSyncTable.gamemode == INFECTION then
                -- set infection timer
                gGlobalSyncTable.amountOfTime = gGlobalSyncTable.infectionActiveTimer
            elseif gGlobalSyncTable.gamemode == HOT_POTATO then
                -- set hot potato timer
                gGlobalSyncTable.amountOfTime = gGlobalSyncTable.hotPotatoActiveTimer
            elseif gGlobalSyncTable.gamemode == JUGGERNAUT then
                -- set juggernaut timer
                gGlobalSyncTable.amountOfTime = gGlobalSyncTable.juggernautActiveTimer
            elseif gGlobalSyncTable.gamemode == ASSASSINS then
                -- set assassins timer
                gGlobalSyncTable.amountOfTime = gGlobalSyncTable.assassinsActiveTimer
            elseif gGlobalSyncTable.gamemode == SARDINES then
                -- set sardines timer
                gGlobalSyncTable.amountOfTime = gGlobalSyncTable.sardinesActiveTimer
            elseif gGlobalSyncTable.gamemode == HUNT then
                -- set hunt timer
                gGlobalSyncTable.amountOfTime = gGlobalSyncTable.huntActiveTimer
            elseif gGlobalSyncTable.gamemode == DEATHMATCH then
                -- set deathmatch timer
                gGlobalSyncTable.amountOfTime = gGlobalSyncTable.deathmatchActiveTimer
            elseif gGlobalSyncTable.gamemode == TERMINATOR then
                -- set deathmatch timer
                gGlobalSyncTable.amountOfTime = gGlobalSyncTable.terminatorActiveTimer
            end

            timer = gGlobalSyncTable.amountOfTime -- set timer to amount of time in a round

            -- set timer to sardines hiding timer if we are in the gamemode sardines
            if gGlobalSyncTable.gamemode == SARDINES then timer = gGlobalSyncTable.sardinesHidingTimer end

            -- if we have custom roles, skip straight to actually starting the round
            local skipTaggerSelection = false
            for i = 0, MAX_PLAYERS - 1 do
                if gNetworkPlayers[i].connected then
                    if gPlayerSyncTable[i].state == TAGGER then
                        skipTaggerSelection = true
                    end
                end
            end

            local amountOfTaggersNeeded = math.floor(numPlayers / PLAYERS_NEEDED) -- always have the amount of the players needed, rounding down, be taggers

            -- set tag max lives for gamemodes like juggernaut, hunt, and deathmatch
            if gGlobalSyncTable.gamemode == JUGGERNAUT then gGlobalSyncTable.tagMaxLives = clampf(math.floor(numPlayers * 2), 1, 16) end
            if gGlobalSyncTable.gamemode == HUNT then gGlobalSyncTable.tagMaxLives = gGlobalSyncTable.huntLivesCount end
            if gGlobalSyncTable.gamemode == DEATHMATCH then gGlobalSyncTable.tagMaxLives = gGlobalSyncTable.deathmatchLivesCount end

            for i = 0, MAX_PLAYERS - 1 do
                gPlayerSyncTable[i].tagLives = gGlobalSyncTable.tagMaxLives
            end

            if not skipTaggerSelection then
                if gGlobalSyncTable.modifier == MODIFIER_ONE_TAGGER
                or gGlobalSyncTable.gamemode == TERMINATOR then
                    amountOfTaggersNeeded = 1
                elseif gGlobalSyncTable.modifier == MODIFIER_ONE_RUNNER then
                    amountOfTaggersNeeded = numPlayers - 1
                end

                if gGlobalSyncTable.gamemode == JUGGERNAUT
                or gGlobalSyncTable.gamemode == SARDINES then
                    amountOfTaggersNeeded = numPlayers - 1
                end

                log_to_console("Tag: Assigning Players")

                local amountOfTaggers = 0

                while amountOfTaggers < amountOfTaggersNeeded do
                    -- select taggers
                    local randomIndex = math.random(0, MAX_PLAYERS - 1) -- select random index

                    if gPlayerSyncTable[randomIndex].state ~= TAGGER and gPlayerSyncTable[randomIndex].state ~= SPECTATOR and gPlayerSyncTable[randomIndex].state ~= -1 and gNetworkPlayers[randomIndex].connected then
                        gPlayerSyncTable[randomIndex].state = TAGGER

                        log_to_console("Tag: Assigned " .. gNetworkPlayers[randomIndex].name .. " as " .. get_role_name(TAGGER))

                        amountOfTaggers = amountOfTaggers + 1
                    end
                end
            end

            if gGlobalSyncTable.gamemode == HOT_POTATO then
                -- get current amount of runners
                local curRunnerCount = 0
                for i = 0, MAX_PLAYERS - 1 do

                    local np = gNetworkPlayers[i]
                    local s = gPlayerSyncTable[i]

                    if  s.state == RUNNER
                    and np.connected then
                        curRunnerCount = curRunnerCount + 1
                    end
                end

                hotPotatoTimerMultiplier = curRunnerCount / 2

                if hotPotatoTimerMultiplier > 2.3 then hotPotatoTimerMultiplier = 2.3 end
            else
                hotPotatoTimerMultiplier = 1
            end

            if gGlobalSyncTable.gamemode == ASSASSINS
            or gGlobalSyncTable.gamemode == DEATHMATCH then
                for i = 0, MAX_PLAYERS - 1 do
                    if gPlayerSyncTable[i].state ~= SPECTATOR then
                        gPlayerSyncTable[i].state = TAGGER
                    end
                end
            end

            gGlobalSyncTable.roundState = ROUND_ACTIVE -- begin round

            -- if the gamemode is sardines set round state to hiding sardines
            if gGlobalSyncTable.gamemode == SARDINES then gGlobalSyncTable.roundState = ROUND_HIDING_SARDINES end

            log_to_console("Tag: Started the game")
        end
    elseif gGlobalSyncTable.roundState == ROUND_HIDING_SARDINES then
        timer = timer - 1
        gGlobalSyncTable.displayTimer = timer

        if timer <= 0 then
            timer = gGlobalSyncTable.amountOfTime

            gGlobalSyncTable.roundState = ROUND_ACTIVE
        end
    elseif gGlobalSyncTable.roundState == ROUND_ACTIVE then
        if timer > 0 then
            timer = timer - (1 * hotPotatoTimerMultiplier) -- subtract timer by one multiplied by hot potato multiplyer
            gGlobalSyncTable.displayTimer = timer          -- set display timer to timer
        end

        for i = 0, MAX_PLAYERS - 1 do
            if (gPlayerSyncTable[i].state == RUNNER
            or (gGlobalSyncTable.gamemode == SARDINES
            and gPlayerSyncTable[i].state == WILDCARD_ROLE))
            and gGlobalSyncTable.roundState == ROUND_ACTIVE then
                gPlayerSyncTable[i].amountOfTimeAsRunner = gPlayerSyncTable[i].amountOfTimeAsRunner + 1 -- increase amount of time as runner
            end
        end

        if timer <= 0 then
            if gGlobalSyncTable.gamemode ~= HOT_POTATO then
                timer = 5 * 30 -- 5 seconds

                if gGlobalSyncTable.gamemode == ASSASSINS
                or gGlobalSyncTable.gamemode == DEATHMATCH then
                    gGlobalSyncTable.roundState = ROUND_TAGGERS_WIN -- end round
                else
                    gGlobalSyncTable.roundState = ROUND_RUNNERS_WIN -- end round
                end

                log_to_console("Tag: Timer's Set to 0, ending round...")

                return
            else
                for i = 0, MAX_PLAYERS - 1 do
                    if gNetworkPlayers[i].connected then
                        if gPlayerSyncTable[i].state == TAGGER then
                            spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[i].pos.x,
                                gMarioStates[i].pos.y, gMarioStates[i].pos.z, function() end)
                            gPlayerSyncTable[i].state = WILDCARD_ROLE
                            explosion_popup(i)
                        end
                    end
                end
            end
        end

        check_round_status() -- check current round status
    elseif gGlobalSyncTable.roundState == ROUND_RUNNERS_WIN or gGlobalSyncTable.roundState == ROUND_TAGGERS_WIN then
        timer = timer - 1
        gGlobalSyncTable.displayTimer = timer

        if timer <= 0 then
            if gGlobalSyncTable.doVoting and gGlobalSyncTable.autoMode then
                gGlobalSyncTable.roundState = ROUND_VOTING
                timer = 11 * 30
                log_to_console("Tag: Settings round state to ROUND_VOTING...")
            else
                if not gGlobalSyncTable.autoMode then
                    for i = 0, MAX_PLAYERS - 1 do
                        if gPlayerSyncTable[i].state ~= SPECTATOR then
                            gPlayerSyncTable[i].state = RUNNER
                        end
                    end

                    gGlobalSyncTable.roundState = ROUND_WAIT_PLAYERS

                    goto ifend
                end

                timer = 15 * 30 -- 15 seconds

                local level = levels[gGlobalSyncTable.selectedLevel]

                while blacklistedCourses[gGlobalSyncTable.selectedLevel] == true or table.contains(badLevels, level.level) or gGlobalSyncTable.selectedLevel == prevLevel do
                    gGlobalSyncTable.selectedLevel = math.random(1, #levels) -- select a random level

                    if level.level == LEVEL_TTC and isRomhack then
                        gGlobalSyncTable.ttcSpeed = math.random(0, 3)
                    end
                end

                prevLevel = gGlobalSyncTable.selectedLevel
                gGlobalSyncTable.roundState = ROUND_WAIT -- set round state to the intermission state

                log_to_console("Tag: Settings round state to ROUND_WAIT...")

                ::ifend::
            end
        end
    elseif gGlobalSyncTable.roundState == ROUND_HOT_POTATO_INTERMISSION then
        timer = timer - 1
        gGlobalSyncTable.displayTimer = timer

        if timer <= 0 then
            local currentConnectedCount = 0

            for i = 0, MAX_PLAYERS - 1 do
                if gNetworkPlayers[i].connected then
                    if gPlayerSyncTable[i].state ~= SPECTATOR and gPlayerSyncTable[i].state ~= WILDCARD_ROLE then
                        currentConnectedCount = currentConnectedCount + 1
                    end
                end
            end

            local amountOfTaggersNeeded = math.floor(currentConnectedCount / PLAYERS_NEEDED) -- always have the amount of the players needed, rounding down, be taggers
            if amountOfTaggersNeeded < 1 then amountOfTaggersNeeded = 1 end
            if gGlobalSyncTable.modifier == MODIFIER_ONE_TAGGER then
                amountOfTaggersNeeded = 1
            elseif gGlobalSyncTable.modifier == MODIFIER_ONE_RUNNER then
                amountOfTaggersNeeded = numPlayers - 1
            end

            timer = gGlobalSyncTable.amountOfTime

            log_to_console("Tag: Assigning Taggers")

            local amountOfTaggers = 0

            while amountOfTaggers < amountOfTaggersNeeded do
                -- select taggers
                local randomIndex = math.random(0, MAX_PLAYERS - 1) -- select random index

                if gPlayerSyncTable[randomIndex].state ~= TAGGER and gPlayerSyncTable[randomIndex].state ~= SPECTATOR and gPlayerSyncTable[randomIndex].state ~= WILDCARD_ROLE and gPlayerSyncTable[randomIndex].state ~= -1 and gNetworkPlayers[randomIndex].connected then
                    gPlayerSyncTable[randomIndex].state = TAGGER

                    log_to_console("Tag: Assigned " .. gNetworkPlayers[randomIndex].name .. " as Tagger or Infector")

                    amountOfTaggers = amountOfTaggers + 1
                end
            end

            hotPotatoTimerMultiplier = amountOfTaggersNeeded

            if hotPotatoTimerMultiplier > 2.3 then hotPotatoTimerMultiplier = 2.3 end

            gGlobalSyncTable.roundState = ROUND_ACTIVE
        end
    elseif gGlobalSyncTable.roundState == ROUND_VOTING then
        timer = timer - 1
        if timer >= 0 then
            gGlobalSyncTable.displayTimer = timer
        end

        if timer <= -3 * 30 then
            timer = 15 * 30 -- 15
            local voteResult = -1
            local maxVotes = -1
            for i = 1, 4 do
                -- get number of votes
                local votes = 0
                for v = 0, MAX_PLAYERS - 1 do
                    if gNetworkPlayers[v].connected then
                        if gPlayerSyncTable[v].votingNumber == i then
                            votes = votes + 1
                        end
                    end
                end

                if votes > maxVotes then
                    voteResult = i
                    maxVotes = votes
                end
            end

            if voteRandomLevels[voteResult] ~= nil then
                gGlobalSyncTable.selectedLevel = voteRandomLevels[voteResult]
            end

            local level = levels[gGlobalSyncTable.selectedLevel]

            while blacklistedCourses[gGlobalSyncTable.selectedLevel] == true or table.contains(badLevels, level.level) or gGlobalSyncTable.selectedLevel == prevLevel do
                gGlobalSyncTable.selectedLevel = math.random(1, #levels) -- select a random level

                if level.level == LEVEL_TTC and isRomhack then
                    gGlobalSyncTable.ttcSpeed = math.random(0, 3)
                end
            end

            prevLevel = gGlobalSyncTable.selectedLevel
            gGlobalSyncTable.roundState = ROUND_WAIT -- set round state to the intermission state
        end
    end
end

local function update()
    -- server update
    if network_is_server() then server_update() end

    if gPlayerSyncTable[0].invincTimer ~= nil and gPlayerSyncTable[0].invincTimer > 0 then
        gPlayerSyncTable[0].invincTimer = gPlayerSyncTable[0].invincTimer - 1
    end

    -- handle romhack overrides
    if  gGlobalSyncTable.romhackOverride ~= nil
    and gGlobalSyncTable.romhackOverride ~= prevRomhackOverride then
        -- get romhack
        local romhack = romhacks[gGlobalSyncTable.romhackOverride]

        if romhack == nil then return end

        -- set levels var to romhack override
        levels = romhack.levels

        -- check level reg stages
        if romhacks[3].levels ~= {} then
            for _, level in pairs(romhacks[3].levels) do
                table.insert(levels, level)
            end
        end

        -- popup
        djui_popup_create("Set romhack to\n" .. romhack.name, 3)

        -- set prev romhack override
        prevRomhackOverride = gGlobalSyncTable.romhackOverride
    end

    -- handle speed boost
    if speedBoostTimer < 20 * 30 and gPlayerSyncTable[0].state == TAGGER and boosts_enabled() then
        speedBoostTimer = speedBoostTimer + 1
    elseif gPlayerSyncTable[0].state ~= TAGGER or not boosts_enabled() then
        speedBoostTimer = 5 * 30 -- 5 seconds
    end

    -- set some variables if we are a spectator
    if gPlayerSyncTable[0].state == SPECTATOR then
        gPlayerSyncTable[0].amountOfTimeAsRunner = 0
        gPlayerSyncTable[0].amountOfTags = 0
    end

    -- set network descriptions
    for i = 0, MAX_PLAYERS - 1 do
        local np = gNetworkPlayers[i]
        local s = gPlayerSyncTable[i]
        network_player_set_description(np, get_role_name(s.state), 220, 220, 220, 255)
    end
end

---@param m MarioState
local function mario_update(m)
    if not gGlobalSyncTable.water then
        -- get rid of water
        for i = 1, 10 do
            set_environment_region(i, -10000)
        end
    else
        -- bring back water
        for i = 1, 10 do
            if waterRegions[i] ~= nil then
                set_environment_region(i, waterRegions[i])
            end
        end
    end

    -- disable special triple jump
    m.specialTripleJump = 0

    -- this ensures bljs are a no go, but hey, you can go as fast as a dive, so
    if not bljs_enabled() and m.forwardVel <= -48
    and (m.action == ACT_LONG_JUMP or m.action == ACT_LONG_JUMP_LAND
    or m.action == ACT_LONG_JUMP_LAND_STOP) then
        m.forwardVel = -48 -- this is the dive speed
    end

    m.peakHeight = m.pos.y -- disables fall damage

    -- disable hangable ceilings
    if m.ceil and m.ceil.type == SURFACE_HANGABLE then
        m.ceil.type = SURFACE_DEFAULT
    end

    -- set player that just joined to be invisible (-1 is not a valid state so)
    if gPlayerSyncTable[m.playerIndex].state == -1 then
        obj_set_model_extended(m.marioObj, E_MODEL_NONE)
    end

    -- this is for bowser stages
    if m.statusForCamera.cameraEvent == CAM_EVENT_BOWSER_INIT then
        m.statusForCamera.cameraEvent = 0
        m.area.camera.cutscene = 0
    end

    -- don't lose cap permanently (thanks shine thief)
    m.cap = 0

    -- this sets cap flags
    -- guide:
    -- | = add
    -- & ~ = subtract
    if  gPlayerSyncTable[m.playerIndex].state ~= SPECTATOR
    and gPlayerSyncTable[m.playerIndex].state ~= WILDCARD_ROLE then
        if gGlobalSyncTable.modifier ~= MODIFIER_FLY then
            m.flags = m.flags & ~MARIO_WING_CAP
        else
            m.flags = m.flags | MARIO_WING_CAP
        end
        m.flags = m.flags & ~MARIO_METAL_CAP
        m.flags = m.flags & ~MARIO_VANISH_CAP
    elseif gPlayerSyncTable[m.playerIndex].state == SPECTATOR then
        m.flags = m.flags | MARIO_WING_CAP
        m.flags = m.flags & ~MARIO_METAL_CAP
        m.flags = m.flags | MARIO_VANISH_CAP
    end

    -- set model state according to state
    if gPlayerSyncTable[m.playerIndex].state == TAGGER
    and gGlobalSyncTable.gamemode ~= ASSASSINS
    and gGlobalSyncTable.gamemode ~= DEATHMATCH
    and ((gGlobalSyncTable.modifier ~= MODIFIER_INCOGNITO
    or gPlayerSyncTable[0].state == TAGGER)
    or m.playerIndex == 0) then
        m.marioBodyState.modelState = MODEL_STATE_METAL
    elseif gPlayerSyncTable[m.playerIndex].state == SPECTATOR then
        m.marioBodyState.modelState = MODEL_STATE_NOISE_ALPHA -- vanish cap mario
    elseif gPlayerSyncTable[m.playerIndex].state == RUNNER
    or (gGlobalSyncTable.modifier == MODIFIER_INCOGNITO
    and gPlayerSyncTable[m.playerIndex].state ~= WILDCARD_ROLE) then
        m.marioBodyState.modelState = 0 -- normal
    end

    -- sync invinc timer to sync table invinc timer
    if gPlayerSyncTable[m.playerIndex].invincTimer ~= nil then
        m.invincTimer = gPlayerSyncTable[m.playerIndex].invincTimer
    end

    if m.playerIndex == 0 then
        -- load save data if we haven't
        if not initializedSaveData then
            initializedSaveData = true
            -- booleans
            if network_is_server() then
                if load_bool("bljs") ~= nil then gGlobalSyncTable.bljs = load_bool("bljs") end
                if load_bool("cannons") ~= nil then gGlobalSyncTable.cannons = load_bool("cannons") end
                if load_bool("water") ~= nil then gGlobalSyncTable.water = load_bool("water") end
                if load_bool("eliminateOnDeath") ~= nil then gGlobalSyncTable.eliminateOnDeath = load_bool("eliminateOnDeath") end
                if load_bool("voting") ~= nil then gGlobalSyncTable.voting = load_bool("voting") end
                if load_bool("autoMode") ~= nil then gGlobalSyncTable.autoMode = load_bool("autoMode") end
                if load_bool("boost") ~= nil then gGlobalSyncTable.boosts = load_bool("boost") end
                if load_bool("hazardSurfaces") ~= nil then gGlobalSyncTable.hazardSurfaces = load_bool("hazardSurfaces") end
            end
            if load_bool("useRomhackCam") ~= nil then useRomhackCam = load_bool("useRomhackCam") end
            if load_bool("autoHideHud") ~= nil then autoHideHud = load_bool("autoHideHud") end
            -- binds
            for i = 0, BIND_MAX do
                if load_int("bind_" .. tostring(i)) ~= nil then
                    binds[i].btn = load_int("bind_" .. tostring(i))
                end
            end
            -- stats
            -- load global stats
            if load_int("stats_global_playTime") ~= nil then
                stats.globalStats.playTime = load_int("stats_global_playTime")
            end

            if load_int("stats_global_runnerVictories") ~= nil then
                stats.globalStats.runnerVictories = load_int("stats_global_runnerVictories")
            end

            if load_int("stats_global_taggerVictories") ~= nil then
                stats.globalStats.taggerVictories = load_int("stats_global_taggerVictories")
            end

            if load_int("stats_global_totalTimeAsRunner") ~= nil then
                stats.globalStats.totalTimeAsRunner = load_int("stats_global_totalTimeAsRunner")
            end

            if load_int("stats_global_totalTags") ~= nil then
                stats.globalStats.totalTags = load_int("stats_global_totalTags")
            end

            -- load gamemode stats
            for i = MIN_GAMEMODE, MAX_GAMEMODE do
                if load_int("stats_" .. i .. "_playTime") ~= nil then
                    stats[i].playTime = load_int("stats_" .. i .. "_playTime")
                end
                if load_int("stats_" .. i .. "_runnerVictories") ~= nil then
                    stats[i].runnerVictories = load_int("stats_" .. i .. "_runnerVictories")
                end
                if load_int("stats_" .. i .. "_taggerVictories") ~= nil then
                    stats[i].taggerVictories = load_int("stats_" .. i .. "_taggerVictories")
                end
                if load_int("stats_" .. i .. "_totalTimeAsRunner") ~= nil then
                    stats[i].totalTimeAsRunner = load_int("stats_" .. i .. "_totalTimeAsRunner")
                end
                if load_int("stats_" .. i .. "_totalTags") ~= nil then
                    stats[i].totalTags = load_int("stats_" .. i .. "_totalTags")
                end
            end

            -- print some stats so players can get a gist of this guy's skill
            if stats.globalStats.runnerVictories > 0 then
                djui_chat_message_create_global(get_player_name(0) .. " \\#dcdcdc\\has won \\#FFE557\\" .. stats.globalStats.runnerVictories .. " \\#dcdcdc\\times as a \\#316BE8\\Runner\\#dcdcdc\\.")
            end
            if stats.globalStats.taggerVictories > 0 then
                djui_chat_message_create_global(get_player_name(0) .. " \\#dcdcdc\\has won \\#FFE557\\" .. stats.globalStats.taggerVictories .. " \\#dcdcdc\\times as a \\#E82E2E\\Tagger\\#dcdcdc\\.")
            end
        end

        ---@type NetworkPlayer
        local np = gNetworkPlayers[0]
        local selectedLevel = levels[gGlobalSyncTable.selectedLevel] -- get currently selected level

        -- check if mario is in the proper level, act, and area, if not, rewarp mario
        if gGlobalSyncTable.roundState == ROUND_ACTIVE
        or gGlobalSyncTable.roundState == ROUND_WAIT
        or gGlobalSyncTable.roundState == ROUND_HOT_POTATO_INTERMISSION
        or gGlobalSyncTable.roundState == ROUND_HIDING_SARDINES then
            if np.currLevelNum ~= selectedLevel.level or np.currAreaIndex ~= selectedLevel.area then
                -- attempt to warp to stage
                local warpSuccesful = warp_to_level(selectedLevel.level, selectedLevel.area, 0)

                if not warpSuccesful then
                    -- warping failed, so try a few common warp nodes
                    if warp_to_warpnode(selectedLevel.level, selectedLevel.area, 0, 10) then
                        return
                    end

                    if warp_to_warpnode(selectedLevel.level, selectedLevel.area, 0, 0) then
                        return
                    end

                    -- try randomly warping to warp nodes
                    for i = 1, 100 do
                        if warp_to_warpnode(selectedLevel.level, selectedLevel.area, 0, i) then
                            return
                        end
                    end

                    if network_is_server() then
                        -- if it failed and we are the server, assign it to the bad levels table
                        table.insert(badLevels, gGlobalSyncTable.selectedLevel)

                        local level = levels[gGlobalSyncTable.selectedLevel]

                        while blacklistedCourses[gGlobalSyncTable.selectedLevel] == true or table.contains(badLevels, level.level) or gGlobalSyncTable.selectedLevel == prevLevel do
                            gGlobalSyncTable.selectedLevel = course_to_level(math.random(COURSE_MIN, COURSE_MAX)) -- select a random level
                        end

                        prevLevel = gGlobalSyncTable.selectedLevel
                    end
                end
            end
        elseif gGlobalSyncTable.roundState == ROUND_WAIT_PLAYERS and not gGlobalSyncTable.autoMode then
            if np.currLevelNum ~= gLevelValues.entryLevel then
                warp_to_start_level()
            end
        end

        -- spawn pipes
        -- make sure the level has pipes (found in level table), then check if they aren't spawned
        if selectedLevel.pipes ~= nil
        and obj_get_first_with_behavior_id(id_bhvPipe) == nil
        and np.currLevelNum == selectedLevel.level then
            -- spawn pipes
            for pipesIndex, pipes in pairs(selectedLevel.pipes) do
                for _, pipe in pairs(pipes) do
                    spawn_non_sync_object(id_bhvPipe, E_MODEL_BITS_WARP_PIPE,
                    pipe.x, pipe.y, pipe.z, function (o)
                        o.oPipesLevel = gGlobalSyncTable.selectedLevel
                        o.oPipesIndex = pipesIndex -- our pipes index
                    end)
                end
            end
        end

        -- handle pipe invinc timers and such, too lazy to write what this does
        pipeTimer = pipeTimer + 1
        if pipeTimer > 3 * 30 then
            pipeUse = 0
        end

        -- get rid of unwated behaviors (no better way to do it other than this block of text)
        obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhv1Up))
        obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvBubba))
        obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvOneCoin))
        obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvRedCoin))
        obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvRedCoinStarMarker))
        obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvHeaveHo))
        obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvHeaveHoThrowMario))
        obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvWhompKingBoss))
        obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvSmallWhomp))
        obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvMoneybag))
        obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvMoneybagHidden))
        obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvSpindrift))
        obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvYoshi))
        obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvBulletBill))
        obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvHoot))
        obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvTweester))
        obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvBowser))
        obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvBowserBodyAnchor))
        obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvBowserTailAnchor))
        obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvKingBobomb))
        obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvStar))
        obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvStarSpawnCoordinates))
        obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvSpawnedStar))
        obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvKoopaShell))
        obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvWingCap))
        obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvMetalCap))
        obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvVanishCap))
        obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvWarpPipe))
        obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvBoo))

        -- water level diamond breaks water being disabled, so just get rid of it
        if not gGlobalSyncTable.water then
            obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvWaterLevelDiamond))
        end

        -- delete objects depending if romhacks are off
        if not isRomhack then
            obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvActivatedBackAndForthPlatform))
            obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvExclamationBox))
        end

        -- delete unwanted behaviors in level
        if selectedLevel.unwantedBhvs ~= nil then
            for _, bhv in pairs(selectedLevel.unwantedBhvs) do
                obj_mark_for_deletion(obj_get_first_with_behavior_id(bhv))
            end
        end

        -- check if we are in the room the level wants us to be in
        if  selectedLevel.room ~= nil
        and current_mario_room_check(selectedLevel.room) ~= 1
        and np.currAreaSyncValid and (roomTimer > 5 * 30
        or  gGlobalSyncTable.roundState == ROUND_WAIT) then
            local randomLevel = gGlobalSyncTable.selectedLevel + 1
            if levels[randomLevel] == nil then
                randomLevel = gGlobalSyncTable.selectedLevel - 1
            end
            warp_to_level(levels[randomLevel].level, 1, 0)
        elseif selectedLevel.room ~= nil and np.currAreaSyncValid
        and current_mario_room_check(selectedLevel.room) ~= 1 then
            roomTimer = roomTimer + 1

            if roomTimer % 30 == 1 then
                play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
            end
        else
            roomTimer = 0
        end

        -- handle speed boost, this is a fun if statement
        if m.controller.buttonPressed & binds[BIND_BOOST].btn ~= 0
        and speedBoostTimer >= 20 * 30
        and gPlayerSyncTable[0].state == TAGGER
        and boosts_enabled() then
            speedBoostTimer = 0
        end

        -- set our initial state
        if np.currAreaSyncValid and gPlayerSyncTable[0].state == -1 then
            if gGlobalSyncTable.roundState == ROUND_ACTIVE
            or gGlobalSyncTable.roundState == ROUND_HOT_POTATO_INTERMISSION
            or gGlobalSyncTable.roundState == ROUND_HIDING_SARDINES then
                if gGlobalSyncTable.gamemode == TAG
                or gGlobalSyncTable.gamemode == INFECTION
                or gGlobalSyncTable.gamemode == HOT_POTATO
                or gGlobalSyncTable.gamemode == ASSASSINS
                or gGlobalSyncTable.gamemode == TERMINATOR then
                    gPlayerSyncTable[0].state = WILDCARD_ROLE
                else
                    gPlayerSyncTable[0].state = TAGGER
                end
            else
                gPlayerSyncTable[0].state = RUNNER
            end
        end

        -- desync timer
        if desyncTimer <= 0 then
            m.freeze = 1
        end

        -- handle leaderboard and desync timer
        if gGlobalSyncTable.roundState == ROUND_RUNNERS_WIN or gGlobalSyncTable.roundState == ROUND_TAGGERS_WIN then
            m.freeze = 1
            set_mario_action(m, ACT_NOTHING, 0)
        elseif desyncTimer > 0 or network_is_server() then
            if showSettings or isPaused then
                m.freeze = 1
            else
                m.freeze = 0
            end
        end

        -- sync tick tock clock speed
        if get_ttc_speed_setting() ~= gGlobalSyncTable.ttcSpeed then
            set_ttc_speed_setting(gGlobalSyncTable.ttcSpeed)
        end

        -- handle level surface
        if levels[gGlobalSyncTable.selectedLevel].overrideSurfaceType ~= nil
        and levels[gGlobalSyncTable.selectedLevel].overrideSurfaceType[m.floor.type] ~= nil then
            m.floor.type = levels[gGlobalSyncTable.selectedLevel].overrideSurfaceType[m.floor.type]
        end

        -- handle play time stats
        if gGlobalSyncTable.roundState == ROUND_ACTIVE
        or gGlobalSyncTable.roundState == ROUND_HOT_POTATO_INTERMISSION
        or gGlobalSyncTable.roundState == ROUND_HIDING_SARDINES then
            if stats[gGlobalSyncTable.gamemode].playTime ~= nil then
                stats[gGlobalSyncTable.gamemode].playTime = stats[gGlobalSyncTable.gamemode].playTime + 1
            end

            stats.globalStats.playTime = stats.globalStats.playTime + 1
        end
    end
end

local function before_set_mario_action(m, action)
    if m.playerIndex == 0 then
        -- cancel any unwanted action
        if action == ACT_WAITING_FOR_DIALOG
        or action == ACT_READING_SIGN
        or action == ACT_READING_AUTOMATIC_DIALOG
        or action == ACT_READING_NPC_DIALOG
        or action == ACT_JUMBO_STAR_CUTSCENE
        or action == ACT_BURNING_FALL
        or action == ACT_BURNING_JUMP then
            return 1
        end
    end
end

---@param m MarioState
local function before_phys(m)
    if m.playerIndex ~= 0 then return end

    -- handle speed boost
    if speedBoostTimer < 5 * 30 and gPlayerSyncTable[0].state == TAGGER then -- this allows for 5 seconds of speedboost
        -- mario's speed be goin willlld
        if  m.action ~= ACT_BACKWARD_AIR_KB
        and m.action ~= ACT_FORWARD_AIR_KB
        and m.action ~= ACT_HARD_BACKWARD_AIR_KB
        and m.action ~= ACT_HARD_FORWARD_AIR_KB
        and m.action ~= ACT_BACKWARD_AIR_KB
        and m.action ~= ACT_FORWARD_AIR_KB then
            m.vel.x = m.vel.x * 1.25
            m.vel.z = m.vel.z * 1.25
        else
            m.vel.x = m.vel.x * 1.05
            m.vel.z = m.vel.z * 1.05
        end

        -- tells other players we are boosting
        gPlayerSyncTable[0].boosting = true
    else
        -- we aren't boosting, so set boosting var to false
        gPlayerSyncTable[0].boosting = false
    end

    -- this function handles boost trail
    generate_boost_trail()
end

local function hud_round_status()
    -- if you want comments on the hud stuff, you ain't getting it, I barely undestand it
    -- but I understand it just enough to make the huds I make

    local text = ""
    local fade = hudFade

    -- set text
    if gGlobalSyncTable.roundState == ROUND_WAIT_PLAYERS then
        if gGlobalSyncTable.autoMode then
            text = "Waiting for Players"
        else
            text = "Waiting for Host"
        end
    elseif gGlobalSyncTable.roundState == ROUND_ACTIVE then
        text = "Time Remaining: " ..
            math.floor(gGlobalSyncTable.displayTimer / 30) -- divide by 30 for seconds and not frames (all game logic runs at 30fps)

        -- if auto hide hud is on, and we are less than 20 seconds away from the round ending, make fade hud peek
        if math.floor(gGlobalSyncTable.displayTimer / 30) <= 20 then
            fade = hudFade + linear_interpolation(clampf(gGlobalSyncTable.displayTimer / 30, 15, 20), 128, 0, 15, 20)

            fade = clampf(fade, 0, 255)
        end
    elseif gGlobalSyncTable.roundState == ROUND_HIDING_SARDINES then
        text = "You have " ..
        math.floor(gGlobalSyncTable.displayTimer / 30)
        .. " seconds to hide!" -- divide by 30 for seconds and not frames (all game logic runs at 30fps)

        -- if auto hide hud is on, and we are less than 10 seconds away from the sardine hiding session ending, make fade hud peek
        if math.floor(gGlobalSyncTable.displayTimer / 30) <= 10
        and gPlayerSyncTable[0].state == RUNNER then
            fade = hudFade + linear_interpolation(clampf(gGlobalSyncTable.displayTimer / 30, 7, 10), 128, 0, 7, 10)

            fade = clampf(fade, 0, 255)
        end
    elseif gGlobalSyncTable.roundState == ROUND_WAIT then
        text = "Starting in " ..
            math.floor(gGlobalSyncTable.displayTimer / 30) + 1 -- divide by 30 for seconds and not frames (all game logic runs at 30fps)
    elseif gGlobalSyncTable.roundState == ROUND_RUNNERS_WIN or gGlobalSyncTable.state == ROUND_TAGGERS_WIN then
        text = "Starting new round"
    elseif gGlobalSyncTable.roundState == ROUND_HOT_POTATO_INTERMISSION then
        text = "Intermission: " ..
            math.floor(gGlobalSyncTable.displayTimer / 30) + 1 -- divide by 30 for seconds and not frames (all game logic runs at 30fps)
    else
        return
    end

    local scale = 1.5

    -- get width of screen and text
    local screenWidth = djui_hud_get_screen_width()
    local width = djui_hud_measure_text(text) * scale

    local x = (screenWidth - width) / 2.0
    local y = 0

    -- render rect
    djui_hud_set_color(20, 20, 22, fade / 1.4)
    djui_hud_render_rect_outlined(x - (12 * scale), y, width + (24 * scale), (32 * scale), 35, 35, 35, 4, fade / 1.4)

    -- render text
    djui_hud_set_color(255, 255, 255, fade)
    djui_hud_print_text(text, x, y, scale)
end

local function hud_gamemode()
    local text = get_gamemode(gGlobalSyncTable.gamemode)
    local scale = 1

    -- get width of screen and text
    local width = djui_hud_measure_text(strip_hex(text)) * scale

    local x = 12 * scale
    local y = 0

    -- render rect
    djui_hud_set_color(20, 20, 22, hudFade / 1.4)
    djui_hud_render_rect_outlined(x - (12 * scale), y, width + (24 * scale), (32 * scale), 35, 35, 35, 4 / 1.5, hudFade / 1.4)

    -- render text
    djui_hud_set_color(220, 220, 220, hudFade)
    djui_hud_print_colored_text(text, x, y, scale, hudFade)
end

local function hud_modifier()
    local text = get_modifier_text()
    local scale = 1

    -- get width of screen and text
    local screenWidth = djui_hud_get_screen_width()
    local width = djui_hud_measure_text(strip_hex(text)) * scale

    local x = screenWidth - width - (12 * scale)
    local y = 0

    -- render rect
    djui_hud_set_color(20, 20, 22, hudFade / 1.4)
    djui_hud_render_rect_outlined(x - (12 * scale), y, width + (24 * scale), (32 * scale), 35, 35, 35, 4 / 1.5, hudFade / 1.4)

    -- render text
    djui_hud_set_color(220, 220, 220, hudFade)
    djui_hud_print_colored_text(text, x, y, scale, hudFade)
end

local function hud_boost()
    if gGlobalSyncTable.roundState == ROUND_VOTING then return end
    if gPlayerSyncTable[0].state ~= TAGGER then return end
    if not boosts_enabled() then return end

    djui_hud_set_font(FONT_NORMAL)
    djui_hud_set_resolution(RESOLUTION_N64)

    local screenWidth  = djui_hud_get_screen_width()
    local screenHeight = djui_hud_get_screen_height()

    local scale        = 1
    local width        = 128 * scale
    local height       = 16 * scale
    local x            = math.floor((screenWidth - width) / 2)
    local y            = math.floor(screenHeight - height - 4 * scale)
    local boostTime    = speedBoostTimer / 30 / 20

    djui_hud_set_color(0, 0, 0, 128)
    djui_hud_render_rect(x, y, width, height)

    x = x + 2 * scale
    y = y + 2 * scale
    width = width - 4 * scale
    height = height - 4 * scale
    width = math.floor(width * boostTime)
    djui_hud_set_color(0, 137, 237, 128)
    djui_hud_render_rect(x, y, width, height)

    if speedBoostTimer < 5 * 30 then
        text = "Boosting"
    elseif speedBoostTimer >= 5 * 30 and speedBoostTimer < 20 * 30 then
        text = "Recharging"
    else
        text = "Boost (" .. button_to_text(binds[BIND_BOOST].btn) .. ")"
    end

    scale = 0.25
    width = djui_hud_measure_text(text) * scale
    height = 32 * scale
    x = (screenWidth - width) / 2
    y = screenHeight - 28

    djui_hud_set_color(0, 0, 0, 128)
    djui_hud_render_rect(x - 6, y, width + 12, height)

    djui_hud_set_color(0, 162, 255, 128)
    djui_hud_print_text(text, x, y, scale)
end

local function hud_render()
    -- if we are hiding the hud as a spectator, don't render the hud
    if spectatorHideHud then return end

    -- set djui font and resolution
    djui_hud_set_font(FONT_NORMAL)
    djui_hud_set_resolution(RESOLUTION_DJUI)

    -- fade
    if (is_standing_still()
    or not autoHideHud)
    and gGlobalSyncTable.roundState ~= ROUND_VOTING then
        hudFade = hudFade + 40
    else
        hudFade = hudFade - 40
    end

    hudFade = clampf(hudFade, 0, 255)

    -- render hud
    if gGlobalSyncTable.roundState ~= ROUND_RUNNERS_WIN
    and gGlobalSyncTable.roundState ~= ROUND_TAGGERS_WIN then
        hud_round_status()
        hud_gamemode()
        hud_modifier()
        hud_boost()
    end

    -- hide hud
    hud_hide()
end

---@param a MarioState
---@param v MarioState
local function allow_pvp(a, v)
    -- don't allow spectators to attack players, vice versa
    if gPlayerSyncTable[v.playerIndex].state == SPECTATOR or gPlayerSyncTable[a.playerIndex].state == SPECTATOR then return false end
    -- if the modifier is friendly fire, don't continue
    if gGlobalSyncTable.modifier == MODIFIER_FRIENDLY_FIRE then return end
    -- check if 2 runners are trying to attack eachother
    if gPlayerSyncTable[v.playerIndex].state == RUNNER and gPlayerSyncTable[a.playerIndex].state == RUNNER then return false end
    -- check if 2 taggers are trying to attack eachother
    if gPlayerSyncTable[v.playerIndex].state == TAGGER and gPlayerSyncTable[a.playerIndex].state == TAGGER
    and gGlobalSyncTable.gamemode ~= ASSASSINS and gGlobalSyncTable.gamemode ~= DEATHMATCH then return false end
end

---@param m MarioState
---@param o Object
---@param intee InteractionType
local function allow_interact(m, o, intee)
    -- check if intee is unwanted
    if intee == INTERACT_STAR_OR_KEY
    or intee == INTERACT_KOOPA_SHELL then
        return false
    end

    -- disable warp interaction
    if (intee == INTERACT_WARP or intee == INTERACT_WARP_DOOR)
    and gGlobalSyncTable.roundState ~= ROUND_WAIT_PLAYERS then
        return false
    end

    -- disable banned level interactions
    local selectedLevel = levels[gGlobalSyncTable.selectedLevel]
    if selectedLevel.disabledBhvs ~= nil then
        for _, bhv in pairs(selectedLevel.disabledBhvs) do
            if get_id_from_behavior(o.behavior) == bhv then
                return false
            end
        end
    end

    -- dont allow spectator to interact with objects, L
    -- they are allowed to interact with pipes because that is handled with distance,
    -- and not interaction, so such restrictions would be handled on the behavior
    if gPlayerSyncTable[m.playerIndex].state == SPECTATOR then return false end
end

local function on_warp()
    local m = gMarioStates[0]
    local level = levels[gGlobalSyncTable.selectedLevel]

    if level ~= nil and level.spawnLocation ~= nil then
        vec3f_copy(m.pos, level.spawnLocation)

        reset_standing_still()
    end
end

local function level_init()
    -- get rid of water
    for i = 1, 10 do
        waterRegions[i] = get_environment_region(i)
        if not gGlobalSyncTable.water then
            set_environment_region(i, -10000)
        end
    end
end

---@param m MarioState
local function act_nothing(m)
    -- great action am I right
    m.forwardVel = 0
    m.vel.x = 0
    m.vel.y = 0
    m.vel.z = 0
    m.slideVelX = 0
    m.slideVelZ = 0
    -- this is to freeze mario's animation
    m.marioObj.header.gfx.animInfo.animFrame = m.marioObj.header.gfx.animInfo.animFrame - (m.marioObj.header.gfx.animInfo.animAccel + 1)

    -- get out of the action if round state is wait or wait players
    if gGlobalSyncTable.roundState == ROUND_WAIT_PLAYERS
    or gGlobalSyncTable.roundState == ROUND_WAIT then
        set_mario_action(m, ACT_FREEFALL, 0)
    end
end

-- runs once per frame (all game logic runs at 30fps)
hook_event(HOOK_UPDATE, update)
-- runs when the hud is rendered
hook_event(HOOK_ON_HUD_RENDER, hud_render)
-- runs when mario is updated
hook_event(HOOK_MARIO_UPDATE, mario_update)
-- runs before mario's physic step
hook_event(HOOK_BEFORE_PHYS_STEP, before_phys)
-- runs right before mario is about to attack
hook_event(HOOK_ALLOW_PVP_ATTACK, allow_pvp)
-- runs right before mario is about to interact with an object
hook_event(HOOK_ALLOW_INTERACT, allow_interact)
-- runs right before mario sets his action
hook_event(HOOK_BEFORE_SET_MARIO_ACTION, before_set_mario_action)
-- runs on warp
hook_event(HOOK_ON_WARP, on_warp)
-- runs on level initialization
hook_event(HOOK_ON_LEVEL_INIT, level_init)
-- make sure the user can never pause exit
hook_event(HOOK_ON_PAUSE_EXIT, function() return false end)
-- this hook allows us to walk on lava and quicksand
hook_event(HOOK_ALLOW_HAZARD_SURFACE, function() return gGlobalSyncTable.hazardSurfaces end)
-- disables dialogs
hook_event(HOOK_ON_DIALOG, function () return false end)

-- make ACT_NOTHING do something, wild ain't it
hook_mario_action(ACT_NOTHING, act_nothing)

-- Good job, you made it to the end of your file. I'd suggest heading over to tag.lua next!
