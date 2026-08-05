import sys

file_path = r'd:\Documents\Aling Kiwe Shop Test\42.0\media\lua\server\ShopServer.lua'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Cart limit
content = content.replace(
'''    elseif command == ProjectShopee.Commands.CheckoutCart then
        local cart = args.cart
        if not cart then return end''',
'''    elseif command == ProjectShopee.Commands.CheckoutCart then
        local cart = args.cart
        if not cart then return end
        if #cart > 50 then return end'''
)

# 2. SaveConfig
content = content.replace(
'''local function SaveConfig()
    ModData.transmit("ProjectShopee")
    ProjectShopee.NeedsSave = false
end''',
'''local function SaveConfig()
    ProjectShopee.NeedsSave = false
end'''
)

# 3. Targeted Syncs
content = content.replace(
'''        if not ProjectShopee.ActiveCheckouts[pos] or ProjectShopee.ActiveCheckouts[pos] == username then
            ProjectShopee.ActiveCheckouts[pos] = username
            sendServerCommand(player, "ProjectShopee", "AllowOpenCheckout", {pos = pos})''',
'''        if not ProjectShopee.ActiveCheckouts[pos] or ProjectShopee.ActiveCheckouts[pos] == username then
            ProjectShopee.ActiveCheckouts[pos] = username
            sendServerCommand(player, "ProjectShopee", ProjectShopee.Commands.SyncConfig, ProjectShopee.Config)
            sendServerCommand(player, "ProjectShopee", "AllowOpenCheckout", {pos = pos})'''
)

content = content.replace(
'''        if not ProjectShopee.ActiveATMs[pos] or ProjectShopee.ActiveATMs[pos] == username then
            ProjectShopee.ActiveATMs[pos] = username
            sendServerCommand(player, "ProjectShopee", "AllowOpenATM", {pos = pos})''',
'''        if not ProjectShopee.ActiveATMs[pos] or ProjectShopee.ActiveATMs[pos] == username then
            ProjectShopee.ActiveATMs[pos] = username
            sendServerCommand(player, "ProjectShopee", ProjectShopee.Commands.SyncConfig, ProjectShopee.Config)
            sendServerCommand(player, "ProjectShopee", "AllowOpenATM", {pos = pos})'''
)

content = content.replace(
'''        if not ProjectShopee.ActivePersonalShops[pos] or ProjectShopee.ActivePersonalShops[pos] == username then
            ProjectShopee.ActivePersonalShops[pos] = username
            sendServerCommand(player, "ProjectShopee", "AllowOpenPersonalShop", {pos = pos})''',
'''        if not ProjectShopee.ActivePersonalShops[pos] or ProjectShopee.ActivePersonalShops[pos] == username then
            ProjectShopee.ActivePersonalShops[pos] = username
            sendServerCommand(player, "ProjectShopee", ProjectShopee.Commands.SyncConfig, ProjectShopee.Config)
            sendServerCommand(player, "ProjectShopee", "AllowOpenPersonalShop", {pos = pos})'''
)

# 4. Remove BroadcastConfig from transactions
content = content.replace(
'''            SaveConfig()
            BroadcastConfig()
            
            sendServerCommand(player, "ProjectShopee", "ClientSay", {text="+$" .. tostring(totalDeposited) .. " (Deposit)", color={r=0, g=255, b=0}})''',
'''            SaveConfig()
            
            sendServerCommand(player, "ProjectShopee", "ClientSay", {text="+$" .. tostring(totalDeposited) .. " (Deposit)", color={r=0, g=255, b=0}})'''
)

content = content.replace(
'''            SaveConfig()
            BroadcastConfig()
            
            sendServerCommand(player, "ProjectShopee", "ClientSay", {text="Transferred $" .. tostring(amount) .. " to " .. targetUser, color={r=0, g=255, b=0}})''',
'''            SaveConfig()
            
            sendServerCommand(player, "ProjectShopee", "ClientSay", {text="Transferred $" .. tostring(amount) .. " to " .. targetUser, color={r=0, g=255, b=0}})'''
)

content = content.replace(
'''            SaveConfig()
            BroadcastConfig()
            
            local square = player:getSquare() or getCell():getGridSquare(math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ()))''',
'''            SaveConfig()
            
            local square = player:getSquare() or getCell():getGridSquare(math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ()))'''
)

content = content.replace(
'''            SaveConfig()
            BroadcastConfig()
            
            sendServerCommand(player, "ProjectShopee", "ClientSay", {text="+$" .. tostring(totalMoney), color={r=0, g=255, b=0}})''',
'''            SaveConfig()
            
            sendServerCommand(player, "ProjectShopee", "ClientSay", {text="+$" .. tostring(totalMoney), color={r=0, g=255, b=0}})'''
)

content = content.replace(
'''                SaveConfig()
            BroadcastConfig()
                sendServerCommand(player, "ProjectShopee", "ClientSay", {text="Added " .. tostring(added) .. " to shop!", color={r=0, g=255, b=0}})''',
'''                SaveConfig()
                sendServerCommand(player, "ProjectShopee", ProjectShopee.Commands.SyncConfig, ProjectShopee.Config)
                sendServerCommand(player, "ProjectShopee", "ClientSay", {text="Added " .. tostring(added) .. " to shop!", color={r=0, g=255, b=0}})'''
)

content = content.replace(
'''            SaveConfig()
            BroadcastConfig()
            SyncPlayerBalance(player)
            sendServerCommand(player, "ProjectShopee", "ClientSay", {text="Collected $" .. tostring(earnings) .. "!", color={r=0, g=255, b=0}})''',
'''            SaveConfig()
            sendServerCommand(player, "ProjectShopee", ProjectShopee.Commands.SyncConfig, ProjectShopee.Config)
            SyncPlayerBalance(player)
            sendServerCommand(player, "ProjectShopee", "ClientSay", {text="Collected $" .. tostring(earnings) .. "!", color={r=0, g=255, b=0}})'''
)

content = content.replace(
'''            SaveConfig()
            BroadcastConfig()
            
            -- Give item to buyer (Drop on floor)''',
'''            SaveConfig()
            sendServerCommand(player, "ProjectShopee", ProjectShopee.Commands.SyncConfig, ProjectShopee.Config)
            
            -- Give item to buyer (Drop on floor)'''
)

content = content.replace(
'''        SaveConfig()
            BroadcastConfig()
        
        local square = player:getSquare() or getCell():getGridSquare(math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ()))''',
'''        SaveConfig()
        sendServerCommand(player, "ProjectShopee", ProjectShopee.Commands.SyncConfig, ProjectShopee.Config)
        
        local square = player:getSquare() or getCell():getGridSquare(math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ()))'''
)


with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
