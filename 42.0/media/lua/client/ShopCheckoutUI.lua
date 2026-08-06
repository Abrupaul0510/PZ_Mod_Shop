if isServer() then return end
require "ISUI/ISCollapsableWindow"
require "ISUI/ISScrollingListBox"
require "ISUI/ISButton"
require "ISUI/ISComboBox"
require "ISUI/ISTextEntryBox"

ShopCheckoutUI = ISCollapsableWindow:derive("ShopCheckoutUI")

function ShopCheckoutUI:initialise()
    ISCollapsableWindow.initialise(self)
    self.cartBanner = getTexture("media/textures/cart_banner.png")
    self.sellBanner = getTexture("media/textures/sell_banner.png")
    
    local btnWid = 120
    local btnHgt = 25
    local fontHgt = getTextManager():getFontHeight(UIFont.Small)
    local itemHgt = math.max(fontHgt + 4, 24)
    
    -- LEFT PANEL: CART
    self.cartList = ISScrollingListBox:new(10, 170, self.width/2 - 15, self.height - 220)
    self.cartList:initialise()
    self.cartList:instantiate()
    self.cartList.itemheight = itemHgt
    self.cartList.selected = 0
    self.cartList.joypadParent = self
    self.cartList.font = UIFont.Small
    self.cartList.doDrawItem = self.drawCartListItem
    self.cartList.drawBorder = true
    self:addChild(self.cartList)
    
    self.removeCartBtn = ISButton:new(10, self.height - btnHgt - 10, 80, btnHgt, "Remove", self, self.onRemoveCart)
    self.removeCartBtn:initialise()
    self:addChild(self.removeCartBtn)
      
    self.clearCartBtn = ISButton:new(95, self.height - btnHgt - 10, 80, btnHgt, "Clear", self, self.onClearCart)
    self.clearCartBtn:initialise()
    self:addChild(self.clearCartBtn)
      
    self.checkoutBtn = ISButton:new(180, self.height - btnHgt - 10, self.width/2 - 180 - 5, btnHgt, "CHECKOUT", self, self.onCheckout)
    self.checkoutBtn:initialise()
    self.checkoutBtn.backgroundColor = {r=0, g=0.5, b=0, a=1.0}
    self.checkoutBtn.textColor = {r=1, g=1, b=1, a=1.0}
    self:addChild(self.checkoutBtn)
    
    -- RIGHT PANEL: SELL
    self.sellCategoryCombo = ISComboBox:new(self.width/2 + 5, 145, (self.width/2 - 20)/2, 20, self, self.onSellCategoryChange)
    self.sellCategoryCombo:initialise()
    self:addChild(self.sellCategoryCombo)
    
    self.sellSearchEntry = ISTextEntryBox:new("", self.width/2 + 5 + (self.width/2 - 20)/2 + 5, 145, (self.width/2 - 20)/2, 20)
    self.sellSearchEntry:initialise()
    self.sellSearchEntry:instantiate()
    self:addChild(self.sellSearchEntry)
    
    self.sellList = ISScrollingListBox:new(self.width/2 + 5, 170, self.width/2 - 15, self.height - 220)
    self.sellList:initialise()
    self.sellList:instantiate()
    self.sellList.itemheight = itemHgt
    self.sellList.selected = 0
    self.sellList.joypadParent = self
    self.sellList.font = UIFont.Small
    self.sellList.doDrawItem = self.drawCatalogListItem
    self.sellList.drawBorder = true
    self:addChild(self.sellList)
    
    self.openSellUIBtn = ISButton:new(self.width/2 + 5, self.height - btnHgt - 10, self.width/2 - 15, btnHgt, "Scan Inventory to Sell", self, self.onOpenSellUI)
    self.openSellUIBtn:initialise()
    self.openSellUIBtn.backgroundColor = {r=0.2, g=0.2, b=0.8, a=1.0}
    self.openSellUIBtn.textColor = {r=1, g=1, b=1, a=1.0}
    self:addChild(self.openSellUIBtn)
    
    self:refresh()
end

function ShopCheckoutUI:drawCartListItem(y, item, alt)
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
    end
    local priceStr = "$" .. tostring(data.price * data.amount)
    local priceWid = getTextManager():MeasureStringX(self.font, priceStr)
    local itemName = tostring(data.amount) .. "x " .. (data.itemObj and data.itemObj:getDisplayName() or data.name)
    local maxTextWidth = self:getWidth() - priceWid - 70
    if getTextManager():MeasureStringX(self.font, itemName) > maxTextWidth then
        while string.len(itemName) > 0 and getTextManager():MeasureStringX(self.font, itemName .. "...") > maxTextWidth do
            itemName = string.sub(itemName, 1, string.len(itemName) - 1)
        end
        itemName = itemName .. "..."
    end
    if data.itemObj then
        self:drawText(itemName, 30, y + (item.height - self.fontHgt)/2, 1, 1, 1, a, self.font);
    else
        self:drawText(itemName, 30, y + (item.height - self.fontHgt)/2, 1, 0.3, 0.3, a, self.font);
    end
    self:drawText(priceStr, self:getWidth() - priceWid - 30, y + (item.height - self.fontHgt)/2, 0.2, 1, 0.2, a, self.font);

    return y + item.height;
end

function ShopCheckoutUI:drawCatalogListItem(y, item, alt)
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
    end
    local priceStr = "$" .. tostring(data.price)
    local priceWid = getTextManager():MeasureStringX(self.font, priceStr)
    local itemName = data.itemObj and data.itemObj:getDisplayName() or data.name
    local maxTextWidth = self:getWidth() - priceWid - 70
    if getTextManager():MeasureStringX(self.font, itemName) > maxTextWidth then
        while string.len(itemName) > 0 and getTextManager():MeasureStringX(self.font, itemName .. "...") > maxTextWidth do
            itemName = string.sub(itemName, 1, string.len(itemName) - 1)
        end
        itemName = itemName .. "..."
    end
    if data.itemObj then
        self:drawText(itemName, 30, y + (item.height - self.fontHgt)/2, 1, 1, 1, a, self.font);
    else
        self:drawText(itemName, 30, y + (item.height - self.fontHgt)/2, 1, 0.3, 0.3, a, self.font);
    end
    self:drawText(priceStr, self:getWidth() - priceWid - 30, y + (item.height - self.fontHgt)/2, 0.2, 1, 0.2, a, self.font);

    return y + item.height;
end

function ShopCheckoutUI:refresh()
    -- Cart List
    self.cartList:clear()
    self.cartTotal = 0
    ProjectShopee.Client.Cart = ProjectShopee.Client.Cart or {}
    
    for itemName, amount in pairs(ProjectShopee.Client.Cart) do
        local price = ProjectShopee.Config.Catalog.Buy[itemName]
        if price then
            local itemObj = getScriptManager():getItem(itemName)
            self.cartTotal = self.cartTotal + (price * amount)
            self.cartList:addItem(itemName, {name=itemName, amount=amount, price=price, itemObj=itemObj})
        else
            ProjectShopee.Client.Cart[itemName] = nil
        end
    end
    
    -- Sell List
    self.masterSellList = {}
    local sellCategories = { ["All Categories"] = true }
    for itemName, price in pairs(ProjectShopee.Config.Catalog.Sell) do
        local itemObj = getScriptManager():getItem(itemName)
        local cat = itemObj and itemObj:getDisplayCategory() or "Unknown"
        sellCategories[cat] = true
        table.insert(self.masterSellList, {name=itemName, price=price, itemObj=itemObj, category=cat})
    end
    self.masterSellList = self:sortList(self.masterSellList)
    
    local currentSellCat = "All Categories"
    if self.sellCategoryCombo.options[self.sellCategoryCombo.selected] then
        local opt = self.sellCategoryCombo.options[self.sellCategoryCombo.selected]
        currentSellCat = type(opt) == "table" and opt.text or opt
    end
    self.sellCategoryCombo:clear()
    
    self.sellCategoryCombo:addOption("All Categories")
    for cat, _ in pairs(sellCategories) do
        if cat ~= "All Categories" then self.sellCategoryCombo:addOption(cat) end
    end
    
    for i, option in ipairs(self.sellCategoryCombo.options) do
        local optText = type(option) == "table" and option.text or option
        if optText == currentSellCat then self.sellCategoryCombo.selected = i; break end
    end
    
    self:populateSellList()
end

function ShopCheckoutUI:populateSellList()
    self.sellList:clear()
    local selectedSellCat = "All Categories"
    if self.sellCategoryCombo.options[self.sellCategoryCombo.selected] then
        local opt = self.sellCategoryCombo.options[self.sellCategoryCombo.selected]
        selectedSellCat = type(opt) == "table" and opt.text or opt
    end
    local searchText = self.sellSearchEntry and self.sellSearchEntry:getText() or ""
    searchText = string.lower(searchText)
    
    for _, item in ipairs(self.masterSellList) do
        if selectedSellCat == "All Categories" or item.category == selectedSellCat then
            local dispName = item.itemObj and item.itemObj:getDisplayName() or item.name
            if searchText == "" or string.find(string.lower(dispName), searchText, 1, true) then
                self.sellList:addItem(item.name, item)
            end
        end
    end
end

function ShopCheckoutUI:onSellCategoryChange()
    self:populateSellList()
end

function ShopCheckoutUI:sortList(itemsList)
    local temp = {}
    for i=1, #itemsList do table.insert(temp, itemsList[i]) end
    table.sort(temp, function(a,b)
        local nameA = a.itemObj and a.itemObj:getDisplayName() or a.name
        local nameB = b.itemObj and b.itemObj:getDisplayName() or b.name
        return nameA < nameB
    end)
    return temp
end

function ShopCheckoutUI:onClearCart()
    ProjectShopee.Client.Cart = {}
    self:refresh()
end

function ShopCheckoutUI:onRemoveCart()
    local sel = self.cartList.items[self.cartList.selected]
    if not sel then return end
    
    local itemName = sel.item.name
    if ProjectShopee.Client.Cart[itemName] then
        ProjectShopee.Client.Cart[itemName] = ProjectShopee.Client.Cart[itemName] - 1
        if ProjectShopee.Client.Cart[itemName] <= 0 then
            ProjectShopee.Client.Cart[itemName] = nil
        end
        self:refresh()
    end
end

function ShopCheckoutUI:onCheckout()
    local player = getPlayer()
    
    local primary = player:getPrimaryHandItem()
    local secondary = player:getSecondaryHandItem()
    local hasBag = false
    
    if primary and primary:getFullType() == "Base.Plasticbag" then hasBag = true end
    if secondary and secondary:getFullType() == "Base.Plasticbag" then hasBag = true end
    
    if not hasBag then
        player:Say("You need to get a Plastic Bag equipped to checkout")
        return
    end

    local balance = ProjectShopee.Client.Balance or 0
    
    if self.cartTotal <= 0 then
        player:Say("My cart is empty.")
        return
    end
    
    if balance >= self.cartTotal then
        local cartPayload = {}
        for itemName, amount in pairs(ProjectShopee.Client.Cart) do
            local price = ProjectShopee.Config.Catalog.Buy[itemName]
            if price then
                table.insert(cartPayload, {item=itemName, amount=amount, price=price})
            end
        end
        
        sendClientCommand("ProjectShopee", ProjectShopee.Commands.CheckoutCart, {cart=cartPayload, pos=self.pos})
        
        ProjectShopee.Client.Cart = {}
        self:refresh()
    else
        player:Say("I don't have enough money in the bank. Total is $" .. tostring(self.cartTotal))
    end
end



function ShopCheckoutUI:onOpenSellUI()
    if not ShopSellUI then require("ShopSellUI") end
    if not ProjectShopeeSellUI_Instance then
        ProjectShopeeSellUI_Instance = ShopSellUI:new(50, 50, 400, 450, self.player, self.pos)
        ProjectShopeeSellUI_Instance:initialise()
        ProjectShopeeSellUI_Instance:addToUIManager()
    else
        ProjectShopeeSellUI_Instance.pos = self.pos
        ProjectShopeeSellUI_Instance:setVisible(true)
        ProjectShopeeSellUI_Instance:addToUIManager()
        ProjectShopeeSellUI_Instance:bringToTop()
        ProjectShopeeSellUI_Instance:populateList()
    end
end

function ShopCheckoutUI:prerender()
    ISCollapsableWindow.prerender(self)
    
    if self.cartBanner then
        self:drawTextureScaled(self.cartBanner, 0, 20, 300, 100, 1, 1, 1, 1)
    end
    if self.sellBanner then
        self:drawTextureScaled(self.sellBanner, 300, 20, 300, 100, 1, 1, 1, 1)
    end
    
    self:drawText("Checkout Cart", 10, 130, 1, 1, 1, 1, UIFont.Small)
    self:drawText("Sell to Kiwe", self.width/2 + 5, 130, 1, 1, 1, 1, UIFont.Small)
    
    local balance = ProjectShopee.Client.Balance or 0
    self:drawText("Balance: $" .. tostring(balance), 10, 150, 0.2, 0.9, 0.2, 1, UIFont.Small)
    
    local cartTotal = self.cartTotal or 0
    local totalText = "Total: $" .. tostring(cartTotal)
    local tw = getTextManager():MeasureStringX(UIFont.Small, totalText)
    self:drawText(totalText, self.width/2 - 5 - tw, 150, 0.9, 0.2, 0.2, 1, UIFont.Small)
end

function ShopCheckoutUI:update()
    ISCollapsableWindow.update(self)
    
    if self.sellSearchEntry then
        local currentSearch = self.sellSearchEntry:getText()
        if self.lastSellSearchText ~= currentSearch then
            self.lastSellSearchText = currentSearch
            self:populateSellList()
        end
    end
    

    
    if not self:getIsVisible() then return end
    
    local parts = {}
    for match in string.gmatch(self.pos, "[^,]+") do table.insert(parts, tonumber(match)) end
    if #parts == 3 then
        local dist = math.sqrt((self.player:getX() - parts[1])^2 + (self.player:getY() - parts[2])^2)
        if dist > 2.5 or self.player:getZ() ~= parts[3] then
            self:close()
        end
    end
end

function ShopCheckoutUI:close()
    ISCollapsableWindow.close(self)
    if ProjectShopeeSellUI_Instance and ProjectShopeeSellUI_Instance:getIsVisible() then
        ProjectShopeeSellUI_Instance:close()
    end
    sendClientCommand("ProjectShopee", ProjectShopee.Commands.CloseCheckout, { pos = self.pos })
end

function ShopCheckoutUI:new(x, y, width, height, player, pos)
    local o = {}
    x = getCore():getScreenWidth() - 600 - 50
    y = getCore():getScreenHeight() / 2 - (height / 2)
    o = ISCollapsableWindow:new(x, y, 600, 500)
    setmetatable(o, self)
    self.__index = self
    o.title = "Checkout Counter"
    o.resizable = false
    o.pin = true
    o.isCollapsed = false
    o.collapseCounter = 0
    o.clearStentil = false
    o.moveWithMouse = true
    o.player = player
    o.pos = pos
    return o
end
