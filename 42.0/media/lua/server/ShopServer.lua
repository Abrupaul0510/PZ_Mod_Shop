if not isServer() then return end

ProjectShopee = ProjectShopee or {}
ProjectShopee.Server = {}
ProjectShopee.ActiveCheckouts = {}
ProjectShopee.ActiveATMs = {}
ProjectShopee.ActivePersonalShops = {}

local function trim(s)
   return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function SaveConfig()
    local writer = getFileWriter("ProjectShopeeConfig.txt", true, false)
    if not writer then return end
    
    writer:write("SHOPS\n")
    for pos, data in pairs(ProjectShopee.Config.Shops) do
        writer:write(pos .. "\n")
        if type(data) == "table" then
            if data.Name then
                writer:write("NAME=" .. data.Name .. "\n")
            end
            if data.Items then
                for item, _ in pairs(data.Items) do
                    writer:write("ITEM=" .. item .. "\n")
                end
            end
        end
    end
    
    writer:write("CHECKOUTS\n")
    if ProjectShopee.Config.Checkouts then
        for pos, _ in pairs(ProjectShopee.Config.Checkouts) do
            writer:write(pos .. "\n")
        end
    end
    
    writer:write("ATMS\n")
    if ProjectShopee.Config.ATMs then
        for pos, _ in pairs(ProjectShopee.Config.ATMs) do
            writer:write(pos .. "\n")
        end
    end
    
    writer:write("MONEY_RATIOS\n")
    if ProjectShopee.Config.MoneyRatios then
        for item, ratio in pairs(ProjectShopee.Config.MoneyRatios) do
            writer:write(item .. "=" .. tostring(ratio) .. "\n")
        end
    end
    
    writer:write("PS_WHITELIST\n")
    if ProjectShopee.Config.PersonalShopWhitelist then
        for user, _ in pairs(ProjectShopee.Config.PersonalShopWhitelist) do
            writer:write(user .. "\n")
        end
    end
    
    writer:write("PERSONAL_SHOPS\n")
    if ProjectShopee.Config.PersonalShops then
        for pos, data in pairs(ProjectShopee.Config.PersonalShops) do
            writer:write("POS=" .. pos .. "\n")
            writer:write("OWNER=" .. data.Owner .. "\n")
            if data.Name then writer:write("NAME=" .. data.Name .. "\n") end
            if data.IsOpen ~= nil then writer:write("ISOPEN=" .. tostring(data.IsOpen) .. "\n") end
            writer:write("EARNINGS=" .. tostring(data.Earnings or 0) .. "\n")
            for item, itemData in pairs(data.Stock or {}) do
                writer:write("ITEM=" .. item .. "," .. tostring(itemData.Count) .. "," .. tostring(itemData.Price) .. "\n")
            end
            for _, logStr in ipairs(data.Logs or {}) do
                writer:write("LOG=" .. logStr .. "\n")
            end
        end
    end
    
    writer:write("CATALOG_BUY\n")
    if ProjectShopee.Config.Catalog.Buy then
        for item, price in pairs(ProjectShopee.Config.Catalog.Buy) do
            writer:write(item .. "=" .. tostring(price) .. "\n")
        end
    end
    
    writer:write("CATALOG_SELL\n")
    if ProjectShopee.Config.Catalog.Sell then
        for item, price in pairs(ProjectShopee.Config.Catalog.Sell) do
            writer:write(item .. "=" .. tostring(price) .. "\n")
        end
    end
    
    writer:write("CATALOG_LIMITS\n")
    if ProjectShopee.Config.Catalog.Limits then
        for item, limit in pairs(ProjectShopee.Config.Catalog.Limits) do
            writer:write(item .. "=" .. tostring(limit) .. "\n")
        end
    end
    
    writer:write("BANK_BALANCES\n")
    if ProjectShopee.Config.BankBalances then
        for username, balance in pairs(ProjectShopee.Config.BankBalances) do
            writer:write(username .. "=" .. tostring(balance) .. "\n")
        end
    end
    
    writer:write("TRANSACTION_LOGS\n")
    if ProjectShopee.Config.TransactionLogs then
        for _, logLine in ipairs(ProjectShopee.Config.TransactionLogs) do
            writer:write(logLine .. "\n")
        end
    end
    
    writer:close()
end

local function BroadcastConfig()
    local players = getOnlinePlayers()
    if players then
        for i=0, players:size()-1 do
            local p = players:get(i)
            sendServerCommand(p, "ProjectShopee", ProjectShopee.Commands.SyncConfig, ProjectShopee.Config)
        end
    end
end

ProjectShopee.NeedsSave = false

local function PeriodicSave()
    if ProjectShopee.NeedsSave then
        SaveConfig()
        BroadcastConfig()
        ProjectShopee.NeedsSave = false
    end
end
Events.EveryOneMinute.Add(PeriodicSave)

local function LoadConfig()
    local reader = getFileReader("ProjectShopeeConfig.txt", false)
    if not reader then return end
    
    ProjectShopee.Config.Shops = {}
    ProjectShopee.Config.Checkouts = {}
    ProjectShopee.Config.ATMs = {}
    ProjectShopee.Config.PersonalShopWhitelist = {}
    ProjectShopee.Config.PersonalShops = {}
    ProjectShopee.Config.MoneyRatios = {
        ["Base.Money"] = 1,
        ["Base.MoneyBundle"] = 100
    }
    ProjectShopee.Config.Catalog = { Buy = {}, Sell = {}, Limits = {} }
    ProjectShopee.Config.BankBalances = {}
    ProjectShopee.Config.TransactionLogs = {}
    
    local mode = ""
    local currentPos = ""
    local line = reader:readLine()
    local lastPos = nil
    
    while line ~= nil do
        line = trim(line)
        if line == "SHOPS" or line == "CHECKOUTS" or line == "ATMS" or line == "MONEY_RATIOS" or line == "PS_WHITELIST" or line == "PERSONAL_SHOPS" or line == "CATALOG_BUY" or line == "CATALOG_SELL" or line == "CATALOG_LIMITS" or line == "BANK_BALANCES" or line == "TRANSACTION_LOGS" then
            mode = line
        elseif line ~= "" then
            if mode == "SHOPS" then
                if string.sub(line, 1, 5) == "ITEM=" then
                    local item = string.sub(line, 6)
                    if lastPos and type(ProjectShopee.Config.Shops[lastPos]) == "table" then
                        ProjectShopee.Config.Shops[lastPos].Items[item] = true
                    end
                elseif string.sub(line, 1, 5) == "NAME=" then
                    local name = string.sub(line, 6)
                    if lastPos and type(ProjectShopee.Config.Shops[lastPos]) == "table" then
                        ProjectShopee.Config.Shops[lastPos].Name = name
                    end
                else
                    ProjectShopee.Config.Shops[line] = { Items = {} }
                    lastPos = line
                end
            elseif mode == "CHECKOUTS" then
                ProjectShopee.Config.Checkouts[line] = true
            elseif mode == "ATMS" then
                ProjectShopee.Config.ATMs[line] = true
            elseif mode == "MONEY_RATIOS" then
                local equalsPos = string.find(line, "=")
                if equalsPos then
                    local item = string.sub(line, 1, equalsPos - 1)
                    local ratio = tonumber(string.sub(line, equalsPos + 1))
                    if item and ratio then
                        ProjectShopee.Config.MoneyRatios[item] = ratio
                    end
                end
            elseif mode == "PS_WHITELIST" then
                ProjectShopee.Config.PersonalShopWhitelist[line] = true
            elseif mode == "PERSONAL_SHOPS" then
                if string.sub(line, 1, 4) == "POS=" then
                    currentPos = string.sub(line, 5)
                    ProjectShopee.Config.PersonalShops[currentPos] = {
                        Owner = "",
                        Earnings = 0,
                        Stock = {},
                        Logs = {}
                    }
                elseif string.sub(line, 1, 6) == "OWNER=" and currentPos ~= "" then
                    ProjectShopee.Config.PersonalShops[currentPos].Owner = string.sub(line, 7)
                elseif string.sub(line, 1, 5) == "NAME=" and currentPos ~= "" then
                    ProjectShopee.Config.PersonalShops[currentPos].Name = string.sub(line, 6)
                elseif string.sub(line, 1, 7) == "ISOPEN=" and currentPos ~= "" then
                    ProjectShopee.Config.PersonalShops[currentPos].IsOpen = (string.sub(line, 8) == "true")
                elseif string.sub(line, 1, 9) == "EARNINGS=" and currentPos ~= "" then
                    ProjectShopee.Config.PersonalShops[currentPos].Earnings = tonumber(string.sub(line, 10)) or 0
                elseif string.sub(line, 1, 4) == "LOG=" and currentPos ~= "" then
                    table.insert(ProjectShopee.Config.PersonalShops[currentPos].Logs, string.sub(line, 5))
                elseif string.sub(line, 1, 5) == "ITEM=" and currentPos ~= "" then
                    local parts = {}
                    for match in string.gmatch(string.sub(line, 6), "[^,]+") do table.insert(parts, match) end
                    if #parts == 3 then
                        ProjectShopee.Config.PersonalShops[currentPos].Stock[parts[1]] = {
                            Count = tonumber(parts[2]) or 1,
                            Price = tonumber(parts[3]) or 1
                        }
                    end
                end
            elseif mode == "CATALOG_BUY" then
                local equalsPos = string.find(line, "=")
                if equalsPos then
                    local item = string.sub(line, 1, equalsPos - 1)
                    local price = tonumber(string.sub(line, equalsPos + 1))
                    if item and price then
                        ProjectShopee.Config.Catalog.Buy[item] = price
                    end
                end
            elseif mode == "CATALOG_SELL" then
                local equalsPos = string.find(line, "=")
                if equalsPos then
                    local item = string.sub(line, 1, equalsPos - 1)
                    local price = tonumber(string.sub(line, equalsPos + 1))
                    if item and price then
                        ProjectShopee.Config.Catalog.Sell[item] = price
                    end
                end
            elseif mode == "CATALOG_LIMITS" then
                local equalsPos = string.find(line, "=")
                if equalsPos then
                    local item = string.sub(line, 1, equalsPos - 1)
                    local limit = tonumber(string.sub(line, equalsPos + 1))
                    if item and limit then
                        ProjectShopee.Config.Catalog.Limits[item] = limit
                    end
                end
            elseif mode == "BANK_BALANCES" then
                local equalsPos = string.find(line, "=")
                if equalsPos then
                    local username = string.sub(line, 1, equalsPos - 1)
                    local balance = tonumber(string.sub(line, equalsPos + 1))
                    if username and balance then
                        ProjectShopee.Config.BankBalances[username] = balance
                    end
                end
            elseif mode == "TRANSACTION_LOGS" then
                table.insert(ProjectShopee.Config.TransactionLogs, line)
            end
        end
        line = reader:readLine()
    end
    
    reader:close()
    
    print("Project Shopee: Loaded Config from File!")
    for k, v in pairs(ProjectShopee.Config.Shops) do
        print("Project Shopee: Shop loaded at: " .. tostring(k))
    end
end
Events.OnInitGlobalModData.Add(LoadConfig)

local function SyncPlayerBalance(player)
    local username = player:getUsername()
    local balance = ProjectShopee.Config.BankBalances[username] or 0
    sendServerCommand(player, "ProjectShopee", "SyncBalance", {balance=balance})
end

local function LogTransaction(logStr)
    ProjectShopee.Config.TransactionLogs = ProjectShopee.Config.TransactionLogs or {}
    table.insert(ProjectShopee.Config.TransactionLogs, 1, logStr)
    -- Cap at 200 logs
    if #ProjectShopee.Config.TransactionLogs > 200 then
        table.remove(ProjectShopee.Config.TransactionLogs)
    end
end

local PlayerCooldowns = {}

local function OnClientCommand(module, command, player, args)
    if module ~= "ProjectShopee" then return end

    -- Rate limiting: 100ms minimum between requests for transactions
    local isTransaction = (command == ProjectShopee.Commands.BuyItem) or 
                          (command == ProjectShopee.Commands.SellItem) or 
                          (command == ProjectShopee.Commands.CheckoutCart) or 
                          (command == ProjectShopee.Commands.DepositMoney) or 
                          (command == ProjectShopee.Commands.TransferMoney) or
                          (command == ProjectShopee.Commands.BuyFromPersonalShop)

    if isTransaction then
        local username = player:getUsername()
        local now = getTimestampMs()
        if PlayerCooldowns[username] and now - PlayerCooldowns[username] < 100 then
            return
        end
        PlayerCooldowns[username] = now
    end

    if command == ProjectShopee.Commands.RequestConfig then
        local username = player:getUsername()
        if ProjectShopee.Config.BankBalances[username] == nil then
            ProjectShopee.Config.BankBalances[username] = 0
            SaveConfig()
        end
        print("Project Shopee: Received RequestConfig from " .. player:getUsername())
        sendServerCommand(player, "ProjectShopee", ProjectShopee.Commands.SyncConfig, ProjectShopee.Config)
        SyncPlayerBalance(player)
    
    elseif command == ProjectShopee.Commands.AddShop then
        if player:getAccessLevel() ~= "admin" then return end
        ProjectShopee.Config.Shops[args.pos] = { Items = {} }
        SaveConfig()
        BroadcastConfig()
        
    elseif command == ProjectShopee.Commands.RemoveShop then
        if player:getAccessLevel() ~= "admin" then return end
        ProjectShopee.Config.Shops[args.pos] = nil
        SaveConfig()
        BroadcastConfig()
        
    elseif command == ProjectShopee.Commands.RenameShop then
        if player:getAccessLevel() ~= "admin" then return end
        if ProjectShopee.Config.Shops[args.pos] then
            ProjectShopee.Config.Shops[args.pos].Name = args.name
            SaveConfig()
            BroadcastConfig()
        end
        
    elseif command == ProjectShopee.Commands.UpdateTileStock then
        if player:getAccessLevel() ~= "admin" then return end
        if ProjectShopee.Config.Shops[args.pos] then
            ProjectShopee.Config.Shops[args.pos].Items = args.Items
            SaveConfig()
            BroadcastConfig()
        end

    elseif command == ProjectShopee.Commands.AddCheckout then
        if player:getAccessLevel() ~= "admin" then return end
        ProjectShopee.Config.Checkouts[args.pos] = true
        SaveConfig()
        BroadcastConfig()
        
    elseif command == ProjectShopee.Commands.RemoveCheckout then
        if player:getAccessLevel() ~= "admin" then return end
        ProjectShopee.Config.Checkouts[args.pos] = nil
        SaveConfig()
        BroadcastConfig()

    elseif command == ProjectShopee.Commands.AddATM then
        if player:getAccessLevel() ~= "admin" then return end
        ProjectShopee.Config.ATMs[args.pos] = true
        SaveConfig()
        BroadcastConfig()
        
    elseif command == ProjectShopee.Commands.RemoveATM then
        if player:getAccessLevel() ~= "admin" then return end
        ProjectShopee.Config.ATMs[args.pos] = nil
        SaveConfig()
        BroadcastConfig()
        
    elseif command == ProjectShopee.Commands.UpdateMoneyRatios then
        if player:getAccessLevel() ~= "admin" then return end
        ProjectShopee.Config.MoneyRatios = args.Ratios
        SaveConfig()
        BroadcastConfig()
        
    elseif command == ProjectShopee.Commands.DepositMoney then
        local depositItems = args.items -- e.g. { ["Base.Money"] = 10, ["Base.MoneyBundle"] = 2 }
        local totalDeposited = 0
        local inv = player:getInventory()
        
        for itemType, amt in pairs(depositItems) do
            local amount = math.floor(tonumber(amt) or 0)
            local ratio = ProjectShopee.Config.MoneyRatios[itemType] or 0
            if ratio > 0 and amount > 0 then
                local count = inv:getCountType(itemType)
                if count >= amount then
                    local remaining = amount
                    while remaining > 0 do
                        local item = inv:FindAndReturn(itemType)
                        if item then
                            inv:Remove(item)
                            sendServerCommand(player, "ProjectShopee", "ClientRemoveItem", {itemType=itemType, amount=1})
                            remaining = remaining - 1
                        else
                            break
                        end
                    end
                    totalDeposited = totalDeposited + ((amount - remaining) * ratio)
                end
            end
        end
        
        if totalDeposited > 0 then
            local username = player:getUsername()
            local prevBalance = ProjectShopee.Config.BankBalances[username] or 0
            local newBalance = prevBalance + totalDeposited
            ProjectShopee.Config.BankBalances[username] = newBalance
            
            local logStr = "[" .. os.date("%m-%d %H:%M") .. "] " .. username .. " DEPOSITED physical money for $" .. tostring(totalDeposited) .. " | Bal: $"..prevBalance.." -> $"..newBalance
            LogTransaction(logStr)
            
            ProjectShopee.NeedsSave = true
            
            sendServerCommand(player, "ProjectShopee", "ClientSay", {text="+$" .. tostring(totalDeposited) .. " (Deposit)", color={r=0, g=255, b=0}})
            SyncPlayerBalance(player)
        else
            sendServerCommand(player, "ProjectShopee", "ClientSay", {text="Failed to deposit.", color={r=255, g=0, b=0}})
        end

    elseif command == ProjectShopee.Commands.TransferMoney then
        local targetUser = args.target
        local amount = math.floor(tonumber(args.amount) or 0)
        if not targetUser or targetUser == "" or amount <= 0 then
            sendServerCommand(player, "ProjectShopee", "ClientSay", {text="Invalid transfer details.", color={r=255, g=0, b=0}})
            return
        end
        
        local username = player:getUsername()
        if username == targetUser then
            sendServerCommand(player, "ProjectShopee", "ClientSay", {text="You cannot transfer to yourself.", color={r=255, g=0, b=0}})
            return
        end
        
        local senderBalance = ProjectShopee.Config.BankBalances[username] or 0
        if ProjectShopee.Config.BankBalances[targetUser] == nil then
            sendServerCommand(player, "ProjectShopee", "ClientSay", {text="Target user does not exist or hasn't played recently.", color={r=255, g=0, b=0}})
            return
        end
        
        if senderBalance >= amount then
            local targetBalance = ProjectShopee.Config.BankBalances[targetUser] or 0
            
            ProjectShopee.Config.BankBalances[username] = senderBalance - amount
            ProjectShopee.Config.BankBalances[targetUser] = targetBalance + amount
            
            local logStr = "[" .. os.date("%m-%d %H:%M") .. "] " .. username .. " TRANSFERRED $" .. tostring(amount) .. " to " .. targetUser .. " | Bal: $"..senderBalance.." -> $"..(senderBalance - amount)
            LogTransaction(logStr)
            
            ProjectShopee.NeedsSave = true
            
            sendServerCommand(player, "ProjectShopee", "ClientSay", {text="Transferred $" .. tostring(amount) .. " to " .. targetUser, color={r=0, g=255, b=0}})
            SyncPlayerBalance(player)
            
            -- Sync target if online
            local players = getOnlinePlayers()
            if players then
                for i=0, players:size()-1 do
                    local p = players:get(i)
                    if p:getUsername() == targetUser then
                        SyncPlayerBalance(p)
                        sendServerCommand(p, "ProjectShopee", "ClientSay", {text="Received $" .. tostring(amount) .. " from " .. username, color={r=0, g=255, b=0}})
                        break
                    end
                end
            end
            
        else
            sendServerCommand(player, "ProjectShopee", "ClientSay", {text="Insufficient digital balance for transfer.", color={r=255, g=0, b=0}})
        end

    elseif command == ProjectShopee.Commands.UpdateCatalog then
        if player:getAccessLevel() ~= "admin" then return end
        ProjectShopee.Config.Catalog = args.Catalog
        SaveConfig()
        BroadcastConfig()

    elseif command == ProjectShopee.Commands.AdminRequestLogs then
        if player:getAccessLevel() ~= "admin" then return end
        sendServerCommand(player, "ProjectShopee", ProjectShopee.Commands.SyncLogs, ProjectShopee.Config.TransactionLogs or {})

    elseif command == ProjectShopee.Commands.AdminSetMoney then
        if player:getAccessLevel() ~= "admin" then return end
        local targetUser = args.username
        local newBalance = tonumber(args.balance)
        if targetUser and newBalance then
            local prevBalance = ProjectShopee.Config.BankBalances[targetUser] or 0
            ProjectShopee.Config.BankBalances[targetUser] = newBalance
            local logStr = "[" .. os.date("%m-%d %H:%M") .. "] ADMIN (" .. player:getUsername() .. ") SET " .. targetUser .. "'s balance to $" .. tostring(newBalance) .. " | Bal: $"..prevBalance.." -> $"..newBalance
            LogTransaction(logStr)
            SaveConfig()
            -- Sync to target if they are online
            local players = getOnlinePlayers()
            if players then
                for i=0, players:size()-1 do
                    local p = players:get(i)
                    if p:getUsername() == targetUser then
                        SyncPlayerBalance(p)
                        sendServerCommand(p, "ProjectShopee", "ClientSay", {text="Balance Updated!", color={r=0, g=255, b=0}})
                        break
                    end
                end
            end
            -- Send updated config back to the admin who just did it
            sendServerCommand(player, "ProjectShopee", ProjectShopee.Commands.SyncConfig, ProjectShopee.Config)
        end

    elseif command == ProjectShopee.Commands.BuyItem then
        local itemName = args.item
        local amount = math.floor(tonumber(args.amount) or 0)
        
        -- Server-side enforcement of limits
        local limit = 50
        if ProjectShopee.Config.Catalog.Limits and ProjectShopee.Config.Catalog.Limits[itemName] then
            limit = ProjectShopee.Config.Catalog.Limits[itemName]
        end
        if amount <= 0 or amount > limit then return end
        
        local pricePaid = ProjectShopee.Config.Catalog.Buy[itemName]
        if not pricePaid then return end
        
        local totalCost = pricePaid * amount
        
        local username = player:getUsername()
        local balance = ProjectShopee.Config.BankBalances[username] or 0
        
        if balance >= totalCost then
            local prevBalance = balance
            local newBalance = balance - totalCost
            ProjectShopee.Config.BankBalances[username] = newBalance
            
            local logStr = "[" .. os.date("%m-%d %H:%M") .. "] " .. username .. " BOUGHT " .. tostring(amount) .. "x " .. itemName .. " for $" .. tostring(totalCost) .. " | Bal: $"..prevBalance.." -> $"..newBalance
            LogTransaction(logStr)
            
            ProjectShopee.NeedsSave = true
            
            local square = player:getSquare() or getCell():getGridSquare(math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ()))
            
            if square then
                for i=1, amount do
                    square:AddWorldInventoryItem(itemName, 0.5, 0.5, 0.0)
                end
            else
                for i=1, amount do
                    player:getInventory():AddItem(itemName)
                end
            end
            
            sendServerCommand(player, "ProjectShopee", "ClientSyncInventory", {})
            sendServerCommand(player, "ProjectShopee", "ClientSay", {text="-$" .. tostring(totalCost), color={r=255, g=0, b=0}})
            SyncPlayerBalance(player)
        end
        
    elseif command == ProjectShopee.Commands.CheckoutCart then
        local cart = args.cart
        if not cart then return end
        
        local totalCost = 0
        local itemsStrList = {}
        local sanitizedCart = {}
        for _, cartItem in ipairs(cart) do
            local amt = math.floor(tonumber(cartItem.amount) or 0)
            
            -- Server-side enforcement of limits
            local limit = 50
            if ProjectShopee.Config.Catalog.Limits and ProjectShopee.Config.Catalog.Limits[cartItem.item] then
                limit = ProjectShopee.Config.Catalog.Limits[cartItem.item]
            end
            if amt > limit then amt = limit end
            
            if amt > 0 then
                local realPrice = ProjectShopee.Config.Catalog.Buy[cartItem.item] or 0
                totalCost = totalCost + (realPrice * amt)
                table.insert(itemsStrList, tostring(amt) .. "x " .. cartItem.item)
                table.insert(sanitizedCart, {item = cartItem.item, amount = amt})
            end
        end
        if totalCost <= 0 then return end
        local itemsStr = table.concat(itemsStrList, ", ")
        
        local username = player:getUsername()
        local balance = ProjectShopee.Config.BankBalances[username] or 0
        
        if balance >= totalCost then
            local prevBalance = balance
            local newBalance = balance - totalCost
            ProjectShopee.Config.BankBalances[username] = newBalance
            
            local logStr = "[" .. os.date("%m-%d %H:%M") .. "] " .. username .. " CHECKOUT (" .. itemsStr .. ") for $" .. tostring(totalCost) .. " | Bal: $"..prevBalance.." -> $"..newBalance
            LogTransaction(logStr)
            
            ProjectShopee.NeedsSave = true
            
            local square = player:getSquare() or getCell():getGridSquare(math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ()))
            
            for _, cartItem in ipairs(sanitizedCart) do
                if square then
                    for i=1, cartItem.amount do
                        square:AddWorldInventoryItem(cartItem.item, 0.5, 0.5, 0.0)
                    end
                else
                    for i=1, cartItem.amount do
                        player:getInventory():AddItem(cartItem.item)
                    end
                end
            end
            
            sendServerCommand(player, "ProjectShopee", "ClientSyncInventory", {})
            sendServerCommand(player, "ProjectShopee", "ClientSay", {text="-$" .. tostring(totalCost), color={r=255, g=0, b=0}})
            SyncPlayerBalance(player)
        end
        
    elseif command == ProjectShopee.Commands.SellItem then
        local itemName = args.item
        local amount = math.floor(tonumber(args.amount) or 0)
        local price = ProjectShopee.Config.Catalog.Sell[itemName]
        
        if amount <= 0 or not price then return end
        
        local inv = player:getInventory()
        local count = inv:getCountType(itemName)
        
        if count >= amount then
            local remaining = amount
            while remaining > 0 do
                local item = inv:FindAndReturn(itemName)
                if item then
                    inv:Remove(item)
                    sendServerCommand(player, "ProjectShopee", "ClientRemoveItem", {itemType=itemName, amount=1})
                    remaining = remaining - 1
                else
                    break
                end
            end
            if remaining > 0 then
                print("Project Shopee: Failed to find enough items to sell!")
            end
            
            local totalMoney = (amount - remaining) * price
            local username = player:getUsername()
            local prevBalance = ProjectShopee.Config.BankBalances[username] or 0
            local newBalance = prevBalance + totalMoney
            ProjectShopee.Config.BankBalances[username] = newBalance
            
            local logStr = "[" .. os.date("%m-%d %H:%M") .. "] " .. username .. " SOLD " .. tostring(amount - remaining) .. "x " .. itemName .. " for $" .. tostring(totalMoney) .. " | Bal: $"..prevBalance.." -> $"..newBalance
            LogTransaction(logStr)
            
            ProjectShopee.NeedsSave = true
            
            sendServerCommand(player, "ProjectShopee", "ClientSay", {text="+$" .. tostring(totalMoney), color={r=0, g=255, b=0}})
            SyncPlayerBalance(player)
        end
        
    elseif command == ProjectShopee.Commands.AdminSetPSWhitelist then
        if player:getAccessLevel() ~= "admin" then return end
        local newWhitelist = args.Whitelist
        ProjectShopee.Config.PersonalShopWhitelist = newWhitelist
        
        if ProjectShopee.Config.PersonalShops then
            for pos, data in pairs(ProjectShopee.Config.PersonalShops) do
                if not newWhitelist[data.Owner] then
                    ProjectShopee.Config.PersonalShops[pos] = nil
                end
            end
        end
        
        SaveConfig()
        BroadcastConfig()
        
    elseif command == ProjectShopee.Commands.RequestOpenCheckout then
        local pos = args.pos
        local username = player:getUsername()
        if not pos then return end
        
        if not ProjectShopee.ActiveCheckouts[pos] or ProjectShopee.ActiveCheckouts[pos] == username then
            ProjectShopee.ActiveCheckouts[pos] = username
            sendServerCommand(player, "ProjectShopee", "AllowOpenCheckout", {pos = pos})
        else
            sendServerCommand(player, "ProjectShopee", "DenyOpenCheckout", {pos = pos, message="Someone is already using this Checkout!"})
        end
        
    elseif command == ProjectShopee.Commands.CloseCheckout then
        local pos = args.pos
        local username = player:getUsername()
        if pos and ProjectShopee.ActiveCheckouts[pos] == username then
            ProjectShopee.ActiveCheckouts[pos] = nil
        end
        
    elseif command == ProjectShopee.Commands.RequestOpenATM then
        local pos = args.pos
        local username = player:getUsername()
        if not pos then return end
        
        if not ProjectShopee.ActiveATMs[pos] or ProjectShopee.ActiveATMs[pos] == username then
            ProjectShopee.ActiveATMs[pos] = username
            sendServerCommand(player, "ProjectShopee", "AllowOpenATM", {pos = pos})
        else
            sendServerCommand(player, "ProjectShopee", "DenyOpenATM", {pos = pos, message="Someone is already using this ATM!"})
        end
        
    elseif command == ProjectShopee.Commands.CloseATM then
        local pos = args.pos
        local username = player:getUsername()
        if pos and ProjectShopee.ActiveATMs[pos] == username then
            ProjectShopee.ActiveATMs[pos] = nil
        end
        
    elseif command == ProjectShopee.Commands.RequestOpenPersonalShop then
        local pos = args.pos
        local username = player:getUsername()
        if not pos then return end
        
        if not ProjectShopee.ActivePersonalShops[pos] or ProjectShopee.ActivePersonalShops[pos] == username then
            ProjectShopee.ActivePersonalShops[pos] = username
            sendServerCommand(player, "ProjectShopee", "AllowOpenPersonalShop", {pos = pos})
        else
            sendServerCommand(player, "ProjectShopee", "DenyOpenPersonalShop", {pos = pos, message="Someone is already browsing this Shop!"})
        end
        
    elseif command == ProjectShopee.Commands.ClosePersonalShop then
        local pos = args.pos
        local username = player:getUsername()
        if pos and ProjectShopee.ActivePersonalShops[pos] == username then
            ProjectShopee.ActivePersonalShops[pos] = nil
        end
        
    elseif command == ProjectShopee.Commands.CreatePersonalShop then
        local username = player:getUsername()
        if not ProjectShopee.Config.PersonalShopWhitelist[username] then return end
        
        for p, data in pairs(ProjectShopee.Config.PersonalShops) do
            if data.Owner == username then
                sendServerCommand(player, "ProjectShopee", "ClientSay", {text="You already have a Personal Shop!", color={r=255, g=0, b=0}})
                return
            end
        end
        
        ProjectShopee.Config.PersonalShops[args.pos] = {
            Owner = username,
            Name = username .. "'s Personal Shop",
            IsOpen = false,
            Earnings = 0,
            Stock = {}
        }
        SaveConfig()
        BroadcastConfig()
        sendServerCommand(player, "ProjectShopee", "ClientSay", {text="Personal Shop Created!", color={r=0, g=255, b=0}})
        
    elseif command == ProjectShopee.Commands.RemovePersonalShop then
        local username = player:getUsername()
        local shop = ProjectShopee.Config.PersonalShops[args.pos]
        if shop and (shop.Owner == username or player:getAccessLevel() == "admin") then
            ProjectShopee.Config.PersonalShops[args.pos] = nil
            SaveConfig()
            BroadcastConfig()
            sendServerCommand(player, "ProjectShopee", "ClientSay", {text="Personal Shop Removed.", color={r=255, g=255, b=0}})
        end
        
    elseif command == ProjectShopee.Commands.AddItemToPersonalShop then
        local username = player:getUsername()
        if not ProjectShopee.Config.PersonalShopWhitelist[username] then
            sendServerCommand(player, "ProjectShopee", "ClientSay", {text="You are no longer whitelisted to manage a shop.", color={r=255, g=0, b=0}})
            return
        end
        local shop = ProjectShopee.Config.PersonalShops[args.pos]
        if not shop or shop.Owner ~= username then return end
        
        local amount = math.floor(tonumber(args.amount) or 0)
        local price = math.floor(tonumber(args.price) or 1)
        if amount <= 0 or price < 0 then return end
        
        -- Check unique limit
        local uniqueItems = 0
        for k, v in pairs(shop.Stock) do uniqueItems = uniqueItems + 1 end
        if not shop.Stock[args.item] and uniqueItems >= 10 then
            sendServerCommand(player, "ProjectShopee", "ClientSay", {text="Max 10 unique items allowed!", color={r=255, g=0, b=0}})
            return
        end
        
        local inv = player:getInventory()
        local count = inv:getCountType(args.item)
        if count >= amount then
            local remaining = amount
            while remaining > 0 do
                local itemObj = inv:FindAndReturn(args.item)
                if itemObj then
                    inv:Remove(itemObj)
                    sendServerCommand(player, "ProjectShopee", "ClientRemoveItem", {itemType=args.item, amount=1})
                    remaining = remaining - 1
                else
                    break
                end
            end
            
            local added = amount - remaining
            if added > 0 then
                if not shop.Stock[args.item] then
                    shop.Stock[args.item] = { Count = 0, Price = price }
                else
                    shop.Stock[args.item].Price = price -- Update price for all
                end
                shop.Stock[args.item].Count = shop.Stock[args.item].Count + added
                
                ProjectShopee.NeedsSave = true
                sendServerCommand(player, "ProjectShopee", "ClientSay", {text="Added " .. tostring(added) .. " to shop!", color={r=0, g=255, b=0}})
            end
        end
        
    elseif command == ProjectShopee.Commands.CollectPSEarnings then
        local username = player:getUsername()
        local shop = ProjectShopee.Config.PersonalShops[args.pos]
        if not shop or shop.Owner ~= username then return end
        
        local earnings = shop.Earnings or 0
        if earnings > 0 then
            shop.Earnings = 0
            local prevBalance = ProjectShopee.Config.BankBalances[username] or 0
            ProjectShopee.Config.BankBalances[username] = prevBalance + earnings
            
            local logStr = "[" .. os.date("%m-%d %H:%M") .. "] " .. username .. " COLLECTED $" .. tostring(earnings) .. " from Personal Shop | Bal: $"..prevBalance.." -> $"..(prevBalance + earnings)
            LogTransaction(logStr)
            
            ProjectShopee.NeedsSave = true
            SyncPlayerBalance(player)
            sendServerCommand(player, "ProjectShopee", "ClientSay", {text="Collected $" .. tostring(earnings) .. "!", color={r=0, g=255, b=0}})
        end
        
    elseif command == ProjectShopee.Commands.BuyFromPersonalShop then
        local shop = ProjectShopee.Config.PersonalShops[args.pos]
        if not shop then return end
        
        local amount = math.floor(tonumber(args.amount) or 0)
        if amount <= 0 then return end
        
        local itemData = shop.Stock[args.item]
        if not itemData or itemData.Count < amount then return end
        
        local username = player:getUsername()
        local balance = ProjectShopee.Config.BankBalances[username] or 0
        local totalCost = itemData.Price * amount
        
        if balance >= totalCost then
            -- Take money from buyer
            local prevBalance = balance
            ProjectShopee.Config.BankBalances[username] = balance - totalCost
            
            -- Add money to shop earnings
            shop.Earnings = (shop.Earnings or 0) + totalCost
            
            -- Remove item from shop stock
            itemData.Count = itemData.Count - amount
            if itemData.Count <= 0 then
                shop.Stock[args.item] = nil
            end
            
            -- Log transaction globally
            local logStr = "[" .. os.date("%m-%d %H:%M") .. "] " .. username .. " BOUGHT " .. tostring(amount) .. "x " .. args.item .. " from " .. shop.Owner .. "'s Shop for $" .. tostring(totalCost)
            LogTransaction(logStr)
            
            -- Log transaction locally to the shop owner
            shop.Logs = shop.Logs or {}
            local shopLogStr = "[" .. os.date("%m-%d %H:%M") .. "] " .. username .. " BOUGHT " .. tostring(amount) .. "x " .. args.item .. " for $" .. tostring(totalCost)
            table.insert(shop.Logs, 1, shopLogStr)
            if #shop.Logs > 100 then
                table.remove(shop.Logs)
            end
            
            ProjectShopee.NeedsSave = true
            
            -- Give item to buyer (Drop on floor)
            local square = player:getSquare() or getCell():getGridSquare(math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ()))
            
            if square then
                for i=1, amount do
                    square:AddWorldInventoryItem(args.item, 0.5, 0.5, 0.0)
                end
            else
                for i=1, amount do
                    player:getInventory():AddItem(args.item)
                end
            end
            
            sendServerCommand(player, "ProjectShopee", "ClientSyncInventory", {})
            sendServerCommand(player, "ProjectShopee", "ClientSay", {text="-$" .. tostring(totalCost), color={r=255, g=0, b=0}})
            SyncPlayerBalance(player)
        else
            sendServerCommand(player, "ProjectShopee", "ClientSay", {text="Insufficient balance!", color={r=255, g=0, b=0}})
        end

    elseif command == ProjectShopee.Commands.RenamePersonalShop then
        local username = player:getUsername()
        if not ProjectShopee.Config.PersonalShopWhitelist[username] then
            sendServerCommand(player, "ProjectShopee", "ClientSay", {text="You are no longer whitelisted to manage a shop.", color={r=255, g=0, b=0}})
            return
        end
        local shop = ProjectShopee.Config.PersonalShops[args.pos]
        if not shop or shop.Owner ~= username then return end
        
        shop.Name = args.name
        SaveConfig()
        BroadcastConfig()
        sendServerCommand(player, "ProjectShopee", "ClientSay", {text="Shop renamed to: " .. args.name, color={r=0, g=255, b=0}})

    elseif command == ProjectShopee.Commands.RemoveItemFromPersonalShop then
        local username = player:getUsername()
        local shop = ProjectShopee.Config.PersonalShops[args.pos]
        if not shop or shop.Owner ~= username then return end
        
        local amount = math.floor(tonumber(args.amount) or 0)
        if amount <= 0 then return end
        
        local itemData = shop.Stock[args.item]
        if not itemData or itemData.Count < amount then return end
        
        itemData.Count = itemData.Count - amount
        if itemData.Count <= 0 then
            shop.Stock[args.item] = nil
        end
        
        ProjectShopee.NeedsSave = true
        
        local square = player:getSquare() or getCell():getGridSquare(math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ()))
        if square then
            for i=1, amount do
                square:AddWorldInventoryItem(args.item, 0.5, 0.5, 0.0)
            end
        else
            for i=1, amount do
                player:getInventory():AddItem(args.item)
            end
        end
        sendServerCommand(player, "ProjectShopee", "ClientSyncInventory", {})
        sendServerCommand(player, "ProjectShopee", "ClientSay", {text="Removed " .. tostring(amount) .. "x " .. args.item, color={r=255, g=255, b=0}})

    elseif command == ProjectShopee.Commands.RelocatePersonalShop then
        local username = player:getUsername()
        if not ProjectShopee.Config.PersonalShopWhitelist[username] then return end
        
        local oldPos = nil
        local oldShop = nil
        for p, data in pairs(ProjectShopee.Config.PersonalShops) do
            if data.Owner == username then
                oldPos = p
                oldShop = data
                break
            end
        end
        
        if not oldShop then return end
        
        if oldShop.Earnings and oldShop.Earnings > 0 then
            sendServerCommand(player, "ProjectShopee", "ClientSay", {text="You must collect your earnings before relocating!", color={r=255, g=0, b=0}})
            return
        end
        
        local hasStock = false
        if oldShop.Stock then
            for k, v in pairs(oldShop.Stock) do
                if v.Count > 0 then
                    hasStock = true
                    break
                end
            end
        end
        
        if hasStock then
            sendServerCommand(player, "ProjectShopee", "ClientSay", {text="You must remove all items from your shop before relocating!", color={r=255, g=0, b=0}})
            return
        end
        
        
        ProjectShopee.Config.PersonalShops[oldPos] = nil
        ProjectShopee.Config.PersonalShops[args.newPos] = {
            Owner = username,
            Name = oldShop.Name,
            IsOpen = false,
            Earnings = 0,
            Stock = {}
        }
        
        SaveConfig()
        BroadcastConfig()
        sendServerCommand(player, "ProjectShopee", "ClientSay", {text="Shop Relocated Successfully!", color={r=0, g=255, b=0}})

    elseif command == ProjectShopee.Commands.TogglePersonalShopStatus then
        local username = player:getUsername()
        if not ProjectShopee.Config.PersonalShopWhitelist[username] then
            sendServerCommand(player, "ProjectShopee", "ClientSay", {text="You are no longer whitelisted to manage a shop.", color={r=255, g=0, b=0}})
            return
        end
        local shop = ProjectShopee.Config.PersonalShops[args.pos]
        if not shop or shop.Owner ~= username then return end
        
        if shop.IsOpen == nil then shop.IsOpen = true end
        shop.IsOpen = not shop.IsOpen
        
        SaveConfig()
        BroadcastConfig()
        local statusStr = shop.IsOpen and "Opened" or "Closed"
        sendServerCommand(player, "ProjectShopee", "ClientSay", {text="Shop is now " .. statusStr, color={r=0, g=255, b=0}})
    end
end
Events.OnClientCommand.Add(OnClientCommand)

local function CleanupActiveCheckouts()
    local onlinePlayers = getOnlinePlayers()
    local onlineNames = {}
    if onlinePlayers then
        for i=0, onlinePlayers:size()-1 do
            local p = onlinePlayers:get(i)
            if p then
                onlineNames[p:getUsername()] = p
            end
        end
    end
    
    for pos, username in pairs(ProjectShopee.ActiveCheckouts) do
        local p = onlineNames[username]
        if not p then
            -- Player disconnected
            ProjectShopee.ActiveCheckouts[pos] = nil
        else
            -- Check distance
            local parts = {}
            for part in string.gmatch(pos, "([^,]+)") do table.insert(parts, tonumber(part)) end
            if #parts == 3 then
                local dx = p:getX() - parts[1]
                local dy = p:getY() - parts[2]
                local dz = p:getZ() - parts[3]
                local dist = math.sqrt(dx*dx + dy*dy)
                if dist > 5 or dz ~= 0 then
                    ProjectShopee.ActiveCheckouts[pos] = nil
                end
            else
                ProjectShopee.ActiveCheckouts[pos] = nil
            end
        end
    end
end
Events.EveryOneMinute.Add(CleanupActiveCheckouts)
