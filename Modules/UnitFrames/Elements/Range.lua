local K, C = KkthnxUI[1], KkthnxUI[2]
local Module = K:GetModule("Unitframes")

-- Global caching
local string_find, UnitIsUnit, GetNumGroupMembers, IsInRaid, UnitIsPlayer, UnitPhaseReason, UnitInRange, UnitCanAttack, UnitIsConnected = string.find, UnitIsUnit, GetNumGroupMembers, IsInRaid, UnitIsPlayer, UnitPhaseReason, UnitInRange, UnitCanAttack, UnitIsConnected

local function GetGroupUnit(unit)
	if UnitIsUnit(unit, "player") then
		return nil
	end

	if string_find(unit, "party") or string_find(unit, "raid") then
		return unit
	end

	-- Check if the unit is in the player's group
	local isInRaid = IsInRaid()
	local groupPrefix = isInRaid and "raid" or "party"
	local numGroupMembers = GetNumGroupMembers()

	for i = 1, numGroupMembers do
		local groupUnit = groupPrefix .. i
		if UnitIsUnit(unit, groupUnit) then
			return groupUnit
		end
	end
end

local function getMaxRange(unit)
	local minRange, maxRange = K.LibRangeCheck:GetRange(unit, true, true)
	return (not minRange) or maxRange
end

local function friendlyIsInRange(realUnit)
	local unit = GetGroupUnit(realUnit) or realUnit

	if UnitIsPlayer(unit) then
		if not UnitInPhase(unit) then
			return false
		end
	end

	local inRange, checkedRange = UnitInRange(unit)
	if checkedRange and not inRange then
		return false -- blizz checked and said the unit is out of range
	end

	return getMaxRange(unit)
end

function Module:UpdateRange()
	if not C["Unitframe"].Range then
		return
	end
	
	local range = self.Range
	if not range then
		return
	end

	local unit = self.unit
	local alpha = range.insideAlpha

	if self.forceInRange or unit == "player" then
		alpha = range.insideAlpha
	elseif self.forceNotInRange then
		alpha = range.outsideAlpha
	elseif unit then
		if UnitCanAttack("player", unit) or UnitIsUnit(unit, "pet") then
			alpha = (getMaxRange(unit) and range.insideAlpha) or range.outsideAlpha
		else
			alpha = (UnitIsConnected(unit) and friendlyIsInRange(unit) and range.insideAlpha) or range.outsideAlpha
		end
	end

	range.RangeAlpha = alpha
	self:SetAlpha(alpha)
end
