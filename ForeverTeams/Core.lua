local ADDON, FT = ...
_G.ForeverTeams = FT
FT.version = 1
FT.teams = {}
FT.roster = {}
FT.invitations = {}
FT.requests = {}
FT.events = {}
FT.profiles = {}
FT.professions = {}
FT.playerInfo = {}
FT.attunements = {}
FT.selected = nil
FT.colors = {
  {name="Pink", hex="ff83b7"}, {name="Purple", hex="aa89ff"},
  {name="Blue", hex="69b6ff"}, {name="Green", hex="78d996"},
  {name="Yellow", hex="f7d96b"}, {name="Orange", hex="ffab69"},
  {name="Red", hex="ff7777"}, {name="White", hex="eeeeee"},
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
  return (s:gsub("%-.*$", ""))
end
local function selfName() return norm(UnitName("player")) end
local function valid(s, max)
  return type(s) == "string" and #s > 0 and #s <= max and not s:find("[|\r\n]")
end
local function myGuild() return GetGuildInfo("player") end
local function rosterRefresh()
  wipe(FT.roster)
  local total = GetNumGuildMembers and GetNumGuildMembers() or 0
  for i = 1, total do
    local name, rank, rankID, level, class, _, _, _, online = GetGuildRosterInfo(i)
    if name then FT.roster[norm(name)] = { name = name, rank = rank, rankID = rankID, level = level, class = class, online = online } end
  end
  FT:Refresh()
end
function FT:Refresh() if self.Draw then self:Draw() end end
function FT:Notice(s) print("|cff9bdd00EXIN Teams:|r " .. s) end
function FT:Member(team, who) return team and team.members[norm(who)] end
function FT:CanManage(team, who)
  local role = self:Member(team, who)
  return role == "leader" or role == "officer"
end
local function send(op, ...)
  if not myGuild() then return end
  local fields = {op, ...}
  for _, field in ipairs(fields) do if type(field) ~= "string" or field:find("[|\r\n]") then return end end
  local msg = table.concat(fields, "|")
  if #msg > 240 then return end
  if C_ChatInfo and C_ChatInfo.SendAddonMessage then
    C_ChatInfo.SendAddonMessage(PREFIX, msg, "GUILD")
  elseif SendAddonMessage then
    SendAddonMessage(PREFIX, msg, "GUILD")
  end
end
local function save()
  if FT.db then
    FT.db.teams = FT.teams
    FT.db.requests = FT.requests
    FT.db.invitations = FT.invitations
    FT.db.professions = FT.professions
    FT.db.playerInfo = FT.playerInfo
    FT.db.attunements = FT.attunements
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
local function validWhen(s)
  if type(s) ~= "string" then return false end
  local year, month, day, hour, minute = s:match("^(%d%d%d%d)%-(%d%d)%-(%d%d) (%d%d):(%d%d)$")
  return year and tonumber(month) >= 1 and tonumber(month) <= 12 and
    tonumber(day) >= 1 and tonumber(day) <= 31 and tonumber(hour) <= 23 and tonumber(minute) <= 59
end
local function apply(op, f, actor)
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
    if FT.db then FT.db.profiles = FT.profiles end
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
    if f[6] ~= actor or team then return end
    FT.teams[id] = { id = id, name = f[3], focus = f[4], motd = f[5], owner = actor,
      color = FT:Color(f[7]).name,
      members = {[actor] = "leader"}, events = {} }
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
    clearPending(id, actor)
    save()
  elseif op == "ACCEPT" and FT:CanManage(team, actor) and FT.requests[id] and FT.requests[id][norm(f[3])] and not team.members[norm(f[3])] then
    team.members[norm(f[3])] = "member"
    clearPending(id, norm(f[3]))
    save()
  elseif op == "REMOVE" and (actor == norm(f[3]) or FT:CanManage(team, actor) and team.owner ~= norm(f[3])) and team.owner ~= norm(f[3]) then
    team.members[norm(f[3])] = nil
    clearPending(id, norm(f[3]))
    save()
  elseif op == "ROLE" and actor == team.owner and team.members[norm(f[3])] and norm(f[3]) ~= team.owner and (f[4] == "officer" or f[4] == "member") then
    team.members[norm(f[3])] = f[4]
    save()
  elseif op == "MOTD" and FT:CanManage(team, actor) and valid(f[3], 150) then
    team.motd = f[3]
    save()
  elseif op == "FOCUS" and FT:CanManage(team, actor) and valid(f[3], 48) then
    team.focus = f[3]
    save()
  elseif op == "COLOR" and FT:CanManage(team, actor) and FT:Color(f[3]).name == f[3] then
    team.color = f[3]
    save()
  elseif op == "EVENT" and FT:CanManage(team, actor) and valid(f[3], 48) and validWhen(f[4]) and
    valid(f[5], 70) and not eventByID(team, f[3]) and #team.events < 20 then
    table.insert(team.events, {id = f[3], when = f[4], title = f[5], by = actor, attendees = {}})
    save()
  elseif op == "RSVP" and team.members[actor] and (f[4] == "yes" or f[4] == "no") then
    local event = eventByID(team, f[3])
    if event then
      event.attendees = event.attendees or {}
      event.attendees[actor] = f[4] == "yes" and true or nil
      save()
    end
  elseif op == "ATTEND" and actor == team.owner and team.members[norm(f[4])] and
    (f[5] == "yes" or f[5] == "no") then
    local event = eventByID(team, f[3])
    if event then
      event.attendees = event.attendees or {}
      event.attendees[norm(f[4])] = f[5] == "yes" and true or nil
      save()
    end
  elseif op == "SYNC" and actor == team.owner then
    -- Received team metadata from its leader; membership is sent separately.
    if valid(f[3], 24) and valid(f[4], 48) and valid(f[5], 150) then
      team.name, team.focus, team.motd = f[3], f[4], f[5]
      team.color = FT:Color(f[6]).name
      save()
    end
  elseif op == "ROSTER" and actor == team.owner and valid(f[3], 80) and (f[4] == "member" or f[4] == "officer" or f[4] == "leader") then
    local who = norm(f[3])
    if FT.roster[who] and (f[4] ~= "leader" or who == team.owner) then
      team.members[who] = f[4]
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
  send(op, ...)
end
local function syncTeams()
  if not myGuild() then return end
  local readiness = FT.attunements[selfName()]
  if readiness then
    send("ATTUNE", selfName(), tostring(readiness.version), readiness.states, readiness.faction)
  end
  local own = FT.profiles[selfName()]
  if own then send("PROFILE", selfName(), own.main, own.off) end
  local trades = FT.professions[selfName()]
  if trades and trades[1] and trades[2] then
    send("PROF", selfName(), trades[1].name, tostring(trades[1].rank), trades[2].name, tostring(trades[2].rank))
  end
  local info = FT.playerInfo[selfName()]
  if info then send("PREF", selfName(), info.availability, info.interest) end
  local delay = 0
  local pendingPackets = {}
  for id, team in pairs(FT.teams) do
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
        end
      end
      for _, packet in ipairs(packets) do table.insert(pendingPackets, packet) end
    end
    if FT.requests[id] and FT.requests[id][selfName()] and not team.members[selfName()] then
      local request=FT.requests[id][selfName()]
      table.insert(pendingPackets, {"APPLY", id, selfName(),
        type(request)=="table" and request.availability or "Not provided",
        type(request)=="table" and request.interest or "Both"})
    end
    if FT:CanManage(team, selfName()) and FT.invitations[id] then
      for who in pairs(FT.invitations[id]) do
        if not team.members[who] then table.insert(pendingPackets, {"INVITE", id, who}) end
      end
    end
  end
  for _, packet in ipairs(pendingPackets) do
    local payload = packet
    delay = delay + 0.35
    C_Timer.After(delay, function() send(unpack(payload)) end)
  end
end
function FT:OpenGuild()
  local guild = myGuild()
  if not guild then self:Notice("Join a guild before using teams."); return false end
  ForeverTeamsDB = ForeverTeamsDB or {}
  ForeverTeamsDB[guild] = ForeverTeamsDB[guild] or {teams = {}}
  self.db = ForeverTeamsDB[guild]
  self.teams = self.db.teams
  self.db.profiles = self.db.profiles or {}
  self.profiles = self.db.profiles
  self.db.professions = self.db.professions or {}
  self.professions = self.db.professions
  self.db.playerInfo = self.db.playerInfo or {}
  self.playerInfo = self.db.playerInfo
  self.db.attunements = self.db.attunements or {}
  self.attunements = self.db.attunements
  self.db.requests = self.db.requests or {}
  self.db.invitations = self.db.invitations or {}
  self.requests = self.db.requests
  self.invitations = self.db.invitations
  for id, team in pairs(self.teams) do
    if type(team) ~= "table" or type(team.members) ~= "table" or type(team.owner) ~= "string" then
      self.teams[id] = nil
    else team.events = team.events or {}; team.color = self:Color(team.color).name end
  end
  if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster()
  elseif GuildRoster then GuildRoster() end
  rosterRefresh()
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
    send("ATTUNE", who, tostring(self.progressVersion or 1), stateText, faction)
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
      send("HELLO", selfName())
      local own = FT.profiles[selfName()]
      if own then send("PROFILE", selfName(), own.main, own.off) end
    end)
  elseif event == "SKILL_LINES_CHANGED" then
    C_Timer.After(0.5, function() FT:UpdateProfessions() end)
  elseif event == "QUEST_LOG_UPDATE" or event == "BAG_UPDATE_DELAYED" then
    queueProgressUpdate(false)
  elseif event == "PLAYER_GUILD_UPDATE" then FT:OpenGuild()
  elseif event == "GUILD_ROSTER_UPDATE" then rosterRefresh()
  elseif event == "CHAT_MSG_ADDON" then
    local prefix, message, channel, sender = ...
    if prefix ~= PREFIX or channel ~= "GUILD" or type(message) ~= "string" or #message > 240 then return end
    local actor = norm(sender)
    if actor == selfName() or not FT.roster[actor] then return end
    local fields = {}
    for part in (message .. "|"):gmatch("(.-)|") do table.insert(fields, part) end
    if fields[1] == "HELLO" then syncTeams(); return end
    apply(fields[1], fields, actor)
  end
end)
