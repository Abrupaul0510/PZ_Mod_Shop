require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISScrollingListBox"
require "ISUI/ISTextEntryBox"

ShopAdminBankUI = ISPanel:derive("ShopAdminBankUI")

function ShopAdminBankUI:initialise()
    ISPanel.initialise(self)
    self:create()
end

function ShopAdminBankUI:create()
    local fontHgt = getTextManager():getFontHeight(UIFont.Small)
    
    self.closeBtn = ISButton:new(self.width - 100, 10, 90, 25, "Close", self, self.close)
    self.closeBtn:initialise()
    self:addChild(self.closeBtn)
    
    -- Bank Balances List
    self.bankSearchEntry = ISTextEntryBox:new("", 110, 27, 150, 20)
    self.bankSearchEntry:initialise()
    self.bankSearchEntry:instantiate()
    self:addChild(self.bankSearchEntry)
    
    self.bankList = ISScrollingListBox:new(10, 50, 250, self.height - 120)
    self.bankList:initialise()
    self.bankList:instantiate()
    self.bankList.itemheight = math.max(fontHgt + 4, 24)
    self.bankList.selected = 0
    self.bankList.font = UIFont.Small
    self.bankList.doDrawItem = self.drawBankListItem
    self.bankList.drawBorder = true
    self:addChild(self.bankList)
    
    -- Balance Edit Section
    self.userEntry = ISTextEntryBox:new("Username", 10, self.height - 60, 120, 25)
    self.userEntry:initialise()
    self.userEntry:instantiate()
    self:addChild(self.userEntry)
    
    self.balanceEntry = ISTextEntryBox:new("0", 140, self.height - 60, 120, 25)
    self.balanceEntry:initialise()
    self.balanceEntry:instantiate()
    self.balanceEntry:setOnlyNumbers(true)
    self:addChild(self.balanceEntry)
    
    self.setBtn = ISButton:new(10, self.height - 30, 250, 25, "Update Player Balance", self, self.onSetBalance)
    self.setBtn:initialise()
    self:addChild(self.setBtn)
    
    -- Transaction Logs List
    self.logSearchEntry = ISTextEntryBox:new("", 400, 27, 200, 20)
    self.logSearchEntry:initialise()
    self.logSearchEntry:instantiate()
    self:addChild(self.logSearchEntry)
    
    self.logList = ISScrollingListBox:new(270, 50, self.width - 280, self.height - 60)
    self.logList:initialise()
    self.logList:instantiate()
    self.logList.itemheight = fontHgt + 6
    self.logList.selected = 0
    self.logList.font = UIFont.Small
    self.logList.doDrawItem = self.drawLogListItem
    self.logList.drawBorder = true
    self:addChild(self.logList)
    
    -- Auto-fill username when clicking a list item
    self.bankList.onMouseUp = function(list, x, y)
        local selectedItem = list.items[list.selected]
        if selectedItem and selectedItem.item then
            self.userEntry:setText(selectedItem.item.username)
            self.balanceEntry:setText(tostring(selectedItem.item.balance))
        end
    end
    
    self:populateBankList()
    
    -- Request the latest logs and config from the server
    sendClientCommand("ProjectShopee", ProjectShopee.Commands.RequestConfig, {})
    sendClientCommand("ProjectShopee", ProjectShopee.Commands.AdminRequestLogs, {})
end

function ShopAdminBankUI:drawBankListItem(y, item, alt)
    local a = 0.9;
    if self.selected == item.index then
        self:drawRect(0, (y), self:getWidth(), item.height-1, 0.3, 0.7, 0.35, 0.15);
    end
    self:drawRectBorder(0, (y), self:getWidth(), item.height, a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

    local data = item.item;
    self:drawText(data.username, 10, y + (item.height - self.fontHgt)/2, 1, 1, 1, a, self.font);
    
    local balanceStr = "$" .. tostring(data.balance)
    local balWid = getTextManager():MeasureStringX(self.font, balanceStr)
    self:drawText(balanceStr, self:getWidth() - balWid - 10, y + (item.height - self.fontHgt)/2, 0.2, 1, 0.2, a, self.font);

    return y + item.height;
end

function ShopAdminBankUI:drawLogListItem(y, item, alt)
    local a = 0.8;
    if self.selected == item.index then
        self:drawRect(0, (y), self:getWidth(), item.height-1, 0.3, 0.7, 0.35, 0.15);
    end
    self:drawRectBorder(0, (y), self:getWidth(), item.height, 0.2, self.borderColor.r, self.borderColor.g, self.borderColor.b);

    local text = item.text
    if string.match(text, "ADMIN") then
        self:drawText(text, 5, y + (item.height - self.fontHgt)/2, 1, 0.6, 0.2, a, self.font);
    elseif string.match(text, "BOUGHT") or string.match(text, "CHECKOUT") then
        self:drawText(text, 5, y + (item.height - self.fontHgt)/2, 1, 0.4, 0.4, a, self.font);
    elseif string.match(text, "SOLD") then
        self:drawText(text, 5, y + (item.height - self.fontHgt)/2, 0.4, 1, 0.4, a, self.font);
    else
        self:drawText(text, 5, y + (item.height - self.fontHgt)/2, 1, 1, 1, a, self.font);
    end

    return y + item.height;
end

function ShopAdminBankUI:populateBankList()
    self.bankList:clear()
    local filter = string.lower(self.bankSearchEntry:getText() or "")
    if ProjectShopee.Config.BankBalances then
        for username, balance in pairs(ProjectShopee.Config.BankBalances) do
            if filter == "" or string.find(string.lower(username), filter) then
                self.bankList:addItem(username, {username=username, balance=balance})
            end
        end
    end
end

function ShopAdminBankUI:populateLogs(logsTable)
    self.logList:clear()
    local filter = string.lower(self.logSearchEntry:getText() or "")
    
    local sourceLogs = logsTable or self.currentLogs or {}
    self.currentLogs = sourceLogs
    
    for _, logLine in ipairs(sourceLogs) do
        if filter == "" or string.find(string.lower(logLine), filter) then
            self.logList:addItem(logLine, nil)
        end
    end
end

function ShopAdminBankUI:onSetBalance()
    local targetUser = self.userEntry:getText()
    local newBalance = tonumber(self.balanceEntry:getText())
    
    if targetUser and targetUser ~= "" and targetUser ~= "Username" and newBalance then
        sendClientCommand("ProjectShopee", ProjectShopee.Commands.AdminSetMoney, {username = targetUser, balance = newBalance})
    end
end

function ShopAdminBankUI:prerender()
    ISPanel.prerender(self)
    self:drawText("Admin: Bank Management & Logs", 10, 10, 1, 1, 1, 1, UIFont.Medium)
    self:drawText("Player Balances:", 10, 30, 1, 1, 1, 1, UIFont.Small)
    self:drawText("Transaction Logs:", 270, 30, 1, 1, 1, 1, UIFont.Small)
end

function ShopAdminBankUI:update()
    ISPanel.update(self)
    if self.lastBankSearch ~= self.bankSearchEntry:getText() then
        self.lastBankSearch = self.bankSearchEntry:getText()
        self:populateBankList()
    end
    if self.lastLogSearch ~= self.logSearchEntry:getText() then
        self.lastLogSearch = self.logSearchEntry:getText()
        self:populateLogs()
    end
end

function ShopAdminBankUI:close()
    self:removeFromUIManager()
end

function ShopAdminBankUI:new(x, y, width, height, player)
    local o = {}
    x = getCore():getScreenWidth() - width - 50
    y = getCore():getScreenHeight() / 2 - (height / 2)
    o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0, g=0, b=0, a=0.7}
    o.borderColor = {r=1, g=1, b=1, a=1}
    o.playerNum = player
    o.moveWithMouse = true
    return o
end

local function OnServerCommand(module, command, args)
    if module ~= "ProjectShopee" then return end
    
    if command == ProjectShopee.Commands.SyncConfig then
        if ShopAdminBankUI.instance then
            ShopAdminBankUI.instance:populateBankList()
        end
    elseif command == ProjectShopee.Commands.SyncLogs then
        if ShopAdminBankUI.instance then
            ShopAdminBankUI.instance:populateLogs(args)
        end
    end
end
Events.OnServerCommand.Add(OnServerCommand)

local oldNew = ShopAdminBankUI.new
function ShopAdminBankUI:new(x, y, width, height, player)
    local o = oldNew(self, x, y, width, height, player)
    ShopAdminBankUI.instance = o
    return o
end

local oldClose = ShopAdminBankUI.close
function ShopAdminBankUI:close()
    oldClose(self)
    ShopAdminBankUI.instance = nil
end
