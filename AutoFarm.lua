--============================================================
-- MM2 V8.8.4 - AutoFarm.lua
-- Coin Farm V13.4 vertical-aware target selection.
--
-- V13.4:
-- - Keeps V13.3 enlarged HRP pickup hitbox.
-- - Keeps normal direct underground farming at -5.05.
-- - Keeps V13.3 contact re-arm fallback.
-- - Keeps all bag-full actions / stats / remotes untouched.
--
-- NEW:
-- - Coin selection now slightly penalizes large vertical travel.
-- - Scores the REAL farm target (coin.Y - 5.05), not coin center.
-- - High coins are NOT ignored.
-- - Flat nearby routes are simply preferred when reasonable.
--============================================================

local MM2 = getgenv and getgenv().MM2_V85_SPLIT or _G.MM2_V85_SPLIT
assert(MM2 and MM2.UI and MM2.UI.AutoFarmPage, "Load Shared.lua + UI.lua first")

local RunService = MM2.Services.RunService
local LocalPlayer = MM2.LocalPlayer
local Flags = MM2.Flags
local UI = MM2.UI
local VirtualUser = game:GetService("VirtualUser")

Flags.AntiDisconnect = Flags.AntiDisconnect == true
Flags.FarmSpeed = math.clamp(tonumber(Flags.FarmSpeed) or 25,5,25)
Flags.KillAllAfterBagFull = Flags.KillAllAfterBagFull == true
Flags.ShootMurdererAfterBagFull = Flags.ShootMurdererAfterBagFull == true
Flags.FlingMurdererAfterBagFull = Flags.FlingMurdererAfterBagFull == true
Flags.ResetCharacterAfterBagFull = Flags.ResetCharacterAfterBagFull == true
Flags.StayUndergroundAfterBagFull = Flags.StayUndergroundAfterBagFull == true

UI.AddSection(
	UI.AutoFarmPage,
	"Auto Farm",
	"Coin Farm V13.4 vertical-aware selection"
)

UI.CreateToggle(
	UI.AutoFarmPage,
	"Auto Farm Coins",
	"Automatically farms coins for you",
	"AutoFarm"
)

UI.CreateSlider(
	UI.AutoFarmPage,
	"Farm Speed",
	"Adjusts auto-farm movement speed",
	function()
		return Flags.FarmSpeed
	end,
	function(value)
		Flags.FarmSpeed = math.clamp(tonumber(value) or 25,5,25)
	end,
	5,
	25,
	1
)

--============================================================
-- Anti Disconnect
--============================================================

local AntiDisconnectConnection = nil

local function SetAntiDisconnect(on)
	if AntiDisconnectConnection then
		AntiDisconnectConnection:Disconnect()
		AntiDisconnectConnection = nil
	end

	if on then
		AntiDisconnectConnection = LocalPlayer.Idled:Connect(function()
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new(0,0))
			end)
		end)

		MM2.Track(AntiDisconnectConnection)
	end
end

UI.CreateToggle(
	UI.AutoFarmPage,
	"Anti Disconnect",
	"Prevents the normal inactivity timeout during long farming sessions",
	"AntiDisconnect",
	SetAntiDisconnect
)

if Flags.AntiDisconnect then
	SetAntiDisconnect(true)
end

--============================================================
-- Movement Constants
--============================================================

local FARM_MAX_VELOCITY = 25
local FARM_RESPONSIVENESS = 18
local FARM_MAX_FORCE = 500000

local FARM_UPRIGHT_RESPONSIVENESS = 12
local FARM_UPRIGHT_MAX_TORQUE = 500000
local FARM_UPRIGHT_MAX_ANGULAR = 10

--============================================================
-- Normal Coin Movement
--============================================================

local FARM_COIN_Y_OFFSET = -5.05
local FARM_HRP_SIZE = Vector3.new(2,12,1)

local FARM_MAX_VALID_COLLECTION_DISTANCE = 6.5
local FARM_MAX_TARGET_DISTANCE = 500
local FARM_LOOP_DELAY = 0.02
local FARM_MAX_START_DISTANCE = 500

--============================================================
-- V13.4 Coin Selection
--
-- 1.00 = no extra vertical penalty
-- 1.35 = mild preference for flatter routes
--
-- This is intentionally mild.
-- Elevated coins can still be selected normally.
--============================================================

local FARM_VERTICAL_SELECTION_WEIGHT = 1.35

--============================================================
-- V13.3 Contact Re-Arm
--============================================================

local FARM_REARM_CLOSE_HORIZONTAL = 0.40

local FARM_REARM_MIN_SETTLED_V = 4.65
local FARM_REARM_MAX_SETTLED_V = 5.25

local FARM_REARM_STUCK_DELAY = 0.30

local FARM_REARM_EXIT_Y_OFFSET = -7.35
local FARM_REARM_EXIT_REACHED_V = 7.15
local FARM_REARM_EXIT_TIMEOUT = 0.45

local FARM_REARM_SEPARATION_HOLD = 0.06

local FARM_REARM_REENTER_TIMEOUT = 0.50
local FARM_REARM_REENTER_V = 5.25

local FARM_REARM_VERIFY_DELAY = 0.35

local FARM_REARM_MAX_ATTEMPTS = 2

local FARM_REARM_SKIP_TIME = 1.50

--============================================================
-- After Bag Full Constants
--============================================================

local FARM_BAG_LIFT_HEIGHT = 6
local FARM_BAG_LIFT_REACHED_DISTANCE = 0.75
local FARM_BAG_LIFT_TIMEOUT = 2.5

local FARM_UNDERGROUND_OFFSET = 6
local FARM_UNDERGROUND_TIMEOUT = 2.5

--============================================================
-- State
--============================================================

local AutoFarmRunning = false

local FarmPaused = false
local FarmPauseReason = nil

local FarmBagCount = 0
local FarmBagMax = 40
local FarmBagFull = false

local FarmBagLiftInProgress = false
local FarmBagLiftDone = false

local FarmAfterBagFullHandled = false
local FarmAfterBagActionBusy = false

local FarmStatsCoins = 0
local FarmStatsStartedAt = nil
local FarmLastReportedBagCount = 0

local FarmCharacter = nil
local FarmHumanoid = nil
local FarmHRP = nil

local FarmAttachment = nil
local FarmPositionAlign = nil
local FarmUprightAlign = nil

local FarmCurrentCoin = nil
local FarmCurrentTouch = nil

local FarmNoclipConnection = nil
local FarmOriginalCollision = {}

local FarmSafeReturnCFrame = nil

local FarmOriginalHRPSize = nil
local FarmSizedHRP = nil

--============================================================
-- V13.3 Re-Arm State
--============================================================

local FarmRearmState = "idle"

local FarmRearmCloseStartedAt = nil
local FarmRearmStateStartedAt = 0
local FarmRearmAttempts = 0

local FarmCoinSkipUntil =
	setmetatable({}, {__mode = "k"})

--============================================================
-- Character
--============================================================

local function FarmUpdateCharacter()
	FarmCharacter = LocalPlayer.Character

	if not FarmCharacter then
		FarmHumanoid = nil
		FarmHRP = nil
		return false
	end

	FarmHumanoid = FarmCharacter:FindFirstChildOfClass("Humanoid")
	FarmHRP = FarmCharacter:FindFirstChild("HumanoidRootPart")

	return FarmHumanoid ~= nil and FarmHRP ~= nil
end

--============================================================
-- HRP Pickup Hitbox
--============================================================

local function FarmRestoreHRPSize()
	if FarmSizedHRP
		and FarmSizedHRP.Parent
		and FarmOriginalHRPSize then

		pcall(function()
			FarmSizedHRP.Size = FarmOriginalHRPSize
		end)
	end

	FarmOriginalHRPSize = nil
	FarmSizedHRP = nil
end

local function FarmApplyHRPSize()
	if not FarmUpdateCharacter() then
		return false
	end

	if FarmSizedHRP
		and FarmSizedHRP ~= FarmHRP then

		FarmRestoreHRPSize()
	end

	if FarmSizedHRP ~= FarmHRP then
		FarmSizedHRP = FarmHRP
		FarmOriginalHRPSize = FarmHRP.Size
	end

	pcall(function()
		FarmHRP.Size = FARM_HRP_SIZE
	end)

	return true
end

--============================================================
-- Coin Helpers
--============================================================

local function FarmIsCoinServer(obj)
	return obj
		and obj.Name == "Coin_Server"
		and (obj:IsA("BasePart") or obj:IsA("Model"))
end

local function FarmGetPosition(obj)
	if not obj then
		return nil
	end

	if obj:IsA("BasePart") then
		return obj.Position
	end

	if obj:IsA("Model") then
		local ok,pivot = pcall(function()
			return obj:GetPivot()
		end)

		if ok then
			return pivot.Position
		end
	end

	return nil
end

local function FarmGetTouchObject(coin)
	if not coin then
		return nil
	end

	local direct = coin:FindFirstChild("TouchInterest")

	if direct then
		return direct
	end

	for _,obj in ipairs(coin:GetDescendants()) do
		if obj.Name == "TouchInterest"
			or obj:IsA("TouchTransmitter") then

			return obj
		end
	end

	return nil
end

local function FarmValidCoin(coin)
	return coin
		and FarmIsCoinServer(coin)
		and coin:IsDescendantOf(workspace)
		and FarmGetPosition(coin) ~= nil
		and FarmGetTouchObject(coin) ~= nil
end

local function FarmCoinIsTemporarilySkipped(coin)
	local untilTime =
		FarmCoinSkipUntil[coin]

	if not untilTime then
		return false
	end

	if os.clock() >= untilTime then
		FarmCoinSkipUntil[coin] = nil
		return false
	end

	return true
end

--============================================================
-- Target Position Helpers
--============================================================

local function FarmGetCoinTargetWithOffset(coinPos,yOffset)
	return Vector3.new(
		coinPos.X,
		coinPos.Y + yOffset,
		coinPos.Z
	)
end

local function FarmGetCoinTarget(coinPos)
	return FarmGetCoinTargetWithOffset(
		coinPos,
		FARM_COIN_Y_OFFSET
	)
end

--============================================================
-- V13.4 Vertical-Aware Coin Selection
--============================================================

local function FarmFindNearestCoin()
	if not FarmHRP then
		return nil,math.huge
	end

	local best = nil
	local bestScore = math.huge
	local bestTravelDistance = math.huge

	local hrpPosition = FarmHRP.Position

	for _,obj in ipairs(workspace:GetDescendants()) do
		if FarmValidCoin(obj)
			and not FarmCoinIsTemporarilySkipped(obj) then

			local pos = FarmGetPosition(obj)

			if pos then
				local target =
					FarmGetCoinTarget(pos)

				local dx =
					target.X
					-
					hrpPosition.X

				local dz =
					target.Z
					-
					hrpPosition.Z

				local horizontalDistance =
					math.sqrt(
						dx*dx
						+
						dz*dz
					)

				local verticalDistance =
					math.abs(
						target.Y
						-
						hrpPosition.Y
					)

				local score =
					horizontalDistance
					+
					(
						verticalDistance
						*
						FARM_VERTICAL_SELECTION_WEIGHT
					)

				local travelDistance =
					(hrpPosition-target).Magnitude

				if score < bestScore then
					best = obj
					bestScore = score
					bestTravelDistance = travelDistance
				end
			end
		end
	end

	return best,bestTravelDistance
end

--============================================================
-- Movement
--============================================================

local function FarmDestroyMovement()
	if FarmPositionAlign then
		pcall(function()
			FarmPositionAlign:Destroy()
		end)
	end

	if FarmUprightAlign then
		pcall(function()
			FarmUprightAlign:Destroy()
		end)
	end

	if FarmAttachment then
		pcall(function()
			FarmAttachment:Destroy()
		end)
	end

	FarmPositionAlign = nil
	FarmUprightAlign = nil
	FarmAttachment = nil
end

local function FarmEnsureMovement()
	if not FarmUpdateCharacter() then
		return false
	end

	FarmApplyHRPSize()

	if FarmAttachment
		and FarmAttachment.Parent == FarmHRP
		and FarmPositionAlign
		and FarmPositionAlign.Parent == FarmHRP
		and FarmUprightAlign
		and FarmUprightAlign.Parent == FarmHRP then

		return true
	end

	FarmDestroyMovement()

	FarmAttachment = Instance.new("Attachment")
	FarmAttachment.Name = "FarmAttachmentV13_4"
	FarmAttachment.Parent = FarmHRP

	FarmPositionAlign = Instance.new("AlignPosition")
	FarmPositionAlign.Name = "FarmAlign"
	FarmPositionAlign.Mode = Enum.PositionAlignmentMode.OneAttachment
	FarmPositionAlign.Attachment0 = FarmAttachment

	FarmPositionAlign.MaxVelocity =
		math.clamp(
			tonumber(Flags.FarmSpeed) or FARM_MAX_VELOCITY,
			5,
			FARM_MAX_VELOCITY
		)

	FarmPositionAlign.Responsiveness = FARM_RESPONSIVENESS
	FarmPositionAlign.MaxForce = FARM_MAX_FORCE
	FarmPositionAlign.ApplyAtCenterOfMass = true
	FarmPositionAlign.RigidityEnabled = false
	FarmPositionAlign.Position = FarmHRP.Position
	FarmPositionAlign.Parent = FarmHRP

	FarmUprightAlign = Instance.new("AlignOrientation")
	FarmUprightAlign.Name = "FarmUprightAlign"
	FarmUprightAlign.Mode = Enum.OrientationAlignmentMode.OneAttachment
	FarmUprightAlign.Attachment0 = FarmAttachment
	FarmUprightAlign.Responsiveness = FARM_UPRIGHT_RESPONSIVENESS
	FarmUprightAlign.MaxTorque = FARM_UPRIGHT_MAX_TORQUE
	FarmUprightAlign.MaxAngularVelocity = FARM_UPRIGHT_MAX_ANGULAR
	FarmUprightAlign.RigidityEnabled = false
	FarmUprightAlign.Parent = FarmHRP

	return true
end

--============================================================
-- Noclip
--============================================================

local function FarmApplyNoclip()
	if not FarmCharacter or not FarmHumanoid then
		return
	end

	FarmApplyHRPSize()

	for _,obj in ipairs(FarmCharacter:GetDescendants()) do
		if obj:IsA("BasePart") then
			if FarmOriginalCollision[obj] == nil then
				FarmOriginalCollision[obj] = obj.CanCollide
			end

			obj.CanCollide = false
		end
	end

	FarmHumanoid.Sit = false

	local state = FarmHumanoid:GetState()

	if state == Enum.HumanoidStateType.Climbing
		or state == Enum.HumanoidStateType.Seated then

		FarmHumanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	end
end

local function FarmStartNoclip()
	if FarmNoclipConnection then
		FarmNoclipConnection:Disconnect()
	end

	FarmNoclipConnection = nil

	table.clear(FarmOriginalCollision)

	FarmApplyNoclip()

	FarmNoclipConnection = RunService.Stepped:Connect(function()
		if not AutoFarmRunning
			or (
				FarmPaused
				and not FarmBagLiftInProgress
				and not Flags.StayUndergroundAfterBagFull
			) then

			return
		end

		if FarmUpdateCharacter() then
			FarmApplyNoclip()
		end
	end)
end

local function FarmStopNoclip()
	if FarmNoclipConnection then
		FarmNoclipConnection:Disconnect()
		FarmNoclipConnection = nil
	end

	for part,oldState in pairs(FarmOriginalCollision) do
		if part and part.Parent then
			pcall(function()
				part.CanCollide = oldState
			end)
		end
	end

	table.clear(FarmOriginalCollision)
end

--============================================================
-- Target / Re-Arm Reset
--============================================================

local function FarmResetRearm()
	FarmRearmState = "idle"
	FarmRearmCloseStartedAt = nil
	FarmRearmStateStartedAt = 0
	FarmRearmAttempts = 0
end

local function FarmReleaseTarget()
	FarmCurrentCoin = nil
	FarmCurrentTouch = nil

	FarmResetRearm()
end

local function FarmSelectTarget(coin)
	if not FarmValidCoin(coin)
		or not FarmEnsureMovement() then

		return false
	end

	local coinPos = FarmGetPosition(coin)

	if not coinPos then
		return false
	end

	FarmCurrentCoin = coin
	FarmCurrentTouch = FarmGetTouchObject(coin)

	FarmResetRearm()

	FarmPositionAlign.Position =
		FarmGetCoinTarget(coinPos)

	return true
end

local function FarmCheckCollection(coin,coinPos)
	local oldTouch = FarmCurrentTouch
	local newTouch = FarmGetTouchObject(coin)

	FarmCurrentTouch = newTouch

	if oldTouch and not newTouch then
		local distance =
			FarmHRP
			and (FarmHRP.Position-coinPos).Magnitude
			or math.huge

		if distance <= FARM_MAX_VALID_COLLECTION_DISTANCE then
			return true
		else
			return "invalid"
		end
	end

	return false
end

--============================================================
-- V13.3 Re-Arm Movement
--============================================================

local function FarmHorizontalDistanceToCoin(coinPos)
	if not FarmHRP then
		return math.huge
	end

	local dx =
		FarmHRP.Position.X
		-
		coinPos.X

	local dz =
		FarmHRP.Position.Z
		-
		coinPos.Z

	return math.sqrt(dx*dx + dz*dz)
end

local function FarmVerticalBelowCoin(coinPos)
	if not FarmHRP then
		return math.huge
	end

	return coinPos.Y-FarmHRP.Position.Y
end

local function FarmBeginRearm()
	FarmRearmAttempts += 1

	FarmRearmState = "exit"
	FarmRearmStateStartedAt = os.clock()
	FarmRearmCloseStartedAt = nil
end

local function FarmUpdateRearm(coinPos)
	if not FarmPositionAlign
		or not FarmHRP then

		return
	end

	local now = os.clock()

	local horizontalDistance =
		FarmHorizontalDistanceToCoin(
			coinPos
		)

	local verticalBelow =
		FarmVerticalBelowCoin(
			coinPos
		)

	if FarmRearmState == "idle" then
		FarmPositionAlign.Position =
			FarmGetCoinTarget(
				coinPos
			)

		local settled =
			horizontalDistance
				<= FARM_REARM_CLOSE_HORIZONTAL
			and verticalBelow
				>= FARM_REARM_MIN_SETTLED_V
			and verticalBelow
				<= FARM_REARM_MAX_SETTLED_V

		if settled then
			if not FarmRearmCloseStartedAt then
				FarmRearmCloseStartedAt = now
			end

			if now-FarmRearmCloseStartedAt
				>= FARM_REARM_STUCK_DELAY then

				FarmBeginRearm()
			end
		else
			FarmRearmCloseStartedAt = nil
		end

		return
	end

	if FarmRearmState == "exit" then
		FarmPositionAlign.Position =
			FarmGetCoinTargetWithOffset(
				coinPos,
				FARM_REARM_EXIT_Y_OFFSET
			)

		local outsideContact =
			verticalBelow
				>= FARM_REARM_EXIT_REACHED_V

		local timedOut =
			now-FarmRearmStateStartedAt
				>= FARM_REARM_EXIT_TIMEOUT

		if outsideContact or timedOut then
			FarmRearmState = "hold"
			FarmRearmStateStartedAt = now
		end

		return
	end

	if FarmRearmState == "hold" then
		FarmPositionAlign.Position =
			FarmGetCoinTargetWithOffset(
				coinPos,
				FARM_REARM_EXIT_Y_OFFSET
			)

		if now-FarmRearmStateStartedAt
			>= FARM_REARM_SEPARATION_HOLD then

			FarmRearmState = "reenter"
			FarmRearmStateStartedAt = now
		end

		return
	end

	if FarmRearmState == "reenter" then
		FarmPositionAlign.Position =
			FarmGetCoinTarget(
				coinPos
			)

		local backInPickupZone =
			verticalBelow
				<= FARM_REARM_REENTER_V

		local timedOut =
			now-FarmRearmStateStartedAt
				>= FARM_REARM_REENTER_TIMEOUT

		if backInPickupZone or timedOut then
			FarmRearmState = "verify"
			FarmRearmStateStartedAt = now
		end

		return
	end

	if FarmRearmState == "verify" then
		FarmPositionAlign.Position =
			FarmGetCoinTarget(
				coinPos
			)

		if now-FarmRearmStateStartedAt
			< FARM_REARM_VERIFY_DELAY then

			return
		end

		if FarmRearmAttempts
			< FARM_REARM_MAX_ATTEMPTS then

			FarmRearmState = "idle"

			FarmRearmCloseStartedAt =
				now
				-
				(
					FARM_REARM_STUCK_DELAY
					-
					0.10
				)

			return
		end

		local failedCoin =
			FarmCurrentCoin

		if failedCoin then
			FarmCoinSkipUntil[failedCoin] =
				now + FARM_REARM_SKIP_TIME
		end

		FarmReleaseTarget()
		return
	end
end

--============================================================
-- Safe Position
--============================================================

local function FarmReturnToSafePosition()
	if not FarmSafeReturnCFrame
		or not FarmUpdateCharacter() then

		return
	end

	pcall(function()
		FarmHRP.AssemblyLinearVelocity = Vector3.zero
		FarmHRP.AssemblyAngularVelocity = Vector3.zero

		FarmHRP.CFrame = FarmSafeReturnCFrame

		FarmHRP.AssemblyLinearVelocity = Vector3.zero
		FarmHRP.AssemblyAngularVelocity = Vector3.zero
	end)
end

--============================================================
-- Pause / Wake
--============================================================

local function FarmPause(reason)
	reason = reason or "PAUSED"

	if reason == "BAG FULL" then
		return
	end

	if FarmPaused
		and FarmPauseReason == reason then

		return
	end

	FarmPaused = true
	FarmPauseReason = reason

	FarmReleaseTarget()
	FarmStopNoclip()
	FarmDestroyMovement()
	FarmRestoreHRPSize()
end

local function FarmWake()
	FarmPaused = false
	FarmPauseReason = nil

	if not FarmUpdateCharacter() then
		return false
	end

	if not FarmSafeReturnCFrame then
		FarmSafeReturnCFrame = FarmHRP.CFrame
	end

	FarmApplyHRPSize()

	if not FarmEnsureMovement() then
		return false
	end

	if not FarmNoclipConnection then
		FarmStartNoclip()
	end

	return true
end

--============================================================
-- After Bag Full Helpers
--============================================================

local function FarmFindMurderer()
	for _,player in ipairs(MM2.Services.Players:GetPlayers()) do
		if player ~= LocalPlayer
			and MM2.State.ServerRolesCache[player.Name] == "Murderer" then

			local character = player.Character

			local humanoid =
				character
				and character:FindFirstChildOfClass("Humanoid")

			if humanoid
				and humanoid.Health > 0 then

				return player
			end
		end
	end

	return nil
end

local function FarmHasKnife()
	if MM2.Functions.HasKnifeAnywhere then
		local ok,result =
			pcall(
				MM2.Functions.HasKnifeAnywhere
			)

		if ok then
			return result == true
		end
	end

	local character = LocalPlayer.Character
	local backpack =
		LocalPlayer:FindFirstChildOfClass("Backpack")

	for _,container in ipairs({
		character,
		backpack
	}) do

		if container then
			for _,obj in ipairs(container:GetChildren()) do
				if obj:IsA("Tool")
					and (
						obj.Name == "Knife"
						or obj:GetAttribute("IsKnife") == true
					) then

					return true
				end
			end
		end
	end

	return false
end

local function FarmFindGroundY()
	if not FarmUpdateCharacter() then
		return nil
	end

	local params = RaycastParams.new()

	params.FilterType =
		Enum.RaycastFilterType.Exclude

	params.FilterDescendantsInstances =
		{FarmCharacter}

	params.IgnoreWater = true

	local xz =
		Vector3.new(
			FarmHRP.Position.X,
			0,
			FarmHRP.Position.Z
		)

	local upResult =
		workspace:Raycast(
			FarmHRP.Position,
			Vector3.new(0,120,0),
			params
		)

	if upResult then
		return upResult.Position.Y
	end

	local downOrigin =
		Vector3.new(
			xz.X,
			FarmHRP.Position.Y + 20,
			xz.Z
		)

	local downResult =
		workspace:Raycast(
			downOrigin,
			Vector3.new(0,-180,0),
			params
		)

	if downResult then
		return downResult.Position.Y
	end

	return nil
end

local function FarmMoveUnderground()
	if not FarmUpdateCharacter()
		or not FarmEnsureMovement() then

		return false
	end

	if not FarmNoclipConnection then
		FarmStartNoclip()
	end

	local floorY = FarmFindGroundY()

	if not floorY then
		return false
	end

	local target =
		Vector3.new(
			FarmHRP.Position.X,
			floorY-FARM_UNDERGROUND_OFFSET,
			FarmHRP.Position.Z
		)

	FarmPositionAlign.Position = target

	local started = os.clock()

	while AutoFarmRunning
		and MM2.Running
		and FarmBagFull
		and Flags.StayUndergroundAfterBagFull do

		if not FarmUpdateCharacter()
			or not FarmPositionAlign then

			break
		end

		FarmPositionAlign.Position = target

		if (FarmHRP.Position-target).Magnitude
			<= FARM_BAG_LIFT_REACHED_DISTANCE then

			return true
		end

		if os.clock()-started
			>= FARM_UNDERGROUND_TIMEOUT then

			break
		end

		task.wait(0.03)
	end

	return false
end

--============================================================
-- After Bag Full Actions
--============================================================

local function FarmRunAfterBagFullActions()
	if FarmAfterBagFullHandled then
		return
	end

	FarmAfterBagFullHandled = true

	if FarmAfterBagActionBusy then
		return
	end

	FarmAfterBagActionBusy = true

	task.spawn(function()
		local killAllRan = false

		if Flags.KillAllAfterBagFull
			and FarmHasKnife()
			and MM2.Functions.KillAllOnce then

			local ok,success =
				pcall(
					MM2.Functions.KillAllOnce
				)

			killAllRan =
				ok
				and success == true
		end

		if Flags.ShootMurdererAfterBagFull
			and MM2.Functions.ShootMurderer then

			while MM2.Running
				and Flags.AutoFarm
				and FarmBagFull
				and Flags.ShootMurdererAfterBagFull do

				local murderer =
					FarmFindMurderer()

				if not murderer then
					break
				end

				local ok,success,message =
					pcall(
						MM2.Functions.ShootMurderer
					)

				if not ok then
					break
				end

				if success == true
					or message == "No Murderer" then

					break
				end

				local retryDelay =
					(
						message == "Cooldown"
							or message == "Busy"
							or message == "No Gun"
					)
					and 0.20
					or 0.12

				task.wait(retryDelay)
			end
		end

		if Flags.FlingMurdererAfterBagFull
			and MM2.Functions.ExecuteYeet then

			local murderer =
				FarmFindMurderer()

			if murderer then
				pcall(
					MM2.Functions.ExecuteYeet,
					murderer
				)
			end
		end

		if Flags.ResetCharacterAfterBagFull
			and not Flags.StayUndergroundAfterBagFull
			and not killAllRan then

			task.wait(0.15)

			local character =
				LocalPlayer.Character

			local humanoid =
				character
				and character:FindFirstChildOfClass(
					"Humanoid"
				)

			if humanoid
				and humanoid.Health > 0 then

				humanoid.Health = 0
			end
		end

		FarmAfterBagActionBusy = false
	end)
end

--============================================================
-- Bag Full Movement
--============================================================

local function FarmBeginBagFullLift()
	if FarmBagLiftInProgress
		or FarmBagLiftDone then

		return
	end

	FarmBagLiftInProgress = true

	FarmPaused = true
	FarmPauseReason = "BAG FULL"

	FarmReleaseTarget()

	FarmRunAfterBagFullActions()

	if Flags.StayUndergroundAfterBagFull then
		task.spawn(function()
			FarmMoveUnderground()

			FarmBagLiftInProgress = false
			FarmBagLiftDone = true

			while AutoFarmRunning
				and MM2.Running
				and FarmBagFull
				and Flags.StayUndergroundAfterBagFull do

				if FarmUpdateCharacter()
					and FarmPositionAlign then

					local floorY =
						FarmFindGroundY()

					if floorY then
						FarmPositionAlign.Position =
							Vector3.new(
								FarmHRP.Position.X,
								floorY-FARM_UNDERGROUND_OFFSET,
								FarmHRP.Position.Z
							)
					end
				end

				task.wait(0.20)
			end

			FarmStopNoclip()
			FarmDestroyMovement()
			FarmRestoreHRPSize()
		end)

		return
	end

	task.spawn(function()
		if not FarmUpdateCharacter()
			or not FarmEnsureMovement() then

			FarmStopNoclip()
			FarmDestroyMovement()
			FarmRestoreHRPSize()

			FarmBagLiftInProgress = false
			FarmBagLiftDone = true

			return
		end

		if not FarmNoclipConnection then
			FarmStartNoclip()
		end

		local liftTarget =
			FarmHRP.Position
			+ Vector3.new(
				0,
				FARM_BAG_LIFT_HEIGHT,
				0
			)

		FarmPositionAlign.Position =
			liftTarget

		local started = os.clock()

		while AutoFarmRunning
			and MM2.Running
			and FarmBagFull do

			if not FarmUpdateCharacter()
				or not FarmPositionAlign then

				break
			end

			if (FarmHRP.Position-liftTarget).Magnitude
				<= FARM_BAG_LIFT_REACHED_DISTANCE then

				break
			end

			if os.clock()-started
				>= FARM_BAG_LIFT_TIMEOUT then

				break
			end

			task.wait(0.03)
		end

		FarmStopNoclip()
		FarmDestroyMovement()
		FarmRestoreHRPSize()

		FarmBagLiftInProgress = false
		FarmBagLiftDone = true
	end)
end

--============================================================
-- Main Farm Loop
--============================================================

local function FarmLoop()
	while AutoFarmRunning and MM2.Running do
		if not Flags.AutoFarm then
			break
		end

		if FarmBagLiftInProgress then
			task.wait(0.05)
			continue
		end

		if MM2.IsPreRoundActive
			and MM2.IsPreRoundActive() then

			FarmPause("INTERMISSION")

			task.wait(0.10)
			continue
		end

		if FarmBagFull then
			if not FarmBagLiftDone then
				FarmBeginBagFullLift()
			end

			task.wait(0.10)
			continue
		end

		if not FarmUpdateCharacter() then
			FarmPause("NO CHARACTER")

			task.wait(0.10)
			continue
		end

		if FarmHumanoid.Health <= 0 then
			FarmPause("NOT ALIVE")

			task.wait(0.10)
			continue
		end

		--====================================================
		-- V13.4 Pick best vertical-aware valid coin
		--====================================================

		if not FarmCurrentCoin then
			local coin,nearestDistance =
				FarmFindNearestCoin()

			if not coin then
				FarmPause("NO COINS")

				task.wait(0.08)
				continue
			end

			if nearestDistance
				> FARM_MAX_START_DISTANCE then

				FarmPause("COINS TOO FAR")

				task.wait(0.08)
				continue
			end

			if not FarmWake() then
				task.wait(0.05)
				continue
			end

			FarmSelectTarget(coin)
		end

		if FarmPaused then
			task.wait(0.02)
			continue
		end

		if not FarmCurrentCoin then
			continue
		end

		if not FarmCurrentCoin:IsDescendantOf(workspace) then
			FarmReleaseTarget()
			continue
		end

		local coinPos =
			FarmGetPosition(
				FarmCurrentCoin
			)

		if not coinPos then
			FarmReleaseTarget()
			continue
		end

		local distance =
			(FarmHRP.Position-coinPos).Magnitude

		if distance
			> FARM_MAX_TARGET_DISTANCE then

			FarmReleaseTarget()
			continue
		end

		--====================================================
		-- Collection Check
		--====================================================

		local collection =
			FarmCheckCollection(
				FarmCurrentCoin,
				coinPos
			)

		if collection == true
			or collection == "invalid" then

			FarmReleaseTarget()
			continue
		end

		--====================================================
		-- V13.3 NORMAL MOVEMENT + CONTACT RE-ARM
		--====================================================

		if FarmPositionAlign then
			FarmApplyHRPSize()

			FarmPositionAlign.MaxVelocity =
				math.clamp(
					tonumber(Flags.FarmSpeed)
						or FARM_MAX_VELOCITY,
					5,
					FARM_MAX_VELOCITY
				)

			FarmUpdateRearm(
				coinPos
			)
		end

		task.wait(FARM_LOOP_DELAY)
	end

	--========================================================
	-- Cleanup
	--========================================================

	AutoFarmRunning = false

	FarmPaused = false
	FarmPauseReason = nil

	FarmBagLiftInProgress = false

	FarmReleaseTarget()
	FarmStopNoclip()
	FarmDestroyMovement()
	FarmRestoreHRPSize()
end

--============================================================
-- Public AutoFarm Functions
--============================================================

function MM2.Functions.StartAutoFarm()
	if AutoFarmRunning then
		return
	end

	AutoFarmRunning = true

	FarmPaused = false
	FarmPauseReason = nil

	FarmBagLiftInProgress = false
	FarmBagLiftDone = false

	FarmAfterBagFullHandled = false
	FarmAfterBagActionBusy = false

	FarmSafeReturnCFrame = nil

	FarmCurrentCoin = nil
	FarmCurrentTouch = nil

	FarmResetRearm()

	table.clear(FarmCoinSkipUntil)

	FarmUpdateCharacter()
	FarmApplyHRPSize()

	task.spawn(FarmLoop)
end

function MM2.Functions.StopAutoFarm()
	AutoFarmRunning = false

	FarmPaused = false
	FarmPauseReason = nil

	FarmBagLiftInProgress = false
	FarmBagLiftDone = false

	FarmAfterBagFullHandled = false
	FarmAfterBagActionBusy = false

	FarmReturnToSafePosition()

	FarmReleaseTarget()
	FarmStopNoclip()
	FarmDestroyMovement()
	FarmRestoreHRPSize()

	table.clear(FarmCoinSkipUntil)

	FarmSafeReturnCFrame = nil
end

function MM2.Functions.UpdateAutoFarm()
	if Flags.AutoFarm then
		if not AutoFarmRunning then
			MM2.Functions.StartAutoFarm()
		end
	elseif AutoFarmRunning then
		MM2.Functions.StopAutoFarm()
	end
end

--============================================================
-- After Bag Full UI
--============================================================

UI.AddSection(
	UI.AutoFarmPage,
	"After Bag Full",
	"Choose what happens when your coin bag fills"
)

UI.CreateToggle(
	UI.AutoFarmPage,
	"Kill All After Bag Full",
	"Uses Kill All after bag full",
	"KillAllAfterBagFull"
)

UI.CreateToggle(
	UI.AutoFarmPage,
	"Shoot Murderer After Bag Full",
	"Repeatedly shoots murderer until they go down",
	"ShootMurdererAfterBagFull"
)

UI.CreateToggle(
	UI.AutoFarmPage,
	"Fling Murderer After Bag Full",
	"Throws away the murderer after bag full",
	"FlingMurdererAfterBagFull"
)

UI.CreateToggle(
	UI.AutoFarmPage,
	"Reset Character After Bag Full",
	"Resets your character after bag full",
	"ResetCharacterAfterBagFull",
	function(on)
		if on
			and UI.SetToggleState then

			UI.SetToggleState(
				"StayUndergroundAfterBagFull",
				false,
				false
			)
		end
	end
)

UI.CreateToggle(
	UI.AutoFarmPage,
	"Stay Underground After Bag Full",
	"Moves 6 studs below the map floor after bag full",
	"StayUndergroundAfterBagFull",
	function(on)
		if on
			and UI.SetToggleState then

			UI.SetToggleState(
				"ResetCharacterAfterBagFull",
				false,
				false
			)
		end
	end
)

if Flags.ResetCharacterAfterBagFull
	and Flags.StayUndergroundAfterBagFull then

	Flags.StayUndergroundAfterBagFull = false

	if UI.SetToggleState then
		UI.SetToggleState(
			"StayUndergroundAfterBagFull",
			false,
			false
		)
	end
end

--============================================================
-- Stats
--============================================================

UI.AddSection(
	UI.AutoFarmPage,
	"Stats",
	"Coin farming statistics"
)

local CoinRateCard = Instance.new("Frame")
CoinRateCard.Size = UDim2.new(1,0,0,64)
CoinRateCard.BackgroundColor3 = UI.COLORS.Card
CoinRateCard.BorderSizePixel = 0
CoinRateCard.Parent = UI.AutoFarmPage

local CoinRateCorner = Instance.new("UICorner")
CoinRateCorner.CornerRadius = UDim.new(0,11)
CoinRateCorner.Parent = CoinRateCard

local CoinRateStroke = Instance.new("UIStroke")
CoinRateStroke.Color = UI.COLORS.Stroke
CoinRateStroke.Transparency = 0.45
CoinRateStroke.Parent = CoinRateCard

local CoinRateTitle = Instance.new("TextLabel")
CoinRateTitle.Size = UDim2.new(1,-28,0,20)
CoinRateTitle.Position = UDim2.fromOffset(14,10)
CoinRateTitle.BackgroundTransparency = 1
CoinRateTitle.TextXAlignment = Enum.TextXAlignment.Left
CoinRateTitle.Text = "Coin Rate"
CoinRateTitle.TextColor3 = UI.COLORS.Text
CoinRateTitle.TextSize = 12
CoinRateTitle.Font = Enum.Font.GothamBold
CoinRateTitle.Parent = CoinRateCard

local CoinRateValue = Instance.new("TextLabel")
CoinRateValue.Size = UDim2.new(1,-28,0,18)
CoinRateValue.Position = UDim2.fromOffset(14,34)
CoinRateValue.BackgroundTransparency = 1
CoinRateValue.TextXAlignment = Enum.TextXAlignment.Left
CoinRateValue.Text = "0 coins/min"
CoinRateValue.TextColor3 = UI.COLORS.Muted
CoinRateValue.TextSize = 10
CoinRateValue.Font = Enum.Font.Gotham
CoinRateValue.Parent = CoinRateCard

local function FarmResetStats()
	FarmStatsCoins = 0
	FarmStatsStartedAt = nil
	FarmLastReportedBagCount = FarmBagCount

	CoinRateValue.Text =
		"0 coins/min"
end

UI.CreateActionFeature(
	UI.AutoFarmPage,
	"Reset Stats",
	"Resets coin rate statistics",
	FarmResetStats
)

MM2.Track(
	RunService.Heartbeat:Connect(function()
		if not FarmStatsStartedAt
			or FarmStatsCoins <= 0 then

			CoinRateValue.Text =
				"0 coins/min"

			return
		end

		local elapsed =
			math.max(
				os.clock()-FarmStatsStartedAt,
				1
			)

		local rate =
			FarmStatsCoins
			/
			(elapsed/60)

		CoinRateValue.Text =
			string.format(
				"%.1f coins/min",
				rate
			)
	end)
)

--============================================================
-- Gameplay Remotes
--============================================================

local ReplicatedStorage =
	MM2.Services.ReplicatedStorage

local Track = MM2.Track

local FarmGameplayRemotes =
	ReplicatedStorage:FindFirstChild("Remotes")
	and ReplicatedStorage.Remotes:FindFirstChild("Gameplay")

local FarmCoinCollected =
	FarmGameplayRemotes
	and FarmGameplayRemotes:FindFirstChild("CoinCollected")

local FarmRoundStart =
	FarmGameplayRemotes
	and FarmGameplayRemotes:FindFirstChild("RoundStart")

local FarmCoinsStarted =
	FarmGameplayRemotes
	and FarmGameplayRemotes:FindFirstChild("CoinsStarted")

local FarmVictoryScreen =
	FarmGameplayRemotes
	and FarmGameplayRemotes:FindFirstChild("VictoryScreen")

if FarmCoinCollected
	and FarmCoinCollected:IsA("RemoteEvent") then

	Track(
		FarmCoinCollected.OnClientEvent:Connect(function(...)
			local args = {...}

			local current =
				tonumber(args[2])

			local maximum =
				tonumber(args[3])

			if maximum
				and maximum > 0 then

				FarmBagMax = maximum
			end

			if current then
				if current
					> FarmLastReportedBagCount then

					FarmStatsCoins +=
						current
						-
						FarmLastReportedBagCount

					FarmStatsStartedAt =
						FarmStatsStartedAt
						or os.clock()

					if AutoFarmRunning
						and not FarmBagFull then

						FarmReleaseTarget()
					end
				end

				FarmLastReportedBagCount =
					current

				FarmBagCount =
					current
			end

			FarmBagFull =
				FarmBagCount
				>=
				FarmBagMax

			if Flags.AutoFarm
				and FarmBagFull then

				FarmBeginBagFullLift()
			end
		end)
	)
end

--============================================================
-- Round Reset
--============================================================

local function FarmResetBag()
	FarmBagCount = 0
	FarmLastReportedBagCount = 0

	FarmBagFull = false

	FarmPaused = false
	FarmPauseReason = nil

	FarmBagLiftInProgress = false
	FarmBagLiftDone = false

	FarmAfterBagFullHandled = false
	FarmAfterBagActionBusy = false

	FarmSafeReturnCFrame = nil

	table.clear(FarmCoinSkipUntil)

	FarmReleaseTarget()
end

if FarmRoundStart
	and FarmRoundStart:IsA("RemoteEvent") then

	Track(
		FarmRoundStart.OnClientEvent:Connect(
			FarmResetBag
		)
	)
end

if FarmCoinsStarted
	and FarmCoinsStarted:IsA("RemoteEvent") then

	Track(
		FarmCoinsStarted.OnClientEvent:Connect(
			FarmResetBag
		)
	)
end

if FarmVictoryScreen
	and FarmVictoryScreen:IsA("RemoteEvent") then

	Track(
		FarmVictoryScreen.OnClientEvent:Connect(function()
			if Flags.AutoFarm then
				FarmPause("INTERMISSION")
			end
		end)
	)
end

return MM2