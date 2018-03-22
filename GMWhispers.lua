GMWhispers = {};

GMWhispers.CurWhisperMessage = '';
GMWhispers.CurName = '';

function GMWhispers.Send(title)
	GMWhispers_SubjectPopup:Hide();
	GMWhispers_SubjectPopup_Subject:SetText('');
	local msg = string.gsub(GMGenie_SavedVars.Whispers[title], "NAME", GMWhispers.CurName);
	if string.find(msg, "SUBJECT") then
		GMWhispers.CurWhisperMessage = msg;
		GMWhispers_SubjectPopup:Show();
		GMWhispers_SubjectPopup_Subject:SetFocus();
	else
		args = {strsplit("\n",msg)};
		for index,text in pairs(args) do
			SendChatMessage(text, "WHISPER", nil, GMWhispers.CurName);
		end
	end
end

function GMWhispers.sendFromSpy()
	GMWhispers.CurName = GMSpy.currentRequest["name"];
	GMWhispers.Send(this.value);
end

function GMWhipsers_SendFromMenu(name, title)
	GMWhispers.CurName = name;
	GMWhispers.Send(title);
end

function GMWhispers.SendWithSubject()
	GMWhispers_SubjectPopup:Hide();
	local subject = GMWhispers_SubjectPopup_Subject:GetText();
	GMWhispers_SubjectPopup_Subject:SetText('');
	
	local msg = string.gsub(GMWhispers.CurWhisperMessage, "SUBJECT", subject);
	args = {strsplit("\n",msg)};
	for index,text in pairs(args) do
		SendChatMessage(text, "WHISPER", nil, GMWhispers.CurName);
	end
	
	GMWhispers.CurWhisperMessage = '';
end

function GMWhispers.LoadDropdown()
	local numWhispers = 0;
	if GMGenie_SavedVars.Whispers then
		GMGenie_SavedVars.WhispersTemp = GMGenie.pairsByKeys2(GMGenie_SavedVars.Whispers);
		for index,name in pairs(GMGenie_SavedVars.WhispersTemp) do
			numWhispers = numWhispers + 1;
			info = {};
			info.text = name;
			info.value = name;
			info.func = GMWhispers.sendFromSpy;
			info.owner = this:GetParent();
			UIDropDownMenu_AddButton(info);
		end
    else
        GMGenie_SavedVars.Whispers = {};
	end
	
	if (numWhispers == 0) then
		info = {};
		info.text = "No whisper macros added yet.";
		info.value = "NOGMWhisper";
		info.func = GMWhispers.ShowOptions;
		info.owner = this:GetParent();
		UIDropDownMenu_AddButton(info);
	end
end

function GMWhispers.Onload()
	UnitPopupButtons["GMWHISPERS"] = { text = "Whisper Macros", dist = 0, nested = 1};
	UnitPopupButtons["CHATNOTES_ADD"] = { text = CN_MENU_ADD, dist = 0,};
	
	GMWhispers.UpdateContextMenu();
	
	table.insert(UnitPopupMenus["PLAYER"], #UnitPopupMenus["PLAYER"]-1, "GMWHISPERS");
	table.insert(UnitPopupMenus["FRIEND"], #UnitPopupMenus["FRIEND"]-1, "GMWHISPERS");
	table.insert(UnitPopupMenus["PARTY"], #UnitPopupMenus["PARTY"]-1, "GMWHISPERS");
	table.insert(UnitPopupMenus["RAID_PLAYER"], #UnitPopupMenus["RAID_PLAYER"]-1, "GMWHISPERS");
	table.insert(UnitPopupMenus["TEAM"], #UnitPopupMenus["TEAM"]-1, "GMWHISPERS");
	table.insert(UnitPopupMenus["CHAT_ROSTER"], #UnitPopupMenus["CHAT_ROSTER"]-1, "GMWHISPERS");

	hooksecurefunc("UnitPopup_OnClick", GMWhispers.ContextMenuClick);
	--hooksecurefunc("UnitPopup_HideButtons", CN_UnitPopupHideButtons);
end

function GMWhispers.UpdateContextMenu()
	UnitPopupMenus["GMWHISPERS"] = {};
	if GMGenie_SavedVars.Whispers then
		GMGenie_SavedVars.WhispersTemp = GMGenie.pairsByKeys2(GMGenie_SavedVars.Whispers);
		for index,name in pairs(GMGenie_SavedVars.WhispersTemp) do
			table.insert(UnitPopupMenus["GMWHISPERS"], "GMWhispers_"..name);
			UnitPopupButtons["GMWhispers_"..name] = { text = name, dist = 0,};
		end
	end
	if (#UnitPopupMenus["GMWHISPERS"] == 0) then
		table.insert(UnitPopupMenus["GMWHISPERS"], "NOGMWhispers");
		UnitPopupButtons["NOGMWhispers"] = { text = "No whisper macros added yet.", dist = 0,};
	end
end

function GMWhispers.ContextMenuClick()
	local dropdownFrame = UIDROPDOWNMENU_INIT_MENU;
	local button = this.value;
	local name = dropdownFrame.name;
	local startPos = string.find(button, "GMWhispers_");
	
	if (startPos == 1) then
	    GMWhipsers_SendFromMenu(name, string.sub(button, 12));
	    ToggleDropDownMenu(1, nil, dropdownFrame, "cursor");
	elseif (button == "NOGMWhispers") then
		GMWhispers.ShowOptions();
	end

	return;
end
