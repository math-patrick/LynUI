local _, ns = ...
local oUF = ns.oUF
local UF = ns.UF

local PLAYER_CLASS = UnitClassBase('player')

-- Default positions from Lyn's layout: { point, relativePoint, x, y } on UIParent.
ns.UNIT_POSITIONS = {
	player = { 'BOTTOM', 'BOTTOM', -185, 125 },
	target = { 'BOTTOM', 'BOTTOM', 187, 125 },
	focus = { 'BOTTOMLEFT', 'BOTTOMLEFT', 50, 525 },
	pet = { 'BOTTOMLEFT', 'BOTTOMLEFT', 50, 425 },
	boss = { 'TOPRIGHT', 'TOPRIGHT', -325, -350 },
	targetCastbar = { 'BOTTOM', 'BOTTOM', 0, 350 },
}

---------------------------------------------------------------------------
-- Player / Target (342 x 40)
---------------------------------------------------------------------------

local function Main(self, unit)
	UF.SetupFrame(self, 342, 40)

	local health = UF.CreateHealth(self)
	health:SetPoint('TOPLEFT', 2, -2)
	health:SetPoint('BOTTOMRIGHT', -2, 8)
	UF.CreateHealPrediction(self, 338)
	UF.CreatePower(self)

	local overlay = UF.CreateOverlay(self)

	local percent = UF.CreateText(overlay, UF.FONT_BIG, 22, 'RIGHT')
	percent:SetPoint('RIGHT', -7, -.5)
	self.HealthPercent = percent

	local value = UF.CreateText(overlay, unit == 'player' and UF.FONT_BIG or UF.FONT_BOLD, 10, 'RIGHT')
	value:SetPoint('RIGHT', percent, 'LEFT', -5, 1)
	value:SetTextColor(.8, .8, .8)
	value.hideAtFull = unit == 'player'
	self.HealthValue = value

	local marker = overlay:CreateTexture(nil, 'OVERLAY')
	marker:SetSize(32, 32)
	marker:SetPoint('TOP', overlay, 'BOTTOM', 0, 15)
	self.RaidTargetIndicator = marker

	return overlay
end

local function Player(self, unit)
	local overlay = Main(self, unit)

	local power = UF.CreateText(overlay, UF.FONT_BIG, 22, 'LEFT')
	power:SetPoint('LEFT', 7, -.5)
	self.PowerValue = power

	local pvp = UF.CreateText(self, UF.FONT_BIG, 12, 'LEFT')
	pvp:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -5)
	self:Tag(pvp, '[lyn:pvp]')

	local resting = UF.CreateText(self, UF.FONT_BIG, 12, 'LEFT')
	resting:SetPoint('LEFT', pvp, 'RIGHT', 0, 0)
	resting:SetText('|cff5f9bffRESTING|r')
	self.RestingIndicator = resting

	local leader = overlay:CreateTexture(nil, 'OVERLAY')
	leader:SetSize(13, 13)
	leader:SetPoint('BOTTOMRIGHT', overlay, 'TOPRIGHT', -6, -5)
	self.LeaderIndicator = leader

	-- Procs and big cooldowns above the frame, right-aligned (Lyn's whitelist
	-- used Legion spell IDs; Midnight's IMPORTANT flag covers the same idea).
	local auras = UF.CreateAuras(self, {
		filter = 'HELPFUL|PLAYER|IMPORTANT', max = 10, size = 32, width = 342, height = 70,
		anchor = 'BOTTOMRIGHT', growthX = 'LEFT', growthY = 'UP',
	})
	-- above the class resource strip
	auras:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', -1, 16)
	self.LynProcs = auras

	-- Combo points, holy power, chi, ... as a thin strip on top of the frame.
	self.ClassPower = UF.CreateSegments(self, 10, 342)

	if PLAYER_CLASS == 'DEATHKNIGHT' then
		local runes = UF.CreateSegments(self, 6, 342)
		runes.PostUpdate = nil -- always six
		runes.colorSpec = true
		self.Runes = runes
	end

	UF.CreateCastbar(self, 'overlay', true)
end

local function Target(self, unit)
	local overlay = Main(self, unit)

	local name = UF.CreateText(overlay, UF.FONT_BIG, 18, 'LEFT')
	name:SetPoint('LEFT', 7, -.5)
	name:SetPoint('RIGHT', self.HealthValue, 'LEFT', -10, 0)
	self:Tag(name, '[lyn:name]')

	local classification = UF.CreateText(overlay, UF.FONT_BIG, 12, 'RIGHT')
	classification:SetPoint('BOTTOMRIGHT', overlay, 'TOPRIGHT', -6, -4)
	self:Tag(classification, '[lyn:classification]')

	local quest = UF.CreateText(overlay, UF.FONT_BIG, 12, 'RIGHT')
	quest:SetPoint('RIGHT', classification, 'LEFT', -1, 0)
	quest:SetText('|cffffe400QUEST|r')
	self.QuestIndicator = quest

	local pvp = UF.CreateText(overlay, UF.FONT_BIG, 12, 'LEFT')
	pvp:SetPoint('BOTTOMLEFT', overlay, 'TOPLEFT', 6, -4)
	self:Tag(pvp, '[lyn:pvp]')

	local debuffs = UF.CreateAuras(self, {
		filter = 'HARMFUL|PLAYER', max = 27, size = 32, width = 342, height = 108,
		anchor = 'BOTTOMLEFT', growthX = 'RIGHT', growthY = 'UP', debuffBorder = true,
	})
	debuffs:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', 1, 6)
	self.LynDebuffs = debuffs

	local buffs = UF.CreateAuras(self, {
		filter = 'HELPFUL', max = 12, size = 22, width = 342,
		anchor = 'TOPLEFT', growthX = 'RIGHT', growthY = 'DOWN',
	})
	buffs:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 1, -6)
	self.LynBuffs = buffs

	UF.CreateCastbar(self, 'target')
end

---------------------------------------------------------------------------
-- Target of target (name only, above the target frame)
---------------------------------------------------------------------------

local function TargetTarget(self)
	self:RegisterForClicks('AnyUp')
	self:SetSize(180, 12)

	local name = UF.CreateText(self, UF.FONT_BIG, 12, 'CENTER')
	name:SetAllPoints()
	self:Tag(name, '[lyn:color][lyn:name]')
end

---------------------------------------------------------------------------
-- Focus / Pet (140 x 26)
---------------------------------------------------------------------------

local function Small(self)
	UF.SetupFrame(self, 140, 26)

	local health = UF.CreateHealth(self)
	health:SetAllPoints()
	UF.CreateHealPrediction(self, 140)

	local overlay = UF.CreateOverlay(self)

	local percent = UF.CreateText(overlay, UF.FONT_BIG, 13, 'RIGHT')
	percent:SetPoint('RIGHT', -7, 0)
	self.HealthPercent = percent

	local name = UF.CreateText(overlay, UF.FONT_BIG, 13, 'LEFT')
	name:SetPoint('LEFT', 7, 0)
	name:SetPoint('RIGHT', percent, 'LEFT', -4, 0)
	self:Tag(name, '[lyn:name]')

	local marker = overlay:CreateTexture(nil, 'OVERLAY')
	marker:SetSize(24, 24)
	marker:SetPoint('TOP', 0, 11)
	self.RaidTargetIndicator = marker

	local buffs = UF.CreateAuras(self, {
		filter = 'HELPFUL', max = 5, size = 22, width = 140,
		anchor = 'TOPLEFT', growthX = 'RIGHT', growthY = 'DOWN',
	})
	buffs:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -9)

	local debuffs = UF.CreateAuras(self, {
		filter = 'HARMFUL|PLAYER', max = 5, size = 22, width = 140,
		anchor = 'BOTTOMLEFT', growthX = 'RIGHT', growthY = 'UP', debuffBorder = true,
	})
	debuffs:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', 0, 9)

	UF.CreateCastbar(self, 'overlay')
end

---------------------------------------------------------------------------
-- Boss (160 x 20)
---------------------------------------------------------------------------

local function Boss(self)
	UF.SetupFrame(self, 160, 20)

	local health = UF.CreateHealth(self)
	health:SetAllPoints()
	health.colorClass = false

	local overlay = UF.CreateOverlay(self)

	local percent = UF.CreateText(overlay, UF.FONT_BIG, 16, 'RIGHT')
	percent:SetPoint('RIGHT', -2, 0)
	self.HealthPercent = percent

	local value = UF.CreateText(overlay, UF.FONT_BIG, 12, 'RIGHT')
	value:SetPoint('RIGHT', percent, 'LEFT', 0, 0)
	value:SetTextColor(.8, .8, .8)
	self.HealthValue = value

	local name = UF.CreateText(overlay, UF.FONT_BIG, 13, 'LEFT')
	name:SetPoint('BOTTOMLEFT', overlay, 'TOPLEFT', 2, 4)
	name:SetPoint('RIGHT', 0, 0)
	self:Tag(name, '[lyn:name]')

	local marker = overlay:CreateTexture(nil, 'OVERLAY')
	marker:SetSize(18, 18)
	marker:SetPoint('TOP', 0, 10)
	self.RaidTargetIndicator = marker

	local debuffs = UF.CreateAuras(self, {
		filter = 'HARMFUL|PLAYER', max = 4, size = 18, width = 100,
		anchor = 'TOPRIGHT', growthX = 'LEFT', growthY = 'DOWN', debuffBorder = true,
	})
	debuffs:SetPoint('TOPRIGHT', self, 'TOPLEFT', -9, 0)

	UF.CreateCastbar(self, 'overlay')

	self.Range = { insideAlpha = 1, outsideAlpha = .5 }
end

---------------------------------------------------------------------------
-- Spawning
---------------------------------------------------------------------------

oUF:RegisterStyle('Lyn:Player', Player)
oUF:RegisterStyle('Lyn:Target', Target)
oUF:RegisterStyle('Lyn:TargetTarget', TargetTarget)
oUF:RegisterStyle('Lyn:Small', Small)
oUF:RegisterStyle('Lyn:Boss', Boss)

-- frames that /lyn move can reposition, keyed like ns.UNIT_POSITIONS
ns.movableUnits = {}

local function Place(frame, key)
	local p = ns.db.unitPositions[key] or ns.UNIT_POSITIONS[key]
	frame:ClearAllPoints()
	frame:SetPoint(p[1], UIParent, p[2], p[3], p[4])
	ns.movableUnits[key] = frame
end

---------------------------------------------------------------------------
-- Live settings
---------------------------------------------------------------------------

local frames = {} -- every spawned unit frame
local player, target

local function SetElement(frame, element, on)
	if not frame then return end
	if on then frame:EnableElement(element) else frame:DisableElement(element) end
end

local function ApplyScale()
	ns:AfterCombat('unitScale', function()
		for _, frame in ipairs(frames) do frame:SetScale(ns.db.unitScale) end
	end)
end

-- Aura containers and cast bars touch secure frames, so this also waits for
-- combat to end.
local function ApplyElementsNow()
	if player then
		SetElement(player, 'ClassPower', ns.db.showClassPower)
		if player.Runes then SetElement(player, 'Runes', ns.db.showClassPower) end
		SetElement(player, 'Castbar', ns.db.playerCastbar)
		player.LynProcs:SetShown(ns.db.showPlayerProcs)
	end
	if target then
		SetElement(target, 'Castbar', ns.db.targetCastbar)
		target.LynBuffs:SetShown(ns.db.showTargetBuffs)
		target.LynDebuffs:SetShown(ns.db.showTargetDebuffs)
	end
end

local function ApplyElements()
	ns:AfterCombat('unitElements', ApplyElementsNow)
end

function ns:ResetUnitPositions()
	wipe(ns.db.unitPositions)
	ns:AfterCombat('unitPositions', function()
		for key, frame in next, ns.movableUnits do Place(frame, key) end
	end)
end

ns:RegisterModule('unitFrames', function()
	UF.LoadMedia()

	oUF:Factory(function(self)
		self:SetActiveStyle('Lyn:Player')
		player = self:Spawn('player', 'LynPlayerFrame')
		Place(player, 'player')

		self:SetActiveStyle('Lyn:Target')
		target = self:Spawn('target', 'LynTargetFrame')
		Place(target, 'target')
		Place(target.Castbar, 'targetCastbar')

		self:SetActiveStyle('Lyn:TargetTarget')
		local tot = self:Spawn('targettarget', 'LynTargetTargetFrame')
		tot:SetPoint('BOTTOM', target, 'TOP', 0, -7)
		tot:SetFrameLevel(target:GetFrameLevel() + 10)

		self:SetActiveStyle('Lyn:Small')
		local focus = self:Spawn('focus', 'LynFocusFrame')
		Place(focus, 'focus')
		local pet = self:Spawn('pet', 'LynPetFrame')
		Place(pet, 'pet')

		frames = { player, target, tot, focus, pet }

		self:SetActiveStyle('Lyn:Boss')
		local previous
		for index = 1, MAX_BOSS_FRAMES or 5 do
			local boss = self:Spawn('boss' .. index, 'LynBossFrame' .. index)
			if index == 1 then
				Place(boss, 'boss')
			else
				boss:SetPoint('TOPRIGHT', previous, 'BOTTOMRIGHT', 0, -30)
			end
			previous = boss
			table.insert(frames, boss)
		end

		ApplyScale()
		ApplyElements()
	end)

	ns:OnChange('unitScale', ApplyScale)
	ns:OnChange('ufTexture', UF.SetTexture)
	ns:OnChange('ufFont', UF.SetFont)
	for _, key in ipairs({ 'showClassPower', 'playerCastbar', 'targetCastbar', 'showPlayerProcs', 'showTargetBuffs', 'showTargetDebuffs' }) do
		ns:OnChange(key, ApplyElements)
	end
end)
