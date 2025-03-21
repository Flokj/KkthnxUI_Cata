local K, C = KkthnxUI[1], KkthnxUI[2]
local Module = K:GetModule("Announcements")

-- Localize WoW API functions
local GetSpellLink = C_Spell.GetSpellLink
local GetSpellName = C_Spell.GetSpellName
local IsInGroup = IsInGroup
local SendChatMessage = SendChatMessage
local UnitName = UnitName

local spellList = {
	[226241] = true, -- 宁神圣典
	[256230] = true, -- 静心圣典
	[185709] = true, -- 焦糖鱼宴
	[259409] = true, -- 海帆盛宴
	[259410] = true, -- 船长盛宴
	[276972] = true, -- 秘法药锅
	[286050] = true, -- 鲜血大餐
	[265116] = true, -- 工程战复
}

local groupUnits = { ["player"] = true }
for i = 1, 4 do
	groupUnits["party" .. i] = true
end
for i = 1, 40 do
	groupUnits["raid" .. i] = true
end

function Module:ItemAlert_Update(unit, castID, spellID)
	if not C["Announcements"].ItemAlert then
		return
	end

	if groupUnits[unit] and spellList[spellID] and (spellList[spellID] ~= castID) then
		SendChatMessage(format("%s placed %s", UnitName(unit), GetSpellLink(spellID) or GetSpellName(spellID)), K.CheckChat())
		spellList[spellID] = castID
	end
end

function Module:ItemAlert_CheckGroup()
	if IsInGroup() then
		K:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", Module.ItemAlert_Update)
	else
		K:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED", Module.ItemAlert_Update)
	end
end

function Module:CreateItemAnnounce()
	self:ItemAlert_CheckGroup()
	K:RegisterEvent("GROUP_LEFT", self.ItemAlert_CheckGroup)
	K:RegisterEvent("GROUP_JOINED", self.ItemAlert_CheckGroup)
end
