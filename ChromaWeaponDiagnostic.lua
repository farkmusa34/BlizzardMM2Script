-- BLIZZARD MM2 - CHROMA WEAPON DIAGNOSTIC
-- Equip a real Chroma Gun or Knife, press START, and leave it equipped for 15 seconds.
-- Samples the same weapon at 0,1,2,3,5,7,10,12,15 seconds.

local Players=game:GetService("Players")
local P=Players.LocalPlayer
local PG=P:WaitForChild("PlayerGui")
local old=PG:FindFirstChild("BlizzardChromaDiagnostic")
if old then old:Destroy() end

local G=Instance.new("ScreenGui")
G.Name="BlizzardChromaDiagnostic"; G.ResetOnSpawn=false; G.DisplayOrder=999999; G.Parent=PG
local F=Instance.new("Frame")
F.Size=UDim2.fromOffset(390,240); F.Position=UDim2.new(.5,-195,.5,-120)
F.BackgroundColor3=Color3.fromRGB(24,24,28); F.BorderSizePixel=0; F.Active=true; F.Draggable=true; F.Parent=G
Instance.new("UICorner",F).CornerRadius=UDim.new(0,12)

local T=Instance.new("TextLabel")
T.Size=UDim2.new(1,-20,0,36); T.Position=UDim2.fromOffset(10,8); T.BackgroundTransparency=1
T.Text="Chroma Weapon Diagnostic"; T.TextColor3=Color3.new(1,1,1); T.TextSize=19; T.Font=Enum.Font.GothamBold; T.Parent=F
local S=Instance.new("TextLabel")
S.Size=UDim2.new(1,-24,0,55); S.Position=UDim2.fromOffset(12,45); S.BackgroundTransparency=1
S.TextWrapped=true; S.Text="Equip a Chroma Gun or Knife, then start."; S.TextColor3=Color3.fromRGB(210,210,215)
S.TextSize=14; S.Font=Enum.Font.Gotham; S.Parent=F

local function mk(txt,y)
 local b=Instance.new("TextButton"); b.Size=UDim2.new(1,-30,0,42); b.Position=UDim2.fromOffset(15,y)
 b.BackgroundColor3=Color3.fromRGB(45,45,53); b.BorderSizePixel=0; b.Text=txt; b.TextColor3=Color3.new(1,1,1)
 b.TextSize=15; b.Font=Enum.Font.GothamSemibold; b.Parent=F; Instance.new("UICorner",b).CornerRadius=UDim.new(0,9); return b
end
local Start=mk("START 15s CAPTURE",108)
local Copy=mk("COPY LOGS",160)
local X=Instance.new("TextButton"); X.Size=UDim2.fromOffset(30,30); X.Position=UDim2.new(1,-38,0,8)
X.BackgroundTransparency=1; X.Text="×"; X.TextColor3=Color3.new(1,1,1); X.TextSize=24; X.Parent=F
X.MouseButton1Click:Connect(function() G:Destroy() end)

local logs,running={},false
local times={0,1,2,3,5,7,10,12,15}
local function add(x) table.insert(logs,tostring(x)) end
local function path(o) local ok,v=pcall(function() return o:GetFullName() end); return ok and v or o.Name end
local function v3(v) return string.format("(%.4f,%.4f,%.4f)",v.X,v.Y,v.Z) end
local function col(c) return string.format("(%.4f,%.4f,%.4f)",c.R,c.G,c.B) end
local function cframe(c)
 local x,y,z,r00,r01,r02,r10,r11,r12,r20,r21,r22=c:GetComponents()
 return string.format("Pos=(%.4f,%.4f,%.4f) M=[%.5f %.5f %.5f; %.5f %.5f %.5f; %.5f %.5f %.5f]",
 x,y,z,r00,r01,r02,r10,r11,r12,r20,r21,r22)
end
local function weapon()
 local c=P.Character if not c then return end
 local g=c:FindFirstChild("Gun"); if g and g:IsA("Tool") then return g,"Gun" end
 local k=c:FindFirstChild("Knife"); if k and k:IsA("Tool") then return k,"Knife" end
end

local classes={Decal=true,Texture=true,SpecialMesh=true,ParticleEmitter=true,Trail=true,Beam=true,Attachment=true,
 PointLight=true,SpotLight=true,SurfaceLight=true,Highlight=true,Sparkles=true,Fire=true,Smoke=true,
 Color3Value=true,NumberValue=true,StringValue=true,BoolValue=true,Script=true,LocalScript=true,ModuleScript=true}
local function interesting(o)
 if classes[o.ClassName] then return true end
 local n=o.Name:lower()
 return n:find("chroma",1,true) or n:find("effect",1,true) or n:find("rainbow",1,true) or n:find("color",1,true)
end
local function desc(o)
 local p=o.ClassName.." | "..o.Name.." | "..path(o)
 if o:IsA("Decal") or o:IsA("Texture") then
  return p..string.format(" | Texture=%s | Color3=%s | Transparency=%.5f",o.Texture,col(o.Color3),o.Transparency)
 elseif o:IsA("SpecialMesh") then
  return p..string.format(" | MeshId=%s | TextureId=%s | Scale=%s | Offset=%s | VertexColor=%s",o.MeshId,o.TextureId,v3(o.Scale),v3(o.Offset),v3(o.VertexColor))
 elseif o:IsA("ParticleEmitter") then
  return p..string.format(" | Enabled=%s | Texture=%s | Rate=%.4f | LightEmission=%.4f | TimeScale=%.4f",tostring(o.Enabled),o.Texture,o.Rate,o.LightEmission,o.TimeScale)
 elseif o:IsA("Trail") then
  return p..string.format(" | Enabled=%s | Texture=%s | Lifetime=%.4f",tostring(o.Enabled),o.Texture,o.Lifetime)
 elseif o:IsA("Beam") then
  return p..string.format(" | Enabled=%s | Texture=%s",tostring(o.Enabled),o.Texture)
 elseif o:IsA("Attachment") then return p.." | CFrame="..cframe(o.CFrame)
 elseif o:IsA("PointLight") or o:IsA("SpotLight") or o:IsA("SurfaceLight") then
  return p..string.format(" | Enabled=%s | Color=%s | Brightness=%.4f | Range=%.4f",tostring(o.Enabled),col(o.Color),o.Brightness,o.Range)
 elseif o:IsA("Highlight") then
  return p..string.format(" | Enabled=%s | FillColor=%s | FillTransparency=%.4f | OutlineColor=%s | OutlineTransparency=%.4f",
  tostring(o.Enabled),col(o.FillColor),o.FillTransparency,col(o.OutlineColor),o.OutlineTransparency)
 elseif o:IsA("Color3Value") then return p.." | Value="..col(o.Value)
 elseif o:IsA("NumberValue") or o:IsA("StringValue") or o:IsA("BoolValue") then return p.." | Value="..tostring(o.Value)
 elseif o:IsA("Script") or o:IsA("LocalScript") or o:IsA("ModuleScript") then
  local en="N/A"; pcall(function() en=tostring(o.Enabled) end); return p.." | Enabled="..en
 end
 return p
end

local function signature(tool)
 local a={}
 local h=tool:FindFirstChild("Handle")
 if h and h:IsA("BasePart") then table.insert(a,"HC="..col(h.Color).." HT="..string.format("%.5f",h.Transparency)) end
 for _,o in ipairs(tool:GetDescendants()) do if interesting(o) then local ok,x=pcall(desc,o); if ok then table.insert(a,x) end end end
 table.sort(a); return table.concat(a,"\n")
end
local function snap(tool,typ,t)
 add(""); add(("="):rep(55)); add(string.format("SAMPLE t=%.1fs | Weapon=%s",t,typ)); add(("="):rep(55))
 add("TOOL | TextureId="..tool.TextureId.." | Grip="..cframe(tool.Grip).." | GripPos="..v3(tool.GripPos))
 local h=tool:FindFirstChild("Handle")
 if h and h:IsA("BasePart") then add(string.format("HANDLE | Size=%s | Color=%s | Material=%s | Transparency=%.5f",v3(h.Size),col(h.Color),tostring(h.Material),h.Transparency)) end
 local n=0
 for _,o in ipairs(tool:GetDescendants()) do if interesting(o) then n+=1; local ok,x=pcall(desc,o); if ok then add(x) end end end
 add("InterestingDescendantCount="..n)
end

Start.MouseButton1Click:Connect(function()
 if running then return end
 local tool,typ=weapon()
 if not tool then S.Text="No equipped Gun or Knife found."; return end
 running=true; logs={}
 add("BLIZZARD CHROMA WEAPON DIAGNOSTIC"); add("WeaponType="..typ); add("InitialPath="..path(tool)); add("Samples=0,1,2,3,5,7,10,12,15")
 local t0=os.clock(); local last=nil; local changes=0
 for _,target in ipairs(times) do
  local w=target-(os.clock()-t0); if w>0 then task.wait(w) end
  local now,nowType=weapon()
  if now~=tool or nowType~=typ then add("ABORTED: weapon changed."); S.Text="Aborted — weapon changed."; running=false; return end
  S.Text=string.format("Capturing %s... %d / 15 sec",typ,target); snap(tool,typ,target)
  local sig=signature(tool)
  if last then local changed=sig~=last; if changed then changes+=1 end; add("STATE_CHANGE_FROM_PREVIOUS_SAMPLE="..tostring(changed)) end
  last=sig
 end
 add(""); add("SUMMARY | ChangedSampleIntervals="..changes); add("END")
 running=false; S.Text="Done. Press COPY LOGS."
end)

Copy.MouseButton1Click:Connect(function()
 if #logs==0 then S.Text="No logs yet."; return end
 local text=table.concat(logs,"\n"); local ok=false
 if setclipboard then ok=pcall(setclipboard,text) elseif toclipboard then ok=pcall(toclipboard,text) end
 if ok then S.Text="Logs copied." else S.Text="Clipboard unavailable; logs printed."; print(text) end
end)

print("[Blizzard] Chroma Weapon Diagnostic loaded")
