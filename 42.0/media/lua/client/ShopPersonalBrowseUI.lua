require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISScrollingListBox"
require "ISUI/ISTextEntryBox"

ShopPersonalBrowseUI = ISCollapsableWindow:derive("ShopPersonalBrowseUI")

function ShopPersonalBrowseUI:initialise()
    ISCollapsableWindow.initialise(self)
    self:create()
end

function ShopPersonalBrowseUI:create()
    local fontHgt = getTextManager():getFontHeight(UIFont.Small)
    
    self.list = ISScrollingListBox:new(10, 25, self.width - 20, self.height - 100)
    self.list:initialise()
    self.list:instantiate()
    self.list.itemheight = math.max(fontHgt + 10, 32)
    self.list.selected = 0
    self.list.font = UIFont.Small
    self.list.doDrawItem = self.drawListItem
    self.list.drawBorder = true
    self:addChild(self.list)
    
    -- Bottom Controls
    local ctrlY = self.height - 70
    
    self.amountEntry = ISTextEntryBox:new("1", 10, ctrlY, 80, 25)
    self.amountEntry:initialise()
    self.amountEntry:instantiate()
    self.amountEntry:setOnlyNumbers(true)
    self.amountEntry:setMaxTextLength(6)
    self:addChild(self.amountEntry)
    
    self.buyBtn = ISButton:new(100, ctrlY, self.width - 110, 25, "Buy Item", self, self.onBuy)
    self.buyBtn:initialise()
    self:addChild(self.buyBtn)
    
    self:populateList()
end

function ShopPersonalBrowseUI:drawListItem(y, item, alt)
    local a = 0.9;
    if self.selected == item.index then
        self:drawRect(0, (y), self:getWidth(), item.height-1, 0.3, 0.7, 0.35, 0.15);
    end
    self:drawRectBorder(0, (y), self:getWidth(), item.height, a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

    local data = item.item;
    
    local tex = ScriptManager.instance:getItem(data.itemFullType)
    if tex and tex:getIcon() then
        local icon = getTexture("Item_" .. tex:getIcon())
        if icon then
            self:drawTextureScaledAspect(icon, 10, y + (item.height - 32)/2, 32, 32, 1, 1, 1, 1)
        end
    end
    
    local name = tex and tex:getDisplayName() or data.itemFullType
    self:drawText(name, 50, y + (item.height - self.fontHgt)/2, 1, 1, 1, a, self.font);
    
    local rightText = "Stock: " .. tostring(data.count) .. "  |  Price: $" .. tostring(data.price)
    local rightWid = getTextManager():MeasureStringX(self.font, rightText)
    self:drawText(rightText, self:getWidth() - rightWid - 10, y + (item.height - self.fontHgt)/2, 1, 1, 1, a, self.font);

    return y + item.height;
end

function ShopPersonalBrowseUI:populateList()
    self.list:clear()
    local shopData = ProjectShopee.Config.PersonalShops and ProjectShopee.Config.PersonalShops[self.pos]
    if shopData and shopData.Stock then
        for itemType, data in pairs(shopData.Stock) do
            if data.Count > 0 then
                self.list:addItem(itemType, {
                    itemFullType = itemType,
                    count = data.Count,
                    price = data.Price
                })
            end
        end
    end
end

function ShopPersonalBrowseUI:onBuy()
    local selectedItem = self.list.items[self.list.selected]
    if not selectedItem or not selectedItem.item then return end
    
    local amount = tonumber(self.amountEntry:getText())
    if not amount or amount <= 0 then return end
    
    local limit = 10
    if ProjectShopee.Config.Catalog.Limits and ProjectShopee.Config.Catalog.Limits[selectedItem.item.itemFullType] then
        limit = ProjectShopee.Config.Catalog.Limits[selectedItem.item.itemFullType]
    end
    
    if amount > limit then
        self.player:Say("I can only buy up to " .. tostring(limit) .. " at a time.")
        return
    end
    
    if amount > selectedItem.item.count then
        self.player:Say("They don't have that many in stock.")
        return
    end
    
    local totalCost = amount * selectedItem.item.price
    if ProjectShopee.Client.Balance == nil or ProjectShopee.Client.Balance < totalCost then
        self.player:Say("I don't have enough digital balance ($" .. tostring(totalCost) .. ").")
        return
    end
    
    sendClientCommand("ProjectShopee", ProjectShopee.Commands.BuyFromPersonalShop, {
        pos = self.pos,
        item = selectedItem.item.itemFullType,
        amount = amount
    })
    
    self.player:Say("Buying item...")
    -- Server will sync config which updates UI if we keep it open, or we can close it. We will keep it open.
end

function ShopPersonalBrowseUI:render()
    ISCollapsableWindow.render(self)
    self:drawText("Quantity:", 10, self.height - 90, 1, 1, 1, 1, UIFont.Small)
    
    local balance = ProjectShopee.Client.Balance or 0
    local balanceText = "Digital Bank Balance: $" .. tostring(balance)
    local textWid = getTextManager():MeasureStringX(UIFont.Small, balanceText)
    self:drawText(balanceText, self.width - textWid - 10, self.height - 90, 0, 1, 0, 1, UIFont.Small)
end

function ShopPersonalBrowseUI:update()
    ISCollapsableWindow.update(self)
    
    if self.amountEntry then
        local text = self.amountEntry:getText()
        local scrubbed = text:gsub("[^0-9]", "")

        if text ~= scrubbed then self.amountEntry:setText(scrubbed) end
    end
    
    local parts = {}
    for match in string.gmatch(self.pos, "[^,]+") do table.insert(parts, tonumber(match)) end
    if #parts == 3 then
        local dist = math.sqrt((self.player:getX() - parts[1])^2 + (self.player:getY() - parts[2])^2)
        if dist > 2.5 or self.player:getZ() ~= parts[3] then
            self:close()
        end
    end
    
    local currentShopData = ProjectShopee.Config.PersonalShops and ProjectShopee.Config.PersonalShops[self.pos]
    if currentShopData and not currentShopData.IsOpen then
        self:close()
    end
end

function ShopPersonalBrowseUI:close()
    sendClientCommand("ProjectShopee", ProjectShopee.Commands.ClosePersonalShop, {pos = self.pos})
    self:removeFromUIManager()
end

function ShopPersonalBrowseUI:new(x, y, width, height, player, pos)
    local o = {}
    x = getCore():getScreenWidth() - width - 50
    y = getCore():getScreenHeight() / 2 - (height / 2)
    o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    local shopData = ProjectShopee.Config.PersonalShops and ProjectShopee.Config.PersonalShops[pos]
    local ownerName = shopData and shopData.Owner or "Unknown"
    local shopName = (shopData and shopData.Name and shopData.Name ~= "") and shopData.Name or (ownerName .. "'s Personal Shop")
    
    o.title = shopName
    o.resizable = false
    o.pin = true
    o.isCollapsed = false
    o.collapseCounter = 0
    o.clearStentil = false
    o.moveWithMouse = true
    o.playerNum = player:getPlayerNum()
    o.player = player
    o.pos = pos
    o.moveWithMouse = true
    return o
end

local function OnServerCommand(module, command, args)
    if module ~= "ProjectShopee" then return end
    if command == ProjectShopee.Commands.SyncConfig then
        if ShopPersonalBrowseUI.instance then
            ShopPersonalBrowseUI.instance:populateList()
        end
    end
end
Events.OnServerCommand.Add(OnServerCommand)

local oldNew = ShopPersonalBrowseUI.new
function ShopPersonalBrowseUI:new(x, y, width, height, player, pos)
    local o = oldNew(self, x, y, width, height, player, pos)
    ShopPersonalBrowseUI.instance = o
    return o
end

local oldClose = ShopPersonalBrowseUI.close
function ShopPersonalBrowseUI:close()
    oldClose(self)
    ShopPersonalBrowseUI.instance = nil
end

