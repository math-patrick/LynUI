local _, ns = ...
local oUF = ns.oUF

-- Lyn's power colors
for token, rgb in next, {
	MANA = { .37, .6, 1 },
	RAGE = { .9, .3, .23 },
	FOCUS = { 1, .81, .27 },
	RUNIC_POWER = { 0, .81, 1 },
} do
	local color = oUF.colors.power[token]
	if color then color:SetRGB(unpack(rgb)) end
end

local Methods, Events = oUF.Tags.Methods, oUF.Tags.Events

-- "Lady Bloodfang Construct" -> "L. B. CONSTRUCT". Names can be secret in
-- restricted content; those are shown as they come.
Methods['lyn:name'] = function(unit)
	local name = UnitName(unit)
	if not name or issecretvalue(name) then return name end
	return (name:upper():gsub('(%w)[^%s]+%s', '%1. '))
end
Events['lyn:name'] = 'UNIT_NAME_UPDATE'

Methods['lyn:pvp'] = function(unit)
	if UnitIsPVP(unit) or UnitIsPVPFreeForAll(unit) then
		return '|cff50bb33PVP|r'
	end
end
Events['lyn:pvp'] = 'UNIT_FACTION'

local CLASSIFICATION = {
	rare = '|cfff6c6f9RARE|r',
	rareelite = '|cfff6c6f9RARE+|r',
	elite = '|cff41c2b3ELITE|r',
	worldboss = '|cff9af5deBOSS|r',
}
Methods['lyn:classification'] = function(unit)
	return CLASSIFICATION[UnitClassification(unit)]
end
Events['lyn:classification'] = 'UNIT_CLASSIFICATION_CHANGED'

-- Color prefix for names (target of target).
Methods['lyn:color'] = function(unit)
	if not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit) then
		return '|cffa0a0a0'
	end
	local colors = _COLORS
	if not UnitPlayerControlled(unit) and UnitIsTapDenied(unit) then
		return colors.tapped:GenerateHexColorMarkup()
	end
	if UnitIsPlayer(unit) or unit == 'pet' then
		local _, class = UnitClass(unit)
		if class and not issecretvalue(class) and colors.class[class] then
			return colors.class[class]:GenerateHexColorMarkup()
		end
	end
	local reaction = UnitReaction(unit, 'player')
	if reaction and not issecretvalue(reaction) and colors.reaction[reaction] then
		return colors.reaction[reaction]:GenerateHexColorMarkup()
	end
	return '|cffffffff'
end
Events['lyn:color'] = 'UNIT_NAME_UPDATE UNIT_FACTION UNIT_CONNECTION UNIT_HEALTH'
