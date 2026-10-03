-- BLIZZARD WEAPON SKIN CAPTURE DIAGNOSTIC
-- Standalone / read-only. Capture equipped Gun or Knife, hotbar, held geometry,
-- holster candidates, meshes/textures, attachments, welds, and visual effects.

local Players=game:GetService("Players")
local P=Players.LocalPlayer
local PG=P:WaitForChild("PlayerGui")
local old=PG:FindFirstChild("BlizzardWeaponSkinCaptureDiagnostic") if old then old:Destroy() end
local captures,n={},0

local function safe(f,d) local ok,r=pcall(f); if ok then return r end; return d or "<error>" end
local function path(o) return safe(function() return o:GetFullName() end,tostring(o)) end
local function v3(v) return string.format("(%.4f, %.4f, %.4f)",v.X,v.Y,v.Z) end
local function c3(c) return string.format("(%.4f, %.4f, %.4f)",c.R,c.G,c.B) end
local function cf(c) local x,y,z,a,b,d,e,f,g,h,i,j=c:GetComponents(); return string.format("Pos=(%.4f,%.4f,%.4f) M=[%.5f %.5f %.5f; %.5f %.5f %.5f; %.5f %.5f %.5f]",x,y,z,a,b,d,e,f,g,h,i,j) end
local function add(t,s) t[#t+1]=tostring(s) end

local function describe(o,t,p)
 p=p or ""; add(t,p.."INSTANCE | Class="..o.ClassName.." | Name="..o.Name.." | Path="..path(o))
 local attrs=safe(function() return o:GetAttributes() end,{})
 for k,v in pairs(attrs) do add(t,p.."  ATTRIBUTE | "..k.."="..tostring(v)) end
 if o:IsA("Tool") then
  add(t,p.."  TOOL | TextureId="..tostring(o.TextureId).." | Grip="..cf(o.Grip).." | GripPos="..v3(o.GripPos).." | RequiresHandle="..tostring(o.RequiresHandle))
 elseif o:IsA("BasePart") then
  add(t,p.."  PART | CFrame="..cf(o.CFrame).." | Position="..v3(o.Position).." | Orientation="..v3(o.Orientation).." | Size="..v3(o.Size).." | Transparency="..o.Transparency.." | Color="..c3(o.Color).." | Material="..tostring(o.Material))
  if o:IsA("MeshPart") then add(t,p.."  MESHPART | MeshId="..tostring(o.MeshId).." | TextureID="..tostring(o.TextureID)) end
 elseif o:IsA("SpecialMesh") then
  add(t,p.."  MESH | MeshType="..tostring(o.MeshType).." | MeshId="..tostring(o.MeshId).." | TextureId="..tostring(o.TextureId).." | Scale="..v3(o.Scale).." | Offset="..v3(o.Offset))
 elseif o:IsA("Decal") or o:IsA("Texture") then
  add(t,p.."  TEXTURE | Texture="..tostring(o.Texture).." | Transparency="..o.Transparency.." | Color3="..c3(o.Color3))
 elseif o:IsA("Attachment") then
  add(t,p.."  ATTACHMENT | CFrame="..cf(o.CFrame).." | Position="..v3(o.Position).." | Orientation="..v3(o.Orientation))
 elseif o:IsA("Weld") or o:IsA("Motor6D") or o:IsA("ManualWeld") then
  add(t,p.."  JOINT | Part0="..tostring(o.Part0 and path(o.Part0) or "nil").." | Part1="..tostring(o.Part1 and path(o.Part1) or "nil").." | C0="..cf(o.C0).." | C1="..cf(o.C1))
 elseif o:IsA("WeldConstraint") then
  add(t,p.."  WELD | Part0="..tostring(o.Part0 and path(o.Part0) or "nil").." | Part1="..tostring(o.Part1 and path(o.Part1) or "nil"))
 elseif o:IsA("ParticleEmitter") then
  add(t,p.."  PARTICLE | Enabled="..tostring(o.Enabled).." | Texture="..tostring(o.Texture).." | Rate="..o.Rate.." | Lifetime="..tostring(o.Lifetime).." | Speed="..tostring(o.Speed).." | Color="..tostring(o.Color).." | Transparency="..tostring(o.Transparency).." | Size="..tostring(o.Size).." | LightEmission="..o.LightEmission)
 elseif o:IsA("Trail") then
  add(t,p.."  TRAIL | Enabled="..tostring(o.Enabled).." | Texture="..tostring(o.Texture).." | Lifetime="..o.Lifetime.." | Color="..tostring(o.Color).." | Transparency="..tostring(o.Transparency).." | WidthScale="..tostring(o.WidthScale).." | A0="..tostring(o.Attachment0 and path(o.Attachment0) or "nil").." | A1="..tostring(o.Attachment1 and path(o.Attachment1) or "nil"))
 elseif o:IsA("Beam") then
  add(t,p.."  BEAM | Enabled="..tostring(o.Enabled).." | Texture="..tostring(o.Texture).." | TextureSpeed="..o.TextureSpeed.." | Width0="..o.Width0.." | Width1="..o.Width1.." | Color="..tostring(o.Color).." | Transparency="..tostring(o.Transparency))
 elseif o:IsA("PointLight") or o:IsA("SpotLight") or o:IsA("SurfaceLight") then
  add(t,p.."  LIGHT | Enabled="..tostring(o.Enabled).." | Brightness="..o.Brightness.." | Range="..o.Range.." | Color="..c3(o.Color))
 elseif o:IsA("Highlight") then
  add(t,p.."  HIGHLIGHT | Enabled="..tostring(o.Enabled).." | FillColor="..c3(o.FillColor).." | OutlineColor="..c3(o.OutlineColor))
 elseif o:IsA("ImageLabel") or o:IsA("ImageButton") then
  add(t,p.."  IMAGE | Image="..tostring(o.Image).." | Visible="..tostring(o.Visible).." | Transparency="..o.ImageTransparency)
 end
end

local function equipped()
 local ch=P.Character; if not ch then return nil end
 for _,name in ipairs({"Gun","Knife"}) do local x=ch:FindFirstChild(name); if x and x:IsA("Tool") then return x end end
 return ch:FindFirstChildOfClass("Tool")
end
local function icons()
 local r={}; for _,d in ipairs(PG:GetDescendants()) do if d.Name=="ToolIcon" and (d:IsA("ImageLabel") or d:IsA("ImageButton")) and d:FindFirstAncestor("BackpackFrame") then r[#r+1]=d end end; return r
end
local function candidates(ch,w)
 local r={}; if not ch then return r end
 for _,d in ipairs(ch:GetDescendants()) do
  if not w or not d:IsDescendantOf(w) then
   local s=d.Name:lower(); local named=s:find("gun",1,true) or s:find("knife",1,true) or s:find("holster",1,true) or s:find("weapon",1,true) or s:find("chroma",1,true) or s:find("effect",1,true)
   if named or d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") then r[#r+1]=d end
  end
 end
 return r
end

local function capture()
 n+=1; local t={}; local ch=P.Character; local w=equipped()
 add(t,"============================================================"); add(t,"CAPTURE #"..n); add(t,"============================================================")
 add(t,"EquippedWeapon="..tostring(w and w.Name or "NONE")); add(t,"EquippedWeaponPath="..tostring(w and path(w) or "nil"))
 add(t,"\n---------------- EQUIPPED TOOL ----------------")
 if w then describe(w,t); local ds=w:GetDescendants(); table.sort(ds,function(a,b)return path(a)<path(b)end); for _,d in ipairs(ds) do describe(d,t,"  ") end else add(t,"WARNING: No equipped Tool. Hold the Gun/Knife before Capture.") end
 add(t,"\n---------------- HOTBAR ----------------"); local hs=icons(); add(t,"LiveToolIconCount="..#hs); for i,x in ipairs(hs) do add(t,"HOTBAR ICON #"..i); describe(x,t,"  ") end
 add(t,"\n---------------- CHARACTER / HOLSTER / EFFECT CANDIDATES ----------------"); local cs=candidates(ch,w); add(t,"CandidateCount="..#cs); for _,x in ipairs(cs) do describe(x,t,"  ") end
 add(t,"\nEND CAPTURE #"..n); add(t,"============================================================")
 captures[#captures+1]=table.concat(t,"\n"); return captures[#captures],w
end

local gui=Instance.new("ScreenGui"); gui.Name="BlizzardWeaponSkinCaptureDiagnostic"; gui.ResetOnSpawn=false; gui.DisplayOrder=999999; gui.Parent=PG
local main=Instance.new("Frame"); main.Size=UDim2.fromOffset(500,390); main.Position=UDim2.new(.5,-250,.5,-195); main.BackgroundColor3=Color3.fromRGB(20,20,23); main.BorderSizePixel=0; main.Active=true; main.Draggable=true; main.Parent=gui; Instance.new("UICorner",main).CornerRadius=UDim.new(0,10)
local title=Instance.new("TextLabel"); title.BackgroundTransparency=1; title.Position=UDim2.fromOffset(12,8); title.Size=UDim2.new(1,-24,0,24); title.Font=Enum.Font.GothamBold; title.TextSize=14; title.TextColor3=Color3.new(1,1,1); title.TextXAlignment=Enum.TextXAlignment.Left; title.Text="Blizzard Weapon Skin Capture"; title.Parent=main
local status=Instance.new("TextLabel"); status.BackgroundTransparency=1; status.Position=UDim2.fromOffset(12,32); status.Size=UDim2.new(1,-24,0,20); status.Font=Enum.Font.Gotham; status.TextSize=11; status.TextColor3=Color3.fromRGB(190,190,195); status.TextXAlignment=Enum.TextXAlignment.Left; status.Text="Equip Gun or Knife, then press Capture."; status.Parent=main
local scroll=Instance.new("ScrollingFrame"); scroll.Position=UDim2.fromOffset(10,58); scroll.Size=UDim2.new(1,-20,1,-110); scroll.BackgroundColor3=Color3.fromRGB(13,13,15); scroll.BorderSizePixel=0; scroll.ScrollBarThickness=4; scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; scroll.Parent=main; Instance.new("UICorner",scroll).CornerRadius=UDim.new(0,7)
local out=Instance.new("TextLabel"); out.BackgroundTransparency=1; out.Position=UDim2.fromOffset(7,6); out.Size=UDim2.new(1,-14,0,0); out.AutomaticSize=Enum.AutomaticSize.Y; out.Font=Enum.Font.Code; out.TextSize=9; out.TextColor3=Color3.fromRGB(225,225,230); out.TextXAlignment=Enum.TextXAlignment.Left; out.TextYAlignment=Enum.TextYAlignment.Top; out.Text=""; out.Parent=scroll
local buttons=Instance.new("Frame"); buttons.BackgroundTransparency=1; buttons.Position=UDim2.new(0,10,1,-42); buttons.Size=UDim2.new(1,-20,0,32); buttons.Parent=main; local lay=Instance.new("UIListLayout",buttons); lay.FillDirection=Enum.FillDirection.Horizontal; lay.Padding=UDim.new(0,7)
local function btn(s) local b=Instance.new("TextButton"); b.Size=UDim2.new(1/3,-5,1,0); b.BackgroundColor3=Color3.fromRGB(39,39,44); b.TextColor3=Color3.new(1,1,1); b.Font=Enum.Font.GothamSemibold; b.TextSize=11; b.Text=s; b.Parent=buttons; Instance.new("UICorner",b).CornerRadius=UDim.new(0,7); return b end
local cap,copy,clear=btn("CAPTURE"),btn("COPY ALL"),btn("CLEAR ALL")
cap.MouseButton1Click:Connect(function() local s,w=capture(); out.Text=s; status.Text="Saved Capture #"..n.." — "..tostring(w and w.Name or "NO WEAPON") end)
copy.MouseButton1Click:Connect(function() local s=table.concat(captures,"\n\n"); if setclipboard then pcall(setclipboard,s) elseif toclipboard then pcall(toclipboard,s) end; status.Text="Copied "..#captures.." capture(s)." end)
clear.MouseButton1Click:Connect(function() table.clear(captures); n=0; out.Text=""; status.Text="All captures cleared. Counter reset." end)
