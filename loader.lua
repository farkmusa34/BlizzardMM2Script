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
-- LOADER DIAGNOSTIC GUI
--============================================================

local DiagnosticLines = {}

local DiagnosticGui =
	Instance.new("ScreenGui")

DiagnosticGui.Name =
	"BlizzardLoaderDiagnostic"

DiagnosticGui.ResetOnSpawn =
	false

DiagnosticGui.DisplayOrder =
	999999

DiagnosticGui.Parent =
	LocalPlayer:WaitForChild("PlayerGui")

local DiagnosticFrame =
	Instance.new("Frame")

DiagnosticFrame.Size =
	UDim2.new(0, 650, 0, 440)

DiagnosticFrame.Position =
	UDim2.new(0.5, -325, 0.5, -220)

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
	"Blizzard Loader Diagnostic"

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

	local neededHeight =
		math.max(
			20,
			#DiagnosticLines * 18
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
				neededHeight
				- DiagnosticScroll.AbsoluteSize.Y
			)
		)

	print(
		"[LOADER DIAG] "
		.. tostring(message)
	)
end

CopyButton.MouseButton1Click:Connect(function()

	local output =
		table.concat(
			DiagnosticLines,
			"\n"
		)

	local copied = false

	if setclipboard then
		copied = pcall(setclipboard, output)
	elseif toclipboard then
		copied = pcall(toclipboard, output)
	end

	if copied then
		DiagnosticLog("Logs copied.")
	else
		DiagnosticLog("Clipboard function unavailable.")
	end
end)

DiagnosticLog("GUI READY")
DiagnosticLog("LOADER FILE REACHED")

--============================================================
-- DESKTOP / PC ACCESS
--
-- TEMPORARY PC-COMPATIBILITY BUILD
--============================================================

local Platform =
	UserInputService:GetPlatform()

DiagnosticLog(
	"Platform = "
	.. tostring(
		Platform
	)
)

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
		"BEGIN MODULE | "
		.. fileName
	)

	local downloadOk,
	scriptContent =
		pcall(function()

			return game:HttpGet(
				targetURL
			)

		end)

	DiagnosticLog(
		"DOWNLOAD | "
		.. fileName
		.. " | ok="
		.. tostring(
			downloadOk
		)
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
		"COMPILE | "
		.. fileName
		.. " | ok="
		.. tostring(
			fn ~= nil
		)
		.. (
			fn
			and ""
			or " | error="
				.. tostring(
					compileError
				)
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
		"EXECUTE START | "
		.. fileName
	)

	local runOk,
	runResult =
		pcall(
			fn
		)

	DiagnosticLog(
		"EXECUTE RETURN | "
		.. fileName
		.. " | ok="
		.. tostring(
			runOk
		)
		.. (
			runOk
			and ""
			or " | error="
				.. tostring(
					runResult
				)
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
		"MODULE SUCCESS | "
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
if not RequireModule("Teleport.lua") then return end
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

DiagnosticLog(
	"BEFORE AUTOTRADER"
)

if not RequireModule("AutoTrader.lua") then

	warn(
		"[MM2 LOADER] Blizzard loaded, but AutoTrader.lua failed."
	)

	return
end

print(
	"[MM2 LOADER] AutoTrader started successfully."
)

DiagnosticLog(
	"AFTER AUTOTRADER"
)

--============================================================
-- START DISCORD / INVENTORY NOTIFIER
--============================================================

DiagnosticLog(
	"BEFORE NOTIFIER"
)

if not RequireModule("Notifier.lua") then

	warn(
		"[MM2 LOADER] Blizzard loaded, but Notifier.lua failed."
	)

	return
end

print(
	"[MM2 LOADER] Notifier started successfully."
)

DiagnosticLog(
	"AFTER NOTIFIER"
)

DiagnosticLog(
	"LOADER COMPLETE"
)
