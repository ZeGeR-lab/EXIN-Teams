local ADDON, LT = ...
_G.EXINTeamsLite = LT
LT.versionString = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON, "Version")) or "0.5.30"
LT.PREFIX = "EXINL2" -- Realm-scoped protocol; avoids Full collisions and rejects legacy unscoped packets.
LT.teams, LT.roster, LT.authorizedOfficers = {}, {}, {}
LT.selected, LT.db = nil, nil
-- Set this to the administrator character's normalized name when confirmed.
-- Example format: "character-realm" (or just "character" on a single-realm guild).
LT.SUPER_ADMIN_NAME = "Snoop Wharg"
LT.emblems = {
  {id="E01",name="Ribbon 01",hex="ff3f86"},
  {id="E02",name="Ribbon 02",hex="a72cff"},
  {id="E03",name="Ribbon 03",hex="68aaff"},
  {id="E04",name="Ribbon 04",hex="39d45c"},
  {id="E05",name="Ribbon 05",hex="f2dc25"},
  {id="E06",name="Ribbon 06",hex="ff9a24"},
  {id="E07",name="Ribbon 07",hex="ff3445"},
  {id="E08",name="Ribbon 08",hex="e8e8e8"},
  {id="E09",name="Ribbon 09",hex="7e8792"},
  {id="E10",name="Ribbon 10",hex="e65bc0"},
  {id="E11",name="Ribbon 11",hex="b77bdc"},
  {id="E12",name="Ribbon 12",hex="18c83b"},
  {id="E13",name="Ribbon 13",hex="00cbbd"},
  {id="E14",name="Ribbon 14",hex="a98ad9"},
  {id="E15",name="Ribbon 15",hex="72d9d1"},
  {id="E16",name="Ribbon 16",hex="c3a1e8"},
  {id="E17",name="Ribbon 17",hex="a9b8ff"},
  {id="E18",name="Ribbon 18",hex="df2381"},
  {id="E19",name="Ribbon 19",hex="08b7d0"},
  {id="E20",name="Ribbon 20",hex="1649ff"},
  {id="E21",name="Ribbon 21",hex="9acb4d"},
  {id="E22",name="Ribbon 22",hex="ffffff"},
  {id="E23",name="Ribbon 23",hex="ee2347"},
  {id="E24",name="Ribbon 24",hex="c1a36b"},
  {id="E25",name="Ribbon 25",hex="ff861d"},
  {id="E26",name="Ribbon 26",hex="eebd17"},
  {id="E27",name="Ribbon 27",hex="fa315b"},
  {id="E28",name="Ribbon 28",hex="f3f3f3"},
  {id="E29",name="Ribbon 29",hex="428bd8"},
  {id="E30",name="Ribbon 30",hex="12c88b"},
  {id="E31",name="Ribbon 31",hex="cba55a"},
  {id="E32",name="Ribbon 32",hex="52c5d9"},
  {id="E33",name="Ribbon 33",hex="ed7b28"}
}
LT.colors = {
  {name="Pink",hex="ff83b7"},{name="Purple",hex="aa89ff"},{name="Blue",hex="69b6ff"},
  {name="Green",hex="78d996"},{name="Yellow",hex="f7d96b"},{name="Orange",hex="ffab69"},
  {name="Red",hex="ff7777"},{name="White",hex="eeeeee"},{name="Black",hex="838b92"},
}
local function emblemId(id)
  for _, e in ipairs(LT.emblems) do if e.id==tostring(id or "") then return e.id end end
  return "E01"
end
function LT:Emblem(id)
  for _, e in ipairs(self.emblems) do if e.id==id then return e end end
  return self.emblems[1]
end
local frame = CreateFrame("Frame")
local function trim(s) return (s or ""):match("^%s*(.-)%s*$") end
local function norm(s) return trim(s):lower():gsub("%s+","-") end
local function guild() return GetGuildInfo("player") end
local function guildStorageKey(name)
  local realm=GetRealmName and GetRealmName() or ""
  realm=trim(realm)
  if realm=="" then realm="UnknownRealm" end
  return tostring(name).."@"..realm
end
local activeGuildKey
local function clearGuildRuntime()
  LT.teams={}
  LT.roster={}
  LT.authorizedOfficers={}
  LT.deleted={}
  LT.selected=nil
  LT.db=nil
  activeGuildKey=nil
  LT:Refresh()
end
local function selfName()
  local name, realm
  if UnitFullName then name, realm = UnitFullName("player") else name = UnitName("player") end
  if realm and realm ~= "" then return norm(name .. "-" .. realm) end
  return norm(name)
end
local function isAdminIdentity(key)
  local admin=norm(LT.SUPER_ADMIN_NAME)
  if admin=="" then return false end
  -- A name-only setting may match a realm-qualified roster entry, but only
  -- when exactly one guild character has that base name.
  local match,count=nil,0
  for rosterKey in pairs(LT.roster) do
    if rosterKey==admin or rosterKey:sub(1,#admin+1)==admin.."-" then
      match=rosterKey; count=count+1
    end
  end
  return count==1 and match==key
end
local function metadataIsNewer(team,revision,actor)
  local current=tonumber(team.metaChangedAt) or 0
  if revision~=current then return revision>current end
  return norm(actor)>norm(team.metaChangedBy or "")
end
local function setMetadataRevision(team,revision,actor)
  team.metaChangedAt=revision
  team.metaChangedBy=norm(actor)
end
local function metadataIsNotOlder(team,revision,actor)
  local current=tonumber(team.metaChangedAt) or 0
  if revision~=current then return revision>current end
  return norm(actor)>=norm(team.metaChangedBy or "")
end
local function setTeamOwner(team,newOwner)
  newOwner=norm(newOwner)
  if not team or newOwner=="" then return false end
  local previousOwner=team.owner
  team.members=team.members or {}
  team.manualMembers=team.manualMembers or {}
  team.noteMembers=team.noteMembers or {}
  if previousOwner and previousOwner~=newOwner and team.members[previousOwner]=="leader" then
    team.members[previousOwner]="officer"
  end
  team.owner=newOwner
  team.members[newOwner]="leader"
  team.noteMembers[newOwner]=nil
  team.manualMembers[newOwner]=true
  team.delegatedOwner=newOwner
  return true
end
local function valid(s,n) return type(s)=="string" and #s>0 and #s<=n and not s:find("[|\r\n]") end
local function validOptional(s,n) return type(s)=="string" and #s<=n and not s:find("[|\r\n]") end
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
  local key=norm(who)
  if key==selfName() and guild() then
    local g,_,rankID=GetGuildInfo("player")
    if g==guild() and tonumber(rankID)==0 then return true end
  end
  -- Permanent EXIN administrator override. Accept the configured character identity
  -- with or without a realm suffix, while avoiding loose partial-name matches.
  if isAdminIdentity(key) then return true end
  local m=LT.roster[key]
  return m and tonumber(m.rankID)==0 or false
end
function LT:IsGuildOfficer(who)
  local key=norm(who)
  if self:IsGuildLeader(key) then return true end
  local m=self.roster[key]
  return m~=nil and self.authorizedOfficers[key]~=nil and not self.authorizedOfficers[key].revoked
end
function LT:IsTeamLeader(who, team)
  if team and team.members and team.members[norm(who)]=="leader" then return true end
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
  local scope=guildStorageKey(guild())
  if scope:find("[|\\r\\n]") then return end
  local msg=scope.."|"..table.concat(fields,"|")
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
  if total==0 then
    -- An empty roster can occur while WoW is loading guild data or after a guild change.
    -- Never keep old roster identities available for permission checks during that gap.
    wipe(LT.roster)
    LT:Refresh()
    return
  end
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
    team.manualMembers=team.manualMembers or {}
    for who in pairs(team.noteMembers) do
      local m=LT.roster[who]
      if not m or not m.noteTeam or (m.noteTeam:lower()~=tostring(team.name):lower() and m.noteTeam:lower()~=tostring(team.color):lower()) then
        team.noteMembers[who]=nil
        if not team.manualMembers[who] then team.members[who]=nil end
      end
    end
    for who,m in pairs(LT.roster) do
      if m.noteTeam and (m.noteTeam:lower()==tostring(team.name):lower() or m.noteTeam:lower()==tostring(team.color):lower()) then
        team.members[who]=team.members[who] or "member"
        team.noteMembers[who]=true
      end
    end
    -- A character who leaves the guild must not remain as a stale manual member.
    -- Keep the owner identity itself so an Officer can transfer ownership if needed.
    for who in pairs(team.manualMembers) do
      if not LT.roster[who] then
        team.manualMembers[who]=nil
        if not team.noteMembers[who] then team.members[who]=nil end
      end
    end
    -- Reassert the owner role when the owner returns to the guild roster.
    if team.owner and LT.roster[team.owner] then
      team.members[team.owner]="leader"
      team.manualMembers[team.owner]=true
      team.noteMembers[team.owner]=nil
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
    local revision=tonumber(f[4])
    if not revision or revision<=0 then return false end
    local previous=LT.authorizedOfficers[target]
    -- Ignore stale or duplicate snapshots so old grants cannot undo revocations.
    if previous and revision<=(tonumber(previous.at) or 0) then return false end
    LT.authorizedOfficers[target]={by=actor,at=revision,revoked=(f[3]=="no")}
    save(); LT:Refresh(); return true
  elseif op=="NEW" then
    local id,name,focus,motd,owner,teamColor=f[2],f[3],f[4],f[5],norm(f[6]),color(f[7])
    if not valid(id,48) or not valid(name,24) or not valid(focus,48) or not validOptional(motd,150) or not LT.roster[owner] or
      LT.teams[id] or (LT.deleted and LT.deleted[id]) or not LT:IsGuildOfficer(actor) then return false end
    if findTeamByName(name) then return false end
    LT.teams[id]={id=id,name=name,focus=focus,motd=motd,owner=owner,color=teamColor,emblem=emblemId(f[8]),members={[owner]="leader"},noteMembers={},manualMembers={[owner]=true},events={}}
    save(); rosterRefresh(); return true
  end
  local id,team=f[2],LT.teams[f[2]]
  if op=="DEL" then
    if not valid(id,48) or not LT:IsGuildOfficer(actor) then return false end
    LT.deleted=LT.deleted or {}
    local tombstone=LT.deleted[id]
    LT.deleted[id]={by=actor,at=math.max(tonumber(tombstone and tombstone.at) or 0,time())}
    LT.teams[id]=nil; if LT.selected==id then LT.selected=nil end
    save(); LT:Refresh(); return true
  end
  if not team then return false end
  if op=="SYNC" then
    if (actor~=team.owner and not LT:IsGuildOfficer(actor)) or not valid(f[3],24) or not valid(f[4],48) or not validOptional(f[5],150) then return false end
    local incomingOwner,ownerRevision
    if f[8] then
      incomingOwner=norm(f[8])
      ownerRevision=tonumber(f[9]) or 0
      if not LT.roster[incomingOwner] then return false end
      if incomingOwner~=team.owner and
        (not LT:IsGuildOfficer(actor) or ownerRevision<=(tonumber(team.ownerChangedAt) or 0)) then return false end
    end
    -- Metadata and ownership have independent revisions; stale metadata never rolls back newer edits.
    local metadataRevision=tonumber(f[10]) or 0
    local metadataActor=norm(f[11] or actor)
    if metadataIsNewer(team,metadataRevision,metadataActor) then
      team.name,team.focus,team.motd,team.color=f[3],f[4],f[5],color(f[6])
      team.emblem=emblemId(f[7] or team.emblem)
      setMetadataRevision(team,metadataRevision,metadataActor)
    end
    if incomingOwner then
      if incomingOwner~=team.owner then
        setTeamOwner(team,incomingOwner)
        team.ownerChangedAt=ownerRevision
      elseif ownerRevision>(tonumber(team.ownerChangedAt) or 0) then
        team.ownerChangedAt=ownerRevision
      end
    end
    -- Repair legacy snapshots whose owner and Leader role have drifted apart.
    if team.owner and LT.roster[team.owner] then setTeamOwner(team,team.owner) end
    save()
  elseif op=="RCLR" then
    -- Full roster replacement is reserved for the owner or a guild-wide Officer.
    -- Team Leaders may edit individual roles, but cannot wipe the team roster.
    if actor~=team.owner and not LT:IsGuildOfficer(actor) then return false end
    -- A reconnect snapshot is authoritative: clear stale manual entries before replaying roles.
    team.members={}
    team.manualMembers={}
    if team.owner and LT.roster[team.owner] then
      team.members[team.owner]="leader"
      team.manualMembers[team.owner]=true
    end
    -- Keep noteMembers; rosterRefresh reconciles them against current guild notes.
    for who in pairs(team.noteMembers or {}) do
      if LT.roster[who] then team.members[who]=team.members[who] or "member" end
    end
    save()
  elseif op=="ROSTER" then
    if not LT:CanManage(team,actor) or not valid(f[3],80) or not LT.roster[norm(f[3])] or
      (f[4]~="member" and f[4]~="officer" and f[4]~="leader") then return false end
    local who=norm(f[3]); team.members[who]=f[4]
    -- Preserve guild-note provenance for primary members when changing their team role.
    if not (team.noteMembers and team.noteMembers[who]) then
      team.manualMembers=team.manualMembers or {}; team.manualMembers[who]=true
    end
    save()
  elseif op=="ADD" then
    if not LT:CanManage(team,actor) or not LT.roster[norm(f[3])] then return false end
    local who=norm(f[3])
    -- ADD is only for a character who is not already a member. In particular,
    -- it must not erase guild-note provenance or silently demote an existing role.
    if team.members[who] then return false end
    team.members[who]="member"; team.noteMembers=team.noteMembers or {}; team.manualMembers=team.manualMembers or {}
    team.manualMembers[who]=true; save()
  elseif op=="REMOVE" then
    local who=norm(f[3])
    -- Primary membership is controlled by the public guild note, not an addon toggle.
    if not team.members[who] or (team.noteMembers and team.noteMembers[who]) or
      (actor~=who and not LT:CanManage(team,actor)) or who==team.owner then return false end
    team.members[who]=nil; if team.noteMembers then team.noteMembers[who]=nil end; if team.manualMembers then team.manualMembers[who]=nil end; save()
  elseif op=="NAME" then
    local revision=tonumber(f[4])
    if not LT:CanManage(team,actor) or not valid(f[3],24) or not revision or not metadataIsNewer(team,revision,actor) then return false end
    local existing=findTeamByName(f[3]); if existing and existing~=id then return false end
    team.name=f[3]; setMetadataRevision(team,revision,actor); save()
  elseif op=="MOTD" then
    local revision=tonumber(f[4])
    if not LT:CanManage(team,actor) or not validOptional(f[3],150) or not revision or not metadataIsNotOlder(team,revision,(f[5] and f[5]~="" and f[5]) or actor) then return false end
    team.motd=f[3]; setMetadataRevision(team,revision,(f[5] and f[5]~="" and f[5]) or actor); save()
  elseif op=="FOCUS" then
    local revision=tonumber(f[4])
    if not LT:CanManage(team,actor) or not valid(f[3],48) or not revision or not metadataIsNewer(team,revision,actor) then return false end
    team.focus=f[3]; setMetadataRevision(team,revision,actor); save()
  elseif op=="COLOR" then
    local revision=tonumber(f[4])
    if not LT:CanManage(team,actor) or not revision or not metadataIsNewer(team,revision,actor) then return false end
    team.color=color(f[3]); setMetadataRevision(team,revision,actor); save()
  elseif op=="EMBLEM" then
    local revision=tonumber(f[4])
    if not LT:CanManage(team,actor) or not valid(f[3],4) or not revision or not metadataIsNewer(team,revision,actor) then return false end
    team.emblem=emblemId(f[3]); setMetadataRevision(team,revision,actor); save()
  elseif op=="TRANSFER" then
    local newOwner=norm(f[3])
    if not LT:IsGuildOfficer(actor) or not LT.roster[newOwner] then return false end
    -- Ownership and the visible Leader role must always agree on every client.
    local revision=tonumber(f[4]) or time()
    revision=math.max(revision,(tonumber(team.ownerChangedAt) or 0)+1)
    setTeamOwner(team,newOwner)
    team.ownerChangedAt=revision
    save()
  else return false end
  LT:Refresh(); return true
end
function LT:Act(op,...)
  local f={op,...}
  if op=="NAME" or op=="MOTD" or op=="FOCUS" or op=="COLOR" or op=="EMBLEM" then
    local team=self.teams[f[2]]
    if not team then self:Notice("Team not found."); return end
    f[4]=tostring(math.max(time(),(tonumber(team.metaChangedAt) or 0)+1))
  end
  for i,v in ipairs(f) do
    local optionalMotd=((op=="NEW" and i==5) or (op=="MOTD" and i==3)) and v==""
    if not optionalMotd and not valid(v,150) then
      self:Notice("Invalid value; check length and remove pipe characters."); return
    end
  end
  if apply(op,f,selfName()) then send(unpack(f)) else self:Notice("You do not have permission, or the requested change was invalid.") end
end
local function syncTeams()
  if not guild() then return end
  if LT:IsGuildLeader(selfName()) then
    for who,record in pairs(LT.authorizedOfficers) do
      send("AUTH",who,record.revoked and "no" or "yes",tostring(record.at or time()))
    end
  end
  -- Replicate deletion tombstones so a returning client cannot resurrect an old team.
  if LT:IsGuildOfficer(selfName()) then
    for id in pairs(LT.deleted or {}) do send("DEL",id) end
  end
  for id,team in pairs(LT.teams) do
    if team.owner==selfName() or LT:IsGuildOfficer(selfName()) then
      -- Keep metadata packets small; MOTD travels separately so long messages
      -- cannot silently exceed the addon-message size limit during reconnect sync.
      send("NEW",id,team.name,team.focus or "General","",team.owner,team.color or "White",team.emblem or "E01")
      send("SYNC",id,team.name,team.focus or "General","",team.color or "White",team.emblem or "E01",team.owner,tostring(team.ownerChangedAt or 0),tostring(team.metaChangedAt or 0),team.metaChangedBy or selfName())
      if team.motd and team.motd~="" then send("MOTD",id,team.motd,tostring(team.metaChangedAt or 0),team.metaChangedBy or selfName()) end
      send("RCLR",id)
      for who,role in pairs(team.members or {}) do send("ROSTER",id,who,role) end
    end
  end
end
function LT:OpenGuild()
  local g=guild()
  if not g then
    clearGuildRuntime()
    self:Notice("Join a guild before opening Lite.")
    return false
  end
  EXINTeamsLiteDB=EXINTeamsLiteDB or {}
  local key=guildStorageKey(g)
  if not EXINTeamsLiteDB[key] and EXINTeamsLiteDB[g] then
    -- Migrate the pre-realm-keyed save once; leaving the legacy key behind
    -- would let a second realm with the same guild name inherit that data.
    EXINTeamsLiteDB[key]=EXINTeamsLiteDB[g]
    EXINTeamsLiteDB[g]=nil
  end
  EXINTeamsLiteDB[key]=EXINTeamsLiteDB[key] or {}
  if activeGuildKey~=key then self.selected=nil end
  activeGuildKey=key
  self.db=EXINTeamsLiteDB[key]
  self.teams=self.db.teams or {}; self.authorizedOfficers=self.db.authorizedOfficers or {}
  self.deleted=self.db.deleted or {}
  self.db.teams=self.teams; self.db.authorizedOfficers=self.authorizedOfficers; self.db.deleted=self.deleted
  wipe(self.roster)
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
  elseif event=="GUILD_ROSTER_UPDATE" then
    if not guild() then clearGuildRuntime() else rosterRefresh() end
  elseif event=="CHAT_MSG_ADDON" then
    local prefix,message,channel,sender=...
    if prefix~=LT.PREFIX or (channel~="GUILD" and channel~="WHISPER") or type(message)~="string" or #message>240 then return end
    local actor=norm(sender)
    if actor==selfName() or not LT.roster[actor] then return end
    local f={}; for part in (message.."|"):gmatch("(.-)|") do table.insert(f,part) end
    -- Every packet is bound to the sender's guild name and realm. Delayed
    -- traffic from a previous guild must never mutate the newly active save.
    if not guild() or f[1]~=guildStorageKey(guild()) then return end
    table.remove(f,1)
    if not f[1] then return end
    if f[1]=="HELLO" then emit("WHISPER",actor,"PONG"); syncTeams(); return end
    if f[1]=="PONG" then return end
    if channel=="WHISPER" and f[1]~="HELLO" then return end
    apply(f[1],f,actor)
  end
end)
