local _, ns = ...

-- The LynUI options, built on Blizzard's own Settings panel
-- (Esc > Options > AddOns > LynUI, or /lyn). Almost everything applies the
-- moment it is changed; options that need a reload say so in their tooltip.

local root

---------------------------------------------------------------------------
-- Control helpers. Every control is a proxy onto ns.db through ns:Set, so
-- modules hear about the change and update live.
---------------------------------------------------------------------------

local function Proxy(category, key, varType, label)
	return Settings.RegisterProxySetting(category, 'LYNUI_' .. key, varType, label, ns.DEFAULTS[key],
		function() return ns.db[key] end,
		function(value) ns:Set(key, value) end)
end

local function Checkbox(category, key, label, tooltip)
	return Settings.CreateCheckbox(category, Proxy(category, key, Settings.VarType.Boolean, label), tooltip)
end

local function Slider(category, key, label, min, max, step, format, tooltip)
	local options = Settings.CreateSliderOptions(min, max, step)
	options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
		return format:format(value)
	end)
	return Settings.CreateSlider(category, Proxy(category, key, Settings.VarType.Number, label), options, tooltip)
end

-- choices: function returning { { value, label }, ... }
local function Dropdown(category, key, label, choices, tooltip)
	local function GetOptions()
		local container = Settings.CreateControlTextContainer()
		for _, choice in ipairs(choices()) do
			container:Add(choice[1], choice[2])
		end
		return container:GetData()
	end
	return Settings.CreateDropdown(category, Proxy(category, key, Settings.VarType.String, label), GetOptions, tooltip)
end

local function Header(layout, text)
	layout:AddInitializer(Settings.CreateElementInitializer('SettingsListSectionHeaderTemplate', { name = text }))
end

local function Button(layout, label, buttonText, onClick, tooltip)
	layout:AddInitializer(CreateSettingsButtonInitializer(label, buttonText, onClick, tooltip, true))
end

-- Grey a control out while its parent checkbox is off.
local function DependsOn(initializer, parent, key)
	initializer:SetParentInitializer(parent, function() return ns.db[key] end)
end

---------------------------------------------------------------------------
-- Choices
---------------------------------------------------------------------------

local function SharedMedia(kind)
	return function()
		local list = {}
		local LSM = LibStub and LibStub('LibSharedMedia-3.0', true)
		for _, name in ipairs(LSM and LSM:List(kind) or {}) do
			list[#list + 1] = { name, name }
		end
		return list
	end
end

local function Colors()
	return {
		{ 'dark', 'Dark grey' },
		{ 'gold', 'Gold' },
		{ 'class', 'Class color' },
		{ 'black', 'Black' },
	}
end

---------------------------------------------------------------------------
-- Pages
---------------------------------------------------------------------------

local RELOAD = '\n\n|cffffd100Needs a reload.|r'
local INSTALL = '\n\n|cffffd100Used by "Install the Lyn profile".|r'

local function BuildGeneral(category, layout)
	Header(layout, 'Quick actions')
	Button(layout, 'Move unit frames', 'Unlock / lock', function() ns:ToggleMovers() end,
		'Show drag handles over Lyn\'s unit frames. Click again to lock them.')
	Button(layout, 'Reset unit frames', 'Reset positions', function() ns:ResetUnitPositions() end,
		'Put every unit frame back in Lyn\'s original layout.')
	Button(layout, 'Reload the interface', 'Reload', ReloadUI)

	Header(layout, 'EllesmereUI profile')
	Button(layout, 'Lyn profile', 'Install / re-apply', function() ns:InstallProfile() end,
		'Create the "Lyn" EllesmereUI profile from your current one (or re-apply it): Lyn fonts, bar layout, chat style, gold minimap, and EllesmereUI\'s player/target frames handed over to Lyn\'s.')
	Checkbox(category, 'actionBars', 'Include action bar layout',
		'Lay out EllesmereUI\'s bars the Lyn way when installing.' .. INSTALL)
	Checkbox(category, 'chatStyle', 'Include chat style',
		'Restyle EllesmereUI\'s chat the Lyn way when installing.' .. INSTALL)
	Button(layout, 'Raid frames', 'Keep original font', function() ns:RestoreRaidFont() end,
		'Keep EllesmereUI\'s raid frames on the font you used before Lyn. Reloads the interface.')
end

local function BuildUnitFrames(category, layout)
	Checkbox(category, 'unitFrames', 'Enable Lyn unit frames',
		'Player, target, target of target, focus, pet and boss frames.' .. RELOAD)
	Slider(category, 'unitScale', 'Scale', .5, 1.5, .05, '%.2f', 'Size of all Lyn unit frames.')
	Dropdown(category, 'ufTexture', 'Bar texture', SharedMedia('statusbar'),
		'Health, power and cast bar texture. Every SharedMedia texture is listed.')
	Dropdown(category, 'ufFont', 'Font', SharedMedia('font'),
		'Font for names and numbers. Every SharedMedia font is listed.')

	Header(layout, 'Parts')
	Checkbox(category, 'showClassPower', 'Class resource strip',
		'Combo points, holy power, chi, runes and the like on top of the player frame.')
	Checkbox(category, 'playerCastbar', 'Player cast bar',
		'The striped bar drawn over your health bar. When off, Blizzard\'s own cast bar comes back.')
	Checkbox(category, 'targetCastbar', 'Target cast bar', 'The big cast bar near the middle of the screen.')
	Checkbox(category, 'showPlayerProcs', 'Procs above the player frame',
		'Your important buffs and procs, right above the player frame.')
	Checkbox(category, 'showTargetDebuffs', 'Your debuffs above the target', nil)
	Checkbox(category, 'showTargetBuffs', 'Buffs below the target', nil)
end

local function BuildActionBars(category, layout)
	local borders = Checkbox(category, 'buttonBorders', 'Lyn button borders', 'Lyn\'s beveled border around every action button.')
	DependsOn(Dropdown(category, 'buttonBorderColor', 'Border color', Colors), borders, 'buttonBorders')

	Header(layout, 'EllesmereUI bars')
	Button(layout, 'Lyn layout', 'Apply', function() ns:ApplyPart('actionBars') end,
		'Main bar and bar 2 on the stone strip, bar 3 bottom right with bars 4 and 5 above it (faded until moused over), 32px buttons. Applies to your active EllesmereUI profile and reloads.')
end

local function BuildChat(category, layout)
	Checkbox(category, 'compactChat', 'Compact messages',
		'Shorter loot, currency, reputation, xp, quest, achievement, raid and AFK lines.')
	Checkbox(category, 'hideChatSpam', 'Hide AFK replies and channel joins', nil)

	Header(layout, 'EllesmereUI chat')
	Button(layout, 'Lyn chat style', 'Apply', function() ns:ApplyPart('chat') end,
		'Transparent, borderless chat with plain class-colored tabs and the input box underneath. Applies to your active EllesmereUI profile and reloads.')
end

local function BuildScreen(category, layout)
	Header(layout, 'Stone strip')
	local strip = Checkbox(category, 'infoBar', 'Show the stone strip', 'The stone bar with metal trim along the bottom of the screen.')
	DependsOn(Slider(category, 'infoBarHeight', 'Height', 20, 80, 1, '%d'), strip, 'infoBar')
	DependsOn(Dropdown(category, 'infoBarTrim', 'Trim color', Colors), strip, 'infoBar')

	Header(layout, 'Menu button')
	local menu = Checkbox(category, 'menuButton', 'Show the menu button',
		'Your race portrait. Left-click: micro menu. Right-click: game menu. Shift + drag: move.')
	DependsOn(Slider(category, 'menuSize', 'Size', 20, 48, 1, '%d'), menu, 'menuButton')
	Button(layout, 'Position', 'Reset', function() ns:ResetMenuButton(true) end)
end

---------------------------------------------------------------------------

function ns:OpenSettings()
	if root then
		Settings.OpenToCategory(root:GetID())
	end
end

ns:RegisterModule(nil, function()
	local layout
	root, layout = Settings.RegisterVerticalLayoutCategory('LynUI')
	BuildGeneral(root, layout)

	for _, page in ipairs({
		{ 'Unit frames', BuildUnitFrames },
		{ 'Action bars', BuildActionBars },
		{ 'Chat', BuildChat },
		{ 'Stone strip and menu', BuildScreen },
	}) do
		local category, subLayout = Settings.RegisterVerticalLayoutSubcategory(root, page[1])
		page[2](category, subLayout)
	end

	Settings.RegisterAddOnCategory(root)

	ns:OnChange('unitFrames', function()
		ns:Print('Unit frame change saved. Reload to apply (Settings > LynUI > Reload).')
	end)
end)
