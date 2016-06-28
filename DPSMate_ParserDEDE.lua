local player = UnitName("player")
local _,playerclass = UnitClass("player")
local t = {}
local strgfind = string.gfind
local DB = DPSMate.DB
local tnbr = tonumber

--schmetternd
if (GetLocale() == "deDE") then
	-- Ihr trefft X. Schaden: d+. (gestreift/geblockt)
	-- Ihr trefft X kritisch für d+ Schaden.
	-- Ihr fallt und verliert d+ Gesundheit.
	-- Ihr ertrinkt und verliert d+ Gesundheit.
	-- Ihr verliert d+ Gesundheit durch Berührung mit Lava.
	DPSMate.Parser.SelfHits = function(self, msg)
		t = {}
		for a,b,c in strgfind(msg, "Ihr trefft (.+)%. Schaden: (%d+)\.%s?(.*)") do
			if c == "(gestreift)" then t[3]=1;t[1]=0 elseif c ~= "" then t[4]=1;t[1]=0; end
			DB:EnemyDamage(true, DPSMateEDT, player, "Angreifen", 1, 0, 0, 0, 0, 0, tnbr(b), a, t[4] or 0, t[3] or 0)
			DB:DamageDone(player, "Angreifen", 1, 0, 0, 0, 0, 0, tnbr(b), t[3] or 0, t[4] or 0)
			if self.TargetParty[a] then DB:BuildFail(1, a, player, "Angreifen", tnbr(b)) end
			return
		end
		for a,b in strgfind(msg, "Ihr trefft (.+) kritisch für (%d+) Schaden%.") do
			DB:EnemyDamage(true, DPSMateEDT, player, "Angreifen", 0, 1, 0, 0, 0, 0, tnbr(b), a, t[4] or 0, t[3] or 0)
			DB:DamageDone(player, "Angreifen", 0, 1, 0, 0, 0, 0, tnbr(b), t[3] or 0, t[4] or 0)
			if self.TargetParty[a] then DB:BuildFail(1, a, player, "Angreifen", tnbr(b)) end
			return
		end
		for a in strgfind(msg, "Ihr fallt und verliert (%d+) Gesundheit%.") do
			DB:DamageTaken(player, "Fallen", 1, 0, 0, 0, 0, 0, tnbr(a), "Umgebung", 0)
			DB:DeathHistory(player, "Umgebung", "Fallen", tnbr(a), 1, 0, 0, 0)
			return
		end
		for a in strgfind(msg, "Ihr verliert (%d+) Gesundheit durch Berührung mit Lava%.") do
			DB:DamageTaken(player, "Lava", 1, 0, 0, 0, 0, 0, tnbr(a), "Umgebung", 0)
			DB:DeathHistory(player, "Umgebung", "Lava", tnbr(a), 1, 0, 0, 0)
			return
		end
		for a in strgfind(msg, "Ihr ertrinkt und verliert (%d+) Gesundheit%.") do
			DB:DamageTaken(player, "Ertrinken", 1, 0, 0, 0, 0, 0, tnbr(a), "Umgebung", 0)
			DB:DeathHistory(player, "Umgebung", "Ertrinken", tnbr(a), 1, 0, 0, 0)
			return
		end
	end
	
	-- Ihr verfehlt X.
	-- Ihr greift an. X weicht aus.
	DPSMate.Parser.SelfMisses = function(self, msg)
		-- Filter out immune message --> using them?
		t = {}
		for a in strgfind(msg, "Ihr verfehlt (.+)%.") do 
			DB:EnemyDamage(true, DPSMateEDT, player, "Angreifen", 0, 0, 1, 0, 0, 0, 0, a, 0, 0)
			DB:DamageDone(player, "Angreifen", 0, 0, 1, 0, 0, 0, 0, 0, 0)
			return
		end
		for a,b in strgfind(msg, "Ihr greift an%. (.+) weicht aus%.") do 
			DB:EnemyDamage(true, DPSMateEDT, player, "Angreifen", 0, 0, 0, 0, 1, 0, 0, a, 0, 0)
			DB:DamageDone(player, "Angreifen", 0, 0, 0, 0, 1, 0, 0, 0, 0)
			return
		end
		-- Not tested
		for a,b in strgfind(msg, "Ihr greift an%. (.+) (%a-)%.") do 
			if b=="pariert" then t[1]=1 else t[3]=1 end
			DB:EnemyDamage(true, DPSMateEDT, player, "Angreifen", 0, 0, 0, t[1] or 0, 0, 0, 0, a, t[3] or 0, 0)
			DB:DamageDone(player, "Angreifen", 0, 0, 0, t[1] or 0, 0, 0, 0, 0, t[3] or 0)
		end
	end
	
	-- X trifft Y kritisch: 455 Schaden.
	-- X von Euch trifft X für 208 Schaden.
	-- X trifft Y. Schaden: 21 Feuer.
	-- Y ist X ausgewichen.
	-- X wurde von Y pariert.
	-- X wurde von Y geblockt.
	-- X hat Y verfehlt.
	-- Ihr habt es mit X versucht, aber Y hat widerstanden.
	DPSMate.Parser.SelfSpellDMG = function(self, msg)
		-- Filter out immune message -> using them?
		t = {}
		for a,b,c,d,e in strgfind(msg, "(.+) von Euch trifft (.+) für (%d+)(.*)\.%s?(.*)") do 
			t[1] = tnbr(c)
			if strfind(e, "geblockt") then t[4]=1;t[2]=0;t[3]=0 end
			if DPSMate.Parser.Kicks[a] then DB:AssignPotentialKick(player, a, c, GetTime()) end
			if DPSMate.Parser.DmgProcs[a] then DB:BuildBuffs(player, player, a, true) end
			DB:EnemyDamage(true, DPSMateEDT, player, a,  1, 0, 0, 0, 0, 0, t[1], c, t[4] or 0, 0)
			DB:DamageDone(player, a, 1, 0, 0, 0, 0, 0, t[1], 0, t[4] or 0)
			if self.TargetParty[c] then DB:BuildFail(1, c, player, a, t[1]) end
			return
		end
		for a,b,c,d,e,f in strgfind(msg, "(.+) trifft (.+)%s?(.*)%. Schaden: (%d+)(.*)\.%s?(.*)") do 
			t[1] = tnbr(d)
			if c=="kritisch" then t[2] = 1;t[3]=0 end
			if DPSMate.Parser.Kicks[a] then DB:AssignPotentialKick(player, a, c, GetTime()) end
			if DPSMate.Parser.DmgProcs[a] then DB:BuildBuffs(player, player, a, true) end
			DB:EnemyDamage(true, DPSMateEDT, player, a,  t[3] or 1, t[2] or 0, 0, 0, 0, 0, t[1], c, 0, 0)
			DB:DamageDone(player, a, t[3] or 1, t[2] or 0, 0, 0, 0, 0, t[1], 0, 0)
			if self.TargetParty[c] then DB:BuildFail(1, c, player, a, t[1]) end
			return
		end
		for a,b,c,d,e in strgfind(msg, "(.+) trifft (.+) kritisch: (%d+)(.*)\.%s?(.*)") do 
			t[1] = tnbr(c)
			if strfind(e, "geblockt") then t[4]=1;t[2]=0;end
			if DPSMate.Parser.Kicks[a] then DB:AssignPotentialKick(player, a, c, GetTime()) end
			if DPSMate.Parser.DmgProcs[a] then DB:BuildBuffs(player, player, a, true) end
			DB:EnemyDamage(true, DPSMateEDT, player, a,  0, t[2] or 1, 0, 0, 0, 0, t[1], c, t[4] or 0, 0)
			DB:DamageDone(player, a, 0, t[2] or 1, 0, 0, 0, 0, t[1], 0, t[4] or 0)
			if self.TargetParty[c] then DB:BuildFail(1, c, player, a, t[1]) end
			return
		end
		for a,b in strgfind(msg, "(.+) ist (.+) ausgewichen%.") do 
			DB:EnemyDamage(true, DPSMateEDT, player, b, 0, 0, 0, 0, 1, 0, 0, a, 0, 0)
			DB:DamageDone(player, b, 0, 0, 0, 0, 1, 0, 0, 0, 0)
			return
		end
		for a,b in strgfind(msg, "(.+) wurde von (.+) pariert%.") do 
			DB:EnemyDamage(true, DPSMateEDT, player, a, 0, 0, 0, 1, 0, 0, 0, b, 0, 0)
			DB:DamageDone(player, a, 0, 0, 0, 1, 0, 0, 0, 0, 0)
			return
		end
		for a,b in strgfind(msg, "(.+) hat (.+) verfehlt%.") do
			DB:EnemyDamage(true, DPSMateEDT, player, a, 0, 0, 1, 0, 0, 0, 0, b, 0, 0)
			DB:DamageDone(player, a, 0, 0, 1, 0, 0, 0, 0, 0, 0)
			return
		end
		for a,b in strgfind(msg, "Ihr habt es mit (.+) versucht, aber (.+) hat widerstanden%.") do
			DB:EnemyDamage(true, DPSMateEDT, player, a, 0, 0, 0, 0, 0, 1, 0, b, 0, 0)
			DB:DamageDone(player, a, 0, 0, 0, 0, 0, 1, 0, 0, 0)
			return
		end
		for a,b in strgfind(msg, "(.+) wurde von (.+) geblockt%.") do 
			DB:EnemyDamage(true, DPSMateEDT, player, a, 0, 0, 0, 0, 0, 0, 0, b, 1, 0)
			DB:DamageDone(player, a, 0, 0, 0, 0, 0, 0, 0, 0, 1)
			return
		end
	end
	
	-- X ist von Y betroffen.
	-- X erleidet d+ Feuerschaden (durch Y). (Player only?)
	-- X erleidet d+ Feuerschaden von Z (durch Y).
	DPSMate.Parser.PeriodicDamage = function(self, msg)
		t = {}
		-- (NAME) is afflicted by (ABILITY). => Filtered out for now.
		for a,b in strgfind(msg, "(.+) ist von (.+) betroffen%.") do DB:ConfirmAfflicted(a, b, GetTime()); if self.CC[b] then  DB:BuildActiveCC(a, b) end; return end
		-- School can be used now but how and when?
		for a,b,c,d,e in strgfind(msg, "(.+) erleidet (%d+) (%a-) von (.+) %(durch (.+)%)%.") do
			t[1] = tnbr(b)
			DB:EnemyDamage(true, DPSMateEDT, d, e.."(Periodisch)", 1, 0, 0, 0, 0, 0, t[1], a, 0, 0)
			DB:DamageDone(d, e.."(Periodisch)", 1, 0, 0, 0, 0, 0, t[1], 0, 0)
			if self.TargetParty[a] and self.TargetParty[d] then DB:BuildFail(1, a, d, e.."(Periodisch)", t[1]) end
			return
		end
		for a,b,c,d in strgfind(msg, "(.+) erleidet (%d+) (%a-) %(durch (.+)%)%.") do
			t[1] = tnbr(b)
			DB:EnemyDamage(true, DPSMateEDT, player, d.."(Periodisch)", 1, 0, 0, 0, 0, 0, t[1], a, 0, 0)
			DB:DamageDone(player, d.."(Periodisch)", 1, 0, 0, 0, 0, 0, t[1], 0, 0)
			if self.TargetParty[a] then DB:BuildFail(1, a, player, d.."(Periodisch)", t[1]) end
			return
		end
	end
	
	-- Xs Y trifft Z für d+ Feuerschaden.
	-- X ist Y von Z ausgewichen.
	-- X von Z verfehlt Y.
	-- X von Z wurde von Y pariert.
	DPSMate.Parser.FriendlyPlayerDamage = function(self, msg)
		t = {}
		for f,a,b,c,d,e in strgfind(msg, "(.+)s (.+) trifft (.+) kritisch für (%d+)(.*)\.%s?(.*)") do 
			t[1] = tnbr(c)
			if strfind(e, "geblockt") then t[4]=1;t[2]=0;end
			if DPSMate.Parser.Kicks[a] then DB:AssignPotentialKick(f, a, c, GetTime()) end
			if DPSMate.Parser.DmgProcs[a] then DB:BuildBuffs(f, f, a, true) end
			DB:EnemyDamage(true, DPSMateEDT, f, a,  0, t[2] or 1, 0, 0, 0, 0, t[1], b, t[4] or 0, 0)
			DB:DamageDone(f, a, 0, t[2] or 1, 0, 0, 0, 0, t[1], 0, t[4] or 0)
			if self.TargetParty[b] and self.TargetParty[f] then DB:BuildFail(1, b, f, a, t[1]) end
			return
		end
		for f,a,b,c,d,e in strgfind(msg, "(.+)s (.+) trifft (.+) für (%d+)(.*)\.%s?(.*)") do 
			t[1] = tnbr(c)
			if strfind(e, "geblockt") then t[4]=1;t[2]=0;t[3]=0 end
			if DPSMate.Parser.Kicks[a] then DB:AssignPotentialKick(f, a, b, GetTime()) end
			if DPSMate.Parser.DmgProcs[a] then DB:BuildBuffs(f, f, a, true) end
			DB:EnemyDamage(true, DPSMateEDT, f, a,  1, 0, 0, 0, 0, 0, t[1], b, t[4] or 0, 0)
			DB:DamageDone(f, a, 1, 0, 0, 0, 0, 0, t[1], 0, t[4] or 0)
			if self.TargetParty[b] and self.TargetParty[f] then DB:BuildFail(1, b, f, a, t[1]) end
			return
		end
		for a,b,f in strgfind(msg, "(.+) ist (.+) von (.+) ausgewichen%.") do 
			DB:EnemyDamage(true, DPSMateEDT, f, b, 0, 0, 0, 0, 1, 0, 0, a, 0, 0)
			DB:DamageDone(f, b, 0, 0, 0, 0, 1, 0, 0, 0, 0)
			return
		end
		for a,f,b in strgfind(msg, "(.+) von (.+) wurde von (.+) pariert%.") do 
			DB:EnemyDamage(true, DPSMateEDT, f, a, 0, 0, 0, 1, 0, 0, 0, b, 0, 0)
			DB:DamageDone(f, a, 0, 0, 0, 1, 0, 0, 0, 0, 0)
			return
		end
		for a,f,b in strgfind(msg, "(.+) von (.+) verfehlt (.+)%.") do
			DB:EnemyDamage(true, DPSMateEDT, f, a, 0, 0, 1, 0, 0, 0, 0, b, 0, 0)
			DB:DamageDone(f, a, 0, 0, 1, 0, 0, 0, 0, 0, 0)
			return
		end
		for f,a,b in strgfind(msg, "(.+)s (.+) wurde von (.+) widerstanden%.") do
			DB:EnemyDamage(true, DPSMateEDT, f, a, 0, 0, 0, 0, 0, 1, 0, b, 0, 0)
			DB:DamageDone(f, a, 0, 0, 0, 0, 0, 1, 0, 0, 0)
			return
		end
		for a,f,b in strgfind(msg, "(.+) von (.+) wurde von (.+) geblockt%.") do 
			DB:EnemyDamage(true, DPSMateEDT, f, a, 0, 0, 0, 0, 0, 0, 0, b, 1, 0)
			DB:DamageDone(f, a, 0, 0, 0, 0, 0, 0, 0, 0, 1)
			return
		end
	end
	
	-- X trifft Y für d+ Schaden.
	-- X trifft Y kritisch für d+ Schaden.
	-- X trifft Euch für 7 Schaden.
	-- X trifft Euch krtisch: 10 Schaden.
	-- X fällt und verliert d+ Gesundheit.
	DPSMate.Parser.FriendlyPlayerHits = function(self, msg)
		t = {}
		for a,b,c,d in strgfind(msg, "(.-) trifft (.+) kritisch für (%d+) Schaden\.%s?(.*)") do
			if d=="(gestreift)" then t[1]=1;t[3]=0 elseif d~="" then t[2]=1;t[3]=0 end
			t[5] = tnbr(c)
			DB:EnemyDamage(true, DPSMateEDT, a, "Angreifen", 0, t[3] or 1, 0, 0, 0, 0, t[5], b, t[2] or 0, t[1] or 0)
			DB:DamageDone(a, "Angreifen", 0, t[3] or 1, 0, 0, 0, 0, t[5], t[1] or 0, t[2] or 0)
			if self.TargetParty[a] and self.TargetParty[b] then DB:BuildFail(1, b, a, "Angreifen", t[5]) end
			return
		end
		for a,b,c,d in strgfind(msg, "(.-) trifft (.+) für (%d+) Schaden\.%s?(.*)") do
			if d=="(gestreift)" then t[1]=1;t[3]=0 elseif d~="" then t[2]=1;t[3]=0 end
			if b=="Euch" then b=player end
			t[5] = tnbr(c)
			DB:EnemyDamage(true, DPSMateEDT, a, "Angreifen", t[3] or 1, 0, 0, 0, 0, 0, t[5], b, t[2] or 0, t[1] or 0)
			DB:DamageDone(a, "Angreifen", t[3] or 1, 0, 0, 0, 0, 0, t[5], t[1] or 0, t[2] or 0)
			if self.TargetParty[a] and self.TargetParty[b] then DB:BuildFail(1, b, a, "Angreifen", t[5]) end
			return
		end
		for a,c,d in strgfind(msg, "(.-) trifft Euch kritisch: (%d+) Schaden\.%s?(.*)") do
			if d=="(gestreift)" then t[1]=1;t[3]=0 elseif d~="" then t[2]=1;t[3]=0 end
			t[5] = tnbr(c)
			DB:EnemyDamage(true, DPSMateEDT, a, "Angreifen", 0, t[3] or 1, 0, 0, 0, 0, t[5], player, t[2] or 0, t[1] or 0)
			DB:DamageDone(a, "Angreifen", 0, t[3] or 1, 0, 0, 0, 0, t[5], t[1] or 0, t[2] or 0)
			if self.TargetParty[a] then DB:BuildFail(1, player, a, "Angreifen", t[5]) end
			return
		end
		-- (...). (608 absorbed/resisted) -> Therefore here some loss
		for a,b in strgfind(msg, "(.-) verliert (%d+) Gesundheit durch Berührung mit Lava%.") do
			DB:DamageTaken(a, "Lava", 1, 0, 0, 0, 0, 0, tnbr(b), "Umgebung", 0)
			DB:DeathHistory(a, "Umgebung", "Lava", tnbr(b), 1, 0, 0, 0)
			return
		end
		for a,b in strgfind(msg, "(.-) fällt und verliert (%d+) Gesundheit%.") do
			DB:DamageTaken(a, "Fallen", 1, 0, 0, 0, 0, 0, tnbr(b), "Umgebung", 0)
			DB:DeathHistory(a, "Umgebung", "Fallen", tnbr(b), 1, 0, 0, 0)
			return
		end
		for a,b in strgfind(msg, "(.-) ertrinkt und verliert (%d+) Gesundheit%.") do
			DB:DamageTaken(a, "Ertrinken", 1, 0, 0, 0, 0, 0, tnbr(b), "Umgebung", 0)
			DB:DeathHistory(a, "Umgebung", "Ertrinken", tnbr(b), 1, 0, 0, 0)
			return
		end
	end
	
	-- X greift an. Y pariert.
	-- X verfehlt Y.
	-- X greift an. Y weicht aus.
	DPSMate.Parser.FriendlyPlayerMisses = function(self, msg)
		t = {}
		for a,b in strgfind(msg, "(.-) verfehlt (.+)%.") do 
			if b=="Euch" then b=player end
			DB:EnemyDamage(true, DPSMateEDT, a, "Angreifen", 0, 0, 1, 0, 0, 0, 0, b, 0, 0)
			DB:DamageDone(a, "Angreifen", 0, 0, 1, 0, 0, 0, 0, 0, 0)
			return
		end
		for a,b in strgfind(msg, "(.-) greift an%. (.+) weicht aus%.") do 
			if b=="Ihr" then b=player end
			DB:EnemyDamage(true, DPSMateEDT, a, "Angreifen", 0, 0, 0, 0, 1, 0, 0, b, 0, 0)
			DB:DamageDone(a, "Angreifen", 0, 0, 0, 0, 1, 0, 0, 0, 0)
			return
		end
		for a,b in strgfind(msg, "(.-) greift an%. (.+) pariert%.") do 
			if b=="Ihr" then b=player end
			DB:EnemyDamage(true, DPSMateEDT, a, "Angreifen", 0, 0, 0, 1, 0, 0, 0, b, 0, 0)
			DB:DamageDone(a, "Angreifen", 0, 0, 0, 1, 0, 0, 0, 0, 0)
			return
		end
		for a,b in strgfind(msg, "(.-) greift an%. (.+) blockt%.") do 
			if b=="Ihr" then b=player end
			DB:EnemyDamage(true, DPSMateEDT, a, "Angreifen", 0, 0, 0, 0, 0, 0, 0, b, 1, 0)
			DB:DamageDone(a, "Angreifen", 0, 0, 0, 0, 0, 0, 0, 0, 1)
			return
		end
	end
	
	DPSMate.Parser.SpellDamageShieldsOnSelf = function(self, msg)
		for a,b,c in strgfind(msg, "Ihr reflektiert (%d+) (%a-) auf (.+)%.") do 
			local am = tnbr(a)
			DB:EnemyDamage(true, DPSMateEDT, player, "Reflektieren", 1, 0, 0, 0, 0, 0, am, c, 0, 0)
			DB:DamageDone(player, "Reflektieren", 1, 0, 0, 0, 0, 0, am, 0, 0)
		end
		
		-- The rebirth support
		for a,b in strgfind(msg, "(.+) ist (.+) ausgewichen%.") do 
			DB:EnemyDamage(true, DPSMateEDT, player, b, 0, 0, 0, 0, 1, 0, 0, a, 0, 0)
			DB:DamageDone(player, b, 0, 0, 0, 0, 1, 0, 0, 0, 0)
			return
		end
		for a,b in strgfind(msg, "(.+) wurde von (.+) pariert%.") do 
			DB:EnemyDamage(true, DPSMateEDT, player, a, 0, 0, 0, 1, 0, 0, 0, b, 0, 0)
			DB:DamageDone(player, a, 0, 0, 0, 1, 0, 0, 0, 0, 0)
			return
		end
		for a,b in strgfind(msg, "(.+) hat (.+) verfehlt%.") do
			DB:EnemyDamage(true, DPSMateEDT, player, a, 0, 0, 1, 0, 0, 0, 0, b, 0, 0)
			DB:DamageDone(player, a, 0, 0, 1, 0, 0, 0, 0, 0, 0)
			return
		end
		for a,b in strgfind(msg, "Ihr habt es mit (.+) versucht, aber (.+) hat widerstanden%.") do
			DB:EnemyDamage(true, DPSMateEDT, player, a, 0, 0, 0, 0, 0, 1, 0, b, 0, 0)
			DB:DamageDone(player, a, 0, 0, 0, 0, 0, 1, 0, 0, 0)
			return
		end
		for a,b in strgfind(msg, "(.+) wurde von (.+) geblockt%.") do 
			DB:EnemyDamage(true, DPSMateEDT, player, a, 0, 0, 0, 0, 0, 0, 0, b, 1, 0)
			DB:DamageDone(player, a, 0, 0, 0, 0, 0, 0, 0, 0, 1)
			return
		end
	end
	
	-- X reflektiert d+ Feuerschaden auf Euch.
	DPSMate.Parser.SpellDamageShieldsOnOthers = function(self, msg)
		for a,b,c,d in strgfind(msg, "(.+) reflektiert (%d+) (%a-) auf (.+)%.") do
			local am,ta = tnbr(b)
			if d == "Euch" then ta=player end
			DB:EnemyDamage(true, DPSMateEDT, a, "Reflektieren", 1, 0, 0, 0, 0, 0, am, ta or d, 0, 0)
			DB:DamageDone(a, "Reflektieren", 1, 0, 0, 0, 0, 0, am, 0, 0)
		end
		
		-- The rebirth support
		for a,b,f in strgfind(msg, "(.+) ist (.+) von (.+) ausgewichen%.") do 
			DB:EnemyDamage(true, DPSMateEDT, f, b, 0, 0, 0, 0, 1, 0, 0, a, 0, 0)
			DB:DamageDone(f, b, 0, 0, 0, 0, 1, 0, 0, 0, 0)
			return
		end
		for a,f,b in strgfind(msg, "(.+) von (.+) wurde von (.+) pariert%.") do 
			DB:EnemyDamage(true, DPSMateEDT, f, a, 0, 0, 0, 1, 0, 0, 0, b, 0, 0)
			DB:DamageDone(f, a, 0, 0, 0, 1, 0, 0, 0, 0, 0)
			return
		end
		for a,f,b in strgfind(msg, "(.+) von (.+) verfehlt (.+)%.") do
			DB:EnemyDamage(true, DPSMateEDT, f, a, 0, 0, 1, 0, 0, 0, 0, b, 0, 0)
			DB:DamageDone(f, a, 0, 0, 1, 0, 0, 0, 0, 0, 0)
			return
		end
		for f,a,b in strgfind(msg, "(.+)s (.+) wurde von (.+) widerstanden%.") do
			DB:EnemyDamage(true, DPSMateEDT, f, a, 0, 0, 0, 0, 0, 1, 0, b, 0, 0)
			DB:DamageDone(f, a, 0, 0, 0, 0, 0, 1, 0, 0, 0)
			return
		end
		for a,f,b in strgfind(msg, "(.+) von (.+) wurde von (.+) geblockt%.") do 
			DB:EnemyDamage(true, DPSMateEDT, f, a, 0, 0, 0, 0, 0, 0, 0, b, 1, 0)
			DB:DamageDone(f, a, 0, 0, 0, 0, 0, 0, 0, 0, 1)
			return
		end
	end
	
	----------------------------------------------------------------------------------
	--------------                    Damage taken                      --------------                                  
	----------------------------------------------------------------------------------

	-- X trifft Euch für d+ Schaden.
	-- X trifft Euch kritisch: d+ Schaden.
	DPSMate.Parser.CreatureVsSelfHits = function(self, msg)
		t = {}
		for a,c,d in strgfind(msg, "(.+) trifft Euch für (%d+)(.*)") do
			if strfind(d, "schmetternd") then t[3]=1;t[1]=0; elseif strfind(d, "geblockt") then t[4]=1;t[1]=0; end
			t[5] = tnbr(c)
			DB:EnemyDamage(false, DPSMateEDD, player, "Angreifen", t[1] or 1, 0, 0, 0, 0, 0, t[5], a, t[4] or 0, t[3] or 0)
			DB:DamageTaken(player, "Angreifen", t[1] or 1, 0, 0, 0, 0, 0, t[5], a, t[3] or 0)
			DB:DeathHistory(player, a, "Angreifen", t[5], t[1] or 1, 0, 0, t[3] or 0)
			return
		end
		for a,c,d in strgfind(msg, "(.+) trifft Euch kritisch: (%d+)(.*)") do
			if strfind(d, "schmetternd") then t[3]=1;t[2]=0 elseif strfind(d, "geblockt") then t[4]=1;t[2]=0 end
			t[5] = tnbr(c)
			DB:EnemyDamage(false, DPSMateEDD, player, "Angreifen", 0, t[2] or 1, 0, 0, 0, 0, t[5], a, t[4] or 0, t[3] or 0)
			DB:DamageTaken(player, "Angreifen", 0, t[2] or 1, 0, 0, 0, 0, t[5], a, t[3] or 0)
			DB:DeathHistory(player, a, "Angreifen", t[5], 0, t[2] or 1, 0, t[3] or 0)
			return
		end
	end
	
	-- X verfehlt Euch.
	-- X greift an. Ihr pariert.
	-- X greift an. Ihr weicht aus.
	DPSMate.Parser.CreatureVsSelfMisses = function(self, msg)
		t = {}
		for c in strgfind(msg, "(.+) greift an%. Ihr absorbiert allen Schaden%.") do DB:Absorb("Angreifen", player, c); return end
		for a in strgfind(msg, "(.+) verfehlt Euch%.") do 
			DB:EnemyDamage(false, DPSMateEDD, player, "Angreifen", 0, 0, 1, 0, 0, 0, 0, a, 0, 0)
			DB:DamageTaken(player, "Angreifen", 0, 0, 1, 0, 0, 0, 0, a, 0)
			return
		end
		for a,b in strgfind(msg, "(.+) greift an. Ihr (.+)%.") do 
			if b=="pariert" then t[1]=1 elseif b=="weicht aus" then t[2]=1 else t[3]=1 end 
			DB:EnemyDamage(false, DPSMateEDD, player, "Angreifen", 0, 0, 0, t[1] or 0, t[2] or 0, 0, 0, a, t[3] or 0, 0)
			DB:DamageTaken(player, "Angreifen", 0, 0, 0, t[1] or 0, t[2] or 0, 0, 0, a, 0)
			return
		end
	end 
	
	-- X trifft Euch (mit Y). Schaden: d+.
	-- X trifft Euch kritisch (mit Y). Schaden: d+.
	-- X trifft Euch mit 'Y' für d+ Frostschaden.
	-- X trifft Euch (mit Y) und verfehlt Euch.
	-- Xs Y wurde ausgewichen.
	DPSMate.Parser.CreatureVsSelfSpellDamage = function(self, msg)
		t = {}
		for a,b,c,d,e in strgfind(msg, "(.+) trifft Euch(.*) %(mit (.+)%)%. Schaden: (%d+)(.*)") do -- Potential here to track school and resisted damage
			if b=="" then t[1]=1;t[2]=0 end
			if strfind(e, "geblockt") then t[4]=1 end
			t[3] = tnbr(d)
			DB:UnregisterPotentialKick(player, b, GetTime())
			DB:EnemyDamage(false, DPSMateEDD, player, c, t[1] or 0, t[2] or 1, 0, 0, 0, 0, t[3], a, t[4] or 0, 0)
			DB:DamageTaken(player, c, t[1] or 0, t[2] or 1, 0, 0, 0, 0, t[3], a, 0)
			DB:DeathHistory(player, a, c, t[3], t[1] or 0, t[2] or 1, 0, 0)
			if self.FailDT[b] then DB:BuildFail(2, a, player, c, t[3]) end
			return
		end
		for a,b,c,d in strgfind(msg, "(.+) trifft Euch mit %'(.+)%' für (%d+)(.*)") do -- Potential here to track school and resisted damage
			--if c=="kritisch" then t[1]=1;t[2]=0 end
			--if strfind(e, "geblockt") then t[4]=1 end
			t[3] = tnbr(c)
			DB:UnregisterPotentialKick(player, b, GetTime())
			DB:EnemyDamage(false, DPSMateEDD, player, b, t[1] or 1, 0, 0, 0, 0, 0, t[3], a, t[4] or 0, 0)
			DB:DamageTaken(player, b, t[1] or 1, 0, 0, 0, 0, 0, t[3], a, 0)
			DB:DeathHistory(player, a, b, t[3], t[1] or 1, 0, 0, 0)
			if self.FailDT[b] then DB:BuildFail(2, a, player, b, t[3]) end
			return
		end
		for a,b,c,d in strgfind(msg, "(.+)s (.+) trifft Euch kritisch für (%d+)(.*)") do -- Potential here to track school and resisted damage
			--if c=="kritisch" then t[1]=1;t[2]=0 end
			--if strfind(e, "geblockt") then t[4]=1 end
			t[3] = tnbr(c)
			DB:UnregisterPotentialKick(player, b, GetTime())
			DB:EnemyDamage(false, DPSMateEDD, player, b, 0, 1, 0, 0, 0, 0, t[3], a, t[4] or 0, 0)
			DB:DamageTaken(player, b, 0, 1, 0, 0, 0, 0, t[3], a, 0)
			DB:DeathHistory(player, a, b, t[3], 0, 1, 0, 0)
			if self.FailDT[b] then DB:BuildFail(2, a, player, b, t[3]) end
			return
		end
		for a,b in strgfind(msg, "(.+) greift an %(mit (.+)%) und verfehlt Euch%.") do
			DB:EnemyDamage(false, DPSMateEDD, player, b, 0, 0, 1, 0, 0, 0, 0, a, 0, 0)
			DB:DamageTaken(player, b, 0, 0, 1, 0, 0, 0, 0, a, 0)
			return
		end
		for a,b in strgfind(msg, "(.+)s (.+) wurde pariert%.") do
			DB:EnemyDamage(false, DPSMateEDD, player, b, 0, 0, 0, 1, 0, 0, 0, a, 0, 0)
			DB:DamageTaken(player, b, 0, 0, 0, 1, 0, 0, 0, a, 0)
			return
		end
		for a,b in strgfind(msg, "(.+)s (.+) wurde ausgewichen%.") do
			DB:EnemyDamage(false, DPSMateEDD, player, b, 0, 0, 0, 0, 1, 0, 0, a, 0, 0)
			DB:DamageTaken(player, b, 0, 0, 0, 0, 1, 0, 0, a, 0)
			return
		end
		for a,b in strgfind(msg, "(.+) versucht es mit (.+)%.%.%. widerstanden%.") do
			DB:EnemyDamage(false, DPSMateEDD, player, b, 0, 0, 0, 0, 0, 1, 0, a, 0, 0)
			DB:DamageTaken(player, b, 0, 0, 0, 0, 0, 1, 0, a, 0)
			return
		end
		for a,b in strgfind(msg, "(.+)s (.+) wurde geblockt%.") do
			DB:EnemyDamage(false, DPSMateEDD, player, b, 0, 0, 0, 0, 0, 0, 0, a, 1, 0)
			DB:DamageTaken(player, b, 0, 0, 0, 0, 0, 0, 0, a, 1)
			return
		end
	end
	
	DPSMate.Parser.PeriodicSelfDamage = function(self, msg)
		t = {}
		for a,b,c,d,e in strgfind(msg, "Ihr erleidet (%d+) (%a+) von (.+) %(durch (.+)%)%.(.*)") do -- Potential to track school and resisted damage
			t[1] = tnbr(a)
			DB:EnemyDamage(false, DPSMateEDD, player, d.."(Periodisch)", 1, 0, 0, 0, 0, 0, t[1], c, 0, 0)
			DB:DamageTaken(player, d.."(Periodisch)", 1, 0, 0, 0, 0, 0, t[1], c, 0)
			DB:DeathHistory(player, c, d.."(Periodisch)", t[1], 1, 0, 0, 0)
			if self.FailDT[d] then DB:BuildFail(2, c, player, d, t[1]) end
			return
		end
		for a in strgfind(msg, "Ihr seid von (.+) betroffen%.") do
			DB:BuildBuffs("Unbekannt", player, a, false)
			if self.CC[a] then DB:BuildActiveCC(player, a) end
			return
		end
		for a,b,d,e in strgfind(msg, "Ihr erleidet (%d+) Punkte (%a+) %(durch (.+)%)%.(.*)") do -- Potential to track school and resisted damage
			t[1] = tnbr(a)
			DB:EnemyDamage(false, DPSMateEDD, player, d.."(Periodisch)", 1, 0, 0, 0, 0, 0, t[1], player, 0, 0)
			DB:DamageTaken(player, d.."(Periodisch)", 1, 0, 0, 0, 0, 0, t[1], player, 0)
			DB:DeathHistory(player, player, d.."(Periodisch)", t[1], 1, 0, 0, 0)
			return
		end
	end
	
	DPSMate.Parser.CreatureVsCreatureHits = function(self, msg) 
		t = {}
		for a,c,d,e in strgfind(msg, "(.+) trifft (.+) kritisch für (%d+)(.*)") do
			if strfind(e, "schmetternd") then t[3]=1;t[1]=0;t[2]=0 elseif strfind(e, "geblockt") then t[4]=1;t[1]=0;t[2]=0 end
			t[5] = tnbr(d)
			DB:EnemyDamage(false, DPSMateEDD, c, "Angreifen", 0, t[2] or 1, 0, 0, 0, 0, t[5], a, t[4] or 0, t[3] or 0)
			DB:DamageTaken(c, "Angreifen", 0, t[2] or 1, 0, 0, 0, 0, t[5], a, t[3] or 0)
			DB:DeathHistory(c, a, "Angreifen", t[5], 0, t[2] or 1, 0, t[3] or 0)
			return
		end
		for a,c,d,e in strgfind(msg, "(.+) trifft (.+) für (%d+)(.*)") do
			if strfind(e, "schmetternd") then t[3]=1;t[1]=0;t[2]=0 elseif strfind(e, "geblockt") then t[4]=1;t[1]=0;t[2]=0 end
			t[5] = tnbr(d)
			DB:EnemyDamage(false, DPSMateEDD, c, "Angreifen", t[1] or 1, 0, 0, 0, 0, 0, t[5], a, t[4] or 0, t[3] or 0)
			DB:DamageTaken(c, "Angreifen", t[1] or 1, 0, 0, 0, 0, 0, t[5], a, t[3] or 0)
			DB:DeathHistory(c, a, "Angreifen", t[5], t[1] or 1, 0, 0, t[3] or 0)
			return
		end
	end
	
	-- X verfehlt Y.
	-- X greift an. Y weicht aus.
	-- X greift an. Y pariert.
	DPSMate.Parser.CreatureVsCreatureMisses = function(self, msg)
		t = {}
		for c, ta in strgfind(msg, "(.+) greift an%. (.+) absorbiert allen Schaden%.") do DB:Absorb("Angreifen", ta, c); return end
		for a,b,c in strgfind(msg, "(.+) greift an%. (.-) (.+)%.") do 
			if c=="pariert" then t[1]=1 elseif c=="weicht aus" then t[2]=1 else t[3]=1 end 
			DB:EnemyDamage(false, DPSMateEDD, b, "Angreifen", 0, 0, 0, t[1] or 0, t[2] or 0, 0, 0, a, t[3] or 0, 0)
			DB:DamageTaken(b, "Angreifen", 0, 0, 0, t[1] or 0, t[2] or 0, 0, 0, a, 0)
			return
		end
		for a,b in strgfind(msg, "(.+) verfehlt (.+)%.") do 
			DB:EnemyDamage(false, DPSMateEDD, b, "Angreifen", 0, 0, 1, 0, 0, 0, 0, a, 0, 0)
			DB:DamageTaken(b, "Angreifen", 0, 0, 1, 0, 0, 0, 0, a, 0)
			return 
		end
	end
	
	DPSMate.Parser.SpellPeriodicDamageTaken = function(self, msg)
		t = {}
		for a,b,c,d,e,f in strgfind(msg, "(.+) erleidet (%d+) (%a+) von (.+) %(durch (.+)%)%.(.*)") do -- Potential to track resisted damage and school
			t[1] = tnbr(b)
			DB:EnemyDamage(false, DPSMateEDD, a, e.."(Periodisch)", 1, 0, 0, 0, 0, 0, t[1], d, 0, 0)
			DB:DamageTaken(a, e.."(Periodisch)", 1, 0, 0, 0, 0, 0, t[1], d, 0)
			DB:DeathHistory(a, d, e.."(Periodisch)", t[1], 1, 0, 0, 0)
			if self.FailDT[e] then DB:BuildFail(2, d, a, e, t[1]) end
			return
		end
		for a, b in strgfind(msg, "(.+) ist von (.+) betroffen%.") do
			DB:BuildBuffs("Unbekannt", a, b, false)
			if self.CC[b] then DB:BuildActiveCC(a, b) end
			return
		end
	end
	
	-- Xs Y trifft Z für d+ Heiligschaden.
	-- Xs Y trifft Z kritisch für d+ Heiligschaden.
	DPSMate.Parser.CreatureVsCreatureSpellDamage = function(self, msg)
		t = {}
		for a,b,d,e,f in strgfind(msg, "(.+)s (.+) trifft (.+) kritisch für (%d+)(.*)") do
			if strfind(f, "geblockt") then t[4]=1;t[2]=0 end
			t[3] = tnbr(e)
			DB:UnregisterPotentialKick(d, b, GetTime())
			DB:EnemyDamage(false, DPSMateEDD, d, b, 0, t[2] or 1, 0, 0, 0, 0, t[3], a, t[4] or 0, 0)
			DB:DamageTaken(d, b, 0, t[2] or 1, 0, 0, 0, 0, t[3], a, 0)
			DB:DeathHistory(d, a, b, t[3], 0, t[2] or 1, 0, 0)
			if self.FailDT[b] then DB:BuildFail(2, a, d, b, t[3]) end
			return
		end
		for a,b,d,e,f in strgfind(msg, "(.+)s (.+) trifft (.+) für (%d+)(.*)") do
			if strfind(f, "geblockt") then t[4]=1;t[1]=0 end
			t[3] = tnbr(e)
			DB:UnregisterPotentialKick(d, b, GetTime())
			DB:EnemyDamage(false, DPSMateEDD, d, b, t[1] or 1, 0, 0, 0, 0, 0, t[3], a, t[4] or 0, 0)
			DB:DamageTaken(d, b, t[1] or 1, 0, 0, 0, 0, 0, t[3], a, 0)
			DB:DeathHistory(d, a, b, t[3], t[1] or 1, 0, 0, 0)
			if self.FailDT[b] then DB:BuildFail(2, a, d, b, t[3]) end
			return
		end
		for c,b,a in strgfind(msg, "(.+) ist (.+) von (.+) ausgewichen%.") do
			DB:EnemyDamage(false, DPSMateEDD, c, b, 0, 0, 0, 0, 1, 0, 0, a, 0, 0)
			DB:DamageTaken(c, b, 0, 0, 0, 0, 1, 0, 0, a, 0)
			return
		end
		for b,a,c in strgfind(msg, "(.+) von (.+) wurde von (.+) pariert%.") do
			DB:EnemyDamage(false, DPSMateEDD, c, b, 0, 0, 0, 1, 0, 0, 0, a, 0, 0)
			DB:DamageTaken(c, b, 0, 0, 0, 1, 0, 0, 0, a, 0)
			return
		end
		for b,a,c in strgfind(msg, "(.+) von (.+) verfehlt (.+)%.") do
			DB:EnemyDamage(false, DPSMateEDD, c, b, 0, 0, 1, 0, 0, 0, 0, a, 0, 0)
			DB:DamageTaken(c, b, 0, 0, 1, 0, 0, 0, 0, a, 0)
			return
		end
		for a,b,c in strgfind(msg, "(.+)s (.+) wurde von (.+) widerstanden%.") do
			DB:EnemyDamage(false, DPSMateEDD, c, b, 0, 0, 0, 0, 0, 1, 0, a, 0, 0)
			DB:DamageTaken(c, b, 0, 0, 0, 0, 0, 1, 0, a, 0)
			return
		end
	end

	----------------------------------------------------------------------------------
	--------------                       Healing                        --------------                                  
	----------------------------------------------------------------------------------
	
	-- Kritische Heilung: X heilt Y um d+ Punkte.
	-- X heilt Y um d+ Punkte.
	-- Energiegeladene Rüstung des Schurken.
	DPSMate.Parser.SpellSelfBuff = function(self, msg)
		t = {}
		for a,b,c in strgfind(msg, "Kritische Heilung: (.+) heilt (.+) um (%d+) Punkte.") do 
			if b=="Euch" then t[1]=player end
			t[2] = tnbr(c)
			overheal = self:GetOverhealByName(t[2], t[1] or b)
			DB:HealingTaken(DPSMateHealingTaken, t[1] or b, a, 0, 1, t[2], player)
			DB:HealingTaken(DPSMateEHealingTaken, t[1] or b, a, 0, 1, t[2]-overheal, player)
			DB:Healing(0, DPSMateEHealing, player, a, 0, 1, t[2]-overheal, t[1] or b)
			if overheal>0 then DB:Healing(2, DPSMateOverhealing, player, a, 0, 1, overheal, t[1] or b) end
			DB:Healing(1, DPSMateTHealing, player, a, 0, 1, t[2], t[1] or b)
			DB:DeathHistory(t[1] or b, player, a, t[2], 0, 1, 1, 0)
			return
		end
		for a,b,c in strgfind(msg, "(.+) heilt (.+) um (%d+) Punkte%.") do 
			if b=="Euch" then t[1]=player end
			t[2] = tnbr(c)
			overheal = self:GetOverhealByName(t[2], t[1] or b)
			DB:HealingTaken(DPSMateHealingTaken, t[1] or b, a, 1, 0, t[2], player)
			DB:HealingTaken(DPSMateEHealingTaken, t[1] or b, a, 1, 0, t[2]-overheal, player)
			DB:Healing(0, DPSMateEHealing, player, a, 1, 0, t[2]-overheal, t[1] or b)
			if overheal>0 then DB:Healing(2, DPSMateOverhealing, player, a, 1, 0, overheal, t[1] or b) end
			DB:Healing(1, DPSMateTHealing, player, a, 1, 0, t[2], t[1] or b)
			DB:DeathHistory(t[1] or b, player, a, t[2], 1, 0, 1, 0)
			return
		end
		for a,b in strgfind(msg, "Ihr bekommt (%d+) Energie durch (.+)%.") do -- Potential to gain energy values for class evaluation
			DB:BuildBuffs(player, player, b, true)
			DB:DestroyBuffs(player, b)
			return
		end
		for b,a in strgfind(msg, "Ihr bekommt durch (.+) (%d) Extra-Angriff%.") do -- Potential for more evaluation
			DB:BuildBuffs(player, player, b, true)
			DB:DestroyBuffs(player, b)
			return
		end	
	end
	
	-- Ihr erhaltet d+ Gesundheit durch X.
	DPSMate.Parser.SpellPeriodicSelfBuff = function(self, msg) -- Maybe some loss here?
		t = {}
		for a,b,c in strgfind(msg, "Ihr erhaltet (%d+) Gesundheit von (.+) %(durch (.+)%)%.") do
			t[1]=tnbr(a)
			overheal = self:GetOverhealByName(t[1], player)
			DB:HealingTaken(DPSMateHealingTaken, player, c.."(Periodisch)", 1, 0, t[1], b)
			DB:HealingTaken(DPSMateEHealingTaken, player, c.."(Periodisch)", 1, 0, t[1]-overheal, b)
			DB:Healing(0, DPSMateEHealing, b, c.."(Periodisch)", 1, 0, t[1]-overheal, player)
			if overheal>0 then DB:Healing(2, DPSMateOverhealing, b, c.."(Periodisch)", 1, 0, overheal, player) end
			DB:Healing(1, DPSMateTHealing, b, c.."(Periodisch)", 1, 0, t[1], player)
			DB:DeathHistory(player, b, c.."(Periodisch)", t[1], 1, 0, 1, 0)
			return
		end
		for a,b in strgfind(msg, "Ihr erhaltet (%d+) Gesundheit von (.+)%.") do 
			t[1] = tnbr(a)
			overheal = self:GetOverhealByName(t[1], player)
			DB:HealingTaken(DPSMateHealingTaken, player, b.."(Periodisch)", 1, 0, t[1], player)
			DB:HealingTaken(DPSMateEHealingTaken, player, b.."(Periodisch)", 1, 0, t[1]-overheal, player)
			DB:Healing(0, DPSMateEHealing, player, b.."(Periodisch)", 1, 0, t[1]-overheal, player)
			if overheal>0 then DB:Healing(2, DPSMateOverhealing, player, b.."(Periodisch)", 1, 0, overheal, player) end
			DB:Healing(1, DPSMateTHealing, player, b.."(Periodisch)", 1, 0, t[1], player)
			DB:DeathHistory(player, player, b.."(Periodisch)", t[1], 1, 0, 1, 0)
			return
		end
		for a in strgfind(msg, "Ihr bekommt %'(.+)%'%.") do
			if strfind(a, "von") then return end
			if strfind(a, "%(") then a=strsub(a, 1, strfind(a, "%(")-2) end -- Unstable Power (12)
			DB:ConfirmBuff(player, a, GetTime())
			if DPSMate.Parser.Dispels[a] then 
				DB:RegisterHotDispel(player, a)
				--DB:AwaitDispel(a, player, "Unknown", GetTime());
			end
			if self.RCD[a] then DPSMate:Broadcast(1, player, a) end
			if self.FailDB[a] then DB:BuildFail(3, "Umgebung", player, a, 0) end
			return 
		end
	end
	
	DPSMate.Parser.SpellPeriodicFriendlyPlayerBuffs = function(self, msg)
		t = {}
		for f,a,b,c in strgfind(msg, "(.+) erhält (%d+) Gesundheit von (.+)s (.+)%.") do
			t[1]=tnbr(a)
			overheal = self:GetOverhealByName(t[1], f)
			DB:HealingTaken(DPSMateHealingTaken, f, c.."(Periodisch)", 1, 0, t[1], b)
			DB:HealingTaken(DPSMateEHealingTaken, f, c.."(Periodisch)", 1, 0, t[1]-overheal, b)
			DB:Healing(0, DPSMateEHealing, b, c.."(Periodisch)", 1, 0, t[1]-overheal, f)
			if overheal>0 then DB:Healing(2, DPSMateOverhealing, b, c.."(Periodisch)", 1, 0, overheal, f) end
			DB:Healing(1, DPSMateTHealing, b, c.."(Periodisch)", 1, 0, t[1], f)
			DB:DeathHistory(f, b, c.."(Periodisch)", t[1], 1, 0, 1, 0)
			return
		end
		for f,a,b in strgfind(msg, "(.+) erhält (%d+) Gesundheit durch (.+)%.") do 
			t[1] = tnbr(a)
			overheal = self:GetOverhealByName(t[1], f)
			DB:HealingTaken(DPSMateHealingTaken, f, b.."(Periodisch)", 1, 0, t[1], player)
			DB:HealingTaken(DPSMateEHealingTaken, f, b.."(Periodisch)", 1, 0, t[1]-overheal, player)
			DB:Healing(0, DPSMateEHealing, player, b.."(Periodisch)", 1, 0, t[1]-overheal)
			if overheal>0 then DB:Healing(2, DPSMateOverhealing, player, b.."(Periodisch)", 1, 0, overheal) end
			DB:Healing(1, DPSMateTHealing, player, b.."(Periodisch)", 1, 0, t[1])
			DB:DeathHistory(f, player, b.."(Periodisch)", t[1], 1, 0, 1, 0)
			return
		end
		for f,a in strgfind(msg, "(.+) bekommt %'(.+)%'%.") do
			if strfind(a, "von") then return end
			if strfind(a, "%(") then a=strsub(a, 1, strfind(a, "%(")-2) end -- Unstable Power (12)
			DB:ConfirmBuff(f, a, GetTime())
			if DPSMate.Parser.Dispels[a] then
				DB:RegisterHotDispel(f, a)
				--DB:AwaitDispel(a, f, "Unknown", GetTime());
			end
			if self.RCD[a] then DPSMate:Broadcast(1, f, a) end
			if self.FailDB[a] then DB:BuildFail(3, "Umgebung", f, a, 0) end
			return 
		end
	end
	
	-- Xs Y heilt Z um d+ Punkte.
	-- X benutzt Y und heilt Euch um 867 Punkte.
	-- Kritische Heilung: Xs Y heilt Z um d+ Punkte.
	-- Kritische Heilung: Xs Y heilt Euch um d+ Punkte.
	DPSMate.Parser.SpellHostilePlayerBuff = function(self, msg)
		t = {}
		for a,b,c,d in strgfind(msg, "Kritische Heilung: (.+)s (.+) heilt (.+) um (%d+) Punkte%.") do 
			t[1] = tnbr(d)
			if c=="Euch" then t[2]=player end
			overheal = self:GetOverhealByName(t[1], t[2] or c)
			DB:HealingTaken(DPSMateHealingTaken, t[2] or c, b, 0, 1, t[1], a)
			DB:HealingTaken(DPSMateEHealingTaken, t[2] or c, b, 0, 1, t[1]-overheal, a)
			DB:Healing(0, DPSMateEHealing, a, b, 0, 1, t[1]-overheal, t[2] or c)
			if overheal>0 then DB:Healing(2, DPSMateOverhealing, a, b, 0, 1, overheal, t[2] or c) end
			DB:Healing(1, DPSMateTHealing, a, b, 0, 1, t[1], t[2] or c)
			DB:DeathHistory(t[2] or c, a, b, t[1], 0, 1, 1, 0)
			return
		end
		for a,b,c,d in strgfind(msg, "(.+)s (.+) heilt (.+) um (%d+) Punkte%.") do 
			t[1] = tnbr(d)
			overheal = self:GetOverhealByName(t[1], t[2] or c)
			DB:HealingTaken(DPSMateHealingTaken, t[2] or c, b, 1, 0, t[1], a)
			DB:HealingTaken(DPSMateEHealingTaken, t[2] or c, b, 1, 0, t[1]-overheal, a)
			DB:Healing(0, DPSMateEHealing, a, b, 1, 0, t[1]-overheal, t[2] or c)
			if overheal>0 then DB:Healing(2, DPSMateOverhealing, a, b, 1, 0, overheal, t[2] or c) end
			DB:Healing(1, DPSMateTHealing, a, b, 1, 0, t[1], t[2] or c)
			DB:DeathHistory(t[2] or c, a, b, t[1], 1, 0, 1, 0)
			return
		end
		for a,b,d in strgfind(msg, "(.+) benutzt (.+) und heilt Euch um (%d+) Punkte%.") do 
			t[1] = tnbr(d)
			overheal = self:GetOverhealByName(t[1], player)
			DB:HealingTaken(DPSMateHealingTaken, player, b, 1, 0, t[1], a)
			DB:HealingTaken(DPSMateEHealingTaken, player, b, 1, 0, t[1]-overheal, a)
			DB:Healing(0, DPSMateEHealing, a, b, 1, 0, t[1]-overheal, player)
			if overheal>0 then DB:Healing(2, DPSMateOverhealing, a, b, 1, 0, overheal, player) end
			DB:Healing(1, DPSMateTHealing, a, b, 1, 0, t[1], player)
			DB:DeathHistory(player, a, b, t[1], 1, 0, 1, 0)
			return
		end
		for a,b,c,d in strgfind(msg, "(.+) gains (%d+) Energy from (.+)'s (.+)%.") do
			DB:BuildBuffs(c, a, d, true)
			DB:DestroyBuffs(c, d)
			return 
		end
		for a,c,b in strgfind(msg, "(.+) bekommt durch (.+) (%d+) Extra-Angriff%.") do
			DB:BuildBuffs(a, a, c, true)
			DB:DestroyBuffs(a, c)
			return 
		end
	end
	
	----------------------------------------------------------------------------------
	--------------                       Absorbs                        --------------                                  
	----------------------------------------------------------------------------------
	
	-- X trifft Y für d+ Schaden. (d+ absorbiert)
	DPSMate.Parser.CreatureVsSelfHitsAbsorb = function(self, msg)
		for c, b, absorbed in strgfind(msg, "(.+) trifft Euch für (%d+) Schaden%. %((%d+) absorbiert%)") do DB:SetUnregisterVariables(tnbr(absorbed), "Angreifen", c); return end
		for c, b, absorbed in strgfind(msg, "(.+) trifft Euch kritisch für (%d+) Schaden%. %((%d+) absorbiert%)") do DB:SetUnregisterVariables(tnbr(absorbed), "Angreifen", c); return end
	end
	
	DPSMate.Parser.CreatureVsCreatureHitsAbsorb = function(self, msg)
		for c, b, a, absorbed in strgfind(msg, "(.+) trifft (.+) für (%d+) Schaden%. %((%d+) absorbiert%)") do DB:SetUnregisterVariables(tnbr(absorbed), "Angreifen", c); return end
	end
	
	DPSMate.Parser.CreatureVsSelfSpellDamageAbsorb = function(self, msg)
		for c, q, ab, b, a, absorbed in strgfind(msg, "(.+) trifft Euch(.*) mit %'(.+)%' für (.+)%. %((%d+) absorbiert%)") do DB:SetUnregisterVariables(tnbr(absorbed), ab, c); return end
	end
	
	DPSMate.Parser.CreatureVsCreatureSpellDamageAbsorb = function(self, msg)
		for c, ab, b, a, x, absorbed in strgfind(msg, "(.+)s (.+) trifft (.+) für (.+)%. %((%d+) absorbiert%)") do DB:SetUnregisterVariables(tnbr(absorbed), ab, c); return end
	end
	
	DPSMate.Parser.SpellPeriodicSelfBuffAbsorb = function(self, msg)
		for ab in strgfind(msg, "Ihr bekommt %'(.+)%'%.") do if DB.ShieldFlags[ab] then DB:ConfirmAbsorbApplication(ab, player, GetTime()) end end
	end

	DPSMate.Parser.SpellPeriodicFriendlyPlayerBuffsAbsorb = function(self, msg)
		for ta, ab in strgfind(msg, "(.+) bekommt %'(.+)%'%.") do if DB.ShieldFlags[ab] then DB:ConfirmAbsorbApplication(ab, ta, GetTime()) end end
	end
	
	DPSMate.Parser.SpellAuraGoneSelf = function(self, msg)
		for ab in strgfind(msg, "%'(.+)%' schwindet von Euch%.") do if DB.ShieldFlags[ab] then DB:UnregisterAbsorb(ab, player) end; if self.RCD[ab] then DPSMate:Broadcast(6, player, ab) end; DB:DestroyBuffs(player, ab); DB:UnregisterHotDispel(player, ab); DB:RemoveActiveCC(player, ab) end
	end
	
	DPSMate.Parser.SpellAuraGoneParty = function(self, msg)
		for ab, ta in strgfind(msg, "%'(.+)%' schwindet von (.+)%.") do if DB.ShieldFlags[ab] then DB:UnregisterAbsorb(ab, ta) end; if self.RCD[ab] then DPSMate:Broadcast(6, ta, ab) end; DB:DestroyBuffs(ta, ab); DB:UnregisterHotDispel(ta, ab); DB:RemoveActiveCC(ta, ab) end
	end
	
	DPSMate.Parser.SpellAuraGoneOther = function(self, msg)
		for ab, ta in strgfind(msg, "%'(.+)%' schwindet von (.+)%.") do if DB.ShieldFlags[ab] then DB:UnregisterAbsorb(ab, ta) end; if self.RCD[ab] then DPSMate:Broadcast(6, ta, ab) end; DB:DestroyBuffs(ta, ab); DB:UnregisterHotDispel(ta, ab); DB:RemoveActiveCC(ta, ab) end
	end
	
	----------------------------------------------------------------------------------
	--------------                       Dispels                        --------------                                  
	----------------------------------------------------------------------------------
	
	DPSMate.Parser.SpellSelfBuffDispels = function(self, msg)
		for ab, tar in strgfind(msg, "Ihr wirkt (.+) auf (.+)%.") do if DPSMate.Parser.Dispels[ab] then DB:AwaitDispel(ab, tar, player, GetTime()) end; if self.RCD[ab] then DPSMate:Broadcast(2, player, tar, ab) end; return end
		for ab in strgfind(msg, "Ihr wirkt (.+)%.") do if DPSMate.Parser.Dispels[ab] then DB:AwaitDispel(ab, "Unbekannt", player, GetTime()) end; return end
	end
	
	DPSMate.Parser.SpellHostilePlayerBuffDispels = function(self, msg)
		for c, ab, ta in strgfind(msg, "(.+) wirkt (.+) auf (.+)%.") do if ta=="Euch" then ta = player end; if DPSMate.Parser.Dispels[ab] then DB:AwaitDispel(ab, ta, c, GetTime()) end; if self.RCD[ab] then DPSMate:Broadcast(2, c, ta, ab) end; return end
		for c, ab in strgfind(msg, "(.+) wirkt (.+)%.") do if DPSMate.Parser.Dispels[ab] then DB:AwaitDispel(ab, "Unbekannt", c, GetTime()) end; return end
	end
	
	DPSMate.Parser.SpellBreakAura = function(self, msg) 
		for ab, ta in strgfind(msg, "%'(.+)%' von (.+) wurde entfernt%.") do DB:ConfirmRealDispel(ab, ta, GetTime()); return end
		for ab in strgfind(msg, "(.+) wurde entfernt%.") do DB:ConfirmRealDispel(ab, player, GetTime()); return end
	end
	
	----------------------------------------------------------------------------------
	--------------                       Deaths                         --------------                                  
	----------------------------------------------------------------------------------

	DPSMate.Parser.CombatFriendlyDeath = function(self, msg)
		for ta,kind in strgfind(msg, "(.-) (.-)%.") do if ta=="Ihr" then DB:UnregisterDeath(player) else DB:UnregisterDeath(ta) end end
	end

	DPSMate.Parser.CombatHostileDeaths = function(self, msg)
		for ta in strgfind(msg, "(.+) stirbt%.") do 
			DB:UnregisterDeath(ta)
			DB:Attempt(false, true, ta)
		end
	end
	
	----------------------------------------------------------------------------------
	--------------                     Interrupts                       --------------                                  
	----------------------------------------------------------------------------------

	DPSMate.Parser.CreatureVsCreatureSpellDamageInterrupts = function(self, msg)
		for c, ab in strgfind(msg, "(.+) beginnt (.+) zu wirken%.") do DB:RegisterPotentialKick(c, ab, GetTime()); return end
		--for c, ab in strgfind(msg, "(.+) begins to perform (.+)%.") do DB:RegisterPotentialKick(c, ab, GetTime()) end -- Nicht genutzt für die deutsche Sprache?
	end
	DPSMate.Parser.HostilePlayerSpellDamageInterrupts = function(self, msg)
		for c, ab in strgfind(msg, "(.-) beginnt (.+) zu wirken%.") do DB:RegisterPotentialKick(c, ab, GetTime()); return end
		--for c, ab in strgfind(msg, "(.-) begins to perform (.+)%.") do DB:RegisterPotentialKick(c, ab, GetTime()) end
	end
	
	local linkQuality = {
		["9d9d9d"] = 0,
		["ffffff"] = 1,
		["1eff00"] = 2,
		["0070dd"] = 3,
		["a335ee"] = 4,
		["ff8000"] = 5
	}
	DPSMate.Parser.Loot = function(self, msg)
		for a,b,c,d,e in strgfind(msg, "(.-) bekommt Beute: |cff(.-)|Hitem:(%d+)(.+)%[(.+)%]|h|r") do
			DB:Loot(a, linkQuality[b], tnbr(c), e)
			return
		end
		for a,b,c,d in strgfind(msg, "Ihr erhaltet Beute: |cff(.-)|Hitem:(%d+)(.+)%[(.+)%]|h|r") do
			DB:Loot(player, linkQuality[a], tnbr(b), d)
			return
		end
	end
	
	-- Pet section

	DPSMate.Parser.PetHits = function(self, msg)
		t = {}
		for a,b,c,d in strgfind(msg, "(.-) trifft (.+) kritisch für (%d+) Schaden\.%s?(.*)") do
			if d=="(gestreift)" then t[1]=1;t[3]=0 elseif d~="" then t[2]=1;t[3]=0 end
			t[5] = tnbr(c)
			DB:EnemyDamage(true, DPSMateEDT, a, "Angreifen", 0, t[3] or 1, 0, 0, 0, 0, t[5], b, t[2] or 0, t[1] or 0)
			DB:DamageDone(a, "Angreifen", 0, t[3] or 1, 0, 0, 0, 0, t[5], t[1] or 0, t[2] or 0)
			if self.TargetParty[a] and self.TargetParty[b] then DB:BuildFail(1, b, a, "Angreifen", t[5]) end
			return
		end
		for a,b,c,d in strgfind(msg, "(.-) trifft (.+) für (%d+) Schaden\.%s?(.*)") do
			if d=="(gestreift)" then t[1]=1;t[3]=0 elseif d~="" then t[2]=1;t[3]=0 end
			if b=="Euch" then b=player end
			t[5] = tnbr(c)
			DB:EnemyDamage(true, DPSMateEDT, a, "Angreifen", t[3] or 1, 0, 0, 0, 0, 0, t[5], b, t[2] or 0, t[1] or 0)
			DB:DamageDone(a, "Angreifen", t[3] or 1, 0, 0, 0, 0, 0, t[5], t[1] or 0, t[2] or 0)
			if self.TargetParty[a] and self.TargetParty[b] then DB:BuildFail(1, b, a, "Angreifen", t[5]) end
			return
		end
		for a,c,d in strgfind(msg, "(.-) trifft Euch kritisch: (%d+) Schaden\.%s?(.*)") do
			if d=="(gestreift)" then t[1]=1;t[3]=0 elseif d~="" then t[2]=1;t[3]=0 end
			t[5] = tnbr(c)
			DB:EnemyDamage(true, DPSMateEDT, a, "Angreifen", 0, t[3] or 1, 0, 0, 0, 0, t[5], player, t[2] or 0, t[1] or 0)
			DB:DamageDone(a, "Angreifen", 0, t[3] or 1, 0, 0, 0, 0, t[5], t[1] or 0, t[2] or 0)
			if self.TargetParty[a] then DB:BuildFail(1, player, a, "Angreifen", t[5]) end
			return
		end
	end

	DPSMate.Parser.PetMisses = function(self, msg)
		t = {}
		for a,b in strgfind(msg, "(.-) verfehlt (.+)%.") do 
			if b=="Euch" then b=player end
			DB:EnemyDamage(true, DPSMateEDT, a, "Angreifen", 0, 0, 1, 0, 0, 0, 0, b, 0, 0)
			DB:DamageDone(a, "Angreifen", 0, 0, 1, 0, 0, 0, 0, 0, 0)
			return
		end
		for a,b in strgfind(msg, "(.-) greift an%. (.+) weicht aus%.") do 
			if b=="Ihr" then b=player end
			DB:EnemyDamage(true, DPSMateEDT, a, "Angreifen", 0, 0, 0, 0, 1, 0, 0, b, 0, 0)
			DB:DamageDone(a, "Angreifen", 0, 0, 0, 0, 1, 0, 0, 0, 0)
			return
		end
		for a,b in strgfind(msg, "(.-) greift an%. (.+) pariert%.") do 
			if b=="Ihr" then b=player end
			DB:EnemyDamage(true, DPSMateEDT, a, "Angreifen", 0, 0, 0, 1, 0, 0, 0, b, 0, 0)
			DB:DamageDone(a, "Angreifen", 0, 0, 0, 1, 0, 0, 0, 0, 0)
			return
		end
		for a,b in strgfind(msg, "(.-) greift an%. (.+) blockt%.") do 
			if b=="Ihr" then b=player end
			DB:EnemyDamage(true, DPSMateEDT, a, "Angreifen", 0, 0, 0, 0, 0, 0, 0, b, 1, 0)
			DB:DamageDone(a, "Angreifen", 0, 0, 0, 0, 0, 0, 0, 0, 1)
			return
		end
	end

	-- Marktast casts bla on bla.
	DPSMate.Parser.PetSpellDamage = function(self, msg)
		t = {}
		for f,a,b,c,d,e in strgfind(msg, "(.+)s (.+) trifft (.+) kritisch für (%d+)(.*)\.%s?(.*)") do 
			t[1] = tnbr(c)
			if strfind(e, "geblockt") then t[4]=1;t[2]=0;end
			if DPSMate.Parser.Kicks[a] then DB:AssignPotentialKick(f, a, c, GetTime()) end
			if DPSMate.Parser.DmgProcs[a] then DB:BuildBuffs(f, f, a, true) end
			DB:EnemyDamage(true, DPSMateEDT, f, a,  0, t[2] or 1, 0, 0, 0, 0, t[1], b, t[4] or 0, 0)
			DB:DamageDone(f, a, 0, t[2] or 1, 0, 0, 0, 0, t[1], 0, t[4] or 0)
			if self.TargetParty[b] and self.TargetParty[f] then DB:BuildFail(1, b, f, a, t[1]) end
			return
		end
		for f,a,b,c,d,e in strgfind(msg, "(.+)s (.+) trifft (.+) für (%d+)(.*)\.%s?(.*)") do 
			t[1] = tnbr(c)
			if strfind(e, "geblockt") then t[4]=1;t[2]=0;t[3]=0 end
			if DPSMate.Parser.Kicks[a] then DB:AssignPotentialKick(f, a, b, GetTime()) end
			if DPSMate.Parser.DmgProcs[a] then DB:BuildBuffs(f, f, a, true) end
			DB:EnemyDamage(true, DPSMateEDT, f, a,  1, 0, 0, 0, 0, 0, t[1], b, t[4] or 0, 0)
			DB:DamageDone(f, a, 1, 0, 0, 0, 0, 0, t[1], 0, t[4] or 0)
			if self.TargetParty[b] and self.TargetParty[f] then DB:BuildFail(1, b, f, a, t[1]) end
			return
		end
		for a,b,f in strgfind(msg, "(.+) ist (.+) von (.+) ausgewichen%.") do 
			DB:EnemyDamage(true, DPSMateEDT, f, b, 0, 0, 0, 0, 1, 0, 0, a, 0, 0)
			DB:DamageDone(f, b, 0, 0, 0, 0, 1, 0, 0, 0, 0)
			return
		end
		for a,f,b in strgfind(msg, "(.+) von (.+) wurde von (.+) pariert%.") do 
			DB:EnemyDamage(true, DPSMateEDT, f, a, 0, 0, 0, 1, 0, 0, 0, b, 0, 0)
			DB:DamageDone(f, a, 0, 0, 0, 1, 0, 0, 0, 0, 0)
			return
		end
		for a,f,b in strgfind(msg, "(.+) von (.+) verfehlt (.+)%.") do
			DB:EnemyDamage(true, DPSMateEDT, f, a, 0, 0, 1, 0, 0, 0, 0, b, 0, 0)
			DB:DamageDone(f, a, 0, 0, 1, 0, 0, 0, 0, 0, 0)
			return
		end
		for f,a,b in strgfind(msg, "(.+)s (.+) wurde von (.+) widerstanden%.") do
			DB:EnemyDamage(true, DPSMateEDT, f, a, 0, 0, 0, 0, 0, 1, 0, b, 0, 0)
			DB:DamageDone(f, a, 0, 0, 0, 0, 0, 1, 0, 0, 0)
			return
		end
		for a,f,b in strgfind(msg, "(.+) von (.+) wurde von (.+) geblockt%.") do 
			DB:EnemyDamage(true, DPSMateEDT, f, a, 0, 0, 0, 0, 0, 0, 0, b, 1, 0)
			DB:DamageDone(f, a, 0, 0, 0, 0, 0, 0, 0, 0, 1)
			return
		end
	end
end