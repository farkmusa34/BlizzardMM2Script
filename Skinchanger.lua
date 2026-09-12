--============================================================
-- Blizzard MM2 V8.8.4 - SkinChanger.lua
-- WindUI-compatible Skin Changer module
--============================================================

local MM2 =
	getgenv
	and getgenv().MM2_V85_SPLIT
	or _G.MM2_V85_SPLIT

assert(
	MM2
	and MM2.UI
	and MM2.UI.SkinChangerPage,
	"Load Shared.lua + the WindUI UI.lua first"
)

local UI = MM2.UI

--============================================================
-- GUN
--============================================================

UI.AddSection(
	UI.SkinChangerPage,
	"Gun",
	"Change the appearance of your gun"
)

UI.CreateDropdown(
	UI.SkinChangerPage,
	"Gun Skin",
	"Select a gun skin",
	{
		"Default",
		"Harvester",
	},
	"Default",
	function(value)
		print(
			"[SkinChanger] Gun Skin:",
			value
		)
	end
)

--============================================================
-- KNIFE
--============================================================

UI.AddSection(
	UI.SkinChangerPage,
	"Knife",
	"Change the appearance of your knife"
)

UI.CreateDropdown(
	UI.SkinChangerPage,
	"Knife Skin",
	"Select a knife skin",
	{
		"Default",
	},
	"Default",
	function(value)
		print(
			"[SkinChanger] Knife Skin:",
			value
		)
	end
)

print(
	"[Blizzard MM2] SkinChanger.lua UI loaded"
)

return MM2