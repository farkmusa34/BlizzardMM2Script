--============================================================
-- Blizzard MM2 V8.8.4 - KnifeSkin.lua
-- Knife skin module shell. Captured skins will be added next.
--============================================================

local MM2 = (getgenv and getgenv().MM2_V85_SPLIT) or _G.MM2_V85_SPLIT
assert(MM2 and MM2.UI and MM2.UI.SkinChangerKnifePage, "Load Shared.lua + UI.lua first")

local UI = MM2.UI
MM2.SkinChanger = MM2.SkinChanger or {}
local SkinChanger = MM2.SkinChanger
SkinChanger.SelectedKnife = SkinChanger.SelectedKnife or "Default"
SkinChanger.KnifeSkins = SkinChanger.KnifeSkins or {}

-- Public registration point used when we add captured knife skins.
function SkinChanger.RegisterKnifeSkin(Name, Data)
    if type(Name) ~= "string" or Name == "" or type(Data) ~= "table" then return false end
    if SkinChanger.KnifeSkins[Name] ~= nil then return false end
    SkinChanger.KnifeSkins[Name] = Data
    return true
end

print("[Blizzard MM2] KnifeSkin.lua loaded")
return MM2
