require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISScrollingListBox"
require "ISUI/ISTextEntryBox"

ShopAdminPersonalUI = ISCollapsableWindow:derive("ShopAdminPersonalUI")

function ShopAdminPersonalUI:initialise()
    ISCollapsableWindow.initialise(self)
    self:create()
end

function ShopAdminPersonalUI:create()
    local fontHgt = getTextManager():getFontHeight(UIFont.Small)
    
    self.userEntry = ISTextEntryBox:new("Username", 10, 25, 150, 25)
    self.userEntry:initialise()
    self.userEntry:instantiate()
    self:addChild(self.userEntry)
    

    
    self.addBtn = ISButton:new(170, 25, 60, 25, "Add", self, self.onAdd)
    self.addBtn:initialise()
    self:addChild(self.addBtn)
    
    self.removeBtn = ISButton:new(240, 25, 80, 25, "Remove", self, self.onRemove)
    self.removeBtn:initialise()
    self:addChild(self.removeBtn)
    
    self.list = ISScrollingListBox:new(10, 65, self.width - 20, self.height - 75)
    self.list:initialise()
    self.list:instantiate()
    self.list.itemheight = fontHgt + 6
    self.list.selected = 0
    self.list.font = UIFont.Small
    self.list.doDrawItem = self.drawListItem
    self.list.drawBorder = true
    self:addChild(self.list)
    
    self.list.onMouseUp = function(list, x, y)
        local selectedItem = list.items[list.selected]
        if selectedItem and selectedItem.item then
            self.userEntry:setText(selectedItem.item.username)
        end
    end
    
    self:populateList()
end

function ShopAdminPersonalUI:drawListItem(y, item, alt)
    local a = 0.9;
    if self.selected == item.index then
        self:drawRect(0, (y), self:getWidth(), item.height-1, 0.3, 0.7, 0.35, 0.15);
    end
    self:drawRectBorder(0, (y), self:getWidth(), item.height, a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

    local data = item.item;
    self:drawText(data.username, 10, y + (item.height - self.fontHgt)/2, 1, 1, 1, a, self.font);
    
    return y + item.height;
end

function ShopAdminPersonalUI:populateList()
    self.list:clear()
    if ProjectShopee.Config.PersonalShopWhitelist then
        for username, _ in pairs(ProjectShopee.Config.PersonalShopWhitelist) do
            self.list:addItem(username, {username=username})
        end
    end
end

function ShopAdminPersonalUI:onAdd()
    local user = self.userEntry:getText()
    if user and user ~= "" and user ~= "Username" then
        local wl = ProjectShopee.Config.PersonalShopWhitelist or {}
        wl[user] = true
        sendClientCommand("ProjectShopee", ProjectShopee.Commands.AdminSetPSWhitelist, {Whitelist = wl})
    end
end

function ShopAdminPersonalUI:onRemove()
    local user = self.userEntry:getText()
    if user and user ~= "" and user ~= "Username" then
        local wl = ProjectShopee.Config.PersonalShopWhitelist or {}
        wl[user] = nil
        sendClientCommand("ProjectShopee", ProjectShopee.Commands.AdminSetPSWhitelist, {Whitelist = wl})
    end
end

function ShopAdminPersonalUI:render()
    ISCollapsableWindow.render(self)
end

function ShopAdminPersonalUI:close()
    self:removeFromUIManager()
end

function ShopAdminPersonalUI:new(x, y, width, height, player)
    local o = {}
    x = getCore():getScreenWidth() - width - 50
    y = getCore():getScreenHeight() / 2 - (height / 2)
    o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.title = "Admin: Personal Shop Whitelist"
    o.resizable = false
    o.pin = true
    o.isCollapsed = false
    o.collapseCounter = 0
    o.clearStentil = false
    o.moveWithMouse = true
    o.playerNum = player
    return o
end

local function OnServerCommand(module, command, args)
    if module ~= "ProjectShopee" then return end
    
    if command == ProjectShopee.Commands.SyncConfig then
        if ShopAdminPersonalUI.instance then
            ShopAdminPersonalUI.instance:populateList()
        end
    end
end
Events.OnServerCommand.Add(OnServerCommand)

local oldNew = ShopAdminPersonalUI.new
function ShopAdminPersonalUI:new(x, y, width, height, player)
    local o = oldNew(self, x, y, width, height, player)
    ShopAdminPersonalUI.instance = o
    return o
end

local oldClose = ShopAdminPersonalUI.close
function ShopAdminPersonalUI:close()
    oldClose(self)
    ShopAdminPersonalUI.instance = nil
end
