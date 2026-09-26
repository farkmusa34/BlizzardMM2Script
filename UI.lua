--============================================================
-- Blizzard MM2 v1.85.4 - UI.lua
-- SIMPLE WINDUI BRIDGE
--
-- WindUI owns the visible menu and toolbar.
-- WindUI sections keep their original appearance,
-- stay permanently open, and hide only the section chevron.
-- Real Dropdown() controls keep their normal dropdown arrow.
--============================================================

local MM2 =
	getgenv
	and getgenv().MM2_V85_SPLIT
	or _G.MM2_V85_SPLIT

assert(
	MM2,
	"Shared.lua must load first"
)

local S = MM2.Services
local Flags = MM2.Flags
local Track = MM2.Track
local PlayerGui = MM2.PlayerGui
local CoreGui = S.CoreGui
local UIS = S.UserInputService

MM2.UI = MM2.UI or {}
local UI = MM2.UI

--============================================================
-- CLEANUP OLD GUI
--============================================================

for _,name in ipairs({
	"MM2_UTILITY_V8",
	"MM2_V8_ToolbarGui",
	"BlizzardMM2_LegacyHost",
}) do

	local p =
		PlayerGui:FindFirstChild(name)

	if p then
		pcall(function()
			p:Destroy()
		end)
	end

	pcall(function()

		local c =
			CoreGui:FindFirstChild(name)

		if c then
			c:Destroy()
		end
	end)
end

--============================================================
-- LEGACY COLORS
--============================================================

local COLORS = {
	Background = Color3.fromRGB(15,16,20),
	Sidebar = Color3.fromRGB(18,19,24),
	Card = Color3.fromRGB(24,25,31),
	CardHover = Color3.fromRGB(29,31,38),
	Stroke = Color3.fromRGB(54,57,68),
	Text = Color3.fromRGB(240,242,248),
	Muted = Color3.fromRGB(157,163,178),
	Accent = Color3.fromRGB(64,174,255),
	Accent2 = Color3.fromRGB(75,230,255),
	Success = Color3.fromRGB(80,215,135),
	Danger = Color3.fromRGB(255,92,105),
}

UI.COLORS = COLORS

--============================================================
-- REAL COMPATIBILITY SCREENGUI
--============================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2_UTILITY_V8"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 80
ScreenGui.Parent = PlayerGui

UI.ScreenGui = ScreenGui
UI.Gui = ScreenGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "LegacyMainFrame"
MainFrame.Size = UDim2.fromOffset(1,1)
MainFrame.Position = UDim2.fromOffset(-10000,-10000)
MainFrame.BackgroundTransparency = 1
MainFrame.BorderSizePixel = 0
MainFrame.Visible = true
MainFrame.Parent = ScreenGui

UI.MainFrame = MainFrame
UI.Main = MainFrame

--============================================================
-- EXACT OLD SNOWFLAKE HELPER
--============================================================

local function NewLine(parent,w,h,x,y,rotation,color,z)

	local line = Instance.new("Frame")
	line.AnchorPoint = Vector2.new(0.5,0.5)
	line.Size = UDim2.fromOffset(w,h)
	line.Position = UDim2.fromOffset(x,y)
	line.BackgroundColor3 = color
	line.BorderSizePixel = 0
	line.Rotation = rotation
	line.ZIndex = z or 3
	line.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1,0)
	corner.Parent = line

	return line
end

local function CreateSnowflake(parent,size,color)

	local holder = Instance.new("Frame")
	holder.Size = UDim2.fromOffset(size,size)
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.Parent = parent

	local cx = size / 2
	local cy = size / 2
	local armLength = size * 0.82
	local thickness = math.max(1,size * 0.075)

	for _,rotation in ipairs({0,60,120}) do
		NewLine(
			holder,
			armLength,
			thickness,
			cx,
			cy,
			rotation,
			color,
			3
		)
	end

	local branchLength = size * 0.25
	local branchOffset = size * 0.27

	for _,rotation in ipairs({
		0,60,120,180,240,300
	}) do

		local r = math.rad(rotation)

		local bx =
			cx
			+ math.cos(r)
			* branchOffset

		local by =
			cy
			+ math.sin(r)
			* branchOffset

		NewLine(
			holder,
			branchLength,
			thickness,
			bx,
			by,
			rotation + 35,
			color,
			4
		)

		NewLine(
			holder,
			branchLength,
			thickness,
			bx,
			by,
			rotation - 35,
			color,
			4
		)
	end

	return holder
end

UI.CreateSnowflake = CreateSnowflake

--============================================================
-- RGB / BLUE CYAN STROKE
--============================================================

function UI.CreateBlueCyanStroke(parent,thickness,transparency)

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = thickness or 1.4
	stroke.Transparency = transparency or 0.10
	stroke.Color = Color3.fromRGB(60,175,255)
	stroke.Parent = parent

	local gradient = Instance.new("UIGradient")

	gradient.Color =
		ColorSequence.new({
			ColorSequenceKeypoint.new(
				0,
				Color3.fromRGB(55,110,255)
			),

			ColorSequenceKeypoint.new(
				0.5,
				Color3.fromRGB(55,235,255)
			),

			ColorSequenceKeypoint.new(
				1,
				Color3.fromRGB(55,110,255)
			),
		})

	gradient.Parent = stroke

	task.spawn(function()

		while MM2.Running
			and gradient.Parent
		do

			gradient.Rotation =
				(
					gradient.Rotation
					+ 2
				)
				% 360

			task.wait(0.03)
		end
	end)

	return stroke,gradient
end

--============================================================
-- LOAD WINDUI
--============================================================

local okWind,WindUI =
	pcall(function()

		return loadstring(
			game:HttpGet(
				"https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
			)
		)()
	end)

assert(
	okWind
	and WindUI,
	"Failed to load WindUI"
)

UI.WindUI = WindUI

local Window =
	WindUI:CreateWindow({
		Title = "Blizzard MM2",
		Author = "v1.85.4",
		Folder = "BlizzardMM2",
		Icon = "gamepad-2",

		-- Blizzard Blue factory/default appearance.
		Theme = "Sky",

		Size =
			UDim2.fromOffset(
				580,
				430
			),

		Transparent = true,
		HideSearchBar = true,
		ScrollBarEnabled = false,

		-- WindUI native floating opener.
		-- Explicitly allow it on desktop as well as mobile.
		OpenButton = {
			Title = "Blizzard MM2",
			Icon = "gamepad-2",
			Enabled = true,
			Draggable = true,
			OnlyMobile = false,
			CornerRadius = UDim.new(1,0),
			StrokeThickness = 2,
			Scale = 0.8,
		},
	})

UI.Window = Window

-- Reinforce WindUI's own opener after window creation. This is the
-- same native floating "Blizzard MM2" controller, not a custom fallback.
pcall(function()
	if Window.EditOpenButton then
		Window:EditOpenButton({
			Title = "Blizzard MM2",
			Icon = "gamepad-2",
			Enabled = true,
			Draggable = true,
			OnlyMobile = false,
			CornerRadius = UDim.new(1,0),
			StrokeThickness = 2,
			Scale = 1,
		})
	end
end)


--============================================================
-- TOP STATUS TAG
--
-- Misc.lua controls this color whenever the selected
-- appearance/theme changes.
--
-- Blizzard Blue is used before Misc.lua has loaded.
--============================================================

local DEFAULT_BLIZZARD_BLUE =
	Color3.fromRGB(
		55,
		145,
		255
	)

UI.CurrentThemeAccent =
	UI.CurrentThemeAccent
	or DEFAULT_BLIZZARD_BLUE

local LatestUpdateTag = nil

local function CreateLatestUpdateTag(color)

	color =
		typeof(color) == "Color3"
		and color
		or DEFAULT_BLIZZARD_BLUE

	local ok,result =
		pcall(function()

			return Window:Tag({
				Title = "Latest Update",
				Icon = "sparkles",
				Color = color,
				Border = true,
			})
		end)

	if ok then

		LatestUpdateTag = result
		UI.LatestUpdateTag = result

		return result
	end

	warn(
		"[Blizzard UI] Latest Update tag failed:",
		result
	)

	return nil
end

function UI.SetLatestUpdateTheme(color)

	color =
		typeof(color) == "Color3"
		and color
		or DEFAULT_BLIZZARD_BLUE

	UI.CurrentThemeAccent = color


	-- Keep every floating Blizzard card synced to the selected theme.
	if UI.FloatingCardRegistry then
		for _,entry in pairs(UI.FloatingCardRegistry) do
			if entry and entry.Stroke then
				entry.Stroke.Color = color
			end
		end
	end

	-- Prefer WindUI's native tag color updater.
	if LatestUpdateTag
		and LatestUpdateTag.SetColor
	then

		local success =
			pcall(function()

				LatestUpdateTag:SetColor(
					color
				)
			end)

		if success then

			UI.LatestUpdateTag =
				LatestUpdateTag

			return LatestUpdateTag
		end
	end

	-- Fallback for WindUI builds without SetColor().
	if LatestUpdateTag
		and LatestUpdateTag.Destroy
	then

		pcall(function()
			LatestUpdateTag:Destroy()
		end)
	end

	LatestUpdateTag = nil
	UI.LatestUpdateTag = nil

	return CreateLatestUpdateTag(
		color
	)
end

CreateLatestUpdateTag(
	UI.CurrentThemeAccent
)

--============================================================
-- IMPORTANT:
-- WINDUI BUILT-IN OPEN BUTTON STAYS ENABLED
--============================================================

--============================================================
-- REAL WINDUI TABS
--============================================================

UI.WindTabs = {}

UI.WindTabs.Player =
	Window:Tab({
		Title = "Player",
		Icon = "shield-check"
	})

UI.WindTabs.Visuals =
	Window:Tab({
		Title = "Visuals",
		Icon = "eye"
	})

UI.WindTabs.Combat =
	Window:Tab({
		Title = "Combat",
		Icon = "crosshair"
	})

UI.WindTabs.Teleport =
	Window:Tab({
		Title = "Teleport",
		Icon = "navigation"
	})

UI.WindTabs.Fling =
	Window:Tab({
		Title = "Fling",
		Icon = "wind"
	})

UI.WindTabs.AutoFarm =
	Window:Tab({
		Title = "Auto Farm",
		Icon = "bot"
	})

--============================================================
-- SKIN CHANGER
-- Expandable sidebar category
--============================================================

UI.WindTabs.SkinChanger =
	Window:Tab({
		Title = "Skin Changer",
		Icon = "palette"
	})

UI.WindTabs.Misc =
	Window:Tab({
		Title = "Misc",
		Icon = "settings"
	})

--============================================================
-- HIDDEN LEGACY PAGES
--============================================================

local LegacyHost = Instance.new("Frame")
LegacyHost.Name = "BlizzardMM2_LegacyHost"
LegacyHost.Size = UDim2.fromOffset(1,1)
LegacyHost.Position = UDim2.fromOffset(-20000,-20000)
LegacyHost.BackgroundTransparency = 1
LegacyHost.Visible = false
LegacyHost.Parent = ScreenGui

local function NewLegacyPage(name)

	local page = Instance.new("ScrollingFrame")
	page.Name = name .. "Page"
	page.Size = UDim2.fromOffset(500,1000)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 0
	page.CanvasSize = UDim2.fromOffset(0,0)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.Visible = true
	page.Parent = LegacyHost

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0,6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = page

	return page
end

UI.VisualsPage = NewLegacyPage("Visuals")
UI.CombatPage = NewLegacyPage("Combat")
UI.PlayerPage = NewLegacyPage("Player")
UI.TeleportPage = NewLegacyPage("Teleport")
UI.FlingPage = NewLegacyPage("Fling")
UI.AutoFarmPage = NewLegacyPage("AutoFarm")
UI.SkinChangerPage = NewLegacyPage("SkinChanger")
UI.MiscPage = NewLegacyPage("Misc")

UI.Pages = {
	Visuals = UI.VisualsPage,
	Combat = UI.CombatPage,
	Player = UI.PlayerPage,
	Teleport = UI.TeleportPage,
	Fling = UI.FlingPage,
	AutoFarm = UI.AutoFarmPage,
	SkinChanger = UI.SkinChangerPage,
	Misc = UI.MiscPage,
}

UI.PageMap = {
	[UI.VisualsPage] = UI.WindTabs.Visuals,
	[UI.CombatPage] = UI.WindTabs.Combat,
	[UI.PlayerPage] = UI.WindTabs.Player,
	[UI.TeleportPage] = UI.WindTabs.Teleport,
	[UI.FlingPage] = UI.WindTabs.Fling,
	[UI.AutoFarmPage] = UI.WindTabs.AutoFarm,
	[UI.SkinChangerPage] = UI.WindTabs.SkinChanger,
	[UI.MiscPage] = UI.WindTabs.Misc,
}

UI.ActiveSection = {}

--============================================================
-- PAGE NAVIGATION
--============================================================

function UI.ShowPage(name)

	local tab =
		UI.WindTabs[
			tostring(
				name or "Visuals"
			)
		]

	if not tab then
		return false
	end

	pcall(function()
		tab:Select()
	end)

	return true
end

--============================================================
-- WINDUI SECTION PATCH
--
-- Keep original WindUI sections such as:
-- Aim / Sheriff / Murderer / Movement / Jump / Utility
--
-- Only hide their collapse chevron and force them open.
-- Real Dropdown() controls are untouched.
--============================================================

local function LockSectionOpenAndHideArrow(section)

	if not section then
		return
	end

	section.Opened = true

	local function HideChevron()

		local main = section.ElementFrame

		if not main then
			return
		end

		local outline =
			main:FindFirstChild("Outline")

		local top =
			outline
			and outline:FindFirstChild("Top")

		if not top then
			return
		end

		for _,child in ipairs(top:GetChildren()) do

			if child:IsA("Frame") then

				for _,descendant in ipairs(
					child:GetDescendants()
				) do

					if descendant:IsA("ImageLabel")
						or descendant:IsA("ImageButton")
					then

						descendant.Visible = false
					end
				end
			end
		end
	end

	HideChevron()

	task.defer(function()
		HideChevron()
	end)

	if section.Open then
		pcall(function()
			section:Open(true)
		end)
	end

	if section.Close then

		section.Close =
			function(self)

				self.Opened = true

				if self.Open then
					pcall(function()
						self:Open(true)
					end)
				end

				HideChevron()
			end
	end
end

function UI.AddSection(page,titleText,subtitleText)

	local tab = UI.PageMap[page]

	if not tab then

		warn(
			"[Blizzard UI] No mapped tab for section:",
			titleText
		)

		return nil
	end

	local section

	local ok,result =
		pcall(function()

			return tab:Section({
				Title =
					tostring(
						titleText or ""
					),

				Desc =
					tostring(
						subtitleText or ""
					),

				Opened = true,
			})
		end)

	if ok and result then

		section = result

	else

		local ok2,result2 =
			pcall(function()

				return tab:Section({
					Title =
						tostring(
							titleText or ""
						),

					Opened = true,
				})
			end)

		if ok2 and result2 then

			section = result2

		else

			warn(
				"[Blizzard UI] Section failed:",
				titleText,
				result,
				result2
			)

			section = tab
		end
	end

	if section ~= tab then
		LockSectionOpenAndHideArrow(
			section
		)
	end

	UI.ActiveSection[page] = section

	return section
end

local function GetControlParent(page)

	return
		UI.ActiveSection[page]
		or UI.PageMap[page]
end

--============================================================
-- DROPDOWN
--============================================================

function UI.CreateDropdown(
	page,
	titleText,
	description,
	values,
	defaultValue,
	callback
)

	local parent =
		GetControlParent(page)

	if not parent then

		warn(
			"[Blizzard UI] Dropdown has no parent:",
			titleText
		)

		return nil
	end

	local dropdown

	local config = {
		Title =
			tostring(
				titleText or ""
			),

		Desc =
			tostring(
				description or ""
			),

		Values = values or {},
		AllowNone = true,
		SearchBarEnabled = true,

		Callback =
			function(value)

				if callback then

					local cbOk,cbErr =
						pcall(
							callback,
							value
						)

					if not cbOk then

						warn(
							"[Blizzard UI Dropdown]",
							titleText,
							cbErr
						)
					end
				end
			end,
	}

	if defaultValue ~= nil then
		config.Value = defaultValue
	end

	local ok,result =
		pcall(function()

			return parent:Dropdown(
				config
			)
		end)

	if ok then

		dropdown = result

	else

		warn(
			"[Blizzard UI] Dropdown create failed:",
			titleText,
			result
		)
	end

	return dropdown
end

--============================================================
-- DYNAMIC INFO / PARAGRAPH
--============================================================

function UI.CreateInfo(
	page,
	titleText,
	description
)

	local parent =
		GetControlParent(page)

	if not parent then

		warn(
			"[Blizzard UI] Info has no parent:",
			titleText
		)

		return nil,function() end
	end

	local control

	local ok,result =
		pcall(function()

			return parent:Paragraph({
				Title =
					tostring(
						titleText or ""
					),

				Desc =
					tostring(
						description or ""
					),
			})
		end)

	if ok then

		control = result

	else

		warn(
			"[Blizzard UI] Info create failed:",
			titleText,
			result
		)
	end

	local function SetText(newText)

		newText =
			tostring(
				newText or ""
			)

		if not control then
			return
		end

		if control.SetDesc then

			pcall(function()
				control:SetDesc(
					newText
				)
			end)

			return
		end

		pcall(function()

			if control.Desc ~= nil then
				control.Desc = newText
			end
		end)
	end

	return control,SetText
end

--============================================================
-- TOGGLE REGISTRY
--============================================================

UI.ToggleRegistry = {}

function UI.SetToggleState(
	flagName,
	value,
	runCallback
)

	local entry =
		UI.ToggleRegistry[
			flagName
		]

	value = value == true
	Flags[flagName] = value

	if entry
		and entry.Render
	then

		entry.Render(
			value,
			runCallback == true
		)

	elseif runCallback == true
		and entry
		and entry.Callback
	then

		pcall(
			entry.Callback,
			value
		)
	end

	return value
end

UI.SetToggle = UI.SetToggleState

function UI.CreateToggle(
	page,
	titleText,
	description,
	flagName,
	callback
)

	local parent =
		GetControlParent(page)

	if not parent then

		warn(
			"[Blizzard UI] Toggle has no parent:",
			titleText
		)

		return nil,nil,function() end
	end

	Flags[flagName] =
		Flags[flagName] == true

	local control
	local ignoreNextCallback = false

	local ok,result =
		pcall(function()

			return parent:Toggle({
				Title =
					tostring(
						titleText or ""
					),

				Desc =
					tostring(
						description or ""
					),

				Value =
					Flags[flagName],

				Callback =
					function(value)

						value =
							value == true

						Flags[flagName] =
							value

						if ignoreNextCallback then
							return
						end

						if callback then

							local cbOk,cbErr =
								pcall(
									callback,
									value
								)

							if not cbOk then

								warn(
									"[Blizzard UI Toggle Callback]",
									flagName,
									cbErr
								)
							end
						end

						pcall(function()

							WindUI:Notify({
								Title =
									tostring(
										titleText
										or flagName
										or "Feature"
									),

								Content =
									value
									and "Enabled!"
									or "Disabled!",

								Icon =
									flagName == "AutoFarm"
									and "bot"
									or (value and "check" or "x"),

								Duration = 2.5,
							})
						end)
					end,
			})
		end)

	if ok then

		control = result

	else

		warn(
			"[Blizzard UI] Toggle create failed:",
			titleText,
			result
		)
	end

	local function render(
		value,
		runCallback
	)

		value = value == true
		Flags[flagName] = value

		if control
			and control.Set
		then

			ignoreNextCallback = true

			pcall(function()
				control:Set(
					value
				)
			end)

			ignoreNextCallback = false
		end

		if runCallback
			and callback
		then

			pcall(
				callback,
				value
			)
		end
	end

	UI.ToggleRegistry[flagName] = {
		Control = control,
		Render = render,
		Callback = callback,
	}

	return
		control,
		control,
		render
end

--============================================================
-- ACTIONS
--============================================================

function UI.CreateActionFeature(
	page,
	titleText,
	description,
	callback,
	icon
)

	local parent =
		GetControlParent(page)

	if not parent then

		warn(
			"[Blizzard UI] Action has no parent:",
			titleText
		)

		return nil
	end

	local control

	local ok,result =
		pcall(function()

			return parent:Button({
				Title =
					tostring(
						titleText or ""
					),

				Desc =
					tostring(
						description or ""
					),

				Icon = icon,

				Callback =
					function()

						if callback then

							local cbOk,cbErr =
								pcall(
									callback
								)

							if not cbOk then

								warn(
									"[Blizzard UI Action]",
									titleText,
									cbErr
								)
							end
						end
					end,
			})
		end)

	if ok then

		control = result

	else

		warn(
			"[Blizzard UI] Action create failed:",
			titleText,
			result
		)
	end

	return control
end

function UI.CreateActionButton(
	parent,
	text,
	callback,
	style
)

	if UI.PageMap[parent] then

		return UI.CreateActionFeature(
			parent,
			text,
			"",
			callback
		)
	end

	if typeof(parent) ~= "Instance" then
		return nil
	end

	local button =
		Instance.new("TextButton")

	button.Size =
		UDim2.new(
			1,
			0,
			0,
			34
		)

	button.BackgroundColor3 =
		style == "danger"
		and COLORS.Danger
		or COLORS.Card

	button.BorderSizePixel = 0

	button.Text =
		tostring(
			text or ""
		)

	button.TextColor3 = COLORS.Text
	button.TextSize = 11
	button.Font = Enum.Font.GothamBold
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0,9)
	corner.Parent = button

	Track(
		button.MouseButton1Click:Connect(
			function()

				if callback then
					pcall(
						callback
					)
				end
			end
		)
	)

	return button
end

--============================================================
-- SLIDER
--============================================================

local function CreateMappedSlider(
	page,
	labelText,
	description,
	getter,
	setter,
	minValue,
	maxValue,
	step
)

	local parent =
		GetControlParent(page)

	if not parent then

		warn(
			"[Blizzard UI] Slider has no parent:",
			labelText
		)

		return nil
	end

	minValue =
		tonumber(
			minValue
		)
		or 0

	maxValue =
		tonumber(
			maxValue
		)
		or 100

	step =
		tonumber(
			step
		)
		or 1

	local defaultValue = minValue

	if getter then

		local ok,value =
			pcall(
				getter
			)

		if ok
			and tonumber(value)
		then

			defaultValue =
				tonumber(
					value
				)
		end
	end

	defaultValue =
		math.clamp(
			defaultValue,
			minValue,
			maxValue
		)

	local slider

	local ok,result =
		pcall(function()

			return parent:Slider({
				Title =
					tostring(
						labelText or ""
					),

				Desc =
					tostring(
						description or ""
					),

				Step = step,

				Value = {
					Min = minValue,
					Max = maxValue,
					Default = defaultValue,
				},

				Callback =
					function(value)

						value =
							tonumber(
								value
							)
							or defaultValue

						if setter then

							local setOk,setErr =
								pcall(
									setter,
									value
								)

							if not setOk then

								warn(
									"[Blizzard UI Slider]",
									labelText,
									setErr
								)
							end
						end
					end,
			})
		end)

	if ok then

		slider = result

	else

		warn(
			"[Blizzard UI] Slider create failed:",
			labelText,
			result
		)
	end

	return slider
end

function UI.CreateSlider(
	page,
	labelText,
	description,
	getter,
	setter,
	minValue,
	maxValue,
	step
)

	return CreateMappedSlider(
		page,
		labelText,
		description,
		getter,
		setter,
		minValue,
		maxValue,
		step
	)
end

function UI.CreateValueControl(
	page,
	labelText,
	getter,
	setter,
	minValue,
	maxValue,
	step
)

	return CreateMappedSlider(
		page,
		labelText,
		"",
		getter,
		setter,
		minValue,
		maxValue,
		step
	)
end

--============================================================
-- MOVABLE BLIZZARD QUICK BUTTONS
--
-- Shared floating-button system used by Combat / Fling / Player.
--
-- Features:
--   • rounded dark glass card
--   • WindUI / Lucide icon centered above the label
--   • selected Blizzard theme color as the outline
--   • quick click flash / blink feedback
--   • global lock / size / reset controls
--   • draggable on touch and mouse while unlocked
--   • 25% smaller factory card size than the old 98x98 cards
--============================================================

UI.FloatingCardRegistry = UI.FloatingCardRegistry or {}
UI.QuickButtons = UI.FloatingCardRegistry

local QUICK_BUTTON_BASE_SIZE = 74
local QUICK_BUTTON_MIN_SCALE = 60
local QUICK_BUTTON_MAX_SCALE = 140

Flags.QuickButtonsLocked = Flags.QuickButtonsLocked == true
Flags.QuickButtonScale = math.clamp(
	tonumber(Flags.QuickButtonScale) or 100,
	QUICK_BUTTON_MIN_SCALE,
	QUICK_BUTTON_MAX_SCALE
)

local LEGACY_ICON_ALIASES = {
	["💀"] = "skull",
	["🎯"] = "crosshair",
	["⚡"] = "zap",
	["💣"] = "bomb",
	["🛡️"] = "shield",
	["🛡"] = "shield",
	["❄️"] = "snowflake",
	["❄"] = "snowflake",
}

local function ResolveWindUIIcon(iconName)
	iconName = tostring(iconName or "")
	iconName = LEGACY_ICON_ALIASES[iconName] or iconName

	if iconName == "" then
		return nil,nil,nil
	end

	local creator = WindUI and WindUI.Creator
	local icons = creator and creator.Icons
	if not icons or not icons.Icon2 then
		return nil,nil,nil
	end

	local ok,data = pcall(function()
		return icons.Icon2(iconName,"lucide")
	end)

	if not ok or not data then
		return nil,nil,nil
	end

	if typeof(data) == "string" then
		return data,nil,nil
	end

	if type(data) == "table" then
		local image = data[1]
		local info = data[2]

		if typeof(image) == "string" then
			return
				image,
				info and info.ImageRectSize or nil,
				info and info.ImageRectPosition or nil
		end
	end

	return nil,nil,nil
end

local function ApplyQuickButtonScaleToEntry(entry)
	if not entry or not entry.Holder then
		return
	end

	local scale = math.clamp(
		tonumber(Flags.QuickButtonScale) or 100,
		QUICK_BUTTON_MIN_SCALE,
		QUICK_BUTTON_MAX_SCALE
	) / 100

	if entry.UIScale then
		entry.UIScale.Scale = scale
	end
end

function UI.SetQuickButtonsLocked(value)
	Flags.QuickButtonsLocked = value == true
	return Flags.QuickButtonsLocked
end

function UI.SetQuickButtonScale(value)
	Flags.QuickButtonScale = math.clamp(
		tonumber(value) or 100,
		QUICK_BUTTON_MIN_SCALE,
		QUICK_BUTTON_MAX_SCALE
	)

	for _,entry in pairs(UI.FloatingCardRegistry) do
		ApplyQuickButtonScaleToEntry(entry)
	end

	return Flags.QuickButtonScale
end

function UI.ResetQuickButtonPositions()
	for _,entry in pairs(UI.FloatingCardRegistry) do
		if entry and entry.Holder and entry.DefaultPosition then
			entry.Holder.Position = entry.DefaultPosition
		end
	end
	return true
end

function UI.ResetQuickButtons()
	UI.ResetQuickButtonPositions()
	UI.SetQuickButtonScale(100)
	UI.SetQuickButtonsLocked(false)
	return true
end

local function FlashQuickButton(entry)
	if not entry or not entry.Button or not entry.Stroke then
		return
	end

	local button = entry.Button
	local stroke = entry.Stroke
	entry.FlashToken = (entry.FlashToken or 0) + 1
	local token = entry.FlashToken

	button.BackgroundTransparency = 0.01
	stroke.Transparency = 0
	stroke.Thickness = 3.2

	if entry.Icon then
		pcall(function()
			entry.Icon.ImageColor3 = UI.CurrentThemeAccent or DEFAULT_BLIZZARD_BLUE
		end)
	end

	task.delay(0.11,function()
		if not entry.Button or not entry.Button.Parent or entry.FlashToken ~= token then
			return
		end

		button.BackgroundTransparency = 0.10
		stroke.Transparency = 0.05
		stroke.Thickness = 2.0

		if entry.Icon then
			pcall(function()
				entry.Icon.ImageColor3 = Color3.fromRGB(255,255,255)
			end)
		end
	end)
end

function UI.CreateMovableCardButton(
	name,
	icon,
	labelText,
	startPosition,
	callback
)
	local cleanName = tostring(name or "Floating")
	local defaultPosition = startPosition or UDim2.fromScale(0.8,0.75)

	local holder = Instance.new("Frame")
	holder.Name = cleanName .. "Holder"
	holder.AnchorPoint = Vector2.new(0.5,0.5)
	holder.Position = defaultPosition
	holder.Size = UDim2.fromOffset(QUICK_BUTTON_BASE_SIZE,QUICK_BUTTON_BASE_SIZE)
	holder.BackgroundTransparency = 1
	holder.Active = true
	holder.ZIndex = 250
	holder.Parent = ScreenGui

	local uiScale = Instance.new("UIScale")
	uiScale.Name = "QuickButtonScale"
	uiScale.Scale = Flags.QuickButtonScale / 100
	uiScale.Parent = holder

	local button = Instance.new("TextButton")
	button.Name = cleanName
	button.Size = UDim2.fromScale(1,1)
	button.Position = UDim2.fromScale(0,0)
	button.BackgroundColor3 = Color3.fromRGB(14,16,22)
	button.BackgroundTransparency = 0.10
	button.BorderSizePixel = 0
	button.Text = ""
	button.AutoButtonColor = false
	button.Active = true
	button.ZIndex = 251
	button.Parent = holder

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0,14)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Name = "ThemeStroke"
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = UI.CurrentThemeAccent or DEFAULT_BLIZZARD_BLUE
	stroke.Thickness = 2.0
	stroke.Transparency = 0.05
	stroke.Parent = button

	local iconImage,rectSize,rectOffset = ResolveWindUIIcon(icon)
	local iconObject

	if iconImage then
		local image = Instance.new("ImageLabel")
		image.Name = "Icon"
		image.AnchorPoint = Vector2.new(0.5,0)
		image.Position = UDim2.new(0.5,0,0,9)
		image.Size = UDim2.fromOffset(26,26)
		image.BackgroundTransparency = 1
		image.Image = iconImage
		image.ImageColor3 = Color3.fromRGB(255,255,255)
		image.ScaleType = Enum.ScaleType.Fit
		image.ZIndex = 252
		if rectSize then
			image.ImageRectSize = rectSize
		end
		if rectOffset then
			image.ImageRectOffset = rectOffset
		end
		image.Parent = button
		iconObject = image
	else
		local fallback = Instance.new("TextLabel")
		fallback.Name = "IconFallback"
		fallback.AnchorPoint = Vector2.new(0.5,0)
		fallback.Position = UDim2.new(0.5,0,0,7)
		fallback.Size = UDim2.fromOffset(29,29)
		fallback.BackgroundTransparency = 1
		fallback.Text = tostring(icon or "")
		fallback.TextColor3 = Color3.fromRGB(255,255,255)
		fallback.TextSize = 21
		fallback.Font = Enum.Font.GothamBold
		fallback.ZIndex = 252
		fallback.Parent = button
		iconObject = fallback
	end

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.AnchorPoint = Vector2.new(0.5,0)
	label.Position = UDim2.new(0.5,0,0,40)
	label.Size = UDim2.new(1,-8,0,27)
	label.BackgroundTransparency = 1
	label.Text = string.upper(tostring(labelText or ""))
	label.TextColor3 = Color3.fromRGB(255,255,255)
	label.TextSize = 9
	label.Font = Enum.Font.GothamBold
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.ZIndex = 252
	label.Parent = button

	local entry = {
		Button = button,
		Holder = holder,
		Stroke = stroke,
		Icon = iconObject,
		Label = label,
		UIScale = uiScale,
		DefaultPosition = defaultPosition,
		DefaultSize = QUICK_BUTTON_BASE_SIZE,
	}

	UI.FloatingCardRegistry[cleanName] = entry

	local dragging = false
	local moved = false
	local dragStart
	local startPos
	local dragInput

	Track(button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			if Flags.QuickButtonsLocked then
				dragging = false
				moved = false
				return
			end

			dragging = true
			moved = false
			dragStart = input.Position
			startPos = holder.Position

			Track(input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end))
		end
	end))

	Track(button.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragInput = input
		end
	end))

	Track(UIS.InputChanged:Connect(function(input)
		if Flags.QuickButtonsLocked then
			dragging = false
			return
		end

		if not dragging
			or input ~= dragInput
			or not dragStart
			or not startPos
		then
			return
		end

		local delta = input.Position - dragStart

		if delta.Magnitude >= 4 then
			moved = true
		end

		if moved then
			holder.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end))

	Track(button.MouseButton1Click:Connect(function()
		if moved then
			moved = false
			return
		end

		FlashQuickButton(entry)

		if callback then
			local ok,err = pcall(callback)
			if not ok then
				warn("[Blizzard UI Floating Card]",cleanName,err)
			end
		end
	end))

	ApplyQuickButtonScaleToEntry(entry)

	return button,holder,label,iconObject
end

-- Old API name kept so existing modules automatically receive the new card.
UI.CreateMovableCircleButton = UI.CreateMovableCardButton

--============================================================
-- WINDUI TOOLBAR
--
-- No custom ToolbarGui is created here.
-- WindUI's built-in controller / RGB opener remains enabled.
--============================================================

--============================================================
-- MAINFRAME HIDE COMPATIBILITY
--============================================================

Track(
	MainFrame:GetPropertyChangedSignal(
		"Visible"
	):Connect(function()

		if MainFrame.Visible == false then

			pcall(function()

				if Window.Toggle then
					Window:Toggle()
				end
			end)
		end
	end)
)

--============================================================
-- CLEANUP
--============================================================

Track(
	ScreenGui.Destroying:Connect(
		function()

			pcall(function()

				if Window
					and Window.Destroy
				then

					Window:Destroy()
				end
			end)
		end
	)
)

--============================================================
-- START
--============================================================

UI.ShowPage(
	"Visuals"
)

print(
	"[Blizzard MM2 UI] Simple WindUI bridge v1.85.4 loaded"
)

return MM2
