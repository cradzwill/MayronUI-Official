-- luacheck: ignore MayronUI self 143 631
local Lib = _G.LibStub:GetLibrary("LibMayronGUI");
if (not Lib) then return; end

local WidgetsPackage = Lib.WidgetsPackage;
local Private = Lib.Private;
local obj = Lib.Objects;

local SlideController = WidgetsPackage:Get("SlideController");
local DropDownMenu = WidgetsPackage:CreateClass("DropDownMenu", Private.FrameWrapper);

DropDownMenu.Static.MAX_HEIGHT = 354;

-- Local Functions -------------------------------
local dropdowns = {};

-- @param exclude - for all except the excluded dropdown menu
local function FoldAll(exclude)
    for _, dropdown in ipairs(dropdowns) do
        if ((not exclude) or (exclude and exclude ~= dropdown)) then
            dropdown:Hide();
        end
    end

    if (not exclude and DropDownMenu.Static.Menu) then
        DropDownMenu.Static.Menu:Hide();
    end
end

local function DropDownToggleButton_OnClick(self)
    DropDownMenu.Static.Menu:SetFrameStrata("TOOLTIP");
    self.dropdown:Toggle(not self.dropdown:IsExpanded());
    FoldAll(self.dropdown);
end

local function OnSizeChanged(self, _, height)
    self:SetWidth(height);
end

-- Lib Functions ------------------------

function Lib:FoldAllDropDownMenus(exclude)
    FoldAll(exclude);
end

-- @constructor
function Lib:CreateDropDown(style, parent, direction)

    if (not DropDownMenu.Static.Menu) then
        DropDownMenu.Static.Menu = Lib:CreateScrollFrame(style, _G.UIParent, "MUI_DropDownMenu");
        DropDownMenu.Static.Menu:Hide();
        DropDownMenu.Static.Menu:SetBackdrop(style:GetBackdrop("DropDownMenu"));
        DropDownMenu.Static.Menu:SetScript("OnHide", FoldAll);

        Private:SetBackground(DropDownMenu.Static.Menu, 0, 0, 0, 0.9);
        table.insert(_G.UISpecialFrames, "MUI_DropDownMenu");
    end

    direction = direction or "DOWN";
    direction = direction:upper();

    local dropDownContainer = Private:PopFrame("Frame", parent);
    dropDownContainer:SetSize(200, 30);

    local header = Private:PopFrame("Frame", dropDownContainer);
    header:SetAllPoints(true);
    header:SetBackdrop(style:GetBackdrop("DropDownMenu"));
    header.bg = Private:SetBackground(header, style:GetTexture("ButtonTexture"));

    dropDownContainer.toggleButton = self:CreateButton(style, dropDownContainer);
    dropDownContainer.toggleButton:SetSize(30, 30);
    dropDownContainer.toggleButton:SetPoint("TOPRIGHT", dropDownContainer, "TOPRIGHT");
    dropDownContainer.toggleButton:SetPoint("BOTTOMRIGHT", dropDownContainer, "BOTTOMRIGHT");
    dropDownContainer.toggleButton:SetScript("OnSizeChanged", OnSizeChanged);

    dropDownContainer.toggleButton.arrow = dropDownContainer.toggleButton:CreateTexture(nil, "OVERLAY");
    dropDownContainer.toggleButton.arrow:SetTexture(style:GetTexture("ArrowButtonTexture"));
    dropDownContainer.toggleButton.arrow:SetAllPoints(true);

    dropDownContainer.child = Private:PopFrame("Frame", DropDownMenu.Static.Menu);
    Private:SetFullWidth(dropDownContainer.child);

    dropDownContainer.toggleButton.child = dropDownContainer.child; -- needed for OnClick
    dropDownContainer.toggleButton:SetScript("OnClick", DropDownToggleButton_OnClick);

    header:SetPoint("BOTTOMRIGHT", dropDownContainer.toggleButton, "BOTTOMLEFT", -2, 0);

    if (direction == "DOWN") then
        dropDownContainer.toggleButton.arrow:SetTexCoord(0, 1, 0.2, 1);
    elseif (direction == "UP") then
        dropDownContainer.toggleButton.arrow:SetTexCoord(1, 0, 1, 0.2);
    end

    local slideController = SlideController(DropDownMenu.Static.Menu);
    slideController:SetMinHeight(1);

    slideController:OnEndRetract(function(self, frame)
        frame:Hide();
    end);

    dropDownContainer.toggleButton.dropdown = DropDownMenu(header, direction, slideController, dropDownContainer, style);
    table.insert(dropdowns, dropDownContainer.toggleButton.dropdown);

    -- enabled by default
    dropDownContainer.toggleButton.dropdown:SetEnabled(true);

    return dropDownContainer.toggleButton.dropdown;
end

-----------------------------------
-- DropDownMenu Object
-----------------------------------
local function ToolTip_OnEnter(frame)
    _G.GameTooltip:SetOwner(frame, "ANCHOR_RIGHT", 0, 2);
    _G.GameTooltip:AddLine(frame.tooltip);
    _G.GameTooltip:Show();
end

 local function ToolTip_OnLeave()
    _G.GameTooltip:Hide();
end


function DropDownMenu:__Construct(data, header, direction, slideController, frame, style)
    data.header = header;
    data.direction = direction;
    data.slideController = slideController;
    data.frame = frame; -- must be called frame for GetFrame() to work!
    data.menu = DropDownMenu.Static.Menu;
    data.style = style;
    data.options = {};
end

function DropDownMenu:GetMenu(data)
    return data.menu;
end

function DropDownMenu:SetToolTip(data, tooltip)
    if (not data.header.tooltip) then
        data.header:SetScript("OnEnter", ToolTip_OnEnter);
        data.header:SetScript("OnLeave", ToolTip_OnLeave);
    end
    data.header.tooltip = tooltip;
end

-- tooltip means that the tooltip should be the same as the label
function DropDownMenu:SetLabel(data, text, tooltip)
    if (not data.label) then
        data.label = data.header:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
        data.label:SetPoint("LEFT", 10, 0);
        data.label:SetPoint("RIGHT", -10, 0);
        data.label:SetWordWrap(false);
        data.label:SetJustifyH("LEFT");
    end

    data.label:SetText(text);
    if (not data.header.custom) then
        if (tooltip) then
            self:SetToolTip(tooltip);
            data.header.custom = true;
        else
            self:SetToolTip(text);
        end
    end
end

function DropDownMenu:GetLabel(data)
    return data.label and data.label:GetText();
end

WidgetsPackage:DefineReturns("number");
function DropDownMenu:GetNumOptions(data)
    return #data.options;
end

WidgetsPackage:DefineParams("number");
WidgetsPackage:DefineReturns("Button");
function DropDownMenu:GetOptionByID(data, optionID)
    local foundOption = data.options[optionID];
    obj:Assert(foundOption, "DropDownMenu.GetOption failed to find option with id '%s'.", optionID);
    return foundOption;
end

WidgetsPackage:DefineParams("string");
WidgetsPackage:DefineReturns("Button");
function DropDownMenu:GetOptionByLabel(data, label)
    for _, optionButton in ipairs(data.options) do
        if (optionButton:GetText() == label) then
            return optionButton;
        end
    end
end

WidgetsPackage:DefineParams("string");
function DropDownMenu:RemoveOptionByLabel(data, label)
    for optionID, optionButton in ipairs(data.options) do
        if (optionButton:GetText() == label) then
            self:RemoveOptionByID(optionID);
        end
    end
end

WidgetsPackage:DefineParams("number");
function DropDownMenu:RemoveOptionByID(data, optionID)
    local optionToRemove = self:GetOption(optionID);

    table.remove(data.options, optionID);
    Private:PushFrame(optionToRemove);

    local height = 30;
    local child = data.frame.child;

    -- reposition all options
    for id, option in ipairs(data.options) do
        option:ClearAllPoints();

        if (id == 1) then
            if (data.direction == "DOWN") then
                option:SetPoint("TOPLEFT", 2, -2);
                option:SetPoint("TOPRIGHT", -2, -2);
            elseif (data.direction == "UP") then
                option:SetPoint("BOTTOMLEFT", 2, 2);
                option:SetPoint("BOTTOMRIGHT", -2, 2);
            end

        else
            if (data.direction == "DOWN") then
                option:SetPoint("TOPLEFT", data.options[id - 1], "BOTTOMLEFT", 0, -1);
                option:SetPoint("TOPRIGHT", data.options[id - 1], "BOTTOMRIGHT", 0, -1);
            elseif (data.direction == "UP") then
                option:SetPoint("BOTTOMLEFT", data.options[id - 1], "TOPLEFT", 0, 1);
                option:SetPoint("BOTTOMRIGHT", data.options[id - 1], "TOPRIGHT", 0, 1);
            end

            height = height + 27;
        end
    end

    data.scrollHeight = height;
    child:SetHeight(height);

    if (DropDownMenu.Static.Menu:IsShown()) then
        DropDownMenu.Static.Menu:SetHeight(height);
    end
end

function DropDownMenu:AddOptions(_, func, optionsTable)
    for _, optionValues in ipairs(optionsTable) do
        local label = optionValues[1];
        self:AddOption(label, func, select(2, _G.unpack(optionValues)));
    end
end

function DropDownMenu:AddOption(data, label, func, ...)
    local r, g, b = data.style:GetColor();
    local child = data.frame.child;
    local height = 30;

    local option = Private:PopFrame("Button", child);

    if (#data.options == 0) then
        if (data.direction == "DOWN") then
            option:SetPoint("TOPLEFT", 2, -2);
            option:SetPoint("TOPRIGHT", -2, -2);
        elseif (data.direction == "UP") then
            option:SetPoint("BOTTOMLEFT", 2, 2);
            option:SetPoint("BOTTOMRIGHT", -2, 2);
        end

    else
        local previousOption = data.options[#data.options];

        if (data.direction == "DOWN") then
            option:SetPoint("TOPLEFT", previousOption, "BOTTOMLEFT", 0, -1);
            option:SetPoint("TOPRIGHT", previousOption, "BOTTOMRIGHT", 0, -1);
        elseif (data.direction == "UP") then
            option:SetPoint("BOTTOMLEFT", previousOption, "TOPLEFT", 0, 1);
            option:SetPoint("BOTTOMRIGHT", previousOption, "TOPRIGHT", 0, 1);
        end

        height = child:GetHeight() + 27;
    end

    -- insert option only after it has been positioned
    table.insert(data.options, option);

    data.scrollHeight = height;
    child:SetHeight(height);

    option:SetHeight(26);
    option:SetNormalFontObject("GameFontHighlight");
    option:SetText(label or " ");

    local optionFontString = option:GetFontString();
    optionFontString:ClearAllPoints();
    optionFontString:SetPoint("LEFT", 10, 0);
    optionFontString:SetPoint("RIGHT", -10, 0);
    optionFontString:SetWordWrap(false);
    optionFontString:SetJustifyH("LEFT");

    option:SetNormalTexture(1);
    option:GetNormalTexture():SetColorTexture(r * 0.7, g * 0.7, b * 0.7, 0.4);
    option:SetHighlightTexture(1);
    option:GetHighlightTexture():SetColorTexture(r * 0.7, g * 0.7, b * 0.7, 0.4);

    local args = {...};
    option:SetScript("OnClick", function()
        self:SetLabel(label, true);
        self:Toggle(false);

        if (not func) then return end

        if (type(func) == "table") then
            local tbl = func[1];
            local methodName = func[2];

            tbl[methodName](tbl, self, _G.unpack(args));
        else
            func(self, _G.unpack(args));
        end
    end);

    return option;
end

function DropDownMenu:SetEnabled(data, enabled)
    data.frame.toggleButton:SetEnabled(enabled);

    if (enabled) then
        local r, g, b = data.style:GetColor();
        r = r * 0.7; g = g * 0.7; b = b * 0.7;

        DropDownMenu.Static.Menu:SetBackdropBorderColor(r, g, b);

        data.header:SetBackdropBorderColor(r, g, b);
        data.header.bg:SetVertexColor(r, g, b, 0.6);

        data.frame.toggleButton:GetNormalTexture():SetVertexColor(r, g, b, 0.6);
        data.frame.toggleButton:GetHighlightTexture():SetVertexColor(r, g, b, 0.3);
        data.frame.toggleButton:SetBackdropBorderColor(r, g, b);

        if (data.options) then
            for _, option in ipairs(data.options) do
                option:GetNormalTexture():SetColorTexture(r, g, b, 0.4);
                option:GetHighlightTexture():SetColorTexture(r, g, b, 0.4);
            end
        end

        if (data.label) then
            data.label:SetTextColor(1, 1, 1);
        end
    else
        DropDownMenu.Static.Menu:Hide();
        DropDownMenu.Static.Menu:SetBackdropBorderColor(0.2, 0.2, 0.2);
        data.header.bg:SetVertexColor(0.2, 0.2, 0.2, 0.6);
        data.header:SetBackdropBorderColor(0.2, 0.2, 0.2);
        data.frame.toggleButton:GetNormalTexture():SetVertexColor(0.2, 0.2, 0.2, 0.6);
        data.frame.toggleButton:GetHighlightTexture():SetVertexColor(0.2, 0.2, 0.2, 0.7);
        data.frame.toggleButton:SetBackdropBorderColor(0.2, 0.2, 0.2);
        data.frame.toggleButton.arrow:SetAlpha(0.5);

        --TODO: This line needs to be tested...
        data.style:ApplyColor(nil, 0.8, data.frame.ScrollBar.thumb);

        self:Toggle(false);

        if (data.label) then
            data.label:SetTextColor(0.5, 0.5, 0.5);
        end
    end
end

-- Unlike Toggle(), this function hides the menu instantly (does not fold)
function DropDownMenu:Hide(data)
    data.expanded = false;
    data.frame.child:Hide();

    if (data.direction == "DOWN") then
        data.frame.toggleButton.arrow:SetTexCoord(0, 1, 0.2, 1);

    elseif (data.direction == "UP") then
        data.frame.toggleButton.arrow:SetTexCoord(1, 0, 1, 0.2);
    end
end

function DropDownMenu:IsExpanded(data)
    return data.expanded;
end

function DropDownMenu:Toggle(data, show, clickSoundFilePath)
    if (not data.options) then
        -- no list of options so nothing to toggle...
        return
    end

    local step = #data.options * 4;
    step = (step > 20) and step or 20;
    step = (step < 30) and step or 30;

    DropDownMenu.Static.Menu:ClearAllPoints();

    if (data.direction == "DOWN") then
        DropDownMenu.Static.Menu:SetPoint("TOPLEFT", data.frame, "BOTTOMLEFT", 0, -2);
        DropDownMenu.Static.Menu:SetPoint("TOPRIGHT", data.frame, "BOTTOMRIGHT", 0, -2);
    elseif (data.direction == "UP") then
        DropDownMenu.Static.Menu:SetPoint("BOTTOMLEFT", data.frame, "TOPLEFT", 0, 2);
        DropDownMenu.Static.Menu:SetPoint("BOTTOMRIGHT", data.frame, "TOPRIGHT", 0, 2);
    end

    if (show) then
        local max_height = (data.scrollHeight < DropDownMenu.Static.MAX_HEIGHT)
            and data.scrollHeight or DropDownMenu.Static.MAX_HEIGHT;

        DropDownMenu.Static.Menu:SetScrollChild(data.frame.child);
        DropDownMenu.Static.Menu:SetHeight(1);

        data.frame.child:Show();
        data.slideController:SetMaxHeight(max_height);

        if (data.direction == "DOWN") then
            data.frame.toggleButton.arrow:SetTexCoord(1, 0, 1, 0.2);
        elseif (data.direction == "UP") then
            data.frame.toggleButton.arrow:SetTexCoord(0, 1, 0.2, 1);
        end
    else
        if (data.direction == "DOWN") then
            data.frame.toggleButton.arrow:SetTexCoord(0, 1, 0.2, 1);
        elseif (data.direction == "UP") then
            data.frame.toggleButton.arrow:SetTexCoord(1, 0, 1, 0.2);
        end
    end

    data.slideController:SetStepValue(step);
    data.slideController:Start();

    if (clickSoundFilePath) then
        _G.PlaySound(clickSoundFilePath);
    end

    data.expanded = show;
end