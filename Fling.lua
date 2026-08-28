--============================================================
-- MM2 V8.6 STABLE - Fling.lua
-- Based on user's split-build Fling.lua with timing/P/cleanup fixes.
--============================================================

local MM2 = getgenv and getgenv().MM2_V85_SPLIT or _G.MM2_V85_SPLIT
assert(MM2 and MM2.UI and MM2.UI.FlingPage, "Load Shared.lua + UI.lua first")

local Players = MM2.Services.Players
local RunService = MM2.Services.RunService
local LocalPlayer = MM2.LocalPlayer
local UI = MM2.UI
local Track = MM2.Track

UI.AddSection(UI.FlingPage, "Fling", "Choose a target or use quick-role actions")

local FLING_DURATION = 1.30
local FLING_HUGE = 900000000
local FLING_FORCE_NAME = "MarbegFlingVelocity"

local FLING_POSITION_PATTERN = {
	Vector3.new(0, 1.5, -12.80),
	Vector3.new(0, -1.5, -12.80),
	Vector3.new(2.25, 1.5, -14.80),
	Vector3.new(-2.25, -1.5, -10.80),
	Vector3.new(0, 1.5, -1.00),
	Vector3.new(0, -1.5, -1.00),
}

local FlingRunning = false
local CurrentFlingForce = nil

local function GetTargetFlingCharacter(player)
	if not player then return nil end
	local character = player.Character
	if not character then return nil end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then return nil end
	return character,humanoid,hrp
end

local function StopFling()
	FlingRunning = false
	local _,humanoid,hrp = MM2.GetLocalCharacter()

	if CurrentFlingForce then
		pcall(function() CurrentFlingForce:Destroy() end)
		CurrentFlingForce = nil
	end

	if hrp then
		pcall(function()
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		end)
	end

	if humanoid then
		pcall(function()
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end)
	end
end
MM2.Functions.StopFling = StopFling

local function ExecuteYeet(targetPlayer)
	if FlingRunning then
		MM2.Notify("Fling already running.",2)
		return
	end

	if not targetPlayer or targetPlayer == LocalPlayer then return end

	local character,humanoid,hrp = MM2.GetLocalCharacter()
	if not character then return end

	local targetCharacter,targetHumanoid,targetHRP = GetTargetFlingCharacter(targetPlayer)
	if not targetCharacter then
		MM2.Notify("Target character unavailable.",2)
		return
	end

	FlingRunning = true
	local originalCFrame = hrp.CFrame

	local oldForce = hrp:FindFirstChild(FLING_FORCE_NAME)
	if oldForce then oldForce:Destroy() end

	local force = Instance.new("BodyVelocity")
	force.Name = FLING_FORCE_NAME
	force.Velocity = Vector3.new(FLING_HUGE,FLING_HUGE,FLING_HUGE)
	force.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
	force.P = 1250
	force.Parent = hrp
	CurrentFlingForce = force

	hrp.AssemblyAngularVelocity = Vector3.new(FLING_HUGE,FLING_HUGE,FLING_HUGE)

	local startTime = os.clock()
	local frame = 0
	local patternIndex = 1
	local velocityPhase = 1

	while FlingRunning and os.clock()-startTime < FLING_DURATION do
		targetCharacter,targetHumanoid,targetHRP = GetTargetFlingCharacter(targetPlayer)
		if not targetHRP then break end

		frame += 1
		local offset = FLING_POSITION_PATTERN[patternIndex]
		hrp.CFrame = targetHRP.CFrame * CFrame.new(offset.X,offset.Y,offset.Z)

		local phase = math.floor((frame-1)/6)%3
		if phase == 0 then
			hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(
				0,
				math.rad(targetHRP.Orientation.Y),
				0
			)
		elseif phase == 1 then
			hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(
				math.rad(-60),
				math.rad(180),
				math.rad(180)
			)
		else
			hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(
				math.rad(60),
				math.rad(180),
				math.rad(180)
			)
		end

		hrp.AssemblyAngularVelocity = Vector3.new(FLING_HUGE,FLING_HUGE,FLING_HUGE)

		if velocityPhase == 1 then
			hrp.AssemblyLinearVelocity = Vector3.new(
				387791264,
				919603648,
				-227394880
			)
		elseif velocityPhase == 2 then
			hrp.AssemblyLinearVelocity = Vector3.new(
				233146464,
				615062400,
				231791104
			)
		else
			hrp.AssemblyLinearVelocity = Vector3.new(
				-350938112,
				1164999296,
				265938784
			)
		end

		patternIndex += 1
		if patternIndex > #FLING_POSITION_PATTERN then
			patternIndex = 1
			velocityPhase += 1
			if velocityPhase > 3 then velocityPhase = 1 end
		end

		RunService.Heartbeat:Wait()
	end

	if CurrentFlingForce then
		pcall(function() CurrentFlingForce:Destroy() end)
		CurrentFlingForce = nil
	end

	-- Stable cleanup: return immediately without yielding a physics frame.
	pcall(function()
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		hrp.CFrame = originalCFrame
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end)

	pcall(function()
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end)

	FlingRunning = false
end
MM2.Functions.ExecuteYeet = ExecuteYeet

local function FlingRole(role,label)
	for _,player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and MM2.State.ServerRolesCache[player.Name] == role then
			task.spawn(function() ExecuteYeet(player) end)
			return
		end
	end
	MM2.Notify("No "..label.." target found.",2)
end

-- One-tap role actions in the Fling page.
-- These use the existing FlingRole -> ExecuteYeet engine.
UI.CreateActionFeature(
	UI.FlingPage,
	"Fling Sheriff",
	"Flings the current sheriff",
	function() FlingRole("Sheriff","sheriff") end
)

UI.CreateActionFeature(
	UI.FlingPage,
	"Fling Murderer",
	"Flings the current murderer",
	function() FlingRole("Murderer","murderer") end
)

UI.CreateActionFeature(
	UI.FlingPage,
	"Fling Hero",
	"Flings the current hero",
	function() FlingRole("Hero","hero") end
)

local TargetCard = Instance.new("Frame")
TargetCard.Size = UDim2.new(1,0,0,112)
TargetCard.BackgroundColor3 = UI.COLORS.Card
TargetCard.BorderSizePixel = 0
TargetCard.Parent = UI.FlingPage

local TargetLabel = Instance.new("TextLabel")
TargetLabel.Size = UDim2.new(1,-28,0,22)
TargetLabel.Position = UDim2.fromOffset(14,10)
TargetLabel.BackgroundTransparency = 1
TargetLabel.TextXAlignment = Enum.TextXAlignment.Left
TargetLabel.Text = "Selected Target"
TargetLabel.TextColor3 = UI.COLORS.Text
TargetLabel.TextSize = 12
TargetLabel.Font = Enum.Font.GothamBold
TargetLabel.Parent = TargetCard

local TargetStatus = Instance.new("TextLabel")
TargetStatus.Size = UDim2.new(1,-28,0,18)
TargetStatus.Position = UDim2.fromOffset(14,33)
TargetStatus.BackgroundTransparency = 1
TargetStatus.TextXAlignment = Enum.TextXAlignment.Left
TargetStatus.Text = "None"
TargetStatus.TextColor3 = UI.COLORS.Muted
TargetStatus.TextSize = 10
TargetStatus.Font = Enum.Font.Gotham
TargetStatus.Parent = TargetCard
MM2.UI.TargetStatus = TargetStatus

local DropdownButton = Instance.new("TextButton")
DropdownButton.Size = UDim2.new(1,-28,0,36)
DropdownButton.Position = UDim2.fromOffset(14,62)
DropdownButton.BackgroundColor3 = UI.COLORS.Background
DropdownButton.BorderSizePixel = 0
DropdownButton.Text = "SELECT PLAYER"
DropdownButton.TextColor3 = UI.COLORS.Text
DropdownButton.TextSize = 10
DropdownButton.Font = Enum.Font.GothamBold
DropdownButton.Parent = TargetCard

local DropdownList = Instance.new("ScrollingFrame")
DropdownList.Size = UDim2.new(1,0,0,142)
DropdownList.BackgroundColor3 = UI.COLORS.Card
DropdownList.BorderSizePixel = 0
DropdownList.ScrollBarThickness = 3
DropdownList.Visible = false
DropdownList.CanvasSize = UDim2.fromOffset(0,0)
DropdownList.ZIndex = 30
DropdownList.Parent = UI.FlingPage

local DropdownLayout = Instance.new("UIListLayout")
DropdownLayout.Padding = UDim.new(0,4)
DropdownLayout.Parent = DropdownList

local function RefreshPlayerDropdown()
	for _,child in ipairs(DropdownList:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	local count = 0
	for _,player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			count += 1

			local item = Instance.new("TextButton")
			item.Size = UDim2.new(1,0,0,30)
			item.BackgroundColor3 = UI.COLORS.Background
			item.BorderSizePixel = 0
			item.Text = player.Name
			item.TextColor3 = UI.COLORS.Text
			item.TextSize = 10
			item.Font = Enum.Font.GothamMedium
			item.ZIndex = 31
			item.Parent = DropdownList

			Track(item.MouseButton1Click:Connect(function()
				MM2.State.SelectedFlingTarget = player
				TargetStatus.Text = player.Name
				DropdownList.Visible = false
			end))
		end
	end

	DropdownList.CanvasSize = UDim2.fromOffset(0,count*34+12)
end

Track(DropdownButton.MouseButton1Click:Connect(function()
	if not DropdownList.Visible then
		RefreshPlayerDropdown()
	end
	DropdownList.Visible = not DropdownList.Visible
end))

UI.CreateActionFeature(
	UI.FlingPage,
	"Fling Selected Player",
	"Throws the selected player away",
	function()
		if not MM2.State.SelectedFlingTarget then
			MM2.Notify("Select a target first.",2)
			return
		end
		ExecuteYeet(MM2.State.SelectedFlingTarget)
	end
)

UI.CreateActionFeature(
	UI.FlingPage,
	"Stop Fling",
	"Stops the current fling",
	StopFling
)

return MM2
