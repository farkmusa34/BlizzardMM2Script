--============================================================
-- Blizzard MM2 V8.8.4 - UI.lua
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
	Background =
		Color3.fromRGB(
			15,
			16,
			20
		),

	Sidebar =
		Color3.fromRGB(
			18,
			19,
			24
		),

	Card =
		Color3.fromRGB(
			24,
			25,
			31
		),

	CardHover =
		Color3.fromRGB(
			29,
			31,
			38
		),

	Stroke =
		Color3.fromRGB(
			54,
			57,
			68
		),

	Text =
		Color3.fromRGB(
			240,
			242,
			248
		),

	Muted =
		Color3.fromRGB(
			157,
			163,
			178
		),

	Accent =
		Color3.fromRGB(
			64,
			174,
			255
		),

	Accent2 =
		Color3.fromRGB(
			75,
			230,
			255
		),

	Success =
		Color3.fromRGB(
			80,
			215,
			135
		),

	Danger =
		Color3.fromRGB(
			255,
			92,
			105
		),
}

UI.COLORS = COLORS

--============================================================
-- REAL COMPATIBILITY SCREENGUI
--============================================================

local ScreenGui =
	Instance.new("ScreenGui")

ScreenGui.Name =
	"MM2_UTILITY_V8"

ScreenGui.ResetOnSpawn =
	false

ScreenGui.IgnoreGuiInset =
	true

ScreenGui.DisplayOrder =
	80

ScreenGui.Parent =
	PlayerGui

UI.ScreenGui =
	ScreenGui

UI.Gui =
	ScreenGui

local MainFrame =
	Instance.new("Frame")

MainFrame.Name =
	"LegacyMainFrame"

MainFrame.Size =
	UDim2.fromOffset(
		1,
		1
	)

MainFrame.Position =
	UDim2.fromOffset(
		-10000,
		-10000
	)

MainFrame.BackgroundTransparency =
	1

MainFrame.BorderSizePixel =
	0

MainFrame.Visible =
	true

MainFrame.Parent =
	ScreenGui

UI.MainFrame =
	MainFrame

UI.Main =
	MainFrame

--============================================================
-- EXACT OLD SNOWFLAKE HELPER
--============================================================

local function NewLine(
	parent,
	w,
	h,
	x,
	y,
	rotation,
	color,
	z
)

	local line =
		Instance.new("Frame")

	line.AnchorPoint =
		Vector2.new(
			0.5,
			0.5
		)

	line.Size =
		UDim2.fromOffset(
			w,
			h
		)

	line.Position =
		UDim2.fromOffset(
			x,
			y
		)

	line.BackgroundColor3 =
		color

	line.BorderSizePixel =
		0

	line.Rotation =
		rotation

	line.ZIndex =
		z or 3

	line.Parent =
		parent

	local corner =
		Instance.new("UICorner")

	corner.CornerRadius =
		UDim.new(
			1,
			0
		)

	corner.Parent =
		line

	return line
end

local function CreateSnowflake(
	parent,
	size,
	color
)

	local holder =
		Instance.new("Frame")

	holder.Size =
		UDim2.fromOffset(
			size,
			size
		)

	holder.BackgroundTransparency =
		1

	holder.BorderSizePixel =
		0

	holder.Parent =
		parent

	local cx =
		size / 2

	local cy =
		size / 2

	local armLength =
		size * 0.82

	local thickness =
		math.max(
			1,
			size * 0.075
		)

	for _,rotation in ipairs({
		0,
		60,
		120
	}) do

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

	local branchLength =
		size * 0.25

	local branchOffset =
		size * 0.27

	for _,rotation in ipairs({
		0,
		60,
		120,
		180,
		240,
		300
	}) do

		local r =
			math.rad(rotation)

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

UI.CreateSnowflake =
	CreateSnowflake

--============================================================
-- RGB / BLUE CYAN STROKE
--============================================================

function UI.CreateBlueCyanStroke(
	parent,
	thickness,
	transparency
)

	local stroke =
		Instance.new("UIStroke")

	stroke.Thickness =
		thickness or 1.4

	stroke.Transparency =
		transparency or 0.10

	stroke.Color =
		Color3.fromRGB(
			60,
			175,
			255
		)

	stroke.Parent =
		parent

	local gradient =
		Instance.new("UIGradient")

	gradient.Color =
		ColorSequence.new({
			ColorSequenceKeypoint.new(
				0,
				Color3.fromRGB(
					55,
					110,
					255
				)
			),

			ColorSequenceKeypoint.new(
				0.5,
				Color3.fromRGB(
					55,
					235,
					255
				)
			),

			ColorSequenceKeypoint.new(
				1,
				Color3.fromRGB(
					55,
					110,
					255
				)
			),
		})

	gradient.Parent =
		stroke

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

			task.wait(
				0.03
			)
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

UI.WindUI =
	WindUI

local Window =
	WindUI:CreateWindow({
		Title = "Blizzard MM2",
		Author = "V8.8.4",
		Folder = "BlizzardMM2",
		Icon = "gamepad-2",
		Theme = "Dark",

		Size =
			UDim2.fromOffset(
				580,
				430
			),

		Transparent = true,
		HideSearchBar = true,
		ScrollBarEnabled = false,
	})

UI.Window =
	Window

--============================================================
-- IMPORTANT:
-- WINDUI BUILT-IN OPEN BUTTON STAYS ENABLED
--============================================================

--============================================================
-- REAL WINDUI TABS
--============================================================

UI.WindTabs = {}

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

UI.WindTabs.Player =
	Window:Tab({
		Title = "Player",
		Icon = "shield"
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

UI.WindTabs.Misc =
	Window:Tab({
		Title = "Misc",
		Icon = "settings"
	})

--============================================================
-- HIDDEN LEGACY PAGES
--============================================================

local LegacyHost =
	Instance.new("Frame")

LegacyHost.Name =
	"BlizzardMM2_LegacyHost"

LegacyHost.Size =
	UDim2.fromOffset(
		1,
		1
	)

LegacyHost.Position =
	UDim2.fromOffset(
		-20000,
		-20000
	)

LegacyHost.BackgroundTransparency =
	1

LegacyHost.Visible =
	false

LegacyHost.Parent =
	ScreenGui

local function NewLegacyPage(name)

	local page =
		Instance.new(
			"ScrollingFrame"
		)

	page.Name =
		name .. "Page"

	page.Size =
		UDim2.fromOffset(
			500,
			1000
		)

	page.BackgroundTransparency =
		1

	page.BorderSizePixel =
		0

	page.ScrollBarThickness =
		0

	page.CanvasSize =
		UDim2.fromOffset(
			0,
			0
		)

	page.AutomaticCanvasSize =
		Enum.AutomaticSize.Y

	page.Visible =
		true

	page.Parent =
		LegacyHost

	local layout =
		Instance.new(
			"UIListLayout"
		)

	layout.Padding =
		UDim.new(
			0,
			6
		)

	layout.SortOrder =
		Enum.SortOrder.LayoutOrder

	layout.Parent =
		page

	return page
end

UI.VisualsPage =
	NewLegacyPage("Visuals")

UI.CombatPage =
	NewLegacyPage("Combat")

UI.PlayerPage =
	NewLegacyPage("Player")

UI.FlingPage =
	NewLegacyPage("Fling")

UI.AutoFarmPage =
	NewLegacyPage("AutoFarm")

UI.MiscPage =
	NewLegacyPage("Misc")

UI.Pages = {
	Visuals =
		UI.VisualsPage,

	Combat =
		UI.CombatPage,

	Player =
		UI.PlayerPage,

	Fling =
		UI.FlingPage,

	AutoFarm =
		UI.AutoFarmPage,

	Misc =
		UI.MiscPage,
}

UI.PageMap = {
	[UI.VisualsPage] =
		UI.WindTabs.Visuals,

	[UI.CombatPage] =
		UI.WindTabs.Combat,

	[UI.PlayerPage] =
		UI.WindTabs.Player,

	[UI.FlingPage] =
		UI.WindTabs.Fling,

	[UI.AutoFarmPage] =
		UI.WindTabs.AutoFarm,

	[UI.MiscPage] =
		UI.WindTabs.Misc,
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

		-- WindUI's section chevron lives inside a child Frame
		-- in the top header. This does not touch Dropdown()
		-- controls, so Fling player selection keeps its arrow.
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

	-- WindUI can finish some UI setup on deferred tasks.
	-- Re-hide the chevron after that setup completes.
	task.defer(function()
		HideChevron()
	end)

	-- Keep the section open.
	if section.Open then
		pcall(function()
			section:Open(true)
		end)
	end

	-- Prevent later Close() calls from collapsing it.
	if section.Close then
		section.Close = function(self)
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

function UI.AddSection(
	page,
	titleText,
	subtitleText
)

	local tab =
		UI.PageMap[page]

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

	-- Feature controls remain parented to the real WindUI
	-- section, preserving the old grouped layout.
	UI.ActiveSection[page] =
		section

	return section
end

local function GetControlParent(page)

	return
		UI.ActiveSection[page]
		or UI.PageMap[page]
end

--============================================================
-- DROPDOWN
--
-- Real dropdowns remain unchanged.
-- Fling -> Select Player to Target keeps its arrow.
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

		Values =
			values or {},

		AllowNone =
			true,

		SearchBarEnabled =
			true,

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
		config.Value =
			defaultValue
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
				control.Desc =
					newText
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

	value =
		value == true

	Flags[flagName] =
		value

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

UI.SetToggle =
	UI.SetToggleState

--============================================================
-- CREATE TOGGLE
--============================================================

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

	local ignoreNextCallback =
		false

	local firstCallback =
		true

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

						-- Ignore programmatic Set() updates.
						if ignoreNextCallback then
							return
						end

						-- Some WindUI versions may call the
						-- callback once while creating the toggle.
						-- Skip that so startup does not spam toasts.
						if firstCallback then
							firstCallback =
								false

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

						--============================================
						-- WINDUI FEATURE NOTIFICATION
						--============================================

						MM2.Notify(
							value
								and "Enabled!"
								or "Disabled!",

							2,

							value
								and "check"
								or "x",

							tostring(
								titleText
								or flagName
								or "Feature"
							)
						)
					end,
			})
		end)

	if ok then
		control =
			result
	else

		warn(
			"[Blizzard UI] Toggle create failed:",
			titleText,
			result
		)
	end

	-- If WindUI did NOT fire the callback during creation,
	-- allow the next callback to be treated as a real click.
	task.defer(function()
		firstCallback =
			false
	end)

	local function render(
		value,
		runCallback
	)

		value =
			value == true

		Flags[flagName] =
			value

		if control
			and control.Set
		then

			ignoreNextCallback =
				true

			pcall(function()

				control:Set(
					value
				)
			end)

			ignoreNextCallback =
				false
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
		Control =
			control,

		Render =
			render,

		Callback =
			callback,
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
	callback
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

	if typeof(parent)
		~= "Instance"
	then
		return nil
	end

	local button =
		Instance.new(
			"TextButton"
		)

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

	button.BorderSizePixel =
		0

	button.Text =
		tostring(
			text or ""
		)

	button.TextColor3 =
		COLORS.Text

	button.TextSize =
		11

	button.Font =
		Enum.Font.GothamBold

	button.Parent =
		parent

	local corner =
		Instance.new(
			"UICorner"
		)

	corner.CornerRadius =
		UDim.new(
			0,
			9
		)

	corner.Parent =
		button

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

	local defaultValue =
		minValue

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

				Step =
					step,

				Value = {
					Min =
						minValue,

					Max =
						maxValue,

					Default =
						defaultValue,
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
-- MOVABLE CIRCLE BUTTON COMPATIBILITY
--============================================================

function UI.CreateMovableCircleButton(
	name,
	icon,
	labelText,
	startPosition,
	callback
)

	local holder =
		Instance.new("Frame")

	holder.Name =
		tostring(
			name or "Floating"
		)
		.. "Holder"

	holder.AnchorPoint =
		Vector2.new(
			0.5,
			0.5
		)

	holder.Position =
		startPosition
		or UDim2.fromScale(
			0.8,
			0.75
		)

	holder.Size =
		UDim2.fromOffset(
			84,
			84
		)

	holder.BackgroundTransparency =
		1

	holder.Active =
		true

	holder.ZIndex =
		250

	holder.Parent =
		ScreenGui

	local button =
		Instance.new(
			"TextButton"
		)

	button.Name =
		tostring(
			name or "Floating"
		)

	button.AnchorPoint =
		Vector2.new(
			0.5,
			0.5
		)

	button.Position =
		UDim2.fromScale(
			0.5,
			0.42
		)

	button.Size =
		UDim2.fromOffset(
			54,
			54
		)

	button.BackgroundColor3 =
		Color3.fromRGB(
			18,
			20,
			26
		)

	button.BackgroundTransparency =
		0.08

	button.BorderSizePixel =
		0

	button.Text =
		tostring(
			icon or ""
		)

	button.TextColor3 =
		COLORS.Text

	button.TextSize =
		22

	button.Font =
		Enum.Font.GothamBold

	button.Active =
		true

	button.ZIndex =
		251

	button.Parent =
		holder

	local corner =
		Instance.new(
			"UICorner"
		)

	corner.CornerRadius =
		UDim.new(
			1,
			0
		)

	corner.Parent =
		button

	UI.CreateBlueCyanStroke(
		button,
		1.5,
		0.12
	)

	local label =
		Instance.new(
			"TextLabel"
		)

	label.AnchorPoint =
		Vector2.new(
			0.5,
			0
		)

	label.Position =
		UDim2.new(
			0.5,
			0,
			1,
			-18
		)

	label.Size =
		UDim2.new(
			2,
			0,
			0,
			18
		)

	label.BackgroundTransparency =
		1

	label.Text =
		tostring(
			labelText or ""
		)

	label.TextColor3 =
		COLORS.Text

	label.TextSize =
		9

	label.Font =
		Enum.Font.GothamBold

	label.ZIndex =
		252

	label.Parent =
		holder

	local dragging =
		false

	local moved =
		false

	local dragStart
	local startPos
	local dragInput

	Track(
		button.InputBegan:Connect(
			function(input)

				if input.UserInputType
					== Enum.UserInputType.MouseButton1
					or input.UserInputType
					== Enum.UserInputType.Touch
				then

					dragging =
						true

					moved =
						false

					dragStart =
						input.Position

					startPos =
						holder.Position

					Track(
						input.Changed:Connect(
							function()

								if input.UserInputState
									== Enum.UserInputState.End
								then

									dragging =
										false
								end
							end
						)
					)
				end
			end
		)
	)

	Track(
		button.InputChanged:Connect(
			function(input)

				if input.UserInputType
					== Enum.UserInputType.MouseMovement
					or input.UserInputType
					== Enum.UserInputType.Touch
				then

					dragInput =
						input
				end
			end
		)
	)

	Track(
		UIS.InputChanged:Connect(
			function(input)

				if not dragging
					or input ~= dragInput
					or not dragStart
					or not startPos
				then

					return
				end

				local delta =
					input.Position
					- dragStart

				if delta.Magnitude
					>= 4
				then

					moved =
						true
				end

				if moved then

					holder.Position =
						UDim2.new(
							startPos.X.Scale,
							startPos.X.Offset
								+ delta.X,

							startPos.Y.Scale,
							startPos.Y.Offset
								+ delta.Y
						)
				end
			end
		)
	)

	Track(
		button.MouseButton1Click:Connect(
			function()

				if moved then

					moved =
						false

					return
				end

				if callback then
					pcall(
						callback
					)
				end
			end
		)
	)

	return button,holder
end

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

		if MainFrame.Visible
			== false
		then

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
	"[Blizzard MM2 UI] Simple WindUI bridge V8.8.4 loaded"
)

return MM2
