-- Blizzard Auto Farm / Intermission Diagnostic (observation only)
-- Run separately. Turn ON Auto Farm Coins + Farm Underground.
-- Capture from active round through 5 seconds of intermission.
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local player = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G
if env.BlizzardIntermissionDiag and env.BlizzardIntermissionDiag.Stop then
    pcall(env.BlizzardIntermissionDiag.Stop)
end
local diag = {Running=false, Lines={}, Connection=nil}
env.BlizzardIntermissionDiag = diag
local gui = Instance.new('ScreenGui')
gui.Name = 'BlizzardIntermissionDiag'
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild('PlayerGui')
local frame = Instance.new('Frame')
frame.Size = UDim2.fromOffset(270,144)
frame.Position = UDim2.new(0.5,-135,0.22,0)
frame.BackgroundColor3 = Color3.fromRGB(27,27,38)
frame.Active = true
frame.Draggable = true
frame.Parent = gui
local corner = Instance.new('UICorner',frame)
corner.CornerRadius = UDim.new(0,9)
local title = Instance.new('TextLabel')
title.Size = UDim2.new(1,-12,0,30)
title.Position = UDim2.fromOffset(6,5)
title.BackgroundTransparency = 1
title.Text = 'Farm / Intermission Diagnostic'
title.TextColor3 = Color3.new(1,1,1)
title.TextSize = 15
title.Font = Enum.Font.GothamBold
title.Parent = frame
local status = Instance.new('TextLabel')
status.Size = UDim2.new(1,-12,0,25)
status.Position = UDim2.fromOffset(6,34)
status.BackgroundTransparency = 1
status.Text = 'Ready - capture during active round'
status.TextColor3 = Color3.fromRGB(190,190,205)
status.TextSize = 12
status.Font = Enum.Font.Gotham
status.Parent = frame
local function button(label,x,callback)
    local b=Instance.new('TextButton')
    b.Size=UDim2.fromOffset(119,32)
    b.Position=UDim2.fromOffset(x,66)
    b.BackgroundColor3=Color3.fromRGB(91,66,160)
    b.TextColor3=Color3.new(1,1,1)
    b.TextSize=13
    b.Font=Enum.Font.GothamSemibold
    b.Text=label
    b.Parent=frame
    Instance.new('UICorner',b).CornerRadius=UDim.new(0,6)
    b.MouseButton1Click:Connect(callback)
    return b
end
local function readFlags()
    local mm2=env.MM2_V85_SPLIT or _G.MM2_V85_SPLIT
    return mm2 and mm2.Flags
end
local function log(line)
    diag.Lines[#diag.Lines+1]=line
    if #diag.Lines>900 then table.remove(diag.Lines,1) end
end
local function sample()
    local c=player.Character
    local hrp=c and c:FindFirstChild('HumanoidRootPart')
    local hum=c and c:FindFirstChildOfClass('Humanoid')
    local flags=readFlags()
    local phase='unknown'
    local mm2=env.MM2_V85_SPLIT or _G.MM2_V85_SPLIT
    if mm2 and type(mm2.IsPreRoundActive)=='function' then
        local ok,result=pcall(mm2.IsPreRoundActive)
        if ok then phase=result and 'INTERMISSION' or 'ROUND' end
    end
    if not hrp then
        log(string.format('t=%.2f phase=%s HRP=MISSING AF=%s UG=%s',os.clock()-diag.Started,phase,tostring(flags and flags.AutoFarm),tostring(flags and flags.FarmUnderground)))
        return
    end
    local p=hrp.Position
    local v=hrp.AssemblyLinearVelocity
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances=c and {c} or {}
    params.RespectCanCollide=true
    local hit=workspace:Raycast(p,Vector3.new(0,-150,0),params)
    local floor=hit and string.format('%.2f',p.Y-hit.Position.Y) or 'NONE'
    local align=hrp:FindFirstChild('FarmAlign')
    local target=(align and align:IsA('AlignPosition')) and string.format('%.2f',align.Position.Y) or 'NONE'
    local collide=hrp.CanCollide and 'Y' or 'N'
    log(string.format('t=%.2f phase=%s AF=%s UG=%s pos=(%.1f,%.2f,%.1f) vy=%.2f speed=%.1f state=%s floorDist=%s HRPSizeY=%.1f collide=%s alignY=%s',
        os.clock()-diag.Started,phase,tostring(flags and flags.AutoFarm),tostring(flags and flags.FarmUnderground),
        p.X,p.Y,p.Z,v.Y,v.Magnitude,hum and hum:GetState().Name or 'NONE',floor,hrp.Size.Y,collide,target))
end
function diag.Stop()
    diag.Running=false
    if diag.Connection then diag.Connection:Disconnect();diag.Connection=nil end
    if gui then gui:Destroy() end
end
local record=button('Start Recording',10,function()
    if diag.Running then
        diag.Running=false
        if diag.Connection then diag.Connection:Disconnect();diag.Connection=nil end
        status.Text='Stopped - '..#diag.Lines..' samples'
        record.Text='Start Recording'
    else
        diag.Running=true
        diag.Started=os.clock()
        log('--- NEW CAPTURE ---')
        local elapsed=0
        diag.Connection=RunService.Heartbeat:Connect(function(dt)
            elapsed=elapsed+dt
            if elapsed>=0.2 then
                elapsed=0
                sample()
                status.Text='Recording: '..#diag.Lines..' lines'
            end
        end)
        record.Text='Stop Recording'
    end
end)
button('Copy Logs',140,function()
    local s=table.concat(diag.Lines,'\n')
    if type(setclipboard)=='function' then
        setclipboard(s)
        status.Text='Copied '..#diag.Lines..' lines'
    else
        status.Text='Clipboard not supported'
        print(s)
    end
end)
local clear=Instance.new('TextButton')
clear.Size=UDim2.fromOffset(250,29)
clear.Position=UDim2.fromOffset(10,105)
clear.Text='Clear Logs'
clear.Font=Enum.Font.Gotham
clear.TextSize=12
clear.TextColor3=Color3.new(1,1,1)
clear.BackgroundColor3=Color3.fromRGB(54,54,67)
clear.Parent=frame
Instance.new('UICorner',clear).CornerRadius=UDim.new(0,6)
clear.MouseButton1Click:Connect(function()
    table.clear(diag.Lines)
    status.Text='Logs cleared'
end)
