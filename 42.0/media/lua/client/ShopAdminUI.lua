if isServer() then return end
require "ISUI/ISCollapsableWindow"
require "ISUI/ISScrollingListBox"
require "ISUI/ISTextEntryBox"
require "ISUI/ISButton"

ShopAdminUI = ISCollapsableWindow:derive("ShopAdminUI")

function ShopAdminUI:initialise()
    ISCollapsableWindow.initialise(self)
    
    local fontHgt = getTextManager():getFontHeight(UIFont.Small)
    local itemHgt = math.max(fontHgt + 4, 24)
    
    -- LEFT PANEL: MASTER LIST
    self.searchEntry = ISTextEntryBox:new("", 10, 30, 380, 24)
    self.searchEntry:initialise()
    self.searchEntry:instantiate()
    self.searchEntry.onTextChange = function(box) self:populateMasterList() end
    self:addChild(self.searchEntry)
    
    self.masterList = ISScrollingListBox:new(10, 60, 380, self.height - 110)
    self.masterList:initialise()
    self.masterList:instantiate()
    self.masterList.itemheight = itemHgt
    self.masterList.selected = 0
    self.masterList.joypadParent = self
    self.masterList.font = UIFont.Small
    self.masterList.doDrawItem = self.drawMasterListItem
    self.masterList.drawBorder = true
    self:addChild(self.masterList)
    
    -- RIGHT PANEL: BUY CATALOG
    self.buyList = ISScrollingListBox:new(410, 30, 370, 180)
    self.buyList:initialise()
    self.buyList:instantiate()
    self.buyList.itemheight = itemHgt
    self.buyList.selected = 0
    self.buyList.joypadParent = self
    self.buyList.font = UIFont.Small
    self.buyList.doDrawItem = self.drawCatalogListItem
    self.buyList.drawBorder = true
    self:addChild(self.buyList)
    
    self.buyPriceEntry = ISTextEntryBox:new("100", 410, 220, 50, 24)
    self.buyPriceEntry:initialise()
    self.buyPriceEntry:instantiate()
    self.buyPriceEntry:setOnlyNumbers(true)
    self:addChild(self.buyPriceEntry)
    
    self.buyLimitEntry = ISTextEntryBox:new("50", 465, 220, 30, 24)
    self.buyLimitEntry:initialise()
    self.buyLimitEntry:instantiate()
    self.buyLimitEntry:setOnlyNumbers(true)
    self:addChild(self.buyLimitEntry)
    
    self.addBuyBtn = ISButton:new(500, 220, 130, 24, "Add to Buy", self, self.onAddBuy)
    self.addBuyBtn:initialise()
    self:addChild(self.addBuyBtn)
    
    self.removeBuyBtn = ISButton:new(640, 220, 140, 24, "Remove from Buy", self, self.onRemoveBuy)
    self.removeBuyBtn:initialise()
    self:addChild(self.removeBuyBtn)
    
    -- RIGHT PANEL: SELL CATALOG
    self.sellList = ISScrollingListBox:new(410, 280, 370, 180)
    self.sellList:initialise()
    self.sellList:instantiate()
    self.sellList.itemheight = itemHgt
    self.sellList.selected = 0
    self.sellList.joypadParent = self
    self.sellList.font = UIFont.Small
    self.sellList.doDrawItem = self.drawCatalogListItem
    self.sellList.drawBorder = true
    self:addChild(self.sellList)
    
    self.sellPriceEntry = ISTextEntryBox:new("50", 410, 470, 80, 24)
    self.sellPriceEntry:initialise()
    self.sellPriceEntry:instantiate()
    self.sellPriceEntry:setOnlyNumbers(true)
    self:addChild(self.sellPriceEntry)
    
    self.addSellBtn = ISButton:new(500, 470, 130, 24, "Add to Sell", self, self.onAddSell)
    self.addSellBtn:initialise()
    self:addChild(self.addSellBtn)
    
    self.removeSellBtn = ISButton:new(640, 470, 140, 24, "Remove from Sell", self, self.onRemoveSell)
    self.removeSellBtn:initialise()
    self:addChild(self.removeSellBtn)
    
    -- SAVE BUTTON
    self.saveBtn = ISButton:new(410, self.height - 40, 370, 30, "SAVE CATALOG TO SERVER", self, self.onSave)
    self.saveBtn:initialise()
    self.saveBtn.backgroundColor = {r=0, g=0.5, b=0, a=1.0}
    self.saveBtn.textColor = {r=1, g=1, b=1, a=1.0}
    self:addChild(self.saveBtn)
    
    -- CACHE ALL ITEMS
    self.allItems = {}
    local allItems = getScriptManager():getAllItems()
    for i=0, allItems:size()-1 do
        local item = allItems:get(i)
        if not item:getObsolete() then
            table.insert(self.allItems, item)
        end
    end
    
    -- Sort alphabetically by display name
    table.sort(self.allItems, function(a,b) return a:getDisplayName() < b:getDisplayName() end)
    
    self.catalogData = { Buy = {}, Sell = {}, Limits = {} }
    if ProjectShopee and ProjectShopee.Config and ProjectShopee.Config.Catalog then
        if ProjectShopee.Config.Catalog.Buy then
            for k,v in pairs(ProjectShopee.Config.Catalog.Buy) do self.catalogData.Buy[k] = v end
        end
        if ProjectShopee.Config.Catalog.Sell then
            for k,v in pairs(ProjectShopee.Config.Catalog.Sell) do self.catalogData.Sell[k] = v end
        end
        if ProjectShopee.Config.Catalog.Limits then
            for k,v in pairs(ProjectShopee.Config.Catalog.Limits) do self.catalogData.Limits[k] = v end
        end
    end
    
    self:populateMasterList()
    self:populateCatalogLists()
end

function ShopAdminUI:populateMasterList()
    self.masterList:clear()
    local searchTxt = string.lower(self.searchEntry:getInternalText() or "")
    
    for _, item in ipairs(self.allItems) do
        local name = string.lower(item:getDisplayName())
        local fName = string.lower(item:getFullName())
        if searchTxt == "" or string.find(name, searchTxt) or string.find(fName, searchTxt) then
            self.masterList:addItem(item:getFullName(), item)
        end
    end
end

function ShopAdminUI:populateCatalogLists()
    self.buyList:clear()
    for itemName, price in pairs(self.catalogData.Buy) do
        local itemObj = getScriptManager():getItem(itemName)
        local limit = self.catalogData.Limits[itemName] or 50
        self.buyList:addItem(itemName, {name=itemName, price=price, itemObj=itemObj, limit=limit})
    end
    -- Zomboid ISScrollingListBox doesn't have a reliable sort method by default if items aren't perfectly structured,
    -- so we rely on the insertion order, or we can pre-sort.
    
    self.sellList:clear()
    for itemName, price in pairs(self.catalogData.Sell) do
        local itemObj = getScriptManager():getItem(itemName)
        self.sellList:addItem(itemName, {name=itemName, price=price, itemObj=itemObj})
    end
end

function ShopAdminUI:onAddBuy()
    local sel = self.masterList.items[self.masterList.selected]
    if not sel then return end
    local itemName = sel.item:getFullName()
    local price = tonumber(self.buyPriceEntry:getInternalText()) or 100
    local limit = tonumber(self.buyLimitEntry:getInternalText()) or 50
    self.catalogData.Buy[itemName] = price
    self.catalogData.Limits[itemName] = limit
    self:populateCatalogLists()
end

function ShopAdminUI:onRemoveBuy()
    local sel = self.buyList.items[self.buyList.selected]
    if not sel then return end
    self.catalogData.Buy[sel.item.name] = nil
    self.catalogData.Limits[sel.item.name] = nil
    self:populateCatalogLists()
end

function ShopAdminUI:onAddSell()
    local sel = self.masterList.items[self.masterList.selected]
    if not sel then return end
    local itemName = sel.item:getFullName()
    local price = tonumber(self.sellPriceEntry:getInternalText()) or 50
    self.catalogData.Sell[itemName] = price
    self:populateCatalogLists()
end

function ShopAdminUI:onRemoveSell()
    local sel = self.sellList.items[self.sellList.selected]
    if not sel then return end
    self.catalogData.Sell[sel.item.name] = nil
    self:populateCatalogLists()
end

function ShopAdminUI:drawMasterListItem(y, item, alt)
    local a = 0.9;
    if self.selected == item.index then
        self:drawRect(0, (y), self:getWidth(), item.height-1, 0.3, 0.7, 0.35, 0.15);
    end
    self:drawRectBorder(0, (y), self:getWidth(), item.height, a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

    local itemObj = item.item;
    local tex = itemObj:getNormalTexture()
    if tex then
        self:drawTextureScaledAspect(tex, 4, y+2, 20, 20, 1, 1, 1, 1)
    end
    
    self:drawText(itemObj:getFullName(), 30, y + (item.height - self.fontHgt)/2, 0.6, 0.6, 0.8, a, self.font);
    self:drawText(itemObj:getDisplayName(), 180, y + (item.height - self.fontHgt)/2, 1, 1, 1, a, self.font);

    return y + item.height;
end

function ShopAdminUI:drawCatalogListItem(y, item, alt)
    local a = 0.9;
    if self.selected == item.index then
        self:drawRect(0, (y), self:getWidth(), item.height-1, 0.3, 0.7, 0.35, 0.15);
    end
    self:drawRectBorder(0, (y), self:getWidth(), item.height, a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

    local data = item.item;
    if data.itemObj then
        local tex = data.itemObj:getNormalTexture()
        if tex then
            self:drawTextureScaledAspect(tex, 4, y+2, 20, 20, 1, 1, 1, 1)
        end
        self:drawText(data.itemObj:getDisplayName(), 30, y + (item.height - self.fontHgt)/2, 1, 1, 1, a, self.font);
    else
        self:drawText(data.name, 30, y + (item.height - self.fontHgt)/2, 1, 0.3, 0.3, a, self.font);
    end
    self:drawText("$" .. tostring(data.price), 250, y + (item.height - self.fontHgt)/2, 0.2, 1, 0.2, a, self.font);
    if data.limit then
        self:drawText("Max: " .. tostring(data.limit), 300, y + (item.height - self.fontHgt)/2, 0.8, 0.8, 0.2, a, self.font);
    end

    return y + item.height;
end

function ShopAdminUI:refresh()
    -- Sync internal catalog data with global config if it changed
    self.catalogData = { Buy = {}, Sell = {}, Limits = {} }
    if ProjectShopee and ProjectShopee.Config and ProjectShopee.Config.Catalog then
        if ProjectShopee.Config.Catalog.Buy then
            for k,v in pairs(ProjectShopee.Config.Catalog.Buy) do self.catalogData.Buy[k] = v end
        end
        if ProjectShopee.Config.Catalog.Sell then
            for k,v in pairs(ProjectShopee.Config.Catalog.Sell) do self.catalogData.Sell[k] = v end
        end
        if ProjectShopee.Config.Catalog.Limits then
            for k,v in pairs(ProjectShopee.Config.Catalog.Limits) do self.catalogData.Limits[k] = v end
        end
    end
    self:populateMasterList()
    self:populateCatalogLists()
end

function ShopAdminUI:onSave()
    sendClientCommand("ProjectShopee", ProjectShopee.Commands.UpdateCatalog, {Catalog=self.catalogData})
    self:close()
end

function ShopAdminUI:render()
    ISCollapsableWindow.render(self)
    self:drawText("Search Game Items:", 10, 15, 1, 1, 1, 1, UIFont.Small)
    self:drawText("Buy Catalog:", 410, 15, 1, 1, 1, 1, UIFont.Small)
    self:drawText("Sell Catalog:", 410, 265, 1, 1, 1, 1, UIFont.Small)
end

function ShopAdminUI:new(x, y, width, height, player)
    local o = {}
    x = getCore():getScreenWidth() - width - 50
    y = getCore():getScreenHeight() / 2 - (height / 2)
    o = ISCollapsableWindow:new(x, y, 800, 560)
    setmetatable(o, self)
    self.__index = self
    o.title = "Admin Catalog Manager"
    o.resizable = false
    o.pin = true
    o.isCollapsed = false
    o.collapseCounter = 0
    o.clearStentil = false
    o.moveWithMouse = true
    o.player = player
    return o
end
