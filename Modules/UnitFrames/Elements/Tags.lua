local K, C, L = KkthnxUI[1], KkthnxUI[2], KkthnxUI[3]
local oUF = K.oUF

local format, floor = string.format, math.floor
local AFK, DND, DEAD, PLAYER_OFFLINE, LEVEL = AFK, DND, DEAD, PLAYER_OFFLINE, LEVEL
local ALTERNATE_POWER_INDEX = ALTERNATE_POWER_INDEX or 10
local UnitIsDeadOrGhost, UnitIsConnected, UnitIsTapDenied, UnitIsPlayer = UnitIsDeadOrGhost, UnitIsConnected, UnitIsTapDenied, UnitIsPlayer
local UnitHealth, UnitHealthMax, UnitPower, UnitPowerType = UnitHealth, UnitHealthMax, UnitPower, UnitPowerType
local UnitClass, UnitReaction, UnitLevel, UnitClassification = UnitClass, UnitReaction, UnitLevel, UnitClassification
local UnitIsAFK, UnitIsDND, UnitIsDead, UnitIsGhost = UnitIsAFK, UnitIsDND, UnitIsDead, UnitIsGhost
local GetCreatureDifficultyColor = GetCreatureDifficultyColor
local GetSpellInfo, UnitIsFeignDeath = GetSpellInfo, UnitIsFeignDeath

local FEIGN_DEATH
local function GetFeignDeathTag()
	if not FEIGN_DEATH then
		FEIGN_DEATH = GetSpellInfo(5384)
	end
	return FEIGN_DEATH
end

local function GetHealthColor(percentage)
	local r, g, b
	if percentage < 20 then
		r, g, b = 1, 0.1, 0.1
	elseif percentage < 35 then
		r, g, b = 1, 0.5, 0
	elseif percentage < 80 then
		r, g, b = 1, 0.9, 0.3
	else
		r, g, b = 1, 1, 1
	end
	return K.RGBToHex(r, g, b) .. percentage
end

local function FormatHealthValue(health, percentage)
	local formattedValue = K.ShortValue(health)
	if percentage < 100 then
		formattedValue = formattedValue .. " - " .. GetHealthColor(percentage)
	else
		formattedValue = formattedValue
	end
	return formattedValue
end

local function GetUnitHealthPerc(unit)
	local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)
	if maxHealth == 0 then
		return 0, health
	else
		return K.Round(health / maxHealth * 100, 1), health
	end
end

oUF.Tags.Methods["hp"] = function(unit)
	if UnitIsDeadOrGhost(unit) or not UnitIsConnected(unit) then
		return oUF.Tags.Methods["DDG"](unit)
	else
		local percentage, currentHealth = GetUnitHealthPerc(unit)
		if unit == "player" or unit == "target" or unit == "focus" or unit:match("party%d?$") then
			return FormatHealthValue(currentHealth, percentage)
		else
			return GetHealthColor(percentage)
		end
	end
end
oUF.Tags.Events["hp"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED PARTY_MEMBER_ENABLE PARTY_MEMBER_DISABLE"

oUF.Tags.Methods["power"] = function(unit)
	local cur, maxPower = UnitPower(unit), UnitPowerMax(unit)
	local per = maxPower == 0 and 0 or K.Round(cur / maxPower * 100)

	if unit == "player" or unit == "target" or unit == "focus" then
		if per < 100 and UnitPowerType(unit) == 0 and maxPower ~= 0 then
			return K.ShortValue(cur) .. " - " .. per
		else
			return K.ShortValue(cur)
		end
	else
		return per
	end
end
oUF.Tags.Events["power"] = "UNIT_POWER_FREQUENT UNIT_MAXPOWER UNIT_DISPLAYPOWER"

oUF.Tags.Methods["color"] = function(unit)
	local class = select(2, UnitClass(unit))
	local reaction = UnitReaction(unit, "player")

	if UnitIsTapDenied(unit) then
		return K.RGBToHex(oUF.colors.tapped)
	elseif UnitIsPlayer(unit) then
		return K.RGBToHex(K.Colors.class[class])
	elseif reaction then
		return K.RGBToHex(K.Colors.reaction[reaction])
	else
		return K.RGBToHex(1, 1, 1)
	end
end
oUF.Tags.Events["color"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_NAME_UPDATE UNIT_FACTION UNIT_CONNECTION PLAYER_FLAGS_CHANGED"

oUF.Tags.Methods["afkdnd"] = function(unit)
	if UnitIsAFK(unit) then
		return "|cffCFCFCF <" .. AFK .. ">|r"
	elseif UnitIsDND(unit) then
		return "|cffCFCFCF <" .. DND .. ">|r"
	else
		return ""
	end
end
oUF.Tags.Events["afkdnd"] = "PLAYER_FLAGS_CHANGED"

--oUF.Tags.Methods["DDG"] = function(unit)
--	if UnitIsFeignDeath(unit) then
--		return "|cff99ccff" .. GetFeignDeathTag() .. "|r"
--	elseif UnitIsDead(unit) then
--		return "|cffCFCFCF" .. DEAD .. "|r"
--	elseif UnitIsGhost(unit) then
--		return "|cffCFCFCF" .. L["Ghost"] .. "|r"
--	elseif not UnitIsConnected(unit) then
--		return "|cffCFCFCF" .. PLAYER_OFFLINE .. "|r"
--	end
--end
--oUF.Tags.Events["DDG"] = "UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH UNIT_NAME_UPDATE UNIT_CONNECTION PLAYER_FLAGS_CHANGED"

oUF.Tags.Methods["DDG"] = function(unit)
	if UnitIsFeignDeath(unit) then
		return "|cff99ccff" .. GetFeignDeathTag() .. "|r"
	elseif UnitIsDead(unit) then
		return "|cffCFCFCF" .. DEAD .. "|r"
	elseif UnitIsGhost(unit) then
		return "|cffCFCFCF" .. L["Ghost"] .. "|r"
	elseif not UnitIsConnected(unit) then
		return "|cffCFCFCF" .. PLAYER_OFFLINE .. "|r"
	elseif UnitIsAFK(unit) then
		return "|cffCFCFCF <" .. AFK .. ">|r"
	elseif UnitIsDND(unit) then
		return "|cffCFCFCF <" .. DND .. ">|r"
	else
		return ""
	end
end

oUF.Tags.Events["DDG"] = "PLAYER_FLAGS_CHANGED UNIT_HEALTH UNIT_MAXHEALTH UNIT_NAME_UPDATE UNIT_CONNECTION"

-- Level tags
oUF.Tags.Methods["fulllevel"] = function(unit)
	local level = UnitLevel(unit)
	local color = K.RGBToHex(GetCreatureDifficultyColor(level))
	if level > 0 then
		level = color .. level .. "|r"
	else
		level = "|cffff0000??|r"
	end
	local str = level

	local class = UnitClassification(unit)
	if not UnitIsConnected(unit) then
		str = "??"
	elseif class == "worldboss" then
		str = "|cffff0000Boss|r"
	elseif class == "rareelite" then
		str = level .. "|cff0080ffR|r+"
	elseif class == "elite" then
		str = level .. "+"
	elseif class == "rare" then
		str = level .. "|cff0080ffR|r"
	end

	return str
end
oUF.Tags.Events["fulllevel"] = "UNIT_LEVEL PLAYER_LEVEL_UP UNIT_CLASSIFICATION_CHANGED"

-- RaidFrame tags
oUF.Tags.Methods["raidhp"] = function(unit)
	if UnitIsDeadOrGhost(unit) or not UnitIsConnected(unit) then
		return oUF.Tags.Methods["DDG"](unit)
	elseif C["Raid"].HealthFormat.Value == 2 then
		local per = GetUnitHealthPerc(unit) or 0
		return GetHealthColor(per)
	elseif C["Raid"].HealthFormat.Value == 3 then
		local cur = UnitHealth(unit)
		return K.ShortValue(cur)
	elseif C["Raid"].HealthFormat.Value == 4 then
		local loss = UnitHealthMax(unit) - UnitHealth(unit)
		if loss == 0 then
			return
		end
		return K.ShortValue(loss)
	end
end
oUF.Tags.Events["raidhp"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_NAME_UPDATE UNIT_CONNECTION PLAYER_FLAGS_CHANGED"

-- Nameplate tags
oUF.Tags.Methods["nphp"] = function(unit)
	local per, cur = GetUnitHealthPerc(unit)
	if C["Nameplate"].FullHealth then
		return FormatHealthValue(cur, per)
	elseif per < 100 then
		return GetHealthColor(per)
	end
end
oUF.Tags.Events["nphp"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION"

oUF.Tags.Methods["nppp"] = function(unit)
	local per = oUF.Tags.Methods["perpp"](unit)
	local color
	if per > 85 then
		color = K.RGBToHex(1, 0.1, 0.1)
	elseif per > 50 then
		color = K.RGBToHex(1, 1, 0.1)
	else
		color = K.RGBToHex(0.8, 0.8, 1)
	end
	per = color .. per .. "|r"

	return per
end
oUF.Tags.Events["nppp"] = "UNIT_POWER_FREQUENT UNIT_MAXPOWER"

oUF.Tags.Methods["nplevel"] = function(unit)
	local level = UnitLevel(unit)
	if level and level ~= K.Level then
		if level > 0 then
			level = K.RGBToHex(GetCreatureDifficultyColor(level)) .. level .. "|r "
		else
			level = "|cffff0000??|r "
		end
	else
		level = ""
	end

	return level
end
oUF.Tags.Events["nplevel"] = "UNIT_LEVEL PLAYER_LEVEL_UP"

local NPClassifies = {
	rare = "   ",
	elite = "   ",
	rareelite = "   ",
	worldboss = "   ",
}
oUF.Tags.Methods["nprare"] = function(unit)
	local class = UnitClassification(unit)
	return class and NPClassifies[class]
end
oUF.Tags.Events["nprare"] = "UNIT_CLASSIFICATION_CHANGED"

oUF.Tags.Methods["pppower"] = function(unit)
	local cur = UnitPower(unit)
	local per = oUF.Tags.Methods["perpp"](unit) or 0
	if UnitPowerType(unit) == 0 then
		return per
	else
		return cur
	end
end
oUF.Tags.Events["pppower"] = "UNIT_POWER_FREQUENT UNIT_MAXPOWER UNIT_DISPLAYPOWER"

oUF.Tags.Methods["npctitle"] = function(unit)
	if UnitIsPlayer(unit) then return end

	K.ScanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	K.ScanTooltip:SetUnit(unit)

	local textLine = _G[format("KKUI_ScanTooltipTextLeft%d", GetCVarBool("colorblindmode") and 3 or 2)]
	local title = textLine and textLine:GetText()
	if title and not strfind(title, "^" .. LEVEL) then
		return title
	end
end
oUF.Tags.Events["npctitle"] = "UNIT_NAME_UPDATE"

oUF.Tags.Methods["tarname"] = function(unit)
	local tarUnit = unit .. "target"
	if UnitExists(tarUnit) then
		return K.RGBToHex(K.UnitColor(tarUnit))..UnitName(tarUnit)
	end
end
oUF.Tags.Events["tarname"] = "UNIT_NAME_UPDATE UNIT_THREAT_SITUATION_UPDATE UNIT_HEALTH_FREQUENT"

-- AltPower value tag
oUF.Tags.Methods["altpower"] = function(unit)
	local cur = UnitPower(unit, ALTERNATE_POWER_INDEX)
	local max = UnitPowerMax(unit, ALTERNATE_POWER_INDEX)
	if max > 0 and not UnitIsDeadOrGhost(unit) then
		return format("%s%%", floor(cur/max*100 + .5))
	end
end
oUF.Tags.Events["altpower"] = "UNIT_POWER_UPDATE UNIT_MAXPOWER"

-- Eclipse power for Druid
local POWERTYPE_BALANCE = Enum.PowerType.Balance or 26
oUF.Tags.Methods["cureclipse"] = function(unit)
	local textFormat = GetEclipseDirection() == "sun" and "|cff40bfff%s>" or "|cffffff00<%s"
	local max = UnitPowerMax("player", POWERTYPE_BALANCE)
	return format(textFormat, (max == 0 and 0) or math.abs(UnitPower("player", POWERTYPE_BALANCE)))
end
oUF.Tags.Events["cureclipse"] = "UNIT_POWER_FREQUENT ECLIPSE_DIRECTION_CHANGE"

oUF.Tags.Methods["lfdrole"] = function(unit)
	local role = UnitGroupRolesAssigned(unit)
	if IsInGroup() and (UnitInParty(unit) or UnitInRaid(unit)) and (role ~= "NONE" and role ~= "DAMAGER") then
		if role == "HEALER" then
			return "|TInterface\\AddOns\\KkthnxUI\\Media\\Chat\\Roles\\Healer.tga:12:12:0:0:64:64:5:59:5:59|t"
		elseif role == "TANK" then
			return "|TInterface\\AddOns\\KkthnxUI\\Media\\Chat\\Roles\\Tank.tga:12:12:0:0:64:64:5:59:5:59|t"
		end
	end
end
oUF.Tags.Events["lfdrole"] = "PLAYER_ROLES_ASSIGNED GROUP_ROSTER_UPDATE"