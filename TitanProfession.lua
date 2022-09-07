--[[
	Description: Titan Panel plugin that shows your Profession level
	Author: Eliote
	This addon was created and developed after Canettieri's "Titan Panel [Professions] Multi".
--]]

local ADDON_NAME, L = ...;
local VERSION = GetAddOnMetadata(ADDON_NAME, "Version")

local Elib = LibStub("Elib-4.0")

local PROFESSION_LEVEL_LIMIT = 800
local PANDAREM_LIMIT = 600
local TitanProfession = LibStub("AceAddon-3.0"):NewAddon("TitanProfessionClassic", "AceEvent-3.0")

local Elib = LibStub("Elib-4.0")
---@type LibAddonCompat
local LAC = LibStub("LibAddonCompat-1.0")

local PROFESSION_LEVEL_LIMIT = 375

local Color = {}
Color.WHITE = "|cFFFFFFFF"
Color.RED = "|cFFDC2924"
Color.YELLOW = "|cFFFFF244"
Color.GREEN = "|cFF3DDC53"

local function CanLevelUp(profLvl, profMaxLvl)
	if profMaxLvl == 0 then return end
	if profMaxLvl == PROFESSION_LEVEL_LIMIT then return end

	if profLvl > (profMaxLvl - 25) then return true end
end

local function GetProfLvlColor(profLvl, profMaxLvl)
	if CanLevelUp(profLvl, profMaxLvl) then
		if profLvl == profMaxLvl then
			return Color.RED
		else
			return Color.YELLOW
		end
	end

	return Color.WHITE
end

local menus = {
	{ type = "toggle", text = L["ShowMax"], var = "ShowMax", def = true },
	{ type = "toggle", text = L["HideNotLearned"], var = "HideNotLearned", def = true },
	{ type = "rightSideToggle" }
}

local function TitanProf(titanId, profIndex, castSkill, defaultDesc, noProfHint)
	local ID = titanId

	local profName = defaultDesc
	local profIcon = ""
	local profLevel = 0
	local profMaxLevel = 0
	local profBonus = 0
	local profOffset

	local startLevel

	local isPrimary = profIndex <= 2

	local learn = false

	local function SetVars(name, icon, level, maxLevel, offset, bonus)
		learn = name and true

		if (startLevel == nil) then
			startLevel = level
		end

		profOffset = offset
		profIcon = icon or "Interface\\Icons\\INV_Misc_QuestionMark"
		profName = name or defaultDesc
		profLevel = level or 0
		profMaxLevel = maxLevel or 0
		profBonus = bonus or 0

		TitanPlugins[ID].icon = profIcon
		TitanPlugins[ID].tooltipTitle = profName

		if profMaxLevel > 0 then
			if isPrimary then
				TitanPlugins[ID].menuText = defaultDesc .. " [" .. Color.GREEN .. profName .. "|r]"
			else
				TitanPlugins[ID].menuText = defaultDesc .. "|r"
			end
		else
			TitanPlugins[ID].menuText = defaultDesc .. " [" .. Color.RED .. L["noprof"] .. "|r]"
		end

		TitanPanelButton_UpdateButton(ID)
	end

	local function ReloadProf()
		-- ignore while TitanPlugins is not registered
		if (TitanPlugins == nil) then return end

		local prof = select(profIndex, LAC:GetProfessions())
		if not prof then return SetVars() end

		local name, icon, level, maxLevel, _, offset, _, skillModifier = LAC:GetProfessionInfo(prof)
		SetVars(name, icon, level, maxLevel, offset, skillModifier)
	end

	local function CreateToolTip()
		GameTooltip:SetText(profName, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);

		if profMaxLevel > 0 then
			if CanLevelUp(profLevel, profMaxLevel) then
				GameTooltip:AddLine("|cFFFFFFFF" .. L["goTrainerHint"], nil, nil, nil, true);
			end

			if castSkill then
				GameTooltip:AddLine("|cFFFFFFFF" .. L["tooltipHint"], nil, nil, nil, true);
			end

			GameTooltip:AddLine(" ");

			local bonusText = ""
			if (profBonus and profBonus > 0) then
				bonusText = Color.GREEN .. "+" .. profBonus .. "|r(" .. Color.GREEN .. profBonus + profLevel .. "|r)"
			end

			GameTooltip:AddDoubleLine(L["tooltipLevel"], GetProfLvlColor(profLevel, profMaxLevel) .. profLevel .. bonusText);
			GameTooltip:AddDoubleLine(L["tooltipMaxLevel"], Color.WHITE .. profMaxLevel);

			local dif = profLevel - startLevel
			if dif > 0 then
				GameTooltip:AddDoubleLine(L["thisSession"], Color.GREEN .. dif);
			end
		else
			GameTooltip:AddLine(noProfHint, nil, nil, nil, true);
		end
	end

	local function GetButtonText(self, id)
		if TitanGetVar(id, "HideNotLearned") and not learn then return end

		if profMaxLevel == 0 then
			return profName .. ": ", Color.RED .. defaultDesc
		end

		local bonusText1 = ""

		if profBonus and profBonus > 0 then
			bonusText1 = Color.GREEN .. "+" .. profBonus .. "|r(" .. Color.GREEN .. (profLevel + profBonus) .. "|r)"
		end

		local maxText = (TitanGetVar(id, "ShowMax") and ("|r/" .. Color.RED .. profMaxLevel)) or ""

		local session = ""
		local dif = profLevel - startLevel
		if dif > 0 then
			session = Color.GREEN .. " [" .. dif .. Color.GREEN .. "]"
		end

		return profName .. ": ", GetProfLvlColor(profLevel, profMaxLevel) .. profLevel .. bonusText1 .. maxText .. session .. "|r"
	end

	local function OnClick(self, button)
		if (button == "LeftButton") then
			if profOffset and castSkill then
				CastSpell(profOffset + castSkill, "Spell")
			end
		end
	end

	Elib.Register({
		id = ID,
		name = defaultDesc .. "|r",
		tooltip = L["noprof"],
		icon = "Interface\\Icons\\INV_Misc_QuestionMark",
		category = "Profession",
		version = VERSION,
		getButtonText = GetButtonText,
		onClick = OnClick,
		onUpdate = ReloadProf,
		customTooltip = CreateToolTip,
		menus = menus
	})
end

function TitanProfession:OnInitialize()
	TitanProf("TITAN_PROF_1", LAC.PROFESSION_FIRST_INDEX, 1, PROFESSIONS_FIRST_PROFESSION, PROFESSIONS_MISSING_PROFESSION) -- prof1
	TitanProf("TITAN_PROF_2", LAC.PROFESSION_SECOND_INDEX, 1, PROFESSIONS_SECOND_PROFESSION, PROFESSIONS_MISSING_PROFESSION) -- prof2
	TitanProf("TITAN_PROF_3", LAC.PROFESSIONS_ARCHAEOLOGY, 1, PROFESSIONS_ARCHAEOLOGY, PROFESSIONS_ARCHAEOLOGY_MISSING) -- first aid
	TitanProf("TITAN_PROF_4", LAC.PROFESSION_FISHING_INDEX, 1, PROFESSIONS_FISHING, PROFESSIONS_FISHING_MISSING) -- fishing
	TitanProf("TITAN_PROF_5", LAC.PROFESSION_COOKING_INDEX, 1, PROFESSIONS_COOKING, PROFESSIONS_COOKING_MISSING) -- cooking
	TitanProf("TITAN_PROF_6", LAC.PROFESSION_FIRST_AID_INDEX, 1, PROFESSIONS_FIRST_AID, PROFESSIONS_FIRST_AID_MISSING or PROFESSIONS_FIRST_AID) -- first aid
end