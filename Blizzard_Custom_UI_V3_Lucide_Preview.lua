-- Blizzard MM2 | Custom UI V3 | standalone visual preview
-- WindUI / Lucide-inspired line icons. No gameplay features are executed.
-- Tabs, groups, toggles, sliders and search are UI previews only.
local Players = game:GetService('Players')
local UIS = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local player = Players.LocalPlayer
local guiParent = player:WaitForChild('PlayerGui')
local old = guiParent:FindFirstChild('BlizzardCustomV3')
if old then old:Destroy() end
local C = {
 bg=Color3.fromRGB(10,10,14), card=Color3.fromRGB(20,20,26), card2=Color3.fromRGB(27,27,34),
 border=Color3.fromRGB(48,48,59), white=Color3.fromRGB(242,242,247), muted=Color3.fromRGB(137,137,151),
 dim=Color3.fromRGB(91,91,106), green=Color3.fromRGB(30,191,106), yellow=Color3.fromRGB(255,195,51),
 blue=Color3.fromRGB(69,181,255), purple=Color3.fromRGB(193,128,250)
}
local function obj(t,p,props)
 local x=Instance.new(t); for k,v in pairs(props or {}) do x[k]=v end; x.Parent=p; return x
end
local function corner(p,r) obj('UICorner',p,{CornerRadius=UDim.new(0,r)}) end
local function stroke(p,c,w) obj('UIStroke',p,{Color=c or C.border,Thickness=w or 1}) end
local function txt(p,s,pos,size,font,color,align)
 return obj('TextLabel',p,{BackgroundTransparency=1,Text=s,Position=pos,Size=size,Font=font or Enum.Font.Gotham,TextSize=15,TextColor3=color or C.white,TextXAlignment=align or Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd})
end
local function panel(p,pos,size,col,r,border)
 local f=obj('Frame',p,{Position=pos,Size=size,BackgroundColor3=col or C.card,BorderSizePixel=0}); corner(f,r or 14); if border then stroke(f) end; return f
end
local function line(p,x1,y1,x2,y2,w,col)
 local dx,dy=x2-x1,y2-y1
 local f=obj('Frame',p,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset((x1+x2)/2,(y1+y2)/2),Size=UDim2.fromOffset(math.sqrt(dx*dx+dy*dy),w or 2),Rotation=math.deg(math.atan2(dy,dx)),BackgroundColor3=col or C.muted,BorderSizePixel=0}); corner(f,w or 2);return f
end
local function circle(p,x,y,d,col,width)
 local f=obj('Frame',p,{Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(d,d),BackgroundTransparency=1,BorderSizePixel=0});corner(f,d/2);stroke(f,col or C.muted,width or 2);return f
end
-- Icons are drawn with Roblox primitives so no missing-glyph squares or remote assets.
-- Icon names follow the Lucide names used by WindUI.
local function icon(p,name,x,y,col)
 local h=obj('Frame',p,{Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(24,24),BackgroundTransparency=1});col=col or C.muted
 local L=function(a,b,c,d)line(h,a,b,c,d,2,col)end
 if name=='house' then L(3,11,12,3);L(12,3,21,11);L(5,10,5,21);L(19,10,19,21);L(5,21,19,21);L(10,21,10,15);L(14,15,14,21)
 elseif name=='settings' then circle(h,7,7,10,col);circle(h,10,10,4,col,1);for i=0,7 do local a=i*math.pi/4;L(12+8*math.cos(a),12+8*math.sin(a),12+11*math.cos(a),12+11*math.sin(a))end
 elseif name=='user-round' then circle(h,8,2,8,col);L(4,21,4,18);L(4,18,8,14);L(8,14,16,14);L(16,14,20,18);L(20,18,20,21)
 elseif name=='eye' then L(2,12,8,7);L(8,7,16,7);L(16,7,22,12);L(22,12,16,17);L(16,17,8,17);L(8,17,2,12);circle(h,9,9,6,col)
 elseif name=='crosshair' or name=='target' then circle(h,3,3,18,col);L(12,0,12,7);L(12,17,12,24);L(0,12,7,12);L(17,12,24,12)
 elseif name=='swords' then L(4,3,19,18);L(19,18,22,21);L(2,21,7,16);L(20,3,5,18);L(5,18,2,21);L(22,21,17,16)
 elseif name=='wind' then L(2,7,16,7);L(2,12,21,12);L(2,17,15,17);circle(h,14,3,7,col,1)
 elseif name=='plane' or name=='send' then L(2,10,22,2);L(22,2,15,22);L(15,22,11,13);L(11,13,2,10);L(11,13,22,2)
 elseif name=='bot' then L(12,2,12,6);L(5,7,19,7);L(19,7,19,20);L(19,20,5,20);L(5,20,5,7);circle(h,7,11,3,col,1);circle(h,14,11,3,col,1);L(9,17,15,17)
 elseif name=='palette' then circle(h,2,2,20,col);circle(h,6,7,2,col,1);circle(h,12,5,2,col,1);circle(h,17,9,2,col,1)
 elseif name=='sliders-horizontal' then for _,yy in ipairs({5,12,19}) do L(2,yy,22,yy) end;circle(h,6,2,6,col);circle(h,15,9,6,col)
 elseif name=='mouse-pointer-click' then L(5,2,7,20);L(7,20,11,15);L(11,15,16,21);L(16,21,19,18);L(19,18,13,12);L(13,12,19,10);L(19,10,5,2)
 elseif name=='footprints' then circle(h,3,3,7,col);circle(h,14,11,7,col);L(5,11,9,18);L(16,3,20,10)
 elseif name=='shield' then L(12,2,21,6);L(21,6,20,15);L(20,15,12,22);L(12,22,4,15);L(4,15,3,6);L(3,6,12,2)
 elseif name=='scan-eye' then L(2,8,2,2);L(2,2,8,2);L(16,2,22,2);L(22,2,22,8);L(2,16,2,22);L(2,22,8,22);L(16,22,22,22);L(22,22,22,16);circle(h,8,8,8,col)
 elseif name=='save' then L(4,2,18,2);L(18,2,22,6);L(22,6,22,22);L(22,22,3,22);L(3,22,3,2);L(8,2,8,10);L(8,10,17,10);L(7,22,7,15);L(7,15,18,15)
 else circle(h,5,5,14,col);L(12,8,12,16);L(8,12,16,12) end
 return h
end
local screen=obj('ScreenGui',guiParent,{Name='BlizzardCustomV3',ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=150})
local shade=obj('Frame',screen,{BackgroundTransparency=1,Size=UDim2.fromScale(1,1)})
local main=panel(shade,UDim2.fromScale(.5,.51),UDim2.fromOffset(1170,610),C.bg,22,true)
main.AnchorPoint=Vector2.new(.5,.5);main.ClipsDescendants=true
local scale=obj('UIScale',main,{Scale=1})
local function resize()
 local v=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
 scale.Scale=math.min((v.X-30)/1170,(v.Y-75)/610,1)
end
resize();if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(resize)end
local header=obj('Frame',main,{Size=UDim2.new(1,0,0,89),BackgroundTransparency=1})
obj('Frame',main,{Position=UDim2.fromOffset(0,89),Size=UDim2.new(1,0,0,1),BackgroundColor3=C.border,BorderSizePixel=0})
local logo=panel(header,UDim2.fromOffset(24,19),UDim2.fromOffset(45,45),C.card2,13)
icon(logo,'bot',10,10,C.white)
txt(header,'Blizzard MM2',UDim2.fromOffset(82,18),UDim2.fromOffset(188,27),Enum.Font.GothamBold,C.white).TextSize=22
local ver=panel(header,UDim2.fromOffset(263,24),UDim2.fromOffset(75,25),C.card,13)
txt(ver,'v1.85.4',UDim2.fromOffset(8,2),UDim2.fromOffset(63,20),Enum.Font.GothamBold,C.muted).TextSize=12
obj('Frame',header,{Position=UDim2.fromOffset(84,58),Size=UDim2.fromOffset(7,7),BackgroundColor3=C.green,BorderSizePixel=0});corner(header:FindFirstChildWhichIsA('Frame',false) or logo,4)
txt(header,'CUSTOM UI  ·  VISUAL PREVIEW',UDim2.fromOffset(99,52),UDim2.fromOffset(265,20),Enum.Font.Gotham,C.muted).TextSize=11
local search=panel(header,UDim2.fromOffset(427,17),UDim2.fromOffset(430,54),C.card,13,true)
icon(search,'scan-eye',13,15,C.muted)
local searchBox=obj('TextBox',search,{Position=UDim2.fromOffset(48,0),Size=UDim2.new(1,-57,1,0),BackgroundTransparency=1,ClearTextOnFocus=false,PlaceholderText='Search settings',PlaceholderColor3=C.dim,Text='',TextSize=17,TextColor3=C.white,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left})
local function topButton(s,x,callback)
 local b=obj('TextButton',header,{Position=UDim2.fromOffset(x,24),Size=UDim2.fromOffset(39,39),BackgroundTransparency=1,Text=s,TextSize=23,TextColor3=C.muted,Font=Enum.Font.Gotham});b.MouseButton1Click:Connect(callback);return b
end
local minimized=false
topButton('−',1018,function() minimized=not minimized;main.Size=minimized and UDim2.fromOffset(1170,90) or UDim2.fromOffset(1170,610) end)
topButton('□',1061,function() scale.Scale=math.min(scale.Scale+.06,1) end)
topButton('×',1104,function()screen:Destroy()end)
local sidebar=obj('Frame',main,{Position=UDim2.fromOffset(0,90),Size=UDim2.fromOffset(295,520),BackgroundTransparency=1})
obj('Frame',main,{Position=UDim2.fromOffset(295,90),Size=UDim2.fromOffset(1,520),BackgroundColor3=C.border,BorderSizePixel=0})
local sideScroll=obj('ScrollingFrame',sidebar,{Position=UDim2.fromOffset(12,12),Size=UDim2.new(1,-24,1,-94),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=C.dim,CanvasSize=UDim2.fromOffset(0,0)})
local sl=obj('UIListLayout',sideScroll,{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder})
local footer=panel(sidebar,UDim2.fromOffset(14,443),UDim2.fromOffset(267,64),C.card,13)
local av=obj('ImageLabel',footer,{Position=UDim2.fromOffset(9,8),Size=UDim2.fromOffset(47,47),BackgroundColor3=C.card2,BorderSizePixel=0});corner(av,24)
local ok,thumb=pcall(function()return Players:GetUserThumbnailAsync(player.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100)end)
if ok then av.Image=thumb end
txt(footer,player.DisplayName,UDim2.fromOffset(66,10),UDim2.fromOffset(190,23),Enum.Font.GothamBold,C.white).TextSize=14
txt(footer,'@'..player.Name,UDim2.fromOffset(66,34),UDim2.fromOffset(190,18),Enum.Font.Gotham,C.muted).TextSize=12
local content=obj('Frame',main,{Position=UDim2.fromOffset(296,90),Size=UDim2.fromOffset(874,520),BackgroundTransparency=1})
local headIcon=panel(content,UDim2.fromOffset(26,23),UDim2.fromOffset(52,52),C.card2,13)
local over=txt(content,'OVERVIEW',UDim2.fromOffset(96,23),UDim2.fromOffset(380,18),Enum.Font.GothamBold,C.dim);over.TextSize=12
local heading=txt(content,'Home',UDim2.fromOffset(96,44),UDim2.fromOffset(680,39),Enum.Font.GothamBold,C.white);heading.TextSize=27
local body=obj('ScrollingFrame',content,{Position=UDim2.fromOffset(26,98),Size=UDim2.new(1,-52,1,-107),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.dim,CanvasSize=UDim2.fromOffset(0,0)})
local bodyList=obj('UIListLayout',body,{Padding=UDim.new(0,13),SortOrder=Enum.SortOrder.LayoutOrder})
local pages={
 {'Home','OVERVIEW','house'},
 {'On-Screen Buttons','SETTINGS','mouse-pointer-click'}, {'General','SETTINGS','sliders-horizontal'},
 {'Movement','PLAYER','footprints'}, {'Players','PLAYER','user-round'},
 {'Aim','COMBAT','crosshair'}, {'Sheriff & Murderer','COMBAT','swords'}, {'Fling','COMBAT','wind'},
 {'ESP','VISUALS','eye'}, {'Role ESP','VISUALS','scan-eye'},
 {'Gun','SKIN CHANGER','crosshair'}, {'Knife','SKIN CHANGER','swords'},
 {'Auto Farm','FARMING','bot'}, {'Teleport','MISC','send'}, {'Misc','MISC','settings'}
}
local nav={};local current='Home'
local function addSection(name)
 local f=obj('Frame',sideScroll,{Size=UDim2.new(1,-6,0,32),BackgroundTransparency=1})
 txt(f,name,UDim2.fromOffset(13,8),UDim2.new(1,-20,0,18),Enum.Font.GothamBold,C.dim).TextSize=11
end
local function addNav(page,group,ic)
 local b=obj('TextButton',sideScroll,{Size=UDim2.new(1,-6,0,48),BackgroundColor3=C.bg,BackgroundTransparency=1,BorderSizePixel=0,Text=''})
 corner(b,12);icon(b,ic,17,12,C.muted)
 local label=txt(b,page,UDim2.fromOffset(59,8),UDim2.new(1,-69,0,32),Enum.Font.Gotham,C.muted);label.TextSize=16
 nav[page]={button=b,label=label,icon=ic}
 b.MouseButton1Click:Connect(function()current=page; if _G.BlizzardV3Render then _G.BlizzardV3Render() end end)
end
local prev=''
for _,data in ipairs(pages) do
 if data[2]~=prev and data[1]~='Home' then addSection(data[2]);prev=data[2] end
 addNav(unpack(data))
end
sl:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()sideScroll.CanvasSize=UDim2.fromOffset(0,sl.AbsoluteContentSize.Y+10)end)
local function clearBody()for _,x in ipairs(body:GetChildren()) do if x~=bodyList then x:Destroy() end end end
local function makeCard(height)
 return panel(body,UDim2.new(),UDim2.new(1,-8,0,height),C.card,18,true)
end
local function addRow(card,label,y,kind,value)
 txt(card,label,UDim2.fromOffset(22,y),UDim2.new(1,-150,0,35),Enum.Font.Gotham,C.white).TextSize=15
 if kind=='toggle' then
  local b=panel(card,UDim2.new(1,-89,0,y+3),UDim2.fromOffset(65,30),C.card2,12)
  local knob=panel(b,UDim2.fromOffset(5,5),UDim2.fromOffset(20,20),C.muted,7)
  local on=false
  local click=obj('TextButton',b,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text=''})
  click.MouseButton1Click:Connect(function()on=not on;b.BackgroundColor3=on and C.green or C.card2;knob.Position=UDim2.fromOffset(on and 40 or 5,5);knob.BackgroundColor3=on and C.white or C.muted end)
 elseif kind=='button' then
  local b=panel(card,UDim2.new(1,-68,0,y-1),UDim2.fromOffset(43,36),C.card2,11)
  icon(b,value or 'send',10,6,C.white)
 elseif kind=='slider' then
  local val=txt(card,tostring(value or 50),UDim2.new(1,-82,0,y),UDim2.fromOffset(60,30),Enum.Font.GothamBold,C.white,Enum.TextXAlignment.Right)
  local bar=panel(card,UDim2.fromOffset(22,y+48),UDim2.new(1,-45,0,5),C.border,3)
  local fill=panel(bar,UDim2.fromScale(.5,0),UDim2.fromScale(.5,1),C.white,3)
  local dot=panel(bar,UDim2.fromScale(.5,.5),UDim2.fromOffset(16,16),C.white,8);dot.AnchorPoint=Vector2.new(.5,.5)
  local dragging=false
  local function update(input)
   local t=math.clamp((input.Position.X-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
   fill.Size=UDim2.fromScale(t,1);dot.Position=UDim2.fromScale(t,.5);val.Text=tostring(math.floor(t*100))
  end
  bar.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true;update(i)end end)
  UIS.InputChanged:Connect(function(i)if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) and bar.Parent then update(i)end end)
  UIS.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
 end
end
local definitions={
 ['On-Screen Buttons']={{'Layout',{'Lock Buttons','toggle'},{'Button Size','slider',65},{'Reset Positions','button','send'}},{'Sheriff',{'Shoot Murderer','toggle'},{'Rage Shoot','toggle'}},{'Murderer',{'Throw Knife','toggle'},{'Kill All','toggle'}},{'Player',{'Bomb Boost','toggle'},{'Noclip','toggle'},{'Fly','toggle'},{'Infinite Jump','toggle'}}},
 General={{'Appearance',{'Theme','button','palette'}},{'Performance',{'Lite Mode (phones)','toggle'},{'FPS Boost','toggle'},{'FPS Cap','slider',0}},{'Server',{'Anti-AFK','toggle'},{'Hop Server','button','send'}},{'Config',{'Auto Save','toggle'},{'Save Now','button','save'}}},
 Movement={{'Movement',{'Fly','toggle'},{'Walk Through Walls','toggle'},{'Infinite Jump','toggle'},{'Wall Jump','toggle'},{'Walk Speed','slider',50},{'Fly Speed','slider',50}}},
 Players={{'Alerts',{'Round Start Alert','toggle'}},{'Player List',{'Role Badges','toggle'},{'Distance Display','toggle'}}},
 Aim={{'Triggerbot',{'Triggerbot','toggle'},{'Reaction Delay','slider',5}},{'Aim Assist',{'Aim Lock','toggle'},{'Aim Prediction','toggle'},{'Prediction Strength','slider',50}}},
 ['Sheriff & Murderer']={{'Sheriff',{'Shoot Murderer','button','crosshair'},{'Auto Grab Gun','toggle'}},{'Murderer',{'Throw Knife','button','swords'},{'Rage Throw','toggle'},{'Knife Aura','toggle'}}},
 Fling={{'Fling',{'Fling Murderer','button','wind'},{'Fling Sheriff / Hero','button','wind'},{'Anti Fling','toggle'},{'Fling Notify','toggle'}}},
 ESP={{'World Visuals',{'Match ESP','toggle'},{'Gun ESP','toggle'},{'Tracers','toggle'},{'Nametags','toggle'},{'Distance ESP','toggle'}}},
 ['Role ESP']={{'Roles',{'Role ESP','toggle'},{'Role Labels','toggle'}}},
 Gun={{'Gun Skins',{'Select Gun Skin','button','palette'},{'Enable Skin Changer','toggle'}}},
 Knife={{'Knife Skins',{'Select Knife Skin','button','palette'},{'Enable Skin Changer','toggle'}}},
 ['Auto Farm']={{'Coin Farm',{'Auto Farm Coins','toggle'},{'Farm Underground','toggle'},{'Farm Speed','slider',25}},{'When Bag Is Full',{'Auto Return','toggle'},{'Rejoin Server','button','send'}}},
 Teleport={{'Teleport',{'Teleport to Map','button','send'},{'Teleport to Lobby','button','send'}}},
 Misc={{'Utilities',{'Anti-AFK','toggle'},{'Server Hop','button','send'},{'Notifications','toggle'}}}
}
local function home()
 local p=makeCard(185)
 local grad=obj('UIGradient',p,{Rotation=0,Color=ColorSequence.new(Color3.fromRGB(15,44,31),C.card)})
 local stripe=obj('Frame',p,{Size=UDim2.fromOffset(4,185),BackgroundColor3=C.green,BorderSizePixel=0})
 local face=obj('ImageLabel',p,{Position=UDim2.fromOffset(28,28),Size=UDim2.fromOffset(82,82),Image=ok and thumb or '',BackgroundColor3=C.card2,BorderSizePixel=0});corner(face,41);stroke(face,C.green,3)
 txt(p,player.DisplayName,UDim2.fromOffset(131,36),UDim2.fromOffset(420,30),Enum.Font.GothamBold,C.white).TextSize=23
 txt(p,'@'..player.Name,UDim2.fromOffset(131,70),UDim2.fromOffset(420,22),Enum.Font.Gotham,C.muted).TextSize=15
 local badge=panel(p,UDim2.new(1,-151,0,43),UDim2.fromOffset(124,35),C.green,18)
 txt(badge,'INNOCENT',UDim2.fromOffset(7,7),UDim2.fromOffset(110,22),Enum.Font.GothamBold,C.white,Enum.TextXAlignment.Center).TextSize=13
 for i,s in ipairs({'VISUAL PREVIEW','DARK MONO','BLIZZARD MM2'}) do
  local chip=panel(p,UDim2.fromOffset(28+(i-1)*184,133),UDim2.fromOffset(174,31),C.card2,16)
  txt(chip,s,UDim2.fromOffset(12,6),UDim2.fromOffset(150,20),Enum.Font.Gotham,C.white).TextSize=11
 end
 local stats=makeCard(116)
 for i,item in ipairs({{'—','COINS',C.yellow},{'—','GEMS',C.blue},{'—','LEVEL',C.purple}}) do
  local x=(i-1)*270
  txt(stats,item[1],UDim2.fromOffset(x+25,22),UDim2.fromOffset(220,36),Enum.Font.GothamBold,C.white,Enum.TextXAlignment.Center).TextSize=26
  txt(stats,item[2],UDim2.fromOffset(x+25,67),UDim2.fromOffset(220,22),Enum.Font.GothamBold,item[3],Enum.TextXAlignment.Center).TextSize=14
  if i<3 then obj('Frame',stats,{Position=UDim2.fromOffset(x+270,26),Size=UDim2.fromOffset(1,65),BackgroundColor3=C.border,BorderSizePixel=0}) end
 end
 local info=makeCard(128)
 txt(info,'BLIZZARD',UDim2.fromOffset(26,24),UDim2.fromOffset(480,35),Enum.Font.GothamBold,C.white).TextSize=24
 txt(info,'Custom UI V3  •  WindUI-style line icons  •  Visual preview only',UDim2.fromOffset(26,66),UDim2.new(1,-52,0,30),Enum.Font.Gotham,C.muted).TextSize=14
end
local function render()
 clearBody()
 for name,entry in pairs(nav) do
  local selected=name==current
  entry.button.BackgroundTransparency=selected and 0 or 1
  entry.button.BackgroundColor3=C.card2
  entry.label.TextColor3=selected and C.white or C.muted
  entry.label.Font=selected and Enum.Font.GothamBold or Enum.Font.Gotham
 end
 over.Text=({Home='OVERVIEW',['On-Screen Buttons']='SETTINGS',General='SETTINGS',Movement='PLAYER',Players='PLAYER',Aim='COMBAT',['Sheriff & Murderer']='COMBAT',Fling='COMBAT',ESP='VISUALS',['Role ESP']='VISUALS',Gun='SKIN CHANGER',Knife='SKIN CHANGER',['Auto Farm']='FARMING',Teleport='MISC',Misc='MISC'})[current] or 'BLIZZARD'
 heading.Text=current
 for _,child in ipairs(headIcon:GetChildren()) do if child:IsA('Frame') then child:Destroy() end end
 icon(headIcon,nav[current].icon,14,14,C.white)
 if current=='Home' then home() else
  for _,group in ipairs(definitions[current] or {}) do
   local total=0;for j=2,#group do total=total+(group[j][2]=='slider' and 93 or 60) end
   local card=makeCard(62+total)
   txt(card,group[1],UDim2.fromOffset(23,15),UDim2.new(1,-80,0,30),Enum.Font.GothamBold,C.white).TextSize=18
   txt(card,tostring(#group-1),UDim2.new(1,-70,0,16),UDim2.fromOffset(35,25),Enum.Font.Gotham,C.dim).TextSize=13
   obj('Frame',card,{Position=UDim2.fromOffset(23,58),Size=UDim2.new(1,-46,0,1),BackgroundColor3=C.border,BorderSizePixel=0})
   local y=71
   for j=2,#group do
    local row=group[j]
    addRow(card,row[1],y,row[2],row[3])
    y=y+(row[2]=='slider' and 93 or 60)
    if j<#group then obj('Frame',card,{Position=UDim2.fromOffset(23,y-9),Size=UDim2.new(1,-46,0,1),BackgroundColor3=C.border,BorderSizePixel=0}) end
   end
  end
 end
 body.CanvasPosition=Vector2.new(0,0)
 body.CanvasSize=UDim2.fromOffset(0,bodyList.AbsoluteContentSize.Y+15)
end
_G.BlizzardV3Render=render
bodyList:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()body.CanvasSize=UDim2.fromOffset(0,bodyList.AbsoluteContentSize.Y+15)end)
searchBox:GetPropertyChangedSignal('Text'):Connect(function()
 local q=searchBox.Text:lower()
 for name,entry in pairs(nav) do entry.button.Visible=q=='' or name:lower():find(q,1,true)~=nil end
end)
render()
-- Drag window from the top header; UI preview remains independent of feature scripts.
local dragging,start,origin=false,nil,nil
header.InputBegan:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=true;start=input.Position;origin=main.Position end
end)
UIS.InputChanged:Connect(function(input)
 if dragging and start and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
  local d=input.Position-start;main.Position=UDim2.new(origin.X.Scale,origin.X.Offset+d.X,origin.Y.Scale,origin.Y.Offset+d.Y)
 end
end)
UIS.InputEnded:Connect(function(input)if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
