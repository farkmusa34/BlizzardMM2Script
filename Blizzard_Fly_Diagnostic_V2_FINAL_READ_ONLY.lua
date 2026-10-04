--============================================================
-- BLIZZARD FLY DIAGNOSTIC V2 FINAL
-- MODE = READ ONLY
--
-- Final formula/teardown diagnostic.
-- Reads existing fly objects and character/camera state only.
-- Does NOT create or modify movers, CFrames, velocity, humanoid
-- states, PlatformStand, AutoRotate, or movement.
--============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local LP = Players.LocalPlayer
local CAPTURE_INTERVAL = 0.05
local POST_MOVER_REMOVAL_SECONDS = 1.0

local captureOn = false
local captureStart = 0
local lastSample = 0
local connections = {}
local logs = {}

local lastHRP = nil
local lastPos = nil
local lastVelocity = nil
local lastPlatformStand = nil
local lastAutoRotate = nil
local lastMoverSignature = nil
local postRemovalUntil = nil

local function now()
	return captureOn and (os.clock() - captureStart) or 0
end

local function fmtVec(v)
	if not v then return "NONE" end
	return string.format("(%.3f, %.3f, %.3f)", v.X, v.Y, v.Z)
end

local function fmtCF(cf)
	if not cf then return "NONE" end
	local p = cf.Position
	local l = cf.LookVector
	return string.format(
		"Pos%s Look%s",
		fmtVec(p), fmtVec(l)
	)
end

local function log(s)
	local line = string.format("[%.5f] %s", now(), tostring(s))
	table.insert(logs, line)
	print(line)
end

local function getCharacter()
	local char = LP.Character
	if not char then return nil,nil,nil end
	return char, char:FindFirstChildOfClass("Humanoid"), char:FindFirstChild("HumanoidRootPart")
end

local function getMM2()
	local ok, value = pcall(function()
		if getgenv then return getgenv().MM2_V85_SPLIT end
		return _G.MM2_V85_SPLIT
	end)
	return ok and value or nil
end

local function getFlyFlag()
	local mm2 = getMM2()
	return mm2 and mm2.Flags and mm2.Flags.Fly or nil
end

local function getFlySpeed()
	local mm2 = getMM2()
	return mm2 and mm2.PlayerSettings and mm2.PlayerSettings.FlySpeed or nil
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

local function findFlyObjects(hrp)
	local bv, bg, lv, ao
	if not hrp then return nil,nil,nil,nil end
	for _,obj in ipairs(hrp:GetDescendants()) do
		if obj:IsA("BodyVelocity") and not bv then bv = obj
		elseif obj:IsA("BodyGyro") and not bg then bg = obj
		elseif obj:IsA("LinearVelocity") and not lv then lv = obj
		elseif obj:IsA("AlignOrientation") and not ao then ao = obj
		end
	end
	return bv,bg,lv,ao
end

local function moverSignature(hrp)
	local bv,bg,lv,ao = findFlyObjects(hrp)
	return table.concat({
		bv and ("BV:"..bv.Name) or "BV:NONE",
		bg and ("BG:"..bg.Name) or "BG:NONE",
		lv and ("LV:"..lv.Name) or "LV:NONE",
		ao and ("AO:"..ao.Name) or "AO:NONE"
	},"|")
end

local function bodyVelocityText(bv)
	if not bv then return "BodyVelocity=NONE" end
	return "BodyVelocity="..bv.Name
		.." Parent="..tostring(bv.Parent and bv.Parent:GetFullName() or "NONE")
		.." Velocity="..fmtVec(bv.Velocity)
		.." Magnitude="..string.format("%.3f",bv.Velocity.Magnitude)
		.." MaxForce="..fmtVec(bv.MaxForce)
		.." P="..tostring(bv.P)
end

local function bodyGyroText(bg)
	if not bg then return "BodyGyro=NONE" end
	return "BodyGyro="..bg.Name
		.." Parent="..tostring(bg.Parent and bg.Parent:GetFullName() or "NONE")
		.." CFrame={"..fmtCF(bg.CFrame).."}"
		.." MaxTorque="..fmtVec(bg.MaxTorque)
		.." P="..tostring(bg.P)
		.." D="..tostring(bg.D)
end

local function linearVelocityText(lv)
	if not lv then return "LinearVelocity=NONE" end
	local ok,v = pcall(function() return lv.VectorVelocity end)
	local ok2,mf = pcall(function() return lv.MaxForce end)
	return "LinearVelocity="..lv.Name
		.." VectorVelocity="..(ok and fmtVec(v) or "UNAVAILABLE")
		.." MaxForce="..(ok2 and tostring(mf) or "UNAVAILABLE")
end

local function alignOrientationText(ao)
	if not ao then return "AlignOrientation=NONE" end
	return "AlignOrientation="..ao.Name
		.." CFrame={"..fmtCF(ao.CFrame).."}"
		.." MaxTorque="..tostring(ao.MaxTorque)
		.." Responsiveness="..tostring(ao.Responsiveness)
		.." RigidityEnabled="..tostring(ao.RigidityEnabled)
end

local function derivedText(hum,hrp,cam,bv)
	if not cam or not bv then return "Derived=UNAVAILABLE" end
	local vel = bv.Velocity
	local look = cam.CFrame.LookVector
	local right = cam.CFrame.RightVector
	local up = cam.CFrame.UpVector
	local horizontal = Vector3.new(vel.X,0,vel.Z).Magnitude
	local move = hum.MoveDirection

	return string.format(
		"Derived CmdMag=%.3f Horizontal=%.3f CamDot[F=%.3f R=%.3f U=%.3f] MoveDot[Look=%.3f Right=%.3f Up=%.3f] ActualVsCmdDelta=%s",
		vel.Magnitude,
		horizontal,
		vel:Dot(look),
		vel:Dot(right),
		vel:Dot(up),
		move:Dot(look),
		move:Dot(right),
		move:Dot(up),
		fmtVec(hrp.AssemblyLinearVelocity - vel)
	)
end

local function snapshot(label)
	if not captureOn then return end
	local char,hum,hrp = getCharacter()

	log("========== "..label.." ==========")
	if not char or not hum or not hrp then
		log("Character/Humanoid/HRP unavailable")
		return
	end

	local cam = workspace.CurrentCamera
	local bv,bg,lv,ao = findFlyObjects(hrp)

	log("FlyFlag="..tostring(getFlyFlag()).." FlySpeed="..tostring(getFlySpeed()))
	log("State="..tostring(hum:GetState()))
	log("Position="..fmtVec(hrp.Position))
	log("HRPVelocity="..fmtVec(hrp.AssemblyLinearVelocity).." Speed="..string.format("%.3f",hrp.AssemblyLinearVelocity.Magnitude))
	log("HRPAngular="..fmtVec(hrp.AssemblyAngularVelocity).." AngularSpeed="..string.format("%.3f",hrp.AssemblyAngularVelocity.Magnitude))
	log("MoveDirection="..fmtVec(hum.MoveDirection).." MoveMagnitude="..string.format("%.3f",hum.MoveDirection.Magnitude))
	log("FloorMaterial="..tostring(hum.FloorMaterial))
	log("PlatformStand="..tostring(hum.PlatformStand).." Sit="..tostring(hum.Sit).." AutoRotate="..tostring(hum.AutoRotate))
	log("Input="..inputSummary().." Touch="..tostring(UIS.TouchEnabled).." Keyboard="..tostring(UIS.KeyboardEnabled))

	if cam then
		log("CameraPosition="..fmtVec(cam.CFrame.Position))
		log("CameraLook="..fmtVec(cam.CFrame.LookVector))
		log("CameraRight="..fmtVec(cam.CFrame.RightVector))
		log("CameraUp="..fmtVec(cam.CFrame.UpVector))
	end

	log("HRPLook="..fmtVec(hrp.CFrame.LookVector))
	log("HRPRight="..fmtVec(hrp.CFrame.RightVector))
	log("HRPUp="..fmtVec(hrp.CFrame.UpVector))
	log(bodyVelocityText(bv))
	log(bodyGyroText(bg))
	log(linearVelocityText(lv))
	log(alignOrientationText(ao))
	log(derivedText(hum,hrp,cam,bv))
end

local function disconnectWatchers()
	for _,c in ipairs(connections) do pcall(function() c:Disconnect() end) end
	table.clear(connections)
	lastHRP = nil
end

local function attachWatchers()
	disconnectWatchers()
	local _,hum,hrp = getCharacter()
	if not hum or not hrp then return end

	lastHRP = hrp
	lastPlatformStand = hum.PlatformStand
	lastAutoRotate = hum.AutoRotate
	lastMoverSignature = moverSignature(hrp)

	table.insert(connections, hum.StateChanged:Connect(function(old,new)
		if captureOn then log("STATE CHANGE "..tostring(old).." -> "..tostring(new)) end
	end))

	table.insert(connections, hum:GetPropertyChangedSignal("PlatformStand"):Connect(function()
		if captureOn then
			log("PLATFORMSTAND CHANGE "..tostring(lastPlatformStand).." -> "..tostring(hum.PlatformStand))
			snapshot("PLATFORMSTAND CHANGED")
		end
		lastPlatformStand = hum.PlatformStand
	end))

	table.insert(connections, hum:GetPropertyChangedSignal("AutoRotate"):Connect(function()
		if captureOn then
			log("AUTOROTATE CHANGE "..tostring(lastAutoRotate).." -> "..tostring(hum.AutoRotate))
			snapshot("AUTOROTATE CHANGED")
		end
		lastAutoRotate = hum.AutoRotate
	end))

	local function observeMover(obj)
		if obj:IsA("BodyVelocity") then
			for _,prop in ipairs({"Velocity","MaxForce","P"}) do
				table.insert(connections,obj:GetPropertyChangedSignal(prop):Connect(function()
					if captureOn then log("BODYVELOCITY "..prop.." CHANGE "..bodyVelocityText(obj)) end
				end))
			end
		elseif obj:IsA("BodyGyro") then
			for _,prop in ipairs({"CFrame","MaxTorque","P","D"}) do
				table.insert(connections,obj:GetPropertyChangedSignal(prop):Connect(function()
					if captureOn then log("BODYGYRO "..prop.." CHANGE "..bodyGyroText(obj)) end
				end))
			end
		end
	end

	for _,obj in ipairs(hrp:GetDescendants()) do observeMover(obj) end

	table.insert(connections, hrp.DescendantAdded:Connect(function(obj)
		if captureOn and (obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") or obj:IsA("LinearVelocity") or obj:IsA("AlignOrientation")) then
			log("FLY OBJECT ADDED "..obj.ClassName..":"..obj.Name)
			observeMover(obj)
			task.defer(function()
				if captureOn then snapshot("FLY OBJECT ADDED") end
			end)
		end
	end))

	table.insert(connections, hrp.DescendantRemoving:Connect(function(obj)
		if captureOn and (obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") or obj:IsA("LinearVelocity") or obj:IsA("AlignOrientation")) then
			log("FLY OBJECT REMOVING "..obj.ClassName..":"..obj.Name)
			snapshot("BEFORE FLY OBJECT REMOVAL")
			postRemovalUntil = os.clock() + POST_MOVER_REMOVAL_SECONDS
		end
	end))
end

local function sample()
	if not captureOn or os.clock() - lastSample < CAPTURE_INTERVAL then return end
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

	local cam = workspace.CurrentCamera
	local bv,bg,lv,ao = findFlyObjects(hrp)
	local p = hrp.Position
	local v = hrp.AssemblyLinearVelocity
	local dPos = lastPos and (p-lastPos) or Vector3.zero
	local dVel = lastVelocity and (v-lastVelocity) or Vector3.zero
	local sig = moverSignature(hrp)

	if lastMoverSignature and sig ~= lastMoverSignature then
		log("MOVER SIGNATURE CHANGE "..lastMoverSignature.." -> "..sig)
		snapshot("MOVER SIGNATURE CHANGED")
		if not bv and not bg and not lv and not ao then
			postRemovalUntil = os.clock() + POST_MOVER_REMOVAL_SECONDS
		end
	end
	lastMoverSignature = sig

	local cmd = bv and bv.Velocity or (lv and lv.VectorVelocity or nil)
	local derived = "NONE"
	if cmd and cam then
		derived = string.format(
			"CmdMag=%.3f Hor=%.3f DotF=%.3f DotR=%.3f DotU=%.3f",
			cmd.Magnitude,
			Vector3.new(cmd.X,0,cmd.Z).Magnitude,
			cmd:Dot(cam.CFrame.LookVector),
			cmd:Dot(cam.CFrame.RightVector),
			cmd:Dot(cam.CFrame.UpVector)
		)
	end

	log(
		"SAMPLE"
		.." Fly="..tostring(getFlyFlag())
		.." FlySpeed="..tostring(getFlySpeed())
		.." State="..tostring(hum:GetState())
		.." Pos="..fmtVec(p)
		.." dPos="..fmtVec(dPos)
		.." Vel="..fmtVec(v)
		.." dVel="..fmtVec(dVel)
		.." Move="..fmtVec(hum.MoveDirection)
		.." CamLook="..(cam and fmtVec(cam.CFrame.LookVector) or "NONE")
		.." CamRight="..(cam and fmtVec(cam.CFrame.RightVector) or "NONE")
		.." CamUp="..(cam and fmtVec(cam.CFrame.UpVector) or "NONE")
		.." CmdVel="..fmtVec(cmd)
		.." "..derived
		.." PlatformStand="..tostring(hum.PlatformStand)
		.." AutoRotate="..tostring(hum.AutoRotate)
		.." Input="..inputSummary()
		.." Movers={"..sig.."}"
		..((postRemovalUntil and os.clock() <= postRemovalUntil) and " POST_REMOVAL=YES" or "")
	)

	lastPos = p
	lastVelocity = v
end

--============================================================
-- SMALL DIAGNOSTIC UI
--============================================================

local old = game:GetService("CoreGui"):FindFirstChild("BlizzardFlyDiagnosticV2Final")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "BlizzardFlyDiagnosticV2Final"
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
title.Text = "BLIZZARD FLY DIAGNOSTIC V2 FINAL — READ ONLY"
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

	log("BLIZZARD FLY DIAGNOSTIC V2 FINAL")
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
	local text = table.concat(logs,"\n") .. "\n\nEND V2 FINAL"
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
		log("BLIZZARD FLY DIAGNOSTIC V2 FINAL")
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

print("BLIZZARD FLY DIAGNOSTIC V2 FINAL loaded — MODE=READ ONLY")
