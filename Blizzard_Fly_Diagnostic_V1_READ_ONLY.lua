--============================================================
-- BLIZZARD FLY DIAGNOSTIC V1
-- MODE = READ ONLY
--
-- Purpose:
-- Observe an existing fly implementation without changing it.
-- This script does NOT create LinearVelocity/BodyVelocity,
-- AlignOrientation/BodyGyro, change Humanoid states, CFrame,
-- velocities, or movement properties.
--
-- Controls:
-- START      begin/restart capture
-- COPY       copy current log
-- CLEAR      clear current log
-- STOP       stop capture (UI stays open)
--============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local LP = Players.LocalPlayer

local CAPTURE_INTERVAL = 0.05
local captureOn = false
local captureStart = 0
local lastSample = 0
local connections = {}
local logs = {}

local lastState = nil
local lastHRP = nil
local lastPos = nil
local lastVelocity = nil

local function now()
	return captureOn and (os.clock() - captureStart) or 0
end

local function fmtVec(v)
	if not v then return "NONE" end
	return string.format("(%.3f, %.3f, %.3f)", v.X, v.Y, v.Z)
end

local function log(s)
	local line = string.format("[%.5f] %s", now(), tostring(s))
	table.insert(logs, line)
	print(line)
end

local function getCharacter()
	local char = LP.Character
	if not char then return nil,nil,nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	return char,hum,hrp
end

local function getMM2()
	local ok, value = pcall(function()
		if getgenv then
			return getgenv().MM2_V85_SPLIT
		end
		return _G.MM2_V85_SPLIT
	end)
	if ok then return value end
	return nil
end

local function getFlyFlag()
	local mm2 = getMM2()
	if mm2 and mm2.Flags then
		return mm2.Flags.Fly
	end
	return nil
end

local function getFlySpeed()
	local mm2 = getMM2()
	if mm2 and mm2.PlayerSettings then
		return mm2.PlayerSettings.FlySpeed
	end
	return nil
end

local function inputSummary()
	local keys = {}
	if UIS.KeyboardEnabled then
		if UIS:IsKeyDown(Enum.KeyCode.W) then table.insert(keys,"W") end
		if UIS:IsKeyDown(Enum.KeyCode.A) then table.insert(keys,"A") end
		if UIS:IsKeyDown(Enum.KeyCode.S) then table.insert(keys,"S") end
		if UIS:IsKeyDown(Enum.KeyCode.D) then table.insert(keys,"D") end
		if UIS:IsKeyDown(Enum.KeyCode.Space) then table.insert(keys,"SPACE") end
		if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then table.insert(keys,"CTRL") end
		if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then table.insert(keys,"SHIFT") end
	end
	return #keys > 0 and table.concat(keys,"+") or "NONE"
end

local function listMovers(hrp)
	if not hrp then return "NONE" end
	local found = {}
	for _,obj in ipairs(hrp:GetDescendants()) do
		if obj:IsA("LinearVelocity")
			or obj:IsA("VectorForce")
			or obj:IsA("BodyVelocity")
			or obj:IsA("BodyForce")
			or obj:IsA("AlignOrientation")
			or obj:IsA("BodyGyro")
			or obj:IsA("Attachment")
		then
			local text = obj.ClassName .. ":" .. obj.Name
			if obj:IsA("LinearVelocity") then
				text ..= " VV=" .. fmtVec(obj.VectorVelocity)
				text ..= " MaxForce=" .. tostring(obj.MaxForce)
			elseif obj:IsA("BodyVelocity") then
				text ..= " Vel=" .. fmtVec(obj.Velocity)
				text ..= " MaxForce=" .. fmtVec(obj.MaxForce)
			elseif obj:IsA("AlignOrientation") then
				text ..= " Resp=" .. tostring(obj.Responsiveness)
				text ..= " Rigid=" .. tostring(obj.RigidityEnabled)
			end
			table.insert(found,text)
		end
	end
	return #found > 0 and table.concat(found," | ") or "NONE"
end

local function snapshot(label)
	if not captureOn then return end

	local char,hum,hrp = getCharacter()
	log("========== "..label.." ==========")

	if not char or not hum or not hrp then
		log("Character/Humanoid/HRP unavailable")
		return
	end

	local fly = getFlyFlag()
	local speed = getFlySpeed()
	local cam = workspace.CurrentCamera

	log("FlyFlag="..tostring(fly).." FlySpeed="..tostring(speed))
	log("State="..tostring(hum:GetState()))
	log("Position="..fmtVec(hrp.Position))
	log("HRPVelocity="..fmtVec(hrp.AssemblyLinearVelocity)
		.." Speed="..string.format("%.3f",hrp.AssemblyLinearVelocity.Magnitude))
	log("HRPAngular="..fmtVec(hrp.AssemblyAngularVelocity)
		.." AngularSpeed="..string.format("%.3f",hrp.AssemblyAngularVelocity.Magnitude))
	log("MoveDirection="..fmtVec(hum.MoveDirection)
		.." MoveMagnitude="..string.format("%.3f",hum.MoveDirection.Magnitude))
	log("FloorMaterial="..tostring(hum.FloorMaterial))
	log("PlatformStand="..tostring(hum.PlatformStand)
		.." Sit="..tostring(hum.Sit)
		.." AutoRotate="..tostring(hum.AutoRotate))
	log("Input="..inputSummary()
		.." Touch="..tostring(UIS.TouchEnabled)
		.." Keyboard="..tostring(UIS.KeyboardEnabled))

	if cam then
		log("CameraLook="..fmtVec(cam.CFrame.LookVector))
		log("CameraRight="..fmtVec(cam.CFrame.RightVector))
	end

	log("Movers="..listMovers(hrp))
end

local function disconnectWatchers()
	for _,c in ipairs(connections) do
		pcall(function() c:Disconnect() end)
	end
	table.clear(connections)
	lastState = nil
	lastHRP = nil
end

local function attachWatchers()
	disconnectWatchers()

	local _,hum,hrp = getCharacter()
	if not hum or not hrp then return end

	lastState = hum:GetState()
	lastHRP = hrp

	table.insert(connections, hum.StateChanged:Connect(function(old,new)
		if captureOn then
			log("STATE CHANGE "..tostring(old).." -> "..tostring(new))
		end
		lastState = new
	end))

	table.insert(connections, hrp.ChildAdded:Connect(function(obj)
		if captureOn then
			log("HRP CHILD ADDED "..obj.ClassName..":"..obj.Name)
			if obj:IsA("LinearVelocity")
				or obj:IsA("VectorForce")
				or obj:IsA("BodyVelocity")
				or obj:IsA("BodyForce")
				or obj:IsA("AlignOrientation")
				or obj:IsA("BodyGyro")
				or obj:IsA("Attachment")
			then
				snapshot("FLY OBJECT ADDED")
			end
		end
	end))

	table.insert(connections, hrp.ChildRemoved:Connect(function(obj)
		if captureOn then
			log("HRP CHILD REMOVED "..obj.ClassName..":"..obj.Name)
		end
	end))
end

local function sample()
	if not captureOn then return end
	if os.clock() - lastSample < CAPTURE_INTERVAL then return end
	lastSample = os.clock()

	local char,hum,hrp = getCharacter()
	if not char or not hum or not hrp then
		log("SAMPLE character unavailable")
		return
	end

	if hrp ~= lastHRP then
		log("HRP CHANGED - reattaching observers")
		attachWatchers()
	end

	local p = hrp.Position
	local v = hrp.AssemblyLinearVelocity
	local d = lastPos and (p - lastPos) or Vector3.zero
	local dv = lastVelocity and (v - lastVelocity) or Vector3.zero
	local fly = getFlyFlag()

	log(
		"SAMPLE"
		.." Fly="..tostring(fly)
		.." State="..tostring(hum:GetState())
		.." Pos="..fmtVec(p)
		.." dPos="..fmtVec(d)
		.." Vel="..fmtVec(v)
		.." dVel="..fmtVec(dv)
		.." Move="..fmtVec(hum.MoveDirection)
		.." Input="..inputSummary()
		.." Movers={"..listMovers(hrp).."}"
	)

	lastPos = p
	lastVelocity = v
end

--============================================================
-- SMALL DIAGNOSTIC UI
--============================================================

local old = game:GetService("CoreGui"):FindFirstChild("BlizzardFlyDiagnosticV1")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "BlizzardFlyDiagnosticV1"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = game:GetService("CoreGui")

local frame = Instance.new("Frame")
frame.Name = "Panel"
frame.Size = UDim2.fromOffset(370,155)
frame.Position = UDim2.new(0.5,-185,0,80)
frame.BackgroundColor3 = Color3.fromRGB(20,20,25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,10)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-20,0,36)
title.Position = UDim2.fromOffset(10,5)
title.BackgroundTransparency = 1
title.Text = "BLIZZARD FLY DIAGNOSTIC V1 — READ ONLY"
title.TextColor3 = Color3.new(1,1,1)
title.TextSize = 15
title.Font = Enum.Font.GothamBold
title.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1,-20,0,25)
status.Position = UDim2.fromOffset(10,40)
status.BackgroundTransparency = 1
status.Text = "STOPPED"
status.TextColor3 = Color3.new(1,1,1)
status.TextSize = 13
status.Font = Enum.Font.Gotham
status.Parent = frame

local function makeButton(text,x)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(78,42)
	b.Position = UDim2.fromOffset(x,85)
	b.BackgroundColor3 = Color3.fromRGB(35,35,43)
	b.TextColor3 = Color3.new(1,1,1)
	b.Text = text
	b.TextSize = 13
	b.Font = Enum.Font.GothamBold
	b.Parent = frame
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0,8)
	c.Parent = b
	return b
end

local startBtn = makeButton("START",10)
local copyBtn  = makeButton("COPY",100)
local clearBtn = makeButton("CLEAR",190)
local stopBtn  = makeButton("STOP",280)

local function startCapture()
	captureOn = true
	captureStart = os.clock()
	lastSample = 0
	lastPos = nil
	lastVelocity = nil
	table.clear(logs)

	log("BLIZZARD FLY DIAGNOSTIC V1")
	log("MODE=READ ONLY")
	log("========== CAPTURE START ==========")
	attachWatchers()
	snapshot("START SNAPSHOT")
	status.Text = "CAPTURING — test fly now"
end

local function stopCapture()
	if not captureOn then
		status.Text = "STOPPED"
		return
	end
	log("========== CAPTURE STOP ==========")
	snapshot("STOP SNAPSHOT")
	captureOn = false
	disconnectWatchers()
	status.Text = "STOPPED — COPY to export"
end

startBtn.MouseButton1Click:Connect(startCapture)

copyBtn.MouseButton1Click:Connect(function()
	if captureOn then
		snapshot("COPY PRESSED")
	end
	local text = table.concat(logs,"\n") .. "\n\nEND V1"
	if setclipboard then
		setclipboard(text)
		status.Text = "COPIED "..tostring(#logs).." lines"
	elseif toclipboard then
		toclipboard(text)
		status.Text = "COPIED "..tostring(#logs).." lines"
	else
		status.Text = "Clipboard function unavailable"
		print(text)
	end
end)

clearBtn.MouseButton1Click:Connect(function()
	table.clear(logs)
	if captureOn then
		captureStart = os.clock()
		lastSample = 0
		lastPos = nil
		lastVelocity = nil
		log("BLIZZARD FLY DIAGNOSTIC V1")
		log("MODE=READ ONLY")
		log("========== LOG CLEARED / CAPTURE CONTINUES ==========")
	end
	status.Text = captureOn and "CLEARED — still capturing" or "CLEARED"
end)

stopBtn.MouseButton1Click:Connect(stopCapture)

RunService.RenderStepped:Connect(sample)

LP.CharacterAdded:Connect(function()
	if captureOn then
		log("CHARACTER ADDED")
		task.delay(0.3,function()
			if captureOn then
				attachWatchers()
				snapshot("RESPAWN SNAPSHOT")
			end
		end)
	end
end)

print("BLIZZARD FLY DIAGNOSTIC V1 loaded — MODE=READ ONLY")
