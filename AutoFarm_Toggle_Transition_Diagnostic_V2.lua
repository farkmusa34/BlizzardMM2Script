-- AUTO FARM TOGGLE TRANSITION DIAGNOSTIC V2
-- READ-ONLY game observer: Start / Copy / Clear
-- Does NOT call AutoFarm functions, remotes, or alter character physics.
-- UI and its own sampling connection are the only objects it creates.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Workspace=game:GetService("Workspace")
local me=Players.LocalPlayer
local parent=me:WaitForChild("PlayerGui")
local old=parent:FindFirstChild("FarmToggleObserverV2")
if old then old:Destroy() end -- only our previous diagnostic UI

local gui=Instance.new("ScreenGui")
gui.Name="FarmToggleObserverV2";gui.ResetOnSpawn=false;gui.Parent=parent
local frame=Instance.new("Frame")
frame.Size=UDim2.fromOffset(340,151)
frame.Position=UDim2.new(.5,-170,.14,0)
frame.BackgroundColor3=Color3.fromRGB(24,27,34)
frame.BorderSizePixel=0;frame.Parent=gui
Instance.new("UICorner",frame).CornerRadius=UDim.new(0,10)
local title=Instance.new("TextLabel")
title.Size=UDim2.new(1,-12,0,30);title.Position=UDim2.fromOffset(6,4)
title.BackgroundTransparency=1;title.Text="AutoFarm Toggle Observer V2"
title.TextColor3=Color3.new(1,1,1);title.Font=Enum.Font.GothamBold
title.TextSize=14;title.Parent=frame
local status=Instance.new("TextLabel")
status.Size=UDim2.new(1,-14,0,36);status.Position=UDim2.fromOffset(7,36)
status.BackgroundTransparency=1;status.Text="Idle | Start, then switch toggles"
status.TextWrapped=true;status.TextColor3=Color3.fromRGB(210,215,230)
status.TextSize=12;status.Font=Enum.Font.Code;status.Parent=frame

local buttons={}
for i,name in ipairs({"Start","Copy","Clear"}) do
 local b=Instance.new("TextButton")
 b.Size=UDim2.fromOffset(100,37);b.Position=UDim2.fromOffset(10+(i-1)*110,83)
 b.BackgroundColor3=Color3.fromRGB(54,76,108);b.TextColor3=Color3.new(1,1,1)
 b.Text=name;b.Font=Enum.Font.GothamBold;b.TextSize=14;b.Parent=frame
 Instance.new("UICorner",b).CornerRadius=UDim.new(0,7)
 buttons[name]=b
end
local foot=Instance.new("TextLabel")
foot.Size=UDim2.new(1,-12,0,19);foot.Position=UDim2.fromOffset(6,126)
foot.BackgroundTransparency=1;foot.Text="Character observation only; no farm calls"
foot.TextSize=11;foot.TextColor3=Color3.fromRGB(160,172,190)
foot.Font=Enum.Font.Code;foot.Parent=frame

local recording=false
local started=0
local lastTick=0
local previous=nil
local lines={}
local conn=nil
local function write(msg)
 local line=string.format("[TOGGLE][%.2fs] %s",os.clock()-started,msg)
 lines[#lines+1]=line
 if #lines>1400 then table.remove(lines,1) end
 print(line)
 status.Text=string.format("Recording: %s | Lines: %d",tostring(recording),#lines)
end
local function capture()
 local char=me.Character
 local root=char and char:FindFirstChild("HumanoidRootPart")
 local hum=char and char:FindFirstChildOfClass("Humanoid")
 if not (char and root and hum) then return nil end
 local parts,colliding=0,0
 local movers={}
 for _,obj in ipairs(char:GetDescendants()) do
  if obj:IsA("BasePart") then
   parts+=1
   if obj.CanCollide then colliding+=1 end
  elseif obj:IsA("AlignPosition") or obj:IsA("AlignOrientation")
      or obj:IsA("BodyPosition") or obj:IsA("BodyVelocity")
      or obj:IsA("LinearVelocity") or obj:IsA("VectorForce")
      or obj:IsA("BodyGyro") then
   local enabled="?"
   pcall(function() enabled=tostring(obj.Enabled) end)
   movers[#movers+1]=obj.Name..":"..obj.ClassName..":"..enabled
  end
 end
 table.sort(movers)
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances={char}
 local floor=Workspace:Raycast(root.Position,Vector3.new(0,-120,0),params)
 local dist=floor and (root.Position.Y-floor.Position.Y) or nil
 local v=root.AssemblyLinearVelocity
 local snap={
  t=os.clock()-started,
  y=root.Position.Y,x=root.Position.X,z=root.Position.Z,
  vy=v.Y,hs=Vector3.new(v.X,0,v.Z).Magnitude,
  size=root.Size.Y,rootColl=root.CanCollide,coll=colliding,parts=parts,
  state=hum:GetState().Name,ground=dist,
  movers=table.concat(movers,","),
  anchored=root.Anchored,
  floorName=floor and floor.Instance.Name or "NONE"
 }
 return snap
end
local function desc(s)
 return string.format("Y=%.2f VY=%.2f HSpeed=%.1f State=%s HRP_Y=%.1f HRPColl=%s PartsColl=%d/%d Floor=%s%s Anchored=%s Movers=[%s]",
 s.y,s.vy,s.hs,s.state,s.size,tostring(s.rootColl),s.coll,s.parts,
 s.ground and string.format("%.2f",s.ground) or "NONE<120",
 s.ground and ("/"..s.floorName) or "",
 tostring(s.anchored),s.movers=="" and "NONE" or s.movers)
end
local function inspect(s)
 if not previous then write("INITIAL | "..desc(s));previous=s;return end
 local p=previous
 local changes={}
 local function changed(name,a,b)
  if a~=b then changes[#changes+1]=name..":"..tostring(a).."->"..tostring(b) end
 end
 changed("HRPSizeY",p.size,s.size)
 changed("HRPCollide",p.rootColl,s.rootColl)
 changed("PartsColliding",p.coll,s.coll)
 changed("Movers",p.movers,s.movers)
 changed("HumanoidState",p.state,s.state)
 changed("Anchored",p.anchored,s.anchored)
 changed("FloorDetected",p.ground~=nil,s.ground~=nil)
 local displacement=math.sqrt((s.x-p.x)^2+(s.y-p.y)^2+(s.z-p.z)^2)
 if #changes>0 then
  write("CHANGE "..table.concat(changes," | ").." | "..desc(s))
 end
 if displacement>35 then
  write(string.format("POSITION JUMP %.1f studs | Y %.2f->%.2f | %s",displacement,p.y,s.y,desc(s)))
 end
 if s.vy < -25 and p.vy>=-25 then write("FALL START | "..desc(s)) end
 -- Regular samples retain timing even when settings are unchanged.
 write("SAMPLE | "..desc(s))
 previous=s
end
buttons.Start.MouseButton1Click:Connect(function()
 recording=true;started=os.clock();lastTick=0;previous=nil;lines={}
 write("START | Observe main AutoFarm ON/OFF, then Underground ON/OFF; no script calls")
 if conn then conn:Disconnect() end
 conn=RunService.Heartbeat:Connect(function()
  if not recording or os.clock()-lastTick<.2 then return end
  lastTick=os.clock()
  local ok,s=pcall(capture)
  if not ok then write("READ ERROR "..tostring(s))
  elseif s then inspect(s)
  elseif previous then write("CHARACTER MISSING");previous=nil end
 end)
end)
buttons.Copy.MouseButton1Click:Connect(function()
 local data=table.concat(lines,"\n")
 local fn=type(setclipboard)=="function" and setclipboard or
          (type(toclipboard)=="function" and toclipboard or nil)
 if fn then
  local ok=pcall(fn,data)
  status.Text=ok and ("Copied "..#lines.." lines") or "Clipboard failed"
 else status.Text="Clipboard not supported" end
end)
buttons.Clear.MouseButton1Click:Connect(function()
 lines={};previous=nil
 status.Text=recording and "Cleared | Recording continues" or "Cleared | Idle"
end)
