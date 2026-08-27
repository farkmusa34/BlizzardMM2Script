--============================================================
-- MM2 V8.6.1 - Combat.lua
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

UI.AddSection(UI.CombatPage, "Combat", "Aim, pickup and weapon features")
UI.CreateToggle(UI.CombatPage, "TriggerBot", "Fire when the crosshair is on the murderer", "TriggerBot")
UI.CreateToggle(UI.CombatPage, "Aim Lock", "Torso aim lock in first-person / lock-center", "AimLock")
UI.CreateToggle(UI.CombatPage, "Auto Grab Gun", "Automatically grabs the gun without moving your body", "AutoGrab")
UI.CreateToggle(
	UI.CombatPage,
	"Floating Shoot Button",
	"Show a draggable Shoot Murderer button",
	"ShowShootButton",
	function(on)
		if MM2.UI.FloatingShootButton then
			MM2.UI.FloatingShootButton.Visible = on
		end
	end
)

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

local FloatingShootButton = Instance.new("TextButton")
FloatingShootButton.Name = "FloatingShootMurderer"
FloatingShootButton.AnchorPoint = Vector2.new(0.5,0.5)
FloatingShootButton.Position = UDim2.new(0.78,0,0.72,0)
FloatingShootButton.Size = UDim2.fromOffset(190,60)
FloatingShootButton.BackgroundColor3 = UI.COLORS.Card
FloatingShootButton.BackgroundTransparency = 0.12
FloatingShootButton.BorderSizePixel = 0
FloatingShootButton.Text = "Shoot Murderer"
FloatingShootButton.TextColor3 = UI.COLORS.Text
FloatingShootButton.Font = Enum.Font.GothamBold
FloatingShootButton.TextSize = 15
FloatingShootButton.AutoButtonColor = false
FloatingShootButton.Active = true
FloatingShootButton.Draggable = true
FloatingShootButton.Visible = false
FloatingShootButton.ZIndex = 300
FloatingShootButton.Parent = UI.ScreenGui
MM2.UI.FloatingShootButton = FloatingShootButton

local c = Instance.new("UICorner")
c.CornerRadius = UDim.new(0,18)
c.Parent = FloatingShootButton

local s = Instance.new("UIStroke")
s.Color = UI.COLORS.Accent
s.Thickness = 1.4
s.Transparency = 0.2
s.Parent = FloatingShootButton

Track(FloatingShootButton.Activated:Connect(function()
	local success,message = MM2.Functions.ShootMurderer()
	FloatingShootButton.Text = tostring(message or (success and "Shot Fired" or "Shot Failed"))

	task.delay(0.75,function()
		if FloatingShootButton and FloatingShootButton.Parent then
			FloatingShootButton.Text = "Shoot Murderer"
		end
	end)
end))

--============================================================
-- AUTO GRAB
--============================================================

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
