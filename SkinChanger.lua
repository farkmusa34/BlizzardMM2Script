--============================================================
-- Blizzard MM2 V8.8.4 - SkinChanger.lua
--
-- Client-side cosmetic skin changer.
-- Does NOT modify ownership or inventory metadata.
--
-- Gun:
--   Default + 25 captured skins
--
-- Knife:
--   Default + 25 captured skins
--
-- Includes:
--   • Held gun / knife skin model
--   • Per-skin gun grip
--   • Real local MM2 GunDisplay / KnifeDisplay
--   • Visible MM2 BackpackUI hotbar icon
--   • Round / respawn persistence
--   • Silent background reapplication
--   • Palette WindUI notifications
--============================================================

local MM2 =
	getgenv
	and getgenv().MM2_V85_SPLIT
	or _G.MM2_V85_SPLIT

assert(
	MM2
	and MM2.UI
	and MM2.UI.SkinChangerPage,
	"Load Shared.lua + UI.lua first"
)

print("[SkinChanger] Starting...")

--============================================================
-- REFERENCES
--============================================================

local S = MM2.Services
local UI = MM2.UI
local Track = MM2.Track

local Players =
	S.Players
	or game:GetService("Players")

local Workspace =
	game:GetService("Workspace")

local LocalPlayer =
	MM2.LocalPlayer
	or Players.LocalPlayer

local Backpack =
	LocalPlayer:WaitForChild("Backpack")

local PlayerGui =
	LocalPlayer:WaitForChild("PlayerGui")

--============================================================
-- MODULE STATE
--============================================================

MM2.SkinChanger =
	MM2.SkinChanger
	or {}

local SkinChanger =
	MM2.SkinChanger

SkinChanger.SelectedGun =
	SkinChanger.SelectedGun
	or "Default"

SkinChanger.SelectedKnife =
	SkinChanger.SelectedKnife
	or "Default"

local CurrentGun = nil
local CurrentKnife = nil

local SavedGunState =
	setmetatable({}, {__mode = "k"})

local SavedHolsterState =
	setmetatable({}, {__mode = "k"})

local SavedKnifeState =
	setmetatable({}, {__mode = "k"})

local SavedKnifeBackState =
	setmetatable({}, {__mode = "k"})

--============================================================
-- GUN SKIN DATA
--============================================================

local COMMON_GRIP =
	CFrame.new(
		0,
		-0.699999988079,
		-0.300000011921,
		1, 0, 0,
		0, 1, 4.37113882867e-08,
		0, -4.37113882867e-08, 1
	)

local SWIRLY_GRIP =
	CFrame.new(
		0,
		-0.699999988079,
		-0.300000011921,
		1, 0, 0,
		0, 0, -1,
		0, 1, 0
	)

local GunSkins = {
	["Harvester"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=7800847534",
		MeshId = "rbxassetid://7775027413",
		TextureId = "http://www.roblox.com/asset/?id=7775245551",
		Size = Vector3.new(2.24476003647, 0.654919981956, 2.88000011444),
		Scale = Vector3.new(0.0507251992822, 0.0507255233824, 0.0506916828454),
		Grip = COMMON_GRIP,
		HolsterCFrame = CFrame.new(
			0.129910007119, 0, 0.0750100016594,
			1.99999994948e-05, -0.499998033047, -0.866026580334,
			1, -4.19616335421e-05, 4.73204127047e-05,
			-5.99999984843e-05, -0.866026580334, 0.499998033047
		),
	},

	["Gingerscope"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=15666596216",
		MeshId = "rbxassetid://15374602183",
		TextureId = "rbxassetid://15409041564",
		Size = Vector3.new(0.269699990749, 1.2581499815, 4.20871019363),
		Scale = Vector3.new(0.0841728448868, 0.0841981619596, 0.0841742008924),
		Grip = COMMON_GRIP,
		HolsterCFrame = CFrame.new(
			0.129910007119, -2.99999992421e-05, 0.0750000029802,
			1, 0, 0,
			0, 0.707131803036, 0.707081794739,
			0, -0.707081794739, 0.707131803036
		),
	},

	["Icepiercer"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=11874071041",
		MeshId = "rbxassetid://11868991644",
		TextureId = "rbxassetid://11869075814",
		Size = Vector3.new(2.46938991547, 0.752629995346, 2.73834991455),
		Scale = Vector3.new(0.0547669678926, 0.0547667965293, 0.054766997695),
		Grip = COMMON_GRIP,
		HolsterCFrame = CFrame.new(
			0.129879996181, 0, 0.0749799981713,
			1.99999994948e-05, -0.499998033047, -0.866026580334,
			1, -4.19616335421e-05, 4.73204127047e-05,
			-5.99999984843e-05, -0.866026580334, 0.499998033047
		),
	},

	["Chroma Bauble"] = {
		Icon = "rbxthumb://type=Asset&w=150&h=150&id=137938731902685",
		MeshId = "rbxassetid://107813118898769",
		TextureId = "rbxassetid://137012201908941",
		Size = Vector3.new(0.484169989824, 1.37511003017, 2.08516001701),
		Scale = Vector3.new(0.0471000000834, 0.0471000000834, 0.0471000000834),
		Grip = COMMON_GRIP,
		HolsterCFrame = CFrame.new(
			0, -0.238619998097, 0.107270002365,
			1, 0, 0,
			0, 0.642758846283, 0.766068637371,
			0, -0.766068637371, 0.642758846283
		),
	},

	["Chroma Blizzard"] = {
		Icon = "rbxassetid://97865938907417",
		MeshId = "rbxassetid://77235373292363",
		TextureId = "rbxassetid://97280881789656",
		Size = Vector3.new(0.421099990606, 1.43482005596, 2.07080006599),
		Scale = Vector3.new(0.0433400012553, 0.0433400012553, 0.0433400012553),
		Grip = COMMON_GRIP,
		HolsterCFrame = CFrame.new(
			0, -0.192719995975, 0.0866400003433,
			1, 0, 0,
			0, 0.642758846283, 0.766068637371,
			0, -0.766068637371, 0.642758846283
		),
	},

	["Chroma Constellation"] = {
		Icon = "rbxthumb://type=Asset&w=150&h=150&id=98517109155878",
		MeshId = "rbxassetid://124598402927958",
		TextureId = "rbxassetid://123603327635244",
		Size = Vector3.new(0.537000000477, 1.58299994469, 2.367000103),
		Scale = Vector3.new(0.10123000294, 0.10123000294, 0.10123000294),
		Grip = COMMON_GRIP,
		HolsterCFrame = CFrame.new(
			0, -0.512939989567, 0.230580002069,
			1, 0, 0,
			0, 0.642758846283, 0.766068637371,
			0, -0.766068637371, 0.642758846283
		),
	},

	["Chroma Darkbringer"] = {
		Icon = "http://www.roblox.com/asset/?id=4751507011",
		MeshId = "rbxassetid://4730813852",
		TextureId = "rbxassetid://4728494788",
		Size = Vector3.new(0.426629990339, 1.37000000477, 1.64999997616),
		Scale = Vector3.new(0.0363899990916, 0.035000000149, 0.035000000149),
		Grip = COMMON_GRIP,
		HolsterCFrame = CFrame.new(
			0, -0.186649993062, 0.123209998012,
			1, 0, 0,
			0, 0.173620477319, 0.984812676907,
			0, -0.984812676907, 0.173620477319
		),
	},

	["Chroma Evergun"] = {
		Icon = "rbxassetid://15694208971",
		MeshId = "rbxassetid://15408863676",
		TextureId = "",
		Size = Vector3.new(0.833000004292, 1.38399994373, 2.51900005341),
		Scale = Vector3.new(0.0209999997169, 0.0209999997169, 0.0205000005662),
		Grip = COMMON_GRIP,
		HolsterCFrame = CFrame.new(
			0, -0.199980005622, 0.0899199992418,
			1, 0, 0,
			0, 0.642758846283, 0.766068637371,
			0, -0.766068637371, 0.642758846283
		),
	},

	["Chroma Laser"] = {
		Icon = "rbxassetid://3187422628",
		MeshId = "rbxassetid://130099641",
		TextureId = "",
		Size = Vector3.new(0.509999990463, 1.17999994755, 1.35000002384),
		Scale = Vector3.new(0.5, 0.5, 0.5),
		Grip = COMMON_GRIP,
		HolsterCFrame = CFrame.new(),
	},

	["Chroma Lightbringer"] = {
		Icon = "http://www.roblox.com/asset/?id=4751507078",
		MeshId = "rbxassetid://4730813852",
		TextureId = "rbxassetid://5278764604",
		Size = Vector3.new(0.426629990339, 1.37000000477, 1.64999997616),
		Scale = Vector3.new(0.0363899990916, 0.035000000149, 0.035000000149),
		Grip = COMMON_GRIP,
		HolsterCFrame = CFrame.new(
			0, -0.186609998345, 0.12323000282,
			1, 0, 0,
			0, 0.173620477319, 0.984812676907,
			0, -0.984812676907, 0.173620477319
		),
	},

	["Chroma Luger"] = {
		Icon = "rbxassetid://3187399258",
		MeshId = "rbxassetid://95356090",
		TextureId = "",
		Size = Vector3.new(0.509999990463, 1.17999994755, 1.35000002384),
		Scale = Vector3.new(1.79999995232, 1.79999995232, 1.79999995232),
		Grip = COMMON_GRIP,
		HolsterCFrame = CFrame.new(
			0.15000000596, 0.0383500009775, 0.333220005035,
			1, 0, 0,
			0, 0, 1,
			0, -1, 0
		),
	},

	["Chroma Raygun"] = {
		Icon = "rbxthumb://type=Asset&w=150&h=150&id=83259634072260",
		MeshId = "rbxassetid://115447220952926",
		TextureId = "rbxassetid://127881437685243",
		Size = Vector3.new(0.689999997616, 1.64300000668, 2.35500001907),
		Scale = Vector3.new(0.0472000017762, 0.0472000017762, 0.0472000017762),
		Grip = COMMON_GRIP,
		HolsterCFrame = CFrame.new(
			0, -0.200039997697, 0.0899100005627,
			1, 0, 0,
			0, 0.642758846283, 0.766068637371,
			0, -0.766068637371, 0.642758846283
		),
	},

	["Chroma Shark"] = {
		Icon = "rbxassetid://3187421856",
		MeshId = "rbxassetid://118269783",
		TextureId = "rbxassetid://3171214838",
		Size = Vector3.new(0.800000011921, 1.01999998093, 2.06999993324),
		Scale = Vector3.new(0.439999997616, 0.439999997616, 0.439999997616),
		Grip = COMMON_GRIP,
		HolsterCFrame = CFrame.new(
			0.15000000596, -0.243560001254, 0.230590000749,
			1, 0, 0,
			0, 0, 1,
			0, -1, 0
		),
	},

	["Chroma Snowcannon"] = {
		Icon = "rbxassetid://93075282395578",
		MeshId = "rbxassetid://99836890880541",
		TextureId = "rbxassetid://122392330922281",
		Size = Vector3.new(0.559000015259, 1.35500001907, 2.5),
		Scale = Vector3.new(0.0496399998665, 0.0496399998665, 0.0496399998665),
		Grip = COMMON_GRIP,
		HolsterCFrame = CFrame.new(
			0, -0.251529991627, 0.113049998879,
			1, 0, 0,
			0, 0.642758846283, 0.766068637371,
			0, -0.766068637371, 0.642758846283
		),
	},

	["Chroma Sunrise"] = {
		Icon = "rbxthumb://type=Asset&w=150&h=150&id=124766755976937",
		MeshId = "rbxassetid://109742397574153",
		TextureId = "rbxassetid://71731808219690",
		Size = Vector3.new(0.484169989824, 1.37511003017, 2.08516001701),
		Scale = Vector3.new(0.0471000000834, 0.0471000000834, 0.0471000000834),
		Grip = COMMON_GRIP,
		HolsterCFrame = CFrame.new(
			0, -0.199980005622, 0.0899199992418,
			1, 0, 0,
			0, 0.642758846283, 0.766068637371,
			0, -0.766068637371, 0.642758846283
		),
	},

	["Chroma Swirly Gun"] = {
		Icon = "http://www.roblox.com/asset/?id=8311453396",
		MeshId = "rbxassetid://8310911339",
		TextureId = "rbxassetid://10044501316",
		Size = Vector3.new(1.04972994328, 3.20869994164, 1.60000002384),
		Scale = Vector3.new(1, 1, 1),
		Grip = SWIRLY_GRIP,
		HolsterCFrame = CFrame.new(),
	},

	["Chroma Traveler's Gun"] = {
		Icon = "rbxassetid://15097920149",
		MeshId = "rbxassetid://15090814396",
		TextureId = "rbxassetid://15090814672",
		Size = Vector3.new(0.571979999542, 0.528729975224, 2.51999998093),
		Scale = Vector3.new(0.0483900010586, 0.0491000004113, 0.049240000546),
		Grip = COMMON_GRIP,
		HolsterCFrame = CFrame.new(),
	},

	["Chroma Treat"] = {
		Icon = "rbxassetid://121364530728626",
		MeshId = "rbxassetid://135790480817772",
		TextureId = "rbxassetid://86649236464456",
		Size = Vector3.new(0.553520023823, 1.57208001614, 2.38384008408),
		Scale = Vector3.new(0.0538400001824, 0.0538400001824, 0.0538400001824),
		Grip = COMMON_GRIP,
		HolsterCFrame = CFrame.new(
			0, -0.200039997697, 0.0898699983954,
			1, 0, 0,
			0, 0.642758846283, 0.766068637371,
			0, -0.766068637371, 0.642758846283
		),
	},

	["Chroma Vampire's Gun"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=85107391551890",
		MeshId = "rbxassetid://126591885289479",
		TextureId = "rbxassetid://104946799389637",
		Size = Vector3.new(0.42199999094, 1.29200005531, 2.41199994087),
		Scale = Vector3.new(0.0500000007451, 0.0500000007451, 0.0500000007451),
		Grip = COMMON_GRIP,
		HolsterCFrame = CFrame.new(
			0, -0.200010001659, 0.0898900032043,
			1, 0, 0,
			0, 0.642758846283, 0.766068637371,
			0, -0.766068637371, 0.642758846283
		),
	},

	["Chroma Watergun"] = {
		Icon = "rbxassetid://18351465514",
		MeshId = "rbxassetid://18280999342",
		TextureId = "rbxassetid://18281003313",
		Size = Vector3.new(0.448000013828, 1.36500000954, 2),
		Scale = Vector3.new(0.0394699983299, 0.0394699983299, 0.0394699983299),
		Grip = COMMON_GRIP,
		HolsterCFrame = CFrame.new(
			0, -0.200039997697, 0.0899000018835,
			1, 0, 0,
			0, 0.642758846283, 0.766068637371,
			0, -0.766068637371, 0.642758846283
		),
	},

	["Amerilaser"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=446050753",
		MeshId = "http://www.roblox.com/asset/?id=116657254",
		TextureId = "https://www.roblox.com/asset/?id=445884341",
		Size = Vector3.new(0.600000023842, 1, 1.79999995232),
		Scale = Vector3.new(0.699999988079, 0.699999988079, 0.699999988079),
		Grip = COMMON_GRIP,
		HolsterCFrame = CFrame.new(),
	},

	["Bauble"] = {
		Icon = "rbxthumb://type=Asset&w=150&h=150&id=84481559639371",
		MeshId = "rbxassetid://107813118898769",
		TextureId = "rbxassetid://137012201908941",
		Size = Vector3.new(0.484169989824, 1.37511003017, 2.08516001701),
		Scale = Vector3.new(0.0471000000834, 0.0471000000834, 0.0471000000834),
		Grip = COMMON_GRIP,
		HolsterCFrame = CFrame.new(
			0, -0.238619998097, 0.107270002365,
			1, 0, 0,
			0, 0.642758846283, 0.766068637371,
			0, -0.766068637371, 0.642758846283
		),
	},

	["Blaster"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=386277381",
		MeshId = "http://www.roblox.com/asset/?id=92656610",
		TextureId = "https://www.roblox.com/asset/?id=386269992",
		Size = Vector3.new(0.800000011921, 2, 3.09999990463),
		Scale = Vector3.new(0.40000000596, 0.449999988079, 0.5),
		Grip = COMMON_GRIP,
		HolsterCFrame = CFrame.new(
			0.15000000596, 0.05488999933, 0.204899996519,
			1, 0, 0,
			0, 0.173620477319, 0.984812676907,
			0, -0.984812676907, 0.173620477319
		),
	},

	["Blossom"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=12339377105",
		MeshId = "rbxassetid://12322809632",
		TextureId = "rbxassetid://12322809917",
		Size = Vector3.new(0.606119990349, 0.265819996595, 1.16242003441),
		Scale = Vector3.new(0.0476300008595, 0.0441300012171, 0.0438200011849),
		Grip = COMMON_GRIP,
		HolsterCFrame = CFrame.new(
			0, -0.200010001659, 0.0899000018835,
			1, 0, 0,
			0, 0.642758846283, 0.766068637371,
			0, -0.766068637371, 0.642758846283
		),
	},

	["Borealis"] = {
		Icon = "rbxthumb://type=Asset&w=150&h=150&id=108635848059846",
		MeshId = "rbxassetid://16070198638",
		TextureId = "rbxassetid://107873598804292",
		Size = Vector3.new(0.459109991789, 1.35493004322, 2.3462998867),
		Scale = Vector3.new(0.0469265319407, 0.0469345152378, 0.0469259992242),
		Grip = COMMON_GRIP,
		HolsterCFrame = CFrame.new(),
	},
}

SkinChanger.GunSkins = GunSkins

local GunSkinOrder = {
	"Default",
	"Harvester",
	"Gingerscope",
	"Icepiercer",
	"Chroma Bauble",
	"Chroma Blizzard",
	"Chroma Constellation",
	"Chroma Darkbringer",
	"Chroma Evergun",
	"Chroma Laser",
	"Chroma Lightbringer",
	"Chroma Luger",
	"Chroma Raygun",
	"Chroma Shark",
	"Chroma Snowcannon",
	"Chroma Sunrise",
	"Chroma Swirly Gun",
	"Chroma Traveler's Gun",
	"Chroma Treat",
	"Chroma Vampire's Gun",
	"Chroma Watergun",
	"Amerilaser",
	"Bauble",
	"Blaster",
	"Blossom",
	"Borealis",
}

--============================================================
-- KNIFE SKIN DATA
-- Batwing and Celestial intentionally skipped.
--============================================================

local KNIFE_GRIP =
	CFrame.new(
		0,
		-1,
		-0.10000000149,
		1, 0, 0,
		0, 1, 0,
		0, 0, 1
	)

local KnifeSkins = {
	["Elderwood Scythe"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=4468593654",
		MeshId = "rbxassetid://4217523241",
		TextureId = "http://www.roblox.com/asset/?id=4210044808",
		Size = Vector3.new(0.288089990616, 3.82182002068, 2.61528992653),
		Scale = Vector3.new(0.0764362066984, 0.0764364004135, 0.0764362812042),
		Grip = KNIFE_GRIP,
		BackCFrame = CFrame.new(
			0.101580001414, 0.15963999927, 0.156130000949,
			0.99899572134, -0.0298155341297, -0.033445995301,
			0.0400298275054, 0.92925709486, 0.367258667946,
			0.0201299134642, -0.368228673935, 0.929517388344
		),
	},

	["Hallowscythe"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=5877016863",
		MeshId = "rbxassetid://5841877975",
		TextureId = "http://www.roblox.com/asset/?id=5841879647",
		Size = Vector3.new(0.392430007458, 3.54154992104, 2.94250011444),
		Scale = Vector3.new(0.0707915574312, 0.0708310008049, 0.0708310827613),
		Grip = KNIFE_GRIP,
		BackCFrame = CFrame.new(
			0.00824000034481, 0.0546000003815, 0.624050021172,
			-0.998681664467, 0.0469071343541, 0.0208514891565,
			0.045730073005, 0.997507631779, -0.0537343211472,
			-0.0233200397342, -0.0527099333704, -0.998337626457
		),
	},

	["Icebreaker"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=6121572723",
		MeshId = "rbxassetid://6124173614",
		TextureId = "rbxassetid://6124173821",
		Size = Vector3.new(0.410620003939, 3.07429003716, 1.9553899765),
		Scale = Vector3.new(0.96848744154, 0.968496859074, 0.968495666981),
		Grip = KNIFE_GRIP,
		BackCFrame = CFrame.new(),
	},

	["Icewing"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=2669997196",
		MeshId = "rbxassetid://3183449780",
		TextureId = "rbxassetid://2279588369",
		Size = Vector3.new(0.400029987097, 4.05000019073, 1.79999995232),
		Scale = Vector3.new(0.0850000008941, 0.0850000008941, 0.0850000008941),
		Grip = KNIFE_GRIP,
		BackCFrame = CFrame.new(
			0.00310000008903, -0.00953000038862, 0.205899998546,
			-0.999763667583, 0.0167404916137, 0.0138673856854,
			0.0203700754791, 0.944195926189, 0.3287537992,
			-0.00759002799168, 0.32895860076, -0.944313764572
		),
	},

	["Logchopper"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=4528268775",
		MeshId = "http://www.roblox.com/asset?id=4535643726",
		TextureId = "rbxassetid://5211110240",
		Size = Vector3.new(0.40000000596, 3, 0.699999988079),
		Scale = Vector3.new(0.959999978542, 0.959999978542, 0.959999978542),
		Grip = KNIFE_GRIP,
		BackCFrame = CFrame.new(),
	},

	["Nik's Scythe"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=2533350813",
		MeshId = "http://www.roblox.com/asset/?id=305826272",
		TextureId = "rbxassetid://2533345412",
		Size = Vector3.new(0.40000000596, 3, 0.800000011921),
		Scale = Vector3.new(1, 1, 1),
		Grip = KNIFE_GRIP,
		BackCFrame = CFrame.new(),
	},

	["Swirly Axe"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=8304801000",
		MeshId = "rbxassetid://8293463844",
		TextureId = "rbxassetid://8293464070",
		Size = Vector3.new(0.513459980488, 2.89648008347, 2.66000008583),
		Scale = Vector3.new(0.0579302534461, 0.0579296015203, 0.0579014122486),
		Grip = KNIFE_GRIP,
		BackCFrame = CFrame.new(),
	},

	["Traveler's Axe"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=15070870271",
		MeshId = "rbxassetid://15057341638",
		TextureId = "rbxassetid://15057460725",
		Size = Vector3.new(0.604409992695, 3.40599989891, 2.18736004829),
		Scale = Vector3.new(0.0681290477514, 0.0681200027466, 0.0681300386786),
		Grip = KNIFE_GRIP,
		BackCFrame = CFrame.new(),
	},

	["Vampire's Axe"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=130837676383567",
		MeshId = "rbxassetid://92263601594064",
		TextureId = "rbxassetid://73008954478338",
		Size = Vector3.new(0.311980009079, 3.62749004364, 1.92278003693),
		Scale = Vector3.new(0.07254909724, 0.0725497975945, 0.0725500360131),
		Grip = KNIFE_GRIP,
		BackCFrame = CFrame.new(),
	},

	["Chroma Alienbeam"] = {
		Icon = "rbxthumb://type=Asset&w=150&h=150&id=104256106059730",
		MeshId = "rbxassetid://86649405964534",
		TextureId = "rbxassetid://94763497877100",
		Size = Vector3.new(0.933000028133, 3.79099988937, 1.05400002003),
		Scale = Vector3.new(0.0769700035453, 0.0769700035453, 0.0769700035453),
		Grip = KNIFE_GRIP,
		BackCFrame = CFrame.new(),
	},

	["Chroma Boneblade"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=2513597845",
		MeshId = "rbxassetid://1857106669",
		TextureId = "rbxassetid://2513576265",
		Size = Vector3.new(0.40000000596, 3, 0.699999988079),
		Scale = Vector3.new(0.730000019073, 0.730000019073, 0.730000019073),
		Grip = KNIFE_GRIP,
		BackCFrame = CFrame.new(),
	},

	["Chroma Candleflame"] = {
		Icon = "http://www.roblox.com/asset/?id=7806149582",
		MeshId = "rbxassetid://7791364860",
		TextureId = "rbxassetid://7806078587",
		Size = Vector3.new(0.40000000596, 3, 0.800000011921),
		Scale = Vector3.new(0.0599999986589, 0.0599999986589, 0.0599999986589),
		Grip = KNIFE_GRIP,
		BackCFrame = CFrame.new(),
	},

	["Chroma Cookiecane"] = {
		Icon = "rbxassetid://11979596437",
		MeshId = "rbxassetid://7791364860",
		TextureId = "",
		Size = Vector3.new(0.40000000596, 3, 0.800000011921),
		Scale = Vector3.new(0.0599999986589, 0.0599999986589, 0.0599999986589),
		Grip = KNIFE_GRIP,
		BackCFrame = CFrame.new(),
	},

	["Chroma Deathshard"] = {
		Icon = "rbxassetid://3187397317",
		MeshId = "rbxassetid://62275962",
		TextureId = "rbxassetid://3167029738",
		Size = Vector3.new(0.550000011921, 2.3900001049, 0.20000000298),
		Scale = Vector3.new(0.800000011921, 0.800000011921, 0.800000011921),
		Grip = KNIFE_GRIP,
		BackCFrame = CFrame.new(
			0, 2.99999992421e-05, 0,
			-0.0446001961827, -0.000309581402689, -0.999005019665,
			0.03549015522, 0.999368309975, -0.00189413852058,
			0.998374402523, -0.0355393141508, -0.0445610359311
		),
	},

	["Chroma Elderwood"] = {
		Icon = "http://www.roblox.com/asset/?id=11255021976",
		MeshId = "rbxassetid://11238166013",
		TextureId = "http://www.roblox.com/asset/?id=11370088878",
		Size = Vector3.new(0.275999993086, 3.53099989891, 1.04100000858),
		Scale = Vector3.new(0.070000000298, 0.070000000298, 0.070000000298),
		Grip = KNIFE_GRIP,
		BackCFrame = CFrame.new(),
	},

	["Chroma Evergreen"] = {
		Icon = "rbxassetid://15694192241",
		MeshId = "rbxassetid://15408280573",
		TextureId = "",
		Size = Vector3.new(0.414350003004, 4.14349985123, 1.02113997936),
		Scale = Vector3.new(0.00460000010207, 0.00460000010207, 0.00460000010207),
		Grip = KNIFE_GRIP,
		BackCFrame = CFrame.new(),
	},

	["Chroma Fang"] = {
		Icon = "rbxassetid://3187397850",
		MeshId = "rbxassetid://117500241",
		TextureId = "",
		Size = Vector3.new(0.990000009537, 3, 0.230000004172),
		Scale = Vector3.new(0.40000000596, 0.370000004768, 0.370000004768),
		Grip = KNIFE_GRIP,
		BackCFrame = CFrame.new(
			0, 0, 0,
			-0.0395700186491, -0.000499858986586, -0.999216794968,
			0.017680009827, 0.99984306097, -0.00120031903498,
			0.999060451984, -0.0177136547863, -0.0395549722016
		),
	},

	["Chroma Gemstone"] = {
		Icon = "rbxassetid://3183657875",
		MeshId = "rbxassetid://1626714161",
		TextureId = "rbxassetid://3183577898",
		Size = Vector3.new(0.40000000596, 3, 0.699999988079),
		Scale = Vector3.new(25, 25, 25),
		Grip = KNIFE_GRIP,
		BackCFrame = CFrame.new(),
	},

	["Chroma Gingerblade"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=2672351679",
		MeshId = "rbxassetid://2682453204",
		TextureId = "rbxassetid://2672327402",
		Size = Vector3.new(0.25, 3, 0.5),
		Scale = Vector3.new(0.610000014305, 0.610000014305, 0.610000014305),
		Grip = KNIFE_GRIP,
		BackCFrame = CFrame.new(),
	},

	["Chroma Heart Wand"] = {
		Icon = "rbxassetid://83357695007777",
		MeshId = "rbxassetid://77738838473091",
		TextureId = "rbxassetid://78842905206144",
		Size = Vector3.new(0.804019987583, 2.28355002403, 3.46268010139),
		Scale = Vector3.new(0.078210003674, 0.078210003674, 0.078210003674),
		Grip = KNIFE_GRIP,
		BackCFrame = CFrame.new(),
	},

	["Chroma Heat"] = {
		Icon = "rbxassetid://3187444849",
		MeshId = "http://www.roblox.com/asset/?id=105333894",
		TextureId = "http://www.roblox.com/asset/?id=105334003",
		Size = Vector3.new(0.40000000596, 3, 0.699999988079),
		Scale = Vector3.new(0.330000013113, 0.330000013113, 0.330000013113),
		Grip = KNIFE_GRIP,
		BackCFrame = CFrame.new(),
	},

	["Chroma Ornament"] = {
		Icon = "rbxassetid://74528014775455",
		MeshId = "rbxassetid://116508096109443",
		TextureId = "rbxassetid://135843404105980",
		Size = Vector3.new(0.46873998642, 3.47608995438, 0.789160013199),
		Scale = Vector3.new(0.0732600018382, 0.0732600018382, 0.0732600018382),
		Grip = KNIFE_GRIP,
		BackCFrame = CFrame.new(),
	},

	["Chroma Saw"] = {
		Icon = "rbxassetid://3187398132",
		MeshId = "rbxassetid://168119698",
		TextureId = "rbxassetid://3171086347",
		Size = Vector3.new(0.25, 3.07999992371, 1),
		Scale = Vector3.new(0.5, 0.5, 0.550000011921),
		Grip = KNIFE_GRIP,
		BackCFrame = CFrame.new(),
	},

	["Chroma Seer"] = {
		Icon = "rbxassetid://3184140321",
		MeshId = "rbxassetid://156092238",
		TextureId = "rbxassetid://3184059718",
		Size = Vector3.new(0.40000000596, 3, 0.699999988079),
		Scale = Vector3.new(0.699999988079, 0.910000026226, 1),
		Grip = KNIFE_GRIP,
		BackCFrame = CFrame.new(),
	},

	["Winters Edge"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=1268708987",
		MeshId = "http://www.roblox.com/asset/?id=93108071",
		TextureId = "http://www.roblox.com/asset/?id=93112631",
		Size = Vector3.new(0.660000026226, 3, 0.379999995232),
		Scale = Vector3.new(0.449999988079, 0.449999988079, 0.449999988079),
		Grip = KNIFE_GRIP,
		BackCFrame = CFrame.new(
			-0.0510899983346, 0.0859400033951, -0.000509999983478,
			-0.0348299741745, -0.00183982844464, -0.999391555786,
			0.0347399748862, 0.9993917346, -0.00305055780336,
			0.998789310455, -0.0348250865936, -0.0347448736429
		),
	},
}

SkinChanger.KnifeSkins = KnifeSkins

local KnifeSkinOrder = {
	"Default",
	"Elderwood Scythe",
	"Hallowscythe",
	"Icebreaker",
	"Icewing",
	"Logchopper",
	"Nik's Scythe",
	"Swirly Axe",
	"Traveler's Axe",
	"Vampire's Axe",
	"Chroma Alienbeam",
	"Chroma Boneblade",
	"Chroma Candleflame",
	"Chroma Cookiecane",
	"Chroma Deathshard",
	"Chroma Elderwood",
	"Chroma Evergreen",
	"Chroma Fang",
	"Chroma Gemstone",
	"Chroma Gingerblade",
	"Chroma Heart Wand",
	"Chroma Heat",
	"Chroma Ornament",
	"Chroma Saw",
	"Chroma Seer",
	"Winters Edge",
}

--============================================================
-- NOTIFICATION
--============================================================

local function NotifySkinChanger(Message)
	pcall(function()
		UI.WindUI:Notify({
			Title = "Skin Changer",
			Content = tostring(Message or ""),
			Icon = "palette",
			Duration = 2.5,
		})
	end)
end

--============================================================
-- CURRENT TOOLS
--============================================================

local function GetGun()
	local Character = LocalPlayer.Character
	local BackpackGun = Backpack:FindFirstChild("Gun")
	if BackpackGun and BackpackGun:IsA("Tool") then
		return BackpackGun
	end
	local CharacterGun = Character and Character:FindFirstChild("Gun")
	if CharacterGun and CharacterGun:IsA("Tool") then
		return CharacterGun
	end
	return nil
end

local function GetKnife()
	local Character = LocalPlayer.Character
	local BackpackKnife = Backpack:FindFirstChild("Knife")
	if BackpackKnife and BackpackKnife:IsA("Tool") then
		return BackpackKnife
	end
	local CharacterKnife = Character and Character:FindFirstChild("Knife")
	if CharacterKnife and CharacterKnife:IsA("Tool") then
		return CharacterKnife
	end
	return nil
end

--============================================================
-- SAVE ORIGINAL TOOLS
--============================================================

local function SaveOriginalGun(Gun)
	if not Gun or SavedGunState[Gun] then
		return false
	end

	local Handle = Gun:FindFirstChild("Handle")
	if not Handle or not Handle:IsA("BasePart") then
		return false
	end

	local Mesh = Handle:FindFirstChildOfClass("SpecialMesh")
	if not Mesh then
		return false
	end

	SavedGunState[Gun] = {
		TextureId = Gun.TextureId,
		Grip = Gun.Grip,
		HandleSize = Handle.Size,
		MeshType = Mesh.MeshType,
		MeshId = Mesh.MeshId,
		MeshTextureId = Mesh.TextureId,
		MeshScale = Mesh.Scale,
		MeshOffset = Mesh.Offset,
	}

	return true
end

local function SaveOriginalKnife(Knife)
	if not Knife or SavedKnifeState[Knife] then
		return false
	end

	local Handle = Knife:FindFirstChild("Handle")
	if not Handle or not Handle:IsA("BasePart") then
		return false
	end

	local Mesh = Handle:FindFirstChildOfClass("SpecialMesh")
	if not Mesh then
		return false
	end

	SavedKnifeState[Knife] = {
		TextureId = Knife.TextureId,
		Grip = Knife.Grip,
		HandleSize = Handle.Size,
		MeshType = Mesh.MeshType,
		MeshId = Mesh.MeshId,
		MeshTextureId = Mesh.TextureId,
		MeshScale = Mesh.Scale,
		MeshOffset = Mesh.Offset,
	}

	return true
end

--============================================================
-- VISIBLE MM2 HOTBAR
--============================================================

local function GetVisibleToolIcon()
	local BackpackUI = PlayerGui:FindFirstChild("BackpackUI")
	if not BackpackUI then
		return nil
	end

	local BackpackFrame = BackpackUI:FindFirstChild("BackpackFrame")
	if not BackpackFrame then
		return nil
	end

	local BackpackItem = BackpackFrame:FindFirstChild("BackpackItem")
	if not BackpackItem then
		return nil
	end

	local Container = BackpackItem:FindFirstChild("Container")
	if not Container then
		return nil
	end

	local ToolIcon = Container:FindFirstChild("ToolIcon")
	if ToolIcon
		and (
			ToolIcon:IsA("ImageLabel")
			or ToolIcon:IsA("ImageButton")
		)
	then
		return ToolIcon
	end

	return nil
end

local function SetVisibleHotbarIcon(Image)
	local ToolIcon = GetVisibleToolIcon()
	if not ToolIcon then
		return false
	end

	return pcall(function()
		ToolIcon.Image = tostring(Image or "")
	end)
end

--============================================================
-- LOCAL GUN DISPLAY
--============================================================

local function GetGunBelt()
	local Character = LocalPlayer.Character
	if not Character then
		return nil
	end

	local LowerTorso = Character:FindFirstChild("LowerTorso")
	if not LowerTorso then
		return nil
	end

	return LowerTorso:FindFirstChild("GunBelt")
end

local function IsLocalGunDisplay(Display)
	if not Display or not Display:IsA("BasePart") then
		return false
	end

	local GunBelt = GetGunBelt()
	if not GunBelt then
		return false
	end

	for _,Descendant in ipairs(Display:GetDescendants()) do
		if Descendant:IsA("RigidConstraint") then
			if Descendant.Attachment0 == GunBelt
				or Descendant.Attachment1 == GunBelt
			then
				return true
			end
		end
	end

	return false
end

local function FindLocalGunDisplay()
	local WeaponDisplays = Workspace:FindFirstChild("WeaponDisplays")
	if not WeaponDisplays then
		return nil
	end

	for _,Child in ipairs(WeaponDisplays:GetChildren()) do
		if Child.Name == "GunDisplay"
			and Child:IsA("BasePart")
			and IsLocalGunDisplay(Child)
		then
			return Child
		end
	end

	return nil
end

--============================================================
-- LOCAL KNIFE DISPLAY
--============================================================

local function GetKnifeBack()
	local Character = LocalPlayer.Character
	if not Character then
		return nil
	end

	local UpperTorso = Character:FindFirstChild("UpperTorso")
	if not UpperTorso then
		return nil
	end

	return UpperTorso:FindFirstChild("KnifeBack")
end

local function FindLocalKnifeDisplay()
	local WeaponDisplays = Workspace:FindFirstChild("WeaponDisplays")
	if not WeaponDisplays then
		return nil
	end

	local KnifeBack = GetKnifeBack()
	if not KnifeBack then
		return nil
	end

	for _,Display in ipairs(WeaponDisplays:GetChildren()) do
		if Display.Name == "KnifeDisplay"
			and Display:IsA("BasePart")
		then
			for _,Descendant in ipairs(Display:GetDescendants()) do
				if Descendant:IsA("RigidConstraint")
					and (
						Descendant.Attachment0 == KnifeBack
						or Descendant.Attachment1 == KnifeBack
					)
				then
					return Display
				end
			end
		end
	end

	return nil
end

--============================================================
-- SAVE ORIGINAL DISPLAYS
--============================================================

local function SaveOriginalHolster(Display)
	if not Display or SavedHolsterState[Display] then
		return false
	end

	local Mesh = Display:FindFirstChildOfClass("SpecialMesh")
	local Attachment = Display:FindFirstChildOfClass("Attachment")

	SavedHolsterState[Display] = {
		Size = Display.Size,
		Transparency = Display.Transparency,
		Massless = Display.Massless,
		CanCollide = Display.CanCollide,
		MeshType = Mesh and Mesh.MeshType,
		MeshId = Mesh and Mesh.MeshId,
		TextureId = Mesh and Mesh.TextureId,
		Scale = Mesh and Mesh.Scale,
		Offset = Mesh and Mesh.Offset,
		AttachmentCFrame = Attachment and Attachment.CFrame,
	}

	return true
end

local function SaveOriginalKnifeBack(Display)
	if not Display or SavedKnifeBackState[Display] then
		return false
	end

	local Mesh = Display:FindFirstChildOfClass("SpecialMesh")
	local Attachment = Display:FindFirstChildOfClass("Attachment")

	SavedKnifeBackState[Display] = {
		Size = Display.Size,
		Transparency = Display.Transparency,
		Massless = Display.Massless,
		CanCollide = Display.CanCollide,
		MeshType = Mesh and Mesh.MeshType,
		MeshId = Mesh and Mesh.MeshId,
		TextureId = Mesh and Mesh.TextureId,
		Scale = Mesh and Mesh.Scale,
		Offset = Mesh and Mesh.Offset,
		AttachmentCFrame = Attachment and Attachment.CFrame,
	}

	return true
end

--============================================================
-- APPLY TOOL SKINS
--============================================================

local function ApplyGunSkinToTool(Gun, Skin)
	if not Gun
		or not Skin
		or not Gun:IsA("Tool")
		or Gun.Name ~= "Gun"
	then
		return false
	end

	local Handle = Gun:FindFirstChild("Handle")
	if not Handle or not Handle:IsA("BasePart") then
		return false
	end

	local Mesh = Handle:FindFirstChildOfClass("SpecialMesh")
	if not Mesh then
		return false
	end

	SaveOriginalGun(Gun)

	local Success = pcall(function()
		Gun.TextureId = Skin.Icon
		Gun.Grip = Skin.Grip
		Handle.Size = Skin.Size
		Mesh.MeshType = Enum.MeshType.FileMesh
		Mesh.MeshId = Skin.MeshId
		Mesh.TextureId = Skin.TextureId
		Mesh.Scale = Skin.Scale
		Mesh.Offset = Vector3.new(0, 0, 0)
	end)

	if Success then
		SetVisibleHotbarIcon(Skin.Icon)
	end

	return Success
end

local function ApplyKnifeSkinToTool(Knife, Skin)
	if not Knife
		or not Skin
		or not Knife:IsA("Tool")
		or Knife.Name ~= "Knife"
	then
		return false
	end

	local Handle = Knife:FindFirstChild("Handle")
	if not Handle or not Handle:IsA("BasePart") then
		return false
	end

	local Mesh = Handle:FindFirstChildOfClass("SpecialMesh")
	if not Mesh then
		return false
	end

	SaveOriginalKnife(Knife)

	local Success = pcall(function()
		Knife.TextureId = Skin.Icon
		Knife.Grip = Skin.Grip
		Handle.Size = Skin.Size
		Mesh.MeshType = Enum.MeshType.FileMesh
		Mesh.MeshId = Skin.MeshId
		Mesh.TextureId = Skin.TextureId
		Mesh.Scale = Skin.Scale
		Mesh.Offset = Vector3.new(0, 0, 0)
	end)

	if Success then
		SetVisibleHotbarIcon(Skin.Icon)
	end

	return Success
end

--============================================================
-- APPLY DISPLAY SKINS
--============================================================

local function ApplyGunSkinToHolster(Skin)
	if not Skin then
		return false
	end

	local Display = FindLocalGunDisplay()
	if not Display then
		return false
	end

	SaveOriginalHolster(Display)

	local Mesh = Display:FindFirstChildOfClass("SpecialMesh")
	local Attachment = Display:FindFirstChildOfClass("Attachment")

	return pcall(function()
		Display.Size = Skin.Size
		Display.Transparency = 0
		Display.Massless = true
		Display.CanCollide = false

		if Mesh then
			Mesh.MeshType = Enum.MeshType.FileMesh
			Mesh.MeshId = Skin.MeshId
			Mesh.TextureId = Skin.TextureId
			Mesh.Scale = Skin.Scale
			Mesh.Offset = Vector3.new(0, 0, 0)
		end

		if Attachment and Skin.HolsterCFrame then
			Attachment.CFrame = Skin.HolsterCFrame
		end
	end)
end

local function ApplyKnifeSkinToBack(Skin)
	if not Skin then
		return false
	end

	local Display = FindLocalKnifeDisplay()
	if not Display then
		return false
	end

	SaveOriginalKnifeBack(Display)

	local Mesh = Display:FindFirstChildOfClass("SpecialMesh")
	local Attachment = Display:FindFirstChildOfClass("Attachment")

	return pcall(function()
		Display.Size = Skin.Size
		Display.Transparency = 0
		Display.Massless = true
		Display.CanCollide = false

		if Mesh then
			Mesh.MeshType = Enum.MeshType.FileMesh
			Mesh.MeshId = Skin.MeshId
			Mesh.TextureId = Skin.TextureId
			Mesh.Scale = Skin.Scale
			Mesh.Offset = Vector3.new(0, 0, 0)
		end

		if Attachment and Skin.BackCFrame then
			Attachment.CFrame = Skin.BackCFrame
		end
	end)
end

--============================================================
-- RESTORE TOOLS
--============================================================

local function RestoreGun(Gun)
	if not Gun then
		return false
	end

	local Original = SavedGunState[Gun]
	if not Original then
		return false
	end

	local Handle = Gun:FindFirstChild("Handle")
	if not Handle then
		return false
	end

	local Mesh = Handle:FindFirstChildOfClass("SpecialMesh")
	if not Mesh then
		return false
	end

	local Success = pcall(function()
		Gun.TextureId = Original.TextureId
		Gun.Grip = Original.Grip
		Handle.Size = Original.HandleSize
		Mesh.MeshType = Original.MeshType
		Mesh.MeshId = Original.MeshId
		Mesh.TextureId = Original.MeshTextureId
		Mesh.Scale = Original.MeshScale
		Mesh.Offset = Original.MeshOffset
	end)

	if Success then
		SetVisibleHotbarIcon(Original.TextureId)
	end

	return Success
end

local function RestoreKnife(Knife)
	if not Knife then
		return false
	end

	local Original = SavedKnifeState[Knife]
	if not Original then
		return false
	end

	local Handle = Knife:FindFirstChild("Handle")
	if not Handle then
		return false
	end

	local Mesh = Handle:FindFirstChildOfClass("SpecialMesh")
	if not Mesh then
		return false
	end

	local Success = pcall(function()
		Knife.TextureId = Original.TextureId
		Knife.Grip = Original.Grip
		Handle.Size = Original.HandleSize
		Mesh.MeshType = Original.MeshType
		Mesh.MeshId = Original.MeshId
		Mesh.TextureId = Original.MeshTextureId
		Mesh.Scale = Original.MeshScale
		Mesh.Offset = Original.MeshOffset
	end)

	if Success then
		SetVisibleHotbarIcon(Original.TextureId)
	end

	return Success
end

--============================================================
-- RESTORE DISPLAYS
--============================================================

local function RestoreHolster()
	local Display = FindLocalGunDisplay()
	if not Display then
		return false
	end

	local Original = SavedHolsterState[Display]
	if not Original then
		return false
	end

	local Mesh = Display:FindFirstChildOfClass("SpecialMesh")
	local Attachment = Display:FindFirstChildOfClass("Attachment")

	return pcall(function()
		Display.Size = Original.Size
		Display.Transparency = Original.Transparency
		Display.Massless = Original.Massless
		Display.CanCollide = Original.CanCollide

		if Mesh then
			if Original.MeshType then
				Mesh.MeshType = Original.MeshType
			end
			Mesh.MeshId = Original.MeshId or ""
			Mesh.TextureId = Original.TextureId or ""
			Mesh.Scale = Original.Scale or Vector3.new(1, 1, 1)
			Mesh.Offset = Original.Offset or Vector3.new(0, 0, 0)
		end

		if Attachment and Original.AttachmentCFrame then
			Attachment.CFrame = Original.AttachmentCFrame
		end
	end)
end

local function RestoreKnifeBack()
	local Display = FindLocalKnifeDisplay()
	if not Display then
		return false
	end

	local Original = SavedKnifeBackState[Display]
	if not Original then
		return false
	end

	local Mesh = Display:FindFirstChildOfClass("SpecialMesh")
	local Attachment = Display:FindFirstChildOfClass("Attachment")

	return pcall(function()
		Display.Size = Original.Size
		Display.Transparency = Original.Transparency
		Display.Massless = Original.Massless
		Display.CanCollide = Original.CanCollide

		if Mesh then
			if Original.MeshType then
				Mesh.MeshType = Original.MeshType
			end
			Mesh.MeshId = Original.MeshId or ""
			Mesh.TextureId = Original.TextureId or ""
			Mesh.Scale = Original.Scale or Vector3.new(1, 1, 1)
			Mesh.Offset = Original.Offset or Vector3.new(0, 0, 0)
		end

		if Attachment and Original.AttachmentCFrame then
			Attachment.CFrame = Original.AttachmentCFrame
		end
	end)
end

--============================================================
-- APPLY CURRENT SELECTIONS
--============================================================

local function ApplyCurrentGunSkin()
	local Selected = SkinChanger.SelectedGun
	local Gun = GetGun()

	if Selected == "Default" then
		if Gun then
			RestoreGun(Gun)
		end
		RestoreHolster()
		return
	end

	local Skin = GunSkins[Selected]
	if not Skin then
		return
	end

	if Gun then
		CurrentGun = Gun
		ApplyGunSkinToTool(Gun, Skin)
	end

	ApplyGunSkinToHolster(Skin)
end

local function ApplyCurrentKnifeSkin()
	local Selected = SkinChanger.SelectedKnife
	local Knife = GetKnife()

	if Selected == "Default" then
		if Knife then
			RestoreKnife(Knife)
		end
		RestoreKnifeBack()
		return
	end

	local Skin = KnifeSkins[Selected]
	if not Skin then
		return
	end

	if Knife then
		CurrentKnife = Knife
		ApplyKnifeSkinToTool(Knife, Skin)
	end

	ApplyKnifeSkinToBack(Skin)
end

SkinChanger.ApplyCurrentGunSkin = ApplyCurrentGunSkin
SkinChanger.ApplyCurrentKnifeSkin = ApplyCurrentKnifeSkin

--============================================================
-- MANUAL SELECTION
--============================================================

local function SelectGunSkin(Value, ShowNotification)
	if type(Value) ~= "string" then
		return
	end

	if Value ~= "Default" and not GunSkins[Value] then
		return
	end

	local Changed = Value ~= SkinChanger.SelectedGun
	SkinChanger.SelectedGun = Value

	ApplyCurrentGunSkin()

	if not ShowNotification or not Changed then
		return
	end

	if Value == "Default" then
		NotifySkinChanger("Default Gun Equipped")
	else
		NotifySkinChanger(Value .. " Equipped")
	end
end

local function SelectKnifeSkin(Value, ShowNotification)
	if type(Value) ~= "string" then
		return
	end

	if Value ~= "Default" and not KnifeSkins[Value] then
		return
	end

	local Changed = Value ~= SkinChanger.SelectedKnife
	SkinChanger.SelectedKnife = Value

	ApplyCurrentKnifeSkin()

	if not ShowNotification or not Changed then
		return
	end

	if Value == "Default" then
		NotifySkinChanger("Default Knife Equipped")
	else
		NotifySkinChanger(Value .. " Equipped")
	end
end

SkinChanger.SelectGunSkin = SelectGunSkin
SkinChanger.SelectKnifeSkin = SelectKnifeSkin

--============================================================
-- WINDUI
--============================================================

print("[SkinChanger] Creating UI...")

local GunSection =
	UI.AddSection(
		UI.SkinChangerPage,
		"Gun",
		"Change the appearance of your gun"
	)

if not GunSection then
	warn("[SkinChanger] Failed to create Gun section")
end

local GunDropdown =
	UI.CreateDropdown(
		UI.SkinChangerPage,
		"Gun Skin",
		"Select a gun skin",
		GunSkinOrder,
		SkinChanger.SelectedGun,
		function(Value)
			SelectGunSkin(Value, true)
		end
	)

if not GunDropdown then
	warn("[SkinChanger] Failed to create Gun dropdown")
end

local KnifeSection =
	UI.AddSection(
		UI.SkinChangerPage,
		"Knife",
		"Change the appearance of your knife"
	)

if not KnifeSection then
	warn("[SkinChanger] Failed to create Knife section")
end

local KnifeDropdown =
	UI.CreateDropdown(
		UI.SkinChangerPage,
		"Knife Skin",
		"Select a knife skin",
		KnifeSkinOrder,
		SkinChanger.SelectedKnife,
		function(Value)
			SelectKnifeSkin(Value, true)
		end
	)

if not KnifeDropdown then
	warn("[SkinChanger] Failed to create Knife dropdown")
end

print("[SkinChanger] UI created successfully")

--============================================================
-- TOOL WATCHING
--============================================================

local function WatchGun(Gun)
	if not Gun
		or not Gun:IsA("Tool")
		or Gun.Name ~= "Gun"
	then
		return
	end

	if CurrentGun == Gun then
		return
	end

	CurrentGun = Gun

	task.defer(function()
		task.wait(0.15)
		if Gun.Parent then
			ApplyCurrentGunSkin()
		end
	end)

	Track(
		Gun.AncestryChanged:
		Connect(function()
			task.defer(function()
				task.wait(0.05)

				if not Gun.Parent then
					return
				end

				if Gun.Parent == Backpack
					or Gun.Parent == LocalPlayer.Character
				then
					ApplyCurrentGunSkin()
				end
			end)
		end)
	)
end

local function WatchKnife(Knife)
	if not Knife
		or not Knife:IsA("Tool")
		or Knife.Name ~= "Knife"
	then
		return
	end

	if CurrentKnife == Knife then
		return
	end

	CurrentKnife = Knife

	task.defer(function()
		task.wait(0.15)
		if Knife.Parent then
			ApplyCurrentKnifeSkin()
		end
	end)

	Track(
		Knife.AncestryChanged:
		Connect(function()
			task.defer(function()
				task.wait(0.05)

				if not Knife.Parent then
					return
				end

				if Knife.Parent == Backpack
					or Knife.Parent == LocalPlayer.Character
				then
					ApplyCurrentKnifeSkin()
				end
			end)
		end)
	)
end

local function CheckChild(Child)
	if not Child or not Child:IsA("Tool") then
		return
	end

	if Child.Name == "Gun" then
		WatchGun(Child)
	elseif Child.Name == "Knife" then
		WatchKnife(Child)
	end
end

--============================================================
-- CHARACTER WATCHING
--============================================================

local function HookCharacter(Character)
	if not Character then
		return
	end

	Track(
		Character.ChildAdded:
		Connect(function(Child)
			CheckChild(Child)
		end)
	)

	local Gun = Character:FindFirstChild("Gun")
	if Gun then
		WatchGun(Gun)
	end

	local Knife = Character:FindFirstChild("Knife")
	if Knife then
		WatchKnife(Knife)
	end
end

--============================================================
-- WEAPON DISPLAY WATCHING
--============================================================

local HookedWeaponDisplays =
	setmetatable({}, {__mode = "k"})

local function HookWeaponDisplays(WeaponDisplays)
	if not WeaponDisplays
		or HookedWeaponDisplays[WeaponDisplays]
	then
		return
	end

	HookedWeaponDisplays[WeaponDisplays] = true

	Track(
		WeaponDisplays.DescendantAdded:
		Connect(function()
			task.defer(function()
				task.wait(0.10)

				if SkinChanger.SelectedGun ~= "Default" then
					ApplyCurrentGunSkin()
				end

				if SkinChanger.SelectedKnife ~= "Default" then
					ApplyCurrentKnifeSkin()
				end
			end)
		end)
	)
end

--============================================================
-- START WATCHERS
--============================================================

local WatcherOK, WatcherError =
	pcall(function()

		Track(
			Backpack.ChildAdded:
			Connect(function(Child)
				CheckChild(Child)
			end)
		)

		if LocalPlayer.Character then
			HookCharacter(LocalPlayer.Character)
		end

		Track(
			LocalPlayer.CharacterAdded:
			Connect(function(Character)

				CurrentGun = nil
				CurrentKnife = nil

				HookCharacter(Character)

				task.defer(function()
					task.wait(0.5)
					ApplyCurrentGunSkin()
					ApplyCurrentKnifeSkin()
				end)
			end)
		)

		Track(
			PlayerGui.DescendantAdded:
			Connect(function(Descendant)

				if Descendant.Name ~= "ToolIcon" then
					return
				end

				if not (
					Descendant:IsA("ImageLabel")
					or Descendant:IsA("ImageButton")
				)
				then
					return
				end

				task.defer(function()
					task.wait(0.05)

					local Knife = GetKnife()
					local Gun = GetGun()

					if Knife and SkinChanger.SelectedKnife ~= "Default" then
						ApplyCurrentKnifeSkin()
					elseif Gun and SkinChanger.SelectedGun ~= "Default" then
						ApplyCurrentGunSkin()
					end
				end)
			end)
		)

		local WeaponDisplays =
			Workspace:FindFirstChild("WeaponDisplays")

		if WeaponDisplays then
			HookWeaponDisplays(WeaponDisplays)
		end

		Track(
			Workspace.ChildAdded:
			Connect(function(Child)

				if Child.Name ~= "WeaponDisplays" then
					return
				end

				HookWeaponDisplays(Child)

				task.defer(function()
					task.wait(0.25)
					ApplyCurrentGunSkin()
					ApplyCurrentKnifeSkin()
				end)
			end)
		)
	end)

if not WatcherOK then
	warn(
		"[SkinChanger] Watcher setup failed:",
		WatcherError
	)
else
	print("[SkinChanger] Watchers started")
end

--============================================================
-- LIGHT PERSISTENCE LOOP
--============================================================

task.spawn(function()

	while MM2.Running do

		task.wait(0.25)

		local Gun = GetGun()
		local Knife = GetKnife()

		if Gun and Gun ~= CurrentGun then
			WatchGun(Gun)
		end

		if Knife and Knife ~= CurrentKnife then
			WatchKnife(Knife)
		end

		if SkinChanger.SelectedGun ~= "Default" then
			pcall(ApplyCurrentGunSkin)
		end

		if SkinChanger.SelectedKnife ~= "Default" then
			pcall(ApplyCurrentKnifeSkin)
		end
	end
end)

--============================================================
-- EXISTING TOOLS
--============================================================

local ExistingGun = GetGun()

if ExistingGun then
	task.defer(function()
		task.wait(0.25)
		WatchGun(ExistingGun)
		ApplyCurrentGunSkin()
	end)
end

local ExistingKnife = GetKnife()

if ExistingKnife then
	task.defer(function()
		task.wait(0.25)
		WatchKnife(ExistingKnife)
		ApplyCurrentKnifeSkin()
	end)
end

print("[Blizzard MM2] SkinChanger.lua loaded")

return MM2
