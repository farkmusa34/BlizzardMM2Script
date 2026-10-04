--============================================================
-- Blizzard MM2 V8.8.4 - KnifeSkin.lua
--
-- Full knife-side module split from the working SkinChanger.lua.
-- 69 captured knife skins mapped in screenshot order:
-- Batwing -> Heart Wand.
--
-- Existing verified knife entries keep their original BackCFrame.
-- New diagnostic-only entries do NOT invent a BackCFrame.
--============================================================

local MM2 =
	getgenv
	and getgenv().MM2_V85_SPLIT
	or _G.MM2_V85_SPLIT

assert(
	MM2
	and MM2.UI
	and MM2.UI.SkinChangerPage
	and MM2.UI.SkinChangerKnifePage,
	"Load Shared.lua + UI.lua first"
)

print("[KnifeSkin] Starting...")

local S = MM2.Services
local UI = MM2.UI
local Track = MM2.Track

local Players =
	S.Players
	or game:GetService("Players")

local Workspace =
	game:GetService("Workspace")

local RunService =
	game:GetService("RunService")

local LocalPlayer =
	MM2.LocalPlayer
	or Players.LocalPlayer

local Backpack =
	LocalPlayer:WaitForChild("Backpack")

local PlayerGui =
	LocalPlayer:WaitForChild("PlayerGui")

MM2.SkinChanger =
	MM2.SkinChanger
	or {}

local SkinChanger =
	MM2.SkinChanger

SkinChanger.SelectedKnife =
	SkinChanger.SelectedKnife
	or "Default"

SkinChanger.HeldPosition =
	SkinChanger.HeldPosition
	or {}

SkinChanger.HeldPosition.Knife =
	SkinChanger.HeldPosition.Knife
	or {
		X = 0,
		Y = 0,
		Z = 0,
	}

SkinChanger.HeldPosition.Knife.X = tonumber(SkinChanger.HeldPosition.Knife.X) or 0
SkinChanger.HeldPosition.Knife.Y = tonumber(SkinChanger.HeldPosition.Knife.Y) or 0
SkinChanger.HeldPosition.Knife.Z = tonumber(SkinChanger.HeldPosition.Knife.Z) or 0

local CurrentKnife = nil

local SavedKnifeState =
	setmetatable({}, {__mode = "k"})

local SavedKnifeBackState =
	setmetatable({}, {__mode = "k"})

local HELD_POSITION_MIN = -0.525
local HELD_POSITION_MAX = 0.525
local HELD_POSITION_STEP = 0.01

local function GetHeldPosition()
	local Data = SkinChanger.HeldPosition.Knife
	Data.X = tonumber(Data.X) or 0
	Data.Y = tonumber(Data.Y) or 0
	Data.Z = tonumber(Data.Z) or 0
	return Data
end

local function GetHeldOffsetGrip(BaseGrip)
	if typeof(BaseGrip) ~= "CFrame" then
		return BaseGrip
	end

	local Data = GetHeldPosition()

	local Position =
		BaseGrip.Position
		+ Vector3.new(
			tonumber(Data.X) or 0,
			tonumber(Data.Y) or 0,
			-(tonumber(Data.Z) or 0)
		)

	local RotationOnly =
		BaseGrip
		- BaseGrip.Position

	return
		CFrame.new(Position)
		* RotationOnly
end

local KNIFE_GRIP =
	CFrame.new(
		0,
		-1,
		-0.10000000149,
		1, 0, 0,
		0, 1, 0,
		0, 0, 1
	)

--============================================================
-- KNIFE SKIN DATA
--============================================================

local KnifeSkins = {
	["Batwing"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=375690925",
		MeshId = "http://www.roblox.com/asset/?id=305826272",
		TextureId = "rbxassetid://2511673515",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(1.0000, 1.0000, 1.0000),
		Grip = KNIFE_GRIP,
	},

	["Celestial"] = {
		Icon = "rbxthumb://type=Asset&w=150&h=150&id=136673966529736",
		MeshId = "rbxassetid://109711282082830",
		TextureId = "rbxassetid://79010754957272",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(0.0533, 0.0533, 0.0533),
		Grip = KNIFE_GRIP,
	},

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

	["Chroma Elderwood Blade"] = {
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

	["Chroma Ornament"] = {
		Material = Enum.Material.Plastic,
		Decals = {
			{Texture = "rbxassetid://101916509598198", Face = Enum.NormalId.Left, ZIndex = 1},
		},
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

	["Chroma Slasher"] = {
			Icon = "rbxassetid://3187398385",
			MeshId = "rbxassetid://283709822",
			TextureId = "rbxassetid://3171107559",
			Size = Vector3.new(0.40000000596, 3.1700000762939453, 0.699999988079071),
			Scale = Vector3.new(0.44999998807907104, 0.44999998807907104, 0.44999998807907104),
			Grip = KNIFE_GRIP,
			BackCFrame = CFrame.new(),
		},

	["Chroma Snow Dagger"] = {
			Icon = "rbxassetid://102260232089801",
			MeshId = "rbxassetid://140633396635861",
			TextureId = "rbxassetid://77812964601215",
			Size = Vector3.new(0.33125999569892883, 2.7512600421905518, 0.6569899916648865),
			Scale = Vector3.new(0.059780001640319824, 0.059780001640319824, 0.059780001640319824),
			Grip = KNIFE_GRIP,
			BackCFrame = CFrame.new(),
		},

	["Chroma Snowstorm"] = {
			Icon = "rbxassetid://74943438536351",
			MeshId = "rbxassetid://86944837615327",
			TextureId = "rbxassetid://86253759560362",
			Size = Vector3.new(0.25999999046325684, 3.8519999980926514, 0.9580000042915344),
			Scale = Vector3.new(0.07705000042915344, 0.07705000042915344, 0.07705000042915344),
			Grip = KNIFE_GRIP,
			BackCFrame = CFrame.new(),
		},

	["Chroma Sunset"] = {
			Icon = "rbxassetid://118232478609755",
			MeshId = "rbxassetid://137082284051764",
			TextureId = "rbxassetid://93782017269677",
			Size = Vector3.new(0.2759999930858612, 3.5309998989105225, 1.0410000085830688),
			Scale = Vector3.new(0.07000000029802322, 0.07000000029802322, 0.07000000029802322),
			Grip = KNIFE_GRIP,
			BackCFrame = CFrame.new(),
		},

	["Chroma Sweet"] = {
			Icon = "rbxassetid://107087165596219",
			MeshId = "rbxassetid://88250692342609",
			TextureId = "rbxassetid://120707737118924",
			Size = Vector3.new(0.710669994354248, 2.018399953842163, 3.060620069503784),
			Scale = Vector3.new(0.06913000345230103, 0.06913000345230103, 0.06913000345230103),
			Grip = KNIFE_GRIP,
			BackCFrame = CFrame.new(),
		},

	["Chroma Tides"] = {
			Icon = "rbxassetid://3187398906",
			MeshId = "rbxassetid://238314382",
			TextureId = "rbxassetid://3171168641",
			Size = Vector3.new(0.44999998807907104, 0.699999988079071, 3.049999952316284),
			Scale = Vector3.new(0.699999988079071, 0.8999999761581421, 0.699999988079071),
			Grip = CFrame.new(
				0,
				-1,
				-0.100000001,
				1, 0, 0,
				0, -4.37113883e-08, 1,
				0, -1, -4.37113883e-08
			),
			BackCFrame = CFrame.new(
				-0.0034000000450760126,
				0.12728999555110931,
				-0.21514999866485596,
				0.997990489,
				-0.0632634386,
				-0.0035702223,
				0.00363000156,
				0.000830019824,
				0.999993205,
				-0.0632600263,
				-0.997996628,
				0.00105799828
			),
		},

	["Alienbeam"] = {
		Icon = "rbxthumb://type=Asset&w=150&h=150&id=77607127867154",
		MeshId = "rbxassetid://86649405964534",
		TextureId = "rbxassetid://94763497877100",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(0.0758, 0.0758, 0.0758),
		Grip = KNIFE_GRIP,
	},

	["Australis"] = {
		Icon = "rbxthumb://type=Asset&w=150&h=150&id=101343256002049",
		MeshId = "rbxassetid://16025287191",
		TextureId = "rbxassetid://97521579968070",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(0.0753, 0.0753, 0.0753),
		Grip = KNIFE_GRIP,
	},

	["Bat"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=11229814357",
		MeshId = "rbxassetid://11182796403",
		TextureId = "rbxassetid://11192090515",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(0.0741, 0.0741, 0.0741),
		Grip = KNIFE_GRIP,
	},

	["BattleAxe"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=1133237368",
		MeshId = "rbxassetid://1084767698",
		TextureId = "rbxassetid://1084767901",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(0.5600, 0.5600, 0.5600),
		Grip = KNIFE_GRIP,
	},

	["BattleAxe II"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=2513535503",
		MeshId = "rbxassetid://2397016406",
		TextureId = "rbxassetid://2513526862",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(0.7357, 0.7357, 0.7357),
		Grip = KNIFE_GRIP,
	},

	["Bioblade"] = {
		Icon = "http://www.roblox.com/asset/?id=4751540097",
		MeshId = "rbxassetid://4662600017",
		TextureId = "http://www.roblox.com/asset/?id=4751538400",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(0.0624, 0.0684, 0.0660),
		Grip = KNIFE_GRIP,
	},

	["Bloom"] = {
		Icon = "rbxassetid://132419834610569",
		MeshId = "rbxassetid://73266355643345",
		TextureId = "rbxassetid://103489229144925",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(0.0740, 0.0740, 0.0740),
		Grip = KNIFE_GRIP,
	},

	["Blue Seer"] = {
		Icon = "rbxassetid://3184139996",
		MeshId = "http://www.roblox.com/asset?id=156092238",
		TextureId = "rbxassetid://3184062977",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(0.7000, 0.9100, 1.0000),
		Grip = KNIFE_GRIP,
	},

	["Boneblade"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=2513505477",
		MeshId = "rbxassetid://1857106669",
		TextureId = "rbxassetid://2516324337",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(0.7000, 0.7000, 0.7000),
		Grip = KNIFE_GRIP,
	},

	["Candleflame"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=7805833970",
		MeshId = "rbxassetid://7791364860",
		TextureId = "rbxassetid://7791364988",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(0.0667, 0.0668, 0.0668),
		Grip = KNIFE_GRIP,
	},

	["Candy"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=332021011",
		MeshId = "http://www.roblox.com/asset/?id=19040337",
		TextureId = "http://www.roblox.com/asset/?id=19040326",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(1.1000, 1.4000, 1.1000),
		Grip = KNIFE_GRIP,
	},

	["Chill"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=332022166",
		MeshId = "http://www.roblox.com/asset/?id=105329941",
		TextureId = "http://www.roblox.com/asset/?id=105978218",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(0.5000, 0.5000, 0.5000),
		Grip = KNIFE_GRIP,
	},

	["Clockwork"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=360609441",
		MeshId = "http://www.roblox.com/asset/?id=352571495",
		TextureId = "http://www.roblox.com/asset/?id=352570357",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(1.1000, 1.6000, 1.2000),
		Grip = KNIFE_GRIP,
	},

	["Cookieblade"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=6121574620",
		MeshId = "rbxassetid://6123168377",
		TextureId = "rbxassetid://6123168583",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(1.0000, 1.0000, 1.0000),
		Grip = KNIFE_GRIP,
	},

	["Cookiecane"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=11855306927",
		MeshId = "rbxassetid://6123168377",
		TextureId = "",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(1.0000, 1.0000, 1.0000),
		Grip = KNIFE_GRIP,
	},

	["Darksword"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=15080267070",
		MeshId = "rbxassetid://15020899066",
		TextureId = "rbxassetid://15020899218",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(0.0800, 0.0800, 0.0800),
		Grip = KNIFE_GRIP,
	},

	["Deathshard"] = {
		Icon = "rbxassetid://3175017717",
		MeshId = "http://www.roblox.com/asset/?id=62275962",
		TextureId = "http://www.roblox.com/asset/?id=192567360",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(0.7500, 0.7500, 0.7500),
		Grip = KNIFE_GRIP,
	},

	["Eggblade"] = {
		Icon = "http://www.roblox.com/asset/?id=6607512359",
		MeshId = "rbxassetid://6596834762",
		TextureId = "http://www.roblox.com/asset/?id=6596824396",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(0.0686, 0.0686, 0.0686),
		Grip = KNIFE_GRIP,
	},

	["Elderwood Blade"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=11254879631",
		MeshId = "rbxassetid://11238166013",
		TextureId = "rbxassetid://11238176757",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(0.0700, 0.0700, 0.0700),
		Grip = KNIFE_GRIP,
	},

	["Eternal"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=538706317",
		MeshId = "rbxassetid://532155954",
		TextureId = "rbxassetid://532156041",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(0.4500, 0.4500, 0.4500),
		Grip = KNIFE_GRIP,
	},

	["Eternal II"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=2545253030",
		MeshId = "rbxassetid://532155954",
		TextureId = "rbxassetid://2585776718",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(0.4500, 0.4500, 0.4500),
		Grip = KNIFE_GRIP,
	},

	["Eternal III"] = {
		Icon = "rbxassetid://3281170430",
		MeshId = "rbxassetid://532155954",
		TextureId = "rbxassetid://5238664918",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(0.4700, 0.4700, 0.4700),
		Grip = KNIFE_GRIP,
	},

	["Eternal IV"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=4999958740",
		MeshId = "rbxassetid://532155954",
		TextureId = "rbxassetid://5222717744",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(0.4700, 0.4700, 0.4700),
		Grip = KNIFE_GRIP,
	},

	["Eternalcane"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=4488391411",
		MeshId = "rbxassetid://3132923779",
		TextureId = "rbxassetid://4488374804",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(0.9500, 0.9500, 0.9500),
		Grip = KNIFE_GRIP,
	},

	["Evergreen"] = {
		Icon = "rbxassetid://15694357137",
		MeshId = "rbxassetid://15408280573",
		TextureId = "rbxassetid://15408244684",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(0.0046, 0.0046, 0.0046),
		Grip = KNIFE_GRIP,
	},

	["Fang"] = {
		Icon = "rbxassetid://3187397768",
		MeshId = "http://www.roblox.com/asset/?id=117500241",
		TextureId = "http://www.roblox.com/asset/?id=117500388",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(0.4000, 0.4000, 0.4000),
		Grip = KNIFE_GRIP,
	},

	["Flames"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=585873746",
		MeshId = "http://www.roblox.com/asset/?id=238314098",
		TextureId = "http://www.roblox.com/asset/?id=238314124",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(0.6000, 0.8000, 0.7300),
		Grip = KNIFE_GRIP,
	},

	["Flowerwood"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=16963860501",
		MeshId = "rbxassetid://16883629972",
		TextureId = "rbxassetid://16895441338",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(0.0792, 0.0792, 0.0792),
		Grip = KNIFE_GRIP,
	},

	["Frostbite"] = {
		Icon = "http://www.roblox.com/asset/?id=4528373246",
		MeshId = "http://www.roblox.com/asset?id=4528435571",
		TextureId = "rbxassetid://5211130051",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(1.1000, 1.1000, 1.1000),
		Grip = KNIFE_GRIP,
	},

	["Frostsaber"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=1268934541",
		MeshId = "rbxassetid://1192795322",
		TextureId = "rbxassetid://1192795941",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(0.5500, 0.5500, 0.6000),
		Grip = KNIFE_GRIP,
	},

	["Gemstone"] = {
		Icon = "rbxassetid://3183657748",
		MeshId = "rbxassetid://1626714161",
		TextureId = "rbxassetid://3183579677",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(25.0000, 25.0000, 25.0000),
		Grip = KNIFE_GRIP,
	},

	["Ghostblade"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=4217586790",
		MeshId = "rbxassetid://4217554208",
		TextureId = "rbxassetid://5007736173",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(0.0500, 0.0500, 0.0500),
		Grip = KNIFE_GRIP,
	},

	["Gingerblade"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=2669336659",
		MeshId = "rbxassetid://2682453204",
		TextureId = "rbxassetid://2682446647",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(0.6100, 0.6100, 0.6100),
		Grip = KNIFE_GRIP,
	},

	["Hallow's Blade"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=1132775323",
		MeshId = "http://www.roblox.com/asset?id=179155055",
		TextureId = "rbxassetid://1132750758",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(0.5500, 0.5500, 0.5550),
		Grip = KNIFE_GRIP,
	},

	["Hallow's Edge"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=531878205",
		MeshId = "http://www.roblox.com/asset?id=179155055",
		TextureId = "http://www.roblox.com/asset?id=179155105",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(0.5700, 0.5700, 0.5700),
		Grip = KNIFE_GRIP,
	},

	["Handsaw"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=332042435",
		MeshId = "http://www.roblox.com/asset?id=179155055",
		TextureId = "",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(0.5700, 0.5700, 0.5700),
		Grip = KNIFE_GRIP,
	},

	["Heart Wand"] = {
		Icon = "rbxthumb://type=Asset&w=150&h=150&id=118334707962654",
		MeshId = "rbxassetid://77738838473091",
		TextureId = "rbxassetid://76246633927299",
		Size = Vector3.new(0.4000000059604645, 3, 0.699999988079071),
		Scale = Vector3.new(0.0782, 0.0782, 0.0782),
		Grip = KNIFE_GRIP,
	},
}

SkinChanger.KnifeSkins = KnifeSkins

local KnifeSkinOrder = {
	"Batwing",
	"Celestial",
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
	"Chroma Elderwood Blade",
	"Chroma Evergreen",
	"Chroma Fang",
	"Chroma Gemstone",
	"Chroma Gingerblade",
	"Chroma Heart Wand",
	"Chroma Heat",
	"Chroma Ornament",
	"Chroma Saw",
	"Chroma Seer",
	"Chroma Slasher",
	"Chroma Snow Dagger",
	"Chroma Snowstorm",
	"Chroma Sunset",
	"Chroma Sweet",
	"Chroma Tides",
	"Alienbeam",
	"Australis",
	"Bat",
	"BattleAxe",
	"BattleAxe II",
	"Bioblade",
	"Bloom",
	"Blue Seer",
	"Boneblade",
	"Candleflame",
	"Candy",
	"Chill",
	"Clockwork",
	"Cookieblade",
	"Cookiecane",
	"Darksword",
	"Deathshard",
	"Eggblade",
	"Elderwood Blade",
	"Eternal",
	"Eternal II",
	"Eternal III",
	"Eternal IV",
	"Eternalcane",
	"Evergreen",
	"Fang",
	"Flames",
	"Flowerwood",
	"Frostbite",
	"Frostsaber",
	"Gemstone",
	"Ghostblade",
	"Gingerblade",
	"Hallow's Blade",
	"Hallow's Edge",
	"Handsaw",
	"Heart Wand",
}

SkinChanger.KnifeSkinOrder = KnifeSkinOrder

local ChromaKnifeData = {
	["Chroma Alienbeam"] = {
		Material = Enum.Material.Glass,
		Reflectance = 0,
		Decals = {
			{Texture = "rbxassetid://138018131999412", Face = Enum.NormalId.Left, ZIndex = 0},
		},
	},

	["Chroma Boneblade"] = {
		Material = Enum.Material.Plastic,
		Decals = {
			{Texture = "rbxassetid://2513578115", Face = Enum.NormalId.Front, ZIndex = 1},
		},
	},

	["Chroma Candleflame"] = {
		Material = Enum.Material.Plastic,
		Decals = {
			{Texture = "rbxassetid://7806088865", Face = Enum.NormalId.Front, ZIndex = 1},
		},
	},

	["Chroma Cookiecane"] = {
		Material = Enum.Material.Plastic,
		Decals = {
			{Texture = "rbxassetid://11883888650", Face = Enum.NormalId.Back, ZIndex = 1},
		},
	},

	["Chroma Deathshard"] = {
		Material = Enum.Material.Concrete,
		Decals = {
			{Texture = "rbxassetid://3167033529", Face = Enum.NormalId.Front, ZIndex = 1},
		},
	},

	["Chroma Elderwood Blade"] = {
		Material = Enum.Material.Plastic,
		Decals = {
			{Texture = "rbxassetid://11370095395", Face = Enum.NormalId.Right, ZIndex = 1},
		},
	},

	["Chroma Evergreen"] = {
		Material = Enum.Material.Plastic,
		AnimatePartColor = true,
		ChromaSpeed = 0.33,
		DecalPhase = 0,
		Decals = {
			{
				Name = "Decal",
				Texture = "rbxassetid://15693337518",
				Face = Enum.NormalId.Front,
				ZIndex = 1,
				Transparency = 0.6000000238418579,
			},
			{
				Name = "Decal",
				Texture = "rbxassetid://15693352412",
				Face = Enum.NormalId.Front,
				ZIndex = 1,
				Transparency = 0,
				AnimateColor = false,
			},
		},
	},

	["Chroma Fang"] = {
		Material = Enum.Material.DiamondPlate,
		Reflectance = 0.009999999776482582,
		Decals = {
			{Texture = "rbxassetid://3167057391", Face = Enum.NormalId.Front, ZIndex = 1},
		},
	},

	["Chroma Gemstone"] = {
		Material = Enum.Material.DiamondPlate,
		Reflectance = 0.009999999776482582,
		Decals = {
			{Texture = "rbxassetid://3183578044", Face = Enum.NormalId.Left, ZIndex = 1},
		},
	},

	["Chroma Gingerblade"] = {
		Material = Enum.Material.Fabric,
		Decals = {
			{Texture = "rbxassetid://2672332704", Face = Enum.NormalId.Front, ZIndex = 1},
			{Texture = "rbxassetid://2672332700", Face = Enum.NormalId.Front, ZIndex = 1},
		},
	},

	["Chroma Heart Wand"] = {
		Material = Enum.Material.Plastic,
		Decals = {
			{Texture = "rbxassetid://106915560132163", Face = Enum.NormalId.Left, ZIndex = 1},
		},
	},

	["Chroma Heat"] = {
		Material = Enum.Material.DiamondPlate,
		Reflectance = 0.009999999776482582,
		Decals = {
			{Texture = "rbxassetid://3171194830", Face = Enum.NormalId.Left, ZIndex = 1},
		},
	},

	["Chroma Saw"] = {
		Material = Enum.Material.Plastic,
		Decals = {
			{Texture = "rbxassetid://3171091036", Face = Enum.NormalId.Left, ZIndex = 1},
		},
	},

	["Chroma Seer"] = {
		Material = Enum.Material.Plastic,
		Decals = {
			{Texture = "rbxassetid://3184061374", Face = Enum.NormalId.Front, ZIndex = 1},
		},
	},

	["Chroma Slasher"] = {
		Material = Enum.Material.DiamondPlate,
		Reflectance = 0.009999999776482582,
		Decals = {
			{Texture = "rbxassetid://3171107715", Face = Enum.NormalId.Back, ZIndex = 1},
		},
	},

	["Chroma Snow Dagger"] = {
		Material = Enum.Material.Plastic,
		Decals = {
			{Texture = "rbxassetid://109403096491788", Face = Enum.NormalId.Left, ZIndex = 1},
		},
	},

	["Chroma Snowstorm"] = {
		Material = Enum.Material.Plastic,
		Decals = {
			{Texture = "rbxassetid://118939212650553", Face = Enum.NormalId.Left, ZIndex = 1},
		},
	},

	["Chroma Sunset"] = {
		Material = Enum.Material.Plastic,
		Decals = {
			{
				Name = "Chroma",
				Texture = "rbxassetid://70538223885127",
				Face = Enum.NormalId.Right,
				ZIndex = 1,
				Transparency = 0,
			},
			{
				Name = "Glow",
				Texture = "rbxassetid://95001575076131",
				Face = Enum.NormalId.Left,
				ZIndex = 2,
				Transparency = 1,
			},
		},
	},

	["Chroma Sweet"] = {
		Material = Enum.Material.Plastic,
		Decals = {
			{Texture = "rbxassetid://87741741305052", Face = Enum.NormalId.Left, ZIndex = 1},
		},
	},

	["Chroma Tides"] = {
		Material = Enum.Material.Plastic,
		Decals = {
			{Texture = "rbxassetid://3171161741", Face = Enum.NormalId.Back, ZIndex = 1},
		},
	},
}

--============================================================
-- CHROMA ANIMATION
--============================================================

local ActiveChroma =
	setmetatable({}, {__mode = "k"})

-- Approximation until we measure MM2's exact cycle speed.
local CHROMA_SPEED = 0.16
local CHROMA_DECAL_PHASE = 0.28

local function RemoveBlizzardChromaObjects(Part)
	if not Part then
		return
	end

	for _,Child in ipairs(
		Part:GetChildren()
	) do
		if Child:GetAttribute(
			"BlizzardChroma"
		) then
			Child:Destroy()
		end
	end

	ActiveChroma[Part] = nil
end

local function ApplyChromaVisuals(
	Part,
	Config
)
	if not Part
		or not Part:IsA("BasePart")
	then
		return
	end

	if not Config then
		RemoveBlizzardChromaObjects(
			Part
		)
		return
	end

	local Existing =
		ActiveChroma[Part]

	if Existing
		and Existing.Config == Config
	then
		if Config.Material then
			Part.Material =
				Config.Material
		end

		if Config.Reflectance ~= nil then
			Part.Reflectance =
				Config.Reflectance
		else
			Part.Reflectance = 0
		end

		return
	end

	RemoveBlizzardChromaObjects(
		Part
	)

	if Config.Material then
		Part.Material =
			Config.Material
	end

	if Config.Reflectance ~= nil then
		Part.Reflectance =
			Config.Reflectance
	else
		Part.Reflectance = 0
	end

	local Decals = {}

	for Index,Info in ipairs(
		Config.Decals
		or {}
	) do
		local Decal =
			Instance.new("Decal")

		Decal.Name =
			Info.Name
			or "Chroma"

		Decal.Texture =
			Info.Texture
			or ""

		Decal.Face =
			Info.Face
			or Enum.NormalId.Front

		Decal.ZIndex =
			Info.ZIndex
			or 1

		if Info.Transparency ~= nil then
			Decal.Transparency =
				Info.Transparency
		else
			Decal.Transparency = 0
		end

		Decal:SetAttribute(
			"BlizzardChroma",
			true
		)

		Decal:SetAttribute(
			"BlizzardChromaIndex",
			Index
		)

		Decal.Parent = Part

		table.insert(
			Decals,
			Decal
		)
	end

	ActiveChroma[Part] = {
		Config = Config,
		Decals = Decals,
	}
end

local ChromaConnection =
	RunService.RenderStepped:
	Connect(function()

		local Time =
			os.clock()

		for Part,Data in pairs(
			ActiveChroma
		) do

			if not Part
				or not Part.Parent
				or not Data
			then
				ActiveChroma[Part] = nil
				continue
			end

			local Speed =
				Data.Config.ChromaSpeed
				or CHROMA_SPEED

			local Phase =
				Data.Config.DecalPhase
			if Phase == nil then
				Phase = CHROMA_DECAL_PHASE
			end

			local PartHue =
				(
					Time
					* Speed
				) % 1

			local DecalHue =
				(
					Time
					* Speed
					+ Phase
				) % 1

			if Data.Config.AnimatePartColor then
				Part.Color =
					Color3.fromHSV(
						PartHue,
						1,
						1
					)
			end

			local DecalColor =
				Color3.fromHSV(
					DecalHue,
					1,
					1
				)

			for Index,Decal in ipairs(
				Data.Decals
			) do
				local Info =
					Data.Config.Decals
					and Data.Config.Decals[Index]

				if Decal
					and Decal.Parent
					and (
						not Info
						or Info.AnimateColor ~= false
					)
				then
					Decal.Color3 =
						DecalColor
				end
			end
		end
	end)

Track(
	ChromaConnection
)


--============================================================
-- NOTIFICATION
--============================================================

local function NotifySkinChanger(Message)
	pcall(function()
		UI.WindUI:Notify({
			Title = "Skin Changer",
			Content = tostring(
				Message or ""
			),
			Icon = "palette",
			Duration = 2.5,
		})
	end)
end


local function GetKnife()
	local Character =
		LocalPlayer.Character

	local BackpackKnife =
		Backpack:
		FindFirstChild("Knife")

	if BackpackKnife
		and BackpackKnife:IsA("Tool")
	then
		return BackpackKnife
	end

	local CharacterKnife =
		Character
		and Character:
			FindFirstChild("Knife")

	if CharacterKnife
		and CharacterKnife:IsA("Tool")
	then
		return CharacterKnife
	end

	return nil
end


local function SaveOriginalKnife(Knife)
	if not Knife
		or SavedKnifeState[Knife]
	then
		return false
	end

	local Handle =
		Knife:
		FindFirstChild("Handle")

	if not Handle
		or not Handle:IsA("BasePart")
	then
		return false
	end

	local Mesh =
		Handle:
		FindFirstChildOfClass(
			"SpecialMesh"
		)

	if not Mesh then
		return false
	end

	SavedKnifeState[Knife] = {
		TextureId = Knife.TextureId,
		Grip = Knife.Grip,
		HandleSize = Handle.Size,

		HandleColor = Handle.Color,
		HandleMaterial = Handle.Material,
		HandleReflectance = Handle.Reflectance,

		MeshType = Mesh.MeshType,
		MeshId = Mesh.MeshId,
		MeshTextureId = Mesh.TextureId,
		MeshScale = Mesh.Scale,
		MeshOffset = Mesh.Offset,
	}

	return true
end


--============================================================
-- VISIBLE MM2 HOTBAR - WEAPON OWNER BASED
--============================================================

local function GetOwnedWeapon()
	local Character = LocalPlayer.Character
	local Tool =
		(Character and Character:FindFirstChild("Knife"))
		or Backpack:FindFirstChild("Knife")

	if Tool and Tool:IsA("Tool") then
		return Tool
	end

	return nil
end

local function GetVisibleToolIcons()
	local BackpackUI = PlayerGui:FindFirstChild("BackpackUI")
	if not BackpackUI then
		return {}
	end

	local BackpackFrame = BackpackUI:FindFirstChild("BackpackFrame")
	if not BackpackFrame then
		return {}
	end

	local Icons = {}
	for _,Descendant in ipairs(BackpackFrame:GetDescendants()) do
		if Descendant.Name == "ToolIcon"
			and (
				Descendant:IsA("ImageLabel")
				or Descendant:IsA("ImageButton")
			)
		then
			table.insert(Icons, Descendant)
		end
	end

	return Icons
end

local function SetVisibleHotbarIcon(Image)
	-- This module may force the visible hotbar only while its weapon
	-- is the weapon the player currently owns.
	if not GetOwnedWeapon() then
		return false
	end

	local Icons = GetVisibleToolIcons()
	if #Icons == 0 then
		return false
	end

	local Changed = false
	for _,ToolIcon in ipairs(Icons) do
		if pcall(function()
			ToolIcon.Image = tostring(Image or "")
		end) then
			Changed = true
		end
	end

	return Changed
end

local function ReapplySelectedHotbarIcon()
	if not GetOwnedWeapon() then
		return false
	end

	local Selected = SkinChanger.SelectedKnife
	local Skin = KnifeSkins[Selected]

	if Selected == "Default" or not Skin then
		return false
	end

	return SetVisibleHotbarIcon(Skin.Icon)
end

local function QueueHotbarIconRefresh()
	task.spawn(function()
		for _,Delay in ipairs({0, 0.03, 0.08, 0.15, 0.30, 0.60, 1.00}) do
			if Delay > 0 then
				task.wait(Delay)
			end

			-- Ownership is checked again on every pass, so an old Gun
			-- refresh cannot overwrite Knife after the role/tool changes.
			if not GetOwnedWeapon() then
				return
			end

			ReapplySelectedHotbarIcon()
		end
	end)
end

--============================================================
-- LOCAL KNIFE DISPLAY
--============================================================

local function GetKnifeBack()
	local Character =
		LocalPlayer.Character

	if not Character then
		return nil
	end

	local UpperTorso =
		Character:
		FindFirstChild(
			"UpperTorso"
		)

	if not UpperTorso then
		return nil
	end

	return
		UpperTorso:
		FindFirstChild(
			"KnifeBack"
		)
end

local function FindLocalKnifeDisplay()
	local WeaponDisplays =
		Workspace:
		FindFirstChild(
			"WeaponDisplays"
		)

	if not WeaponDisplays then
		return nil
	end

	local KnifeBack =
		GetKnifeBack()

	if not KnifeBack then
		return nil
	end

	for _,Display in ipairs(
		WeaponDisplays:GetChildren()
	) do
		if Display.Name == "KnifeDisplay"
			and Display:IsA("BasePart")
		then
			for _,Descendant in ipairs(
				Display:GetDescendants()
			) do
				if Descendant:IsA(
					"RigidConstraint"
				)
					and (
						Descendant.Attachment0
							== KnifeBack
						or Descendant.Attachment1
							== KnifeBack
					)
				then
					return Display
				end
			end
		end
	end

	return nil
end


local function SaveOriginalKnifeBack(Display)
	if not Display
		or SavedKnifeBackState[Display]
	then
		return false
	end

	local Mesh =
		Display:
		FindFirstChildOfClass(
			"SpecialMesh"
		)

	local Attachment =
		Display:
		FindFirstChildOfClass(
			"Attachment"
		)

	SavedKnifeBackState[Display] = {
		Size = Display.Size,
		Transparency = Display.Transparency,
		Massless = Display.Massless,
		CanCollide = Display.CanCollide,

		Color = Display.Color,
		Material = Display.Material,
		Reflectance = Display.Reflectance,

		MeshType = Mesh and Mesh.MeshType,
		MeshId = Mesh and Mesh.MeshId,
		TextureId = Mesh and Mesh.TextureId,
		Scale = Mesh and Mesh.Scale,
		Offset = Mesh and Mesh.Offset,

		AttachmentCFrame =
			Attachment
			and Attachment.CFrame,
	}

	return true
end


--============================================================
-- CHROMA VISUAL RESTORE HELPERS
--============================================================

local function RestoreToolVisualBase(
	Handle,
	Original
)
	if not Handle
		or not Original
	then
		return
	end

	RemoveBlizzardChromaObjects(
		Handle
	)

	Handle.Color =
		Original.HandleColor

	Handle.Material =
		Original.HandleMaterial

	Handle.Reflectance =
		Original.HandleReflectance
end

local function RestoreDisplayVisualBase(
	Display,
	Original
)
	if not Display
		or not Original
	then
		return
	end

	RemoveBlizzardChromaObjects(
		Display
	)

	Display.Color =
		Original.Color

	Display.Material =
		Original.Material

	Display.Reflectance =
		Original.Reflectance
end


local function ApplyKnifeSkinToTool(
	Knife,
	Skin
)
	if not Knife
		or not Skin
		or not Knife:IsA("Tool")
		or Knife.Name ~= "Knife"
	then
		return false
	end

	local Handle =
		Knife:
		FindFirstChild(
			"Handle"
		)

	if not Handle
		or not Handle:IsA("BasePart")
	then
		return false
	end

	local Mesh =
		Handle:
		FindFirstChildOfClass(
			"SpecialMesh"
		)

	if not Mesh then
		return false
	end

	SaveOriginalKnife(
		Knife
	)

	local Original =
		SavedKnifeState[
			Knife
		]

	local Success =
		pcall(function()

			Knife.TextureId =
				Skin.Icon

			Knife.Grip =
				GetHeldOffsetGrip(
					Skin.Grip
				)

			Handle.Size =
				Skin.Size

			Mesh.MeshType =
				Enum.MeshType.FileMesh

			Mesh.MeshId =
				Skin.MeshId

			Mesh.TextureId =
				Skin.TextureId

			Mesh.Scale =
				Skin.Scale

			Mesh.Offset =
				Vector3.new(
					0,
					0,
					0
				)

			local Chroma =
				ChromaKnifeData[
					SkinChanger.SelectedKnife
				]

			if Chroma then
				ApplyChromaVisuals(
					Handle,
					Chroma
				)

				-- Real Chroma Evergreen hides its decorative Christmas-light
				-- decal layers while the knife is actively held. Keep the
				-- Handle chroma cycle itself running; the back/display copy
				-- still receives the captured 0.6 + 0.0 decal transparencies.
				if SkinChanger.SelectedKnife == "Chroma Evergreen" then
					for _,Child in ipairs(Handle:GetChildren()) do
						if Child:IsA("Decal")
							and Child:GetAttribute("BlizzardChroma")
						then
							Child.Transparency = 1
						end
					end
				end
			else
				RestoreToolVisualBase(
					Handle,
					Original
				)
			end
		end)

	if Success then
		SetVisibleHotbarIcon(Skin.Icon)
	end

	return Success
end


local function ApplyKnifeSkinToBack(
	Skin
)
	if not Skin then
		return false
	end

	local Display =
		FindLocalKnifeDisplay()

	if not Display then
		return false
	end

	SaveOriginalKnifeBack(
		Display
	)

	local Original =
		SavedKnifeBackState[
			Display
		]

	local Mesh =
		Display:
		FindFirstChildOfClass(
			"SpecialMesh"
		)

	local Attachment =
		Display:
		FindFirstChildOfClass(
			"Attachment"
		)

	return pcall(function()

		Display.Size =
			Skin.Size

		Display.Transparency =
			0

		Display.Massless =
			true

		Display.CanCollide =
			false

		if Mesh then
			Mesh.MeshType =
				Enum.MeshType.FileMesh

			Mesh.MeshId =
				Skin.MeshId

			Mesh.TextureId =
				Skin.TextureId

			Mesh.Scale =
				Skin.Scale

			Mesh.Offset =
				Vector3.new(
					0,
					0,
					0
				)
		end

		if Attachment
			and Skin.BackCFrame
		then
			Attachment.CFrame =
				Skin.BackCFrame
		end

		local Chroma =
			ChromaKnifeData[
				SkinChanger.SelectedKnife
			]

		if Chroma then
			ApplyChromaVisuals(
				Display,
				Chroma
			)
		else
			RestoreDisplayVisualBase(
				Display,
				Original
			)
		end
	end)
end


local function RestoreKnife(
	Knife
)
	if not Knife then
		return false
	end

	local Original =
		SavedKnifeState[
			Knife
		]

	if not Original then
		return false
	end

	local Handle =
		Knife:
		FindFirstChild(
			"Handle"
		)

	if not Handle then
		return false
	end

	local Mesh =
		Handle:
		FindFirstChildOfClass(
			"SpecialMesh"
		)

	if not Mesh then
		return false
	end

	RemoveBlizzardChromaObjects(
		Handle
	)

	local Success =
		pcall(function()

			Knife.TextureId =
				Original.TextureId

			Knife.Grip =
				GetHeldOffsetGrip(
					Original.Grip
				)

			Handle.Size =
				Original.HandleSize

			Handle.Color =
				Original.HandleColor

			Handle.Material =
				Original.HandleMaterial

			Handle.Reflectance =
				Original.HandleReflectance

			Mesh.MeshType =
				Original.MeshType

			Mesh.MeshId =
				Original.MeshId

			Mesh.TextureId =
				Original.MeshTextureId

			Mesh.Scale =
				Original.MeshScale

			Mesh.Offset =
				Original.MeshOffset
		end)

	if Success then
		SetVisibleHotbarIcon(Original.TextureId)
	end

	return Success
end


local function RestoreKnifeBack()
	local Display =
		FindLocalKnifeDisplay()

	if not Display then
		return false
	end

	local Original =
		SavedKnifeBackState[
			Display
		]

	if not Original then
		return false
	end

	local Mesh =
		Display:
		FindFirstChildOfClass(
			"SpecialMesh"
		)

	local Attachment =
		Display:
		FindFirstChildOfClass(
			"Attachment"
		)

	RemoveBlizzardChromaObjects(
		Display
	)

	return pcall(function()

		Display.Size =
			Original.Size

		Display.Transparency =
			Original.Transparency

		Display.Massless =
			Original.Massless

		Display.CanCollide =
			Original.CanCollide

		Display.Color =
			Original.Color

		Display.Material =
			Original.Material

		Display.Reflectance =
			Original.Reflectance

		if Mesh then

			if Original.MeshType then
				Mesh.MeshType =
					Original.MeshType
			end

			Mesh.MeshId =
				Original.MeshId
				or ""

			Mesh.TextureId =
				Original.TextureId
				or ""

			Mesh.Scale =
				Original.Scale
				or Vector3.new(
					1,
					1,
					1
				)

			Mesh.Offset =
				Original.Offset
				or Vector3.new(
					0,
					0,
					0
				)
		end

		if Attachment
			and Original.AttachmentCFrame
		then
			Attachment.CFrame =
				Original.AttachmentCFrame
		end
	end)
end


local function ApplyCurrentKnifeSkin()
	local Selected =
		SkinChanger.SelectedKnife

	local Knife =
		GetKnife()

	if Selected == "Default" then

		if Knife then
			RestoreKnife(
				Knife
			)
		end

		RestoreKnifeBack()

		return
	end

	local Skin =
		KnifeSkins[
			Selected
		]

	if not Skin then
		return
	end

	if Knife then
		CurrentKnife = Knife

		ApplyKnifeSkinToTool(
			Knife,
			Skin
		)
	end

	ApplyKnifeSkinToBack(
		Skin
	)
end

SkinChanger.ApplyCurrentGunSkin =
	ApplyCurrentGunSkin

SkinChanger.ApplyCurrentKnifeSkin =
	ApplyCurrentKnifeSkin


local function SelectKnifeSkin(
	Value,
	ShowNotification
)
	if type(Value)
		~= "string"
	then
		return
	end

	if Value ~= "Default"
		and not KnifeSkins[Value]
	then
		return
	end

	local Changed =
		Value
		~= SkinChanger.SelectedKnife

	SkinChanger.SelectedKnife =
		Value

	ApplyCurrentKnifeSkin()

	if not ShowNotification
		or not Changed
	then
		return
	end

	if Value == "Default" then
		NotifySkinChanger(
			"Default Knife Equipped"
		)
	else
		NotifySkinChanger(
			Value
			.. " Equipped"
		)
	end
end

SkinChanger.SelectGunSkin =
	SelectGunSkin

SkinChanger.SelectKnifeSkin =
	SelectKnifeSkin


--============================================================
-- WINDUI - KNIFE
--============================================================

print("[KnifeSkin] Creating UI...")

local function GetSkinRarity(Name)
	if Name == "Default" then
		return "Default"
	end

	if string.sub(Name, 1, 7) == "Chroma " then
		return "Chroma"
	end

	local AncientKnife = {
		Batwing = true,
		Celestial = true,
		["Elderwood Scythe"] = true,
		Hallowscythe = true,
		Icebreaker = true,
		Icewing = true,
		Logchopper = true,
		["Nik's Scythe"] = true,
		["Swirly Axe"] = true,
		["Traveler's Axe"] = true,
		["Vampire's Axe"] = true,
	}

	if AncientKnife[Name] then
		return "Ancient"
	end

	return "Godly"
end

local KnifeGalleryItems = {}

for _,Name in ipairs(KnifeSkinOrder) do
	local Skin = KnifeSkins[Name]

	table.insert(
		KnifeGalleryItems,
		{
			Name = Name,
			Image = Skin and Skin.Icon or "",
			Rarity = GetSkinRarity(Name),
		}
	)
end

UI.CreateImageSkinSelector(
	UI.SkinChangerKnifePage,
	"Knife",
	"Tap a skin to equip it.",
	"sword",
	KnifeGalleryItems,
	SkinChanger.SelectedKnife,
	function(Value)
		SelectKnifeSkin(Value, true)
	end
)

local function SetKnifePositionAxis(Axis, Value)
	Value =
		math.clamp(
			tonumber(Value) or 0,
			HELD_POSITION_MIN,
			HELD_POSITION_MAX
		)

	local Data = GetHeldPosition()
	Data[Axis] = Value
	ApplyCurrentKnifeSkin()
end

local function ResetKnifePosition()
	local Data = GetHeldPosition()
	Data.X, Data.Y, Data.Z = 0, 0, 0
	ApplyCurrentKnifeSkin()
	NotifySkinChanger("Knife position reset")
end

UI.AddSection(
	UI.SkinChangerKnifePage,
	"Held Weapon Position",
	"Move the held knife left/right, down/up, and backward/forward"
)

UI.CreateSlider(
	UI.SkinChangerKnifePage,
	"Left / Right",
	"Negative = left, positive = right",
	function() return GetHeldPosition().X end,
	function(Value) SetKnifePositionAxis("X", Value) end,
	HELD_POSITION_MIN,
	HELD_POSITION_MAX,
	HELD_POSITION_STEP
)

UI.CreateSlider(
	UI.SkinChangerKnifePage,
	"Down / Up",
	"Negative = down, positive = up",
	function() return GetHeldPosition().Y end,
	function(Value) SetKnifePositionAxis("Y", Value) end,
	HELD_POSITION_MIN,
	HELD_POSITION_MAX,
	HELD_POSITION_STEP
)

UI.CreateSlider(
	UI.SkinChangerKnifePage,
	"Backward / Forward",
	"Negative = backward, positive = forward",
	function() return GetHeldPosition().Z end,
	function(Value) SetKnifePositionAxis("Z", Value) end,
	HELD_POSITION_MIN,
	HELD_POSITION_MAX,
	HELD_POSITION_STEP
)

UI.CreateActionFeature(
	UI.SkinChangerKnifePage,
	"Reset Position",
	"Reset the held knife to its normal position",
	function()
		ResetKnifePosition()
	end,
	"undo-2"
)

print("[KnifeSkin] UI created successfully")

local function WatchKnife(Knife)
	if not Knife
		or not Knife:IsA("Tool")
		or Knife.Name ~= "Knife"
	then
		return
	end

	if CurrentKnife == Knife then
		-- MM2 may reuse the same Knife Tool between rounds.
		-- Reapply the selected cosmetic whenever the known Tool comes back.
		ApplyCurrentKnifeSkin()
		ReapplySelectedHotbarIcon()
		QueueHotbarIconRefresh()
		return
	end

	CurrentKnife = Knife

	-- Mirror the gun hotbar fix for Knife. MM2 may create/rebuild the
	-- live BackpackUI slot after the Knife Tool already exists, so keep
	-- reapplying both the cosmetic and selected icon during that window.
	task.spawn(function()
		for _,Delay in ipairs({0.10, 0.20, 0.35, 0.55, 0.80, 1.10}) do
			task.wait(Delay)

			if not Knife.Parent then
				return
			end

			ApplyCurrentKnifeSkin()
			ReapplySelectedHotbarIcon()
		end
	end)

	Track(
		Knife.AncestryChanged:
		Connect(function()

			task.defer(function()

				task.wait(
					0.05
				)

				if not Knife.Parent then
					return
				end

				if Knife.Parent == Backpack
					or Knife.Parent
						== LocalPlayer.Character
				then
					ApplyCurrentKnifeSkin()
					ReapplySelectedHotbarIcon()
				end
			end)
		end)
	)
end


--============================================================
-- KNIFE WATCHERS
--============================================================

local function CheckChild(Child)
	if not Child
		or not Child:IsA("Tool")
	then
		return
	end

	if Child.Name == "Knife" then
		WatchKnife(Child)
	end
end

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

	local Knife =
		Character:
		FindFirstChild("Knife")

	if Knife then
		WatchKnife(Knife)
	end
end

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

				if SkinChanger.SelectedKnife ~= "Default" then
					ApplyCurrentKnifeSkin()
				end
			end)
		end)
	)
end

local WatcherOK, WatcherError =
	pcall(function()

		Track(
			Backpack.ChildAdded:
			Connect(function(Child)
				CheckChild(Child)

				if Child:IsA("Tool")
					and Child.Name == "Knife"
				then
					ApplyCurrentKnifeSkin()
					ReapplySelectedHotbarIcon()
					QueueHotbarIconRefresh()
				end
			end)
		)

		if LocalPlayer.Character then
			HookCharacter(LocalPlayer.Character)
		end

		Track(
			LocalPlayer.CharacterAdded:
			Connect(function(Character)
				CurrentKnife = nil
				HookCharacter(Character)

				task.defer(function()
					task.wait(0.5)
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

					if Knife
						and SkinChanger.SelectedKnife ~= "Default"
					then
						ApplyCurrentKnifeSkin()
						QueueHotbarIconRefresh()
					else
						ReapplySelectedHotbarIcon()
					end
				end)
			end)
		)

		local WeaponDisplays =
			Workspace:
			FindFirstChild("WeaponDisplays")

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
					ApplyCurrentKnifeSkin()
				end)
			end)
		)
	end)

if not WatcherOK then
	warn("[KnifeSkin] Watcher setup failed:", WatcherError)
else
	print("[KnifeSkin] Watchers started")
end

task.spawn(function()
	while MM2.Running do
		task.wait(0.25)

		local Knife = GetKnife()

		if Knife
			and Knife ~= CurrentKnife
		then
			WatchKnife(Knife)
		end

		if SkinChanger.SelectedKnife ~= "Default" then
			pcall(ApplyCurrentKnifeSkin)

		elseif Knife
			and SavedKnifeState[Knife]
		then
			pcall(RestoreKnife, Knife)
		end
	end
end)

local ExistingKnife = GetKnife()

if ExistingKnife then
	task.defer(function()
		task.wait(0.25)
		WatchKnife(ExistingKnife)
		ApplyCurrentKnifeSkin()
	end)
end

print("[Blizzard MM2] KnifeSkin.lua loaded")
return MM2
