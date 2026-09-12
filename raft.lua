-- =====================================================================
--  PRO SCRIPT v2 — Premium UI + Auto Steal
--  Features: Player ESP | Raft ESP | Chest ESP | Auto Steal All |
--            Auto Steal Richest | Auto Harpoon Loot
-- =====================================================================

-- ===== SERVICES =====
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local TweenService= game:GetService("TweenService")
local UserInput   = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

-- =====================================================================
--  1.  GUI  (Premium / Glassy / Bigger)
-- =====================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ProScriptGuiV2"
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true

-- Gradient background helper
local function addGradient(parent, c1, c2, rotation)
    local g = Instance.new("UIGradient", parent)
    g.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, c1),
        ColorSequenceKeypoint.new(1, c2),
    }
    g.Rotation = rotation or 90
    return g
end

-- ===== MAIN WINDOW =====
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 480, 0, 400)          -- bigger
mainFrame.Position = UDim2.new(0.5, -240, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
mainFrame.Active = true
mainFrame.Draggable = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 14)
local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = Color3.fromRGB(0, 255, 150)
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.4
addGradient(mainFrame, Color3.fromRGB(22, 22, 28), Color3.fromRGB(10, 10, 14), 90)

-- ===== TITLE BAR =====
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 46)
titleBar.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 14)
addGradient(titleBar, Color3.fromRGB(30, 30, 38), Color3.fromRGB(14, 14, 18), 90)

-- Title with icon dot
local titleDot = Instance.new("Frame")
titleDot.Size = UDim2.new(0, 10, 0, 10)
titleDot.Position = UDim2.new(0, 18, 0.5, -5)
titleDot.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
titleDot.BorderSizePixel = 0
titleDot.Parent = titleBar
Instance.new("UICorner", titleDot).CornerRadius = UDim.new(1, 0)
local dotPulse = Instance.new("UIStroke", titleDot)
dotPulse.Color = Color3.fromRGB(0, 255, 150)
dotPulse.Thickness = 2
dotPulse.Transparency = 0.5
task.spawn(function()
    while titleDot.Parent do
        TweenService:Create(dotPulse, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0}):Play()
        task.wait(1.3)
    end
end)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -140, 1, 0)
title.Position = UDim2.new(0, 40, 0, 0)
title.BackgroundTransparency = 1
title.Text = "PRO SCRIPT  •  v2"
title.TextColor3 = Color3.fromRGB(0, 255, 150)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- Minimize
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 32, 0, 32)
minBtn.Position = UDim2.new(1, -78, 0, 7)
minBtn.Text = "—"
minBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 15
minBtn.AutoButtonColor = true
minBtn.Parent = titleBar
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 8)

-- Close
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -42, 0, 7)
closeBtn.Text = "×"
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
addGradient(closeBtn, Color3.fromRGB(230, 60, 60), Color3.fromRGB(160, 30, 30), 90)

-- ===== SIDEBAR =====
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 110, 1, -46)
sidebar.Position = UDim2.new(0, 0, 0, 46)
sidebar.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
sidebar.BorderSizePixel = 0
sidebar.Parent = mainFrame

-- ===== CONTENT AREA =====
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -110, 1, -46)
content.Position = UDim2.new(0, 110, 0, 46)
content.BackgroundTransparency = 1
content.Parent = mainFrame

-- =====================================================================
--  2.  PAGE BUILDERS
-- =====================================================================
local function newPage(name)
    local p = Instance.new("Frame")
    p.Name = name
    p.Size = UDim2.new(1, 0, 1, 0)
    p.BackgroundTransparency = 1
    p.Visible = false
    p.Parent = content
    return p
end

-- ----- MAIN PAGE -----
local mainPage = newPage("MainPage")
mainPage.Visible = true

local mainWelcome = Instance.new("TextLabel")
mainWelcome.Size = UDim2.new(1, -30, 0, 30)
mainWelcome.Position = UDim2.new(0, 18, 0, 12)
mainWelcome.BackgroundTransparency = 1
mainWelcome.Text = "Welcome to PRO SCRIPT v2"
mainWelcome.TextColor3 = Color3.fromRGB(255, 255, 255)
mainWelcome.Font = Enum.Font.GothamBold
mainWelcome.TextSize = 16
mainWelcome.TextXAlignment = Enum.TextXAlignment.Left
mainWelcome.Parent = mainPage

local mainInfo = Instance.new("TextLabel")
mainInfo.Size = UDim2.new(1, -36, 0, 200)
mainInfo.Position = UDim2.new(0, 18, 0, 55)
mainInfo.BackgroundTransparency = 1
mainInfo.Text = "A premium client-side utility.\n\n• ESP tab — highlight players, rafts, chests\n• AUTO tab — auto steal, richest chest, harpoon loot\n\nAll features are client-side.\nSome games may block teleport-based stealing."
mainInfo.TextColor3 = Color3.fromRGB(170, 170, 180)
mainInfo.Font = Enum.Font.Gotham
mainInfo.TextSize = 13
mainInfo.TextXAlignment = Enum.TextXAlignment.Left
mainInfo.TextYAlignment = Enum.TextYAlignment.Top
mainInfo.TextWrapped = true
mainInfo.Parent = mainPage

-- ----- ESP PAGE -----
local espPage = newPage("ESPPAge")

local espHeader = Instance.new("TextLabel")
espHeader.Size = UDim2.new(1, -30, 0, 25)
espHeader.Position = UDim2.new(0, 18, 0, 10)
espHeader.BackgroundTransparency = 1
espHeader.Text = "ESP CONTROLS"
espHeader.TextColor3 = Color3.fromRGB(0, 255, 150)
espHeader.Font = Enum.Font.GothamBold
espHeader.TextSize = 13
espHeader.TextXAlignment = Enum.TextXAlignment.Left
espHeader.Parent = espPage

-- ----- AUTO PAGE -----
local autoPage = newPage("AutoPage")

local autoHeader = Instance.new("TextLabel")
autoHeader.Size = UDim2.new(1, -30, 0, 25)
autoHeader.Position = UDim2.new(0, 18, 0, 10)
autoHeader.BackgroundTransparency = 1
autoHeader.Text = "AUTO STEAL CONTROLS"
autoHeader.TextColor3 = Color3.fromRGB(0, 255, 150)
autoHeader.Font = Enum.Font.GothamBold
autoHeader.TextSize = 13
autoHeader.TextXAlignment = Enum.TextXAlignment.Left
autoHeader.Parent = autoPage

-- =====================================================================
--  3.  TOGGLE WIDGET
-- =====================================================================
local function makeToggle(parent, yPos, label, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -30, 0, 44)
    btn.Position = UDim2.new(0, 18, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Text = label .. " : OFF"
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(60, 60, 72)
    stroke.Thickness = 1

    local pad = Instance.new("UIPadding", btn)
    pad.PaddingLeft = UDim.new(0, 14)

    -- status dot
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 10, 0, 10)
    dot.Position = UDim2.new(1, -24, 0.5, -5)
    dot.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
    dot.BorderSizePixel = 0
    dot.Parent = btn
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    return btn, dot, stroke, color
end

-- ESP toggles
local playerBtn, playerDot, playerStroke, playerColor = makeToggle(espPage, 42, "Player ESP", Color3.fromRGB(255, 60, 60))
local raftBtn,   raftDot,   raftStroke,   raftColor   = makeToggle(espPage, 94, "Raft ESP",   Color3.fromRGB(60, 150, 255))
local chestBtn,  chestDot,  chestStroke,  chestColor  = makeToggle(espPage, 146, "Chest ESP",  Color3.fromRGB(255, 215, 0))

-- AUTO toggles
local stealAllBtn, stealAllDot, stealAllStroke, stealAllColor = makeToggle(autoPage, 42,  "Auto Steal All Chests", Color3.fromRGB(0, 255, 150))
local richestBtn,  richestDot,  richestStroke,  richestColor  = makeToggle(autoPage, 94,  "Auto Steal Richest",    Color3.fromRGB(255, 215, 0))
local harpoonBtn,  harpoonDot,  harpoonStroke,  harpoonColor  = makeToggle(autoPage, 146, "Auto Harpoon Loot",     Color3.fromRGB(255, 120, 40))

-- ===== Status Label (shared at bottom of content) =====
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -30, 0, 40)
statusLabel.Position = UDim2.new(0, 18, 1, -60)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Ready."
statusLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.TextWrapped = true
statusLabel.Parent = espPage   -- also duplicated below

local statusLabel2 = statusLabel:Clone()
statusLabel2.Parent = autoPage

local function setStatus(txt)
    statusLabel.Text = txt
    statusLabel2.Text = txt
end

-- Scan button (ESP page)
local scanBtn = Instance.new("TextButton")
scanBtn.Size = UDim2.new(1, -30, 0, 34)
scanBtn.Position = UDim2.new(0, 18, 0, 200)
scanBtn.Text = "Scan Workspace"
scanBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
scanBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
scanBtn.Font = Enum.Font.GothamBold
scanBtn.TextSize = 13
scanBtn.Parent = espPage
Instance.new("UICorner", scanBtn).CornerRadius = UDim.new(0, 8)

-- Stop All button (AUTO page)
local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(1, -30, 0, 34)
stopBtn.Position = UDim2.new(0, 18, 0, 200)
stopBtn.Text = "STOP ALL AUTO"
stopBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
stopBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 13
stopBtn.Parent = autoPage
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 8)

-- =====================================================================
--  4.  SIDEBAR BUTTONS
-- =====================================================================
local function makeSidebarBtn(text, yPos, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -16, 0, 40)
    b.Position = UDim2.new(0, 8, 0, yPos)
    b.Text = text
    b.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    b.TextColor3 = Color3.fromRGB(200, 200, 210)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.Parent = sidebar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    local s = Instance.new("UIStroke", b)
    s.Color = color or Color3.fromRGB(60, 60, 72)
    s.Thickness = 1
    s.Transparency = 0.4
    return b, s
end

local mainBtn, mainBtnStroke = makeSidebarBtn("Main", 12, Color3.fromRGB(0, 255, 150))
local espBtn,  espBtnStroke  = makeSidebarBtn("ESP",  60, Color3.fromRGB(60, 150, 255))
local autoBtn, autoBtnStroke = makeSidebarBtn("AUTO", 108, Color3.fromRGB(255, 215, 0))

-- page switch
local function setActive(active, activeStroke, inactive1, inactive1Stroke, inactive2, inactive2Stroke)
    active.BackgroundColor3 = Color3.fromRGB(0, 120, 70)
    active.TextColor3 = Color3.fromRGB(255, 255, 255)
    activeStroke.Color = Color3.fromRGB(0, 255, 150)
    activeStroke.Transparency = 0

    for _, pair in ipairs({{inactive1, inactive1Stroke}, {inactive2, inactive2Stroke}}) do
        local b, s = pair[1], pair[2]
        b.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        b.TextColor3 = Color3.fromRGB(200, 200, 210)
        s.Color = Color3.fromRGB(60, 60, 72)
        s.Transparency = 0.4
    end
end

local function showPage(page)
    mainPage.Visible = false
    espPage.Visible = false
    autoPage.Visible = false
    page.Visible = true
end

mainBtn.MouseButton1Click:Connect(function()
    showPage(mainPage)
    setActive(mainBtn, mainBtnStroke, espBtn, espBtnStroke, autoBtn, autoBtnStroke)
end)
espBtn.MouseButton1Click:Connect(function()
    showPage(espPage)
    setActive(espBtn, espBtnStroke, mainBtn, mainBtnStroke, autoBtn, autoBtnStroke)
end)
autoBtn.MouseButton1Click:Connect(function()
    showPage(autoPage)
    setActive(autoBtn, autoBtnStroke, mainBtn, mainBtnStroke, espBtn, espBtnStroke)
end)

-- initialize active
setActive(mainBtn, mainBtnStroke, espBtn, espBtnStroke, autoBtn, autoBtnStroke)

-- =====================================================================
--  5.  MINIMIZE / CLOSE
-- =====================================================================
local minimized = false
local reopenBtn

minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        mainFrame.Visible = false
        if not reopenBtn then
            reopenBtn = Instance.new("TextButton")
            reopenBtn.Size = UDim2.new(0, 160, 0, 40)
            reopenBtn.Position = UDim2.new(0.5, -80, 0, 12)
            reopenBtn.Text = "PRO SCRIPT"
            reopenBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
            reopenBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
            reopenBtn.Font = Enum.Font.GothamBold
            reopenBtn.TextSize = 14
            reopenBtn.Parent = screenGui
            Instance.new("UICorner", reopenBtn).CornerRadius = UDim.new(0, 10)
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

-- =====================================================================
--  6.  ESP SYSTEM
-- =====================================================================
local espState = { players = false, rafts = false, chests = false }
local espObjects = { players = {}, rafts = {}, chests = {} }

local RAFT_KEYWORDS  = {"raft", "boat", "plot", "platform"}
local CHEST_KEYWORDS = {"chest", "loot", "stash", "crate", "treasure"}

local function nameMatches(name, keywords)
    local lower = string.lower(name)
    for _, kw in ipairs(keywords) do
        if string.find(lower, kw, 1, true) then return true end
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

local function clearGroup(g)
    for _, h in pairs(espObjects[g]) do
        if h and h.Parent then h:Destroy() end
    end
    espObjects[g] = {}
end

local function refreshPlayers()
    clearGroup("players")
    if not espState.players then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local h = createHighlight(p.Character, Color3.fromRGB(255, 60, 60))
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
                local h = createHighlight(obj, Color3.fromRGB(60, 150, 255))
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

local function updateToggleVisual(btn, dot, stroke, color, on)
    if on then
        btn.BackgroundColor3 = Color3.fromRGB(color.R * 0.28, color.G * 0.28, color.B * 0.28)
        btn.TextColor3 = color
        dot.BackgroundColor3 = color
        stroke.Color = color
        stroke.Transparency = 0.2
    else
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        btn.TextColor3 = Color3.fromRGB(220, 220, 220)
        dot.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
        stroke.Color = Color3.fromRGB(60, 60, 72)
        stroke.Transparency = 0
    end
end

playerBtn.MouseButton1Click:Connect(function()
    espState.players = not espState.players
    playerBtn.Text = "Player ESP : " .. (espState.players and "ON" or "OFF")
    updateToggleVisual(playerBtn, playerDot, playerStroke, playerColor, espState.players)
    refreshPlayers()
end)

raftBtn.MouseButton1Click:Connect(function()
    espState.rafts = not espState.rafts
    raftBtn.Text = "Raft ESP : " .. (espState.rafts and "ON" or "OFF")
    updateToggleVisual(raftBtn, raftDot, raftStroke, raftColor, espState.rafts)
    refreshRafts()
end)

chestBtn.MouseButton1Click:Connect(function()
    espState.chests = not espState.chests
    chestBtn.Text = "Chest ESP : " .. (espState.chests and "ON" or "OFF")
    updateToggleVisual(chestBtn, chestDot, chestStroke, chestColor, espState.chests)
    refreshChests()
end)

scanBtn.MouseButton1Click:Connect(function()
    print("===== PRO SCRIPT SCAN =====")
    local rc, cc = 0, 0
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            if nameMatches(obj.Name, RAFT_KEYWORDS) then
                print("[RAFT]", obj.ClassName, "->", obj.Name); rc += 1
            elseif nameMatches(obj.Name, CHEST_KEYWORDS) then
                print("[CHEST]", obj.ClassName, "->", obj.Name); cc += 1
            end
        end
    end
    print("Rafts:", rc, "| Chests:", cc)
    setStatus(("Scan complete. Rafts: %d | Chests: %d"):format(rc, cc))
end)

-- =====================================================================
--  7.  AUTO STEAL SYSTEM
-- =====================================================================
local autoState = {
    stealAll = false,
    richest  = false,
    harpoon  = false,
}

local function getCharacter()
    local c = LocalPlayer.Character
    if not c then return nil, nil, nil end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChildOfClass("Humanoid")
    return c, hrp, hum
end

-- Find every chest-like object in workspace (excluding own character)
local function getChests()
    local list = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            if not Players:GetPlayerFromCharacter(obj) then
                if nameMatches(obj.Name, CHEST_KEYWORDS) then
                    -- get primary part or part
                    local root = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))
                                 or obj
                    if root and root:IsA("BasePart") then
                        table.insert(list, {obj = obj, part = root})
                    end
                end
            end
        end
    end
    return list
end

-- Distance between player and a part
local function distTo(part)
    local _, hrp = getCharacter()
    if not hrp or not part then return math.huge end
    return (hrp.Position - part.Position).Magnitude
end

-- Safe teleport (CFrame set, respects collision off temporarily)
local function teleportTo(part)
    local _, hrp = getCharacter()
    if not hrp or not part then return false end
    hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
    return true
end

-- Return to own raft / spawn
local function returnToOwnRaft()
    local char, hrp = getCharacter()
    if not hrp then return end

    -- Find own raft by keyword or fall back to spawn
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and nameMatches(obj.Name, RAFT_KEYWORDS) then
            local owner = obj:GetAttribute("Owner") or obj:GetAttribute("Player") or obj:GetAttribute("UserId")
            if owner then
                local ownerId = typeof(owner) == "number" and owner or (typeof(owner) == "Instance" and owner.UserId) or nil
                if ownerId == LocalPlayer.UserId then
                    local root = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                    if root then
                        hrp.CFrame = CFrame.new(root.Position + Vector3.new(0, 5, 0))
                        return
                    end
                end
            end
        end
    end

    -- Fallback: spawn location
    local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
    if spawn then
        hrp.CFrame = CFrame.new(spawn.Position + Vector3.new(0, 5, 0))
    end
end

-- Try to actually "steal" a chest by firing tools / touching it
local function trySteal(chestEntry)
    local char, hrp = getCharacter()
    if not char or not hrp then return end

    local part = chestEntry.part

    -- 1) Teleport near
    teleportTo(part)

    -- 2) Touch it (fire Touched via moving inside)
    hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 1, 0))

    -- 3) Activate every tool in backpack (harpoon, hands, etc.)
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            pcall(function() tool:Activate() end)
        end
    end

    -- 4) Click any ProximityPrompt on it
    for _, d in ipairs(chestEntry.obj:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            pcall(function()
                d:InputHoldBegin()
                task.wait(d.HoldDuration or 0.1)
                d:InputHoldEnd()
            end)
        end
    end
end

-- ===== AUTO STEAL ALL =====
task.spawn(function()
    while screenGui.Parent do
        task.wait(0.5)
        if autoState.stealAll then
            local chests = getChests()
            if #chests == 0 then
                setStatus("Auto Steal All: no chests found.")
            else
                -- sort by distance so we grab nearest first
                table.sort(chests, function(a, b) return distTo(a.part) < distTo(b.part) end)
                for i, c in ipairs(chests) do
                    if not autoState.stealAll then break end
                    setStatus(("Stealing chest %d/%d (%s)"):format(i, #chests, c.obj.Name))
                    trySteal(c)
                    task.wait(0.35)
                end
                setStatus("Auto Steal All: returned to raft.")
                returnToOwnRaft()
            end
        end
    end
end)

-- ===== AUTO STEAL RICHEST (nearest + biggest) =====
task.spawn(function()
    while screenGui.Parent do
        task.wait(0.6)
        if autoState.richest then
            local chests = getChests()
            if #chests == 0 then
                setStatus("Auto Richest: no chests found.")
            else
                -- "richest" = nearest (proxy for best since we can't read value)
                local best, bestDist = nil, math.huge
                for _, c in ipairs(chests) do
                    local d = distTo(c.part)
                    if d < bestDist then
                        best, bestDist = c, d
                    end
                end
                if best then
                    setStatus(("Richest → %s (%.0f studs)"):format(best.obj.Name, bestDist))
                    trySteal(best)
                    task.wait(0.3)
                    returnToOwnRaft()
                end
            end
        end
    end
end)

-- ===== AUTO HARPOON LOOT =====
-- Fires equipped tool toward nearest loot within range.
local HARPOON_RANGE = 120

local function findHarpoon()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, t in ipairs(char:GetChildren()) do
        if t:IsA("Tool") then
            local n = string.lower(t.Name)
            if string.find(n, "harpoon", 1, true) or string.find(n, "hook", 1, true) or string.find(n, "grapple", 1, true) then
                return t
            end
        end
    end
    -- fallback: first tool
    return char:FindFirstChildOfClass("Tool")
end

task.spawn(function()
    while screenGui.Parent do
        task.wait(0.35)
        if autoState.harpoon then
            local char, hrp = getCharacter()
            if not char or not hrp then
                setStatus("Harpoon: no character.")
            else
                -- find nearest lootable target
                local chests = getChests()
                local best, bestDist = nil, HARPOON_RANGE
                for _, c in ipairs(chests) do
                    local d = distTo(c.part)
                    if d < bestDist then best, bestDist = c, d end
                end

                if best then
                    -- Face target
                    hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(best.part.Position.X, hrp.Position.Y, best.part.Position.Z))
                    -- Activate tool
                    local tool = findHarpoon()
                    if tool then
                        pcall(function() tool:Activate() end)
                        setStatus(("Harpoon fired → %s (%.0f)"):format(best.obj.Name, bestDist))
                    else
                        setStatus("Harpoon: no tool equipped.")
                    end
                else
                    setStatus("Harpoon: no loot in range.")
                end
            end
        end
    end
end)

-- =====================================================================
--  8.  AUTO TOGGLE HOOKUPS
-- =====================================================================
stealAllBtn.MouseButton1Click:Connect(function()
    autoState.stealAll = not autoState.stealAll
    stealAllBtn.Text = "Auto Steal All Chests : " .. (autoState.stealAll and "ON" or "OFF")
    updateToggleVisual(stealAllBtn, stealAllDot, stealAllStroke, stealAllColor, autoState.stealAll)
    setStatus(autoState.stealAll and "Auto Steal All: STARTED" or "Auto Steal All: stopped")
end)

richestBtn.MouseButton1Click:Connect(function()
    autoState.richest = not autoState.richest
    richestBtn.Text = "Auto Steal Richest : " .. (autoState.richest and "ON" or "OFF")
    updateToggleVisual(richestBtn, richestDot, richestStroke, richestColor, autoState.richest)
    setStatus(autoState.richest and "Auto Richest: STARTED" or "Auto Richest: stopped")
end)

harpoonBtn.MouseButton1Click:Connect(function()
    autoState.harpoon = not autoState.harpoon
    harpoonBtn.Text = "Auto Harpoon Loot : " .. (autoState.harpoon and "ON" or "OFF")
    updateToggleVisual(harpoonBtn, harpoonDot, harpoonStroke, harpoonColor, autoState.harpoon)
    setStatus(autoState.harpoon and "Auto Harpoon: STARTED" or "Auto Harpoon: stopped")
end)

stopBtn.MouseButton1Click:Connect(function()
    autoState.stealAll = false
    autoState.richest  = false
    autoState.harpoon  = false

    stealAllBtn.Text = "Auto Steal All Chests : OFF"
    richestBtn.Text  = "Auto Steal Richest : OFF"
    harpoonBtn.Text  = "Auto Harpoon Loot : OFF"

    updateToggleVisual(stealAllBtn, stealAllDot, stealAllStroke, stealAllColor, false)
    updateToggleVisual(richestBtn,  richestDot,  richestStroke,  richestColor,  false)
    updateToggleVisual(harpoonBtn,  harpoonDot,  harpoonStroke,  harpoonColor,  false)

    setStatus("All AUTO features stopped.")
end)

-- =====================================================================
--  9.  AUTO REFRESH LOOP (ESP)
-- =====================================================================
task.spawn(function()
    while screenGui.Parent do
        task.wait(1.5)
        if espState.players then refreshPlayers() end
        if espState.rafts   then refreshRafts()   end
        if espState.chests  then refreshChests()  end
    end
end)

-- =====================================================================
--  10.  KEYBOARD SHORTCUT: RIGHT CTRL to toggle GUI
-- =====================================================================
UserInput.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

print("[PRO SCRIPT v2] Loaded. ESP + AUTO STEAL ready.")
setStatus("Loaded. Ready.")
