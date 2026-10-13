-- Silent Throw Projectile Diagnostic (observation only)
-- Standalone; no Blizzard/Combat.lua dependency.
-- Does not hook remotes, change aim, or activate tools.
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local UIS = game:GetService('UserInputService')
local LP = Players.LocalPlayer
local PG = LP:WaitForChild('PlayerGui')
local old = PG:FindFirstChild('SilentThrowProjectileDiagnostic')
if old then old:Destroy() end
local running, logs, connections, seen = false, {}, {}, {}
local MAX_LOGS = 400
local function log(s)
    local line = string.format('[%.3f] %s', os.clock(), tostring(s))
    table.insert(logs,line)
    if #logs > MAX_LOGS then table.remove(logs,1) end
    print('[SilentThrowDiag] '..line)
end
local function fmt(v)
    return string.format('(%.2f, %.2f, %.2f)',v.X,v.Y,v.Z)
end
local function isKnifeName(s)
    s = string.lower(s)
    return s:find('knife',1,true) or s:find('blade',1,true) or s:find('throw',1,true)
end
local gui = Instance.new('ScreenGui')
gui.Name='SilentThrowProjectileDiagnostic';gui.ResetOnSpawn=false;gui.Parent=PG
gui.DisplayOrder=90
local frame=Instance.new('Frame');frame.Size=UDim2.fromOffset(300,250);frame.Position=UDim2.new(0.5,-150,0.25,0);frame.BackgroundColor3=Color3.fromRGB(25,28,37);frame.Parent=gui
Instance.new('UICorner',frame).CornerRadius=UDim.new(0,12)
local title=Instance.new('TextLabel');title.Size=UDim2.new(1,-18,0,35);title.Position=UDim2.fromOffset(9,4);title.BackgroundTransparency=1;title.Text='Silent Throw | Projectile Diagnostic';title.TextColor3=Color3.new(1,1,1);title.TextSize=16;title.Font=Enum.Font.GothamBold;title.Parent=frame
local status=Instance.new('TextLabel');status.Size=UDim2.new(1,-20,0,35);status.Position=UDim2.fromOffset(10,42);status.BackgroundTransparency=1;status.Text='Stopped';status.TextColor3=Color3.fromRGB(200,205,215);status.TextWrapped=true;status.TextSize=13;status.Font=Enum.Font.Gotham;status.Parent=frame
local function button(name,x,y,callback)
    local b=Instance.new('TextButton');b.Size=UDim2.fromOffset(132,48);b.Position=UDim2.fromOffset(x,y);b.BackgroundColor3=Color3.fromRGB(53,63,82);b.TextColor3=Color3.new(1,1,1);b.TextSize=14;b.Font=Enum.Font.GothamSemibold;b.Text=name;b.Parent=frame
    Instance.new('UICorner',b).CornerRadius=UDim.new(0,8)
    b.MouseButton1Click:Connect(callback)
    return b
end
local function clearConnections()
    for _,c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    table.clear(connections)
end
local function closestVisible()
    local character=LP.Character
    local head=character and (character:FindFirstChild('Head') or character:FindFirstChild('HumanoidRootPart'))
    if not head then return 'none' end
    local best,dist=nil,math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and p.Character then
            local hum=p.Character:FindFirstChildOfClass('Humanoid')
            local part=p.Character:FindFirstChild('HumanoidRootPart') or p.Character:FindFirstChild('Head')
            if hum and hum.Health>0 and part then
                local delta=part.Position-head.Position
                local params=RaycastParams.new()
                params.FilterType=Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances={character}
                local hit=workspace:Raycast(head.Position,delta,params)
                if (not hit or hit.Instance:IsDescendantOf(p.Character)) and delta.Magnitude<dist then
                    best,dist=p.Name,delta.Magnitude
                end
            end
        end
    end
    return best and (best..' distance='..string.format('%.1f',dist)) or 'none'
end
local function watchPart(part)
    if not running or seen[part] or not part:IsA('BasePart') then return end
    -- Name-based candidates only: game-specific projectiles may use other names.
    if not isKnifeName(part.Name) then return end
    if LP.Character and part:IsDescendantOf(LP.Character) then return end
    seen[part]=true
    local born=os.clock()
    local last=part.Position
    local count=0
    log('Candidate projectile SPAWN name='..part:GetFullName()..' pos='..fmt(last)..' velocity='..fmt(part.AssemblyLinearVelocity))
    local conn
    conn=RunService.Heartbeat:Connect(function()
        if not running or not part.Parent or os.clock()-born>2 then
            if conn then conn:Disconnect() end
            if running then log('Candidate projectile END name='..part.Name..' samples='..count) end
            return
        end
        if os.clock()-born>=count*0.15 then
            count=count+1
            local pos=part.Position
            log('Projectile sample '..count..' name='..part.Name..' pos='..fmt(pos)..' velocity='..fmt(part.AssemblyLinearVelocity)..' delta='..fmt(pos-last))
            last=pos
        end
    end)
    table.insert(connections,conn)
end
local function start()
    if running then return end
    running=true;seen={}
    status.Text='Recording: manually throw knives'
    log('START recording. No remote hooks or throw modifications.')
    local character=LP.Character
    local knife=character and character:FindFirstChild('Knife')
    if knife and knife:IsA('Tool') then
        table.insert(connections,knife.Activated:Connect(function()
            if running then
                local cam=workspace.CurrentCamera
                log('Knife Tool.Activated; cameraLook='..(cam and fmt(cam.CFrame.LookVector) or 'none')..'; closestVisible='..closestVisible())
            end
        end))
    else log('Knife not equipped at start; projectile watcher remains active.') end
    table.insert(connections,workspace.DescendantAdded:Connect(function(obj)
        if not running or not obj:IsA('BasePart') then return end
        -- Deferred to avoid interfering with projectile creation.
        task.defer(function() if running then watchPart(obj) end end)
    end))
    -- Some games reuse existing parts instead of creating new ones.
    log('Watcher detects newly created parts named knife/blade/throw. Other projectile names may be missed.')
end
local function stop()
    if not running then return end
    running=false;clearConnections()
    status.Text='Stopped | '..#logs..' log lines'
    log('STOP recording')
end
button('Start Throw',12,90,start)
button('Stop Throw',155,90,stop)
button('Copy Logs',12,148,function()
    local data=table.concat(logs,'\n')
    if typeof(setclipboard)=='function' then
        local ok=pcall(setclipboard,data)
        status.Text=ok and ('Copied '..#logs..' lines') or 'Clipboard failed; check console'
    else
        status.Text='Clipboard unavailable; check console'
        print(data)
    end
end)
button('Clear Logs',155,148,function() table.clear(logs);status.Text=running and 'Recording | logs cleared' or 'Stopped | logs cleared' end)
local note=Instance.new('TextLabel');note.Size=UDim2.new(1,-20,0,35);note.Position=UDim2.fromOffset(10,205);note.BackgroundTransparency=1;note.Text='Move panel using title. Does not alter throws.';note.TextColor3=Color3.fromRGB(175,183,195);note.TextSize=11;note.Parent=frame
local dragging,dragStart,frameStart=false,nil,nil
title.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
        dragging=true;dragStart=input.Position;frameStart=frame.Position
        local c;c=input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false;c:Disconnect() end end)
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseMovement) then
        local delta=input.Position-dragStart
        frame.Position=UDim2.new(frameStart.X.Scale,frameStart.X.Offset+delta.X,frameStart.Y.Scale,frameStart.Y.Offset+delta.Y)
    end
end)
gui.Destroying:Connect(function() running=false;clearConnections() end)
log('Diagnostic ready. Press Start Throw, then use MM2 normal Throw button.')
