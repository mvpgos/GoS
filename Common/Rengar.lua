require("OpenPredict")
local ver = "1.3"

function AutoUpdate(data)
    if tonumber(data) > tonumber(ver) then
        PrintChat("New version found! " .. data)
        PrintChat("Downloading update, please wait...")
        DownloadFileAsync("https://raw.githubusercontent.com/Cloudhax23/GoS/master/Common/Rengar.lua", SCRIPT_PATH .. "Rengar.lua", function() PrintChat("<font color=\"#0fa2cd\"><b>[Rengar OnS]:</b></font><font color=\"#FFFFFF\"> Update Complete, please 2x F6!</font>") return end)
    else
       PrintChat("<font color=\"#0fa2cd\"><b>[Rengar OnS]:</b></font><font color=\"#FFFFFF\"> No Updates Found!</font>")
    end
end

GetWebResultAsync("https://raw.githubusercontent.com/Cloudhax23/GoS/master/Common/Rengar.version", AutoUpdate)
--[[
 ▄████████    ▄████████ ███▄▄▄▄      ▄██████▄     ▄████████    ▄████████ 
  ███    ███   ███    ███ ███▀▀▀██▄   ███          ███    ███   ███    ███ 
  ███    ███   ███    █▀  ███   ███   ███          ███    ███   ███    ███ 
 ▄███▄▄▄▄██▀  ▄███▄▄▄     ███   ███  ▄███          ███    ███  ▄███▄▄▄▄██▀ 
▀▀███▀▀▀▀▀   ▀▀███▀▀▀     ███   ███ ▀▀███ ████▄  ▀███████████ ▀▀███▀▀▀▀▀   
▀███████████   ███    █▄  ███   ███   ███    ███   ███    ███ ▀███████████ 
  ███    ███   ███    ███ ███   ███   ███    ███   ███    ███   ███    ███ 
  ███    ███   ██████████  ▀█   █▀    ████████▀    ███    █▀    ███    ███ 
  ███    ███                                                    ███    ███ 
]]

Callback.Add("Load", function() if myHero.charName == "Rengar" then Rengar_Load() end end)

function Rengar_Load()	
	-- Menu
	M = MenuConfig("Rengar", "Rengar")
		M:Menu("s", "Summoners")
			M.s:Boolean("I", "Use Ignite", true)
		M:Menu("c", "Combo")
			M.c:Boolean("Q", "Use Q", true)
			M.c:Boolean("W", "Use W", true)
			M.c:Boolean("E", "Use E", true)
			M.c:DropDown("CM", "Combo Mode", 1, {"QWE (E Prio)", "QWE (Q Prio)", "QWE (W Prio)"})
			M.c:KeyBinding("cms", "Change Combo Mode", string.byte("T"))
			M.c:DropDown("WJ", "While Jumping", 1, {"E", "W", "Q"})
			M.c:DropDown("AL", "After Landing", 3, {"E", "W", "Q"})
			M.c:Boolean("SWA", "Use Spells Leap w/o 5 Stacks", true)
		M:Menu("f", "LaneClear/ JunglerClear")
			M.f:Boolean("Q", "Use LC Q", true)
			M.f:Boolean("W", "Use LC W", true)
			M.f:Boolean("E", "Use LC E", true)
			M.f:Boolean("QJ", "Use JC Q", true)
			M.f:Boolean("WJ", "Use JC W", true)
			M.f:Boolean("EJ", "Use JC E", true)
			M.f:Boolean("IJ", "Use Items", true)
		M:Menu("h", "Heal")
			M.h:Boolean("AH", "Auto Heal?", true)
			M.h:Slider("HP", "What Hp %?", 25, 1, 100, 1)
		M:Menu("k", "KillSteal")
			M.k:Boolean("W", "Use W", true)
			M.k:Boolean("E", "Use E", true)
		M:Menu("m", "Misc")
			M.m:Boolean("Y", "Use Youmuu When Ult", true)
			M.m:KeyBinding("E", "Flee", string.byte("Z"))
			M.m:Boolean("A", "AutoLevel", false)
			M.m:DropDown("AL", "Auto Level Mode", 1, {"QEW", "QWE"})
		M:Menu("l", "Smite Settings")
			M.l:Boolean("B", "Blue", true)
			M.l:Boolean("R", "Red", true)
			M.l:Boolean("D", "Dragon", true)
			M.l:Boolean("H", "Rift Herald", true)
			M.l:Boolean("Ba", "Baron", true)
			M.l:Boolean("K", "Ks", true)
		M:Menu("d", "Drawings")
			M.d:Boolean("W", "W Blue", false)
			M.d:Boolean("E", "E Green", false)
			M.d:Boolean("R", "R detect Range White", true)

	-- Vars
	Mode = nil
	summonerNameOne = myHero:GetSpellData(SUMMONER_1).name 
	summonerNameTwo = myHero:GetSpellData(SUMMONER_2).name
	ignite = (summonerNameOne:lower():find("summonerdot") and SUMMONER_1 or (summonerNameTwo:lower():find("summonerdot") and SUMMONER_2 or nil))
	smite = nil
	smitetable = {"SummonerSmite","S5_SummonerSmitePlayerGanker","S5_SummonerSmiteDuel"}
	Q = { delay = 0.25, speed = math.huge, width = 0, range = 200}
	W = { delay = 0.25, speed = math.huge, width = 490, range = myHero.boundingRadius+700}
	E = { delay = 0.25, speed = 1500, width = 70, range = myHero.boundingRadius+1000}
	R = { delay = 0.25, speed = math.huge, width = 0, range = 2000}
	Buffs = {R=0, P=0}
	Skills = {
		[_Q] = {combo = function(unit) if ValidTarget(unit, Q.range) and Mode == "Combo" and Ready(_Q) and M.c.Q:Value() then CastSpell(_Q) end end, laneclear = function(unit) if Ready(_Q) and Mode == "LaneClear" and ValidTarget(unit, Q.range) then CastSpell(_Q) end end, jungleclear = function(unit) if Ready(_Q) and Mode == "LaneClear" and ValidTarget(unit, Q.range) then CastSpell(_Q) end end},
		[_W] = {combo = function(unit) if ValidTarget(unit, W.width) and Ready(_W) and M.c.W:Value() then CastSpell(_W) end end, laneclear = function(unit) if Ready(_W) and ValidTarget(unit, W.width) then CastSpell(_W) end end, jungleclear = function(unit) if Ready(_W) and ValidTarget(unit, W.width) then CastSpell(_W) end end, heal = function() if myHero.mana == 5 then CastSpell(_W) end end},
		[_E] = {combo = function(unit,pos) if ValidTarget(unit, E.range) and Ready(_E) and M.c.E:Value() then CastSkillShot(_E, pos) end end, laneclear = function(unit, pos) if Ready(_E) and ValidTarget(unit, E.range) then CastSkillShot(_E, pos) end end, jungleclear = function(unit, pos) if Ready(_E) and ValidTarget(unit, E.range) then CastSkillShot(_E, pos) end end, escape = function(pos) MoveToXYZ(GetMousePos()) if Ready(_E) and ValidTarget(pos, E.range) then local prediction = GetPrediction(pos, E); if prediction.hitChance > .65 and not prediction:mCollision(1) then CastSkillShot(_E, prediction.castPos) end end end},
	}
	--Callbacks
	Rengar_LoadWalker()
	Callback.Add("Animation",function(unit,ani) Rengar_OnJump(unit,ani) end)
	Callback.Add("UpdateBuff", function(unit, buff) Rengar_UBuff(unit, buff) end)
	Callback.Add("RemoveBuff", function(unit, buff) Rengar_RBuff(unit, buff) end)
	Callback.Add("Draw", function() 	
		if M.d.W:Value() or M.d.E:Value() or M.d.R:Value() then
			if M.d.W:Value() and Ready(_W) then
				DrawCircle(myHero, W.width+myHero.boundingRadius, 1,1,GoS.Blue)
			end
			if M.d.E:Value() and Ready(_E) then
				DrawCircle(myHero, E.range+myHero.boundingRadius, 1,1,GoS.Green)
			end
			if M.d.R:Value() and (Ready(_R) or Buffs.R > 0) then
				DrawCircle(myHero, 1450, 1,1,GoS.White)
			end
		end 
	end)
	print("<font color=\"#0fa2cd\"><b>[Rengar OnS]:</b></font><font color=\"#FFFFFF\"> Loaded!</font>")
end

function Rengar_LoadWalker()
	if IOW_Loaded then
		Callback.Add("Tick", function() Rengar_Tick(IOW:Mode(), "Combo", "LaneClear") end)
	end
	if DAC_Loaded then
		Callback.Add("Tick", function() Rengar_Tick(DAC:Mode(), "Combo", "LaneClear") end)
	end
	if PW_Loaded then
		Callback.Add("Tick", function() Rengar_Tick(PW:Mode(), "Combo", "LaneClear") end)
	end
	if GosWalk_Loaded then
		Callback.Add("Tick", function() Rengar_Tick(GosWalk.CurrentMode, 0, 3) end)
	end
end

function Rengar_Tick(m,c,l)
	if myHero.dead then return end
	Rengar_Checks()
	if m == c then
		Rengar_Combo()
		Rengar_CastItems(Qts:GetTarget())
		Mode = "Combo"
	end
	if m == l then
		Rengar_LaneClear()
		Rengar_JungleClear()
		Mode = "LaneClear"
	end
	if M.m.E:Value() then
		Skills[_E].escape(Ets:GetTarget())
	end
	if M.m.Y:Value() and Buffs.R > 0 then
		DelayAction(function() local Youmuu = GetItemSlot(myHero, 3142); if Youmuu ~= nil and Ready(Youmuu) then CastSpell(Youmuu) end end, .1)
	end
	if M.h.AH:Value() and GetPercentHP(myHero) < M.h.HP:Value() then
		Skills[_W].heal()
	end
	if m ~= l and m ~= c then
		Mode = nil
	end
	if M.m.A:Value() then  
		Rengar_Autolevel()
	end
	Rengar_KillSteal()
	Rengar_SwitchCombo()
	Rengar_Smite()
end

function Rengar_Checks()
	Qr = Ready(_Q)
	Wr = Ready(_W)
	Er = Ready(_E)
	Qts = TargetSelector(Q.range,TARGET_LESS_CAST, DAMAGE_PHYSICAL, true, false)
	Wts = TargetSelector(W.width,TARGET_LESS_CAST, DAMAGE_MAGIC, true, false)
	Ets = TargetSelector(E.range,TARGET_LESS_CAST, DAMAGE_PHYSICAL, true, false)
	Rts = TargetSelector(725,TARGET_LESS_CAST, DAMAGE_PHYSICAL, true, false)
	Youmuu = GetItemSlot(myHero, 3142)
	Tiamat = GetItemSlot(myHero, 3077)
	Hydra = GetItemSlot(myHero, 3074)
	Titanic = GetItemSlot(myHero, 3053)
	for i=1,3 do 
		if smite == nil then
			smite = (summonerNameOne:lower():find(smitetable[i]:lower()) and SUMMONER_1 or (summonerNameTwo:lower():find(smitetable[i]:lower()) and SUMMONER_2 or nil))
		end
	end
end

 function Rengar_OnJump(unit, ani)
 	if unit.isMe and ani == "Spell5" then
 		if Mode == "Combo" and myHero.mana == 5 and (Buffs.R > 0 or Buffs.P > 0) then
 			if M.c.WJ:Value() == 1 and Er then
 				local prediction = GetPrediction(Ets:GetTarget(), E)
 				Skills[_E].combo(Ets:GetTarget(), prediction.castPos)
 				elseif (M.c.WJ:Value() == 2 or Wr) and M.c.WJ:Value() ~= 3 and M.c.AL:Value() ~= 2 and not Er then
 					Skills[_W].combo(Wts:GetTarget())
 					elseif M.c.WJ:Value() == 3 or Qr then
 						Skills[_Q].combo(Qts:GetTarget())
 			end
 			DelayAction(function() 
 				if M.c.AL:Value() == 1 and Er then 
 					local prediction = GetPrediction(Ets:GetTarget(), E)
 					Skills[_E].combo(Ets:GetTarget(), prediction.castPos)
 					elseif (M.c.AL:Value() == 2 or Wr) and M.c.AL:Value() ~= 3 and not Er then
 						Skills[_W].combo(Wts:GetTarget())
 						elseif M.c.AL:Value() == 3 or Qr then
 							Skills[_Q].combo(Qts:GetTarget())
 				end
 			end, .450)
 			Rengar_CastItems(Qts:GetTarget()) 
 		end
 		if Mode == "Combo" and M.c.SWA:Value() and (Buffs.R > 0 or Buffs.P > 0) then
 			if M.c.WJ:Value() == 1 and Er then
 				local prediction = GetPrediction(Ets:GetTarget(), E)
 				Skills[_E].combo(Ets:GetTarget(), prediction.castPos)
 				elseif (M.c.WJ:Value() == 2 or Wr) and M.c.WJ:Value() ~= 3 and M.c.AL:Value() ~= 2 and not Er then
 					Skills[_W].combo(Wts:GetTarget())
 					elseif M.c.WJ:Value() == 3 or Qr then
 						Skills[_Q].combo(Qts:GetTarget())
 			end
 			DelayAction(function() 
 				if M.c.AL:Value() == 1 and Er then 
 					local prediction = GetPrediction(Ets:GetTarget(), E)
 					Skills[_E].combo(Ets:GetTarget(), prediction.castPos)
 					elseif (M.c.AL:Value() == 2 or Wr) and M.c.AL:Value() ~= 3 and not Er then
 						Skills[_W].combo(Wts:GetTarget())
 						elseif M.c.AL:Value() == 3 or Qr then
 							Skills[_Q].combo(Qts:GetTarget())
 				end 
 			end, .450)
 			Rengar_CastItems(Qts:GetTarget()) 
 		end
 	end
 end

function Rengar_Combo()
	if Buffs.P == 0 and Mode == "Combo" then 
		if myHero.mana == 5 and M.c.CM:Value() == 1 then
			if Er and ValidTarget(Ets:GetTarget(), E.range) then
				local prediction = GetPrediction(Ets:GetTarget(), E)
				if prediction.hitChance > .65 and not prediction:mCollision(1) then 
					Skills[_E].combo(Ets:GetTarget(), prediction.castPos)
				end
			end
			if Qr and ValidTarget(Qts:GetTarget(), Q.range) then
				Skills[_Q].combo(Qts:GetTarget())
			end
			if Wr and ValidTarget(Wts:GetTarget(), W.width) then
				Skills[_W].combo(Wts:GetTarget())
			end
		end
		if myHero.mana < 5 and M.c.CM:Value() == 1 then
			if Er and ValidTarget(Ets:GetTarget(), E.range) then
				local prediction = GetPrediction(Ets:GetTarget(), E)
				if prediction.hitChance > .65 and not prediction:mCollision(1) then 
					Skills[_E].combo(Ets:GetTarget(), prediction.castPos)
				end
			end
			if Qr and myHero.mana < 5 and ValidTarget(Qts:GetTarget(), Q.range) then
				Skills[_Q].combo(Qts:GetTarget())
			end
			if Wr and myHero.mana < 5 and ValidTarget(Wts:GetTarget(), W.width) then
				Skills[_W].combo(Wts:GetTarget())
			end
		end
		if myHero.mana == 5 and M.c.CM:Value() == 2 then
			if Qr and ValidTarget(Qts:GetTarget(), Q.range) then
				Skills[_Q].combo(Qts:GetTarget())
			end
			if Er and ValidTarget(Ets:GetTarget(), E.range) then
				local prediction = GetPrediction(Ets:GetTarget(), E)
				if prediction.hitChance > .65 and not prediction:mCollision(1) then 
					Skills[_E].combo(Ets:GetTarget(), prediction.castPos)
				end
			end
			if Wr and ValidTarget(Wts:GetTarget(), W.width) then
				Skills[_W].combo(Ets:GetTarget())
			end
		end
		if myHero.mana < 5 and M.c.CM:Value() == 2 then
			if Qr and ValidTarget(Qts:GetTarget(), Q.range) then
				Skills[_Q].combo(Qts:GetTarget())
			end
			if Er and myHero.mana < 5 and ValidTarget(Ets:GetTarget(), E.range) then
				local prediction = GetPrediction(Ets:GetTarget(), E)
				if prediction.hitChance > .65 and not prediction:mCollision(1) then 
					Skills[_E].combo(Ets:GetTarget(), prediction.castPos)
				end
			end
			if Wr and myHero.mana < 5 and ValidTarget(Wts:GetTarget(), W.width) then
				Skills[_W].combo(Wts:GetTarget())
			end
		end
		if myHero.mana == 5 and M.c.CM:Value() == 3 then
			if Wr and ValidTarget(Wts:GetTarget(), W.width) then
				Skills[_W].combo(Wts:GetTarget())
			end
			if Er and ValidTarget(Ets:GetTarget(), E.range) then
				local prediction = GetPrediction(Ets:GetTarget(), E)
				if prediction.hitChance > .65 and not prediction:mCollision(1) then 
					Skills[_E].combo(Ets:GetTarget(), prediction.castPos)
				end
			end
			if Qr and ValidTarget(Qts:GetTarget(), Q.range)  then
				Skills[_Q].combo(Qts:GetTarget())		
			end
		end
		if myHero.mana < 5 and M.c.CM:Value() == 3 then
			if Wr and ValidTarget(Wts:GetTarget(), W.width) and myHero.mana < 5 then
				Skills[_W].combo(Wts:GetTarget())
			end
			if Er and ValidTarget(Ets:GetTarget(), E.range) and myHero.mana < 5 then
				local prediction = GetPrediction(Ets:GetTarget(), E)
				if prediction.hitChance > .65 and not prediction:mCollision(1) then 
					Skills[_E].combo(Ets:GetTarget(), prediction.castPos)
				end
			end
			if Qr and ValidTarget(Qts:GetTarget(), Q.range) and myHero.mana < 5 then
				Skills[_Q].combo(Qts:GetTarget())			
			end
		end
	end 
end

function Rengar_LaneClear()
	for i, u in pairs(minionManager.objects) do
		if u.team == MINION_ENEMY and u.team ~= 300 then
			if M.f.IJ:Value() then
				Rengar_CastItems(u) 
			end
			if M.f.Q:Value() then
				Skills[_Q].laneclear(u)
			end
			if M.f.W:Value() then
				Skills[_W].laneclear(u)
			end
			if M.f.E:Value() then
				Skills[_E].laneclear(u, u)
			end
		end
	end
end

function Rengar_JungleClear()
	for i, u in pairs(minionManager.objects) do
		if u.team ~= MINION_ENEMY and u.team == 300 then
			if M.f.IJ:Value() then
				Rengar_CastItems(u) 
			end
			if M.f.QJ:Value() then
				Skills[_Q].jungleclear(u)
			end
			if M.f.WJ:Value() then
				Skills[_W].jungleclear(u)
			end
			if M.f.EJ:Value() then
				Skills[_E].jungleclear(u, u)
			end
		end
	end
end

function Rengar_UBuff(unit, buff)
	if unit and unit == myHero and buff.Name:lower():find("rengarpassivebuff")  then
		Buffs.P = buff.Count 
	end
	if unit and unit == myHero and buff.Name == "RengarR" then
		Buffs.R = buff.Count 
	end
end

function Rengar_RBuff(unit, buff)
	if unit and unit == myHero and buff.Name:lower():find("rengarpassivebuff") then
		Buffs.P = 0
	end
	if unit and unit == myHero and buff.Name == "RengarR" then
		Buffs.R = 0 
	end
end

function Rengar_CastItems(unit)
	if Buffs.P == 0 then
		local Total = ValidTarget(unit, 385)
		if Ready(Tiamat) and Total then 
			CastSpell(Tiamat)
		end
		if Ready(Hydra) and Total then 
			CastSpell(Hydra)
		end
		if Ready(Titanic) and Total then 
			CastSpell(Titanic)
		end 
		if Mode == "Combo" then 
			if Ready(Youmuu) and Total then 
				CastSpell(Youmuu)
			end
		end 
	end
end

function Rengar_KillSteal()
	for i,u in pairs(GetEnemyHeroes()) do 
		local idmg = (70 + 20*GetLevel(myHero)); 
		local wdmg = (80+30*GetCastLevel(myHero, _W) + .8*GetBonusAP(myHero)); 
		local edmg = (50+50*GetCastLevel(myHero, _E)+.7*GetBonusDmg(myHero))
		if ignite and Ready(ignite) and ValidTarget(u, 660) and M.s.I:Value() and idmg > u.health then 
			CastTargetSpell(u, ignite) 
		end 
		if ValidTarget(u, W.width) and u.health < myHero:CalcMagicDamage(u, wdmg) and Ready(_W) and M.k.W:Value() then 
			CastSpell(_W) 
		end 
		if ValidTarget(u, E.range) and u.health < myHero:CalcDamage(u, edmg) and Ready(_E) and M.k.E:Value() then 
			CastSkillShot(_E, u) 
		end 
	end 
end

local global_ticks = 0

function Rengar_SwitchCombo()
	local Ticker = GetTickCount()
	if M.c.cms:Value() then
		if (global_ticks + 250) < Ticker then
			if M.c.CM:Value() == 1 then 
				M.c.CM:Value(2)
				print("<font color=\"#0fa2cd\"><b>[Rengar OnS]:</b></font><font color=\"#FFFFFF\"> Combo Mode: W</font>")
			elseif M.c.CM:Value() == 2 then
				M.c.CM:Value(3)
				print("<font color=\"#0fa2cd\"><b>[Rengar OnS]:</b></font><font color=\"#FFFFFF\"> Combo Mode: Q</font>")
			elseif M.c.CM:Value() == 3 then
				M.c.CM:Value(1)
				print("<font color=\"#0fa2cd\"><b>[Rengar OnS]:</b></font><font color=\"#FFFFFF\"> Combo Mode: E</font>")
			end
			global_ticks = Ticker
		end
	end
end

function Rengar_Smite()
	if smite and Ready(smite) then
		for i, u in pairs(minionManager.objects) do
			if u.team ~= MINION_ENEMY and u.team == 300 and ValidTarget(u, 650) then
				local smiteDMG = (({[1]=390,[2]=410,[3]=430,[4]=450,[5]=480,[6]=510,[7]=540,[8]=570,[9]=600,[10]=640,[11]=680,[12]=720,[13]=760,[14]=800,[15]=850,[16]=900,[17]=950,[18]=1000})[GetLevel(myHero)])
				local wdmg1 = (80+30*GetCastLevel(myHero, _W) + .8*GetBonusAP(myHero)); 
				local edmg1 = (50+50*GetCastLevel(myHero, _E)+.7*GetBonusDmg(myHero));
				local wdmg = myHero:CalcMagicDamage(u, wdmg)
				local edmg = myHero:CalcDamage(u, edmg)
				if u.charName:lower():find("dragon") and M.l.D:Value() then
					if u.health < smiteDMG then
						CastTargetSpell(u, smite)
						elseif u.health < smiteDMG + wdmg and Ready(_W) and ValidTarget(u, W.range) then
							CastSpell(_W)
							DelayAction(function() CastTargetSpell(u, smite) end, W.delay+.25)
							elseif u.health < smiteDMG + wdmg + edmg and Ready(_W) and Ready(_E) and ValidTarget(u, E.range) then
								CastSkillShot(_E, u)
								CastSpell(_W)
								DelayAction(function() CastTargetSpell(u, smite) end, W.delay+E.delay+.25)
					end
				end
				local smiteable = {["SRU_Red"]={menu = M.l.R:Value()},["SRU_Blue"]={menu = M.l.B:Value()},["SRU_RiftHerald"]={menu = M.l.H:Value()},["SRU_Baron"]={menu = M.l.Ba:Value()}}
				if smiteable[u.charName] and smiteable[u.charName].menu then
					if u.health < smiteDMG then
						CastTargetSpell(u, smite)
					end
					if u.health < smiteDMG + wdmg  and Ready(_W) and ValidTarget(u, W.range) then
						CastSpell(_W)
						DelayAction(function() CastTargetSpell(u, smite) end, W.delay+.25)
					end
					if u.health < smiteDMG + wdmg + edmg and Ready(_W) and Ready(_E) and ValidTarget(u, E.range) then
						CastSkillShot(_E, u)
						CastSpell(_W)
						DelayAction(function() CastTargetSpell(u, smite) end, W.delay+E.delay+.25)
					end
				end		
			end
		end
		if GetCastName(myHero,smite) == "S5_SummonerSmitePlayerGanker" and M.l.K:Value() then
			for i,enemy in pairs(GetEnemyHeroes()) do
				if ValidTarget(enemy, 750) and GetCurrentHP(enemy) + GetDmgShield(enemy) <= 20+8*GetLevel(myHero) then
					CastTargetSpell(enemy,smite)
				end
			end
		end
	end
end

function Rengar_Autolevel()  
	if GetLevelPoints(myHero) == 1 then 
	    local leveltable = M.m.AL:Value() == 1 and (({_Q, _W, _E, _Q, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E})[myHero.level]) or (({_Q, _W, _E, _Q, _Q, _R, _Q, _E, _Q, _E, _R, _E, _E, _W, _W, _R, _W, _W})[myHero.level])
	    DelayAction(function() LevelSpell(leveltable) end, math.random(1000,3000)*0.001)
	end
end
