local _, FT = ...
local function key(s) return (s or ""):lower():gsub("%s+","-") end
local function short(s) return (s or ""):gsub("%-"," ") end
local function label(parent,x,y,width)
  local t=parent:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  t:SetPoint("TOPLEFT",x,y); t:SetWidth(width); t:SetJustifyH("LEFT")
  return t
end
local function button(parent,title,x,y,w,fn)
  local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
  b:SetPoint("TOPLEFT",x,y); b:SetSize(w,23); b:SetText(title); b:SetScript("OnClick",fn)
  return b
end
local function field(parent,x,y,w,max)
  local box=CreateFrame("EditBox",nil,parent,"InputBoxTemplate")
  box:SetPoint("TOPLEFT",x,y); box:SetSize(w,22); box:SetMaxLetters(max or 70)
  box:SetAutoFocus(false); box:SetFontObject(ChatFontNormal)
  box:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
  return box
end
local function wrap(parent,w,h)
  local f=CreateFrame("Frame",nil,parent,"BackdropTemplate")
  f:SetSize(w,h); f:SetPoint("CENTER"); f:SetFrameStrata("FULLSCREEN_DIALOG")
  f:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",edgeSize=24,
    insets={left=8,right=8,top=8,bottom=8}})
  f:SetBackdropColor(0.035,0.045,0.06,0.98)
  f:SetBackdropBorderColor(0.34,0.45,0.25,1)
  f:Hide()
  return f
end
local function card(parent,x,y,w,h)
  local border=parent:CreateTexture(nil,"BACKGROUND")
  border:SetTexture("Interface\\Buttons\\WHITE8X8")
  border:SetPoint("TOPLEFT",x,y); border:SetSize(w,h)
  border:SetVertexColor(0.20,0.26,0.22,0.95)
  local fill=parent:CreateTexture(nil,"BACKGROUND",nil,1)
  fill:SetTexture("Interface\\Buttons\\WHITE8X8")
  fill:SetPoint("TOPLEFT",x+1,y-1); fill:SetSize(w-2,h-2)
  fill:SetVertexColor(0.08,0.10,0.13,0.96)
  return fill
end
local function accent(parent,x,y,w)
  local bar=parent:CreateTexture(nil,"BACKGROUND",nil,2)
  bar:SetTexture("Interface\\Buttons\\WHITE8X8")
  bar:SetPoint("TOPLEFT",x,y); bar:SetSize(w,3)
  bar:SetVertexColor(0.61,0.86,0.25,1)
end
local calendar=wrap(UIParent,790,620)
local editor=wrap(calendar,480,245)
local planner=wrap(calendar,580,610)
local attendancePanel=wrap(calendar,490,520)
card(calendar,12,-40,495,437)
card(calendar,512,-40,266,437)
card(calendar,12,-483,766,119)
accent(calendar,13,-41,493)
accent(calendar,513,-41,264)
accent(calendar,13,-484,764)
card(editor,14,-42,452,158)
accent(editor,15,-43,450)
card(attendancePanel,14,-48,462,408)
accent(attendancePanel,15,-49,460)
card(planner,14,-48,552,473)
accent(planner,15,-49,550)
-- Calendar buttons are created after these panels. Give dialogs an explicit
-- higher level so newly created day buttons never draw through a dialog.
for _,panel in ipairs({editor,planner,attendancePanel}) do
  panel:SetFrameLevel(calendar:GetFrameLevel()+100)
end
local function showPanel(panel)
  for _,other in ipairs({editor,planner,attendancePanel}) do
    if other~=panel then other:Hide() end
  end
  panel:Show()
  panel:Raise()
end
local today=date("*t")
local year,month=today.year,today.month
local day=string.format("%04d-%02d-%02d",year,month,today.day)
local mode="personal"
local selected=nil
local teamID=nil
local eventPage=1
local modeTabs={}
local function team()
  if teamID and FT.teams[teamID] then return FT.teams[teamID] end
  if FT.selected and FT.teams[FT.selected] then return FT.teams[FT.selected] end
end
local function entries()
  local result={}
  if mode=="personal" then
    for _, event in pairs(FT.personalEvents or {}) do
      if event.when and (event.owner==FT:SelfName() or event.invited and event.invited[FT:SelfName()]) then
        table.insert(result,{event=event,personal=true})
      end
    end
    -- Attending a team event also puts it on your personal calendar, without duplicating the event.
    for _, group in pairs(FT.teams) do
      for _, event in ipairs(group.events or {}) do
        if event.when and event.attendees and event.attendees[FT:SelfName()] then
          table.insert(result,{event=event,team=group})
        end
      end
    end
    for _, event in ipairs(FT.guildEvents or {}) do
      if event.when and event.attendees and event.attendees[FT:SelfName()] then
        table.insert(result,{event=event,guild=true})
      end
    end
  elseif mode=="guild" then
    for _, event in ipairs(FT.guildEvents or {}) do
      if event.when then table.insert(result,{event=event,guild=true}) end
    end
  else
    local group=team()
    for _, event in ipairs(group and group.events or {}) do
      if event.when then table.insert(result,{event=event,team=group}) end
    end
  end
  table.sort(result,function(a,b)
    return a.event.when==b.event.when and a.event.title<b.event.title or a.event.when<b.event.when
  end)
  return result
end
local header=label(calendar,20,-21,580)
header:SetFontObject(GameFontNormalLarge)
local sub=label(calendar,22,-501,750)
local eventHeading=label(calendar,525,-107,245)
eventHeading:SetText("|cff9bdd00EVENTS ON SELECTED DAY|r")
local dayHeader={"Sun","Mon","Tue","Wed","Thu","Fri","Sat"}
for i,name in ipairs(dayHeader) do label(calendar,20+(i-1)*69,-106,65):SetText(name) end
local dayButtons={}
local render
for index=1,42 do
  local col=(index-1)%7
  local row=math.floor((index-1)/7)
  dayButtons[index]=button(calendar,"",20+col*69,-125-row*58,65,function(self)
    if self.calendarDay then day=self.calendarDay; selected=nil; eventPage=1; render() end
  end)
  dayButtons[index]:SetHeight(52)
end
local eventRows={}
for i=1,6 do
  eventRows[i]=button(calendar,"",520,-130-(i-1)*47,248,function(self)
    selected=self.entry
    if selected then render() end
  end)
  eventRows[i]:SetHeight(42)
end
local detail=label(calendar,520,-519,250)
detail:SetHeight(29)
local pageText=label(calendar,601,-459,65)
local rsvpYes,rsvpNo,inviteButton,inviteBox,deleteButton,raidButton,raid20,raid40,guildCreateButton,attendanceButton
local function dateLabel(d)
  local year_,month_,day_=d:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
  local stamp=time({year=tonumber(year_),month=tonumber(month_),day=tonumber(day_),hour=12})
  return date("%a %b %d",stamp)
end
render=function()
  if not calendar:IsShown() then return end
  local group=team()
  header:SetText("|cff9bdd00EXIN CALENDAR|r  "..date("%B %Y",time({year=year,month=month,day=1,hour=12})))
  sub:SetText((mode=="personal" and "Personal calendar" or mode=="guild" and "Guild calendar" or
    "Team calendar: "..(group and group.name or "Select a team on the Teams tab"))..
    "  |cff8b9b8b• Calendar times use your client's local time|r")
  for name,tab in pairs(modeTabs) do
    if name==mode then tab:LockHighlight() else tab:UnlockHighlight() end
  end
  local first=time({year=year,month=month,day=1,hour=12})
  local offset=tonumber(date("%w",first))
  local days=tonumber(date("%d",time({year=year,month=month+1,day=0,hour=12})))
  local all=entries()
  for i,b in ipairs(dayButtons) do
    local n=i-offset
    local stamp=n>=1 and n<=days and string.format("%04d-%02d-%02d",year,month,n)
    b.calendarDay=stamp
    b:SetShown(stamp~=nil)
    if stamp then
      local count=0
      for _, entry in ipairs(all) do if entry.event.when:sub(1,10)==stamp then count=count+1 end end
      b:SetText((stamp==day and "|cff9bdd00["..n.."]|r" or tostring(n))..
        (count>0 and "\n|cffffcc55"..count.." event"..(count==1 and "" or "s").."|r" or ""))
      if stamp==day then b:LockHighlight() else b:UnlockHighlight() end
    else
      b:UnlockHighlight()
    end
  end
  local shown={}
  for _,entry in ipairs(all) do if entry.event.when:sub(1,10)==day then table.insert(shown,entry) end end
  local pages=math.max(1,math.ceil(#shown/#eventRows))
  if eventPage>pages then eventPage=pages end
  pageText:SetText(eventPage.." / "..pages)
  for i,b in ipairs(eventRows) do
    local entry=shown[(eventPage-1)*#eventRows+i]
    b.entry=entry
    b:SetShown(entry~=nil)
    if entry and selected and entry.event==selected.event then b:LockHighlight() else b:UnlockHighlight() end
    if entry then
      local event=entry.event
      b:SetText("|cff"..(entry.team and FT:Color(entry.team.color).hex or "9bdd00")..event.when:sub(12).."|r  "..
        event.title.."\n|cff9aabb4"..(entry.team and entry.team.name or entry.guild and "Guild" or
          event.owner==FT:SelfName() and "Personal" or "Personal invite").."|r")
    end
  end
  local e=selected and selected.event
  local current=e and ((selected.personal and FT.personalEvents[e.id]) or
    (selected.team and FT.teams[selected.team.id] and (function()
      for _,event in ipairs(FT.teams[selected.team.id].events) do if event.id==e.id then return event end end
    end)()) or selected.guild and FT.guildEvents)
  if not current then selected=nil; e=nil end
  local self=FT:SelfName()
  local status=e and (e.attendees and e.attendees[self] and "Going" or e.declined and e.declined[self] and "Declined" or "No response")
  local count=0
  if e then for _ in pairs(e.attendees or {}) do count=count+1 end end
  detail:SetText(e and ("|cffffcc55"..e.title.."|r  ("..count.." going)\n"..status..
    (e.note and e.note~="" and (" · "..e.note) or "")) or
    ("|cff9aabb4"..dateLabel(day)..": choose an event or add one.|r"))
  local eligible=e and (selected.guild and FT.roster[self] or selected.team and selected.team.members[self] or selected.personal and
    e.invited and e.invited[self] and e.owner~=self)
  rsvpYes:SetShown(eligible and true or false)
  rsvpNo:SetShown(eligible and true or false)
  local ownPersonal=e and selected.personal and e.owner==self
  inviteButton:SetShown(ownPersonal and true or false)
  inviteBox:SetShown(ownPersonal and true or false)
  deleteButton:SetShown((ownPersonal or e and selected.guild and FT:IsGuildOfficer(self) or
    e and selected.team and FT:CanManage(selected.team,self)) and true or false)
  deleteButton:ClearAllPoints()
  deleteButton:SetPoint("TOPLEFT",520,ownPersonal and -545 or -575)
  guildCreateButton:SetShown(FT:IsGuildOfficer(self) and true or false)
  raidButton:SetShown(e and selected.team and e.raidSize and
    (FT:CanManage(selected.team,self) or selected.team.members[self]) and true or false)
  local canPlan=e and selected.team and FT:CanManage(selected.team,self)
  raid20:SetShown(canPlan and true or false)
  raid40:SetShown(canPlan and true or false)
  attendanceButton:SetShown(e and true or false)
end
button(calendar,"<",580,-17,32,function()
  month=month-1; if month<1 then month=12; year=year-1 end
  day=string.format("%04d-%02d-01",year,month); selected=nil; render()
end)
button(calendar,">",620,-17,32,function()
  month=month+1; if month>12 then month=1; year=year+1 end
  day=string.format("%04d-%02d-01",year,month); selected=nil; render()
end)
button(calendar,"Close",690,-17,80,function() calendar:Hide(); editor:Hide(); planner:Hide(); attendancePanel:Hide() end)
modeTabs.personal=button(calendar,"Personal",20,-75,100,function() mode="personal"; selected=nil; eventPage=1; render() end)
modeTabs.team=button(calendar,"Team",125,-75,100,function() mode="team"; selected=nil; eventPage=1; render() end)
modeTabs.guild=button(calendar,"Guild",230,-75,95,function() mode="guild"; selected=nil; eventPage=1; render() end)
button(calendar,"Previous",520,-447,75,function() if eventPage>1 then eventPage=eventPage-1; selected=nil; render() end end)
button(calendar,"Next",665,-447,75,function() eventPage=eventPage+1; selected=nil; render() end)
rsvpYes=button(calendar,"Yes, going",520,-545,105,function()
  if not selected then return end
  if selected.guild then FT:Act("GUILD_RSVP",selected.event.id,"yes")
  elseif selected.team then FT:Act("RSVP",selected.team.id,selected.event.id,"yes")
  else FT:RSVPPersonal(selected.event.id,true) end
  render()
end)
rsvpNo=button(calendar,"No",630,-545,55,function()
  if not selected then return end
  if selected.guild then FT:Act("GUILD_RSVP",selected.event.id,"no")
  elseif selected.team then FT:Act("RSVP",selected.team.id,selected.event.id,"no")
  else FT:RSVPPersonal(selected.event.id,false) end
  render()
end)
inviteBox=field(calendar,525,-568,155,80)
inviteBox:SetText("")
inviteButton=button(calendar,"Invite guildmate",685,-564,90,function()
  if selected and FT:InvitePersonal(selected.event.id,inviteBox:GetText()) then
    inviteBox:SetText(""); FT:Notice("Calendar invitation saved.")
  else FT:Notice("Enter a guild character's full name.") end
  render()
end)
deleteButton=button(calendar,"Delete event",520,-545,110,function()
  if selected then
    if selected.guild and FT:IsGuildOfficer(FT:SelfName()) then FT:Act("GUILD_DEL",selected.event.id)
    elseif selected.team and FT:CanManage(selected.team,FT:SelfName()) then
      FT:Act("EVENT_DEL",selected.team.id,selected.event.id)
    elseif selected.personal then FT:RemovePersonal(selected.event.id) end
    selected=nil; render()
  end
end)
raidButton=button(calendar,"Planner",690,-545,80,function()
  if selected then FT:ShowRaidPlanner(selected.team,selected.event) end
end)
raid20=button(calendar,"Raid 20",300,-545,100,function()
  if selected and selected.team and FT:CanManage(selected.team,FT:SelfName()) then
    FT:Act("RAID_SIZE",selected.team.id,selected.event.id,"20"); render()
  end
end)
raid40=button(calendar,"Raid 40",405,-545,100,function()
  if selected and selected.team and FT:CanManage(selected.team,FT:SelfName()) then
    FT:Act("RAID_SIZE",selected.team.id,selected.event.id,"40"); render()
  end
end)
local editorTitle=label(editor,20,-20,440)
editorTitle:SetFontObject(GameFontNormalLarge)
label(editor,25,-60,80):SetText("Title")
local titleBox=field(editor,85,-55,350,70)
label(editor,25,-95,150):SetText("Time (HH:MM)")
local timeBox=field(editor,150,-90,90,5)
label(editor,25,-129,100):SetText("Note")
local noteBox=field(editor,85,-124,350,60)
local editorKind="personal"
local function openEditor(kind)
  if kind=="team" and (not team() or not FT:CanManage(team(),FT:SelfName())) then
    FT:Notice("Select a team you manage before creating its event."); return
  end
  if kind=="guild" and not FT:IsGuildOfficer(FT:SelfName()) then return end
  editorKind=kind
  editorTitle:SetText("|cff9bdd00NEW "..kind:upper().." EVENT|r")
  titleBox:SetText(""); timeBox:SetText("19:00"); noteBox:SetText("")
  noteBox:SetShown(kind=="personal")
  showPanel(editor)
end
button(calendar,"+ Personal event",20,-545,140,function() openEditor("personal") end)
button(calendar,"+ Team event",165,-545,130,function() openEditor("team") end)
guildCreateButton=button(calendar,"+ Guild event",300,-575,135,function() openEditor("guild") end)

local attendanceTitle=label(attendancePanel,20,-24,445)
attendanceTitle:SetFontObject(GameFontNormalLarge)
local attendanceRows={}
for i=1,15 do attendanceRows[i]=label(attendancePanel,25,-65-(i-1)*26,440) end
local attendancePage=1
local attendancePageText=label(attendancePanel,220,-467,120)
local function drawAttendance()
  if not selected or not selected.event then attendancePanel:Hide(); return end
  local event=selected.event
  attendanceTitle:SetText("|cff9bdd00ATTENDANCE|r  "..event.title)
  local people={}
  for who in pairs(event.attendees or {}) do table.insert(people,{who=who,status="Going"}) end
  for who in pairs(event.declined or {}) do table.insert(people,{who=who,status="Declined"}) end
  table.sort(people,function(a,b) return a.status==b.status and a.who<b.who or a.status>b.status end)
  local pages=math.max(1,math.ceil(#people/#attendanceRows))
  if attendancePage>pages then attendancePage=pages end
  attendancePageText:SetText(attendancePage.." / "..pages)
  for i,row in ipairs(attendanceRows) do
    local person=people[(attendancePage-1)*#attendanceRows+i]
    row:SetText(person and ((person.status=="Going" and "|cff77dd77Going|r  " or "|cffff7777Declined|r  ")..
      short(person.who)) or (i==1 and #people==0 and "No responses yet." or ""))
  end
end
button(attendancePanel,"Previous",25,-458,90,function()
  if attendancePage>1 then attendancePage=attendancePage-1; drawAttendance() end
end)
button(attendancePanel,"Next",340,-458,55,function() attendancePage=attendancePage+1; drawAttendance() end)
button(attendancePanel,"Close",400,-458,65,function() attendancePanel:Hide() end)
attendanceButton=button(calendar,"Attendance",685,-500,90,function()
  if selected then attendancePage=1; showPanel(attendancePanel); drawAttendance() end
end)
button(editor,"Create",260,-185,90,function()
  local title=titleBox:GetText():match("^%s*(.-)%s*$")
  local hh,mm=timeBox:GetText():match("^(%d%d):(%d%d)$")
  if #title<2 or #title>70 or not hh or tonumber(hh)>23 or tonumber(mm)>59 then
    FT:Notice("Use a title and time such as 19:00."); return
  end
  local when=day.." "..hh..":"..mm
  if editorKind=="personal" then FT:NewPersonalEvent(when,title,noteBox:GetText())
  elseif editorKind=="guild" then
    local id=FT:SelfName().."-"..tostring(time()).."-"..tostring(math.floor(GetTime()*1000)%100000)
    FT:Act("GUILD_EVENT",id,when,title)
  else
    local group=team()
    local id=FT:SelfName().."-"..tostring(time()).."-"..tostring(math.floor(GetTime()*1000)%100000)
    FT:Act("EVENT",group.id,id,when,title)
  end
  editor:Hide(); render()
end)
button(editor,"Cancel",365,-185,90,function() editor:Hide() end)

local planTeam,planEvent,planPage
local planTitle=label(planner,22,-21,540)
planTitle:SetFontObject(GameFontNormalLarge)
local planHint=label(planner,22,-53,540)
planHint:SetText("Assign confirmed attendees to five-person groups. Click a slot to assign or clear it.")
local planRows={}
local slot
local drawPlan
for i=1,20 do
  planRows[i]=button(planner,"",22+(i-1)%5*108,-87+math.floor((i-1)/5)*(-88),104,function(self)
    if not planEvent or not FT:CanManage(planTeam,FT:SelfName()) then return end
    slot=self.slot
    if slot then FT:Notice("Selected slot "..slot..". Type a confirmed character below and click Assign.") end
  end)
  planRows[i]:SetHeight(74)
end
local planPageText=label(planner,250,-454,160)
local assignBox=field(planner,25,-492,220,80)
local function refreshPlan()
  local group=FT.teams[planTeam and planTeam.id]
  if not group or not FT:CanSeeDetails(group,FT:SelfName()) then planner:Hide(); return end
  local current
  for _,item in ipairs(group.events or {}) do if item.id==planEvent.id then current=item; break end end
  if not current then planner:Hide(); return end
  planTeam,planEvent=group,current
  local groupCount=(current.raidSize or 20)/5
  if planPage>math.ceil(groupCount/4) then planPage=1 end
  planTitle:SetText("|cff9bdd00RAID PLANNER|r  "..current.title.."  ("..(current.raidSize or 20).." players)")
  planPageText:SetText("Groups "..((planPage-1)*4+1).."–"..math.min(planPage*4,groupCount))
  for i,b in ipairs(planRows) do
    local index=(planPage-1)*20+i
    local groupNo=math.floor((index-1)/5)+1
    b.slot=groupNo<=groupCount and index or nil
    b:SetShown(b.slot~=nil)
    if b.slot then
      local who=current.slots and current.slots[index]
      b:SetText("Group "..groupNo.." · "..((index-1)%5+1).."\n"..(who and short(who) or "—"))
    end
  end
end
drawPlan=refreshPlan
function FT:ShowRaidPlanner(group,event)
  if not group or not event or not event.raidSize or not self:CanSeeDetails(group,self:SelfName()) then return end
  planTeam,planEvent,planPage=group,event,1
  slot=nil; assignBox:SetText("")
  showPanel(planner); drawPlan()
end
button(planner,"Other groups",25,-449,118,function()
  if planEvent and planEvent.raidSize==40 then planPage=planPage==1 and 2 or 1; drawPlan() end
end)
button(planner,"Assign",255,-486,75,function()
  if not slot or not planTeam or not planEvent or not FT:CanManage(planTeam,FT:SelfName()) then return end
  local who=key(assignBox:GetText():match("^%s*(.-)%s*$"))
  if not planEvent.attendees or not planEvent.attendees[who] then
    FT:Notice("Only confirmed attendees can be assigned."); return
  end
  FT:Act("RAID_SLOT",planTeam.id,planEvent.id,tostring(slot),who)
  drawPlan()
end)
button(planner,"Clear slot",337,-486,84,function()
  if slot and planTeam and planEvent and FT:CanManage(planTeam,FT:SelfName()) then
    FT:Act("RAID_SLOT",planTeam.id,planEvent.id,tostring(slot),"clear"); drawPlan()
  end
end)
button(planner,"Invite confirmed",24,-555,135,function()
  if not planTeam or not planEvent or not FT:CanManage(planTeam,FT:SelfName()) then return end
  if InCombatLockdown and InCombatLockdown() then FT:Notice("Invite after combat."); return end
  local invite=C_PartyInfo and C_PartyInfo.InviteUnit or InviteUnit
  if not invite then FT:Notice("Party invitations are unavailable on this client."); return end
  local present={}
  if GetNumGroupMembers then
    for i=1,GetNumGroupMembers() do
      local unit="raid"..i
      if not IsInRaid or not IsInRaid() then unit="party"..i end
      local name=UnitFullName and UnitFullName(unit) or UnitName(unit)
      if name then present[key(name)]=true end
      local guid=UnitGUID and UnitGUID(unit)
      if guid then for who, entry in pairs(FT.roster) do if entry.guid==guid then present[who]=true end end end
    end
  end
  local count=0
  local candidates={}
  for index=1,planEvent.raidSize or 0 do
    local who=planEvent.slots and planEvent.slots[index]
    local member=who and FT.roster[who]
    if member and member.online and not present[who] and planEvent.attendees and planEvent.attendees[who] and who~=FT:SelfName() then
      table.insert(candidates,{who=who,slot=index,officer=FT:IsGuildOfficer(who) or planTeam.members[who]=="officer"})
    end
  end
  table.sort(candidates,function(a,b)
    if a.officer~=b.officer then return a.officer end
    return a.slot<b.slot
  end)
  for _,candidate in ipairs(candidates) do
    local ok=pcall(invite,candidate.who)
    if ok then count=count+1 end
  end
  FT:Notice(count.." invitation attempts sent. Group placement depends on who accepts.")
end)
button(planner,"Convert to raid",166,-555,120,function()
  if InCombatLockdown and InCombatLockdown() then FT:Notice("Convert after combat."); return end
  local convert=C_PartyInfo and C_PartyInfo.ConvertToRaid or ConvertToRaid
  if convert and (not IsInGroup or IsInGroup()) then
    local ok=pcall(convert)
    FT:Notice(ok and "Raid conversion requested." or "Raid conversion was blocked by the game.")
  else FT:Notice("Form a party first, then convert it to a raid.") end
end)
button(planner,"Arrange groups",291,-555,120,function()
  if not planTeam or not planEvent or not FT:CanManage(planTeam,FT:SelfName()) then return end
  if InCombatLockdown and InCombatLockdown() then FT:Notice("Arrange groups after combat."); return end
  if not IsInRaid or not IsInRaid() or not SetRaidSubgroup then
    FT:Notice("Join a raid to arrange its groups."); return
  end
  local moved=0
  for memberIndex=1,GetNumGroupMembers() do
    local unit="raid"..memberIndex
    local name=UnitFullName and UnitFullName(unit) or UnitName(unit)
    local member=key(name)
    local guid=UnitGUID and UnitGUID(unit)
    if guid and not FT.roster[member] then
      for who, entry in pairs(FT.roster) do if entry.guid==guid then member=who; break end end
    end
    for slot, assigned in pairs(planEvent.slots or {}) do
      if assigned==member then
        local ok=pcall(SetRaidSubgroup,memberIndex,math.floor((slot-1)/5)+1)
        if ok then moved=moved+1 end
        break
      end
    end
  end
  FT:Notice("Placed "..moved.." raid members; remaining players can be placed after joining.")
end)
button(planner,"Close",468,-555,80,function() planner:Hide() end)

function FT:ShowCalendar()
  if not self.db and not self:OpenGuild() then return end
  local now=date("*t")
  year,month=now.year,now.month
  day=string.format("%04d-%02d-%02d",year,month,now.day)
  teamID=self.selected
  selected=nil; eventPage=1
  editor:Hide(); planner:Hide(); attendancePanel:Hide()
  calendar:Show(); render()
end
local oldRefresh=FT.Refresh
function FT:Refresh()
  oldRefresh(self)
  if calendar:IsShown() then render() end
  if attendancePanel:IsShown() then drawAttendance() end
  if planner:IsShown() then drawPlan() end
end
