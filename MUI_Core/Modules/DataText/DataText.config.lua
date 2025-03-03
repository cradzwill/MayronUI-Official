-- luacheck: ignore MayronUI self 143 631
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db, _, _, obj, L = MayronUI:GetCoreComponents();
local C_DataTextModule = MayronUI:GetModuleClass("DataTextModule");
local dataTextLabels = MayronUI:GetComponent("DataTextLabels");
local pairs, string = _G.pairs, _G.string;

function C_DataTextModule:GetConfigTable()
    local label_TextFields = obj:PopTable();

    local function SetLabel_OnLoad(config, container)
      label_TextFields[config.module] = container.component;
      local path = ("profile.datatext.labels.hidden.%s"):format(config.module);
      local isHidden = db:ParsePathValue(path);

      if (isHidden) then
          container.component:SetEnabled(false);
      end
    end

    local function CreateLabelOptions(module)
      return {
        {   name = "Hide Label";
            type = "check";
            absoluteDbPath = true;
            dbPath = "profile.datatext.labels.hidden." .. module;
            SetValue = function(self, newValue)
              local stored = newValue and true or nil;
              db:SetPathValue(self.dbPath, stored);
              local label = label_TextFields[module];
              label:SetEnabled(not newValue); -- if hidden == true then hide label option
            end
        },
        {   name = "Set Label",
            type = "textfield",
            module = module;
            absoluteDbPath = true;
            dbPath = "profile.datatext.labels." .. module;
            OnLoad = SetLabel_OnLoad,
        },
        { type = "divider" };
      }
    end

    return {
        type = "menu",
        module = "DataTextModule",
        dbPath = "profile.datatext",
        children =  {
            {   name = L["General Data Text Options"],
                type = "title",
                marginTop = 0;
            },
            {   name = L["Enabled"],
                tooltip = tk.Strings:Concat(
                    L["If unchecked, the entire DataText module will be disabled and all"], "\n",
                    L["DataText buttons, as well as the background bar, will not be displayed."]),
                type = "check",
                requiresReload = true, -- TODO: Maybe modules can be global? - move module enable/disable to general menu?
                dbPath = "enabled",
            },
            {   name = L["Block in Combat"],
                tooltip = L["Prevents you from using data text modules while in combat."],
                type = "check",
                dbPath = "blockInCombat",
            },
            {   name = L["Auto Hide Menu in Combat"],
                type = "check",
                dbPath = "popup.hideInCombat",
            },
            {   type = "divider"
            },
            {   name = L["Spacing"],
                type = "slider",
                tooltip = L["Adjust the spacing between data text buttons."],
                min = 0,
                max = 5,
                default = 1,
                dbPath = "spacing",
            },
            {   name = L["Font Size"],
                type = "slider",
                tooltip = L["The font size of text that appears on data text buttons."],
                min = 8,
                max = 18,
                default = 11,
                dbPath = "fontSize",
            },
            {   name = L["Height"],
                type = "slider",
                valueType = "number",
                min = 10;
                max = 50;
                tooltip = L["Adjust the height of the datatext bar."],
                dbPath = "height",
            },
            {   name = L["Menu Width"],
                type = "slider",
                min = 150;
                max = 400;
                step = 10;
                dbPath = "popup.width",
            },
            {   name = L["Max Menu Height"],
                type = "slider",
                min = 150;
                max = 400;
                step = 10;
                dbPath = "popup.maxHeight",
            },
            {   type = "divider"
            },
            {   type = "dropdown",
                name = L["Bar Strata"],
                tooltip = L["The frame strata of the entire DataText bar."],
                options = tk.Constants.ORDERED_FRAME_STRATAS,
                disableSorting = true;
                dbPath = "frameStrata";
            },
            {   type = "slider",
                name = L["Bar Level"],
                tooltip = L["The frame level of the entire DataText bar based on its frame strata value."],
                min = 1,
                max = 50,
                default = 30,
                dbPath = "frameLevel"
            },
            {   name = L["Data Text Modules"],
                type = "title",
            },
          {   type = "loop",
              loops = 10,
              func = function(id)
                local child = {
                  name = tk.Strings:JoinWithSpace(L["Button"], id);
                  type = "dropdown";
                  dbPath = string.format("profile.datatext.displayOrders[%s]", id);
                  options = dataTextLabels;
                  labels = "values";

                  GetValue = function(_, value)
                    if (value == nil) then
                      value = "disabled";
                    end

                    return dataTextLabels[value];
                  end;

                  SetValue = function(self, newLabel)
                    local newValue;

                    for value, label in pairs(dataTextLabels) do
                      if (newLabel == label) then
                        newValue = value;
                        break;
                      end
                    end

                    db:SetPathValue(self.dbPath, newValue);
                  end;
                };

                if (id == 1) then
                  child.paddingTop = 0;
                end

                return child;
              end
            },
            {   type = "title",
                name = L["Module Options"]
            },
            {   type = "submenu",
                module = "DataText",
                name = L["Durability"],
                dbPath = "durability",
                children = CreateLabelOptions("durability");
            },
            {   type = "submenu",
                module = "DataText",
                name = L["Friends"],
                dbPath = "friends",
                children = CreateLabelOptions("friends");
            },
            {   type = "submenu",
                module = "DataText",
                name = L["Guild"],
                dbPath = "guild",
                children = function()
                  local children = CreateLabelOptions("guild");
                  children[#children + 1] =
                  { type = "check",
                    name = L["Show Self"],
                    tooltip = L["Show your character in the guild list."],
                    dbPath = "showSelf"
                  };
                  children[#children + 1] =
                  { type = "check",
                    name = L["Show Tooltips"],
                    tooltip = L["Show guild info tooltips when the cursor is over guild members in the guild list."],
                    dbPath = "showTooltips"
                  };

                  return children;
                end;
            };
            {
              type = "submenu",
              name = L["Inventory"],
              module = "DataText",
              dbPath = "inventory",
              children = function()
                local children = CreateLabelOptions("inventory");
                children[#children + 1] =
                {
                  name = L["Show Total Slots"];
                  type = "check";
                  dbPath = "showTotalSlots";
                };
                children[#children + 1] =
                {
                  name = L["Show Used Slots"];
                  type = "radio";
                  groupName = "inventory";
                  dbPath = "slotsToShow";

                  GetValue = function(_, value)
                    return value == "used";
                  end;

                  SetValue = function(self)
                    db:SetPathValue(self.dbPath, "used");
                  end;
                };
                children[#children + 1] =
                {
                  name = L["Show Free Slots"];
                  type = "radio";
                  groupName = "inventory";
                  dbPath = "slotsToShow";

                  GetValue = function(_, value)
                    return value == "free";
                  end;

                  SetValue = function(self)
                    db:SetPathValue(self.dbPath, "free");
                  end;
                };
                return children;
              end;
            },
            {
              type = "submenu",
              module = "DataText",
              name = L["Performance"],
              dbPath = "performance",
              children = {
                {
                  type = "fontstring",
                  content = L["Changes to these settings will take effect after 0-3 seconds."];
                },
                {
                  name = L["Show FPS"],
                  type = "check",
                  dbPath = "showFps",
                },
                {
                  type = "divider"
                },
                {
                  name = L["Show Server Latency (ms)"],
                  type = "check",
                  width = 230,
                  dbPath = "showServerLatency",
                },
                {
                  type = "divider"
                },
                {
                  name = L["Show Home Latency (ms)"],
                  type = "check",
                  width = 230,
                  dbPath = "showHomeLatency",
                },
              }
            },
            {   type = "submenu",
                name = L["Money"];
                module = "DataText",
                dbPath = "money",
                children = {
                  {   name = L["Show Realm Name"],
                      type = "check",
                      dbPath = "showRealm",
                  },
                }
            },
            {   type = "submenu",
                module = "DataText",
                name = L["Quests"],
                dbPath = "quest",
                children = CreateLabelOptions("quest");
            },
            {   type = "submenu",
                module = "DataText",
                name = L["Volume Options"],
                dbPath = "volumeOptions",
                children = CreateLabelOptions("volumeOptions");
            },
        }
    };
end