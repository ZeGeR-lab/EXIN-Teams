local _, FT = ...
local panel = CreateFrame("Frame", "ForeverTeamsPanel", UIParent, "BackdropTemplate")
panel:SetSize(710, 580)
panel:SetPoint("CENTER")
panel:SetFrameStrata("DIALOG")
panel:SetMovable(true)
panel:EnableMouse(true)
panel:RegisterForDrag("LeftButton")
panel:SetScript("OnDragStart", panel.StartMoving)
panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
panel:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize=24,
  insets={left=8,right=8,top=8,bottom=8}})
panel:SetBackdropColor(0.035, 0.045, 0.06, 0.98)
panel:SetBackdropBorderColor(0.34, 0.45, 0.25, 1)
panel:Hide()
local function card(x, y, width, height)
  local border = panel:CreateTexture(nil, "BACKGROUND")
  border:SetTexture("Interface\\Buttons\\WHITE8X8")
  border:SetPoint("TOPLEFT", x, y)
  border:SetSize(width, height)
  border:SetVertexColor(0.20, 0.26, 0.22, 0.95)
  local fill = panel:CreateTexture(nil, "BACKGROUND", nil, 1)
  fill:SetTexture("Interface\\Buttons\\WHITE8X8")
  fill:SetPoint("TOPLEFT", x+1, y-1)
  fill:SetSize(width-2, height-2)
  fill:SetVertexColor(0.08, 0.10, 0.13, 0.95)
end
card(12, -40, 185, 480)
card(202, -40, 495, 87)
card(202, -168, 495, 185)
card(202, -357, 495, 78)
card(202, -468, 495, 100)
local accent = panel:CreateTexture(nil, "BACKGROUND", nil, 2)
accent:SetTexture("Interface\\Buttons\\WHITE8X8")
accent:SetPoint("TOPLEFT", 203, -41)
accent:SetSize(493, 3)
accent:SetVertexColor(0.61, 0.86, 0.25)
local function line(parent, x, y, width, size)
  local t = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  t:SetPoint("TOPLEFT", x, y)
  t:SetWidth(width)
  t:SetJustifyH("LEFT")
  if size == "small" then t:SetFontObject(GameFontHighlightSmall) end
  return t
end
local title = line(panel, 20, -17, 500)
title:SetText("|cff9bdd00EXIN TEAMS|r  |cff8b9b8bEx Inferno guild dashboard|r")
local function button(parent, label, x, y, w, fn)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(w, 24)
  b:SetPoint("TOPLEFT", x, y)
  b:SetText(label)
  b:SetScript("OnClick", fn)
  return b
end
button(panel, "X", 665, -14, 25, function() panel:Hide() end)
local header = line(panel, 210, -50, 470)
header:SetFontObject(GameFontNormalLarge)
local message = line(panel, 210, -78, 475, "small")
message:SetHeight(38)
local teamRows, rosterRows, requestRows, eventRows = {}, {}, {}, {}
local rosterHover, requestHover = {}, {}
local function ask(titleText, default, callback)
  StaticPopupDialogs.FOREVER_TEAMS_INPUT = {
    text=titleText, button1=ACCEPT, button2=CANCEL, hasEditBox=true, timeout=0,
    whileDead=true, hideOnEscape=true, preferredIndex=3,
    OnShow=function(dialog)
      local box = dialog.EditBox or dialog.editBox
      if box then box:SetText(default or ""); box:SetFocus() end
    end,
    OnAccept=function(dialog)
      local box = dialog.EditBox or dialog.editBox
      if box then callback(box:GetText()) end
    end,
    EditBoxOnEnterPressed=function(box)
      callback(box:GetText())
      box:GetParent():Hide()
    end,
  }
  StaticPopup_Show("FOREVER_TEAMS_INPUT")
end
local function chosen() return FT.teams[FT.selected] end
local function me() return (UnitName("player") or ""):lower() end
local function sortedTeams()
  local list = {}
  for _, team in pairs(FT.teams) do table.insert(list, team) end
  table.sort(list, function(a,b) return (a.name or "") < (b.name or "") end)
  return list
end
local function sortedMembers(team)
  local list = {}
  for who in pairs(team.members) do table.insert(list, who) end
  table.sort(list)
  return list
end
local function professionText(who)
  local trades=FT.professions[who]
  if not trades or not trades[1] then return "Not shared yet" end
  local result={}
  for _, trade in ipairs(trades) do
    if trade.name and trade.name ~= "None" then
      table.insert(result, trade.name .. " (" .. tostring(trade.rank or 0) .. ")")
    end
  end
  return #result > 0 and table.concat(result, ", ") or "None recorded"
end
local function hover(x,y,width,detail)
  local f=CreateFrame("Frame",nil,panel)
  f:SetPoint("TOPLEFT",x,y)
  f:SetSize(width,19)
  f:EnableMouse(true)
  f:SetScript("OnEnter",function(self)
    if not self.who then return end
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
    GameTooltip:AddLine(self.who,0.65,0.88,0.35)
    GameTooltip:AddLine("Professions: "..professionText(self.who),1,1,1,true)
    detail(self)
    GameTooltip:Show()
  end)
  f:SetScript("OnLeave",function() GameTooltip:Hide() end)
  f:Hide()
  return f
end
button(panel, "New team", 20, -44, 85, function()
  ask("Team name (up to 24 characters)", "", function(name)
    name = name:match("^%s*(.-)%s*$")
    if #name < 2 or #name > 24 then FT:Notice("Use a name of 2–24 characters."); return end
    local id = me() .. "-" .. tostring(time()) .. "-" .. tostring(math.floor(GetTime() * 1000) % 100000)
    FT:Act("NEW", id, name, "General", "Welcome to " .. name, me(), "White")
    FT.selected = id; FT:Refresh()
  end)
end)
button(panel, "Refresh", 110, -44, 75, function() FT:OpenGuild(); FT:Refresh() end)
local teamLabel = line(panel, 22, -82, 170, "small")
teamLabel:SetText("|cff9bdd00YOUR TEAMS|r")
for i=1,12 do
  teamRows[i] = button(panel, "", 20, -100-(i-1)*28, 170, function(self)
    FT.selected = self.teamID; FT:Refresh()
  end)
end
local roleTitle = line(panel, 22, -433, 170, "small")
roleTitle:SetText("|cff9bdd00DUNGEON ROLES|r")
local mainRoleButton = button(panel, "Main: choose", 20, -450, 170, function()
  local profile = FT.profiles[me()] or {main="DPS", off="None"}
  local order = {"Tank", "Healer", "DPS"}
  local index = 0
  for i, value in ipairs(order) do if value == profile.main then index = i end end
  FT:Act("PROFILE", me(), order[index % #order + 1], profile.off)
end)
local offRoleButton = button(panel, "Off: none", 20, -480, 170, function()
  local profile = FT.profiles[me()] or {main="DPS", off="None"}
  local order = {"None", "Tank", "Healer", "DPS"}
  local index = 1
  for i, value in ipairs(order) do if value == profile.off then index = i end end
  FT:Act("PROFILE", me(), profile.main, order[index % #order + 1])
end)
local rosterTitle = line(panel, 210, -175, 480)
rosterTitle:SetText("|cff9bdd00ROSTER|r")
for i=1,9 do
  rosterRows[i] = line(panel, 215, -195-(i-1)*19, 460, "small")
  rosterHover[i] = hover(213,-192-(i-1)*19,460,function(self)
    local profile=FT.profiles[self.who]
    if profile then GameTooltip:AddLine("Dungeon roles: "..profile.main.." / "..profile.off,0.8,0.85,1) end
    local info=FT.playerInfo[self.who]
    if info then
      GameTooltip:AddLine("Availability: "..info.availability,1,1,1,true)
      GameTooltip:AddLine("Interests: "..info.interest,1,1,1,true)
    end
  end)
end
local requestTitle = line(panel, 210, -365, 480)
requestTitle:SetText("|cff9bdd00APPLICATIONS|r")
local requestButtons = {}
for i=1,3 do
  requestRows[i] = line(panel, 215, -384-(i-1)*20, 340, "small")
  requestButtons[i] = button(panel, "Accept", 575, -378-(i-1)*20, 75, function(self)
    local team = chosen()
    if team and self.applicant and FT:CanManage(team, me()) then
      FT:Act("ACCEPT", team.id, self.applicant)
    end
  end)
  requestButtons[i]:SetHeight(18)
  requestHover[i] = hover(213,-381-(i-1)*20,350,function(self)
    local team=chosen()
    local request=team and FT.requests[team.id] and FT.requests[team.id][self.who]
    if type(request)=="table" then
      GameTooltip:AddLine("Availability: "..(request.availability or "Not provided"),1,1,1,true)
      GameTooltip:AddLine("Interests: "..(request.interest or "Not provided"),1,1,1,true)
    end
  end)
end
local eventTitle = line(panel, 210, -475, 480)
eventTitle:SetText("|cff9bdd00TEAM EVENTS|r  |cff8b9b8bserver time|r")
local eventButtons = {}
for i=1,3 do
  eventRows[i] = line(panel, 215, -495-(i-1)*22, 350, "small")
  eventButtons[i] = button(panel,"Join",575,-489-(i-1)*22,75,function(self)
    local team=chosen()
    if team and team.members[me()] and self.eventID then
      FT:Act("RSVP",team.id,self.eventID,self.attending and "no" or "yes")
    end
  end)
end
local controls = {}
local function control(label,x,y,w,fn)
  local b=button(panel,label,x,y,w,fn)
  table.insert(controls,b)
  return b
end
local applyButton=control("Apply",210,-135,55,function()
  local team=chosen()
  if team and not team.members[me()] and not (FT.requests[team.id] and FT.requests[team.id][me()]) then
    local teamID=team.id
    ask("When are you usually available? (days and server time, up to 70 characters)", "", function(availability)
      availability=availability:match("^%s*(.-)%s*$")
      if #availability < 2 or #availability > 70 or availability:find("[|\r\n]") then
        FT:Notice("Please enter your usual availability (2–70 characters)."); return
      end
      C_Timer.After(0,function()
        ask("Do you play PvE, PvP, or Both?", "Both", function(interest)
          interest=interest:match("^%s*(.-)%s*$"):lower()
          interest=interest=="pve" and "PvE" or interest=="pvp" and "PvP" or interest=="both" and "Both" or nil
          if not interest then FT:Notice("Enter PvE, PvP, or Both."); return end
          if FT.teams[teamID] then
            FT:UpdateProfessions()
            FT:Act("PREF",me(),availability,interest)
            FT:Act("APPLY",teamID,me(),availability,interest)
            FT:Notice("Application sent to "..FT.teams[teamID].name)
          end
        end)
      end)
    end)
  end
end)
local joinButton=control("Join invite",270,-135,95,function()
  local team=chosen()
  if team and FT.invitations[team.id] and FT.invitations[team.id][me()] then
    FT:Act("JOIN",team.id,me())
  end
end)
control("Leave",370,-135,55,function()
  local team=chosen()
  if team and team.members[me()] and team.owner ~= me() then FT:Act("REMOVE",team.id,me()) end
end)
control("Invite",430,-135,60,function()
  local team=chosen(); if not team or not FT:CanManage(team,me()) then return end
  ask("Guild member to invite", "", function(name)
    local who=name:lower():gsub("%-.*$", "")
    if FT.roster[who] then FT:Act("INVITE",team.id,who) else FT:Notice("That character is not in the loaded guild roster.") end
  end)
end)
control("Accept",495,-135,66,function()
  local team=chosen(); if not team or not FT:CanManage(team,me()) then return end
  ask("Applicant name", "", function(name) FT:Act("ACCEPT",team.id,name:lower():gsub("%-.*$", "")) end)
end)
control("Remove",565,-135,70,function()
  local team=chosen(); if not team or not FT:CanManage(team,me()) then return end
  ask("Member to remove", "", function(name) FT:Act("REMOVE",team.id,name:lower():gsub("%-.*$", "")) end)
end)
control("Role",638,-135,48,function()
  local team=chosen(); if not team or team.owner ~= me() then return end
  ask("Member name to toggle officer role", "", function(name)
    local who=name:lower():gsub("%-.*$", "")
    if team.members[who] and who ~= me() then
      FT:Act("ROLE",team.id,who,team.members[who]=="officer" and "member" or "officer")
    end
  end)
end)
control("Edit focus",210,-442,90,function()
  local team=chosen(); if team and FT:CanManage(team,me()) then
    ask("Team focus",team.focus,function(s) FT:Act("FOCUS",team.id,s) end)
  end
end)
control("Edit message",305,-442,105,function()
  local team=chosen(); if team and FT:CanManage(team,me()) then
    ask("Team message of the day",team.motd,function(s) FT:Act("MOTD",team.id,s) end)
  end
end)
control("Add event",415,-442,90,function()
  local team=chosen(); if team and FT:CanManage(team,me()) then
    ask("YYYY-MM-DD HH:MM ; Event title (server time)","",function(s)
      local when,title=s:match("^%s*(%d%d%d%d%-%d%d%-%d%d %d%d:%d%d)%s*;%s*(.-)%s*$")
      if not when or not title or #title < 2 or #title > 70 then
        FT:Notice("Use YYYY-MM-DD HH:MM ; Event title.")
        return
      end
      local eventID=me().."-"..tostring(time()).."-"..tostring(math.floor(GetTime()*1000)%100000)
      FT:Act("EVENT",team.id,eventID,when,title)
    end)
  end
end)
control("Team color",510,-442,100,function()
  local team=chosen(); if not team or not FT:CanManage(team,me()) then return end
  local index=1
  for i,color in ipairs(FT.colors) do if color.name == team.color then index=i; break end end
  FT:Act("COLOR",team.id,FT.colors[index % #FT.colors + 1].name)
end)
function FT:Draw()
  if not panel:IsShown() then return end
  local list=sortedTeams()
  for i,b in ipairs(teamRows) do
    local team=list[i]
    b.teamID=team and team.id
    b:SetShown(team ~= nil)
    if team then
      b:SetText((team.id == FT.selected and "● " or "  ") .. team.name)
      if team.id == FT.selected then b:LockHighlight() else b:UnlockHighlight() end
      b:GetFontString():SetTextColor(tonumber(FT:Color(team.color).hex:sub(1,2),16)/255,
        tonumber(FT:Color(team.color).hex:sub(3,4),16)/255,
        tonumber(FT:Color(team.color).hex:sub(5,6),16)/255)
    end
  end
  local team=chosen()
  if not team then
    header:SetText("Choose a team or create one")
    message:SetText("Join multiple teams. Team data syncs among guild members running EXIN Teams.")
    accent:SetVertexColor(0.61, 0.86, 0.25)
  else
    header:SetText("|cff" .. FT:Color(team.color).hex .. team.name .. "|r  •  " .. (team.focus or "General"))
    message:SetText("|cff8b9b8bLeader:|r " .. team.owner .. "\n" .. (team.motd or ""))
    local hex=FT:Color(team.color).hex
    accent:SetVertexColor(tonumber(hex:sub(1,2),16)/255, tonumber(hex:sub(3,4),16)/255, tonumber(hex:sub(5,6),16)/255)
  end
  local members=team and sortedMembers(team) or {}
  rosterTitle:SetText("|cff9bdd00ROSTER|r  |cff8b9b8b"..#members.." members|r")
  for i,t in ipairs(rosterRows) do
    local who=members[i]
    rosterHover[i].who=who
    rosterHover[i]:SetShown(who ~= nil)
    if who then
      local data=FT.roster[who]
      local profile=FT.profiles[who]
      local dungeonRole=profile and ("  |cffc9d5df"..profile.main..(profile.off ~= "None" and "/"..profile.off or "").."|r") or "  |cff778899role unset|r"
      t:SetText(((who == me() or data and data.online) and "|cff44dd77●|r " or "|cff888888○|r ") ..
        (data and data.name or who) .. "  |cff9aabb4" .. team.members[who] .. "|r  " ..
        (data and data.class or "") .. dungeonRole)
    else t:SetText("") end
  end
  local requests={}
  if team and FT.requests[team.id] then for who in pairs(FT.requests[team.id]) do table.insert(requests,who) end end
  table.sort(requests)
  requestTitle:SetText("|cff9bdd00APPLICATIONS|r  |cff8b9b8b"..#requests.." pending|r")
  for i,t in ipairs(requestRows) do
    local who=requests[i]
    requestHover[i].who=who
    requestHover[i]:SetShown(who ~= nil)
    t:SetText(who and ("|cffd9e5d3"..who.."|r") or "")
    requestButtons[i].applicant=who
    requestButtons[i]:SetShown(who and team and FT:CanManage(team,me()) and true or false)
  end
  for i,t in ipairs(eventRows) do
    local event=team and team.events[#team.events-(i-1)]
    local attending=event and event.attendees and event.attendees[me()]
    local count=0
    if event then for _ in pairs(event.attendees or {}) do count=count+1 end end
    t:SetText(event and (event.when and ("|cff9aabb4"..event.when.."|r  "..event.title.."  |cff8b9b8b("..count.." going)|r") or event.text or "") or "")
    eventButtons[i].eventID=event and event.id
    eventButtons[i].attending=attending
    eventButtons[i]:SetShown(event and event.id and team.members[me()] and true or false)
    eventButtons[i]:SetText(attending and "Leave" or "Join")
  end
  for _,b in ipairs(controls) do b:SetEnabled(team ~= nil) end
  local isMember=team and team.members[me()]
  local pending=team and FT.requests[team.id] and FT.requests[team.id][me()]
  applyButton:SetText(pending and "Pending" or "Apply")
  applyButton:SetEnabled(team and not isMember and not pending and true or false)
  joinButton:SetEnabled(team and not isMember and FT.invitations[team.id] and FT.invitations[team.id][me()] and true or false)
  local own=FT.profiles[me()]
  mainRoleButton:SetText("Main: "..(own and own.main or "choose"))
  offRoleButton:SetText("Off: "..(own and own.off or "None"))
end
SLASH_FOREVERTEAMS1 = "/teams"
SLASH_FOREVERTEAMS2 = "/exin"
SlashCmdList.FOREVERTEAMS = function()
  if panel:IsShown() then panel:Hide()
  elseif FT:OpenGuild() then panel:Show(); FT:Refresh() end
end
