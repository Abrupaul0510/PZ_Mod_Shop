require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISScrollingListBox"
require "ISUI/ISTextEntryBox"

ShopPersonalAddUI = ISCollapsableWindow:derive("ShopPersonalAddUI")

function ShopPersonalAddUI:initialise()
    ISCollapsableWindow.initialise(self)
    self:create()
end

function ShopPersonalAddUI:create()
    local fontHgt = getTextManager():getFontHeight(UIFont.Small)
    
    self.list = ISScrollingListBox:new(10, 25, self.width - 20, self.height - 150)
    self.list:initialise()
    self.list:instantiate()
    self.list.itemheight = math.max(fontHgt + 10, 32)
    self.list.selected = 0
    self.list.font = UIFont.Small
    self.list.doDrawItem = self.drawListItem
    self.list.drawBorder = true
    self:addChild(self.list)
    
    -- Bottom Controls
    local ctrlY = self.height - 120
    self.amountEntry = ISTextEntryBox:new("1", 10, ctrlY, 100, 25)
    self.amountEntry:initialise()
    self.amountEntry:instantiate()
    self.amountEntry:setOnlyNumbers(true)
    self.amountEntry:setMaxTextLength(6)
    self:addChild(self.amountEntry)
    
    self.priceEntry = ISTextEntryBox:new("100", 120, ctrlY, 100, 25)
    self.priceEntry:initialise()
    self.priceEntry:instantiate()
    self.priceEntry:setOnlyNumbers(true)
    self.priceEntry:setMaxTextLength(6)
    self:addChild(self.priceEntry)
    
    self.addBtn = ISButton:new(230, ctrlY, self.width - 240, 25, "List Item", self, self.onAdd)
    self.addBtn:initialise()
    self:addChild(self.addBtn)
    
    self.list.onMouseUp = function(list, x, y)
        local selectedItem = list.items[list.selected]
        if selectedItem and selectedItem.item then
            self.amountEntry:setText(tostring(selectedItem.item.count))
        end
    end
    
    self:populateList()
end

function ShopPersonalAddUI:drawListItem(y, item, alt)
    local a = 0.9;
    if self.selected == item.index then
        self:drawRect(0, (y), self:getWidth(), item.height-1, 0.3, 0.7, 0.35, 0.15);
    end
    self:drawRectBorder(0, (y), self:getWidth(), item.height, a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

    local data = item.item;
    
    if data.tex then
        self:drawTextureScaledAspect(data.tex, 10, y + (item.height - 32)/2, 32, 32, 1, 1, 1, 1)
    end
    
    self:drawText(data.name, 50, y + (item.height - self.fontHgt)/2, 1, 1, 1, a, self.font);
    
    local rightText = "Owned: " .. tostring(data.count)
    local rightWid = getTextManager():MeasureStringX(self.font, rightText)
    self:drawText(rightText, self:getWidth() - rightWid - 10, y + (item.height - self.fontHgt)/2, 1, 1, 1, a, self.font);

    return y + item.height;
end

function ShopPersonalAddUI:populateList()
    self.list:clear()
    local inv = self.player:getInventory()
    local it = inv:getItems()
    local grouped = {}
    
    for i = 0, it:size()-1 do
        local item = it:get(i)
        if not item:isEquipped() and not item:isFavorite() then
            local type = item:getFullType()
            if not grouped[type] then 
                grouped[type] = { 
                    count = 0, 
                    name = item:getName(), 
                    tex = item:getTex() 
                } 
            end
            grouped[type].count = grouped[type].count + 1
        end
    end
    
    for type, data in pairs(grouped) do
        self.list:addItem(type, {
            itemFullType = type,
            count = data.count,
            name = data.name,
            tex = data.tex
        })
    end
end

function ShopPersonalAddUI:onAdd()
    local selectedItem = self.list.items[self.list.selected]
    if not selectedItem or not selectedItem.item then return end
    
    local amount = tonumber(self.amountEntry:getText())
    local price = tonumber(self.priceEntry:getText())
    
    if not amount or amount < 1 then
        amount = 1
        self.amountEntry:setText("1")
    end
    if not price or price < 1 then
        price = 1
        self.priceEntry:setText("1")
    end
    
    if amount > selectedItem.item.count then
        self.player:Say("I don't have that many to list.")
        return
    end
    
    sendClientCommand("ProjectShopee", ProjectShopee.Commands.AddItemToPersonalShop, {
        pos = self.pos,
        item = selectedItem.item.itemFullType,
        amount = amount,
        price = price
    })
    
    self.player:Say("Listing item...")
    self:close()
end

function ShopPersonalAddUI:render()
    ISCollapsableWindow.render(self)
    
    local ctrlY = self.height - 140
    self:drawText("Quantity:", 10, ctrlY, 1, 1, 1, 1, UIFont.Small)
    self:drawText("Price ($) per unit:", 120, ctrlY, 1, 1, 1, 1, UIFont.Small)
end

function ShopPersonalAddUI:update()
    ISCollapsableWindow.update(self)
    
    if self.amountEntry then
        local text = self.amountEntry:getText()
        local scrubbed = text:gsub("[^0-9]", "")
        if scrubbed == "" or scrubbed == "0" then scrubbed = "1" end
        if text ~= scrubbed then self.amountEntry:setText(scrubbed) end
    end
    if self.priceEntry then
        local text = self.priceEntry:getText()
        local scrubbed = text:gsub("[^0-9]", "")
        if scrubbed == "" or scrubbed == "0" then scrubbed = "1" end
        if text ~= scrubbed then self.priceEntry:setText(scrubbed) end
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

function ShopPersonalAddUI:close()
    self:removeFromUIManager()
end

function ShopPersonalAddUI:new(x, y, width, height, player, pos)
    local o = {}
    x = getCore():getScreenWidth() - width - 50
    y = getCore():getScreenHeight() / 2 - (height / 2)
    o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.title = "Select Inventory Item to List"
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

