--============================================================
-- Blizzard MM2 V8.8.4 - Misc.lua
-- WindUI-compatible Misc module.
--
-- Sections:
--   Appearance
--   Server
--   Config
--   UI
--
-- Fixes:
--   * Theme dropdown uses the WindUI bridge.
--   * Theme control appears inside Appearance.
--   * Cyber Neon is a real custom theme.
--   * Summer Event is the factory/default theme.
--============================================================

local MM2 = getgenv and getgenv().MM2_V85_SPLIT or _G.MM2_V85_SPLIT

assert(
	MM2
	and MM2.UI
	and MM2.UI.MiscPage,
	"Load Shared.lua + the WindUI UI.lua first"
)

--============================================================
-- SERVICES
--============================================================

local LocalPlayer = MM2.LocalPlayer
local UI = MM2.UI
local Flags = MM2.Flags
local Track = MM2.Track

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local VirtualUser = game:GetService("VirtualUser")

--============================================================
-- DEFAULT FLAGS
--============================================================

Flags.Theme =
	typeof(Flags.Theme) == "string"
	and Flags.Theme
	or "Summer Event"

Flags.AntiAFK = Flags.AntiAFK == true
Flags.AntiDisconnect = Flags.AntiDisconnect == true
Flags.AutoSaveConfig = Flags.AutoSaveConfig == true

--============================================================
-- CONFIG
--============================================================

local CONFIG_FOLDER = "BlizzardMenu"
local CONFIG_FILE = CONFIG_FOLDER .. "/config.json"

local ConfigBusy = false
local LastConfigSnapshot = nil

--============================================================
-- HELPERS
--============================================================

local function CopyTable(source)
	local result = {}

	for key, value in pairs(source) do
		if type(value) == "table" then
			result[key] = CopyTable(value)
		else
			result[key] = value
		end
	end

	return result
end

local DefaultFlags = CopyTable(Flags)
local DefaultPlayerSettings = CopyTable(MM2.PlayerSettings or {})

--============================================================
-- THEMES
--============================================================

local ThemeOrder = {
	"Dark",
	"Summer Event",
	"Ocean Blue",
	"Crimson",
	"Midnight Purple",
	"Emerald",
	"Rose Pink",
	"Cyber Neon",
	"Arctic",
	"Sunset",
}

local WindThemeMap = {
	["Dark"] = "Dark",
	["Summer Event"] = "Amber",
	["Ocean Blue"] = "Sky",
	["Crimson"] = "Crimson",
	["Midnight Purple"] = "Violet",
	["Emerald"] = "Emerald",
	["Rose Pink"] = "Rose",

	-- Custom theme
	["Cyber Neon"] = "Cyber Neon",

	["Arctic"] = "Light",
	["Sunset"] = "Amber",
}

--============================================================
-- CUSTOM CYBER NEON THEME
--============================================================

if UI.WindUI and UI.WindUI.AddTheme then
	pcall(function()
		UI.WindUI:AddTheme({
			Name = "Cyber Neon",

			-- Main cyan accent
			Accent = "#00F0FF",

			-- Dark purple/black dialog areas
			Dialog = "#13051F",

			-- Bright neon cyan outlines
			Outline = "#00F0FF",

			-- Main text
			Text = "#F6F4FF",

			-- Secondary text
			Placeholder = "#B58ACF",

			-- Main background
			Background = "#07070D",

			-- Hot-magenta controls/buttons
			Button = "#FF0080",

			-- Neon purple icons
			Icon = "#B000FF",
		})
	end)
end

local ThemeDropdown = nil
local ApplyingTheme = false

local function ApplyTheme(themeName)
	if typeof(themeName) ~= "string"
		or not WindThemeMap[themeName]
	then
		themeName = "Summer Event"
	end

	Flags.Theme = themeName

	local windTheme =
		WindThemeMap[themeName]
		or "Amber"

	if UI.WindUI
		and UI.WindUI.SetTheme
	then
		local success,err =
			pcall(function()
				UI.WindUI:SetTheme(
					windTheme
				)
			end)

		if not success then
			warn(
				"[Blizzard Misc] Theme failed:",
				themeName,
				windTheme,
				err
			)

			return false
		end
	end

	return true
end

MM2.Functions.ApplyTheme = ApplyTheme

--============================================================
-- APPEARANCE
--============================================================

UI.AddSection(
	UI.MiscPage,
	"Appearance",
	"Customize the Blizzard MM2 interface"
)

ThemeDropdown =
	UI.CreateDropdown(
		UI.MiscPage,
		"Theme",
		"Choose your menu color theme",
		ThemeOrder,
		Flags.Theme,
		function(value)

			if ApplyingTheme then
				return
			end

			if typeof(value) == "string" then
				ApplyTheme(value)
			end
		end
	)

--============================================================
-- SERVER
--============================================================

UI.AddSection(
	UI.MiscPage,
	"Server",
	"Session and server utilities"
)

--============================================================
-- ANTI-AFK
--============================================================

local AntiAFKConnection = nil

local function SetAntiAFK(on)
	if AntiAFKConnection then
		AntiAFKConnection:Disconnect()
		AntiAFKConnection = nil
	end

	if not on then
		return
	end

	AntiAFKConnection = LocalPlayer.Idled:Connect(function()
		if not Flags.AntiAFK then
			return
		end

		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new(0,0))
		end)
	end)

	Track(AntiAFKConnection)
end

UI.CreateToggle(
	UI.MiscPage,
	"Anti-AFK",
	"Prevents the normal inactivity timeout",
	"AntiAFK",
	SetAntiAFK
)

--============================================================
-- ANTI DISCONNECT / REJOIN
--============================================================

local ReconnectBusy = false

local function RejoinCurrentPlace()
	if ReconnectBusy then
		return false
	end

	ReconnectBusy = true

	local success = pcall(function()
		if game.JobId and game.JobId ~= "" then
			TeleportService:TeleportToPlaceInstance(
				game.PlaceId,
				game.JobId,
				LocalPlayer
			)
		else
			TeleportService:Teleport(
				game.PlaceId,
				LocalPlayer
			)
		end
	end)

	task.delay(5, function()
		ReconnectBusy = false
	end)

	return success
end

MM2.Functions.RejoinServer = RejoinCurrentPlace

local LastDisconnectMessage = ""

Track(GuiService.ErrorMessageChanged:Connect(function(message)
	if not Flags.AntiDisconnect then
		return
	end

	if typeof(message) ~= "string" or message == "" then
		return
	end

	if message == LastDisconnectMessage then
		return
	end

	LastDisconnectMessage = message

	task.delay(1, function()
		if Flags.AntiDisconnect then
			RejoinCurrentPlace()
		end
	end)
end))

UI.CreateToggle(
	UI.MiscPage,
	"Anti Disconnect",
	"Attempts to rejoin if the client detects a disconnect",
	"AntiDisconnect"
)

UI.CreateActionFeature(
	UI.MiscPage,
	"Rejoin Server",
	"Reconnect to the current server",
	function()
		RejoinCurrentPlace()
	end
)

--============================================================
-- SERVER HOP
--============================================================

local ServerHopBusy = false

local function GetServerList(cursor)
	local url =
		"https://games.roblox.com/v1/games/"
		.. tostring(game.PlaceId)
		.. "/servers/Public?sortOrder=Asc&limit=100"

	if cursor and cursor ~= "" then
		url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
	end

	local body = nil

	local ok = pcall(function()
		if game.HttpGet then
			body = game:HttpGet(url)
		else
			body = HttpService:GetAsync(url)
		end
	end)

	if not ok or not body then
		return nil
	end

	local decoded = nil

	local decodeOK = pcall(function()
		decoded = HttpService:JSONDecode(body)
	end)

	if not decodeOK then
		return nil
	end

	return decoded
end

local function FindHopServer()
	local cursor = nil
	local pagesChecked = 0

	repeat
		local response = GetServerList(cursor)

		if not response then
			return nil
		end

		for _, server in ipairs(response.data or {}) do
			if server.id ~= game.JobId
				and tonumber(server.playing)
				and tonumber(server.maxPlayers)
				and server.playing < server.maxPlayers
			then
				return server.id
			end
		end

		cursor = response.nextPageCursor
		pagesChecked += 1
	until not cursor or pagesChecked >= 5

	return nil
end

local function ServerHop()
	if ServerHopBusy then
		return false
	end

	ServerHopBusy = true

	task.spawn(function()
		local serverId = FindHopServer()

		if serverId then
			pcall(function()
				TeleportService:TeleportToPlaceInstance(
					game.PlaceId,
					serverId,
					LocalPlayer
				)
			end)
		else
			pcall(function()
				TeleportService:Teleport(
					game.PlaceId,
					LocalPlayer
				)
			end)
		end

		task.delay(5, function()
			ServerHopBusy = false
		end)
	end)

	return true
end

MM2.Functions.ServerHop = ServerHop

UI.CreateActionFeature(
	UI.MiscPage,
	"Server Hop",
	"Join another public server",
	function()
		ServerHop()
	end
)

--============================================================
-- CONFIG
--============================================================

UI.AddSection(
	UI.MiscPage,
	"Config",
	"Save and restore menu settings"
)

local function ConfigValueSupported(value)
	local valueType = typeof(value)

	return valueType == "boolean"
		or valueType == "number"
		or valueType == "string"
end

local function BuildConfig()
	local config = {
		Version = "8.8.4",
		Flags = {},
		PlayerSettings = {},
	}

	for key, value in pairs(Flags) do
		if ConfigValueSupported(value) then
			config.Flags[key] = value
		end
	end

	if MM2.PlayerSettings then
		for key, value in pairs(MM2.PlayerSettings) do
			if ConfigValueSupported(value) then
				config.PlayerSettings[key] = value
			end
		end
	end

	return config
end

local function EnsureConfigFolder()
	if not makefolder or not isfolder then
		return
	end

	if not isfolder(CONFIG_FOLDER) then
		pcall(makefolder, CONFIG_FOLDER)
	end
end

local function SaveConfig()
	if ConfigBusy then
		return false
	end

	if not writefile then
		return false
	end

	ConfigBusy = true
	EnsureConfigFolder()

	local config = BuildConfig()

	local success = pcall(function()
		local encoded = HttpService:JSONEncode(config)

		writefile(
			CONFIG_FILE,
			encoded
		)

		LastConfigSnapshot = encoded
	end)

	ConfigBusy = false
	return success
end

MM2.Functions.SaveConfig = SaveConfig

--============================================================
-- LOAD CONFIG
--============================================================

local function LoadConfig()
	if not isfile
		or not readfile
		or not isfile(CONFIG_FILE)
	then
		return false
	end

	local success = pcall(function()
		local raw = readfile(CONFIG_FILE)
		local data = HttpService:JSONDecode(raw)

		if type(data.Flags) == "table" then
			for key, value in pairs(data.Flags) do
				if ConfigValueSupported(value) then
					Flags[key] = value
				end
			end
		end

		if type(data.PlayerSettings) == "table"
			and MM2.PlayerSettings
		then
			for key, value in pairs(data.PlayerSettings) do
				if ConfigValueSupported(value) then
					MM2.PlayerSettings[key] = value
				end
			end
		end
	end)

	if success then
		ApplyTheme(Flags.Theme or "Summer Event")

		if UI.SetToggleState then
			for key, value in pairs(Flags) do
				if typeof(value) == "boolean" then
					pcall(
						UI.SetToggleState,
						key,
						value,
						true
					)
				end
			end
		end

		SetAntiAFK(Flags.AntiAFK)

		if ThemeDropdown then
			ApplyingTheme = true

			pcall(function()
				if ThemeDropdown.Select then
					ThemeDropdown:Select(
						Flags.Theme or "Summer Event"
					)
				elseif ThemeDropdown.Set then
					ThemeDropdown:Set(
						Flags.Theme or "Summer Event"
					)
				end
			end)

			ApplyingTheme = false
		end
	end

	return success
end

MM2.Functions.LoadConfig = LoadConfig

--============================================================
-- RESET CONFIG
--============================================================

local function ResetConfig()
	if ConfigBusy then
		return false
	end

	ConfigBusy = true

	Flags.AutoSaveConfig = false

	if delfile
		and isfile
		and isfile(CONFIG_FILE)
	then
		pcall(delfile, CONFIG_FILE)
	end

	for key, value in pairs(DefaultFlags) do
		Flags[key] = value
	end

	if MM2.PlayerSettings then
		for key, value in pairs(DefaultPlayerSettings) do
			MM2.PlayerSettings[key] = value
		end
	end

	if UI.SetToggleState then
		for key, value in pairs(DefaultFlags) do
			if typeof(value) == "boolean" then
				pcall(
					UI.SetToggleState,
					key,
					value,
					true
				)
			end
		end
	end

	local character = LocalPlayer.Character
	local humanoid =
		character
		and character:FindFirstChildOfClass("Humanoid")

	if humanoid then
		if DefaultPlayerSettings.WalkSpeed then
			humanoid.WalkSpeed =
				DefaultPlayerSettings.WalkSpeed
		end

		if DefaultPlayerSettings.JumpPower then
			humanoid.JumpPower =
				DefaultPlayerSettings.JumpPower
		end
	end

	SetAntiAFK(false)

	-- Factory theme is now Summer Event.
	Flags.Theme = "Summer Event"
	ApplyTheme("Summer Event")

	if ThemeDropdown then
		ApplyingTheme = true

		pcall(function()
			if ThemeDropdown.Select then
				ThemeDropdown:Select(
					"Summer Event"
				)
			elseif ThemeDropdown.Set then
				ThemeDropdown:Set(
					"Summer Event"
				)
			end
		end)

		ApplyingTheme = false
	end

	LastConfigSnapshot = nil
	ConfigBusy = false

	return true
end

MM2.Functions.ResetConfig = ResetConfig

--============================================================
-- CONFIG UI
--============================================================

UI.CreateToggle(
	UI.MiscPage,
	"Auto Save Config",
	"Automatically saves when settings change",
	"AutoSaveConfig"
)

UI.CreateActionFeature(
	UI.MiscPage,
	"Save Current Config",
	"Save your current menu settings",
	function()
		SaveConfig()
	end
)

UI.CreateActionFeature(
	UI.MiscPage,
	"Reset Config",
	"Restore the default configuration",
	function()
		ResetConfig()
	end
)

--============================================================
-- AUTO SAVE WATCHER
--============================================================

task.spawn(function()
	while MM2.Running do
		task.wait(1)

		if Flags.AutoSaveConfig and writefile then
			local currentConfig = BuildConfig()
			local encoded = nil

			local ok = pcall(function()
				encoded =
					HttpService:JSONEncode(
						currentConfig
					)
			end)

			if ok
				and encoded
				and encoded ~= LastConfigSnapshot
			then
				SaveConfig()
			end
		end
	end
end)

--============================================================
-- UI
--============================================================

UI.AddSection(
	UI.MiscPage,
	"UI",
	"Menu controls"
)

local function HideMenu()
	local window =
		UI.Window
		or UI.MainFrame

	if not window then
		return false
	end

	local success = pcall(function()
		if window.Toggle then
			window:Toggle()
		elseif window.Close then
			window:Close()
		end
	end)

	return success
end

MM2.Functions.HideMenu = HideMenu

UI.CreateActionFeature(
	UI.MiscPage,
	"Hide Menu",
	"Hide the main menu",
	function()
		HideMenu()
	end
)

--============================================================
-- UNLOAD
--============================================================

local function UnloadMenu()
	MM2.Running = false

	if MM2.Functions.StopAutoFarm then
		pcall(
			MM2.Functions.StopAutoFarm
		)
	end

	if MM2.Functions.StopFly then
		pcall(
			MM2.Functions.StopFly
		)
	end

	if MM2.Functions.StopPlayerNoclip then
		pcall(
			MM2.Functions.StopPlayerNoclip
		)
	end

	if Flags.AutoSaveConfig then
		pcall(
			SaveConfig
		)
	end

	if MM2.Functions.Unload then
		pcall(
			MM2.Functions.Unload
		)

		return
	end

	if UI.Window then
		pcall(function()
			UI.Window:Destroy()
		end)
	end

	for _, gui in ipairs({
		UI.ScreenGui,
		UI.OverlayGui,
		UI.TracerGui,
		UI.Gui,
	}) do
		if typeof(gui) == "Instance"
			and gui.Parent
		then
			pcall(function()
				gui:Destroy()
			end)
		end
	end
end

MM2.Functions.UnloadMenu = UnloadMenu

UI.CreateActionFeature(
	UI.MiscPage,
	"Unload",
	"Disable features and remove the menu",
	function()
		UnloadMenu()
	end
)

--============================================================
-- INITIALIZE
--============================================================

local loadedConfig =
	LoadConfig()

if not loadedConfig then
	ApplyTheme(
		Flags.Theme
		or "Summer Event"
	)
end

if ThemeDropdown then
	ApplyingTheme = true

	pcall(function()
		if ThemeDropdown.Select then
			ThemeDropdown:Select(
				Flags.Theme
				or "Summer Event"
			)
		elseif ThemeDropdown.Set then
			ThemeDropdown:Set(
				Flags.Theme
				or "Summer Event"
			)
		end
	end)

	ApplyingTheme = false
end

if Flags.AntiAFK then
	SetAntiAFK(true)
end

return MM2