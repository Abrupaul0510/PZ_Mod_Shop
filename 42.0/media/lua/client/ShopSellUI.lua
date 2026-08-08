if isServer() then return end
require "ISUI/ISCollapsableWindow"
require "ISUI/ISScrollingListBox"
require "ISUI/ISButton"
require "ISUI/ISTextEntryBox"

ShopSellUI = ISCollapsableWindow:derive("ShopSellUI")

function ShopSellUI:initialise()
    ISCollapsableWindow.initialise(self)
    
    local btnWid = 100
    local btnHgt = 25
    local fontHgt = getTextManager():getFontHeight(UIFont.Small)
    local itemHgt = math.max(fontHgt + 4, 24)
    
    self.sellList = ISScrollingListBox:new(10, 30, self.width - 20, self.height - 80)
    self.sellList:initialise()
    self.sellList:instantiate()
    self.sellList.itemheight = itemHgt
    self.sellList.selected = 0
    self.sellList.joypadParent = self
    self.sellList.font = UIFont.Small
    self.sellList.doDrawItem = self.drawSellListItem
    self.sellList.drawBorder = true
    self:addChild(self.sellList)
    
    self.sellBtn = ISButton:new(10, self.height - btnHgt - 10, 80, btnHgt, "Sell", self, self.onSell)
    self.sellBtn:initialise()
    self:addChild(self.sellBtn)
    
    self.sellAmountEntry = ISTextEntryBox:new("1", 95, self.height - btnHgt - 10, 40, btnHgt)
    self.sellAmountEntry:initialise()
    self.sellAmountEntry:instantiate()
    self.sellAmountEntry:setOnlyNumbers(true)
    self.sellAmountEntry:setMaxTextLength(6)
    self:addChild(self.sellAmountEntry)
    
    self.sellAllBtn = ISButton:new(140, self.height - btnHgt - 10, 80, btnHgt, "Sell ALL", self, self.onSellAll)
    self.sellAllBtn:initialise()
    self:addChild(self.sellAllBtn)
    
    self.processingTimer = 0
    
    self:populateList()
end

function ShopSellUI:drawSellListItem(y, item, alt)
    local a = 0.9;
    if self.selected == item.index then
        self:drawRect(0, (y), self:getWidth(), item.height-1, 0.3, 0.7, 0.35, 0.15);
    end
    self:drawRectBorder(0, (y), self:getWidth(), item.height, a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

    local data = item.item;
    local itemObj = data.itemObj
    
    if itemObj then
        local tex = itemObj:getNormalTexture()
        if tex then
            self:drawTextureScaledAspect(tex, 4, y+2, 20, 20, 1, 1, 1, 1)
        end
    end
    
    local priceStr = "Sell for: $" .. tostring(data.price * data.count)
    local priceWid = getTextManager():MeasureStringX(self.font, priceStr)
    local itemName = tostring(data.count) .. "x " .. (itemObj and itemObj:getDisplayName() or data.name)
    local maxTextWidth = self:getWidth() - priceWid - 70
    
    if getTextManager():MeasureStringX(self.font, itemName) > maxTextWidth then
        while string.len(itemName) > 0 and getTextManager():MeasureStringX(self.font, itemName .. "...") > maxTextWidth do
            itemName = string.sub(itemName, 1, string.len(itemName) - 1)
        end
        itemName = itemName .. "..."
    end
    
    if itemObj then
        self:drawText(itemName, 30, y + (item.height - self.fontHgt)/2, 1, 1, 1, a, self.font);
    else
        self:drawText(itemName, 30, y + (item.height - self.fontHgt)/2, 1, 0.3, 0.3, a, self.font);
    end
    self:drawText(priceStr, self:getWidth() - priceWid - 30, y + (item.height - self.fontHgt)/2, 0.2, 1, 0.2, a, self.font);

    return y + item.height;
end

function ShopSellUI:populateList()
    self.sellList:clear()
    local inv = getPlayer():getInventory()
    local items = inv:getItems()
    local counts = {}
    local sampleItems = {}
    
    local catalog = ProjectShopee.Config.Catalogs and ProjectShopee.Config.Catalogs[self.storeID] or ProjectShopee.Config.Catalog
    
    for i=0, items:size()-1 do
        local invItem = items:get(i)
        local fullType = invItem:getFullType()
        if catalog.Sell and catalog.Sell[fullType] then
            if not counts[fullType] then
                counts[fullType] = 0
                sampleItems[fullType] = invItem
            end
            counts[fullType] = counts[fullType] + 1
        end
    end
    
    for fullType, count in pairs(counts) do
        local price = catalog.Sell[fullType]
        local itemObj = getScriptManager():getItem(fullType)
        self.sellList:addItem(fullType, {name=fullType, count=count, price=price, itemObj=itemObj})
    end
end

function ShopSellUI:onSell()
    if self.processingTimer > 0 then return end
    
    local sel = self.sellList.items[self.sellList.selected]
    if not sel then return end
    
    local itemName = sel.item.name
    local amount = tonumber(self.sellAmountEntry:getText()) or 1
    if amount < 1 then amount = 1 end
    
    if amount > sel.item.count then
        amount = sel.item.count
    end

    self.processingTimer = 15
    self.sellBtn.title = "Processing.."
    self.sellAllBtn.title = "Processing.."
    self.sellBtn.backgroundColor = {r=0.5, g=0.5, b=0.5, a=1.0}
    self.sellAllBtn.backgroundColor = {r=0.5, g=0.5, b=0.5, a=1.0}
    
    sendClientCommand("ProjectShopee", ProjectShopee.Commands.SellItem, {item=itemName, amount=amount, pos=self.pos, storeID=self.storeID})
end

function ShopSellUI:onSellAll()
    if self.processingTimer > 0 then return end
    
    local sel = self.sellList.items[self.sellList.selected]
    if not sel then return end
    
    local itemName = sel.item.name
    local amount = sel.item.count
    
    self.processingTimer = 15
    self.sellBtn.title = "Processing.."
    self.sellAllBtn.title = "Processing.."
    self.sellBtn.backgroundColor = {r=0.5, g=0.5, b=0.5, a=1.0}
    self.sellAllBtn.backgroundColor = {r=0.5, g=0.5, b=0.5, a=1.0}
    
    sendClientCommand("ProjectShopee", ProjectShopee.Commands.SellItem, {item=itemName, amount=amount, pos=self.pos, storeID=self.storeID})
end

function ShopSellUI:prerender()
    ISCollapsableWindow.prerender(self)
    self:drawText("Sellable Items in Inventory", 10, 10, 1, 1, 1, 1, UIFont.Small)
    
    local balance = ProjectShopee.Client.Balance or 0
    local bText = "Balance: $" .. tostring(balance)
    local tw = getTextManager():MeasureStringX(UIFont.Small, bText)
    self:drawText(bText, self.width - tw - 10, 10, 0.2, 0.9, 0.2, 1, UIFont.Small)
end

function ShopSellUI:update()
    ISCollapsableWindow.update(self)
    if not self:getIsVisible() then return end
    
    if self.processingTimer > 0 then
        self.processingTimer = self.processingTimer - 1
        if self.processingTimer <= 0 then
            self:populateList()
            self.sellBtn.title = "Sell"
            self.sellAllBtn.title = "Sell ALL"
            self.sellBtn.backgroundColor = {r=0, g=0, b=0, a=1.0}
            self.sellAllBtn.backgroundColor = {r=0, g=0, b=0, a=1.0}
        end
    end

    if self.sellAmountEntry then
        local text = self.sellAmountEntry:getText()
        local scrubbed = text:gsub("[^0-9]", "")
        if text ~= scrubbed then self.sellAmountEntry:setText(scrubbed) end
    end
end

function ShopSellUI:new(x, y, width, height, player, pos, storeID)
    local o = {}
    x = getCore():getScreenWidth() / 2 - (width / 2)
    y = getCore():getScreenHeight() / 2 - (height / 2)
    o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.storeID = storeID or "Store1"
    o.title = "Sell My Items (" .. o.storeID .. ")"
    o.resizable = false
    o.pin = true
    o.isCollapsed = false
    o.clearStentil = false
    o.moveWithMouse = true
    o.player = player
    o.pos = pos
    return o
end
