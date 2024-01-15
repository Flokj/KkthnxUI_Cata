local K, C = KkthnxUI[1], KkthnxUI[2]
local Module = K:GetModule("Unitframes")

-- Lua functions
local math_rad = math.rad
local pairs = pairs
local string_format = string.format
local table_wipe = table.wipe
local tonumber = tonumber
local unpack = unpack

-- WoW API
local Ambiguate = Ambiguate
local C_NamePlate_GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit
local C_NamePlate_SetNamePlateEnemySize = C_NamePlate.SetNamePlateEnemySize
local C_NamePlate_SetNamePlateFriendlySize = C_NamePlate.SetNamePlateFriendlySize
local CreateFrame = CreateFrame
local GetNumGroupMembers = GetNumGroupMembers
local GetNumSubgroupMembers = GetNumSubgroupMembers
local GetPlayerInfoByGUID = GetPlayerInfoByGUID
local INTERRUPTED = INTERRUPTED
local InCombatLockdown = InCombatLockdown
local IsInGroup = IsInGroup
local IsInRaid = IsInRaid
local SetCVar = SetCVar
local UnitClassification = UnitClassification
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitIsConnected = UnitIsConnected
local UnitIsPlayer = UnitIsPlayer
local UnitIsTapDenied = UnitIsTapDenied
local UnitIsUnit = UnitIsUnit
local UnitName = UnitName
local UnitNameplateShowsWidgetsOnly = UnitNameplateShowsWidgetsOnly
local UnitPlayerControlled = UnitPlayerControlled
local UnitReaction = UnitReaction
local UnitThreatSituation = UnitThreatSituation
local hooksecurefunc = hooksecurefunc

-- Custom data
local customUnits = {}
local showPowerList = {}

-- Unit classification
local NPClassifies = {
	elite = { 1, 1, 1 },
	rare = { 1, 1, 1, true },
	rareelite = { 1, 0.1, 0.1 },
	worldboss = { 0, 1, 0 },
}

-- Init
function Module:UpdatePlateCVars()
	if InCombatLockdown() then return end

	local topInset, bottomInset = -1, -1
	if C["Nameplate"].InsideView then
		topInset, bottomInset = 0.10, 0.12
	end

	SetCVar("nameplateOtherTopInset", topInset)
	SetCVar("nameplateOtherBottomInset", bottomInset)

	local settings = {
		namePlateMinScale = C["Nameplate"].MinScale,
		namePlateMaxScale = C["Nameplate"].MinScale,
		nameplateMinAlpha = C["Nameplate"].MinAlpha,
		nameplateMaxAlpha = C["Nameplate"].MinAlpha,		
		nameplateOverlapV = C["Nameplate"].VerticalSpacing,
		nameplateNotSelectedAlpha = 1,
		nameplateShowOnlyNames =  0,
		nameplateShowFriendlyNPCs = 1,
		ClampTargetNameplateToScreen = 1,
	}

	for cvar, value in pairs(settings) do
		SetCVar(cvar, value)
	end
end

function Module:UpdateClickableSize()
	if InCombatLockdown() then return end

	local uiScale = C["General"].UIScale
	C_NamePlate_SetNamePlateEnemySize(C["Nameplate"].PlateWidth * uiScale, C["Nameplate"].PlateHeight * uiScale)
	C_NamePlate_SetNamePlateFriendlySize(C["Nameplate"].PlateWidth * uiScale, C["Nameplate"].PlateHeight * uiScale)
end

function Module:SetupCVars()
	Module:UpdatePlateCVars()
	local settings = {
		nameplateOverlapH = 0.8,
		nameplateSelectedAlpha = 1,
		nameplateSelectedScale = C["Nameplate"].SelectedScale,
		nameplateLargerScale = 1,
		nameplateGlobalScale = 1,
		nameplateMaxDistance = C["Nameplate"].Distance,
	}

	for cvar, value in pairs(settings) do
		SetCVar(cvar, value)
	end

	Module:UpdateClickableSize()
	hooksecurefunc(NamePlateDriverFrame, "UpdateNamePlateOptions", Module.UpdateClickableSize)
end

function Module:BlockAddons()
	if not DBM or not DBM.Nameplate then return end

	if DBM.Options then
		DBM.Options.DontShowNameplateIconsCD = true
	end

	local function showAurasForDBM(_, _, _, spellID)
		if not tonumber(spellID) then return end
		if not C.NameplateWhiteList[spellID] then
			C.NameplateWhiteList[spellID] = true
		end
	end
	hooksecurefunc(DBM.Nameplate, "Show", showAurasForDBM)
end

function Module:CreateUnitTable()
	table_wipe(customUnits)
	if not C["Nameplate"].CustomUnitColor then return end

	K.CopyTable(C.NameplateCustomUnits, customUnits)
	K.SplitList(customUnits, C["Nameplate"].CustomUnitList)
end

function Module:CreatePowerUnitTable()
	table_wipe(showPowerList)
	K.CopyTable(C.NameplateShowPowerList, showPowerList)
	K.SplitList(showPowerList, C["Nameplate"].PowerUnitList)
end

function Module:UpdateUnitPower()
	local unitName = self.unitName
	local npcID = self.npcID
	local shouldShowPower = showPowerList[unitName] or showPowerList[npcID]
	self.powerText:SetShown(shouldShowPower)
end

-- Off-tank threat color
local groupRoles, isInGroup, myRole = {}
local function refreshGroupRoles()
	local isInRaid = IsInRaid()
	isInGroup = isInRaid or IsInGroup()
	table_wipe(groupRoles)
	myRole = UnitGroupRolesAssigned("player")

	if isInGroup then
		local numPlayers = (isInRaid and GetNumGroupMembers()) or GetNumSubgroupMembers()
		local unit = (isInRaid and "raid") or "party"
		for i = 1, numPlayers do
			local index = unit .. i
			if UnitExists(index) then
				groupRoles[UnitName(index)] = UnitGroupRolesAssigned(index)
			end
		end
	end
end

local function resetGroupRoles()
	isInGroup = IsInRaid() or IsInGroup()
	table_wipe(groupRoles)
end

function Module:UpdateGroupRoles()
	refreshGroupRoles()
	K:RegisterEvent("GROUP_ROSTER_UPDATE", refreshGroupRoles)
	K:RegisterEvent("GROUP_LEFT", resetGroupRoles)
end

function Module:CheckThreatStatus(unit)
	if not UnitExists(unit) then return end

	local unitTarget = unit .. "target"
	local unitRole = isInGroup and UnitExists(unitTarget) and not UnitIsUnit(unitTarget, "player") and groupRoles[UnitName(unitTarget)] or "NONE"

	if myRole == "Tank" and unitRole == "TANK" then
		return true, UnitThreatSituation(unitTarget, unit)
	else
		return false, UnitThreatSituation("player", unit)
	end
end

-- Update unit color
function Module:UpdateColor(_, unit)
	if not unit or self.unit ~= unit then return end

	local element = self.Health
	local name = self.unitName
	local npcID = self.npcID
	local isCustomUnit = customUnits[name] or customUnits[npcID]
	local isPlayer = self.isPlayer
	local isFriendly = self.isFriendly
	local isOffTank, status = Module:CheckThreatStatus(unit)

	local customColor = C["Nameplate"].CustomColor
	local targetColor = C["Nameplate"].TargetColor
	local insecureColor = C["Nameplate"].InsecureColor
	local offTankColor = C["Nameplate"].OffTankColor
	local revertThreat = C["Nameplate"].DPSRevertThreat
	local secureColor = C["Nameplate"].SecureColor
	local transColor = C["Nameplate"].TransColor

	local executeRatio = C["Nameplate"].ExecuteRatio
	local healthPerc = UnitHealth(unit) / (UnitHealthMax(unit) + 0.0001) * 100

	local r, g, b
	if not UnitIsConnected(unit) then
		r, g, b = 0.7, 0.7, 0.7
	else
		if C["Nameplate"].ColoredTarget and UnitIsUnit(unit, "target") then
			r, g, b = targetColor[1], targetColor[2], targetColor[3]
		elseif isCustomUnit then
			r, g, b = customColor[1], customColor[2], customColor[3]
		elseif isPlayer and isFriendly then
			if C["Nameplate"].FriendlyCC then
				r, g, b = K.UnitColor(unit)
			else
				r, g, b = K.Colors.power["MANA"][1], K.Colors.power["MANA"][2], K.Colors.power["MANA"][3]
			end
		elseif isPlayer and not isFriendly and C["Nameplate"].HostileCC then
			r, g, b = K.UnitColor(unit)
		elseif UnitIsTapDenied(unit) and not UnitPlayerControlled(unit) then
			r, g, b = 0.6, 0.6, 0.6
		else
			r, g, b = K.UnitColor(unit)
			if status and (C["Nameplate"].TankMode or myRole == "Tank") then
				if status == 3 then
					if myRole ~= "Tank" and revertThreat then
						r, g, b = insecureColor[1], insecureColor[2], insecureColor[3]
					else
						if isOffTank then
							r, g, b = offTankColor[1], offTankColor[2], offTankColor[3]
						else
							r, g, b = secureColor[1], secureColor[2], secureColor[3]
						end
					end
				elseif status == 2 or status == 1 then
					r, g, b = transColor[1], transColor[2], transColor[3]
				elseif status == 0 then
					if myRole ~= "Tank" and revertThreat then
						r, g, b = secureColor[1], secureColor[2], secureColor[3]
					else
						r, g, b = insecureColor[1], insecureColor[2], insecureColor[3]
					end
				end
			end
		end
	end

	if r or g or b then
		element:SetStatusBarColor(r, g, b)
	end

	self.ThreatIndicator:Hide()
	if status and (isCustomUnit or (not C["Nameplate"].TankMode and myRole ~= "Tank")) then
		if status == 3 then
			self.ThreatIndicator:SetBackdropBorderColor(1, 0, 0)
			self.ThreatIndicator:Show()
		elseif status == 2 or status == 1 then
			self.ThreatIndicator:SetBackdropBorderColor(1, 1, 0)
			self.ThreatIndicator:Show()
		end
	end

	if executeRatio > 0 and healthPerc <= executeRatio then
		self.nameText:SetTextColor(1, 0, 0)
	else
		self.nameText:SetTextColor(1, 1, 1)
	end
end

function Module:UpdateThreatColor(_, unit)
	if unit ~= self.unit then return end

	Module.UpdateColor(self, _, unit)
end

-- Backdrop shadow
function Module:CreateThreatColor(self)
	local threatIndicator = self:CreateShadow()
	threatIndicator:SetPoint("TOPLEFT", self.Health.backdrop, "TOPLEFT", -1, 1)
	threatIndicator:SetPoint("BOTTOMRIGHT", self.Health.backdrop, "BOTTOMRIGHT", 1, -1)
	threatIndicator:Hide()

	self.ThreatIndicator = threatIndicator
	self.ThreatIndicator.Override = Module.UpdateThreatColor
end

-- Target indicator
function Module:UpdateTargetChange()
	local element = self.TargetIndicator
	local unit = self.unit

	if C["Nameplate"].TargetIndicator.Value ~= 1 then
		local isTarget = UnitIsUnit(unit, "target") and not UnitIsUnit(unit, "player")
		element:SetShown(isTarget)

		local shouldPlayAnim = isTarget and not element.TopArrowAnim:IsPlaying()
		local shouldStopAnim = not isTarget and element.TopArrowAnim:IsPlaying()

		if shouldPlayAnim then
			element.TopArrowAnim:Play()
		elseif shouldStopAnim then
			element.TopArrowAnim:Stop()
		end
	end

	if C["Nameplate"].ColoredTarget then
		Module.UpdateThreatColor(self, _, unit)
	end
end

function Module:UpdateTargetIndicator()
	local style = C["Nameplate"].TargetIndicator.Value
	local element = self.TargetIndicator
	local isNameOnly = self.plateType == "NameOnly"

	if style == 1 then
		element:Hide()
		return
	end

	local showTopArrow = style == 2 or style == 5
	local showRightArrow = style == 3 or style == 6
	local showGlow = (style == 4 or style == 5 or style == 6) and not isNameOnly
	local showNameGlow = (style == 4 or style == 5 or style == 6) and isNameOnly

	element.TopArrow:SetShown(showTopArrow)
	element.RightArrow:SetShown(showRightArrow)
	element.Glow:SetShown(showGlow)
	element.nameGlow:SetShown(showNameGlow)
	element:Show()
end

local points = { -15, -5, 0, 5, 0 }

function Module:AddTargetIndicator(self)
	local TargetIndicator = CreateFrame("Frame", nil, self)
	TargetIndicator:SetAllPoints()
	TargetIndicator:SetFrameLevel(0)
	TargetIndicator:Hide()

	-- Function to create and configure arrows
	local function CreateArrow(parent, point, x, y, rotation)
		local arrow = parent:CreateTexture(nil, "BACKGROUND", nil, -5)
		arrow:SetSize(64, 64) -- 128 / 2 simplified
		arrow:SetTexture(C["Nameplate"].TargetIndicatorTexture.Value)
		arrow:SetPoint(point, parent, point, x, y)
		if rotation then
			arrow:SetRotation(rotation)
		end
		return arrow
	end

	-- Top arrow
	TargetIndicator.TopArrow = CreateArrow(TargetIndicator, "BOTTOM", 0, 40)
	local animGroup = TargetIndicator.TopArrow:CreateAnimationGroup()
	animGroup:SetLooping("REPEAT")
	local anim = animGroup:CreateAnimation("Path")
	anim:SetDuration(1)

	for i, offset in ipairs(points) do
		local point = anim:CreateControlPoint()
		point:SetOrder(i)
		point:SetOffset(0, offset)
	end

	TargetIndicator.TopArrowAnim = animGroup

	-- Right arrow
	TargetIndicator.RightArrow = CreateArrow(TargetIndicator, "LEFT", 3, 0, math_rad(-90))

	-- Glow
	TargetIndicator.Glow = CreateFrame("Frame", nil, TargetIndicator, "BackdropTemplate")
	TargetIndicator.Glow:SetPoint("TOPLEFT", self.Health.backdrop, -2, 2)
	TargetIndicator.Glow:SetPoint("BOTTOMRIGHT", self.Health.backdrop, 2, -2)
	TargetIndicator.Glow:SetBackdrop({ edgeFile = C["Media"].Textures.GlowTexture, edgeSize = 4 })
	TargetIndicator.Glow:SetBackdropBorderColor(unpack(C["Nameplate"].TargetIndicatorColor))
	TargetIndicator.Glow:SetFrameLevel(0)

	-- Name glow
	TargetIndicator.nameGlow = TargetIndicator:CreateTexture(nil, "BACKGROUND", nil, -5)
	TargetIndicator.nameGlow:SetSize(150, 80)
	TargetIndicator.nameGlow:SetTexture("Interface\\GLUES\\Models\\UI_Draenei\\GenericGlow64")
	TargetIndicator.nameGlow:SetVertexColor(102 / 255, 157 / 255, 255 / 255)
	TargetIndicator.nameGlow:SetBlendMode("ADD")
	TargetIndicator.nameGlow:SetPoint("CENTER", self, "BOTTOM")

	self.TargetIndicator = TargetIndicator
	self:RegisterEvent("PLAYER_TARGET_CHANGED", Module.UpdateTargetChange, true)
	Module.UpdateTargetIndicator(self)
end

local isInInstance
local function CheckInstanceStatus()
	isInInstance = IsInInstance()
end

function Module:QuestIconCheck()
	if not C["Nameplate"].QuestIndicator then return end

	CheckInstanceStatus()
	K:RegisterEvent("PLAYER_ENTERING_WORLD", CheckInstanceStatus)
end

function Module:UpdateQuestUnit(_, unit)
	if not C["Nameplate"].QuestIndicator then return end

	if isInInstance then
		self.questIcon:Hide()
		self.questCount:SetText("")
		return
	end

	unit = unit or self.unit

	local questProgress
	local prevDiff = 0
	local data = C_TooltipInfo.GetUnit(unit)

	if data then
		for i = 1, #data.lines do
			local lineData = data.lines[i]
			if lineData.type == 8 then
				local text = lineData.leftText
				if text then
					local current, goal = strmatch(text, "(%d+)/(%d+)")
					local progress = strmatch(text, "(%d+)%%")
					if current and goal then
						local diff = floor(goal - current)
						if diff > prevDiff then
							questProgress = diff
							prevDiff = diff
						end
					elseif progress and prevDiff == 0 then
						questProgress = progress .. "%"
						break -- Exit loop if progress is found
					end
				end
			end
		end
	end

	if questProgress then
		self.questCount:SetText(questProgress)
		self.questIcon:SetAtlas("pvptalents-warmode-swords")
		self.questIcon:Show()
	else
		self.questCount:SetText("")
		if isLootQuest then
			self.questIcon:SetAtlas("QuestNormal")
			self.questIcon:Show()
		else
			self.questIcon:Hide()
		end
	end
end

function Module:AddQuestIcon(self)
	if not C["Nameplate"].QuestIndicator then return end

	self.questIcon = self:CreateTexture(nil, "OVERLAY", nil, 2)
	self.questIcon:SetPoint("LEFT", self, "RIGHT", 1, 0)
	self.questIcon:SetSize(28, 25)
	self.questIcon:SetAtlas("QuestNormal")
	self.questIcon:Hide()

	self.questCount = K.CreateFontString(self, 13, "", "", nil, "LEFT", 0, 0)
	self.questCount:SetPoint("LEFT", self.questIcon, "RIGHT", -2, 0)
	-- Fired whenever the quest log changes. (Frequently, but not as frequently as QUEST_LOG_UPDATE)
	--self:RegisterEvent("UNIT_QUEST_LOG_CHANGED", Module.UpdateQuestUnit, true)
end

function Module:AddClassIcon(self)
	if not C["Nameplate"].ClassIcon then return	end

	self.Class = CreateFrame("Frame", nil, self)
	self.Class:SetSize(self:GetHeight() * 2 + 3, self:GetHeight() * 2 + 3)
	self.Class:SetPoint("BOTTOMLEFT", self.Castbar, "BOTTOMRIGHT", 3, 0)
	self.Class:CreateShadow(true)

	self.Class.Icon = self.Class:CreateTexture(nil, "OVERLAY")
	self.Class.Icon:SetAllPoints()
	self.Class.Icon:SetTexture("Interface\\WorldStateFrame\\Icons-Classes")
	self.Class.Icon:SetTexCoord(0, 0, 0, 0)
end

function Module:UpdateClassIcon(self, unit)
	if not C["Nameplate"].ClassIcon then return	end

	local reaction = UnitReaction(unit, "player")
	if UnitIsPlayer(unit) and (reaction and reaction <= 4) then
		local _, class = UnitClass(unit)
		local texcoord = CLASS_ICON_TCOORDS[class]
		self.Class.Icon:SetTexCoord(texcoord[1] + 0.015, texcoord[2] - 0.02, texcoord[3] + 0.018, texcoord[4] - 0.02)
		self.Class:Show()
	else
		self.Class.Icon:SetTexCoord(0, 0, 0, 0)
		self.Class:Hide()
	end
end

function Module:AddCreatureIcon(self)
	local iconFrame = CreateFrame("Frame", nil, self)
	iconFrame:SetAllPoints()
	iconFrame:SetFrameLevel(self:GetFrameLevel() + 2)

	local ClassifyIndicator = iconFrame:CreateTexture(nil, "ARTWORK")
	ClassifyIndicator:SetTexture(K.MediaFolder .. "Nameplates\\star")
	ClassifyIndicator:SetPoint("RIGHT", self.nameText, "LEFT")
	ClassifyIndicator:SetSize(14, 14)
	ClassifyIndicator:Hide()

	self.ClassifyIndicator = ClassifyIndicator
end

function Module:UpdateUnitClassify(unit)
	if not self.ClassifyIndicator then return end
	if not unit then unit = self.unit end

	self.ClassifyIndicator:Hide()

	local class = UnitClassification(unit)
	local classify = class and NPClassifies[class]
	if classify then
		local r, g, b, desature = unpack(classify)
		self.ClassifyIndicator:SetVertexColor(r, g, b)
		self.ClassifyIndicator:SetDesaturated(desature)
		self.ClassifyIndicator:Show()
	end
end

-- Mouseover indicator
function Module:IsMouseoverUnit()
	if not self or not self.unit then return end

	if self:IsVisible() and UnitExists("mouseover") then
		return UnitIsUnit("mouseover", self.unit)
	end

	return false
end

function Module:UpdateMouseoverShown()
	if not self or not self.unit then return end

	if self:IsShown() and UnitIsUnit("mouseover", self.unit) then
		self.HighlightIndicator:Show()
		self.HighlightUpdater:Show()
	else
		self.HighlightUpdater:Hide()
	end
end

function Module:HighlightOnUpdate(elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	if self.elapsed > 0.1 then
		if not Module.IsMouseoverUnit(self.__owner) then
			self:Hide()
		end
		self.elapsed = 0
	end
end

function Module:HighlightOnHide()
	self.__owner.HighlightIndicator:Hide()
end

function Module:MouseoverIndicator(self)
	local highlight = CreateFrame("Frame", nil, self.Health)
	highlight:SetAllPoints(self)
	highlight:Hide()

	local texture = highlight:CreateTexture(nil, "ARTWORK")
	texture:SetAllPoints()
	texture:SetColorTexture(1, 1, 1, 0.25)

	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT", Module.UpdateMouseoverShown, true)

	local updater = CreateFrame("Frame", nil, self)
	updater.__owner = self
	updater:SetScript("OnUpdate", Module.HighlightOnUpdate)
	updater:HookScript("OnHide", Module.HighlightOnHide)

	self.HighlightIndicator = highlight
	self.HighlightUpdater = updater
end

-- Interrupt info on castbars
function Module:UpdateSpellInterruptor(...)
	local _, _, sourceGUID, sourceName, _, _, destGUID = ...
	if destGUID == self.unitGUID and sourceGUID and sourceName and sourceName ~= "" then
		local _, class = GetPlayerInfoByGUID(sourceGUID)
		local r, g, b = K.ColorClass(class)
		local color = K.RGBToHex(r, g, b)
		local sourceName = Ambiguate(sourceName, "short")
		self.Castbar.Text:SetText(INTERRUPTED .. " > " .. color .. sourceName)
		self.Castbar.Time:SetText("")
	end
end

function Module:SpellInterruptor(self)
	if not self.Castbar then return end
	self:RegisterCombatEvent("SPELL_INTERRUPT", Module.UpdateSpellInterruptor)
end

local function updateSpellTarget(self, _, unit)
	Module.PostCastUpdate(self.Castbar, unit)
end

-- Create Nameplates
local platesList = {}
function Module:CreatePlates()
	self.mystyle = "nameplate"

	self:SetSize(C["Nameplate"].PlateWidth, C["Nameplate"].PlateHeight)
	self:SetPoint("CENTER")
	self:SetScale(C["General"].UIScale)

	self.Health = CreateFrame("StatusBar", nil, self)
	self.Health:SetAllPoints()
	self.Health:SetStatusBarTexture(K.GetTexture(C["General"].Texture))

	self.Overlay = CreateFrame("Frame", nil, self) -- We will use this to overlay onto our special borders.
	self.Overlay:SetAllPoints(self.Health)
	self.Overlay:SetFrameLevel(4)

	self.Health.backdrop = self.Health:CreateShadow(true) -- don't mess up with libs
	self.Health.backdrop:SetPoint("TOPLEFT", self.Health, "TOPLEFT", -3, 3)
	self.Health.backdrop:SetPoint("BOTTOMRIGHT", self.Health, "BOTTOMRIGHT", 3, -3)
	self.Health.backdrop:SetFrameLevel(self.Health:GetFrameLevel())

	self.Health.frequentUpdates = true
	self.Health.UpdateColor = Module.UpdateColor

	if C["Nameplate"].Smooth then
		K:SmoothBar(self.Health)
	end

	self.nameText = K.CreateFontString(self, C["Nameplate"].NameTextSize, "", "", false)
	self.nameText:SetJustifyH("CENTER")
	self.nameText:ClearAllPoints()
	self.nameText:SetPoint("BOTTOMLEFT", self, "TOPLEFT", -3, 4)
	self.nameText:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", -3, 4)

	self.npcTitle = K.CreateFontString(self, C["Nameplate"].NameTextSize - 1)
	self.npcTitle:ClearAllPoints()
	self.npcTitle:SetPoint("TOP", self.nameText, "BOTTOM", 0, -4)
	self.npcTitle:Hide()
	self:Tag(self.npcTitle, "[npctitle]")

	self.tarName = K.CreateFontString(self, C["Nameplate"].NameTextSize + 2)
	self.tarName:ClearAllPoints()
	self.tarName:SetPoint("TOP", self, "BOTTOM", 0, -10)
	self.tarName:Hide()
	self:Tag(self.tarName, "[tarname]")

	self.healthValue = K.CreateFontString(self.Overlay, C["Nameplate"].HealthTextSize, "", "", false, "CENTER", 0, 0)
	self.healthValue:SetPoint("CENTER", self.Overlay, 0, 0)
	self:Tag(self.healthValue, "[nphp]")

	self.Castbar = CreateFrame("StatusBar", "oUF_CastbarNameplate", self)
	self.Castbar:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -3)
	self.Castbar:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -3)
	self.Castbar:SetHeight(self:GetHeight())
	self.Castbar:SetStatusBarTexture(K.GetTexture(C["General"].Texture))
	self.Castbar:SetFrameLevel(10)
	self.Castbar:CreateShadow(true)
	self.Castbar.castTicks = {}

	self.Castbar.Spark = self.Castbar:CreateTexture(nil, "OVERLAY", nil, 2)
	self.Castbar.Spark:SetSize(64, self.Castbar:GetHeight() - 2)
	self.Castbar.Spark:SetTexture(C["Media"].Textures.Spark128Texture)
	self.Castbar.Spark:SetBlendMode("ADD")
	self.Castbar.Spark:SetAlpha(0.8)

	self.Castbar.Time = K.CreateFontString(self.Castbar, 12, "", "", false, "RIGHT", 0, -1)
	self.Castbar.Text = K.CreateFontString(self.Castbar, 12, "", "", false, "LEFT", 0, -1)
	self.Castbar.Text:SetPoint("RIGHT", self.Castbar.Time, "LEFT", -5, 0)
	self.Castbar.Text:SetJustifyH("LEFT")

	self.Castbar.Icon = self.Castbar:CreateTexture(nil, "ARTWORK")
	self.Castbar.Icon:SetSize(self:GetHeight() * 2 + 5, self:GetHeight() * 2 + 5)
	self.Castbar.Icon:SetPoint("BOTTOMRIGHT", self.Castbar, "BOTTOMLEFT", -3, 0)
	self.Castbar.Icon:SetTexCoord(K.TexCoords[1], K.TexCoords[2], K.TexCoords[3], K.TexCoords[4])

	self.Castbar.Button = CreateFrame("Frame", nil, self.Castbar)
	self.Castbar.Button:CreateShadow(true)
	self.Castbar.Button:SetAllPoints(self.Castbar.Icon)
	self.Castbar.Button:SetFrameLevel(self.Castbar:GetFrameLevel())

	self.Castbar.glowFrame = CreateFrame("Frame", nil, self.Castbar)
	self.Castbar.glowFrame:SetPoint("CENTER", self.Castbar.Icon)
	self.Castbar.glowFrame:SetSize(self:GetHeight() * 2 + 5, self:GetHeight() * 2 + 5)

	self.Castbar.spellTarget = K.CreateFontString(self.Castbar, C["Nameplate"].NameTextSize + 2)
	self.Castbar.spellTarget:ClearAllPoints()
	self.Castbar.spellTarget:SetJustifyH("LEFT")
	self.Castbar.spellTarget:SetPoint("TOPLEFT", self.Castbar.Text, "BOTTOMLEFT", 0, -6)
	self:RegisterEvent("UNIT_TARGET", updateSpellTarget)

	self.Castbar.timeToHold = 0.5
	self.Castbar.decimal = "%.1f"
	self.Castbar.OnUpdate = Module.OnCastbarUpdate
	self.Castbar.PostCastStart = Module.PostCastStart
	self.Castbar.PostCastUpdate = Module.PostCastUpdate
	self.Castbar.PostCastStop = Module.PostCastStop
	self.Castbar.PostCastFail = Module.PostCastFailed
	self.Castbar.PostCastInterruptible = Module.PostUpdateInterruptible

	self.RaidTargetIndicator = self:CreateTexture(nil, "OVERLAY")
	self.RaidTargetIndicator:SetPoint("TOPRIGHT", self, "TOPLEFT", -8, 25)
	self.RaidTargetIndicator:SetSize(40, 40)

	self.Auras = CreateFrame("Frame", nil, self)
	self.Auras:SetFrameLevel(self:GetFrameLevel() + 2)
	self.Auras.spacing = 8
	self.Auras.initdialAnchor = "BOTTOMLEFT"
	self.Auras["growth-y"] = "UP"
	if C["Nameplate"].NameplateClassPower then
		self.Auras:SetPoint("BOTTOMLEFT", self.nameText, "TOPLEFT", 0, 6 + C["Nameplate"].PlateHeight)
		self.Auras:SetPoint("BOTTOMRIGHT", self.nameText, "TOPRIGHT", 0, 6 + C["Nameplate"].PlateHeight)
	else
		self.Auras:SetPoint("BOTTOMLEFT", self.nameText, "TOPLEFT", 0, 6)
		self.Auras:SetPoint("BOTTOMRIGHT", self.nameText, "TOPRIGHT", 0, 6)
	end
	self.Auras.numTotal = C["Nameplate"].MaxAuras
	self.Auras.size = C["Nameplate"].AuraSize
	self.Auras.gap = false
	self.Auras.disableMouse = true
	self.Auras.CustomFilter = Module.CustomFilter

	Module:UpdateAuraContainer(self:GetWidth(), self.Auras, self.Auras.numTotal)

	self.Auras.showStealableBuffs = true
	self.Auras.PostCreateButton = Module.PostCreateButton
	self.Auras.PostUpdateButton = Module.PostUpdateButton

	Module:CreateThreatColor(self)

	self.PvPClassificationIndicator = self:CreateTexture(nil, "ARTWORK")
	self.PvPClassificationIndicator:SetSize(18, 18)
	self.PvPClassificationIndicator:ClearAllPoints()
	if C["Nameplate"].ClassIcon then
		self.PvPClassificationIndicator:SetPoint("TOPLEFT", self, "TOPRIGHT", 5, 20)
	else
		self.PvPClassificationIndicator:SetPoint("LEFT", self, "RIGHT", 6, 0)
	end

	self.powerText = K.CreateFontString(self, 15)
	self.powerText:ClearAllPoints()
	self.powerText:SetPoint("TOP", self.Castbar, "BOTTOM", 0, -4)
	self:Tag(self.powerText, "[nppp]")

	Module:MouseoverIndicator(self)
	Module:AddTargetIndicator(self)
	Module:AddCreatureIcon(self)
	Module:AddQuestIcon(self)
	Module:SpellInterruptor(self)
	Module:AddClassIcon(self)

	platesList[self] = self:GetName()
end

function Module:ToggleNameplateAuras()
	if C["Nameplate"].PlateAuras then
		if not self:IsElementEnabled("Auras") then
			self:EnableElement("Auras")
		end
	else
		if self:IsElementEnabled("Auras") then
			self:DisableElement("Auras")
		end
	end
end

function Module:UpdateNameplateAuras()
	Module.ToggleNameplateAuras(self)

	if not C["Nameplate"].PlateAuras then return end

	local element = self.Auras
	if C["Nameplate"].NameplateClassPower then
		element:SetPoint("BOTTOMLEFT", self.nameText, "TOPLEFT", 0, 6 + C["Nameplate"].PlateHeight)
	else
		element:SetPoint("BOTTOMLEFT", self.nameText, "TOPLEFT", 0, 5)
	end

	element.numTotal = C["Nameplate"].MaxAuras
	element.size = C["Nameplate"].AuraSize
	element.showDebuffType = true
	element:SetWidth(self:GetWidth())
	element:SetHeight((element.size + element.spacing) * 2)

	element:ForceUpdate()
end

function Module:UpdateNameplateSize()
	-- local plateHeight = C["Nameplate"].PlateHeight
	-- local nameTextSize = C["Nameplate"].NameTextSize
	-- local iconSize = plateHeight * 2 + 3

	-- self:SetSize(C["Nameplate"].PlateWidth, plateHeight)

	-- self.nameText:SetFont(select(1, KkthnxUIFont:GetFont()), nameTextSize, "")
	if self.plateType == "NameOnly" then
		self:Tag(self.nameText, "[nprare] [color][name] [nplevel]")
		self.npcTitle:UpdateTag()
	else
		self:Tag(self.nameText, "[name]")
	end

	-- self.npcTitle:SetFont(select(1, KkthnxUIFont:GetFont()), nameTextSize - 1, "")
	-- self.tarName:SetFont(select(1, KkthnxUIFont:GetFont()), nameTextSize + 4, "")

	-- self.Castbar.Icon:SetSize(iconSize, iconSize)
	-- self.Castbar:SetHeight(plateHeight)
	-- self.Castbar.Time:SetFont(select(1, KkthnxUIFont:GetFont()), nameTextSize-1, "")
	-- self.Castbar.Text:SetFont(select(1, KkthnxUIFont:GetFont()), nameTextSize-1, "")
	-- self.Castbar.Time:SetPoint("TOPRIGHT", self.Castbar, "RIGHT", 0, 5)
	-- self.Castbar.Text:SetPoint("TOPLEFT", self.Castbar, "LEFT", 0, 5)
	-- self.Castbar.spellTarget:SetFont(select(1, KkthnxUIFont:GetFont()), nameTextSize + 3, "")
 
	-- self.healthValue:SetFont(select(1, KkthnxUIFont:GetFont()), C["Nameplate"].HealthTextSize, "")
	-- self.healthValue:UpdateTag()

	self.nameText:UpdateTag()
end

function Module:RefreshNameplats()
	for nameplate in pairs(platesList) do
		--Module.UpdateNameplateSize(nameplate)
		Module.UpdateUnitClassify(nameplate)
		Module.UpdateNameplateAuras(nameplate)
		Module.UpdateTargetIndicator(nameplate)
		Module.UpdateTargetChange(nameplate)
	end
	Module:UpdateClickableSize()
end

function Module:RefreshAllPlates()
	Module:RefreshNameplats()
	Module:ResizeTargetPower()
end

local DisabledElements = {
	"Health",
	"Castbar",
	"HealthPrediction",
	"ThreatIndicator",
}
function Module:UpdatePlateByType()
	local name = self.nameText
	local hpval = self.healthValue
	local title = self.npcTitle
	local raidtarget = self.RaidTargetIndicator
	local questIcon = self.questIcon

	name:SetShown(not self.widgetsOnly)
	name:ClearAllPoints()
	self:Tag(self.nameText, "[nprare] [color][name] [nplevel]")
	self.npcTitle:UpdateTag()
	raidtarget:ClearAllPoints()

	if self.plateType == "NameOnly" then
		for _, element in pairs(DisabledElements) do
			if self:IsElementEnabled(element) then
				self:DisableElement(element)
			end
		end

		name:SetJustifyH("CENTER")
		name:SetPoint("CENTER", self, "BOTTOM")

		hpval:Hide()
		title:Hide()

		raidtarget:SetPoint("BOTTOM", name, "TOP", 0, 5)
		raidtarget:SetParent(self)

		if questIcon then questIcon:SetPoint("LEFT", name, "RIGHT", 0, 0) end

		if self.widgetContainer then
			self.widgetContainer:ClearAllPoints()
			self.widgetContainer:SetPoint("TOP", title, "BOTTOM", 0, -5)
		end
	else
		for _, element in pairs(DisabledElements) do
			if not self:IsElementEnabled(element) then
				self:EnableElement(element)
			end
		end

		name:SetJustifyH("CENTER")
		name:SetPoint("BOTTOMLEFT", self, "TOPLEFT", -3, 4)
		name:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", -3, 4)
		self:Tag(self.nameText, "[name]")

		hpval:Show()
		title:Hide()

		raidtarget:SetPoint("TOPRIGHT", self, "TOPLEFT", -8, 25)

		if questIcon then questIcon:SetPoint("LEFT", self, "RIGHT", 1, 0) end

		if self.widgetContainer then
			self.widgetContainer:ClearAllPoints()
			self.widgetContainer:SetPoint("TOP", self.Castbar, "BOTTOM", 0, -5)
		end
	end
	
	--Module.UpdateNameplateSize(self)
	Module.UpdateTargetIndicator(self)
	Module.ToggleNameplateAuras(self)
end

function Module:RefreshPlateType(unit)
	self.reaction = UnitReaction(unit, "player")
	self.isFriendly = self.reaction and self.reaction >= 4 and not UnitCanAttack("player", unit)
	if C["Nameplate"].NameOnly and self.isFriendly or self.widgetsOnly then
		self.plateType = "NameOnly"
	elseif C["Nameplate"].FriendPlate and self.isFriendly then
		self.plateType = "FriendPlate"
	else
		self.plateType = "None"
	end

	if self.previousType == nil or self.previousType ~= self.plateType then
		Module.UpdatePlateByType(self)
		self.previousType = self.plateType
	end
end

function Module:OnUnitFactionChanged(unit)
	local nameplate = C_NamePlate_GetNamePlateForUnit(unit, issecure())
	local unitFrame = nameplate and nameplate.unitFrame
	if unitFrame and unitFrame.unitName then
		Module.RefreshPlateType(unitFrame, unit)
	end
end

function Module:RefreshPlateOnFactionChanged()
	K:RegisterEvent("UNIT_FACTION", Module.OnUnitFactionChanged)
end

function Module:PostUpdatePlates(event, unit)
	if not self then return end

	if event == "NAME_PLATE_UNIT_ADDED" then
		self.unitName = UnitName(unit)
		self.unitGUID = UnitGUID(unit)
		self.isPlayer = UnitIsPlayer(unit)
		self.npcID = K.GetNPCID(self.unitGUID)

		Module.RefreshPlateType(self, unit)
	elseif event == "NAME_PLATE_UNIT_REMOVED" then
		self.npcID = nil
	end

	if event ~= "NAME_PLATE_UNIT_REMOVED" then
		Module.UpdateUnitPower(self)
		Module.UpdateTargetChange(self)
		--Module.UpdateQuestUnit(self, event, unit)
		Module.UpdateUnitClassify(self, unit)
		Module:UpdateClassIcon(self, unit)
		Module:UpdateTargetClassPower()
	end
end

-- Player Nameplate
function Module:PlateVisibility(event)
	if (event == "PLAYER_REGEN_DISABLED" or InCombatLockdown()) and UnitIsUnit("player", self.unit) then
		UIFrameFadeIn(self.Health, 0.2, self.Health:GetAlpha(), 1)
		UIFrameFadeIn(self.Power, 0.2, self.Power:GetAlpha(), 1)
		UIFrameFadeIn(self.Auras, 0.2, self.Power:GetAlpha(), 1)
	else
		UIFrameFadeOut(self.Health, 0.2, self.Health:GetAlpha(), 0)
		UIFrameFadeOut(self.Power, 0.2, self.Power:GetAlpha(), 0)
		UIFrameFadeOut(self.Auras, 0.2, self.Power:GetAlpha(), 0)
	end
end

function Module:CreatePlayerPlate()
	self.mystyle = "PlayerPlate"

	local iconSize, margin = C["Nameplate"].PPIconSize, 2
	self:SetSize(iconSize * 5 + margin * 4, C["Nameplate"].PPHeight)
	self:EnableMouse(false)
	self.iconSize = iconSize

	self.Health = CreateFrame("StatusBar", nil, self)
	self.Health:SetAllPoints()
	self.Health:SetStatusBarTexture(K.GetTexture(C["General"].Texture))
	self.Health:SetStatusBarColor(0.1, 0.1, 0.1)
	self.Health:CreateShadow(true)

	self.Health.colorClass = true

	self.Power = CreateFrame("StatusBar", nil, self)
	self.Power:SetStatusBarTexture(K.GetTexture(C["General"].Texture))
	self.Power:SetHeight(C["Nameplate"].PPPHeight)
	self.Power:SetWidth(self:GetWidth())
	self.Power:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -3)
	self.Power:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -3)
	self.Power:CreateShadow(true)

	self.Power.colorPower = true
	self.Power.frequentUpdates = true

	Module:CreateClassPower(self)

	local textFrame = CreateFrame("Frame", nil, self.Power)
	textFrame:SetAllPoints()
	self.powerText = K.CreateFontString(textFrame, 12, "")
	self:Tag(self.powerText, "[pppower]")
	Module:TogglePlatePower()

	Module:CreateGCDTicker(self)
	Module:UpdateTargetClassPower()
	Module:TogglePlateVisibility()
end

function Module:TogglePlayerPlate()
	local plate = _G.oUF_PlayerPlate
	if not plate then return end

	if C["Nameplate"].ShowPlayerPlate then
		plate:Enable()
	else
		plate:Disable()
	end
end

function Module:TogglePlatePower()
	local plate = oUF_PlayerPlate
	if not plate then return end

	plate.powerText:SetShown(C["Nameplate"].PPPowerText)
end

function Module:TogglePlateVisibility()
	local plate = oUF_PlayerPlate
	if not plate then return end

	if C["Nameplate"].PPHideOOC then
		plate:RegisterEvent("UNIT_EXITED_VEHICLE", Module.PlateVisibility)
		plate:RegisterEvent("UNIT_ENTERED_VEHICLE", Module.PlateVisibility)
		plate:RegisterEvent("PLAYER_REGEN_ENABLED", Module.PlateVisibility, true)
		plate:RegisterEvent("PLAYER_REGEN_DISABLED", Module.PlateVisibility, true)
		plate:RegisterEvent("PLAYER_ENTERING_WORLD", Module.PlateVisibility, true)
		Module.PlateVisibility(plate)
	else
		plate:UnregisterEvent("UNIT_EXITED_VEHICLE", Module.PlateVisibility)
		plate:UnregisterEvent("UNIT_ENTERED_VEHICLE", Module.PlateVisibility)
		plate:UnregisterEvent("PLAYER_REGEN_ENABLED", Module.PlateVisibility)
		plate:UnregisterEvent("PLAYER_REGEN_DISABLED", Module.PlateVisibility)
		plate:UnregisterEvent("PLAYER_ENTERING_WORLD", Module.PlateVisibility)
		Module.PlateVisibility(plate, "PLAYER_REGEN_DISABLED")
	end
end

-- Target nameplate
function Module:CreateTargetPlate()
	self.mystyle = "targetplate"
	self:EnableMouse(false)
	self:SetSize(10, 10)

	Module:CreateClassPower(self)
end

function Module:UpdateTargetClassPower()
	local plate = _G.oUF_TargetPlate
	if not plate then return end

	local bar = plate.ClassPowerBar
	local nameplate = C_NamePlate_GetNamePlateForUnit("target")
	if nameplate then
		bar:SetParent(nameplate.unitFrame)
		bar:ClearAllPoints()
		bar:SetPoint("BOTTOM", nameplate.unitFrame, "TOP", 0, 20)
		bar:Show()
	else
		bar:Hide()
	end
end

function Module:ToggleTargetClassPower()
	local plate = oUF_TargetPlate
	if not plate then return end

	local playerPlate = _G.oUF_PlayerPlate
	if C["Nameplate"].NameplateClassPower then
		plate:Enable()
		if plate.ClassPower then
			if not plate:IsElementEnabled("ClassPower") then
				plate:EnableElement("ClassPower")
				plate.ClassPower:ForceUpdate()
			end
			if playerPlate then
				if playerPlate:IsElementEnabled("ClassPower") then
					playerPlate:DisableElement("ClassPower")
				end
			end
		end

		if plate.Runes then
			if not plate:IsElementEnabled("Runes") then
				plate:EnableElement("Runes")
				plate.Runes:ForceUpdate()
			end
			if playerPlate then
				if playerPlate:IsElementEnabled("Runes") then
					playerPlate:DisableElement("Runes")
				end
			end
		end
	else
		plate:Disable()
		if plate.ClassPower then
			if plate:IsElementEnabled("ClassPower") then
				plate:DisableElement("ClassPower")
			end
			if playerPlate then
				if not playerPlate:IsElementEnabled("ClassPower") then
					playerPlate:EnableElement("ClassPower")
					playerPlate.ClassPower:ForceUpdate()
				end
			end
		end
		if plate.Runes then
			if plate:IsElementEnabled("Runes") then
				plate:DisableElement("Runes")
			end
			if playerPlate then
				if not playerPlate:IsElementEnabled("Runes") then
					playerPlate:EnableElement("Runes")
					playerPlate.Runes:ForceUpdate()
				end
			end
		end
	end
end

function Module:ResizeTargetPower()
	local plate = oUF_TargetPlate
	if not plate then return end

	local barWidth = C["Nameplate"].PlateWidth
	local barHeight = C["Nameplate"].PlateHeight
	local bars = plate.ClassPower or plate.Runes
	if bars then
		plate.ClassPowerBar:SetSize(barWidth, barHeight)
		local max = bars.__max
		for i = 1, max do
			bars[i]:SetHeight(barHeight)
			bars[i]:SetWidth((barWidth - (max - 1) * 6) / max)
		end
	end
end

function Module:CreateGCDTicker(self)
	if not C["Nameplate"].PPGCDTicker then return end

	local GCD = CreateFrame("Frame", "oUF_PlateGCD", self.Power)
	GCD:SetWidth(self:GetWidth())
	GCD:SetHeight(C["Nameplate"].PPPHeight)
	GCD:SetPoint("LEFT", self.Power, "LEFT", 0, 0)

	GCD.Color = { 1, 1, 1, 0.6 }
	GCD.Texture = C["Media"].Textures.Spark128Texture
	GCD.Height = C["Nameplate"].PPPHeight
	GCD.Width = 128 / 2

	self.GCD = GCD
end