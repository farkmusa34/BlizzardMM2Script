-- MM2 UNDERGROUND COIN TARGETED DIAGNOSTIC V6
-- Observation-only: never moves the character or changes coins.
-- Captures the sequence around delayed underground coin contacts.
-- Touch/coin disappearance = POSSIBLE pickup, not proof.

local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local UIS = game:GetService('UserInputService')
local player = Players.LocalPlayer

local CONFIG = {
    limit = 15, sampleEvery = 0.04, searchEvery = 0.16,
    maxHorizontalStart = 9, undergroundMinimum = 2.5,
    timeout = 6, leaveDistance = 12, leaveGrace = 0.55,
    yReference = -5.05, turnMinSpeed = 2.0,
    eventLimit = 70, staleCoinCooldown = 7
}

local parent = (type(gethui) == 'function' and gethui()) or game:GetService('CoreGui')
local previous = parent:FindFirstChild('UndergroundCoinTargetedV6')
if previous then previous:Destroy() end

local gui = Instance.new('ScreenGui')
gui.Name = 'UndergroundCoinTargetedV6'
gui.ResetOnSpawn = false
gui.Parent = parent

local panel = Instance.new('Frame')
panel.Size = UDim2.fromOffset(365, 251)
panel.Position = UDim2.new(.5, -182, .27, 0)
panel.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = gui
Instance.new('UICorner', panel).CornerRadius = UDim.new(0, 10)

local function makeLabel(y, h, content, fontSize)
    local obj = Instance.new('TextLabel')
    obj.BackgroundTransparency = 1
    obj.Position = UDim2.fromOffset(12, y)
    obj.Size = UDim2.new(1, -24, 0, h)
    obj.TextColor3 = Color3.fromRGB(237, 240, 246)
    obj.TextXAlignment = Enum.TextXAlignment.Left
    obj.TextYAlignment = Enum.TextYAlignment.Center
    obj.Font = Enum.Font.Gotham
    obj.TextSize = fontSize or 12
    obj.TextWrapped = true
    obj.Text = content
    obj.Parent = panel
    return obj
end
local title = makeLabel(8, 24, 'UNDERGROUND TARGETED DIAGNOSTIC V6', 14)
title.Font = Enum.Font.GothamBold
local status = makeLabel(39, 23, 'STOPPED | 0/15 completed', 13)
local currentLabel = makeLabel(68, 37, 'Target: none', 12)
local detail = makeLabel(109, 41, 'Ready. Capture only when testing underground.', 12)
local note = makeLabel(211, 31, 'Observes geometry, not server-confirmed collection. Drag using title.', 10)

local function makeButton(txt, x, color)
    local b = Instance.new('TextButton')
    b.Size = UDim2.fromOffset(106, 38)
    b.Position = UDim2.fromOffset(x, 162)
    b.BackgroundColor3 = color
    b.Text = txt
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextSize = 13
    b.Font = Enum.Font.GothamBold
    b.Parent = panel
    Instance.new('UICorner', b).CornerRadius = UDim.new(0, 7)
    return b
end
local capture = makeButton('Capture', 12, Color3.fromRGB(35, 145, 95))
local clear = makeButton('Clear', 129, Color3.fromRGB(90, 96, 113))
local copy = makeButton('Copy', 246, Color3.fromRGB(46, 107, 195))

local dragInput, dragStart, startPosition
panel.InputBegan:Connect(function(input)
    if (input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch)
        or input.Position.Y - panel.AbsolutePosition.Y > 36 then return end
    dragInput = input
    dragStart = input.Position
    startPosition = panel.Position
end)
UIS.InputChanged:Connect(function(input)
    if not dragInput then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement and input ~= dragInput then return end
    local d = input.Position - dragStart
    panel.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + d.X,
        startPosition.Y.Scale, startPosition.Y.Offset + d.Y)
end)
UIS.InputEnded:Connect(function(input)
    if input == dragInput or (dragInput and input.UserInputType == Enum.UserInputType.MouseButton1) then
        dragInput = nil
    end
end)

local capturing = false
local results = {}
local current = nil
local ignored = setmetatable({}, {__mode = 'k'})
local lastSearch, lastSample = 0, 0

local function rootPart()
    local char = player.Character
    return char and char:FindFirstChild('HumanoidRootPart')
end
local function positionOf(coin)
    if not coin or not coin.Parent then return nil end
    if coin:IsA('BasePart') then return coin.Position end
    if coin:IsA('Model') then
        local ok, cf = pcall(function() return coin:GetPivot() end)
        if ok then return cf.Position end
    end
    return nil
end
local function hasTouch(coin)
    if not coin or not coin.Parent then return false end
    for _, desc in ipairs(coin:GetDescendants()) do
        if desc.Name == 'TouchInterest' or desc:IsA('TouchTransmitter') then return true end
    end
    return false
end
local function hDistance(a, b)
    return Vector2.new(a.X - b.X, a.Z - b.Z).Magnitude
end
local function boxDistance(root, p)
    local localP = root.CFrame:PointToObjectSpace(p)
    local half = root.Size * .5
    local x = math.max(math.abs(localP.X) - half.X, 0)
    local y = math.max(math.abs(localP.Y) - half.Y, 0)
    local z = math.max(math.abs(localP.Z) - half.Z, 0)
    return math.sqrt(x*x + y*y + z*z)
end
local function fmt(x)
    if x == nil or x == math.huge then return 'N/A' end
    return string.format('%.2f', x)
end
local function event(a, name, extras)
    if #a.events >= CONFIG.eventLimit then return end
    local elapsed = os.clock() - a.started
    table.insert(a.events, string.format('+%.2fs %s%s', elapsed, name,
        extras and (' | ' .. extras) or ''))
end
local function refresh()
    status.Text = string.format('%s | %d/%d completed', capturing and 'CAPTURING' or 'STOPPED', #results, CONFIG.limit)
    capture.Text = capturing and 'Stop' or 'Capture'
    capture.BackgroundColor3 = capturing and Color3.fromRGB(178, 66, 70) or Color3.fromRGB(35, 145, 95)
end
local function begin(coin)
    local a = {
        coin = coin, map = coin.Parent and coin.Parent.Parent and coin.Parent.Parent.Name or 'unknown',
        started = os.clock(), events = {}, samples = 0, firstOverlap = nil,
        overlapDuration = 0, overlapSamples = 0, overlapStart = nil,
        maxOverlapRun = 0, minH = math.huge, minBox = math.huge,
        bestY = nil, bestYError = math.huge, maxHSpeed = 0, maxVSpeed = 0,
        hTurns = 0, vReversals = 0, lastHorizontalDir = nil, lastVerticalSign = 0,
        lastPos = nil, lastT = nil, lastH = nil, leaveSince = nil,
        initiallyTouched = hasTouch(coin)
    }
    current = a
    event(a, 'TARGET_ACQUIRED', coin:GetFullName())
    return a
end
local function finish(reason)
    local a = current
    if not a then return end
    local elapsed = os.clock() - a.started
    if a.overlapStart then
        local run = os.clock() - a.overlapStart
        a.overlapDuration = a.overlapDuration + run
        a.maxOverlapRun = math.max(a.maxOverlapRun, run)
        a.overlapStart = nil
    end
    event(a, 'END_' .. reason)
    local summary = string.format(
        '#%02d %s | map=%s | duration=%.2fs | Hmin=%s | Ybest=%s | Yerror=%s | BoxMin=%s | FirstOverlap=%s | OverlapTotal=%.2fs | LongestOverlap=%.2fs | OverlapSamples=%d | HspeedMax=%.2f | VspeedMax=%.2f | Hturns=%d | Vreversals=%d | samples=%d',
        #results + 1, reason, a.map, elapsed, fmt(a.minH), fmt(a.bestY),
        fmt(a.bestYError), fmt(a.minBox), fmt(a.firstOverlap), a.overlapDuration,
        a.maxOverlapRun, a.overlapSamples, a.maxHSpeed, a.maxVSpeed,
        a.hTurns, a.vReversals, a.samples)
    table.insert(results, {summary = summary, events = a.events})
    ignored[a.coin] = os.clock() + CONFIG.staleCoinCooldown
    current = nil
    currentLabel.Text = 'Target: none'
    detail.Text = string.format('Saved #%d: %s', #results, reason)
    if #results >= CONFIG.limit then
        capturing = false
        detail.Text = 'Reached 15 observations. Press Copy.'
    end
    refresh()
end
local function findTarget(root)
    local chosen, best
    for _, coin in ipairs(workspace:GetDescendants()) do
        if coin.Name == 'Coin_Server' and (coin:IsA('BasePart') or coin:IsA('Model')) then
            local pos = positionOf(coin)
            if pos and hasTouch(coin) and (ignored[coin] or 0) < os.clock() then
                local h = hDistance(root.Position, pos)
                local below = pos.Y - root.Position.Y
                if below >= CONFIG.undergroundMinimum and h <= CONFIG.maxHorizontalStart
                    and (not best or h < best) then
                    chosen, best = coin, h
                end
            end
        end
    end
    return chosen
end
local function sign(v)
    if v > CONFIG.turnMinSpeed then return 1 end
    if v < -CONFIG.turnMinSpeed then return -1 end
    return 0
end
local function sample(a, root, coinPos, now)
    local h = hDistance(root.Position, coinPos)
    local y = root.Position.Y - coinPos.Y
    local box = boxDistance(root, coinPos)
    a.samples = a.samples + 1
    a.minH = math.min(a.minH, h)
    a.minBox = math.min(a.minBox, box)
    local yErr = math.abs(y - CONFIG.yReference)
    if yErr < a.bestYError then a.bestYError, a.bestY = yErr, y end

    local velocity = root.AssemblyLinearVelocity
    local horizontalSpeed = Vector2.new(velocity.X, velocity.Z).Magnitude
    a.maxHSpeed = math.max(a.maxHSpeed, horizontalSpeed)
    a.maxVSpeed = math.max(a.maxVSpeed, math.abs(velocity.Y))

    -- A horizontal turn means reversing along the previous significant movement vector.
    local move = Vector2.new(velocity.X, velocity.Z)
    if move.Magnitude >= CONFIG.turnMinSpeed then
        local dir = move.Unit
        if a.lastHorizontalDir and a.lastHorizontalDir:Dot(dir) < -0.45 then
            a.hTurns = a.hTurns + 1
            event(a, 'HORIZONTAL_REVERSAL', string.format('H=%.2f speed=%.2f', h, horizontalSpeed))
        end
        a.lastHorizontalDir = dir
    end
    local vs = sign(velocity.Y)
    if vs ~= 0 then
        if a.lastVerticalSign ~= 0 and vs ~= a.lastVerticalSign then
            a.vReversals = a.vReversals + 1
            event(a, 'VERTICAL_REVERSAL', string.format('H=%.2f Y=%.2f Vy=%.2f', h, y, velocity.Y))
        end
        a.lastVerticalSign = vs
    end

    if box <= .02 then
        a.overlapSamples = a.overlapSamples + 1
        if not a.overlapStart then
            a.overlapStart = now
            if not a.firstOverlap then
                a.firstOverlap = now - a.started
                event(a, 'FIRST_HRP_OVERLAP', string.format('H=%.2f Y=%.2f', h, y))
            else
                event(a, 'HRP_OVERLAP_REENTER', string.format('H=%.2f Y=%.2f', h, y))
            end
        end
    elseif a.overlapStart then
        local run = now - a.overlapStart
        a.overlapDuration = a.overlapDuration + run
        a.maxOverlapRun = math.max(a.maxOverlapRun, run)
        a.overlapStart = nil
        event(a, 'HRP_OVERLAP_EXIT', string.format('after=%.2fs H=%.2f', run, h))
    end
    if a.lastH and a.lastH > 2 and h <= 2 then
        event(a, 'WITHIN_2_STUDS', string.format('H=%.2f Y=%.2f', h, y))
    end
    if a.lastH and a.lastH > 1 and h <= 1 then
        event(a, 'WITHIN_1_STUD', string.format('H=%.2f Y=%.2f', h, y))
    end
    a.lastH = h
    if h > CONFIG.leaveDistance then
        if not a.leaveSince then a.leaveSince = now; event(a, 'LEFT_TARGET_RADIUS', fmt(h)) end
    else
        a.leaveSince = nil
    end
    currentLabel.Text = string.format('Target: %s | H %.2f | Y %.2f | overlap %s', a.map, h, y,
        a.overlapStart and 'YES' or 'NO')
    detail.Text = string.format('%.2fs | turns H:%d V:%d | overlap %.2fs',
        now - a.started, a.hTurns, a.vReversals,
        a.overlapDuration + (a.overlapStart and now - a.overlapStart or 0))
end

capture.MouseButton1Click:Connect(function()
    if capturing then
        capturing = false
        -- Save an in-progress observation so pausing never silently discards its data.
        if current then finish('MANUAL_STOP_UNCONFIRMED') end
        detail.Text = 'Paused. Existing logs preserved.'
    elseif #results >= CONFIG.limit then
        detail.Text = 'Already 15/15. Copy, then Clear to restart.'
    else
        capturing = true
        detail.Text = 'Watching underground coins...'
    end
    refresh()
end)
clear.MouseButton1Click:Connect(function()
    capturing = false
    current = nil
    results = {}
    ignored = setmetatable({}, {__mode = 'k'})
    currentLabel.Text = 'Target: none'
    detail.Text = 'Cleared. Ready to capture.'
    refresh()
end)
local function report()
    local lines = {
        'MM2 UNDERGROUND TARGETED COIN DIAGNOSTIC V6',
        string.format('Completed: %d/%d | Capture: %s', #results, CONFIG.limit, capturing and 'ON' or 'OFF'),
        'Reference Y: -5.05 | Underground min: 2.5 | Timeout: 6s',
        'TOUCH_REMOVED and COIN_REMOVED mean POSSIBLE pickup, not proof.',
        'Overlap = coin point inside observed HRP bounding box, not server touch confirmation.',
        'Events show sampled order; rapid motion between samples may be missed.',
        '----------------------------------------'
    }
    for _, r in ipairs(results) do
        table.insert(lines, r.summary)
        for _, ev in ipairs(r.events) do table.insert(lines, '    ' .. ev) end
    end
    if current then
        table.insert(lines, 'CURRENT IN-PROGRESS TARGET (not yet completed):')
        for _, ev in ipairs(current.events) do table.insert(lines, '    ' .. ev) end
    end
    return table.concat(lines, '\n')
end
copy.MouseButton1Click:Connect(function()
    local content = report()
    local fn = setclipboard or toclipboard
    if type(fn) == 'function' then
        local ok = pcall(fn, content)
        detail.Text = ok and 'Report copied. Logs preserved.' or 'Clipboard failed; report printed to console.'
        if not ok then print(content) end
    else
        print(content)
        detail.Text = 'Clipboard unavailable; report printed to console.'
    end
end)

local heartbeat
heartbeat = RunService.Heartbeat:Connect(function()
    if not gui.Parent then heartbeat:Disconnect(); return end
    if not capturing then return end
    local now = os.clock()
    local root = rootPart()
    if not root then
        if current then finish('CHARACTER_LOST_UNCONFIRMED') end
        return
    end
    if current then
        local a = current
        local pos = positionOf(a.coin)
        if not pos then finish('COIN_REMOVED_POSSIBLE_PICKUP'); return end
        if a.initiallyTouched and not hasTouch(a.coin) then
            finish('TOUCH_REMOVED_POSSIBLE_PICKUP'); return
        end
        if now - lastSample >= CONFIG.sampleEvery then
            lastSample = now
            sample(a, root, pos, now)
        end
        if a.leaveSince and now - a.leaveSince >= CONFIG.leaveGrace then
            finish('TARGET_LEFT_UNCONFIRMED'); return
        end
        if now - a.started >= CONFIG.timeout then
            finish('TIMEOUT_UNCONFIRMED'); return
        end
    elseif now - lastSearch >= CONFIG.searchEvery then
        lastSearch = now
        local coin = findTarget(root)
        if coin then begin(coin) end
    end
end)
refresh()
print('[Underground Targeted Diagnostic V6] Loaded. Observation only.')
