-- Off-Screen Arrows Diagnostic V1 - standalone observation / preview
-- LocalScript: Roblox Studio > StarterPlayer > StarterPlayerScripts
-- Reads public client player/camera state; does not alter game objects or combat.
-- No dependencies on Blizzard or other scripts.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local previous = playerGui:FindFirstChild("OffScreenArrowsDiagnostic")
if previous then previous:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "OffScreenArrowsDiagnostic"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "ControlPanel"
panel.Size = UDim2.fromOffset(320, 177)
panel.Position = UDim2.new(0, 12, 0, 72)
panel.BackgroundColor3 = Color3.fromRGB(22, 25, 33)
panel.BackgroundTransparency = 0.06
panel.BorderSizePixel = 0
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

local function text(parent, value, size, pos, fontSize)
    local obj = Instance.new("TextLabel")
    obj.BackgroundTransparency = 1
    obj.TextColor3 = Color3.fromRGB(240, 243, 249)
    obj.Font = Enum.Font.Gotham
    obj.TextSize = fontSize or 13
    obj.TextXAlignment = Enum.TextXAlignment.Left
    obj.Text = value
    obj.Size = size
    obj.Position = pos
    obj.Parent = parent
    return obj
end

text(panel, "OFF-SCREEN ARROWS  |  OBSERVER V1", UDim2.new(1, -20, 0, 23), UDim2.fromOffset(12, 8), 13)
local status = text(panel, "Status: stopped", UDim2.new(1, -20, 0, 21), UDim2.fromOffset(12, 32), 12)
local stats = text(panel, "Visible: 0   Off-screen: 0   Behind: 0", UDim2.new(1, -20, 0, 20), UDim2.fromOffset(12, 52), 12)
local note = text(panel, "Preview arrows show computed direction + distance.", UDim2.new(1, -20, 0, 22), UDim2.fromOffset(12, 75), 11)
note.TextColor3 = Color3.fromRGB(180, 188, 204)

local function button(label, x, y, w)
    local b = Instance.new("TextButton")
    b.Text = label
    b.TextSize = 12
    b.Font = Enum.Font.GothamMedium
    b.TextColor3 = Color3.new(1, 1, 1)
    b.BackgroundColor3 = Color3.fromRGB(56, 71, 102)
    b.Size = UDim2.fromOffset(w, 30)
    b.Position = UDim2.fromOffset(x, y)
    b.BorderSizePixel = 0
    b.Parent = panel
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
    return b
end
local startButton = button("Start Observing", 12, 103, 143)
local stopButton = button("Stop Observing", 165, 103, 143)
local copyButton = button("Copy Logs", 12, 139, 143)
local clearButton = button("Clear Logs", 165, 139, 143)

-- Drag panel on desktop and mobile.
local dragging, dragOrigin, panelOrigin = false, nil, nil
panel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragOrigin = input.Position
        panelOrigin = panel.Position
        local conn
        conn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                conn:Disconnect()
            end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and dragOrigin and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragOrigin
        panel.Position = UDim2.new(panelOrigin.X.Scale, panelOrigin.X.Offset + d.X, panelOrigin.Y.Scale, panelOrigin.Y.Offset + d.Y)
    end
end)

local MAX_LOGS = 350
local logs = {}
local running = false
local markers = {}
local tickAccumulator = 0
local lastLogAt = 0
local LOG_INTERVAL = 0.75
local UPDATE_INTERVAL = 0.05
local EDGE_MARGIN = 48

local function addLog(line)
    local t = os.clock()
    logs[#logs + 1] = string.format("[%.2f] %s", t, line)
    if #logs > MAX_LOGS then table.remove(logs, 1) end
end

local function removeMarker(player)
    local marker = markers[player]
    if marker then marker:Destroy(); markers[player] = nil end
end

local function markerFor(player)
    if markers[player] then return markers[player] end
    local holder = Instance.new("Frame")
    holder.Name = "Arrow_" .. player.Name
    holder.Size = UDim2.fromOffset(68, 52)
    holder.AnchorPoint = Vector2.new(0.5, 0.5)
    holder.BackgroundTransparency = 1
    holder.ZIndex = 10
    holder.Parent = gui
    local triangle = Instance.new("TextLabel")
    triangle.Name = "Triangle"
    triangle.Size = UDim2.fromOffset(44, 32)
    triangle.Position = UDim2.fromOffset(12, 0)
    triangle.BackgroundTransparency = 1
    triangle.Text = "▲"
    triangle.Font = Enum.Font.GothamBold
    triangle.TextSize = 30
    triangle.TextColor3 = Color3.fromRGB(255, 225, 90)
    triangle.TextStrokeTransparency = 0.25
    triangle.ZIndex = 11
    triangle.Parent = holder
    local distance = text(holder, "", UDim2.fromOffset(68, 18), UDim2.fromOffset(0, 32), 12)
    distance.Name = "Distance"
    distance.TextXAlignment = Enum.TextXAlignment.Center
    distance.TextStrokeTransparency = 0.35
    distance.ZIndex = 11
    markers[player] = holder
    return holder
end

local function getRoot(player)
    local character = player.Character
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
end

-- Camera-space direction is stable even when a target is behind the camera.
-- A behind-camera target's horizontal component is reversed for a useful screen-edge pointer.
local function screenDirection(camera, worldPosition)
    local localPos = camera.CFrame:PointToObjectSpace(worldPosition)
    local dx, dy = localPos.X, -localPos.Y
    if localPos.Z > 0 then dx, dy = -dx, -dy end
    local dir = Vector2.new(dx, dy)
    if dir.Magnitude < 0.001 then return Vector2.new(0, -1), true end
    return dir.Unit, localPos.Z > 0
end

local function edgePosition(direction, width, height)
    local cx, cy = width * 0.5, height * 0.5
    local rx, ry = math.max(20, cx - EDGE_MARGIN), math.max(20, cy - EDGE_MARGIN)
    local sx = math.abs(direction.X) > 0.0001 and rx / math.abs(direction.X) or math.huge
    local sy = math.abs(direction.Y) > 0.0001 and ry / math.abs(direction.Y) or math.huge
    local scale = math.min(sx, sy)
    return cx + direction.X * scale, cy + direction.Y * scale
end

local function clearMarkers()
    for player in pairs(markers) do removeMarker(player) end
end

local function update()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    local myRoot = getRoot(localPlayer)
    local visible, offscreen, behind = 0, 0, 0
    local logParts = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            local root = getRoot(player)
            if root then
                local projected, onScreen = camera:WorldToViewportPoint(root.Position)
                local isBehind = projected.Z <= 0
                local inside = onScreen and not isBehind and projected.X >= 0 and projected.X <= viewport.X and projected.Y >= 0 and projected.Y <= viewport.Y
                if inside then
                    visible += 1
                    removeMarker(player)
                else
                    offscreen += 1
                    if isBehind then behind += 1 end
                    local direction = screenDirection(camera, root.Position)
                    local x, y = edgePosition(direction, viewport.X, viewport.Y)
                    local marker = markerFor(player)
                    marker.Position = UDim2.fromOffset(x, y)
                    local angle = math.deg(math.atan2(direction.Y, direction.X)) + 90
                    marker.Triangle.Rotation = angle
                    local studs = myRoot and (root.Position - myRoot.Position).Magnitude or 0
                    -- Roblox distances are in studs, not meters.
                    marker.Distance.Text = myRoot and string.format("%.0f studs", studs) or "? studs"
                    table.insert(logParts, string.format("%s: %s angle=%.1f edge=(%.0f,%.0f) depth=%.1f dist=%.0f studs", player.Name, isBehind and "BEHIND" or "OFFSCREEN", angle, x, y, projected.Z, studs))
                end
            else
                removeMarker(player)
            end
        end
    end
    stats.Text = string.format("Visible: %d   Off-screen: %d   Behind: %d", visible, offscreen, behind)
    if os.clock() - lastLogAt >= LOG_INTERVAL then
        lastLogAt = os.clock()
        addLog(string.format("Viewport=%dx%d Visible=%d Offscreen=%d Behind=%d", viewport.X, viewport.Y, visible, offscreen, behind))
        for _, part in ipairs(logParts) do addLog(part) end
    end
end

startButton.MouseButton1Click:Connect(function()
    if running then return end
    running = true
    tickAccumulator = 0
    lastLogAt = 0
    status.Text = "Status: observing (20 updates/sec)"
    addLog("START OBSERVING - standalone arrows preview, edge margin 48px")
end)
stopButton.MouseButton1Click:Connect(function()
    if not running then return end
    running = false
    clearMarkers()
    status.Text = "Status: stopped"
    addLog("STOP OBSERVING")
end)
clearButton.MouseButton1Click:Connect(function()
    table.clear(logs)
    addLog("LOGS CLEARED")
end)
copyButton.MouseButton1Click:Connect(function()
    local payload = "OFF-SCREEN ARROWS DIAGNOSTIC V1\n" .. table.concat(logs, "\n")
    -- setclipboard is executor-specific; Studio Roblox does not provide it.
    if type(setclipboard) == "function" then
        local ok = pcall(setclipboard, payload)
        status.Text = ok and "Status: logs copied" or "Status: clipboard unavailable"
    else
        print(payload)
        status.Text = "Status: logs printed to Output (no clipboard API)"
    end
end)

RunService.Heartbeat:Connect(function(dt)
    if not running then return end
    tickAccumulator += dt
    if tickAccumulator < UPDATE_INTERVAL then return end
    tickAccumulator %= UPDATE_INTERVAL
    update()
end)

Players.PlayerRemoving:Connect(removeMarker)
addLog("READY - press Start Observing")
