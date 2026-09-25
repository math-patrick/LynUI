local _, ns = ...

-- Lyn's game menu button: a race portrait that opens a compact micro menu.
--   left click           micro menu
--   right click          game menu
--   shift + right click  reload UI
--   shift + drag         move the button

-- Routing through Blizzard's own micro buttons keeps their combat and
-- availability rules (disabled store, locked collections, ...) intact.
local ENTRIES = {
	{ 'CharacterMicroButton', 'CHARACTER_BUTTON' },
	{ 'ProfessionMicroButton', 'PROFESSIONS_BUTTON' },
	{ 'PlayerSpellsMicroButton', 'PLAYERSPELLS_BUTTON', 'TALENTS_BUTTON' },
	{ 'AchievementMicroButton', 'ACHIEVEMENT_BUTTON' },
	{ 'QuestLogMicroButton', 'QUESTLOG_BUTTON' },
	{ 'HousingMicroButton', 'HOUSING_MICRO_BUTTON' },
	{ 'GuildMicroButton', 'GUILD_AND_COMMUNITIES', 'GUILD' },
	{ 'LFDMicroButton', 'GROUP_FINDER', 'DUNGEONS_BUTTON' },
	{ 'CollectionsMicroButton', 'COLLECTIONS' },
	{ 'EJMicroButton', 'ADVENTURE_JOURNAL' },
	{ 'StoreMicroButton', 'BLIZZARD_STORE' },
}

local function EntryLabel(entry)
	for i = 2, #entry do
		local text = _G[entry[i]]
		if type(text) == 'string' and text ~= '' then return text end
	end
	return (entry[1]:gsub('MicroButton$', ''))
end

local function OpenMenu(owner)
	MenuUtil.CreateContextMenu(owner, function(_, root)
		root:CreateTitle(UnitName('player'))
		for _, entry in ipairs(ENTRIES) do
			local microButton = _G[entry[1]]
			if microButton then
				local item = root:CreateButton(EntryLabel(entry), function()
					microButton:Click()
				end)
				item:SetEnabled(microButton:IsEnabled())
			end
		end
		root:CreateButton(SOCIAL_BUTTON or FRIENDS, function() ToggleFriendsFrame() end)
		root:CreateDivider()
		root:CreateButton('LynUI settings', function() ns:OpenSettings() end)
		root:CreateButton(ADDON_LIST or ADDONS, function() ShowUIPanel(AddonList) end)
		root:CreateButton(RELOADUI or 'Reload UI', ReloadUI)
	end)
end

local RACE_ATLAS_NAMES = { scourge = 'undead' }

local function SetPortrait(icon)
	local _, race = UnitRace('player')
	race = race and race:lower()
	local sex = UnitSex('player') == 3 and 'female' or 'male'
	local atlas = race and ('raceicon128-%s-%s'):format(RACE_ATLAS_NAMES[race] or race, sex)
	if atlas and C_Texture.GetAtlasInfo(atlas) then
		icon:SetAtlas(atlas)
		return
	end
	-- Newer races may not have a portrait atlas; fall back to the class icon.
	local _, class = UnitClass('player')
	icon:SetAtlas('classicon-' .. class:lower())
end

local button

-- toDefault: forget the dragged position and go back to the bottom right.
function ns:ResetMenuButton(toDefault)
	if toDefault then ns.db.menuPoint = CopyTable(ns.DEFAULTS.menuPoint) end
	if not button then return end
	button:ClearAllPoints()
	local p = ns.db.menuPoint
	button:SetPoint(p[1], _G[p[2]] or UIParent, p[3], p[4], p[5])
end

local function UpdateButton()
	button:SetSize(ns.db.menuSize, ns.db.menuSize)
	if ns.db.menuButton then
		RegisterStateDriver(button, 'visibility', '[petbattle] hide; show')
	else
		UnregisterStateDriver(button, 'visibility')
		button:Hide()
	end
end

ns:RegisterModule(nil, function()
	button = CreateFrame('Button', 'LynMenuButton', UIParent, 'BackdropTemplate')
	button:SetFrameStrata('MEDIUM')
	button:SetClampedToScreen(true)
	button:SetMovable(true)
	button:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
	button:RegisterForDrag('LeftButton')
	ns:ResetMenuButton()

	button:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8x8]], edgeFile = [[Interface\Buttons\WHITE8x8]], edgeSize = 1 })
	button:SetBackdropColor(0, 0, 0, 1)
	button:SetBackdropBorderColor(unpack(ns.COLOR_DARK))

	local icon = button:CreateTexture(nil, 'ARTWORK')
	icon:SetPoint('TOPLEFT', 1, -1)
	icon:SetPoint('BOTTOMRIGHT', -1, 1)
	SetPortrait(icon)

	local highlight = button:CreateTexture(nil, 'HIGHLIGHT')
	highlight:SetAllPoints(icon)
	highlight:SetColorTexture(1, 1, 1, .15)

	button:SetScript('OnClick', function(self, mouseButton)
		if mouseButton == 'LeftButton' then
			OpenMenu(self)
		elseif IsShiftKeyDown() then
			ReloadUI()
		elseif MainMenuMicroButton then
			MainMenuMicroButton:Click()
		end
	end)

	button:SetScript('OnDragStart', function(self)
		if IsShiftKeyDown() then self:StartMoving() end
	end)
	button:SetScript('OnDragStop', function(self)
		self:StopMovingOrSizing()
		self:SetUserPlaced(false)
		local point, _, relativePoint, x, y = self:GetPoint()
		ns.db.menuPoint = { point, 'UIParent', relativePoint, x, y }
	end)

	button:SetScript('OnEnter', function(self)
		GameTooltip:SetOwner(self, 'ANCHOR_TOPLEFT')
		GameTooltip:AddLine('Lyn Menu')
		GameTooltip:AddLine('Left-click: menu', 1, 1, 1)
		GameTooltip:AddLine('Right-click: game menu', 1, 1, 1)
		GameTooltip:AddLine('Shift + right-click: reload UI', 1, 1, 1)
		GameTooltip:AddLine('Shift + drag: move', 1, 1, 1)
		GameTooltip:Show()
	end)
	button:SetScript('OnLeave', GameTooltip_Hide)

	UpdateButton()
	ns:OnChange('menuButton', UpdateButton)
	ns:OnChange('menuSize', UpdateButton)
end)
