--============================================================
-- MM2 V8.8.4 - AutoFarm.lua
-- Coin Farm V13.10 lifecycle-safe shutdown + nearest safe return
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

UI.AddSection(UI.AutoFarmPage,"Auto Farm","Coin Farm V13.10 lifecycle-safe return")

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
-- Shutdown generation prevents stale farm tasks from re-enabling movement/noclip.
local FarmRunGeneration = 0
local FarmLoopGeneration = nil
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
-- V13.11 Embedded Lifecycle Diagnostic
--============================================================

local FarmDiagLogs = {}
local FarmDiagMaxLogs = 900
local FarmDiagMarkTime = nil
local FarmDiagLastCanCollide = nil
local FarmDiagLastNC = nil
local FarmDiagLastMoverCount = nil
local FarmDiagLastGeneration = FarmRunGeneration
local FarmDiagLastRunning = AutoFarmRunning
local FarmDiagLastUpdateFlag = nil
local FarmDiagLastUpdateRunning = nil

local function FarmDiag(message)
    local line = string.format("[%.3f] %s", os.clock(), tostring(message))
    table.insert(FarmDiagLogs, line)
    if #FarmDiagLogs > FarmDiagMaxLogs then
        table.remove(FarmDiagLogs, 1)
    end
    print("[AutoFarmDiag] " .. line)
end

local function FarmDiagState(prefix)
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    local nc, total, movers = 0, 0, 0
    if character then
        for _,obj in ipairs(character:GetDescendants()) do
            if obj:IsA("BasePart") then
                total += 1
                if not obj.CanCollide then nc += 1 end
            end
            if obj.Name == "FarmAlign" or obj.Name == "FarmUprightAlign" or obj.Name == "FarmAttachmentV13_3" then
                movers += 1
            end
        end
    end
    local vel = root and root.AssemblyLinearVelocity or Vector3.zero
    FarmDiag(string.format(
        "%s | Flag=%s Running=%s Gen=%s LoopGen=%s Paused=%s NoclipConn=%s Movers=%d NC=%d/%d RootCollide=%s Speed=%.2f State=%s",
        prefix,
        tostring(Flags.AutoFarm), tostring(AutoFarmRunning), tostring(FarmRunGeneration),
        tostring(FarmLoopGeneration), tostring(FarmPaused), tostring(FarmNoclipConnection ~= nil),
        movers, nc, total, tostring(root and root.CanCollide),
        Vector3.new(vel.X,0,vel.Z).Magnitude,
        tostring(hum and hum:GetState())
    ))
end

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
	FarmDiag("FarmDestroyMovement() called")
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

local function FarmEnsureMovement(expectedGeneration)
	FarmDiag("FarmEnsureMovement() expectedGen=" .. tostring(expectedGeneration) .. " currentGen=" .. tostring(FarmRunGeneration) .. " running=" .. tostring(AutoFarmRunning))
	-- Never allow a stale callback to recreate farm movers after OFF.
	if not AutoFarmRunning then
		return false
	end
	if expectedGeneration ~= nil and expectedGeneration ~= FarmRunGeneration then
		return false
	end
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
	FarmDiag("MOVERS CREATED by FarmEnsureMovement gen=" .. tostring(FarmRunGeneration))

	return true
end

--============================================================
-- Noclip
--============================================================

local function FarmApplyNoclip(expectedGeneration)
	if not AutoFarmRunning then
		return false
	end
	if expectedGeneration ~= nil and expectedGeneration ~= FarmRunGeneration then
		return false
	end
	if not FarmCharacter or not FarmHumanoid then
		return false
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

	return true
end

local function FarmStartNoclip(expectedGeneration)
	FarmDiag("FarmStartNoclip() expectedGen=" .. tostring(expectedGeneration) .. " currentGen=" .. tostring(FarmRunGeneration) .. " running=" .. tostring(AutoFarmRunning))
	expectedGeneration = expectedGeneration or FarmRunGeneration

	if not AutoFarmRunning or expectedGeneration ~= FarmRunGeneration then
		return false
	end

	if FarmNoclipConnection then
		FarmNoclipConnection:Disconnect()
		FarmNoclipConnection = nil
	end

	table.clear(FarmOriginalCollision)

	if not FarmApplyNoclip(expectedGeneration) then
		return false
	end

	FarmNoclipConnection = RunService.Stepped:Connect(function()
		if not AutoFarmRunning
			or expectedGeneration ~= FarmRunGeneration
			or (FarmPaused and not FarmBagLiftInProgress) then
			return
		end

		if FarmUpdateCharacter() then
			FarmApplyNoclip(expectedGeneration)
		end
	end)

	return true
end

local function FarmStopNoclip()
	FarmDiag("FarmStopNoclip() called; hadConnection=" .. tostring(FarmNoclipConnection ~= nil))
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
-- V13.9: multi-floor + clearance validation + stuck recovery
--============================================================

local FARM_RETURN_STAND_OFFSET = 2.90
local FARM_RETURN_CAST_ABOVE = 220
local FARM_RETURN_CAST_DEPTH = 520
local FARM_RETURN_FALLBACK_RADIUS = 420
local FARM_RETURN_FALLBACK_STEP = 14
local FARM_RETURN_FALLBACK_SAMPLES = 32

-- A candidate floor is not accepted unless there is enough room for the rig.
local FARM_RETURN_CLEARANCE_HEIGHT = 7.0
local FARM_RETURN_CLEARANCE_RADIUS = 1.65
local FARM_RETURN_EDGE_SAMPLE_RADIUS = 1.35
local FARM_RETURN_MIN_FLOOR_NORMAL = 0.82

-- If Roblox leaves the humanoid in a broken recovery state, relocate once
-- to another validated point instead of repeatedly forcing GettingUp in place.
local FARM_RETURN_RECOVERY_TIMEOUT = 1.20
local FARM_RETURN_VERIFY_TIMEOUT = 2.25
local FARM_RETURN_RECOVERY_RADIUS = 24
local FARM_RETURN_RECOVERY_STEP = 4
local FARM_RETURN_RECOVERY_SAMPLES = 16

local FarmLastSafeReturnCFrame = nil
local FarmLastSafeReturnAt = 0

local function FarmIsUnsafeReturnPart(part)
    if not part then return true end
    local node = part
    while node and node ~= workspace do
        local name = string.lower(node.Name)
        if string.find(name, "glitchproof", 1, true)
            or string.find(name, "glitch proof", 1, true)
            or string.find(name, "coincontainer", 1, true)
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

local function FarmHasReturnClearance(surfacePosition)
    if not FarmCharacter then return false end

    -- Check a small cylinder-ish footprint around the character. This rejects
    -- walls, pillars, furniture, undersides of stairs, and cramped floor edges.
    local offsets = {
        Vector3.new(0,0,0),
        Vector3.new(FARM_RETURN_CLEARANCE_RADIUS,0,0),
        Vector3.new(-FARM_RETURN_CLEARANCE_RADIUS,0,0),
        Vector3.new(0,0,FARM_RETURN_CLEARANCE_RADIUS),
        Vector3.new(0,0,-FARM_RETURN_CLEARANCE_RADIUS),
    }

    local params = FarmMakeRayParams()

    for _,offset in ipairs(offsets) do
        local origin = surfacePosition + offset + Vector3.new(0,0.20,0)
        local hit = workspace:Raycast(
            origin,
            Vector3.new(0,FARM_RETURN_CLEARANCE_HEIGHT,0),
            params
        )

        if hit and hit.Instance and hit.Instance.CanCollide then
            return false
        end
    end

    return true
end

local function FarmHasFloorSupport(x,z,surfaceY)
    -- Make sure the center and four nearby points belong to approximately the
    -- same walkable level. This avoids returning on a tiny ledge or beside a wall.
    local offsets = {
        Vector2.new(0,0),
        Vector2.new(FARM_RETURN_EDGE_SAMPLE_RADIUS,0),
        Vector2.new(-FARM_RETURN_EDGE_SAMPLE_RADIUS,0),
        Vector2.new(0,FARM_RETURN_EDGE_SAMPLE_RADIUS),
        Vector2.new(0,-FARM_RETURN_EDGE_SAMPLE_RADIUS),
    }

    for _,offset in ipairs(offsets) do
        local params = FarmMakeRayParams()
        local result = workspace:Raycast(
            Vector3.new(x + offset.X, surfaceY + 3.0, z + offset.Y),
            Vector3.new(0,-6.0,0),
            params
        )

        if not result
            or not result.Instance
            or not result.Instance:IsA("BasePart")
            or not result.Instance.CanCollide
            or FarmIsUnsafeReturnPart(result.Instance)
            or result.Normal.Y < FARM_RETURN_MIN_FLOOR_NORMAL
            or math.abs(result.Position.Y - surfaceY) > 1.35 then
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
        local params = FarmMakeRayParams(ignore)
        local result = workspace:Raycast(
            Vector3.new(x,originY,z),
            Vector3.new(0,-depth,0),
            params
        )

        if not result then return nil end

        if FarmValidateReturnResult(result) then
            return result
        end

        -- Continue downward. This is important on Hotel and other multi-floor
        -- maps: if one floor/roof is unsuitable, a valid lower floor can still
        -- be selected rather than abandoning the whole X/Z column.
        table.insert(ignore,result.Instance)
    end

    return nil
end

local function FarmRememberSafePosition()
    if not FarmUpdateCharacter() or not FarmHumanoid or FarmHumanoid.Health <= 0 then
        return
    end

    local params = FarmMakeRayParams()
    local result = workspace:Raycast(
        FarmHRP.Position + Vector3.new(0,2,0),
        Vector3.new(0,-10,0),
        params
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

local function FarmFindNearestReturnSurface(current, maxRadius, step, samples, rejectPosition)
    maxRadius = maxRadius or FARM_RETURN_FALLBACK_RADIUS
    step = step or FARM_RETURN_FALLBACK_STEP
    samples = samples or FARM_RETURN_FALLBACK_SAMPLES

    local castY = current.Y + FARM_RETURN_CAST_ABOVE

    local direct = FarmRaycastSafeSurface(
        current.X,current.Z,castY,FARM_RETURN_CAST_DEPTH
    )
    if direct and (not rejectPosition or (direct.Position-rejectPosition).Magnitude >= 3.0) then
        return direct
    end

    for radius = step,maxRadius,step do
        local ringBest,ringBestScore = nil,math.huge

        for i = 0,samples-1 do
            local angle = (math.pi*2*i)/samples
            local x = current.X + math.cos(angle)*radius
            local z = current.Z + math.sin(angle)*radius
            local result = FarmRaycastSafeSurface(x,z,castY,FARM_RETURN_CAST_DEPTH)

            if result then
                local p = result.Position
                if not rejectPosition or (p-rejectPosition).Magnitude >= 3.0 then
                    local dx,dz = p.X-current.X,p.Z-current.Z
                    local score = math.sqrt(dx*dx+dz*dz)
                    if score < ringBestScore then
                        ringBest,ringBestScore = result,score
                    end
                end
            end
        end

        if ringBest then return ringBest end
    end

    return nil
end

local function FarmCFrameFromSurface(result,yaw)
    local p = result.Position
    return CFrame.new(p.X,p.Y+FARM_RETURN_STAND_OFFSET,p.Z)
        * CFrame.Angles(0,yaw,0)
end

local function FarmReturnToSafePosition()
    if not FarmUpdateCharacter() then return false end

    local _,currentYaw,_ = FarmHRP.CFrame:ToOrientation()
    local target = nil

    -- Revalidate the remembered point before using it. A saved point is useful,
    -- but it must not bypass the new wall/ceiling/floor checks.
    if FarmLastSafeReturnCFrame then
        local saved = FarmLastSafeReturnCFrame.Position
        local result = FarmRaycastSafeSurface(
            saved.X,
            saved.Z,
            saved.Y + 8,
            16
        )

        if result and math.abs((result.Position.Y + FARM_RETURN_STAND_OFFSET) - saved.Y) <= 2.0 then
            target = FarmCFrameFromSurface(result,currentYaw)
        end
    end

    if not target then
        local result = FarmFindNearestReturnSurface(FarmHRP.Position)
        if not result then return false end
        target = FarmCFrameFromSurface(result,currentYaw)
    end

    local function placeAt(cf)
        if not FarmUpdateCharacter() then return false end

        pcall(function()
            FarmHumanoid.Sit = false
            FarmHumanoid.PlatformStand = false
            FarmHumanoid.AutoRotate = false
            FarmHRP.AssemblyLinearVelocity = Vector3.zero
            FarmHRP.AssemblyAngularVelocity = Vector3.zero
            FarmHRP.CFrame = cf
            FarmHRP.AssemblyLinearVelocity = Vector3.zero
            FarmHRP.AssemblyAngularVelocity = Vector3.zero
        end)

        return true
    end

    -- Short controlled placement.
    for _ = 1,6 do
        if not placeAt(target) then return false end
        RunService.Heartbeat:Wait()
    end

    pcall(function()
        FarmHumanoid.Sit = false
        FarmHumanoid.PlatformStand = false
        FarmHumanoid:ChangeState(Enum.HumanoidStateType.Running)
    end)

    local verifyStarted = os.clock()
    local badStarted = nil
    local stableFrames = 0
    local recoveredOnce = false

    while os.clock()-verifyStarted < FARM_RETURN_VERIFY_TIMEOUT do
        RunService.Heartbeat:Wait()
        if not FarmUpdateCharacter() then return false end

        local state = FarmHumanoid:GetState()
        local upDot = FarmHRP.CFrame.UpVector:Dot(Vector3.yAxis)
        local displacement = (FarmHRP.Position-target.Position).Magnitude

        local recoveryState =
            state == Enum.HumanoidStateType.FallingDown
            or state == Enum.HumanoidStateType.GettingUp
            or state == Enum.HumanoidStateType.Ragdoll
            or state == Enum.HumanoidStateType.PlatformStanding

        local physicallyBad = upDot < 0.80 or displacement > 5.5

        if recoveryState or physicallyBad then
            stableFrames = 0
            badStarted = badStarted or os.clock()

            -- Do NOT spam GettingUp. The old version could remain trapped there
            -- for many seconds. After the timeout, choose another validated floor.
            if os.clock()-badStarted >= FARM_RETURN_RECOVERY_TIMEOUT then
                if recoveredOnce then
                    -- Last controlled attempt at the already validated target.
                    placeAt(target)
                    pcall(function()
                        FarmHumanoid:ChangeState(Enum.HumanoidStateType.Running)
                    end)
                    badStarted = os.clock()
                else
                    recoveredOnce = true

                    local badSurface = Vector3.new(
                        target.Position.X,
                        target.Position.Y-FARM_RETURN_STAND_OFFSET,
                        target.Position.Z
                    )

                    local alternate = FarmFindNearestReturnSurface(
                        FarmHRP.Position,
                        FARM_RETURN_RECOVERY_RADIUS,
                        FARM_RETURN_RECOVERY_STEP,
                        FARM_RETURN_RECOVERY_SAMPLES,
                        badSurface
                    )

                    if alternate then
                        target = FarmCFrameFromSurface(alternate,currentYaw)
                    end

                    for _ = 1,6 do
                        placeAt(target)
                        RunService.Heartbeat:Wait()
                    end

                    pcall(function()
                        FarmHumanoid.Sit = false
                        FarmHumanoid.PlatformStand = false
                        FarmHumanoid:ChangeState(Enum.HumanoidStateType.Running)
                    end)

                    badStarted = nil
                end
            end
        else
            badStarted = nil
            stableFrames += 1
            if stableFrames >= 7 then
                break
            end
        end
    end

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

local function FarmWake(expectedGeneration)
	FarmDiag("FarmWake() expectedGen=" .. tostring(expectedGeneration) .. " currentGen=" .. tostring(FarmRunGeneration) .. " running=" .. tostring(AutoFarmRunning) .. " flag=" .. tostring(Flags.AutoFarm))
	expectedGeneration = expectedGeneration or FarmRunGeneration

	if not AutoFarmRunning or expectedGeneration ~= FarmRunGeneration then
		return false
	end

	FarmPaused = false
	FarmPauseReason = nil

	if not FarmUpdateCharacter() then
		return false
	end

	FarmApplyHRPSize()

	if not FarmEnsureMovement(expectedGeneration) then
		return false
	end

	if not FarmNoclipConnection then
		if not FarmStartNoclip(expectedGeneration) then
			return false
		end
	end

	return AutoFarmRunning and expectedGeneration == FarmRunGeneration
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
	local actionGeneration = FarmRunGeneration

	task.spawn(function()
		local function actionStillValid()
			return AutoFarmRunning
				and actionGeneration == FarmRunGeneration
				and Flags.AutoFarm
				and FarmBagFull
		end

		if not actionStillValid() then
			FarmAfterBagActionBusy = false
			return
		end

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

		if actionStillValid()
			and Flags.FlingMurdererAfterBagFull
			and MM2.Functions.ExecuteYeet then

			local murderer = FarmFindMurderer()

			if murderer then
				pcall(
					MM2.Functions.ExecuteYeet,
					murderer
				)
			end
		end

		if actionStillValid()
			and Flags.ResetCharacterAfterBagFull
			and not killAllRan then

			task.wait(0.15)
			if not actionStillValid() then
				FarmAfterBagActionBusy = false
				return
			end

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
	local bagGeneration = FarmRunGeneration

	if not AutoFarmRunning
		or not Flags.AutoFarm
		or not FarmBagFull
		or FarmBagLiftInProgress
		or FarmBagLiftDone then
		return
	end

	FarmBagLiftInProgress = true
	FarmPaused = true
	FarmPauseReason = "BAG FULL"

	FarmReleaseTarget()
	FarmRunAfterBagFullActions()


	task.spawn(function()
		if not AutoFarmRunning or bagGeneration ~= FarmRunGeneration or not FarmUpdateCharacter() or not FarmEnsureMovement(bagGeneration) then
			FarmStopNoclip()
			FarmDestroyMovement()
			FarmRestoreHRPSize()

			FarmBagLiftInProgress = false
			FarmBagLiftDone = true
			return
		end

		if not FarmNoclipConnection then
			FarmStartNoclip(bagGeneration)
		end

		local liftTarget =
			FarmHRP.Position + Vector3.new(0,FARM_BAG_LIFT_HEIGHT,0)

		FarmPositionAlign.Position = liftTarget
		local started = os.clock()

		while AutoFarmRunning
			and bagGeneration == FarmRunGeneration
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

		if bagGeneration == FarmRunGeneration then
			FarmStopNoclip()
			FarmDestroyMovement()
			FarmRestoreHRPSize()

			FarmBagLiftInProgress = false
			FarmBagLiftDone = true
		end
	end)
end

--============================================================
-- Main Farm Loop
--============================================================

local function FarmLoop(runGeneration)
	FarmLoopGeneration = runGeneration
	while AutoFarmRunning and MM2.Running and runGeneration == FarmRunGeneration do
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

			if not FarmWake(runGeneration) then
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

	-- Only the current generation may perform global cleanup. An old loop can
	-- finish after OFF or after a new run has started; it must not touch either.
	if runGeneration == FarmRunGeneration then
		AutoFarmRunning = false
		FarmPaused = false
		FarmPauseReason = nil
		FarmBagLiftInProgress = false

		FarmReleaseTarget()
		FarmStopNoclip()
		FarmDestroyMovement()
		FarmRestoreHRPSize()
	end

	if FarmLoopGeneration == runGeneration then
		FarmLoopGeneration = nil
	end
end

--============================================================
-- Public AutoFarm Functions
--============================================================

function MM2.Functions.StartAutoFarm()
	FarmDiag("===== StartAutoFarm CALLED =====")
	FarmDiagState("BEFORE START")
	if AutoFarmRunning then
		return
	end

	FarmRunGeneration += 1
	local runGeneration = FarmRunGeneration
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

	FarmDiagState("AFTER START gen=" .. tostring(runGeneration))
	task.spawn(function()
		FarmLoop(runGeneration)
	end)
end

function MM2.Functions.StopAutoFarm()
	FarmDiag("===== StopAutoFarm CALLED =====")
	FarmDiagState("BEFORE STOP")
	-- Invalidate every task belonging to the current run before touching the
	-- character. This is the key race-condition fix.
	FarmRunGeneration += 1
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
	FarmStopNoclip()
	FarmDestroyMovement()
	FarmRestoreHRPSize()

	-- Give any already-resumed stale iteration one scheduler turn to observe
	-- the invalid generation. Then clean once more before relocating.
	task.wait()
	FarmStopNoclip()
	FarmDestroyMovement()
	FarmRestoreHRPSize()

	-- Relocate only after all farm forces and noclip writers are dead.
	-- A shutdown fence runs alongside return verification so any stale callback
	-- that somehow resumes during these scheduler turns is immediately neutralized.
	local stopGeneration = FarmRunGeneration
	local shutdownFenceAlive = true

	task.spawn(function()
		local deadline = os.clock() + 3.0
		while shutdownFenceAlive
			and not AutoFarmRunning
			and FarmRunGeneration == stopGeneration
			and os.clock() < deadline do

			FarmStopNoclip()
			FarmDestroyMovement()
			FarmRestoreHRPSize()
			RunService.Heartbeat:Wait()
		end
	end)

	FarmReturnToSafePosition()
	shutdownFenceAlive = false
	FarmStopNoclip()
	FarmDestroyMovement()
	FarmRestoreHRPSize()

	if FarmUpdateCharacter() then
		pcall(function()
			FarmHumanoid.Sit = false
			FarmHumanoid.PlatformStand = false
			FarmHRP.AssemblyLinearVelocity = Vector3.zero
			FarmHRP.AssemblyAngularVelocity = Vector3.zero
		end)
	end

	table.clear(FarmCoinSkipUntil)
	FarmDiagState("AFTER STOP")
end

function MM2.Functions.UpdateAutoFarm()
	-- Diagnostic: only record UpdateAutoFarm when its state actually changes.
	-- This avoids the old 0.1-second log spam while preserving meaningful transitions.
	if FarmDiagLastUpdateFlag ~= Flags.AutoFarm or FarmDiagLastUpdateRunning ~= AutoFarmRunning then
		FarmDiag("UpdateAutoFarm STATE flag=" .. tostring(Flags.AutoFarm) .. " running=" .. tostring(AutoFarmRunning))
		FarmDiagLastUpdateFlag = Flags.AutoFarm
		FarmDiagLastUpdateRunning = AutoFarmRunning
	end
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

			if AutoFarmRunning and Flags.AutoFarm and FarmBagFull then
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
			if AutoFarmRunning and Flags.AutoFarm then
				FarmPause("INTERMISSION")
			end
		end)
	)
end

--============================================================
-- Embedded Diagnostic GUI
-- One-run tester: ON / OFF / CLEAR / COPY
--============================================================

task.spawn(function()
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local old = PlayerGui:FindFirstChild("AutoFarmV13_12Diagnostic")
    if old then old:Destroy() end
    local oldPrevious = PlayerGui:FindFirstChild("AutoFarmV13_11Diagnostic")
    if oldPrevious then oldPrevious:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "AutoFarmV13_12Diagnostic"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999999
    gui.Parent = PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 330, 0, 225)
    frame.Position = UDim2.new(0.5, -165, 0.12, 0)
    frame.Active = true
    frame.Draggable = true
    frame.Parent = gui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -12, 0, 30)
    title.Position = UDim2.new(0, 6, 0, 4)
    title.BackgroundTransparency = 1
    title.Text = "AutoFarm LIVE DIAGNOSTIC"
    title.TextScaled = true
    title.Parent = frame

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -12, 0, 42)
    status.Position = UDim2.new(0, 6, 0, 35)
    status.BackgroundTransparency = 1
    status.TextWrapped = true
    status.TextScaled = true
    status.Text = "PASSIVE WATCHER: use the REAL AutoFarm toggle. CLEAR/COPY only."
    status.Parent = frame

    local function button(text, x, y, w)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, w, 0, 36)
        b.Position = UDim2.new(0, x, 0, y)
        b.Text = text
        b.TextScaled = true
        b.Parent = frame
        return b
    end

    local clearButton = button("CLEAR LOGS", 10, 82, 150)
    local copyButton = button("COPY LOGS", 170, 82, 150)

    clearButton.MouseButton1Click:Connect(function()
        table.clear(FarmDiagLogs)
        FarmDiagMarkTime = nil
        FarmDiagLastUpdateFlag = Flags.AutoFarm
        FarmDiagLastUpdateRunning = AutoFarmRunning
        FarmDiag("LOGS CLEARED - NEW TEST STARTED")
        FarmDiagState("CLEAR BASELINE")
        status.Text = "Logs cleared. Use the REAL AutoFarm toggle; this diagnostic only watches."
    end)

    copyButton.MouseButton1Click:Connect(function()
        FarmDiagState("COPY CURRENT STATE")
        local text = table.concat(FarmDiagLogs, "\n")
        if setclipboard then
            local ok = pcall(setclipboard, text)
            status.Text = ok and "Logs copied. Send them to me." or "Clipboard call failed; logs remain in console."
        elseif toclipboard then
            local ok = pcall(toclipboard, text)
            status.Text = ok and "Logs copied. Send them to me." or "Clipboard call failed; logs remain in console."
        else
            status.Text = "Clipboard unsupported; logs are in console."
        end
    end)


    FarmDiag("EMBEDDED AUTOFARM DIAGNOSTIC GUI LOADED")
    FarmDiagState("INITIAL STATE")
end)

-- Passive watcher: this is intentionally independent from the farm lifecycle.
task.spawn(function()
    while MM2.Running do
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local nc, total, movers = 0, 0, 0
        if character then
            for _,obj in ipairs(character:GetDescendants()) do
                if obj:IsA("BasePart") then
                    total += 1
                    if not obj.CanCollide then nc += 1 end
                end
                if obj.Name == "FarmAlign" or obj.Name == "FarmUprightAlign" or obj.Name == "FarmAttachmentV13_3" then
                    movers += 1
                end
            end
        end

        local collide = root and root.CanCollide or nil
        if FarmDiagLastCanCollide ~= nil and collide ~= FarmDiagLastCanCollide then
            FarmDiag("WATCH Root.CanCollide " .. tostring(FarmDiagLastCanCollide) .. " -> " .. tostring(collide))
            FarmDiagState("COLLISION CHANGE")
        end
        if FarmDiagLastNC ~= nil and nc ~= FarmDiagLastNC then
            FarmDiag("WATCH NonCollidable " .. tostring(FarmDiagLastNC) .. " -> " .. tostring(nc) .. "/" .. tostring(total))
        end
        if FarmDiagLastMoverCount ~= nil and movers ~= FarmDiagLastMoverCount then
            FarmDiag("WATCH Farm mover instances " .. tostring(FarmDiagLastMoverCount) .. " -> " .. tostring(movers))
            FarmDiagState("MOVER CHANGE")
        end
        if FarmDiagLastGeneration ~= FarmRunGeneration then
            FarmDiag("WATCH Generation " .. tostring(FarmDiagLastGeneration) .. " -> " .. tostring(FarmRunGeneration))
        end
        if FarmDiagLastRunning ~= AutoFarmRunning then
            FarmDiag("WATCH AutoFarmRunning " .. tostring(FarmDiagLastRunning) .. " -> " .. tostring(AutoFarmRunning))
        end

        FarmDiagLastCanCollide = collide
        FarmDiagLastNC = nc
        FarmDiagLastMoverCount = movers
        FarmDiagLastGeneration = FarmRunGeneration
        FarmDiagLastRunning = AutoFarmRunning

        if FarmDiagMarkTime and os.clock() - FarmDiagMarkTime <= 5.2 then
            local vel = root and root.AssemblyLinearVelocity or Vector3.zero
            local hs = Vector3.new(vel.X,0,vel.Z).Magnitude
            if hs >= 4 or movers > 0 or nc == total and total > 0 then
                FarmDiag(string.format("POST-OFF WATCH +%.3fs speed=%.2f movers=%d NC=%d/%d flag=%s running=%s gen=%s",
                    os.clock()-FarmDiagMarkTime, hs, movers, nc, total,
                    tostring(Flags.AutoFarm), tostring(AutoFarmRunning), tostring(FarmRunGeneration)))
            end
        end

        task.wait(0.10)
    end
end)

return MM2
