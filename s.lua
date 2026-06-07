-- ESP + Hard Aimbot + Rage Teleport LocalScript (With 'P' Master Toggle, Local Godmode, & NPC Support)
-- Place in StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ============================================================
-- CONFIG
-- ============================================================
local Config = {
    Master_Enabled = true,
    
    ESP_Enabled = true,
    ESP_BoxColor = Color3.fromRGB(255, 50, 50),
    ESP_NameColor = Color3.fromRGB(255, 255, 255),
    ESP_MaxDistance = 2500, 

    Aimbot_Enabled = true,
    Aimbot_Key = Enum.KeyCode.X,
    Aimbot_Smoothness = 1,
    Aimbot_FOV = 500,
    Aimbot_TargetPart = "Head",
    Aimbot_TeamCheck = true,
    Tracer_Enabled = false,
    Tracer_Color = Color3.fromRGB(255, 80, 80),
    Tracer_Thickness = 1.5,

    Prediction_Enabled = false,
    Prediction_Strength = 0.1,

    AutoFire_Enabled = false,
    
    TeleportLoop_Enabled = false,
    Speed_Step = 10,
    Default_Speed = 16
}

-- ============================================================
-- LOCAL HEALTH REGEN LOOP (Client-Side Only)
-- ============================================================
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 and hum.Health < 100 then
        hum.MaxHealth = 100
        hum.Health = 100
    end
end)

-- ============================================================
-- ESP DATA STRUCTURE
-- ============================================================
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "ESPFolder"
ESPFolder.Parent = LocalPlayer.PlayerGui

local trackedTargets = {}

local function removeESP(char)
    local data = trackedTargets[char]
    if not data then return end
    
    for _, conn in ipairs(data.connections) do
        conn:Disconnect()
    end
    data.connections = {} 

    if data.highlight then data.highlight:Destroy() end
    if data.billboard then data.billboard:Destroy() end
    
    data.highlight = nil
    data.billboard = nil
    trackedTargets[char] = nil
end

local function isEnemy(targetModel)
    local targetPlayer = Players:GetPlayerFromCharacter(targetModel)
    if targetPlayer then
        if not targetPlayer.Team or not LocalPlayer.Team then return true end
        return targetPlayer.Team ~= LocalPlayer.Team
    end
    return true -- NPCs are always considered enemies
end

local function applyESP(char)
    if trackedTargets[char] then removeESP(char) end

    local root = char:WaitForChild("HumanoidRootPart", 10)
    local humanoid = char:WaitForChild("Humanoid", 10)
    if not root or not humanoid then return end

    local data = { connections = {}, highlight = nil, billboard = nil }
    trackedTargets[char] = data

    local highlight = Instance.new("Highlight")
    highlight.FillColor = Config.ESP_BoxColor
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.Adornee = char
    highlight.Parent = char
    data.highlight = highlight

    local billboard = Instance.new("BillboardGui")
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 120, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.Parent = root
    data.billboard = billboard

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    
    -- Dynamically assign tag based on Player name vs NPC character model name
    local targetPlayer = Players:GetPlayerFromCharacter(char)
    nameLabel.Text = targetPlayer and targetPlayer.Name or ("[NPC] " .. char.Name)
    
    nameLabel.TextColor3 = Config.ESP_NameColor
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard

    local renderConn = RunService.RenderStepped:Connect(function()
        if not char.Parent or not humanoid or humanoid.Health <= 0 then
            highlight.Enabled = false
            billboard.Enabled = false
            return
        end

        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end

        local isTargetEnemy = isEnemy(char)
        local dist = (root.Position - myRoot.Position).Magnitude
        
        local visible = Config.Master_Enabled 
            and Config.ESP_Enabled 
            and dist <= Config.ESP_MaxDistance 
            and isTargetEnemy 

        highlight.Enabled = visible
        billboard.Enabled = visible
    end)
    
    table.insert(data.connections, renderConn)
end

-- ============================================================
-- TRACER LINES
-- ============================================================
local tracerLines = {}

local function getOrCreateTracer(char)
    if not tracerLines[char] then
        local line = Drawing.new("Line")
        line.Thickness = Config.Tracer_Thickness
        line.Color = Config.Tracer_Color
        line.Transparency = 0.7
        line.Visible = false
        tracerLines[char] = line
    end
    return tracerLines[char]
end

local function cleanupTracer(char)
    if tracerLines[char] then
        tracerLines[char]:Remove()
        tracerLines[char] = nil
    end
end

-- ============================================================
-- OPTIMIZED LAG-FREE TARGET FUNCTION
-- ============================================================
local function getClosestTarget(ignoreFOV)
    local closestTarget = nil
    local closestDist = ignoreFOV and math.huge or Config.Aimbot_FOV
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        
    -- OPTIMIZATION: Loop only through actual real players instead of the entire workspace
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        local char = player.Character
        if not char then continue end
        
        if Config.Aimbot_TeamCheck and not isEnemy(char) then continue end

        local targetPart = char:FindFirstChild(Config.Aimbot_TargetPart) or char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChild("Humanoid")
        if not targetPart or not humanoid or humanoid.Health <= 0 then continue end

        if ignoreFOV then
            if myRoot then
                local dist = (targetPart.Position - myRoot.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestTarget = char
                end
            end
        else
            local screenPos, onScreen = Camera:WorldToScreenPoint(targetPart.Position)
            if not onScreen then continue end

            local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
            if dist < closestDist then
                closestDist = dist
                closestTarget = char
            end
        end
    end

    return closestTarget
end

-- ============================================================
-- MAIN RENDERING LOOP
-- ============================================================
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1.5
fovCircle.Color = Color3.fromRGB(255, 80, 80)
fovCircle.Filled = false
fovCircle.Transparency = 0.7
fovCircle.Visible = false
fovCircle.Radius = Config.Aimbot_FOV

local mouse1Down = false

RunService.RenderStepped:Connect(function()
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    fovCircle.Visible = Config.Master_Enabled and Config.Aimbot_Enabled

    -- Manage Tracers for all visible entities in tracked pool
    for char, data in pairs(trackedTargets) do
        local line = getOrCreateTracer(char)
        local root = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChild("Humanoid")

        if not Config.Master_Enabled or not Config.Tracer_Enabled or not root or not humanoid or humanoid.Health <= 0 then
            line.Visible = false
            continue
        end

        local screenPos, onScreen = Camera:WorldToScreenPoint(root.Position)
        if not onScreen then
            line.Visible = false
            continue
        end

        line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        line.To = Vector2.new(screenPos.X, screenPos.Y)
        line.Visible = true
    end

    if not Config.Master_Enabled or not Config.Aimbot_Enabled then return end
    if Config.TeleportLoop_Enabled then return end

    if not UserInputService:IsKeyDown(Config.Aimbot_Key) then
        if mouse1Down then
            mouse1Down = false
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end
        return
    end

    local targetChar = getClosestTarget(false)
    if not targetChar then return end

    local targetPart = targetChar:FindFirstChild(Config.Aimbot_TargetPart) or targetChar:FindFirstChild("HumanoidRootPart")
    if not targetPart then return end

    local targetPosition = targetPart.Position
    if Config.Prediction_Enabled then
        local rootPart = targetChar:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local velocity = rootPart.AssemblyLinearVelocity
            targetPosition = targetPosition + (velocity * Config.Prediction_Strength)
        end
    end

    local _, onScreen = Camera:WorldToScreenPoint(targetPosition)
    if not onScreen then return end

    local targetCF = CFrame.new(Camera.CFrame.Position, targetPosition)
    Camera.CFrame = Camera.CFrame:Lerp(targetCF, Config.Aimbot_Smoothness)

    if Config.AutoFire_Enabled and not mouse1Down then
        mouse1Down = true
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    end
end)

-- ============================================================
-- TELEPORT + RAGE SHOOT LOOP
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.1) 
        if Config.Master_Enabled and Config.TeleportLoop_Enabled then
            local targetChar = getClosestTarget(true) 
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            
            if targetChar and myRoot then
                local tRoot = targetChar:FindFirstChild("HumanoidRootPart")
                local tHead = targetChar:FindFirstChild("Head")
                
                if tRoot and tHead then
                    myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 3)
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, tHead.Position)
                    
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                    task.wait(0.02)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                end
            end
        end
    end
end)

-- ============================================================
-- ESP INITIALIZATION & WORKSPACE SCANNERS
-- ============================================================
local function checkAndSetup(descendant)
    if descendant:IsA("Humanoid") and descendant.Parent then
        local char = descendant.Parent
        if char ~= LocalPlayer.Character then
            task.spawn(applyESP, char)
        end
    end
end

-- Initialize workspace elements
for _, desc in ipairs(workspace:GetDescendants()) do
    checkAndSetup(desc)
end

-- Track newly incoming instances (NPC Spawning / Player Respawning)
workspace.DescendantAdded:Connect(function(desc)
    task.wait(0.2)
    checkAndSetup(desc)
end)

workspace.DescendantRemoving:Connect(function(desc)
    if desc:IsA("Humanoid") and desc.Parent then
        removeESP(desc.Parent)
        cleanupTracer(desc.Parent)
    end
end)

-- ============================================================
-- KEYBINDS
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    if input.KeyCode == Enum.KeyCode.P then
        Config.Master_Enabled = not Config.Master_Enabled
        print("[MASTER SWITCH] " .. (Config.Master_Enabled and "ENABLED" or "DISABLED"))
        
        if not Config.Master_Enabled then
            fovCircle.Visible = false
            for _, line in pairs(tracerLines) do
                line.Visible = false
            end
            if mouse1Down then
                mouse1Down = false
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end
        end
    end

    if input.KeyCode == Enum.KeyCode.T then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = hum.WalkSpeed + Config.Speed_Step
            print("[Speed] Increased to " .. hum.WalkSpeed)
        end
    end
    
    if input.KeyCode == Enum.KeyCode.Y then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = math.max(0, hum.WalkSpeed - Config.Speed_Step)
            print("[Speed] Decreased to " .. hum.WalkSpeed)
        end
    end

    if input.KeyCode == Enum.KeyCode.H then
        Config.TeleportLoop_Enabled = not Config.TeleportLoop_Enabled
        print("[Teleport Loop] " .. (Config.TeleportLoop_Enabled and "ENABLED" or "DISABLED"))
    end

    if input.KeyCode == Enum.KeyCode.F1 then
        Config.ESP_Enabled = not Config.ESP_Enabled
        print("[ESP] " .. (Config.ESP_Enabled and "ON" or "OFF"))
    end
    if input.KeyCode == Enum.KeyCode.F2 then
        Config.Aimbot_Enabled = not Config.Aimbot_Enabled
        print("[Aimbot] " .. (Config.Aimbot_Enabled and "ON" or "OFF"))
    end
    if input.KeyCode == Enum.KeyCode.F3 then
        Config.Tracer_Enabled = not Config.Tracer_Enabled
        print("[Tracers] " .. (Config.Tracer_Enabled and "ON" or "OFF"))
    end
    if input.KeyCode == Enum.KeyCode.F4 then
        Config.Prediction_Enabled = not Config.Prediction_Enabled
        print("[Prediction] " .. (Config.Prediction_Enabled and "ON" or "OFF"))
    end
    if input.KeyCode == Enum.KeyCode.F5 then
        Config.AutoFire_Enabled = not Config.AutoFire_Enabled
        if not Config.AutoFire_Enabled and mouse1Down then
            mouse1Down = false
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end
        print("[AutoFire] " .. (Config.AutoFire_Enabled and "ON" or "OFF"))
    end
end)

print("Loaded. P = Master Toggle | T/Y = Adjust Speed | H = Toggle Teleport Loop | F1-F5 = Visual Toggles")
