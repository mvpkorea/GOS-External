--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Initialize:                                                                                                                                          
    -- Return:                                                                                                                                          
        if _G.GamsteronMorganaLoaded or myHero.charName ~= "Morgana" then
            return
        end
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    -- Load Core:                                                                                                                                       
        local _Update = true
        ------------------------------------------------------------------------------------------------------------------------------------------------
        if _Update then
            if not FileExist(COMMON_PATH .. "GamsteronCore.lua") then
                DownloadFileAsync("https://raw.githubusercontent.com/gamsteron/GOS-External/master/Common/GamsteronCore.lua", COMMON_PATH .. "GamsteronCore.lua", function() end)
                while not FileExist(COMMON_PATH .. "GamsteronCore.lua") do end
            end
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        require('GamsteronCore')
        ------------------------------------------------------------------------------------------------------------------------------------------------
        if _G.GamsteronCoreUpdated then
            return
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        local Core = _G.GamsteronCore
        ------------------------------------------------------------------------------------------------------------------------------------------------
        local Interrupter = Core:Interrupter()
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    -- Load Prediction:                                                                                                                                       
        if _Update then
            if not FileExist(COMMON_PATH .. "GamsteronPrediction.lua") then
                DownloadFileAsync("https://raw.githubusercontent.com/gamsteron/GOS-External/master/Common/GamsteronPrediction.lua", COMMON_PATH .. "GamsteronPrediction.lua", function() end)
                while not FileExist(COMMON_PATH .. "GamsteronPrediction.lua") do end
            end
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        require('GamsteronPrediction')
        ------------------------------------------------------------------------------------------------------------------------------------------------
        if _G.GamsteronPredictionUpdated then
            return
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        local Prediction = _G.GamsteronPrediction
	----------------------------------------------------------------------------------------------------------------------------------------------------
	-- Auto Update:                                                                                                                                     
        if _Update then
            local args =
            {
                version = 0.01,
                ----------------------------------------------------------------------------------------------------------------------------------------
                scriptPath = COMMON_PATH .. "GamsteronMorgana.lua",
                scriptUrl = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Champions/GamsteronMorgana.lua",
                ----------------------------------------------------------------------------------------------------------------------------------------
                versionPath = COMMON_PATH .. "GamsteronMorgana.version",
                versionUrl = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Champions/GamsteronMorgana.version"
            }
            --------------------------------------------------------------------------------------------------------------------------------------------
            local success, version = Core:AutoUpdate(args)
            --------------------------------------------------------------------------------------------------------------------------------------------
            if success then
                print("GamsteronMorgana updated to version " .. version .. ". Please Reload with 2x F6 !")
                _G.GamsteronMorganaUpdated = true
            end
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        if _G.GamsteronMorganaUpdated then
            return
        end
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Locals:                                                                                                                                              
    local Menu
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    local Orbwalker, TargetSelector, ObjectManager, Damage, Spells
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    local _Q							= _G._Q
	local _W							= _G._W
	local _E							= _G._E
    local _R							= _G._R
    local pairs							= _G.pairs
    local myHero						= _G.myHero
    local GameTimer                     = _G.Game.Timer
    local GameCanUseSpell               = _G.Game.CanUseSpell
    local MathMax                       = _G.math.max
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants:                                                                                                                                           
    local SPELLTYPE_LINE            = 0
    local SPELLTYPE_CIRCLE          = 1
    local SPELLTYPE_CONE            = 2
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    local COLLISION_MINION          = 0
    local COLLISION_ALLYHERO        = 1
    local COLLISION_ENEMYHERO       = 2
    local COLLISION_YASUOWALL       = 3
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    local TEAM_ALLY						= myHero.team
	local TEAM_ENEMY					= 300 - TEAM_ALLY
    local TEAM_JUNGLE					= 300
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    local ORBWALKER_MODE_NONE           = -1
    local ORBWALKER_MODE_COMBO          = 0
    local ORBWALKER_MODE_HARASS         = 1
    local ORBWALKER_MODE_LANECLEAR      = 2
    local ORBWALKER_MODE_JUNGLECLEAR    = 3
    local ORBWALKER_MODE_LASTHIT        = 4
    local ORBWALKER_MODE_FLEE           = 5
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    local DAMAGE_TYPE_PHYSICAL			= 0
	local DAMAGE_TYPE_MAGICAL			= 1
    local DAMAGE_TYPE_TRUE				= 2
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    local HEROES_SPELL                  = 0
    local HEROES_ATTACK                 = 1
    local HEROES_IMMORTAL               = 2
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Load:                                                                                                                                                
    do
        local QData =
        {
            Type = SPELLTYPE_LINE, Aoe = false, From = myHero,
            Delay = 0.25, Radius = 70, Range = 1175, Speed = 1200,
            Collision = true, MaxCollision = 0, CollisionObjects = { COLLISION_MINION, COLLISION_YASUOWALL }
        }
        local WData =
        {
            Type = SPELLTYPE_CIRCLE, Aoe = false, Collision = false, From = myHero,
            Delay = 0.25, Radius = 150, Range = 900, Speed = math.huge
        }
        local EData = { Range = 800 }
        local RData = { Range = 625 }
        ------------------------------------------------------------------------------------------------------------------------------------------------
        local Q_KS_ON = false
        local Q_AUTO_ON = true
        local Q_COMBO_ON = true
        local Q_DISABLEAA = false
        local Q_HARASS_ON = false
        local Q_INTERRUPTER_ON = true
        local Q_KS_MINHP = 200
        local Q_KS_HITCHANCE = 3
        local Q_AUTO_HITCHANCE = 3
        local Q_COMBO_HITCHANCE = 3
        local W_KS_ON = false
        local W_KS_MINHP = 200
        local W_AUTO_ON = true
        local W_COMBO_ON = false
        local W_HARASS_ON = false
        local W_CLEAR_ON = false
        local W_CLEAR_MINX = 3
        local E_AUTO_ON = true
        local E_ALLY_ON = true
        local E_SELF_ON = true
        local R_KS_ON = false
        local R_KS_MINHP = 200
        local R_AUTO_ON = true
        local R_AUTO_ENEMIESX = 3
        local R_AUTO_RANGEX = 300
        local R_COMBO_ON = false
        local R_HARASS_ON = false
        local R_COMBO_ENEMIESX = 3
        local R_COMBO_RANGEX = 300
        ------------------------------------------------------------------------------------------------------------------------------------------------
        local function LoadMenu()
            Menu = MenuElement({name = "Gamsteron Morgana", id = "GamsteronMorgana", type = _G.MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GoSExt/master/Icons/morganads83fd.png" })
                -- Q
                Menu:MenuElement({name = "Q settings", id = "qset", type = _G.MENU })
                    -- Disable Attack
                    Menu.qset:MenuElement({id = "disaa", name = "Disable attack if ready or almostReady", value = false, callback = function(value) Q_DISABLEAA = value end})
                    -- Interrupt:
                    Menu.qset:MenuElement({id = "interrupter", name = "Interrupter", value = true, callback = function(value) Q_INTERRUPTER_ON = value end})
                    -- KS
                    Menu.qset:MenuElement({name = "KS", id = "killsteal", type = _G.MENU })
                        Menu.qset.killsteal:MenuElement({id = "enabled", name = "Enabled", value = false, callback = function(value) Q_KS_ON = value end})
                        Menu.qset.killsteal:MenuElement({id = "minhp", name = "minimum enemy hp", value = 200, min = 1, max = 300, step = 1, callback = function(value) Q_KS_MINHP = value end})
                        Menu.qset.killsteal:MenuElement({id = "hitchance", name = "Hitchance", value = 3, drop = { "Collision", "Normal", "High", "Immobile" }, callback = function(value) Q_KS_HITCHANCE = value end })
                    -- Auto
                    Menu.qset:MenuElement({name = "Auto", id = "auto", type = _G.MENU })
                        Menu.qset.auto:MenuElement({id = "enabled", name = "Enabled", value = true, callback = function(value) Q_AUTO_ON = value end})
                        Menu.qset.auto:MenuElement({name = "Use on:", id = "useon", type = _G.MENU })
                            Core:OnEnemyHeroLoad(function(hero) Menu.qset.auto.useon:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
                        Menu.qset.auto:MenuElement({id = "hitchance", name = "Hitchance", value = 3, drop = { "Collision", "Normal", "High", "Immobile" }, callback = function(value) Q_AUTO_HITCHANCE = value end })
                    -- Combo / Harass
                    Menu.qset:MenuElement({name = "Combo / Harass", id = "comhar", type = _G.MENU })
                        Menu.qset.comhar:MenuElement({id = "combo", name = "Combo", value = true, callback = function(value) Q_COMBO_ON = value end})
                        Menu.qset.comhar:MenuElement({id = "harass", name = "Harass", value = false, callback = function(value) Q_HARASS_ON = value end})
                        Menu.qset.comhar:MenuElement({name = "Use on:", id = "useon", type = _G.MENU })
                            Core:OnEnemyHeroLoad(function(hero) Menu.qset.comhar.useon:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
                        Menu.qset.comhar:MenuElement({id = "hitchance", name = "Hitchance", value = 3, drop = { "Collision", "Normal", "High", "Immobile" }, callback = function(value) Q_COMBO_HITCHANCE = value end })
                -- W
                Menu:MenuElement({name = "W settings", id = "wset", type = _G.MENU })
                    -- KS
                    Menu.wset:MenuElement({name = "KS", id = "killsteal", type = _G.MENU })
                        Menu.wset.killsteal:MenuElement({id = "enabled", name = "Enabled", value = false, callback = function(value) W_KS_ON = value end})
                        Menu.wset.killsteal:MenuElement({id = "minhp", name = "minimum enemy hp", value = 200, min = 1, max = 300, step = 1, callback = function(value) W_KS_MINHP = value end})
                    -- Auto
                    Menu.wset:MenuElement({name = "Auto", id = "auto", type = _G.MENU })
                        Menu.wset.auto:MenuElement({id = "enabled", name = "Enabled", value = true, callback = function(value) W_AUTO_ON = value end})
                    -- Combo / Harass
                    Menu.wset:MenuElement({name = "Combo / Harass", id = "comhar", type = _G.MENU })
                        Menu.wset.comhar:MenuElement({id = "combo", name = "Use W Combo", value = false, callback = function(value) W_COMBO_ON = value end})
                        Menu.wset.comhar:MenuElement({id = "harass", name = "Use W Harass", value = false, callback = function(value) W_HARASS_ON = value end})
                    -- Clear
                    Menu.wset:MenuElement({name = "Clear", id = "laneclear", type = _G.MENU })
                        Menu.wset.laneclear:MenuElement({id = "enabled", name = "Enbaled", value = false, callback = function(value) W_CLEAR_ON = value end})
                        Menu.wset.laneclear:MenuElement({id = "xminions", name = "Min minions W Clear", value = 3, min = 1, max = 5, step = 1, callback = function(value) W_CLEAR_MINX = value end})
                -- E
                Menu:MenuElement({name = "E settings", id = "eset", type = _G.MENU })
                    -- Auto
                    Menu.eset:MenuElement({name = "Auto", id = "auto", type = _G.MENU })
                        Menu.eset.auto:MenuElement({id = "enabled", name = "Enabled", value = true, callback = function(value) E_AUTO_ON = value end})
                        Menu.eset.auto:MenuElement({id = "ally", name = "Use on ally", value = true, callback = function(value) E_ALLY_ON = value end})
                        Menu.eset.auto:MenuElement({id = "selfish", name = "Use on yourself", value = true, callback = function(value) E_SELF_ON = value end})
                --R
                Menu:MenuElement({name = "R settings", id = "rset", type = _G.MENU })
                    -- KS
                    Menu.rset:MenuElement({name = "KS", id = "killsteal", type = _G.MENU })
                        Menu.rset.killsteal:MenuElement({id = "enabled", name = "Enabled", value = false, callback = function(value) R_KS_ON = value end})
                        Menu.rset.killsteal:MenuElement({id = "minhp", name = "Minimum enemy hp", value = 200, min = 1, max = 300, step = 1, callback = function(value) R_KS_MINHP = value end})
                    -- Auto
                    Menu.rset:MenuElement({name = "Auto", id = "auto", type = _G.MENU })
                        Menu.rset.auto:MenuElement({id = "enabled", name = "Enabled", value = true, callback = function(value) R_AUTO_ON = value end})
                        Menu.rset.auto:MenuElement({id = "xenemies", name = ">= X enemies near morgana", value = 3, min = 1, max = 5, step = 1, callback = function(value) R_AUTO_ENEMIESX = value end})
                        Menu.rset.auto:MenuElement({id = "xrange", name = "< X distance enemies to morgana", value = 300, min = 100, max = 550, step = 50, callback = function(value) R_AUTO_RANGEX = value end})
                    -- Combo / Harass
                    Menu.rset:MenuElement({name = "Combo / Harass", id = "comhar", type = _G.MENU })
                        Menu.rset.comhar:MenuElement({id = "combo", name = "Use R Combo", value = true, callback = function(value) R_COMBO_ON = value end})
                        Menu.rset.comhar:MenuElement({id = "harass", name = "Use R Harass", value = false, callback = function(value) R_HARASS_ON = value end})
                        Menu.rset.comhar:MenuElement({id = "xenemies", name = ">= X enemies near morgana", value = 2, min = 1, max = 4, step = 1, callback = function(value) R_COMBO_ENEMIESX = value end})
                        Menu.rset.comhar:MenuElement({id = "xrange", name = "< X distance enemies to morgana", value = 300, min = 100, max = 550, step = 50, callback = function(value) R_COMBO_RANGEX = value end})
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        Callback.Add("Load", function()
            Orbwalker, TargetSelector, ObjectManager, Damage, Spells = _G.SDK.Orbwalker, _G.SDK.TargetSelector, _G.SDK.ObjectManager, _G.SDK.Damage, _G.SDK.Spells
            --------------------------------------------------------------------------------------------------------------------------------------------
            LoadMenu()
            --------------------------------------------------------------------------------------------------------------------------------------------
            Orbwalker.CanAttackC = function()
                if not Spells:CheckSpellDelays({ q = 0.33, w = 0.33, e = 0.33, r = 0.33 }) then
                    return false
                end
                -- LastHit, LaneClear
                if not Orbwalker.Modes[ORBWALKER_MODE_COMBO] and not Orbwalker.Modes[ORBWALKER_MODE_HARASS] then
                    return true
                end
                -- Q
                if Q_DISABLEAA and myHero:GetSpellData(_Q).level > 0 and myHero.mana > myHero:GetSpellData(_Q).mana and (GameCanUseSpell(_Q) == 0 or myHero:GetSpellData(_Q).currentCd < 1) then
                    return false
                end
                return true
            end
            --------------------------------------------------------------------------------------------------------------------------------------------
            Orbwalker.CanMoveC = function()
                if not Spells:CheckSpellDelays({ q = 0.25, w = 0.25, e = 0.25, r = 0.25 }) then
                    return false
                end
                return true
            end
        end)
        ------------------------------------------------------------------------------------------------------------------------------------------------
        Interrupter:OnInterrupt(function(enemy, activeSpell)
            if Q_INTERRUPTER_ON and Spells:IsReady(_Q, { q = 0.3, w = 0.3, e = 0.3, r = 0.3 } ) then
                Prediction:CastSpell(HK_Q, enemy, myHero, QData, 4)
            end
        end)
        ------------------------------------------------------------------------------------------------------------------------------------------------
        local function QLogic()
            if Spells:IsReady(_Q, { q = 0.3, w = 0.3, e = 0.3, r = 0.3 } ) then
                local EnemyHeroes = ObjectManager:GetEnemyHeroes(QData.Range, false, HEROES_SPELL)
                ----------------------------------------------------------------------------------------------------------------------------------------
                if Q_KS_ON then
                    local baseDmg = 25
                    local lvlDmg = 55 * myHero:GetSpellData(_Q).level
                    local apDmg = myHero.ap * 0.9
                    local qDmg = baseDmg + lvlDmg + apDmg
                    if qDmg > Q_KS_MINHP then
                        for i = 1, #EnemyHeroes do
                            local qTarget = EnemyHeroes[i]
                            if qTarget.health > Q_KS_MINHP and qTarget.health < Damage:CalculateDamage(myHero, qTarget, DAMAGE_TYPE_MAGICAL, qDmg) and Prediction:CastSpell(HK_Q, qTarget, myHero, QData, Q_KS_HITCHANCE) then
                                return
                            end
                        end
                    end
                end
                ----------------------------------------------------------------------------------------------------------------------------------------
                if (Orbwalker.Modes[ORBWALKER_MODE_COMBO] and Q_COMBO_ON) or (Orbwalker.Modes[ORBWALKER_MODE_HARASS] and Q_HARASS_ON) then
                    local qList = {}
                    for i = 1, #EnemyHeroes do
                        local hero = EnemyHeroes[i]
                        local heroName = hero.charName
                        if Menu.qset.comhar.useon[heroName] and Menu.qset.comhar.useon[heroName]:Value() then
                            qList[#qList+1] = hero
                        end
                    end
                    local qTarget = TargetSelector:GetTarget(qList, DAMAGE_TYPE_MAGICAL)
                    if qTarget and Prediction:CastSpell(HK_Q, qTarget, myHero, QData, Q_COMBO_HITCHANCE) then
                        return
                    end
                ----------------------------------------------------------------------------------------------------------------------------------------
                elseif Q_AUTO_ON then
                    local qList = {}
                    for i = 1, #EnemyHeroes do
                        local hero = EnemyHeroes[i]
                        local heroName = hero.charName
                        if Menu.qset.auto.useon[heroName] and Menu.qset.auto.useon[heroName]:Value() then
                            qList[#qList+1] = hero
                        end
                    end
                    local qTarget = TargetSelector:GetTarget(qList, DAMAGE_TYPE_MAGICAL)
                    if qTarget and Prediction:CastSpell(HK_Q, qTarget, myHero, QData, Q_AUTO_HITCHANCE) then
                        return
                    end
                end
            end
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        local function WLogic()
            if Spells:IsReady(_W, { q = 0.3, w = 0.3, e = 0.3, r = 0.3 } ) then
                local EnemyHeroes = ObjectManager:GetEnemyHeroes(WData.Range, false, 0)
                ----------------------------------------------------------------------------------------------------------------------------------------
                if W_KS_ON then
                    local baseDmg = 10
                    local lvlDmg = 14 * myHero:GetSpellData(_W).level
                    local apDmg = myHero.ap * 0.22
                    local wDmg = baseDmg + lvlDmg + apDmg
                    if wDmg > W_KS_MINHP then
                        for i = 1, #EnemyHeroes do
                            local wTarget = EnemyHeroes[i]
                            if wTarget.health > W_KS_MINHP and wTarget.health < Damage:CalculateDamage(myHero, wTarget, DAMAGE_TYPE_MAGICAL, wDmg) and Prediction:CastSpell(HK_W, wTarget, myHero, WData, 3) then
                                return
                            end
                        end
                    end
                end
                ----------------------------------------------------------------------------------------------------------------------------------------
                if (Orbwalker.Modes[ORBWALKER_MODE_COMBO] and W_COMBO_ON) or (Orbwalker.Modes[ORBWALKER_MODE_HARASS] and W_HARASS_ON) then
                    for i = 1, #EnemyHeroes do
                        local unit = EnemyHeroes[i]
                        if Prediction:CastSpell(HK_W, unit, myHero, WData, 3) then
                            return
                        end
                    end
                end
                ----------------------------------------------------------------------------------------------------------------------------------------
                if (Orbwalker.Modes[ORBWALKER_MODE_LANECLEAR] and W_CLEAR_ON) then
                    local target = nil
                    local BestHit = 0
                    local CurrentCount = 0
                    local eMinions = ObjectManager:GetEnemyMinions(WData.Range + 200)
                    for i, minion in pairs(eMinions) do
                        CurrentCount = 0
                        local minionPos = Core:To2D(minion.pos)
                        for j, minion2 in pairs(eMinions) do
                            if Core:IsInRange(minionPos, Core:To2D(minion2.pos), 250) then
                                CurrentCount = CurrentCount + 1
                            end
                        end
                        if CurrentCount > BestHit then
                            BestHit = CurrentCount
                            target = minion
                        end
                    end
                    if target and BestHit >= W_CLEAR_MINX and Control.CastSpell(HK_W, target) then
                        return
                    end
                end
                ----------------------------------------------------------------------------------------------------------------------------------------
                if W_AUTO_ON then
                    for i = 1, #EnemyHeroes do
                        local unit = EnemyHeroes[i]
                        local data = Core:GetHeroData(unit, true)
                        local remainingTime = MathMax(data.RemainingImmobile, data.ExpireImmobile - GameTimer())
                        if remainingTime > 0.5 and not unit.pathing.isDashing and Prediction:CastSpell(HK_W, unit, myHero, WData, 4) then
                            return
                        end
                    end
                end
            end
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        local function ELogic()
            if E_AUTO_ON and (E_ALLY_ON or E_SELF_ON) and Spells:IsReady(_E, { q = 0.3, w = 0.3, e = 0.3, r = 0.3 } ) then
                local EnemyHeroes = ObjectManager:GetEnemyHeroes(2500, false, HEROES_IMMORTAL)
                for i, hero in pairs(EnemyHeroes) do
                    local heroPos = Core:To2D(hero.pos)
                    local currSpell = hero.activeSpell
                    if currSpell and currSpell.valid and hero.isChanneling then
                        local AllyHeroes = ObjectManager:GetAllyHeroes(EData.Range)
                        for j, ally in pairs(AllyHeroes) do
                            local isMe = ally.isMe
                            if (E_SELF_ON and isMe) or (not canUse and E_ALLY_ON and not isMe) then
                                local allyPos = Core:To2D(ally.pos)
                                local canUse = false
                                if currSpell.target == ally.handle then
                                    canUse = true
                                else
                                    local spellPos = Core:To2D(currSpell.placementPos)
                                    local endPos = spellPos--(currSpell.range > 0) and Core:Extended(heroPos, Core:Normalized(spellPos, heroPos), currSpell.range) or spellPos
                                    local width = ally.boundingRadius + 100
                                    if currSpell.width > 0 then width = width + currSpell.width end
                                    local isOnSegment, pointSegment, pointLine = Core:ProjectOn(allyPos, endPos, heroPos)
                                    if Core:IsInRange(pointSegment, allyPos, width) then
                                        canUse = true
                                    end
                                end
                                if canUse and Control.CastSpell(HK_E, ally) then
                                    return
                                end
                            end
                        end
                    end
                end
            end
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        local function RLogic()
            if Spells:IsReady(_R, { q = 0.33, w = 0.33, e = 0.33, r = 0.5 } ) then
                local EnemyHeroes = ObjectManager:GetEnemyHeroes(RData.Range, false, 0)
                if R_KS_ON then
                    local baseDmg = 75
                    local lvlDmg = 75 * myHero:GetSpellData(_R).level
                    local apDmg = myHero.ap * 0.7
                    local rDmg = baseDmg + lvlDmg + apDmg
                    if rDmg > R_KS_MINHP then
                        for i = 1, #EnemyHeroes do
                            local rTarget = EnemyHeroes[i]
                            if rTarget.health > R_KS_MINHP and rTarget.health < Damage:CalculateDamage(myHero, rTarget, DAMAGE_TYPE_MAGICAL, rDmg) and Prediction:CastSpell(HK_R) then
                                return
                            end
                        end
                    end
                end
                if (Orbwalker.Modes[ORBWALKER_MODE_COMBO] and R_COMBO_ON) or (Orbwalker.Modes[ORBWALKER_MODE_HARASS] and R_HARASS_ON) then
                    local count = 0
                    local mePos = Core:To2D(myHero.pos)
                    for i = 1, #EnemyHeroes do
                        local unit = EnemyHeroes[i]
                        if Core:IsInRange(mePos, Core:To2D(unit.pos), R_COMBO_RANGEX) then
                            count = count + 1
                        end
                    end
                    if count >= R_COMBO_ENEMIESX and Prediction:CastSpell(HK_R) then
                        return
                    end
                end
                if R_AUTO_ON then
                    local count = 0
                    for i = 1, #EnemyHeroes do
                        local unit = EnemyHeroes[i]
                        if unit.pos:DistanceTo(myHero.pos) < R_AUTO_RANGEX then
                            count = count + 1
                        end
                    end
                    if count >= R_AUTO_ENEMIESX and Prediction:CastSpell(HK_R) then
                        return
                    end
                end
            end
        end
        ------------------------------------------------------------------------------------------------------------------------------------------------
        Callback.Add("Draw", function()
            if Orbwalker:IsAutoAttacking() then return end
            QLogic()
            WLogic()
            ELogic()
            RLogic()
        end)
    end
    ----------------------------------------------------------------------------------------------------------------------------------------------------
    _G.GamsteronMorganaLoaded = true
--------------------------------------------------------------------------------------------------------------------------------------------------------