--============================================================
-- MM2 V8.7.1 UI
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
	Background = Color3.fromRGB(15,16,21), Panel = Color3.fromRGB(20,22,28),
	Sidebar = Color3.fromRGB(18,20,26), Card = Color3.fromRGB(26,29,36),
	CardHover = Color3.fromRGB(31,34,42), Stroke = Color3.fromRGB(52,57,70),
	Text = Color3.fromRGB(238,241,248), Muted = Color3.fromRGB(150,157,171),
	Accent = Color3.fromRGB(103,126,255), Accent2 = Color3.fromRGB(160,92,255),
	TrackOff = Color3.fromRGB(58,62,72), Knob = Color3.fromRGB(244,246,251),
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

local BlueCyanGradients = {}
local function CreateBlueCyanStroke(parent,thickness,transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = thickness or 1.5
	stroke.Transparency = transparency or 0.10
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = parent
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00,Color3.fromRGB(10,55,170)),
		ColorSequenceKeypoint.new(0.35,Color3.fromRGB(45,140,255)),
		ColorSequenceKeypoint.new(0.65,Color3.fromRGB(75,200,255)),
		ColorSequenceKeypoint.new(0.85,Color3.fromRGB(35,245,255)),
		ColorSequenceKeypoint.new(1.00,Color3.fromRGB(10,55,170)),
	})
	gradient.Parent = stroke
	BlueCyanGradients[#BlueCyanGradients+1] = gradient
	return stroke,gradient
end
MM2.UI.CreateBlueCyanStroke = CreateBlueCyanStroke
CreateBlueCyanStroke(MainFrame,1.5,0.08)

task.spawn(function()
	local rotation = 0
	while MM2.Running do
		rotation = (rotation + 1) % 360
		for i = #BlueCyanGradients,1,-1 do
			local gradient = BlueCyanGradients[i]
			if gradient and gradient.Parent then gradient.Rotation = rotation else table.remove(BlueCyanGradients,i) end
		end
		task.wait(0.03)
	end
end)

local function NewLine(parent,w,h,x,y,rotation,color,z)
	local line = Instance.new("Frame")
	line.AnchorPoint = Vector2.new(0.5,0.5)
	line.Size = UDim2.fromOffset(w,h)
	line.Position = UDim2.fromOffset(x,y)
	line.Rotation = rotation or 0
	line.BackgroundColor3 = color
	line.BorderSizePixel = 0
	line.ZIndex = z or 1
	line.Parent = parent
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1,0)
	c.Parent = line
	return line
end

local function CreateSnowflake(parent,size,color)
	local holder = Instance.new("Frame")
	holder.Size = UDim2.fromOffset(size,size)
	holder.BackgroundTransparency = 1
	holder.Parent = parent

	local cx,cy = size/2,size/2
	local armLength = size*0.78
	local thickness = math.max(1.4,size*0.075)

	-- Six main arms.
	for _,rotation in ipairs({0,60,120}) do
		NewLine(holder,armLength,thickness,cx,cy,rotation,color,3)
	end

	-- Branches on each arm make this read as a real snowflake,
	-- instead of the old simple asterisk.
	for _,rotation in ipairs({0,60,120,180,240,300}) do
		local rad = math.rad(rotation)
		local branchCenterX = cx + math.cos(rad)*(size*0.27)
		local branchCenterY = cy + math.sin(rad)*(size*0.27)

		NewLine(holder,size*0.22,thickness*0.82,
			branchCenterX + math.cos(math.rad(rotation+35))*(size*0.045),
			branchCenterY + math.sin(math.rad(rotation+35))*(size*0.045),
			rotation+35,color,3)

		NewLine(holder,size*0.22,thickness*0.82,
			branchCenterX + math.cos(math.rad(rotation-35))*(size*0.045),
			branchCenterY + math.sin(math.rad(rotation-35))*(size*0.045),
			rotation-35,color,3)
	end

	return holder
end

local function CreateSidebarIcon(parent,kind,color)
	local h = Instance.new("Frame")
	h.Size = UDim2.fromOffset(20,20)
	h.BackgroundTransparency = 1
	h.Parent = parent

	local selectedAssets = {
		Visuals = 9653613382,      -- Visuals #5
		Fling = 18164947844,       -- Fling #1
		Player = 12928483395,      -- Player #2
	}

	if selectedAssets[kind] then
		local img = Instance.new("ImageLabel")
		img.Name = "IconImage"
		img.Size = UDim2.fromOffset(18,18)
		img.Position = UDim2.fromOffset(1,1)
		img.BackgroundTransparency = 1
		img.Image = ("rbxthumb://type=Asset&id=%s&w=150&h=150"):format(selectedAssets[kind])
		img.ImageColor3 = color
		img.ScaleType = Enum.ScaleType.Fit
		img.Parent = h

	elseif kind == "Combat" then
		local ring = Instance.new("Frame")
		ring.Size = UDim2.fromOffset(10,10)
		ring.Position = UDim2.fromOffset(5,5)
		ring.BackgroundTransparency = 1
		ring.Parent = h

		local rs = Instance.new("UIStroke")
		rs.Color = color
		rs.Thickness = 1.4
		rs.Parent = ring

		local rc = Instance.new("UICorner")
		rc.CornerRadius = UDim.new(1,0)
		rc.Parent = ring

		NewLine(h,6,1.4,3,10,0,color,2)
		NewLine(h,6,1.4,17,10,0,color,2)
		NewLine(h,6,1.4,10,3,90,color,2)
		NewLine(h,6,1.4,10,17,90,color,2)

	elseif kind == "AutoFarm" then
		local head = Instance.new("Frame")
		head.Size = UDim2.fromOffset(14,10)
		head.Position = UDim2.fromOffset(3,7)
		head.BackgroundTransparency = 1
		head.Parent = h

		local hs = Instance.new("UIStroke")
		hs.Color = color
		hs.Thickness = 1.4
		hs.Parent = head

		local hc = Instance.new("UICorner")
		hc.CornerRadius = UDim.new(0,3)
		hc.Parent = head

		NewLine(h,1.4,4,10,4.5,0,color,2)
		NewLine(h,5,1.4,10,2.5,0,color,2)

		for _,x in ipairs({7,13}) do
			local dot = Instance.new("Frame")
			dot.Size = UDim2.fromOffset(2.4,2.4)
			dot.Position = UDim2.fromOffset(x-1.2,10.8)
			dot.BackgroundColor3 = color
			dot.BorderSizePixel = 0
			dot.Parent = h

			local dc = Instance.new("UICorner")
			dc.CornerRadius = UDim.new(1,0)
			dc.Parent = dot
		end
	end

	return h
end

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1,0,0,54)
Header.BackgroundTransparency = 1
Header.Parent = MainFrame

local Logo = Instance.new("Frame")
Logo.Size = UDim2.fromOffset(36,36)
Logo.Position = UDim2.fromOffset(16,9)
Logo.BackgroundColor3 = COLORS.Card
Logo.BorderSizePixel = 0
Logo.Parent = Header
local lc = Instance.new("UICorner"); lc.CornerRadius = UDim.new(0,10); lc.Parent = Logo
local HeaderSnowflake = CreateSnowflake(Logo,22,COLORS.Text)
HeaderSnowflake.Position = UDim2.new(0.5,-11,0.5,-11)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0,250,0,24); Title.Position = UDim2.fromOffset(62,8); Title.BackgroundTransparency = 1
Title.TextXAlignment = Enum.TextXAlignment.Left; Title.Text = "Murder Mystery 2 Script"; Title.TextColor3 = COLORS.Text; Title.TextSize = 13; Title.Font = Enum.Font.GothamBold; Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(0,280,0,18); Subtitle.Position = UDim2.fromOffset(62,29); Subtitle.BackgroundTransparency = 1
Subtitle.TextXAlignment = Enum.TextXAlignment.Left; Subtitle.Text = "V8.7.1"; Subtitle.TextColor3 = COLORS.Muted; Subtitle.TextSize = 10; Subtitle.Font = Enum.Font.Gotham; Subtitle.Parent = Header

local VersionLabel = Instance.new("TextLabel")
VersionLabel.Size = UDim2.fromOffset(52,24); VersionLabel.Position = UDim2.new(1,-100,0,15); VersionLabel.BackgroundColor3 = COLORS.Card; VersionLabel.BorderSizePixel = 0
VersionLabel.Text = "V8.7.1"; VersionLabel.TextColor3 = COLORS.Muted; VersionLabel.TextSize = 9; VersionLabel.Font = Enum.Font.GothamBold; VersionLabel.Parent = Header
local VersionCorner = Instance.new("UICorner"); VersionCorner.CornerRadius = UDim.new(0,7); VersionCorner.Parent = VersionLabel

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.fromOffset(30,30); CloseButton.Position = UDim2.new(1,-42,0,12); CloseButton.BackgroundColor3 = COLORS.Card; CloseButton.BorderSizePixel = 0
CloseButton.Text = "×"; CloseButton.TextColor3 = COLORS.Text; CloseButton.TextSize = 20; CloseButton.Font = Enum.Font.GothamMedium; CloseButton.AutoButtonColor = false; CloseButton.Parent = Header
local CloseCorner = Instance.new("UICorner"); CloseCorner.CornerRadius = UDim.new(0,8); CloseCorner.Parent = CloseButton

local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(1,-24,0,1); Divider.Position = UDim2.fromOffset(12,54); Divider.BackgroundColor3 = COLORS.Stroke; Divider.BackgroundTransparency = 0.35; Divider.BorderSizePixel = 0; Divider.Parent = MainFrame

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0,126,1,-68); Sidebar.Position = UDim2.fromOffset(12,62); Sidebar.BackgroundColor3 = COLORS.Sidebar; Sidebar.BorderSizePixel = 0; Sidebar.Parent = MainFrame
local SidebarCorner = Instance.new("UICorner"); SidebarCorner.CornerRadius = UDim.new(0,12); SidebarCorner.Parent = Sidebar
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1,-150,1,-68); Content.Position = UDim2.fromOffset(138,62); Content.BackgroundTransparency = 1; Content.Parent = MainFrame

do
	local dragging, dragStart, startPos = false,nil,nil
	Header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = input.Position; startPos = MainFrame.Position end
	end)
	UIS.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position-dragStart
			MainFrame.Position = UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
		end
	end)
	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
end

local ToolbarGui = Instance.new("ScreenGui")
ToolbarGui.Name = "MM2_V8_ToolbarGui"; ToolbarGui.ResetOnSpawn = false; ToolbarGui.IgnoreGuiInset = false; ToolbarGui.DisplayOrder = 5
pcall(function() ToolbarGui.Parent = CoreGui end)
if not ToolbarGui.Parent then ToolbarGui.Parent = PlayerGui end
MM2.UI.ToolbarGui = ToolbarGui

local ToolbarOutline = Instance.new("Frame")
ToolbarOutline.Name = "FloatingOutline"
ToolbarOutline.Size = UDim2.fromOffset(244,44)
ToolbarOutline.Position = UDim2.new(0.5,-122,0.15,-96)
ToolbarOutline.BackgroundColor3 = Color3.fromRGB(45,140,255)
ToolbarOutline.BackgroundTransparency = 0
ToolbarOutline.BorderSizePixel = 0
ToolbarOutline.Active = true
ToolbarOutline.Parent = ToolbarGui

local toc = Instance.new("UICorner")
toc.CornerRadius = UDim.new(1,0)
toc.Parent = ToolbarOutline

-- A real 2px gradient shell, rather than a stroke on a transparent frame.
-- This guarantees the cyan/blue border is visible.
local ToolbarGradient = Instance.new("UIGradient")
ToolbarGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0.00,Color3.fromRGB(10,55,170)),
	ColorSequenceKeypoint.new(0.35,Color3.fromRGB(45,140,255)),
	ColorSequenceKeypoint.new(0.65,Color3.fromRGB(75,200,255)),
	ColorSequenceKeypoint.new(0.85,Color3.fromRGB(35,245,255)),
	ColorSequenceKeypoint.new(1.00,Color3.fromRGB(10,55,170)),
})
ToolbarGradient.Parent = ToolbarOutline
BlueCyanGradients[#BlueCyanGradients+1] = ToolbarGradient

local Floating = Instance.new("Frame")
Floating.Name = "FloatingOpener"; Floating.Size = UDim2.fromOffset(240,40); Floating.Position = UDim2.fromOffset(2,2)
Floating.BackgroundColor3 = Color3.fromRGB(14,18,26); Floating.BackgroundTransparency = 0.32; Floating.BorderSizePixel = 0; Floating.Active = true; Floating.Parent = ToolbarOutline
local FloatingCorner = Instance.new("UICorner"); FloatingCorner.CornerRadius = UDim.new(1,0); FloatingCorner.Parent = Floating

local DragHandle = Instance.new("TextButton")
DragHandle.Size = UDim2.fromOffset(36,40); DragHandle.BackgroundTransparency = 1; DragHandle.AutoButtonColor = false; DragHandle.Active = true
DragHandle.Text = "≡"; DragHandle.TextColor3 = COLORS.Muted; DragHandle.TextSize = 17; DragHandle.Font = Enum.Font.GothamBold; DragHandle.Parent = Floating

local FloatDivider = Instance.new("Frame")
FloatDivider.Size = UDim2.fromOffset(1,24); FloatDivider.Position = UDim2.fromOffset(38,8); FloatDivider.BackgroundColor3 = COLORS.Stroke; FloatDivider.BackgroundTransparency = 0.15; FloatDivider.BorderSizePixel = 0; FloatDivider.Parent = Floating

local ToolbarSnowflake = CreateSnowflake(Floating,20,COLORS.Text)
ToolbarSnowflake.Position = UDim2.fromOffset(47,10)

local OpenButton = Instance.new("TextButton")
OpenButton.Size = UDim2.new(1,-72,1,0); OpenButton.Position = UDim2.fromOffset(70,0); OpenButton.BackgroundTransparency = 1
OpenButton.TextXAlignment = Enum.TextXAlignment.Left; OpenButton.Text = "Murder Mystery 2 Script"; OpenButton.TextColor3 = COLORS.Text; OpenButton.TextSize = 10; OpenButton.Font = Enum.Font.GothamBold; OpenButton.AutoButtonColor = false; OpenButton.Parent = Floating

do
	local dragging, dragStart, startPos = false,nil,nil
	DragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = input.Position; startPos = ToolbarOutline.Position end
	end)
	UIS.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position-dragStart
			ToolbarOutline.Position = UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
		end
	end)
	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
end

Track(CloseButton.MouseButton1Click:Connect(function() MainFrame.Visible = false end))
Track(OpenButton.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end))

local Pages, TabButtons, TabIcons, TabLabels = {}, {}, {}, {}
MM2.UI.Pages, MM2.UI.TabButtons = Pages, TabButtons

local function NewPage(name)
	local page = Instance.new("ScrollingFrame")
	page.Name = name .. "Page"; page.Size = UDim2.fromScale(1,1); page.BackgroundTransparency = 1; page.BorderSizePixel = 0
	page.ScrollBarThickness = 4; page.ScrollBarImageColor3 = COLORS.Stroke; page.CanvasSize = UDim2.fromOffset(0,0); page.Visible = false; page.Parent = Content
	local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0,10); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = page
	local padding = Instance.new("UIPadding"); padding.PaddingTop = UDim.new(0,2); padding.PaddingLeft = UDim.new(0,2); padding.PaddingRight = UDim.new(0,8); padding.PaddingBottom = UDim.new(0,10); padding.Parent = page
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() page.CanvasSize = UDim2.fromOffset(0,layout.AbsoluteContentSize.Y+18) end)
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
		local active = tabName == name
		btn.BackgroundColor3 = active and COLORS.Card or Color3.fromRGB(0,0,0)
		btn.BackgroundTransparency = active and 0 or 1

		local label = TabLabels[tabName]
		if label then
			label.TextColor3 = active and COLORS.Text or COLORS.Muted
		end

		local icon = TabIcons[tabName]
		if icon then
			for _,obj in ipairs(icon:GetDescendants()) do
				if obj:IsA("Frame") and obj.BackgroundTransparency < 1 then
					obj.BackgroundColor3 = active and COLORS.Accent or COLORS.Muted
				elseif obj:IsA("UIStroke") then
					obj.Color = active and COLORS.Accent or COLORS.Muted
				elseif obj:IsA("ImageLabel") then
					obj.ImageColor3 = active and COLORS.Accent or COLORS.Muted
				end
			end
		end
	end
end

local function AddSidebarButton(name,label,order)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(1,-12,0,34)
	btn.Position = UDim2.fromOffset(6,8+((order-1)*38))
	btn.BackgroundTransparency = 1
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Parent = Sidebar

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0,9)
	c.Parent = btn

	-- Dedicated icon slot on the far left.
	local icon = CreateSidebarIcon(btn,name,COLORS.Muted)
	icon.AnchorPoint = Vector2.new(0,0.5)
	icon.Position = UDim2.new(0,8,0.5,0)

	-- Dedicated label slot so the icon can never sit on top of the name.
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Label"
	textLabel.Size = UDim2.new(1,-45,1,0)
	textLabel.Position = UDim2.fromOffset(41,0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = label
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextYAlignment = Enum.TextYAlignment.Center
	textLabel.TextColor3 = COLORS.Muted
	textLabel.TextSize = 10
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Parent = btn

	TabButtons[name] = btn
	TabIcons[name] = icon
	TabLabels[name] = textLabel

	Track(btn.MouseButton1Click:Connect(function()
		MM2.UI.ShowPage(name)
	end))
end

AddSidebarButton("Visuals","Visuals",1)
AddSidebarButton("Combat","Combat",2)
AddSidebarButton("Player","Player",3)
AddSidebarButton("Fling","Fling",4)
AddSidebarButton("AutoFarm","Auto Farm",5)

function MM2.UI.AddSection(parent,titleText,subtitleText)
	local wrap = Instance.new("Frame"); wrap.Size = UDim2.new(1,0,0,subtitleText and 52 or 34); wrap.BackgroundTransparency = 1; wrap.Parent = parent
	local title = Instance.new("TextLabel"); title.Size = UDim2.new(1,0,0,22); title.BackgroundTransparency = 1; title.TextXAlignment = Enum.TextXAlignment.Left; title.Text = titleText; title.TextColor3 = COLORS.Text; title.TextSize = 14; title.Font = Enum.Font.GothamBold; title.Parent = wrap
	if subtitleText then
		local sub = Instance.new("TextLabel"); sub.Size = UDim2.new(1,0,0,20); sub.Position = UDim2.fromOffset(0,24); sub.BackgroundTransparency = 1; sub.TextXAlignment = Enum.TextXAlignment.Left; sub.Text = subtitleText; sub.TextColor3 = COLORS.Muted; sub.TextSize = 10; sub.Font = Enum.Font.Gotham; sub.Parent = wrap
	end
	return wrap
end

function MM2.UI.CreateToggle(parent,titleText,description,flagName,callback)
	local card = Instance.new("Frame"); card.Size = UDim2.new(1,0,0,64); card.BackgroundColor3 = COLORS.Card; card.BorderSizePixel = 0; card.Parent = parent
	local cardCorner = Instance.new("UICorner"); cardCorner.CornerRadius = UDim.new(0,11); cardCorner.Parent = card
	local cardStroke = Instance.new("UIStroke"); cardStroke.Color = COLORS.Stroke; cardStroke.Transparency = 0.45; cardStroke.Thickness = 1; cardStroke.Parent = card
	local label = Instance.new("TextLabel"); label.Size = UDim2.new(1,-104,0,22); label.Position = UDim2.fromOffset(14,10); label.BackgroundTransparency = 1; label.TextXAlignment = Enum.TextXAlignment.Left; label.Text = titleText; label.TextColor3 = COLORS.Text; label.TextSize = 12; label.Font = Enum.Font.GothamBold; label.Parent = card
	local desc = Instance.new("TextLabel"); desc.Size = UDim2.new(1,-104,0,18); desc.Position = UDim2.fromOffset(14,34); desc.BackgroundTransparency = 1; desc.TextXAlignment = Enum.TextXAlignment.Left; desc.Text = description or ""; desc.TextColor3 = COLORS.Muted; desc.TextSize = 9; desc.Font = Enum.Font.Gotham; desc.Parent = card
	local track = Instance.new("TextButton"); track.Size = UDim2.fromOffset(48,24); track.Position = UDim2.new(1,-62,0.5,-12); track.BackgroundColor3 = COLORS.TrackOff; track.BorderSizePixel = 0; track.Text = ""; track.AutoButtonColor = false; track.Parent = card
	local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(1,0); tc.Parent = track
	local knob = Instance.new("Frame"); knob.Size = UDim2.fromOffset(18,18); knob.Position = UDim2.fromOffset(3,3); knob.BackgroundColor3 = COLORS.Knob; knob.BorderSizePixel = 0; knob.Parent = track
	local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(1,0); kc.Parent = knob
	local function Render(value,instant)
		local d = instant and 0 or 0.14
		TweenService:Create(knob,TweenInfo.new(d,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position = value and UDim2.fromOffset(27,3) or UDim2.fromOffset(3,3)}):Play()
		TweenService:Create(track,TweenInfo.new(d,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundColor3 = value and COLORS.Accent or COLORS.TrackOff}):Play()
	end
	Render(Flags[flagName],true)
	Track(track.MouseButton1Click:Connect(function()
		Flags[flagName] = not Flags[flagName]; Render(Flags[flagName],false); if callback then callback(Flags[flagName]) end
	end))
	return card,track,Render
end

function MM2.UI.CreateActionFeature(parent,titleText,description,callback)
	local card = Instance.new("Frame"); card.Size = UDim2.new(1,0,0,64); card.BackgroundColor3 = COLORS.Card; card.BorderSizePixel = 0; card.Parent = parent
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0,11); corner.Parent = card
	local stroke = Instance.new("UIStroke"); stroke.Color = COLORS.Stroke; stroke.Transparency = 0.45; stroke.Thickness = 1; stroke.Parent = card
	local title = Instance.new("TextLabel"); title.Size = UDim2.new(1,-112,0,22); title.Position = UDim2.fromOffset(14,10); title.BackgroundTransparency = 1; title.TextXAlignment = Enum.TextXAlignment.Left; title.Text = titleText; title.TextColor3 = COLORS.Text; title.TextSize = 12; title.Font = Enum.Font.GothamBold; title.Parent = card
	local desc = Instance.new("TextLabel"); desc.Size = UDim2.new(1,-112,0,18); desc.Position = UDim2.fromOffset(14,34); desc.BackgroundTransparency = 1; desc.TextXAlignment = Enum.TextXAlignment.Left; desc.Text = description or ""; desc.TextColor3 = COLORS.Muted; desc.TextSize = 9; desc.Font = Enum.Font.Gotham; desc.Parent = card
	local action = Instance.new("TextButton"); action.Size = UDim2.fromOffset(82,32); action.Position = UDim2.new(1,-96,0.5,-16); action.BackgroundColor3 = COLORS.Accent; action.BorderSizePixel = 0; action.Text = "TRIGGER"; action.TextColor3 = COLORS.Text; action.TextSize = 9; action.Font = Enum.Font.GothamBold; action.AutoButtonColor = false; action.Parent = card
	local ac = Instance.new("UICorner"); ac.CornerRadius = UDim.new(0,9); ac.Parent = action
	Track(action.MouseButton1Click:Connect(function() if callback then task.spawn(callback) end end))
	return card,action
end

function MM2.UI.CreateActionButton(parent,text,callback,style)
	local button = Instance.new("TextButton"); button.Size = UDim2.new(1,0,0,42); button.BackgroundColor3 = style == "danger" and COLORS.Danger or COLORS.Accent; button.BorderSizePixel = 0; button.Text = text; button.TextColor3 = COLORS.Text; button.TextSize = 11; button.Font = Enum.Font.GothamBold; button.AutoButtonColor = false; button.Parent = parent
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0,10); corner.Parent = button
	Track(button.MouseButton1Click:Connect(callback)); return button
end

function MM2.UI.CreateMovableCircleButton(name,icon,labelText,startPosition,callback)
	local holder = Instance.new("Frame"); holder.Name = name .. "Holder"; holder.Size = UDim2.fromOffset(104,84); holder.Position = startPosition; holder.BackgroundTransparency = 1; holder.Active = true; holder.ZIndex = 320; holder.Parent = ScreenGui
	local button = Instance.new("TextButton"); button.Name = name; button.AnchorPoint = Vector2.new(0.5,0); button.Position = UDim2.new(0.5,0,0,0); button.Size = UDim2.fromOffset(56,56); button.BackgroundColor3 = Color3.fromRGB(16,20,29); button.BackgroundTransparency = 0.08; button.BorderSizePixel = 0
	local hasIcon = icon ~= nil and tostring(icon) ~= ""
	button.Text = hasIcon and tostring(icon) or tostring(labelText or name); button.TextColor3 = COLORS.Text; button.TextSize = hasIcon and 22 or 9; button.TextWrapped = not hasIcon; button.Font = Enum.Font.GothamBold; button.AutoButtonColor = false; button.Active = true; button.ZIndex = 321; button.Parent = holder
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(1,0); corner.Parent = button
	CreateBlueCyanStroke(button,1.7,0.08)
	local label = Instance.new("TextLabel"); label.Size = UDim2.new(1,0,0,24); label.Position = UDim2.fromOffset(0,59); label.BackgroundTransparency = 1; label.Text = labelText or name; label.Visible = hasIcon; label.TextColor3 = COLORS.Text; label.TextTransparency = 0.05; label.TextSize = 9; label.TextWrapped = true; label.Font = Enum.Font.GothamBold; label.ZIndex = 321; label.Parent = holder
	local dragging,moved,dragStart,startPos = false,false,nil,nil
	Track(button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; moved = false; dragStart = input.Position; startPos = holder.Position end
	end))
	Track(UIS.InputChanged:Connect(function(input)
		if not dragging or not dragStart or not startPos then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local delta = input.Position-dragStart; if delta.Magnitude >= 4 then moved = true end
		if moved then holder.Position = UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y) end
	end))
	Track(UIS.InputEnded:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false; if not moved and callback then task.spawn(callback) end end
	end))
	return button,holder,label
end

function MM2.UI.CreateValueControl(parent,labelText,getter,setter,minValue,maxValue,step)
	local card = Instance.new("Frame"); card.Size = UDim2.new(1,0,0,64); card.BackgroundColor3 = COLORS.Card; card.BorderSizePixel = 0; card.Parent = parent
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0,11); corner.Parent = card
	local stroke = Instance.new("UIStroke"); stroke.Color = COLORS.Stroke; stroke.Transparency = 0.45; stroke.Parent = card
	local label = Instance.new("TextLabel"); label.Size = UDim2.new(1,-140,1,0); label.Position = UDim2.fromOffset(14,0); label.BackgroundTransparency = 1; label.TextXAlignment = Enum.TextXAlignment.Left; label.Text = labelText; label.TextColor3 = COLORS.Text; label.TextSize = 12; label.Font = Enum.Font.GothamBold; label.Parent = card
	local value = Instance.new("TextLabel"); value.Size = UDim2.fromOffset(48,28); value.Position = UDim2.new(1,-110,0.5,-14); value.BackgroundColor3 = COLORS.Background; value.BorderSizePixel = 0; value.Text = tostring(getter()); value.TextColor3 = COLORS.Text; value.TextSize = 11; value.Font = Enum.Font.GothamBold; value.Parent = card
	local vc = Instance.new("UICorner"); vc.CornerRadius = UDim.new(0,8); vc.Parent = value
	local minus = Instance.new("TextButton"); minus.Size = UDim2.fromOffset(26,28); minus.Position = UDim2.new(1,-138,0.5,-14); minus.BackgroundColor3 = COLORS.Background; minus.BorderSizePixel = 0; minus.Text = "−"; minus.TextColor3 = COLORS.Text; minus.TextSize = 14; minus.Font = Enum.Font.GothamBold; minus.Parent = card
	local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(0,8); mc.Parent = minus
	local plus = Instance.new("TextButton"); plus.Size = UDim2.fromOffset(26,28); plus.Position = UDim2.new(1,-30,0.5,-14); plus.BackgroundColor3 = COLORS.Background; plus.BorderSizePixel = 0; plus.Text = "+"; plus.TextColor3 = COLORS.Text; plus.TextSize = 14; plus.Font = Enum.Font.GothamBold; plus.Parent = card
	local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0,8); pc.Parent = plus
	local function update(v) v = math.clamp(v,minValue,maxValue); setter(v); value.Text = tostring(getter()) end
	Track(minus.MouseButton1Click:Connect(function() update(getter()-step) end)); Track(plus.MouseButton1Click:Connect(function() update(getter()+step) end)); return card
end

function MM2.UI.CreateSlider(parent,labelText,description,getter,setter,minValue,maxValue,step)
	local card = Instance.new("Frame"); card.Size = UDim2.new(1,0,0,78); card.BackgroundColor3 = COLORS.Card; card.BorderSizePixel = 0; card.Parent = parent
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0,11); corner.Parent = card
	local stroke = Instance.new("UIStroke"); stroke.Color = COLORS.Stroke; stroke.Transparency = 0.45; stroke.Parent = card
	local label = Instance.new("TextLabel"); label.Size = UDim2.new(1,-80,0,20); label.Position = UDim2.fromOffset(14,9); label.BackgroundTransparency = 1; label.TextXAlignment = Enum.TextXAlignment.Left; label.Text = labelText; label.TextColor3 = COLORS.Text; label.TextSize = 12; label.Font = Enum.Font.GothamBold; label.Parent = card
	local valueLabel = Instance.new("TextLabel"); valueLabel.Size = UDim2.fromOffset(54,20); valueLabel.Position = UDim2.new(1,-68,0,9); valueLabel.BackgroundTransparency = 1; valueLabel.TextXAlignment = Enum.TextXAlignment.Right; valueLabel.Text = tostring(getter()); valueLabel.TextColor3 = COLORS.Text; valueLabel.TextSize = 11; valueLabel.Font = Enum.Font.GothamBold; valueLabel.Parent = card
	local desc = Instance.new("TextLabel"); desc.Size = UDim2.new(1,-28,0,16); desc.Position = UDim2.fromOffset(14,28); desc.BackgroundTransparency = 1; desc.TextXAlignment = Enum.TextXAlignment.Left; desc.Text = description or ""; desc.TextColor3 = COLORS.Muted; desc.TextSize = 9; desc.Font = Enum.Font.Gotham; desc.Parent = card
	local bar = Instance.new("TextButton"); bar.Size = UDim2.new(1,-28,0,8); bar.Position = UDim2.fromOffset(14,57); bar.BackgroundColor3 = COLORS.TrackOff; bar.BorderSizePixel = 0; bar.Text = ""; bar.AutoButtonColor = false; bar.Active = true; bar.Parent = card
	local barCorner = Instance.new("UICorner"); barCorner.CornerRadius = UDim.new(1,0); barCorner.Parent = bar
	local fill = Instance.new("Frame"); fill.Size = UDim2.fromScale(0,1); fill.BackgroundColor3 = COLORS.Accent; fill.BorderSizePixel = 0; fill.Parent = bar
	local fillCorner = Instance.new("UICorner"); fillCorner.CornerRadius = UDim.new(1,0); fillCorner.Parent = fill
	local knob = Instance.new("Frame"); knob.AnchorPoint = Vector2.new(0.5,0.5); knob.Size = UDim2.fromOffset(16,16); knob.Position = UDim2.new(0,0,0.5,0); knob.BackgroundColor3 = COLORS.Knob; knob.BorderSizePixel = 0; knob.ZIndex = 3; knob.Parent = bar
	local knobCorner = Instance.new("UICorner"); knobCorner.CornerRadius = UDim.new(1,0); knobCorner.Parent = knob
	local dragging = false
	local function snap(v) return math.clamp(math.floor(((v-minValue)/step)+0.5)*step+minValue,minValue,maxValue) end
	local function render(v) local alpha = math.clamp((v-minValue)/(maxValue-minValue),0,1); fill.Size = UDim2.fromScale(alpha,1); knob.Position = UDim2.new(alpha,0,0.5,0); valueLabel.Text = tostring(v) end
	local function setFromX(x) local width = math.max(bar.AbsoluteSize.X,1); local alpha = math.clamp((x-bar.AbsolutePosition.X)/width,0,1); local v = snap(minValue+(maxValue-minValue)*alpha); setter(v); render(getter()) end
	render(getter())
	Track(bar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; setFromX(input.Position.X) end end))
	Track(UIS.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then setFromX(input.Position.X) end end))
	Track(UIS.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end))
	return card
end

return MM2
