GMSpy = {};
GMSpy.waitingForPin1 = false;
GMSpy.waitingForPin2 = false;
GMSpy.waitingForWho = false;

function GMSpy.spy(name)
    GMSpy.waitingForPin1 = true;
    GMSpy.currentRequest = {};
    GMSpy.currentRequest["name"] = name;
    
    SendChatMessage(".playerinfo "..name, "GUILD");
end

function GMSpy.processPin1(offline, name1, guid, account, accountId, email, gmLevel, ip, login, latency)
    if string.lower(name1) == string.lower(GMSpy.currentRequest["name"]) then
        GMSpy.waitingForPin2 = true;
        GMSpy.waitingForPin1 = false;
        
        if string.len(offline) == 0 then
            GMSpy.openWho(name1);
            GMSpy.currentRequest["guild"] = "Loading...";
            GMSpy.currentRequest["location"] = "Loading...";
            offline = false;
        else
            GMSpy.currentRequest["guild"] = "Unknown";
            GMSpy.currentRequest["location"] = "Unknown";
            offline = true;
        end
        
        GMSpy.currentRequest["name"] = name1;
        GMSpy.currentRequest["offline"] = offline;
        GMSpy.currentRequest["guid"] = guid;
        GMSpy.currentRequest["account"] = account;
        GMSpy.currentRequest["accountId"] = accountId;
        GMSpy.currentRequest["gmLevel"] = gmLevel;
        GMSpy.currentRequest["email"] = email;
        GMSpy.currentRequest["ip"] = ip;
        GMSpy.currentRequest["login"] = login;
        if not offline then
            GMSpy.currentRequest["latency"] = latency;
        else
            GMSpy.currentRequest["latency"] = "offline";
        end
    end
end

function GMSpy.processPin2(race, class, playedTime, level, money)
    GMSpy.waitingForPin2 = false;
    
    GMSpy.currentRequest["race"] = race;
    GMSpy.currentRequest["class"] = class;
    GMSpy.currentRequest["playedTime"] = playedTime;
    GMSpy.currentRequest["level"] = level;
    GMSpy.currentRequest["money"] = money;
    
    GMSpy.resetBoxes();
    getglobal("GMSpy_InfoWindow"):Show();
end

function GMSpy.processWho()
    local i = 1;
	local max = GetNumWhoResults();
    local found = false;
    
    while i <= max and not found do
        name, guild, level, race, class, zone, filename = GetWhoInfo(i);
        if name == GMSpy.currentRequest["name"] then
            found = true;
            GMSpy.currentRequest["guild"] = guild;
            GMSpy.currentRequest["location"] = zone;
            GMSpy.closeWho();
        end
        i = i + 1;
    end
    
    if not found then
        FriendsFrame_OnEvent();
    end
end

function GMSpy.resetBoxes()
    getglobal("GMSpy_InfoWindow_CharInfo"):SetText("Level "..GMSpy.currentRequest["level"].." "..GMSpy.currentRequest["race"].." "..GMSpy.currentRequest["class"]);
    getglobal("GMSpy_InfoWindow_Guild"):SetText("<"..GMSpy.currentRequest["guild"]..">");
    getglobal("GMSpy_InfoWindow_Text"):SetText(GMSpy.currentRequest["name"]);
    getglobal("GMSpy_InfoWindow_Character_Name"):SetText(GMSpy.currentRequest["name"]);
    getglobal("GMSpy_InfoWindow_Character_Id"):SetText(GMSpy.currentRequest["guid"]);
    getglobal("GMSpy_InfoWindow_Account_Name"):SetText(GMSpy.currentRequest["account"]);
    getglobal("GMSpy_InfoWindow_Account_Id"):SetText(GMSpy.currentRequest["accountId"]);
    getglobal("GMSpy_InfoWindow_Email_Email"):SetText(GMSpy.currentRequest["email"]);
    getglobal("GMSpy_InfoWindow_IpLat_Ip"):SetText(GMSpy.currentRequest["ip"]);
    getglobal("GMSpy_InfoWindow_IpLat_Latency"):SetText(GMSpy.currentRequest["latency"]);
    getglobal("GMSpy_InfoWindow_LastLogin_LastLogin"):SetText(GMSpy.currentRequest["login"]);
    getglobal("GMSpy_InfoWindow_PlayedGM_PlayedTime"):SetText(GMSpy.currentRequest["playedTime"]);
    getglobal("GMSpy_InfoWindow_PlayedGM_GM"):SetText(GMSpy.currentRequest["gmLevel"]);
    getglobal("GMSpy_InfoWindow_Money_Money"):SetText(GMSpy.currentRequest["money"]);
    getglobal("GMSpy_InfoWindow_Location_Location"):SetText(GMSpy.currentRequest["location"]);
    getglobal("GMSpy_InfoWindow_Root"):SetAttribute("macrotext1", "/target ".. GMTickets.currentTicket["name"] .." \n/g .freeze");
    getglobal("GMSpy_InfoWindow_Root"):SetAttribute("macrotext2", "/target ".. GMTickets.currentTicket["name"] .." \n/g .unfreeze");
end

function GMSpy.openWho(name)
    FriendsFrame:UnregisterEvent("WHO_LIST_UPDATE");
    GMSpy.captureWho:RegisterEvent("WHO_LIST_UPDATE");
    SetWhoToUI(1);
    SendWho(name);
    Chronos.scheduleByName('closewho', 5, GMSpy.closeWho);
end

function GMSpy.closeWho()
    FriendsFrame:RegisterEvent("WHO_LIST_UPDATE"); 
    GMSpy.captureWho:UnregisterEvent("WHO_LIST_UPDATE");
    SetWhoToUI(0);
    if GMSpy.currentRequest["location"] == "Loading..." and GMSpy.currentRequest["guild"] == "Loading..." then
        GMSpy.currentRequest["guild"] = "Unknown";
        GMSpy.currentRequest["location"] = "Unknown";
    end
    GMSpy.resetBoxes();
end

GMSpy.captureWho = CreateFrame("FRAME", "captureWho");
GMSpy.captureWho:SetScript("OnEvent", GMSpy.processWho);

SLASH_SPY1 = "/spy";
SlashCmdList["SPY"] = GMSpy.spy;

function GMSpy.whisper()
    ChatFrame_SendTell(GMSpy.currentRequest["name"]);
end

function GMSpy.summon()
    SendChatMessage(".summon "..GMSpy.currentRequest["name"], "GUILD");
end

function GMSpy.appear()
    SendChatMessage(".appear "..GMSpy.currentRequest["name"], "GUILD");
end

function GMSpy.revive()
    SendChatMessage(".revive "..GMSpy.currentRequest["name"], "GUILD");
end