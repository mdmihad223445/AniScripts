-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ========== 1. CREATE GUI ==========
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ProScriptGui"
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false

-- Main window
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, 220)
mainFrame.Position = UDim2.new(0.5, -140, 0.5, -110)
mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
title.Text = "PRO SCRIPT"
title.TextColor3 = Color3.fromRGB(0, 255, 150)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = mainFrame
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

-- Minimize button
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 30, 0, 30)
minBtn.Position = UDim2.new(1, -65, 0, 3)
minBtn.Text = "-"
minBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Font = Enum.Font.GothamBold
minBtn.Parent = mainFrame
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 4)

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -33, 0, 3)
closeBtn.Text = "×"
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = mainFrame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)

-- Sidebar
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 70, 1, -35)
sidebar.Position = UDim2.new(0, 0, 0, 35)
sidebar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
sidebar.BorderSizePixel = 0
sidebar.Parent = mainFrame

-- Main page
local mainPage = Instance.new("Frame")
mainPage.Size = UDim2.new(1, -70, 1, -35)
mainPage.Position = UDim2.new(0, 70, 0, 35)
mainPage.BackgroundTransparency = 1
mainPage.Visible = true
mainPage.Parent = mainFrame

-- ESP page
local espPage = Instance.new("Frame")
espPage.Size = UDim2.new(1, -70, 1, -35)
espPage.Position = UDim2.new(0, 70, 0, 35)
espPage.BackgroundTransparency = 1
espPage.Visible = false
espPage.Parent = mainFrame

-- Sidebar buttons
local mainBtn = Instance.new("TextButton")
mainBtn.Size = UDim2.new(1, -6, 0, 35)
mainBtn.Position = UDim2.new(0, 3, 0, 5)
mainBtn.Text = "Main"
mainBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
mainBtn.Font = Enum.Font.Gotham
mainBtn.Parent = sidebar
Instance.new("UICorner", mainBtn).CornerRadius = UDim.new(0, 4)

local espBtn = Instance.new("TextButton")
espBtn.Size = UDim2.new(1, -6, 0, 35)
espBtn.Position = UDim2.new(0, 3, 0, 45)
espBtn.Text = "ESP"
espBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
espBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
espBtn.Font = Enum.Font.Gotham
espBtn.Parent = sidebar
Instance.new("UICorner", espBtn).CornerRadius = UDim.new(0, 4)

mainBtn.MouseButton1Click:Connect(function()
    mainPage.Visible = true
    espPage.Visible = false
end)

espBtn.MouseButton1Click:Connect(function()
    mainPage.Visible = false
    espPage.Visible = true
end)

-- ========== 2. MINIMIZE / CLOSE ==========
local minimized = false
local reopenBtn

minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        mainFrame.Visible = false
        if not reopenBtn then
            reopenBtn = Instance.new("TextButton")
            reopenBtn.Size = UDim2.new(0, 100, 0, 35)
            reopenBtn.Position = UDim2.new(0.5, -50, 0, 10)
            reopenBtn.Text = "PRO SCRIPT"
            reopenBtn.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
            reopenBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
            reopenBtn.Font = Enum.Font.GothamBold
            reopenBtn.Parent = screenGui
            Instance.new("UICorner", reopenBtn).CornerRadius = UDim.new(0, 6)
            reopenBtn.MouseButton1Click:Connect(function()
                mainFrame.Visible = true
                reopenBtn:Destroy()
                reopenBtn = nil
                minimized = false
            end)
        end
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- ========== 3. ESP SYSTEM (AUTO-SCANNER) ==========
local espEnabled = false
local espObjects = {}

-- Keywords the scanner looks for
local RAFT_KEYWORDS  = {"raft", "boat", "plot", "base", "platform"}
local CHEST_KEYWORDS = {"chest", "loot", "stash", "crate", "treasure", "box"}

local function nameMatches(name, keywords)
    local lower = string.lower(name)
    for _, kw in ipairs(keywords) do
        if string.find(lower, kw, 1, true) then
            return true
        end
    end
    return false
end

local function createESP(target, color)
    if not target or not target.Parent then return end
    local highlight = Instance.new("Highlight")
    highlight.Adornee = target
    highlight.FillColor = color
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = target
    return highlight
end

local function clearESP()
    for _, highlight in pairs(espObjects) do
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
    end
    espObjects = {}
end

local function refreshESP()
    if not espEnabled then return end
    clearESP()

    -- PLAYER ESP
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local h = createESP(player.Character, Color3.fromRGB(255, 50, 50))
            if h then espObjects[player.Character] = h end
        end
    end

    -- AUTO-SCAN WORKSPACE
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            -- Skip players (already handled)
            if not Players:GetPlayerFromCharacter(obj) then
                if nameMatches(obj.Name, CHEST_KEYWORDS) then
                    local h = createESP(obj, Color3.fromRGB(255, 215, 0)) -- gold
                    if h then espObjects[obj] = h end
                elseif nameMatches(obj.Name, RAFT_KEYWORDS) then
                    local h = createESP(obj, Color3.fromRGB(50, 150, 255)) -- blue
                    if h then espObjects[obj] = h end
                end
            end
        end
    end
end

-- ESP toggle
local espToggle = Instance.new("TextButton")
espToggle.Size = UDim2.new(1, -20, 0, 40)
espToggle.Position = UDim2.new(0, 10, 0, 10)
espToggle.Text = "ESP: OFF"
espToggle.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
espToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
espToggle.Font = Enum.Font.GothamBold
espToggle.Parent = espPage
Instance.new("UICorner", espToggle).CornerRadius = UDim.new(0, 6)

-- Status label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 0, 55)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Scanner: idle"
statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = espPage

-- Scan button (prints findings to console)
local scanBtn = Instance.new("TextButton")
scanBtn.Size = UDim2.new(1, -20, 0, 30)
scanBtn.Position = UDim2.new(0, 10, 0, 80)
scanBtn.Text = "Scan Workspace (Console)"
scanBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
scanBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
scanBtn.Font = Enum.Font.Gotham
scanBtn.Parent = espPage
Instance.new("UICorner", scanBtn).CornerRadius = UDim.new(0, 6)

scanBtn.MouseButton1Click:Connect(function()
    print("===== PRO SCRIPT SCAN =====")
    local count = 0
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            if nameMatches(obj.Name, CHEST_KEYWORDS) or nameMatches(obj.Name, RAFT_KEYWORDS) then
                print(obj.ClassName, "->", obj.Name, "| Parent:", obj.Parent and obj.Parent.Name)
                count = count + 1
            end
        end
    end
    print("Found:", count, "matches")
    print("===========================")
    statusLabel.Text = "Scanner: found " .. count .. " matches (check console)"
end)

espToggle.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    if espEnabled then
        espToggle.Text = "ESP: ON"
        espToggle.BackgroundColor3 = Color3.fromRGB(0, 120, 60)
        refreshESP()
    else
        espToggle.Text = "ESP: OFF"
        espToggle.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        clearESP()
        statusLabel.Text = "Scanner: idle"
    end
end)

-- Auto-refresh loop
task.spawn(function()
    while screenGui.Parent do
        task.wait(1.5)
        if espEnabled then
            refreshESP()
        end
    end
end)

print("[PRO SCRIPT] Loaded. Scanner active.")
