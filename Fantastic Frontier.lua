local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Fantastic Frontier",
    Icon = 0, 
    LoadingTitle = "Fantastic Frontier",
    LoadingSubtitle = "by Bartus",
    Theme = "Default", 
 
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false, 
 
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "FantasticFrontier",
        FileName = "FantasticCFG"
    },
 
    Discord = {
        Enabled = false, 
        Invite = "noinvitelink", 
        RememberJoins = true 
    },
 
    KeySystem = false, 
    KeySettings = {
        Title = "Untitled",
        Subtitle = "Key System",
        Note = "No method of obtaining the key is provided", 
        FileName = "Key", 
        SaveKey = true, 
        GrabKeyFromSite = false, 
        Key = {"Hello"} 
    }
})

---------------------------------------------------------------------------------------
--VARIABLES
--Functions
local speed = 150
local flySpeed = 150
local sellLocation = Vector3.new(713, 228, -482)
local RabbitHole = Vector3.new(-3156, 250, -2552) 
local Mutamanda = Vector3.new(-2250, 0, -1162)
local MainHall = Vector3.new(5936 , 176, 4844)
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
--Fishing
local Fishing = false
local Refish = true
local AutoOpen = false
local rodConnections = {}
--Selling
local Selling = false
local autoSell = false
local platformCreated = false
local TotalValue = 0
local OverallEarned = 0
local SellAt = 15
local Items = 0
--Monsters
local Fighting = false
local aimOffset = Vector3.new(0, 2, 0)
local aimSmoothing = 0
local isAttacking = false
local attackInterval = 0.2
local lastAttackTime = 0
local maxAttackDistance = 50
--Lost
local autoLost = false
local Lost = nil
local followDistance = -20
local heightOffset = -20
local smoothing = 0
local Reward = Vector3.new(12542.5, 249.5, -2361.9)
local LostExit = Vector3.new(12526.5, 251.5, -2350.5)
--Circus

--Visuals
--Npc's

local espEnabled = false

local npcConfigs = {
    {
        object = workspace.SM.Door_SMEntrance.SMEntranceModel, 
        displayName = "Strangeman",
        color = Color3.fromRGB(166, 0, 255),
        showDistance = true
    },
    {
        object = workspace.PassiveNPCs:WaitForChild("NPC_Stick"),
        displayName = "Stick",
        color = Color3.fromRGB(0, 255, 0),
        showDistance = true
    },
    {
        object = workspace.PassiveNPCs:WaitForChild("NPC_Junkman"),
        displayName = "Junkman",
        color = Color3.fromRGB(255, 170, 0),
        showDistance = true
    },
    {
        object = workspace.PassiveNPCs:WaitForChild("NPC_Construct"),
        displayName = "Construct",
        color = Color3.fromRGB(255, 81, 0),
        showDistance = true
    },
    {
        object = workspace.PassiveNPCs:WaitForChild("NPC_Vhitmire"),
        displayName = "Vhitmire",
        color = Color3.fromRGB(100, 100, 100),
        showDistance = true
    },
}


local textSize = 18
local activeHighlights = {}
---------------------------------------------------------------------------------------
--FUNCTIONS
--Webhook
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function sendInventoryWebhook()
    local player = Players.LocalPlayer
    local inventory = player:WaitForChild("Inventory")
    local itemInfoFolder = ReplicatedStorage:WaitForChild("ItemInfo")
    
    -- Get gold value
    local stats = player:WaitForChild("Stats")
    local gold = stats:WaitForChild("Gold")
    local goldValue = gold.Value
    
    local inventoryFields = {}
    local totalValue = 0
    
    for _, itemSlot in pairs(inventory:GetChildren()) do
        local itemCode = itemSlot.Value
        if itemCode ~= 0 then 
            local itemData = itemInfoFolder:FindFirstChild(tostring(itemCode))
            if itemData then
                local name = itemData:FindFirstChild("FullName")
                local value = itemData:FindFirstChild("SellValue")
                if name and value then
                    table.insert(inventoryFields, {
                        name = name.Value,
                        value = string.format("💵 Value: $%d", value.Value),
                        inline = true
                    })
                    totalValue = totalValue + value.Value
                end
            end
        end
    end
    
    local success, response = request({
        Url = "https://discord.com/api/webhooks/1368300280193745076/85zkCfWStQekxuadO0F-zphwm9PFc7g09bo2D2PdVRdWomFepg3qPtcfWFZQjRl3dWEP",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = HttpService:JSONEncode({
            embeds = {{
                title = "📦 Player Inventory Report",
                description = string.format(
                    "%s's Inventory\n📦 Total Inventory Value: $%d\n💰 Current Gold: $%d",
                    player.DisplayName,
                    totalValue,
                    goldValue
                ),
                color = 0x00FF00,
                fields = inventoryFields,
                timestamp = DateTime.now():ToIsoDate()
            }}
        })
    })
    
    if not success then
        warn("Failed to send inventory webhook:", response)
    end
end


--Flying
local function flyToTarget(startPos, endPos, speed)
    local char = game.Players.LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    
    local totalDistance = (endPos - startPos).magnitude
    local flightTime = totalDistance / speed

    local startTime = tick()
    local endTime = startTime + flightTime

    while tick() < endTime do
        local elapsedTime = tick() - startTime
        local distanceTraveled = speed * elapsedTime
        local newPos = startPos + (endPos - startPos).unit * distanceTraveled
        hrp.CFrame = CFrame.new(newPos)
        wait(0.03)
    end
    hrp.CFrame = CFrame.new(endPos)
end

--Selling
local function sellItems(itemsToSell)
    if Selling or Fighting then return end
    Selling = true

    sendInventoryWebhook()

    wait(3)

    local player = game.Players.LocalPlayer
    local char = player.Character
    if not (char and char:FindFirstChild("HumanoidRootPart")) then return end

    local startPos = char.HumanoidRootPart.Position

    if not platformCreated then
        local platform = Instance.new("Part")
        platform.Size = Vector3.new(4, 1, 4)
        platform.Position = startPos - Vector3.new(0, 3, 0)
        platform.Anchored = true
        platform.Transparency = 0
        platform.CanCollide = true
        platform.Name = "AntiVoidPlatform"
        platform.Parent = workspace

        local platform2 = Instance.new("Part")
        platform2.Size = Vector3.new(4, 1, 4)
        platform2.Position = Vector3.new(sellLocation.X, sellLocation.Y - 3, sellLocation.Z)
        platform2.Anchored = true
        platform2.Transparency = 0
        platform2.CanCollide = true
        platform2.Name = "SellPlatform"
        platform2.Parent = workspace

        platformCreated = true
    end

    flyToTarget(startPos, sellLocation, flySpeed)

    for _, item in pairs(itemsToSell) do
        if game.ReplicatedStorage.ItemInfo:FindFirstChild(tostring(item.Value)) then
            local itemInfo = game.ReplicatedStorage.ItemInfo[tostring(item.Value)]
            if itemInfo.SellValue.Value > 50 then
                game.ReplicatedStorage.Events.SellShop:FireServer(item.Value, workspace.Shops.Sellers, 1)
                OverallEarned = OverallEarned + itemInfo.SellValue.Value
                wait(0.1)
            end
        end
    end

    wait(5)
    flyToTarget(sellLocation, startPos, flySpeed)
    Selling = false
    wait(0.1)
    mouse1click()
end

--Lost

local function LostChest()
    local guttermouth = workspace:FindFirstChild("Guttermouth")
    if not guttermouth then return nil end

    local room4 = guttermouth:FindFirstChild("GuttermouthRoom4")
    if not room4 then return nil end

    local monsters = room4:FindFirstChild("Monsters")
    return monsters
end

RunService.Heartbeat:Connect(function()
    local monsters = LostChest()
    if monsters then
        local phantomKnight = monsters:FindFirstChild("PhantomKnightNPC")
        if phantomKnight then
            local hrp = phantomKnight:FindFirstChild("HumanoidRootPart")
            if hrp then
                Lost = hrp
            else
                Lost = nil
            end
        else
            Lost = nil
        end
    else
        Lost = nil
    end
end)

--Follow
local lastSeenLostTime = 0

local function followAndAim(dt)
    if not autoLost or Selling then
        return 
    end

    local currentTime = os.clock()

    if Lost then
        lastSeenLostTime = currentTime

        local targetPart = Lost
        local targetCFrame = targetPart.CFrame
        local desiredPosition = targetCFrame * CFrame.new(0, heightOffset, followDistance)

        if smoothing > 0 then
            humanoidRootPart.CFrame = humanoidRootPart.CFrame:Lerp(desiredPosition, math.min(1, smoothing * (60 * dt)))
        else
            humanoidRootPart.CFrame = desiredPosition
        end

        local lookAtPosition = targetPart.Position + aimOffset
        local currentLook = humanoidRootPart.CFrame.LookVector
        local desiredLook = (lookAtPosition - humanoidRootPart.Position).Unit

        if aimSmoothing > 0 then
            local smoothedLook = currentLook:Lerp(desiredLook, math.min(1, aimSmoothing * (60 * dt)))
            humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position, humanoidRootPart.Position + smoothedLook)
        else
            humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position, lookAtPosition)
        end

        humanoidRootPart.AssemblyLinearVelocity = Vector3.new()
        humanoidRootPart.AssemblyAngularVelocity = Vector3.new()

        if humanoid then
            humanoid.AutoRotate = false
            humanoid:MoveTo(humanoidRootPart.Position)
        end

        local distance = (targetPart.Position - humanoidRootPart.Position).Magnitude
        if distance <= maxAttackDistance and currentTime - lastAttackTime >= attackInterval then
            mouse1click()
            lastAttackTime = currentTime
            isAttacking = true
        else
            isAttacking = false
        end
 
    elseif autoLost and not Lost then
        if isAttacking or Fighting or Selling or Lost then
            return
        else
            Fighting = true
            task.delay(10, function()
                startPos = game.Players.LocalPlayer.Character.HumanoidRootPart.Position
                endPos = Reward
                flyToTarget(startPos, endPos, flySpeed)
                wait(1)
                workspace:WaitForChild("Guttermouth"):WaitForChild("GuttermouthRoom4"):WaitForChild("ClaimRewards"):InvokeServer()
                wait(1)
                startPos = game.Players.LocalPlayer.Character.HumanoidRootPart.Position
                endPos = LostExit
                flyToTarget(startPos, endPos, flySpeed)
                wait(1)
                workspace:WaitForChild("Guttermouth"):WaitForChild("GuttermouthRoom4"):WaitForChild("GutterExit"):WaitForChild("InteractEvent"):FireServer()
                wait(2)
                if Selling then return end
                workspace:WaitForChild("Guttermouth"):WaitForChild("Door_GuttermouthPhantom (Hidden Key)"):WaitForChild("InteractEvent"):FireServer()
                Fighting = false
            end)
        end
    end
end

-- Main connection
local connection = RunService.Heartbeat:Connect(followAndAim)

---------------------------------------------------------------------------------------
--MAIN SCRIPT

local MainTab = Window:CreateTab("Main", 0)
local Section = MainTab:CreateSection("Fishing")

MainTab:CreateToggle({
    Name = "Auto Fish",
    CurrentValue = false,
    Flag = "AutoFish",
    Callback = function(Value)
        Fishing = Value
        if Value then
            local function setupRod(tool)
                if tool:IsA("Tool") and string.find(string.lower(tool.Name), "rod") then
                    local conn = tool.ChildAdded:Connect(function(child)
                        if child.Name == "SplashPart" then
                            while Selling do
                                wait(0.1)
                            end

                            for i = 1, 10 do
                                mouse1click()
                                wait()
                            end
                            if Refish then
                                wait(5)
                                mouse1click()
                            end
                        end
                    end)
                    table.insert(rodConnections, conn)
                end
            end

            for _, v in pairs(game.Players.LocalPlayer.Character:GetChildren()) do
                setupRod(v)
            end

            local toolAddedConnection = game.Players.LocalPlayer.Character.ChildAdded:Connect(function(tool)
                setupRod(tool)
            end)
            table.insert(rodConnections, toolAddedConnection)
        else
            for _, conn in pairs(rodConnections) do
                conn:Disconnect()
            end
            rodConnections = {}
        end
    end,
})


MainTab:CreateToggle({
    Name = "Auto Sell", 
    CurrentValue = false,
    Flag = "AutoSell",
    Callback = function(Value)
        autoSell = Value
        if Value then
            spawn(function()
                while autoSell do
                    Items = 0
                    TotalValue = 0
                    local inventory = game.Players.LocalPlayer:FindFirstChild("Inventory")
                    if inventory then
                        for _, v in pairs(inventory:GetChildren()) do
                            local itemID = tostring(v.Value)
                            local itemInfo = game.ReplicatedStorage.ItemInfo:FindFirstChild(itemID)
                            if itemInfo and itemInfo:FindFirstChild("SellValue") then
                                local val = itemInfo.SellValue.Value
                                if val > 50 then
                                    Items = Items + 1
                                    TotalValue = TotalValue + val
                                end
                            end
                        end

                        if Items >= SellAt then
                            local itemsToSell = {}
                            for _, v in pairs(inventory:GetChildren()) do
                                local itemID = tostring(v.Value)
                                local itemInfo = game.ReplicatedStorage.ItemInfo:FindFirstChild(itemID)
                                if itemInfo and itemInfo:FindFirstChild("SellValue") then
                                    local val = itemInfo.SellValue.Value
                                    if val > 50 then
                                        table.insert(itemsToSell, v)
                                    end
                                end
                            end
                            sellItems(itemsToSell)
                            wait(5)
                        end
                    end
                    wait(1)
                end
            end)
        end        
    end,
})


MainTab:CreateToggle({
    Name = "Auto Open Chests",
    CurrentValue = false,
    Flag = "AutoOpen",
    Callback = function(Value)
        AutoOpen = Value
        if Value then
            spawn(function()
                local slot = 1
                local event = game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("OpenSlot")

                while AutoOpen do
                    event:FireServer(slot)
                    slot = (slot % 20) + 1  
                    wait(1)
                end
            end)
        end
    end,
})


local Section = MainTab:CreateSection("Lost")

local connection = nil

MainTab:CreateToggle({
    Name = "Auto Lost",
    CurrentValue = false,
    Flag = "AutoLost",
    Callback = function(Value)
        wait(0.5)
        autoLost = Value
        if Value then
            connection = RunService.Heartbeat:Connect(followAndAim)
        else
            if connection then
                connection:Disconnect()
                connection = nil
            end
            Fighting = false
        end
    end,
})


---------------------------------------------------------------------------------------
-- VISUALS TAB
local VisualsTab = Window:CreateTab("Visuals", 0)
local Section = VisualsTab:CreateSection("World", 0)

VisualsTab:CreateButton({
    Name = "Remove Fog",
    Callback = function()
        local player = game.Players.LocalPlayer
        if player:FindFirstChild("PlayerScripts") then
            if player:FindFirstChild("PlayerScripts"):FindFirstChild("Fog") then
                player.PlayerScripts.Fog:Destroy()
            end
        end
        if player.Character:FindFirstChild("Fogbox") then
            if player.Character:FindFirstChild("Fogbox"):FindFirstChild("Ring1") then
                player.Character.Fogbox.Ring1:Destroy()
            end
            if player.Character:FindFirstChild("Fogbox"):FindFirstChild("Ring2") then
                player.Character.Fogbox.Ring2:Destroy()
            end
            if player.Character:FindFirstChild("Fogbox"):FindFirstChild("Ring3") then
                player.Character.Fogbox.Ring3:Destroy()
            end
        end
    end
})
local Label = VisualsTab:CreateLabel("Run around map so models for esp can load")
local Section = VisualsTab:CreateSection("NPC's", 0)
local textSize = 18
local activeHighlights = {}

local function getAdornee(model)
    return model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
end

local function createESP(npcConfig)
    local npc = npcConfig.object
    if not npc or not npc:IsDescendantOf(workspace) then return end

    local adornee = getAdornee(npc)
    if not adornee then
        warn("Could not find valid part for ESP on: " .. npcConfig.displayName)
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = npcConfig.displayName .. "ESP"
    highlight.FillColor = npcConfig.color
    highlight.OutlineColor = npcConfig.color
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Enabled = espEnabled 
    highlight.Adornee = adornee
    highlight.Parent = npc

    local billboard = Instance.new("BillboardGui")
    billboard.Name = npcConfig.displayName .. "ESPLabel"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Adornee = adornee
    billboard.Enabled = espEnabled
    billboard.Parent = npc

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Label"
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.TextColor3 = npcConfig.color
    textLabel.TextScaled = false
    textLabel.TextSize = textSize
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Text = npcConfig.displayName
    textLabel.Parent = billboard

    activeHighlights[npc] = {highlight = highlight, billboard = billboard}

    local function updateESP()
        if not npc or not npc:IsDescendantOf(workspace) then
            highlight:Destroy()
            billboard:Destroy()
            activeHighlights[npc] = nil
            return
        end

        if not espEnabled then return end

        if npcConfig.showDistance and player.Character then
            local playerRoot = player.Character:FindFirstChild("HumanoidRootPart")
            local npcRoot = getAdornee(npc)
            
            if playerRoot and npcRoot then
                local distance = (playerRoot.Position - npcRoot.Position).Magnitude
                textLabel.Text = string.format("%s\n[%d studs]", npcConfig.displayName, math.floor(distance))
            end
        else
            textLabel.Text = npcConfig.displayName
        end
    end

    if npcConfig.showDistance then
        coroutine.wrap(function()
            while npc and npc:IsDescendantOf(workspace) do
                if espEnabled then
                    updateESP()
                end
                task.wait(0.1)
            end
        end)()
    end

    npc.AncestryChanged:Connect(function()
        if not npc:IsDescendantOf(workspace) then
            highlight:Destroy()
            billboard:Destroy()
            activeHighlights[npc] = nil
        end
    end)
end

for _, config in ipairs(npcConfigs) do
    coroutine.wrap(createESP)(config)
end

VisualsTab:CreateToggle({
    Name = "ESP",
    CurrentValue = espEnabled,
    Flag = "NPCEsp",
    Callback = function(Value)
        espEnabled = Value
        for npc, elements in pairs(activeHighlights) do
            elements.highlight.Enabled = espEnabled
            elements.billboard.Enabled = espEnabled
        end
    end,
})


---------------------------------------------------------------------------------------
-- TELEPORT TAB
local TeleportTab = Window:CreateTab("Teleport", 0)
local Section = TeleportTab:CreateSection("Overall", 0)

TeleportTab:CreateButton({
    Name = "Mutamanda",
    Callback = function()
        local startPos = game.Players.LocalPlayer.Character.HumanoidRootPart.Position
        local endPos = Mutamanda
        flyToTarget(startPos, endPos, flySpeed)
    end,
})

TeleportTab:CreateButton({
    Name = "Rabbit Hole",
    Callback = function()
        local startPos = game.Players.LocalPlayer.Character.HumanoidRootPart.Position
        local endPos = RabbitHole
        flyToTarget(startPos, endPos, flySpeed)
    end,
})

TeleportTab:CreateButton({
    Name = "Main Hall (Mansion)",
    Callback = function()
        local startPos = game.Players.LocalPlayer.Character.HumanoidRootPart.Position
        local endPos = MainHall
        flyToTarget(startPos, endPos, flySpeed)
    end,
})


---------------------------------------------------------------------------------------
--SETTINGS
local SettingsTab = Window:CreateTab("Settings", 0)
local Section = SettingsTab:CreateSection("Script related", 0)

SettingsTab:CreateButton({
    Name = "Unload",
    Callback = function()
        Rayfield:Destroy()
    end,
})

local Slider = SettingsTab:CreateSlider({
    Name = "Slider Example",
    Range = {1, 20},
    Increment = 1,
    Suffix = "Items",
    CurrentValue = 10,
    Flag = "Slider1", 
    Callback = function(Value)
        SellAt = Value
   end,
})
---------------------------------------------------------------------------------------
--INFO

local InfoTab = Window:CreateTab("Info", 0)
local Section = InfoTab:CreateSection("Fishing", 0)
local ItemsLabel = InfoTab:CreateLabel("Items: 0")
local TotalValueLabel = InfoTab:CreateLabel("Total Sell Value: $0")

spawn(function()
    while true do
        ItemsLabel:Set(string.format("Items: %d", Items))
        TotalValueLabel:Set(string.format("Value: $%d", TotalValue))
        wait(1)
    end
end)

---------------------------------------------------------------------------------------
--DEBUG

local DebugTab = Window:CreateTab("Debug", 0)
local Section = DebugTab:CreateSection("Player", 0)

DebugTab:CreateButton({
    Name = "SimmpleSpy",
    Callback = function()
        loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/78n/SimpleSpy/main/SimpleSpyBeta.lua"))()
    end,
})

DebugTab:CreateButton({
    Name = "Position",
    Callback = function()
        print(game.Players.LocalPlayer.Character.HumanoidRootPart.Position)
    end,
})

DebugTab:CreateButton({
    Name = "Lost",
    Callback = function()
        print(Lost)
    end,
})

DebugTab:CreateButton({
    Name = "Fight",
    Callback = function()
        print(Fighting)
    end,
})

DebugTab:CreateButton({
    Name = "AutoLost",
    Callback = function()
        print(autoLost)
    end,
})

DebugTab:CreateButton({
    Name = "AutoSellAt",
    Callback = function()
        print(SellAt)
    end,
})


---------------------------------------------------------------------------------------
