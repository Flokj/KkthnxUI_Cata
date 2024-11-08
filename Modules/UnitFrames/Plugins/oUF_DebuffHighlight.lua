local K = KkthnxUI[1]
local oUF = K.oUF

local CanDispel = {
	["DRUID"] = {
		["Magic"] = false,
		["Curse"] = true,
		["Poison"] = true,
	},
	["PALADIN"] = {
		["Magic"] = false,
		["Poison"] = true,
		["Disease"] = true,
	},
	["PRIEST"] = {
		["Magic"] = true,
		["Disease"] = true,
	},
	["SHAMAN"] = {
		["Magic"] = false,
		["Curse"] = true,
	},
	["MAGE"] = {
		["Curse"] = true,
	},
	["WARLOCK"] = {
		["Magic"] = true,
	},
}

local dispellist = CanDispel[K.Class] or {}
local origColors = {}

local function GetDebuffType(unit, filter)
	if not UnitCanAssist("player", unit) then
		return nil
	end

	local i = 1
	while true do
		local _, texture, _, debufftype = UnitAura(unit, i, "HARMFUL")
		if not texture then
			break
		end

		if debufftype and not filter or (filter and dispellist[debufftype]) then
			return debufftype, texture
		end

		i = i + 1
	end
end
local function CheckPetSpells()
	if IsSpellKnown(19505, true) then
		return true
	end
end

-- Check for certain talents to see if we can dispel magic or not
local function CheckDispel(_, event, arg1)
	if event == "UNIT_PET" then
		if arg1 == "player" and K.Class == "WARLOCK" then
			dispellist.Magic = CheckPetSpells()
		end
	elseif event == "CHARACTER_POINTS_CHANGED" and arg1 > 0 then
		return -- Not interested in gained points from leveling
	end
end

local function Update(object, _, unit)
	if object.unit ~= unit then
		return
	end

	local debuffType, texture = GetDebuffType(unit, object.DebuffHighlightFilter)
	if debuffType then
		local color = DebuffTypeColor[debuffType]
		if object.DebuffHighlightUseTexture then
			object.DebuffHighlight:SetTexture(texture)
		else
			object.DebuffHighlight:SetVertexColor(color.r, color.g, color.b, object.DebuffHighlightAlpha or 0.5)
		end
	else
		if object.DebuffHighlightUseTexture then
			object.DebuffHighlight:SetTexture(nil)
		else
			local color = origColors[object]
			object.DebuffHighlight:SetVertexColor(color.r, color.g, color.b, color.a)
		end
	end
end

local function Enable(object)
	-- If we're not highlighting this unit return
	if not object.DebuffHighlight then
		return
	end

	-- If we're filtering highlights and we're not of the dispelling type, return
	if object.DebuffHighlightFilter and not CanDispel[K.Class] then
		return
	end

	-- Make sure aura scanning is active for this object
	object:RegisterEvent("UNIT_AURA", Update)

	if not object.DebuffHighlightUseTexture then
		local r, g, b, a = object.DebuffHighlight:GetVertexColor()
		origColors[object] = { r = r, g = g, b = b, a = a }
	end

	return true
end

local function Disable(object)
	if object.DebuffHighlight then
		object:UnregisterEvent("UNIT_AURA", Update)
	end
end

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", CheckDispel)
frame:RegisterEvent("UNIT_PET", CheckDispel)
frame:RegisterEvent("PLAYER_TALENT_UPDATE")
frame:RegisterEvent("CHARACTER_POINTS_CHANGED")

oUF:AddElement("DebuffHighlight", Update, Enable, Disable)

for _, frame in ipairs(oUF.objects) do
	Enable(frame)
end
