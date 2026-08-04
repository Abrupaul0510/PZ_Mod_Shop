require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISTextEntryBox"
require "ISUI/ISScrollingListBox"

ShopAdminRatiosUI = ISPanel:derive("ShopAdminRatiosUI")

function ShopAdminRatiosUI:initialise()
    ISPanel.initialise(self)
    self:create()
end

function ShopAdminRatiosUI:create()
    local fontHgt = getTextManager():getFontHeight(UIFont.Small)

    self.closeBtn = ISButton:new(self.width - 100, 10, 90, 25, "Close", self, self.close)
    self.closeBtn:initialise()
    self:addChild(self.closeBtn)
    
    self.saveBtn = ISButton:new(self.width - 200, 10, 90, 25, "Save", self, self.onSave)
    self.saveBtn:initialise()
    self:addChild(self.saveBtn)

    self.ratioList = ISScrollingListBox:new(10, 50, self.width - 20, self.height - 100)
    self.ratioList:initialise()
    self.ratioList:instantiate()
    self.ratioList.itemheight = math.max(fontHgt + 4, 24)
    self.ratioList.selected = 0
    self.ratioList.font = UIFont.Small
    self.ratioList.doDrawItem = self.drawRatioItem
    self.ratioList.drawBorder = true
    self:addChild(self.ratioList)
    
    self.ratioList.onMouseUp = function(list, x, y)
        local selectedItem = list.items[list.selected]
        if selectedItem and selectedItem.item then
            self.valueEntry:setText(tostring(selectedItem.item.ratio))
        end
    end

    self.valueEntry = ISTextEntryBox:new("0", 10, self.height - 40, 150, 25)
    self.valueEntry:initialise()
    self.valueEntry:instantiate()
    self.valueEntry:setOnlyNumbers(true)
    self:addChild(self.valueEntry)
    
    self.updateBtn = ISButton:new(170, self.height - 40, self.width - 180, 25, "Update Selected Ratio", self, self.onUpdateRatio)
    self.updateBtn:initialise()
    self:addChild(self.updateBtn)
    
    self.ratios = {}
    if ProjectShopee.Config.MoneyRatios then
        for item, ratio in pairs(ProjectShopee.Config.MoneyRatios) do
            self.ratios[item] = ratio
        end
    end
    
    self:populateList()
end

function ShopAdminRatiosUI:drawRatioItem(y, item, alt)
    local a = 0.9;
    if self.selected == item.index then
        self:drawRect(0, (y), self:getWidth(), item.height-1, 0.3, 0.7, 0.35, 0.15);
    end
    self:drawRectBorder(0, (y), self:getWidth(), item.height, a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

    local data = item.item;
    local itemObj = ScriptManager.instance:getItem(data.item)
    if itemObj then
        local tex = itemObj:getNormalTexture()
        if tex then
            self:drawTextureScaledAspect(tex, 4, y+2, 20, 20, 1, 1, 1, 1)
        end
        self:drawText(itemObj:getDisplayName(), 30, y + (item.height - self.fontHgt)/2, 1, 1, 1, a, self.font);
    else
        self:drawText(data.item, 30, y + (item.height - self.fontHgt)/2, 1, 0.3, 0.3, a, self.font);
    end
    
    local ratioStr = "=$" .. tostring(data.ratio)
    local ratioWid = getTextManager():MeasureStringX(self.font, ratioStr)
    self:drawText(ratioStr, self:getWidth() - ratioWid - 10, y + (item.height - self.fontHgt)/2, 0.2, 1, 0.2, a, self.font);

    return y + item.height;
end

function ShopAdminRatiosUI:populateList()
    self.ratioList:clear()
    for item, ratio in pairs(self.ratios) do
        self.ratioList:addItem(item, {item=item, ratio=ratio})
    end
end

function ShopAdminRatiosUI:onUpdateRatio()
    local selectedItem = self.ratioList.items[self.ratioList.selected]
    if selectedItem and selectedItem.item then
        local newRatio = tonumber(self.valueEntry:getText())
        if newRatio then
            self.ratios[selectedItem.item.item] = newRatio
            self:populateList()
        end
    end
end

function ShopAdminRatiosUI:onSave()
    sendClientCommand("ProjectShopee", ProjectShopee.Commands.UpdateMoneyRatios, {Ratios = self.ratios})
    getPlayer():Say("Money Ratios Saved!")
    self:close()
end

function ShopAdminRatiosUI:prerender()
    ISPanel.prerender(self)
    self:drawText("Configure ATM Money Ratios", 10, 10, 1, 1, 1, 1, UIFont.Medium)
    self:drawText("How much bank balance is 1 item worth?", 10, 30, 0.7, 0.7, 0.7, 1, UIFont.Small)
end

function ShopAdminRatiosUI:close()
    self:removeFromUIManager()
end

function ShopAdminRatiosUI:new(x, y, width, height, player)
    local o = {}
    x = getCore():getScreenWidth() - width - 50
    y = getCore():getScreenHeight() / 2 - (height / 2)
    o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0, g=0, b=0, a=0.9}
    o.borderColor = {r=1, g=1, b=1, a=1}
    o.playerNum = player:getPlayerNum()
    o.player = player
    o.moveWithMouse = true
    return o
end
