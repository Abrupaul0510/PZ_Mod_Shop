require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISTextEntryBox"

ShopRenameUI = ISPanel:derive("ShopRenameUI")

function ShopRenameUI:initialise()
    ISPanel.initialise(self)
    self:create()
end

function ShopRenameUI:create()
    local btnWid = 100
    local btnHgt = 25

    self.nameEntry = ISTextEntryBox:new(self.currentName, 20, 40, self.width - 40, 25)
    self.nameEntry:initialise()
    self.nameEntry:instantiate()
    self:addChild(self.nameEntry)
    
    self.saveBtn = ISButton:new(20, self.height - 35, 80, 25, "Save", self, self.onSave)
    self.saveBtn:initialise()
    self:addChild(self.saveBtn)

    self.cancelBtn = ISButton:new(self.width - 100, self.height - 35, 80, 25, "Cancel", self, self.close)
    self.cancelBtn:initialise()
    self:addChild(self.cancelBtn)
end

function ShopRenameUI:onSave()
    local text = self.nameEntry:getText()
    if text and text ~= "" then
        sendClientCommand("ProjectShopee", ProjectShopee.Commands.RenameShop, {pos = self.pos, name = text})
    end
    self:close()
end

function ShopRenameUI:prerender()
    ISPanel.prerender(self)
    self:drawText("Enter New Shop Name:", 20, 15, 1, 1, 1, 1, UIFont.Small)
end

function ShopRenameUI:close()
    self:removeFromUIManager()
end

function ShopRenameUI:new(x, y, width, height, player, pos, currentName)
    local o = {}
    x = getCore():getScreenWidth() / 2 - (width / 2)
    y = getCore():getScreenHeight() / 2 - (height / 2)
    o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0, g=0, b=0, a=0.9}
    o.borderColor = {r=1, g=1, b=1, a=1}
    o.playerNum = player:getPlayerNum()
    o.player = player
    o.pos = pos
    o.currentName = currentName
    o.moveWithMouse = true
    return o
end
