require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISTextEntryBox"
require "ISUI/ISScrollingListBox"

ShopDepositUI = ISPanel:derive("ShopDepositUI")

function ShopDepositUI:initialise()
    ISPanel.initialise(self)
    self:create()
end

function ShopDepositUI:create()
    local fontHgt = getTextManager():getFontHeight(UIFont.Small)
    
    self.closeBtn = ISButton:new(self.width - 100, 10, 90, 25, "Close", self, self.close)
    self.closeBtn:initialise()
    self:addChild(self.closeBtn)

    self.moneyList = ISScrollingListBox:new(10, 50, self.width - 20, self.height - 210)
    self.moneyList:initialise()
    self.moneyList:instantiate()
    self.moneyList.itemheight = math.max(fontHgt + 4, 24)
    self.moneyList.selected = 0
    self.moneyList.font = UIFont.Small
    self.moneyList.doDrawItem = self.drawMoneyItem
    self.moneyList.drawBorder = true
    self:addChild(self.moneyList)
    
    self.amountEntry = ISTextEntryBox:new("1", 10, self.height - 70, 60, 25)
    self.amountEntry:initialise()
    self.amountEntry:instantiate()
    self.amountEntry:setOnlyNumbers(true)
    self.amountEntry:setMaxTextLength(6)
    self:addChild(self.amountEntry)
    
    self.depositBtn = ISButton:new(80, self.height - 150, 150, 25, "Deposit Amount", self, self.onDepositAmount)
    self.depositBtn:initialise()
    self:addChild(self.depositBtn)
    
    self.depositAllBtn = ISButton:new(240, self.height - 150, self.width - 250, 25, "Deposit ALL", self, self.onDepositAll)
    self.depositAllBtn:initialise()
    self:addChild(self.depositAllBtn)

    self.targetEntry = ISTextEntryBox:new("Enter Username", 10, self.height - 70, 120, 25)
    self.targetEntry:initialise()
    self.targetEntry:instantiate()
    self:addChild(self.targetEntry)
    
    self.transferAmountEntry = ISTextEntryBox:new("1", 140, self.height - 70, 80, 25)
    self.transferAmountEntry:initialise()
    self.transferAmountEntry:instantiate()
    self.transferAmountEntry:setOnlyNumbers(true)
    self.transferAmountEntry:setMaxTextLength(6)
    self:addChild(self.transferAmountEntry)
    
    self.transferBtn = ISButton:new(230, self.height - 70, 160, 25, "Transfer Money", self, self.onTransferMoney)
    self.transferBtn:initialise()
    self:addChild(self.transferBtn)

    self:populateList()
end

function ShopDepositUI:drawMoneyItem(y, item, alt)
    local a = 0.9;
    if self.selected == item.index then
        self:drawRect(0, (y), self:getWidth(), item.height-1, 0.1, 0.4, 0.1, 0.3);
    end
    self:drawRectBorder(0, (y), self:getWidth(), item.height, a, 0, 0.8, 0.2);

    local data = item.item;
    local itemObj = ScriptManager.instance:getItem(data.item)
    if itemObj then
        local tex = itemObj:getNormalTexture()
        if tex then
            self:drawTextureScaledAspect(tex, 4, y+2, 20, 20, 1, 1, 1, 1)
        end
        self:drawText(tostring(data.count) .. "x " .. itemObj:getDisplayName(), 30, y + (item.height - self.fontHgt)/2, 0.2, 0.9, 0.2, a, self.font);
    else
        self:drawText(tostring(data.count) .. "x " .. data.item, 30, y + (item.height - self.fontHgt)/2, 0.2, 0.7, 0.2, a, self.font);
    end
    
    local valStr = "Value: $" .. tostring(data.ratio) .. " each"
    local valWid = getTextManager():MeasureStringX(self.font, valStr)
    self:drawText(valStr, self:getWidth() - valWid - 10, y + (item.height - self.fontHgt)/2, 0.2, 0.9, 0.2, a, self.font);

    return y + item.height;
end

function ShopDepositUI:populateList()
    self.moneyList:clear()
    local inv = self.player:getInventory()
    
    if ProjectShopee.Config.MoneyRatios then
        for itemType, ratio in pairs(ProjectShopee.Config.MoneyRatios) do
            local count = inv:getCountTypeRecurse(itemType)
            if count > 0 then
                self.moneyList:addItem(itemType, {item=itemType, ratio=ratio, count=count})
            end
        end
    end
end

function ShopDepositUI:onDepositAmount()
    local selectedItem = self.moneyList.items[self.moneyList.selected]
    if not selectedItem or not selectedItem.item then
        self.player:Say("I dont have that amount of money, Wag managarap :)")
        self:close()
        return
    end
    
    local amt = tonumber(self.amountEntry:getText())
    if amt and amt > 0 then
        if amt > selectedItem.item.count then
            self.player:Say("I dont have that amount of money, Wag managarap :)")
            self:close()
            return
        end
        
        local itemsToDeposit = {}
        itemsToDeposit[selectedItem.item.item] = amt
        
        sendClientCommand("ProjectShopee", ProjectShopee.Commands.DepositMoney, {items = itemsToDeposit})
        self:close()
    end
end

function ShopDepositUI:onDepositAll()
    local itemsToDeposit = {}
    local hasMoney = false
    
    if ProjectShopee.Config.MoneyRatios then
        local inv = self.player:getInventory()
        for itemType, ratio in pairs(ProjectShopee.Config.MoneyRatios) do
            local count = inv:getCountTypeRecurse(itemType)
            if count > 0 then
                itemsToDeposit[itemType] = count
                hasMoney = true
            end
        end
    end
    
    if hasMoney then
        sendClientCommand("ProjectShopee", ProjectShopee.Commands.DepositMoney, {items = itemsToDeposit})
        self:close()
    else
        self.player:Say("I dont have that amount of money, Wag managarap :)")
        self:close()
    end
end

function ShopDepositUI:onTransferMoney()
    local targetUser = self.targetEntry:getText()
    local amt = tonumber(self.transferAmountEntry:getText())
    
    if targetUser == "" or targetUser == "Enter Username" or not amt or amt <= 0 then
        self.player:Say("Invalid transfer details.")
        return
    end
    
    local balance = ProjectShopee.Client.Balance or 0
    if amt > balance then
        self.player:Say("I don't have enough digital balance for that!")
        return
    end
    
    sendClientCommand("ProjectShopee", ProjectShopee.Commands.TransferMoney, {target = targetUser, amount = amt})
    self:close()
end

function ShopDepositUI:prerender()
    ISPanel.prerender(self)
    -- Dark green/black CRT background
    self:drawRect(0, 0, self.width, self.height, 0.95, 0.05, 0.1, 0.05)
    -- Glowing green border
    self:drawRectBorder(0, 0, self.width, self.height, 1, 0, 0.8, 0.2)
    
    self:drawText("ATM TERMINAL", 10, 10, 0.2, 0.9, 0.2, 1, UIFont.Medium)
    self:drawText("Select money from inventory to deposit:", 10, 30, 0.2, 0.7, 0.2, 1, UIFont.Small)
    
    local balance = ProjectShopee.Client.Balance or 0
    local balText = "BALANCE: $" .. tostring(balance)
    local balWid = getTextManager():MeasureStringX(UIFont.Medium, balText)
    self:drawText(balText, self.width - balWid - 100, 10, 0.2, 0.9, 0.2, 1, UIFont.Medium)
    
    -- Separator
    self:drawRect(10, self.height - 90, self.width - 20, 1, 0.2, 0.8, 0.2, 0.5)
    
    self:drawText("TRANSFER FUNDS", 10, self.height - 87, 0.2, 0.9, 0.2, 1, UIFont.Small)
    self:drawText("Target Username", 10, self.height - 40, 0.2, 0.7, 0.2, 1, UIFont.Small)
    self:drawText("Amount", 140, self.height - 40, 0.2, 0.7, 0.2, 1, UIFont.Small)
end

function ShopDepositUI:update()
    ISPanel.update(self)
    if not self:getIsVisible() then return end
    
    if self.amountEntry then
        local text = self.amountEntry:getText()
        local scrubbed = text:gsub("[^0-9]", "")

        if text ~= scrubbed then self.amountEntry:setText(scrubbed) end
    end
    if self.transferAmountEntry then
        local text = self.transferAmountEntry:getText()
        local scrubbed = text:gsub("[^0-9]", "")

        if text ~= scrubbed then self.transferAmountEntry:setText(scrubbed) end
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

function ShopDepositUI:close()
    self:removeFromUIManager()
end

function ShopDepositUI:new(x, y, width, height, player, pos)
    local o = {}
    x = getCore():getScreenWidth() - width - 50
    y = getCore():getScreenHeight() / 2 - (height / 2)
    o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0, g=0, b=0, a=0.7}
    o.borderColor = {r=1, g=1, b=1, a=1}
    o.playerNum = player:getPlayerNum()
    o.player = player
    o.pos = pos
    o.moveWithMouse = true
    return o
end

