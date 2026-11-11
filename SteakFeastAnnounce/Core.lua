SteakFeastAnnounce = {
	feastSpellIDs = {57397, 57399, 57398},
	frame = CreateFrame("Frame", nil, UIParent),
	icon = CreateFrame("Button", "FeastMarker", Minimap),
	events = {
		"COMBAT_LOG_EVENT_UNFILTERED",
		"READY_CHECK"
	},
	Init = function(self)
		if self.initialized then return end
		self.initialized = true

		local texture = self.icon:CreateTexture(nil, "BACKGROUND")
		texture:SetAllPoints(self.icon)
		self.icon:SetSize(12, 12)
		texture:SetTexture("Interface\\Icons\\inv_misc_fish_52")

		self.icon:Hide()

		for _, event in ipairs(self.events) do
			self.frame:RegisterEvent(event)
		end

		self.frame:SetScript("OnEvent", function(_, event, ...)
			if self[event] then
				self[event](self, ...)
			end
		end)
	end,
	SendList = function(self, prefix, list, chatType)
		local max = 245
		local msg = prefix
		local first = true

		for _, name in ipairs(list) do
			local add = first and name or (", "..name)
			first = false

			if #msg + #add >= max then
				SendChatMessage(msg, chatType)
				msg = prefix..name
			else
				msg = msg..add
			end
		end
	end,
	HasFeast = function(self, unit)
		local b = 1

		while true do
			local name, _, _, _, _, _, _, _, _, spellID = UnitBuff(unit, b)
			if not name then break end

			if table.contains(self.feastSpellIDs, spellID) or name == "Well Fed" then
				return true
			end
		end

		return false
	end,
	GetUnitLink = function(self, unit)
		local name = UnitName(unit)
		local _, class = UnitClass(unit)
		local r, g, b = RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b

		return ("|cff%02x%02x%02x|Hplayer:%s|h[%s]|h|r"):format(r*255, g*255, b*255, name, name)
	end,
	GetColoredName = function(self, unit)
		local name = UnitName(unit)
		local _, class = UnitClass(unit)
		local r, g, b = RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b

		return ("|cff%02x%02x%02x%s|r"):format(r*255, g*255, b*255, name)
	end,
	GetChatType = function(self)
		local chatType = "YELL"

		if GetNumRaidMembers() > 0 then
			if UnitIsRaidOfficer("player") or UnitIsPartyLeader("player") then
				chatType = "RAID_WARNING"
			else
				chatType = "RAID"
			end
		elseif GetNumPartyMembers() > 0 then
			chatType = "PARTY"
		end

		return chatType
	end,
	READY_CHECK = function(self)
		local prefix = GetNumRaidMembers() > 0 and "raid" or "party"
		local numMembers = prefix == "raid" and GetNumRaidMembers() or GetNumPartyMembers()
		local unbuffed = {}
		local members = {}

		for i=1,numMembers do
			local unit = prefix..i
			local unitLink = self:GetColoredName(unit)

			if not self:HasFeast(unit) then table.insert(unbuffed, unitLink) end
		end

		--local playerLink = GetUnitLink("player")
		local playerLink = UnitName("player")

		if prefix == "party" and not self:HasFeast("player") then table.insert(unbuffed, playerLink) end

		if InCombatLockdown() then
			if #unbuffed > 0 then
				print(("Missing Feast: %s"):format(table.concat(unbuffed, ", ")))
			else
				print("All group members are well fed.")
			end
		else
			if #unbuffed > 0 then
				SendList("Missing Feast: ", unbuffed, chatType)
			else
				SendChatMessage("All group members are well fed.", chatType)
			end
		end
	end,
	COMBAT_LOG_EVENT_UNFILTERED = function(self, timestamp, event, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellID, spellName, spellSchool)
		if event ~= "SPELL_CREATE" and not ( spellID == 57426 or destName == "Fish Feast" ) then return end

		local chatType = self:GetChatType()
		local x, y = 0, 0

		if GetNumRaidMembers() > 0 then
			for i=1,40 do
				if UnitExists("raid"..i) and UnitGUID("raid"..i) == srcGUID then
					x, y = GetPlayerMapPosition("raid"..i)
					break
				end
			end
		elseif GetNumPartyMembers() > 0 then
			for i=1,4 do
				if UnitExists("party"..i) and UnitGUID("party"..i) == srcGUID then
					x, y = GetPlayerMapPosition("party"..i)
					break
				end
			end
		end

		local msg = "%s dropped a %s at [%.01d, %.01d]. Eat up!"

		local link = GetSpellLink(57397) or GetSpellLink(57426) or "Fish Feast"

		if InCombatLockdown() then
			print(msg:format(srcName, link, x*100, y*100))
		else
			SendChatMessage(msg:format(srcName, link, x*100, y*100), chatType)
		end

		if x > 0 and y > 0 then
			local width = Minimmap:GetWidth() / 2
			local height = Minimap:GetHeight() / 2

			local angle = math.atan2(y - 0.5, x - 0.5)

			local radiusX = width * math.sqrt(2)
			local radiusY = height * math.sqrt(2)

			local offsetX = math.cos(angle) * radiusX * math.abs(x - 0.5)
			local offsetY = math.sin(angle) * radiusY * math.abs(x - 0.5)

			self.icon.expiration = GetTime() + 180
			self.icon.srcName = srcName
			self.icon.link = link

			self.icon:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText("Fish Feast")
				GameTooltip:AddLine(("Time remaining: %ds"):format(math.max(0, self.expiration - GetTime())))
				GameTooltip:Show()
			end)

			self.icon:SetScript("OnLeave", function()
				GameTooltip:Hide()
			end)

			self.icon:SetScript("OnUpdate", function(self, elapsed)
				if GetTime() < self.expiration then return end

				self:Hide()
				self:SetScript("OnUpdate", nil)

				local message = ("%s's %s has expired."):format(self.srcName, self.link)

				if InCombatLockdown() then
					print(message)
				else
					SendChatMessage(message, chatType)
				end
			end)

			self.icon:ClearAllPoints()
			self.icon:SetPoint("CENTER", Minimap, "CENTER", offsetX, offsetY)
			self.icon:Show()
		else
			self.icon:Hide()
		end
	end
}

SteakFeastAnnounce:Init()
