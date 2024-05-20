local K, C = KkthnxUI[1], KkthnxUI[2]
local Module = K:GetModule("Announcements")

local math_floor = math.floor
local mod = mod
local pairs = pairs
local string_find = string.find
local string_format = string.format
local string_gsub = string.gsub
local string_match = string.match
local table_wipe = table.wipe
local tonumber = tonumber

local GetInfo = GetInfo
local GetLogIndexForQuestID = GetLogIndexForQuestID
local GetNumQuestLogEntries = GetNumQuestLogEntries
local GetQuestIDForLogIndex = GetQuestIDForLogIndex
local GetQuestTagInfo = GetQuestTagInfo
local GetTitleForQuestID = GetTitleForQuestID
local IsComplete = IsComplete
local IsWorldQuest = IsWorldQuest
local DAILY = DAILY
local ERR_QUEST_ADD_FOUND_SII = ERR_QUEST_ADD_FOUND_SII
local ERR_QUEST_ADD_ITEM_SII = ERR_QUEST_ADD_ITEM_SII
local ERR_QUEST_ADD_KILL_SII = ERR_QUEST_ADD_KILL_SII
local ERR_QUEST_ADD_PLAYER_KILL_SII = ERR_QUEST_ADD_PLAYER_KILL_SII
local ERR_QUEST_COMPLETE_S = ERR_QUEST_COMPLETE_S
local ERR_QUEST_FAILED_S = ERR_QUEST_FAILED_S
local ERR_QUEST_OBJECTIVE_COMPLETE_S = ERR_QUEST_OBJECTIVE_COMPLETE_S
local GetQuestLink = GetQuestLink
local IsInGroup = IsInGroup
local IsInRaid = IsInRaid
local IsPartyLFG = IsPartyLFG
local LE_QUEST_FREQUENCY_DAILY = Enum.QuestFrequency.Daily
local LE_QUEST_TAG_TYPE_PROFESSION = Enum.QuestTagType.Profession
local PlaySound = PlaySound
local SendChatMessage = SendChatMessage

local soundKitID = 6199 -- https://wowhead.com/sound=6199/b-peonbuildingcomplete1

--[[
	26905 -- https://www.wowhead.com/sound=26905/ui-questobjectivescomplete
]]

-- Boolean flag to indicate whether debug mode is enabled or not
local debugMode = false
-- Table to cache world quest IDs to prevent duplicate announcements
local WQcache = {}
-- Table to store completed quest IDs to prevent duplicate announcements
local completedQuest = {}
-- Variable to indicate whether initial quest checking is complete
local initComplete

-- Get the quest link or the quest name
local function GetQuestLinkOrName(questID)
	-- Get the quest link by quest ID
	-- If it is not returned, get the quest title by quest ID
	-- If it is not returned, return an empty string
	return GetQuestLink(questID) or GetTitleForQuestID(questID) or ""
end

-- Get the text for the quest acceptance message
local function acceptText(questID, daily)
	-- Get the title of the quest
	local title = GetQuestLinkOrName(questID)
	-- If the quest is a daily quest, format the message with "Accepted" and "Daily"
	if daily then
		return string_format("%s [%s]%s", "Accepted", DAILY, title)
	-- If the quest is not a daily quest, format the message with "Accepted"
	else
		return string_format("%s %s", "Accepted", title)
	end
end

-- Get the text for the quest completion message
local function completeText(questID)
	-- Play a sound
	PlaySound(soundKitID, "Master")
	-- Format the message with "Completed" and the quest title
	return string_format("%s %s", "Completed", GetQuestLinkOrName(questID))
end

-- Send message to the appropriate channel
local function sendQuestMsg(msg)
	-- If OnlyCompleteRing is true, return
	if C["Announcements"].OnlyCompleteRing then return end

	-- If debug mode is enabled, print the message in the chat
	-- If the player is in a LFG party, send the message to the instance chat
	-- If the player is in a raid, send the message to the raid chat
	-- If the player is in a group, send the message to the party chat
	if debugMode and K.isDeveloper then
		print(msg)
	elseif IsPartyLFG() then
		SendChatMessage(msg, "INSTANCE_CHAT")
	elseif IsInRaid() then
		SendChatMessage(msg, "RAID")
	elseif IsInGroup() then
		SendChatMessage(msg, "PARTY")
	end
end

-- Get the pattern for a given quest match
local function getPattern(pattern)
	-- Escape any special characters in the pattern
	pattern = string_gsub(pattern, "%(", "%%%1")
	pattern = string_gsub(pattern, "%)", "%%%1")
	-- Replace any wildcard characters with capture groups
	pattern = string_gsub(pattern, "%%%d?$?.", "(.+)")
	-- Format the pattern to match the entire string
	return string_format("^%s$", pattern)
end

-- Table of quest match patterns
local questMatches = {
	["Found"] = getPattern(ERR_QUEST_ADD_FOUND_SII),
	["Item"] = getPattern(ERR_QUEST_ADD_ITEM_SII),
	["Kill"] = getPattern(ERR_QUEST_ADD_KILL_SII),
	["PKill"] = getPattern(ERR_QUEST_ADD_PLAYER_KILL_SII),
	["ObjectiveComplete"] = getPattern(ERR_QUEST_OBJECTIVE_COMPLETE_S),
	["QuestComplete"] = getPattern(ERR_QUEST_COMPLETE_S),
	["QuestFailed"] = getPattern(ERR_QUEST_FAILED_S),
}

function Module:FindQuestProgress(_, msg)
	-- Check if the option to announce quest progress is disabled, if so, exit the function
	if not C["Announcements"].QuestProgress then return end

	-- Check if the option to only announce quest progress when the ring is complete is enabled, if so, exit the function
	if C["Announcements"].OnlyCompleteRing then return end

	-- Iterate through the patterns in the `questMatches` table
	for _, pattern in pairs(questMatches) do
		-- Check if the message matches any of the patterns
		if string_match(msg, pattern) then
			-- Get the current and max values from the message
			local _, _, _, cur, max = string_find(msg, "(.*)[:]%s*([-%d]+)%s*/%s*([-%d]+)%s*$")
			-- Convert the values to numbers
			cur, max = tonumber(cur), tonumber(max)
			if cur and max and max >= 10 then
				-- Check if the progress is a multiple of the max value divided by 5
				if mod(cur, math_floor(max / 5)) == 0 then
					-- Send the message using `sendQuestMsg` function
					sendQuestMsg(msg)
				end
			else
				-- Send the message using `sendQuestMsg` function
				sendQuestMsg(msg)
			end
			break
		end
	end
end

function Module:FindQuestAccept(questID)
	-- Check if questID is nil, if so, exit the function
	if not questID then return end

	-- Check if the quest is a world quest and it has been cached before, if so, exit the function
	if IsWorldQuest(questID) and WQcache[questID] then return end
	-- Cache the world quest
	WQcache[questID] = true

	-- Get the tag info for the quest
	local tagInfo = GetQuestTagInfo(questID)
	-- Check if the quest is a profession quest, if so, exit the function
	if tagInfo and tagInfo.worldQuestType == LE_QUEST_TAG_TYPE_PROFESSION then return end

	-- Get the quest log index for the quest ID
	local questLogIndex = GetLogIndexForQuestID(questID)
	-- Check if the quest log index is valid
	if questLogIndex then
		-- Get the information for the quest
		local info = GetInfo(questLogIndex)
		-- Check if the information is valid
		if info then
			-- Send the message using `sendQuestMsg` function with the quest ID and whether the quest is a daily quest as parameters
			sendQuestMsg(acceptText(questID, info.frequency == LE_QUEST_FREQUENCY_DAILY))
		end
	end
end

function Module:FindQuestComplete()
	-- Loop through all quests in player's quest log
	for i = 1, GetNumQuestLogEntries() do
		-- Get the quest ID for the current log index
		local name, _, _, _, _, isComplete, _, questID = GetQuestLogTitle(i)
		-- Check if the quest is not a world quest and it is not marked as completed before
		if name and isComplete and not completedQuest[questID] and not IsWorldQuest(questID) then
			-- Check if this function has been called before
			if initComplete then
				-- Send the message using `sendQuestMsg` function with the quest ID as parameter
				sendQuestMsg(completeText(name))
			end
			-- Mark the quest as completed
			completedQuest[questID] = true
		end
	end
	-- Set the `initComplete` variable to true
	initComplete = true
end

function Module:FindWorldQuestComplete(questID)
	-- Check if the passed quest ID is a world quest
	if IsWorldQuest(questID) then
		-- Check if the quest is not marked as completed before
		if questID and not completedQuest[questID] then
			-- Send the message using `sendQuestMsg` function with the quest ID as parameter
			sendQuestMsg(completeText(questID))
			-- Mark the quest as completed
			completedQuest[questID] = true
		end
	end
end

function Module:CreateQuestNotifier()
	if C["Announcements"].QuestNotifier and not K.CheckAddOnState("QuestNotifier") then
		K:RegisterEvent("QUEST_ACCEPTED", Module.FindQuestAccept)
		K:RegisterEvent("QUEST_LOG_UPDATE", Module.FindQuestComplete)
		K:RegisterEvent("QUEST_TURNED_IN", Module.FindWorldQuestComplete)
		K:RegisterEvent("UI_INFO_MESSAGE", Module.FindQuestProgress)
	else
		table_wipe(completedQuest)
		K:UnregisterEvent("QUEST_ACCEPTED", Module.FindQuestAccept)
		K:UnregisterEvent("QUEST_LOG_UPDATE", Module.FindQuestComplete)
		K:UnregisterEvent("QUEST_TURNED_IN", Module.FindWorldQuestComplete)
		K:UnregisterEvent("UI_INFO_MESSAGE", Module.FindQuestProgress)
	end
end
