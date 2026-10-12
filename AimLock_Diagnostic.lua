-- Blizzard Aim Lock diagnostic | read-only | Shared(8) + Combat 5(2)
local MM2 = (getgenv and getgenv().MM2_V85_SPLIT) or _G.MM2_V85_SPLIT
assert(MM2 and MM2.State and MM2.Flags, 'Load Blizzard Shared.lua first')
local Players = game:GetService('Players')
local UIS = game:GetService('UserInputService')
local RS = game:GetService('ReplicatedStorage')
local lp = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G
if env.BlizzardAimDiag and env.BlizzardAimDiag.Stop then env.BlizzardAimDiag.Stop() end
local gui = Instance.new('ScreenGui')
gui.Name = 'BlizzardAimDiagnostic'
gui.ResetOnSpawn = false
gui.DisplayOrder = 10000
local parent = (gethui and gethui()) or game:GetService('CoreGui')
local ok = pcall(function() gui.Parent = parent end)
if not ok then gui.Parent = lp:WaitForChild('PlayerGui') end
local frame = Instance.new('Frame')
frame.Size = UDim2.fromOffset(196,75)
frame.Position = UDim2.new(0.5,-98,0.16,0)
frame.BackgroundColor3 = Color3.fromRGB(23,25,33)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new('UICorner',frame).CornerRadius = UDim.new(0,10)
local title = Instance.new('TextLabel')
title.BackgroundTransparency = 1
title.Size = UDim2.new(1,0,0,29)
title.Text = 'AIM LOCK DIAGNOSTIC'
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.Parent = frame
local copy = Instance.new('TextButton')
copy.Position = UDim2.fromOffset(10,34)
copy.Size = UDim2.new(1,-20,0,32)
copy.BackgroundColor3 = Color3.fromRGB(67,113,235)
copy.Text = 'COPY'
copy.TextColor3 = Color3.new(1,1,1)
copy.Font = Enum.Font.GothamBold
copy.TextSize = 14
copy.Parent = frame
Instance.new('UICorner',copy).CornerRadius = UDim.new(0,7)
local D = {Running=true, Lines={}, Gui=gui}
env.BlizzardAimDiag = D
local start = os.clock()
local function log(line)
  table.insert(D.Lines,string.format('+%.2fs %s',os.clock()-start,line))
  if #D.Lines > 600 then table.remove(D.Lines,1) end
end
local function value(v) if v == nil then return 'nil' end return tostring(v) end
local function snapshot(raw, remoteStatus)
  local state = MM2.State
  local char = lp.Character
  local hum = char and char:FindFirstChildOfClass('Humanoid')
  local root = char and char:FindFirstChild('HumanoidRootPart')
  local data = type(raw)=='table' and raw[lp.Name] or nil
  local role = type(data)=='table' and data.Role or nil
  local camera = workspace.CurrentCamera
  local spec = MM2.GetSpectatedPlayer and MM2.GetSpectatedPlayer()
  local firstPerson = camera and (camera.CFrame.Position-camera.Focus.Position).Magnitude <= 1.1 or false
  local shift = UIS.MouseBehavior == Enum.MouseBehavior.LockCenter
  local murdererName = state.ServerMurder
  local murderer = murdererName and Players:FindFirstChild(murdererName)
  local mchar = murderer and murderer.Character
  local mh = mchar and mchar:FindFirstChildOfClass('Humanoid')
  local targetPart = mchar and (mchar:FindFirstChild('UpperTorso') or mchar:FindFirstChild('Torso') or mchar:FindFirstChild('HumanoidRootPart'))
  local targetRole = murderer and MM2.GetPlayerRole and MM2.GetPlayerRole(murderer)
  local countdown = MM2.IsCountdownActive and MM2.IsCountdownActive()
  local combatPreRound = not (state.GameplayRoundActive == true and state.RoleRoundActive == true and not state.SuppressStaleRoles)
  local currentGate = MM2.Flags.AimLock == true and (firstPerson or shift) and state.RoleRoundActive == true and state.GameplayRoundActive == true and not combatPreRound
  return table.concat({
    'role='..value(role), 'dead='..value(type(data)=='table' and data.Dead or nil),
    'killed='..value(type(data)=='table' and data.Killed or nil),
    'health='..value(hum and math.floor(hum.Health) or nil),
    'spectating='..value(spec and spec.Name or false),
    'round='..value(state.RoleRoundActive), 'gameplay='..value(state.GameplayRoundActive),
    'stale='..value(state.SuppressStaleRoles), 'countdown='..value(countdown),
    'aimToggle='..value(MM2.Flags.AimLock), 'firstPerson='..value(firstPerson),
    'shiftLock='..value(shift), 'combatGate='..value(currentGate),
    'target='..value(murdererName), 'targetRole='..value(targetRole),
    'targetAlive='..value(mh and mh.Health > 0 or false),
    'targetPart='..value(targetPart ~= nil),
    'position='..value(root and string.format('%.0f,%.0f,%.0f',root.Position.X,root.Position.Y,root.Position.Z) or nil),
    'remote='..remoteStatus
  },' | ')
end
local last = nil
log('START | Shared(8) 904 lines | Combat 5(2) 1386 lines')
log('Combat requires GameplayRoundActive=true; Shared(8) does not initialize that flag')
function D.Stop() D.Running=false; if gui then gui:Destroy() end end
copy.MouseButton1Click:Connect(function()
  log('COPY PRESSED')
  local output = table.concat(D.Lines,'\n')
  if setclipboard then
    local success = pcall(setclipboard,output)
    copy.Text = success and 'COPIED!' or 'COPY FAILED'
  else
    copy.Text = 'NO CLIPBOARD'
    print(output)
  end
  task.delay(1.5,function() if copy and copy.Parent then copy.Text='COPY' end end)
end)
task.spawn(function()
  while D.Running and gui.Parent do
    local raw, status
    local remote = MM2.State.GetPlayerDataRemote
    if not remote or not remote.Parent then remote = RS:FindFirstChild('GetPlayerData',true) end
    if remote and remote:IsA('RemoteFunction') then
      local success, result = pcall(function() return remote:InvokeServer() end)
      raw = success and result or nil
      status = success and 'ok' or 'failed'
    else status='missing' end
    local success, result = pcall(snapshot,raw,status)
    if success then
      -- Position changes are intentionally logged when large enough to reveal teleports.
      local stable = result:gsub('position=[^|]+','position=*')
      if stable ~= last then log(result); last=stable end
    else log('SNAPSHOT ERROR '..tostring(result)) end
    task.wait(0.35)
  end
end)
