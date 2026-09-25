local _, ns = ...

-- /lyn install builds an EllesmereUI profile named "Lyn" from the profile
-- you're currently using: same layout, bars, cooldown manager and spells,
-- with Lyn's fonts, bar texture and borders applied on top. It goes through
-- EllesmereUI's own export/import, so your other profiles are left alone and
-- you can switch back at any time from EllesmereUI's Profiles page.
local PROFILE_NAME = 'Lyn'
local FONT = 'Lyn Roboto Slab'
local BAR_TEXTURE = 'sm:Lyn Fer35'

local function RGB(color)
	return { r = color[1], g = color[2], b = color[3] }
end

local UNITS = { 'player', 'target', 'targettarget', 'focus', 'focustarget', 'pet', 'boss' }
-- Drawn by LynUI's own oUF frames; EllesmereUI's versions get switched off.
local LYN_UNITS = { 'player', 'target', 'targettarget', 'focus', 'pet', 'boss' }

local function StyleUnitFrames(uf)
	uf.useBlizzardStyle = false
	uf.healthBarTexture = BAR_TEXTURE
	for _, unit in ipairs(UNITS) do
		local settings = uf[unit]
		if type(settings) == 'table' then
			settings.healthBarTexture = BAR_TEXTURE
			settings.healthClassColored = true
			settings.borderTexture = 'solid'
			settings.borderColor = RGB(ns.COLOR_DARK)
		end
	end

	uf.enabledFrames = uf.enabledFrames or {}
	uf.frameSource = uf.frameSource or {}
	for _, unit in ipairs(LYN_UNITS) do
		uf.enabledFrames[unit] = not ns.db.unitFrames
		uf.frameSource[unit] = ns.db.unitFrames and 'hidden' or 'eui'
	end
end

---------------------------------------------------------------------------
-- Action bars: Lyn's layout on and around the stone strip.
--
--   [pet]      [stance][     bar 6     ]            [ bar 5 ] (faded)
--                                                   [ bar 4 ] (faded)
--   stone:     [    main bar    ][     bar 2     ]  [ bar 3 ] (faded)  [menu]
---------------------------------------------------------------------------

local BUTTON, PET_BUTTON, GAP = 32, 28, 5
local STONE_ROW = 9   -- bottom of the row sitting on the stone strip
local UPPER_ROW = 70  -- first row clear of the strip's gold trim
local MENU_ROOM = 50  -- space kept free for the menu button, bottom right

-- Lyn faded every bar except the main two and stance until moused over.
local FADED = { Bar3 = true, Bar4 = true, Bar5 = true, PetBar = true }

local function RowWidth(count, size)
	return count * size + (count - 1) * GAP
end

-- EllesmereUI stores bar positions as offsets of the bar's center from the
-- screen center, in UIParent units.
local function LynBarLayout()
	local W, H = UIParent:GetWidth(), UIParent:GetHeight()
	local function At(left, bottom, width, height)
		return {
			point = 'CENTER', relPoint = 'CENTER',
			x = left + width / 2 - W / 2,
			y = bottom + height / 2 - H / 2,
		}
	end

	local row = RowWidth(12, BUTTON)
	local stance = RowWidth(10, BUTTON)
	local right = W - MENU_ROOM - row
	return {
		MainBar = At(W / 2 - 6 - row, STONE_ROW, row, BUTTON),
		Bar2 = At(W / 2 + 6, STONE_ROW, row, BUTTON),
		Bar3 = At(right, STONE_ROW, row, BUTTON),
		Bar4 = At(right, UPPER_ROW, row, BUTTON),
		Bar5 = At(right, UPPER_ROW + BUTTON + GAP, row, BUTTON),
		Bar6 = At(W / 2 - row / 2, UPPER_ROW, row, BUTTON),
		StanceBar = At(W / 2 - row / 2 - 12 - stance, UPPER_ROW, stance, BUTTON),
		PetBar = At(10, STONE_ROW + 2, RowWidth(10, PET_BUTTON), PET_BUTTON),
	}
end

-- Bars placed above must not stay chained to other bars by unlock-mode
-- anchors or size matching, or those would override the new positions.
local function Unchain(layout, ...)
	for i = 1, select('#', ...) do
		local store = select(i, ...)
		if type(store) == 'table' then
			for key in pairs(layout) do store[key] = nil end
		end
	end
end

local function StyleActionBars(ab, force)
	if not force and ns.db.actionBars == false then return end
	ab.useBlizzardStyle = false
	ab.slotBgColor = { r = 0, g = 0, b = 0 }
	ab.slotBgOpacity = 60
	ab.barPositions = ab.barPositions or {}

	local layout = LynBarLayout()
	for key, position in pairs(layout) do
		local bar = type(ab.bars) == 'table' and ab.bars[key]
		if type(bar) == 'table' then
			local size = key == 'PetBar' and PET_BUTTON or BUTTON
			bar.buttonWidth = size
			bar.buttonHeight = size
			bar.buttonPadding = GAP
			bar.orientation = 'horizontal'
			bar.numRows = 1
			bar.overrideNumRows = nil
			bar.borderEnabled = false -- LynUI draws Lyn's border instead
			bar.bgEnabled = false
			bar.hideMacroText = true
			bar.keybindFontSize = 10
			bar.countFontSize = 14

			local hidden = bar.alwaysHidden or bar.barVisibility == 'never'
			if FADED[key] and not hidden then
				bar.barVisibility = 'mouseover'
				bar.mouseoverEnabled = true
				bar.mouseoverAlpha = .3
				bar._savedBarAlpha = 1
			end

			ab.barPositions[key] = position
		end
	end
	return layout
end

local function StyleMinimap(mm)
	local map = mm.minimap
	if type(map) ~= 'table' then return end
	map.useBlizzardStyle = false
	map.shape = 'square'
	map.borderTexture = 'solid'
	map.borderSize = 2
	map.borderUseClassColor = false
	map.borderColor = RGB(ns.COLOR_GOLD)
end

-- Lyn's chat: no background or borders, plain tabs (class colored when
-- selected, grey otherwise), input box underneath, no side buttons, and a
-- 400x250 window bottom left above the stone strip. EllesmereUI's chat engine
-- keeps rendering the lines; in Midnight it is the only safe place to rewrite
-- chat text, so Lyn's old AddMessage/CHAT_*_GET tricks are not used.
local function StyleChat(ec, force)
	if not force and ns.db.chatStyle == false then return end
	if type(ec.chat) ~= 'table' then ec.chat = {} end
	local chat = ec.chat

	chat.enabled = true
	chat.bgAlpha = 0
	chat.bgTexture = 'none'
	chat.extendBgBehindTabs = false
	chat.hideBorders = true
	chat.panelBorderTexture = 'solid'
	chat.panelBorderThickness = 'none'
	chat.innerBorderColor = { r = 1, g = 1, b = 1, a = 0 }

	chat.chatFontSize = 12
	chat.timestampAll = false
	chat.abbreviateChannels = true
	chat.classColorNames = true

	chat.tabFontSize = 11
	chat.tabFontColorActiveMode = 'class'
	chat.tabFontColorActive = { r = 1, g = 1, b = 1, a = 1 }
	chat.tabFontColorMode = 'custom'
	chat.tabFontColor = { r = .3, g = .3, b = .3, a = 1 }
	chat.tabBackgroundTexture = 'none'
	chat.tabBackgroundColor = { r = 0, g = 0, b = 0, a = 0 }
	chat.tabBackgroundColorActive = { r = 0, g = 0, b = 0, a = 0 }
	chat.activeUnderline = false
	chat.activeTabBorder = false
	chat.tabBorderThickness = 'none'

	chat.sidebarVisibility = 'never'
	chat.inputOnTop = false
	chat.idleFadeEnabled = false

	chat.chatPosition = { point = 'BOTTOMLEFT', relPoint = 'BOTTOMLEFT', x = 50, y = 95 }
	chat.chatSize = { w = 400, h = 250 }
end

local STYLERS = {
	EllesmereUIUnitFrames = StyleUnitFrames,
	EllesmereUIActionBars = StyleActionBars,
	EllesmereUIMinimap = StyleMinimap,
	EllesmereUIChat = StyleChat,
}

-- Raid frames are left exactly as they were: the Lyn global font would
-- otherwise reach them, so they get a per-module font pinned to the font the
-- player had before Lyn (EllesmereUI's own default is Expressway).
local RAID_FOLDER = 'EllesmereUIRaidFrames'

local function KeepRaidFont(fonts)
	local original = ns.db.originalFont or 'Expressway'
	fonts.moduleFonts = fonts.moduleFonts or {}
	for _, entry in ipairs(fonts.moduleFonts) do
		if entry.folder == RAID_FOLDER then
			if (entry.font or '__global') == '__global' then entry.font = original end
			return
		end
	end
	table.insert(fonts.moduleFonts, {
		folder = RAID_FOLDER, display = 'Raid Frames', font = original, outline = '__global',
	})
end

-- Works on both an import payload's data and a stored profile table.
-- Returns the action bar layout that was applied, if any.
local function ApplyLynLook(data)
	data.fonts = data.fonts or {}
	if data.fonts.global and data.fonts.global ~= FONT and not ns.db.originalFont then
		ns.db.originalFont = data.fonts.global
	end
	data.fonts.global = FONT
	data.fonts.outlineMode = 'shadow'
	KeepRaidFont(data.fonts)
	local barLayout
	for addon, styler in pairs(STYLERS) do
		local settings = data.addons and data.addons[addon]
		if type(settings) == 'table' then
			barLayout = styler(settings) or barLayout
		end
	end

	local unlock = data.unlockLayout
	if barLayout and type(unlock) == 'table' then
		Unchain(barLayout, unlock.anchors, unlock.widthMatch, unlock.heightMatch)
	end
	return barLayout
end

-- Already on "Lyn": the live settings are the stored profile tables, so
-- restyle them directly and reload.
local function RestyleActive()
	local profile = EllesmereUIDB.profiles[PROFILE_NAME]
	local barLayout = ApplyLynLook(profile)
	if barLayout then
		-- the live unlock-mode stores for the active profile
		Unchain(barLayout, EllesmereUIDB.unlockAnchors, EllesmereUIDB.unlockWidthMatch, EllesmereUIDB.unlockHeightMatch)
	end
	local fonts = EllesmereUI.GetFontsDB()
	fonts.global = FONT
	fonts.outlineMode = 'shadow'
	KeepRaidFont(fonts)
	ReloadUI()
end

-- /lyn raidfont: only put the raid frames back on the original font.
function ns:RestoreRaidFont()
	if not (EllesmereUI and EllesmereUI.GetFontsDB) then
		ns:Print('EllesmereUI is not loaded.')
		return
	end
	if InCombatLockdown() then
		ns:Print('Can\'t do that in combat.')
		return
	end
	KeepRaidFont(EllesmereUI.GetFontsDB())
	local profile = EllesmereUIDB.profiles[EllesmereUI.GetActiveProfileName()]
	if profile then
		profile.fonts = profile.fonts or {}
		KeepRaidFont(profile.fonts)
	end
	ReloadUI()
end

---------------------------------------------------------------------------
-- Single parts, for the settings panel: apply just the bar layout or just
-- the chat style to whichever EllesmereUI profile is active.
---------------------------------------------------------------------------

StaticPopupDialogs.LYNUI_CONFIRM = {
	text = '%s',
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(_, callback) callback() end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

function ns:Confirm(text, callback)
	StaticPopup_Show('LYNUI_CONFIRM', text, nil, callback)
end

local PARTS = {
	actionBars = { folder = 'EllesmereUIActionBars', styler = StyleActionBars, label = 'Lyn action bar layout' },
	chat = { folder = 'EllesmereUIChat', styler = StyleChat, label = 'Lyn chat style' },
}

function ns:ApplyPart(key)
	local part = PARTS[key]
	if not (EllesmereUI and EllesmereUI.GetActiveProfileName and EllesmereUIDB) then
		ns:Print('EllesmereUI is not loaded.')
		return
	end
	if InCombatLockdown() then
		ns:Print('Can\'t do that in combat.')
		return
	end

	local name = EllesmereUI.GetActiveProfileName()
	local profile = EllesmereUIDB.profiles[name]
	local settings = profile and profile.addons and profile.addons[part.folder]
	if type(settings) ~= 'table' then
		ns:Print(('%s is not enabled in EllesmereUI.'):format(part.folder))
		return
	end

	ns:Confirm(('Apply the %s to your EllesmereUI profile "%s"?\n\nYour UI will reload.'):format(part.label, name), function()
		local layout = part.styler(settings, true)
		if layout then
			local unlock = profile.unlockLayout
			if type(unlock) == 'table' then
				Unchain(layout, unlock.anchors, unlock.widthMatch, unlock.heightMatch)
			end
			Unchain(layout, EllesmereUIDB.unlockAnchors, EllesmereUIDB.unlockWidthMatch, EllesmereUIDB.unlockHeightMatch)
		end
		ReloadUI()
	end)
end

local function BuildAndImport()
	local EUI = EllesmereUI
	if InCombatLockdown() then
		ns:Print('Can\'t change profiles in combat.')
		return
	end

	local source = EUI.GetActiveProfileName()
	if source == PROFILE_NAME then
		RestyleActive()
		return
	end

	-- Export everything: all modules, unlock layout, cooldown manager + spells,
	-- global settings, spec overrides and window skins.
	local exported = EUI.ExportProfile(source, nil, true, true, nil, true, true, true)
	local payload, err = EUI.DecodeImportString(exported or '')
	if not payload then
		ns:Print('Could not read your current EllesmereUI profile:', err or 'unknown error')
		return
	end

	for _, name in ipairs(EUI.GetProfileList() or {}) do
		if name == PROFILE_NAME then
			EUI.DeleteProfile(PROFILE_NAME)
			break
		end
	end

	ApplyLynLook(payload.data)
	-- Keep the player's own UI scale and spec assignments.
	payload.data.uiScale = nil
	payload.data.applyUIScale = nil
	payload.data.assignedSpecs = nil

	local ok, importErr, status = EUI.ImportProfile(payload, PROFILE_NAME)
	if not ok then
		ns:Print('EllesmereUI refused the import:', importErr or 'unknown error')
		return
	end

	if status == 'spec_locked' then
		ns:Print(('Created the "%s" profile, but your current spec is assigned to another profile. Switch to it from EllesmereUI\'s Profiles page.'):format(PROFILE_NAME))
		return
	end
	ReloadUI()
end

StaticPopupDialogs.LYNUI_INSTALL = {
	text = '%s\n\nYour UI will reload.',
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = BuildAndImport,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

function ns:InstallProfile()
	local EUI = EllesmereUI
	if not (EUI and EUI.ExportProfile and EUI.DecodeImportString and EUI.ImportProfile) then
		ns:Print('EllesmereUI is not loaded, or this version has no profile API.')
		return
	end

	local source = EUI.GetActiveProfileName()
	local message
	if source == PROFILE_NAME then
		message = ('Re-apply the Lyn look to the "%s" profile?'):format(PROFILE_NAME)
	else
		local exists = false
		for _, name in ipairs(EUI.GetProfileList() or {}) do
			if name == PROFILE_NAME then exists = true end
		end
		message = ('Create the "%s" EllesmereUI profile from "%s"?'):format(PROFILE_NAME, source)
		if exists then
			message = message .. ('\nThis replaces the existing "%s" profile.'):format(PROFILE_NAME)
		end
	end
	StaticPopup_Show('LYNUI_INSTALL', message)
end

-- EllesmereUI's own player/target/... frames would sit on top of Lyn's.
ns:RegisterModule('unitFrames', function()
	local EUI = EllesmereUI
	if not (EUI and EUI.GetActiveProfileName and EllesmereUIDB and EllesmereUIDB.profiles) then return end
	if not C_AddOns.IsAddOnLoaded('EllesmereUIUnitFrames') then return end

	local profile = EllesmereUIDB.profiles[EUI.GetActiveProfileName()]
	local uf = profile and profile.addons and profile.addons.EllesmereUIUnitFrames
	local enabled = uf and uf.enabledFrames
	if not enabled or enabled.player ~= false then
		ns:Print('EllesmereUI is also drawing unit frames. Type /lyn install to hand player, target, focus, pet and boss frames over to Lyn.')
	end
end)
