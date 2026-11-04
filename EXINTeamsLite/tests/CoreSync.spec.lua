local captured
local roster={
  {"Snoop Wharg-AeriePeak","Member",4,80,"Warrior",nil,"",nil,true},
  {"Guildmaster-AeriePeak","Guild Master",0,80,"Paladin",nil,"",nil,true},
  {"Officer-AeriePeak","Member",4,80,"Mage",nil,"",nil,true},
  {"Member-AeriePeak","Member",4,80,"Priest",nil,"",nil,true},
  {"OldMember-AeriePeak","Member",4,80,"Rogue",nil,"",nil,true},
}
function CreateFrame()
  local f={}
  function f:RegisterEvent() end
  function f:SetScript(_,fn) captured=fn end
  return f
end
function GetGuildInfo() return "Ex Inferno","Member",4 end
function UnitFullName() return "Snoop Wharg","AeriePeak" end
function UnitName() return "Snoop Wharg" end
function GetNumGuildMembers() return #roster end
function GetGuildRosterInfo(i) return unpack(roster[i]) end
function wipe(t) for k in pairs(t) do t[k]=nil end end
function time() return 1000 end
function GetTime() return 1 end
C_Timer={After=function() end}
C_ChatInfo={RegisterAddonMessagePrefix=function() end,SendAddonMessage=function() end}
local LT={}
assert(loadfile("EXINTeamsLite/Core.lua"))("EXINTeamsLite",LT)
LT:OpenGuild()
assert(LT:IsGuildLeader("Snoop Wharg-AeriePeak"),"permanent admin override should resolve unique realm-qualified name")
LT.authorizedOfficers["member-aeriepeak"]={by="guildmaster-aeriepeak",at=200,revoked=true}
local function receive(message,sender)
  captured(nil,"CHAT_MSG_ADDON",LT.PREFIX,message,"GUILD",sender)
end
receive("AUTH|Member-AeriePeak|yes|199","Guildmaster-AeriePeak")
assert(LT.authorizedOfficers["member-aeriepeak"].revoked,"stale grant must not undo a newer revocation")
receive("AUTH|Member-AeriePeak|yes|201","Guildmaster-AeriePeak")
assert(not LT.authorizedOfficers["member-aeriepeak"].revoked,"newer grant should be accepted")
receive("AUTH|Member-AeriePeak|no|200","Guildmaster-AeriePeak")
assert(not LT.authorizedOfficers["member-aeriepeak"].revoked,"stale revocation must not undo a newer grant")
LT.authorizedOfficers["officer-aeriepeak"]={by="guildmaster-aeriepeak",at=200,revoked=false}
LT.teams.team1={
  id="team1",name="Old Team",focus="General",motd="",color="Blue",emblem="E01",
  owner="oldmember-aeriepeak",ownerChangedAt=100,
  members={["oldmember-aeriepeak"]="leader",["member-aeriepeak"]="member",["officer-aeriepeak"]="officer"},
  noteMembers={["member-aeriepeak"]=true},manualMembers={["oldmember-aeriepeak"]=true,["officer-aeriepeak"]=true},events={}
}
receive("SYNC|team1|Team Alpha|General||Blue|E01|member-aeriepeak|150","Officer-AeriePeak")
assert(LT.teams.team1.owner=="member-aeriepeak","trusted newer ownership snapshot should reconcile")
assert(LT.teams.team1.members["member-aeriepeak"]=="leader","new owner must receive Leader role")
assert(LT.teams.team1.members["oldmember-aeriepeak"]=="officer","previous owner Leader role should be demoted")
receive("SYNC|team1|Old Team|General||Blue|E01|oldmember-aeriepeak|140","Officer-AeriePeak")
assert(LT.teams.team1.owner=="member-aeriepeak","stale ownership snapshot must not roll back owner")
assert(LT.teams.team1.name=="Team Alpha","rejected stale snapshot must not partially overwrite metadata")
receive("RCLR|team1","Officer-AeriePeak")
assert(LT.teams.team1.members["officer-aeriepeak"]==nil,"roster reset must remove stale manual membership")
assert(LT.teams.team1.members["member-aeriepeak"]=="leader","roster reset must preserve note membership and owner role")
receive("ROSTER|team1|Officer-AeriePeak|officer","Officer-AeriePeak")
assert(LT.teams.team1.members["officer-aeriepeak"]=="officer","roster replay should restore current manual membership")

-- Team Leaders may manage their team, but cannot delete it or change guild-wide permissions.
receive("NAME|team1|Leader Rename","OldMember-AeriePeak")
assert(LT.teams.team1.name=="Leader Rename","team owner should be able to manage team metadata")
receive("DEL|team1","OldMember-AeriePeak")
assert(LT.teams.team1~=nil,"team owner must not be allowed to delete a team")
receive("AUTH|Member-AeriePeak|yes|202","Officer-AeriePeak")
assert(LT.authorizedOfficers["member-aeriepeak"].at==201,"designated Officers must not alter Guild Master-only permissions")
receive("AUTH|Member-AeriePeak|no|202","Guildmaster-AeriePeak")
assert(LT.authorizedOfficers["member-aeriepeak"].revoked,"Guild Master should be able to revoke designated Officer access")

-- Ordinary members cannot manage team metadata or perform Officer-only deletion.
receive("NAME|team1|Unauthorized Rename","Member-AeriePeak")
assert(LT.teams.team1.name=="Leader Rename","ordinary member must not rename a team")
receive("DEL|team1","Member-AeriePeak")
assert(LT.teams.team1~=nil,"ordinary member must not delete a team")

-- Designated Officers may delete teams, even without an in-game Officer rank.
receive("DEL|team1","Officer-AeriePeak")
assert(LT.teams.team1==nil and LT.deleted.team1~=nil,"designated Officer should be allowed to delete a team")
print("CoreSync.spec.lua: all synchronization and permission tests passed")
