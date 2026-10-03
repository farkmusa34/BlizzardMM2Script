--============================================================
-- Blizzard MM2 V8.8.4 - GunSkins.lua
-- Gun skin data module split from SkinChanger.lua.
-- Existing captured skins preserved; new verified captures can be appended.
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
	["Constellation"] = {
		Icon = "rbxthumb://type=Asset&w=150&h=150&id=114197436469014",
		MeshId = "rbxassetid://124598402927958",
		TextureId = "rbxassetid://79010754957272",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(0.1007, 0.1007, 0.1007),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, 0, 0, 0, 0.99144, 0.13053, 0, -0.13053, 0.99144
		),
		HolsterCFrame = CFrame.new(),
	},

	["Darkbringer"] = {
		Icon = "http://www.roblox.com/asset/?id=4751387674",
		MeshId = "rbxassetid://4730813852",
		TextureId = "rbxassetid://4728494788",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(0.0384, 0.035, 0.035),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, 0, 0, 0, 0.99144, 0.13053, 0, -0.13053, 0.99144
		),
		HolsterCFrame = CFrame.new(),
	},

	["Darkshot"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=15080280688",
		MeshId = "rbxassetid://4730813852",
		TextureId = "",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(0.0384, 0.035, 0.035),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, 0, 0, 0, 0.99144, 0.13053, 0, -0.13053, 0.99144
		),
		HolsterCFrame = CFrame.new(),
	},

	["Elderwood Revolver"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=4468571736",
		MeshId = "rbxassetid://4210029922",
		TextureId = "http://www.roblox.com/asset/?id=4210038158",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(0.0298, 0.0298, 0.0298),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, 0, 0, 0, 0.99144, 0.13053, 0, -0.13053, 0.99144
		),
		HolsterCFrame = CFrame.new(),
	},

	["Evergun"] = {
		Icon = "rbxassetid://15694357721",
		MeshId = "rbxassetid://15408863676",
		TextureId = "rbxassetid://15408849730",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(0.0205, 0.0205, 0.0205),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, 0, 0, 0, 0.99144, 0.13053, 0, -0.13053, 0.99144
		),
		HolsterCFrame = CFrame.new(),
	},

	["Flora"] = {
		Icon = "rbxassetid://139276091458016",
		MeshId = "rbxassetid://108253816085047",
		TextureId = "rbxassetid://116621225933096",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(0.0457, 0.0457, 0.0457),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, 0, 0, 0, 0.99144, 0.13053, 0, -0.13053, 0.99144
		),
		HolsterCFrame = CFrame.new(),
	},

	["Flowerwood Gun"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=16963894455",
		MeshId = "rbxassetid://16895099893",
		TextureId = "rbxassetid://16895448237",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(0.0519, 0.0519, 0.0519),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, 0, 0, 0, 0.99144, 0.13053, 0, -0.13053, 0.99144
		),
		HolsterCFrame = CFrame.new(),
	},

	["Ginger Luger"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=2674983099",
		MeshId = "http://www.roblox.com/asset/?id=95356090",
		TextureId = "rbxassetid://2702668339",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(1.8, 1.8, 1.8),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, 0, 0, 0, 0.99144, 0.13053, 0, -0.13053, 0.99144
		),
		HolsterCFrame = CFrame.new(),
	},

	["Gingermint"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=11872179646",
		MeshId = "rbxassetid://11866444071",
		TextureId = "rbxassetid://11866444253",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(0.0461, 0.0461, 0.0461),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, 0, 0, 0, 0.99144, 0.13053, 0, -0.13053, 0.99144
		),
		HolsterCFrame = CFrame.new(),
	},

	["Green Luger"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=332044679",
		MeshId = "http://www.roblox.com/asset/?id=95356090",
		TextureId = "http://www.roblox.com/asset/?id=126534866",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(1.8, 1.8, 1.8),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, -0, 0, 0, -0, 1, 0, -1, -0
		),
		HolsterCFrame = CFrame.new(),
	},

	["Hallowgun"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=5877089721",
		MeshId = "rbxassetid://5841866437",
		TextureId = "http://www.roblox.com/asset/?id=5841868338",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(0.0408, 0.0408, 0.0408),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, 0, 0, 0, 0.99144, 0.13053, 0, -0.13053, 0.99144
		),
		HolsterCFrame = CFrame.new(),
	},

	["Icebeam"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=8305000161",
		MeshId = "rbxassetid://8310908064",
		TextureId = "rbxassetid://8231066536",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(1, 1, 1.0002),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, -0, 0, 0, -0, 1, 0, -1, -0
		),
		HolsterCFrame = CFrame.new(),
	},

	["Iceblaster"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=6121579464",
		MeshId = "rbxassetid://6125828567",
		TextureId = "rbxassetid://6120563948",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(1, 1, 1),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, -0, 0, 0, -0, 1, 0, -1, -0
		),
		HolsterCFrame = CFrame.new(),
	},

	["Jinglegun"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=6121678262",
		MeshId = "rbxassetid://6125843704",
		TextureId = "rbxassetid://6125843755",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(1, 1, 1),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, -0, 0, 0, -0, 1, 0, -1, -0
		),
		HolsterCFrame = CFrame.new(),
	},

	["Laser"] = {
		Icon = "rbxassetid://3187422496",
		MeshId = "http://www.roblox.com/asset?id=130099641",
		TextureId = "http://www.roblox.com/asset?id=161254231",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(0.5, 0.5, 0.5),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, 0, 0, 0, 0.99144, 0.13053, 0, -0.13053, 0.99144
		),
		HolsterCFrame = CFrame.new(),
	},

	["Lightbringer"] = {
		Icon = "http://www.roblox.com/asset/?id=4751387063",
		MeshId = "rbxassetid://4730813852",
		TextureId = "http://www.roblox.com/asset/?id=4728487789",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(0.039, 0.039, 0.039),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, 0, 0, 0, 0.99144, 0.13053, 0, -0.13053, 0.99144
		),
		HolsterCFrame = CFrame.new(),
	},

	["Luger"] = {
		Icon = "rbxassetid://3187399148",
		MeshId = "http://www.roblox.com/asset/?id=95356090",
		TextureId = "http://www.roblox.com/asset/?id=126534866",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(1.8, 1.8, 1.8),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, 0, 0, 0, 0.99144, 0.13053, 0, -0.13053, 0.99144
		),
		HolsterCFrame = CFrame.new(),
	},

	["Lugercane"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=4535482609",
		MeshId = "rbxassetid://95356090",
		TextureId = "rbxassetid://4835358188",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(1.8, 1.8, 1.8),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, 0, 0, 0, 0.99144, 0.13053, 0, -0.13053, 0.99144
		),
		HolsterCFrame = CFrame.new(),
	},

	["Makeshift"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=11229837140",
		MeshId = "rbxassetid://11158364935",
		TextureId = "http://www.roblox.com/asset/?id=11274360089",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(0.0546, 0.0546, 0.0546),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, 0, 0, 0, 0.99144, 0.13053, 0, -0.13053, 0.99144
		),
		HolsterCFrame = CFrame.new(),
	},

	["Minty"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=4528291487",
		MeshId = "rbxassetid://4528424409",
		TextureId = "rbxassetid://4528424475",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(1.119, 1.119, 1.119),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, 0, 0, 0, 0.99144, 0.13053, 0, -0.13053, 0.99144
		),
		HolsterCFrame = CFrame.new(),
	},

	["Ocean"] = {
		Icon = "rbxassetid://13933165014",
		MeshId = "rbxassetid://13928587755",
		TextureId = "rbxassetid://13928590054",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(0.0787, 0.0431, 0.0468),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, -0, 0, 0, -0, 1, 0, -1, -0
		),
		HolsterCFrame = CFrame.new(),
	},

	["Pearlshine"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=18322646152",
		MeshId = "rbxassetid://18280804203",
		TextureId = "rbxassetid://18280805635",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(0.0431, 0.0431, 0.0431),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, 0, 0, 0, 0.99144, 0.13053, 0, -0.13053, 0.99144
		),
		HolsterCFrame = CFrame.new(),
	},

	["Plasmabeam"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=10014717343",
		MeshId = "rbxassetid://9702755186",
		TextureId = "rbxassetid://10015208201",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(0.0424, 0.0463, 0.0439),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, 0, 0, 0, 0.99144, 0.13053, 0, -0.13053, 0.99144
		),
		HolsterCFrame = CFrame.new(),
	},

	["Rainbow Gun"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=12966354606",
		MeshId = "rbxassetid://12921221200",
		TextureId = "rbxassetid://12921231088",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(0.0519, 0.0519, 0.0519),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, 0, 0, 0, 0.99144, 0.13053, 0, -0.13053, 0.99144
		),
		HolsterCFrame = CFrame.new(),
	},

	["Raygun"] = {
		Icon = "rbxthumb://type=Asset&w=150&h=150&id=139431943195380",
		MeshId = "rbxassetid://115447220952926",
		TextureId = "rbxassetid://127881437685243",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(0.0471, 0.0471, 0.0471),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, 0, 0, 0, 0.99144, 0.13053, 0, -0.13053, 0.99144
		),
		HolsterCFrame = CFrame.new(),
	},

	["Red Luger"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=332044583",
		MeshId = "http://www.roblox.com/asset/?id=95356090",
		TextureId = "http://www.roblox.com/asset/?id=126534866",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(1.8, 1.8, 1.8),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, 0, 0, 0, 0.99144, 0.13053, 0, -0.13053, 0.99144
		),
		HolsterCFrame = CFrame.new(),
	},

	["Shark"] = {
		Icon = "rbxassetid://3187421705",
		MeshId = "http://www.roblox.com/asset/?id=118269783",
		TextureId = "rbxassetid://1106696354",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(0.44, 0.44, 0.44),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, 0, 0, 0, 0.99144, 0.13053, 0, -0.13053, 0.99144
		),
		HolsterCFrame = CFrame.new(),
	},

	["Snowcannon"] = {
		Icon = "rbxthumb://type=Asset&w=150&h=150&id=129186939023729",
		MeshId = "rbxassetid://99836890880541",
		TextureId = "rbxassetid://122392330922281",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(0.05, 0.05, 0.05),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, 0, 0, 0, 0.99144, 0.13053, 0, -0.13053, 0.99144
		),
		HolsterCFrame = CFrame.new(),
	},

	["Soul"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=75233248021696",
		MeshId = "rbxassetid://79527507796407",
		TextureId = "rbxassetid://80102752403085",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(0.0444, 0.0444, 0.0444),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, 0, 0, 0, 0.99144, 0.13053, 0, -0.13053, 0.99144
		),
		HolsterCFrame = CFrame.new(),
	},

	["Spectre"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=11229779932",
		MeshId = "rbxassetid://11165536294",
		TextureId = "rbxassetid://11165715120",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(0.0525, 0.0525, 0.0525),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, -0, 0, 0, -0, 1, 0, -1, -0
		),
		HolsterCFrame = CFrame.new(),
	},

	["Sugar"] = {
		Icon = "rbxassetid://3215356000",
		MeshId = "http://www.roblox.com/asset/?id=101086719",
		TextureId = "http://www.roblox.com/asset/?id=101086650",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(0.5, 0.5, 0.5),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, 0, 0, 0, 0.99144, 0.13053, 0, -0.13053, 0.99144
		),
		HolsterCFrame = CFrame.new(),
	},

	["Sunrise"] = {
		Icon = "rbxthumb://type=Asset&w=150&h=150&id=129480661108374",
		MeshId = "rbxassetid://109742397574153",
		TextureId = "rbxassetid://71731808219690",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(0.0459, 0.0459, 0.0459),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, 0, 0, 0, 0.99144, 0.13053, 0, -0.13053, 0.99144
		),
		HolsterCFrame = CFrame.new(),
	},

	["Swirly Gun"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=8305002569",
		MeshId = "rbxassetid://8310911339",
		TextureId = "rbxassetid://8293539377",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(1, 1, 1),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, -0, 0, 0, -0, 1, 0, -1, -0
		),
		HolsterCFrame = CFrame.new(),
	},

	["Traveler's Gun"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=15091442039",
		MeshId = "rbxassetid://15090814396",
		TextureId = "rbxassetid://15090814672",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(0.0491, 0.0491, 0.0491),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, 0, 0, 0, 0.99144, 0.13053, 0, -0.13053, 0.99144
		),
		HolsterCFrame = CFrame.new(),
	},

	["Vampire's Gun"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=90274872705656",
		MeshId = "rbxassetid://126591885289479",
		TextureId = "rbxassetid://104946799389637",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(0.0483, 0.0483, 0.0483),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, 0, 0, 0, 0.99144, 0.13053, 0, -0.13053, 0.99144
		),
		HolsterCFrame = CFrame.new(),
	},

	["Watergun"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=18351388416",
		MeshId = "rbxassetid://18280999342",
		TextureId = "rbxassetid://18281003313",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(0.0395, 0.0395, 0.0395),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, 0, 0, 0, 0.99144, 0.13053, 0, -0.13053, 0.99144
		),
		HolsterCFrame = CFrame.new(),
	},

	["Xenoshot"] = {
		Icon = "rbxthumb://type=Asset&w=150&h=150&id=96859273002742",
		MeshId = "rbxassetid://96867436912658",
		TextureId = "rbxassetid://103568875118220",
		Size = Vector3.new(0.2, 1.83, 1.03),
		Scale = Vector3.new(0.0533, 0.0534, 0.0534),
		Grip = CFrame.new(
			0, -0.31, 0.67, 1, 0, 0, 0, 0.99144, 0.13053, 0, -0.13053, 0.99144
		),
		HolsterCFrame = CFrame.new(),
	},

}

local GunSkinOrder = {
	"Gingerscope",
	"Harvester",
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
	"Constellation",
	"Darkbringer",
	"Darkshot",
	"Elderwood Revolver",
	"Evergun",
	"Flora",
	"Flowerwood Gun",
	"Ginger Luger",
	"Gingermint",
	"Green Luger",
	"Hallowgun",
	"Icebeam",
	"Iceblaster",
	"Jinglegun",
	"Laser",
	"Lightbringer",
	"Luger",
	"Lugercane",
	"Makeshift",
	"Minty",
	"Ocean",
	"Pearlshine",
	"Plasmabeam",
	"Rainbow Gun",
	"Raygun",
	"Red Luger",
	"Shark",
	"Snowcannon",
	"Soul",
	"Spectre",
	"Sugar",
	"Sunrise",
	"Swirly Gun",
	"Traveler's Gun",
	"Vampire's Gun",
	"Watergun",
	"Xenoshot",
}

return {
	Skins = GunSkins,
	Order = GunSkinOrder,
}
