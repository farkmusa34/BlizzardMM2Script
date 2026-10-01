local MM2 = getgenv and getgenv().MM2_V85_SPLIT or _G.MM2_V85_SPLIT
assert(MM2 and MM2.UI and MM2.UI.CombatPage, "Load Shared.lua + UI.lua first")

local Players = MM2.Services.Players
local RunService = MM2.Services.RunService
local UIS = MM2.Services.UserInputService
local LocalPlayer = MM2.LocalPlayer
local Flags = MM2.Flags
local UI = MM2.UI
local Track = MM2.Track

-- Compact Combat section spacing without changing the shared UI framework.
-- This only trims the outer top/bottom padding of each WindUI section;
-- control/card internals are left untouched.
local function AddCompactCombatSection(titleText)
	-- UI.lua owns WindUI spacing. Combat.lua only creates the section.
	if UI.SetNextSectionSpacing then
		UI.SetNextSectionSpacing(UI.CombatPage, 0, 0)
	end

	return UI.AddSection(UI.CombatPage, titleText, "")
end

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
		CombatNotify("Shoot Murderer",message,"circle-x",2.5)
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
		CombatNotify("Kill All",message,"circle-x",2.5)
	end
end


AddCompactCombatSection("Aimbot")
UI.CreateToggle(UI.CombatPage, "TriggerBot", "Automatically shoots the Murderer when your crosshair is on them", "TriggerBot")
Flags.TriggerBotDelay = math.clamp(tonumber(Flags.TriggerBotDelay) or 0.05,0,0.60)
UI.CreateSlider(
	UI.CombatPage,
	"TriggerBot Delay",
	"Sets the delay before TriggerBot fires",
	function() return Flags.TriggerBotDelay end,
	function(value)
		Flags.TriggerBotDelay = math.clamp(tonumber(value) or 0.05,0,0.60)
	end,
	0,0.60,0.01
)
UI.CreateToggle(UI.CombatPage, "Aim Lock", "Tracks the Murderer while Shift Lock is enabled", "AimLock")

AddCompactCombatSection("Sheriff")
UI.CreateToggle(UI.CombatPage, "Shoot Murderer Button (LEGIT)", "Shows a shoot button that only fires when the Murderer is visible", "ShowLegitShootButton", function(on)
	if MM2.UI.FloatingLegitShootHolder then
		MM2.UI.FloatingLegitShootHolder.Visible = on
	elseif MM2.UI.FloatingLegitShootButton then
		MM2.UI.FloatingLegitShootButton.Visible = on
	end
end)
UI.CreateToggle(UI.CombatPage, "Shoot Murderer Button (RAGE)", "Shows a shoot button that can target the Murderer through walls", "ShowShootButton", function(on)
	if MM2.UI.FloatingShootHolder then
		MM2.UI.FloatingShootHolder.Visible = on
	elseif MM2.UI.FloatingShootButton then
		MM2.UI.FloatingShootButton.Visible = on
	end
end)

AddCompactCombatSection("Dropped Sheriff Gun")
UI.CreateToggle(UI.CombatPage, "Auto Grab Gun", "Automatically picks up the dropped gun without moving your character", "AutoGrab")

AddCompactCombatSection("Murderer")
Flags.LegitThrow = Flags.LegitThrow == true
Flags.RageThrow = false -- legacy flag retired; WallThrow now controls through-wall targeting.
Flags.WallThrow = Flags.WallThrow == true
Flags.ShowThrowAimbotButton = Flags.ShowThrowAimbotButton == true

UI.CreateToggle(UI.CombatPage, "Auto Throw Knife", "Automatically throws your knife at the closest visible player", "LegitThrow")
UI.CreateToggle(UI.CombatPage, "Throw Aimbot Button", "Throws your knife at the closest visible player", "ShowThrowAimbotButton", function(on)
	if MM2.UI.FloatingThrowAimbotHolder then MM2.UI.FloatingThrowAimbotHolder.Visible = on end
end)
UI.CreateToggle(UI.CombatPage, "Wall Throw", "Allows your thrown knives to target players through walls", "WallThrow")

local KNIFE_RANGE_MIN = 5
local KNIFE_RANGE_MAX = 200
local KILL_ALL_RANGE = 10000
Flags.KnifeRange = math.clamp(tonumber(Flags.KnifeRange) or 10,KNIFE_RANGE_MIN,KNIFE_RANGE_MAX)

Flags.ShowKillAllButton = Flags.ShowKillAllButton == true
UI.CreateToggle(UI.CombatPage, "Show Kill All Button", "Shows the floating Kill All button", "ShowKillAllButton", function(on)
	if MM2.UI.FloatingKillAllHolder then MM2.UI.FloatingKillAllHolder.Visible = on end
end)

UI.CreateActionFeature(UI.CombatPage, "Kill All", "Stabs every player as murderer", function()
	if MM2.Functions.KillAllOnce then
		local ok,success,message = pcall(MM2.Functions.KillAllOnce)
		if not ok then
			warn("[MM2 KILL ALL ACTION]",success)
			CombatNotify("Kill All","Kill All error","circle-x",2)
		else
			NotifyKillAllResult(success,message)
		end
	end
end, "skull")

--============================================================
-- KNIFE AURA
--============================================================

AddCompactCombatSection("Knife Aura")

Flags.KnifeAura = Flags.KnifeAura == true
UI.CreateToggle(UI.CombatPage, "Knife Aura", "Stabs nearby players when you use your knife", "KnifeAura")

UI.CreateSlider(
	UI.CombatPage,
	"Knife Aura Radius",
	"Sets the Knife Aura range",
	function() return Flags.KnifeRange end,
	function(value)
		Flags.KnifeRange = math.clamp(tonumber(value) or 10,KNIFE_RANGE_MIN,KNIFE_RANGE_MAX)
	end,
	KNIFE_RANGE_MIN,KNIFE_RANGE_MAX,5
)

--============================================================
-- CROSSHAIR
--============================================================


AddCompactCombatSection("Crosshair")

Flags.CustomCrosshair = Flags.CustomCrosshair == true
Flags.CrosshairType = tostring(Flags.CrosshairType or "Classic")
Flags.CrosshairSize = math.clamp(tonumber(Flags.CrosshairSize) or 10,4,24)
Flags.CrosshairGap = math.clamp(tonumber(Flags.CrosshairGap) or 5,0,16)
Flags.CrosshairThickness = math.clamp(tonumber(Flags.CrosshairThickness) or 2,1,6)
Flags.CrosshairOpacity = math.clamp(tonumber(Flags.CrosshairOpacity) or 100,20,100)

local CrosshairRoot = Instance.new("Frame")
CrosshairRoot.Name = "BlizzardCustomCrosshair"
CrosshairRoot.AnchorPoint = Vector2.new(0.5,0.5)
CrosshairRoot.Position = UDim2.fromScale(0.5,0.5)
CrosshairRoot.Size = UDim2.fromOffset(100,100)
CrosshairRoot.BackgroundTransparency = 1
CrosshairRoot.Visible = Flags.CustomCrosshair
CrosshairRoot.ZIndex = 100
CrosshairRoot.Parent = CombatOverlay

local CrosshairRotor = Instance.new("Frame")
CrosshairRotor.Name = "Rotor"
CrosshairRotor.AnchorPoint = Vector2.new(0.5,0.5)
CrosshairRotor.Position = UDim2.fromScale(0.5,0.5)
CrosshairRotor.Size = UDim2.fromScale(1,1)
CrosshairRotor.BackgroundTransparency = 1
CrosshairRotor.ZIndex = 100
CrosshairRotor.Parent = CrosshairRoot

local CrosshairPieces = {}

local function NewCrosshairPiece(name)
	local f = Instance.new("Frame")
	f.Name = name
	f.AnchorPoint = Vector2.new(0.5,0.5)
	f.BackgroundColor3 = Color3.fromRGB(255,255,255)
	f.BorderSizePixel = 0
	f.ZIndex = 102
	f.Parent = CrosshairRotor
	CrosshairPieces[name] = f
	return f
end

local CHTop = NewCrosshairPiece("Top")
local CHBottom = NewCrosshairPiece("Bottom")
local CHLeft = NewCrosshairPiece("Left")
local CHRight = NewCrosshairPiece("Right")

local CHDot = Instance.new("Frame")
CHDot.Name = "CenterDot"
CHDot.AnchorPoint = Vector2.new(0.5,0.5)
CHDot.Position = UDim2.fromScale(0.5,0.5)
CHDot.BorderSizePixel = 0
CHDot.BackgroundColor3 = Color3.fromRGB(255,255,255)
CHDot.ZIndex = 103
CHDot.Parent = CrosshairRoot
local CHDotCorner = Instance.new("UICorner")
CHDotCorner.CornerRadius = UDim.new(1,0)
CHDotCorner.Parent = CHDot

local CHCircle = Instance.new("Frame")
CHCircle.Name = "Circle"
CHCircle.AnchorPoint = Vector2.new(0.5,0.5)
CHCircle.Position = UDim2.fromScale(0.5,0.5)
CHCircle.BackgroundTransparency = 1
CHCircle.ZIndex = 101
CHCircle.Parent = CrosshairRoot
local CHCircleCorner = Instance.new("UICorner")
CHCircleCorner.CornerRadius = UDim.new(1,0)
CHCircleCorner.Parent = CHCircle
local CHCircleStroke = Instance.new("UIStroke")
CHCircleStroke.Color = Color3.fromRGB(255,255,255)
CHCircleStroke.Parent = CHCircle

local function UpdateCrosshairVisual()
	local style = tostring(Flags.CrosshairType or "Classic")
	local size = math.floor(tonumber(Flags.CrosshairSize) or 10)
	local gap = math.floor(tonumber(Flags.CrosshairGap) or 5)
	local thick = math.floor(tonumber(Flags.CrosshairThickness) or 2)
	local alpha = 1-(math.clamp(tonumber(Flags.CrosshairOpacity) or 100,20,100)/100)
	local diagonal = style == "X"

	CrosshairRoot.Visible = Flags.CustomCrosshair == true
	for _,piece in pairs(CrosshairPieces) do
		piece.Visible = false
		piece.BackgroundTransparency = alpha
		piece.Rotation = 0
	end
	CHDot.Visible = false
	CHDot.BackgroundTransparency = alpha
	CHCircle.Visible = false
	CHCircleStroke.Transparency = alpha
	CHCircleStroke.Thickness = thick
	CrosshairRotor.Rotation = 0

	local showLines = style == "Classic" or style == "Dot + Lines" or style == "Spinner" or style == "X"
	if showLines then
		for _,piece in pairs(CrosshairPieces) do piece.Visible = true end
		CHTop.Size = UDim2.fromOffset(thick,size)
		CHBottom.Size = UDim2.fromOffset(thick,size)
		CHLeft.Size = UDim2.fromOffset(size,thick)
		CHRight.Size = UDim2.fromOffset(size,thick)
		CHTop.Position = UDim2.new(0.5,0,0.5,-gap-size/2)
		CHBottom.Position = UDim2.new(0.5,0,0.5,gap+size/2)
		CHLeft.Position = UDim2.new(0.5,-gap-size/2,0.5,0)
		CHRight.Position = UDim2.new(0.5,gap+size/2,0.5,0)
	end

	if diagonal then
		CrosshairRotor.Rotation = 45
	end

	if style == "Dot" or style == "Dot + Lines" or style == "Spinner" or style == "Circle + Dot" then
		CHDot.Visible = true
		local dotSize = math.max(2,thick+1)
		CHDot.Size = UDim2.fromOffset(dotSize,dotSize)
	end

	if style == "Circle + Dot" then
		CHCircle.Visible = true
		local diameter = math.max(10,(gap+size)*2)
		CHCircle.Size = UDim2.fromOffset(diameter,diameter)
	end
end

UI.CreateToggle(UI.CombatPage, "Crosshair", "Select your custom crosshair", "CustomCrosshair", function()
	UpdateCrosshairVisual()
end)

local CROSSHAIR_STYLES = {"Classic","Dot","Dot + Lines","Spinner","Circle + Dot","X"}

UI.CreateDropdown(
	UI.CombatPage,
	"Crosshair Type",
	"Select a crosshair style",
	CROSSHAIR_STYLES,
	Flags.CrosshairType,
	function(crosshairType)
		if crosshairType then
			Flags.CrosshairType = tostring(crosshairType)
			UpdateCrosshairVisual()
		end
	end
)

UI.CreateSlider(
	UI.CombatPage,
	"Crosshair Size",
	"Adjusts the crosshair size",
	function() return Flags.CrosshairSize end,
	function(value)
		Flags.CrosshairSize = math.clamp(tonumber(value) or 10,4,24)
		UpdateCrosshairVisual()
	end,
	4,24,1
)

UI.CreateSlider(
	UI.CombatPage,
	"Crosshair Thickness",
	"Adjusts the crosshair line thickness",
	function() return Flags.CrosshairThickness end,
	function(value)
		Flags.CrosshairThickness = math.clamp(tonumber(value) or 2,1,6)
		UpdateCrosshairVisual()
	end,
	1,6,1
)

UpdateCrosshairVisual()

local CrosshairSpinAngle = 0
Track(RunService.RenderStepped:Connect(function(dt)
	if Flags.CustomCrosshair and Flags.CrosshairType == "Spinner" then
		local seconds = 1.25
		CrosshairSpinAngle = (CrosshairSpinAngle + (360/seconds)*dt) % 360
		CrosshairRotor.Rotation = CrosshairSpinAngle
	elseif Flags.CrosshairType ~= "X" then
		CrosshairRotor.Rotation = 0
	end
end))

local AIMLOCK_FOV = 150
local COMBAT_MAX_DISTANCE = 2000
local SHOT_COOLDOWN = 1.5
local LastTriggerShot = 0
local DiagnosticVYWindowLatched = false
local GeneralDiagnosticRequestedCase = nil
local GeneralDiagnosticCaseIndex = 1
local GeneralDiagnosticSelectedIndex = 1
-- Optional exact movement window layered on top of ANY selected diagnostic case.
-- nil means AUTO (use only the case's normal matcher).
local GeneralDiagnosticCustomWindowEnabled = false
local GeneralDiagnosticVYMin = nil
local GeneralDiagnosticVYMax = nil
local GeneralDiagnosticHSMin = nil
local GeneralDiagnosticHSMax = nil
-- Server-facing prediction used only while the general diagnostic is active.
-- Production/manual prediction remains untouched.
local GeneralDiagnosticPredictionMs = 60
local GENERAL_DIAGNOSTIC_CASES = {"GROUNDED_HORIZONTAL","EARLY_RISE","LATE_RISE","APEX","NORMAL_FALL","FAST_FALL","DIAGONAL_RISE","DIAGONAL_FALL","DIRECTION_CHANGE","JUMP_SPAM"}
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

local DIAGNOSTIC_BASE_PREDICTION_MS = 20
-- Final acceptance-boundary diagnostic: keep prediction fixed and move only the
-- server-facing destination vertically. This isolates whether the server cares
-- about the Arg2 endpoint itself or accepts a shot because the origin->destination
-- segment intersects a live body part.
local ACTUAL_ENDPOINT_OFFSET_SWEEP = {0.0,2.0}

local function GetManualShootTargetPosition(torso,useVerticalPrediction,predictionSeconds)
	local velocity = torso.AssemblyLinearVelocity
	local predictionVelocity = useVerticalPrediction and velocity or Vector3.new(velocity.X,0,velocity.Z)
	local prediction = tonumber(predictionSeconds) or MANUAL_SHOOT_PREDICTION
	return torso.Position + predictionVelocity * prediction
end

-- Production prediction selected from the completed falling diagnostics.
-- Preserve the original 60 ms horizontal prediction normally. For the one
-- condition we isolated cleanly (vertical-only fast descent, VY -35..-45),
-- use the measured 20 ms full XYZ prediction with NO additional Y offset.
local function GetProductionShootTargetPosition(torso)
	local velocity = torso.AssemblyLinearVelocity
	local horizontalSpeed = Vector3.new(velocity.X,0,velocity.Z).Magnitude
	local fastVerticalFall = velocity.Y <= -35 and velocity.Y >= -45 and horizontalSpeed <= 1.0

	if fastVerticalFall then
		return torso.Position + velocity * 0.020
	end

	local horizontalVelocity = Vector3.new(velocity.X,0,velocity.Z)
	if horizontalVelocity.Magnitude > 120 then
		horizontalVelocity = horizontalVelocity.Unit * 120
	end
	return torso.Position + horizontalVelocity * MANUAL_SHOOT_PREDICTION
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
-- FINAL A/B: keeps prediction fixed at 20 ms and changes ONLY endpoint Y offset: 0 studs, then +2 studs.
--============================================================

local ExactFireDiagnostic = {
	Enabled = true,
	ShotNumber = 0,
	Pending = nil,
	Results = {},
}

local function GetNextDiagnosticOffsetStuds()
	local nextShot = ExactFireDiagnostic.ShotNumber + 1
	return ACTUAL_ENDPOINT_OFFSET_SWEEP[((nextShot - 1) % #ACTUAL_ENDPOINT_OFFSET_SWEEP) + 1]
end

local DiagnosticLogLines = {}

local DiagnosticGui = Instance.new("ScreenGui")
DiagnosticGui.Name = "BlizzardCFrameDiagnostic"
DiagnosticGui.ResetOnSpawn = false
DiagnosticGui.IgnoreGuiInset = false
DiagnosticGui.DisplayOrder = 999998
DiagnosticGui.Parent = MM2.PlayerGui

local DiagnosticFrame = Instance.new("Frame")
DiagnosticFrame.Name = "Main"
DiagnosticFrame.Size = UDim2.fromOffset(238,382)
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
DiagnosticTitle.Text = "GENERAL MOVEMENT PREDICTION DIAGNOSTIC"
DiagnosticTitle.Parent = DiagnosticFrame

local DiagnosticStatus = Instance.new("TextLabel")
DiagnosticStatus.Size = UDim2.new(1,-12,0,64)
DiagnosticStatus.Position = UDim2.fromOffset(6,24)
DiagnosticStatus.BackgroundTransparency = 1
DiagnosticStatus.Font = Enum.Font.Code
DiagnosticStatus.TextSize = 10
DiagnosticStatus.TextWrapped = false
DiagnosticStatus.TextXAlignment = Enum.TextXAlignment.Left
DiagnosticStatus.TextYAlignment = Enum.TextYAlignment.Top
DiagnosticStatus.TextColor3 = Color3.fromRGB(220,220,225)
DiagnosticStatus.Text = "Choose a shot type below\nEnable General Prediction Diagnostic\nIt will auto-fire ONE matching shot"
DiagnosticStatus.Parent = DiagnosticFrame

local CasePrevButton = Instance.new("TextButton")
CasePrevButton.Size = UDim2.fromOffset(34,27)
CasePrevButton.Position = UDim2.fromOffset(6,94)
CasePrevButton.BackgroundColor3 = Color3.fromRGB(32,32,39)
CasePrevButton.BorderSizePixel = 0
CasePrevButton.Font = Enum.Font.GothamBold
CasePrevButton.TextSize = 14
CasePrevButton.TextColor3 = Color3.fromRGB(245,245,250)
CasePrevButton.Text = "<"
CasePrevButton.Parent = DiagnosticFrame

local CaseSelectButton = Instance.new("TextButton")
CaseSelectButton.Size = UDim2.new(1,-86,0,27)
CaseSelectButton.Position = UDim2.fromOffset(43,94)
CaseSelectButton.BackgroundColor3 = Color3.fromRGB(32,32,39)
CaseSelectButton.BorderSizePixel = 0
CaseSelectButton.Font = Enum.Font.GothamSemibold
CaseSelectButton.TextSize = 9
CaseSelectButton.TextColor3 = Color3.fromRGB(245,245,250)
CaseSelectButton.Text = GENERAL_DIAGNOSTIC_CASES[GeneralDiagnosticSelectedIndex]
CaseSelectButton.Parent = DiagnosticFrame

local CaseNextButton = Instance.new("TextButton")
CaseNextButton.Size = UDim2.fromOffset(34,27)
CaseNextButton.Position = UDim2.new(1,-40,0,94)
CaseNextButton.BackgroundColor3 = Color3.fromRGB(32,32,39)
CaseNextButton.BorderSizePixel = 0
CaseNextButton.Font = Enum.Font.GothamBold
CaseNextButton.TextSize = 14
CaseNextButton.TextColor3 = Color3.fromRGB(245,245,250)
CaseNextButton.Text = ">"
CaseNextButton.Parent = DiagnosticFrame

local function RefreshDiagnosticCaseSelection()
    CaseSelectButton.Text = GENERAL_DIAGNOSTIC_CASES[GeneralDiagnosticSelectedIndex]
    DiagnosticStatus.Text = "Selected: "..CaseSelectButton.Text.."\nEnable General Prediction Diagnostic\nWaiting only for this movement case"
end

CasePrevButton.Activated:Connect(function()
    GeneralDiagnosticSelectedIndex -= 1
    if GeneralDiagnosticSelectedIndex < 1 then GeneralDiagnosticSelectedIndex = #GENERAL_DIAGNOSTIC_CASES end
    RefreshDiagnosticCaseSelection()
end)
CaseNextButton.Activated:Connect(function()
    GeneralDiagnosticSelectedIndex += 1
    if GeneralDiagnosticSelectedIndex > #GENERAL_DIAGNOSTIC_CASES then GeneralDiagnosticSelectedIndex = 1 end
    RefreshDiagnosticCaseSelection()
end)
CaseSelectButton.Activated:Connect(function()
    GeneralDiagnosticSelectedIndex += 1
    if GeneralDiagnosticSelectedIndex > #GENERAL_DIAGNOSTIC_CASES then GeneralDiagnosticSelectedIndex = 1 end
    RefreshDiagnosticCaseSelection()
end)

-- Generic exact-window chooser. Works with FAST_FALL, DIAGONAL_FALL, rises, etc.
local WindowModeButton = Instance.new("TextButton")
WindowModeButton.Size = UDim2.new(1,-12,0,25)
WindowModeButton.Position = UDim2.fromOffset(6,127)
WindowModeButton.BackgroundColor3 = Color3.fromRGB(32,32,39)
WindowModeButton.BorderSizePixel = 0
WindowModeButton.Font = Enum.Font.GothamSemibold
WindowModeButton.TextSize = 10
WindowModeButton.TextColor3 = Color3.fromRGB(245,245,250)
WindowModeButton.Text = "WINDOW: AUTO"
WindowModeButton.Parent = DiagnosticFrame

local function MakeWindowBox(label,x,y)
    local box = Instance.new("TextBox")
    box.Size = UDim2.fromOffset(109,25)
    box.Position = UDim2.fromOffset(x,y)
    box.BackgroundColor3 = Color3.fromRGB(32,32,39)
    box.BorderSizePixel = 0
    box.ClearTextOnFocus = false
    box.Font = Enum.Font.Code
    box.TextSize = 10
    box.TextColor3 = Color3.fromRGB(245,245,250)
    box.PlaceholderColor3 = Color3.fromRGB(145,145,155)
    box.PlaceholderText = label
    box.Text = ""
    box.Parent = DiagnosticFrame
    return box
end

local VYMinBox = MakeWindowBox("VY MIN e.g. -37",6,158)
local VYMaxBox = MakeWindowBox("VY MAX e.g. -36",123,158)
local HSMinBox = MakeWindowBox("HS MIN e.g. 15",6,189)
local HSMaxBox = MakeWindowBox("HS MAX e.g. 17",123,189)

local WindowHint = Instance.new("TextLabel")
WindowHint.Size = UDim2.new(1,-12,0,34)
WindowHint.Position = UDim2.fromOffset(6,220)
WindowHint.BackgroundTransparency = 1
WindowHint.Font = Enum.Font.Code
WindowHint.TextSize = 9
WindowHint.TextWrapped = true
WindowHint.TextXAlignment = Enum.TextXAlignment.Left
WindowHint.TextYAlignment = Enum.TextYAlignment.Top
WindowHint.TextColor3 = Color3.fromRGB(180,180,190)
WindowHint.Text = "CUSTOM = selected case + these limits. Blank field = no extra limit."
WindowHint.Parent = DiagnosticFrame

-- Diagnostic-only server-facing prediction chooser.
local PredictionMsBox = Instance.new("TextBox")
PredictionMsBox.Size = UDim2.new(1,-12,0,27)
PredictionMsBox.Position = UDim2.fromOffset(6,258)
PredictionMsBox.BackgroundColor3 = Color3.fromRGB(32,32,39)
PredictionMsBox.BorderSizePixel = 0
PredictionMsBox.ClearTextOnFocus = false
PredictionMsBox.Font = Enum.Font.Code
PredictionMsBox.TextSize = 10
PredictionMsBox.TextColor3 = Color3.fromRGB(245,245,250)
PredictionMsBox.PlaceholderColor3 = Color3.fromRGB(145,145,155)
PredictionMsBox.PlaceholderText = "DIAGNOSTIC PREDICTION MS (e.g. 30)"
PredictionMsBox.Text = tostring(GeneralDiagnosticPredictionMs)
PredictionMsBox.Parent = DiagnosticFrame

local PredictionHint = Instance.new("TextLabel")
PredictionHint.Size = UDim2.new(1,-12,0,24)
PredictionHint.Position = UDim2.fromOffset(6,288)
PredictionHint.BackgroundTransparency = 1
PredictionHint.Font = Enum.Font.Code
PredictionHint.TextSize = 9
PredictionHint.TextWrapped = true
PredictionHint.TextXAlignment = Enum.TextXAlignment.Left
PredictionHint.TextColor3 = Color3.fromRGB(180,180,190)
PredictionHint.Text = "Changes diagnostic shots only; production prediction is untouched."
PredictionHint.Parent = DiagnosticFrame

local function ParseWindowBox(box)
    local t = tostring(box.Text or ""):gsub("%s+","")
    if t == "" then return nil end
    return tonumber(t)
end

local function RefreshCustomWindow()
    GeneralDiagnosticVYMin = ParseWindowBox(VYMinBox)
    GeneralDiagnosticVYMax = ParseWindowBox(VYMaxBox)
    GeneralDiagnosticHSMin = ParseWindowBox(HSMinBox)
    GeneralDiagnosticHSMax = ParseWindowBox(HSMaxBox)
    WindowModeButton.Text = GeneralDiagnosticCustomWindowEnabled and "WINDOW: CUSTOM" or "WINDOW: AUTO"
end

WindowModeButton.Activated:Connect(function()
    GeneralDiagnosticCustomWindowEnabled = not GeneralDiagnosticCustomWindowEnabled
    RefreshCustomWindow()
end)
for _,box in ipairs({VYMinBox,VYMaxBox,HSMinBox,HSMaxBox}) do
    box.FocusLost:Connect(RefreshCustomWindow)
end

local function RefreshDiagnosticPrediction()
    local ms = tonumber((PredictionMsBox.Text or ""):gsub("%s+",""))
    if ms then
        GeneralDiagnosticPredictionMs = math.clamp(ms,0,250)
    end
    PredictionMsBox.Text = tostring(GeneralDiagnosticPredictionMs)
    return GeneralDiagnosticPredictionMs
end

-- Keep the stored value in sync while typing, not only after FocusLost.
PredictionMsBox:GetPropertyChangedSignal("Text"):Connect(function()
    local ms = tonumber((PredictionMsBox.Text or ""):gsub("%s+",""))
    if ms then
        GeneralDiagnosticPredictionMs = math.clamp(ms,0,250)
    end
end)
PredictionMsBox.FocusLost:Connect(RefreshDiagnosticPrediction)

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
	ExactFireDiagnostic.Results = {}
	GeneralDiagnosticCaseIndex = 1
	SetDiagnosticStatus("Logs cleared\n6 controlled movement shots\nEnable General Prediction Diagnostic")
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


-- Rolling target-motion buffer. Read-only: this does not alter prediction or firing.
local PRE_SHOT_WINDOW = 0.200
local PRE_SHOT_MAX_SAMPLES = 40
local DiagnosticMotionBuffer = {}

local function DiagnosticHumanoidState(humanoid)
	if not humanoid then return "NONE" end
	local ok,state = pcall(function() return humanoid:GetState() end)
	return ok and tostring(state):gsub("Enum.HumanoidStateType.","") or "?"
end

local function CaptureDiagnosticMotionSample()
	local player = FindLiveMurderer()
	local torso = player and GetCombatTorso(player.Character)
	local humanoid = player and player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not player or not torso or not humanoid then return end
	local now = os.clock()
	table.insert(DiagnosticMotionBuffer,{
		Clock=now,
		Player=player,
		Position=torso.Position,
		Velocity=torso.AssemblyLinearVelocity,
		State=DiagnosticHumanoidState(humanoid),
		Floor=tostring(humanoid.FloorMaterial):gsub("Enum.Material.",""),
		Jump=humanoid.Jump == true,
	})
	while #DiagnosticMotionBuffer > PRE_SHOT_MAX_SAMPLES do table.remove(DiagnosticMotionBuffer,1) end
	while #DiagnosticMotionBuffer > 0 and now-DiagnosticMotionBuffer[1].Clock > PRE_SHOT_WINDOW do
		table.remove(DiagnosticMotionBuffer,1)
	end
end

RunService.Heartbeat:Connect(CaptureDiagnosticMotionSample)

local function SnapshotDiagnosticMotion(player,shotClock)
	local out = {}
	for _,sample in ipairs(DiagnosticMotionBuffer) do
		if sample.Player == player and sample.Clock <= shotClock and shotClock-sample.Clock <= PRE_SHOT_WINDOW then
			table.insert(out,sample)
		end
	end
	return out
end

local HYPOTHETICAL_MS = {20,30,40,50,60,80,100}

local function ClassifyDiagnosticPhase(record)
	local vy = record.BaseVelocity.Y
	local floor = record.BaseFloor
	local airborne = floor == "Air"
	local pre = record.PreShotSamples or {}
	local jumpStartedRecently = false
	for i = math.max(1,#pre-8),#pre do
		local sample = pre[i]
		if sample and (sample.State == "Jumping" or sample.Jump or sample.Velocity.Y > 6) then
			jumpStartedRecently = true
			break
		end
	end
	-- Direction wins over recent jump history. This prevents descending shots
	-- from being mislabeled JUMP_START just because a jump occurred recently.
	if vy <= -10 then return "FALLING" end
	if airborne and vy < -2 then return "DESCENT_NEAR_APEX" end
	if not airborne and math.abs(vy) < 5 and not jumpStartedRecently then return "GROUNDED" end
	if jumpStartedRecently and vy >= -2 and vy < 8 then return "JUMP_START" end
	if vy >= 35 then return "EARLY_ASCENT" end
	if vy >= 10 then return "LATE_ASCENT" end
	return "APEX"
end

local function BuildHypotheticalTargets(position,velocity)
	local targets = {}
	for _,ms in ipairs(HYPOTHETICAL_MS) do
		targets[ms] = position + velocity*(ms/1000)
	end
	return targets
end


--============================================================
-- HITBOX / PART-INTERSECTION HELPERS (READ-ONLY)
-- The real shot is NOT changed. These only inspect the fixed shot segment.
--============================================================
local DIAGNOSTIC_BODY_PARTS = {
    "Head","UpperTorso","LowerTorso","Torso","HumanoidRootPart",
    "LeftUpperArm","LeftLowerArm","LeftHand","RightUpperArm","RightLowerArm","RightHand",
    "LeftUpperLeg","LeftLowerLeg","LeftFoot","RightUpperLeg","RightLowerLeg","RightFoot",
    "Left Arm","Right Arm","Left Leg","Right Leg",
}

local function PointToSegmentDistance(point,a,b)
    local ab = b-a
    local denom = ab:Dot(ab)
    if denom <= 1e-8 then return (point-a).Magnitude,0,a end
    local t = math.clamp((point-a):Dot(ab)/denom,0,1)
    local closest = a+ab*t
    return (point-closest).Magnitude,t,closest
end

-- Segment-vs-oriented-box slab test. Uses the live BasePart CFrame/Size.
local function SegmentIntersectsPart(a,b,part)
    if not part or not part:IsA("BasePart") then return false,nil end
    local la = part.CFrame:PointToObjectSpace(a)
    local lb = part.CFrame:PointToObjectSpace(b)
    local d = lb-la
    local h = part.Size*0.5
    local tmin,tmax = 0,1
    local function axis(origin,delta,half)
        if math.abs(delta) < 1e-8 then
            return math.abs(origin) <= half
        end
        local t1=(-half-origin)/delta
        local t2=( half-origin)/delta
        if t1>t2 then t1,t2=t2,t1 end
        tmin=math.max(tmin,t1)
        tmax=math.min(tmax,t2)
        return tmin<=tmax
    end
    if not axis(la.X,d.X,h.X) then return false,nil end
    if not axis(la.Y,d.Y,h.Y) then return false,nil end
    if not axis(la.Z,d.Z,h.Z) then return false,nil end
    local hitLocal=la+d*tmin
    return true,part.CFrame:PointToWorldSpace(hitLocal)
end

local function InspectCharacterAgainstShot(character,origin,destination)
    local result={Intersections={},NearestPart=nil,NearestCenterDistance=math.huge,NearestSurfaceApprox=math.huge}
    if not character then return result end
    local seen={}
    for _,name in ipairs(DIAGNOSTIC_BODY_PARTS) do
        local part=character:FindFirstChild(name)
        if part and part:IsA("BasePart") and not seen[part] then
            seen[part]=true
            local centerDist,t,closest=PointToSegmentDistance(part.Position,origin,destination)
            -- Approximate center-to-surface clearance for quick comparison only.
            local radius=part.Size.Magnitude*0.5
            local surfaceApprox=math.max(0,centerDist-radius)
            if centerDist<result.NearestCenterDistance then
                result.NearestCenterDistance=centerDist
                result.NearestSurfaceApprox=surfaceApprox
                result.NearestPart=part.Name
                result.NearestT=t
                result.NearestPoint=closest
            end
            local hit,hitPoint=SegmentIntersectsPart(origin,destination,part)
            if hit then
                table.insert(result.Intersections,{Name=part.Name,Point=hitPoint})
            end
        end
    end
    return result
end

local function JoinIntersectionNames(info)
    if not info or #info.Intersections==0 then return "NONE" end
    local names={}
    for _,v in ipairs(info.Intersections) do table.insert(names,v.Name) end
    return table.concat(names,",")
end

--============================================================
-- SERVER-ACCEPTANCE / ENDPOINT HELPERS (READ-ONLY)
-- Tests whether the exact Arg2 destination point is actually inside a live
-- body-part OBB at each sampled frame. This is intentionally different from
-- the existing segment-intersection test: a segment can cross a character
-- even when the endpoint itself is outside every body part.
--============================================================
local function PointInsidePartOBB(point,part)
    if not point or not part or not part:IsA("BasePart") then return false,nil end
    local p = part.CFrame:PointToObjectSpace(point)
    local h = part.Size*0.5
    local inside = math.abs(p.X) <= h.X and math.abs(p.Y) <= h.Y and math.abs(p.Z) <= h.Z
    -- Signed clearance to the nearest box face while inside; negative means outside.
    local clearance = math.min(h.X-math.abs(p.X),h.Y-math.abs(p.Y),h.Z-math.abs(p.Z))
    return inside,clearance
end

local function InspectEndpointAgainstCharacter(character,point)
    local result={InsideParts={},NearestPart=nil,NearestCenterDistance=math.huge,BestClearance=-math.huge}
    if not character or not point then return result end
    local seen={}
    for _,name in ipairs(DIAGNOSTIC_BODY_PARTS) do
        local part=character:FindFirstChild(name)
        if part and part:IsA("BasePart") and not seen[part] then
            seen[part]=true
            local centerDistance=(point-part.Position).Magnitude
            if centerDistance < result.NearestCenterDistance then
                result.NearestCenterDistance=centerDistance
                result.NearestPart=part.Name
            end
            local inside,clearance=PointInsidePartOBB(point,part)
            if clearance and clearance > result.BestClearance then
                result.BestClearance=clearance
                result.BestClearancePart=part.Name
            end
            if inside then
                table.insert(result.InsideParts,{Name=part.Name,Clearance=clearance})
            end
        end
    end
    return result
end

local function JoinEndpointInsideNames(info)
    if not info or #info.InsideParts==0 then return "NONE" end
    local names={}
    for _,v in ipairs(info.InsideParts) do table.insert(names,v.Name) end
    return table.concat(names,",")
end

local function BeginExactFireDiagnostic(player,torso,entryClock,targetPosition,actualPredictionMs,endpointOffsetStuds)
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
		ActualPredictionMs = tonumber(actualPredictionMs) or DIAGNOSTIC_BASE_PREDICTION_MS,
		EndpointOffsetStuds = tonumber(endpointOffsetStuds) or 0,
		StartHealth = humanoid and humanoid.Health or -1,
		PreShotSamples = SnapshotDiagnosticMotion(player,entryClock),
		BaseState = DiagnosticHumanoidState(humanoid),
		BaseFloor = humanoid and tostring(humanoid.FloorMaterial):gsub("Enum.Material.","") or "NONE",
		BaseJump = humanoid and humanoid.Jump == true or false,
	}
	record.Phase = ClassifyDiagnosticPhase(record)
	record.GeneralCase = GeneralDiagnosticRequestedCase or record.Phase
	-- Vertical-only diagnostic controls. These are READ-ONLY and never alter the shot.
	local bv = record.BaseVelocity
	record.BaseHorizontalSpeed = Vector3.new(bv.X,0,bv.Z).Magnitude
	record.BaseVerticalSpeed = bv.Y
	record.VerticalOnlyAtFire = record.BaseHorizontalSpeed <= 2.0
	record.HypotheticalTargets = BuildHypotheticalTargets(record.BasePosition,record.BaseVelocity)
	record.BestHypothetical = nil
	record.BestHypotheticalError = math.huge
	record.BestHypotheticalCheckpoint = nil
	record.HypotheticalClosest = {}
	for _,ms in ipairs(HYPOTHETICAL_MS) do
		record.HypotheticalClosest[ms] = {Error = math.huge, Checkpoint = nil}
	end
	record.SentTargetClosest = {Error = math.huge, Checkpoint = nil}
	record.PartIntersectionFrames = 0
	record.FirstPartIntersection = nil
	record.ClosestPartCenter = {Distance=math.huge, Part=nil, Checkpoint=nil}
	record.EndpointInsideFrames = 0
	record.FirstEndpointInside = nil
	record.EndpointInsideAtHealthChange = nil
	record.BestEndpointClearance = {Value=-math.huge, Part=nil, Checkpoint=nil}

	ExactFireDiagnostic.Pending = record
	return record
end

local function MonitorExactFireDiagnostic(record)
	-- Dense sampler for the current REAL server-facing prediction value.
	task.spawn(function()
		local fireClock = record.FireClock or os.clock()
		local denseWindow = 0.100
		local extraCheckpoints = {0.150,0.200}
		local denseSamples = {}
		local eventTimes = {
			YRise = nil,
			FloorAir = nil,
			StateChange = nil,
			HealthChange = nil,
		}
		local initialState = record.BaseState
		local initialFloor = record.BaseFloor
		local initialHealth = record.StartHealth
		local lastHealth = initialHealth

		local function inspectSample(elapsed,tag)
			local torso = record.Torso
			local humanoid = record.Humanoid
			if not torso or not torso.Parent then
				return false
			end

			local position = torso.Position
			local velocity = torso.AssemblyLinearVelocity
			local state = DiagnosticHumanoidState(humanoid)
			local floor = humanoid and tostring(humanoid.FloorMaterial):gsub("Enum.Material.","") or "NONE"
			local jump = humanoid and humanoid.Jump == true or false
			local health = humanoid and humanoid.Health or -1
			local elapsedMs = elapsed*1000
			local errorToSentTarget = (position-record.TargetPosition).Magnitude

			local hitboxInfo = nil
			local endpointInfo = nil
			if record.ShotOrigin and record.ShotDestination then
				hitboxInfo = InspectCharacterAgainstShot(record.Player and record.Player.Character,record.ShotOrigin,record.ShotDestination)
				if hitboxInfo.NearestCenterDistance < record.ClosestPartCenter.Distance then
					record.ClosestPartCenter.Distance = hitboxInfo.NearestCenterDistance
					record.ClosestPartCenter.Part = hitboxInfo.NearestPart
					record.ClosestPartCenter.Checkpoint = elapsedMs
				end
				if #hitboxInfo.Intersections > 0 then
					record.PartIntersectionFrames += 1
					if not record.FirstPartIntersection then
						record.FirstPartIntersection = {Ms=elapsedMs,Parts=JoinIntersectionNames(hitboxInfo)}
					end
				end
						endpointInfo = InspectEndpointAgainstCharacter(record.Player and record.Player.Character,record.ShotDestination)
				if endpointInfo.BestClearance > record.BestEndpointClearance.Value then
					record.BestEndpointClearance.Value=endpointInfo.BestClearance
					record.BestEndpointClearance.Part=endpointInfo.BestClearancePart
					record.BestEndpointClearance.Checkpoint=elapsedMs
				end
				if #endpointInfo.InsideParts > 0 then
					record.EndpointInsideFrames += 1
					if not record.FirstEndpointInside then
						record.FirstEndpointInside={Ms=elapsedMs,Parts=JoinEndpointInsideNames(endpointInfo)}
					end
				end
			end

			-- Transition timestamps are observational only.
			if not eventTimes.YRise and velocity.Y > 6 then
				eventTimes.YRise = elapsedMs
			end
			if not eventTimes.FloorAir and floor == "Air" and initialFloor ~= "Air" then
				eventTimes.FloorAir = elapsedMs
			end
			if not eventTimes.StateChange and state ~= initialState then
				eventTimes.StateChange = elapsedMs
				eventTimes.StateChangeTo = state
			end
			if not eventTimes.HealthChange and initialHealth >= 0 and health >= 0 and health < initialHealth then
				eventTimes.HealthChange = elapsedMs
			end
			lastHealth = health

			if errorToSentTarget < record.SentTargetClosest.Error then
				record.SentTargetClosest.Error = errorToSentTarget
				record.SentTargetClosest.Checkpoint = elapsedMs
			end

			local hypoParts = {}
			for _,ms in ipairs(HYPOTHETICAL_MS) do
				local hp = record.HypotheticalTargets[ms]
				local err = (position-hp).Magnitude
				table.insert(hypoParts,string.format("%dms=%.3f",ms,err))
				local closest = record.HypotheticalClosest[ms]
				if closest and err < closest.Error then
					closest.Error = err
					closest.Checkpoint = elapsedMs
				end
				if err < record.BestHypotheticalError then
					record.BestHypotheticalError = err
					record.BestHypothetical = ms
					record.BestHypotheticalCheckpoint = elapsedMs
				end
			end

			table.insert(denseSamples,{
				Ms=elapsedMs, Position=position, Velocity=velocity, State=state,
				Floor=floor, Jump=jump, Health=health, Error=errorToSentTarget,
			})

			local horizontalSpeed = Vector3.new(velocity.X,0,velocity.Z).Magnitude
			PushDiagnosticLog(string.format(
				"+%.1fms%s H=%s Pos=%s Vel=%s HSpeed=%.3f VY=%.3f State=%s Floor=%s Jump=%s ErrorToSentTarget=%.3f",
				elapsedMs,
				tag and (" ["..tag.."]") or "",
				health >= 0 and string.format("%.1f",health) or "?",
				DiagnosticVector3(position), DiagnosticVector3(velocity),
				horizontalSpeed, velocity.Y,
				state, floor, tostring(jump), errorToSentTarget
			))
			PushDiagnosticLog("      HypotheticalErrors: "..table.concat(hypoParts," | "))
			if hitboxInfo then
				PushDiagnosticLog(string.format("      ShotSegment: Intersects=%s | NearestCenter=%s %.3f",
					JoinIntersectionNames(hitboxInfo), tostring(hitboxInfo.NearestPart or "NONE"),
					hitboxInfo.NearestCenterDistance < math.huge and hitboxInfo.NearestCenterDistance or -1
				))
			end
			if endpointInfo then
				PushDiagnosticLog(string.format("      Arg2Endpoint: Inside=%s | NearestCenter=%s %.3f | BestSignedClearance=%s %.3f",
					JoinEndpointInsideNames(endpointInfo),tostring(endpointInfo.NearestPart or "NONE"),
					endpointInfo.NearestCenterDistance < math.huge and endpointInfo.NearestCenterDistance or -1,
					tostring(endpointInfo.BestClearancePart or "NONE"),
					endpointInfo.BestClearance > -math.huge and endpointInfo.BestClearance or -999
				))
			end
			return true
		end

		-- Sample immediately after FireServer returns, then every Heartbeat through 100 ms.
		inspectSample(math.max(0,os.clock()-fireClock),"RETURN")
		while os.clock()-fireClock < denseWindow do
			RunService.Heartbeat:Wait()
			inspectSample(os.clock()-fireClock,"FRAME")
		end

		-- Keep two later observations so outcome/death timing is not lost.
		for _,checkpoint in ipairs(extraCheckpoints) do
			local remaining = checkpoint-(os.clock()-fireClock)
			if remaining > 0 then task.wait(remaining) end
			if not inspectSample(os.clock()-fireClock,checkpoint == 0.150 and "150MS" or "200MS") then
				PushDiagnosticLog(string.format("+%.1fms Target part unavailable",(os.clock()-fireClock)*1000))
			end
		end

		local endHealth = record.Humanoid and record.Humanoid.Health or lastHealth or -1
		local outcome = "UNKNOWN"
		if record.StartHealth >= 0 and endHealth >= 0 then
			outcome = endHealth < record.StartHealth and "HIT" or "NO HEALTH CHANGE"
		end

		ExactFireDiagnostic.Results[record.Id] = {
			Offset = record.EndpointOffsetStuds,
			Outcome = outcome,
			BestClearance = record.BestEndpointClearance and record.BestEndpointClearance.Value or -math.huge,
			FirstInside = record.FirstEndpointInside and record.FirstEndpointInside.Ms or nil,
		}

		PushDiagnosticLog("ANALYSIS SUMMARY")
		PushDiagnosticLog("------------------------------------------------------------")
		PushDiagnosticLog("Phase="..tostring(record.Phase))
		local fastDescentControl = record.VerticalOnlyAtFire
			and record.BaseVerticalSpeed >= -45
			and record.BaseVerticalSpeed <= -35
		PushDiagnosticLog("FastDescentControl(VY -35..-45)="..tostring(fastDescentControl))
		if not fastDescentControl then
			PushDiagnosticLog("CONTROL_WARNING=For the clean A/B set, fire while VY is between -35 and -45 with near-zero horizontal speed")
		end
		PushDiagnosticLog(string.format(
			"VerticalOnlyControl=%s HorizontalSpeedAtFire=%.3f VerticalSpeedAtFire=%.3f",
			tostring(record.VerticalOnlyAtFire),
			record.BaseHorizontalSpeed or -1,
			record.BaseVerticalSpeed or 0
		))
		if not record.VerticalOnlyAtFire then
			PushDiagnosticLog("CONTROL_WARNING=Horizontal motion exceeded 2 studs/s; do not use this shot as a clean vertical-only sample")
		end
		if record.BestHypothetical then
			PushDiagnosticLog(string.format(
				"BestHypothetical=%dms Error=%.3f studs At=+%.1fms",
				record.BestHypothetical, record.BestHypotheticalError,
				record.BestHypotheticalCheckpoint or -1
			))
		else
			PushDiagnosticLog("BestHypothetical=unavailable")
		end

		PushDiagnosticLog("CLOSEST APPROACH BY HYPOTHETICAL (dense 0-100ms + 150/200ms)")
		local closestParts = {}
		for _,ms in ipairs(HYPOTHETICAL_MS) do
			local closest = record.HypotheticalClosest[ms]
			if closest and closest.Checkpoint then
				table.insert(closestParts,string.format("%dms=%.3f@+%.1fms",ms,closest.Error,closest.Checkpoint))
			else
				table.insert(closestParts,string.format("%dms=unavailable",ms))
			end
		end
		PushDiagnosticLog(table.concat(closestParts," | "))
		if record.SentTargetClosest and record.SentTargetClosest.Checkpoint then
			PushDiagnosticLog(string.format(
				"Actual%dmsClosest=%.3f studs At=+%.1fms",
				record.ActualPredictionMs or 60, record.SentTargetClosest.Error, record.SentTargetClosest.Checkpoint
			))
		end

		local function eventText(v)
			return v and string.format("+%.1fms",v) or "not observed"
		end
		PushDiagnosticLog("HITBOX / PART INTERSECTION SUMMARY")
		PushDiagnosticLog("------------------------------------------------------------")
		if record.FirstPartIntersection then
			PushDiagnosticLog(string.format("FirstIntersection=+%.1fms Parts=%s",record.FirstPartIntersection.Ms,record.FirstPartIntersection.Parts))
		else
			PushDiagnosticLog("FirstIntersection=NONE")
		end
		PushDiagnosticLog("IntersectionFrames="..tostring(record.PartIntersectionFrames or 0))
		if record.ClosestPartCenter and record.ClosestPartCenter.Checkpoint then
			PushDiagnosticLog(string.format("ClosestPartCenter=%s Distance=%.3f At=+%.1fms",
				tostring(record.ClosestPartCenter.Part or "NONE"),record.ClosestPartCenter.Distance,record.ClosestPartCenter.Checkpoint))
		end

		PushDiagnosticLog("SERVER ACCEPTANCE / ARG2 ENDPOINT SUMMARY")
		PushDiagnosticLog("------------------------------------------------------------")
		if record.FirstEndpointInside then
			PushDiagnosticLog(string.format("FirstArg2Inside=+%.1fms Parts=%s",record.FirstEndpointInside.Ms,record.FirstEndpointInside.Parts))
		else
			PushDiagnosticLog("FirstArg2Inside=NONE")
		end
		PushDiagnosticLog("Arg2InsideFrames="..tostring(record.EndpointInsideFrames or 0))
		if record.BestEndpointClearance and record.BestEndpointClearance.Checkpoint then
			PushDiagnosticLog(string.format("BestArg2SignedClearance=%s %.3f At=+%.1fms",
				tostring(record.BestEndpointClearance.Part or "NONE"),record.BestEndpointClearance.Value,record.BestEndpointClearance.Checkpoint))
		end
		PushDiagnosticLog("InterpretationHint=positive clearance means Arg2 was inside that live body-part box; negative means outside")
		PushDiagnosticLog("TRANSITION TIMELINE")
		PushDiagnosticLog("------------------------------------------------------------")
		PushDiagnosticLog("Fire=+0.0ms")
		PushDiagnosticLog("YRise(>6)="..eventText(eventTimes.YRise))
		PushDiagnosticLog("Floor->Air="..eventText(eventTimes.FloorAir))
		PushDiagnosticLog("StateChange="..eventText(eventTimes.StateChange)..(eventTimes.StateChangeTo and (" -> "..eventTimes.StateChangeTo) or ""))
		PushDiagnosticLog("HealthChange="..eventText(eventTimes.HealthChange))
		PushDiagnosticLog("DenseFrames="..tostring(#denseSamples))
		PushDiagnosticLog(string.format("ActualPrediction=%dms XYZ + YOffset=%.1f studs (SERVER-FACING)",record.ActualPredictionMs or DIAGNOSTIC_BASE_PREDICTION_MS,record.EndpointOffsetStuds or 0))
		PushDiagnosticLog("SERVER ACCEPTANCE CONTROL SUMMARY")
		PushDiagnosticLog("------------------------------------------------------------")
		if record.PreFireState then
			PushDiagnosticLog(string.format("PreFireSinceLastShot=%.3fms PreFireCooldownRemaining=%.3fms",
				record.PreFireState.SinceLastManualShot*1000,record.PreFireState.CooldownRemaining*1000))
			PushDiagnosticLog("PreFireToolEnabled="..tostring(record.PreFireState.ToolEnabled).." PreFireCantShoot="..tostring(record.PreFireState.CantShootEnabled))
		end
		if record.ReturnFireState then
			PushDiagnosticLog("ReturnToolEnabled="..tostring(record.ReturnFireState.ToolEnabled).." ReturnCantShoot="..tostring(record.ReturnFireState.CantShootEnabled))
		end
		PushDiagnosticLog("Outcome="..outcome)

		if Flags.GeneralPredictionDiagnostic and record.GeneralCase then
			PushDiagnosticLog("SELECTED DIAGNOSTIC COMPLETE - General Prediction Diagnostic remains ON")
			SetDiagnosticStatus("COMPLETE: "..tostring(record.GeneralCase).."\nOutcome: "..outcome.."\nDiagnostic remains ON; waiting for next matching shot")
		end

		PushDiagnosticLog("============================================================")
	end)
end

local function ReadGunFireState(gun,character)
	local state = {}
	state.Clock = os.clock()
	state.Parent = gun and gun.Parent and gun.Parent:GetFullName() or "nil"
	state.Equipped = gun ~= nil and character ~= nil and gun.Parent == character
	state.ToolEnabled = (gun and gun:IsA("Tool")) and gun.Enabled or nil
	local cantShoot = gun and gun:FindFirstChild("CantShoot")
	if cantShoot and cantShoot:IsA("BillboardGui") then
		state.CantShootEnabled = cantShoot.Enabled
	else
		state.CantShootEnabled = nil
	end
	local handle = gun and gun:FindFirstChild("Handle")
	state.HandlePresent = handle ~= nil and handle:IsA("BasePart")
	local shootRemote = gun and gun:FindFirstChild("Shoot")
	state.RemotePresent = shootRemote ~= nil and shootRemote:IsA("RemoteEvent")
	state.SinceLastManualShot = state.Clock-(LastManualShot or 0)
	state.CooldownRemaining = math.max(0,SHOT_COOLDOWN-state.SinceLastManualShot)
	state.ShootBusy = ShootBusy == true
	return state
end

local function LogGunFireState(label,state)
	PushDiagnosticLog(label)
	PushDiagnosticLog("------------------------------------------------------------")
	PushDiagnosticLog("Clock="..string.format("%.6f",state.Clock))
	PushDiagnosticLog("GunParent="..tostring(state.Parent))
	PushDiagnosticLog("GunEquipped="..tostring(state.Equipped))
	PushDiagnosticLog("ToolEnabled="..tostring(state.ToolEnabled))
	PushDiagnosticLog("CantShootEnabled="..tostring(state.CantShootEnabled))
	PushDiagnosticLog("HandlePresent="..tostring(state.HandlePresent).." RemotePresent="..tostring(state.RemotePresent))
	PushDiagnosticLog("ShootBusy="..tostring(state.ShootBusy))
	PushDiagnosticLog(string.format("SinceLastManualShot=%.3fms CooldownRemaining=%.3fms",
		state.SinceLastManualShot*1000,state.CooldownRemaining*1000))
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

	-- Keep shot construction fixed while the diagnostic isolates jump timing.
	local originMode = "HRP_ORIGIN"
	local originCFrame = CFrame.new(hrp.Position,targetPosition)
	local destinationCFrame = CFrame.new(targetPosition)
	if ExactFireDiagnostic.Enabled and diagnostic then
		diagnostic.FireClock = os.clock()
		diagnostic.ShotOrigin = originCFrame.Position
		diagnostic.ShotDestination = destinationCFrame.Position
		SetDiagnosticStatus(
			"Shot #"..diagnostic.Id.." fired\n"
			.."Target: "..tostring(diagnostic.Player and diagnostic.Player.Name or "?").."\n"
			.."Origin: "..originMode.."\n"
			.."Prediction: "..tostring(diagnostic.ActualPredictionMs or DIAGNOSTIC_BASE_PREDICTION_MS).."ms + YOffset "..string.format("%+.1f",diagnostic.EndpointOffsetStuds or 0).." (ACTUAL)\n"
			.."Collecting result..."
		)

		local targetPart = diagnostic.Torso
		local firePosition = targetPart and targetPart.Parent and targetPart.Position or nil
		local fireVelocity = targetPart and targetPart.Parent and targetPart.AssemblyLinearVelocity or nil

		PushDiagnosticLog("============================================================")
		PushDiagnosticLog("GENERAL MOVEMENT PREDICTION DIAGNOSTIC SHOT #"..diagnostic.Id)
		PushDiagnosticLog("Target="..tostring(diagnostic.Player and diagnostic.Player.Name or "?"))
		PushDiagnosticLog(string.format("Prediction=%dms XYZ + YOffset=%.1f studs (ACTUAL SERVER-FACING; vertical enabled)",diagnostic.ActualPredictionMs or DIAGNOSTIC_BASE_PREDICTION_MS,diagnostic.EndpointOffsetStuds or 0))
		PushDiagnosticLog("OriginMode="..originMode)
		PushDiagnosticLog("Phase="..tostring(diagnostic.Phase))
		PushDiagnosticLog(string.format(
			"VERTICAL-ONLY CONTROL: HorizontalSpeed=%.3f VerticalSpeed=%.3f CleanVerticalOnly=%s",
			diagnostic.BaseHorizontalSpeed or -1,
			diagnostic.BaseVerticalSpeed or 0,
			tostring(diagnostic.VerticalOnlyAtFire)
		))
		PushDiagnosticLog("RequestedMovementCase="..tostring(diagnostic.GeneralCase or "UNKNOWN"))
		PushDiagnosticLog("Instruction=Automatic trigger selected this movement state; production prediction was not changed")
		PushDiagnosticLog("PRE-SHOT ROLLING BUFFER (oldest -> newest)")
		PushDiagnosticLog("------------------------------------------------------------")
		local pre = diagnostic.PreShotSamples or {}
		if #pre == 0 then
			PushDiagnosticLog("No pre-shot samples available")
		else
			for _,sample in ipairs(pre) do
				PushDiagnosticLog(string.format(
					"%+.1fms Pos=%s Vel=%s State=%s Floor=%s Jump=%s",
					(sample.Clock-diagnostic.EntryClock)*1000,
					DiagnosticVector3(sample.Position),
					DiagnosticVector3(sample.Velocity),
					sample.State,sample.Floor,tostring(sample.Jump)
				))
			end
		end
		PushDiagnosticLog("PREDICTION/FIRE SNAPSHOT")
		PushDiagnosticLog("------------------------------------------------------------")
		PushDiagnosticLog("BasePosition="..DiagnosticVector3(diagnostic.BasePosition))
		PushDiagnosticLog("BaseVelocity="..DiagnosticVector3(diagnostic.BaseVelocity))
		PushDiagnosticLog("BaseState="..diagnostic.BaseState.." BaseFloor="..diagnostic.BaseFloor.." BaseJump="..tostring(diagnostic.BaseJump))
		PushDiagnosticLog("SentTarget="..DiagnosticVector3(targetPosition))
		PushDiagnosticLog(string.format("HYPOTHETICAL TARGETS (read-only; ACTUAL shot=%dms)",diagnostic.ActualPredictionMs or 60))
		for _,ms in ipairs(HYPOTHETICAL_MS) do
			PushDiagnosticLog(string.format("%dms=%s",ms,DiagnosticVector3(diagnostic.HypotheticalTargets[ms])))
		end

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
		PushDiagnosticLog("ShooterHRPLook="..DiagnosticVector3(hrp.CFrame.LookVector))
		PushDiagnosticLog("OriginCFramePosition="..DiagnosticVector3(originCFrame.Position))
		PushDiagnosticLog("OriginLook="..DiagnosticVector3(originCFrame.LookVector))
		PushDiagnosticLog("OriginRight="..DiagnosticVector3(originCFrame.RightVector))
		PushDiagnosticLog("OriginUp="..DiagnosticVector3(originCFrame.UpVector))
		PushDiagnosticLog("DestinationCFramePosition="..DiagnosticVector3(destinationCFrame.Position))
		PushDiagnosticLog("DestinationLook="..DiagnosticVector3(destinationCFrame.LookVector))
		PushDiagnosticLog("DestinationRight="..DiagnosticVector3(destinationCFrame.RightVector))
		PushDiagnosticLog("DestinationUp="..DiagnosticVector3(destinationCFrame.UpVector))

		local camera = workspace.CurrentCamera
		if camera then
			PushDiagnosticLog("CameraPosition="..DiagnosticVector3(camera.CFrame.Position))
			PushDiagnosticLog("CameraLook="..DiagnosticVector3(camera.CFrame.LookVector))
		end

		local handle = gun:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then
			PushDiagnosticLog("GunHandlePosition="..DiagnosticVector3(handle.Position))
			PushDiagnosticLog("GunHandleLook="..DiagnosticVector3(handle.CFrame.LookVector))
			PushDiagnosticLog(string.format("HandleToTarget=%.3f HRPToHandle=%.3f",
				(handle.Position-targetPosition).Magnitude,
				(hrp.Position-handle.Position).Magnitude
			))
		else
			PushDiagnosticLog("GunHandle=unavailable")
		end

		local originDot = originCFrame.LookVector:Dot((destinationCFrame.Position-originCFrame.Position).Unit)
		PushDiagnosticLog(string.format("OriginLookDotToTarget=%.6f",originDot))
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
		local fireHitbox = InspectCharacterAgainstShot(diagnostic.Player and diagnostic.Player.Character,originCFrame.Position,destinationCFrame.Position)
		PushDiagnosticLog("FIRE-TIME HITBOX CHECK")
		PushDiagnosticLog("------------------------------------------------------------")
		PushDiagnosticLog("IntersectedParts="..JoinIntersectionNames(fireHitbox))
		PushDiagnosticLog(string.format("NearestPartCenter=%s Distance=%.3f",
			tostring(fireHitbox.NearestPart or "NONE"),
			fireHitbox.NearestCenterDistance < math.huge and fireHitbox.NearestCenterDistance or -1
		))
	end

	-- SERVER-FACING / PAYLOAD DIAGNOSTIC (read-only logging; shot unchanged)
	if ExactFireDiagnostic.Enabled and diagnostic then
		PushDiagnosticLog("SERVER-FACING FIRE SNAPSHOT")
		PushDiagnosticLog("------------------------------------------------------------")
		PushDiagnosticLog("RemotePath="..shoot:GetFullName())
		PushDiagnosticLog("RemoteClass="..shoot.ClassName)
		PushDiagnosticLog("RemoteParent="..(shoot.Parent and shoot.Parent:GetFullName() or "nil"))
		PushDiagnosticLog("GunPath="..gun:GetFullName())
		PushDiagnosticLog("GunParent="..(gun.Parent and gun.Parent:GetFullName() or "nil"))
		PushDiagnosticLog("GunEquipped="..tostring(gun.Parent == character))
		PushDiagnosticLog("ArgCount=2")
		PushDiagnosticLog("Arg1Type="..typeof(originCFrame).." Arg1CFramePos="..DiagnosticVector3(originCFrame.Position))
		PushDiagnosticLog("Arg1Look="..DiagnosticVector3(originCFrame.LookVector))
		PushDiagnosticLog("Arg2Type="..typeof(destinationCFrame).." Arg2CFramePos="..DiagnosticVector3(destinationCFrame.Position))
		PushDiagnosticLog("PayloadOriginToDestination="..string.format("%.3f",(originCFrame.Position-destinationCFrame.Position).Magnitude))

		local attrs = gun:GetAttributes()
		local attrNames = {}
		for name in pairs(attrs) do table.insert(attrNames,name) end
		table.sort(attrNames)
		if #attrNames == 0 then
			PushDiagnosticLog("GunAttributes=NONE")
		else
			for _,name in ipairs(attrNames) do
				local value = attrs[name]
				PushDiagnosticLog("GunAttribute["..tostring(name).."]="..tostring(value).." ("..typeof(value)..")")
			end
		end

		local children = {}
		for _,child in ipairs(gun:GetChildren()) do
			table.insert(children,child.Name..":"..child.ClassName)
		end
		table.sort(children)
		PushDiagnosticLog("GunChildren="..(#children > 0 and table.concat(children,",") or "NONE"))
		PushDiagnosticLog("FireCallClock="..string.format("%.6f",os.clock()))
	end

	local preFireState = nil
	if ExactFireDiagnostic.Enabled and diagnostic then
		preFireState = ReadGunFireState(gun,character)
		diagnostic.PreFireState = preFireState
		LogGunFireState("PRE-FIRE STATE",preFireState)
	end

	-- BOUNDARY-V3 STRICT FINAL FIRE GATE:
	-- This is the last possible check before the server-facing RemoteEvent.
	-- The earlier gate protects shot construction; this one guarantees that
	-- DiagnosticAutoVYShot never sends a diagnostic shot if the target has
	-- drifted outside VY -35..-45 (inclusive) while logs were being built.
	if Flags.DiagnosticAutoVYShot and not Flags.GeneralPredictionDiagnostic and diagnostic then
		local finalTargetPart = diagnostic.Torso
		local finalVelocity = finalTargetPart and finalTargetPart.Parent and finalTargetPart.AssemblyLinearVelocity or nil
		local finalHorizontalSpeed = finalVelocity and Vector3.new(finalVelocity.X,0,finalVelocity.Z).Magnitude or math.huge
		local finalVY = finalVelocity and finalVelocity.Y or math.huge
		local finalInWindow = finalVY >= -45 and finalVY <= -35
		local finalCleanVertical = finalHorizontalSpeed <= 1.0

		PushDiagnosticLog(string.format(
			"BOUNDARY-V3 FINAL FIRE GATE: VY=%.3f HSpeed=%.3f InWindow=%s CleanVertical=%s",
			finalVY,finalHorizontalSpeed,tostring(finalInWindow),tostring(finalCleanVertical)
		))

		if not finalInWindow or not finalCleanVertical then
			PushDiagnosticLog("BOUNDARY-V3 FIRE REJECTED: no FireServer call was sent")
			-- This was not a real test shot. Restore the sequence so the same
			-- endpoint offset is retried on the next valid window entry.
			ExactFireDiagnostic.ShotNumber = math.max(0,ExactFireDiagnostic.ShotNumber-1)
			ExactFireDiagnostic.Pending = nil
			SetDiagnosticStatus(string.format(
				"STRICT GATE REJECTED\nVY %.3f | HSpeed %.3f\nNo server shot sent; retrying same offset",
				finalVY,finalHorizontalSpeed
			))
			return false
		end
	end

	local remoteStart = os.clock()
	shoot:FireServer(originCFrame,destinationCFrame)

	if ExactFireDiagnostic.Enabled and diagnostic then
		diagnostic.RemoteReturnClock = os.clock()
		PushDiagnosticLog("SERVER-FACING FIRE RETURN")
		PushDiagnosticLog("------------------------------------------------------------")
		PushDiagnosticLog("RemoteStillParented="..tostring(shoot.Parent ~= nil))
		PushDiagnosticLog("GunStillEquipped="..tostring(gun.Parent == character))
		PushDiagnosticLog(string.format(
			"FireServerReturn=%.3fms",
			(diagnostic.RemoteReturnClock-remoteStart)*1000
		))
		local returnState = ReadGunFireState(gun,character)
		diagnostic.ReturnFireState = returnState
		LogGunFireState("IMMEDIATE POST-FIRE STATE",returnState)
		task.spawn(function()
			for _,delaySeconds in ipairs({0.016,0.050,0.100,0.250}) do
				local waitFor = delaySeconds-(os.clock()-remoteStart)
				if waitFor > 0 then task.wait(waitFor) end
				if gun and gun.Parent then
					LogGunFireState(string.format("GUN STATE +%.0fMS",delaySeconds*1000),ReadGunFireState(gun,character))
				else
					PushDiagnosticLog(string.format("GUN STATE +%.0fMS: gun unavailable",delaySeconds*1000))
				end
			end
		end)
		PushDiagnosticLog("POST-FIRE HITBOX TRACKING: every Heartbeat through 100ms, then 150/200ms")
		PushDiagnosticLog("------------------------------------------------------------")
		ExactFireDiagnostic.Pending = nil
		MonitorExactFireDiagnostic(diagnostic)
	end

	return true
end

--============================================================
-- RAGE SHOOT - restored from the older working implementation
-- Uses the old target-local CFrame construction and has NO LOS requirement.
-- Kept separate from FireCombatGun so Legit/diagnostic behavior stays intact.
--============================================================

local function FireRageCombatGun(gun,targetPosition)
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
	shoot:FireServer(originCFrame,destinationCFrame)
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
			return false,"No Murderer"
		end
		local torso = GetCombatTorso(murderer.Character)
		if not torso then
			return false,"No Target"
		end
		local gun = EnsureCombatGun()
		if not gun then
			return false,"No Gun"
		end

		task.wait(0.12)

		if not IsLivePlayer(murderer) then
			return false,"No Murderer"
		end
		torso = GetCombatTorso(murderer.Character)
		if not torso then
			return false,"No Target"
		end

		local targetPosition = GetProductionShootTargetPosition(torso)
		if not FireRageCombatGun(gun,targetPosition) then
			return false,"Shot Failed"
		end
		LastManualShot = os.clock()
		return true,"Shot Fired"
	end)
	ShootBusy = false
	if not ok then
		warn("[MM2 RAGE SHOOT ERROR]",success)
		return false,"Error"
	end
	return success,message
end

-- Forward declaration: ShootMurdererLegit revalidates diagnostic cases before the matcher is defined below.
local GeneralDiagnosticMatches

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
		if not IsLivePlayer(murderer) then return false,"No Gun or Murderer" end
		torso = GetCombatTorso(murderer.Character)
		if not torso then return false,"No Gun or Murderer" end
		if not HasClearLineOfSight(torso) then return false,"Murderer Behind Wall" end

		-- Revalidate the selected diagnostic case at the exact fire point.
		-- This prevents FAST_FALL (and other narrow cases) from matching in the
		-- auto-trigger loop, then firing after the target has already left the window.
		if Flags.GeneralPredictionDiagnostic and GeneralDiagnosticRequestedCase then
			local diagnosticHumanoid = murderer.Character and murderer.Character:FindFirstChildOfClass("Humanoid")
			if not diagnosticHumanoid or not GeneralDiagnosticMatches(GeneralDiagnosticRequestedCase,torso,diagnosticHumanoid) then
				return false,"Diagnostic Window Missed"
			end
		end

		local targetPosition = GetProductionShootTargetPosition(torso)
		if Flags.GeneralPredictionDiagnostic and GeneralDiagnosticRequestedCase then
			-- Diagnostic A/B mode: the chooser controls the ACTUAL server-facing
			-- XYZ prediction for this diagnostic shot only. Production is unchanged.
			-- Read the TextBox again at the exact fire point. This prevents a typed
			-- value (for example 30) from being missed if FocusLost has not fired yet.
			local typedMs = tonumber((PredictionMsBox.Text or ""):gsub("%s+",""))
			local actualMs = math.clamp(typedMs or tonumber(GeneralDiagnosticPredictionMs) or 60,0,250)
			GeneralDiagnosticPredictionMs = actualMs
			targetPosition = GetManualShootTargetPosition(torso,true,actualMs/1000)
			if not ExactFireDiagnostic.Pending then
				BeginExactFireDiagnostic(murderer,torso,os.clock(),targetPosition,actualMs,0)
			end
		end
		if not FireCombatGun(gun,targetPosition) then
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
-- GENERAL PREDICTION DIAGNOSTIC AUTO-TRIGGER
-- Fires only through ShootMurdererLegit, so normal visibility/cooldown/gun checks remain intact.
-- The diagnostic can override prediction for diagnostic shots only; production prediction remains unchanged.
--============================================================
local function GeneralDiagnosticBaseMatches(caseName,torso,humanoid)
	if not torso or not humanoid or humanoid.Health <= 0 then return false end
	local v = torso.AssemblyLinearVelocity
	local hs = Vector3.new(v.X,0,v.Z).Magnitude
	local airborne = humanoid.FloorMaterial == Enum.Material.Air
	if caseName == "GROUNDED_HORIZONTAL" then
		return hs >= 8 and math.abs(v.Y) <= 5 and not airborne
	elseif caseName == "EARLY_RISE" then
		return airborne and hs < 8 and v.Y >= 35
	elseif caseName == "LATE_RISE" then
		return airborne and hs < 8 and v.Y >= 12 and v.Y < 35
	elseif caseName == "APEX" then
		return airborne and math.abs(v.Y) <= 6 and hs < 8
	elseif caseName == "NORMAL_FALL" then
		return airborne and hs < 8 and v.Y <= -12 and v.Y >= -30
	elseif caseName == "FAST_FALL" then
		return airborne and v.Y <= -35 and v.Y >= -45 and hs <= 2
	elseif caseName == "DIAGONAL_RISE" then
		return airborne and hs >= 8 and v.Y >= 12
	elseif caseName == "DIAGONAL_FALL" then
		-- Fast diagonal-fall sample: wait until the target is genuinely descending fast.
		return airborne and hs >= 8 and v.Y >= -45 and v.Y <= -30
	elseif caseName == "DIRECTION_CHANGE" then
		local samples = DiagnosticMotionBuffers[torso.Parent and Players:GetPlayerFromCharacter(torso.Parent)]
		if samples and #samples >= 2 and hs >= 8 then
			local old = samples[math.max(1,#samples-1)].Velocity
			local a,b = Vector3.new(old.X,0,old.Z),Vector3.new(v.X,0,v.Z)
			return a.Magnitude >= 8 and b.Magnitude >= 8 and a.Unit:Dot(b.Unit) < 0.35
		end
		return false
	elseif caseName == "JUMP_SPAM" then
		return airborne and hs >= 4 and math.abs(v.Y) >= 8
	end
	return false
end


GeneralDiagnosticMatches = function(caseName,torso,humanoid)
    if not GeneralDiagnosticBaseMatches(caseName,torso,humanoid) then return false end
    if not GeneralDiagnosticCustomWindowEnabled then return true end
    local v = torso.AssemblyLinearVelocity
    local hs = Vector3.new(v.X,0,v.Z).Magnitude
    -- Normalize custom bounds so either entry order works.
    -- Example: VY Min=-35 / VY Max=-45 means the valid interval is -45..-35.
    if GeneralDiagnosticVYMin ~= nil and GeneralDiagnosticVYMax ~= nil then
        local vyLow = math.min(GeneralDiagnosticVYMin,GeneralDiagnosticVYMax)
        local vyHigh = math.max(GeneralDiagnosticVYMin,GeneralDiagnosticVYMax)
        if v.Y < vyLow or v.Y > vyHigh then return false end
    elseif GeneralDiagnosticVYMin ~= nil and v.Y < GeneralDiagnosticVYMin then
        return false
    elseif GeneralDiagnosticVYMax ~= nil and v.Y > GeneralDiagnosticVYMax then
        return false
    end

    if GeneralDiagnosticHSMin ~= nil and GeneralDiagnosticHSMax ~= nil then
        local hsLow = math.min(GeneralDiagnosticHSMin,GeneralDiagnosticHSMax)
        local hsHigh = math.max(GeneralDiagnosticHSMin,GeneralDiagnosticHSMax)
        if hs < hsLow or hs > hsHigh then return false end
    elseif GeneralDiagnosticHSMin ~= nil and hs < GeneralDiagnosticHSMin then
        return false
    elseif GeneralDiagnosticHSMax ~= nil and hs > GeneralDiagnosticHSMax then
        return false
    end
    return true
end

task.spawn(function()
	while task.wait(0.01) do
		if Flags.GeneralPredictionDiagnostic and ExactFireDiagnostic.Enabled then
			local wanted = GENERAL_DIAGNOSTIC_CASES[GeneralDiagnosticSelectedIndex]
			local murderer = FindLiveMurderer()
			local torso = murderer and GetCombatTorso(murderer.Character)
			local humanoid = murderer and murderer.Character and murderer.Character:FindFirstChildOfClass("Humanoid")
			if torso and humanoid then
				local v = torso.AssemblyLinearVelocity
				local hs = Vector3.new(v.X,0,v.Z).Magnitude
				local windowText = GeneralDiagnosticCustomWindowEnabled and string.format("CUSTOM VY[%s,%s] HS[%s,%s]", tostring(GeneralDiagnosticVYMin or "*"), tostring(GeneralDiagnosticVYMax or "*"), tostring(GeneralDiagnosticHSMin or "*"), tostring(GeneralDiagnosticHSMax or "*")) or "AUTO WINDOW"
				SetDiagnosticStatus(string.format("SELECTED: %s\nHSpeed %.1f | VY %.1f\n%s",wanted,hs,v.Y,windowText))
				if not ShootBusy and os.clock()-LastManualShot >= SHOT_COOLDOWN and HasClearLineOfSight(torso) and GeneralDiagnosticMatches(wanted,torso,humanoid) then
					GeneralDiagnosticRequestedCase = wanted
					local ok = MM2.Functions.ShootMurdererLegit()
					GeneralDiagnosticRequestedCase = nil
					if not ok and ExactFireDiagnostic.Pending then ExactFireDiagnostic.Pending = nil end
				end
			end
		end
	end
end)

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

local function ThrowAimbotOnce()
	if Flags.WallThrow then
		return RageThrowOnce()
	end
	return LegitThrowOnce()
end
MM2.Functions.ThrowAimbotOnce = ThrowAimbotOnce

task.spawn(function()
	while MM2.Running do
		if Flags.LegitThrow then
			if Flags.WallThrow then
				RageThrowOnce()
			else
				LegitThrowOnce()
			end
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
		if KnifeRangeSuppressActivated or not Flags.KnifeAura then return end
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
		local targets = GetKnifeTargetsInRange(KILL_ALL_RANGE)
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

local TriggerBotBusy = false

local function UpdateCombatFeatures()
	local camera = workspace.CurrentCamera
	if not camera then return end

	local active = Flags.TriggerBot or Flags.AimLock
	if not active then
		return
	end
	if Flags.AimLock and IsAimLockAllowed() then
		local _,targetPart = GetBestCombatTarget()
		if targetPart then
			camera.CFrame = CFrame.new(camera.CFrame.Position,targetPart.Position)
		end
	end

	-- TriggerBot is visibility based, not crosshair based:
	-- visible murderer -> equip gun if needed -> predicted shot -> cooldown.
	if not Flags.TriggerBot or TriggerBotBusy or ShootBusy then return end
	local now = os.clock()
	if now-LastTriggerShot < SHOT_COOLDOWN or now-LastManualShot < SHOT_COOLDOWN then return end

	local murderer = FindLiveMurderer()
	local targetPart = murderer and GetCombatTorso(murderer.Character)
	if not murderer or not targetPart or not IsLivePlayer(murderer) then return end
	if not HasClearLineOfSight(targetPart) then return end

	TriggerBotBusy = true
	task.spawn(function()
		local ok = pcall(function()
			local delaySeconds = math.clamp(tonumber(Flags.TriggerBotDelay) or 0.05,0,0.60)
			if delaySeconds > 0 then
				task.wait(delaySeconds)
			end
			if not Flags.TriggerBot or not IsLivePlayer(murderer) then return end
			targetPart = GetCombatTorso(murderer.Character)
			if not targetPart or not HasClearLineOfSight(targetPart) then return end
			-- Revalidate again after equipping because the target may move behind a wall.
			local gun = EnsureCombatGun()
			if not gun or not Flags.TriggerBot or not IsLivePlayer(murderer) then return end
			targetPart = GetCombatTorso(murderer.Character)
			if not targetPart or not HasClearLineOfSight(targetPart) then return end
			local fireNow = os.clock()
			if fireNow-LastTriggerShot < SHOT_COOLDOWN or fireNow-LastManualShot < SHOT_COOLDOWN then return end
			local targetPosition = GetProductionShootTargetPosition(targetPart)
			if FireCombatGun(gun,targetPosition) then
				LastTriggerShot = os.clock()
				LastManualShot = LastTriggerShot
			end
		end)
		if not ok then
			warn("[MM2 TRIGGERBOT] shot task failed")
		end
		TriggerBotBusy = false
	end)
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
--   KILL ALL   -> skull
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
					CombatNotify("Shoot Murderer","Error","circle-x",2)
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
					CombatNotify("Shoot Murderer","Error","circle-x",2)
					return
				end

				NotifyShootResult(success,message)
			end)
		end
	)

FloatingShootHolder.Visible = Flags.ShowShootButton == true
MM2.UI.FloatingShootButton = FloatingShootButton
MM2.UI.FloatingShootHolder = FloatingShootHolder

-- Throw Aimbot: existing crossed-swords icon with a red outline.
local FloatingThrowAimbotButton,FloatingThrowAimbotHolder =
	UI.CreateMovableCardButton(
		"FloatingThrowAimbot",
		"swords",
		"THROW",
		UDim2.new(0.67,-52,0.70,-42),
		function()
			task.spawn(function()
				local ok,success,message = pcall(function()
					return MM2.Functions.ThrowAimbotOnce()
				end)
				if not ok then
					warn("[MM2 THROW AIMBOT BUTTON]",success)
					CombatNotify("Throw Aimbot","Error","circle-x",2)
				elseif success then
					CombatNotify("Throw Aimbot","Knife Thrown","swords",1.8)
				elseif message then
					CombatNotify("Throw Aimbot",message,"circle-x",2.5)
				end
			end)
		end
	)

-- Red outline for the Murderer action card, when the shared card API returns a GuiObject holder.
if typeof(FloatingThrowAimbotHolder) == "Instance" then
	local stroke = FloatingThrowAimbotHolder:FindFirstChildWhichIsA("UIStroke",true)
	if stroke then
		stroke.Color = Color3.fromRGB(255,70,70)
	else
		stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(255,70,70)
		stroke.Thickness = 1.5
		stroke.Parent = FloatingThrowAimbotHolder
	end
end
FloatingThrowAimbotHolder.Visible = Flags.ShowThrowAimbotButton == true
MM2.UI.FloatingThrowAimbotButton = FloatingThrowAimbotButton
MM2.UI.FloatingThrowAimbotHolder = FloatingThrowAimbotHolder

-- Kill All: skull Lucide icon.
local FloatingKillAllButton,FloatingKillAllHolder =
	UI.CreateMovableCardButton(
		"FloatingKillAll",
		"skull",
		"KILL ALL",
		UDim2.new(0.67,-52,0.78,-42),
		function()
			local ok,success,message = pcall(function()
				return MM2.Functions.KillAllOnce()
			end)

			if not ok then
				warn("[MM2 KILL ALL BUTTON]",success)
				CombatNotify("Kill All","Kill All error","circle-x",2)
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
