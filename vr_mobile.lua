local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local mobileSystemSource = [[
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

    -- --- DYNAMIC SCREEN DETECTOR & SCALER ---
    local ringSize, knobSize, btnSize, frameSize, textFontScale, layoutMult, frameXOffset, frameYOffset
    
    local function autoScaleLayout()
        local size = camera.ViewportSize
        -- If width is larger than 1000 pixels, assume it's a Tablet/iPad. Otherwise, treat as an iPhone.
        if size.X > 1000 then
            -- Tablet Proportions
            ringSize = 150
            knobSize = 65
            btnSize = 72
            frameSize = 380
            textFontScale = 14
            layoutMult = 1.3
            frameXOffset = -420
            frameYOffset = -180
        else
            -- iPhone Proportions
            ringSize = 110
            knobSize = 45
            btnSize = 50
            frameSize = 260
            textFontScale = 11
            layoutMult = 0.88
            frameXOffset = -290
            frameYOffset = -105
        end
    end
    autoScaleLayout()

    -- --- CAMERA FREEZE FOR JOYSTICK FLIGHT ---
    local function sinkAction() return Enum.ContextActionResult.Sink end
    local function toggleCameraLock(lock)
        local playerScripts = player:WaitForChild("PlayerScripts")
        local cameraModule = playerScripts:FindFirstChild("PlayerModule") and require(playerScripts.PlayerModule):GetCameras()
        if lock then
            ContextActionService:BindActionAtPriority("VR_CamLock", sinkAction, false, 99999, Enum.UserInputType.Touch, Enum.UserInputType.MouseButton1)
            if cameraModule and cameraModule.activeCamera then cameraModule.activeCamera:SetEnabled(false) end
        else
            ContextActionService:UnbindAction("VR_CamLock")
            if cameraModule and cameraModule.activeCamera then cameraModule.activeCamera:SetEnabled(true) end
        end
    end

    -- --- DYNAMIC PROFILE LEFT JOYSTICK ---
    local joyRing = Instance.new("Frame")
    joyRing.Size = UDim2.new(0, ringSize, 0, ringSize)
    joyRing.Position = UDim2.new(0.05, 0, 0.58, 0)
    joyRing.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    joyRing.BackgroundTransparency = 0.75
    joyRing.BorderSizePixel = 0
    joyRing.Active = true
    joyRing.Parent = screenGui
    Instance.new("UICorner", joyRing).CornerRadius = UDim.new(1, 0)

    local ringStroke = Instance.new("UIStroke")
    ringStroke.Color = Color3.fromRGB(255, 255, 255)
    ringStroke.Thickness = 1.5
    ringStroke.Transparency = 0.6
    ringStroke.Parent = joyRing

    local joyStick = Instance.new("TextButton")
    joyStick.Size = UDim2.new(0, knobSize, 0, knobSize)
    joyStick.Position = UDim2.new(0.5, -(knobSize/2), 0.5, -(knobSize/2))
    joyStick.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    joyStick.BackgroundTransparency = 0.45
    joyStick.Text = ""
    joyStick.BorderSizePixel = 0
    joyStick.Active = true
    joyStick.Parent = joyRing
    Instance.new("UICorner", joyStick).CornerRadius = UDim.new(1, 0)

    local activeKeys = {W = false, A = false, S = false, D = false}
    local joyDragging = false
    local joyInput = nil
    local targetSpeed = 2

    RunService.RenderStepped:Connect(function()
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and joyDragging then hum.WalkSpeed = targetSpeed end
    end)

    local function updateKeys(newKeys)
        for key, state in pairs(newKeys) do
            if activeKeys[key] ~= state then
                activeKeys[key] = state
                VirtualInputManager:SendKeyEvent(state, Enum.KeyCode[key], false, game)
            end
        end
    end

    joyStick.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            joyDragging = true
            joyInput = input
            toggleCameraLock(true)
            joyStick.BackgroundTransparency = 0.1
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if joyDragging and input == joyInput then
            local center = joyRing.AbsolutePosition + (joyRing.AbsoluteSize / 2)
            local delta = Vector2.new(input.Position.X, input.Position.Y) - center
            local maxRadius = joyRing.AbsoluteSize.X / 2
            local distance = math.min(delta.Magnitude, maxRadius)
            local dir = delta.Magnitude > 0 and delta.Unit or Vector2.new(0, 0)
            
            joyStick.Position = UDim2.new(0.5, (dir.X * distance) - (knobSize/2), 0.5, (dir.Y * distance) - (knobSize/2))
            targetSpeed = math.clamp((distance / maxRadius) * 2, 0.2, 2)

            local keys = {W = false, A = false, S = false, D = false}
            if distance > 10 then
                if dir.Y < -0.35 then keys.W = true end
                if dir.Y > 0.35 then keys.S = true end
                if dir.X < -0.35 then keys.A = true end
                if dir.X > 0.35 then keys.D = true end
            end
            updateKeys(keys)
        end
    end)

    joyStick.InputEnded:Connect(function(input)
        if input == joyInput then
            joyDragging = false
            joyInput = nil
            targetSpeed = 2
            toggleCameraLock(false)
            joyStick.Position = UDim2.new(0.5, -(knobSize/2), 0.5, -(knobSize/2))
            joyStick.BackgroundTransparency = 0.45
            updateKeys({W = false, A = false, S = false, D = false})
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
    end)

    -- --- SMART DYNAMIC BUTTON CLUSTER FRAME ---
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Size = UDim2.new(0, frameSize, 0, frameSize)
    buttonFrame.Position = UDim2.new(1, frameXOffset, 0.38, frameYOffset)
    buttonFrame.BackgroundTransparency = 1
    buttonFrame.Parent = screenGui

    local function createCircleButton(shortName, fullName, key, isMouse, xPos, yPos)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, btnSize, 0, btnSize)
        btn.Position = UDim2.new(0, xPos, 0, yPos)
        btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        btn.BackgroundTransparency = 0.60
        btn.Text = shortName
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = textFontScale
        btn.BorderSizePixel = 0
        btn.Parent = buttonFrame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = Color3.fromRGB(255, 255, 255)
        btnStroke.Thickness = 1.5
        btnStroke.Transparency = 0.6
        btnStroke.Parent = btn

        local tip = Instance.new("TextLabel")
        tip.Size = UDim2.new(1.6, 0, 0, 12)
        tip.Position = UDim2.new(-0.3, 0, -0.38, 0)
        tip.BackgroundTransparency = 1
        tip.Text = fullName
        tip.TextColor3 = Color3.fromRGB(200, 200, 200)
        tip.Font = Enum.Font.GothamSemibold
        tip.TextSize = textFontScale - 3.5
        tip.Parent = btn

        local isToggledActive = false

        btn.MouseButton1Click:Connect(function()
            isToggledActive = not isToggledActive
            if isToggledActive then
                btn.BackgroundTransparency = 0.25
                btn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
                if isMouse then
                    VirtualInputManager:SendMouseButtonEvent(0, 0, key, true, game, 0)
                else
                    VirtualInputManager:SendKeyEvent(true, key, false, game)
                end
            else
                btn.BackgroundTransparency = 0.60
                btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                if isMouse then
                    VirtualInputManager:SendMouseButtonEvent(0, 0, key, false, game, 0)
                else
                    VirtualInputManager:SendKeyEvent(false, key, false, game)
                end
            end
        end)
    end

    createCircleButton("PL Q", "Pinch Player L", Enum.KeyCode.Q, false, 15 * layoutMult, 40 * layoutMult)
    createCircleButton("PL E", "Pinch Player R", Enum.KeyCode.E, false, 100 * layoutMult, 10 * layoutMult)
    createCircleButton("OB L", "Grab Object L", 0, true, 185 * layoutMult, 40 * layoutMult)
    createCircleButton("OB R", "Grab Object R", 1, true, 230 * layoutMult, 115 * layoutMult)
    createCircleButton("▲", "Fly UP", Enum.KeyCode.Space, false, 160 * layoutMult, 190 * layoutMult)
    createCircleButton("▼", "Fly DOWN", Enum.KeyCode.LeftShift, false, 75 * layoutMult, 205 * layoutMult)

    -- Dynamic listener handles orientation changes on the fly
    camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        autoScaleLayout()
        joyRing.Size = UDim2.new(0, ringSize, 0, ringSize)
        joyStick.Size = UDim2.new(0, knobSize, 0, knobSize)
        joyStick.Position = UDim2.new(0.5, -(knobSize/2), 0.5, -(knobSize/2))
