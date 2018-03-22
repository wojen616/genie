GMTickets = {};

-- config
GMTickets.perPage = 10;

-- vars
GMTickets.pages = 1;
GMTickets.tickets = 0;
GMTickets.currentPage = 1;
GMTickets.currentTicket = { ["num"] = 0, ["ticketId"] = 0, ['name'] = "", ["message"] = "" };
GMTickets.order = "ticketId";
GMTickets.ascDesc = false;
GMTickets.messageOpen = false;
GMTickets.done = 0;

-- ticket list
GMTickets.list = {};
GMTickets.read = {};
GMTickets.idToNum = {};

-- refresh ticket list & schedule next refresh
function GMTickets.refresh()
    if not GMTickets.tempList then
        -- remove scheduled refresh, if any
        Chronos.unscheduleByName('ticketrefresh');
        -- create empty list
        GMTickets.tempList = {};
        GMTickets.idToNum = {};
        GMTickets.tickets = 0;
        -- get ticket list
        if GMGenie_SavedVars.showOfflineTickets then
            SendChatMessage(".ticket list", "GUILD");
        else
            SendChatMessage(".ticket onlinelist", "GUILD");
        end
        
        -- schedule next refresh
        -- Chronos.scheduleByName('ticketrefresh', 60, GMTickets.refresh);
    end
end

-- add ticket from chat list to the addon list
function GMTickets.listTicket(ticketId, name, createStr, createStamp, lastModifiedStr, lastModifiedStamp)
    local ticketInfo = { ["ticketId"] = ticketId, ["name"] = name, ["createStr"] = createStr, ["createStamp"] = createStamp, ["lastModifiedStr"] = lastModifiedStr, ["lastModifiedStamp"] = lastModifiedStamp, ["assignedTo"] = "" };
    if GMTickets.tempList and not GMTickets.idToNum[ticketId] then
        -- add to temp list if page is being refreshed
        table.insert(GMTickets.tempList, ticketInfo);
        GMTickets.tickets = GMTickets.tickets + 1;
        GMTickets.idToNum[ticketId] = GMTickets.tickets;
    elseif not GMTickets.idToNum[ticketId] then
        -- else add to current list
        table.insert(GMTickets.list, ticketInfo);
        GMTickets.tickets = GMTickets.tickets + 1;
        GMTickets.idToNum[ticketId] = GMTickets.tickets;
    else
        GMTickets.list[GMTickets.idToNum[ticketId]] = ticketInfo;
    end
    -- if no new tickets come in the chat for 1 second, update the list
    -- Chronos.scheduleByName('ticketreupdate', 0.5, GMTickets.update);
end

-- set assignedTo for a ticket
function GMTickets.setAssigned(ticketId, assignedTo)
    -- ticket list currently being refreshed or not?
    if GMTickets.tempList then
        GMTickets.tempList[GMTickets.idToNum[ticketId]]["assignedTo"] = assignedTo;
    else
        GMTickets.list[GMTickets.idToNum[ticketId]]["assignedTo"] = assignedTo;
    end
end

-- update ticket list
function GMTickets.update()
    -- move temp list to current list and empty temp list
    if GMTickets.tempList then
        GMTickets.list = GMTickets.tempList;
        GMTickets.tempList = nil;
    end
    -- calc number of pages
    GMTickets.pages = math.ceil(GMTickets.tickets/GMTickets.perPage);
    -- allways at least 1 page
    if GMTickets.pages < 1 then
        GMTickets.pages = 1;
    end
    -- does the page currently being viewed still exist?
    if GMTickets.currentPage > GMTickets.pages then
        GMTickets.currentPage = GMTickets.pages;
    end
    -- order ticket list
    GMTickets.sort();
end

-- change ordering for ticket list
function GMTickets.changeOrder(order)
    if GMTickets.order == order then
        if GMTickets.ascDesc then
            GMTickets.ascDesc = false;
        else
            GMTickets.ascDesc = true;
        end
    else
        GMTickets.order = order;
        GMTickets.ascDesc = false;
    end
    GMTickets.currentPage = 1;
    GMTickets.sort();
end

-- order ticket list
function GMTickets.sort()
    if GMTickets.ascDesc then
        table.sort(GMTickets.list, function(a,b) return a[GMTickets.order]>b[GMTickets.order] end);
    else
        table.sort(GMTickets.list, function(a,b) return a[GMTickets.order]<b[GMTickets.order] end);
    end
    
    -- update idToNum table
    GMTickets.idToNum = {};
    for ticketNum, ticketInfo in ipairs(GMTickets.list) do
        GMTickets.idToNum[ticketInfo["ticketId"]] = ticketNum;
    end
    
    -- update the ticket window
    GMTickets.updateView();
end

-- update the ticket window
function GMTickets.updateView()
    -- Page x of y (z tickets)
    GMTickets_Main_Info_Text:SetText("Page ".. GMTickets.currentPage .." of ".. GMTickets.pages.." (".. GMTickets.tickets .." tickets, " ..GMTickets.done.. " done)");
    
    -- previous page
    if (GMTickets.currentPage == 1) then
		GMTickets_Main_Previous:Disable();
	else
		GMTickets_Main_Previous:Enable();
	end
    
    -- next page
    if (GMTickets.currentPage == GMTickets.pages) then
		GMTickets_Main_Next:Disable();
	else
		GMTickets_Main_Next:Enable();
	end
    
    -- start and end of the list on the current page
    local minTicket = 1 + ((GMTickets.currentPage - 1) * GMTickets.perPage);
	local maxTicket = GMTickets.currentPage * GMTickets.perPage;
    local num = 1;
    local i = 0;
    
    -- reset num
    if GMTickets.currentTicket["num"] > 0 then
        getglobal("TicketStatusButton".. GMTickets.currentTicket["num"] .."_Texture"):SetTexture(0, 0, 0);
    end
    GMTickets.currentTicket["num"] = 0;
    
    -- loop through tickets
    for ticketNum, ticketInfo in ipairs(GMTickets.list) do
        i = i + 1;
        -- Show ticket?
        if i >= minTicket and i <= maxTicket then
            -- ticket currently open? Set background
            if(ticketInfo["ticketId"] == GMTickets.currentTicket["ticketId"]) then
                getglobal("TicketStatusButton".. num .."_Texture"):SetTexture("Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar");
                GMTickets.currentTicket["num"] = num;
            else
                getglobal("TicketStatusButton".. num .."_Texture"):SetTexture(0, 0, 0);
            end
            -- set ticket info
            getglobal("TicketStatusButton".. num .."_ticketId"):SetText(ticketInfo["ticketId"]);
            getglobal("TicketStatusButton".. num .."_name"):SetText(ticketInfo["name"]);
            getglobal("TicketStatusButton".. num .."_createStr"):SetText(ticketInfo["createStr"]);
            getglobal("TicketStatusButton".. num .."_lastModifiedStr"):SetText(ticketInfo["lastModifiedStr"]);
            getglobal("TicketStatusButton".. num .."_assignedTo"):SetText(ticketInfo["assignedTo"]);
            getglobal("TicketStatusButton".. num):Show();
            
            getglobal("TicketStatusButton".. num).ticketId = ticketInfo["ticketId"];
            
            -- ticket is read?
			if GMTickets.read[ticketInfo["ticketId"]] then
				getglobal("TicketStatusButton".. num .."_name"):SetTextColor(1,1,1);
			else
				getglobal("TicketStatusButton".. num .."_name"):SetTextColor(1,0.82,0);
			end
            -- number on the ticket window
            num = num + 1;
        end
    end
    if num <= GMTickets.perPage then
        for num = num, GMTickets.perPage do
            getglobal("TicketStatusButton".. num):Hide();
        end
    end
end

-- next page
function GMTickets.goToNext()
    if GMTickets.currentPage < GMTickets.pages then
        GMTickets.currentPage = GMTickets.currentPage + 1;
        GMTickets.updateView();
    end
end

-- previous page
function GMTickets.goToPrevious()
    if GMTickets.currentPage > 1 then
        GMTickets.currentPage = GMTickets.currentPage - 1;
        GMTickets.updateView();
    end
end

-- mark ticket as read
function GMTickets.markAsRead(ticketId)
	GMTickets.read[ticketId] = true;
	GMTickets.updateView();
end

-- mark ticket as unread
function GMTickets.markAsUnread(ticketId)
	GMTickets.ReadTickets[ticketId] = false;
end

function GMTickets.isOpen()
    local frame = getglobal("GMTickets_Main");
	if (frame) then
        return frame:IsVisible();
    end
end

-- hide or show ticket window
function GMTickets.toggle()
	if GMTickets.isOpen() then
        -- stop auto-refresh
        Chronos.unscheduleByName('ticketrefresh');
        -- hide window
        getglobal("GMTickets_Main"):Hide();
    else
        -- refresh ticket list and initiate auto-refresh
        GMTickets.refresh();
        -- set text fro next and previous buttons, characters don't work in xml
        GMTickets_Main_Previous:SetText('<');
        GMTickets_Main_Next:SetText('>');
        -- show window
        getglobal("GMTickets_Main"):Show();
    end
end

-- load ticket
function GMTickets.loadTicket(ticketId, num)
    if (GMTickets.currentTicket["ticketId"] == ticketId) then
		GMTickets.close();
    else
        -- un-highlight previous ticket in list
        if GMTickets.currentTicket["num"] > 0 then
            getglobal("TicketStatusButton".. GMTickets.currentTicket["num"] .."_Texture"):SetTexture(0, 0, 0);
        end
        -- update current ticket
        GMTickets.currentTicket = { ["num"] = num, ["ticketId"] = ticketId, ["name"] = GMTickets.list[GMTickets.idToNum[ticketId]]["name"] };
        -- set title and loading text
        getglobal("GMTickets_View_Text"):SetText(GMTickets.currentTicket["name"].."'s Ticket");
        GMTickets.currentTicket["message"] = "Loading...";
        GMTickets.showMessage();
        -- hide reading frame UNUSED ATM
        --getglobal("GMTickets_View_Ticket_Reading"):Hide();
        -- get ticket
        SendChatMessage(".ticket viewid ".. ticketId,"GUILD");
        -- open spy
        --if GMGenie_SavedVars.useSpy then
          --  GMSpy.spy(GMTickets.currentTicket["name"]);
        --end
        -- mark as read
        GMTickets.markAsRead(ticketId);
        -- highlight in list
        getglobal("TicketStatusButton".. num .."_Texture"):SetTexture("Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar");
        -- toggle frame
		getglobal("GMTickets_View"):Show();
        if GMGenie_SavedVars.swapTicketWindows then
            GMTickets.toggle();
        end
	end
end

function GMTickets.showMessage()
    getglobal("GMTickets_View_Ticket_Frame_Text"):SetText(GMTickets.currentTicket["message"]);
end

function GMTickets.close()
    if GMTickets.currentTicket["num"] > 0 then
        getglobal("TicketStatusButton".. GMTickets.currentTicket["num"] .."_Texture"):SetTexture(0, 0, 0);
    end
    getglobal("GMTickets_View"):Hide();
    GMTickets.currentTicket = { ["num"] = 0, ["ticketId"] = 0, ['name'] = "" };
    if GMGenie_SavedVars.swapTicketWindows then
        GMTickets.toggle();
    end
end

-- read ticket
function GMTickets.readTicket(ticketId, message)
    if GMTickets.currentTicket["ticketId"] == ticketId then
        GMTickets.currentTicket["message"] = message;
        GMTickets.showMessage();
        return true;
    end
    return false;
end

--add line to ticket
function GMTickets.addLine(message)
    GMTickets.currentTicket["message"] = GMTickets.currentTicket["message"].."\n"..message;
    GMTickets.showMessage();
end

function GMTickets.delete()
    SendChatMessage(".ticket close "..GMTickets.currentTicket["ticketId"], "GUILD");
    GMTickets.done = GMTickets.done + 1;
    GMTickets_Main_Info_Text:SetText("Page ".. GMTickets.currentPage .." of ".. GMTickets.pages.." (".. GMTickets.tickets .." tickets, " ..GMTickets.done.. " done)");
    GMTickets.close();
    GMTickets.refresh();
end

function GMTickets.showInfo(ticketId)
    local ticketInfo = GMTickets.list[GMTickets.idToNum[ticketId]];
end

function GMTickets.assignToSelf()
    SendChatMessage(".ticket assign "..GMTickets.currentTicket["ticketId"].." "..UnitName("player"), "GUILD");
end

function GMTickets.assign()
    getglobal("GMTickets_AssignPopup"):Show();
    getglobal("GMTickets_AssignPopup_GMName"):SetText("");
end

function GMTickets.assignTo()
    getglobal("GMTickets_AssignPopup"):Hide();
    SendChatMessage(".ticket assign "..GMTickets.currentTicket["ticketId"].." "..getglobal("GMTickets_AssignPopup_GMName"):GetText(), "GUILD");
end

function GMTickets.comment()
    getglobal("GMTickets_CommentPopup"):Show();
    getglobal("GMTickets_CommentPopup_Comment"):SetText("");
end

function GMTickets.setComment()
    getglobal("GMTickets_CommentPopup"):Hide();
    SendChatMessage("ticket comment "..GMTickets.currentTicket["ticketId"].." "..getglobal("GMTickets_CommentPopup_Comment"):GetText(), "GUILD");
end

-- add slash command to open.close ticket widnow
SLASH_TICKETS1 = "/tickets";
SlashCmdList["TICKETS"] = GMTickets.toggle;