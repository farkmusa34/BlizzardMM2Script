--============================================================
-- Blizzard MM2 V8.8.4 - SkinChanger.lua
--
-- Client-side cosmetic skin changer.
-- Does NOT modify ownership / inventory metadata.
--
-- Current skins:
-- Gun:
--   Default
--   Harvester
--
-- Knife:
--   Placeholder for future skins
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

local S = MM2.Services
local UI = MM2.UI
local Track = MM2.Track

local Players =
	S.Players
	or game:GetService("Players")

local Workspace =
	S.Workspace
	or game:GetService("Workspace")

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

-- Original values are stored per Gun instance so selecting
-- Default can restore the actual weapon appearance.
local SavedGunState =
	setmetatable(
		{},
		{
			__mode = "k"
		}
	)

local SavedHolsterState =
	setmetatable(
		{},
		{
			__mode = "k"
		}
	)

--============================================================
-- HARVESTER DATA
--============================================================

local HARVESTER_ICON =
	"http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=7800847534"

local HARVESTER_MESH =
	"rbxassetid://7775027413"

local HARVESTER_TEXTURE =
	"http://www.roblox.com/asset/?id=7775245551"

local HARVESTER_SIZE =
	Vector3.new(
		2.244760036468506,
		0.6549199819564819,
		2.880000114440918
	)

local HARVESTER_SCALE =
	Vector3.new(
		0.05072519928216934,
		0.05072552338242531,
		0.05069168284535408
	)

local HARVESTER_GRIP =
	CFrame.new(
		0,
		-0.699999988,
		-0.300000012,

		1, 0, 0,
		0, 1, 4.37113883e-08,
		0, -4.37113883e-08, 1
	)

local HARVESTER_HOLSTER_CFRAME =
	CFrame.new(
		0.129902899,
		0.000002229222218375071,
		0.0750019923,

		0.0000205636024,
		-0.5,
		-0.866025388,

		1,
		-0.0000404856182,
		0.0000471191852,

		-0.0000586211681,
		-0.866025388,
		0.5
	)

--============================================================
-- GUN SKIN DATABASE
--============================================================

local GunSkins = {

	Harvester = {

		Icon =
			HARVESTER_ICON,

		MeshId =
			HARVESTER_MESH,

		TextureId =
			HARVESTER_TEXTURE,

		Size =
			HARVESTER_SIZE,

		Scale =
			HARVESTER_SCALE,

		Grip =
			HARVESTER_GRIP,

		HolsterCFrame =
			HARVESTER_HOLSTER_CFRAME,
	},
}

SkinChanger.GunSkins =
	GunSkins

--============================================================
-- FIND CURRENT GUN
--============================================================

local function GetGun()

	local Character =
		LocalPlayer.Character

	return
		Backpack:FindFirstChild("Gun")
		or (
			Character
			and Character:FindFirstChild("Gun")
		)
end

--============================================================
-- SAVE ORIGINAL GUN
--============================================================

local function SaveOriginalGun(Gun)

	if not Gun
		or SavedGunState[Gun]
	then
		return
	end

	local Handle =
		Gun:FindFirstChild("Handle")

	if not Handle then
		return
	end

	local Mesh =
		Handle:FindFirstChildOfClass(
			"SpecialMesh"
		)

	if not Mesh then
		return
	end

	SavedGunState[Gun] = {

		TextureId =
			Gun.TextureId,

		Grip =
			Gun.Grip,

		HandleSize =
			Handle.Size,

		MeshType =
			Mesh.MeshType,

		MeshId =
			Mesh.MeshId,

		MeshTextureId =
			Mesh.TextureId,

		MeshScale =
			Mesh.Scale,

		MeshOffset =
			Mesh.Offset,
	}
end

--============================================================
-- VISIBLE MM2 HOTBAR
--============================================================

local function GetVisibleToolIcon()

	local BackpackUI =
		PlayerGui:FindFirstChild(
			"BackpackUI"
		)

	if not BackpackUI then
		return nil
	end

	local BackpackFrame =
		BackpackUI:FindFirstChild(
			"BackpackFrame"
		)

	if not BackpackFrame then
		return nil
	end

	local BackpackItem =
		BackpackFrame:FindFirstChild(
			"BackpackItem"
		)

	if not BackpackItem then
		return nil
	end

	local Container =
		BackpackItem:FindFirstChild(
			"Container"
		)

	if not Container then
		return nil
	end

	local ToolIcon =
		Container:FindFirstChild(
			"ToolIcon"
		)

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

local function SetVisibleHotbarIcon(
	Image
)

	local ToolIcon =
		GetVisibleToolIcon()

	if not ToolIcon then
		return false
	end

	ToolIcon.Image =
		tostring(
			Image or ""
		)

	return true
end

--============================================================
-- OPTIONAL CORE HOTBAR
--============================================================

local function SetCoreHotbarIcon(
	Image
)

	pcall(function()

		local CoreGui =
			game:GetService("CoreGui")

		local RobloxGui =
			CoreGui:FindFirstChild(
				"RobloxGui"
			)

		local BackpackGui =
			RobloxGui
			and RobloxGui:FindFirstChild(
				"Backpack"
			)

		local Hotbar =
			BackpackGui
			and BackpackGui:FindFirstChild(
				"Hotbar"
			)

		local Slot =
			Hotbar
			and Hotbar:FindFirstChild("1")

		local Icon =
			Slot
			and Slot:FindFirstChild(
				"Icon"
			)

		if Icon
			and (
				Icon:IsA("ImageLabel")
				or Icon:IsA("ImageButton")
			)
		then

			Icon.Image =
				tostring(
					Image or ""
				)
		end
	end)
end

--============================================================
-- LOCAL GUN DISPLAY / HOLSTER
--============================================================

local function IsLocalGunDisplay(
	Display
)

	local Character =
		LocalPlayer.Character

	if not Character then
		return false
	end

	local LowerTorso =
		Character:FindFirstChild(
			"LowerTorso"
		)

	if not LowerTorso then
		return false
	end

	local GunBelt =
		LowerTorso:FindFirstChild(
			"GunBelt"
		)

	if not GunBelt then
		return false
	end

	for _,Descendant
		in ipairs(
			Display:GetDescendants()
		)
	do

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
		Workspace:FindFirstChild(
			"WeaponDisplays"
		)

	if not WeaponDisplays then
		return nil
	end

	for _,Child
		in ipairs(
			WeaponDisplays:GetChildren()
		)
	do

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
-- SAVE ORIGINAL HOLSTER
--============================================================

local function SaveOriginalHolster(
	Display
)

	if not Display
		or SavedHolsterState[Display]
	then
		return
	end

	local Mesh =
		Display:FindFirstChildOfClass(
			"SpecialMesh"
		)

	local Attachment =
		Display:FindFirstChildOfClass(
			"Attachment"
		)

	SavedHolsterState[Display] = {

		Size =
			Display.Size,

		MeshType =
			Mesh
			and Mesh.MeshType,

		MeshId =
			Mesh
			and Mesh.MeshId,

		TextureId =
			Mesh
			and Mesh.TextureId,

		Scale =
			Mesh
			and Mesh.Scale,

		Offset =
			Mesh
			and Mesh.Offset,

		AttachmentCFrame =
			Attachment
			and Attachment.CFrame,
	}
end

--============================================================
-- APPLY GUN SKIN
--============================================================

local function ApplyGunSkinToTool(
	Gun,
	Skin
)

	if not Gun
		or not Skin
	then
		return false
	end

	if not Gun:IsA("Tool")
		or Gun.Name ~= "Gun"
	then
		return false
	end

	local Handle =
		Gun:FindFirstChild("Handle")

	if not Handle then
		return false
	end

	local Mesh =
		Handle:FindFirstChildOfClass(
			"SpecialMesh"
		)

	if not Mesh then
		return false
	end

	SaveOriginalGun(
		Gun
	)

	pcall(function()

		Gun.TextureId =
			Skin.Icon

		Gun.Grip =
			Skin.Grip

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
			Vector3.zero
	end)

	SetVisibleHotbarIcon(
		Skin.Icon
	)

	SetCoreHotbarIcon(
		Skin.Icon
	)

	return true
end

--============================================================
-- APPLY HOLSTER SKIN
--============================================================

local function ApplyGunSkinToHolster(
	Skin
)

	local Display =
		FindLocalGunDisplay()

	if not Display
		or not Skin
	then
		return false
	end

	SaveOriginalHolster(
		Display
	)

	local Mesh =
		Display:FindFirstChildOfClass(
			"SpecialMesh"
		)

	local Attachment =
		Display:FindFirstChildOfClass(
			"Attachment"
		)

	if Mesh then

		pcall(function()

			Mesh.MeshType =
				Enum.MeshType.FileMesh

			Mesh.MeshId =
				Skin.MeshId

			Mesh.TextureId =
				Skin.TextureId

			Mesh.Scale =
				Skin.Scale

			Mesh.Offset =
				Vector3.zero
		end)
	end

	pcall(function()

		Display.Size =
			Skin.Size
	end)

	if Attachment
		and Skin.HolsterCFrame
	then

		pcall(function()

			Attachment.CFrame =
				Skin.HolsterCFrame
		end)
	end

	return true
end

--============================================================
-- RESTORE DEFAULT GUN
--============================================================

local function RestoreGun(
	Gun
)

	if not Gun then
		return false
	end

	local Original =
		SavedGunState[Gun]

	if not Original then
		return false
	end

	local Handle =
		Gun:FindFirstChild("Handle")

	local Mesh =
		Handle
		and Handle:FindFirstChildOfClass(
			"SpecialMesh"
		)

	if not Handle
		or not Mesh
	then
		return false
	end

	pcall(function()

		Gun.TextureId =
			Original.TextureId

		Gun.Grip =
			Original.Grip

		Handle.Size =
			Original.HandleSize

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

	SetVisibleHotbarIcon(
		Original.TextureId
	)

	SetCoreHotbarIcon(
		Original.TextureId
	)

	return true
end

--============================================================
-- RESTORE DEFAULT HOLSTER
--============================================================

local function RestoreHolster()

	local Display =
		FindLocalGunDisplay()

	if not Display then
		return false
	end

	local Original =
		SavedHolsterState[Display]

	if not Original then
		return false
	end

	local Mesh =
		Display:FindFirstChildOfClass(
			"SpecialMesh"
		)

	local Attachment =
		Display:FindFirstChildOfClass(
			"Attachment"
		)

	pcall(function()

		Display.Size =
			Original.Size
	end)

	if Mesh then

		pcall(function()

			Mesh.MeshType =
				Original.MeshType

			Mesh.MeshId =
				Original.MeshId

			Mesh.TextureId =
				Original.TextureId

			Mesh.Scale =
				Original.Scale

			Mesh.Offset =
				Original.Offset
		end)
	end

	if Attachment
		and Original.AttachmentCFrame
	then

		pcall(function()

			Attachment.CFrame =
				Original.AttachmentCFrame
		end)
	end

	return true
end

--============================================================
-- APPLY CURRENT SELECTION
--============================================================

local function ApplyCurrentGunSkin()

	local Gun =
		GetGun()

	if SkinChanger.SelectedGun
		== "Default"
	then

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
			SkinChanger.SelectedGun
		]

	if not Skin then
		return
	end

	if Gun then

		CurrentGun =
			Gun

		ApplyGunSkinToTool(
			Gun,
			Skin
		)
	end

	ApplyGunSkinToHolster(
		Skin
	)
end

SkinChanger.ApplyCurrentGunSkin =
	ApplyCurrentGunSkin

--============================================================
-- WATCH GUN
--============================================================

local function WatchGun(
	Gun
)

	if not Gun
		or CurrentGun == Gun
	then
		return
	end

	CurrentGun =
		Gun

	task.defer(function()

		task.wait(
			0.15
		)

		if Gun.Parent then
			ApplyCurrentGunSkin()
		end
	end)

	Track(
		Gun.AncestryChanged:Connect(
			function()

				task.defer(function()

					task.wait(
						0.05
					)

					if Gun.Parent == Backpack
						or Gun.Parent
							== LocalPlayer.Character
					then

						ApplyCurrentGunSkin()
					end
				end)
			end
		)
	)
end

local function CheckChild(
	Child
)

	if Child:IsA("Tool")
		and Child.Name == "Gun"
	then

		WatchGun(
			Child
		)
	end
end

--============================================================
-- BACKPACK WATCH
--============================================================

Track(
	Backpack.ChildAdded:Connect(
		function(Child)

			CheckChild(
				Child
			)
		end
	)
)

--============================================================
-- CHARACTER WATCH
--============================================================

local function HookCharacter(
	Character
)

	Track(
		Character.ChildAdded:Connect(
			function(Child)

				CheckChild(
					Child
				)
			end
		)
	)

	local Gun =
		Character:FindFirstChild(
			"Gun"
		)

	if Gun then
		WatchGun(
			Gun
		)
	end
end

if LocalPlayer.Character then

	HookCharacter(
		LocalPlayer.Character
	)
end

Track(
	LocalPlayer.CharacterAdded:Connect(
		function(Character)

			CurrentGun =
				nil

			HookCharacter(
				Character
			)

			task.defer(function()

				task.wait(
					0.5
				)

				ApplyCurrentGunSkin()
			end)
		end
	)
)

--============================================================
-- WATCH MM2 BACKPACK UI REBUILDS
--============================================================

Track(
	PlayerGui.DescendantAdded:Connect(
		function(Descendant)

			if Descendant.Name
					~= "ToolIcon"
			then
				return
			end

			if not (
				Descendant:IsA(
					"ImageLabel"
				)

				or Descendant:IsA(
					"ImageButton"
				)
			)
			then
				return
			end

			task.defer(function()

				task.wait(
					0.05
				)

				ApplyCurrentGunSkin()
			end)
		end
	)
)

--============================================================
-- LIGHT REAPPLY LOOP
--============================================================

task.spawn(function()

	while MM2.Running do

		task.wait(
			0.25
		)

		local Gun =
			GetGun()

		if Gun
			and CurrentGun ~= Gun
		then

			WatchGun(
				Gun
			)
		end

		if SkinChanger.SelectedGun
			~= "Default"
		then

			ApplyCurrentGunSkin()
		end
	end
end)

--============================================================
-- WINDUI
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
	SkinChanger.SelectedGun,
	function(Value)

		if type(Value)
			~= "string"
		then
			return
		end

		SkinChanger.SelectedGun =
			Value

		ApplyCurrentGunSkin()
	end
)

UI.AddSection(
	UI.SkinChangerPage,
	"Knife",
	"Knife skins will be added next"
)

UI.CreateDropdown(
	UI.SkinChangerPage,
	"Knife Skin",
	"Select a knife skin",
	{
		"Default",
	},
	"Default",
	function(Value)

		if type(Value)
			== "string"
		then

			SkinChanger.SelectedKnife =
				Value
		end
	end
)

--============================================================
-- EXISTING GUN
--============================================================

local ExistingGun =
	GetGun()

if ExistingGun then

	task.defer(function()

		task.wait(
			0.25
		)

		WatchGun(
			ExistingGun
		)
	end)
end

print(
	"[Blizzard MM2] SkinChanger.lua loaded"
)

return MM2