-- MM2 Underground Coin Pickup Diagnostic V3
-- Standalone observation tool. No movement, hitbox, or collection changes.
-- Capture starts/stops sampling; auto-stops after 15 finished observations.
-- Copy exports a complete report using setclipboard/toClipboard if available.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local ENV = (getgenv and getgenv()) or _G
if type(ENV.StopUndergroundCoinDiagnosticV3) == "function" then
    pcall(ENV.StopUndergroundCoinDiagnosticV3)
end

local LIMIT = 15
local SAMPLE_PERIOD = 0.05
local SEARCH_PERIOD = 0.25
local TRACK_DISTANCE = 13
local MAX_SECONDS = 8
local EXPECTED_Y = -5.05
local STUCK_SECONDS = 0.8
local records = {}
local capturing = false
local current, currentData = nil, nil
local sampleAccumulator, searchAccumulator = 0, 0
local heartbeatConnection, coinEventConnection
local latestBagCount
local active = true
local gui

local function rootPart()
    local character = LocalPlayer.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end
local function positionOf(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        local ok, cf = pcall(function() return obj:GetPivot() end)
        if ok then return cf.Position end
    end
end
local function hasTouch(obj)
    if not obj or not obj.Parent then return false end
    if obj:FindFirstChild("TouchInterest", true) then return true end
    for _, child in ipairs(obj:GetDescendants()) do
        if child:IsA("TouchTransmitter") then return true end
    end
    return false
end
local function closestCoin(root)
    local best, dist = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "Coin_Server" and (obj:IsA("BasePart") or obj:IsA("Model")) and hasTouch(obj) then
            local p = positionOf(obj)
            if p then
                local d = (root.Position - p).Magnitude
                if d < dist then best, dist = obj, d end
            end
        end
    end
    return best, dist
end
local function fmt(n)
    if n == math.huge then return "N/A" end
    return string.format("%.2f", n or 0)
end
local function report()
    local lines = {
        "MM2 UNDERGROUND COIN PICKUP DIAGNOSTIC V3",
        "Observation only | Limit: " .. LIMIT .. " | Recorded: " .. #records,
        "Expected V13.10 offset: -5.05 | Expected HRP: 2x12x1",
        "Note: Touch/coin removal is a POSSIBLE pickup, not proof.",
        "CoinCollected bag-count increases confirm a pickup event, but cannot identify the exact coin.",
        "----------------------------------------"
    }
    for i, r in ipairs(records) do
        lines[#lines + 1] = string.format(
            "#%02d %s | %s | t=%ss | Hmin=%s | 3Dmin=%s | Yclosest=%s | Yerror=%s | HitboxMin=%s | Overlap=%d | Reversals=%d | MaxSpeed=%s | HRP=%s | Events=%d | Notes=%s",
            i, r.outcome, r.coinName, fmt(r.duration), fmt(r.minH), fmt(r.min3D),
            fmt(r.closestY), fmt(r.closestY - EXPECTED_Y), fmt(r.minHitbox),
            r.overlaps, r.reversals, fmt(r.maxSpeed), r.rootSize,
            r.coinEvents, r.notes ~= "" and r.notes or "none"
        )
    end
    return table.concat(lines, "\n")
end

local panel = Instance.new("ScreenGui")
panel.Name = "UndergroundCoinDiagnosticV3"
panel.ResetOnSpawn = false
panel.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local parentOK = pcall(function() panel.Parent = game:GetService("CoreGui") end)
if not parentOK then panel.Parent = LocalPlayer:WaitForChild("PlayerGui") end
gui = panel
local frame = Instance.new("Frame")
frame.Name = "Panel"
frame.Size = UDim2.fromOffset(310, 160)
frame.Position = UDim2.new(0.5, -155, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(24, 26, 35)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = panel
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, -40, 0, 35)
header.Position = UDim2.fromOffset(12, 3)
header.BackgroundTransparency = 1
header.Text = "Underground Coin Diagnostic V3"
header.TextColor3 = Color3.fromRGB(245, 245, 250)
header.TextSize = 15
header.Font = Enum.Font.GothamBold
header.TextXAlignment = Enum.TextXAlignment.Left
header.Parent = frame
local status = Instance.new("TextLabel")
status.Position = UDim2.fromOffset(12, 43)
status.Size = UDim2.new(1, -24, 0, 44)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(195, 200, 215)
status.TextSize = 13
status.TextWrapped = true
status.Font = Enum.Font.Gotham
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = frame
local function makeButton(label, x, width)
    local b = Instance.new("TextButton")
    b.Position = UDim2.fromOffset(x, 100)
    b.Size = UDim2.fromOffset(width, 36)
    b.BackgroundColor3 = Color3.fromRGB(52, 57, 75)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 13
    b.Text = label
    b.Parent = frame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
    return b
end
local captureButton = makeButton("Capture", 12, 98)
local clearButton = makeButton("Clear", 116, 82)
local copyButton = makeButton("Copy", 204, 94)
local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(27, 27)
close.Position = UDim2.new(1, -32, 0, 6)
close.BackgroundTransparency = 1
close.Text = "×"
close.TextSize = 22
close.TextColor3 = Color3.fromRGB(230, 230, 235)
close.Parent = frame

-- Drag via title area (mouse and touch).
local dragging, dragStart, panelStart = false, nil, nil
header.Active = true
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        panelStart = frame.Position
        local release
        release = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                release:Disconnect()
            end
        end)
    end
end)
local dragConnection = game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(panelStart.X.Scale, panelStart.X.Offset + delta.X, panelStart.Y.Scale, panelStart.Y.Offset + delta.Y)
    end
end)

local function updateStatus(extra)
    if not active then return end
    captureButton.Text = capturing and "Stop" or "Capture"
    status.Text = string.format("%s  •  %d/%d attempts\n%s", capturing and "Recording" or "Stopped", #records, LIMIT, extra or (currentData and "Tracking nearby coin..." or "Ready"))
end
local function disconnectCapture()
    if heartbeatConnection then heartbeatConnection:Disconnect(); heartbeatConnection = nil end
    if coinEventConnection then coinEventConnection:Disconnect(); coinEventConnection = nil end
end
local function finish(reason)
    if not currentData then return end
    local r = currentData
    r.duration = os.clock() - r.started
    r.outcome = reason
    if r.min3D == math.huge then r.closestY = 0 end
    records[#records + 1] = r
    current, currentData = nil, nil
    if #records >= LIMIT then
        capturing = false
        disconnectCapture()
        updateStatus("Limit reached. Press Copy.")
    else
        updateStatus("Last: " .. reason)
    end
end
local function startCoin(coin, root)
    current = coin
    currentData = {
        coinName = coin:GetFullName(), started = os.clock(),
        minH = math.huge, min3D = math.huge, minHitbox = math.huge,
        closestY = 0, overlaps = 0, reversals = 0, lastDirection = 0,
        maxSpeed = 0, rootSize = tostring(root.Size), coinEvents = 0,
        closeSince = nil, stuck = false, notes = "", outcome = ""
    }
    updateStatus("Tracking coin...")
end
local function sample(dt)
    sampleAccumulator += dt
    searchAccumulator += dt
    if sampleAccumulator < SAMPLE_PERIOD then return end
    sampleAccumulator = 0
    local root = rootPart()
    if not root then
        if currentData then finish("CHARACTER_MISSING") end
        return
    end
    if not currentData then
        if searchAccumulator < SEARCH_PERIOD then return end
        searchAccumulator = 0
        local coin, d = closestCoin(root)
        if coin and d <= TRACK_DISTANCE and root.Position.Y < positionOf(coin).Y - 1.5 then
            startCoin(coin, root)
        end
        return
    end
    if not current or not current:IsDescendantOf(workspace) then
        finish("COIN_REMOVED_POSSIBLE_PICKUP")
        return
    end
    if not hasTouch(current) then
        finish("TOUCH_REMOVED_POSSIBLE_PICKUP")
        return
    end
    local coinPos = positionOf(current)
    if not coinPos then finish("COIN_POSITION_MISSING"); return end
    local r = currentData
    local delta = root.Position - coinPos
    local h = Vector2.new(delta.X, delta.Z).Magnitude
    local d = delta.Magnitude
    local relative = root.CFrame:PointToObjectSpace(coinPos)
    local half = root.Size * 0.5
    local hx = math.max(math.abs(relative.X) - half.X, 0)
    local hy = math.max(math.abs(relative.Y) - half.Y, 0)
    local hz = math.max(math.abs(relative.Z) - half.Z, 0)
    local hitboxDistance = Vector3.new(hx, hy, hz).Magnitude
    r.minH = math.min(r.minH, h)
    r.minHitbox = math.min(r.minHitbox, hitboxDistance)
    if d < r.min3D then r.min3D = d; r.closestY = delta.Y end
    if hitboxDistance <= 0.1 then r.overlaps += 1 end
    local v = root.AssemblyLinearVelocity
    r.maxSpeed = math.max(r.maxSpeed, v.Magnitude)
    local direction = v.Y > 1 and 1 or (v.Y < -1 and -1 or 0)
    if direction ~= 0 then
        if r.lastDirection ~= 0 and r.lastDirection ~= direction then r.reversals += 1 end
        r.lastDirection = direction
    end
    if h <= 1.5 and d <= 7 then
        r.closeSince = r.closeSince or os.clock()
        if not r.stuck and os.clock() - r.closeSince >= STUCK_SECONDS then
            r.stuck = true
            r.notes = "STUCK_SUSPECTED"
        end
    else
        r.closeSince = nil
    end
    if os.clock() - r.started >= MAX_SECONDS then
        finish("TIMEOUT_UNCONFIRMED")
    end
end
local function stopCapture()
    if not capturing then return end
    capturing = false
    disconnectCapture()
    if currentData then finish("CAPTURE_STOPPED_PARTIAL") end
    updateStatus("Capture stopped. Copy results.")
end
local function startCapture()
    if #records >= LIMIT then
        updateStatus("Limit reached. Clear to restart.")
        return
    end
    capturing = true
    sampleAccumulator, searchAccumulator = 0, SEARCH_PERIOD
    local gameplay = ReplicatedStorage:FindFirstChild("Remotes")
    gameplay = gameplay and gameplay:FindFirstChild("Gameplay")
    local coinEvent = gameplay and gameplay:FindFirstChild("CoinCollected")
    if coinEvent and coinEvent:IsA("RemoteEvent") then
        coinEventConnection = coinEvent.OnClientEvent:Connect(function(...)
            local args = {...}
            local count = tonumber(args[2])
            if count then
                if latestBagCount and count > latestBagCount and currentData then
                    currentData.coinEvents += count - latestBagCount
                    currentData.notes = currentData.notes .. " BAG_COUNT_INCREASE"
                end
                latestBagCount = count
            end
        end)
    end
    heartbeatConnection = RunService.Heartbeat:Connect(sample)
    updateStatus("Recording underground attempts...")
end
captureButton.MouseButton1Click:Connect(function()
    if capturing then stopCapture() else startCapture() end
end)
clearButton.MouseButton1Click:Connect(function()
    stopCapture()
    table.clear(records)
    current, currentData, latestBagCount = nil, nil, nil
    updateStatus("Cleared. Ready to capture.")
end)
copyButton.MouseButton1Click:Connect(function()
    local clipboard = (setclipboard or toclipboard)
    if type(clipboard) ~= "function" then
        updateStatus("Clipboard unavailable in this environment.")
        print(report())
        return
    end
    local ok = pcall(clipboard, report())
    updateStatus(ok and "Copied report to clipboard." or "Copy failed; report printed to console.")
    if not ok then print(report()) end
end)
local function shutdown()
    if not active then return end
    stopCapture()
    active = false
    if dragConnection then dragConnection:Disconnect() end
    if gui then gui:Destroy() end
    ENV.StopUndergroundCoinDiagnosticV3 = nil
end
close.MouseButton1Click:Connect(shutdown)
ENV.StopUndergroundCoinDiagnosticV3 = shutdown
updateStatus("Ready. Start the farm, then Capture.")
