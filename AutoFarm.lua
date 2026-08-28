--============================================================
-- MM2 V8.7.1 - AutoFarm.lua
-- Coin Farm V12.1 contact sweep.
-- V8.7.1: smooth +6 stud bag-full lift + Anti Disconnect.
--============================================================

local MM2 = getgenv and getgenv().MM2_V85_SPLIT or _G.MM2_V85_SPLIT
assert(MM2 and MM2.UI and MM2.UI.AutoFarmPage, "Load Shared.lua + UI.lua first")

local RunService = MM2.Services.RunService
local LocalPlayer = MM2.LocalPlayer
local Flags = MM2.Flags
local UI = MM2.UI
local VirtualUser = game:GetService("VirtualUser")

Flags.AntiDisconnect = Flags.AntiDisconnect == true

UI.AddSection(UI.AutoFarmPage, "Auto Farm", "Coin Farm V12.1 contact-sweep controls")
UI.CreateToggle(UI.AutoFarmPage, "Auto Farm Coins", "Automatically farms coins for you", "AutoFarm")

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

local FARM_MAX_VELOCITY = 25
local FARM_RESPONSIVENESS = 18
local FARM_MAX_FORCE = 500000
local FARM_UPRIGHT_RESPONSIVENESS = 12
local FARM_UPRIGHT_MAX_TORQUE = 500000
local FARM_UPRIGHT_MAX_ANGULAR = 10
local FARM_FAR_Y_OFFSET = -5.25
local FARM_CONTACT_START_DISTANCE = 6.5
local FARM_SWEEP_START_OFFSET = -5.25
local FARM_SWEEP_END_OFFSET = 1.75
local FARM_SWEEP_RATE = 6.5
local FARM_SWEEP_RETRY_DELAY = 0.08
local FARM_MAX_VALID_COLLECTION_DISTANCE = 3.25
local FARM_MAX_TARGET_DISTANCE = 500
local FARM_LOOP_DELAY = 0.02
local FARM_MAX_START_DISTANCE = 500

local FARM_BAG_LIFT_HEIGHT = 6
local FARM_BAG_LIFT_REACHED_DISTANCE = 0.75
local FARM_BAG_LIFT_TIMEOUT = 2.5

local AutoFarmRunning = false
local FarmPaused = false
local FarmPauseReason = nil

local FarmBagCount = 0
local FarmBagMax = 40
local FarmBagFull = false
local FarmBagLiftInProgress = false

local FarmCharacter = nil
local FarmHumanoid = nil
local FarmHRP = nil
local FarmAttachment = nil
local FarmPositionAlign = nil
local FarmUprightAlign = nil
local FarmCurrentCoin = nil
local FarmCurrentTouch = nil
local FarmSweepOffset = FARM_SWEEP_START_OFFSET
local FarmSweepActive = false
local FarmSweepAttempts = 0
local FarmNoclipConnection = nil
local FarmOriginalCollision = {}

-- Kept only for manual-stop safety.
local FarmSafeReturnCFrame = nil

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

local function FarmIsCoinServer(obj)
	return obj and obj.Name == "Coin_Server"
		and (obj:IsA("BasePart") or obj:IsA("Model"))
end

local function FarmGetPosition(obj)
	if not obj then return nil end
	if obj:IsA("BasePart") then return obj.Position end
	if obj:IsA("Model") then
		local ok,pivot = pcall(function() return obj:GetPivot() end)
		if ok then return pivot.Position end
	end
	return nil
end

local function FarmGetTouchObject(coin)
	if not coin then return nil end
	local direct = coin:FindFirstChild("TouchInterest")
	if direct then return direct end

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

local function FarmFindNearestCoin()
	if not FarmHRP then return nil,math.huge end
	local best,bestDistance = nil,math.huge

	for _,obj in ipairs(workspace:GetDescendants()) do
		if FarmValidCoin(obj) then
			local pos = FarmGetPosition(obj)
			if pos then
				local distance = (FarmHRP.Position-pos).Magnitude
				if distance < bestDistance then
					best,bestDistance = obj,distance
				end
			end
		end
	end
	return best,bestDistance
end

local function FarmDestroyMovement()
	if FarmPositionAlign then pcall(function() FarmPositionAlign:Destroy() end) end
	if FarmUprightAlign then pcall(function() FarmUprightAlign:Destroy() end) end
	if FarmAttachment then pcall(function() FarmAttachment:Destroy() end) end
	FarmPositionAlign,FarmUprightAlign,FarmAttachment = nil,nil,nil
end

local function FarmEnsureMovement()
	if not FarmUpdateCharacter() then return false end

	if FarmAttachment
		and FarmAttachment.Parent == FarmHRP
		and FarmPositionAlign
		and FarmPositionAlign.Parent == FarmHRP
		and FarmUprightAlign
		and FarmUprightAlign.Parent == FarmHRP
	then
		return true
	end

	FarmDestroyMovement()

	FarmAttachment = Instance.new("Attachment")
	FarmAttachment.Name = "FarmAttachmentV12_2"
	FarmAttachment.Parent = FarmHRP

	FarmPositionAlign = Instance.new("AlignPosition")
	FarmPositionAlign.Name = "FarmAlign"
	FarmPositionAlign.Mode = Enum.PositionAlignmentMode.OneAttachment
	FarmPositionAlign.Attachment0 = FarmAttachment
	FarmPositionAlign.MaxVelocity = FARM_MAX_VELOCITY
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

local function FarmApplyNoclip()
	if not FarmCharacter or not FarmHumanoid then return end

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
	if state == Enum.HumanoidStateType.Climbing or state == Enum.HumanoidStateType.Seated then
		FarmHumanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	end
end

local function FarmStartNoclip()
	if FarmNoclipConnection then FarmNoclipConnection:Disconnect() end
	FarmNoclipConnection = nil
	table.clear(FarmOriginalCollision)
	FarmApplyNoclip()

	FarmNoclipConnection = RunService.Stepped:Connect(function()
		if not AutoFarmRunning or (FarmPaused and not FarmBagLiftInProgress) then return end
		if FarmUpdateCharacter() then FarmApplyNoclip() end
	end)
end

local function FarmStopNoclip()
	if FarmNoclipConnection then
		FarmNoclipConnection:Disconnect()
		FarmNoclipConnection = nil
	end

	for part,oldState in pairs(FarmOriginalCollision) do
		if part and part.Parent then
			pcall(function() part.CanCollide = oldState end)
		end
	end
	table.clear(FarmOriginalCollision)
end

local function FarmReleaseTarget()
	FarmCurrentCoin = nil
	FarmCurrentTouch = nil
	FarmSweepOffset = FARM_SWEEP_START_OFFSET
	FarmSweepActive = false
	FarmSweepAttempts = 0
end

local function FarmReturnToSafePosition()
	if not FarmSafeReturnCFrame or not FarmUpdateCharacter() then return end
	pcall(function()
		FarmHRP.AssemblyLinearVelocity = Vector3.zero
		FarmHRP.AssemblyAngularVelocity = Vector3.zero
		FarmHRP.CFrame = FarmSafeReturnCFrame
		FarmHRP.AssemblyLinearVelocity = Vector3.zero
		FarmHRP.AssemblyAngularVelocity = Vector3.zero
	end)
end

local function FarmPause(reason)
	reason = reason or "PAUSED"
	if reason == "BAG FULL" then return end
	if FarmPaused and FarmPauseReason == reason then return end

	FarmPaused = true
	FarmPauseReason = reason
	FarmReleaseTarget()
	FarmStopNoclip()
	FarmDestroyMovement()
end

local function FarmWake()
	FarmPaused = false
	FarmPauseReason = nil
	if not FarmUpdateCharacter() then return false end

	if not FarmSafeReturnCFrame then
		FarmSafeReturnCFrame = FarmHRP.CFrame
	end

	if not FarmEnsureMovement() then return false end
	if not FarmNoclipConnection then FarmStartNoclip() end
	return true
end

local function FarmSelectTarget(coin)
	if not FarmValidCoin(coin) then return false end
	if not FarmEnsureMovement() then return false end

	local coinPos = FarmGetPosition(coin)
	if not coinPos then return false end

	FarmCurrentCoin = coin
	FarmCurrentTouch = FarmGetTouchObject(coin)
	FarmSweepOffset = FARM_SWEEP_START_OFFSET
	FarmSweepActive = false
	FarmSweepAttempts = 0
	FarmPositionAlign.Position = coinPos + Vector3.new(0,FARM_FAR_Y_OFFSET,0)
	return true
end

local function FarmResetSweep()
	FarmSweepOffset = FARM_SWEEP_START_OFFSET
	FarmSweepAttempts += 1
	task.wait(FARM_SWEEP_RETRY_DELAY)
end

local function FarmUpdateSweep(coinPos,dt)
	FarmSweepActive = true
	FarmSweepOffset += FARM_SWEEP_RATE * dt
	if FarmSweepOffset > FARM_SWEEP_END_OFFSET then FarmResetSweep() end

	local target = coinPos + Vector3.new(0,FarmSweepOffset,0)
	FarmPositionAlign.Position = target
	return target
end

local function FarmCheckCollection(coin,coinPos)
	local oldTouch = FarmCurrentTouch
	local newTouch = FarmGetTouchObject(coin)
	FarmCurrentTouch = newTouch

	if oldTouch and not newTouch then
		local distance = FarmHRP and (FarmHRP.Position-coinPos).Magnitude or math.huge
		if distance <= FARM_MAX_VALID_COLLECTION_DISTANCE then return true else return "invalid" end
	end
	return false
end

local function FarmBeginBagFullLift()
	if FarmBagLiftInProgress then return end
	FarmBagLiftInProgress = true
	FarmPaused = true
	FarmPauseReason = "BAG FULL"
	FarmReleaseTarget()

	task.spawn(function()
		if not FarmUpdateCharacter() or not FarmEnsureMovement() then
			FarmStopNoclip()
			FarmDestroyMovement()
			FarmBagLiftInProgress = false
			return
		end

		if not FarmNoclipConnection then FarmStartNoclip() end

		-- Capture exactly once, then let the existing AlignPosition move smoothly.
		local liftTarget = FarmHRP.Position + Vector3.new(0,FARM_BAG_LIFT_HEIGHT,0)
		FarmPositionAlign.Position = liftTarget

		local started = os.clock()
		while AutoFarmRunning and MM2.Running and FarmBagFull do
			if not FarmUpdateCharacter() or not FarmPositionAlign then break end
			if (FarmHRP.Position-liftTarget).Magnitude <= FARM_BAG_LIFT_REACHED_DISTANCE then break end
			if os.clock()-started >= FARM_BAG_LIFT_TIMEOUT then break end
			task.wait(0.03)
		end

		FarmStopNoclip()
		FarmDestroyMovement()
		FarmBagLiftInProgress = false
	end)
end

local function FarmLoop()
	local lastLoop = os.clock()

	while AutoFarmRunning and MM2.Running do
		if not Flags.AutoFarm then break end

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
			FarmBeginBagFullLift()
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

		if not FarmCurrentCoin then continue end

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

		local collection = FarmCheckCollection(FarmCurrentCoin,coinPos)
		if collection == true or collection == "invalid" then
			FarmReleaseTarget()
			continue
		end

		local now = os.clock()
		local dt = math.clamp(now-lastLoop,0,0.05)
		lastLoop = now

		if distance > FARM_CONTACT_START_DISTANCE then
			FarmSweepActive = false
			FarmSweepOffset = FARM_SWEEP_START_OFFSET
			FarmPositionAlign.Position = coinPos + Vector3.new(0,FARM_FAR_Y_OFFSET,0)
		else
			FarmUpdateSweep(coinPos,dt)
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
end

function MM2.Functions.StartAutoFarm()
	if AutoFarmRunning then return end
	AutoFarmRunning = true
	FarmPaused = false
	FarmPauseReason = nil
	FarmBagLiftInProgress = false
	FarmSafeReturnCFrame = nil
	FarmCurrentCoin = nil
	FarmCurrentTouch = nil
	FarmSweepOffset = FARM_SWEEP_START_OFFSET
	FarmSweepActive = false
	FarmSweepAttempts = 0
	FarmUpdateCharacter()
	task.spawn(FarmLoop)
end

function MM2.Functions.StopAutoFarm()
	AutoFarmRunning = false
	FarmPaused = false
	FarmPauseReason = nil
	FarmBagLiftInProgress = false

	-- Manual stop retains the old emergency return behavior.
	FarmReturnToSafePosition()
	FarmReleaseTarget()
	FarmStopNoclip()
	FarmDestroyMovement()
	FarmSafeReturnCFrame = nil
end

function MM2.Functions.UpdateAutoFarm()
	if Flags.AutoFarm then
		if not AutoFarmRunning then MM2.Functions.StartAutoFarm() end
	elseif AutoFarmRunning then
		MM2.Functions.StopAutoFarm()
	end
end

local ReplicatedStorage = MM2.Services.ReplicatedStorage
local Track = MM2.Track

local FarmGameplayRemotes = ReplicatedStorage:FindFirstChild("Remotes")
	and ReplicatedStorage.Remotes:FindFirstChild("Gameplay")

local FarmCoinCollected = FarmGameplayRemotes and FarmGameplayRemotes:FindFirstChild("CoinCollected")
local FarmRoundStart = FarmGameplayRemotes and FarmGameplayRemotes:FindFirstChild("RoundStart")
local FarmCoinsStarted = FarmGameplayRemotes and FarmGameplayRemotes:FindFirstChild("CoinsStarted")
local FarmVictoryScreen = FarmGameplayRemotes and FarmGameplayRemotes:FindFirstChild("VictoryScreen")

if FarmCoinCollected and FarmCoinCollected:IsA("RemoteEvent") then
	Track(FarmCoinCollected.OnClientEvent:Connect(function(...)
		local args = {...}
		local current = tonumber(args[2])
		local maximum = tonumber(args[3])
		if maximum and maximum > 0 then FarmBagMax = maximum end
		if current then FarmBagCount = current end
		FarmBagFull = FarmBagCount >= FarmBagMax

		if Flags.AutoFarm and FarmBagFull then
			FarmBeginBagFullLift()
		end
	end))
end

local function FarmResetBag()
	FarmBagCount = 0
	FarmBagFull = false
	FarmPaused = false
	FarmPauseReason = nil
	FarmBagLiftInProgress = false
	FarmSafeReturnCFrame = nil
end

if FarmRoundStart and FarmRoundStart:IsA("RemoteEvent") then
	Track(FarmRoundStart.OnClientEvent:Connect(FarmResetBag))
end

if FarmCoinsStarted and FarmCoinsStarted:IsA("RemoteEvent") then
	Track(FarmCoinsStarted.OnClientEvent:Connect(FarmResetBag))
end

if FarmVictoryScreen and FarmVictoryScreen:IsA("RemoteEvent") then
	Track(FarmVictoryScreen.OnClientEvent:Connect(function()
		if Flags.AutoFarm then FarmPause("INTERMISSION") end
	end))
end

return MM2
