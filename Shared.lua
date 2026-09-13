--============================================================
-- MM2 V8.5 SPLIT BUILD - Shared.lua
-- Shared services/state/helpers/role cache.
--============================================================

--============================================================
-- CLEAN PREVIOUS BLIZZARD INSTANCE
--============================================================

local PreviousMM2 =
	getgenv
	and getgenv().MM2_V85_SPLIT
	or _G.MM2_V85_SPLIT

if PreviousMM2 then

	PreviousMM2.Running = false

	if PreviousMM2.Connections then
		for _,connection in ipairs(
			PreviousMM2.Connections
		) do
			pcall(function()
				connection:Disconnect()
			end)
		end
	end

	if PreviousMM2.Functions then

		if PreviousMM2.Functions.ClearPlayerESP then
			pcall(
				PreviousMM2.Functions.ClearPlayerESP
			)
		end

		if PreviousMM2.Functions.ClearGunESP then
			pcall(
				PreviousMM2.Functions.ClearGunESP
			)
		end

		if PreviousMM2.Functions.ClearTracers then
			pcall(
				PreviousMM2.Functions.ClearTracers
			)
		end

		if PreviousMM2.Functions.ClearCoinESP then
			pcall(
				PreviousMM2.Functions.ClearCoinESP
			)
		end
	end

	if PreviousMM2.UI
		and PreviousMM2.UI.TracerGui
	then
		pcall(function()
			PreviousMM2.UI.TracerGui:Destroy()
		end)
	end

	task.wait()
end

--============================================================
-- CREATE FRESH INSTANCE
--============================================================

local MM2 = {}

if getgenv then
	getgenv().MM2_V85_SPLIT = MM2
else
	_G.MM2_V85_SPLIT = MM2
end

--============================================================
-- SERVICES
--============================================================

MM2.Services = {
	Players = game:GetService("Players"),
	RunService = game:GetService("RunService"),
	UserInputService = game:GetService("UserInputService"),
	StarterGui = game:GetService("StarterGui"),
	ReplicatedStorage = game:GetService("ReplicatedStorage"),
	TweenService = game:GetService("TweenService"),
	CoreGui = game:GetService("CoreGui"),
}

local S =
	MM2.Services

MM2.LocalPlayer =
	S.Players.LocalPlayer

MM2.PlayerGui =
	MM2.LocalPlayer:WaitForChild(
		"PlayerGui"
	)

MM2.Camera =
	workspace.CurrentCamera

MM2.Running =
	true

MM2.Connections =
	{}

--============================================================
-- CONNECTION TRACKER
--============================================================

function MM2.Track(connection)

	table.insert(
		MM2.Connections,
		connection
	)

	return connection
end

--============================================================
-- DEFAULT FLAGS
--============================================================

MM2.Flags = {
	Theme = "Summer Event",
	AntiFling = true,

	MatchESP = false,
	GunESP = false,
	TriggerBot = false,
	AimLock = false,
	AutoGrab = false,
	AutoFarm = false,
	ShowShootButton = false,

	Fly = false,
	Noclip = false,
	InfiniteJump = false,

	MurdererTracer = false,
	SheriffTracer = false,
	HeroTracer = false,
	InnocentTracer = false,
}

--============================================================
-- CONFIG
--============================================================

MM2.Config = {
	MAX_ESP_DISTANCE = 2000,

	ROLE_CLEAR_GRACE = 1.0,

	KnifeNames = {
		Knife = true,
		CrateKnife = true
	},

	GunNames = {
		Gun = true,
		Revolver = true
	},
}

--============================================================
-- STATE
--============================================================

MM2.State = {
	OriginalSheriff = nil,
	OriginalSheriffUserId = nil,

	GunDroppedThisRound = false,
	CountdownWasActive = false,

	SelectedFlingTarget = nil,
	Is_Picking_Up = false,

	ServerRolesCache = {},

	ServerMurder = nil,
	ServerSheriff = nil,
	ServerHero = nil,

	RoleRoundActive = false,
	RoleRoundSignature = nil,
	RoleRolesMissingSince = nil,

	-- Startup/intermission protection.
	RoleBootstrapSeen = false,
	RoleInactiveSignature = nil,

	SuppressStaleRoles = false,
	StaleSpecialSignature = nil,

	RecentRespawns = {},
	PlayerOutOfRound = {},

	GetPlayerDataRemote =
		S.ReplicatedStorage:FindFirstChild(
			"GetPlayerData",
			true
		),
}

--============================================================
-- PLAYER SETTINGS
--============================================================

MM2.PlayerSettings = {
	FlySpeed = 55,
	WalkSpeed = 16,
	JumpPower = 50
}

--============================================================
-- UI / FUNCTIONS
--============================================================

MM2.UI =
	MM2.UI or {}

MM2.Functions =
	MM2.Functions or {}

--============================================================
-- NOTIFICATIONS
--============================================================

function MM2.Notify(
	message,
	duration,
	icon,
	title
)

	local UI =
		MM2.UI

	if UI
		and UI.WindUI
		and UI.WindUI.Notify
	then

		local success =
			pcall(function()

				UI.WindUI:Notify({
					Title =
						tostring(
							title
							or "Blizzard MM2"
						),

					Content =
						tostring(
							message
							or ""
						),

					Duration =
						tonumber(
							duration
						)
						or 2.5,

					Icon =
						icon
						or "check",
				})
			end)

		if success then
			return true
		end
	end

	pcall(function()

		S.StarterGui:SetCore(
			"SendNotification",
			{
				Title =
					tostring(
						title
						or "Blizzard MM2"
					),

				Text =
					tostring(
						message
						or ""
					),

				Duration =
					tonumber(
						duration
					)
					or 2.5
			}
		)
	end)

	return false
end

--============================================================
-- TOOL HELPERS
--============================================================

function MM2.HasTool(
	container,
	allowedNames
)

	if not container then
		return false
	end

	for _,obj in ipairs(
		container:GetChildren()
	) do

		if obj:IsA("Tool")
			and allowedNames[obj.Name]
		then

			return true
		end
	end

	return false
end

function MM2.HasGunAnywhere()

	local char =
		MM2.LocalPlayer.Character

	local bp =
		MM2.LocalPlayer:FindFirstChild(
			"Backpack"
		)

	return
		(
			char
			and (
				char:FindFirstChild("Gun")
				or char:FindFirstChild("Revolver")
			)
		)
		or
		(
			bp
			and (
				bp:FindFirstChild("Gun")
				or bp:FindFirstChild("Revolver")
			)
		)
end

--============================================================
-- GUI VISIBILITY
--============================================================

function MM2.IsActuallyVisible(guiObject)

	local current =
		guiObject

	while current
		and current ~= MM2.PlayerGui
	do

		if current:IsA("GuiObject")
			and not current.Visible
		then
			return false
		end

		if current:IsA("LayerCollector")
			and not current.Enabled
		then
			return false
		end

		current =
			current.Parent
	end

	return true
end

--============================================================
-- LOCAL CHARACTER
--============================================================

function MM2.GetLocalCharacter()

	local char =
		MM2.LocalPlayer.Character

	if not char then
		return nil
	end

	local humanoid =
		char:FindFirstChildOfClass(
			"Humanoid"
		)

	local hrp =
		char:FindFirstChild(
			"HumanoidRootPart"
		)

	if not humanoid
		or not hrp
	then
		return nil
	end

	return
		char,
		humanoid,
		hrp
end

--============================================================
-- ROLE SIGNATURE
--============================================================

function MM2.BuildSpecialSignature(cache)

	local result =
		{}

	for playerName,role in pairs(cache) do

		if role == "Murderer"
			or role == "Sheriff"
			or role == "Hero"
		then

			table.insert(
				result,
				playerName
				.. "="
				.. role
			)
		end
	end

	table.sort(result)

	return
		table.concat(
			result,
			"|"
		)
end

--============================================================
-- ROLE ROUND STATE
--============================================================

local function BeginRoleRound(
	newCache,
	newMurder,
	newSheriff,
	newHero
)

	local State =
		MM2.State

	State.RoleRoundActive =
		true

	State.RoleRolesMissingSince =
		nil

	State.RoleRoundSignature =
		MM2.BuildSpecialSignature(
			newCache
		)

	State.PlayerOutOfRound =
		{}

	State.RecentRespawns =
		{}

	State.SuppressStaleRoles =
		false

	State.StaleSpecialSignature =
		nil

	State.ServerRolesCache =
		newCache

	State.ServerMurder =
		newMurder

	State.ServerSheriff =
		newSheriff

	State.ServerHero =
		newHero
end

local function EndRoleRound()

	local State =
		MM2.State

	State.RoleRoundActive =
		false

	State.RoleRoundSignature =
		nil

	State.RoleRolesMissingSince =
		nil

	State.ServerRolesCache =
		{}

	State.ServerMurder =
		nil

	State.ServerSheriff =
		nil

	State.ServerHero =
		nil

	State.RecentRespawns =
		{}

	State.PlayerOutOfRound =
		{}

	State.SuppressStaleRoles =
		false

	State.StaleSpecialSignature =
		nil

	-- Makes the next new assignment detectable.
	State.RoleInactiveSignature =
		""
end

MM2.Functions.BeginRoleRound =
	BeginRoleRound

MM2.Functions.EndRoleRound =
	EndRoleRound

--============================================================
-- LIVE ROUND EVIDENCE
--============================================================

local function HasLiveRoundEvidence()

	-- Active maps normally contain the round CoinContainer.
	if workspace:FindFirstChild(
		"CoinContainer",
		true
	) then
		return true
	end

	-- Dropped gun = strong live-round evidence.
	if workspace:FindFirstChild(
		"GunDrop",
		true
	) then
		return true
	end

	-- Equipped round weapon on a player.
	for _,player in ipairs(
		S.Players:GetPlayers()
	) do

		local char =
			player.Character

		if char then

			for _,obj in ipairs(
				char:GetChildren()
			) do

				if obj:IsA("Tool")
					and (
						MM2.Config.KnifeNames[obj.Name]
						or MM2.Config.GunNames[obj.Name]
					)
				then

					return true
				end
			end
		end
	end

	return false
end

--============================================================
-- MID-ROUND STARTUP ELIGIBILITY
--============================================================

local function BuildStartupPlayerOutOfRound(
	rawRoles
)

	local result =
		{}

	for _,player in ipairs(
		S.Players:GetPlayers()
	) do

		if player ~= MM2.LocalPlayer then

			local data =
				rawRoles[player.Name]

			-- IMPORTANT:
			-- Only used when Blizzard first loads halfway
			-- through an already-running round.
			--
			-- Correct diagnostic showed:
			--
			-- active player:
			-- Dead=false / Killed=false
			--
			-- already eliminated:
			-- Dead=true / Killed=true
			--
			-- or completely missing from GetPlayerData.
			if type(data) ~= "table"
				or data.Dead == true
				or data.Killed == true
			then

				result[player.Name] =
					true
			end
		end
	end

	return result
end

--============================================================
-- LIVE MURDERER CHECK
--============================================================

local function HasLiveMurderer(
	rawRoles,
	murdererName
)

	if not murdererName then
		return false
	end

	local data =
		rawRoles[murdererName]

	if type(data) ~= "table" then
		return false
	end

	if data.Role ~= "Murderer" then
		return false
	end

	if data.Dead == true
		or data.Killed == true
	then
		return false
	end

	return true
end

--============================================================
-- SERVER ROLE CACHE
--============================================================

function MM2.UpdateServerRoles()

	local State =
		MM2.State

	if not State.GetPlayerDataRemote
		or not State.GetPlayerDataRemote.Parent
	then

		State.GetPlayerDataRemote =
			S.ReplicatedStorage:FindFirstChild(
				"GetPlayerData",
				true
			)
	end

	if not State.GetPlayerDataRemote
		or not State.GetPlayerDataRemote:IsA(
			"RemoteFunction"
		)
	then
		return
	end

	local success,rawRoles =
		pcall(function()

			return
				State.GetPlayerDataRemote:InvokeServer()
		end)

	if not success
		or type(rawRoles) ~= "table"
	then
		return
	end

	local newCache =
		{}

	local newMurder =
		nil

	local newSheriff =
		nil

	local newHero =
		nil

	for playerName,data in pairs(
		rawRoles
	) do

		if type(playerName) == "string"
			and type(data) == "table"
			and data.Role
		then

			newCache[playerName] =
				data.Role

			if data.Role == "Murderer" then

				newMurder =
					playerName

			elseif data.Role == "Sheriff" then

				newSheriff =
					playerName

			elseif data.Role == "Hero" then

				newHero =
					playerName
			end
		end
	end

	local sig =
		MM2.BuildSpecialSignature(
			newCache
		)

	--========================================================
	-- STARTUP / NEW ROUND DETECTION
	--========================================================

	if not State.RoleRoundActive then

		local hasAssignedPair =
			newMurder ~= nil
			and newSheriff ~= nil

		local hasLiveMurderer =
			HasLiveMurderer(
				rawRoles,
				newMurder
			)

		--====================================================
		-- FIRST SUCCESSFUL SNAPSHOT AFTER BLIZZARD LOAD
		--====================================================

		if not State.RoleBootstrapSeen then

			State.RoleBootstrapSeen =
				true

			State.RoleInactiveSignature =
				sig

			-- IMPORTANT:
			--
			-- Mid-round startup does NOT require Sheriff.
			--
			-- Correct diagnostic showed a real active round
			-- where Murderer was alive but Sheriff was already
			-- absent.
			--
			-- A live Murderer + live world evidence is enough
			-- to recognize that Blizzard loaded mid-round.
			if hasLiveMurderer
				and HasLiveRoundEvidence()
			then

				local startupOutOfRound =
					BuildStartupPlayerOutOfRound(
						rawRoles
					)

				BeginRoleRound(
					newCache,
					newMurder,
					newSheriff,
					newHero
				)

				-- BeginRoleRound intentionally clears the table,
				-- so restore ONLY the startup elimination snapshot
				-- after activation.
				State.PlayerOutOfRound =
					startupOutOfRound

				return
			end

			-- Otherwise this may just be stale intermission data.
			State.ServerRolesCache =
				newCache

			State.ServerMurder =
				newMurder

			State.ServerSheriff =
				newSheriff

			State.ServerHero =
				newHero

			return
		end

		--====================================================
		-- NORMAL FRESH ROUND ASSIGNMENT
		--====================================================

		-- Keep the original pair requirement here.
		--
		-- This preserves the behavior that was already working:
		-- fresh Murderer + Sheriff assignment activates Role ESP
		-- before the actual RoundStart remote.
		if hasAssignedPair then

			local assignmentChanged =
				sig
				~= State.RoleInactiveSignature

			local alreadyRunning =
				HasLiveRoundEvidence()

			if assignmentChanged
				or alreadyRunning
			then

				BeginRoleRound(
					newCache,
					newMurder,
					newSheriff,
					newHero
				)

				return
			end
		end

		State.RoleInactiveSignature =
			sig
	end

	--========================================================
	-- ACTIVE ROUND
	--========================================================

	if State.RoleRoundActive then

		local hasSpecialRole =
			newMurder ~= nil
			or newSheriff ~= nil
			or newHero ~= nil

		if hasSpecialRole then

			State.RoleRolesMissingSince =
				nil

			State.ServerRolesCache =
				newCache

			State.ServerMurder =
				newMurder

			State.ServerSheriff =
				newSheriff

			State.ServerHero =
				newHero

			State.RoleRoundSignature =
				sig

		else

			if not State.RoleRolesMissingSince then

				State.RoleRolesMissingSince =
					os.clock()

			elseif os.clock()
				- State.RoleRolesMissingSince
				>= MM2.Config.ROLE_CLEAR_GRACE
			then

				EndRoleRound()
			end
		end

		return
	end

	--========================================================
	-- INTERMISSION / NO ACTIVE ROLE ROUND
	--========================================================

	State.RoleRolesMissingSince =
		nil

	State.ServerRolesCache =
		newCache

	State.ServerMurder =
		newMurder

	State.ServerSheriff =
		newSheriff

	State.ServerHero =
		newHero

	if State.SuppressStaleRoles
		and State.StaleSpecialSignature ~= nil
		and sig ~= State.StaleSpecialSignature
	then

		State.SuppressStaleRoles =
			false

		State.StaleSpecialSignature =
			nil

		State.RecentRespawns =
			{}

		State.PlayerOutOfRound =
			{}
	end
end

--============================================================
-- CHARACTER RESET TRACKING
--============================================================

function MM2.RegisterCharacterReset(player)

	local State =
		MM2.State

	State.PlayerOutOfRound[
		player.Name
	] =
		true

	local now =
		os.clock()

	State.RecentRespawns[
		player.Name
	] =
		now

	for name,timestamp in pairs(
		State.RecentRespawns
	) do

		if now - timestamp > 0.8 then

			State.RecentRespawns[
				name
			] =
				nil
		end
	end

	local count =
		0

	for _ in pairs(
		State.RecentRespawns
	) do
		count += 1
	end

	local required =
		math.clamp(
			math.floor(
				#S.Players:GetPlayers()
				* 0.35
			),
			2,
			3
		)

	if count >= required
		and not State.SuppressStaleRoles
	then

		State.StaleSpecialSignature =
			MM2.BuildSpecialSignature(
				State.ServerRolesCache
			)

		State.SuppressStaleRoles =
			true
	end
end

function MM2.WatchPlayer(player)

	MM2.Track(
		player.CharacterAdded:Connect(
			function()

				MM2.RegisterCharacterReset(
					player
				)
			end
		)
	)
end

for _,player in ipairs(
	S.Players:GetPlayers()
) do

	MM2.WatchPlayer(
		player
	)
end

MM2.Track(
	S.Players.PlayerAdded:Connect(
		MM2.WatchPlayer
	)
)

--============================================================
-- COUNTDOWN DETECTION
--============================================================

function MM2.IsCountdownActive()

	for _,obj in ipairs(
		MM2.PlayerGui:GetDescendants()
	) do

		if obj:IsA("TextLabel")
			or obj:IsA("TextButton")
		then

			local text =
				string.lower(
					obj.Text
					or ""
				)

			if string.find(
				text,
				"game starts in",
				1,
				true
			)
				and MM2.IsActuallyVisible(obj)
			then

				return true
			end
		end
	end

	return false
end

--============================================================
-- ROUND RESET
--============================================================

function MM2.UpdateRoundReset()

	local active =
		MM2.IsCountdownActive()

	if active
		and not MM2.State.CountdownWasActive
	then

		MM2.State.OriginalSheriff =
			nil

		MM2.State.OriginalSheriffUserId =
			nil

		MM2.State.GunDroppedThisRound =
			false
	end

	MM2.State.CountdownWasActive =
		active
end

--============================================================
-- PLAYER ROLE
--============================================================

function MM2.GetPlayerRole(player)

	if not player
		or player == MM2.LocalPlayer
	then
		return "None"
	end

	local char =
		player.Character

	if not char then
		return "None"
	end

	local humanoid =
		char:FindFirstChildOfClass(
			"Humanoid"
		)

	local head =
		char:FindFirstChild(
			"Head"
		)

	if not humanoid
		or humanoid.Health <= 0
		or not head
	then
		return "None"
	end

	-- Never convert uncertain/stale roles into green ESP.
	if MM2.State.SuppressStaleRoles then
		return "None"
	end

	-- Player already eliminated/reset this round.
	--
	-- This also contains the initial mid-round startup
	-- snapshot for people who died before Blizzard loaded.
	if MM2.State.PlayerOutOfRound[
		player.Name
	] then
		return "None"
	end

	local role =
		MM2.State.ServerRolesCache[
			player.Name
		]

	if role == "Murderer"
		or role == "Sheriff"
		or role == "Hero"
		or role == "Innocent"
	then

		return role
	end

	-- Mid-round startup protection:
	-- missing server role must never become green Innocent.
	if MM2.State.RoleRoundActive == true then
		return "None"
	end

	return "Innocent"
end

--============================================================
-- ROLE COLORS
--============================================================

function MM2.GetRoleColor(role)

	if role == "Murderer" then

		return Color3.fromRGB(
			255,
			72,
			72
		)

	elseif role == "Sheriff" then

		return Color3.fromRGB(
			79,
			142,
			255
		)

	elseif role == "Hero" then

		return Color3.fromRGB(
			255,
			208,
			84
		)

	elseif role == "Innocent" then

		return Color3.fromRGB(
			84,
			224,
			128
		)
	end

	return Color3.fromRGB(
		255,
		255,
		255
	)
end

--============================================================
-- SPECTATING
--============================================================

function MM2.GetSpectatedPlayer()

	local camera =
		workspace.CurrentCamera

	if not camera then
		return nil
	end

	local subject =
		camera.CameraSubject

	if not subject then
		return nil
	end

	if subject:IsA("Humanoid") then

		local p =
			S.Players:GetPlayerFromCharacter(
				subject.Parent
			)

		if p
			and p ~= MM2.LocalPlayer
		then
			return p
		end

	elseif subject:IsA("BasePart") then

		local char =
			subject:FindFirstAncestorOfClass(
				"Model"
			)

		local p =
			char
			and S.Players:GetPlayerFromCharacter(
				char
			)

		if p
			and p ~= MM2.LocalPlayer
		then
			return p
		end
	end

	return nil
end

--============================================================
-- REFERENCE POSITION
--============================================================

function MM2.GetReferencePosition()

	local camera =
		workspace.CurrentCamera

	local spectated =
		MM2.GetSpectatedPlayer()

	if spectated then

		local hrp =
			spectated.Character
			and spectated.Character:FindFirstChild(
				"HumanoidRootPart"
			)

		if hrp then
			return hrp.Position
		end
	end

	local char =
		MM2.LocalPlayer.Character

	local humanoid =
		char
		and char:FindFirstChildOfClass(
			"Humanoid"
		)

	local hrp =
		char
		and char:FindFirstChild(
			"HumanoidRootPart"
		)

	if humanoid
		and humanoid.Health > 0
		and hrp
	then
		return hrp.Position
	end

	return
		camera
		and camera.CFrame.Position
		or nil
end

--============================================================
-- ESP DISTANCE
--============================================================

function MM2.IsPositionWithinESPDistance(position)

	local reference =
		position
		and MM2.GetReferencePosition()

	return
		reference
		and (
			reference - position
		).Magnitude
			< MM2.Config.MAX_ESP_DISTANCE
		or false
end

function MM2.IsWithinESPDistance(player)

	local hrp =
		player.Character
		and player.Character:FindFirstChild(
			"HumanoidRootPart"
		)

	return
		hrp
		and MM2.IsPositionWithinESPDistance(
			hrp.Position
		)
		or false
end

return MM2