-- Blizzard MM2 Main tab - STANDALONE VISUAL PREVIEW
-- Does not load or change any Blizzard MM2 modules.
-- All gameplay actions are intentionally disabled.

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local guiParent = player:WaitForChild("PlayerGui")
local old = guiParent:FindFirstChild("Blizzard_Main_Standalone_Preview")
if old then old:Destroy() end

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
pcall(function()
    WindUI:AddTheme({Name="Blizzard Preview Mono", Accent="#FFFFFF", Dialog="#020203", Outline="#303440", Text="#F5F5F5", Placeholder="#929298", Background="#101116", Button="#222632", Toggle="#FFFFFF", Icon="#FFFFFF"})
end)
local window = WindUI:CreateWindow({
    Title="Blizzard MM2 - Main Preview", Author="v1.85.4 | VISUAL ONLY",
    Folder="BlizzardMainStandalonePreview", Icon="snowflake",
    Theme="Blizzard Preview Mono", Size=UDim2.fromOffset(580,430),
    Transparent=true, HideSearchBar=true,
    OpenButton={Title="Main Preview",Icon="house",Enabled=true,Draggable=true,OnlyMobile=false}
})
local main = window:Tab({Title="Main",Icon="house"})
local function section(title,icon)
    -- These are native WindUI sections, unlike Blizzard's forced-open bridge.
    return main:Section({Title=title, Icon=icon, Opened=(title=="Round Information")})
end
local function action(parent,name,icon)
    parent:Button({Title=name,Desc="Visual preview only - no game action",Icon=icon,Callback=function() end})
end

local overlayGui = Instance.new("ScreenGui")
overlayGui.Name="Blizzard_Main_Standalone_Preview"
overlayGui.ResetOnSpawn=false
overlayGui.DisplayOrder=95
overlayGui.Parent=guiParent
local panel=Instance.new("Frame")
panel.Size=UDim2.fromOffset(300,322)
panel.Position=UDim2.new(0.5,-150,0.23,0)
panel.BackgroundColor3=Color3.fromRGB(26,29,40)
panel.BorderSizePixel=0
panel.Visible=false
panel.Active=true
panel.Draggable=true
panel.Parent=overlayGui
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,14)
local stroke=Instance.new("UIStroke",panel)
stroke.Color=Color3.fromRGB(65,74,96)
stroke.Thickness=1.2
local pad=Instance.new("UIPadding",panel)
pad.PaddingTop=UDim.new(0,12)
pad.PaddingLeft=UDim.new(0,14)
pad.PaddingRight=UDim.new(0,14)
local layout=Instance.new("UIListLayout",panel)
layout.Padding=UDim.new(0,6)
layout.SortOrder=Enum.SortOrder.LayoutOrder
local function line(label,value,color)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,22)
    row.BackgroundTransparency=1
    row.Parent=panel
    local a=Instance.new("TextLabel",row)
    a.Size=UDim2.new(0.52,0,1,0)
    a.BackgroundTransparency=1
    a.Font=Enum.Font.Gotham
    a.TextSize=12
    a.TextXAlignment=Enum.TextXAlignment.Left
    a.TextColor3=Color3.fromRGB(170,180,198)
    a.Text=label
    local b=Instance.new("TextLabel",row)
    b.Position=UDim2.new(0.52,0,0,0)
    b.Size=UDim2.new(0.48,0,1,0)
    b.BackgroundTransparency=1
    b.Font=Enum.Font.GothamBold
    b.TextSize=12
    b.TextXAlignment=Enum.TextXAlignment.Right
    b.TextColor3=color or Color3.fromRGB(245,245,248)
    b.Text=value
end
line("ROUND INFORMATION", "PREVIEW",Color3.fromRGB(125,183,255))
line("Round Status", "In Progress",Color3.fromRGB(66,220,135))
line("Current Map", "Research Facility")
line("Time Remaining", "01:42")
line("Your Role", "Innocent",Color3.fromRGB(66,220,135))
line("Players Alive", "8 / 12")
line("Murderer", "Player123 - Alive",Color3.fromRGB(255,112,122))
line("Sheriff", "Player456 - Alive",Color3.fromRGB(120,174,255))
line("Hero", "Not assigned",Color3.fromRGB(255,203,95))
line("Dropped Gun", "Not dropped")
line("DATA", "SAMPLE ONLY",Color3.fromRGB(165,170,185))

local round=section("Round Information","activity")
round:Paragraph({Title="Round Status",Desc="In Progress  |  Research Facility  |  01:42"})
round:Paragraph({Title="Your Role / Players Alive",Desc="Innocent  |  8 / 12"})
round:Paragraph({Title="Round Roles",Desc="Murderer: Player123 (Alive)\nSheriff: Player456 (Alive)\nHero: Not assigned"})
round:Toggle({Title="Round Information Overlay",Desc="Show sample round details on screen.",Default=false,Callback=function(on) panel.Visible=(on==true) end})

local quick=section("Quick Actions","zap")
action(quick,"Fling Murderer","wind")
action(quick,"Shoot Murderer (LEGIT)","crosshair")
action(quick,"Kill All","swords")
action(quick,"Teleport to Lobby","house")
action(quick,"Teleport to Map","map")
action(quick,"Hop Server","shuffle")
local selectedPlayer="Select a player"
quick:Dropdown({Title="Teleport to Player",Desc="Sample players for layout testing",Values={"Select a player","Player123","Player456","Player789"},Value="Select a player",Callback=function(value) selectedPlayer=type(value)=="table" and (value[1] or "Select a player") or tostring(value) end})
action(quick,"Teleport to Selected Player","navigation")

local voting=section("Map Voting","vote")
voting:Toggle({Title="Show Map Voting Overlay",Desc="Coming later - visual placeholder only.",Default=false,Callback=function() end})

local emotes=section("Animations & Emotes","smile")
emotes:Dropdown({Title="Select Emote",Desc="Preview selection only",Values={"Wave","Cheer","Dance","Laugh","Point"},Value="Wave",Callback=function() end})
action(emotes,"Play Emote","play")
action(emotes,"Stop Emote","square")

print("[Blizzard Main Preview] Standalone visual preview loaded. No Blizzard gameplay modules changed.")
