-----------------------------------
-- Valkurm Mobs Era Module
-----------------------------------
require("scripts/globals/dynamis")
require("scripts/globals/zone")
-----------------------------------
xi = xi or {}
xi.dynamis = xi.dynamis or {}

local dragontraps = { "dragontrap1_killed", "dragontrap2_killed", "dragontrap3_killed" }
local morbols = { "morbol1_killed", "morbol2_killed" }
local flies = { "fly1_killed", "fly2_killed", "fly3_killed" }

local function checkFlytrapKills(mob)
    local zone = mob:getZone()
    local killed = 0
    for _, flytrap in pairs(dragontraps) do
        if zone:getLocalVar(flytrap) == 1 then
            killed = killed + 1
        end
    end

    return killed
end

local function checkMorbolKills(mob)
    local zone = mob:getZone()
    local killed = 0
    for _, morbol in pairs(morbols) do
        if zone:getLocalVar(morbol) == 1 then
            killed = killed + 1
        end
    end

    return killed
end

xi.dynamis.nightmareFlyCheck = function(zone)
    local playersInZone = zone:getPlayers()
    local req = 0
    for _, fly in pairs(flies) do
        if zone:getLocalVar(fly) == 1 then
            req = req + 1
        end
    end

    if req == 3 and zone:getLocalVar("SJUnlock") ~= 1 then
        for _, playerEntity in pairs(playersInZone) do
            if  playerEntity:hasStatusEffect(xi.effect.SJ_RESTRICTION) then -- Does player have SJ restriction?
                playerEntity:delStatusEffect(xi.effect.SJ_RESTRICTION) -- Remove SJ restriction
            end
        end

        zone:setLocalVar('SJUnlock', 1)
    end
end

xi.dynamis.onSpawnCirrate = function(mob)
    xi.dynamis.cirrateBuffs =
    {
        { { "dragontrap1_killed", "dragontrap2_killed", "dragontrap3_killed" }, "putridbreathcap", 3, "dragon_killed", nil, 1609 },
        { { "fairy_ring_killed" }, "miasmicbreathpower", 30, "fairy_killed", 40, 1605 },
        { { "nanatina_killed" }, "fragrantbreathduration", 30, "nana_killed", nil, 1607 },
        { { "stcemqestcint_killed" }, "vampiriclashpower", 1, "stcem_killed", nil, 1611 },
    }
    xi.dynamis.cirrateSkills = -- All chance values are the max value they will go until.
    {
        --  [skillID] = {chance, "Mob's Name"},
        [1607] = 20, -- Fragrant Breath
        [1605] = 20, -- Miasmic Breath
        [1609] = 20, -- Putrid Breath
        [1611] = 20, -- Vampiric Lash
        [1610] = 20, -- Extremely Bad Breath
    }

    mob:addListener("WEAPONSKILL_STATE_EXIT", "CIRRATE_WEAPONSKILL_STATE_EXIT", function(mobA)
        mobA:getZone():setLocalVar("cirrate_tp", 0)
        mobA:setTP(0)
    end)

    mob:setRoamFlags(xi.roamFlag.SCRIPTED)
    xi.dynamis.setMegaBossStats(mob)
    -- Set Mods
    mob:setSpeed(140)
    mob:addMod(xi.mod.REGAIN, 1250)
    mob:setAutoAttackEnabled(false)
end

xi.dynamis.onSpawnFairy = function(mob)
    mob:setSpeed(140)
    xi.dynamis.onSpawnNoAuto(mob)
end

xi.dynamis.onEngageMorbol = function(mob, target)
    local cirrate = GetMobByID(mob:getLocalVar("ParentID"))
    if cirrate then
        mob:setSpeed(cirrate:getSpeed())
    end
end

xi.dynamis.onEngagedCirrate = function(mob, target)
    local zoneID = mob:getZoneID()
    local flytrapKills = checkFlytrapKills(mob)
    local morbolKills = checkMorbolKills(mob)
    if
        flytrapKills < 3 and
        morbolKills == 0 and
        mob:getLocalVar("spawnedPets") == 0
    then
        mob:setLocalVar("spawnedPets", 1)
        xi.dynamis.nmDynamicSpawn(289, 24, true, zoneID, target, mob)
        xi.dynamis.nmDynamicSpawn(290, 24, true, zoneID, target, mob)
    end
end

xi.dynamis.onFightCirrate = function(mob, target)
    local zone = mob:getZone()
    local buffs = xi.dynamis.cirrateBuffs
    local skills = xi.dynamis.cirrateSkills
    local itTotal = 0
    local total = skills[1607] + skills[1605] + skills[1609] + skills[1611] + skills[1610]
    local rand = math.random(1, total)

    if #buffs > 0 then
        local selection = math.random(1, #buffs)
        local count = 0
        for _, var in pairs(buffs[selection][1]) do
            if zone:getLocalVar(var) == 1 then
                count = count + 1
            end
        end

        if count > 0 then
            mob:setLocalVar(buffs[selection][2], buffs[selection][3])
            zone:setLocalVar(buffs[selection][4], 1)
            if buffs[selection][5] ~= nil then
                mob:setSpeed(buffs[selection][5])
            end

            xi.dynamis.cirrateSkills[buffs[selection][6]] = 12  -- Updates first entry to 12 if the mob is dead.
            table.remove(buffs, selection)
        end
    end

    if mob:getTP() >= 2000 and zone:getLocalVar("cirrate_tp") == 0 then
        zone:getLocalVar("cirrate_tp", 1)
        for skill, chance in pairs(skills) do
            if rand <= itTotal + chance then
                return mob:useMobAbility(skill)
            else
                itTotal = itTotal + chance
            end
        end
    end
end

xi.dynamis.onWeaponskillPrepCirrate = function(mob)
end

xi.dynamis.onWeaponskillPrepNantina = function(mob)
    local charm = math.random(1, 100)

    if charm <= 10 then
        return 1619 -- Attractant
    else
        if mob:getHPP() > 25 then
            return 1617
        else
            return 1618
        end
    end
end
