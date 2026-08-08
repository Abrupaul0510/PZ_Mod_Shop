if isServer() then return end
require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"

AnimalShopUI = ISCollapsableWindow:derive("AnimalShopUI")

local ANIMAL_PRICES = {
    ["cow"] = 5000,
    ["bull"] = 6000,
    ["cowcalf"] = 2500,
    ["sow"] = 3000,
    ["boar"] = 3500,
    ["piglet"] = 1500,
    ["ewe"] = 4000,
    ["ram"] = 4500,
    ["lamb"] = 2500,
    ["hen"] = 500,
    ["cockerel"] = 600,
    ["chick"] = 200
}

local ANIMALS = {
    { id="cow", name="Cow", icon="map_cow.png", type="cow", breed="Holstein" },
    { id="bull", name="Bull", icon="map_cow.png", type="cow", breed="Holstein" },
    { id="cowcalf", name="Calf", icon="map_cow.png", type="cow", breed="Holstein" },
    { id="sow", name="Sow (Pig)", icon="map_pig.png", type="pig", breed="Yorkshire" },
    { id="boar", name="Boar (Pig)", icon="map_pig.png", type="pig", breed="Yorkshire" },
    { id="piglet", name="Piglet", icon="map_pig.png", type="pig", breed="Yorkshire" },
    { id="ewe", name="Ewe (Sheep)", icon="map_sheep.png", type="sheep", breed="Suffolk" },
    { id="ram", name="Ram", icon="map_sheep.png", type="sheep", breed="Suffolk" },
    { id="lamb", name="Lamb", icon="map_sheep.png", type="sheep", breed="Suffolk" },
    { id="hen", name="Hen", icon="map_chicken.png", type="chicken", breed="Leghorn" },
    { id="cockerel", name="Rooster", icon="map_chicken.png", type="chicken", breed="Leghorn" },
    { id="chick", name="Chick", icon="map_chicken.png", type="chicken", breed="Leghorn" }
}

function AnimalShopUI:initialise()
    ISCollapsableWindow.initialise(self)
    
    self.title = "Aling Kiwe - Animal Store"
    self:setResizable(false)
    
    local btnWid = 100
    local btnHgt = 30
    local padding = 10
    local startX = padding
    local startY = 40
    local iconSize = 64
    
    local row = 0
    local col = 0
    local maxCols = 5
    
    for i, animal in ipairs(ANIMALS) do
        local x = startX + (col * (btnWid + padding))
        local y = startY + (row * (iconSize + btnHgt + padding * 2))
        
        local price = ANIMAL_PRICES[animal.id] or 1000
        
        -- Create buy button under the icon
        local btn = ISButton:new(x, y + iconSize + padding, btnWid, btnHgt, "Buy $" .. tostring(price), self, self.onBuyAnimal)
        btn.internal = animal.id
        btn:initialise()
        btn:instantiate()
        btn.borderColor = {r=1, g=1, b=1, a=0.2}
        self:addChild(btn)
        
        -- Add to self to draw later
        animal.x = x
        animal.y = y
        animal.tex = getTexture("media/ui/LootableMaps/" .. animal.icon) or getTexture("media/ui/" .. animal.icon) or getTexture("Item_Food")
        
        col = col + 1
        if col >= maxCols then
            col = 0
            row = row + 1
        end
    end
end

function AnimalShopUI:prerender()
    ISCollapsableWindow.prerender(self)
    
    -- Draw money
    local username = self.player:getUsername()
    local bal = ProjectShopee.Config.BankBalances[username] or 0
    self:drawText("Your Balance: $" .. tostring(bal), 10, 20, 1, 1, 1, 1, UIFont.Small)
    
    -- Draw Animal Icons
    for i, animal in ipairs(ANIMALS) do
        if animal.tex then
            self:drawTextureScaledAspect(animal.tex, animal.x + (100 - 64)/2, animal.y, 64, 64, 1, 1, 1, 1)
        end
        self:drawTextCentre(animal.name, animal.x + 50, animal.y - 15, 1, 1, 1, 1, UIFont.Small)
    end
end

function AnimalShopUI:onBuyAnimal(button)
    local animalId = button.internal
    local price = ANIMAL_PRICES[animalId] or 1000
    
    local username = self.player:getUsername()
    local balance = ProjectShopee.Config.BankBalances[username] or 0
    
    if balance < price then
        self.player:Say("I don't have enough digital money for this animal!")
        return
    end
    
    
    local animData = nil
    for _, a in ipairs(ANIMALS) do
        if a.id == animalId then
            animData = a
            break
        end
    end
    
    if not animData then return end
    
    -- Request the server to handle payment and spawning
    sendClientCommand(self.player, "AlingKiweAnimals", "BuyAnimal", { animalType = animData.type, breedName = animData.breed, targetType = animData.id, price = price, pos = self.pos })
end

function AnimalShopUI:new(x, y, width, height, player, pos)
    local o = {}
    o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.player = player
    o.pos = pos
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.backgroundColor = {r=0, g=0, b=0, a=0.8}
    return o
end

function AnimalShopUI:close()
    ISCollapsableWindow.close(self)
    if ProjectShopeeAnimalShopUI_Instance then
        ProjectShopeeAnimalShopUI_Instance:removeFromUIManager()
        ProjectShopeeAnimalShopUI_Instance = nil
    end
end
