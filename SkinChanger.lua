--============================================================
-- Blizzard MM2 V8.8.4 - SkinChanger.lua
--
-- Client-side cosmetic skin changer.
-- Does NOT modify ownership or inventory metadata.
--
-- Gun:
--   Default
--   Harvester
--
-- Knife:
--   Default (more skins later)
--
-- Includes:
--   • Held Harvester model
--   • Harvester grip
--   • Real local MM2 GunDisplay holster
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

local HARVESTER = {

	Icon =
		"http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=7800847534",

	MeshId =
		"rbxassetid://7775027413",

	TextureId =
		"http://www.roblox.com/asset/?id=7775245551",

	Size =
		Vector3.new(
			2.244760036468506,
			0.6549199819564819,
			2.880000114440918
		),

	Scale =
		Vector3.new(
			0.05072519928216934,
			0.05072552338242531,
			0.05069168284535408
		),

	Grip =
		CFrame.new(
			0,
			-0.699999988,
			-0.300000012,

			1, 0, 0,
			0, 1, 4.37113883e-08,
			0, -4.37113883e-08, 1
		),

	HolsterCFrame =
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
		),
}

local GunSkins = {
	Harvester = HARVESTER,
}

SkinChanger.GunSkins =
	GunSkins

--============================================================
-- NOTIFICATION
--
-- Only called from MANUAL dropdown selection.
-- Background reapplication never calls this.
--============================================================

local function NotifySkinChanger(
	Message
)

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
-- CURRENT GUN
--============================================================

local function GetGun()

	local Character =
		LocalPlayer.Character

	local BackpackGun =
		Backpack:FindFirstChild(
			"Gun"
		)

	if BackpackGun
		and BackpackGun:IsA("Tool")
	then

		return BackpackGun
	end

	local CharacterGun =
		Character
		and Character:FindFirstChild(
			"Gun"
		)

	if CharacterGun
		and CharacterGun:IsA("Tool")
	then

		return CharacterGun
	end

	return nil
end

--============================================================
-- SAVE ORIGINAL GUN
--============================================================

local function SaveOriginalGun(
	Gun
)

	if not Gun
		or SavedGunState[Gun]
	then

		return false
	end

	local Handle =
		Gun:FindFirstChild(
			"Handle"
		)

	if not Handle
		or not Handle:IsA("BasePart")
	then

		return false
	end

	local Mesh =
		Handle:FindFirstChildOfClass(
			"SpecialMesh"
		)

	if not Mesh then
		return false
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

	return true
end

--============================================================
-- VISIBLE MM2 HOTBAR
--
-- Actual visible path previously confirmed:
--
-- PlayerGui
--   BackpackUI
--     BackpackFrame
--       BackpackItem
--         Container
--           ToolIcon
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

	local Success =
		pcall(function()

			ToolIcon.Image =
				tostring(
					Image or ""
				)
		end)

	return Success
end

--============================================================
-- FIND LOCAL MM2 GUN DISPLAY
--============================================================

local function GetGunBelt()

	local Character =
		LocalPlayer.Character

	if not Character then
		return nil
	end

	local LowerTorso =
		Character:FindFirstChild(
			"LowerTorso"
		)

	if not LowerTorso then
		return nil
	end

	return LowerTorso:FindFirstChild(
		"GunBelt"
	)
end

local function IsLocalGunDisplay(
	Display
)

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

	for _,Descendant
		in ipairs(
			Display:GetDescendants()
		)
	do

		if Descendant:IsA(
			"RigidConstraint"
		)
		then

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

		if Child.Name
				== "GunDisplay"
			and Child:IsA(
				"BasePart"
			)
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
-- SAVE ORIGINAL HOLSTER
--============================================================

local function SaveOriginalHolster(
	Display
)

	if not Display
		or SavedHolsterState[Display]
	then

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

	SavedHolsterState[Display] = {

		Size =
			Display.Size,

		Transparency =
			Display.Transparency,

		Massless =
			Display.Massless,

		CanCollide =
			Display.CanCollide,

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

	return true
end

--============================================================
-- APPLY GUN SKIN TO HELD / BACKPACK TOOL
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
		Gun:FindFirstChild(
			"Handle"
		)

	if not Handle
		or not Handle:IsA("BasePart")
	then

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

	local Success =
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
				Vector3.new(
					0,
					0,
					0
				)
		end)

	SetVisibleHotbarIcon(
		Skin.Icon
	)

	return Success
end

--============================================================
-- APPLY GUN SKIN TO REAL MM2 HOLSTER
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

	local Mesh =
		Display:FindFirstChildOfClass(
			"SpecialMesh"
		)

	local Attachment =
		Display:FindFirstChildOfClass(
			"Attachment"
		)

	local Success =
		pcall(function()

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
				and Skin.HolsterCFrame
			then

				Attachment.CFrame =
					Skin.HolsterCFrame
			end
		end)

	return Success
end

--============================================================
-- RESTORE GUN
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
		Gun:FindFirstChild(
			"Handle"
		)

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

	local Success =
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

	return Success
end

--============================================================
-- RESTORE HOLSTER
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

	local Success =
		pcall(function()

			Display.Size =
				Original.Size

			Display.Transparency =
				Original.Transparency

			Display.Massless =
				Original.Massless

			Display.CanCollide =
				Original.CanCollide

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

	return Success
end

--============================================================
-- APPLY CURRENT SELECTION
--
-- Silent function.
-- Never sends notifications.
--============================================================

local function ApplyCurrentGunSkin()

	local Selected =
		SkinChanger.SelectedGun

	local Gun =
		GetGun()

	if Selected
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
			Selected
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

SkinChanger.SelectGunSkin =
	SelectGunSkin

--============================================================
-- WINDUI
--
-- IMPORTANT:
-- UI IS CREATED BEFORE ANY PERSISTENCE WATCHERS.
--============================================================

print(
	"[SkinChanger] Creating UI..."
)

local GunSection =
	UI.AddSection(
		UI.SkinChangerPage,
		"Gun",
		"Change the appearance of your gun"
	)

if not GunSection then

	warn(
		"[SkinChanger] Failed to create Gun section"
	)
end

local GunDropdown =
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

			SelectGunSkin(
				Value,
				true
			)
		end
	)

if not GunDropdown then

	warn(
		"[SkinChanger] Failed to create Gun dropdown"
	)
end

local KnifeSection =
	UI.AddSection(
		UI.SkinChangerPage,
		"Knife",
		"Knife skins will be added next"
	)

if not KnifeSection then

	warn(
		"[SkinChanger] Failed to create Knife section"
	)
end

local KnifeDropdown =
	UI.CreateDropdown(
		UI.SkinChangerPage,
		"Knife Skin",
		"Select a knife skin",
		{
			"Default",
		},
		SkinChanger.SelectedKnife,
		function(Value)

			if type(Value)
				== "string"
			then

				SkinChanger.SelectedKnife =
					Value
			end
		end
	)

if not KnifeDropdown then

	warn(
		"[SkinChanger] Failed to create Knife dropdown"
	)
end

print(
	"[SkinChanger] UI created successfully"
)

--============================================================
-- GUN WATCHING
--============================================================

local function WatchGun(
	Gun
)

	if not Gun
		or not Gun:IsA("Tool")
		or Gun.Name ~= "Gun"
	then

		return
	end

	if CurrentGun == Gun then
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
		Gun.AncestryChanged:
		Connect(function()

			task.defer(function()

				task.wait(
					0.05
				)

				if not Gun.Parent then
					return
				end

				if Gun.Parent
						== Backpack
					or Gun.Parent
						== LocalPlayer.Character
				then

					ApplyCurrentGunSkin()
				end
			end)
		end)
	)
end

local function CheckChild(
	Child
)

	if Child
		and Child:IsA("Tool")
		and Child.Name == "Gun"
	then

		WatchGun(
			Child
		)
	end
end

--============================================================
-- CHARACTER WATCHING
--============================================================

local function HookCharacter(
	Character
)

	if not Character then
		return
	end

	Track(
		Character.ChildAdded:
		Connect(function(
			Child
		)

			CheckChild(
				Child
			)
		end)
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

--============================================================
-- WEAPON DISPLAY WATCHING
--============================================================

local HookedWeaponDisplays =
	setmetatable(
		{},
		{
			__mode = "k"
		}
	)

local function HookWeaponDisplays(
	WeaponDisplays
)

	if not WeaponDisplays
		or HookedWeaponDisplays[
			WeaponDisplays
		]
	then

		return
	end

	HookedWeaponDisplays[
		WeaponDisplays
	] = true

	Track(
		WeaponDisplays.DescendantAdded:
		Connect(function()

			if SkinChanger.SelectedGun
				== "Default"
			then

				return
			end

			task.defer(function()

				task.wait(
					0.10
				)

				ApplyCurrentGunSkin()
			end)
		end)
	)
end

--============================================================
-- START WATCHERS
--
-- Protected separately so even if something here fails,
-- the Skin Changer UI remains visible.
--============================================================

local WatcherOK,WatcherError =
	pcall(function()

		-- Backpack
		Track(
			Backpack.ChildAdded:
			Connect(function(
				Child
			)

				CheckChild(
					Child
				)
			end)
		)

		-- Existing character
		if LocalPlayer.Character then

			HookCharacter(
				LocalPlayer.Character
			)
		end

		-- Respawns
		Track(
			LocalPlayer.CharacterAdded:
			Connect(function(
				Character
			)

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
			end)
		)

		-- MM2 visible hotbar rebuild
		Track(
			PlayerGui.DescendantAdded:
			Connect(function(
				Descendant
			)

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
			end)
		)

		-- Existing WeaponDisplays
		local WeaponDisplays =
			Workspace:FindFirstChild(
				"WeaponDisplays"
			)

		if WeaponDisplays then

			HookWeaponDisplays(
				WeaponDisplays
			)
		end

		-- Future WeaponDisplays folders
		Track(
			Workspace.ChildAdded:
			Connect(function(
				Child
			)

				if Child.Name
					~= "WeaponDisplays"
				then

					return
				end

				HookWeaponDisplays(
					Child
				)

				task.defer(function()

					task.wait(
						0.25
					)

					ApplyCurrentGunSkin()
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

	print(
		"[SkinChanger] Watchers started"
	)
end

--============================================================
-- LIGHT PERSISTENCE LOOP
--============================================================

task.spawn(function()

	while MM2.Running do

		task.wait(
			0.25
		)

		local Gun =
			GetGun()

		if Gun
			and Gun ~= CurrentGun
		then

			WatchGun(
				Gun
			)
		end

		if SkinChanger.SelectedGun
			~= "Default"
		then

			pcall(
				ApplyCurrentGunSkin
			)
		end
	end
end)

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

		ApplyCurrentGunSkin()
	end)
end

print(
	"[Blizzard MM2] SkinChanger.lua loaded"
)

return MM2