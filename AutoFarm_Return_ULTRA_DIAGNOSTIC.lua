--============================================================
-- AUTO FARM RETURN - ULTRA FOCUSED DIAGNOSTIC
-- Focus: trajectory (X/Y/Z), Auto Farm OFF, floor candidates,
--        return/teleport jumps, and 2 seconds after return.
--============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

local old = PG:FindFirstChild("AutoFarmReturnUltraDiagnostic")
if old then old:Destroy() end

local Gui = Instance.new("ScreenGui")
Gui.Name = "AutoFarmReturnUltraDiagnostic"
Gui.ResetOnSpawn = false
Gui.DisplayOrder = 999999
Gui.Parent = PG

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(390, 310)
Main.Position = UDim2.new(0.5, -195, 0.5, -155)
Main.BackgroundColor3 = Color3.fromRGB(22,22,26)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = Gui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,-10,0,32)
Title.Position = UDim2.fromOffset(5,2)
Title.BackgroundTransparency = 1
Title.Text = "RETURN ULTRA DIAGNOSTIC"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.Parent = Main

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1,-20,0,155)
Status.Position = UDim2.fromOffset(10,38)
Status.BackgroundTransparency = 1
Status.TextColor3 = Color3.fromRGB(220,220,220)
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.TextYAlignment = Enum.TextYAlignment.Top
Status.Font = Enum.Font.Code
Status.TextSize = 12
Status.TextWrapped = false
Status.Text = "Watching trajectory..."
Status.Parent = Main

local function button(text, x, y, w)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(w or 175,42)
    b.Position = UDim2.fromOffset(x,y)
    b.BackgroundColor3 = Color3.fromRGB(45,45,52)
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.Text = text
    b.Parent = Main
    return b
end

local MarkOff = button("MARK AUTO FARM OFF",10,202,180)
local Copy = button("COPY LOGS",200,202,180)
local Clear = button("CLEAR",10,254,180)
local Close = button("CLOSE",200,254,180)

local logs = {}
local samples = {}
local MAX_SAMPLES = 24
local lastPos
local lastCF
local lastState
local monitoringReturn = false
local returnStart = 0
local returnBefore
local jumpCaptured = false

local function now()
    return os.clock()
end

local function vec(v)
    return string.format("(%.3f, %.3f, %.3f)",v.X,v.Y,v.Z)
end

local function add(s)
    logs[#logs+1] = string.format("[%.3f] %s",now(),s)
end

local function getChar()
    local c = LP.Character
    if not c then return end
    return c, c:FindFirstChild("HumanoidRootPart"), c:FindFirstChildOfClass("Humanoid")
end

local function direction(v)
    local h = Vector2.new(v.X,v.Z).Magnitude
    local ay = math.abs(v.Y)
    if h < 2 and v.Y > 2 then return "VERTICAL-UP" end
    if h < 2 and v.Y < -2 then return "VERTICAL-DOWN" end
    if h >= 2 and v.Y > 2 then return "DIAGONAL-UP" end
    if h >= 2 and v.Y < -2 then return "DIAGONAL-DOWN" end
    if h >= 2 then return "HORIZONTAL" end
    return "STATIONARY"
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function floorsBelow(origin)
    local c = LP.Character
    rayParams.FilterDescendantsInstances = c and {c} or {}
    local hits = {}
    local y = origin.Y
    local x,z = origin.X,origin.Z

    -- Repeated downward casts let us see multiple levels/floors.
    for i=1,8 do
        local start = Vector3.new(x,y,z)
        local hit = workspace:Raycast(start,Vector3.new(0,-300,0),rayParams)
        if not hit then break end

        hits[#hits+1] = {
            pos = hit.Position,
            part = hit.Instance,
            dist = origin.Y-hit.Position.Y
        }

        y = hit.Position.Y - 0.12
        if origin.Y-y > 300 then break end
    end
    return hits
end

local function clearanceAt(p)
    local c = LP.Character
    local op = OverlapParams.new()
    op.FilterType = Enum.RaycastFilterType.Exclude
    op.FilterDescendantsInstances = c and {c} or {}

    -- Approximate standing-character volume above candidate floor.
    local center = p + Vector3.new(0,3,0)
    local parts = workspace:GetPartBoundsInBox(CFrame.new(center),Vector3.new(4,6,4),op)
    local blockers = {}
    for _,part in ipairs(parts) do
        if part.CanCollide then
            blockers[#blockers+1] = part:GetFullName()
        end
    end
    return #blockers == 0, blockers
end

local function dumpOff(reason)
    local c,hrp,hum = getChar()
    if not hrp or not hum then
        add("OFF MARK FAILED: character unavailable")
        return
    end

    local v = hrp.AssemblyLinearVelocity
    local hs = Vector2.new(v.X,v.Z).Magnitude

    add("============================================================")
    add("AUTO FARM OFF | "..(reason or "manual"))
    add("OFF POSITION = "..vec(hrp.Position))
    add("VELOCITY = "..vec(v))
    add(string.format("HorizontalSpeed=%.3f | VerticalSpeed=%.3f",hs,v.Y))
    add("DIRECTION = "..direction(v))
    add("DESCENDING = "..tostring(v.Y < -2))
    add("HumanoidState = "..tostring(hum:GetState()))
    add("---- PRE-OFF TRAJECTORY (oldest -> newest) ----")

    for _,s in ipairs(samples) do
        add(string.format(
            "T-%0.3fs Pos=%s Vel=%s H=%.2f V=%.2f Dir=%s",
            now()-s.t,vec(s.p),vec(s.v),
            Vector2.new(s.v.X,s.v.Z).Magnitude,s.v.Y,direction(s.v)
        ))
    end

    add("---- FLOORS DIRECTLY BELOW OFF POSITION ----")
    local floors = floorsBelow(hrp.Position)
    if #floors == 0 then
        add("NO FLOOR HIT BELOW")
    else
        for i,f in ipairs(floors) do
            local clear, blockers = clearanceAt(f.pos)
            add(string.format(
                "#%d FloorY=%.3f VerticalDistance=%.3f Part=%s Clearance=%s",
                i,f.pos.Y,f.dist,f.part:GetFullName(),clear and "PASS" or "FAIL"
            ))
            if not clear then
                add("   Blockers: "..table.concat(blockers," | "))
            end
        end
    end

    returnBefore = hrp.Position
    monitoringReturn = true
    returnStart = now()
    jumpCaptured = false
    add("---- WATCHING FOR RETURN / POSITION JUMP ----")
end

MarkOff.MouseButton1Click:Connect(function()
    dumpOff("MARK BUTTON PRESSED")
end)

Copy.MouseButton1Click:Connect(function()
    local text = table.concat(logs,"\n")
    if setclipboard then
        setclipboard(text)
        Copy.Text = "COPIED"
        task.delay(1,function()
            if Copy then Copy.Text = "COPY LOGS" end
        end)
    else
        Copy.Text = "NO CLIPBOARD API"
    end
end)

Clear.MouseButton1Click:Connect(function()
    table.clear(logs)
    table.clear(samples)
    add("LOG CLEARED")
end)

Close.MouseButton1Click:Connect(function()
    Gui:Destroy()
end)

-- Optional integration:
-- Your Auto Farm script can call:
-- _G.AutoFarmReturnDiagnosticOff("AUTO FARM TOGGLE")
_G.AutoFarmReturnDiagnosticOff = dumpOff

local postTimes = {0.10,0.25,0.50,1.00,2.00}
local posted = {}

RunService.Heartbeat:Connect(function()
    local c,hrp,hum = getChar()
    if not hrp or not hum then return end

    local t = now()
    local p = hrp.Position
    local v = hrp.AssemblyLinearVelocity

    samples[#samples+1] = {t=t,p=p,v=v}
    while #samples > MAX_SAMPLES do table.remove(samples,1) end

    Status.Text = string.format(
        "Pos: %s\nVel: %s\nHorizontal: %.2f\nVertical: %.2f\nDirection: %s\nState: %s\n\nPress MARK exactly when Auto Farm is turned OFF.",
        vec(p),vec(v),Vector2.new(v.X,v.Z).Magnitude,v.Y,direction(v),tostring(hum:GetState())
    )

    if lastPos then
        local delta = p-lastPos
        local dist = delta.Magnitude

        -- Focus specifically on abrupt CFrame/return changes.
        if monitoringReturn and dist >= 5 and not jumpCaptured then
            jumpCaptured = true
            add("RETURN/POSITION JUMP DETECTED")
            add("Before = "..vec(lastPos))
            add("After  = "..vec(p))
            add(string.format(
                "DeltaXYZ=%s | 3D=%.3f | Horizontal=%.3f | Vertical=%.3f",
                vec(delta),dist,Vector2.new(delta.X,delta.Z).Magnitude,delta.Y
            ))

            local floors = floorsBelow(p)
            add("---- FLOORS BELOW ACTUAL DESTINATION ----")
            for i,f in ipairs(floors) do
                local clear, blockers = clearanceAt(f.pos)
                add(string.format(
                    "#%d FloorY=%.3f VDist=%.3f Part=%s Clearance=%s",
                    i,f.pos.Y,f.dist,f.part:GetFullName(),clear and "PASS" or "FAIL"
                ))
                if not clear then
                    add("   Blockers: "..table.concat(blockers," | "))
                end
            end
        end
    end

    if monitoringReturn then
        local elapsed = t-returnStart
        for _,pt in ipairs(postTimes) do
            local key = tostring(pt)
            if elapsed >= pt and not posted[key] then
                posted[key] = true
                add(string.format(
                    "POST %.2fs | Pos=%s Vel=%s H=%.2f V=%.2f Dir=%s State=%s CanCollide=%s AutoRotate=%s",
                    pt,vec(p),vec(v),Vector2.new(v.X,v.Z).Magnitude,v.Y,
                    direction(v),tostring(hum:GetState()),
                    tostring(hrp.CanCollide),tostring(hum.AutoRotate)
                ))
            end
        end

        if elapsed >= 2.05 then
            add("---- FINAL ----")
            add("Position="..vec(p))
            add("State="..tostring(hum:GetState()))
            add("Direction="..direction(v))
            add("============================================================")
            monitoringReturn = false
            table.clear(posted)
        end
    end

    if lastState and hum:GetState() ~= lastState and monitoringReturn then
        add("STATE "..tostring(lastState).." -> "..tostring(hum:GetState()))
    end

    lastState = hum:GetState()
    lastPos = p
    lastCF = hrp.CFrame
end)

add("ULTRA RETURN DIAGNOSTIC STARTED")
add("Press MARK AUTO FARM OFF at the same moment Auto Farm is disabled.")
add("For exact integration, call _G.AutoFarmReturnDiagnosticOff() from the Auto Farm toggle-off code.")
