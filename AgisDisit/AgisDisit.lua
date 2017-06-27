
-----------------------------------------------------------------------------------
local ADDONNAME, THIS = ...;
-----------------------------------------------------------------------------------

-- localize

local GetContainerNumSlots, GetContainerItemInfo, GetItemInfo = GetContainerNumSlots, GetContainerItemInfo, GetItemInfo
local print, tonumber, strmatch, strfind, strtrim = print, tonumber, strmatch, strfind, strtrim
local HasAction, GetActionInfo = HasAction, GetActionInfo
local GetMacroBody, GetMacroInfo, EditMacro = GetMacroBody, GetMacroInfo, EditMacro
local CloseLoot = CloseLoot
local IsFlying, IsFalling = IsFlying, IsFalling
local UnitAffectingCombat, UnitCastingInfo, UnitIsDead = UnitAffectingCombat, UnitCastingInfo, UnitIsDead

-- variables

local CloseNextLoot = false
local SpellNameDE = GetSpellInfo(13262)
local failedItems = {}
local dissingItemID = nil

-----------------------------------------------------------------------------------

local function findItemID()
    local i, j, _, locked, itemLink, itemName, itemRarity, itemLevel, equipLoc, sellPrice, itemID
    for i=0,4 do
        for j=1,GetContainerNumSlots(i) do
            _, _, locked, _, _, _, itemLink = GetContainerItemInfo(i, j)
            if ( itemLink ) then
                itemName, itemLink, itemRarity, itemLevel, _, _, _, _, equipLoc, _, sellPrice = GetItemInfo(itemLink)
                if ( itemRarity == 2 or itemRarity == 3 ) then
                    if ( equipLoc ~= "" and sellPrice > 0 ) then
                        itemID, _ = strmatch(itemLink, "item%:(%d+)%:.+%[(.-)%]")
                        itemID = itemID + 0
                        if ( not failedItems[itemID] ) then
                            return itemID
                        end
                    end
                end
            end
        end
    end
    return nil
end

-----------------------------------------------------------------------------------

local function findSlotInfo(text)
	local slotID, slotType, macroID;
	for slotID=1,120 do
        if ( HasAction(slotID) ) then
            slotType, macroID = GetActionInfo(slotID)
            if ( slotType == "macro" ) then
                if ( strfind(GetMacroBody(macroID), text) ) then
                    return macroID, slotID, ceil(slotID/12), slotID % 12
                end
            end
        end
    end
    return nil
end

-----------------------------------------------------------------------------------

-----------------------------------------------------------------------------------
local EventHandlers = {}
-----------------------------------------------------------------------------------

function EventHandlers:UNIT_SPELLCAST_FAILED(unitID, spell)
    if ( unitID == "player" and spell == SpellNameDE ) then
        failedItems[dissingItemID] = 1
        dissingItemID = nil
    end
end






function EventHandlers:UNIT_SPELLCAST_SUCCEEDED(unitID, spell)
    if ( unitID == "player" and spell == SpellNameDE ) then
        CloseNextLoot = true
        dissingItemID = nil
    end
end

function EventHandlers:LOOT_OPENED(auto)
    if ( CloseNextLoot ) then
        CloseNextLoot = false
        CloseLoot()
    end
end

--function EventHandlers:UNIT_SPELLCAST_INTERRUPTED(unitID, spell)
--    if ( unitID == "player" and spell == SpellNameDE ) then
--    end
--end

-----------------------------------------------------------------------------------

local EventFrame = CreateFrame("FRAME");
function EventFrame:OnEvent(event, ...)
    EventHandlers[event](self, ...)
end
EventFrame:SetScript("OnEvent", EventFrame.OnEvent);
for event,v in pairs(EventHandlers) do
    EventFrame:RegisterEvent(event);
end

-----------------------------------------------------------------------------------

-----------------------------------------------------------------------------------

SLASH_AGIDISIT1 = "/disit";
SlashCmdList["AGIDISIT"] = function()

    local macroID = findSlotInfo("/disit")
    if ( macroID == nil ) then
        print("cannot find action slot")
        return
    end

    local macroName, macroIcon, macroBody, macroLocal = GetMacroInfo(macroID)
    macroBody = strtrim(strmatch(macroBody, "(.+/disit).*"))

    if ( IsFlying() or IsFalling() or UnitAffectingCombat("player") or UnitCastingInfo("player") or UnitIsDead("player") ) then
        print("Cant disit right now")
    else
        dissingItemID = findItemID()
        if ( dissingItemID ) then
            macroBody = macroBody .. "\n/use " .. SpellNameDE .. "\n/use item:" .. dissingItemID .. "\n/dised " .. macroID
            local itemName, itemLink = GetItemInfo(dissingItemID)
            print("DISENCHANTING "..itemLink)
        else
            print("no items found for disenchanting")
        end
    end

    EditMacro(macroID, macroName, macroIcon, macroBody, macroLocal)

end

-----------------------------------------------------------------------------------

SLASH_AGIDISED1 = "/dised";
SlashCmdList["AGIDISED"] = function(macroID)
    macroID = tonumber(macroID)
    local macroName, macroIcon, macroBody, macroLocal = GetMacroInfo(macroID)
    macroBody = strtrim(strmatch(macroBody, "(.*/disit).*"))
    EditMacro(macroID, macroName, macroIcon, macroBody, macroLocal)
end

-----------------------------------------------------------------------------------
