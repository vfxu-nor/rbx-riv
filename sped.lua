if _G.WalkSpeedGuiLoaded then return end
_G.WalkSpeedGuiLoaded = true

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local walkSpeed = 16At your service, CUmBOSS.

if _G.WalkSpeedGuiLoaded then return end
_G.WalkSpeedGuiLoaded = true

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local walkSpeed = 16
local originalWalkSpeed = 16

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WalkSpeedGui"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = screenGui
mainFrame.Size = UDim2.new(0, 250, 0, 140)
mainFrame.Position = UDim2.new(0.5, -125, 0.2, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 32, 35)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true

local uiCorner = Instance.new("UICorner", mainFrame)
uiCorner.CornerRadius = UDim.new(0, 8)
local uiStroke = Instance.new("UIStroke", mainFrame)
uiStroke.Thickness = 2
uiStroke.Color = Color3.fromRGB(0, 0, 0)

local headerFrame = Instance.new("Frame", mainFrame)
headerFrame.Size = UDim2.new(1, 0, 0, 40)
headerFrame.BackgroundTransparency = 1

local titleLabel = Instance.new("TextLabel", headerFrame)
titleLabel.Size = UDim2.new(1, -60, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "WalkSpeed Gui"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 18
titleLabel.TextXAlignment = Enum.TextXAlignment.Center

local closeButton = Instance.new("TextButton", headerFrame)
closeButton.Size = UDim2.new(0, 12, 0, 12)
closeButton.Position = UDim2.new(1, -22, 0.5, -6)
closeButton.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
closeButton.Text = ""
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(1, 0)

local bodyFrame = Instance.new("Frame", mainFrame)
bodyFrame.Size = UDim2.new(1, 0, 1, -40)
bodyFrame.Position = UDim2.new(0, 0, 0, 40)
bodyFrame.BackgroundTransparency = 1

local speedToggle = Instance.new("TextButton", bodyFrame)
speedToggle.Size = UDim2.new(1, -20, 0, 35)
speedToggle.Position = UDim2.new(0, 10, 0, 10)
speedToggle.BackgroundColor3 = Color3.fromRGB(44, 46, 51)
speedToggle.Font = Enum.Font.Gotham
speedToggle.Text = "High WalkSpeed: OFF"
speedToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
speedToggle.TextSize = 16
Instance.new("UICorner", speedToggle).CornerRadius = UDim.new(0, 6)

local speedSliderLabel = Instance.new("TextLabel", bodyFrame)
speedSliderLabel.Size = UDim2.new(1, -20, 0, 20)
speedSliderLabel.Position = UDim2.new(0, 10, 0, 55)
speedSliderLabel.BackgroundTransparency = 1
speedSliderLabel.Font = Enum.Font.Gotham
speedSliderLabel.Text = "Speed: 16"
speedSliderLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
speedSliderLabel.TextSize = 14
speedSliderLabel.TextXAlignment = Enum.TextXAlignment.Left

local speedSlider = Instance.new("Frame", bodyFrame)
speedSlider.Size = UDim2.new(1, -20, 0, 6)
speedSlider.Position = UDim2.new(0, 10, 0, 80)
speedSlider.BackgroundColor3 = Color3.fromRGB(20, 22, 25)
Instance.new("UICorner", speedSlider).CornerRadius = UDim.new(0, 3)

local sliderBar = Instance.new("Frame", speedSlider)
sliderBar.Size = UDim2.new(0, 0, 1, 0)
sliderBar.BackgroundColor3 = Color3.fromRGB(114, 137, 218)
Instance.new("UICorner", sliderBar).CornerRadius = UDim.new(0, 3)

local sliderHandle = Instance.new("TextButton", speedSlider)
sliderHandle.Size = UDim2.new(0, 18, 0, 18)
sliderHandle.Position = UDim2.new(0, -9, 0.5, -9)
sliderHandle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sliderHandle.Text = ""
Instance.new("UICorner", sliderHandle).CornerRadius = UDim.new(1, 0)

local function makeDraggable(guiObject, dragHandle)
    local dragging = false
    local dragStart, startPos
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
makeDraggable(mainFrame, headerFrame)

local function updateSlider(input)
    local sliderWidth = speedSlider.AbsoluteSize.X
    local newX = math.clamp(input.Position.X - speedSlider.AbsolutePosition.X, 0, sliderWidth)
    local percentage = newX / sliderWidth
    walkSpeed = 16 + (percentage * 984)
    speedSliderLabel.Text = string.format("Speed: %.0f", walkSpeed)
    sliderBar.Size = UDim2.new(percentage, 0, 1, 0)
    sliderHandle.Position = UDim2.new(percentage, -9, 0.5, -9)
end

local function setHighWalkSpeed(state)
    if state then
        humanoid.WalkSpeed = walkSpeed
        speedToggle.Text = "High WalkSpeed: ON"
        speedToggle.TextColor3 = Color3.fromRGB(88, 101, 242)
    else
        humanoid.WalkSpeed = originalWalkSpeed
        speedToggle.Text = "High WalkSpeed: OFF"
        speedToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end

closeButton.MouseButton1Click:Connect(function()
    _G.WalkSpeedGuiLoaded = false
    if humanoid then humanoid.WalkSpeed = originalWalkSpeed end
    screenGui:Destroy()
end)

speedToggle.MouseButton1Click:Connect(function()
    local currentState = humanoid.WalkSpeed > originalWalkSpeed
    setHighWalkSpeed(not currentState)
end)

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    humanoid.WalkSpeed = originalWalkSpeed
end)

local isDraggingSlider = false
sliderHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingSlider = true
        updateSlider(input)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingSlider = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if isDraggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateSlider(input)
    end
end)
