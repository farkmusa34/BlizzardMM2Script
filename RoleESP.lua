--============================================================
-- Blizzard MM2 - RoleESP.lua
-- Player roles and character appearance, independent of Visuals.
-- Uses Shared.lua role cache and the existing proven ESP logic.
--============================================================
local MM2 = getgenv and getgenv().MM2_V85_SPLIT or _G.MM2_V85_SPLIT
assert(MM2 and MM2.UI and MM2.UI.WindTabs and MM2.UI.WindTabs.RoleESP,
    "Load Shared.lua + UI.lua before RoleESP.lua")
local Players = MM2.Services.Players
local LocalPlayer = MM2.LocalPlayer
local Flags = MM2.Flags
local UI = MM2.UI
local RoleTab = UI.WindTabs.RoleESP

-- Keep previous highlighting defaults off, with fill enabled by default.
if Flags.CharacterFill == nil then Flags.CharacterFill = true end
if type(Flags.FillStrength) ~= "number" then Flags.FillStrength = 50 end

UI.AddSection(UI.RoleESPPage, "Player")
for _,role in ipairs({"Innocent", "Murderer", "Sheriff", "Hero"}) do
    UI.CreateToggle(UI.RoleESPPage, role .. " ESP",
        "Highlights " .. string.lower(role) .. " players with their role color.",
        role .. "ESP", function()
            if MM2.Functions.UpdatePlayerESP then MM2.Functions.UpdatePlayerESP() end
        end, "scan-eye")
end
UI.CreateToggle(UI.RoleESPPage, "Nametags",
    "Shows player names above their heads.", "NameTags", function()
        if MM2.Functions.UpdatePlayerESP then MM2.Functions.UpdatePlayerESP() end
    end, "badge")

UI.AddSection(UI.RoleESPPage, "Appearance")
UI.CreateToggle(UI.RoleESPPage, "Character Fill",
    "Fills enabled player highlights with their role colors.", "CharacterFill", function()
        if MM2.Functions.UpdatePlayerESP then MM2.Functions.UpdatePlayerESP() end
    end, "palette")
local sliderOK, sliderError = pcall(function()
    RoleTab:Slider({
        Title = "Fill Strength",
        Desc = "Controls character highlight opacity (0–100%).",
        Value = {Min=0, Max=100, Default=Flags.FillStrength, Step=5},
        Callback = function(value)
            if type(value) == "number" then
                Flags.FillStrength = math.clamp(value, 0, 100)
                if MM2.Functions.UpdatePlayerESP then MM2.Functions.UpdatePlayerESP() end
            end
        end,
    })
end)
if not sliderOK then warn("[Blizzard Role ESP] Fill Strength slider:", sliderError) end

--============================================================
-- PLAYER ESP: independent outlines, fill, and nametags
--============================================================
local MATCH_ESP_ROLE_GRACE = 0.85
MM2.State.MatchESPLastValid = MM2.State.MatchESPLastValid or {}

local function RemovePlayerESP(player)
    if not player then return end
    local char=player.Character
    if char then
        local h=char:FindFirstChild("MM2_MatchESP")
        if h then h:Destroy() end
        local head=char:FindFirstChild("Head")
        local tag=head and head:FindFirstChild("MM2_NameTag")
        if tag then tag:Destroy() end
    end
    MM2.State.MatchESPLastValid[player]=nil
end
MM2.Functions.RemovePlayerESP=RemovePlayerESP
MM2.Functions.ClearPlayerESP=function()
    for _,player in ipairs(Players:GetPlayers()) do RemovePlayerESP(player) end
    table.clear(MM2.State.MatchESPLastValid)
end
MM2.Functions.RefreshPlayerVisuals=function()
    if not (Flags.InnocentESP or Flags.MurdererESP or Flags.SheriffESP or Flags.HeroESP or Flags.NameTags) then MM2.Functions.ClearPlayerESP() end
end

local function HasLiveAssignedRoles()
    for _,player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not MM2.State.PlayerOutOfRound[player.Name] then
            local char=player.Character
            local hum=char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health>0 then
                local role=MM2.GetPlayerRole(player)
                if role=="Murderer" or role=="Sheriff" or role=="Hero" then return true end
            end
        end
    end
    return false
end

local function GetVisibleRole(player, char, existing)
    local role=MM2.GetPlayerRole(player)
    if role=="Murderer" or role=="Sheriff" or role=="Hero" or role=="Innocent" then
        MM2.State.MatchESPLastValid[player]={Character=char,Role=role,Time=os.clock()}
        return role
    end
    local cached=MM2.State.MatchESPLastValid[player]
    if existing and cached and cached.Character==char and os.clock()-cached.Time<=MATCH_ESP_ROLE_GRACE then
        return cached.Role
    end
    return nil
end

MM2.Functions.UpdatePlayerESP=function()
    if not (Flags.InnocentESP or Flags.MurdererESP or Flags.SheriffESP or Flags.HeroESP or Flags.NameTags) then
        if next(MM2.State.MatchESPLastValid) then MM2.Functions.ClearPlayerESP() end
        return
    end
    if not MM2.State.RoleRoundActive and not HasLiveAssignedRoles() then
        MM2.Functions.ClearPlayerESP()
        return
    end
    for _,player in ipairs(Players:GetPlayers()) do
        if player==LocalPlayer or MM2.State.PlayerOutOfRound[player.Name] then
            RemovePlayerESP(player)
            continue
        end
        local char=player.Character
        local head=char and char:FindFirstChild("Head")
        local hrp=char and char:FindFirstChild("HumanoidRootPart")
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if not head or not hrp or not hum or hum.Health<=0 or not MM2.IsPositionWithinESPDistance(hrp.Position) then
            RemovePlayerESP(player)
            continue
        end
        local h=char:FindFirstChild("MM2_MatchESP")
        local tag=head:FindFirstChild("MM2_NameTag")
        local role=GetVisibleRole(player,char,h~=nil or tag~=nil)
        if not role then RemovePlayerESP(player) continue end
        local color=MM2.GetRoleColor(role)
        if Flags[role .. "ESP"] then
            if not h then
                h=Instance.new("Highlight")
                h.Name="MM2_MatchESP"
                h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                h.Parent=char
            end
            h.Adornee=char
            h.Enabled=true
            h.FillColor=color
            h.OutlineColor=color
            h.OutlineTransparency=0
            h.FillTransparency=(Flags.CharacterFill and (1-math.clamp(Flags.FillStrength or 50,0,100)/100)) or 1
        elseif h then h:Destroy() end
        if Flags.NameTags then
            if not tag then
                tag=Instance.new("BillboardGui")
                tag.Name="MM2_NameTag"
                tag.Size=UDim2.fromOffset(160,40)
                tag.StudsOffset=Vector3.new(0,2.5,0)
                tag.AlwaysOnTop=true
                tag.Parent=head
                local text=Instance.new("TextLabel")
                text.Name="TagText"
                text.Size=UDim2.fromScale(1,1)
                text.BackgroundTransparency=1
                text.Font=Enum.Font.GothamBold
                text.TextSize=12
                text.TextStrokeTransparency=0.5
                text.Parent=tag
            end
            tag.Adornee=head
            tag.Enabled=true
            local label=tag:FindFirstChild("TagText")
            if label then label.Text=player.Name label.TextColor3=color end
        elseif tag then tag:Destroy() end
    end
end

-- Independent update loop: Nametags must still work when Role ESP is OFF.
-- Shared.lua may also call UpdatePlayerESP; updates reuse existing instances.
task.spawn(function()
    while MM2.Running do
        if Flags.InnocentESP or Flags.MurdererESP or Flags.SheriffESP or Flags.HeroESP or Flags.NameTags then
            MM2.Functions.UpdatePlayerESP()
        elseif next(MM2.State.MatchESPLastValid) then
            MM2.Functions.ClearPlayerESP()
        end
        task.wait(0.15)
    end
    MM2.Functions.ClearPlayerESP()
end)

