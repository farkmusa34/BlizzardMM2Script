local MM2 = getgenv and getgenv().MM2_V85_SPLIT or _G.MM2_V85_SPLIT
assert(MM2 and MM2.UI and MM2.UI.CombatPage, "Load Shared.lua + UI.lua first")

local Players = MM2.Services.Players
local RunService = MM2.Services.RunService
local UIS = MM2.Services.UserInputService
local LocalPlayer = MM2.LocalPlayer
local Flags = MM2.Flags
local UI = MM2.UI
local Track = MM2.Track

-- Combat UI should still load even if Visuals.lua has not created TracerGui yet.
local CombatOverlay = UI.TracerGui or UI.ScreenGui
assert(CombatOverlay, "Combat overlay GUI not found")

local function CombatNotify(title,content,icon,duration)
	local wind = UI.WindUI
	if wind and wind.Notify then
		local ok = pcall(function()
			wind:Notify({
				Title = tostring(title or "Combat"),
				Content = tostring(content or ""),
				Icon = tostring(icon or "info"),
				Duration = tonumber(duration) or 2.5,
			})
		end)
		if ok then return end
	end
	if MM2.Notify then
		pcall(MM2.Notify,tostring(content or title or "Combat"),tonumber(duration) or 2.5,icon,title)
	end
end

local function NormalizeShootMessage(message)
	if message == "No Murderer"
		or message == "No Gun"
		or message == "No Target"
	then
		return "No Gun or Murderer"
	end
	return message
end

local function NotifyShootResult(success,message)
	message = NormalizeShootMessage(message)
	if success then
		CombatNotify("Shoot Murderer",message or "Shot Fired","check",1.8)
	elseif message and message ~= "Cooldown" and message ~= "Busy" then
		CombatNotify("Shoot Murderer",message,"x",2.5)
	end
end

local function NormalizeKillAllMessage(message)
	if message == "No Knife" or message == "Murderer Role Required" then
		return "Murderer Role Required"
	end
	return message
end

local function NotifyKillAllResult(success,message)
	message = NormalizeKillAllMessage(message)
	if success then
		CombatNotify("Kill All",message or "Activated","check",1.8)
	elseif message and message ~= "Cooldown" and message ~= "Busy" then
		CombatNotify("Kill All",message,"x",2.5)
	end
end

UI.AddSection(UI.CombatPage, "Aim", "Crosshair and aiming features")
UI.CreateToggle(UI.CombatPage, "TriggerBot", "Fire when the crosshair is on the murderer", "TriggerBot")
UI.CreateToggle(UI.CombatPage, "Aim Lock", "Torso aim lock in first-person / lock-center", "AimLock")

UI.AddSection(UI.CombatPage, "Sheriff", "Legit and rage gun features")
UI.CreateToggle(UI.CombatPage, "Shoot Murderer (Legit)", "Requires clear line of sight; does not shoot through walls", "ShowLegitShootButton", function(on)
	if MM2.UI.FloatingLegitShootHolder then
		MM2.UI.FloatingLegitShootHolder.Visible = on
	elseif MM2.UI.FloatingLegitShootButton then
		MM2.UI.FloatingLegitShootButton.Visible = on
	end
end)
UI.CreateToggle(UI.CombatPage, "Shoot Murderer (Rage)", "Keeps the current behavior and can attempt shots through walls", "ShowShootButton", function(on)
	if MM2.UI.FloatingShootHolder then
		MM2.UI.FloatingShootHolder.Visible = on
	elseif MM2.UI.FloatingShootButton then
		MM2.UI.FloatingShootButton.Visible = on
	end
end)
UI.CreateToggle(UI.CombatPage, "Auto Grab Gun", "Automatically grabs the gun without moving your body", "AutoGrab")

UI.AddSection(UI.CombatPage, "Murderer", "Legit and rage knife features")

local RenderLegitThrow
local RenderRageThrow

local function SetThrowToggle(flagName,value)
	Flags[flagName] = value == true
	if flagName == "LegitThrow" and RenderLegitThrow then
		RenderLegitThrow(Flags[flagName],false)
	elseif flagName == "RageThrow" and RenderRageThrow then
		RenderRageThrow(Flags[flagName],false)
	end
	if UI.SetToggleState then
		UI.SetToggleState(flagName,Flags[flagName],false)
	end
end

do
	local _,_,render = UI.CreateToggle(UI.CombatPage, "Auto Throw Knife (Legit)", "Automatically throws only when the target has clear line of sight", "LegitThrow", function(on)
		if on then SetThrowToggle("RageThrow",false) end
	end)
	RenderLegitThrow = render
end

do
	local _,_,render = UI.CreateToggle(UI.CombatPage, "Auto Throw Knife (Rage)", "Keeps the existing auto-throw behavior and can target through walls", "RageThrow", function(on)
		if on then SetThrowToggle("LegitThrow",false) end
	end)
	RenderRageThrow = render
end

if Flags.LegitThrow and Flags.RageThrow then
	SetThrowToggle("RageThrow",false)
end

local KNIFE_RANGE_MIN = 5
local KNIFE_RANGE_MAX = 1000
Flags.KnifeRange = math.clamp(tonumber(Flags.KnifeRange) or 25,KNIFE_RANGE_MIN,KNIFE_RANGE_MAX)

UI.CreateSlider(
	UI.CombatPage,
	"Knife Range",
	"Extends one knife activation to every live player inside the selected range",
	function() return Flags.KnifeRange end,
	function(value)
		Flags.KnifeRange = math.clamp(tonumber(value) or 25,KNIFE_RANGE_MIN,KNIFE_RANGE_MAX)
	end,
	KNIFE_RANGE_MIN,KNIFE_RANGE_MAX,5
)

UI.CreateActionFeature(UI.CombatPage, "Kill All", "Uses one knife activation at maximum Knife Range", function()
	if MM2.Functions.KillAllOnce then
		local ok,success,message = pcall(MM2.Functions.KillAllOnce)
		if not ok then
			warn("[MM2 KILL ALL ACTION]",success)
			CombatNotify("Kill All","Kill All error","x",2)
		else
			NotifyKillAllResult(success,message)
		end
	end
end)

Flags.ShowKillAllButton = Flags.ShowKillAllButton == true
UI.CreateToggle(UI.CombatPage, "Show Kill All Button", "stab all button", "ShowKillAllButton", function(on)
	if MM2.UI.FloatingKillAllHolder then MM2.UI.FloatingKillAllHolder.Visible = on end
end)

local CrosshairDot = Instance.new("Frame")
CrosshairDot.Name = "CrosshairDot"
CrosshairDot.AnchorPoint = Vector2.new(0.5,0.5)
CrosshairDot.Position = UDim2.new(0.5,0,0.5,0)
CrosshairDot.Size = UDim2.fromOffset(4,4)
CrosshairDot.BackgroundColor3 = Color3.fromRGB(255,255,255)
CrosshairDot.BorderSizePixel = 0
CrosshairDot.Visible = false
CrosshairDot.ZIndex = 100
CrosshairDot.Parent = CombatOverlay

local AIMLOCK_FOV = 150
local COMBAT_MAX_DISTANCE = 2000
local SHOT_COOLDOWN = 1.5
local LastTriggerShot = 0
local LastManualShot = 0
local ShootBusy = false

local function GetCombatTorso(character)
	if not character then return nil end
	return character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
		or character:FindFirstChild("HumanoidRootPart")
end

--============================================================
-- REAL SHOOT PATH DIAGNOSTIC
-- Observes the production SHOOT / RAGE SHOOT path.
-- It does not change the 0.12 second wait or shot arguments.
--============================================================

local ShootDiagnostic = {
	Logs = {},
	ShotNumber = 0,
	Current = nil,
}

local function ShootDiagVec(v)
	if typeof(v) ~= "Vector3" then return "nil" end
	return string.format("(%.3f, %.3f, %.3f)",v.X,v.Y,v.Z)
end

local function ShootDiagLog(text)
	text = tostring(text)
	table.insert(ShootDiagnostic.Logs,text)
	print("[REAL SHOOT DIAG] "..text)
end

local function ShootDiagLOS(targetPart)
	local character = LocalPlayer.Character
	if not character or not targetPart or not targetPart.Parent then return false,"nil" end
	local originPart = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
	if not originPart then return false,"nil" end
	local direction = targetPart.Position-originPart.Position
	if direction.Magnitude <= 0.1 then return true,"target" end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}
	params.IgnoreWater = true
	local result = workspace:Raycast(originPart.Position,direction,params)
	if not result then return true,"nil" end
	return result.Instance:IsDescendantOf(targetPart.Parent),result.Instance:GetFullName()
end

local function ShootDiagBegin(mode,murderer,targetPart)
	ShootDiagnostic.ShotNumber += 1
	local shot = {
		Number = ShootDiagnostic.ShotNumber,
		Mode = mode,
		Player = murderer,
		Character = murderer and murderer.Character,
		StartTime = os.clock(),
	}
	ShootDiagLog("============================================================")
	ShootDiagLog("REAL COMBAT SHOT #"..shot.Number)
	ShootDiagLog("Mode="..tostring(mode))
	ShootDiagLog("ProductionTaskWait=0.120s")
	ShootDiagLog("Target="..tostring(murderer and murderer.Name or "nil"))
	if targetPart then
		shot.BeforePosition = targetPart.Position
		shot.BeforeVelocity = targetPart.AssemblyLinearVelocity
		ShootDiagLog("BEFORE WAIT Part="..targetPart.Name.." Pos="..ShootDiagVec(shot.BeforePosition).." Vel="..ShootDiagVec(shot.BeforeVelocity))
		ShootDiagLog(string.format("BEFORE WAIT Speed=%.3f",shot.BeforeVelocity.Magnitude))
		local clear,hit = ShootDiagLOS(targetPart)
		ShootDiagLog("BEFORE WAIT LOS="..tostring(clear).." Hit="..tostring(hit))
	end
	return shot
end

local function ShootDiagAfterWait(shot,targetPart)
	if not shot or not targetPart then return end
	shot.AfterWaitTime = os.clock()-shot.StartTime
	shot.AfterPosition = targetPart.Position
	shot.AfterVelocity = targetPart.AssemblyLinearVelocity
	ShootDiagLog(string.format("AFTER WAIT ActualElapsed=%.3fms",shot.AfterWaitTime*1000))
	ShootDiagLog("AFTER WAIT Part="..targetPart.Name.." Pos="..ShootDiagVec(shot.AfterPosition).." Vel="..ShootDiagVec(shot.AfterVelocity))
	if shot.BeforePosition then
		ShootDiagLog(string.format("MovementDuringWait=%.3f studs",(shot.AfterPosition-shot.BeforePosition).Magnitude))
	end
	local clear,hit = ShootDiagLOS(targetPart)
	ShootDiagLog("AFTER WAIT LOS="..tostring(clear).." Hit="..tostring(hit))
end

local function ShootDiagObserveResult(shot)
	if not shot or not shot.Player then return end
	task.spawn(function()
		local sent = shot.FireTime or os.clock()
		local originalCharacter = shot.Character
		local deathTime = nil
		for _,checkpoint in ipairs({0.05,0.10,0.20,0.40,0.80}) do
			local remaining = checkpoint-(os.clock()-sent)
			if remaining > 0 then task.wait(remaining) end
			local character = shot.Player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local part = GetCombatTorso(character)
			local health = humanoid and humanoid.Health or -1
			if humanoid and humanoid.Health <= 0 and not deathTime then
				deathTime = os.clock()-sent
			end
			ShootDiagLog(string.format("+%03dms Health=%.1f Pos=%s",checkpoint*1000,health,part and ShootDiagVec(part.Position) or "nil"))
		end
		if deathTime and shot.Player.Character == originalCharacter then
			ShootDiagLog(string.format("RESULT=HIT DeathAt=%.2fms",deathTime*1000))
		else
			ShootDiagLog("RESULT=MISS/NO DEATH OBSERVED")
		end
		ShootDiagLog("============================================================")
	end)
end

-- Small mobile-friendly log panel. It only copies/clears diagnostic logs.
do
	local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if playerGui then
		local old = playerGui:FindFirstChild("BlizzardRealShootDiagnostic")
		if old then old:Destroy() end
		local gui = Instance.new("ScreenGui")
		gui.Name = "BlizzardRealShootDiagnostic"
		gui.ResetOnSpawn = false
		gui.DisplayOrder = 999999
		gui.Parent = playerGui

		local frame = Instance.new("Frame")
		frame.Size = UDim2.fromOffset(280,118)
		frame.Position = UDim2.new(0.5,-140,0.12,0)
		frame.BackgroundColor3 = Color3.fromRGB(18,20,27)
		frame.BorderSizePixel = 0
		frame.Active = true
		frame.Parent = gui
		Instance.new("UICorner",frame).CornerRadius = UDim.new(0,12)
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(60,170,255)
		stroke.Thickness = 1.5
		stroke.Parent = frame

		local title = Instance.new("TextLabel")
		title.BackgroundTransparency = 1
		title.Position = UDim2.fromOffset(12,8)
		title.Size = UDim2.new(1,-24,0,24)
		title.Font = Enum.Font.GothamBold
		title.TextSize = 14
		title.TextColor3 = Color3.new(1,1,1)
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Text = "REAL SHOOT DIAGNOSTIC"
		title.Parent = frame

		local status = Instance.new("TextLabel")
		status.BackgroundTransparency = 1
		status.Position = UDim2.fromOffset(12,34)
		status.Size = UDim2.new(1,-24,0,28)
		status.Font = Enum.Font.Gotham
		status.TextSize = 11
		status.TextColor3 = Color3.fromRGB(220,225,235)
		status.TextWrapped = true
		status.TextXAlignment = Enum.TextXAlignment.Left
		status.Text = "Use the real SHOOT button, then Copy Logs."
		status.Parent = frame

		local copy = Instance.new("TextButton")
		copy.Position = UDim2.fromOffset(12,72)
		copy.Size = UDim2.fromOffset(160,34)
		copy.BackgroundColor3 = Color3.fromRGB(31,35,46)
		copy.BorderSizePixel = 0
		copy.Font = Enum.Font.GothamBold
		copy.TextSize = 12
		copy.TextColor3 = Color3.new(1,1,1)
		copy.Text = "COPY LOGS"
		copy.Parent = frame
		Instance.new("UICorner",copy).CornerRadius = UDim.new(0,8)

		local clear = Instance.new("TextButton")
		clear.Position = UDim2.fromOffset(180,72)
		clear.Size = UDim2.fromOffset(88,34)
		clear.BackgroundColor3 = Color3.fromRGB(31,35,46)
		clear.BorderSizePixel = 0
		clear.Font = Enum.Font.GothamBold
		clear.TextSize = 12
		clear.TextColor3 = Color3.new(1,1,1)
		clear.Text = "CLEAR"
		clear.Parent = frame
		Instance.new("UICorner",clear).CornerRadius = UDim.new(0,8)

		copy.Activated:Connect(function()
			local text = table.concat(ShootDiagnostic.Logs,"\n")
			if setclipboard then
				local ok = pcall(setclipboard,text)
				status.Text = ok and ("Copied "..#ShootDiagnostic.Logs.." lines") or "Copy failed"
			else
				status.Text = "setclipboard unavailable"
			end
		end)

		clear.Activated:Connect(function()
			table.clear(ShootDiagnostic.Logs)
			ShootDiagnostic.ShotNumber = 0
			status.Text = "Logs cleared"
		end)

		local dragging,dragStart,startPos = false,nil,nil
		frame.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				dragStart = input.Position
				startPos = frame.Position
			end
		end)
		UIS.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
				local delta = input.Position-dragStart
				frame.Position = UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
			end
		end)
		UIS.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
			end
		end)
	end
end

ShootDiagLog("REAL SHOOT DIAGNOSTIC LOADED")
ShootDiagLog("ProductionTaskWait=0.120s")
ShootDiagLog("TriggerBot logic unchanged=true")

local function IsLivePlayer(player)
	if not player or player == LocalPlayer then return false end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return character ~= nil and humanoid ~= nil and humanoid.Health > 0
end

local function IsMurderer(player)
	if not IsLivePlayer(player) then return false end
	local ok, role = pcall(function()
		return MM2.GetPlayerRole(player)
	end)
	if ok and role == "Murderer" then
		return true
	end
	return MM2.State
		and MM2.State.ServerRolesCache
		and MM2.State.ServerRolesCache[player.Name] == "Murderer"
end

local function FindLiveMurderer()
	for _, player in ipairs(Players:GetPlayers()) do
		if IsMurderer(player) then
			return player
		end
	end
	return nil
end

local function HasClearLineOfSight(targetPart)
	local character = LocalPlayer.Character
	if not character or not targetPart or not targetPart.Parent then return false end
	local originPart = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
	if not originPart then return false end
	local direction = targetPart.Position-originPart.Position
	if direction.Magnitude <= 0.1 then return true end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}
	params.IgnoreWater = true
	local result = workspace:Raycast(originPart.Position,direction,params)
	return result == nil or result.Instance:IsDescendantOf(targetPart.Parent)
end

local function IsAimLockAllowed()
	local camera = workspace.CurrentCamera
	local character = LocalPlayer.Character
	if not camera or not character then return false end
	local head = character:FindFirstChild("Head")
	if head and (camera.CFrame.Position-head.Position).Magnitude < 1 then
		return true
	end
	return UIS.MouseBehavior == Enum.MouseBehavior.LockCenter
end

local function GetBestCombatTarget()
	local camera = workspace.CurrentCamera
	if not camera then return nil,nil end
	local viewport = camera.ViewportSize
	local center = Vector2.new(viewport.X/2,viewport.Y/2)
	local bestPlayer,bestPart,bestDistance = nil,nil,AIMLOCK_FOV
	for _,player in ipairs(Players:GetPlayers()) do
		if IsMurderer(player) then
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local torso = GetCombatTorso(character)
			if humanoid and humanoid.Health > 0 and torso
				and MM2.IsPositionWithinESPDistance(torso.Position)
			then
				local screenPosition,onScreen = camera:WorldToViewportPoint(torso.Position)
				if onScreen and screenPosition.Z > 0 then
					local d = (Vector2.new(screenPosition.X,screenPosition.Y)-center).Magnitude
					if d < bestDistance then
						bestDistance,bestPlayer,bestPart = d,player,torso
					end
				end
			end
		end
	end
	return bestPlayer,bestPart
end

local function GetCombatCrosshairHit()
	local camera = workspace.CurrentCamera
	local character = LocalPlayer.Character
	if not camera or not character then return nil end
	local viewport = camera.ViewportSize
	local ray = camera:ViewportPointToRay(viewport.X/2,viewport.Y/2)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}
	params.IgnoreWater = true
	return workspace:Raycast(ray.Origin,ray.Direction*COMBAT_MAX_DISTANCE,params)
end

local function ResolveCombatPlayer(instance)
	if not instance then return nil end
	local current = instance
	while current and current ~= workspace do
		if current:IsA("Model") then
			local player = Players:GetPlayerFromCharacter(current)
			if player then return player end
		end
		current = current.Parent
	end
	return nil
end

local function GetCombatGun()
	local character = LocalPlayer.Character
	if not character then return nil end
	local gun = character:FindFirstChild("Gun") or character:FindFirstChild("Revolver")
	if gun and gun:IsA("Tool") then
		return gun
	end
	return nil
end

local function GetBackpackGun()
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	if not backpack then return nil end
	local gun = backpack:FindFirstChild("Gun") or backpack:FindFirstChild("Revolver")
	if gun and gun:IsA("Tool") then
		return gun
	end
	return nil
end

local function EnsureCombatGun()
	local gun = GetCombatGun()
	if gun then
		return gun
	end
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local backpackGun = GetBackpackGun()
	if not humanoid or humanoid.Health <= 0 or not backpackGun then
		return nil
	end
	local ok = pcall(function()
		humanoid:EquipTool(backpackGun)
	end)
	if not ok then
		return nil
	end
	local deadline = os.clock()+0.75
	repeat
		task.wait(0.03)
		gun = GetCombatGun()
	until gun or os.clock() >= deadline
	return gun
end

local function FireCombatGun(gun,targetPosition)
	if not gun or typeof(targetPosition) ~= "Vector3" then
		return false
	end
	local character = LocalPlayer.Character
	if not character or gun.Parent ~= character then
		return false
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local shoot = gun:FindFirstChild("Shoot")
	if not shoot or not shoot:IsA("RemoteEvent") then
		return false
	end
	local direction = targetPosition-hrp.Position
	if direction.Magnitude <= 0.1 then
		return false
	end
	local unitDirection = direction.Unit
	local originCFrame = CFrame.new(
		targetPosition-unitDirection*2,
		targetPosition
	)
	local destinationCFrame = CFrame.new(targetPosition)

	local diagnosticShot = ShootDiagnostic.Current
	if diagnosticShot then
		diagnosticShot.FireTime = os.clock()
		diagnosticShot.TargetPosition = targetPosition
		ShootDiagLog("FIRE TargetPosition="..ShootDiagVec(targetPosition))
		ShootDiagLog("FIRE ShooterHRP="..ShootDiagVec(hrp.Position))
		ShootDiagLog(string.format("FIRE Distance=%.3f",direction.Magnitude))
		ShootDiagLog("FIRE Origin="..ShootDiagVec(originCFrame.Position))
		ShootDiagLog("FIRE Destination="..ShootDiagVec(destinationCFrame.Position))
		ShootDiagLog(string.format("StartToFireServer=%.3fms",(diagnosticShot.FireTime-diagnosticShot.StartTime)*1000))
	end

	local beforeFire = os.clock()
	shoot:FireServer(originCFrame,destinationCFrame)
	local afterFire = os.clock()

	if diagnosticShot then
		ShootDiagLog(string.format("FireServerCall=%.3fms",(afterFire-beforeFire)*1000))
		ShootDiagnostic.Current = nil
		ShootDiagObserveResult(diagnosticShot)
	end
	return true
end

MM2.Functions.ShootMurderer = function()
	if ShootBusy then
		return false,"Busy"
	end
	local now = os.clock()
	if now-LastManualShot < SHOT_COOLDOWN then
		return false,"Cooldown"
	end
	ShootBusy = true
	local ok, success, message = pcall(function()
		local murderer = FindLiveMurderer()
		if not murderer then
			return false,"No Gun or Murderer"
		end
		local torso = GetCombatTorso(murderer.Character)
		if not torso then
			return false,"No Gun or Murderer"
		end
		local gun = EnsureCombatGun()
		if not gun then
			return false,"No Gun or Murderer"
		end
		local diagnosticShot = ShootDiagBegin("RAGE SHOOT",murderer,torso)
		task.wait(0.12)
		if not IsLivePlayer(murderer) then
			ShootDiagLog("ABORT=Target no longer live after wait")
			return false,"No Gun or Murderer"
		end
		torso = GetCombatTorso(murderer.Character)
		if not torso then
			ShootDiagLog("ABORT=No target part after wait")
			return false,"No Gun or Murderer"
		end
		ShootDiagAfterWait(diagnosticShot,torso)
		ShootDiagnostic.Current = diagnosticShot
		local fired = FireCombatGun(gun,torso.Position)
		if not fired then
			return false,"Shot Failed"
		end
		LastManualShot = os.clock()
		return true,"Shot Fired"
	end)
	ShootBusy = false
	if not ok then
		warn("[MM2 V8.6.1 SHOOT ERROR]",success)
		return false,"Error"
	end
	return success,message
end

MM2.Functions.ShootMurdererLegit = function()
	if ShootBusy then return false,"Busy" end
	local now = os.clock()
	if now-LastManualShot < SHOT_COOLDOWN then return false,"Cooldown" end
	ShootBusy = true
	local ok,success,message = pcall(function()
		local murderer = FindLiveMurderer()
		if not murderer then return false,"No Gun or Murderer" end
		local torso = GetCombatTorso(murderer.Character)
		if not torso then return false,"No Gun or Murderer" end
		if not HasClearLineOfSight(torso) then return false,"Murderer Behind Wall" end
		local gun = EnsureCombatGun()
		if not gun then return false,"No Gun or Murderer" end
		local diagnosticShot = ShootDiagBegin("LEGIT SHOOT",murderer,torso)
		task.wait(0.12)
		if not IsLivePlayer(murderer) then
			ShootDiagLog("ABORT=Target no longer live after wait")
			return false,"No Gun or Murderer"
		end
		torso = GetCombatTorso(murderer.Character)
		if not torso then
			ShootDiagLog("ABORT=No target part after wait")
			return false,"No Gun or Murderer"
		end
		ShootDiagAfterWait(diagnosticShot,torso)
		if not HasClearLineOfSight(torso) then
			ShootDiagLog("ABORT=Murderer Behind Wall after wait")
			return false,"Murderer Behind Wall"
		end
		ShootDiagnostic.Current = diagnosticShot
		if not FireCombatGun(gun,torso.Position) then
			ShootDiagnostic.Current = nil
			return false,"Shot Failed"
		end
		LastManualShot = os.clock()
		return true,"Shot Fired"
	end)
	ShootBusy = false
	if not ok then
		warn("[MM2 LEGIT SHOOT ERROR]",success)
		return false,"Error"
	end
	return success,message
end

--============================================================
-- RAGE THROW
--============================================================

local LastRageThrow = 0

local function GetRageThrowTargetPart(character)
	if not character then return nil end
	return character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
		or character:FindFirstChild("HumanoidRootPart")
end

local function FindClosestRageTarget()
	local character = LocalPlayer.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil,nil end
	local bestPlayer,bestPart,bestDistance = nil,nil,math.huge
	for _,player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local targetCharacter = player.Character
			local humanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
			local part = GetRageThrowTargetPart(targetCharacter)
			if humanoid and humanoid.Health > 0 and part then
				local distance = (part.Position-hrp.Position).Magnitude
				if distance < bestDistance then
					bestDistance,bestPlayer,bestPart = distance,player,part
				end
			end
		end
	end
	return bestPlayer,bestPart
end

local function RageThrowOnce()
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not humanoid or humanoid.Health <= 0 or not hrp then return false end
	local knife = character:FindFirstChild("Knife")
	if not knife then
		local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
		local stowed = backpack and backpack:FindFirstChild("Knife")
		if stowed then
			pcall(function() humanoid:EquipTool(stowed) end)
			task.wait(0.03)
			knife = character:FindFirstChild("Knife")
		end
	end
	if not knife or knife:GetAttribute("Disabled") == true then return false end
	local events = knife:FindFirstChild("Events")
	local thrown = events and events:FindFirstChild("KnifeThrown")
	if not thrown or not thrown:IsA("RemoteEvent") then return false end
	local cooldown = 1.05 * (tonumber(knife:GetAttribute("ThrowSpeed")) or 1)
	if os.clock()-LastRageThrow < cooldown then return false end
	local _,targetPart = FindClosestRageTarget()
	if not targetPart then return false end
	local target = targetPart.Position
	local direction = target-hrp.Position
	direction = direction.Magnitude > 0.1 and direction.Unit or Vector3.new(0,0,-1)
	LastRageThrow = os.clock()
	local ok = pcall(function()
		thrown:FireServer(
			CFrame.new(target-direction*2,target),
			CFrame.new(target)
		)
	end)
	return ok
end

MM2.Functions.RageThrowOnce = RageThrowOnce

local LastLegitThrow = 0
local LastLegitBlockedNotice = 0

local function FindClosestLegitTarget()
	local character = LocalPlayer.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil,nil,false end
	local bestPlayer,bestPart,bestDistance = nil,nil,math.huge
	local blockedTargetExists = false
	for _,player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local targetCharacter = player.Character
			local humanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
			local part = GetRageThrowTargetPart(targetCharacter)
			if humanoid and humanoid.Health > 0 and part then
				if HasClearLineOfSight(part) then
					local distance = (part.Position-hrp.Position).Magnitude
					if distance < bestDistance then
						bestDistance,bestPlayer,bestPart = distance,player,part
					end
				else
					blockedTargetExists = true
				end
			end
		end
	end
	return bestPlayer,bestPart,blockedTargetExists
end

local function LegitThrowOnce()
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not humanoid or humanoid.Health <= 0 or not hrp then return false end
	local knife = character:FindFirstChild("Knife")
	if not knife then
		local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
		local stowed = backpack and backpack:FindFirstChild("Knife")
		if stowed then
			pcall(function() humanoid:EquipTool(stowed) end)
			task.wait(0.03)
			knife = character:FindFirstChild("Knife")
		end
	end
	if not knife or knife:GetAttribute("Disabled") == true then return false end
	local events = knife:FindFirstChild("Events")
	local thrown = events and events:FindFirstChild("KnifeThrown")
	if not thrown or not thrown:IsA("RemoteEvent") then return false end
	local cooldown = 1.05 * (tonumber(knife:GetAttribute("ThrowSpeed")) or 1)
	if os.clock()-LastLegitThrow < cooldown then return false end
	local _,targetPart,blockedTargetExists = FindClosestLegitTarget()
	if not targetPart then
		if blockedTargetExists and os.clock()-LastLegitBlockedNotice >= 1.5 then
			LastLegitBlockedNotice = os.clock()
			MM2.Notify("Murderer Behind Wall",1)
		end
		return false,"Murderer Behind Wall"
	end
	if not HasClearLineOfSight(targetPart) then
		return false,"Murderer Behind Wall"
	end
	local target = targetPart.Position
	local direction = target-hrp.Position
	direction = direction.Magnitude > 0.1 and direction.Unit or Vector3.new(0,0,-1)
	LastLegitThrow = os.clock()
	return pcall(function()
		thrown:FireServer(
			CFrame.new(target-direction*2,target),
			CFrame.new(target)
		)
	end)
end

MM2.Functions.LegitThrowOnce = LegitThrowOnce

task.spawn(function()
	while MM2.Running do
		if Flags.LegitThrow and Flags.RageThrow then
			SetThrowToggle("RageThrow",false)
		end
		if Flags.LegitThrow then
			LegitThrowOnce()
		elseif Flags.RageThrow then
			RageThrowOnce()
		end
		task.wait(0.03)
	end
end)

--============================================================
-- KNIFE RANGE / KILL ALL
--============================================================

local KillAllBusy = false
local LastKillAll = 0
local KILL_ALL_COOLDOWN = 0.35
local KnifeRangeSuppressActivated = false
local KnifeRangeBoundKnife = nil
local KnifeRangeActivatedConnection = nil

local function GetKnifeRangeTargetPart(character)
	if not character then return nil end
	return character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
		or character:FindFirstChild("HumanoidRootPart")
end

local function FindKnifeTool()
	local character = LocalPlayer.Character
	local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
	local function scan(container)
		if not container then return nil end
		for _,tool in ipairs(container:GetChildren()) do
			if tool:IsA("Tool") and (
				tool.Name == "Knife"
				or tool:GetAttribute("IsKnife") == true
			) then
				return tool
			end
		end
		return nil
	end
	return scan(character) or scan(backpack)
end

local function EnsureKnifeEquipped()
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid or humanoid.Health <= 0 then
		return nil
	end
	local knife = FindKnifeTool()
	if not knife then return nil end
	if knife.Parent ~= character then
		local ok = pcall(function()
			humanoid:EquipTool(knife)
		end)
		if not ok then return nil end
		local deadline = os.clock()+0.75
		repeat
			task.wait(0.03)
		until knife.Parent == character or os.clock() >= deadline
	end
	if knife.Parent ~= character then
		return nil
	end
	return knife
end

local function GetKnifeHandle(knife)
	if not knife then return nil end
	local handle = knife:FindFirstChild("Handle")
	if handle and handle:IsA("BasePart") then
		return handle
	end
	return knife:FindFirstChildWhichIsA("BasePart",true)
end

local function GetKnifeTargetsInRange(range)
	range = math.clamp(
		tonumber(range) or Flags.KnifeRange,
		KNIFE_RANGE_MIN,
		KNIFE_RANGE_MAX
	)
	local character = LocalPlayer.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then return {} end
	local targets = {}
	for _,player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local targetCharacter = player.Character
			local humanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
			local targetPart = GetKnifeRangeTargetPart(targetCharacter)
			if humanoid and humanoid.Health > 0 and targetPart then
				local distance = (targetPart.Position-hrp.Position).Magnitude
				if distance <= range then
					table.insert(targets,{
						Player = player,
						Part = targetPart,
						Distance = distance,
					})
				end
			end
		end
	end
	return targets
end

local function TouchKnifeTargets(handle,targets)
	if not handle or not firetouchinterest then
		return 0
	end
	local touched = {}
	for _,target in ipairs(targets) do
		local part = target.Part
		if part and part.Parent then
			local ok = pcall(function()
				firetouchinterest(handle,part,0)
			end)
			if ok then
				table.insert(touched,part)
			end
		end
	end
	if #touched > 0 then
		RunService.Heartbeat:Wait()
	end
	for _,part in ipairs(touched) do
		if part and part.Parent then
			pcall(function()
				firetouchinterest(handle,part,1)
			end)
		end
	end
	return #touched
end

local function ProcessKnifeRange(knife,range)
	if not knife or knife.Parent ~= LocalPlayer.Character then
		return 0
	end
	local handle = GetKnifeHandle(knife)
	if not handle then return 0 end
	local targets = GetKnifeTargetsInRange(range)
	if #targets <= 0 then return 0 end
	return TouchKnifeTargets(handle,targets)
end

local function DisconnectKnifeRangeActivation()
	if KnifeRangeActivatedConnection then
		KnifeRangeActivatedConnection:Disconnect()
		KnifeRangeActivatedConnection = nil
	end
	KnifeRangeBoundKnife = nil
end

local function BindKnifeRangeActivation(knife)
	if knife == KnifeRangeBoundKnife and KnifeRangeActivatedConnection then
		return
	end
	DisconnectKnifeRangeActivation()
	if not knife or not knife:IsA("Tool") then
		return
	end
	KnifeRangeBoundKnife = knife
	KnifeRangeActivatedConnection = knife.Activated:Connect(function()
		if KnifeRangeSuppressActivated then return end
		task.spawn(function()
			ProcessKnifeRange(knife,Flags.KnifeRange)
		end)
	end)
	Track(KnifeRangeActivatedConnection)
end

MM2.Functions.GetKnifeRangeMax = function()
	return KNIFE_RANGE_MAX
end

MM2.Functions.ProcessKnifeRange = function(range)
	local knife = EnsureKnifeEquipped()
	if not knife then return false,"Murderer Role Required" end
	local touched = ProcessKnifeRange(knife,range or Flags.KnifeRange)
	if touched <= 0 then
		return false,"No Targets"
	end
	return true,"Triggered "..touched
end

MM2.Functions.KillAllOnce = function()
	if KillAllBusy then
		return false,"Busy"
	end
	local now = os.clock()
	if now-LastKillAll < KILL_ALL_COOLDOWN then
		return false,"Cooldown"
	end
	KillAllBusy = true
	local success,message = false,"Error"
	local ok,err = pcall(function()
		local knife = EnsureKnifeEquipped()
		if not knife then
			message = "Murderer Role Required"
			return
		end
		local handle = GetKnifeHandle(knife)
		if not handle then
			message = "No Handle"
			return
		end
		local targets = GetKnifeTargetsInRange(KNIFE_RANGE_MAX)
		if #targets <= 0 then
			message = "No Targets"
			return
		end
		KnifeRangeSuppressActivated = true
		local activated = pcall(function()
			knife:Activate()
		end)
		if not activated then
			KnifeRangeSuppressActivated = false
			message = "Activation Failed"
			return
		end
		local touched = TouchKnifeTargets(handle,targets)
		task.delay(0.08,function()
			KnifeRangeSuppressActivated = false
		end)
		if touched <= 0 then
			message = "No Targets"
			return
		end
		success = true
		message = "Triggered "..touched
	end)
	LastKillAll = os.clock()
	KillAllBusy = false
	if not ok then
		KnifeRangeSuppressActivated = false
		warn("[MM2 KILL ALL ERROR]",err)
		return false,"Error"
	end
	return success,message
end

task.spawn(function()
	while MM2.Running do
		local character = LocalPlayer.Character
		local knife = character and character:FindFirstChild("Knife")
		if knife and knife:IsA("Tool") then
			BindKnifeRangeActivation(knife)
		elseif KnifeRangeBoundKnife then
			DisconnectKnifeRangeActivation()
		end
		task.wait(0.15)
	end
	DisconnectKnifeRangeActivation()
end)

local function UpdateCombatFeatures()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local active = Flags.TriggerBot or Flags.AimLock
	CrosshairDot.Visible = active
	if not active then
		return
	end
	if Flags.AimLock and IsAimLockAllowed() then
		local _,targetPart = GetBestCombatTarget()
		if targetPart then
			camera.CFrame = CFrame.new(
				camera.CFrame.Position,
				targetPart.Position
			)
		end
	end
	if not Flags.TriggerBot then return end
	local now = os.clock()
	if now-LastTriggerShot < SHOT_COOLDOWN then
		return
	end
	local gun = GetCombatGun()
	if not gun then return end
	local rayResult = GetCombatCrosshairHit()
	if not rayResult then return end
	local targetPlayer = ResolveCombatPlayer(rayResult.Instance)
	if not targetPlayer or not IsMurderer(targetPlayer) then
		return
	end
	local targetPart = GetCombatTorso(targetPlayer.Character)

	if not targetPart then
		return
	end

	local targetPosition = rayResult.Position
	local velocity = targetPart.AssemblyLinearVelocity
	local horizontalVelocity = Vector3.new(
		velocity.X,
		0,
		velocity.Z
	)
	local predictionTime = 0.06
	if horizontalVelocity.Magnitude > 120 then
		horizontalVelocity = horizontalVelocity.Unit * 120
	end
	targetPosition += horizontalVelocity * predictionTime
	if FireCombatGun(gun,targetPosition) then
		LastTriggerShot = os.clock()
	end
end

RunService:BindToRenderStep(
	"MM2_V8_CombatFeatures",
	Enum.RenderPriority.Camera.Value+1,
	UpdateCombatFeatures
)

--============================================================
-- BLIZZARD FLOATING COMBAT CARDS
--
-- Uses UI.CreateMovableCardButton from UI.lua so the floating
-- controls match the WindUI / Lucide visual language:
--   SHOOT      -> crosshair
--   RAGE SHOOT -> zap
--   KILL ALL   -> swords
--============================================================

assert(
	UI.CreateMovableCardButton,
	"Updated UI.lua with CreateMovableCardButton is required"
)

-- Legit shot: clean crosshair card.
local FloatingLegitShootButton,FloatingLegitShootHolder =
	UI.CreateMovableCardButton(
		"FloatingLegitShootMurderer",
		"crosshair",
		"SHOOT",
		UDim2.new(0.78,0,0.64,0),
		function()
			task.spawn(function()
				local ok,success,message = pcall(function()
					return MM2.Functions.ShootMurdererLegit()
				end)

				if not ok then
					warn("[MM2 LEGIT SHOOT BUTTON]",success)
					CombatNotify("Shoot Murderer","Error","x",2)
					return
				end

				NotifyShootResult(success,message)
			end)
		end
	)

FloatingLegitShootHolder.Visible = Flags.ShowLegitShootButton == true
MM2.UI.FloatingLegitShootButton = FloatingLegitShootButton
MM2.UI.FloatingLegitShootHolder = FloatingLegitShootHolder

-- Rage shot: lightning / zap card.
local FloatingShootButton,FloatingShootHolder =
	UI.CreateMovableCardButton(
		"FloatingShootMurderer",
		"zap",
		"RAGE SHOOT",
		UDim2.new(0.78,0,0.76,0),
		function()
			task.spawn(function()
				local ok,success,message = pcall(function()
					return MM2.Functions.ShootMurderer()
				end)

				if not ok then
					warn("[MM2 V8.6.2 SHOOT] BUTTON CALL ERROR:",success)
					CombatNotify("Shoot Murderer","Error","x",2)
					return
				end

				NotifyShootResult(success,message)
			end)
		end
	)

FloatingShootHolder.Visible = Flags.ShowShootButton == true
MM2.UI.FloatingShootButton = FloatingShootButton
MM2.UI.FloatingShootHolder = FloatingShootHolder

-- Kill All: crossed-swords Lucide icon.
local FloatingKillAllButton,FloatingKillAllHolder =
	UI.CreateMovableCardButton(
		"FloatingKillAll",
		"swords",
		"KILL ALL",
		UDim2.new(0.67,-52,0.78,-42),
		function()
			local ok,success,message = pcall(function()
				return MM2.Functions.KillAllOnce()
			end)

			if not ok then
				warn("[MM2 KILL ALL BUTTON]",success)
				CombatNotify("Kill All","Kill All error","x",2)
			else
				NotifyKillAllResult(success,message)
			end
		end
	)

FloatingKillAllHolder.Visible = Flags.ShowKillAllButton == true
MM2.UI.FloatingKillAllButton = FloatingKillAllButton
MM2.UI.FloatingKillAllHolder = FloatingKillAllHolder

--============================================================
-- AUTO GRAB GUN
--============================================================

local AUTO_GRAB_TOUCH_BURST = 2

local function GetPickupPart(gun)
	if not gun then return nil end
	if gun:IsA("BasePart")
		and gun:FindFirstChildOfClass("TouchTransmitter")
	then
		return gun
	end
	for _,obj in ipairs(gun:GetDescendants()) do
		if obj:IsA("BasePart")
			and obj:FindFirstChildOfClass("TouchTransmitter")
		then
			return obj
		end
	end
	if gun:IsA("BasePart") then
		return gun
	end
	return gun:FindFirstChildWhichIsA("BasePart",true)
end

function MM2.IsPreRoundActive()
	for _,obj in ipairs(MM2.PlayerGui:GetDescendants()) do
		if obj:IsA("TextLabel") or obj:IsA("TextButton") then
			local text = string.lower(tostring(obj.Text or ""))
			if string.find(text,"intermission",1,true)
				and MM2.IsActuallyVisible(obj)
			then
				return true
			end
		end
	end
	return false
end

local function IsLocalMurderer()
	local char = LocalPlayer.Character
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	return MM2.HasTool(char,MM2.Config.KnifeNames)
		or MM2.HasTool(backpack,MM2.Config.KnifeNames)
		or MM2.State.ServerRolesCache[LocalPlayer.Name] == "Murderer"
end

local function TouchAutoGrabPart(localPart,pickupPart)
	if not localPart
		or not pickupPart
		or not pickupPart.Parent
	then
		return false
	end
	if not firetouchinterest then
		return false
	end
	return pcall(function()
		firetouchinterest(localPart,pickupPart,0)
		RunService.Heartbeat:Wait()
		firetouchinterest(localPart,pickupPart,1)
	end)
end

MM2.Functions.UpdateAutoGrab = function()
	if not Flags.AutoGrab
		or MM2.IsPreRoundActive()
		or MM2.State.Is_Picking_Up
		or MM2.HasGunAnywhere()
		or IsLocalMurderer()
	then
		return
	end
	local gunDrop = MM2.State.CachedGunDrop
	if not gunDrop or not gunDrop.Parent then
		gunDrop = workspace:FindFirstChild("GunDrop",true)
	end
	if not gunDrop then
		return
	end
	local targetPart = GetPickupPart(gunDrop)
	if not targetPart
		or not targetPart.Parent
	then
		return
	end
	local char = LocalPlayer.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not char
		or not hrp
		or not humanoid
		or humanoid.Health <= 0
	then
		return
	end
	local torso = char:FindFirstChild("UpperTorso")
		or char:FindFirstChild("Torso")
	MM2.State.Is_Picking_Up = true
	pcall(function()
		for _ = 1,AUTO_GRAB_TOUCH_BURST do
			if not Flags.AutoGrab
				or MM2.HasGunAnywhere()
				or not gunDrop.Parent
				or not targetPart.Parent
			then
				break
			end
			if Flags.AutoFarm then
				if torso then
					TouchAutoGrabPart(torso,targetPart)
				end
				if MM2.HasGunAnywhere() or not gunDrop.Parent then
					break
				end
				TouchAutoGrabPart(hrp,targetPart)
				if MM2.HasGunAnywhere() or not gunDrop.Parent then
					break
				end
			else
				TouchAutoGrabPart(hrp,targetPart)
				if MM2.HasGunAnywhere() or not gunDrop.Parent then
					break
				end
				if torso then
					TouchAutoGrabPart(torso,targetPart)
				end
				if MM2.HasGunAnywhere() or not gunDrop.Parent then
					break
				end
			end
			task.wait(0.02)
		end
	end)
	MM2.State.Is_Picking_Up = false
end

return MM2
