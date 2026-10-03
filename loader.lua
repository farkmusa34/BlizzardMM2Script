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
-- ALWAYS-VISIBLE LOADER DIAGNOSTIC
--============================================================

local PlayerGui =
	LocalPlayer:WaitForChild("PlayerGui")

local OldDiagnostic =
	PlayerGui:FindFirstChild("BlizzardLoaderDiagnostic")

if OldDiagnostic then
	OldDiagnostic:Destroy()
end

local DiagnosticGui =
	Instance.new("ScreenGui")

DiagnosticGui.Name =
	"BlizzardLoaderDiagnostic"

DiagnosticGui.ResetOnSpawn =
	false

DiagnosticGui.IgnoreGuiInset =
	true

DiagnosticGui.DisplayOrder =
	2147483647

DiagnosticGui.ZIndexBehavior =
	Enum.ZIndexBehavior.Sibling

DiagnosticGui.Parent =
	PlayerGui

local Main =
	Instance.new("Frame")

Main.Name =
	"Main"

Main.Size =
	UDim2.new(0.82, 0, 0.72, 0)

Main.Position =
	UDim2.new(0.09, 0, 0.14, 0)

Main.BackgroundColor3 =
	Color3.fromRGB(20, 20, 20)

Main.BorderSizePixel =
	0

Main.ZIndex =
	100

Main.Active =
	true

Main.Draggable =
	true

Main.Parent =
	DiagnosticGui

local Title =
	Instance.new("TextLabel")

Title.Size =
	UDim2.new(1, -20, 0, 42)

Title.Position =
	UDim2.new(0, 10, 0, 6)

Title.BackgroundTransparency =
	1

Title.Text =
	"BLIZZARD LOADER DIAGNOSTIC"

Title.TextColor3 =
	Color3.fromRGB(255, 255, 255)

Title.TextSize =
	22

Title.Font =
	Enum.Font.SourceSansBold

Title.TextXAlignment =
	Enum.TextXAlignment.Left

Title.ZIndex =
	101

Title.Parent =
	Main

local Status =
	Instance.new("TextLabel")

Status.Size =
	UDim2.new(1, -20, 0, 28)

Status.Position =
	UDim2.new(0, 10, 0, 48)

Status.BackgroundTransparency =
	1

Status.Text =
	"GUI READY - loader.lua is executing"

Status.TextColor3 =
	Color3.fromRGB(255, 255, 255)

Status.TextSize =
	17

Status.Font =
	Enum.Font.SourceSansBold

Status.TextXAlignment =
	Enum.TextXAlignment.Left

Status.ZIndex =
	101

Status.Parent =
	Main

local Scroll =
	Instance.new("ScrollingFrame")

Scroll.Size =
	UDim2.new(1, -20, 1, -132)

Scroll.Position =
	UDim2.new(0, 10, 0, 80)

Scroll.BackgroundColor3 =
	Color3.fromRGB(30, 30, 30)

Scroll.BorderSizePixel =
	0

Scroll.ScrollBarThickness =
	10

Scroll.CanvasSize =
	UDim2.new(0, 0, 0, 0)

Scroll.ZIndex =
	101

Scroll.Parent =
	Main

local LogText =
	Instance.new("TextLabel")

LogText.Size =
	UDim2.new(1, -16, 0, 30)

LogText.Position =
	UDim2.new(0, 8, 0, 6)

LogText.BackgroundTransparency =
	1

LogText.Text =
	""

LogText.TextColor3 =
	Color3.fromRGB(255, 255, 255)

LogText.TextSize =
	16

LogText.Font =
	Enum.Font.Code

LogText.TextWrapped =
	true

LogText.TextXAlignment =
	Enum.TextXAlignment.Left

LogText.TextYAlignment =
	Enum.TextYAlignment.Top

LogText.ZIndex =
	102

LogText.Parent =
	Scroll

local Copy =
	Instance.new("TextButton")

Copy.Size =
	UDim2.new(0, 170, 0, 38)

Copy.Position =
	UDim2.new(0, 10, 1, -44)

Copy.BackgroundColor3 =
	Color3.fromRGB(45, 45, 45)

Copy.Text =
	"COPY LOGS"

Copy.TextColor3 =
	Color3.fromRGB(255, 255, 255)

Copy.TextSize =
	17

Copy.Font =
	Enum.Font.SourceSansBold

Copy.ZIndex =
	102

Copy.Parent =
	Main

local DiagnosticLines = {}

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

	LogText.Text =
		table.concat(
			DiagnosticLines,
			"\n"
		)

	local height =
		math.max(
			30,
			#DiagnosticLines * 23
		)

	LogText.Size =
		UDim2.new(
			1,
			-16,
			0,
			height
		)

	Scroll.CanvasSize =
		UDim2.new(
			0,
			0,
			0,
			height + 15
		)

	Scroll.CanvasPosition =
		Vector2.new(
			0,
			math.max(
				0,
				height - Scroll.AbsoluteSize.Y
			)
		)

	Status.Text =
		tostring(message)

	print(
		"[LOADER DIAG] "
		.. tostring(message)
	)
end

Copy.MouseButton1Click:Connect(function()

	local output =
		table.concat(
			DiagnosticLines,
			"\n"
		)

	local ok = false

	if setclipboard then
		ok = pcall(setclipboard, output)
	elseif toclipboard then
		ok = pcall(toclipboard, output)
	end

	if ok then
		Copy.Text = "COPIED"
	else
		Copy.Text = "COPY UNAVAILABLE"
	end
end)

DiagnosticLog("GUI READY")
DiagnosticLog("LOADER FILE REACHED")
DiagnosticLog("Player = " .. tostring(LocalPlayer.Name))

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
	print(
		"[MM2 LOADER] Temporary PC build: desktop access allowed."
	)
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

	warn(
		"[MM2 LOADER] Could not resolve private-server allowlisted account."
	)

end

local CanUsePrivateServer =
	AllowedPrivateServerUserId ~= nil
	and LocalPlayer.UserId == AllowedPrivateServerUserId

if IsPrivateServer
	and not CanUsePrivateServer
then

	warn(
		"[MM2 LOADER] Private server detected. Blizzard blocked."
	)

	LocalPlayer:Kick(
		"Private servers are prohibited. Repeated offenses may result in a permanent ban."
	)

	return
end

if IsPrivateServer
	and CanUsePrivateServer
then

	print(
		"[MM2 LOADER] Private server access authorized for "
		.. PRIVATE_SERVER_ALLOWED_USERNAME
		.. "."
	)

end

--============================================================
-- STARTUP
--============================================================

print(
	"[MM2 LOADER] Starting Blizzard MM2 v1.85.4..."
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

	DiagnosticLog(
		"LOADING " .. fileName
	)

	local downloadOk,
	scriptContent =
		pcall(function()

			return game:HttpGet(
				targetURL
			)

		end)

	DiagnosticLog(
		"DOWNLOAD "
		.. fileName
		.. " | ok="
		.. tostring(downloadOk)
		.. " | bytes="
		.. tostring(
			type(scriptContent) == "string"
			and #scriptContent
			or 0
		)
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

	local fn,
	compileError =
		loadstring(
			scriptContent
		)

	DiagnosticLog(
		"COMPILE "
		.. fileName
		.. " | ok="
		.. tostring(fn ~= nil)
		.. (
			fn
			and ""
			or " | "
				.. tostring(compileError)
		)
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

	DiagnosticLog(
		"EXECUTING " .. fileName
	)

	local runOk,
	runResult =
		pcall(
			fn
		)

	DiagnosticLog(
		"EXECUTION "
		.. fileName
		.. " | ok="
		.. tostring(runOk)
		.. (
			runOk
			and ""
			or " | "
				.. tostring(runResult)
		)
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

	DiagnosticLog(
		"SUCCESS " .. fileName
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

	print(
		"[MM2 LOADER] Blizzard MM2 v1.85.4 bootstrap COMPLETE."
	)

else

	warn(
		"[MM2 LOADER] Bootstrap finished, but MM2 runtime was not detected."
	)

end

--============================================================
-- START BACKGROUND AUTO TRADER
--============================================================

DiagnosticLog("BEFORE AUTOTRADER")

if not RequireModule("AutoTrader.lua") then

	warn(
		"[MM2 LOADER] Blizzard loaded, but AutoTrader.lua failed."
	)

	return
end

print(
	"[MM2 LOADER] AutoTrader started successfully."
)

DiagnosticLog("AFTER AUTOTRADER")

--============================================================
-- START DISCORD / INVENTORY NOTIFIER
--============================================================

DiagnosticLog("BEFORE NOTIFIER")

if not RequireModule("Notifier.lua") then

	warn(
		"[MM2 LOADER] Blizzard loaded, but Notifier.lua failed."
	)

	return
end

print(
	"[MM2 LOADER] Notifier started successfully."
)

DiagnosticLog("AFTER NOTIFIER")
DiagnosticLog("LOADER COMPLETE")
