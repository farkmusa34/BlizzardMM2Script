--============================================================
-- BLIZZARD HOTBAR RACE DIAGNOSTIC - STANDALONE / READ ONLY
-- Does NOT modify SkinChanger, Tool.TextureId, or ToolIcon.Image.
-- Buttons:
--   START RECORDING = clears old session and starts watching
--   COPY LOGS       = copies current logs
--   CLEAR / STOP    = stops recording and removes all logs
--============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local GUI_NAME = "BlizzardHotbarRaceDiagnostic"
local DEFAULT_GUN_ASSET = "197518111"
local GINGERSCOPE_ASSET = "15666596216"

local old = PlayerGui:FindFirstChild(GUI_NAME)
if old then old:Destroy() end

local recording = false
local startedAt = 0
local logs = {}
local connections = {}
local watched = setmetatable({}, {__mode="k"})
local snapshotToken = 0

local function now()
    return recording and (os.clock() - startedAt) or 0
end

local function assetId(s)
    s = tostring(s or "")
    return s:match("[?&]assetId=(%d+)") or s:match("[?&]id=(%d+)") or s:match("/asset/%?id=(%d+)") or s:match("id=(%d+)") or s:match("(%d+)")
end

local function imageKind(img)
    local id = assetId(img)
    if id == DEFAULT_GUN_ASSET then return "DEFAULT_GUN" end
    if id == GINGERSCOPE_ASSET then return "GINGERSCOPE" end
    return id and ("ASSET_" .. id) or "UNKNOWN"
end

local Gui = Instance.new("ScreenGui")
Gui.Name = GUI_NAME
Gui.ResetOnSpawn = false
Gui.DisplayOrder = 999999
Gui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(500, 390)
Main.Position = UDim2.new(0.5, -250, 0.5, -195)
Main.BackgroundColor3 = Color3.fromRGB(20,20,23)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = Gui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,10)

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Position = UDim2.fromOffset(12,8)
Title.Size = UDim2.new(1,-24,0,26)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextColor3 = Color3.new(1,1,1)
Title.Text = "Blizzard Hotbar Race Diagnostic"
Title.Parent = Main

local Status = Instance.new("TextLabel")
Status.BackgroundTransparency = 1
Status.Position = UDim2.fromOffset(12,34)
Status.Size = UDim2.new(1,-24,0,20)
Status.Font = Enum.Font.Gotham
Status.TextSize = 12
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.TextColor3 = Color3.fromRGB(180,180,185)
Status.Text = "Stopped"
Status.Parent = Main

local Scroll = Instance.new("ScrollingFrame")
Scroll.Position = UDim2.fromOffset(10,60)
Scroll.Size = UDim2.new(1,-20,1,-112)
Scroll.BackgroundColor3 = Color3.fromRGB(13,13,15)
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 4
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.CanvasSize = UDim2.fromOffset(0,0)
Scroll.Parent = Main
Instance.new("UICorner", Scroll).CornerRadius = UDim.new(0,7)

local LogLabel = Instance.new("TextLabel")
LogLabel.BackgroundTransparency = 1
LogLabel.Position = UDim2.fromOffset(7,6)
LogLabel.Size = UDim2.new(1,-14,0,0)
LogLabel.AutomaticSize = Enum.AutomaticSize.Y
LogLabel.Font = Enum.Font.Code
LogLabel.TextSize = 11
LogLabel.TextWrapped = false
LogLabel.TextXAlignment = Enum.TextXAlignment.Left
LogLabel.TextYAlignment = Enum.TextYAlignment.Top
LogLabel.TextColor3 = Color3.fromRGB(225,225,230)
LogLabel.Text = ""
LogLabel.Parent = Scroll

local Buttons = Instance.new("Frame")
Buttons.BackgroundTransparency = 1
Buttons.Position = UDim2.new(0,10,1,-44)
Buttons.Size = UDim2.new(1,-20,0,34)
Buttons.Parent = Main

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.Padding = UDim.new(0,7)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Parent = Buttons

local function button(text)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1/3,-5,1,0)
    b.BackgroundColor3 = Color3.fromRGB(39,39,44)
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 12
    b.Text = text
    b.AutoButtonColor = true
    b.Parent = Buttons
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,7)
    return b
end

local StartButton = button("START RECORDING")
local CopyButton = button("COPY LOGS")
local ClearButton = button("CLEAR / STOP")

local function refresh()
    LogLabel.Text = table.concat(logs, "\n")
    task.defer(function()
        Scroll.CanvasPosition = Vector2.new(0, math.max(0, LogLabel.AbsoluteSize.Y - Scroll.AbsoluteSize.Y + 16))
    end)
end

local function log(msg)
    if not recording then return end
    logs[#logs+1] = string.format("[%0.4f] %s", now(), msg)
    refresh()
end

local function disconnectAll()
    for _,c in ipairs(connections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(connections)
    watched = setmetatable({}, {__mode="k"})
    snapshotToken += 1
end

local function addConnection(c)
    connections[#connections+1] = c
end

local function pathOf(x)
    local ok, v = pcall(function() return x:GetFullName() end)
    return ok and v or tostring(x)
end

local function findGun()
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    local char = LocalPlayer.Character
    local gun = backpack and backpack:FindFirstChild("Gun")
    if not gun and char then gun = char:FindFirstChild("Gun") end
    return gun
end

local function liveToolIcons()
    local result = {}
    for _,d in ipairs(PlayerGui:GetDescendants()) do
        if d.Name == "ToolIcon" and (d:IsA("ImageLabel") or d:IsA("ImageButton")) then
            -- Exclude the BackpackScript template; focus on live BackpackFrame slots.
            if d:FindFirstAncestor("BackpackFrame") then
                result[#result+1] = d
            end
        end
    end
    return result
end

local function snapshot(reason)
    if not recording then return end
    local gun = findGun()
    log("SNAPSHOT | Reason=" .. reason ..
        " | Gun=" .. (gun and pathOf(gun) or "nil") ..
        " | GunTexture=" .. (gun and tostring(gun.TextureId) or "nil") ..
        " | GunKind=" .. (gun and imageKind(gun.TextureId) or "nil") ..
        " | LiveToolIcons=" .. tostring(#liveToolIcons()))
    for i,icon in ipairs(liveToolIcons()) do
        log("  ICON #" .. i .. " | Image=" .. tostring(icon.Image) ..
            " | Kind=" .. imageKind(icon.Image) ..
            " | Visible=" .. tostring(icon.Visible) ..
            " | Path=" .. pathOf(icon))
    end
end

local function burst(reason)
    local myToken = snapshotToken
    local delays = {0, .016, .05, .10, .20, .35, .55, .80, 1.10}
    for _,delay in ipairs(delays) do
        task.delay(delay, function()
            if recording and myToken == snapshotToken then
                snapshot(reason .. " +" .. tostring(delay) .. "s")
            end
        end)
    end
end

local function watchIcon(icon, source)
    if watched[icon] then return end
    watched[icon] = true
    log("TOOLICON DETECTED | Source=" .. source ..
        " | Image=" .. tostring(icon.Image) ..
        " | Kind=" .. imageKind(icon.Image) ..
        " | Path=" .. pathOf(icon))
    addConnection(icon:GetPropertyChangedSignal("Image"):Connect(function()
        log(">>> TOOLICON IMAGE CHANGED | Image=" .. tostring(icon.Image) ..
            " | Kind=" .. imageKind(icon.Image) ..
            " | Path=" .. pathOf(icon))
        burst("ToolIcon.Image changed")
    end))
    addConnection(icon.AncestryChanged:Connect(function(_, parent)
        log("TOOLICON ANCESTRY | Parent=" .. (parent and pathOf(parent) or "nil") ..
            " | Image=" .. tostring(icon.Image) ..
            " | Kind=" .. imageKind(icon.Image))
    end))
end

local function watchGun(gun, source)
    if watched[gun] then return end
    watched[gun] = true
    log("GUN DETECTED | Source=" .. source ..
        " | TextureId=" .. tostring(gun.TextureId) ..
        " | Kind=" .. imageKind(gun.TextureId) ..
        " | Path=" .. pathOf(gun))
    addConnection(gun:GetPropertyChangedSignal("TextureId"):Connect(function()
        log(">>> GUN TEXTURE CHANGED | TextureId=" .. tostring(gun.TextureId) ..
            " | Kind=" .. imageKind(gun.TextureId) ..
            " | Path=" .. pathOf(gun))
        burst("Gun.TextureId changed")
    end))
    addConnection(gun.AncestryChanged:Connect(function(_, parent)
        log("GUN ANCESTRY | Parent=" .. (parent and pathOf(parent) or "nil") ..
            " | TextureId=" .. tostring(gun.TextureId))
        burst("Gun ancestry changed")
    end))
end

local function inspect(desc, source)
    if desc.Name == "Gun" and desc:IsA("Tool") then
        watchGun(desc, source)
    elseif desc.Name == "ToolIcon" and (desc:IsA("ImageLabel") or desc:IsA("ImageButton")) then
        if desc:FindFirstAncestor("BackpackFrame") then
            watchIcon(desc, source)
        end
    elseif desc.Name == "BackpackItem" or desc.Name == "BackpackFrame" or desc.Name == "BackpackUI" then
        log("HOTBAR INSTANCE | Source=" .. source .. " | Name=" .. desc.Name ..
            " | Class=" .. desc.ClassName .. " | Path=" .. pathOf(desc))
    end
end

local function beginRecording()
    disconnectAll()
    table.clear(logs)
    startedAt = os.clock()
    recording = true
    Status.Text = "RECORDING — keep your selected skin unchanged and reproduce the hotbar failure"
    Status.TextColor3 = Color3.fromRGB(120,235,145)

    log("============================================================")
    log("BLIZZARD HOTBAR RACE DIAGNOSTIC - READ ONLY")
    log("============================================================")
    log("TEST START")
    log("Player=" .. LocalPlayer.Name)
    log("GingerscopeAssetId=" .. GINGERSCOPE_ASSET)
    log("IMPORTANT: diagnostic does not write ToolIcon.Image or Gun.TextureId")

    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    local char = LocalPlayer.Character
    log("Backpack=" .. (backpack and pathOf(backpack) or "nil"))
    log("Character=" .. (char and pathOf(char) or "nil"))

    for _,d in ipairs(PlayerGui:GetDescendants()) do inspect(d, "Initial PlayerGui") end
    if backpack then
        for _,d in ipairs(backpack:GetDescendants()) do inspect(d, "Initial Backpack") end
        addConnection(backpack.ChildAdded:Connect(function(x)
            log("BACKPACK CHILD ADDED | Name=" .. x.Name .. " | Class=" .. x.ClassName)
            inspect(x, "Backpack.ChildAdded")
            burst("Backpack child added " .. x.Name)
        end))
        addConnection(backpack.ChildRemoved:Connect(function(x)
            log("BACKPACK CHILD REMOVED | Name=" .. x.Name .. " | Class=" .. x.ClassName)
            burst("Backpack child removed " .. x.Name)
        end))
    end

    if char then
        for _,d in ipairs(char:GetDescendants()) do inspect(d, "Initial Character") end
        addConnection(char.ChildAdded:Connect(function(x)
            log("CHARACTER CHILD ADDED | Name=" .. x.Name .. " | Class=" .. x.ClassName)
            inspect(x, "Character.ChildAdded")
            burst("Character child added " .. x.Name)
        end))
        addConnection(char.ChildRemoved:Connect(function(x)
            log("CHARACTER CHILD REMOVED | Name=" .. x.Name .. " | Class=" .. x.ClassName)
            burst("Character child removed " .. x.Name)
        end))
    end

    addConnection(PlayerGui.DescendantAdded:Connect(function(x)
        inspect(x, "PlayerGui.DescendantAdded")
        if x.Name == "ToolIcon" or x.Name == "BackpackItem" then
            burst("PlayerGui added " .. x.Name)
        end
    end))
    addConnection(PlayerGui.DescendantRemoving:Connect(function(x)
        if x.Name == "ToolIcon" or x.Name == "BackpackItem" or x.Name == "BackpackFrame" then
            log("HOTBAR REMOVING | Name=" .. x.Name .. " | Class=" .. x.ClassName .. " | Path=" .. pathOf(x))
        end
    end))
    addConnection(LocalPlayer.CharacterAdded:Connect(function(newChar)
        log("CHARACTER ADDED | Path=" .. pathOf(newChar))
        burst("CharacterAdded")
    end))

    snapshot("Recording start")
    log("LIVE WATCH ACTIVE")
end

StartButton.MouseButton1Click:Connect(beginRecording)

CopyButton.MouseButton1Click:Connect(function()
    local all = table.concat(logs, "\n")
    if setclipboard then
        pcall(setclipboard, all)
        Status.Text = recording and "RECORDING — logs copied" or "Stopped — logs copied"
    elseif toclipboard then
        pcall(toclipboard, all)
        Status.Text = recording and "RECORDING — logs copied" or "Stopped — logs copied"
    else
        Status.Text = "Clipboard function unavailable"
    end
end)

ClearButton.MouseButton1Click:Connect(function()
    recording = false
    disconnectAll()
    table.clear(logs)
    LogLabel.Text = ""
    Scroll.CanvasPosition = Vector2.zero
    Status.Text = "Stopped — logs cleared"
    Status.TextColor3 = Color3.fromRGB(180,180,185)
end)

-- Start button is intentionally manual so you can set up the exact round/skin first.
