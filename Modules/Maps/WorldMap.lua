local K, C = KkthnxUI[1], KkthnxUI[2]
local Module = K:NewModule("WorldMap")

local select, wipe, strmatch, gmatch, tinsert, pairs = select, wipe, strmatch, gmatch, tinsert, pairs
local tonumber, format, ceil, mod = tonumber, format, ceil, mod
local WorldMapFrame = WorldMapFrame
local CreateVector2D = CreateVector2D
local UnitPosition = UnitPosition
local C_Map_GetMapArtID = C_Map.GetMapArtID
local C_Map_GetMapArtLayers = C_Map.GetMapArtLayers
local C_Map_GetBestMapForUnit = C_Map.GetBestMapForUnit
local C_Map_GetWorldPosFromMapPos = C_Map.GetWorldPosFromMapPos
local C_MapExplorationInfo_GetExploredMapTextures = C_MapExplorationInfo.GetExploredMapTextures
local TexturePool_HideAndClearAnchors = TexturePool_HideAndClearAnchors

local mapRects = {}
local tempVec2D = CreateVector2D(0, 0)
local currentMapID, playerCoords, cursorCoords

function Module:GetPlayerMapPos(mapID)
	if not mapID then return end
	tempVec2D.x, tempVec2D.y = UnitPosition("player")
	if not tempVec2D.x then return end

	local mapRect = mapRects[mapID]
	if not mapRect then
		mapRect = {}
		mapRect[1] = select(2, C_Map_GetWorldPosFromMapPos(mapID, CreateVector2D(0, 0)))
		mapRect[2] = select(2, C_Map_GetWorldPosFromMapPos(mapID, CreateVector2D(1, 1)))
		mapRect[2]:Subtract(mapRect[1])

		mapRects[mapID] = mapRect
	end
	tempVec2D:Subtract(mapRect[1])

	return tempVec2D.y / mapRect[2].y, tempVec2D.x / mapRect[2].x
end

function Module:GetCursorCoords()
	if not WorldMapFrame.ScrollContainer:IsMouseOver() then return end

	local cursorX, cursorY = WorldMapFrame.ScrollContainer:GetNormalizedCursorPosition()
	if cursorX < 0 or cursorX > 1 or cursorY < 0 or cursorY > 1 then return end
	return cursorX, cursorY
end

local function CoordsFormat(owner, none)
	local text = none and ": --, --" or ": %.1f, %.1f"
	return owner .. K.MyClassColor .. text
end

function Module:UpdateCoords(elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	if self.elapsed > 0.1 then
		local cursorX, cursorY = Module:GetCursorCoords()
		if cursorX and cursorY then
			cursorCoords:SetFormattedText(CoordsFormat("Cursor"), 100 * cursorX, 100 * cursorY)
		else
			cursorCoords:SetText(CoordsFormat("Cursor", true))
		end

		if not currentMapID then
			playerCoords:SetText(CoordsFormat(PLAYER, true))
		else
			local x, y = Module:GetPlayerMapPos(currentMapID)
			if not x or (x == 0 and y == 0) then
				playerCoords:SetText(CoordsFormat(PLAYER, true))
			else
				playerCoords:SetFormattedText(CoordsFormat(PLAYER), 100 * x, 100 * y)
			end
		end

		self.elapsed = 0
	end
end

function Module:UpdateMapID()
	if self:GetMapID() == C_Map_GetBestMapForUnit("player") then
		currentMapID = self:GetMapID()
	else
		currentMapID = nil
	end
end

function Module:SetupCoords()
	if not C["WorldMap"].Coordinates then
		return
	end
	local coordsFrame = CreateFrame("FRAME", nil, WorldMapFrame.ScrollContainer)
	coordsFrame:SetSize(WorldMapFrame:GetWidth(), 17)
	coordsFrame:SetPoint("BOTTOMLEFT", 17)
	coordsFrame:SetPoint("BOTTOMRIGHT", 0)

	coordsFrame.Texture = coordsFrame:CreateTexture(nil, "BACKGROUND")
	coordsFrame.Texture:SetAllPoints()
	coordsFrame.Texture:SetTexture(C["Media"].Textures.White8x8Texture)
	coordsFrame.Texture:SetVertexColor(0.04, 0.04, 0.04, 0.5)

	playerCoords = K.CreateFontString(coordsFrame, 13, "", "", false, "BOTTOMRIGHT", -132, 1)
	cursorCoords = K.CreateFontString(coordsFrame, 13, "", "", false, "BOTTOMLEFT", 152, 1)

	hooksecurefunc(WorldMapFrame, "OnFrameSizeChanged", Module.UpdateMapID)
	hooksecurefunc(WorldMapFrame, "OnMapChanged", Module.UpdateMapID)

	local CoordsUpdater = CreateFrame("Frame", nil, WorldMapFrame)
	CoordsUpdater:SetScript("OnUpdate", Module.UpdateCoords)
end

function Module:UpdateMapScale()
	if self.isMaximized and self:GetScale() ~= C["WorldMap"].MaxMapScale then
		self:SetScale(C["WorldMap"].MaxMapScale)
	elseif not self.isMaximized and self:GetScale() ~= C["WorldMap"].MapScale then
		self:SetScale(C["WorldMap"].MapScale)
	end
end

function Module:UpdateMapAnchor()
	Module.UpdateMapScale(self)
	K.RestoreMoverFrame(self)
end

local function isMouseOverMap()
	return not WorldMapFrame:IsMouseOver()
end

function Module:MapFader()
	if C["WorldMap"].FadeWhenMoving then
		PlayerMovementFrameFader.AddDeferredFrame(WorldMapFrame, 0.5, 1, 0.5, isMouseOverMap)
	else
		PlayerMovementFrameFader.RemoveFrame(WorldMapFrame)
	end
end

function Module:MapPartyDots()
	local WorldMapUnitPin, WorldMapUnitPinSizes
	--local partyTexture = "WhiteCircle-RaidBlips"
	local partyTexture = "Interface\\OptionsFrame\\VoiceChat-Record"

	local function setPinTexture(self)
		self:SetPinTexture("raid", partyTexture)
		self:SetPinTexture("party", partyTexture)
	end

	-- Set group icon textures
	for pin in WorldMapFrame:EnumeratePinsByTemplate("GroupMembersPinTemplate") do
		WorldMapUnitPin = pin
		WorldMapUnitPinSizes = pin.dataProvider:GetUnitPinSizesTable()
		setPinTexture(WorldMapUnitPin)
		hooksecurefunc(WorldMapUnitPin, "UpdateAppearanceData", setPinTexture)
		break
	end

	-- Set party icon size and enable class colors
	WorldMapUnitPinSizes.player = 22
	WorldMapUnitPinSizes.party = 12
	WorldMapUnitPin:SetAppearanceField("party", "useClassColor", true)
	WorldMapUnitPin:SetAppearanceField("raid", "useClassColor", true)
	WorldMapUnitPin:SynchronizePinSizes()
end

local shownMapCache, exploredCache, fileDataIDs = {}, {}, {}

local function GetStringFromInfo(info)
	return format("W%dH%dX%dY%d", info.textureWidth, info.textureHeight, info.offsetX, info.offsetY)
end

local function GetShapesFromString(str)
	local w, h, x, y = strmatch(str, "W(%d*)H(%d*)X(%d*)Y(%d*)")
	return tonumber(w), tonumber(h), tonumber(x), tonumber(y)
end

local function RefreshFileIDsByString(str)
	wipe(fileDataIDs)

	for fileID in gmatch(str, "%d+") do
		tinsert(fileDataIDs, fileID)
	end
end

function Module:MapData_RefreshOverlays(fullUpdate)
	wipe(shownMapCache)
	wipe(exploredCache)

	local mapID = WorldMapFrame.mapID
	if not mapID then return end

	local mapArtID = C_Map_GetMapArtID(mapID)
	local mapData = mapArtID and C.WorldMapPlusData[mapArtID]
	if not mapData then return end

	local exploredMapTextures = C_MapExplorationInfo_GetExploredMapTextures(mapID)
	if exploredMapTextures then
		for _, exploredTextureInfo in pairs(exploredMapTextures) do
			exploredCache[GetStringFromInfo(exploredTextureInfo)] = true
		end
	end

	if not self.layerIndex then self.layerIndex = WorldMapFrame.ScrollContainer:GetCurrentLayerIndex() end
	local layers = C_Map_GetMapArtLayers(mapID)
	local layerInfo = layers and layers[self.layerIndex]
	if not layerInfo then return end

	local TILE_SIZE_WIDTH = layerInfo.tileWidth
	local TILE_SIZE_HEIGHT = layerInfo.tileHeight

	-- Blizzard_SharedMapDataProviders\MapExplorationDataProvider: MapExplorationPinMixin:RefreshOverlays
	for i, exploredInfoString in pairs(mapData) do
		if not exploredCache[i] then
			local width, height, offsetX, offsetY = GetShapesFromString(i)
			RefreshFileIDsByString(exploredInfoString)
			local numTexturesWide = ceil(width / TILE_SIZE_WIDTH)
			local numTexturesTall = ceil(height / TILE_SIZE_HEIGHT)
			local texturePixelWidth, textureFileWidth, texturePixelHeight, textureFileHeight

			for j = 1, numTexturesTall do
				if j < numTexturesTall then
					texturePixelHeight = TILE_SIZE_HEIGHT
					textureFileHeight = TILE_SIZE_HEIGHT
				else
					texturePixelHeight = mod(height, TILE_SIZE_HEIGHT)
					if texturePixelHeight == 0 then
						texturePixelHeight = TILE_SIZE_HEIGHT
					end
					textureFileHeight = 16
					while textureFileHeight < texturePixelHeight do
						textureFileHeight = textureFileHeight * 2
					end
				end
				for k = 1, numTexturesWide do
					local texture = self.overlayTexturePool:Acquire()
					if k < numTexturesWide then
						texturePixelWidth = TILE_SIZE_WIDTH
						textureFileWidth = TILE_SIZE_WIDTH
					else
						texturePixelWidth = width % TILE_SIZE_WIDTH
						if texturePixelWidth == 0 then
							texturePixelWidth = TILE_SIZE_WIDTH
						end
						textureFileWidth = 16
						while textureFileWidth < texturePixelWidth do
							textureFileWidth = textureFileWidth * 2
						end
					end
					texture:SetWidth(texturePixelWidth)
					texture:SetHeight(texturePixelHeight)
					texture:SetTexCoord(0, texturePixelWidth / textureFileWidth, 0, texturePixelHeight / textureFileHeight)
					texture:SetPoint("TOPLEFT", offsetX + (TILE_SIZE_WIDTH * (k - 1)), -(offsetY + (TILE_SIZE_HEIGHT * (j - 1))))
					texture:SetTexture(fileDataIDs[((j - 1) * numTexturesWide) + k], nil, nil, "TRILINEAR")

					if KkthnxUIDB.Variables[K.Realm][K.Name].RevealWorldMap then
						texture:SetVertexColor(0.7, 0.7, 0.7)
						if C["WorldMap"].MapRevealGlow then
							texture:SetVertexColor(0.7, 0.7, 0.7)
						else
							texture:SetVertexColor(1, 1, 1)
						end
						texture:SetDrawLayer("ARTWORK", -1)
						texture:Show()
						if fullUpdate then
							self.textureLoadGroup:AddTexture(texture)
						end
					else
						texture:Hide()
					end
					tinsert(shownMapCache, texture)
				end
			end
		end
	end
end

function Module:OnEnable()
	if not C["WorldMap"].SmallWorldMap then return end
	if C_AddOns.IsAddOnLoaded("Leatrix_Maps") or C_AddOns.IsAddOnLoaded("Mapster") then return end

	-- Fix worldmap cursor when scaling
	WorldMapFrame.ScrollContainer.GetCursorPosition = function(f)
		local x, y = MapCanvasScrollControllerMixin.GetCursorPosition(f)
		local scale = WorldMapFrame:GetScale()
		return x / scale, y / scale
	end

	-- Hide town and city icons
	hooksecurefunc(BaseMapPoiPinMixin, "OnAcquired", function(self)
	local wmapID = WorldMapFrame.mapID
		if wmapID and wmapID == 1414 or wmapID == 1415 or wmapID == 947 or wmapID == 1945 or wmapID == 113 then
			if self.Texture and self.Texture:GetTexture() == 136441 then
				self:Hide()
			end
		end
	end)

	-- Fix scroll zooming in classic
	WorldMapFrame.ScrollContainer:HookScript("OnMouseWheel", function(self, delta)
		local x, y = self:GetNormalizedCursorPosition()
		local nextZoomOutScale, nextZoomInScale = self:GetCurrentZoomRange()
		if delta == 1 then
			if nextZoomInScale > self:GetCanvasScale() then
				self:InstantPanAndZoom(nextZoomInScale, x, y)
			end
		else
			if nextZoomOutScale < self:GetCanvasScale() then
				self:InstantPanAndZoom(nextZoomOutScale, x, y)
			end
		end
	end)

	K.CreateMoverFrame(WorldMapFrame, nil, true)
	self.UpdateMapScale(WorldMapFrame)
	WorldMapFrame:HookScript("OnShow", self.UpdateMapAnchor)
	hooksecurefunc(WorldMapFrame, "SynchronizeDisplayState", self.UpdateMapAnchor)

	-- Default elements
	WorldMapFrame.BlackoutFrame:SetAlpha(0)
	WorldMapFrame.BlackoutFrame:EnableMouse(false)
	WorldMapFrame:SetFrameStrata("MEDIUM")
	WorldMapFrame.BorderFrame:SetFrameStrata("MEDIUM")
	WorldMapFrame.BorderFrame:SetFrameLevel(1)
	WorldMapFrame:SetAttribute("UIPanelLayout-area", "center")
	WorldMapFrame:SetAttribute("UIPanelLayout-enabled", false)
	WorldMapFrame:SetAttribute("UIPanelLayout-allowOtherPanels", true)
	WorldMapFrame.HandleUserActionToggleSelf = function()
		if WorldMapFrame:IsShown() then WorldMapFrame:Hide() else WorldMapFrame:Show() end end
	tinsert(UISpecialFrames, "WorldMapFrame")
	-- Fix issue when map open at default
	if WorldMapFrame:IsShown() then
		ToggleFrame(WorldMapFrame)
	end

	self:MapPartyDots()
	self:SetupCoords()
	self:MapFader()

	self:CreateWowHeadLinks()
	self:CreateWorldMapReveal()
end