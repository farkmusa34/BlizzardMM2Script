--============================================================
-- MM2 V8.8.4 STABLE - Fling.lua
-- WindUI dropdown migration + existing fling logic
--============================================================

local MM2 = getgenv and getgenv().MM2_V85_SPLIT or _G.MM2_V85_SPLIT
assert(MM2 and MM2.UI and MM2.UI.FlingPage, "Load Shared.lua + UI.lua first")

local Players = MM2.Services.Players
local RunService = MM2.Services.RunService
local LocalPlayer = MM2.LocalPlayer
local UI = MM2.UI
local Track = MM2.Track

UI.AddSection(
	UI.FlingPage,
	"One-Tap Fling Role Actions",
	"Role and selected-player fling actions"
)

local FLING_DURATION = 1.30
local FLING_HUGE = 900000000
local FLING_FORCE_NAME = "MarbegFlingVelocity"

local FLING_POSITION_PATTERN = {
	Vector3.new(0, 1.5, -12.80),
	Vector3.new(0, -1.5, -12.80),
	Vector3.new(2.25, 1.5, -14.80),
	Vector3.new(-2.25, -1.5, -10.80),
	Vector3.new(0, 1.5, -1.00),
	Vector3.new(0, -1.5, -1.00),
}

local FlingRunning = false
local CurrentFlingForce = nil

--============================================================
-- FLING TARGET HELPERS
--============================================================

local function GetTargetFlingCharacter(player)
	if not player then
		return nil
	end

	local character = player.Character

	if not character then
		return nil
	end

	local humanoid =
		character:FindFirstChildOfClass("Humanoid")

	local hrp =
		character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not hrp then
		return nil
	end

	return character,humanoid,hrp
end

--============================================================
-- STOP FLING
--============================================================

local function StopFling()
	FlingRunning = false

	local _,humanoid,hrp =
		MM2.GetLocalCharacter()

	if CurrentFlingForce then
		pcall(function()
			CurrentFlingForce:Destroy()
		end)

		CurrentFlingForce = nil
	end

	if hrp then
		pcall(function()
			hrp.AssemblyLinearVelocity =
				Vector3.zero

			hrp.AssemblyAngularVelocity =
				Vector3.zero
		end)
	end

	if humanoid then
		pcall(function()
			humanoid:ChangeState(
				Enum.HumanoidStateType.GettingUp
			)
		end)
	end
end

MM2.Functions.StopFling = StopFling

--============================================================
-- EXECUTE FLING
--============================================================

local function ExecuteYeet(targetPlayer)
	if FlingRunning then
		MM2.Notify(
			"Fling already running.",
			2
		)

		return
	end

	if not targetPlayer
		or targetPlayer == LocalPlayer
	then
		return
	end

	local character,humanoid,hrp =
		MM2.GetLocalCharacter()

	if not character then
		return
	end

	local targetCharacter,
		targetHumanoid,
		targetHRP =
		GetTargetFlingCharacter(
			targetPlayer
		)

	if not targetCharacter then
		MM2.Notify(
			"Target character unavailable.",
			2
		)

		return
	end

	FlingRunning = true

	local originalCFrame =
		hrp.CFrame

	local oldForce =
		hrp:FindFirstChild(
			FLING_FORCE_NAME
		)

	if oldForce then
		oldForce:Destroy()
	end

	local force =
		Instance.new("BodyVelocity")

	force.Name =
		FLING_FORCE_NAME

	force.Velocity =
		Vector3.new(
			FLING_HUGE,
			FLING_HUGE,
			FLING_HUGE
		)

	force.MaxForce =
		Vector3.new(
			math.huge,
			math.huge,
			math.huge
		)

	force.P = 1250
	force.Parent = hrp

	CurrentFlingForce = force

	hrp.AssemblyAngularVelocity =
		Vector3.new(
			FLING_HUGE,
			FLING_HUGE,
			FLING_HUGE
		)

	local startTime = os.clock()
	local frame = 0
	local patternIndex = 1
	local velocityPhase = 1

	while FlingRunning
		and os.clock() - startTime
			< FLING_DURATION
	do
		targetCharacter,
		targetHumanoid,
		targetHRP =
			GetTargetFlingCharacter(
				targetPlayer
			)

		if not targetHRP then
			break
		end

		frame += 1

		local offset =
			FLING_POSITION_PATTERN[
				patternIndex
			]

		hrp.CFrame =
			targetHRP.CFrame
			* CFrame.new(
				offset.X,
				offset.Y,
				offset.Z
			)

		local phase =
			math.floor(
				(frame - 1) / 6
			) % 3

		if phase == 0 then
			hrp.CFrame =
				CFrame.new(
					hrp.Position
				)
				* CFrame.Angles(
					0,
					math.rad(
						targetHRP.Orientation.Y
					),
					0
				)

		elseif phase == 1 then
			hrp.CFrame =
				CFrame.new(
					hrp.Position
				)
				* CFrame.Angles(
					math.rad(-60),
					math.rad(180),
					math.rad(180)
				)

		else
			hrp.CFrame =
				CFrame.new(
					hrp.Position
				)
				* CFrame.Angles(
					math.rad(60),
					math.rad(180),
					math.rad(180)
				)
		end

		hrp.AssemblyAngularVelocity =
			Vector3.new(
				FLING_HUGE,
				FLING_HUGE,
				FLING_HUGE
			)

		if velocityPhase == 1 then
			hrp.AssemblyLinearVelocity =
				Vector3.new(
					387791264,
					919603648,
					-227394880
				)

		elseif velocityPhase == 2 then
			hrp.AssemblyLinearVelocity =
				Vector3.new(
					233146464,
					615062400,
					231791104
				)

		else
			hrp.AssemblyLinearVelocity =
				Vector3.new(
					-350938112,
					1164999296,
					265938784
				)
		end

		patternIndex += 1

		if patternIndex
			> #FLING_POSITION_PATTERN
		then
			patternIndex = 1
			velocityPhase += 1

			if velocityPhase > 3 then
				velocityPhase = 1
			end
		end

		RunService.Heartbeat:Wait()
	end

	if CurrentFlingForce then
		pcall(function()
			CurrentFlingForce:Destroy()
		end)

		CurrentFlingForce = nil
	end

	pcall(function()
		hrp.AssemblyLinearVelocity =
			Vector3.zero

		hrp.AssemblyAngularVelocity =
			Vector3.zero

		hrp.CFrame =
			originalCFrame

		hrp.AssemblyLinearVelocity =
			Vector3.zero

		hrp.AssemblyAngularVelocity =
			Vector3.zero
	end)

	pcall(function()
		humanoid:ChangeState(
			Enum.HumanoidStateType.GettingUp
		)
	end)

	FlingRunning = false
end

MM2.Functions.ExecuteYeet = ExecuteYeet

--============================================================
-- ROLE FLING HELPERS
--============================================================

local function FlingRole(role,label)
	for _,player in ipairs(
		Players:GetPlayers()
	) do
		if player ~= LocalPlayer
			and MM2.State.ServerRolesCache[
				player.Name
			] == role
		then
			task.spawn(function()
				ExecuteYeet(player)
			end)

			return
		end
	end

	MM2.Notify(
		"No "..label.." target found.",
		2
	)
end

local function FlingSheriffOrHero()
	for _,player in ipairs(
		Players:GetPlayers()
	) do
		if player ~= LocalPlayer
			and MM2.State.ServerRolesCache[
				player.Name
			] == "Sheriff"
		then
			task.spawn(function()
				ExecuteYeet(player)
			end)

			return
		end
	end

	for _,player in ipairs(
		Players:GetPlayers()
	) do
		if player ~= LocalPlayer
			and MM2.State.ServerRolesCache[
				player.Name
			] == "Hero"
		then
			task.spawn(function()
				ExecuteYeet(player)
			end)

			return
		end
	end

	MM2.Notify(
		"No sheriff/hero target found.",
		2
	)
end

--============================================================
-- ONE-TAP ROLE ACTIONS
--============================================================

UI.CreateActionFeature(
	UI.FlingPage,
	"Fling Murderer",
	"Flings the current murderer",
	function()
		FlingRole(
			"Murderer",
			"murderer"
		)
	end
)

UI.CreateActionFeature(
	UI.FlingPage,
	"Fling Sheriff",
	"Flings the current sheriff",
	function()
		FlingRole(
			"Sheriff",
			"sheriff"
		)
	end
)

UI.CreateActionFeature(
	UI.FlingPage,
	"Fling Hero",
	"Flings the current hero",
	function()
		FlingRole(
			"Hero",
			"hero"
		)
	end
)

--============================================================
-- ORIGINAL MOVABLE ROLE BUTTONS
--============================================================

if UI.CreateMovableCircleButton then

	local FloatingFlingSheriffButton,
		FloatingFlingSheriffHolder =
		UI.CreateMovableCircleButton(
			"FloatingFlingSheriff",
			"",
			"fling sheriff/hero",
			UDim2.new(
				0.78,
				-52,
				0.78,
				-42
			),
			function()
				FlingSheriffOrHero()
			end
		)

	FloatingFlingSheriffHolder.Visible =
		false

	MM2.UI.FloatingFlingSheriffButton =
		FloatingFlingSheriffButton

	MM2.UI.FloatingFlingSheriffHolder =
		FloatingFlingSheriffHolder

	local FloatingFlingMurdererButton,
		FloatingFlingMurdererHolder =
		UI.CreateMovableCircleButton(
			"FloatingFlingMurderer",
			"",
			"fling murderer",
			UDim2.new(
				0.89,
				-52,
				0.78,
				-42
			),
			function()
				FlingRole(
					"Murderer",
					"murderer"
				)
			end
		)

	FloatingFlingMurdererHolder.Visible =
		false

	MM2.UI.FloatingFlingMurdererButton =
		FloatingFlingMurdererButton

	MM2.UI.FloatingFlingMurdererHolder =
		FloatingFlingMurdererHolder
end

--============================================================
-- FLAGS
--============================================================

local Flags = MM2.Flags

Flags.ShowFlingMurdererButton =
	Flags.ShowFlingMurdererButton == true

Flags.ShowFlingSheriffButton =
	Flags.ShowFlingSheriffButton == true

Flags.AntiFling =
	Flags.AntiFling == true

Flags.FlingNotify =
	Flags.FlingNotify == true

--============================================================
-- ANTI FLING CONSTANTS
--============================================================

local ANTI_FLING_LINEAR_LIMIT = 80
local ANTI_FLING_ANGULAR_LIMIT = 25

local FLING_NOTIFY_LINEAR_LIMIT = 220
local FLING_NOTIFY_ANGULAR_LIMIT = 45
local FLING_NOTIFY_NEAR_DISTANCE = 10
local FLING_NOTIFY_CONFIRM_TIME = 0.06
local FLING_NOTIFY_COOLDOWN = 4

local AntiFlingCollisionOriginal = {}
local FlingNotifySuspiciousSince = {}
local FlingNotifyLastAlert = {}

--============================================================
-- ANTI FLING COLLISION
--============================================================

local function RestoreAntiFlingPlayerCollisions()
	for part,oldCanCollide in pairs(
		AntiFlingCollisionOriginal
	) do
		if part and part.Parent then
			pcall(function()
				part.CanCollide =
					oldCanCollide
			end)
		end
	end

	table.clear(
		AntiFlingCollisionOriginal
	)
end

local function DisableOtherPlayerCollisions()
	for _,player in ipairs(
		Players:GetPlayers()
	) do
		if player ~= LocalPlayer then
			local character =
				player.Character

			if character then
				for _,part in ipairs(
					character:GetDescendants()
				) do
					if part:IsA("BasePart") then

						if AntiFlingCollisionOriginal[
							part
						] == nil
						then
							AntiFlingCollisionOriginal[
								part
							] =
								part.CanCollide
						end

						part.CanCollide =
							false
					end
				end
			end
		end
	end
end

--============================================================
-- ANTI FLING VELOCITY
--============================================================

local function KillLocalFlingVelocity(
	character,
	humanoid,
	hrp
)
	if not character or not hrp then
		return
	end

	local killedLinear = false

	for _,part in ipairs(
		character:GetDescendants()
	) do
		if part:IsA("BasePart") then

			if part.AssemblyAngularVelocity.Magnitude
				> ANTI_FLING_ANGULAR_LIMIT
			then
				part.AssemblyAngularVelocity =
					Vector3.zero
			end

			if not Flags.Fly
				and part.AssemblyLinearVelocity.Magnitude
					> ANTI_FLING_LINEAR_LIMIT
			then
				part.AssemblyLinearVelocity =
					Vector3.zero

				part.AssemblyAngularVelocity =
					Vector3.zero

				killedLinear = true
			end
		end
	end

	hrp.AssemblyAngularVelocity =
		Vector3.zero

	if killedLinear
		and humanoid
		and not Flags.Fly
	then
		pcall(function()
			humanoid:ChangeState(
				Enum.HumanoidStateType.GettingUp
			)
		end)
	end
end

--============================================================
-- FLING NOTIFIER
--============================================================

local function GetNearestOtherPlayerTo(
	rootPart,
	excludePlayer
)
	if not rootPart then
		return nil,math.huge
	end

	local nearestPlayer = nil
	local nearestDistance = math.huge

	for _,player in ipairs(
		Players:GetPlayers()
	) do
		if player ~= excludePlayer then
			local character =
				player.Character

			local humanoid =
				character
				and character:
					FindFirstChildOfClass(
						"Humanoid"
					)

			local otherHRP =
				character
				and character:
					FindFirstChild(
						"HumanoidRootPart"
					)

			if humanoid
				and humanoid.Health > 0
				and otherHRP
			then
				local distance =
					(
						otherHRP.Position
						- rootPart.Position
					).Magnitude

				if distance
					< nearestDistance
				then
					nearestDistance =
						distance

					nearestPlayer =
						player
				end
			end
		end
	end

	return nearestPlayer,nearestDistance
end

local function UpdateFlingNotify()
	if not Flags.FlingNotify
		or FlingRunning
	then
		table.clear(
			FlingNotifySuspiciousSince
		)

		return
	end

	local now = os.clock()

	for _,suspect in ipairs(
		Players:GetPlayers()
	) do
		if suspect ~= LocalPlayer then

			local character =
				suspect.Character

			local humanoid =
				character
				and character:
					FindFirstChildOfClass(
						"Humanoid"
					)

			local hrp =
				character
				and character:
					FindFirstChild(
						"HumanoidRootPart"
					)

			if humanoid
				and humanoid.Health > 0
				and hrp
			then
				local linear =
					hrp.AssemblyLinearVelocity.Magnitude

				local angular =
					hrp.AssemblyAngularVelocity.Magnitude

				local victim,distance =
					GetNearestOtherPlayerTo(
						hrp,
						suspect
					)

				local suspicious =
					victim ~= nil
					and distance
						<= FLING_NOTIFY_NEAR_DISTANCE
					and (
						linear
							>= FLING_NOTIFY_LINEAR_LIMIT
						or angular
							>= FLING_NOTIFY_ANGULAR_LIMIT
					)

				if suspicious then

					local since =
						FlingNotifySuspiciousSince[
							suspect
						]

					if not since then
						FlingNotifySuspiciousSince[
							suspect
						] = now

					elseif now - since
						>= FLING_NOTIFY_CONFIRM_TIME
					then
						local lastAlert =
							FlingNotifyLastAlert[
								suspect
							]
							or 0

						if now - lastAlert
							>= FLING_NOTIFY_COOLDOWN
						then
							FlingNotifyLastAlert[
								suspect
							] = now

							if victim
								== LocalPlayer
							then
								MM2.Notify(
									"Possible fling attempt by "
									.. suspect.Name,
									3
								)
							else
								MM2.Notify(
									"Possible fling: "
									.. suspect.Name
									.. " -> "
									.. victim.Name,
									3
								)
							end
						end
					end
				else
					FlingNotifySuspiciousSince[
						suspect
					] = nil
				end
			else
				FlingNotifySuspiciousSince[
					suspect
				] = nil
			end
		end
	end
end

--============================================================
-- ANTI FLING LOOPS
--============================================================

Track(
	RunService.Stepped:Connect(function()

		if not Flags.AntiFling
			or FlingRunning
		then
			if next(
				AntiFlingCollisionOriginal
			) then
				RestoreAntiFlingPlayerCollisions()
			end

			return
		end

		DisableOtherPlayerCollisions()
	end)
)

Track(
	RunService.Heartbeat:Connect(function()

		UpdateFlingNotify()

		if not Flags.AntiFling
			or FlingRunning
		then
			return
		end

		local character,
			humanoid,
			hrp =
			MM2.GetLocalCharacter()

		if not character
			or not hrp
		then
			return
		end

		KillLocalFlingVelocity(
			character,
			humanoid,
			hrp
		)
	end)
)

--============================================================
-- WINDUI PLAYER TARGET DROPDOWN
--============================================================

local function GetPlayerNames()
	local names = {}

	for _,player in ipairs(
		Players:GetPlayers()
	) do
		if player ~= LocalPlayer then
			table.insert(
				names,
				player.Name
			)
		end
	end

	table.sort(names)

	return names
end

local PlayerDropdown

PlayerDropdown =
	UI.CreateDropdown(
		UI.FlingPage,
		"Select Player to Target",
		"Choose which player the selected-player actions target",
		GetPlayerNames(),
		nil,
		function(playerName)

			if typeof(playerName) ~= "string" then
				MM2.State.SelectedFlingTarget =
					nil

				return
			end

			local player =
				Players:FindFirstChild(
					playerName
				)

			if player
				and player ~= LocalPlayer
			then
				MM2.State.SelectedFlingTarget =
					player
			else
				MM2.State.SelectedFlingTarget =
					nil
			end
		end
	)

MM2.UI.PlayerTargetDropdown =
	PlayerDropdown

--============================================================
-- REFRESH TARGET DROPDOWN
--============================================================

local function RefreshPlayerDropdown()

	if not PlayerDropdown then
		return
	end

	local names =
		GetPlayerNames()

	pcall(function()
		PlayerDropdown:Refresh(
			names
		)
	end)

	local selected =
		MM2.State.SelectedFlingTarget

	if selected then
		local stillExists =
			Players:FindFirstChild(
				selected.Name
			)

		if not stillExists then
			MM2.State.SelectedFlingTarget =
				nil
		end
	end
end

--============================================================
-- PLAYER JOIN / LEAVE
--============================================================

Track(
	Players.PlayerAdded:Connect(
		function()
			task.defer(
				RefreshPlayerDropdown
			)
		end
	)
)

Track(
	Players.PlayerRemoving:Connect(
		function(player)

			FlingNotifySuspiciousSince[
				player
			] = nil

			FlingNotifyLastAlert[
				player
			] = nil

			if MM2.State.SelectedFlingTarget
				== player
			then
				MM2.State.SelectedFlingTarget =
					nil
			end

			task.defer(
				RefreshPlayerDropdown
			)
		end
	)
)

--============================================================
-- SELECTED PLAYER ACTIONS
--============================================================

UI.CreateActionFeature(
	UI.FlingPage,
	"Fling Selected Player",
	"Throws the selected player away",
	function()

		local target =
			MM2.State.SelectedFlingTarget

		if not target
			or not target.Parent
		then
			MM2.State.SelectedFlingTarget =
				nil

			MM2.Notify(
				"Select a target first.",
				2
			)

			return
		end

		ExecuteYeet(target)
	end
)

UI.CreateActionFeature(
	UI.FlingPage,
	"Stop Fling",
	"Stops the current fling",
	StopFling
)

UI.CreateActionFeature(
	UI.FlingPage,
	"Refresh Player List",
	"Refreshes the selectable player list",
	function()

		RefreshPlayerDropdown()

		MM2.Notify(
			"Player list refreshed.",
			1.5
		)
	end
)

--============================================================
-- ON SCREEN BUTTONS
--============================================================

UI.AddSection(
	UI.FlingPage,
	"On Screen Buttons",
	"Movable fling controls shown on your screen"
)

UI.CreateToggle(
	UI.FlingPage,
	"Fling Murderer Button",
	"Show the movable fling murderer button",
	"ShowFlingMurdererButton",
	function(on)

		if MM2.UI.FloatingFlingMurdererHolder then
			MM2.UI.FloatingFlingMurdererHolder.Visible =
				on
		end
	end
)

UI.CreateToggle(
	UI.FlingPage,
	"Fling Sheriff/Hero Button",
	"Show the movable fling sheriff/hero button",
	"ShowFlingSheriffButton",
	function(on)

		if MM2.UI.FloatingFlingSheriffHolder then
			MM2.UI.FloatingFlingSheriffHolder.Visible =
				on
		end
	end
)

--============================================================
-- PROTECTION
--============================================================

UI.AddSection(
	UI.FlingPage,
	"Protection",
	"Defensive fling protection"
)

UI.CreateToggle(
	UI.FlingPage,
	"Anti Fling",
	"Prevents you from getting thrown away",
	"AntiFling",
	function(on)

		if not on then
			RestoreAntiFlingPlayerCollisions()
			return
		end

		if FlingRunning then
			return
		end

		DisableOtherPlayerCollisions()

		local character,
			humanoid,
			hrp =
			MM2.GetLocalCharacter()

		if character and hrp then
			KillLocalFlingVelocity(
				character,
				humanoid,
				hrp
			)
		end
	end
)

UI.CreateToggle(
	UI.FlingPage,
	"Fling Notify",
	"Get notified when players attempt to fling you or other players",
	"FlingNotify",
	function(on)

		if not on then
			table.clear(
				FlingNotifySuspiciousSince
			)
		end
	end
)

return MM2