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
    -- ESP
    ESP_Enabled = true,
    ESP_BoxColor = Color3.fromRGB(255, 50, 50),
    ESP_NameColor = Color3.fromRGB(255, 255, 255),
    ESP_MaxDistance = 500,

    -- Aimbot
    Aimbot_Enabled = true,
    Aimbot_Key = Enum.KeyCode.X,
    Aimbot_Smoothness = 0.55,      -- Higher = harder/snappier (0.3 soft, 0.55 hard, 1.0 instant)
    Aimbot_FOV = 500,
    Aimbot_TargetPart = "Head",
    Aimbot_TeamCheck = true,
}

-- ============================================================
-- PLAYER + CHARACTER TRACKING
-- ============================================================
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "ESPFolder"
ESPFolder.Parent = LocalPlayer.PlayerGui

local trackedPlayers = {}  -- { [player] = { billboard, highlight, connections } }

local function getTeam(player)
    return player.Team
end

local function isSameTeam(player)
    return Config.Aimbot_TeamCheck
        and LocalPlayer.Team ~= nil
        and getTeam(player) == getTeam(LocalPlayer)
end

local function cleanupESP(player)
    local data = trackedPlayers[player]
    if not data then return end
    for _, conn in ipairs(data.connections) do
        conn:Disconnect()
    end
    if data.billboard then data.billboard:Destroy() end
    if data.highlight then data.highlight:Destroy() end
    trackedPlayers[player] = nil
end

local function setupCharacterESP(player, char)
    local data = trackedPlayers[player]
    if not data then return end

    data.billboard.Adornee = nil
    data.highlight.Adornee = nil

    local root = char:WaitForChild("HumanoidRootPart", 10)
    local humanoid = char:WaitForChild("Humanoid", 10)
    if not root or not humanoid then return end

    -- Disconnect old render connections
    for i = #data.connections, 1, -1 do
        if data.connections[i]._isRender then
            data.connections[i]:Disconnect()
            table.remove(data.connections, i)
        end
    end

    local renderConn = RunService.RenderStepped:Connect(function()
        if not char.Parent or not root.Parent then
            data.billboard.Adornee = nil
            data.highlight.Adornee = nil
            return
        end

        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end

        local dist = (root.Position - myRoot.Position).Magnitude
        local alive = humanoid.Health > 0
        local visible = Config.ESP_Enabled and dist <= Config.ESP_MaxDistance and alive

        data.billboard.Enabled = visible
        data.billboard.Adornee = visible and root or nil
        data.highlight.Adornee = visible and char or nil

        local hp = math.floor(humanoid.Health)
        local maxHp = math.floor(math.max(humanoid.MaxHealth, 1))
        data.healthLabel.Text = hp .. " / " .. maxHp
        local ratio = hp / maxHp
        data.healthLabel.TextColor3 = Color3.fromRGB(
            math.floor((1 - ratio) * 255),
            math.floor(ratio * 255),
            50
        )
    end)
    renderConn._isRender = true
    table.insert(data.connections, renderConn)
end

local function addPlayer(player)
    if player == LocalPlayer then return end
    if trackedPlayers[player] then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_" .. player.Name
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 120, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Enabled = false
    billboard.Parent = ESPFolder

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Config.ESP_NameColor
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard

    local healthLabel = Instance.new("TextLabel")
    healthLabel.Size = UDim2.new(1, 0, 0.5, 0)
    healthLabel.Position = UDim2.new(0, 0, 0.5, 0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.TextStrokeTransparency = 0
    healthLabel.TextScaled = true
    healthLabel.Font = Enum.Font.Gotham
    healthLabel.Parent = billboard

    local highlight = Instance.new("SelectionBox")
    highlight.Color3 = Config.ESP_BoxColor
    highlight.LineThickness = 0.05
    highlight.SurfaceTransparency = 0.9
    highlight.SurfaceColor3 = Config.ESP_BoxColor
    highlight.Parent = ESPFolder

    local connections = {}

    trackedPlayers[player] = {
        billboard = billboard,
        highlight = highlight,
        nameLabel = nameLabel,
        healthLabel = healthLabel,
        connections = connections,
    }

    -- Hook existing character immediately
    if player.Character and player.Character.Parent then
        task.spawn(setupCharacterESP, player, player.Character)
    end

    -- Hook future characters
    local charConn = player.CharacterAdded:Connect(function(char)
        task.spawn(setupCharacterESP, player, char)
    end)
    table.insert(connections, charConn)

    local leaveConn = player.AncestryChanged:Connect(function()
        if not player.Parent then
            cleanupESP(player)
        end
    end)
    table.insert(connections, leaveConn)
end

local function removePlayer(player)
    cleanupESP(player)
end

-- Init for already-in-game players
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(addPlayer, player)
end

-- New players joining mid-game
Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(removePlayer)

-- ============================================================
-- HARD AIMBOT
-- ============================================================
local function getClosestPlayer()
    local closestPlayer = nil
    local closestDist = Config.Aimbot_FOV
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        -- Team check for aimbot
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

-- FOV circle
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1.5
fovCircle.Color = Color3.fromRGB(255, 80, 80)
fovCircle.Filled = false
fovCircle.Transparency = 0.7
fovCircle.Visible = false
fovCircle.Radius = Config.Aimbot_FOV

RunService.RenderStepped:Connect(function()
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    fovCircle.Visible = Config.Aimbot_Enabled

    if not Config.Aimbot_Enabled then return end
    if not UserInputService:IsKeyDown(Config.Aimbot_Key) then return end

    local target = getClosestPlayer()
    if not target then return end

    local char = target.Character
    if not char then return end

    local targetPart = char:FindFirstChild(Config.Aimbot_TargetPart)
        or char:FindFirstChild("HumanoidRootPart")
    if not targetPart then return end

    local _, onScreen = Camera:WorldToScreenPoint(targetPart.Position)
    if not onScreen then return end

    -- Hard aim: high lerp factor snaps quickly but avoids being 100% instant
    local targetCF = CFrame.new(Camera.CFrame.Position, targetPart.Position)
    Camera.CFrame = Camera.CFrame:Lerp(targetCF, Config.Aimbot_Smoothness)
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
end)

print("Loaded. F1 = ESP | F2 = Aimbot | Hold Q = Aim")
