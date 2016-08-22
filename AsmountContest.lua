--[[
	AsmountContest (C) Kruithne <kruithne@gmail.com>
	Licensed under GNU General Public Licence version 3.
	
	https://github.com/Kruithne/AsmountContest

	AsmountContest.lua - Core add-on core/functions.
--]]

AsmountContest = {};
local A = AsmountContest;
local K = Krutilities;

local eventFrame = CreateFrame("FRAME");
eventFrame:RegisterEvent("ADDON_LOADED");
eventFrame:SetScript("OnEvent", function(...) A.OnEvent(...); end);

A.OnEvent = function(self, event, ...)
	if event == "ADDON_LOADED" then
		local addonName = ...;
		if addonName == "Blizzard_Collections" or (addonName == "AsmountContest" and IsAddOnLoaded("Blizzard_Collections")) then
			A.LoadAddon();
		end
	end
end

A.OnButtonClick = function(self)
	A.OpenFrame();
end

A.OnFrameLoad = function(self)
	self:SetMovable(true);
	self:EnableMouse(true);
	self:RegisterForDrag("LeftButton");
end

A.OnFrameDragStart = function(self)
	self:StartMoving();
end

A.OnFrameDragStop = function(self)
	self:StopMovingOrSizing();
end

A.OnFrameUpdate = function(self, elapsed)
	if self.updateTime >= 2 then
		A.CheckMounts();
		self.updateTime = 0;
	else
		self.updateTime = self.updateTime + elapsed;
	end
end

A.OnTextButtonClick = function(self)
	UninviteUnit(self.player);
	A.CheckMounts();
end

A.LoadAddon = function()
	local button = K:Frame({
		type = "BUTTON",
		name = "AsmountContestButton",
		parent = "MountJournal",
		points = { point = "RIGHT", relativeTo = MountJournalSummonRandomFavoriteButtonSpellName, relativePoint = "LEFT" },
		size = 33,
		textures = {
			{ parentName = "IconTexture", layer = "ARTWORK", texture = [[Interface/ICONS/INV_Misc_Food_Draenor_GrilledGulper]] },
			{ parentName = "Border", layer = "OVERLAY", texture = [[Interface/Buttons/ActionBarFlyoutButton]], size = 35, subLevel = 1, texCoord = {0.01562500, 0.67187500, 0.39843750, 0.72656250} },
			{ texture = [[Interface/Buttons/UI-Quickslot-Depress]], buttonTex = "PUSHED" },
			{ parentName = "Highlight", texture = [[Interface/Buttons/ButtonHilight-Square]], blend = "ADD", buttonTex = "HIGHLIGHT" },
		},
		texts = {
			parentName = "Text", inherit = "GameFontNormal", maxLines = 2, justifyH = "RIGHT", text = "Mount Contest",
			size = {170, 0}, color = {1, 1, 1}, points = { point = "RIGHT", relativeTo = "$parentBorder", relativePoint = "LEFT", x = -2 }
		},
		scripts = { OnClick = A.OnButtonClick }
	});
end

A.CreateFrame = function()
	if A.Frame then return; end

	A.Frame = K:Frame({
		name = "AsmountContestFrame",
		size = {350, 100},
		backdrop = {
			edgeFile = [[Interface/DialogFrame/UI-DialogBox-Border]],
			edgeSize = 32, insets = { left = 10, right = 10, top = 10, bottom = 10 }
		},
		texts = { parentName = "OwnText", injectSelf = "ownText", text = "Mount: None", inherit = "GameFontNormal", points = { point = "TOP", y = -25 } },
		data = { updateTime = 0 },
		textures = {
			layer = "BACKGROUND",
			parentName = "Background",
			texture = [[Interface/Garrison/GarrisonMissionUIInfoBoxBackgroundTile]],
			tile = true,
			points = {
				{ point = "TOPLEFT", x = 10, y = -10 },
				{ point = "BOTTOMRIGHT", x = -10, y = 10 }
			}
		},
		frames = {
			type = "BUTTON",
			inherit = "UIPanelCloseButton",
			parentName = "CloseButton",
			points = { point = "TOPRIGHT", x = -6, y = -6 },
			scripts = { OnClick = function(self) self:GetParent():Hide(); end }
		},
		scripts = {
			OnLoad = A.OnFrameLoad,
			OnDragStart = A.OnFrameDragStart,
			OnDragStop = A.OnFrameDragStop,
			OnUpdate = A.OnFrameUpdate
		}
	});
end

A.CheckMounts = function()
	local currentMount = "NONE";
	local mountSpells = {};
	local hasMount = {};
	local mounts = C_MountJournal.GetMountIDs();

	mountSpells["NONE"] = "None";

	for i, mountID in ipairs(mounts) do
		local mountName, mountSpellID, _, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(mountID);
		mountSpells[mountSpellID] = mountName;

		if isCollected then
			hasMount[mountSpellID] = true;
		end
	end

	local buffIndex = 1;
	while true do
		local buffName, _, _, _, _, _, _, _, _, _, buffSpellID = UnitBuff("player", buffIndex);
		if buffName then
			if mountSpells[buffSpellID] then
				currentMount = buffSpellID;
				break;
			end
			buffIndex = buffIndex + 1;
		else
			break;
		end
	end

	A.Frame.ownText:SetText("Mount: " .. mountSpells[currentMount]);

	local frameIndex = 1;
	while true do
		local frame = _G["AsmountContestFrameText" .. frameIndex];
		if frame then
			frame:Hide();
			frame.button:Hide();
			frameIndex = frameIndex + 1;
		else
			break;
		end
	end

	if currentMount == "NONE" then
		A.Frame:SetHeight(100);
		return;
	end

	local previousFrame = nil;
	local height = 100;
	frameIndex = 1;

	local localName = UnitName("player");
	for raidIndex = 1, 40 do
		local raidID = "raid" .. raidIndex;
		local playerName = UnitName(raidID);
		if playerName and playerName ~= localName then
			local frameName = "AsmountContestFrameText" .. frameIndex;
			local frame = _G[frameName];
			local _, playerClass = UnitClass(raidID);

			local text = "|c" .. RAID_CLASS_COLORS[playerClass].colorStr .. playerName .. FONT_COLOR_CODE_CLOSE .. ": ";
			local mountText = RED_FONT_COLOR_CODE .. "Not mounted!";

			local raidBuffIndex = 1;
			while true do
				local buffName, _, _, _, _, _, _, _, _, _, buffSpellID = UnitBuff(raidID, raidBuffIndex);

				if buffName then
					if mountSpells[buffSpellID] then
						if buffSpellID == currentMount then
							mountText = GREEN_FONT_COLOR_CODE .. buffName;
						else
							if hasMount[buffSpellID] then
								mountText = RED_FONT_COLOR_CODE .. buffName;
							else
								mountText = ORANGE_FONT_COLOR_CODE .. buffName;
							end
						end
						break;
					else
						raidBuffIndex = raidBuffIndex + 1;
					end
				else
					break;
				end
			end

			text = text .. mountText;

			if frame then
				frame:Show();
				frame.button:Show();
				frame.button.player = raidID;
				frame:SetText(text);
			else
				frame = A.Frame:SpawnText({
					name = frameName,
					inherit = "GameFontNormal",
					points = {{ point = "LEFT", x = 40 }, { point = "RIGHT" }},
					justifyH = "LEFT",
					text = text
				});

				frame.button = A.Frame:SpawnFrame({
					name = frameName .. "Button",
					type = "BUTTON",
					size = 16,
					points = { point = "LEFT", relativeTo = frame, x = -20 },
					data = { player = "none" }, scripts = { OnClick = A.OnTextButtonClick },
					textures = { texture = [[Interface/BUTTONS/UI-GroupLoot-Pass-Up]] }
				});
			end

			if previousFrame then
				frame:SetPoint("TOP", previousFrame, "BOTTOM", 0, -10);
			else
				frame:SetPoint("TOP", A.Frame.ownText, "BOTTOM", 0, -20);
			end

			height = height + frame:GetHeight() + 10;
			previousFrame = frame;
			frameIndex = frameIndex + 1;
		end
	end

	A.Frame:SetHeight(height);
end

A.CloseFrame = function()
	if A.Frame then
		A.Frame:Hide();
	end
end

A.OpenFrame = function()
	A.CreateFrame();
	A.Frame:Show();
end

SLASH_RANDOMMOUNT1 = "/randommount";
function SlashCmdList.RANDOMMOUNT(msg, editbox)
	local mounts = {};
	for i=1,GetNumCompanions("mount") do
		tinsert(mounts,i);
	end

	CallCompanion("mount", mounts[random(#mounts)]);
end