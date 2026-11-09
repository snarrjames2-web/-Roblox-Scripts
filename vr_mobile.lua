local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Expanded proportions calibrated for iPad and Tablet interfaces
local ringSize = 170
local knobSize = 70
local btnSize = 78
local frameSize = 420 
local textFontScale = 16

local mobileSystemSource = string.format([[
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local ContextActionService = game:GetService("ContextActionService")
    local UserInputService = game:GetService("UserInputService")
    local Workspace = game:GetService("Workspace")

    local player = Players.LocalPlayer
    local camera = Workspace.CurrentCamera
    local playerGui = player:WaitForChild("PlayerGui")

    if playerGui:FindFirstChild("VR_Mobile_System") then
        playerGui.VR_Mobile_System:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "VR_Mobile_System"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    -- ==========================================================
    -- SMOOTH CONTAINMENT CAGE SYSTEM (ANTI-FLING CONFIG)
    -- ==========================================================
    local barrierEnabled = false
    local barrierShape = "Square" -- "Square" or "Circle"
    local barrierSize = 30 
    local barrierHeight = 50 
    local centerPoint = Vector3.new(0, 0, 0)
    local isPlacing = false 
    local isPlaced = false 

    local visualPart = Instance.new("Part")
    visualPart.Anchored = true
    visualPart.CanCollide = false
    visualPart.CastShadow = false
    visualPart.Transparency = 0.85
    visualPart.Color = Color3.fromRGB(0, 255, 150)
    visualPart.Material = Enum.Material.ForceField
    visualPart.Parent = Workspace

    local function updateVisual()
        if not barrierEnabled or not isPlaced then
            visualPart.Size = Vector3.new(0,0,0)
            return
        end
        if barrierShape == "Square" then
            visualPart.Shape = Enum.PartType.Block
            visualPart.Size = Vector3.new(barrierSize * 2, barrierHeight * 2, barrierSize * 2)
            visualPart.Position = centerPoint
        elseif barrierShape == "Circle" then
            visualPart.Shape = Enum.PartType.Cylinder
            visualPart.Size = Vector3.new(barrierHeight * 2, barrierSize * 2, barrierSize * 2)
            visualPart.Position = centerPoint
            visualPart.Orientation = Vector3.new(0, 0, 90)
        end
    end

    -- Setup Vector Force Constraint (No Breaking Limb Joints)
    local forceConstraint = Instance.new("VectorForce")
    local attachment = Instance.new("Attachment")
    forceConstraint.Force = Vector3.zero
    forceConstraint.RelativeTo = Enum.ActuatorRelativeTo.World

    local function setupCharacterForces(character)
        local rootPart = character:WaitForChild("HumanoidRootPart", 5)
        if not rootPart then return end
        attachment.Parent = rootPart
        forceConstraint.Attachment0 = attachment
        forceConstraint.Parent = rootPart
    end

    if player.Character then setupCharacterForces(player.Character) end
    player.CharacterAdded:Connect(setupCharacterForces)

    -- --- FIXED CAGE CONTROLS FRAME (Inward from Screen Bounds) ---
    local cageFrame = Instance.new("Frame")
    cageFrame.Size = UDim2.new(0, 160, 0, 255)
    -- Positioned on the right side but shifted safely left to avoid screen edge cutoffs
    cageFrame.Position = UDim2.new(1, -620, 0.45, -210) 
    cageFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    cageFrame.BackgroundTransparency = 0.1
    cageFrame.BorderSizePixel = 0
    cageFrame.Parent = screenGui

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(1, -10, 0, 35)
    toggleBtn.Position = UDim2.new(0, 5, 0, 5)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    toggleBtn.Text = "Cage: OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.Parent = cageFrame

    local shapeBtn = Instance.new("TextButton")
    shapeBtn.Size = UDim2.new(1, -10, 0, 35)
    shapeBtn.Position = UDim2.new(0, 5, 0, 45)
    shapeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    shapeBtn.Text = "Shape: Square"
    shapeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    shapeBtn.Font = Enum.Font.GothamBold
    shapeBtn.Parent = cageFrame

    local sizeLabel = Instance.new("TextLabel")
    sizeLabel.Size = UDim2.new(0, 60, 0, 35)
    sizeLabel.Position = UDim2.new(0, 5, 0, 85)
    sizeLabel.Text = "Size:"
    sizeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    sizeLabel.Font = Enum.Font.GothamBold
    sizeLabel.BackgroundTransparency = 1
    sizeLabel.Parent = cageFrame

    local sizeInput = Instance.new("TextBox")
    sizeInput.Size = UDim2.new(1, -75, 0, 35)
    sizeInput.Position = UDim2.new(0, 70, 0, 85)
    sizeInput.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    sizeInput.Text = tostring(barrierSize)
    sizeInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    sizeInput.Font = Enum.Font.GothamBold
    sizeInput.Parent = cageFrame

    local placeBtn = Instance.new("TextButton")
    placeBtn.Size = UDim2.new(1, -10, 0, 35)
    placeBtn.Position = UDim2.new(0, 5, 0, 130)
    placeBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
    placeBtn.Text = "Place"
    placeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    placeBtn.Font = Enum.Font.GothamBold
    placeBtn.Parent = cageFrame

    local unplaceBtn = Instance.new("TextButton")
    unplaceBtn.Size = UDim2.new(1, -10, 0, 35)
    unplaceBtn.Position = UDim2.new(0, 5, 0, 170)
    unplaceBtn.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
    unplaceBtn.Text = "Unplace"
    unplaceBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    unplaceBtn.Font = Enum.Font.GothamBold
    unplaceBtn.Parent = cageFrame

    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, -10, 0, 40)
    infoLabel.Position = UDim2.new(0, 5, 0, 210)
    infoLabel.Text = "Not placed yet"
    infoLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    infoLabel.TextWrapped = true
    infoLabel.BackgroundTransparency = 1
    infoLabel.TextSize = 12
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.Parent = cageFrame

    -- Interactivity Logic
    toggleBtn.MouseButton1Click:Connect(function()
        barrierEnabled = not barrierEnabled
        if barrierEnabled then
            toggleBtn.Text = "Cage: ON"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        else
            toggleBtn.Text = "Cage: OFF"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            forceConstraint.Force = Vector3.zero
        end
        updateVisual()
    end)

    shapeBtn.MouseButton1Click:Connect(function()
        barrierShape = (barrierShape == "Square") and "Circle" or "Square"
        shapeBtn.Text = "Shape: " .. barrierShape
        updateVisual()
    end)

    sizeInput.FocusLost:Connect(function()
        local num = tonumber(sizeInput.Text)
        if num and num > 0 then barrierSize = num else sizeInput.Text = tostring(barrierSize) end
        updateVisual()
    end)

    placeBtn.MouseButton1Click:Connect(function()
        isPlacing = true
        infoLabel.Text = "Tap ground to place..."
        infoLabel.TextColor3 = Color3.fromRGB(0, 120, 255)
    end)

    unplaceBtn.MouseButton1Click:Connect(function()
        isPlaced = false
        isPlacing = false
        forceConstraint.Force = Vector3.zero
        infoLabel.Text = "Cage Unplaced"
        infoLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
        updateVisual()
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not isPlacing then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            local ray = camera:ScreenPointToRay(input.Position.X, input.Position.Y)
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            raycastParams.FilterDescendantsInstances = {player.Character, visualPart}
            
            local raycastResult = Workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
            if raycastResult then
                centerPoint = raycastResult.Position
                isPlacing = false
                isPlaced = true
                infoLabel.Text = "Cage Active!"
                infoLabel.TextColor3 = Color3.fromRGB(50, 180, 50)
                updateVisual()
            end
        end
    end)

    -- Force Field Physics Engine
    RunService.RenderStepped:Connect(function()
        if not barrierEnabled or not isPlaced then 
            forceConstraint.Force = Vector3.zero
            return 
        end
        
        local character = player.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        local relativePos = rootPart.Position - centerPoint
        local calculatedPushForce = Vector3.zero
        local PUSH_POWER = 35000 
        
        if relativePos.Y > barrierHeight then
            calculatedPushForce = calculatedPushForce + Vector3.new(0, -PUSH_POWER * (relativePos.Y - barrierHeight), 0)
        elseif relativePos.Y < -barrierHeight then
            calculatedPushForce = calculatedPushForce + Vector3.new(0, PUSH_POWER * (-barrierHeight - relativePos.Y), 0)
        end
        
        if barrierShape == "Square" then
            if math.abs(relativePos.X) > barrierSize then
                local dir = relativePos.X > 0 and -1 or 1
                calculatedPushForce = calculatedPushForce + Vector3.new(PUSH_POWER * dir * (math.abs(relativePos.X) - barrierSize), 0, 0)
            end
