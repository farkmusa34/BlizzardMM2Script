-- Blizzard MM2 - Focused Shoot Movement Diagnostic
-- Load AFTER Combat.lua.
-- Purpose:
--   1) Observe the Murderer's movement immediately around a Legit SHOOT press.
--   2) Compare a small set of horizontal lead candidates.
--   3) Highlight turns/stops that make one-frame velocity prediction unreliable.
--
-- This does NOT replace Combat.lua's shot logic. It wraps ShootMurdererLegit
-- and leaves the production shot unchanged.

local MM2 = getgenv and getgenv().MM2_V85_SPLIT or _G.MM2_V85_SPLIT
assert(MM2 and MM2.Functions and MM2.Functions.ShootMurdererLegit, "Load Combat.lua first")

local Players = MM2.Services.Players
local RunService = MM2.Services.RunService or game:GetService("RunService")
local LP = MM2.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

local GUI_NAME = "BlizzardFocusedShootDiagnostic"
local old = PG:FindFirstChild(GUI_NAME)
if old then old:Destroy() end

-- Restore the true production function if an older diagnostic is already wrapped.
if MM2.Functions._FocusedShootDiagOriginal then
	MM2.Functions.ShootMurdererLegit = MM2.Functions._FocusedShootDiagOriginal
elseif MM2.Functions._ShootDiagOriginal then
	MM2.Functions.ShootMurdererLegit = MM2.Functions._ShootDiagOriginal
end

local Original = MM2.Functions.ShootMurdererLegit
MM2.Functions._FocusedShootDiagOriginal = Original

local LEADS = {0, 0.03, 0.06, 0.09}
local PRE_SAMPLE_SECONDS = 0.18
local POST_SAMPLE_SECONDS = 0.20
local HISTORY_LIMIT = 80

local logs = {}
local shotNumber = 0
local history = {}

local function H(v)
	return Vector3.new(v.X, 0, v.Z)
end

local function V(v)
	return typeof(v) == "Vector3"
		and string.format("(%.2f, %.2f, %.2f)", v.X, v.Y, v.Z)
		or "nil"
end

local function torso(character)
	return character and (
		character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
		or character:FindFirstChild("HumanoidRootPart")
	)
end

local function live(player)
	local character = player and player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return player ~= LP and humanoid and humanoid.Health > 0
end

local function murderer()
	for _,player in ipairs(Players:GetPlayers()) do
		if live(player) then
			local ok,role = pcall(function()
				return MM2.GetPlayerRole(player)
			end)

			if (ok and role == "Murderer")
				or (
					MM2.State
					and MM2.State.ServerRolesCache
					and MM2.State.ServerRolesCache[player.Name] == "Murderer"
				)
			then
				return player
			end
		end
	end
end

local function pushHistory()
	local player = murderer()
	local part = player and torso(player.Character)
	if not part then return end

	history[#history + 1] = {
		t = os.clock(),
		player = player,
		character = player.Character,
		pos = part.Position,
		vel = part.AssemblyLinearVelocity,
	}

	while #history > HISTORY_LIMIT do
		table.remove(history, 1)
	end
end

RunService.Heartbeat:Connect(pushHistory)

local function angleBetween(a,b)
	a,b = H(a),H(b)
	if a.Magnitude < 0.25 or b.Magnitude < 0.25 then
		return 0
	end
	local dot = math.clamp(a.Unit:Dot(b.Unit), -1, 1)
	return math.deg(math.acos(dot))
end

local function getRecentSamples(player, seconds)
	local now = os.clock()
	local out = {}

	for i = #history,1,-1 do
		local s = history[i]
		if now - s.t > seconds then break end
		if s.player == player and s.character == player.Character then
			table.insert(out, 1, s)
		end
	end

	return out
end

local function summarizeMovement(player, currentPos, currentVel)
	local samples = getRecentSamples(player, PRE_SAMPLE_SECONDS)
	if #samples < 2 then
		return "History=insufficient", H(currentVel), 0, 0
	end

	local first = samples[1]
	local last = samples[#samples]
	local dt = math.max(last.t - first.t, 1/240)
	local observed = H(last.pos - first.pos) / dt
	local currentH = H(currentVel)
	local turn = angleBetween(observed, currentH)
	local speedDelta = currentH.Magnitude - observed.Magnitude

	local state
	if currentH.Magnitude < 1.5 and observed.Magnitude < 2.5 then
		state = "STATIONARY"
	elseif currentH.Magnitude < observed.Magnitude * 0.55 and observed.Magnitude > 5 then
		state = "SLOWING/STOPPING"
	elseif turn >= 35 then
		state = "TURNING"
	else
		state = "STABLE"
	end

	return string.format(
		"State=%s Hist=%.0fms ObsSpeed=%.2f NowSpeed=%.2f Turn=%.1fdeg dSpeed=%+.2f",
		state, dt*1000, observed.Magnitude, currentH.Magnitude, turn, speedDelta
	), observed, turn, speedDelta
end

--============================================================
-- SMALL GUI
--============================================================

local gui = Instance.new("ScreenGui")
gui.Name = GUI_NAME
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999
gui.Parent = PG

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(390, 300)
main.Position = UDim2.new(0,16,.15,0)
main.BackgroundColor3 = Color3.fromRGB(18,18,22)
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui
Instance.new("UICorner",main).CornerRadius = UDim.new(0,12)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(70,165,255)
stroke.Transparency = .2
stroke.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-16,0,30)
title.Position = UDim2.fromOffset(8,4)
title.BackgroundTransparency = 1
title.Text = "FOCUSED SHOOT DIAGNOSTIC"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1,-16,0,28)
status.Position = UDim2.fromOffset(8,34)
status.BackgroundTransparency = 1
status.Text = "Waiting for Legit SHOOT..."
status.TextColor3 = Color3.fromRGB(210,210,220)
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = main

local box = Instance.new("TextLabel")
box.Size = UDim2.new(1,-16,1,-106)
box.Position = UDim2.fromOffset(8,64)
box.BackgroundColor3 = Color3.fromRGB(9,9,12)
box.BorderSizePixel = 0
box.TextColor3 = Color3.fromRGB(225,225,230)
box.Font = Enum.Font.Code
box.TextSize = 9
box.TextXAlignment = Enum.TextXAlignment.Left
box.TextYAlignment = Enum.TextYAlignment.Top
box.TextWrapped = false
box.Text = "Loaded."
box.Parent = main
Instance.new("UICorner",box).CornerRadius = UDim.new(0,8)

local function makeButton(text,x)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(179,28)
	b.Position = UDim2.new(0,x,1,-34)
	b.BackgroundColor3 = Color3.fromRGB(35,35,43)
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.new(1,1,1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 11
	b.Parent = main
	Instance.new("UICorner",b).CornerRadius = UDim.new(0,8)
	return b
end

local copy = makeButton("COPY LOGS",8)
local clear = makeButton("CLEAR",203)

local function refresh()
	local visible = {}
	for i = math.max(1,#logs-15),#logs do
		visible[#visible+1] = logs[i]
	end
	box.Text = table.concat(visible,"\n")
end

local function log(text)
	text = tostring(text)
	logs[#logs+1] = text
	print("[FOCUSED SHOOT] "..text)
	refresh()
end

copy.MouseButton1Click:Connect(function()
	if setclipboard then
		pcall(setclipboard,table.concat(logs,"\n"))
		status.Text = "Copied."
	else
		status.Text = "Clipboard unavailable."
	end
end)

clear.MouseButton1Click:Connect(function()
	table.clear(logs)
	refresh()
	status.Text = "Cleared."
end)

local dragging,startInput,startPosition
main.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1
	then
		dragging = true
		startInput = input.Position
		startPosition = main.Position
	end
end)

main.InputChanged:Connect(function(input)
	if dragging and (
		input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseMovement
	) then
		local d = input.Position - startInput
		main.Position = UDim2.new(
			startPosition.X.Scale,startPosition.X.Offset+d.X,
			startPosition.Y.Scale,startPosition.Y.Offset+d.Y
		)
	end
end)

main.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1
	then
		dragging = false
	end
end)

--============================================================
-- POST-SHOT FOCUSED MONITOR
--============================================================

local function monitor(player, character, basePos, baseVel, fireReturnTime)
	task.spawn(function()
		local candidates = {}
		for _,lead in ipairs(LEADS) do
			candidates[lead] = basePos + H(baseVel) * lead
		end

		local checkpoints = {0.033,0.066,0.10,0.15,POST_SAMPLE_SECONDS}

		for _,cp in ipairs(checkpoints) do
			local remaining = cp - (os.clock() - fireReturnTime)
			if remaining > 0 then task.wait(remaining) end

			local c = player.Character
			local humanoid = c and c:FindFirstChildOfClass("Humanoid")
			local part = torso(c)

			if c ~= character or not humanoid or not part then
				log(string.format("+%dms target changed/missing",cp*1000))
				break
			end

			local bestLead,bestError = nil,math.huge
			local errors = {}

			for _,lead in ipairs(LEADS) do
				local candidate = candidates[lead]
				local error = (
					Vector3.new(candidate.X,part.Position.Y,candidate.Z)
					- part.Position
				).Magnitude

				errors[#errors+1] = string.format("%d=%.2f",lead*1000,error)

				if error < bestError then
					bestLead,bestError = lead,error
				end
			end

			log(string.format(
				"+%dms H=%.0f Spd=%.1f Y=%.1f Best=%dms Err=%.2f | %s",
				cp*1000,
				humanoid.Health,
				H(part.AssemblyLinearVelocity).Magnitude,
				part.AssemblyLinearVelocity.Y,
				(bestLead or 0)*1000,
				bestError,
				table.concat(errors," ")
			))
		end

		log("------------------------------------------------------------")
	end)
end

--============================================================
-- WRAP LEGIT SHOOT
--============================================================

MM2.Functions.ShootMurdererLegit = function(...)
	shotNumber += 1

	local player = murderer()
	local part = player and torso(player.Character)

	log("============================================================")
	log("SHOT #"..shotNumber)

	if not player or not part then
		log("No live Murderer at press.")
		local success,message = Original(...)
		log("Result="..tostring(success).." / "..tostring(message))
		return success,message
	end

	local pressPos = part.Position
	local pressVel = part.AssemblyLinearVelocity
	local movementSummary,observedVel = summarizeMovement(player,pressPos,pressVel)

	log("Target="..player.Name)
	log("Press Pos="..V(pressPos))
	log("Press Vel="..V(pressVel).." XZ="..string.format("%.2f",H(pressVel).Magnitude).." Y="..string.format("%.2f",pressVel.Y))
	log(movementSummary)
	log("ObservedVel="..V(observedVel))

	for _,lead in ipairs(LEADS) do
		local instantCandidate = pressPos + H(pressVel)*lead
		local historyCandidate = pressPos + H(observedVel)*lead
		log(string.format(
			"%dms Instant=%s History=%s",
			lead*1000,
			V(instantCandidate),
			V(historyCandidate)
		))
	end

	local t0 = os.clock()
	local success,message = Original(...)
	local t1 = os.clock()

	log(string.format(
		"Call=%.2fms Result=%s / %s",
		(t1-t0)*1000,
		tostring(success),
		tostring(message)
	))

	status.Text = string.format(
		"Shot #%d: %s / %s",
		shotNumber,
		tostring(success),
		tostring(message)
	)

	if success and player.Character == player.Character then
		local fresh = torso(player.Character)
		if fresh then
			local freshPos = fresh.Position
			local freshVel = fresh.AssemblyLinearVelocity

			log("Return Pos="..V(freshPos))
			log("Return Vel="..V(freshVel).." XZ="..string.format("%.2f",H(freshVel).Magnitude).." Y="..string.format("%.2f",freshVel.Y))
			log(string.format(
				"Direction change Press->Return=%.1fdeg",
				angleBetween(pressVel,freshVel)
			))

			monitor(player,player.Character,freshPos,freshVel,t1)
		end
	else
		log("No post-shot monitor.")
		log("------------------------------------------------------------")
	end

	return success,message
end

log("FOCUSED SHOOT DIAGNOSTIC LOADED")
log("Tests Legit SHOOT only; production shot logic is unchanged.")
log("Best tests: running straight, sharp turn, stopping, jumping.")
log("Keep Auto Shoot/TriggerBot and Aim Lock OFF while testing.")
