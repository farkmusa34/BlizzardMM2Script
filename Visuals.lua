--============================================================
-- Blizzard MM2 v1.85.4 VISUALS - Visuals.lua
-- Native WindUI UI + existing visual feature logic
-- Match ESP, Gun ESP, Coin ESP, Tracers, Round Timer.
--
-- Match ESP reliability update:
-- - Shared.lua remains the authority for round/player state.
-- - Eliminated players are removed immediately.
-- - A very short role grace prevents one transient bad role
--   snapshot from destroying otherwise-valid Match ESP.
-- - Existing ESP is rebuilt automatically on new characters.
--============================================================

local MM2 = getgenv and getgenv().MM2_V85_SPLIT or _G.MM2_V85_SPLIT
assert(MM2 and MM2.UI and MM2.UI.WindTabs and MM2.UI.WindTabs.Visuals,
	"Load Shared.lua + UI.lua first"
)

local Players = MM2.Services.Players
local RunService = MM2.Services.RunService
local LocalPlayer = MM2.LocalPlayer
local Flags = MM2.Flags
local UI = MM2.UI
local Track = MM2.Track
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VisualsTab = UI.WindTabs.Visuals

-- RoleRoundActive is owned by Shared.lua.
-- It is driven by live server role assignments.
-- Visuals.lua only consumes the state.

--============================================================
-- NATIVE WINDUI HELPERS
--============================================================

UI.ToggleRegistry = UI.ToggleRegistry or {}

local function CreateNativeToggle(title, desc, flagName, callback)
	Flags[flagName] = Flags[flagName] == true
	local control
	local suppressCallback = false
	local createOK, createResult = pcall(function()
		return VisualsTab:Toggle({
			Title = title,
			Desc = desc,
			Value = Flags[flagName],
			Callback = function(value)
				value = value == true
				Flags[flagName] = value
				-- Ignore programmatic Set() changes.
				if suppressCallback then
					return
				end
				-- Run the actual feature logic.
				if callback then
					local ok, err = pcall(
						callback,
						value
					)
					if not ok then
						warn(
							"[Blizzard Visuals] Toggle callback error:",
							flagName,
							err
						)
					end
				end
				-- WindUI notification. Keep the SAME feature icon for both
				-- Enabled and Disabled; check/x are not state icons anymore.
				pcall(function()
					local icon =
						(UI.ToggleNotificationIcons and UI.ToggleNotificationIcons[flagName])
						or "settings"

					UI.WindUI:Notify({
						Title = tostring(
							title
							or flagName
							or "Feature"
						),
						Content =
							value
							and "Enabled!"
							or "Disabled!",
						Icon = icon,
						Duration = 2.5,
					})
				end)
			end,
		})
	end)
	if createOK then
		control = createResult
	else
		warn(
			"[Blizzard Visuals] Toggle create failed:",
			title,
			createResult
		)
	end
	local function render(value, runCallback)
		value = value == true
		Flags[flagName] = value
		if control and control.Set then
			suppressCallback = true
			pcall(function()
				control:Set(value)
			end)
			suppressCallback = false
		end
		if runCallback and callback then
			pcall(
				callback,
				value
			)
		end
	end
	UI.ToggleRegistry[flagName] = {
		Control = control,
		Render = render,
		Callback = callback,
	}
	return control, control, render
end

local function AddHeading(title, desc)
	local ok, result = pcall(function()
		-- Match the known-good Misc construction: title-only.
		return VisualsTab:Section({
			Title = title,
			Opened = true,
		})
	end)
	if not ok then
		warn(
			"[Blizzard Visuals] Section create failed:",
			title,
			result
		)
		return nil
	end

	-- Reuse UI.lua's exact Misc-style title-only header compaction.
	if UI.CompactTitleOnlySection then
		UI.CompactTitleOnlySection(result)
	end

	return result
end

--============================================================
-- VISUALS UI - DIRECT WINDUI
--============================================================

local function CreateVisualSlider(title, desc, flag, minValue, maxValue, step, default)
    if type(Flags[flag]) ~= "number" then Flags[flag] = default end
    local ok, err = pcall(function()
        VisualsTab:Slider({Title=title, Desc=desc, Value={Min=minValue, Max=maxValue, Default=Flags[flag], Step=step},
            Callback=function(value)
                if type(value)=="number" then Flags[flag]=math.clamp(value,minValue,maxValue) end
            end})
    end)
    if not ok then warn("[Blizzard Visuals] Slider failed:",title,err) end
end

local function CreateVisualDropdown(title, desc, flag, values, default)
    if not table.find(values, Flags[flag]) then Flags[flag]=default end
    local ok, err = pcall(function()
        VisualsTab:Dropdown({Title=title, Desc=desc, Values=values, Value=Flags[flag], Multi=false,
            Callback=function(value)
                if type(value)=="table" then value=value[1] end
                if table.find(values,value) then Flags[flag]=value end
            end})
    end)
    if not ok then warn("[Blizzard Visuals] Dropdown failed:",title,err) end
end

-- Color picker values are stored for future shot diagnostics; no firing hooks are installed.
local function CreateShotColorPicker(title, flag, default)
    Flags[flag] = typeof(Flags[flag])=="Color3" and Flags[flag] or default
    local ok, err = pcall(function()
        VisualsTab:Colorpicker({Title=title, Desc="Color for future bullet effects (not active yet).",
            Default=Flags[flag], Callback=function(value)
                if typeof(value)=="Color3" then Flags[flag]=value end
            end})
    end)
    if not ok then warn("[Blizzard Visuals] Color picker failed:",title,err) end
end

AddHeading("World Visuals")
CreateNativeToggle("Gun ESP", "Highlights the dropped gun.", "GunESP", function(on)
    if not on and MM2.Functions.ClearGunESP then MM2.Functions.ClearGunESP() end
end)
CreateNativeToggle("Coin ESP", "Highlights uncollected coins.", "CoinESP", function(on)
    if not on and MM2.Functions.ClearCoinESP then MM2.Functions.ClearCoinESP() end
end)
CreateNativeToggle("Off-Screen Arrows", "Points toward off-screen players and shows their distance.", "OffScreenArrows", function(on)
    if not on and MM2.Functions.ClearOffScreenArrows then MM2.Functions.ClearOffScreenArrows() end
end)
-- UI-only placeholders: no gunshot observers or bullet effects until diagnostic is complete.
CreateNativeToggle("Bullet Tracers", "Future bullet effects (not active yet).", "BulletTracers")
CreateShotColorPicker("Your Shot Color", "YourShotColor", Color3.fromRGB(45,155,255))
CreateShotColorPicker("Other Players' Shot Color", "OtherShotColor", Color3.fromRGB(255,64,64))
CreateVisualSlider("Bullet Tracer Duration", "Future bullet effect duration (not active yet).", "BulletTracerDuration", 0.1, 2, 0.1, 0.3)
CreateNativeToggle("Round Timer", "Shows the remaining time in the current round.", "RoundTimer", function(on)
    if not on and MM2.Functions.HideRoundTimer then MM2.Functions.HideRoundTimer()
    elseif on and MM2.Functions.RefreshRoundTimer then MM2.Functions.RefreshRoundTimer() end
end)

AddHeading("Tracers")
CreateNativeToggle("Enable Tracers", "Shows role-colored lines pointing toward players.", "EnableTracers", function(on)
    if not on and MM2.Functions.ClearTracers then MM2.Functions.ClearTracers() end
end)
CreateVisualDropdown("Tracer Origin", "Sets where tracers start on your screen.", "TracerOrigin", {"Bottom Center","Center","Top Center"}, "Bottom Center")
Flags.TracerThickness = 1 -- Fixed 1-pixel tracer width; no UI slider.

--============================================================
-- COIN ESP
--============================================================

MM2.State.CoinHighlights = MM2.State.CoinHighlights or {}

local function IsAvailableCoin(obj)
	if not obj or not obj.Parent or not obj:IsA("BasePart") then
		return false
	end

	if obj.Name ~= "Coin_Server"
		and obj:GetAttribute("CoinID") == nil
	then
		return false
	end

	local collected = obj:GetAttribute("Collected")

	return collected ~= true
		and collected ~= "true"
end

local function GetCoinAdornee(coin)
	local visual = coin:FindFirstChild("CoinVisual")

	if visual then
		return visual:FindFirstChild("MainCoin")
			or visual
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

	if not Flags.CoinESP then
		return
	end

	local seen = {}

	local container =
		workspace:FindFirstChild(
			"CoinContainer",
			true
		)

	if container then

		for _,coin in ipairs(
			container:GetChildren()
		) do

			if IsAvailableCoin(coin) then

				seen[coin] = true

				if not MM2.State.CoinHighlights[coin] then

					local h =
						Instance.new(
							"Highlight"
						)

					h.Name =
						"MM2_CoinESP"

					h.Adornee =
						GetCoinAdornee(
							coin
						)

					h.FillColor =
						Color3.fromRGB(
							255,
							205,
							55
						)

					h.OutlineColor =
						Color3.fromRGB(
							255,
							235,
							150
						)

					h.FillTransparency =
						0.25

					h.OutlineTransparency =
						0

					h.DepthMode =
						Enum.HighlightDepthMode.AlwaysOnTop

					h.Parent =
						coin

					MM2.State.CoinHighlights[coin] =
						h
				end
			end
		end
	end

	for coin,highlight in pairs(
		MM2.State.CoinHighlights
	) do

		if not seen[coin]
			or not coin.Parent
		then

			if highlight then
				pcall(function()
					highlight:Destroy()
				end)
			end

			MM2.State.CoinHighlights[coin] =
				nil
		end
	end
end

task.spawn(function()

	while MM2.Running do

		if Flags.CoinESP then

			MM2.Functions.UpdateCoinESP()

		elseif next(
			MM2.State.CoinHighlights
		) then

			MM2.Functions.ClearCoinESP()
		end

		task.wait(0.15)
	end

	MM2.Functions.ClearCoinESP()
end)

--============================================================
-- GUN ESP
--============================================================

MM2.State.CachedGunDrop =
	workspace:FindFirstChild(
		"GunDrop",
		true
	)

MM2.State.CachedGunPart = nil
MM2.State.GunHighlight = nil
MM2.State.GunTag = nil
MM2.State.HighlightedGun = nil
MM2.State.HighlightedGunPart = nil

local function GetGunPart(gun)

	if not gun then
		return nil
	end

	if gun:IsA("BasePart") then
		return gun
	end

	return gun:FindFirstChildWhichIsA(
		"BasePart",
		true
	)
end

local function RefreshGunPart()

	MM2.State.CachedGunPart =
		GetGunPart(
			MM2.State.CachedGunDrop
		)
end

RefreshGunPart()

Track(
	workspace.DescendantAdded:
	Connect(function(obj)

		if obj.Name == "GunDrop" then

			MM2.State.CachedGunDrop =
				obj

			RefreshGunPart()

			MM2.State.GunDroppedThisRound =
				true
		end
	end)
)

Track(
	workspace.DescendantRemoving:
	Connect(function(obj)

		if obj == MM2.State.CachedGunDrop
			or obj == MM2.State.CachedGunPart
		then

			MM2.State.CachedGunDrop =
				nil

			MM2.State.CachedGunPart =
				nil

			if MM2.Functions.ClearGunESP then
				MM2.Functions.ClearGunESP()
			end
		end
	end)
)

MM2.Functions.ClearGunESP = function()

	if MM2.State.GunHighlight then

		MM2.State.GunHighlight:
			Destroy()

		MM2.State.GunHighlight =
			nil
	end

	if MM2.State.GunTag then

		MM2.State.GunTag:
			Destroy()

		MM2.State.GunTag =
			nil
	end

	MM2.State.HighlightedGun =
		nil

	MM2.State.HighlightedGunPart =
		nil
end

MM2.Functions.UpdateGunESP = function()

	if not Flags.GunESP then
		return
	end

	if not MM2.State.CachedGunDrop
		or not MM2.State.CachedGunDrop.Parent
	then

		MM2.State.CachedGunDrop =
			workspace:FindFirstChild(
				"GunDrop",
				true
			)

		RefreshGunPart()
	end

    if MM2.State.CachedGunDrop and (not MM2.State.CachedGunPart or not MM2.State.CachedGunPart:IsDescendantOf(MM2.State.CachedGunDrop)) then
        RefreshGunPart()
    end

	local gun =
		MM2.State.CachedGunDrop

	local part =
		MM2.State.CachedGunPart

	if not gun
		or not gun.Parent
		or not part
		or not part.Parent
	then

		MM2.Functions.ClearGunESP()
		return
	end

	if not MM2.IsPositionWithinESPDistance(
		part.Position
	) then

		MM2.Functions.ClearGunESP()
		return
	end

	if MM2.State.HighlightedGun ~= gun
		or MM2.State.HighlightedGunPart ~= part
	then

		MM2.Functions.ClearGunESP()

		MM2.State.HighlightedGun =
			gun

		MM2.State.HighlightedGunPart =
			part
	end

	if not MM2.State.GunHighlight then

		local h =
			Instance.new(
				"Highlight"
			)

		h.Name =
			"MM2_GunESP"

		h.Adornee =
			part

		h.FillColor =
			Color3.fromRGB(
				255,
				215,
				0
			)

		h.OutlineColor =
			Color3.fromRGB(
				255,
				180,
				0
			)

		h.FillTransparency =
			0.25

		h.OutlineTransparency =
			0

		h.Parent =
			part

		MM2.State.GunHighlight =
			h
	end

	if not MM2.State.GunTag then

		local tag =
			Instance.new(
				"BillboardGui"
			)

		tag.Name =
			"MM2_GunTag"

		tag.Adornee =
			part

		tag.Size =
			UDim2.new(
				0,
				180,
				0,
				40
			)

		tag.StudsOffset =
			Vector3.new(
				0,
				1.5,
				0
			)

		tag.AlwaysOnTop =
			true

		tag.Parent =
			part

		local text =
			Instance.new(
				"TextLabel"
			)

		text.Name =
			"TagText"

		text.Size =
			UDim2.new(
				1,
				0,
				1,
				0
			)

		text.BackgroundTransparency =
			1

		text.Font =
			Enum.Font.GothamBold

		text.TextSize =
			12

		text.TextColor3 =
			Color3.fromRGB(
				255,
				215,
				0
			)

		text.TextStrokeTransparency =
			0.5

		text.Text =
			"Dropped Gun"

		text.Parent =
			tag

		MM2.State.GunTag =
			tag
	end
end

--============================================================
-- TRACERS
--============================================================

local TracerGui =
	Instance.new("ScreenGui")

TracerGui.Name =
	"MM2_V8_TracerGui"

TracerGui.ResetOnSpawn =
	false

TracerGui.IgnoreGuiInset =
	true

TracerGui.DisplayOrder =
	5

TracerGui.Parent =
	MM2.PlayerGui

MM2.UI.TracerGui =
	TracerGui

MM2.State.TracerLines =
	{}

local function ShouldShowTracer(role)
    return Flags.EnableTracers==true and (role=="Murderer" or role=="Sheriff" or role=="Hero" or role=="Innocent")
end

local function GetTracerTargetPart(char)

	if not char then
		return nil
	end

	return char:FindFirstChild(
		"UpperTorso"
	)
		or char:FindFirstChild(
			"Torso"
		)
		or char:FindFirstChild(
			"HumanoidRootPart"
		)
end

local function CreateTracer(player)

	local line =
		Instance.new("Frame")

	line.Name =
		"Tracer_" .. player.Name

	line.AnchorPoint =
		Vector2.new(
			0.5,
			0.5
		)

	line.BorderSizePixel =
		0

	line.Size =
		UDim2.fromOffset(
            0,
            1
        )

	line.Visible =
		false

	line.ZIndex =
		20

	line.Parent =
		TracerGui

	MM2.State.TracerLines[player] =
		line

	return line
end

MM2.Functions.RemoveTracer = function(player)

	local line =
		MM2.State.TracerLines[player]

	if line then
		line:Destroy()
	end

	MM2.State.TracerLines[player] =
		nil
end

MM2.Functions.ClearTracers = function()

	for player,line in pairs(
		MM2.State.TracerLines
	) do

		if line then
			line:Destroy()
		end

		MM2.State.TracerLines[player] =
			nil
	end
end

local function DrawTracer(
	line,
	from,
	to,
	color
)

	local delta =
		to - from

	local length =
		delta.Magnitude

	if length < 2 then

		line.Visible =
			false

		return
	end

	local midpoint =
		from + delta / 2

	line.Position =
		UDim2.fromOffset(
			midpoint.X,
			midpoint.Y
		)

	line.Size =
		UDim2.fromOffset(
            length,
            1
        )

	line.Rotation =
		math.deg(
			math.atan2(
				delta.Y,
				delta.X
			)
		)

	line.BackgroundColor3 =
		color

	line.Visible =
		true
end

local function GetTracerOriginPart()

	local spectated =
		MM2.GetSpectatedPlayer()

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
    if not Flags.EnableTracers then
        for _,line in pairs(MM2.State.TracerLines) do line.Visible=false end
        return
    end

	if MM2.State.RoleRoundActive ~= true then

		for _,line in pairs(
			MM2.State.TracerLines
		) do

			line.Visible =
				false
		end

		return
	end

	local Camera =
		workspace.CurrentCamera

	if not Camera then
		return
	end

	local viewport =
		Camera.ViewportSize

    local startPoint
    if Flags.TracerOrigin=="Top Center" then
        startPoint=Vector2.new(viewport.X/2, 8)
    elseif Flags.TracerOrigin=="Center" then
        startPoint=Vector2.new(viewport.X/2, viewport.Y/2)
    else
        startPoint=Vector2.new(viewport.X/2, viewport.Y-8)
    end

	for _,player in ipairs(
		Players:GetPlayers()
	) do

		if player == LocalPlayer then

			local line =
				MM2.State.TracerLines[
					player
				]

			if line then
				line.Visible = false
			end

			continue
		end

		if MM2.State.PlayerOutOfRound[
			player.Name
		] then

			local line =
				MM2.State.TracerLines[
					player
				]

			if line then
				line.Visible = false
			end

			continue
		end

		local char =
			player.Character

		local humanoid =
			char
			and char:FindFirstChildOfClass(
				"Humanoid"
			)

		local targetPart =
			GetTracerTargetPart(
				char
			)

		local role =
			MM2.GetPlayerRole(
				player
			)

		local line =
			MM2.State.TracerLines[
				player
			]

		if targetPart
			and humanoid
			and humanoid.Health > 0
			and MM2.IsWithinESPDistance(
				player
			)
			and ShouldShowTracer(
				role
			)
		then

			local targetScreenPos =
				Camera:
				WorldToViewportPoint(
					targetPart.Position
				)

			local targetPoint

			if targetScreenPos.Z > 0 then

				targetPoint =
					Vector2.new(
						math.clamp(
							targetScreenPos.X,
							2,
							viewport.X - 2
						),

						math.clamp(
							targetScreenPos.Y,
							2,
							viewport.Y - 2
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
						viewport.Y / 2
					)
					or Vector2.new(
						viewport.X - 2,
						viewport.Y / 2
					)
			end

			line =
				line
				or CreateTracer(
					player
				)

			DrawTracer(
				line,
				startPoint,
				targetPoint,
				MM2.GetRoleColor(
					role
				)
			)

		elseif line then

			line.Visible =
				false
		end
	end
end

--============================================================
-- OFF-SCREEN ROLE ARROWS
--============================================================
local ArrowGui=Instance.new("ScreenGui")
ArrowGui.Name="MM2_OffScreenArrows"
ArrowGui.IgnoreGuiInset=true
ArrowGui.ResetOnSpawn=false
ArrowGui.DisplayOrder=6
ArrowGui.Parent=MM2.PlayerGui
local ArrowLabels={}
MM2.Functions.ClearOffScreenArrows=function()
    for player,label in pairs(ArrowLabels) do
        if label then label:Destroy() end
        ArrowLabels[player]=nil
    end
end
local function UpdateOffScreenArrows()
    if not Flags.OffScreenArrows or not MM2.State.RoleRoundActive then
        for _,label in pairs(ArrowLabels) do label.Visible=false end
        return
    end
    local camera=workspace.CurrentCamera
    if not camera then return end
    local size=camera.ViewportSize
    local origin=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local spectated=MM2.GetSpectatedPlayer and MM2.GetSpectatedPlayer()
    if spectated and spectated.Character then origin=spectated.Character:FindFirstChild("HumanoidRootPart") or origin end
    if not origin then return end
    local alive={}
    for _,player in ipairs(Players:GetPlayers()) do
        if player~=LocalPlayer and not MM2.State.PlayerOutOfRound[player.Name] then
            local char=player.Character
            local hrp=char and char:FindFirstChild("HumanoidRootPart")
            local hum=char and char:FindFirstChildOfClass("Humanoid")
            local role=MM2.GetPlayerRole(player)
            if hrp and hum and hum.Health>0 and MM2.IsPositionWithinESPDistance(hrp.Position)
                and (role=="Murderer" or role=="Sheriff" or role=="Hero" or role=="Innocent") then
                local screen,onScreen=camera:WorldToViewportPoint(hrp.Position)
                if not (onScreen and screen.Z>0) then
                    alive[player]=true
                    local label=ArrowLabels[player]
                    if not label then
                        label=Instance.new("TextLabel")
                        label.Name="Arrow_"..player.Name
                        label.AnchorPoint=Vector2.new(0.5,0.5)
                        label.Size=UDim2.fromOffset(104,35)
                        label.BackgroundTransparency=1
                        label.TextSize=13
                        label.Font=Enum.Font.GothamBold
                        label.TextStrokeTransparency=0.25
                        label.TextWrapped=true
                        label.ZIndex=25
                        label.Parent=ArrowGui
                        ArrowLabels[player]=label
                    end
                    local localPos=camera.CFrame:PointToObjectSpace(hrp.Position)
                    local dx=localPos.X
                    local dy=-localPos.Y
                    if localPos.Z>0 then dx=-dx dy=-dy end
                    local angle=math.atan2(dy,dx)
                    local rx=size.X*0.41
                    local ry=size.Y*0.37
                    label.Position=UDim2.fromOffset(size.X/2+math.cos(angle)*rx,size.Y/2-math.sin(angle)*ry)
                    local arrow=(math.abs(dx)>math.abs(dy)) and (dx>0 and "▶" or "◀") or (dy>0 and "▲" or "▼")
                    label.Text=arrow.." "..role.."\n"..math.floor((hrp.Position-origin.Position).Magnitude+0.5).." studs"
                    label.TextColor3=MM2.GetRoleColor(role)
                    label.Visible=true
                end
            end
        end
    end
    for player,label in pairs(ArrowLabels) do
        if not alive[player] then label.Visible=false end
        if not player.Parent then label:Destroy() ArrowLabels[player]=nil end
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

local RoundTimerHolder =
	Instance.new("Frame")

RoundTimerHolder.Name =
	"RoundTimerHolder"

RoundTimerHolder.AnchorPoint =
	Vector2.new(0.5,0)

RoundTimerHolder.Position =
	UDim2.new(
		0.5,
		0,
		0,
		66
	)

RoundTimerHolder.Size =
	UDim2.fromOffset(
		88,
		28
	)

RoundTimerHolder.BackgroundColor3 =
	Color3.fromRGB(
		14,
		18,
		26
	)

RoundTimerHolder.BackgroundTransparency =
	0.12

RoundTimerHolder.BorderSizePixel =
	0

RoundTimerHolder.Visible =
	false

RoundTimerHolder.ZIndex =
	150

RoundTimerHolder.Parent =
	UI.ScreenGui

local timerCorner =
	Instance.new("UICorner")

timerCorner.CornerRadius =
	UDim.new(
		1,
		0
	)

timerCorner.Parent =
	RoundTimerHolder

if UI.CreateBlueCyanStroke then

	UI.CreateBlueCyanStroke(
		RoundTimerHolder,
		1.4,
		0.10
	)

else

	local stroke =
		Instance.new(
			"UIStroke"
		)

	stroke.Color =
		Color3.fromRGB(
			45,
			140,
			255
		)

	stroke.Thickness =
		1.4

	stroke.Transparency =
		0.10

	stroke.Parent =
		RoundTimerHolder
end

local RoundTimerLabel =
	Instance.new("TextLabel")

RoundTimerLabel.Name =
	"Timer"

RoundTimerLabel.Size =
	UDim2.fromScale(
		1,
		1
	)

RoundTimerLabel.BackgroundTransparency =
	1

RoundTimerLabel.Text =
	"3:00"

RoundTimerLabel.TextColor3 =
	(UI.COLORS and UI.COLORS.Text)
	or Color3.fromRGB(
		238,
		241,
		248
	)

RoundTimerLabel.TextSize =
	12

RoundTimerLabel.Font =
	Enum.Font.GothamBold

RoundTimerLabel.TextXAlignment =
	Enum.TextXAlignment.Center

RoundTimerLabel.TextYAlignment =
	Enum.TextYAlignment.Center

RoundTimerLabel.ZIndex =
	151

RoundTimerLabel.Parent =
	RoundTimerHolder

UI.RoundTimerHolder =
	RoundTimerHolder

UI.RoundTimerLabel =
	RoundTimerLabel

local function IsRoundWeapon(tool)

	if not tool
		or not tool:IsA("Tool")
	then

		return false
	end

	if tool.Name == "Knife"
		or tool.Name == "Gun"
		or tool.Name == "Revolver"
	then

		return true
	end

	if tool:GetAttribute(
		"IsKnife"
	) == true
		or tool:GetAttribute(
			"IsGun"
		) == true
	then

		return true
	end

	return false
end

local function ContainerHasRoundWeapon(
	container
)

	if not container then
		return false
	end

	for _,obj in ipairs(
		container:GetChildren()
	) do

		if IsRoundWeapon(obj) then
			return true
		end
	end

	return false
end

local function PlayerHasRoundWeapon(
	player
)

	if not player then
		return false
	end

	local character =
		player.Character

	local backpack =
		player:FindFirstChildOfClass(
			"Backpack"
		)

	if ContainerHasRoundWeapon(
		character
	) then

		return true
	end

	if ContainerHasRoundWeapon(
		backpack
	) then

		return true
	end

	return false
end

local function AnyLivePlayerHasRoundWeapon()

	for _,player in ipairs(
		Players:GetPlayers()
	) do

		local character =
			player.Character

		local humanoid =
			character
			and character:FindFirstChildOfClass(
				"Humanoid"
			)

		if humanoid
			and humanoid.Health > 0
			and PlayerHasRoundWeapon(
				player
			)
		then

			return true
		end
	end

	return false
end

local function FormatRoundTime(seconds)

	seconds =
		math.max(
			0,
			math.ceil(
				seconds
			)
		)

	local minutes =
		math.floor(
			seconds / 60
		)

	local secs =
		seconds % 60

	return string.format(
		"%d:%02d",
		minutes,
		secs
	)
end

local function HideRoundTimer()

	if RoundTimerHolder then
		RoundTimerHolder.Visible =
			false
	end
end

local function StopRoundTimer()

	RoundTimerRunning =
		false

	RoundTimerStartedAt =
		nil

	RoundTimerLastWeaponTime =
		0

	MM2.State.RoundTimerRunning =
		false

	MM2.State.RoundTimerStartedAt =
		nil

	HideRoundTimer()
end

local function StartRoundTimer()

	if RoundTimerRunning then
		return
	end

	RoundTimerRunning =
		true

	RoundTimerStartedAt =
		os.clock()

	RoundTimerLastWeaponTime =
		os.clock()

	RoundTimerArmed =
		false

	MM2.State.RoundTimerRunning =
		true

	MM2.State.RoundTimerStartedAt =
		RoundTimerStartedAt

	if RoundTimerLabel then

		RoundTimerLabel.Text =
			"3:00"
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

	RoundTimerArmed =
		true
end

--============================================================
-- ROUND EVENT CONNECTIONS
--
-- IMPORTANT:
-- These remotes control the ROUND TIMER ONLY.
-- Role ESP lifecycle is handled by Shared.lua's role data.
--============================================================

local GameplayRemotes =
	ReplicatedStorage:
	FindFirstChild(
		"Remotes"
	)

GameplayRemotes =
	GameplayRemotes
	and GameplayRemotes:
	FindFirstChild(
		"Gameplay"
	)

local RoundStartRemote =
	GameplayRemotes
	and GameplayRemotes:
	FindFirstChild(
		"RoundStart"
	)

local CoinsStartedRemote =
	GameplayRemotes
	and GameplayRemotes:
	FindFirstChild(
		"CoinsStarted"
	)

local VictoryScreenRemote =
	GameplayRemotes
	and GameplayRemotes:
	FindFirstChild(
		"VictoryScreen"
	)

if RoundStartRemote
	and RoundStartRemote:IsA(
		"RemoteEvent"
	)
then

	Track(
		RoundStartRemote.OnClientEvent:
		Connect(function()

			ArmRoundTimer()
		end)
	)
end

if CoinsStartedRemote
	and CoinsStartedRemote:IsA(
		"RemoteEvent"
	)
then

	Track(
		CoinsStartedRemote.OnClientEvent:
		Connect(function()

			if not RoundTimerRunning then

				RoundTimerArmed =
					true
			end
		end)
	)
end

if VictoryScreenRemote
	and VictoryScreenRemote:IsA(
		"RemoteEvent"
	)
then

	Track(
		VictoryScreenRemote.OnClientEvent:
		Connect(function()

			-- Do NOT clear Role ESP here.
			-- Live role/spectator state can continue briefly
			-- after VictoryScreen.

			RoundTimerArmed =
				false

			StopRoundTimer()
		end)
	)
end

--============================================================
-- ROUND TIMER UPDATE LOOP
--============================================================

task.spawn(function()

	local hadRoundWeapon =
		false

	while MM2.Running do

		local hasRoundWeapon =
			AnyLivePlayerHasRoundWeapon()

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

		hadRoundWeapon =
			hasRoundWeapon

		task.wait(0.10)
	end

	StopRoundTimer()
end)

--============================================================
-- RENDER CONNECTIONS
--============================================================
local arrowAccumulator=0
Track(RunService.RenderStepped:Connect(function(dt)
    arrowAccumulator=arrowAccumulator+dt
    if arrowAccumulator>=0.05 then
        arrowAccumulator=0
        UpdateOffScreenArrows()
    end
end))


Track(
	RunService.RenderStepped:
	Connect(
		MM2.Functions.UpdateTracers
	)
)

print(
	"[Blizzard MM2 Visuals] v1.85.5 updated loaded"
)

return MM2
