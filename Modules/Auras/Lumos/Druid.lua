local K = KkthnxUI[1]
local Module = K:GetModule("Auras")

if K.Class ~= "DRUID" then
	return
end

local function UpdateCooldown(button, spellID, texture)
	return Module:UpdateCooldown(button, spellID, texture)
end

local function UpdateBuff(button, spellID, auraID, cooldown, glow)
	return Module:UpdateAura(button, "player", auraID, "HELPFUL", spellID, cooldown, glow)
end

local function UpdateDebuff(button, spellID, auraID, cooldown, glow)
	return Module:UpdateAura(button, "target", auraID, "HARMFUL", spellID, cooldown, glow)
end

local function UpdateSpellStatus(button, spellID)
	button.Icon:SetTexture(GetSpellTexture(spellID))
	if IsSpellUsable(spellID) then
		button.Icon:SetDesaturated(false)
	else
		button.Icon:SetDesaturated(true)
	end
end

function Module:ChantLumos(self)
	local spec = GetSpecialization()
	if spec == 1 then
		UpdateBuff(self.lumos[1], 164545, 164545)
		UpdateBuff(self.lumos[2], 164547, 164547)

		do
			local button = self.lumos[3]
			UpdateSpellStatus(button, 78674)
			button.Count:SetText(floor(UnitPower("player", 8)/40))
		end

		do
			local button = self.lumos[4]
			if IsPlayerSpell(114107) then
				UpdateSpellStatus(button, 191034)
				button.Count:SetText(floor(UnitPower("player", 8)/40))
			elseif IsPlayerSpell(202345) then
				UpdateBuff(button, 279709, 279709)
			else
				UpdateSpellStatus(button, 191034)
				button.Count:SetText(floor(UnitPower("player", 8)/50))
			end
		end

		do
			local button = self.lumos[5]
			if IsPlayerSpell(102560) then
				UpdateBuff(button, 102560, 102560, true, true)
			else
				UpdateBuff(button, 194223, 194223, true, true)
			end
		end
	elseif spec == 2 then
		UpdateDebuff(self.lumos[1], 1822, 155722, false, "END")
		UpdateDebuff(self.lumos[2], 1079, 1079, false, "END")

		do
			local button = self.lumos[3]
			if IsPlayerSpell(155580) then
				UpdateDebuff(button, 155625, 155625, false, "END")
			else
				UpdateBuff(button, 5217, 5217, true, true)
			end
		end

		do
			local button = self.lumos[4]
			if IsPlayerSpell(52610) then
				UpdateBuff(button, 52610, 52610, false, true)
			elseif IsPlayerSpell(202028) then
				UpdateCooldown(button, 202028, true)
			elseif IsPlayerSpell(102543) then
				UpdateBuff(button, 102543, 102543, true, true)
			else
				UpdateBuff(button, 106951, 106951, true, true)
			end
		end

		do
			local button = self.lumos[5]
			if IsPlayerSpell(274837) then
				UpdateCooldown(button, 274837, true)
			elseif IsPlayerSpell(155672) then
				UpdateBuff(button, 145152, 145152)
			else
				UpdateBuff(button, 135700, 135700)
			end
		end
	elseif spec == 3 then
		UpdateBuff(self.lumos[1], 192081, 192081, false, "END")
		UpdateBuff(self.lumos[2], 22842, 22842, true)
		UpdateBuff(self.lumos[3], 22812, 22812, true)

		do
			local button = self.lumos[4]
			if IsPlayerSpell(102558) then
				UpdateBuff(button, 102558, 102558, true)
			elseif IsPlayerSpell(203964) then
				UpdateBuff(button, 213708, 213708)
			else
				UpdateDebuff(button, 192090, 192090)
			end
		end

		UpdateBuff(self.lumos[5], 61336, 61336, true, true)
	elseif spec == 4 then
				do
			local button = self.lumos[1]
			if IsPlayerSpell(207383) then
				UpdateBuff(button, 207383, 207640)
			elseif IsPlayerSpell(102351) then
				UpdateCooldown(button, 102351, true)
			else
				UpdateCooldown(button, 18562, true)
			end
		end

		UpdateCooldown(self.lumos[2], 48438, true)
		A:UpdateAura(self.lumos[3], "target", 102342, "HELPFUL", 102342, true)

		do
			local button = self.lumos[4]
			if IsPlayerSpell(197721) then
				UpdateBuff(button, 197721, 197721, true)
			else
				UpdateBuff(button, 29166, 29166, true, true)
			end
		end

		UpdateBuff(self.lumos[5], 740, 157982, true)
	end
end
