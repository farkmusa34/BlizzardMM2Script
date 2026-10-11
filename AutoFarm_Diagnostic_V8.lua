-- AutoFarm Diagnostic V8 | V13.11-specific observational tool
-- Read-only: never writes farm movement, target, collision, or coin state.
-- Drag the top bar to move the panel (mouse or touch).
local Players=game:GetService('Players')
local RunService=game:GetService('RunService')
local UIS=game:GetService('UserInputService')
local lp=Players.LocalPlayer
local pg=lp:WaitForChild('PlayerGui')
local previous=pg:FindFirstChild('AutoFarmDiagnosticV8')
if previous then previous:Destroy() end
local gui=Instance.new('ScreenGui'); gui.Name='AutoFarmDiagnosticV8'; gui.ResetOnSpawn=false; gui.Parent=pg
local panel=Instance.new('Frame'); panel.Size=UDim2.fromOffset(365,205); panel.Position=UDim2.new(.5,-182,.12,0); panel.BackgroundColor3=Color3.fromRGB(22,27,37); panel.Parent=gui
Instance.new('UICorner',panel).CornerRadius=UDim.new(0,9)
local function txt(parent,y,h,value,size)
 local x=Instance.new('TextLabel'); x.BackgroundTransparency=1; x.Position=UDim2.fromOffset(10,y); x.Size=UDim2.new(1,-20,0,h); x.Font=Enum.Font.Code; x.TextSize=size or 12; x.TextColor3=Color3.fromRGB(235,240,249); x.TextWrapped=true; x.Text=value; x.Parent=parent; return x
end
local bar=Instance.new('TextButton'); bar.Text='≡ AutoFarm Diagnostic V8 — DRAG HERE'; bar.TextSize=13; bar.Font=Enum.Font.GothamBold; bar.TextColor3=Color3.new(1,1,1); bar.BackgroundColor3=Color3.fromRGB(42,60,85); bar.Size=UDim2.new(1,0,0,35); bar.Parent=panel
Instance.new('UICorner',bar).CornerRadius=UDim.new(0,9)
local dragging=false; local dragStart, panelStart, dragInput
bar.InputBegan:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=true; dragStart=input.Position; panelStart=panel.Position; dragInput=input end
end)
bar.InputChanged:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then dragInput=input end end)
UIS.InputChanged:Connect(function(input)
 if dragging and input==dragInput then local d=input.Position-dragStart; panel.Position=UDim2.new(panelStart.X.Scale,panelStart.X.Offset+d.X,panelStart.Y.Scale,panelStart.Y.Offset+d.Y) end
end)
UIS.InputEnded:Connect(function(input) if input==dragInput or (input.UserInputType==Enum.UserInputType.MouseButton1 and dragging) then dragging=false end end)
local status=txt(panel,44,57,'Press Start. V8 compares smooth approaches and retries.',12)
local summary=txt(panel,104,27,'clean=0 delayed=0 unresolved=0',12)
local buttons={}
for i,name in ipairs({'Start','Copy','Clear'}) do
 local b=Instance.new('TextButton'); b.Size=UDim2.fromOffset(108,34); b.Position=UDim2.fromOffset(9+(i-1)*117,138); b.BackgroundColor3=Color3.fromRGB(53,75,103); b.TextColor3=Color3.new(1,1,1); b.Font=Enum.Font.GothamBold; b.TextSize=13; b.Text=name; b.Parent=panel; Instance.new('UICorner',b).CornerRadius=UDim.new(0,6); buttons[name]=b
end
txt(panel,177,22,'Read-only | V13.11 | drag title to move',11)
local lines, running, active, conn={},false,nil,nil
local clean,delayed,unresolved,id=0,0,0,0
local start=os.clock(); local lastScan=0
local function vec(v) return v and string.format('(%.2f,%.2f,%.2f)',v.X,v.Y,v.Z) or 'nil' end
local function log(s)
 local line=string.format('[V8 %.2f] %s',os.clock()-start,s); lines[#lines+1]=line
 if #lines>5500 then table.remove(lines,1) end
 print(line)
end
local function touch(c)
 if not c or not c.Parent then return nil end
 local direct=c:FindFirstChild('TouchInterest'); if direct then return direct end
 for _,d in ipairs(c:GetDescendants()) do if d.Name=='TouchInterest' or d:IsA('TouchTransmitter') then return d end end
end
local function coinPos(c)
 if not c or not c.Parent then return nil end
 if c:IsA('BasePart') then return c.Position end
 if c:IsA('Model') then local ok,p=pcall(function() return c:GetPivot().Position end); if ok then return p end end
end
local function coinsNear(hrp,align)
 local best,score=nil,math.huge
 -- AlignPosition Y follows coin Y -5.05 (underground) or +3.35 (aboveground).
 for _,c in ipairs(workspace:GetDescendants()) do
  if c.Name=='Coin_Server' and (c:IsA('BasePart') or c:IsA('Model')) and touch(c) then
   local p=coinPos(c)
   if p then
    local h=Vector2.new(p.X-hrp.Position.X,p.Z-hrp.Position.Z).Magnitude
    local target=align.Position
    local targetXZ=Vector2.new(target.X-p.X,target.Z-p.Z).Magnitude
    local underground=math.abs(target.Y-(p.Y-5.05))
    local above=math.abs(target.Y-(p.Y+3.35))
    local y=math.min(underground,above)
    -- The target may be offset horizontally during contact retry; allow up to 3 studs.
    if h<10 and y<1.5 and targetXZ<3.5 then
     local s=targetXZ*2+y*3+h*.08
     if s<score then best,score=c,s end
    end
   end
  end
 end
 return best
end
local function refresh() summary.Text=string.format('clean=%d delayed=%d unresolved=%d',clean,delayed,unresolved) end
local function finish(reason)
 if not active then return end
 local a=active; active=nil
 local duration=os.clock()-a.t
 local category=(reason=='TOUCH_GONE' and duration<.85 and a.retryChanges==0) and 'CLEAN' or ((reason=='TOUCH_GONE') and 'DELAYED' or 'UNRESOLVED')
 if category=='CLEAN' then clean+=1 elseif category=='DELAYED' then delayed+=1 else unresolved+=1 end
 log(string.format('END #%d %s reason=%s duration=%.2f targetChanges=%d retryChanges=%d horizontalReversals=%d verticalReversals=%d minHorizontal=%.2f maxYChange=%.2f NOTE=TouchInterest loss does not prove award',a.id,category,reason,duration,a.targetChanges,a.retryChanges,a.revH,a.revY,a.minH,a.maxY-a.minY))
 for _,s in ipairs(a.samples) do log('  '..s) end
 refresh()
end
local function begin(c,hrp,align)
 id+=1; local p=hrp.Position; local cp=coinPos(c)
 active={id=id,coin=c,t=os.clock(),samples={},lastSample=-1,minH=math.huge,minY=p.Y,maxY=p.Y,revH=0,revY=0,lastHS=nil,lastVS=nil,lastTarget=align.Position,targetChanges=0,retryChanges=0,awaySince=nil}
 log(string.format('BEGIN #%d coin=%s coinPos=%s hrp=%s align=%s mode=%s',id,c:GetFullName(),vec(cp),vec(p),vec(align.Position),math.abs(align.Position.Y-(cp.Y-5.05))<1.5 and 'UNDERGROUND' or 'ABOVE'))
end
local function update()
 local char=lp.Character; local hrp=char and char:FindFirstChild('HumanoidRootPart'); if not hrp then if active then finish('HRP_LOST') end; return end
 local align=hrp:FindFirstChild('FarmAlign'); if not align then if active then finish('ALIGN_LOST') end; return end
 local now=os.clock()
 if not active then
  if now-lastScan<.08 then return end; lastScan=now
  local c=coinsNear(hrp,align); if c then begin(c,hrp,align) end; return
 end
 local a=active; local cp=coinPos(a.coin)
 if not cp or not touch(a.coin) then finish('TOUCH_GONE'); return end
 local p=hrp.Position; local target=align.Position; local vel=hrp.AssemblyLinearVelocity
 local h=Vector2.new(p.X-cp.X,p.Z-cp.Z).Magnitude
 a.minH=math.min(a.minH,h); a.minY=math.min(a.minY,p.Y); a.maxY=math.max(a.maxY,p.Y)
 local dot=(vel.X*(p.X-cp.X)+vel.Z*(p.Z-cp.Z))/math.max(h,.1)
 local hs=dot>2 and 1 or dot< -2 and -1 or 0; local vs=vel.Y>2 and 1 or vel.Y< -2 and -1 or 0
 if hs~=0 then if a.lastHS and a.lastHS~=hs then a.revH+=1 end; a.lastHS=hs end
 if vs~=0 then if a.lastVS and a.lastVS~=vs then a.revY+=1 end; a.lastVS=vs end
 if (target-a.lastTarget).Magnitude>.25 then
  a.targetChanges+=1
  local offset=Vector2.new(target.X-cp.X,target.Z-cp.Z).Magnitude
  if offset>.6 then a.retryChanges+=1 end
  log(string.format('TARGET_CHANGE #%d t=%.2f from=%s to=%s horizontalOffset=%.2f (offset may be retry/stage/next coin)',a.id,now-a.t,vec(a.lastTarget),vec(target),offset))
  a.lastTarget=target
 end
 if now-a.lastSample>=.09 and #a.samples<100 then
  a.lastSample=now
  a.samples[#a.samples+1]=string.format('t=%.2f hrp=%s coin=%s target=%s horiz=%.2f below=%.2f vel=%s error=%.2f targetXZ=%.2f touch=1',now-a.t,vec(p),vec(cp),vec(target),h,cp.Y-p.Y,vec(vel),(p-target).Magnitude,Vector2.new(target.X-cp.X,target.Z-cp.Z).Magnitude)
 end
 if h>13 then a.awaySince=a.awaySince or now else a.awaySince=nil end
 if a.awaySince and now-a.awaySince>.25 then finish('MOVED_AWAY_TARGET_CHANGED_OR_SKIPPED'); return end
 if now-a.t>7 then finish('TIMEOUT_7S') end
end
buttons.Start.MouseButton1Click:Connect(function()
 if running then running=false; buttons.Start.Text='Start'; if conn then conn:Disconnect();conn=nil end; if active then finish('STOPPED') end; status.Text='Stopped. Copy logs to share.'; return end
 running=true; buttons.Start.Text='Stop'; start=os.clock();lastScan=0
 log('START V8 | read-only V13.11-specific FarmAlign target matching; nearest proxy replaced by target-aware matching')
 status.Text='Recording. Watch for a bouncing coin, then Copy.'
 conn=RunService.Heartbeat:Connect(function() local ok,err=pcall(update); if not ok then log('ERROR '..tostring(err)) end end)
end)
buttons.Copy.MouseButton1Click:Connect(function()
 local report=string.format('AutoFarm V8 | clean=%d delayed=%d unresolved=%d\n',clean,delayed,unresolved)..table.concat(lines,'\n')
 if type(setclipboard)=='function' then setclipboard(report);status.Text='Copied! Paste logs into chat.' else status.Text='Clipboard unavailable; logs printed to console.' end
end)
buttons.Clear.MouseButton1Click:Connect(function() table.clear(lines);clean=0;delayed=0;unresolved=0;id=0;refresh();status.Text='Cleared. Continue recording.' end)
