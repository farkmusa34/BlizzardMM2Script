--============================================================
-- Blizzard MM2 V8.8.4 - UI.lua
-- WindUI front-end + legacy compatibility layer V2.
--
-- Goal:
--   Keep Visuals.lua / Combat.lua / AutoFarm.lua / Player.lua /
--   Fling.lua / Misc.lua / Main.lua unchanged while replacing the
--   main menu controls with WindUI.
--
-- Important compatibility guarantees:
--   * UI.ScreenGui is a real ScreenGui Instance.
--   * UI.ToolbarGui is a real ScreenGui with FloatingOutline.
--   * UI.*Page fields are real ScrollingFrame Instances so older
--     modules can still do: SomeFrame.Parent = UI.FlingPage
--   * Builder calls are routed to the matching WindUI tab/section.
--   * CreateToggle still returns a third "render" function.
--   * SetToggleState can update a WindUI toggle without firing its
--     callback when runCallback == false.
--============================================================

local MM2 = getgenv and getgenv().MM2_V85_SPLIT or _G.MM2_V85_SPLIT
assert(MM2, "Shared.lua must load first")

local S = MM2.Services
local Flags = MM2.Flags
local Track = MM2.Track
local PlayerGui = MM2.PlayerGui
local CoreGui = S.CoreGui
local UIS = S.UserInputService
local TweenService = S.TweenService

MM2.UI = MM2.UI or {}
local UI = MM2.UI

--============================================================
-- CLEAN OLD UI
--============================================================

for _,guiName in ipairs({
	"MM2_UTILITY_V8",
	"MM2_V8_ToolbarGui",
	"BlizzardMM2_Compat",
	"BlizzardMM2_OverlayButtons",
}) do
	local old = PlayerGui:FindFirstChild(guiName)
	if old then
		pcall(function() old:Destroy() end)
	end

	pcall(function()
		local oldCore = CoreGui:FindFirstChild(guiName)
		if oldCore then oldCore:Destroy() end
	end)
end

--============================================================
-- COLORS USED BY LEGACY DIRECT-INSTANCE UI
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
-- COMPATIBILITY SCREEN GUI
--============================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2_UTILITY_V8"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 80
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

UI.ScreenGui = ScreenGui
UI.Gui = ScreenGui

-- MainFrame remains a REAL Frame because old Misc.lua directly writes
-- UI.MainFrame.Visible = false.
local CompatMainFrame = Instance.new("Frame")
CompatMainFrame.Name = "CompatMainFrame"
CompatMainFrame.BackgroundTransparency = 1
CompatMainFrame.BorderSizePixel = 0
CompatMainFrame.AnchorPoint = Vector2.new(0.5,0.5)
CompatMainFrame.Position = UDim2.fromScale(0.5,0.5)
CompatMainFrame.Size = UDim2.fromOffset(580,430)
CompatMainFrame.Visible = true
CompatMainFrame.Active = false
CompatMainFrame.Parent = ScreenGui

UI.MainFrame = CompatMainFrame
UI.Main = CompatMainFrame

--============================================================
-- EXACT OLD HAND-DRAWN BLIZZARD SNOWFLAKE
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
	holder.Name = "BlizzardSnowflake"
	holder.Size = UDim2.fromOffset(size,size)
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.Parent = parent

	local cx = size/2
	local cy = size/2
	local armLength = size*0.82
	local thickness = math.max(1,size*0.075)

	for _,rotation in ipairs({0,60,120}) do
		NewLine(holder,armLength,thickness,cx,cy,rotation,color,6)
	end

	local branchLength = size*0.25
	local branchOffset = size*0.27

	for _,rotation in ipairs({0,60,120,180,240,300}) do
		local radians = math.rad(rotation)
		local bx = cx + math.cos(radians)*branchOffset
		local by = cy + math.sin(radians)*branchOffset

		NewLine(
			holder,
			branchLength,
			thickness,
			bx,
			by,
			rotation+35,
			color,
			7
		)

		NewLine(
			holder,
			branchLength,
			thickness,
			bx,
			by,
			rotation-35,
			color,
			7
		)
	end

	return holder
end

UI.CreateSnowflake = CreateSnowflake

--============================================================
-- BLUE / CYAN STROKE COMPATIBILITY
--============================================================

function UI.CreateBlueCyanStroke(parent,thickness,transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = thickness or 1.4
	stroke.Transparency = transparency or 0.10
	stroke.Color = Color3.fromRGB(70,185,255)
	stroke.Parent = parent

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0,Color3.fromRGB(50,120,255)),
		ColorSequenceKeypoint.new(0.5,Color3.fromRGB(65,230,255)),
		ColorSequenceKeypoint.new(1,Color3.fromRGB(50,120,255)),
	})
	gradient.Parent = stroke

	task.spawn(function()
		while MM2.Running and gradient and gradient.Parent do
			gradient.Rotation = (gradient.Rotation + 2) % 360
			task.wait(0.03)
		end
	end)

	return stroke,gradient
end

--============================================================
-- WINDUI
--============================================================

local WindUI
do
	local ok,result = pcall(function()
		return loadstring(game:HttpGet(
			"https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
		))()
	end)

	if not ok or not result then
		error("Blizzard MM2: failed to load WindUI: "..tostring(result))
	end

	WindUI = result
end

UI.WindUI = WindUI

local Window = WindUI:CreateWindow({
	Title = "Blizzard MM2",
	Author = "V8.8.4",
	Folder = "BlizzardMM2",
	Icon = "", -- exact Blizzard snowflake is overlaid below.
	Theme = "Dark",
	Size = UDim2.fromOffset(580,430),
	Transparent = true,
	HideSearchBar = true,
	ScrollBarEnabled = false,
})

UI.Window = Window

-- Use our exact Blizzard toolbar instead of WindUI's generic opener.
pcall(function()
	if Window.EditOpenButton then
		Window:EditOpenButton({Enabled = false})
	end
end)

--============================================================
-- PAGE / TAB BRIDGE
--
-- UI.*Page MUST remain Instances for old direct-parent code.
-- Each Instance page is mapped to one WindUI tab for builder calls.
--============================================================

local PAGE_ORDER = {
	{"Visuals","Visuals","eye"},
	{"Combat","Combat","crosshair"},
	{"Player","Player","shield"},
	{"Fling","Fling","wind"},
	{"AutoFarm","Auto Farm","bot"},
	{"Misc","Misc","settings"},
}

local PageToTab = {}
local NameToPage = {}
local NameToTab = {}
local CurrentSection = {}
local ActivePageName = "Visuals"

UI.Pages = NameToPage
UI.TabButtons = NameToTab

local LegacyContentHolder = Instance.new("Frame")
LegacyContentHolder.Name = "LegacyContentHolder"
LegacyContentHolder.BackgroundTransparency = 1
LegacyContentHolder.BorderSizePixel = 0
LegacyContentHolder.AnchorPoint = Vector2.new(0,0)
LegacyContentHolder.Position = UDim2.fromOffset(170,58)
LegacyContentHolder.Size = UDim2.new(1,-184,1,-72)
LegacyContentHolder.ClipsDescendants = true
LegacyContentHolder.Active = false
LegacyContentHolder.Visible = false
LegacyContentHolder.Parent = ScreenGui

local function MakeLegacyPage(name)
	local page = Instance.new("ScrollingFrame")
	page.Name = name.."Page"
	page.Size = UDim2.fromScale(1,1)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 0
	page.ScrollingEnabled = false
	page.CanvasSize = UDim2.fromOffset(0,0)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.Visible = false
	page.Active = false
	page.Position = UDim2.fromOffset(-10000,-10000)
	page.ZIndex = 1
	page.Parent = LegacyContentHolder

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0,10)
	padding.PaddingRight = UDim.new(0,10)
	padding.PaddingTop = UDim.new(0,8)
	padding.PaddingBottom = UDim.new(0,8)
	padding.Parent = page

	local layout = Instance.new("UIListLayout")
	layout.Name = "LegacyLayout"
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0,8)
	layout.Parent = page

	return page
end

local function AddLegacySpacer(page,height)
	-- Compatibility pages are storage-only in V2.
	-- Visible spacing is handled entirely by WindUI.
	return nil
end

local function SetLegacyPageVisible(name)
	ActivePageName = name
	-- Legacy page Instances intentionally remain hidden.
end

for _,info in ipairs(PAGE_ORDER) do
	local name,title,icon = info[1],info[2],info[3]

	local page = MakeLegacyPage(name)
	local tab = Window:Tab({
		Title = title,
		Icon = icon,
	})

	NameToPage[name] = page
	NameToTab[name] = tab
	PageToTab[page] = tab

	UI[name.."Page"] = page

end

--============================================================
-- WINDUI TARGET HELPERS
--============================================================

local function ResolveTab(parent)
	if PageToTab[parent] then
		return PageToTab[parent]
	end

	-- Allows a WindUI tab/section to be passed directly too.
	if type(parent) == "table" then
		return parent
	end

	return nil
end

local function ResolveBuilderParent(parent)
	if CurrentSection[parent] then
		return CurrentSection[parent]
	end

	return ResolveTab(parent)
end

--============================================================
-- SHOW PAGE
--============================================================

function UI.ShowPage(name)
	name = tostring(name or "Visuals")
	local tab = NameToTab[name]

	if not tab then
		return false
	end

	SetLegacyPageVisible(name)

	pcall(function()
		tab:Select()
	end)

	return true
end

--============================================================
-- SECTIONS
--============================================================

function UI.AddSection(parent,titleText,subtitleText)
	local tab = ResolveTab(parent)
	if not tab then
		warn("[Blizzard MM2 UI] Missing WindUI tab for section:",titleText)
		return nil
	end

	local section
	local ok,result = pcall(function()
		return tab:Section({
			Title = tostring(titleText or ""),
			Desc = tostring(subtitleText or ""),
			Box = true,
			Opened = true,
		})
	end)

	if ok and result then
		section = result
	else
		local ok2,result2 = pcall(function()
			return tab:Section({
				Title = tostring(titleText or ""),
				Box = true,
				Opened = true,
			})
		end)

		if ok2 and result2 then
			section = result2
		else
			warn("[Blizzard MM2 UI] Section create failed:",titleText,result,result2)
			section = tab
		end
	end

	CurrentSection[parent] = section
	return section
end
end

--============================================================
-- TOGGLE REGISTRY / SETTER
--============================================================

UI.ToggleRegistry = UI.ToggleRegistry or {}

function UI.SetToggleState(flagName,value,runCallback)
	local record = UI.ToggleRegistry[flagName]

	Flags[flagName] = value == true

	if record and record.Render then
		record.Render(Flags[flagName],runCallback == true)
	elseif runCallback == true and record and record.Callback then
		record.Callback(Flags[flagName])
	end

	return Flags[flagName]
end

UI.SetToggle = UI.SetToggleState

--============================================================
-- CREATE TOGGLE
--
-- Return contract intentionally preserved:
--   control, control, render
--============================================================

function UI.CreateToggle(parent,titleText,description,flagName,callback)
	local container = ResolveBuilderParent(parent)
	if not container then
		return nil,nil,function() end
	end

	AddLegacySpacer(parent,58)

	Flags[flagName] = Flags[flagName] == true

	local suppressCallback = false
	local control

	local ok,result = pcall(function()
		return container:Toggle({
			Title = tostring(titleText or ""),
			Desc = tostring(description or ""),
			Value = Flags[flagName],
			Callback = function(on)
				on = on == true

				if suppressCallback then
					Flags[flagName] = on
					return
				end

				Flags[flagName] = on

				if callback then
					local cbOk,cbErr = pcall(callback,on)
					if not cbOk then
						warn("[Blizzard MM2 UI Toggle]",flagName,cbErr)
					end
				end
			end,
		})
	end)

	if ok then
		control = result
	else
		warn("[Blizzard MM2 UI] Toggle create failed:",titleText,result)
	end

	local function Render(value,runCallback)
		value = value == true
		Flags[flagName] = value

		if control and control.Set then
			suppressCallback = true
			pcall(function()
				control:Set(value)
			end)
			suppressCallback = false
		end

		if runCallback and callback then
			local cbOk,cbErr = pcall(callback,value)
			if not cbOk then
				warn("[Blizzard MM2 UI Toggle Render]",flagName,cbErr)
			end
		end

		return value
	end

	UI.ToggleRegistry[flagName] = {
		Control = control,
		Render = Render,
		Callback = callback,
	}

	return control,control,Render
end

--============================================================
-- ACTION FEATURE / BUTTON
--============================================================

function UI.CreateActionFeature(parent,titleText,description,callback)
	local container = ResolveBuilderParent(parent)
	if not container then
		return nil
	end

	AddLegacySpacer(parent,58)

	local control
	local ok,result = pcall(function()
		return container:Button({
			Title = tostring(titleText or ""),
			Desc = tostring(description or ""),
			Callback = function()
				if callback then
					local cbOk,cbErr = pcall(callback)
					if not cbOk then
						warn("[Blizzard MM2 UI Action]",titleText,cbErr)
					end
				end
			end,
		})
	end)

	if ok then
		control = result
	else
		warn("[Blizzard MM2 UI] Action create failed:",titleText,result)
	end

	return control
end

function UI.CreateActionButton(parent,text,callback,style)
	-- When called with a page, use WindUI.
	if PageToTab[parent] or type(parent) == "table" then
		return UI.CreateActionFeature(parent,text,"",callback)
	end

	-- Legacy fallback for any custom Instance container.
	if typeof(parent) == "Instance" then
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1,0,0,34)
		button.BackgroundColor3 =
			style == "danger" and COLORS.Danger or COLORS.Card
		button.BorderSizePixel = 0
		button.Text = tostring(text or "ACTION")
		button.TextColor3 = COLORS.Text
		button.TextSize = 11
		button.Font = Enum.Font.GothamBold
		button.Parent = parent

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0,9)
		corner.Parent = button

		Track(button.MouseButton1Click:Connect(function()
			if callback then
				pcall(callback)
			end
		end))

		return button
	end

	return nil
end

--============================================================
-- SLIDERS
--============================================================

local function MakeWindSlider(parent,labelText,description,getter,setter,minValue,maxValue,step)
	local container = ResolveBuilderParent(parent)
	if not container then
		return nil
	end

	AddLegacySpacer(parent,68)

	minValue = tonumber(minValue) or 0
	maxValue = tonumber(maxValue) or 100
	step = tonumber(step) or 1

	local defaultValue = minValue
	if getter then
		local ok,value = pcall(getter)
		if ok and tonumber(value) then
			defaultValue = tonumber(value)
		end
	end

	defaultValue = math.clamp(defaultValue,minValue,maxValue)

	local suppress = false
	local slider

	local ok,result = pcall(function()
		return container:Slider({
			Title = tostring(labelText or ""),
			Desc = tostring(description or ""),
			Step = step,
			Value = {
				Min = minValue,
				Max = maxValue,
				Default = defaultValue,
			},
			Callback = function(value)
				if suppress then return end
				value = tonumber(value) or defaultValue

				if setter then
					local setOk,setErr = pcall(setter,value)
					if not setOk then
						warn("[Blizzard MM2 UI Slider]",labelText,setErr)
					end
				end
			end,
		})
	end)

	if ok then
		slider = result
	else
		warn("[Blizzard MM2 UI] Slider create failed:",labelText,result)
	end

	local function Render(value,runSetter)
		value = math.clamp(
			tonumber(value) or defaultValue,
			minValue,
			maxValue
		)

		if slider and slider.Set then
			suppress = true
			pcall(function()
				slider:Set(value)
			end)
			suppress = false
		end

		if runSetter and setter then
			pcall(setter,value)
		end

		return value
	end

	return slider,Render
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
	return MakeWindSlider(
		parent,
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
	parent,
	labelText,
	getter,
	setter,
	minValue,
	maxValue,
	step
)
	return MakeWindSlider(
		parent,
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
-- LEGACY PAGE HOSTS
--
-- Direct-instance UI created by older modules is retained here so
-- their code does not error. These hosts are intentionally hidden;
-- WindUI is the only visible main-menu renderer.
--============================================================

--============================================================
-- FLOATING / MOVABLE CIRCLE BUTTONS
--============================================================

function UI.CreateMovableCircleButton(
	name,
	icon,
	labelText,
	startPosition,
	callback
)
	local holder = Instance.new("Frame")
	holder.Name = tostring(name or "FloatingButton").."Holder"
	holder.AnchorPoint = Vector2.new(0.5,0.5)
	holder.Position = startPosition or UDim2.new(0.8,0,0.75,0)
	holder.Size = UDim2.fromOffset(84,84)
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.Active = true
	holder.ZIndex = 250
	holder.Parent = ScreenGui

	local button = Instance.new("TextButton")
	button.Name = tostring(name or "FloatingButton")
	button.AnchorPoint = Vector2.new(0.5,0.5)
	button.Position = UDim2.fromScale(0.5,0.42)
	button.Size = UDim2.fromOffset(54,54)
	button.BackgroundColor3 = Color3.fromRGB(18,20,26)
	button.BackgroundTransparency = 0.08
	button.BorderSizePixel = 0
	button.Text = tostring(icon or "")
	button.TextColor3 = COLORS.Text
	button.TextSize = 22
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = true
	button.Active = true
	button.ZIndex = 251
	button.Parent = holder

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1,0)
	corner.Parent = button

	UI.CreateBlueCyanStroke(button,1.5,0.12)

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.AnchorPoint = Vector2.new(0.5,0)
	label.Position = UDim2.new(0.5,0,1,-18)
	label.Size = UDim2.new(1.8,0,0,18)
	label.BackgroundTransparency = 1
	label.Text = tostring(labelText or "")
	label.TextColor3 = COLORS.Text
	label.TextStrokeTransparency = 0.5
	label.TextSize = 9
	label.Font = Enum.Font.GothamBold
	label.ZIndex = 252
	label.Parent = holder

	local dragging = false
	local moved = false
	local dragStart
	local startPos
	local dragInput

	Track(button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			moved = false
			dragStart = input.Position
			startPos = holder.Position

			Track(input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if moved then
						holder:SetAttribute("_JustDragged",true)
						task.delay(0.12,function()
							if holder and holder.Parent then
								holder:SetAttribute("_JustDragged",false)
							end
						end)
					end
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
		if not dragging
			or input ~= dragInput
			or not dragStart
			or not startPos
		then
			return
		end

		local delta = input.Position-dragStart
		if delta.Magnitude >= 4 then
			moved = true
		end

		if moved then
			holder.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset+delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset+delta.Y
			)
		end
	end))

	Track(button.MouseButton1Click:Connect(function()
		if holder:GetAttribute("_JustDragged") then
			return
		end

		if callback then
			pcall(callback)
		end
	end))

	return button,holder
end

--============================================================
-- EXACT BLIZZARD FLOATING TOOLBAR
--
-- Visuals.lua expects:
--   UI.ToolbarGui
--   ToolbarGui:FindFirstChild("FloatingOutline")
--============================================================

local ToolbarGui = Instance.new("ScreenGui")
ToolbarGui.Name = "MM2_V8_ToolbarGui"
ToolbarGui.ResetOnSpawn = false
ToolbarGui.IgnoreGuiInset = true
ToolbarGui.DisplayOrder = 100
ToolbarGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ToolbarGui.Parent = PlayerGui

UI.ToolbarGui = ToolbarGui

local FloatingOutline = Instance.new("Frame")
FloatingOutline.Name = "FloatingOutline"
FloatingOutline.AnchorPoint = Vector2.new(0.5,0)
FloatingOutline.Position = UDim2.new(0.5,0,0,12)
FloatingOutline.Size = UDim2.fromOffset(152,42)
FloatingOutline.BackgroundColor3 = Color3.fromRGB(15,17,23)
FloatingOutline.BackgroundTransparency = 0.08
FloatingOutline.BorderSizePixel = 0
FloatingOutline.Active = true
FloatingOutline.ZIndex = 100
FloatingOutline.Parent = ToolbarGui

local ToolbarCorner = Instance.new("UICorner")
ToolbarCorner.CornerRadius = UDim.new(1,0)
ToolbarCorner.Parent = FloatingOutline

UI.CreateBlueCyanStroke(FloatingOutline,1.4,0.12)

local ToolbarButton = Instance.new("TextButton")
ToolbarButton.Name = "OpenMenu"
ToolbarButton.Size = UDim2.fromScale(1,1)
ToolbarButton.BackgroundTransparency = 1
ToolbarButton.BorderSizePixel = 0
ToolbarButton.Text = ""
ToolbarButton.Active = true
ToolbarButton.AutoButtonColor = false
ToolbarButton.ZIndex = 101
ToolbarButton.Parent = FloatingOutline

local ToolbarSnowflake = CreateSnowflake(ToolbarButton,20,COLORS.Text)
ToolbarSnowflake.Position = UDim2.fromOffset(14,11)
ToolbarSnowflake.ZIndex = 103

local ToolbarTitle = Instance.new("TextLabel")
ToolbarTitle.Name = "Title"
ToolbarTitle.Position = UDim2.fromOffset(44,0)
ToolbarTitle.Size = UDim2.new(1,-52,1,0)
ToolbarTitle.BackgroundTransparency = 1
ToolbarTitle.Text = "Blizzard MM2"
ToolbarTitle.TextColor3 = COLORS.Text
ToolbarTitle.TextSize = 12
ToolbarTitle.Font = Enum.Font.GothamBold
ToolbarTitle.TextXAlignment = Enum.TextXAlignment.Left
ToolbarTitle.ZIndex = 102
ToolbarTitle.Parent = ToolbarButton

-- Movable toolbar, preserving click-to-toggle.
do
	local dragging = false
	local moved = false
	local dragStart
	local startPosition
	local dragInput

	Track(ToolbarButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			moved = false
			dragStart = input.Position
			startPosition = FloatingOutline.Position

			Track(input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end))
		end
	end))

	Track(ToolbarButton.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragInput = input
		end
	end))

	Track(UIS.InputChanged:Connect(function(input)
		if not dragging
			or input ~= dragInput
			or not dragStart
			or not startPosition
		then
			return
		end

		local delta = input.Position-dragStart

		if delta.Magnitude >= 5 then
			moved = true
		end

		if moved then
			FloatingOutline.Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset+delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset+delta.Y
			)
		end
	end))

	Track(ToolbarButton.MouseButton1Click:Connect(function()
		if moved then
			moved = false
			return
		end

		pcall(function()
			if Window.Toggle then
				Window:Toggle()
			end
		end)

	end))
end

--============================================================
-- HEADER BRANDING COMPATIBILITY
--============================================================

-- Keep the exact old snowflake available to the compatibility layer.
-- WindUI itself remains unobstructed; no transparent overlay is placed
-- over its window.
local HeaderSnowflake = CreateSnowflake(CompatMainFrame,22,COLORS.Text)
HeaderSnowflake.Name = "HeaderBlizzardSnowflake"
HeaderSnowflake.Position = UDim2.fromOffset(16,15)
HeaderSnowflake.Visible = false

-- Old Misc.lua may write UI.MainFrame.Visible = false. Mirror that into
-- WindUI only when it transitions from visible -> hidden.
local lastCompatVisible = CompatMainFrame.Visible

Track(CompatMainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
	local nowVisible = CompatMainFrame.Visible
	if lastCompatVisible and not nowVisible then
		pcall(function()
			if Window.Toggle then
				Window:Toggle()
			elseif Window.Close then
				Window:Close()
			end
		end)
	end
	lastCompatVisible = nowVisible
end))

-- Main.lua destroys UI.ScreenGui during cleanup. Ensure WindUI follows.
Track(ScreenGui.Destroying:Connect(function()
	pcall(function()
		if Window and Window.Destroy then
			Window:Destroy()
		end
	end)
end))

--============================================================
-- INITIAL PAGE
--============================================================

UI.ShowPage("Visuals")

print("[Blizzard MM2 UI] WindUI compatibility layer V8.8.4 V2 loaded")

return MM2
