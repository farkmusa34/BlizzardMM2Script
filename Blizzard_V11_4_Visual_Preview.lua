-- BLIZZARD V11.4 | STAR-INSPIRED CUSTOM UI | STANDALONE VISUAL PREVIEW
-- No gameplay modules are called. Preview switches and sliders store local UI state only.
local Players=game:GetService('Players')
local UIS=game:GetService('UserInputService')
local RunService=game:GetService('RunService')
local TweenService=game:GetService('TweenService')
local Stats=game:GetService('Stats')
local player=Players.LocalPlayer
local parent=player:WaitForChild('PlayerGui')
for _,name in ipairs({'BlizzardV11','BlizzardV11_1','BlizzardV11_2','BlizzardV11_3','BlizzardV11_4','BlizzardStarPreview'}) do
 local old=parent:FindFirstChild(name)
 if old then old:Destroy() end
end
local C={bg=Color3.fromRGB(10,10,13),sidebar=Color3.fromRGB(12,12,16),panel=Color3.fromRGB(18,18,23),card=Color3.fromRGB(20,20,25),hover=Color3.fromRGB(35,35,42),border=Color3.fromRGB(43,43,51),white=Color3.fromRGB(246,246,249),muted=Color3.fromRGB(135,135,149),green=Color3.fromRGB(17,211,112),yellow=Color3.fromRGB(255,196,65)}
local function new(t,p,props)
 local o=Instance.new(t)
 for k,v in pairs(props or {}) do o[k]=v end
 o.Parent=p
 return o
end
local function corner(p,r) return new('UICorner',p,{CornerRadius=UDim.new(0,r)}) end
local function pill(p) return new('UICorner',p,{CornerRadius=UDim.new(1,0)}) end
local function stroke(p,color,thickness) return new('UIStroke',p,{Color=color or C.border,Thickness=thickness or 1,Transparency=.12}) end
local function text(p,s,x,y,w,h,size,color,bold)
 return new('TextLabel',p,{BackgroundTransparency=1,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),Text=tostring(s),TextColor3=color or C.white,TextSize=size or 14,Font=bold and Enum.Font.GothamBold or Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd})
end
local function btn(p,x,y,w,h,bg)
 local b=new('TextButton',p,{Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundColor3=bg or C.hover,Text='',AutoButtonColor=false,BorderSizePixel=0})
 corner(b,9)
 return b
end
local function tween(o,d,props,style)
 local t=TweenService:Create(o,TweenInfo.new(d,style or Enum.EasingStyle.Quart,Enum.EasingDirection.Out),props)
 t:Play()
 return t
end
-- Optional icon pack; fallback is a simple symbol when unavailable.
local icons
pcall(function()
 local result=loadstring(game:HttpGet('https://raw.githubusercontent.com/Footagesus/Icons/main/lucide/dist/Icons.lua'))()
 if type(result)=='table' then icons=result end
end)
local fallback={['gamepad-2']='✚',house='⌂',search='⌕',footprints='♧',users='♙',crosshair='⊕',sword='⚔',wind='≋',eye='◉',settings='⚙',bomb='◉',plane='➤',bot='▣',palette='◈',navigation='➤',['arrow-up']='↑',['chevron-down']='⌄',['chevron-right']='›',minus='−',maximize='□',x='×',['mouse-pointer-click']='↖'}
local function icon(p,name,x,y,size,color)
 local holder=new('Frame',p,{Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(size,size),BackgroundTransparency=1})
 local d=icons and icons[name]
 local id,off,rect
 if type(d)=='string' then id=d
 elseif type(d)=='table' then
  if type(d[1])=='string' then id=d[1];local m=d[2];if type(m)=='table' then off=m.ImageRectPosition;rect=m.ImageRectSize end
  elseif type(d.Image)=='string' then id=d.Image;off=d.ImageRectPosition or d.RectOffset;rect=d.ImageRectSize or d.RectSize end
 end
 if id then
  local im=new('ImageLabel',holder,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=id,ImageColor3=color or C.white,ScaleType=Enum.ScaleType.Fit})
  if typeof(off)=='Vector2' then im.ImageRectOffset=off end
  if typeof(rect)=='Vector2' then im.ImageRectSize=rect end
 else
  local t=text(holder,fallback[name] or '•',0,0,size,size,math.max(13,size-2),color or C.white,true)
  t.TextXAlignment=Enum.TextXAlignment.Center
 end
 return holder
end
local gui=new('ScreenGui',parent,{Name='BlizzardV11_4',ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=999,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
local DEFAULT=Vector2.new(760,570)
local WIDE=Vector2.new(1000,550)
local expanded=false
local open=true
local window=new('CanvasGroup',gui,{Name='MainWindow',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.52),Size=UDim2.fromOffset(DEFAULT.X,DEFAULT.Y),BackgroundColor3=C.bg,BorderSizePixel=0,GroupTransparency=0,ClipsDescendants=true,ZIndex=1})
corner(window,20);stroke(window,Color3.fromRGB(75,75,84))
local windowScale=new('UIScale',window,{Scale=1})
local body=new('Frame',window,{BackgroundTransparency=1,Size=UDim2.fromScale(1,1)})
local side=new('Frame',body,{BackgroundColor3=C.sidebar,BorderSizePixel=0,Size=UDim2.new(0,232,1,0)})
new('Frame',side,{Position=UDim2.new(1,-1,0,0),Size=UDim2.new(0,1,1,0),BackgroundColor3=C.border,BorderSizePixel=0})
local sideHead=new('Frame',side,{Size=UDim2.new(1,0,0,113),BackgroundTransparency=1})
icon(sideHead,'gamepad-2',17,21,32,C.white)
text(sideHead,'Blizzard',58,16,125,28,19,C.white,true)
local ver=text(sideHead,'V11.4',168,21,53,19,10,C.muted,true)
local fpsDot=new('Frame',sideHead,{Position=UDim2.fromOffset(59,57),Size=UDim2.fromOffset(7,7),BackgroundColor3=C.green});pill(fpsDot)
local fpsText=text(sideHead,'-- fps',72,49,55,23,11,C.muted)
local pingDot=new('Frame',sideHead,{Position=UDim2.fromOffset(136,57),Size=UDim2.fromOffset(7,7),BackgroundColor3=C.green});pill(pingDot)
local pingText=text(sideHead,'-- ms',149,49,66,23,11,C.muted)
local searchFrame=new('Frame',sideHead,{Position=UDim2.fromOffset(14,80),Size=UDim2.fromOffset(204,36),BackgroundColor3=C.panel});corner(searchFrame,10);stroke(searchFrame)
icon(searchFrame,'search',10,10,17,C.muted)
local searchBox=new('TextBox',searchFrame,{Position=UDim2.fromOffset(35,2),Size=UDim2.fromOffset(160,32),BackgroundTransparency=1,Text='',PlaceholderText='Search settings',PlaceholderColor3=C.muted,TextColor3=C.white,TextSize=12,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false})
local sideScroll=new('ScrollingFrame',side,{Position=UDim2.fromOffset(0,132),Size=UDim2.new(1,0,1,-205),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=C.border,CanvasSize=UDim2.fromOffset(0,0),ScrollingEnabled=true,Active=true,ScrollingDirection=Enum.ScrollingDirection.Y,ElasticBehavior=Enum.ElasticBehavior.WhenScrollable})
local footer=new('Frame',side,{AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,12,1,-12),Size=UDim2.fromOffset(208,56),BackgroundColor3=C.panel});corner(footer,12)
local avatar='rbxthumb://type=AvatarHeadShot&id='..player.UserId..'&w=150&h=150'
local av=new('ImageLabel',footer,{Position=UDim2.fromOffset(8,8),Size=UDim2.fromOffset(40,40),BackgroundColor3=C.hover,Image=avatar});pill(av)
text(footer,player.DisplayName,55,7,143,22,12,C.white,true)
text(footer,'@'..player.Name,55,28,143,18,10,C.muted)
local main=new('Frame',body,{Position=UDim2.fromOffset(232,0),Size=UDim2.new(1,-232,1,0),BackgroundTransparency=1})
local top=new('Frame',main,{Size=UDim2.new(1,0,0,91),BackgroundTransparency=1})
new('Frame',top,{Position=UDim2.new(0,0,1,-1),Size=UDim2.new(1,0,0,1),BackgroundColor3=C.border,BorderSizePixel=0})
local headingIcon=new('Frame',top,{Position=UDim2.fromOffset(24,22),Size=UDim2.fromOffset(43,43),BackgroundColor3=C.white});corner(headingIcon,12)
local headingImage=icon(headingIcon,'house',10,10,23,C.bg)
local categoryText=text(top,'OVERVIEW',81,18,210,18,10,C.muted,true)
local headingText=text(top,'Home',81,37,285,32,21,C.white,true)
local controls=new('Frame',top,{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-13,0,20),Size=UDim2.fromOffset(117,36),BackgroundTransparency=1})
local controlButtons={}
for i,d in ipairs({{'minus','Minimize'},{'maximize','Expand'},{'x','Close'}}) do
 local b=btn(controls,(i-1)*40,0,35,35,C.panel);corner(b,13)
 icon(b,d[1],9,9,17,C.muted)
 controlButtons[i]=b
end
local content=new('ScrollingFrame',main,{Position=UDim2.fromOffset(0,91),Size=UDim2.new(1,0,1,-91),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.border,CanvasSize=UDim2.fromOffset(0,0),ScrollingDirection=Enum.ScrollingDirection.Y,ScrollingEnabled=true,Active=true,ElasticBehavior=Enum.ElasticBehavior.WhenScrollable,AutomaticCanvasSize=Enum.AutomaticSize.Y})
local padding=new('UIPadding',content,{PaddingLeft=UDim.new(0,20),PaddingRight=UDim.new(0,20),PaddingTop=UDim.new(0,16),PaddingBottom=UDim.new(0,20)})
local layout=new('UIListLayout',content,{Padding=UDim.new(0,13),SortOrder=Enum.SortOrder.LayoutOrder})
-- UIListLayout drives scrolling; explicit LayoutOrder prevents overlap and stale bounds.
local function updateCanvas()
 content.CanvasSize=UDim2.fromOffset(0,math.ceil(layout.AbsoluteContentSize.Y+padding.PaddingTop.Offset+padding.PaddingBottom.Offset+24))
end
layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(updateCanvas)
content:GetPropertyChangedSignal('AbsoluteSize'):Connect(updateCanvas)
local groups={
 {'HOME',{{'Home','house'}}},
 {'SETTINGS',{{'On-Screen Buttons','mouse-pointer-click'},{'General','settings'}}},
 {'PLAYER',{{'Movement','footprints'},{'Players','users'}}},
 {'COMBAT',{{'Aim','crosshair'},{'Sheriff & Murderer','sword'},{'Fling','wind'}}},
 {'VISUALS',{{'ESP','eye'},{'Effects','eye'},{'Role ESP','eye'}}},
 {'SKIN CHANGER',{{'Gun','palette'},{'Knife','sword'}}},
 {'FARMING',{{'Auto Farm','bot'}}},
 {'MISC',{{'Teleport','navigation'},{'Misc','settings'}}}
}
local pages={
 ['On-Screen Buttons']={'SETTINGS','mouse-pointer-click',{{'Layout','settings',{{'Lock Buttons','toggle'},{'Button Size','slider',50,150,100},{'Reset Size / Positions','action'}}},{'Sheriff','crosshair',{{'Shoot Murderer Button','toggle'},{'Rage Shoot Button','toggle'}}},{'Murderer','sword',{{'Throw Knife Button','toggle'},{'Kill All Button','toggle'}}},{'Fling','wind',{{'Fling Murderer Button','toggle'},{'Fling Sheriff / Hero Button','toggle'}}}}},
 ['General']={'SETTINGS','settings',{{'Appearance','palette',{{'Background Thumbnail','toggle'}}},{'Performance','settings',{{'Lite Mode','toggle'},{'FPS Boost','toggle'}}},{'Config','settings',{{'Auto Save','toggle'},{'Save Now','action'},{'Load Saved','action'}}}}},
 ['Movement']={'PLAYER','footprints',{{'Movement','footprints',{{'Walk Speed','slider',16,100,16},{'Jump Power','slider',50,150,50},{'Walk Through Walls with Freefall Protection','toggle'}}},{'Fly','plane',{{'Fly','toggle'},{'Fly Speed','slider',10,100,10}}},{'Jumping','arrow-up',{{'Infinite Jump','toggle'},{'Wall Jump','toggle'}}},{'Bomb Boost','bomb',{{'Bomb Boost Button','action'},{'Boost Power','slider',30,250,120}}}}},
 ['Players']={'PLAYER','users',{{'Alerts','settings',{{'Round Start Alert','toggle'}}}}},
 ['Aim']={'COMBAT','crosshair',{{'Aim','crosshair',{{'TriggerBot','toggle'},{'Aim Lock','toggle'},{'Shoot Murderer (Legit)','action'}}},{'Accuracy','crosshair',{{'Aim Prediction','toggle'},{'Prediction Strength','slider',30,250,100},{'Wall Throw','toggle'}}}}},
 ['Sheriff & Murderer']={'COMBAT','sword',{{'Sheriff','crosshair',{{'Shoot Murderer','action'},{'Rage Shoot','toggle'}}},{'Murderer','sword',{{'Legit Throw','toggle'},{'Auto Throw Knife (RAGE)','toggle'},{'Throw Aimbot Button','action'},{'Kill All','action'}}}}},
 ['Fling']={'COMBAT','wind',{{'Fling','wind',{{'Fling Murderer Button','toggle'},{'Fling Sheriff / Hero Button','toggle'},{'Anti Fling','toggle'},{'Fling Notify','toggle'}}}}},
 ['ESP']={'VISUALS','eye',{{'Player ESP','eye',{{'Match ESP','toggle'},{'Gun ESP','toggle'},{'Tracers','toggle'},{'Nametags','toggle'},{'Distance ESP','toggle'}}}}},
 ['Effects']={'VISUALS','eye',{{'Visual Effects','eye',{{'Tracers','toggle'},{'Tracer Thickness','slider',1,10,3},{'Glow','toggle'}}}}},
 ['Role ESP']={'VISUALS','eye',{{'Role Display','eye',{{'Role ESP','toggle'},{'Show Role Labels','toggle'},{'Show Distance','toggle'}}}}},
 ['Gun']={'SKIN CHANGER','palette',{{'Gun Skins','palette',{{'Enable Gun Skin Changer','toggle'},{'Select Gun Skin','action'}}}}},
 ['Knife']={'SKIN CHANGER','sword',{{'Knife Skins','palette',{{'Enable Knife Skin Changer','toggle'},{'Select Knife Skin','action'}}}}},
 ['Auto Farm']={'FARMING','bot',{{'Coin Farm','bot',{{'Auto Farm Coins','toggle'},{'Farm Underground','toggle'},{'Farm Speed','slider',1,25,25}}},{'When The Bag Is Full','bot',{{'Fling Murderer','toggle'},{'Shoot Murderer','toggle'},{'Kill All','toggle'},{'Reset Character','toggle'}}}}},
 ['Teleport']={'MISC','navigation',{{'Teleport','navigation',{{'Teleport to Map','action'},{'Teleport to Lobby','action'}}}}},
 ['Misc']={'MISC','settings',{{'Miscellaneous','settings',{{'Anti AFK','toggle'},{'Hop Server','action'},{'Notifications','toggle'}}}}}
}
local selected='Home'
local expandedGroups={}
local collapsed={}
local state={}
local navRender,render
local nextLayoutOrder=0
for _,g in ipairs(groups) do expandedGroups[g[1]]=true end
local function clearChildren(frame)
 for _,child in ipairs(frame:GetChildren()) do
  if not child:IsA('UIListLayout') and not child:IsA('UIPadding') then child:Destroy() end
 end
end
local function section(title,ic,rows)
 local key=selected..'/'..title
 local isCollapsed=collapsed[key] or false
 nextLayoutOrder=nextLayoutOrder+1
 local box=new('Frame',content,{LayoutOrder=nextLayoutOrder,Size=UDim2.new(1,0,0,57),BackgroundColor3=C.card,BorderSizePixel=0,AutomaticSize=Enum.AutomaticSize.None})
 corner(box,16);stroke(box,C.border)
 local h=btn(box,0,0,100,56,C.card);h.Size=UDim2.new(1,0,0,56);h.BackgroundTransparency=1
 local square=new('Frame',h,{Position=UDim2.fromOffset(15,12),Size=UDim2.fromOffset(33,33),BackgroundColor3=C.white});corner(square,9)
 icon(square,ic,8,8,17,C.bg)
 text(h,title,59,11,240,34,14,C.white,true)
 local badge=text(h,tostring(#rows),0,17,24,22,11,C.muted,true)
 badge.AnchorPoint=Vector2.new(1,0);badge.Position=UDim2.new(1,-48,0,17);badge.TextXAlignment=Enum.TextXAlignment.Center
 local arrow=icon(h,isCollapsed and 'chevron-right' or 'chevron-down',0,20,17,C.muted)
 arrow.AnchorPoint=Vector2.new(1,0);arrow.Position=UDim2.new(1,-17,0,20)
 h.MouseButton1Click:Connect(function()collapsed[key]=not collapsed[key];render()end)
 if isCollapsed then return end
 local y=57
 for _,r in ipairs(rows) do
  local kind=r[2]
  local height=kind=='slider' and 77 or 49
  new('Frame',box,{Position=UDim2.fromOffset(15,y),Size=UDim2.new(1,-30,0,1),BackgroundColor3=C.border,BorderSizePixel=0})
  local label=text(box,r[1],18,y+6,310,35,12,C.white)
  label.Size=UDim2.new(1,-114,0,35)
  if kind=='toggle' then
   local on=state[r[1]]==true
   local sw=btn(box,0,y+12,54,28,on and C.white or Color3.fromRGB(48,48,57))
   for _,child in ipairs(sw:GetChildren()) do if child:IsA('UICorner') then child:Destroy() end end
   pill(sw)
   sw.AnchorPoint=Vector2.new(1,0);sw.Position=UDim2.new(1,-17,0,y+12)
   local knob=new('Frame',sw,{Position=UDim2.fromOffset(on and 29 or 4,4),Size=UDim2.fromOffset(20,20),BackgroundColor3=on and C.bg or C.muted});pill(knob)
   sw.MouseButton1Click:Connect(function()
    on=not on;state[r[1]]=on
    tween(sw,.18,{BackgroundColor3=on and C.white or Color3.fromRGB(48,48,57)})
    tween(knob,.18,{Position=UDim2.fromOffset(on and 29 or 4,4),BackgroundColor3=on and C.bg or C.muted})
   end)
  elseif kind=='action' then
   local a=btn(box,0,y+8,36,32,C.hover);a.AnchorPoint=Vector2.new(1,0);a.Position=UDim2.new(1,-18,0,y+8)
   icon(a,'chevron-right',10,8,17,C.white)
   a.MouseButton1Click:Connect(function()tween(a,.12,{BackgroundColor3=C.border});task.delay(.16,function()if a.Parent then tween(a,.2,{BackgroundColor3=C.hover})end end)end)
  elseif kind=='slider' then
   local low,high,initial=r[3],r[4],r[5]
   local value=state[r[1]] or initial
   local val=text(box,tostring(value),0,y+5,55,32,12,C.white,true)
   val.AnchorPoint=Vector2.new(1,0);val.Position=UDim2.new(1,-18,0,y+5);val.TextXAlignment=Enum.TextXAlignment.Right
   local track=btn(box,18,y+57,100,5,C.hover);track.Size=UDim2.new(1,-36,0,5);pill(track)
   local fraction=(value-low)/(high-low)
   local fill=new('Frame',track,{Size=UDim2.fromScale(fraction,1),BackgroundColor3=C.white});pill(fill)
   local thumb=new('Frame',track,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(fraction,.5),Size=UDim2.fromOffset(15,15),BackgroundColor3=C.white});pill(thumb)
   local activeInput
   local function update(input)
    local width=math.max(track.AbsoluteSize.X,1)
    local f=math.clamp((input.Position.X-track.AbsolutePosition.X)/width,0,1)
    local v=math.floor(low+(high-low)*f+.5)
    state[r[1]]=v;val.Text=tostring(v)
    fill.Size=UDim2.fromScale(f,1);thumb.Position=UDim2.fromScale(f,.5)
   end
   track.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then activeInput=input;update(input)end
   end)
   local changed,ended
   changed=UIS.InputChanged:Connect(function(input)
    if not track.Parent then changed:Disconnect();if ended then ended:Disconnect()end;return end
    if activeInput and (input==activeInput or (activeInput.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement)) then update(input)end
   end)
   ended=UIS.InputEnded:Connect(function(input)
    if activeInput and (input==activeInput or (activeInput.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseButton1)) then activeInput=nil end
   end)
  end
  y=y+height
 end
 box.Size=UDim2.new(1,0,0,y+7)
end
local function home()
 nextLayoutOrder=nextLayoutOrder+1
 local card=new('Frame',content,{LayoutOrder=nextLayoutOrder,Size=UDim2.new(1,0,0,115),BackgroundColor3=C.card});corner(card,16);stroke(card)
 local a=new('ImageLabel',card,{Position=UDim2.fromOffset(16,18),Size=UDim2.fromOffset(57,57),Image=avatar,BackgroundColor3=C.hover});pill(a)
 local title=text(card,player.DisplayName,86,17,265,30,17,C.white,true)
 text(card,'@'..player.Name,86,46,265,24,12,C.muted)
 text(card,'VISUAL PREVIEW • NO GAMEPLAY CONNECTED',17,86,420,20,10,C.green,true)
 nextLayoutOrder=nextLayoutOrder+1
 local summary=new('Frame',content,{LayoutOrder=nextLayoutOrder,Size=UDim2.new(1,0,0,87),BackgroundColor3=C.card});corner(summary,16);stroke(summary)
 for i,d in ipairs({{'—','COINS'},{'—','GEMS'},{'—','LEVEL'}}) do
  local x=(i-1)/3
  local cell=new('Frame',summary,{Position=UDim2.fromScale(x,0),Size=UDim2.fromScale(1/3,1),BackgroundTransparency=1})
  local n=text(cell,d[1],0,11,100,34,22,C.white,true);n.Size=UDim2.new(1,0,0,34);n.TextXAlignment=Enum.TextXAlignment.Center
  local l=text(cell,d[2],0,52,100,20,10,C.muted,true);l.Size=UDim2.new(1,0,0,20);l.TextXAlignment=Enum.TextXAlignment.Center
 end
 section('Quick Actions','crosshair',{{'Shoot Murderer','action'},{'Fling Murderer','action'},{'Kill All','action'},{'Hop Server','action'}})
end
function render()
 clearChildren(content);nextLayoutOrder=0;content.CanvasPosition=Vector2.zero
 local page=pages[selected]
 local cat,ic=page and page[1] or 'OVERVIEW',page and page[2] or 'house'
 categoryText.Text=cat;headingText.Text=selected
 headingImage:Destroy();headingImage=icon(headingIcon,ic,10,10,23,C.bg)
 if selected=='Home' then home() else
  for _,s in ipairs(page[3]) do section(s[1],s[2],s[3]) end
  if selected=='Players' then
   for _,other in ipairs(Players:GetPlayers()) do
    nextLayoutOrder=nextLayoutOrder+1
    local r=new('Frame',content,{LayoutOrder=nextLayoutOrder,Size=UDim2.new(1,0,0,62),BackgroundColor3=C.card});corner(r,12)
    local a=new('ImageLabel',r,{Position=UDim2.fromOffset(10,9),Size=UDim2.fromOffset(43,43),Image='rbxthumb://type=AvatarHeadShot&id='..other.UserId..'&w=150&h=150',BackgroundColor3=C.hover});pill(a)
    text(r,other.DisplayName,64,7,230,24,13,C.white,true)
    text(r,'@'..other.Name..' · ROLE UNKNOWN',64,31,260,20,10,C.muted)
   end
  end
 end
 task.defer(updateCanvas)
end
function navRender()
 sideScroll:ClearAllChildren()
 local y=5
 for _,g in ipairs(groups) do
  local groupName,items=g[1],g[2]
  if groupName~='HOME' then
   y=y+7
   local head=btn(sideScroll,12,y,208,28,C.sidebar)
   text(head,groupName,27,3,153,22,10,C.muted,true)
   icon(head,expandedGroups[groupName] and 'chevron-down' or 'chevron-right',184,6,16,C.muted)
   head.MouseButton1Click:Connect(function()expandedGroups[groupName]=not expandedGroups[groupName];navRender()end)
   y=y+32
  end
  if groupName=='HOME' or expandedGroups[groupName] then
   for _,item in ipairs(items) do
    local name,ic=item[1],item[2]
    local active=name==selected
    local b=btn(sideScroll,12,y,208,39,active and C.white or C.sidebar);corner(b,10)
    icon(b,ic,11,10,19,active and C.bg or C.muted)
    text(b,name,40,5,160,29,14,active and C.bg or C.muted,active)
    b.MouseButton1Click:Connect(function()selected=name;navRender();render()end)
    y=y+43
   end
  end
 end
 sideScroll.CanvasSize=UDim2.fromOffset(0,y+40)
end
navRender();render()
updateCanvas()
searchBox:GetPropertyChangedSignal('Text'):Connect(function()
 local q=searchBox.Text:lower()
 if #q<2 then return end
 for _,g in ipairs(groups) do for _,item in ipairs(g[2]) do
  if item[1]:lower():find(q,1,true) then selected=item[1];expandedGroups[g[1]]=true;navRender();render();return end
 end end
end)
-- V11.4: Reference-matched 3:1 floating capsule, proportionally scaled for mobile.
-- Keep the pill above the window, with no extra rectangular corners.
local toolbar=new('TextButton',gui,{Name='FloatingBlizzardPill',AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,43),Size=UDim2.fromOffset(156,52),BackgroundColor3=Color3.fromRGB(24,23,29),Text='',AutoButtonColor=false,BorderSizePixel=0,ZIndex=50})
pill(toolbar)
new('UIStroke',toolbar,{Color=Color3.fromRGB(225,225,232),Thickness=1.15,Transparency=.04,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
local toolIcon=icon(toolbar,'gamepad-2',13,16,21,C.white);toolIcon.ZIndex=51
for _,d in ipairs(toolIcon:GetDescendants()) do if d:IsA('GuiObject') then d.ZIndex=52 end end
local toolName=text(toolbar,'Blizzard',42,8,107,23,15,C.white,true);toolName.ZIndex=51
local tDot1=new('Frame',toolbar,{Position=UDim2.fromOffset(42,36),Size=UDim2.fromOffset(7,7),BackgroundColor3=C.green,ZIndex=51});pill(tDot1)
local tFps=text(toolbar,'-- fps',53,28,39,22,10,C.muted);tFps.ZIndex=51
local tDot2=new('Frame',toolbar,{Position=UDim2.fromOffset(96,36),Size=UDim2.fromOffset(7,7),BackgroundColor3=C.green,ZIndex=51});pill(tDot2)
local tPing=text(toolbar,'-- ms',107,28,43,22,10,C.muted);tPing.ZIndex=51
local pillScale=new('UIScale',toolbar,{Scale=1})
local function viewport()return workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1000,700)end
local function responsive()
 local v=viewport();local size=expanded and WIDE or DEFAULT
 windowScale.Scale=math.clamp(math.min((v.X-22)/size.X,(v.Y-24)/size.Y),.30,1.1)
 pillScale.Scale=math.clamp(math.min((v.X-20)/170,1),.65,1)
end
responsive()
local cameraConnection
local function watchCamera()
 if cameraConnection then cameraConnection:Disconnect()end
 if workspace.CurrentCamera then cameraConnection=workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(responsive)end
 responsive()
end
local cameraWatch=workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(watchCamera)
watchCamera()
local spinTween
local function spin(clockwise)
 if spinTween then spinTween:Cancel()end
 toolIcon.Rotation=0
 -- Full 360 degrees, with direction determined by open/close.
 spinTween=tween(toolIcon,.40,{Rotation=clockwise and 360 or -360},Enum.EasingStyle.Quad)
 spinTween.Completed:Once(function(state)
  if state==Enum.PlaybackState.Completed then toolIcon.Rotation=0 end
 end)
end
local transition
local function setOpen(value)
 if open==value then return end
 open=value
 if transition then transition:Cancel()end
 spin(value)
 if value then
  window.Visible=true
  window.GroupTransparency=1
  local size=expanded and WIDE or DEFAULT
  window.Size=UDim2.fromOffset(size.X*.96,size.Y*.96)
  transition=tween(window,.28,{GroupTransparency=0,Size=UDim2.fromOffset(size.X,size.Y)})
 else
  local size=expanded and WIDE or DEFAULT
  transition=tween(window,.28,{GroupTransparency=1,Size=UDim2.fromOffset(size.X*.96,size.Y*.96)})
  local closing=transition
  closing.Completed:Once(function(state)
   if state==Enum.PlaybackState.Completed and not open then window.Visible=false end
  end)
 end
end
controlButtons[1].MouseButton1Click:Connect(function()setOpen(false)end)
controlButtons[3].MouseButton1Click:Connect(function()setOpen(false)end)
controlButtons[2].MouseButton1Click:Connect(function()
 expanded=not expanded
 local size=expanded and WIDE or DEFAULT
 responsive()
 tween(window,.32,{Size=UDim2.fromOffset(size.X,size.Y)})
end)
-- Pill: tap toggles; drag moves without toggling.
local toolStart,toolOrigin,toolInput,moved
toolbar.InputBegan:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
  toolInput=input;toolStart=input.Position;toolOrigin=toolbar.AbsolutePosition;moved=false
 end
end)
local moveConnection=UIS.InputChanged:Connect(function(input)
 if not toolInput then return end
 if input~=toolInput and not (toolInput.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement) then return end
 local delta=input.Position-toolStart
 if delta.Magnitude>9 then moved=true end
 if moved then
  local v=viewport();local size=toolbar.AbsoluteSize
  local x=math.clamp(toolOrigin.X+delta.X,0,math.max(0,v.X-size.X))
  local y=math.clamp(toolOrigin.Y+delta.Y,0,math.max(0,v.Y-size.Y))
  toolbar.AnchorPoint=Vector2.new(0,0)
  toolbar.Position=UDim2.fromOffset(x,y)
 end
end)
local endConnection=UIS.InputEnded:Connect(function(input)
 if toolInput and (input==toolInput or (toolInput.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseButton1)) then
  local wasMoved=moved;toolInput=nil
  if not wasMoved then setOpen(not open)end
 end
end)
-- Live local FPS / ping readout (read-only).
local frames,last=0,os.clock()
local perf=RunService.RenderStepped:Connect(function()
 frames=frames+1
 local now=os.clock()
 if now-last>=1 then
  fpsText.Text=tostring(math.floor(frames/(now-last)+.5))..' fps'
  tFps.Text=fpsText.Text
  frames=0;last=now
 end
end)
local alive=true
task.spawn(function()
 while alive and gui.Parent do
  pcall(function()
   local ms=Stats.Network.ServerStatsItem['Data Ping']:GetValue()
   pingText.Text=tostring(math.floor(ms+.5))..' ms'
   tPing.Text=pingText.Text
   local color=ms<100 and C.green or C.yellow
   pingDot.BackgroundColor3=color;tDot2.BackgroundColor3=color
  end)
  task.wait(3)
 end
end)
gui.Destroying:Connect(function()
 alive=false
 for _,c in ipairs({perf,moveConnection,endConnection,cameraWatch,cameraConnection}) do if c then c:Disconnect()end end
end)
print('[Blizzard V11.4] Star-inspired standalone visual preview ready. Gameplay modules: NOT CONNECTED.')
