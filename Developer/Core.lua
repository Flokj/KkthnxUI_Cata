local K, C, L = KkthnxUI[1], KkthnxUI[2], KkthnxUI[3]
--local Module = K:NewModule("Developer")

K.Devs = {
	["Неотжал-Пламегор"] = true,
}

local function isDeveloper()
	return K.Devs[K.Name .. "-" .. K.Realm]
end
K.isDeveloper = isDeveloper

if not K.isDeveloper() then
	return
end
