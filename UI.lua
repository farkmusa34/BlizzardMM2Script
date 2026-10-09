--============================================================
-- Blizzard MM2 v1.85.4 - UI.lua
-- MONO / BLACK-GRAY WINDUI BRIDGE
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
	Accent = Color3.fromRGB(245,245,245),
	Accent2 = Color3.fromRGB(190,190,195),
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

--============================================================
-- BLIZZARD MONO THEME
-- Black / charcoal surfaces with white controls and icons.
-- Existing WindUI toggle geometry is preserved, so toggles stay pill-shaped.
--============================================================

pcall(function()
	if WindUI.AddTheme then
		WindUI:AddTheme({
			Name = "Blizzard Mono",
			Accent = "#FFFFFF",
			-- Dark smoked-glass palette: near-black rather than washed gray.
			-- Window stays Transparent=true below, so the game remains visible through it.
			Dialog = "#020203",
			Outline = "#0B0B0E",
			Text = "#F5F5F5",
			Placeholder = "#929298",
			Background = "#000001",
			Button = "#07070A",
			-- Mono toggle treatment: dark/gray when OFF, bright white when ON.
			Toggle = "#FFFFFF",
			ToggleBar = "#B8B8BC",
			Icon = "#FFFFFF",
		})
	end
end)

local Window =
	WindUI:CreateWindow({
		Title = "Blizzard MM2",
		Author = "v1.85.4",
		Folder = "BlizzardMM2",
		Icon = "gamepad-2",

		-- Black / gray / white factory appearance.
		Theme = "Blizzard Mono",

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
-- White/mono accent is used before Misc.lua has loaded.
--============================================================

local DEFAULT_BLIZZARD_BLUE =
	Color3.fromRGB(
		246,
		190,
		52
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
				Title = "SUMMER EVENT",
				Icon = "sun",
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
		"[Blizzard UI] SUMMER EVENT tag failed:",
		result
	)

	return nil
end

function UI.SetLatestUpdateTheme(color)

	-- SUMMER EVENT has a fixed sun-gold identity; theme changes must not turn it white.
	color = DEFAULT_BLIZZARD_BLUE

	UI.CurrentThemeAccent = color


	-- Keep every floating Blizzard card synced to the selected theme.
	if UI.FloatingCardRegistry then
		for _,entry in pairs(UI.FloatingCardRegistry) do
			if entry and entry.Stroke then
				entry.Stroke.Color = entry.FixedStrokeColor or color
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
	DEFAULT_BLIZZARD_BLUE
)

-- WindUI/theme modules may apply their accent shortly after startup.
-- Re-assert the event orange after those initialization passes.
task.defer(function() UI.SetLatestUpdateTheme(DEFAULT_BLIZZARD_BLUE) end)
task.delay(0.15,function() UI.SetLatestUpdateTheme(DEFAULT_BLIZZARD_BLUE) end)
task.delay(0.75,function() UI.SetLatestUpdateTheme(DEFAULT_BLIZZARD_BLUE) end)

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

-- Use WindUI's native sidebar Section as the expandable parent.
-- This gives Skin Changer its own arrow without creating/selecting an empty page.
UI.WindTabs.SkinChanger =
	Window:Section({
		Title = "Skin Changer",
		Icon = "palette",
		Opened = true
	})

-- Gun / Knife are real child tabs owned by the Skin Changer section.
UI.WindTabs.SkinChangerGun =
	UI.WindTabs.SkinChanger:Tab({
		Title = "Gun",
		Icon = "crosshair"
	})

UI.WindTabs.SkinChangerKnife =
	UI.WindTabs.SkinChanger:Tab({
		Title = "Knife",
		Icon = "sword"
	})

UI.WindTabs.Misc =
	Window:Tab({
		Title = "Misc",
		Icon = "settings"
	})



--============================================================
-- SKIN CHANGER SIDEBAR GROUP
-- Native WindUI Window:Section handles expand/collapse + arrow.
-- No custom overlay/hitbox is needed, so the parent never opens an empty tab.
--============================================================

--============================================================
-- SIDEBAR PLAYER PROFILE REMOVED
-- Extra sidebar room is reserved for the expandable Skin Changer group.
--============================================================

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
UI.SkinChangerGunPage = NewLegacyPage("SkinChangerGun")
UI.SkinChangerKnifePage = NewLegacyPage("SkinChangerKnife")
UI.MiscPage = NewLegacyPage("Misc")

UI.Pages = {
	Visuals = UI.VisualsPage,
	Combat = UI.CombatPage,
	Player = UI.PlayerPage,
	Teleport = UI.TeleportPage,
	Fling = UI.FlingPage,
	AutoFarm = UI.AutoFarmPage,
	SkinChanger = UI.SkinChangerPage,
	SkinChangerGun = UI.SkinChangerGunPage,
	SkinChangerKnife = UI.SkinChangerKnifePage,
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
	[UI.SkinChangerGunPage] = UI.WindTabs.SkinChangerGun,
	[UI.SkinChangerKnifePage] = UI.WindTabs.SkinChangerKnife,
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

local NextSectionSpacing = {}
local SectionCountByPage = setmetatable({}, {__mode = "k"})

function UI.SetNextSectionSpacing(page,above,below)
	-- Compatibility only. Visuals already demonstrates the native WindUI
	-- section gap we want, so no custom padding is added here.
	NextSectionSpacing[page] = true
end

local function LowerFirstSectionHeadingY(section, page)
	-- The first heading has no section above it, so give it a deliberate
	-- downward visual offset without changing section/card geometry.
	if not section or not section.ElementFrame then
		return
	end

	local basePositions = setmetatable({}, {__mode = "k"})
	local FIRST_HEADING_Y_NUDGE = 0

	local function Apply()
		local outline = section.ElementFrame:FindFirstChild("Outline")
		local top = outline and outline:FindFirstChild("Top")
		if not top then return end

		for _,obj in ipairs(top:GetDescendants()) do
			if obj:IsA("TextLabel") or obj:IsA("TextButton") then
				if not basePositions[obj] then
					basePositions[obj] = obj.Position
				end

				local native = basePositions[obj]
				obj.TextYAlignment = Enum.TextYAlignment.Center
				obj.Position = UDim2.new(
					native.X.Scale, native.X.Offset,
					native.Y.Scale, native.Y.Offset + FIRST_HEADING_Y_NUDGE
				)
			end
		end
	end

	Apply()
	task.defer(Apply)
	task.delay(0.05, Apply)
	task.delay(0.20, Apply)
end

-- Compact title-only section spacing.
-- Removes only part of WindUI's title-only reserved header space.
-- The title remains unclipped and card-to-card spacing stays untouched.
local SECTION_TO_FIRST_CONTROL_REDUCTION = 0

local function TightenSectionToFirstControlGap(section)
	if not section or not section.ElementFrame then
		return
	end

	local nativeSizes = setmetatable({}, {__mode = "k"})

	local function Apply()
		local main = section.ElementFrame
		local outline = main:FindFirstChild("Outline")
		local top = outline and outline:FindFirstChild("Top")
		if not top or not top:IsA("GuiObject") then return end

		-- WindUI's title-only section still reserves some of the old Desc row.
		-- Reduce only part of that header reserve, and disable clipping so the
		-- title itself can never be chopped by the tighter header.
		pcall(function() main.ClipsDescendants = false end)
		pcall(function() outline.ClipsDescendants = false end)
		pcall(function() top.ClipsDescendants = false end)

		if not nativeSizes[top] then
			nativeSizes[top] = top.Size
		end

		local native = nativeSizes[top]
		top.Size = UDim2.new(
			native.X.Scale, native.X.Offset,
			native.Y.Scale, math.max(0, native.Y.Offset - SECTION_TO_FIRST_CONTROL_REDUCTION)
		)
	end

	Apply()
	task.defer(Apply)
	task.delay(0.05, Apply)
	task.delay(0.20, Apply)
end

-- Public hook for tabs (such as Visuals.lua) that create WindUI sections directly.
-- This reuses the exact title-only compaction that gives Misc its good spacing.
UI.CompactTitleOnlySection = TightenSectionToFirstControlGap

local function CenterLaterSectionHeadingY(section)
	-- IMPORTANT:
	--   * Do not resize Top / Outline / ElementFrame.
	--   * Do not move cards.
	--   * Do not change X.
	--   * Only later headings are visually nudged upward on Y.
	-- This preserves WindUI's native (Visuals-like) section gap.
	if not section or not section.ElementFrame then
		return
	end

	local basePositions = setmetatable({}, {__mode = "k"})
	local HEADING_Y_NUDGE = 0

	local function Apply()
		local outline = section.ElementFrame:FindFirstChild("Outline")
		local top = outline and outline:FindFirstChild("Top")
		if not top then
			return
		end

		for _,obj in ipairs(top:GetDescendants()) do
			if obj:IsA("TextLabel") or obj:IsA("TextButton") then
				-- Save WindUI's native position once so delayed passes never stack.
				if not basePositions[obj] then
					basePositions[obj] = obj.Position
				end

				local native = basePositions[obj]
				obj.TextYAlignment = Enum.TextYAlignment.Center
				obj.Position = UDim2.new(
					native.X.Scale,
					native.X.Offset,
					native.Y.Scale,
					native.Y.Offset + HEADING_Y_NUDGE
				)
			end
		end
	end

	Apply()
	task.defer(Apply)
	task.delay(0.05, Apply)
	task.delay(0.20, Apply)
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
	local isVisuals = (page == UI.VisualsPage)

	-- Track heading order per tab. The first heading already looks correct,
	-- so only headings #2+ receive the visual Y adjustment.
	SectionCountByPage[page] = (SectionCountByPage[page] or 0) + 1
	local isFirstHeading = SectionCountByPage[page] == 1

	local ok,result =
		pcall(function()
			local config = {
				Title = tostring(titleText or ""),
				Opened = true,
			}

			-- Compact title-only sections on the main tabs.
			-- Visuals keeps its existing subtitle behavior; every other tab omits Desc.
			if isVisuals then
				local desc = tostring(subtitleText or "")
				if desc ~= "" then
					config.Desc = desc
				end
			end

			-- Keep WindUI's native section construction; geometry is compacted
			-- immediately after creation instead of moving the cards themselves.
			return tab:Section(config)
		end)

	if ok and result then
		section = result
	else
		local ok2,result2 =
			pcall(function()
				return tab:Section({
					Title = tostring(titleText or ""),
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
		LockSectionOpenAndHideArrow(section)

		-- Normalize section spacing on every tab. The section header reserve is
		-- compacted instead of moving individual cards, so section transitions
		-- stay consistent even when WindUI rebuilds/reflows the page.
		TightenSectionToFirstControlGap(section)

		-- Keep every heading on WindUI's native vertical center. No tab-specific
		-- offsets: those were the source of Combat/other tabs drifting apart.
		if isFirstHeading then
			LowerFirstSectionHeadingY(section, page)
		else
			CenterLaterSectionHeadingY(section)
		end
	end

	NextSectionSpacing[page] = nil
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
		local resolvedDefault = defaultValue
		if type(defaultValue) == "function" then
			local okDefault,valueDefault = pcall(defaultValue)
			if okDefault then
				resolvedDefault = valueDefault
			end
		end
		config.Value = resolvedDefault
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
-- IMAGE SKIN SELECTOR
--============================================================

function UI.CreateImageSkinSelector(
	page,
	titleText,
	description,
	icon,
	items,
	selectedValue,
	callback
)
	local tab = UI.PageMap[page]
	if not tab then
		warn("[Blizzard UI] Image selector has no WindUI tab:", titleText)
		return nil
	end

	items = items or {}
	local selected = tostring(selectedValue or "Default")
	local root

	-- WindUI does not expose a documented custom-content mount in every build.
	-- Resolve the actual content ScrollingFrame/Frame from the tab object at runtime.
	local function ResolveContent()
		local candidates = {}
		local seen = {}

		local function scan(value, depth)
			if depth > 4 or seen[value] then return end
			if type(value) == "table" then
				seen[value] = true
				for _,v in pairs(value) do
					scan(v, depth + 1)
				end
			elseif typeof(value) == "Instance" and value:IsA("GuiObject") then
				table.insert(candidates, value)
			end
		end

		scan(tab, 0)

		local best, bestScore
		for _,obj in ipairs(candidates) do
			local score = 0
			local n = string.lower(obj.Name or "")
			if obj:IsA("ScrollingFrame") then score += 100 end
			if string.find(n, "content") or string.find(n, "container") then score += 50 end
			if obj.AbsoluteSize.X >= 300 then score += 30 end
			if obj.AbsoluteSize.Y >= 250 then score += 20 end
			if not bestScore or score > bestScore then
				best, bestScore = obj, score
			end
		end
		return best
	end

	local function Build()
		if root and root.Parent then
			root:Destroy()
		end

		pcall(function() tab:Select() end)
		task.wait()

		local parent = ResolveContent()
		if not parent then
			warn("[Blizzard UI] Could not resolve embedded gallery parent:", titleText)
			return
		end

		root = Instance.new("Frame")
		root.Name = "BlizzardEmbeddedSkinGallery_" .. tostring(titleText)
		root.BackgroundTransparency = 1
		local rowCount = math.max(1, math.ceil(#items / 4))
		local CARD_HEIGHT = 64
		local CARD_GAP = 5
		local GRID_TOP_INSET = 3
		local GRID_BOTTOM_INSET = 3
		local gridHeight = GRID_TOP_INSET + rowCount * CARD_HEIGHT + math.max(0,rowCount - 1) * CARD_GAP + GRID_BOTTOM_INSET
		root.Size = UDim2.new(1, -8, 0, 78 + gridHeight)
		root.AutomaticSize = Enum.AutomaticSize.None
		root.LayoutOrder = -10000
		root.Parent = parent

		local search = Instance.new("TextBox")
		search.Name = "Search"
		search.Position = UDim2.fromOffset(4, 2)
		search.Size = UDim2.new(1, -8, 0, 42)
		search.BackgroundColor3 = Color3.fromRGB(27,27,30)
		search.BorderSizePixel = 0
		search.ClearTextOnFocus = false
		search.Font = Enum.Font.Gotham
		search.PlaceholderText = "Search " .. tostring(#items) .. " " .. string.lower(titleText) .. " skins..."
		search.PlaceholderColor3 = Color3.fromRGB(125,125,132)
		search.Text = ""
		search.TextColor3 = Color3.fromRGB(235,235,240)
		search.TextSize = 14
		search.TextXAlignment = Enum.TextXAlignment.Left
		search.ZIndex = 20
		search.Parent = root

		local searchPadding = Instance.new("UIPadding")
		searchPadding.PaddingLeft = UDim.new(0,14)
		searchPadding.PaddingRight = UDim.new(0,14)
		searchPadding.Parent = search

		local searchCorner = Instance.new("UICorner")
		searchCorner.CornerRadius = UDim.new(0,8)
		searchCorner.Parent = search

		local helper = Instance.new("TextLabel")
		helper.Name = "Helper"
		helper.BackgroundTransparency = 1
		helper.Position = UDim2.fromOffset(4, 49)
		helper.Size = UDim2.new(1,-8,0,21)
		helper.Font = Enum.Font.Gotham
		local committedStatus = (selected and selected ~= "Default" and selected ~= "")
			and (tostring(selected) .. " · Skin Changed.")
			or "Tap a skin to equip it."
		helper.Text = committedStatus
		helper.TextColor3 = Color3.fromRGB(175,175,182)
		helper.TextSize = 14
		helper.TextXAlignment = Enum.TextXAlignment.Left
		helper.ZIndex = 20
		helper.Parent = root

		local scroll = Instance.new("ScrollingFrame")
		scroll.Name = "SkinGrid"
		scroll.Position = UDim2.fromOffset(5, 74)
		scroll.Size = UDim2.new(1,-12,0,gridHeight)
		scroll.BackgroundTransparency = 1
		scroll.BorderSizePixel = 0
		scroll.ScrollBarThickness = 0
		scroll.ScrollingEnabled = false
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.None
		scroll.CanvasSize = UDim2.fromOffset(0,gridHeight)
		scroll.ZIndex = 20
		scroll.Parent = root

		local grid = Instance.new("UIGridLayout")
		-- Four equal columns at every supported window width.
		-- A small negative offset leaves room for the three gaps and prevents right-edge clipping.
		grid.CellPadding = UDim2.fromOffset(CARD_GAP,CARD_GAP)
		grid.CellSize = UDim2.new(0.25,-8,0,CARD_HEIGHT)
		grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
		grid.VerticalAlignment = Enum.VerticalAlignment.Top
		grid.SortOrder = Enum.SortOrder.LayoutOrder
		grid.Parent = scroll

		local gridPadding = Instance.new("UIPadding")
		gridPadding.PaddingTop = UDim.new(0,GRID_TOP_INSET)
		gridPadding.PaddingLeft = UDim.new(0,1)
		gridPadding.PaddingRight = UDim.new(0,3)
		gridPadding.PaddingBottom = UDim.new(0,GRID_BOTTOM_INSET)
		gridPadding.Parent = scroll

		local tiles = {}

		local function refreshSelection()
			for name,data in pairs(tiles) do
				local active = name == selected
				data.Stroke.Thickness = 1
				data.Stroke.Transparency = 0.18
				data.Stroke.Color = data.OutlineColor or Color3.fromRGB(190,35,220)
				data.Tile.BackgroundColor3 = active
					and Color3.fromRGB(65,65,70)
					or Color3.fromRGB(24,24,27)
			end
		end

		local function rarityColor(rarity)
			rarity = string.lower(tostring(rarity or ""))
			if rarity == "ancient" then
				return Color3.fromRGB(132,55,220)
			elseif rarity == "chroma" then
				return Color3.fromRGB(210,70,255)
			elseif rarity == "godly" then
				return Color3.fromRGB(255,80,220)
			elseif rarity == "legendary" then
				return Color3.fromRGB(255,90,90)
			elseif rarity == "rare" then
				return Color3.fromRGB(80,145,255)
			elseif rarity == "uncommon" then
				return Color3.fromRGB(70,220,115)
			end
			return Color3.fromRGB(150,150,160)
		end

		for index,item in ipairs(items) do
			local name = tostring(item.Name or "Skin")
			local image = tostring(item.Image or "")
			local rarity = tostring(item.Rarity or "")

			local tile = Instance.new("ImageButton")
			tile.Name = "Skin_" .. name
			tile.LayoutOrder = index
			tile.BackgroundColor3 = Color3.fromRGB(24,24,27)
			tile.BorderSizePixel = 0
			tile.Image = ""
			tile.AutoButtonColor = false
			tile.ZIndex = 21
			tile.Parent = scroll

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0,8)
			corner.Parent = tile

			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 1
			stroke.Transparency = 0.18
			local specialPurple = (name == "Harvester" or name == "Gingerscope" or name == "Icepiercer")
			local outlineColor = specialPurple and Color3.fromRGB(132,55,220) or rarityColor(rarity)
			stroke.Color = outlineColor
			stroke.Parent = tile

			local preview = Instance.new("ImageLabel")
			preview.BackgroundTransparency = 1
			-- Keep the existing 4x4 cards unchanged; enlarge only the weapon art.
			-- Center anchoring makes the 1.25x growth expand evenly in every direction.
			preview.AnchorPoint = Vector2.new(0.5,0.5)
			preview.Position = UDim2.new(0.5,0,0,31)
			preview.Size = UDim2.new(1,-8,0,41)
			preview.Image = image
			preview.ScaleType = Enum.ScaleType.Fit
			preview.ZIndex = 22
			preview.Parent = tile

			local previewScale = Instance.new("UIScale")
			previewScale.Name = "WeaponPreviewScale"
			previewScale.Scale = 1.5984
			previewScale.Parent = preview

			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Position = UDim2.new(0,3,1,-22)
			label.Size = UDim2.new(1,-6,0,20)
			label.Font = Enum.Font.GothamMedium
			label.Text = name
			label.TextWrapped = true
			label.TextColor3 = Color3.fromRGB(240,240,244)
			label.TextStrokeColor3 = Color3.fromRGB(0,0,0)
			label.TextStrokeTransparency = 0.3
			label.TextSize = 10
			label.ZIndex = 23
			label.Parent = tile

			tiles[name] = {Tile=tile, Stroke=stroke, Item=item, OutlineColor=outlineColor}

			local function hoverOn()
				helper.Text = rarity ~= "" and (name .. "  ·  " .. rarity) or name
				if name ~= selected then
					tile.BackgroundColor3 = Color3.fromRGB(48,48,53)
				end
			end

			local function hoverOff()
				helper.Text = committedStatus
				refreshSelection()
			end

			Track(tile.MouseEnter:Connect(hoverOn))
			Track(tile.MouseLeave:Connect(hoverOff))
			Track(tile.SelectionGained:Connect(hoverOn))
			Track(tile.SelectionLost:Connect(hoverOff))

			Track(tile.MouseButton1Click:Connect(function()
				selected = name
				refreshSelection()
				local ok = true
				if callback then
					local callOk,result = pcall(callback,name)
					ok = callOk and result ~= false
					if not callOk then
						warn("[Blizzard UI Image Selector]", titleText, result)
					end
				end
				if ok then
					committedStatus = name .. " · Skin Changed."
					helper.Text = committedStatus
				end
			end))
		end

		local function applyFilter()
			local q = string.lower(search.Text or "")
			for name,data in pairs(tiles) do
				data.Tile.Visible = q == "" or string.find(string.lower(name), q, 1, true) ~= nil
			end
		end

		Track(search:GetPropertyChangedSignal("Text"):Connect(applyFilter))
		refreshSelection()
	end

	task.defer(Build)

	return {
		Rebuild = Build,
		SetValue = function(_,value)
			selected = tostring(value or "Default")
			if root and root.Parent then
				for _,obj in ipairs(root:GetDescendants()) do
					if obj:IsA("UIStroke") then
						-- selection is refreshed by the next interaction/rebuild
					end
				end
			end
		end,
	}
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

		-- Optional semantic action styling. WindUI does not expose a
		-- per-button fill option consistently, so style its actual element.
		local ACTION_COLORS = {
			danger = Color3.fromRGB(150,45,52),
			blue = Color3.fromRGB(45,88,155),
			purple = Color3.fromRGB(105,65,155),
			orange = Color3.fromRGB(170,92,38),
		}

		local fill = ACTION_COLORS[style]
		if fill and control then
			local function applyActionFill()
				local root = control.ElementFrame or control.Frame or control.Root
				if typeof(root) ~= "Instance" then return end
				-- Prefer the root card itself; fall back to the largest visible frame.
				local target = root:IsA("Frame") and root or nil
				if not target then
					local bestArea = -1
					for _,obj in ipairs(root:GetDescendants()) do
						if obj:IsA("Frame") and obj.BackgroundTransparency < 1 then
							local area = obj.AbsoluteSize.X * obj.AbsoluteSize.Y
							if area > bestArea then target,bestArea = obj,area end
						end
					end
				end
				if target then
					target.BackgroundColor3 = fill
					target.BackgroundTransparency = math.min(target.BackgroundTransparency,0.08)
				end
			end
			task.defer(applyActionFill)
			task.delay(0.15,applyActionFill)
		end

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

--============================================================
-- TOGGLE APPEARANCE
-- Keep WindUI's original/native toggle rendering.
-- No custom square skin is applied here.
--============================================================
local function ApplyReferenceToggleSkin(control,isOn)
	-- Intentionally left as a no-op for compatibility with older call sites.
	-- WindUI owns the toggle shape, colours, knob, and state animation.
end

--============================================================
-- TOGGLE NOTIFICATION ICONS
-- One feature icon is used for BOTH Enabled and Disabled notices.
-- Error / blocked-action notifications still choose their own icons
-- (for example circle-x) at the call site.
--============================================================
UI.ToggleNotificationIcons = UI.ToggleNotificationIcons or {
	-- Visuals
	-- Keep aliases here so the notifier works with either current or older flag names.
	CoinESP = "coins",
	RoundTimer = "timer",
	MurdererTracer = "scan",
	SheriffTracer = "scan",
	HeroTracer = "scan",
	InnocentTracer = "scan",
	MatchESP = "scan-eye",
	PlayerESP = "eye",
	GunESP = "scan-eye",
	RoleESP = "scan-eye",
	Tracers = "scan",
	TracerESP = "scan",
	Nametags = "badge",
	NameTags = "badge",
	DistanceESP = "ruler",
	ShowDistance = "ruler",
	ESPDistance = "ruler",

	-- Combat
	TriggerBot = "zap",
	AimLock = "target",
	ShowLegitShootButton = "crosshair",
	ShowShootButton = "crosshair",
	AutoGrab = "hand",
	LegitThrow = "sword",
	RageThrow = "sword",
	ShowThrowAimbotButton = "swords",
	WallThrow = "sword",
	ShowKillAllButton = "swords",
	KnifeAura = "swords",
	CustomCrosshair = "crosshair",

	-- Player
	Fly = "plane",
	Noclip = "ghost",
	InfiniteJump = "arrow-up",
	WallClimb = "move-up",
	WallJump = "move-up",
	BombJumpButton = "bomb",

	-- Fling
	ShowFlingMurdererButton = "wind",
	ShowFlingSheriffButton = "shield",
	AntiFling = "shield-check",
	FlingNotify = "bell",

	-- Auto Farm
	AutoFarm = "bot",
	FarmUnderground = "arrow-down",
	KillAllAfterBagFull = "swords",
	ShootMurdererAfterBagFull = "crosshair",
	FlingMurdererAfterBagFull = "wind",
	ResetCharacterAfterBagFull = "rotate-ccw",

	-- Misc
	QuickButtonsLocked = "lock",
	AntiAFK = "clock",
	AutoSaveConfig = "save",
}

-- Shared feature icons used outside toggle notifications.
-- Keep normal feature identities here; blocked/error states still use circle-x.
UI.FeatureIcons = UI.FeatureIcons or {}
UI.FeatureIcons.Combat = UI.FeatureIcons.Combat or {
	LegitShoot = "crosshair",
	RageShoot = "zap",
	ThrowAimbot = "swords",
	KillAll = "skull",
}

function UI.SetToggleNotificationIcon(flagName,icon)
	if typeof(flagName) ~= "string" or flagName == "" then
		return false
	end

	if icon == nil then
		UI.ToggleNotificationIcons[flagName] = nil
		return true
	end

	if typeof(icon) ~= "string" or icon == "" then
		return false
	end

	UI.ToggleNotificationIcons[flagName] = icon
	return true
end

local function GetToggleNotificationIcon(flagName,overrideIcon)
	if typeof(overrideIcon) == "string" and overrideIcon ~= "" then
		return overrideIcon
	end

	local mapped = UI.ToggleNotificationIcons[flagName]
	if typeof(mapped) == "string" and mapped ~= "" then
		return mapped
	end

	-- Neutral fallback for any future toggle that has not been mapped yet.
	return "settings"
end

function UI.CreateToggle(
	page,
	titleText,
	description,
	flagName,
	callback,
	notificationIcon
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

						task.defer(function() ApplyReferenceToggleSkin(control,value) end)

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
									GetToggleNotificationIcon(
										flagName,
										notificationIcon
									),

								Duration = 2.5,
							})
						end)
					end,
			})
		end)

	if ok then

		control = result

		-- Visual-only skin pass. Failure cannot affect control creation.
		task.defer(function() ApplyReferenceToggleSkin(control,Flags[flagName] == true) end)
		task.delay(0.15,function() ApplyReferenceToggleSkin(control,Flags[flagName] == true) end)

		local ACTION_COLORS = {
			danger = Color3.fromRGB(150,45,52),
			blue = Color3.fromRGB(45,88,155),
			purple = Color3.fromRGB(105,65,155),
			orange = Color3.fromRGB(170,92,38),
		}
		local fill = ACTION_COLORS[style]
		if fill and control then
			local function applyActionFill()
				local root = control.ElementFrame or control.Frame or control.Root
				if typeof(root) ~= "Instance" then return end
				local target = root:IsA("Frame") and root or nil
				if not target then
					local bestArea = -1
					for _,obj in ipairs(root:GetDescendants()) do
						if obj:IsA("Frame") and obj.BackgroundTransparency < 1 then
							local area = obj.AbsoluteSize.X * obj.AbsoluteSize.Y
							if area > bestArea then target,bestArea = obj,area end
						end
					end
				end
				if target then
					target.BackgroundColor3 = fill
					target.BackgroundTransparency = math.min(target.BackgroundTransparency,0.08)
				end
			end
			task.defer(applyActionFill)
			task.delay(0.15,applyActionFill)
		end

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

		-- Reapply only the visual skin after WindUI updates its state.
		task.defer(function() ApplyReferenceToggleSkin(control,value) end)

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
	icon,
	style
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

	-- WindUI Button supports Color directly.  Pass the fill when the
	-- button is CREATED instead of trying to recolor its internal GUI later.
	local ACTION_COLORS = {
		danger = Color3.fromRGB(150,45,52),
		blue = Color3.fromRGB(45,88,155),
		purple = Color3.fromRGB(105,65,155),
		orange = Color3.fromRGB(170,92,38),
	}

	local fill = ACTION_COLORS[style]
	local control

	local ok,result =
		pcall(function()
			local config = {
				Title = tostring(titleText or ""),
				Desc = tostring(description or ""),
				Icon = icon,
				Callback = function()
					if callback then
						local cbOk,cbErr = pcall(callback)
						if not cbOk then
							warn(
								"[Blizzard UI Action]",
								titleText,
								cbErr
							)
						end
					end
				end,
			}

			if fill then
				config.Color = fill
			end

			return parent:Button(config)
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

-- Saved quick-button positions can be loaded before Combat/Player/Fling create
-- their floating buttons. Keep them pending and apply each one on creation.
UI.PendingQuickButtonPositions = UI.PendingQuickButtonPositions or {}

local function SerializeQuickButtonPosition(position)
	if typeof(position) ~= "UDim2" then return nil end
	return {
		XScale = position.X.Scale,
		XOffset = position.X.Offset,
		YScale = position.Y.Scale,
		YOffset = position.Y.Offset,
	}
end

local function DeserializeQuickButtonPosition(data)
	if type(data) ~= "table" then return nil end
	local xs = tonumber(data.XScale or data.xScale or data[1])
	local xo = tonumber(data.XOffset or data.xOffset or data[2])
	local ys = tonumber(data.YScale or data.yScale or data[3])
	local yo = tonumber(data.YOffset or data.yOffset or data[4])
	if not xs or not xo or not ys or not yo then return nil end
	return UDim2.new(xs,xo,ys,yo)
end

function UI.GetQuickButtonPositions()
	local positions = {}
	for name,data in pairs(UI.PendingQuickButtonPositions) do
		if type(data) == "table" then
			positions[name] = data
		end
	end
	for name,entry in pairs(UI.FloatingCardRegistry) do
		if entry and entry.Holder then
			local encoded = SerializeQuickButtonPosition(entry.Holder.Position)
			if encoded then positions[name] = encoded end
		end
	end
	return positions
end

function UI.ApplyQuickButtonPositions(positions)
	if type(positions) ~= "table" then return false end
	UI.PendingQuickButtonPositions = {}
	for name,data in pairs(positions) do
		local position = DeserializeQuickButtonPosition(data)
		if position then
			UI.PendingQuickButtonPositions[tostring(name)] = SerializeQuickButtonPosition(position)
			local entry = UI.FloatingCardRegistry[tostring(name)]
			if entry and entry.Holder then entry.Holder.Position = position end
		end
	end
	return true
end

function UI.ResetQuickButtonPositions()
	UI.PendingQuickButtonPositions = {}
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
	callback,
	style
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

	local QUICK_BUTTON_OUTLINE_COLORS = {
		red = Color3.fromRGB(220,42,55),
		danger = Color3.fromRGB(220,42,55),
		blue = Color3.fromRGB(55,145,255),
		orange = Color3.fromRGB(240,150,45),
	}
	local fixedStrokeColor = QUICK_BUTTON_OUTLINE_COLORS[string.lower(tostring(style or ""))]
	-- Fixed semantic colors are independent from the selected menu appearance/theme.
	if not fixedStrokeColor then
		local identity = string.lower(cleanName .. " " .. tostring(labelText or ""))
		if string.find(identity,"bomb") then
			fixedStrokeColor = QUICK_BUTTON_OUTLINE_COLORS.orange
		elseif string.find(identity,"kill all")
			or string.find(identity,"throw knife")
			or string.find(identity,"throw aimbot")
			or string.find(identity,"throw")
			or (string.find(identity,"fling") and string.find(identity,"murder"))
		then
			fixedStrokeColor = QUICK_BUTTON_OUTLINE_COLORS.red
		elseif string.find(identity,"shoot") or string.find(identity,"rage") or (string.find(identity,"fling") and (string.find(identity,"sheriff") or string.find(identity,"hero"))) then
			fixedStrokeColor = QUICK_BUTTON_OUTLINE_COLORS.blue
		end
	end

	local stroke = Instance.new("UIStroke")
	stroke.Name = "ThemeStroke"
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = fixedStrokeColor or UI.CurrentThemeAccent or DEFAULT_BLIZZARD_BLUE
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
		FixedStrokeColor = fixedStrokeColor,
	}

	UI.FloatingCardRegistry[cleanName] = entry

	local pendingPosition = DeserializeQuickButtonPosition(UI.PendingQuickButtonPositions[cleanName])
	if pendingPosition then
		holder.Position = pendingPosition
	end

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
	"[Blizzard MM2 UI] Blizzard Mono WindUI bridge v1.85.4 loaded"
)

--============================================================
-- WINDUI POST-LOAD LAYOUT REFRESH
-- Mimics a tiny resize, then restores the exact original size.
--============================================================
task.defer(function()
	task.wait(0.35)
	pcall(function()
		local frame =
			Window
			and (
				(Window.UIElements and (
					Window.UIElements.Main
					or Window.UIElements.Window
					or Window.UIElements.Container
				))
				or Window.Window
				or Window.Frame
				or Window.Main
			)

		if typeof(frame) ~= "Instance" or not frame:IsA("GuiObject") then
			return
		end

		local originalSize = frame.Size
		frame.Size = UDim2.new(
			originalSize.X.Scale, originalSize.X.Offset + 1,
			originalSize.Y.Scale, originalSize.Y.Offset + 1
		)
		task.wait()
		frame.Size = originalSize
	end)
end)

return MM2
