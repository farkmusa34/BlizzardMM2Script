--============================================================
-- MM2 V8.8.4 - Misc.lua
--
-- Sections:
--   Appearance
--   Server
--   Config
--   UI
--
-- Features:
-- - Theme selector
-- - 10 built-in themes
-- - Anti-AFK
-- - Anti Disconnect / reconnect attempt
-- - Rejoin Server
-- - Server Hop
-- - Auto Save Config
-- - Save Current Config
-- - Reset Config
-- - Hide Menu
-- - Unload
--
-- Requires:
--   MM2.UI.MiscPage
--============================================================

local MM2 = getgenv and getgenv().MM2_V85_SPLIT or _G.MM2_V85_SPLIT

assert(
	MM2
	and MM2.UI
	and MM2.UI.MiscPage,
	"Load Shared.lua + UI.lua with MiscPage support first"
)

--============================================================
-- SERVICES
--============================================================

local Players = MM2.Services.Players
local RunService = MM2.Services.RunService
local UIS = MM2.Services.UserInputService

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
	or "Dark"

Flags.AntiAFK =
	Flags.AntiAFK == true

Flags.AntiDisconnect =
	Flags.AntiDisconnect == true

Flags.AutoSaveConfig =
	Flags.AutoSaveConfig == true

--============================================================
-- CONFIG
--============================================================

local CONFIG_FOLDER = "BlizzardMenu"
local CONFIG_FILE = CONFIG_FOLDER .. "/config.json"

local ConfigBusy = false
local LastConfigSnapshot = nil

--============================================================
-- INTERNAL HELPERS
--============================================================

local function SafeCall(callback,...)
	local ok,result =
		pcall(callback,...)

	return ok,result
end

local function Color(r,g,b)
	return Color3.fromRGB(r,g,b)
end

local function CopyTable(source)
	local result = {}

	for key,value in pairs(source) do
		if type(value) == "table" then
			result[key] =
				CopyTable(value)
		else
			result[key] = value
		end
	end

	return result
end

--============================================================
-- FACTORY DEFAULT SNAPSHOT
--============================================================

local DefaultFlags =
	CopyTable(Flags)

local DefaultPlayerSettings =
	CopyTable(
		MM2.PlayerSettings or {}
	)

--============================================================
-- THEMES
--============================================================

local Themes = {

	["Dark"] = {
		Background = Color(10,11,16),
		Sidebar = Color(13,14,20),
		Card = Color(18,19,27),
		CardHover = Color(23,24,34),

		Stroke = Color(47,50,66),

		Accent = Color(79,195,247),
		Accent2 = Color(54,156,214),

		Text = Color(240,242,248),
		Muted = Color(145,150,165),

		Danger = Color(240,72,72),
	},

	["Summer Event"] = {
		Background = Color(25,20,14),
		Sidebar = Color(34,27,17),
		Card = Color(44,34,21),
		CardHover = Color(55,42,25),

		Stroke = Color(111,82,40),

		Accent = Color(255,190,70),
		Accent2 = Color(255,111,74),

		Text = Color(255,247,224),
		Muted = Color(217,186,139),

		Danger = Color(255,89,89),
	},

	["Ocean Blue"] = {
		Background = Color(6,18,30),
		Sidebar = Color(8,25,40),
		Card = Color(10,33,52),
		CardHover = Color(13,43,66),

		Stroke = Color(29,78,105),

		Accent = Color(53,190,255),
		Accent2 = Color(32,131,214),

		Text = Color(229,247,255),
		Muted = Color(135,182,205),

		Danger = Color(246,84,96),
	},

	["Crimson"] = {
		Background = Color(20,8,12),
		Sidebar = Color(29,10,16),
		Card = Color(39,13,21),
		CardHover = Color(52,17,27),

		Stroke = Color(100,36,49),

		Accent = Color(238,54,78),
		Accent2 = Color(185,31,55),

		Text = Color(255,235,239),
		Muted = Color(198,137,148),

		Danger = Color(255,84,84),
	},

	["Midnight Purple"] = {
		Background = Color(12,8,24),
		Sidebar = Color(18,11,34),
		Card = Color(25,15,45),
		CardHover = Color(34,20,59),

		Stroke = Color(68,44,103),

		Accent = Color(154,92,255),
		Accent2 = Color(111,63,212),

		Text = Color(244,237,255),
		Muted = Color(166,144,193),

		Danger = Color(240,78,104),
	},

	["Emerald"] = {
		Background = Color(7,20,16),
		Sidebar = Color(9,28,22),
		Card = Color(12,38,29),
		CardHover = Color(15,49,37),

		Stroke = Color(34,91,66),

		Accent = Color(47,211,139),
		Accent2 = Color(28,158,99),

		Text = Color(232,255,246),
		Muted = Color(138,193,169),

		Danger = Color(244,80,88),
	},

	["Rose Pink"] = {
		Background = Color(25,10,20),
		Sidebar = Color(35,13,28),
		Card = Color(47,17,37),
		CardHover = Color(60,22,47),

		Stroke = Color(104,46,82),

		Accent = Color(255,105,180),
		Accent2 = Color(216,70,143),

		Text = Color(255,239,249),
		Muted = Color(207,151,185),

		Danger = Color(255,75,99),
	},

	["Cyber Neon"] = {
		Background = Color(4,8,13),
		Sidebar = Color(5,13,20),
		Card = Color(7,20,29),
		CardHover = Color(9,30,40),

		Stroke = Color(20,90,99),

		Accent = Color(0,255,220),
		Accent2 = Color(77,108,255),

		Text = Color(229,255,252),
		Muted = Color(116,180,178),

		Danger = Color(255,45,103),
	},

	["Arctic"] = {
		Background = Color(14,22,29),
		Sidebar = Color(18,29,38),
		Card = Color(23,39,50),
		CardHover = Color(29,49,62),

		Stroke = Color(73,106,126),

		Accent = Color(128,224,255),
		Accent2 = Color(77,171,218),

		Text = Color(244,252,255),
		Muted = Color(164,194,207),

		Danger = Color(238,89,105),
	},

	["Sunset"] = {
		Background = Color(27,12,24),
		Sidebar = Color(37,16,31),
		Card = Color(49,21,38),
		CardHover = Color(63,27,47),

		Stroke = Color(112,56,74),

		Accent = Color(255,139,82),
		Accent2 = Color(223,79,116),

		Text = Color(255,241,232),
		Muted = Color(213,161,153),

		Danger = Color(255,68,79),
	},
}

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

--============================================================
-- THEME ENGINE
--============================================================

local function BuildThemeFromCurrent(theme)
	local result = {}

	for key,value in pairs(UI.COLORS) do
		result[key] = value
	end

	for key,value in pairs(theme) do
		result[key] = value
	end

	return result
end

local function ApplyTheme(themeName)
	local selected =
		Themes[themeName]

	if not selected then
		themeName = "Dark"
		selected = Themes.Dark
	end

	local oldColors = {}

	for key,value in pairs(UI.COLORS) do
		if typeof(value) == "Color3" then
			oldColors[key] = value
		end
	end

	local finalTheme =
		BuildThemeFromCurrent(selected)

	for key,value in pairs(finalTheme) do
		if UI.COLORS[key] ~= nil
			and typeof(value) == "Color3"
		then
			UI.COLORS[key] = value
		end
	end

	local gui =
		UI.ScreenGui
		or UI.Gui
		or UI.TracerGui

	if gui then
		for _,object in ipairs(gui:GetDescendants()) do

			if object:IsA("GuiObject") then
				for key,oldColor in pairs(oldColors) do
					local newColor =
						finalTheme[key]

					if newColor
						and typeof(newColor) == "Color3"
						and object.BackgroundColor3 == oldColor
					then
						object.BackgroundColor3 =
							newColor
					end
				end
			end

			if object:IsA("TextLabel")
				or object:IsA("TextButton")
				or object:IsA("TextBox")
			then
				for key,oldColor in pairs(oldColors) do
					local newColor =
						finalTheme[key]

					if newColor
						and typeof(newColor) == "Color3"
						and object.TextColor3 == oldColor
					then
						object.TextColor3 =
							newColor
					end
				end
			end

			if object:IsA("ImageLabel")
				or object:IsA("ImageButton")
			then
				for key,oldColor in pairs(oldColors) do
					local newColor =
						finalTheme[key]

					if newColor
						and typeof(newColor) == "Color3"
						and object.ImageColor3 == oldColor
					then
						object.ImageColor3 =
							newColor
					end
				end
			end

			if object:IsA("UIStroke") then
				for key,oldColor in pairs(oldColors) do
					local newColor =
						finalTheme[key]

					if newColor
						and typeof(newColor) == "Color3"
						and object.Color == oldColor
					then
						object.Color =
							newColor
					end
				end
			end

			if object:IsA("ScrollingFrame") then
				for key,oldColor in pairs(oldColors) do
					local newColor =
						finalTheme[key]

					if newColor
						and typeof(newColor) == "Color3"
						and object.ScrollBarImageColor3 == oldColor
					then
						object.ScrollBarImageColor3 =
							newColor
					end
				end
			end
		end
	end

	Flags.Theme = themeName

	return true
end

MM2.Functions.ApplyTheme = ApplyTheme

--============================================================
-- APPEARANCE SECTION
--============================================================

UI.AddSection(
	UI.MiscPage,
	"Appearance",
	"Customize the menu appearance"
)

--============================================================
-- THEME DROPDOWN
--============================================================

local ThemeCard = Instance.new("Frame")
ThemeCard.Name = "ThemeSelector"

ThemeCard.Size =
	UDim2.new(1,0,0,50)

ThemeCard.BackgroundColor3 =
	UI.COLORS.Card

ThemeCard.BorderSizePixel = 0
ThemeCard.ClipsDescendants = false
ThemeCard.ZIndex = 20
ThemeCard.Parent = UI.MiscPage

local ThemeCorner =
	Instance.new("UICorner")

ThemeCorner.CornerRadius =
	UDim.new(0,11)

ThemeCorner.Parent =
	ThemeCard

local ThemeStroke =
	Instance.new("UIStroke")

ThemeStroke.Color =
	UI.COLORS.Stroke

ThemeStroke.Transparency = 0.45
ThemeStroke.Parent = ThemeCard

local ThemeTitle =
	Instance.new("TextLabel")

ThemeTitle.Size =
	UDim2.new(0.55,0,0,18)

ThemeTitle.Position =
	UDim2.fromOffset(14,6)

ThemeTitle.BackgroundTransparency = 1
ThemeTitle.Text = "Theme"
ThemeTitle.TextXAlignment =
	Enum.TextXAlignment.Left

ThemeTitle.TextColor3 =
	UI.COLORS.Text

ThemeTitle.TextSize = 12
ThemeTitle.Font = Enum.Font.GothamBold
ThemeTitle.ZIndex = 21
ThemeTitle.Parent = ThemeCard

local ThemeDescription =
	Instance.new("TextLabel")

ThemeDescription.Size =
	UDim2.new(0.55,0,0,14)

ThemeDescription.Position =
	UDim2.fromOffset(14,27)

ThemeDescription.BackgroundTransparency = 1

ThemeDescription.Text =
	"Choose your menu color theme"

ThemeDescription.TextXAlignment =
	Enum.TextXAlignment.Left

ThemeDescription.TextColor3 =
	UI.COLORS.Muted

ThemeDescription.TextSize = 10
ThemeDescription.Font = Enum.Font.Gotham
ThemeDescription.ZIndex = 21
ThemeDescription.Parent = ThemeCard

local ThemeButton =
	Instance.new("TextButton")

ThemeButton.Name = "ThemeButton"

ThemeButton.Size =
	UDim2.fromOffset(136,28)

ThemeButton.Position =
	UDim2.new(
		1,-150,
		0.5,-14
	)

ThemeButton.BackgroundColor3 =
	UI.COLORS.Background

ThemeButton.BorderSizePixel = 0

ThemeButton.Text =
	Flags.Theme .. "  ▼"

ThemeButton.TextColor3 =
	UI.COLORS.Text

ThemeButton.TextSize = 10
ThemeButton.Font = Enum.Font.GothamMedium

ThemeButton.AutoButtonColor = false
ThemeButton.ZIndex = 23
ThemeButton.Parent = ThemeCard

local ThemeButtonCorner =
	Instance.new("UICorner")

ThemeButtonCorner.CornerRadius =
	UDim.new(0,8)

ThemeButtonCorner.Parent =
	ThemeButton

local ThemeButtonStroke =
	Instance.new("UIStroke")

ThemeButtonStroke.Color =
	UI.COLORS.Stroke

ThemeButtonStroke.Transparency = 0.25
ThemeButtonStroke.Parent = ThemeButton

--============================================================
-- DROPDOWN PANEL
--============================================================

local ThemeDropdown =
	Instance.new("Frame")

ThemeDropdown.Name =
	"ThemeDropdown"

ThemeDropdown.Size =
	UDim2.fromOffset(
		190,
		10 * 29 + 10
	)

ThemeDropdown.Position =
	UDim2.new(
		1,-204,
		1,5
	)

ThemeDropdown.BackgroundColor3 =
	UI.COLORS.Card

ThemeDropdown.BorderSizePixel = 0
ThemeDropdown.Visible = false
ThemeDropdown.ZIndex = 100
ThemeDropdown.Parent = ThemeCard

local DropdownCorner =
	Instance.new("UICorner")

DropdownCorner.CornerRadius =
	UDim.new(0,9)

DropdownCorner.Parent =
	ThemeDropdown

local DropdownStroke =
	Instance.new("UIStroke")

DropdownStroke.Color =
	UI.COLORS.Stroke

DropdownStroke.Transparency = 0.15
DropdownStroke.Parent = ThemeDropdown

local DropdownPadding =
	Instance.new("UIPadding")

DropdownPadding.PaddingTop =
	UDim.new(0,5)

DropdownPadding.PaddingBottom =
	UDim.new(0,5)

DropdownPadding.PaddingLeft =
	UDim.new(0,5)

DropdownPadding.PaddingRight =
	UDim.new(0,5)

DropdownPadding.Parent =
	ThemeDropdown

local DropdownLayout =
	Instance.new("UIListLayout")

DropdownLayout.Padding =
	UDim.new(0,3)

DropdownLayout.SortOrder =
	Enum.SortOrder.LayoutOrder

DropdownLayout.Parent =
	ThemeDropdown

local ThemeDropdownOpen = false

local function SetThemeDropdown(open)
	ThemeDropdownOpen = open
	ThemeDropdown.Visible = open

	ThemeButton.Text =
		Flags.Theme
		..
		(open and "  ▲" or "  ▼")
end

for index,themeName in ipairs(ThemeOrder) do

	local option =
		Instance.new("TextButton")

	option.Name =
		themeName

	option.LayoutOrder = index

	option.Size =
		UDim2.new(1,0,0,26)

	option.BackgroundColor3 =
		UI.COLORS.Background

	option.BackgroundTransparency = 0.15
	option.BorderSizePixel = 0

	option.Text =
		themeName

	option.TextXAlignment =
		Enum.TextXAlignment.Left

	option.TextColor3 =
		UI.COLORS.Text

	option.TextSize = 10
	option.Font = Enum.Font.GothamMedium

	option.AutoButtonColor = false
	option.ZIndex = 101
	option.Parent = ThemeDropdown

	local padding =
		Instance.new("UIPadding")

	padding.PaddingLeft =
		UDim.new(0,9)

	padding.Parent = option

	local corner =
		Instance.new("UICorner")

	corner.CornerRadius =
		UDim.new(0,6)

	corner.Parent = option

	option.MouseEnter:Connect(function()
		option.BackgroundTransparency =
			0
	end)

	option.MouseLeave:Connect(function()
		option.BackgroundTransparency =
			0.15
	end)

	option.Activated:Connect(function()
		ApplyTheme(themeName)

		ThemeButton.Text =
			themeName .. "  ▼"

		SetThemeDropdown(false)
	end)
end

ThemeButton.Activated:Connect(function()
	SetThemeDropdown(
		not ThemeDropdownOpen
	)
end)

--============================================================
-- SERVER SECTION
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

	AntiAFKConnection =
		LocalPlayer.Idled:Connect(function()

			if not Flags.AntiAFK then
				return
			end

			pcall(function()

				VirtualUser:CaptureController()

				VirtualUser:ClickButton2(
					Vector2.new(0,0)
				)

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
-- ANTI DISCONNECT
--============================================================

local ReconnectBusy = false

local function RejoinCurrentPlace()
	if ReconnectBusy then
		return false
	end

	ReconnectBusy = true

	local success =
		pcall(function()

			if game.JobId
				and game.JobId ~= ""
			then
				TeleportService:
					TeleportToPlaceInstance(
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

	task.delay(5,function()
		ReconnectBusy = false
	end)

	return success
end

MM2.Functions.RejoinServer =
	RejoinCurrentPlace

local LastDisconnectMessage = ""

Track(
	GuiService.ErrorMessageChanged:Connect(
		function(message)

			if not Flags.AntiDisconnect then
				return
			end

			if typeof(message) ~= "string"
				or message == ""
			then
				return
			end

			if message == LastDisconnectMessage then
				return
			end

			LastDisconnectMessage = message

			task.delay(1,function()

				if Flags.AntiDisconnect then
					RejoinCurrentPlace()
				end

			end)
		end
	)
)

UI.CreateToggle(
	UI.MiscPage,
	"Anti Disconnect",
	"Attempts to rejoin if the client detects a disconnect",
	"AntiDisconnect"
)

--============================================================
-- REJOIN SERVER
--============================================================

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
		..
		tostring(game.PlaceId)
		..
		"/servers/Public?sortOrder=Asc&limit=100"

	if cursor
		and cursor ~= ""
	then
		url =
			url
			..
			"&cursor="
			..
			HttpService:UrlEncode(cursor)
	end

	local body = nil

	local ok =
		pcall(function()

			if game.HttpGet then
				body =
					game:HttpGet(url)
			else
				body =
					HttpService:GetAsync(url)
			end

		end)

	if not ok
		or not body
	then
		return nil
	end

	local decoded = nil

	local decodeOK =
		pcall(function()
			decoded =
				HttpService:JSONDecode(body)
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

		local response =
			GetServerList(cursor)

		if not response then
			return nil
		end

		for _,server in ipairs(
			response.data or {}
		) do

			if server.id ~= game.JobId
				and tonumber(server.playing)
				and tonumber(server.maxPlayers)
				and server.playing
					< server.maxPlayers
			then
				return server.id
			end
		end

		cursor =
			response.nextPageCursor

		pagesChecked += 1

	until not cursor
		or pagesChecked >= 5

	return nil
end

local function ServerHop()

	if ServerHopBusy then
		return false
	end

	ServerHopBusy = true

	task.spawn(function()

		local serverId =
			FindHopServer()

		if serverId then

			pcall(function()

				TeleportService:
					TeleportToPlaceInstance(
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

		task.delay(5,function()
			ServerHopBusy = false
		end)

	end)

	return true
end

MM2.Functions.ServerHop =
	ServerHop

UI.CreateActionFeature(
	UI.MiscPage,
	"Server Hop",
	"Join another public server",
	function()
		ServerHop()
	end
)

--============================================================
-- CONFIG SECTION
--============================================================

UI.AddSection(
	UI.MiscPage,
	"Config",
	"Save and restore menu settings"
)

--============================================================
-- CONFIG SERIALIZATION
--============================================================

local function ConfigValueSupported(value)

	local valueType =
		typeof(value)

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

	for key,value in pairs(Flags) do

		if ConfigValueSupported(value) then
			config.Flags[key] = value
		end

	end

	if MM2.PlayerSettings then

		for key,value in pairs(
			MM2.PlayerSettings
		) do

			if ConfigValueSupported(value) then
				config.PlayerSettings[key] =
					value
			end

		end
	end

	return config
end

local function EnsureConfigFolder()

	if not makefolder
		or not isfolder
	then
		return
	end

	if not isfolder(CONFIG_FOLDER) then
		pcall(
			makefolder,
			CONFIG_FOLDER
		)
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

	local config =
		BuildConfig()

	local success =
		pcall(function()

			local encoded =
				HttpService:JSONEncode(
					config
				)

			writefile(
				CONFIG_FILE,
				encoded
			)

			LastConfigSnapshot =
				encoded

		end)

	ConfigBusy = false

	return success
end

MM2.Functions.SaveConfig =
	SaveConfig

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

	local success =
		pcall(function()

			local raw =
				readfile(CONFIG_FILE)

			local data =
				HttpService:JSONDecode(raw)

			if type(data.Flags)
				== "table"
			then

				for key,value in pairs(
					data.Flags
				) do

					if ConfigValueSupported(value) then
						Flags[key] = value
					end

				end
			end

			if type(data.PlayerSettings)
				== "table"
				and MM2.PlayerSettings
			then

				for key,value in pairs(
					data.PlayerSettings
				) do

					if ConfigValueSupported(value) then
						MM2.PlayerSettings[key] =
							value
					end

				end
			end

		end)

	if success then

		ApplyTheme(
			Flags.Theme or "Dark"
		)

		if UI.SetToggleState then

			for key,value in pairs(Flags) do

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

		SetAntiAFK(
			Flags.AntiAFK
		)

	end

	return success
end

MM2.Functions.LoadConfig =
	LoadConfig

--============================================================
-- RESET CONFIG
--============================================================

local function ResetConfig()

	if ConfigBusy then
		return false
	end

	ConfigBusy = true

	-- Stop auto save first.
	Flags.AutoSaveConfig = false

	-- Delete saved configuration.
	if delfile
		and isfile
		and isfile(CONFIG_FILE)
	then
		pcall(
			delfile,
			CONFIG_FILE
		)
	end

	-- Reset every flag back to its startup default.
	for key,value in pairs(DefaultFlags) do
		Flags[key] = value
	end

	-- Reset every PlayerSetting.
	if MM2.PlayerSettings then

		for key,value in pairs(
			DefaultPlayerSettings
		) do

			MM2.PlayerSettings[key] =
				value

		end
	end

	-- Refresh all registered toggles and run callbacks.
	if UI.SetToggleState then

		for key,value in pairs(DefaultFlags) do

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

	-- Immediately restore character movement values.
	local character =
		LocalPlayer.Character

	local humanoid =
		character
		and character:
			FindFirstChildOfClass(
				"Humanoid"
			)

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

	-- Reset theme.
	Flags.Theme = "Dark"

	ApplyTheme("Dark")

	SetThemeDropdown(false)

	ThemeButton.Text =
		"Dark  ▼"

	LastConfigSnapshot = nil

	ConfigBusy = false

	return true
end

MM2.Functions.ResetConfig =
	ResetConfig

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

		if Flags.AutoSaveConfig
			and writefile
		then

			local currentConfig =
				BuildConfig()

			local encoded = nil

			local ok =
				pcall(function()

					encoded =
						HttpService:
							JSONEncode(
								currentConfig
							)

				end)

			if ok
				and encoded
				and encoded
					~= LastConfigSnapshot
			then
				SaveConfig()
			end
		end
	end
end)

--============================================================
-- UI SECTION
--============================================================

UI.AddSection(
	UI.MiscPage,
	"UI",
	"Menu controls"
)

--============================================================
-- HIDE MENU
--============================================================

local function HideMenu()

	local frame =
		UI.MainFrame
		or UI.Main

	if frame then
		frame.Visible = false
	end
end

MM2.Functions.HideMenu =
	HideMenu

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
		pcall(SaveConfig)
	end

	if MM2.Functions.Unload then

		pcall(
			MM2.Functions.Unload
		)

		return
	end

	for _,gui in ipairs({
		UI.ScreenGui,
		UI.TracerGui,
		UI.Gui,
	}) do

		if gui
			and gui.Parent
		then
			pcall(function()
				gui:Destroy()
			end)
		end
	end
end

MM2.Functions.UnloadMenu =
	UnloadMenu

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
		Flags.Theme or "Dark"
	)
end

ThemeButton.Text =
	(Flags.Theme or "Dark")
	..
	"  ▼"

if Flags.AntiAFK then
	SetAntiAFK(true)
end

return MM2