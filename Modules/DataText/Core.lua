local K = unpack(KkthnxUI)
local Module = K:NewModule("Infobar")

function Module:OnEnable()
	self.CheckLoginTime = GetTime()

	local loadDataTextModules = {
		"CreateDurabilityDataText",
		"CreateGoldDataText",
		"CreateGuildDataText",
		"CreateSystemDataText",
		"CreateLatencyDataText",
		"CreateLocationDataText",
		"CreateSocialDataText",
		"CreateTimeDataText",
		"CreateCoordsDataText",
	}

	for _, funcName in ipairs(loadDataTextModules) do
		local func = self[funcName]
		if type(func) == "function" then
			local success, err = pcall(func, self)
			if not success then
				error("Error in function " .. funcName .. ": " .. tostring(err), 2)
			end
		end
	end
end
