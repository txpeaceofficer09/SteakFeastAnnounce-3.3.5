local f = CreateFrame("Frame", nil, UIParent)

local function HasFeast(unit)
	local b = 1
	while true do
		local name, _, _, _, _, _, _, _, _, spellID = UnitBuff(unit, b)
		if not name then break end

		if spellID == 57397 or spellID == 57399 or spellID == 57398 or name == "Well Fed" then
			return true
		end

		b = b + 1
	end

	return false
end

local function GetUnitLink(unit)
		local name = UnitName(unit)
		local _, class = UnitClass(unit)
		local r, g, b = RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b

		return ("|cff%02x%02x%02x|Hplayer:%s|h[%s]|h|r"):format(r*255, g*255, b*255, name, name)
end

local function GetColoredName(unit)
		local name = UnitName(unit)
		local _, class = UnitClass(unit)
		local r, g, b = RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b

		return ("|cff%02x%02x%02x%s|r"):format(r*255, g*255, b*255, name)
end

local function OnEvent(self, event, timestamp, subEvent, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellID, spellName, spellSchool)
	local chatType = "YELL"
	local x, y = 0, 0

	if GetNumRaidMembers() > 0 then
		if UnitIsRaidOfficer("player") or UnitIsPartyLeader("player") then
			chatType = "RAID_WARNING"
		else
			chatType = "RAID"
		end

		for i=1,40 do
			if UnitExists("raid"..i) and UnitGUID("raid"..i) == srcGUID then
				x, y = GetPlayerMapPosition("raid"..i)
				break
			end
		end
	elseif GetNumPartyMembers() > 0 then
		chatType = "PARTY"

		for i=1,4 do
			if UnitExists("party"..i) and UnitGUID("party"..i) == srcGUID then
				x, y = GetPlayerMapPosition("party"..i)
				break
			end
		end
	end
	
	local msg = "%s dropped a %s at [%.01d, %.01d]. Eat up!"
	
	if subEvent == "SPELL_CREATE" then
		if spellID == 57426 or destName == "Fish Feast" then
			local link = GetSpellLink(57397) or GetSpellLink(57426) or "Fish Feast"

			if InCombatLockdown() then
				print(msg:format(srcName, link, x*100, y*100))
			else
				SendChatMessage(msg:format(srcName, link, x*100, y*100), chatType)
			end

			if IsAddOnLoaded("SteakMinimap") then
				if x > 0 and y > 0 then
					local icon = CreateFrame("Button", nil, MapFrameSC)
					icon:SetSize(12, 12)
					local tex = icon:CreateTexture(nil, "BACKGROUND")
					tex:SetAllPoints()
					tex:SetTexture("Interface\\Icons\\inv_misc_fish_52")
					icon:SetPoint("CENTER", MapFrameSC, "TOPLEFT", x*MapFrameSC:GetWidth(), -y*MapFrameSC:GetHeight())

					icon.expiration = GetTime() + 180
					icon.srcName = srcName
					icon.link = link

					icon:SetScript("OnEnter", function(self)
						GameTooltip:SetText("Fish Feast")
						GameTooltip:AddLine(("Time remaining: %ss"):format(self.expiration - GetTime()))
					end)

					icon:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
					
					icon:SetScript("OnUpdate", function(self, elapsed)
						self.timer = (self.timer or 0) + elapsed
						if self.timer < 180 then return end
						self.timer = 0
						self:Hide()
						self:SetScript("OnUpdate", nil)

						local message =	("%s's %s has expired."):format(srcName, link)

						if InCombatLockdown() then
							print(message)
						else
							SendChatMessage(message, chatType)
						end
					end)
				end
			end
		end
	elseif event == "READY_CHECK" then
		local prefix = GetNumRaidMembers() > 0 and "raid" or "party"
		local numMembers = prefix == "raid" and GetNumRaidMembers() or GetNumPartyMembers()
		local unbuffed = {}
		local members = {}

		for i=1,numMembers do
			local unit = prefix..i
			--local unitLink = GetUnitLink(unit)
			--local unitLink = UnitName(unit)
			local unitLink = GetColoredName(unit)
			
			if not HasFeast(unit) then table.insert(unbuffed, unitLink) end
		end

		--local playerLink = GetUnitLink("player")
		local playerLink = UnitName("player")
		
		if prefix == "party" and not HasFeast("player") then table.insert(unbuffed, playerLink) end

		local message = "All group members are well fed."

		if #unbuffed > 0 then
			message = ("Missing Feast: %s"):format(table.concat(unbuffed, ", "))
		end

		if InCombatLockdown() then
			print(message)
		else		
			SendChatMessage(message, chatType)
		end
	end
end

f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
f:RegisterEvent("READY_CHECK")

f:SetScript("OnEvent", OnEvent)
