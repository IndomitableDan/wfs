local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- Variables for features
local flying = false
local noclip = false
local collectionBoost = false
local autoFarm = false
local flySpeed = 50
local bodyVelocity = nil
local bodyGyro = nil
local collisionGroupName = "NoClipGroup"

-- Create collision group for noclip
PhysicsService:CreateCollisionGroup(collisionGroupName)
PhysicsService:CollisionGroupSetCollidable(collisionGroupName, "Default", false)

-- Game-specific (Weapon Fighting Simulator)
local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage -- Adjust if remote folder is different
local swingRemote = remotes:FindFirstChild("Swing") -- Common attack remote; check with executor explorer if not working (may be "SwingWeapon" or "Attack")
local enemiesFolder = workspace:FindFirstChild("Battlefield") and workspace.Battlefield:FindFirstChild("LiveEnemies") or workspace -- Adjust if enemies are elsewhere
local dropsFolder = workspace:FindFirstChild("Orbs") or workspace -- Adjust if drops are in a different folder (e.g., "Drops")

-- Function to make a UI element draggable (for mobile touch)
local function makeDraggable(frame)
    local dragging = false
    local dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch and dragging then
            update(input)
        end
    end)
end

-- Create GUI programmatically (sleek dark theme)
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.Name = "FlyNoclipGUI"
screenGui.ResetOnSpawn = false

-- Toggle Button (small, always visible when menu closed, draggable)
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "MenuToggle"
toggleButton.Text = "Menu"
toggleButton.Size = UDim2.new(0, 60, 0, 30)
toggleButton.Position = UDim2.new(1, -70, 1, -40) -- Bottom-right corner
toggleButton.BackgroundColor3 = Color3.new(0.11, 0.11, 0.13) -- Dark gray
toggleButton.TextColor3 = Color3.new(0.9, 0.9, 0.9) -- Light gray
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 14
toggleButton.Parent = screenGui
local toggleCorner = Instance.new("UICorner", toggleButton)
toggleCorner.CornerRadius = UDim.new(0, 5)
makeDraggable(toggleButton) -- Make toggle draggable too

-- Main Frame (draggable, hidden initially)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 200, 0, 250)
mainFrame.Position = UDim2.new(1, -210, 1, -260) -- Bottom-right, above toggle
mainFrame.BackgroundColor3 = Color3.new(0.11, 0.11, 0.13)
mainFrame.BackgroundTransparency = 0.1
mainFrame.Visible = false
mainFrame.Parent = screenGui
local mainCorner = Instance.new("UICorner", mainFrame)
mainCorner.CornerRadius = UDim.new(0, 8)
makeDraggable(mainFrame) -- Make main frame draggable

-- Toggle GUI visibility
toggleButton.Activated:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

-- Helper function to create buttons
local function createButton(name, text, position, callback)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Text = text
    button.Size = UDim2.new(0, 180, 0, 30)
    button.Position = position
    button.BackgroundColor3 = Color3.new(0.2, 0.2, 0.22)
    button.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    button.Font = Enum.Font.SourceSans
    button.TextSize = 14
    button.Parent = mainFrame
    local btnCorner = Instance.new("UICorner", button)
    btnCorner.CornerRadius = UDim.new(0, 5)
    button.Activated:Connect(callback)
    return button
end

-- Fly Button
local flyButton = createButton("FlyButton", "Fly: OFF", UDim2.new(0, 10, 0, 10), function()
    flying = not flying
    if flying then
        humanoid.PlatformStand = true
        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.Parent = humanoidRootPart
        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bodyGyro.CFrame = humanoidRootPart.CFrame
        bodyGyro.Parent = humanoidRootPart
        flyButton.Text = "Fly: ON"
    else
        humanoid.PlatformStand = false
        if bodyVelocity then bodyVelocity:Destroy() end
        if bodyGyro then bodyGyro:Destroy() end
        flyButton.Text = "Fly: OFF"
    end
end)

-- Noclip Button
local noclipButton = createButton("NoclipButton", "Noclip: OFF", UDim2.new(0, 10, 0, 50), function()
    noclip = not noclip
    local group = noclip and collisionGroupName or "Default"
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            PhysicsService:SetPartCollisionGroup(part, group)
        end
    end
    noclipButton.Text = "Noclip: " .. (noclip and "ON" or "OFF")
end)

-- Collection Boost Button
local collectionButton = createButton("CollectionButton", "Collection Boost: OFF", UDim2.new(0, 10, 0, 90), function()
    collectionBoost = not collectionBoost
    collectionButton.Text = "Collection Boost: " .. (collectionBoost and "ON" or "OFF")
end)

-- Auto Farm Button
local autoFarmButton = createButton("AutoFarmButton", "Auto Farm: OFF", UDim2.new(0, 10, 0, 130), function()
    autoFarm = not autoFarm
    autoFarmButton.Text = "Auto Farm: " .. (autoFarm and "ON" or "OFF")
end)

-- Speed Slider (simple frame with draggable indicator and text label)
local speedLabel = Instance.new("TextLabel")
speedLabel.Text = "Fly Speed: 50"
speedLabel.Size = UDim2.new(0, 180, 0, 20)
speedLabel.Position = UDim2.new(0, 10, 0, 170)
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
speedLabel.Font = Enum.Font.SourceSans
speedLabel.TextSize = 14
speedLabel.Parent = mainFrame

local sliderFrame = Instance.new("Frame")
sliderFrame.Size = UDim2.new(0, 180, 0, 10)
sliderFrame.Position = UDim2.new(0, 10, 0, 195)
sliderFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.22)
sliderFrame.Parent = mainFrame
local sliderCorner = Instance.new("UICorner", sliderFrame)
sliderCorner.CornerRadius = UDim.new(0, 5)

local sliderKnob = Instance.new("Frame")
sliderKnob.Size = UDim2.new(0, 10, 0, 20)
sliderKnob.Position = UDim2.new(0.25, 0, -0.5, 0) -- Default at 50 (range 10-200)
sliderKnob.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
sliderKnob.Parent = sliderFrame
local knobCorner = Instance.new("UICorner", sliderKnob)
knobCorner.CornerRadius = UDim.new(0, 5)
makeDraggable(sliderKnob) -- Draggable for adjustment

-- Update speed based on knob position (range 10-200)
RunService.RenderStepped:Connect(function()
    local knobPos = math.clamp(sliderKnob.Position.X.Scale, 0, 1)
    flySpeed = math.round(10 + (190 * knobPos)) -- 10 to 200
    speedLabel.Text = "Fly Speed: " .. flySpeed
end)

-- Flying movement (mobile joystick + ascend with space-like input, but use joystick for vertical if tilted)
RunService.RenderStepped:Connect(function()
    if flying and bodyVelocity and bodyGyro then
        local moveDirection = humanoid.MoveDirection * flySpeed
        bodyVelocity.Velocity = workspace.CurrentCamera.CFrame:VectorToWorldSpace(moveDirection)
        if moveDirection.Magnitude > 0 then
            bodyGyro.CFrame = CFrame.lookAt(Vector3.new(0,0,0), workspace.CurrentCamera.CFrame:VectorToWorldSpace(moveDirection))
        end
    end
end)

-- Collection Boost Loop
RunService.Heartbeat:Connect(function()
    if collectionBoost then
        for _, drop in ipairs(dropsFolder:GetChildren()) do
            if drop:IsA("BasePart") and (drop.Name:find("Orb") or drop.Name:find("Coin") or drop.Name:find("Gem")) then -- Add more drop names if needed
                drop.CFrame = humanoidRootPart.CFrame + Vector3.new(0, 3, 0) -- Teleport to player for collection
            end
        end
    end
end)

-- Auto Farm Loop (teleport to nearest enemy + auto swing)
RunService.RenderStepped:Connect(function()
    if autoFarm and swingRemote and swingRemote:IsA("RemoteEvent") then
        local nearest, minDist = nil, math.huge
        for _, enemy in ipairs(enemiesFolder:GetChildren()) do
            if enemy:IsA("Model") and enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 and enemy:FindFirstChild("HumanoidRootPart") then
                local dist = (humanoidRootPart.Position - enemy.HumanoidRootPart.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearest = enemy
                end
            end
        end
        if nearest and minDist < 100 then -- Range limit to avoid teleporting far
            humanoidRootPart.CFrame = nearest.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5) -- Teleport in front
            swingRemote:FireServer() -- Auto attack/swing
        end
    end
end)

-- Handle respawn/reapply states
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
    if flying then
        flyButton.Activated:Invoke() -- Re-enable fly
        flyButton.Activated:Invoke()
    end
    if noclip then
        noclipButton.Activated:Invoke() -- Re-enable noclip
        noclipButton.Activated:Invoke()
    end
end)

print("Script loaded! Tap 'Menu' to open GUI.")