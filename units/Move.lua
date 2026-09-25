local _, ns = ...

-- /lyn move: drag handles over the unit frames. Positions are saved per
-- account; /lyn resetframes puts everything back to Lyn's layout.
local LABELS = {
	player = 'Player', target = 'Target', focus = 'Focus', pet = 'Pet',
	boss = 'Boss', targetCastbar = 'Target Castbar',
}

local movers = {}
local unlocked = false

local function SavePosition(key, frame)
	local point, _, relativePoint, x, y = frame:GetPoint()
	ns.db.unitPositions[key] = { point, relativePoint, x, y }
end

local function CreateMover(key, frame)
	local mover = CreateFrame('Frame', nil, UIParent)
	mover:SetFrameStrata('DIALOG')
	mover:SetAllPoints(frame)
	mover:EnableMouse(true)
	mover:RegisterForDrag('LeftButton')

	local bg = mover:CreateTexture(nil, 'BACKGROUND')
	bg:SetAllPoints()
	bg:SetColorTexture(16/255, 197/255, 211/255, .35)

	local label = mover:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
	label:SetPoint('CENTER')
	label:SetText(LABELS[key] or key)

	mover:SetScript('OnDragStart', function()
		if InCombatLockdown() then return end
		frame:SetMovable(true)
		frame:StartMoving()
	end)
	mover:SetScript('OnDragStop', function()
		frame:StopMovingOrSizing()
		frame:SetUserPlaced(false) -- we save the position ourselves
		SavePosition(key, frame)
	end)

	return mover
end

function ns:ToggleMovers()
	if InCombatLockdown() then
		ns:Print('Can\'t move frames in combat.')
		return
	end
	if not next(ns.movableUnits or {}) then
		ns:Print('Lyn unit frames are disabled (/lyn frames).')
		return
	end

	unlocked = not unlocked
	for key, frame in next, ns.movableUnits do
		movers[key] = movers[key] or CreateMover(key, frame)
		movers[key]:SetShown(unlocked)
	end
	ns:Print(unlocked and 'Drag the frames, then type /lyn move again to lock them.' or 'Frames locked.')
end

-- Leaving the frames unlocked going into combat would leave dead handles.
local watcher = CreateFrame('Frame')
watcher:RegisterEvent('PLAYER_REGEN_DISABLED')
watcher:SetScript('OnEvent', function()
	if unlocked then
		unlocked = false
		for _, mover in next, movers do mover:Hide() end
	end
end)
