-- these, hopefully temporary, fixes are for tainting worldmap
-- by: lightspark

local oldResetZoom = WorldMapScrollFrame_ResetZoom
WorldMapScrollFrame_ResetZoom = function()
	if InCombatLockdown() then
		WorldMapFrame_Update()
		WorldMapScrollFrame_ReanchorQuestPOIs()
		WorldMapFrame_ResetPOIHitTranslations()
		WorldMapBlobFrame_DelayedUpdateBlobs()
	else
		oldResetZoom()
	end
end

if WorldMapFrame.UIElementsFrame.BountyBoard.GetDisplayLocation == WorldMapBountyBoardMixin.GetDisplayLocation then
	WorldMapFrame.UIElementsFrame.BountyBoard.GetDisplayLocation = function(frame)
		if InCombatLockdown() then
			return
		end

		return WorldMapBountyBoardMixin.GetDisplayLocation(frame)
	end
end

if WorldMapFrame.UIElementsFrame.ActionButton.GetDisplayLocation == WorldMapActionButtonMixin.GetDisplayLocation then
	WorldMapFrame.UIElementsFrame.ActionButton.GetDisplayLocation = function(frame, useAlternateLocation)
		if InCombatLockdown() then
			return
		end

		return WorldMapActionButtonMixin.GetDisplayLocation(frame, useAlternateLocation)
	end
end

if WorldMapFrame.UIElementsFrame.ActionButton.Refresh == WorldMapActionButtonMixin.Refresh then
	WorldMapFrame.UIElementsFrame.ActionButton.Refresh = function(frame)
		if InCombatLockdown() then
			return
		end

		WorldMapActionButtonMixin.Refresh(frame)
	end
end


-- http://www.wowinterface.com/forums/showpost.php?p=320422&postcount=8
--[[
local function FixFontShadow(obj)
    local x, y = obj:GetShadowOffset()
    if y > -2 and y < 0 then
        obj:SetShadowOffset(x, -3)
    end
end
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    f:UnregisterEvent("PLAYER_LOGIN")

    FixFontShadow(ChatFontNormal)
    FixFontShadow(NumberFont_Shadow_Med)
    FixFontShadow(AchievementFont_Small)
    FixFontShadow(NumberFont_OutlineThick_Mono_Small)
    FixFontShadow(NumberFont_Outline_Huge)
    FixFontShadow(NumberFont_Outline_Large)
    FixFontShadow(NumberFont_Outline_Med)
    FixFontShadow(NumberFont_Shadow_Small)
    FixFontShadow(SystemFont_InverseShadow_Small)
    FixFontShadow(SystemFont_Large)
    FixFontShadow(SystemFont_Med1)
    FixFontShadow(SystemFont_Med2)
    FixFontShadow(SystemFont_Med3)
    FixFontShadow(SystemFont_OutlineThick_Huge2)
    FixFontShadow(SystemFont_OutlineThick_Huge4)
    FixFontShadow(SystemFont_OutlineThick_WTF)
    FixFontShadow(SystemFont_Outline_Small)
    FixFontShadow(SystemFont_Shadow_Huge1)
    FixFontShadow(SystemFont_Shadow_Huge3)
    FixFontShadow(SystemFont_Shadow_Large)
    FixFontShadow(SystemFont_Shadow_Med1)
    FixFontShadow(SystemFont_Shadow_Med3)
    FixFontShadow(SystemFont_Shadow_Outline_Huge2)
    FixFontShadow(SystemFont_Shadow_Small)
    FixFontShadow(SystemFont_Small)
    FixFontShadow(SystemFont_Tiny)
    FixFontShadow(ReputationDetailFont)
    FixFontShadow(ItemTextFontNormal)
    FixFontShadow(DialogButtonNormalText)
    FixFontShadow(InvoiceTextFontNormal)
    FixFontShadow(InvoiceTextFontSmall)
    FixFontShadow(MailTextFontNormal)
    FixFontShadow(GameFontHighlightSmall)
    FixFontShadow(GameFontNormalSmall)
    FixFontShadow(GameFontNormalSmall2)
    FixFontShadow(GameFontDisableSmall)
    FixFontShadow(GameFontNormalHuge)
    FixFontShadow(GameFontNormalLarge)
    FixFontShadow(GameFontHighlight)
    FixFontShadow(GameFontDisable)
    FixFontShadow(GameFontNormal)
    FixFontShadow(GameFontBlackMedium)
    FixFontShadow(GameFontHighlightMedium)
    FixFontShadow(SubSpellFont)
    FixFontShadow(NumberFontNormalSmall)
    FixFontShadow(NumberFontNormal)
    FixFontShadow(NumberFontNormalLarge)
    FixFontShadow(NumberFontNormalHuge)
    FixFontShadow(WorldMapTextFont)
    FixFontShadow(MovieSubtitleFont)
    FixFontShadow(AchievementPointsFont)
    FixFontShadow(AchievementPointsFontSmall)
    FixFontShadow(AchievementDateFont)
    FixFontShadow(AchievementCriteriaFont)
    FixFontShadow(AchievementDescriptionFont)
    FixFontShadow(FriendsFont_Large)
    FixFontShadow(FriendsFont_Normal)
    FixFontShadow(FriendsFont_Small)
    FixFontShadow(FriendsFont_UserText)
    FixFontShadow(GameTooltipHeaderText)
    FixFontShadow(GameTooltipText)
    FixFontShadow(GameTooltipTextSmall)
    FixFontShadow(ZoneTextString)
    FixFontShadow(SubZoneTextString)
    FixFontShadow(PVPInfoTextString)
    FixFontShadow(PVPArenaTextString)
    FixFontShadow(CombatTextFont)
    FixFontShadow(BackpackTokenFrameToken1Count)
    FixFontShadow(BackpackTokenFrameToken2Count)
    FixFontShadow(BackpackTokenFrameToken3Count)
    FixFontShadow(QuestFontHighlight)
    FixFontShadow(QuestFontNormalSmall)
    FixFontShadow(QuestTitleFont)
    FixFontShadow(QuestFont)
    FixFontShadow(QuestFont_Large)
    FixFontShadow(QuestTitleFontBlackShadow)
    FixFontShadow(QuestFont_Super_Huge)
    FixFontShadow(HelpFrameKnowledgebaseNavBarHomeButtonText)
    FixFontShadow(GameFont_Gigantic)
    FixFontShadow(CoreAbilityFont)
    FixFontShadow(DestinyFontHuge)
    FixFontShadow(DestinyFontLarge)
    FixFontShadow(InvoiceFont_Small)
    FixFontShadow(InvoiceFont_Med)
    FixFontShadow(MailFont_Large)
    FixFontShadow(QuestFont_Shadow_Small)
    FixFontShadow(QuestFont_Shadow_Huge)
    FixFontShadow(QuestFont_Huge)
    FixFontShadow(QuestFont_Enormous)
    FixFontShadow(SpellFont_Small)
    FixFontShadow(SystemFont_Huge1)
    FixFontShadow(SystemFont_OutlineThick_WTF)
    FixFontShadow(SystemFont_OutlineThick_Huge2)
    FixFontShadow(SystemFont_OutlineThick_Huge4)
    FixFontShadow(SystemFont_Outline)
    FixFontShadow(SystemFont_Shadow_Large_Outline)
    FixFontShadow(SystemFont_Shadow_Large2)
    FixFontShadow(SystemFont_Shadow_Med2)
    FixFontShadow(SystemFont_Shadow_Huge2)
    FixFontShadow(SystemFont_Small2)
    FixFontShadow(Tooltip_Med)
    FixFontShadow(Tooltip_Small)
    -----
    FixFontShadow(GameFontNormalMed3)
    FixFontShadow(GameFontNormalHuge2)
    FixFontShadow(GameFontNormalLarge2)
    FixFontShadow(Game30Font)
    FixFontShadow(Game24Font)
    FixFontShadow(Game20Font)
    FixFontShadow(Game18Font)
    FixFontShadow(Fancy24Font) -- e.g. Weekly best @ ChallengesFrame
    FixFontShadow(Fancy16Font)
    FixFontShadow(Fancy48Font)
    FixFontShadow(Fancy22Font) -- e.g. TalkingHeadFrame TitleFont
    FixFontShadow(Fancy32Font)
    FixFontShadow(SystemFont_LargeNamePlate)
    FixFontShadow(SystemFont_NamePlate)
    FixFontShadow(SystemFont_LargeNamePlateFixed)
    FixFontShadow(SystemFont_NamePlateFixed)
    FixFontShadow(WhiteNormalNumberFont)    -- font shown at tradeskill skillbars
    FixFontShadow(PVPInfoTextFont)
    FixFontShadow(ChatFrame1EditBox)    -- chateditbox input text
    FixFontShadow(ChatFrame1EditBoxHeader)  -- chateditbox say/whisper/guild text
    FixFontShadow(GameTooltipHeader)    -- dungeon journal suggestion font

    f:SetScript("OnEvent", nil) -- not sure if this helps saving memory
    f = nil -- not sure if this helps saving memory
end)

-- some addon fontstrings need this
local proto = getmetatable(f:CreateFontString()).__index
hooksecurefunc(proto, "SetShadowOffset", function(self, x, y)
    if y > -2 and y < 0 then
        self:SetShadowOffset(x, -3)
    end
end)
hooksecurefunc(proto, "SetFontObject", function(self, ...)
    self:SetShadowOffset(self:GetShadowOffset())
end)
--]]
