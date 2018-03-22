-- ADD TicketTab = "General";

function GMTickets.OptionsOnokay()
	if(GMTickets_OptionsWindow_showOffline:GetChecked()) then GMGenie_SavedVars.showOfflineTickets = true; else GMGenie_SavedVars.showOfflineTickets = false; end
	if(GMTickets_OptionsWindow_swapWindows:GetChecked()) then GMGenie_SavedVars.swapTicketWindows = true; else GMGenie_SavedVars.swapTicketWindows = false; end
	if(GMTickets_OptionsWindow_useSpy:GetChecked()) then GMGenie_SavedVars.useSpy = true; else GMGenie_SavedVars.useSpy = false; end
    GMTickets.refresh();
end

function GMTickets.OptionsOncancel()
	getglobal("GMTickets_OptionsWindow_showOffline"):SetChecked(GMGenie_SavedVars.showOfflineTickets);
	getglobal("GMTickets_OptionsWindow_swapWindows"):SetChecked(GMGenie_SavedVars.swapTicketWindows);
    getglobal("GMTickets_OptionsWindow_useSpy"):SetChecked(GMGenie_SavedVars.useSpy);
end

function GMTickets.OptionsOndefault()
	GMGenie_SavedVars.showOfflineTickets = true;
	getglobal("GMTickets_OptionsWindow_showOffline"):SetChecked(GMGenie_SavedVars.showOfflineTickets);
    
	GMGenie_SavedVars.swapTicketWindows = false;
	getglobal("GMTickets_OptionsWindow_swapWindows"):SetChecked(GMGenie_SavedVars.swapTicketWindows);
    
	GMGenie_SavedVars.useSpy = false;
	getglobal("GMTickets_OptionsWindow_useSpy"):SetChecked(GMGenie_SavedVars.useSpy);
end

function GMTickets.OptionsOnload(panel)
	panel.name = "Wishmaster";
	panel.parent = "GM Genie";
	panel.okay = GMTickets.OptionsOnokay;
	panel.cancel = GMTickets.OptionsOncancel;
	panel.default = GMTickets.OptionsOndefault;
	
	InterfaceOptions_AddCategory(panel);
	
	getglobal("GMTickets_OptionsWindow_Title"):SetText("Wishmaster");
	getglobal("GMTickets_OptionsWindow_SubText"):SetText("Here you can change the settings for Wishmaster.");
end

function GMTickets.LoadSavedVars()
	if event == "ADDON_LOADED" and arg1 == "GMGenie" then
		if not GMGenie_SavedVars.showOfflineTickets then
			GMGenie_SavedVars.showOfflineTickets = true;
		end
		getglobal("GMTickets_OptionsWindow_showOffline"):SetChecked(GMGenie_SavedVars.showOfflineTickets);
        
        if not GMGenie_SavedVars.swapTicketWindows then
			GMGenie_SavedVars.swapTicketWindows = false;
		end
		getglobal("GMTickets_OptionsWindow_swapWindows"):SetChecked(GMGenie_SavedVars.swapTicketWindows);
        
        if not GMGenie_SavedVars.useSpy then
			GMGenie_SavedVars.useSpy = false;
		end
		getglobal("GMTickets_OptionsWindow_useSpy"):SetChecked(GMGenie_SavedVars.useSpy);
	end
end

function GMTickets.ShowOptions()
	InterfaceOptionsFrame_OpenToCategory("Wishmaster");
end

GMTickets.EventsFrame = CreateFrame("FRAME");
GMTickets.EventsFrame:RegisterEvent("ADDON_LOADED");
GMTickets.EventsFrame:SetScript("OnEvent", GMTickets.LoadSavedVars);