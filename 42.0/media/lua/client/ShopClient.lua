if isServer() then return end

ProjectShopee = ProjectShopee or {}
ProjectShopee.Client = {}
ProjectShopee.Client.Cart = {}

local function OnServerCommand(module, command, args)
    if module ~= "ProjectShopee" then return end
    
    if command == ProjectShopee.Commands.SyncConfig then
        print("Project Shopee: Client received SyncConfig!")
        if args.Shops then 
            ProjectShopee.Config.Shops = args.Shops 
            local count = 0
            for k,v in pairs(args.Shops) do count = count + 1 end
            print("Project Shopee: Received " .. tostring(count) .. " shops from server.")
        end
        if args.Checkouts then ProjectShopee.Config.Checkouts = args.Checkouts end
        if args.ATMs then ProjectShopee.Config.ATMs = args.ATMs end
        if args.MoneyRatios then ProjectShopee.Config.MoneyRatios = args.MoneyRatios end
        if args.Catalog then ProjectShopee.Config.Catalog = args.Catalog end
        if args.BankBalances then ProjectShopee.Config.BankBalances = args.BankBalances end
        if args.PersonalShopWhitelist then ProjectShopee.Config.PersonalShopWhitelist = args.PersonalShopWhitelist end
        if args.PersonalShops then ProjectShopee.Config.PersonalShops = args.PersonalShops end
        
        -- Optionally refresh open UIs here
        if ProjectShopeeUI_Instance and ProjectShopeeUI_Instance:getIsVisible() then
            ProjectShopeeUI_Instance:refresh()
        end
        if ProjectShopeeAdminUI_Instance and ProjectShopeeAdminUI_Instance:getIsVisible() then
            ProjectShopeeAdminUI_Instance:refresh()
        end
    elseif command == "SyncBalance" then
        ProjectShopee.Client.Balance = args.balance
        if ProjectShopeeUI_Instance and ProjectShopeeUI_Instance:getIsVisible() then
            ProjectShopeeUI_Instance:refresh()
        end
    elseif command == "ClientRemoveItem" then
        local inv = getPlayer():getInventory()
        local remaining = args.amount
        while remaining > 0 do
            local item = inv:FindAndReturn(args.itemType)
            if not item then break end
            inv:Remove(item)
            remaining = remaining - 1
        end
    elseif command == "ClientAddItem" then
        local inv = getPlayer():getInventory()
        for i=1, args.amount do
            inv:AddItem(args.itemType)
        end
    elseif command == "ClientSay" then
        getPlayer():Say(args.text)
        if args.color then
            getPlayer():setHaloNote(args.text, args.color.r, args.color.g, args.color.b, 300)
        end
    elseif command == "ClientSyncInventory" then
        getPlayer():getInventory():requestServerItemsForContainer()
    elseif command == "ClientRefreshContainer" then
        local square = getCell():getGridSquare(args.x, args.y, args.z)
        if square then
            for i=0, square:getObjects():size()-1 do
                local obj = square:getObjects():get(i)
                if obj:getContainer() then
                    obj:getContainer():requestServerItemsForContainer()
                    break
                end
            end
        end
    elseif command == "AllowOpenCheckout" then
        local playerObj = getPlayer()
        if not playerObj then return end
        local pos = args.pos
        if not ShopCheckoutUI then require("ShopCheckoutUI") end
        if not ProjectShopeeCheckoutUI_Instance then
            ProjectShopeeCheckoutUI_Instance = ShopCheckoutUI:new(50, 50, 600, 500, playerObj, pos)
            ProjectShopeeCheckoutUI_Instance:initialise()
            ProjectShopeeCheckoutUI_Instance:addToUIManager()
        else
            ProjectShopeeCheckoutUI_Instance.pos = pos
            ProjectShopeeCheckoutUI_Instance:setVisible(true)
            ProjectShopeeCheckoutUI_Instance:addToUIManager()
            ProjectShopeeCheckoutUI_Instance:bringToTop()
            ProjectShopeeCheckoutUI_Instance:refresh()
        end
    elseif command == "DenyOpenCheckout" or command == "DenyOpenATM" or command == "DenyOpenPersonalShop" then
        local playerObj = getPlayer()
        if playerObj and args and args.message then
            playerObj:Say(args.message)
        end
    elseif command == "AllowOpenATM" then
        local playerObj = getPlayer()
        if not playerObj then return end
        local pos = args.pos
        if not ShopDepositUI then require("ShopDepositUI") end
        if ProjectShopeeDepositUI_Instance and ProjectShopeeDepositUI_Instance:getIsVisible() then
            ProjectShopeeDepositUI_Instance:close()
        end
        ProjectShopeeDepositUI_Instance = ShopDepositUI:new(50, 50, 400, 400, playerObj, pos)
        ProjectShopeeDepositUI_Instance:initialise()
        ProjectShopeeDepositUI_Instance:addToUIManager()
    elseif command == "AllowOpenPersonalShop" then
        local playerObj = getPlayer()
        if not playerObj then return end
        local pos = args.pos
        if not ShopPersonalBrowseUI then require("ShopPersonalBrowseUI") end
        if ProjectShopeePersonalBrowseUI_Instance and ProjectShopeePersonalBrowseUI_Instance:getIsVisible() then
            ProjectShopeePersonalBrowseUI_Instance:close()
        end
        ProjectShopeePersonalBrowseUI_Instance = ShopPersonalBrowseUI:new(0, 0, 500, 500, playerObj, pos)
        ProjectShopeePersonalBrowseUI_Instance:initialise()
        ProjectShopeePersonalBrowseUI_Instance:addToUIManager()
    end
end
Events.OnServerCommand.Add(OnServerCommand)

local ticks = 0
local function DelayedRequestConfig()
    ticks = ticks + 1
    if ticks > 300 then
        print("Project Shopee: Sending delayed RequestConfig!")
        sendClientCommand("ProjectShopee", ProjectShopee.Commands.RequestConfig, {})
        Events.OnTick.Remove(DelayedRequestConfig)
    end
end
local function OnGameStartDelay()
    Events.OnTick.Add(DelayedRequestConfig)
end
Events.OnGameStart.Add(OnGameStartDelay)

local function OnPlayerDeath(player)
    if ProjectShopeeUI_Instance then
        ProjectShopeeUI_Instance:close()
        ProjectShopeeUI_Instance:removeFromUIManager()
        ProjectShopeeUI_Instance = nil
    end
    if ProjectShopeeAdminUI_Instance then
        ProjectShopeeAdminUI_Instance:close()
        ProjectShopeeAdminUI_Instance:removeFromUIManager()
        ProjectShopeeAdminUI_Instance = nil
    end
end
Events.OnPlayerDeath.Add(OnPlayerDeath)

local function OnFillWorldObjectContextMenu(player, context, worldobjects, test)
    local playerObj = getSpecificPlayer(player)
    local access = playerObj:getAccessLevel()
    local isAdmin = false
    if access and (access == "admin" or access == "Admin") then
        isAdmin = true
    end
    
    print("Project Shopee Debug: Context Menu Opened. AccessLevel=" .. tostring(access) .. " isAdmin=" .. tostring(isAdmin))
    
    local square = nil
    for _, obj in ipairs(worldobjects) do
        if obj.getSquare and obj:getSquare() then
            square = obj:getSquare()
            break
        elseif instanceof(obj, "IsoGridSquare") then
            square = obj
            break
        end
    end
    
    if not square then 
        print("Project Shopee Debug: NO SQUARE FOUND!")
        return 
    end
    
    local pos = ProjectShopee.Shared.GetPosString(square)
    print("Project Shopee Debug: Square Found at " .. pos)
    local isShop = type(ProjectShopee.Config.Shops[pos]) == "table"
    local isCheckout = ProjectShopee.Config.Checkouts[pos] == true
    local isATM = ProjectShopee.Config.ATMs[pos] == true
    local personalShopData = ProjectShopee.Config.PersonalShops and ProjectShopee.Config.PersonalShops[pos]
    local isPersonalShop = personalShopData ~= nil
    local username = playerObj:getUsername()
    local isWhitelisted = ProjectShopee.Config.PersonalShopWhitelist and ProjectShopee.Config.PersonalShopWhitelist[username]
    
    if isATM then
        context:addOption("Open ATM / Deposit", playerObj, function()
            local dist = math.sqrt((playerObj:getX() - square:getX())^2 + (playerObj:getY() - square:getY())^2)
            if dist > 2.5 or playerObj:getZ() ~= square:getZ() then
                playerObj:Say("Im too far...Ano ako si Lasticman")
                return
            end
            
            sendClientCommand("ProjectShopee", ProjectShopee.Commands.RequestOpenATM, { pos = pos })
        end)
    end
    
    if isShop then
        context:addOption("Open Shop", playerObj, function()
            local dist = math.sqrt((playerObj:getX() - square:getX())^2 + (playerObj:getY() - square:getY())^2)
            if dist > 2.5 or playerObj:getZ() ~= square:getZ() then
                playerObj:Say("Im too far...Ano ako si Lasticman")
                return
            end
            
            if ProjectShopeeCheckoutUI_Instance and ProjectShopeeCheckoutUI_Instance:getIsVisible() then
                ProjectShopeeCheckoutUI_Instance:close()
            end
            
            if not ProjectShopeeUI_Instance then
                ProjectShopeeUI_Instance = ShopUI:new(50, 50, 600, 500, playerObj, pos)
                ProjectShopeeUI_Instance:initialise()
                ProjectShopeeUI_Instance:addToUIManager()
            else
                ProjectShopeeUI_Instance.pos = pos
                ProjectShopeeUI_Instance:setVisible(true)
                ProjectShopeeUI_Instance:addToUIManager()
                ProjectShopeeUI_Instance:bringToTop()
                ProjectShopeeUI_Instance:refresh()
            end
        end)
    end
    
    if isCheckout then
        context:addOption("Open Checkout", playerObj, function()
            local dist = math.sqrt((playerObj:getX() - square:getX())^2 + (playerObj:getY() - square:getY())^2)
            if dist > 2.5 or playerObj:getZ() ~= square:getZ() then
                playerObj:Say("Im too far...Ano ako si Lasticman")
                return
            end
            
            if ProjectShopeeUI_Instance and ProjectShopeeUI_Instance:getIsVisible() then
                ProjectShopeeUI_Instance:close()
            end
            
            sendClientCommand("ProjectShopee", ProjectShopee.Commands.RequestOpenCheckout, { pos = pos })
        end)
    end
    
    if isPersonalShop then
        if personalShopData.Owner == username and isWhitelisted then
            local statusLabel = personalShopData.IsOpen and "Close Personal Shop" or "Open Personal Shop"
            context:addOption(statusLabel, playerObj, function()
                sendClientCommand("ProjectShopee", ProjectShopee.Commands.TogglePersonalShopStatus, { pos = pos })
            end)
            
            context:addOption("Manage My Personal Shop", playerObj, function()
                local dist = math.sqrt((playerObj:getX() - square:getX())^2 + (playerObj:getY() - square:getY())^2)
                if dist > 2.5 or playerObj:getZ() ~= square:getZ() then
                    playerObj:Say("Im too far...Ano ako si Lasticman")
                    return
                end
                
                -- Dynamic check against the latest config
                local currentShopData = ProjectShopee.Config.PersonalShops and ProjectShopee.Config.PersonalShops[pos]
                if currentShopData and currentShopData.IsOpen then
                    playerObj:Say("Close the shop first to manage it!")
                    return
                end
                
                if not ShopPersonalManageUI then require("ShopPersonalManageUI") end
                local ui = ShopPersonalManageUI:new(0, 0, 500, 500, playerObj, pos)
                ui:initialise()
                ui:addToUIManager()
            end)
        end
        context:addOption("Browse " .. personalShopData.Owner .. "'s Shop", playerObj, function()
            local dist = math.sqrt((playerObj:getX() - square:getX())^2 + (playerObj:getY() - square:getY())^2)
            if dist > 2.5 or playerObj:getZ() ~= square:getZ() then
                playerObj:Say("Im too far...Ano ako si Lasticman")
                return
            end
            
            local currentShopData = ProjectShopee.Config.PersonalShops and ProjectShopee.Config.PersonalShops[pos]
            if currentShopData and not currentShopData.IsOpen then
                playerObj:Say("The Shop is still Closed")
                return
            end
            
            sendClientCommand("ProjectShopee", ProjectShopee.Commands.RequestOpenPersonalShop, { pos = pos })
        end)
    elseif not isShop and not isCheckout and not isATM and isWhitelisted then
        local hasShop = false
        for _, sData in pairs(ProjectShopee.Config.PersonalShops or {}) do
            if sData.Owner == username then
                hasShop = true
                break
            end
        end
        
        if hasShop then
            context:addOption("Relocate My Personal Shop Here", playerObj, function()
                sendClientCommand("ProjectShopee", ProjectShopee.Commands.RelocatePersonalShop, { newPos = pos })
            end)
        else
            context:addOption("Setup Personal Shop", playerObj, function()
                sendClientCommand("ProjectShopee", ProjectShopee.Commands.CreatePersonalShop, { pos = pos })
            end)
        end
    end
    
    if isAdmin then
        local adminMenu = context:addOption("Admin: Shop Config")
        local adminSubMenu = context:getNew(context)
        context:addSubMenu(adminMenu, adminSubMenu)
        
        adminSubMenu:addOption("Bank & Logs", playerObj, function()
            if not ShopAdminBankUI then
                require "ShopAdminBankUI"
            end
            local ui = ShopAdminBankUI:new(50, 50, 900, 500, player)
            ui:initialise()
            ui:addToUIManager()
        end)
        
        adminSubMenu:addOption("Global Shop Catalog", playerObj, function()
            if not ProjectShopeeAdminUI_Instance then
                ProjectShopeeAdminUI_Instance = ShopAdminUI:new(100, 100, 500, 600, playerObj)
                ProjectShopeeAdminUI_Instance:initialise()
                ProjectShopeeAdminUI_Instance:addToUIManager()
            else
                ProjectShopeeAdminUI_Instance:setVisible(true)
                ProjectShopeeAdminUI_Instance:addToUIManager()
                ProjectShopeeAdminUI_Instance:bringToTop()
                ProjectShopeeAdminUI_Instance:refresh()
            end
        end)
        
        adminSubMenu:addOption("Configure ATM Ratios", playerObj, function()
            if not ShopAdminRatiosUI then require("ShopAdminRatiosUI") end
            local ui = ShopAdminRatiosUI:new(50, 50, 400, 300, playerObj)
            ui:initialise()
            ui:addToUIManager()
        end)
        
        adminSubMenu:addOption("Manage Personal Shop Whitelist", playerObj, function()
            if not ShopAdminPersonalUI then require("ShopAdminPersonalUI") end
            local ui = ShopAdminPersonalUI:new(50, 50, 400, 400, playerObj)
            ui:initialise()
            ui:addToUIManager()
        end)
        
        if isPersonalShop then
            adminSubMenu:addOption("Remove Personal Shop Status", playerObj, function()
                sendClientCommand("ProjectShopee", ProjectShopee.Commands.RemovePersonalShop, { pos = pos })
            end)
        end
        
        if isShop then
            adminSubMenu:addOption("Manage Tile Stock", playerObj, function()
                if not ShopTileStockUI then require("ShopTileStockUI") end
                local ui = ShopTileStockUI:new(50, 50, 600, 500, playerObj, pos)
                ui:initialise()
                ui:addToUIManager()
            end)
            adminSubMenu:addOption("Rename Shop Tile", playerObj, function()
                local currentName = ProjectShopee.Config.Shops[pos].Name or "Global Shop"
                if not ShopRenameUI then require("ShopRenameUI") end
                local ui = ShopRenameUI:new(0, 0, 280, 100, playerObj, pos, currentName)
                ui:initialise()
                ui:addToUIManager()
            end)
            adminSubMenu:addOption("Remove Shop Status", playerObj, function()
                sendClientCommand("ProjectShopee", ProjectShopee.Commands.RemoveShop, { pos = pos })
            end)
        else
            adminSubMenu:addOption("Make this tile a Shop", playerObj, function()
                sendClientCommand("ProjectShopee", ProjectShopee.Commands.AddShop, { pos = pos })
            end)
        end
        
        if isCheckout then
            adminSubMenu:addOption("Remove Checkout Status", playerObj, function()
                sendClientCommand("ProjectShopee", ProjectShopee.Commands.RemoveCheckout, { pos = pos })
            end)
        else
            adminSubMenu:addOption("Make this tile a Checkout", playerObj, function()
                sendClientCommand("ProjectShopee", ProjectShopee.Commands.AddCheckout, { pos = pos })
            end)
        end
        
        if isATM then
            adminSubMenu:addOption("Remove ATM Status", playerObj, function()
                sendClientCommand("ProjectShopee", ProjectShopee.Commands.RemoveATM, { pos = pos })
            end)
        else
            adminSubMenu:addOption("Make this tile an ATM", playerObj, function()
                sendClientCommand("ProjectShopee", ProjectShopee.Commands.AddATM, { pos = pos })
            end)
        end
    end
end
Events.OnFillWorldObjectContextMenu.Add(OnFillWorldObjectContextMenu)
