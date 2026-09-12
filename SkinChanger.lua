--====================================================================
-- BLIZZARD MM2 V8.8.4 - SkinChanger.lua
--
-- Client-side cosmetic skin changer.
--
-- Current skins:
--   Gun:
--     Default
--     Harvester
--
-- Includes:
--   • WindUI Skin Changer page
--   • Harvester held-gun appearance
--   • MM2 GunDisplay holster appearance
--   • BackpackUI hotbar icon
--   • Round / respawn persistence
--   • Automatic silent reapplication
--   • Restore to Default
--   • Palette WindUI notifications
--====================================================================

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

--====================================================================
-- REFERENCES
--====================================================================

local UI =
	MM2.UI

local Players =
	MM2.Services.Players

local Workspace =
	workspace

local LocalPlayer =
	MM2.LocalPlayer

local PlayerGui =
	MM2.PlayerGui

--====================================================================
-- SKIN CHANGER STATE
--====================================================================

MM2.SkinChanger =
	MM2.SkinChanger or {}

local SkinChanger =
	MM2.SkinChanger

SkinChanger.SelectedGun =
	SkinChanger.SelectedGun
	or "Default"

SkinChanger.SelectedKnife =
	SkinChanger.SelectedKnife
	or "Default"

--====================================================================
-- HARVESTER DATA
--====================================================================

local HARVESTER = {

	Icon =
		"http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=7800847534",

	MeshId =
		"rbxassetid://7775027413",

	TextureId =
		"http://www.roblox.com/asset/?id=7775245551",

	HandleSize =
		Vector3.new(
			2.244760036468506,
			0.6549199819564819,
			2.880000114440918
		),

	MeshScale =
		Vector3.new(
			0.05072519928216934,
			0.05072552338242531,
			0.05069168284535408
		),

	-- Exact grip captured from the working client changer.
	Grip =
		CFrame.new(
			0,
			-0.699999988,
			-0.300000012,

			1, 0, 0,
			0, 1, 4.37113883e-08,
			0, -4.37113883e-08, 1
		),

	-- Exact Harvester GunBelt attachment captured from MM2.
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

--====================================================================
-- SAVED ORIGINAL STATE
--====================================================================

local SavedGuns = {}
local SavedDisplays = {}

local DefaultGunIcon = nil

local CreatedDisplay = nil

--====================================================================
-- NOTIFICATION
--====================================================================

local function NotifySkin(
	message
)

	pcall(function()

		UI.WindUI:Notify({
			Title =
				"Skin Changer",

			Content =
				tostring(message),

			Icon =
				"palette",

			Duration =
				2.5,
		})
	end)
end

--====================================================================
-- CHARACTER HELPERS
--====================================================================

local function GetCharacter()

	return LocalPlayer.Character
end

local function GetBackpack()

	return LocalPlayer:
		FindFirstChildOfClass(
			"Backpack"
		)
end

local function GetGunBelt()

	local Character =
		GetCharacter()

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

	return LowerTorso:
		FindFirstChild(
			"GunBelt"
		)
end

--====================================================================
-- FIND CURRENT GUN
--====================================================================

local function GetGun()

	local Character =
		GetCharacter()

	if Character then

		local Gun =
			Character:
			FindFirstChild(
				"Gun"
			)

		if Gun
			and Gun:IsA("Tool")
		then

			return Gun
		end
	end

	local Backpack =
		GetBackpack()

	if Backpack then

		local Gun =
			Backpack:
			FindFirstChild(
				"Gun"
			)

		if Gun
			and Gun:IsA("Tool")
		then

			return Gun
		end
	end

	return nil
end

--====================================================================
-- SAVE ORIGINAL GUN
--====================================================================

local function SaveGun(
	Gun
)

	if SavedGuns[Gun] then
		return
	end

	local Handle =
		Gun:FindFirstChild(
			"Handle"
		)

	if not Handle
		or not Handle:IsA(
			"BasePart"
		)
	then

		return
	end

	local Mesh =
		Handle:
		FindFirstChildOfClass(
			"SpecialMesh"
		)

	if not DefaultGunIcon
		and Gun.TextureId
		and Gun.TextureId ~= ""
	then

		DefaultGunIcon =
			Gun.TextureId
	end

	SavedGuns[Gun] = {

		TextureId =
			Gun.TextureId,

		Grip =
			Gun.Grip,

		Handle =
			Handle,

		HandleSize =
			Handle.Size,

		HandleTransparency =
			Handle.Transparency,

		MeshOriginallyExisted =
			Mesh ~= nil,

		MeshId =
			Mesh
			and Mesh.MeshId
			or nil,

		MeshTexture =
			Mesh
			and Mesh.TextureId
			or nil,

		MeshScale =
			Mesh
			and Mesh.Scale
			or nil,

		MeshOffset =
			Mesh
			and Mesh.Offset
			or nil,

		MeshType =
			Mesh
			and Mesh.MeshType
			or nil,
	}
end

--====================================================================
-- APPLY HARVESTER TO HELD / BACKPACK GUN
--====================================================================

local function ApplyHarvesterToGun(
	Gun
)

	if SkinChanger.SelectedGun
		~= "Harvester"
	then

		return false
	end

	if not Gun
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
		or not Handle:IsA(
			"BasePart"
		)
	then

		return false
	end

	SaveGun(
		Gun
	)

	Gun.TextureId =
		HARVESTER.Icon

	Gun.Grip =
		HARVESTER.Grip

	Handle.Size =
		HARVESTER.HandleSize

	Handle.Transparency =
		0

	--============================================================
	-- DEFAULT GUN:
	-- Part + SpecialMesh
	--============================================================

	if Handle:IsA("Part") then

		local Mesh =
			Handle:
			FindFirstChildOfClass(
				"SpecialMesh"
			)

		if not Mesh then

			Mesh =
				Instance.new(
					"SpecialMesh"
				)

			Mesh.Name =
				"Mesh"

			Mesh.Parent =
				Handle
		end

		Mesh.MeshType =
			Enum.MeshType.FileMesh

		Mesh.MeshId =
			HARVESTER.MeshId

		Mesh.TextureId =
			HARVESTER.TextureId

		Mesh.Scale =
			HARVESTER.MeshScale

		Mesh.Offset =
			Vector3.zero

	--============================================================
	-- MESH PART FALLBACK
	--============================================================

	elseif Handle:IsA(
		"MeshPart"
	) then

		pcall(function()

			Handle.MeshId =
				HARVESTER.MeshId

			Handle.TextureID =
				HARVESTER.TextureId
		end)
	end

	return true
end

--====================================================================
-- RESTORE ORIGINAL GUN
--====================================================================

local function RestoreGun(
	Gun
)

	local Data =
		SavedGuns[Gun]

	if not Data then
		return
	end

	if Gun
		and Gun.Parent
	then

		pcall(function()

			Gun.TextureId =
				Data.TextureId

			Gun.Grip =
				Data.Grip
		end)
	end

	local Handle =
		Data.Handle

	if Handle
		and Handle.Parent
	then

		Handle.Size =
			Data.HandleSize

		Handle.Transparency =
			Data.HandleTransparency

		if Handle:IsA(
			"Part"
		) then

			local Mesh =
				Handle:
				FindFirstChildOfClass(
					"SpecialMesh"
				)

			if Data.MeshOriginallyExisted then

				if not Mesh then

					Mesh =
						Instance.new(
							"SpecialMesh"
						)

					Mesh.Name =
						"Mesh"

					Mesh.Parent =
						Handle
				end

				Mesh.MeshId =
					Data.MeshId
					or ""

				Mesh.TextureId =
					Data.MeshTexture
					or ""

				Mesh.Scale =
					Data.MeshScale
					or Vector3.one

				Mesh.Offset =
					Data.MeshOffset
					or Vector3.zero

				if Data.MeshType then

					Mesh.MeshType =
						Data.MeshType
				end

			elseif Mesh then

				Mesh:Destroy()
			end
		end
	end

	SavedGuns[Gun] =
		nil
end

--====================================================================
-- RESTORE ALL SAVED GUNS
--====================================================================

local function RestoreAllGuns()

	local List = {}

	for Gun in pairs(
		SavedGuns
	) do

		table.insert(
			List,
			Gun
		)
	end

	for _,Gun in ipairs(
		List
	) do

		RestoreGun(
			Gun
		)
	end
end

--====================================================================
-- VISIBLE MM2 HOTBAR ICON
--
-- Confirmed path:
--
-- PlayerGui
--   BackpackUI
--     BackpackFrame
--       BackpackItem
--         Container
--           ToolIcon
--====================================================================

local function GetVisibleToolIcons()

	local Results = {}

	local BackpackUI =
		PlayerGui:
		FindFirstChild(
			"BackpackUI"
		)

	if not BackpackUI then
		return Results
	end

	for _,Object in ipairs(
		BackpackUI:GetDescendants()
	) do

		if Object.Name ==
			"ToolIcon"
			and (
				Object:IsA("ImageLabel")
				or Object:IsA("ImageButton")
			)
		then

			table.insert(
				Results,
				Object
			)
		end
	end

	return Results
end

local function UpdateHotbarIcon()

	local DesiredIcon

	if SkinChanger.SelectedGun
		== "Harvester"
	then

		DesiredIcon =
			HARVESTER.Icon

	else

		DesiredIcon =
			DefaultGunIcon

		if not DesiredIcon then

			local Gun =
				GetGun()

			if Gun then

				local Saved =
					SavedGuns[Gun]

				if Saved
					and Saved.TextureId
				then

					DesiredIcon =
						Saved.TextureId

				elseif Gun.TextureId
					~= HARVESTER.Icon
				then

					DesiredIcon =
						Gun.TextureId
				end
			end
		end
	end

	if not DesiredIcon
		or DesiredIcon == ""
	then

		return
	end

	for _,Icon in ipairs(
		GetVisibleToolIcons()
	) do

		pcall(function()

			Icon.Image =
				DesiredIcon
		end)
	end
end

--====================================================================
-- OPTIONAL ROBLOX CORE HOTBAR ICON
--
-- This one wasn't the visible MM2 icon in our test,
-- but updating it doesn't hurt.
--====================================================================

local function UpdateCoreHotbar()

	local CoreGui =
		MM2.Services.CoreGui

	if not CoreGui then
		return
	end

	local DesiredIcon =
		SkinChanger.SelectedGun
			== "Harvester"
			and HARVESTER.Icon
			or DefaultGunIcon

	if not DesiredIcon then
		return
	end

	pcall(function()

		local RobloxGui =
			CoreGui:
			FindFirstChild(
				"RobloxGui"
			)

		local Backpack =
			RobloxGui
			and RobloxGui:
				FindFirstChild(
					"Backpack"
				)

		local Hotbar =
			Backpack
			and Backpack:
				FindFirstChild(
					"Hotbar"
				)

		if not Hotbar then
			return
		end

		for _,Object in ipairs(
			Hotbar:GetDescendants()
		) do

			if Object.Name ==
				"Icon"
				and (
					Object:IsA(
						"ImageLabel"
					)
					or Object:IsA(
						"ImageButton"
					)
				)
			then

				Object.Image =
					DesiredIcon
			end
		end
	end)
end

--====================================================================
-- FIND LOCAL MM2 GUNDISPLAY
--====================================================================

local function FindLocalGunDisplay()

	local GunBelt =
		GetGunBelt()

	if not GunBelt then
		return nil
	end

	local WeaponDisplays =
		Workspace:
		FindFirstChild(
			"WeaponDisplays"
		)

	if not WeaponDisplays then
		return nil
	end

	-- Multiple GunDisplay objects may exist.
	-- Match the RigidConstraint that actually references
	-- our character's GunBelt.
	for _,Object in ipairs(
		WeaponDisplays:GetDescendants()
	) do

		if Object:IsA(
			"RigidConstraint"
		) then

			local A0 =
				Object.Attachment0

			local A1 =
				Object.Attachment1

			local UsesOurGunBelt =
				A0 == GunBelt
				or A1 == GunBelt

			if UsesOurGunBelt then

				local Parent =
					Object.Parent

				if Parent
					and Parent:IsA(
						"BasePart"
					)
				then

					return
						Parent,
						Object
				end
			end
		end
	end

	return nil
end

--====================================================================
-- SAVE ORIGINAL GUNDISPLAY
--====================================================================

local function SaveDisplay(
	Display
)

	if SavedDisplays[Display] then
		return
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

	SavedDisplays[Display] = {

		Size =
			Display.Size,

		Transparency =
			Display.Transparency,

		Massless =
			Display.Massless,

		CanCollide =
			Display.CanCollide,

		MeshOriginallyExisted =
			Mesh ~= nil,

		MeshId =
			Mesh
			and Mesh.MeshId
			or nil,

		MeshTexture =
			Mesh
			and Mesh.TextureId
			or nil,

		MeshScale =
			Mesh
			and Mesh.Scale
			or nil,

		MeshOffset =
			Mesh
			and Mesh.Offset
			or nil,

		MeshType =
			Mesh
			and Mesh.MeshType
			or nil,

		Attachment =
			Attachment,

		AttachmentCFrame =
			Attachment
			and Attachment.CFrame
			or nil,
	}
end

--====================================================================
-- FALLBACK LOCAL HOLSTER
--
-- Used only if MM2 hasn't created its actual GunDisplay yet.
-- Once the real display appears, this gets removed automatically.
--====================================================================

local function CreateFallbackDisplay()

	if SkinChanger.SelectedGun
		~= "Harvester"
	then

		return nil
	end

	if CreatedDisplay
		and CreatedDisplay.Parent
	then

		return CreatedDisplay
	end

	local GunBelt =
		GetGunBelt()

	if not GunBelt then
		return nil
	end

	local Character =
		GetCharacter()

	if not Character then
		return nil
	end

	local Part =
		Instance.new(
			"Part"
		)

	Part.Name =
		"BlizzardHarvesterDisplay"

	Part.Size =
		HARVESTER.HandleSize

	Part.Transparency =
		0

	Part.Anchored =
		false

	Part.Massless =
		true

	Part.CanCollide =
		false

	Part.CanTouch =
		false

	Part.CanQuery =
		false

	local Mesh =
		Instance.new(
			"SpecialMesh"
		)

	Mesh.Name =
		"Mesh"

	Mesh.MeshType =
		Enum.MeshType.FileMesh

	Mesh.MeshId =
		HARVESTER.MeshId

	Mesh.TextureId =
		HARVESTER.TextureId

	Mesh.Scale =
		HARVESTER.MeshScale

	Mesh.Parent =
		Part

	local Attachment =
		Instance.new(
			"Attachment"
		)

	Attachment.Name =
		"Attachment"

	Attachment.CFrame =
		HARVESTER.HolsterCFrame

	Attachment.Parent =
		Part

	local Constraint =
		Instance.new(
			"RigidConstraint"
		)

	Constraint.Attachment0 =
		GunBelt

	Constraint.Attachment1 =
		Attachment

	Constraint.Parent =
		Part

	Part.Parent =
		Character

	CreatedDisplay =
		Part

	return Part
end

--====================================================================
-- APPLY HARVESTER TO REAL GUNDISPLAY
--====================================================================

local function ApplyHarvesterHolster()

	if SkinChanger.SelectedGun
		~= "Harvester"
	then

		return false
	end

	local Display =
		FindLocalGunDisplay()

	if not Display then

		return
			CreateFallbackDisplay()
			~= nil
	end

	-- Real MM2 display now exists.
	-- Remove temporary fallback.
	if CreatedDisplay then

		pcall(function()

			CreatedDisplay:
				Destroy()
		end)

		CreatedDisplay =
			nil
	end

	SaveDisplay(
		Display
	)

	Display.Size =
		HARVESTER.HandleSize

	Display.Transparency =
		0

	Display.Massless =
		true

	Display.CanCollide =
		false

	local Mesh =
		Display:
		FindFirstChildOfClass(
			"SpecialMesh"
		)

	if not Mesh then

		Mesh =
			Instance.new(
				"SpecialMesh"
			)

		Mesh.Name =
			"Mesh"

		Mesh.Parent =
			Display
	end

	Mesh.MeshType =
		Enum.MeshType.FileMesh

	Mesh.MeshId =
		HARVESTER.MeshId

	Mesh.TextureId =
		HARVESTER.TextureId

	Mesh.Scale =
		HARVESTER.MeshScale

	Mesh.Offset =
		Vector3.zero

	local Attachment =
		Display:
		FindFirstChildOfClass(
			"Attachment"
		)

	if not Attachment then

		Attachment =
			Instance.new(
				"Attachment"
			)

		Attachment.Name =
			"Attachment"

		Attachment.Parent =
			Display
	end

	Attachment.CFrame =
		HARVESTER.HolsterCFrame

	return true
end

--====================================================================
-- RESTORE GUNDISPLAYS
--====================================================================

local function RestoreDisplays()

	if CreatedDisplay then

		pcall(function()

			CreatedDisplay:
				Destroy()
		end)

		CreatedDisplay =
			nil
	end

	for Display,Data in pairs(
		SavedDisplays
	) do

		if Display
			and Display.Parent
		then

			pcall(function()

				Display.Size =
					Data.Size

				Display.Transparency =
					Data.Transparency

				Display.Massless =
					Data.Massless

				Display.CanCollide =
					Data.CanCollide

				local Mesh =
					Display:
					FindFirstChildOfClass(
						"SpecialMesh"
					)

				if Data.MeshOriginallyExisted then

					if not Mesh then

						Mesh =
							Instance.new(
								"SpecialMesh"
							)

						Mesh.Name =
							"Mesh"

						Mesh.Parent =
							Display
					end

					Mesh.MeshId =
						Data.MeshId
						or ""

					Mesh.TextureId =
						Data.MeshTexture
						or ""

					Mesh.Scale =
						Data.MeshScale
						or Vector3.one

					Mesh.Offset =
						Data.MeshOffset
						or Vector3.zero

					if Data.MeshType then

						Mesh.MeshType =
							Data.MeshType
					end

				elseif Mesh then

					Mesh:
						Destroy()
				end

				if Data.Attachment
					and Data.Attachment.Parent
					and Data.AttachmentCFrame
				then

					Data.Attachment.CFrame =
						Data.AttachmentCFrame
				end
			end)
		end
	end

	table.clear(
		SavedDisplays
	)
end

--====================================================================
-- APPLY CURRENT SELECTED GUN SKIN
--
-- IMPORTANT:
-- NO notification here.
--
-- This function can run repeatedly in the background without
-- notification spam.
--====================================================================

local function ApplySelectedGunSkin()

	if SkinChanger.SelectedGun
		== "Harvester"
	then

		local Gun =
			GetGun()

		if Gun then

			ApplyHarvesterToGun(
				Gun
			)
		end

		ApplyHarvesterHolster()

		UpdateHotbarIcon()
		UpdateCoreHotbar()
	end
end

--====================================================================
-- SELECT GUN SKIN
--
-- Notifications happen HERE only.
--====================================================================

local function SelectGunSkin(
	SkinName,
	ShowNotification
)

	SkinName =
		tostring(
			SkinName
			or "Default"
		)

	if SkinName ==
		SkinChanger.SelectedGun
	then

		-- Same selection.
		-- Refresh silently instead.
		ApplySelectedGunSkin()

		return
	end

	--============================================================
	-- DEFAULT
	--============================================================

	if SkinName ==
		"Default"
	then

		SkinChanger.SelectedGun =
			"Default"

		RestoreAllGuns()
		RestoreDisplays()

		UpdateHotbarIcon()
		UpdateCoreHotbar()

		if ShowNotification then

			NotifySkin(
				"Default Gun Equipped"
			)
		end

		return
	end

	--============================================================
	-- HARVESTER
	--============================================================

	if SkinName ==
		"Harvester"
	then

		SkinChanger.SelectedGun =
			"Harvester"

		ApplySelectedGunSkin()

		if ShowNotification then

			NotifySkin(
				"Harvester Equipped"
			)
		end

		return
	end
end

-- Expose useful functions for future skins.
SkinChanger.SelectGunSkin =
	SelectGunSkin

SkinChanger.Refresh =
	ApplySelectedGunSkin

--====================================================================
-- BACKPACK WATCHER
--====================================================================

local CurrentBackpackConnection =
	nil

local function WatchBackpack()

	if CurrentBackpackConnection then

		CurrentBackpackConnection:
			Disconnect()

		CurrentBackpackConnection =
			nil
	end

	local Backpack =
		GetBackpack()

	if not Backpack then
		return
	end

	CurrentBackpackConnection =
		Backpack.ChildAdded:
		Connect(function(
			Child
		)

			if SkinChanger.SelectedGun
				~= "Harvester"
			then

				return
			end

			if Child:IsA("Tool")
				and Child.Name == "Gun"
			then

				task.defer(function()

					if Child.Parent
						and SkinChanger.SelectedGun
							== "Harvester"
					then

						ApplyHarvesterToGun(
							Child
						)

						ApplyHarvesterHolster()

						UpdateHotbarIcon()
					end
				end)
			end
		end)
end

--====================================================================
-- CHARACTER WATCHER
--====================================================================

local CurrentCharacterConnection =
	nil

local function WatchCharacter(
	Character
)

	if CurrentCharacterConnection then

		CurrentCharacterConnection:
			Disconnect()

		CurrentCharacterConnection =
			nil
	end

	if not Character then
		return
	end

	CurrentCharacterConnection =
		Character.ChildAdded:
		Connect(function(
			Child
		)

			if SkinChanger.SelectedGun
				~= "Harvester"
			then

				return
			end

			if Child:IsA("Tool")
				and Child.Name == "Gun"
			then

				task.defer(function()

					if Child.Parent
						and SkinChanger.SelectedGun
							== "Harvester"
					then

						ApplyHarvesterToGun(
							Child
						)

						ApplyHarvesterHolster()

						UpdateHotbarIcon()
					end
				end)
			end
		end)

	task.delay(
		0.75,
		function()

			if SkinChanger.SelectedGun
				== "Harvester"
			then

				ApplySelectedGunSkin()
			end
		end
	)
end

WatchBackpack()

if LocalPlayer.Character then

	WatchCharacter(
		LocalPlayer.Character
	)
end

MM2.Track(
	LocalPlayer.CharacterAdded:
	Connect(function(
		Character
	)

		-- Round ending / respawn can rebuild everything.
		task.wait(
			0.25
		)

		WatchBackpack()

		WatchCharacter(
			Character
		)

		if SkinChanger.SelectedGun
			== "Harvester"
		then

			task.wait(
				0.75
			)

			ApplySelectedGunSkin()
		end
	end)
)

--====================================================================
-- BACKPACK UI REBUILD WATCHER
--
-- MM2 destroys/recreates ToolIcon at times.
-- Reapply the selected skin icon whenever it comes back.
--====================================================================

MM2.Track(
	PlayerGui.DescendantAdded:
	Connect(function(
		Object
	)

		if SkinChanger.SelectedGun
			~= "Harvester"
		then

			return
		end

		if Object.Name ==
			"ToolIcon"
			and (
				Object:IsA("ImageLabel")
				or Object:IsA("ImageButton")
			)
		then

			task.defer(function()

				if Object.Parent
					and SkinChanger.SelectedGun
						== "Harvester"
				then

					Object.Image =
						HARVESTER.Icon
				end
			end)
		end
	end)
)

--====================================================================
-- WEAPON DISPLAY WATCHER
--====================================================================

MM2.Track(
	Workspace.ChildAdded:
	Connect(function(
		Child
	)

		if SkinChanger.SelectedGun
			~= "Harvester"
		then

			return
		end

		if Child.Name ==
			"WeaponDisplays"
		then

			task.delay(
				0.4,
				function()

					if SkinChanger.SelectedGun
						== "Harvester"
					then

						ApplyHarvesterHolster()
					end
				end
			)
		end
	end)
)

local function WatchWeaponDisplays(
	WeaponDisplays
)

	if not WeaponDisplays then
		return
	end

	MM2.Track(
		WeaponDisplays.DescendantAdded:
		Connect(function()

			if SkinChanger.SelectedGun
				~= "Harvester"
			then

				return
			end

			task.defer(function()

				if SkinChanger.SelectedGun
					== "Harvester"
				then

					ApplyHarvesterHolster()
				end
			end)
		end)
end

WatchWeaponDisplays(
	Workspace:
	FindFirstChild(
		"WeaponDisplays"
	)
)

MM2.Track(
	Workspace.ChildAdded:
	Connect(function(
		Child
	)

		if Child.Name ==
			"WeaponDisplays"
		then

			WatchWeaponDisplays(
				Child
			)
		end
	end)
)

--====================================================================
-- LIGHT PERSISTENCE LOOP
--
-- This handles MM2 silently rebuilding the Gun / GunDisplay
-- between rounds.
--
-- NO notifications here.
--====================================================================

task.spawn(function()

	while MM2.Running do

		task.wait(
			0.25
		)

		if SkinChanger.SelectedGun
			== "Harvester"
		then

			ApplySelectedGunSkin()
		end
	end
end)

--====================================================================
-- WINDUI
--====================================================================

UI.AddSection(
	UI.SkinChangerPage,
	"Gun",
	"Change the appearance of your gun"
)

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
		function(
			Value
		)

			if typeof(Value)
				~= "string"
			then

				return
			end

			SelectGunSkin(
				Value,
				true
			)
		end
	)

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
	SkinChanger.SelectedKnife,
	function(
		Value
	)

		if typeof(Value)
			== "string"
		then

			SkinChanger.SelectedKnife =
				Value
		end
	end
)

--====================================================================
-- INITIAL REFRESH
--
-- If SkinChanger.lua gets reloaded while Harvester was already
-- selected, restore the visible appearance without notifying.
--====================================================================

task.defer(function()

	if SkinChanger.SelectedGun
		== "Harvester"
	then

		ApplySelectedGunSkin()
	end
end)

print(
	"[Blizzard MM2] SkinChanger.lua loaded"
)

return MM2