local K, C = unpack(KkthnxUI)
local Module = K:GetModule("Automation")

local function skipOnKeyDown(self, key)
	if not C["Automation"].AutoSkipCinematic then return end

	if key == "ESCAPE" then
		local closeDialog = self.closeDialog
		if self:IsShown() and closeDialog and closeDialog.confirmButton then
			closeDialog:Hide()
		end
	end
end

local function skipOnKeyUp(self, key)
	if not C["Automation"].AutoSkipCinematic then return end

	if key == "SPACE" or key == "ESCAPE" or key == "ENTER" then
		local closeDialog = self.closeDialog
		if self:IsShown() and closeDialog and closeDialog.confirmButton then
			closeDialog.confirmButton:Click()
		end
	end
end

function Module:CreateSkipCinematic()
	MovieFrame.closeDialog = MovieFrame.CloseDialog
	MovieFrame.closeDialog.confirmButton = MovieFrame.CloseDialog.ConfirmButton

	CinematicFrame.closeDialog.confirmButton = CinematicFrameCloseDialogConfirmButton

	MovieFrame:HookScript("OnKeyDown", skipOnKeyDown)
	MovieFrame:HookScript("OnKeyUp", skipOnKeyUp)

	CinematicFrame:HookScript("OnKeyDown", skipOnKeyDown)
	CinematicFrame:HookScript("OnKeyUp", skipOnKeyUp)
end
