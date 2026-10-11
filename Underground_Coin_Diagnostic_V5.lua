-- MM2 Underground Coin Diagnostic V5 | observation only
-- Does not move the character or alter the farm.
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local UIS = game:GetService('UserInputService')
local player = Players.LocalPlayer
local LIMIT, OFFSET, MIN_BELOW = 15, -5.05, 2.5
local RANGE, LOST_RANGE, SAMPLE_RATE = 12, 18, .05
local old = (gethui and gethui() or game:GetService('CoreGui')):FindFirstChild('UndergroundCoinDiagnosticV5')
if old then old:Destroy() end
local gui = Instance.new('ScreenGui')
gui.Name = 'UndergroundCoinDiagnosticV5'; gui.ResetOnSpawn = false
local parent = (gethui and gethui()) or game:GetService('CoreGui')
local ok = pcall(function() gui.Parent = parent end)
if not ok then gui.Parent = player:WaitForChild('PlayerGui') end
local panel = Instance.new('Frame', gui)
panel.Size = UDim2.fromOffset(360, 322)
panel.Position = UDim2.new(.5,-180,.22,0)
panel.BackgroundColor3 = Color3.fromRGB(24,27,35)
panel.BorderSizePixel = 0; panel.Active = true
Instance.new('UICorner',panel).CornerRadius = UDim.new(0,10)
local function text(y,h,s,content)
 local t=Instance.new('TextLabel',panel); t.BackgroundTransparency=1
 t.Position=UDim2.fromOffset(10,y); t.Size=UDim2.new(1,-20,0,h)
 t.Font=Enum.Font.Gotham; t.TextSize=s; t.TextColor3=Color3.fromRGB(235,239,246)
 t.TextXAlignment=Enum.TextXAlignment.Left; t.TextWrapped=true; t.Text=content
 return t
end
local title=text(7,25,15,'UNDERGROUND COIN DIAGNOSTIC V5')
title.Font=Enum.Font.GothamBold
local status=text(35,23,13,'Stopped | Possible pickups: 0/15')
local info=text(59,38,12,'Coin tracking: idle')
local function btn(x,label,color)
 local b=Instance.new('TextButton',panel); b.Size=UDim2.fromOffset(108,34)
 b.Position=UDim2.fromOffset(x,105); b.Text=label; b.Font=Enum.Font.GothamBold
 b.TextSize=13; b.TextColor3=Color3.new(1,1,1); b.BackgroundColor3=color
 Instance.new('UICorner',b).CornerRadius=UDim.new(0,7)
 return b
end
local capture=btn(10,'Capture',Color3.fromRGB(36,142,91))
local clear=btn(126,'Clear',Color3.fromRGB(92,99,114))
local copy=btn(242,'Copy',Color3.fromRGB(52,102,186))
local log=Instance.new('TextBox',panel)
log.Position=UDim2.fromOffset(10,148); log.Size=UDim2.new(1,-20,0,164)
log.BackgroundColor3=Color3.fromRGB(15,17,23); log.TextColor3=Color3.fromRGB(221,230,238)
log.Font=Enum.Font.Code; log.TextSize=11; log.TextXAlignment=Enum.TextXAlignment.Left
log.TextYAlignment=Enum.TextYAlignment.Top; log.MultiLine=true; log.TextWrapped=true
log.ClearTextOnFocus=false; log.TextEditable=false; log.Text='No observations yet.'
Instance.new('UICorner',log).CornerRadius=UDim.new(0,6)
-- Drag by title only
local dragging,startInput,startPos,dragType
panel.InputBegan:Connect(function(input)
 if input.UserInputType~=Enum.UserInputType.Touch and input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
 if input.Position.Y-panel.AbsolutePosition.Y>32 then return end
 dragging=true; startInput=input.Position; startPos=panel.Position; dragType=input.UserInputType
end)
UIS.InputChanged:Connect(function(input)
 if not dragging then return end
 if input.UserInputType~=Enum.UserInputType.MouseMovement and input.UserInputType~=Enum.UserInputType.Touch then return end
 if dragType==Enum.UserInputType.Touch and input.UserInputType~=Enum.UserInputType.Touch then return end
 local d=input.Position-startInput
 panel.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
end)
UIS.InputEnded:Connect(function(input)
 if input.UserInputType==dragType then dragging=false end
end)
local active=false; local confirmed,uncertain=0,0
local records={}; local tracked=nil; local ignored={}; local lastScan=0; local lastTick=0
local function root()
 local c=player.Character
 return c and c:FindFirstChild('HumanoidRootPart')
end
local function pos(coin)
 if not coin or not coin.Parent then return nil end
 if coin:IsA('BasePart') then return coin.Position end
 if coin:IsA('Model') then local success,p=pcall(function() return coin:GetPivot().Position end); if success then return p end end
end
local function hasTouch(coin)
 if not coin or not coin.Parent then return false end
 if coin:IsA('TouchTransmitter') or coin.Name=='TouchInterest' then return true end
 for _,d in ipairs(coin:GetDescendants()) do
  if d.Name=='TouchInterest' or d:IsA('TouchTransmitter') then return true end
 end
 return false
end
local function fmt(x) return x==math.huge and 'N/A' or string.format('%.2f',x) end
local function report()
 local lines={'MM2 UNDERGROUND COIN DIAGNOSTIC V5',
 'Possible pickups: '..confirmed..'/'..LIMIT..' | Unconfirmed: '..uncertain,
 'Reference Y offset: '..OFFSET..' | Underground threshold: '..MIN_BELOW,
 'Touch/coin removal is a POSSIBLE pickup, not guaranteed collection.',
 'Observations are proximity-based and do not modify gameplay.',
 '----------------------------------------'}
 for _,v in ipairs(records) do lines[#lines+1]=v end
 return table.concat(lines,'\n')
end
local function refresh(note)
 status.Text=string.format('%s | Possible pickups: %d/%d | Other: %d',active and 'CAPTURING' or 'STOPPED',confirmed,LIMIT,uncertain)
 capture.Text=active and 'Stop' or 'Capture'
 capture.BackgroundColor3=active and Color3.fromRGB(184,62,62) or Color3.fromRGB(36,142,91)
 if note then info.Text=note end
 log.Text=#records>0 and table.concat(records,'\n\n') or 'No observations yet.'
end
local function finish(reason,possible)
 if not tracked then return end
 local a=tracked; tracked=nil
 if possible then confirmed=confirmed+1 else uncertain=uncertain+1 end
 local s=string.format('#%02d %s | t=%ss | map=%s | Hmin=%s | Ybest=%s | Yerror=%s | BoxMin=%s | Overlap=%d | HspeedMax=%s | VspeedMax=%s | Hturns=%d | Vreversals=%d | samples=%d',
  #records+1,reason,fmt(os.clock()-a.started),a.map,
  fmt(a.hmin),fmt(a.ybest),fmt(a.yerr),fmt(a.boxmin),a.overlap,
  fmt(a.hspeed),fmt(a.vspeed),a.hturns,a.vturns,a.samples)
 records[#records+1]=s
 ignored[a.coin]=os.clock()+2
 if confirmed>=LIMIT then active=false end
 refresh(reason..(confirmed>=LIMIT and ' | limit reached' or ''))
end
local function newTrack(coin,cp)
 local map=coin.Parent and coin.Parent.Parent and coin.Parent.Parent.Name or 'unknown'
 tracked={coin=coin,cp=cp,map=map,started=os.clock(),hadTouch=hasTouch(coin),
 hmin=math.huge,yerr=math.huge,ybest=math.huge,boxmin=math.huge,overlap=0,
 hspeed=0,vspeed=0,hturns=0,vturns=0,samples=0,lastHdir=nil,lastVsign=0,lastPosition=nil,lastTime=nil}
end
local function sample(a,r,cp,now)
 local rp=r.Position; local h=Vector2.new(rp.X-cp.X,rp.Z-cp.Z).Magnitude
 local y=rp.Y-cp.Y
 a.hmin=math.min(a.hmin,h)
 local e=math.abs(y-OFFSET)
 if e<a.yerr then a.yerr=e; a.ybest=y end
 local rel=r.CFrame:PointToObjectSpace(cp); local half=r.Size/2
 local dx=math.max(math.abs(rel.X)-half.X,0)
 local dy=math.max(math.abs(rel.Y)-half.Y,0)
 local dz=math.max(math.abs(rel.Z)-half.Z,0)
 local dist=math.sqrt(dx*dx+dy*dy+dz*dz)
 a.boxmin=math.min(a.boxmin,dist)
 if dist<.01 then a.overlap=a.overlap+1 end
 local vel=r.AssemblyLinearVelocity
 local hv=Vector2.new(vel.X,vel.Z)
 a.hspeed=math.max(a.hspeed,hv.Magnitude)
 a.vspeed=math.max(a.vspeed,math.abs(vel.Y))
 local vs=vel.Y>1 and 1 or vel.Y< -1 and -1 or 0
 if vs~=0 then if a.lastVsign~=0 and vs~=a.lastVsign then a.vturns=a.vturns+1 end; a.lastVsign=vs end
 if hv.Magnitude>2 then
  local hd=hv.Unit
  if a.lastHdir and hd:Dot(a.lastHdir)<-.3 then a.hturns=a.hturns+1 end
  a.lastHdir=hd
 end
 a.samples=a.samples+1
end
local function closestCoin(r)
 local best,bestPos,bestDist
 for _,coin in ipairs(workspace:GetDescendants()) do
  if coin.Name=='Coin_Server' and (coin:IsA('BasePart') or coin:IsA('Model')) and not ignored[coin] then
   local cp=pos(coin)
   if cp then
    local h=Vector2.new(r.Position.X-cp.X,r.Position.Z-cp.Z).Magnitude
    if h<RANGE and cp.Y-r.Position.Y>=MIN_BELOW and (not bestDist or h<bestDist) then
     best,bestPos,bestDist=coin,cp,h
    end
   end
  end
 end
 return best,bestPos
end
capture.MouseButton1Click:Connect(function()
 if active then active=false; refresh('Paused; existing logs retained.'); return end
 if confirmed>=LIMIT then refresh('Limit reached. Copy or Clear to start over.'); return end
 active=true; refresh('Recording underground coin observations...')
end)
clear.MouseButton1Click:Connect(function()
 active=false; tracked=nil; confirmed=0; uncertain=0; records={}; ignored={}
 refresh('Cleared. Ready to capture.')
end)
copy.MouseButton1Click:Connect(function()
 local content=report()
 local clipboard=setclipboard or toclipboard
 if type(clipboard)=='function' then
  local success=pcall(clipboard,content)
  info.Text=success and 'Report copied to clipboard.' or 'Clipboard failed; view logs below.'
 else
  log.TextEditable=true; log.Text=content
  info.Text='Clipboard unavailable. Select text from log box.'
 end
end)
RunService.Heartbeat:Connect(function()
 if not active then return end
 local now=os.clock()
 if now-lastTick<SAMPLE_RATE then return end
 lastTick=now
 local r=root(); if not r then return end
 if tracked then
  local a=tracked
  local cp=pos(a.coin)
  if not cp then finish('COIN_REMOVED_POSSIBLE_PICKUP',true); return end
  local touch=hasTouch(a.coin)
  if a.hadTouch and not touch then finish('TOUCH_REMOVED_POSSIBLE_PICKUP',true); return end
  local h=Vector2.new(r.Position.X-cp.X,r.Position.Z-cp.Z).Magnitude
  if h>LOST_RANGE or cp.Y-r.Position.Y<0 then
   finish('TARGET_LEFT_UNCONFIRMED',false); return
  end
  if now-a.started>6 then finish('TIMEOUT_UNCONFIRMED',false); return end
  sample(a,r,cp,now)
 else
  if now-lastScan<.20 then return end
  lastScan=now
  for coin,expiry in pairs(ignored) do if expiry<now then ignored[coin]=nil end end
  local coin,cp=closestCoin(r)
  if coin then newTrack(coin,cp); refresh('Tracking underground coin...') end
 end
end)
refresh('Ready. Press Capture.')
print('[Underground Coin Diagnostic V5] Ready.')
