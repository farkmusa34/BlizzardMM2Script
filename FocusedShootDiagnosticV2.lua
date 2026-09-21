-- BLIZZARD MM2 - FOCUSED SHOOT DIAGNOSTIC V2
-- Load AFTER Combat.lua. Production shot logic is NOT changed.

local Players=game:GetService('Players')
local RunService=game:GetService('RunService')
local UIS=game:GetService('UserInputService')
local LP=Players.LocalPlayer
local PG=LP:WaitForChild('PlayerGui')
local ENV=getgenv and getgenv() or _G
local MM2=ENV.MM2_V85_SPLIT or _G.MM2_V85_SPLIT
assert(MM2 and MM2.Functions and type(MM2.Functions.ShootMurdererLegit)=='function','Load Shared/UI/Combat first')

-- unwrap older diagnostics when possible
local original=MM2.Functions._FocusedShootDiagV2Original or MM2.Functions._ShootDiagOriginal or MM2.Functions._ExactShootDiagOriginal or MM2.Functions.ShootMurdererLegit
MM2.Functions.ShootMurdererLegit=original
MM2.Functions._FocusedShootDiagV2Original=original
MM2.Functions._ShootDiagOriginal=original

local old=PG:FindFirstChild('FocusedShootDiagnosticV2'); if old then old:Destroy() end
if ENV.__FSDV2History then pcall(function() ENV.__FSDV2History:Disconnect() end) end
if ENV.__FSDV2Removing then pcall(function() ENV.__FSDV2Removing:Disconnect() end) end

local logs,shotNo={},0
local history={}
local KEEP=.45
local function log(s) s=tostring(s); logs[#logs+1]=s; print(s) end
local function fmt(n,d) return string.format('%.'..(d or 2)..'f',n or 0) end
local function vec(v) return string.format('(%.2f, %.2f, %.2f)',v.X,v.Y,v.Z) end
local function xz(v) return Vector3.new(v.X,0,v.Z) end
local function speed(v) return xz(v).Magnitude end
local function angle(a,b)
 local aa,bb=xz(a),xz(b); if aa.Magnitude<.35 or bb.Magnitude<.35 then return 0 end
 return math.deg(math.acos(math.clamp(aa.Unit:Dot(bb.Unit),-1,1)))
end
local function partOf(c) return c and (c:FindFirstChild('UpperTorso') or c:FindFirstChild('Torso') or c:FindFirstChild('HumanoidRootPart')) end
local function live(p)
 if not p or p==LP or not p.Character then return false end
 local h=p.Character:FindFirstChildOfClass('Humanoid'); return h and h.Health>0 and partOf(p.Character)~=nil
end
local function role(p)
 if type(MM2.GetPlayerRole)=='function' then local ok,r=pcall(MM2.GetPlayerRole,p); if ok and r then return tostring(r) end end
 if MM2.RoleCache then local r=MM2.RoleCache[p] or MM2.RoleCache[p.Name] or MM2.RoleCache[p.UserId]; if r then return tostring(r) end end
end
local function murderer()
 for _,p in ipairs(Players:GetPlayers()) do if live(p) and string.lower(role(p) or '')=='murderer' then return p end end
end

ENV.__FSDV2History=RunService.Heartbeat:Connect(function()
 local now=os.clock()
 for _,p in ipairs(Players:GetPlayers()) do
  if live(p) then
   local pt=partOf(p.Character); local hum=p.Character:FindFirstChildOfClass('Humanoid')
   local h=history[p] or {}; history[p]=h
   h[#h+1]={t=now,p=pt.Position,v=pt.AssemblyLinearVelocity,floor=hum and hum.FloorMaterial,state=hum and hum:GetState()}
   while #h>1 and (now-h[1].t>KEEP or #h>100) do table.remove(h,1) end
  else history[p]=nil end
 end
end)
ENV.__FSDV2Removing=Players.PlayerRemoving:Connect(function(p) history[p]=nil end)

local function observed(p,window)
 local h=history[p]; if not h or #h<2 then return Vector3.zero,0 end
 local newest=h[#h]; local oldest=h[1]; local target=newest.t-window
 for i=#h-1,1,-1 do if h[i].t<=target then oldest=h[i]; break end end
 local dt=newest.t-oldest.t; if dt<=.001 then return Vector3.zero,dt end
 return (newest.p-oldest.p)/dt,dt
end
local function verticalRange(p,window)
 local h=history[p]; if not h or #h==0 then return 0 end
 local newest=h[#h]; local lo,hi=newest.p.Y,newest.p.Y
 for i=#h,1,-1 do local s=h[i]; if newest.t-s.t>window then break end; lo=math.min(lo,s.p.Y); hi=math.max(hi,s.p.Y) end
 return hi-lo
end
local function classify(p,pt)
 local v=pt.AssemblyLinearVelocity; local sv,sdt=observed(p,.055); local mv,mdt=observed(p,.14)
 local ns,ss,ms=speed(v),speed(sv),speed(mv); local ts,tm=angle(sv,v),angle(mv,v)
 local ds,dm=ns-ss,ns-ms; local hum=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
 local air=false; local hs='Unknown'
 if hum then hs=tostring(hum:GetState()); air=hum.FloorMaterial==Enum.Material.Air or hum:GetState()==Enum.HumanoidStateType.Jumping or hum:GetState()==Enum.HumanoidStateType.Freefall else air=math.abs(v.Y)>2 end
 local tags={}
 if air then tags[#tags+1]='AIRBORNE'; tags[#tags+1]=(v.Y>2 and 'RISING' or v.Y<-2 and 'FALLING' or 'APEX') else tags[#tags+1]='GROUND' end
 if ns<.75 then tags[#tags+1]='XZ-STATIONARY' elseif ns<3 then tags[#tags+1]='XZ-SLOW' end
 if ts>=18 or tm>=25 then tags[#tags+1]='TURNING' end
 if ds<=-3.5 or dm<=-5 then tags[#tags+1]='DECELERATING' elseif ds>=3.5 or dm>=5 then tags[#tags+1]='ACCELERATING' end
 if ms>=5 and ns<=2 then tags[#tags+1]='STOPPING' elseif ms<=2 and ns>=5 then tags[#tags+1]='STARTING' end
 if #tags==1 and not air and ns>=3 then tags[#tags+1]='STABLE' end
 return table.concat(tags,'+'),{v=v,sv=sv,mv=mv,sdt=sdt,mdt=mdt,ns=ns,ss=ss,ms=ms,ts=ts,tm=tm,ds=ds,dm=dm,hs=hs,vr=verticalRange(p,.14)}
end

local leads={0,.03,.06,.09}; local names={'0','30','60','90'}
local function predicted(pos,v,t,useY) return pos+(useY and v or xz(v))*t end
local function errors(pos,v,actual,useY)
 local best,bestE,vals
 vals={}
 for i,t in ipairs(leads) do local d=actual-predicted(pos,v,t,useY); local e=useY and d.Magnitude or xz(d).Magnitude; vals[#vals+1]=names[i]..'='..fmt(e); if not bestE or e<bestE then best,bestE=names[i],e end end
 return best,bestE,table.concat(vals,' ')
end
local function candidates(label,pos,v,useY)
 local a={label..':' }; for i,t in ipairs(leads) do a[#a+1]=names[i]..'='..vec(predicted(pos,v,t,useY)) end; return table.concat(a,' ')
end
local function bucket(ms) if ms<4 then return 'IMMEDIATE' elseif ms<25 then return 'PARTIAL-FRAME' elseif ms<42 then return '~2-FRAME' else return 'LONG-DELAY' end end

local function monitor(p,char,pname,pressPos,pressV,shortV,mediumV)
 task.spawn(function()
  local cps={.016,.033,.050,.066,.100,.150,.200}; local elapsed=0
  for _,cp in ipairs(cps) do task.wait(math.max(0,cp-elapsed)); elapsed=cp
   if not p.Parent or p.Character~=char then log('+'..math.floor(cp*1000+.5)..'ms target changed/missing'); return end
   local pt=char:FindFirstChild(pname) or partOf(char); local hum=char:FindFirstChildOfClass('Humanoid'); if not pt or not hum then log('+'..math.floor(cp*1000+.5)..'ms target changed/missing'); return end
   local actual=pt.Position; local cv=pt.AssemblyLinearVelocity; local bx,ex=errors(pressPos,pressV,actual,false); local b3,e3,v3=errors(pressPos,pressV,actual,true)
   log(string.format('+%dms H=%s XZ=%.1f Y=%.1f dY=%+.2f BestXZ=%sms/%.2f Best3D=%sms/%.2f',math.floor(cp*1000+.5),fmt(hum.Health,0),speed(cv),cv.Y,actual.Y-pressPos.Y,bx,ex,b3,e3))
   if cp==.066 or cp==.100 then local bs,es=errors(pressPos,shortV,actual,true); local bm,em=errors(pressPos,mediumV,actual,true); log(string.format('  History3D Short=%sms/%.2f Medium=%sms/%.2f | Current3D %s',bs,es,bm,em,v3)) end
  end
 end)
end

MM2.Functions.ShootMurdererLegit=function(...)
 shotNo+=1; log(string.rep('=',60)); log('SHOT #'..shotNo)
 local p=murderer()
 if not p then local t=os.clock(); log('No live Murderer at press.'); local ok,msg=original(...); local ms=(os.clock()-t)*1000; log(string.format('Call=%.2fms [%s] Result=%s / %s',ms,bucket(ms),tostring(ok),tostring(msg))); return ok,msg end
 local char=p.Character; local pt=partOf(char); if not pt then return original(...) end
 local pname=pt.Name; local pos=pt.Position; local pv=pt.AssemblyLinearVelocity; local state,d=classify(p,pt)
 log('Target='..p.Name); log('State='..state..' HumanoidState='..d.hs); log('Press Pos='..vec(pos)); log(string.format('Press Vel=%s XZ=%.2f Y=%.2f',vec(pv),d.ns,pv.Y))
 log(string.format('Short[%dms] Vel=%s XZ=%.2f Turn=%.1f dSpeed=%+.2f',math.floor(d.sdt*1000+.5),vec(d.sv),d.ss,d.ts,d.ds))
 log(string.format('Medium[%dms] Vel=%s XZ=%.2f Turn=%.1f dSpeed=%+.2f VerticalRange=%.2f',math.floor(d.mdt*1000+.5),vec(d.mv),d.ms,d.tm,d.dm,d.vr))
 log(candidates('Current XZ',pos,pv,false)); log(candidates('Current 3D',pos,pv,true))
 local t=os.clock(); local ok,msg=original(...); local ms=(os.clock()-t)*1000
 log(string.format('Call=%.2fms [%s] Result=%s / %s',ms,bucket(ms),tostring(ok),tostring(msg)))
 local rp=p.Character==char and (char:FindFirstChild(pname) or partOf(char)) or nil
 if rp then local rv=rp.AssemblyLinearVelocity; local move=rp.Position-pos; log('Return Pos='..vec(rp.Position)); log(string.format('Return Vel=%s XZ=%.2f Y=%.2f Move=%s Dist=%.2f',vec(rv),speed(rv),rv.Y,vec(move),move.Magnitude)); log(string.format('Press->Return Turn=%.1fdeg XZSpeedDelta=%+.2f YDelta=%+.2f',angle(pv,rv),speed(rv)-speed(pv),rv.Y-pv.Y)) end
 if ok and msg=='Shot Fired' and p.Character==char then log('POST-SHOT: 16/33/50/66/100/150/200ms'); monitor(p,char,pname,pos,pv,d.sv,d.mv) else log('No post-shot monitor.') end
 log(string.rep('-',60)); return ok,msg
end

-- compact draggable log controls
local gui=Instance.new('ScreenGui'); gui.Name='FocusedShootDiagnosticV2'; gui.ResetOnSpawn=false; gui.DisplayOrder=999999; gui.Parent=PG
local main=Instance.new('Frame'); main.Size=UDim2.fromOffset(390,310); main.Position=UDim2.new(.5,-195,.5,-155); main.BackgroundColor3=Color3.fromRGB(20,20,24); main.BackgroundTransparency=.08; main.BorderSizePixel=0; main.Active=true; main.Parent=gui; Instance.new('UICorner',main).CornerRadius=UDim.new(0,12)
local stroke=Instance.new('UIStroke'); stroke.Thickness=1; stroke.Transparency=.35; stroke.Color=Color3.fromRGB(160,190,255); stroke.Parent=main
local title=Instance.new('TextLabel'); title.Size=UDim2.new(1,-20,0,34); title.Position=UDim2.fromOffset(10,4); title.BackgroundTransparency=1; title.Text='FOCUSED SHOOT DIAGNOSTIC V2'; title.TextColor3=Color3.new(1,1,1); title.TextSize=15; title.Font=Enum.Font.GothamBold; title.TextXAlignment=Enum.TextXAlignment.Left; title.Parent=main
local info=Instance.new('TextLabel'); info.Size=UDim2.new(1,-20,1,-92); info.Position=UDim2.fromOffset(10,42); info.BackgroundColor3=Color3.fromRGB(14,14,18); info.BackgroundTransparency=.15; info.TextColor3=Color3.fromRGB(220,220,230); info.TextSize=12; info.Font=Enum.Font.Code; info.TextWrapped=true; info.TextXAlignment=Enum.TextXAlignment.Left; info.TextYAlignment=Enum.TextYAlignment.Top; info.Text='Production shot unchanged.\n\nV2 records ground/airborne, rising/falling, turning, acceleration/deceleration, start/stop, short/medium history, XZ + 3D error, and call-delay bucket.\n\nGet ~8-10 FIRED shots with mixed movement.'; info.Parent=main; Instance.new('UICorner',info).CornerRadius=UDim.new(0,8)
local copy=Instance.new('TextButton'); copy.Size=UDim2.new(.5,-15,0,36); copy.Position=UDim2.new(0,10,1,-46); copy.BackgroundColor3=Color3.fromRGB(40,44,54); copy.Text='COPY LOGS'; copy.TextColor3=Color3.new(1,1,1); copy.Font=Enum.Font.GothamBold; copy.Parent=main; Instance.new('UICorner',copy).CornerRadius=UDim.new(0,8)
local clear=Instance.new('TextButton'); clear.Size=UDim2.new(.5,-15,0,36); clear.Position=UDim2.new(.5,5,1,-46); clear.BackgroundColor3=Color3.fromRGB(40,44,54); clear.Text='CLEAR'; clear.TextColor3=Color3.new(1,1,1); clear.Font=Enum.Font.GothamBold; clear.Parent=main; Instance.new('UICorner',clear).CornerRadius=UDim.new(0,8)
local dragging,dragStart,startPos,dragInput=false
local function beginDrag(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=true; dragStart=input.Position; startPos=main.Position; dragInput=input end end
title.InputBegan:Connect(beginDrag)
UIS.InputChanged:Connect(function(input) if dragging and (input==dragInput or input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then local d=input.Position-dragStart; main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y) end end)
UIS.InputEnded:Connect(function(input) if input==dragInput then dragging=false; dragInput=nil end end)
copy.MouseButton1Click:Connect(function() local s=table.concat(logs,'\n'); if setclipboard then setclipboard(s); copy.Text='COPIED' elseif toclipboard then toclipboard(s); copy.Text='COPIED' else copy.Text='NO CLIPBOARD API' end; task.delay(1.2,function() if copy.Parent then copy.Text='COPY LOGS' end end) end)
clear.MouseButton1Click:Connect(function() table.clear(logs); shotNo=0; clear.Text='CLEARED'; task.delay(1,function() if clear.Parent then clear.Text='CLEAR' end end) end)

log('FOCUSED SHOOT DIAGNOSTIC V2 LOADED')
log('Production Legit SHOOT logic is unchanged.')
log('Collect ~8-10 FIRED shots with mixed movement.')
log('Best tests: straight run, turn, stop/start, jump/fall.')
log('Keep automatic shooting and Aim Lock OFF.')
