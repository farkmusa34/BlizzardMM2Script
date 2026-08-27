--============================================================
-- MM2 V8.5 SPLIT BUILD - UI.lua
-- Dashboard, tabs, toolbar, builders.
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

for _, guiName in ipairs({"MM2_UTILITY_V8","MM2_V8_TracerGui","MM2_V8_PlayerESP_Gui","MM2_V8_ToolbarGui"}) do
	local old = PlayerGui:FindFirstChild(guiName)
	if old then old:Destroy() end
end
pcall(function()
	local old = CoreGui:FindFirstChild("MM2_UTILITY_V8")
	if old then old:Destroy() end
	local oldToolbar = CoreGui:FindFirstChild("MM2_V8_ToolbarGui")
	if oldToolbar then oldToolbar:Destroy() end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2_UTILITY_V8"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = false
ScreenGui.DisplayOrder = 10
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = PlayerGui end

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
MM2.UI.ScreenGui = ScreenGui
MM2.UI.COLORS = COLORS

local MainFrame = Instance.new("Frame")
MainFrame.Name = "Dashboard"
MainFrame.Size = UDim2.fromOffset(518,345)
MainFrame.Position = UDim2.new(0.5,-242,0.5,-198)
MainFrame.BackgroundColor3 = COLORS.Background
MainFrame.BackgroundTransparency = 0.04
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui
MM2.UI.MainFrame = MainFrame
local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0,16)
MainCorner.Parent = MainFrame
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = COLORS.Stroke
MainStroke.Thickness = 1
MainStroke.Transparency = 0.15
MainStroke.Parent = MainFrame

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1,0,0,54)
Header.BackgroundTransparency = 1
Header.Parent = MainFrame

local Logo = Instance.new("TextLabel")
Logo.Size = UDim2.new(0,36,0,36)
Logo.Position = UDim2.fromOffset(16,9)
Logo.BackgroundColor3 = COLORS.Card
Logo.BorderSizePixel = 0
Logo.Text = "❄"
Logo.TextColor3 = COLORS.Text
Logo.TextSize = 19
Logo.Font = Enum.Font.GothamBold
Logo.Parent = Header
local lc = Instance.new("UICorner")
lc.CornerRadius = UDim.new(0,10)
lc.Parent = Logo

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0,250,0,24)
Title.Position = UDim2.fromOffset(62,8)
Title.BackgroundTransparency = 1
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Text = "MURDER MYSTERY 2 SCRIPT"
Title.TextColor3 = COLORS.Text
Title.TextSize = 13
Title.Font = Enum.Font.GothamBold
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(0,280,0,18)
Subtitle.Position = UDim2.fromOffset(62,29)
Subtitle.BackgroundTransparency = 1
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Text = "Personal utility dashboard"
Subtitle.TextColor3 = COLORS.Muted
Subtitle.TextSize = 10
Subtitle.Font = Enum.Font.Gotham
Subtitle.Parent = Header

local VersionLabel = Instance.new("TextLabel")
VersionLabel.Size = UDim2.fromOffset(52,24)
VersionLabel.Position = UDim2.new(1,-100,0,15)
VersionLabel.BackgroundColor3 = COLORS.Card
VersionLabel.BorderSizePixel = 0
VersionLabel.Text = "V8.5"
VersionLabel.TextColor3 = COLORS.Muted
VersionLabel.TextSize = 10
VersionLabel.Font = Enum.Font.GothamBold
VersionLabel.Parent = Header

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.fromOffset(30,30)
CloseButton.Position = UDim2.new(1,-42,0,12)
CloseButton.BackgroundColor3 = COLORS.Card
CloseButton.BorderSizePixel = 0
CloseButton.Text = "×"
CloseButton.TextColor3 = COLORS.Text
CloseButton.TextSize = 20
CloseButton.Font = Enum.Font.GothamMedium
CloseButton.AutoButtonColor = false
CloseButton.Parent = Header

local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(1,-24,0,1)
Divider.Position = UDim2.fromOffset(12,54)
Divider.BackgroundColor3 = COLORS.Stroke
Divider.BackgroundTransparency = 0.35
Divider.BorderSizePixel = 0
Divider.Parent = MainFrame

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0,126,1,-68)
Sidebar.Position = UDim2.fromOffset(12,62)
Sidebar.BackgroundColor3 = COLORS.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1,-150,1,-68)
Content.Position = UDim2.fromOffset(138,62)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

do
	local dragging, dragStart, startPos = false,nil,nil
	Header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = MainFrame.Position
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			MainFrame.Position = UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
		end
	end)
	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

local ToolbarGui = Instance.new("ScreenGui")
ToolbarGui.Name = "MM2_V8_ToolbarGui"
ToolbarGui.ResetOnSpawn = false
ToolbarGui.IgnoreGuiInset = false
ToolbarGui.DisplayOrder = 5
pcall(function() ToolbarGui.Parent = CoreGui end)
if not ToolbarGui.Parent then ToolbarGui.Parent = PlayerGui end
MM2.UI.ToolbarGui = ToolbarGui

local Floating = Instance.new("Frame")
Floating.Name = "FloatingOpener"
Floating.Size = UDim2.fromOffset(190,38)
Floating.Position = UDim2.new(0.5,-95,0.15,-94)
Floating.BackgroundColor3 = Color3.fromRGB(18,20,26)
Floating.BackgroundTransparency = 0.42
Floating.BorderSizePixel = 0
Floating.Active = true
Floating.Parent = ToolbarGui

local RGBStroke = Instance.new("UIStroke")
RGBStroke.Thickness = 1.5
RGBStroke.Transparency = 0.08
RGBStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
RGBStroke.Parent = Floating
local RGBGradient = Instance.new("UIGradient")
RGBGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0.00,Color3.fromRGB(70,235,255)),
	ColorSequenceKeypoint.new(0.25,Color3.fromRGB(60,180,255)),
	ColorSequenceKeypoint.new(0.50,Color3.fromRGB(70,110,255)),
	ColorSequenceKeypoint.new(0.75,Color3.fromRGB(105,80,255)),
	ColorSequenceKeypoint.new(1.00,Color3.fromRGB(70,235,255)),
})
RGBGradient.Parent = RGBStroke

task.spawn(function()
	while MM2.Running and RGBGradient.Parent do
		RGBGradient.Rotation = (RGBGradient.Rotation + 1.4) % 360
		task.wait(0.025)
	end
end)

local DragHandle = Instance.new("TextButton")
DragHandle.Size = UDim2.fromOffset(32,38)
DragHandle.BackgroundTransparency = 1
DragHandle.AutoButtonColor = false
DragHandle.Active = true
DragHandle.Text = "≡"
DragHandle.TextColor3 = COLORS.Muted
DragHandle.TextSize = 17
DragHandle.Font = Enum.Font.GothamBold
DragHandle.Parent = Floating

local OpenButton = Instance.new("TextButton")
OpenButton.Size = UDim2.new(1,-38,1,0)
OpenButton.Position = UDim2.fromOffset(38,0)
OpenButton.BackgroundTransparency = 1
OpenButton.Text = "❄ Murder Mystery 2 Script"
OpenButton.TextColor3 = COLORS.Text
OpenButton.TextSize = 9
OpenButton.Font = Enum.Font.GothamBold
OpenButton.Parent = Floating

do
	local dragging, dragStart, startPos = false,nil,nil
	DragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = Floating.Position
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			Floating.Position = UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
		end
	end)
	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
end

Track(CloseButton.MouseButton1Click:Connect(function() MainFrame.Visible = false end))
Track(OpenButton.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end))

local Pages, TabButtons = {}, {}
MM2.UI.Pages, MM2.UI.TabButtons = Pages, TabButtons

local function NewPage(name)
	local page = Instance.new("ScrollingFrame")
	page.Name = name .. "Page"
	page.Size = UDim2.fromScale(1,1)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 4
	page.ScrollBarImageColor3 = COLORS.Stroke
	page.CanvasSize = UDim2.fromOffset(0,0)
	page.Visible = false
	page.Parent = Content
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0,10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = page
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0,2)
	padding.PaddingLeft = UDim.new(0,2)
	padding.PaddingRight = UDim.new(0,8)
	padding.PaddingBottom = UDim.new(0,10)
	padding.Parent = page
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		page.CanvasSize = UDim2.fromOffset(0,layout.AbsoluteContentSize.Y+18)
	end)
	Pages[name] = page
	return page
end

MM2.UI.VisualsPage = NewPage("Visuals")
MM2.UI.CombatPage = NewPage("Combat")
MM2.UI.PlayerPage = NewPage("Player")
MM2.UI.FlingPage = NewPage("Fling")
MM2.UI.AutoFarmPage = NewPage("AutoFarm")

function MM2.UI.ShowPage(name)
	for pageName,page in pairs(Pages) do page.Visible = pageName == name end
	for tabName,btn in pairs(TabButtons) do
		btn.BackgroundColor3 = tabName == name and COLORS.Card or Color3.fromRGB(0,0,0)
		btn.BackgroundTransparency = tabName == name and 0 or 1
		btn.TextColor3 = tabName == name and COLORS.Text or COLORS.Muted
	end
end

local function AddSidebarButton(name,label,order)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(1,-12,0,34)
	btn.Position = UDim2.fromOffset(6,8+((order-1)*38))
	btn.BackgroundTransparency = 1
	btn.BorderSizePixel = 0
	btn.Text = label
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.TextColor3 = COLORS.Muted
	btn.TextSize = 10
	btn.Font = Enum.Font.GothamBold
	btn.AutoButtonColor = false
	btn.Parent = Sidebar
	TabButtons[name] = btn
	Track(btn.MouseButton1Click:Connect(function() MM2.UI.ShowPage(name) end))
end

AddSidebarButton("Visuals","◉ VISUALS",1)
AddSidebarButton("Combat","◉ COMBAT",2)
AddSidebarButton("Player","◉ PLAYER",3)
AddSidebarButton("Fling","◉ FLING",4)
AddSidebarButton("AutoFarm","◉ AUTO FARM",5)

function MM2.UI.AddSection(parent,titleText,subtitleText)
	local wrap = Instance.new("Frame")
	wrap.Size = UDim2.new(1,0,0,subtitleText and 52 or 34)
	wrap.BackgroundTransparency = 1
	wrap.Parent = parent
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1,0,0,22)
	title.BackgroundTransparency = 1
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = titleText
	title.TextColor3 = COLORS.Text
	title.TextSize = 14
	title.Font = Enum.Font.GothamBold
	title.Parent = wrap
	if subtitleText then
		local sub = Instance.new("TextLabel")
		sub.Size = UDim2.new(1,0,0,20)
		sub.Position = UDim2.fromOffset(0,24)
		sub.BackgroundTransparency = 1
		sub.TextXAlignment = Enum.TextXAlignment.Left
		sub.Text = subtitleText
		sub.TextColor3 = COLORS.Muted
		sub.TextSize = 10
		sub.Font = Enum.Font.Gotham
		sub.Parent = wrap
	end
	return wrap
end

function MM2.UI.CreateToggle(parent,titleText,description,flagName,callback)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1,0,0,64)
	card.BackgroundColor3 = COLORS.Card
	card.BorderSizePixel = 0
	card.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1,-104,0,22)
	label.Position = UDim2.fromOffset(14,10)
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = titleText
	label.TextColor3 = COLORS.Text
	label.TextSize = 12
	label.Font = Enum.Font.GothamBold
	label.Parent = card
	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1,-104,0,18)
	desc.Position = UDim2.fromOffset(14,34)
	desc.BackgroundTransparency = 1
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.Text = description or ""
	desc.TextColor3 = COLORS.Muted
	desc.TextSize = 9
	desc.Font = Enum.Font.Gotham
	desc.Parent = card
	local track = Instance.new("TextButton")
	track.Size = UDim2.fromOffset(48,24)
	track.Position = UDim2.new(1,-62,0.5,-12)
	track.BackgroundColor3 = COLORS.TrackOff
	track.BorderSizePixel = 0
	track.Text = ""
	track.AutoButtonColor = false
	track.Parent = card
	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(18,18)
	knob.Position = UDim2.fromOffset(3,3)
	knob.BackgroundColor3 = COLORS.Knob
	knob.BorderSizePixel = 0
	knob.Parent = track
	local function Render(value,instant)
		local d = instant and 0 or 0.14
		TweenService:Create(knob,TweenInfo.new(d,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
			Position = value and UDim2.fromOffset(27,3) or UDim2.fromOffset(3,3)
		}):Play()
		TweenService:Create(track,TweenInfo.new(d,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
			BackgroundColor3 = value and COLORS.Accent or COLORS.TrackOff
		}):Play()
	end
	Render(Flags[flagName],true)
	Track(track.MouseButton1Click:Connect(function()
		Flags[flagName] = not Flags[flagName]
		Render(Flags[flagName],false)
		if callback then callback(Flags[flagName]) end
	end))
	return card,track,Render
end

function MM2.UI.CreateActionButton(parent,text,callback,style)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1,0,0,42)
	button.BackgroundColor3 = style == "danger" and COLORS.Danger or COLORS.Accent
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = COLORS.Text
	button.TextSize = 11
	button.Font = Enum.Font.GothamBold
	button.Parent = parent
	Track(button.MouseButton1Click:Connect(callback))
	return button
end

function MM2.UI.CreateValueControl(parent,labelText,getter,setter,minValue,maxValue,step)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1,0,0,64)
	card.BackgroundColor3 = COLORS.Card
	card.BorderSizePixel = 0
	card.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1,-140,1,0)
	label.Position = UDim2.fromOffset(14,0)
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = labelText
	label.TextColor3 = COLORS.Text
	label.TextSize = 12
	label.Font = Enum.Font.GothamBold
	label.Parent = card
	local value = Instance.new("TextLabel")
	value.Size = UDim2.fromOffset(48,28)
	value.Position = UDim2.new(1,-110,0.5,-14)
	value.BackgroundColor3 = COLORS.Background
	value.BorderSizePixel = 0
	value.Text = tostring(getter())
	value.TextColor3 = COLORS.Text
	value.TextSize = 11
	value.Font = Enum.Font.GothamBold
	value.Parent = card
	local minus = Instance.new("TextButton")
	minus.Size = UDim2.fromOffset(26,28)
	minus.Position = UDim2.new(1,-138,0.5,-14)
	minus.BackgroundColor3 = COLORS.Background
	minus.BorderSizePixel = 0
	minus.Text = "−"
	minus.TextColor3 = COLORS.Text
	minus.Parent = card
	local plus = Instance.new("TextButton")
	plus.Size = UDim2.fromOffset(26,28)
	plus.Position = UDim2.new(1,-30,0.5,-14)
	plus.BackgroundColor3 = COLORS.Background
	plus.BorderSizePixel = 0
	plus.Text = "+"
	plus.TextColor3 = COLORS.Text
	plus.Parent = card
	local function update(v)
		v = math.clamp(v,minValue,maxValue)
		setter(v)
		value.Text = tostring(getter())
	end
	Track(minus.MouseButton1Click:Connect(function() update(getter()-step) end))
	Track(plus.MouseButton1Click:Connect(function() update(getter()+step) end))
	return card
end

function MM2.UI.CreateSlider(parent,labelText,description,getter,setter,minValue,maxValue,step)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1,0,0,78)
	card.BackgroundColor3 = COLORS.Card
	card.BorderSizePixel = 0
	card.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1,-80,0,20)
	label.Position = UDim2.fromOffset(14,9)
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = labelText
	label.TextColor3 = COLORS.Text
	label.TextSize = 12
	label.Font = Enum.Font.GothamBold
	label.Parent = card
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.fromOffset(54,20)
	valueLabel.Position = UDim2.new(1,-68,0,9)
	valueLabel.BackgroundTransparency = 1
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Text = tostring(getter())
	valueLabel.TextColor3 = COLORS.Text
	valueLabel.TextSize = 11
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.Parent = card
	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1,-28,0,16)
	desc.Position = UDim2.fromOffset(14,28)
	desc.BackgroundTransparency = 1
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.Text = description or ""
	desc.TextColor3 = COLORS.Muted
	desc.TextSize = 9
	desc.Font = Enum.Font.Gotham
	desc.Parent = card
	local bar = Instance.new("TextButton")
	bar.Size = UDim2.new(1,-28,0,8)
	bar.Position = UDim2.fromOffset(14,57)
	bar.BackgroundColor3 = COLORS.TrackOff
	bar.BorderSizePixel = 0
	bar.Text = ""
	bar.AutoButtonColor = false
	bar.Parent = card
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0,1)
	fill.BackgroundColor3 = COLORS.Accent
	fill.BorderSizePixel = 0
	fill.Parent = bar
	local knob = Instance.new("Frame")
	knob.AnchorPoint = Vector2.new(0.5,0.5)
	knob.Size = UDim2.fromOffset(16,16)
	knob.Position = UDim2.new(0,0,0.5,0)
	knob.BackgroundColor3 = COLORS.Knob
	knob.BorderSizePixel = 0
	knob.ZIndex = 3
	knob.Parent = bar
	local dragging = false
	local function snap(v)
		return math.clamp(math.floor(((v-minValue)/step)+0.5)*step+minValue,minValue,maxValue)
	end
	local function render(v)
		local alpha = math.clamp((v-minValue)/(maxValue-minValue),0,1)
		fill.Size = UDim2.fromScale(alpha,1)
		knob.Position = UDim2.new(alpha,0,0.5,0)
		valueLabel.Text = tostring(v)
	end
	local function setFromX(x)
		local width = math.max(bar.AbsoluteSize.X,1)
		local alpha = math.clamp((x-bar.AbsolutePosition.X)/width,0,1)
		local v = snap(minValue+(maxValue-minValue)*alpha)
		setter(v)
		render(getter())
	end
	render(getter())
	Track(bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromX(input.Position.X)
		end
	end))
	Track(UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setFromX(input.Position.X)
		end
	end))
	Track(UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end))
	return card
end

return MM2
