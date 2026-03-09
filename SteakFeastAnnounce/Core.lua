local f = CreateFrame("Frame", nil, UIParent)

f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
f:RegisterEvent("READY_CHECK")

local function HasFeast(unit)
	local isWellFed = false

	local b = 1
	while true do
		local name, _, _, _, _, _, _, _, _, spellID = UnitBuff(unit, i)
		if not name then break end

		if spellID == 57397 then
			isWellFed = true
			break
		end

		b = b + 1
	end

	return isWellFed
end

f:SetScript("OnEvent", function(self, event, ...)
	local _, subEvent, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellID, spellName, spellSchool = ...

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
	
	
	if subEvent == "SPELL_CREATE" then
		if spellID == 57426 or destName == "Fish Feast" then
			local link = GetSpellLink(57397) or GetSpellLink(57426)
			if link then
				SendChatMessage(srcName.." dropped a "..link..".  Eat up!", chatType)
			else
				SendChatMessage(srcName.." dropped a Fish Feast.  Eat up!", chatType)
			end
		end
	elseif subEvent == "READY_CHECK" then
		local prefix = GetNumRaidMembers() > 0 and "raid" or "party"
		local numMembers = prefix == "raid" and GetNumRaidMembers() or GetNumPartyMembers()
		local unbuffed = {}

		for i=1,numMembers do
			local unit = prefix..i

			local unitLink = string.format("|Hplayer:%s|h[%s]|h", UnitName(unit), UnitName(unit))
			if not HasFeast(unit) then table.insert(unbuffed, unitLink) end
		end

		local playerLink = string.format("|Hplayer:%s|h[%s]|h", UnitName("player"), UnitName("player"))
		if prefix == "party" and not HasFeast("player") then table.insert(unbuffed, playerLink) end

		if #unbuffed == 0 then
			SendChatMessage("All group members are well fed.", chatType)
		else
			SendChatMessage("Missing Feast: "..table.concat(unbuffed, ", ")
		end
	end
end)
