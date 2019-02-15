local GamsteronAIOVer = 0.0793
local LocalCore, MENU, CHAMPION, INTERRUPTER, ORB, TS, OB, DMG, SPELLS
do
    if _G.GamsteronAIOLoaded == true then return end
    _G.GamsteronAIOLoaded = true

    local SUPPORTED_CHAMPIONS =
    {
        ["Twitch"] = true,
        ["Morgana"] = true,
        ["Karthus"] = true,
        ["KogMaw"] = true,
        ["Vayne"] = true,
        ["Brand"] = true,
        ["Ezreal"] = true,
        ["Varus"] = true
    }
    if not SUPPORTED_CHAMPIONS[myHero.charName] then
        print("GamsteronAIO - " .. myHero.charName .. " is not supported !")
        return
    end

	if not FileExist(COMMON_PATH .. "GamsteronCore.lua") then
		DownloadFileAsync("https://raw.githubusercontent.com/gamsteron/GOS-External/master/Common/GamsteronCore.lua", COMMON_PATH .. "GamsteronCore.lua", function() end)
		while not FileExist(COMMON_PATH .. "GamsteronCore.lua") do end
    end
    
    if not FileExist(COMMON_PATH .. "GamsteronPrediction.lua") then
        DownloadFileAsync("https://raw.githubusercontent.com/gamsteron/GOS-External/master/Common/GamsteronPrediction.lua", COMMON_PATH .. "GamsteronPrediction.lua", function() end)
        while not FileExist(COMMON_PATH .. "GamsteronPrediction.lua") do end
    end

    require('GamsteronPrediction')
    if _G.GamsteronPredictionUpdated then
        return
    end

	require('GamsteronCore')
	if _G.GamsteronCoreUpdated then return end
	LocalCore = _G.GamsteronCore

	local success, version = LocalCore:AutoUpdate({
		version = GamsteronAIOVer,
		scriptPath = SCRIPT_PATH .. "GamsteronAIO.lua",
		scriptUrl = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/GamsteronAIO.lua",
		versionPath = SCRIPT_PATH .. "GamsteronAIO.version",
		versionUrl = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/GamsteronAIO.version"
	})
	if success then
		print("GamsteronAIO updated to version " .. version .. ". Please Reload with 2x F6 !")
		_G.GamsteronAIOUpdated = true
		return
	end
end

local function IsGamsteronCollision(unit, radius, speed, delay)
    if unit:GetCollision(radius, speed, delay) > 0 then
        return true
    end
    return false
end

--locals
    local GetTickCount					= GetTickCount
    local myHero						= myHero
    local LocalCharName					= myHero.charName
    local LocalVector					= Vector
    local LocalOsClock					= os.clock
    local LocalCallbackAdd				= Callback.Add
    local LocalCallbackDel				= Callback.Del
    local LocalDrawLine					= Draw.Line
    local LocalDrawColor				= Draw.Color
    local LocalDrawCircle				= Draw.Circle
    local LocalDrawText					= Draw.Text
    local LocalControlIsKeyDown			= Control.IsKeyDown
    local LocalControlMouseEvent		= Control.mouse_event
    local LocalControlSetCursorPos		= Control.SetCursorPos
    local LocalControlKeyUp				= Control.KeyUp
    local LocalControlKeyDown			= Control.KeyDown
    local LocalGameCanUseSpell			= Game.CanUseSpell
    local LocalGameLatency				= Game.Latency
    local LocalGameTimer				= Game.Timer
    local LocalGameParticleCount		= Game.ParticleCount
    local LocalGameParticle				= Game.Particle
    local LocalGameHeroCount 			= Game.HeroCount
    local LocalGameHero 				= Game.Hero
    local LocalGameMinionCount 			= Game.MinionCount
    local LocalGameMinion 				= Game.Minion
    local LocalGameTurretCount 			= Game.TurretCount
    local LocalGameTurret 				= Game.Turret
    local LocalGameWardCount 			= Game.WardCount
    local LocalGameWard 				= Game.Ward
    local LocalGameObjectCount 			= Game.ObjectCount
    local LocalGameObject				= Game.Object
    local LocalGameMissileCount 		= Game.MissileCount
    local LocalGameMissile				= Game.Missile
    local LocalGameIsChatOpen			= Game.IsChatOpen
    local LocalGameIsOnTop				= Game.IsOnTop
    local STATE_UNKNOWN					= STATE_UNKNOWN
    local STATE_ATTACK					= STATE_ATTACK
    local STATE_WINDUP					= STATE_WINDUP
    local STATE_WINDDOWN				= STATE_WINDDOWN
    local ITEM_1						= ITEM_1
    local ITEM_2						= ITEM_2
    local ITEM_3						= ITEM_3
    local ITEM_4						= ITEM_4
    local ITEM_5						= ITEM_5
    local ITEM_6						= ITEM_6
    local ITEM_7						= ITEM_7
    local _Q							= _Q
    local _W							= _W
    local _E							= _E
    local _R							= _R
    local MOUSEEVENTF_RIGHTDOWN			= MOUSEEVENTF_RIGHTDOWN
    local MOUSEEVENTF_RIGHTUP			= MOUSEEVENTF_RIGHTUP
    local Obj_AI_Barracks				= Obj_AI_Barracks
    local Obj_AI_Hero					= Obj_AI_Hero
    local Obj_AI_Minion					= Obj_AI_Minion
    local Obj_AI_Turret					= Obj_AI_Turret
    local Obj_HQ 						= "obj_HQ"
    local pairs							= pairs
    local LocalMathCeil					= math.ceil
    local LocalMathMax					= math.max
    local LocalMathMin					= math.min
    local LocalMathSqrt					= math.sqrt
    local LocalMathRandom				= math.random
    local LocalMathHuge					= math.huge
    local LocalMathAbs					= math.abs
    local LocalStringSub				= string.sub
    local LocalStringLen				= string.len
    local EPSILON						= 1E-12
    local TEAM_ALLY						= myHero.team
    local TEAM_ENEMY					= 300 - TEAM_ALLY
    local TEAM_JUNGLE					= 300
    local ORBWALKER_MODE_NONE           = -1
    local ORBWALKER_MODE_COMBO          = 0
    local ORBWALKER_MODE_HARASS         = 1
    local ORBWALKER_MODE_LANECLEAR      = 2
    local ORBWALKER_MODE_JUNGLECLEAR    = 3
    local ORBWALKER_MODE_LASTHIT        = 4
    local ORBWALKER_MODE_FLEE           = 5
    local DAMAGE_TYPE_PHYSICAL			= 0
    local DAMAGE_TYPE_MAGICAL			= 1
    local DAMAGE_TYPE_TRUE				= 2
    local function CheckWall(from, to, distance)
        local pos1 = to + (to-from):Normalized() * 50
        local pos2 = pos1 + (to-from):Normalized() * (distance - 50)
        local point1 = Point(pos1.x, pos1.z)
        local point2 = Point(pos2.x, pos2.z)
        if MapPosition:intersectsWall(LineSegment(point1, point2)) or (MapPosition:inWall(point1) and MapPosition:inWall(point2)) then
            return true
        end
        return false
    end
    local function CastSpell(spell, unit, spelldata, hitchance)
        if LocalCore:IsValidTarget(unit) then
            local HitChance = hitchance or 3
            local Pred = GetGamsteronPrediction(unit, spelldata, myHero.pos)
            if Pred.Hitchance >= HitChance then
                return LocalCore:CastSpell(spell, nil, Pred.CastPosition)
            end
        end
        return false
    end
local AIO = {
    Twitch = function()
        local TwitchVersion = 0.01
        MENU = MenuElement({name = "Gamsteron Twitch", id = "Gamsteron_Twitch", type = _G.MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Icons/twitch.png" })
        -- Q
        MENU:MenuElement({name = "Q settings", id = "qset", type = _G.MENU })
            MENU.qset:MenuElement({id = "combo", name = "Use Q Combo", value = false})
            MENU.qset:MenuElement({id = "harass", name = "Use Q Harass", value = false})
            MENU.qset:MenuElement({id = "recallkey", name = "Invisible Recall Key", key = string.byte("T"), value = false, toggle = true})
            MENU.qset.recallkey:Value(false)
            MENU.qset:MenuElement({id = "note1", name = "Note: Key should be diffrent than recall key", type = SPACE})
        -- W
        MENU:MenuElement({name = "W settings", id = "wset", type = _G.MENU })
            MENU.wset:MenuElement({id = "stopq", name = "Stop if Q invisible", value = true})
            MENU.wset:MenuElement({id = "stopwult", name = "Stop if R", value = false})
            MENU.wset:MenuElement({id = "combo", name = "Use W Combo", value = true})
            MENU.wset:MenuElement({id = "harass", name = "Use W Harass", value = false})
            MENU.wset:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = { "normal", "high" } })
        -- E
        MENU:MenuElement({name = "E settings", id = "eset", type = _G.MENU })
            MENU.eset:MenuElement({id = "combo", name = "Use E Combo", value = true})
            MENU.eset:MenuElement({id = "harass", name = "Use E Harass", value = false})
            MENU.eset:MenuElement({id = "killsteal", name = "Use E KS", value = true})
            MENU.eset:MenuElement({id = "stacks", name = "X stacks", value = 6, min = 1, max = 6, step = 1 })
            MENU.eset:MenuElement({id = "enemies", name = "X enemies", value = 1, min = 1, max = 5, step = 1 })
        -- R
        MENU:MenuElement({name = "R settings", id = "rset", type = _G.MENU })
            MENU.rset:MenuElement({id = "combo", name = "Use R Combo", value = true})
            MENU.rset:MenuElement({id = "harass", name = "Use R Harass", value = false})
            MENU.rset:MenuElement({id = "xenemies", name = "x - enemies", value = 3, min = 1, max = 5, step = 1 })
            MENU.rset:MenuElement({id = "xrange", name = "x - distance", value = 750, min = 300, max = 1500, step = 50 })
        -- Drawings
        MENU:MenuElement({name = "Drawings", id = "draws", type = _G.MENU })
            MENU.draws:MenuElement({id = "enabled", name = "Enabled", value = true})
            MENU.draws:MenuElement({name = "Q Timer",  id = "qtimer", type = _G.MENU})
                MENU.draws.qtimer:MenuElement({id = "enabled", name = "Enabled", value = true})
                MENU.draws.qtimer:MenuElement({id = "color", name = "Color ", color = Draw.Color(200, 65, 255, 100)})
            MENU.draws:MenuElement({name = "Q Invisible Range",  id = "qinvisible", type = _G.MENU})
                MENU.draws.qinvisible:MenuElement({id = "enabled", name = "Enabled", value = true})
                MENU.draws.qinvisible:MenuElement({id = "color", name = "Color ", color = Draw.Color(200, 255, 0, 0)})
            MENU.draws:MenuElement({name = "Q Notification Range",  id = "qnotification", type = _G.MENU})
                MENU.draws.qnotification:MenuElement({id = "enabled", name = "Enabled", value = true})
                MENU.draws.qnotification:MenuElement({id = "color", name = "Color ", color = Draw.Color(200, 188, 77, 26)})
        -- Version
        MENU:MenuElement({name = "Version " .. tostring(TwitchVersion), type = _G.SPACE, id = "verspace"})
        CHAMPION = LocalCore:Class()
        function CHAMPION:__init()
            self.WData = { delay = 0.25, radius = 50, range = 950, speed = 1400, type = _G.SPELLTYPE_CIRCLE }
            self.HasQBuff = false
            self.QBuffDuration = 0
            self.HasQASBuff = false
            self.QASBuffDuration = 0
            self.Recall = true
            self.EBuffs = {}
        end
        function CHAMPION:Tick()
            --[[q buff best orbwalker dps
            if gsoGetTickCount() - gsoSpellTimers.lqk < 500 and gsoGetTickCount() > champInfo.lastASCheck + 1000 then
            champInfo.asNoQ = gsoMyHero.attackSpeed
            champInfo.windUpNoQ = gsoTimers.windUpTime
            champInfo.lastASCheck = gsoGetTickCount()
            end--]]
            --[[disable attack
            local num = 1150 - (gsoGetTickCount() - (gsoSpellTimers.lqk + (gsoExtra.maxLatency*1000)))
            if num < (gsoTimers.windUpTime*1000)+50 and num > - 50 then
            return false
            end--]]
            --qrecall
            if MENU.qset.recallkey:Value() == self.Recall then
                LocalControlKeyDown(HK_Q)
                LocalControlKeyUp(HK_Q)
                LocalControlKeyDown(string.byte("B"))
                LocalControlKeyUp(string.byte("B"))
                self.Recall = not self.Recall
            end
            --qbuff
            local qDuration = LocalCore:GetBuffDuration(myHero, "globalcamouflage")--twitchhideinshadows
            self.HasQBuff = qDuration > 0
            if qDuration > 0 then
                self.QBuffDuration = Game.Timer() + qDuration
            else
                self.QBuffDuration = 0
            end
            --qasbuff
            local qasDuration = LocalCore:GetBuffDuration(myHero, "twitchhideinshadowsbuff")
            self.HasQASBuff = qasDuration > 0
            if qasDuration > 0 then
                self.QASBuffDuration = Game.Timer() + qasDuration
            else
                self.QASBuffDuration = 0
            end
            --handle e buffs
            local enemyList = OB:GetEnemyHeroes(1200, false, 0)
            for i = 1, #enemyList do
                local hero  = enemyList[i]
                local nID   = hero.networkID
                if self.EBuffs[nID] == nil then
                    self.EBuffs[nID] = { count = 0, durT = 0 }
                end
                if not hero.dead then
                    local hasB = false
                    local cB = self.EBuffs[nID].count
                    local dB = self.EBuffs[nID].durT
                    for i = 0, hero.buffCount do
                        local buff = hero:GetBuff(i)
                        if buff and buff.count > 0 and buff.name:lower() == "twitchdeadlyvenom" then
                            hasB = true
                            if cB < 6 and buff.duration > dB then
                                self.EBuffs[nID].count = cB + 1
                                self.EBuffs[nID].durT = buff.duration
                            else
                                self.EBuffs[nID].durT = buff.duration
                            end
                            break
                        end
                    end
                    if not hasB then
                        self.EBuffs[nID].count = 0
                        self.EBuffs[nID].durT = 0
                    end
                end
            end
            -- Combo / Harass
            if ORB:IsAutoAttacking() then
                return
            end
            --EKS
            if MENU.eset.killsteal:Value() and SPELLS:IsReady(_E, { q = 0, w = 0.25, e = 0.5, r = 0 } ) then
                for i = 1, #enemyList do
                    local hero = enemyList[i]
                    local buffCount
                    if self.EBuffs[hero.networkID] then
                        buffCount = self.EBuffs[hero.networkID].count
                    else
                        buffCount = 0
                    end
                    if buffCount > 0 and myHero.pos:DistanceTo(hero.pos) < 1200 - 35 then
                        local elvl = myHero:GetSpellData(_E).level
                        local basedmg = 10 + ( elvl * 10 )
                        local perstack = ( 10 + (5*elvl) ) * buffCount
                        local bonusAD = myHero.bonusDamage * 0.25 * buffCount
                        local bonusAP = myHero.ap * 0.2 * buffCount
                        local edmg = basedmg + perstack + bonusAD + bonusAP
                        if DMG:CalculateDamage(myHero, hero, DAMAGE_TYPE_PHYSICAL, edmg) >= hero.health + (1.5*hero.hpRegen) and Control.CastSpell(HK_E) then
                            break
                        end
                    end
                end
            end
            local isCombo = ORB.Modes[ORBWALKER_MODE_COMBO]
            local isHarass = ORB.Modes[ORBWALKER_MODE_HARASS]
            if isCombo or isHarass then
                -- R
                if ((isCombo and MENU.rset.combo:Value()) or (isHarass and MENU.rset.harass:Value())) and SPELLS:IsReady(_R, { q = 1, w = 0.33, e = 0.33, r = 0.5 } ) and #OB:GetEnemyHeroes(MENU.rset.xrange:Value(), false, 1) >= MENU.rset.xenemies:Value() and Control.CastSpell(HK_R) then
                    return
                end
                -- [ get combo target ]
                local target = TS:GetComboTarget()
                if target and ORB:CanAttack() then
                    return
                end
                -- Q
                if ((isCombo and MENU.qset.combo:Value()) or (isHarass and MENU.qset.harass:Value())) and target and SPELLS:IsReady(_Q, { q = 0.5, w = 0.33, e = 0.33, r = 0.1 } ) and Control.CastSpell(HK_Q) then
                    return
                end
                --W
                if ((isCombo and MENU.wset.combo:Value())or(isHarass and MENU.wset.harass:Value())) and not(MENU.wset.stopwult:Value() and Game.Timer() < lastRk + 5.45) and not(MENU.wset.stopq:Value() and self.HasQBuff) and SPELLS:IsReady(_W, { q = 0, w = 1, e = 0.75, r = 0 } ) then
                    if target then
                        WTarget = target
                    else
                        WTarget = TS:GetTarget(OB:GetEnemyHeroes(950, false, 0), 0)
                    end
                    CastSpell(HK_W, WTarget, self.WData, MENU.wset.hitchance:Value() + 1)
                end
                --E
                if ((ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.eset.combo:Value())or(ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.eset.harass:Value())) and SPELLS:IsReady(_E, { q = 0, w = 0.25, e = 0.5, r = 0 } ) then
                    local countE = 0
                    local xStacks = MENU.eset.stacks:Value()
                    local enemyList = OB:GetEnemyHeroes(1200, false, 0)
                    for i = 1, #enemyList do
                        local hero = enemyList[i]
                        local buffCount
                        if self.EBuffs[hero.networkID] then
                            buffCount = self.EBuffs[hero.networkID].count
                        else
                            buffCount = 0
                        end
                        if hero and myHero.pos:DistanceTo(hero.pos) < 1200 - 35 and buffCount >= xStacks then
                            countE = countE + 1
                        end
                    end
                    if countE >= MENU.eset.enemies:Value() and Control.CastSpell(HK_E) then
                        return
                    end
                end
            end
        end
        function CHAMPION:Draw()
            local lastQ, lastQk, lastW, lastWk, lastE, lastEk, lastR, lastRk = SPELLS:GetLastSpellTimers()
            if Game.Timer() < lastQk + 16 then
                local pos2D = myHero.pos:To2D()
                local posX = pos2D.x - 50
                local posY = pos2D.y
                local num1 = 1.35-(Game.Timer()-lastQk)
                local timerEnabled = MENU.draws.qtimer.enabled:Value()
                local timerColor = MENU.draws.qtimer.color:Value()
                if num1 > 0.001 then
                    if timerEnabled then
                        local str1 = tostring(math.floor(num1*1000))
                        local str2 = ""
                        for i = 1, #str1 do
                            if #str1 <=2 then
                                str2 = 0
                                break
                            end
                            local char1
                            if i <= #str1-2 then
                                char1 = str1:sub(i,i)
                            else
                                char1 = "0"
                            end
                            str2 = str2..char1
                        end
                        Draw.Text(str2, 50, posX+50, posY-15, timerColor)
                    end
                elseif self.HasQBuff then
                    local num2 = math.floor(1000*(self.QBuffDuration-Game.Timer()))
                    if num2 > 1 then
                        if MENU.draws.qinvisible.enabled:Value() then
                            Draw.Circle(myHero.pos, 500, 1, MENU.draws.qinvisible.color:Value())
                        end
                        if MENU.draws.qnotification.enabled:Value() then
                            Draw.Circle(myHero.pos, 800, 1, MENU.draws.qnotification.color:Value())
                        end
                        if timerEnabled then
                            local str1 = tostring(num2)
                            local str2 = ""
                            for i = 1, #str1 do
                                if #str1 <=2 then
                                    str2 = 0
                                    break
                                end
                                local char1
                                if i <= #str1-2 then
                                    char1 = str1:sub(i,i)
                                else
                                    char1 = "0"
                                end
                                str2 = str2..char1
                            end
                            Draw.Text(str2, 50, posX+50, posY-15, timerColor)
                        end
                    end
                end
            end
        end
        function CHAMPION:PreAttack(args)
            local isCombo = ORB.Modes[ORBWALKER_MODE_COMBO]
            local isHarass = ORB.Modes[ORBWALKER_MODE_HARASS]
            if isCombo or isHarass then
                -- R
                if (isCombo and MENU.rset.combo:Value()) or (isHarass and MENU.rset.harass:Value()) then
                    if SPELLS:IsReady(_R, { q = 1, w = 0.33, e = 0.33, r = 0.5 } ) and #OB:GetEnemyHeroes(MENU.rset.xrange:Value(), false, 1) >= MENU.rset.xenemies:Value() and Control.CastSpell(HK_R) then
                        return
                    end
                end
            end
        end
        function CHAMPION:CanMove()
            if not SPELLS:CheckSpellDelays({ q = 0, w = 0.2, e = 0.2, r = 0 }) then
                return false
            end
            return true
        end
        function CHAMPION:CanAttack()
            if not SPELLS:CheckSpellDelays({ q = 0, w = 0.33, e = 0.33, r = 0 }) then
                return false
            end
            return true
        end
    end,
    Morgana = function()
        local MorganaVersion = "0.02 - fixed error"
        MENU = MenuElement({name = "Gamsteron Morgana", id = "Gamsteron_Morgana", type = _G.MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Icons/morganads83fd.png" })
        -- Q
        MENU:MenuElement({name = "Q settings", id = "qset", type = _G.MENU })
            -- Disable Attack
            MENU.qset:MenuElement({id = "disaa", name = "Disable attack if ready or almostReady", value = false})
            -- Interrupt:
            MENU.qset:MenuElement({id = "interrupter", name = "Interrupter", value = true})
            -- KS
            MENU.qset:MenuElement({name = "KS", id = "killsteal", type = _G.MENU })
                MENU.qset.killsteal:MenuElement({id = "enabled", name = "Enabled", value = false })
                MENU.qset.killsteal:MenuElement({id = "minhp", name = "minimum enemy hp", value = 200, min = 1, max = 300, step = 1})
                MENU.qset.killsteal:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = { "Normal", "High", "Immobile" } })
            -- Auto
            MENU.qset:MenuElement({name = "Auto", id = "auto", type = _G.MENU })
                MENU.qset.auto:MenuElement({id = "enabled", name = "Enabled", value = true})
                MENU.qset.auto:MenuElement({name = "Use on:", id = "useon", type = _G.MENU })
                    LocalCore:OnEnemyHeroLoad(function(hero) MENU.qset.auto.useon:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
                MENU.qset.auto:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = { "Normal", "High", "Immobile" } })
            -- Combo / Harass
            MENU.qset:MenuElement({name = "Combo / Harass", id = "comhar", type = _G.MENU })
                MENU.qset.comhar:MenuElement({id = "combo", name = "Combo", value = true})
                MENU.qset.comhar:MenuElement({id = "harass", name = "Harass", value = false})
                MENU.qset.comhar:MenuElement({name = "Use on:", id = "useon", type = _G.MENU })
                    LocalCore:OnEnemyHeroLoad(function(hero) MENU.qset.comhar.useon:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
                MENU.qset.comhar:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = { "Normal", "High", "Immobile" } })
        -- W
        MENU:MenuElement({name = "W settings", id = "wset", type = _G.MENU })
            -- KS
            MENU.wset:MenuElement({name = "KS", id = "killsteal", type = _G.MENU })
                MENU.wset.killsteal:MenuElement({id = "enabled", name = "Enabled", value = false})
                MENU.wset.killsteal:MenuElement({id = "minhp", name = "minimum enemy hp", value = 200, min = 1, max = 300, step = 1})
            -- Auto
            MENU.wset:MenuElement({name = "Auto", id = "auto", type = _G.MENU })
                MENU.wset.auto:MenuElement({id = "enabled", name = "Enabled", value = true})
            -- Combo / Harass
            MENU.wset:MenuElement({name = "Combo / Harass", id = "comhar", type = _G.MENU })
                MENU.wset.comhar:MenuElement({id = "combo", name = "Use W Combo", value = false})
                MENU.wset.comhar:MenuElement({id = "harass", name = "Use W Harass", value = false})
            -- Clear
            MENU.wset:MenuElement({name = "Clear", id = "laneclear", type = _G.MENU })
                MENU.wset.laneclear:MenuElement({id = "enabled", name = "Enbaled", value = false})
                MENU.wset.laneclear:MenuElement({id = "xminions", name = "Min minions W Clear", value = 3, min = 1, max = 5, step = 1})
        -- E
        MENU:MenuElement({name = "E settings", id = "eset", type = _G.MENU })
            -- Auto
            MENU.eset:MenuElement({name = "Auto", id = "auto", type = _G.MENU })
                MENU.eset.auto:MenuElement({id = "enabled", name = "Enabled", value = true})
                MENU.eset.auto:MenuElement({id = "ally", name = "Use on ally", value = true})
                MENU.eset.auto:MenuElement({id = "selfish", name = "Use on yourself", value = true})
        --R
        MENU:MenuElement({name = "R settings", id = "rset", type = _G.MENU })
            -- KS
            MENU.rset:MenuElement({name = "KS", id = "killsteal", type = _G.MENU })
                MENU.rset.killsteal:MenuElement({id = "enabled", name = "Enabled", value = false})
                MENU.rset.killsteal:MenuElement({id = "minhp", name = "Minimum enemy hp", value = 200, min = 1, max = 300, step = 1})
            -- Auto
            MENU.rset:MenuElement({name = "Auto", id = "auto", type = _G.MENU })
                MENU.rset.auto:MenuElement({id = "enabled", name = "Enabled", value = true})
                MENU.rset.auto:MenuElement({id = "xenemies", name = ">= X enemies near morgana", value = 3, min = 1, max = 5, step = 1})
                MENU.rset.auto:MenuElement({id = "xrange", name = "< X distance enemies to morgana", value = 300, min = 100, max = 550, step = 50})
            -- Combo / Harass
            MENU.rset:MenuElement({name = "Combo / Harass", id = "comhar", type = _G.MENU })
                MENU.rset.comhar:MenuElement({id = "combo", name = "Use R Combo", value = true})
                MENU.rset.comhar:MenuElement({id = "harass", name = "Use R Harass", value = false})
                MENU.rset.comhar:MenuElement({id = "xenemies", name = ">= X enemies near morgana", value = 2, min = 1, max = 4, step = 1})
                MENU.rset.comhar:MenuElement({id = "xrange", name = "< X distance enemies to morgana", value = 300, min = 100, max = 550, step = 50})
        -- Version
        MENU:MenuElement({name = "Version " .. tostring(MorganaVersion), type = _G.SPACE, id = "verspace"})
        CHAMPION = LocalCore:Class()
        function CHAMPION:__init()
            self.QData = { Type = _G.SPELLTYPE_LINE, Aoe = false, Delay = 0.25, Radius = 70, Range = 1175, Speed = 1200, Collision = true, MaxCollision = 0, CollisionObjects = { _G.COLLISION_MINION, _G.COLLISION_YASUOWALL } }
            self.WData = { Type = _G.SPELLTYPE_CIRCLE, Aoe = false, Collision = false, Delay = 0.25, Radius = 150, Range = 900, Speed = math.huge }
            self.EData = { Range = 800 }
            self.RData = { Range = 625 }
        end
        function CHAMPION:QLogic()
            local result = false
            if SPELLS:IsReady(_Q, { q = 1, w = 0.3, e = 0.3, r = 0.3 } ) then
                local EnemyHeroes = OB:GetEnemyHeroes(self.QData.Range, false, LocalCore.HEROES_SPELL)
        
                if MENU.qset.killsteal.enabled:Value() then
                    local baseDmg = 25
                    local lvlDmg = 55 * myHero:GetSpellData(_Q).level
                    local apDmg = myHero.ap * 0.9
                    local qDmg = baseDmg + lvlDmg + apDmg
                    if qDmg > MENU.qset.killsteal.minhp:Value() then
                        for i = 1, #EnemyHeroes do
                            local qTarget = EnemyHeroes[i]
                            if qTarget.health > MENU.qset.killsteal.minhp:Value() and qTarget.health < DMG:CalculateDamage(myHero, qTarget, LocalCore.DAMAGE_TYPE_MAGICAL, qDmg) then
                                result = CastSpell(HK_Q, qTarget, self.QData, MENU.qset.killsteal.hitchance:Value() + 1)
                            end
                        end
                    end
                end if result then return end
        
                if (ORB.Modes[LocalCore.ORBWALKER_MODE_COMBO] and MENU.qset.comhar.combo:Value()) or (ORB.Modes[LocalCore.ORBWALKER_MODE_HARASS] and MENU.qset.comhar.harass:Value()) then
                    local qList = {}
                    for i = 1, #EnemyHeroes do
                        local hero = EnemyHeroes[i]
                        local heroName = hero.charName
                        if MENU.qset.comhar.useon[heroName] and MENU.qset.comhar.useon[heroName]:Value() then
                            qList[#qList+1] = hero
                        end
                    end
                    result = CastSpell(HK_Q, TS:GetTarget(qList, LocalCore.DAMAGE_TYPE_MAGICAL), self.QData, MENU.qset.comhar.hitchance:Value() + 1)
                end if result then return end

                if MENU.qset.auto.enabled:Value() then
                    local qList = {}
                    for i = 1, #EnemyHeroes do
                        local hero = EnemyHeroes[i]
                        local heroName = hero.charName
                        if MENU.qset.auto.useon[heroName] and MENU.qset.auto.useon[heroName]:Value() then
                            qList[#qList+1] = hero
                        end
                    end
                    CastSpell(HK_Q, TS:GetTarget(qList, LocalCore.DAMAGE_TYPE_MAGICAL), self.QData,  MENU.qset.auto.hitchance:Value() + 1)
                end
            end
        end
        function CHAMPION:WLogic()
            local result = false
            if SPELLS:IsReady(_W, { q = 0.3, w = 1, e = 0.3, r = 0.3 } ) then
                local EnemyHeroes = OB:GetEnemyHeroes(self.WData.Range, false, 0)

                if MENU.wset.killsteal.enabled:Value() then
                    local baseDmg = 10
                    local lvlDmg = 14 * myHero:GetSpellData(_W).level
                    local apDmg = myHero.ap * 0.22
                    local wDmg = baseDmg + lvlDmg + apDmg
                    if wDmg > MENU.wset.killsteal.minhp:Value() then
                        for i = 1, #EnemyHeroes do
                            local wTarget = EnemyHeroes[i]
                            if wTarget.health > MENU.wset.killsteal.minhp:Value() and wTarget.health < DMG:CalculateDamage(myHero, wTarget, LocalCore.DAMAGE_TYPE_MAGICAL, wDmg) then
                                result = CastSpell(HK_W, wTarget, self.WData, _G.HITCHANCE_HIGH)
                            end
                        end
                    end
                end if result then return end
        
                if (ORB.Modes[LocalCore.ORBWALKER_MODE_COMBO] and MENU.wset.comhar.combo:Value()) or (ORB.Modes[LocalCore.ORBWALKER_MODE_HARASS] and MENU.wset.comhar.harass:Value()) then
                    for i = 1, #EnemyHeroes do
                        result = CastSpell(HK_W, EnemyHeroes[i], self.WData, _G.HITCHANCE_HIGH)
                        if result then break end
                    end
                end if result then return end
        
                if (ORB.Modes[LocalCore.ORBWALKER_MODE_LANECLEAR] and MENU.wset.laneclear.enabled:Value()) then
                    local target = nil
                    local BestHit = 0
                    local CurrentCount = 0
                    local eMinions = OB:GetEnemyMinions(self.WData.Range + 200)
                    for i = 1, #eMinions do
                        local minion = eMinions[i]
                        CurrentCount = 0
                        local minionPos = minion.pos
                        for j = 1, #eMinions do
                            local minion2 = eMinions[i]
                            if LocalCore:IsInRange(minionPos, minion2.pos, 250) then
                                CurrentCount = CurrentCount + 1
                            end
                        end
                        if CurrentCount > BestHit then
                            BestHit = CurrentCount
                            target = minion
                        end
                    end
                    if target and BestHit >= MENU.wset.laneclear.xminions:Value() then
                        result = Control.CastSpell(HK_W, target)
                    end
                end if result then return end
        
                if MENU.wset.auto.enabled:Value() then
                    for i = 1, #EnemyHeroes do
                        local unit = EnemyHeroes[i]
                        local ImmobileDuration, DashDuration, SlowDuration = GetImmobileDashSlowDuration(unit)
                        if ImmobileDuration > 0.5 and not unit.pathing.isDashing then
                            Control.CastSpell(HK_W, unit)
                        end
                    end
                end
            end
        end
        function CHAMPION:ELogic()
            if MENU.eset.auto.enabled:Value() and (MENU.eset.auto.ally:Value() or MENU.eset.auto.selfish:Value()) and SPELLS:IsReady(_E, { q = 0.3, w = 0.3, e = 1, r = 0.3 } ) then
                local EnemyHeroes = OB:GetEnemyHeroes(2500, false, LocalCore.HEROES_IMMORTAL)
                local AllyHeroes = OB:GetAllyHeroes(self.EData.Range)
                for i = 1, #EnemyHeroes do
                    local hero = EnemyHeroes[i]
                    local heroPos = hero.pos
                    local currSpell = hero.activeSpell
                    if currSpell and currSpell.valid and hero.isChanneling then
                        for j = 1, #AllyHeroes do
                            local ally = AllyHeroes[j]
                            if (MENU.eset.auto.selfish:Value() and ally.isMe) or (MENU.eset.auto.ally:Value() and not ally.isMe) then
                                local canUse = false
                                local allyPos = ally.pos
                                if currSpell.target == ally.handle then
                                    canUse = true
                                else
                                    local spellPos = currSpell.placementPos
                                    local width = ally.boundingRadius + 100
                                    if currSpell.width > 0 then width = width + currSpell.width end
                                    local isOnSegment, pointSegment, pointLine = LocalCore:ProjectOn(allyPos, spellPos, heroPos)
                                    if LocalCore:IsInRange(pointSegment, allyPos, width) then
                                        canUse = true
                                    end
                                end
                                if canUse then
                                    Control.CastSpell(HK_E, ally)
                                end
                            end
                        end
                    end
                end
            end
        end
        function CHAMPION:RLogic()
            local result = false
            if SPELLS:IsReady(_R, { q = 0.33, w = 0.33, e = 0.33, r = 1 } ) then
                local EnemyHeroes = OB:GetEnemyHeroes(self.RData.Range, false, 0)
        
                if MENU.rset.killsteal.enabled:Value() then
                    local baseDmg = 75
                    local lvlDmg = 75 * myHero:GetSpellData(_R).level
                    local apDmg = myHero.ap * 0.7
                    local rDmg = baseDmg + lvlDmg + apDmg
                    if rDmg > MENU.rset.killsteal.minhp:Value() then
                        for i = 1, #EnemyHeroes do
                            local rTarget = EnemyHeroes[i]
                            if rTarget.health > MENU.rset.killsteal.minhp:Value() and rTarget.health < DMG:CalculateDamage(myHero, rTarget, LocalCore.DAMAGE_TYPE_MAGICAL, rDmg) then
                                result = LocalCore:CastSpell(HK_R)
                            end
                        end
                    end
                end if result then return end
        
                if (ORB.Modes[LocalCore.ORBWALKER_MODE_COMBO] and MENU.rset.comhar.combo:Value()) or (ORB.Modes[LocalCore.ORBWALKER_MODE_HARASS] and MENU.rset.comhar.harass:Value()) then
                    local count = 0
                    local mePos = myHero.pos
                    for i = 1, #EnemyHeroes do
                        local unit = EnemyHeroes[i]
                        if LocalCore:IsInRange(mePos, unit.pos, MENU.rset.comhar.xrange:Value()) then
                            count = count + 1
                        end
                    end
                    if count >= MENU.rset.comhar.xenemies:Value() then
                        result = LocalCore:CastSpell(HK_R)
                    end
                end if result then return end
                
                if MENU.rset.auto.enabled:Value() then
                    local count = 0
                    local mePos = myHero.pos
                    for i = 1, #EnemyHeroes do
                        local unit = EnemyHeroes[i]
                        if LocalCore:GetDistance(mePos, unit.pos) < MENU.rset.auto.xrange:Value() then
                            count = count + 1
                        end
                    end
                    if count >= MENU.rset.auto.xenemies:Value() then
                        result = LocalCore:CastSpell(HK_R)
                    end if result then return end
                end
            end
        end
        function CHAMPION:Tick()
            -- Is Attacking
            if ORB:IsAutoAttacking() then
                return
            end
            self:QLogic()
            self:WLogic()
            self:ELogic()
            self:RLogic()
        end
        function CHAMPION:Interrupter()
            INTERRUPTER = LocalCore:__Interrupter()
            INTERRUPTER:OnInterrupt(function(enemy)
                if MENU.qset.interrupter:Value() and SPELLS:IsReady(_Q, { q = 1, w = 0.3, e = 0.3, r = 0.3 } ) and enemy.pos:ToScreen().onScreen and myHero.pos:DistanceTo(enemy.pos) < 1000 then
                    CastSpell(HK_Q, enemy, self.QData, _G.HITCHANCE_NORMAL)
                end
            end)
        end
        function CHAMPION:CanAttack()
            if not SPELLS:CheckSpellDelays({ q = 0.33, w = 0.33, e = 0.33, r = 0.33 }) then
                return false
            end
            -- LastHit, LaneClear
            if not ORB.Modes[LocalCore.ORBWALKER_MODE_COMBO] and not ORB.Modes[LocalCore.ORBWALKER_MODE_HARASS] then
                return true
            end
            -- Q
            if MENU.qset.disaa:Value() and myHero:GetSpellData(_Q).level > 0 and myHero.mana > myHero:GetSpellData(_Q).mana and (LocalGameCanUseSpell(_Q) == 0 or myHero:GetSpellData(_Q).currentCd < 1) then
                return false
            end
            return true
        end
        function CHAMPION:CanMove()
            if not SPELLS:CheckSpellDelays({ q = 0.25, w = 0.25, e = 0.25, r = 0.25 }) then
                return false
            end
            return true
        end
    end,
    Karthus = function()
        local KarthusVersion = 0.01
        MENU = MenuElement({name = "Gamsteron Karthus", id = "Gamsteron_Karthus", type = _G.MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Icons/karthusw5s.png" })
        -- Q
        MENU:MenuElement({name = "Q settings", id = "qset", type = _G.MENU })
            -- Disable Attack
            MENU.qset:MenuElement({id = "disaa", name = "Disable attack", value = true})
            -- KS
            MENU.qset:MenuElement({name = "KS", id = "killsteal", type = _G.MENU })
                MENU.qset.killsteal:MenuElement({id = "enabled", name = "Enabled", value = true})
                MENU.qset.killsteal:MenuElement({id = "minhp", name = "minimum enemy hp", value = 200, min = 1, max = 300, step = 1})
                MENU.qset.killsteal:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = { "normal", "high" } })
            -- Auto
            MENU.qset:MenuElement({name = "Auto", id = "auto", type = _G.MENU })
                MENU.qset.auto:MenuElement({id = "enabled", name = "Enabled", value = true})
                MENU.qset.auto:MenuElement({name = "Use on:", id = "useon", type = _G.MENU })
                    LocalCore:OnEnemyHeroLoad(function(hero) MENU.qset.auto.useon:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
                MENU.qset.auto:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = { "normal", "high" } })
            -- Combo / Harass
            MENU.qset:MenuElement({name = "Combo / Harass", id = "comhar", type = _G.MENU })
                MENU.qset.comhar:MenuElement({id = "combo", name = "Combo", value = true})
                MENU.qset.comhar:MenuElement({id = "harass", name = "Harass", value = false})
                MENU.qset.comhar:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = { "normal", "high" } })
        -- W
        MENU:MenuElement({name = "W settings", id = "wset", type = _G.MENU })
            MENU.wset:MenuElement({id = "combo", name = "Combo", value = true})
            MENU.wset:MenuElement({id = "harass", name = "Harass", value = false})
            MENU.wset:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = { "normal", "high" } })
        -- E
        MENU:MenuElement({name = "E settings", id = "eset", type = _G.MENU })
            MENU.eset:MenuElement({id = "auto", name = "Auto", value = true})
            MENU.eset:MenuElement({id = "combo", name = "Combo", value = true})
            MENU.eset:MenuElement({id = "harass", name = "Harass", value = false})
            MENU.eset:MenuElement({id = "minmp", name = "minimum mana percent", value = 25, min = 1, max = 100, step = 1})
        --R
        MENU:MenuElement({name = "R settings", id = "rset", type = _G.MENU })
            MENU.rset:MenuElement({id = "killsteal", name = "Auto KS X enemies in passive form", value = true})
            MENU.rset:MenuElement({id = "kscount", name = "^^^ X enemies ^^^", value = 2, min = 1, max = 5, step = 1})
        -- Drawings
        MENU:MenuElement({name = "Drawings", id = "draws", type = _G.MENU })
            MENU.draws:MenuElement({name = "Draw Kill Count", id = "ksdraw", type = _G.MENU })
            MENU.draws.ksdraw:MenuElement({id = "enabled", name = "Enabled", value = true})
            MENU.draws.ksdraw:MenuElement({id = "size", name = "Text Size", value = 25, min = 1, max = 64, step = 1 })
        -- Version
        MENU:MenuElement({name = "Version " .. tostring(KarthusVersion), type = _G.SPACE, id = "verspace"})
        CHAMPION = LocalCore:Class()
        function CHAMPION:__init()
            self.QData = { delay = 0.625, radius = 1, range = 900, speed = _G.math.huge, collision = false, type = _G.SPELLTYPE_CIRCLE }
            self.WData = { delay = 0.25, radius = 1, range = 1000, speed = _G.math.huge, collision = false, type = _G.SPELLTYPE_CIRCLE }
        end
        function CHAMPION:Tick()
            -- Is Attacking
            if ORB:IsAutoAttacking() then
                return
            end
            -- Has Passive Buff
            local hasPassive = LocalCore:HasBuff(myHero, "karthusdeathdefiedbuff")
            -- W
            if SPELLS:IsReady(_W, { q = 0.33, w = 0.5, e = 0.33, r = 3.23 } ) then
                if (ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.wset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.wset.harass:Value()) then
                    local enemyList = OB:GetEnemyHeroes(1000, false, 0)
                    CastSpell(HK_W, TS:GetTarget(enemyList, 1), self.WData, MENU.wset.hitchance:Value() + 1)
                end
            end
            -- E
            if SPELLS:IsReady(_E, { q = 0.33, w = 0.33, e = 0.5, r = 3.23 } ) and not hasPassive then
                if MENU.eset.auto:Value() or (ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.eset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.eset.harass:Value()) then
                    local enemyList = OB:GetEnemyHeroes(425, false, 0)
                    local eBuff = LocalCore:HasBuff(myHero, "karthusdefile")
                    if eBuff and #enemyList == 0 and Control.CastSpell(HK_E) then
                        return
                    end
                    local manaPercent = 100 * myHero.mana / myHero.maxMana
                    if not eBuff and #enemyList > 0 and manaPercent > MENU.eset.minmp:Value() and Control.CastSpell(HK_E) then
                        return
                    end
                end
            end
            -- Q
            if SPELLS:IsReady(_Q, { q = 0.5, w = 0.33, e = 0.33, r = 3.23 } ) and myHero:GetSpellData(_Q).ammoCd == 0 and myHero:GetSpellData(_Q).ammoCurrentCd == 0 and myHero:GetSpellData(_Q).ammo == 2 then
                -- KS
                if MENU.qset.killsteal.enabled:Value() then
                    local qDmg = self:GetQDmg()
                    local minHP = MENU.qset.killsteal.minhp:Value()
                    if qDmg > minHP then
                        local enemyList = OB:GetEnemyHeroes(875, false, 0)
                        for i = 1, #enemyList do
                            local qTarget = enemyList[i]
                            if qTarget.health > minHP and qTarget.health < DMG:CalculateDamage(myHero, qTarget, DAMAGE_TYPE_MAGICAL, self:GetQDmg()) then
                                CastSpell(HK_Q, qTarget, self.QData, MENU.qset.killsteal.hitchance:Value() + 1)
                            end
                        end
                    end
                end
                -- Combo Harass
                if (ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.qset.comhar.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.qset.comhar.harass:Value()) then
                    for i = 1, 3 do
                        local enemyList = OB:GetEnemyHeroes(1000 - (i*100), false, 0)
                        CastSpell(HK_Q, TS:GetTarget(enemyList, 1), self.QData, MENU.qset.comhar.hitchance:Value() + 1)
                    end
                -- Auto
                elseif MENU.qset.auto.enabled:Value() then
                    for i = 1, 3 do
                        local qList = {}
                        local enemyList = OB:GetEnemyHeroes(1000 - (i*100), false, 0)
                        for i = 1, #enemyList do
                            local hero = enemyList[i]
                            local heroName = hero.charName
                            if MENU.qset.auto.useon[heroName] and MENU.qset.auto.useon[heroName]:Value() then
                                qList[#qList+1] = hero
                            end
                        end
                        CastSpell(HK_Q, TS:GetTarget(qList, 1), self.QData, MENU.qset.auto.hitchance:Value() + 1)
                    end
                end
            end
            -- R
            if SPELLS:IsReady(_R, { q = 0.33, w = 0.33, e = 0.33, r = 0.5 } ) and MENU.rset.killsteal:Value() and hasPassive then
                local rCount = 0
                local enemyList = OB:GetEnemyHeroes(99999, false, 0)
                for i = 1, #enemyList do
                    local rTarget = enemyList[i]
                    if rTarget.health < DMG:CalculateDamage(myHero, rTarget, DAMAGE_TYPE_MAGICAL, self:GetRDmg()) then
                        rCount = rCount + 1
                    end
                end
                if rCount > MENU.rset.kscount:Value() and Control.CastSpell(HK_R) then
                    return
                end
            end
        end
        function CHAMPION:Draw()
            if MENU.draws.ksdraw.enabled:Value() and LocalGameCanUseSpell(_R) == 0 then
                local rCount = 0
                local enemyList = OB:GetEnemyHeroes(99999, false, 0)
                for i = 1, #enemyList do
                    local rTarget = enemyList[i]
                    if rTarget.health < DMG:CalculateDamage(myHero, rTarget, DAMAGE_TYPE_MAGICAL, self:GetRDmg()) then
                        rCount = rCount + 1
                    end
                end
                local mePos = myHero.pos:To2D()
                local posX = mePos.x - 50
                local posY = mePos.y
                if rCount > 0 then
                    LocalDrawText("Kill Count: "..rCount, MENU.draws.ksdraw.size:Value(), posX, posY, LocalDrawColor(255, 000, 255, 000))
                else
                    LocalDrawText("Kill Count: "..rCount, MENU.draws.ksdraw.size:Value(), posX, posY, LocalDrawColor(150, 255, 000, 000))
                end
            end
        end
        function CHAMPION:CanAttack()
            if not SPELLS:CheckSpellDelays({ q = 0.33, w = 0.33, e = 0.33, r = 3.23 }) then
                return false
            end
            if not MENU.qset.disaa:Value() then
                return true
            end
            if not ORB.Modes[ORBWALKER_MODE_COMBO] and not ORB.Modes[ORBWALKER_MODE_HARASS] then
                return true
            end
            if myHero.mana > myHero:GetSpellData(_Q).mana then
                return false
            end
            return true
        end
        function CHAMPION:CanMove()
            if not SPELLS:CheckSpellDelays({ q = 0.2, w = 0.2, e = 0.2, r = 3.13 }) then
                return false
            end
            return true
        end
        function CHAMPION:GetQDmg()
            local qLvl = myHero:GetSpellData(_Q).level
            if qLvl == 0 then return 0 end
            local baseDmg = 30
            local lvlDmg = 20 * qLvl
            local apDmg = myHero.ap * 0.3
            return baseDmg + lvlDmg + apDmg
        end
        function CHAMPION:GetRDmg()
            local rLvl = myHero:GetSpellData(_R).level
            if rLvl == 0 then return 0 end
            local baseDmg = 100
            local lvlDmg = 150 * rLvl
            local apDmg = myHero.ap * 0.75
            return baseDmg + lvlDmg + apDmg
        end
    end,
    KogMaw = function()
        local KogMawVersion = 0.01
        MENU = MenuElement({name = "Gamsteron KogMaw", id = "Gamsteron_KogMaw", type = _G.MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Icons/kog.png" })
        -- Q
        MENU:MenuElement({name = "Q settings", id = "qset", type = _G.MENU })
            MENU.qset:MenuElement({id = "combo", name = "Combo", value = true})
            MENU.qset:MenuElement({id = "harass", name = "Harass", value = false})
            MENU.qset:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = { "normal", "high" } })
        -- W
        MENU:MenuElement({name = "W settings", id = "wset", type = _G.MENU })
            MENU.wset:MenuElement({id = "combo", name = "Combo", value = true})
            MENU.wset:MenuElement({id = "harass", name = "Harass", value = false})
            MENU.wset:MenuElement({id = "stopq", name = "Stop Q if has W buff", value = false})
            MENU.wset:MenuElement({id = "stope", name = "Stop E if has W buff", value = false})
            MENU.wset:MenuElement({id = "stopr", name = "Stop R if has W buff", value = false})
        -- E
        MENU:MenuElement({name = "E settings", id = "eset", type = _G.MENU })
            MENU.eset:MenuElement({id = "combo", name = "Combo", value = true})
            MENU.eset:MenuElement({id = "harass", name = "Harass", value = false})
            MENU.eset:MenuElement({id = "emana", name = "Minimum Mana %", value = 20, min = 1, max = 100, step = 1 })
            MENU.eset:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = { "normal", "high" } })
        -- R
        MENU:MenuElement({name = "R settings", id = "rset", type = _G.MENU })
            MENU.rset:MenuElement({id = "combo", name = "Combo", value = true})
            MENU.rset:MenuElement({id = "harass", name = "Harass", value = false})
            MENU.rset:MenuElement({id = "onlylow", name = "Only 0-40 % HP enemies", value = true})
            MENU.rset:MenuElement({id = "stack", name = "Stop at x stacks", value = 3, min = 1, max = 9, step = 1 })
            MENU.rset:MenuElement({id = "rmana", name = "Minimum Mana %", value = 20, min = 1, max = 100, step = 1 })
            MENU.rset:MenuElement({name = "KS", id = "ksmenu", type = _G.MENU })
                MENU.rset.ksmenu:MenuElement({id = "ksr", name = "KS - Enabled", value = true})
                MENU.rset.ksmenu:MenuElement({id = "csksr", name = "KS -> Check R stacks", value = false})
            MENU.rset:MenuElement({name = "Semi Manual", id = "semirkog", type = _G.MENU })
                MENU.rset.semirkog:MenuElement({name = "Semi-Manual Key", id = "semir", key = string.byte("T")})
                MENU.rset.semirkog:MenuElement({name = "Check R stacks", id = "semistacks", value = false})
                MENU.rset.semirkog:MenuElement({name = "Only 0-40 % HP enemies", id = "semilow",  value = false})
                MENU.rset.semirkog:MenuElement({name = "Use on:", id = "useon", type = _G.MENU })
                    LocalCore:OnEnemyHeroLoad(function(hero) MENU.rset.semirkog.useon:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
            MENU.rset:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = { "normal", "high" } })
        -- Version
        MENU:MenuElement({name = "Version " .. tostring(KogMawVersion), type = _G.SPACE, id = "verspace"})
        CHAMPION = LocalCore:Class()
        function CHAMPION:__init()
            self.QData = { delay = 0.25, radius = 70, range = 1175, speed = 1650, collision = true, type = _G.SPELLTYPE_LINE }
            self.EData = { delay = 0.25, radius = 120, range = 1280, speed = 1350, collision = false, type = _G.SPELLTYPE_LINE }
            self.RData = { delay = 1.2, radius = 225, range = 0, speed = math.huge, collision = false, type = _G.SPELLTYPE_CIRCLE }
            self.HasWBuff = false
        end
        function CHAMPION:Tick()
            -- Is Attacking
            if ORB:IsAutoAttacking() then
                return
            end
            -- Can Attack
            local AATarget = TS:GetComboTarget()
            if AATarget and not ORB.IsNone and ORB:CanAttack() then
                return
            end
            -- W
            if ((ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.wset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.wset.harass:Value())) and ORB:IsBeforeAttack(0.55) and SPELLS:IsReady(_W, { q = 0.33, w = 0.5, e = 0.33, r = 0.33 } ) then
                local enemyList = OB:GetEnemyHeroes(610 + ( 20 * myHero:GetSpellData(_W).level ) + myHero.boundingRadius - 35, true, 1)
                if #enemyList > 0 and Control.CastSpell(HK_W) then
                    return
                end
            end
            -- Check W Buff
            local HasWBuff = false
            for i = 0, myHero.buffCount do
                local buff = myHero:GetBuff(i)
                if buff and buff.count > 0 and buff.duration > 0 and buff.name == "KogMawBioArcaneBarrage" then
                    HasWBuff = true
                    break
                end
            end
            self.HasWBuff = HasWBuff
            -- Get Mana Percent
            local manaPercent = 100 * myHero.mana / myHero.maxMana
            -- Save Mana
            local wMana = 40 - ( myHero:GetSpellData(_W).currentCd * myHero.mpRegen )
            local meMana = myHero.mana - wMana
            if not(AATarget) and (LocalGameTimer() < SPELLS.LastW + 0.3 or LocalGameTimer() < SPELLS.LastWk + 0.3) then
                return
            end
            -- R
            local result = false
            if meMana > myHero:GetSpellData(_R).mana and SPELLS:IsReady(_R, { q = 0.33, w = 0.15, e = 0.33, r = 0.5 } ) then
                self.RData.range = 900 + 300 * myHero:GetSpellData(_R).level
                local enemyList = OB:GetEnemyHeroes(self.RData.range, false, 0)
                local rStacks = LocalCore:GetBuffCount(myHero, "kogmawlivingartillerycost") < MENU.rset.stack:Value()
                local checkRStacksKS = MENU.rset.ksmenu.csksr:Value()
                -- KS
                if MENU.rset.ksmenu.ksr:Value() and ( not checkRStacksKS or rStacks ) then
                    local rTargets = {}
                    for i = 1, #enemyList do
                        local hero = enemyList[i]
                        local baseRDmg = 60 + ( 40 * myHero:GetSpellData(_R).level ) + ( myHero.bonusDamage * 0.65 ) + ( myHero.ap * 0.25 )
                        local rMultipier = math.floor(100 - ( ( ( hero.health + ( hero.hpRegen * 3 ) ) * 100 ) / hero.maxHealth ))
                        local rDmg
                        if rMultipier > 60 then
                            rDmg = baseRDmg * 2
                        else
                            rDmg = baseRDmg * ( 1 + ( rMultipier * 0.00833 ) )
                        end
                        rDmg = DMG:CalculateDamage(myHero, hero, DAMAGE_TYPE_MAGICAL, rDmg)
                        local unitKillable = rDmg > hero.health + (hero.hpRegen * 2)
                        if unitKillable then
                            rTargets[#rTargets+1] = hero
                        end
                    end
                    result = CastSpell(HK_R, TS:GetTarget(rTargets, 1), self.RData, MENU.rset.hitchance:Value() + 1)
                end if result then return end
                -- SEMI MANUAL
                local checkRStacksSemi = MENU.rset.semirkog.semistacks:Value()
                if MENU.rset.semirkog.semir:Value() and ( not checkRStacksSemi or rStacks ) then
                    local onlyLowR = MENU.rset.semirkog.semilow:Value()
                    local rTargets = {}
                    if onlyLowR then
                        for i = 1, #enemyList do
                            local hero = enemyList[i]
                            if hero and ( ( hero.health + ( hero.hpRegen * 3 ) ) * 100 ) / hero.maxHealth < 40 then
                                rTargets[#rTargets+1] = hero
                            end
                        end
                    else
                        rTargets = enemyList
                    end
                    result = CastSpell(HK_R, TS:GetTarget(rTargets, 1), self.RData, MENU.rset.hitchance:Value() + 1)
                end if result then return end
                -- Combo / Harass
                if (ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.rset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.rset.harass:Value()) then
                    local stopRIfW = MENU.wset.stopr:Value() and self.HasWBuff
                    if not stopRIfW and rStacks and manaPercent > MENU.rset.rmana:Value() then
                        local onlyLowR = MENU.rset.onlylow:Value()
                        local AATarget2
                        if onlyLowR and AATarget and ( AATarget.health * 100 ) / AATarget.maxHealth > 39 then
                            AATarget2 = nil
                        else
                            AATarget2 = AATarget
                        end
                        local t
                        if AATarget2 then
                            t = AATarget2
                        else
                            local rTargets = {}
                            if onlyLowR then
                                for i = 1, #enemyList do
                                    local hero = enemyList[i]
                                    if hero and ( ( hero.health + ( hero.hpRegen * 3 ) ) * 100 ) / hero.maxHealth < 40 then
                                        rTargets[#rTargets+1] = hero
                                    end
                                end
                            else
                                rTargets = enemyList
                            end
                            t = TS:GetTarget(rTargets, 1)
                        end
                        result = CastSpell(HK_R, t, self.RData, MENU.rset.hitchance:Value() + 1)
                    end
                end if result then return end
            end
            -- Q
            local stopQIfW = MENU.wset.stopq:Value() and self.HasWBuff
            if not stopQIfW and meMana > myHero:GetSpellData(_Q).mana and SPELLS:IsReady(_Q, { q = 0.5, w = 0.15, e = 0.33, r = 0.33 } ) then
                -- Combo / Harass
                if (ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.qset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.qset.harass:Value()) then
                    local t
                    if AATarget then
                        t = AATarget
                    else
                        t = TS:GetTarget(OB:GetEnemyHeroes(1175, false, 0), 1)
                    end
                    result = CastSpell(HK_Q, t, self.QData, MENU.qset.hitchance:Value() + 1)
                end
            end if result then return end
            -- E
            local stopEifW = MENU.wset.stope:Value() and self.HasWBuff
            if not stopEifW and manaPercent > MENU.eset.emana:Value() and meMana > myHero:GetSpellData(_E).mana and SPELLS:IsReady(_E, { q = 0.33, w = 0.15, e = 0.5, r = 0.33 } ) then
                if (ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.eset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.eset.harass:Value()) then
                    local t
                    if AATarget then
                        t = AATarget
                    else
                        t = TS:GetTarget(OB:GetEnemyHeroes(1280, false, 0), 1)
                    end
                    result = CastSpell(HK_E, t, self.EData, MENU.eset.hitchance:Value() + 1)
                end
            end if result then return end
        end
        function CHAMPION:PreAttack(args)
            if ((ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.wset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.wset.harass:Value())) and SPELLS:IsReady(_W, { q = 0.33, w = 0.5, e = 0.33, r = 0.33 } ) then
                local enemyList = OB:GetEnemyHeroes(610 + ( 20 * myHero:GetSpellData(_W).level ) + myHero.boundingRadius - 35, true, 1)
                if #enemyList > 0 and Control.CastSpell(HK_W) then
                    args.Process = false
                end
            end
        end
        function CHAMPION:CanMove()
            if not SPELLS:CheckSpellDelays({ q = 0.2, w = 0, e = 0.2, r = 0.2 }) then
                return false
            end
            return true
        end
        function CHAMPION:CanAttack()
            if not SPELLS:CheckSpellDelays({ q = 0.33, w = 0, e = 0.33, r = 0.33 }) then
                return false
            end
            return true
        end
    end,
    Vayne = function()
        require "MapPositionGOS"
        local VayneVersion = "0.03 - antimelee, antidash, interrupt etc."
        MENU = MenuElement({name = "Gamsteron Vayne", id = "Gamsteron_Vayne", type = _G.MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Icons/vayne.png" })
        -- Q
        MENU:MenuElement({name = "Q settings", id = "qset", type = _G.MENU })
            MENU.qset:MenuElement({id = "combo", name = "Combo", value = true})
            MENU.qset:MenuElement({id = "harass", name = "Harass", value = false})
        -- E
        MENU:MenuElement({name = "E settings", id = "eset", type = _G.MENU })
            MENU.eset:MenuElement({id = "melee", name = "AntiMelee", value = true})
            MENU.eset:MenuElement({name = "Use on (AntiMelee):", id = "useonmelee", type = _G.MENU })
                LocalCore:OnEnemyHeroLoad(function(hero)
                    local notMelee = {
                        ["Thresh"] = true,
                        ["Azir"] = true,
                        ["Velkoz"] = true
                    }
                    if LocalCore.IsMelee[hero.charName] and not notMelee[hero.charName] then
                        MENU.eset.useonmelee:MenuElement({id = hero.charName, name = hero.charName, value = true})
                    end
                end)
            MENU.eset:MenuElement({id = "dash", name = "AntiDash - kha e, rangar r", value = true})
            MENU.eset:MenuElement({id = "interrupt", name = "Interrupt dangerous spells", value = true})
            MENU.eset:MenuElement({id = "combo", name = "Combo (Stun)", value = true})
            MENU.eset:MenuElement({id = "harass", name = "Harass (Stun)", value = false})
            MENU.eset:MenuElement({name = "Use on (Stun):", id = "useonstun", type = _G.MENU })
                LocalCore:OnEnemyHeroLoad(function(hero) MENU.eset.useonstun:MenuElement({id = hero.charName, name = hero.charName, value = true}) end)
        --R
        MENU:MenuElement({name = "R settings", id = "rset", type = _G.MENU })
            MENU.rset:MenuElement({id = "qready", name = "Only if Q ready or almost ready", value = true})
            MENU.rset:MenuElement({id = "combo", name = "Combo - if X enemies near vayne", value = true})
            MENU.rset:MenuElement({id = "xcount", name = "  ^^^ X enemies ^^^", value = 3, min = 1, max = 5, step = 1})
            MENU.rset:MenuElement({id = "xdistance", name = "^^^ max. distance ^^^", value = 500, min = 250, max = 750, step = 50})
        -- Version
        MENU:MenuElement({name = "Version " .. tostring(VayneVersion), type = _G.SPACE, id = "verspace"})
        CHAMPION = LocalCore:Class()
        function CHAMPION:__init()
            _G.GamsteronMenuSpell.isaa:Value(false)
            self.LastReset = 0
            self.EData = { delay = 0.5, radius = 0, range = 550 - 35, speed = 2000, collision = false, type = _G.SPELLTYPE_LINE }
        end
        function CHAMPION:Tick()

            -- reset attack after Q
            if LocalGameCanUseSpell(_Q) ~= 0 and LocalGameTimer() > self.LastReset + 1 and LocalCore:HasBuff(myHero, "vaynetumblebonus") then
                ORB:__OnAutoAttackReset()
                self.LastReset = LocalGameTimer()
            end
            -- reset attack after Q

            local result = false

            -- r
            if ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.rset.combo:Value() and SPELLS:IsReady(_R, { q = 0.5, w = 0, e = 0.5, r = 0.5 } ) then
                local canR = true
                if MENU.rset.qready:Value() then
                    canR = false
                    if LocalGameCanUseSpell(_Q) == 0 then canR = true end
                    if LocalGameCanUseSpell(_Q) == 32 and myHero.mana > myHero:GetSpellData(_Q).mana and myHero:GetSpellData(_Q).currentCd < 0.75 then canR = true end
                end
                if canR then
                    local countEnemies = 0
                    for i = 1, LocalGameHeroCount() do
                        local hero = LocalGameHero(i)
                        if LocalCore:IsValidTarget(hero) and hero.team == LocalCore.TEAM_ENEMY and myHero.pos:DistanceTo(hero.pos) < MENU.rset.xdistance:Value() and not OB:IsHeroImmortal(hero, false) then
                            countEnemies = countEnemies + 1
                        end
                    end
                    if countEnemies >= MENU.rset.xcount:Value() then
                        result = Control.CastSpell(HK_R)
                    end
                end
            end
            -- r

            -- e
            if not result and SPELLS:IsReady(_E, { q = 0.75, w = 0, e = 0.75, r = 0 } ) then

                -- e antiMelee
                if MENU.eset.melee:Value() then
                    local meleeHeroes = {}
                    for i = 1, LocalGameHeroCount() do
                        local hero = LocalGameHero(i)
                        if LocalCore:IsValidTarget(hero) and hero.team == LocalCore.TEAM_ENEMY and hero.range < 400 and MENU.eset.useonmelee[hero.charName] and MENU.eset.useonmelee[hero.charName]:Value() and myHero.pos:DistanceTo(hero.pos) < hero.range + myHero.boundingRadius + hero.boundingRadius then
                            _G.table.insert(meleeHeroes, hero)
                        end
                    end
                    if #meleeHeroes > 0 then
                        _G.table.sort(meleeHeroes, function(a,b) return a.health + (a.totalDamage*2) + (a.attackSpeed*100) > b.health + (b.totalDamage*2) + (b.attackSpeed*100) end)
                        local meleeTarget = meleeHeroes[1]
                        if LocalCore:IsFacing(meleeTarget, myHero, 60) then
                            Control.CastSpell(HK_E, meleeTarget)
                            result = true
                        end
                    end
                end
                -- e antiMelee

                -- e antiDash
                if not result and MENU.eset.dash:Value() then
                    for i = 1, LocalGameHeroCount() do
                        local hero = LocalGameHero(i)
                        if LocalCore:IsValidTarget(hero) and hero.team == LocalCore.TEAM_ENEMY then
                            local path = hero.pathing
                            if path and path.isDashing and hero.posTo and myHero.pos:DistanceTo(hero.posTo) < 500 and LocalCore:IsFacing(hero, myHero, 75) then
                                local extpos = hero.pos:Extended(hero.posTo, path.dashSpeed * (0.07+_G.LATENCY))
                                if myHero.pos:DistanceTo(extpos) < 550 + myHero.boundingRadius + hero.boundingRadius then
                                    Control.CastSpell(HK_E, hero)
                                    result = true
                                    break
                                end
                            end
                        end
                    end
                end
                -- e antiDash

                -- e stun
                if not result and ((ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.eset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.eset.harass:Value())) then
                    local eRange = self.EData.range + myHero.boundingRadius
                    for i = 1, LocalGameHeroCount() do
                        local hero = LocalGameHero(i)
                        if LocalCore:IsValidTarget(hero) and hero.team == LocalCore.TEAM_ENEMY and myHero.pos:DistanceTo(hero.pos) < eRange + hero.boundingRadius and not OB:IsHeroImmortal(hero, false) then
                            if MENU.eset.useonstun[hero.charName] and MENU.eset.useonstun[hero.charName]:Value() and CheckWall(myHero.pos, hero.pos, 450) and CheckWall(myHero.pos, hero:GetPrediction(self.EData.delay+0.06+LATENCY,self.EData.speed), 450) then
                                result = Control.CastSpell(HK_E, hero)
                                break
                            end
                        end
                    end
                end
                -- e stun
            end
            -- e

            -- q
            if not result and SPELLS:IsReady(_Q, { q = 0.5, w = 0, e = 0.5, r = 0 } ) then

                -- Is Attacking
                local isAttacking = false
                if ORB:IsAutoAttacking() then
                    isAttacking = true
                end
                -- Can Attack
                local AATarget = TS:GetComboTarget()
                if AATarget and not ORB.IsNone and ORB:CanAttack() then
                    isAttacking = true
                end
                --Q
                if not isAttacking and ((ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.qset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.qset.harass:Value())) then
                    local mePos = myHero.pos
                    local extended = Vector(myHero.pos):Extended(Vector(_G.mousePos), 300)
                    local meRange = myHero.range + myHero.boundingRadius
                    for i = 1, LocalGameHeroCount() do
                        local hero = LocalGameHero(i)
                        if LocalCore:IsValidTarget(hero) and hero.team == LocalCore.TEAM_ENEMY and extended and Vector(extended):DistanceTo(hero.pos) < meRange + hero.boundingRadius - 35 and not OB:IsHeroImmortal(hero, true) then
                            result = Control.CastSpell(HK_Q)
                            break
                        end
                    end
                end

            end
            -- q

            return result
        end
        function CHAMPION:Interrupter()
            INTERRUPTER = LocalCore:__Interrupter()
            INTERRUPTER:OnInterrupt(function(enemy)
                if MENU.eset.interrupt:Value() and SPELLS:IsReady(_E, { q = 0.75, w = 0, e = 0.5, r = 0 } ) and enemy.pos:ToScreen().onScreen and myHero.pos:DistanceTo(enemy.pos) < 550 + myHero.boundingRadius + enemy.boundingRadius - 35 then
                    Control.CastSpell(HK_E, enemy)
                end
            end)
        end
        function CHAMPION:CanAttack()
            if not SPELLS:CheckSpellDelays({ q = 0.3, w = 0, e = 0.5, r = 0 }) then
                return false
            end
            return true
        end
        function CHAMPION:CanMove()
            if not SPELLS:CheckSpellDelays({ q = 0.2, w = 0, e = 0.4, r = 0 }) then
                return false
            end
            return true
        end
    end,
    Brand = function()
        local BrandVersion = "0.02 - fixed q casting, no bugs, faster combo"
        MENU = MenuElement({name = "Gamsteron Brand", id = "Gamsteron_Brand", type = _G.MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Icons/x1xxbrandx3xx.png" })
        -- Q
        MENU:MenuElement({name = "Q settings", id = "qset", type = _G.MENU })
            -- KS
            MENU.qset:MenuElement({name = "KS", id = "killsteal", type = _G.MENU })
                MENU.qset.killsteal:MenuElement({id = "enabled", name = "Enabled", value = true})
                MENU.qset.killsteal:MenuElement({id = "minhp", name = "minimum enemy hp", value = 200, min = 1, max = 300, step = 1})
                MENU.qset.killsteal:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = { "normal", "high" } })
            -- Auto
            MENU.qset:MenuElement({name = "Auto", id = "auto", type = _G.MENU })
                MENU.qset.auto:MenuElement({id = "stun", name = "Auto Stun", value = true})
                MENU.qset.auto:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = { "normal", "high" } })
            -- Combo / Harass
            MENU.qset:MenuElement({name = "Combo / Harass", id = "comhar", type = _G.MENU })
                MENU.qset.comhar:MenuElement({id = "combo", name = "Combo", value = true})
                MENU.qset.comhar:MenuElement({id = "harass", name = "Harass", value = false})
                MENU.qset.comhar:MenuElement({id = "stun", name = "Only if will stun", value = true})
                MENU.qset.comhar:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = { "normal", "high" } })
        -- W
        MENU:MenuElement({name = "W settings", id = "wset", type = _G.MENU })
            MENU.wset:MenuElement({id = "disaa", name = "Disable attack if ready or almostReady", value = true})
            -- KS
            MENU.wset:MenuElement({name = "KS", id = "killsteal", type = _G.MENU })
                MENU.wset.killsteal:MenuElement({id = "enabled", name = "Enabled", value = true})
                MENU.wset.killsteal:MenuElement({id = "minhp", name = "minimum enemy hp", value = 200, min = 1, max = 300, step = 1})
                MENU.wset.killsteal:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = { "normal", "high" } })
            -- Auto
            MENU.wset:MenuElement({name = "Auto", id = "auto", type = _G.MENU })
                MENU.wset.auto:MenuElement({id = "enabled", name = "Enabled", value = true})
                MENU.wset.auto:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = { "normal", "high" } })
            -- Combo / Harass
            MENU.wset:MenuElement({name = "Combo / Harass", id = "comhar", type = _G.MENU })
                MENU.wset.comhar:MenuElement({id = "combo", name = "Combo", value = true})
                MENU.wset.comhar:MenuElement({id = "harass", name = "Harass", value = false})
                MENU.wset.comhar:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = { "normal", "high" } })
        -- E
        MENU:MenuElement({name = "E settings", id = "eset", type = _G.MENU })
            MENU.eset:MenuElement({id = "disaa", name = "Disable attack if ready or almostReady", value = true})
            -- KS
            MENU.eset:MenuElement({name = "KS", id = "killsteal", type = _G.MENU })
                MENU.eset.killsteal:MenuElement({id = "enabled", name = "Enabled", value = true})
                MENU.eset.killsteal:MenuElement({id = "minhp", name = "minimum enemy hp", value = 100, min = 1, max = 300, step = 1})
            -- Auto
            MENU.eset:MenuElement({name = "Auto", id = "auto", type = _G.MENU })
                MENU.eset.auto:MenuElement({id = "stun", name = "If Q ready | no collision & W not ready $ mana for Q + E", value = true})
                MENU.eset.auto:MenuElement({id = "passive", name = "If Q not ready & W not ready $ enemy has passive buff", value = true})
            -- Combo / Harass
            MENU.eset:MenuElement({name = "Combo / Harass", id = "comhar", type = _G.MENU })
                MENU.eset.comhar:MenuElement({id = "combo", name = "Combo", value = true})
                MENU.eset.comhar:MenuElement({id = "harass", name = "Harass", value = false})
        --R
        MENU:MenuElement({name = "R settings", id = "rset", type = _G.MENU })
            -- Auto
            MENU.rset:MenuElement({name = "Auto", id = "auto", type = _G.MENU })
                MENU.rset.auto:MenuElement({id = "enabled", name = "Enabled", value = true})
                MENU.rset.auto:MenuElement({id = "xenemies", name = ">= X enemies near target", value = 2, min = 1, max = 4, step = 1})
                MENU.rset.auto:MenuElement({id = "xrange", name = "< X distance enemies to target", value = 300, min = 100, max = 600, step = 50})
            -- Combo / Harass
            MENU.rset:MenuElement({name = "Combo / Harass", id = "comhar", type = _G.MENU })
                MENU.rset.comhar:MenuElement({id = "combo", name = "Use R Combo", value = true})
                MENU.rset.comhar:MenuElement({id = "harass", name = "Use R Harass", value = false})
                MENU.rset.comhar:MenuElement({id = "xenemies", name = ">= X enemies near target", value = 1, min = 1, max = 4, step = 1})
                MENU.rset.comhar:MenuElement({id = "xrange", name = "< X distance enemies to target", value = 300, min = 100, max = 600, step = 50})
        -- Version
        MENU:MenuElement({name = "Version " .. tostring(BrandVersion), type = _G.SPACE, id = "verspace"})
        CHAMPION = LocalCore:Class()
        function CHAMPION:__init()
            self.ETarget = nil
            self.QData = { Delay = 0.25, Radius = 80, Range = 1050, Speed = 1550, Collision = true, Type = _G.SPELLTYPE_LINE }
            self.WData = { Delay = 0.625, Radius = 100, Range = 875, Speed = math.huge, Collision = false, Type = _G.SPELLTYPE_CIRCLE }
        end
        function CHAMPION:Tick()
            -- Is Attacking
            if ORB:IsAutoAttacking() then
                return
            end
            local result = false
            -- Q
            if SPELLS:IsReady(_Q, { q = 0.5, w = 0.53, e = 0.53, r = 0.33 } ) then
                -- KS
                if MENU.qset.killsteal.enabled:Value() then
                    local baseDmg = 50
                    local lvlDmg = 30 * myHero:GetSpellData(_Q).level
                    local apDmg = myHero.ap * 0.55
                    local qDmg = baseDmg + lvlDmg + apDmg
                    local minHP = MENU.qset.killsteal.minhp:Value()
                    if qDmg > minHP then
                        local enemyList = OB:GetEnemyHeroes(1050, false, 0)
                        for i = 1, #enemyList do
                            local qTarget = enemyList[i]
                            if qTarget.health > minHP and qTarget.health < DMG:CalculateDamage(myHero, qTarget, DAMAGE_TYPE_MAGICAL, qDmg) then
                                result = CastSpell(HK_Q, qTarget, self.QData, MENU.qset.killsteal.hitchance:Value() + 1)
                            end
                        end
                    end
                end if result then return end
                -- Combo Harass
                if (ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.qset.comhar.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.qset.comhar.harass:Value()) then
                    if LocalGameTimer() < SPELLS.LastEk + 1 and LocalGameTimer() > SPELLS.LastE + 0.33 and self.ETarget and not self.ETarget.dead and not IsGamsteronCollision(self.ETarget, self.QData.Radius, self.QData.Speed, self.QData.Delay) then
                        result = CastSpell(HK_Q, self.ETarget, self.QData, MENU.qset.comhar.hitchance:Value() + 1)
                        if result then return end
                    end
                    local blazeList = {}
                    local enemyList = OB:GetEnemyHeroes(1050, false, 0)
                    for i = 1, #enemyList do
                        local unit = enemyList[i]
                        if LocalCore:GetBuffDuration(unit, "brandablaze") > 0.5 and not IsGamsteronCollision(unit, self.QData.Radius, self.QData.Speed, self.QData.Delay) then
                            blazeList[#blazeList+1] = unit
                        end
                    end
                    result = CastSpell(HK_Q, TS:GetTarget(blazeList, 1), self.QData, MENU.qset.comhar.hitchance:Value() + 1)
                    if not result and not MENU.qset.comhar.stun:Value() and LocalGameTimer() > SPELLS.LastWk + 1.33 and LocalGameTimer() > SPELLS.LastEk + 0.77 and LocalGameTimer() > SPELLS.LastRk + 0.77 then
                        result = CastSpell(HK_Q, TS:GetTarget(OB:GetEnemyHeroes(1050, false, 0), 1), self.QData, MENU.qset.comhar.hitchance:Value() + 1)
                    end
                -- Auto
                elseif MENU.qset.auto.stun:Value() then
                    if LocalGameTimer() < SPELLS.LastEk + 1 and LocalGameTimer() > SPELLS.LastE + 0.33 and self.ETarget and not self.ETarget.dead and not IsGamsteronCollision(self.ETarget, self.QData.Radius, self.QData.Speed, self.QData.Delay) then
                        result = CastSpell(HK_Q, self.ETarget, self.QData, MENU.qset.auto.hitchance:Value() + 1)
                        if result then return end
                    end
                    local blazeList = {}
                    local enemyList = OB:GetEnemyHeroes(1050, false, 0)
                    for i = 1, #enemyList do
                        local unit = enemyList[i]
                        if LocalCore:GetBuffDuration(unit, "brandablaze") > 0.5 and not IsGamsteronCollision(unit, self.QData.Radius, self.QData.Speed, self.QData.Delay) then
                            blazeList[#blazeList+1] = unit
                        end
                    end
                    result = CastSpell(HK_Q, TS:GetTarget(blazeList, 1), self.QData, MENU.qset.auto.hitchance:Value() + 1)
                end
            end if result then return end
            -- E
            if SPELLS:IsReady(_E, { q = 0.33, w = 0.53, e = 0.5, r = 0.33 } ) then
                -- antigap
                local enemyList = OB:GetEnemyHeroes(635, false, 0)
                for i = 1, #enemyList do
                    local unit = enemyList[i]
                    if LocalCore:GetDistanceSquared(myHero.pos, unit.pos) < 300 * 300 then
                        result = Control.CastSpell(HK_E, unit)
                    end
                end if result then return end
                -- KS
                if MENU.eset.killsteal.enabled:Value() then
                    local baseDmg = 50
                    local lvlDmg = 20 * myHero:GetSpellData(_E).level
                    local apDmg = myHero.ap * 0.35
                    local eDmg = baseDmg + lvlDmg + apDmg
                    local minHP = MENU.eset.killsteal.minhp:Value()
                    if eDmg > minHP then
                        for i = 1, #enemyList do
                            local unit = enemyList[i]
                            if unit.health > minHP and unit.health < DMG:CalculateDamage(myHero, unit, DAMAGE_TYPE_MAGICAL, eDmg) then
                                result = Control.CastSpell(HK_E, unit)
                                if result then break end
                            end
                        end
                    end
                end if result then return end
                -- Combo / Harass
                if (ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.eset.comhar.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.eset.comhar.harass:Value()) then
                    local blazeList = {}
                    for i = 1, #enemyList do
                        local unit = enemyList[i]
                        if LocalCore:GetBuffDuration(unit, "brandablaze") > 0.33 then
                            blazeList[#blazeList+1] = unit
                        end
                    end
                    local eTarget = TS:GetTarget(blazeList, 1)
                    if eTarget then
                        result = Control.CastSpell(HK_E, eTarget)
                        self.ETarget = eTarget
                    end if result then return end
                    if LocalGameTimer() > SPELLS.LastQk + 0.77 and LocalGameTimer() > SPELLS.LastWk + 1.33 and LocalGameTimer() > SPELLS.LastRk + 0.77 then
                        eTarget = TS:GetTarget(enemyList, 1)
                        if eTarget then
                            result = Control.CastSpell(HK_E, eTarget)
                            self.ETarget = eTarget
                        end
                    end
                -- Auto
                elseif myHero:GetSpellData(_Q).level > 0 and myHero:GetSpellData(_W).level > 0 then
                    -- EQ -> if Q ready | no collision & W not ready $ mana for Q + E
                    if MENU.eset.auto.stun:Value() and myHero.mana > myHero:GetSpellData(_Q).mana + myHero:GetSpellData(_E).mana then
                        if (LocalGameCanUseSpell(_Q) == 0 or myHero:GetSpellData(_Q).currentCd < 0.75) and not(LocalGameCanUseSpell(_W) == 0 or myHero:GetSpellData(_W).currentCd < 0.75) then
                            local blazeList = {}
                            local enemyList = OB:GetEnemyHeroes(635, false, 0)
                            for i = 1, #enemyList do
                                local unit = enemyList[i]
                                if LocalCore:GetBuffDuration(unit, "brandablaze") > 0.33 then
                                    blazeList[#blazeList+1] = unit
                                end
                            end
                            local eTarget = TS:GetTarget(blazeList, 1)
                            if eTarget and not IsGamsteronCollision(eTarget, self.QData.Radius, self.QData.Speed, self.QData.Delay) then
                                result = Control.CastSpell(HK_E, eTarget)
                            end if result then return end
                            if LocalGameTimer() > SPELLS.LastQk + 0.77 and LocalGameTimer() > SPELLS.LastWk + 1.33 and LocalGameTimer() > SPELLS.LastRk + 0.77 then
                                eTarget = TS:GetTarget(enemyList, 1)
                                if eTarget and not IsGamsteronCollision(eTarget, self.QData.Radius, self.QData.Speed, self.QData.Delay) then
                                    result = Control.CastSpell(HK_E, eTarget)
                                    self.ETarget = eTarget
                                end
                            end
                        end
                    end
                    -- Passive -> If Q not ready & W not ready $ enemy has passive buff
                    if MENU.eset.auto.passive:Value() and not(LocalGameCanUseSpell(_Q) == 0 or myHero:GetSpellData(_Q).currentCd < 0.75) and not(LocalGameCanUseSpell(_W) == 0 or myHero:GetSpellData(_W).currentCd < 0.75) then
                        local blazeList = {}
                        local enemyList = OB:GetEnemyHeroes(670, false, 0)
                        for i = 1, #enemyList do
                            local unit = enemyList[i]
                            if LocalCore:GetBuffDuration(unit, "brandablaze") > 0.33 then
                                blazeList[#blazeList+1] = unit
                            end
                        end
                        local eTarget = TS:GetTarget(blazeList, 1)
                        if eTarget then
                            result = Control.CastSpell(HK_E, eTarget)
                            self.ETarget = eTarget
                        end
                    end
                end
            end if result then return end
            -- W
            if SPELLS:IsReady(_W, { q = 0.33, w = 0.5, e = 0.33, r = 0.33 } ) then
                -- KS
                if MENU.wset.killsteal.enabled:Value() then
                    local baseDmg = 30
                    local lvlDmg = 45 * myHero:GetSpellData(_W).level
                    local apDmg = myHero.ap * 0.6
                    local wDmg = baseDmg + lvlDmg + apDmg
                    local minHP = MENU.wset.killsteal.minhp:Value()
                    if wDmg > minHP then
                        local enemyList = OB:GetEnemyHeroes(950, false, 0)
                        for i = 1, #enemyList do
                            local wTarget = enemyList[i]
                            if wTarget.health > minHP and wTarget.health < DMG:CalculateDamage(myHero, wTarget, DAMAGE_TYPE_MAGICAL, wDmg) then
                                result = CastSpell(HK_W, wTarget, self.WData, MENU.wset.killsteal.hitchance:Value() + 1)
                                if result then break end
                            end
                        end
                    end
                end if result then return end
                -- Combo / Harass
                if (ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.wset.comhar.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.wset.comhar.harass:Value()) then
                    local blazeList = {}
                    local enemyList = OB:GetEnemyHeroes(950, false, 0)
                    for i = 1, #enemyList do
                        local unit = enemyList[i]
                        if LocalCore:GetBuffDuration(unit, "brandablaze") > 1.33 then
                            blazeList[#blazeList+1] = unit
                        end
                    end
                    result = CastSpell(HK_W, TS:GetTarget(blazeList, 1), self.WData, MENU.wset.comhar.hitchance:Value() + 1)
                    if not result and LocalGameTimer() > SPELLS.LastQk + 0.77 and LocalGameTimer() > SPELLS.LastEk + 0.77 and LocalGameTimer() > SPELLS.LastRk + 0.77 then
                        result = CastSpell(HK_W, TS:GetTarget(enemyList, 1), self.WData, MENU.wset.comhar.hitchance:Value() + 1)
                    end
                -- Auto
                elseif MENU.wset.auto.enabled:Value() then
                    for i = 1, 3 do
                        local blazeList = {}
                        local enemyList = OB:GetEnemyHeroes(1200 - (i * 100), false, 0)
                        for j = 1, #enemyList do
                            local unit = enemyList[j]
                            if LocalCore:GetBuffDuration(unit, "brandablaze") > 1.33 then
                                blazeList[#blazeList+1] = unit
                            end
                        end
                        result = CastSpell(HK_W, TS:GetTarget(blazeList, 1), self.WData, MENU.wset.auto.hitchance:Value() + 1)
                        if not result and LocalGameTimer() > SPELLS.LastQk + 0.77 and LocalGameTimer() > SPELLS.LastEk + 0.77 and LocalGameTimer() > SPELLS.LastRk + 0.77 then
                            result = CastSpell(HK_W, TS:GetTarget(enemyList, 1), self.WData, MENU.wset.auto.hitchance:Value() + 1)
                        end
                    end
                end
            end if result then return end
            -- R
            if SPELLS:IsReady(_R, { q = 0.33, w = 0.33, e = 0.33, r = 0.5 } ) then
                -- Combo / Harass
                if (ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.rset.comhar.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.rset.comhar.harass:Value()) then
                    local enemyList = OB:GetEnemyHeroes(750, false, 0)
                    local xRange = MENU.rset.comhar.xrange:Value()
                    local xEnemies = MENU.rset.comhar.xenemies:Value()
                    for i = 1, #enemyList do
                        local count = 0
                        local rTarget = enemyList[i]
                        for j = 1, #enemyList do
                            local unit = enemyList[j]
                            if rTarget ~= unit and rTarget.pos:DistanceTo(unit.pos) < xRange then
                                count = count + 1
                            end
                        end
                        if count >= xEnemies then
                            result = Control.CastSpell(HK_R, rTarget)
                            if result then break end
                        end
                    end
                -- Auto
                elseif MENU.rset.auto.enabled:Value() then
                    local enemyList = OB:GetEnemyHeroes(750, false, 0)
                    local xRange = MENU.rset.auto.xrange:Value()
                    local xEnemies = MENU.rset.auto.xenemies:Value()
                    for i = 1, #enemyList do
                        local count = 0
                        local rTarget = enemyList[i]
                        for j = 1, #enemyList do
                            local unit = enemyList[j]
                            if rTarget ~= unit and rTarget.pos:DistanceTo(unit.pos) < xRange then
                                count = count + 1
                            end
                        end
                        if count >= xEnemies then
                            result = Control.CastSpell(HK_R, rTarget)
                            if result then break end
                        end
                    end
                end
            end
        end
        function CHAMPION:CanMove()
            if not SPELLS:CheckSpellDelays({ q = 0.2, w = 0.2, e = 0.2, r = 0.2 }) then
                return false
            end
            return true
        end
        function CHAMPION:CanAttack()
            if not SPELLS:CheckSpellDelays({ q = 0.33, w = 0.33, e = 0.33, r = 0.33 }) then
                return false
            end
            -- LastHit, LaneClear
            if not ORB.Modes[ORBWALKER_MODE_COMBO] and not ORB.Modes[ORBWALKER_MODE_HARASS] then
                return true
            end
            -- W
            if MENU.wset.disaa:Value() and myHero:GetSpellData(_W).level > 0 and myHero.mana > myHero:GetSpellData(_W).mana and ( LocalGameCanUseSpell(_W) == 0 or myHero:GetSpellData(_W).currentCd < 1 ) then
                return false
            end
            -- E
            if MENU.eset.disaa:Value() and myHero:GetSpellData(_E).level > 0 and myHero.mana > myHero:GetSpellData(_E).mana and ( LocalGameCanUseSpell(_E) == 0 or myHero:GetSpellData(_E).currentCd < 1 ) then
                return false
            end
            return true
        end
    end,
    Ezreal = function()
        local EzrealVersion = "0.02 - smoother and faster E usage"
        MENU = MenuElement({name = "Gamsteron Ezreal", id = "Gamsteron_Ezreal", type = _G.MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Icons/ezreal.png" })
        -- E Manual
        MENU:MenuElement({name = "Manual E", id = "mane", type = _G.MENU })
            MENU.mane:MenuElement({id = "efake", name = "E Fake Key", value = false, key = string.byte("E")})
            MENU.mane:MenuElement({id = "elol", name = "E LoL Key", value = false, key = string.byte("L")})
        -- Auto Q
        MENU:MenuElement({name = "Auto Q", id = "autoq", type = _G.MENU })
            MENU.autoq:MenuElement({id = "enable", name = "Enable", value = true, key = string.byte("T"), toggle = true})
            MENU.autoq:MenuElement({id = "mana", name = "Q Auto min. mana percent", value = 50, min = 0, max = 100, step = 1 })
            MENU.autoq:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = { "normal", "high" } })
        -- Q
        MENU:MenuElement({name = "Q settings", id = "qset", type = _G.MENU })
            MENU.qset:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = { "normal", "high" } })
            MENU.qset:MenuElement({id = "combo", name = "Combo", value = true})
            MENU.qset:MenuElement({id = "harass", name = "Harass", value = false})
            MENU.qset:MenuElement({id = "clearm", name = "LaneClear/LastHit", type = _G.MENU })
                MENU.qset.clearm:MenuElement({id = "lhenabled", name = "LastHit Enabled", value = true})
                MENU.qset.clearm:MenuElement({id = "lhmana", name = "LastHit Min. Mana %", value = 50, min = 0, max = 100, step = 5 })
                MENU.qset.clearm:MenuElement({id = "lcenabled", name = "LaneClear Enabled", value = false})
                MENU.qset.clearm:MenuElement({id = "lcmana", name = "LaneClear Min. Mana %", value = 75, min = 0, max = 100, step = 5 })
        -- W
        MENU:MenuElement({name = "W settings", id = "wset", type = _G.MENU })
            MENU.wset:MenuElement({id = "hitchance", name = "Hitchance", value = 1, drop = { "normal", "high" } })
            MENU.wset:MenuElement({id = "combo", name = "Combo", value = true})
            MENU.wset:MenuElement({id = "harass", name = "Harass", value = false})
        -- Drawings
        MENU:MenuElement({name = "Drawings", id = "draws", type = _G.MENU })
            MENU.draws:MenuElement({name = "Auto Q", id = "autoq", type = _G.MENU })
                MENU.draws.autoq:MenuElement({id = "enabled", name = "Enabled", value = true})
                MENU.draws.autoq:MenuElement({id = "size", name = "Text Size", value = 25, min = 1, max = 64, step = 1 })
                MENU.draws.autoq:MenuElement({id = "custom", name = "Custom Position", value = false})
                MENU.draws.autoq:MenuElement({id = "posX", name = "Text Position Width", value = Game.Resolution().x * 0.5 - 150, min = 1, max = Game.Resolution().x, step = 1 })
                MENU.draws.autoq:MenuElement({id = "posY", name = "Text Position Height", value = Game.Resolution().y * 0.5, min = 1, max = Game.Resolution().y, step = 1 })
            MENU.draws:MenuElement({name = "Q Farm", id = "qfarm", type = _G.MENU })
                MENU.draws.qfarm:MenuElement({name = "LastHitable Minion",  id = "lasthit", type = MENU})
                    MENU.draws.qfarm.lasthit:MenuElement({name = "Enabled",  id = "enabled", value = true})
                    MENU.draws.qfarm.lasthit:MenuElement({name = "Color",  id = "color", color = LocalDrawColor(150, 255, 255, 255)})
                    MENU.draws.qfarm.lasthit:MenuElement({name = "Width",  id = "width", value = 3, min = 1, max = 10})
                    MENU.draws.qfarm.lasthit:MenuElement({name = "Radius",  id = "radius", value = 50, min = 1, max = 100})
                MENU.draws.qfarm:MenuElement({name = "Almost LastHitable Minion",  id = "almostlasthit", type = MENU})
                    MENU.draws.qfarm.almostlasthit:MenuElement({name = "Enabled",  id = "enabled", value = true})
                    MENU.draws.qfarm.almostlasthit:MenuElement({name = "Color",  id = "color", color = LocalDrawColor(150, 239, 159, 55)})
                    MENU.draws.qfarm.almostlasthit:MenuElement({name = "Width",  id = "width", value = 3, min = 1, max = 10})
                    MENU.draws.qfarm.almostlasthit:MenuElement({name = "Radius",  id = "radius", value = 50, min = 1, max = 100})
        -- Version
        MENU:MenuElement({name = "Version " .. tostring(EzrealVersion), type = _G.SPACE, id = "verspace"})
        CHAMPION = LocalCore:Class()
        function CHAMPION:__init()
            self.QData = { Delay = 0.25, Radius = 60, Range = 1150, Speed = 2000, Collision = true, Type = _G.SPELLTYPE_LINE }
            self.WData = { Delay = 0.25, Radius = 60, Range = 1150, Speed = 2000, Collision = false, Type = _G.SPELLTYPE_LINE }
            self.QFarm = nil
            self.LastEFake = 0
        end
        function CHAMPION:Farm()
            -- [ mana percent ]
            local manaPercent = 100 * myHero.mana / myHero.maxMana

            -- [ q farm ]
            if MENU.qset.clearm.lhenabled:Value() or MENU.qset.clearm.lcenabled:Value() then
                if manaPercent > MENU.qset.clearm.lhmana:Value() then
                    self.QFarm:Tick()
                end
            end
        end
        function CHAMPION:WndMsg(msg, wParam)
            if wParam == MENU.mane.efake:Key() then
                self.LastEFake = os.clock()
            end
        end
        function CHAMPION:Tick()
            
            -- [ e manual ]
            if os.clock() < self.LastEFake + 0.5 and SPELLS:IsReady(_E, { q = 0.33, w = 0.33, e = 0.2, r = 0.77 } ) then
                local key = MENU.mane.elol:Key()
                LocalControlKeyDown(key)
				LocalControlKeyUp(key)
				LocalControlKeyDown(key)
				LocalControlKeyUp(key)
				LocalControlKeyDown(key)
				LocalControlKeyUp(key)
                _G.ORB_NEXT_CONTROLL = LocalGameTimer() + 0.25
            end

            -- [ is attacking ]
            if ORB:IsAutoAttacking() then
                return
            end

            -- [ get attack target ]
            local AATarget = TS:GetComboTarget()

            -- [ can attack ]
            if AATarget and not ORB.IsNone and ORB:CanAttack() then
                return
            end
            
            local result = false

            -- [ mana percent ]
            local manaPercent = 100 * myHero.mana / myHero.maxMana

            -- [ use q ]
            if SPELLS:IsReady(_Q, { q = 0.5, w = 0.33, e = 0.33, r = 1.13 } ) then

                -- [ combo / harass ]
                if (ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.qset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.qset.harass:Value()) then
                    local QTarget
                    if AATarget then
                        QTarget = AATarget
                    else
                        QTarget = TS:GetTarget(OB:GetEnemyHeroes(1150, false, 0), 0)
                    end
                    result = CastSpell(HK_Q, QTarget, self.QData, MENU.qset.hitchance:Value() + 1)
                -- [ auto ]
                elseif MENU.autoq.enable:Value() and manaPercent > MENU.autoq.mana:Value() then
                    local enemyHeroes = OB:GetEnemyHeroes(1150, false, 0)
                    for i = 1, #enemyHeroes do
                        result = CastSpell(HK_Q, enemyHeroes[i], self.QData, MENU.autoq.hitchance:Value() + 1)
                        if result then break end
                    end
                end

                -- [ cast q clear ]
                if not result and MENU.qset.clearm.lhenabled:Value() and not ORB.IsNone and not ORB.Modes[ORBWALKER_MODE_COMBO] and manaPercent > MENU.qset.clearm.lhmana:Value() then
                    -- [ last hit ]
                    local lhtargets = self.QFarm:GetLastHitTargets()
                    for i = 1, #lhtargets do
                        local unit = lhtargets[i]
                        if unit.alive and unit:GetCollision(self.QData.Radius + 35, self.QData.Speed, self.QData.Delay) == 1 then
                            result = Control.CastSpell(HK_Q, unit:GetPrediction(self.QData.Speed, self.QData.Delay))
                            if result then
                                ORB:SetAttack(false)
                                DelayAction(function() ORB:SetAttack(true) end, self.QData.Delay + (unit.pos:DistanceTo(myHero.pos) / self.QData.Speed) + 0.05)
                                break
                            end
                        end
                    end
                end
                if not result and MENU.qset.clearm.lcenabled:Value() and ORB.Modes[ORBWALKER_MODE_LANECLEAR] and not self.QFarm:ShouldWait() and manaPercent > MENU.qset.clearm.lcmana:Value() then
                    -- [ enemy heroes ]
                    local enemyHeroes = OB:GetEnemyHeroes(self.Range, false, "spell")
                    for i = 1, #enemyHeroes do
                        result = CastSpell(HK_Q, enemyHeroes[i], self.QData, MENU.qset.hitchance:Value() + 1)
                        if result then break end
                    end if result then return end
                    -- [ lane clear ]
                    local lctargets = self.QFarm:GetLaneClearTargets()
                    for i = 1, #lctargets do
                        local unit = lctargets[i]
                        if unit.alive and unit:GetCollision(self.QData.Radius + 35, self.QData.Speed, self.QData.Delay) == 1 then
                            result = Control.CastSpell(HK_Q, unit:GetPrediction(self.QData.Speed, self.QData.Delay))
                            if result then break end
                        end
                    end
                end
            end

            -- [ use w ]
            if not result and SPELLS:IsReady(_W, { q = 0.33, w = 0.5, e = 0.33, r = 1.13 } ) then
                if (ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.wset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.wset.harass:Value()) then
                    local WTarget
                    if AATarget then
                        WTarget = AATarget
                    else
                        WTarget = TS:GetTarget(OB:GetEnemyHeroes(1000, false, 0), 0)
                    end
                    CastSpell(HK_W, WTarget, self.WData, MENU.wset.hitchance:Value() + 1)
                end
            end
        end
        function CHAMPION:Draw()
            if MENU.draws.autoq.enabled:Value() then
                local mePos = myHero.pos:To2D()
                local isCustom = MENU.draws.autoq.custom:Value()
                local posX, posY
                if isCustom then
                    posX = MENU.draws.autoq.posX:Value()
                    posY = MENU.draws.autoq.posY:Value()
                else
                    posX = mePos.x - 50
                    posY = mePos.y
                end
                if MENU.autoq.enable:Value() then
                    LocalDrawText("Auto Q Enabled", MENU.draws.autoq.size:Value(), posX, posY, LocalDrawColor(255, 000, 255, 000))
                else
                    LocalDrawText("Auto Q Disabled", MENU.draws.autoq.size:Value(), posX, posY, LocalDrawColor(255, 255, 000, 000))
                end
            end
            -- [ q farm ]
            local lhmenu = MENU.draws.qfarm.lasthit
            local lcmenu = MENU.draws.qfarm.almostlasthit
            if lhmenu.enabled:Value() or lcmenu.enabled:Value() then
                local fm = self.QFarm.FarmMinions
                for i = 1, #fm do
                    local minion = fm[i]
                    if minion.LastHitable and lhmenu.enabled:Value() then
                        LocalDrawCircle(minion.Minion.pos,lhmenu.radius:Value(),lhmenu.width:Value(),lhmenu.color:Value())
                    elseif minion.AlmostLastHitable and lcmenu.enabled:Value() then
                        LocalDrawCircle(minion.Minion.pos,lcmenu.radius:Value(),lcmenu.width:Value(),lcmenu.color:Value())
                    end
                end
            end
        end
        function CHAMPION:QClear()
            self.QFarm = SPELLS:SpellClear(_Q, self.QData, function() return ((25 * myHero:GetSpellData(_Q).level) - 10) + (1.1 * myHero.totalDamage) + (0.4 * myHero.ap) end)
        end
        function CHAMPION:CanAttack()
            if not SPELLS:CheckSpellDelays({ q = 0.33, w = 0.33, e = 0.33, r = 1.13 }) then
                return false
            end
            return true
        end
        function CHAMPION:CanMove()
            if not SPELLS:CheckSpellDelays({ q = 0.2, w = 0.2, e = 0.2, r = 1 }) then
                return false
            end
            return true
        end
    end,
    Varus = function()
        local VarusVersion = "0.02 - fixed Q, added dist check to predPos"
        MENU = MenuElement({name = "Gamsteron Varus", id = "Gamsteron_Varus", type = _G.MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GOS-External/master/Icons/gsovarussf3f.png" })
        -- Q
        MENU:MenuElement({name = "Q settings", id = "qset", type = _G.MENU })
            MENU.qset:MenuElement({id = "combo", name = "Combo", value = true})
            MENU.qset:MenuElement({id = "harass", name = "Harass", value = false})
            MENU.qset:MenuElement({id = "stacks", name = "If enemy has 3 W stacks [ W passive ]", value = true})
            MENU.qset:MenuElement({id = "active", name = "If varus has W buff [ W active ]", value = true})
            MENU.qset:MenuElement({id = "range", name = "No enemies in AA range", value = true})
            MENU.qset:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = { "normal", "high" } })
        -- W
        MENU:MenuElement({name = "W settings", id = "wset", type = _G.MENU })
            MENU.wset:MenuElement({id = "combo", name = "Combo", value = true})
            MENU.wset:MenuElement({id = "harass", name = "Harass", value = false})
            MENU.wset:MenuElement({id = "whp", name = "min. hp %", value = 50, min = 1, max = 100, step = 1})
        -- E
        MENU:MenuElement({name = "E settings", id = "eset", type = _G.MENU })
            MENU.eset:MenuElement({id = "combo", name = "Combo", value = true})
            MENU.eset:MenuElement({id = "harass", name = "Harass", value = false})
            MENU.eset:MenuElement({id = "range", name = "No enemies in AA range", value = true})
            MENU.eset:MenuElement({id = "stacks", name = "If enemy has 3 W stacks [ W passive ]", value = false})
            MENU.eset:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = { "normal", "high" } })
        -- R
        MENU:MenuElement({name = "R settings", id = "rset", type = _G.MENU })
            MENU.rset:MenuElement({id = "combo", name = "Use R Combo", value = true})
            MENU.rset:MenuElement({id = "harass", name = "Use R Harass", value = false})
            MENU.rset:MenuElement({id = "rci", name = "Use R if enemy isImmobile", value = true})
            MENU.rset:MenuElement({id = "rcd", name = "Use R if enemy distance < X", value = true})
            MENU.rset:MenuElement({id = "rdist", name = "use R if enemy distance < X", value = 500, min = 250, max = 1000, step = 50})
            MENU.rset:MenuElement({id = "hitchance", name = "Hitchance", value = 2, drop = { "normal", "high" } })
        -- Version
        MENU:MenuElement({name = "Version " .. tostring(VarusVersion), type = _G.SPACE, id = "verspace"})
        CHAMPION = LocalCore:Class()
        function CHAMPION:__init()
            self.HasQBuff = false
            self.QStartTime = 0
            self.QData = { Delay = 0.1, Radius = 70, Range = 1650, Speed = 1900, Collision = false, Type = _G.SPELLTYPE_LINE }
            self.EData = { Delay = 0.5, Radius = 235, Range = 925, Speed = 1500, Collision = false, Type = _G.SPELLTYPE_CIRCLE }
            self.RData = { Delay = 0.25, Radius = 120, Range = 1075, Speed = 1950, Collision = false, Type = _G.SPELLTYPE_LINE }
        end
        function CHAMPION:WndMsg(msg, wParam)
            if wParam == HK_Q then
                self.QStartTime = os.clock()
            end
        end
        function CHAMPION:Tick()
            -- Check Q Buff
            self.HasQBuff = LocalCore:HasBuff(myHero, "varusq")
            -- Is Attacking
            if not self.HasQBuff and ORB:IsAutoAttacking() then
                return
            end
            -- Can Attack
            local AATarget = TS:GetComboTarget()
            if not self.HasQBuff and AATarget and not ORB.IsNone and ORB:CanAttack() then
                return
            end
            local result = false
            -- Get Enemies
            local enemyList = OB:GetEnemyHeroes(math.huge, false, 0)
            --R
            if ((ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.rset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.rset.harass:Value())) and SPELLS:IsReady(_R, { q = 0.33, w = 0, e = 0.63, r = 0.5 } ) then
                if MENU.rset.rcd:Value() then
                    result = CastSpell(HK_R, LocalCore:GetClosestEnemy(enemyList, MENU.rset.rdist:Value()), self.RData, MENU.rset.hitchance:Value() + 1)
                end
                if not result and MENU.rset.rci:Value() then
                    local t = LocalCore:GetImmobileEnemy(enemyList, 900)
                    if t and myHero.pos:DistanceTo(t.pos) < self.RData.range then
                        result = Control.CastSpell(HK_R, t)
                    end
                end
            end if result then return end
            --E
            if ((ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.eset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.eset.harass:Value())) and SPELLS:IsReady(_E, { q = 0.33, w = 0, e = 0.63, r = 0.33 } ) then
                local aaRange = MENU.eset.range:Value() and not AATarget
                local onlyStacksE = MENU.eset.stacks:Value()
                local eTargets = {}
                for i = 1, #enemyList do
                    local hero = enemyList[i]
                    if myHero.pos:DistanceTo(hero.pos) < 925 and (LocalCore:GetBuffCount(hero, "varuswdebuff") == 3 or not onlyStacksE or myHero:GetSpellData(_W).level == 0 or aaRange) then
                        eTargets[#eTargets+1] = hero
                    end
                end
                result = CastSpell(HK_E, TS:GetTarget(eTargets, 0), self.EData, MENU.eset.hitchance:Value() + 1)
            end if result then return end
            -- Q
            if (ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.qset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.qset.harass:Value()) then
                local aaRange = MENU.qset.range:Value() and not AATarget
                local wActive = MENU.qset.active:Value() and LocalGameTimer() < SPELLS.LastWk + 3
                -- Q1
                if not self.HasQBuff and SPELLS:IsReady(_Q, { q = 0.5, w = 0.1, e = 1, r = 0.33 } ) then
                    if LocalControlIsKeyDown(HK_Q) then
                        LocalControlKeyUp(HK_Q)
                    end
                    -- W
                    if ((ORB.Modes[ORBWALKER_MODE_COMBO] and MENU.wset.combo:Value()) or (ORB.Modes[ORBWALKER_MODE_HARASS] and MENU.wset.harass:Value())) and SPELLS:IsReady(_W, { q = 0.33, w = 0.5, e = 0.63, r = 0.33 } ) then
                        local whp = MENU.wset.whp:Value()
                        for i = 1, #enemyList do
                            local hero = enemyList[i]
                            local hp = 100 * ( hero.health / hero.maxHealth )
                            if hp < whp and myHero.pos:DistanceTo(hero.pos) < 1500 then
                                result = Control.CastSpell(HK_W)
                                if result then break end
                            end
                        end
                    end if result then return end
                    local onlyStacksQ = MENU.qset.stacks:Value()
                    for i = 1, #enemyList do
                        local hero = enemyList[i]
                        if myHero.pos:DistanceTo(hero.pos) < 1500 and (LocalCore:GetBuffCount(hero, "varuswdebuff") == 3 or not onlyStacksQ or myHero:GetSpellData(_W).level == 0 or wActive or aaRange) then
                            LocalControlKeyDown(HK_Q)
                            SPELLS.LastQ = LocalGameTimer()
                            result = true
                            break
                        end
                    end
                -- Q2
                elseif self.HasQBuff and SPELLS:IsReady(_Q, { q = 0.2, w = 0, e = 0.63, r = 0.33 } ) then
                    local qTargets = {}
                    local onlyStacksQ = MENU.qset.stacks:Value()
                    local qTimer = os.clock() - self.QStartTime
                    local qExtraRange
                    if qTimer < 2 then
                        qExtraRange = qTimer * 0.5 * 700
                    else
                        qExtraRange = 700
                    end
                    for i = 1, #enemyList do
                        local hero = enemyList[i]
                        if myHero.pos:DistanceTo(hero.pos) < 925 + qExtraRange and (LocalCore:GetBuffCount(hero, "varuswdebuff") == 3 or not onlyStacksQ or myHero:GetSpellData(_W).level == 0 or wActive or aaRange) then
                            table.insert(qTargets, hero)
                        end
                    end
                    local qt = TS:GetTarget(qTargets, 0)
                    if LocalCore:IsValidTarget(qt) then
                        local Pred = GetGamsteronPrediction(qt, self.QData, myHero.pos)
                        if Pred.Hitchance >= MENU.qset.hitchance:Value() + 1 and LocalCore:IsInRange(Pred.CastPosition, myHero.pos, 925 + qExtraRange) and LocalCore:IsInRange(Pred.UnitPosition, myHero.pos, 925 + qExtraRange) then
                            LocalCore:CastSpell(HK_Q, nil, Pred.CastPosition)
                        end
                    end
                end
            end
        end
        function CHAMPION:CanAttack()
            self.HasQBuff = LocalCore:HasBuff(myHero, "varusq")
            if not SPELLS:CheckSpellDelays({ q = 0.33, w = 0, e = 0.33, r = 0.33 }) then
                return false
            end
            if self.HasQBuff == true then
                return false
            end
            return true
        end
        function CHAMPION:CanMove()
            if not SPELLS:CheckSpellDelays({ q = 0.2, w = 0, e = 0.2, r = 0.2 }) then
                return false
            end
            return true
        end
    end
}

AIO[LocalCharName]()

AddLoadCallback(function()
    ORB, TS, OB, DMG, SPELLS = _G.SDK.Orbwalker, _G.SDK.TargetSelector, _G.SDK.ObjectManager, _G.SDK.Damage, _G.SDK.Spells
    CHAMPION = CHAMPION()
    if CHAMPION.Interrupter then
        CHAMPION:Interrupter()
    end
    if CHAMPION.CanAttack then
        ORB:CanAttackEvent(function() return CHAMPION:CanAttack() end)
    end
    if CHAMPION.CanMove then
        ORB:CanMoveEvent(function() return CHAMPION:CanMove() end)
    end
    if CHAMPION.PreAttack then
        ORB:OnPreAttack(function(args) CHAMPION:PreAttack(args) end)
    end
    if CHAMPION.QClear then
        CHAMPION:QClear()
    end
    if CHAMPION.WClear then
        CHAMPION:WClear()
    end
    if CHAMPION.EClear then
        CHAMPION:EClear()
    end
    if CHAMPION.RClear then
        CHAMPION:RClear()
    end
    if CHAMPION.Farm then
        Callback.Add("Tick", function()
            if _G.GamsteronDebug then
                local status, err = pcall(function () CHAMPION:Farm() end) if not status then print("CHAMPION.Farm " .. tostring(err)) end
            else
                CHAMPION:Farm()
            end
        end)
    end
    if CHAMPION.Tick then
        Callback.Add("Draw", function()
            if _G.GamsteronDebug then
                local status, err = pcall(function () CHAMPION:Tick() end) if not status then print("CHAMPION.Tick " .. tostring(err)) end
            else
                CHAMPION:Tick()
            end
        end)
    end
    if CHAMPION.Draw then
        Callback.Add('Draw', function()
            if _G.GamsteronDebug then
                local status, err = pcall(function () CHAMPION:Draw() end) if not status then print("CHAMPION.Draw " .. tostring(err)) end
            else
                CHAMPION:Draw()
            end
        end)
    end
    if CHAMPION.WndMsg then
        Callback.Add('WndMsg', function(msg, wParam)
            if _G.GamsteronDebug then
                local status, err = pcall(function() CHAMPION:WndMsg(msg, wParam) end) if not status then print("CHAMPION.WndMsg " .. tostring(err)) end
            else
                CHAMPION:WndMsg(msg, wParam)
            end
        end)
    end
end)
