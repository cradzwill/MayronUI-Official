-- luacheck: ignore self
local _G = _G;
local MayronUI, strupper = _G.MayronUI, _G.string.upper;
local tk, _, _, _, obj, L = MayronUI:GetCoreComponents();
local tostring = _G.tostring;

---@class MayronUI.ConfigMenuUtils
local Utils = MayronUI:NewComponent("ConfigMenuUtils");

local function GetDefaultValue(config)
  if (not config.dbPath) then return end

  local default;

  if (config.dbFramework == "orbitus") then
    local db = MayronUI:GetComponent(config.database)--[[@as OrbitusDB.DatabaseMixin]];
    default = db.utilities:QueryDefaults(config.dbPath);
  else
    local db = MayronUI:GetComponent(config.database or "Database");
    default = db:GetDefault(config.dbPath);
  end

  return default;
end

function Utils:SetComponentEnabled(component, enabled)
  if (obj:IsFunction(enabled)) then
    component:SetEnabled(enabled());
  elseif (enabled ~= nil) then
    if (obj:IsString(enabled)) then
      if (component.dbFramework == "orbitus") then
        local db = MayronUI:GetComponent(component.database)--[[@as OrbitusDB.DatabaseMixin]];
        local repo = db.utilities:GetRepositoryFromQuery(enabled);
        enabled = repo:Query(enabled);
      else
        local db = MayronUI:GetComponent("Database");
        enabled = db:ParsePathValue(enabled);
      end
    end

    component:SetEnabled(enabled);
  else
    component:SetEnabled(true);
  end
end

function Utils:SetShown(frame, shown)
  if (obj:IsFunction(shown)) then
    frame:SetShown(shown());
  elseif (shown ~= nil) then
    frame:SetShown(shown);
  else
    frame:SetShown(true);
  end
end

local componentNameSpacing = 8; -- spacing between name and the component

--- This function wraps the widget inside of a new container with a "name" fontstring label.
function Utils:WrapInNamedContainer(component, config)
  local oldParent = component:GetParent();
  local container = tk:CreateFrame("Frame", oldParent);
  component:SetParent(container);

  local currentWidth = component:GetWidth();
  container:SetWidth(currentWidth);

  -- this is needed to access the component from the container
  -- which is passed to some config functions (i.e. OnLoad):
  container.component = component;
  component.wrapper = container;

  container.name = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  container.name:SetPoint("TOPLEFT");
  container.name:SetText(config.name);

  local desiredWidth = (container.name:GetStringWidth() or 0);
  local default = self:AppendDefaultValueToTooltip(config);
  local canReset = default ~= nil and (obj:IsString(default) or obj:IsNumber(default) or obj:IsBoolean(default));

  if (obj:IsFunction(component.Reset) and canReset) then
    container.reset = tk:CreateFrame("Button", container);
    container.reset:SetPoint("TOPRIGHT");
    container.reset:SetSize(18, 18);
    desiredWidth = desiredWidth + 18 + 4; -- 4 for some spacing between name and reset button
    container.reset:SetNormalTexture(tk:GetAssetFilePath("Textures\\refresh"));

    local normalTexture = container.reset:GetNormalTexture()--[[@as Texture]];
    normalTexture:ClearAllPoints();
    normalTexture:SetPoint("TOPLEFT", 2, -2);
    normalTexture:SetPoint("BOTTOMRIGHT", -2, 2);
    tk:ApplyThemeColor(normalTexture);

    container.reset:SetHighlightAtlas("chatframe-button-highlight");

    local dbPath = config.dbPath;
    local dbFramework = config.dbFramework;
    local database = config.database;

    tk:SetBasicTooltip(container.reset, L["Reset to default"], "ANCHOR_TOP");

    container.reset:SetScript("OnClick", function()
      if (dbFramework == "orbitus") then
        local db = MayronUI:GetComponent(database)--[[@as OrbitusDB.DatabaseMixin]];
        local repo = db.utilities:GetRepositoryFromQuery(dbPath);
        repo:Store(dbPath, nil);
      else
        local db = MayronUI:GetComponent("Database");
        db:SetPathValue(dbPath, default);
      end

      component:Reset(default);
    end);
  end

  if (desiredWidth > currentWidth) then
    container:SetWidth(desiredWidth);
    component:SetWidth(desiredWidth);
  end

  self:SetBasicTooltip(container, config);
  self:SetBasicTooltip(component, config);

  local desiredHeight = component:GetHeight() + container.name:GetStringHeight() + componentNameSpacing;
  container:SetHeight(desiredHeight);
  component:SetPoint("TOPLEFT", container.name, "BOTTOMLEFT", 0, -componentNameSpacing);

  return container;
end

function Utils:GetAttribute(config, attributeName, ...)
  if (attributeName == "options" and config.media and obj:IsString(config.media)) then
    config.options = tk.Constants.LSM:List(config.media);
  end

  if (config[attributeName] ~= nil) then
    return config[attributeName];
  end

  local funcName = tk.Strings:Concat("Get", (attributeName:gsub("^%l", strupper)));

  if (obj:IsFunction(config[funcName])) then
    return config[funcName](config, ...);
  end

  if (attributeName == "options" and config.media) then
    config.options = tk.Constants.LSM:List(config.media);
  end

  obj:Error("Required attribute '%s' missing for %s widget in config table '%s' using database path '%s'",
    attributeName, config.type, config.name, config.dbPath);
end

function Utils:HasAttribute(configTable, attributeName)
  if (configTable[attributeName] ~= nil) then
    return true;
  end

  local funcName = tk.Strings:Concat("Get", (attributeName:gsub("^%l", strupper)));

  if (obj:IsFunction(configTable[funcName])) then
    return true;
  end

  return false;
end

function Utils.OnMenuButtonClick(menuButton)
  if (menuButton:IsObjectType("CheckButton") and not menuButton:GetChecked()) then
    -- should not be allowed to uncheck a menu button by clicking it a second time!
    menuButton:SetChecked(true);
    return
  end

  local configMenu = MayronUI:ImportModule("ConfigMenu")--[[@as MayronUI.ConfigMenu]];
  configMenu:OpenMenu(menuButton);
end

function Utils:AppendDefaultValueToTooltip(config, dropdownOptions)
  local default = GetDefaultValue(config);
  local canReset = default ~= nil and (obj:IsNumber(default) or obj:IsString(default) or obj:IsBoolean(default));
  local doesNotContainDefaultTooltip = not tk.Strings:Contains(config.tooltip, L["Default value is"]);

  if (canReset and doesNotContainDefaultTooltip) then
    if (dropdownOptions and obj:IsTable(dropdownOptions)) then
      for key, value in pairs(dropdownOptions) do
        if (obj:IsTable(value)) then
          local pair = value;
          key = pair[1];
          value = pair[2];
        end

        if (obj:IsString(key)) then
          if (value == default) then
            default = key; -- use the key of the DropDown component to represent the name of the default value to the user
            break
          end
        end
      end
    end

    local defaultText;
    if (obj:IsBoolean(default)) then
      defaultText = default and L["Enabled"] or L["Disabled"];
    elseif (config.defaultText) then
      defaultText = config.defaultText;
    else
      defaultText = tostring(default);
    end

    local defaultTooltip = tk.Strings:JoinWithSpace(L["Default value is"], defaultText);

    if (obj:IsString(config.tooltip)) then
      config.tooltip = tk.Strings:Join("\n\n", config.tooltip, defaultTooltip);
    else
      config.tooltip = defaultTooltip;
    end
  end

  return default;
end

function Utils:SetBasicTooltip(widget, config)
  if (obj:IsString(config.tooltip)) then
    tk:SetBasicTooltip(widget, config.tooltip, "ANCHOR_TOPLEFT");
  end
end