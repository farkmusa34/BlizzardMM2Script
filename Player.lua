--============================================================
-- MM2 V8.6 REPLACEMENT - Player.lua
-- Fly, Noclip, Infinite Jump, Walk Speed, Jump Power, Reset.
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

UI.AddSection(UI.PlayerPage, "Player", "Movement and character controls")

local PlayerNoclipOriginal = {}
local FlyConnection = nil
local FlyAttachment = nil
local FlyVelocity = nil
local FlyOrientation = nil
local PlayerNoclipConnection = nil

local function StopFly()
	if FlyConnection then
		FlyConnection:Disconnect()
		FlyConnection = nil
	end
	if FlyVelocity then
		FlyVelocity:Destroy()
		FlyVelocity = nil
	end
	if FlyOrientation then
		FlyOrientation:Destroy()
		FlyOrientation = nil
	end
	if FlyAttachment then
		FlyAttachment:Destroy()
		FlyAttachment = nil
	end
end
MM2.Functions.StopFly = StopFly

local function StartFly()
	StopFly()

	local char,humanoid,hrp = MM2.GetLocalCharacter()
	if not char then return end

	FlyAttachment = Instance.new("Attachment")
	FlyAttachment.Name = "MM2_V8_FlyAttachment"
	FlyAttachment.Parent = hrp

	FlyVelocity = Instance.new("LinearVelocity")
	FlyVelocity.Name = "MM2_V8_FlyVelocity"
	FlyVelocity.Attachment0 = FlyAttachment
	FlyVelocity.MaxForce = math.huge
	FlyVelocity.VectorVelocity = Vector3.zero
	FlyVelocity.Parent = hrp

	FlyOrientation = Instance.new("AlignOrientation")
	FlyOrientation.Name = "MM2_V8_FlyOrientation"
	FlyOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	FlyOrientation.Attachment0 = FlyAttachment
	FlyOrientation.MaxTorque = math.huge
	FlyOrientation.Responsiveness = 20
	FlyOrientation.RigidityEnabled = false
	FlyOrientation.Parent = hrp

	FlyConnection = RunService.RenderStepped:Connect(function()
		if not Flags.Fly then return end

		local currentChar,currentHumanoid,currentHRP = MM2.GetLocalCharacter()
		if not currentChar or not FlyVelocity or not FlyVelocity.Parent then return end

		local cam = workspace.CurrentCamera
		if not cam then return end

		local move = Vector3.zero
		if UIS:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.yAxis end
		if UIS:IsKeyDown(Enum.KeyCode.LeftControl)
			or UIS:IsKeyDown(Enum.KeyCode.LeftShift)
		then
			move -= Vector3.yAxis
		end

		if move.Magnitude > 0 then
			move = move.Unit * Settings.FlySpeed
		end

		FlyVelocity.VectorVelocity = move

		local look = cam.CFrame.LookVector
		local flat = Vector3.new(look.X,0,look.Z)
		if flat.Magnitude > 0.01 then
			FlyOrientation.CFrame = CFrame.lookAt(Vector3.zero,flat.Unit)
		end

		currentHumanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	end)
end
MM2.Functions.StartFly = StartFly

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

local function StartPlayerNoclip()
	if PlayerNoclipConnection then
		PlayerNoclipConnection:Disconnect()
	end
	table.clear(PlayerNoclipOriginal)

	PlayerNoclipConnection = RunService.Stepped:Connect(function()
		if Flags.Noclip then
			ApplyPlayerNoclip()
		end
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
end
MM2.Functions.StopPlayerNoclip = StopPlayerNoclip

UI.CreateToggle(
	UI.PlayerPage,
	"Fly",
	"WASD + Space / Ctrl to move",
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
	"Disable character collisions",
	"Noclip",
	function(on)
		if on then StartPlayerNoclip() else StopPlayerNoclip() end
	end
)

UI.CreateToggle(
	UI.PlayerPage,
	"Infinite Jump",
	"Jump again while airborne",
	"InfiniteJump"
)

UI.CreateSlider(
	UI.PlayerPage,
	"Walk Speed",
	"Sets your walk speed",
	function() return Settings.WalkSpeed end,
	function(value)
		Settings.WalkSpeed = value
		local _,humanoid = MM2.GetLocalCharacter()
		if humanoid then humanoid.WalkSpeed = value end
	end,
	16,120,4
)

-- V8.6: Jump Power now uses the same slider style as Walk Speed/Fly Speed.
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
	20,150,5
)

UI.CreateActionButton(
	UI.PlayerPage,
	"RESET CHARACTER",
	function()
		local char = LocalPlayer.Character
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.Health = 0 end
	end,
	"danger"
)

Track(UIS.JumpRequest:Connect(function()
	if not Flags.InfiniteJump then return end
	local _,humanoid = MM2.GetLocalCharacter()
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end))

Track(LocalPlayer.CharacterAdded:Connect(function(char)
	task.wait(0.25)
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = Settings.WalkSpeed
		humanoid.UseJumpPower = true
		humanoid.JumpPower = Settings.JumpPower
	end

	if Flags.Fly then StartFly() end
	if Flags.Noclip then StartPlayerNoclip() end
end))

return MM2
