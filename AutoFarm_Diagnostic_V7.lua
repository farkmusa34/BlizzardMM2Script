-- MM2 AutoFarm Diagnostic V7 | READ-ONLY comparative capture
-- Run alongside AutoFarm V13.11. Captures clean AND delayed coin approaches.
-- No character movement, remotes, collision changes, or farming changes.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local LP=Players.LocalPlayer
local old=LP.PlayerGui:FindFirstChild("AutoFarmDiagnosticV7")
if old then old:Destroy() end
local gui=Instance.new("ScreenGui")
gui.Name="AutoFarmDiagnosticV7"; gui.ResetOnSpawn=false
gui.Parent=LP:WaitForChild("PlayerGui")
local panel=Instance.new("Frame")
panel.Size=UDim2.fromOffset(355,176)
panel.Position=UDim2.new(0.5,-177,0.10,0)
panel.BackgroundColor3=Color3.fromRGB(24,28,36); panel.Parent=gui
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,9)
local function label(y,h,txt)
 local x=Instance.new("TextLabel"); x.Position=UDim2.fromOffset(9,y)
 x.Size=UDim2.new(1,-18,0,h); x.BackgroundTransparency=1
 x.TextColor3=Color3.fromRGB(235,240,248); x.Font=Enum.Font.Code
 x.TextSize=12; x.TextWrapped=true; x.Text=txt; x.Parent=panel
 return x
end
local title=label(5,24,"AutoFarm Diagnostic V7 | READ ONLY")
title.Font=Enum.Font.GothamBold; title.TextSize=14
local status=label(31,44,"Press Start. Records clean and delayed coin approaches.")
local footer=label(146,22,"Only observations; no game state changes.")
local buttons={}
for i,name in ipairs({"Start","Copy","Clear"}) do
 local b=Instance.new("TextButton")
 b.Size=UDim2.fromOffset(106,36)
 b.Position=UDim2.fromOffset(9+(i-1)*115,99)
 b.BackgroundColor3=Color3.fromRGB(52,70,95)
 b.TextColor3=Color3.new(1,1,1); b.Font=Enum.Font.GothamBold
 b.TextSize=13; b.Text=name; b.Parent=panel
 Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
 buttons[name]=b
end
local running=false
local lines={}
local maxLines=4500
local active=nil
local lastScan=0
local clean,delayed,unresolved=0,0,0
local nextId=0
local startTime=0
local function log(s)
 local line=string.format("[V7 %.2f] %s",os.clock()-startTime,s)
 lines[#lines+1]=line
 if #lines>maxLines then table.remove(lines,1) end
 print(line)
end
local function touch(coin)
 if not coin or not coin.Parent then return nil end
 local d=coin:FindFirstChild("TouchInterest")
 if d then return d end
 for _,x in ipairs(coin:GetDescendants()) do
  if x.Name=="TouchInterest" or x:IsA("TouchTransmitter") then return x end
 end
 return nil
end
local function pos(coin)
 if not coin or not coin.Parent then return nil end
 if coin:IsA("BasePart") then return coin.Position end
 if coin:IsA("Model") then
  local ok,p=pcall(function() return coin:GetPivot().Position end)
  if ok then return p end
 end
 return nil
end
local function nearest(hrp)
 local best,bestDist=nil,math.huge
 for _,obj in ipairs(workspace:GetDescendants()) do
  if obj.Name=="Coin_Server" and (obj:IsA("BasePart") or obj:IsA("Model")) and touch(obj) then
   local cp=pos(obj)
   if cp then
    local d=(hrp.Position-cp).Magnitude
    if d<bestDist then best,bestDist=obj,d end
   end
  end
 end
 return best,bestDist
end
local function vec(v)
 return v and string.format("(%.2f,%.2f,%.2f)",v.X,v.Y,v.Z) or "nil"
end
local function finish(outcome)
 if not active then return end
 local a=active
 local duration=os.clock()-a.started
 local category=(outcome=="TOUCH_GONE" and duration<0.85) and "CLEAN" or "DELAYED"
 if outcome~="TOUCH_GONE" then category="UNRESOLVED" end
 if category=="CLEAN" then clean+=1 elseif category=="DELAYED" then delayed+=1 else unresolved+=1 end
 log(string.format("END #%d %s outcome=%s duration=%.2fs samples=%d horizontalRange=%.2f verticalRange=%.2f reversalsXZ=%d reversalsY=%d touchGone=%s NOTE=TouchInterest disappearance is NOT server-award proof",
  a.id,category,outcome,duration,#a.samples,a.maxH-a.minH,a.maxY-a.minY,a.revH,a.revY,tostring(outcome=="TOUCH_GONE")))
 -- Keep compact sample timeline for clean and delayed cases, including target and velocity.
 for _,s in ipairs(a.samples) do log("  "..s) end
 active=nil
end
local function begin(coin,cp,hrp,align)
 nextId+=1
 local p=hrp.Position
 active={id=nextId,coin=coin,started=os.clock(),samples={},
  minY=p.Y,maxY=p.Y,minH=0,maxH=0,revH=0,revY=0,lastHX=nil,lastVY=nil,
  base=p,lastSample=0,initialTouch=touch(coin),everNear=true}
 log(string.format("BEGIN #%d coin=%s coinPos=%s hrp=%s target=%s",
  nextId,coin:GetFullName(),vec(cp),vec(p),vec(align and align.Position)))
end
local function update()
 local ch=LP.Character
 local hrp=ch and ch:FindFirstChild("HumanoidRootPart")
 if not hrp then return end
 local align=hrp:FindFirstChild("FarmAlign")
 local now=os.clock()
 if not active then
  if now-lastScan<0.15 then return end
  lastScan=now
  if not align then return end
  local coin,d=nearest(hrp)
  if coin and d<=8 then begin(coin,pos(coin),hrp,align) end
  return
 end
 local a=active
 local cp=pos(a.coin)
 local stillTouch=touch(a.coin)
 if not cp or not stillTouch then finish("TOUCH_GONE"); return end
 if not align then finish("FARM_ALIGN_MISSING"); return end
 local p=hrp.Position
 local dx,dz=p.X-cp.X,p.Z-cp.Z
 local horizontal=math.sqrt(dx*dx+dz*dz)
 a.minH=math.min(a.minH,horizontal); a.maxH=math.max(a.maxH,horizontal)
 a.minY=math.min(a.minY,p.Y); a.maxY=math.max(a.maxY,p.Y)
 local v=hrp.AssemblyLinearVelocity
 local hdot=(v.X*dx+v.Z*dz)/(horizontal>0.1 and horizontal or 1)
 local hs=(hdot>2 and 1) or (hdot< -2 and -1) or 0
 local vs=(v.Y>2 and 1) or (v.Y< -2 and -1) or 0
 if hs~=0 and a.lastHX and hs~=a.lastHX then a.revH+=1 end
 if vs~=0 and a.lastVY and vs~=a.lastVY then a.revY+=1 end
 if hs~=0 then a.lastHX=hs end
 if vs~=0 then a.lastVY=vs end
 if now-a.lastSample>=0.12 then
  a.lastSample=now
  local s=string.format("t=%.2f hrp=%s target=%s coin=%s horiz=%.2f below=%.2f vel=%s targetError=%.2f touch=1",
   now-a.started,vec(p),vec(align.Position),vec(cp),horizontal,cp.Y-p.Y,vec(v),
   (p-align.Position).Magnitude)
  if #a.samples<65 then a.samples[#a.samples+1]=s end
 end
 if now-a.started>6 then finish("TIMEOUT_6S"); return end
 if horizontal>13 and now-a.started>0.5 then finish("MOVED_AWAY"); return end
end
local conn
buttons.Start.MouseButton1Click:Connect(function()
 if running then
  running=false; buttons.Start.Text="Start"
  if conn then conn:Disconnect(); conn=nil end
  if active then finish("STOPPED") end
  status.Text=string.format("Stopped | clean=%d delayed=%d unresolved=%d",clean,delayed,unresolved)
  return
 end
 running=true; buttons.Start.Text="Stop"
 startTime=os.clock(); lastScan=0; active=nil
 log("START V7: clean<0.85s, delayed>=0.85s; read-only; nearest coin proxy (not internal target)")
 conn=RunService.Heartbeat:Connect(function()
  local ok,err=pcall(update)
  if not ok then log("ERROR "..tostring(err)) end
 end)
 status.Text="Recording | Farm coins normally; copy logs after several examples."
end)
buttons.Copy.MouseButton1Click:Connect(function()
 local report=string.format("AutoFarm V7 | clean=%d delayed=%d unresolved=%d\n",clean,delayed,unresolved)..table.concat(lines,"\n")
 if setclipboard then
  setclipboard(report); status.Text="Logs copied to clipboard."
 else
  status.Text="setclipboard unavailable; inspect console logs."
 end
end)
buttons.Clear.MouseButton1Click:Connect(function()
 table.clear(lines); clean=0; delayed=0; unresolved=0; nextId=0
 status.Text="Logs cleared."
end)
