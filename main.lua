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
    Aimbot_Smoothness = 0.55,
    Aimbot_FOV = 500,
    Aimbot_TargetPart = "Head",
    Aimbot_TeamCheck = true,
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
    for _, conn in ipairs(data.connections) do
        conn:Disconnect()
    end
    if data.highlight then data.highlight:Destroy() end
    if data.billboard then data.billboard:Destroy() end
    trackedPlayers[player] = nil
end

local function applyESP(player, char)
    local data = trackedPlayers[player]
    if not data then return end

    if data.highlight then data.highlight:Destroy() end
    if data.billboard then data.billboard:Destroy() end

    -- Remove old render connections
    for i = #data.connections, 1, -1 do
        if data.connections[i]._isRender then
            data.connections[i]:Disconnect()
            table.remove(data.connections, i)
        end
    end

    local root = char:WaitForChild("HumanoidRootPart", 10)
    local humanoid = char:WaitForChild("Humanoid", 10)
    if not root or not humanoid then return end

    local highlight = Instance.new("Highlight")
    highlight.FillColor = Config.ESP_BoxColor
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
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

    local renderConn = RunService.RenderStepped:Connect(function()
        if not char.Parent then
            highlight.Enabled = false
            billboard.Enabled = false
            return
        end

        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end

        local dist = (root.Position - myRoot.Position).Magnitude
        local alive = humanoid.Health > 0
        local visible = Config.ESP_Enabled and dist <= Config.ESP_MaxDistance and alive

        highlight.Enabled = visible
        billboard.Enabled = visible

        if visible then
            local hp = math.floor(humanoid.Health)
            local maxHp = math.max(math.floor(humanoid.MaxHealth), 1)
            healthLabel.Text = hp .. " / " .. maxHp
            local ratio = hp / maxHp
            healthLabel.TextColor3 = Color3.fromRGB(
                math.floor((1 - ratio) * 255),
                math.floor(ratio * 255),
                50
            )
        end
    end)
    renderConn._isRender = true
    table.insert(data.connections, renderConn)
end

local function addPlayer(player)
    if player == LocalPlayer then return end
    if trackedPlayers[player] then return end

    trackedPlayers[player] = { connections = {}, highlight = nil, billboard = nil }

    if player.Character and player.Character.Parent then
        task.spawn(applyESP, player, player.Character)
    end

    local charConn = player.CharacterAdded:Connect(function(char)
        task.spawn(applyESP, player, char)
    end)
    table.insert(trackedPlayers[player].connections, charConn)
end

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(addPlayer, player)
end

Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(removeESP)

-- ============================================================
-- AIMBOT
-- ============================================================
local function getClosestPlayer()
    local closestPlayer = nil
    local closestDist = Config.Aimbot_FOV
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
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

print("Loaded. F1 = ESP | F2 = Aimbot | Hold X = Aim")
