local events={}
local roster={
  {"Snoop Wharg-AeriePeak","Member",4,80,"Warrior",nil,"",nil,true},
  {"Guildmaster-AeriePeak","Guild Master",0,80,"Paladin",nil,"",nil,true},
  {"Officer-AeriePeak","Member",4,80,"Mage",nil,"",nil,true},
  {"Member-AeriePeak","Member",4,80,"Priest",nil,"",nil,true},
  {"OldMember-AeriePeak","Member",4,80,"Rogue",nil,"",nil,true},
}
function CreateFrame()
  local f={}
  function f:RegisterEvent(e) events[e]=true end
  function f:SetScript(_,fn) self.handler=fn end
  return f
end
function GetGuildInfo() return "Ex Inferno","Guild Master",0 end
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
local chunk=assert(loadfile("EXINTeamsLite/Core.lua"))
chunk("EXINTeamsLite",LT)
local frame=_G.EXINTeamsLite and nil
local handler
-- The frame is the only event frame created by Core.lua.
-- Capture its registered event callback through the CreateFrame mock.
local captured
CreateFrame=function()
  local f={}
  function f:RegisterEvent() end
  function f:SetScript(_,fn) captured=fn end
  return f
end
