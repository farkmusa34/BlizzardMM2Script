-- Blizzard MM2 Round State Diagnostic GUI - observation only
-- Run after Shared.lua, UI.lua and Combat.lua. Press START while in lobby before countdown.
local MM2 = (getgenv and getgenv().MM2_V85_SPLIT) or _G.MM2_V85_SPLIT
assert(MM2 and MM2.State and MM2.Services, "Load Shared.lua first")
local S, state = MM2.Services, MM2.State
local players, rs = S.Players, S.ReplicatedStorage
local player = MM2.LocalPlayer or players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local old = playerGui:FindFirstChild("BlizzardRoundDiagnosticGUI")
if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name="BlizzardRoundDiagnosticGUI"; gui.ResetOnSpawn=false; gui.DisplayOrder=900; gui.Parent=playerGui
local panel=Instance.new("Frame")
panel.Size=UDim2.fromOffset(390,310); panel.Position=UDim2.new(0.5,-195,0.25,0)
panel.BackgroundColor3=Color3.fromRGB(20,24,35); panel.BorderSizePixel=0; panel.Active=true; panel.Draggable=true; panel.Parent=gui
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,12)
local function label(text,y,h,size)
 local x=Instance.new("TextLabel"); x.Size=UDim2.new(1,-20,0,h); x.Position=UDim2.fromOffset(10,y)
 x.BackgroundTransparency=1; x.TextColor3=Color3.fromRGB(238,241,255); x.TextSize=size or 14
 x.Font=Enum.Font.Gotham; x.TextXAlignment=Enum.TextXAlignment.Left; x.TextWrapped=true; x.Text=text; x.Parent=panel; return x
end
label("Blizzard • Round State Diagnostic",10,25,17)
local status=label("Ready — press Start while in lobby, before countdown",39,38,12)
local function button(text,x,width)
 local b=Instance.new("TextButton"); b.Size=UDim2.fromOffset(width,35); b.Position=UDim2.fromOffset(x,83)
 b.BackgroundColor3=Color3.fromRGB(44,106,200); b.TextColor3=Color3.new(1,1,1)
 b.Font=Enum.Font.GothamBold; b.TextSize=13; b.Text=text; b.Parent=panel
 Instance.new("UICorner",b).CornerRadius=UDim.new(0,7); return b
end
local startBtn=button("Start",10,115)
local stopBtn=button("Stop",135,115)
local copyBtn=button("Copy Logs",260,120)
local scroll=Instance.new("ScrollingFrame"); scroll.Size=UDim2.new(1,-20,1,-136)
scroll.Position=UDim2.fromOffset(10,126); scroll.BackgroundColor3=Color3.fromRGB(11,15,24)
scroll.BorderSizePixel=0; scroll.ScrollBarThickness=4; scroll.Parent=panel
Instance.new("UICorner",scroll).CornerRadius=UDim.new(0,7)
local output=Instance.new("TextLabel"); output.Size=UDim2.new(1,-10,0,1); output.Position=UDim2.fromOffset(5,5)
output.BackgroundTransparency=1; output.TextColor3=Color3.fromRGB(197,222,255)
output.Font=Enum.Font.Code; output.TextSize=11; output.TextWrapped=true
output.TextXAlignment=Enum.TextXAlignment.Left; output.TextYAlignment=Enum.TextYAlignment.Top
output.Text="Press Start to begin capturing state changes."; output.Parent=scroll
local logs,connections={},{}
local running=false; local generation=0; local startTime=0; local last=nil
local function redraw()
 output.Text=table.concat(logs,"\n")
 task.defer(function()
  if not output.Parent then return end
  local textService=game:GetService("TextService")
  local width=math.max(100,scroll.AbsoluteSize.X-20)
  local size=textService:GetTextSize(output.Text,11,Enum.Font.Code,Vector2.new(width,100000))
  output.Size=UDim2.new(1,-10,0,math.max(1,size.Y+10))
  scroll.CanvasSize=UDim2.fromOffset(0,math.max(1,size.Y+20))
  scroll.CanvasPosition=Vector2.new(0,math.max(0,scroll.CanvasSize.Y.Offset-scroll.AbsoluteSize.Y))
 end)
end
local function log(message)
 local line=string.format("[Blizzard RoundDiag +%.2fs] %s",os.clock()-startTime,message)
 table.insert(logs,line); print(line); redraw()
end
local function countRoles()
 local cache=state.ServerRolesCache or {}; local m,s,h=0,0,0
 for _,v in pairs(cache) do
  local role=type(v)=="table" and (v.Role or v.role) or v
  if role=="Murderer" then m=m+1 elseif role=="Sheriff" then s=s+1 elseif role=="Hero" then h=h+1 end
 end
 return m,s,h
end
local function roundToolsPresent()
 for _,p in ipairs(players:GetPlayers()) do
  local char=p.Character
  if char then for _,item in ipairs(char:GetChildren()) do
   if item:IsA("Tool") and (item.Name=="Knife" or item.Name=="Gun" or item.Name=="Revolver") then return true end
  end end
 end
 return false
end
local function phaseText()
 local pg=MM2.PlayerGui or playerGui
 for _,obj in ipairs(pg:GetDescendants()) do
  if obj:IsA("TextLabel") or obj:IsA("TextButton") then
   local v=string.lower(tostring(obj.Text or ""))
   if v:find("intermission",1,true) or v:find("game starts",1,true) or v:find("starting in",1,true) or v:find("waiting for",1,true) or v:find("voting",1,true) then
    local ok,visible=pcall(function() return MM2.IsActuallyVisible and MM2.IsActuallyVisible(obj) or obj.Visible end)
    if ok and visible then return v:sub(1,70) end
   end
  end
 end
 return "none"
end
local function sample()
 local m,s,h=countRoles()
 local camera=workspace.CurrentCamera
 local targetDistance="none"
 if camera and state.ServerMurder then
  local target=players:FindFirstChild(tostring(state.ServerMurder))
  local root=target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
  if root then targetDistance=tostring(math.floor((root.Position-camera.CFrame.Position).Magnitude+0.5)) end
 end
 local precheck="unavailable"
 if MM2.IsPreRoundActive then local ok,result=pcall(MM2.IsPreRoundActive); precheck=ok and tostring(result) or "ERROR" end
 local signature=table.concat({
  "roleActive="..tostring(state.RoleRoundActive),
  "gameplayActive="..tostring(state.GameplayRoundActive),
  "staleSuppressed="..tostring(state.SuppressStaleRoles),
  "roles(M/S/H)="..m.."/"..s.."/"..h,
  "coins="..tostring(workspace:FindFirstChild("CoinContainer",true)~=nil),
  "gunDrop="..tostring(workspace:FindFirstChild("GunDrop",true)~=nil),
  "equippedWeapon="..tostring(roundToolsPresent()),
  "pregameCheck="..precheck,
  "phaseText="..phaseText(),
  "aimLockEnabled="..tostring(MM2.Flags and MM2.Flags.AimLock),
  "murderDistanceStuds="..targetDistance
 }," | ")
 if signature~=last then last=signature; log(signature) end
end
local function disconnect()
 for _,c in ipairs(connections) do pcall(function() c:Disconnect() end) end
 table.clear(connections)
end
local function stop()
 if not running then return end
 running=false; generation=generation+1; disconnect(); log("Stopped")
 status.Text="Stopped — press Copy Logs and paste into chat"
end
startBtn.MouseButton1Click:Connect(function()
 if running then return end
 table.clear(logs); last=nil; running=true; generation=generation+1
 local myGeneration=generation; startTime=os.clock()
 status.Text="Recording — keep running through pregame, round and victory"
 log("START: capture lobby -> countdown -> active round -> victory")
 local remotes=rs:FindFirstChild("Remotes"); local gameplay=remotes and remotes:FindFirstChild("Gameplay")
 for _,name in ipairs({"RoundStart","CoinsStarted","VictoryScreen"}) do
  local remote=gameplay and gameplay:FindFirstChild(name)
  if remote and remote:IsA("RemoteEvent") then
   table.insert(connections,remote.OnClientEvent:Connect(function(...)
    if running then log("EVENT "..name.." | roleActive="..tostring(state.RoleRoundActive).." | gameplayActive="..tostring(state.GameplayRoundActive)) end
   end))
   log("Watching event: "..name)
  else log("Event unavailable: "..name) end
 end
 task.spawn(function()
  while running and generation==myGeneration and MM2.Running do
   local ok,err=pcall(sample)
   if not ok then log("SAMPLE ERROR: "..tostring(err)) end
   task.wait(0.25)
  end
 end)
end)
stopBtn.MouseButton1Click:Connect(stop)
copyBtn.MouseButton1Click:Connect(function()
 local value=table.concat(logs,"\n")
 if #value==0 then status.Text="No logs yet — press Start first"; return end
 local copyFn=setclipboard or toclipboard
 if type(copyFn)=="function" then
  local ok,err=pcall(copyFn,value)
  status.Text=ok and ("Copied "..#logs.." lines — paste into chat") or ("Copy failed: "..tostring(err))
 else
  status.Text="Clipboard unavailable; select logs or use console output"
 end
end)
gui.Destroying:Connect(function() running=false; generation=generation+1; disconnect() end)
print("[Blizzard RoundDiag] GUI ready; press Start in lobby before pregame countdown")
