--============================================================
-- Blizzard MM2 v1.85.4 - Player.lua
-- Movement, Jump, Bomb Boost, Utility.
--============================================================

local MM2 = getgenv and getgenv().MM2_V85_SPLIT or _G.MM2_V85_SPLIT
assert(MM2 and MM2.UI and MM2.UI.PlayerPage, "Load Shared.lua + UI.lua first")

local RunService = MM2.Services.RunService
local UIS = MM2.Services.UserInputService
local LocalPlayer = MM2.LocalPlayer
local Flags = MM2.Flags
local UI = MM2.UI
local Track = MM2.Track
local Settings = MM2.PlayerSettings
Settings.BoostPower = tonumber(Settings.BoostPower) or 62

--============================================================
-- STATE
--============================================================

local PlayerNoclipOriginal = {}

local FlyConnection = nil
local FlyVelocity = nil
local FlyOrientation = nil
local FlyHumanoid = nil
local MobileFlyUp = false
local MobileFlyDown = false
local MobileFlyUpButton = nil
local MobileFlyDownButton = nil

local PlayerNoclipConnection = nil

local LastSafeCFrame = nil
local VoidFallStarted = nil

local BombJumpBusy = false
local FloatingBombButton = nil

local WalkSpeedHumanoid = nil
local WalkSpeedChangedConnection = nil
local WalkSpeedEnforcerConnection = nil

--============================================================
-- WALK SPEED
--============================================================

local function DisconnectWalkSpeedWatcher()
	if WalkSpeedChangedConnection then
		WalkSpeedChangedConnection:Disconnect()
		WalkSpeedChangedConnection = nil
	end
	WalkSpeedHumanoid = nil
end

local function ApplyWalkSpeed()
	local _,humanoid = MM2.GetLocalCharacter()
	if not humanoid then
		return
	end
	local desired = math.clamp(
		tonumber(Settings.WalkSpeed) or 16,
		16,
		120
	)
	if humanoid.WalkSpeed ~= desired then
		humanoid.WalkSpeed = desired
	end
	if WalkSpeedHumanoid ~= humanoid then
		DisconnectWalkSpeedWatcher()
		WalkSpeedHumanoid = humanoid
		WalkSpeedChangedConnection =
			humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
				if not MM2.Running
					or not WalkSpeedHumanoid
					or not WalkSpeedHumanoid.Parent
				then
					return
				end
				local target = math.clamp(
					tonumber(Settings.WalkSpeed) or 16,
					16,
					120
				)
				if WalkSpeedHumanoid.WalkSpeed ~= target then
					WalkSpeedHumanoid.WalkSpeed = target
				end
			end)
	end
end

local function StartWalkSpeedEnforcer()
	if WalkSpeedEnforcerConnection then
		return
	end
	WalkSpeedEnforcerConnection =
		RunService.Stepped:Connect(function()
			if MM2.Running then
				ApplyWalkSpeed()
			end
		end)
	Track(WalkSpeedEnforcerConnection)
end

MM2.Functions.ApplyWalkSpeed = ApplyWalkSpeed

--============================================================
-- MOBILE FLY CONTROLS
--============================================================

local function IsMobileFlyDevice()
	return UIS.TouchEnabled
		and not UIS.KeyboardEnabled
end

local function StyleMobileFlyButton(button)
	button.Size = UDim2.fromOffset(58,58)
	button.BackgroundColor3 = Color3.fromRGB(18,18,24)
	button.BackgroundTransparency = 0.08
	button.TextSize = 28
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = Color3.fromRGB(255,255,255)
	button.AutoButtonColor = true
	button.ZIndex = 60
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1,0)
	corner.Parent = button
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(80,220,255)
	stroke.Parent = button
end

local function CreateMobileFlyButtons()
	if not IsMobileFlyDevice() then
		return
	end
	local overlay = UI.TracerGui or UI.ScreenGui
	if not overlay then
		return
	end
	if not MobileFlyUpButton then
		MobileFlyUpButton = Instance.new("TextButton")
		MobileFlyUpButton.Name = "MM2_MobileFlyUpButton"
		MobileFlyUpButton.AnchorPoint = Vector2.new(1,1)
		MobileFlyUpButton.Position = UDim2.new(1,-150,1,-150)
		MobileFlyUpButton.Text = "▲"
		StyleMobileFlyButton(MobileFlyUpButton)
		MobileFlyUpButton.Parent = overlay
		MobileFlyUpButton.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1
			then
				MobileFlyUp = true
			end
		end)
		MobileFlyUpButton.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1
			then
				MobileFlyUp = false
			end
		end)
	end
	if not MobileFlyDownButton then
		MobileFlyDownButton = Instance.new("TextButton")
		MobileFlyDownButton.Name = "MM2_MobileFlyDownButton"
		MobileFlyDownButton.AnchorPoint = Vector2.new(1,1)
		MobileFlyDownButton.Position = UDim2.new(1,-150,1,-85)
		MobileFlyDownButton.Text = "▼"
		StyleMobileFlyButton(MobileFlyDownButton)
		MobileFlyDownButton.Parent = overlay
		MobileFlyDownButton.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1
			then
				MobileFlyDown = true
			end
		end)
		MobileFlyDownButton.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1
			then
				MobileFlyDown = false
			end
		end)
	end
	MobileFlyUpButton.Visible = true
	MobileFlyDownButton.Visible = true
end

local function SetMobileFlyButtonsVisible(on)
	-- Fly uses joystick/camera movement directly; no extra Fly buttons.
	MobileFlyUp = false
	MobileFlyDown = false
	if MobileFlyUpButton then MobileFlyUpButton.Visible = false end
	if MobileFlyDownButton then MobileFlyDownButton.Visible = false end
end

--============================================================
-- FLY
-- Reconstructed from the read-only Fly diagnostics.
--============================================================

local function StopFly()
	if FlyConnection then
		FlyConnection:Disconnect()
		FlyConnection = nil
	end

	-- Match the observed shutdown order: velocity mover first, gyro second.
	if FlyVelocity then
		FlyVelocity:Destroy()
		FlyVelocity = nil
	end

	if FlyOrientation then
		FlyOrientation:Destroy()
		FlyOrientation = nil
	end

	if FlyHumanoid and FlyHumanoid.Parent then
		FlyHumanoid.PlatformStand = false
		FlyHumanoid.AutoRotate = true
	end

	FlyHumanoid = nil
	MobileFlyUp = false
	MobileFlyDown = false
	SetMobileFlyButtonsVisible(false)
end

MM2.Functions.StopFly = StopFly

local function StartFly()
	StopFly()

	local char,humanoid,hrp = MM2.GetLocalCharacter()
	if not char or not humanoid or not hrp then
		return
	end

	FlyHumanoid = humanoid

	-- Observed startup state.
	humanoid.PlatformStand = true
	humanoid.AutoRotate = false

	FlyVelocity = Instance.new("BodyVelocity")
	FlyVelocity.Name = "MarbegPlayerFlyVelocity"
	FlyVelocity.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
	FlyVelocity.P = 12000
	FlyVelocity.Velocity = Vector3.zero
	FlyVelocity.Parent = hrp

	FlyOrientation = Instance.new("BodyGyro")
	FlyOrientation.Name = "MarbegPlayerFlyGyro"
	FlyOrientation.MaxTorque = Vector3.new(math.huge,math.huge,math.huge)
	FlyOrientation.P = 9000
	FlyOrientation.D = 500
	FlyOrientation.CFrame = hrp.CFrame
	FlyOrientation.Parent = hrp

	if IsMobileFlyDevice() then
		SetMobileFlyButtonsVisible(true)
	end

	FlyConnection = RunService.RenderStepped:Connect(function()
		if not Flags.Fly then
			return
		end

		local currentChar,currentHumanoid,currentHRP = MM2.GetLocalCharacter()
		if not currentChar or not currentHumanoid or not currentHRP
			or currentHumanoid ~= FlyHumanoid
			or not FlyVelocity or not FlyVelocity.Parent
			or not FlyOrientation or not FlyOrientation.Parent
		then
			return
		end

		local cam = workspace.CurrentCamera
		if not cam then
			return
		end

		local camCF = cam.CFrame
		local look = camCF.LookVector
		local right = camCF.RightVector

		-- Gyro follows camera yaw only. The diagnostic showed Y=0 on its
		-- LookVector even while camera pitch affected flight direction.
		local flatLook = Vector3.new(look.X,0,look.Z)
		if flatLook.Magnitude > 0.01 then
			FlyOrientation.CFrame = CFrame.lookAt(Vector3.zero,flatLook.Unit)
		end

		local move = Vector3.zero

		if IsMobileFlyDevice() then
			-- Roblox MoveDirection is world-space, so project it onto the
			-- camera's horizontal forward/right axes, then rebuild movement
			-- with full camera LookVector so forward/backward keeps pitch.
			local md = currentHumanoid.MoveDirection
			if md.Magnitude > 0.01 then
				local flatForward = flatLook.Magnitude > 0.01 and flatLook.Unit or Vector3.zAxis
				local flatRight = Vector3.new(right.X,0,right.Z)
				if flatRight.Magnitude > 0.01 then
					flatRight = flatRight.Unit
				end

				local forwardAmount = md:Dot(flatForward)
				local rightAmount = md:Dot(flatRight)
				move += look * forwardAmount
				move += right * rightAmount
			end

			if MobileFlyUp then move += Vector3.yAxis end
			if MobileFlyDown then move -= Vector3.yAxis end
		else
			if UIS:IsKeyDown(Enum.KeyCode.W) then move += look end
			if UIS:IsKeyDown(Enum.KeyCode.S) then move -= look end
			if UIS:IsKeyDown(Enum.KeyCode.A) then move -= right end
			if UIS:IsKeyDown(Enum.KeyCode.D) then move += right end
			if UIS:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.yAxis end
			if UIS:IsKeyDown(Enum.KeyCode.LeftControl)
				or UIS:IsKeyDown(Enum.KeyCode.LeftShift)
			then
				move -= Vector3.yAxis
			end
		end

		local speed = math.clamp(tonumber(Settings.FlySpeed) or 65,10,200)
		if move.Magnitude > 0.01 then
			move = move.Unit * speed
		else
			move = Vector3.zero
		end

		FlyVelocity.Velocity = move
	end)
end

MM2.Functions.StartFly = StartFly

--============================================================
-- NOCLIP
--============================================================

local function ApplyPlayerNoclip()
	local char = LocalPlayer.Character
	if not char then return end
	for _,obj in ipairs(char:GetDescendants()) do
		if obj:IsA("BasePart") then
			if PlayerNoclipOriginal[obj] == nil then
				PlayerNoclipOriginal[obj] = obj.CanCollide
			end
			obj.CanCollide = false
		end
	end
end

--============================================================
-- NOCLIP VOID PROTECTION
--============================================================

local function RaycastGroundBelow(char,hrp,distance)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {char}
	params.IgnoreWater = false
	return workspace:Raycast(hrp.Position,Vector3.new(0,-distance,0),params)
end

local function UpdateNoclipVoidProtection()
	if not Flags.Noclip then
		LastSafeCFrame = nil
		VoidFallStarted = nil
		return
	end
	if Flags.Fly then
		VoidFallStarted = nil
		return
	end
	local char,humanoid,hrp = MM2.GetLocalCharacter()
	if not char or not humanoid or not hrp then return end
	local closeGround = RaycastGroundBelow(char,hrp,8)
	if closeGround and math.abs(hrp.AssemblyLinearVelocity.Y) < 25 then
		LastSafeCFrame = hrp.CFrame
		VoidFallStarted = nil
		return
	end
	if not LastSafeCFrame then return end
	local groundFarBelow = RaycastGroundBelow(char,hrp,120)
	local noGroundBelow = groundFarBelow == nil
	local fellFarBelowSafe = hrp.Position.Y < LastSafeCFrame.Position.Y - 35
	local isFalling = humanoid:GetState() == Enum.HumanoidStateType.Freefall
		or hrp.AssemblyLinearVelocity.Y < -20
	local likelyVoid = isFalling and noGroundBelow and fellFarBelowSafe
	if likelyVoid then
		if not VoidFallStarted then VoidFallStarted = os.clock() end
		if os.clock() - VoidFallStarted >= 1 then
			hrp.CFrame = LastSafeCFrame + Vector3.new(0,2,0)
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
			VoidFallStarted = nil
		end
	else
		VoidFallStarted = nil
	end
end

local function StartPlayerNoclip()
	if PlayerNoclipConnection then
		PlayerNoclipConnection:Disconnect()
	end
	table.clear(PlayerNoclipOriginal)
	LastSafeCFrame = nil
	VoidFallStarted = nil
	PlayerNoclipConnection = RunService.Stepped:Connect(function()
		if not Flags.Noclip then return end
		ApplyPlayerNoclip()
		UpdateNoclipVoidProtection()
	end)
	ApplyPlayerNoclip()
end

MM2.Functions.StartPlayerNoclip = StartPlayerNoclip

local function StopPlayerNoclip()
	if PlayerNoclipConnection then
		PlayerNoclipConnection:Disconnect()
		PlayerNoclipConnection = nil
	end
	for part,oldValue in pairs(PlayerNoclipOriginal) do
		if part and part.Parent then
			pcall(function() part.CanCollide = oldValue end)
		end
	end
	table.clear(PlayerNoclipOriginal)
	LastSafeCFrame = nil
	VoidFallStarted = nil
end

MM2.Functions.StopPlayerNoclip = StopPlayerNoclip

--============================================================
-- WALL CLIMB
--============================================================

local WALL_CHECK_DISTANCE = 3.25

local function IsTouchingWall()
	local char,_,hrp = MM2.GetLocalCharacter()
	if not char or not hrp then return false end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {char}
	local forward = Vector3.new(hrp.CFrame.LookVector.X,0,hrp.CFrame.LookVector.Z)
	if forward.Magnitude <= 0.01 then return false end
	forward = forward.Unit
	local right = Vector3.new(hrp.CFrame.RightVector.X,0,hrp.CFrame.RightVector.Z)
	if right.Magnitude > 0.01 then right = right.Unit end
	local origins = {
		hrp.Position,
		hrp.Position + right * 1.2,
		hrp.Position - right * 1.2,
	}
	for _,origin in ipairs(origins) do
		local result = workspace:Raycast(origin,forward * WALL_CHECK_DISTANCE,params)
		if result and result.Instance and result.Instance:IsA("BasePart") then
			if math.abs(result.Normal.Y) < 0.65 then
				return true
			end
		end
	end
	return false
end

MM2.Functions.IsTouchingWall = IsTouchingWall

--============================================================
-- BOMB JUMP
--============================================================

local BOMB_TOOL_NAMES = {
	["fake bomb"] = true,
	["fakebomb"] = true,
	["bomb"] = true,
}

local function IsBombTool(tool)
	if not tool or not tool:IsA("Tool") then return false end
	return BOMB_TOOL_NAMES[string.lower(tool.Name)] == true
end

local function FindBombTool()
	local char = LocalPlayer.Character
	if char then
		for _,obj in ipairs(char:GetChildren()) do
			if IsBombTool(obj) then return obj end
		end
	end
	local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
	if backpack then
		for _,obj in ipairs(backpack:GetChildren()) do
			if IsBombTool(obj) then return obj end
		end
	end
	return nil
end

local function TriggerBombJump()
	if BombJumpBusy then
		return false
	end
	BombJumpBusy = true
	local char,humanoid,hrp = MM2.GetLocalCharacter()
	local bomb = FindBombTool()
	if not char or not humanoid or not hrp then
		BombJumpBusy = false
		return false
	end
	if not bomb then
		BombJumpBusy = false
		MM2.Notify(
			"No bomb in inventory.",
			2.5,
			"bomb",
			"Bomb Jump"
		)
		return false
	end
	local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
	if not backpack then
		BombJumpBusy = false
		return false
	end
	humanoid:EquipTool(bomb)
	task.wait(0.06)
	humanoid:UnequipTools()
	task.wait(0.035)
	humanoid:EquipTool(bomb)
	task.wait(0.055)
	humanoid.Jump = true
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	task.wait(0.035)
	local boostPower = math.clamp(tonumber(Settings.BoostPower) or 62,20,150)
	local forward = Vector3.new(hrp.CFrame.LookVector.X,0,hrp.CFrame.LookVector.Z)
	local velocity = hrp.AssemblyLinearVelocity
	local boostX,boostZ = velocity.X,velocity.Z
	if forward.Magnitude > 0.01 then
		forward = forward.Unit
		boostX = boostX + forward.X * 8
		boostZ = boostZ + forward.Z * 8
	end
	hrp.AssemblyLinearVelocity = Vector3.new(
		boostX,
		math.max(velocity.Y,boostPower),
		boostZ
	)
	task.delay(0.30,function()
		BombJumpBusy = false
	end)
	return true
end

MM2.Functions.TriggerBombJump = TriggerBombJump

--============================================================
-- MOVABLE BOMB QUICK BUTTON
--============================================================

local FloatingBombHolder = nil

local function CreateBombJumpButton()
	if FloatingBombButton and FloatingBombHolder then
		FloatingBombHolder.Visible = true
		return
	end
	assert(UI.CreateMovableCardButton,"Updated UI.lua quick-button helper is required")
	FloatingBombButton,FloatingBombHolder =
		UI.CreateMovableCardButton(
			"FloatingBombJump",
			"bomb",
			"BOMB JUMP",
			UDim2.new(1,-80,0.68,0),
			function()
				TriggerBombJump()
			end,
			"orange"
		)
	MM2.UI.FloatingBombButton = FloatingBombButton
	MM2.UI.FloatingBombHolder = FloatingBombHolder
end

local function SetBombButtonVisible(on)
	if on then
		CreateBombJumpButton()
		if FloatingBombHolder then FloatingBombHolder.Visible = true end
	else
		if FloatingBombHolder then FloatingBombHolder.Visible = false end
	end
end

--============================================================
-- MOVEMENT SECTION
--============================================================

UI.AddSection(UI.PlayerPage,"Movement","Movement and mobility controls")

UI.CreateToggle(
	UI.PlayerPage,
	"Fly",
	"PC: WASD + Space/Ctrl. Mobile: joystick + Up/Down",
	"Fly",
	function(on)
		if on then StartFly() else StopFly() end
	end
)

UI.CreateSlider(
	UI.PlayerPage,
	"Fly Speed",
	"Adjust how fast you fly",
	function() return Settings.FlySpeed end,
	function(value) Settings.FlySpeed = value end,
	10,200,5
)

UI.CreateToggle(
	UI.PlayerPage,
	"Noclip",
	"Walk through objects with void protection",
	"Noclip",
	function(on)
		if on then StartPlayerNoclip() else StopPlayerNoclip() end
	end
)

local WalkSpeedSlider = UI.CreateSlider(
	UI.PlayerPage,
	"Walk Speed",
	"Sets and keeps your selected walk speed",
	function()
		return Settings.WalkSpeed
	end,
	function(value)
		Settings.WalkSpeed = math.clamp(
			tonumber(value) or 16,
			16,
			120
		)
		ApplyWalkSpeed()
	end,
	16,120,4
)

StartWalkSpeedEnforcer()
ApplyWalkSpeed()

task.spawn(function()
	task.wait(1.25)
	ApplyWalkSpeed()
	if WalkSpeedSlider then
		local value = math.clamp(tonumber(Settings.WalkSpeed) or 16,16,120)
		pcall(function()
			if WalkSpeedSlider.Set then
				WalkSpeedSlider:Set(value)
			elseif WalkSpeedSlider.SetValue then
				WalkSpeedSlider:SetValue(value)
			end
		end)
	end
end)

--============================================================
-- JUMP SECTION
--============================================================

UI.AddSection(UI.PlayerPage,"Jump","Jumping and climbing controls")

UI.CreateToggle(UI.PlayerPage,"Infinite Jump","Jump again while airborne","InfiniteJump")
UI.CreateToggle(UI.PlayerPage,"Wall Climb","Infinite jump only while touching a wall","WallClimb")

UI.CreateSlider(
	UI.PlayerPage,
	"Jump Power",
	"Sets your jump power",
	function() return Settings.JumpPower end,
	function(value)
		Settings.JumpPower = value
		local _,humanoid = MM2.GetLocalCharacter()
		if humanoid then
			humanoid.UseJumpPower = true
			humanoid.JumpPower = value
		end
	end,
	50,200,5
)

--============================================================
-- BOMB BOOST SECTION
--============================================================

UI.AddSection(UI.PlayerPage,"Bomb Boost","Fake Bomb movement techniques")

UI.CreateActionFeature(
	UI.PlayerPage,
	"Bomb Jump",
	"Perform one timed Fake Bomb jump",
	function() TriggerBombJump() end,
	"bomb",
	"orange"
)

UI.CreateSlider(
	UI.PlayerPage,
	"Boost Power",
	"Sets how high the boost blasts you upward",
	function() return Settings.BoostPower end,
	function(value)
		Settings.BoostPower = math.clamp(tonumber(value) or 62,20,150)
	end,
	20,150,2
)

UI.CreateToggle(
	UI.PlayerPage,
	"Bomb Jump Button",
	"Show the movable bomb jump button",
	"BombJumpButton",
	function(on) SetBombButtonVisible(on) end
)

--============================================================
-- UTILITY SECTION
--============================================================

UI.AddSection(UI.PlayerPage,"Utility","Player utilities")

UI.CreateActionFeature(
	UI.PlayerPage,
	"Reset Character",
	"Respawn your character",
	function()
		local char = LocalPlayer.Character
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.Health = 0 end
	end,
	"rotate-ccw"
)

--============================================================
-- JUMP INPUT
--============================================================

Track(UIS.JumpRequest:Connect(function()
	if Flags.Fly then
		if UIS.TouchEnabled then
			MobileFlyUp = true
			task.delay(0.12,function()
				MobileFlyUp = false
			end)
		end
		return
	end
	local _,humanoid = MM2.GetLocalCharacter()
	if not humanoid then return end
	if Flags.InfiniteJump then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		return
	end
	if Flags.WallClimb and IsTouchingWall() then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end))

--============================================================
-- RESPAWN
--============================================================

Track(LocalPlayer.CharacterAdded:Connect(function(char)
	LastSafeCFrame = nil
	VoidFallStarted = nil
	BombJumpBusy = false
	MobileFlyUp = false
	MobileFlyDown = false
	DisconnectWalkSpeedWatcher()
	task.wait(0.25)
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.UseJumpPower = true
		humanoid.JumpPower = Settings.JumpPower
	end
	ApplyWalkSpeed()
	if Flags.Fly then StartFly() end
	if Flags.Noclip then StartPlayerNoclip() end
	if Flags.BombJumpButton then SetBombButtonVisible(true) end
end))

return MM2
