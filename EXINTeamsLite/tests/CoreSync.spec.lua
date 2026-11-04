local captured
local roster={
  {"Snoop Wharg-AeriePeak","Member",4,80,"Warrior",nil,"",nil,true},
  {"Guildmaster-AeriePeak","Guild Master",0,80,"Paladin",nil,"",nil,true},
  {"Officer-AeriePeak","Member",4,80,"Mage",nil,"",nil,true},
  {"Member-AeriePeak","Member",4,80,"Priest",nil,"",nil,true},
  {"OldMember-AeriePeak","Member",4,80,"Rogue",nil,"",nil,true},
  {"Random-AeriePeak","Member",4,80,"Hunter",nil,"",nil,true},
  {"Zzz-AeriePeak","Member",4,80,"Hunter",nil,"",nil,true},
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
LT.authorizedOfficers["zzz-aeriepeak"]={by="guildmaster-aeriepeak",at=200,revoked=false}
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
receive("ROSTER|team1|OldMember-AeriePeak|leader","Member-AeriePeak")
receive("RCLR|team1","OldMember-AeriePeak")
assert(LT.teams.team1.members["officer-aeriepeak"]=="officer","Team Leader must not be able to clear the complete team roster")
assert(not LT:IsGuildOfficer("OldMember-AeriePeak"),"ordinary Team Leader must not have guild-wide Officer permissions")
receive("AUTH|Member-AeriePeak|yes|203","OldMember-AeriePeak")
assert(LT.authorizedOfficers["member-aeriepeak"].at==201,"Team Leader must not change guild-wide Officer permissions")
assert(LT:CanManage(LT.teams.team1,"OldMember-AeriePeak"),"fixture should establish Team Leader management access")
assert((tonumber(LT.teams.team1.metaChangedAt) or 0)<10,"metadata revision fixture should allow revision 10")
receive("NAME|team1|Leader Rename|10","OldMember-AeriePeak")
assert(LT.teams.team1.name=="Leader Rename","Team Leader should be able to manage team metadata")
receive("SYNC|team1|Stale Snapshot|General||Red|E02|member-aeriepeak|150|5","Officer-AeriePeak")
assert(LT.teams.team1.name=="Leader Rename","older reconnect snapshot must not roll back newer team metadata")
receive("NAME|team1|Stale Rename|9","OldMember-AeriePeak")
assert(LT.teams.team1.name=="Leader Rename","older metadata revision must not overwrite a newer edit")
receive("NAME|team1|Tie Winner|11","Zzz-AeriePeak")
receive("NAME|team1|Tie Loser|11","OldMember-AeriePeak")
assert(LT.teams.team1.name=="Tie Winner","same-second metadata edits should resolve consistently by actor identity")
receive("MOTD|team1|Current message|12","Officer-AeriePeak")
receive("MOTD|team1|Stale message|11","Officer-AeriePeak")
assert(LT.teams.team1.motd=="Current message","stale team message must not overwrite newer message")
receive("MOTD|team1||13","Officer-AeriePeak")
assert(LT.teams.team1.motd=="","a newer blank team message should clear the previous message")
receive("MOTD|team1|Stale restore|12","Officer-AeriePeak")
assert(LT.teams.team1.motd=="","stale team message must not restore a cleared message")
receive("FOCUS|team1|Raid Progression|14","Zzz-AeriePeak")
receive("FOCUS|team1|Old Focus|13","Officer-AeriePeak")
assert(LT.teams.team1.focus=="Raid Progression","stale focus update must be rejected")
receive("COLOR|team1|Red|15","Officer-AeriePeak")
receive("COLOR|team1|Blue|14","Zzz-AeriePeak")
assert(LT.teams.team1.color=="Red","stale team color update must be rejected")
receive("EMBLEM|team1|E22|16","Zzz-AeriePeak")
receive("EMBLEM|team1|E02|15","Officer-AeriePeak")
assert(LT.teams.team1.emblem=="E22","stale team emblem update must be rejected")
receive("DEL|team1","OldMember-AeriePeak")
assert(LT.teams.team1~=nil,"Team Leader must not be allowed to delete a team")
receive("AUTH|Member-AeriePeak|yes|202","Officer-AeriePeak")
assert(LT.authorizedOfficers["member-aeriepeak"].at==201,"designated Officers must not alter Guild Master-only permissions")
receive("AUTH|Member-AeriePeak|no|202","Guildmaster-AeriePeak")
assert(LT.authorizedOfficers["member-aeriepeak"].revoked,"Guild Master should be able to revoke designated Officer access")

-- Ordinary members cannot manage team metadata or perform Officer-only deletion.
receive("NAME|team1|Unauthorized Rename","Random-AeriePeak")
assert(LT.teams.team1.name=="Tie Winner","ordinary member must not rename a team")
receive("DEL|team1","Random-AeriePeak")
assert(LT.teams.team1~=nil,"ordinary member must not delete a team")

-- Only designated Officers may create teams; ordinary members cannot self-create one.
receive("NEW|team2|Unauthorized Team|General||Random-AeriePeak|Blue|E01","Random-AeriePeak")
assert(LT.teams.team2==nil,"ordinary member must not create a team")
receive("NEW|team2|Officer Team|General||Random-AeriePeak|Blue|E01","Officer-AeriePeak")
assert(LT.teams.team2~=nil and LT.teams.team2.owner=="random-aeriepeak","designated Officer should be able to create a team for a guild member")

-- Designated Officers may delete teams, even without an in-game Officer rank.
receive("DEL|team1","Officer-AeriePeak")
assert(LT.teams.team1==nil and LT.deleted.team1~=nil,"designated Officer should be allowed to delete a team")
receive("NEW|team1|Resurrected Team|General||Random-AeriePeak|Blue|E01","Officer-AeriePeak")
assert(LT.teams.team1==nil,"a deleted team must not be recreated from a stale NEW packet")

-- Guild roster refresh removes manual memberships for characters who left the guild.
receive("ROSTER|team2|Zzz-AeriePeak|officer","Officer-AeriePeak")
assert(LT.teams.team2.members["zzz-aeriepeak"]=="officer","fixture should add a manual member")
local savedRoster=roster
roster={}
for _,entry in ipairs(savedRoster) do
  if entry[1]~="Zzz-AeriePeak" then table.insert(roster,entry) end
end
captured(nil,"GUILD_ROSTER_UPDATE")
assert(LT.teams.team2.members["zzz-aeriepeak"]==nil,"guild leaver must be removed from the local team roster")
assert(LT.teams.team2.manualMembers["zzz-aeriepeak"]==nil,"guild leaver manual-membership provenance must be pruned")
roster=savedRoster
captured(nil,"GUILD_ROSTER_UPDATE")
assert(LT.teams.team2.members["zzz-aeriepeak"]==nil,"a returning character must not regain stale manual membership")

-- Legacy color-based guild notes must remain primary across repeated refreshes.
roster[7][7]="Blue - DiscordZzz"
captured(nil,"GUILD_ROSTER_UPDATE")
assert(LT.teams.team2.noteMembers["zzz-aeriepeak"]==true,"color-based legacy note should be recognized")
captured(nil,"GUILD_ROSTER_UPDATE")
assert(LT.teams.team2.noteMembers["zzz-aeriepeak"]==true,"recognized legacy note membership must not be erased on the next refresh")

-- Changing a public note moves primary membership, and Discord names may contain hyphens.
LT.teams.team3={
  id="team3",name="Team Three",focus="General",motd="",color="Red",owner="random-aeriepeak",
  members={["random-aeriepeak"]="leader"},noteMembers={},manualMembers={["random-aeriepeak"]=true},events={}
}
roster[7][7]="Team Three - Discord - Zzz"
captured(nil,"GUILD_ROSTER_UPDATE")
assert(LT.teams.team2.noteMembers["zzz-aeriepeak"]==nil,"changing the guild note should remove the old primary team membership")
assert(LT.teams.team3.noteMembers["zzz-aeriepeak"]==true,"changing the guild note should assign the new primary team membership")
assert(LT.roster["zzz-aeriepeak"].discordName=="Discord - Zzz","Discord names containing hyphens should be preserved")
-- Local UI-originated action validation must also accept an empty message.
LT.teams.team2.motd="Message to clear"
LT:Act("MOTD","team2","")
assert(LT.teams.team2.motd=="","local team manager action should be able to clear the message")
print("CoreSync.spec.lua: all synchronization and permission tests passed")
