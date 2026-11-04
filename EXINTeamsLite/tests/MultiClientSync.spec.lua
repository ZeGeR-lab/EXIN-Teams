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
member.env.C_ChatInfo.SendAddonMessage(member.LT.PREFIX,"HELLO|"..member.LT:SelfName(),"GUILD")
flush()
assert(member.LT.teams.crimson~=nil,"HELLO handshake should replicate the team")
assert(member.LT.teams.crimson.owner=="member-aeriepeak","team owner should replicate")
assert(member.LT.teams.crimson.members["member-aeriepeak"]=="leader","owner Leader role should replicate")

-- The remote owner edits metadata; both installations must converge.
member.LT:Act("NAME","crimson","Crimson Raiders")
flush()
assert(snoop.LT.teams.crimson.name=="Crimson Raiders","owner metadata edit should replicate to admin")
assert(member.LT.teams.crimson.name=="Crimson Raiders","owner metadata edit should persist locally")

-- A remote roster edit must be reflected on both clients.
member.LT:Act("ADD","crimson","Officer-AeriePeak")
flush()
assert(snoop.LT.teams.crimson.members["officer-aeriepeak"]=="member","member addition should replicate to admin")
assert(member.LT.teams.crimson.members["officer-aeriepeak"]=="member","member addition should persist locally")

-- Guild Master authorization is replicated and grants guild-wide Officer access.
snoop.LT:Act("AUTH","Officer-AeriePeak","yes","2100")
flush()
assert(member.LT:IsGuildOfficer("Officer-AeriePeak"),"authorized Officer status should replicate")

-- Simulate a disconnected client missing a deletion broadcast.
member.online=false
snoop.LT:Act("DEL","crimson")
flush()
assert(snoop.LT.teams.crimson==nil and snoop.LT.deleted.crimson~=nil,"admin deletion should create a tombstone")
local sentBeforeReconnect=#sent
member.online=true
member.env.C_ChatInfo.SendAddonMessage(member.LT.PREFIX,"HELLO|"..member.LT:SelfName(),"GUILD")
flush()
local tombstoneReplay=false
for i=sentBeforeReconnect+1,#sent do
  local packet=sent[i]
  if packet.from==snoop.name and packet.message=="DEL|crimson" then tombstoneReplay=true end
end
assert(tombstoneReplay,"reconnecting client should trigger an Officer tombstone replay")
assert(member.LT.teams.crimson==nil,"reconnect tombstone replay must remove a stale team")
assert(member.LT.deleted.crimson~=nil,"reconnect should persist the deletion tombstone")

-- A stale NEW packet cannot resurrect the deleted team on either client.
local stale="NEW|crimson|Old Crimson|Raid||Member-AeriePeak|Blue|E01"
member.eventHandler(nil,"CHAT_MSG_ADDON",member.LT.PREFIX,stale,"GUILD","Snoop Wharg-AeriePeak")
assert(member.LT.teams.crimson==nil,"stale NEW must not resurrect a tombstoned team")
print("MultiClientSync.spec.lua: all two-client synchronization tests passed")
