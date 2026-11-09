-- AUTO-RELOAD MOBILE VR CONTROLLER
-- Saves itself to execute automatically after teleports and rejoins, while keeping the PC sidebar hidden.

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 1. DEFINE THE ENTIRE SCRIPT SOURCE FOR CROSS-SERVER AUTO-EXECUTION
local scriptSource = [[
    local TeleportService = game:GetService("TeleportService")
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    -- Execute the vr_mobile layout script
    task.spawn(function()
        pcall(function()
            loadstring(game:HttpGet("https://githubusercontent.com"))()
        end)
    end)

    -- Launch VR Hands payload and clean up the PC sidebar clutter
    task.spawn(function()
        local success, originalCode = pcall(function()
            return game:HttpGet("https://githubusercontent.com")
        end)
        
        if success and originalCode then
            local cleanedCode = originalCode
            cleanedCode = cleanedCode:gsub('Text = "PC"', 'Text = "Mobile"')
            cleanedCode = cleanedCode:gsub('Text = "Keyboard"', 'Text = ""')
            cleanedCode = cleanedCode:gsub('Text = "Mouse Controls"', 'Text = ""')
            cleanedCode = cleanedCode:gsub(':FindFirstChild%%("PCControls"%%)', 'nil')
            cleanedCode = cleanedCode:gsub('PCControls.Visible = true', 'PCControls.Visible = false')

            local func, err = loadstring(cleanedCode)
            if func then 
                task.spawn(func)
            else
                loadstring(originalCode)()
            end
        else
            loadstring(game:HttpGet("https://githubusercontent.com"))()
        end

        -- Sweeper routine to instantly catch and hide sneaky PC elements
        task.wait(2)
        local sg = game:GetService("CoreGui"):FindFirstChild("ScreenGui") or playerGui:FindFirstChild("ScreenGui")
        if sg then
            for _, v in pairs(sg:GetDescendants()) do
                if v:IsA("TextLabel") or v:IsA("TextButton") then
                    if v.Text:find("PC") or v.Text:find("Key") or v.Text:find("Mouse") then
                        v.Visible = false
                    end
                end
            end
        end
    end)

    -- Add the persistent mobile Rejoin button
    local function createRejoinButton()
        local targetGui = game:GetService("CoreGui"):FindFirstChild("VR_Mobile_System") or playerGui:WaitForChild("PlayerGui", 5)
        if not targetGui then return end
        
        if targetGui:FindFirstChild("InstantRejoinBtn") then
            targetGui.InstantRejoinBtn:Destroy()
        end

        local rj = Instance.new("TextButton")
        rj.Name = "InstantRejoinBtn"
        rj.Size = UDim2.new(0, 90, 0, 35)
        rj.Position = UDim2.new(0, 10, 0, 10)
        rj.Text = "REJOIN"
        rj.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        rj.TextColor3 = Color3.fromRGB(255, 255, 255)
        rj.Font = Enum.Font.SourceSansBold
        rj.TextSize = 14
        rj.Parent = targetGui
        Instance.new("UICorner", rj).CornerRadius = UDim.new(0, 6)

        rj.MouseButton1Click:Connect(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
        end)
    end

    task.spawn(function()
        task.wait(1)
        createRejoinButton()
    end)
]]

-- 2. QUEUE THE CODE TO RUN IMMEDIATELY UPON NEXT TELEPORT/REJOIN
if typeof(queue_on_teleport) == "function" then
    queue_on_teleport(scriptSource)
elseif typeof(syn) == "table" and syn.queue_on_teleport then
    syn.queue_on_teleport(scriptSource)
elseif typeof(fluxus) == "table" and fluxus.queue_on_teleport then
    fluxus.queue_on_teleport(scriptSource)
end

-- 3. RUN IT FOR THE CURRENT SERVER IMMEDIATELY
loadstring(scriptSource)()
