-- =====================================================================
--  AniScript v12  --  PRO EDITION  (full rebuild of v11)
--  Game: raft-style games (Build and Defend Your Raft, etc.)
--
--  FIXED vs v11 (user report):
--   [1] TP TO RICHEST CHEST picked POOR chests:
--       the old scorer fell back to "count child parts", so every chest
--       scored the same and the sort collapsed to "nearest chest".
--       v12 uses a COMPOSITE WEALTH SCORER: chest sign text ($ numbers),
--       chest attributes, NumberValue children, visible item count and -
--       as a fallback - the raft OWNER's leaderstats gold. Two buttons:
--       "TP Richest Chest" and "TP Poorest Chest", full ranking in F9.
--   [2] GOD MODE still took damage:
--       healing back to ~100 HP cannot survive one big hit (shark bite
--       / instakill). God Mode v3 locks MaxHealth & Health to 1,000,000,
--       adds an invisible ForceField (blocks Humanoid:TakeDamage),
--       re-heals on the same frame via HealthChanged, re-asserts every
--       frame (fights server resets) and keeps leaderstats HP maxed.
--   [3] AUTO STEAL "sometimes can't steal":
--       many games run the real steal through a RemoteEvent behind the
--       prompt. v12 LEARNS that remote automatically (hookmetamethod is
--       used when the executor supports it - the first successful steal,
--       manual or automatic, teaches it to the script). Every later
--       steal fires the learned remote directly + prompts as backup.
--       Steal attempts now also stand in 3 different spots, face the
--       chest, zero their velocity, and print a full F9 report when a
--       chest refuses to be stolen.
--   [4] UI TOO LONG:
--       the window is now a FIXED, SMALL 336 x 306 panel. Every tab is
--       a scrolling list (auto-sized canvas) - features stack in compact
--       24px rows and you simply scroll for more.
--
--  KEPT from v11 (all fixed earlier):
--   + Walk on Water (V) / Ghost without floor-clip or levitation
--   + Chest ESP = raft chests ONLY, Sea Box ESP separate (silver)
--   + Shark ESP folder-aware, shield rafts never targeted
--   + Auto Collect Sea Loot, Click TP, speed/jump boost, Anti-AFK,
--     FPS Boost, keybinds (RightCtrl / F / G / V)
--
--  Show / hide UI: RightControl
-- =====================================================================

if not game:IsLoaded() then game.Loaded:Wait() end

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInput         = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting          = game:GetService("Lighting")
local LocalPlayer       = Players.LocalPlayer

-- =====================================================================
--  SHARED FEATURE STATE  (declared early - every section reads these)
-- =====================================================================
local autoSteal   = false
local stealing    = false
local collectOn   = false
local collecting  = false
local flySpeed    = 80
local clickTpOn   = false

local espState = {
    players  = false,
    chests   = false,   -- ONLY chests standing on rafts
    seaboxes = false,   -- floating sea boxes / sea chests
    rafts    = false,
    loots    = false,
    sharks   = false,
}

local defaultWalk      = 16
local defaultJumpPower = 50
local defaultJumpHeight = 7.2

do
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        defaultWalk      = hum.WalkSpeed or 16
        defaultJumpPower = hum.JumpPower or 50
        defaultJumpHeight = hum.JumpHeight or 7.2
    end
end

local UI = {}   -- collected widget handles (filled by the UI section)

-- =====================================================================
--  1.  GUI SHELL  (FIXED SMALL window: 336 x 306 - never grows)
-- =====================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AniScript"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local WIN_W, WIN_H   = 336, 306      -- fixed size: small + compact
local TITLE_H        = 30
local TAB_H          = 26
local STATUS_H       = 40

local THEME = {
    bg       = Color3.fromRGB(16, 16, 23),
    card     = Color3.fromRGB(26, 26, 36),
    stroke   = Color3.fromRGB(56, 56, 72),
    text     = Color3.fromRGB(228, 228, 238),
    textDim  = Color3.fromRGB(140, 140, 158),
    accent   = Color3.fromRGB(139, 92, 246),
    accentSoft = Color3.fromRGB(167, 139, 250),
    good     = Color3.fromRGB(34, 197, 94),
    warn     = Color3.fromRGB(245, 158, 11),
    bad      = Color3.fromRGB(239, 68, 68),
    info     = Color3.fromRGB(56, 189, 248),
    track    = Color3.fromRGB(45, 45, 58),
    knobOff  = Color3.fromRGB(120, 120, 135),
}

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, WIN_W, 0, WIN_H)
mainFrame.Position = UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2)
mainFrame.BackgroundColor3 = THEME.bg
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

local mainGradient = Instance.new("UIGradient", mainFrame)
mainGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(23, 23, 32)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 13, 19)),
}
mainGradient.Rotation = 90

local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = THEME.accent
mainStroke.Thickness = 1.2
mainStroke.Transparency = 0.35

-- title bar ------------------------------------------------------------
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
    ColorSequenceKeypoint.new(0, Color3.fromRGB(52, 34, 92)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(26, 26, 36)),
}
titleGrad.Rotation = 25

local accentBar = Instance.new("Frame")
accentBar.Size = UDim2.new(0, 3, 0, 14)
accentBar.Position = UDim2.new(0, 10, 0.5, -7)
accentBar.BackgroundColor3 = THEME.accentSoft
accentBar.BorderSizePixel = 0
accentBar.Parent = titleBar
Instance.new("UICorner", accentBar).CornerRadius = UDim.new(1, 0)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -120, 1, 0)
title.Position = UDim2.new(0, 20, 0, 0)
title.BackgroundTransparency = 1
title.Text = "AniScript"
title.TextColor3 = Color3.fromRGB(240, 235, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local verBadge = Instance.new("TextLabel")
verBadge.Size = UDim2.new(0, 58, 0, 16)
verBadge.Position = UDim2.new(0, 92, 0.5, -8)
verBadge.BackgroundColor3 = Color3.fromRGB(44, 32, 78)
verBadge.Text = "v12 PRO"
verBadge.TextColor3 = THEME.accentSoft
verBadge.Font = Enum.Font.GothamBold
verBadge.TextSize = 8
verBadge.Parent = titleBar
Instance.new("UICorner", verBadge).CornerRadius = UDim.new(0, 4)

-- drag by title bar ----------------------------------------------------
local dragZone = Instance.new("Frame")
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

-- minimize / close buttons ---------------------------------------------
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

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 20, 0, 20)
closeBtn.Position = UDim2.new(1, -26, 0, 5)
closeBtn.Text = "x"
closeBtn.BackgroundColor3 = Color3.fromRGB(210, 60, 80)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.AutoButtonColor = true
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)


-- =====================================================================
--  2.  WIDGET FACTORIES  (layout-based, compact 24px rows)
--  No manual Y positions anymore: every page is a UIListLayout stack,
--  the window is FIXED SIZE and you scroll for more features.
-- =====================================================================
local pageSeq = setmetatable({}, { __mode = "k" })
local function nextOrder(parent)
    local n = (pageSeq[parent] or 0) + 1
    pageSeq[parent] = n
    return n
end

local function makeHeader(parent, text)
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1, 0, 0, 14)
    wrap.BackgroundTransparency = 1
    wrap.LayoutOrder = nextOrder(parent)
    wrap.Parent = parent

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 0, 9)
    bar.Position = UDim2.new(0, 2, 0.5, -4)
    bar.BackgroundColor3 = THEME.accent
    bar.BorderSizePixel = 0
    bar.Parent = wrap
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local h = Instance.new("TextLabel")
    h.Size = UDim2.new(1, -12, 1, 0)
    h.Position = UDim2.new(0, 10, 0, 0)
    h.BackgroundTransparency = 1
    h.Text = text
    h.TextColor3 = THEME.accentSoft
    h.Font = Enum.Font.GothamBold
    h.TextSize = 9
    h.TextXAlignment = Enum.TextXAlignment.Left
    h.TextYAlignment = Enum.TextYAlignment.Center
    h.Parent = wrap
    return h
end

local function makeToggle(parent, label, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 24)
    btn.LayoutOrder = nextOrder(parent)
    btn.BackgroundColor3 = THEME.card
    btn.Text = ""
    btn.AutoButtonColor = true
    btn.BorderSizePixel = 0
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = THEME.stroke
    stroke.Thickness = 1

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -58, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 10
    lbl.TextColor3 = THEME.text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = btn

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 24, 0, 13)
    track.Position = UDim2.new(1, -31, 0.5, -6)
    track.BackgroundColor3 = THEME.track
    track.BorderSizePixel = 0
    track.Parent = btn
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 9, 0, 9)
    knob.Position = UDim2.new(0, 2, 0.5, -4)
    knob.BackgroundColor3 = THEME.knobOff
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local api = { on = false, btn = btn }

    function api.set(v)
        api.on = v and true or false
        local ti = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(knob, ti, {
            Position = api.on and UDim2.new(1, -11, 0.5, -4) or UDim2.new(0, 2, 0.5, -4),
            BackgroundColor3 = api.on and color or THEME.knobOff,
        }):Play()
        TweenService:Create(track, ti, {
            BackgroundColor3 = api.on
                and Color3.new(color.R * 0.35 + 0.08, color.G * 0.35 + 0.08, color.B * 0.35 + 0.08)
                or THEME.track,
        }):Play()
        TweenService:Create(stroke, ti, {
            Color = api.on and color or THEME.stroke,
            Transparency = api.on and 0.25 or 0,
        }):Play()
        TweenService:Create(lbl, ti, {
            TextColor3 = api.on and color or THEME.text,
        }):Play()
    end

    api.set(false)
    return api
end

local function makeSlider(parent, label, minV, maxV, initV, color)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.LayoutOrder = nextOrder(parent)
    row.BackgroundColor3 = THEME.card
    row.BorderSizePixel = 0
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", row)
    stroke.Color = THEME.stroke
    stroke.Thickness = 1

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 70, 0, 14)
    lbl.Position = UDim2.new(0, 10, 0, 1)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 9
    lbl.TextColor3 = THEME.text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0, 40, 0, 14)
    valLbl.Position = UDim2.new(1, -46, 0, 1)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(math.floor(initV + 0.5))
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 9
    valLbl.TextColor3 = color
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -126, 0, 4)
    track.Position = UDim2.new(0, 82, 0, 20)
    track.BackgroundColor3 = THEME.track
    track.BorderSizePixel = 0
    track.Active = true
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = color
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 10, 0, 10)
    knob.Position = UDim2.new(0, -5, 0.5, -5)
    knob.BackgroundColor3 = Color3.fromRGB(235, 235, 245)
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local api = { value = initV, onChange = nil }

    local function render(v)
        local rel = (v - minV) / (maxV - minV)
        local ti = TweenInfo.new(0.08, Enum.EasingStyle.Linear)
        TweenService:Create(fill, ti, { Size = UDim2.new(rel, 0, 1, 0) }):Play()
        TweenService:Create(knob, ti, { Position = UDim2.new(rel, -5, 0.5, -5) }):Play()
        valLbl.Text = tostring(math.floor(v + 0.5))
    end

    function api.set(v, fire)
        v = math.clamp(v, minV, maxV)
        api.value = v
        render(v)
        if fire and api.onChange then api.onChange(v) end
    end

    api.set(initV, false)

    local sliding = false
    local function fromX(x)
        local rel = (x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
        rel = math.clamp(rel, 0, 1)
        api.set(minV + (maxV - minV) * rel, true)
    end
    local function beginDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            fromX(input.Position.X)
        end
    end
    track.InputBegan:Connect(beginDrag)
    knob.InputBegan:Connect(beginDrag)
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

    return api
end

local function makeButton(parent, text, bg, fg)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 24)
    b.LayoutOrder = nextOrder(parent)
    b.Text = text
    b.BackgroundColor3 = bg
    b.TextColor3 = fg
    b.Font = Enum.Font.GothamBold
    b.TextSize = 10
    b.AutoButtonColor = true
    b.BorderSizePixel = 0
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    local s = Instance.new("UIStroke", b)
    s.Color = Color3.new(fg.R * 0.4, fg.G * 0.4, fg.B * 0.4)
    s.Thickness = 1
    s.Transparency = 0.4
    return b
end

local function makeHint(parent, text)
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -4, 0, 0)
    t.AutomaticSize = Enum.AutomaticSize.Y
    t.LayoutOrder = nextOrder(parent)
    t.BackgroundTransparency = 1
    t.Text = text
    t.TextColor3 = THEME.textDim
    t.Font = Enum.Font.Gotham
    t.TextSize = 8
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.TextYAlignment = Enum.TextYAlignment.Top
    t.TextWrapped = true
    t.Parent = parent
    return t
end

-- =====================================================================
--  3.  SCROLL AREA + TAB ROW + PAGES  (the "fixed size, scroll more"
--      rebuild: pages auto-size vertically, canvas grows with content)
-- =====================================================================
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -8, 1, -(TITLE_H + TAB_H + STATUS_H + 8))
scroll.Position = UDim2.new(0, 4, 0, TITLE_H + TAB_H + 2)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = THEME.accent
scroll.ScrollingDirection = Enum.ScrollingDirection.Y
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
scroll.Parent = mainFrame

local function newPage()
    local p = Instance.new("Frame")
    p.Size = UDim2.new(1, -6, 0, 0)
    p.AutomaticSize = Enum.AutomaticSize.Y
    p.BackgroundTransparency = 1
    p.Visible = false
    p.Parent = scroll

    local lay = Instance.new("UIListLayout", p)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Padding = UDim.new(0, 4)

    local pad = Instance.new("UIPadding", p)
    pad.PaddingLeft = UDim.new(0, 6)
    pad.PaddingRight = UDim.new(0, 6)
    pad.PaddingTop = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 4)
    return p
end

local mainPage = newPage()
mainPage.Visible = true
local movePage = newPage()
local espPage  = newPage()
local miscPage = newPage()
local pages = { mainPage, movePage, espPage, miscPage }

-- tab row with sliding pill -------------------------------------------
local tabRow = Instance.new("Frame")
tabRow.Size = UDim2.new(1, -8, 0, TAB_H)
tabRow.Position = UDim2.new(0, 4, 0, TITLE_H + 2)
tabRow.BackgroundTransparency = 1
tabRow.Parent = mainFrame

local pill = Instance.new("Frame")
pill.Size = UDim2.new(0.25, -6, 0, 22)
pill.Position = UDim2.new(0, 3, 0, 2)
pill.BackgroundColor3 = Color3.fromRGB(48, 36, 84)
pill.BorderSizePixel = 0
pill.ZIndex = 1
pill.Parent = tabRow
Instance.new("UICorner", pill).CornerRadius = UDim.new(0, 6)
local pillStroke = Instance.new("UIStroke", pill)
pillStroke.Color = THEME.accent
pillStroke.Thickness = 1
pillStroke.Transparency = 0.5

local TAB_NAMES = { "MAIN", "MOVE", "ESP", "MISC" }
local tabBtns = {}
for i = 1, 4 do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.25, -6, 0, 22)
    b.Position = UDim2.new((i - 1) * 0.25, 3, 0, 2)
    b.BackgroundTransparency = 1
    b.Text = TAB_NAMES[i]
    b.Font = Enum.Font.GothamBold
    b.TextSize = 9
    b.TextColor3 = THEME.textDim
    b.ZIndex = 2
    b.Parent = tabRow
    tabBtns[i] = b
end

local currentTab = 1
local function setTab(i)
    currentTab = i
    for j = 1, 4 do
        pages[j].Visible = (j == i)
        tabBtns[j].TextColor3 = (j == i) and THEME.text or THEME.textDim
    end
    scroll.CanvasPosition = Vector2.new(0, 0)
    TweenService:Create(pill,
        TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Position = UDim2.new((i - 1) * 0.25, 3, 0, 2) }):Play()
    local p = pages[i]
    p.Position = UDim2.new(0, 6, 0, 0)
    TweenService:Create(p,
        TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Position = UDim2.new(0, 0, 0, 0) }):Play()
end

for i = 1, 4 do
    tabBtns[i].MouseButton1Click:Connect(function() setTab(i) end)
end
setTab(1)

-- =====================================================================
--  4.  STATUS BAR  (compact, 2-3 lines)
-- =====================================================================
local statusBar = Instance.new("Frame")
statusBar.Size = UDim2.new(1, 0, 0, STATUS_H)
statusBar.Position = UDim2.new(0, 0, 1, -STATUS_H)
statusBar.BackgroundColor3 = Color3.fromRGB(21, 21, 29)
statusBar.BorderSizePixel = 0
statusBar.Parent = mainFrame
Instance.new("UICorner", statusBar).CornerRadius = UDim.new(0, 10)

local sbFix = Instance.new("Frame")
sbFix.Size = UDim2.new(1, 0, 0, 10)
sbFix.Position = UDim2.new(0, 0, 0, 0)
sbFix.BackgroundColor3 = Color3.fromRGB(21, 21, 29)
sbFix.BorderSizePixel = 0
sbFix.Parent = statusBar

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 6, 0, 6)
statusDot.Position = UDim2.new(0, 10, 0, 8)
statusDot.BackgroundColor3 = THEME.good
statusDot.BorderSizePixel = 0
statusDot.Parent = statusBar
Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -24, 1, -12)
statusLabel.Position = UDim2.new(0, 22, 0, 4)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Ready."
statusLabel.TextColor3 = THEME.textDim
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 9
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.TextWrapped = true
statusLabel.Parent = statusBar

local STATUS_COLORS = {
    ok   = THEME.good,
    warn = THEME.warn,
    err  = THEME.bad,
    info = THEME.info,
}

local function setStatus(text, kind)
    statusLabel.Text = text or ""
    statusDot.BackgroundColor3 = STATUS_COLORS[kind or "info"] or THEME.info
end

-- =====================================================================
--  5.  MINIMIZE + OPEN ANIMATION
-- =====================================================================
local minimized = false
local reopenBtn = nil
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        mainFrame.Visible = false
        if not reopenBtn then
            reopenBtn = Instance.new("TextButton")
            reopenBtn.Size = UDim2.new(0, 120, 0, 26)
            reopenBtn.Position = UDim2.new(0.5, -60, 0, 10)
            reopenBtn.Text = "AniScript v12"
            reopenBtn.BackgroundColor3 = Color3.fromRGB(24, 20, 40)
            reopenBtn.TextColor3 = THEME.accentSoft
            reopenBtn.Font = Enum.Font.GothamBold
            reopenBtn.TextSize = 11
            reopenBtn.AutoButtonColor = true
            reopenBtn.Parent = screenGui
            Instance.new("UICorner", reopenBtn).CornerRadius = UDim.new(0, 8)
            local s = Instance.new("UIStroke", reopenBtn)
            s.Color = THEME.accent
            s.Transparency = 0.35
            reopenBtn.MouseButton1Click:Connect(function()
                mainFrame.Visible = true
                reopenBtn:Destroy()
                reopenBtn = nil
                minimized = false
            end)
        end
    end
end)

do
    local uiScale = Instance.new("UIScale", mainFrame)
    uiScale.Scale = 0.92
    TweenService:Create(uiScale,
        TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Scale = 1 }):Play()
end


-- =====================================================================
--  6.  PAGE CONTENTS  (widgets only - handlers are wired at the end)
--  Compact fixed window: rows stack automatically, scroll for more.
-- =====================================================================

-- ---------------- MAIN PAGE ----------------
makeHeader(mainPage, "STEAL & FARM")

UI.steal = makeToggle(mainPage, "Auto Steal Raft Chests", Color3.fromRGB(0, 255, 150))
UI.collect = makeToggle(mainPage, "Auto Collect Sea Loot", Color3.fromRGB(255, 170, 60))

UI.richest = makeButton(mainPage,
    "TP  ·  Richest Chest",
    Color3.fromRGB(55, 45, 15),
    Color3.fromRGB(255, 220, 90))

UI.poorest = makeButton(mainPage,
    "TP  ·  Poorest Chest",
    Color3.fromRGB(28, 40, 58),
    Color3.fromRGB(120, 200, 255))

UI.stealNow = makeButton(mainPage,
    "Steal Nearest Chest  (NOW)",
    Color3.fromRGB(62, 18, 26),
    Color3.fromRGB(255, 120, 130))

UI.returnB = makeButton(mainPage,
    "Return to My Raft",
    Color3.fromRGB(28, 40, 58),
    Color3.fromRGB(120, 200, 255))

UI.rescan = makeButton(mainPage,
    "Scan World  (F9 Report)",
    Color3.fromRGB(38, 38, 52),
    Color3.fromRGB(180, 180, 205))

makeHeader(mainPage, "CHEATS")

UI.god = makeToggle(mainPage, "God Mode", Color3.fromRGB(255, 80, 80))
UI.ghost = makeToggle(mainPage, "Ghost Mode", Color3.fromRGB(180, 180, 255))
UI.water = makeToggle(mainPage, "Walk on Water", Color3.fromRGB(56, 189, 248))
UI.fly = makeToggle(mainPage, "Fly", Color3.fromRGB(120, 200, 255))

UI.flySpeed = makeSlider(mainPage, "Fly Speed", 20, 300, flySpeed,
    Color3.fromRGB(120, 200, 255))

makeHint(mainPage,
    "Ghost: through walls only - floors hold you, no floating.\n" ..
    "God: 1M HP + forcefield - no hit can kill or even scratch you.\n" ..
    "Water: step off your raft and walk across the sea (V).\n" ..
    "TP Rich/Poor: full chest ranking printed in F9.")

-- ---------------- MOVE PAGE ----------------
makeHeader(movePage, "MOVEMENT")

UI.walkSpeed = makeSlider(movePage, "Walk Speed", 16, 200, defaultWalk,
    Color3.fromRGB(34, 197, 94))

UI.jumpPower = makeSlider(movePage, "Jump Power", 20, 300, defaultJumpPower,
    Color3.fromRGB(245, 158, 11))

UI.resetMove = makeButton(movePage,
    "Reset Movement to Game Default",
    Color3.fromRGB(38, 38, 52),
    Color3.fromRGB(180, 180, 205))

UI.clickTp = makeToggle(movePage, "Click TP (Ctrl + Click)", Color3.fromRGB(56, 189, 248))

makeHeader(movePage, "KEYBINDS")

makeHint(movePage,
    "RightCtrl  -  show / hide UI\n" ..
    "F  -  Fly        G  -  Ghost        V  -  Walk on Water\n" ..
    "Ctrl + Click  -  teleport to cursor (when Click TP is ON)")

-- ---------------- ESP PAGE ----------------
makeHeader(espPage, "ESP")

UI.espPlayers = makeToggle(espPage, "Player ESP", Color3.fromRGB(0, 255, 120))
UI.espChests = makeToggle(espPage, "Raft Chest ESP", Color3.fromRGB(255, 200, 0))
UI.espSeaboxes = makeToggle(espPage, "Sea Box ESP", Color3.fromRGB(200, 205, 215))
UI.espRafts = makeToggle(espPage, "Raft ESP", Color3.fromRGB(60, 140, 255))
UI.espLoots = makeToggle(espPage, "Loot ESP", Color3.fromRGB(170, 110, 60))
UI.espSharks = makeToggle(espPage, "Shark ESP", Color3.fromRGB(255, 50, 50))

makeHint(espPage,
    "Gold = Raft Chest with its wealth ($x) + owner\n" ..
    "Silver = Sea Box (floating on sea, never counted as chest)\n" ..
    "Blue = Raft ([SHIELD] = protected, skipped by steal/TP)\n" ..
    "Brown = Sea Loot   Red = Shark   Green = Player\n" ..
    "Every tag shows live distance in studs.")

-- ---------------- MISC PAGE ----------------
makeHeader(miscPage, "UTILITY")

UI.antiAfk = makeToggle(miscPage, "Anti-AFK (never get kicked)", Color3.fromRGB(34, 197, 94))
UI.fps = makeToggle(miscPage, "FPS Boost", Color3.fromRGB(56, 189, 248))

makeHeader(miscPage, "INFO")

makeHint(miscPage,
    "AniScript v12 PRO - fixed window, scroll for more.\n" ..
    "Steal learning: the first successful steal teaches the script\n" ..
    "the game's steal remote -> every later steal is guaranteed.\n" ..
    "Close (x) cleans every feature up safely.")


-- =====================================================================
--  7.  KEYWORDS + MATCHER
-- =====================================================================
local KEYWORDS = {
    chests = { "chest", "stash", "treasure", "crate", "safe", "vault" },
    rafts  = { "raft", "boat", "plot", "platform", "ship" },
    sharks = { "shark", "meg", "predator", "monster", "whale", "orca",
               "croc", "piranha", "beast", "jaws" },
    loots  = { "loot", "drop", "pickup", "reward", "wood", "plank", "leaf",
               "leaves", "vine", "rope", "scrap", "bolt", "plastic", "barrel",
               "coin", "gem", "seed", "fiber", "cloth", "ore", "metal",
               "stone", "fish", "bag", "box" },
}

local NEGATIVE_LOOT = {
    "water", "wave", "ocean", "foam", "splash", "cloud", "sky", "rain",
    "particle", "beam", "sun", "moon", "fog", "mist", "bubble", "ripple", "light",
}

local SHARK_CONTAINERS = { "sharks", "enemies", "monsters", "predators",
                           "hostiles", "mobs", "bosses", "threats" }

local WATER_NAMES = { "water", "ocean", "sea", "lake", "river" }

local EMPTY_MARKERS = { "empty", "opened", "stolen", "looted" }

local function nameMatches(name, keywords)
    if not name then return false end
    local l = string.lower(name)
    for _, kw in ipairs(keywords) do
        if string.find(l, kw, 1, true) then return true end
    end
    return false
end

local function isWaterInstance(inst)
    if not inst then return false end
    if inst:IsA("Terrain") then return false end
    return nameMatches(inst.Name, WATER_NAMES)
end

-- =====================================================================
--  8.  CORE HELPERS
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

local function isPlayerPart(obj)
    local inst = obj
    while inst and inst ~= workspace do
        if Players:GetPlayerFromCharacter(inst) then return true end
        inst = inst.Parent
    end
    return false
end

-- =====================================================================
--  9.  RAFT GEOMETRY  (bounding box + inside + surface checks)
-- =====================================================================
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

-- tight padding (+3 horizontal / +5 vertical): floating sea boxes next
-- to a raft are NOT counted as being on it
local function isInsideRaft(part, raft)
    if not part or not raft then return false end
    local cframe, size = getRaftBoundingBox(raft)
    if not cframe or not size then return false end
    local half = size / 2 + Vector3.new(3, 5, 3)
    local localPos = cframe:PointToObjectSpace(part.Position)
    return math.abs(localPos.X) <= half.X
       and math.abs(localPos.Y) <= half.Y
       and math.abs(localPos.Z) <= half.Z
end

-- A chest counts as "resting on the raft" when the ray straight down
-- from it hits the raft itself, or hits small furniture that stands on
-- the raft (tables / shelves), but NEVER water or giant sea parts.
local function isOnRaftSurface(part, raft)
    if not part or not raft then return false end
    local origin = part.Position + Vector3.new(0, 1, 0)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local filter = {}
    local char = LocalPlayer.Character
    if char then table.insert(filter, char) end
    table.insert(filter, part)
    local chestModel = part:FindFirstAncestorOfClass("Model")
    if chestModel and chestModel ~= raft then table.insert(filter, chestModel) end
    params.FilterDescendantsInstances = filter
    params.IgnoreWater = false

    local ray = workspace:Raycast(origin, Vector3.new(0, -120, 0), params)
    if not ray or not ray.Instance then return false end

    -- direct hit on the raft (or any of its descendants)?
    local hit = ray.Instance
    local inst = hit
    while inst and inst ~= workspace do
        if inst == raft then return true end
        inst = inst.Parent
    end

    -- water / sea parts never count as raft surface
    if hit:IsA("Terrain") and ray.Material == Enum.Material.Water then return false end
    if isWaterInstance(hit) then return false end

    -- furniture fallback: small solid thing inside the raft box
    if hit:IsA("BasePart")
       and hit.Size.X < 60 and hit.Size.Z < 60
       and isInsideRaft(hit, raft) then
        return true
    end
    return false
end

-- =====================================================================
--  10.  CHEST QUALITY + WEALTH SCORING v12
--  THE "TP TO RICHEST WENT TO A POOR CHEST" FIX:
--  v11 fell back to "count the child parts" -> every chest scored 1-2
--  -> the sort collapsed to nearest-chest. v12 builds a COMPOSITE
--  score from every signal a raft game actually uses:
--    a) chest attributes (Value / Coins / Gold / Amount ...)
--    b) NumberValue / IntValue children
--    c) the "$ number" text on chest signs / billboards
--    d) visible item count (weighted, last resort)
--    e) fallback: the raft OWNER's leaderstats wealth (gold/coins...)
--  and the score is shown on the chest ESP tag + F9 ranking so you
--  can always verify what "richest" means.
-- =====================================================================
local function hasInteraction(model)
    if not model then return false end
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Enabled then return true end
        if d:IsA("ClickDetector") then return true end
    end
    return false
end

local function chestLooksEmpty(chest)
    if not chest then return true end
    local n = string.lower(chest.Name)
    for _, m in ipairs(EMPTY_MARKERS) do
        if string.find(n, m, 1, true) then return true end
    end
    for _, attr in ipairs({ "Empty", "Opened", "Looted", "Stolen" }) do
        if chest:GetAttribute(attr) == true then return true end
    end
    return false
end

local VALUE_ATTRS = { "Value", "Amount", "Resources", "Coins", "Gold", "Count",
                      "Stored", "Items", "Money", "Cash", "Score", "Wealth" }

local WEALTH_STAT_WORDS = { "gold", "coin", "money", "cash", "value", "score",
                            "wealth", "trophy", "point", "resource", "gem", "gem" }

-- "$1,234" / "1.2k" / "3M coins" -> 1234 / 1200 / 3000000
local function parseMoneyText(s)
    if type(s) ~= "string" then return nil end
    local t = string.gsub(s, "[,:%$%s]", "")
    local num, suf = string.match(t, "(%d+%.?%d*)[kKmMbB]?")
    -- find suffix explicitly next to the number
    local num2, suf2 = string.match(t, "(%d+%.?%d-)%s*([kKmMbB])")
    if num2 then num, suf = num2, suf2 end
    if not num then return nil end
    local v = tonumber(num)
    if not v then return nil end
    if suf == "k" or suf == "K" then v = v * 1e3
    elseif suf == "m" or suf == "M" then v = v * 1e6
    elseif suf == "b" or suf == "B" then v = v * 1e9
    end
    return v
end

-- games put "$1234" signs (BillboardGui / SurfaceGui TextLabels) on the
-- chest or the raft next to it - that is usually the REAL loot value
local function readChestSignMoney(chest)
    local best = nil
    local function scanGui(gui)
        for _, d in ipairs(gui:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") then
                local n = parseMoneyText(d.Text or "")
                if n and (not best or n > best) then best = n end
            end
        end
    end
    for _, d in ipairs(chest:GetDescendants()) do
        if d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
            scanGui(d)
        end
    end
    return best
end

local function formatMoney(v)
    if v >= 1e6 then return string.format("$%.1fM", v / 1e6) end
    if v >= 1e3 then return string.format("$%.1fK", v / 1e3) end
    return "$" .. tostring(math.floor(v + 0.5))
end

-- richest-player signal: sum of the owner's leaderstats wealth
local function playerWealth(p)
    if not p then return 0 end
    local ls = p:FindFirstChild("leaderstats")
    if not ls then return 0 end
    local total = 0
    for _, st in ipairs(ls:GetChildren()) do
        if st:IsA("IntValue") or st:IsA("NumberValue") then
            local n = string.lower(st.Name)
            for _, w in ipairs(WEALTH_STAT_WORDS) do
                if string.find(n, w, 1, true) then
                    total = total + (st.Value or 0)
                    break
                end
            end
        end
    end
    return total
end

-- returns score, displayText
local function chestWealth(chest, owner)
    if not chest then return 0, "~" end

    -- a) attributes
    local attrSum = 0
    for _, attr in ipairs(VALUE_ATTRS) do
        local v = chest:GetAttribute(attr)
        if typeof(v) == "number" then attrSum = attrSum + v end
    end

    -- b) value children
    local valSum = 0
    for _, d in ipairs(chest:GetChildren()) do
        if d:IsA("NumberValue") or d:IsA("IntValue") then
            valSum = valSum + (d.Value or 0)
        end
    end

    -- c) sign text
    local sign = readChestSignMoney(chest)

    -- d) visible item count (weak - weighted x10)
    local items = 0
    for _, d in ipairs(chest:GetChildren()) do
        if d:IsA("BasePart") then
            local lower = string.lower(d.Name)
            if not string.find(lower, "decal", 1, true)
               and not string.find(lower, "handle", 1, true)
               and not string.find(lower, "icon", 1, true)
               and not string.find(lower, "highlight", 1, true) then
                items = items + 1
            end
        elseif d:IsA("Model") or d:IsA("Folder") then
            items = items + 1
        end
    end

    local primary = math.max(attrSum, valSum, sign or 0, items * 10)
    if primary > 0 then
        return primary, formatMoney(primary)
    end

    -- e) fallback: the owner's leaderstats wealth
    local ow = playerWealth(owner)
    if ow > 0 then
        return ow, formatMoney(ow) .. " (owner)"
    end
    return 0, "~"
end


-- =====================================================================
--  11.  CREW / OWNER DETECTION  (crew-aware home + never steal own raft)
-- =====================================================================
local CREW_WORDS = { "crew", "team", "party", "gang", "clan", "alliance" }

local ownerCache = {}

local function getRaftOwner(raft)
    if not raft then return nil end
    local c = ownerCache[raft]
    if c then return c.owner end

    local attrs = { "Owner", "Player", "UserId", "PlotOwner", "OwnerUserId",
                    "CrewOwner", "Captain" }
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

    local owner = scanAttrs(raft)

    if not owner then
        -- plot containers are often named after the owning player
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

        owner = nameOwner(raft.Name)

        if not owner then
            local anc = raft.Parent
            while anc and anc ~= workspace do
                local po = nameOwner(anc.Name)
                if po then owner = po break end
                local o2 = scanAttrs(anc)
                if o2 then owner = o2 break end
                anc = anc.Parent
            end
        end
    end

    ownerCache[raft] = { owner = owner }
    return owner
end

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

-- =====================================================================
--  12.  SHIELD DETECTION v2  (never TP / steal from shielded rafts)
-- =====================================================================
local SHIELD_WORDS = { "shield", "protected", "barrier", "bubble", "forcefield" }
local shieldCache = {}

local function isRaftShielded(raft)
    if not raft then return false end
    local c = shieldCache[raft]
    if c then return c.shielded end

    local shielded = false

    local function attrScan(inst)
        for name, value in pairs(inst:GetAttributes()) do
            local ln = string.lower(name)
            for _, w in ipairs(SHIELD_WORDS) do
                if string.find(ln, w, 1, true) then
                    if value == true or value == "true" or value == "yes"
                       or (typeof(value) == "number" and value > 0) then
                        return true
                    end
                end
            end
        end
        return false
    end

    if attrScan(raft) then
        shielded = true
    else
        local anc = raft.Parent
        while anc and anc ~= workspace do
            if attrScan(anc) then shielded = true break end
            anc = anc.Parent
        end
    end

    if not shielded and nameMatches(raft.Name, SHIELD_WORDS) then
        shielded = true
    end
    if not shielded then
        local anc = raft.Parent
        while anc and anc ~= workspace do
            if nameMatches(anc.Name, SHIELD_WORDS) then
                shielded = true
                break
            end
            anc = anc.Parent
        end
    end

    if not shielded then
        for _, d in ipairs(raft:GetDescendants()) do
            if d:IsA("ForceField") then
                shielded = true
                break
            end
            if (d:IsA("BasePart") or d:IsA("Model") or d:IsA("Folder"))
               and nameMatches(d.Name, SHIELD_WORDS) then
                shielded = true
                break
            end
        end
    end

    shieldCache[raft] = { shielded = shielded }
    return shielded
end

-- =====================================================================
--  13.  WORLD SCAN  (one pass, cached 0.75s, feeds ESP + steal + collect)
-- =====================================================================
local scanCache = {
    t = 0,
    rafts = {}, chestKW = {}, sharkKW = {}, lootKW = {}, interactive = {},
}

-- sharks are ALSO detected by their container folder name - this is the
-- fix for "shark esp not working" when shark models themselves are named
-- "1", "2", "Boss" etc. inside workspace.Sharks / workspace.Enemies.
local function isSharkLike(obj)
    if nameMatches(obj.Name, KEYWORDS.sharks) then return true end
    if obj:IsA("Model") then
        local p = obj.Parent
        local hops = 0
        while p and p ~= workspace and hops < 2 do
            if nameMatches(p.Name, SHARK_CONTAINERS) then return true end
            p = p.Parent
            hops = hops + 1
        end
    end
    return false
end

local function scanWorld()
    local rafts, chestKW, sharkKW, lootKW, interactive = {}, {}, {}, {}, {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("BasePart"))
           and not Players:GetPlayerFromCharacter(obj) then
            local n = obj.Name
            if nameMatches(n, KEYWORDS.chests) then
                table.insert(chestKW, obj)
            elseif isSharkLike(obj) then
                table.insert(sharkKW, obj)
            elseif nameMatches(n, KEYWORDS.rafts) then
                table.insert(rafts, obj)
            elseif nameMatches(n, KEYWORDS.loots) and not nameMatches(n, NEGATIVE_LOOT) then
                table.insert(lootKW, obj)
            else
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
    ownerCache = {}
    shieldCache = {}
    return scanCache
end

local function getWorldScan(force)
    if force or (os.clock() - scanCache.t) > 0.75 then
        scanCache.t = os.clock()
        local ok, err = pcall(scanWorld)
        if not ok then
            warn("[AniScript] world scan error:", err)
        end
    end
    return scanCache
end

-- =====================================================================
--  14.  RAFT CHEST FINDER  v12
--  A chest counts ONLY if it is INSIDE a raft box AND resting on that
--  raft (raycast hits the raft or its furniture). Sea boxes never pass.
--  Every entry carries: value (composite wealth score) + vtext (the
--  readable "$x" form used by ESP labels, F9 reports and TP buttons).
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
            else
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
                elseif not isOnRaftSurface(root, raft) then
                    stats.notOnSurface = stats.notOnSurface + 1
                else
                    local owner = getRaftOwner(raft)
                    local value, vtext = chestWealth(obj, owner)
                    if includeMine then
                        stats.valid = stats.valid + 1
                        table.insert(list, {
                            obj = obj, part = root, raft = raft,
                            owner = owner, value = value, vtext = vtext,
                        })
                    else
                        if isOwnedByMeOrCrew(raft) then
                            stats.mine = stats.mine + 1
                        elseif isRaftShielded(raft) then
                            stats.shielded = stats.shielded + 1
                        elseif chestLooksEmpty(obj) then
                            stats.empty = stats.empty + 1
                        else
                            stats.valid = stats.valid + 1
                            table.insert(list, {
                                obj = obj, part = root, raft = raft,
                                owner = owner, value = value, vtext = vtext,
                            })
                        end
                    end
                end
            end
        end
    end
    return { list = list, stats = stats }
end


-- =====================================================================
--  15.  ESP ENGINE v3
--  * billboards (name + wealth + live distance) are ALWAYS created ->
--    nothing can ever be invisible, even past Roblox's 31-highlight cap
--  * highlights are budgeted (24 total) with sensible per-group caps
--  * sea boxes & loot use SelectionBox outlines instead of highlights
--  * sync is diff-based -> zero flicker; labels RE-READ on every sync
--    so wealth / shield marks stay live
-- =====================================================================
local espVisuals = { players = {}, chests = {}, seaboxes = {}, rafts = {}, loots = {}, sharks = {} }

local ESP_COLORS = {
    players  = Color3.fromRGB(0, 255, 120),
    chests   = Color3.fromRGB(255, 200, 0),
    seaboxes = Color3.fromRGB(200, 205, 215),
    rafts    = Color3.fromRGB(60, 140, 255),
    loots    = Color3.fromRGB(170, 110, 60),
    sharks   = Color3.fromRGB(255, 50, 50),
}

local MAX_TOTAL_HIGHLIGHTS = 24
local HIGHLIGHT_CAPS = { players = 6, chests = 8, rafts = 3, sharks = 4, seaboxes = 2 }
local TRACK_CAPS = { players = 30, chests = 40, seaboxes = 40, rafts = 20, loots = 40, sharks = 15 }

local function createHighlight(target, color)
    if not target or not target.Parent then return nil end
    local ok, h = pcall(function()
        local hl = Instance.new("Highlight")
        hl.Adornee = target
        hl.FillColor = color
        hl.FillTransparency = 0.45
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = target
        return hl
    end)
    if ok then return h end
    return nil
end

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
    bb.Size = UDim2.new(0, 140, 0, 18)
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
        elseif labelFn then
            -- live labels: wealth values / shield marks refresh every sync
            local nl = labelFn(obj)
            if nl and nl ~= v.label then
                v.label = nl
                if v.tl and v.tl.Parent then v.tl.Text = nl end
            end
        end
    end

    -- nearest first, so caps always favour what is close to you
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
                local v = { root = root, label = labelFn and labelFn(obj) or group }
                local cap = HIGHLIGHT_CAPS[group]
                if group == "loots" or group == "seaboxes" then
                    v.selbox = createSelBox(obj, color)
                elseif cap and idx <= cap and countHighlights() < MAX_TOTAL_HIGHLIGHTS then
                    v.highlight = createHighlight(obj, color)
                elseif group == "sharks" then
                    v.selbox = createSelBox(obj, color)
                end
                v.bb, v.tl = createBillboard(root, color, v.label)
                store[obj] = v
            end
        end
    end
end

-- sea loot = keyword matches + floating interactive pickups NOT on rafts
local function buildLootList(scan)
    local rafts = scan.rafts
    local out = {}
    local seen = {}
    local function tryAdd(obj)
        if seen[obj] then return end
        if isPlayerPart(obj) then return end
        if nameMatches(obj.Name, NEGATIVE_LOOT) then return end
        if nameMatches(obj.Name, KEYWORDS.chests) then return end   -- those are Sea Boxes
        local root = getRootPart(obj)
        if not root then return end
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

-- sea boxes = chest-KEYWORD objects that are NOT standing on any raft
-- (floating crates / chests on the water). They get their own silver ESP
-- and NEVER mix with the gold "Raft Chest" ESP.
local function buildSeaBoxList(scan)
    local out = {}
    for _, obj in ipairs(scan.chestKW) do
        if not isPlayerPart(obj) then
            local root = getRootPart(obj)
            if root then
                local onRaft = false
                for _, r in ipairs(scan.rafts) do
                    if isInsideRaft(root, r) and isOnRaftSurface(root, r) then
                        onRaft = true
                        break
                    end
                end
                if not onRaft then table.insert(out, obj) end
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

    -- RAFT CHESTS (ONLY chests standing ON rafts - gold, wealth-tagged)
    arr = {}
    local chestLabels = {}
    if espState.chests then
        local res = getRaftChests(true, false)
        for _, c in ipairs(res.list) do
            table.insert(arr, c.obj)
            chestLabels[c.obj] = "Chest " .. (c.vtext or "~")
                .. (c.owner and (" - " .. c.owner.Name) or "")
                .. (isRaftShielded(c.raft) and " [SHIELD]" or "")
        end
    end
    syncGroup("chests", arr, ESP_COLORS.chests, function(o)
        return chestLabels[o] or "Chest"
    end)

    -- SEA BOXES (floating boxes / chests on the water - silver)
    arr = {}
    if espState.seaboxes then
        arr = buildSeaBoxList(scan)
    end
    syncGroup("seaboxes", arr, ESP_COLORS.seaboxes, function() return "Sea Box" end)

    -- RAFTS (label shows owner + shield state)
    arr = {}
    if espState.rafts then
        for _, r in ipairs(scan.rafts) do
            if not isPlayerPart(r) then table.insert(arr, r) end
        end
    end
    syncGroup("rafts", arr, ESP_COLORS.rafts, function(o)
        local ow = getRaftOwner(o)
        return (ow and ("Raft - " .. ow.Name) or "Raft")
            .. (isRaftShielded(o) and " [SHIELD]" or "")
    end)

    -- SHARKS (folder-aware detection + always-visible tags)
    arr = {}
    if espState.sharks then
        for _, s in ipairs(scan.sharkKW) do
            if not isPlayerPart(s) then table.insert(arr, s) end
        end
    end
    syncGroup("sharks", arr, ESP_COLORS.sharks, function() return "Shark" end)

    -- LOOT (floating sea pickups, real names as label)
    arr = {}
    if espState.loots then
        arr = buildLootList(scan)
    end
    syncGroup("loots", arr, ESP_COLORS.loots, function(o)
        return o.Name ~= "" and o.Name or "Loot"
    end)
end


-- =====================================================================
--  16.  CHEAT ENGINES  (fly / god v3 / ghost / walk on water / movement)
--  All engines share ONE Heartbeat connection (smooth + optimized).
-- =====================================================================

local function getStandHeight(hum, hrp)
    if not hum or not hrp then return 3 end
    if hum.RigType == Enum.HumanoidRigType.R15 then
        return (hum.HipHeight or 2) + hrp.Size.Y / 2
    end
    return 3
end

local function makeDownRay(char)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { char }
    params.IgnoreWater = false
    return params
end

-- ---------------- FLY (CFrame-based, nothing can block it) ------------
local flyState = false

local function flyStep(dt)
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
        pcall(function() hrp.CFrame = hrp.CFrame + move * dt end)
    end
    pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero end)
end

local function setFly(on)
    flyState = on and true or false
    UI.fly.set(flyState)
    setStatus(flyState
        and "Fly ON - WASD move, Space up, Shift down. Tune speed below. (F)"
        or "Fly OFF.", flyState and "ok" or "info")
end

-- ---------------- GOD MODE v3  (the "still taking damage" fix) --------
-- WHY v11 failed: it healed back to ~100 HP, so any single hit bigger
-- than that (shark bite, instakill, fall) killed you BEFORE the heal.
-- v3 makes you actually immortal:
--   L1  MaxHealth & Health locked to 1,000,000 - any hit is a scratch
--   L2  invisible ForceField - blocks Humanoid:TakeDamage damage cold
--   L3  instant re-heal on HealthChanged (same frame, never visible)
--   L4  Dead state disabled + BreakJointsOnDeath/RequiresNeck off
--   L5  per-frame re-assert - fights server resets of MaxHealth
--   L6  leaderstats Health/Hp keeper for custom-HP games
-- Turning it OFF restores your original MaxHealth cleanly.
local godOn = false
local godHookedHum = nil
local godHealthCon = nil
local godFF = nil
local godOriginalMax = 100
local GOD_MAX = 1000000
local godStatMax = {}

local function ensureForceField(char)
    if not char then return nil end
    local ff = char:FindFirstChild("AniGodFF")
    if not ff or not ff:IsA("ForceField") then
        ff = Instance.new("ForceField")
        ff.Name = "AniGodFF"
        ff.Visible = false
        ff.Parent = char
    end
    return ff
end

local function hookGod(hum)
    if not hum then return end
    godHookedHum = hum
    godOriginalMax = math.max(hum.MaxHealth or 100, 1)
    pcall(function()
        hum.MaxHealth = GOD_MAX
        hum.Health = GOD_MAX
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        hum.BreakJointsOnDeath = false
        hum.RequiresNeck = false
    end)
    if godHealthCon then
        pcall(function() godHealthCon:Disconnect() end)
        godHealthCon = nil
    end
    godHealthCon = hum:GetPropertyChangedSignal("Health"):Connect(function()
        if not godOn then return end
        if hum.Parent and hum.Health < GOD_MAX then
            pcall(function() hum.Health = GOD_MAX end)
        end
    end)
    godFF = ensureForceField(hum.Parent)
end

local function godStatsHeal()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if not ls then return end
    for _, st in ipairs(ls:GetChildren()) do
        if st:IsA("IntValue") or st:IsA("NumberValue") then
            local n = string.lower(st.Name)
            if n == "health" or n == "hp" or n == "life" then
                local cur = st.Value
                local mx = godStatMax[st]
                if not mx or cur > mx then
                    mx = cur
                    godStatMax[st] = mx
                end
                if cur < mx then
                    pcall(function() st.Value = mx end)
                end
            end
        end
    end
end

local function godTick()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if hum ~= godHookedHum then
        hookGod(hum)
        return
    end
    pcall(function()
        if hum.MaxHealth ~= GOD_MAX then hum.MaxHealth = GOD_MAX end
        if hum.Health < GOD_MAX then hum.Health = GOD_MAX end
    end)
    if not (godFF and godFF.Parent == char) then
        godFF = ensureForceField(char)
    end
    godStatsHeal()
end

local function removeGod()
    if godHealthCon then
        pcall(function() godHealthCon:Disconnect() end)
        godHealthCon = nil
    end
    godHookedHum = nil
    if godFF and godFF.Parent then
        pcall(function() godFF:Destroy() end)
    end
    godFF = nil
    godStatMax = {}
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function()
            hum.MaxHealth = godOriginalMax
            hum.Health = godOriginalMax
            hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
            hum.BreakJointsOnDeath = true
            hum.RequiresNeck = true
        end)
    end
    godOriginalMax = 100
end

local function setGod(on)
    godOn = on and true or false
    if godOn then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hookGod(hum) end
        setStatus("God Mode ON - 1M HP + forcefield: no hit can hurt or kill you.", "ok")
    else
        removeGod()
        setStatus("God Mode OFF - health restored to normal.")
    end
    UI.god.set(godOn)
end

-- ---------------- GHOST MODE (walls only - no floor clip, no float) ---
local ghostOn = false
local ghostNoclipCon = nil
local ghostSavedCollide = {}

local function startGhost()
    ghostOn = true
    if ghostNoclipCon then ghostNoclipCon:Disconnect() end
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
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        end)
    end
end

local function stopGhost()
    ghostOn = false
    if ghostNoclipCon then ghostNoclipCon:Disconnect() ghostNoclipCon = nil end
    for d in pairs(ghostSavedCollide) do
        pcall(function() if d.Parent then d.CanCollide = true end end)
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

local function ghostGround()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if flyState then return end   -- fly owns altitude while active

    local hum = char:FindFirstChildOfClass("Humanoid")
    local stand = getStandHeight(hum, hrp)
    local ray = workspace:Raycast(hrp.Position, Vector3.new(0, -(stand + 14), 0), makeDownRay(char))
    if not ray then return end   -- nothing below -> fall normally

    local floorY = ray.Position.Y
    local feetY  = hrp.Position.Y - stand
    local pen    = floorY - feetY

    local v = hrp.AssemblyLinearVelocity
    if pen >= -0.3 then
        -- floor at/above feet level -> full support
        if v.Y < 0 then
            pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z) end)
        end
        if pen > 0.05 then
            -- sunk slightly into the floor -> rise back out gently
            pcall(function()
                hrp.CFrame = hrp.CFrame + Vector3.new(0, math.min(pen, 0.5), 0)
            end)
        end
    elseif pen > -14 and v.Y < -60 then
        -- floor a bit further below -> cap fall speed for a soft landing
        pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(v.X, -60, v.Z) end)
    end
end

local function setGhost(on)
    if on then startGhost() else stopGhost() end
    UI.ghost.set(ghostOn)
    setStatus(ghostOn
        and "Ghost Mode ON - through walls only; floors still hold you, no floating. (G)"
        or "Ghost Mode OFF.", ghostOn and "ok" or "info")
end

-- ---------------- WALK ON WATER ---------------------------------------
-- Water-only ground support: step off your raft and you stand on the
-- sea surface and walk on it. Solid floors still behave normally, and
-- you fall / land normally everywhere else (no levitation).
local waterOn = false
local waterHeld = false

local function waterStep()
    if ghostOn or flyState then return end   -- those engines already own you

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local stand = getStandHeight(hum, hrp)

    local ray = workspace:Raycast(hrp.Position, Vector3.new(0, -(stand + 14), 0), makeDownRay(char))
    local held = false
    if ray then
        local isWater = (ray.Instance:IsA("Terrain") and ray.Material == Enum.Material.Water)
                        or isWaterInstance(ray.Instance)
        if isWater then
            local floorY = ray.Position.Y
            local feetY  = hrp.Position.Y - stand
            local pen    = floorY - feetY
            if pen >= -0.3 then
                held = true
                local v = hrp.AssemblyLinearVelocity
                if v.Y < 0 then
                    pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z) end)
                end
                if pen > 0.05 then
                    pcall(function()
                        hrp.CFrame = hrp.CFrame + Vector3.new(0, math.min(pen, 0.5), 0)
                    end)
                end
            elseif pen > -14 then
                local v = hrp.AssemblyLinearVelocity
                if v.Y < -60 then
                    pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(v.X, -60, v.Z) end)
                end
            end
        end
    end

    -- edge-triggered state switch: Freefall/Swimming are disabled only
    -- while water-held, so you keep full walking control on the surface
    -- but normal physics everywhere else
    if held ~= waterHeld then
        waterHeld = held
        if hum then
            pcall(function()
                hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, not held)
                hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, not held)
            end)
        end
    end
end

local function setWater(on)
    waterOn = on and true or false
    if not waterOn then
        waterHeld = false
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function()
                hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
                hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
            end)
        end
    end
    UI.water.set(waterOn)
    setStatus(waterOn
        and "Walk on Water ON - step off the raft and walk across the sea. (V)"
        or "Walk on Water OFF.", waterOn and "ok" or "info")
end

-- ---------------- MOVEMENT BOOSTS --------------------------------------
local moveTargets = { walk = defaultWalk, jump = defaultJumpPower }
local moveDirty = { walk = false, jump = false }

local function applyWalkTarget()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then pcall(function() hum.WalkSpeed = moveTargets.walk end) end
end

local function applyJumpTarget()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    pcall(function()
        if hum.UsingJumpPower then
            hum.JumpPower = moveTargets.jump
        else
            hum.JumpHeight = math.max(1, moveTargets.jump * 0.144)
        end
    end)
end

-- ---------------- MASTER HEARTBEAT (one loop for everything) -----------
RunService.Heartbeat:Connect(function(dt)
    if not screenGui.Parent then return end
    if flyState then flyStep(dt) end
    if ghostOn then ghostGround() end
    if waterOn then waterStep() end
    if godOn then godTick() end
end)

-- ---------------- RESPAWN SAFE-REAPPLY ----------------------------------
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.4)
    ghostSavedCollide = {}
    godFF = nil
    if godOn then
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then hookGod(hum) end
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
    if waterOn then
        waterHeld = false
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        defaultWalk = hum.WalkSpeed or 16
        defaultJumpPower = hum.JumpPower or 50
        defaultJumpHeight = hum.JumpHeight or 7.2
    end
    if moveDirty.walk then applyWalkTarget() end
    if moveDirty.jump then applyJumpTarget() end
    local mouse = LocalPlayer:GetMouse()
    if mouse then pcall(function() mouse.TargetFilter = char end) end
end)


-- =====================================================================
--  17.  HOME / RETURN TO RAFT  (crew-aware)
-- =====================================================================
local stoodRaft = nil
local homeRaft = nil
local savedCFrame = nil

local function tpTo(pos)
    local _, hrp = getChar()
    if hrp then pcall(function() hrp.CFrame = CFrame.new(pos) end) end
end

-- raycast straight down from the feet - no full world scan needed.
-- Returns the OUTERMOST keyword-matching ancestor (the raft container).
local function getRaftUnderFeet()
    local char, hrp = getChar()
    if not hrp then return nil end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local filter = { char }
    params.FilterDescendantsInstances = filter
    params.IgnoreWater = true
    local ray = workspace:Raycast(hrp.Position, Vector3.new(0, -30, 0), params)
    if not ray or not ray.Instance then return nil end
    local inst = ray.Instance
    local found = nil
    while inst and inst ~= workspace do
        if (inst:IsA("Model") or inst:IsA("BasePart"))
           and nameMatches(inst.Name, KEYWORDS.rafts) then
            found = inst
        end
        inst = inst.Parent
    end
    return found
end

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
        savedCFrame = hrp.CFrame
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
    pcall(function() hrp.CFrame = CFrame.new(pos + Vector3.new(0, 6, 0)) end)
    return true
end

-- order: raft I own -> cached home raft -> last raft stood on ->
-- saved CFrame -> spawn location
local function returnToMySpot()
    local strict = findMyRaftStrict()
    if strict and tpOntoRaft(strict) then return true end
    if homeRaft and homeRaft.Parent and tpOntoRaft(homeRaft) then return true end
    if stoodRaft and stoodRaft.Parent and tpOntoRaft(stoodRaft) then return true end
    local _, hrp = getChar()
    if savedCFrame and hrp then
        pcall(function() hrp.CFrame = savedCFrame end)
        return true
    end
    local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
    if spawn and hrp then
        pcall(function() hrp.CFrame = CFrame.new(spawn.Position + Vector3.new(0, 5, 0)) end)
        return true
    end
    return false
end

-- =====================================================================
--  18.  STEAL REMOTE LEARNING  (the "sometimes can't steal" fix)
--  Many raft games do the real steal through a RemoteEvent behind the
--  prompt. The FIRST successful steal (yours, manual, or the script's
--  prompt attempt) passes through the __namecall hook below and the
--  script records: which remote, which argument slot is the chest, and
--  the full argument template. Every later steal fires that remote
--  directly with the NEW chest substituted in -> guaranteed steals.
--  Learning is filtered so a wrong "chest-sync" remote never gets
--  recorded: a steal-NAMED remote is always trusted, anything else is
--  only learned inside an armed window (script stealing, or you are
--  standing right next to an enemy chest), and a learned remote is
--  LOCKED the moment a steal is confirmed to have worked.
--  Fully optional + silently skipped on executors without hooks.
-- =====================================================================
local stealRemoteInfo = nil   -- { remote, args, chestIdx, chest, locked }
local stealHookInstalled = false
local manualStealing = false  -- true while the manual "Steal Now" runs
local nearChestArmed = false  -- true while you stand near an enemy chest

local STEAL_REMOTE_WORDS = { "steal", "take", "rob", "loot", "claim", "collect" }

local function chestRelatedInstance(arg)
    if typeof(arg) ~= "Instance" then return false end
    local inst = arg
    if nameMatches(inst.Name, KEYWORDS.chests) then return true end
    local p = inst.Parent
    local hops = 0
    while p and p ~= workspace and hops < 3 do
        if nameMatches(p.Name, KEYWORDS.chests) then return true end
        p = p.Parent
        hops = hops + 1
    end
    return false
end

local function remoteNameLooksLikeSteal(rm)
    local n = string.lower(rm.Name)
    for _, w in ipairs(STEAL_REMOTE_WORDS) do
        if string.find(n, w, 1, true) then return true end
    end
    return false
end

local function installStealHook()
    if stealHookInstalled then return end
    local ok = pcall(function()
        if type(hookmetamethod) ~= "function" then error("hookmetamethod unavailable") end
        if type(getnamecallmethod) ~= "function" then error("getnamecallmethod unavailable") end

        local old
        local hookFn = function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" and self:IsA("RemoteEvent") then
                local args = { ... }
                for i, a in ipairs(args) do
                    if chestRelatedInstance(a) then
                        if remoteNameLooksLikeSteal(self) then
                            stealRemoteInfo = { remote = self, args = args, chestIdx = i, chest = a, locked = true }
                        elseif not (stealRemoteInfo and stealRemoteInfo.locked)
                               and (autoSteal or manualStealing or nearChestArmed) then
                            stealRemoteInfo = { remote = self, args = args, chestIdx = i, chest = a }
                        end
                        break
                    end
                end
            end
            return old(self, ...)
        end

        if type(newcclosure) == "function" then
            hookFn = newcclosure(hookFn)
        end

        old = hookmetamethod(game, "__namecall", hookFn)
        stealHookInstalled = true
    end)
    if stealHookInstalled then
        print("[AniScript] steal remote learning ACTIVE - steal one chest (manually is fine) and every later steal becomes guaranteed.")
    else
        print("[AniScript] steal remote learning unavailable in this executor - prompt stealing is used instead.")
    end
end

-- keep the "near an enemy chest" armed-window flag fresh (cheap, cached)
task.spawn(function()
    while screenGui.Parent do
        task.wait(0.5)
        nearChestArmed = false
        local _, hrp = getChar()
        if hrp then
            local res = getRaftChests(false, false)
            for _, c in ipairs(res.list) do
                if c.part and c.part.Parent then
                    if (hrp.Position - c.part.Position).Magnitude < 14 then
                        nearChestArmed = true
                        break
                    end
                end
            end
        end
    end
end)

-- fire the learned steal remote with the NEW chest substituted in.
-- Other instance args that belonged to the old chest are re-mapped by
-- name path onto the new chest; everything else is kept as recorded.
local function fireLearnedRemote(entry)
    if not stealRemoteInfo then return false end
    local info = stealRemoteInfo
    if not (info.remote and info.remote.Parent) then
        stealRemoteInfo = nil
        return false
    end
    local target = entry.obj
    if not target then return false end

    local out = {}
    for i, a in ipairs(info.args) do
        if i == info.chestIdx then
            out[i] = target
        elseif typeof(a) == "Instance" and info.chest
               and a ~= info.chest and a:IsDescendantOf(info.chest) then
            local path = {}
            local inst = a
            while inst and inst ~= info.chest do
                table.insert(path, 1, inst.Name)
                inst = inst.Parent
            end
            local mapped = target
            for _, nm in ipairs(path) do
                mapped = mapped and mapped:FindFirstChild(nm) or nil
                if not mapped then break end
            end
            out[i] = mapped or target
        else
            out[i] = a
        end
    end

    local ok = pcall(function()
        info.remote:FireServer(unpack(out))
    end)
    return ok
end

-- =====================================================================
--  19.  PROMPT FIRING v3
-- =====================================================================
local DRIVE_WORDS = { "drive", "steer", "sit", "seat", "helm", "pilot",
                      "sail", "mount", "ride", "control", "captain" }

local function promptLooksLikeDriver(d)
    local texts = {}
    pcall(function()
        table.insert(texts, tostring(d.ActionText or ""))
        table.insert(texts, tostring(d.ObjectText or ""))
    end)
    local inst = d.Parent
    local hops = 0
    while inst and inst ~= workspace and hops < 2 do
        table.insert(texts, inst.Name or "")
        inst = inst.Parent
        hops = hops + 1
    end
    for _, t in ipairs(texts) do
        local l = string.lower(t)
        for _, w in ipairs(DRIVE_WORDS) do
            if string.find(l, w, 1, true) then return true end
        end
    end
    return false
end

local function firePrompt(d)
    if not d or not d.Parent then return false end
    -- prompts that need line-of-sight silently fail from behind/inside
    -- the chest - turn that off client-side before firing
    pcall(function() d.RequiresLineOfSight = false end)
    if fireproximityprompt then
        local ok = pcall(fireproximityprompt, d)
        if ok then return true end
    end
    local ok2 = pcall(function()
        d:InputHoldBegin()
        local hold = math.min(d.HoldDuration or 0, 2)
        if hold > 0 then task.wait(hold + 0.05) end
        d:InputHoldEnd()
    end)
    if ok2 then return true end
    -- last resort: a real "E" keypress through VirtualInputManager
    pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.05)
        VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
    return false
end

local function fireAllPrompts(obj, cap)
    local fired = 0
    if not obj then return 0 end
    for _, d in ipairs(obj:GetDescendants()) do
        if fired >= (cap or 12) then break end
        if d:IsA("ProximityPrompt") and d.Enabled then
            firePrompt(d)
            fired = fired + 1
            task.wait(0.05)
        elseif d:IsA("ClickDetector") then
            pcall(function() fireclickdetector(d) end)
            fired = fired + 1
        end
    end
    return fired
end

-- chest prompts first, then raft prompts located NEAR the chest (some
-- games hang the steal trigger on the raft itself)
local function promptCandidates(entry)
    local out = {}
    if not entry or not entry.obj then return out end
    for _, d in ipairs(entry.obj:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Enabled then
            table.insert(out, d)
        elseif d:IsA("ClickDetector") then
            table.insert(out, d)
        end
    end
    if entry.raft and entry.part and entry.part.Parent then
        local cpos = entry.part.Position
        for _, d in ipairs(entry.raft:GetDescendants()) do
            local parent = d.Parent
            local dp = nil
            if parent and parent:IsA("BasePart") then dp = parent.Position end
            if parent and (parent:IsA("VehicleSeat") or parent:IsA("Seat")) then
                -- never touch seats - that is how you end up "driving" the raft
            elseif d:IsA("ProximityPrompt") and d.Enabled then
                if not dp or (dp - cpos).Magnitude <= 12 then
                    if not promptLooksLikeDriver(d) then
                        table.insert(out, d)
                    end
                end
            elseif d:IsA("ClickDetector") then
                if not dp or (dp - cpos).Magnitude <= 12 then
                    if not (parent and (parent:IsA("VehicleSeat") or parent:IsA("Seat"))) then
                        table.insert(out, d)
                    end
                end
            end
            if #out >= 14 then break end
        end
    end
    return out
end

-- jog the character through the chest volume for touch-based pickups
local function touchJitter(entry)
    if not entry.part or not entry.part.Parent then return end
    local p = entry.part.Position
    for i = 1, 3 do
        if not autoSteal then return end
        tpTo(p + Vector3.new((i - 2) * 0.8, 1.2 + (i % 2) * 0.6, (i % 2 == 0) and 0.8 or -0.8))
        task.wait(0.08)
    end
end

-- three different standing spots across retries: some games only
-- accept the steal when you are NOT inside the chest volume
local ATTEMPT_OFFSETS = {
    Vector3.new(0, 3, 0),      -- on top of the chest
    Vector3.new(0, 1.4, 2.6),  -- in front of the chest
    Vector3.new(0, 1.4, 0),    -- inside the chest volume
}

-- stand at pos and face the chest - safe against the straight-down
-- direction (CFrame.lookAt degenerates when look == up vector)
local function placeAndFace(hrp, pos, chestPos)
    local d = chestPos - pos
    if math.abs(d.X) < 0.05 and math.abs(d.Z) < 0.05 then
        pcall(function() hrp.CFrame = CFrame.new(pos) end)
    else
        pcall(function() hrp.CFrame = CFrame.lookAt(pos, chestPos) end)
    end
end

local function attemptSteal(entry, attempt)
    local fired = 0

    -- stand at this attempt's spot, FACE the chest, zero the velocity
    if entry.part and entry.part.Parent then
        local off = ATTEMPT_OFFSETS[attempt] or ATTEMPT_OFFSETS[1]
        local pos = entry.part.Position + off
        local _, hrp = getChar()
        if hrp then
            pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero end)
            placeAndFace(hrp, pos, entry.part.Position)
        else
            tpTo(pos)
        end
    end
    task.wait(0.12)

    -- 1) learned steal remote (the guaranteed path once learned)
    if stealRemoteInfo then
        if fireLearnedRemote(entry) then
            fired = fired + 1
        end
        task.wait(0.1)
    end

    -- 2) chest prompts + near-raft prompts (skip driver/seat prompts)
    local candidates = promptCandidates(entry)
    for _, d in ipairs(candidates) do
        if not autoSteal then return fired end
        if fired >= 14 then break end
        if d:IsA("ProximityPrompt") then
            if firePrompt(d) then fired = fired + 1 end
        else
            pcall(function() fireclickdetector(d) end)
            fired = fired + 1
        end
        task.wait(0.05)
    end

    -- 3) some games steal with the equipped tool
    local char = LocalPlayer.Character
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") then pcall(function() t:Activate() end) end
        end
    end

    -- safety net: even if some seat prompt slipped through, stand up -
    -- we are here to STEAL, never to drive somebody's raft
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum.Sit = false end) end
    end

    -- 4) touch-based chests get a physical jog
    if fired == 0 then
        touchJitter(entry)
    end
    return fired
end

local function chestStillThere(entry)
    local obj = entry.obj
    if not obj or not obj.Parent then return false end
    if chestLooksEmpty(obj) then return false end
    return true
end

-- up to 3 attempts, verifying the chest disappears / opens between them;
-- a full F9 report is printed when a chest refuses to be stolen so the
-- "sometimes I can't steal" cases become diagnosable
local function stealChest(entry)
    if not entry.part then return false end
    local totalFired = 0
    for attempt = 1, 3 do
        if not autoSteal and not manualStealing then return false end
        local fired = attemptSteal(entry, attempt)
        totalFired = totalFired + fired
        task.wait(0.45)
        if not autoSteal and not manualStealing then return false end
        if not chestStillThere(entry) then
            -- whatever fired during this successful steal IS the steal
            -- remote -> lock it so later syncs can never overwrite it
            if stealRemoteInfo and not stealRemoteInfo.locked then
                stealRemoteInfo.locked = true
            end
            print(("[AniScript] steal OK: %s | prompts fired: %d | remote: %s")
                :format(entry.obj.Name, totalFired,
                        stealRemoteInfo and "learned+used" or "not learned yet"))
            return true
        end
        if attempt < 3 then
            setStatus(("Stealing %s - attempt %d/3 (%d fired)...")
                :format(entry.obj.Name, attempt + 1, fired), "info")
        end
    end

    -- F9 diagnostic report for the stubborn chest
    local prompts, enabled = 0, 0
    for _, d in ipairs(entry.obj:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            prompts = prompts + 1
            if d.Enabled then enabled = enabled + 1 end
        end
    end
    print(("[AniScript] STEAL REPORT: %s | chest prompts: %d (%d enabled) | fired: %d | remote: %s | result: chest still there")
        :format(entry.obj.Name, prompts, enabled, totalFired,
                stealRemoteInfo and "learned+used" or "not learned"))
    print("  -> if prompts fired but the chest stayed: the game needs its steal remote.")
    print("  -> steal ONE chest manually with E - the script learns the remote and retries become guaranteed.")
    return false
end

-- manual "Steal Nearest Chest (NOW)" - instant test button
local function stealNearestNow()
    if stealing or manualStealing then return end
    local res = getRaftChests(false, true)
    if #res.list == 0 then
        setStatus("Steal Now: no stealable raft chest found (mine/crew, shielded and empty are skipped).", "warn")
        return
    end
    table.sort(res.list, function(a, b)
        return distTo(a.part) < distTo(b.part)
    end)
    local c = res.list[1]
    manualStealing = true
    task.spawn(function()
        local got = stealChest(c)
        setStatus(got
            and ("Steal Now: " .. c.obj.Name .. " stolen! (" .. c.vtext .. ")")
            or  "Steal Now: could not confirm - full report in F9 console.", 
            got and "ok" or "warn")
        manualStealing = false
    end)
end

-- store the loot at home by firing the home raft's prompts
local function storeChestAtHome()
    local myRaft = homeRaft
    if not (myRaft and myRaft.Parent) then
        myRaft = findMyRaftStrict()
        if myRaft then homeRaft = myRaft end
    end
    if not myRaft then return end

    local _, hrp = getChar()
    if not hrp then return end

    if not tpOntoRaft(myRaft) then return end
    task.wait(0.15)
    if not autoSteal then return end

    local char = LocalPlayer.Character
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") then pcall(function() t:Activate() end) end
        end
    end

    local firedHome = 0
    for _, d in ipairs(myRaft:GetDescendants()) do
        if not autoSteal then return end
        if firedHome >= 10 then break end
        local parent = d.Parent
        if parent and (parent:IsA("VehicleSeat") or parent:IsA("Seat")) then
            -- skip seats on the home raft too
        elseif d:IsA("ProximityPrompt") and d.Enabled then
            if not promptLooksLikeDriver(d) then
                firePrompt(d)
                firedHome = firedHome + 1
            end
        elseif d:IsA("ClickDetector") then
            pcall(function() fireclickdetector(d) end)
            firedHome = firedHome + 1
        end
    end

    -- never stay seated after storing
    local hum2 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum2 then pcall(function() hum2.Sit = false end) end
end

-- =====================================================================
--  20.  AUTO STEAL LOOP  (raft -> raft forever, shield-safe)
-- =====================================================================
local chestCooldown = {}   -- [chest instance] = expiry os.clock()
local raftCooldown  = {}   -- [raft instance]  = expiry os.clock()
local lastRaft = nil
local stealCycles = 0
local CHEST_CD = 45
local RAFT_CD  = 18

local function cleanCooldowns()
    local now = os.clock()
    for k, t in pairs(chestCooldown) do
        if t < now or not k.Parent then chestCooldown[k] = nil end
    end
    for k, t in pairs(raftCooldown) do
        if t < now or not k.Parent then raftCooldown[k] = nil end
    end
end

local function runStealCycle()
    cleanCooldowns()
    local now = os.clock()

    local res = getRaftChests(false, true)
    local stats, chests = res.stats, res.list

    local avail = {}
    for _, c in ipairs(chests) do
        if not (chestCooldown[c.obj] and chestCooldown[c.obj] > now) then
            if not (raftCooldown[c.raft] and raftCooldown[c.raft] > now) then
                table.insert(avail, c)
            end
        end
    end

    if #avail == 0 then
        if #chests == 0 then
            setStatus(("Auto Steal: scanning... (chest-like: %d | on rafts: %d | mine/crew: %d | shielded: %d | empty: %d)")
                :format(stats.keyword, stats.keyword - stats.notInRaft,
                        stats.mine, stats.shielded, stats.empty), "warn")
        else
            setStatus("Auto Steal: stolen chests cooling down - rotating to a new raft soon...", "info")
        end
        return
    end

    -- pick: a NEW raft first (not last stolen from, not on raft cooldown),
    -- then the nearest chest on it
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

    -- cooldowns are set BEFORE the trip so even a failed steal moves on
    chestCooldown[c.obj] = now + CHEST_CD
    raftCooldown[c.raft] = now + RAFT_CD
    lastRaft = c.raft

    setStatus(("Cycle %d -> %s (%s, owner: %s) | %d queued")
        :format(stealCycles, c.obj.Name, c.vtext,
                c.owner and c.owner.Name or "?", #avail))

    -- STEP 1: teleport to the chest and steal it (with retries)
    local got = stealChest(c)
    if not autoSteal then return end
    task.wait(0.25)

    -- STEP 2: always return home (crew-aware)
    setStatus(("Cycle %d: returning home..."):format(stealCycles))
    returnToMySpot()
    if not autoSteal then return end
    task.wait(0.15)

    -- STEP 3: store the loot at home
    setStatus(("Cycle %d: storing loot at home..."):format(stealCycles))
    storeChestAtHome()
    if not autoSteal then return end
    task.wait(0.35)

    setStatus(("Cycle %d done (%s) - moving to the next raft...")
        :format(stealCycles, got and "stolen" or "no confirm, rotated"),
        got and "ok" or "warn")
end

task.spawn(function()
    while screenGui.Parent do
        task.wait(0.4)
        if autoSteal and not stealing and not manualStealing then
            stealing = true
            local ok, err = pcall(runStealCycle)
            if not ok then
                warn("[AniScript] steal error:", err)
                setStatus("Auto Steal error - see F9. Returning home...", "err")
                pcall(returnToMySpot)
                task.wait(1)
            end
            stealing = false
        end
    end
end)

-- =====================================================================
--  21.  AUTO COLLECT SEA LOOT
-- =====================================================================
local lootBlacklist = {}
local collectedCount = 0

local function runCollectCycle()
    local now = os.clock()
    for k, t in pairs(lootBlacklist) do
        if t < now or not k.Parent then lootBlacklist[k] = nil end
    end

    local scan = getWorldScan()
    local loots = buildLootList(scan)
    local best, bestD = nil, math.huge
    for _, obj in ipairs(loots) do
        if not (lootBlacklist[obj] and lootBlacklist[obj] > now) and obj.Parent then
            local root = getRootPart(obj)
            if root then
                local d = distTo(root)
                if d < bestD then
                    best, bestD = obj, d
                end
            end
        end
    end

    if not best then
        setStatus("Auto Collect: no sea loot found nearby - scanning...", "info")
        return
    end
    local root = getRootPart(best)
    if not root then return end

    tpTo(root.Position + Vector3.new(0, 1.6, 0))
    task.wait(0.12)
    if not collectOn then return end

    fireAllPrompts(best, 10)

    -- touch jog for touch-based pickups
    for i = 1, 3 do
        if not collectOn then return end
        tpTo(root.Position + Vector3.new((i - 2) * 0.9, 1.2 + (i % 2) * 0.6, (i % 2 == 0) and 0.9 or -0.9))
        task.wait(0.07)
    end
    task.wait(0.3)
    if not collectOn then return end

    if best.Parent and root.Parent then
        lootBlacklist[best] = os.clock() + 60
        setStatus(("Auto Collect: %s did not pop (blacklisted 60s) - trying next...")
            :format(best.Name), "warn")
    else
        collectedCount = collectedCount + 1
        setStatus(("Auto Collect: picked up %s  (total %d)")
            :format(best.Name, collectedCount), "ok")
    end
end

task.spawn(function()
    while screenGui.Parent do
        task.wait(0.45)
        if collectOn and not collecting and not autoSteal and not manualStealing then
            collecting = true
            pcall(runCollectCycle)
            collecting = false
        end
    end
end)


-- =====================================================================
--  22.  UTILITIES  (Anti-AFK / FPS Boost)
-- =====================================================================
local antiAfkOn = false
local antiAfkCon = nil

local function setAntiAfk(on)
    antiAfkOn = on and true or false
    if antiAfkOn then
        if not antiAfkCon then
            local ok, VirtualUser = pcall(function() return game:GetService("VirtualUser") end)
            if ok and VirtualUser then
                antiAfkCon = LocalPlayer.Idled:Connect(function()
                    pcall(function()
                        VirtualUser:CaptureController()
                        VirtualUser:ClickButton2(Vector2.new())
                    end)
                end)
            end
        end
    else
        if antiAfkCon then
            pcall(function() antiAfkCon:Disconnect() end)
            antiAfkCon = nil
        end
    end
    UI.antiAfk.set(antiAfkOn)
    setStatus(antiAfkOn
        and "Anti-AFK ON - you will never be kicked for idling."
        or "Anti-AFK OFF.", antiAfkOn and "ok" or "info")
end

local fpsBoosted = false
local fpsSaved = nil

local function setFpsBoost(on)
    if on and not fpsBoosted then
        fpsSaved = {
            GlobalShadows = Lighting.GlobalShadows,
            FogEnd = Lighting.FogEnd,
            effects = {},
            water = nil,
        }
        for _, e in ipairs(Lighting:GetChildren()) do
            if e:IsA("PostEffect") then
                table.insert(fpsSaved.effects, { inst = e, enabled = e.Enabled })
                e.Enabled = false
            end
        end
        local Terrain = workspace:FindFirstChildOfClass("Terrain")
        if Terrain then
            fpsSaved.water = {
                waveSize = Terrain.WaterWaveSize,
                waveSpeed = Terrain.WaterWaveSpeed,
                reflectance = Terrain.WaterReflectance,
                transparency = Terrain.WaterTransparency,
            }
            pcall(function()
                Terrain.WaterWaveSize = 0
                Terrain.WaterWaveSpeed = 0
                Terrain.WaterReflectance = 0
                Terrain.WaterTransparency = 1
            end)
        end
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 100000000
        end)
        fpsBoosted = true
    elseif not on and fpsBoosted and fpsSaved then
        pcall(function()
            Lighting.GlobalShadows = fpsSaved.GlobalShadows
            Lighting.FogEnd = fpsSaved.FogEnd
        end)
        for _, rec in ipairs(fpsSaved.effects) do
            pcall(function() rec.inst.Enabled = rec.enabled end)
        end
        local Terrain = workspace:FindFirstChildOfClass("Terrain")
        if Terrain and fpsSaved.water then
            pcall(function()
                Terrain.WaterWaveSize = fpsSaved.water.waveSize
                Terrain.WaterWaveSpeed = fpsSaved.water.waveSpeed
                Terrain.WaterReflectance = fpsSaved.water.reflectance
                Terrain.WaterTransparency = fpsSaved.water.transparency
            end)
        end
        fpsSaved = nil
        fpsBoosted = false
    end
    UI.fps.set(on and true or false)
    setStatus(on
        and "FPS Boost ON - shadows, fog, post effects and water waves disabled."
        or "FPS Boost OFF - visuals restored.", on and "ok" or "info")
end

-- =====================================================================
--  23.  TP TO RICHEST / POOREST CHEST  (the "tp went to a poor chest"
--      fix: wealth-ranked, shield-excluded, full ranking in F9)
-- =====================================================================
local function tpToWealthiest(richest)
    local ok, err = pcall(function()
        local res = getRaftChests(false, true)
        if #res.list == 0 then
            setStatus("TP: no stealable raft chests (yours, crew, shielded and empty ones are skipped).", "warn")
            return
        end

        -- never teleport onto a shielded raft
        local safe = {}
        for _, c in ipairs(res.list) do
            if not isRaftShielded(c.raft) then
                table.insert(safe, c)
            end
        end
        if #safe == 0 then
            setStatus("TP: every chest found sits on a SHIELDED raft - nothing safe to teleport to.", "warn")
            return
        end

        table.sort(safe, function(a, b)
            if a.value ~= b.value then
                if richest then return a.value > b.value end
                return a.value < b.value
            end
            return distTo(a.part) < distTo(b.part)
        end)

        local best = safe[1]
        if not (best.part and best.part.Parent) then
            setStatus("TP: that chest vanished mid-scan - try again.", "warn")
            return
        end

        tpTo(best.part.Position + Vector3.new(0, 3, 0))
        setStatus(("TP %s -> %s  (%s, owner %s, %.0f studs away)")
            :format(richest and "RICH" or "POOR", best.obj.Name, best.vtext,
                    best.owner and best.owner.Name or "?", distTo(best.part)), "ok")

        -- full wealth ranking in F9 so you can always verify the choice
        print(("=== AniScript v12 CHEST RANKING (%s first) - %d safe chests ===")
            :format(richest and "RICHEST" or "POOREST", #safe))
        for i, c in ipairs(safe) do
            if i > 10 then
                print(("  ... and %d more"):format(#safe - 10))
                break
            end
            print(("  #%d  %s | %s | owner %s | %.0f studs | raft %s")
                :format(i, c.obj.Name, c.vtext,
                        c.owner and c.owner.Name or "?", distTo(c.part), c.raft.Name))
        end
    end)
    if not ok then
        warn("[AniScript] TP error:", err)
        setStatus("TP error - see F9.", "err")
    end
end

-- =====================================================================
--  24.  WIRING  (buttons / sliders / keybinds)
-- =====================================================================

-- ---------------- MAIN ----------------
local function setSteal(on)
    autoSteal = on and true or false
    if autoSteal then
        stealCycles = 0
        lastRaft = nil
        saveMySpot()
        setStatus("Auto Steal ON - hops raft to raft, skips shielded rafts. Tip: steal one chest with E once so the remote is learned.", "ok")
    else
        setStatus("Auto Steal OFF - stopped instantly.")
    end
    UI.steal.set(autoSteal)
end

local function setCollect(on)
    collectOn = on and true or false
    if collectOn then
        collectedCount = 0
        setStatus("Auto Collect ON - teleport-hops to every floating sea loot and picks it up.", "ok")
    else
        setStatus("Auto Collect OFF.")
    end
    UI.collect.set(collectOn)
end

UI.steal.btn.MouseButton1Click:Connect(function() setSteal(not autoSteal) end)
UI.collect.btn.MouseButton1Click:Connect(function() setCollect(not collectOn) end)
UI.god.btn.MouseButton1Click:Connect(function() setGod(not godOn) end)
UI.ghost.btn.MouseButton1Click:Connect(function() setGhost(not ghostOn) end)
UI.water.btn.MouseButton1Click:Connect(function() setWater(not waterOn) end)
UI.fly.btn.MouseButton1Click:Connect(function() setFly(not flyState) end)
UI.antiAfk.btn.MouseButton1Click:Connect(function() setAntiAfk(not antiAfkOn) end)
UI.fps.btn.MouseButton1Click:Connect(function() setFpsBoost(not fpsBoosted) end)
UI.clickTp.btn.MouseButton1Click:Connect(function()
    clickTpOn = not clickTpOn
    UI.clickTp.set(clickTpOn)
    setStatus(clickTpOn
        and "Click TP ON - hold Ctrl and click anywhere to teleport there."
        or "Click TP OFF.", clickTpOn and "ok" or "info")
end)

UI.flySpeed.onChange = function(v)
    flySpeed = math.floor(v)
end

UI.walkSpeed.onChange = function(v)
    moveTargets.walk = math.floor(v)
    moveDirty.walk = true
    applyWalkTarget()
    setStatus(("Walk Speed set to %d."):format(moveTargets.walk), "info")
end

UI.jumpPower.onChange = function(v)
    moveTargets.jump = math.floor(v)
    moveDirty.jump = true
    applyJumpTarget()
    setStatus(("Jump Power set to %d."):format(moveTargets.jump), "info")
end

UI.resetMove.MouseButton1Click:Connect(function()
    moveDirty.walk = false
    moveDirty.jump = false
    moveTargets.walk = defaultWalk
    moveTargets.jump = defaultJumpPower
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function()
            hum.WalkSpeed = defaultWalk
            if hum.UsingJumpPower then
                hum.JumpPower = defaultJumpPower
            else
                hum.JumpHeight = defaultJumpHeight
            end
        end)
    end
    UI.walkSpeed.set(defaultWalk, false)
    UI.jumpPower.set(defaultJumpPower, false)
    setStatus("Movement reset to the game's defaults.", "ok")
end)

-- ---------------- TP RICH / TP POOR / STEAL NOW / RETURN / SCAN -------
UI.richest.MouseButton1Click:Connect(function() tpToWealthiest(true) end)
UI.poorest.MouseButton1Click:Connect(function() tpToWealthiest(false) end)
UI.stealNow.MouseButton1Click:Connect(function() stealNearestNow() end)

UI.returnB.MouseButton1Click:Connect(function()
    if returnToMySpot() then
        setStatus("Returned to my raft (crew-aware).", "ok")
    else
        setStatus("Could not find home raft - stand on it once, then try again.", "warn")
    end
end)

UI.rescan.MouseButton1Click:Connect(function()
    local ok, err = pcall(function()
        local res = getRaftChests(false, true)
        local s = res.stats
        print(("=== AniScript v12 CHEST SCAN: %d valid ==="):format(#res.list))
        print(("  chest-like: %d | no root: %d | not inside a raft: %d | not resting on raft: %d | mine/crew: %d | shielded: %d | empty: %d")
            :format(s.keyword, s.noRoot, s.notInRaft, s.notOnSurface, s.mine, s.shielded, s.empty))
        for i, c in ipairs(res.list) do
            print(("[%d] %s | %s | raft=%s | owner=%s | dist=%.0f | shielded=%s"):format(
                i, c.obj.Name, c.vtext, c.raft.Name,
                c.owner and c.owner.Name or "?", distTo(c.part),
                tostring(isRaftShielded(c.raft))))
        end
        local scan = getWorldScan(true)
        print(("=== Rafts found: %d ==="):format(#scan.rafts))
        for _, r in ipairs(scan.rafts) do
            local o = getRaftOwner(r)
            print(("  %s | owner=%s | mine/crew=%s | shielded=%s"):format(
                r.Name, o and o.Name or "?",
                tostring(isOwnedByMeOrCrew(r)), tostring(isRaftShielded(r))))
        end
        print(("=== Sharks tracked: %d | Sea loot: %d ===")
            :format(#scan.sharkKW, #buildLootList(scan)))
        setStatus(("Scan: %d valid raft chests. Full report in F9 (F9 > console).")
            :format(#res.list), "ok")
    end)
    if not ok then
        warn("[AniScript] scan error:", err)
        setStatus("Scan error - see F9.", "err")
    end
end)

-- ---------------- ESP TOGGLES ----------------
UI.espPlayers.btn.MouseButton1Click:Connect(function()
    espState.players = not espState.players
    UI.espPlayers.set(espState.players)
    refreshESP()
    setStatus(espState.players and "Player ESP ON." or "Player ESP OFF.",
        espState.players and "ok" or "info")
end)

UI.espChests.btn.MouseButton1Click:Connect(function()
    espState.chests = not espState.chests
    UI.espChests.set(espState.chests)
    refreshESP()
    setStatus(espState.chests
        and "Raft Chest ESP ON - gold tags show each chest's wealth + owner. Sea boxes stay separate (silver)."
        or "Raft Chest ESP OFF.", espState.chests and "ok" or "info")
end)

UI.espSeaboxes.btn.MouseButton1Click:Connect(function()
    espState.seaboxes = not espState.seaboxes
    UI.espSeaboxes.set(espState.seaboxes)
    refreshESP()
    setStatus(espState.seaboxes
        and "Sea Box ESP ON - floating boxes / chests on the water glow silver (never counted as raft chests)."
        or "Sea Box ESP OFF.", espState.seaboxes and "ok" or "info")
end)

UI.espRafts.btn.MouseButton1Click:Connect(function()
    espState.rafts = not espState.rafts
    UI.espRafts.set(espState.rafts)
    refreshESP()
    setStatus(espState.rafts
        and "Raft ESP ON - owner shown, shielded rafts marked [SHIELD]."
        or "Raft ESP OFF.", espState.rafts and "ok" or "info")
end)

UI.espLoots.btn.MouseButton1Click:Connect(function()
    espState.loots = not espState.loots
    UI.espLoots.set(espState.loots)
    refreshESP()
    setStatus(espState.loots
        and "Loot ESP ON - floating sea pickups (wood, barrels, scrap...) tracked by name + smart scan."
        or "Loot ESP OFF.", espState.loots and "ok" or "info")
end)

UI.espSharks.btn.MouseButton1Click:Connect(function()
    espState.sharks = not espState.sharks
    UI.espSharks.set(espState.sharks)
    refreshESP()
    setStatus(espState.sharks
        and "Shark ESP ON - sharks found by name AND enemy folders, always-visible tags."
        or "Shark ESP OFF.", espState.sharks and "ok" or "info")
end)

-- =====================================================================
--  25.  KEYBINDS + CLICK TP
-- =====================================================================
UserInput.InputBegan:Connect(function(input, gp)
    if gp then return end
    if not screenGui.Parent then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if clickTpOn and UserInput:IsKeyDown(Enum.KeyCode.LeftControl) then
            local mouse = LocalPlayer:GetMouse()
            if mouse and mouse.Target then
                local pos = mouse.Hit.Position
                tpTo(pos + Vector3.new(0, 3.5, 0))
                setStatus("Click TP: moved.", "ok")
            end
        end
        return
    end

    local k = input.KeyCode
    if k == Enum.KeyCode.RightControl then
        mainFrame.Visible = not mainFrame.Visible
    elseif k == Enum.KeyCode.F then
        setFly(not flyState)
    elseif k == Enum.KeyCode.G then
        setGhost(not ghostOn)
    elseif k == Enum.KeyCode.V then
        setWater(not waterOn)
    end
end)

-- =====================================================================
--  26.  BACKGROUND LOOPS  (all cheap, all gated)
-- =====================================================================
-- remember the raft we stand on + our spot on it (raycast, no world scan)
task.spawn(function()
    while screenGui.Parent do
        task.wait(0.5)
        if not stealing then
            local r = getRaftUnderFeet()
            if r then
                stoodRaft = r
                local _, hrp = getChar()
                if hrp then savedCFrame = hrp.CFrame end
            end
        end
    end
end)

-- ESP refresh (diff-based, no flicker; labels re-read for live wealth)
task.spawn(function()
    while screenGui.Parent do
        task.wait(1.5)
        if espState.players or espState.chests or espState.seaboxes
           or espState.rafts or espState.loots or espState.sharks then
            refreshESP()
        end
    end
end)

-- live distance text on every ESP tag
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

-- keep boosted walk / jump applied (games love resetting them)
task.spawn(function()
    while screenGui.Parent do
        task.wait(0.6)
        if moveDirty.walk or moveDirty.jump then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                if moveDirty.walk and hum.WalkSpeed ~= moveTargets.walk then
                    applyWalkTarget()
                end
                if moveDirty.jump then
                    if hum.UsingJumpPower and hum.JumpPower ~= moveTargets.jump then
                        applyJumpTarget()
                    end
                end
            end
        end
    end
end)

-- =====================================================================
--  27.  CLOSE (clean shutdown of every feature)
-- =====================================================================
closeBtn.MouseButton1Click:Connect(function()
    autoSteal = false
    stealing = false
    manualStealing = false
    collectOn = false
    collecting = false
    flyState = false
    clickTpOn = false
    if ghostOn then stopGhost() end
    if godOn then
        godOn = false
        removeGod()
    end
    if waterOn then
        waterOn = false
        waterHeld = false
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function()
                hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
                hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
            end)
        end
    end
    if antiAfkCon then
        pcall(function() antiAfkCon:Disconnect() end)
        antiAfkCon = nil
    end
    if fpsBoosted then setFpsBoost(false) end
    for _, t in pairs(espVisuals) do
        for _, v in pairs(t) do
            pcall(function() if v.highlight then v.highlight:Destroy() end end)
            pcall(function() if v.selbox then v.selbox:Destroy() end end)
            pcall(function() if v.bb then v.bb:Destroy() end end)
        end
    end
    screenGui:Destroy()
end)

-- =====================================================================
--  28.  READY
-- =====================================================================
installStealHook()

setStatus("AniScript v12 PRO ready. RightCtrl = show/hide. F = Fly, G = Ghost, V = Walk on Water.", "ok")

print("[AniScript v12 PRO] loaded.")
print("  FIXED: TP Richest now wealth-ranks chests (signs $, values, owner gold) + TP Poorest button;")
print("  God Mode = 1M HP + forcefield + instant heal - no hit can get through;")
print("  Auto Steal learns the game's steal remote after your first steal - then it is guaranteed;")
print("  stubborn chests print a full F9 report (prompts, enabled, remote learned).")
print("  UI: fixed small window (336x306) - scroll inside each tab for more features.")
print("  KEPT: walk on water (V), ghost without floor-clip/levitate, raft-chest-only ESP with $wealth")
print("  tags, shark ESP, shield-raft skipping, auto collect, click TP, anti-AFK, FPS boost.")
