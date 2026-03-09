local f = CreateFrame("Frame", nil, UIParent)

f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

f:SetScript("OnEvent", function(self, event, ...)
	local _, subEvent, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellID, spellName, spellSchool = ...
	
	if subEvent == "SPELL_CREATE" then
		local chatType = "YELL"
	
		if GetNumRaidMembers() > 0 then
			for i=1,40 do
				if UnitExists("raid"..i) and UnitGUID("raid"..i) == srcGUID then
					chatType = "RAID"
					break
				end
			end
		elseif GetNumPartyMembers() > 0 then
			for i=1,4 do
				if UnitExists("party"..i) and UnitGUID("party"..i) == srcGUID then
					chatType = "PARTY"
					break
				end
			end
		end
	
		if spellID == 57397 then
			local link = GetSpellLink(57397)
			SendChatMessage(srcName.." dropped a "..link..".  Eat up!", chatType)
		end
	end
end)
