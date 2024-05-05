local AddOnName, Engine = ...

local bit_band = bit.band
local bit_bor = bit.bor
local next = next
local pairs = pairs
local select = select
local string_format = string.format
local string_lower = string.lower
local tonumber = tonumber

local BAG_ITEM_QUALITY_COLORS = BAG_ITEM_QUALITY_COLORS
local COMBATLOG_OBJECT_AFFILIATION_MINE = COMBATLOG_OBJECT_AFFILIATION_MINE
local COMBATLOG_OBJECT_AFFILIATION_PARTY = COMBATLOG_OBJECT_AFFILIATION_PARTY
local COMBATLOG_OBJECT_AFFILIATION_RAID = COMBATLOG_OBJECT_AFFILIATION_RAID
local COMBATLOG_OBJECT_CONTROL_PLAYER = COMBATLOG_OBJECT_CONTROL_PLAYER
local COMBATLOG_OBJECT_REACTION_FRIENDLY = COMBATLOG_OBJECT_REACTION_FRIENDLY
local COMBATLOG_OBJECT_TYPE_PET = COMBATLOG_OBJECT_TYPE_PET
local CUSTOM_CLASS_COLORS = CUSTOM_CLASS_COLORS
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local CreateFrame = CreateFrame
local Enum = Enum
local GetAddOnEnableState = GetAddOnEnableState
local GetAddOnInfo = GetAddOnInfo
local GetBuildInfo = GetBuildInfo
local GetLocale = GetLocale
local GetNumAddOns = GetNumAddOns
local GetPhysicalScreenSize = GetPhysicalScreenSize
local GetRealmName = GetRealmName
local LOCALIZED_CLASS_NAMES_FEMALE = LOCALIZED_CLASS_NAMES_FEMALE
local LOCALIZED_CLASS_NAMES_MALE = LOCALIZED_CLASS_NAMES_MALE
local LibStub = LibStub
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local UnitClass = UnitClass
local UnitFactionGroup = UnitFactionGroup
local UnitGUID = UnitGUID
local UnitLevel = UnitLevel
local UnitName = UnitName
local UnitRace = UnitRace
local UnitSex = UnitSex

-- Deprecated
GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata

LE_ITEM_CLASS_CONSUMABLE = LE_ITEM_CLASS_CONSUMABLE or Enum.ItemClass.Consumable
LE_ITEM_CLASS_CONTAINER = LE_ITEM_CLASS_CONTAINER or Enum.ItemClass.Container
LE_ITEM_CLASS_WEAPON = LE_ITEM_CLASS_WEAPON or Enum.ItemClass.Weapon
LE_ITEM_CLASS_GEM = LE_ITEM_CLASS_GEM or Enum.ItemClass.Gem
LE_ITEM_CLASS_ARMOR = LE_ITEM_CLASS_ARMOR or Enum.ItemClass.Armor
LE_ITEM_CLASS_REAGENT = LE_ITEM_CLASS_REAGENT or Enum.ItemClass.Reagent
LE_ITEM_CLASS_PROJECTILE = LE_ITEM_CLASS_PROJECTILE or Enum.ItemClass.Projectile
LE_ITEM_CLASS_TRADEGOODS = LE_ITEM_CLASS_TRADEGOODS or Enum.ItemClass.Tradegoods
LE_ITEM_CLASS_ITEM_ENHANCEMENT = LE_ITEM_CLASS_ITEM_ENHANCEMENT or Enum.ItemClass.ItemEnhancement
LE_ITEM_CLASS_RECIPE = LE_ITEM_CLASS_RECIPE or Enum.ItemClass.Recipe
LE_ITEM_CLASS_QUIVER = LE_ITEM_CLASS_QUIVER or Enum.ItemClass.Quiver
LE_ITEM_CLASS_QUESTITEM = LE_ITEM_CLASS_QUESTITEM or Enum.ItemClass.Questitem
LE_ITEM_CLASS_KEY = LE_ITEM_CLASS_KEY or Enum.ItemClass.Key
LE_ITEM_CLASS_MISCELLANEOUS = LE_ITEM_CLASS_MISCELLANEOUS or Enum.ItemClass.Miscellaneous
LE_ITEM_CLASS_GLYPH = LE_ITEM_CLASS_GLYPH or Enum.ItemClass.Glyph
LE_ITEM_CLASS_BATTLEPET = LE_ITEM_CLASS_BATTLEPET or Enum.ItemClass.Battlepet
LE_ITEM_CLASS_WOW_TOKEN = LE_ITEM_CLASS_WOW_TOKEN or Enum.ItemClass.WoWToken

-- Create the Engine table and its sub-tables
Engine[1] = {} -- K, Main
Engine[2] = {} -- C, Config
Engine[3] = {} -- L, Locale

-- Assign the sub-tables to variables K, C, and L
local K, C, L = Engine[1], Engine[2], Engine[3]

-- Lib Info
K.LibBase64 = LibStub("LibBase64-1.0")
K.LibActionButton = LibStub("LibActionButton-1.0")
K.LibChangeLog = LibStub("LibChangelog")
K.LibDeflate = LibStub("LibDeflate-KkthnxUI")
K.LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
K.LibRangeCheck = LibStub("LibRangeCheck-3.0")
K.LibSerialize = LibStub("LibSerialize")
K.LibCustomGlow = LibStub("LibCustomGlow-1.0", true)
K.cargBags = Engine.cargBags
K.oUF = Engine.oUF

-- AddOn Info
K.Title = GetAddOnMetadata(AddOnName, "Title")
K.Version = GetAddOnMetadata(AddOnName, "Version")

-- Functions
K.Noop = function() end

-- Player Info
K.Name = UnitName("player")
K.Class = select(2, UnitClass("player"))
K.Race = UnitRace("player")
K.Faction = UnitFactionGroup("player")
K.Level = UnitLevel("player")
K.Client = GetLocale()
K.Realm = GetRealmName()
K.Sex = UnitSex("player")
K.GUID = UnitGUID("player")

-- Screen Info
K.ScreenWidth, K.ScreenHeight = GetPhysicalScreenSize()
K.Resolution = string_format("%dx%d", K.ScreenWidth, K.ScreenHeight)

-- UI Info
K.TexCoords = { 0.08, 0.92, 0.08, 0.92 }
K.ScanTooltip = CreateFrame("GameTooltip", "KKUI_ScanTooltip", nil, "GameTooltipTemplate")
K.EasyMenu = CreateFrame("Frame", "KKUI_EasyMenu", UIParent, "UIDropDownMenuTemplate")

-- WoW Info
K.WowPatch, K.WowBuild, K.WowRelease, K.TocVersion = GetBuildInfo()
K.WowBuild = tonumber(K.WowBuild)

-- Color Info
K.GreyColor = "|CFFC0C0C0"
K.InfoColor = "|CFF669DFF"
K.InfoColorTint = "|CFF93BAFF" -- 30% Tint
K.SystemColor = "|CFFFFCC66"

-- Media Info
-- Media Info
K.MediaFolder = "Interface\\AddOns\\KkthnxUI\\Media\\"
K.UIFont = "KkthnxUIFont"
K.UIFontSize = select(2, _G.KkthnxUIFont:GetFont())
K.UIFontStyle = select(3, _G.KkthnxUIFont:GetFont())
K.UIFontOutline = "KkthnxUIFontOutline"
K.UIFontSize = select(2, _G.KkthnxUIFontOutline:GetFont())
K.UIFontStyle = select(3, _G.KkthnxUIFontOutline:GetFont())
K.LeftButton = " |TInterface\\TUTORIALFRAME\\UI-TUTORIAL-FRAME:13:11:0:-1:512:512:12:66:230:307|t "
K.RightButton = " |TInterface\\TUTORIALFRAME\\UI-TUTORIAL-FRAME:13:11:0:-1:512:512:12:66:333:410|t "
K.ScrollButton = " |TInterface\\TUTORIALFRAME\\UI-TUTORIAL-FRAME:13:11:0:-1:512:512:12:66:127:204|t "

-- Lists
K.ClassList = {}
K.ClassColors = {}
K.QualityColors = {}
K.AddOns = {}
K.AddOnVersion = {}

-- Flags
-- Constants
K.PartyPetFlags = bit_bor(COMBATLOG_OBJECT_AFFILIATION_PARTY, COMBATLOG_OBJECT_REACTION_FRIENDLY, COMBATLOG_OBJECT_CONTROL_PLAYER, COMBATLOG_OBJECT_TYPE_PET)
K.RaidPetFlags = bit_bor(COMBATLOG_OBJECT_AFFILIATION_RAID, COMBATLOG_OBJECT_REACTION_FRIENDLY, COMBATLOG_OBJECT_CONTROL_PLAYER, COMBATLOG_OBJECT_TYPE_PET)

-- Tables
local eventsFrame = CreateFrame("Frame")
local events = {}
local registeredEvents = {}
local modules = {}
local modulesQueue = {}

-- Variables
local isScaling = false

-- Functions
function K.IsMyPet(flags)
	return bit_band(flags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0
end

-- Populate the ClassList table with localized class names
for k, v in pairs(LOCALIZED_CLASS_NAMES_MALE) do
	K.ClassList[v] = k
end

for k, v in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do
	K.ClassList[v] = k
end

-- Populate the ClassColors table with the colors of each class
local colors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
for class, value in pairs(colors) do
	K.ClassColors[class] = {}
	K.ClassColors[class].r = value.r
	K.ClassColors[class].g = value.g
	K.ClassColors[class].b = value.b
	K.ClassColors[class].colorStr = value.colorStr
end

-- Get the player's class color
K.r, K.g, K.b = K.ClassColors[K.Class].r, K.ClassColors[K.Class].g, K.ClassColors[K.Class].b
K.MyClassColor = string_format("|cff%02x%02x%02x", K.r * 255, K.g * 255, K.b * 255)

-- Populate the QualityColors table with the colors of each item quality
local qualityColors = BAG_ITEM_QUALITY_COLORS
for index, value in pairs(qualityColors) do
	K.QualityColors[index] = { r = value.r, g = value.g, b = value.b }
end
K.QualityColors[-1] = { r = 1, g = 1, b = 1 }
K.QualityColors[LE_ITEM_QUALITY_POOR] = { r = 0.61, g = 0.61, b = 0.61 }
K.QualityColors[LE_ITEM_QUALITY_COMMON] = { r = 1, g = 1, b = 1 }

eventsFrame:SetScript("OnEvent", function(_, event, ...)
	for func in pairs(events[event]) do
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then
			func(event, CombatLogGetCurrentEventInfo())
		else
			func(event, ...)
		end
	end
end)

function K:RegisterEvent(event, func, unit1, unit2)
	if event == "CLEU" then
		event = "COMBAT_LOG_EVENT_UNFILTERED"
	end

	if not events[event] then
		events[event] = {}
		if unit1 then
			eventsFrame:RegisterUnitEvent(event, unit1, unit2)
		else
			eventsFrame:RegisterEvent(event)
		end
	end

	events[event][func] = true

	if not registeredEvents[event] then
		registeredEvents[event] = {}
	end
	table.insert(registeredEvents[event], func)
end

function K:UnregisterEvent(event, func)
	if event == "CLEU" then
		event = "COMBAT_LOG_EVENT_UNFILTERED"
	end

	local funcs = events[event]
	if funcs and funcs[func] then
		funcs[func] = nil

		if not next(funcs) then
			events[event] = nil
			eventsFrame:UnregisterEvent(event)
		end
	end

	if registeredEvents[event] then
		for i, f in ipairs(registeredEvents[event]) do
			if f == func then
				table.remove(registeredEvents[event], i)
				break
			end
		end
	end
end

function K:NewModule(name)
	assert(not modules[name], ("Module '%s' already exists."):format(name))
	local module = { name = name }
	modules[name] = module
	table.insert(modulesQueue, module)
	return module
end

function K:GetModule(name)
	local module = modules[name]
	assert(module, ("Cannot find module '%s'."):format(name))
	return module
end

local function GetBestScale()
	-- Constants
	local PIXEL_RATIO = 768
	local MAX_SCALE = 1.15
	local MIN_SCALE = 0.4

	-- Calculate the best scale based on the current screen height
	return K.Round(math.max(MIN_SCALE, math.min(MAX_SCALE, PIXEL_RATIO / K.ScreenHeight)), 2)
end

function K.SetupUIScale(init)
	-- If autoscaling is enabled, set the UIScale to the best calculated scale
	if C["General"].AutoScale then
		C["General"].UIScale = GetBestScale()
	end

	local scale = C["General"].UIScale

	if not InCombatLockdown() then
		UIParent:SetScale(scale)
	end

	if init then
		local pixelRatio = 768 / K.ScreenHeight
		K.Mult = (1 - pixelRatio) / scale
	end
end

local function UpdatePixelScale(event)
	if isScaling then
		-- Do not update the pixel scale while it is already being updated
		return
	end
	isScaling = true

	if event == "UI_SCALE_CHANGED" then
		-- If the UI scale has changed, update the screen width and height
		K.ScreenWidth, K.ScreenHeight = GetPhysicalScreenSize()
	end

	-- Initialize and setup the UIScale
	K.SetupUIScale(true)
	K.SetupUIScale()

	isScaling = false
end

-- Register events for initializing the addon
K:RegisterEvent("PLAYER_LOGIN", function()
	-- Set CVars
	SetCVar("ActionButtonUseKeyDown", 1)

	-- Set up UI scaling
	K.SetupUIScale()

	-- Register event for UI scale change
	K:RegisterEvent("UI_SCALE_CHANGED", UpdatePixelScale)

	-- Set smoothing amount
	K:SetSmoothingAmount(C["General"].SmoothAmount)

	-- Enable modules
	for _, module in ipairs(modulesQueue) do
		assert(module.OnEnable, "Module has no OnEnable function.")
		assert(not module.Enabled, "Module is already enabled.")

		module:OnEnable()
		module.Enabled = true
	end

	-- Set modules
	K.Modules = modules

	-- Call initialization callback if it exists
	if K.InitCallback then
		K:InitCallback()
	end
end)

-- Event return values were wrong: https://wow.gamepedia.com/PLAYER_LEVEL_UP
K:RegisterEvent("PLAYER_LEVEL_UP", function(_, level)
	if not K.Level then return end
	K.Level = level
end)

-- Save original Chat_DisplayTimePlayed function
local originalChatFrame_DisplayTimePlayed = ChatFrame_DisplayTimePlayed
-- Override ChatFrame_DisplayTimePlayed function
ChatFrame_DisplayTimePlayed = function(_, totalTime, levelTime)
	-- Get player's money as string
	local money = GetMoneyString(GetMoney())

	-- Get player's class
	local localizedClass, englishClass = UnitClass("player")
	local colorClass = K.ClassColors[englishClass]
	local colorString = colorClass.colorStr

	-- Create messages using string formatting
	local totalTimeMessage = string.format("%sTotal time played: %s", K.SystemColor, K.GreyColor .. SecondsToTime(totalTime))
	local levelTimeMessage = string.format("%sTime played this level: %s", K.SystemColor, K.GreyColor .. SecondsToTime(levelTime))
	local moneyMessage = string.format("%sMoney: %s", K.SystemColor, K.GreyColor .. money)

	-- Create player info message using string concatenation
	local playerInfo = string.format("%s %sLevel %d|r |c%s%s|r", K.Name, K.SystemColor, K.Level, colorString, localizedClass)

	-- Print each message on its own line
	print(playerInfo)
	print(totalTimeMessage)
	print(levelTimeMessage)
	print(moneyMessage)
end

for i = 1, GetNumAddOns() do
	local Name, _, _, _, Reason = GetAddOnInfo(i)
	K.AddOns[string_lower(Name)] = GetAddOnEnableState(K.Name, Name) == 2 and (not Reason or Reason ~= "DEMAND_LOADED")
	K.AddOnVersion[string_lower(Name)] = GetAddOnMetadata(Name, "Version")
end

_G.KkthnxUI = Engine
