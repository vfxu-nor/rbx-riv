-- ESP + Hard Aimbot LocalScript
-- Place in StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ============================================================
-- CONFIG
-- ============================================================
local Config = {
    ESP_Enabled = true,
    ESP_BoxColor = Color3.fromRGB(255, 50, 50),
    ESP_NameColor = Color3.fromRGB(255, 255, 255),
    ESP_MaxDistance = 500,

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
}

-- ============================================================
-- ESP
-- ============================================================
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "ESPFolder"
ESPFolder.Parent = LocalPlayer.PlayerGui

local trackedPlayers = {}

local function removeESP(player)
    local data = trackedPlayers[player]
    if not data then return end
    
    -- Disconnect all loops for this player
    for _, conn in ipairs(data.connections) do
        conn:Disconnect()
    end
    data.connections = {} -- Clear the list

    if data.highlight then data.highlight:Destroy() end
    if data.billboard then data.billboard:Destroy() end
    
    data.highlight = nil
    data.billboard = nil
end

local function isEnemy(player)
    if not player.Team or not LocalPlayer.Team then return true end
    
    return player.Team ~= LocalPlayer.Team
end

local function applyESP(player, char)
    local data = trackedPlayers[player]
    if not data then return end

    -- Clean up previous round's visuals
    if data.highlight then data.highlight:Destroy() end
    if data.billboard then data.billboard:Destroy() end

    local root = char:WaitForChild("HumanoidRootPart", 10)
    local humanoid = char:WaitForChild("Humanoid", 10)
    if not root or not humanoid then return end

    -- Create Visuals
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
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Config.ESP_NameColor
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard

    -- THE FIX: Save the connection normally
    local renderConn = RunService.RenderStepped:Connect(function()
        if not char.Parent or not humanoid or humanoid.Health <= 0 then
            highlight.Enabled = false
            billboard.Enabled = false
            return
        end

        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end

    local isTargetEnemy = isEnemy(player)
    local dist = (root.Position - myRoot.Position).Magnitude
    
    local visible = Config.ESP_Enabled 
        and dist <= Config.ESP_MaxDistance 
        and isTargetEnemy 

    highlight.Enabled = visible
    billboard.Enabled = visible
    end)
    
    table.insert(data.connections, renderConn)
end

local function addPlayer(player)
    if player == LocalPlayer then return end
    
    trackedPlayers[player] = { connections = {}, highlight = nil, billboard = nil }

    local function setup()
        if player.Character then
            task.spawn(applyESP, player, player.Character)
        end
    end

    -- Initial setup
    setup()

    -- New Round Listener
    player.CharacterAdded:Connect(function(char)
        task.wait(0.5) -- Wait for game to position the character
        removeESP(player) -- Wipe old round data
        setup() -- Apply new round data
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(addPlayer, player)
end

Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(removeESP)

-- ============================================================
-- TRACER LINES
-- ============================================================
local tracerLines = {}

local function getOrCreateTracer(player)
    if not tracerLines[player] then
        local line = Drawing.new("Line")
        line.Thickness = Config.Tracer_Thickness
        line.Color = Config.Tracer_Color
        line.Transparency = 0.7
        line.Visible = false
        tracerLines[player] = line
    end
    return tracerLines[player]
end

local function cleanupTracer(player)
    if tracerLines[player] then
        tracerLines[player]:Remove()
        tracerLines[player] = nil
    end
end

Players.PlayerRemoving:Connect(cleanupTracer)

-- ============================================================
-- AIMBOT
-- ============================================================
local function getClosestPlayer()
local closestPlayer = nil
    local closestDist = Config.Aimbot_FOV
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not isEnemy(player) then continue end
        if Config.Aimbot_TeamCheck
            and LocalPlayer.Team ~= nil
            and player.Team == LocalPlayer.Team then
            continue
        end

        local char = player.Character
        if not char then continue end

        local targetPart = char:FindFirstChild(Config.Aimbot_TargetPart)
            or char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChild("Humanoid")
        if not targetPart or not humanoid or humanoid.Health <= 0 then continue end

        local screenPos, onScreen = Camera:WorldToScreenPoint(targetPart.Position)
        if not onScreen then continue end

        local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
        if dist < closestDist then
            closestDist = dist
            closestPlayer = player
        end
    end

    return closestPlayer
end

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
    fovCircle.Visible = Config.Aimbot_Enabled

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local line = getOrCreateTracer(player)
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChild("Humanoid")

        if not Config.Tracer_Enabled or not root or not humanoid or humanoid.Health <= 0 then
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

    if not Config.Aimbot_Enabled then return end
    if not UserInputService:IsKeyDown(Config.Aimbot_Key) then
        if mouse1Down then
            mouse1Down = false
            UserInputService:GetMouseButtonsPressed()
            game:GetService("VirtualInputManager"):SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end
        return
    end

    local target = getClosestPlayer()
    if not target then return end

    local char = target.Character
    if not char then return end

    local targetPart = char:FindFirstChild(Config.Aimbot_TargetPart)
        or char:FindFirstChild("HumanoidRootPart")
    if not targetPart then return end

    -- Prediction: offset aim by velocity
    local targetPosition = targetPart.Position
    if Config.Prediction_Enabled then
        local rootPart = char:FindFirstChild("HumanoidRootPart")
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
        game:GetService("VirtualInputManager"):SendMouseButtonEvent(0, 0, 0, true, game, 0)
    end
end)

-- ============================================================
-- KEYBINDS
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
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
            game:GetService("VirtualInputManager"):SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end
        print("[AutoFire] " .. (Config.AutoFire_Enabled and "ON" or "OFF"))
    end
end)

print("Loaded. F1 = ESP | F2 = Aimbot | Hold X = Aim")
