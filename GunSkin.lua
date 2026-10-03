--============================================================
-- Blizzard MM2 V8.8.4 - GunSkin.lua
-- Gun skin module shell. Captured skins will be added next.
--============================================================

local MM2 = (getgenv and getgenv().MM2_V85_SPLIT) or _G.MM2_V85_SPLIT
assert(MM2 and MM2.UI and MM2.UI.SkinChangerGunPage, "Load Shared.lua + UI.lua first")

local UI = MM2.UI
MM2.SkinChanger = MM2.SkinChanger or {}
local SkinChanger = MM2.SkinChanger
SkinChanger.SelectedGun = SkinChanger.SelectedGun or "Default"
SkinChanger.GunSkins = SkinChanger.GunSkins or {}

-- Public registration point used when we add captured gun skins.
function SkinChanger.RegisterGunSkin(Name, Data)
    if type(Name) ~= "string" or Name == "" or type(Data) ~= "table" then return false end
    if SkinChanger.GunSkins[Name] ~= nil then return false end
    SkinChanger.GunSkins[Name] = Data
    return true
end

print("[Blizzard MM2] GunSkin.lua loaded")
return MM2
