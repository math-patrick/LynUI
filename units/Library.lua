local _, ns = ...

-- Shared building blocks for Lyn's oUF unit frames.
--
-- Midnight note: in combat and instances, health and power numbers reach
-- addons as "secret" values. They can be displayed (SetValue, SetText,
-- AbbreviateNumbers) but not compared or used in math. Everything that Lyn
-- used to decide with an `if` (hide the percent at full health, the red to
-- green gradient, hiding power text when empty or full) is therefore done
-- with curves, which the client evaluates for us.

local UF = {}
ns.UF = UF

UF.FONT_BIG = ns.MEDIA .. [[fonts\PassionOne-Regular.ttf]]
UF.FONT_BOLD = ns.MEDIA .. [[fonts\RobotoSlab-Bold.ttf]]
UF.TEXTURE = ns.MEDIA .. [[statusbars\fer35.tga]]
UF.TEXTURE_STRIPED = ns.MEDIA .. [[statusbars\lyn2.tga]]

local BORDER = ns.MEDIA .. [[border\]]
local PLAYER_CLASS = UnitClassBase('player')

---------------------------------------------------------------------------
-- Live media: every bar and text built here is remembered so the texture
-- and font chosen in the settings can be swapped without a reload.
---------------------------------------------------------------------------

local registry = { bars = {}, textures = {}, texts = {} }

local function Fetch(kind, name, fallback)
	local LSM = LibStub and LibStub('LibSharedMedia-3.0', true)
	return LSM and name and LSM:Fetch(kind, name, true) or fallback
end

-- Resolve the saved choices; called before any frame is built.
function UF.LoadMedia()
	UF.TEXTURE = Fetch('statusbar', ns.db.ufTexture, UF.TEXTURE)
	UF.FONT_BIG = Fetch('font', ns.db.ufFont, UF.FONT_BIG)
end

function UF.SetTexture(name)
	UF.TEXTURE = Fetch('statusbar', name, UF.TEXTURE)
	for bar in next, registry.bars do bar:SetStatusBarTexture(UF.TEXTURE) end
	for tex in next, registry.textures do tex:SetTexture(UF.TEXTURE) end
end

function UF.SetFont(name)
	UF.FONT_BIG = Fetch('font', name, UF.FONT_BIG)
	for text, style in next, registry.texts do
		text:SetFont(UF.FONT_BIG, style.size, style.outline)
	end
end

local function RegisterText(text, size, outline)
	registry.texts[text] = { size = size, outline = outline }
end

---------------------------------------------------------------------------
-- Curves
---------------------------------------------------------------------------

local function StepCurve(...)
	local curve = C_CurveUtil.CreateCurve()
	curve:SetType(Enum.LuaCurveType.Step)
	for i = 1, select('#', ...), 2 do
		curve:AddPoint(select(i, ...), select(i + 1, ...))
	end
	return curve
end

-- alpha 1 below 100%, 0 at exactly 100%
UF.HIDE_AT_FULL = StepCurve(0, 1, 1, 0)
-- alpha 0 when empty, 1 in between, 0 when full
UF.HIDE_AT_EMPTY_OR_FULL = StepCurve(0, 0, 0.0001, 1, 1, 0)

-- red -> yellow -> green, used to color the health percent text
UF.GRADIENT = C_CurveUtil.CreateColorCurve()
UF.GRADIENT:SetType(Enum.LuaCurveType.Linear)
UF.GRADIENT:AddPoint(0, CreateColor(1, 0, 0))
UF.GRADIENT:AddPoint(0.5, CreateColor(1, 1, 0))
UF.GRADIENT:AddPoint(1, CreateColor(0, 1, 0))

---------------------------------------------------------------------------
-- Art
---------------------------------------------------------------------------

local SECTIONS = { 'TOPLEFT', 'TOPRIGHT', 'BOTTOMLEFT', 'BOTTOMRIGHT', 'TOP', 'BOTTOM', 'LEFT', 'RIGHT' }

local function SetBorderColor(self, r, g, b, a)
	for _, tex in next, self.borderTextures do
		tex:SetVertexColor(r, g, b, a or 1)
	end
end

-- Lyn's 8-piece beveled border. Returns the textures without touching the
-- object's fields, so it is safe on Blizzard/secure frames too.
function UF.CreateBorderTextures(object, offset, layer, sublevel)
	offset = offset or 0

	local t = {}
	for i, section in ipairs(SECTIONS) do
		local tex = object:CreateTexture(nil, layer or 'OVERLAY', nil, sublevel or 1)
		tex:SetTexture(BORDER .. section, i > 4 and 'REPEAT' or nil, i > 4 and 'REPEAT' or nil)
		t[section] = tex
	end

	t.TOPLEFT:SetSize(8, 8)
	t.TOPLEFT:SetPoint('BOTTOMRIGHT', object, 'TOPLEFT', 6 + offset, -6 - offset)
	t.TOPRIGHT:SetSize(8, 8)
	t.TOPRIGHT:SetPoint('BOTTOMLEFT', object, 'TOPRIGHT', -6 - offset, -6 - offset)
	t.BOTTOMLEFT:SetSize(8, 8)
	t.BOTTOMLEFT:SetPoint('TOPRIGHT', object, 'BOTTOMLEFT', 6 + offset, 6 + offset)
	t.BOTTOMRIGHT:SetSize(8, 8)
	t.BOTTOMRIGHT:SetPoint('TOPLEFT', object, 'BOTTOMRIGHT', -6 - offset, 6 + offset)

	t.TOP:SetHeight(8)
	t.TOP:SetHorizTile(true)
	t.TOP:SetPoint('TOPLEFT', t.TOPLEFT, 'TOPRIGHT', 0, 2)
	t.TOP:SetPoint('TOPRIGHT', t.TOPRIGHT, 'TOPLEFT', 0, 2)
	t.BOTTOM:SetHeight(8)
	t.BOTTOM:SetHorizTile(true)
	t.BOTTOM:SetPoint('BOTTOMLEFT', t.BOTTOMLEFT, 'BOTTOMRIGHT', 0, -2)
	t.BOTTOM:SetPoint('BOTTOMRIGHT', t.BOTTOMRIGHT, 'BOTTOMLEFT', 0, -2)
	t.LEFT:SetWidth(8)
	t.LEFT:SetVertTile(true)
	t.LEFT:SetPoint('TOPLEFT', t.TOPLEFT, 'BOTTOMLEFT', -2, 0)
	t.LEFT:SetPoint('BOTTOMLEFT', t.BOTTOMLEFT, 'TOPLEFT', -2, 0)
	t.RIGHT:SetWidth(8)
	t.RIGHT:SetVertTile(true)
	t.RIGHT:SetPoint('TOPRIGHT', t.TOPRIGHT, 'BOTTOMRIGHT', 2, 0)
	t.RIGHT:SetPoint('BOTTOMRIGHT', t.BOTTOMRIGHT, 'TOPRIGHT', 2, 0)

	for _, tex in next, t do
		tex:SetVertexColor(unpack(ns.COLOR_DARK))
	end
	return t
end

-- Same, stored on our own frames with a SetBorderColor method.
function UF.CreateBorder(object, offset, layer, sublevel)
	if object.borderTextures then return end
	object.borderTextures = UF.CreateBorderTextures(object, offset, layer, sublevel)
	object.SetBorderColor = SetBorderColor
end

-- Black background plus the Lyn border on a raised child frame.
function UF.CreateLayout(frame, inset)
	local bg = frame:CreateTexture(nil, 'BACKGROUND', nil, -8)
	bg:SetColorTexture(0, 0, 0, 1)
	bg:SetPoint('TOPLEFT', 1, -1)
	bg:SetPoint('BOTTOMRIGHT', -1, 1)

	local border = CreateFrame('Frame', nil, frame)
	border:SetAllPoints()
	border:SetFrameLevel(frame:GetFrameLevel() + 4)
	UF.CreateBorder(border, inset or 0)
	frame.LynBorder = border
end

function UF.CreateShadow(frame)
	local shadow = CreateFrame('Frame', nil, frame, 'BackdropTemplate')
	shadow:SetPoint('TOPLEFT', -6.5, 6.5)
	shadow:SetPoint('BOTTOMRIGHT', 6.5, -6.5)
	shadow:SetFrameStrata('BACKGROUND')
	shadow:SetFrameLevel(0)
	shadow:SetBackdrop({ edgeFile = BORDER .. 'shadow', edgeSize = 10 })
	shadow:SetBackdropBorderColor(0, 0, 0, .8)
end

-- Texts using the main unit frame font follow the font setting live.
function UF.CreateText(parent, font, size, justify, outline)
	outline = outline or 'OUTLINE'
	local text = parent:CreateFontString(nil, 'OVERLAY')
	text:SetFont(font, size, outline)
	text:SetShadowOffset(1, -1)
	text:SetShadowColor(0, 0, 0, 1)
	text:SetTextColor(1, 1, 1)
	text:SetJustifyH(justify or 'LEFT')
	text:SetWordWrap(false)
	if font == UF.FONT_BIG then RegisterText(text, size, outline) end
	return text
end

-- Bars without an explicit texture follow the texture setting live.
local function CreateBar(parent, texture)
	local bar = CreateFrame('StatusBar', nil, parent)
	bar:SetStatusBarTexture(texture or UF.TEXTURE)
	if not texture then registry.bars[bar] = true end
	return bar
end

local function CreateBarBackground(bar)
	local bg = bar:CreateTexture(nil, 'BORDER')
	bg:SetAllPoints()
	bg:SetTexture(UF.TEXTURE)
	bg:SetVertexColor(.15, .15, .15, 1)
	registry.textures[bg] = true
end

---------------------------------------------------------------------------
-- Health
---------------------------------------------------------------------------

local function IsGone(unit)
	return not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit)
end

local function UpdateHealthTexts(health, unit, cur)
	local frame = health.__owner

	local percent = frame.HealthPercent
	if percent then
		percent:SetAlpha(1)
		percent:SetTextColor(1, 1, 1)
		if not UnitIsConnected(unit) then
			percent:SetText('|cff999999OFFLINE|r')
		elseif UnitIsGhost(unit) then
			percent:SetText('|cff999999GHOST|r')
		elseif UnitIsDead(unit) then
			percent:SetText('|cff999999DEAD|r')
		else
			percent:SetFormattedText('%d%%', UnitHealthPercent(unit, true, CurveConstants.ScaleTo100))
			percent:SetAlpha(UnitHealthPercent(unit, false, UF.HIDE_AT_FULL))
			-- If the client refuses secret text colors, stay white from then on.
			if UF.gradientText ~= false then
				local color = UnitHealthPercent(unit, true, UF.GRADIENT)
				if not pcall(percent.SetTextColor, percent, color:GetRGB()) then
					UF.gradientText = false
					percent:SetTextColor(1, 1, 1)
				end
			end
		end
	end

	local value = frame.HealthValue
	if value then
		if IsGone(unit) then
			value:SetText('')
		else
			value:SetText(AbbreviateNumbers(cur))
			if value.hideAtFull then
				value:SetAlpha(UnitHealthPercent(unit, false, UF.HIDE_AT_FULL))
			end
		end
	end
end

local function PostUpdateHealth(health, unit, cur)
	if UnitIsDeadOrGhost(unit) then
		health:SetValue(0)
	end
	UpdateHealthTexts(health, unit, cur)
end

function UF.CreateHealth(self)
	local health = CreateBar(self)
	health:SetStatusBarColor(.1, .1, .1)
	CreateBarBackground(health)

	health.smoothing = Enum.StatusBarInterpolation.ExponentialEaseOut
	health.colorDisconnected = true
	health.colorTapping = true
	health.colorClass = true
	health.colorReaction = true
	health.PostUpdate = PostUpdateHealth

	self.Health = health
	return health
end

-- Incoming heals, absorbs and heal absorbs, as in Lyn's HealPrediction.
function UF.CreateHealPrediction(self, width)
	local health = self.Health

	local function Overlay(anchor, r, g, b, a)
		local bar = CreateBar(health)
		bar:SetPoint('TOP')
		bar:SetPoint('BOTTOM')
		bar:SetPoint('LEFT', anchor, 'RIGHT')
		bar:SetWidth(width)
		bar:SetStatusBarColor(r, g, b, a)
		return bar
	end

	local healingPlayer = Overlay(health:GetStatusBarTexture(), 12/255, 217/255, 21/255, .5)
	local healingOther = Overlay(healingPlayer:GetStatusBarTexture(), 12/255, 217/255, 21/255, .5)
	local absorb = Overlay(healingOther:GetStatusBarTexture(), .6, .6, .6, .5)

	local shield = absorb:CreateTexture(nil, 'OVERLAY')
	shield:SetTexture([[Interface\RaidFrame\Shield-Overlay]], 'REPEAT', 'REPEAT')
	shield:SetHorizTile(true)
	shield:SetVertTile(true)
	shield:SetAllPoints(absorb:GetStatusBarTexture())

	local overAbsorb = health:CreateTexture(nil, 'OVERLAY')
	overAbsorb:SetTexture([[Interface\RaidFrame\Shield-Overshield]])
	overAbsorb:SetBlendMode('ADD')
	overAbsorb:SetWidth(16)
	overAbsorb:SetPoint('TOP')
	overAbsorb:SetPoint('BOTTOM')
	overAbsorb:SetPoint('LEFT', health, 'RIGHT', -7, 0)

	local healAbsorb = CreateBar(health)
	healAbsorb:SetPoint('TOP')
	healAbsorb:SetPoint('BOTTOM')
	healAbsorb:SetPoint('RIGHT', health:GetStatusBarTexture())
	healAbsorb:SetWidth(width)
	healAbsorb:SetReverseFill(true)
	healAbsorb:SetStatusBarColor(200/255, 72/255, 59/255)

	health.HealingPlayer = healingPlayer
	health.HealingOther = healingOther
	health.DamageAbsorb = absorb
	health.OverDamageAbsorbIndicator = overAbsorb
	health.HealAbsorb = healAbsorb
end

---------------------------------------------------------------------------
-- Power
---------------------------------------------------------------------------

local function SetPowerShown(power, shown)
	if power.isShown == shown then return end
	power.isShown = shown
	local health = power.__owner.Health
	health:ClearAllPoints()
	health:SetPoint('TOPLEFT', 2, -2)
	health:SetPoint('BOTTOMRIGHT', -2, shown and 8 or 2)
	power:SetShown(shown)
end

local function PostUpdatePower(power, unit, cur, _, max)
	local frame = power.__owner

	-- Units without a power bar give the whole frame to health. A secret max
	-- can't be tested, so in that case the bar simply stays where it is.
	local empty = false
	if not issecretvalue(max) then
		empty = max <= 0
		SetPowerShown(power, not empty and not IsGone(unit) and not unit:match('^boss'))
	end

	local text = frame.PowerValue
	if text then
		if empty or IsGone(unit) then
			text:SetText('')
		else
			local _, token = UnitPowerType(unit)
			local color = frame.colors.power[token] or frame.colors.power.MANA
			text:SetText(AbbreviateNumbers(cur))
			text:SetTextColor(color:GetRGB())
			text:SetAlpha(UnitPowerPercent(unit, nil, false, UF.HIDE_AT_EMPTY_OR_FULL))
		end
	end
end

function UF.CreatePower(self)
	local power = CreateBar(self)
	power:SetPoint('BOTTOMLEFT', 2, 2)
	power:SetPoint('TOPRIGHT', self, 'BOTTOMRIGHT', -2, 7)
	power:SetStatusBarColor(.1, .1, .1)
	CreateBarBackground(power)

	local cost = CreateBar(power)
	cost:SetPoint('TOP')
	cost:SetPoint('BOTTOM')
	cost:SetPoint('RIGHT', power:GetStatusBarTexture())
	cost:SetWidth(self:GetWidth())
	cost:SetFrameLevel(power:GetFrameLevel() + 1)
	cost:SetReverseFill(true)
	cost:SetStatusBarColor(1, 0, 0)
	power.CostPrediction = cost

	power.smoothing = Enum.StatusBarInterpolation.ExponentialEaseOut
	power.colorPower = true
	power.PostUpdate = PostUpdatePower
	power.isShown = true

	self.Power = power
	return power
end

---------------------------------------------------------------------------
-- Class resources (combo points, holy power, chi, runes, ...)
---------------------------------------------------------------------------

local SEGMENT_HEIGHT, SEGMENT_GAP = 6, 3

-- Spread the visible segments across the full frame width.
local function LayoutSegments(segments, count)
	if not count or issecretvalue(count) or count < 1 then return end
	if segments.laidOut == count then return end
	segments.laidOut = count
	local width = (segments.width - (count - 1) * SEGMENT_GAP) / count
	for index, segment in ipairs(segments) do
		segment:SetWidth(width)
		segment:ClearAllPoints()
		segment:SetPoint('BOTTOMLEFT', segments.anchor, 'TOPLEFT', (index - 1) * (width + SEGMENT_GAP), 4)
	end
end

-- A thin strip of segments sitting on top of the frame. Every segment starts
-- hidden; oUF shows the ones the current class/spec actually uses.
function UF.CreateSegments(self, count, width)
	local segments = { width = width, anchor = self }
	for index = 1, count do
		local segment = CreateBar(self)
		segment:SetHeight(SEGMENT_HEIGHT)
		segment:Hide()

		local bg = segment:CreateTexture(nil, 'BACKGROUND')
		bg:SetPoint('TOPLEFT', -1, 1)
		bg:SetPoint('BOTTOMRIGHT', 1, -1)
		bg:SetColorTexture(0, 0, 0, 1)

		segments[index] = segment
	end
	LayoutSegments(segments, count)

	segments.PostUpdate = function(element, _, max)
		LayoutSegments(element, max)
	end
	return segments
end

---------------------------------------------------------------------------
-- Castbar
---------------------------------------------------------------------------

local INTERRUPTIBLE = { 12/255, 211/255, 99/255 }
local LOCKED = { .4, .4, .4 }

local function PostCastStart(castbar, unit, _, notInterruptible, name)
	if castbar.Text and name and not issecretvalue(name) then
		castbar.Text:SetText(name:upper())
	end

	if castbar.style == 'target' then
		-- notInterruptible may be secret, so let the client pick the color.
		local pick = C_CurveUtil.EvaluateColorValueFromBoolean
		castbar:SetStatusBarColor(
			pick(notInterruptible, LOCKED[1], INTERRUPTIBLE[1]),
			pick(notInterruptible, LOCKED[2], INTERRUPTIBLE[2]),
			pick(notInterruptible, LOCKED[3], INTERRUPTIBLE[3]))
	elseif unit == 'player' and PLAYER_CLASS == 'PRIEST' then
		castbar:SetStatusBarColor(252/255, 100/255, 74/255)
	else
		castbar:SetStatusBarColor(1, 1, 1)
	end
end

-- 'overlay': striped bar drawn over the health bar (player, focus, pet).
-- 'target': Lyn's big standalone bar near the middle of the screen.
function UF.CreateCastbar(self, style, withText)
	local castbar = CreateFrame('StatusBar', nil, self)
	castbar.style = style
	castbar.PostCastStart = PostCastStart
	castbar.timeToHold = 0.5

	local spark = castbar:CreateTexture(nil, 'OVERLAY')
	spark:SetBlendMode('ADD')
	castbar.Spark = spark

	if style == 'target' then
		castbar:SetStatusBarTexture(UF.TEXTURE)
		registry.bars[castbar] = true
		castbar:SetSize(300, 24)
		castbar:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, 350)
		UF.CreateLayout(castbar, -1)
		spark:SetSize(28, 48)
		spark:SetPoint('CENTER', castbar:GetStatusBarTexture(), 'RIGHT')

		local text = UF.CreateText(castbar, UF.FONT_BIG, 12, 'LEFT', '')
		text:SetPoint('LEFT', 5, 0)
		text:SetPoint('RIGHT', -45, 0)
		castbar.Text = text

		local time = UF.CreateText(castbar, UF.FONT_BIG, 12, 'RIGHT', '')
		time:SetPoint('RIGHT', -5, 0)
		castbar.Time = time
	else
		local health = self.Health
		castbar:SetStatusBarTexture(UF.TEXTURE_STRIPED)
		castbar:SetAllPoints(health)
		castbar:SetFrameLevel(health:GetFrameLevel() + 1)
		spark:SetSize(24, 60)
		spark:SetPoint('CENTER', castbar:GetStatusBarTexture(), 'RIGHT')

		if withText then
			-- Parented to the castbar so it hides with it; placed under the frame.
			local text = UF.CreateText(castbar, UF.FONT_BIG, 12, 'RIGHT')
			text:SetPoint('TOPRIGHT', self, 'BOTTOMRIGHT', 0, -4)
			text:SetWidth(200)
			castbar.Text = text
		end
	end

	self.Castbar = castbar
	return castbar
end

---------------------------------------------------------------------------
-- Auras
---------------------------------------------------------------------------

local function PostCreateAuraButton(_, button)
	button.Icon:SetTexCoord(.07, .93, .07, .93)
	UF.CreateBorder(button, -1)

	if button.Count then
		button.Count:ClearAllPoints()
		button.Count:SetPoint('BOTTOMRIGHT', -1, 1)
		button.Count:SetFont(UF.FONT_BIG, 12, 'OUTLINE')
		RegisterText(button.Count, 12, 'OUTLINE')
	end

	if button.Time then
		button.Time:ClearAllPoints()
		button.Time:SetPoint('TOP', 0, -2)
		button.Time:SetFont(UF.FONT_BIG, 14, 'OUTLINE')
		RegisterText(button.Time, 14, 'OUTLINE')
		button.Time:SetTextColor(1, .82, 0)
		button.Time:SetShadowOffset(1, -1)
		button.Time:SetShadowColor(0, 0, 0, 1)
	end
end

-- options: filter, max, size, width, height, anchor, growthX, growthY, debuffBorder
function UF.CreateAuras(self, options)
	local auras = self:CreateAuras({
		initialAnchor = options.anchor,
		growthX = options.growthX,
		growthY = options.growthY,
		layoutLimit = options.width,
	})
	auras:SetSize(options.width, options.height or options.size)

	auras.size = options.size
	auras.elementSpacing = 6
	auras.lineSpacing = 6
	auras.showCount = true
	auras.showDuration = true
	auras.disableCooldown = true
	auras.showDebuffBorder = options.debuffBorder
	auras.PostCreateButton = PostCreateAuraButton
	auras:AddGroup(options.filter, { maxFrameCount = options.max })

	return auras
end

---------------------------------------------------------------------------
-- Frame basics
---------------------------------------------------------------------------

function UF.SetupFrame(self, width, height)
	self:RegisterForClicks('AnyUp')
	self:SetScript('OnEnter', UnitFrame_OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)
	self:SetSize(width, height)
	UF.CreateLayout(self)
	UF.CreateShadow(self)
end

-- A frame above the health bar for texts and icons.
function UF.CreateOverlay(self, anchor)
	local overlay = CreateFrame('Frame', nil, self)
	overlay:SetAllPoints(anchor or self.Health)
	overlay:SetFrameLevel((anchor or self.Health):GetFrameLevel() + 5)
	return overlay
end
