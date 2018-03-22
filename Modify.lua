--This file is part of Game Master Genie.
--Copyright 2011, 2012, 2013 Chocochaos

--Game Master Genie is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3 of the License.
--Game Master Genie is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
--You should have received a copy of the GNU General Public License along with Game Master Genie. If not, see <http://www.gnu.org/licenses/>.

GMGenie.Modify = {};

-- config
GMGenie.Modify.perPage = 10;

-- vars
GMGenie.Modify.pages = 1;
GMGenie.Modify.modify = 0;
GMGenie.Modify.onlineTickets = 0;
GMGenie.Modify.currentPage = 1;
GMGenie.Modify.currentTicket = { ["num"] = 0, ["ticketId"] = 0, ['name'] = "", ["message"] = "" };
GMGenie.Modify.order = "ticketId";
GMGenie.Modify.ascDesc = false;
GMGenie.Modify.messageOpen = false;
GMGenie.Modify.done = 0;
GMGenie.Modify.syncList = {};
GMGenie.Modify.loadingOnline = false;
--GMGenie.Modify.Colours = { ["onlineUnread"] = "ffbfbfff", ["onlineRead"] = "ffffffff", ["offlineUnread"] = "ff5f5f80", ["offlineRead"] = "ff808080" };
GMGenie.Modify.Colours = { ["current"] = "ffffffff", ["onlineUnread"] = "ffbfbfff", ["onlineRead"] = "ff5f5f7f", ["offlineUnread"] = "ffff0000", ["offlineRead"] = "ff7f0000" };

-- ticket list
GMGenie.Modify.list = {};
GMGenie.Modify.read = {};
GMGenie.Modify.idToNum = {};

function GMGenie.Modify.onLoad()
    -- Chronos.scheduleRepeating('ticketrefresh', 60, GMGenie.Modify.refresh);
    GMGenie.Modify.refresh();
end

-- refresh ticket list & schedule next refresh
function GMGenie.Modify.refresh()
    if not GMGenie.Modify.tempList then
        -- create empty list
        GMGenie.Modify.tempList = {};
        GMGenie.Modify.idToNum = {};
        GMGenie.Modify.modify = 0;
		GMGenie.Modify.onlineTickets = 0;
		GMGenie.Modify.loadingOnline = false;
        -- get ticket list
		SendChatMessage(".ticket list", "GUILD");
        -- schedule next refresh
        -- Chronos.scheduleByName('ticketreupdate', 3, GMGenie.Modify.update);
	elseif GMGenie.Modify.loadingOnline then
		SendChatMessage(".ticket onlinelist", "GUILD");
        -- Chronos.scheduleByName('ticketreupdate', 3, GMGenie.Modify.update);
    end
end

-- add ticket from chat list to the addon list
function GMGenie.Modify.listTicket(ticketId, name, createStr, createStamp, lastModifiedStr, lastModifiedStamp)
    local ticketInfo = { ["ticketId"] = ticketId, ["name"] = name, ["createStr"] = createStr, ["createStamp"] = createStamp, ["lastModifiedStr"] = lastModifiedStr, ["lastModifiedStamp"] = lastModifiedStamp, ["assignedTo"] = "", ['online'] = GMGenie.Modify.loadingOnline };
    if GMGenie.Modify.tempList and not GMGenie.Modify.idToNum[ticketId] and not GMGenie.Modify.loadingOnline then
        -- add to temp list if page is being refreshed
		table.insert(GMGenie.Modify.tempList, ticketInfo);
		GMGenie.Modify.modify = GMGenie.Modify.modify + 1;
		GMGenie.Modify.idToNum[ticketId] = GMGenie.Modify.modify;
	elseif GMGenie.Modify.tempList and GMGenie.Modify.loadingOnline then
		GMGenie.Modify.onlineTickets = GMGenie.Modify.onlineTickets + 1;
		if GMGenie.Modify.idToNum[ticketId] then
			GMGenie.Modify.tempList[GMGenie.Modify.idToNum[ticketId]] = ticketInfo;
		else
			table.insert(GMGenie.Modify.tempList, ticketInfo);
			GMGenie.Modify.modify = GMGenie.Modify.modify + 1;
			GMGenie.Modify.idToNum[ticketId] = GMGenie.Modify.modify;
		end
    end
    -- if no new modify come in the chat for 1 second, update the list
    -- Chronos.scheduleByName('ticketreupdate', 0.25, GMGenie.Modify.update);
end

-- set assignedTo for a ticket
function GMGenie.Modify.setAssigned(ticketId, assignedTo)
    -- ticket list currently being refreshed or not?
    if GMGenie.Modify.tempList and GMGenie.Modify.idToNum[ticketId] then
        GMGenie.Modify.tempList[GMGenie.Modify.idToNum[ticketId]]["assignedTo"] = assignedTo;
    elseif GMGenie.Modify.idToNum[ticketId] then
        GMGenie.Modify.list[GMGenie.Modify.idToNum[ticketId]]["assignedTo"] = assignedTo;
	else
		Chronos.schedule(0.2, GMGenie.Modify.setAssigned, ticketId, assignedTo);
    end
end

-- update ticket list
function GMGenie.Modify.update()
	-- Check onlines too?
	if not GMGenie.Modify.loadingOnline then
		GMGenie.Modify.loadingOnline = true;
		GMGenie.Modify.refresh();
	else
		GMGenie.Modify.loadingOnline = false;
		
		-- move temp list to current list and empty temp list
		if GMGenie.Modify.tempList then
			GMGenie.Modify.list = GMGenie.Modify.tempList;
			GMGenie.Modify.tempList = nil;
		end
		-- calc number of pages
		if GMGenie_SavedVars.showOfflineTickets then
			GMGenie.Modify.pages = math.ceil(GMGenie.Modify.modify/GMGenie.Modify.perPage);
		else
			GMGenie.Modify.pages = math.ceil(GMGenie.Modify.onlineTickets/GMGenie.Modify.perPage);
		end
		-- allways at least 1 page
		if GMGenie.Modify.pages < 1 then
			GMGenie.Modify.pages = 1;
		end
		-- does the page currently being viewed still exist?
		if GMGenie.Modify.currentPage > GMGenie.Modify.pages then
			GMGenie.Modify.currentPage = GMGenie.Modify.pages;
		end
		-- order ticket list
		GMGenie.Modify.sort();
	end
end

-- change ordering for ticket list
function GMGenie.Modify.changeOrder(order)
    if GMGenie.Modify.order == order then
        if GMGenie.Modify.ascDesc then
            GMGenie.Modify.ascDesc = false;
        else
            GMGenie.Modify.ascDesc = true;
        end
    else
        GMGenie.Modify.order = order;
        GMGenie.Modify.ascDesc = false;
    end
    GMGenie.Modify.currentPage = 1;
    GMGenie.Modify.sort();
end

-- order ticket list
function GMGenie.Modify.sort()
    if GMGenie.Modify.ascDesc then
        table.sort(GMGenie.Modify.list, function(a,b) return a[GMGenie.Modify.order]>b[GMGenie.Modify.order] end);
    else
        table.sort(GMGenie.Modify.list, function(a,b) return a[GMGenie.Modify.order]<b[GMGenie.Modify.order] end);
    end
    
    -- update idToNum table
    GMGenie.Modify.idToNum = {};
    for ticketNum, ticketInfo in ipairs(GMGenie.Modify.list) do
        GMGenie.Modify.idToNum[ticketInfo["ticketId"]] = ticketNum;
    end
    
    -- update the ticket window
    GMGenie.Modify.updateView();
end

-- update the ticket window
function GMGenie.Modify.updateView()
    -- Page x of y (z modify)
    local offlineCount = GMGenie.Modify.modify - GMGenie.Modify.onlineTickets;
    
    local plural = {["total"] = "s", ["online"] = "s", ["offline"] = "s"};
    if GMGenie.Modify.onlineTickets == 1 then
        plural["online"] = "";
    end
    if offlineCount == 1 then
        plural["offline"] = "";
    end
    if GMGenie.Modify.modify == 1 then
        plural["total"] = "";
    end
    
    GMGenie_Modify_Main_Info_Text:SetText(GMGenie.Modify.modify .." ticket".. plural["total"] .." (|c".. GMGenie.Modify.Colours["onlineUnread"] .. GMGenie.Modify.onlineTickets.." online,|r |c".. GMGenie.Modify.Colours["offlineUnread"] .. offlineCount.." offline|r), " ..GMGenie.Modify.done.. " fertig");
	GMGenie_Tickets_Main_Info_Page:SetText("Seite ".. GMGenie.Modify.currentPage .." of ".. GMGenie.Modify.pages);
    
    GMGenie_Hud_Tickets:SetText("Modify (|c".. GMGenie.Modify.Colours["onlineUnread"] .. GMGenie.Modify.onlineTickets .."|r / |c".. GMGenie.Modify.Colours["offlineUnread"] .. offlineCount .. "|r)");
    
    -- previous page
    if (GMGenie.Modify.currentPage == 1) then
		GMGenie_Tickets_Main_Previous:Disable();
	else
		GMGenie_Tickets_Main_Previous:Enable();
	end
    
    -- next page
    if (GMGenie.Modify.currentPage == GMGenie.Modify.pages) then
		GMGenie_Tickets_Main_Next:Disable();
	else
		GMGenie_Tickets_Main_Next:Enable();
	end
    
    -- start and end of the list on the current page
    local minTicket = 1 + ((GMGenie.Modify.currentPage - 1) * GMGenie.Modify.perPage);
	local maxTicket = GMGenie.Modify.currentPage * GMGenie.Modify.perPage;
    local num = 1;
    local i = 0;
    
    -- reset num
    GMGenie.Modify.currentTicket["num"] = 0;
    
    -- loop through modify
    for ticketNum, ticketInfo in ipairs(GMGenie.Modify.list) do
        -- Show ticket?
        if ticketInfo["online"] or GMGenie_SavedVars.showOfflineTickets then
            i = i + 1;
            if i >= minTicket and i <= maxTicket then
                -- colour in list
                local colour;
                if ticketInfo["ticketId"] == GMGenie.Modify.currentTicket["ticketId"] then
                    colour = GMGenie.Modify.Colours["current"];
                else
                    if GMGenie.Modify.read[ticketInfo["ticketId"]] then
                        if ticketInfo["online"] then
                            colour = GMGenie.Modify.Colours["onlineRead"];
                        else
                            colour = GMGenie.Modify.Colours["offlineRead"];
                        end
                    else
                        if ticketInfo["online"] then
                            colour = GMGenie.Modify.Colours["onlineUnread"];
                        else
                            colour = GMGenie.Modify.Colours["offlineUnread"];
                        end
                    end
                end
                
                -- set ticket info
                getglobal("TicketStatusButton".. num .."_ticketId"):SetText("|c".. colour .. ticketInfo["ticketId"] .."|r");
                getglobal("TicketStatusButton".. num .."_name"):SetText("|c".. colour .. ticketInfo["name"] .."|r");
                getglobal("TicketStatusButton".. num .."_createStr"):SetText("|c".. colour .. ticketInfo["createStr"] .."|r");
                getglobal("TicketStatusButton".. num .."_lastModifiedStr"):SetText("|c".. colour .. ticketInfo["lastModifiedStr"] .."|r");
                getglobal("TicketStatusButton".. num .."_assignedTo"):SetText("|c".. colour .. ticketInfo["assignedTo"] .."|r");
                getglobal("TicketStatusButton".. num):Show();
                
                getglobal("TicketStatusButton".. num).ticketId = ticketInfo["ticketId"];
                
                -- number on the ticket window
                num = num + 1;
            end
        end
    end
    if num <= GMGenie.Modify.perPage then
        for num = num, GMGenie.Modify.perPage do
            getglobal("TicketStatusButton".. num):Hide();
        end
    end
end

-- next page
function GMGenie.Modify.goToNext()
    if GMGenie.Modify.currentPage < GMGenie.Modify.pages then
        GMGenie.Modify.currentPage = GMGenie.Modify.currentPage + 1;
        GMGenie.Modify.updateView();
    end
end

-- previous page
function GMGenie.Modify.goToPrevious()
    if GMGenie.Modify.currentPage > 1 then
        GMGenie.Modify.currentPage = GMGenie.Modify.currentPage - 1;
        GMGenie.Modify.updateView();
    end
end

-- mark ticket as read
function GMGenie.Modify.markAsRead(ticketId)
	GMGenie.Modify.read[ticketId] = true;
	GMGenie.Modify.updateView();
end

-- mark ticket as unread
function GMGenie.Modify.markAsUnread(ticketId)
	GMGenie.Modify.ReadTickets[ticketId] = false;
end

function GMGenie.Modify.isOpen()
    local frame = GMGenie_Tickets_Main;
	if (frame) then
        return frame:IsVisible();
    end
end

-- hide or show ticket window
function GMGenie.Modify.toggle(showOffline)
	if GMGenie.Modify.isOpen() then
        -- hide window
        GMGenie_Modify_Main:Hide();
    else
        if showOffline and not GMGenie_SavedVars.showOfflineTickets then
            GMGenie.Modify.toggleOfflineTickets();
        end
        -- refresh ticket list and initiate auto-refresh
        GMGenie.Modify.onLoad();
        -- show window
        GMGenie_Modify_Main:Show();
    end
end

-- load ticket
function GMGenie.Modify.loadTicket(ticketId, num)
    if (GMGenie.Modify.currentTicket["ticketId"] and GMGenie.Modify.currentTicket["ticketId"] == ticketId) then
		GMGenie.Modify.close();
        return;
    else
        if GMGenie.Modify.idToNum[ticketId] then
            if GMGenie.Modify.list[GMGenie.Modify.idToNum[ticketId]]["name"] then
                -- update current ticket
                GMGenie.Modify.currentTicket = { ["num"] = num, ["ticketId"] = ticketId, ["name"] = GMGenie.Modify.list[GMGenie.Modify.idToNum[ticketId]]["name"], ["comment"] = "", ["message"] = "Loading..." };
                -- set title and loading text
                GMGenie_Tickets_View_Title_Text:SetText(GMGenie.Modify.currentTicket["name"].."'s Ticket");
                GMGenie.Modify.showMessage();
                -- hide reading frame UNUSED ATM
                --GMGenie_Tickets_View_Ticket_Reading:Hide();
                -- get ticket
                SendChatMessage(".ticket viewid ".. ticketId,"GUILD");
                -- open spy
                if GMGenie_SavedVars.useSpy then
                    GMGenie.Spy.spy(GMGenie.Modify.currentTicket["name"]);
                end
                -- mark as read
                GMGenie.Modify.markAsRead(ticketId);
                -- toggle frame
                GMGenie_Tickets_View:Show();
                if GMGenie_SavedVars.swapTicketWindows then
                    GMGenie.Modify.toggle();
                end
				-- chronos schedule and send message
				-- Chronos.scheduleRepeating('ticketSync', 30, GMGenie.Modify.sync);
				GMGenie.Modify.sync();
				GMGenie.Modify.displaySync()
                return;
            end
        end
	end
    Chronos.schedule(0.2, GMGenie.Modify.loadTicket, ticketId, num);
end

function GMGenie.Modify.displaySync()
	local names = {};
	local num = 0;
	for name, ticketId in pairs(GMGenie.Modify.syncList) do
		if tonumber(ticketId) == tonumber(GMGenie.Modify.currentTicket["ticketId"]) then
			table.insert(names,name);
			num = num + 1;
		end
	end
	
	if num > 0 then
		local text = "";
		for index, name in ipairs(names) do
			text = text..name;
			if index == (num-1) then
				text = text.." and ";
			elseif index < (num-1) then
				text = text..", ";
			end
		end
		GMGenie_Tickets_View_Sync_Names:SetText(text);
		GMGenie_Tickets_View_Ticket:SetHeight(150);
		GMGenie_Tickets_View_Ticket_Frame:SetHeight(150);
        GMGenie_Tickets_View_Ticket_Frame_Text:SetHeight(150);
		GMGenie_Tickets_View_Sync:Show();
	else
		GMGenie_Tickets_View_Ticket:SetHeight(173);
		GMGenie_Tickets_View_Ticket_Frame:SetHeight(173);
        GMGenie_Tickets_View_Ticket_Frame_Text:SetHeight(173);
		GMGenie_Tickets_View_Sync:Hide();
	end
end

function GMGenie.Modify.sync()
	SendAddonMessage("GMGenie_Sync", GMGenie.Modify.currentTicket["ticketId"], "GUILD");
end

function GMGenie.Modify.syncMessage(name, ticketId)
	if UnitName("player") ~= name then
		if not (GMGenie.Modify.syncList[name] and GMGenie.Modify.syncList[name] == ticketId) then
			GMGenie.Modify.syncList[name] = ticketId;
			if ticketId == 0 then
				Chronos.unscheduleByName('ticketSync'..name);
			else
				Chronos.scheduleByName('ticketSync'..name, 35, GMGenie.Modify.syncMessage, name, 0);
			end
			GMGenie.Modify.displaySync();
		else
			Chronos.scheduleByName('ticketSync'..name, 35, GMGenie.Modify.syncMessage, name, 0);
		end
	end
end

function GMGenie.Modify.loadComment(comment)
    GMGenie.Modify.currentTicket["comment"] = comment;
    GMGenie.Modify.showMessage();
end

function GMGenie.Modify.showMessage()
    GMGenie_Tickets_View_Ticket_Frame_Text:SetText(GMGenie.Modify.currentTicket["message"]);
	GMGenie_Tickets_View_Comment:SetText(GMGenie.Modify.currentTicket["comment"]);
end

function GMGenie.Modify.close()
    if GMGenie.Spy.currentRequest["name"] == GMGenie.Modify.currentTicket["name"] then
        GMGenie_Spy_InfoWindow:Hide();
    end
	SendAddonMessage("GMGenie_Sync", "0", "GUILD");
	Chronos.unscheduleRepeating('ticketSync');
    GMGenie_Tickets_View:Hide();
    GMGenie.Modify.currentTicket = { ["num"] = 0, ["ticketId"] = 0, ['name'] = "" };
    if GMGenie_SavedVars.swapTicketWindows then
        GMGenie.Modify.toggle();
    end
	GMGenie.Modify.updateView();
end

-- read ticket
function GMGenie.Modify.readTicket(ticketId, message)
    if GMGenie.Modify.currentTicket["ticketId"] == ticketId then
        GMGenie.Modify.currentTicket["message"] = message;
        GMGenie.Modify.showMessage();
        return true;
    end
    return false;
end

-- set comment
function GMGenie.Modify.comment(ticketId, comment)
    if GMGenie.Modify.currentTicket["ticketId"] == ticketId then
        GMGenie.Modify.currentTicket["comment"] = comment;
        GMGenie.Modify.showMessage();
        return true;
    end
    return false;
end

--add line to ticket
function GMGenie.Modify.addLine(message)
    GMGenie.Modify.currentTicket["message"] = GMGenie.Modify.currentTicket["message"].."\n"..message;
    GMGenie.Modify.showMessage();
end

function GMGenie.Modify.delete()
    SendChatMessage(".ticket close "..GMGenie.Modify.currentTicket["ticketId"], "GUILD");
    GMGenie.Modify.done = GMGenie.Modify.done + 1;
	local offlineCount = GMGenie.Modify.modify - GMGenie.Modify.onlineTickets;
    GMGenie.Modify.close();
    GMGenie.Modify.refresh();
end

function GMGenie.Modify.assignToSelf()
    SendChatMessage(".ticket assign "..GMGenie.Modify.currentTicket["ticketId"].." "..UnitName("player"), "GUILD");
end

function GMGenie.Modify.assign()
    GMGenie_Tickets_AssignPopup:Show();
    GMGenie_Tickets_AssignPopup_GMName:SetText("");
end

function GMGenie.Modify.assignTo()
    GMGenie_Tickets_AssignPopup:Hide();
    SendChatMessage(".ticket assign "..GMGenie.Modify.currentTicket["ticketId"].." "..GMGenie_Tickets_AssignPopup_GMName:GetText(), "GUILD");
end

function GMGenie.Modify.unassign()
    SendChatMessage(".ticket unassign "..GMGenie.Modify.currentTicket["ticketId"], "GUILD");
end

function GMGenie.Modify.setComment()
    SendChatMessage(".ticket comment "..GMGenie.Modify.currentTicket["ticketId"].." "..GMGenie_Tickets_View_Comment:GetText(), "GUILD");
end

function GMGenie.Modify.Response()
   GMGenie_Tickets_ResponsePopup:Show();
end

-- add slash command to open.close ticket widnow
SLASH_TICKETS1 = "/modify";
SlashCmdList["MODIFY"] = GMGenie.Modify.toggle;

local frame = CreateFrame("FRAME");
frame:RegisterEvent("CHAT_MSG_ADDON");

function frame:OnEvent(event, arg1, arg2, arg3, arg4)
    if event == "CHAT_MSG_ADDON" and (arg1=="GMGenie_TicketSync" or arg1 =="GMGenie_Sync") then
		GMGenie.Modify.syncMessage(arg4, arg2);
    end
end
frame:SetScript("OnEvent", frame.OnEvent);