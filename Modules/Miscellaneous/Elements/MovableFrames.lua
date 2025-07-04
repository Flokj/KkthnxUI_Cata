local K, C = KkthnxUI[1], KkthnxUI[2]

-- Caching global functions and variables for performance
local pairs, type, string_gmatch, print = pairs, type, string.gmatch, print

local frames = {
	-- ["FrameName"] = true (the parent frame should be moved) or false (the frame itself should be moved)
	-- for child frames (i.e. frames that don't have a name, but only a parentKey="XX" use
	-- "ParentFrameName.XX" as frame name. more than one level is supported, e.g. "Foo.Bar.Baz")

	-- Blizz Frames
	["AddonList"] = false,
	["ChannelFrame"] = false,
	["ChatConfigFrame"] = false,
	["DressUpFrame"] = false,
	["FriendsFrame"] = false,
	["GameMenuFrame"] = false,
	["GossipFrame"] = false,
	["GuildRegistrarFrame"] = false,
	["HelpFrame"] = false,
	["ItemTextFrame"] = false,
	["LootFrame"] = false,
	["MailFrame"] = false,
	["MerchantFrame"] = false,
	["ModelPreviewFrame"] = false,
	["OpenMailFrame"] = false,
	["PetitionFrame"] = false,
	["PetStableFrame"] = false,
	["PVEFrame"] = false,
	["PVPFrame"] = false,
	["QuestFrame"] = false,
	["QuestLogDetailFrame"] = false,
	["RaidParentFrame"] = false,
	["SendMailFrame"] = true,
	["SpellBookFrame"] = false,
	["StackSplitFrame"] = false,
	["TabardFrame"] = false,
	["TaxiFrame"] = false,
	--["TradeFrame"] = false,
	["TutorialFrame"] = false,
}

local function CharacterFrameMoveCheck()
	if C_AddOns.IsAddOnLoaded("RXPGuides") then return end

	frames["PaperDollFrame"] = "CharacterFrame"
	frames["ReputationFrame"] = true
	frames["SkillFrame"] = true
	frames["TokenFrame"] = true
end

-- Frame Existing Check
local function IsFrameExists()
	if not C["General"].MoveBlizzardFrames then	return end
	for k in pairs(frames) do
		if not _G[k] and K.isDeveloper then
			print("Frame not found:", k)
		end
	end
end

-- Frames provided by load on demand addons, hooked when the addon is loaded.
local lodFrames = {
	-- AddonName = { list of frames, same syntax as above }
	Blizzard_AchievementUI = { ["AchievementFrame"] = false, ["AchievementFrameHeader"] = true, ["AchievementFrameCategoriesContainer"] = "AchievementFrame", ["AchievementFrame.searchResults"] = false },
	Blizzard_AdventureMap = { ["AdventureMapQuestChoiceDialog"] = false },
	Blizzard_AlliedRacesUI = { ["AlliedRacesFrame"] = false },
	Blizzard_ArchaeologyUI = { ["ArchaeologyFrame"] = false },
	Blizzard_ArtifactUI = { ["ArtifactFrame"] = false, ["ArtifactRelicForgeFrame"] = false },
	Blizzard_AuctionUI = { ["AuctionFrame"] = false },
	Blizzard_AzeriteEssenceUI = { ["AzeriteEssenceUI"] = false },
	Blizzard_AzeriteRespecUI = { ["AzeriteRespecFrame"] = false },
	Blizzard_AzeriteUI = { ["AzeriteEmpoweredItemUI"] = false },
	Blizzard_BarbershopUI = { ["BarberShopFrame"] = false },
	Blizzard_BindingUI = { ["KeyBindingFrame"] = false },
	Blizzard_BlackMarketUI = { ["BlackMarketFrame"] = false },
	Blizzard_Calendar = { ["CalendarFrame"] = false, ["CalendarCreateEventFrame"] = true },
	Blizzard_ChallengesUI = { ["ChallengesKeystoneFrame"] = false },
	Blizzard_Collections = { ["WardrobeFrame"] = false, ["WardrobeOutfitEditFrame"] = false },
	Blizzard_Communities = { ["CommunitiesFrame"] = false, ["CommunitiesSettingsDialog"] = false, ["CommunitiesGuildLogFrame"] = false, ["CommunitiesTicketManagerDialog"] = false, ["CommunitiesAvatarPickerDialog"] = false, ["CommunitiesFrame.NotificationSettingsDialog"] = false },
	Blizzard_FlightMap = { ["FlightMapFrame"] = false },
	Blizzard_GMSurveyUI = { ["GMSurveyFrame"] = false },
	Blizzard_GuildBankUI = { ["GuildBankFrame"] = false, ["GuildBankEmblemFrame"] = true },
	Blizzard_GuildControlUI = { ["GuildControlUI"] = false },
	Blizzard_GuildRecruitmentUI = { ["CommunitiesGuildRecruitmentFrame"] = false },
	Blizzard_GuildUI = { ["GuildFrame"] = false, ["GuildRosterFrame"] = true, ["GuildFrame.TitleMouseover"] = true },
	Blizzard_InspectUI = { ["InspectFrame"] = false, ["InspectPVPFrame"] = true, ["InspectTalentFrame"] = true },
	Blizzard_IslandsPartyPoseUI = { ["IslandsPartyPoseFrame"] = false },
	Blizzard_IslandsQueueUI = { ["IslandsQueueFrame"] = false },
	Blizzard_ItemSocketingUI = { ["ItemSocketingFrame"] = false },
	Blizzard_ItemUpgradeUI = { ["ItemUpgradeFrame"] = false },
	Blizzard_LookingForGroupUI = { ["LFGParentFrame"] = false },
	Blizzard_LookingForGuildUI = { ["LookingForGuildFrame"] = false },
	Blizzard_MacroUI = { ["MacroFrame"] = false },
	Blizzard_ObliterumUI = { ["ObliterumForgeFrame"] = false },
	Blizzard_OrderHallUI = { ["OrderHallTalentFrame"] = false },
	Blizzard_ScrappingMachineUI = { ["ScrappingMachineFrame"] = false },
	Blizzard_TalentUI = { ["PlayerTalentFrame"] = false },
	Blizzard_TimeManager = { ["TimeManagerFrame"] = false },
	Blizzard_TradeSkillUI = { ["TradeSkillFrame"] = false },
	Blizzard_TrainerUI = { ["ClassTrainerFrame"] = false },
	Blizzard_VoidStorageUI = { ["VoidStorageFrame"] = false, ["VoidStorageBorderFrameMouseBlockFrame"] = "VoidStorageFrame" },
}

local parentFrame = {}
local hooked = {}

local function MouseDownHandler(frame, button)
	frame = parentFrame[frame] or frame
	if frame and button == "LeftButton" then
		frame:StartMoving()
		frame:SetUserPlaced(false)
	end
end

local function MouseUpHandler(frame, button)
	frame = parentFrame[frame] or frame
	if frame and button == "LeftButton" and frame:IsMovable() then
		frame:StopMovingOrSizing()
	end
end

local function HookScript(frame, script, handler)
	if not frame.GetScript then return end

	local oldHandler = frame:GetScript(script)
	frame:SetScript(script, function(...)
		handler(...)
		if oldHandler then
			oldHandler(...)
		end
	end)
end

local function HookFrame(name, moveParent)
	local frame = _G
	for s in string_gmatch(name, "%w+") do
		frame = frame and frame[s]
	end

	if frame == _G then
		frame = nil
	end

	local parent
	if frame and not hooked[name] then
		if moveParent then
			parent = type(moveParent) == "string" and _G[moveParent] or frame:GetParent()
			if not parent then
				print("Parent frame not found: " .. name)
				return
			end
			parentFrame[frame] = parent
		end

		if parent then
			parent:SetMovable(true)
			parent:SetClampedToScreen(false)
		end

		frame:EnableMouse(true)
		frame:SetMovable(true)
		frame:SetClampedToScreen(false)

		HookScript(frame, "OnMouseDown", MouseDownHandler)
		HookScript(frame, "OnMouseUp", MouseUpHandler)

		hooked[name] = true
	end
end

local function HookFrames(list)
	if not C["General"].MoveBlizzardFrames then	return end
	for name, child in pairs(list) do
		HookFrame(name, child)
	end
end

local function InitSetup()
	CharacterFrameMoveCheck()
	IsFrameExists()
	HookFrames(frames)
end

local function AddonLoaded(_, name)
	local frameList = lodFrames[name]
	if frameList then
		HookFrames(frameList)
	end
end
K:RegisterEvent("PLAYER_LOGIN", InitSetup)
K:RegisterEvent("ADDON_LOADED", AddonLoaded)
