local K = KkthnxUI[1]
local Module = K:GetModule("Auras")

if K.Class ~= "SHAMAN" then
	return
end

local function GetUnitAura(unit, spell, filter)
	return Module:GetUnitAura(unit, spell, filter)
end

local function UpdateCooldown(button, spellID, texture)
	return Module:UpdateCooldown(button, spellID, texture)
end

local function UpdateBuff(button, spellID, auraID, cooldown)
	return Module:UpdateAura(button, "player", auraID, "HELPFUL", spellID, cooldown)
end

local function UpdateDebuff(button, spellID, auraID, cooldown, glow)
	return Module:UpdateAura(button, "target", auraID, "HARMFUL", spellID, cooldown, glow)
end

local function UpdateTotemAura(button, texture, spellID)
	return Module:UpdateTotemAura(button, texture, spellID)
end

function Module:ChantLumos(self)
	local spec = GetSpecialization()
	if spec == 1 then
		UpdateDebuff(self.lumos[1], 188389, 188389, true, "END")
		UpdateBuff(self.lumos[2], 51505, 77762, true)

		do
			local button = self.lumos[3]
			if IsPlayerSpell(260694) then
				UpdateDebuff(button, 260694, 269808, true)
			elseif IsPlayerSpell(117014) then
				UpdateCooldown(button, 117014, true)
			else
				if IsUsableSpell(8042) then
					button.Icon:SetDesaturated(false)
					B.ShowOverlayGlow(button.glowFrame)
				else
					button.Icon:SetDesaturated(true)
					B.HideOverlayGlow(button.glowFrame)
				end
				button.Icon:SetTexture(GetSpellTexture(8042))
			end
		end

		do
			local button = self.lumos[4]
			if IsPlayerSpell(260895) then
				UpdateBuff(button, 260895, 272737)
			elseif IsPlayerSpell(191634) then
				UpdateBuff(button, 191634, 191634, true, true)
			else
				UpdateBuff(button, 114050, 114050, true, true)
			end
		end

		UpdateCooldown(self.lumos[5], 198067, true)
	elseif spec == 2 then
		UpdateBuff(self.lumos[1], 194084, 194084, false, "END")

		do
			local button = self.lumos[2]
			if IsPlayerSpell(210853) then
				UpdateBuff(button, 210853, 196834)
			elseif IsPlayerSpell(210727) then
				UpdateCooldown(button, 187837, true)
			else
				UpdateDebuff(button, 192087, 268429)
			end
		end

		do
			local button = self.lumos[3]
			if IsPlayerSpell(197992) then
				local name, _, duration, expire = GetUnitAura("player", 202004, "HELPFUL")
				if name then
					button.CD:SetCooldown(expire-duration, duration)
					button.CD:Show()
					button.Icon:SetDesaturated(false)
					button.Count:SetText("")
					button.Icon:SetTexture(GetSpellTexture(197992))
				else
					UpdateCooldown(button, 193786, true)
				end
			elseif IsPlayerSpell(262647) then
				UpdateBuff(button, 262647, 262652)
			else
				UpdateCooldown(button, 193786, true)
			end
		end

		do
			local button = self.lumos[4]
			if IsPlayerSpell(197211) then
				UpdateBuff(button, 197211, 197211)
			elseif IsPlayerSpell(197214) then
				UpdateCooldown(button, 197214, true)
			else
				UpdateCooldown(button, 187874, true)
			end
		end

		do
			local button = self.lumos[5]
			if IsPlayerSpell(188089) then
				UpdateDebuff(button, 188089, 188089, true)
			elseif IsPlayerSpell(114051) then
				UpdateBuff(button, 114051, 114051, true, true)
			else
				UpdateCooldown(button, 51533, true)
			end
		end
	elseif spec == 3 then
		UpdateCooldown(self.lumos[1], 61295, true)

		do
			local button = self.lumos[2]
			if IsPlayerSpell(157153) then
				button.Icon:SetTexture(GetSpellTexture(157504))
				local name, _, _, _, _, _, value = GetUnitAura("player", 157504, "HELPFUL")
				if name then
					UpdateTotemAura(button, 971076)
					button.Count:SetText(B.Numb(value))
					button.Count:SetTextColor(1, 1, 1)
				else
					UpdateCooldown(button, 157153)
				end
			else
				UpdateCooldown(button, 5394, true)
			end
		end

		UpdateCooldown(self.lumos[3], 73920, true)

		do
			local button = self.lumos[4]
			if IsPlayerSpell(198838) then
				UpdateTotemAura(button, 136098, 198838)
			else
				UpdateBuff(button, 108271, 108271, true, true)
			end
		end

		UpdateBuff(self.lumos[5], 79206, 79206, true)
	end
end
