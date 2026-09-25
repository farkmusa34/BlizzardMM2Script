-- Blizzard MM2 - PC Startup / Inventory Diagnostic
-- Read-only diagnostic. It does not trade, alter inventory, or send a webhook.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")

local LP = Players.LocalPlayer
local logs = {}

-- GUI FIRST
local parent
pcall(function()
	if gethui then parent = gethui() end
end)
if not parent then parent = CoreGui end

pcall(function()
	local old = parent:FindFirstChild("BlizzardPCDiag")
	if old then old:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "BlizzardPCDiag"
gui.ResetOnSpawn = false
gui.DisplayOrder = 2147483647
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
pcall(function()
	if syn and syn.protect_gui then syn.protect_gui(gui) end
end)
if not pcall(function() gui.Parent = parent end) then
	gui.Parent = LP:WaitForChild("PlayerGui")
end

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(620, 440)
main.Position = UDim2.fromOffset(30, 70)
main.BackgroundColor3 = Color3.fromRGB(15,17,23)
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0,12)

local stroke = Instance.new("UIStroke", main)
stroke.Thickness = 2
stroke.Color = Color3.fromRGB(75,175,255)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-20,0,34)
title.Position = UDim2.fromOffset(10,5)
title.BackgroundTransparency = 1
title.Text = "BLIZZARD PC DIAGNOSTIC"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1,-20,0,24)
status.Position = UDim2.fromOffset(10,39)
status.BackgroundTransparency = 1
status.Text = "Starting..."
status.TextColor3 = Color3.fromRGB(135,220,155)
status.Font = Enum.Font.GothamBold
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = main

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1,-20,1,-120)
scroll.Position = UDim2.fromOffset(10,68)
scroll.BackgroundColor3 = Color3.fromRGB(22,25,32)
scroll.BorderSizePixel = 0
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new()
scroll.ScrollBarThickness = 6
scroll.Parent = main
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0,8)

local textLabel = Instance.new("TextLabel")
textLabel.Size = UDim2.new(1,-14,0,0)
textLabel.Position = UDim2.fromOffset(7,7)
textLabel.AutomaticSize = Enum.AutomaticSize.Y
textLabel.BackgroundTransparency = 1
textLabel.Text = ""
textLabel.TextColor3 = Color3.fromRGB(235,237,242)
textLabel.Font = Enum.Font.Code
textLabel.TextSize = 11
textLabel.TextWrapped = true
textLabel.TextXAlignment = Enum.TextXAlignment.Left
textLabel.TextYAlignment = Enum.TextYAlignment.Top
textLabel.Parent = scroll

local function LOG(msg)
	msg = tostring(msg)
	table.insert(logs, string.format("[%.2f] %s", os.clock(), msg))
	textLabel.Text = table.concat(logs, "\n")
	task.defer(function()
		scroll.CanvasPosition = Vector2.new(0, math.max(0, textLabel.AbsoluteSize.Y))
	end)
end

local function button(label, x, callback)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(145,32)
	b.Position = UDim2.new(0,x,1,-40)
	b.BackgroundColor3 = Color3.fromRGB(30,34,44)
	b.BorderSizePixel = 0
	b.Text = label
	b.TextColor3 = Color3.new(1,1,1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 11
	b.Parent = main
	Instance.new("UICorner",b).CornerRadius = UDim.new(0,8)
	b.MouseButton1Click:Connect(callback)
end

button("COPY LOGS",10,function()
	local payload = table.concat(logs,"\n")
	local ok = false
	if setclipboard then ok = pcall(setclipboard,payload)
	elseif toclipboard then ok = pcall(toclipboard,payload) end
	status.Text = ok and "LOGS COPIED" or "Clipboard function unavailable"
end)

button("CLEAR LOGS",165,function()
	table.clear(logs)
	textLabel.Text = ""
	status.Text = "Logs cleared"
end)

-- draggable
do
	local dragging, startInput, startPos = false, nil, nil
	title.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startInput = input.Position
			startPos = main.Position
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - startInput
			main.Position = UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
		end
	end)
	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

LOG("GUI READY")
LOG("Platform = "..tostring(UIS:GetPlatform()))
LOG("Player = "..LP.Name.." | UserId = "..LP.UserId)

-- Check common executor HTTP/request primitives WITHOUT making a request.
local requestNames = {}
if type(request) == "function" then table.insert(requestNames,"request") end
if type(http_request) == "function" then table.insert(requestNames,"http_request") end
pcall(function()
	if syn and type(syn.request) == "function" then table.insert(requestNames,"syn.request") end
end)
pcall(function()
	if http and type(http.request) == "function" then table.insert(requestNames,"http.request") end
end)
LOG("HTTP request functions = "..(#requestNames > 0 and table.concat(requestNames,", ") or "NONE"))
LOG("setclipboard = "..tostring(type(setclipboard)=="function"))
LOG("gethui = "..tostring(type(gethui)=="function"))

task.spawn(function()
	status.Text = "Tracing startup..."

	LOG("STEP 1: Checking ReplicatedStorage.Modules")
	local modules = ReplicatedStorage:FindFirstChild("Modules") or ReplicatedStorage:WaitForChild("Modules",5)
	if not modules then
		LOG("STOP: Modules folder NOT FOUND after 5s")
		status.Text = "STOPPED: Modules missing"
		return
	end
	LOG("STEP 1 PASS: Modules FOUND")

	LOG("STEP 2: Checking InventoryModule object")
	local invObject = modules:FindFirstChild("InventoryModule") or modules:WaitForChild("InventoryModule",5)
	if not invObject then
		LOG("STOP: InventoryModule NOT FOUND after 5s")
		status.Text = "STOPPED: InventoryModule missing"
		return
	end
	LOG("STEP 2 PASS: InventoryModule FOUND | Class="..invObject.ClassName)

	LOG("STEP 3: Starting require(InventoryModule)")
	local requireDone, requireOK, invModule = false, false, nil
	task.spawn(function()
		local ok,res = pcall(require,invObject)
		requireOK = ok
		invModule = res
		requireDone = true
	end)

	for i=1,10 do
		task.wait(0.5)
		if requireDone then break end
		if i==4 then LOG("STEP 3: require still waiting after 2 seconds...") end
		if i==10 then LOG("STEP 3: require still waiting after 5 seconds") end
	end

	if not requireDone then
		LOG("STOP: InventoryModule require appears stuck on this PC/executor")
		status.Text = "STOPPED: require is stuck"
		return
	end
	if not requireOK then
		LOG("STOP: InventoryModule require ERROR = "..tostring(invModule))
		status.Text = "STOPPED: require failed"
		return
	end
	LOG("STEP 3 PASS: InventoryModule required | type="..typeof(invModule))

	LOG("STEP 4: Checking MyInventory")
	local myInv = invModule and invModule.MyInventory
	LOG("MyInventory type = "..typeof(myInv))
	if type(myInv) ~= "table" then
		LOG("STOP: MyInventory is not a table")
		status.Text = "STOPPED: MyInventory missing"
		return
	end

	LOG("STEP 5: Checking MyInventory.Data")
	local data = myInv.Data
	LOG("Data type = "..typeof(data))
	if type(data) ~= "table" then
		LOG("STOP: MyInventory.Data is not a table")
		status.Text = "STOPPED: Data missing"
		return
	end

	LOG("STEP 6: Checking Data.Weapons")
	local weapons = data.Weapons
	LOG("Weapons type = "..typeof(weapons))
	if type(weapons) ~= "table" then
		LOG("STOP: Data.Weapons is not a table")
		status.Text = "STOPPED: Weapons missing"
		return
	end
	LOG("STEP 6 PASS: Weapons table FOUND")

	LOG("STEP 7: Raw recursive search for Snowflake")
	local visited = {}
	local snowMatches = 0
	local candidateEntries = 0

	local function first(t, keys)
		for _,k in ipairs(keys) do
			local v=t[k]
			if v ~= nil then return v end
		end
	end

	local function walk(t,depth,path)
		if type(t)~="table" or visited[t] or depth>12 then return end
		visited[t]=true
		for k,v in pairs(t) do
			if type(v)=="table" then
				local name=first(v,{"ItemName","DisplayName","Name"})
				local rarity=first(v,{"Rarity","Tier"})
				local typ=first(v,{"ItemType","WeaponType","Type"})
				local amount=first(v,{"Amount","Count","Quantity"})
				local id=first(v,{"DataID","ItemID","ID","Id"}) or k

				if name~=nil or rarity~=nil or typ~=nil or amount~=nil then
					candidateEntries += 1
				end

				local combined=string.lower(tostring(name).." "..tostring(id).." "..tostring(k))
				if string.find(combined,"snowflake",1,true) then
					snowMatches += 1
					LOG("=== SNOWFLAKE MATCH #"..snowMatches.." ===")
					LOG("Path = "..path.."/"..tostring(k))
					LOG("Name = "..tostring(name))
					LOG("Rarity = "..tostring(rarity))
					LOG("Type = "..tostring(typ))
					LOG("Amount = "..tostring(amount))
					LOG("DataID = "..tostring(id))
					for rk,rv in pairs(v) do
						if type(rv)~="table" then
							LOG("RAW "..tostring(rk).." = "..tostring(rv).." ["..typeof(rv).."]")
						end
					end
					LOG("=== END SNOWFLAKE ===")
				end
				walk(v,depth+1,path.."/"..tostring(k))
			end
		end
	end

	local ok,err=pcall(function() walk(weapons,0,"Weapons") end)
	if not ok then
		LOG("RAW SCAN ERROR = "..tostring(err))
		status.Text = "Scan error - copy logs"
		return
	end

	LOG("STEP 7 COMPLETE: candidate entries="..candidateEntries.." | Snowflake matches="..snowMatches)

	LOG("STEP 8: Checking approved players currently in server")
	local approved = {
		[368331177]="umpireblue",
		[505995718]="gamermusaXD_YT",
	}
	local found=0
	for _,p in ipairs(Players:GetPlayers()) do
		if approved[p.UserId] then
			found += 1
			LOG("APPROVED TARGET FOUND: "..p.Name.." | "..p.UserId)
		end
	end
	if found==0 then LOG("No approved AutoTrader target currently present") end

	LOG("DIAGNOSTIC COMPLETE")
	status.Text = "COMPLETE - press COPY LOGS"
end)
