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
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main window
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 340, 0, 300)
mainFrame.Position = UDim2.new(0.5, -170, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)
local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = Color3.fromRGB(0, 255, 150)
mainStroke.Thickness = 1
mainStroke.Transparency = 0.5

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -100, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Text = "PRO SCRIPT"
title.TextColor3 = Color3.fromRGB(0, 255, 150)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- Minimize button
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 28, 0, 28)
minBtn.Position = UDim2.new(1, -66, 0, 6)
minBtn.Text = "—"
minBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 14
minBtn.Parent = titleBar
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -34, 0, 6)
closeBtn.Text = "×"
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

-- Sidebar
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 80, 1, -40)
sidebar.Position = UDim2.new(0, 0, 0, 40)
sidebar.BackgroundColor3 = Color3.fromRGB(14, 14, 17)
sidebar.BorderSizePixel = 0
sidebar.Parent = mainFrame

-- Content area
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -80, 1, -40)
content.Position = UDim2.new(0, 80, 0, 40)
content.BackgroundTransparency = 1
content.Parent = mainFrame

-- ===== MAIN PAGE =====
local mainPage = Instance.new("Frame")
mainPage.Size = UDim2.new(1, 0, 1, 0)
mainPage.BackgroundTransparency = 1
mainPage.Visible = true
mainPage.Parent = content

local mainWelcome = Instance.new("TextLabel")
mainWelcome.Size = UDim2.new(1, -20, 0, 30)
mainWelcome.Position = UDim2.new(0, 10, 0, 10)
mainWelcome.BackgroundTransparency = 1
mainWelcome.Text = "Welcome to PRO SCRIPT"
mainWelcome.TextColor3 = Color3.fromRGB(255, 255, 255)
mainWelcome.Font = Enum.Font.GothamBold
mainWelcome.TextSize = 14
mainWelcome.TextXAlignment = Enum.TextXAlignment.Left
mainWelcome.Parent = mainPage

local mainInfo = Instance.new("TextLabel")
mainInfo.Size = UDim2.new(1, -20, 0, 100)
mainInfo.Position = UDim2.new(0, 10, 0, 45)
mainInfo.BackgroundTransparency = 1
mainInfo.Text = "Use the ESP tab on the left\nto toggle visual highlights\nfor players, rafts, and chests.\n\nAll features are client-side only."
mainInfo.TextColor3 = Color3.fromRGB(160, 160, 170)
mainInfo.Font = Enum.Font.Gotham
mainInfo.TextSize = 12
mainInfo.TextXAlignment = Enum.TextXAlignment.Left
mainInfo.TextYAlignment = Enum.TextYAlignment.Top
mainInfo.Parent = mainPage

-- ===== ESP PAGE =====
local espPage = Instance.new("Frame")
espPage.Size = UDim2.new(1, 0, 1, 0)
espPage.BackgroundTransparency = 1
espPage.Visible = false
espPage.Parent = content

local espHeader = Instance.new("TextLabel")
espHeader.Size = UDim2.new(1, -20, 0, 25)
espHeader.Position = UDim2.new(0, 10, 0, 8)
espHeader.BackgroundTransparency = 1
espHeader.Text = "ESP CONTROLS"
espHeader.TextColor3 = Color3.fromRGB(0, 255, 150)
espHeader.Font = Enum.Font.GothamBold
espHeader.TextSize = 12
espHeader.TextXAlignment = Enum.TextXAlignment.Left
espHeader.Parent = espPage

-- Helper: create toggle button
local function makeToggle(parent, yPos, label, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 40)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Text = label .. ": OFF"
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(60, 60, 70)
    stroke.Thickness = 1

    -- Status dot indicator
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(1, -20, 0.5, -4)
    dot.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    dot.BorderSizePixel = 0
    dot.Parent = btn
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    -- Padding for text
    local pad = Instance.new("UIPadding", btn)
    pad.PaddingLeft = UDim.new(0, 12)

    return btn, dot, stroke, color
end

-- Toggle buttons
local playerBtn, playerDot, playerStroke, playerColor = makeToggle(espPage, 40, "Player ESP", Color3.fromRGB(255, 50, 50))
local raftBtn, raftDot, raftStroke, raftColor     = makeToggle(espPage, 88, "Raft ESP",   Color3.fromRGB(50, 150, 255))
local chestBtn, chestDot, chestStroke, chestColor = makeToggle(espPage, 136, "Chest ESP", Color3.fromRGB(255, 215, 0))

-- Status label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 40)
statusLabel.Position = UDim2.new(0, 10, 0, 190)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Ready."
statusLabel.TextColor3 = Color3.fromRGB(140, 140, 150)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.TextWrapped = true
statusLabel.Parent = espPage

-- Scan button
local scanBtn = Instance.new("TextButton")
scanBtn.Size = UDim2.new(1, -20, 0, 30)
scanBtn.Position = UDim2.new(0, 10, 0, 155)
scanBtn.Text = "Scan Workspace"
scanBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
scanBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
scanBtn.Font = Enum.Font.GothamBold
scanBtn.TextSize = 12
scanBtn.Parent = espPage
Instance.new("UICorner", scanBtn).CornerRadius = UDim.new(0, 6)

-- ===== SIDEBAR BUTTONS =====
local mainBtn = Instance.new("TextButton")
mainBtn.Size = UDim2.new(1, -12, 0, 36)
mainBtn.Position = UDim2.new(0, 6, 0, 10)
mainBtn.Text = "Main"
mainBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 70)
mainBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
mainBtn.Font = Enum.Font.GothamBold
mainBtn.TextSize = 12
mainBtn.Parent = sidebar
Instance.new("UICorner", mainBtn).CornerRadius = UDim.new(0, 6)

local espBtn = Instance.new("TextButton")
espBtn.Size = UDim2.new(1, -12, 0, 36)
espBtn.Position = UDim2.new(0, 6, 0, 52)
espBtn.Text = "ESP"
espBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
espBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
espBtn.Font = Enum.Font.GothamBold
espBtn.TextSize = 12
espBtn.Parent = sidebar
Instance.new("UICorner", espBtn).CornerRadius = UDim.new(0, 6)

-- Page switching
local function setActive(active, inactive)
    active.BackgroundColor3 = Color3.fromRGB(0, 120, 70)
    active.TextColor3 = Color3.fromRGB(255, 255, 255)
    inactive.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
    inactive.TextColor3 = Color3.fromRGB(200, 200, 200)
end

mainBtn.MouseButton1Click:Connect(function()
    mainPage.Visible = true
    espPage.Visible = false
    setActive(mainBtn, espBtn)
end)

espBtn.MouseButton1Click:Connect(function()
    mainPage.Visible = false
    espPage.Visible = true
    setActive(espBtn, mainBtn)
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
            reopenBtn.Size = UDim2.new(0, 120, 0, 36)
            reopenBtn.Position = UDim2.new(0.5, -60, 0, 10)
            reopenBtn.Text = "PRO SCRIPT"
            reopenBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
            reopenBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
            reopenBtn.Font = Enum.Font.GothamBold
            reopenBtn.TextSize = 13
            reopenBtn.Parent = screenGui
            Instance.new("UICorner", reopenBtn).CornerRadius = UDim.new(0, 8)
            local s = Instance.new("UIStroke", reopenBtn)
            s.Color = Color3.fromRGB(0, 255, 150)
            s.Transparency = 0.4
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

-- ========== 3. ESP SYSTEM (3 SEPARATE TOGGLES) ==========
local espState = {
    players = false,
    rafts   = false,
    chests  = false,
}

local espObjects = {
    players = {},
    rafts   = {},
    chests  = {},
}

local RAFT_KEYWORDS  = {"raft", "boat", "plot", "platform"}
local CHEST_KEYWORDS = {"chest", "loot", "stash", "crate", "treasure"}

local function nameMatches(name, keywords)
    local lower = string.lower(name)
    for _, kw in ipairs(keywords) do
        if string.find(lower, kw, 1, true) then
            return true
        end
    end
    return false
end

local function createHighlight(target, color)
    if not target or not target.Parent then return nil end
    local h = Instance.new("Highlight")
    h.Adornee = target
    h.FillColor = color
    h.FillTransparency = 0.5
    h.OutlineColor = Color3.fromRGB(255, 255, 255)
    h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = target
    return h
end

local function clearGroup(group)
    for _, h in pairs(espObjects[group]) do
        if h and h.Parent then h:Destroy() end
    end
    espObjects[group] = {}
end

local function clearAll()
    clearGroup("players")
    clearGroup("rafts")
    clearGroup("chests")
end

local function refreshPlayers()
    clearGroup("players")
    if not espState.players then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local h = createHighlight(p.Character, Color3.fromRGB(255, 50, 50))
            if h then espObjects.players[p.Character] = h end
        end
    end
end

local function refreshRafts()
    clearGroup("rafts")
    if not espState.rafts then return end
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
            if nameMatches(obj.Name, RAFT_KEYWORDS) then
                local h = createHighlight(obj, Color3.fromRGB(50, 150, 255))
                if h then espObjects.rafts[obj] = h end
            end
        end
    end
end

local function refreshChests()
    clearGroup("chests")
    if not espState.chests then return end
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            if not Players:GetPlayerFromCharacter(obj) then
                if nameMatches(obj.Name, CHEST_KEYWORDS) then
                    local h = createHighlight(obj, Color3.fromRGB(255, 215, 0))
                    if h then espObjects.chests[obj] = h end
                end
            end
        end
    end
end

-- Toggle helper
local function updateToggleVisual(btn, dot, stroke, color, on)
    if on then
        btn.BackgroundColor3 = Color3.fromRGB(color.R * 0.3, color.G * 0.3, color.B * 0.3)
        btn.TextColor3 = color
        dot.BackgroundColor3 = color
        stroke.Color = color
        stroke.Transparency = 0.3
    else
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
        btn.TextColor3 = Color3.fromRGB(220, 220, 220)
        dot.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        stroke.Color = Color3.fromRGB(60, 60, 70)
        stroke.Transparency = 0
    end
end

playerBtn.MouseButton1Click:Connect(function()
    espState.players = not espState.players
    playerBtn.Text = "Player ESP: " .. (espState.players and "ON" or "OFF")
    updateToggleVisual(playerBtn, playerDot, playerStroke, playerColor, espState.players)
    refreshPlayers()
end)

raftBtn.MouseButton1Click:Connect(function()
    espState.rafts = not espState.rafts
    raftBtn.Text = "Raft ESP: " .. (espState.rafts and "ON" or "OFF")
    updateToggleVisual(raftBtn, raftDot, raftStroke, raftColor, espState.rafts)
    refreshRafts()
end)

chestBtn.MouseButton1Click:Connect(function()
    espState.chests = not espState.chests
    chestBtn.Text = "Chest ESP: " .. (espState.chests and "ON" or "OFF")
    updateToggleVisual(chestBtn, chestDot, chestStroke, chestColor, espState.chests)
    refreshChests()
end)

-- Scan button
scanBtn.MouseButton1Click:Connect(function()
    print("===== PRO SCRIPT SCAN =====")
    local rc, cc = 0, 0
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            if nameMatches(obj.Name, RAFT_KEYWORDS) then
                print("[RAFT]", obj.ClassName, "->", obj.Name)
                rc = rc + 1
            elseif nameMatches(obj.Name, CHEST_KEYWORDS) then
                print("[CHEST]", obj.ClassName, "->", obj.Name)
                cc = cc + 1
            end
        end
    end
    print("Rafts found:", rc, "| Chests found:", cc)
    print("===========================")
    statusLabel.Text = "Scan complete.\nRafts: " .. rc .. " | Chests: " .. cc
end)

-- Auto refresh loop
task.spawn(function()
    while screenGui.Parent do
        task.wait(1.5)
        if espState.players then refreshPlayers() end
        if espState.rafts   then refreshRafts()   end
        if espState.chests  then refreshChests()  end
    end
end)

print("[PRO SCRIPT] Loaded. 3 ESP toggles ready.")
