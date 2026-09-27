--============================================================
-- BLIZZARD MM2 - SPEED ISOLATION DIAGNOSTIC V3
-- Small GUI + V2-style speed controller + Copy Logs
--
-- PURPOSE:
-- Temporarily test the exact simple WalkSpeed strategy that behaved well
-- in Speed Test V2, while logging the Humanoid state/floor behavior.
-- This diagnostic does not enable Fly/Noclip/etc.
--============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

local OLD_NAME = "BlizzardSpeedIsolationV3"
local old = PG:FindFirstChild(OLD_NAME)
if old then old:Destroy() end

local SPEEDS = {16,40,60,80,100,120}
local SpeedIndex = 1
local TestSpeed = SPEEDS[SpeedIndex]
local Running = false

local Logs = {}
local MAX_LOGS = 400
local LastState,LastFloor,LastY,LastActual,LastWS
local LastSnapshot = 0
local LastKick = 0

local function AddLog(text)
	Logs[#Logs+1] = string.format("[%.3f] %s",os.clock(),text)
	while #Logs > MAX_LOGS do table.remove(Logs,1) end
end

local function GetCharacter()
	local char = LP.Character
	if not char then return end
	return char,
		char:FindFirstChildOfClass("Humanoid"),
		char:FindFirstChild("HumanoidRootPart")
end

local function RootObjects(hrp)
	if not hrp then return "(none)" end
	local t = {}
	for _,o in ipairs(hrp:GetChildren()) do
		if o:IsA("Attachment") or o:IsA("LinearVelocity")
			or o:IsA("AlignOrientation") or o:IsA("VectorForce")
			or o:IsA("BodyVelocity") or o:IsA("BodyGyro")
			or o:IsA("BodyPosition") then
			t[#t+1] = o.ClassName..":"..o.Name
		end
	end
	table.sort(t)
	return #t > 0 and table.concat(t,",") or "(none)"
end

--============================================================
-- GUI
--============================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = OLD_NAME
Gui.ResetOnSpawn = false
Gui.DisplayOrder = 999999
Gui.Parent = PG

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(300,240)
Main.Position = UDim2.new(0.5,-150,0.12,0)
Main.BackgroundColor3 = Color3.fromRGB(18,18,18)
Main.BorderSizePixel = 0
Main.Parent = Gui
Instance.new("UICorner",Main).CornerRadius = UDim.new(0,12)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(58,58,58)
Stroke.Thickness = 1
Stroke.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,-20,0,30)
Title.Position = UDim2.fromOffset(10,4)
Title.BackgroundTransparency = 1
Title.Text = "SPEED ISOLATION V3"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Active = true
Title.Parent = Main

local Minus = Instance.new("TextButton")
Minus.Size = UDim2.fromOffset(42,36)
Minus.Position = UDim2.fromOffset(10,38)
Minus.Text = "−"
Minus.TextSize = 20
Minus.Font = Enum.Font.GothamBold
Minus.TextColor3 = Color3.new(1,1,1)
Minus.BackgroundColor3 = Color3.fromRGB(38,38,38)
Minus.BorderSizePixel = 0
Minus.Parent = Main
Instance.new("UICorner",Minus).CornerRadius = UDim.new(0,8)

local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.fromOffset(181,36)
SpeedLabel.Position = UDim2.fromOffset(57,38)
SpeedLabel.BackgroundColor3 = Color3.fromRGB(27,27,27)
SpeedLabel.BorderSizePixel = 0
SpeedLabel.TextColor3 = Color3.new(1,1,1)
SpeedLabel.Font = Enum.Font.GothamBold
SpeedLabel.TextSize = 13
SpeedLabel.Parent = Main
Instance.new("UICorner",SpeedLabel).CornerRadius = UDim.new(0,8)

local Plus = Instance.new("TextButton")
Plus.Size = UDim2.fromOffset(42,36)
Plus.Position = UDim2.fromOffset(248,38)
Plus.Text = "+"
Plus.TextSize = 20
Plus.Font = Enum.Font.GothamBold
Plus.TextColor3 = Color3.new(1,1,1)
Plus.BackgroundColor3 = Color3.fromRGB(38,38,38)
Plus.BorderSizePixel = 0
Plus.Parent = Main
Instance.new("UICorner",Plus).CornerRadius = UDim.new(0,8)

local Info = Instance.new("TextLabel")
Info.Size = UDim2.fromOffset(280,100)
Info.Position = UDim2.fromOffset(10,82)
Info.BackgroundColor3 = Color3.fromRGB(27,27,27)
Info.BorderSizePixel = 0
Info.TextColor3 = Color3.fromRGB(235,235,235)
Info.Font = Enum.Font.Code
Info.TextSize = 11
Info.TextXAlignment = Enum.TextXAlignment.Left
Info.TextYAlignment = Enum.TextYAlignment.Center
Info.Text = "  Press START TEST"
Info.Parent = Main
Instance.new("UICorner",Info).CornerRadius = UDim.new(0,8)

local Start = Instance.new("TextButton")
Start.Size = UDim2.fromOffset(88,44)
Start.Position = UDim2.fromOffset(10,190)
Start.BackgroundColor3 = Color3.fromRGB(235,235,235)
Start.BorderSizePixel = 0
Start.TextColor3 = Color3.fromRGB(15,15,15)
Start.Font = Enum.Font.GothamBold
Start.TextSize = 11
Start.Text = "START"
Start.Parent = Main
Instance.new("UICorner",Start).CornerRadius = UDim.new(0,8)

local Clear = Instance.new("TextButton")
Clear.Size = UDim2.fromOffset(84,44)
Clear.Position = UDim2.fromOffset(103,190)
Clear.BackgroundColor3 = Color3.fromRGB(38,38,38)
Clear.BorderSizePixel = 0
Clear.TextColor3 = Color3.new(1,1,1)
Clear.Font = Enum.Font.GothamBold
Clear.TextSize = 11
Clear.Text = "CLEAR"
Clear.Parent = Main
Instance.new("UICorner",Clear).CornerRadius = UDim.new(0,8)

local Copy = Instance.new("TextButton")
Copy.Size = UDim2.fromOffset(98,44)
Copy.Position = UDim2.fromOffset(192,190)
Copy.BackgroundColor3 = Color3.fromRGB(38,38,38)
Copy.BorderSizePixel = 0
Copy.TextColor3 = Color3.new(1,1,1)
Copy.Font = Enum.Font.GothamBold
Copy.TextSize = 11
Copy.Text = "COPY LOGS"
Copy.Parent = Main
Instance.new("UICorner",Copy).CornerRadius = UDim.new(0,8)

local function UpdateSpeedLabel()
	SpeedLabel.Text = "TEST SPEED: "..TestSpeed
end
UpdateSpeedLabel()

local function ApplySpeed()
	local _,hum = GetCharacter()
	if hum then hum.WalkSpeed = TestSpeed end
end

Minus.MouseButton1Click:Connect(function()
	SpeedIndex -= 1
	if SpeedIndex < 1 then SpeedIndex = #SPEEDS end
	TestSpeed = SPEEDS[SpeedIndex]
	UpdateSpeedLabel()
	if Running then
		ApplySpeed()
		AddLog("TEST SPEED CHANGED -> "..TestSpeed)
	end
end)

Plus.MouseButton1Click:Connect(function()
	SpeedIndex += 1
	if SpeedIndex > #SPEEDS then SpeedIndex = 1 end
	TestSpeed = SPEEDS[SpeedIndex]
	UpdateSpeedLabel()
	if Running then
		ApplySpeed()
		AddLog("TEST SPEED CHANGED -> "..TestSpeed)
	end
end)

Start.MouseButton1Click:Connect(function()
	Running = not Running
	if Running then
		LastState,LastFloor,LastY,LastActual,LastWS = nil,nil,nil,nil,nil
		LastSnapshot,LastKick = 0,0
		ApplySpeed()
		AddLog("===== V3 TEST STARTED | SPEED="..TestSpeed.." =====")
		Start.Text = "STOP"
	else
		AddLog("===== V3 TEST STOPPED =====")
		Start.Text = "START"
	end
end)

Clear.MouseButton1Click:Connect(function()
	table.clear(Logs)
	LastState,LastFloor,LastY,LastActual,LastWS = nil,nil,nil,nil,nil
	LastSnapshot,LastKick = 0,0
	AddLog("LOGS CLEARED | SPEED="..TestSpeed)
	Clear.Text = "CLEARED"
	task.delay(0.6,function()
		if Clear.Parent then Clear.Text = "CLEAR" end
	end)
end)

Copy.MouseButton1Click:Connect(function()
	local text = table.concat(Logs,"\n")
	if setclipboard then setclipboard(text)
	elseif toclipboard then toclipboard(text)
	else warn(text) end
	Copy.Text = "COPIED"
	task.delay(0.6,function()
		if Copy.Parent then Copy.Text = "COPY LOGS" end
	end)
end)

--============================================================
-- DRAG
--============================================================

local Dragging = false
local DragStart,StartPos,DragInput

Title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		Dragging = true
		DragStart = input.Position
		StartPos = Main.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				Dragging = false
			end
		end)
	end
end)

Title.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
		DragInput = input
	end
end)

UIS.InputChanged:Connect(function(input)
	if Dragging and input == DragInput then
		local d = input.Position-DragStart
		Main.Position = UDim2.new(
			StartPos.X.Scale,StartPos.X.Offset+d.X,
			StartPos.Y.Scale,StartPos.Y.Offset+d.Y
		)
	end
end)

--============================================================
-- EXACT V2-STYLE HEARTBEAT CONTROL + DIAGNOSTICS
--============================================================

RunService.Heartbeat:Connect(function()
	local _,hum,hrp = GetCharacter()
	if not hum or not hrp then
		Info.Text = "  Waiting for character..."
		return
	end

	local v = hrp.AssemblyLinearVelocity
	local actual = Vector3.new(v.X,0,v.Z).Magnitude
	local state = hum:GetState()
	local floor = hum.FloorMaterial

	Info.Text = string.format(
		"  Set:%-4d WS:%-5.1f Actual:%-6.1f\n"
		.."  Y:%-7.2f State:%s\n"
		.."  Floor:%-12s AR:%s PS:%s\n"
		.."  HRP: %s",
		TestSpeed,hum.WalkSpeed,actual,v.Y,
		state.Name,floor.Name,
		tostring(hum.AutoRotate),tostring(hum.PlatformStand),
		RootObjects(hrp)
	)

	if not Running then return end

	-- Same simple control strategy as the working V2:
	-- only restore WalkSpeed if another script actually changed it.
	if hum.WalkSpeed ~= TestSpeed then
		AddLog(string.format(
			"EXTERNAL WALKSPEED CHANGE %.1f -> %d",
			hum.WalkSpeed,TestSpeed
		))
		hum.WalkSpeed = TestSpeed
	end

	if LastState and state ~= LastState then
		AddLog(string.format(
			"STATE %s -> %s | Set=%d WS=%.1f Actual=%.1f Y=%.2f Floor=%s AR=%s PS=%s",
			LastState.Name,state.Name,TestSpeed,hum.WalkSpeed,actual,v.Y,
			floor.Name,tostring(hum.AutoRotate),tostring(hum.PlatformStand)
		))
	end

	if LastFloor and floor ~= LastFloor then
		AddLog(string.format(
			"FLOOR %s -> %s | Set=%d Actual=%.1f Y=%.2f State=%s",
			LastFloor.Name,floor.Name,TestSpeed,actual,v.Y,state.Name
		))
	end

	if LastWS and math.abs(hum.WalkSpeed-LastWS) > 0.01 then
		AddLog(string.format(
			"OBSERVED WS %.1f -> %.1f | Set=%d State=%s",
			LastWS,hum.WalkSpeed,TestSpeed,state.Name
		))
	end

	if LastY and actual > 10 then
		local delta = v.Y-LastY
		if math.abs(delta) >= 6 and os.clock()-LastKick >= 0.05 then
			LastKick = os.clock()
			AddLog(string.format(
				"Y-KICK %.2f -> %.2f Delta=%.2f | Set=%d Actual=%.1f State=%s Floor=%s",
				LastY,v.Y,delta,TestSpeed,actual,state.Name,floor.Name
			))
		end
	end

	if LastActual and LastActual > 30 and actual < 5 then
		AddLog(string.format(
			"SPEED DROP %.1f -> %.1f | Set=%d Y=%.2f State=%s Floor=%s",
			LastActual,actual,TestSpeed,v.Y,state.Name,floor.Name
		))
	end

	if os.clock()-LastSnapshot >= 0.5 then
		LastSnapshot = os.clock()
		AddLog(string.format(
			"SNAP | Set=%d WS=%.1f Actual=%.1f Y=%.2f State=%s Floor=%s AR=%s PS=%s HRP=[%s]",
			TestSpeed,hum.WalkSpeed,actual,v.Y,state.Name,floor.Name,
			tostring(hum.AutoRotate),tostring(hum.PlatformStand),RootObjects(hrp)
		))
	end

	LastState,LastFloor,LastY,LastActual,LastWS =
		state,floor,v.Y,actual,hum.WalkSpeed
end)

LP.CharacterAdded:Connect(function()
	LastState,LastFloor,LastY,LastActual,LastWS = nil,nil,nil,nil,nil
	LastSnapshot,LastKick = 0,0
	if Running then
		task.wait(0.25)
		ApplySpeed()
		AddLog("CHARACTER RESPAWNED | REAPPLIED TEST SPEED "..TestSpeed)
	end
end)

AddLog("SPEED ISOLATION V3 LOADED")
