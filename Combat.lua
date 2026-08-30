--============================================================
-- MM2 V8.7.0 LEGIT / RAGE COMBAT - Combat.lua
-- TriggerBot, Aim Lock, Shoot Murderer, Auto Grab.
--============================================================

local MM2 = getgenv and getgenv().MM2_V85_SPLIT or _G.MM2_V85_SPLIT
assert(MM2 and MM2.UI and MM2.UI.CombatPage and MM2.UI.TracerGui, "Load Shared.lua + UI.lua + Visuals.lua first")

local Players = MM2.Services.Players
local RunService = MM2.Services.RunService
local UIS = MM2.Services.UserInputService
local LocalPlayer = MM2.LocalPlayer
local Flags = MM2.Flags
local UI = MM2.UI
local Track = MM2.Track

UI.AddSection(UI.CombatPage, "Aim", "Crosshair and aiming features")
UI.CreateToggle(UI.CombatPage, "TriggerBot", "Fire when the crosshair is on the murderer", "TriggerBot")
UI.CreateToggle(UI.CombatPage, "Aim Lock", "Torso aim lock in first-person / lock-center", "AimLock")

UI.AddSection(UI.CombatPage, "Sheriff", "Legit and rage gun features")
UI.CreateToggle(UI.CombatPage, "Shoot Murderer (Legit)", "Requires clear line of sight; does not shoot through walls", "ShowLegitShootButton", function(on)
	if MM2.UI.FloatingLegitShootButton then MM2.UI.FloatingLegitShootButton.Visible = on end
end)
UI.CreateToggle(UI.CombatPage, "Shoot Murderer (Rage)", "Keeps the current behavior and can attempt shots through walls", "ShowShootButton", function(on)
	if MM2.UI.FloatingShootButton then MM2.UI.FloatingShootButton.Visible = on end
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

UI.CreateActionFeature(UI.CombatPage, "Kill All", "Stabs everyone when murderer", function()
	if MM2.Functions.KillAllOnce then
		local ok,success,message = pcall(MM2.Functions.KillAllOnce)
		if not ok then
			warn("[MM2 KILL ALL ACTION]",success)
			MM2.Notify("Kill All error",2)
		elseif message and message ~= "Cooldown" then
			MM2.Notify(message,1.5)
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
CrosshairDot.Parent = UI.TracerGui

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

-- Legit sheriff shot: same proven gun/equip path, but requires a clear ray to the murderer.
MM2.Functions.ShootMurdererLegit = function()
	if ShootBusy then return false,"Busy" end
	local now = os.clock()
	if now-LastManualShot < SHOT_COOLDOWN then return false,"Cooldown" end
	ShootBusy = true
	local ok,success,message = pcall(function()
		local murderer = FindLiveMurderer()
		if not murderer then return false,"No Murderer" end
		local torso = GetCombatTorso(murderer.Character)
		if not torso then return false,"No Target" end
		if not HasClearLineOfSight(torso) then return false,"Murderer Behind Wall" end
		local gun = EnsureCombatGun()
		if not gun then return false,"No Gun" end
		task.wait(0.12)
		if not IsLivePlayer(murderer) then return false,"No Murderer" end
		torso = GetCombatTorso(murderer.Character)
		if not torso then return false,"No Target" end
		if not HasClearLineOfSight(torso) then return false,"Murderer Behind Wall" end
		if not FireCombatGun(gun,torso.Position) then return false,"Shot Failed" end
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
-- Closest live-player knife throw using the diagnosed KnifeThrown
-- two-CFrame call. Only runs while a usable Knife exists.
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
		thrown:FireServer(CFrame.new(target-direction*2,target),CFrame.new(target))
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
-- KILL ALL
-- Uses the same compact Knife + TouchInterest path that worked in the
-- standalone diagnostic, but keeps it isolated from Shoot Murderer.
--============================================================

local KillAllBusy = false
local LastKillAll = 0
local KILL_ALL_COOLDOWN = 0.35

local function GetKillAllTargetPart(character)
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

local function TouchKillTarget(knife,handle,targetPart)
	if not knife or not handle or not targetPart or not targetPart.Parent then
		return false
	end
	if not firetouchinterest then
		return false
	end
	return pcall(function()
		knife:Activate()
		firetouchinterest(handle,targetPart,0)
		RunService.Heartbeat:Wait()
		firetouchinterest(handle,targetPart,1)
	end)
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
	local successCount = 0
	local ok,err = pcall(function()
		local knife = EnsureKnifeEquipped()
		if not knife then
			error("No Knife")
		end
		local handle = GetKnifeHandle(knife)
		if not handle then
			error("No Handle")
		end
		for _,player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				local character = player.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				local targetPart = GetKillAllTargetPart(character)
				if humanoid and humanoid.Health > 0 and targetPart then
					if TouchKillTarget(knife,handle,targetPart) then
						successCount += 1
					end
					task.wait(0.02)
				end
			end
		end
	end)
	LastKillAll = os.clock()
	KillAllBusy = false
	if not ok then
		local message = tostring(err)
		if string.find(message,"No Knife",1,true) then
			return false,"No Knife"
		elseif string.find(message,"No Handle",1,true) then
			return false,"No Handle"
		end
		warn("[MM2 KILL ALL ERROR]",err)
		return false,"Error"
	end
	if successCount <= 0 then
		return false,"No Targets"
	end
	return true,"Triggered "..successCount
end

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
			camera.CFrame = CFrame.new(camera.CFrame.Position,targetPart.Position)
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
	local torso = GetCombatTorso(targetPlayer.Character)
	if not torso then return end
	if FireCombatGun(gun,torso.Position) then
		LastTriggerShot = os.clock()
	end
end

RunService:BindToRenderStep(
	"MM2_V8_CombatFeatures",
	Enum.RenderPriority.Camera.Value+1,
	UpdateCombatFeatures
)

local function MakeShootButtonMovable(button)
	local dragging = false
	local moved = false
	local dragStart
	local startPosition
	local dragInput

	Track(button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			moved = false
			dragStart = input.Position
			startPosition = button.Position

			Track(input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if moved then
						button:SetAttribute("_JustDragged",true)
						task.delay(0.10,function()
							if button and button.Parent then
								button:SetAttribute("_JustDragged",false)
							end
						end)
					end
				end
			end))
		end
	end))

	Track(button.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragInput = input
		end
	end))

	Track(UIS.InputChanged:Connect(function(input)
		if not dragging or input ~= dragInput or not dragStart or not startPosition then return end
		local delta = input.Position-dragStart
		if delta.Magnitude >= 4 then moved = true end
		if moved then
			button.Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset+delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset+delta.Y
			)
		end
	end))
end

local FloatingShootButton = Instance.new("TextButton")
FloatingShootButton.Name = "FloatingShootMurderer"
FloatingShootButton.AnchorPoint = Vector2.new(0.5,0.5)
FloatingShootButton.Position = UDim2.new(0.78,0,0.72,0)
FloatingShootButton.Size = UDim2.fromOffset(190,60)
FloatingShootButton.BackgroundColor3 = UI.COLORS.Card
FloatingShootButton.BackgroundTransparency = 0.12
FloatingShootButton.BorderSizePixel = 0
FloatingShootButton.Text = "Shoot Murderer (Rage)"
FloatingShootButton.TextColor3 = UI.COLORS.Text
FloatingShootButton.Font = Enum.Font.GothamBold
FloatingShootButton.TextSize = 15
FloatingShootButton.AutoButtonColor = true
FloatingShootButton.Active = true
FloatingShootButton.Draggable = false
FloatingShootButton.Visible = false
FloatingShootButton.ZIndex = 300
FloatingShootButton.Parent = UI.ScreenGui
MM2.UI.FloatingShootButton = FloatingShootButton
MakeShootButtonMovable(FloatingShootButton)
FloatingShootButton.Visible = Flags.ShowShootButton == true

local c = Instance.new("UICorner")
c.CornerRadius = UDim.new(0,18)
c.Parent = FloatingShootButton

local s = Instance.new("UIStroke")
s.Color = UI.COLORS.Accent
s.Thickness = 1.4
s.Transparency = 0.2
s.Parent = FloatingShootButton

Track(FloatingShootButton.MouseButton1Click:Connect(function()
	if FloatingShootButton:GetAttribute("_JustDragged") then return end
	FloatingShootButton.Text = "CLICK DETECTED"
	task.spawn(function()
		local ok,success,message = pcall(function()
			return MM2.Functions.ShootMurderer()
		end)
		if FloatingShootButton and FloatingShootButton.Parent then
			if not ok then
				warn("[MM2 V8.6.2 SHOOT] BUTTON CALL ERROR:",success)
				FloatingShootButton.Text = "Error"
			else
				FloatingShootButton.Text = tostring(
					message or (success and "Shot Fired" or "Shot Failed")
				)
			end
		end
		task.delay(1,function()
			if FloatingShootButton and FloatingShootButton.Parent then
				FloatingShootButton.Text = "Shoot Murderer (Rage)"
			end
		end)
	end)
end))

local FloatingLegitShootButton = Instance.new("TextButton")
FloatingLegitShootButton.Name = "FloatingLegitShootMurderer"
FloatingLegitShootButton.AnchorPoint = Vector2.new(0.5,0.5)
FloatingLegitShootButton.Position = UDim2.new(0.78,0,0.64,0)
FloatingLegitShootButton.Size = UDim2.fromOffset(190,60)
FloatingLegitShootButton.BackgroundColor3 = UI.COLORS.Card
FloatingLegitShootButton.BackgroundTransparency = 0.12
FloatingLegitShootButton.BorderSizePixel = 0
FloatingLegitShootButton.Text = "Shoot Murderer (Legit)"
FloatingLegitShootButton.TextColor3 = UI.COLORS.Text
FloatingLegitShootButton.Font = Enum.Font.GothamBold
FloatingLegitShootButton.TextSize = 15
FloatingLegitShootButton.AutoButtonColor = true
FloatingLegitShootButton.Active = true
FloatingLegitShootButton.Draggable = false
FloatingLegitShootButton.Visible = false
FloatingLegitShootButton.ZIndex = 300
FloatingLegitShootButton.Parent = UI.ScreenGui
MM2.UI.FloatingLegitShootButton = FloatingLegitShootButton
MakeShootButtonMovable(FloatingLegitShootButton)
FloatingLegitShootButton.Visible = Flags.ShowLegitShootButton == true

local legitCorner = Instance.new("UICorner")
legitCorner.CornerRadius = UDim.new(0,18)
legitCorner.Parent = FloatingLegitShootButton
local legitStroke = Instance.new("UIStroke")
legitStroke.Color = UI.COLORS.Accent
legitStroke.Thickness = 1.4
legitStroke.Transparency = 0.2
legitStroke.Parent = FloatingLegitShootButton

Track(FloatingLegitShootButton.MouseButton1Click:Connect(function()
	if FloatingLegitShootButton:GetAttribute("_JustDragged") then return end
	task.spawn(function()
		local ok,success,message = pcall(function() return MM2.Functions.ShootMurdererLegit() end)
		if FloatingLegitShootButton and FloatingLegitShootButton.Parent then
			FloatingLegitShootButton.Text = ok and tostring(message or (success and "Shot Fired" or "Shot Failed")) or "Error"
			task.delay(1,function()
				if FloatingLegitShootButton and FloatingLegitShootButton.Parent then
					FloatingLegitShootButton.Text = "Shoot Murderer (Legit)"
				end
			end)
		end
	end)
end))

if UI.CreateMovableCircleButton then
	local FloatingKillAllButton,FloatingKillAllHolder = UI.CreateMovableCircleButton(
		"FloatingKillAll",
		"💀",
		"KILL ALL",
		UDim2.new(0.67,-52,0.78,-42),
		function()
			local ok,success,message = pcall(function()
				return MM2.Functions.KillAllOnce()
			end)
			if not ok then
				warn("[MM2 KILL ALL BUTTON]",success)
				MM2.Notify("Kill All error",2)
			elseif message and message ~= "Cooldown" then
				MM2.Notify(message,1.5)
			end
		end
	)
	FloatingKillAllHolder.Visible = false
	MM2.UI.FloatingKillAllButton = FloatingKillAllButton
	MM2.UI.FloatingKillAllHolder = FloatingKillAllHolder
end

local MAX_GRAB_DISTANCE = 150
local AUTO_GRAB_TOUCH_BURST = 2

local function GetPickupPart(gun)
	if not gun then return nil end
	if gun:IsA("BasePart") and gun:FindFirstChildOfClass("TouchTransmitter") then
		return gun
	end
	for _,obj in ipairs(gun:GetDescendants()) do
		if obj:IsA("BasePart") and obj:FindFirstChildOfClass("TouchTransmitter") then
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

local function IsGunWithinAutoGrabDistance(position)
	local hrp = LocalPlayer.Character
		and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	return hrp
		and position
		and (hrp.Position-position).Magnitude < MAX_GRAB_DISTANCE
		or false
end

local function IsLocalMurderer()
	local char = LocalPlayer.Character
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	return MM2.HasTool(char,MM2.Config.KnifeNames)
		or MM2.HasTool(backpack,MM2.Config.KnifeNames)
		or MM2.State.ServerRolesCache[LocalPlayer.Name] == "Murderer"
end

local function TouchAutoGrabPart(localPart,pickupPart)
	if not localPart or not pickupPart or not pickupPart.Parent then
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
	if not gunDrop then return end
	local targetPart = GetPickupPart(gunDrop)
	if not targetPart
		or not targetPart.Parent
		or not IsGunWithinAutoGrabDistance(targetPart.Position)
	then
		return
	end
	local char = LocalPlayer.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not char or not hrp or not humanoid or humanoid.Health <= 0 then
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
			task.wait(0.02)
		end
	end)
	MM2.State.Is_Picking_Up = false
end

return MM2
