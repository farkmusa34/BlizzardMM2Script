-- BLIZZARD V7 | STAR HUB STYLE | STANDALONE VISUAL PREVIEW
-- UI controls change preview state only. No MM2 gameplay modules are called.
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local parent=player:WaitForChild("PlayerGui")
for _,n in ipairs({"BlizzardStarPreview","BlizzardV5","BlizzardV6","BlizzardV7"}) do
 local g=parent:FindFirstChild(n);if g then g:Destroy() end
end
local C={
 bg=Color3.fromRGB(10,10,13),panel=Color3.fromRGB(18,18,23),
 card=Color3.fromRGB(21,21,26),hover=Color3.fromRGB(37,37,43),
 border=Color3.fromRGB(44,44,52),white=Color3.fromRGB(246,246,249),
 muted=Color3.fromRGB(126,126,141),green=Color3.fromRGB(35,192,105),
 blue=Color3.fromRGB(77,156,255),yellow=Color3.fromRGB(255,197,56),
 red=Color3.fromRGB(246,75,88),purple=Color3.fromRGB(188,132,255)
}
local function make(t,p,props)
 local o=Instance.new(t)
 for k,v in pairs(props or {}) do o[k]=v end
 o.Parent=p;return o
end
local function round(o,r)make("UICorner",o,{CornerRadius=UDim.new(0,r)})end
local function line(o,color)make("UIStroke",o,{Color=color or C.border,Thickness=1,Transparency=.12})end
local function txt(p,s,x,y,w,h,size,color,bold)
 return make("TextLabel",p,{BackgroundTransparency=1,Position=UDim2.fromOffset(x,y),
 Size=UDim2.fromOffset(w,h),Text=s,TextColor3=color or C.white,
 Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,TextSize=size or 14,
 TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,
 TextTruncate=Enum.TextTruncate.AtEnd})
end
local function button(p,x,y,w,h,bg)
 local o=make("TextButton",p,{Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),
 BackgroundColor3=bg or C.hover,Text="",AutoButtonColor=false,BorderSizePixel=0})
 round(o,9);return o
end
-- Exact icon metadata loader retained from V6. Unsupported metadata shows '?'.
local iconPack
pcall(function()
 local result=loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/Icons/main/lucide/dist/Icons.lua"))()
 if type(result)=="table" then iconPack=result end
end)
local function ico(p,name,x,y,size,color)
 local holder=make("Frame",p,{Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(size,size),BackgroundTransparency=1})
 local d=iconPack and iconPack[name]
 local id,offset,rect
 if type(d)=="string" then id=d
 elseif type(d)=="table" then
  if type(d[1])=="string" then id=d[1];local m=d[2];if type(m)=="table" then offset=m.ImageRectPosition;rect=m.ImageRectSize end
  elseif type(d.Image)=="string" then id=d.Image;offset=d.ImageRectPosition or d.RectOffset;rect=d.ImageRectSize or d.RectSize end
 end
 if id then
  local im=make("ImageLabel",holder,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=id,ImageColor3=color or C.white,ScaleType=Enum.ScaleType.Fit})
  if typeof(offset)=="Vector2" then im.ImageRectOffset=offset end
  if typeof(rect)=="Vector2" then im.ImageRectSize=rect end
 else
  local f=txt(holder,"?",0,0,size,size,math.max(12,size-3),C.muted,true);f.TextXAlignment=Enum.TextXAlignment.Center
 end
 return holder
end
local gui=make("ScreenGui",parent,{Name="BlizzardV7",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=999})
local window=make("Frame",gui,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.53),
 Size=UDim2.fromOffset(900,510),BackgroundColor3=C.bg,BorderSizePixel=0,ClipsDescendants=true})
round(window,18);line(window,Color3.fromRGB(89,89,99))
local scale=make("UIScale",window,{Scale=1})
local function resize()
 local v=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1000,700)
 scale.Scale=math.max(.28,math.min(1,(v.X-24)/900,(v.Y-54)/510))
end
resize()
local cameraConnection
local function watchCamera()
 if cameraConnection then cameraConnection:Disconnect() end
 if workspace.CurrentCamera then cameraConnection=workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
 resize()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
watchCamera()
local header=make("Frame",window,{Size=UDim2.fromOffset(900,76),BackgroundColor3=C.bg,BorderSizePixel=0})
make("Frame",header,{Position=UDim2.fromOffset(0,75),Size=UDim2.fromOffset(900,1),BackgroundColor3=C.border,BorderSizePixel=0})
local logo=make("Frame",header,{Position=UDim2.fromOffset(20,17),Size=UDim2.fromOffset(40,40),BackgroundColor3=C.hover});round(logo,11)
ico(logo,"snowflake",8,8,24,C.white)
txt(header,"Blizzard",69,14,134,29,22,C.white,true)
local version=make("Frame",header,{Position=UDim2.fromOffset(185,19),Size=UDim2.fromOffset(67,23),BackgroundColor3=C.panel});round(version,12)
txt(version,"v1.85.4",9,2,56,18,11,C.muted,true)
local fpsDot=make("Frame",header,{Position=UDim2.fromOffset(70,53),Size=UDim2.fromOffset(7,7),BackgroundColor3=C.green});round(fpsDot,4)
local fpsLabel=txt(header,"-- fps",83,46,68,22,11,C.muted)
local pingDot=make("Frame",header,{Position=UDim2.fromOffset(151,53),Size=UDim2.fromOffset(7,7),BackgroundColor3=C.yellow});round(pingDot,4)
local pingLabel=txt(header,"-- ms",163,46,65,22,11,C.muted)
local count=0;local last=os.clock()
local perf=RunService.RenderStepped:Connect(function()
 count=count+1
 if os.clock()-last>=1 then fpsLabel.Text=tostring(math.floor(count/(os.clock()-last)+.5)).." fps";count=0;last=os.clock() end
end)
local okStats,stats=pcall(function()return game:GetService("Stats")end)
task.spawn(function()
 while gui.Parent do
  if okStats and stats then
   pcall(function()
    local ms=stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    pingLabel.Text=tostring(math.floor(ms+.5)).." ms"
    pingDot.BackgroundColor3=ms<100 and C.green or C.yellow
   end)
  end
  task.wait(3)
 end
end)
local search=make("Frame",header,{Position=UDim2.fromOffset(329,15),Size=UDim2.fromOffset(348,45),BackgroundColor3=C.panel});round(search,11);line(search)
ico(search,"search",15,13,19,C.muted)
local searchBox=make("TextBox",search,{Position=UDim2.fromOffset(45,4),Size=UDim2.fromOffset(289,37),BackgroundTransparency=1,
 Text="",PlaceholderText="Search settings",PlaceholderColor3=C.muted,TextColor3=C.white,TextSize=15,Font=Enum.Font.Gotham,
 TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false})
local sidebar=make("Frame",window,{Position=UDim2.fromOffset(0,76),Size=UDim2.fromOffset(245,434),BackgroundColor3=C.bg,BorderSizePixel=0})
make("Frame",sidebar,{Position=UDim2.fromOffset(244,0),Size=UDim2.fromOffset(1,434),BackgroundColor3=C.border,BorderSizePixel=0})
local sideScroll=make("ScrollingFrame",sidebar,{Position=UDim2.fromOffset(0,0),Size=UDim2.fromOffset(244,354),
 BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=C.border,CanvasSize=UDim2.fromOffset(0,0)})
local footer=make("Frame",sidebar,{Position=UDim2.fromOffset(14,365),Size=UDim2.fromOffset(214,57),BackgroundColor3=C.panel});round(footer,12)
local avatarUrl="rbxthumb://type=AvatarHeadShot&id="..player.UserId.."&w=150&h=150"
local av=make("ImageLabel",footer,{Position=UDim2.fromOffset(10,9),Size=UDim2.fromOffset(39,39),BackgroundColor3=C.hover,Image=avatarUrl});round(av,20)
txt(footer,player.DisplayName,57,8,150,22,13,C.white,true)
txt(footer,"@"..player.Name,57,30,150,17,11,C.muted)
local dot=make("Frame",footer,{Position=UDim2.fromOffset(42,41),Size=UDim2.fromOffset(11,11),BackgroundColor3=C.green});round(dot,6)
local main=make("Frame",window,{Position=UDim2.fromOffset(245,76),Size=UDim2.fromOffset(655,434),BackgroundColor3=C.bg,BorderSizePixel=0})
local content=make("ScrollingFrame",main,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,
 ScrollBarThickness=3,ScrollBarImageColor3=C.border,CanvasSize=UDim2.fromOffset(0,600),ScrollingDirection=Enum.ScrollingDirection.Y})
local navGroups={
 {"HOME",{{"Home","house"}}},
 {"SETTINGS",{{"On-Screen Buttons","mouse-pointer-2"},{"General","sliders-horizontal"}}},
 {"PLAYER",{{"Movement","footprints"},{"Players","users"}}},
 {"COMBAT",{{"Aim","crosshair"},{"Sheriff & Murderer","sword"},{"Fling","wind"}}},
 {"VISUALS",{{"ESP","scan-eye"},{"Effects","sparkles"},{"Role ESP","eye"}}},
 {"SKIN CHANGER",{{"Gun","crosshair"},{"Knife","sword"}}},
 {"FARMING",{{"Auto Farm","bot"}}},
 {"MISC",{{"Teleport","navigation"},{"Misc","settings"}}}
}
local groupIcons={HOME="house",SETTINGS="settings",PLAYER="user-round",COMBAT="swords",VISUALS="eye",["SKIN CHANGER"]="palette",FARMING="coins",MISC="settings"}
local expanded={};for _,g in ipairs(navGroups)do expanded[g[1]]=true end
local selected="Home"
local renderPage
local function divider(p,y,x,w)
 make("Frame",p,{Position=UDim2.fromOffset(x or 20,y),Size=UDim2.fromOffset(w or 557,1),BackgroundColor3=C.border,BorderSizePixel=0})
end
local function navRender()
 sideScroll:ClearAllChildren()
 local y=10
 for _,g in ipairs(navGroups) do
  local groupName,items=g[1],g[2]
  if groupName~="HOME" then
   y=y+7
   local h=button(sideScroll,14,y,214,31,C.bg)
   ico(h,groupIcons[groupName],10,6,17,C.muted)
   txt(h,groupName,36,4,147,23,11,C.muted,true)
   ico(h,expanded[groupName] and "chevron-down" or "chevron-right",190,8,15,C.muted)
   h.MouseButton1Click:Connect(function()expanded[groupName]=not expanded[groupName];navRender()end)
   y=y+34
  end
  if groupName=="HOME" or expanded[groupName] then
   for _,item in ipairs(items) do
    local name,ic=item[1],item[2]
    local active=selected==name
    local b=button(sideScroll,14,y,214,43,active and C.hover or C.bg)
    if active then local bar=make("Frame",b,{Position=UDim2.fromOffset(3,10),Size=UDim2.fromOffset(4,23),BackgroundColor3=C.white});round(bar,3)end
    ico(b,ic,17,11,21,active and C.white or C.muted)
    txt(b,name,51,8,154,27,15,active and C.white or C.muted,active)
    b.MouseButton1Click:Connect(function()selected=name;navRender();renderPage()end)
    y=y+49
   end
   if groupName=="HOME" then divider(sideScroll,y+4,18,208);y=y+17 end
  end
 end
 sideScroll.CanvasSize=UDim2.fromOffset(0,y+16)
end
local function card(y,title,ic)
 local box=make("Frame",content,{Position=UDim2.fromOffset(27,y),Size=UDim2.fromOffset(597,64),BackgroundColor3=C.panel,BorderSizePixel=0});round(box,16)
 ico(box,ic or "settings",21,19,23,C.white)
 txt(box,title,57,12,465,38,17,C.white,true)
 return box
end
local function toggle(parent,x,y,on)
 local b=button(parent,x,y,57,31,on and C.white or Color3.fromRGB(49,49,59))
 local knob=make("Frame",b,{Position=UDim2.fromOffset(on and 29 or 4,4),Size=UDim2.fromOffset(23,23),
 BackgroundColor3=on and C.bg or C.muted});round(knob,8)
 b.MouseButton1Click:Connect(function()
  on=not on;b.BackgroundColor3=on and C.white or Color3.fromRGB(49,49,59)
  knob.Position=UDim2.fromOffset(on and 29 or 4,4);knob.BackgroundColor3=on and C.bg or C.muted
 end)
 return b
end
local function action(parent,x,y,ic)
 local b=button(parent,x,y,42,34,C.hover);ico(b,ic,11,8,20,C.white);return b
end
local function addRow(box,y,name,kind,ic)
 divider(box,y,20,557)
 txt(box,name,24,y+8,430,39,15,C.white)
 if kind=="toggle" then toggle(box,508,y+12,false)
 elseif kind=="on" then toggle(box,508,y+12,true)
 else action(box,528,y+10,ic or "play") end
 return y+56
end
local function addSlider(box,y,name,minv,maxv,value)
 divider(box,y,20,557)
 txt(box,name,24,y+8,410,32,15,C.white)
 local val=txt(box,tostring(value),520,y+8,50,30,14,C.white,true);val.TextXAlignment=Enum.TextXAlignment.Right
 local track=button(box,24,y+55,549,5,C.hover);round(track,3)
 local fill=make("Frame",track,{Size=UDim2.fromScale((value-minv)/(maxv-minv),1),BackgroundColor3=Color3.fromRGB(205,205,215)});round(fill,3)
 local knob=make("Frame",track,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale((value-minv)/(maxv-minv),.5),Size=UDim2.fromOffset(17,17),BackgroundColor3=C.white});round(knob,9)
 local function update(input)
  local fraction=math.clamp((input.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
  local v=math.floor(minv+(maxv-minv)*fraction+.5)
  val.Text=tostring(v);fill.Size=UDim2.fromScale(fraction,1);knob.Position=UDim2.fromScale(fraction,.5)
 end
 local dragging=false
 track.InputBegan:Connect(function(input)if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=true;update(input)end end)
 UIS.InputChanged:Connect(function(input)if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then update(input)end end)
 UIS.InputEnded:Connect(function(input)if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
 return y+91
end
local function section(y,title,ic,rows)
 local box=card(y,title,ic)
 local cursor=55
 for _,r in ipairs(rows)do
  if r[2]=="slider" then cursor=addSlider(box,cursor,r[1],r[3],r[4],r[5])
  else cursor=addRow(box,cursor,r[1],r[2],r[3]) end
 end
 box.Size=UDim2.fromOffset(597,cursor+8)
 return y+cursor+26
end
local function pageHead(category,name,ic)
 local badge=make("Frame",content,{Position=UDim2.fromOffset(27,19),Size=UDim2.fromOffset(46,46),BackgroundColor3=C.hover});round(badge,12)
 ico(badge,ic,11,11,24,C.white)
 txt(content,category,89,15,450,23,11,C.muted,true)
 txt(content,name,89,35,460,37,24,C.white,true)
end
local function home()
 pageHead("OVERVIEW","Home","house")
 local profile=make("Frame",content,{Position=UDim2.fromOffset(27,87),Size=UDim2.fromOffset(597,146),BackgroundColor3=Color3.fromRGB(14,24,20)});round(profile,16);line(profile,C.border)
 local accent=make("Frame",profile,{Size=UDim2.fromOffset(3,146),BackgroundColor3=C.green});round(accent,2)
 local big=make("ImageLabel",profile,{Position=UDim2.fromOffset(20,19),Size=UDim2.fromOffset(68,68),BackgroundColor3=C.hover,Image=avatarUrl});round(big,35);line(big,C.green)
 txt(profile,player.DisplayName,104,22,320,29,19,C.white,true)
 txt(profile,"@"..player.Name,104,52,320,22,13,C.muted)
 local role=make("Frame",profile,{Position=UDim2.fromOffset(468,25),Size=UDim2.fromOffset(108,30),BackgroundColor3=C.hover});round(role,15)
 local rt=txt(role,"PREVIEW",0,4,108,22,12,C.white,true);rt.TextXAlignment=Enum.TextXAlignment.Center
 local chips={{"Murderer: Preview","sword",C.red,20,176},{"Sheriff: Preview","shield",C.blue,204,176},{"Bag: Preview","shopping-bag",C.yellow,388,187}}
 for _,c in ipairs(chips)do
  local chip=make("Frame",profile,{Position=UDim2.fromOffset(c[4],104),Size=UDim2.fromOffset(c[5],28),BackgroundColor3=Color3.fromRGB(32,39,37)});round(chip,14)
  ico(chip,c[2],8,6,16,c[3]);txt(chip,c[1],31,4,c[5]-35,21,11,C.white)
 end
 local statsBox=make("Frame",content,{Position=UDim2.fromOffset(27,247),Size=UDim2.fromOffset(597,102),BackgroundColor3=C.panel});round(statsBox,16);line(statsBox)
 for i,d in ipairs({{"—","COINS",C.yellow},{"—","GEMS",C.blue},{"—","LEVEL",C.purple}})do
  local x=(i-1)*199
  local a=txt(statsBox,d[1],x+10,15,178,39,26,C.white,true);a.TextXAlignment=Enum.TextXAlignment.Center
  local b=txt(statsBox,d[2],x+10,61,178,21,12,d[3],true);b.TextXAlignment=Enum.TextXAlignment.Center
  if i>1 then make("Frame",statsBox,{Position=UDim2.fromOffset(x,17),Size=UDim2.fromOffset(1,68),BackgroundColor3=C.border})end
 end
 local status=make("Frame",content,{Position=UDim2.fromOffset(27,364),Size=UDim2.fromOffset(597,105),BackgroundColor3=C.panel});round(status,16);line(status)
 for i,d in ipairs({{"—","AUTO FARM",C.green},{"—","ESP ACTIVE",C.green},{"0","COLLECTED",C.yellow},{"0h 00m","UPTIME",C.white}})do
  local x=(i-1)*149
  local a=txt(status,d[1],x,18,149,38,22,d[3],true);a.TextXAlignment=Enum.TextXAlignment.Center
  local b=txt(status,d[2],x,64,149,23,11,C.muted,true);b.TextXAlignment=Enum.TextXAlignment.Center
  if i>1 then make("Frame",status,{Position=UDim2.fromOffset(x,19),Size=UDim2.fromOffset(1,67),BackgroundColor3=C.border})end
 end
 local q=card(483,"Quick Actions","zap");q.Size=UDim2.fromOffset(597,238)
 local y=60
 for _,d in ipairs({{"Shoot Murderer","crosshair"},{"Fling Murderer","wind"},{"Kill All","swords"},{"Hop Server","shuffle"}})do y=addRow(q,y,d[1],"action",d[2]) end
 content.CanvasSize=UDim2.fromOffset(0,750)
end
local pages={
 ["General"]={"SETTINGS","sliders-horizontal",{
  {"Appearance","palette",{{"Background Thumbnail","toggle"}}},
  {"Performance","zap",{{"Lite Mode","toggle"},{"FPS Boost","toggle"}}},
  {"Config","save",{{"Auto Save","on"},{"Save Now","action","save"},{"Load Saved","action","folder-open"}}},
  {"Panel","panel-top",{{"Hide Panel","action","eye-off"},{"Unload Preview","action","power"}}}
 }},
 ["On-Screen Buttons"]={"SETTINGS","mouse-pointer-2",{
  {"Layout","settings",{{"Lock Buttons","toggle"},{"Button Size","slider",50,150,100},{"Reset Size / Positions","action","rotate-ccw"}}},
  {"Sheriff","shield",{{"Shoot Murderer Button","toggle"},{"Rage Shoot Button","toggle"}}},
  {"Murderer","sword",{{"Throw Knife Button","toggle"},{"Kill All Button","toggle"}}},
  {"Fling","wind",{{"Fling Murderer Button","toggle"},{"Fling Sheriff / Hero Button","toggle"}}},
  {"Player","user-round",{{"Bomb Boost Button","toggle"},{"Fly Button","toggle"},{"Noclip Button","toggle"},{"Infinite Jump Button","toggle"}}}
 }},
 ["Movement"]={"PLAYER","footprints",{
  {"Movement","footprints",{{"Walk Speed","slider",16,100,16},{"Jump Power","slider",50,150,50},{"Walk Through Walls with Freefall Protection","toggle"}}},
  {"Fly","plane",{{"Fly","toggle"},{"Fly Speed","slider",10,100,10}}},
  {"Jumping","arrow-up",{{"Infinite Jump","toggle"},{"Wall Jump","toggle"}}},
  {"Bomb Boost","bomb",{{"Bomb Boost Button","action","bomb"},{"Boost Power","slider",30,250,120}}}
 }},
 ["Players"]={"PLAYER","users",{
  {"Alerts","triangle-alert",{{"Round Start Alert","on"}}}
 }},
 ["Aim"]={"COMBAT","crosshair",{
  {"Aim","crosshair",{{"TriggerBot","toggle"},{"Aim Lock","toggle"},{"Shoot Murderer (Legit)","action","crosshair"}}},
  {"Accuracy","target",{{"Aim Prediction","on"},{"Prediction Strength","slider",30,250,100},{"Wall Throw","toggle"}}}
 }},
 ["Sheriff & Murderer"]={"COMBAT","sword",{
  {"Sheriff","shield",{{"Shoot Murderer","action","crosshair"},{"Rage Shoot","toggle"}}},
  {"Murderer","sword",{{"Legit Throw","toggle"},{"Auto Throw Knife (RAGE)","toggle"},{"Throw Aimbot Button","action","sword"},{"Kill All","action","swords"}}}
 }},
 ["Fling"]={"COMBAT","wind",{
  {"Fling","wind",{{"Fling Murderer Button","toggle"},{"Fling Sheriff / Hero Button","toggle"},{"Anti Fling","toggle"},{"Fling Notify","toggle"}}}
 }},
 ["ESP"]={"VISUALS","scan-eye",{
  {"Player ESP","eye",{{"Match ESP","toggle"},{"Gun ESP","toggle"},{"Tracers","toggle"},{"Nametags","toggle"},{"Distance ESP","toggle"}}}
 }},
 ["Effects"]={"VISUALS","sparkles",{
  {"Visual Effects","sparkles",{{"Tracers","toggle"},{"Tracer Thickness","slider",1,10,3},{"Glow","toggle"}}}
 }},
 ["Role ESP"]={"VISUALS","eye",{
  {"Role Display","scan-eye",{{"Role ESP","toggle"},{"Show Role Labels","toggle"},{"Show Distance","toggle"}}}
 }},
 ["Gun"]={"SKIN CHANGER","crosshair",{
  {"Gun Skins","palette",{{"Enable Gun Skin Changer","toggle"},{"Select Gun Skin","action","chevron-down"}}}
 }},
 ["Knife"]={"SKIN CHANGER","sword",{
  {"Knife Skins","palette",{{"Enable Knife Skin Changer","toggle"},{"Select Knife Skin","action","chevron-down"}}}
 }},
 ["Auto Farm"]={"FARMING","bot",{
  {"Coin Farm","coins",{{"Auto Farm Coins","toggle"},{"Farm Underground","toggle"},{"Farm Speed","slider",1,25,25}}},
  {"When The Bag Is Full","backpack",{{"Fling Murderer","toggle"},{"Shoot Murderer","toggle"},{"Kill All","toggle"},{"Reset Character","toggle"}}},
  {"Statistics","chart-no-axes-column",{{"Reset Stats","action","rotate-ccw"}}}
 }},
 ["Teleport"]={"MISC","navigation",{
  {"Teleport","navigation",{{"Teleport to Map","action","map-pin"},{"Teleport to Lobby","action","house"}}}
 }},
 ["Misc"]={"MISC","settings",{
  {"Miscellaneous","settings",{{"Anti AFK","toggle"},{"Hop Server","action","shuffle"},{"Notifications","on"}}}
 }}
}
function renderPage()
 content:ClearAllChildren()
 content.CanvasPosition=Vector2.zero
 if selected=="Home" then home();return end
 local p=pages[selected];if not p then return end
 pageHead(p[1],selected,p[2])
 local y=87
 for _,sec in ipairs(p[3])do y=section(y,sec[1],sec[2],sec[3])end
 if selected=="Players" then
  txt(content,"PLAYERS IN THIS SERVER",28,y+5,400,25,12,C.muted,true);y=y+40
  for _,other in ipairs(Players:GetPlayers())do
   local row=make("Frame",content,{Position=UDim2.fromOffset(27,y),Size=UDim2.fromOffset(597,72),BackgroundColor3=C.panel});round(row,15);line(row)
   local a=make("ImageLabel",row,{Position=UDim2.fromOffset(15,12),Size=UDim2.fromOffset(48,48),
    Image="rbxthumb://type=AvatarHeadShot&id="..other.UserId.."&w=150&h=150",BackgroundColor3=C.hover});round(a,25)
   txt(row,other.DisplayName,75,12,290,24,15,C.white,true)
   txt(row,"@"..other.Name,75,37,290,19,12,C.muted)
   local r=txt(row,"ROLE UNKNOWN",382,15,113,21,11,C.muted,true);r.TextXAlignment=Enum.TextXAlignment.Center
   action(row,537,20,"eye");y=y+84
  end
 end
 content.CanvasSize=UDim2.fromOffset(0,y+20)
end
navRender();renderPage()
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
 local q=string.lower(searchBox.Text)
 if q=="" then return end
 for _,g in ipairs(navGroups)do for _,item in ipairs(g[2])do
  if string.find(string.lower(item[1]),q,1,true) then
   selected=item[1];expanded[g[1]]=true;navRender();renderPage();return
  end
 end end
end)
local minimized=false
local function headButton(x,name,fn)
 local b=button(header,x,22,30,30,C.bg);ico(b,name,5,5,20,C.muted);b.MouseButton1Click:Connect(fn)
end
headButton(774,"minus",function()
 minimized=not minimized;window.Size=UDim2.fromOffset(900,minimized and 76 or 510)
end)
headButton(812,"maximize",function()
 minimized=false;window.Size=UDim2.fromOffset(900,510)
end)
headButton(851,"x",function()gui:Destroy()end)
local dragging=false;local startInput,startPos
header.InputBegan:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  dragging=true;startInput=input.Position;startPos=window.Position
 end
end)
UIS.InputChanged:Connect(function(input)
 if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
  local delta=(input.Position-startInput)/scale.Scale
  window.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
 end
end)
UIS.InputEnded:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
end)
gui.Destroying:Connect(function()
 if perf then perf:Disconnect() end
 if cameraConnection then cameraConnection:Disconnect() end
end)
print("[Blizzard V7] Standalone Star Hub-inspired visual preview ready. Icon pack:",iconPack and "loaded" or "unavailable")
