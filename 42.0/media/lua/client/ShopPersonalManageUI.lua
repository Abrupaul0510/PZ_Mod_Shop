require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISScrollingListBox"
require "ISUI/ISTextEntryBox"
require "ISUI/ISModalDialog"

ShopPersonalManageUI = ISCollapsableWindow:derive("ShopPersonalManageUI")

function ShopPersonalManageUI:initialise()
    ISCollapsableWindow.initialise(self)
    self:create()
end

function ShopPersonalManageUI:create()
    local fontHgt = getTextManager():getFontHeight(UIFont.Small)
    
    self.collectBtn = ISButton:new(10, 25, 180, 25, "Collect Earnings", self, self.onCollect)
    self.collectBtn:initialise()
    self:addChild(self.collectBtn)
    
    self.renameBtn = ISButton:new(200, 25, 100, 25, "Rename Shop", self, self.onRename)
    self.renameBtn:initialise()
    self:addChild(self.renameBtn)
    
    self.addBtn = ISButton:new(self.width - 160, 25, 150, 25, "List New Item", self, self.onAddItem)
    self.addBtn:initialise()
    self:addChild(self.addBtn)
    
    self.list = ISScrollingListBox:new(10, 60, self.width - 20, self.height - 110)
    self.list:initialise()
    self.list:instantiate()
    self.list.itemheight = math.max(fontHgt + 10, 32)
    self.list.selected = 0
    self.list.font = UIFont.Small
    self.list.doDrawItem = self.drawListItem
    self.list.drawBorder = true
    self:addChild(self.list)
    
    self.amountEntry = ISTextEntryBox:new("1", 10, self.height - 40, 100, 25)
    self.amountEntry:initialise()
    self.amountEntry:instantiate()
    self.amountEntry:setOnlyNumbers(true)
    self.amountEntry:setMaxTextLength(6)
    self:addChild(self.amountEntry)
    
    self.removeBtn = ISButton:new(120, self.height - 40, 150, 25, "Take Back Item", self, self.onRemoveItem)
    self.removeBtn:initialise()
    self:addChild(self.removeBtn)
    
    self.logsBtn = ISButton:new(280, self.height - 40, 100, 25, "View Logs", self, self.onViewLogs)
    self.logsBtn:initialise()
    self:addChild(self.logsBtn)
    
    self.list.onMouseUp = function(list, x, y)
        local selectedItem = list.items[list.selected]
        if selectedItem and selectedItem.item then
            self.amountEntry:setText("1")
        end
    end
    
    self:populateList()
end

function ShopPersonalManageUI:drawListItem(y, item, alt)
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

function ShopPersonalManageUI:populateList()
    self.list:clear()
    local shopData = ProjectShopee.Config.PersonalShops and ProjectShopee.Config.PersonalShops[self.pos]
    if shopData then
        self.collectBtn:setTitle("Collect Earnings: $" .. tostring(shopData.Earnings or 0))
        if shopData.Stock then
            for itemType, data in pairs(shopData.Stock) do
                self.list:addItem(itemType, {
                    itemFullType = itemType,
                    count = data.Count,
                    price = data.Price
                })
            end
        end
    end
end

function ShopPersonalManageUI:onCollect()
    sendClientCommand("ProjectShopee", ProjectShopee.Commands.CollectPSEarnings, {pos = self.pos})
end

function ShopPersonalManageUI:onRename()
    local shopData = ProjectShopee.Config.PersonalShops and ProjectShopee.Config.PersonalShops[self.pos]
    local currentName = (shopData and shopData.Name and shopData.Name ~= "") and shopData.Name or (self.player:getUsername() .. "'s Personal Shop")
    
    local modal = ISTextBox:new(0, 0, 280, 180, "Enter new shop name:", currentName, self, function(target, button, playerObj)
        if button.internal == "OK" then
            local text = button.parent.entry:getText()
            if text and text ~= "" then
                sendClientCommand("ProjectShopee", ProjectShopee.Commands.RenamePersonalShop, {pos = target.pos, name = text})
            end
        end
    end, self.playerNum)
    
    modal:initialise()
    modal:addToUIManager()
end

function ShopPersonalManageUI:onRemoveItem()
    if self.actionCooldown and self.actionCooldown > 0 then return end
    self.actionCooldown = 30
    self.removeBtn:setEnable(false)
    self.removeBtn.title = "Wait..."
    local selectedItem = self.list.items[self.list.selected]
    if not selectedItem or not selectedItem.item then return end
    
    local amount = tonumber(self.amountEntry:getText())
    if not amount or amount < 1 then
        amount = 1
        self.amountEntry:setText("1")
    end
    
    if amount > selectedItem.item.count then
        self.player:Say("I don't have that many in stock.")
        return
    end
    
    sendClientCommand("ProjectShopee", ProjectShopee.Commands.RemoveItemFromPersonalShop, {
        pos = self.pos,
        item = selectedItem.item.itemFullType,
        amount = amount
    })
    self.player:Say("Taking back items...")
end

function ShopPersonalManageUI:onViewLogs()
    if not ShopPersonalLogsUI then require("ShopPersonalLogsUI") end
    if ProjectShopeePersonalLogsUI_Instance and ProjectShopeePersonalLogsUI_Instance:getIsVisible() then
        ProjectShopeePersonalLogsUI_Instance:close()
    end
    ProjectShopeePersonalLogsUI_Instance = ShopPersonalLogsUI:new(50, 50, 600, 400, self.pos)
    ProjectShopeePersonalLogsUI_Instance:initialise()
    ProjectShopeePersonalLogsUI_Instance:addToUIManager()
end

function ShopPersonalManageUI:onAddItem()
    if not ShopPersonalAddUI then require("ShopPersonalAddUI") end
    local ui = ShopPersonalAddUI:new(0, 0, 400, 500, self.player, self.pos)
    ui:initialise()
    ui:addToUIManager()
end

function ShopPersonalManageUI:render()
    ISCollapsableWindow.render(self)
end

function ShopPersonalManageUI:update()
    ISCollapsableWindow.update(self)
    
    if self.actionCooldown and self.actionCooldown > 0 then
        self.actionCooldown = self.actionCooldown - 1
        if self.actionCooldown <= 0 then
            self.removeBtn:setEnable(true)
            self.removeBtn.title = "Take Back Item"
        end
    end
    
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
    if currentShopData and currentShopData.IsOpen then
        self:close()
    end
end

function ShopPersonalManageUI:close()
    self:removeFromUIManager()
end

function ShopPersonalManageUI:new(x, y, width, height, player, pos)
    local o = {}
    x = getCore():getScreenWidth() - width - 50
    y = getCore():getScreenHeight() / 2 - (height / 2)
    o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    local shopData = ProjectShopee.Config.PersonalShops and ProjectShopee.Config.PersonalShops[pos]
    local ownerName = shopData and shopData.Owner or "Unknown"
    local shopName = (shopData and shopData.Name and shopData.Name ~= "") and shopData.Name or (ownerName .. "'s Personal Shop")
    
    o.title = "Manage: " .. shopName
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



local oldNew = ShopPersonalManageUI.new
function ShopPersonalManageUI:new(x, y, width, height, player, pos)
    local o = oldNew(self, x, y, width, height, player, pos)
    ShopPersonalManageUI.instance = o
    return o
end

local oldClose = ShopPersonalManageUI.close
function ShopPersonalManageUI:close()
    oldClose(self)
    ShopPersonalManageUI.instance = nil
end




