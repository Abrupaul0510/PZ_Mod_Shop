if isServer() then return end
require "ISUI/ISCollapsableWindow"
require "ISUI/ISScrollingListBox"
require "ISUI/ISButton"
require "ISUI/ISComboBox"

ShopUI = ISCollapsableWindow:derive("ShopUI")

function ShopUI:initialise()
    ISCollapsableWindow.initialise(self)
    self.globalBanner = getTexture("media/textures/global_banner.png")
    
    local btnWid = 100
    local btnHgt = 25
    local fontHgt = getTextManager():getFontHeight(UIFont.Small)
    local itemHgt = math.max(fontHgt + 4, 24)
    
    self.buyCategoryCombo = ISComboBox:new(10, 145, self.width/2 - 15, 20, self, self.onBuyCategoryChange)
    self.buyCategoryCombo:initialise()
    self:addChild(self.buyCategoryCombo)

    self.buyList = ISScrollingListBox:new(10, 170, self.width/2 - 15, self.height - 220)
    self.buyList:initialise()
    self.buyList:instantiate()
    self.buyList.itemheight = itemHgt
    self.buyList.selected = 0
    self.buyList.joypadParent = self
    self.buyList.font = UIFont.Small
    self.buyList.doDrawItem = self.drawCatalogListItem
    self.buyList.drawBorder = true
    self:addChild(self.buyList)
    
    self.cartList = ISScrollingListBox:new(self.width/2 + 5, 170, self.width/2 - 15, self.height - 220)
    self.cartList:initialise()
    self.cartList:instantiate()
    self.cartList.itemheight = itemHgt
    self.cartList.selected = 0
    self.cartList.joypadParent = self
    self.cartList.font = UIFont.Small
    self.cartList.doDrawItem = self.drawCartListItem
    self.cartList.drawBorder = true
    self:addChild(self.cartList)
    
    self.addBtn = ISButton:new(10, self.height - btnHgt - 10, btnWid + 20, btnHgt, "Add to Cart", self, self.onAddToCart)
    self.addBtn:initialise()
    self.addBtn.backgroundColor = {r=0, g=0.5, b=0, a=1.0}
    self.addBtn.textColor = {r=1, g=1, b=1, a=1.0}
    self:addChild(self.addBtn)
    
    self.buyAmountEntry = ISTextEntryBox:new("1", 10 + btnWid + 25, self.height - btnHgt - 10, 40, btnHgt)
    self.buyAmountEntry:initialise()
    self.buyAmountEntry:instantiate()
    self.buyAmountEntry:setOnlyNumbers(true)
    self.buyAmountEntry:setMaxTextLength(6)
    self:addChild(self.buyAmountEntry)
    
    self.removeBtn = ISButton:new(self.width/2 + 5, self.height - btnHgt - 10, btnWid, btnHgt, "Remove", self, self.onRemoveFromCart)
    self.removeBtn:initialise()
    self:addChild(self.removeBtn)
    
    self.removeAmountEntry = ISTextEntryBox:new("1", self.width/2 + 5 + btnWid + 5, self.height - btnHgt - 10, 40, btnHgt)
    self.removeAmountEntry:initialise()
    self.removeAmountEntry:instantiate()
    self.removeAmountEntry:setOnlyNumbers(true)
    self.removeAmountEntry:setMaxTextLength(6)
    self:addChild(self.removeAmountEntry)
    
    self.clearCartBtn = ISButton:new(self.width/2 + 5 + btnWid + 5 + 45, self.height - btnHgt - 10, 80, btnHgt, "Clear Cart", self, self.onClearCart)
    self.clearCartBtn:initialise()
    self:addChild(self.clearCartBtn)
    
    self:refresh()
end

function ShopUI:drawCartListItem(y, item, alt)
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

function ShopUI:drawCatalogListItem(y, item, alt)
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

function ShopUI:refresh()
    self.masterBuyList = {}
    
    local catalog = ProjectShopee.Config.Catalogs and ProjectShopee.Config.Catalogs[self.storeID] or ProjectShopee.Config.Catalog
    local buyCategories = { ["All Categories"] = true }
    for itemName, price in pairs(catalog.Buy or {}) do
        if ProjectShopee.Config.Shops[self.pos] and ProjectShopee.Config.Shops[self.pos].Items and ProjectShopee.Config.Shops[self.pos].Items[itemName] then
            local itemObj = getScriptManager():getItem(itemName)
            local cat = itemObj and itemObj:getDisplayCategory() or "Unknown"
            buyCategories[cat] = true
            table.insert(self.masterBuyList, {name=itemName, price=price, itemObj=itemObj, category=cat})
        end
    end
    self.masterBuyList = self:sortList(self.masterBuyList)
    
    local currentBuyCat = self.buyCategoryCombo.options[self.buyCategoryCombo.selected] or "All Categories"
    self.buyCategoryCombo:clear()
    
    self.buyCategoryCombo:addOption("All Categories")
    for cat, _ in pairs(buyCategories) do
        if cat ~= "All Categories" then self.buyCategoryCombo:addOption(cat) end
    end
    
    for i, option in ipairs(self.buyCategoryCombo.options) do
        if option == currentBuyCat then self.buyCategoryCombo.selected = i; break end
    end
    
    self:populateLists()
    self:populateCartList()
end

function ShopUI:populateCartList()
    self.cartList:clear()
    ProjectShopee.Client.Carts = ProjectShopee.Client.Carts or { Store1={}, Store2={} }
    local cartData = ProjectShopee.Client.Carts[self.storeID] or {}
    ProjectShopee.Client.Carts[self.storeID] = cartData
    local catalog = ProjectShopee.Config.Catalogs and ProjectShopee.Config.Catalogs[self.storeID] or ProjectShopee.Config.Catalog
    
    for itemName, amount in pairs(cartData) do
        local price = catalog.Buy[itemName]
        if price then
            local itemObj = getScriptManager():getItem(itemName)
            self.cartList:addItem(itemName, {name=itemName, amount=amount, price=price, itemObj=itemObj})
        else
            -- Item no longer in catalog
            cartData[itemName] = nil
        end
    end
end

function ShopUI:populateLists()
    self.buyList:clear()
    
    local selectedBuyCat = self.buyCategoryCombo.options[self.buyCategoryCombo.selected]
    for _, item in ipairs(self.masterBuyList) do
        if selectedBuyCat == "All Categories" or item.category == selectedBuyCat then
            self.buyList:addItem(item.name, item)
        end
    end
end

function ShopUI:onBuyCategoryChange()
    self:populateLists()
end

function ShopUI:sortList(itemsList)
    local temp = {}
    for i=1, #itemsList do table.insert(temp, itemsList[i]) end
    table.sort(temp, function(a,b)
        local nameA = a.itemObj and a.itemObj:getDisplayName() or a.name
        local nameB = b.itemObj and b.itemObj:getDisplayName() or b.name
        return nameA < nameB
    end)
    return temp
end

function ShopUI:onAddToCart()
    local player = getPlayer()
    
    local primary = player:getPrimaryHandItem()
    local secondary = player:getSecondaryHandItem()
    local hasBag = false
    
    if primary and string.find(string.lower(primary:getName()), "plastic bag") then hasBag = true end
    if secondary and string.find(string.lower(secondary:getName()), "plastic bag") then hasBag = true end
    
    if not hasBag then
        player:Say("You need to get a Plastic Bag equipped")
        return
    end

    local item = self.buyList.items[self.buyList.selected]
    if not item then return end
    
    local catalog = ProjectShopee.Config.Catalogs and ProjectShopee.Config.Catalogs[self.storeID] or ProjectShopee.Config.Catalog
    local itemName = item.item.name
    local price = catalog.Buy[itemName]
    if not price then return end
    local amount = tonumber(self.buyAmountEntry:getText()) or 1
    if amount < 1 then amount = 1 end
    
    local limit = 50
    if catalog.Limits and catalog.Limits[itemName] then
        limit = catalog.Limits[itemName]
    end
    
    ProjectShopee.Client.Carts = ProjectShopee.Client.Carts or { Store1={}, Store2={} }
    local cartData = ProjectShopee.Client.Carts[self.storeID] or {}
    ProjectShopee.Client.Carts[self.storeID] = cartData
    
    local maxCartSize = 20
    local currentTotal = 0
    for _, qty in pairs(cartData) do
        currentTotal = currentTotal + qty
    end
    
    if currentTotal + amount > maxCartSize then
        player:Say("My cart is full! I can't hold more than " .. maxCartSize .. " items.")
        return
    end
    
    local currentInCart = cartData[itemName] or 0
    
    if currentInCart + amount > limit then
        player:Say("Max limit for this item is " .. tostring(limit))
        return
    end
    
    cartData[itemName] = currentInCart + amount
    self:populateCartList()
    player:Say("Added " .. tostring(amount) .. "x " .. (item.item.itemObj and item.item.itemObj:getDisplayName() or itemName) .. " to Cart!")
end

function ShopUI:onRemoveFromCart()
    local item = self.cartList.items[self.cartList.selected]
    if not item then return end
    
    local itemName = item.item.name
    local amountToRemove = tonumber(self.removeAmountEntry:getText()) or 1
    if amountToRemove < 1 then amountToRemove = 1 end
    
    local cartData = ProjectShopee.Client.Carts and ProjectShopee.Client.Carts[self.storeID] or {}
    local currentInCart = cartData[itemName] or 0
    
    if currentInCart <= amountToRemove then
        cartData[itemName] = nil
        getPlayer():Say("Removed all " .. (item.item.itemObj and item.item.itemObj:getDisplayName() or itemName) .. " from Cart.")
    else
        cartData[itemName] = currentInCart - amountToRemove
        getPlayer():Say("Removed " .. tostring(amountToRemove) .. "x " .. (item.item.itemObj and item.item.itemObj:getDisplayName() or itemName) .. " from Cart.")
    end
    self:populateCartList()
end

function ShopUI:onClearCart()
    if ProjectShopee.Client.Carts then
        ProjectShopee.Client.Carts[self.storeID] = {}
    end
    self:populateCartList()
    getPlayer():Say("Cart cleared.")
end

function ShopUI:prerender()
    ISCollapsableWindow.prerender(self)
    

    
    local shopName = "Shop Catalog"
    if ProjectShopee.Config.Shops and ProjectShopee.Config.Shops[self.pos] and ProjectShopee.Config.Shops[self.pos].Name then
        shopName = ProjectShopee.Config.Shops[self.pos].Name
    end
    
    if self.globalBanner then
        self:drawTextureScaled(self.globalBanner, 0, 20, 600, 100, 1, 1, 1, 1)
    end
    
    self:drawText(shopName, 10, 130, 1, 1, 1, 1, UIFont.Small)
    self:drawText("Your Cart", self.width/2 + 5, 130, 1, 1, 1, 1, UIFont.Small)
    
    local balance = ProjectShopee.Client.Balance or 0
    self:drawText("Balance: $" .. tostring(balance), self.width/2 + 5, 150, 0.2, 0.9, 0.2, 1, UIFont.Small)
end

function ShopUI:render()
    ISCollapsableWindow.render(self)
    

    
    local shopName = "Shop Catalog"
    if ProjectShopee.Config.Shops and ProjectShopee.Config.Shops[self.pos] and ProjectShopee.Config.Shops[self.pos].Name then
        shopName = ProjectShopee.Config.Shops[self.pos].Name
    end
    
    if self.globalBanner then
        self:drawTextureScaled(self.globalBanner, 0, 20, 600, 100, 1, 1, 1, 1)
    end
    
    self:drawText(shopName, 10, 130, 1, 1, 1, 1, UIFont.Small)
    self:drawText("Your Cart", self.width/2 + 5, 130, 1, 1, 1, 1, UIFont.Small)
    
    local balance = ProjectShopee.Client.Balance or 0
    self:drawText("Balance: $" .. tostring(balance), self.width/2 + 5, 150, 0.2, 0.9, 0.2, 1, UIFont.Small)
end

function ShopUI:update()
    ISCollapsableWindow.update(self)
    if not self:getIsVisible() then return end
    
    if self.buyAmountEntry then
        local text = self.buyAmountEntry:getText()
        local scrubbed = text:gsub("[^0-9]", "")

        if text ~= scrubbed then self.buyAmountEntry:setText(scrubbed) end
    end
    if self.removeAmountEntry then
        local text = self.removeAmountEntry:getText()
        local scrubbed = text:gsub("[^0-9]", "")

        if text ~= scrubbed then self.removeAmountEntry:setText(scrubbed) end
    end
    
    local parts = {}
    for match in string.gmatch(self.pos, "[^,]+") do table.insert(parts, tonumber(match)) end
    if #parts == 3 then
        local dist = math.sqrt((self.player:getX() - parts[1])^2 + (self.player:getY() - parts[2])^2)
        if dist > 2.5 or self.player:getZ() ~= parts[3] then
            self:close()
        end
    end
end

function ShopUI:new(x, y, width, height, player, pos, storeID)
    local o = {}
    x = getCore():getScreenWidth() - width - 50
    y = getCore():getScreenHeight() / 2 - (height / 2)
    o = ISCollapsableWindow:new(x, y, 600, 500)
    setmetatable(o, self)
    self.__index = self
    o.storeID = storeID or "Store1"
    o.title = "Kiwi Store (" .. o.storeID .. ")"
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

