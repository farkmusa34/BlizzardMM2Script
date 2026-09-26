--============================================================
-- MM2 V8.8.4 - AutoFarm.lua
-- Coin Farm V14.0 precise upright safe return
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

UI.AddSection(UI.AutoFarmPage,"Auto Farm","Coin Farm V14.0 precise upright safe return")

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
-- V13.4 Predictive Vertical Pickup
-- Only affects steep upward targets that are already nearby.
-- Normal coins keep the exact V13.3 direct path.
--============================================================

local FARM_PREDICTIVE_MIN_UPWARD_RISE = 10
local FARM_PREDICTIVE_MAX_HORIZONTAL = 20
local FARM_PREDICTIVE_STAGE_Y_TOLERANCE = 0.65
local FARM_PREDICTIVE_MIN_STAGE_HORIZONTAL = 8
local FARM_PREDICTIVE_STAGE_TIMEOUT = 1.50

--============================================================
-- V13.5 Horizontal Contact Retry
-- Runs only after a normal pickup has settled under the coin
-- without registering. The existing vertical re-arm remains backup.
--============================================================

local FARM_CONTACT_RETRY_DISTANCE = 2.00
local FARM_CONTACT_RETRY_REACHED = 1.70
local FARM_CONTACT_RETRY_EXIT_TIMEOUT = 0.40
local FARM_CONTACT_RETRY_CROSS_TIMEOUT = 0.55
local FARM_CONTACT_RETRY_VERIFY_DELAY = 0.25

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

local FarmOriginalHRPSize = nil
local FarmSizedHRP = nil

--============================================================
-- V13.3 Re-Arm State
--============================================================

local FarmRearmState = "idle"
local FarmRearmCloseStartedAt = nil
local FarmRearmStateStartedAt = 0
local FarmRearmAttempts = 0

-- V13.5 one-shot horizontal contact retry state.
local FarmContactRetryUsed = false
local FarmContactRetryDirection = nil

-- V13.4 predictive staging state.
local FarmPredictiveStageActive = false
local FarmPredictiveStageXZ = nil
local FarmPredictiveStageStartedAt = 0

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
	if FarmSizedHRP and FarmSizedHRP.Parent and FarmOriginalHRPSize then
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
	if FarmSizedHRP and FarmSizedHRP ~= FarmHRP then
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
		if obj.Name == "TouchInterest" or obj:IsA("TouchTransmitter") then
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
	local untilTime = FarmCoinSkipUntil[coin]
	if not untilTime then
		return false
	end
	if os.clock() >= untilTime then
		FarmCoinSkipUntil[coin] = nil
		return false
	end
	return true
end

local function FarmFindNearestCoin()
	if not FarmHRP then
		return nil,math.huge
	end

	local best = nil
	local bestDistance = math.huge

	for _,obj in ipairs(workspace:GetDescendants()) do
		if FarmValidCoin(obj) and not FarmCoinIsTemporarilySkipped(obj) then
			local pos = FarmGetPosition(obj)
			if pos then
				local distance = (FarmHRP.Position-pos).Magnitude
				if distance < bestDistance then
					best = obj
					bestDistance = distance
				end
			end
		end
	end

	return best,bestDistance
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
	FarmAttachment.Name = "FarmAttachmentV13_3"
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
			or (FarmPaused and not FarmBagLiftInProgress) then
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
	FarmContactRetryUsed = false
	FarmContactRetryDirection = nil
end

local function FarmResetPredictiveStage()
	FarmPredictiveStageActive = false
	FarmPredictiveStageXZ = nil
	FarmPredictiveStageStartedAt = 0
end

local function FarmReleaseTarget()
	FarmCurrentCoin = nil
	FarmCurrentTouch = nil
	FarmResetRearm()
	FarmResetPredictiveStage()
end

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

local function FarmSelectTarget(coin)
	if not FarmValidCoin(coin) or not FarmEnsureMovement() then
		return false
	end

	local coinPos = FarmGetPosition(coin)
	if not coinPos then
		return false
	end

	FarmCurrentCoin = coin
	FarmCurrentTouch = FarmGetTouchObject(coin)
	FarmResetRearm()
	FarmResetPredictiveStage()

	local targetY = coinPos.Y + FARM_COIN_Y_OFFSET
	local dx = FarmHRP.Position.X - coinPos.X
	local dz = FarmHRP.Position.Z - coinPos.Z
	local horizontal = math.sqrt(dx*dx + dz*dz)
	local upwardRise = targetY - FarmHRP.Position.Y

	local riskyVerticalPickup =
		upwardRise >= FARM_PREDICTIVE_MIN_UPWARD_RISE
		and horizontal <= FARM_PREDICTIVE_MAX_HORIZONTAL

	if riskyVerticalPickup then
		local stageX = FarmHRP.Position.X
		local stageZ = FarmHRP.Position.Z

		if horizontal < FARM_PREDICTIVE_MIN_STAGE_HORIZONTAL then
			local awayX = dx
			local awayZ = dz
			local awayMagnitude = math.sqrt(awayX*awayX + awayZ*awayZ)

			if awayMagnitude < 0.05 then
				local look = FarmHRP.CFrame.LookVector
				awayX = look.X
				awayZ = look.Z
				awayMagnitude = math.sqrt(awayX*awayX + awayZ*awayZ)
			end

			if awayMagnitude < 0.05 then
				awayX = 1
				awayZ = 0
				awayMagnitude = 1
			end

			awayX /= awayMagnitude
			awayZ /= awayMagnitude

			stageX = coinPos.X + awayX*FARM_PREDICTIVE_MIN_STAGE_HORIZONTAL
			stageZ = coinPos.Z + awayZ*FARM_PREDICTIVE_MIN_STAGE_HORIZONTAL
		end

		FarmPredictiveStageActive = true
		FarmPredictiveStageXZ = Vector2.new(stageX,stageZ)
		FarmPredictiveStageStartedAt = os.clock()

		FarmPositionAlign.Position =
			Vector3.new(
				stageX,
				targetY,
				stageZ
			)
	else
		FarmPositionAlign.Position = FarmGetCoinTarget(coinPos)
	end

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
	local dx = FarmHRP.Position.X-coinPos.X
	local dz = FarmHRP.Position.Z-coinPos.Z
	return math.sqrt(dx*dx + dz*dz)
end

local function FarmVerticalBelowCoin(coinPos)
	if not FarmHRP then
		return math.huge
	end
	return coinPos.Y-FarmHRP.Position.Y
end

local function FarmUpdatePredictiveStage(coinPos)
	if not FarmPredictiveStageActive
		or not FarmPredictiveStageXZ
		or not FarmPositionAlign
		or not FarmHRP then
		return false
	end

	local targetY = coinPos.Y + FARM_COIN_Y_OFFSET
	local yError = math.abs(FarmHRP.Position.Y-targetY)
	local timedOut =
		os.clock()-FarmPredictiveStageStartedAt
		>= FARM_PREDICTIVE_STAGE_TIMEOUT

	if yError <= FARM_PREDICTIVE_STAGE_Y_TOLERANCE or timedOut then
		FarmPredictiveStageActive = false
		FarmPredictiveStageXZ = nil
		FarmPredictiveStageStartedAt = 0
		FarmPositionAlign.Position = FarmGetCoinTarget(coinPos)

		return false
	end

	FarmPositionAlign.Position =
		Vector3.new(
			FarmPredictiveStageXZ.X,
			targetY,
			FarmPredictiveStageXZ.Y
		)

	return true
end
local function FarmGetContactRetryDirection(coinPos)
	if not FarmHRP then
		return Vector2.new(1,0)
	end

	local dx = FarmHRP.Position.X-coinPos.X
	local dz = FarmHRP.Position.Z-coinPos.Z
	local magnitude = math.sqrt(dx*dx + dz*dz)

	if magnitude >= 0.10 then
		return Vector2.new(dx/magnitude,dz/magnitude)
	end

	local right = FarmHRP.CFrame.RightVector
	local rx = right.X
	local rz = right.Z
	local rightMagnitude = math.sqrt(rx*rx + rz*rz)

	if rightMagnitude >= 0.10 then
		return Vector2.new(rx/rightMagnitude,rz/rightMagnitude)
	end

	return Vector2.new(1,0)
end

local function FarmGetContactRetryTarget(coinPos,side)
	local direction = FarmContactRetryDirection or Vector2.new(1,0)
	return Vector3.new(
		coinPos.X + direction.X*FARM_CONTACT_RETRY_DISTANCE*side,
		coinPos.Y + FARM_COIN_Y_OFFSET,
		coinPos.Z + direction.Y*FARM_CONTACT_RETRY_DISTANCE*side
	)
end

local function FarmBeginContactRetry(coinPos)
	FarmContactRetryUsed = true
	FarmContactRetryDirection = FarmGetContactRetryDirection(coinPos)
	FarmRearmState = "contactExit"
	FarmRearmStateStartedAt = os.clock()
	FarmRearmCloseStartedAt = nil
end

local function FarmBeginRearm()
	FarmRearmAttempts += 1
	FarmRearmState = "exit"
	FarmRearmStateStartedAt = os.clock()
	FarmRearmCloseStartedAt = nil
end

local function FarmUpdateRearm(coinPos)
	if not FarmPositionAlign or not FarmHRP then
		return
	end

	local now = os.clock()
	local horizontalDistance = FarmHorizontalDistanceToCoin(coinPos)
	local verticalBelow = FarmVerticalBelowCoin(coinPos)

	if FarmRearmState == "idle" then
		FarmPositionAlign.Position = FarmGetCoinTarget(coinPos)

		local settled =
			horizontalDistance <= FARM_REARM_CLOSE_HORIZONTAL
			and verticalBelow >= FARM_REARM_MIN_SETTLED_V
			and verticalBelow <= FARM_REARM_MAX_SETTLED_V

		if settled then
			if not FarmRearmCloseStartedAt then
				FarmRearmCloseStartedAt = now
			end

			if now-FarmRearmCloseStartedAt >= FARM_REARM_STUCK_DELAY then
				if not FarmContactRetryUsed then
					FarmBeginContactRetry(coinPos)
				else
					FarmBeginRearm()
				end
			end
		else
			FarmRearmCloseStartedAt = nil
		end

		return
	end

	if FarmRearmState == "contactExit" then
		FarmPositionAlign.Position = FarmGetContactRetryTarget(coinPos,1)

		local reached =
			FarmHorizontalDistanceToCoin(coinPos)
			>= FARM_CONTACT_RETRY_REACHED
		local timedOut =
			now-FarmRearmStateStartedAt
			>= FARM_CONTACT_RETRY_EXIT_TIMEOUT

		if reached or timedOut then
			FarmRearmState = "contactCross"
			FarmRearmStateStartedAt = now
		end

		return
	end

	if FarmRearmState == "contactCross" then
		FarmPositionAlign.Position = FarmGetContactRetryTarget(coinPos,-1)

		local direction = FarmContactRetryDirection or Vector2.new(1,0)
		local relX = FarmHRP.Position.X-coinPos.X
		local relZ = FarmHRP.Position.Z-coinPos.Z
		local signedAlong =
			relX*direction.X + relZ*direction.Y
		local reachedOtherSide =
			signedAlong <= -FARM_CONTACT_RETRY_REACHED
		local timedOut =
			now-FarmRearmStateStartedAt
			>= FARM_CONTACT_RETRY_CROSS_TIMEOUT

		if reachedOtherSide or timedOut then
			FarmRearmState = "contactVerify"
			FarmRearmStateStartedAt = now
			FarmPositionAlign.Position = FarmGetCoinTarget(coinPos)
		end

		return
	end

	if FarmRearmState == "contactVerify" then
		FarmPositionAlign.Position = FarmGetCoinTarget(coinPos)

		if now-FarmRearmStateStartedAt < FARM_CONTACT_RETRY_VERIFY_DELAY then
			return
		end

		FarmBeginRearm()
		return
	end

	if FarmRearmState == "exit" then
		FarmPositionAlign.Position =
			FarmGetCoinTargetWithOffset(
				coinPos,
				FARM_REARM_EXIT_Y_OFFSET
			)

		local outsideContact = verticalBelow >= FARM_REARM_EXIT_REACHED_V
		local timedOut = now-FarmRearmStateStartedAt >= FARM_REARM_EXIT_TIMEOUT

		if outsideContact then
			FarmRearmState = "hold"
			FarmRearmStateStartedAt = now
		elseif timedOut then
			-- Timeout alone is not treated as successful separation.
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

		if now-FarmRearmStateStartedAt >= FARM_REARM_SEPARATION_HOLD then
			FarmRearmState = "reenter"
			FarmRearmStateStartedAt = now
		end

		return
	end

	if FarmRearmState == "reenter" then
		FarmPositionAlign.Position = FarmGetCoinTarget(coinPos)

		local backInPickupZone = verticalBelow <= FARM_REARM_REENTER_V
		local timedOut = now-FarmRearmStateStartedAt >= FARM_REARM_REENTER_TIMEOUT

		if backInPickupZone or timedOut then
			FarmRearmState = "verify"
			FarmRearmStateStartedAt = now
		end

		return
	end

	if FarmRearmState == "verify" then
		FarmPositionAlign.Position = FarmGetCoinTarget(coinPos)

		if now-FarmRearmStateStartedAt < FARM_REARM_VERIFY_DELAY then
			return
		end

		if FarmRearmAttempts < FARM_REARM_MAX_ATTEMPTS then
			FarmRearmState = "idle"
			FarmRearmCloseStartedAt =
				now-(FARM_REARM_STUCK_DELAY-0.10)
			return
		end

		local failedCoin = FarmCurrentCoin
		if failedCoin then
			FarmCoinSkipUntil[failedCoin] = now + FARM_REARM_SKIP_TIME
		end

		FarmReleaseTarget()
		return
	end
end

--============================================================
-- Safe Position
-- V14.0: full-body clearance + controlled upright settle
--============================================================

local FARM_RETURN_STAND_OFFSET = 2.95
local FARM_RETURN_CAST_ABOVE = 220
local FARM_RETURN_CAST_DEPTH = 520
local FARM_RETURN_FALLBACK_RADIUS = 420
local FARM_RETURN_FALLBACK_STEP = 10
local FARM_RETURN_FALLBACK_SAMPLES = 32

-- Stricter standing-space checks. The old version mostly used vertical rays,
-- which could miss furniture/walls clipping the sides of the character.
local FARM_RETURN_BOX_SIZE = Vector3.new(4.2,5.8,4.2)
local FARM_RETURN_BOX_Y_OFFSET = 2.95
local FARM_RETURN_EDGE_SAMPLE_RADIUS = 1.65
local FARM_RETURN_MIN_FLOOR_NORMAL = 0.90
local FARM_RETURN_MAX_FLOOR_VARIANCE = 0.55

-- Controlled landing/settle values.
local FARM_RETURN_HOVER_HEIGHT = 1.35
local FARM_RETURN_HOLD_FRAMES = 10
local FARM_RETURN_STABLE_FRAMES = 10
local FARM_RETURN_VERIFY_TIMEOUT = 1.35
local FARM_RETURN_MAX_ATTEMPTS = 5
local FARM_RETURN_RECOVERY_RADIUS = 36
local FARM_RETURN_RECOVERY_STEP = 5
local FARM_RETURN_RECOVERY_SAMPLES = 24

local FarmLastSafeReturnCFrame = nil
local FarmLastSafeReturnAt = 0

local function FarmIsUnsafeReturnPart(part)
    if not part then return true end
    local node = part
    while node and node ~= workspace do
        local name = string.lower(node.Name)
        if string.find(name,"glitchproof",1,true)
            or string.find(name,"glitch proof",1,true)
            or string.find(name,"coincontainer",1,true)
            or name == "coin_server" then
            return true
        end
        node = node.Parent
    end
    return false
end

local function FarmMakeRayParams(extraIgnore)
    local ignore = {FarmCharacter}
    if extraIgnore then
        for _,v in ipairs(extraIgnore) do
            table.insert(ignore,v)
        end
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignore
    params.IgnoreWater = true
    params.RespectCanCollide = true
    return params
end

local function FarmMakeOverlapParams()
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {FarmCharacter}
    params.RespectCanCollide = true
    params.MaxParts = 80
    return params
end

local function FarmHasReturnClearance(surfacePosition)
    if not FarmCharacter then return false end

    -- Test the actual volume the standing rig will occupy. Start the box just
    -- above the floor so the floor itself is not falsely counted as an obstacle.
    local center = surfacePosition + Vector3.new(0,FARM_RETURN_BOX_Y_OFFSET + 0.15,0)
    local parts = workspace:GetPartBoundsInBox(
        CFrame.new(center),
        FARM_RETURN_BOX_SIZE,
        FarmMakeOverlapParams()
    )

    for _,part in ipairs(parts) do
        if part:IsA("BasePart") and part.CanCollide then
            -- Any collidable geometry in the standing volume means this point
            -- is too close to a wall, prop, stair, ceiling, or other obstruction.
            return false
        end
    end

    return true
end

local function FarmHasFloorSupport(x,z,surfaceY)
    -- Nine support samples, including diagonals, reject ledges and uneven props.
    local r = FARM_RETURN_EDGE_SAMPLE_RADIUS
    local offsets = {
        Vector2.new(0,0),
        Vector2.new(r,0), Vector2.new(-r,0),
        Vector2.new(0,r), Vector2.new(0,-r),
        Vector2.new(r,r), Vector2.new(r,-r),
        Vector2.new(-r,r), Vector2.new(-r,-r),
    }

    for _,offset in ipairs(offsets) do
        local result = workspace:Raycast(
            Vector3.new(x+offset.X,surfaceY+2.5,z+offset.Y),
            Vector3.new(0,-5.0,0),
            FarmMakeRayParams()
        )

        if not result
            or not result.Instance
            or not result.Instance:IsA("BasePart")
            or not result.Instance.CanCollide
            or FarmIsUnsafeReturnPart(result.Instance)
            or result.Normal.Y < FARM_RETURN_MIN_FLOOR_NORMAL
            or math.abs(result.Position.Y-surfaceY) > FARM_RETURN_MAX_FLOOR_VARIANCE then
            return false
        end
    end

    return true
end

local function FarmValidateReturnResult(result)
    if not result or not result.Instance then return false end
    if not result.Instance:IsA("BasePart") or not result.Instance.CanCollide then return false end
    if FarmIsUnsafeReturnPart(result.Instance) then return false end
    if result.Normal.Y < FARM_RETURN_MIN_FLOOR_NORMAL then return false end

    local p = result.Position
    if not FarmHasFloorSupport(p.X,p.Z,p.Y) then return false end
    if not FarmHasReturnClearance(p) then return false end
    return true
end

local function FarmRaycastSafeSurface(x,z,originY,depth)
    local ignore = {FarmCharacter}

    for _ = 1,32 do
        local result = workspace:Raycast(
            Vector3.new(x,originY,z),
            Vector3.new(0,-depth,0),
            FarmMakeRayParams(ignore)
        )
        if not result then return nil end
        if FarmValidateReturnResult(result) then return result end
        table.insert(ignore,result.Instance)
    end

    return nil
end

local function FarmRememberSafePosition()
    if not FarmUpdateCharacter() or not FarmHumanoid or FarmHumanoid.Health <= 0 then return end

    local result = workspace:Raycast(
        FarmHRP.Position+Vector3.new(0,2,0),
        Vector3.new(0,-10,0),
        FarmMakeRayParams()
    )
    if not FarmValidateReturnResult(result) then return end

    local height = FarmHRP.Position.Y-result.Position.Y
    if height < 1.5 or height > 5.5 then return end

    local _,yaw,_ = FarmHRP.CFrame:ToOrientation()
    FarmLastSafeReturnCFrame =
        CFrame.new(result.Position.X,result.Position.Y+FARM_RETURN_STAND_OFFSET,result.Position.Z)
        * CFrame.Angles(0,yaw,0)
    FarmLastSafeReturnAt = os.clock()
end

local function FarmFindNearestReturnSurface(current,maxRadius,step,samples,rejectPositions)
    maxRadius = maxRadius or FARM_RETURN_FALLBACK_RADIUS
    step = step or FARM_RETURN_FALLBACK_STEP
    samples = samples or FARM_RETURN_FALLBACK_SAMPLES
    rejectPositions = rejectPositions or {}

    local castY = current.Y+FARM_RETURN_CAST_ABOVE

    local function rejected(p)
        for _,bad in ipairs(rejectPositions) do
            local flat = Vector3.new(p.X-bad.X,0,p.Z-bad.Z)
            if flat.Magnitude < 5.0 and math.abs(p.Y-bad.Y) < 4.0 then
                return true
            end
        end
        return false
    end

    local direct = FarmRaycastSafeSurface(current.X,current.Z,castY,FARM_RETURN_CAST_DEPTH)
    if direct and not rejected(direct.Position) then return direct end

    for radius = step,maxRadius,step do
        local ringBest,ringBestScore = nil,math.huge
        for i = 0,samples-1 do
            local angle = (math.pi*2*i)/samples
            local x = current.X+math.cos(angle)*radius
            local z = current.Z+math.sin(angle)*radius
            local result = FarmRaycastSafeSurface(x,z,castY,FARM_RETURN_CAST_DEPTH)
            if result and not rejected(result.Position) then
                local dx,dz = result.Position.X-current.X,result.Position.Z-current.Z
                local score = math.sqrt(dx*dx+dz*dz)
                if score < ringBestScore then
                    ringBest,ringBestScore = result,score
                end
            end
        end
        if ringBest then return ringBest end
    end
    return nil
end

local function FarmCFrameFromSurface(result,yaw,heightExtra)
    local p = result.Position
    return CFrame.new(p.X,p.Y+FARM_RETURN_STAND_OFFSET+(heightExtra or 0),p.Z)
        * CFrame.Angles(0,yaw,0)
end

local function FarmReturnStateIsBad(state)
    return state == Enum.HumanoidStateType.FallingDown
        or state == Enum.HumanoidStateType.Ragdoll
        or state == Enum.HumanoidStateType.PlatformStanding
        or state == Enum.HumanoidStateType.Seated
end

local function FarmReturnToSafePosition()
    if not FarmUpdateCharacter() then return false end

    local _,currentYaw,_ = FarmHRP.CFrame:ToOrientation()
    local searchOrigin = FarmHRP.Position
    local rejected = {}
    local preferred = nil

    -- A remembered pre-farm position gets first priority only after it passes
    -- every current floor + full-body clearance test again.
    if FarmLastSafeReturnCFrame then
        local saved = FarmLastSafeReturnCFrame.Position
        local result = FarmRaycastSafeSurface(saved.X,saved.Z,saved.Y+8,16)
        if result and math.abs((result.Position.Y+FARM_RETURN_STAND_OFFSET)-saved.Y) <= 1.25 then
            preferred = result
        end
    end

    local function hardResetAt(result)
        if not result or not FarmUpdateCharacter() then return false end

        local hover = FarmCFrameFromSurface(result,currentYaw,FARM_RETURN_HOVER_HEIGHT)
        local stand = FarmCFrameFromSurface(result,currentYaw,0)

        pcall(function()
            FarmHumanoid.Sit = false
            FarmHumanoid.PlatformStand = false
            FarmHumanoid.AutoRotate = false
            FarmHumanoid:ChangeState(Enum.HumanoidStateType.Physics)
        end)

        -- Keep the rig above the floor for a few frames. Noclip is still active
        -- here, so old farm momentum/geometry cannot knock the rig sideways.
        for _ = 1,FARM_RETURN_HOLD_FRAMES do
            if not FarmUpdateCharacter() then return false end
            FarmHRP.CFrame = hover
            FarmHRP.AssemblyLinearVelocity = Vector3.zero
            FarmHRP.AssemblyAngularVelocity = Vector3.zero
            RunService.Heartbeat:Wait()
        end

        -- Put it at normal standing height while still controlled.
        for _ = 1,4 do
            if not FarmUpdateCharacter() then return false end
            FarmHRP.CFrame = stand
            FarmHRP.AssemblyLinearVelocity = Vector3.zero
            FarmHRP.AssemblyAngularVelocity = Vector3.zero
            RunService.Heartbeat:Wait()
        end

        pcall(function()
            FarmHumanoid.Sit = false
            FarmHumanoid.PlatformStand = false
            FarmHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
        RunService.Heartbeat:Wait()
        pcall(function()
            FarmHumanoid:ChangeState(Enum.HumanoidStateType.Running)
        end)

        return true,stand
    end

    for attempt = 1,FARM_RETURN_MAX_ATTEMPTS do
        local result = preferred
        preferred = nil

        if not result then
            result = FarmFindNearestReturnSurface(
                searchOrigin,
                attempt == 1 and FARM_RETURN_FALLBACK_RADIUS or FARM_RETURN_RECOVERY_RADIUS,
                attempt == 1 and FARM_RETURN_FALLBACK_STEP or FARM_RETURN_RECOVERY_STEP,
                attempt == 1 and FARM_RETURN_FALLBACK_SAMPLES or FARM_RETURN_RECOVERY_SAMPLES,
                rejected
            )
        end
        if not result then break end

        local ok,target = hardResetAt(result)
        if not ok then return false end

        -- Turn collisions back on BEFORE verification. This is the important
        -- part: we test whether this exact spot can really support the rig.
        FarmStopNoclip()

        local started = os.clock()
        local stableFrames = 0
        local failed = false

        while os.clock()-started < FARM_RETURN_VERIFY_TIMEOUT do
            RunService.Heartbeat:Wait()
            if not FarmUpdateCharacter() then return false end

            local state = FarmHumanoid:GetState()
            local upDot = FarmHRP.CFrame.UpVector:Dot(Vector3.yAxis)
            local flatDelta = Vector3.new(
                FarmHRP.Position.X-target.Position.X,
                0,
                FarmHRP.Position.Z-target.Position.Z
            ).Magnitude
            local yDelta = math.abs(FarmHRP.Position.Y-target.Position.Y)
            local speed = FarmHRP.AssemblyLinearVelocity.Magnitude

            if FarmReturnStateIsBad(state)
                or upDot < 0.94
                or flatDelta > 2.25
                or yDelta > 2.0 then
                failed = true
                break
            end

            if speed < 2.0 and upDot >= 0.985 and flatDelta < 1.0 and yDelta < 1.0 then
                stableFrames += 1
                if stableFrames >= FARM_RETURN_STABLE_FRAMES then
                    pcall(function()
                        FarmHumanoid.Sit = false
                        FarmHumanoid.PlatformStand = false
                        FarmHumanoid.AutoRotate = true
                        FarmHRP.AssemblyLinearVelocity = Vector3.zero
                        FarmHRP.AssemblyAngularVelocity = Vector3.zero
                        FarmHumanoid:ChangeState(Enum.HumanoidStateType.Running)
                    end)
                    return true
                end
            else
                stableFrames = 0
            end
        end

        -- This candidate looked valid geometrically but failed with real
        -- collisions, so never reuse it during this return attempt.
        table.insert(rejected,result.Position)

        if attempt < FARM_RETURN_MAX_ATTEMPTS then
            -- Re-enable temporary noclip only while relocating to the next
            -- candidate. It will be disabled again before verification.
            FarmStartNoclip()
            pcall(function()
                FarmHumanoid.Sit = false
                FarmHumanoid.PlatformStand = false
                FarmHumanoid.AutoRotate = false
                FarmHRP.AssemblyLinearVelocity = Vector3.zero
                FarmHRP.AssemblyAngularVelocity = Vector3.zero
            end)
        end
    end

    -- Fail-safe: never intentionally leave the character ragdolled.
    FarmStopNoclip()
    if FarmUpdateCharacter() then
        pcall(function()
            FarmHumanoid.Sit = false
            FarmHumanoid.PlatformStand = false
            FarmHumanoid.AutoRotate = true
            FarmHRP.AssemblyLinearVelocity = Vector3.zero
            FarmHRP.AssemblyAngularVelocity = Vector3.zero
            FarmHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
        RunService.Heartbeat:Wait()
        pcall(function()
            FarmHumanoid:ChangeState(Enum.HumanoidStateType.Running)
        end)
    end
    return false
end

--============================================================
-- Pause / Wake
--============================================================

local function FarmPause(reason)
	reason = reason or "PAUSED"

	if reason == "BAG FULL" then
		return
	end

	if FarmPaused and FarmPauseReason == reason then
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

			if humanoid and humanoid.Health > 0 then
				return player
			end
		end
	end

	return nil
end

local function FarmHasKnife()
	if MM2.Functions.HasKnifeAnywhere then
		local ok,result = pcall(MM2.Functions.HasKnifeAnywhere)
		if ok then
			return result == true
		end
	end

	local character = LocalPlayer.Character
	local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")

	for _,container in ipairs({character,backpack}) do
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
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {FarmCharacter}
	params.IgnoreWater = true

	local xz = Vector3.new(FarmHRP.Position.X,0,FarmHRP.Position.Z)

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

			local ok,success = pcall(MM2.Functions.KillAllOnce)
			killAllRan = ok and success == true
		end

		if Flags.ShootMurdererAfterBagFull
			and MM2.Functions.ShootMurderer then

			while MM2.Running
				and Flags.AutoFarm
				and FarmBagFull
				and Flags.ShootMurdererAfterBagFull do

				local murderer = FarmFindMurderer()
				if not murderer then
					break
				end

				local ok,success,message =
					pcall(MM2.Functions.ShootMurderer)

				if not ok then
					break
				end

				if success == true or message == "No Murderer" then
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

			local murderer = FarmFindMurderer()

			if murderer then
				pcall(
					MM2.Functions.ExecuteYeet,
					murderer
				)
			end
		end

		if Flags.ResetCharacterAfterBagFull
			and not killAllRan then

			task.wait(0.15)

			local character = LocalPlayer.Character
			local humanoid =
				character
				and character:FindFirstChildOfClass("Humanoid")

			if humanoid and humanoid.Health > 0 then
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
	if FarmBagLiftInProgress or FarmBagLiftDone then
		return
	end

	FarmBagLiftInProgress = true
	FarmPaused = true
	FarmPauseReason = "BAG FULL"

	FarmReleaseTarget()
	FarmRunAfterBagFullActions()


	task.spawn(function()
		if not FarmUpdateCharacter() or not FarmEnsureMovement() then
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
			FarmHRP.Position + Vector3.new(0,FARM_BAG_LIFT_HEIGHT,0)

		FarmPositionAlign.Position = liftTarget
		local started = os.clock()

		while AutoFarmRunning
			and MM2.Running
			and FarmBagFull do

			if not FarmUpdateCharacter() or not FarmPositionAlign then
				break
			end

			if (FarmHRP.Position-liftTarget).Magnitude
				<= FARM_BAG_LIFT_REACHED_DISTANCE then
				break
			end

			if os.clock()-started >= FARM_BAG_LIFT_TIMEOUT then
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

		if MM2.IsPreRoundActive and MM2.IsPreRoundActive() then
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

		if not FarmCurrentCoin then
			local coin,nearestDistance = FarmFindNearestCoin()

			if not coin then
				FarmPause("NO COINS")
				task.wait(0.08)
				continue
			end

			if nearestDistance > FARM_MAX_START_DISTANCE then
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

		local coinPos = FarmGetPosition(FarmCurrentCoin)

		if not coinPos then
			FarmReleaseTarget()
			continue
		end

		local distance = (FarmHRP.Position-coinPos).Magnitude

		if distance > FARM_MAX_TARGET_DISTANCE then
			FarmReleaseTarget()
			continue
		end

		local collection =
			FarmCheckCollection(
				FarmCurrentCoin,
				coinPos
			)

		if collection == true or collection == "invalid" then
			FarmReleaseTarget()
			continue
		end

		if FarmPositionAlign then
			FarmApplyHRPSize()

			FarmPositionAlign.MaxVelocity =
				math.clamp(
					tonumber(Flags.FarmSpeed) or FARM_MAX_VELOCITY,
					5,
					FARM_MAX_VELOCITY
				)

			if not FarmUpdatePredictiveStage(coinPos) then
				FarmUpdateRearm(coinPos)
			end
		end

		task.wait(FARM_LOOP_DELAY)
	end

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
	FarmCurrentCoin = nil
	FarmCurrentTouch = nil

	FarmResetRearm()
	FarmResetPredictiveStage()
	table.clear(FarmCoinSkipUntil)
	FarmUpdateCharacter()
	FarmRememberSafePosition()
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

	-- Stop every force/target FIRST so nothing can keep dragging the
	-- character while the return is being calculated.
	FarmReleaseTarget()
	FarmDestroyMovement()
	FarmRestoreHRPSize()

	-- Keep noclip active only for the actual relocation. This prevents the
	-- character from getting trapped in geometry while moving back to the
	-- local surface. Then restore normal collisions immediately afterward.
	FarmReturnToSafePosition()
	FarmStopNoclip()

	if FarmUpdateCharacter() then
		pcall(function()
			FarmHumanoid.Sit = false
			FarmHumanoid.PlatformStand = false
			FarmHRP.AssemblyLinearVelocity = Vector3.zero
			FarmHRP.AssemblyAngularVelocity = Vector3.zero
		end)
	end

	table.clear(FarmCoinSkipUntil)
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
	"ResetCharacterAfterBagFull"
)

--============================================================
-- Stats
--============================================================

UI.AddSection(
	UI.AutoFarmPage,
	"Stats",
	"Coin farming statistics"
)

local CoinRateInfo, SetCoinRateText =
	UI.CreateInfo(
		UI.AutoFarmPage,
		"Coin Rate",
		"0 coins/min"
	)

local function FarmResetStats()
	FarmStatsCoins = 0
	FarmStatsStartedAt = nil
	FarmLastReportedBagCount = FarmBagCount

	SetCoinRateText(
		"0 coins/min"
	)
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
			or FarmStatsCoins <= 0
		then
			SetCoinRateText(
				"0 coins/min"
			)

			return
		end

		local elapsed =
			math.max(
				os.clock()
					- FarmStatsStartedAt,
				1
			)

		local rate =
			FarmStatsCoins
			/ (elapsed / 60)

		SetCoinRateText(
			string.format(
				"%.1f coins/min",
				rate
			)
		)
	end)
)

--============================================================
-- Gameplay Remotes
--============================================================

local ReplicatedStorage = MM2.Services.ReplicatedStorage
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

if FarmCoinCollected and FarmCoinCollected:IsA("RemoteEvent") then
	Track(
		FarmCoinCollected.OnClientEvent:Connect(function(...)
			local args = {...}
			local current = tonumber(args[2])
			local maximum = tonumber(args[3])

			if maximum and maximum > 0 then
				FarmBagMax = maximum
			end

			if current then
				if current > FarmLastReportedBagCount then
					FarmStatsCoins += current-FarmLastReportedBagCount
					FarmStatsStartedAt = FarmStatsStartedAt or os.clock()

					if AutoFarmRunning and not FarmBagFull then
						FarmReleaseTarget()
					end
				end

				FarmLastReportedBagCount = current
				FarmBagCount = current
			end

			FarmBagFull = FarmBagCount >= FarmBagMax

			if Flags.AutoFarm and FarmBagFull then
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

	table.clear(FarmCoinSkipUntil)
	FarmReleaseTarget()
end

if FarmRoundStart and FarmRoundStart:IsA("RemoteEvent") then
	Track(
		FarmRoundStart.OnClientEvent:Connect(
			FarmResetBag
		)
	)
end

if FarmCoinsStarted and FarmCoinsStarted:IsA("RemoteEvent") then
	Track(
		FarmCoinsStarted.OnClientEvent:Connect(
			FarmResetBag
		)
	)
end

if FarmVictoryScreen and FarmVictoryScreen:IsA("RemoteEvent") then
	Track(
		FarmVictoryScreen.OnClientEvent:Connect(function()
			if Flags.AutoFarm then
				FarmPause("INTERMISSION")
			end
		end)
	)
end

return MM2
