local ADDON, LT = ...
_G.EXINTeamsLite = LT
LT.versionString = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON, "Version")) or "0.1.0"
LT.PREFIX = "FTeams1" -- Shared protocol with EXIN Teams Full.
LT.teams, LT.roster, LT.authorizedOfficers = {}, {}, {}
LT.selected, LT.db = nil, nil
LT.colors = {
  {name="Pink",hex="ff83b7"},{name="Purple",hex="aa89ff"},{name="Blue",hex="69b6ff"},
  {name="Green",hex="78d996"},{name="Yellow",hex="f7d96b"},{name="Orange",hex="ffab69"},
  {name="Red",hex="ff7777"},{name="White",hex="eeeeee"},{name="Black",hex="838b92"},
}
local frame = CreateFrame("Frame")
local function trim(s) return (s or ""):match("^%s*(.-)%s*$") end
local function norm(s) return trim(s):lower():gsub("%s+","-") end
local function guild() return GetGuildInfo("player") end
local function selfName()
  local name = UnitFullName and UnitFullName("player") or UnitName("player")
  return norm(name)
end
local function valid(s,n) return type(s)=="string" and #s>0 and #s<=n and not s:find("[|\r\n]") end
local function color(name)
  for _, c in ipairs(LT.colors) do if c.name:lower()==tostring(name or ""):lower() then return c.name end end
  return "White"
end
function LT:Color(name)
  for _, c in ipairs(self.colors) do if c.name==name then return c end end
  return self.colors[8]
end
function LT:Notice(s) print("|cff9bdd00EXIN Teams Lite:|r "..tostring(s)) end
function LT:SelfName() return selfName() end
function LT:IsGuildLeader(who)
  if norm(who)==selfName() and guild() then
    local g,_,rankID=GetGuildInfo("player")
    if g==guild() and tonumber(rankID)==0 then return true end
  end
  local m=self.roster[norm(who)]
  return m and tonumber(m.rankID)==0 or false
end
function LT:IsGuildOfficer(who)
  local key=norm(who)
  if self:IsGuildLeader(key) then return true end
  local m=self.roster[key]
  return m~=nil and self.authorizedOfficers[key]~=nil
end
function LT:IsTeamLeader(who, team)
  local m=self.roster[norm(who)]
  if not m or not m.noteTeam then return false end
  local rank=(m.rank or ""):lower()
  if rank=="team leader" then return not team or m.noteTeam:lower()==team.name:lower() or m.noteTeam:lower()==tostring(team.color):lower() end
  for _, c in ipairs(self.colors) do
    if rank=="team leader "..c.name:lower() and m.noteTeam:lower()==c.name:lower() then
      return not team or m.noteTeam:lower()==team.name:lower() or m.noteTeam:lower()==tostring(team.color):lower()
    end
  end
  return false
end
function LT:CanManage(team, who)
  if not team then return false end
  who=norm(who)
  return self:IsGuildOfficer(who) or team.owner==who or self:IsTeamLeader(who,team)
end
function LT:CanDelete(team, who) return team and self:IsGuildOfficer(who) end
local function emit(channel,target,op,...)
  if not guild() then return end
  local fields={op,...}
  for _,v in ipairs(fields) do if type(v)~="string" or v:find("[|\r\n]") then return end end
  local msg=table.concat(fields,"|")
  if #msg>240 then LT:Notice("A sync packet was too large and was not sent."); return end
  if C_ChatInfo and C_ChatInfo.SendAddonMessage then C_ChatInfo.SendAddonMessage(LT.PREFIX,msg,channel,target)
  elseif SendAddonMessage then SendAddonMessage(LT.PREFIX,msg,channel,target) end
end
local function send(op,...) emit("GUILD",nil,op,...) end
local function save()
  if not LT.db then return end
  LT.db.teams=LT.teams
  LT.db.authorizedOfficers=LT.authorizedOfficers
  LT.db.deleted=LT.deleted or {}
end
local function leaderRankName(rank)
  rank=(rank or ""):lower()
  if rank=="team leader" then return true end
  for _,c in ipairs(LT.colors) do if rank=="team leader "..c.name:lower() then return true end end
  return false
end
local function rosterRefresh()
  local total=GetNumGuildMembers and GetNumGuildMembers() or 0
  if total==0 then LT:Refresh(); return end
  wipe(LT.roster)
  for i=1,total do
    local name,rank,rankID,level,class,_,note,_,online,_,_,_,_,_,_,_,guid=GetGuildRosterInfo(i)
    if name then
      local team,discord=(note or ""):match("^%s*(.-)%s+%-%s+(.+)%s*$")
      if team=="" or not discord or trim(discord)=="" then team,discord=nil,nil end
      LT.roster[norm(name)]={name=name,rank=rank,rankID=rankID,level=level,class=class,note=note or "",
        noteTeam=team and trim(team),discordName=discord and trim(discord),online=online,guid=guid}
    end
  end
  -- Public guild notes define the primary membership. Additional memberships remain addon-managed.
  for id,team in pairs(LT.teams) do
    team.members=team.members or {}
    team.noteMembers=team.noteMembers or {}
    for who in pairs(team.noteMembers) do
      local m=LT.roster[who]
      if not m or not m.noteTeam or m.noteTeam:lower()~=tostring(team.name):lower() then
        team.noteMembers[who]=nil
        if team.members[who]=="member" then team.members[who]=nil end
      end
    end
    for who,m in pairs(LT.roster) do
      if m.noteTeam and (m.noteTeam:lower()==tostring(team.name):lower() or m.noteTeam:lower()==tostring(team.color):lower()) then
        team.members[who]=team.members[who] or "member"
        team.noteMembers[who]=true
      end
    end
  end
  -- Remove authorizations for characters no longer in the guild on this client.
  for who in pairs(LT.authorizedOfficers) do if not LT.roster[who] then LT.authorizedOfficers[who]=nil end end
  save()
  LT:Refresh()
end
local function findTeamByName(name)
  local key=trim(name):lower()
  for id,t in pairs(LT.teams) do if t.name:lower()==key or t.color:lower()==key then return id,t end end
end
local function apply(op,f,actor)
  actor=norm(actor)
  if op=="AUTH" then
    -- Only the current guild master may alter the replicated authorization list.
    if not LT:IsGuildLeader(actor) or not LT.roster[norm(f[2])] or (f[3]~="yes" and f[3]~="no") then return false end
    local target=norm(f[2])
    if f[3]=="yes" then
      LT.authorizedOfficers[target]={by=actor,at=tonumber(f[4]) or time()}
    else LT.authorizedOfficers[target]=nil end
    save(); LT:Refresh(); return true
  elseif op=="NEW" then
    local id,name,focus,motd,owner,teamColor=f[2],f[3],f[4],f[5],norm(f[6]),color(f[7])
    if not valid(id,48) or not valid(name,24) or not valid(focus,48) or not valid(motd,70) or owner~=actor or
      LT.teams[id] or (LT.deleted and LT.deleted[id]) or not LT:IsGuildOfficer(actor) then return false end
    if findTeamByName(name) then return false end
    LT.teams[id]={id=id,name=name,focus=focus,motd=motd,owner=owner,color=teamColor,members={},noteMembers={},events={}}
    save(); rosterRefresh(); return true
  end
  local id,team=f[2],LT.teams[f[2]]
  if op=="DEL" then
    if not team or not LT:CanDelete(team,actor) then return false end
    LT.deleted=LT.deleted or {}; LT.deleted[id]={by=actor,at=time()}
    LT.teams[id]=nil; if LT.selected==id then LT.selected=nil end
    save(); LT:Refresh(); return true
  end
  if not team then return false end
  if op=="SYNC" then
    if actor~=team.owner or not valid(f[3],24) or not valid(f[4],48) or not valid(f[5],150) then return false end
    team.name,team.focus,team.motd,team.color=f[3],f[4],f[5],color(f[6]); save()
  elseif op=="ROSTER" then
    if actor~=team.owner or not valid(f[3],80) or not LT.roster[norm(f[3])] or
      (f[4]~="member" and f[4]~="officer" and f[4]~="leader") then return false end
    local who=norm(f[3]); team.members[who]=f[4]=="leader" and "member" or f[4]
    team.noteMembers[who]=nil
    save()
  elseif op=="ADD" then
    if not LT:CanManage(team,actor) or not LT.roster[norm(f[3])] then return false end
    local who=norm(f[3]); team.members[who]="member"; team.noteMembers[who]=nil; save()
  elseif op=="REMOVE" then
    local who=norm(f[3])
    if not team.members[who] or (actor~=who and not LT:CanManage(team,actor)) or who==team.owner then return false end
    team.members[who]=nil; if team.noteMembers then team.noteMembers[who]=nil end; save()
  elseif op=="MOTD" then
    if not LT:CanManage(team,actor) or not valid(f[3],150) then return false end
    team.motd=f[3]; save()
  elseif op=="FOCUS" then
    if not LT:CanManage(team,actor) or not valid(f[3],48) then return false end
    team.focus=f[3]; save()
  elseif op=="COLOR" then
    if not LT:CanManage(team,actor) then return false end
    team.color=color(f[3]); save()
  elseif op=="TRANSFER" then
    if not LT:IsGuildOfficer(actor) or not LT.roster[norm(f[3])] then return false end
    team.owner=norm(f[3]); team.delegatedOwner=team.owner; save()
  else return false end
  LT:Refresh(); return true
end
function LT:Act(op,...)
  local f={op,...}
  for _,v in ipairs(f) do if not valid(v,150) then self:Notice("Invalid value; check length and remove pipe characters."); return end end
  if apply(op,f,selfName()) then send(op,...) else self:Notice("You do not have permission, or the requested change was invalid.") end
end
local function syncTeams()
  if not guild() then return end
  if LT:IsGuildLeader(selfName()) then
    for who,record in pairs(LT.authorizedOfficers) do send("AUTH",who,"yes",tostring(record.at or time())) end
  end
  for id,team in pairs(LT.teams) do
    if team.owner==selfName() then
      send("NEW",id,team.name,team.focus or "General",team.motd or "",team.owner,team.color or "White")
      send("SYNC",id,team.name,team.focus or "General",team.motd or "",team.color or "White")
      for who,role in pairs(team.members or {}) do send("ROSTER",id,who,role) end
    end
  end
end
function LT:OpenGuild()
  local g=guild()
  if not g then self:Notice("Join a guild before opening Lite."); return false end
  EXINTeamsLiteDB=EXINTeamsLiteDB or {}
  EXINTeamsLiteDB[g]=EXINTeamsLiteDB[g] or {}
  self.db=EXINTeamsLiteDB[g]
  self.teams=self.db.teams or {}; self.authorizedOfficers=self.db.authorizedOfficers or {}
  self.deleted=self.db.deleted or {}
  self.db.teams=self.teams; self.db.authorizedOfficers=self.authorizedOfficers; self.db.deleted=self.deleted
  if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster() elseif GuildRoster then GuildRoster() end
  rosterRefresh()
  return true
end
function LT:Refresh() if self.Draw then self:Draw() end end
function LT:Toggle()
  if self.panel and self.panel:IsShown() then self.panel:Hide()
  elseif self:OpenGuild() then self.panel:Show(); self:Refresh(); self:CheckConnection() end
end
function LT:CheckConnection()
  if guild() then send("HELLO",selfName()) end
end
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_GUILD_UPDATE")
frame:RegisterEvent("GUILD_ROSTER_UPDATE")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:SetScript("OnEvent",function(_,event,...)
  if event=="PLAYER_LOGIN" then
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then C_ChatInfo.RegisterAddonMessagePrefix(LT.PREFIX)
    elseif RegisterAddonMessagePrefix then RegisterAddonMessagePrefix(LT.PREFIX) end
    LT:OpenGuild()
    C_Timer.After(4,function() LT:CheckConnection() end)
  elseif event=="PLAYER_GUILD_UPDATE" then LT:OpenGuild()
  elseif event=="GUILD_ROSTER_UPDATE" then rosterRefresh()
  elseif event=="CHAT_MSG_ADDON" then
    local prefix,message,channel,sender=...
    if prefix~=LT.PREFIX or (channel~="GUILD" and channel~="WHISPER") or type(message)~="string" or #message>240 then return end
    local actor=norm(sender)
    if actor==selfName() or not LT.roster[actor] then return end
    local f={}; for part in (message.."|"):gmatch("(.-)|") do table.insert(f,part) end
    if f[1]=="HELLO" then emit("WHISPER",actor,"PONG"); syncTeams(); return end
    if f[1]=="PONG" then return end
    if channel=="WHISPER" and f[1]~="HELLO" then return end
    apply(f[1],f,actor)
  end
end)
