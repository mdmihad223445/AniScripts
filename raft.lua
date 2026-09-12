-- =====================================================================
--  PRO SCRIPT v6 — Raft Chest Auto Steal (bug-fixed)
--  ESP: Player(green) | Chest(gold) | Raft(blue) | Loot(brown) | Shark(red)
--  Auto Steal: ONLY chests physically inside OTHER players' rafts
--  New: Teleport to Richest Chest
-- =====================================================================

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInput    = game:GetService("UserInputService")
local LocalPlayer  = Players.LocalPlayer

-- =====================================================================
--  1.  GUI
-- =====================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ProScriptV6"
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 360, 0, 300)
mainFrame.Position = UDim2.new(0.5, -180, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)
local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = Color3.fromRGB(0, 255, 150)
mainStroke.Thickness = 1
mainStroke.Transparency = 0.45

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 34)
titleBar.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -90, 1, 0)
title.Position = UDim2.new(0, 14, 0, 0)
title.BackgroundTransparency = 1
title.Text = "PRO SCRIPT v6"
title.TextColor3 = Color3.fromRGB(0, 255, 150)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 24, 0, 24)
minBtn.Position = UDim2.new(1, -54, 0, 5)
minBtn.Text = "—"
minBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 13
minBtn.Parent = titleBar
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -28, 0, 5)
closeBtn.Text = "×"
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 15
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 84, 1, -34)
sidebar.Position = UDim2.new(0, 0, 0, 34)
sidebar.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
sidebar.BorderSizePixel = 0
sidebar.Parent = mainFrame

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -84, 1, -34)
content.Position = UDim2.new(0, 84, 0, 34)
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
statusLabel.Size = UDim2.new(1, -20, 0, 70)
statusLabel.Position = UDim2.new(0, 10, 1, -76)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Ready."
statusLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
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
    btn.Size = UDim2.new(1, -20, 0, 28)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    btn.TextColor3 = Color3.fromRGB(215, 215, 220)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Text = label .. "  [OFF]"
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(55, 55, 65)
    stroke.Thickness = 1
    local pad = Instance.new("UIPadding", btn)
    pad.PaddingLeft = UDim.new(0, 12)
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(1, -18, 0.5, -4)
    dot.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
    dot.BorderSizePixel = 0
    dot.Parent = btn
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    return btn, dot, stroke, color
end

local function updateToggle(btn, dot, stroke, color, on, label)
    if on then
        btn.BackgroundColor3 = Color3.fromRGB(color.R * 0.28, color.G * 0.28, color.B * 0.28)
        btn.TextColor3 = color
        dot.BackgroundColor3 = color
        stroke.Color = color
        stroke.Transparency = 0.2
    else
        btn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
        btn.TextColor3 = Color3.fromRGB(215, 215, 220)
        dot.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
        stroke.Color = Color3.fromRGB(55, 55, 65)
        stroke.Transparency = 0
    end
    btn.Text = label .. "  [" .. (on and "ON" or "OFF") .. "]"
end

-- =====================================================================
--  5.  ESP PAGE
-- =====================================================================
local espHeader = Instance.new("TextLabel")
espHeader.Size = UDim2.new(1, -20, 0, 20)
espHeader.Position = UDim2.new(0, 10, 0, 6)
espHeader.BackgroundTransparency = 1
espHeader.Text = "ESP CONTROLS"
espHeader.TextColor3 = Color3.fromRGB(0, 255, 150)
espHeader.Font = Enum.Font.GothamBold
espHeader.TextSize = 11
espHeader.TextXAlignment = Enum.TextXAlignment.Left
espHeader.Parent = espPage

local pBtn, pDot, pStroke, pColor = makeToggle(espPage, 30, "Player ESP", Color3.fromRGB(0, 255, 120))
local cBtn, cDot, cStroke, cColor = makeToggle(espPage, 62, "Chest ESP",  Color3.fromRGB(255, 200, 0))
local rBtn, rDot, rStroke, rColor = makeToggle(espPage, 94, "Raft ESP",   Color3.fromRGB(60, 140, 255))
local lBtn, lDot, lStroke, lColor = makeToggle(espPage, 126, "Loot ESP",  Color3.fromRGB(170, 110, 60))
local sBtn, sDot, sStroke, sColor = makeToggle(espPage, 158, "Shark ESP", Color3.fromRGB(255, 50, 50))

local dumpBtn = Instance.new("TextButton")
dumpBtn.Size = UDim2.new(1, -20, 0, 26)
dumpBtn.Position = UDim2.new(0, 10, 0, 192)
dumpBtn.Text = "Dump Workspace Names (F9)"
dumpBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
dumpBtn.TextColor3 = Color3.fromRGB(180, 180, 200)
dumpBtn.Font = Enum.Font.GothamBold
dumpBtn.TextSize = 10
dumpBtn.Parent = espPage
Instance.new("UICorner", dumpBtn).CornerRadius = UDim.new(0, 6)

-- =====================================================================
--  6.  MAIN PAGE
-- =====================================================================
local mainHeader = Instance.new("TextLabel")
mainHeader.Size = UDim2.new(1, -20, 0, 18)
mainHeader.Position = UDim2.new(0, 10, 0, 4)
mainHeader.BackgroundTransparency = 1
mainHeader.Text = "MAIN — AUTO STEAL RAFT CHESTS"
mainHeader.TextColor3 = Color3.fromRGB(0, 255, 150)
mainHeader.Font = Enum.Font.GothamBold
mainHeader.TextSize = 10
mainHeader.TextXAlignment = Enum.TextXAlignment.Left
mainHeader.Parent = mainPage

local stealBtn, stealDot, stealStroke, stealColor =
    makeToggle(mainPage, 26, "Auto Steal Raft Chests", Color3.fromRGB(0, 255, 150))

local richestBtn = Instance.new("TextButton")
richestBtn.Size = UDim2.new(1, -20, 0, 28)
richestBtn.Position = UDim2.new(0, 10, 0, 60)
richestBtn.Text = "Teleport to Richest Chest"
richestBtn.BackgroundColor3 = Color3.fromRGB(50, 40, 15)
richestBtn.TextColor3 = Color3.fromRGB(255, 220, 80)
richestBtn.Font = Enum.Font.GothamBold
richestBtn.TextSize = 11
richestBtn.Parent = mainPage
Instance.new("UICorner", richestBtn).CornerRadius = UDim.new(0, 6)

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(1, -20, 0, 26)
stopBtn.Position = UDim2.new(0, 10, 0, 94)
stopBtn.Text = "STOP"
stopBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
stopBtn.TextColor3 = Color3.fromRGB(255, 130, 130)
stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 11
stopBtn.Parent = mainPage
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 6)

local returnBtn = Instance.new("TextButton")
returnBtn.Size = UDim2.new(1, -20, 0, 26)
returnBtn.Position = UDim2.new(0, 10, 0, 126)
returnBtn.Text = "Return to My Raft"
returnBtn.BackgroundColor3 = Color3.fromRGB(30, 40, 55)
returnBtn.TextColor3 = Color3.fromRGB(120, 200, 255)
returnBtn.Font = Enum.Font.GothamBold
returnBtn.TextSize = 11
returnBtn.Parent = mainPage
Instance.new("UICorner", returnBtn).CornerRadius = UDim.new(0, 6)

local rescanBtn = Instance.new("TextButton")
rescanBtn.Size = UDim2.new(1, -20, 0, 26)
rescanBtn.Position = UDim2.new(0, 10, 0, 158)
rescanBtn.Text = "Scan Raft Chests (F9)"
rescanBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
rescanBtn.TextColor3 = Color3.fromRGB(180, 180, 200)
rescanBtn.Font = Enum.Font.GothamBold
rescanBtn.TextSize = 11
rescanBtn.Parent = mainPage
Instance.new("UICorner", rescanBtn).CornerRadius = UDim.new(0, 6)

-- =====================================================================
--  7.  SIDEBAR NAV
-- =====================================================================
local function makeSidebarBtn(text, yPos)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -12, 0, 32)
    b.Position = UDim2.new(0, 6, 0, yPos)
    b.Text = text
    b.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    b.TextColor3 = Color3.fromRGB(200, 200, 210)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.Parent = sidebar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local mainNav = makeSidebarBtn("Main", 10)
local espNav  = makeSidebarBtn("ESP",  50)

local function setActive(active, inactive)
    active.BackgroundColor3 = Color3.fromRGB(0, 120, 70)
    active.TextColor3 = Color3.fromRGB(255, 255, 255)
    inactive.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    inactive.TextColor3 = Color3.fromRGB(200, 200, 210)
end

mainNav.MouseButton1Click:Connect(function()
    mainPage.Visible = true; espPage.Visible = false; setActive(mainNav, espNav)
end)
espNav.MouseButton1Click:Connect(function()
    mainPage.Visible = false; espPage.Visible = true; setActive(espNav, mainNav)
end)
setActive(mainNav, espNav)

local minimized = false
local reopenBtn
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        mainFrame.Visible = false
        if not reopenBtn then
            reopenBtn = Instance.new("TextButton")
            reopenBtn.Size = UDim2.new(0, 130, 0, 32)
            reopenBtn.Position = UDim2.new(0.5, -65, 0, 12)
            reopenBtn.Text = "PRO SCRIPT"
            reopenBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
            reopenBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
            reopenBtn.Font = Enum.Font.GothamBold
            reopenBtn.TextSize = 12
            reopenBtn.Parent = screenGui
            Instance.new("UICorner", reopenBtn).CornerRadius = UDim.new(0, 8)
            local s = Instance.new("UIStroke", reopenBtn)
            s.Color = Color3.fromRGB(0, 255, 150)
            s.Transparency = 0.4
            reopenBtn.MouseButton1Click:Connect(function()
                mainFrame.Visible = true
                reopenBtn:Destroy(); reopenBtn = nil; minimized = false
            end)
        end
    end
end)
closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

-- =====================================================================
--  8.  KEYWORDS
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
--  9.  ESP
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

dumpBtn.MouseButton1Click:Connect(function()
    print("===== WORKSPACE MODEL DUMP =====")
    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
            print(obj.ClassName, "->", obj.Name)
            count = count + 1
            if count >= 200 then print("...truncated"); break end
        end
    end
    print(("Total: %d"):format(count))
    setStatus("Dumped models to F9.")
end)

-- =====================================================================
--  10.  RAFT / CHEST HELPERS
-- =====================================================================

-- Cache raft list; refresh every scan
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
    local function scan(inst)
        for _, attr in ipairs({"Owner", "Player", "UserId", "PlotOwner", "OwnerUserId"}) do
            local v = inst:GetAttribute(attr)
            if v then
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

-- Is the raft shielded / protected?
local function isRaftShielded(raft)
    if not raft then return false end
    local function scan(inst)
        for _, attr in ipairs({"Shielded", "Shield", "Protected", "IsShielded", "Locked"}) do
            local v = inst:GetAttribute(attr)
            if v == true then return true end
        end
        return false
    end
    if scan(raft) then return true end
    local anc = raft.Parent
    while anc and anc ~= workspace do
        if scan(anc) then return true end
        anc = anc.Parent
    end
    -- also scan for a child named Shield
    for _, d in ipairs(raft:GetDescendants()) do
        if string.find(string.lower(d.Name), "shield", 1, true) and d:IsA("BasePart") then
            if d.Transparency < 1 and d.Visible then return true end
        end
    end
    return false
end

-- Does the chest have resources? (children / value attributes)
local function chestHasResources(chest)
    -- read Value / Amount / Resources attribute
    for _, attr in ipairs({"Value", "Amount", "Resources", "Coins", "Gold", "Count"}) do
        local v = chest:GetAttribute(attr)
        if typeof(v) == "number" and v > 0 then return true, v end
    end
    -- count significant children
    local n = 0
    for _, d in ipairs(chest:GetChildren()) do
        if d:IsA("BasePart") then
            local lower = string.lower(d.Name)
            -- skip decals / handles / empty markers
            if not string.find(lower, "decal", 1, true)
               and not string.find(lower, "handle", 1, true)
               and not string.find(lower, "empty", 1, true)
               and not string.find(lower, "icon", 1, true) then
                n = n + 1
            end
        elseif d:IsA("Model") or d:IsA("Folder") then
            n = n + 1
        end
    end
    return n > 0, n
end

-- Get numeric value for "richest" sorting
local function chestValue(chest)
    for _, attr in ipairs({"Value", "Amount", "Resources", "Coins", "Gold", "Count"}) do
        local v = chest:GetAttribute(attr)
        if typeof(v) == "number" then return v end
    end
    -- fallback: child count
    local ok, n = chestHasResources(chest)
    return ok and n or 0
end

-- Bounding-box check: is `part` inside `model`?
local function isInsideModel(part, model)
    if not part or not model then return false end
    local ok, cf, size = pcall(function()
        return model:GetBoundingBox()
    end)
    if not ok then return false end
    local localPos = cf:PointToObjectSpace(part.Position)
    local half = size / 2 + Vector3.new(4, 4, 4)  -- small padding
    return math.abs(localPos.X) <= half.X
       and math.abs(localPos.Y) <= half.Y
       and math.abs(localPos.Z) <= half.Z
end

-- =====================================================================
--  11.  AUTO STEAL  — raft chests only
-- =====================================================================
local autoSteal = false
local savedCFrame = nil
local stealBusy  = false     -- prevents overlapping loops

local function getChar()
    local c = LocalPlayer.Character
    if not c then return nil, nil end
    return c, c:FindFirstChild("HumanoidRootPart")
end

local function saveMySpot()
    local _, hrp = getChar()
    if hrp then savedCFrame = hrp.CFrame end
end

-- Continuously update saved spot while idle so "return" is always current raft
task.spawn(function()
    while screenGui.Parent do
        task.wait(1)
        if not autoSteal then
            saveMySpot()
        end
    end
end)

local function returnToMySpot()
    -- 1) use saved CFrame
    if savedCFrame then
        local _, hrp = getChar()
        if hrp then
            hrp.CFrame = savedCFrame
            return true
        end
    end
    -- 2) fallback: find my own raft
    for _, raft in ipairs(getRafts()) do
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
    -- 3) fallback: spawn
    local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
    if spawn then
        local _, hrp = getChar()
        if hrp then hrp.CFrame = CFrame.new(spawn.Position + Vector3.new(0, 5, 0)) end
    end
    return false
end

-- Get list of raft chests (with owner + resources filter)
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

                        -- Must be strictly INSIDE a raft model
                        local raft = nil
                        for _, r in ipairs(rafts) do
                            if isInsideModel(root, r) then
                                raft = r
                                break
                            end
                        end
                        if not raft then continue end  -- skip sea chests

                        -- Skip own raft
                        local owner = getRaftOwner(raft)
                        if owner == LocalPlayer then continue end

                        -- Skip shielded rafts
                        if isRaftShielded(raft) then continue end

                        -- Skip empty chests
                        local hasRes = chestHasResources(obj)
                        if not hasRes then continue end

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

local function teleportInstant(targetPos)
    local _, hrp = getChar()
    if not hrp then return end
    hrp.CFrame = CFrame.new(targetPos)
end

local function interactWithChest(entry)
    local char = LocalPlayer.Character
    if not char then return end

    local _, hrp = getChar()
    if hrp and entry.part then
        hrp.CFrame = CFrame.new(entry.part.Position + Vector3.new(0, 1.5, 0))
    end
    task.wait(0.15)

    for _, t in ipairs(char:GetChildren()) do
        if t:IsA("Tool") then
            pcall(function() t:Activate() end)
        end
    end

    for _, d in ipairs(entry.obj:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Enabled then
            pcall(function()
                d:InputHoldBegin()
                local hold = d.HoldDuration
                task.wait((hold and hold > 0) and (hold + 0.1) or 0.15)
                d:InputHoldEnd()
            end)
        end
    end

    for _, d in ipairs(entry.obj:GetDescendants()) do
        if d:IsA("ClickDetector") then
            pcall(function() fireclickdetector(d) end)
        end
    end

    -- also try the raft itself
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
    teleportInstant(entry.part.Position + Vector3.new(0, 2, 0))
    task.wait(0.08)
    interactWithChest(entry)
end

-- Main loop (guarded against overlap)
task.spawn(function()
    while screenGui.Parent do
        task.wait(0.4)
        if autoSteal and not stealBusy then
            stealBusy = true

            local ok, err = pcall(function()
                local chests = getRaftChests()
                if #chests == 0 then
                    setStatus("Auto Steal: no valid raft chests (empty / shielded / sea excluded).")
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
                warn("[ProScript] steal loop error:", err)
                setStatus("Auto Steal error — see F9.")
            end

            stealBusy = false
        end
    end
end)

stealBtn.MouseButton1Click:Connect(function()
    autoSteal = not autoSteal
    if autoSteal then
        saveMySpot()
        setStatus("Auto Steal Raft Chests: STARTED.")
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
    if returnToMySpot() then setStatus("Returned to my raft.") else setStatus("No raft found.") end
end)

-- ===== NEW: Teleport to Richest Chest =====
richestBtn.MouseButton1Click:Connect(function()
    local chests = getRaftChests()
    if #chests == 0 then
        setStatus("Richest: no raft chests with resources found.")
        return
    end
    -- sort by value desc
    table.sort(chests, function(a, b) return a.value > b.value end)
    local best = chests[1]
    teleportInstant(best.part.Position + Vector3.new(0, 3, 0))
    local ownerName = best.owner and best.owner.Name or "?"
    setStatus(("Teleported to richest: %s (value=%d, owner=%s)"):format(
        best.obj.Name, best.value, ownerName))
    print(("[Richest] %s | value=%d | owner=%s | raft=%s"):format(
        best.obj.Name, best.value, ownerName, best.raft.Name))
end)

rescanBtn.MouseButton1Click:Connect(function()
    local chests = getRaftChests()
    print(("=== RAFT CHEST SCAN: %d valid ==="):format(#chests))
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

setStatus("Loaded. Ready.")
print("[PRO SCRIPT v6] ready.")
