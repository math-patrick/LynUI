local _, ns = ...

-- The stone strip with the gold metal trim along the bottom of the screen.
-- Pure decoration: it sits in the BACKGROUND strata and takes no mouse input,
-- so EllesmereUI's action bars can be placed on top of it.
local STONE = [[Interface\PLAYERACTIONBARALT\STONE]]
local bar, trim

local function Update()
	bar:SetHeight(ns.db.infoBarHeight)
	trim:SetVertexColor(ns:GetColor(ns.db.infoBarTrim))
	if ns.db.infoBar then
		RegisterStateDriver(bar, 'visibility', '[petbattle] hide; show')
	else
		UnregisterStateDriver(bar, 'visibility')
		bar:Hide()
	end
end

ns:RegisterModule(nil, function()
	bar = CreateFrame('Frame', 'LynInfoBar', UIParent)
	bar:SetFrameStrata('BACKGROUND')
	bar:SetPoint('BOTTOMLEFT')
	bar:SetPoint('BOTTOMRIGHT')
	bar:EnableMouse(false)

	local stone = bar:CreateTexture(nil, 'BACKGROUND')
	stone:SetTexture(STONE, 'REPEAT', 'REPEAT')
	stone:SetHorizTile(true)
	stone:SetTexCoord(0, 1, .15, .35)
	stone:SetVertexColor(.5, .5, .5)
	stone:SetAllPoints()

	trim = bar:CreateTexture(nil, 'OVERLAY')
	trim:SetTexture(STONE, 'REPEAT', 'REPEAT')
	trim:SetHorizTile(true)
	trim:SetVertTile(true)
	trim:SetTexCoord(0, 1, 0, .4)
	trim:SetHeight(45)
	trim:SetPoint('TOPLEFT', 0, 15)
	trim:SetPoint('TOPRIGHT', 0, 15)

	Update()
	ns:OnChange('infoBar', Update)
	ns:OnChange('infoBarHeight', Update)
	ns:OnChange('infoBarTrim', Update)
end)
