-- luacheck: ignore self
local _G = _G;
local MayronUI = _G.MayronUI;
local math, Mixin = _G.math, _G.Mixin;
local CreateAndInitFromMixin = _G.CreateAndInitFromMixin;
local tk, _, _, _, obj = MayronUI:GetCoreComponents();

local ScrollBarWidth = 6;
local ScrollFrame_OnScrollRangeChanged = _G["ScrollFrame_OnScrollRangeChanged"];

---@class MayronUI.GUIBuilder
local gui = MayronUI:GetComponent("GUIBuilder");

local function UpdateScrollChildPosition(self, yRange, offset)
  local frame = self:GetScrollChild();
  local xOffset = 0;

  if (yRange > 0 and self.ScrollBar:IsShown()) then
    local barOffset = frame.barOffset--[[@as number]] or 0;
    xOffset = barOffset + self.ScrollBar:GetWidth();
  end

  if (xOffset > 0) then
    xOffset = -xOffset;
  end

  frame:ClearAllPoints();
  frame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, offset);
  frame:SetPoint("TOPRIGHT", self, "TOPRIGHT", xOffset, offset);
end

---@param self ScrollFrame|table
---@param yRange number
local function DynamicScrollFrame_OnScrollRangeChanged(self, xRange, yRange)
  local frame = self:GetScrollChild();
  local offset = self:GetVerticalScroll();

  if (self.animating) then
    self.ScrollBar:Hide();

    if (offset > 0) then
      self:SetVerticalScroll(0);
    else
      frame:ClearAllPoints();
      frame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0);
      frame:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 0);
    end

    return
  end

  ScrollFrame_OnScrollRangeChanged(self, xRange, yRange);
  UpdateScrollChildPosition(self, yRange, offset);
  local scrollStep = math.floor(frame:GetHeight() + 0.5) * 0.025;
  self.ScrollBar.scrollStep = scrollStep;
end

local function DynamicScrollFrame_OnMouseWheel(self, step)
  if (not self.ScrollBar:IsShown()) then
    self:SetVerticalScroll(0);
    return
  end

  local amount = self.ScrollBar.scrollStep;
  local offset = self:GetVerticalScroll() - (step * amount);
  local yRange = self:GetVerticalScrollRange();

  if (offset < 0) then
    offset = 0;
  elseif (offset > yRange) then
    offset = yRange;
  end

  self:SetVerticalScroll(offset);
  UpdateScrollChildPosition(self, yRange, offset);
end

local function DynamicScrollFrame_OnShow(self)
  local offset = self:GetVerticalScroll();
  local yRange = self:GetVerticalScrollRange();
  UpdateScrollChildPosition(self, yRange, offset);
end

---@param parent Frame The ScrollFrame's parent frame
---@param scrollFrameName string? The global name for the new ScrollFrame
function gui:CreateScrollFrame(parent, scrollFrameName)
  if (scrollFrameName == nil) then
    local parentName = parent:GetName();
    scrollFrameName = parentName and (parentName.."ScrollFrame") or nil;
  end

  local scrollFrame = tk:CreateFrame("ScrollFrame", parent, scrollFrameName, "UIPanelScrollFrameTemplate");

  Mixin(scrollFrame, _G["BackdropTemplateMixin"]);
  scrollFrame:EnableMouseWheel(true);
  scrollFrame.scrollBarHideable = true;

  local scrollBar = scrollFrame.ScrollBar--[[@as Slider|table]];
  tk:KillElement(scrollBar.ScrollUpButton);
  tk:KillElement(scrollBar.ScrollDownButton);

  scrollBar:ClearAllPoints();
  scrollBar:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 0, 0);
  scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", -ScrollBarWidth, 0);

  scrollFrame:SetScript("OnMouseWheel", DynamicScrollFrame_OnMouseWheel);
  scrollFrame:SetScript("OnShow", DynamicScrollFrame_OnShow);
  scrollFrame:SetScript("OnScrollRangeChanged", DynamicScrollFrame_OnScrollRangeChanged);
  scrollFrame:HookScript("OnVerticalScroll", DynamicScrollFrame_OnShow);

  local thumb = scrollBar:GetThumbTexture()--[[@as Texture]];
  scrollBar.thumb = thumb;
  local r, g, b = tk:GetThemeColor();
  thumb:SetTexture(tk.Constants.SOLID_TEXTURE);
  thumb:SetVertexColor(r, g, b, 0.8);
  thumb:SetSize(ScrollBarWidth, 50);
  scrollBar:Hide();

  return scrollFrame, scrollBar;
end

---@param frame Frame The ScrollFrame's Child frame
---@param scrollFrameName string? The global name for the new ScrollFrame
---@param barOffset number? The distance the frame is away from the scroll bar
---@return ScrollFrame scrollFrame, Slider scrollBar
function gui:WrapInScrollFrame(frame, scrollFrameName, barOffset)
  local parent = frame:GetParent()--[[@as Frame]];

  if (scrollFrameName == nil) then
    local frameName = frame:GetName();
    scrollFrameName = frameName and (frameName.."ScrollFrame") or nil;
  end

  local scrollFrame, scrollBar = self:CreateScrollFrame(parent, scrollFrameName);

  local frameWidth, frameHeight = frame:GetSize();
  scrollFrame:SetSize(frameWidth or 300, frameHeight or 300);

  for p = 1, frame:GetNumPoints() do
    local point, relFrame, relPoint, xOffset, yOffset = frame:GetPoint(p);
    scrollFrame:SetPoint(point, relFrame, relPoint, xOffset, yOffset);
  end

  scrollFrame:SetScrollChild(frame);

  frame.barOffset = barOffset or 0;
  frame:ClearAllPoints();
  frame:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0);
  frame:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 0, 0);

  return scrollFrame, scrollBar;
end

---@class MayronUI.DynamicFrame
---@field private __spacing number
---@field private __padding number
---@field private __children (table|Region)[]
---@field private __wrap boolean
---@field private __devMode boolean
---@field private __frame Region|table
---@field private __background (Texture|table)?
---@field private __scrollFrame (ScrollFrame|table)?
---@field private __scrollBar (Slider|table)?
local DynamicFrameMixin = {};

---@param parent Frame
---@param globalName string?
---@param spacing number?
---@param padding number?
---@return MayronUI.DynamicFrame
function gui:CreateDynamicFrame(parent, globalName, spacing, padding)
  return CreateAndInitFromMixin(DynamicFrameMixin, parent, globalName, spacing, padding)
end

---@param parent Frame
---@param globalName string?
---@param spacing number?
---@param padding number?
function DynamicFrameMixin:Init(parent, globalName, spacing, padding)
  self.__spacing = spacing or 0;
  self.__padding = padding or 0;
  self.__wrap = true;
  self.__devMode = false;
  self.__children = {};
  self.__frame = tk:CreateFrame("Frame", parent, globalName);

  local refreshWrapper = function() self:Refresh() end
  self.__frame:SetScript("OnSizeChanged", refreshWrapper);
  self.__frame:SetScript("OnShow", refreshWrapper);
end

---@param r number
---@param g number
---@param b number
---@param a number?
function DynamicFrameMixin:SetBackgroundColor(r, g, b, a)
  if (not self.__background) then
    self.__background = tk:SetBackground(self.__frame, r, g, b, a);
  else
    self.__background:SetVertexColor(r, g, b, a or 1);
  end
end

function DynamicFrameMixin:WrapInScrollFrame()
  if (not self.__scrollFrame) then
    self.__scrollFrame, self.__scrollBar = gui:WrapInScrollFrame(self.__frame);
  end

  return self.__scrollFrame, self.__scrollBar;
end

function DynamicFrameMixin:GetFrame()
  return self.__frame;
end

---@return table|ScrollFrame|BackdropTemplate
function DynamicFrameMixin:GetScrollFrame()
  return self.__scrollFrame;
end

---@return table|Slider
function DynamicFrameMixin:GetScrollBar()
  return self.__scrollBar;
end

---@param wrap boolean
function DynamicFrameMixin:SetWrappingEnabled(wrap)
  self.__wrap = wrap;
end

---@return (table|Region)[]
function DynamicFrameMixin:GetChildren()
  return self.__children;
end

---@param ... Region
---@overload fun(self, children: Region[])
function DynamicFrameMixin:AddChildren(...)
  local length = select("#", ...);

  if (length == 1) then
    local arg1 = ...;

    if (type(arg1) == "table" and not arg1.GetObjectType) then
      for _, child in ipairs(arg1) do
        self:AddChild(child);
      end

      return
    end
  end

  for i = 1, length do
    local child = (select(i, ...));
    self:AddChild(child);
  end
end

---@param child Region
function DynamicFrameMixin:AddChild(child)
  tk:Assert(
    type(child) == "table" and type(child.GetObjectType) == "function",
    "Failed to add child to dynamic frame.");

  child:ClearAllPoints();
  child:SetParent(self.__frame);
  self.__children[#self.__children+1] = child;
end

function DynamicFrameMixin:SetDevMode(devMode)
  self.__devMode = devMode;
end

---@param child Frame
function DynamicFrameMixin:RemoveChild(child)
  local position;

  for id, otherChild in ipairs(self.__children) do
    if (otherChild == child) then
      position = id;
      break
    end
  end

  if (position) then
    table.remove(self.__children, position);
  end
end

local function ModifyRowChildren(row, rowHeight)
  for _, rowChild in ipairs(row) do
    local childHeight = rowChild:GetHeight();
    local diff = rowHeight - childHeight;

    if (diff >= 2) then
      local gap = math.ceil(diff / 2);
      local point, relFrame, relPoint, xOffset, yOffset = rowChild:GetPoint(1);
      rowChild:SetPoint(point, relFrame, relPoint, xOffset, yOffset - gap);
    end
  end
end

function DynamicFrameMixin:Refresh()
  local row = obj:PopTable();
  local rowHeight = 0;
  local rowWidth = 0;
  local minCanvasWidth;
  local canvasHeight = 0;
  local canvasWidth = self.__frame:GetWidth() - (self.__padding * 2);
  local canvasXOffset, canvasYOffset = 0, 0;

  for _, child in ipairs(self.__children) do
    if (child:IsShown()) then
      if (type(child.OnDynamicFrameRefresh) == "function") then
        child:OnDynamicFrameRefresh(canvasWidth);
      end
    end
  end

  local function AddChildToRow(child)
    local childWidth, childHeight = child:GetSize();

    child:SetPoint("TOPLEFT", canvasXOffset + self.__padding, -(canvasYOffset + self.__padding));
    canvasXOffset = canvasXOffset + childWidth;

    row[#row+1] = child;

    rowWidth = canvasXOffset;
    rowHeight = math.max(rowHeight, childHeight);
    canvasHeight = math.max(canvasHeight, canvasYOffset + rowHeight);
  end

  for _, child in ipairs(self.__children) do
    if (self.__devMode and not child.__background) then
      local f = child--[[@as Frame]];
      tk:SetBackground(f, math.random(), math.random(), math.random());
    end

    if (child:IsShown()) then
      local childWidth = child:GetWidth();

      if (child.fullWidth) then
        childWidth = canvasWidth;
        child:SetWidth(childWidth);

      elseif (child.fillWidth) then
        childWidth = canvasWidth - canvasXOffset;

        if (#row > 0) then
          childWidth = childWidth - self.__spacing;
        end

        child:SetWidth(childWidth);

      elseif (child.percentWidth) then
        local percent = child.percentWidth;
        if (percent > 1) then
          percent = percent / 100;
        end

        if (percent < 0.01) then
          percent = 0.01;
        end

        childWidth = canvasWidth * percent;
        child:SetWidth(childWidth - self.__spacing);
      end

      if (child.minWidth and childWidth < child.minWidth) then
        childWidth = child.minWidth;
        child:SetWidth(childWidth);
      end

      local firstChild = #row == 0;
      local estimatedCanvasXOffset = childWidth; -- if added to current row, this would be the canvasXOffset
      local forceNewRow = child.divider;

      if (not firstChild) then
        canvasXOffset = canvasXOffset + self.__spacing;
        estimatedCanvasXOffset = estimatedCanvasXOffset + canvasXOffset;
      end

      local notEnoughRoom = canvasWidth < estimatedCanvasXOffset;
      local multipleRowsAllowed = self.__wrap;

      if (forceNewRow or (not firstChild and multipleRowsAllowed and notEnoughRoom)) then
        -- New row required
        canvasXOffset = 0;

        canvasYOffset = canvasYOffset + self.__spacing + rowHeight;
        ModifyRowChildren(row, rowHeight);

        if (minCanvasWidth == nil) then
          minCanvasWidth = rowWidth;
        else
          minCanvasWidth = math.min(minCanvasWidth, rowWidth);
        end

        tk.Tables:Empty(row);
        rowHeight = 0;
      end

      if (not forceNewRow) then
        AddChildToRow(child);
      end
    end
  end

  ModifyRowChildren(row, rowHeight);

  if (minCanvasWidth == nil) then
    minCanvasWidth = rowWidth;
  else
    minCanvasWidth = math.min(minCanvasWidth, rowWidth);
  end

  -- For DynamicFrame's as children of other DynamicFrames
  self.__frame.minWidth = minCanvasWidth + (self.__padding * 2);

  obj:PushTable(row);

  local newFrameHeight = canvasHeight + (self.__padding * 2);
  self.__frame:SetHeight(newFrameHeight);
end

