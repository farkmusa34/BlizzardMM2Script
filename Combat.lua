local MM2 = getgenv and getgenv().MM2_V85_SPLIT or _G.MM2_V85_SPLIT
assert(MM2 and MM2.UI and MM2.UI.CombatPage, "Load Shared.lua + UI.lua first")

local Players = MM2.Services.Players
local RunService = MM2.Services.RunService
local UIS = MM2.Services.UserInputService
local LocalPlayer = MM2.LocalPlayer
local Flags = MM2.Flags
local UI = MM2.UI
local Track = MM2.Track

local CombatFeatureIcons = (UI.FeatureIcons and UI.FeatureIcons.Combat) or {}
local function CombatFeatureIcon(name,fallback)
	local icon = CombatFeatureIcons[name]
	if typeof(icon) == "string" and icon ~= "" then
		return icon
	end
	return fallback
end

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
Flags.SilentAim = Flags.SilentAim == true
UI.CreateToggle(UI.CombatPage, "Silent Aim", "Redirects your manual shots toward the enemy’s head.", "SilentAim")
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

UI.CreateToggle(UI.CombatPage, "Auto Throw Knife (RAGE)", "Automatically throws your knife at the closest visible player", "LegitThrow")
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
end, CombatFeatureIcon("KillAll","skull"))

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
	local originCFrame = CFrame.new(hrp.Position,targetPosition)
	local destinationCFrame = CFrame.new(targetPosition)
	shoot:FireServer(originCFrame,destinationCFrame)
	return true
end

--============================================================
-- RAGE SHOOT - restored from the older working implementation
-- Uses the old target-local CFrame construction and has NO LOS requirement.
-- Kept separate from FireCombatGun so LEGIT behavior stays intact.
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

--============================================================
-- SILENT AIM - MANUAL SHOT REDIRECTION
--============================================================
-- The normal gun script still performs the manual activation and FireServer.
-- Silent Aim only replaces that one manual Gun.Shoot destination.
-- Target/prediction is cached OUTSIDE __namecall so the hook itself does not
-- call Roblox methods and recursively re-enter __namecall.

local SilentAimHookInstalled = false
local SilentAimOldNamecall = nil
local SilentAimCachedTargetPosition = nil

local function GetSilentAimTargetPart(character)
	if not character then return nil end
	return character:FindFirstChild("Head")
		or character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
		or character:FindFirstChild("HumanoidRootPart")
end

local function UpdateSilentAimCache()
	SilentAimCachedTargetPosition = nil
	if not Flags.SilentAim then return end

	local murderer = FindLiveMurderer()
	if not murderer or not IsLivePlayer(murderer) then return end

	local targetPart = GetSilentAimTargetPart(murderer.Character)
	if not targetPart then return end

	SilentAimCachedTargetPosition = GetProductionShootTargetPosition(targetPart)
end

Track(RunService.RenderStepped:Connect(UpdateSilentAimCache))

local function IsLocalGunShootRemoteNoNamecalls(instance)
	if typeof(instance) ~= "Instance" then return false end
	if instance.Name ~= "Shoot" then return false end

	local tool = instance.Parent
	if not tool then return false end
	if tool.Name ~= "Gun" and tool.Name ~= "Revolver" then return false end

	local character = LocalPlayer.Character
	return character ~= nil and tool.Parent == character
end

local function InstallSilentAimHook()
	if SilentAimHookInstalled then return true end
	if not hookmetamethod or not getnamecallmethod then
		warn("[MM2 SILENT AIM] hookmetamethod/getnamecallmethod unavailable")
		return false
	end

	local oldNamecall
	local wrapClosure = newcclosure or function(fn) return fn end
	oldNamecall = hookmetamethod(game,"__namecall",wrapClosure(function(self,...)
		local method = getnamecallmethod()

		if Flags.SilentAim
			and method == "FireServer"
			and IsLocalGunShootRemoteNoNamecalls(self)
			and (not checkcaller or not checkcaller())
		then
			local targetPosition = SilentAimCachedTargetPosition
			if targetPosition then
				local args = {...}
				local originalOrigin = args[1]
				local originPosition = typeof(originalOrigin) == "CFrame" and originalOrigin.Position or nil

				if originPosition and (targetPosition-originPosition).Magnitude > 0.1 then
					args[1] = CFrame.new(originPosition,targetPosition)
					args[2] = CFrame.new(targetPosition)
					return oldNamecall(self,table.unpack(args))
				end
			end
		end

		return oldNamecall(self,...)
	end))

	SilentAimOldNamecall = oldNamecall
	SilentAimHookInstalled = true
	return true
end

InstallSilentAimHook()

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

		local targetPosition = GetProductionShootTargetPosition(torso)
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
	local character = LocalPlayer.Character
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	local hasKnife = MM2.HasTool(character,MM2.Config.KnifeNames)
		or MM2.HasTool(backpack,MM2.Config.KnifeNames)
		or (MM2.State and MM2.State.ServerRolesCache
			and MM2.State.ServerRolesCache[LocalPlayer.Name] == "Murderer")

	if not hasKnife then
		return false,"Murderer Role Required"
	end

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
		CombatFeatureIcon("LegitShoot","crosshair"),
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
		CombatFeatureIcon("RageShoot","zap"),
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
		CombatFeatureIcon("ThrowAimbot","sword"),
		"THROW\nKNIFE",
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
					CombatNotify("Throw Aimbot","Knife Thrown",CombatFeatureIcon("ThrowAimbot","sword"),1.8)
				elseif message then
					CombatNotify("Throw Aimbot",message,"circle-x",2.5)
				end
			end)
		end
	)

FloatingThrowAimbotHolder.Visible = Flags.ShowThrowAimbotButton == true
MM2.UI.FloatingThrowAimbotButton = FloatingThrowAimbotButton
MM2.UI.FloatingThrowAimbotHolder = FloatingThrowAimbotHolder

-- Kill All: skull Lucide icon.
local FloatingKillAllButton,FloatingKillAllHolder =
	UI.CreateMovableCardButton(
		"FloatingKillAll",
		CombatFeatureIcon("KillAll","skull"),
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

-- Throw Aimbot floating button: force the intended red outline.
if typeof(FloatingThrowAimbotHolder) == "Instance" then
	local throwStroke = FloatingThrowAimbotHolder:FindFirstChildWhichIsA("UIStroke",true)
	if not throwStroke then
		throwStroke = Instance.new("UIStroke")
		throwStroke.Thickness = 1.5
		throwStroke.Parent = FloatingThrowAimbotHolder
	end
	throwStroke.Color = Color3.fromRGB(255,70,70)
end

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
