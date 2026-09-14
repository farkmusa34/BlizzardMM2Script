--============================================================
-- Blizzard MM2 v1.85.4 - Teleport.lua
-- Round, player, murderer, map, and lobby teleports.
--============================================================

local MM2 =
	getgenv
	and getgenv().MM2_V85_SPLIT
	or _G.MM2_V85_SPLIT

assert(
	MM2
	and MM2.UI
	and MM2.UI.TeleportPage,
	"Load Shared.lua + UI.lua first"
)

local S = MM2.Services
local Players = S.Players
local LocalPlayer = MM2.LocalPlayer
local UI = MM2.UI

local SelectedPlayerName = nil

--============================================================
-- HELPERS
--============================================================

local function GetAliveCharacter(player)
	if not player then
		return nil
	end

	local char = player.Character
	if not char then
		return nil
	end

	local humanoid =
		char:FindFirstChildOfClass("Humanoid")

	local hrp =
		char:FindFirstChild("HumanoidRootPart")

	if not humanoid
		or humanoid.Health <= 0
		or not hrp
	then
		return nil
	end

	return char,humanoid,hrp
end

local function GetLocalTeleportCharacter()
	local char,humanoid,hrp =
		MM2.GetLocalCharacter()

	if not char
		or not humanoid
		or humanoid.Health <= 0
		or not hrp
	then

		MM2.Notify(
			"Your character is not ready.",
			2.5,
			"triangle-alert",
			"Teleport"
		)

		return nil
	end

	return char,humanoid,hrp
end

local function TeleportLocalToCFrame(targetCFrame)
	local char,humanoid,hrp =
		GetLocalTeleportCharacter()

	if not char then
		return false
	end

	if typeof(targetCFrame) ~= "CFrame" then
		return false
	end

	-- Clear movement first so the character does not keep
	-- carrying old velocity after the teleport.
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero

	char:PivotTo(targetCFrame)

	task.defer(function()
		if hrp and hrp.Parent then
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		end
	end)

	return true
end

local function TeleportNearHRP(
	targetHRP,
	mode
)

	if not targetHRP
		or not targetHRP.Parent
	then
		return false
	end

	local targetCFrame

	if mode == "behind" then

		-- Roblox faces toward local -Z, so positive Z
		-- places us behind the target.
		targetCFrame =
			targetHRP.CFrame
			* CFrame.new(
				0,
				0,
				4.5
			)

	elseif mode == "side" then

		targetCFrame =
			targetHRP.CFrame
			* CFrame.new(
				4.5,
				0,
				1.5
			)

	else

		targetCFrame =
			targetHRP.CFrame
			* CFrame.new(
				0,
				0,
				4.5
			)
	end

	return TeleportLocalToCFrame(
		targetCFrame
	)
end

local function RefreshServerRoles()
	pcall(function()
		MM2.UpdateServerRoles()
	end)
end

--============================================================
-- MURDERER
--============================================================

local function GetMurdererPlayer()
	RefreshServerRoles()

	local murdererName =
		MM2.State.ServerMurder

	if not murdererName then
		return nil
	end

	local murderer =
		Players:FindFirstChild(
			murdererName
		)

	if not murderer
		or murderer == LocalPlayer
	then
		return nil
	end

	local _,humanoid,hrp =
		GetAliveCharacter(
			murderer
		)

	if not humanoid
		or not hrp
	then
		return nil
	end

	if MM2.GetPlayerRole(murderer)
		~= "Murderer"
	then
		return nil
	end

	return murderer,hrp
end

local function TeleportBehindMurderer()
	local murderer,hrp =
		GetMurdererPlayer()

	if not murderer
		or not hrp
	then

		MM2.Notify(
			"No active Murderer found.",
			2.5,
			"triangle-alert",
			"Teleport"
		)

		return false
	end

	if TeleportNearHRP(
		hrp,
		"behind"
	) then

		MM2.Notify(
			"Teleported behind "
				.. murderer.DisplayName
				.. ".",
			2.0,
			"navigation",
			"Teleport"
		)

		return true
	end

	return false
end

--============================================================
-- ACTIVE MAP
--============================================================

local function FindMapAnchorPlayer()
	RefreshServerRoles()

	local fallbackMurderer = nil

	for _,player in ipairs(
		Players:GetPlayers()
	) do

		if player ~= LocalPlayer then

			local role =
				MM2.GetPlayerRole(
					player
				)

			local _,humanoid,hrp =
				GetAliveCharacter(
					player
				)

			if humanoid
				and hrp
				and role ~= "None"
			then

				-- Prefer a non-Murderer so "Teleport to Map"
				-- does not usually place the user next to the
				-- dangerous role.
				if role ~= "Murderer" then
					return player,hrp
				end

				fallbackMurderer = {
					Player = player,
					HRP = hrp,
				}
			end
		end
	end

	if fallbackMurderer then
		return
			fallbackMurderer.Player,
			fallbackMurderer.HRP
	end

	return nil
end

local function TeleportToMap()
	local player,hrp =
		FindMapAnchorPlayer()

	if not player
		or not hrp
	then

		MM2.Notify(
			"No active round player found.",
			2.5,
			"triangle-alert",
			"Teleport"
		)

		return false
	end

	if TeleportNearHRP(
		hrp,
		"side"
	) then

		MM2.Notify(
			"Teleported to the active map.",
			2.0,
			"map",
			"Teleport"
		)

		return true
	end

	return false
end

--============================================================
-- LOBBY / INTERMISSION
--============================================================

local LOBBY_KEYWORDS = {
	"lobby",
	"intermission",
	"waiting",
	"waitingroom",
	"waiting room",
}

local function NameLooksLikeLobby(name)
	name =
		string.lower(
			tostring(name or "")
		)

	for _,keyword in ipairs(
		LOBBY_KEYWORDS
	) do

		if string.find(
			name,
			keyword,
			1,
			true
		) then
			return true
		end
	end

	return false
end

local function FindLobbyPlayerAnchor()
	RefreshServerRoles()

	for _,player in ipairs(
		Players:GetPlayers()
	) do

		if player ~= LocalPlayer then

			local _,humanoid,hrp =
				GetAliveCharacter(
					player
				)

			if humanoid
				and hrp
			then

				local role =
					MM2.GetPlayerRole(
						player
					)

				-- During an active round, people already
				-- eliminated/reset are marked out-of-round.
				-- Those characters are usually back in lobby.
				if MM2.State.PlayerOutOfRound[
					player.Name
				] == true
				then
					return player,hrp
				end

				-- During intermission there is no active role
				-- round, so an alive role-less player is also
				-- a useful lobby anchor.
				if MM2.State.RoleRoundActive ~= true
					and role == "None"
				then
					return player,hrp
				end
			end
		end
	end

	return nil
end

local function FindNamedLobbyPart()
	local best = nil

	for _,obj in ipairs(
		workspace:GetDescendants()
	) do

		if obj:IsA("BasePart")
			and NameLooksLikeLobby(
				obj.Name
			)
		then

			best = obj

			if obj:IsA("SpawnLocation") then
				return obj
			end
		end
	end

	if best then
		return best
	end

	-- Look for a Lobby/Intermission model/folder and then
	-- choose a usable part inside it.
	for _,obj in ipairs(
		workspace:GetDescendants()
	) do

		if (
			obj:IsA("Model")
			or obj:IsA("Folder")
		)
			and NameLooksLikeLobby(
				obj.Name
			)
		then

			local spawn =
				obj:FindFirstChildWhichIsA(
					"SpawnLocation",
					true
				)

			if spawn then
				return spawn
			end

			local part =
				obj:FindFirstChildWhichIsA(
					"BasePart",
					true
				)

			if part then
				return part
			end
		end
	end

	return nil
end

local function TeleportToLobby()
	local player,hrp =
		FindLobbyPlayerAnchor()

	if player
		and hrp
	then

		if TeleportNearHRP(
			hrp,
			"side"
		) then

			MM2.Notify(
				"Teleported to lobby / intermission.",
				2.0,
				"house",
				"Teleport"
			)

			return true
		end
	end

	local lobbyPart =
		FindNamedLobbyPart()

	if lobbyPart then

		local target =
			lobbyPart.CFrame
			* CFrame.new(
				0,
				math.max(
					3,
					lobbyPart.Size.Y * 0.5 + 2
				),
				0
			)

		if TeleportLocalToCFrame(
			target
		) then

			MM2.Notify(
				"Teleported to lobby / intermission.",
				2.0,
				"house",
				"Teleport"
			)

			return true
		end
	end

	MM2.Notify(
		"Could not find the lobby yet.",
		2.5,
		"triangle-alert",
		"Teleport"
	)

	return false
end

--============================================================
-- PLAYER TARGETS
--============================================================

local function GetPlayerNames()
	local values = {}

	for _,player in ipairs(
		Players:GetPlayers()
	) do

		if player ~= LocalPlayer then
			table.insert(
				values,
				player.Name
			)
		end
	end

	table.sort(
		values,
		function(a,b)
			return string.lower(a)
				< string.lower(b)
		end
	)

	return values
end

local function GetSelectedPlayer()
	if not SelectedPlayerName then
		return nil
	end

	local player =
		Players:FindFirstChild(
			SelectedPlayerName
		)

	if player == LocalPlayer then
		return nil
	end

	return player
end

local function TeleportToSelectedPlayer(
	behind
)

	local player =
		GetSelectedPlayer()

	if not player then

		MM2.Notify(
			"Select a player first.",
			2.5,
			"user-x",
			"Teleport"
		)

		return false
	end

	local _,humanoid,hrp =
		GetAliveCharacter(
			player
		)

	if not humanoid
		or not hrp
	then

		MM2.Notify(
			"That player is not currently available.",
			2.5,
			"user-x",
			"Teleport"
		)

		return false
	end

	local ok =
		TeleportNearHRP(
			hrp,
			behind
				and "behind"
				or "side"
		)

	if ok then

		MM2.Notify(
			behind
				and (
					"Teleported behind "
					.. player.DisplayName
					.. "."
				)
				or (
					"Teleported to "
					.. player.DisplayName
					.. "."
				),
			2.0,
			"navigation",
			"Teleport"
		)
	end

	return ok
end

--============================================================
-- EXPOSE FUNCTIONS
--============================================================

MM2.Functions.TeleportBehindMurderer =
	TeleportBehindMurderer

MM2.Functions.TeleportToMap =
	TeleportToMap

MM2.Functions.TeleportToLobby =
	TeleportToLobby

MM2.Functions.TeleportToSelectedPlayer =
	TeleportToSelectedPlayer

--============================================================
-- UI
--============================================================

UI.AddSection(
	UI.TeleportPage,
	"Round",
	"Quick teleports for the active round"
)

UI.CreateActionFeature(
	UI.TeleportPage,
	"Teleport Behind Murderer",
	"Teleport a few studs behind the current Murderer",
	TeleportBehindMurderer
)

UI.CreateActionFeature(
	UI.TeleportPage,
	"Teleport to Map",
	"Teleport near an alive player in the active round",
	TeleportToMap
)

UI.CreateActionFeature(
	UI.TeleportPage,
	"Teleport to Lobby / Intermission",
	"Teleport back to a lobby player or detected lobby area",
	TeleportToLobby
)

UI.AddSection(
	UI.TeleportPage,
	"Players",
	"Teleport to a specific player"
)

local playerNames =
	GetPlayerNames()

UI.CreateDropdown(
	UI.TeleportPage,
	"Player",
	"Choose a player",
	playerNames,
	nil,
	function(value)

		if type(value) == "table" then
			value =
				value.Value
				or value.Title
				or value.Name
				or value[1]
		end

		if value ~= nil then
			SelectedPlayerName =
				tostring(value)
		end
	end
)

UI.CreateActionFeature(
	UI.TeleportPage,
	"Teleport to Player",
	"Teleport next to the selected player",
	function()
		TeleportToSelectedPlayer(
			false
		)
	end
)

UI.CreateActionFeature(
	UI.TeleportPage,
	"Teleport Behind Player",
	"Teleport a few studs behind the selected player",
	function()
		TeleportToSelectedPlayer(
			true
		)
	end
)

print(
	"[Blizzard MM2 Teleport] v1.85.4 loaded"
)

return MM2
