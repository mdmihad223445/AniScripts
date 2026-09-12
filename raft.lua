-- =====================================================================
--  PRO SCRIPT v4  —  Full build
--  ESP: Player (green) | Chest (gold) | Raft (blue) | Loot (brown) | Shark (red)
--  Main: Auto Steal All Chests (tween-tp + all interactions + return)
-- =====================================================================

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInput    = game:GetService("UserInputService")
local LocalPlayer  = Players.LocalPlayer

-- =====================================================================
--  1.  GUI
-- =====================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ProScriptV4"
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 360, 0, 280)
mainFrame.Position = UDim2.new(0.5, -180, 0.5, -140)
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

-- title bar
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
title.Text = "PRO SCRIPT v4"
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

-- sidebar
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 84, 1, -34)
sidebar.Position = UDim2.new(0, 0, 0, 34)
sidebar.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
sidebar.BorderSizePixel = 0
sidebar.Parent = mainFrame

-- content
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
--  3.  STATUS LABEL (shared)
-- =====================================================================
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 60)
statusLabel.Position = UDim2.new(0, 10, 1, -66)
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
    btn.Size = UDim2.new(1, -20, 0, 30)
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
local cBtn, cDot, cStroke, cColor = makeToggle(espPage, 64, "Chest ESP",  Color3.fromRGB(255, 200, 0))
local rBtn, rDot, rStroke, rColor = makeToggle(espPage, 98, "Raft ESP",   Color3.fromRGB(60, 140, 255))
local lBtn, lDot, lStroke, lColor = makeToggle(espPage, 132, "Loot ESP",  Color3.fromRGB(170, 110, 60))
local sBtn, sDot, sStroke, sColor = makeToggle(espPage, 166, "Shark ESP", Color3.fromRGB(255, 50, 50))

-- debug dump button
local dumpBtn = Instance.new("TextButton")
dumpBtn.Size = UDim2.new(1, -20, 0, 26)
dumpBtn.Position = UDim2.new(0, 10, 0, 200)
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
mainHeader.Size = UDim2.new(1, -20, 0, 20)
mainHeader.Position = UDim2.new(0, 10, 0, 6)
mainHeader.BackgroundTransparency = 1
mainHeader.Text = "MAIN — AUTO STEAL"
mainHeader.TextColor3 = Color3.fromRGB(0, 255, 150)
mainHeader.Font = Enum.Font.GothamBold
mainHeader.TextSize = 11
mainHeader.TextXAlignment = Enum.TextXAlignment.Left
mainHeader.Parent = mainPage

local stealBtn, stealDot, stealStroke, stealColor =
    makeToggle(mainPage, 32, "Auto Steal All Chests", Color3.fromRGB(0, 255, 150))

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(1, -20, 0, 28)
stopBtn.Position = UDim2.new(0, 10, 0, 68)
stopBtn.Text = "STOP"
stopBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
stopBtn.TextColor3 = Color3.fromRGB(255, 130, 130)
stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 11
stopBtn.Parent = mainPage
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 6)

local returnBtn = Instance.new("TextButton")
returnBtn.Size = UDim2.new(1, -20, 0, 28)
returnBtn.Position = UDim2.new(0, 10, 0, 102)
returnBtn.Text = "Return to My Raft"
returnBtn.BackgroundColor3 = Color3.fromRGB(30, 40, 55)
returnBtn.TextColor3 = Color3.fromRGB(120, 200, 255)
returnBtn.Font = Enum.Font.GothamBold
returnBtn.TextSize = 11
returnBtn.Parent = mainPage
Instance.new("UICorner", returnBtn).CornerRadius = UDim.new(0, 6)

local rescanBtn = Instance.new("TextButton")
rescanBtn.Size = UDim2.new(1, -20, 0, 28)
rescanBtn.Position = UDim2.new(0, 10, 0, 136)
rescanBtn.Text = "Re-scan Chests (F9 log)"
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
    mainPage.Visible = true
    espPage.Visible = false
    setActive(mainNav, espNav)
end)
espNav.MouseButton1Click:Connect(function()
    mainPage.Visible = false
    espPage.Visible = true
    setActive(espNav, mainNav)
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
--  8.  KEYWORDS + MATCHER
-- =====================================================================
local KEYWORDS = {
    chests = {"chest", "stash", "treasure", "crate", "safe", "vault", "lootbox"},
    rafts  = {"raft", "boat", "plot", "platform", "ship"},
    loots  = {"loot", "drop", "bag", "pickup", "reward", "coin", "gem"},
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
    if espState.sharks then
        -- print all shark-like matches so user can see real names
        print("=== SHARK ESP DEBUG ===")
        local found = 0
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
                if nameMatches(obj.Name, KEYWORDS.sharks) then
                    print("  MATCH:", obj.Name, obj.ClassName)
                    found = found + 1
                end
            end
        end
        print(("Total shark-like models: %d"):format(found))
        print("=======================")
    end
end)

-- workspace name dump
dumpBtn.MouseButton1Click:Connect(function()
    print("===== WORKSPACE MODEL DUMP =====")
    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
            print(obj.ClassName, "->", obj.Name)
            count = count + 1
            if count >= 200 then print("...truncated at 200"); break end
        end
    end
    print(("Total models (first 200 shown): %d"):format(count))
    print("===============================")
    setStatus("Dumped workspace model names to F9 console.")
end)

-- =====================================================================
--  10.  AUTO STEAL  (smooth tween-tp + every interaction)
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
    if hrp then
        savedCFrame = hrp.CFrame
        setStatus("Saved my position.")
    end
end

local function returnToMySpot()
    if not savedCFrame then
        setStatus("No saved spot. Toggle Auto Steal to save it.")
        return
    end
    local _, hrp = getChar()
    if hrp then
        hrp.CFrame = savedCFrame
        setStatus("Returned to my raft.")
    end
end

local function getChests()
    local list = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            if not Players:GetPlayerFromCharacter(obj) then
                if nameMatches(obj.Name, KEYWORDS.chests) then
                    local root = obj:IsA("Model")
                        and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))
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

local function distTo(part)
    local _, hrp = getChar()
    if not hrp or not part then return math.huge end
    return (hrp.Position - part.Position).Magnitude
end

-- Smooth tween teleport (avoids insta-kick from naive speed checks)
local function smoothTeleport(targetPos)
    local _, hrp = getChar()
    if not hrp then return end
    local dist = (hrp.Position - targetPos).Magnitude
    -- duration scaled: ~1s per 200 studs, min 0.15s
    local dur = math.clamp(dist / 200, 0.15, 1.2)
    local tw = TweenService:Create(
        hrp,
        TweenInfo.new(dur, Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(targetPos)}
    )
    tw:Play()
    tw.Completed:Wait()
end

-- Try every interaction path on the chest
local function interactWithChest(entry)
    local char = LocalPlayer.Character
    if not char then return end

    -- 1) tools
    for _, t in ipairs(char:GetChildren()) do
        if t:IsA("Tool") then
            pcall(function() t:Activate() end)
        end
    end

    -- 2) ProximityPrompt (hold)
    for _, d in ipairs(entry.obj:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            pcall(function()
                d.Enabled = true
                d:InputHoldBegin()
                local hold = d.HoldDuration
                if hold and hold > 0 then
                    task.wait(hold + 0.05)
                else
                    task.wait(0.12)
                end
                d:InputHoldEnd()
            end)
        end
    end

    -- 3) ClickDetector
    for _, d in ipairs(entry.obj:GetDescendants()) do
        if d:IsA("ClickDetector") then
            pcall(function() fireclickdetector(d) end)
        end
    end

    -- 4) Touched — move HRP inside
    local _, hrp = getChar()
    if hrp and entry.part then
        hrp.CFrame = CFrame.new(entry.part.Position + Vector3.new(0, 1, 0))
    end

    task.wait(0.18)
end

-- steal one chest
local function stealChest(entry)
    local _, hrp = getChar()
    if not hrp or not entry.part then return end
    local targetPos = entry.part.Position + Vector3.new(0, 2.5, 0)
    smoothTeleport(targetPos)
    interactWithChest(entry)
end

-- main auto loop
task.spawn(function()
    while screenGui.Parent do
        task.wait(0.5)
        if autoSteal then
            local chests = getChests()
            if #chests == 0 then
                setStatus("Auto Steal: no chests found.")
            else
                table.sort(chests, function(a, b) return distTo(a.part) < distTo(b.part) end)
                for i, c in ipairs(chests) do
                    if not autoSteal then break end
                    setStatus(("Stealing %d/%d — %s"):format(i, #chests, c.obj.Name))
                    stealChest(c)
                end
                returnToMySpot()
                setStatus("Cycle done. Back on my raft.")
            end
        end
    end
end)

stealBtn.MouseButton1Click:Connect(function()
    autoSteal = not autoSteal
    if autoSteal then
        saveMySpot()
        setStatus("Auto Steal: STARTED (my spot saved).")
    else
        setStatus("Auto Steal: stopped.")
    end
    updateToggle(stealBtn, stealDot, stealStroke, stealColor, autoSteal, "Auto Steal All Chests")
end)

stopBtn.MouseButton1Click:Connect(function()
    autoSteal = false
    updateToggle(stealBtn, stealDot, stealStroke, stealColor, false, "Auto Steal All Chests")
    returnToMySpot()
    setStatus("Stopped.")
end)

returnBtn.MouseButton1Click:Connect(function()
    returnToMySpot()
end)

rescanBtn.MouseButton1Click:Connect(function()
    local chests = getChests()
    print(("=== CHEST SCAN: %d found ==="):format(#chests))
    for i, c in ipairs(chests) do
        print(("[%d] %s (%s) — dist %.0f"):format(i, c.obj.Name, c.obj.ClassName, distTo(c.part)))
    end
    setStatus(("Scan: %d chests. See F9 console."):format(#chests))
end)

-- =====================================================================
--  11.  OPTIMIZED REFRESH LOOP
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

-- shortcut
UserInput.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

setStatus("Loaded. Ready.")
print("[PRO SCRIPT v4] ready — F9 console for scans.")
