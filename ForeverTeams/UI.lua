local _, FT = ...
local panel = CreateFrame("Frame", "ForeverTeamsPanel", UIParent, "BackdropTemplate")
panel:SetSize(780, 620)
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
local teamPage = CreateFrame("Frame", nil, panel)
teamPage:SetAllPoints(panel)
local attunementPage = CreateFrame("Frame", nil, panel)
attunementPage:SetAllPoints(panel)
local questPageFrame = CreateFrame("Frame", nil, panel)
questPageFrame:SetAllPoints(panel)
local guildActivityPage = CreateFrame("Frame",nil,panel)
guildActivityPage:SetAllPoints(panel)
local function card(parent, x, y, width, height)
  local border = parent:CreateTexture(nil, "BACKGROUND")
  border:SetTexture("Interface\\Buttons\\WHITE8X8")
  border:SetPoint("TOPLEFT", x, y)
  border:SetSize(width, height)
  border:SetVertexColor(0.20, 0.26, 0.22, 0.95)
  local fill = parent:CreateTexture(nil, "BACKGROUND", nil, 1)
  fill:SetTexture("Interface\\Buttons\\WHITE8X8")
  fill:SetPoint("TOPLEFT", x+1, y-1)
  fill:SetSize(width-2, height-2)
  fill:SetVertexColor(0.08, 0.10, 0.13, 0.95)
end
card(teamPage, 12, -40, 185, 530)
card(teamPage, 202, -40, 495, 87)
card(teamPage, 202, -168, 495, 185)
card(teamPage, 202, -357, 495, 78)
card(teamPage, 202, -468, 495, 100)
local accent = teamPage:CreateTexture(nil, "BACKGROUND", nil, 2)
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
local title = line(panel, 20, -17, 250)
title:SetText("|cff9bdd00EXIN TEAMS|r  |cff8b9b8bEx Inferno|r")
local versionLabel=line(panel,665,-598,95,"small")
versionLabel:SetJustifyH("RIGHT")
versionLabel:SetText("|cff8b9b8bv"..FT.versionString.."|r")
local function button(parent, label, x, y, w, fn)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(w, 24)
  b:SetPoint("TOPLEFT", x, y)
  b:SetText(label)
  b:SetScript("OnClick", fn)
  return b
end
local closeButton = button(panel, "X", 735, -14, 25, function() panel:Hide() end)
closeButton:SetFrameLevel(panel:GetFrameLevel()+10)
local function rankCheck()
  local own=FT:SelfName()
  local guildName,rank,index=GetGuildInfo("player")
  local entry=FT.roster[own]
  local status="EXIN Teams v"..FT.versionString.."\nGuild: "..tostring(guildName)..
    "\nCharacter: "..own.."\nGame rank: "..tostring(rank).." (#"..tostring(index)..")"..
    "\nRoster rank: "..tostring(entry and entry.rank or "not loaded")..
    " (#"..tostring(entry and entry.rankID or "not loaded")..")"..
    "\nGuild admin: "..(FT:IsGuildOfficer(own) and "YES" or "NO")
  StaticPopupDialogs.FOREVER_TEAMS_RANK_CHECK={text="%s",button1=OKAY or "OK",timeout=0,
    whileDead=true,hideOnEscape=true,preferredIndex=3}
  StaticPopup_Show("FOREVER_TEAMS_RANK_CHECK",status)
end
StaticPopupDialogs.EXIN_TEAMS_VERSION_STATUS={text="%s",button1=OKAY or "OK",timeout=0,
  whileDead=true,hideOnEscape=true,preferredIndex=3}
function FT:ShowVersionStatus(status)
  StaticPopup_Show("EXIN_TEAMS_VERSION_STATUS",status)
end
button(panel,"Check version",20,-584,105,function() FT:CheckVersion() end)
local currentPage = "teams"
local drawGuildActivity
local pageFrames = {teams=teamPage, attunements=attunementPage, quests=questPageFrame,activity=guildActivityPage}
local pageButtons = {}
local function selectPage(name)
  currentPage = name
  for key, page in pairs(pageFrames) do page:SetShown(key == name) end
  for key, tab in pairs(pageButtons) do
    if key == name then tab:LockHighlight() else tab:UnlockHighlight() end
  end
  FT:Refresh()
end
pageButtons.teams = button(panel, "Teams", 215, -12, 70, function() selectPage("teams") end)
local calendarTab=button(panel,"Calendar",290,-12,85,function()
  if FT.ShowCalendar then FT:ShowCalendar() end
end)
pageButtons.attunements = button(panel, "Attunements", 380, -12, 100, function() selectPage("attunements") end)
pageButtons.quests = button(panel, "Dungeon quests", 485, -12, 105, function() selectPage("quests") end)
pageButtons.activity = button(panel,"All activity",595,-12,100,function() selectPage("activity") end)
calendarTab:SetFrameLevel(panel:GetFrameLevel()+10)
for _, tab in pairs(pageButtons) do tab:SetFrameLevel(panel:GetFrameLevel()+10) end
pageButtons.teams:LockHighlight()
attunementPage:Hide()
questPageFrame:Hide()
guildActivityPage:Hide()
local recruitment=CreateFrame("Frame",nil,UIParent,"BackdropTemplate")
recruitment:SetSize(500,285)
recruitment:SetPoint("CENTER")
recruitment:SetFrameStrata("FULLSCREEN_DIALOG")
recruitment:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",edgeSize=24,
  insets={left=8,right=8,top=8,bottom=8}})
recruitment:SetBackdropColor(0.035,0.045,0.06,0.98)
recruitment:SetBackdropBorderColor(0.34,0.45,0.25,1)
recruitment:Hide()
local recruitTitle=line(recruitment,20,-18,450)
recruitTitle:SetText("|cff9bdd00GUILD RECRUITMENT|r  |cff8b9b8bTrade chat|r")
local recruitHelp=line(recruitment,20,-45,450,"small")
recruitHelp:SetText("Paste your message below (up to 240 characters). Save or post it manually.")
local recruitBorder=CreateFrame("Frame",nil,recruitment,"BackdropTemplate")
recruitBorder:SetPoint("TOPLEFT",20,-74)
recruitBorder:SetSize(460,133)
recruitBorder:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12,
  insets={left=3,right=3,top=3,bottom=3}})
recruitBorder:SetBackdropColor(0.075,0.095,0.12,1)
recruitBorder:SetBackdropBorderColor(0.34,0.45,0.25,1)
local recruitBox=CreateFrame("EditBox",nil,recruitBorder)
recruitBox:SetPoint("TOPLEFT",14,-14)
recruitBox:SetSize(430,105)
recruitBox:SetMultiLine(true)
recruitBox:SetMaxLetters(240)
recruitBox:SetAutoFocus(false)
recruitBox:SetFontObject(ChatFontNormal)
recruitBox:SetTextColor(1,1,1)
recruitBox:SetJustifyH("LEFT")
recruitBox:SetJustifyV("TOP")
recruitBox:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
local recruitCount=line(recruitment,380,-211,96,"small")
recruitCount:SetJustifyH("RIGHT")
recruitBox:SetScript("OnTextChanged",function(self)
  recruitCount:SetText(#self:GetText().." / 240")
end)
local function saveRecruitment()
  if FT.db then FT.db.recruitment=recruitBox:GetText() end
end
button(recruitment,"Save",235,-239,70,function() saveRecruitment(); FT:Notice("Recruitment message saved.") end)
button(recruitment,"Post to Trade",310,-239,110,function()
  local messageText=recruitBox:GetText():match("^%s*(.-)%s*$")
  if not messageText or messageText=="" then FT:Notice("Write a recruitment message first."); return end
  if not GetChannelList or not (C_ChatInfo and C_ChatInfo.SendChatMessage) and not SendChatMessage then
    FT:Notice("Trade chat is unavailable."); return
  end
  local channels={GetChannelList()}
  local channelID
  for i=1,#channels,3 do
    if type(channels[i+1])=="string" and channels[i+1]:lower():find("trade",1,true) then
      channelID=channels[i]; break
    end
  end
  if not channelID then FT:Notice("Join Trade chat before posting your message."); return end
  if recruitment.lastPost and GetTime()-recruitment.lastPost < 60 then
    FT:Notice("Wait a minute before posting again."); return
  end
  saveRecruitment()
  if C_ChatInfo and C_ChatInfo.SendChatMessage then
    C_ChatInfo.SendChatMessage(messageText,"CHANNEL",nil,channelID)
  else SendChatMessage(messageText,"CHANNEL",nil,channelID) end
  recruitment.lastPost=GetTime()
end)
button(recruitment,"Close",425,-239,60,function() recruitment:Hide() end)
local recruitButton=button(panel,"Recruitment",130,-584,110,function()
  if not FT.db then FT:OpenGuild() end
  recruitBox:SetText(FT.db and FT.db.recruitment or "")
  recruitment:Show()
end)
recruitButton:SetFrameLevel(panel:GetFrameLevel()+10)
local header = line(teamPage, 210, -50, 470)

header:SetFontObject(GameFontNormalLarge)
local message = line(teamPage, 210, -78, 475, "small")
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
local function me() return FT:SelfName() end
local function canSee(team) return FT:CanSeeDetails(team, me()) end
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
  local f=CreateFrame("Frame",nil,teamPage)
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
local newTeamButton=button(teamPage, "New team", 20, -44, 85, function()
  if not FT:CanCreate(me()) then FT:Notice("Only guild officers or Team Leaders with a valid guild note can create teams."); return end
  ask("Team name (up to 24 characters)", "", function(name)
    name = name:match("^%s*(.-)%s*$")
    if #name < 2 or #name > 24 then FT:Notice("Use a name of 2–24 characters."); return end
    local id = me() .. "-" .. tostring(time()) .. "-" .. tostring(math.floor(GetTime() * 1000) % 100000)
    local color=FT:LeaderColor(me()) or "White"
    if not FT:CanOwnTeam(me(),name,color) then
      FT:Notice("Your guild note must name this team or its color before you can create it."); return
    end
    FT:Act("NEW", id, name, "General", "Welcome to " .. name, me(), color)
    if FT.teams[id] then FT.selected = id; FT:Refresh() end
  end)
end)
button(teamPage, "Refresh", 110, -44, 75, function()
  if FT:OpenGuild() then FT:CheckConnection() end
  FT:Refresh()
end)
local teamLabel = line(teamPage, 22, -82, 170, "small")
teamLabel:SetText("|cff9bdd00YOUR TEAMS|r")
local otherTeamLabel = line(teamPage, 22, -105, 170, "small")
otherTeamLabel:SetText("|cff9bdd00OTHER TEAMS|r")
local teamPageIndex=1
for i=1,10 do
  teamRows[i] = button(teamPage, "", 20, -100-(i-1)*28, 170, function(self)
    FT.selected = self.teamID; FT:Refresh()
  end)
end
local teamListPage=line(teamPage,77,-400,65,"small")
button(teamPage,"<",20,-392,40,function()
  if teamPageIndex > 1 then teamPageIndex=teamPageIndex-1; FT:Refresh() end
end)
button(teamPage,">",147,-392,40,function()
  teamPageIndex=teamPageIndex+1; FT:Refresh()
end)
local roleTitle = line(teamPage, 22, -433, 170, "small")
roleTitle:SetText("|cff9bdd00DUNGEON ROLES|r")
local mainRoleButton = button(teamPage, "Main: choose", 20, -450, 170, function()
  local profile = FT.profiles[me()] or {main="DPS", off="None"}
  local order = {"Tank", "Healer", "DPS"}
  local index = 0
  for i, value in ipairs(order) do if value == profile.main then index = i end end
  FT:Act("PROFILE", me(), order[index % #order + 1], profile.off)
end)
local offRoleButton = button(teamPage, "Off: none", 20, -480, 170, function()
  local profile = FT.profiles[me()] or {main="DPS", off="None"}
  local order = {"None", "Tank", "Healer", "DPS"}
  local index = 1
  for i, value in ipairs(order) do if value == profile.off then index = i end end
  FT:Act("PROFILE", me(), profile.main, order[index % #order + 1])
end)

local participationButton=button(teamPage,"Join active roster",20,-510,170,function()
  local team=chosen()
  if team and team.owner==me() then
    FT:Act("PART",team.id,me(),team.members[me()] and "no" or "yes")
  end
end)
local deleteID
StaticPopupDialogs.FOREVER_TEAMS_DELETE = {
  text="Delete this team for all addon users? This cannot be undone.",
  button1=DELETE or "Delete", button2=CANCEL, timeout=0, whileDead=true, hideOnEscape=true,
  OnAccept=function()
    local team=FT.teams[deleteID]
    if team and FT:CanDelete(team,me()) then FT:Act("DEL",team.id) end
    deleteID=nil
  end,
  OnCancel=function() deleteID=nil end,
}
local deleteButton=button(teamPage,"Delete team",20,-540,170,function()
  local team=chosen()
  if team and FT:CanDelete(team,me()) then
    deleteID=team.id
    StaticPopup_Show("FOREVER_TEAMS_DELETE")
  end
end)
local rosterTitle = line(teamPage, 210, -175, 480)
local notesNeeded = button(teamPage,"Notes needed",570,-163,115,function() end)
notesNeeded:SetScript("OnEnter",function(self)
  GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
  GameTooltip:AddLine("Guild notes needed",1,0.82,0.35)
  for _, name in ipairs(self.missing or {}) do GameTooltip:AddLine(name,1,0.82,0.35) end
  GameTooltip:AddLine("Use Team - DiscordName in the guild member note.",1,1,1,true)
  GameTooltip:Show()
end)
notesNeeded:SetScript("OnLeave",function() GameTooltip:Hide() end)

rosterTitle:SetText("|cff9bdd00ROSTER|r")
for i=1,9 do
  rosterRows[i] = line(teamPage, 215, -195-(i-1)*19, 460, "small")
  rosterHover[i] = hover(213,-192-(i-1)*19,460,function(self)
    local profile=FT.profiles[self.who]
    if profile then GameTooltip:AddLine("Dungeon roles: "..profile.main.." / "..profile.off,0.8,0.85,1) end
    local info=FT.playerInfo[self.who]
    if info then
      GameTooltip:AddLine("Availability: "..info.availability,1,1,1,true)
      GameTooltip:AddLine("Interests: "..info.interest,1,1,1,true)
    end
    local entry=FT.roster[self.who]
    if not entry or not entry.noteTeam or not entry.discordName then
      GameTooltip:AddLine("Guild note needed: Team - DiscordName",1,0.82,0.35,true)
    end
    if entry and entry.discordName then GameTooltip:AddLine("Discord: "..entry.discordName,0.8,0.85,1,true) end
    if entry and entry.note ~= "" then GameTooltip:AddLine("Guild note: "..entry.note,0.8,0.85,1,true) end
  end)
end
local requestTitle = line(teamPage, 210, -365, 480)
requestTitle:SetText("|cff9bdd00APPLICATIONS|r")
local requestButtons = {}
for i=1,3 do
  requestRows[i] = line(teamPage, 215, -384-(i-1)*20, 340, "small")
  requestButtons[i] = button(teamPage, "Accept", 575, -378-(i-1)*20, 75, function(self)
    local team = chosen()
    if team and self.applicant and FT:CanManage(team, me()) then
      FT:Act("ACCEPT", team.id, self.applicant)
    end
  end)
  requestButtons[i]:SetHeight(18)
  requestHover[i] = hover(213,-381-(i-1)*20,350,function(self)
    local team=chosen()
    local request=FT.playerInfo[self.who] or (team and FT.requests[team.id] and FT.requests[team.id][self.who])
    if type(request)=="table" then
      GameTooltip:AddLine("Availability: "..(request.availability or "Not provided"),1,1,1,true)
      GameTooltip:AddLine("Interests: "..(request.interest or "Not provided"),1,1,1,true)
    end
  end)
end
local eventTitle = line(teamPage, 210, -475, 365)
eventTitle:SetText("|cff9bdd00TEAM EVENTS|r  |cff8b9b8bserver time|r")
card(guildActivityPage,20,-52,738,512)
local allActivityTitle=line(guildActivityPage,36,-66,680)
allActivityTitle:SetText("|cff9bdd00GUILD TEAM ACTIVITY|r  |cff8b9b8bUpdates from all visible teams|r")
local allActivityInfo=line(guildActivityPage,36,-96,685,"small")
allActivityInfo:SetText("Team changes and calendar events appear here. Member details remain restricted.")
local allActivityRows={}
for i=1,16 do
  local row=line(guildActivityPage,36,-128-(i-1)*25,700,"small")
  row:SetHeight(24)
  allActivityRows[i]=row
end
local allActivityIndex=1
local allActivityPages=line(guildActivityPage,349,-540,110,"small")
drawGuildActivity=function()
  local all={}
  for _,team in pairs(FT.teams) do
    for _,record in ipairs(team.activity or {}) do
      if type(record)=="table" and type(record.text)=="string" then
        table.insert(all,{at=record.at or 0,text=record.text,name=team.name or "Team",color=team.color})
      end
    end
  end
  table.sort(all,function(a,b)
    if a.at~=b.at then return a.at>b.at end
    if a.name~=b.name then return a.name<b.name end
    return a.text<b.text
  end)
  local pages=math.max(1,math.ceil(#all/#allActivityRows))
  allActivityIndex=math.min(allActivityIndex,pages)
  allActivityPages:SetText(allActivityIndex.." / "..pages)
  for i,row in ipairs(allActivityRows) do
    local entry=all[(allActivityIndex-1)*#allActivityRows+i]
    row:SetText(entry and ("|cff8b9b8b"..date("%m/%d %H:%M",entry.at).."|r  |cff"..
      FT:Color(entry.color).hex..entry.name.."|r  "..entry.text) or
      (#all==0 and i==1 and "No team activity has been recorded yet." or ""))
  end
end
button(guildActivityPage,"Previous",36,-531,92,function()
  if allActivityIndex>1 then allActivityIndex=allActivityIndex-1; drawGuildActivity() end
end)
button(guildActivityPage,"Next",625,-531,90,function()
  allActivityIndex=allActivityIndex+1; drawGuildActivity()
end)
local activityPanel=CreateFrame("Frame",nil,UIParent,"BackdropTemplate")
activityPanel:SetSize(610,420)
activityPanel:SetPoint("CENTER")
activityPanel:SetFrameStrata("FULLSCREEN_DIALOG")
activityPanel:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",edgeSize=24,
  insets={left=8,right=8,top=8,bottom=8}})
activityPanel:Hide()
local activityTitle=line(activityPanel,20,-20,550)
local activityRows={}
local activityPage=1
for i=1,12 do
  activityRows[i]=line(activityPanel,22,-56-(i-1)*27,565,"small")
  activityRows[i]:SetHeight(25)
end
local activityPageText=line(activityPanel,240,-383,130,"small")
local function drawActivity()
  local team=FT.teams[FT.selected]
  if not team or not FT:CanSeeDetails(team,me()) then activityPanel:Hide(); return end
  local entries=team.activity or {}
  local pages=math.max(1,math.ceil(#entries/#activityRows))
  if activityPage > pages then activityPage=pages end
  activityTitle:SetText("|cff9bdd00TEAM ACTIVITY|r  "..team.name)
  activityPageText:SetText("Page "..activityPage.." / "..pages)
  for i,row in ipairs(activityRows) do
    local record=entries[(activityPage-1)*#activityRows+i]
    row:SetText(record and ("|cff8b9b8b"..date("%m/%d %H:%M",record.at or time()).."|r  "..(record.text or "")) or
      (#entries == 0 and i == 1 and "No activity recorded yet." or ""))
  end
end
button(activityPanel,"Previous",25,-375,90,function() if activityPage>1 then activityPage=activityPage-1; drawActivity() end end)
button(activityPanel,"Next",390,-375,70,function() activityPage=activityPage+1; drawActivity() end)
button(activityPanel,"Close",480,-375,90,function() activityPanel:Hide() end)
local activityButton=button(teamPage,"Activity log",580,-470,105,function()
  activityPage=1
  drawActivity()
  if FT.teams[FT.selected] and FT:CanSeeDetails(FT.teams[FT.selected],me()) then activityPanel:Show() end
end)
local eventButtons = {}
for i=1,3 do
  eventRows[i] = line(teamPage, 215, -495-(i-1)*22, 350, "small")
  eventButtons[i] = button(teamPage,"Join",575,-489-(i-1)*22,75,function(self)
    local team=chosen()
    if team and team.members[me()] and self.eventID then
      FT:Act("RSVP",team.id,self.eventID,self.attending and "no" or "yes")
    end
  end)
end
local controls = {}
local function control(label,x,y,w,fn)
  local b=button(teamPage,label,x,y,w,fn)
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
            FT:Act("APPLY",teamID,me(),availability,interest)
            C_Timer.After(0.5,function() FT:Act("PREF",me(),availability,interest) end)
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
    local who=name:lower():gsub("%s+", "-")
    if not FT.roster[who] then FT:Notice("That character is not in the loaded guild roster.")
    elseif team.members[who] then FT:Notice("That character is already on this team's roster (possibly from their guild note).")
    else
      FT:Act("INVITE",team.id,who)
      FT:Notice("Invite sent to "..FT.roster[who].name..". Online players also receive a whisper.")
    end
  end)
end)
control("Add",495,-135,66,function()
  local team=chosen(); if not team or not FT:CanManage(team,me()) then return end
  ask("Guild member to add to the active roster (addon optional)", "", function(name)
    local who=name:lower():gsub("%s+", "-")
    if FT.roster[who] then FT:Act("ADD",team.id,who)
    else FT:Notice("That character is not in the loaded guild roster.") end
  end)
end)
control("Remove",565,-135,70,function()
  local team=chosen(); if not team or not FT:CanManage(team,me()) then return end
  ask("Member to remove", "", function(name) FT:Act("REMOVE",team.id,name:lower():gsub("%s+", "-")) end)
end)
control("Role",638,-135,48,function()
  local team=chosen(); if not team or not (FT:IsGuildOfficer(me()) or (team.owner == me() and FT:CanManage(team,me()))) then return end
  ask("Member name to toggle officer role", "", function(name)
    local who=name:lower():gsub("%s+", "-")
    if team.members[who] and who ~= team.owner then
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
control("Calendar",415,-442,90,function()
  if FT.ShowCalendar then FT:ShowCalendar() end
end)
control("Team color",510,-442,100,function()
  local team=chosen(); if not team or not FT:CanManage(team,me()) then return end
  local index=1
  for i,color in ipairs(FT.colors) do if color.name == team.color then index=i; break end end
  FT:Act("COLOR",team.id,FT.colors[index % #FT.colors + 1].name)
end)
local transferButton=control("Transfer",615,-442,78,function()
  local team=chosen()
  if not team or not FT:IsGuildOfficer(me()) then return end
  local teamID=team.id
  ask("New team leader's full character name", "", function(name)
    local who=name:match("^%s*(.-)%s*$"):lower():gsub("%s+","-")
    if not FT.roster[who] then FT:Notice("Choose a character in the loaded guild roster."); return end
    if not FT.teams[teamID] or FT.teams[teamID].owner==who then return end
    local stamp=tostring(time()*1000+math.floor(GetTime()*1000)%1000)
    FT:Act("TRANSFER",teamID,who,stamp)
  end)
end)

card(attunementPage, 12, -44, 190, 556)
card(attunementPage, 208, -44, 558, 556)
local attunementListTitle = line(attunementPage, 22, -55, 170, "small")
attunementListTitle:SetText("|cff9bdd00RAIDS|r")
local selectedAttunement = 1
local attunementButtons = {}
for index=1,#(FT.attunementData or {}) do
  attunementButtons[index] = button(attunementPage, "", 20, -75-(index-1)*30, 174, function(self)
    selectedAttunement = self.raidIndex
    FT:Refresh()
  end)
  attunementButtons[index].raidIndex = index
end
local attunementScope = line(attunementPage, 22, -272, 168, "small")
attunementScope:SetHeight(62)
attunementScope:SetJustifyV("TOP")
local attunementHelp = line(attunementPage, 22, -345, 168, "small")
attunementHelp:SetHeight(115)
attunementHelp:SetJustifyV("TOP")
attunementHelp:SetText("|cff9bdd00HOW IT WORKS|r\nEach player checks their own quest history and privately shares readiness with their teams and guild officers. No report means that character has not synced this version yet.")
button(attunementPage, "Refresh my status", 20, -560, 174, function()
  FT:UpdateAttunements(true)
  FT:Notice("Your raid readiness was refreshed and shared with the guild.")
end)
local attunementHeader = line(attunementPage, 220, -58, 530)
attunementHeader:SetFontObject(GameFontNormalLarge)
local attunementMeta = line(attunementPage, 220, -84, 530, "small")
local attunementRequirement = line(attunementPage, 220, -106, 530, "small")
attunementRequirement:SetHeight(48)
attunementRequirement:SetJustifyV("TOP")
local attunementSummary = line(attunementPage, 220, -162, 530, "small")
local attunementRows = {}
for index=1,17 do
  attunementRows[index] = line(attunementPage, 225, -188-(index-1)*22, 520, "small")
end

card(questPageFrame, 12, -44, 210, 556)
card(questPageFrame, 228, -44, 538, 556)
local dungeonListTitle = line(questPageFrame, 22, -55, 190, "small")
dungeonListTitle:SetText("|cff9bdd00FOREVER DUNGEONS|r")
local selectedDungeon = 1
local selectedQuestPage = 1
local dungeonButtons = {}
for index=1,#(FT.dungeonData or {}) do
  dungeonButtons[index] = button(questPageFrame, "", 20, -75-(index-1)*28, 194, function(self)
    selectedDungeon = self.dungeonIndex
    selectedQuestPage = 1
    FT:Refresh()
  end)
  dungeonButtons[index].dungeonIndex = index
end
button(questPageFrame, "Refresh quest status", 20, -562, 194, function()
  FT:RefreshQuestCache()
  FT:Refresh()
end)
local dungeonHeader = line(questPageFrame, 240, -58, 510)
dungeonHeader:SetFontObject(GameFontNormalLarge)
local dungeonMeta = line(questPageFrame, 240, -84, 510, "small")
local questLegend = line(questPageFrame, 240, -108, 510, "small")
questLegend:SetText("|cff44dd77Completed|r   |cffffcc55In quest log|r   |cffff7777Not completed|r   |cff778899Other faction/class|r")
local questPending = line(questPageFrame, 240, -150, 505)
questPending:SetHeight(90)
questPending:SetJustifyV("TOP")
local questRows = {}
for index=1,6 do
  local top = -142-(index-1)*67
  questRows[index] = {
    name=line(questPageFrame, 242, top, 505),
    pickup=line(questPageFrame, 252, top-20, 493, "small"),
  }
  questRows[index].pickup:SetHeight(40)
  questRows[index].pickup:SetJustifyV("TOP")
end
local questPageText = line(questPageFrame, 480, -568, 90, "small")
questPageText:SetJustifyH("CENTER")
local questPrev = button(questPageFrame, "Previous", 385, -561, 90, function()
  if selectedQuestPage > 1 then selectedQuestPage = selectedQuestPage - 1; FT:Refresh() end
end)
local questNext = button(questPageFrame, "Next", 575, -561, 90, function()
  selectedQuestPage = selectedQuestPage + 1
  FT:Refresh()
end)

local attunementLabels = {
  C="|cff44dd77Complete|r", P="|cffffcc55In progress|r", M="|cffff7777Missing|r",
  U="|cff9aabb4Not published|r", N="|cff9aabb4No report|r",
}
local questLabels = {
  C="|cff44dd77Completed|r", P="|cffffcc55In quest log|r",
  M="|cffff7777Not completed|r", X="|cff778899Not available|r",
}
local function attunementMembers()
  local members = {}
  local team = chosen()
  if team then
    if FT:CanSeeDetails(team,me()) then return sortedMembers(team), team.name end
    return {}, "Team members and guild officers only"
  end
  if not FT:IsGuildOfficer(me()) then return {me()}, "Your character" end
  for who in pairs(FT.roster) do table.insert(members, who) end
  local found
  for _, who in ipairs(members) do if who == me() then found = true end end
  if not found then table.insert(members, me()) end
  table.sort(members)
  return members, "Guild roster"
end
local function memberAttunementState(who, index)
  local raid = FT.attunementData[index]
  if raid and not raid.published then return "U" end
  local report = FT.attunements[who]
  if not report or report.version ~= (FT.progressVersion or 1) or type(report.states) ~= "string" then return "N" end
  local state = report.states:sub(index,index)
  return attunementLabels[state] and state or "N"
end
local function drawAttunements()
  local raid = FT.attunementData[selectedAttunement] or FT.attunementData[1]
  if not raid then return end
  local members, scope = attunementMembers()
  local counts = {C=0,P=0,M=0,U=0,N=0}
  local ordered = {}
  local priority = {M=1,P=2,N=3,C=4,U=5}
  for _, who in ipairs(members) do
    local state = memberAttunementState(who, selectedAttunement)
    counts[state] = (counts[state] or 0) + 1
    table.insert(ordered, {who=who,state=state})
  end
  table.sort(ordered, function(a,b)
    if priority[a.state] == priority[b.state] then return a.who < b.who end
    return priority[a.state] < priority[b.state]
  end)
  for index, raidButton in ipairs(attunementButtons) do
    local data = FT.attunementData[index]
    raidButton:SetText((index == selectedAttunement and "● " or "  ") .. data.name)
    if index == selectedAttunement then raidButton:LockHighlight() else raidButton:UnlockHighlight() end
  end
  attunementScope:SetText("|cff9bdd00TRACKING|r\n"..scope.."\n|cff8b9b8bSelect a team on the Teams tab to narrow this list.|r")
  attunementHeader:SetText(raid.name)
  attunementMeta:SetText("|cff9bdd00"..raid.size.."|r  •  "..raid.phase)
  attunementRequirement:SetText(raid.requirement)
  if raid.published then
    attunementSummary:SetText("|cffff7777"..counts.M.." missing|r   |cffffcc55"..counts.P.." in progress|r   |cff44dd77"..counts.C.." complete|r   |cff9aabb4"..counts.N.." no report|r")
  else
    attunementSummary:SetText("|cff9aabb4Requirements are not published, so nobody is marked missing.|r")
  end
  for index, row in ipairs(attunementRows) do
    local entry = ordered[index]
    if entry then
      local roster = FT.roster[entry.who]
      local display = roster and roster.name or entry.who
      local online = entry.who == me() or roster and roster.online
      row:SetText((online and "|cff44dd77●|r " or "|cff777777○|r ")..display.."  "..attunementLabels[entry.state])
    else
      row:SetText("")
    end
  end
end
local function drawQuests()
  FT:RefreshQuestCache()
  local dungeon = FT.dungeonData[selectedDungeon] or FT.dungeonData[1]
  if not dungeon then return end
  for index, dungeonButton in ipairs(dungeonButtons) do
    local data = FT.dungeonData[index]
    local suffix = ""
    if data.pending then
      suffix = " |cff778899(pending)|r"
    else
      local complete, eligible = 0, 0
      for _, quest in ipairs(data.quests or {}) do
        local state = FT:QuestState(quest)
        if state ~= "X" then eligible = eligible + 1 end
        if state == "C" then complete = complete + 1 end
      end
      suffix = " |cff778899"..complete.."/"..eligible.."|r"
    end
    dungeonButton:SetText((index == selectedDungeon and "● " or "  ")..(data.short or data.name)..suffix)
    if index == selectedDungeon then dungeonButton:LockHighlight() else dungeonButton:UnlockHighlight() end
  end
  dungeonHeader:SetText(dungeon.name)
  dungeonMeta:SetText("|cff9bdd00Group Finder "..(dungeon.finder or "TBA").."|r  •  Quest completion is for this character")
  local quests = dungeon.quests or {}
  local perPage = #questRows
  local pages = math.max(1, math.ceil(#quests/perPage))
  if selectedQuestPage > pages then selectedQuestPage = pages end
  questPending:SetText(dungeon.pending and ("|cffffcc55Quest data not published yet.|r\n\n"..(dungeon.note or "This entry will be updated when Forever exposes its quest IDs.")) or "")
  questPending:SetShown(dungeon.pending and true or false)
  for index, row in ipairs(questRows) do
    local quest = quests[(selectedQuestPage-1)*perPage+index]
    row.name:SetShown(quest ~= nil)
    row.pickup:SetShown(quest ~= nil)
    if quest then
      local state = FT:QuestState(quest)
      local restrictions = quest.side and (" • "..quest.side) or ""
      if quest.class then restrictions = restrictions.." • "..quest.class:sub(1,1)..quest.class:sub(2):lower() end
      row.name:SetText(questLabels[state].."  |cffffffff"..quest.name.."|r  |cff9aabb4Lv "..quest.level..restrictions.."|r")
      local details = "Starts: "..quest.pickup
      if quest.note then details = details.."\n|cff9aabb4"..quest.note.."|r" end
      row.pickup:SetText(details)
    end
  end
  questPageText:SetText("Page "..selectedQuestPage.." / "..pages)
  questPageText:SetShown(not dungeon.pending and #quests > 0)
  questPrev:SetShown(not dungeon.pending and pages > 1)
  questNext:SetShown(not dungeon.pending and pages > 1)
  questPrev:SetEnabled(selectedQuestPage > 1)
  questNext:SetEnabled(selectedQuestPage < pages)
end

local function drawTeams()
  local mine, others={},{}
  for _, team in ipairs(sortedTeams()) do
    if team.members[me()] or team.owner == me() then table.insert(mine,team)
    else table.insert(others,team) end
  end
  local list={}
  for _, team in ipairs(mine) do table.insert(list,{team=team,own=true}) end
  for _, team in ipairs(others) do table.insert(list,{team=team,own=false}) end
  local pages=math.max(1,math.ceil(#list/10))
  if teamPageIndex > pages then teamPageIndex=pages end
  local pageStart=(teamPageIndex-1)*10+1
  local ownCount=math.max(0,math.min(#mine-pageStart+1,10))
  teamLabel:SetText("|cff9bdd00YOUR TEAMS|r  |cff8b9b8b"..#mine.."|r")
  otherTeamLabel:SetText("|cff9bdd00OTHER TEAMS|r  |cff8b9b8b"..#others.."|r")
  otherTeamLabel:ClearAllPoints()
  otherTeamLabel:SetPoint("TOPLEFT",22,-102-ownCount*25)
  teamListPage:SetText(teamPageIndex.." / "..pages)
  for i,b in ipairs(teamRows) do
    local item=list[pageStart+i-1]
    local team=item and item.team
    b.teamID=team and team.id
    b:SetShown(team ~= nil)
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT",20,(item and item.own) and (-100-(i-1)*25) or (-120-(i-1)*25))
    if team then
      b:SetText((team.id == FT.selected and "● " or "  ") .. team.name)
      if team.id == FT.selected then b:LockHighlight() else b:UnlockHighlight() end
      b:GetFontString():SetTextColor(tonumber(FT:Color(team.color).hex:sub(1,2),16)/255,
        tonumber(FT:Color(team.color).hex:sub(3,4),16)/255,
        tonumber(FT:Color(team.color).hex:sub(5,6),16)/255)
    end
  end
  local team=chosen()
  if not team and #mine > 0 then
    FT.selected=mine[1].id
    team=mine[1]
  end
  if not team then
    header:SetText("Choose a team or create one")
    message:SetText("Join multiple teams. Team data syncs among guild members running EXIN Teams.")
    accent:SetVertexColor(0.61, 0.86, 0.25)
  else
    header:SetText("|cff" .. FT:Color(team.color).hex .. team.name .. "|r  •  " .. (team.focus or "General"))
    message:SetText("|cff8b9b8bLeader:|r " ..
      (FT.roster[team.owner] and FT.roster[team.owner].name or team.owner:gsub("%-"," ")) ..
      "\n" .. (team.motd or ""))
    local hex=FT:Color(team.color).hex
    accent:SetVertexColor(tonumber(hex:sub(1,2),16)/255, tonumber(hex:sub(3,4),16)/255, tonumber(hex:sub(5,6),16)/255)
  end
  local members=team and sortedMembers(team) or {}
  local missingNotes={}
  if team and canSee(team) then
    for _, who in ipairs(members) do
      local entry=FT.roster[who]
      if not entry or not entry.noteTeam or not entry.discordName then
        table.insert(missingNotes,entry and entry.name or who)
      end
    end
  end
  notesNeeded.missing=missingNotes
  activityButton:SetShown(team ~= nil and canSee(team) and true or false)
  notesNeeded:SetShown(team ~= nil and canSee(team) and #missingNotes > 0)
  notesNeeded:SetText("Notes needed ("..#missingNotes..")")
  newTeamButton:SetEnabled(FT:CanCreate(me()) and true or false)
  participationButton:SetShown(team and team.owner==me() and true or false)
  participationButton:SetText(team and team.members[me()] and "Leave active roster" or "Join active roster")
  deleteButton:SetShown(FT:CanDelete(team,me()) and true or false)
  transferButton:SetShown(team and FT:IsGuildOfficer(me()) and true or false)
  rosterTitle:SetText("|cff9bdd00ROSTER|r  |cff8b9b8b"..#members.." members|r")
  for i,t in ipairs(rosterRows) do
    local who=members[i]
    rosterHover[i].who=who
    rosterHover[i]:SetShown(who ~= nil and canSee(team) and true or false)
    if who then
      local data=FT.roster[who]
      local allowed=canSee(team)
      local needsNote=allowed and (not data or not data.noteTeam or not data.discordName)
      local profile=allowed and FT.profiles[who]
      local dungeonRole=not allowed and "" or profile and ("  |cffc9d5df"..profile.main..(profile.off ~= "None" and "/"..profile.off or "").."|r") or "  |cff778899role unset|r"
      t:SetText(((who == me() or data and data.online) and "|cff44dd77●|r " or "|cff888888○|r ") ..
        (needsNote and "|cffffcc55" or "|cffffffff") .. ((data and data.name or who):gsub("%-", " ")) .. "|r  |cff9aabb4" .. team.members[who] .. "|r  " ..
        (data and data.class or "") .. dungeonRole)
    else t:SetText("") end
  end
  local requests={}
  if team and FT:CanManage(team,me()) and FT.requests[team.id] then
    for who in pairs(FT.requests[team.id]) do table.insert(requests,who) end
  end
  table.sort(requests)
  requestTitle:SetText("|cff9bdd00APPLICATIONS|r  |cff8b9b8b"..#requests.." pending|r")
  for i,t in ipairs(requestRows) do
    local who=requests[i]
    requestHover[i].who=who
    requestHover[i]:SetShown(who ~= nil and canSee(team) and true or false)
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
function FT:Draw()
  if activityPanel:IsShown() then drawActivity() end
  if not panel:IsShown() then return end
  if currentPage == "activity" then
    drawGuildActivity()
  elseif currentPage == "attunements" then
    drawAttunements()
  elseif currentPage == "quests" then
    drawQuests()
  else
    drawTeams()
  end
end
function FT:Toggle()
  if panel:IsShown() then panel:Hide()
  elseif self:OpenGuild() then panel:Show(); self:Refresh() end
end
SLASH_FOREVERTEAMS1 = "/teams"
SLASH_FOREVERTEAMS2 = "/exin"
SlashCmdList.FOREVERTEAMS = function(command)
  if command and command:lower():match("^%s*rankcheck%s*$") then
    rankCheck()
    return
  end
  if command and command:lower():match("^%s*namecheck%s*$") then
    local own=FT:SelfName()
    local guild=FT.roster[own]
    FT:Notice("Name check: UnitFullName="..tostring(UnitFullName and UnitFullName("player"))..
      "; guild roster="..tostring(guild and guild.name or "not matched")..
      "; character key="..own)
    return
  end
  FT:Toggle()
end
