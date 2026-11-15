local Astrolabe = DongleStub("Astrolabe-0.4")

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

		self.icon:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText("Fish Feast")
			GameTooltip:AddLine(("Time remaining: %ds"):format(math.max(0, self.expiration - GetTime())))
			GameTooltip:Show()
		end)

		self.icon:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		self.icon:SetScript("OnShow", function(self)
			self:SetScript("OnUpdate", function(self, elapsed)
				if GetTime() < self.expiration then return end

				self:Hide()

				local message = ("%s's %s has expired."):format(self.srcName or "Unknown", self.link or "Unknown")

				if InCombatLockdown() then
					print(message)
				else
					SendChatMessage(message, chatType)
				end
			end)
		end)

		self.icon:SetScript("OnHide", function(self)
			Astrolabe:RemoveIconFromMinimap(self)
			self:SetScript("OnUpdate", nil)
		end)

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
		for b=1,40,1 do
			local name, _, _, _, _, _, _, _, _, spellID = UnitBuff(unit, b)
			if not name then break end

			if table.contains(self.feastSpellIDs, spellID) or name == "Well Fed" then
				return true
			end
		end

		return false
	end,
	GetSourceUnit = function(self, guid)
		if UnitGUID("player") == guid then return "player" end

		local prefix, count

		if GetNumRaidMembers() > 0 then
			prefix = "raid"
			count = GetNumRaidMembers()
		elseif GetNumPartyMembers() > 0 then
			prefix = "party"
			count = GetNumPartyMembers()
		else
			return nil
		end

		for i=1,count do
			local unit = prefix..i

			if UnitGUID(unit) == guid then return unit end
		end

		return nil
	end,
	--[[
	PlaceIconOnMinimap = function(self, frame, mapID, mapFloor, x, y)
		local library = Astrolabe

		if not library and DongleStub then library = DongleStub("Astrolabe-0.4") end

		return library:PlaceIconOnMinimap(frame, mapID, mapFloor, x, y)
	end,
	RemoveIconFromMinimap(self, frame)
		local library = Astrolabe

		if not library and DongleStub then library = DongleStub("Astrolabe-0.4") end

		return library:RemoveIconFromMinimap(frame)
	end,
	]]
	GetUnitPosition = function(self, unit)
		local mapID, mapFloor, x, y

		local library = Astrolabe

		if not library and DongleStub then library = DongleStub("Astrolabe-0.4") end


		if library and library.GetUnitPosition then
			mapID, mapFloor, x, y = library:GetUnitPosition(unit)
		else
			x, y = GetPlayerMapPosition(unit)
			mapID = GetCurrentMapAreaID()
		end

		return mapID, mapFloor, x, y
	end,
	AnnounceFeastLocation = function(self, guid, spellID)
		local unit = self:GetSourceUnit(guid)
		if not unit then return false end

		local mapID, mapFloor, x, y = self:GetUnitPosition(unit)

		if not mapID or not x or not y then return false end

		local chatType = self:GetChatType()
		local msg = "%s dropped a %s at [%.1f, %.1f]. Eat up!"
		--local link = GetSpellLink(57397) or GetSpellLink(57426) or "Fish Feast"
		local link = GetSpellLink(spellID) or "Feast"

		local name = select(6, GetPlayerInfoByGUID(guid))

		if InCombatLockdown() then
			print(msg:format(name or "Unknown", link or "Unknown", x*100 or "?", y*100 or "?"))
		else
			SendChatMessage(msg:format(name, link, x*100, y*100), chatType)
		end
	end,
	PlaceFeastMarker = function(self, guid)
		local unit = self:GetSourceUnit(guid)
		if not unit then return false end

		local mapID, mapFloor, x, y = self:GetUnitPosition(unit)

		if not mapID or not x or not y then return flase end

		self.icon:ClearAllPoints()
		local result = Astrolabe:PlaceIconOnMinimap(self.icon, mapID, mapFloor, x, y)

		return result == 0
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
		local chatType = self:GetChatType()

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
				self:SendList("Missing Feast: ", unbuffed, chatType)
			else
				SendChatMessage("All group members are well fed.", chatType)
			end
		end
	end,
	COMBAT_LOG_EVENT_UNFILTERED = function(self, timestamp, event, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellID, spellName, spellSchool)
		--if event ~= "SPELL_CREATE" and not ( spellID == 57426 or dstName == "Fish Feast" ) then return end
		--if event ~= "SPELL_CREATE" and not ( table.contains(self.feastSpellIDs, spellID) or dstName == "Fish Feast" or dstName == "Great Feast" ) then return end

		if event == "SPELL_CREATE" and ( dstName == "Fish Feast" or dstName == "Great Feast" or table.contains(self.feastSpellIDs, spellID) ) then
			self:AnnounceFeastLocation(srcGUID, spellID)

			if self:PlaceFeastMarker(srcGUID) then
				self.icon.expiration = GetTime() + 180
				self.icon.srcName = srcName
				self.icon.link = link

				self.icon:Show()			
			else
				self.icon:Hide()
			end
		end
	end
}

SteakFeastAnnounce:Init()
