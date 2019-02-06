-- luacheck: ignore MayronUI self 143 631
local _, namespace = ...;

local obj = namespace.components.Objects;
local tk = namespace.components.Toolkit; ---@type Toolkit

local TOOLTIP_ANCHOR_POINT = "ANCHOR_TOP";
local GameTooltip, ipairs = _G.GameTooltip, _G.ipairs;

function tk:SetFontSize(fontString, size)
    local fontPath, _, flags = fontString:GetFont();
    fontString:SetFont(fontPath, size, flags);
end

do
    function tk.GeneralTooltip_OnLeave()
        GameTooltip:Hide();
    end

    function tk.BasicTooltip_OnEnter(self)
        GameTooltip:SetOwner(self, TOOLTIP_ANCHOR_POINT, 0, 2);
        GameTooltip:AddLine(self.text);
        GameTooltip:Show();
    end

    function tk.AuraTooltip_OnEnter(self)
        if (self.auraId) then
            GameTooltip:SetOwner(self, TOOLTIP_ANCHOR_POINT, 0, 2);
            GameTooltip:SetSpellByID(self.auraId);
            GameTooltip:Show();
        end
    end

    local function MultipleLinesTooltip_OnEnter(self)
        GameTooltip:SetOwner(self, TOOLTIP_ANCHOR_POINT, 0, 2);

        for _, line in ipairs(self.lines) do

            if (line.text) then
                GameTooltip:AddLine(line.text);

            elseif (line.leftText and line.rightText) then
                GameTooltip:AddDoubleLine(line.leftText, line.rightText, nil, nil, nil, 1, 1, 1);
            end

            obj:PushTable(line);
        end

        obj:PushTable(self.lines);
        GameTooltip:Show();
    end

    function tk:SetBasicTooltip(widget, text)
        widget.text = text;

        widget:SetScript("OnEnter", tk.BasicTooltip_OnEnter);
        widget:SetScript("OnLeave", tk.GeneralTooltip_OnLeave);
    end

    function tk:SetAuraTooltip(widget, auraId)
        widget.auraId = auraId;

        widget:SetScript("OnEnter", tk.AuraTooltip_OnEnter);
        widget:SetScript("OnLeave", tk.GeneralTooltip_OnLeave);
    end

    function tk:SetMultipleLinesTooltip(widget, tooltipData)
        widget.tooltip = tooltipData;

        widget:SetScript("OnEnter", MultipleLinesTooltip_OnEnter);
        widget:SetScript("OnLeave", tk.GeneralTooltip_OnLeave);
    end
end

function tk:SetFullWidth(frame, rightPadding)
    rightPadding = rightPadding or 0;

    if (not frame:GetParent()) then
        tk.hooksecurefunc(frame, "SetParent", function()
            frame:GetParent():HookScript("OnSizeChanged", function(_, width)
                frame:SetWidth(width - rightPadding);
            end);

            frame:SetWidth(frame:GetParent():GetWidth() - rightPadding);
        end);

    else
        frame:GetParent():HookScript("OnSizeChanged", function(_, width)
            frame:SetWidth(width - rightPadding);
        end);

        frame:SetWidth(frame:GetParent():GetWidth() - rightPadding);
    end
end

function tk:MakeMovable(frame, dragger, movable)
    if (movable == nil) then
        movable = true;
    end

    dragger = dragger or frame;
    dragger:EnableMouse(movable);
    dragger:RegisterForDrag("LeftButton");

    frame:SetMovable(movable);
    frame:SetClampedToScreen(true);

    dragger:HookScript("OnDragStart", function()
        if (frame:IsMovable()) then
            local x, y = frame:GetCenter();

            frame:SetPoint("CENTER", tk.UIParent, "BOTTOMLEFT", x, y);
            frame:StartMoving();
        end
    end);

    dragger:HookScript("OnDragStop", function()
        if (frame:IsMovable()) then
            frame:StopMovingOrSizing();
        end
    end);
end

function tk:SavePosition(frame, db_path, override)
    local point, relativeFrame, relativePoint, x, y = frame:GetPoint();

    if (not relativeFrame) then
        relativeFrame = frame:GetParent():GetName();
    else
        relativeFrame = relativeFrame:GetName();

        if (not relativeFrame or relativeFrame and relativeFrame ~= "UIParent") then
            if (not override) then
                return
            end

            x, y = frame:GetCenter();
            point = "CENTER";
            relativeFrame = "UIParent"; -- Do not want this to be UIParent in some cases
            relativePoint = "BOTTOMLEFT";
        end
    end

    local positions = {
        point = point,
        relativeFrame = relativeFrame,
        relativePoint = relativePoint,
        x = x, y = y
    };

    namespace.Database:SetPathValue(db_path, positions);
    return positions;
end

function tk:MakeResizable(frame, dragger)
    dragger = dragger or frame;
    frame:SetResizable(true);
    dragger:RegisterForDrag("LeftButton");

    dragger:HookScript("OnDragStart", function()
        frame:StartSizing();
    end);

    dragger:HookScript("OnDragStop", function()
        frame:StopMovingOrSizing();
    end);
end

function tk:FlipTexture(texture, direction)
    direction = direction:trim():upper();

    if (direction == "VERTICAL") then
        texture:SetTexCoord(0, 1, 1, 0);
    elseif (direction == "HORIZONTAL") then
        texture:SetTexCoord(1, 0, 0, 1);
    end
end

function tk:ClipTexture(texture, sideName, amount)
    sideName = sideName:trim():upper();

    local left, right, top, bottom = texture:GetTexCoord();

    if (sideName == "LEFT") then
        texture:SetTexCoord(amount, right, top, bottom);

    elseif (sideName == "RIGHT") then
        texture:SetTexCoord(left, 1 - amount, top, bottom);

    elseif (sideName == "TOP") then
        texture:SetTexCoord(left, right, amount, bottom);

    elseif (sideName == "BOTTOM") then
        texture:SetTexCoord(left, right, top, 1 - amount);
    end
end

function tk:KillElement(element)
    element:Hide();
    element:SetParent(tk.Constants.DUMMY_FRAME);
    element:SetAllPoints(true);
    element.Show = tk.Constants.DUMMY_FUNC;
end

function tk:KillAllElements(...)
    for _, element in ipairs({...}) do
        self:KillElement(element);
    end
end

function tk:HideFrameElements(frame, kill)
    for _, child in pairs({frame:GetChildren()}) do
        if (kill) then
            self:KillElement(child);
        else
            child:Hide();
        end
    end

    for _, region in pairs({frame:GetRegions()}) do
        if (kill) then
            self:KillElement(region);
        else
            region:Hide();
        end
    end
end

function tk:HookOnce(func)
    local execute = true;

    local function wrapper(...)
        if (execute) then
            func(...);
            execute = nil;
        end
    end

    return wrapper;
end

function tk:SetClassColoredTexture(className, texture)
    className = className or (tk.select(2, _G.UnitClass("player")));
    className = tk.string.upper(className);
    className = className:gsub("%s+", "");
    local color = self.Constants.CLASS_COLORS[className];
    texture:SetVertexColor(color.r, color.g, color.b, texture:GetAlpha());
end

-- apply theme color to a vararg list of elements
-- first arg can be a number specifying the alpha value
function tk:ApplyThemeColor(...)
    local alpha = (tk.select(1, ...));

    -- first argument is "colorName"
    if (not (tk.type(alpha) == "number" and alpha)) then
        tk.Constants.AddOnStyle:ApplyColor(nil, 1, ...);
    else
        tk.Constants.AddOnStyle:ApplyColor(nil, ...);
    end
end

function tk:GetThemeColor(returnTable)
    if (tk.Constants.AddOnStyle) then
        return tk.Constants.AddOnStyle:GetColor(nil, returnTable);
    end

    local color = namespace.components.Database.profile.theme.color;
    return color.r, color.g, color.b, color.hex;
end

function tk:UpdateThemeColor(value)
    local color = tk.Constants.CLASS_COLORS[value] or value;

    local colorValues = obj:PopTable();
    colorValues.r = color.r;
    colorValues.g = color.g;
    colorValues.b = color.b;
    colorValues.hex = color:GenerateHexColor();

    -- update database
    namespace.Database.profile.theme.color = colorValues;

    -- update Constant Style Object
    tk.Constants.AddOnStyle:SetColor(color.r, color.g, color.b);
end

function tk:SetBackground(frame, ...)
    local args = obj:PopTable(...);
    local texture = frame:CreateTexture(nil, "BACKGROUND");

    texture:SetAllPoints(frame);

    if (#args > 1) then
        texture:SetColorTexture(...);
    else
        texture:SetTexture(args[1]);
    end

    obj:PushTable(args);

    return texture;
end

function tk:GroupCheckButtons(...)
    local btns = obj:PopTable();

    for id, btn in obj:IterateArgs(...) do
        btn:SetID(id);
        table.insert(btns, btn);

        btn:HookScript("OnClick", function(self)
            if (self:GetChecked()) then

                for otherId, otherBtn in ipairs(btns) do
                    if (id ~= otherId) then
                        otherBtn:SetChecked(false);
                    end
                end
            end
        end);
    end
end

function tk:SetFontSize(fontstring, size)
    local filename, _, flags = fontstring:GetFont();
    fontstring:SetFont(filename, size, flags);
end

function tk:SetGameFont(font)
    tk._G["UNIT_NAME_FONT"] = font;
    tk._G["NAMEPLATE_FONT"] = font;
    tk._G["DAMAGE_TEXT_FONT"] = font;
    tk._G["STANDARD_TEXT_FONT"] = font;

    local fonts = {
        "SystemFont_Tiny", "SystemFont_Shadow_Small", "SystemFont_Small",
        "SystemFont_Small2", "SystemFont_Shadow_Small2", "SystemFont_Shadow_Med1_Outline",
        "SystemFont_Shadow_Med1", "QuestFont_Large", "SystemFont_Large",
        "SystemFont_Shadow_Large_Outline", "SystemFont_Shadow_Med2", "SystemFont_Shadow_Large",
        "SystemFont_Shadow_Large2", "SystemFont_Shadow_Huge1", "SystemFont_Huge2",
        "SystemFont_Shadow_Huge2", "SystemFont_Shadow_Huge3", "SystemFont_World",
        "SystemFont_World_ThickOutline", "SystemFont_Shadow_Outline_Huge2", "SystemFont_Med1",
        "SystemFont_WTF2", "SystemFont_Outline_WTF2", "GameTooltipHeader", "System_IME",

        -- other:
        "NumberFont_OutlineThick_Mono_Small", "NumberFont_Outline_Huge",
        "NumberFont_Outline_Large", "NumberFont_Outline_Med", "NumberFont_Shadow_Med",
        "NumberFont_Shadow_Small", "QuestFont", "QuestTitleFont", "QuestTitleFontBlackShadow",
        "GameFontNormalMed3", "SystemFont_Med3", "SystemFont_OutlineThick_Huge2",
        "SystemFont_Outline_Small", "SystemFont_Shadow_Med3", "Tooltip_Med", "Tooltip_Small",
        "ZoneTextString", "SubZoneTextString", "PVPInfoTextString", "PVPArenaTextString",
        "CombatTextFont", "FriendsFont_Normal", "FriendsFont_Small", "FriendsFont_Large",
        "FriendsFont_UserText",
    };

    -- prevent weird font size bug
    _G.SystemFont_NamePlate:SetFont(font, 9);

    for _, f in tk.ipairs(fonts) do
        local _, size, outline = tk._G[f]:GetFont();
        tk._G[f]:SetFont(font, size, outline);
    end
end

do
    local frames = {};

    function tk:PopFrame(frameType, parent)
        parent = parent or _G.UIParent;
        frameType = frameType or "Frame";

        local frame;
        local framesTable = frames[frameType];

        if (type(framesTable) == "table" and #framesTable > 0) then
            frame = framesTable and framesTable[#framesTable];
        end

        if (not frame) then
            frame = _G.CreateFrame(frameType);
        else
            framesTable[#framesTable] = nil;
        end

        frame:SetParent(parent);
        frame:Show();

        return frame;
    end

    function tk:PushFrame(frame)
        if (not frame.GetObjectType) then
            return
        end

        local frameType = frame:GetObjectType();
        frames[frameType] = frames[frameType] or {};
        frame:SetParent(tk.Constants.DUMMY_FRAME);
        frame:SetAllPoints(true);
        frame:Hide();

        for _, child in ipairs({frame:GetChildren()}) do
            self:PushFrame(child);
        end

        for _, region in ipairs({frame:GetRegions()}) do
            region:SetParent(tk.Constants.DUMMY_FRAME);
            region:SetAllPoints(true);
            region:Hide();
        end

        table.insert(frames[frameType], frame);
    end
end