function GMWhispers.OptionsOnload(panel)
	panel.name = "Whisper Macros";
	panel.parent = "GM Genie";
	
	InterfaceOptions_AddCategory(panel);
	
	getglobal(panel:GetName().."_Title"):SetText("Whisper Macros");
	getglobal(panel:GetName().."_SubText"):SetText("Here you add and update whisper macros, which will be available from the ticket interface and the player context menus.");
end


GMWhispers.Currentediting = nil;

function GMWhispers.DropdownOnload()
	if GMGenie_SavedVars.Whispers then
		GMGenie_SavedVars.WhispersTemp = GMGenie.pairsByKeys2(GMGenie_SavedVars.Whispers);
		for index,name in pairs(GMGenie_SavedVars.WhispersTemp) do
			info = {};
			info.text = name;
			info.value = name;
			info.func = GMWhispers.Edit;
			info.owner = this:GetParent();
			UIDropDownMenu_AddButton(info);
		end
    else
        GMGenie_SavedVars.Whispers = {};
	end
end

function GMWhispers.Edit()
	GMWhispers.Currentediting = this.value;
	GMWhispers_OptionsWindow_Name:SetText(this.value);
	GMWhispers_OptionsWindow_Macro_Frame_Text:SetText(GMGenie_SavedVars.Whispers[this.value]);
	GMWhispers_OptionsWindow_Save:SetText("Save");
	GMWhispers_OptionsWindow_Delete:Enable();
end

function GMWhispers.Save()
	local name = GMWhispers_OptionsWindow_Name:GetText();
	local macro = GMWhispers_OptionsWindow_Macro_Frame_Text:GetText();
	
	if name and macro and name ~= "" then
		GMGenie_SavedVars.Whispers[name] = macro;
		
		if GMWhispers.Currentediting then
			if (name ~= GMWhispers.Currentediting) then
				GMGenie_SavedVars.Whispers[GMWhispers.Currentediting] = nil;
				GMWhispers.Currentediting = name;
			end
		else
			GMWhispers.Currentediting = name;
			GMWhispers_OptionsWindow_Save:SetText("Save");
			GMWhispers_OptionsWindow_Delete:Enable();
		end
	end
	GMWhispers.UpdateContextMenu();
end

function GMWhispers.Delete()
	local name = GMWhispers_OptionsWindow_Name:GetText();
	
	if name and name ~= "" then
		GMGenie_SavedVars.Whispers[name] = nil;
		GMWhispers.CleanForm();
	end
	GMWhispers.UpdateContextMenu();
end

function GMWhispers.CleanForm()
	GMWhispers.Currentediting = nil;
	GMWhispers_OptionsWindow_Name:SetText("");
	GMWhispers_OptionsWindow_Macro_Frame_Text:SetText("");
	GMWhispers_OptionsWindow_Save:SetText("Add");
	GMWhispers_OptionsWindow_Delete:Disable();
end

function GMWhispers.ShowOptions()
	InterfaceOptionsFrame_OpenToCategory("Whisper Macros");
end
