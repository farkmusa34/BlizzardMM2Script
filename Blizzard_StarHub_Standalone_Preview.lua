-- Blizzard MM2 | Star Hub-inspired standalone visual preview
-- UI ONLY: No Blizzard modules, no gameplay features, no functional tabs.
-- Designed for Roblox client execution. Close and minimize are presentation controls.
local Players = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')
local player = Players.LocalPlayer
local parent = player:WaitForChild('PlayerGui')
local old = parent:FindFirstChild('BlizzardStarPreview')
if old then old:Destroy() end

local C = {
 bg=Color3.fromRGB(10,10,14), panel=Color3.fromRGB(17,17,22),
 card=Color3.fromRGB(22,22,28), hover=Color3.fromRGB(34,34,41),
 border=Color3.fromRGB(49,49,58), white=Color3.fromRGB(245,245,248),
 muted=Color3.fromRGB(119,119,132), green=Color3.fromRGB(34,193,104),
 blue=Color3.fromRGB(88,177,255), yellow=Color3.fromRGB(255,198,67)
}
local function new(class, parentObj, props)
 local o=Instance.new(class)
 for k,v in pairs(props or {}) do o[k]=v end
 o.Parent=parentObj
 return o
end
local function corner(o,r) new('UICorner',o,{CornerRadius=UDim.new(0,r)}) end
local function stroke(o,col,thick) new('UIStroke',o,{Color=col or C.border,Thickness=thick or 1,Transparency=0.15}) end
local function label(p,text,x,y,w,h,size,color,bold)
 return new('TextLabel',p,{BackgroundTransparency=1,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),Text=text,TextColor3=color or C.white,Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,TextSize=size or 14,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd})
end
local gui=new('ScreenGui',parent,{Name='BlizzardStarPreview',ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=999})
local scaleRoot=new('Frame',gui,{Name='PreviewWindow',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(900,510),BackgroundColor3=C.bg,ClipsDescendants=true})
corner(scaleRoot,18); stroke(scaleRoot,Color3.fromRGB(87,87,99),1.2)
local scale=new('UIScale',scaleRoot,{Scale=1})
local function resize()
 local v=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1000,700)
 scale.Scale=math.min(1,math.max(.40,math.min((v.X-24)/900,(v.Y-32)/510)))
end
resize()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(resize) end

-- Header
local header=new('Frame',scaleRoot,{BackgroundColor3=C.bg,Size=UDim2.new(1,0,0,76),BorderSizePixel=0})
new('Frame',header,{BackgroundColor3=C.border,BorderSizePixel=0,Position=UDim2.fromOffset(0,75),Size=UDim2.new(1,0,0,1)})
label(header,'✦',24,17,40,42,33,C.white,true)
label(header,'Blizzard',66,14,150,31,23,C.white,true)
local ver=new('Frame',header,{Position=UDim2.fromOffset(181,20),Size=UDim2.fromOffset(67,24),BackgroundColor3=C.panel})
corner(ver,12); label(ver,'v1.85.4',10,3,56,18,11,C.muted,true)
label(header,'●',67,47,12,16,13,C.green,true)
label(header,'UI CONCEPT  •  VISUAL PREVIEW',82,46,225,19,11,C.muted,false)
local search=new('Frame',header,{Position=UDim2.fromOffset(340,15),Size=UDim2.fromOffset(355,45),BackgroundColor3=C.panel})
corner(search,11); stroke(search)
label(search,'⌕   Search settings',17,9,300,28,16,C.muted,false)
label(header,'—',792,19,27,28,24,C.muted,false)
label(header,'□',824,20,25,27,22,C.muted,false)
local close=new('TextButton',header,{Position=UDim2.fromOffset(855,17),Size=UDim2.fromOffset(29,32),BackgroundTransparency=1,Text='×',TextSize=27,Font=Enum.Font.Gotham,TextColor3=C.muted})
close.MouseButton1Click:Connect(function() gui:Destroy() end)

-- Sidebar
local side=new('Frame',scaleRoot,{Position=UDim2.fromOffset(0,76),Size=UDim2.fromOffset(245,434),BackgroundColor3=C.bg,BorderSizePixel=0})
new('Frame',side,{Position=UDim2.fromOffset(244,0),Size=UDim2.fromOffset(1,434),BorderSizePixel=0,BackgroundColor3=C.border})
local function sideItem(text,y,icon,selected)
 local bg=new('Frame',side,{Position=UDim2.fromOffset(14,y),Size=UDim2.fromOffset(214,43),BackgroundColor3=selected and C.hover or C.bg,BorderSizePixel=0})
 corner(bg,10)
 if selected then local bar=new('Frame',bg,{Position=UDim2.fromOffset(0,10),Size=UDim2.fromOffset(4,23),BackgroundColor3=C.white});corner(bar,3) end
 label(bg,icon,17,10,25,25,19,selected and C.white or C.muted,true)
 label(bg,text,51,10,155,25,15,selected and C.white or C.muted,selected)
end
sideItem('Home',12,'⌂',true)
new('Frame',side,{Position=UDim2.fromOffset(18,67),Size=UDim2.fromOffset(207,1),BackgroundColor3=C.border,BorderSizePixel=0})
label(side,'SETTINGS',25,82,190,22,12,C.muted,true)
sideItem('Player',111,'♙',false)
sideItem('Visuals',157,'◉',false)
sideItem('Combat',203,'⌖',false)
sideItem('Teleport',249,'◇',false)
sideItem('Fling',295,'≋',false)
sideItem('Auto Farm',341,'▣',false)
-- Small user footer overlays the last sidebar item intentionally, like a compact scrolled sidebar.
local foot=new('Frame',side,{Position=UDim2.fromOffset(14,373),Size=UDim2.fromOffset(214,48),BackgroundColor3=C.panel})
corner(foot,12)
local avatar=new('ImageLabel',foot,{Position=UDim2.fromOffset(9,6),Size=UDim2.fromOffset(36,36),BackgroundColor3=C.hover,Image='rbxthumb://type=AvatarHeadShot&id='..tostring(player.UserId)..'&w=150&h=150'})
corner(avatar,18)
label(foot,player.DisplayName,54,6,151,19,12,C.white,true)
label(foot,'@'..player.Name,54,24,151,18,11,C.muted,false)

-- Main content
local main=new('Frame',scaleRoot,{Position=UDim2.fromOffset(245,76),Size=UDim2.fromOffset(655,434),BackgroundColor3=C.bg,BorderSizePixel=0})
local sc=new('ScrollingFrame',main,{Position=UDim2.fromOffset(0,0),Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,ScrollBarThickness=3,ScrollBarImageColor3=C.border,CanvasSize=UDim2.fromOffset(0,625)})
local tag=new('Frame',sc,{Position=UDim2.fromOffset(27,21),Size=UDim2.fromOffset(44,44),BackgroundColor3=C.hover})
corner(tag,12);label(tag,'⌂',10,8,27,29,27,C.white,true)
label(sc,'OVERVIEW',87,19,200,19,11,C.muted,true)
label(sc,'Home',87,38,260,33,23,C.white,true)

local profile=new('Frame',sc,{Position=UDim2.fromOffset(27,87),Size=UDim2.fromOffset(597,146),BackgroundColor3=C.panel})
corner(profile,16);stroke(profile)
local greenLine=new('Frame',profile,{Position=UDim2.fromOffset(0,0),Size=UDim2.fromOffset(3,146),BackgroundColor3=C.green});corner(greenLine,2)
local bigAvatar=new('ImageLabel',profile,{Position=UDim2.fromOffset(20,19),Size=UDim2.fromOffset(68,68),BackgroundColor3=C.hover,Image='rbxthumb://type=AvatarHeadShot&id='..tostring(player.UserId)..'&w=150&h=150'})
corner(bigAvatar,35);stroke(bigAvatar,C.green,2)
label(profile,player.DisplayName,104,23,310,27,19,C.white,true)
label(profile,'@'..player.Name,104,53,300,20,13,C.muted,false)
local role=new('Frame',profile,{Position=UDim2.fromOffset(475,25),Size=UDim2.fromOffset(102,30),BackgroundColor3=C.green})
corner(role,15);label(role,'PREVIEW',16,6,85,18,12,C.white,true)
local function chip(t,x,w)
 local ch=new('Frame',profile,{Position=UDim2.fromOffset(x,103),Size=UDim2.fromOffset(w,28),BackgroundColor3=C.hover})
 corner(ch,14);label(ch,t,12,5,w-20,19,11,C.white,false)
end
chip('◇  Visual concept',20,154);chip('◉  Dark mono',184,129);chip('✦  Blizzard MM2',323,143)

local stats=new('Frame',sc,{Position=UDim2.fromOffset(27,247),Size=UDim2.fromOffset(597,103),BackgroundColor3=C.panel})
corner(stats,16);stroke(stats)
local function stat(x,v,name,color)
 label(stats,v,x,18,160,34,27,C.white,true)
 label(stats,name,x,61,160,22,12,color,true)
end
stat(43,'—','COINS',C.yellow);stat(243,'—','GEMS',C.blue);stat(442,'—','LEVEL',Color3.fromRGB(188,137,255))
for _,x in ipairs({199,398}) do new('Frame',stats,{Position=UDim2.fromOffset(x,17),Size=UDim2.fromOffset(1,68),BackgroundColor3=C.border,BorderSizePixel=0}) end

local lower=new('Frame',sc,{Position=UDim2.fromOffset(27,364),Size=UDim2.fromOffset(597,119),BackgroundColor3=C.panel})
corner(lower,16);stroke(lower)
label(lower,'BLIZZARD',24,20,260,29,23,C.white,true)
label(lower,'Standalone UI concept • No features connected',24,52,540,21,13,C.muted,false)
label(lower,'HOME DASHBOARD PREVIEW',24,86,400,20,11,C.green,true)
local notice=new('Frame',sc,{Position=UDim2.fromOffset(27,497),Size=UDim2.fromOffset(597,79),BackgroundColor3=C.card})
corner(notice,14)
label(notice,'✦  Preview mode',20,12,300,25,16,C.white,true)
label(notice,'Sidebar entries are decorative. Your original Blizzard UI is unchanged.',20,41,555,22,12,C.muted,false)

-- Drag from header (desktop and touch)
local dragging, dragStart, startPos=false,nil,nil
header.InputBegan:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  dragging=true;dragStart=input.Position;startPos=scaleRoot.Position
  input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end)
 end
end)
UserInputService.InputChanged:Connect(function(input)
 if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
  local delta=input.Position-dragStart
  scaleRoot.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
 end
end)
print('[Blizzard Preview] Standalone Star Hub-inspired visual UI loaded. No features connected.')
