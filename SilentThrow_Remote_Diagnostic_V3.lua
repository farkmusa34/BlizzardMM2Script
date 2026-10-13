-- Silent Throw Remote Diagnostic V3 - Standalone, observation only.
-- Observes outgoing KnifeThrown:FireServer calls, never changes arguments.
-- Requires executor support for hookmetamethod, getnamecallmethod and newcclosure.
-- Hook remains installed after Stop, but becomes inert. Rejoin to fully remove it.

local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local UIS = game:GetService('UserInputService')
local LocalPlayer = Players.LocalPlayer
local guiParent = (gethui and gethui()) or game:GetService('CoreGui')

if getgenv and getgenv().SilentThrowRemoteDiagnosticV3 then
    pcall(function() getgenv().SilentThrowRemoteDiagnosticV3:Destroy() end)
end

local active, logs, gui = false, {}, nil
local connections = {}
local function now() return string.format('%.3f', os.clock()) end
local function log(s)
    local line = '[' .. now() .. '] ' .. s
    logs[#logs+1] = line
    if #logs > 450 then table.remove(logs, 1) end
    print('[SilentThrow V3] ' .. line)
end
local function vec(v)
    return string.format('(%.2f, %.2f, %.2f)', v.X, v.Y, v.Z)
end
local function formatArg(value)
    local t = typeof(value)
    if t == 'CFrame' then
        return 'CFrame pos=' .. vec(value.Position) .. ' look=' .. vec(value.LookVector)
    elseif t == 'Vector3' then
        return 'Vector3 ' .. vec(value)
    elseif t == 'Instance' then
        local ok, path = pcall(function() return value:GetFullName() end)
        return 'Instance ' .. (ok and path or value.Name)
    elseif t == 'table' then
        return 'table (not expanded)'
    end
    return t .. ' ' .. tostring(value)
end
local function nearestVisible()
    local character = LocalPlayer.Character
    local originPart = character and (character:FindFirstChild('Head') or character:FindFirstChild('HumanoidRootPart'))
    if not originPart then return 'none' end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character}
    local closest, distance = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local c = player.Character
            local hum = c and c:FindFirstChildOfClass('Humanoid')
            local part = c and (c:FindFirstChild('UpperTorso') or c:FindFirstChild('Torso') or c:FindFirstChild('HumanoidRootPart'))
            if hum and hum.Health > 0 and part then
                local delta = part.Position - originPart.Position
                local hit = workspace:Raycast(originPart.Position, delta, params)
                if (not hit or hit.Instance:IsDescendantOf(c)) and delta.Magnitude < distance then
                    closest, distance = player, delta.Magnitude
                end
            end
        end
    end
    if closest then return closest.Name .. ' distance=' .. string.format('%.1f', distance) end
    return 'none'
end

local screen = Instance.new('ScreenGui')
screen.Name = 'SilentThrowRemoteDiagnosticV3'
screen.ResetOnSpawn = false
screen.Parent = guiParent
gui = screen
local frame = Instance.new('Frame')
frame.Size = UDim2.fromOffset(315, 215)
frame.Position = UDim2.new(0.5, -157, 0.28, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 27, 34)
frame.Active = true
frame.Draggable = true
frame.Parent = screen
Instance.new('UICorner', frame).CornerRadius = UDim.new(0, 10)
local heading = Instance.new('TextLabel')
heading.Size = UDim2.new(1, -20, 0, 37)
heading.Position = UDim2.fromOffset(10, 8)
heading.BackgroundTransparency = 1
heading.TextColor3 = Color3.new(1,1,1)
heading.Font = Enum.Font.GothamBold
heading.TextSize = 15
heading.Text = 'Silent Throw - Remote Diagnostic V3'
heading.Parent = frame
local status = Instance.new('TextLabel')
status.Size = UDim2.new(1, -24, 0, 48)
status.Position = UDim2.fromOffset(12, 48)
status.BackgroundTransparency = 1
status.TextWrapped = true
status.TextColor3 = Color3.fromRGB(190, 195, 205)
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.Text = 'Ready. Press Start Throw, then manually throw.'
status.Parent = frame
local function button(label, x, y, callback)
    local b = Instance.new('TextButton')
    b.Size = UDim2.fromOffset(138, 43)
    b.Position = UDim2.fromOffset(x, y)
    b.BackgroundColor3 = Color3.fromRGB(51, 60, 76)
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 13
    b.Text = label
    b.Parent = frame
    Instance.new('UICorner', b).CornerRadius = UDim.new(0, 7)
    b.MouseButton1Click:Connect(callback)
end

local hooked, hookError = false, nil
local function installHook()
    if hooked then return true end
    if not (hookmetamethod and getnamecallmethod and newcclosure) then
        hookError = 'Executor lacks hookmetamethod/getnamecallmethod/newcclosure'
        return false
    end
    local old
    local ok, err = pcall(function()
        old = hookmetamethod(game, '__namecall', newcclosure(function(self, ...)
            -- Preserve original call, arguments and return values. Never yield inside hook.
            if active and typeof(self) == 'Instance' and self.Name == 'KnifeThrown' and getnamecallmethod() == 'FireServer' then
                local args = table.pack(...)
                local name = self.Name
                task.defer(function()
                    if not active then return end
                    log('MANUAL THROW REMOTE: ' .. name .. ':FireServer argc=' .. args.n)
                    for i = 1, args.n do log('  arg' .. i .. ' = ' .. formatArg(args[i])) end
                    local camera = workspace.CurrentCamera
                    if camera then log('  camera=' .. formatArg(camera.CFrame)) end
                    log('  closestVisible=' .. nearestVisible())
                end)
            end
            return old(self, ...)
        end))
    end)
    if not ok then hookError = tostring(err); return false end
    hooked = true
    return true
end

local function watchCharacter(character)
    local function watchTool(tool)
        if not tool:IsA('Tool') then return end
        if not string.find(string.lower(tool.Name), 'knife', 1, true) then return end
        connections[#connections+1] = tool.Activated:Connect(function()
            if active then log('Tool.Activated ' .. tool.Name .. ' (throw or stab)') end
        end)
    end
    for _, child in ipairs(character:GetChildren()) do watchTool(child) end
    connections[#connections+1] = character.ChildAdded:Connect(watchTool)
end
if LocalPlayer.Character then watchCharacter(LocalPlayer.Character) end
connections[#connections+1] = LocalPlayer.CharacterAdded:Connect(watchCharacter)

button('Start Throw', 12, 105, function()
    if not installHook() then
        status.Text = 'Cannot observe remote: ' .. tostring(hookError)
        log('HOOK UNAVAILABLE: ' .. tostring(hookError))
        return
    end
    active = true
    status.Text = 'Recording outgoing KnifeThrown calls. Throw normally.'
    log('START recording outgoing KnifeThrown:FireServer calls')
end)
button('Stop Throw', 165, 105, function()
    log('STOP recording')
    active = false
    status.Text = 'Stopped. Press Copy Logs to share results.'
end)
button('Copy Logs', 12, 156, function()
    local output = table.concat(logs, '\n')
    if setclipboard then
        setclipboard(output)
        status.Text = 'Logs copied (' .. #logs .. ' lines).'
    else
        status.Text = 'Clipboard unsupported; check executor console.'
        print(output)
    end
end)
button('Clear Logs', 165, 156, function()
    table.clear(logs)
    status.Text = 'Logs cleared.'
    log('Logs cleared')
end)

local api = {}
function api:Destroy()
    active = false
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    screen:Destroy()
end
if getgenv then getgenv().SilentThrowRemoteDiagnosticV3 = api end
log('Diagnostic ready. Observation only; hook does not change FireServer arguments.')
