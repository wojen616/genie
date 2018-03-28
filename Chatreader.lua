--This file is part of Game Master Genie.
--Copyright 2011-2014 Chocochaos

--Game Master Genie is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3 of the License.
--Game Master Genie is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
--You should have received a copy of the GNU General Public License along with Game Master Genie. If not, see <http://www.gnu.org/licenses/>.

TicketTab = "General";

-- 1d2h3m4s to number in seconds
function GMGenie.timeStrToSeconds(timeStr)
    local days = string.match(timeStr, "([0-9]*)d");
    if not days then
        days = 0;
    end
    local hours = string.match(timeStr, "([0-9]*)h");
    if not hours then
        hours = 0;
    end
    local minutes = string.match(timeStr, "([0-9]*)m");
    if not minutes then
        minutes = 0;
    end
    local seconds = string.match(timeStr, "([0-9]*)s");
    if not seconds then
        seconds = 0;
    end
    return (((((tonumber(days) * 24) + tonumber(hours)) * 60) + tonumber(minutes)) * 60) + tonumber(seconds);
end

-- Read from chat
local ORIG_ChatFrame_MessageEventHandler = ChatFrame_MessageEventHandler;
function ChatFrame_MessageEventHandler(self, event, ...)
    local arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15 = ...;

    local ActionTaken = false;

    -- development code to analize chat messages
    --local excapedarg = string.gsub(arg1, "%|", "%%");
    --GMGenie.showGMMessage("1: " .. excapedarg);

    -- check for system messages of interest
    if (event == "CHAT_MSG_SYSTEM") then
        -- Showing list of open tickets whose creator is online.
        if string.find(arg1, "Showing list of open tickets") then
            Chronos.scheduleByName('ticketreupdate', 0.5, GMGenie.Tickets.update);
            ActionTaken = true;
        end
        -- ticket list or reading ticket
        local ticketId, name, createStr, lastModifiedStr, rest = string.match(arg1, "^%|cffaaffaaTicket%|r:%|cffaaccff%s([0-9]+).%|r%s%|cff00ff00Created%sby%|r:%|cff00ccff%s(.+)%|r%s%|cff00ff00Created%|r:%|cff00ccff%s([a-zA-Z0-9%s]+)%sago%|r%s%|cff00ff00Last%schange%|r:%|cff00ccff%s([a-zA-Z0-9%s]+)%sago%|r%s(.*)$");

        if ticketId and name and createStr and lastModifiedStr then
            ticketId = tonumber(ticketId);
            local createStamp = GMGenie.timeStrToSeconds(createStr);
            local lastModifiedStamp = GMGenie.timeStrToSeconds(lastModifiedStr);
            if GMGenie.Tickets.tempList then
                GMGenie.Tickets.listTicket(ticketId, name, createStr, createStamp, lastModifiedStr, lastModifiedStamp);
            end

            local assignedTo = string.match(rest, "%|cff00ff00Assigned%sto%|r:%|cff00ccff%s([a-zA-Z]+)%|r%s");
            if assignedTo then
                GMGenie.Tickets.setAssigned(ticketId, assignedTo);
            end
            local message = string.match(rest, "%|cff00ff00Ticket%sMessage%|r:%s%[(.-)%]%|r");
            local ticketCorrect = false;
            if message then
                ticketCorrect = GMGenie.Tickets.readTicket(ticketId, message);
            else
                local message = string.match(rest, "%|cff00ff00Ticket%sMessage%|r:%s%[(.*)");
                if message then
                    ticketCorrect = GMGenie.Tickets.readTicket(ticketId, message);
                    if ticketCorrect then
                        GMGenie.Tickets.messageOpen = true;
                    end
                end
            end

            local comment = string.match(rest, "%|cff00ff00GM%sComment%|r:%s%[(.*)%]%|r");
            if comment then
                GMGenie.Tickets.comment(ticketId, comment);
            end

            if ticketCorrect or GMGenie.Tickets.tempList then
                ActionTaken = true;
            end
        elseif GMGenie.Tickets.messageOpen then
            ActionTaken = true;
            local message, rest = string.match(arg1, "(.-)%]%|r(.*)");
            if message then
                GMGenie.Tickets.messageOpen = false;
                GMGenie.Tickets.addLine(message);
            else
                if string.find(arg1, "%]%|r") then
                    rest = string.match(arg1, "%]%|r(.*)");
                    GMGenie.Tickets.messageOpen = false;
                else
                    GMGenie.Tickets.addLine(arg1);
                end
            end

            if rest then
                local comment = string.match(rest, "%|cff00ff00GM%sComment%|r:%s%[(.*)%]%|r");
                if comment and GMGenie.Tickets.currentTicket['ticketId'] then
                    GMGenie.Tickets.comment(GMGenie.Tickets.currentTicket['ticketId'], comment);
                end
            end
        else
            
        end

        local charName = UnitName("player");
        if string.match(arg1, "%|cffffffff%|Hplayer:" .. charName .. "%|h%[" .. charName .. "%]%|h%|r%'s Fly Mode on") then
            GMGenie.Hud.flyStatus(true);
        elseif string.match(arg1, "%|cffffffff%|Hplayer:" .. charName .. "%|h%[" .. charName .. "%]%|h%|r%'s Fly Mode off") then
            GMGenie.Hud.flyStatus(false);
        elseif arg1 == "Accepting Whisper: ON" or arg1 == "Accepting Whisper: on" then
            GMGenie.Hud.whisperStatus(true);
        elseif arg1 == "Accepting Whisper: OFF" or arg1 == "Accepting Whisper: off" then
            GMGenie.Hud.whisperStatus(false);
        elseif arg1 == "You are: visible" then
            GMGenie.Hud.visibilityStatus(true);
        elseif arg1 == "You are: invisible" then
            GMGenie.Hud.visibilityStatus(false);
        end

        local characterName = string.match(arg1, "%|cFFFFBF00%[AntiCheat%]%:%|cFFFFFFFF %[(.*)%] %|cFF00FFFFdetected as possible cheater%.");
        if characterName then
            arg1 = "|cFFFFBF00[AntiCheat]:|r |Hanticheat:" .. characterName .. "|h[" .. characterName .. "]|h detected as possible cheater.";
        end
    end

    -- if nothing was done, just display the message
    if not ActionTaken then
        ORIG_ChatFrame_MessageEventHandler(self, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15);
    end
end
