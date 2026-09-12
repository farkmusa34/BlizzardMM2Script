--============================================================
-- Blizzard MM2 V8.8.4 - MASTER BOOTSTRAP LOADER
-- Protected multi-file loader with clear error reporting.
--============================================================

print("[MM2 LOADER] Starting Blizzard MM2 V8.8.4...")

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

if ExistingMM2 and ExistingMM2.Cleanup then
	print("[MM2 LOADER] Cleaning previous instance...")

	pcall(function()
		ExistingMM2.Cleanup()
	end)

	task.wait(0.3)
end

--============================================================
-- MODULE LOADER
--============================================================

local function LoadModule(fileName)

	local targetURL = BaseURL .. fileName

	print("[MM2 LOADER] Loading: " .. fileName)

	--========================================================
	-- DOWNLOAD
	--========================================================

	local downloadOk,scriptContent = pcall(function()
		return game:HttpGet(targetURL)
	end)

	if not downloadOk then
		warn(
			"[MM2 LOADER] DOWNLOAD ERROR IN "
			.. fileName
			.. ": "
			.. tostring(scriptContent)
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

	local fn,compileError =
		loadstring(scriptContent)

	if not fn then
		warn(
			"[MM2 LOADER] COMPILE ERROR IN "
			.. fileName
			.. ": "
			.. tostring(compileError)
		)

		return false
	end

	--========================================================
	-- EXECUTE
	--========================================================

	local runOk,runResult = pcall(fn)

	if not runOk then
		warn(
			"[MM2 LOADER] RUNTIME ERROR IN "
			.. fileName
			.. ": "
			.. tostring(runResult)
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
-- LOAD ORDER
--============================================================

LoadModule("Shared.lua")
LoadModule("UI.lua")
LoadModule("Visuals.lua")
LoadModule("Combat.lua")
LoadModule("AutoFarm.lua")
LoadModule("Player.lua")
LoadModule("Fling.lua")
LoadModule("Misc.lua")
LoadModule("Skinchanger.lua")
LoadModule("Main.lua")

--============================================================
-- FINAL STATUS
--============================================================

local MM2 =
	(getgenv and getgenv().MM2_V85_SPLIT)
	or _G.MM2_V85_SPLIT

if MM2 and MM2.Running then
	print(
		"[MM2 LOADER] Blizzard MM2 V8.8.4 bootstrap COMPLETE."
	)
else
	warn(
		"[MM2 LOADER] Bootstrap finished, but MM2 runtime was not detected."
	)
end