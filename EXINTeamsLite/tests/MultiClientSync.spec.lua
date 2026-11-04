-- Two-client synchronization integration test for EXIN Teams Lite.
local roster = {
  {"Snoop Wharg-AeriePeak","Guild Master",0,80,"Warrior",nil,"",nil,true},
  {"Member-AeriePeak","Member",4,80,"Priest",nil,"",nil,true},
  {"Officer-AeriePeak","Member",4,80,"Mage",nil,"",nil,true},
}
local clients, queue, sent = {}, {}, {}
local function normalize(s) return (tostring(s or ""):lower():gsub("%s+","-")) end
local function deliver(sender, prefix, message, channel, target)
  table.insert(sent,{from=sender.name,message=message,channel=channel,target=target})
  if channel == "GUILD" then
    for _, client in ipairs(clients) do
      if client.online then
        table.insert(queue,{client=client,prefix=prefix,message=message,channel=channel,sender=sender.name})
      end
    end
  elseif channel == "WHISPER" then
    for _, client in ipairs(clients) do
      if client.online and normalize(client.name)==normalize(target) then
        table.insert(queue,{client=client,prefix=prefix,message=message,channel=channel,sender=sender.name})
      end
    end
  end
end
local function flush()
  local guard=0
  while #queue>0 do
    guard=guard+1
    assert(guard<1000,"message loop detected")
    local item=table.remove(queue,1)
    item.client.eventHandler(nil,"CHAT_MSG_ADDON",item.prefix,item.message,item.channel,item.sender)
  end
end
local function newClient(name)
  local client={name=name,online=true,frames={},saved={}}
  local env={}
  setmetatable(env,{__index=_G})
  env._G=env
  client.env=env
  env.EXINTeamsLiteDB=client.saved
  env.CreateFrame=function()
    local frame={}
    function frame:RegisterEvent() end
    function frame:SetScript(_,fn) client.eventHandler=fn end
    table.insert(client.frames,frame)
    return frame
  end
  env.GetGuildInfo=function() return "Ex Inferno","Member",4 end
  env.GetRealmName=function() return "AeriePeak" end
  env.UnitFullName=function() return name:match("^([^%-]+)%-?(.*)$") end
  env.UnitName=function() return name:match("^([^%-]+)") end
  env.GetNumGuildMembers=function() return #roster end
  env.GetGuildRosterInfo=function(i) return unpack(roster[i]) end
  env.wipe=function(t) for k in pairs(t) do t[k]=nil end end
  env.time=function() return 2000 end
  env.GetTime=function() return 1 end
  env.C_Timer={After=function(_,fn) end}
  env.C_ChatInfo={
    RegisterAddonMessagePrefix=function() end,
    SendAddonMessage=function(prefix,message,channel,target)
      deliver(client,prefix,message,channel,target)
    end
  }
  local chunk=assert(loadfile("EXINTeamsLite/Core.lua"))
  setfenv(chunk,env)
  client.LT={}
  chunk("EXINTeamsLite",client.LT)
  client.LT:OpenGuild()
  return client
end
local snoop=newClient("Snoop Wharg-AeriePeak")
local member=newClient("Member-AeriePeak")
table.insert(clients,snoop)
table.insert(clients,member)

-- A guild-wide admin creates a team owned by the second client.
snoop.LT:Act("NEW","crimson","Team Crimson","Raid","","Member-AeriePeak","Blue","E01")
flush()
assert(snoop.LT.teams.crimson~=nil,"creator should have the new team")
assert(member.LT.teams.crimson~=nil,"guild broadcast should deliver the new team to the connected client")

-- Member reconnects; the authoritative admin responds with a complete snapshot.
member.env.C_ChatInfo.SendAddonMessage(member.LT.PREFIX,"Ex Inferno@AeriePeak|HELLO|"..member.LT:SelfName(),"GUILD")
flush()
assert(member.LT.teams.crimson~=nil,"HELLO handshake should replicate the team")
assert(member.LT.teams.crimson.owner=="member-aeriepeak","team owner should replicate")
assert(member.LT.teams.crimson.members["member-aeriepeak"]=="leader","owner Leader role should replicate")

-- The remote owner edits metadata; both installations must converge.
member.LT:Act("NAME","crimson","Crimson Raiders")
flush()
assert(snoop.LT.teams.crimson.name=="Crimson Raiders","owner metadata edit should replicate to admin")
assert(member.LT.teams.crimson.name=="Crimson Raiders","owner metadata edit should persist locally")

-- Empty team messages must synchronize as a real clear, not be ignored.
member.LT:Act("MOTD","crimson","Recruiting now")
flush()
assert(snoop.LT.teams.crimson.motd=="Recruiting now","team message should replicate to admin")
member.LT:Act("MOTD","crimson","")
flush()
assert(snoop.LT.teams.crimson.motd=="","cleared team message should replicate to admin")
assert(member.LT.teams.crimson.motd=="","cleared team message should persist on owner")

-- A remote roster edit must be reflected on both clients.
member.LT:Act("ADD","crimson","Officer-AeriePeak")
flush()
assert(snoop.LT.teams.crimson.members["officer-aeriepeak"]=="member","member addition should replicate to admin")
assert(member.LT.teams.crimson.members["officer-aeriepeak"]=="member","member addition should persist locally")

-- Guild Master authorization is replicated and grants guild-wide Officer access.
snoop.LT:Act("AUTH","Officer-AeriePeak","yes","2100")
flush()
assert(member.LT:IsGuildOfficer("Officer-AeriePeak"),"authorized Officer status should replicate")

-- Simultaneous team creation with the same name must converge regardless of arrival order.
-- Both authorized clients create locally before either broadcast is delivered.
snoop.LT:Act("NEW","z-team","Collision Team","Raid","","Member-AeriePeak","Blue","E01")
local officerClient=newClient("Officer-AeriePeak")
table.insert(clients,officerClient)
officerClient.env.C_ChatInfo.SendAddonMessage(officerClient.LT.PREFIX,"Ex Inferno@AeriePeak|HELLO|"..officerClient.LT:SelfName(),"GUILD")
flush()
assert(officerClient.LT:IsGuildOfficer("Officer-AeriePeak"),"new Officer client should receive its authorization during reconnect sync")
officerClient.LT:Act("NEW","a-team","Collision Team","Raid","","Officer-AeriePeak","Red","E02")
assert(snoop.LT.teams["z-team"]~=nil and officerClient.LT.teams["a-team"]~=nil,"fixture should create the conflicting teams independently")
flush()
for _,client in ipairs(clients) do
  assert(client.LT.teams["a-team"]~=nil,"every client should retain the lexicographically smallest team ID")
  assert(client.LT.teams["z-team"]==nil,"every client should discard the losing duplicate team")
  assert(client.LT.deleted["z-team"]~=nil,"losing duplicate team should receive a tombstone")
end
local staleDuplicate="Ex Inferno@AeriePeak|NEW|z-team|Collision Team|Raid||Member-AeriePeak|Blue|E01"
member.eventHandler(nil,"CHAT_MSG_ADDON",member.LT.PREFIX,staleDuplicate,"GUILD","Snoop Wharg-AeriePeak")
assert(member.LT.teams["z-team"]==nil,"a stale duplicate NEW packet must not resurrect the losing team")

-- Concurrent ownership transfers with identical timestamps must converge by actor identity.
-- Snoop's normalized identity sorts after Officer's, so Snoop's transfer wins on every client.
snoop.LT:Act("TRANSFER","a-team","Member-AeriePeak","2300")
officerClient.LT:Act("TRANSFER","a-team","Snoop Wharg-AeriePeak","2300")
flush()
for _,client in ipairs(clients) do
  assert(client.LT.teams["a-team"].owner=="member-aeriepeak","equal-time ownership transfers must converge on the same deterministic winner")
  assert(client.LT.teams["a-team"].ownerChangedAt==2300,"winning ownership revision should be preserved without arrival-order increments")
  assert(client.LT.teams["a-team"].ownerChangedBy=="snoop-wharg-aeriepeak","winning transfer actor should be recorded consistently")
end

-- Simultaneous deletion by two Officers must remain idempotent and final.
snoop.LT:Act("DEL","a-team")
officerClient.LT:Act("DEL","a-team")
flush()
for _,client in ipairs(clients) do
  assert(client.LT.teams["a-team"]==nil,"concurrent deletion must remove the team on every client")
  assert(client.LT.deleted["a-team"]~=nil,"concurrent deletion must leave a durable tombstone")
end
-- Delayed snapshots and roster updates must never recreate a tombstoned team.
local staleTeamSync="Ex Inferno@AeriePeak|SYNC|a-team|Restored Team|Raid||Blue|E01|member-aeriepeak|2300|0||snoop-wharg-aeriepeak"
local staleTeamRoster="Ex Inferno@AeriePeak|ROSTER|a-team|officer-aeriepeak|leader"
member.eventHandler(nil,"CHAT_MSG_ADDON",member.LT.PREFIX,staleTeamSync,"GUILD","Snoop Wharg-AeriePeak")
member.eventHandler(nil,"CHAT_MSG_ADDON",member.LT.PREFIX,staleTeamRoster,"GUILD","Officer-AeriePeak")
assert(member.LT.teams["a-team"]==nil,"delayed SYNC and ROSTER packets must not recreate a deleted team")
local staleTeamNew="Ex Inferno@AeriePeak|NEW|a-team|Restored Team|Raid||Member-AeriePeak|Blue|E01"
member.eventHandler(nil,"CHAT_MSG_ADDON",member.LT.PREFIX,staleTeamNew,"GUILD","Snoop Wharg-AeriePeak")
assert(member.LT.teams["a-team"]==nil,"delayed NEW must not recreate a deleted team")

-- Ownership transfer while the former owner is offline must reconcile on reconnect.
member.online=false
snoop.LT:Act("TRANSFER","crimson","Officer-AeriePeak","2200")
flush()
assert(snoop.LT.teams.crimson.owner=="officer-aeriepeak","transferring Officer should become owner locally")
assert(snoop.LT.teams.crimson.members["officer-aeriepeak"]=="leader","new owner should receive Leader role")
assert(snoop.LT.teams.crimson.members["member-aeriepeak"]=="officer","previous owner should be demoted to Officer")
member.online=true
member.env.C_ChatInfo.SendAddonMessage(member.LT.PREFIX,"Ex Inferno@AeriePeak|HELLO|"..member.LT:SelfName(),"GUILD")
flush()
assert(member.LT.teams.crimson.owner=="officer-aeriepeak","offline former owner should receive the new owner on reconnect")
assert(member.LT.teams.crimson.members["officer-aeriepeak"]=="leader","reconnect snapshot should restore new owner Leader role")
local staleOwner="Ex Inferno@AeriePeak|SYNC|crimson|Old Owner Snapshot|Raid||Blue|E01|member-aeriepeak|2199|0|"
member.eventHandler(nil,"CHAT_MSG_ADDON",member.LT.PREFIX,staleOwner,"GUILD","Snoop Wharg-AeriePeak")
assert(member.LT.teams.crimson.owner=="officer-aeriepeak","stale owner snapshot must not roll back a completed transfer")
assert(member.LT.teams.crimson.name=="Crimson Raiders","rejected stale owner snapshot must not overwrite metadata")

-- A replaced owner who leaves and later rejoins must not regain stale manual membership.
member.online=false
local beforeLeave=roster
roster={}
for _,entry in ipairs(beforeLeave) do if entry[1]~="Member-AeriePeak" then table.insert(roster,entry) end end
snoop.eventHandler(nil,"GUILD_ROSTER_UPDATE")
assert(snoop.LT.teams.crimson.owner=="officer-aeriepeak","former owner departure must not reverse the transfer")
assert(snoop.LT.teams.crimson.members["member-aeriepeak"]==nil,"departing former owner must be removed from team membership")
roster=beforeLeave
snoop.eventHandler(nil,"GUILD_ROSTER_UPDATE")
assert(snoop.LT.teams.crimson.owner=="officer-aeriepeak","former owner return must not reclaim ownership")
assert(snoop.LT.teams.crimson.members["member-aeriepeak"]==nil,"former owner must not regain stale manual membership after returning")
member.eventHandler(nil,"GUILD_ROSTER_UPDATE")
member.online=true

-- Simulate a disconnected client missing a deletion broadcast.
member.online=false
snoop.LT:Act("DEL","crimson")
flush()
assert(snoop.LT.teams.crimson==nil and snoop.LT.deleted.crimson~=nil,"admin deletion should create a tombstone")
local sentBeforeReconnect=#sent
member.online=true
member.env.C_ChatInfo.SendAddonMessage(member.LT.PREFIX,"Ex Inferno@AeriePeak|HELLO|"..member.LT:SelfName(),"GUILD")
flush()
local tombstoneReplay=false
for i=sentBeforeReconnect+1,#sent do
  local packet=sent[i]
  if packet.from==snoop.name and packet.message=="Ex Inferno@AeriePeak|DEL|crimson" then tombstoneReplay=true end
end
assert(tombstoneReplay,"reconnecting client should trigger an Officer tombstone replay")
assert(member.LT.teams.crimson==nil,"reconnect tombstone replay must remove a stale team")
assert(member.LT.deleted.crimson~=nil,"reconnect should persist the deletion tombstone")

-- A stale NEW packet cannot resurrect the deleted team on either client.
local stale="Ex Inferno@AeriePeak|NEW|crimson|Old Crimson|Raid||Member-AeriePeak|Blue|E01"
member.eventHandler(nil,"CHAT_MSG_ADDON",member.LT.PREFIX,stale,"GUILD","Snoop Wharg-AeriePeak")
assert(member.LT.teams.crimson==nil,"stale NEW must not resurrect a tombstoned team")
print("MultiClientSync.spec.lua: all two-client synchronization tests passed")
