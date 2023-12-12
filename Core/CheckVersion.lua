local K, C = unpack(KkthnxUI)
local Module = K:NewModule("VersionCheck")

-- Sourced: NDui (siweia)
-- Edited: KkthnxUI (Kkthnx)

local _G = _G
local string_format = _G.string.format
local string_gsub = _G.string.gsub
local string_split = _G.string.split

local Ambiguate = _G.Ambiguate
local C_ChatInfo_RegisterAddonMessagePrefix = _G.C_ChatInfo.RegisterAddonMessagePrefix
local C_ChatInfo_SendAddonMessage = _G.C_ChatInfo.SendAddonMessage
local GetTime = _G.GetTime
local IsInGroup = _G.IsInGroup
local IsInGuild = _G.IsInGuild

local function HandleVersonTag(version)
	local major, minor = string_split(".", version)
	major, minor = tonumber(major), tonumber(minor)
	if K.Base64:CV(major) then
		major, minor = 0, 0
		if K.isDeveloper and author then
			print("Moron: " .. author)
		end
	end
	return major, minor
end

function Module:VersionCheck_Compare(new, old, author)
	local new1, new2 = HandleVersonTag(new, author)
	local old1, old2 = HandleVersonTag(old)
	if new1 > old1 or (new1 == old1 and new2 > old2) then
		return "IsNew"
	elseif new1 < old1 or (new1 == old1 and new2 < old2) then
		return "IsOld"
	end
end

local hasChecked
function Module:VersionCheck_Init()
	if not hasChecked then
		local status = Module:VersionCheck_Compare(KkthnxUIDB.DetectVersion, K.Version)
		if status == "IsNew" then
			local release = string_gsub(KkthnxUIDB.DetectVersion, "(%d+)$", "0")
			K.Print("|cff669dffKkthnxUI|r is out of date, the latest release is |cff70C0F5%s|r", release)
		elseif status == "IsOld" then
			KkthnxUIDB.DetectVersion = K.Version
		end

		hasChecked = true
	end
end

local lastVCTime = 0
function Module:VersionCheck_Send(channel)
	if GetTime() - lastVCTime >= 10 then
		C_ChatInfo_SendAddonMessage("KKUIVersionCheck", KkthnxUIDB.DetectVersion, channel)
		lastVCTime = GetTime()
	end
end

function Module:VersionCheck_Update(...)
	local prefix, msg, distType, author = ...
	if prefix ~= "KKUIVersionCheck" then return end
	if Ambiguate(author, "none") == K.Name then return end

	local status = Module:VersionCheck_Compare(msg, KkthnxUIDB.DetectVersion, author)
	if status == "IsNew" then
		KkthnxUIDB.DetectVersion = msg
	elseif status == "IsOld" then
		Module:VersionCheck_Send(distType)
	end

	Module:VersionCheck_Init()
end

function Module:VersionCheck_UpdateGroup()
	if not IsInGroup() then return end

	Module:VersionCheck_Send(K.CheckChat())
end

function Module:OnEnable()
	Module:VersionCheck_Init()
	C_ChatInfo_RegisterAddonMessagePrefix("KKUIVersionCheck")
	K:RegisterEvent("CHAT_MSG_ADDON", Module.VersionCheck_Update)

	if IsInGuild() then
		C_ChatInfo_SendAddonMessage("KKUIVersionCheck", K.Version, "GUILD")
		lastVCTime = GetTime()
	end
	Module:VersionCheck_UpdateGroup()
	K:RegisterEvent("GROUP_ROSTER_UPDATE", Module.VersionCheck_UpdateGroup)
end
