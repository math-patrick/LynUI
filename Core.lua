local addonName, ns = ...

ns.MEDIA = [[Interface\AddOns\LynUI\media\]]
ns.COLOR_GOLD = { 218/255, 193/255, 28/255 }
ns.COLOR_DARK = { .2, .2, .2 }

-- Everything here is editable in the settings panel (/lyn). Most options
-- apply immediately through ns:Set; the few that need a reload say so.
ns.DEFAULTS = {
	-- unit frames
	unitFrames = true,
	unitPositions = {},
	unitScale = 1,
	ufTexture = 'Lyn Fer35',
	ufFont = 'Lyn Passion One',
	showClassPower = true,
	showPlayerProcs = true,
	showTargetBuffs = true,
	showTargetDebuffs = true,
	playerCastbar = true,
	targetCastbar = true,

	-- action bars
	actionBars = true,       -- /lyn install lays out EllesmereUI's bars
	buttonBorders = true,
	buttonBorderColor = 'dark',

	-- chat
	chatStyle = true,        -- /lyn install styles EllesmereUI's chat
	compactChat = true,
	hideChatSpam = true,

	-- screen
	infoBar = true,
	infoBarHeight = 50,
	infoBarTrim = 'gold',
	menuButton = true,
	menuSize = 30,
	menuPoint = { 'BOTTOMRIGHT', 'UIParent', 'BOTTOMRIGHT', -10, 10 },
}

-- Named colors used by several options.
function ns:GetColor(name)
	if name == 'gold' then return unpack(ns.COLOR_GOLD) end
	if name == 'class' then
		local color = C_ClassColor.GetClassColor(UnitClassBase('player'))
		return color:GetRGB()
	end
	if name == 'black' then return 0, 0, 0 end
	return unpack(ns.COLOR_DARK)
end

---------------------------------------------------------------------------
-- Settings store with change callbacks
---------------------------------------------------------------------------

local listeners = {}

function ns:OnChange(key, callback)
	listeners[key] = listeners[key] or {}
	table.insert(listeners[key], callback)
end

function ns:Set(key, value)
	ns.db[key] = value
	for _, callback in ipairs(listeners[key] or {}) do
		local ok, err = pcall(callback, value)
		if not ok then geterrorhandler()(err) end
	end
end

-- Secure frames (unit frames) can't be changed in combat; run afterwards.
local combatQueue = {}
local combatWatcher = CreateFrame('Frame')
combatWatcher:SetScript('OnEvent', function(self)
	self:UnregisterEvent('PLAYER_REGEN_ENABLED')
	for key, fn in pairs(combatQueue) do
		combatQueue[key] = nil
		fn()
	end
end)

function ns:AfterCombat(key, fn)
	if not InCombatLockdown() then
		fn()
		return
	end
	combatQueue[key] = fn
	combatWatcher:RegisterEvent('PLAYER_REGEN_ENABLED')
	ns:Print('That change will apply when combat ends.')
end

---------------------------------------------------------------------------
-- Modules
---------------------------------------------------------------------------

local modules = {}

-- `key` names a setting that must be on for the module to start at login
-- (only for features that can't be switched on later without a reload).
-- Modules without a key always start and follow their settings live.
function ns:RegisterModule(key, onEnable)
	modules[#modules + 1] = { key = key, onEnable = onEnable }
end

function ns:Print(...)
	print('|cff10c5d3Lyn|rUI:', ...)
end

-- Midnight hands addons "secret" values in restricted contexts (combat,
-- instances). They can be displayed but never compared or string-matched.
function ns.IsSecret(value)
	return issecretvalue ~= nil and issecretvalue(value)
end

local loader = CreateFrame('Frame')
loader:RegisterEvent('ADDON_LOADED')
loader:RegisterEvent('PLAYER_LOGIN')
loader:SetScript('OnEvent', function(self, event, arg1)
	if event == 'ADDON_LOADED' and arg1 == addonName then
		LynUIDB = LynUIDB or {}
		for key, value in pairs(ns.DEFAULTS) do
			if LynUIDB[key] == nil then
				LynUIDB[key] = type(value) == 'table' and CopyTable(value) or value
			end
		end
		ns.db = LynUIDB
		self:UnregisterEvent('ADDON_LOADED')
	elseif event == 'PLAYER_LOGIN' then
		for _, module in ipairs(modules) do
			if not module.key or ns.db[module.key] ~= false then
				local ok, err = pcall(module.onEnable)
				if not ok then geterrorhandler()(err) end
			end
		end
		self:UnregisterEvent('PLAYER_LOGIN')
	end
end)

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------

local function PrintHelp()
	ns:Print('commands:')
	print('  /lyn  - open the settings')
	print('  /lyn install  - create or re-apply the "Lyn" EllesmereUI profile')
	print('  /lyn raidfont  - keep EllesmereUI raid frames on your original font')
	print('  /lyn move  - unlock/lock the unit frames for dragging')
	print('  /lyn resetframes  - put the unit frames back in Lyn\'s layout')
	print('  /lyn resetmenu  - move the menu button back to its default spot')
end

SLASH_LYNUI1 = '/lyn'
SlashCmdList.LYNUI = function(msg)
	local cmd = strtrim(msg or ''):lower()
	if cmd == '' or cmd == 'config' or cmd == 'options' then
		ns:OpenSettings()
	elseif cmd == 'install' then
		ns:InstallProfile()
	elseif cmd == 'raidfont' then
		ns:RestoreRaidFont()
	elseif cmd == 'move' then
		ns:ToggleMovers()
	elseif cmd == 'resetframes' then
		ns:ResetUnitPositions()
	elseif cmd == 'resetmenu' then
		ns:ResetMenuButton(true)
	else
		PrintHelp()
	end
end
