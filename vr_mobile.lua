local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Fixed scaled layout custom fit for iPhone screen ratios
local ringSize = 110      
local knobSize = 45       
local btnSize = 50        
local frameSize = 260     
local textFontScale = 11  

local mobileSystemSource = string.format([[
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local ContextActionService = game:GetService("ContextActionService")
    local UserInputService = game:GetService("UserInputService")

    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    if playerGui:FindFirstChild("VR_Mobile_System") then
        playerGui.VR_Mobile_System:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "VR_Mobile_System"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

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

    -- --- IPHONE SPECIFIC LEFT JOYSTICK ---
    local joyRing = Instance.new("Frame")
    joyRing.Size = UDim2.new(0, %d, 0, %d)
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
    joyStick.Size = UDim2.new(0, %d, 0, %d)
    joyStick.Position = UDim2.new(0.5, -%d, 0.5, -%d)
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
            
            joyStick.Position = UDim2.new(0.5, (dir.X * distance) - %d, 0.5, (dir.Y * distance) - %d)
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
            joyStick.Position = UDim2.new(0.5, -%d, 0.5, -%d)
            joyStick.BackgroundTransparency = 0.45
            updateKeys({W = false, A = false, S = false, D = false})
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
    end)

    -- --- IPHONE CORNER-SAFE RIGHT BUTTON CLUSTER ---
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Size = UDim2.new(0, %d, 0, %d)
    buttonFrame.Position = UDim2.new(1, -290, 0.38, -105)
    buttonFrame.BackgroundTransparency = 1
    buttonFrame.Parent = screenGui

    local function createCircleButton(shortName, fullName, key, isMouse, xPos, yPos)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, %d, 0, %d)
        btn.Position = UDim2.new(0, xPos, 0, yPos)
        btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        btn.BackgroundTransparency = 0.60
        btn.Text = shortName
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = %d
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
        tip.TextSize = 7.5
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

    local mult = 0.88 
    createCircleButton("PL Q", "Pinch Player L", Enum.KeyCode.Q, false, 15 * mult, 40 * mult)
    createCircleButton("PL E", "Pinch Player R", Enum.KeyCode.E, false, 100 * mult, 10 * mult)
    createCircleButton("OB L", "Grab Object L", 0, true, 185 * mult, 40 * mult)
    createCircleButton("OB R", "Grab Object R", 1, true, 230 * mult, 115 * mult)
    createCircleButton("▲", "Fly UP", Enum.KeyCode.Space, false, 160 * mult, 190 * mult)
    createCircleButton("▼", "Fly DOWN", Enum.KeyCode.LeftShift, false, 75 * mult, 205 * mult)

    task.spawn(function()
        pcall(function()
            loadstring(game:HttpGet("githubusercontent.com"))()
        end)
    end)
]], ringSize, ringSize, knobSize, knobSize, knobSize/2, knobSize/2, knobSize/2, knobSize/2, knobSize/2, knobSize/2, frameSize, frameSize, btnSize, btnSize, textFontScale)

if typeof(queue_on_teleport) == "function" then
    queue_on_teleport(mobileSystemSource)
elseif typeof(syn) == "table" and syn.queue_on_teleport then
    syn.queue_on_teleport(mobileSystemSource)
elseif typeof(fluxus) == "table" and fluxus.queue_on_teleport then
    fluxus.queue_on_teleport(mobileSystemSource)
end

task.spawn(function()
    pcall(function()
        loadstring(mobileSystemSource)()
    end)
end)
