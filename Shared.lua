--============================================================
-- MM2 V8.6.3 SPLIT BUILD - Shared.lua
-- Stable role cache + optimized hot path.
--============================================================

local MM2 = getgenv and getgenv().MM2_V85_SPLIT or _G.MM2_V85_SPLIT

if not MM2 then
	MM2 = {}

	if getgenv then
		getgenv().MM2_V85_SPLIT = MM2
	else
		_G.MM2_V85_SPLIT = MM2
	end
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

local S = MM2.Services

MM2.LocalPlayer = S.Players.LocalPlayer
MM2.PlayerGui = MM2.LocalPlayer:WaitForChild("PlayerGui")
MM2.Camera = workspace.CurrentCamera
MM2.Running = true
MM2.Connections = {}

--============================================================
-- CONNECTION TRACKING
--============================================================

function MM2.Track(connection)
	table.insert(MM2.Connections, connection)
	return connection
end

--============================================================
-- FLAGS
--============================================================

MM2.Flags = {
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

	SuppressStaleRoles = false,
	StaleSpecialSignature = nil,

	RecentRespawns = {},
	PlayerOutOfRound = {},

	GetPlayerDataRemote =
		S.ReplicatedStorage:FindFirstChild("GetPlayerData", true),

	-- Prevents a confirmed special role from temporarily
	-- becoming Innocent because of a stale server update.
	ConfirmedSpecialRoles = {},
}

MM2.PlayerSettings = {
	FlySpeed = 55,
	WalkSpeed = 16,
	JumpPower = 50
}

MM2.UI = {}
MM2.Functions = {}

--============================================================
-- NOTIFICATIONS
--============================================================

function MM2.Notify(message, duration)
	pcall(function()
		S.StarterGui:SetCore("SendNotification", {
			Title = "Murder Mystery 2 Script",
			Text = message,
			Duration = duration or 3
		})
	end)
end

--============================================================
-- TOOL HELPERS
--============================================================

function MM2.HasTool(container, allowedNames)
	if not container then
		return false
	end

	for _, obj in ipairs(container:GetChildren()) do
		if obj:IsA("Tool") and allowedNames[obj.Name] then
			return true
		end
	end

	return false
end

function MM2.HasGunAnywhere()
	local char = MM2.LocalPlayer.Character
	local backpack = MM2.LocalPlayer:FindFirstChild("Backpack")

	return (
		char
		and (
			char:FindFirstChild("Gun")
			or char:FindFirstChild("Revolver")
		)
	)
	or (
		backpack
		and (
			backpack:FindFirstChild("Gun")
			or backpack:FindFirstChild("Revolver")
		)
	)
end

--============================================================
-- GUI VISIBILITY
--============================================================

function MM2.IsActuallyVisible(guiObject)
	local current = guiObject

	while current and current ~= MM2.PlayerGui do

		if current:IsA("GuiObject") and not current.Visible then
			return false
		end

		if current:IsA("LayerCollector") and not current.Enabled then
			return false
		end

		current = current.Parent
	end

	return true
end

--============================================================
-- LOCAL CHARACTER
--============================================================

function MM2.GetLocalCharacter()
	local char = MM2.LocalPlayer.Character

	if not char then
		return nil
	end

	local humanoid =
		char:FindFirstChildOfClass("Humanoid")

	local hrp =
		char:FindFirstChild("HumanoidRootPart")

	if not humanoid or not hrp then
		return nil
	end

	return char, humanoid, hrp
end

--============================================================
-- ROLE HELPERS
--============================================================

function MM2.BuildSpecialSignature(cache)
	local result = {}

	for playerName, role in pairs(cache) do

		if role == "Murderer"
			or role == "Sheriff"
			or role == "Hero"
		then

			table.insert(
				result,
				playerName .. "=" .. role
			)
		end
	end

	table.sort(result)

	return table.concat(result, "|")
end

local function IsSpecialRole(role)
	return role == "Murderer"
		or role == "Sheriff"
		or role == "Hero"
end

local function ClearConfirmedRoles()
	table.clear(MM2.State.ConfirmedSpecialRoles)
end

--============================================================
-- SERVER ROLE CACHE
--============================================================

function MM2.UpdateServerRoles()

	local State = MM2.State

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
		or not State.GetPlayerDataRemote:IsA("RemoteFunction")
	then
		return
	end

	local success, rawRoles = pcall(function()
		return State.GetPlayerDataRemote:InvokeServer()
	end)

	if not success
		or type(rawRoles) ~= "table"
	then
		return
	end

	local newCache = {}

	local newMurder = nil
	local newSheriff = nil
	local newHero = nil

	for playerName, data in pairs(rawRoles) do

		if type(playerName) == "string"
			and type(data) == "table"
			and data.Role
		then

			local role = data.Role

			newCache[playerName] = role

			if role == "Murderer" then
				newMurder = playerName

			elseif role == "Sheriff" then
				newSheriff = playerName

			elseif role == "Hero" then
				newHero = playerName
			end
		end
	end

	if not next(newCache) then
		return
	end

	local sig =
		MM2.BuildSpecialSignature(newCache)

	-- A different special-role signature means fresh
	-- role information has arrived for another round.
	if State.SuppressStaleRoles
		and State.StaleSpecialSignature ~= nil
		and sig ~= State.StaleSpecialSignature
	then

		State.SuppressStaleRoles = false
		State.StaleSpecialSignature = nil

		table.clear(State.RecentRespawns)
		table.clear(State.PlayerOutOfRound)
	end

	State.ServerRolesCache = newCache

	State.ServerMurder = newMurder
	State.ServerSheriff = newSheriff
	State.ServerHero = newHero

	-- Only SPECIAL roles are confirmed.
	--
	-- Innocent can therefore never overwrite an already
	-- confirmed Murderer/Sheriff/Hero during the round.
	for playerName, role in pairs(newCache) do

		if IsSpecialRole(role) then
			State.ConfirmedSpecialRoles[playerName] = role
		end
	end
end

--============================================================
-- RESPAWN / ROUND RESET
--============================================================

function MM2.RegisterCharacterReset(player)

	local State = MM2.State

	State.PlayerOutOfRound[player.Name] = true

	local now = os.clock()

	State.RecentRespawns[player.Name] = now

	for name, timestamp in pairs(State.RecentRespawns) do

		if now - timestamp > 0.8 then
			State.RecentRespawns[name] = nil
		end
	end

	local count = 0

	for _ in pairs(State.RecentRespawns) do
		count += 1
	end

	local required =
		math.clamp(
			math.floor(
				#S.Players:GetPlayers() * 0.35
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

		State.SuppressStaleRoles = true
	end
end

function MM2.WatchPlayer(player)

	MM2.Track(
		player.CharacterAdded:Connect(function()
			MM2.RegisterCharacterReset(player)
		end)
	)
end

for _, player in ipairs(S.Players:GetPlayers()) do
	MM2.WatchPlayer(player)
end

MM2.Track(
	S.Players.PlayerAdded:Connect(
		MM2.WatchPlayer
	)
)

--============================================================
-- COUNTDOWN
--============================================================

function MM2.IsCountdownActive()

	for _, obj in ipairs(
		MM2.PlayerGui:GetDescendants()
	) do

		if obj:IsA("TextLabel")
			or obj:IsA("TextButton")
		then

			local text =
				string.lower(obj.Text or "")

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

	-- IMPORTANT:
	-- This only runs ONCE when countdown begins.
	--
	-- We do NOT perform this check from GetPlayerRole(),
	-- because GetPlayerRole() is a frequently-called ESP path.
	if active
		and not MM2.State.CountdownWasActive
	then

		MM2.State.OriginalSheriff = nil
		MM2.State.OriginalSheriffUserId = nil
		MM2.State.GunDroppedThisRound = false

		-- Remove previous-round special-role locks.
		ClearConfirmedRoles()
	end

	MM2.State.CountdownWasActive = active
end

--============================================================
-- GET PLAYER ROLE
-- OPTIMIZED: no GUI scanning/intermission checks here.
--============================================================

function MM2.GetPlayerRole(player)

	if not player
		or player == MM2.LocalPlayer
	then
		return "None"
	end

	local char = player.Character

	if not char then
		return "None"
	end

	local humanoid =
		char:FindFirstChildOfClass("Humanoid")

	local head =
		char:FindFirstChild("Head")

	if not humanoid
		or humanoid.Health <= 0
		or not head
	then
		return "None"
	end

	local State = MM2.State

	local confirmed =
		State.ConfirmedSpecialRoles[player.Name]

	local role =
		State.ServerRolesCache[player.Name]

	-- Server data is temporarily stale.
	--
	-- Preserve a positively-confirmed special role instead
	-- of suddenly displaying that player as Innocent.
	if State.SuppressStaleRoles then
		return confirmed or "Innocent"
	end

	-- A player who has respawned/out-of-round should no
	-- longer display their previous special role.
	if State.PlayerOutOfRound[player.Name] then
		return "None"
	end

	-- Positive Murderer/Sheriff/Hero result.
	if IsSpecialRole(role) then

		State.ConfirmedSpecialRoles[player.Name] = role

		return role
	end

	-- Do not allow a temporary Innocent result to overwrite
	-- a confirmed special role.
	if role == "Innocent" then
		return confirmed or "Innocent"
	end

	-- Missing/temporary role information.
	return confirmed or "Innocent"
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
-- SPECTATE
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

		local player =
			S.Players:GetPlayerFromCharacter(
				subject.Parent
			)

		if player
			and player ~= MM2.LocalPlayer
		then
			return player
		end

	elseif subject:IsA("BasePart") then

		local char =
			subject:FindFirstAncestorOfClass(
				"Model"
			)

		local player =
			char
			and S.Players:GetPlayerFromCharacter(
				char
			)

		if player
			and player ~= MM2.LocalPlayer
		then
			return player
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

		local char =
			spectated.Character

		local hrp =
			char
			and char:FindFirstChild(
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

	return camera
		and camera.CFrame.Position
		or nil
end

--============================================================
-- ESP DISTANCE
--============================================================

function MM2.IsPositionWithinESPDistance(position)

	if not position then
		return false
	end

	local reference =
		MM2.GetReferencePosition()

	if not reference then
		return false
	end

	return (reference - position).Magnitude
		< MM2.Config.MAX_ESP_DISTANCE
end

function MM2.IsWithinESPDistance(player)

	local char =
		player.Character

	if not char then
		return false
	end

	local hrp =
		char:FindFirstChild(
			"HumanoidRootPart"
		)

	if not hrp then
		return false
	end

	return MM2.IsPositionWithinESPDistance(
		hrp.Position
	)
end

return MM2