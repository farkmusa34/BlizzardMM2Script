--============================================================
-- MM2 V8.8.4 - AutoFarm.lua
-- Coin Farm V13.4 predictive vertical pickup + GUI Diagnostic
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

UI.AddSection(UI.AutoFarmPage,"Auto Farm","Coin Farm V13.4 predictive vertical pickup")

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

-- V13.4 predictive staging state.
local FarmPredictiveStageActive = false
local FarmPredictiveStageXZ = nil
local FarmPredictiveStageStartedAt = 0

local FarmCoinSkipUntil =
	setmetatable({}, {__mode = "k"})

--============================================================
-- V13.3 Diagnostic State
--============================================================

local FarmDiagLogs = {}
local FarmDiagMaxLogs = 500
local FarmDiagStartedAt = os.clock()

local FarmDiagTargetStartedAt = nil
local FarmDiagLastTrackAt = 0
local FarmDiagLastState = "idle"
local FarmDiagLastY = nil
local FarmDiagLastVerticalDirection = 0
local FarmDiagVerticalReversals = 0

local FarmDiagGui = nil
local FarmDiagWindow = nil
local FarmDiagLogLabel = nil
local FarmDiagScroll = nil
local FarmDiagStatus = nil

local function FarmDiagRefresh()
	if not FarmDiagLogLabel then
		return
	end

	FarmDiagLogLabel.Text = table.concat(FarmDiagLogs,"\n")

	task.defer(function()
		if not FarmDiagScroll or not FarmDiagLogLabel then
			return
		end
		FarmDiagScroll.CanvasPosition =
			Vector2.new(
				0,
				math.max(
					0,
					FarmDiagLogLabel.AbsoluteSize.Y - FarmDiagScroll.AbsoluteSize.Y
				)
			)
	end)
end

local function FarmDiagAdd(text)
	local elapsed = os.clock()-FarmDiagStartedAt
	table.insert(
		FarmDiagLogs,
		string.format("[%.3f] %s",elapsed,tostring(text))
	)

	while #FarmDiagLogs > FarmDiagMaxLogs do
		table.remove(FarmDiagLogs,1)
	end

	FarmDiagRefresh()
end

local function FarmDiagClear()
	table.clear(FarmDiagLogs)
	FarmDiagStartedAt = os.clock()
	FarmDiagTargetStartedAt = nil
	FarmDiagLastTrackAt = 0
	FarmDiagLastState = "idle"
	FarmDiagLastY = nil
	FarmDiagLastVerticalDirection = 0
	FarmDiagVerticalReversals = 0
	FarmDiagAdd("Logs cleared")
end

local function FarmDiagCopy()
	local text = table.concat(FarmDiagLogs,"\n")
	local clipboard = setclipboard or toclipboard

	if clipboard then
		local ok = pcall(clipboard,text)
		if ok then
			if FarmDiagStatus then
				FarmDiagStatus.Text = "Status: Logs copied"
			end
			return
		end
	end

	if FarmDiagStatus then
		FarmDiagStatus.Text = "Status: Clipboard unavailable"
	end
end

local function FarmDiagTargetStart(coinPos)
	if not FarmHRP or not coinPos then
		return
	end

	FarmDiagTargetStartedAt = os.clock()
	FarmDiagLastTrackAt = 0
	FarmDiagLastState = FarmRearmState
	FarmDiagLastY = FarmHRP.Position.Y
	FarmDiagLastVerticalDirection = 0
	FarmDiagVerticalReversals = 0

	local dx = FarmHRP.Position.X-coinPos.X
	local dz = FarmHRP.Position.Z-coinPos.Z
	local horizontal = math.sqrt(dx*dx + dz*dz)
	local targetY = coinPos.Y+FARM_COIN_Y_OFFSET
	local yGap = math.abs(FarmHRP.Position.Y-targetY)

	FarmDiagAdd(
		string.format(
			"TARGET | StartH=%.3f | StartYGap=%.3f | HRPY=%.3f | CoinY=%.3f | TargetY=%.3f",
			horizontal,
			yGap,
			FarmHRP.Position.Y,
			coinPos.Y,
			targetY
		)
	)
end

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

		FarmDiagAdd(
			string.format(
				"PREDICTIVE STAGE | H=%.3f | Rise=%.3f | StageH=%.3f",
				horizontal,
				upwardRise,
				math.sqrt(
					(stageX-coinPos.X)^2
					+
					(stageZ-coinPos.Z)^2
				)
			)
		)
	else
		FarmPositionAlign.Position = FarmGetCoinTarget(coinPos)
	end

	FarmDiagTargetStart(coinPos)

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

		FarmDiagAdd(
			string.format(
				"PREDICTIVE APPROACH | YErr=%.3f | Timeout=%s",
				yError,
				tostring(timedOut)
			)
		)

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

local function FarmDiagTrack(coin,coinPos)
	if not FarmHRP or not coin or not coinPos then
		return
	end

	local now = os.clock()
	local currentY = FarmHRP.Position.Y

	if FarmDiagLastY then
		local deltaY = currentY-FarmDiagLastY
		local direction = 0

		if deltaY > 0.08 then
			direction = 1
		elseif deltaY < -0.08 then
			direction = -1
		end

		if direction ~= 0
			and FarmDiagLastVerticalDirection ~= 0
			and direction ~= FarmDiagLastVerticalDirection then

			FarmDiagVerticalReversals += 1

			FarmDiagAdd(
				string.format(
					"VERTICAL REVERSAL #%d | %s | HRPY=%.3f",
					FarmDiagVerticalReversals,
					direction == 1 and "UP" or "DOWN",
					currentY
				)
			)
		end

		if direction ~= 0 then
			FarmDiagLastVerticalDirection = direction
		end
	end

	FarmDiagLastY = currentY

	local horizontal = FarmHorizontalDistanceToCoin(coinPos)
	local verticalBelow = FarmVerticalBelowCoin(coinPos)
	local targetY = coinPos.Y+FARM_COIN_Y_OFFSET
	local yError = math.abs(FarmHRP.Position.Y-targetY)

	if FarmDiagLastState ~= FarmRearmState then
		FarmDiagAdd(
			string.format(
				"STATE | %s -> %s | Attempt=%d",
				tostring(FarmDiagLastState),
				tostring(FarmRearmState),
				FarmRearmAttempts
			)
		)
		FarmDiagLastState = FarmRearmState
	end

	local interval = (horizontal <= 2 or yError <= 2) and 0.12 or 0.35
	if now-FarmDiagLastTrackAt < interval then
		return
	end
	FarmDiagLastTrackAt = now

	FarmDiagAdd(
		string.format(
			"TRACK | H=%.3f | VBelow=%.3f | YErr=%.3f | HRPY=%.3f | CoinY=%.3f | State=%s | Attempt=%d | Touch=%s | Reversals=%d",
			horizontal,
			verticalBelow,
			yError,
			FarmHRP.Position.Y,
			coinPos.Y,
			tostring(FarmRearmState),
			FarmRearmAttempts,
			FarmGetTouchObject(coin) and "YES" or "NO",
			FarmDiagVerticalReversals
		)
	)
end

local function FarmBeginRearm()
	FarmRearmAttempts += 1
	FarmRearmState = "exit"
	FarmRearmStateStartedAt = os.clock()
	FarmRearmCloseStartedAt = nil

	FarmDiagAdd(
		string.format(
			"REARM START | Attempt=%d | Reversals=%d",
			FarmRearmAttempts,
			FarmDiagVerticalReversals
		)
	)
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

		FarmDiagAdd(
			string.format(
				"FAILED | Attempts=%d | Reversals=%d | Skip=%.2fs",
				FarmRearmAttempts,
				FarmDiagVerticalReversals,
				FARM_REARM_SKIP_TIME
			)
		)

		FarmReleaseTarget()
		return
	end
end

--============================================================
-- Safe Position
--============================================================

local function FarmReturnToSafePosition()
	if not FarmSafeReturnCFrame or not FarmUpdateCharacter() then
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

local function FarmMoveUnderground()
	if not FarmUpdateCharacter() or not FarmEnsureMovement() then
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

		if not FarmUpdateCharacter() or not FarmPositionAlign then
			break
		end

		FarmPositionAlign.Position = target

		if (FarmHRP.Position-target).Magnitude
			<= FARM_BAG_LIFT_REACHED_DISTANCE then
			return true
		end

		if os.clock()-started >= FARM_UNDERGROUND_TIMEOUT then
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
			and not Flags.StayUndergroundAfterBagFull
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

	if Flags.StayUndergroundAfterBagFull then
		task.spawn(function()
			FarmMoveUnderground()

			FarmBagLiftInProgress = false
			FarmBagLiftDone = true

			while AutoFarmRunning
				and MM2.Running
				and FarmBagFull
				and Flags.StayUndergroundAfterBagFull do

				if FarmUpdateCharacter() and FarmPositionAlign then
					local floorY = FarmFindGroundY()
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

		FarmDiagTrack(
			FarmCurrentCoin,
			coinPos
		)

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

	if FarmDiagStatus then
		FarmDiagStatus.Text = "Status: Farm stopped"
	end
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
	FarmResetPredictiveStage()
	table.clear(FarmCoinSkipUntil)
	FarmUpdateCharacter()
	FarmApplyHRPSize()

	if FarmDiagStatus then
		FarmDiagStatus.Text = "Status: Farming"
	end

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

	if FarmDiagStatus then
		FarmDiagStatus.Text = "Status: Farm stopped"
	end
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
		if on and UI.SetToggleState then
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
		if on and UI.SetToggleState then
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
	CoinRateValue.Text = "0 coins/min"
end

UI.CreateActionFeature(
	UI.AutoFarmPage,
	"Reset Stats",
	"Resets coin rate statistics",
	FarmResetStats
)

MM2.Track(
	RunService.Heartbeat:Connect(function()
		if not FarmStatsStartedAt or FarmStatsCoins <= 0 then
			CoinRateValue.Text = "0 coins/min"
			return
		end

		local elapsed = math.max(os.clock()-FarmStatsStartedAt,1)
		local rate = FarmStatsCoins/(elapsed/60)

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
						FarmDiagAdd(
							string.format(
								"COLLECTED | Bag=%d/%d | Attempt=%d | Reversals=%d | Time=%.3f",
								current,
								FarmBagMax,
								FarmRearmAttempts,
								FarmDiagVerticalReversals,
								FarmDiagTargetStartedAt
									and (os.clock()-FarmDiagTargetStartedAt)
									or 0
							)
						)

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
	FarmSafeReturnCFrame = nil

	table.clear(FarmCoinSkipUntil)
	FarmReleaseTarget()

	FarmDiagAdd("ROUND RESET")
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

--============================================================
-- Auto Farm Diagnostic GUI
--============================================================

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local OldDiag = PlayerGui:FindFirstChild("MM2_AutoFarmDiagnostic")
if OldDiag then
	OldDiag:Destroy()
end

FarmDiagGui = Instance.new("ScreenGui")
FarmDiagGui.Name = "MM2_AutoFarmDiagnostic"
FarmDiagGui.ResetOnSpawn = false
FarmDiagGui.DisplayOrder = 100
FarmDiagGui.Parent = PlayerGui

FarmDiagWindow = Instance.new("Frame")
FarmDiagWindow.Size = UDim2.fromOffset(500,310)
FarmDiagWindow.Position = UDim2.new(0.5,-250,0.5,-155)
FarmDiagWindow.BackgroundColor3 = UI.COLORS.Background
FarmDiagWindow.BorderSizePixel = 0
FarmDiagWindow.Parent = FarmDiagGui

local WindowCorner = Instance.new("UICorner")
WindowCorner.CornerRadius = UDim.new(0,14)
WindowCorner.Parent = FarmDiagWindow

local WindowStroke = Instance.new("UIStroke")
WindowStroke.Color = UI.COLORS.Stroke
WindowStroke.Transparency = 0.25
WindowStroke.Parent = FarmDiagWindow

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1,0,0,52)
Header.BackgroundTransparency = 1
Header.Active = true
Header.Parent = FarmDiagWindow

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,-28,0,20)
Title.Position = UDim2.fromOffset(14,7)
Title.BackgroundTransparency = 1
Title.Text = "Auto Farm V13.4 Diagnostic"
Title.TextColor3 = UI.COLORS.Text
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

FarmDiagStatus = Instance.new("TextLabel")
FarmDiagStatus.Size = UDim2.new(1,-28,0,18)
FarmDiagStatus.Position = UDim2.fromOffset(14,28)
FarmDiagStatus.BackgroundTransparency = 1
FarmDiagStatus.Text = "Status: Ready"
FarmDiagStatus.TextColor3 = UI.COLORS.Muted
FarmDiagStatus.TextSize = 10
FarmDiagStatus.Font = Enum.Font.Gotham
FarmDiagStatus.TextXAlignment = Enum.TextXAlignment.Left
FarmDiagStatus.Parent = Header

local ButtonRow = Instance.new("Frame")
ButtonRow.Size = UDim2.new(1,-24,0,34)
ButtonRow.Position = UDim2.fromOffset(12,55)
ButtonRow.BackgroundTransparency = 1
ButtonRow.Parent = FarmDiagWindow

local ButtonLayout = Instance.new("UIListLayout")
ButtonLayout.FillDirection = Enum.FillDirection.Horizontal
ButtonLayout.Padding = UDim.new(0,8)
ButtonLayout.Parent = ButtonRow

local function CreateDiagButton(text,callback)
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(0,153,1,0)
	Button.BackgroundColor3 = UI.COLORS.Card
	Button.BorderSizePixel = 0
	Button.AutoButtonColor = false
	Button.Text = text
	Button.TextColor3 = UI.COLORS.Text
	Button.TextSize = 10
	Button.Font = Enum.Font.GothamBold
	Button.Parent = ButtonRow

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0,8)
	Corner.Parent = Button

	Button.MouseButton1Click:Connect(function()
		Button.BackgroundColor3 = UI.COLORS.Accent

		task.delay(0.10,function()
			if Button.Parent then
				Button.BackgroundColor3 = UI.COLORS.Card
			end
		end)

		callback()
	end)

	return Button
end

CreateDiagButton(
	"START FARM",
	function()
		if AutoFarmRunning then
			FarmDiagStatus.Text = "Status: Already farming"
			FarmDiagAdd("Start pressed while already farming")
			return
		end

		Flags.AutoFarm = true

		if UI.SetToggleState then
			UI.SetToggleState(
				"AutoFarm",
				true,
				false
			)
		end

		MM2.Functions.StartAutoFarm()
		FarmDiagStatus.Text = "Status: Farming"
		FarmDiagAdd("AUTO FARM STARTED")
	end
)

CreateDiagButton(
	"CLEAR LOGS",
	function()
		FarmDiagClear()
		FarmDiagStatus.Text = "Status: Logs cleared"
	end
)

CreateDiagButton(
	"COPY LOGS",
	function()
		FarmDiagCopy()
	end
)

FarmDiagScroll = Instance.new("ScrollingFrame")
FarmDiagScroll.Size = UDim2.new(1,-24,1,-106)
FarmDiagScroll.Position = UDim2.fromOffset(12,96)
FarmDiagScroll.BackgroundColor3 = UI.COLORS.Card
FarmDiagScroll.BorderSizePixel = 0
FarmDiagScroll.ScrollBarThickness = 5
FarmDiagScroll.ScrollBarImageColor3 = UI.COLORS.Muted
FarmDiagScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
FarmDiagScroll.CanvasSize = UDim2.new()
FarmDiagScroll.Parent = FarmDiagWindow

local LogCorner = Instance.new("UICorner")
LogCorner.CornerRadius = UDim.new(0,9)
LogCorner.Parent = FarmDiagScroll

FarmDiagLogLabel = Instance.new("TextLabel")
FarmDiagLogLabel.Size = UDim2.new(1,-18,0,0)
FarmDiagLogLabel.Position = UDim2.fromOffset(9,8)
FarmDiagLogLabel.AutomaticSize = Enum.AutomaticSize.Y
FarmDiagLogLabel.BackgroundTransparency = 1
FarmDiagLogLabel.Text = ""
FarmDiagLogLabel.TextColor3 = UI.COLORS.Text
FarmDiagLogLabel.TextSize = 10
FarmDiagLogLabel.Font = Enum.Font.Code
FarmDiagLogLabel.TextWrapped = false
FarmDiagLogLabel.TextXAlignment = Enum.TextXAlignment.Left
FarmDiagLogLabel.TextYAlignment = Enum.TextYAlignment.Top
FarmDiagLogLabel.Parent = FarmDiagScroll

local UIS = MM2.Services.UserInputService
local dragging = false
local dragInput = nil
local dragStart = nil
local startingPosition = nil

Header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		dragging = true
		dragStart = input.Position
		startingPosition = FarmDiagWindow.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

Header.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UIS.InputChanged:Connect(function(input)
	if not dragging or input ~= dragInput then
		return
	end

	local delta = input.Position-dragStart

	FarmDiagWindow.Position =
		UDim2.new(
			startingPosition.X.Scale,
			startingPosition.X.Offset + delta.X,
			startingPosition.Y.Scale,
			startingPosition.Y.Offset + delta.Y
		)
end)

FarmDiagAdd("Diagnostic ready")
FarmDiagAdd("Press START FARM and wait for a bad pickup")

return MM2
