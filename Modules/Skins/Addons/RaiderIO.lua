local K, C = KkthnxUI[1], KkthnxUI[2]
local Module = K:GetModule("Skins")
local ModuleTooltip = K:GetModule("Tooltip")

local IsAddOnLoaded = _G.IsAddOnLoaded

function Module:ReskinRaiderIO()
	if not IsAddOnLoaded("RaiderIO") then
		return
	end

	if RaiderIO_CustomDropDownListMenuBackdrop then
		ModuleTooltip.ReskinTooltip(RaiderIO_CustomDropDownListMenuBackdrop)
	end

	if RaiderIO_ProfileTooltip then
		RaiderIO_ProfileTooltip:SetScript("OnShow", function()
			ModuleTooltip.ReskinTooltip(RaiderIO_ProfileTooltip)
		end)
	end
end
