-- luacheck: ignore MayronUI self 143 631
local MayronUI = _G.MayronUI;
local _, db, _, _, obj = MayronUI:GetCoreComponents();
local C_Timer, string = _G.C_Timer, _G.string;
local GetNetStats, GetFramerate = _G.GetNetStats, _G.GetFramerate;

-- Register and Import Modules -------
local Performance = obj:CreateClass("Performance");

-- Load Database Defaults ------------

db:AddToDefaults("profile.datatext.performance", {
  showFps = true,
  showHomeLatency = true,
  showServerLatency = false
});

-- Performance Module --------------

MayronUI:Hook("DataTextModule", "OnInitialize", function(self)
  local sv = db.profile.datatext.performance;
  sv:SetParent(db.profile.datatext);

  local settings = sv:GetTrackedTable();
  self:RegisterComponentClass("performance", Performance, settings);
end);

function Performance:__Construct(data, settings, dataTextModule)
  data.settings = settings;
  self.TotalLabelsShown = 0;
  self.HasLeftMenu = false;
  self.HasRightMenu = false;
  self.Button = dataTextModule:CreateDataTextButton();
end

function Performance:SetEnabled(data, enabled)
  data.enabled = enabled;
  if (not enabled) then
    data.executed = nil;
  end
end

function Performance:IsEnabled(data)
  return data.enabled;
end

local function FormatLabelByLatency(label, latency)
    if (latency <= 100) then
        label = string.format("%s |cff32cd32%u|r ms", label, latency);
    end

    if (latency >= 101 and latency <= 250) then
        label = string.format("%s |cffffcc00%u|r ms", label, latency);
    end

    if (latency >= 251) then
        label = string.format("%s |cffff0000%u|r ms", label, latency);
    end

    return label;
end

function Performance:Update(data, refreshSettings)
  if (refreshSettings) then
    data.settings:Refresh();
  end

  if (data.executed) then return end

  data.executed = true;

  local function loop()
    if (not data.enabled) then return end
    local _, _, latencyHome, latencyServer = GetNetStats();

    local label = "";

    if (data.settings.showFps) then
      label = string.format("|cffffffff%u|r fps", GetFramerate());
    end

    if (data.settings.showHomeLatency) then
      label = FormatLabelByLatency(label, latencyHome);
    end
    if (data.settings.showServerLatency) then
      label = FormatLabelByLatency(label, latencyServer);
    end

    self.Button:SetText(label:trim());

    C_Timer.After(3, loop);
  end

  loop();
end

function Performance:Click() end