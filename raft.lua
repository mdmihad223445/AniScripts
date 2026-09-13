--=============================================================================--
--  RAFT HUB v3.0  --  full rebuild
--
--  FIXES vs the old version
--  * Auto Steal : works while walking AND while driving your raft. It NEVER
--                 touches YOUR raft / crew rafts / shield rafts. It never
--                 blocks manual stealing. It keeps working forever (no freeze
--                 after the first steal). It always returns you to your spot
--                 and re-sits you on your raft seat.
--  * TP Rich / Poor : two separate buttons, correct rich/poor sorting, shield
--                 rafts skipped, always picks DIFFERENT rafts when possible.
--  * God Mode   : health restored every single frame.
--  * Ghost Mode : you pass through walls but never through the floor and you
--                 never levitate -- you simply walk normally.
--  * Chest ESP  : only real raft chests (no crates / boxes / shield rafts).
--  * Shark ESP  : fixed, re-scans constantly.
--  * UI         : fixed compact window, scroll INSIDE it for more features.
--
--  NEW FEATURES
--  * Walk on Water (Main tab)          * Infinite Jump
--  * Instant Interact (0s hold)        * Fullbright + FPS Boost
--  * TP to players                     * Save / Return position
--  * Set My Raft (own-raft exclusion)  * Fix Character (un-glitch) button
--  * Speed / Jump / Gravity sliders    * Anti-AFK (always on)
--
--  Hotkey : RightCtrl shows / hides the menu.
--  Re-running the script safely removes the old instance first.
--=============================================================================--

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local RUNNING = true
local Connections = {}
local function bind(c)
    Connections[#Connections + 1] = c
    return c
end
local function now()
    return time()
end

-- forward declarations (filled in later)
local notify = function() end
local stealStatusLabel, scanInfoLabel, playerLabel
local Toggles, Sliders = {}, {}

local STATE = {
    -- stealing
    autosteal = false, stealCooldown = 8, stealRange = 1000, autoReturn = true,
    stealCount = 0, lastStealTarget = "-", nextStealAt = 0,
    stealMsg = "Watching for enemy rafts...",
    -- movement
    god = false, ghost = false, waterwalk = false, infjump = false,
    walkspeed = 16, jumppower = 50, gravity = 196.2,
    -- esp
    espChest = false, espRaft = false, espShark = false, espPlayer = false,
    espTracer = false, showMine = false,
    -- graphics
    fullbright = false, fpsboost = false, instant = false,
    -- misc
    myRaft = nil, savedCF = nil,
}
local DEFAULT_GRAVITY = 196.2

--=============================================================================--
--  SAFE RE-EXECUTION : kill any previous instance of this hub first.
--  (this is what fixed the "glitched / can't steal manually" state)
--=============================================================================--
pcall(function()
    if getgenv ~= nil and getgenv().__RAFTHUB_UNLOAD ~= nil then
        getgenv().__RAFTHUB_UNLOAD()
    end
end)
pcall(function()
    local containers = {}
    if gethui ~= nil then
        local ok, h = pcall(gethui)
        if ok and h ~= nil then containers[#containers + 1] = h end
    end
    containers[#containers + 1] = game:GetService("CoreGui")
    containers[#containers + 1] = LocalPlayer:WaitForChild("PlayerGui")
    for i = 1, #containers do
        for _, s in ipairs(containers[i]:GetChildren()) do
            if s.Name == "RaftHub_v3" then s:Destroy() end
        end
    end
end)

bind(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = Workspace.CurrentCamera
end))

--=============================================================================--
--  SMALL UTILITIES
--=============================================================================--
local function getChar()
    return LocalPlayer.Character
end
local function getRoot()
    local c = getChar()
    if c == nil then return nil end
    return c:FindFirstChild("HumanoidRootPart")
end
local function getHumanoid()
    local c = getChar()
    if c == nil then return nil end
    return c:FindFirstChildOfClass("Humanoid")
end

local function comma(n)
    local s = tostring(math.floor(n + 0.5))
    local out = string.gsub(string.reverse(s), "(%d%d%d)", "%1,")
    out = string.reverse(out)
    if string.sub(out, 1, 1) == "," then out = string.sub(out, 2) end
    return out
end
local function fmtNum(n)
    if n == nil then return "?" end
    if n >= 1000000000 then return string.format("%.2fB", n / 1000000000) end
    if n >= 1000000 then return string.format("%.2fM", n / 1000000) end
    if n >= 100000 then return string.format("%.1fK", n / 1000) end
    return comma(n)
end

local atan2 = math.atan2 or function(y, x)
    if x > 0 then return math.atan(y / x) end
    if x < 0 and y >= 0 then return math.atan(y / x) + math.pi end
    if x < 0 then return math.atan(y / x) - math.pi end
    if y > 0 then return math.pi / 2 end
    return -math.pi / 2
end

--=============================================================================--
--  GUI CONTAINER
--=============================================================================--
local Gui = Instance.new("ScreenGui")
Gui.Name = "RaftHub_v3"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.DisplayOrder = 9999
do
    local ok = false
    pcall(function()
        if gethui ~= nil then
            Gui.Parent = gethui()
            ok = true
        end
    end)
    if not ok then
        pcall(function()
            Gui.Parent = game:GetService("CoreGui")
            ok = true
        end)
    end
    if not ok then
        Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end
local tracerHolder = Instance.new("Folder")
tracerHolder.Name = "RaftHubTracers"
tracerHolder.Parent = Gui

--=============================================================================--
--  GAME SCANNER : rafts, raft chests, owners, sharks
--=============================================================================--
local CHEST_BLOCK = { "crate", "box", "barrel", "storage", "shield", "supply", "container", "package" }

-- only real chests (name contains "chest", and none of the junk words)
local function isRaftChest(inst)
    local n = string.lower(inst.Name)
    if string.find(n, "chest", 1, true) == nil then return false end
    for i = 1, #CHEST_BLOCK do
        if string.find(n, CHEST_BLOCK[i], 1, true) ~= nil then return false end
    end
    return true
end

local function parseNumText(text)
    if type(text) ~= "string" then return nil end
    local t = string.lower(text)
    local mult = 1
    if string.find(t, "k", 1, true) then
        mult = 1000
    elseif string.find(t, "m", 1, true) then
        mult = 1000000
    end
    local digits = string.gsub(t, "[^%d%.]", "")
    if digits == "" or digits == "." then return nil end
    local num = tonumber(digits)
    if num == nil then return nil end
    return num * mult
end

-- try to read how much a chest is worth (attributes / values / billboard text)
local function getChestValue(chest)
    local ok, v = pcall(function()
        local attrs = { "Value", "value", "Coins", "Gold", "Money", "Worth", "Amount" }
        for i = 1, #attrs do
            local val = chest:GetAttribute(attrs[i])
            if type(val) == "number" then return val end
        end
        for _, d in ipairs(chest:GetChildren()) do
            local dn = string.lower(d.Name)
            if d:IsA("NumberValue") or d:IsA("IntValue") then
                if string.find(dn, "value", 1, true) or string.find(dn, "coin", 1, true)
                    or string.find(dn, "gold", 1, true) or string.find(dn, "money", 1, true)
                    or string.find(dn, "worth", 1, true) then
                    return d.Value
                end
            end
        end
        local bg = chest:FindFirstChildWhichIsA("BillboardGui", true)
        if bg == nil and chest.Parent ~= nil then
            bg = chest.Parent:FindFirstChildWhichIsA("BillboardGui", true)
        end
        if bg ~= nil then
            for _, t in ipairs(bg:GetDescendants()) do
                if t:IsA("TextLabel") and t.Text ~= nil and #t.Text > 0 then
                    local num = parseNumText(t.Text)
                    if num ~= nil then return num end
                end
            end
        end
        return nil
    end)
    if ok then return v end
    return nil
end

-- prompt helpers ---------------------------------------------------------------
local BLOCK_WORDS = { "open", "access", "collect", "store", "deposit", "view", "shield", "withdraw", "check" }
local function promptBlocked(p)
    local t = string.lower((p.ActionText or "") .. " " .. (p.ObjectText or ""))
    for i = 1, #BLOCK_WORDS do
        if string.find(t, BLOCK_WORDS[i], 1, true) ~= nil then return true end
    end
    return false
end

-- find the "steal" prompt of a chest (prefers prompts that literally say Steal)
local function findStealPrompt(chest)
    local prompts = {}
    if chest:IsA("ProximityPrompt") then
        prompts[#prompts + 1] = chest
    end
    local descs = chest:GetDescendants()
    for i = 1, #descs do
        if descs[i]:IsA("ProximityPrompt") then
            prompts[#prompts + 1] = descs[i]
        end
    end
    if #prompts == 0 and chest.Parent ~= nil then
        local pd = chest.Parent:GetChildren()
        for i = 1, #pd do
            if pd[i]:IsA("ProximityPrompt") then
                prompts[#prompts + 1] = pd[i]
            end
        end
    end
    local fallback = nil
    for i = 1, #prompts do
        local p = prompts[i]
        if p.Enabled then
            local t = string.lower((p.ActionText or "") .. " " .. (p.ObjectText or ""))
            if string.find(t, "steal", 1, true) ~= nil or string.find(t, "rob", 1, true) ~= nil then
                return p
            end
            if fallback == nil and not promptBlocked(p) then
                fallback = p
            end
        end
    end
    return fallback
end

local function promptPos(prompt)
    local p = prompt.Parent
    if p == nil then return nil end
    if p:IsA("Attachment") then return p.WorldPosition end
    if p:IsA("BasePart") then return p.Position end
    if p:IsA("Model") then
        local ok, pv = pcall(function() return p:GetPivot().Position end)
        if ok then return pv end
    end
    return nil
end

local function instPos(inst)
    if inst == nil then return nil end
    if inst:IsA("BasePart") then return inst.Position end
    if inst:IsA("Attachment") then return inst.WorldPosition end
    if inst:IsA("Model") then
        local ok, pv = pcall(function() return inst:GetPivot().Position end)
        if ok then return pv end
    end
    local bp = inst:FindFirstChildWhichIsA("BasePart", true)
    if bp ~= nil then return bp.Position end
    return nil
end

-- owner detection ---------------------------------------------------------------
local function nameMatchPlayer(s)
    if s == nil or s == "" then return nil end
    local ls = string.lower(s)
    local list = Players:GetPlayers()
    for i = 1, #list do
        local p = list[i]
        if string.lower(p.Name) == ls or string.lower(p.DisplayName) == ls then
            return p
        end
    end
    return nil
end

local function getRaftOwner(model)
    local p = nameMatchPlayer(model.Name)
    if p ~= nil then return p end

    local attrs = { "Owner", "owner", "OwnerName", "Creator", "CreatorName", "CreatedBy" }
    for i = 1, #attrs do
        local ok, v = pcall(function() return model:GetAttribute(attrs[i]) end)
        if ok and v ~= nil then
            if type(v) == "string" then
                local mp = nameMatchPlayer(v)
                if mp ~= nil then return mp end
            elseif type(v) == "number" then
                local list = Players:GetPlayers()
                for j = 1, #list do
                    if list[j].UserId == v then return list[j] end
                end
            end
        end
    end

    local ok2, descs = pcall(function() return model:GetDescendants() end)
    if ok2 then
        for i = 1, #descs do
            local d = descs[i]
            local dn = string.lower(d.Name)
            local isOwnerVal = string.find(dn, "owner", 1, true) ~= nil or string.find(dn, "creator", 1, true) ~= nil
            if isOwnerVal then
                if d:IsA("ObjectValue") and d.Value ~= nil and d.Value:IsA("Player") then
                    return d.Value
                elseif d:IsA("StringValue") or d:IsA("IntValue") or d:IsA("NumberValue") then
                    local v = d.Value
                    if type(v) == "string" then
                        local mp = nameMatchPlayer(v)
                        if mp ~= nil then return mp end
                    elseif type(v) == "number" then
                        local list = Players:GetPlayers()
                        for j = 1, #list do
                            if list[j].UserId == v then return list[j] end
                        end
                    end
                end
            end
        end
    end
    return nil
end

-- raft scanning -----------------------------------------------------------------
-- richest-player signal: sum of the raft OWNER's leaderstats wealth (gold/coins)
local WEALTH_STAT_WORDS = { "gold", "coin", "money", "cash", "value", "score", "wealth", "trophy", "point", "resource", "gem" }
local function playerWealth(p)
    if p == nil then return 0 end
    local ok, ls = pcall(function() return p:FindFirstChild("leaderstats") end)
    if not ok or ls == nil then return 0 end
    local total = 0
    for _, st in ipairs(ls:GetChildren()) do
        if st:IsA("IntValue") or st:IsA("NumberValue") then
            local n = string.lower(st.Name)
            for i = 1, #WEALTH_STAT_WORDS do
                if string.find(n, WEALTH_STAT_WORDS[i], 1, true) ~= nil then
                    total = total + (st.Value or 0)
                    break
                end
            end
        end
    end
    return total
end

local SCAN = { rafts = {}, sharks = {}, lastAt = 0 }
local ownerCache = {}

local function raftCenterOf(model, chests)
    if model:IsA("Model") then
        local ok, cf = pcall(function() return model:GetBoundingBox() end)
        if ok and cf ~= nil then return cf.Position end
    end
    local n = 0
    local sum = Vector3.new(0, 0, 0)
    for i = 1, #chests do
        local p = instPos(chests[i])
        if p ~= nil then
            n = n + 1
            sum = sum + p
        end
    end
    if n > 0 then return sum / n end
    return nil
end

local function considerRaft(inst, depth)
    if not (inst:IsA("Model") or inst:IsA("Folder")) then return end
    if inst == LocalPlayer.Character then return end
    if inst:FindFirstChildOfClass("Humanoid") ~= nil then return end

    local lname = string.lower(inst.Name)
    local shield = string.find(lname, "shield", 1, true) ~= nil

    local chests = {}
    local descs = inst:GetDescendants()
    for i = 1, #descs do
        local d = descs[i]
        if isRaftChest(d) then
            chests[#chests + 1] = d
        elseif (not shield) and d:IsA("BasePart") then
            if string.find(string.lower(d.Name), "shield", 1, true) ~= nil then
                shield = true
            end
        end
    end

    local owner = ownerCache[inst]
    if owner == nil then
        owner = getRaftOwner(inst)
        if owner == nil then owner = false end
        ownerCache[inst] = owner
    end
    if owner == false then owner = nil end

    local looksRaft = string.find(lname, "raft", 1, true) ~= nil
    if not (looksRaft or #chests > 0 or owner ~= nil) then return end

    -- a big container holding many chests -> split into its child rafts
    if #chests >= 10 and depth < 3 then
        local kids = inst:GetChildren()
        local subCandidates = 0
        for i = 1, #kids do
            local k = kids[i]
            if (k:IsA("Model") or k:IsA("Folder")) and k:FindFirstChildOfClass("Humanoid") == nil then
                local kn = string.lower(k.Name)
                local isSub = string.find(kn, "raft", 1, true) ~= nil
                if not isSub and nameMatchPlayer(k.Name) ~= nil then isSub = true end
                if not isSub then
                    local kd = k:GetChildren()
                    for j = 1, #kd do
                        if isRaftChest(kd[j]) then isSub = true break end
                    end
                end
                if isSub then subCandidates = subCandidates + 1 end
            end
        end
        if subCandidates >= 2 then
            for i = 1, #kids do
                considerRaft(kids[i], depth + 1)
            end
            return
        end
    end

    local isMine = (owner == LocalPlayer) or (inst == STATE.myRaft)
    local isCrew = false
    if owner ~= nil and owner ~= LocalPlayer and owner.Team ~= nil
        and LocalPlayer.Team ~= nil and owner.Team == LocalPlayer.Team then
        isCrew = true
    end

    local total, known, topVal, topChest = 0, 0, -1, nil
    for i = 1, #chests do
        local v = getChestValue(chests[i])
        if v ~= nil then
            total = total + v
            known = known + 1
            if v > topVal then
                topVal = v
                topChest = chests[i]
            end
        end
    end
    if topChest == nil and #chests > 0 then topChest = chests[1] end
    local wealth, wealthFrom
    if known > 0 then
        wealth = total
        wealthFrom = "chests"
    else
        local ow = 0
        if owner ~= nil then ow = playerWealth(owner) end
        if ow > 0 then
            wealth = ow
            wealthFrom = "owner"
        else
            wealth = #chests * 100
            wealthFrom = "count"
        end
    end

    SCAN.rafts[#SCAN.rafts + 1] = {
        model = inst,
        name = inst.Name,
        owner = owner,
        shield = shield,
        mine = isMine,
        crew = isCrew,
        chests = chests,
        wealth = wealth,
        wealthFrom = wealthFrom,
        known = known,
        topChest = topChest,
        center = raftCenterOf(inst, chests),
    }
end

local function fullScan()
    if not RUNNING then return end
    SCAN.rafts = {}
    SCAN.sharks = {}

    for m, _ in pairs(ownerCache) do
        if m.Parent == nil then ownerCache[m] = nil end
    end

    -- sharks (name sweep over the whole workspace)
    local ok, descs = pcall(function() return Workspace:GetDescendants() end)
    if ok then
        for i = 1, #descs do
            local inst = descs[i]
            if inst:IsA("Model") and #SCAN.sharks < 24 then
                if string.find(string.lower(inst.Name), "shark", 1, true) ~= nil
                    and inst:FindFirstChildOfClass("Humanoid") == nil then
                    SCAN.sharks[#SCAN.sharks + 1] = inst
                end
            end
        end
    end

    -- rafts (top level + one split level)
    local kids = Workspace:GetChildren()
    for i = 1, #kids do
        considerRaft(kids[i], 0)
    end
    SCAN.lastAt = now()
end

--=============================================================================--
--  ESP SYSTEM (highlight + billboard, auto purge, optional tracers)
--=============================================================================--
local KIND_COLOR = {
    chest    = Color3.fromRGB(255, 170, 60),
    shark    = Color3.fromRGB(255, 85, 85),
    raft     = Color3.fromRGB(60, 220, 140),
    raftMine = Color3.fromRGB(95, 170, 255),
    player   = Color3.fromRGB(150, 200, 255),
}
local KIND_OFFSET = { chest = 3, shark = 5, raft = 10, player = 4 }
local ESPReg = { chest = {}, shark = {}, raft = {}, player = {} }

local function anchorFor(inst)
    if inst:IsA("BasePart") or inst:IsA("Model") or inst:IsA("Attachment") then return inst end
    local bp = inst:FindFirstChildWhichIsA("BasePart", true)
    if bp ~= nil then return bp end
    return inst
end

local function espAnchor(model, chests)
    if model:IsA("Model") or model:IsA("BasePart") then return model end
    if chests ~= nil and chests[1] ~= nil then return anchorFor(chests[1]) end
    return anchorFor(model)
end

local function destroyEntry(e)
    if e.highlight ~= nil then pcall(function() e.highlight:Destroy() end) end
    if e.gui ~= nil then pcall(function() e.gui:Destroy() end) end
    if e.tracer ~= nil then pcall(function() e.tracer:Destroy() end) end
end

local function ensureEntry(reg, inst, kind, data, anchor)
    local e = reg[inst]
    if e ~= nil and e.kind == kind then
        e.data = data
        return
    end
    if e ~= nil then
        destroyEntry(e)
        reg[inst] = nil
    end
    if anchor == nil then anchor = anchorFor(inst) end
    local color
    if kind == "raft" and data ~= nil and data.shield then
        color = Color3.fromRGB(150, 160, 175)
    elseif kind == "raft" and data ~= nil and data.mine then
        color = KIND_COLOR.raftMine
    else
        color = KIND_COLOR[kind]
    end
    local h = Instance.new("Highlight")
    h.FillColor = color
    h.FillTransparency = 0.72
    h.OutlineColor = color
    h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Adornee = anchor
    h.Parent = anchor

    local bg = Instance.new("BillboardGui")
    bg.Adornee = anchor
    bg.AlwaysOnTop = true
    bg.MaxDistance = 6000
    bg.LightInfluence = 0
    bg.StudsOffsetWorldSpace = Vector3.new(0, KIND_OFFSET[kind] or 3, 0)
    bg.Size = UDim2.new(0, 200, 0, 18)
    local tl = Instance.new("TextLabel")
    tl.BackgroundTransparency = 1
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.Font = Enum.Font.GothamMedium
    tl.TextSize = 12
    tl.TextColor3 = color
    tl.TextStrokeTransparency = 0.65
    tl.TextXAlignment = Enum.TextXAlignment.Center
    tl.Text = ""
    tl.Parent = bg
    bg.Parent = anchor

    reg[inst] = { kind = kind, data = data, highlight = h, gui = bg, label = tl, tracer = nil }
end

local function purgeKind(kind, keep)
    local reg = ESPReg[kind]
    if reg == nil then return end
    for inst, e in pairs(reg) do
        if keep == nil or keep[inst] ~= true then
            destroyEntry(e)
            reg[inst] = nil
        end
    end
end

local function espTextFor(e, inst, dist)
    local d = string.format("%dm", math.floor(dist + 0.5))
    local k = e.kind
    if k == "chest" then
        local v = getChestValue(inst)
        if v ~= nil then
            return string.format("CHEST  %s  -  %s", fmtNum(v), d)
        end
        return string.format("CHEST  -  %s", d)
    elseif k == "shark" then
        return string.format("SHARK  -  %s", d)
    elseif k == "raft" then
        local r = e.data
        if r == nil then return "RAFT" end
        local who = "Raft"
        if r.owner ~= nil then who = r.owner.Name elseif r.name ~= nil then who = r.name end
        local tag
        if r.shield then tag = "SHIELD RAFT"
        elseif r.mine then tag = "MY RAFT"
        elseif r.crew then tag = "CREW RAFT"
        else tag = "ENEMY RAFT" end
        local wealth
        if r.wealthFrom == "owner" then
            wealth = fmtNum(r.wealth) .. " gold"
        elseif r.known > 0 then
            wealth = fmtNum(r.wealth)
        else
            wealth = string.format("%d chests", #r.chests)
        end
        return string.format("%s  %s  -  %s  -  %s", tag, who, wealth, d)
    elseif k == "player" then
        local pl = e.data
        local nm = "Player"
        if pl ~= nil then
            if pl.DisplayName ~= nil and pl.DisplayName ~= "" then nm = pl.DisplayName else nm = pl.Name end
        end
        return string.format("%s  -  %s", nm, d)
    end
    return d
end

local function refreshESP()
    local root = getRoot()
    local rp = nil
    if root ~= nil then rp = root.Position end

    -- CHEST ESP : raft chests only (no crates, no boxes, no shield rafts)
    local seenChest = {}
    if STATE.espChest then
        local list = {}
        for _, r in ipairs(SCAN.rafts) do
            if (not r.shield) and (STATE.showMine or ((not r.mine) and (not r.crew))) then
                for _, c in ipairs(r.chests) do
                    local p = instPos(c)
                    local d = 9e9
                    if p ~= nil and rp ~= nil then d = (p - rp).Magnitude end
                    list[#list + 1] = { c, r, d }
                end
            end
        end
        table.sort(list, function(a, b) return a[3] < b[3] end)
        local n = #list
        if n > 20 then n = 20 end
        for i = 1, n do
            ensureEntry(ESPReg.chest, list[i][1], "chest", list[i][2], nil)
            seenChest[list[i][1]] = true
        end
    end
    purgeKind("chest", seenChest)

    -- RAFT ESP : owner + wealth
    local seenRaft = {}
    if STATE.espRaft then
        local list = {}
        for _, r in ipairs(SCAN.rafts) do
            if STATE.showMine or (not r.mine) then
                local d = 9e9
                if r.center ~= nil and rp ~= nil then d = (r.center - rp).Magnitude end
                list[#list + 1] = { r, d }
            end
        end
        table.sort(list, function(a, b) return a[2] < b[2] end)
        local n = #list
        if n > 12 then n = 12 end
        for i = 1, n do
            local r = list[i][1]
            ensureEntry(ESPReg.raft, r.model, "raft", r, espAnchor(r.model, r.chests))
            seenRaft[r.model] = true
        end
    end
    purgeKind("raft", seenRaft)

    -- SHARK ESP
    local seenShark = {}
    if STATE.espShark then
        for _, s in ipairs(SCAN.sharks) do
            ensureEntry(ESPReg.shark, s, "shark", nil, nil)
            seenShark[s] = true
        end
    end
    purgeKind("shark", seenShark)

    -- PLAYER ESP
    local seenPlayer = {}
    if STATE.espPlayer then
        local list = Players:GetPlayers()
        for i = 1, #list do
            local pl = list[i]
            if pl ~= LocalPlayer and pl.Character ~= nil then
                ensureEntry(ESPReg.player, pl.Character, "player", pl, nil)
                seenPlayer[pl.Character] = true
            end
        end
    end
    purgeKind("player", seenPlayer)
end

local function updateScanInfo()
    if scanInfoLabel == nil then return end
    local total, enemy, mine, crew, shield = 0, 0, 0, 0, 0
    for _, r in ipairs(SCAN.rafts) do
        total = total + 1
        if r.shield then shield = shield + 1
        elseif r.mine then mine = mine + 1
        elseif r.crew then crew = crew + 1
        else enemy = enemy + 1 end
    end
    scanInfoLabel.Text = string.format(
        "Rafts loaded: %d  -  Enemy: %d  -  Mine: %d  -  Crew: %d  -  Shield: %d",
        total, enemy, mine, crew, shield)
end

-- ESP text + tracer refresh (throttled)
local lastESPText = 0
local function ensureTracer(e)
    if e.tracer ~= nil then return e.tracer end
    local f = Instance.new("Frame")
    if e.kind == "shark" then
        f.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
    else
        f.BackgroundColor3 = Color3.fromRGB(150, 200, 255)
    end
    f.BorderSizePixel = 0
    f.AnchorPoint = Vector2.new(0.5, 0.5)
    f.Visible = false
    f.ZIndex = 2
    f.Parent = tracerHolder
    e.tracer = f
    return f
end

bind(RunService.RenderStepped:Connect(function()
    if not RUNNING then return end
    if not (STATE.espChest or STATE.espRaft or STATE.espShark or STATE.espPlayer) then return end
    local t = now()
    if t - lastESPText < 0.1 then return end
    lastESPText = t
    local cam = Camera
    if cam == nil then return end
    local camPos = cam.CFrame.Position
    local vw = cam.ViewportSize
    local originX = vw.X * 0.5
    local originY = vw.Y

    local function upd(reg, inst, e)
        if inst.Parent == nil then
            destroyEntry(e)
            reg[inst] = nil
            return
        end
        local pos = instPos(inst)
        if pos == nil then return end
        local dist = (camPos - pos).Magnitude
        e.label.Text = espTextFor(e, inst, dist)
        if STATE.espTracer and (e.kind == "shark" or e.kind == "player") then
            local sp, onScreen = cam:WorldToViewportPoint(pos)
            if onScreen then
                local f = ensureTracer(e)
                local dx = sp.X - originX
                local dy = sp.Y - originY
                local len = math.sqrt(dx * dx + dy * dy)
                if len > 6 then
                    f.Visible = true
                    f.Position = UDim2.new(0.5, dx * 0.5, 1, dy * 0.5)
                    f.Size = UDim2.new(0, len, 0, 1.5)
                    f.Rotation = math.deg(atan2(dy, dx))
                else
                    f.Visible = false
                end
            elseif e.tracer ~= nil then
                e.tracer.Visible = false
            end
        elseif e.tracer ~= nil then
            e.tracer.Visible = false
        end
    end

    for inst, e in pairs(ESPReg.chest) do upd(ESPReg.chest, inst, e) end
    for inst, e in pairs(ESPReg.raft) do upd(ESPReg.raft, inst, e) end
    for inst, e in pairs(ESPReg.shark) do upd(ESPReg.shark, inst, e) end
    for inst, e in pairs(ESPReg.player) do upd(ESPReg.player, inst, e) end
end))

--=============================================================================--
--  MOVEMENT : GOD / GHOST (floor safe) / WATER WALK / INFINITE JUMP / STATS
--=============================================================================--
-- GOD MODE v2 : invisible ForceField (blocks Humanoid:TakeDamage cold) +
-- 1M HP lock + instant heal + per-frame re-assert + leaderstats HP keeper.
-- (ForceField + MaxHealth lock is what actually works in this game.)
local GOD_MAX = 1000000
local godOriginalMax = 100
local godFF = nil
local godHookedHum = nil
local godHealthCon = nil
local godStatMax = {}

local function ensureForceField(char)
    if char == nil then return nil end
    local ff = char:FindFirstChild("RaftHubGodFF")
    if ff == nil or not ff:IsA("ForceField") then
        ff = Instance.new("ForceField")
        ff.Name = "RaftHubGodFF"
        ff.Visible = false
        ff.Parent = char
    end
    return ff
end

local function hookGod()
    local h = getHumanoid()
    if h == nil then return end
    if godHookedHum ~= h then
        godHookedHum = h
        godOriginalMax = math.max(h.MaxHealth or 100, 1)
    end
    pcall(function()
        h.MaxHealth = GOD_MAX
        h.Health = GOD_MAX
        h:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        h.BreakJointsOnDeath = false
        h.RequiresNeck = false
    end)
    if godHealthCon ~= nil then
        pcall(function() godHealthCon:Disconnect() end)
        godHealthCon = nil
    end
    godHealthCon = h:GetPropertyChangedSignal("Health"):Connect(function()
        if not STATE.god then return end
        if h.Parent ~= nil and h.Health < GOD_MAX then
            pcall(function() h.Health = GOD_MAX end)
        end
    end)
    local ch = getChar()
    if ch ~= nil then godFF = ensureForceField(ch) end
end

local function setGod(on)
    STATE.god = on
    local h = getHumanoid()
    if on then
        if h ~= nil then hookGod() end
    else
        if godHealthCon ~= nil then
            pcall(function() godHealthCon:Disconnect() end)
            godHealthCon = nil
        end
        if godFF ~= nil then
            pcall(function() godFF:Destroy() end)
            godFF = nil
        end
        if h ~= nil then
            pcall(function()
                h:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
                h.RequiresNeck = true
                h.MaxHealth = math.max(godOriginalMax, 1)
                if h.Health > h.MaxHealth then h.Health = h.MaxHealth end
            end)
        end
        godHookedHum = nil
        godStatMax = {}
    end
end

bind(RunService.Heartbeat:Connect(function()
    if not RUNNING or not STATE.god then return end
    local h = getHumanoid()
    if h == nil then return end
    if h.MaxHealth ~= GOD_MAX then
        pcall(function() h.MaxHealth = GOD_MAX end)
    end
    if h.Health < GOD_MAX then
        pcall(function() h.Health = GOD_MAX end)
    end
    if h.BreakJointsOnDeath then h.BreakJointsOnDeath = false end
    local ch = getChar()
    if ch ~= nil and (godFF == nil or godFF.Parent ~= ch) then
        godFF = ensureForceField(ch)
    end
    -- custom HP systems that track health in leaderstats
    pcall(function()
        local ls = LocalPlayer:FindFirstChild("leaderstats")
        if ls ~= nil then
            for _, st in ipairs(ls:GetChildren()) do
                if st:IsA("IntValue") or st:IsA("NumberValue") then
                    local n = string.lower(st.Name)
                    if n == "health" or n == "hp" or n == "life" then
                        local mx = godStatMax[st]
                        if mx == nil or st.Value > mx then
                            godStatMax[st] = st.Value
                            mx = st.Value
                        end
                        if st.Value < mx then st.Value = mx end
                    end
                end
            end
        end
    end)
end))

-- GHOST MODE : pass through walls, NEVER through the floor, no floating.
-- Rule: a part whose top edge is more than 1 stud above foot level is an
-- obstacle (wall) -> noclip it. Floors stay solid so you keep walking.
local noclipParts = {}
local ghostParams = OverlapParams.new()
ghostParams.FilterType = Enum.RaycastFilterType.Exclude
local ghostChar = nil

local function restoreCollisions()
    for p, _ in pairs(noclipParts) do
        pcall(function() if p.Parent ~= nil then p.CanCollide = true end end)
    end
    noclipParts = {}
end

bind(RunService.Stepped:Connect(function()
    if not RUNNING or not STATE.ghost then return end
    local root = getRoot()
    if root == nil then return end
    local ch = getChar()
    if ch ~= ghostChar then
        ghostChar = ch
        if ch ~= nil then ghostParams.FilterDescendantsInstances = { ch } end
    end
    local feetY = root.Position.Y - root.Size.Y * 0.5
    local ok, parts = pcall(function()
        return Workspace:GetPartBoundsInRadius(root.Position, 14, ghostParams)
    end)
    if not ok then return end
    local flagged = {}
    for i = 1, #parts do
        local p = parts[i]
        if p.CanCollide then
            local top = p.Position.Y + p.Size.Y * 0.5
            if top > feetY + 1.0 then
                flagged[p] = true
                noclipParts[p] = true
                p.CanCollide = false
            end
        end
    end
    -- restore parts that fell out of range so nothing stays noclip'd behind you
    for p, _ in pairs(noclipParts) do
        if not flagged[p] then
            pcall(function() if p.Parent ~= nil then p.CanCollide = true end end)
            noclipParts[p] = nil
        end
    end
end))

-- WALK ON WATER : disable swim state + stand on the water surface
local function hitIsWater(hit)
    if hit == nil then return false end
    local nm = string.lower(hit.Instance.Name)
    return hit.Material == Enum.Material.Water
        or string.find(nm, "water", 1, true) ~= nil
        or string.find(nm, "ocean", 1, true) ~= nil
        or string.find(nm, "sea", 1, true) ~= nil
end

local function applySwimState(disableSwim)
    local h = getHumanoid()
    if h ~= nil then
        pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, not disableSwim) end)
    end
end

bind(RunService.Heartbeat:Connect(function()
    if not RUNNING or not STATE.waterwalk then return end
    local root = getRoot()
    if root == nil then return end
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = false
    local ch = getChar()
    if ch ~= nil then rayParams.FilterDescendantsInstances = { ch } end
    local origin = root.Position + Vector3.new(0, 2, 0)
    local hit = Workspace:Raycast(origin, Vector3.new(0, -12, 0), rayParams)
    if not hitIsWater(hit) then
        hit = Workspace:Raycast(origin, Vector3.new(0, 8, 0), rayParams)
    end
    if not hitIsWater(hit) then return end
    local h = getHumanoid()
    local hip = 2
    if h ~= nil and h.HipHeight > 0 then hip = h.HipHeight end
    local targetY = hit.Position.Y + hip + root.Size.Y * 0.5 - 0.35
    if root.Position.Y < targetY + 0.35 then
        local vel = root.AssemblyLinearVelocity
        if vel.Y <= 0.5 then
            root.CFrame = CFrame.new(root.Position.X, targetY, root.Position.Z) * root.CFrame.Rotation
            root.AssemblyLinearVelocity = Vector3.new(vel.X, 0, vel.Z)
        end
    end
end))

-- INFINITE JUMP
bind(UserInputService.JumpRequest:Connect(function()
    if not RUNNING or not STATE.infjump then return end
    local h = getHumanoid()
    if h ~= nil then
        pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end)
    end
end))

-- speed / jump / gravity re-apply loop
task.spawn(function()
    while RUNNING do
        task.wait(0.5)
        pcall(function()
            local h = getHumanoid()
            if h ~= nil then
                if STATE.walkspeed ~= 16 then h.WalkSpeed = STATE.walkspeed end
                if STATE.jumppower ~= 50 then
                    if h.UseJumpPower then
                        h.JumpPower = STATE.jumppower
                    else
                        local g = Workspace.Gravity
                        if g > 0 then h.JumpHeight = (STATE.jumppower * STATE.jumppower) / (2 * g) end
                    end
                end
            end
            if STATE.gravity ~= DEFAULT_GRAVITY then Workspace.Gravity = STATE.gravity end
        end)
    end
end)

--=============================================================================--
--  AUTO STEAL (enemy rafts only -- own / crew / shield rafts are NEVER touched)
--=============================================================================--
local function firePrompt(prompt)
    if not prompt.Enabled then return false end
    pcall(function() prompt.RequiresLineOfSight = false end)
    local hold = tonumber(prompt.HoldDuration) or 0
    if hold > 0.25 then
        local ok = pcall(function() prompt:InputHoldBegin() end)
        if ok then
            task.wait(hold + 0.1)
            pcall(function() prompt:InputHoldEnd() end)
            return true
        end
    end
    if fireproximityprompt ~= nil then
        local ok = pcall(fireproximityprompt, prompt)
        if ok then return true end
    end
    local ok2 = pcall(function() prompt:InputHoldBegin() end)
    if ok2 then
        if hold > 0 then task.wait(hold + 0.1) end
        pcall(function() prompt:InputHoldEnd() end)
        return true
    end
    return false
end

local stealCooldowns = {}

local function raftUnderPlayer()
    local root = getRoot()
    if root == nil then return nil end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ch = getChar()
    if ch ~= nil then params.FilterDescendantsInstances = { ch } end
    local hit = Workspace:Raycast(root.Position, Vector3.new(0, -12, 0), params)
    if hit == nil then return nil end
    local a = hit.Instance
    while a ~= nil and a ~= Workspace do
        for _, r in ipairs(SCAN.rafts) do
            if r.model == a then return r end
        end
        a = a.Parent
    end
    return nil
end

local function autoStealStep()
    local root = getRoot()
    local h = getHumanoid()
    if root == nil or h == nil then
        STATE.stealMsg = "Waiting for character..."
        return
    end
    if h.Health <= 0 then return end
    local t = now()

    -- if you are standing on an ENEMY raft we switch to assist mode:
    -- fire nearby prompts only, never teleport you, never fight your manual play
    local stood = raftUnderPlayer()
    local assistMode = stood ~= nil and (not stood.mine) and (not stood.crew)

    local bestChest, bestPrompt, bestRaft, bestDist, bestPos
    local skippedCooling = 0

    for _, r in ipairs(SCAN.rafts) do
        if (not r.mine) and (not r.crew) and (not r.shield) then
            local cdUntil = stealCooldowns[r.model] or 0
            if t >= cdUntil then
                for _, chest in ipairs(r.chests) do
                    local prompt = findStealPrompt(chest)
                    local cpos = nil
                    if prompt ~= nil then cpos = promptPos(prompt) end
                    if cpos == nil then cpos = instPos(chest) end
                    if cpos ~= nil then
                        local dist = (cpos - root.Position).Magnitude
                        if dist <= STATE.stealRange then
                            if assistMode then
                                local range = (prompt ~= nil and prompt.MaxActivationDistance or 10) + 2
                                if dist <= range and (bestDist == nil or dist < bestDist) then
                                    bestChest, bestPrompt, bestRaft, bestDist, bestPos = chest, prompt, r, dist, cpos
                                end
                            elseif bestDist == nil or dist < bestDist then
                                bestChest, bestPrompt, bestRaft, bestDist, bestPos = chest, prompt, r, dist, cpos
                            end
                        end
                    end
                end
            else
                skippedCooling = skippedCooling + 1
            end
        end
    end

    if bestChest == nil then
        if skippedCooling > 0 then
            STATE.stealMsg = "Cooling down..."
        elseif assistMode then
            STATE.stealMsg = "On enemy raft: get closer to a chest to steal it"
        else
            STATE.stealMsg = "No enemy rafts loaded nearby - sail closer"
        end
        return
    end

    local seat = nil
    if h.Seated and h.SeatPart ~= nil then seat = h.SeatPart end
    local savedCF = root.CFrame
    local teleported = false

    local maxDist = (bestPrompt ~= nil and bestPrompt.MaxActivationDistance or 10) * 0.8 + 2
    if bestDist > maxDist then
        if assistMode then return end
        if seat ~= nil then
            h.Sit = false
            task.wait(0.12)
        end
        local dir = root.Position - bestPos
        local flat = Vector3.new(dir.X, 0, dir.Z)
        if flat.Magnitude < 0.5 then
            flat = Vector3.new(1, 0, 0)
        else
            flat = flat.Unit
        end
        local tpPos = bestPos + flat * 4 + Vector3.new(0, 3, 0)
        root.CFrame = CFrame.lookAt(tpPos, bestPos)
        teleported = true
        task.wait(0.15)
    end

    local fired = false
    if bestPrompt ~= nil then
        fired = firePrompt(bestPrompt)
    else
        local det = bestChest:FindFirstChildWhichIsA("ClickDetector", true)
        if det ~= nil and fireclickdetector ~= nil then
            fired = pcall(fireclickdetector, det)
        elseif firetouchinterest ~= nil then
            pcall(firetouchinterest, root, bestChest, 0)
            pcall(firetouchinterest, root, bestChest, 1)
            fired = true
        end
    end

    task.wait(0.2)

    STATE.stealCount = STATE.stealCount + 1
    STATE.lastStealTarget = "?"
    if bestRaft.owner ~= nil then
        STATE.lastStealTarget = bestRaft.owner.Name
    elseif bestRaft.name ~= nil then
        STATE.lastStealTarget = bestRaft.name
    end
    STATE.nextStealAt = now() + STATE.stealCooldown
    stealCooldowns[bestRaft.model] = now() + STATE.stealCooldown
    STATE.stealMsg = string.format("Stole from %s%s raft", STATE.lastStealTarget, fired and "" or " (no prompt - touch mode)")
    notify("Auto Steal", "Stole a chest from " .. STATE.lastStealTarget .. "'s raft", 2.5)

    if teleported and STATE.autoReturn then
        if seat ~= nil and seat.Parent ~= nil then
            root.CFrame = CFrame.new(seat.Position + Vector3.new(0, 4, 0))
            task.wait(0.4) -- let the seat grab you again
        else
            root.CFrame = savedCF
        end
    end
end

--=============================================================================--
--  TELEPORTS
--=============================================================================--
local function ensureFreshScan()
    pcall(fullScan)
    pcall(updateScanInfo)
end

local function enemyRaftList()
    local list = {}
    for _, r in ipairs(SCAN.rafts) do
        if (not r.mine) and (not r.crew) and (not r.shield) then
            list[#list + 1] = r
        end
    end
    return list
end

local function unseatForTP()
    local h = getHumanoid()
    if h ~= nil and h.Seated then
        h.Sit = false
        task.wait(0.1)
    end
end

local function tpTo(cfOrPos)
    local root = getRoot()
    if root == nil then
        notify("Teleport", "No character found")
        return false
    end
    unseatForTP()
    if typeof(cfOrPos) == "CFrame" then
        root.CFrame = cfOrPos
    else
        root.CFrame = CFrame.new(cfOrPos)
    end
    return true
end

local function raftLandPos(r)
    local p = nil
    if r.topChest ~= nil then p = instPos(r.topChest) end
    if p == nil then p = r.center end
    if p == nil then
        local part = r.model:FindFirstChildWhichIsA("BasePart", true)
        if part ~= nil then p = part.Position end
    end
    if p == nil then return nil end
    return p + Vector3.new(0, 6, 0)
end

local function tpToRaft(r)
    if r == nil then return end
    local land = raftLandPos(r)
    if land == nil then
        notify("Teleport", "Could not resolve that raft's position")
        return
    end
    if tpTo(land) then
        local who = "?"
        if r.owner ~= nil then who = r.owner.Name elseif r.name ~= nil then who = r.name end
        local val
        if r.known > 0 then val = fmtNum(r.wealth)
        elseif r.wealthFrom == "owner" then val = fmtNum(r.wealth) .. " owner gold"
        else val = string.format("%d chests", #r.chests) end
        notify("Teleport", "Teleported to " .. who .. "'s raft - " .. val)
    end
end

-- TP to RICH / TP to POOR (fixed sorting, always different rafts when possible)
local function tpByWealth(wantRich)
    ensureFreshScan()
    local list = enemyRaftList()
    if #list == 0 then
        notify("Teleport", "No enemy rafts found. The server only loads rafts near you - sail closer and retry.")
        return
    end
    if wantRich then
        table.sort(list, function(a, b) return a.wealth > b.wealth end)
    else
        table.sort(list, function(a, b) return a.wealth < b.wealth end)
    end
    local pick = list[1]
    if (not wantRich) and #list >= 2 and list[1].wealth == list[2].wealth then
        pick = list[2]
    end
    tpToRaft(pick)
    if #list == 1 then
        notify("Teleport", "Only 1 enemy raft is loaded nearby, so Rich and Poor point at the same raft.")
    end
end

local function tpNearestEnemy()
    ensureFreshScan()
    local list = enemyRaftList()
    local root = getRoot()
    if #list == 0 or root == nil then
        notify("Teleport", "No enemy rafts found nearby")
        return
    end
    local rp = root.Position
    local best, bd = nil, nil
    for _, r in ipairs(list) do
        local p = r.center
        if p == nil and r.topChest ~= nil then p = instPos(r.topChest) end
        if p ~= nil then
            local d = (p - rp).Magnitude
            if bd == nil or d < bd then best, bd = r, d end
        end
    end
    if best ~= nil then
        tpToRaft(best)
    else
        notify("Teleport", "No enemy rafts found nearby")
    end
end

local function tpNearestChest()
    ensureFreshScan()
    local root = getRoot()
    if root == nil then return end
    local best, bd, bp = nil, nil, nil
    for _, r in ipairs(SCAN.rafts) do
        if (not r.mine) and (not r.crew) and (not r.shield) then
            for _, c in ipairs(r.chests) do
                local p = instPos(c)
                if p ~= nil then
                    local d = (p - root.Position).Magnitude
                    if bd == nil or d < bd then best, bd, bp = c, d, p end
                end
            end
        end
    end
    if bp ~= nil then
        if tpTo(CFrame.lookAt(bp + Vector3.new(0, 5, 0), bp)) then
            notify("Teleport", "Teleported to the nearest enemy raft chest")
        end
    else
        notify("Teleport", "No enemy chests found nearby")
    end
end

local function setMyRaft(silent)
    local root = getRoot()
    if root == nil then return false end
    ensureFreshScan()
    local r = raftUnderPlayer()
    if r ~= nil then
        STATE.myRaft = r.model
        if not silent then
            notify("My Raft", "Marked '" .. r.name .. "' as YOUR raft - excluded from auto steal and enemy TP")
        end
        return true
    end
    if not silent then
        notify("My Raft", "No raft detected under you. Stand ON your raft and press again.")
    end
    return false
end

local function tpMyRaft()
    if STATE.myRaft == nil or STATE.myRaft.Parent == nil then
        notify("Teleport", "My Raft is not set - stand on your raft and press 'Set MY Raft'")
        return
    end
    local entry = nil
    for _, r in ipairs(SCAN.rafts) do
        if r.model == STATE.myRaft then entry = r break end
    end
    local land = nil
    if entry ~= nil then
        land = raftLandPos(entry)
    else
        local part = STATE.myRaft:FindFirstChildWhichIsA("BasePart", true)
        if part ~= nil then land = part.Position + Vector3.new(0, 6, 0) end
    end
    if land ~= nil and tpTo(land) then
        notify("Teleport", "Teleported to your raft")
    else
        notify("Teleport", "Could not resolve your raft's position")
    end
end

local function savePos()
    local root = getRoot()
    if root ~= nil then
        STATE.savedCF = root.CFrame
        notify("Position", "Saved your current position")
    end
end

local function tpBack()
    local root = getRoot()
    if root == nil or STATE.savedCF == nil then
        notify("Position", "No saved position yet")
        return
    end
    unseatForTP()
    root.CFrame = STATE.savedCF
    notify("Position", "Returned to your saved position")
end

-- player selector
local selectedPlayer = nil
local function cyclePlayer(dirn)
    local others = {}
    local list = Players:GetPlayers()
    for i = 1, #list do
        if list[i] ~= LocalPlayer then others[#others + 1] = list[i] end
    end
    if #others == 0 then
        selectedPlayer = nil
        return
    end
    local idx = 1
    if selectedPlayer ~= nil then
        for i = 1, #others do
            if others[i] == selectedPlayer then idx = i break end
        end
    end
    idx = ((idx - 1 + dirn) % #others) + 1
    selectedPlayer = others[idx]
end

local function tpToSelectedPlayer()
    if selectedPlayer == nil or selectedPlayer.Character == nil then
        notify("Players", "Select a player first (< >)")
        return
    end
    local c = selectedPlayer.Character
    local root = c:FindFirstChild("HumanoidRootPart")
    if root == nil then
        notify("Players", "That player has no character right now")
        return
    end
    if tpTo(root.CFrame * CFrame.new(0, 0, 4)) then
        notify("Players", "Teleported to " .. selectedPlayer.Name)
    end
end

--=============================================================================--
--  GRAPHICS : FULLBRIGHT / FPS BOOST / INSTANT INTERACT
--=============================================================================--
local FB = { saved = nil, fx = {} }
local function setFullbright(on)
    if on then
        if FB.saved == nil then
            FB.saved = {
                ClockTime = Lighting.ClockTime,
                Brightness = Lighting.Brightness,
                FogEnd = Lighting.FogEnd,
                FogStart = Lighting.FogStart,
                GlobalShadows = Lighting.GlobalShadows,
                ExposureCompensation = Lighting.ExposureCompensation,
                Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient,
            }
        end
        pcall(function()
            Lighting.ClockTime = 14
            Lighting.Brightness = 2
            Lighting.FogEnd = 100000
            Lighting.FogStart = 98000
            Lighting.GlobalShadows = false
            Lighting.ExposureCompensation = 0.25
            Lighting.Ambient = Color3.fromRGB(120, 120, 130)
            Lighting.OutdoorAmbient = Color3.fromRGB(160, 160, 170)
        end)
        for _, e in ipairs(Lighting:GetChildren()) do
            local cn = e.ClassName
            if cn == "Atmosphere" or cn == "BloomEffect" or cn == "SunRaysEffect"
                or cn == "BlurEffect" or cn == "DepthOfFieldEffect" then
                if e.Enabled then
                    e.Enabled = false
                    FB.fx[#FB.fx + 1] = e
                end
            end
        end
    else
        if FB.saved ~= nil then
            pcall(function()
                for k, v in pairs(FB.saved) do Lighting[k] = v end
            end)
            FB.saved = nil
        end
        for i = #FB.fx, 1, -1 do
            pcall(function() FB.fx[i].Enabled = true end)
            FB.fx[i] = nil
        end
    end
end

local FX = { quality = nil, items = {}, conn = nil }
local function setFPSBoost(on)
    if on then
        pcall(function()
            FX.quality = settings().Rendering.QualityLevel
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
        pcall(function() Lighting.GlobalShadows = false end)
        local ok, descs = pcall(function() return Workspace:GetDescendants() end)
        if ok then
            for i = 1, #descs do
                local d = descs[i]
                local cn = d.ClassName
                if (cn == "ParticleEmitter" or cn == "Trail" or cn == "Beam"
                    or cn == "Fire" or cn == "Smoke" or cn == "Sparkles") and d.Enabled then
                    d.Enabled = false
                    FX.items[#FX.items + 1] = d
                end
            end
        end
        FX.conn = Workspace.DescendantAdded:Connect(function(d)
            task.defer(function()
                local cn = d.ClassName
                if cn == "ParticleEmitter" or cn == "Trail" or cn == "Beam"
                    or cn == "Fire" or cn == "Smoke" or cn == "Sparkles" then
                    if d.Enabled then
                        d.Enabled = false
                        FX.items[#FX.items + 1] = d
                    end
                end
            end)
        end)
    else
        pcall(function()
            if FX.quality ~= nil then settings().Rendering.QualityLevel = FX.quality end
        end)
        FX.quality = nil
        for i = #FX.items, 1, -1 do
            pcall(function() FX.items[i].Enabled = true end)
            FX.items[i] = nil
        end
        if FX.conn ~= nil then
            FX.conn:Disconnect()
            FX.conn = nil
        end
    end
end

-- INSTANT INTERACT : all hold prompts become instant (also helps manual stealing)
local holdOrig = {}
local iiConn = nil
local function setInstantInteract(on)
    if on then
        local ok, descs = pcall(function() return Workspace:GetDescendants() end)
        if ok then
            for i = 1, #descs do
                local d = descs[i]
                if d:IsA("ProximityPrompt") and d.HoldDuration > 0 then
                    holdOrig[d] = d.HoldDuration
                    d.HoldDuration = 0
                end
            end
        end
        iiConn = Workspace.DescendantAdded:Connect(function(d)
            task.defer(function()
                if d:IsA("ProximityPrompt") and d.HoldDuration > 0 then
                    holdOrig[d] = d.HoldDuration
                    d.HoldDuration = 0
                end
            end)
        end)
    else
        for p, v in pairs(holdOrig) do
            pcall(function() if p.Parent ~= nil then p.HoldDuration = v end end)
        end
        holdOrig = {}
        if iiConn ~= nil then
            iiConn:Disconnect()
            iiConn = nil
        end
    end
end

--=============================================================================--
--  RECOVERY
--=============================================================================--
local function fixCharacter()
    pcall(function()
        if STATE.ghost then
            STATE.ghost = false
            if Toggles.ghost ~= nil then Toggles.ghost.set(false, false) end
            restoreCollisions()
        end
        local h = getHumanoid()
        if h ~= nil then
            h.Sit = false
            h:ChangeState(Enum.HumanoidStateType.GettingUp)
            h:SetStateEnabled(Enum.HumanoidStateType.Swimming, not STATE.waterwalk)
            if STATE.god then h.Health = h.MaxHealth end
        end
        stealCooldowns = {}
        STATE.nextStealAt = 0
        notify("Fix Character", "State repaired: collisions restored, seat released, cooldowns cleared")
    end)
end

local function respawnChar()
    pcall(function()
        setGod(false)
        if Toggles.god ~= nil then Toggles.god.set(false, false) end
        local h = getHumanoid()
        if h ~= nil then h.Health = 0 end
    end)
end

--=============================================================================--
--  UI : fixed compact window + scrollable tabs
--=============================================================================--
local ACCENT   = Color3.fromRGB(0, 210, 175)
local ACCENT_D = Color3.fromRGB(0, 145, 120)
local BG       = Color3.fromRGB(15, 18, 24)
local BG2      = Color3.fromRGB(21, 26, 34)
local BG3      = Color3.fromRGB(29, 36, 47)
local BG_HOV   = Color3.fromRGB(26, 32, 42)
local STROKE   = Color3.fromRGB(44, 54, 68)
local TEXT     = Color3.fromRGB(235, 240, 245)
local SUB      = Color3.fromRGB(135, 148, 165)
local COL_BAR  = Color3.fromRGB(38, 46, 58)
local COL_TRK  = Color3.fromRGB(45, 54, 67)

local function mk(class, props, parent)
    local inst = Instance.new(class)
    if props ~= nil then
        for k, v in pairs(props) do
            if k ~= "Parent" then inst[k] = v end
        end
    end
    if inst:IsA("GuiObject") then inst.BorderSizePixel = 0 end
    if parent ~= nil then inst.Parent = parent end
    return inst
end
local function corner(r, parent)
    return mk("UICorner", { CornerRadius = UDim.new(0, r) }, parent)
end
local function addStroke(parent, c, t)
    return mk("UIStroke", { Color = c or STROKE, Thickness = t or 1, Transparency = 0.3 }, parent)
end

local layoutCounter = 0
local function nextOrder()
    layoutCounter = layoutCounter + 1
    return layoutCounter
end

-- window (FIXED SIZE, small) ---------------------------------------------------
local Win = mk("Frame", {
    Size = UDim2.new(0, 480, 0, 330),
    Position = UDim2.new(0.5, -240, 0.5, -180),
    BackgroundColor3 = BG,
    Active = true,
}, Gui)
corner(10, Win)
addStroke(Win)
local WinScale = mk("UIScale", { Scale = 0.92 }, Win)
TweenService:Create(WinScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

-- floating reopen dot
local openDot = mk("TextButton", {
    Visible = false,
    Position = UDim2.new(0, 14, 0, 14),
    Size = UDim2.new(0, 46, 0, 46),
    BackgroundColor3 = BG,
    AutoButtonColor = false,
    Text = "RH",
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    TextColor3 = ACCENT,
    ZIndex = 50,
}, Gui)
corner(14, openDot)
addStroke(openDot)

local function hideUI()
    Win.Visible = false
    openDot.Visible = true
end
local function showUI()
    Win.Visible = true
    openDot.Visible = false
end
openDot.Activated:Connect(showUI)

-- title bar
local TitleBar = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 38),
    BackgroundColor3 = BG2,
}, Win)
corner(10, TitleBar)
mk("Frame", {
    Position = UDim2.new(0, 0, 1, -10),
    Size = UDim2.new(1, 0, 0, 10),
    BackgroundColor3 = BG2,
}, TitleBar)

mk("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 0),
    Size = UDim2.new(1, -110, 1, 0),
    Font = Enum.Font.GothamBold,
    Text = "RAFT HUB",
    TextColor3 = TEXT,
    TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Left,
}, TitleBar)
mk("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 92, 0, 0),
    Size = UDim2.new(0, 60, 1, 0),
    Font = Enum.Font.GothamBold,
    Text = "v3.0",
    TextColor3 = ACCENT,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
}, TitleBar)

local function topBtn(txt, xPos)
    local b = mk("TextButton", {
        Position = UDim2.new(1, xPos, 0, 6),
        Size = UDim2.new(0, 26, 0, 26),
        BackgroundColor3 = BG3,
        Text = txt,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = SUB,
        AutoButtonColor = false,
    }, TitleBar)
    corner(6, b)
    b.MouseEnter:Connect(function() b.BackgroundColor3 = BG_HOV end)
    b.MouseLeave:Connect(function() b.BackgroundColor3 = BG3 end)
    b.Activated:Connect(hideUI)
    return b
end
topBtn("-", -64)
topBtn("x", -32)

-- drag
do
    local dragging = false
    local dragStart, startPos
    TitleBar.InputBegan:Connect(function(io)
        if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = io.Position
            startPos = Win.Position
        end
    end)
    bind(UserInputService.InputChanged:Connect(function(io)
        if dragging and (io.UserInputType == Enum.UserInputType.MouseMovement or io.UserInputType == Enum.UserInputType.Touch) then
            local delta = io.Position - dragStart
            Win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))
    bind(UserInputService.InputEnded:Connect(function(io)
        if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
end

-- tab row
local tabNames = { "MAIN", "VISUALS", "TELEPORT", "MOVEMENT" }
local TabRow = mk("Frame", {
    Position = UDim2.new(0, 0, 0, 38),
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundTransparency = 1,
}, Win)
mk("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
}, TabRow)

local Tabs = {}
local tabBtns = {}
local function selectTab(i)
    for j = 1, #tabBtns do
        local on = (i == j)
        tabBtns[j].label.TextColor3 = on and ACCENT or SUB
        tabBtns[j].under.BackgroundTransparency = on and 0 or 1
        Tabs[j].Visible = on
    end
end

-- content area
local Content = mk("Frame", {
    Position = UDim2.new(0, 6, 0, 72),
    Size = UDim2.new(1, -12, 1, -80),
    BackgroundTransparency = 1,
}, Win)

local function makeTabScroll()
    local sf = mk("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = ACCENT,
        ScrollBarImageTransparency = 0.4,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
    }, Content)
    mk("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, sf)
    mk("UIPadding", {
        PaddingTop = UDim.new(0, 2),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 2),
        PaddingRight = UDim.new(0, 6),
    }, sf)
    return sf
end
for i = 1, #tabNames do
    Tabs[i] = makeTabScroll()
    Tabs[i].Visible = (i == 1)
end

for i, nm in ipairs(tabNames) do
    local b = mk("TextButton", {
        Size = UDim2.new(0, 110, 1, -4),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        LayoutOrder = i,
    }, TabRow)
    local l = mk("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, -4),
        Font = Enum.Font.GothamBold,
        Text = nm,
        TextSize = 11,
        TextColor3 = SUB,
    }, b)
    local u = mk("Frame", {
        Position = UDim2.new(0.5, -14, 1, -2),
        Size = UDim2.new(0, 28, 0, 2),
        BackgroundColor3 = ACCENT,
        BackgroundTransparency = 1,
    }, b)
    tabBtns[#tabBtns + 1] = { label = l, under = u }
    b.Activated:Connect(function() selectTab(i) end)
end

-- components -------------------------------------------------------------------
local function section(parent, title)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = SUB,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = nextOrder(),
    }, parent)
end

local function addToggle(parent, title, default, cb)
    local row = mk("TextButton", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = BG2,
        AutoButtonColor = false,
        Text = "",
        LayoutOrder = nextOrder(),
    }, parent)
    corner(8, row)
    addStroke(row)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -66, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = title,
        TextColor3 = TEXT,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local track = mk("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.new(0, 38, 0, 18),
        BackgroundColor3 = COL_TRK,
    }, row)
    corner(9, track)
    local knob = mk("Frame", {
        Position = UDim2.new(0, 2, 0.5, -7),
        Size = UDim2.new(0, 14, 0, 14),
        BackgroundColor3 = Color3.fromRGB(170, 180, 195),
    }, track)
    corner(7, knob)

    local state = default and true or false
    local handle = {}
    local function set(v, fire)
        state = v and true or false
        TweenService:Create(track, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { BackgroundColor3 = state and ACCENT_D or COL_TRK }):Play()
        TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
              BackgroundColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(170, 180, 195) }):Play()
        if fire ~= false then
            local ok, err = pcall(cb, state)
            if not ok then warn("[RaftHub] toggle error: " .. tostring(err)) end
        end
    end
    row.Activated:Connect(function() set(not state) end)
    row.MouseEnter:Connect(function() row.BackgroundColor3 = BG_HOV end)
    row.MouseLeave:Connect(function() row.BackgroundColor3 = BG2 end)
    set(state, false)
    handle.set = set
    return handle
end

local function addSlider(parent, title, minv, maxv, def, suffix, cb)
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = BG2,
        LayoutOrder = nextOrder(),
    }, parent)
    corner(8, row)
    addStroke(row)
    mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 3),
        Size = UDim2.new(1, -116, 0, 18),
        Font = Enum.Font.GothamMedium,
        Text = title,
        TextColor3 = TEXT,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local valLab = mk("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 3),
        Size = UDim2.new(0, 100, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = tostring(def) .. suffix,
        TextColor3 = ACCENT,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, row)
    local bar = mk("Frame", {
        Position = UDim2.new(0, 10, 0, 27),
        Size = UDim2.new(1, -20, 0, 6),
        BackgroundColor3 = COL_BAR,
    }, row)
    corner(3, bar)

    local value = def
    local function alpha()
        return (value - minv) / (maxv - minv)
    end
    local fill = mk("Frame", { Size = UDim2.new(alpha(), 0, 1, 0), BackgroundColor3 = ACCENT }, bar)
    corner(3, fill)
    local grab = mk("TextButton", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, -6, 0, -5),
        Size = UDim2.new(1, 12, 0, 16),
        Text = "",
        AutoButtonColor = false,
    }, bar)

    local dragging = false
    local function updateFromX(x)
        local rel = (x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1)
        if rel < 0 then rel = 0 elseif rel > 1 then rel = 1 end
        value = math.floor(minv + (maxv - minv) * rel + 0.5)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        valLab.Text = tostring(value) .. suffix
        local ok, err = pcall(cb, value)
        if not ok then warn("[RaftHub] slider error: " .. tostring(err)) end
    end
    grab.InputBegan:Connect(function(io)
        if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromX(io.Position.X)
        end
    end)
    bind(UserInputService.InputChanged:Connect(function(io)
        if dragging and (io.UserInputType == Enum.UserInputType.MouseMovement or io.UserInputType == Enum.UserInputType.Touch) then
            updateFromX(io.Position.X)
        end
    end))
    bind(UserInputService.InputEnded:Connect(function(io)
        if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    local handle = {}
    handle.set = function(v)
        value = v
        fill.Size = UDim2.new(alpha(), 0, 1, 0)
        valLab.Text = tostring(v) .. suffix
        pcall(cb, v)
    end
    return handle
end

local function addButton(parent, title, cb)
    local b = mk("TextButton", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = BG3,
        AutoButtonColor = false,
        Text = title,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = TEXT,
        LayoutOrder = nextOrder(),
    }, parent)
    corner(8, b)
    addStroke(b)
    b.MouseEnter:Connect(function() b.BackgroundColor3 = BG_HOV end)
    b.MouseLeave:Connect(function() b.BackgroundColor3 = BG3 end)
    b.Activated:Connect(function()
        b.BackgroundColor3 = ACCENT_D
        task.delay(0.12, function() b.BackgroundColor3 = BG3 end)
        local ok, err = pcall(cb)
        if not ok then warn("[RaftHub] button error: " .. tostring(err)) end
    end)
    return b
end

local function addInfo(parent, height)
    local l = mk("TextLabel", {
        Size = UDim2.new(1, 0, 0, height or 36),
        BackgroundColor3 = Color3.fromRGB(13, 17, 23),
        Font = Enum.Font.Gotham,
        Text = "",
        TextColor3 = SUB,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        LayoutOrder = nextOrder(),
    }, parent)
    corner(8, l)
    addStroke(l)
    mk("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, l)
    return l
end

local function addPlayerSelector(parent)
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        LayoutOrder = nextOrder(),
    }, parent)
    local prevB = mk("TextButton", {
        Size = UDim2.new(0, 32, 1, 0),
        BackgroundColor3 = BG3,
        Text = "<",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = TEXT,
        AutoButtonColor = false,
    }, row)
    corner(8, prevB)
    addStroke(prevB)
    local lab = mk("TextLabel", {
        Position = UDim2.new(0, 38, 0, 0),
        Size = UDim2.new(1, -76, 1, 0),
        BackgroundColor3 = BG2,
        Font = Enum.Font.GothamMedium,
        Text = "No player",
        TextColor3 = SUB,
        TextSize = 13,
    }, row)
    corner(8, lab)
    addStroke(lab)
    local nextB = mk("TextButton", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 32, 1, 0),
        BackgroundColor3 = BG3,
        Text = ">",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = TEXT,
        AutoButtonColor = false,
    }, row)
    corner(8, nextB)
    addStroke(nextB)
    prevB.Activated:Connect(function() cyclePlayer(-1) end)
    nextB.Activated:Connect(function() cyclePlayer(1) end)
    return lab
end

--=============================================================================--
--  TAB CONTENT
--=============================================================================--
-- MAIN -----------------------------------------------------------------------
local T1 = Tabs[1]
section(T1, "AUTO STEAL")
Toggles.autosteal = addToggle(T1, "Auto Steal Chests (enemy rafts only)", false, function(v)
    STATE.autosteal = v
    if v then
        task.spawn(function() pcall(fullScan) end)
        notify("Auto Steal", "ON - steals only from ENEMY rafts. Your raft, crew rafts and shield rafts are skipped. It teleports back automatically.", 4)
    else
        STATE.stealMsg = "Auto steal off"
    end
end)
Sliders.cooldown = addSlider(T1, "Steal Cooldown", 2, 30, 8, "s", function(v)
    STATE.stealCooldown = v
end)
Sliders.range = addSlider(T1, "Steal Range", 100, 2000, 1000, " studs", function(v)
    STATE.stealRange = v
end)
Toggles.autoreturn = addToggle(T1, "Return to my position after steal", true, function(v)
    STATE.autoReturn = v
end)
stealStatusLabel = addInfo(T1, 44)

section(T1, "MOVEMENT")
Toggles.god = addToggle(T1, "God Mode", false, function(v)
    setGod(v)
end)
Toggles.ghost = addToggle(T1, "Ghost Mode (through walls, keeps floor)", false, function(v)
    STATE.ghost = v
    if not v then
        restoreCollisions()
        local h = getHumanoid()
        if h ~= nil then pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end) end
    end
end)
Toggles.water = addToggle(T1, "Walk on Water", false, function(v)
    STATE.waterwalk = v
    applySwimState(v)
end)
Toggles.infjump = addToggle(T1, "Infinite Jump", false, function(v)
    STATE.infjump = v
end)

section(T1, "UTILITY")
Toggles.instant = addToggle(T1, "Instant Interact (0s hold on prompts)", false, function(v)
    STATE.instant = v
    setInstantInteract(v)
end)
addButton(T1, "Fix Character (un-glitch)", fixCharacter)
addButton(T1, "Respawn Character", respawnChar)

-- VISUALS --------------------------------------------------------------------
local T2 = Tabs[2]
section(T2, "ESP")
Toggles.chest = addToggle(T2, "Chest ESP (raft chests only)", false, function(v)
    STATE.espChest = v
    if not v then purgeKind("chest", nil) end
    task.spawn(function() pcall(function() fullScan() refreshESP() end) end)
end)
Toggles.raft = addToggle(T2, "Raft ESP (owner + wealth)", false, function(v)
    STATE.espRaft = v
    if not v then purgeKind("raft", nil) end
    task.spawn(function() pcall(function() fullScan() refreshESP() end) end)
end)
Toggles.shark = addToggle(T2, "Shark ESP", false, function(v)
    STATE.espShark = v
    if not v then purgeKind("shark", nil) end
    task.spawn(function() pcall(function() fullScan() refreshESP() end) end)
end)
Toggles.playeresp = addToggle(T2, "Player ESP", false, function(v)
    STATE.espPlayer = v
    if not v then purgeKind("player", nil) end
end)
Toggles.tracer = addToggle(T2, "Tracers (sharks + players)", false, function(v)
    STATE.espTracer = v
    if not v then
        for _, reg in pairs(ESPReg) do
            for _, e in pairs(reg) do
                if e.tracer ~= nil then
                    e.tracer:Destroy()
                    e.tracer = nil
                end
            end
        end
    end
end)
Toggles.showmine = addToggle(T2, "Show my / crew rafts in ESP", false, function(v)
    STATE.showMine = v
    task.spawn(function() pcall(function() fullScan() refreshESP() end) end)
end)
section(T2, "GRAPHICS")
Toggles.fullbright = addToggle(T2, "Fullbright", false, function(v)
    STATE.fullbright = v
    setFullbright(v)
end)
Toggles.fps = addToggle(T2, "FPS Boost", false, function(v)
    STATE.fpsboost = v
    setFPSBoost(v)
end)

-- TELEPORT -------------------------------------------------------------------
local T3 = Tabs[3]
section(T3, "RAFT TELEPORTS")
scanInfoLabel = addInfo(T3, 30)
addButton(T3, "TP to RICHEST Raft", function() tpByWealth(true) end)
addButton(T3, "TP to POOREST Raft", function() tpByWealth(false) end)
addButton(T3, "TP to Nearest Enemy Raft", tpNearestEnemy)
addButton(T3, "TP to Nearest Enemy Chest", tpNearestChest)
addButton(T3, "TP to MY Raft", tpMyRaft)
addButton(T3, "Set MY Raft (stand on it first)", function() setMyRaft(false) end)
section(T3, "POSITION")
addButton(T3, "Save Current Position", savePos)
addButton(T3, "Return to Saved Position", tpBack)
section(T3, "PLAYERS")
playerLabel = addPlayerSelector(T3)
addButton(T3, "TP to Selected Player", tpToSelectedPlayer)

-- MOVEMENT -------------------------------------------------------------------
local T4 = Tabs[4]
section(T4, "CHARACTER")
Sliders.speed = addSlider(T4, "Walk Speed", 16, 250, 16, "", function(v)
    STATE.walkspeed = v
end)
Sliders.jump = addSlider(T4, "Jump Power", 20, 300, 50, "", function(v)
    STATE.jumppower = v
end)
section(T4, "WORLD")
Sliders.grav = addSlider(T4, "Gravity", 50, 500, 196, "", function(v)
    STATE.gravity = v
end)
addButton(T4, "Reset Movement Values", function()
    STATE.walkspeed = 16
    STATE.jumppower = 50
    STATE.gravity = DEFAULT_GRAVITY
    Sliders.speed.set(16)
    Sliders.jump.set(50)
    Sliders.grav.set(196)
    pcall(function()
        local h = getHumanoid()
        if h ~= nil then
            h.WalkSpeed = 16
            h.JumpPower = 50
        end
        Workspace.Gravity = DEFAULT_GRAVITY
    end)
    notify("Movement", "Values reset to defaults")
end)

selectTab(1)

-- toasts ----------------------------------------------------------------------
local ToastList = mk("Frame", {
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -14, 1, -14),
    Size = UDim2.new(0, 300, 1, -80),
    BackgroundTransparency = 1,
}, Gui)
mk("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
}, ToastList)

notify = function(title, msg, dur)
    pcall(function()
        local kids = {}
        for _, c in ipairs(ToastList:GetChildren()) do
            if c:IsA("Frame") then kids[#kids + 1] = c end
        end
        if #kids >= 5 then kids[1]:Destroy() end
        local t = mk("Frame", {
            Size = UDim2.new(1, 0, 0, 52),
            BackgroundColor3 = Color3.fromRGB(17, 21, 28),
            LayoutOrder = layoutCounter + 1000,
        }, ToastList)
        corner(8, t)
        addStroke(t)
        mk("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 6),
            Size = UDim2.new(1, -20, 0, 16),
            Font = Enum.Font.GothamBold,
            Text = title,
            TextColor3 = ACCENT,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, t)
        mk("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 23),
            Size = UDim2.new(1, -20, 0, 26),
            Font = Enum.Font.Gotham,
            Text = msg,
            TextColor3 = SUB,
            TextSize = 11,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
        }, t)
        local sc = mk("UIScale", { Scale = 0.85 }, t)
        TweenService:Create(sc, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
        task.delay(dur or 3.5, function()
            pcall(function()
                local tw = TweenService:Create(sc, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.7 })
                tw:Play()
                task.delay(0.22, function() pcall(function() t:Destroy() end) end)
            end)
        end)
    end)
end

-- hotkey
bind(UserInputService.InputBegan:Connect(function(io, gp)
    if gp then return end
    if io.KeyCode == Enum.KeyCode.RightControl then
        if Win.Visible then hideUI() else showUI() end
    end
end))

--=============================================================================--
--  RUNTIME LOOPS
--=============================================================================--
task.spawn(function()
    while RUNNING do
        local active = STATE.autosteal or STATE.espChest or STATE.espRaft or STATE.espShark or STATE.espPlayer
        pcall(function()
            if active then
                fullScan()
                refreshESP()
                updateScanInfo()
            end
        end)
        task.wait(active and 2.5 or 8)
    end
end)

task.spawn(function()
    while RUNNING do
        task.wait(0.5)
        if STATE.autosteal then
            local ok, err = pcall(autoStealStep)
            if not ok then warn("[RaftHub] auto steal error: " .. tostring(err)) end
        end
    end
end)

task.spawn(function()
    while RUNNING do
        task.wait(0.3)
        if stealStatusLabel ~= nil then
            if STATE.autosteal then
                local remain = STATE.nextStealAt - now()
                if remain < 0 then remain = 0 end
                local nextTxt = "ready"
                if remain > 0 then nextTxt = string.format("%ds", math.ceil(remain)) end
                stealStatusLabel.Text = STATE.stealMsg
                    .. "\nSteals: " .. tostring(STATE.stealCount)
                    .. "  -  Next: " .. nextTxt
                    .. "  -  Last: " .. STATE.lastStealTarget
            else
                stealStatusLabel.Text = "Auto steal is OFF"
            end
        end
    end
end)

task.spawn(function()
    while RUNNING do
        task.wait(1)
        if playerLabel ~= nil then
            local nm = "No players"
            if selectedPlayer ~= nil then
                if selectedPlayer.Parent == Players then
                    nm = selectedPlayer.Name
                else
                    selectedPlayer = nil
                end
            end
            playerLabel.Text = nm
        end
    end
end)

--=============================================================================--
--  FINAL SETUP
--=============================================================================--
-- anti-afk (always on)
pcall(function()
    local VirtualUser = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickController2(Vector2.new())
    end)
end)

-- keep water-walk state + re-detect my raft after respawn
bind(LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1.2)
    if not RUNNING then return end
    if STATE.god then
        hookGod()
    end
    if STATE.waterwalk then
        applySwimState(true)
    end
    if STATE.myRaft == nil or STATE.myRaft.Parent == nil then
        task.wait(0.6)
        pcall(function()
            fullScan()
            local r = raftUnderPlayer()
            if r ~= nil and (r.owner == LocalPlayer or r.owner == nil) and not r.shield then
                STATE.myRaft = r.model
                notify("My Raft", "Auto-detected your raft: " .. r.name)
            end
        end)
    end
end))

-- auto-detect my raft on load
task.spawn(function()
    task.wait(2)
    if not RUNNING then return end
    pcall(function()
        fullScan()
        local r = raftUnderPlayer()
        if r ~= nil and (r.owner == LocalPlayer or r.owner == nil) and not r.shield then
            STATE.myRaft = r.model
            notify("My Raft", "Auto-detected your raft: " .. r.name)
        end
    end)
end)

-- unload (used on re-execution)
local function unloadAll()
    RUNNING = false
    pcall(function() setGod(false) end)
    pcall(function() setFullbright(false) end)
    pcall(function() setFPSBoost(false) end)
    pcall(function() setInstantInteract(false) end)
    pcall(restoreCollisions)
    for _, reg in pairs(ESPReg) do
        for inst, e in pairs(reg) do
            pcall(function() destroyEntry(e) end)
            reg[inst] = nil
        end
    end
    for i = 1, #Connections do
        pcall(function() Connections[i]:Disconnect() end)
    end
    pcall(function() Gui:Destroy() end)
end
pcall(function()
    if getgenv ~= nil then getgenv().__RAFTHUB_UNLOAD = unloadAll end
end)

print("[RAFT HUB v3.0] loaded - RightCtrl = show/hide")
notify("RAFT HUB v3.0", "Loaded. Auto-steal, Rich/Poor TP, God, Ghost, ESP all rebuilt. RightCtrl = show/hide. Scroll inside the tabs for more features.", 6)
