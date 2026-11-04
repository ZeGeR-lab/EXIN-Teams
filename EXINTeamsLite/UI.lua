local _, LT = ...
local panel=CreateFrame("Frame","EXINTeamsLitePanel",UIParent,"BackdropTemplate")
LT.panel=panel
panel:SetSize(760,560); panel:SetPoint("CENTER"); panel:SetFrameStrata("DIALOG")
panel:SetMovable(true); panel:EnableMouse(true); panel:RegisterForDrag("LeftButton")
panel:SetScript("OnDragStart",panel.StartMoving); panel:SetScript("OnDragStop",panel.StopMovingOrSizing)
panel:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",edgeSize=24,insets={left=8,right=8,top=8,bottom=8}})
panel:SetBackdropColor(0.025,0.035,0.05,0.98); panel:Hide()
local function label(parent,text,x,y,w,size)
  local fs=parent:CreateFontString(nil,"OVERLAY",size or "GameFontNormal")
  fs:SetPoint("TOPLEFT",x,y); fs:SetWidth(w or 300); fs:SetJustifyH("LEFT"); fs:SetText(text or ""); return fs
end
local function button(parent,text,x,y,w,fn)
  local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
  b:SetSize(w,24); b:SetPoint("TOPLEFT",x,y); b:SetText(text); b:SetScript("OnClick",fn); return b
end
local function ask(prompt,default,callback)
  StaticPopupDialogs.EXIN_LITE_INPUT={text=prompt,button1=ACCEPT,button2=CANCEL,hasEditBox=true,timeout=0,whileDead=true,hideOnEscape=true,preferredIndex=3,
    OnShow=function(d) local e=d.EditBox or d.editBox; if e then e:SetText(default or ""); e:SetFocus() end end,
    OnAccept=function(d) local e=d.EditBox or d.editBox; callback(e and e:GetText() or "") end}
  StaticPopup_Show("EXIN_LITE_INPUT")
end
label(panel,"|cff9bdd00EXIN TEAMS LITE|r",22,-20,350,"GameFontNormalLarge")
label(panel,"Guild team and roster management",22,-45,500,"GameFontHighlightSmall")
button(panel,"Close",665,-18,70,function() panel:Hide() end)
local search=CreateFrame("EditBox",nil,panel,"InputBoxTemplate")
search:SetSize(220,24); search:SetPoint("TOPLEFT",22,-78); search:SetAutoFocus(false); search:SetTextInsets(5,5,2,2)
search:SetScript("OnTextChanged",function() LT:Draw() end)
local teamList=CreateFrame("Frame",nil,panel); teamList:SetPoint("TOPLEFT",20,-115); teamList:SetSize(235,405)
local detail=CreateFrame("Frame",nil,panel); detail:SetPoint("TOPLEFT",270,-75); detail:SetSize(465,465)
local teamButtons,memberRows={},{}
local title=label(detail,"Select a team",0,0,430,"GameFontNormalLarge")
local meta=label(detail,"",0,-28,430,"GameFontHighlightSmall")
local emblemButton=button(detail,"Choose team emblem",0,-50,145,function()
  if not LT:CanManage(chosen(),LT:SelfName()) then return end
  emblemPicker:SetShown(not emblemPicker:IsShown())
end)
local emblemPicker=CreateFrame("Frame",nil,detail,"BackdropTemplate")
emblemPicker:SetPoint("TOPLEFT",0,-80); emblemPicker:SetSize(238,190)
emblemPicker:SetFrameStrata("DIALOG")
emblemPicker:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
emblemPicker:SetBackdropColor(0.025,0.035,0.05,0.98)
emblemPicker:Hide()
local pickerTitle=label(emblemPicker,"SELECT TEAM EMBLEM",8,-8,210,"GameFontNormal")
local emblemChoices={}
for i,entry in ipairs(LT.emblems) do
  local b=CreateFrame("Button",nil,emblemPicker,"UIPanelButtonTemplate")
  b:SetSize(34,27)
  local col=(i-1)%6; local row=math.floor((i-1)/6)
  b:SetPoint("TOPLEFT",8+col*37,-30-row*29)
  b.icon=b:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
  b.icon:SetPoint("CENTER")
  b.icon:SetText("|cff"..entry.hex.."✕|r")
  b.entry=entry
  b:SetScript("OnEnter",function(self)
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(self.entry.name.." ("..self.entry.id..")"); GameTooltip:Show()
  end)
  b:SetScript("OnLeave",GameTooltip_Hide)
  b:SetScript("OnClick",function(self)
    local team=chosen()
    if team and LT:CanManage(team,LT:SelfName()) then LT:Act("EMBLEM",team.id,self.entry.id) end
    emblemPicker:Hide()
  end)
  emblemChoices[i]=b
end
local function emblemText(team)
  local e=LT:Emblem(team and team.emblem or "E01")
  return "|cff"..e.hex.."✕|r"
end
local function sortedTeams()
  local t={}; for _,v in pairs(LT.teams) do table.insert(t,v) end
  table.sort(t,function(a,b) return (a.name or "")<(b.name or "") end); return t
end
local function sortedMembers(team)
  local t={}; for who in pairs(team and team.members or {}) do table.insert(t,who) end; table.sort(t); return t
end
local function memberDisplay(who)
  local m=LT.roster[who]; return m and m.name or who:gsub("-"," ")
end
local function chosen() return LT.teams[LT.selected] end
local function addTeam()
  if not LT:IsGuildOfficer(LT:SelfName()) then LT:Notice("Only the Guild Master or an authorized Officer can create teams."); return end
  ask("New team name (2–24 characters)","",function(name)
    name=(name or ""):match("^%s*(.-)%s*$")
    if #name<2 or #name>24 or name:find("[|\r\n]") then LT:Notice("Team name must be 2–24 characters."); return end
    local id=LT:SelfName().."-"..time().."-"..math.floor(GetTime()*1000)%100000
    LT:Act("NEW",id,name,"General","Welcome to "..name,LT:SelfName(),"White","E01")
    if LT.teams[id] then LT.selected=id end
    LT:Draw()
  end)
end
button(panel,"Create team",22,-520,105,addTeam)
button(panel,"Refresh",135,-520,80,function() LT:OpenGuild(); LT:CheckConnection(); LT:Draw() end)
local function addMember()
  local team=chosen(); if not team or not LT:CanManage(team,LT:SelfName()) then return end
  ask("Guild character to add to this team","",function(name)
    local who=name:lower():gsub("%s+","-")
    if not LT.roster[who] then LT:Notice("That character is not in the current guild roster."); return end
    LT:Act("ADD",team.id,who)
  end)
end
local function removeMember(who)
  local team=chosen(); if team and LT:CanManage(team,LT:SelfName()) then
    ask("Remove "..memberDisplay(who).." from "..team.name.."? Type the character name to confirm.",who:gsub("-"," "),function(confirm)
      if confirm:lower():gsub("%s+","-")==who then LT:Act("REMOVE",team.id,who) end
    end)
  end
end
local permissionsPanel=CreateFrame("Frame",nil,panel,"BackdropTemplate")
permissionsPanel:SetPoint("TOPLEFT",detail,"TOPLEFT",0,0); permissionsPanel:SetSize(465,465)
permissionsPanel:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background"})
permissionsPanel:SetBackdropColor(0.025,0.035,0.05,0.98); permissionsPanel:Hide()
label(permissionsPanel,"OFFICER PERMISSIONS",0,0,420,"GameFontNormalLarge")
label(permissionsPanel,"Guild Master and designated administrator only",0,-25,420,"GameFontHighlightSmall")
local permissionSearch=CreateFrame("EditBox",nil,permissionsPanel,"InputBoxTemplate")
permissionSearch:SetSize(270,24); permissionSearch:SetPoint("TOPLEFT",0,-52); permissionSearch:SetAutoFocus(false)
permissionSearch:SetTextInsets(5,5,2,2); permissionSearch:SetMaxLetters(48)
permissionSearch:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
local permissionScroll=CreateFrame("ScrollFrame",nil,permissionsPanel,"UIPanelScrollFrameTemplate")
permissionScroll:SetPoint("TOPLEFT",0,-86); permissionScroll:SetSize(430,315)
local permissionContent=CreateFrame("Frame",nil,permissionScroll)
permissionContent:SetSize(410,315); permissionScroll:SetScrollChild(permissionContent)
local permissionRows={}
local function drawPermissions()
  for _,row in ipairs(permissionRows) do row:Hide() end
  local q=(permissionSearch:GetText() or ""):lower()
  local names={}
  for who,m in pairs(LT.roster) do
    local display=(m.name or who):lower()
    if q=="" or display:sub(1,#q)==q then table.insert(names,who) end
  end
  table.sort(names,function(a,b) return (LT.roster[a].name or a)<(LT.roster[b].name or b) end)
  permissionContent:SetHeight(math.max(315,#names*30))
  for i,who in ipairs(names) do
    if not permissionRows[i] then
      local row=CreateFrame("Frame",nil,permissionContent); row:SetSize(405,27)
      row.name=label(row,"",0,0,245,"GameFontHighlight")
      row.action=button(row,"",270,-1,115,function(b)
        if not LT:IsGuildLeader(LT:SelfName()) then LT:Notice("Only the Guild Master or designated administrator can change Officer access."); return end
        local target=b.member
        LT:Act("AUTH",target,LT.authorizedOfficers[target] and "no" or "yes",tostring(time()))
        drawPermissions()
      end)
      permissionRows[i]=row
    end
    local row=permissionRows[i]; row:ClearAllPoints(); row:SetPoint("TOPLEFT",0,-(i-1)*30)
    local m=LT.roster[who]
    local isOfficer=LT.authorizedOfficers[who]~=nil
    row.name:SetText((m.online and "|cff44dd77●|r " or "|cff888888○|r ")..(m.name or who))
    row.action.member=who
    row.action:SetText(isOfficer and "Revoke Officer" or "Make Officer")
    row.action:SetEnabled(not LT:IsGuildLeader(who))
    row:Show()
  end
end
permissionSearch:SetScript("OnTextChanged",drawPermissions)
local backButton=button(permissionsPanel,"Back to teams",0,-420,120,function()
  permissionsPanel:Hide(); detail:Show()
end)
local function managePermissions()
  if not LT:IsGuildLeader(LT:SelfName()) then LT:Notice("Only the Guild Master or designated administrator can manage Officer permissions."); return end
  detail:Hide(); permissionsPanel:Show(); permissionSearch:SetText(""); drawPermissions()
end
button(panel,"Officer permissions",525,-520,130,managePermissions)
function LT:Draw()
  for _,b in ipairs(teamButtons) do b:Hide() end
  local query=(search:GetText() or ""):lower()
  local teams=sortedTeams()
  local visible={}
  for _,t in ipairs(teams) do if query=="" or t.name:lower():find(query,1,true) then table.insert(visible,t) end end
  for i,t in ipairs(visible) do
    if not teamButtons[i] then teamButtons[i]=button(teamList,"",0,-(i-1)*28,220,function(b) LT.selected=b.teamID; LT:Draw() end) end
    local b=teamButtons[i]; b.teamID=t.id; b:SetText(emblemText(t).." "..(LT.selected==t.id and "» " or "")..t.name.." ("..tostring((function() local n=0; for _ in pairs(t.members or {}) do n=n+1 end; return n end)())..")")
    b:ClearAllPoints(); b:SetPoint("TOPLEFT",0,-(i-1)*28); b:Show()
  end
  local team=chosen()
  if not team and visible[1] then self.selected=visible[1].id; team=visible[1] end
  title:SetText(team and (emblemText(team).." "..team.name) or "No teams available")
  emblemButton:SetShown(team~=nil and self:CanManage(team,self:SelfName()))
  if not team then emblemPicker:Hide() end
  meta:SetText(team and ("Leader: "..memberDisplay(team.owner).."   •   Focus: "..(team.focus or "General").."   •   "..(team.motd or "")) or
    "An authorized Officer can create the first team.")
  for _,r in ipairs(memberRows) do r:Hide() end
  if team then
    local canManage=self:CanManage(team,self:SelfName())
    for i,who in ipairs(sortedMembers(team)) do
      if not memberRows[i] then
        local row=CreateFrame("Frame",nil,detail); row:SetSize(440,25)
        row.name=label(row,"",0,0,300,"GameFontHighlight")
        row.remove=button(row,"Remove",350,-1,75,function(b) removeMember(b.member) end)
        memberRows[i]=row
      end
      local row=memberRows[i]; row:ClearAllPoints(); row:SetPoint("TOPLEFT",0,-65-(i-1)*27)
      local m=self.roster[who]
      row.name:SetText((m and m.online and "|cff44dd77●|r " or "|cff888888○|r ")..memberDisplay(who).."  |cff9aabb4"..(team.members[who] or "member").."|r")
      row.remove.member=who; row.remove:SetShown(canManage and who~=team.owner); row:Show()
    end
    if not team.addButton then team.addButton=button(detail,"Add guild member",0,-420,125,addMember) end
    team.addButton:SetShown(canManage)
    if not team.deleteButton then team.deleteButton=button(detail,"Delete team",135,-420,100,function()
      local t=chosen(); if t and LT:CanDelete(t,LT:SelfName()) then
        StaticPopupDialogs.EXIN_LITE_DELETE={text="Delete "..t.name.." for all addon users?",button1=DELETE or "Delete",button2=CANCEL,timeout=0,whileDead=true,hideOnEscape=true,OnAccept=function() LT:Act("DEL",t.id) end}
        StaticPopup_Show("EXIN_LITE_DELETE")
      end
    end) end
    team.deleteButton:SetShown(self:CanDelete(team,self:SelfName()))
  end
end
search:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)

SLASH_EXINTEAMLITE1 = "/exin"
SlashCmdList.EXINTEAMLITE = function() LT:Toggle() end
