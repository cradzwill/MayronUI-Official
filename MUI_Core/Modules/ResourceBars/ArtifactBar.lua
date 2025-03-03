-- luacheck: ignore self 143 631
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, _, em, _, obj = MayronUI:GetCoreComponents(); -- luacheck: ignore
if (not tk:IsRetail()) then return end

local C_ArtifactUI, ArtifactBarMixin, StatusTrackingBarManager = _G.C_ArtifactUI, _G.ArtifactBarMixin, _G.StatusTrackingBarManager;
local GetNumPurchasableArtifactTraits = _G.ArtifactBarGetNumArtifactTraitsPurchasableFromXP;
local C_ArtifactBar = obj:Import("MayronUI.ArtifactBar");
local strformat, select = _G.string.format, _G.select;

-- Local Functions -----------------------
local function OnArtifactXPUpdate(_, _, bar, data)
  if (not bar:CanUse()) then
    bar:SetActive(false);
    return;
  end

  if (not bar:IsActive()) then
    bar:SetActive(true);
  end

  local totalXP, pointsSpent, _, _, _, _, _, _, tier = select(5, C_ArtifactUI.GetEquippedArtifactInfo());
  local _, currentValue, maxValue = GetNumPurchasableArtifactTraits(pointsSpent, totalXP, tier);

  data.statusbar:SetMinMaxValues(0, maxValue);
  data.statusbar:SetValue(currentValue);

  if currentValue > 0 and maxValue == 0 then
    maxValue = currentValue;
  end

  local percent = 100 - tk.Numbers:ToPrecision((currentValue / maxValue) * 100, 2);
  currentValue = tk.Strings:FormatReadableNumber(currentValue);
  maxValue = tk.Strings:FormatReadableNumber(maxValue);

  local text = strformat("%s / %s (%d%% remaining)", currentValue, maxValue, percent);
  data.statusbar.text:SetText(text);
end

-- C_ArtifactBar -------------------------

obj:DefineParams("ResourceBars", "table");
function C_ArtifactBar:__Construct(data, barsModule, moduleData)
  self:CreateResourceBar(barsModule, moduleData, "artifact");
  data.blizzardBar = _G.ArtifactWatchBar;
end

obj:DefineReturns("boolean");
function C_ArtifactBar:CanUse()
  if (obj:IsTable(StatusTrackingBarManager) and obj:IsFunction(StatusTrackingBarManager.CanShowBar)) then
    local barIndex = tk.Constants.RESOURCE_BAR_IDS.Artifact;
    return StatusTrackingBarManager:CanShowBar(barIndex) == true;
  end

  if (obj:IsTable(ArtifactBarMixin) and obj:IsFunction(ArtifactBarMixin.ShouldBeVisible)) then
    return ArtifactBarMixin:ShouldBeVisible() == true;
  end

  return false;
end

obj:DefineParams("boolean");
function C_ArtifactBar:SetActive(data, active)
  self:CallParentMethod("SetActive", active);

  if (active and data.notCreated) then
    data.statusbar.texture = data.statusbar:GetStatusBarTexture();
    local r, g, b = _G.ARTIFACT_BAR_COLOR:GetRGB();
    data.statusbar.texture:SetVertexColor(r, g, b, 0.8);
    data.notCreated = nil;
  end
end

obj:DefineParams("boolean");
function C_ArtifactBar:SetEnabled(data, enabled)
  if (enabled) then
    (em:GetEventListenerByID("ArtifactXP_Update") or
     em:CreateEventListenerWithID("ArtifactXP_Update", OnArtifactXPUpdate))
      :SetCallbackArgs(self, data)
      :RegisterEvents("ARTIFACT_XP_UPDATE", "UNIT_INVENTORY_CHANGED");

    if (self:CanUse()) then
      if (not self:IsActive()) then
          self:SetActive(true);
      end

      -- must be triggered AFTER it has been created!
      em:TriggerEventListenerByID("ArtifactXP_Update");
    end

  elseif (self:IsActive()) then
    self:SetActive(false);
  end

  local listener = em:GetEventListenerByID("ArtifactXP_Update");

  if (listener) then
    listener:SetEnabled(enabled);
  end
end