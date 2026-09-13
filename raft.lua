-- =====================================================================
--  AniScript v10  --  COMPACT UI + EVERY CHEAT FIXED
--  Game: Build and Defend Your Raft (works in any raft-style game)
--
--  FIXED vs v9 (this file):
--   [1] UI: small compact window (~296 x 356) with a MAIN / ESP tab
--       row and a scroll bar inside -- no more big long menu.
--   [2] AUTO STEAL now loops FOREVER across DIFFERENT rafts:
--       teleport -> steal -> return home -> store -> teleport to the
--       NEXT raft -> steal -> return ... Chests you already hit get a
--       45s cooldown and their raft an 18s cooldown, so the loop always
--       moves on to another raft instead of sticking to the same one.
--   [3] FLY rebuilt: movement is CFrame-teleport based every physics
--       step, so neither the humanoid nor game scripts can fight it.
--       WASD move, Space up, Shift down, hover in place when idle.
--   [4] GHOST MODE rebuilt: walk through walls (noclip), stay standing
--       exactly where you are (falling is cancelled), and after you
--       JUMP you stand ON THE AIR at that height and can keep walking
--       on air.
--   [5] GOD MODE rebuilt: huge max health + instant re-heal on every
--       damage tick + the Dead humanoid state is BLOCKED, so even a
--       forced Health = 0 kill cannot finish you.
--
--  Show / hide UI: RightControl
-- =====================================================================

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInput         = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer       = Players.LocalPlayer

-- shared state (declared early because GUI closures use them)
local autoSteal = false
local stealing  = false
local flySpeed  = 80

-- =====================================================================
--  1.  GUI  (COMPACT v10: small window, MAIN/ESP tab row, scrolling)
-- =====================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AniScript"
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local WIN_W, WIN_H = 296, 356
local TITLE_H, TABS_H, STATUS_H = 30, 24, 34

-- main window (SMALL: ~296 x 356 instead of the old 380 x 430)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, WIN_W, 0, WIN_H)
mainFrame.Position = UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

local mainGradient = Instance.new("UIGradient", mainFrame)
mainGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 24, 32)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 14, 20)),
}
mainGradient.Rotation = 90

local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = Color3.fromRGB(120, 80, 255)
mainStroke.Thickness = 1.2
mainStroke.Transparency = 0.35

-- title bar (compact)
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, TITLE_H)
titleBar.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)
local tbFix = Instance.new("Frame")
tbFix.Size = UDim2.new(1, 0, 0, 10)
tbFix.Position = UDim2.new(0, 0, 1, -10)
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
accentBar.Size = UDim2.new(0, 3, 0, 16)
accentBar.Position = UDim2.new(0, 10, 0.5, -8)
accentBar.BackgroundColor3 = Color3.fromRGB(150, 100, 255)
accentBar.BorderSizePixel = 0
accentBar.Parent = titleBar
Instance.new("UICorner", accentBar).CornerRadius = UDim.new(1, 0)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 1, 0)
title.Position = UDim2.new(0, 20, 0, 0)
title.BackgroundTransparency = 1
title.Text = "AniScript  v10"
title.TextColor3 = Color3.fromRGB(240, 235, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- =====================================================================
--  DRAG: hold the TITLE BAR to move the window (same as v9).
-- =====================================================================
local dragZone = Instance.new("Frame")
dragZone.Name = "DragZone"
dragZone.Size = UDim2.new(1, -56, 1, 0)
dragZone.BackgroundTransparency = 1
dragZone.Active = true
dragZone.ZIndex = 2
dragZone.Parent = titleBar

local dragging = false
local dragStart, startPos

dragZone.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

dragZone.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- release outside the title bar must also stop the drag
UserInput.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInput.InputChanged:Connect(function(input)
    if dragging
       and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- minimize
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 20, 0, 20)
minBtn.Position = UDim2.new(1, -50, 0, 5)
minBtn.Text = "-"
minBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
minBtn.TextColor3 = Color3.fromRGB(220, 220, 235)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 12
minBtn.AutoButtonColor = true
minBtn.Parent = titleBar
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

-- close
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 20, 0, 20)
closeBtn.Position = UDim2.new(1, -25, 0, 5)
closeBtn.Text = "x"
closeBtn.BackgroundColor3 = Color3.fromRGB(210, 60, 80)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
local closeGrad = Instance.new("UIGradient", closeBtn)
closeGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(230, 70, 90)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 40, 60)),
}
closeGrad.Rotation = 90

-- =====================================================================
--  TAB ROW (replaces the old 84px sidebar -> the window is much
--  narrower now)
-- =====================================================================
local tabRow = Instance.new("Frame")
tabRow.Size = UDim2.new(1, 0, 0, TABS_H)
tabRow.Position = UDim2.new(0, 0, 0, TITLE_H)
tabRow.BackgroundTransparency = 1
tabRow.Parent = mainFrame

local mainTab = Instance.new("TextButton")
mainTab.Size = UDim2.new(0.5, -8, 0, 20)
mainTab.Position = UDim2.new(0, 6, 0, 2)
mainTab.Text = "MAIN"
mainTab.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
mainTab.TextColor3 = Color3.fromRGB(200, 200, 215)
mainTab.Font = Enum.Font.GothamBold
mainTab.TextSize = 10
mainTab.Parent = tabRow
Instance.new("UICorner", mainTab).CornerRadius = UDim.new(0, 6)

local espTab = Instance.new("TextButton")
espTab.Size = UDim2.new(0.5, -8, 0, 20)
espTab.Position = UDim2.new(0.5, 2, 0, 2)
espTab.Text = "ESP"
espTab.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
espTab.TextColor3 = Color3.fromRGB(200, 200, 215)
espTab.Font = Enum.Font.GothamBold
espTab.TextSize = 10
espTab.Parent = tabRow
Instance.new("UICorner", espTab).CornerRadius = UDim.new(0, 6)

-- =====================================================================
--  SCROLLABLE CONTENT (the menu stays SHORT; anything that does not
--  fit just scrolls -- no more long window)
-- =====================================================================
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -8, 1, -(TITLE_H + TABS_H + STATUS_H + 4))
scroll.Position = UDim2.new(0, 4, 0, TITLE_H + TABS_H + 2)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = Color3.fromRGB(150, 100, 255)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = mainFrame

local MAIN_H, ESP_H = 288, 190

local function newPage(h)
    local p = Instance.new("Frame")
    p.Size = UDim2.new(1, -6, 0, h)
    p.BackgroundTransparency = 1
    p.Visible = false
    p.Parent = scroll
    return p
end

local mainPage = newPage(MAIN_H)
mainPage.Visible = true
local espPage = newPage(ESP_H)

-- =====================================================================
--  STATUS (single footer under the scroll area)
-- =====================================================================
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -16, 0, STATUS_H - 8)
statusLabel.Position = UDim2.new(0, 8, 1, -(STATUS_H + 2))
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Ready."
statusLabel.TextColor3 = Color3.fromRGB(160, 160, 175)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 9
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.TextWrapped = true
statusLabel.Parent = mainFrame

local function setStatus(txt)
    statusLabel.Text = txt
end

-- =====================================================================
--  WIDGETS  (compact 24px rows)
-- =====================================================================
local function makeHeader(parent, yPos, text)
    local h = Instance.new("TextLabel")
    h.Size = UDim2.new(1, -20, 0, 15)
    h.Position = UDim2.new(0, 10, 0, yPos)
    h.BackgroundTransparency = 1
    h.Text = text
    h.TextColor3 = Color3.fromRGB(160, 130, 255)
    h.Font = Enum.Font.GothamBold
    h.TextSize = 9
    h.TextXAlignment = Enum.TextXAlignment.Left
    h.Parent = parent
    return h
end

local function makeToggle(parent, yPos, label, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 24)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    btn.TextColor3 = Color3.fromRGB(220, 220, 230)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.Text = label .. "   OFF"
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = true
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)

    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(60, 60, 78)
    stroke.Thickness = 1

    local pad = Instance.new("UIPadding", btn)
    pad.PaddingLeft = UDim.new(0, 10)

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 7, 0, 7)
    dot.Position = UDim2.new(1, -14, 0.5, -3.5)
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

local function makeActionBtn(parent, yPos, text, bg, fg)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -20, 0, 24)
    b.Position = UDim2.new(0, 10, 0, yPos)
    b.Text = text
    b.BackgroundColor3 = bg
    b.TextColor3 = fg
    b.Font = Enum.Font.GothamBold
    b.TextSize = 10
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
    return b
end

-- draggable value slider (used for Fly Speed) -- compact
local function makeSlider(parent, yPos, label, minV, maxV, initV, color, onSet)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -20, 0, 24)
    row.Position = UDim2.new(0, 10, 0, yPos)
    row.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    row.BorderSizePixel = 0
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

    local stroke = Instance.new("UIStroke", row)
    stroke.Color = Color3.fromRGB(60, 60, 78)
    stroke.Thickness = 1

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 64, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(220, 220, 230)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 9
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0, 30, 1, 0)
    valLbl.Position = UDim2.new(1, -36, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(math.floor(initV))
    valLbl.TextColor3 = color
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 9
    valLbl.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -116, 0, 4)
    track.Position = UDim2.new(0, 78, 0.5, -2)
    track.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    track.BorderSizePixel = 0
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = color
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 10, 0, 10)
    knob.Position = UDim2.new(0, -5, 0.5, -5)
    knob.BackgroundColor3 = Color3.fromRGB(235, 235, 245)
    knob.Text = ""
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local function setValue(v, fire)
        v = math.clamp(v, minV, maxV)
        local rel = (v - minV) / (maxV - minV)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, -5, 0.5, -5)
        valLbl.Text = tostring(math.floor(v + 0.5))
        if fire and onSet then onSet(v) end
    end
    setValue(initV, false)

    local sliding = false
    local function fromX(x)
        local rel = (x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
        rel = math.clamp(rel, 0, 1)
        setValue(minV + (maxV - minV) * rel, true)
    end
    local function beginDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            fromX(input.Position.X)
        end
    end
    knob.InputBegan:Connect(beginDrag)
    track.InputBegan:Connect(beginDrag)

    UserInput.InputChanged:Connect(function(input)
        if sliding
           and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
            fromX(input.Position.X)
        end
    end)
    UserInput.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)

    return setValue
end

-- =====================================================================
--  ESP PAGE
-- =====================================================================
makeHeader(espPage, 2, "ESP CONTROLS")

local pBtn, pDot, pStroke, pColor = makeToggle(espPage, 18,  "Player ESP", Color3.fromRGB(0, 255, 120))
local cBtn, cDot, cStroke, cColor = makeToggle(espPage, 46,  "Chest ESP",  Color3.fromRGB(255, 200, 0))
local rBtn, rDot, rStroke, rColor = makeToggle(espPage, 74,  "Raft ESP",   Color3.fromRGB(60, 140, 255))
local lBtn, lDot, lStroke, lColor = makeToggle(espPage, 102, "Loot ESP",   Color3.fromRGB(170, 110, 60))
local sBtn, sDot, sStroke, sColor = makeToggle(espPage, 130, "Shark ESP",  Color3.fromRGB(255, 50, 50))

local espLegend = Instance.new("TextLabel")
espLegend.Size = UDim2.new(1, -20, 0, 28)
espLegend.Position = UDim2.new(0, 10, 0, 158)
espLegend.BackgroundTransparency = 1
espLegend.Text = "Green = Player   Gold = Raft Chest\nBlue = Raft   Brown = Sea Loot   Red = Shark"
espLegend.TextColor3 = Color3.fromRGB(110, 110, 130)
espLegend.Font = Enum.Font.Gotham
espLegend.TextSize = 8
espLegend.TextXAlignment = Enum.TextXAlignment.Left
espLegend.TextYAlignment = Enum.TextYAlignment.Top
espLegend.TextWrapped = true
espLegend.Parent = espPage

-- =====================================================================
--  MAIN PAGE
-- =====================================================================
makeHeader(mainPage, 2, "AUTO STEAL")

local stealBtn, stealDot, stealStroke, stealColor =
    makeToggle(mainPage, 18, "Auto Steal Raft Chests", Color3.fromRGB(0, 255, 150))

local richestBtn = makeActionBtn(mainPage, 46,
    "Teleport to Richest Chest",
    Color3.fromRGB(55, 45, 15),
    Color3.fromRGB(255, 220, 90))

local returnBtn = makeActionBtn(mainPage, 74,
    "Return to My Raft",
    Color3.fromRGB(30, 42, 60),
    Color3.fromRGB(120, 200, 255))

local rescanBtn = makeActionBtn(mainPage, 102,
    "Scan Raft Chests (F9 log)",
    Color3.fromRGB(40, 40, 55),
    Color3.fromRGB(180, 180, 205))

-- CHEATS --------------------------------------------------------------
makeHeader(mainPage, 130, "CHEATS")

local flyBtn, flyDot, flyStroke, flyColor =
    makeToggle(mainPage, 146, "Fly", Color3.fromRGB(120, 200, 255))

local setFlySpeed = makeSlider(mainPage, 174, "Fly Speed", 20, 300, flySpeed,
    Color3.fromRGB(120, 200, 255),
    function(v) flySpeed = math.floor(v) end)

local godBtn, godDot, godStroke, godColor =
    makeToggle(mainPage, 202, "God Mode", Color3.fromRGB(255, 80, 80))

local ghostBtn, ghostDot, ghostStroke, ghostColor =
    makeToggle(mainPage, 230, "Ghost Mode", Color3.fromRGB(180, 180, 255))

local cheatHint = Instance.new("TextLabel")
cheatHint.Size = UDim2.new(1, -20, 0, 28)
cheatHint.Position = UDim2.new(0, 10, 0, 258)
cheatHint.BackgroundTransparency = 1
cheatHint.Text = "Fly: WASD + Space/Shift. God: no damage at all. Ghost: through walls + jump = stand on air."
cheatHint.TextColor3 = Color3.fromRGB(110, 110, 130)
cheatHint.Font = Enum.Font.Gotham
cheatHint.TextSize = 8
cheatHint.TextXAlignment = Enum.TextXAlignment.Left
cheatHint.TextYAlignment = Enum.TextYAlignment.Top
cheatHint.TextWrapped = true
cheatHint.Parent = mainPage

-- =====================================================================
--  TAB SWITCH
-- =====================================================================
local function setTab(which)
    if which == "main" then
        mainPage.Visible = true
        espPage.Visible = false
        scroll.CanvasSize = UDim2.new(0, 0, 0, MAIN_H)
        mainTab.BackgroundColor3 = Color3.fromRGB(70, 50, 130)
        mainTab.TextColor3 = Color3.fromRGB(240, 235, 255)
        espTab.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
        espTab.TextColor3 = Color3.fromRGB(200, 200, 215)
    else
        mainPage.Visible = false
        espPage.Visible = true
        scroll.CanvasSize = UDim2.new(0, 0, 0, ESP_H)
        espTab.BackgroundColor3 = Color3.fromRGB(70, 50, 130)
        espTab.TextColor3 = Color3.fromRGB(240, 235, 255)
        mainTab.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
        mainTab.TextColor3 = Color3.fromRGB(200, 200, 215)
    end
end

mainTab.MouseButton1Click:Connect(function() setTab("main") end)
espTab.MouseButton1Click:Connect(function() setTab("esp") end)
setTab("main")

-- =====================================================================
--  MINIMIZE (tiny reopen button)
-- =====================================================================
local minimized = false
local reopenBtn
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        mainFrame.Visible = false
        if not reopenBtn then
            reopenBtn = Instance.new("TextButton")
            reopenBtn.Size = UDim2.new(0, 110, 0, 26)
            reopenBtn.Position = UDim2.new(0.5, -55, 0, 10)
            reopenBtn.Text = "AniScript v10"
            reopenBtn.BackgroundColor3 = Color3.fromRGB(24, 20, 40)
            reopenBtn.TextColor3 = Color3.fromRGB(180, 150, 255)
            reopenBtn.Font = Enum.Font.GothamBold
            reopenBtn.TextSize = 11
            reopenBtn.Parent = screenGui
            Instance.new("UICorner", reopenBtn).CornerRadius = UDim.new(0, 8)
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

-- =====================================================================
--  8.  KEYWORDS + MATCHER
-- =====================================================================
local KEYWORDS = {
    chests = {"chest", "stash", "treasure", "crate", "safe", "vault"},
    rafts  = {"raft", "boat", "plot", "platform", "ship"},
    sharks = {"shark", "meg", "predator", "monster", "whale", "orca", "croc", "piranha"},
    -- extended a LOT: sea loot in raft games is usually named after the
    -- resource itself (wood, leaf, vine, rope, scrap, barrel ...)
    loots  = {"loot", "drop", "pickup", "reward", "wood", "plank", "leaf", "leaves",
              "vine", "rope", "scrap", "bolt", "plastic", "barrel", "coin", "gem",
              "seed", "fiber", "cloth", "ore", "metal", "stone", "fish", "bag"},
}

-- names that should NEVER count as sea loot (water fx, sky, lighting)
local NEGATIVE_LOOT = {
    "water", "wave", "ocean", "foam", "splash", "cloud", "sky", "rain",
    "particle", "beam", "sun", "moon", "fog", "mist", "bubble", "ripple", "light",
}

local function nameMatches(name, keywords)
    if not name then return false end
    local l = string.lower(name)
    for _, kw in ipairs(keywords) do
        if string.find(l, kw, 1, true) then return true end
    end
    return false
end

-- =====================================================================
--  9.  CORE HELPERS
-- =====================================================================
local function getChar()
    local c = LocalPlayer.Character
    if not c then return nil, nil end
    return c, c:FindFirstChild("HumanoidRootPart")
end

local function distTo(part)
    if not part or not part:IsA("BasePart") then return math.huge end
    local _, hrp = getChar()
    if not hrp then return math.huge end
    return (hrp.Position - part.Position).Magnitude
end

local function getRootPart(obj)
    if not obj or not obj.Parent then return nil end
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
    end
    return nil
end

-- is this instance part of somebody's character?
local function isPlayerPart(obj)
    local inst = obj
    while inst and inst ~= workspace do
        if Players:GetPlayerFromCharacter(inst) then return true end
        inst = inst.Parent
    end
    return false
end

-- bounding box of a raft / any container (cached per world scan)
local bboxCache = {}

local function getRaftBoundingBox(raft)
    if not raft then return nil end
    if raft:IsA("BasePart") then
        return raft.CFrame, raft.Size
    end
    local c = bboxCache[raft]
    if c then return c.cf, c.size end

    local cf, sz
    if raft:IsA("Model") then
        local ok, a, b = pcall(function() return raft:GetBoundingBox() end)
        if ok and a and b and b.X > 0.5 and b.Y > 0.5 and b.Z > 0.5 then
            cf, sz = a, b
        end
    end
    if not cf then
        -- manual extents from collidable parts (no fake 40-stud box)
        local minV = Vector3.new(math.huge, math.huge, math.huge)
        local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
        local found = false
        for _, d in ipairs(raft:GetDescendants()) do
            if d:IsA("BasePart") and d.CanCollide then
                local p = d.Position
                minV = Vector3.new(math.min(minV.X, p.X), math.min(minV.Y, p.Y), math.min(minV.Z, p.Z))
                maxV = Vector3.new(math.max(maxV.X, p.X), math.max(maxV.Y, p.Y), math.max(maxV.Z, p.Z))
                found = true
            end
        end
        if found then
            cf = CFrame.new((minV + maxV) / 2)
            sz = maxV - minV
        end
    end

    if cf and sz then
        bboxCache[raft] = { cf = cf, size = sz }
        return cf, sz
    end
    return nil
end

local function isInsideRaft(part, raft)
    if not part or not raft then return false end
    local cframe, size = getRaftBoundingBox(raft)
    if not cframe or not size then return false end
    -- tight padding: only +3 horizontal / +8 vertical, so crates that
    -- merely FLOAT NEXT TO a raft are NOT counted as being on it
    local half = size / 2 + Vector3.new(3, 8, 3)
    local localPos = cframe:PointToObjectSpace(part.Position)
    return math.abs(localPos.X) <= half.X
       and math.abs(localPos.Y) <= half.Y
       and math.abs(localPos.Z) <= half.Z
end

-- =====================================================================
--  THE AUTO-STEAL KILLER BUG, FIXED:
--  v8 excluded the WHOLE raft from this raycast whenever the chest was
--  a descendant of the raft, so the ray fell straight through the raft
--  floor into the sea and EVERY parented chest failed the check -> the
--  scan always returned nothing ("scan failed"). Now only the chest
--  itself is excluded, so the ray correctly hits the raft floor below.
-- =====================================================================
local function isOnRaftSurface(part, raft)
    if not part or not raft then return false end
    local origin = part.Position + Vector3.new(0, 1, 0)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local filter = {}
    local char = LocalPlayer.Character
    if char then table.insert(filter, char) end
    -- exclude ONLY the chest itself, never the raft
    table.insert(filter, part)
    local chestModel = part:FindFirstAncestorOfClass("Model")
    if chestModel and chestModel ~= raft then table.insert(filter, chestModel) end
    params.FilterDescendantsInstances = filter
    params.IgnoreWater = false

    local ray = workspace:Raycast(origin, Vector3.new(0, -100, 0), params)
    if not ray or not ray.Instance then return false end
    local hit = ray.Instance
    while hit and hit ~= workspace do
        if hit == raft then return true end
        hit = hit.Parent
    end
    return false
end

-- soft check: real chests usually have a prompt, but not always
local function hasInteraction(model)
    if not model then return false end
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Enabled then return true end
        if d:IsA("ClickDetector") then return true end
    end
    return false
end

-- =====================================================================
--  10.  CREW / OWNER DETECTION  (this is what fixes "return to base
--  doesn't work when I'm in crew")
-- =====================================================================
local CREW_WORDS = {"crew", "team", "party", "gang", "clan", "alliance"}

local function getRaftOwner(raft)
    if not raft then return nil end
    local attrs = {"Owner", "Player", "UserId", "PlotOwner", "OwnerUserId", "CrewOwner", "Captain"}
    local function scanAttrs(inst)
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

    local o = scanAttrs(raft)
    if o then return o end

    -- NEW: plot containers are often named after the owning player
    -- (e.g. workspace.Plots.Bob123.Raft) -> that player is the owner.
    -- In crew mode the crew leader's name is usually the folder name.
    local function nameOwner(name)
        if not name or #name < 3 then return nil end
        local ln = string.lower(name)
        local best
        for _, p in ipairs(Players:GetPlayers()) do
            local pl = string.lower(p.Name)
            if pl == ln then return p end
            if #pl >= 3 and string.find(ln, pl, 1, true) then best = best or p end
        end
        return best
    end

    local no = nameOwner(raft.Name)
    if no then return no end

    local anc = raft.Parent
    while anc and anc ~= workspace do
        local po = nameOwner(anc.Name)
        if po then return po end
        local o2 = scanAttrs(anc)
        if o2 then return o2 end
        anc = anc.Parent
    end
    return nil
end

-- crew name from a player's leaderstats (works in most crew games)
local function getCrewValueOf(player)
    if not player then return nil end
    local ls = player:FindFirstChild("leaderstats")
    if not ls then return nil end
    for _, stat in ipairs(ls:GetChildren()) do
        local n = string.lower(stat.Name)
        local isCrewStat = false
        for _, w in ipairs(CREW_WORDS) do
            if string.find(n, w, 1, true) then isCrewStat = true break end
        end
        if isCrewStat then
            if stat:IsA("StringValue") and stat.Value ~= "" then return stat.Value end
            if stat:IsA("IntValue") or stat:IsA("NumberValue") then
                if stat.Value ~= 0 then return tostring(stat.Value) end
            end
        end
    end
    return nil
end

local function sameCrew(a, b)
    if not a or not b then return false end
    local ca = getCrewValueOf(a)
    local cb = getCrewValueOf(b)
    if ca and cb and ca ~= "" and ca == cb then return true end
    return false
end

-- raft carries a crew attribute that matches mine?
local function raftCrewMatchesMe(raft)
    local myCrew = getCrewValueOf(LocalPlayer)
    if not myCrew or myCrew == "" then return false end
    local inst = raft
    while inst and inst ~= workspace do
        for name, value in pairs(inst:GetAttributes()) do
            local ln = string.lower(name)
            local isCrewAttr = false
            for _, w in ipairs(CREW_WORDS) do
                if string.find(ln, w, 1, true) then isCrewAttr = true break end
            end
            if isCrewAttr and typeof(value) == "string" and value ~= "" and value == myCrew then
                return true
            end
        end
        inst = inst.Parent
    end
    return false
end

-- crew folder containers (ReplicatedStorage.Crews.X / workspace.Teams.X)
local crewGroupCache = { t = 0, grp = nil }
local function getMyCrewGroup()
    if os.clock() - crewGroupCache.t < 3 then return crewGroupCache.grp end
    crewGroupCache.t = os.clock()
    local found = nil
    for _, container in ipairs({ ReplicatedStorage, workspace }) do
        for _, c in ipairs(container:GetChildren()) do
            if (c:IsA("Folder") or c:IsA("Model"))
               and nameMatches(c.Name, CREW_WORDS) then
                if c:FindFirstChild(LocalPlayer.Name) then
                    found = c
                    break
                end
                local members = c:GetAttribute("Members")
                if typeof(members) == "string"
                   and string.find(string.lower(members), string.lower(LocalPlayer.Name), 1, true) then
                    found = c
                    break
                end
            end
        end
        if found then break end
    end
    crewGroupCache.grp = found
    return found
end

-- is this raft mine / my crew's?  (never steal from these)
local function isOwnedByMeOrCrew(raft)
    if not raft then return false end
    local owner = getRaftOwner(raft)
    if owner == LocalPlayer then return true end
    if sameCrew(owner, LocalPlayer) then return true end
    if raftCrewMatchesMe(raft) then return true end
    local grp = getMyCrewGroup()
    if grp then
        if raft:IsDescendantOf(grp) then return true end
        if owner and grp:FindFirstChild(owner.Name) then return true end
    end
    return false
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

-- =====================================================================
--  11.  WORLD SCAN  (one pass, cached 0.5s; feeds ESP + auto steal)
-- =====================================================================
local scanCache = {
    t = 0,
    rafts = {}, chestKW = {}, sharkKW = {}, lootKW = {}, interactive = {},
}

local function scanWorld()
    local rafts, chestKW, sharkKW, lootKW, interactive = {}, {}, {}, {}, {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("BasePart"))
           and not Players:GetPlayerFromCharacter(obj) then
            local n = obj.Name
            if nameMatches(n, KEYWORDS.chests) then
                table.insert(chestKW, obj)
            elseif nameMatches(n, KEYWORDS.sharks) then
                table.insert(sharkKW, obj)
            elseif nameMatches(n, KEYWORDS.rafts) then
                table.insert(rafts, obj)
            elseif nameMatches(n, KEYWORDS.loots) and not nameMatches(n, NEGATIVE_LOOT) then
                table.insert(lootKW, obj)
            else
                -- SMART PICKUP DETECTOR: sea loot is usually an unanchored
                -- model / part with a prompt, click or touch directly in it.
                if obj:IsA("Model") or (obj:IsA("BasePart") and not obj.Anchored) then
                    for _, ch in ipairs(obj:GetChildren()) do
                        if ch:IsA("ProximityPrompt")
                           or ch:IsA("ClickDetector")
                           or ch:IsA("TouchTransmitter") then
                            table.insert(interactive, obj)
                            break
                        end
                    end
                end
            end
        end
    end
    scanCache.rafts = rafts
    scanCache.chestKW = chestKW
    scanCache.sharkKW = sharkKW
    scanCache.lootKW = lootKW
    scanCache.interactive = interactive
    scanCache.t = os.clock()
    bboxCache = {}
    return scanCache
end

local function getWorldScan(force)
    if force or (os.clock() - scanCache.t) > 0.5 then
        scanCache.t = os.clock() -- set first so a failed scan doesn't loop
        local ok, err = pcall(scanWorld)
        if not ok then
            warn("[AniScript] world scan error:", err)
        end
    end
    return scanCache
end

-- =====================================================================
--  12.  CHEST HELPERS
-- =====================================================================
local function chestValue(chest)
    for _, attr in ipairs({"Value", "Amount", "Resources", "Coins", "Gold", "Count", "Stored", "Items"}) do
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

-- soft now: a chest with an interaction prompt counts even when it has
-- no visible content children (that check made v8 reject real chests)
local function chestHasResources(chest)
    for _, attr in ipairs({"Value", "Amount", "Resources", "Coins", "Gold", "Count", "Stored", "Items"}) do
        local v = chest:GetAttribute(attr)
        if typeof(v) == "number" and v > 0 then return true end
    end
    if hasInteraction(chest) then return true end
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

-- =====================================================================
--  13.  RAFT CHEST FINDER  (fixed + with diagnostics)
--  A chest counts ONLY if it is INSIDE a raft AND resting on the raft
--  surface. Sea crates are never inside a raft -> always excluded.
-- =====================================================================
local function getRaftChests(includeMine, fresh)
    local scan = getWorldScan(fresh)
    local rafts = scan.rafts
    local stats = {
        keyword = 0, noRoot = 0, notInRaft = 0, notOnSurface = 0,
        mine = 0, shielded = 0, empty = 0, valid = 0,
    }
    local list = {}
    for _, obj in ipairs(scan.chestKW) do
        if not isPlayerPart(obj) then
            stats.keyword = stats.keyword + 1
            local root = getRootPart(obj)
            if not root then
                stats.noRoot = stats.noRoot + 1
                continue
            end

            -- must be inside a raft bounding box. If several rafts
            -- contain it, pick the TIGHTEST one (a plot container must
            -- never mask the real raft the chest is standing on)
            local raft = nil
            local bestArea = math.huge
            for _, r in ipairs(rafts) do
                if isInsideRaft(root, r) then
                    local _, s = getRaftBoundingBox(r)
                    local area = s and (s.X * s.Z) or math.huge
                    if area < bestArea then
                        bestArea = area
                        raft = r
                    end
                end
            end
            if not raft then
                stats.notInRaft = stats.notInRaft + 1
                continue
            end

            -- must be physically resting on that raft
            if not isOnRaftSurface(root, raft) then
                stats.notOnSurface = stats.notOnSurface + 1
                continue
            end

            local owner = getRaftOwner(raft)

            if includeMine then
                -- ESP mode: show every raft chest (mine included)
                stats.valid = stats.valid + 1
                table.insert(list, {
                    obj = obj, part = root, raft = raft,
                    owner = owner, value = chestValue(obj),
                })
                continue
            end

            -- steal mode: skip my own / my crew's raft
            if isOwnedByMeOrCrew(raft) then
                stats.mine = stats.mine + 1
                continue
            end
            if isRaftShielded(raft) then
                stats.shielded = stats.shielded + 1
                continue
            end
            if not chestHasResources(obj) then
                stats.empty = stats.empty + 1
                continue
            end

            stats.valid = stats.valid + 1
            table.insert(list, {
                obj = obj, part = root, raft = raft,
                owner = owner, value = chestValue(obj),
            })
        end
    end
    return { list = list, stats = stats }
end

-- =====================================================================
--  14.  ESP VISUALS  (persistent -> no flicker, capped under Roblox's
--  31-highlight render limit, plus billboard name + distance tags)
-- =====================================================================
local espState  = { players = false, chests = false, rafts = false, loots = false, sharks = false }
local espVisuals = { players = {}, chests = {}, rafts = {}, loots = {}, sharks = {} }

local ESP_COLORS = {
    players = Color3.fromRGB(0, 255, 120),
    chests  = Color3.fromRGB(255, 200, 0),
    rafts   = Color3.fromRGB(60, 140, 255),
    loots   = Color3.fromRGB(170, 110, 60),
    sharks  = Color3.fromRGB(255, 50, 50),
}

-- Roblox only renders ~31 Highlight instances at once; going over that
-- is why ESP "didn't glow properly" in v8. We budget below it and give
-- everything a billboard tag so nothing is ever invisible.
local MAX_TOTAL_HIGHLIGHTS = 28
local HIGHLIGHT_CAPS = { players = 8, chests = 10, rafts = 6, sharks = 4 }
local TRACK_CAPS      = { players = 30, chests = 40, rafts = 20, sharks = 15, loots = 40 }

local function createHighlight(target, color)
    if not target or not target.Parent then return nil end
    local h = Instance.new("Highlight")
    h.Adornee = target
    h.FillColor = color
    h.FillTransparency = 0.45
    h.OutlineColor = Color3.fromRGB(255, 255, 255)
    h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = target
    return h
end

-- loots use SelectionBox (wireframe box) instead of Highlight so they
-- never eat into the 31-highlight budget
local function createSelBox(target, color)
    if not target or not target.Parent then return nil end
    local ok, sb = pcall(function()
        local s = Instance.new("SelectionBox")
        pcall(function() s.SelectionColor3 = color end)
        pcall(function() s.LineThickness = 0.06 end)
        pcall(function() s.Transparency = 0.15 end)
        s.Adornee = target
        s.Visible = true
        s.Parent = target
        return s
    end)
    if ok then return sb end
    return nil
end

local function createBillboard(rootPart, color, initialText)
    if not rootPart or not rootPart.Parent then return nil, nil end
    local bb = Instance.new("BillboardGui")
    bb.Name = "AniESPTag"
    bb.Adornee = rootPart
    bb.Size = UDim2.new(0, 130, 0, 18)
    bb.StudsOffset = Vector3.new(0, 3.5, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 6000
    bb.Parent = rootPart

    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.Font = Enum.Font.GothamBold
    tl.TextSize = 11
    tl.TextColor3 = color
    tl.TextStrokeTransparency = 0.5
    tl.Text = initialText
    tl.Parent = bb
    return bb, tl
end

local function countHighlights()
    local n = 0
    for _, t in pairs(espVisuals) do
        for _, v in pairs(t) do
            if v.highlight then n = n + 1 end
        end
    end
    return n
end

-- sync a group: keep visuals for objects still in the list, remove the
-- ones that vanished, create for new ones. NO destroy/recreate flicker.
local function syncGroup(group, arr, color, labelFn)
    local store = espVisuals[group]
    local newSet = {}
    for _, obj in ipairs(arr) do newSet[obj] = true end

    for obj, v in pairs(store) do
        if not newSet[obj] or not obj.Parent then
            pcall(function() if v.highlight then v.highlight:Destroy() end end)
            pcall(function() if v.selbox then v.selbox:Destroy() end end)
            pcall(function() if v.bb then v.bb:Destroy() end end)
            store[obj] = nil
        end
    end

    -- nearest first, so the cap always favours what is close to you
    table.sort(arr, function(a, b)
        return distTo(getRootPart(a)) < distTo(getRootPart(b))
    end)

    local idx = 0
    local trackCap = TRACK_CAPS[group] or 30
    for _, obj in ipairs(arr) do
        if not store[obj] and obj.Parent then
            idx = idx + 1
            if idx > trackCap then break end
            local root = getRootPart(obj)
            if root then
                local v = { root = root, label = labelFn(obj) or group }
                local cap = HIGHLIGHT_CAPS[group]
                if group == "loots" then
                    v.selbox = createSelBox(obj, color)
                elseif cap and idx <= cap and countHighlights() < MAX_TOTAL_HIGHLIGHTS then
                    v.highlight = createHighlight(obj, color)
                end
                v.bb, v.tl = createBillboard(root, color, v.label)
                store[obj] = v
            end
        end
    end
end

-- final loot list = keyword matches + floating interactive pickups that
-- are NOT on any raft (chests sit on rafts, sea loot floats on water)
local function buildLootList(scan)
    local rafts = scan.rafts
    local out = {}
    local seen = {}
    local function tryAdd(obj)
        if seen[obj] then return end
        if isPlayerPart(obj) then return end
        if nameMatches(obj.Name, NEGATIVE_LOOT) then return end
        local root = getRootPart(obj)
        if not root then return end
        -- skip giant objects (those are structures, not loot)
        local sz
        if obj:IsA("BasePart") then
            sz = obj.Size
        else
            local _, s = getRaftBoundingBox(obj)
            sz = s
        end
        if sz and math.max(sz.X, sz.Y, sz.Z) > 25 then return end
        seen[obj] = true
        table.insert(out, obj)
    end

    for _, obj in ipairs(scan.lootKW) do tryAdd(obj) end
    for _, obj in ipairs(scan.interactive) do
        if not seen[obj] then
            local root = getRootPart(obj)
            if root then
                local onRaft = false
                for _, r in ipairs(rafts) do
                    if isInsideRaft(root, r) then onRaft = true break end
                end
                if not onRaft then tryAdd(obj) end
            end
        end
    end
    return out
end

local function refreshESP()
    local scan = getWorldScan()

    -- PLAYERS
    local arr = {}
    if espState.players then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                table.insert(arr, p.Character)
            end
        end
    end
    syncGroup("players", arr, ESP_COLORS.players, function(o)
        local pl = Players:GetPlayerFromCharacter(o)
        return pl and pl.Name or "Player"
    end)

    -- CHESTS: raft chests ONLY (this is the fix for sea boxes glowing)
    arr = {}
    local chestLabels = {}
    if espState.chests then
        local res = getRaftChests(true, false)
        for _, c in ipairs(res.list) do
            table.insert(arr, c.obj)
            chestLabels[c.obj] = "Chest" .. (c.owner and (" - " .. c.owner.Name) or "")
        end
    end
    syncGroup("chests", arr, ESP_COLORS.chests, function(o)
        return chestLabels[o] or "Chest"
    end)

    -- RAFTS
    arr = {}
    if espState.rafts then
        for _, r in ipairs(scan.rafts) do table.insert(arr, r) end
    end
    syncGroup("rafts", arr, ESP_COLORS.rafts, function(o)
        local ow = getRaftOwner(o)
        return ow and ("Raft - " .. ow.Name) or "Raft"
    end)

    -- SHARKS
    arr = {}
    if espState.sharks then
        for _, s in ipairs(scan.sharkKW) do table.insert(arr, s) end
    end
    syncGroup("sharks", arr, ESP_COLORS.sharks, function() return "Shark" end)

    -- LOOT (sea pickups)
    arr = {}
    if espState.loots then
        arr = buildLootList(scan)
    end
    syncGroup("loots", arr, ESP_COLORS.loots, function() return "Loot" end)
end

pBtn.MouseButton1Click:Connect(function()
    espState.players = not espState.players
    updateToggle(pBtn, pDot, pStroke, pColor, espState.players, "Player ESP")
    refreshESP()
end)
cBtn.MouseButton1Click:Connect(function()
    espState.chests = not espState.chests
    updateToggle(cBtn, cDot, cStroke, cColor, espState.chests, "Chest ESP")
    refreshESP()
    setStatus(espState.chests
        and "Chest ESP ON - only chests standing ON RAFTS glow (sea boxes are ignored)."
        or "Chest ESP OFF.")
end)
rBtn.MouseButton1Click:Connect(function()
    espState.rafts = not espState.rafts
    updateToggle(rBtn, rDot, rStroke, rColor, espState.rafts, "Raft ESP")
    refreshESP()
end)
lBtn.MouseButton1Click:Connect(function()
    espState.loots = not espState.loots
    updateToggle(lBtn, lDot, lStroke, lColor, espState.loots, "Loot ESP")
    refreshESP()
    setStatus(espState.loots
        and "Loot ESP ON - floating sea pickups detected by name + smart pickup scan."
        or "Loot ESP OFF.")
end)
sBtn.MouseButton1Click:Connect(function()
    espState.sharks = not espState.sharks
    updateToggle(sBtn, sDot, sStroke, sColor, espState.sharks, "Shark ESP")
    refreshESP()
end)

-- live distance text on every billboard tag
task.spawn(function()
    while screenGui.Parent do
        task.wait(0.3)
        local _, hrp = getChar()
        if hrp then
            for _, t in pairs(espVisuals) do
                for obj, v in pairs(t) do
                    if obj.Parent and v.bb and v.bb.Parent and v.root and v.root.Parent then
                        local d = (hrp.Position - v.root.Position).Magnitude
                        v.tl.Text = v.label .. "  " .. tostring(math.floor(d)) .. "m"
                    end
                end
            end
        end
    end
end)

-- =====================================================================
--  15.  FLY / GOD MODE / GHOST MODE  (all rebuilt in v10)
-- =====================================================================

-- ---------------- FLY ----------------
-- v10: CFrame-based. Every physics step we teleport the character by
-- exactly flySpeed * dt in the direction you hold. Nothing (humanoid,
-- game scripts, physics) can block or fight a CFrame write, which is
-- why the v9 velocity-only fly did nothing in some games. Velocity is
-- also zeroed every step, so gravity never drags you down while you
-- fly and you hover perfectly when no key is held.
local flyState = false
local flyCon = nil

local function startFly()
    if flyCon then flyCon:Disconnect() flyCon = nil end
    flyState = true
    flyCon = RunService.Heartbeat:Connect(function(dt)
        if not flyState then return end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local cam = workspace.CurrentCamera
        if not cam then return end

        local move = Vector3.zero
        local look  = cam.CFrame.LookVector
        local right = cam.CFrame.RightVector
        if UserInput:IsKeyDown(Enum.KeyCode.W) then move = move + look end
        if UserInput:IsKeyDown(Enum.KeyCode.S) then move = move - look end
        if UserInput:IsKeyDown(Enum.KeyCode.A) then move = move - right end
        if UserInput:IsKeyDown(Enum.KeyCode.D) then move = move + right end
        if UserInput:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.yAxis end
        if UserInput:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.yAxis end

        if move.Magnitude > 0 then
            move = move.Unit * flySpeed
            pcall(function()
                hrp.CFrame = hrp.CFrame + move * dt
            end)
        end
        pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero end)
    end)
end

local function stopFly()
    flyState = false
    if flyCon then flyCon:Disconnect() flyCon = nil end
end

flyBtn.MouseButton1Click:Connect(function()
    if flyState then
        stopFly()
    else
        startFly()
    end
    updateToggle(flyBtn, flyDot, flyStroke, flyColor, flyState, "Fly")
    setStatus(flyState
        and "Fly ON - WASD to move, Space up, Shift down. Drag the Fly Speed slider."
        or "Fly OFF.")
end)

-- ---------------- GOD MODE ----------------
-- v10: 3 layers stacked, so you NEVER take damage and NEVER die:
--   1) MaxHealth = huge  (normal damage can't add up to death)
--   2) instant re-heal on every Health change (server damage is undone
--      the same frame it arrives)
--   3) the Dead humanoid state is DISABLED, so even a forced
--      Health = 0 / ChangeState(Dead) kill cannot finish you.
-- (If a game deletes the whole character model no client script can
-- save you, but every damage-based death is blocked.)
local godOn = false
local godHealthCon = nil
local godHookedHum = nil
local GOD_HEALTH = math.huge

local function hookGodHumanoid(hum)
    if not hum then return end
    godHookedHum = hum
    pcall(function()
        hum.MaxHealth = GOD_HEALTH
        hum.Health = GOD_HEALTH
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    end)
    if godHealthCon then
        pcall(function() godHealthCon:Disconnect() end)
        godHealthCon = nil
    end
    godHealthCon = hum:GetPropertyChangedSignal("Health"):Connect(function()
        if not godOn then return end
        if hum.Parent and hum.Health < GOD_HEALTH then
            pcall(function() hum.Health = GOD_HEALTH end)
        end
    end)
end

local function applyGod()
    local char = LocalPlayer.Character
    hookGodHumanoid(char and char:FindFirstChildOfClass("Humanoid"))
end

local function removeGod()
    if godHealthCon then
        pcall(function() godHealthCon:Disconnect() end)
        godHealthCon = nil
    end
    godHookedHum = nil
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
            hum.MaxHealth = 100
            hum.Health = math.clamp(hum.Health, 0, 100)
        end)
    end
end

godBtn.MouseButton1Click:Connect(function()
    godOn = not godOn
    if godOn then applyGod() else removeGod() end
    updateToggle(godBtn, godDot, godStroke, godColor, godOn, "God Mode")
    setStatus(godOn
        and "God Mode ON - no damage at all, death itself is blocked."
        or "God Mode OFF.")
end)

-- god keeper: re-hooks after respawn / game resets, keeps health maxed
task.spawn(function()
    while screenGui.Parent do
        task.wait(0.2)
        if godOn then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                if hum ~= godHookedHum then
                    hookGodHumanoid(hum)
                else
                    pcall(function()
                        if hum.MaxHealth ~= GOD_HEALTH then hum.MaxHealth = GOD_HEALTH end
                        if hum.Health < GOD_HEALTH then hum.Health = GOD_HEALTH end
                        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
                    end)
                end
            end
        end
    end
end)

-- ---------------- GHOST MODE ----------------
-- v10 = noclip + air stand, exactly as requested:
--   * pass through walls (collision off, re-applied every physics step)
--   * you STAY standing where you are (falling speed is cancelled, so
--     you never sink through the floor)
--   * JUMP -> you rise and then STAND ON THE AIR at that height, and
--     you can keep walking on air (Freefall state disabled, so the
--     humanoid keeps walking normally while airborne)
local ghostOn = false
local ghostNoclipCon = nil
local ghostHoverCon = nil
local ghostSavedCollide = {}

local function startGhost()
    ghostOn = true
    -- 1) no collision, forever
    ghostNoclipCon = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("BasePart") and d.CanCollide then
                ghostSavedCollide[d] = true
                d.CanCollide = false
            end
        end
    end)
    -- 2) never fall: cancel downward speed -> you hover where you are,
    --    and after a jump you stand on the air at the top of your jump
    ghostHoverCon = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local v = hrp.AssemblyLinearVelocity
        if v.Y < -0.05 then
            pcall(function()
                hrp.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z)
            end)
        end
    end)
    -- 3) no Freefall state -> walk (and jump) while airborne
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end)
    end
end

local function stopGhost()
    ghostOn = false
    if ghostNoclipCon then ghostNoclipCon:Disconnect() ghostNoclipCon = nil end
    if ghostHoverCon then ghostHoverCon:Disconnect() ghostHoverCon = nil end
    for d in pairs(ghostSavedCollide) do
        pcall(function()
            if d.Parent then d.CanCollide = true end
        end)
    end
    ghostSavedCollide = {}
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
    end
end

ghostBtn.MouseButton1Click:Connect(function()
    if ghostOn then
        stopGhost()
    else
        startGhost()
    end
    updateToggle(ghostBtn, ghostDot, ghostStroke, ghostColor, ghostOn, "Ghost Mode")
    setStatus(ghostOn
        and "Ghost Mode ON - walk through walls, jump = stand on air, never fall."
        or "Ghost Mode OFF.")
end)

-- re-apply cheats after respawn (fly needs nothing: it reads the live
-- character every frame)
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.4)
    ghostSavedCollide = {}
    if godOn then
        hookGodHumanoid(char:WaitForChild("Humanoid", 5))
    end
    if ghostOn then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function()
                hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            end)
        end
    end
end)

-- =====================================================================
--  16.  HOME / RETURN TO RAFT  (CREW-AWARE)
--  We remember the raft you are physically standing on while you are
--  idle. Together with owner/crew matching this fixes "return to base
--  doesn't work when I'm in a crew": a crew raft is owned by the crew
--  leader, so v8 never matched it. Now it is found 4 different ways.
-- =====================================================================
local stoodRaft = nil
local homeRaft = nil
local savedCFrame = nil

local function getRaftUnderFeet()
    local _, hrp = getChar()
    if not hrp then return nil end
    local scan = getWorldScan()
    local rafts = scan.rafts
    if #rafts == 0 then return nil end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = rafts
    params.IgnoreWater = true
    local ray = workspace:Raycast(hrp.Position, Vector3.new(0, -25, 0), params)
    if not ray or not ray.Instance then return nil end
    local hit = ray.Instance
    for _, r in ipairs(rafts) do
        if hit == r or hit:IsDescendantOf(r) then return r end
    end
    return nil
end

-- strict: raft I own OR a crewmate's raft (leaderstats / attributes /
-- crew folder). Works in crew mode.
local function findMyRaftStrict()
    local scan = getWorldScan()
    local crewMatch = nil
    for _, raft in ipairs(scan.rafts) do
        if getRaftOwner(raft) == LocalPlayer then
            return raft
        end
        if not crewMatch and isOwnedByMeOrCrew(raft) then
            crewMatch = raft
        end
    end
    return crewMatch
end

local function saveMySpot()
    homeRaft = findMyRaftStrict()
    local _, hrp = getChar()
    if hrp and (homeRaft or stoodRaft) then
        savedCFrame = hrp.CFrame -- only saves while you are on a raft
    end
end

local function tpOntoRaft(raft)
    local _, hrp = getChar()
    if not hrp or not raft or not raft.Parent then return false end
    local root
    if raft:IsA("Model") then
        root = raft.PrimaryPart or raft:FindFirstChildWhichIsA("BasePart")
    elseif raft:IsA("BasePart") then
        root = raft
    end
    local pos = root and root.Position or nil
    if not pos then
        local cf = getRaftBoundingBox(raft)
        if cf then pos = cf.Position end
    end
    if not pos then return false end
    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 6, 0))
    return true
end

-- FIXED: dynamic + crew-aware. Order:
--   1) raft I own  2) cached home raft  3) raft I last stood on
--   4) saved CFrame  5) spawn
local function returnToMySpot()
    local strict = findMyRaftStrict()
    if strict and tpOntoRaft(strict) then return true end
    if homeRaft and homeRaft.Parent and tpOntoRaft(homeRaft) then return true end
    if stoodRaft and stoodRaft.Parent and tpOntoRaft(stoodRaft) then return true end
    local _, hrp = getChar()
    if savedCFrame and hrp then
        hrp.CFrame = savedCFrame
        return true
    end
    local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
    if spawn and hrp then
        hrp.CFrame = CFrame.new(spawn.Position + Vector3.new(0, 5, 0))
        return true
    end
    return false
end

-- =====================================================================
--  17.  AUTO STEAL  (steal -> return -> store -> NEXT RAFT -> repeat forever)
-- =====================================================================
local function tpTo(pos)
    local _, hrp = getChar()
    if hrp then hrp.CFrame = CFrame.new(pos) end
end

-- executor-safe prompt firing
local function firePrompt(d)
    if not d or not d.Parent then return end
    if fireproximityprompt then
        local ok = pcall(fireproximityprompt, d)
        if ok then return end
    end
    pcall(function()
        d:InputHoldBegin()
        local hold = math.min(d.HoldDuration or 0, 1.5)
        task.wait(hold > 0 and (hold + 0.1) or 0.1)
        d:InputHoldEnd()
    end)
end

local function interact(entry)
    local char = LocalPlayer.Character
    if not char then return end
    local _, hrp = getChar()
    if hrp and entry.part and entry.part.Parent then
        hrp.CFrame = CFrame.new(entry.part.Position + Vector3.new(0, 1.5, 0))
    end
    task.wait(0.15)
    if not autoSteal then return end

    -- activate any held tool (some games steal that way)
    for _, t in ipairs(char:GetChildren()) do
        if t:IsA("Tool") then pcall(function() t:Activate() end) end
    end

    -- fire the CHEST's own prompts first
    local fired = 0
    for _, d in ipairs(entry.obj:GetDescendants()) do
        if not autoSteal then return end
        if d:IsA("ProximityPrompt") and d.Enabled then
            firePrompt(d)
            fired = fired + 1
        elseif d:IsA("ClickDetector") then
            pcall(function() fireclickdetector(d) end)
            fired = fired + 1
        end
    end

    -- only if the chest itself had no interaction, try the raft's
    -- (some games put the steal trigger on the raft) -- capped at 10
    -- prompts so one cycle can never hang on hold times
    if entry.raft and fired == 0 then
        for _, d in ipairs(entry.raft:GetDescendants()) do
            if not autoSteal then return end
            if fired >= 10 then break end
            if d:IsA("ProximityPrompt") and d.Enabled then
                firePrompt(d)
                fired = fired + 1
            elseif d:IsA("ClickDetector") then
                pcall(function() fireclickdetector(d) end)
                fired = fired + 1
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

-- store the chest at home by firing prompts on the home raft
local function storeChestAtHome()
    local myRaft = homeRaft
    if not (myRaft and myRaft.Parent) then
        myRaft = findMyRaftStrict()
        if myRaft then homeRaft = myRaft end
    end
    if not myRaft then return end

    local _, hrp = getChar()
    if not hrp then return end

    -- make sure we're standing on the home raft
    if not tpOntoRaft(myRaft) then return end
    task.wait(0.15)
    if not autoSteal then return end

    -- activate held tool (drop / place the chest)
    local char = LocalPlayer.Character
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") then pcall(function() t:Activate() end) end
        end
    end

    -- fire storage / deposit prompts on the home raft (capped so a
    -- cycle can never hang on long prompt hold times)
    local firedHome = 0
    for _, d in ipairs(myRaft:GetDescendants()) do
        if not autoSteal then return end
        if firedHome >= 10 then break end
        if d:IsA("ProximityPrompt") and d.Enabled then
            firePrompt(d)
            firedHome = firedHome + 1
        elseif d:IsA("ClickDetector") then
            pcall(function() fireclickdetector(d) end)
            firedHome = firedHome + 1
        end
    end
end

-- MAIN STEAL LOOP v10: loops FOREVER, and after every steal it moves
-- on to a DIFFERENT raft. Chests you already hit get a 45s cooldown and
-- their raft an 18s cooldown, so the next cycle always teleports to
-- another raft instead of re-visiting the same one. Toggle OFF to stop
-- instantly at any point.
local chestCooldown = {}   -- [chest instance] = expiry os.clock()
local raftCooldown  = {}   -- [raft instance]  = expiry os.clock()
local lastRaft      = nil
local stealCycles   = 0
local CHEST_CD      = 45
local RAFT_CD       = 18

local function cleanCooldowns()
    local now = os.clock()
    for k, t in pairs(chestCooldown) do
        if t < now or not k.Parent then chestCooldown[k] = nil end
    end
    for k, t in pairs(raftCooldown) do
        if t < now or not k.Parent then raftCooldown[k] = nil end
    end
end

task.spawn(function()
    while screenGui.Parent do
        task.wait(0.4)
        if autoSteal and not stealing then
            stealing = true
            local ok, err = pcall(function()
                cleanCooldowns()
                local now = os.clock()

                local res = getRaftChests(false, true)
                local stats, chests = res.stats, res.list

                local avail = {}
                for _, c in ipairs(chests) do
                    if not (chestCooldown[c.obj] and chestCooldown[c.obj] > now) then
                        table.insert(avail, c)
                    end
                end

                if #avail == 0 then
                    if #chests == 0 then
                        setStatus(("Auto Steal: scanning... (chests: %d | on rafts: %d | mine/crew: %d | shielded: %d)")
                            :format(stats.keyword, stats.keyword - stats.notInRaft, stats.mine, stats.shielded))
                    else
                        setStatus("Auto Steal: stolen chests cooling down - moving to the next raft soon...")
                    end
                    return
                end

                -- pick: a NEW raft first (not the last one stolen from,
                -- not on raft cooldown), then the nearest chest
                table.sort(avail, function(a, b)
                    local an = (a.raft == lastRaft) and 1 or 0
                    local bn = (b.raft == lastRaft) and 1 or 0
                    if an ~= bn then return an < bn end
                    local ac = (raftCooldown[a.raft] and raftCooldown[a.raft] > now) and 1 or 0
                    local bc = (raftCooldown[b.raft] and raftCooldown[b.raft] > now) and 1 or 0
                    if ac ~= bc then return ac < bc end
                    return distTo(a.part) < distTo(b.part)
                end)

                local c = avail[1]
                stealCycles = stealCycles + 1

                -- cooldowns are set BEFORE the trip, so even a failed
                -- steal moves the loop on to another raft next cycle
                chestCooldown[c.obj] = now + CHEST_CD
                raftCooldown[c.raft] = now + RAFT_CD
                lastRaft = c.raft

                setStatus(("Cycle %d -> teleporting to %s (owner: %s) | %d chests left")
                    :format(stealCycles, c.obj.Name, c.owner and c.owner.Name or "?", #avail))

                -- STEP 1: teleport to the chest and steal it
                stealChest(c)
                if not autoSteal then return end
                task.wait(0.25)

                -- STEP 2: ALWAYS return home (crew-aware)
                setStatus(("Cycle %d: returning home..."):format(stealCycles))
                returnToMySpot()
                if not autoSteal then return end
                task.wait(0.15)

                -- STEP 3: store the loot at home
                setStatus(("Cycle %d: storing at home..."):format(stealCycles))
                storeChestAtHome()
                if not autoSteal then return end
                task.wait(0.35)

                setStatus(("Cycle %d done - teleporting to the next raft..."):format(stealCycles))
            end)
            if not ok then
                warn("[AniScript] steal error:", err)
                setStatus("Error - see F9. Returning home...")
                pcall(returnToMySpot)
                task.wait(1)
            end
            stealing = false
        end
    end
end)

-- =====================================================================
--  18.  BUTTON HANDLERS
-- =====================================================================
stealBtn.MouseButton1Click:Connect(function()
    autoSteal = not autoSteal
    if autoSteal then
        stealCycles = 0
        lastRaft = nil
        saveMySpot()
        setStatus("Auto Steal ON - steals from raft to raft forever. Toggle OFF to stop instantly.")
    else
        setStatus("Auto Steal OFF - stopped instantly.")
    end
    updateToggle(stealBtn, stealDot, stealStroke, stealColor, autoSteal, "Auto Steal Raft Chests")
end)

returnBtn.MouseButton1Click:Connect(function()
    if returnToMySpot() then
        setStatus("Returned to my raft (crew-aware).")
    else
        setStatus("Could not find home raft - stand on it once, then try again.")
    end
end)

-- Teleport to Richest Chest (fresh scan, best value, tie = closest)
richestBtn.MouseButton1Click:Connect(function()
    local ok, err = pcall(function()
        local res = getRaftChests(false, true)
        if #res.list == 0 then
            setStatus("Richest: no valid raft chests yet - press Scan to see why (F9).")
            return
        end
        table.sort(res.list, function(a, b)
            if a.value ~= b.value then return a.value > b.value end
            return distTo(a.part) < distTo(b.part)
        end)
        local best = res.list[1]
        if best.part and best.part.Parent then
            tpTo(best.part.Position + Vector3.new(0, 3, 0))
            setStatus(("Richest -> %s (value=%d, owner=%s, dist=%.0f)")
                :format(best.obj.Name, best.value,
                        best.owner and best.owner.Name or "?", distTo(best.part)))
        else
            setStatus("Richest: that chest just vanished - try again.")
        end
    end)
    if not ok then
        warn("[AniScript] richest error:", err)
        setStatus("Richest error - see F9.")
    end
end)

-- Scan with FULL diagnostics
rescanBtn.MouseButton1Click:Connect(function()
    local ok, err = pcall(function()
        local res = getRaftChests(false, true)
        local s = res.stats
        print(("=== AniScript v9 CHEST SCAN: %d valid ==="):format(#res.list))
        print(("  chest names: %d | no root: %d | not inside a raft: %d | not resting on raft: %d | mine/crew: %d | shielded: %d | empty: %d")
            :format(s.keyword, s.noRoot, s.notInRaft, s.notOnSurface, s.mine, s.shielded, s.empty))
        for i, c in ipairs(res.list) do
            print(("[%d] %s | raft=%s | owner=%s | value=%d | dist=%.0f"):format(
                i, c.obj.Name, c.raft.Name,
                c.owner and c.owner.Name or "?", c.value, distTo(c.part)))
        end
        local scan = getWorldScan(true)
        print(("=== Rafts found: %d ==="):format(#scan.rafts))
        for _, r in ipairs(scan.rafts) do
            local o = getRaftOwner(r)
            print(("  %s | owner=%s | mine/crew=%s | shielded=%s"):format(
                r.Name, o and o.Name or "?",
                tostring(isOwnedByMeOrCrew(r)), tostring(isRaftShielded(r))))
        end
        setStatus(("Scan: %d valid raft chests. Full report in F9."):format(#res.list))
    end)
    if not ok then
        warn("[AniScript] scan error:", err)
        setStatus("Scan error - see F9.")
    end
end)

-- =====================================================================
--  19.  BACKGROUND LOOPS
-- =====================================================================
-- track which raft we stand on (frozen during a steal trip so enemy
-- rafts never become "home")
task.spawn(function()
    while screenGui.Parent do
        task.wait(0.5)
        if not stealing then
            local r = getRaftUnderFeet()
            if r then stoodRaft = r end
        end
    end
end)

-- keep the saved home spot fresh while idle
task.spawn(function()
    while screenGui.Parent do
        task.wait(1)
        if not autoSteal and not stealing then
            saveMySpot()
        end
    end
end)

-- ESP refresh (visuals persist between refreshes -> no flicker)
task.spawn(function()
    while screenGui.Parent do
        task.wait(2)
        if espState.players or espState.chests or espState.rafts
           or espState.loots or espState.sharks then
            refreshESP()
        end
    end
end)

-- show / hide UI
UserInput.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

-- close: clean everything up
closeBtn.MouseButton1Click:Connect(function()
    autoSteal = false
    stopFly()
    stopGhost()
    removeGod()
    screenGui:Destroy()
end)

-- =====================================================================
--  20.  READY
-- =====================================================================
setStatus("AniScript v10 ready. Small UI: drag by the title bar, scroll inside, RightCtrl = show/hide.")
print("[AniScript v10] loaded. FIXED: compact scrolling UI (no more big menu), auto steal hops")
print("  raft-to-raft FOREVER (chest + raft cooldowns, always a new raft), CFrame fly that cannot")
print("  be blocked, ghost mode = walk through walls + stand on air, god mode blocks death itself.")
