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

-- --- PHONE STANDARD FLIGHT JOYSTICK (2 SPEED HARD MAX) ---
local joyRing = Instance.new("Frame")
joyRing.Size = UDim2.new(0, 120, 0, 120)
joyRing.Position = UDim2.new(0.06, 0, 0.60, 0)
joyRing.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
joyRing.BackgroundTransparency = 0.65
joyRing.BorderSizePixel = 0
joyRing.Active = true
joyRing.Parent = screenGui
Instance.new("UICorner", joyRing).CornerRadius = UDim.new(1, 0)

local ringStroke = Instance.new("UIStroke")
ringStroke.Color = Color3.fromRGB(255, 255, 255)
ringStroke.Thickness = 2
ringStroke.Transparency = 0.5
ringStroke.Parent = joyRing

local joyStick = Instance.new("TextButton")
joyStick.Size = UDim2.new(0, 50, 0, 50)
joyStick.Position = UDim2.new(0.5, -25, 0.5, -25)
joyStick.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
joyStick.BackgroundTransparency = 0.3
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
        
        joyStick.Position = UDim2.new(0.5, (dir.X * distance) - 25, 0.5, (dir.Y * distance) - 25)
        
        -- Set fine-tuned velocity scaling capping cleanly at 2 speed max
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
        joyStick.Position = UDim2.new(0.5, -25, 0.5, -25)
        joyStick.BackgroundTransparency = 0.3
        updateKeys({W = false, A = false, S = false, D = false})
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end)

-- --- CIRCULAR TAP-TO-TOGGLE USER BUTTON MATRIX ---
local buttonFrame = Instance.new("Frame")
buttonFrame.Size = UDim2.new(0, 240, 0, 240)
buttonFrame.Position = UDim2.new(1, -260, 0.52, -120)
buttonFrame.BackgroundTransparency = 1
buttonFrame.Parent = screenGui

local function createCircleButton(shortName, fullName, key, isMouse, xPos, yPos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 56, 0, 56)
    btn.Position = UDim2.new(0, xPos, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    btn.BackgroundTransparency = 0.5
    btn.Text = shortName
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    btn.Parent = buttonFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(255, 255, 255)
    btnStroke.Thickness = 2
    btnStroke.Transparency = 0.5
    btnStroke.Parent = btn

    local isToggledActive = false

    btn.MouseButton1Click:Connect(function()
        isToggledActive = not isToggledActive
        
        if isToggledActive then
            btn.BackgroundTransparency = 0.15
            btn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
            if isMouse then
                VirtualInputManager:SendMouseButtonEvent(0, 0, key, true, game, 0)
            else
                VirtualInputManager:SendKeyEvent(true, key, false, game)
            end
        else
            btn.BackgroundTransparency = 0.5
            btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            if isMouse then
                VirtualInputManager:SendMouseButtonEvent(0, 0, key, false, game, 0)
            else
                VirtualInputManager:SendKeyEvent(false, key, false, game)
            end
        end
    end)
end

createCircleButton("PL Q", "Pinch Player L", Enum.KeyCode.Q, false, 10, 35)
createCircleButton("PL E", "Pinch Player R", Enum.KeyCode.E, false, 85, 10)
createCircleButton("OB L", "Grab Object L", 0, true, 160, 35)
createCircleButton("OB R", "Grab Object R", 1, true, 200, 105)
createCircleButton("▲", "Fly UP", Enum.KeyCode.Space, false, 130, 165)
createCircleButton("▼", "Fly DOWN", Enum.KeyCode.LeftShift, false, 55, 185)

-- Launch target server VR Hands payload script
task.spawn(function()
    pcall(function()
        -- Directly runs the main VR Hands script setup alongside your buttons
        loadstring(game:HttpGet("https://githubusercontent.com"))()
    end)
end)
