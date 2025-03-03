-- luacheck: ignore MayronUI self 143 631
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, _, _, _, obj = MayronUI:GetCoreComponents();

---@class MayronUI.GUIBuilder
local gui = MayronUI:GetComponent("GUIBuilder");

local hooksecurefunc, PlaySound, unpack = _G.hooksecurefunc, _G.PlaySound, _G.unpack;
local Mixin = _G.Mixin;

---comment
---@param self MayronUI.GridTextureMixin|Frame
local function OnGridFrameSizeChanged(self)
  local width, height = self:GetSize();
  local min, max = math.min(width, height), math.max(width, height);
  local percent = min/max;
  local size = width;

  if (percent < 0.3) then
    if (max > 500) then
      size = max;
    else
      size = min;
    end
  end

  ---@type MayronUI.GridTextureType
  local textureType = "ExtraLarge"

  if (size < 250) then
    textureType = "ExtraSmall";
  elseif (size < 350) then
    textureType = "Small";
  elseif (size < 600) then
    textureType = "Medium";
  elseif (size < 900) then
    textureType = "Large";
  end

  if (self.textureType ~= textureType) then
    local texture = tk:GetAssetFilePath("Textures\\DialogBox\\Dialog-"..textureType);
    self:SetGridTexture(texture);
    self.textureType = textureType;
  end
end

do
  ---@type MayronUI.GridTextureMixin[]
  local dialogFrames = {};
  local frameColor;

  function gui:UpdateMuiFrameColor(r, g, b)
    frameColor = {r, g, b};

    for _, frame in ipairs(dialogFrames) do
      frame:SetGridColor(r, g, b);
    end
  end

  function gui:GetMuiFrameColor()
    if (frameColor == nil) then
      local db = MayronUI:GetComponent("Database");

      if (db.profile) then
        local dbTheme = db.profile.theme.frameColor;
        frameColor = { dbTheme.r, dbTheme.g, dbTheme.b };
      end
    end

    if (frameColor == nil) then
      -- fallback (should never be required)
      return tk:GetThemeColor();
    end

    return unpack(frameColor);
  end

  ---@param frame Frame|BackdropTemplate A frame to apply the dialog box background texture to
  ---@param alphaType? MayronUI.GridAlphaType
  ---@param padding number?
  ---@return Frame|MayronUI.GridTextureMixin|table @The new frame (or existing frame if the frame param was supplied).
  function gui:AddDialogTexture(frame, alphaType, padding)
    local texture = tk:GetAssetFilePath("Textures\\DialogBox\\Dialog-Medium");
    local dialogFrame = gui:CreateGridTexture(frame, texture, 10, padding or 12, 674, 674);
    table.insert(dialogFrames, dialogFrame);

    dialogFrame:SetGridAlphaType(alphaType or "Regular");

    local r, g, b = self:GetMuiFrameColor();
    dialogFrame:SetGridColor(r, g, b);

    frame:SetFrameStrata("DIALOG");

    dialogFrame:HookScript("OnSizeChanged", OnGridFrameSizeChanged);
    dialogFrame:HookScript("OnShow", OnGridFrameSizeChanged);
    local width = dialogFrame:GetWidth();

    if (width and width > 0) then
      OnGridFrameSizeChanged(dialogFrame);
    end

    return dialogFrame;
  end
end

do
  local function OnButtonEnabled(self)
    local r, g, b = unpack(self.enabledBackdrop);
    self:SetBackdropBorderColor(r, g, b, 0.7);
  end

  local function OnButtonDisabled(self)
    local r, g, b = _G.DISABLED_FONT_COLOR:GetRGB();
    self:SetBackdropBorderColor(r, g, b, 0.6);
  end

  local function SetWidth(self)
    local fontString = self:GetFontString();

    local width = fontString:GetUnboundedStringWidth() + (self.padding);
    width = max(max(self.minWidth or 0, width), self:GetWidth());

    self:SetWidth(width);
    fontString:SetPoint("CENTER", self);
  end

  local function ApplyThemeColor(button)
    local r, g, b = tk:GetThemeColor();
    local normal = button:GetNormalTexture();
    local highlight = button:GetHighlightTexture();
    local disabled = button:GetDisabledTexture();

    button:SetBackdropBorderColor(r, g, b, 0.7);

    if (obj:IsTable(button.enabledBackdrop)) then
      obj:PushTable(button.enabledBackdrop);
    end

    button.enabledBackdrop = obj:PopTable(r, g, b);

    normal:SetVertexColor(r * 0.6, g * 0.6, b * 0.6, 1);
    highlight:SetVertexColor(r, g, b, 0.2);

    local dr, dg, db = _G.DISABLED_FONT_COLOR:GetRGB();
    disabled:SetVertexColor(dr, dg, db, 0.6);

    if (button:IsEnabled()) then
      button:SetBackdropBorderColor(r, g, b, 0.7);
    else
      button:SetBackdropBorderColor(dr, dg, db, 0.6);
    end
  end

  function gui:CreateButton(parent, text, button, tooltip, padding, minWidth)
    local backgroundTexture = tk:GetAssetFilePath("Textures\\Widgets\\Button");

    button = button or tk:CreateBackdropFrame("Button", parent, nil)--[[@as Button|BackdropTemplate]];
    button.padding = padding or 30;
    button.minWidth = minWidth or 150;
    button:SetHeight(30);
    button:SetBackdrop(tk.Constants.BACKDROP);

    local fs = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")--[[@as FontString]];
    button:SetFontString(fs);
    hooksecurefunc(button, "SetText", SetWidth);

    local width = 0;

    if (text) then
      button:SetText(text);
      width = fs:GetStringWidth() + (button.padding * 2);
    end

    width = math.max(width, button.minWidth);
    button:SetWidth(width);

    local inset = tk.Constants.BACKDROP.edgeSize;
    for i = 1, 3 do
      local texture = tk:SetBackground(button, backgroundTexture);
      texture:ClearAllPoints();
      texture:SetPoint("TOPLEFT", inset, -inset);
      texture:SetPoint("BOTTOMRIGHT", -inset, inset);

      if (i == 1) then
        button:SetNormalTexture(texture);
      elseif (i == 2) then
        button:SetHighlightTexture(texture);
      else
        button:SetDisabledTexture(texture);
      end
    end

    button:SetNormalFontObject("GameFontHighlight");
    button:SetDisabledFontObject("GameFontDisable");

    if (obj:IsString(tooltip)) then
      tk:SetBasicTooltip(button, tooltip, "ANCHOR_TOP");
    end

    button.ApplyThemeColor = ApplyThemeColor;
    tk:ApplyThemeColor(button);

    button:SetScript("OnEnable", OnButtonEnabled);
    button:SetScript("OnDisable", OnButtonDisabled);

    return button;
  end
end

do
  local function OnCheckButtonSetEnabled(self, value)
    if (value) then
      self.text:SetFontObject("GameFontHighlight");
    else
      self.text:SetFontObject("GameFontDisable");
    end
  end

  local function OnCheckButtonEnter(self)
    local btn = self.btn or self;

    if (btn:IsEnabled()) then
      local container = btn:GetParent();
      container.background:SetVertexColor(0.7, 0.7, 0.7);
      container.color:SetBlendMode("ADD");
    end
  end

  local function OnCheckButtonLeave(self)
    local btn = self.btn or self;

    local container = btn:GetParent();
    container.background:SetVertexColor(1, 1, 1);
    container.color:SetBlendMode("BLEND");
  end

  local function ApplyThemeColor(self, r, g, b, a)
    if (self.isSwatch) then
      self.r = r;
      self.g = g;
      self.b = b;
      self.a = a;
      self.color:SetVertexColor(r * a, g * a, b * a);
    else
      tk:ApplyThemeColor(self.color);
    end
  end

  function gui:CreateColorSwatchButton(parent, text, tooltip, globalName, verticalAlignment)
    local container = self:CreateCheckButton(parent, text, tooltip, globalName, verticalAlignment, nil, true);
    container.btn:SetChecked(true);
    return container;
  end

  local cbLabelSpacing = 6;
  local CheckButtonMixin = {};

  function CheckButtonMixin:SetCheckButtonLabel(text)
    if (not obj:IsString(text)) then return end
    self.btn.text:SetText(text);
    local textWidth = self.btn.text:GetStringWidth();

    local btnWidth = self.btn:GetWidth();
    self:SetWidth(btnWidth + cbLabelSpacing + textWidth);
  end

  function CheckButtonMixin:SetChecked(checked)
    checked = checked == true; -- convert to boolean

    if (self.btn:GetChecked() ~= checked) then
      self.btn:Click(); -- fire onClick script
    end
  end

  function gui:CreateCheckButton(parent, text, tooltip, globalName, verticalAlignment, radio, isSwatch)
    local container = tk:CreateFrame("Button", parent, globalName);
    container = Mixin(container, CheckButtonMixin);
    container.isSwatch = isSwatch;
    container:SetSize(1000, 20);

    local btnGlobalName = (globalName and globalName.."CheckButton") or nil;
    container.btn = tk:CreateFrame("CheckButton", container, btnGlobalName, "UICheckButtonTemplate");
    container.btn:SetSize(20, 20);

    tk:KillElement(container.btn:GetHighlightTexture());
    tk:KillElement(container.btn:GetDisabledCheckedTexture());

    local normalTexturePath, checkedTexturePath;

    if (radio) then
      normalTexturePath = tk:GetAssetFilePath("Textures\\Widgets\\RadioButtonUnchecked");
      checkedTexturePath = tk:GetAssetFilePath("Textures\\Widgets\\RadioButtonChecked");
    else
      normalTexturePath = tk:GetAssetFilePath("Textures\\Widgets\\Unchecked");
      checkedTexturePath = tk:GetAssetFilePath("Textures\\Widgets\\Checked");
    end

    -- Normal Texture:
    container.btn:SetNormalTexture(normalTexturePath);
    container.background = container.btn:GetNormalTexture();
    container.background:SetAllPoints(true);

    -- Checked Texture:
    container.btn:SetCheckedTexture(checkedTexturePath);
    container.color = container.btn:GetCheckedTexture();
    container.color:SetAllPoints(true);

    -- Highlight Texture:
    container.btn:SetHighlightTexture("");
    container.btn.SetHighlightTexture = tk.Constants.DUMMY_FUNC;

    -- Pushed Textured:
    container.btn:SetPushedTexture(normalTexturePath);
    container.btn.SetPushedTexture = tk.Constants.DUMMY_FUNC;

    container.ApplyThemeColor = ApplyThemeColor;

    if (not isSwatch) then
      container:ApplyThemeColor();
    end

    if (tooltip) then
      tk:SetBasicTooltip(container.btn, tooltip, "ANCHOR_TOPLEFT");
      container.wrapper = container.btn;
      tk:SetBasicTooltip(container, tooltip, "ANCHOR_TOPLEFT");
    end

    -- Handle Styling:
    container:HookScript("OnEnter", OnCheckButtonEnter);
    container:HookScript("OnLeave", OnCheckButtonLeave);
    container.btn:HookScript("OnEnter", OnCheckButtonEnter);
    container.btn:HookScript("OnLeave", OnCheckButtonLeave);

    container.btn.text = container.btn.text or container.btn.Text;
    container.btn.text:SetFontObject("GameFontHighlight");
    container.btn.text:ClearAllPoints();
    container.btn.text:SetPoint("LEFT", container.btn, "RIGHT", cbLabelSpacing, 1);
    container.btn.text:SetHeight(18);

    if (verticalAlignment == "TOP") then
      container.btn:SetPoint("TOPLEFT");
    elseif (verticalAlignment == "BOTTOM") then
      container.btn:SetPoint("BOTTOMLEFT");
    else
      container.btn:SetPoint("LEFT");
    end

    hooksecurefunc(container.btn, "SetEnabled", OnCheckButtonSetEnabled);
    container:SetCheckButtonLabel(text);

    return container;
  end
end

-------------------------------
-- Extra Widget Enhancements
-------------------------------
do
  local function TitleBar_SetWidth(self)
    local bar = self:GetParent();
    local width = self:GetStringWidth() + 34;

    width = (width > 150 and width) or 150;
    bar:SetWidth(width);
  end

  function gui:AddTitleBar(frame, text)
    local texture = tk:GetAssetFilePath("Textures\\DialogBox\\TitleBar");

    frame.titleBar = tk:CreateFrame("Button", frame);
    frame.titleBar:SetSize(260, 31);
    frame.titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", -7, 11);
    frame.titleBar.bg = frame.titleBar:CreateTexture("ARTWORK");
    frame.titleBar.bg:SetTexture(texture);

    frame.titleBar.bg:SetAllPoints(true);
    frame.titleBar.text = frame.titleBar:CreateFontString(nil, "ARTWORK", "GameFontHighlight");

    frame.titleBar.text:SetSize(260, 31);
    frame.titleBar.text:SetPoint("LEFT", frame.titleBar.bg, "LEFT", 10, 0.5);
    frame.titleBar.text:SetJustifyH("LEFT");

    tk:MakeMovable(frame, frame.titleBar);
    tk:ApplyThemeColor(frame.titleBar.bg);

    hooksecurefunc(frame.titleBar.text, "SetText", TitleBar_SetWidth);
    frame.titleBar.text:SetText(text);
  end
end

function gui:AddResizer(frame)
  local textureFilePath = tk:GetAssetFilePath("Textures\\DialogBox\\DragRegion");

  frame.dragger = tk:CreateFrame("Button", frame);
  frame.dragger:SetSize(28, 28);
  frame.dragger:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2);
  frame.dragger:SetNormalTexture(textureFilePath, "BLEND");
  frame.dragger:SetHighlightTexture(textureFilePath, "ADD");

  tk:MakeResizable(frame, frame.dragger);
  tk:ApplyThemeColor(
    frame.dragger:GetNormalTexture(), 
    frame.dragger:GetHighlightTexture());
end

do
  local function DisableHighlightOnMouseDown(btn)
    btn:GetHighlightTexture():SetAlpha(0);
  end

  local function EnableHighlightOnMouseUp(btn)
    btn:GetHighlightTexture():SetAlpha(1);
  end

  ---@param iconName "bag"|"sort"|"layout"|"arrow"|"cross"|"user"
  ---@param parent Frame
  ---@param highlight boolean
  ---@param iconRotation number?
  ---@return Texture
  function gui:CreateIconTexture(iconName, parent, highlight, iconRotation)
    local textureFilePath = tk:GetAssetFilePath("Icons\\buttons");
    local iconTexture = parent:CreateTexture(nil, highlight and "HIGHLIGHT" or "ARTWORK", nil, 7);
    iconTexture:SetTexture(textureFilePath);
    iconTexture:SetPoint("TOPLEFT", 6, -5);
    iconTexture:SetPoint("BOTTOMRIGHT", -6, 7);
    tk:ApplyThemeColor(iconTexture);

    local left = 0.454545;
    local right = 0.7272727;

    if (highlight) then
      left = right;
      right = 1;
      iconTexture:SetBlendMode("ADD");
      iconTexture:SetAlpha(0.6);
    end

    if (iconName == "bag") then
      iconTexture:SetTexCoord(left, right, 0, 0.196850);
    elseif (iconName == "sort") then
      iconTexture:SetTexCoord(left, right, 0.196850, 0.362204);
    elseif (iconName == "layout") then
      iconTexture:SetTexCoord(left, right, 0.362204, 0.535433);
    elseif (iconName == "arrow") then
      iconTexture:SetTexCoord(left, right, 0.535433, 0.685039);
    elseif (iconName == "cross") then
      iconTexture:SetTexCoord(left, right, 0.685039, 0.834645);
    elseif (iconName == "user") then
      iconTexture:SetTexCoord(left, right, 0.834645, 1);
    end

    if (iconRotation) then
      iconTexture:SetRotation(math.rad(iconRotation));
    end

    return iconTexture;
  end

  ---@param iconName "bag"|"sort"|"layout"|"arrow"|"cross"|"user"
  ---@param parent Frame?
  ---@param globalName string?
  ---@param button Button?
  ---@param iconRotation number?
  ---@return Button
  function gui:CreateIconButton(iconName, parent, globalName, button, iconRotation)
    local btn = button or tk:CreateFrame("Button", parent, globalName);
    btn:SetSize(30, 27.33);

    local textureFilePath = tk:GetAssetFilePath("Icons\\buttons");

    local normalTexture = btn:CreateTexture("$parentNormalTexture", "BACKGROUND");
    normalTexture:SetTexture(textureFilePath);
    normalTexture:SetTexCoord(0, 0.454545, 0, 0.322834);
    normalTexture:SetAllPoints(true);

    local disabledTexture = btn:CreateTexture("$parentDisabledTexture", "BACKGROUND");
    disabledTexture:SetTexture(textureFilePath);
    disabledTexture:SetTexCoord(0, 0.454545, 0, 0.322834);
    disabledTexture:SetAllPoints(true);

    local highlightTexture = btn:CreateTexture("$parentHighlightTexture", "BACKGROUND");
    highlightTexture:SetTexture(textureFilePath);
    highlightTexture:SetTexCoord(0, 0.454545, 0.322834, 0.645669);
    highlightTexture:SetAllPoints(true);

    local pushedTexture = btn:CreateTexture("$parentPushedTexture", "BACKGROUND");
    pushedTexture:SetTexture(textureFilePath);
    pushedTexture:SetTexCoord(0, 0.454545, 0.645669, 0.968503);
    pushedTexture:SetAllPoints(true);

    gui:CreateIconTexture(iconName, btn, false, iconRotation);
    gui:CreateIconTexture(iconName, btn, true, iconRotation);

    btn:SetNormalTexture(normalTexture);
    btn:SetDisabledTexture(disabledTexture);

    btn:SetHighlightTexture(highlightTexture);
    highlightTexture:SetBlendMode("BLEND");

    btn:SetPushedTexture(pushedTexture);
    tk:ApplyThemeColor(normalTexture, highlightTexture, pushedTexture);

    btn:HookScript("OnMouseDown", DisableHighlightOnMouseDown);
    btn:HookScript("OnMouseUp", EnableHighlightOnMouseUp);

    return btn;
  end
end

---@param iconName "bag"|"sort"|"layout"|"arrow"|"cross"|"user"
---@param iconRotation number?
function gui:ReskinIconButton(btn, iconName, iconRotation)
  local frame = btn:GetParent();
  frame.closeBtn = self:CreateIconButton(iconName, frame, nil, btn, iconRotation);
end

function gui:AddCloseButton(frame, onHideCallback, noAnimation)
  frame.closeBtn = self:CreateIconButton("cross", frame);
  frame.closeBtn:SetPoint("TOPRIGHT", -2, -1);

  if (noAnimation) then
    frame.closeBtn:SetScript("OnClick", function()
      if (obj:IsFunction(onHideCallback)) then
        onHideCallback(frame);
      end

      frame:Hide();
      PlaySound(tk.Constants.CLICK);
    end);

    return
  end

  local group = frame:CreateAnimationGroup();
  group.a1 = group:CreateAnimation("Translation");
  group.a1:SetSmoothing("OUT");
  group.a1:SetDuration(0.3);
  group.a1:SetOffset(0, 10);
  group.a2 = group:CreateAnimation("Alpha");
  group.a2:SetSmoothing("OUT");
  group.a2:SetDuration(0.3);
  group.a2:SetFromAlpha(1);
  group.a2:SetToAlpha(-1);

  group:SetScript("OnFinished", function()
    if (obj:IsFunction(onHideCallback)) then
      onHideCallback(frame);
    end

    frame:Hide();
  end);

  frame.closeBtn:SetScript("OnClick", function()
    if (obj:IsFunction(onClickCallback)) then
      onClickCallback(frame);
    end

    group:Play();
    PlaySound(tk.Constants.CLICK);
  end);
end

function gui:AddArrow(frame, direction, center)
  direction = direction or "UP";
  direction = direction:upper();

  frame.arrow = tk:CreateFrame("Frame", frame);
  frame.arrow:SetSize(30, 24);
  local texture = tk:GetAssetFilePath("Textures\\Widgets\\GraphicalArrow");
  frame.arrow.bg = frame.arrow:CreateTexture(nil, "ARTWORK");
  frame.arrow.bg:SetAllPoints(true);
  frame.arrow.bg:SetTexture(texture);
  tk:ApplyThemeColor(frame.arrow.bg);

  if (center) then
    frame.arrow:SetPoint("CENTER");
  end

  if (direction ~= "UP") then
    if (direction == "DOWN") then
      frame.arrow.bg:SetTexCoord(0, 1, 1, 0);

      if (not center) then
        frame.arrow:SetPoint("TOP", frame, "BOTTOM", 0, -2);
      end
    end
  end
end
