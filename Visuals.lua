--============================================================
-- MM2 V8.8 VISUALS - Visuals.lua
-- Match ESP, Gun ESP, Coin ESP, Tracers, Round Timer.
--============================================================

local MM2 = getgenv and getgenv().MM2_V85_SPLIT or _G.MM2_V85_SPLIT
assert(MM2 and MM2.UI and MM2.UI.VisualsPage, "Load Shared.lua + UI.lua first")

local Players = MM2.Services.Players
local RunService = MM2.Services.RunService
local LocalPlayer = MM2.LocalPlayer
local Flags = MM2.Flags
local UI = MM2.UI
local Track = MM2.Track
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--============================================================
-- VISUALS UI
--============================================================

UI.AddSection(UI.VisualsPage, "Visuals", "ESP and tracer controls")

UI.CreateToggle(
	UI.VisualsPage,
	"Coin ESP",
	"Highlight uncollected coins",
	"CoinESP",
	function(on)
		if not on and MM2.Functions.ClearCoinESP then
			MM2.Functions.ClearCoinESP()
		end
	end
)

UI.CreateToggle(
	UI.VisualsPage,
	"Match ESP",
	"Highlight players using detected roles",
	"MatchESP",
	function(on)
		if not on and MM2.Functions.ClearPlayerESP then
			MM2.Functions.ClearPlayerESP()
		end
	end
)

UI.CreateToggle(
	UI.VisualsPage,
	"Gun ESP",
	"Highlight the dropped gun",
	"GunESP",
	function(on)
		if not on and MM2.Functions.ClearGunESP then
			MM2.Functions.ClearGunESP()
		end
	end
)

--============================================================
-- ROUND TIMER UI
--============================================================

Flags.RoundTimer = Flags.RoundTimer == true

UI.AddSection(
	UI.VisualsPage,
	"Round",
	"Round information"
)

UI.CreateToggle(
	UI.VisualsPage,
	"Round Timer",
	"Shows the remaining time in the current round",
	"RoundTimer",
	function(on)
		if not on and MM2.Functions.HideRoundTimer then
			MM2.Functions.HideRoundTimer()
		elseif on and MM2.Functions.RefreshRoundTimer then
			MM2.Functions.RefreshRoundTimer()
		end
	end
)

--============================================================
-- TRACERS UI
--============================================================

UI.AddSection(UI.VisualsPage, "Tracers", "Role-based screen tracers")

for _, item in ipairs({
	{"Murderer Tracer", "Track the murderer", "MurdererTracer"},
	{"Sheriff Tracer", "Track the sheriff", "SheriffTracer"},
	{"Hero Tracer", "Track the hero", "HeroTracer"},
	{"Innocent Tracer", "Track innocents", "InnocentTracer"},
}) do
	UI.CreateToggle(
		UI.VisualsPage,
		item[1],
		item[2],
		item[3],
		function(on)
			if not on and MM2.Functions.ClearTracers then
				MM2.Functions.ClearTracers()
			end
		end
	)
end

--============================================================
-- PLAYER ESP
--============================================================

local function RemovePlayerESP(player)
	local char = player.Character
	if not char then return end

	local highlight = char:FindFirstChild("MM2_MatchESP")
	if highlight then highlight:Destroy() end

	local head = char:FindFirstChild("Head")
	if head then
		local tag = head:FindFirstChild("MM2_NameTag")
		if tag then tag:Destroy() end
	end
end

MM2.Functions.RemovePlayerESP = RemovePlayerESP

MM2.Functions.ClearPlayerESP = function()
	for _, player in ipairs(Players:GetPlayers()) do
		RemovePlayerESP(player)
	end
end

MM2.Functions.UpdatePlayerESP = function()
	if not Flags.MatchESP then return end

	for _, player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer then
			RemovePlayerESP(player)
			continue
		end

		local char = player.Character
		local head = char and char:FindFirstChild("Head")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")

		if not char or not head or not hrp
			or not MM2.IsPositionWithinESPDistance(hrp.Position)
		then
			RemovePlayerESP(player)
			continue
		end

		local role = MM2.GetPlayerRole(player)

		if role == "None" then
			RemovePlayerESP(player)
			continue
		end

		local color = MM2.GetRoleColor(role)
		local highlight = char:FindFirstChild("MM2_MatchESP")

		if not highlight then
			highlight = Instance.new("Highlight")
			highlight.Name = "MM2_MatchESP"
			highlight.Adornee = char
			highlight.FillTransparency = 0.5
			highlight.OutlineTransparency = 0
			highlight.Parent = char
		end

		highlight.FillColor = color
		highlight.OutlineColor = color

		local tag = head:FindFirstChild("MM2_NameTag")

		if not tag then
			tag = Instance.new("BillboardGui")
			tag.Name = "MM2_NameTag"
			tag.Adornee = head
			tag.Size = UDim2.new(0,160,0,40)
			tag.StudsOffset = Vector3.new(0,2.5,0)
			tag.AlwaysOnTop = true
			tag.Parent = head

			local text = Instance.new("TextLabel")
			text.Name = "TagText"
			text.Size = UDim2.new(1,0,1,0)
			text.BackgroundTransparency = 1
			text.Font = Enum.Font.GothamBold
			text.TextSize = 12
			text.TextStrokeTransparency = 0.5
			text.Parent = tag
		end

		local text = tag:FindFirstChild("TagText")

		if text then
			text.Text = player.Name
			text.TextColor3 = color
		end
	end
end

--============================================================
-- COIN ESP
--============================================================

MM2.State.CoinHighlights = MM2.State.CoinHighlights or {}

local function IsAvailableCoin(obj)
	if not obj or not obj.Parent or not obj:IsA("BasePart") then
		return false
	end

	if obj.Name ~= "Coin_Server" and obj:GetAttribute("CoinID") == nil then
		return false
	end

	local collected = obj:GetAttribute("Collected")

	return collected ~= true and collected ~= "true"
end

local function GetCoinAdornee(coin)
	local visual = coin:FindFirstChild("CoinVisual")

	if visual then
		return visual:FindFirstChild("MainCoin") or visual
	end

	return coin
end

MM2.Functions.ClearCoinESP = function()
	for coin,highlight in pairs(MM2.State.CoinHighlights) do
		if highlight then
			pcall(function()
				highlight:Destroy()
			end)
		end

		MM2.State.CoinHighlights[coin] = nil
	end
end

MM2.Functions.UpdateCoinESP = function()
	if not Flags.CoinESP then return end

	local seen = {}
	local container = workspace:FindFirstChild("CoinContainer",true)

	if container then
		for _,coin in ipairs(container:GetChildren()) do
			if IsAvailableCoin(coin) then
				seen[coin] = true

				if not MM2.State.CoinHighlights[coin] then
					local h = Instance.new("Highlight")
					h.Name = "MM2_CoinESP"
					h.Adornee = GetCoinAdornee(coin)
					h.FillColor = Color3.fromRGB(255,205,55)
					h.OutlineColor = Color3.fromRGB(255,235,150)
					h.FillTransparency = 0.25
					h.OutlineTransparency = 0
					h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					h.Parent = coin

					MM2.State.CoinHighlights[coin] = h
				end
			end
		end
	end

	for coin,highlight in pairs(MM2.State.CoinHighlights) do
		if not seen[coin] or not coin.Parent then
			if highlight then
				pcall(function()
					highlight:Destroy()
				end)
			end

			MM2.State.CoinHighlights[coin] = nil
		end
	end
end

task.spawn(function()
	while MM2.Running do
		if Flags.CoinESP then
			MM2.Functions.UpdateCoinESP()
		elseif next(MM2.State.CoinHighlights) then
			MM2.Functions.ClearCoinESP()
		end

		task.wait(0.15)
	end

	MM2.Functions.ClearCoinESP()
end)

--============================================================
-- GUN ESP
--============================================================

MM2.State.CachedGunDrop = workspace:FindFirstChild("GunDrop",true)
MM2.State.CachedGunPart = nil
MM2.State.GunHighlight = nil
MM2.State.GunTag = nil
MM2.State.HighlightedGun = nil
MM2.State.HighlightedGunPart = nil

local function GetGunPart(gun)
	if not gun then return nil end

	if gun:IsA("BasePart") then
		return gun
	end

	return gun:FindFirstChildWhichIsA("BasePart",true)
end

local function RefreshGunPart()
	MM2.State.CachedGunPart = GetGunPart(
		MM2.State.CachedGunDrop
	)
end

RefreshGunPart()

Track(workspace.DescendantAdded:Connect(function(obj)
	if obj.Name == "GunDrop" then
		MM2.State.CachedGunDrop = obj
		RefreshGunPart()
		MM2.State.GunDroppedThisRound = true
	end
end))

Track(workspace.DescendantRemoving:Connect(function(obj)
	if obj == MM2.State.CachedGunDrop
		or obj == MM2.State.CachedGunPart
	then
		MM2.State.CachedGunDrop = nil
		MM2.State.CachedGunPart = nil

		if MM2.Functions.ClearGunESP then
			MM2.Functions.ClearGunESP()
		end
	end
end))

MM2.Functions.ClearGunESP = function()
	if MM2.State.GunHighlight then
		MM2.State.GunHighlight:Destroy()
		MM2.State.GunHighlight = nil
	end

	if MM2.State.GunTag then
		MM2.State.GunTag:Destroy()
		MM2.State.GunTag = nil
	end

	MM2.State.HighlightedGun = nil
	MM2.State.HighlightedGunPart = nil
end

MM2.Functions.UpdateGunESP = function()
	if not Flags.GunESP then return end

	if not MM2.State.CachedGunDrop
		or not MM2.State.CachedGunDrop.Parent
	then
		MM2.State.CachedGunDrop =
			workspace:FindFirstChild("GunDrop",true)

		RefreshGunPart()
	end

	local gun = MM2.State.CachedGunDrop
	local part = MM2.State.CachedGunPart

	if not gun
		or not gun.Parent
		or not part
		or not part.Parent
	then
		MM2.Functions.ClearGunESP()
		return
	end

	if not MM2.IsPositionWithinESPDistance(part.Position) then
		MM2.Functions.ClearGunESP()
		return
	end

	if MM2.State.HighlightedGun ~= gun
		or MM2.State.HighlightedGunPart ~= part
	then
		MM2.Functions.ClearGunESP()

		MM2.State.HighlightedGun = gun
		MM2.State.HighlightedGunPart = part
	end

	if not MM2.State.GunHighlight then
		local h = Instance.new("Highlight")
		h.Name = "MM2_GunESP"
		h.Adornee = part
		h.FillColor = Color3.fromRGB(255,215,0)
		h.OutlineColor = Color3.fromRGB(255,180,0)
		h.FillTransparency = 0.25
		h.OutlineTransparency = 0
		h.Parent = part

		MM2.State.GunHighlight = h
	end

	if not MM2.State.GunTag then
		local tag = Instance.new("BillboardGui")
		tag.Name = "MM2_GunTag"
		tag.Adornee = part
		tag.Size = UDim2.new(0,180,0,40)
		tag.StudsOffset = Vector3.new(0,1.5,0)
		tag.AlwaysOnTop = true
		tag.Parent = part

		local text = Instance.new("TextLabel")
		text.Name = "TagText"
		text.Size = UDim2.new(1,0,1,0)
		text.BackgroundTransparency = 1
		text.Font = Enum.Font.GothamBold
		text.TextSize = 12
		text.TextColor3 = Color3.fromRGB(255,215,0)
		text.TextStrokeTransparency = 0.5
		text.Text = "[DROPPED GUN]"
		text.Parent = tag

		MM2.State.GunTag = tag
	end
end

--============================================================
-- TRACERS
--============================================================

local TracerGui = Instance.new("ScreenGui")
TracerGui.Name = "MM2_V8_TracerGui"
TracerGui.ResetOnSpawn = false
TracerGui.IgnoreGuiInset = true
TracerGui.DisplayOrder = 5
TracerGui.Parent = MM2.PlayerGui

MM2.UI.TracerGui = TracerGui
MM2.State.TracerLines = {}

local function ShouldShowTracer(role)
	if role == "Murderer" then
		return Flags.MurdererTracer
	elseif role == "Sheriff" then
		return Flags.SheriffTracer
	elseif role == "Hero" then
		return Flags.HeroTracer
	elseif role == "Innocent" then
		return Flags.InnocentTracer
	end

	return false
end

local function GetTracerTargetPart(char)
	if not char then return nil end

	return char:FindFirstChild("UpperTorso")
		or char:FindFirstChild("Torso")
		or char:FindFirstChild("HumanoidRootPart")
end

local function CreateTracer(player)
	local line = Instance.new("Frame")
	line.Name = "Tracer_" .. player.Name
	line.AnchorPoint = Vector2.new(0.5,0.5)
	line.BorderSizePixel = 0
	line.Size = UDim2.fromOffset(0,2)
	line.Visible = false
	line.ZIndex = 20
	line.Parent = TracerGui

	MM2.State.TracerLines[player] = line

	return line
end

MM2.Functions.RemoveTracer = function(player)
	local line = MM2.State.TracerLines[player]

	if line then
		line:Destroy()
	end

	MM2.State.TracerLines[player] = nil
end

MM2.Functions.ClearTracers = function()
	for player,line in pairs(MM2.State.TracerLines) do
		if line then
			line:Destroy()
		end

		MM2.State.TracerLines[player] = nil
	end
end

local function DrawTracer(line,from,to,color)
	local delta = to-from
	local length = delta.Magnitude

	if length < 2 then
		line.Visible = false
		return
	end

	local midpoint = from+delta/2

	line.Position = UDim2.fromOffset(
		midpoint.X,
		midpoint.Y
	)

	line.Size = UDim2.fromOffset(
		length,
		2
	)

	line.Rotation = math.deg(
		math.atan2(delta.Y,delta.X)
	)

	line.BackgroundColor3 = color
	line.Visible = true
end

local function GetTracerOriginPart()
	local spectated = MM2.GetSpectatedPlayer()

	if spectated then
		return GetTracerTargetPart(
			spectated.Character
		)
	end

	return GetTracerTargetPart(
		LocalPlayer.Character
	)
end

MM2.Functions.UpdateTracers = function()
	local Camera = workspace.CurrentCamera

	if not Camera then return end

	local viewport = Camera.ViewportSize
	local originTorso = GetTracerOriginPart()

	if not originTorso then
		for _,line in pairs(MM2.State.TracerLines) do
			line.Visible = false
		end

		return
	end

	local originScreenPos =
		Camera:WorldToViewportPoint(
			originTorso.Position
		)

	local startPoint

	if originScreenPos.Z > 0 then
		startPoint = Vector2.new(
			math.clamp(
				originScreenPos.X,
				2,
				viewport.X-2
			),
			math.clamp(
				originScreenPos.Y,
				2,
				viewport.Y-2
			)
		)
	else
		startPoint = Vector2.new(
			viewport.X/2,
			viewport.Y*0.75
		)
	end

	for _,player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer then
			local line =
				MM2.State.TracerLines[player]

			if line then
				line.Visible = false
			end

			continue
		end

		local char = player.Character

		local humanoid =
			char
			and char:FindFirstChildOfClass(
				"Humanoid"
			)

		local targetPart =
			GetTracerTargetPart(char)

		local role =
			MM2.GetPlayerRole(player)

		local line =
			MM2.State.TracerLines[player]

		if targetPart
			and humanoid
			and humanoid.Health > 0
			and MM2.IsWithinESPDistance(player)
			and ShouldShowTracer(role)
		then

			local targetScreenPos =
				Camera:WorldToViewportPoint(
					targetPart.Position
				)

			local targetPoint

			if targetScreenPos.Z > 0 then
				targetPoint = Vector2.new(
					math.clamp(
						targetScreenPos.X,
						2,
						viewport.X-2
					),
					math.clamp(
						targetScreenPos.Y,
						2,
						viewport.Y-2
					)
				)
			else
				local localPos =
					Camera.CFrame:
					PointToObjectSpace(
						targetPart.Position
					)

				targetPoint =
					localPos.X < 0
					and Vector2.new(
						2,
						viewport.Y/2
					)
					or Vector2.new(
						viewport.X-2,
						viewport.Y/2
					)
			end

			line = line
				or CreateTracer(player)

			DrawTracer(
				line,
				startPoint,
				targetPoint,
				MM2.GetRoleColor(role)
			)

		elseif line then
			line.Visible = false
		end
	end
end

--============================================================
-- ROUND TIMER
--============================================================

local ROUND_LENGTH = 180
local ROUND_WEAPON_LOSS_GRACE = 0.35

local RoundTimerRunning = false
local RoundTimerStartedAt = nil
local RoundTimerLastWeaponTime = 0
local RoundTimerArmed = false

MM2.State.RoundTimerRunning = false
MM2.State.RoundTimerStartedAt = nil

local ToolbarGui = UI.ToolbarGui

local ToolbarOutline =
	ToolbarGui
	and ToolbarGui:FindFirstChild(
		"FloatingOutline"
	)

local RoundTimerHolder
local RoundTimerLabel

if ToolbarOutline then
	local oldTimer =
		ToolbarOutline:FindFirstChild(
			"RoundTimerHolder"
		)

	if oldTimer then
		oldTimer:Destroy()
	end

	RoundTimerHolder = Instance.new("Frame")
	RoundTimerHolder.Name = "RoundTimerHolder"
	RoundTimerHolder.AnchorPoint = Vector2.new(0.5,0)
	RoundTimerHolder.Position = UDim2.new(
		0.5,
		0,
		1,
		7
	)
	RoundTimerHolder.Size =
		UDim2.fromOffset(88,28)

	RoundTimerHolder.BackgroundColor3 =
		Color3.fromRGB(14,18,26)

	RoundTimerHolder.BackgroundTransparency =
		0.12

	RoundTimerHolder.BorderSizePixel = 0
	RoundTimerHolder.Visible = false
	RoundTimerHolder.ZIndex = 50
	RoundTimerHolder.Parent = ToolbarOutline

	local corner = Instance.new("UICorner")
	corner.CornerRadius =
		UDim.new(1,0)
	corner.Parent = RoundTimerHolder

	if UI.CreateBlueCyanStroke then
		UI.CreateBlueCyanStroke(
			RoundTimerHolder,
			1.4,
			0.10
		)
	else
		local stroke = Instance.new("UIStroke")
		stroke.Color =
			Color3.fromRGB(45,140,255)
		stroke.Thickness = 1.4
		stroke.Transparency = 0.10
		stroke.Parent = RoundTimerHolder
	end

	RoundTimerLabel = Instance.new("TextLabel")
	RoundTimerLabel.Name = "Timer"
	RoundTimerLabel.Size = UDim2.fromScale(1,1)
	RoundTimerLabel.BackgroundTransparency = 1
	RoundTimerLabel.Text = "3:00"
	RoundTimerLabel.TextColor3 =
		(UI.COLORS and UI.COLORS.Text)
		or Color3.fromRGB(238,241,248)

	RoundTimerLabel.TextSize = 12
	RoundTimerLabel.Font =
		Enum.Font.GothamBold

	RoundTimerLabel.TextXAlignment =
		Enum.TextXAlignment.Center

	RoundTimerLabel.TextYAlignment =
		Enum.TextYAlignment.Center

	RoundTimerLabel.ZIndex = 51
	RoundTimerLabel.Parent =
		RoundTimerHolder

	UI.RoundTimerHolder =
		RoundTimerHolder

	UI.RoundTimerLabel =
		RoundTimerLabel
end

local function IsRoundWeapon(tool)
	if not tool or not tool:IsA("Tool") then
		return false
	end

	if tool.Name == "Knife"
		or tool.Name == "Gun"
		or tool.Name == "Revolver"
	then
		return true
	end

	if tool:GetAttribute("IsKnife") == true
		or tool:GetAttribute("IsGun") == true
	then
		return true
	end

	return false
end

local function ContainerHasRoundWeapon(container)
	if not container then
		return false
	end

	for _,obj in ipairs(container:GetChildren()) do
		if IsRoundWeapon(obj) then
			return true
		end
	end

	return false
end

local function PlayerHasRoundWeapon(player)
	if not player then
		return false
	end

	local character = player.Character
	local backpack =
		player:FindFirstChildOfClass(
			"Backpack"
		)

	if ContainerHasRoundWeapon(character) then
		return true
	end

	if ContainerHasRoundWeapon(backpack) then
		return true
	end

	return false
end

local function AnyLivePlayerHasRoundWeapon()
	for _,player in ipairs(Players:GetPlayers()) do
		local character = player.Character

		local humanoid =
			character
			and character:FindFirstChildOfClass(
				"Humanoid"
			)

		if humanoid
			and humanoid.Health > 0
			and PlayerHasRoundWeapon(player)
		then
			return true
		end
	end

	return false
end

local function FormatRoundTime(seconds)
	seconds = math.max(
		0,
		math.ceil(seconds)
	)

	local minutes =
		math.floor(seconds/60)

	local secs =
		seconds%60

	return string.format(
		"%d:%02d",
		minutes,
		secs
	)
end

local function HideRoundTimer()
	if RoundTimerHolder then
		RoundTimerHolder.Visible = false
	end
end

local function StopRoundTimer()
	RoundTimerRunning = false
	RoundTimerStartedAt = nil
	RoundTimerLastWeaponTime = 0

	MM2.State.RoundTimerRunning = false
	MM2.State.RoundTimerStartedAt = nil

	HideRoundTimer()
end

local function StartRoundTimer()
	if RoundTimerRunning then
		return
	end

	RoundTimerRunning = true
	RoundTimerStartedAt = os.clock()
	RoundTimerLastWeaponTime = os.clock()
	RoundTimerArmed = false

	MM2.State.RoundTimerRunning = true
	MM2.State.RoundTimerStartedAt =
		RoundTimerStartedAt

	if RoundTimerLabel then
		RoundTimerLabel.Text = "3:00"
	end

	if RoundTimerHolder then
		RoundTimerHolder.Visible =
			Flags.RoundTimer == true
	end
end

MM2.Functions.HideRoundTimer =
	HideRoundTimer

MM2.Functions.StopRoundTimer =
	StopRoundTimer

MM2.Functions.StartRoundTimer =
	StartRoundTimer

MM2.Functions.RefreshRoundTimer =
	function()
		if not RoundTimerHolder then
			return
		end

		RoundTimerHolder.Visible =
			Flags.RoundTimer == true
			and RoundTimerRunning
	end

local function ArmRoundTimer()
	if RoundTimerRunning then
		StopRoundTimer()
	end

	RoundTimerArmed = true
end

--============================================================
-- ROUND EVENT CONNECTIONS
--============================================================

local GameplayRemotes =
	ReplicatedStorage:
	FindFirstChild("Remotes")

GameplayRemotes =
	GameplayRemotes
	and GameplayRemotes:
	FindFirstChild("Gameplay")

local RoundStartRemote =
	GameplayRemotes
	and GameplayRemotes:
	FindFirstChild("RoundStart")

local CoinsStartedRemote =
	GameplayRemotes
	and GameplayRemotes:
	FindFirstChild("CoinsStarted")

local VictoryScreenRemote =
	GameplayRemotes
	and GameplayRemotes:
	FindFirstChild("VictoryScreen")

if RoundStartRemote
	and RoundStartRemote:IsA("RemoteEvent")
then
	Track(
		RoundStartRemote.OnClientEvent:
		Connect(function()
			ArmRoundTimer()
		end)
	)
end

if CoinsStartedRemote
	and CoinsStartedRemote:IsA("RemoteEvent")
then
	Track(
		CoinsStartedRemote.OnClientEvent:
		Connect(function()
			if not RoundTimerRunning then
				RoundTimerArmed = true
			end
		end)
	)
end

if VictoryScreenRemote
	and VictoryScreenRemote:IsA("RemoteEvent")
then
	Track(
		VictoryScreenRemote.OnClientEvent:
		Connect(function()
			RoundTimerArmed = false
			StopRoundTimer()
		end)
	)
end

--============================================================
-- ROUND TIMER UPDATE LOOP
--============================================================

task.spawn(function()
	local hadRoundWeapon = false

	while MM2.Running do
		local hasRoundWeapon =
			AnyLivePlayerHasRoundWeapon()

		-- Weapon appearance is the actual round-start signal.
		if hasRoundWeapon then
			RoundTimerLastWeaponTime =
				os.clock()

			if not RoundTimerRunning then
				if RoundTimerArmed
					or not hadRoundWeapon
				then
					StartRoundTimer()
				end
			end
		end

		if RoundTimerRunning then
			local elapsed =
				os.clock()
				- RoundTimerStartedAt

			local remaining =
				ROUND_LENGTH
				- elapsed

			if remaining <= 0 then
				StopRoundTimer()

			elseif not hasRoundWeapon
				and os.clock()
				- RoundTimerLastWeaponTime
				>= ROUND_WEAPON_LOSS_GRACE
			then
				-- Round weapons are no longer in
				-- any active player's Character
				-- or Backpack.
				StopRoundTimer()

			else
				if RoundTimerLabel then
					RoundTimerLabel.Text =
						FormatRoundTime(
							remaining
						)
				end

				if RoundTimerHolder then
					RoundTimerHolder.Visible =
						Flags.RoundTimer
						== true
				end
			end
		else
			HideRoundTimer()
		end

		hadRoundWeapon = hasRoundWeapon

		task.wait(0.10)
	end

	StopRoundTimer()
end)

--============================================================
-- RENDER CONNECTIONS
--============================================================

Track(
	RunService.RenderStepped:
	Connect(
		MM2.Functions.UpdateTracers
	)
)

return MM2