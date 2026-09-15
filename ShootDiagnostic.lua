-- Blizzard MM2 - Floating SHOOT Diagnostic
-- Load AFTER Combat.lua. Keep TriggerBot and Aim Lock OFF.
local MM2=getgenv and getgenv().MM2_V85_SPLIT or _G.MM2_V85_SPLIT
assert(MM2 and MM2.Functions and MM2.Functions.ShootMurdererLegit,"Load Combat.lua first")
local Players,LP=MM2.Services.Players,MM2.LocalPlayer
local PG=LP:WaitForChild("PlayerGui")
local old=PG:FindFirstChild("BlizzardShootDiagnostic"); if old then old:Destroy() end
if MM2.Functions._ShootDiagOriginal then MM2.Functions.ShootMurdererLegit=MM2.Functions._ShootDiagOriginal end
local Original=MM2.Functions.ShootMurdererLegit
MM2.Functions._ShootDiagOriginal=Original
local logs,shotN={},0
local times={0,.03,.06,.09,.12}
local checks={.03,.05,.08,.10,.12,.15,.20,.30,.50,.80}
local function V(v) return typeof(v)=="Vector3" and string.format("(%.3f, %.3f, %.3f)",v.X,v.Y,v.Z) or "nil" end
local function torso(c) return c and (c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso") or c:FindFirstChild("HumanoidRootPart")) end
local function live(p) local c=p and p.Character; local h=c and c:FindFirstChildOfClass("Humanoid"); return p~=LP and h and h.Health>0 end
local function murderer()
 for _,p in ipairs(Players:GetPlayers()) do
  if live(p) then
   local ok,r=pcall(function() return MM2.GetPlayerRole(p) end)
   if (ok and r=="Murderer") or (MM2.State and MM2.State.ServerRolesCache and MM2.State.ServerRolesCache[p.Name]=="Murderer") then return p end
  end
 end
end
local function H(v) return Vector3.new(v.X,0,v.Z) end
local function pred(p,v,t) return p+H(v)*t end
local gui=Instance.new("ScreenGui"); gui.Name="BlizzardShootDiagnostic"; gui.ResetOnSpawn=false; gui.DisplayOrder=999999; gui.Parent=PG
local main=Instance.new("Frame"); main.Size=UDim2.fromOffset(360,285); main.Position=UDim2.new(0,16,.16,0); main.BackgroundColor3=Color3.fromRGB(18,18,22); main.BorderSizePixel=0; main.Active=true; main.Parent=gui
Instance.new("UICorner",main).CornerRadius=UDim.new(0,12)
local st=Instance.new("UIStroke"); st.Color=Color3.fromRGB(70,165,255); st.Transparency=.2; st.Parent=main
local title=Instance.new("TextLabel"); title.Size=UDim2.new(1,-16,0,30); title.Position=UDim2.fromOffset(8,4); title.BackgroundTransparency=1; title.Text="FLOATING SHOOT DIAGNOSTIC"; title.TextColor3=Color3.new(1,1,1); title.Font=Enum.Font.GothamBold; title.TextSize=14; title.TextXAlignment=Enum.TextXAlignment.Left; title.Parent=main
local status=Instance.new("TextLabel"); status.Size=UDim2.new(1,-16,0,28); status.Position=UDim2.fromOffset(8,34); status.BackgroundTransparency=1; status.Text="Waiting for SHOOT..."; status.TextColor3=Color3.fromRGB(210,210,220); status.TextSize=11; status.TextXAlignment=Enum.TextXAlignment.Left; status.Parent=main
local box=Instance.new("TextLabel"); box.Size=UDim2.new(1,-16,1,-106); box.Position=UDim2.fromOffset(8,64); box.BackgroundColor3=Color3.fromRGB(9,9,12); box.BorderSizePixel=0; box.TextColor3=Color3.fromRGB(225,225,230); box.Font=Enum.Font.Code; box.TextSize=9; box.TextXAlignment=Enum.TextXAlignment.Left; box.TextYAlignment=Enum.TextYAlignment.Top; box.Text="Loaded."; box.Parent=main
Instance.new("UICorner",box).CornerRadius=UDim.new(0,8)
local function mk(t,x) local b=Instance.new("TextButton"); b.Size=UDim2.fromOffset(164,28); b.Position=UDim2.new(0,x,1,-34); b.BackgroundColor3=Color3.fromRGB(35,35,43); b.BorderSizePixel=0; b.Text=t; b.TextColor3=Color3.new(1,1,1); b.Font=Enum.Font.GothamBold; b.TextSize=11; b.Parent=main; Instance.new("UICorner",b).CornerRadius=UDim.new(0,8); return b end
local copy,clear=mk("COPY LOGS",8),mk("CLEAR",188)
local function refresh() local a={}; for i=math.max(1,#logs-14),#logs do a[#a+1]=logs[i] end; box.Text=table.concat(a,"\n") end
local function log(s) logs[#logs+1]=tostring(s); print("[SHOOT DIAG] "..tostring(s)); refresh() end
copy.MouseButton1Click:Connect(function() if setclipboard then pcall(setclipboard,table.concat(logs,"\n")); status.Text="Copied." else status.Text="Clipboard unavailable." end end)
clear.MouseButton1Click:Connect(function() table.clear(logs); refresh(); status.Text="Cleared." end)
local drag,start,sp
main.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true; start=i.Position; sp=main.Position end end)
main.InputChanged:Connect(function(i) if drag and (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement) then local d=i.Position-start; main.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y) end end)
main.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
local function monitor(p,c0,p0,v0,t0)
 task.spawn(function()
  local candidates={}; for _,t in ipairs(times) do candidates[t]=pred(p0,v0,t) end
  for _,cp in ipairs(checks) do
   local rem=cp-(os.clock()-t0); if rem>0 then task.wait(rem) end
   local c=p.Character; local h=c and c:FindFirstChildOfClass("Humanoid"); local q=torso(c)
   if c~=c0 or not h or not q then log("+"..math.floor(cp*1000).."ms TARGET CHANGED/MISSING"); break end
   local best,bestE=0,math.huge; local es={}
   for _,t in ipairs(times) do local x=candidates[t]; local e=(Vector3.new(x.X,q.Position.Y,x.Z)-q.Position).Magnitude; es[#es+1]=string.format("%d=%.2f",t*1000,e); if e<bestE then best,bestE=t,e end end
   log(string.format("+%dms H=%.0f Pos=%s Best=%dms Err=%.2f | %s",cp*1000,h.Health,V(q.Position),best*1000,bestE,table.concat(es," ")))
  end
  log("============================================================")
 end)
end
MM2.Functions.ShootMurdererLegit=function(...)
 shotN+=1
 local p=murderer(); local q=p and torso(p.Character)
 log("============================================================"); log("FLOAT SHOOT #"..shotN)
 if q then
  local p0,v0=q.Position,q.AssemblyLinearVelocity
  log("Target="..p.Name.." Fresh="..V(p0).." Vel="..V(v0).." XZSpeed="..string.format("%.2f",H(v0).Magnitude))
  for _,t in ipairs(times) do log(string.format("Candidate %dms=%s",t*1000,V(pred(p0,v0,t)))) end
 end
 local a=os.clock(); local success,msg=Original(...); local b=os.clock()
 log(string.format("ProductionReturn=%.2fms Success=%s Message=%s",(b-a)*1000,tostring(success),tostring(msg)))
 status.Text=string.format("Shot #%d: %s / %s",shotN,tostring(success),tostring(msg))
 if success and p then
  local fresh=torso(p.Character)
  if fresh then
   local fp,fv=fresh.Position,fresh.AssemblyLinearVelocity
   log("AfterFire Fresh="..V(fp).." Vel="..V(fv))
   log("ProductionApprox60ms="..V(pred(fp,fv,.06)))
   monitor(p,p.Character,fp,fv,b)
  end
 else log("NO SHOT MONITOR") end
 return success,msg
end
log("FLOATING SHOOT DIAGNOSTIC LOADED")
log("Production SHOOT remains unchanged at 60ms X/Z prediction.")
log("Keep TriggerBot + Aim Lock OFF.")
