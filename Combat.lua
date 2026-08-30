--============================================================
-- MM2 V8.7.0 LEGIT / RAGE SPLIT - Combat.lua
-- TriggerBot, Aim Lock, Shoot Murderer, Auto Throw, Auto Grab.
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

--============================================================
-- SMALL FLAG / UI HELPERS
--============================================================

local function SetFlag(flagName, value)
	Flags[flagName] = value

	-- Optional compatibility with UI systems that expose a toggle refresh/setter.
	if UI.SetToggleState then
		pcall(function()
			UI.SetToggleState(flagName, value)
		end)
	elseif UI.SetToggle then
		pcall(function()
			UI.SetToggle(flagName, value)
		end)
	end
end

local function EnableExclusive(activeFlag, otherFlag, on)
	SetFlag(activeFlag, on)

	if on then
		SetFlag(otherFlag, false)
	end
end

--============================================================
-- COMBAT UI
--============================================================

UI.AddSection(UI.CombatPage, "Combat", "Aim, pickup and weapon features")

UI.CreateToggle(
	UI.CombatPage,
	"TriggerBot",
	"Fire when the crosshair is on the murderer",
	"TriggerBot"
)

UI.CreateToggle(
	UI.CombatPage,
	"Aim Lock",
	"Torso aim lock in first-person / lock-center",
	"AimLock"
)

UI.CreateToggle(
	UI.CombatPage,
	"Auto Throw Knife (Legit)",
	"Automatically throws only when the target has line of sight",
	"AutoThrowLegit",
	function(on)
		EnableExclusive("AutoThrowLegit", "AutoThrowRage", on)
	end
)

UI.CreateToggle(
	UI.CombatPage,
	"Auto Throw Knife (Rage)",
	"Automatically throws at the closest player even through walls",
	"AutoThrowRage",
	function(on)
		EnableExclusive("AutoThrowRage", "AutoThrowLegit", on)
	end
)

UI.CreateToggle(
	UI.CombatPage,
	"Auto Grab Gun",
	"Automatically grabs the gun without moving your body",
	"AutoGrab"
)

UI.CreateToggle(
	UI.CombatPage,
	"Floating Shoot Buttons",
	"Show the movable Shoot Murderer (Legit) and (Rage) buttons",
	"ShowShootButton",
	function(on)
		if MM2.UI.FloatingShootLegitButton then
			MM2.UI.FloatingShootLegitButton.Visible = on
		end
		if MM2.UI.FloatingShootRageButton then
			MM2.UI.FloatingShootRageButton.Visible = on
		end
	end
)

Flags.ShowKillAllButton = false

if UI.CreateActionFeature then
	UI.CreateActionFeature(
		UI.CombatPage,
		"Shoot Murderer (Legit)",
		"Only shoots when the murderer is visible",
		function()
			if MM2.Functions.ShootMurdererLegit then
				local ok, success, message = pcall(MM2.Functions.ShootMurdererLegit)
				if not ok then
					warn("[MM2 SHOOT LEGIT ACTION]", success)
					MM2.Notify("Shoot error", 2)
				elseif message and message ~= "Cooldown" then
					MM2.Notify(message, 1.5)
				end
			end
		end
	)

	UI.CreateActionFeature(
		UI.CombatPage,
		"Shoot Murderer (Rage)",
		"Shoots the murderer even when a wall is between you",
		function()
			if MM2.Functions.ShootMurdererRage then
				local ok, success, message = pcall(MM2.Functions.ShootMurdererRage)
				if not ok then
					warn("[MM2 SHOOT RAGE ACTION]", success)
					MM2.Notify("Shoot error", 2)
				elseif message and message ~= "Cooldown" then
					MM2.Notify(message, 1.5)
				end
			end
		end
	)

	UI.CreateActionFeature(
		UI.CombatPage,
		"Kill All",
		"Stabs everyone when murderer",
		function()
			if MM2.Functions.KillAllOnce then
				local ok, success, message = pcall(MM2.Functions.KillAllOnce)
				if not ok then
					warn("[MM2 KILL ALL ACTION]", success)
					MM2.Notify("Kill All error", 2)
				elseif message and message ~= "Cooldown" then
					MM2.Notify(message, 1.5)
				end
			end
		end
	)
end

UI.CreateToggle(
	UI.CombatPage,
	"Show Kill All Button",
	"stab all button",
	"ShowKillAllButton",
	function(on)
		if MM2.UI.FloatingKillAllHolder then
			MM2.UI.FloatingKillAllHolder.Visible = on
		end
	end
)

--============================================================
-- CROSSHAIR / CONSTANTS
--============================================================

local CrosshairDot = Instance.new("Frame")
CrosshairDot.Name = "CrosshairDot"
CrosshairDot.AnchorPoint = Vector2.new(0.5, 0.5)
CrosshairDot.Position = UDim2.new(0.5, 0, 0.5, 0)
CrosshairDot.Size = UDim2.fromOffset(4, 4)
CrosshairDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
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

--============================================================
-- COMMON COMBAT HELPERS
--============================================================

local function GetCombatTorso(character)
	if not character then return nil end

	return character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
		or character:FindFirstChild("HumanoidRootPart")
end

local function IsLivePlayer(player)
	if not player or player == LocalPlayer then
		return false
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	return character ~= nil
		and humanoid ~= nil
		and humanoid.Health > 0
end

local function IsMurderer(player)
	if not IsLivePlayer(player) then
		return false
	end

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

-- Legit visibility check.
-- Returns true if nothing blocks the segment, or if the first hit belongs
-- to the target character.
local function HasCombatLineOfSight(targetCharacter, targetPart)
	local character = LocalPlayer.Character
	if not character or not targetCharacter or not targetPart then
		return false
	end

	local originPart = character:FindFirstChild("Head")
		or character:FindFirstChild("HumanoidRootPart")

	if not originPart then
		return false
	end

	local origin = originPart.Position
	local direction = targetPart.Position - origin

	if direction.Magnitude <= 0.05 then
		return true
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}
	params.IgnoreWater = true

	local result = workspace:Raycast(origin, direction, params)

	if not result then
		return true
	end

	return result.Instance
		and result.Instance:IsDescendantOf(targetCharacter)
		or false
end

local function IsAimLockAllowed()
	local camera = workspace.CurrentCamera
	local character = LocalPlayer.Character
	if not camera or not character then
		return false
	end

	local head = character:FindFirstChild("Head")
	if head and (camera.CFrame.Position - head.Position).Magnitude < 1 then
		return true
	end

	return UIS.MouseBehavior == Enum.MouseBehavior.LockCenter
end

local function GetBestCombatTarget()
	local camera = workspace.CurrentCamera
	if not camera then
		return nil, nil
	end

	local viewport = camera.ViewportSize
	local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
	local bestPlayer, bestPart, bestDistance = nil, nil, AIMLOCK_FOV

	for _, player in ipairs(Players:GetPlayers()) do
		if IsMurderer(player) then
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local torso = GetCombatTorso(character)

			if humanoid
				and humanoid.Health > 0
				and torso
				and MM2.IsPositionWithinESPDistance(torso.Position)
			then
				local screenPosition, onScreen = camera:WorldToViewportPoint(torso.Position)

				if onScreen and screenPosition.Z > 0 then
					local d = (
						Vector2.new(screenPosition.X, screenPosition.Y) - center
					).Magnitude

					if d < bestDistance then
						bestDistance = d
						bestPlayer = player
						bestPart = torso
					end
				end
			end
		end
	end

	return bestPlayer, bestPart
end

local function GetCombatCrosshairHit()
	local camera = workspace.CurrentCamera
	local character = LocalPlayer.Character
	if not camera or not character then
		return nil
	end

	local viewport = camera.ViewportSize
	local ray = camera:ViewportPointToRay(viewport.X / 2, viewport.Y / 2)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}
	params.IgnoreWater = true

	return workspace:Raycast(
		ray.Origin,
		ray.Direction * COMBAT_MAX_DISTANCE,
		params
	)
end

local function ResolveCombatPlayer(instance)
	if not instance then
		return nil
	end

	local current = instance

	while current and current ~= workspace do
		if current:IsA("Model") then
			local player = Players:GetPlayerFromCharacter(current)
			if player then
				return player
			end
		end

		current = current.Parent
	end

	return nil
end

--============================================================
-- GUN HELPERS
--============================================================

local function GetCombatGun()
	local character = LocalPlayer.Character
	if not character then
		return nil
	end

	local gun = character:FindFirstChild("Gun")
		or character:FindFirstChild("Revolver")

	if gun and gun:IsA("Tool") then
		return gun
	end

	return nil
end

local function GetBackpackGun()
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	if not backpack then
		return nil
	end

	local gun = backpack:FindFirstChild("Gun")
		or backpack:FindFirstChild("Revolver")

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

	local deadline = os.clock() + 0.75

	repeat
		task.wait(0.03)
		gun = GetCombatGun()
	until gun or os.clock() >= deadline

	return gun
end

local function FireCombatGun(gun, targetPosition)
	if not gun or typeof(targetPosition) ~= "Vector3" then
		return false
	end

	local character = LocalPlayer.Character
	if not character or gun.Parent ~= character then
		return false
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end

	local shoot = gun:FindFirstChild("Shoot")
	if not shoot or not shoot:IsA("RemoteEvent") then
		return false
	end

	local direction = targetPosition - hrp.Position
	if direction.Magnitude <= 0.1 then
		return false
	end

	local unitDirection = direction.Unit

	local originCFrame = CFrame.new(
		targetPosition - unitDirection * 2,
		targetPosition
	)

	local destinationCFrame = CFrame.new(targetPosition)

	shoot:FireServer(originCFrame, destinationCFrame)
	return true
end

--============================================================
-- SHOOT MURDERER - LEGIT / RAGE
--============================================================

local function ShootMurdererMode(mode)
	if ShootBusy then
		return false, "Busy"
	end

	local now = os.clock()
	if now - LastManualShot < SHOT_COOLDOWN then
		return false, "Cooldown"
	end

	local requireLOS = mode == "Legit"

	ShootBusy = true

	local ok, success, message = pcall(function()
		local murderer = FindLiveMurderer()
		if not murderer then
			return false, "No Murderer"
		end

		local torso = GetCombatTorso(murderer.Character)
		if not torso then
			return false, "No Target"
		end

		if requireLOS and not HasCombatLineOfSight(murderer.Character, torso) then
			return false, "Murderer Behind Wall"
		end

		local gun = EnsureCombatGun()
		if not gun then
			return false, "No Gun"
		end

		task.wait(0.12)

		if not IsLivePlayer(murderer) then
			return false, "No Murderer"
		end

		torso = GetCombatTorso(murderer.Character)
		if not torso then
			return false, "No Target"
		end

		-- Re-check after equipping / waiting so Legit never shoots through
		-- a wall the target moved behind.
		if requireLOS and not HasCombatLineOfSight(murderer.Character, torso) then
			return false, "Murderer Behind Wall"
		end

		local fired = FireCombatGun(gun, torso.Position)
		if not fired then
			return false, "Shot Failed"
		end

		LastManualShot = os.clock()
		return true, "Shot Fired"
	end)

	ShootBusy = false

	if not ok then
		warn("[MM2 V8.7 SHOOT ERROR]", success)
		return false, "Error"
	end

	return success, message
end

MM2.Functions.ShootMurdererLegit = function()
	return ShootMurdererMode("Legit")
end

MM2.Functions.ShootMurdererRage = function()
	return ShootMurdererMode("Rage")
end

-- Backwards-compatible old function name.
MM2.Functions.ShootMurderer = MM2.Functions.ShootMurdererRage

--============================================================
-- AUTO THROW KNIFE - LEGIT / RAGE
--============================================================

local LastAutoThrow = 0
local LastBlockedThrowNotice = 0

local function GetThrowTargetPart(character)
	if not character then
		return nil
	end

	return character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
		or character:FindFirstChild("HumanoidRootPart")
end

local function FindClosestThrowTarget(requireLOS)
	local character = LocalPlayer.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")

	if not hrp then
		return nil, nil, false
	end

	local bestPlayer, bestPart, bestDistance = nil, nil, math.huge
	local blockedTargetExists = false

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local targetCharacter = player.Character
			local humanoid = targetCharacter
				and targetCharacter:FindFirstChildOfClass("Humanoid")
			local part = GetThrowTargetPart(targetCharacter)

			if humanoid and humanoid.Health > 0 and part then
				local visible = true

				if requireLOS then
					visible = HasCombatLineOfSight(targetCharacter, part)
					if not visible then
						blockedTargetExists = true
					end
				end

				if visible then
					local distance = (part.Position - hrp.Position).Magnitude

					if distance < bestDistance then
						bestDistance = distance
						bestPlayer = player
						bestPart = part
					end
				end
			end
		end
	end

	return bestPlayer, bestPart, blockedTargetExists
end

local function AutoThrowOnce(mode)
	local requireLOS = mode == "Legit"

	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local hrp = character and character:FindFirstChild("HumanoidRootPart")

	if not character
		or not humanoid
		or humanoid.Health <= 0
		or not hrp
	then
		return false, "No Character"
	end

	local knife = character:FindFirstChild("Knife")

	if not knife then
		local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
		local stowed = backpack and backpack:FindFirstChild("Knife")

		if stowed then
			pcall(function()
				humanoid:EquipTool(stowed)
			end)

			task.wait(0.03)
			knife = character:FindFirstChild("Knife")
		end
	end

	if not knife or knife:GetAttribute("Disabled") == true then
		return false, "No Knife"
	end

	local events = knife:FindFirstChild("Events")
	local thrown = events and events:FindFirstChild("KnifeThrown")

	if not thrown or not thrown:IsA("RemoteEvent") then
		return false, "No Throw Remote"
	end

	local cooldown = 1.05 * (
		tonumber(knife:GetAttribute("ThrowSpeed")) or 1
	)

	if os.clock() - LastAutoThrow < cooldown then
		return false, "Cooldown"
	end

	local _, targetPart, blockedTargetExists =
		FindClosestThrowTarget(requireLOS)

	if not targetPart then
		if requireLOS and blockedTargetExists then
			MM2.State.AutoThrowStatus = "Murderer Behind Wall"

			if os.clock() - LastBlockedThrowNotice >= 1.5 then
				LastBlockedThrowNotice = os.clock()
				MM2.Notify("Murderer Behind Wall", 1)
			end

			return false, "Murderer Behind Wall"
		end

		MM2.State.AutoThrowStatus = "No Target"
		return false, "No Target"
	end

	-- Final LOS check immediately before the Legit throw.
	if requireLOS then
		local targetCharacter = targetPart.Parent

		if not targetCharacter
			or not HasCombatLineOfSight(targetCharacter, targetPart)
		then
			MM2.State.AutoThrowStatus = "Murderer Behind Wall"
			return false, "Murderer Behind Wall"
		end
	end

	local target = targetPart.Position
	local direction = target - hrp.Position

	direction = direction.Magnitude > 0.1
		and direction.Unit
		or Vector3.new(0, 0, -1)

	LastAutoThrow = os.clock()

	local ok = pcall(function()
		thrown:FireServer(
			CFrame.new(target - direction * 2, target),
			CFrame.new(target)
		)
	end)

	if ok then
		MM2.State.AutoThrowStatus = "Knife Thrown"
		return true, "Knife Thrown"
	end

	return false, "Throw Failed"
end

MM2.Functions.AutoThrowKnifeLegit = function()
	return AutoThrowOnce("Legit")
end

MM2.Functions.AutoThrowKnifeRage = function()
	return AutoThrowOnce("Rage")
end

-- Backwards-compatible name from your old file.
MM2.Functions.RageThrowOnce = MM2.Functions.AutoThrowKnifeRage

task.spawn(function()
	while MM2.Running do
		-- Hard mutual exclusion at runtime too, in case an older UI build
		-- somehow leaves both flag values true.
		if Flags.AutoThrowLegit and Flags.AutoThrowRage then
			SetFlag("AutoThrowRage", false)
		end

		if Flags.AutoThrowLegit then
			AutoThrowOnce("Legit")
		elseif Flags.AutoThrowRage then
			AutoThrowOnce("Rage")
		end

		task.wait(0.03)
	end
end)

--============================================================
-- KILL ALL
--============================================================

local KillAllBusy = false
local LastKillAll = 0
local KILL_ALL_COOLDOWN = 0.35

local function GetKillAllTargetPart(character)
	if not character then
		return nil
	end

	return character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
		or character:FindFirstChild("HumanoidRootPart")
end

local function FindKnifeTool()
	local character = LocalPlayer.Character
	local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")

	local function scan(container)
		if not container then
			return nil
		end

		for _, tool in ipairs(container:GetChildren()) do
			if tool:IsA("Tool")
				and (
					tool.Name == "Knife"
					or tool:GetAttribute("IsKnife") == true
				)
			then
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
	if not knife then
		return nil
	end

	if knife.Parent ~= character then
		local ok = pcall(function()
			humanoid:EquipTool(knife)
		end)

		if not ok then
			return nil
		end

		local deadline = os.clock() + 0.75

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
	if not knife then
		return nil
	end

	local handle = knife:FindFirstChild("Handle")

	if handle and handle:IsA("BasePart") then
		return handle
	end

	return knife:FindFirstChildWhichIsA("BasePart", true)
end

local function TouchKillTarget(knife, handle, targetPart)
	if not knife or not handle or not targetPart or not targetPart.Parent then
		return false
	end

	if not firetouchinterest then
		return false
	end

	return pcall(function()
		knife:Activate()
		firetouchinterest(handle, targetPart, 0)
		RunService.Heartbeat:Wait()
		firetouchinterest(handle, targetPart, 1)
	end)
end

MM2.Functions.KillAllOnce = function()
	if KillAllBusy then
		return false, "Busy"
	end

	local now = os.clock()
	if now - LastKillAll < KILL_ALL_COOLDOWN then
		return false, "Cooldown"
	end

	KillAllBusy = true
	local successCount = 0

	local ok, err = pcall(function()
		local knife = EnsureKnifeEquipped()

		if not knife then
			error("No Knife")
		end

		local handle = GetKnifeHandle(knife)

		if not handle then
			error("No Handle")
		end

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				local character = player.Character
				local humanoid = character
					and character:FindFirstChildOfClass("Humanoid")
				local targetPart = GetKillAllTargetPart(character)

				if humanoid and humanoid.Health > 0 and targetPart then
					if TouchKillTarget(knife, handle, targetPart) then
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

		if string.find(message, "No Knife", 1, true) then
			return false, "No Knife"
		elseif string.find(message, "No Handle", 1, true) then
			return false, "No Handle"
		end

		warn("[MM2 KILL ALL ERROR]", err)
		return false, "Error"
	end

	if successCount <= 0 then
		return false, "No Targets"
	end

	return true, "Triggered " .. successCount
end

--============================================================
-- TRIGGERBOT / AIM LOCK
--============================================================

local function UpdateCombatFeatures()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local active = Flags.TriggerBot or Flags.AimLock
	CrosshairDot.Visible = active

	if not active then
		return
	end

	if Flags.AimLock and IsAimLockAllowed() then
		local _, targetPart = GetBestCombatTarget()

		if targetPart then
			camera.CFrame = CFrame.new(
				camera.CFrame.Position,
				targetPart.Position
			)
		end
	end

	if not Flags.TriggerBot then
		return
	end

	local now = os.clock()

	if now - LastTriggerShot < SHOT_COOLDOWN then
		return
	end

	local gun = GetCombatGun()
	if not gun then
		return
	end

	local rayResult = GetCombatCrosshairHit()
	if not rayResult then
		return
	end

	local targetPlayer = ResolveCombatPlayer(rayResult.Instance)

	if not targetPlayer or not IsMurderer(targetPlayer) then
		return
	end

	local torso = GetCombatTorso(targetPlayer.Character)
	if not torso then
		return
	end

	if FireCombatGun(gun, torso.Position) then
		LastTriggerShot = os.clock()
	end
end

RunService:BindToRenderStep(
	"MM2_V8_CombatFeatures",
	Enum.RenderPriority.Camera.Value + 1,
	UpdateCombatFeatures
)

--============================================================
-- MOVABLE FLOATING SHOOT BUTTONS
--============================================================

local function MakeButtonMovable(button)
	local dragging = false
	local dragInput = nil
	local dragStart = nil
	local startPosition = nil
	local moved = false

	local function update(input)
		if not dragging or not dragStart or not startPosition then
			return
		end

		local delta = input.Position - dragStart

		if math.abs(delta.X) > 4 or math.abs(delta.Y) > 4 then
			moved = true
		end

		button.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end

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
						button:SetAttribute("_JustDragged", true)

						task.delay(0.08, function()
							if button and button.Parent then
								button:SetAttribute("_JustDragged", false)
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
		if input == dragInput then
			update(input)
		end
	end))
end

local function CreateFloatingShootButton(name, text, position)
	local button = Instance.new("TextButton")
	button.Name = name
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Position = position
	button.Size = UDim2.fromOffset(190, 60)
	button.BackgroundColor3 = UI.COLORS.Card
	button.BackgroundTransparency = 0.12
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = UI.COLORS.Text
	button.Font = Enum.Font.GothamBold
	button.TextSize = 15
	button.AutoButtonColor = true
	button.Active = true
	button.Visible = false
	button.ZIndex = 300
	button.Parent = UI.ScreenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 18)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = UI.COLORS.Accent
	stroke.Thickness = 1.4
	stroke.Transparency = 0.2
	stroke.Parent = button

	MakeButtonMovable(button)

	return button
end

local FloatingShootLegitButton = CreateFloatingShootButton(
	"FloatingShootMurdererLegit",
	"Shoot Murderer (Legit)",
	UDim2.new(0.78, 0, 0.67, 0)
)

local FloatingShootRageButton = CreateFloatingShootButton(
	"FloatingShootMurdererRage",
	"Shoot Murderer (Rage)",
	UDim2.new(0.78, 0, 0.76, 0)
)

MM2.UI.FloatingShootLegitButton = FloatingShootLegitButton
MM2.UI.FloatingShootRageButton = FloatingShootRageButton

-- Keep old reference alive for anything else that expects it.
MM2.UI.FloatingShootButton = FloatingShootLegitButton

local function HookShootButton(button, defaultText, shootFunction)
	Track(button.MouseButton1Click:Connect(function()
		if button:GetAttribute("_JustDragged") then
			return
		end

		button.Text = "CLICK DETECTED"

		task.spawn(function()
			local ok, success, message = pcall(shootFunction)

			if button and button.Parent then
				if not ok then
					warn("[MM2 V8.7 SHOOT BUTTON ERROR]", success)
					button.Text = "Error"
				else
					button.Text = tostring(
						message
						or (success and "Shot Fired" or "Shot Failed")
					)
				end
			end

			task.delay(1, function()
				if button and button.Parent then
					button.Text = defaultText
				end
			end)
		end)
	end))
end

HookShootButton(
	FloatingShootLegitButton,
	"Shoot Murderer (Legit)",
	MM2.Functions.ShootMurdererLegit
)

HookShootButton(
	FloatingShootRageButton,
	"Shoot Murderer (Rage)",
	MM2.Functions.ShootMurdererRage
)

-- Compact movable manual Kill All button.
if UI.CreateMovableCircleButton then
	local FloatingKillAllButton, FloatingKillAllHolder =
		UI.CreateMovableCircleButton(
			"FloatingKillAll",
			"💀",
			"KILL ALL",
			UDim2.new(0.67, -52, 0.78, -42),
			function()
				local ok, success, message = pcall(function()
					return MM2.Functions.KillAllOnce()
				end)

				if not ok then
					warn("[MM2 KILL ALL BUTTON]", success)
					MM2.Notify("Kill All error", 2)
				elseif message and message ~= "Cooldown" then
					MM2.Notify(message, 1.5)
				end
			end
		)

	FloatingKillAllHolder.Visible = false
	MM2.UI.FloatingKillAllButton = FloatingKillAllButton
	MM2.UI.FloatingKillAllHolder = FloatingKillAllHolder
end

--============================================================
-- AUTO GRAB
--============================================================

local MAX_GRAB_DISTANCE = 150
local AUTO_GRAB_TOUCH_BURST = 2

local function GetPickupPart(gun)
	if not gun then
		return nil
	end

	if gun:IsA("BasePart")
		and gun:FindFirstChildOfClass("TouchTransmitter")
	then
		return gun
	end

	for _, obj in ipairs(gun:GetDescendants()) do
		if obj:IsA("BasePart")
			and obj:FindFirstChildOfClass("TouchTransmitter")
		then
			return obj
		end
	end

	if gun:IsA("BasePart") then
		return gun
	end

	return gun:FindFirstChildWhichIsA("BasePart", true)
end

function MM2.IsPreRoundActive()
	for _, obj in ipairs(MM2.PlayerGui:GetDescendants()) do
		if obj:IsA("TextLabel") or obj:IsA("TextButton") then
			local text = string.lower(tostring(obj.Text or ""))

			if string.find(text, "intermission", 1, true)
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
		and (hrp.Position - position).Magnitude < MAX_GRAB_DISTANCE
		or false
end

local function IsLocalMurderer()
	local char = LocalPlayer.Character
	local backpack = LocalPlayer:FindFirstChild("Backpack")

	return MM2.HasTool(char, MM2.Config.KnifeNames)
		or MM2.HasTool(backpack, MM2.Config.KnifeNames)
		or MM2.State.ServerRolesCache[LocalPlayer.Name] == "Murderer"
end

local function TouchAutoGrabPart(localPart, pickupPart)
	if not localPart or not pickupPart or not pickupPart.Parent then
		return false
	end

	if not firetouchinterest then
		return false
	end

	return pcall(function()
		firetouchinterest(localPart, pickupPart, 0)
		RunService.Heartbeat:Wait()
		firetouchinterest(localPart, pickupPart, 1)
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
		gunDrop = workspace:FindFirstChild("GunDrop", true)
	end

	if not gunDrop then
		return
	end

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
		for _ = 1, AUTO_GRAB_TOUCH_BURST do
			if not Flags.AutoGrab
				or MM2.HasGunAnywhere()
				or not gunDrop.Parent
				or not targetPart.Parent
			then
				break
			end

			TouchAutoGrabPart(hrp, targetPart)

			if MM2.HasGunAnywhere() or not gunDrop.Parent then
				break
			end

			if torso then
				TouchAutoGrabPart(torso, targetPart)
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