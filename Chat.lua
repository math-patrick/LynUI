local _, ns = ...

-- Lyn's compact chat lines ("+ [Item] x3.", "+ 250 Reputation Council.").
-- EllesmereUI already handles channel names, URLs and the chat frames
-- themselves; this only rewrites Blizzard's verbose loot/xp/rep/quest/
-- achievement/status lines and hides the spam Lyn hid. Message filters are
-- the sanctioned way to change chat text in Midnight.
--
-- Patterns are built from Blizzard's own format strings, so they work in
-- every client language. Each template refers to the format's arguments by
-- position (%1, %2, ...), not by where they appear in the sentence.
local RULES = {
	CHAT_MSG_LOOT = {
		{ 'LOOT_ITEM_SELF_MULTIPLE', '+ %1 x%2.' },
		{ 'LOOT_ITEM_SELF', '+ %1.' },
		{ 'LOOT_ITEM_PUSHED_SELF_MULTIPLE', '+ %1 x%2.' },
		{ 'LOOT_ITEM_PUSHED_SELF', '+ %1.' },
		{ 'LOOT_ITEM_CREATED_SELF_MULTIPLE', '+ %1 x%2.' },
		{ 'LOOT_ITEM_CREATED_SELF', '+ %1.' },
		{ 'LOOT_ITEM_BONUS_ROLL_SELF_MULTIPLE', '+ bonus %1 x%2.' },
		{ 'LOOT_ITEM_BONUS_ROLL_SELF', '+ bonus %1.' },
		{ 'LOOT_ITEM_MULTIPLE', '+ %2 x%3 for %1.' },
		{ 'LOOT_ITEM', '+ %2 for %1.' },
	},
	CHAT_MSG_CURRENCY = {
		{ 'CURRENCY_GAINED_MULTIPLE_BONUS', '+ %1 x%2.' },
		{ 'CURRENCY_GAINED_MULTIPLE', '+ %1 x%2.' },
		{ 'CURRENCY_GAINED', '+ %1.' },
	},
	CHAT_MSG_COMBAT_FACTION_CHANGE = {
		{ 'FACTION_STANDING_INCREASED', '+ %2 %1.' },
		{ 'FACTION_STANDING_DECREASED', '- %2 %1.' },
	},
	CHAT_MSG_COMBAT_XP_GAIN = {
		{ 'COMBATLOG_XPGAIN_FIRSTPERSON', '+ %2 xp from %1.' },
		{ 'COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED', '+ %1 xp.' },
	},
	CHAT_MSG_SKILL = {
		{ 'SKILL_RANK_UP', '%1 lvl %2.' },
	},
	CHAT_MSG_SYSTEM = {
		{ 'ERR_QUEST_ACCEPTED_S', '|cfff86256+ Quest:|r %1' },
		{ 'ERR_QUEST_COMPLETE_S', '|cfff86256- Quest:|r %1' },
		{ 'ERR_FRIEND_ONLINE_SS', '|Hplayer:%1|h%2|h has come |cff20ff20online|r.' },
		{ 'ERR_FRIEND_OFFLINE_S', '%1 has gone |cffff2020offline|r.' },
		{ 'ERR_RAID_MEMBER_ADDED_S', '+ Raider |cffff7d00%1|r.' },
		{ 'ERR_RAID_MEMBER_REMOVED_S', '- Raider |cffff7d00%1|r.' },
		{ 'ERR_ZONE_EXPLORED_XP', '+ %2 xp, found %1.' },
		{ 'NEW_TITLE_EARNED', '+ Title %1.' },
		{ 'MARKED_AFK_MESSAGE', '+ AFK.' },
		{ 'MARKED_AFK', '+ AFK.' },
		{ 'CLEARED_AFK', '- AFK.' },
		{ 'MARKED_DND', '+ DND.' },
		{ 'CLEARED_DND', '- DND.' },
	},
	CHAT_MSG_ACHIEVEMENT = {
		{ 'ACHIEVEMENT_BROADCAST', '%1 achieved %2.' },
	},
	CHAT_MSG_GUILD_ACHIEVEMENT = {
		{ 'ACHIEVEMENT_BROADCAST', '%1 achieved %2.' },
	},
}

-- Lines Lyn hid entirely: other players' AFK auto-replies and channel join spam.
local SUPPRESS = { 'CHAT_MSG_AFK', 'CHAT_MSG_CHANNEL_JOIN' }

-- Turns a format string such as "%s receives loot: %sx%d." into an anchored
-- Lua pattern plus the argument index of each capture. Formats using
-- anything other than %s/%d (floats, plural codes) are skipped.
local function CompileFormat(format)
	if format:find('|4') then return end

	local pattern, order = { '^' }, {}
	local pos, nextArg = 1, 1
	while pos <= #format do
		local positional, posType = format:match('^%%(%d)%$([sd])', pos)
		local plainType = not positional and format:match('^%%([sd])', pos)
		local char = format:sub(pos, pos)

		if positional or plainType then
			local specType = posType or plainType
			pattern[#pattern + 1] = specType == 'd' and '([%d%.,]+)' or '(.-)'
			order[#order + 1] = positional and tonumber(positional) or nextArg
			nextArg = nextArg + 1
			pos = pos + (positional and 4 or 2)
		elseif format:sub(pos, pos + 1) == '%%' then
			pattern[#pattern + 1] = '%%'
			pos = pos + 2
		elseif char == '%' then
			return
		else
			pattern[#pattern + 1] = char:find('[%^%$%(%)%.%[%]%*%+%-%?]') and ('%' .. char) or char
			pos = pos + 1
		end
	end
	pattern[#pattern + 1] = '$'
	return table.concat(pattern), order
end

local function Rewrite(rules, message)
	for _, rule in ipairs(rules) do
		local captures = { message:match(rule.pattern) }
		if captures[1] then
			local args = {}
			for i, argIndex in ipairs(rule.order) do
				args[argIndex] = captures[i]
			end
			return (rule.template:gsub('%%(%d)', function(n) return args[tonumber(n)] or '' end))
		end
	end
end

local function Suppress()
	return ns.db.hideChatSpam
end

-- Filters stay registered and read their setting per message, so the
-- options can be flipped without a reload.
ns:RegisterModule(nil, function()
	for _, event in ipairs(SUPPRESS) do
		ChatFrame_AddMessageEventFilter(event, Suppress)
	end

	for event, list in pairs(RULES) do
		local compiled = {}
		for _, entry in ipairs(list) do
			local format = _G[entry[1]]
			local pattern, order
			if type(format) == 'string' then
				pattern, order = CompileFormat(format)
			end
			if pattern then
				compiled[#compiled + 1] = { pattern = pattern, order = order, template = entry[2] }
			end
		end

		if #compiled > 0 then
			ChatFrame_AddMessageEventFilter(event, function(_, _, message, ...)
				if not ns.db.compactChat then return false end
				-- Secret (restricted) messages can't be inspected; pass them through.
				if type(message) ~= 'string' or ns.IsSecret(message) then return false end
				local rewritten = Rewrite(compiled, message)
				if rewritten then
					return false, rewritten, ...
				end
				return false
			end)
		end
	end
end)
