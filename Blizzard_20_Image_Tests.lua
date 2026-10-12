-- Blizzard Wallpaper: 20 Image Tests (standalone, visual diagnostic only)
-- Does not alter Blizzard, WindUI, or gameplay modules.
local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local player = Players.LocalPlayer
local guiParent = player:WaitForChild("PlayerGui")
local previous = guiParent:FindFirstChild("Blizzard_20_Image_Tests")
if previous then previous:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "Blizzard_20_Image_Tests"
gui.ResetOnSpawn = false
gui.DisplayOrder = 9000
gui.IgnoreGuiInset = false
gui.Parent = guiParent
local function make(class, props, parent)
    local object = Instance.new(class)
    for k,v in pairs(props) do object[k] = v end
    object.Parent = parent
    return object
end
local bg = make("Frame", {AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.52),Size=UDim2.fromScale(.88,.80),BackgroundColor3=Color3.fromRGB(13,15,21),BorderSizePixel=0},gui)
make("UICorner",{CornerRadius=UDim.new(0,12)},bg)
make("UIStroke",{Color=Color3.fromRGB(85,92,110),Thickness=1},bg)
make("TextLabel",{Size=UDim2.new(1,-60,0,34),Position=UDim2.fromOffset(12,4),BackgroundTransparency=1,Text="BLIZZARD • 20 IMAGE TESTS",TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=17,TextXAlignment=Enum.TextXAlignment.Left},bg)
local close = make("TextButton",{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-8,0,6),Size=UDim2.fromOffset(32,28),Text="X",TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(60,35,40),Font=Enum.Font.GothamBold,TextSize=16},bg)
make("UICorner",{CornerRadius=UDim.new(0,7)},close)
close.MouseButton1Click:Connect(function() gui:Destroy() end)
local note = make("TextLabel",{Position=UDim2.fromOffset(12,39),Size=UDim2.new(1,-24,0,32),BackgroundTransparency=1,Text="Planet ID: 71522230935715  •  Green = loaded  •  Red = failed / timed out",TextColor3=Color3.fromRGB(190,195,205),TextWrapped=true,Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},bg)
local scroll = make("ScrollingFrame",{Position=UDim2.fromOffset(10,76),Size=UDim2.new(1,-20,1,-84),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,CanvasSize=UDim2.fromScale(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y},bg)
local grid = make("UIGridLayout",{CellSize=UDim2.new(.24,-6,0,116),CellPadding=UDim2.new(.01,0,0,8),SortOrder=Enum.SortOrder.LayoutOrder},scroll)
local sources = {
    {"PLANET ASSET", "rbxassetid://71522230935715"},
    {"PLANET THUMB", "rbxthumb://type=Asset&id=71522230935715&w=420&h=420"},
    {"ROBLOX BUILTIN A", "rbxasset://textures/ui/GuiImagePlaceholder.png"},
    {"ROBLOX BUILTIN B", "rbxasset://textures/ui/Loading/LoadingCircle.png"},
}
local modes = {"Fit Label", "Crop Label", "Stretch Label", "Fit Button", "Tile Label"}
local loadedCount, finishedCount = 0,0
local images = {}
for s,source in ipairs(sources) do
    for m,mode in ipairs(modes) do
        local index = (s-1)*5+m
        local cell = make("Frame",{LayoutOrder=index,BackgroundColor3=Color3.fromRGB(29,32,41),BorderSizePixel=0},scroll)
        make("UICorner",{CornerRadius=UDim.new(0,7)},cell)
        local label = make("TextLabel",{Position=UDim2.fromOffset(4,3),Size=UDim2.new(1,-8,0,17),BackgroundTransparency=1,Text=index..". "..source[1],TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=10,TextScaled=true},cell)
        local class = mode == "Fit Button" and "ImageButton" or "ImageLabel"
        local img = make(class,{Position=UDim2.new(.05,0,0,23),Size=UDim2.new(.9,0,0,66),BackgroundColor3=Color3.fromRGB(8,10,14),BorderSizePixel=0,Image=source[2],ScaleType=(mode=="Crop Label" and Enum.ScaleType.Crop or mode=="Stretch Label" and Enum.ScaleType.Stretch or mode=="Tile Label" and Enum.ScaleType.Tile or Enum.ScaleType.Fit)},cell)
        if mode == "Tile Label" then img.TileSize=UDim2.fromOffset(45,45) end
        local status = make("TextLabel",{Position=UDim2.new(0,4,1,-24),Size=UDim2.new(1,-8,0,20),BackgroundTransparency=1,Text="Checking...",TextColor3=Color3.fromRGB(245,198,95),Font=Enum.Font.GothamBold,TextSize=11},cell)
        images[#images+1] = {img=img,status=status,source=source[1]}
    end
end
local summary = make("TextLabel",{Position=UDim2.new(0,12,1,-26),Size=UDim2.new(1,-24,0,20),BackgroundTransparency=1,Text="Testing 20 combinations...",TextColor3=Color3.fromRGB(220,220,220),Font=Enum.Font.Gotham,TextSize=11,Visible=false},bg)
-- Poll IsLoaded: checks actual ImageLabel/ImageButton rendering instead of trusting PreloadAsync alone.
for _,item in ipairs(images) do
    task.spawn(function()
        local deadline = os.clock()+14
        while gui.Parent and not item.img.IsLoaded and os.clock()<deadline do task.wait(.25) end
        if not gui.Parent then return end
        local ok = item.img.IsLoaded
        item.status.Text = ok and "LOADED" or "NOT LOADED"
        item.status.TextColor3 = ok and Color3.fromRGB(105,235,135) or Color3.fromRGB(245,105,105)
        finishedCount += 1
        if ok then loadedCount += 1 end
        if finishedCount == #images then
            note.Text = "Finished: "..loadedCount.." / 20 loaded. Compare PLANET with ROBLOX BUILTIN tests."
        end
    end)
end
