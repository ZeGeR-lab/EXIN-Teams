local ADDON, FT = ...
_G.ForeverTeams = FT
FT.version = 1
local addonMetadata=C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
FT.versionString=(addonMetadata and addonMetadata(ADDON,"Version")) or "0.5.5"
FT.teams = {}
FT.roster = {}
FT.invitations = {}
FT.requests = {}
FT.events = {}
FT.personalEvents = {}
FT.guildEvents = {}
FT.guildDeleted = {}
FT.profiles = {}
FT.professions = {}
FT.playerInfo = {}
FT.attunements = {}
FT.deleted = {}
FT.selected = nil
FT.colors = {
  {name="Pink", hex="ff83b7"}, {name="Purple", hex="aa89ff"},
  {name="Blue", hex="69b6ff"}, {name="Green", hex="78d996"},
  {name="Yellow", hex="f7d96b"}, {name="Orange", hex="ffab69"},
  {name="Red", hex="ff7777"}, {name="White", hex="eeeeee"},
  {name="Black", hex="838b92"},
}
function FT:Color(name)
  for _, color in ipairs(self.colors) do if color.name == name then return color end end
  return self.colors[8]
end
local PREFIX = "FTeams1"
local frame = CreateFrame("Frame")
local function trim(s) return (s or ""):match("^%s*(.-)%s*$") end
local function norm(s)
  s = trim(s):lower()
  return (s:gsub("%s+", "-"))
end
local function selfName()
  local name=UnitFullName and UnitFullName("player") or UnitName("player")
  local key=norm(name)
  if FT.roster[key] then return key end
  local guid=UnitGUID and UnitGUID("player")
  if guid then
    for who, entry in pairs(FT.roster) do if entry.guid == guid then return who end end
  end
  return key
end
function FT:SelfName() return selfName() end
local function valid(s, max)
  return type(s) == "string" and #s > 0 and #s <= max and not s:find("[|\r\n]")
end
local function myGuild() return GetGuildInfo("player") end
local function display(who)
  local entry=FT.roster[norm(who)]
  return (entry and entry.name or who):gsub("%-", " ")
end
local function rosterRefresh()
  local total = GetNumGuildMembers and GetNumGuildMembers() or 0
  -- A roster request may finish later; an empty interim result must not erase
  -- known members or make their note-based teams disappear.
  if total == 0 then FT:Refresh(); return end
  wipe(FT.roster)
  for i = 1, total do
    local name, rank, rankID, level, class, _, note, _, online, _, _, _, _, _, _, _, guid = GetGuildRosterInfo(i)
    if name then
      local label, discord = (note or ""):match("^%s*(.-)%s+%-%s+(.+)%s*$")
      if label == "" or not discord or trim(discord) == "" then label, discord = nil, nil end
      FT.roster[norm(name)] = { name = name, rank = rank, rankID = rankID, level = level, class = class,
        online = online, guid = guid, note = note or "", noteTeam = label, discordName = discord and trim(discord) }
    end
  end
  if FT.db then
    -- Earlier builds saved first names only. Migrate only when that first name
    -- identifies exactly one character; never merge two players with the same first name.
    local firstNames={}
    for who in pairs(FT.roster) do
      local first=who:match("^[^-]+")
      if firstNames[first] == nil then firstNames[first]=who else firstNames[first]=false end
    end
    local function migrateKey(who)
      if FT.roster[who] then return who end
      return firstNames[who] or who
    end
    local function migrateMap(map)
      if type(map) ~= "table" then return end
      for who, value in pairs(map) do
        local full=migrateKey(who)
        if full ~= who then
          if map[full] == nil then map[full]=value end
          map[who]=nil
        end
      end
    end
    migrateMap(FT.profiles)
    migrateMap(FT.professions)
    migrateMap(FT.playerInfo)
    migrateMap(FT.attunements)
    local function noteKey(value)
      local normalized=trim(value):gsub("%s+"," "):lower()
      return normalized:gsub("^team ","")
    end
    local labels={}
    for who, entry in pairs(FT.roster) do
      local label=entry.noteTeam and trim(entry.noteTeam):gsub("%s+"," ")
      if label and #label>=2 and #label<=24 and not label:find("[|%c]") then
        local folded=noteKey(label)
        labels[folded]=labels[folded] or {name=label,members={}}
        labels[folded].members[who]=true
      end
    end
    local function leaderFor(group)
      local candidates={}
      for who in pairs(group.members) do
        if FT:IsTeamLeader(who) then
          table.insert(candidates,who)
        end
      end
      table.sort(candidates)
      if candidates[1] then return candidates[1] end
      for who, entry in pairs(FT.roster) do
        if tonumber(entry.rankID)==0 then return who end
      end
      candidates={}
      for who in pairs(FT.roster) do if FT:IsGuildOfficer(who) then table.insert(candidates,who) end end
      table.sort(candidates)
      if candidates[1] then return candidates[1] end
      for who in pairs(group.members) do table.insert(candidates,who) end
      table.sort(candidates)
      return candidates[1]
    end
    local match={}
    for id, team in pairs(FT.teams) do
      if team.fromNotes==nil and id:sub(1,5)=="note-" then team.fromNotes=true end
    end
    for label, group in pairs(labels) do
      local team, bestScore
      for id, team in pairs(FT.teams) do
        local sameName=team.name and noteKey(team.name)==label
        local sameColor=team.color and noteKey(team.color)==label
        local score=sameName and (team.fromNotes and 2 or 0) or
          sameColor and (team.fromNotes and 3 or 1)
        if score and (not bestScore or score<bestScore or
          (score==bestScore and id<match[label].id)) then
          match[label]=team
          bestScore=score
        end
      end
      local team=match[label]
      if not team then
        local id="note-"..norm(group.name)
        if not FT.deleted[id] then
          local color=FT:Color(group.name)
          for _,candidate in ipairs(FT.colors) do
            if candidate.name:lower()==label then color=candidate; break end
          end
          local owner=leaderFor(group)
          team={id=id,name=group.name,focus="General",motd="Welcome to "..group.name,
            owner=owner,color=color.name,members={},ownerParticipates=false,
            noteMembers={},events={},fromNotes=true}
          FT.teams[id]=team
        end
      elseif team.fromNotes and not team.delegatedOwner then
        -- If a roster arrived in pieces, replace the temporary steward once
        -- the matching Team Leader appears; never override an admin transfer.
        local leader=leaderFor(group)
        if leader and FT:IsTeamLeader(leader) and not FT:IsTeamLeader(team.owner) then
          team.owner=leader
          team.ownerParticipates=team.members[leader] and true or false
        end
      end
      match[label]=team
    end
    -- A prior build may have created note-blue while an older manually made
    -- Blue team was still syncing. Preserve the manual team and its content.
    for id, duplicate in pairs(FT.teams) do
      local canonical=duplicate.fromNotes and match[noteKey(duplicate.name)]
      if canonical and canonical~=duplicate then
        canonical.members=canonical.members or {}
        canonical.noteMembers=canonical.noteMembers or {}
        for who, role in pairs(duplicate.members or {}) do
          if not canonical.members[who] then canonical.members[who]=role end
        end
        for who in pairs(duplicate.noteMembers or {}) do canonical.noteMembers[who]=true end
        canonical.events=canonical.events or {}
        local eventIDs={}
        for _, event in ipairs(canonical.events) do eventIDs[event.id]=true end
        for _, event in ipairs(duplicate.events or {}) do
          if not eventIDs[event.id] then table.insert(canonical.events,event); eventIDs[event.id]=true end
        end
        for _,field in ipairs({"requests","invitations"}) do
          local collection=FT[field]
          if collection[id] then
            collection[canonical.id]=collection[canonical.id] or {}
            for who,value in pairs(collection[id]) do
              if collection[canonical.id][who]==nil then collection[canonical.id][who]=value end
            end
            collection[id]=nil
          end
        end
        if FT.selected==id then FT.selected=canonical.id end
        FT.deleted[id]={owner=duplicate.owner,by=selfName()}
        FT.teams[id]=nil
      end
    end
    for _, team in pairs(FT.teams) do
      team.owner=migrateKey(team.owner)
      migrateMap(team.members)
      migrateMap(team.noteMembers)
      migrateMap(FT.requests[team.id])
      migrateMap(FT.invitations[team.id])
      for _, event in ipairs(team.events or {}) do migrateMap(event.attendees) end
      team.noteMembers = team.noteMembers or {}
      for who in pairs(team.noteMembers) do
        local entry=FT.roster[who]
        local label=entry and entry.noteTeam
        if not label or match[noteKey(label)]~=team then
          if team.members[who] == "member" then
            FT:RecordActivity(team,display(who).." left after their guild note changed")
            team.members[who]=nil
            if who==team.owner then team.ownerParticipates=false end
          end
          team.noteMembers[who]=nil
        end
      end
      for who, entry in pairs(FT.roster) do
        local label=entry.noteTeam
        if label and match[noteKey(label)]==team and
          (who ~= team.owner or team.ownerParticipates) and not team.members[who] then
          team.members[who]="member"
          team.noteMembers[who]=true
          FT:RecordActivity(team,display(who).." joined from their guild note")
        end
      end
    end
    FT.db.teams=FT.teams
  end
  FT:Refresh()
end
function FT:Refresh() if self.Draw then self:Draw() end end
function FT:Notice(s) print("|cff9bdd00EXIN Teams:|r " .. s) end
function FT:RecordActivity(team, description)
  if not team or not self:CanSeeDetails(team, selfName()) then return end
  team.activity=team.activity or {}
  table.insert(team.activity, 1, {at=time(), text=description})
  while #team.activity > 80 do table.remove(team.activity) end
end
function FT:Member(team, who) return team and team.members[norm(who)] end
local function officerRank(rank, rankID)
  local index=tonumber(rankID)
  if index and index<=1 then return true end
  -- Some Forever guild rank layouts put an explicitly named officer rank
  -- below index 1. These names come from the game, never from member notes.
  local name=type(rank)=="string" and trim(rank):lower() or ""
  return name=="guild master" or name=="guildmaster" or name=="guild leader" or
    name=="officer" or name=="guild officer"
end
function FT:IsGuildOfficer(who)
  local name=norm(who)
  if not myGuild() then return false end
  local member=self.roster[name]
  -- Temporary developer override: the authenticated guild character name only.
  -- Guild notes and Discord names must never grant administrator access.
  if name==selfName() then
    if name=="snoop-warg" and myGuild()=="Ex Inferno" then return true end
    -- GetGuildInfo works before the full roster is populated. Only use it
    -- for the logged-in character; remote users must match a roster entry.
    local guild,rank,index=GetGuildInfo("player")
    if guild==myGuild() and officerRank(rank,index) then return true end
  end
  return member and officerRank(member.rank,member.rankID) or false
end
function FT:IsGuildLeader(who)
  if norm(who)==selfName() and myGuild() then
    local guild,_,index=GetGuildInfo("player")
    if guild==myGuild() and tonumber(index)==0 then return true end
  end
  local member=self.roster[norm(who)]
  return member and tonumber(member.rankID)==0 or false
end
function FT:IsTeamLeader(who)
  local member=self.roster[norm(who)]
  if not member or type(member.rank) ~= "string" or not member.noteTeam or not member.discordName or member.noteTeam == "" then return false end
  local rank=member.rank:lower()
  if rank == "team leader" then return true end
  for _, color in ipairs(self.colors) do
    if rank == "team leader " .. color.name:lower() and member.noteTeam:lower() == color.name:lower() then return true end
  end
  return false
end
function FT:LeaderColor(who)
  local entry=self.roster[norm(who)]
  if not self:IsTeamLeader(who) then return nil end
  for _, color in ipairs(self.colors) do
    if color.name:lower() == entry.noteTeam:lower() then return color.name end
  end
end
function FT:CanCreate(who) return self:IsGuildOfficer(who) or self:IsTeamLeader(who) end
function FT:CanOwnTeam(who, name, color)
  if self:IsGuildOfficer(who) then return true end
  local entry=self.roster[norm(who)]
  return self:IsTeamLeader(who) and (entry.noteTeam:lower() == name:lower() or
    entry.noteTeam:lower() == color:lower())
end
function FT:CanDelete(team, who)
  return team and (self:IsGuildOfficer(who) or
    (team.owner == norm(who) and (team.delegatedOwner==norm(who) or self:CanOwnTeam(who, team.name, team.color))))
end
function FT:CanSeeDetails(team, who)
  return team and (team.members[norm(who)] or team.owner == norm(who) or self:IsGuildOfficer(who))
end
function FT:CanManage(team, who)
  local role = self:Member(team, who)
  return team and (self:IsGuildOfficer(who) or
    (team.owner == norm(who) and (team.delegatedOwner==norm(who) or self:CanOwnTeam(who, team.name, team.color))) or role == "officer")
end
local function emit(channel, target, op, ...)
  if not myGuild() then return end
  local fields = {op, ...}
  for _, field in ipairs(fields) do if type(field) ~= "string" or field:find("[|\r\n]") then return end end
  local msg = table.concat(fields, "|")
  if #msg > 240 then return end
  if C_ChatInfo and C_ChatInfo.SendAddonMessage then
    C_ChatInfo.SendAddonMessage(PREFIX, msg, channel, target)
  elseif SendAddonMessage then
    SendAddonMessage(PREFIX, msg, channel, target)
  end
end
local function send(op, ...) emit("GUILD", nil, op, ...) end
local function sendPrivate(op, ...)
  local destinations={}
  for who, entry in pairs(FT.roster) do
    if who ~= selfName() and entry.online and FT:IsGuildOfficer(who) then destinations[who]=who end
  end
  for id, team in pairs(FT.teams) do
    if team.owner == selfName() or team.members[selfName()] or (FT.requests[id] and FT.requests[id][selfName()]) then
      for who in pairs(team.members) do
        local entry=FT.roster[who]
        if entry and entry.online and who ~= selfName() then destinations[who]=who end
      end
      local entry=FT.roster[team.owner]
      if entry and entry.online and team.owner ~= selfName() then destinations[team.owner]=team.owner end
    end
  end
  for _, name in pairs(destinations) do emit("WHISPER", name, op, ...) end
end
local function save()
  if FT.db then
    if not FT:IsGuildOfficer(selfName()) then
      local function allowed(who)
        if who == selfName() then return true end
        for id, team in pairs(FT.teams) do
          if (team.members[who] or team.owner == who or (FT.requests[id] and FT.requests[id][who])) and
            FT:CanSeeDetails(team, selfName()) then return true end
        end
      end
      for who in pairs(FT.professions) do if not allowed(who) then FT.professions[who]=nil end end
      for who in pairs(FT.playerInfo) do if not allowed(who) then FT.playerInfo[who]=nil end end
      for who in pairs(FT.profiles) do if not allowed(who) then FT.profiles[who]=nil end end
      for who in pairs(FT.attunements) do if not allowed(who) then FT.attunements[who]=nil end end
      for id, requests in pairs(FT.requests) do
        if not FT:CanManage(FT.teams[id], selfName()) then
          for who in pairs(requests) do if who ~= selfName() then requests[who]=nil end end
        end
      end
      for id, invites in pairs(FT.invitations) do
        if not FT:CanManage(FT.teams[id], selfName()) then
          for who in pairs(invites) do if who ~= selfName() then invites[who]=nil end end
        end
      end
    end
    FT.db.teams = FT.teams
    FT.db.requests = FT.requests
    FT.db.invitations = FT.invitations
    FT.db.professions = FT.professions
    FT.db.playerInfo = FT.playerInfo
    FT.db.profiles = FT.profiles
    FT.db.attunements = FT.attunements
    FT.db.deleted = FT.deleted
  end
end
local function clearPending(id, who)
  if FT.requests[id] then FT.requests[id][who] = nil end
  if FT.invitations[id] then FT.invitations[id][who] = nil end
end
local function role(s, allowNone)
  return s == "Tank" or s == "Healer" or s == "DPS" or allowNone and s == "None"
end
local function eventByID(team, eventID)
  for _, event in ipairs(team.events) do if event.id == eventID then return event end end
end
local function guildEventByID(eventID)
  for _, event in ipairs(FT.guildEvents) do if event.id==eventID then return event end end
end
local function validWhen(s)
  if type(s) ~= "string" then return false end
  local year, month, day, hour, minute = s:match("^(%d%d%d%d)%-(%d%d)%-(%d%d) (%d%d):(%d%d)$")
  return year and tonumber(month) >= 1 and tonumber(month) <= 12 and
    tonumber(day) >= 1 and tonumber(day) <= 31 and tonumber(hour) <= 23 and tonumber(minute) <= 59
end
local function personalID() return selfName().."-"..tostring(time()).."-"..tostring(math.floor(GetTime()*1000)%100000) end
function FT:NewPersonalEvent(when, title, note)
  note=note or ""
  if not validWhen(when) or not valid(title,70) or #note>60 or note:find("[|\r\n]") then return end
  local id=personalID()
  self.personalEvents[id]={id=id,when=when,title=title,note=note,owner=selfName(),invited={},attendees={[selfName()]=true},declined={}}
  save()
  self:Refresh()
  return id
end
function FT:InvitePersonal(id, who)
  local event=self.personalEvents[id]
  who=norm(who)
  if not event or event.owner~=selfName() or not self.roster[who] or who==selfName() then return false end
  event.invited[who]=true
  save()
  if self.roster[who].online then
    emit("WHISPER",who,"PERSONAL",id,event.when,event.title,event.note or "")
  end
  self:Refresh()
  return true
end
function FT:RSVPPersonal(id, yes)
  local event=self.personalEvents[id]
  if not event or not event.invited or not event.invited[selfName()] or event.owner==selfName() then return end
  event.attendees=event.attendees or {}
  event.declined=event.declined or {}
  event.attendees[selfName()]=yes and true or nil
  event.declined[selfName()]=yes and nil or true
  local owner=self.roster[event.owner]
  if owner and owner.online then emit("WHISPER",event.owner,"PERSONAL_RSVP",id,yes and "yes" or "no") end
  save()
  self:Refresh()
end
function FT:RemovePersonal(id)
  local event=self.personalEvents[id]
  if not event or event.owner~=selfName() then return end
  for who in pairs(event.invited or {}) do
    if self.roster[who] and self.roster[who].online then emit("WHISPER",who,"PERSONAL_CANCEL",id) end
  end
  self.personalEvents[id]=nil
  save()
  self:Refresh()
end
local function apply(op, f, actor)
  if op=="GUILD_EVENT" then
    if not FT:IsGuildOfficer(actor) or not valid(f[2],80) or f[2]:sub(1,#actor+1)~=actor.."-" or
      not validWhen(f[3]) or not valid(f[4],70) or guildEventByID(f[2]) or FT.guildDeleted[f[2]] or #FT.guildEvents>=100 then return end
    table.insert(FT.guildEvents,{id=f[2],when=f[3],title=f[4],owner=actor,attendees={},declined={}})
    save(); FT:Refresh(); return
  elseif op=="GUILD_RSVP" then
    local event=guildEventByID(f[2])
    if not event or (f[3]~="yes" and f[3]~="no") then return end
    event.attendees=event.attendees or {}; event.declined=event.declined or {}
    event.attendees[actor]=f[3]=="yes" and true or nil
    event.declined[actor]=f[3]=="no" and true or nil
    save(); FT:Refresh(); return
  elseif op=="GUILD_ATTEND" then
    local event=guildEventByID(f[2])
    if not event or event.owner~=actor or not FT.roster[norm(f[3])] or
      (f[4]~="yes" and f[4]~="no") then return end
    event.attendees[norm(f[3])]=f[4]=="yes" and true or nil
    event.declined[norm(f[3])]=f[4]=="no" and true or nil
    save(); FT:Refresh(); return
  elseif op=="GUILD_DEL" then
    if not valid(f[2],80) or not FT:IsGuildOfficer(actor) then return end
    for i, current in ipairs(FT.guildEvents) do
      if current.id==f[2] then table.remove(FT.guildEvents,i); break end
    end
    FT.guildDeleted[f[2]]=true
    save(); FT:Refresh(); return
  end
  if op == "ATTUNE" then
    local version = tonumber(f[3])
    local count = FT.attunementData and #FT.attunementData or 0
    if f[2] ~= actor or version ~= (FT.progressVersion or 1) or
      type(f[4]) ~= "string" or #f[4] ~= count or not f[4]:match("^[CPMU]+$") or
      (f[5] ~= "Alliance" and f[5] ~= "Horde" and f[5] ~= "Neutral") then return end
    FT.attunements[actor] = {version=version, states=f[4], faction=f[5], updated=time()}
    save()
    FT:Refresh()
    return
  end
  if op == "PROFILE" then
    if f[2] ~= actor or not role(f[3]) or not role(f[4], true) then return end
    FT.profiles[actor] = { main = f[3], off = f[4] }
    save()
    FT:Refresh()
    return
  end
  if op == "PROF" then
    if f[2] ~= actor or not valid(f[3], 40) or not valid(f[4], 8) or
      not valid(f[5], 40) or not valid(f[6], 8) or not tonumber(f[4]) or not tonumber(f[6]) then return end
    FT.professions[actor] = {{name=f[3], rank=tonumber(f[4])}, {name=f[5], rank=tonumber(f[6])}}
    save()
    FT:Refresh()
    return
  end
  if op == "PREF" then
    if f[2] ~= actor or not valid(f[3], 70) or
      (f[4] ~= "PvE" and f[4] ~= "PvP" and f[4] ~= "Both") then return end
    FT.playerInfo[actor] = {availability=f[3], interest=f[4]}
    save()
    FT:Refresh()
    return
  end
  local id, team = f[2], FT.teams[f[2]]
  if op == "NEW" then
    if not valid(id, 48) or not valid(f[3], 24) or not valid(f[4], 48) or not valid(f[5], 70) then return end
    if f[6] ~= actor or team or not FT:CanOwnTeam(actor, f[3], FT:Color(f[7]).name) or FT.deleted[id] then return end
    FT.teams[id] = { id = id, name = f[3], focus = f[4], motd = f[5], owner = actor,
      color = FT:Color(f[7]).name,
      members = {}, ownerParticipates=false, events = {}, fromNotes=id:sub(1,5)=="note-" }
    save()
    rosterRefresh()
  elseif op == "DEL" and team and FT:CanDelete(team, actor) then
    FT.deleted[id]={owner=team.owner, by=actor}
    FT.teams[id]=nil
    FT.requests[id]=nil
    FT.invitations[id]=nil
    if FT.selected==id then FT.selected=nil end
    save()
  elseif op == "TRANSFER" and team and FT:IsGuildOfficer(actor) and FT.roster[norm(f[3])] and
    valid(f[4],20) and tonumber(f[4]) and
    tonumber(f[4])>(tonumber(team.ownerChangedAt) or 0) then
    local nextOwner=norm(f[3])
    FT:RecordActivity(team,display(actor).." transferred leadership from "..
      display(team.owner).." to "..display(nextOwner))
    team.owner=nextOwner
    team.delegatedOwner=nextOwner
    team.ownerChangedAt=tonumber(f[4])
    team.ownerParticipates=team.members[nextOwner] and true or false
    save()
  elseif not team then return
  elseif op == "APPLY" and actor == f[3] and not team.members[actor] and
    (not f[4] or valid(f[4], 70)) and (not f[5] or f[5] == "PvE" or f[5] == "PvP" or f[5] == "Both") then
    FT.requests[id] = FT.requests[id] or {}
    FT.requests[id][actor] = {availability=f[4] or "Not provided", interest=f[5] or "Not provided"}
    save()
  elseif op == "INVITE" and FT:CanManage(team, actor) and FT.roster[norm(f[3])] then
    FT.invitations[id] = FT.invitations[id] or {}
    FT.invitations[id][norm(f[3])] = true
    save()
  elseif op == "JOIN" and actor == f[3] and FT.invitations[id] and FT.invitations[id][actor] and not team.members[actor] then
    team.members[actor] = "member"
    FT:RecordActivity(team,display(actor).." joined the team")
    clearPending(id, actor)
    save()
  elseif op == "ACCEPT" and FT:CanManage(team, actor) and FT.requests[id] and FT.requests[id][norm(f[3])] and not team.members[norm(f[3])] then
    team.members[norm(f[3])] = "member"
    FT:RecordActivity(team,display(f[3]).." was accepted by "..display(actor))
    clearPending(id, norm(f[3]))
    save()
  elseif op == "ADD" and FT:CanManage(team, actor) and FT.roster[norm(f[3])] and not team.members[norm(f[3])] then
    team.members[norm(f[3])]="member"
    FT:RecordActivity(team,display(f[3]).." was added by "..display(actor))
    if team.noteMembers then team.noteMembers[norm(f[3])]=nil end
    clearPending(id, norm(f[3]))
    save()
  elseif op == "PART" and actor == team.owner and f[3] == actor then
    if f[4] == "yes" then team.members[actor]="member"
    elseif f[4] == "no" then team.members[actor]=nil
    else return end
    team.ownerParticipates=f[4] == "yes"
    FT:RecordActivity(team,display(actor)..(f[4] == "yes" and " joined the active roster" or " left the active roster"))
    save()
  elseif op == "REMOVE" and (actor == norm(f[3]) or FT:CanManage(team, actor)) and team.owner ~= norm(f[3]) then
    if team.members[norm(f[3])] then
      FT:RecordActivity(team,display(f[3])..(actor == norm(f[3]) and " left the team" or " was removed by "..display(actor)))
    end
    team.members[norm(f[3])] = nil
    if team.noteMembers then team.noteMembers[norm(f[3])]=nil end
    clearPending(id, norm(f[3]))
    save()
  elseif op == "ROLE" and (FT:IsGuildOfficer(actor) or (actor == team.owner and FT:CanManage(team, actor))) and team.members[norm(f[3])] and norm(f[3]) ~= team.owner and (f[4] == "officer" or f[4] == "member") then
    team.members[norm(f[3])] = f[4]
    FT:RecordActivity(team,display(f[3]).." was made "..f[4].." by "..display(actor))
    save()
  elseif op == "MOTD" and FT:CanManage(team, actor) and valid(f[3], 150) then
    if team.motd ~= f[3] then FT:RecordActivity(team,display(actor).." changed the team message") end
    team.motd = f[3]
    save()
  elseif op == "FOCUS" and FT:CanManage(team, actor) and valid(f[3], 48) then
    if team.focus ~= f[3] then FT:RecordActivity(team,display(actor).." changed the team focus") end
    team.focus = f[3]
    save()
  elseif op == "COLOR" and FT:CanManage(team, actor) and FT:Color(f[3]).name == f[3] and
    (FT:IsGuildOfficer(actor) or actor ~= team.owner or FT:CanOwnTeam(actor, team.name, f[3])) then
    if team.color ~= f[3] then FT:RecordActivity(team,display(actor).." changed the team color to "..f[3]) end
    team.color = f[3]
    save()
  elseif op == "EVENT" and FT:CanManage(team, actor) and valid(f[3], 48) and validWhen(f[4]) and
    valid(f[5], 70) and not eventByID(team, f[3]) and not (team.deletedEvents and team.deletedEvents[f[3]]) and #team.events < 100 then
    table.insert(team.events, {id = f[3], when = f[4], title = f[5], by = actor, attendees = {}})
    FT:RecordActivity(team,display(actor).." added event: "..f[5])
    save()
  elseif op == "EVENT_DEL" and FT:CanManage(team,actor) and valid(f[3],48) then
    local event=eventByID(team,f[3])
    if event then
      FT:RecordActivity(team,display(actor).." removed event: "..event.title)
      for i, current in ipairs(team.events) do
        if current.id==f[3] then table.remove(team.events,i); break end
      end
    end
    team.deletedEvents=team.deletedEvents or {}
    team.deletedEvents[f[3]]=true
    save()
  elseif op == "RSVP" and team.members[actor] and (f[4] == "yes" or f[4] == "no") then
    local event = eventByID(team, f[3])
    if event then
      event.attendees = event.attendees or {}
      event.declined = event.declined or {}
      local changed=(f[4]=="yes" and not event.attendees[actor]) or (f[4]=="no" and not event.declined[actor])
      event.attendees[actor] = f[4] == "yes" and true or nil
      event.declined[actor] = f[4] == "no" and true or nil
      if changed then FT:RecordActivity(team,display(actor)..(f[4]=="yes" and " confirmed for " or " declined ")..event.title) end
      save()
    end
  elseif op == "ATTEND" and actor == team.owner and team.members[norm(f[4])] and
    (f[5] == "yes" or f[5] == "no") then
    local event = eventByID(team, f[3])
    if event then
      event.attendees = event.attendees or {}
      event.declined = event.declined or {}
      event.attendees[norm(f[4])] = f[5] == "yes" and true or nil
      event.declined[norm(f[4])] = f[5] == "no" and true or nil
      save()
    end
  elseif op == "RAID_SIZE" and FT:CanManage(team,actor) and (f[4]=="20" or f[4]=="40") then
    local event=eventByID(team,f[3])
    if event then
      event.raidSize=tonumber(f[4])
      event.slots=event.slots or {}
      for slot in pairs(event.slots) do if slot>event.raidSize then event.slots[slot]=nil end end
      save()
    end
  elseif op == "RAID_SLOT" and FT:CanManage(team,actor) then
    local event=eventByID(team,f[3])
    local slot=tonumber(f[4])
    local who=norm(f[5])
    if event and event.raidSize and slot and slot==math.floor(slot) and slot>=1 and slot<=event.raidSize and
      (f[5]=="clear" or event.attendees and event.attendees[who] and team.members[who]) then
      event.slots=event.slots or {}
      if f[5]~="clear" then
        for index, assigned in pairs(event.slots) do if assigned==who then event.slots[index]=nil end end
        event.slots[slot]=who
      else event.slots[slot]=nil end
      save()
    end
  elseif op == "SYNC" and actor == team.owner and FT:CanManage(team, actor) then
    -- Received team metadata from its leader; membership is sent separately.
    if valid(f[3], 24) and valid(f[4], 48) and valid(f[5], 150) then
      team.name, team.focus, team.motd = f[3], f[4], f[5]
      team.color = FT:Color(f[6]).name
      save()
    end
  elseif op == "ROSTER" and actor == team.owner and FT:CanManage(team, actor) and valid(f[3], 80) and (f[4] == "member" or f[4] == "officer" or f[4] == "leader") then
    local who = norm(f[3])
    if FT.roster[who] and (f[4] ~= "leader" or who == team.owner) then
      team.members[who] = f[4] == "leader" and "member" or f[4]
      if who == team.owner then team.ownerParticipates=true end
      clearPending(id, who)
      save()
    end
  end
  FT:Refresh()
end
function FT:Act(op, ...)
  local fields = {op, ...}
  for _, value in ipairs(fields) do if not valid(value, 150) then self:Notice("That entry is too long or contains an unsupported character."); return end end
  apply(op, fields, selfName())
  if op == "PROF" or op == "PREF" or op == "PROFILE" or op == "ATTUNE" then sendPrivate(op, ...)
  elseif op == "APPLY" then send(op, fields[2], selfName())
  else send(op, ...) end
end
local function syncTeams()
  if not myGuild() then return end
  local readiness = FT.attunements[selfName()]
  if readiness then
    sendPrivate("ATTUNE", selfName(), tostring(readiness.version), readiness.states, readiness.faction)
  end
  local own = FT.profiles[selfName()]
  if own then sendPrivate("PROFILE", selfName(), own.main, own.off) end
  local trades = FT.professions[selfName()]
  if trades and trades[1] and trades[2] then
    sendPrivate("PROF", selfName(), trades[1].name, tostring(trades[1].rank), trades[2].name, tostring(trades[2].rank))
  end
  local info = FT.playerInfo[selfName()]
  if info then sendPrivate("PREF", selfName(), info.availability, info.interest) end
  local delay = 0
  local pendingPackets = {}
  for _, event in ipairs(FT.guildEvents) do
    if event.owner==selfName() then
      table.insert(pendingPackets,{"GUILD_EVENT",event.id,event.when,event.title})
      for who in pairs(event.attendees or {}) do
        table.insert(pendingPackets,{"GUILD_ATTEND",event.id,who,"yes"})
      end
      for who in pairs(event.declined or {}) do
        table.insert(pendingPackets,{"GUILD_ATTEND",event.id,who,"no"})
      end
    end
    if event.attendees and event.attendees[selfName()] then
      table.insert(pendingPackets,{"GUILD_RSVP",event.id,"yes"})
    elseif event.declined and event.declined[selfName()] then
      table.insert(pendingPackets,{"GUILD_RSVP",event.id,"no"})
    end
  end
  if FT:IsGuildOfficer(selfName()) then
    for id in pairs(FT.guildDeleted) do table.insert(pendingPackets,{"GUILD_DEL",id}) end
  end
  for id, team in pairs(FT.teams) do
    if FT:IsGuildOfficer(selfName()) and team.delegatedOwner and team.ownerChangedAt then
      table.insert(pendingPackets,{"NEW",id,team.name,team.focus,(team.motd or ""):sub(1,70),selfName(),FT:Color(team.color).name})
      table.insert(pendingPackets,{"TRANSFER",id,team.owner,tostring(team.ownerChangedAt)})
    end
    if team.owner == selfName() then
      local packets = {{"NEW", id, team.name, team.focus, team.motd, team.owner, FT:Color(team.color).name},
        {"SYNC", id, team.name, team.focus, team.motd, FT:Color(team.color).name}}
      for who, role in pairs(team.members) do
        table.insert(packets, {"ROSTER", id, who, role})
      end
      for _, event in ipairs(team.events) do
        if event.id and event.when and event.title then
          table.insert(packets, {"EVENT", id, event.id, event.when, event.title})
          for who in pairs(event.attendees or {}) do
            table.insert(packets, {"ATTEND", id, event.id, who, "yes"})
          end
          for who in pairs(event.declined or {}) do
            table.insert(packets, {"ATTEND", id, event.id, who, "no"})
          end
          if event.raidSize then
            table.insert(packets,{"RAID_SIZE",id,event.id,tostring(event.raidSize)})
            for slot, who in pairs(event.slots or {}) do
              table.insert(packets,{"RAID_SLOT",id,event.id,tostring(slot),who})
            end
          end
        end
      end
      for eventID in pairs(team.deletedEvents or {}) do
        table.insert(packets,{"EVENT_DEL",id,eventID})
      end
      for _, packet in ipairs(packets) do table.insert(pendingPackets, packet) end
    end
    if FT.requests[id] and FT.requests[id][selfName()] and not team.members[selfName()] then
      table.insert(pendingPackets, {"APPLY", id, selfName()})
    end
    if team.members[selfName()] then
      for _, event in ipairs(team.events) do
        if event.attendees and event.attendees[selfName()] then
          table.insert(pendingPackets,{"RSVP",id,event.id,"yes"})
        elseif event.declined and event.declined[selfName()] then
          table.insert(pendingPackets,{"RSVP",id,event.id,"no"})
        end
      end
    end
    if FT:CanManage(team, selfName()) and FT.invitations[id] then
      for who in pairs(FT.invitations[id]) do
        if not team.members[who] then table.insert(pendingPackets, {"INVITE", id, who}) end
      end
    end
  end
  for _, event in pairs(FT.personalEvents) do
    if event.owner == selfName() then
      for who in pairs(event.invited or {}) do
        if FT.roster[who] and FT.roster[who].online then
          local payload={"PERSONAL",event.id,event.when,event.title,event.note or ""}
          delay=delay+0.35
          C_Timer.After(delay,function() emit("WHISPER",who,unpack(payload)) end)
        end
      end
    elseif FT.roster[event.owner] and FT.roster[event.owner].online then
      local status=event.attendees and event.attendees[selfName()] and "yes" or
        event.declined and event.declined[selfName()] and "no"
      if status then emit("WHISPER",event.owner,"PERSONAL_RSVP",event.id,status) end
    end
  end
  for id, record in pairs(FT.deleted) do
    if FT:IsGuildOfficer(selfName()) or (record.owner == selfName() and FT:IsTeamLeader(selfName())) then
      table.insert(pendingPackets, {"DEL",id})
    end
  end
  for _, packet in ipairs(pendingPackets) do
    local payload = packet
    delay = delay + 0.35
    C_Timer.After(delay, function() send(unpack(payload)) end)
  end
end
function FT:CheckConnection()
  if not myGuild() then return end
  self.peers={}
  self.checkID=(self.checkID or 0)+1
  local checkID=self.checkID
  send("HELLO",selfName())
  C_Timer.After(8,function()
    if FT.checkID ~= checkID then return end
    local count=0
    for _ in pairs(FT.peers) do count=count+1 end
    if count == 0 then FT:Notice("No Connection Found: no other guild member online with EXIN Teams.")
    else FT:Notice("EXIN connected to "..count.." guild addon user"..(count == 1 and "." or "s.")) end
  end)
end
function FT:OpenGuild()
  local guild = myGuild()
  if not guild then self:Notice("Join a guild before using teams."); return false end
  ForeverTeamsDB = ForeverTeamsDB or {}
  ForeverTeamsDB[guild] = ForeverTeamsDB[guild] or {teams = {}}
  self.db = ForeverTeamsDB[guild]
  self.db.personalEvents=self.db.personalEvents or {}
  self.personalEvents=self.db.personalEvents
  self.db.guildEvents=self.db.guildEvents or {}
  self.guildEvents=self.db.guildEvents
  self.db.guildDeleted=self.db.guildDeleted or {}
  self.guildDeleted=self.db.guildDeleted
  self.teams = self.db.teams
  self.db.profiles = self.db.profiles or {}
  self.profiles = self.db.profiles
  self.db.professions = self.db.professions or {}
  self.professions = self.db.professions
  self.db.playerInfo = self.db.playerInfo or {}
  self.playerInfo = self.db.playerInfo
  self.db.attunements = self.db.attunements or {}
  self.attunements = self.db.attunements
  self.db.deleted = self.db.deleted or {}
  self.deleted = self.db.deleted
  self.db.requests = self.db.requests or {}
  self.db.invitations = self.db.invitations or {}
  self.requests = self.db.requests
  self.invitations = self.db.invitations
  for id, team in pairs(self.teams) do
    if type(team) ~= "table" or type(team.members) ~= "table" or type(team.owner) ~= "string" then
      self.teams[id] = nil
    else
      team.events = team.events or {}
      team.color = self:Color(team.color).name
      if team.ownerParticipates==nil then team.ownerParticipates=team.members[team.owner] and true or false end
    end
  end
  if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster()
  elseif GuildRoster then GuildRoster() end
  rosterRefresh()
  save()
  if not self.announced then
    for _, team in pairs(self.teams) do
      if team.members[selfName()] then self:Notice(team.name .. ": " .. (team.motd or "")) end
    end
    self.announced = true
  end
  return true
end
function FT:UpdateProfessions()
  if not GetProfessions or not GetProfessionInfo or not self.db then return end
  local first, second = GetProfessions()
  local function read(index)
    if not index then return "None", "0" end
    local name, _, rank = GetProfessionInfo(index)
    if not name or not valid(name, 40) then return "None", "0" end
    return name, tostring(tonumber(rank) or 0)
  end
  local name1, rank1 = read(first)
  local name2, rank2 = read(second)
  local old=self.professions[selfName()]
  if old and old[1] and old[2] and old[1].name==name1 and old[1].rank==tonumber(rank1) and
    old[2].name==name2 and old[2].rank==tonumber(rank2) then return end
  self:Act("PROF", selfName(), name1, rank1, name2, rank2)
end
local activeQuests = {}
function FT:RefreshQuestCache()
  wipe(activeQuests)
  local total = 0
  if C_QuestLog and C_QuestLog.GetNumQuestLogEntries then
    total = C_QuestLog.GetNumQuestLogEntries() or 0
  elseif GetNumQuestLogEntries then
    total = GetNumQuestLogEntries() or 0
  end
  for index = 1, total do
    local questID
    if C_QuestLog and C_QuestLog.GetInfo then
      local info = C_QuestLog.GetInfo(index)
      questID = info and not info.isHeader and info.questID
    elseif GetQuestLogTitle then
      local _, _, _, isHeader, _, _, _, id = GetQuestLogTitle(index)
      if not isHeader then questID = id end
    end
    if questID then activeQuests[questID] = true end
  end
end
function FT:IsQuestComplete(questID)
  if not questID then return false end
  if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
    return C_QuestLog.IsQuestFlaggedCompleted(questID) and true or false
  elseif IsQuestFlaggedCompleted then
    return IsQuestFlaggedCompleted(questID) and true or false
  end
  return false
end
function FT:IsQuestActive(questID)
  if not questID then return false end
  if C_QuestLog and C_QuestLog.IsOnQuest then
    return C_QuestLog.IsOnQuest(questID) and true or false
  end
  return activeQuests[questID] and true or false
end
local function questIDs(entry, field)
  if entry[field] then return entry[field] end
  return entry.id and {entry.id} or {}
end
function FT:QuestState(entry)
  local faction = UnitFactionGroup("player") or "Neutral"
  local class = select(2, UnitClass("player"))
  if entry.side and entry.side ~= faction then return "X" end
  if entry.class and entry.class ~= class then return "X" end
  for _, questID in ipairs(questIDs(entry, "completeIDs")) do
    if self:IsQuestComplete(questID) then return "C" end
  end
  for _, questID in ipairs(questIDs(entry, "activeIDs")) do
    if self:IsQuestActive(questID) then return "P" end
  end
  return "M"
end
local function raidState(entry)
  if not entry.published then return "U" end
  if entry.itemID and GetItemCount and GetItemCount(entry.itemID, true) > 0 then return "C" end
  for _, questID in ipairs(entry.completeIDs or {}) do
    if FT:IsQuestComplete(questID) then return "C" end
  end
  for _, questID in ipairs(entry.activeIDs or entry.completeIDs or {}) do
    if FT:IsQuestActive(questID) then return "P" end
  end
  return "M"
end
function FT:UpdateAttunements(force)
  if not self.db or not self.attunementData then return end
  self:RefreshQuestCache()
  local states = {}
  for _, entry in ipairs(self.attunementData) do table.insert(states, raidState(entry)) end
  local stateText = table.concat(states)
  local faction = UnitFactionGroup("player") or "Neutral"
  local who = selfName()
  local old = self.attunements[who]
  local changed = not old or old.version ~= (self.progressVersion or 1) or
    old.states ~= stateText or old.faction ~= faction
  self.attunements[who] = {version=self.progressVersion or 1, states=stateText, faction=faction, updated=time()}
  save()
  if changed or force then
    sendPrivate("ATTUNE", who, tostring(self.progressVersion or 1), stateText, faction)
  end
  self:Refresh()
end
local progressQueued
local function queueProgressUpdate(force)
  if progressQueued then return end
  progressQueued = true
  C_Timer.After(0.75, function()
    progressQueued = nil
    FT:UpdateAttunements(force)
  end)
end
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_GUILD_UPDATE")
frame:RegisterEvent("GUILD_ROSTER_UPDATE")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("SKILL_LINES_CHANGED")
frame:RegisterEvent("QUEST_LOG_UPDATE")
frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:SetScript("OnEvent", function(_, event, ...)
  if event == "PLAYER_LOGIN" then
    local ok = C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix and C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
    if not ok and RegisterAddonMessagePrefix then RegisterAddonMessagePrefix(PREFIX) end
    FT:OpenGuild()
    C_Timer.After(2, function() FT:UpdateProfessions() end)
    C_Timer.After(2.5, function() FT:UpdateAttunements(true) end)
    C_Timer.After(4, function()
      FT:CheckConnection()
      local own = FT.profiles[selfName()]
      if own then sendPrivate("PROFILE", selfName(), own.main, own.off) end
    end)
  elseif event == "SKILL_LINES_CHANGED" then
    C_Timer.After(0.5, function() FT:UpdateProfessions() end)
  elseif event == "QUEST_LOG_UPDATE" or event == "BAG_UPDATE_DELAYED" then
    queueProgressUpdate(false)
  elseif event == "PLAYER_GUILD_UPDATE" then FT:OpenGuild()
  elseif event == "GUILD_ROSTER_UPDATE" then rosterRefresh()
  elseif event == "CHAT_MSG_ADDON" then
    local prefix, message, channel, sender = ...
    if prefix ~= PREFIX or (channel ~= "GUILD" and channel ~= "WHISPER") or type(message) ~= "string" or #message > 240 then return end
    local actor = norm(sender)
    if actor == selfName() or not FT.roster[actor] then return end
    if FT.peers then FT.peers[actor]=true end
    local fields = {}
    for part in (message .. "|"):gmatch("(.-)|") do table.insert(fields, part) end
    if fields[1] == "PERSONAL" then
      if channel~="WHISPER" or not valid(fields[2],80) or fields[2]:sub(1,#actor+1)~=actor.."-" or
        not validWhen(fields[3]) or not valid(fields[4],70) or
        (fields[5] and (#fields[5]>60 or fields[5]:find("[\r\n]"))) then return end
      local entry=FT.personalEvents[fields[2]]
      if not entry then
        entry={id=fields[2],owner=actor,invited={[selfName()]=true},attendees={[actor]=true},declined={}}
        FT.personalEvents[fields[2]]=entry
      end
      if entry.owner~=actor then return end
      entry.when,entry.title,entry.note=fields[3],fields[4],fields[5] or ""
      local status=entry.attendees and entry.attendees[selfName()] and "yes" or
        entry.declined and entry.declined[selfName()] and "no"
      if status then emit("WHISPER",actor,"PERSONAL_RSVP",entry.id,status) end
      save(); FT:Refresh(); return
    elseif fields[1] == "PERSONAL_RSVP" then
      local entry=FT.personalEvents[fields[2]]
      if channel~="WHISPER" or not entry or entry.owner~=selfName() or not entry.invited[actor] or
        (fields[3]~="yes" and fields[3]~="no") then return end
      entry.attendees[actor]=fields[3]=="yes" and true or nil
      entry.declined[actor]=fields[3]=="no" and true or nil
      save(); FT:Refresh(); return
    elseif fields[1] == "PERSONAL_CANCEL" then
      local entry=FT.personalEvents[fields[2]]
      if channel~="WHISPER" or not entry or entry.owner~=actor then return end
      FT.personalEvents[fields[2]]=nil
      save(); FT:Refresh(); return
    end
    if (fields[1] == "PROF" or fields[1] == "PREF" or fields[1] == "PROFILE" or fields[1] == "ATTUNE") then
      if channel ~= "WHISPER" then return end
      local allowed=FT:IsGuildOfficer(selfName())
      for id, team in pairs(FT.teams) do
        if (team.members[actor] or team.owner == actor or (FT.requests[id] and FT.requests[id][actor])) and
          FT:CanSeeDetails(team, selfName()) then allowed=true; break end
      end
      if not allowed then return end
    elseif channel ~= "GUILD" then return end
    if fields[1] == "HELLO" then
      emit("WHISPER",actor,"PONG")
      syncTeams()
      return
    end
    if fields[1] == "PONG" then return end
    apply(fields[1], fields, actor)
  end
end)
