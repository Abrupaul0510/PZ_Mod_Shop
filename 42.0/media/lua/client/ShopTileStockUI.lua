require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISScrollingListBox"

ShopTileStockUI = ISPanel:derive("ShopTileStockUI")

function ShopTileStockUI:initialise()
    ISPanel.initialise(self)
    self:create()
end

function ShopTileStockUI:create()
    local btnWid = 100
    local btnHgt = 25
    local fontHgt = getTextManager():getFontHeight(UIFont.Small)
    local itemHgt = math.max(fontHgt + 4, 24)

    self.closeBtn = ISButton:new(self.width - 100, 10, 90, 25, "Close", self, self.close)
    self.closeBtn:initialise()
    self:addChild(self.closeBtn)
    
    self.saveBtn = ISButton:new(self.width - 200, 10, 90, 25, "Save", self, self.onSave)
    self.saveBtn:initialise()
    self:addChild(self.saveBtn)
    
    local listWidth = (self.width / 2) - 15
    
    -- Global Catalog List
    self.globalList = ISScrollingListBox:new(10, 90, listWidth, self.height - 140)
    self.globalList:initialise()
    self.globalList:instantiate()
    self.globalList.itemheight = itemHgt
    self.globalList.selected = 0
    self.globalList.font = UIFont.Small
    self.globalList.doDrawItem = self.drawListItem
    self.globalList.drawBorder = true
    self:addChild(self.globalList)
    
    -- Tile Stock List
    self.stockList = ISScrollingListBox:new((self.width / 2) + 5, 90, listWidth, self.height - 140)
    self.stockList:initialise()
    self.stockList:instantiate()
    self.stockList.itemheight = itemHgt
    self.stockList.selected = 0
    self.stockList.font = UIFont.Small
    self.stockList.doDrawItem = self.drawListItem
    self.stockList.drawBorder = true
    self:addChild(self.stockList)
    
    -- Better buttons that span the width of their respective columns
    self.addBtn = ISButton:new(10, self.height - 40, listWidth, 25, "Add to Tile ->", self, self.onAdd)
    self.addBtn:initialise()
    self:addChild(self.addBtn)
    
    self.removeBtn = ISButton:new((self.width / 2) + 5, self.height - 40, listWidth, 25, "<- Remove from Tile", self, self.onRemove)
    self.removeBtn:initialise()
    self:addChild(self.removeBtn)
    
    -- Local copy of stock for editing
    self.stockedItems = {}
    if ProjectShopee.Config.Shops[self.pos] and ProjectShopee.Config.Shops[self.pos].Items then
        for item, _ in pairs(ProjectShopee.Config.Shops[self.pos].Items) do
            self.stockedItems[item] = true
        end
    end
    
    self.searchEntry = ISTextEntryBox:new("", 10, 40, 200, 25)
    self.searchEntry:initialise()
    self.searchEntry:instantiate()
    self:addChild(self.searchEntry)
    self.lastSearchText = ""
    
    self.moduleCombo = ISComboBox:new(220, 40, 200, 25, self, self.populateLists)
    self.moduleCombo:initialise()
    self:addChild(self.moduleCombo)
    
    local modMap = {["All"] = true}
    local catalog = ProjectShopee.Config.Catalogs and ProjectShopee.Config.Catalogs[self.storeID] or ProjectShopee.Config.Catalog
    if catalog and catalog.Buy then
        for itemName, _ in pairs(catalog.Buy) do
            local itemObj = ScriptManager.instance:getItem(itemName)
            if itemObj then
                local mod = itemObj:getModuleName() or "Base"
                modMap[mod] = true
            end
        end
    end
    
    local sortedMods = {}
    for c, _ in pairs(modMap) do table.insert(sortedMods, c) end
    table.sort(sortedMods)
    for _, c in ipairs(sortedMods) do
        self.moduleCombo:addOption(c)
    end
    self.moduleCombo.selected = 1
    
    self:populateLists()
end

function ShopTileStockUI:update()
    ISPanel.update(self)
    if self.searchEntry then
        local currentSearch = self.searchEntry:getText()
        if self.lastSearchText ~= currentSearch then
            self.lastSearchText = currentSearch
            self:populateLists()
        end
    end
end

function ShopTileStockUI:drawListItem(y, item, alt)
    local a = 0.9;
    if self.selected == item.index then
        self:drawRect(0, (y), self:getWidth(), item.height-1, 0.3, 0.7, 0.35, 0.15);
    end
    self:drawRectBorder(0, (y), self:getWidth(), item.height, a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

    local data = item.item;
    if data.obj then
        local tex = data.obj:getNormalTexture()
        if tex then
            self:drawTextureScaledAspect(tex, 4, y+2, 20, 20, 1, 1, 1, 1)
        end
        self:drawText(data.obj:getDisplayName(), 30, y + (item.height - self.fontHgt)/2, 1, 1, 1, a, self.font);
    else
        self:drawText(item.text, 30, y + (item.height - self.fontHgt)/2, 1, 0.3, 0.3, a, self.font);
    end

    return y + item.height;
end

function ShopTileStockUI:populateLists()
    self.globalList:clear()
    self.stockList:clear()
    
    local searchText = self.searchEntry and self.searchEntry:getText() or ""
    searchText = string.lower(searchText)
    
    local selMod = self.moduleCombo and self.moduleCombo.options[self.moduleCombo.selected] or "All"
    
    local catalog = ProjectShopee.Config.Catalogs and ProjectShopee.Config.Catalogs[self.storeID] or ProjectShopee.Config.Catalog
    if catalog and catalog.Buy then
        for itemName, price in pairs(catalog.Buy) do
            local itemObj = ScriptManager.instance:getItem(itemName)
            local displayName = itemName
            local mod = "Base"
            if itemObj then
                displayName = itemObj:getDisplayName()
                mod = itemObj:getModuleName() or "Base"
            end
            
            local matchMod = (selMod == "All" or mod == selMod)
            
            if matchMod and (searchText == "" or string.find(string.lower(displayName), searchText, 1, true)) then
                if self.stockedItems[itemName] then
                    self.stockList:addItem(displayName, {name=itemName, obj=itemObj})
                else
                    self.globalList:addItem(displayName, {name=itemName, obj=itemObj})
                end
            end
        end
    end
end

function ShopTileStockUI:onAdd()
    local selected = self.globalList.items[self.globalList.selected]
    if selected and selected.item then
        self.stockedItems[selected.item.name] = true
        self:populateLists()
    end
end

function ShopTileStockUI:onRemove()
    local selected = self.stockList.items[self.stockList.selected]
    if selected and selected.item then
        self.stockedItems[selected.item.name] = nil
        self:populateLists()
    end
end

function ShopTileStockUI:onSave()
    sendClientCommand("ProjectShopee", ProjectShopee.Commands.UpdateTileStock, {pos=self.pos, Items=self.stockedItems})
    getPlayer():Say("Tile Stock Saved!")
    self:close()
end

function ShopTileStockUI:prerender()
    ISPanel.prerender(self)
    self:drawText("Manage Tile Stock", 10, 10, 1, 1, 1, 1, UIFont.Medium)
    self:drawText("Global Catalog (Not on this tile)", 10, 70, 1, 1, 1, 1, UIFont.Small)
    self:drawText("Stocked on this Tile", (self.width / 2) + 5, 70, 1, 1, 1, 1, UIFont.Small)
end

function ShopTileStockUI:close()
    self:removeFromUIManager()
end

function ShopTileStockUI:new(x, y, width, height, player, pos, storeID)
    local o = {}
    x = getCore():getScreenWidth() - width - 50
    y = getCore():getScreenHeight() / 2 - (height / 2)
    o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0, g=0, b=0, a=0.9}
    o.borderColor = {r=1, g=1, b=1, a=1}
    o.playerNum = player:getPlayerNum()
    o.player = player
    o.pos = pos
    o.storeID = storeID or "Store1"
    o.moveWithMouse = true
    return o
end
