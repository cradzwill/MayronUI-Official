-- luacheck: ignore MayronUI self 143 631
local obj = _G.MayronObjects:GetFramework();
local None = obj:CreateClass("None");

-- CombatTimer Module ----------------

MayronUI:Hook("DataTextModule", "OnInitialize", function(self)
  self:RegisterComponentClass("none", None);
end);

function None:__Construct(_, _, dataTextModule)
  -- set public instance properties
  self.TotalLabelsShown = 0;
  self.HasLeftMenu = false;
  self.HasRightMenu = false;
  self.Button = dataTextModule:CreateDataTextButton();
end

function None:Click() end

function None:IsEnabled(data)
  return data.enabled;
end

function None:SetEnabled(data, enabled)
  data.enabled = enabled;
end

function None:Update(_) end