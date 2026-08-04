require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISScrollingListBox"

ShopPersonalLogsUI = ISCollapsableWindow:derive("ShopPersonalLogsUI")

function ShopPersonalLogsUI:initialise()
    ISCollapsableWindow.initialise(self)
    self:create()
end

function ShopPersonalLogsUI:create()
    local fontHgt = getTextManager():getFontHeight(UIFont.Small)
    
    self.list = ISScrollingListBox:new(10, 25, self.width - 20, self.height - 40)
    self.list:initialise()
    self.list:instantiate()
    self.list.itemheight = fontHgt + 4
    self.list.selected = 0
    self.list.font = UIFont.Small
    self.list.doDrawItem = self.drawListItem
    self.list.drawBorder = true
    self:addChild(self.list)
    
    self:populateList()
end

function ShopPersonalLogsUI:drawListItem(y, item, alt)
    local a = 0.9;
    self:drawRectBorder(0, y, self:getWidth(), self.itemheight, a, self.borderColor.r, self.borderColor.g, self.borderColor.b)

    if self.selected == item.index then
        self:drawRect(0, y, self:getWidth(), self.itemheight, 0.3, 0.7, 0.35, 0.15)
    end

    self:drawText(item.text, 5, y + 2, 1, 1, 1, a, self.font)
    return y + self.itemheight
end

function ShopPersonalLogsUI:populateList()
    self.list:clear()
    local shop = ProjectShopee.Config.PersonalShops and ProjectShopee.Config.PersonalShops[self.pos]
    if not shop then return end
    
    if shop.Logs and #shop.Logs > 0 then
        for _, logStr in ipairs(shop.Logs) do
            self.list:addItem(logStr, nil)
        end
    else
        self.list:addItem("No transactions yet.", nil)
    end
end

function ShopPersonalLogsUI:new(x, y, width, height, pos)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.title = "Transaction Logs"
    o.resizable = false
    o.pin = true
    o.isCollapsed = false
    o.pos = pos
    return o
end
