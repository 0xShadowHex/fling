local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("ChopperHub") then
    playerGui.ChopperHub:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ChopperHub"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local correctKey = "key_C9h0pP1eR4xS7tV2wM5kY8uB3dA6"
local isMobile = UserInputService.TouchEnabled

local settings = {
    FlingPower = 30000,
    FlingDuration = 2.0,
    TeleportBack = true,
    LoopFling = false,
    GhostMode = true
}

local state = {
    ActiveFlingTarget = nil,
    FlingConnection = nil,
    NoClipConnection = nil,
    OriginalCFrame = nil,
    Minimized = false
}

local function corner(parent, radius)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, radius or 8)
    return c
end

local function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke", parent)
    s.Color = color or Color3.fromRGB(200, 150, 70)
    s.Thickness = thickness or 1.2
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Transparency = transparency or 0.4
    return s
end

local function bindHoverEffect(button, defaultBg, hoverBg, defaultText, hoverText, defaultStroke, hoverStroke)
    local bTween = nil
    local tTween = nil
    local sTween = nil
    
    local strokeObj = button:FindFirstChildOfClass("UIStroke")
    local textObj = button:FindFirstChildOfClass("TextLabel") or (button:IsA("TextButton") and button)
    
    button.MouseEnter:Connect(function()
        if bTween then bTween:Cancel() end
        bTween = TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = hoverBg})
        bTween:Play()
        
        if textObj and textObj:IsA("TextLabel") and hoverText then
            if tTween then tTween:Cancel() end
            tTween = TweenService:Create(textObj, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = hoverText})
            tTween:Play()
        end
        
        if strokeObj and hoverStroke then
            if sTween then sTween:Cancel() end
            sTween = TweenService:Create(strokeObj, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Color = hoverStroke})
            sTween:Play()
        end
    end)
    
    button.MouseLeave:Connect(function()
        if bTween then bTween:Cancel() end
        bTween = TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = defaultBg})
        bTween:Play()
        
        if textObj and textObj:IsA("TextLabel") and defaultText then
            if tTween then tTween:Cancel() end
            tTween = TweenService:Create(textObj, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = defaultText})
            tTween:Play()
        end
        
        if strokeObj and defaultStroke then
            if sTween then sTween:Cancel() end
            sTween = TweenService:Create(strokeObj, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Color = defaultStroke})
            sTween:Play()
        end
    end)
end

local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function showNotification(title, text, color, duration)
    duration = duration or 3.5
    local container = screenGui:FindFirstChild("Notifications")
    if not container then
        container = Instance.new("Frame")
        container.Name = "Notifications"
        container.Size = UDim2.new(0, 280, 1, -20)
        container.Position = UDim2.new(1, -290, 0, 10)
        container.BackgroundTransparency = 1
        container.Parent = screenGui
        
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 10)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        layout.VerticalAlignment = Enum.VerticalAlignment.Top
        layout.Parent = container
    end
    
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 68)
    card.BackgroundColor3 = Color3.fromRGB(22, 14, 8)
    card.BackgroundTransparency = 0.25
    card.BorderSizePixel = 0
    card.ClipsDescendants = true
    card.Parent = container
    
    corner(card, 10)
    stroke(card, color or Color3.fromRGB(200, 150, 70), 1.2, 0.3)
    
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 30, 15)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(22, 14, 8))
    })
    grad.Rotation = 45
    grad.Parent = card
    
    local tLabel = Instance.new("TextLabel")
    tLabel.Size = UDim2.new(1, -20, 0, 22)
    tLabel.Position = UDim2.new(0, 12, 0, 8)
    tLabel.BackgroundTransparency = 1
    tLabel.Text = title
    tLabel.TextColor3 = color or Color3.fromRGB(230, 180, 100)
    tLabel.TextSize = 13
    tLabel.Font = Enum.Font.GothamBold
    tLabel.TextXAlignment = Enum.TextXAlignment.Left
    tLabel.Parent = card
    
    local bLabel = Instance.new("TextLabel")
    bLabel.Size = UDim2.new(1, -24, 0, 32)
    bLabel.Position = UDim2.new(0, 12, 0, 28)
    bLabel.BackgroundTransparency = 1
    bLabel.Text = text
    bLabel.TextColor3 = Color3.fromRGB(230, 210, 190)
    bLabel.TextSize = 11
    bLabel.Font = Enum.Font.Gotham
    bLabel.TextWrapped = true
    bLabel.TextXAlignment = Enum.TextXAlignment.Left
    bLabel.Parent = card
    
    local s = Instance.new("Sound", screenGui)
    s.SoundId = "rbxassetid://4590662766"
    s.Volume = 0.5
    s:Play()
    game:GetService("Debris"):AddItem(s, 2)
    
    card.Position = UDim2.new(1, 300, 0, 0)
    TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
    
    task.delay(duration, function()
        local t = TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(1, 300, 0, 0), BackgroundTransparency = 1})
        t:Play()
        t.Completed:Connect(function()
            card:Destroy()
        end)
    end)
end

local mainPanel = Instance.new("Frame")
mainPanel.Name = "MainPanel"
mainPanel.Size = UDim2.new(0, 360, 0, 380)
mainPanel.Position = UDim2.new(0.5, -180, 0.5, -190)
mainPanel.BackgroundColor3 = Color3.fromRGB(20, 14, 8)
mainPanel.BackgroundTransparency = 0.3
mainPanel.BorderSizePixel = 0
mainPanel.Visible = false
mainPanel.ClipsDescendants = true
mainPanel.Parent = screenGui
corner(mainPanel, 14)
stroke(mainPanel, Color3.fromRGB(200, 150, 70), 1.5, 0.35)

local mainGrad = Instance.new("UIGradient")
mainGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 30, 15)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(75, 50, 25)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(22, 14, 8))
})
mainGrad.Rotation = 45
mainGrad.Parent = mainPanel

local minFloat = Instance.new("TextButton")
minFloat.Name = "MinFloat"
minFloat.Size = UDim2.new(0, 50, 0, 50)
minFloat.Position = UDim2.new(0.9, 0, 0.85, 0)
minFloat.BackgroundColor3 = Color3.fromRGB(30, 20, 10)
minFloat.BackgroundTransparency = 0.3
minFloat.Text = "CH"
minFloat.TextColor3 = Color3.fromRGB(250, 220, 180)
minFloat.Font = Enum.Font.GothamBold
minFloat.TextSize = 14
minFloat.Visible = false
minFloat.Parent = screenGui
corner(minFloat, 25)
stroke(minFloat, Color3.fromRGB(200, 150, 70), 1.5, 0.3)

local floatGrad = Instance.new("UIGradient")
floatGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 40, 20)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 20, 10))
})
floatGrad.Rotation = 45
floatGrad.Parent = minFloat

local keyWindow = Instance.new("Frame")
keyWindow.Name = "KeyWindow"
keyWindow.Size = UDim2.new(0, 340, 0, 210)
keyWindow.Position = UDim2.new(0.5, -170, 0.5, -105)
keyWindow.BackgroundColor3 = Color3.fromRGB(22, 15, 8)
keyWindow.BackgroundTransparency = 0.3
keyWindow.BorderSizePixel = 0
keyWindow.ClipsDescendants = true
keyWindow.Parent = screenGui
corner(keyWindow, 14)
stroke(keyWindow, Color3.fromRGB(200, 150, 70), 1.5, 0.35)

local keyGrad = Instance.new("UIGradient")
keyGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 32, 15)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(75, 48, 22)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 15, 8))
})
keyGrad.Rotation = 45
keyGrad.Parent = keyWindow

makeDraggable(keyWindow)
makeDraggable(mainPanel, mainPanel:WaitForChild("TitleBar", 1))
makeDraggable(minFloat, minFloat)

local keyTitle = Instance.new("TextLabel")
keyTitle.Size = UDim2.new(1, 0, 0, 45)
keyTitle.BackgroundTransparency = 1
keyTitle.Text = "CHOPPER HUB | KEY SYSTEM"
keyTitle.TextColor3 = Color3.fromRGB(250, 220, 180)
keyTitle.TextSize = 13
keyTitle.Font = Enum.Font.GothamBold
keyTitle.Parent = keyWindow

local keyInput = Instance.new("TextBox")
keyInput.Size = UDim2.new(0, 280, 0, 36)
keyInput.Position = UDim2.new(0.5, -140, 0, 65)
keyInput.BackgroundColor3 = Color3.fromRGB(32, 20, 12)
keyInput.BackgroundTransparency = 0.5
keyInput.BorderSizePixel = 0
keyInput.PlaceholderText = "Enter Activation Key..."
keyInput.PlaceholderColor3 = Color3.fromRGB(150, 120, 90)
keyInput.Text = ""
keyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
keyInput.TextSize = 12
keyInput.Font = Enum.Font.Gotham
keyInput.Parent = keyWindow
corner(keyInput, 8)
stroke(keyInput, Color3.fromRGB(150, 110, 60), 1, 0.5)

local verifyBtn = Instance.new("TextButton")
verifyBtn.Size = UDim2.new(0, 135, 0, 34)
verifyBtn.Position = UDim2.new(0.5, -140, 0, 115)
verifyBtn.BackgroundColor3 = Color3.fromRGB(80, 50, 20)
verifyBtn.BackgroundTransparency = 0.4
verifyBtn.Text = "Verify Key"
verifyBtn.TextColor3 = Color3.fromRGB(250, 220, 180)
verifyBtn.TextSize = 12
verifyBtn.Font = Enum.Font.GothamBold
verifyBtn.Parent = keyWindow
corner(verifyBtn, 8)
stroke(verifyBtn, Color3.fromRGB(200, 150, 70), 1, 0.4)

local getKeyBtn = Instance.new("TextButton")
getKeyBtn.Size = UDim2.new(0, 135, 0, 34)
getKeyBtn.Position = UDim2.new(0.5, 5, 0, 115)
getKeyBtn.BackgroundColor3 = Color3.fromRGB(50, 32, 15)
getKeyBtn.BackgroundTransparency = 0.4
getKeyBtn.Text = "Get Key Link"
getKeyBtn.TextColor3 = Color3.fromRGB(220, 190, 150)
getKeyBtn.TextSize = 12
getKeyBtn.Font = Enum.Font.GothamBold
getKeyBtn.Parent = keyWindow
corner(getKeyBtn, 8)
stroke(getKeyBtn, Color3.fromRGB(150, 110, 50), 1, 0.4)

local keyStatus = Instance.new("TextLabel")
keyStatus.Size = UDim2.new(1, 0, 0, 30)
keyStatus.Position = UDim2.new(0, 0, 1, -35)
keyStatus.BackgroundTransparency = 1
keyStatus.Text = "Required to verify authorization"
keyStatus.TextColor3 = Color3.fromRGB(180, 160, 140)
keyStatus.TextSize = 11
keyStatus.Font = Enum.Font.Gotham
keyStatus.Parent = keyWindow

bindHoverEffect(verifyBtn, Color3.fromRGB(80, 50, 20), Color3.fromRGB(100, 65, 30), Color3.fromRGB(250, 220, 180), Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 150, 70), Color3.fromRGB(230, 180, 100))
bindHoverEffect(getKeyBtn, Color3.fromRGB(50, 32, 15), Color3.fromRGB(70, 45, 25), Color3.fromRGB(220, 190, 150), Color3.fromRGB(250, 220, 180), Color3.fromRGB(150, 110, 50), Color3.fromRGB(200, 150, 70))

local function shakeWindow(frame)
    local originalPos = frame.Position
    for i = 1, 6 do
        local offset = (i % 2 == 0 and 8 or -8)
        frame.Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset + offset, originalPos.Y.Scale, originalPos.Y.Offset)
        task.wait(0.04)
    end
    frame.Position = originalPos
end

local function launchMainPanel()
    showNotification("Welcome!", "ChopperHub Loaded Successfully.", Color3.fromRGB(230, 180, 100))
    
    local kt = TweenService:Create(keyWindow, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 340, 0, 0), Position = UDim2.new(0.5, -170, 0.5, 0)})
    kt:Play()
    kt.Completed:Connect(function()
        keyWindow:Destroy()
    end)
    
    task.wait(0.35)
    
    mainPanel.Visible = true
    mainPanel.Size = UDim2.new(0, 360, 0, 0)
    mainPanel.Position = UDim2.new(0.5, -180, 0.5, 0)
    local mt = TweenService:Create(mainPanel, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 360, 0, 380), Position = UDim2.new(0.5, -180, 0.5, -190)})
    mt:Play()
end

verifyBtn.MouseButton1Click:Connect(function()
    if keyInput.Text == correctKey then
        launchMainPanel()
    else
        keyStatus.Text = "Invalid Key! Please try again."
        keyStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        shakeWindow(keyWindow)
        
        local s = Instance.new("Sound", screenGui)
        s.SoundId = "rbxassetid://4590662919"
        s.Volume = 0.5
        s:Play()
        game:GetService("Debris"):AddItem(s, 2)
    end
end)

getKeyBtn.MouseButton1Click:Connect(function()
    local keyUrl = "https://discord.gg/36EuJKqNeF"
    if setclipboard or toclipboard then
        local copy = setclipboard or toclipboard
        copy(keyUrl)
        showNotification("Key Link Copied!", "Link copied to your clipboard.", Color3.fromRGB(230, 180, 100))
    else
        showNotification("Link", "Link: discord.gg/36EuJKqNeF", Color3.fromRGB(230, 180, 100))
    end
    keyStatus.TextColor3 = Color3.fromRGB(230, 180, 100)
end)

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 48)
titleBar.BackgroundColor3 = Color3.fromRGB(35, 22, 12)
titleBar.BackgroundTransparency = 0.4
titleBar.BorderSizePixel = 0
titleBar.Parent = mainPanel
corner(titleBar, 14)

local tBarGrad = Instance.new("UIGradient")
tBarGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 38, 20)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 22, 12))
})
tBarGrad.Parent = titleBar

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, -100, 1, 0)
titleLbl.Position = UDim2.new(0, 16, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "CHOPPER HUB"
titleLbl.TextColor3 = Color3.fromRGB(250, 220, 180)
titleLbl.TextSize = 13
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -34, 0.5, -13)
closeBtn.BackgroundColor3 = Color3.fromRGB(75, 20, 25)
closeBtn.BackgroundTransparency = 0.3
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 120, 130)
closeBtn.TextSize = 11
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar
corner(closeBtn, 13)
stroke(closeBtn, Color3.fromRGB(200, 50, 70), 1, 0.4)

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 26, 0, 26)
minBtn.Position = UDim2.new(1, -68, 0.5, -13)
minBtn.BackgroundColor3 = Color3.fromRGB(45, 30, 15)
minBtn.BackgroundTransparency = 0.3
minBtn.Text = "-"
minBtn.TextColor3 = Color3.fromRGB(220, 190, 150)
minBtn.TextSize = 11
minBtn.Font = Enum.Font.GothamBold
minBtn.Parent = titleBar
corner(minBtn, 13)
stroke(minBtn, Color3.fromRGB(200, 150, 70), 1, 0.4)

bindHoverEffect(closeBtn, Color3.fromRGB(75, 20, 25), Color3.fromRGB(110, 25, 40), Color3.fromRGB(255, 120, 130), Color3.fromRGB(255, 170, 190), Color3.fromRGB(200, 50, 70), Color3.fromRGB(255, 80, 100))
bindHoverEffect(minBtn, Color3.fromRGB(45, 30, 15), Color3.fromRGB(65, 42, 22), Color3.fromRGB(220, 190, 150), Color3.fromRGB(250, 220, 180), Color3.fromRGB(200, 150, 70), Color3.fromRGB(230, 180, 100))

local function toggleMinimize()
    state.Minimized = not state.Minimized
    if state.Minimized then
        local t = TweenService:Create(mainPanel, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 360, 0, 0), Position = UDim2.new(0.5, -180, 0.5, 0)})
        t:Play()
        t.Completed:Connect(function()
            if state.Minimized then
                mainPanel.Visible = false
                minFloat.Visible = true
                minFloat.Size = UDim2.new(0, 0, 0, 0)
                TweenService:Create(minFloat, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 50, 0, 50)}):Play()
            end
        end)
    else
        local t = TweenService:Create(minFloat, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)})
        t:Play()
        t.Completed:Connect(function()
            if not state.Minimized then
                minFloat.Visible = false
                mainPanel.Visible = true
                TweenService:Create(mainPanel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 360, 0, 380), Position = UDim2.new(0.5, -180, 0.5, -190)}):Play()
            end
        end)
    end
end

minBtn.MouseButton1Click:Connect(toggleMinimize)

local dragThreshold = 6
local dragStartPos = nil

minFloat.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragStartPos = input.Position
    end
end)

minFloat.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if dragStartPos then
            local dist = (input.Position - dragStartPos).Magnitude
            if dist < dragThreshold then
                toggleMinimize()
            end
        end
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    if state.FlingConnection then state.FlingConnection:Disconnect() end
    if state.NoClipConnection then state.NoClipConnection:Disconnect() end
    screenGui:Destroy()
end)

local searchBar = Instance.new("TextBox")
searchBar.Size = UDim2.new(1, -32, 0, 36)
searchBar.Position = UDim2.new(0, 16, 0, 58)
searchBar.BackgroundColor3 = Color3.fromRGB(28, 18, 10)
searchBar.BackgroundTransparency = 0.5
searchBar.BorderSizePixel = 0
searchBar.PlaceholderText = "Search players by username or display name..."
searchBar.PlaceholderColor3 = Color3.fromRGB(160, 140, 120)
searchBar.Text = ""
searchBar.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBar.TextSize = 11
searchBar.Font = Enum.Font.Gotham
searchBar.Parent = mainPanel
corner(searchBar, 8)
stroke(searchBar, Color3.fromRGB(140, 100, 50), 1, 0.5)

local listContainer = Instance.new("ScrollingFrame")
listContainer.Size = UDim2.new(1, -32, 1, -140)
listContainer.Position = UDim2.new(0, 16, 0, 104)
listContainer.BackgroundTransparency = 1
listContainer.BorderSizePixel = 0
listContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
listContainer.ScrollBarThickness = 3
listContainer.ScrollBarImageColor3 = Color3.fromRGB(200, 150, 70)
listContainer.Parent = mainPanel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = listContainer

local footer = Instance.new("Frame")
footer.Size = UDim2.new(1, 0, 0, 30)
footer.Position = UDim2.new(0, 0, 1, -30)
footer.BackgroundColor3 = Color3.fromRGB(20, 14, 8)
footer.BackgroundTransparency = 0.4
footer.BorderSizePixel = 0
footer.Parent = mainPanel

local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1, -120, 1, 0)
statusLbl.Position = UDim2.new(0, 16, 0, 0)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "Status: Idle"
statusLbl.TextColor3 = Color3.fromRGB(180, 160, 140)
statusLbl.TextSize = 11
statusLbl.Font = Enum.Font.Gotham
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.Parent = footer

local stopAllBtn = Instance.new("TextButton")
stopAllBtn.Size = UDim2.new(0, 90, 0, 20)
stopAllBtn.Position = UDim2.new(1, -106, 0.5, -10)
stopAllBtn.BackgroundColor3 = Color3.fromRGB(110, 25, 40)
stopAllBtn.BackgroundTransparency = 0.3
stopAllBtn.Text = "STOP ALL"
stopAllBtn.TextColor3 = Color3.fromRGB(255, 140, 160)
stopAllBtn.TextSize = 10
stopAllBtn.Font = Enum.Font.GothamBold
stopAllBtn.Parent = footer
corner(stopAllBtn, 6)
stroke(stopAllBtn, Color3.fromRGB(220, 60, 80), 1, 0.4)

local function stopFling()
    if state.FlingConnection then
        state.FlingConnection:Disconnect()
        state.FlingConnection = nil
    end
    if state.NoClipConnection then
        state.NoClipConnection:Disconnect()
        state.NoClipConnection = nil
    end
    
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if root then
        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        
        if settings.TeleportBack and state.OriginalCFrame then
            root.CFrame = state.OriginalCFrame
        end
    end
    
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    
    state.ActiveFlingTarget = nil
    statusLbl.Text = "Status: Idle"
    statusLbl.TextColor3 = Color3.fromRGB(180, 160, 140)
end

local function executeFling(targetPlayer)
    if state.ActiveFlingTarget then
        stopFling()
        task.wait(0.1)
    end
    
    local targetChar = targetPlayer.Character
    local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
    local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
    
    local localChar = localPlayer.Character
    local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
    local localHum = localChar and localChar:FindFirstChild("Humanoid")
    
    if not localRoot or not targetRoot then
        showNotification("Target Error", "Fling failed: Characters are not fully spawned.", Color3.fromRGB(255, 100, 100))
        return
    end
    
    state.ActiveFlingTarget = targetPlayer
    state.OriginalCFrame = localRoot.CFrame
    statusLbl.Text = "Status: Flinging " .. targetPlayer.DisplayName
    statusLbl.TextColor3 = Color3.fromRGB(255, 110, 130)
    
    if localHum then
        localHum:ChangeState(Enum.HumanoidStateType.Physics)
    end
    
    local bAV = Instance.new("BodyAngularVelocity")
    bAV.Name = "ChopperRotor"
    bAV.AngularVelocity = Vector3.new(0, settings.FlingPower, 0)
    bAV.MaxTorque = Vector3.new(0, math.huge, 0)
    bAV.Parent = localRoot
    
    local bV = Instance.new("BodyVelocity")
    bV.Name = "ChopperThrust"
    bV.Velocity = Vector3.new(99999, 99999, 99999)
    bV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bV.Parent = localRoot
    
    local function cleanPhysicalForces()
        bAV:Destroy()
        bV:Destroy()
    end
    
    if settings.GhostMode then
        state.NoClipConnection = RunService.Stepped:Connect(function()
            if localChar then
                for _, part in ipairs(localChar:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
    
    local flingStart = tick()
    
    state.FlingConnection = RunService.Heartbeat:Connect(function()
        local tChar = targetPlayer.Character
        local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
        local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
        
        local lChar = localPlayer.Character
        local lRoot = lChar and lChar:FindFirstChild("HumanoidRootPart")
        
        if not targetPlayer or not targetPlayer.Parent or not tRoot or not tRoot.Parent then
            cleanPhysicalForces()
            stopFling()
            showNotification("Fling Ended", "Target left or died.", Color3.fromRGB(255, 150, 100))
            return
        end
        
        if not lRoot or not lRoot.Parent or not lChar or not lChar.Parent then
            cleanPhysicalForces()
            stopFling()
            return
        end
        
        if (tHum and tHum.Health <= 0) or tRoot.Position.Y < -300 or tRoot.Position.Y > 8000 then
            cleanPhysicalForces()
            stopFling()
            showNotification("Success!", targetPlayer.DisplayName .. " was launched!", Color3.fromRGB(100, 255, 100))
            return
        end
        
        if not settings.LoopFling and (tick() - flingStart > settings.FlingDuration) then
            cleanPhysicalForces()
            stopFling()
            showNotification("Fling Completed", "Duration threshold reached.", Color3.fromRGB(150, 100, 255))
            return
        end
        
        lRoot.AssemblyLinearVelocity = Vector3.new(99999, 99999, 99999)
        lRoot.AssemblyAngularVelocity = Vector3.new(0, settings.FlingPower, 0)
        
        local angle = (tick() * 32) % (2 * math.pi)
        local rotOffset = Vector3.new(math.cos(angle) * 1.3, math.sin(tick() * 8) * 0.8, math.sin(angle) * 1.3)
        
        lRoot.CFrame = CFrame.new(tRoot.Position + rotOffset)
    end)
end

stopAllBtn.MouseButton1Click:Connect(stopFling)

local function rebuildPlayerList()
    for _, item in ipairs(listContainer:GetChildren()) do
        if item:IsA("Frame") then
            item:Destroy()
        end
    end
    
    local query = searchBar.Text:lower()
    local index = 0
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer then
            local displayName = p.DisplayName
            local userName = p.Name
            
            if query == "" or displayName:lower():find(query) or userName:lower():find(query) then
                index = index + 1
                
                local row = Instance.new("Frame")
                row.Name = "PlayerRow_" .. userName
                row.Size = UDim2.new(1, -6, 0, 48)
                row.BackgroundColor3 = Color3.fromRGB(32, 22, 12)
                row.BackgroundTransparency = 0.45
                row.BorderSizePixel = 0
                row.Parent = listContainer
                corner(row, 8)
                stroke(row, Color3.fromRGB(110, 80, 40), 1, 0.5)
                
                local img = Instance.new("ImageLabel")
                img.Size = UDim2.new(0, 36, 0, 36)
                img.Position = UDim2.new(0, 6, 0.5, -18)
                img.BackgroundColor3 = Color3.fromRGB(48, 30, 15)
                img.BackgroundTransparency = 0.2
                img.Image = "rbxthumb://type=AvatarHeadShot&id=" .. p.UserId .. "&w=150&h=150"
                img.Parent = row
                corner(img, 18)
                stroke(img, Color3.fromRGB(180, 140, 60), 1, 0.5)
                
                local nameContainer = Instance.new("Frame")
                nameContainer.Size = UDim2.new(1, -120, 1, 0)
                nameContainer.Position = UDim2.new(0, 48, 0, 0)
                nameContainer.BackgroundTransparency = 1
                nameContainer.Parent = row
                
                local dLabel = Instance.new("TextLabel")
                dLabel.Size = UDim2.new(1, 0, 0.5, 0)
                dLabel.Position = UDim2.new(0, 0, 0.1, 0)
                dLabel.BackgroundTransparency = 1
                dLabel.Text = displayName
                dLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                dLabel.TextSize = 11
                dLabel.Font = Enum.Font.GothamBold
                dLabel.TextXAlignment = Enum.TextXAlignment.Left
                dLabel.Parent = nameContainer
                
                local uLabel = Instance.new("TextLabel")
                uLabel.Size = UDim2.new(1, 0, 0.5, 0)
                uLabel.Position = UDim2.new(0, 0, 0.45, 0)
                uLabel.BackgroundTransparency = 1
                uLabel.Text = "@" .. userName
                uLabel.TextColor3 = Color3.fromRGB(180, 160, 140)
                uLabel.TextSize = 9
                uLabel.Font = Enum.Font.Gotham
                uLabel.TextXAlignment = Enum.TextXAlignment.Left
                uLabel.Parent = nameContainer
                
                local flingBtn = Instance.new("TextButton")
                flingBtn.Size = UDim2.new(0, 65, 0, 26)
                flingBtn.Position = UDim2.new(1, -73, 0.5, -13)
                flingBtn.BackgroundColor3 = Color3.fromRGB(50, 38, 18)
                flingBtn.BackgroundTransparency = 0.3
                flingBtn.Text = "FLING"
                flingBtn.TextColor3 = Color3.fromRGB(255, 225, 160)
                flingBtn.TextSize = 10
                flingBtn.Font = Enum.Font.GothamBold
                flingBtn.Parent = row
                corner(flingBtn, 6)
                stroke(flingBtn, Color3.fromRGB(180, 135, 50), 1, 0.4)
                
                if state.ActiveFlingTarget == p then
                    flingBtn.Text = "STOP"
                    flingBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 35)
                    flingBtn.TextColor3 = Color3.fromRGB(255, 130, 150)
                    stroke(flingBtn, Color3.fromRGB(220, 60, 90), 1, 0.3)
                    bindHoverEffect(flingBtn, Color3.fromRGB(80, 20, 35), Color3.fromRGB(110, 25, 45), Color3.fromRGB(255, 130, 150), Color3.fromRGB(255, 180, 200), Color3.fromRGB(220, 60, 90), Color3.fromRGB(255, 90, 120))
                else
                    bindHoverEffect(flingBtn, Color3.fromRGB(50, 38, 18), Color3.fromRGB(70, 52, 25), Color3.fromRGB(255, 225, 160), Color3.fromRGB(255, 240, 200), Color3.fromRGB(180, 135, 50), Color3.fromRGB(210, 165, 70))
                end
                
                flingBtn.MouseButton1Click:Connect(function()
                    if state.ActiveFlingTarget == p then
                        stopFling()
                        rebuildPlayerList()
                    else
                        executeFling(p)
                        rebuildPlayerList()
                    end
                end)
            end
        end
    end
    
    listContainer.CanvasSize = UDim2.new(0, 0, 0, index * 56)
end

searchBar.Changed:Connect(function(prop)
    if prop == "Text" then
        rebuildPlayerList()
    end
end)

Players.PlayerAdded:Connect(rebuildPlayerList)
Players.PlayerRemoving:Connect(function(p)
    if state.ActiveFlingTarget == p then
        stopFling()
    end
    rebuildPlayerList()
end)

rebuildPlayerList()

showNotification("ChopperHub", "Initializing Key System...", Color3.fromRGB(200, 150, 70), 2.5)
