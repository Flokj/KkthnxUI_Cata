local K, C, L = KkthnxUI[1], KkthnxUI[2], KkthnxUI[3]
local Module = K:GetModule("Tooltip")

local strmatch, format, tonumber, select, strfind = string.match, string.format, tonumber, select, string.find
local UnitAura, GetItemCount, GetItemInfo, GetUnitName = UnitAura, C_Item.GetItemCount, C_Item.GetItemInfo, GetUnitName
local GetCurrencyListInfo = GetCurrencyListInfo
local BAGSLOT, BANK = BAGSLOT, BANK
local SELL_PRICE_TEXT = format("|cffffffff%s%s%%s|r", SELL_PRICE, HEADER_COLON)
local ITEM_LEVEL_STR = gsub(ITEM_LEVEL_PLUS, "%+", "")
ITEM_LEVEL_STR = format("|cffffd100%s|r|n%%s", ITEM_LEVEL_STR)

local types = {
	spell = SPELLS .. "ID:",
	item = ITEMS .. "ID:",
	quest = QUESTS_LABEL .. "ID:",
	talent = TALENT .. "ID:",
	achievement = ACHIEVEMENTS .. "ID:",
	currency = CURRENCY .. "ID:",
	azerite = L["Trait"] .. "ID:",
}

local function createIcon(index)
	return format("|TInterface\\MoneyFrame\\UI-%sIcon:14:14:0:0|t", index)
end

local function setupMoneyString(money)
	local g, s, c = floor(money / 1e4), floor(money / 100) % 100, money % 100
	local str = ""
	if g > 0 then
		str = str .. " " .. g .. createIcon("Gold")
	end

	if s > 0 then
		str = str .. " " .. s .. createIcon("Silver")
	end

	if c > 0 then
		str = str .. " " .. c .. createIcon("Copper")
	end

	return str
end

function Module:UpdateItemSellPrice()
	local frame = Module:GetMouseFocus()
	if not frame then return end

	if frame:IsForbidden() then
		return
	end -- Forbidden on blizz store

	local name = frame:GetName()
	if frame.showSellPrice or frame.objectType or name and (strfind(name, "TradeSkill") or strfind(name, "Character")) then
		local link = select(2, self:GetItem())
		if link then
			local price = select(11, GetItemInfo(link))
			if price and price > 0 then
				local cost = (tonumber(frame.count) or 1) * price
				self:AddLine(format(SELL_PRICE_TEXT, setupMoneyString(cost)))
			end
		end

		frame.showSellPrice = true
	end
end

function Module:AddLineForID(id, linkType, noadd)
	for i = 1, self:NumLines() do
		local line = _G[self:GetName() .. "TextLeft" .. i]
		if not line then
			break
		end
		local text = line:GetText()
		if text and text == linkType then
			return
		end
	end

	if linkType == types.item then
		Module.UpdateItemSellPrice(self)
	end

	if not noadd then
		self:AddLine(" ")
	end

	if linkType == types.item then
		local bagCount = GetItemCount(id)
		local bankCount = GetItemCount(id, true) - bagCount
		local name, _, _, itemLevel, _, _, _, itemStackCount, _, _, _, classID = GetItemInfo(id)
		if bankCount > 0 then
			self:AddDoubleLine(BAGSLOT .. "/" .. BANK .. ":", K.InfoColor .. bagCount .. "/" .. bankCount)
		elseif bagCount > 0 then
			self:AddDoubleLine(BAGSLOT .. ":", K.InfoColor .. bagCount)
		end

		if itemStackCount and itemStackCount > 1 then
			self:AddDoubleLine(L["Stack Cap"] .. ":", K.InfoColor .. itemStackCount)
		end

		-- iLvl info like retail
		if name and itemLevel and itemLevel > 1 and K.iLvlClassIDs[classID] then
			local tipName = self:GetName()
			local index = strfind(tipName, "Shopping") and 3 or 2
			local line = _G[tipName .. "TextLeft" .. index]
			local lineText = line and line:GetText()
			if lineText then
				line:SetFormattedText(ITEM_LEVEL_STR, itemLevel, lineText)
				line:SetJustifyH("LEFT")
				line:SetWidth(ceil(line:GetStringWidth())) -- make sure it won't affect by RatingBuster
			end
		end
	end

	self:AddDoubleLine(linkType, format(K.InfoColor .. "%s|r", id))
	self:Show()
end

function Module:SetHyperLinkID(link)
	local linkType, id = strmatch(link, "^(%a+):(%d+)")
	if not linkType or not id then return end

	if linkType == "spell" or linkType == "enchant" or linkType == "trade" then
		Module.AddLineForID(self, id, types.spell)
	elseif linkType == "talent" then
		Module.AddLineForID(self, id, types.talent, true)
	elseif linkType == "quest" then
		Module.AddLineForID(self, id, types.quest)
	elseif linkType == "achievement" then
		Module.AddLineForID(self, id, types.achievement)
	elseif linkType == "item" then
		Module.AddLineForID(self, id, types.item)
	elseif linkType == "currency" then
		Module.AddLineForID(self, id, types.currency)
	end
end

function Module:SetItemID()
	local link = select(2, self:GetItem())
	if link then
		local id = strmatch(link, "item:(%d+):")
		local keystone = strmatch(link, "|Hkeystone:([0-9]+):")
		if keystone then
			id = tonumber(keystone)
		end

		if id then
			Module.AddLineForID(self, id, types.item)
		end
	end
end

function Module:UpdateSpellCaster(...)
	local unitCaster = select(7, UnitAura(...))
	if unitCaster then
		local name = GetUnitName(unitCaster, true)
		local hexColor = K.RGBToHex(K.UnitColor(unitCaster))
		self:AddDoubleLine(L["From"] .. ":", hexColor .. name)
		self:Show()
	end
end

function Module:CreateTooltipID()
	if not C["Tooltip"].ShowIDs then return end

	-- Update all
	hooksecurefunc(GameTooltip, "SetHyperlink", Module.SetHyperLinkID)
	hooksecurefunc(ItemRefTooltip, "SetHyperlink", Module.SetHyperLinkID)

	-- Spells
	hooksecurefunc(GameTooltip, "SetUnitAura", function(self, ...)
		local id = select(10, UnitAura(...))
		if id then
			Module.AddLineForID(self, id, types.spell)
		end
	end)

	GameTooltip:HookScript("OnTooltipSetSpell", function(self)
		local id = select(2, self:GetSpell())
		if id then
			Module.AddLineForID(self, id, types.spell)
		end
	end)

	hooksecurefunc("SetItemRef", function(link)
		local id = tonumber(strmatch(link, "spell:(%d+)"))
		if id then
			Module.AddLineForID(ItemRefTooltip, id, types.spell)
		end
	end)

	-- Items
	GameTooltip:HookScript("OnTooltipSetItem", Module.SetItemID)
	ItemRefTooltip:HookScript("OnTooltipSetItem", Module.SetItemID)
	ShoppingTooltip1:HookScript("OnTooltipSetItem", Module.SetItemID)
	ShoppingTooltip2:HookScript("OnTooltipSetItem", Module.SetItemID)
	ItemRefShoppingTooltip1:HookScript("OnTooltipSetItem", Module.SetItemID)
	ItemRefShoppingTooltip2:HookScript("OnTooltipSetItem", Module.SetItemID)

	-- Currencies
	hooksecurefunc(GameTooltip, "SetCurrencyToken", function(self, index)
		local id = select(12, GetCurrencyListInfo(index))
		if id then
			Module.AddLineForID(self, id, types.currency)
		end
	end)

	hooksecurefunc(GameTooltip, "SetCurrencyTokenByID", function(self, id)
		if id then
			Module.AddLineForID(self, id, types.currency)
		end
	end)

	-- Spell caster
	hooksecurefunc(GameTooltip, "SetUnitAura", Module.UpdateSpellCaster)
end
