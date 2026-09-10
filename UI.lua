--============================================================
-- Blizzard MM2 V8.8.4 UI
-- WindUI compatibility layer for the split MM2 project.
-- Replaces the old dashboard while preserving the existing UI API.
--============================================================

local MM2 = getgenv and getgenv().MM2_V85_SPLIT or _G.MM2_V85_SPLIT
assert(MM2, "Shared.lua must load first")

local Flags = MM2.Flags
local Track = MM2.Track
local PlayerGui = MM2.PlayerGui
local CoreGui = MM2.Services.CoreGui
local UIS = MM2.Services.UserInputService

MM2.UI = MM2.UI or {}
local UI = MM2.UI

-- Keep these for feature modules that use the old palette.
local COLORS = {
	Background = Color3.fromRGB(15,16,21),
	Panel = Color3.fromRGB(20,22,28),
	Sidebar = Color3.fromRGB(18,20,26),
	Card = Color3.fromRGB(26,29,36),
	CardHover = Color3.fromRGB(31,34,42),
	Stroke = Color3.fromRGB(52,57,70),
	Text = Color3.fromRGB(238,241,248),
	Muted = Color3.fromRGB(150,157,171),
	Accent = Color3.fromRGB(103,126,255),
	Accent2 = Color3.fromRGB(160,92,255),
	TrackOff = Color3.fromRGB(58,62,72),
	Knob = Color3.fromRGB(244,246,251),
	Danger = Color3.fromRGB(225,83,93),
}
UI.COLORS = COLORS

-- Clean up the legacy custom UI if this file is re-run.
for _, guiName in ipairs({
	"MM2_UTILITY_V8",
	"MM2_V8_ToolbarGui",
}) do
	local old = PlayerGui:FindFirstChild(guiName)
	if old then old:Destroy() end
	pcall(function()
		local coreOld = CoreGui:FindFirstChild(guiName)
		if coreOld then coreOld:Destroy() end
	end)
end

--============================================================
-- WINDUI
--============================================================

local WindUI = loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

UI.WindUI = WindUI

local Window = WindUI:CreateWindow({
	Title = "Blizzard MM2",
	Author = "V8.8.4",
	Folder = "BlizzardMM2",
	Icon = "snowflake",
	Theme = "Dark",
	Size = UDim2.fromOffset(580,430),
	Transparent = true,
	HideSearchBar = true,
	ScrollBarEnabled = false,
})

UI.Window = Window
UI.MainFrame = Window

-- WindUI owns the main ScreenGui. Keep this compatibility field available
-- for older modules, while special overlay buttons use a separate ScreenGui.
UI.ScreenGui = nil

--============================================================
-- TABS / OLD PAGE COMPATIBILITY
--============================================================

local Pages = {}
UI.Pages = Pages
UI.TabButtons = {}

local function NewPage(name, title, icon)
	local tab = Window:Tab({
		Title = title,
		Icon = icon,
	})
	Pages[name] = tab
	return tab
end

UI.VisualsPage  = NewPage("Visuals",  "Visuals",   "eye")
UI.CombatPage   = NewPage("Combat",   "Combat",    "crosshair")
UI.PlayerPage   = NewPage("Player",   "Player",    "shield")
UI.FlingPage    = NewPage("Fling",    "Fling",     "wind")
UI.AutoFarmPage = NewPage("AutoFarm", "Auto Farm", "bot")
UI.MiscPage     = NewPage("Misc",     "Misc",      "settings")

function UI.ShowPage(name)
	local page = Pages[name]
	if page and page.Select then
		page:Select()
	end
end

--============================================================
-- TOGGLE REGISTRY
--============================================================

UI.ToggleRegistry = UI.ToggleRegistry or {}

function UI.SetToggleState(flagName, value, runCallback)
	value = value == true
	Flags[flagName] = value

	local entry = UI.ToggleRegistry[flagName]

	if entry and entry.Render then
		entry.Render(value, false)
	end

	if runCallback and entry and entry.Callback then
		task.spawn(entry.Callback, value)
	end

	return value
end

UI.SetToggle = UI.SetToggleState

--============================================================
-- WINDUI BUILDERS - SAME API YOUR FEATURE FILES ALREADY USE
--============================================================

function UI.AddSection(parent, titleText, subtitleText)
	local section = parent:Section({
		Title = titleText,
		TextSize = 18,
	})

	-- WindUI's section title is the important visual piece. If a module
	-- supplies a subtitle, add it as a small paragraph beneath the section.
	if subtitleText and subtitleText ~= "" then
		pcall(function()
			parent:Paragraph({
				Title = subtitleText,
				Desc = "",
			})
		end)
	end

	return section
end

function UI.CreateToggle(parent, titleText, description, flagName, callback)
	local suppressCallback = false

	local toggle = parent:Toggle({
		Title = titleText,
		Desc = description or "",
		Value = Flags[flagName] == true,
		Callback = function(value)
			value = value == true
			Flags[flagName] = value

			if not suppressCallback and callback then
				callback(value)
			end
		end,
	})

	local function Render(value)
		value = value == true
		Flags[flagName] = value

		suppressCallback = true

		pcall(function()
			if toggle.Set then
				toggle:Set(value)
			elseif toggle.SetValue then
				toggle:SetValue(value)
			end
		end)

		suppressCallback = false
	end

	UI.ToggleRegistry[flagName] = {
		Control = toggle,
		Render = Render,
		Callback = callback,
	}

	return toggle, toggle, Render
end

function UI.CreateActionFeature(parent, titleText, description, callback)
	local button = parent:Button({
		Title = titleText,
		Desc = description or "",
		Icon = "mouse-pointer-click",
		Callback = function()
			if callback then
				task.spawn(callback)
			end
		end,
	})

	return button, button
end

function UI.CreateActionButton(parent, text, callback, style)
	local button = parent:Button({
		Title = text,
		Desc = style == "danger" and "Danger action" or "",
		Icon = style == "danger" and "triangle-alert" or "mouse-pointer-click",
		Callback = function()
			if callback then
				task.spawn(callback)
			end
		end,
	})

	return button
end

function UI.CreateValueControl(
	parent,
	labelText,
	getter,
	setter,
	minValue,
	maxValue,
	step
)
	local control

	-- Use a compact slider rather than the old +/- card.
	control = parent:Slider({
		Title = labelText,
		Desc = "",
		Step = step,
		Value = {
			Min = minValue,
			Max = maxValue,
			Default = getter(),
		},
		Callback = function(value)
			setter(value)
		end,
	})

	return control
end

function UI.CreateSlider(
	parent,
	labelText,
	description,
	getter,
	setter,
	minValue,
	maxValue,
	step
)
	local slider = parent:Slider({
		Title = labelText,
		Desc = description or "",
		Step = step,
		Value = {
			Min = minValue,
			Max = maxValue,
			Default = getter(),
		},
		Callback = function(value)
			setter(value)
		end,
	})

	return slider
end

--============================================================
-- SPECIAL ON-SCREEN BUTTONS
-- These are intentionally kept custom because they are game overlays,
-- not menu controls.
--============================================================

local OverlayGui = Instance.new("ScreenGui")
OverlayGui.Name = "BlizzardMM2_OverlayButtons"
OverlayGui.ResetOnSpawn = false
OverlayGui.IgnoreGuiInset = false
OverlayGui.DisplayOrder = 320

pcall(function()
	OverlayGui.Parent = CoreGui
end)

if not OverlayGui.Parent then
	OverlayGui.Parent = PlayerGui
end

UI.ScreenGui = OverlayGui
UI.OverlayGui = OverlayGui

-- Kept for modules that still call this helper.
local BlueCyanGradients = {}

local function CreateBlueCyanStroke(parent, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = thickness or 1.5
	stroke.Transparency = transparency or 0.10
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = parent

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(10,55,170)),
		ColorSequenceKeypoint.new(0.35, Color3.fromRGB(45,140,255)),
		ColorSequenceKeypoint.new(0.65, Color3.fromRGB(75,200,255)),
		ColorSequenceKeypoint.new(0.85, Color3.fromRGB(35,245,255)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(10,55,170)),
	})
	gradient.Parent = stroke

	BlueCyanGradients[#BlueCyanGradients+1] = gradient
	return stroke, gradient
end

UI.CreateBlueCyanStroke = CreateBlueCyanStroke

task.spawn(function()
	local rotation = 0

	while MM2.Running do
		rotation = (rotation + 1) % 360

		for i = #BlueCyanGradients, 1, -1 do
			local gradient = BlueCyanGradients[i]

			if gradient and gradient.Parent then
				gradient.Rotation = rotation
			else
				table.remove(BlueCyanGradients, i)
			end
		end

		task.wait(0.03)
	end
end)

function UI.CreateMovableCircleButton(
	name,
	icon,
	labelText,
	startPosition,
	callback
)
	local holder = Instance.new("Frame")
	holder.Name = name .. "Holder"
	holder.Size = UDim2.fromOffset(104,84)
	holder.Position = startPosition
	holder.BackgroundTransparency = 1
	holder.Active = true
	holder.ZIndex = 320
	holder.Parent = OverlayGui

	local button = Instance.new("TextButton")
	button.Name = name
	button.AnchorPoint = Vector2.new(0.5,0)
	button.Position = UDim2.new(0.5,0,0,0)
	button.Size = UDim2.fromOffset(56,56)
	button.BackgroundColor3 = Color3.fromRGB(16,20,29)
	button.BackgroundTransparency = 0.08
	button.BorderSizePixel = 0

	local hasIcon = icon ~= nil and tostring(icon) ~= ""

	button.Text = hasIcon and tostring(icon) or tostring(labelText or name)
	button.TextColor3 = COLORS.Text
	button.TextSize = hasIcon and 22 or 9
	button.TextWrapped = not hasIcon
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = false
	button.Active = true
	button.ZIndex = 321
	button.Parent = holder

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1,0)
	corner.Parent = button

	CreateBlueCyanStroke(button,1.7,0.08)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1,0,0,24)
	label.Position = UDim2.fromOffset(0,59)
	label.BackgroundTransparency = 1
	label.Text = labelText or name
	label.Visible = hasIcon
	label.TextColor3 = COLORS.Text
	label.TextTransparency = 0.05
	label.TextSize = 9
	label.TextWrapped = true
	label.Font = Enum.Font.GothamBold
	label.ZIndex = 321
	label.Parent = holder

	local dragging, moved, dragStart, startPos = false, false, nil, nil

	Track(button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			moved = false
			dragStart = input.Position
			startPos = holder.Position
		end
	end))

	Track(UIS.InputChanged:Connect(function(input)
		if not dragging or not dragStart or not startPos then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then
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

	Track(UIS.InputEnded:Connect(function(input)
		if not dragging then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false

			if not moved and callback then
				task.spawn(callback)
			end
		end
	end))

	return button, holder, label
end

-- Start on Visuals to match the old UI's first tab.
task.defer(function()
	pcall(function()
		UI.VisualsPage:Select()
	end)
end)

return MM2
