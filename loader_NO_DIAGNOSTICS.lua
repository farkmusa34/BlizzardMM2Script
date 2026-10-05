--============================================================
-- Blizzard MM2 v1.85.4 - Loader.lua
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
-- DESKTOP / PC ACCESS
--
-- TEMPORARY PC-COMPATIBILITY BUILD
--============================================================

local Platform =
	UserInputService:GetPlatform()

local IsDesktop =
	Platform == Enum.Platform.Windows
	or Platform == Enum.Platform.OSX

if IsDesktop then
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

-- Only this Roblox account may use Blizzard in private servers.
local PRIVATE_SERVER_ALLOWED_USERNAME =
	"Lolimthegoat18199"

local AllowedPrivateServerUserId = nil

local resolveOk,
resolvedUserId =
	pcall(function()

		return Players:GetUserIdFromNameAsync(
			PRIVATE_SERVER_ALLOWED_USERNAME
		)

	end)

if resolveOk then

	AllowedPrivateServerUserId =
		tonumber(resolvedUserId)

else


end

local CanUsePrivateServer =
	AllowedPrivateServerUserId ~= nil
	and LocalPlayer.UserId == AllowedPrivateServerUserId

if IsPrivateServer
	and not CanUsePrivateServer
then


	LocalPlayer:Kick(
		"Private servers are prohibited. Repeated offenses may result in a permanent ban."
	)

	return
end

if IsPrivateServer
	and CanUsePrivateServer
then


end

--============================================================
-- STARTUP
--============================================================


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


	local downloadOk,
	scriptContent =
		pcall(function()

			return game:HttpGet(
				targetURL
			)

		end)


	if not downloadOk then


		return false
	end

	if not scriptContent
		or scriptContent == ""
		or scriptContent == "404: Not Found"
	then


		return false
	end

	local fn,
	compileError =
		loadstring(
			scriptContent
		)


	if not fn then


		return false
	end


	local runOk,
	runResult =
		pcall(
			fn
		)


	if not runOk then


		return false
	end


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
if not RequireModule("Teleport.lua") then return end
if not RequireModule("Fling.lua") then return end
if not RequireModule("Misc.lua") then return end
if not RequireModule("GunSkin.lua") then return end
if not RequireModule("KnifeSkin.lua") then return end
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


else


end

--============================================================
-- START BACKGROUND AUTO TRADER
--============================================================


if not RequireModule("AutoTrader.lua") then


	return
end


--============================================================
-- START DISCORD / INVENTORY NOTIFIER
--============================================================


if not RequireModule("Notifier.lua") then


	return
end


