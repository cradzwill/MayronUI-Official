local _, namespace = ...;
local em = namespace.EventManager;
local tk = namespace.Toolkit;
local gui = namespace.GUIBuilder;

local private = {};
private.troops = {};

local IsAddOnLoaded = IsAddOnLoaded;

function namespace:SetupOrderHallBar()
    if (IsAddOnLoaded("Blizzard_OrderHallUI")) then

        private:ReskinCommandBar();
        tk.hooksecurefunc(OrderHallCommandBar, "RefreshCategories", private.EnumerateTroops);

    else
        em:CreateEventHandler("ADDON_LOADED", function(handler, _, name)

            if (name == "Blizzard_OrderHallUI" and OrderHallCommandBar) then
                self:SetupOrderHallBar();
                handler:Destroy();
            end

        end);
    end
end

function private:ReskinCommandBar()
    tk:KillElement(OrderHallCommandBar.Background);
    tk:KillElement(OrderHallCommandBar.WorldMapButton);
    gui:CreateDialogBox(nil, "LOW", OrderHallCommandBar);

    OrderHallCommandBar:ClearAllPoints();
    OrderHallCommandBar:SetPoint("TOP");
    OrderHallCommandBar.SetPoint = tk.Constants.DUMMY_FUNC;
    OrderHallCommandBar.ClearAllPoints = tk.Constants.DUMMY_FUNC;
    OrderHallCommandBar.AreaName:ClearAllPoints();
    OrderHallCommandBar.Currency:SetPoint("LEFT", OrderHallCommandBar.ClassIcon, "RIGHT", 10, 0);
    OrderHallCommandBar.AreaName:SetPoint("LEFT", OrderHallCommandBar.CurrencyIcon, "RIGHT", 10, 2);
    OrderHallCommandBar:SetWidth(OrderHallCommandBar.AreaName:GetStringWidth() + 500);
end

function private:EnumerateTroops()
    local width = OrderHallCommandBar.AreaName:GetStringWidth() + 200;
    tk:EmptyTable(private.troops);

    for frame in OrderHallCommandBar.categoryPool:EnumerateActive() do
        tk.table.insert(private.troops, frame);
    end

    for id, frame in tk.ipairs(private.troops) do

        frame:ClearAllPoints();
        width = width + frame:GetSize() + 4;

        tk:KillElement(frame.TroopPortraitCover);

        if (id == 1) then
            frame:SetPoint("RIGHT", OrderHallCommandBar, "RIGHT", -4, 0);
        else
            frame:SetPoint("RIGHT", private.troops[id - 1], "LEFT", -4, 0);
        end
    end

    OrderHallCommandBar:SetWidth(width);
end