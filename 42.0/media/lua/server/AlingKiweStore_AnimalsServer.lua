if not isServer() then return end

local function findAnimalDef(animalTypeStr)
    if not animalTypeStr or animalTypeStr == "" then return nil end
    
    -- 1. Direct lookup
    if AnimalDefinitions and AnimalDefinitions.getDef then
        local ok, def = pcall(AnimalDefinitions.getDef, animalTypeStr)
        if ok and def then return def end
        
        -- Try lowercase / uppercase
        ok, def = pcall(AnimalDefinitions.getDef, string.lower(animalTypeStr))
        if ok and def then return def end
    end
    
    -- 2. Scan all definitions
    if getAllAnimalsDefinitions then
        local defs = getAllAnimalsDefinitions()
        if defs then
            local lowerTarget = string.lower(animalTypeStr)
            for i = 0, defs:size() - 1 do
                local def = defs:get(i)
                local curType = string.lower(tostring(def:getAnimalType() or ""))
                if curType == lowerTarget or string.find(curType, lowerTarget) or string.find(lowerTarget, curType) then
                    return def
                end
            end
        end
    end
    
    return nil
end

local function findBreed(def, breedNameStr)
    if not def then return nil end
    
    -- 1. Direct lookup by name
    if def.getBreedByName and breedNameStr and breedNameStr ~= "" then
        local ok, breed = pcall(def.getBreedByName, def, breedNameStr)
        if ok and breed then return breed end
        
        ok, breed = pcall(def.getBreedByName, def, string.lower(breedNameStr))
        if ok and breed then return breed end
    end
    
    -- 2. Scan breeds list
    if def.getBreeds then
        local breeds = def:getBreeds()
        if breeds and breeds:size() > 0 then
            if breedNameStr and breedNameStr ~= "" then
                local lowerName = string.lower(breedNameStr)
                for i = 0, breeds:size() - 1 do
                    local b = breeds:get(i)
                    local bName = string.lower(tostring(b:getName() or ""))
                    if bName == lowerName or string.find(bName, lowerName) then
                        return b
                    end
                end
            end
            -- Fallback to first breed
            return breeds:get(0)
        end
    end
    
    return nil
end

local function OnClientCommand(module, command, playerObj, args)
    if module == "AlingKiweAnimals" and command == "BuyAnimal" then
        local targetType = args.targetType or args.animalType -- e.g. "cowcalf", "cow", "sow"
        local animalType = args.animalType -- e.g. "cow", "pig", "sheep", "chicken"
        local breedName = args.breedName   -- e.g. "Holstein", "Yorkshire"
        local price = tonumber(args.price) or 1000
        
        local username = playerObj:getUsername()
        local balance = ProjectShopee.Config.BankBalances[username] or 0
        
        if balance < price then
            sendServerCommand(playerObj, "ProjectShopee", "ClientSay", {text="Insufficient digital balance for this animal.", color={r=255, g=0, b=0}})
            return
        end
        
        local cell = getCell()
        if not cell or not addAnimal then
            sendServerCommand(playerObj, "ProjectShopee", "ClientSay", {text="Server Error: Animal spawning API unavailable.", color={r=255, g=0, b=0}})
            return
        end
        
        -- Find Definition
        local def = findAnimalDef(animalType) or findAnimalDef(targetType)
        if not def then
            -- Print all available to server log for diagnosis
            if getAllAnimalsDefinitions then
                local defs = getAllAnimalsDefinitions()
                print("AlingKiweStore: Available animal types on server:")
                for i = 0, defs:size() - 1 do
                    print(" - " .. tostring(defs:get(i):getAnimalType()))
                end
            end
            sendServerCommand(playerObj, "ProjectShopee", "ClientSay", {text="Internal Error: Animal type not recognized: " .. tostring(animalType), color={r=255, g=0, b=0}})
            return
        end
        
        -- Find Breed
        local breedObj = findBreed(def, breedName)
        if not breedObj then
            sendServerCommand(playerObj, "ProjectShopee", "ClientSay", {text="Internal Error: No breed found for: " .. tostring(animalType), color={r=255, g=0, b=0}})
            return
        end
        
        local spawnType = tostring(def:getAnimalType())
        
        local x = math.floor(playerObj:getX())
        local y = math.floor(playerObj:getY())
        local z = math.floor(playerObj:getZ())
        local psq = playerObj:getSquare()
        
        local function spawnOnSquare(square)
            if not square then return nil end
            
            -- Try with targetType first (e.g. cowcalf, sow)
            local ok, animal = pcall(addAnimal, cell, square:getX(), square:getY(), square:getZ(), targetType, breedObj)
            if not ok or not animal then
                -- Try with spawnType (e.g. cow, pig)
                ok, animal = pcall(addAnimal, cell, square:getX(), square:getY(), square:getZ(), spawnType, breedObj)
            end
            
            if ok and animal then
                if animal.addToWorld then
                    pcall(animal.addToWorld, animal)
                end
                return animal
            end
            return nil
        end
        
        local animal = spawnOnSquare(psq)
        if not animal then
            -- Try surrounding squares
            for i = 1, 15 do
                local sq = cell:getGridSquare(x + ZombRand(-3, 4), y + ZombRand(-3, 4), z)
                animal = spawnOnSquare(sq)
                if animal then break end
            end
        end
        
        if animal then
            -- Deduct money
            local newBalance = balance - price
            ProjectShopee.Config.BankBalances[username] = newBalance
            sendServerCommand(playerObj, "ProjectShopee", "SyncBalance", {balance=newBalance})
            sendServerCommand(playerObj, "ProjectShopee", "ClientSay", {text="Animal purchased! -$" .. tostring(price), color={r=0, g=255, b=0}})
            
            local logStr = "[" .. os.date("%m-%d %H:%M") .. "] " .. username .. " BOUGHT " .. tostring(targetType) .. " (" .. tostring(breedObj:getName()) .. ") for $" .. tostring(price) .. " | Bal: $"..balance.." -> $"..newBalance
            ProjectShopee.Config.TransactionLogs = ProjectShopee.Config.TransactionLogs or {}
            table.insert(ProjectShopee.Config.TransactionLogs, 1, logStr)
            if #ProjectShopee.Config.TransactionLogs > 200 then
                table.remove(ProjectShopee.Config.TransactionLogs)
            end
        else
            sendServerCommand(playerObj, "ProjectShopee", "ClientSay", {text="Failed to spawn animal. Make sure there is clear floor space nearby.", color={r=255, g=0, b=0}})
        end
    end
end

Events.OnClientCommand.Add(OnClientCommand)
