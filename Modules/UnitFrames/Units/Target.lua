local K, C = KkthnxUI[1], KkthnxUI[2]
local Module = K:GetModule("Unitframes")

-- Lua functions
local select = select

-- WoW API
local CreateFrame = CreateFrame

function Module:CreateTarget()
	self.mystyle = "target"

	local targetWidth = C["Unitframe"].TargetHealthWidth
	local targetHeight = C["Unitframe"].TargetHealthHeight
	local targetPortraitStyle = C["Unitframe"].PortraitStyle.Value

	local UnitframeTexture = K.GetTexture(C["General"].Texture)
	local HealPredictionTexture = K.GetTexture(C["General"].Texture)

	if not self then
		return
	end

	-- Create Overlay
	local Overlay = CreateFrame("Frame", nil, self) -- We will use this to overlay onto our special borders.
	Overlay:SetFrameStrata(self:GetFrameStrata())
	Overlay:SetFrameLevel(5)
	Overlay:SetAllPoints()
	Overlay:EnableMouse(false)
	self.Overlay = Overlay

	Module.CreateHeader(self)

	-- Create Health
	local Health = CreateFrame("StatusBar", nil, self)
	Health:SetHeight(targetHeight)
	Health:SetPoint("TOPLEFT")
	Health:SetPoint("TOPRIGHT")
	Health:SetStatusBarTexture(UnitframeTexture)
	Health:CreateBorder()
	self.Health = Health

	Health.colorTapping = true
	Health.colorDisconnected = true
	Health.frequentUpdates = true

	if C["Unitframe"].Smooth then
		K:SmoothBar(Health)
	end

	if C["Unitframe"].HealthbarColor.Value == "Value" then
		Health.colorSmooth = true
		Health.colorClass = false
		Health.colorReaction = false
	elseif C["Unitframe"].HealthbarColor.Value == "Dark" then
		Health.colorSmooth = false
		Health.colorClass = false
		Health.colorReaction = false
		Health:SetStatusBarColor(0.31, 0.31, 0.31)
	else
		Health.colorSmooth = false
		Health.colorClass = true
		Health.colorReaction = true
	end

	Health.Value = Health:CreateFontString(nil, "OVERLAY")
	Health.Value:SetPoint("CENTER", Health, "CENTER", 0, 0)
	Health.Value:SetFontObject(K.UIFont)
	self:Tag(Health.Value, "[hp]")

	-- Create Power
	local Power = CreateFrame("StatusBar", nil, self)
	Power:SetHeight(C["Unitframe"].TargetPowerHeight)
	Power:SetPoint("TOPLEFT", Health, "BOTTOMLEFT", 0, -6)
	Power:SetPoint("TOPRIGHT", Health, "BOTTOMRIGHT", 0, -6)
	Power:SetStatusBarTexture(UnitframeTexture)
	Power:CreateBorder()
	self.Power = Power

	Power.colorPower = true
	Power.frequentUpdates = true

	if C["Unitframe"].Smooth then
		K:SmoothBar(Power)
	end

	Power.Value = Power:CreateFontString(nil, "OVERLAY")
	Power.Value:SetPoint("CENTER", Power, "CENTER", 0, 0)
	Power.Value:SetFontObject(K.UIFont)
	Power.Value:SetFont(select(1, Power.Value:GetFont()), 11, select(3, Power.Value:GetFont()))
	self:Tag(Power.Value, "[power]")

	local Name = self:CreateFontString(nil, "OVERLAY")
	Name:SetPoint("BOTTOMLEFT", Health, "TOPLEFT", 0, 4)
	Name:SetPoint("BOTTOMRIGHT", Health, "TOPRIGHT", 0, 4)
	Name:SetFontObject(K.UIFont)
	Name:SetWordWrap(false)

	if targetPortraitStyle == "NoPortraits" or targetPortraitStyle == "OverlayPortrait" then
		if C["Unitframe"].HealthbarColor.Value == "Class" then
			self:Tag(Name, "[name] [fulllevel][afkdnd]")
		else
			self:Tag(Name, "[color][name] [fulllevel][afkdnd]")
		end
	else
		if C["Unitframe"].HealthbarColor.Value == "Class" then
			self:Tag(Name, "[name][afkdnd]")
		else
			self:Tag(Name, "[color][name][afkdnd]")
		end
	end

	-- Create Portrait conditionally
	if targetPortraitStyle ~= "NoPortraits" then
		local Portrait
		if targetPortraitStyle == "OverlayPortrait" then
			Portrait = CreateFrame("PlayerModel", "KKUI_TargetPortrait", self)
			Portrait:SetFrameStrata(self:GetFrameStrata())
			Portrait:SetPoint("TOPLEFT", Health, "TOPLEFT", 1, -1)
			Portrait:SetPoint("BOTTOMRIGHT", Health, "BOTTOMRIGHT", -1, 1)
			Portrait:SetAlpha(0.6)
		elseif targetPortraitStyle == "ThreeDPortraits" then
			Portrait = CreateFrame("PlayerModel", "KKUI_TargetPortrait", Health)
			Portrait:SetFrameStrata(self:GetFrameStrata())
			Portrait:SetSize(Health:GetHeight() + Power:GetHeight() + 6, Health:GetHeight() + Power:GetHeight() + 6)
			Portrait:SetPoint("TOPLEFT", self, "TOPRIGHT", 6, 0)
			Portrait:CreateBorder()
		else
			Portrait = Health:CreateTexture("KKUI_TargetPortrait", "BACKGROUND", nil, 1)
			Portrait:SetTexCoord(0.15, 0.85, 0.15, 0.85)
			Portrait:SetSize(Health:GetHeight() + Power:GetHeight() + 6, Health:GetHeight() + Power:GetHeight() + 6)
			Portrait:SetPoint("TOPLEFT", self, "TOPRIGHT", 6, 0)

			Portrait.Border = CreateFrame("Frame", nil, self)
			Portrait.Border:SetAllPoints(Portrait)
			Portrait.Border:CreateBorder()

			if targetPortraitStyle == "ClassPortraits" or targetPortraitStyle == "NewClassPortraits" then
				Portrait.PostUpdate = Module.UpdateClassPortraits
			end
		end

		self.Portrait = Portrait
	end

	-- Target Debuffs
	if C["Unitframe"].TargetDebuffs then -- and C["Unitframe"].TargetDebuffsTop
		local Debuffs = CreateFrame("Frame", nil, self)
		Debuffs.spacing = 6
		Debuffs.initialAnchor = "BOTTOMRIGHT"
		Debuffs["growth-x"] = "LEFT"
		Debuffs["growth-y"] = "UP"
		Debuffs:SetPoint("BOTTOMLEFT", Name, "TOPLEFT", 0, 6)
		Debuffs:SetPoint("BOTTOMRIGHT", Name, "TOPRIGHT", 0, 6)
		Debuffs.num = C["Unitframe"].TargetDebuffsPerRow --* 2   -- count row
		Debuffs.iconsPerRow = C["Unitframe"].TargetDebuffsPerRow

		Module:UpdateAuraContainer(targetWidth, Debuffs, Debuffs.num)

		Debuffs.onlyShowPlayer = C["Unitframe"].OnlyShowPlayerDebuff
		Debuffs.PostCreateIcon = Module.PostCreateIcon
		Debuffs.PostUpdateIcon = Module.PostUpdateIcon

		self.Debuffs = Debuffs
	end

	-- Target Buffs
	if C["Unitframe"].TargetBuffs then -- and C["Unitframe"].TargetDebuffsTop
		local Buffs = CreateFrame("Frame", nil, self)
		Buffs:SetPoint("TOPLEFT", Power, "BOTTOMLEFT", 0, -7)
		Buffs:SetPoint("TOPRIGHT", Power, "BOTTOMRIGHT", 0, -7)
		Buffs.initialAnchor = "TOPRIGHT"
		Buffs["growth-x"] = "LEFT"
		Buffs["growth-y"] = "DOWN"
		Buffs.num = C["Unitframe"].TargetBuffsPerRow * 4  -- count row
		Buffs.spacing = 6
		Buffs.iconsPerRow = C["Unitframe"].TargetBuffsPerRow
		Buffs.onlyShowPlayer = false

		Module:UpdateAuraContainer(targetWidth, Buffs, Buffs.num)

		Buffs.showStealableBuffs = true
		Buffs.PostCreateIcon = Module.PostCreateIcon
		Buffs.PostUpdateIcon = Module.PostUpdateIcon

		self.Buffs = Buffs
	end

	-- Target Castbar
	if C["Unitframe"].TargetCastbar then
		local Castbar = CreateFrame("StatusBar", "oUF_CastbarTarget", self)
		Castbar:SetStatusBarTexture(K.GetTexture(C["General"].Texture))
		Castbar:SetFrameLevel(10)
		Castbar:SetSize(C["Unitframe"].TargetCastbarWidth, C["Unitframe"].TargetCastbarHeight)
		Castbar:CreateBorder()
		Castbar.castTicks = {}

		Castbar.Spark = Castbar:CreateTexture(nil, "OVERLAY", nil, 7)
		Castbar.Spark:SetSize(64, Castbar:GetHeight() - 2)
		Castbar.Spark:SetTexture(C["Media"].Textures.Spark128Texture)
		Castbar.Spark:SetBlendMode("ADD")
		Castbar.Spark:SetAlpha(0.8)

		local timer = K.CreateFontString(Castbar, 12, "", "", false, "RIGHT", -3, 0)
		local name = K.CreateFontString(Castbar, 12, "", "", false, "LEFT", 3, 0)
		name:SetPoint("RIGHT", timer, "LEFT", -5, 0)
		name:SetJustifyH("LEFT")

		Castbar.Icon = Castbar:CreateTexture(nil, "ARTWORK")
		Castbar.Icon:SetSize(Castbar:GetHeight(), Castbar:GetHeight())
		Castbar.Icon:SetPoint("BOTTOMRIGHT", Castbar, "BOTTOMLEFT", -6, 0)
		Castbar.Icon:SetTexCoord(K.TexCoords[1], K.TexCoords[2], K.TexCoords[3], K.TexCoords[4])

		Castbar.Button = CreateFrame("Frame", nil, Castbar)
		Castbar.Button:CreateBorder()
		Castbar.Button:SetAllPoints(Castbar.Icon)
		Castbar.Button:SetFrameLevel(Castbar:GetFrameLevel())

		Castbar.decimal = "%.2f"

		Castbar.Time = timer
		Castbar.Text = name
		Castbar.OnUpdate = Module.OnCastbarUpdate
		Castbar.PostCastStart = Module.PostCastStart
		Castbar.PostCastUpdate = Module.PostCastUpdate
		Castbar.PostCastStop = Module.PostCastStop
		Castbar.PostCastFail = Module.PostCastFailed
		Castbar.PostCastInterruptible = Module.PostUpdateInterruptible

		local mover = K.Mover(Castbar, "Target Castbar", "TargetCB", { "BOTTOM", UIParent, "BOTTOM", 105, 420 }, Castbar:GetHeight() + Castbar:GetWidth() + 6, Castbar:GetHeight())
		Castbar:ClearAllPoints()
		Castbar:SetPoint("RIGHT", mover)
		Castbar.mover = mover

		self.Castbar = Castbar
	end

	-- Heal Prediction
	if C["Unitframe"].ShowHealPrediction then
		local frame = CreateFrame("Frame", nil, self)
		frame:SetAllPoints(Health)

		local myBar = frame:CreateTexture(nil, "BORDER", nil, 5)
		myBar:SetWidth(1)
		myBar:SetTexture(HealPredictionTexture)
		myBar:SetVertexColor(0, 1, 0, 0.5)

		local otherBar = frame:CreateTexture(nil, "BORDER", nil, 5)
		otherBar:SetWidth(1)
		otherBar:SetTexture(HealPredictionTexture)
		otherBar:SetVertexColor(0, 1, 1, 0.5)

		self.HealPredictionAndAbsorb = {
			myBar = myBar,
			otherBar = otherBar,
			maxOverflow = 1,
		}
		self.predicFrame = frame
	end

	-- Level
	local Level = self:CreateFontString(nil, "OVERLAY")
	if targetPortraitStyle ~= "NoPortraits" and targetPortraitStyle ~= "OverlayPortrait" then
		Level:Show()
		Level:SetPoint("BOTTOMLEFT", self.Portrait, "TOPLEFT", 0, 4)
		Level:SetPoint("BOTTOMRIGHT", self.Portrait, "TOPRIGHT", 0, 4)
	else
		Level:Hide()
	end
	Level:SetFontObject(K.UIFont)
	self:Tag(Level, "[fulllevel]")

	if C["Unitframe"].CombatText then
		local parentFrame = CreateFrame("Frame", nil, UIParent)
		local FloatingCombatFeedback = CreateFrame("Frame", "oUF_Target_CombatTextFrame", parentFrame)
		FloatingCombatFeedback:SetSize(32, 32)
		K.Mover(FloatingCombatFeedback, "CombatText", "TargetCombatText", { "BOTTOM", self, "TOPRIGHT", 0, 120 })

		for i = 1, 36 do
			FloatingCombatFeedback[i] = parentFrame:CreateFontString("$parentText", "OVERLAY")
		end

		FloatingCombatFeedback.font = select(1, KkthnxUIFontOutline:GetFont())
		FloatingCombatFeedback.fontFlags = "OUTLINE"
		FloatingCombatFeedback.abbreviateNumbers = true

		self.FloatingCombatFeedback = FloatingCombatFeedback

		-- Default CombatText
		SetCVar("enableFloatingCombatText", 0)
		-- K.HideInterfaceOption(_G.InterfaceOptionsCombatPanelEnableFloatingCombatText)
	end

	if C["Unitframe"].PvPIndicator then
		local PvPIndicator = self:CreateTexture(nil, "OVERLAY")
		PvPIndicator:SetSize(32, 36)
		PvPIndicator:SetAlpha(0.9)
		if targetPortraitStyle ~= "NoPortraits" and targetPortraitStyle ~= "OverlayPortrait" then
			PvPIndicator:SetPoint("LEFT", self.Portrait, "RIGHT", 2, 0)
		else
			PvPIndicator:SetPoint("LEFT", Health, "RIGHT", 2, 0)
		end
		PvPIndicator.PostUpdate = Module.PostUpdatePvPIndicator

		self.PvPIndicator = PvPIndicator
	end

	local LeaderIndicator = Overlay:CreateTexture(nil, "OVERLAY")
	LeaderIndicator:SetSize(16, 16)
	if targetPortraitStyle ~= "NoPortraits" and targetPortraitStyle ~= "OverlayPortrait" then
		LeaderIndicator:SetPoint("TOPRIGHT", self.Portrait, 0, 10)
	else
		LeaderIndicator:SetPoint("TOPRIGHT", Health, 0, 10)
	end
	self.LeaderIndicator = LeaderIndicator

	local AssistantIndicator = Overlay:CreateTexture(nil, "OVERLAY")
	AssistantIndicator:SetSize(16, 16)
	if AssistantIndicator ~= "NoPortraits" and targetPortraitStyle ~= "OverlayPortrait" then
		AssistantIndicator:SetPoint("TOPRIGHT", self.Portrait, 0, 10)
	else
		AssistantIndicator:SetPoint("TOPRIGHT", Health, 0, 10)
	end
	self.AssistantIndicator = AssistantIndicator

	local RaidTargetIndicator = Overlay:CreateTexture(nil, "OVERLAY")
	if targetPortraitStyle ~= "NoPortraits" and targetPortraitStyle ~= "OverlayPortrait" then
		RaidTargetIndicator:SetPoint("TOP", self.Portrait, "TOP", 0, 8)
	else
		RaidTargetIndicator:SetPoint("TOP", Health, "TOP", 0, 8)
	end
	RaidTargetIndicator:SetSize(24, 24)
	self.RaidTargetIndicator = RaidTargetIndicator

	local ReadyCheckIndicator = Overlay:CreateTexture(nil, "OVERLAY")
	if targetPortraitStyle ~= "NoPortraits" and targetPortraitStyle ~= "OverlayPortrait" then
		ReadyCheckIndicator:SetPoint("CENTER", self.Portrait)
	else
		ReadyCheckIndicator:SetPoint("CENTER", Health)
	end
	ReadyCheckIndicator:SetSize(targetHeight - 4, targetHeight - 4)
	self.ReadyCheckIndicator = ReadyCheckIndicator

	local ResurrectIndicator = Overlay:CreateTexture(nil, "OVERLAY")
	ResurrectIndicator:SetSize(44, 44)
	if targetPortraitStyle ~= "NoPortraits" and targetPortraitStyle ~= "OverlayPortrait" then
		ResurrectIndicator:SetPoint("CENTER", self.Portrait)
	else
		ResurrectIndicator:SetPoint("CENTER", Health)
	end
	self.ResurrectIndicator = ResurrectIndicator

	local QuestIndicator = Overlay:CreateTexture(nil, "OVERLAY")
	QuestIndicator:SetSize(20, 20)
	QuestIndicator:SetPoint("TOPLEFT", Health, "TOPRIGHT", -6, 6)
	self.QuestIndicator = QuestIndicator

	if C["Unitframe"].DebuffHighlight then
		local DebuffHighlight = Health:CreateTexture(nil, "OVERLAY")
		DebuffHighlight:SetAllPoints(Health)
		DebuffHighlight:SetTexture(C["Media"].Textures.White8x8Texture)
		DebuffHighlight:SetVertexColor(0, 0, 0, 0)
		DebuffHighlight:SetBlendMode("ADD")

		self.DebuffHighlight = DebuffHighlight
		self.DebuffHighlightAlpha = 0.45
		self.DebuffHighlightFilter = true
	end

	local Highlight = Health:CreateTexture(nil, "OVERLAY")
	Highlight:SetAllPoints()
	Highlight:SetTexture("Interface\\PETBATTLES\\PetBattle-SelectedPetGlow")
	Highlight:SetTexCoord(0, 1, 0.5, 1)
	Highlight:SetVertexColor(0.6, 0.6, 0.6)
	Highlight:SetBlendMode("ADD")
	Highlight:Hide()
	self.Highlight = Highlight

	self.ThreatIndicator = {
		IsObjectType = K.Noop,
		Override = Module.UpdateThreat,
	}

	self.Range = {
		Override = Module.UpdateRange,
	}
end
