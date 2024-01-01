local K, C = unpack(KkthnxUI)
local Module = K:NewModule("Skins")

local _G = _G
local table_wipe = _G.table.wipe

local IsAddOnLoaded = _G.IsAddOnLoaded

C.defaultThemes = {}
C.themes = {}
C.otherSkins = {}

function Module:RegisterSkin(addonName, func)
	C.otherSkins[addonName] = func
end

function Module:LoadSkins(list)
	if not next(list) then return end

	for addonName, func in pairs(list) do
		local isLoaded, isFinished = IsAddOnLoaded(addonName)
		if isLoaded and isFinished then func() list[addonName] = nil end
	end
end

function Module:LoadDefaultSkins()
	if IsAddOnLoaded("AuroraClassic") or IsAddOnLoaded("Aurora") then return end

	-- Reskin Blizzard UIs
	for _, func in pairs(C.defaultThemes) do
		func()
	end
	table_wipe(C.defaultThemes)

	if not C["Skins"].BlizzardFrames then table_wipe(C.themes) end

	Module:LoadSkins(C.themes) -- blizzard ui
	Module:LoadSkins(C.otherSkins) -- other addons

	K:RegisterEvent("ADDON_LOADED", function(_, addonName)
		local func = C.themes[addonName]
		if func then func() C.themes[addonName] = nil end

		local func = C.otherSkins[addonName]
		if func then func() C.otherSkins[addonName] = nil end
	end)
end

function Module:OnEnable()
	-- Add Skins
	local loadSkinModules = {
		"LoadDefaultSkins",

		"ReskinAtlasLoot",
		"ReskinBartender4",
		"ReskinSkada",
		"ReskinBugSack",
		"ReskinButtonForge",
		"ReskinChocolateBar",
		"ReskinDeadlyBossMods",
		"ReskinDominos",
		"ReskinRareScanner",
	}

	for _, funcName in ipairs(loadSkinModules) do
		local func = self[funcName]
		if type(func) == "function" then
			local success, err = pcall(func, self)
			if not success then
				error("Error in function " .. funcName .. ": " .. tostring(err), 2)
			end
		end
	end
end