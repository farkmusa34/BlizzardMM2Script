-- SILENT THROW DIAGNOSTIC - STANDALONE / OBSERVATION ONLY
-- Controls: Start Observing, Stop Observing, Copy Logs, Clear Logs
-- Does not fire remotes, redirect throws, or change the camera.
-- Safe mode: no remote interception or gameplay hooks.

local Players = game:GetService('Players')
local UIS = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local player = Players.LocalPlayer
local guiParent = player:WaitForChild('PlayerGui')

local previous = getgenv and getgenv().__SilentThrowDiagnostic
if previous and previous.Destroy then pcall(previous.Destroy) end

local D = {running=false, logs={}, connections={}, lastActivation=0, remoteCount=0}
if getgenv then getgenv().__SilentThrowDiagnostic = D end

local function formatValue(v)
    local kind = typeof(v)
    if kind == 'CFrame' then
        local p = v.Position
        return string.format('CFrame(pos=%.3f, %.3f, %.3f; look=%.3f, %.3f, %.3f)',p.X,p.Y,p.Z,v.LookVector.X,v.LookVector.Y,v.LookVector.Z)
    elseif kind == 'Vector3' then
        return string.format('Vector3(%.3f, %.3f, %.3f)',v.X,v.Y,v.Z)
    elseif kind == 'Instance' then
        return v:GetFullName()
    else
        return tostring(v)
    end
end

local function log(message)
    if not D.running then return end
    local line = string.format('[%.3f] %s',os.clock(),message)
    table.insert(D.logs,line)
    if #D.logs > 400 then table.remove(D.logs,1) end
    print('[SILENT THROW DIAG] '..line)
    if D.output then
        D.output.Text = table.concat(D.logs,'\n')
    end
end

local function isKnife(tool)
    return tool and tool:IsA('Tool') and (tool.Name:lower():find('knife',1,true) ~= nil or tool:GetAttribute('IsKnife') == true)
end

local function getKnife()
    local char = player.Character
    if not char then return nil end
    for _,obj in ipairs(char:GetChildren()) do
        if isKnife(obj) then return obj end
    end
    return nil
end

local function targetSnapshot()
    local char = player.Character
    local root = char and char:FindFirstChild('HumanoidRootPart')
    local cam = workspace.CurrentCamera
    if not root or not cam then return 'no root/camera' end
    local best,dist,visible = nil,math.huge,false
    for _,other in ipairs(Players:GetPlayers()) do
        if other ~= player and other.Character then
            local hum = other.Character:FindFirstChildOfClass('Humanoid')
            local part = other.Character:FindFirstChild('UpperTorso') or other.Character:FindFirstChild('Torso') or other.Character:FindFirstChild('HumanoidRootPart')
            if hum and hum.Health > 0 and part then
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = {char}
                params.IgnoreWater = true
                local delta = part.Position-root.Position
                local hit = workspace:Raycast(root.Position,delta,params)
                local clear = not hit or hit.Instance:IsDescendantOf(other.Character)
                local distance = delta.Magnitude
                if clear and distance < dist then best,dist,visible = other,distance,true end
            end
        end
    end
    return string.format('camera=%s; closestVisible=%s; distance=%s; visible=%s',formatValue(cam.CFrame),best and best.Name or 'none',best and string.format('%.2f',dist) or 'n/a',tostring(visible))
end

local function disconnectAll()
    for _,connection in ipairs(D.connections) do pcall(function() connection:Disconnect() end) end
    table.clear(D.connections)
end

local function bindKnife(tool)
    if not isKnife(tool) or D.boundKnife == tool then return end
    D.boundKnife = tool
    table.insert(D.connections,tool.Activated:Connect(function()
        if not D.running then return end
        D.lastActivation = os.clock()
        log('Knife Tool.Activated: '..tool.Name)
        task.defer(function() if D.running then log('Activation snapshot | '..targetSnapshot()) end end)
    end))
    table.insert(D.connections,tool.Deactivated:Connect(function()
        log('Knife Tool.Deactivated: '..tool.Name)
    end))
    log('Bound equipped knife: '..tool.Name)
end

local function start()
    if D.running then return end
    D.running = true
    disconnectAll()
    D.boundKnife = nil
    log('START observing. Throw manually several times; test visible target and wall-blocked target.')
    local char = player.Character
    if char then
        bindKnife(getKnife())
        table.insert(D.connections,char.ChildAdded:Connect(function(child)
            if isKnife(child) then bindKnife(child) end
        end))
        table.insert(D.connections,char.ChildRemoved:Connect(function(child)
            if child == D.boundKnife then D.boundKnife = nil; log('Knife unequipped') end
        end))
    end
    table.insert(D.connections,player.CharacterAdded:Connect(function(newChar)
        log('Character respawned; press Stop then Start to rebind the new knife')
    end))
    table.insert(D.connections,UIS.InputBegan:Connect(function(input,processed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            log('InputBegan '..input.UserInputType.Name..' processed='..tostring(processed))
        end
    end))
    table.insert(D.connections,UIS.InputEnded:Connect(function(input,processed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            log('InputEnded '..input.UserInputType.Name..' processed='..tostring(processed))
        end
    end))
end

local function stop()
    if not D.running then return end
    log('STOP observing')
    D.running = false
    disconnectAll()
    D.boundKnife = nil
end

-- SAFE MODE: No __namecall hooks. Observes tool activation and user input only.
-- Remote arguments cannot be captured by this non-invasive version.

local screen = Instance.new('ScreenGui')
screen.Name = 'SilentThrowDiagnostic'
screen.ResetOnSpawn = false
screen.Parent = guiParent
D.screen = screen
local frame = Instance.new('Frame')
frame.Size = UDim2.fromOffset(340,360)
frame.Position = UDim2.new(0.5,-170,0.5,-180)
frame.BackgroundColor3 = Color3.fromRGB(24,27,36)
frame.Active = true
frame.Draggable = true
frame.Parent = screen
Instance.new('UICorner',frame).CornerRadius = UDim.new(0,12)
local heading = Instance.new('TextLabel')
heading.Size = UDim2.new(1,-16,0,42)
heading.Position = UDim2.fromOffset(8,4)
heading.BackgroundTransparency = 1
heading.Text = 'SILENT THROW DIAGNOSTIC'
heading.TextColor3 = Color3.new(1,1,1)
heading.TextScaled = true
heading.Font = Enum.Font.GothamBold
heading.Parent = frame
local buttonNames = {'Start Throw','Stop Throw','Copy Logs','Clear Logs'}
local funcs = {
    function() start() end,
    function() stop() end,
    function()
        local output = table.concat(D.logs,'\n')
        if type(setclipboard) == 'function' then
            setclipboard(output)
            print('[SILENT THROW DIAG] Logs copied ('..#D.logs..' lines)')
        else
            warn('[SILENT THROW DIAG] Clipboard unavailable; select text in log box or use console')
        end
    end,
    function() table.clear(D.logs); if D.output then D.output.Text='' end end
}
for i,name in ipairs(buttonNames) do
    local btn = Instance.new('TextButton')
    btn.Size = UDim2.new(0.5,-12,0,38)
    btn.Position = UDim2.new((i-1)%2*0.5,8+((i-1)%2)*4,0,54+math.floor((i-1)/2)*45)
    btn.BackgroundColor3 = Color3.fromRGB(48,63,90)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Text = name
    btn.Parent = frame
    Instance.new('UICorner',btn).CornerRadius = UDim.new(0,7)
    btn.MouseButton1Click:Connect(funcs[i])
end
local logBox = Instance.new('TextBox')
logBox.Size = UDim2.new(1,-16,1,-156)
logBox.Position = UDim2.fromOffset(8,148)
logBox.BackgroundColor3 = Color3.fromRGB(13,16,23)
logBox.TextColor3 = Color3.fromRGB(215,226,243)
logBox.TextXAlignment = Enum.TextXAlignment.Left
logBox.TextYAlignment = Enum.TextYAlignment.Top
logBox.TextWrapped = true
logBox.TextSize = 11
logBox.Font = Enum.Font.Code
logBox.MultiLine = true
logBox.ClearTextOnFocus = false
logBox.TextEditable = false
logBox.Text = ''
logBox.Parent = frame
D.output = logBox
D.Destroy = function()
    stop()
    if D.screen then D.screen:Destroy() end
end
print('[SILENT THROW DIAG] Ready. Press Start Throw, throw manually, then Copy Logs.')
