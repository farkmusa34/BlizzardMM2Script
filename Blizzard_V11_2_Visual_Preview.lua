-- BLIZZARD V11.2 | STANDALONE CUSTOM UI VISUAL PREVIEW
-- Preview controls only. No MM2 gameplay functionality is invoked.
local Players=game:GetService('Players')
local UIS=game:GetService('UserInputService')
local RunService=game:GetService('RunService')
local TweenService=game:GetService('TweenService')
local Stats=game:GetService('Stats')
local player=Players.LocalPlayer
local parent=player:WaitForChild('PlayerGui')
for _,name in ipairs({'BlizzardV11','BlizzardV11_1','BlizzardV11_2'}) do
 local old=parent:FindFirstChild(name);if old then old:Destroy() end
end
local C={bg=Color3.fromRGB(10,10,13),panel=Color3.fromRGB(18,18,23),card=Color3.fromRGB(21,21,26),hover=Color3.fromRGB(36,36,43),border=Color3.fromRGB(43,43,51),white=Color3.fromRGB(246,246,249),muted=Color3.fromRGB(135,135,149),green=Color3.fromRGB(16,211,111)}
local function new(t,p,props)
 local o=Instance.new(t)
 for k,v in pairs(props or {}) do o[k]=v end
 o.Parent=p;return o
end
local function corner(o,r) new('UICorner',o,{CornerRadius=UDim.new(0,r)}) end
local function pill(o) new('UICorner',o,{CornerRadius=UDim.new(1,0)}) end
local function stroke(o,c,th) new('UIStroke',o,{Color=c or C.border,Thickness=th or 1,Transparency=.08}) end
local function label(p,s,size,bold,color)
 return new('TextLabel',p,{BackgroundTransparency=1,Text=s,TextColor3=color or C.white,TextSize=size or 14,Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd})
end
local function place(o,x,y,w,h) o.Position=UDim2.fromOffset(x,y);o.Size=UDim2.fromOffset(w,h);return o end
local function text(p,s,x,y,w,h,size,bold,color) return place(label(p,s,size,bold,color),x,y,w,h) end
local function btn(p,x,y,w,h,bg)
 local b=new('TextButton',p,{Text='',AutoButtonColor=false,BorderSizePixel=0,BackgroundColor3=bg or C.hover});place(b,x,y,w,h);corner(b,9);return b
end
local iconPack
pcall(function()
 local pack=loadstring(game:HttpGet('https://raw.githubusercontent.com/Footagesus/Icons/main/lucide/dist/Icons.lua'))()
 if type(pack)=='table' then iconPack=pack end
end)
local function icon(p,name,x,y,size,color)
 local holder=new('Frame',p,{BackgroundTransparency=1});place(holder,x,y,size,size)
 local d=iconPack and iconPack[name]
 local id,offset,rect
 if type(d)=='string' then id=d
 elseif type(d)=='table' then
  if type(d[1])=='string' then id=d[1];if type(d[2])=='table' then offset=d[2].ImageRectPosition;rect=d[2].ImageRectSize end
  elseif type(d.Image)=='string' then id=d.Image;offset=d.ImageRectPosition or d.RectOffset;rect=d.ImageRectSize or d.RectSize end
 end
 if id then
  local im=new('ImageLabel',holder,{BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Image=id,ImageColor3=color or C.white,ScaleType=Enum.ScaleType.Fit})
  if typeof(offset)=='Vector2' then im.ImageRectOffset=offset end
  if typeof(rect)=='Vector2' then im.ImageRectSize=rect end
 else
  local fallback={['gamepad-2']='🎮',['mouse-pointer-click']='↖',['house']='⌂',['maximize']='□',['minimize']='−',['x']='×',['footprints']='♧',['sword']='⚔',['bot']='▣',['chevron-down']='⌄',['chevron-right']='›'}
  local t=text(holder,fallback[name] or '•',0,0,size,size,math.max(13,size-3),true,color or C.white);t.TextXAlignment=Enum.TextXAlignment.Center
 end
 return holder
end
local gui=new('ScreenGui',parent,{Name='BlizzardV11_2',IgnoreGuiInset=true,ResetOnSpawn=false,DisplayOrder=900})
local stage=new('Frame',gui,{BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.53),Size=UDim2.fromOffset(970,650)})
local stageScale=new('UIScale',stage,{Scale=1})
local window=new('CanvasGroup',stage,{BackgroundColor3=C.bg,BorderSizePixel=0,Size=UDim2.fromScale(1,1),GroupTransparency=0,ClipsDescendants=true});corner(window,22);stroke(window,Color3.fromRGB(77,77,87))
local windowZoom=new('UIScale',window,{Scale=1})
local sideWidth=278
local sidebar=new('Frame',window,{BackgroundColor3=C.bg,BorderSizePixel=0,Size=UDim2.new(0,sideWidth,1,0)})
new('Frame',sidebar,{Position=UDim2.new(1,-1,0,0),Size=UDim2.new(0,1,1,0),BorderSizePixel=0,BackgroundColor3=C.border})
local brand=icon(sidebar,'gamepad-2',23,23,34,C.white)
text(sidebar,'Blizzard',68,20,150,28,21,true)
local ver=btn(sidebar,198,26,55,21,C.panel);pill(ver);text(ver,'V11.2',8,2,45,17,10,true,C.muted)
local fpsDot=new('Frame',sidebar,{BackgroundColor3=C.green});place(fpsDot,70,59,7,7);pill(fpsDot)
local fps=text(sidebar,'-- fps',82,50,75,24,11,false,C.muted)
local pingDot=new('Frame',sidebar,{BackgroundColor3=C.green});place(pingDot,168,59,7,7);pill(pingDot)
local ping=text(sidebar,'-- ms',180,50,75,24,11,false,C.muted)
local search=btn(sidebar,17,91,244,43,C.panel);corner(search,12);stroke(search)
icon(search,'search',13,12,19,C.muted)
local searchInput=new('TextBox',search,{BackgroundTransparency=1,Text='',PlaceholderText='Search settings',PlaceholderColor3=C.muted,TextColor3=C.white,Font=Enum.Font.Gotham,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false});place(searchInput,43,4,191,35)
local nav=new('ScrollingFrame',sidebar,{BackgroundTransparency=1,BorderSizePixel=0,Active=true,ScrollingEnabled=true,ScrollingDirection=Enum.ScrollingDirection.Y,ScrollBarThickness=3,ScrollBarImageColor3=C.border,Position=UDim2.fromOffset(0,147),Size=UDim2.new(1,0,1,-229),CanvasSize=UDim2.fromOffset(0,0),ElasticBehavior=Enum.ElasticBehavior.WhenScrollable})
local avatar='rbxthumb://type=AvatarHeadShot&id='..player.UserId..'&w=150&h=150'
local footer=new('Frame',sidebar,{BackgroundColor3=C.panel,Position=UDim2.new(0,14,1,-72),Size=UDim2.new(1,-28,0,58)});corner(footer,13)
local av=new('ImageLabel',footer,{BackgroundColor3=C.hover,Image=avatar});place(av,9,9,40,40);pill(av)
text(footer,player.DisplayName,57,9,190,22,12,true)
text(footer,'@'..player.Name,57,31,190,17,10,false,C.muted)
local main=new('Frame',window,{BackgroundTransparency=1,Position=UDim2.fromOffset(sideWidth,0),Size=UDim2.new(1,-sideWidth,1,0)})
local top=new('Frame',main,{BackgroundTransparency=1,Size=UDim2.new(1,0,0,83)})
new('Frame',main,{BackgroundColor3=C.border,BorderSizePixel=0,Position=UDim2.fromOffset(0,82),Size=UDim2.new(1,0,0,1)})
local pageBadge=btn(top,23,20,45,45,C.white);corner(pageBadge,12)
local badgeIcon=icon(pageBadge,'house',10,10,25,C.bg)
local category=text(top,'OVERVIEW',83,12,270,20,10,true,C.muted)
local heading=text(top,'Home',83,30,350,36,23,true)
local controls=new('Frame',top,{BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-17,0,21),Size=UDim2.fromOffset(132,39)})
local content=new('ScrollingFrame',main,{BackgroundTransparency=1,BorderSizePixel=0,Active=true,ScrollingEnabled=true,ScrollingDirection=Enum.ScrollingDirection.Y,ScrollBarThickness=4,ScrollBarImageColor3=C.border,Position=UDim2.fromOffset(0,83),Size=UDim2.new(1,0,1,-83),CanvasSize=UDim2.fromOffset(0,0),ElasticBehavior=Enum.ElasticBehavior.WhenScrollable})
local contentPad=new('UIPadding',content,{PaddingLeft=UDim.new(0,22),PaddingRight=UDim.new(0,24),PaddingTop=UDim.new(0,16),PaddingBottom=UDim.new(0,30)})
local layout=new('UIListLayout',content,{FillDirection=Enum.FillDirection.Vertical,Padding=UDim.new(0,15),SortOrder=Enum.SortOrder.LayoutOrder,HorizontalAlignment=Enum.HorizontalAlignment.Center})
local function updateCanvas()
 task.defer(function()
  if content.Parent then content.CanvasSize=UDim2.fromOffset(0,layout.AbsoluteContentSize.Y+52) end
 end)
end
layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(updateCanvas)
local navGroups={
 {'HOME',{{'Home','house'}}},
 {'SETTINGS',{{'On-Screen Buttons','mouse-pointer-click'},{'General','sliders-horizontal'}}},
 {'PLAYER',{{'Movement','footprints'},{'Players','users'}}},
 {'COMBAT',{{'Aim','crosshair'},{'Sheriff & Murderer','sword'},{'Fling','wind'}}},
 {'VISUALS',{{'ESP','scan-eye'},{'Effects','sparkles'},{'Role ESP','eye'}}},
 {'SKIN CHANGER',{{'Gun','crosshair'},{'Knife','sword'}}},
 {'FARMING',{{'Auto Farm','bot'}}},
 {'MISC',{{'Teleport','navigation'},{'Misc','settings'}}}
}
local pages={
 ['On-Screen Buttons']={'SETTINGS','mouse-pointer-click',{{'Layout','mouse-pointer-click',{{'Lock Buttons','toggle'},{'Button Size','slider',50,150,100},{'Reset Size / Positions','action','rotate-ccw'}}},{'Sheriff','shield',{{'Shoot Murderer Button','toggle'},{'Rage Shoot Button','toggle'}}},{'Murderer','sword',{{'Throw Knife Button','toggle'},{'Kill All Button','toggle'}}},{'Fling','wind',{{'Fling Murderer Button','toggle'},{'Fling Sheriff / Hero Button','toggle'}}},{'Player','user-round',{{'Bomb Boost Button','toggle'},{'Fly Button','toggle'},{'Noclip Button','toggle'},{'Infinite Jump Button','toggle'}}}}},
 ['General']={'SETTINGS','sliders-horizontal',{{'Appearance','palette',{{'Background Thumbnail','toggle'}}},{'Performance','zap',{{'Lite Mode','toggle'},{'FPS Boost','toggle'}}},{'Config','save',{{'Auto Save','toggle'},{'Save Now','action','save'},{'Load Saved','action','folder-open'}}}}},
 ['Movement']={'PLAYER','footprints',{{'Movement','footprints',{{'Walk Speed','slider',16,100,16},{'Jump Power','slider',50,150,50},{'Walk Through Walls with Freefall Protection','toggle'}}},{'Fly','plane',{{'Fly','toggle'},{'Fly Speed','slider',10,100,10}}},{'Jumping','arrow-up',{{'Infinite Jump','toggle'},{'Wall Jump','toggle'}}},{'Bomb Boost','bomb',{{'Bomb Boost Button','action','bomb'},{'Boost Power','slider',30,250,120}}}}},
 ['Players']={'PLAYER','users',{{'Alerts','bell',{{'Round Start Alert','toggle'}}}}},
 ['Aim']={'COMBAT','crosshair',{{'Aim','crosshair',{{'TriggerBot','toggle'},{'Aim Lock','toggle'},{'Shoot Murderer (Legit)','action','crosshair'}}},{'Accuracy','target',{{'Aim Prediction','toggle'},{'Prediction Strength','slider',30,250,100},{'Wall Throw','toggle'}}}}},
 ['Sheriff & Murderer']={'COMBAT','sword',{{'Sheriff','shield',{{'Shoot Murderer','action','crosshair'},{'Rage Shoot','toggle'}}},{'Murderer','sword',{{'Legit Throw','toggle'},{'Auto Throw Knife (RAGE)','toggle'},{'Throw Aimbot Button','action','sword'},{'Kill All','action','swords'}}}}},
 ['Fling']={'COMBAT','wind',{{'Fling','wind',{{'Fling Murderer Button','toggle'},{'Fling Sheriff / Hero Button','toggle'},{'Anti Fling','toggle'},{'Fling Notify','toggle'}}}}},
 ['ESP']={'VISUALS','scan-eye',{{'Player ESP','eye',{{'Match ESP','toggle'},{'Gun ESP','toggle'},{'Tracers','toggle'},{'Nametags','toggle'},{'Distance ESP','toggle'}}}}},
 ['Effects']={'VISUALS','sparkles',{{'Visual Effects','sparkles',{{'Tracers','toggle'},{'Tracer Thickness','slider',1,10,3},{'Glow','toggle'}}}}},
 ['Role ESP']={'VISUALS','eye',{{'Role Display','scan-eye',{{'Role ESP','toggle'},{'Show Role Labels','toggle'},{'Show Distance','toggle'}}}}},
 ['Gun']={'SKIN CHANGER','crosshair',{{'Gun Skins','palette',{{'Enable Gun Skin Changer','toggle'},{'Select Gun Skin','action','chevron-down'}}}}},
 ['Knife']={'SKIN CHANGER','sword',{{'Knife Skins','palette',{{'Enable Knife Skin Changer','toggle'},{'Select Knife Skin','action','chevron-down'}}}}},
 ['Auto Farm']={'FARMING','bot',{{'Coin Farm','coins',{{'Auto Farm Coins','toggle'},{'Farm Underground','toggle'},{'Farm Speed','slider',1,25,25}}},{'When The Bag Is Full','backpack',{{'Fling Murderer','toggle'},{'Shoot Murderer','toggle'},{'Kill All','toggle'},{'Reset Character','toggle'}}},{'Statistics','chart-no-axes-column',{{'Reset Stats','action','rotate-ccw'}}}}},
 ['Teleport']={'MISC','navigation',{{'Teleport','navigation',{{'Teleport to Map','action','map-pin'},{'Teleport to Lobby','action','house'}}}}},
 ['Misc']={'MISC','settings',{{'Miscellaneous','settings',{{'Anti AFK','toggle'},{'Hop Server','action','shuffle'},{'Notifications','toggle'}}}}}
}
local selected='Home';local expanded={};local collapsed={};local preview={}
for _,g in ipairs(navGroups) do expanded[g[1]]=true end
local function clearKeep(container,keep)
 for _,child in ipairs(container:GetChildren()) do if not keep[child] then child:Destroy() end end
end
local function section(title,ic,rows)
 local box=new('Frame',content,{BackgroundColor3=C.panel,BorderSizePixel=0,Size=UDim2.new(1,0,0,70),AutomaticSize=Enum.AutomaticSize.None});corner(box,17);stroke(box)
 local key=selected..'/'..title
 local head=new('TextButton',box,{Text='',BackgroundTransparency=1,AutoButtonColor=false,Size=UDim2.new(1,0,0,65)})
 local badge=btn(head,17,13,39,39,C.white);corner(badge,10);icon(badge,ic,10,10,19,C.bg)
 text(head,title,70,12,340,40,15,true)
 local counter=text(head,tostring(#rows),0,18,28,25,12,true,C.muted);counter.AnchorPoint=Vector2.new(1,0);counter.Position=UDim2.new(1,-53,0,18);counter.TextXAlignment=Enum.TextXAlignment.Right
 local chevron=icon(head,collapsed[key] and 'chevron-right' or 'chevron-down',0,23,16,C.muted);chevron.AnchorPoint=Vector2.new(1,0);chevron.Position=UDim2.new(1,-20,0,23)
 local inner=new('Frame',box,{BackgroundTransparency=1,Position=UDim2.fromOffset(0,65),Size=UDim2.new(1,0,0,0)})
 local cursor=0
 if not collapsed[key] then
  for _,r in ipairs(rows) do
   local name,kind=r[1],r[2]
   local height=kind=='slider' and 90 or 56
   new('Frame',inner,{BackgroundColor3=C.border,BorderSizePixel=0,Position=UDim2.fromOffset(18,cursor),Size=UDim2.new(1,-36,0,1)})
   local titleLabel=text(inner,name,21,cursor+9,360,36,13,false)
   titleLabel.Size=UDim2.new(1,-118,0,36)
   if kind=='toggle' then
    local state=preview[name]==true
    local switch=btn(inner,0,cursor+12,59,31,state and C.white or Color3.fromRGB(49,49,58));switch.AnchorPoint=Vector2.new(1,0);switch.Position=UDim2.new(1,-22,0,cursor+12);pill(switch)
    local knob=new('Frame',switch,{BackgroundColor3=state and C.bg or C.muted,Size=UDim2.fromOffset(23,23),Position=UDim2.fromOffset(state and 32 or 4,4)});pill(knob)
    switch.MouseButton1Click:Connect(function()
     state=not state;preview[name]=state
     TweenService:Create(switch,TweenInfo.new(.18),{BackgroundColor3=state and C.white or Color3.fromRGB(49,49,58)}):Play()
     TweenService:Create(knob,TweenInfo.new(.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.fromOffset(state and 32 or 4,4),BackgroundColor3=state and C.bg or C.muted}):Play()
    end)
   elseif kind=='slider' then
    local min,max=r[3],r[4];local value=preview[name] or r[5]
    local val=text(inner,tostring(value),0,cursor+9,75,36,13,true);val.AnchorPoint=Vector2.new(1,0);val.Position=UDim2.new(1,-22,0,cursor+9);val.TextXAlignment=Enum.TextXAlignment.Right
    local track=btn(inner,22,cursor+60,100,5,C.hover);track.Size=UDim2.new(1,-44,0,5);pill(track)
    local fraction=(value-min)/(max-min)
    local fill=new('Frame',track,{BackgroundColor3=C.white,Size=UDim2.fromScale(fraction,1)});pill(fill)
    local handle=new('Frame',track,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(fraction,.5),Size=UDim2.fromOffset(17,17),BackgroundColor3=C.white});pill(handle)
    local drag=false;local pointer=nil
    local function update(input)
     local f=math.clamp((input.Position.X-track.AbsolutePosition.X)/math.max(1,track.AbsoluteSize.X),0,1)
     local v=math.floor(min+(max-min)*f+.5);preview[name]=v;val.Text=tostring(v)
     fill.Size=UDim2.fromScale(f,1);handle.Position=UDim2.fromScale(f,.5)
    end
    track.InputBegan:Connect(function(input)
     if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then drag=true;pointer=input;update(input) end
    end)
    local changed,ended
    changed=UIS.InputChanged:Connect(function(input)
     if drag and (input==pointer or (pointer and pointer.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement)) then update(input) end
    end)
    ended=UIS.InputEnded:Connect(function(input)
     if input==pointer or (pointer and pointer.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseButton1) then drag=false;pointer=nil end
    end)
    track.Destroying:Connect(function() changed:Disconnect();ended:Disconnect() end)
   else
    local act=btn(inner,0,cursor+10,39,36,C.hover);act.AnchorPoint=Vector2.new(1,0);act.Position=UDim2.new(1,-20,0,cursor+10)
    icon(act,r[3] or 'chevron-right',10,8,19,C.white)
   end
   cursor=cursor+height
  end
 end
 inner.Size=UDim2.new(1,0,0,cursor)
 box.Size=UDim2.new(1,0,0,65+cursor+6)
 head.MouseButton1Click:Connect(function()
  collapsed[key]=not collapsed[key]
  local saved=content.CanvasPosition.Y
  task.defer(function()
   if not gui.Parent then return end
   -- The page is rebuilt by the registered section handler.
  end)
 end)
 return box,head,key
end
local renderPage
local function addSection(title,ic,rows)
 local box,head,key=section(title,ic,rows)
 head.MouseButton1Click:Connect(function() task.defer(function() if renderPage then renderPage(true) end end) end)
 return box
end
local function simpleCard(height)
 local b=new('Frame',content,{BackgroundColor3=C.panel,Size=UDim2.new(1,0,0,height),BorderSizePixel=0});corner(b,17);stroke(b);return b
end
local function home()
 local p=simpleCard(137)
 local a=new('ImageLabel',p,{Image=avatar,BackgroundColor3=C.hover});place(a,20,20,66,66);pill(a)
 text(p,player.DisplayName,103,23,360,32,18,true)
 text(p,'@'..player.Name,103,57,350,22,12,false,C.muted)
 text(p,'VISUAL PREVIEW · NO GAMEPLAY CONNECTED',20,108,470,19,10,true,C.green)
 local statsCard=simpleCard(107)
 for i,d in ipairs({'COINS','GEMS','LEVEL'}) do
  local x=(i-1)/3
  local t=text(statsCard,'—',0,19,100,37,24,true);t.Position=UDim2.new(x,0,0,19);t.Size=UDim2.new(1/3,0,0,37);t.TextXAlignment=Enum.TextXAlignment.Center
  local v=text(statsCard,d,0,62,100,22,11,true,C.muted);v.Position=UDim2.new(x,0,0,62);v.Size=UDim2.new(1/3,0,0,22);v.TextXAlignment=Enum.TextXAlignment.Center
 end
 addSection('Quick Actions','zap',{{'Shoot Murderer','action','crosshair'},{'Fling Murderer','action','wind'},{'Kill All','action','swords'},{'Hop Server','action','shuffle'}})
 addSection('Status','activity',{{'Auto Farm Coins','toggle'},{'Match ESP','toggle'}})
end
function renderPage(preserve)
 local oldY=preserve and content.CanvasPosition.Y or 0
 clearKeep(content,{[contentPad]=true,[layout]=true})
 if selected=='Home' then category.Text='OVERVIEW';heading.Text='Home' else local p=pages[selected];if not p then return end;category.Text=p[1];heading.Text=selected end
 if badgeIcon then badgeIcon:Destroy() end
 badgeIcon=icon(pageBadge,selected=='Home' and 'house' or pages[selected][2],10,10,25,C.bg)
 if selected=='Home' then home() else
  for _,s in ipairs(pages[selected][3]) do addSection(s[1],s[2],s[3]) end
  if selected=='Players' then
   for _,other in ipairs(Players:GetPlayers()) do
    local row=simpleCard(70)
    local img=new('ImageLabel',row,{Image='rbxthumb://type=AvatarHeadShot&id='..other.UserId..'&w=150&h=150',BackgroundColor3=C.hover});place(img,13,12,46,46);pill(img)
    text(row,other.DisplayName,72,11,260,24,14,true)
    text(row,'@'..other.Name,72,37,260,19,11,false,C.muted)
   end
  end
 end
 updateCanvas()
 task.defer(function() if content.Parent then content.CanvasPosition=Vector2.new(0,oldY) end end)
end
local navButtons={}
local function navRender()
 clearKeep(nav,{})
 local y=5
 for _,g in ipairs(navGroups) do
  local group,items=g[1],g[2]
  if group~='HOME' then
   y=y+10
   local h=btn(nav,14,y,244,31,C.bg)
   text(h,group,29,5,173,22,10,true,C.muted)
   icon(h,expanded[group] and 'chevron-down' or 'chevron-right',215,8,15,C.muted)
   h.MouseButton1Click:Connect(function()expanded[group]=not expanded[group];navRender()end)
   y=y+36
  end
  if group=='HOME' or expanded[group] then
   for _,it in ipairs(items) do
    local name,ic=it[1],it[2];local active=name==selected
    local b=btn(nav,14,y,244,44,active and C.white or C.bg)
    icon(b,ic,14,12,20,active and C.bg or C.muted)
    text(b,name,48,8,184,29,13,active,active and C.bg or C.muted)
    b.MouseButton1Click:Connect(function()selected=name;navRender();renderPage(false)end)
    y=y+49
   end
  end
 end
 nav.CanvasSize=UDim2.fromOffset(0,y+22)
end
local expandedWindow=false
local tall=Vector2.new(970,650);local wide=Vector2.new(1100,580)
local function viewport() return workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1200,750) end
local function fit()
 local v=viewport();local dims=expandedWindow and wide or tall
 stageScale.Scale=math.min(1,(v.X-30)/dims.X,(v.Y-88)/dims.Y)
end
local function maximize()
 expandedWindow=not expandedWindow
 local dims=expandedWindow and wide or tall
 TweenService:Create(stage,TweenInfo.new(.32,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.fromOffset(dims.X,dims.Y)}):Play()
 fit()
end
local function control(x,ic,fn)
 local b=btn(controls,x,0,39,39,C.panel);corner(b,11);icon(b,ic,10,10,19,C.muted);b.MouseButton1Click:Connect(fn);return b
end
-- Floating pill is a sibling of the window, with higher ZIndex.
local toolbar=new('TextButton',gui,{Name='FloatingBlizzardPill',BackgroundColor3=Color3.fromRGB(23,22,28),BorderSizePixel=0,Text='',AutoButtonColor=false,Size=UDim2.fromOffset(240,80),AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,10),ZIndex=30,Active=true})
pill(toolbar);stroke(toolbar,C.white,1.4)
local toolScale=new('UIScale',toolbar,{Scale=1})
local pad=icon(toolbar,'gamepad-2',20,19,42,C.white);pad.ZIndex=31
for _,d in ipairs(pad:GetDescendants()) do if d:IsA('GuiObject') then d.ZIndex=32 end end
local toolName=text(toolbar,'Blizzard',72,12,155,31,21,true);toolName.ZIndex=31
local d1=new('Frame',toolbar,{BackgroundColor3=C.green,ZIndex=31});place(d1,73,56,9,9);pill(d1)
local toolFps=text(toolbar,'-- fps',89,47,64,26,12,false,C.muted);toolFps.ZIndex=31
local d2=new('Frame',toolbar,{BackgroundColor3=C.green,ZIndex=31});place(d2,157,56,9,9);pill(d2)
local toolPing=text(toolbar,'-- ms',173,47,62,26,12,false,C.muted);toolPing.ZIndex=31
local isOpen=true;local transitionId=0;local openTween
local function spin(open)
 local target=open and 360 or -360
 pad.Rotation=0
 local tw=TweenService:Create(pad,TweenInfo.new(.4,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Rotation=target})
 tw:Play();tw.Completed:Once(function() if pad.Parent and math.abs(pad.Rotation-target)<1 then pad.Rotation=0 end end)
end
local function setOpen(value)
 if isOpen==value then return end
 isOpen=value;transitionId=transitionId+1
 local ticket=transitionId
 if openTween then openTween:Cancel() end
 spin(value)
 if value then
  window.Visible=true
  window.GroupTransparency=1
  windowZoom.Scale=.96
  TweenService:Create(windowZoom,TweenInfo.new(.3,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Scale=1}):Play()
  local tween=TweenService:Create(window,TweenInfo.new(.3,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{GroupTransparency=0})
  openTween=tween;tween:Play()
  TweenService:Create(stageScale,TweenInfo.new(.3,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Scale=stageScale.Scale}):Play()
 else
  TweenService:Create(windowZoom,TweenInfo.new(.3,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Scale=.96}):Play()
  local tween=TweenService:Create(window,TweenInfo.new(.3,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{GroupTransparency=1})
  openTween=tween;tween:Play()
  tween.Completed:Once(function(state) if ticket==transitionId and not isOpen and state==Enum.PlaybackState.Completed then window.Visible=false end end)
 end
end
control(0,'minus',function()setOpen(false)end)
local maxButton=control(46,'maximize',maximize)
control(92,'x',function()setOpen(false)end)
local dragStart,dragOrigin,dragInput,dragMoved
toolbar.InputBegan:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
  dragInput=input;dragStart=input.Position;dragOrigin=toolbar.AbsolutePosition;dragMoved=false
 end
end)
local function moveToolbar(input)
 if not dragInput then return end
 if input~=dragInput and not (dragInput.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement) then return end
 local delta=input.Position-dragStart
 if delta.Magnitude>8 then dragMoved=true end
 if dragMoved then
  local v=viewport();local w=toolbar.AbsoluteSize.X;local h=toolbar.AbsoluteSize.Y
  local x=math.clamp(dragOrigin.X+delta.X,0,math.max(0,v.X-w));local y=math.clamp(dragOrigin.Y+delta.Y,0,math.max(0,v.Y-h))
  toolbar.AnchorPoint=Vector2.zero;toolbar.Position=UDim2.fromOffset(x,y)
 end
end
local conMove=UIS.InputChanged:Connect(moveToolbar)
local conEnd=UIS.InputEnded:Connect(function(input)
 if dragInput and (input==dragInput or (dragInput.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseButton1)) then
  local moved=dragMoved;dragInput=nil
  if not moved then setOpen(not isOpen) end
 end
end)
-- Drag only from empty page-header space, never from scrolling content.
local dragging,initial,origin,dragPointer
local headerDrag=new('Frame',top,{BackgroundTransparency=1,Position=UDim2.fromOffset(350,0),Size=UDim2.new(1,-500,1,0),Active=true})
headerDrag.InputBegan:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=true;dragPointer=input;initial=input.Position;origin=stage.Position end
end)
local conHeader=UIS.InputChanged:Connect(function(input)
 if dragging and (input==dragPointer or (dragPointer and dragPointer.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement)) then
  local delta=input.Position-initial
  stage.Position=UDim2.new(origin.X.Scale,origin.X.Offset+delta.X,origin.Y.Scale,origin.Y.Offset+delta.Y)
 end
end)
local conHeaderEnd=UIS.InputEnded:Connect(function(input)
 if input==dragPointer then dragging=false;dragPointer=nil end
end)
local frameCount,last=0,os.clock()
local conPerf=RunService.RenderStepped:Connect(function()
 frameCount=frameCount+1
 local now=os.clock()
 if now-last>=1 then
  fps.Text=tostring(math.floor(frameCount/(now-last)+.5))..' fps';toolFps.Text=fps.Text
  frameCount=0;last=now
 end
end)
task.spawn(function()
 while gui.Parent do
  pcall(function()
   local ms=Stats.Network.ServerStatsItem['Data Ping']:GetValue()
   ping.Text=tostring(math.floor(ms+.5))..' ms';toolPing.Text=ping.Text
   local color=ms<100 and C.green or Color3.fromRGB(255,197,56)
   pingDot.BackgroundColor3=color;d2.BackgroundColor3=color
  end)
  task.wait(3)
 end
end)
local camCon
local function watchCam()
 if camCon then camCon:Disconnect() end
 if workspace.CurrentCamera then camCon=workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(fit) end
 fit()
end
local camChanged=workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(watchCam)
watchCam()
searchInput:GetPropertyChangedSignal('Text'):Connect(function()
 local q=searchInput.Text:lower()
 if q=='' then return end
 for _,g in ipairs(navGroups) do for _,it in ipairs(g[2]) do
  if it[1]:lower():find(q,1,true) then selected=it[1];expanded[g[1]]=true;navRender();renderPage(false);return end
 end end
end)
navRender();renderPage(false)
gui.Destroying:Connect(function()
 for _,c in ipairs({conMove,conEnd,conHeader,conHeaderEnd,conPerf,camCon,camChanged}) do if c then c:Disconnect() end end
end)
print('[Blizzard V11.2] Standalone preview loaded. No gameplay connected.')
