--============================================================
-- Blizzard MM2 V8.8.4 - GunSkin.lua
--
-- Gun-only module split from the working SkinChanger.lua base.
-- 62 gun skins mapped 1:1 To diagnostic captures #1-#62.
-- Knife code intentionally excluded from this module.
--============================================================

local MM2 =
	getgenv
	and getgenv().MM2_V85_SPLIT
	or _G.MM2_V85_SPLIT

assert(
	MM2
	and MM2.UI
	and MM2.UI.SkinChangerPage
	and MM2.UI.SkinChangerGunPage,
	"Load Shared.lua + UI.lua first"
)

print("[GunSkin] Starting...")

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

SkinChanger.SelectedGun =
	SkinChanger.SelectedGun
	or "Default"

SkinChanger.HeldPosition =
	SkinChanger.HeldPosition
	or {}

SkinChanger.HeldPosition.Gun =
	SkinChanger.HeldPosition.Gun
	or {
		X = 0,
		Y = 0,
		Z = 0,
	}

SkinChanger.HeldPosition.Gun.X = tonumber(SkinChanger.HeldPosition.Gun.X) or 0
SkinChanger.HeldPosition.Gun.Y = tonumber(SkinChanger.HeldPosition.Gun.Y) or 0
SkinChanger.HeldPosition.Gun.Z = tonumber(SkinChanger.HeldPosition.Gun.Z) or 0

local CurrentGun = nil

local SavedGunState =
	setmetatable({}, {__mode = "k"})

local SavedHolsterState =
	setmetatable({}, {__mode = "k"})

local HELD_POSITION_MIN = -0.525
local HELD_POSITION_MAX = 0.525
local HELD_POSITION_STEP = 0.01

local function GetHeldPosition()
	local Data = SkinChanger.HeldPosition.Gun
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

--============================================================
-- GUN SKIN DATA
--============================================================

local GunSkins = {

	["Gingerscope"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=15666596216",
		MeshId = "rbxassetid://15374602183",
		TextureId = "rbxassetid://15409041564",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.269699990749, 1.2581499815, 4.20871019363),
		Scale = Vector3.new(0.0842, 0.0842, 0.0842),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			0.99619, 0.00000, 0.08716,
			-0.01138, 0.99144, 0.13003,
			-0.08641, -0.13053, 0.98767
		),
		Color = Color3.new(0.5608, 0.1333, 0.1333),
		Material = Enum.Material.Brick,
		Transparency = 0,
		HolsterCFrame = CFrame.new(
			0.129910007119, -2.99999992421e-05, 0.0750000029802,
						1, 0, 0,
						0, 0.707131803036, 0.707081794739,
						0, -0.707081794739, 0.707131803036
		),
	},

	["Harvester"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=7800847534",
		MeshId = "rbxassetid://7775027413",
		TextureId = "http://www.roblox.com/asset/?id=7775245551",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(2.24476003647, 0.654919981956, 2.88000011444),
		Scale = Vector3.new(0.0507, 0.0507, 0.0507),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.0667, 0.0667, 0.0667),
		Material = Enum.Material.Brick,
		Transparency = 0,
		HolsterCFrame = CFrame.new(
			0.129910007119, 0, 0.0750100016594,
						1.99999994948e-05, -0.499998033047, -0.866026580334,
						1, -4.19616335421e-05, 4.73204127047e-05,
						-5.99999984843e-05, -0.866026580334, 0.499998033047
		),
	},

	["Icepiercer"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=11874071041",
		MeshId = "rbxassetid://11868991644",
		TextureId = "rbxassetid://11869075814",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(2.46938991547, 0.752629995346, 2.73834991455),
		Scale = Vector3.new(0.0548, 0.0548, 0.0548),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.Plastic,
		Transparency = 0,
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
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.484169989824, 1.37511003017, 2.08516001701),
		Scale = Vector3.new(0.0471, 0.0471, 0.0471),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.Plastic,
		Transparency = 0,
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
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.421099990606, 1.43482005596, 2.07080006599),
		Scale = Vector3.new(0.0433, 0.0433, 0.0433),
		Grip = CFrame.new(
			0.0000, 0.3400, 0.4700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.Plastic,
		Transparency = 0,
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
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.537000000477, 1.58299994469, 2.367000103),
		Scale = Vector3.new(0.1012, 0.1012, 0.1012),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.Plastic,
		Transparency = 0,
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
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.426629990339, 1.37000000477, 1.64999997616),
		Scale = Vector3.new(0.0364, 0.0350, 0.0350),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.0000, 0.5608, 0.6118),
		Material = Enum.Material.Plastic,
		Transparency = 0,
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
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.833000004292, 1.38399994373, 2.51900005341),
		Scale = Vector3.new(0.0210, 0.0210, 0.0205),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(1.0000, 0.0000, 0.9608),
		Material = Enum.Material.Plastic,
		Transparency = 0,
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
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.509999990463, 1.17999994755, 1.35000002384),
		Scale = Vector3.new(0.5000, 0.5000, 0.5000),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.0000, 0.5608, 0.6118),
		Material = Enum.Material.Plastic,
		Transparency = 0,
	},

	["Chroma Lightbringer"] = {
		Icon = "http://www.roblox.com/asset/?id=4751507078",
		MeshId = "rbxassetid://4730813852",
		TextureId = "rbxassetid://5278764604",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.426629990339, 1.37000000477, 1.64999997616),
		Scale = Vector3.new(0.0364, 0.0350, 0.0350),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.0000, 0.5608, 0.6118),
		Material = Enum.Material.Plastic,
		Transparency = 0,
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
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.509999990463, 1.17999994755, 1.35000002384),
		Scale = Vector3.new(1.8000, 1.8000, 1.8000),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.0000, 0.5608, 0.6118),
		Material = Enum.Material.Plastic,
		Transparency = 0,
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
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.689999997616, 1.64300000668, 2.35500001907),
		Scale = Vector3.new(0.0472, 0.0472, 0.0472),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.Glass,
		Transparency = 0,
		HolsterCFrame = CFrame.new(
			0, -0.200039997697, 0.0899100005627,
						1, 0, 0,
						0, 0.642758846283, 0.766068637371,
						0, -0.766068637371, 0.642758846283
		),
	},

	["Chroma Stark"] = {
		Icon = "rbxassetid://3187421856",
		MeshId = "rbxassetid://118269783",
		TextureId = "rbxassetid://3171214838",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.800000011921, 1.01999998093, 2.06999993324),
		Scale = Vector3.new(0.4400, 0.4400, 0.4400),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.Plastic,
		Transparency = 0,
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
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.559000015259, 1.35500001907, 2.5),
		Scale = Vector3.new(0.0496, 0.0496, 0.0496),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.Plastic,
		Transparency = 0,
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
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.484169989824, 1.37511003017, 2.08516001701),
		Scale = Vector3.new(0.0471, 0.0471, 0.0471),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.Plastic,
		Transparency = 0,
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
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(1.04972994328, 3.20869994164, 1.60000002384),
		Scale = Vector3.new(1.0000, 1.0000, 1.0000),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, -0.00000, 0.00000,
			0.00000, -0.00000, 1.00000,
			0.00000, -1.00000, -0.00000
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.Plastic,
		Transparency = 0,
	},

	["Chroma Traveler's Gun"] = {
		Icon = "rbxassetid://15097920149",
		MeshId = "rbxassetid://15090814396",
		TextureId = "rbxassetid://15090814672",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.571979999542, 0.528729975224, 2.51999998093),
		Scale = Vector3.new(0.0484, 0.0491, 0.0492),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.Plastic,
		Transparency = 0,
	},

	["Chroma Treat"] = {
		Icon = "rbxassetid://121364530728626",
		MeshId = "rbxassetid://135790480817772",
		TextureId = "rbxassetid://86649236464456",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.553520023823, 1.57208001614, 2.38384008408),
		Scale = Vector3.new(0.0538, 0.0538, 0.0538),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.Plastic,
		Transparency = 0,
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
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.42199999094, 1.29200005531, 2.41199994087),
		Scale = Vector3.new(0.0500, 0.0500, 0.0500),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.Plastic,
		Transparency = 0,
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
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.448000013828, 1.36500000954, 2),
		Scale = Vector3.new(0.0395, 0.0395, 0.0395),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.Plastic,
		Transparency = 0,
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
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.600000023842, 1, 1.79999995232),
		Scale = Vector3.new(0.7000, 0.7000, 0.7000),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.Plastic,
		Transparency = 0,
	},

	["Bauble"] = {
		Icon = "rbxthumb://type=Asset&w=150&h=150&id=84481559639371",
		MeshId = "rbxassetid://107813118898769",
		TextureId = "rbxassetid://137012201908941",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.484169989824, 1.37511003017, 2.08516001701),
		Scale = Vector3.new(0.0471, 0.0471, 0.0471),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.Plastic,
		Transparency = 0,
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
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.800000011921, 2, 3.09999990463),
		Scale = Vector3.new(0.4000, 0.4500, 0.5000),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.0000, 0.5608, 0.6118),
		Material = Enum.Material.Plastic,
		Transparency = 0,
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
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.606119990349, 0.265819996595, 1.16242003441),
		Scale = Vector3.new(0.0476, 0.0441, 0.0438),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.Plastic,
		Transparency = 0,
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
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.459109991789, 1.35493004322, 2.3462998867),
		Scale = Vector3.new(0.0469, 0.0469, 0.0469),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.5608, 0.1333, 0.1333),
		Material = Enum.Material.Brick,
		Transparency = 0,
	},

	["Constellation"] = {
		Icon = "rbxthumb://type=Asset&w=150&h=150&id=114197436469014",
		MeshId = "rbxassetid://124598402927958",
		TextureId = "rbxassetid://79010754957272",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(0.1007, 0.1007, 0.1007),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.Plastic,
		Transparency = 0,
	},

	["Darkbringer"] = {
		Icon = "http://www.roblox.com/asset/?id=4751387674",
		MeshId = "rbxassetid://4730813852",
		TextureId = "rbxassetid://4728494788",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(0.0384, 0.0350, 0.0350),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.0000, 0.5608, 0.6118),
		Material = Enum.Material.Plastic,
		Transparency = 0,
	},

	["Darkshot"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=15080280688",
		MeshId = "rbxassetid://4730813852",
		TextureId = "",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(0.0384, 0.0350, 0.0350),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.0667, 0.0667, 0.0667),
		Material = Enum.Material.Plastic,
		Transparency = 0,
	},

	["Elderwood Revolver"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=4468571736",
		MeshId = "rbxassetid://4210029922",
		TextureId = "http://www.roblox.com/asset/?id=4210038158",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(0.0298, 0.0298, 0.0298),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.0667, 0.0667, 0.0667),
		Material = Enum.Material.Brick,
		Transparency = 0,
	},

	["Evergun"] = {
		Icon = "rbxassetid://15694357721",
		MeshId = "rbxassetid://15408863676",
		TextureId = "rbxassetid://15408849730",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(0.0205, 0.0205, 0.0205),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.Plastic,
		Transparency = 0,
	},

	["Flora"] = {
		Icon = "rbxassetid://139276091458016",
		MeshId = "rbxassetid://108253816085047",
		TextureId = "rbxassetid://116621225933096",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(0.0457, 0.0457, 0.0457),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.5608, 0.1333, 0.1333),
		Material = Enum.Material.Brick,
		Transparency = 0,
	},

	["Flowerwood Gun"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=16963894455",
		MeshId = "rbxassetid://16895099893",
		TextureId = "rbxassetid://16895448237",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(0.0519, 0.0519, 0.0519),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.Plastic,
		Transparency = 0,
	},

	["Ginger Luger"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=2674983099",
		MeshId = "http://www.roblox.com/asset/?id=95356090",
		TextureId = "rbxassetid://2702668339",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(1.8000, 1.8000, 1.8000),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.0000, 0.5608, 0.6118),
		Material = Enum.Material.Plastic,
		Transparency = 0,
	},

	["Gingermint"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=11872179646",
		MeshId = "rbxassetid://11866444071",
		TextureId = "rbxassetid://11866444253",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(0.0461, 0.0461, 0.0461),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.SmoothPlastic,
		Transparency = 0,
	},

	["Green Luger"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=332044679",
		MeshId = "http://www.roblox.com/asset/?id=95356090",
		TextureId = "http://www.roblox.com/asset/?id=126534866",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(1.8000, 1.8000, 1.8000),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, -0.00000, 0.00000,
			0.00000, -0.00000, 1.00000,
			0.00000, -1.00000, -0.00000
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.SmoothPlastic,
		Transparency = 0,
	},

	["Hallowgun"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=5877089721",
		MeshId = "rbxassetid://5841866437",
		TextureId = "http://www.roblox.com/asset/?id=5841868338",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(0.0408, 0.0408, 0.0408),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.0667, 0.0667, 0.0667),
		Material = Enum.Material.Brick,
		Transparency = 0,
	},

	["Icebeam"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=8305000161",
		MeshId = "rbxassetid://8310908064",
		TextureId = "rbxassetid://8231066536",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(1.0000, 1.0000, 1.0002),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, -0.00000, 0.00000,
			0.00000, -0.00000, 1.00000,
			0.00000, -1.00000, -0.00000
		),
		Color = Color3.new(0.0667, 0.0667, 0.0667),
		Material = Enum.Material.Brick,
		Transparency = 0,
	},

	["Iceblaster"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=6121579464",
		MeshId = "rbxassetid://6125828567",
		TextureId = "rbxassetid://6120563948",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(1.0000, 1.0000, 1.0000),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, -0.00000, 0.00000,
			0.00000, -0.00000, 1.00000,
			0.00000, -1.00000, -0.00000
		),
		Color = Color3.new(0.0667, 0.0667, 0.0667),
		Material = Enum.Material.Brick,
		Transparency = 0,
	},

	["Jinglegun"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=6121678262",
		MeshId = "rbxassetid://6125843704",
		TextureId = "rbxassetid://6125843755",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(1.0000, 1.0000, 1.0000),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, -0.00000, 0.00000,
			0.00000, -0.00000, 1.00000,
			0.00000, -1.00000, -0.00000
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.Plastic,
		Transparency = 0,
	},

	["Laser"] = {
		Icon = "rbxassetid://3187422496",
		MeshId = "http://www.roblox.com/asset?id=130099641",
		TextureId = "http://www.roblox.com/asset?id=161254231",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(0.5000, 0.5000, 0.5000),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.0000, 0.5608, 0.6118),
		Material = Enum.Material.Plastic,
		Transparency = 0,
	},

	["Lightbringer"] = {
		Icon = "http://www.roblox.com/asset/?id=4751387063",
		MeshId = "rbxassetid://4730813852",
		TextureId = "http://www.roblox.com/asset/?id=4728487789",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(0.0390, 0.0390, 0.0390),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.Plastic,
		Transparency = 0,
	},

	["Luger"] = {
		Icon = "rbxassetid://3187399148",
		MeshId = "http://www.roblox.com/asset/?id=95356090",
		TextureId = "http://www.roblox.com/asset/?id=126534866",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(1.8000, 1.8000, 1.8000),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.0000, 0.5608, 0.6118),
		Material = Enum.Material.Plastic,
		Transparency = 0,
	},

	["Lugercane"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=4535482609",
		MeshId = "rbxassetid://95356090",
		TextureId = "rbxassetid://4835358188",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(1.8000, 1.8000, 1.8000),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.0000, 0.5608, 0.6118),
		Material = Enum.Material.Plastic,
		Transparency = 0,
	},

	["Makeshift"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=11229837140",
		MeshId = "rbxassetid://11158364935",
		TextureId = "http://www.roblox.com/asset/?id=11274360089",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(0.0546, 0.0546, 0.0546),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.Plastic,
		Transparency = 0,
	},

	["Minty"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=4528291487",
		MeshId = "rbxassetid://4528424409",
		TextureId = "rbxassetid://4528424475",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(1.1190, 1.1190, 1.1190),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.0667, 0.0667, 0.0667),
		Material = Enum.Material.Brick,
		Transparency = 0,
	},

	["Ocean"] = {
		Icon = "rbxassetid://13933165014",
		MeshId = "rbxassetid://13928587755",
		TextureId = "rbxassetid://13928590054",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(0.0787, 0.0431, 0.0468),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, -0.00000, 0.00000,
			0.00000, -0.00000, 1.00000,
			0.00000, -1.00000, -0.00000
		),
		Color = Color3.new(0.0667, 0.0667, 0.0667),
		Material = Enum.Material.Plastic,
		Transparency = 0,
	},

	["Pearlshine"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=18322646152",
		MeshId = "rbxassetid://18280804203",
		TextureId = "rbxassetid://18280805635",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(0.0431, 0.0431, 0.0431),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.Brick,
		Transparency = 0,
	},

	["Plasmabeam"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=10014717343",
		MeshId = "rbxassetid://9702755186",
		TextureId = "rbxassetid://10015208201",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(0.0424, 0.0463, 0.0439),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.Plastic,
		Transparency = 0,
	},

	["Rainbow Gun"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=12966354606",
		MeshId = "rbxassetid://12921221200",
		TextureId = "rbxassetid://12921231088",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(0.0519, 0.0519, 0.0519),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.0667, 0.0667, 0.0667),
		Material = Enum.Material.Brick,
		Transparency = 0,
	},

	["Raygun"] = {
		Icon = "rbxthumb://type=Asset&w=150&h=150&id=139431943195380",
		MeshId = "rbxassetid://115447220952926",
		TextureId = "rbxassetid://127881437685243",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(0.0471, 0.0471, 0.0471),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.Slate,
		Transparency = 0,
	},

	["Red Luger"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=332044583",
		MeshId = "http://www.roblox.com/asset/?id=95356090",
		TextureId = "http://www.roblox.com/asset/?id=126534866",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(1.8000, 1.8000, 1.8000),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.0000, 0.5608, 0.6118),
		Material = Enum.Material.Plastic,
		Transparency = 0,
	},

	["Shark"] = {
		Icon = "rbxassetid://3187421705",
		MeshId = "http://www.roblox.com/asset/?id=118269783",
		TextureId = "rbxassetid://1106696354",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(0.4400, 0.4400, 0.4400),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.Plastic,
		Transparency = 0,
	},

	["Snowcannon"] = {
		Icon = "rbxthumb://type=Asset&w=150&h=150&id=129186939023729",
		MeshId = "rbxassetid://99836890880541",
		TextureId = "rbxassetid://122392330922281",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(0.0500, 0.0500, 0.0500),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.SmoothPlastic,
		Transparency = 0,
	},

	["Soul"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=75233248021696",
		MeshId = "rbxassetid://79527507796407",
		TextureId = "rbxassetid://80102752403085",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(0.0444, 0.0444, 0.0444),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.Slate,
		Transparency = 0,
	},

	["Spectre"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=11229779932",
		MeshId = "rbxassetid://11165536294",
		TextureId = "rbxassetid://11165715120",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(0.0525, 0.0525, 0.0525),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, -0.00000, 0.00000,
			0.00000, -0.00000, 1.00000,
			0.00000, -1.00000, -0.00000
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.SmoothPlastic,
		Transparency = 0,
	},

	["Sugar"] = {
		Icon = "rbxassetid://3215356000",
		MeshId = "http://www.roblox.com/asset/?id=101086719",
		TextureId = "http://www.roblox.com/asset/?id=101086650",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(0.5000, 0.5000, 0.5000),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.7686, 0.1569, 0.1098),
		Material = Enum.Material.Plastic,
		Transparency = 0,
	},

	["Sunrise"] = {
		Icon = "rbxthumb://type=Asset&w=150&h=150&id=129480661108374",
		MeshId = "rbxassetid://109742397574153",
		TextureId = "rbxassetid://71731808219690",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(0.0459, 0.0459, 0.0459),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.Plastic,
		Transparency = 0,
	},

	["Swirly Gun"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=8305002569",
		MeshId = "rbxassetid://8310911339",
		TextureId = "rbxassetid://8293539377",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(1.0000, 1.0000, 1.0000),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, -0.00000, 0.00000,
			0.00000, -0.00000, 1.00000,
			0.00000, -1.00000, -0.00000
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.Plastic,
		Transparency = 0,
	},

	["Traveler's Gun"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=15091442039",
		MeshId = "rbxassetid://15090814396",
		TextureId = "rbxassetid://15090814672",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(0.0491, 0.0491, 0.0491),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.0667, 0.0667, 0.0667),
		Material = Enum.Material.Brick,
		Transparency = 0,
	},

	["Vampire's Gun"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=90274872705656",
		MeshId = "rbxassetid://126591885289479",
		TextureId = "rbxassetid://104946799389637",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(0.0483, 0.0483, 0.0483),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.Slate,
		Transparency = 0,
	},

	["Watergun"] = {
		Icon = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=18351388416",
		MeshId = "rbxassetid://18280999342",
		TextureId = "rbxassetid://18281003313",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(0.0395, 0.0395, 0.0395),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.6392, 0.6353, 0.6471),
		Material = Enum.Material.Plastic,
		Transparency = 0,
	},

	["Xenoshot"] = {
		Icon = "rbxthumb://type=Asset&w=150&h=150&id=96859273002742",
		MeshId = "rbxassetid://96867436912658",
		TextureId = "rbxassetid://103568875118220",
		ToolSize = Vector3.new(0.2000, 1.8300, 1.0300),
		DisplaySize = Vector3.new(0.2000, 1.8300, 1.0300),
		Scale = Vector3.new(0.0533, 0.0534, 0.0534),
		Grip = CFrame.new(
			0.0000, -0.3100, 0.6700,
			1.00000, 0.00000, 0.00000,
			0.00000, 0.99144, 0.13053,
			0.00000, -0.13053, 0.99144
		),
		Color = Color3.new(0.5608, 0.1333, 0.1333),
		Material = Enum.Material.Brick,
		Transparency = 0,
	},


}

SkinChanger.GunSkins = GunSkins

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
	"Chroma Stark",
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

SkinChanger.GunSkinOrder = GunSkinOrder

-- CHROMA VISUAL DATA
--============================================================

local ChromaGunData = {
	["Chroma Bauble"] = {
		Material = Enum.Material.Plastic,
		Decals = {
			{Texture = "rbxassetid://129391884956433", Face = Enum.NormalId.Left, ZIndex = 1},
		},
	},

	["Chroma Blizzard"] = {
		Material = Enum.Material.Plastic,
		Decals = {
			{Texture = "rbxassetid://110354859513948", Face = Enum.NormalId.Left, ZIndex = 1},
		},
	},

	["Chroma Constellation"] = {
		Material = Enum.Material.Plastic,
		Decals = {
			{Texture = "rbxassetid://97672028439457", Face = Enum.NormalId.Left, ZIndex = 1},
		},
	},

	["Chroma Darkbringer"] = {
		Material = Enum.Material.Plastic,
		Decals = {
			{Texture = "rbxassetid://5278766434", Face = Enum.NormalId.Back, ZIndex = 1},
		},
	},

	["Chroma Evergun"] = {
		Material = Enum.Material.Plastic,
		AnimatePartColor = true,
		ChromaSpeed = 0.33,
		DecalPhase = 0,
		Decals = {
			{
				Name = "Decal",
				Texture = "rbxassetid://15694616343",
				Face = Enum.NormalId.Front,
				ZIndex = 1,
				Transparency = 0.8,
			},
			{
				Name = "Decal",
				Texture = "rbxassetid://15694615445",
				Face = Enum.NormalId.Front,
				ZIndex = 1,
				Transparency = 0,
				AnimateColor = false,
			},
		},
	},

	["Chroma Laser"] = {
		Material = Enum.Material.Plastic,
		Decals = {
			{Texture = "rbxassetid://3171220436", Face = Enum.NormalId.Left, ZIndex = 1},
		},
	},

	["Chroma Lightbringer"] = {
		Material = Enum.Material.Plastic,
		Decals = {
			{Texture = "rbxassetid://5278766434", Face = Enum.NormalId.Back, ZIndex = 1},
		},
	},

	["Chroma Luger"] = {
		Material = Enum.Material.Plastic,
		Decals = {
			{Texture = "rbxassetid://3171206966", Face = Enum.NormalId.Back, ZIndex = 1},
		},
	},

	["Chroma Raygun"] = {
		Material = Enum.Material.Glass,
		Decals = {
			{Texture = "rbxassetid://73231950532216", Face = Enum.NormalId.Left, ZIndex = 0},
		},
	},

	["Chroma Stark"] = {
		Material = Enum.Material.Plastic,
		Decals = {
			{Texture = "rbxassetid://3171214969", Face = Enum.NormalId.Back, ZIndex = 1},
		},
	},

	["Chroma Snowcannon"] = {
		Material = Enum.Material.Plastic,
		Decals = {
			{Texture = "rbxassetid://84894022221722", Face = Enum.NormalId.Left, ZIndex = 1},
		},
	},

	["Chroma Sunrise"] = {
		Material = Enum.Material.Plastic,
		Decals = {
			{Texture = "rbxassetid://87234234470516", Face = Enum.NormalId.Left, ZIndex = 1},
		},
	},

	["Chroma Swirly Gun"] = {
		Material = Enum.Material.Plastic,
		Decals = {
			{Texture = "rbxassetid://10044507532", Face = Enum.NormalId.Front, ZIndex = 1},
		},
	},

	["Chroma Traveler's Gun"] = {
		Material = Enum.Material.Plastic,
		Decals = {
			{Texture = "rbxassetid://138224985315804", Face = Enum.NormalId.Top, ZIndex = 1},
		},
	},

	["Chroma Treat"] = {
		Material = Enum.Material.Plastic,
		Decals = {
			{Texture = "rbxassetid://71260815789113", Face = Enum.NormalId.Left, ZIndex = 1},
		},
	},

	["Chroma Vampire's Gun"] = {
		Material = Enum.Material.Plastic,
		Decals = {
			{Texture = "rbxassetid://126923923696531", Face = Enum.NormalId.Left, ZIndex = 1},
		},
	},

	["Chroma Watergun"] = {
		Material = Enum.Material.Plastic,
		Decals = {
			{Texture = "rbxassetid://18335602807", Face = Enum.NormalId.Left, ZIndex = 1},
		},
	},
}

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

--============================================================

-- CURRENT TOOLS
--============================================================

local function GetGun()
	local Character =
		LocalPlayer.Character

	local BackpackGun =
		Backpack:
		FindFirstChild("Gun")

	if BackpackGun
		and BackpackGun:IsA("Tool")
	then
		return BackpackGun
	end

	local CharacterGun =
		Character
		and Character:
			FindFirstChild("Gun")

	if CharacterGun
		and CharacterGun:IsA("Tool")
	then
		return CharacterGun
	end

	return nil
end


-- SAVE ORIGINAL TOOLS
--============================================================

local function SaveOriginalGun(Gun)
	if not Gun
		or SavedGunState[Gun]
	then
		return false
	end

	local Handle =
		Gun:
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

	SavedGunState[Gun] = {
		TextureId = Gun.TextureId,
		Grip = Gun.Grip,
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
-- VISIBLE MM2 HOTBAR
--============================================================

local function GetVisibleToolIcons()
	local BackpackUI =
		PlayerGui:
		FindFirstChild("BackpackUI")

	if not BackpackUI then
		return {}
	end

	local BackpackFrame =
		BackpackUI:
		FindFirstChild("BackpackFrame")

	if not BackpackFrame then
		return {}
	end

	local Icons = {}

	for _,Descendant in ipairs(
		BackpackFrame:GetDescendants()
	) do
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

local function GetVisibleToolIcon()
	local Icons = GetVisibleToolIcons()
	return Icons[1]
end

local function SetVisibleHotbarIcon(Image)
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
	local Selected = SkinChanger.SelectedGun
	local Skin = GunSkins[Selected]

	if Selected == "Default" or not Skin then
		return false
	end

	return SetVisibleHotbarIcon(Skin.Icon)
end

local function QueueHotbarIconRefresh()
	task.spawn(function()
		for _,Delay in ipairs({0.05, 0.15, 0.30, 0.60, 1.00}) do
			task.wait(Delay)
			ReapplySelectedHotbarIcon()
		end
	end)
end

-- LOCAL GUN DISPLAY
--============================================================

local function GetGunBelt()
	local Character =
		LocalPlayer.Character

	if not Character then
		return nil
	end

	local LowerTorso =
		Character:
		FindFirstChild(
			"LowerTorso"
		)

	if not LowerTorso then
		return nil
	end

	return
		LowerTorso:
		FindFirstChild(
			"GunBelt"
		)
end

local function IsLocalGunDisplay(Display)
	if not Display
		or not Display:IsA("BasePart")
	then
		return false
	end

	local GunBelt =
		GetGunBelt()

	if not GunBelt then
		return false
	end

	for _,Descendant in ipairs(
		Display:GetDescendants()
	) do
		if Descendant:IsA(
			"RigidConstraint"
		) then
			if Descendant.Attachment0
					== GunBelt
				or Descendant.Attachment1
					== GunBelt
			then
				return true
			end
		end
	end

	return false
end

local function FindLocalGunDisplay()
	local WeaponDisplays =
		Workspace:
		FindFirstChild(
			"WeaponDisplays"
		)

	if not WeaponDisplays then
		return nil
	end

	for _,Child in ipairs(
		WeaponDisplays:GetChildren()
	) do
		if Child.Name == "GunDisplay"
			and Child:IsA("BasePart")
			and IsLocalGunDisplay(
				Child
			)
		then
			return Child
		end
	end

	return nil
end

--============================================================

-- SAVE ORIGINAL DISPLAYS
--============================================================

local function SaveOriginalHolster(Display)
	if not Display
		or SavedHolsterState[Display]
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

	SavedHolsterState[Display] = {
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

--============================================================

-- APPLY TOOL SKINS
--============================================================

local function ApplyGunSkinToTool(
	Gun,
	Skin
)
	if not Gun
		or not Skin
		or not Gun:IsA("Tool")
		or Gun.Name ~= "Gun"
	then
		return false
	end

	local Handle =
		Gun:
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

	SaveOriginalGun(
		Gun
	)

	local Original =
		SavedGunState[
			Gun
		]

	local Success =
		pcall(function()

			Gun.TextureId =
				Skin.Icon

			Gun.Grip =
				GetHeldOffsetGrip(
					Skin.Grip
				)

			Handle.Size =
				Skin.ToolSize
				or Skin.Size

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
				ChromaGunData[
					SkinChanger.SelectedGun
				]

			if Chroma then
				ApplyChromaVisuals(
					Handle,
					Chroma
				)
			else
				RestoreToolVisualBase(
					Handle,
					Original
				)
			end
		end)

	if Success then
		SetVisibleHotbarIcon(
			Skin.Icon
		)
	end

	return Success
end


-- APPLY DISPLAY SKINS
--============================================================

local function ApplyGunSkinToHolster(
	Skin
)
	if not Skin then
		return false
	end

	local Display =
		FindLocalGunDisplay()

	if not Display then
		return false
	end

	SaveOriginalHolster(
		Display
	)

	local Original =
		SavedHolsterState[
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
			Skin.DisplaySize
			or Skin.ToolSize
			or Skin.Size

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
			and Skin.HolsterCFrame
		then
			Attachment.CFrame =
				Skin.HolsterCFrame
		end

		local Chroma =
			ChromaGunData[
				SkinChanger.SelectedGun
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


-- RESTORE TOOLS
--============================================================

local function RestoreGun(
	Gun
)
	if not Gun then
		return false
	end

	local Original =
		SavedGunState[
			Gun
		]

	if not Original then
		return false
	end

	local Handle =
		Gun:
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

			Gun.TextureId =
				Original.TextureId

			Gun.Grip =
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
		SetVisibleHotbarIcon(
			Original.TextureId
		)
	end

	return Success
end


-- RESTORE DISPLAYS
--============================================================

local function RestoreHolster()
	local Display =
		FindLocalGunDisplay()

	if not Display then
		return false
	end

	local Original =
		SavedHolsterState[
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


-- APPLY CURRENT SELECTIONS
--============================================================

local function ApplyCurrentGunSkin()
	local Selected =
		SkinChanger.SelectedGun

	local Gun =
		GetGun()

	if Selected == "Default" then

		if Gun then
			RestoreGun(
				Gun
			)
		end

		RestoreHolster()

		return
	end

	local Skin =
		GunSkins[
			Selected
		]

	if not Skin then
		return
	end

	if Gun then
		CurrentGun = Gun

		ApplyGunSkinToTool(
			Gun,
			Skin
		)
	else
		-- Hotbar persistence is independent of the physical Gun.
		ReapplySelectedHotbarIcon()
	end

	ApplyGunSkinToHolster(
		Skin
	)
end


-- MANUAL SELECTION
--============================================================

local function SelectGunSkin(
	Value,
	ShowNotification
)
	if type(Value)
		~= "string"
	then
		return
	end

	if Value ~= "Default"
		and not GunSkins[Value]
	then
		return
	end

	local Changed =
		Value
		~= SkinChanger.SelectedGun

	SkinChanger.SelectedGun =
		Value

	ApplyCurrentGunSkin()

	if not ShowNotification
		or not Changed
	then
		return
	end

	if Value == "Default" then
		NotifySkinChanger(
			"Default Gun Equipped"
		)
	else
		NotifySkinChanger(
			Value
			.. " Equipped"
		)
	end
end


--============================================================
-- WINDUI
--============================================================

print("[GunSkin] Creating UI...")

local function GetSkinRarity(Name)
	if Name == "Default" then
		return "Default"
	end

	if string.sub(Name,1,7) == "Chroma " then
		return "Chroma"
	end

	local AncientGun = {
		Gingerscope=true,
		Harvester=true,
		Icepiercer=true,
		["Traveler's Gun"]=true,
		["Vampire's Gun"]=true,
	}

	if AncientGun[Name] then
		return "Ancient"
	end

	return "Godly"
end

local GunGalleryItems = {}

for _,Name in ipairs(GunSkinOrder) do
	local Skin = GunSkins[Name]

	table.insert(
		GunGalleryItems,
		{
			Name = Name,
			Image = Skin and Skin.Icon or "",
			Rarity = GetSkinRarity(Name),
		}
	)
end

UI.CreateImageSkinSelector(
	UI.SkinChangerGunPage,
	"Gun",
	"Tap a skin to equip it.",
	"crosshair",
	GunGalleryItems,
	SkinChanger.SelectedGun,
	function(Value)
		SelectGunSkin(Value,true)
	end
)

--============================================================
-- HELD GUN POSITION UI
--============================================================

local function SetGunPositionAxis(Axis, Value)
	Value =
		math.clamp(
			tonumber(Value) or 0,
			HELD_POSITION_MIN,
			HELD_POSITION_MAX
		)

	local Data = GetHeldPosition()
	Data[Axis] = Value
	ApplyCurrentGunSkin()
end

local function ResetGunPosition()
	local Data = GetHeldPosition()
	Data.X, Data.Y, Data.Z = 0, 0, 0
	ApplyCurrentGunSkin()
	NotifySkinChanger("Gun position reset")
end

UI.AddSection(
	UI.SkinChangerGunPage,
	"Held Weapon Position",
	"Move the held gun left/right, down/up, and backward/forward"
)

UI.CreateSlider(
	UI.SkinChangerGunPage,
	"Left / Right",
	"Negative = left, positive = right",
	function() return GetHeldPosition().X end,
	function(Value) SetGunPositionAxis("X", Value) end,
	HELD_POSITION_MIN,
	HELD_POSITION_MAX,
	HELD_POSITION_STEP
)

UI.CreateSlider(
	UI.SkinChangerGunPage,
	"Down / Up",
	"Negative = down, positive = up",
	function() return GetHeldPosition().Y end,
	function(Value) SetGunPositionAxis("Y", Value) end,
	HELD_POSITION_MIN,
	HELD_POSITION_MAX,
	HELD_POSITION_STEP
)

UI.CreateSlider(
	UI.SkinChangerGunPage,
	"Backward / Forward",
	"Negative = backward, positive = forward",
	function() return GetHeldPosition().Z end,
	function(Value) SetGunPositionAxis("Z", Value) end,
	HELD_POSITION_MIN,
	HELD_POSITION_MAX,
	HELD_POSITION_STEP
)

UI.CreateActionFeature(
	UI.SkinChangerGunPage,
	"Reset Position",
	"Reset the held gun to its normal position",
	function() ResetGunPosition() end,
	"undo-2"
)

print("[GunSkin] UI created successfully")

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
		-- MM2 can reuse the same Gun Tool between round states.
		-- Reapply the selected cosmetic whenever that known Gun returns.
		ApplyCurrentGunSkin()
		ReapplySelectedHotbarIcon()
		QueueHotbarIconRefresh()
		return
	end

	CurrentGun = Gun

	-- A gun selected during intermission can be created before MM2 has
	-- finished rebuilding BackpackUI. Do a short full refresh window so
	-- both the cosmetic tool and its hotbar icon survive MM2's own writes.
	task.spawn(function()
		for _,Delay in ipairs({0.10, 0.20, 0.35, 0.55, 0.80, 1.10}) do
			task.wait(Delay)

			if not Gun.Parent then
				return
			end

			ApplyCurrentGunSkin()
			ReapplySelectedHotbarIcon()
		end
	end)

	Track(
		Gun.AncestryChanged:
		Connect(function()

			task.defer(function()

				task.wait(
					0.05
				)

				if not Gun.Parent then
					return
				end

				if Gun.Parent == Backpack
					or Gun.Parent
						== LocalPlayer.Character
				then
					ApplyCurrentGunSkin()
					ReapplySelectedHotbarIcon()
				end
			end)
		end)
	)
end


local function CheckChild(Child)
	if not Child
		or not Child:IsA("Tool")
	then
		return
	end

	if Child.Name == "Gun" then
		WatchGun(Child)
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

	local Gun =
		Character:
		FindFirstChild("Gun")

	if Gun then
		WatchGun(Gun)
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

				if Child:IsA("Tool")
					and Child.Name == "Gun"
				then
					ApplyCurrentGunSkin()
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

				CurrentGun = nil

				HookCharacter(Character)

				task.defer(function()
					task.wait(0.5)
					ApplyCurrentGunSkin()
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

					local Gun = GetGun()

					if Gun
						and SkinChanger.SelectedGun ~= "Default"
					then
						ApplyCurrentGunSkin()
						QueueHotbarIconRefresh()

					elseif not Gun
						and SkinChanger.SelectedGun ~= "Default"
						and tostring(Descendant.Image):
							find(
								"197518111",
								1,
								true
							)
					then
						ReapplySelectedHotbarIcon()
						QueueHotbarIconRefresh()
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
					ApplyCurrentGunSkin()
				end)
			end)
		)
	end)

if not WatcherOK then
	warn(
		"[GunSkin] Watcher setup failed:",
		WatcherError
	)
else
	print("[GunSkin] Watchers started")
end

--============================================================
-- LIGHT PERSISTENCE LOOP
--============================================================

task.spawn(function()

	while MM2.Running do

		task.wait(0.25)

		local Gun = GetGun()

		if Gun
			and Gun ~= CurrentGun
		then
			WatchGun(Gun)
		end

		if SkinChanger.SelectedGun ~= "Default" then
			pcall(ApplyCurrentGunSkin)

		elseif Gun
			and SavedGunState[Gun]
		then
			pcall(RestoreGun, Gun)
		end
	end
end)

--============================================================
-- EXISTING TOOL
--============================================================

local ExistingGun = GetGun()

if ExistingGun then
	task.defer(function()
		task.wait(0.25)
		WatchGun(ExistingGun)
		ApplyCurrentGunSkin()
	end)
end

print("[Blizzard MM2] GunSkin.lua loaded")
return MM2
