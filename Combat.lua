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
-- MANUAL SHOOT PREDICTION
--============================================================

local MANUAL_SHOOT_PREDICTION = 0.06
local DIAGNOSTIC_VERTICAL_PREDICTION = true

local function GetManualShootTargetPosition(torso,useVerticalPrediction)
	local velocity = torso.AssemblyLinearVelocity
	local predictionVelocity = useVerticalPrediction and velocity or Vector3.new(velocity.X,0,velocity.Z)
	return torso.Position + predictionVelocity * MANUAL_SHOOT_PREDICTION
end

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

--============================================================
-- CFRAME-ORIGIN LEGIT SHOOT DIAGNOSTIC
-- Keeps the existing 60 ms prediction and tests HRP-based shot origin.
--============================================================

local ExactFireDiagnostic = {
	Enabled = true,
	ShotNumber = 0,
	Pending = nil,
}

local DiagnosticLogLines = {}

local DiagnosticGui = Instance.new("ScreenGui")
DiagnosticGui.Name = "BlizzardCFrameDiagnostic"
DiagnosticGui.ResetOnSpawn = false
DiagnosticGui.IgnoreGuiInset = false
DiagnosticGui.DisplayOrder = 999998
DiagnosticGui.Parent = MM2.PlayerGui

local DiagnosticFrame = Instance.new("Frame")
DiagnosticFrame.Name = "Main"
DiagnosticFrame.Size = UDim2.fromOffset(238,166)
DiagnosticFrame.Position = UDim2.new(0.5,-119,0.16,0)
DiagnosticFrame.BackgroundColor3 = Color3.fromRGB(18,18,22)
DiagnosticFrame.BackgroundTransparency = 0.08
DiagnosticFrame.BorderSizePixel = 0
DiagnosticFrame.Active = true
DiagnosticFrame.Parent = DiagnosticGui

local DiagnosticCorner = Instance.new("UICorner")
DiagnosticCorner.CornerRadius = UDim.new(0,8)
DiagnosticCorner.Parent = DiagnosticFrame

local DiagnosticStroke = Instance.new("UIStroke")
DiagnosticStroke.Thickness = 1
DiagnosticStroke.Transparency = 0.35
DiagnosticStroke.Color = Color3.fromRGB(130,180,255)
DiagnosticStroke.Parent = DiagnosticFrame

local DiagnosticTitle = Instance.new("TextLabel")
DiagnosticTitle.Size = UDim2.new(1,-10,0,22)
DiagnosticTitle.Position = UDim2.fromOffset(6,2)
DiagnosticTitle.BackgroundTransparency = 1
DiagnosticTitle.Font = Enum.Font.GothamBold
DiagnosticTitle.TextSize = 11
DiagnosticTitle.TextXAlignment = Enum.TextXAlignment.Left
DiagnosticTitle.TextColor3 = Color3.fromRGB(245,245,250)
DiagnosticTitle.Text = "CFRAME ORIGIN DIAGNOSTIC"
DiagnosticTitle.Parent = DiagnosticFrame

local DiagnosticStatus = Instance.new("TextLabel")
DiagnosticStatus.Size = UDim2.new(1,-12,0,70)
DiagnosticStatus.Position = UDim2.fromOffset(6,24)
DiagnosticStatus.BackgroundTransparency = 1
DiagnosticStatus.Font = Enum.Font.Code
DiagnosticStatus.TextSize = 10
DiagnosticStatus.TextWrapped = false
DiagnosticStatus.TextXAlignment = Enum.TextXAlignment.Left
DiagnosticStatus.TextYAlignment = Enum.TextYAlignment.Top
DiagnosticStatus.TextColor3 = Color3.fromRGB(220,220,225)
DiagnosticStatus.Text = "Ready\nMode: HRP ORIGIN\nPrediction: 60ms XYZ"
DiagnosticStatus.Parent = DiagnosticFrame

local CopyLogsButton = Instance.new("TextButton")
CopyLogsButton.Size = UDim2.new(1,-12,0,27)
CopyLogsButton.Position = UDim2.new(0,6,1,-67)
CopyLogsButton.BackgroundColor3 = Color3.fromRGB(32,32,39)
CopyLogsButton.BorderSizePixel = 0
CopyLogsButton.AutoButtonColor = true
CopyLogsButton.Font = Enum.Font.GothamSemibold
CopyLogsButton.TextSize = 10
CopyLogsButton.TextColor3 = Color3.fromRGB(245,245,250)
CopyLogsButton.Text = "COPY LOGS"
CopyLogsButton.Parent = DiagnosticFrame

local CopyCorner = Instance.new("UICorner")
CopyCorner.CornerRadius = UDim.new(0,6)
CopyCorner.Parent = CopyLogsButton

local ClearLogsButton = Instance.new("TextButton")
ClearLogsButton.Size = UDim2.new(1,-12,0,27)
ClearLogsButton.Position = UDim2.new(0,6,1,-33)
ClearLogsButton.BackgroundColor3 = Color3.fromRGB(32,32,39)
ClearLogsButton.BorderSizePixel = 0
ClearLogsButton.AutoButtonColor = true
ClearLogsButton.Font = Enum.Font.GothamSemibold
ClearLogsButton.TextSize = 10
ClearLogsButton.TextColor3 = Color3.fromRGB(245,245,250)
ClearLogsButton.Text = "CLEAR LOGS"
ClearLogsButton.Parent = DiagnosticFrame

local ClearCorner = Instance.new("UICorner")
ClearCorner.CornerRadius = UDim.new(0,6)
ClearCorner.Parent = ClearLogsButton

local function PushDiagnosticLog(line)
	line = tostring(line)
	table.insert(DiagnosticLogLines,line)
	if #DiagnosticLogLines > 350 then
		table.remove(DiagnosticLogLines,1)
	end
	print(line)
end

local function SetDiagnosticStatus(text)
	DiagnosticStatus.Text = tostring(text or "")
end

CopyLogsButton.Activated:Connect(function()
	local joined = table.concat(DiagnosticLogLines,"\n")
	if setclipboard then
		local ok = pcall(setclipboard,joined)
		CopyLogsButton.Text = ok and "COPIED!" or "COPY FAILED"
	else
		CopyLogsButton.Text = "NO CLIPBOARD API"
	end
	task.delay(1.2,function()
		if CopyLogsButton and CopyLogsButton.Parent then
			CopyLogsButton.Text = "COPY LOGS"
		end
	end)
end)

ClearLogsButton.Activated:Connect(function()
	table.clear(DiagnosticLogLines)
	ExactFireDiagnostic.ShotNumber = 0
	ExactFireDiagnostic.Pending = nil
	SetDiagnosticStatus("Logs cleared\nMode: HRP ORIGIN\nPrediction: 60ms XYZ")
	ClearLogsButton.Text = "CLEARED!"
	task.delay(1.2,function()
		if ClearLogsButton and ClearLogsButton.Parent then ClearLogsButton.Text = "CLEAR LOGS" end
	end)
end)

-- Small drag behavior for mouse and touch.
do
	local dragging = false
	local dragInput
	local dragStart
	local startPosition

	DiagnosticTitle.Active = true
	DiagnosticTitle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			dragStart = input.Position
			startPosition = DiagnosticFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	DiagnosticTitle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragInput = input
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if dragging and input == dragInput then
			local delta = input.Position-dragStart
			DiagnosticFrame.Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset+delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset+delta.Y
			)
		end
	end)
end

local function DiagnosticVector3(v)
	return string.format("(%.2f, %.2f, %.2f)",v.X,v.Y,v.Z)
end

local function BeginExactFireDiagnostic(player,torso,entryClock,targetPosition)
	if not ExactFireDiagnostic.Enabled or not player or not torso then
		return nil
	end

	ExactFireDiagnostic.ShotNumber += 1

	local humanoid = torso.Parent and torso.Parent:FindFirstChildOfClass("Humanoid")
	local record = {
		Id = ExactFireDiagnostic.ShotNumber,
		Player = player,
		Torso = torso,
		Humanoid = humanoid,
		EntryClock = entryClock,
		PredictClock = os.clock(),
		BasePosition = torso.Position,
		BaseVelocity = torso.AssemblyLinearVelocity,
		TargetPosition = targetPosition,
		StartHealth = humanoid and humanoid.Health or -1,
	}

	ExactFireDiagnostic.Pending = record
	return record
end

local function MonitorExactFireDiagnostic(record)
	task.spawn(function()
		local checkpoints = {0.016,0.033,0.050,0.066,0.100,0.150,0.200}
		local previous = 0

		for _,checkpoint in ipairs(checkpoints) do
			task.wait(math.max(0,checkpoint-previous))
			previous = checkpoint

			local torso = record.Torso
			local humanoid = record.Humanoid

			if torso and torso.Parent then
				local position = torso.Position
				local velocity = torso.AssemblyLinearVelocity
				local errorToSentTarget = (position-record.TargetPosition).Magnitude

				PushDiagnosticLog(string.format(
					"+%dms H=%s Pos=%s Vel=%s ErrorToSentTarget=%.3f",
					math.floor(checkpoint*1000+0.5),
					humanoid and string.format("%.1f",humanoid.Health) or "?",
					DiagnosticVector3(position),
					DiagnosticVector3(velocity),
					errorToSentTarget
				))
			else
				PushDiagnosticLog(string.format(
					"+%dms Target part unavailable",
					math.floor(checkpoint*1000+0.5)
				))
			end
		end

		local endHealth = record.Humanoid and record.Humanoid.Health or -1
		local outcome = "UNKNOWN"
		if record.StartHealth >= 0 and endHealth >= 0 then
			outcome = endHealth < record.StartHealth and "HIT" or "NO HEALTH CHANGE"
		end

		PushDiagnosticLog("Outcome="..outcome)
		PushDiagnosticLog("============================================================")
		SetDiagnosticStatus(
			"Shot #"..record.Id.." complete\n"
			.."Outcome: "..outcome.."\n"
			.."Tap COPY LOGS after several shots."
		)
	end)
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
	local diagnostic = ExactFireDiagnostic.Pending

	-- Controlled test:
	-- Legit diagnostic shots use the shooter's HRP as the first CFrame origin.
	-- All other gun paths keep the previous target-minus-2-studs construction.
	local originMode = diagnostic and "HRP_ORIGIN" or "TARGET_MINUS_2"
	local originCFrame
	if diagnostic then
		originCFrame = CFrame.new(hrp.Position,targetPosition)
	else
		originCFrame = CFrame.new(
			targetPosition-unitDirection*2,
			targetPosition
		)
	end
	local destinationCFrame = CFrame.new(targetPosition)
	if ExactFireDiagnostic.Enabled and diagnostic then
		diagnostic.FireClock = os.clock()
		SetDiagnosticStatus(
			"Shot #"..diagnostic.Id.." fired\n"
			.."Target: "..tostring(diagnostic.Player and diagnostic.Player.Name or "?").."\n"
			.."Prediction: 60ms XYZ\n"
			.."Collecting result..."
		)

		local targetPart = diagnostic.Torso
		local firePosition = targetPart and targetPart.Parent and targetPart.Position or nil
		local fireVelocity = targetPart and targetPart.Parent and targetPart.AssemblyLinearVelocity or nil

		PushDiagnosticLog("============================================================")
		PushDiagnosticLog("CFRAME ORIGIN SHOT #"..diagnostic.Id)
		PushDiagnosticLog("Target="..tostring(diagnostic.Player and diagnostic.Player.Name or "?"))
		PushDiagnosticLog("Prediction=60ms XYZ (vertical enabled)")
		PushDiagnosticLog("OriginMode="..originMode)
		PushDiagnosticLog("BasePosition="..DiagnosticVector3(diagnostic.BasePosition))
		PushDiagnosticLog("BaseVelocity="..DiagnosticVector3(diagnostic.BaseVelocity))
		PushDiagnosticLog("SentTarget="..DiagnosticVector3(targetPosition))

		if firePosition and fireVelocity then
			PushDiagnosticLog("FireMomentPosition="..DiagnosticVector3(firePosition))
			PushDiagnosticLog("FireMomentVelocity="..DiagnosticVector3(fireVelocity))
			PushDiagnosticLog(string.format(
				"BaseToFireMove=%.3f SentTargetToFirePosition=%.3f",
				(firePosition-diagnostic.BasePosition).Magnitude,
				(targetPosition-firePosition).Magnitude
			))
		end

		PushDiagnosticLog("ShooterHRP="..DiagnosticVector3(hrp.Position))
		PushDiagnosticLog("OriginCFramePosition="..DiagnosticVector3(originCFrame.Position))
		PushDiagnosticLog("DestinationCFramePosition="..DiagnosticVector3(destinationCFrame.Position))
		PushDiagnosticLog(string.format(
			"EntryToPrediction=%.3fms PredictionToFire=%.3fms EntryToFire=%.3fms",
			(diagnostic.PredictClock-diagnostic.EntryClock)*1000,
			(diagnostic.FireClock-diagnostic.PredictClock)*1000,
			(diagnostic.FireClock-diagnostic.EntryClock)*1000
		))
		PushDiagnosticLog(string.format(
			"OriginToDestination=%.3f HRPToDestination=%.3f",
			(originCFrame.Position-destinationCFrame.Position).Magnitude,
			(hrp.Position-destinationCFrame.Position).Magnitude
		))
	end

	local remoteStart = os.clock()
	shoot:FireServer(originCFrame,destinationCFrame)

	if ExactFireDiagnostic.Enabled and diagnostic then
		diagnostic.RemoteReturnClock = os.clock()
		PushDiagnosticLog(string.format(
			"FireServerReturn=%.3fms",
			(diagnostic.RemoteReturnClock-remoteStart)*1000
		))
		PushDiagnosticLog("POST-FIRE: 16/33/50/66/100/150/200ms")
		PushDiagnosticLog("------------------------------------------------------------")
		ExactFireDiagnostic.Pending = nil
		MonitorExactFireDiagnostic(diagnostic)
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
		if not IsLivePlayer(murderer) then
			return false,"No Gun or Murderer"
		end
		torso = GetCombatTorso(murderer.Character)
		if not torso then
			return false,"No Gun or Murderer"
		end
		local targetPosition = GetManualShootTargetPosition(torso)
		local fired = FireCombatGun(gun,targetPosition)
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
	local diagnosticEntryClock = now
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
		if not IsLivePlayer(murderer) then return false,"No Gun or Murderer" end
		torso = GetCombatTorso(murderer.Character)
		if not torso then return false,"No Gun or Murderer" end
		if not HasClearLineOfSight(torso) then return false,"Murderer Behind Wall" end
		local targetPosition = GetManualShootTargetPosition(torso,DIAGNOSTIC_VERTICAL_PREDICTION)
		BeginExactFireDiagnostic(murderer,torso,diagnosticEntryClock,targetPosition)
		if not FireCombatGun(gun,targetPosition) then
			ExactFireDiagnostic.Pending = nil
			return false,"Shot Failed"
		end
		LastManualShot = os.clock()
		return true,"Shot Fired"
	end)
	ShootBusy = false
	if not ok then
		ExactFireDiagnostic.Pending = nil
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
