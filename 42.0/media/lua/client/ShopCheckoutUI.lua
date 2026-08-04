if isServer() then return end
require "ISUI/ISCollapsableWindow"
require "ISUI/ISScrollingListBox"
require "ISUI/ISButton"
require "ISUI/ISComboBox"

ShopCheckoutUI = ISCollapsableWindow:derive("ShopCheckoutUI")

function ShopCheckoutUI:initialise()
    ISCollapsableWindow.initialise(self)
    
    local btnWid = 120
    local btnHgt = 25
    local fontHgt = getTextManager():getFontHeight(UIFont.Small)
    local itemHgt = math.max(fontHgt + 4, 24)
    
    -- LEFT PANEL: CART
    self.cartList = ISScrollingListBox:new(10, 45, self.width/2 - 15, self.height - 120)
    self.cartList:initialise()
    self.cartList:instantiate()
    self.cartList.itemheight = itemHgt
    self.cartList.selected = 0
    self.cartList.joypadParent = self
    self.cartList.font = UIFont.Small
    self.cartList.doDrawItem = self.drawCartListItem
    self.cartList.drawBorder = true
    self:addChild(self.cartList)
    
    self.clearCartBtn = ISButton:new(10, self.height - btnHgt - 10, btnWid, btnHgt, "Clear Cart", self, self.onClearCart)
    self.clearCartBtn:initialise()
    self:addChild(self.clearCartBtn)
    
    self.checkoutBtn = ISButton:new(10 + btnWid + 5, self.height - btnHgt - 10, self.width/2 - btnWid - 20, btnHgt, "CHECKOUT", self, self.onCheckout)
    self.checkoutBtn:initialise()
    self.checkoutBtn.backgroundColor = {r=0, g=0.5, b=0, a=1.0}
    self.checkoutBtn.textColor = {r=1, g=1, b=1, a=1.0}
    self:addChild(self.checkoutBtn)
    
    -- RIGHT PANEL: SELL
    self.sellCategoryCombo = ISComboBox:new(self.width/2 + 5, 45, (self.width/2 - 20)/2, 20, self, self.onSellCategoryChange)
    self.sellCategoryCombo:initialise()
    self:addChild(self.sellCategoryCombo)
    
    self.sellSearchEntry = ISTextEntryBox:new("", self.width/2 + 5 + (self.width/2 - 20)/2 + 5, 45, (self.width/2 - 20)/2, 20)
    self.sellSearchEntry:initialise()
    self.sellSearchEntry:instantiate()
    self:addChild(self.sellSearchEntry)
    
    self.sellList = ISScrollingListBox:new(self.width/2 + 5, 70, self.width/2 - 15, self.height - 120)
    self.sellList:initialise()
    self.sellList:instantiate()
    self.sellList.itemheight = itemHgt
    self.sellList.selected = 0
    self.sellList.joypadParent = self
    self.sellList.font = UIFont.Small
    self.sellList.doDrawItem = self.drawCatalogListItem
    self.sellList.drawBorder = true
    self:addChild(self.sellList)
    
    self.sellBtn = ISButton:new(self.width/2 + 5, self.height - btnHgt - 10, 80, btnHgt, "Sell", self, self.onSell)
    self.sellBtn:initialise()
    self:addChild(self.sellBtn)
    
    self.sellAmountEntry = ISTextEntryBox:new("1", self.width/2 + 5 + 85, self.height - btnHgt - 10, 40, btnHgt)
    self.sellAmountEntry:initialise()
    self.sellAmountEntry:instantiate()
    self.sellAmountEntry:setOnlyNumbers(true)
    self.sellAmountEntry:setMaxTextLength(6)
    self:addChild(self.sellAmountEntry)
    
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
        self:drawText(tostring(data.amount) .. "x " .. data.itemObj:getDisplayName(), 30, y + (item.height - self.fontHgt)/2, 1, 1, 1, a, self.font);
    else
        self:drawText(tostring(data.amount) .. "x " .. data.name, 30, y + (item.height - self.fontHgt)/2, 1, 0.3, 0.3, a, self.font);
    end
    
    local priceStr = "$" .. tostring(data.price * data.amount)
    local priceWid = getTextManager():MeasureStringX(self.font, priceStr)
    self:drawText(priceStr, self:getWidth() - priceWid - 10, y + (item.height - self.fontHgt)/2, 0.2, 1, 0.2, a, self.font);

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
        self:drawText(data.itemObj:getDisplayName(), 30, y + (item.height - self.fontHgt)/2, 1, 1, 1, a, self.font);
    else
        self:drawText(data.name, 30, y + (item.height - self.fontHgt)/2, 1, 0.3, 0.3, a, self.font);
    end
    
    local priceStr = "$" .. tostring(data.price)
    local priceWid = getTextManager():MeasureStringX(self.font, priceStr)
    self:drawText(priceStr, self:getWidth() - priceWid - 10, y + (item.height - self.fontHgt)/2, 0.2, 1, 0.2, a, self.font);

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
            -- Item no longer in catalog
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
    
    print("Project Shopee Debug: populating Sell List. Category=" .. tostring(selectedSellCat) .. " Search=" .. tostring(searchText))
    
    for _, item in ipairs(self.masterSellList) do
        print("Project Shopee Debug: Checking item: " .. tostring(item.name) .. " Cat: " .. tostring(item.category))
        if selectedSellCat == "All Categories" or item.category == selectedSellCat then
            local dispName = item.itemObj and item.itemObj:getDisplayName() or item.name
            if searchText == "" or string.find(string.lower(dispName), searchText, 1, true) then
                self.sellList:addItem(item.name, item)
                print("Project Shopee Debug: Added item: " .. tostring(item.name))
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

function ShopCheckoutUI:onCheckout()
    local player = getPlayer()
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
        
        -- Clear cart after successful checkout request
        ProjectShopee.Client.Cart = {}
        self:refresh()
    else
        player:Say("I don't have enough money in the bank. Total is $" .. tostring(self.cartTotal))
    end
end

function ShopCheckoutUI:onSell()
    if self.sellCooldown and self.sellCooldown > 0 then return end
    
    local item = self.sellList.items[self.sellList.selected]
    if not item then return end
    
    local player = getPlayer()
    local inv = player:getInventory()
    local count = inv:getCountType(item.item.name)
    
    local amount = tonumber(self.sellAmountEntry:getText())
    if not amount or amount < 1 then
        amount = 1
        self.sellAmountEntry:setText("1")
    end
    
    if count >= amount then
        self.sellCooldown = 30
        self.sellBtn:setEnable(false)
        self.sellBtn.title = "Wait..."
        sendClientCommand("ProjectShopee", ProjectShopee.Commands.SellItem, {item=item.item.name, amount=amount, pos=self.pos})
    else
        player:Say("I don't have enough of this item to sell.")
    end
end

function ShopCheckoutUI:render()
    ISCollapsableWindow.render(self)
    
    local balance = ProjectShopee.Client.Balance or 0
    local titleText = "Digital Bank Balance: $" .. tostring(balance)
    self:drawTextCentre(titleText, self.width/2, 12, 0, 1, 0, 1, UIFont.Medium)
    
    local totalText = "Cart Total: $" .. tostring(self.cartTotal or 0)
    self:drawText(totalText, 10, 30, 0, 1, 0, 1, UIFont.Small)
    
    self:drawText("Sell Items", self.width/2 + 5, 30, 1, 1, 1, 1, UIFont.Small)
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
    
    if self.sellAmountEntry then
        local text = self.sellAmountEntry:getText()
        local scrubbed = text:gsub("[^0-9]", "")
        if scrubbed == "" or scrubbed == "0" then scrubbed = "1" end
        if text ~= scrubbed then self.sellAmountEntry:setText(scrubbed) end
    end
    
    if self.sellCooldown and self.sellCooldown > 0 then
        self.sellCooldown = self.sellCooldown - 1
        if self.sellCooldown <= 0 then
            self.sellBtn:setEnable(true)
            self.sellBtn.title = "SELL"
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
    sendClientCommand("ProjectShopee", ProjectShopee.Commands.CloseCheckout, { pos = self.pos })
end

function ShopCheckoutUI:new(x, y, width, height, player, pos)
    local o = {}
    x = getCore():getScreenWidth() - width - 50
    y = getCore():getScreenHeight() / 2 - (height / 2)
    o = ISCollapsableWindow:new(x, y, 600, 500)
    setmetatable(o, self)
    self.__index = self
    o.title = "Checkout Counter Test"
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

