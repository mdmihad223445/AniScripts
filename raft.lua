-- =====================================================================
--  AniScript v7 — Fully Working
--  ESP: Player(green) | Chest(gold) | Raft(blue) | Loot(brown) | Shark(red)
--  Auto Steal Raft Chests + Teleport to Richest + Return to Base
-- =====================================================================

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInput    = game:GetService("UserInputService")
local LocalPlayer  = Players.LocalPlayer

-- =====================================================================
--  1.  GUI  (Premium)
-- =====================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AniScript"
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- main window
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 380, 0, 320)
mainFrame.Position = UDim2.new(0.5, -190, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

local mainGradient = Instance.new("UIGradient", mainFrame)
mainGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 24, 32)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 14, 20)),
}
mainGradient.Rotation = 90

local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = Color3.fromRGB(120, 80, 255)
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.35

-- title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)
local tbFix = Instance.new("Frame")
tbFix.Size = UDim2.new(1, 0, 0, 12)
tbFix.Position = UDim2.new(0, 0, 1, -12)
tbFix.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
tbFix.BorderSizePixel = 0
tbFix.Parent = titleBar

local titleGrad = Instance.new("UIGradient", titleBar)
titleGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 30, 90)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(26, 26, 36)),
}
titleGrad.Rotation = 25

local accentBar = Instance.new("Frame")
accentBar.Size = UDim2.new(0, 4, 0, 20)
accentBar.Position = UDim2.new(0, 14, 0.5, -10)
accentBar.BackgroundColor3 = Color3.fromRGB(150, 100, 255)
accentBar.BorderSizePixel = 0
accentBar.Parent = titleBar
Instance.new("UICorner", accentBar).CornerRadius = UDim.new(1, 0)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -100, 1, 0)
title.Position = UDim2.new(0, 28, 0, 0)
title.BackgroundTransparency = 1
title.Text = "AniScript"
title.TextColor3 = Color3.fromRGB(240, 235, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -100, 0, 12)
subtitle.Position = UDim2.new(0, 30, 1, -14)
subtitle.BackgroundTransparency = 1
subtitle.Text = "v7 • premium"
subtitle.TextColor3 = Color3.fromRGB(150, 130, 200)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 9
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = titleBar

-- minimize
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 26, 0, 26)
minBtn.Position = UDim2.new(1, -60, 0, 7)
minBtn.Text = "—"
minBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
minBtn.TextColor3 = Color3.fromRGB(220, 220, 235)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 14
minBtn.AutoButtonColor = true
minBtn.Parent = titleBar
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 8)

-- close
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -32, 0, 7)
closeBtn.Text = "×"
closeBtn.BackgroundColor3 = Color3.fromRGB(210, 60, 80)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
local closeGrad = Instance.new("UIGradient", closeBtn)
closeGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(230, 70, 90)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 40, 60)),
}
closeGrad.Rotation = 90

-- sidebar
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 96, 1, -40)
sidebar.Position = UDim2.new(0, 0, 0, 40)
sidebar.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
sidebar.BorderSizePixel = 0
sidebar.Parent = mainFrame

-- content
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -96, 1, -40)
content.Position = UDim2.new(0, 96, 0, 40)
content.BackgroundTransparency = 1
content.Parent = mainFrame

-- =====================================================================
--  2.  PAGES
-- =====================================================================
local function newPage()
    local p = Instance.new("Frame")
    p.Size = UDim2.new(1, 0, 1, 0)
    p.BackgroundTransparency = 1
    p.Visible = false
    p.Parent = content
    return p
end

local mainPage = newPage()
mainPage.Visible = true
local espPage = newPage()

-- =====================================================================
--  3.  STATUS
-- =====================================================================
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -24, 0, 60)
statusLabel.Position = UDim2.new(0, 12, 1, -66)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Ready."
statusLabel.TextColor3 = Color3.fromRGB(160, 160, 175)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 10
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.TextWrapped = true
statusLabel.Parent = mainPage

local statusLabel2 = statusLabel:Clone()
statusLabel2.Parent = espPage

local function setStatus(txt)
    statusLabel.Text = txt
    statusLabel2.Text = txt
end

-- =====================================================================
--  4.  TOGGLE WIDGET
-- =====================================================================
local function makeToggle(parent, yPos, label, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -24, 0, 34)
    btn.Position = UDim2.new(0, 12, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    btn.TextColor3 = Color3.fromRGB(220, 220, 230)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Text = label .. "   OFF"
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = true
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(60, 60, 78)
    stroke.Thickness = 1

    local pad = Instance.new("UIPadding", btn)
    pad.PaddingLeft = UDim.new(0, 14)

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(1, -20, 0.5, -4)
    dot.BackgroundColor3 = Color3.fromRGB(70, 70, 85)
    dot.BorderSizePixel = 0
    dot.Parent = btn
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    return btn, dot, stroke, color
end

local function updateToggle(btn, dot, stroke, color, on, label)
    if on then
        btn.BackgroundColor3 = Color3.fromRGB(
            math.floor(color.R * 0.25 + 10),
            math.floor(color.G * 0.25 + 10),
            math.floor(color.B * 0.25 + 10))
        btn.TextColor3 = color
        dot.BackgroundColor3 = color
        stroke.Color = color
        stroke.Transparency = 0.15
    else
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        btn.TextColor3 = Color3.fromRGB(220, 220, 230)
        dot.BackgroundColor3 = Color3.fromRGB(70, 70, 85)
        stroke.Color = Color3.fromRGB(60, 60, 78)
        stroke.Transparency = 0
    end
    btn.Text = label .. "   " .. (on and "ON" or "OFF")
end

-- =====================================================================
--  5.  ESP PAGE
-- =====================================================================
local espHeader = Instance.new("TextLabel")
espHeader.Size = UDim2.new(1, -24, 0, 20)
espHeader.Position = UDim2.new(0, 12, 0, 8)
espHeader.BackgroundTransparency = 1
espHeader.Text = "ESP CONTROLS"
espHeader.TextColor3 = Color3.fromRGB(160, 130, 255)
espHeader.Font = Enum.Font.GothamBold
espHeader.TextSize = 11
espHeader.TextXAlignment = Enum.TextXAlignment.Left
espHeader.Parent = espPage

local pBtn, pDot, pStroke, pColor = makeToggle(espPage, 32,  "Player ESP", Color3.fromRGB(0, 255, 120))
local cBtn, cDot, cStroke, cColor = makeToggle(espPage, 70,  "Chest ESP",  Color3.fromRGB(255, 200, 0))
local rBtn, rDot, rStroke, rColor = makeToggle(espPage, 108, "Raft ESP",   Color3.fromRGB(60, 140, 255))
local lBtn, lDot, lStroke, lColor = makeToggle(espPage, 146, "Loot ESP",   Color3.fromRGB(170, 110, 60))
local sBtn, sDot, sStroke, sColor = makeToggle(espPage, 184, "Shark ESP",  Color3.fromRGB(255, 50, 50))

-- =====================================================================
--  6.  MAIN PAGE
-- =====================================================================
local mainHeader = Instance.new("TextLabel")
mainHeader.Size = UDim2.new(1, -24, 0, 20)
mainHeader.Position = UDim2.new(0, 12, 0, 8)
mainHeader.BackgroundTransparency = 1
mainHeader.Text = "AUTO STEAL"
mainHeader.TextColor3 = Color3.fromRGB(160, 130, 255)
mainHeader.Font = Enum.Font.GothamBold
mainHeader.TextSize = 11
mainHeader.TextXAlignment = Enum.TextXAlignment.Left
mainHeader.Parent = mainPage

local stealBtn, stealDot, stealStroke, stealColor =
    makeToggle(mainPage, 32, "Auto Steal Raft Chests", Color3.fromRGB(0, 255, 150))

-- action buttons
local function makeActionBtn(parent, yPos, text, bg, fg)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -24, 0, 32)
    b.Position = UDim2.new(0, 12, 0, yPos)
    b.Text = text
    b.BackgroundColor3 = bg
    b.TextColor3 = fg
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    return b
end

local richestBtn = makeActionBtn(mainPage, 74,
    "Teleport to Richest Chest",
    Color3.fromRGB(55, 45, 15),
    Color3.fromRGB(255, 220, 90))

local stopBtn = makeActionBtn(mainPage, 112,
    "STOP",
    Color3.fromRGB(60, 30, 40),
    Color3.fromRGB(255, 130, 150))

local returnBtn = makeActionBtn(mainPage, 150,
    "Return to My Raft",
    Color3.fromRGB(30, 42, 60),
    Color3.fromRGB(120, 200, 255))

local rescanBtn = makeActionBtn(mainPage, 188,
    "Scan Raft Chests (F9 log)",
    Color3.fromRGB(40, 40, 55),
    Color3.fromRGB(180, 180, 205))

-- =====================================================================
--  7.  SIDEBAR NAV
-- =====================================================================
local function makeSidebarBtn(text, yPos)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -14, 0, 38)
    b.Position = UDim2.new(0, 7, 0, yPos)
    b.Text = text
    b.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    b.TextColor3 = Color3.fromRGB(200, 200, 215)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.Parent = sidebar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    return b
end

local mainNav = makeSidebarBtn("Main", 14)
local espNav  = makeSidebarBtn("ESP",  60)

local function setActive(active, inactive)
    active.BackgroundColor3 = Color3.fromRGB(70, 50, 130)
    active.TextColor3 = Color3.fromRGB(240, 235, 255)
    inactive.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    inactive.TextColor3 = Color3.fromRGB(200, 200, 215)
end

mainNav.MouseButton1Click:Connect(function()
    mainPage.Visible = true; espPage.Visible = false; setActive(mainNav, espNav)
end)
espNav.MouseButton1Click:Connect(function()
    mainPage.Visible = false; espPage.Visible = true; setActive(espNav, mainNav)
end)
setActive(mainNav, espNav)

-- minimize / close
local minimized = false
local reopenBtn
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        mainFrame.Visible = false
        if not reopenBtn then
            reopenBtn = Instance.new("TextButton")
            reopenBtn.Size = UDim2.new(0, 140, 0, 34)
            reopenBtn.Position = UDim2.new(0.5, -70, 0, 14)
            reopenBtn.Text = "AniScript"
            reopenBtn.BackgroundColor3 = Color3.fromRGB(24, 20, 40)
            reopenBtn.TextColor3 = Color3.fromRGB(180, 150, 255)
            reopenBtn.Font = Enum.Font.GothamBold
            reopenBtn.TextSize = 13
            reopenBtn.Parent = screenGui
            Instance.new("UICorner", reopenBtn).CornerRadius = UDim.new(0, 10)
            local s = Instance.new("UIStroke", reopenBtn)
            s.Color = Color3.fromRGB(150, 100, 255)
            s.Transparency = 0.35
            reopenBtn.MouseButton1Click:Connect(function()
                mainFrame.Visible = true
                reopenBtn:Destroy(); reopenBtn = nil; minimized = false
            end)
        end
    end
end)
closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

-- =====================================================================
--  8.  KEYWORDS + MATCHER
-- =====================================================================
local KEYWORDS = {
    chests = {"chest", "stash", "treasure", "crate", "safe", "vault"},
    rafts  = {"raft", "boat", "plot", "platform", "ship"},
    loots  = {"loot", "drop", "bag", "pickup", "reward"},
    sharks = {"shark", "meg", "fish", "predator", "monster", "whale", "orca", "croc", "piranha"},
}

local function nameMatches(name, keywords)
    local l = string.lower(name)
    for _, kw in ipairs(keywords) do
        if string.find(l, kw, 1, true) then return true end
    end
    return false
end

-- =====================================================================
--  9.  ESP SYSTEM
-- =====================================================================
local espState = { players=false, chests=false, rafts=false, loots=false, sharks=false }
local espObjs  = { players={}, chests={}, rafts={}, loots={}, sharks={} }

local function createHighlight(target, color)
    if not target or not target.Parent then return nil end
    local h = Instance.new("Highlight")
    h.Adornee = target
    h.FillColor = color
    h.FillTransparency = 0.55
    h.OutlineColor = Color3.fromRGB(255, 255, 255)
    h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = target
    return h
end

local function clearGroup(g)
    for _, h in pairs(espObjs[g]) do
        if h and h.Parent then h:Destroy() end
    end
    espObjs[g] = {}
end

local function refreshPlayers()
    clearGroup("players")
    if not espState.players then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local h = createHighlight(p.Character, Color3.fromRGB(0, 255, 120))
            if h then espObjs.players[p.Character] = h end
        end
    end
end

local function refreshWorldESP()
    clearGroup("chests"); clearGroup("rafts"); clearGroup("loots"); clearGroup("sharks")
    if not (espState.chests or espState.rafts or espState.loots or espState.sharks) then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            if not Players:GetPlayerFromCharacter(obj) then
                local n = obj.Name
                if espState.chests and nameMatches(n, KEYWORDS.chests) then
                    local h = createHighlight(obj, Color3.fromRGB(255, 200, 0))
                    if h then espObjs.chests[obj] = h end
                elseif espState.rafts and nameMatches(n, KEYWORDS.rafts) then
                    local h = createHighlight(obj, Color3.fromRGB(60, 140, 255))
                    if h then espObjs.rafts[obj] = h end
                elseif espState.loots and nameMatches(n, KEYWORDS.loots) then
                    local h = createHighlight(obj, Color3.fromRGB(170, 110, 60))
                    if h then espObjs.loots[obj] = h end
                elseif espState.sharks and nameMatches(n, KEYWORDS.sharks) then
                    local h = createHighlight(obj, Color3.fromRGB(255, 50, 50))
                    if h then espObjs.sharks[obj] = h end
                end
            end
        end
    end
end

pBtn.MouseButton1Click:Connect(function()
    espState.players = not espState.players
    updateToggle(pBtn, pDot, pStroke, pColor, espState.players, "Player ESP")
    refreshPlayers()
end)
cBtn.MouseButton1Click:Connect(function()
    espState.chests = not espState.chests
    updateToggle(cBtn, cDot, cStroke, cColor, espState.chests, "Chest ESP")
    refreshWorldESP()
end)
rBtn.MouseButton1Click:Connect(function()
    espState.rafts = not espState.rafts
    updateToggle(rBtn, rDot, rStroke, rColor, espState.rafts, "Raft ESP")
    refreshWorldESP()
end)
lBtn.MouseButton1Click:Connect(function()
    espState.loots = not espState.loots
    updateToggle(lBtn, lDot, lStroke, lColor, espState.loots, "Loot ESP")
    refreshWorldESP()
end)
sBtn.MouseButton1Click:Connect(function()
    espState.sharks = not espState.sharks
    updateToggle(sBtn, sDot, sStroke, sColor, espState.sharks, "Shark ESP")
    refreshWorldESP()
end)

-- =====================================================================
--  10.  RAFT / CHEST HELPERS  (fixed bounding box)
-- =====================================================================

local function getRafts()
    local list = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
            if nameMatches(obj.Name, KEYWORDS.rafts) then
                table.insert(list, obj)
            end
        end
    end
    return list
end

local function getRaftOwner(raft)
    if not raft then return nil end
    local attrs = {"Owner", "Player", "UserId", "PlotOwner", "OwnerUserId"}
    local function scan(inst)
        for _, attr in ipairs(attrs) do
            local v = inst:GetAttribute(attr)
            if v ~= nil then
                if typeof(v) == "Instance" and v:IsA("Player") then return v end
                if typeof(v) == "number" then
                    local p = Players:GetPlayerByUserId(v)
                    if p then return p end
                end
                if typeof(v) == "string" then
                    local p = Players:FindFirstChild(v)
                    if p and p:IsA("Player") then return p end
                end
            end
        end
        return nil
    end
    local o = scan(raft)
    if o then return o end
    local anc = raft.Parent
    while anc and anc ~= workspace do
        local o2 = scan(anc)
        if o2 then return o2 end
        anc = anc.Parent
    end
    return nil
end

local function isRaftShielded(raft)
    if not raft then return false end
    local attrs = {"Shielded", "Shield", "Protected", "IsShielded", "Locked"}
    local function scan(inst)
        for _, attr in ipairs(attrs) do
            if inst:GetAttribute(attr) == true then return true end
        end
        return false
    end
    if scan(raft) then return true end
    local anc = raft.Parent
    while anc and anc ~= workspace do
        if scan(anc) then return true end
        anc = anc.Parent
    end
    return false
end

local function chestHasResources(chest)
    for _, attr in ipairs({"Value", "Amount", "Resources", "Coins", "Gold", "Count"}) do
        local v = chest:GetAttribute(attr)
        if typeof(v) == "number" and v > 0 then return true end
    end
    local n = 0
    for _, d in ipairs(chest:GetChildren()) do
        if d:IsA("BasePart") then
            local lower = string.lower(d.Name)
            if not string.find(lower, "decal", 1, true)
               and not string.find(lower, "handle", 1, true)
               and not string.find(lower, "icon", 1, true)
               and not string.find(lower, "highlight", 1, true) then
                n = n + 1
            end
        elseif d:IsA("Model") or d:IsA("Folder") then
            n = n + 1
        end
    end
    return n > 0
end

local function chestValue(chest)
    for _, attr in ipairs({"Value", "Amount", "Resources", "Coins", "Gold", "Count"}) do
        local v = chest:GetAttribute(attr)
        if typeof(v) == "number" then return v end
    end
    local n = 0
    for _, d in ipairs(chest:GetChildren()) do
        if d:IsA("BasePart") then
            local lower = string.lower(d.Name)
            if not string.find(lower, "decal", 1, true)
               and not string.find(lower, "handle", 1, true)
               and not string.find(lower, "icon", 1, true)
               and not string.find(lower, "highlight", 1, true) then
                n = n + 1
            end
        elseif d:IsA("Model") or d:IsA("Folder") then
            n = n + 1
        end
    end
    return n
end

-- FIXED bounding-box check
local function isInsideRaft(part, raft)
    if not part or not raft then return false end
    local ok, cframe = pcall(function()
        if raft.PrimaryPart then
            return raft:GetModelCFrame()
        else
            local anyPart = raft:FindFirstChildWhichIsA("BasePart")
            if anyPart then return anyPart.CFrame end
            return nil
        end
    end)
    if not ok or not cframe then
        -- fallback: distance-based
        local root = raft:FindFirstChildWhichIsA("BasePart")
        if not root then return false end
        return (part.Position - root.Position).Magnitude < 30
    end

    local ok2, size = pcall(function() return raft:GetExtentsSize() end)
    if not ok2 or not size then
        size = Vector3.new(40, 40, 40)
    end

    local localPos = cframe:PointToObjectSpace(part.Position)
    local half = size / 2 + Vector3.new(5, 5, 5)
    return math.abs(localPos.X) <= half.X
       and math.abs(localPos.Y) <= half.Y
       and math.abs(localPos.Z) <= half.Z
end

-- =====================================================================
--  11.  AUTO STEAL (v5-style, proven to work)
-- =====================================================================
local autoSteal = false
local savedCFrame = nil

local function getChar()
    local c = LocalPlayer.Character
    if not c then return nil, nil end
    return c, c:FindFirstChild("HumanoidRootPart")
end

local function saveMySpot()
    local _, hrp = getChar()
    if hrp then savedCFrame = hrp.CFrame end
end

-- continuously refresh saved spot when idle
task.spawn(function()
    while screenGui.Parent do
        task.wait(1)
        if not autoSteal then saveMySpot() end
    end
end)

local function returnToMySpot()
    -- 1) saved CFrame
    if savedCFrame then
        local _, hrp = getChar()
        if hrp then
            hrp.CFrame = savedCFrame
            return true
        end
    end
    -- 2) my own raft
    local rafts = getRafts()
    for _, raft in ipairs(rafts) do
        local owner = getRaftOwner(raft)
        if owner == LocalPlayer then
            local root = raft.PrimaryPart or raft:FindFirstChildWhichIsA("BasePart")
            if root then
                local _, hrp = getChar()
                if hrp then
                    hrp.CFrame = CFrame.new(root.Position + Vector3.new(0, 5, 0))
                    return true
                end
            end
        end
    end
    -- 3) spawn
    local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
    if spawn then
        local _, hrp = getChar()
        if hrp then
            hrp.CFrame = CFrame.new(spawn.Position + Vector3.new(0, 5, 0))
            return true
        end
    end
    return false
end

local function getRaftChests()
    local rafts = getRafts()
    local list = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            if not Players:GetPlayerFromCharacter(obj) then
                if nameMatches(obj.Name, KEYWORDS.chests) then
                    local root = obj:IsA("Model")
                        and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))
                        or obj
                    if root and root:IsA("BasePart") then
                        -- find raft containing this chest
                        local raft = nil
                        for _, r in ipairs(rafts) do
                            if isInsideRaft(root, r) then
                                raft = r
                                break
                            end
                        end
                        if not raft then continue end

                        -- skip my own
                        local owner = getRaftOwner(raft)
                        if owner == LocalPlayer then continue end

                        -- skip shielded
                        if isRaftShielded(raft) then continue end

                        -- skip empty
                        if not chestHasResources(obj) then continue end

                        table.insert(list, {
                            obj = obj,
                            part = root,
                            raft = raft,
                            owner = owner,
                            value = chestValue(obj),
                        })
                    end
                end
            end
        end
    end
    return list
end

local function distTo(part)
    local _, hrp = getChar()
    if not hrp or not part then return math.huge end
    return (hrp.Position - part.Position).Magnitude
end

local function tpTo(pos)
    local _, hrp = getChar()
    if hrp then hrp.CFrame = CFrame.new(pos) end
end

local function interact(entry)
    local char = LocalPlayer.Character
    if not char then return end
    local _, hrp = getChar()
    if hrp and entry.part then
        hrp.CFrame = CFrame.new(entry.part.Position + Vector3.new(0, 1.5, 0))
    end
    task.wait(0.15)

    for _, t in ipairs(char:GetChildren()) do
        if t:IsA("Tool") then pcall(function() t:Activate() end) end
    end

    for _, d in ipairs(entry.obj:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Enabled then
            pcall(function()
                d:InputHoldBegin()
                local hold = d.HoldDuration or 0
                task.wait(hold > 0 and (hold + 0.1) or 0.15)
                d:InputHoldEnd()
            end)
        elseif d:IsA("ClickDetector") then
            pcall(function() fireclickdetector(d) end)
        end
    end

    if entry.raft then
        for _, d in ipairs(entry.raft:GetDescendants()) do
            if d:IsA("ProximityPrompt") and d.Enabled then
                pcall(function()
                    d:InputHoldBegin()
                    task.wait((d.HoldDuration or 0) + 0.1)
                    d:InputHoldEnd()
                end)
            end
        end
    end
    task.wait(0.15)
end

local function stealChest(entry)
    if not entry.part then return end
    tpTo(entry.part.Position + Vector3.new(0, 2, 0))
    task.wait(0.1)
    interact(entry)
end

-- main loop (guarded)
task.spawn(function()
    while screenGui.Parent do
        task.wait(0.4)
        if autoSteal then
            local ok, err = pcall(function()
                local chests = getRaftChests()
                if #chests == 0 then
                    setStatus("Auto Steal: no valid raft chests found.")
                    return
                end
                table.sort(chests, function(a, b) return distTo(a.part) < distTo(b.part) end)
                for i, c in ipairs(chests) do
                    if not autoSteal then break end
                    local ownerName = c.owner and c.owner.Name or "?"
                    setStatus(("Stealing %d/%d — %s (owner: %s)"):format(i, #chests, c.obj.Name, ownerName))
                    stealChest(c)
                end
                returnToMySpot()
                setStatus("Cycle done. Back on my raft.")
            end)
            if not ok then
                warn("[AniScript] steal error:", err)
                setStatus("Error — see F9.")
            end
        end
    end
end)

stealBtn.MouseButton1Click:Connect(function()
    autoSteal = not autoSteal
    if autoSteal then
        saveMySpot()
        setStatus("Auto Steal: STARTED.")
    else
        setStatus("Auto Steal: stopped.")
    end
    updateToggle(stealBtn, stealDot, stealStroke, stealColor, autoSteal, "Auto Steal Raft Chests")
end)

stopBtn.MouseButton1Click:Connect(function()
    autoSteal = false
    updateToggle(stealBtn, stealDot, stealStroke, stealColor, false, "Auto Steal Raft Chests")
    returnToMySpot()
    setStatus("Stopped + returned.")
end)

returnBtn.MouseButton1Click:Connect(function()
    if returnToMySpot() then setStatus("Returned to my raft.") else setStatus("Could not return.") end
end)

-- Teleport to Richest Chest
richestBtn.MouseButton1Click:Connect(function()
    local ok, err = pcall(function()
        local chests = getRaftChests()
        if #chests == 0 then
            setStatus("Richest: no valid raft chests.")
            return
        end
        table.sort(chests, function(a, b) return a.value > b.value end)
        local best = chests[1]
        tpTo(best.part.Position + Vector3.new(0, 3, 0))
        local ownerName = best.owner and best.owner.Name or "?"
        setStatus(("Richest → %s (value=%d, owner=%s)"):format(best.obj.Name, best.value, ownerName))
        print(("[AniScript Richest] %s | value=%d | owner=%s"):format(best.obj.Name, best.value, ownerName))
    end)
    if not ok then
        warn("[AniScript] richest error:", err)
        setStatus("Richest error — see F9.")
    end
end)

rescanBtn.MouseButton1Click:Connect(function()
    local ok, err = pcall(function()
        local chests = getRaftChests()
        print(("=== AniScript RAFT CHEST SCAN: %d valid ==="):format(#chests))
        for i, c in ipairs(chests) do
            local owner = c.owner and c.owner.Name or "?"
            print(("[%d] %s | raft=%s | owner=%s | value=%d | dist=%.0f"):format(
                i, c.obj.Name, c.raft.Name, owner, c.value, distTo(c.part)))
        end
        print("=== All rafts ===")
        for _, r in ipairs(getRafts()) do
            local o = getRaftOwner(r)
            local s = isRaftShielded(r)
            print(("  %s | owner=%s | shielded=%s"):format(r.Name, o and o.Name or "?", tostring(s)))
        end
        setStatus(("Scan: %d valid raft chests. See F9."):format(#chests))
    end)
    if not ok then
        warn("[AniScript] scan error:", err)
        setStatus("Scan error — see F9.")
    end
end)

-- =====================================================================
--  12.  REFRESH LOOP
-- =====================================================================
task.spawn(function()
    while screenGui.Parent do
        task.wait(2)
        if espState.players then refreshPlayers() end
        if espState.chests or espState.rafts or espState.loots or espState.sharks then
            refreshWorldESP()
        end
    end
end)

UserInput.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

setStatus("AniScript ready.")
print("[AniScript v7] loaded.")
