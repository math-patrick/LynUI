local _, ns = ...

-- Lyn's beveled border around EllesmereUI's action buttons. EllesmereUI keeps
-- doing all the real work (paging, keybinds, cooldowns, layout); /lyn install
-- sets its button sizes and layout and turns its own border off so this one
-- takes over. The border is plain textures on the button, drawn under the
-- hotkey/count text and cooldown swipe.
local BUTTON_GROUPS = {
	{ 'ActionButton', 12 },
	{ 'MultiBarBottomLeftButton', 12 },
	{ 'MultiBarBottomRightButton', 12 },
	{ 'MultiBarRightButton', 12 },
	{ 'MultiBarLeftButton', 12 },
	{ 'MultiBar5Button', 12 },
	{ 'MultiBar6Button', 12 },
	{ 'MultiBar7Button', 12 },
	{ 'EABButton', 120 }, -- EllesmereUI's own bars 9 and 10
	{ 'StanceButton', 10 },
	{ 'PetActionButton', 10 },
}

-- Tracked here rather than on the (secure) buttons themselves.
local skinned = setmetatable({}, { __mode = 'k' })

local function StyleBorder(textures)
	local r, g, b = ns:GetColor(ns.db.buttonBorderColor)
	for _, tex in next, textures do
		tex:SetVertexColor(r, g, b)
		tex:SetShown(ns.db.buttonBorders)
	end
end

local function SkinAll()
	for _, group in ipairs(BUTTON_GROUPS) do
		for index = 1, group[2] do
			local button = _G[group[1] .. index]
			if button and not skinned[button] then
				skinned[button] = ns.UF.CreateBorderTextures(button, 0, 'ARTWORK', 7)
				StyleBorder(skinned[button])
			end
		end
	end
end

local function RestyleAll()
	for _, textures in next, skinned do
		StyleBorder(textures)
	end
end

ns:RegisterModule(nil, function()
	if not C_AddOns.IsAddOnLoaded('EllesmereUIActionBars') then return end
	SkinAll()
	-- EllesmereUI creates some buttons (bars 9/10, stance, pet) lazily.
	C_Timer.After(2, SkinAll)
	local watcher = CreateFrame('Frame')
	watcher:RegisterEvent('UPDATE_SHAPESHIFT_FORMS')
	watcher:RegisterEvent('PET_BAR_UPDATE')
	watcher:SetScript('OnEvent', SkinAll)

	ns:OnChange('buttonBorders', RestyleAll)
	ns:OnChange('buttonBorderColor', RestyleAll)
end)
