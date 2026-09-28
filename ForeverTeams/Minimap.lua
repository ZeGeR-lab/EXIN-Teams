local _, FT = ...

local button = CreateFrame("Button", "EXINTeamsMinimapButton", Minimap)
button:SetSize(32, 32)
button:SetFrameStrata("MEDIUM")
button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
button:EnableMouse(true)
button:RegisterForClicks("LeftButtonUp")
button:RegisterForDrag("LeftButton")

local icon = button:CreateTexture(nil, "ARTWORK")
icon:SetAllPoints(button)
icon:SetTexture("Interface\\AddOns\\ForeverTeams\\EXIN_Icon")

local angle = math.rad(220)
local function place()
  -- The minimap's decorative rim extends beyond its map texture. Keep the
  -- button centered on that rim at the default size, and follow larger maps.
  local radius = math.max(100, (Minimap:GetWidth() or 0) / 2 + 10)
  button:ClearAllPoints()
  button:SetPoint("CENTER", Minimap, "CENTER", radius * math.cos(angle), radius * math.sin(angle))
end
local function cursorAngle(y, x)
  if math.atan2 then return math.atan2(y, x) end
  if atan2 then return atan2(y, x) end
  if x == 0 then return y >= 0 and math.pi / 2 or -math.pi / 2 end
  local result = math.atan(y / x)
  if x < 0 then result = result + (y >= 0 and math.pi or -math.pi) end
  return result
end
local function drag()
  local scale = Minimap:GetEffectiveScale()
  local cursorX, cursorY = GetCursorPosition()
  local centerX, centerY = Minimap:GetCenter()
  if not centerX or not centerY or not scale or scale == 0 then return end
  angle = cursorAngle(cursorY / scale - centerY, cursorX / scale - centerX)
  place()
end
button:SetScript("OnDragStart", function(self)
  self.dragged = true
  self:SetScript("OnUpdate", drag)
end)
button:SetScript("OnDragStop", function(self)
  self:SetScript("OnUpdate", nil)
  drag()
  ForeverTeamsDB = ForeverTeamsDB or {}
  ForeverTeamsDB.minimapAngle = angle
  self.draggedAt = GetTime()
end)
button:SetScript("OnClick", function(self)
  if self.draggedAt and GetTime() - self.draggedAt < 0.3 then return end
  if FT.Toggle then FT:Toggle() end
end)
button:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_LEFT")
  GameTooltip:AddLine("EXIN Teams", 0.61, 0.86, 0.25)
  GameTooltip:AddLine("Click to open · Drag to move", 1, 1, 1)
  GameTooltip:Show()
end)
button:SetScript("OnLeave", function() GameTooltip:Hide() end)

local init = CreateFrame("Frame")
init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent", function()
  if ForeverTeamsDB and type(ForeverTeamsDB.minimapAngle) == "number" then
    angle = ForeverTeamsDB.minimapAngle
  end
  place()
end)
place()
