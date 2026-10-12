-- Blizzard MM2 v1.85.4 - Main dashboard
-- Native WindUI elements are used so this lives inside the Main tab.
local MM2 = (getgenv and getgenv().MM2_V85_SPLIT) or _G.MM2_V85_SPLIT
assert(MM2 and MM2.UI and MM2.UI.MainPage, "Shared.lua and updated UI.lua required")
local UI, Flags = MM2.UI, MM2.Flags
local Players, LocalPlayer = MM2.Services.Players, MM2.LocalPlayer
local RunService = MM2.Services.RunService
local page = UI.MainPage
local alive = true
local began = os.clock()
local spectating = nil
local overview, farmInfo, rosterInfo
local entries = {}

local function notify(message, bad)
    MM2.Notify(message, 2.5, bad and "circle-x" or "info", "Main")
end
local function call(name, ...)
    local f = MM2.Functions[name]
    if type(f) ~= "function" then notify(name .. " is unavailable", true); return false end
    local ok, result, message = pcall(f, ...)
    if not ok then notify(tostring(result), true); return false end
    if result == false then notify(tostring(message or "Action unavailable"), true) end
    return result ~= false
end
local function roleOf(player)
    if not MM2.State.RoleRoundActive then return "LOBBY" end
    if MM2.State.PlayerOutOfRound[player.Name] then return "LOBBY" end
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return "LOBBY" end
    local role = MM2.State.ServerRolesCache[player.Name]
    if role == "Murderer" or role == "Sheriff" or role == "Hero" or role == "Innocent" then
        return string.upper(role)
    end
    return "UNKNOWN"
end
local roleColors = {
    MURDERER = Color3.fromRGB(239,68,68),
    SHERIFF = Color3.fromRGB(59,130,246),
    HERO = Color3.fromRGB(251,191,36),
    INNOCENT = Color3.fromRGB(34,197,94),
    LOBBY = Color3.fromRGB(161,161,170),
    UNKNOWN = Color3.fromRGB(161,161,170),
}
local function setParagraph(control, title, desc)
    if not control then return end
    pcall(function() control:SetTitle(title) end)
    pcall(function() control:SetDesc(desc) end)
    -- Some WindUI versions expose only the underlying labels.
    local root = control.ElementFrame or control.Frame
    if typeof(root) == "Instance" then
        for _, node in ipairs(root:GetDescendants()) do
            if node:IsA("TextLabel") then
                if node.Name == "Title" then node.Text = title
                elseif node.Name == "Desc" or node.Name == "Description" then node.Text = desc end
            end
        end
    end
end
local function setRoleOutline(control, role)
    if not control then return end
    local root = control.ElementFrame or control.Frame
    if typeof(root) ~= "Instance" then return end
    local stroke = root:FindFirstChild("MainRoleOutline")
    if not stroke then
        stroke = Instance.new("UIStroke")
        stroke.Name = "MainRoleOutline"
        stroke.Thickness = 1.5
        stroke.Parent = root
    end
    stroke.Color = roleColors[role] or roleColors.UNKNOWN
end
local function localPosition()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end
local function targetPosition(player)
    local char = player and player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if hum and hum.Health > 0 then return root end
end
local function teleportNear(player)
    local mine, target = localPosition(), targetPosition(player)
    if not mine or not target then notify("Player is unavailable", true); return end
    mine.AssemblyLinearVelocity = Vector3.zero
    mine.CFrame = target.CFrame * CFrame.new(4.5, 0, 1.5)
end
local function teleportLobby()
    local root = localPosition()
    if not root then notify("Character unavailable", true); return end
    root.AssemblyLinearVelocity = Vector3.zero
    root.CFrame = CFrame.new(13.497, 504.818, -9.978)
end
local function teleportMap()
    if not MM2.State.RoleRoundActive then notify("No active round", true); return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and roleOf(player) ~= "LOBBY" then
            if targetPosition(player) then teleportNear(player); return end
        end
    end
    notify("Active map position unavailable", true)
end
local function toggleSpectate(player)
    local camera = workspace.CurrentCamera
    if not camera then return end
    if spectating == player then
        spectating = nil
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then camera.CameraSubject = hum end
        notify("Spectate off")
    else
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then notify("Player unavailable", true); return end
        spectating = player
        camera.CameraSubject = hum
        notify("Spectating " .. player.DisplayName)
    end
end

UI.AddSection(page, "Overview", "")
overview = UI.CreateInfo(page, "Loading player...", "Loading role and round information...")
farmInfo = UI.CreateInfo(page, "Auto Farm: OFF", "Per Hour: —   •   Collected: —   •   Uptime: 0m")

UI.AddSection(page, "Quick Actions", "")
UI.CreateActionFeature(page, "Shoot Murderer", "Use the existing sheriff shooting logic", function()
    call("ShootMurderer")
end, "crosshair", "blue")
UI.CreateActionFeature(page, "Fling Murderer", "Fling the active murderer", function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and roleOf(p) == "MURDERER" then
            task.spawn(function() call("ExecuteYeet", p, "Murderer") end)
            return
        end
    end
    notify("No active Murderer", true)
end, "skull", "danger")
UI.CreateActionFeature(page, "Kill All", "Use existing Murderer action", function()
    call("KillAllOnce")
end, "sword", "danger")
UI.CreateActionFeature(page, "Hop Server", "Find another public server", function()
    call("ServerHop")
end, "shuffle")
UI.CreateActionFeature(page, "Teleport to Voting Area", "Location not captured yet", function()
    notify("Voting area coordinates are not configured yet", true)
end, "vote")
UI.CreateActionFeature(page, "Teleport to Lobby", "Return to the captured lobby position", teleportLobby, "house")
UI.CreateActionFeature(page, "Teleport to Map", "Only available during an active round", teleportMap, "map-pin")

UI.AddSection(page, "Players", "")
UI.CreateToggle(page, "Round Start Alert", "Notify when a new round starts", "MainRoundStartAlert")
rosterInfo = UI.CreateInfo(page, "Players in this server", "Loading...")

-- Each player gets a WindUI card and three actions. No floating GUI overlays.
local function addPlayer(player)
    if player == LocalPlayer or entries[player] then return end
    local section = UI.AddSection(page, player.DisplayName .. " (@" .. player.Name .. ")", "")
    local card = UI.CreateInfo(page, "LOBBY", "Distance: —")
    UI.CreateActionFeature(page, "Spectate " .. player.DisplayName, "Toggle camera viewing", function()
        toggleSpectate(player)
    end, "eye")
    UI.CreateActionFeature(page, "Teleport to " .. player.DisplayName, "Teleport beside player once", function()
        teleportNear(player)
    end, "navigation")
    UI.CreateActionFeature(page, "Fling " .. player.DisplayName, "One-time fling action", function()
        task.spawn(function() call("ExecuteYeet", player, player.Name) end)
    end, "wind")
    entries[player] = {section = section, card = card}
end
local function removePlayer(player)
    local item = entries[player]
    if not item then return end
    entries[player] = nil
    if spectating == player then toggleSpectate(player) end
    if item.section then
        local frame = item.section.ElementFrame or item.section.Frame
        if typeof(frame) == "Instance" then frame:Destroy() end
    end
end
for _, player in ipairs(Players:GetPlayers()) do addPlayer(player) end
MM2.Track(Players.PlayerAdded:Connect(addPlayer))
MM2.Track(Players.PlayerRemoving:Connect(removePlayer))
local lastRound = false
local elapsed = 0
local conn = RunService.Heartbeat:Connect(function(dt)
    if not MM2.Running then alive = false; return end
    elapsed += dt
    if elapsed < 1 then return end
    elapsed = 0
    local active = MM2.State.RoleRoundActive == true
    if active and not lastRound and Flags.MainRoundStartAlert then notify("A new round has started!") end
    lastRound = active
    local role = roleOf(LocalPlayer)
    local avatar = LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")"
    local coins = LocalPlayer:GetAttribute("Coins") or "—"
    local gems = LocalPlayer:GetAttribute("Gems") or "—"
    local level = LocalPlayer:GetAttribute("Level") or "—"
    setParagraph(overview, avatar .. "  •  " .. role,
        "Coins: " .. tostring(coins) .. "    Gems: " .. tostring(gems) .. "    Level: " .. tostring(level))
    setRoleOutline(overview, role)
    local minutes = math.floor((os.clock() - began) / 60)
    local stats = MM2.Functions.GetMainFarmStats and MM2.Functions.GetMainFarmStats() or {}
    setParagraph(farmInfo, "Auto Farm: " .. (Flags.AutoFarm and "ON" or "OFF"),
        "Per Hour: " .. tostring(stats.PerHour or "—") ..
        "   •   Collected: " .. tostring(stats.Collected or "—") ..
        "   •   Uptime: " .. minutes .. "m")
    setParagraph(rosterInfo, "Players in this server: " .. #Players:GetPlayers(),
        "Role badges and distances refresh automatically")
    local myRoot = localPosition()
    for player, item in pairs(entries) do
        local target = targetPosition(player)
        local distance = (myRoot and target) and math.floor((myRoot.Position-target.Position).Magnitude) or nil
        local theirRole = roleOf(player)
        setParagraph(item.card, theirRole, "@" .. player.Name .. "  •  Distance: " .. (distance and (distance .. " studs") or "—"))
        setRoleOutline(item.card, theirRole)
    end
end)
MM2.Track(conn)
MM2.Functions.StopMainSpectate = function()
    if spectating then toggleSpectate(spectating) end
end
print("[Blizzard] Main dashboard loaded")
