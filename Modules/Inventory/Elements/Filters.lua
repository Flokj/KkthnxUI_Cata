local K, C = KkthnxUI[1], KkthnxUI[2]
local Module = K:GetModule("Bags")
local cargBags = K.cargBags

local C_ToyBox_GetToyInfo = C_ToyBox and C_ToyBox.GetToyInfo
local LE_ITEM_QUALITY_POOR, LE_ITEM_QUALITY_LEGENDARY = LE_ITEM_QUALITY_POOR, LE_ITEM_QUALITY_LEGENDARY
local LE_ITEM_CLASS_CONSUMABLE, LE_ITEM_CLASS_ITEM_ENHANCEMENT = LE_ITEM_CLASS_CONSUMABLE, LE_ITEM_CLASS_ITEM_ENHANCEMENT
local LE_ITEM_CLASS_WEAPON, LE_ITEM_CLASS_ARMOR, LE_ITEM_CLASS_TRADEGOODS = LE_ITEM_CLASS_WEAPON, LE_ITEM_CLASS_ARMOR, LE_ITEM_CLASS_TRADEGOODS
local AmmoEquipLoc = _G.INVTYPE_AMMO

-- Custom filter lists
local CustomFilterList = {
	[12450] = true, -- Juju Flurry
	[12451] = true, -- Juju Power
	[12455] = true, -- Juju Ember
	[12457] = true, -- Juju Chill
	[12458] = true, -- Juju Guile
	[12459] = true, -- Juju Escape
	[12460] = true, -- Juju Might
	[10646] = true, -- 地精工兵炸药
	[23737] = true, -- 精金手雷
	[23827] = true, -- 超级神风炸药

	[4366] = true, -- 活动假人
	[12662] = true, -- 恶魔符文
	[20520] = true, -- 黑暗符文
	[16023] = true, -- 高级活动假人
	[22797] = true, -- 梦魇草
	[39970] = false, -- 火叶
}

local function isCustomFilter(item)
	if not C["Inventory"].ItemFilter then return end
	return CustomFilterList[item.id]
end

local function isItemInBag(item)
	return item.bagId >= 0 and item.bagId <= 4
end

local function isItemInBank(item)
	return item.bagId == -1 or item.bagId >= 5 and item.bagId <= 11
end

local function isItemJunk(item)
	if not C["Inventory"].ItemFilter then return end
	if not C["Inventory"].FilterJunk then return end

	return (item.quality == LE_ITEM_QUALITY_POOR or KkthnxUIDB.Variables[K.Realm][K.Name].CustomJunkList[item.id]) and item.hasPrice
end

local function isItemEquipSet(item)
	if not C["Inventory"].ItemFilter then return end
	if not C["Inventory"].FilterEquipSet then return end

	return item.isItemSet
end

local function isItemAmmo(item)
	if not C["Inventory"].ItemFilter then return end
	if not C["Inventory"].FilterAmmo then return end

	if C["Inventory"].GatherEmpty and not item.texture then return false end

	if K.Class == "HUNTER" then
		return item.equipLoc == AmmoEquipLoc or Module.BagsType[item.bagId] == -1
	elseif K.Class == "WARLOCK" then
		return item.id == 6265 or Module.BagsType[item.bagId] == 1
	end
end

K.iLvlClassIDs = {
	[LE_ITEM_CLASS_ARMOR] = true,
	[LE_ITEM_CLASS_WEAPON] = true,
}
function Module:IsItemHasLevel(item)
	return K.iLvlClassIDs[item.classID]
end

local function isItemEquipment(item)
	if not C["Inventory"].ItemFilter then return end
	if not C["Inventory"].FilterEquipment then return end

	return item.link and item.quality > LE_ITEM_QUALITY_COMMON and Module:IsItemHasLevel(item)
end

local consumableIDs = {
	[LE_ITEM_CLASS_CONSUMABLE] = true,
	[LE_ITEM_CLASS_ITEM_ENHANCEMENT] = true,
}

local function isItemConsumable(item)
	if not C["Inventory"].ItemFilter then return end
	if not C["Inventory"].FilterConsumable then return end

	if isCustomFilter(item) == false then
		return
	end

	return isCustomFilter(item) or consumableIDs[item.classID]
end

local function isItemLegendary(item)
	if not C["Inventory"].ItemFilter then return end
	if not C["Inventory"].FilterLegendary then return end

	return item.quality == LE_ITEM_QUALITY_LEGENDARY
end

local collectionBlackList = {}
local collectionIDs = {
	[Enum.ItemMiscellaneousSubclass.Mount] = Enum.ItemClass.Miscellaneous,
	[Enum.ItemMiscellaneousSubclass.CompanionPet] = Enum.ItemClass.Miscellaneous,
}

local function isMountOrPet(item)
	return not collectionBlackList[item.id] and item.subClassID and collectionIDs[item.subClassID] == item.classID
end

function isItemCollection(item)
	if not C["Inventory"].ItemFilter then return end
	if not C["Inventory"].FilterCollection then return end
	return item.id and C_ToyBox_GetToyInfo(item.id) or isMountOrPet(item)
end

local function isItemCustom(item, index)
	if not C["Inventory"].ItemFilter then return end
	if not C["Inventory"].FilterFavourite then return end

	local customIndex = item.id and KkthnxUIDB.Variables[K.Realm][K.Name].CustomItems[item.id]
	return customIndex and customIndex == index
end

local function isEmptySlot(item)
	if not C["Inventory"].GatherEmpty then return end

	return Module.initComplete and not item.texture and (C["Inventory"].ItemFilter or Module.BagsType[item.bagId] == 0)
end

local function isTradeGoods(item)
	if not C["Inventory"].ItemFilter then return end
	if not C["Inventory"].FilterGoods then return end

	return item.classID == LE_ITEM_CLASS_TRADEGOODS
end

local function isQuestItem(item)
	if not C["Inventory"].ItemFilter then return end
	if not C["Inventory"].FilterQuest then return end

	return item.isQuestItem
end

local function isItemBOE(item)
	if not C["Inventory"].ItemFilter then return end
	if not C["Inventory"].FilterBOE then return end
	return item.bindOn and item.bindOn == "equip" and Module:IsItemHasLevel(item)
end

function Module:GetFilters()
	local filters = {}

	filters.onlyBags = function(item) return isItemInBag(item) and not isEmptySlot(item) end
	filters.bagAmmo = function(item) return isItemInBag(item) and isItemAmmo(item) end
	filters.bagEquipment = function(item) return isItemInBag(item) and isItemEquipment(item) end
	filters.bagEquipSet = function(item) return isItemInBag(item) and isItemEquipSet(item) end
	filters.bagConsumable = function(item) return isItemInBag(item) and isItemConsumable(item) end
	filters.bagsJunk = function(item) return isItemInBag(item) and isItemJunk(item) end
	filters.onlyBank = function(item) return isItemInBank(item) and not isEmptySlot(item) end
	filters.bankAmmo = function(item) return isItemInBank(item) and isItemAmmo(item) end
	filters.bankLegendary = function(item) return isItemInBank(item) and isItemLegendary(item) end
	filters.bankEquipment = function(item) return isItemInBank(item) and isItemEquipment(item) end
	filters.bankEquipSet = function(item) return isItemInBank(item) and isItemEquipSet(item) end
	filters.bankConsumable = function(item) return isItemInBank(item) and isItemConsumable(item) end
	filters.onlyReagent = function(item) return item.bagId == -3 end
	filters.bagCollection = function(item) return isItemInBag(item) and isItemCollection(item) end
	filters.bankCollection = function(item) return isItemInBank(item) and isItemCollection(item) end
	filters.bagGoods = function(item) return isItemInBag(item) and isTradeGoods(item) end
	filters.bankGoods = function(item) return isItemInBank(item) and isTradeGoods(item) end
	filters.bagQuest = function(item) return isItemInBag(item) and isQuestItem(item) end
	filters.bankQuest = function(item) return isItemInBank(item) and isQuestItem(item) end
	filters.bagBOE = function(item) return isItemInBag(item) and isItemBOE(item) end
	filters.bankBOE = function(item) return isItemInBank(item) and isItemBOE(item) end

	for i = 1, 5 do
		filters["bagCustom" .. i] = function(item) return isItemInBag(item) and isItemCustom(item, i) end
		filters["bankCustom" .. i] = function(item) return isItemInBank(item) and isItemCustom(item, i) end
	end

	return filters
end
