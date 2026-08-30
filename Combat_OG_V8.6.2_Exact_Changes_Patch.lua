--============================================================
-- Combat.lua PATCH FOR THE ORIGINAL V8.6.2 BASE
-- Keeps the existing Rage Shoot + Rage Throw implementations intact.
--============================================================

--============================================================
-- 1) REPLACE THE ORIGINAL TOP UI SECTION
--    Replace everything from the first UI.AddSection(...)
--    through the Show Kill All Button toggle with this block.
--============================================================

UI.AddSection(UI.CombatPage, "Aim", "Crosshair and aiming features")
UI.CreateToggle(UI.CombatPage, "TriggerBot", "Fire when the crosshair is on the murderer", "TriggerBot")
UI.CreateToggle(UI.CombatPage, "Aim Lock", "Torso aim lock in first-person / lock-center", "AimLock")

UI.AddSection(UI.CombatPage, "Sheriff", "Legit and rage gun features")

-- These two are independent. BOTH may be ON at the same time.
UI.CreateToggle(
	UI.CombatPage,
	"Shoot Murderer (Legit)",
	"Requires clear line of sight; does not shoot through walls",
	"ShowLegitShootButton",
	function(on)
		if MM2.UI.FloatingLegitShootButton then
			MM2.UI.FloatingLegitShootButton.Visible = on
		end
	end
)

UI.CreateToggle(
	UI.CombatPage,
	"Shoot Murderer (Rage)",
	"Keeps the current Rage shooting behavior and can attempt shots through walls",
	"ShowShootButton",
	function(on)
		if MM2.UI.FloatingShootButton then
			MM2.UI.FloatingShootButton.Visible = on
		end
	end
)

UI.CreateToggle(
	UI.CombatPage,
	"Auto Grab Gun",
	"Automatically grabs the gun without moving your body",
	"AutoGrab"
)

UI.AddSection(UI.CombatPage, "Murderer", "Legit and rage knife features")

-- Keep references to the Render callbacks so mutual exclusion updates
-- both the real flag AND the visible switch even with the original UI.lua.
local RenderLegitThrow
local RenderRageThrow

local function SetThrowToggle(flagName, value)
	Flags[flagName] = value == true

	if flagName == "LegitThrow" and RenderLegitThrow then
		RenderLegitThrow(Flags[flagName], false)
	elseif flagName == "RageThrow" and RenderRageThrow then
		RenderRageThrow(Flags[flagName], false)
	end

	-- Also support the newer UI.lua toggle registry if present.
	if UI.SetToggleState then
		UI.SetToggleState(flagName, Flags[flagName], false)
	end
end

do
	local _, _, render = UI.CreateToggle(
		UI.CombatPage,
		"Auto Throw Knife (Legit)",
		"Automatically throws only when the target has clear line of sight",
		"LegitThrow",
		function(on)
			if on then
				SetThrowToggle("RageThrow", false)
			end
		end
	)
	RenderLegitThrow = render
end

do
	local _, _, render = UI.CreateToggle(
		UI.CombatPage,
		"Auto Throw Knife (Rage)",
		"Keeps the existing Rage auto-throw behavior and can target through walls",
		"RageThrow",
		function(on)
			if on then
				SetThrowToggle("LegitThrow", false)
			end
		end
	)
	RenderRageThrow = render
end

-- Normalize an old saved state where both happened to start enabled.
if Flags.LegitThrow and Flags.RageThrow then
	SetThrowToggle("RageThrow", false)
end

UI.CreateActionFeature(UI.CombatPage, "Kill All", "Stabs everyone when murderer", function()
	if MM2.Functions.KillAllOnce then
		local ok,success,message = pcall(MM2.Functions.KillAllOnce)
		if not ok then
			warn("[MM2 KILL ALL ACTION]",success)
			MM2.Notify("Kill All error",2)
		elseif message and message ~= "Cooldown" then
			MM2.Notify(message,1.5)
		end
	end
end)

Flags.ShowKillAllButton = Flags.ShowKillAllButton == true

UI.CreateToggle(
	UI.CombatPage,
	"Show Kill All Button",
	"stab all button",
	"ShowKillAllButton",
	function(on)
		if MM2.UI.FloatingKillAllHolder then
			MM2.UI.FloatingKillAllHolder.Visible = on
		end
	end
)


--============================================================
-- 2) LEGIT SHOOT STATUS TEXT
--    In MM2.Functions.ShootMurdererLegit, replace BOTH:
--
--        return false,"Blocked"
--
--    with:
--============================================================

-- return false,"Murderer Behind Wall"


--============================================================
-- 3) REPLACE FindClosestLegitTarget + LegitThrowOnce +
--    the throw background loop with this block.
--
--    IMPORTANT:
--    RageThrowOnce() itself is NOT changed.
--============================================================

local LastLegitThrow = 0
local LastLegitBlockedNotice = 0

local function FindClosestLegitTarget()
	local character = LocalPlayer.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return nil,nil,false
	end

	local bestPlayer,bestPart,bestDistance = nil,nil,math.huge
	local blockedTargetExists = false

	for _,player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local targetCharacter = player.Character
			local humanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
			local part = GetRageThrowTargetPart(targetCharacter)

			if humanoid and humanoid.Health > 0 and part then
				if HasClearLineOfSight(part) then
					local distance = (part.Position-hrp.Position).Magnitude

					if distance < bestDistance then
						bestDistance,bestPlayer,bestPart = distance,player,part
					end
				else
					blockedTargetExists = true
				end
			end
		end
	end

	return bestPlayer,bestPart,blockedTargetExists
end

local function LegitThrowOnce()
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local hrp = character and character:FindFirstChild("HumanoidRootPart")

	if not character or not humanoid or humanoid.Health <= 0 or not hrp then
		return false,"No Character"
	end

	local knife = character:FindFirstChild("Knife")

	if not knife then
		local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
		local stowed = backpack and backpack:FindFirstChild("Knife")

		if stowed then
			pcall(function()
				humanoid:EquipTool(stowed)
			end)

			task.wait(0.03)
			knife = character:FindFirstChild("Knife")
		end
	end

	if not knife or knife:GetAttribute("Disabled") == true then
		return false,"No Knife"
	end

	local events = knife:FindFirstChild("Events")
	local thrown = events and events:FindFirstChild("KnifeThrown")

	if not thrown or not thrown:IsA("RemoteEvent") then
		return false,"No Throw Remote"
	end

	local cooldown = 1.05 * (tonumber(knife:GetAttribute("ThrowSpeed")) or 1)

	if os.clock()-LastLegitThrow < cooldown then
		return false,"Cooldown"
	end

	local _,targetPart,blockedTargetExists = FindClosestLegitTarget()

	if not targetPart then
		if blockedTargetExists then
			MM2.State.LegitThrowStatus = "Murderer Behind Wall"

			-- Avoid notification spam from the 0.03-second loop.
			if os.clock()-LastLegitBlockedNotice >= 1.5 then
				LastLegitBlockedNotice = os.clock()
				MM2.Notify("Murderer Behind Wall",1)
			end

			return false,"Murderer Behind Wall"
		end

		MM2.State.LegitThrowStatus = "No Target"
		return false,"No Target"
	end

	-- Recheck immediately before the throw in case the target moved
	-- behind a wall after target selection.
	if not HasClearLineOfSight(targetPart) then
		MM2.State.LegitThrowStatus = "Murderer Behind Wall"
		return false,"Murderer Behind Wall"
	end

	local target = targetPart.Position
	local direction = target-hrp.Position
	direction = direction.Magnitude > 0.1
		and direction.Unit
		or Vector3.new(0,0,-1)

	LastLegitThrow = os.clock()

	local ok = pcall(function()
		thrown:FireServer(
			CFrame.new(target-direction*2,target),
			CFrame.new(target)
		)
	end)

	if ok then
		MM2.State.LegitThrowStatus = "Knife Thrown"
		return true,"Knife Thrown"
	end

	return false,"Throw Failed"
end

MM2.Functions.LegitThrowOnce = LegitThrowOnce

task.spawn(function()
	while MM2.Running do
		-- Runtime safety in case another script directly changes Flags.
		if Flags.LegitThrow and Flags.RageThrow then
			SetThrowToggle("RageThrow", false)
		end

		if Flags.LegitThrow then
			LegitThrowOnce()
		elseif Flags.RageThrow then
			-- ORIGINAL RAGE FUNCTION. Do not change its internals.
			RageThrowOnce()
		end

		task.wait(0.03)
	end
end)


--============================================================
-- 4) MOVABLE SHOOT BUTTON HELPER
--    Insert this immediately BEFORE:
--
--        local FloatingShootButton = Instance.new("TextButton")
--
--============================================================

local function MakeShootButtonMovable(button)
	local dragging = false
	local moved = false
	local dragStart = nil
	local startPosition = nil
	local dragInput = nil

	Track(button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			moved = false
			dragStart = input.Position
			startPosition = button.Position

			Track(input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false

					if moved then
						button:SetAttribute("_JustDragged",true)

						task.delay(0.10,function()
							if button and button.Parent then
								button:SetAttribute("_JustDragged",false)
							end
						end)
					end
				end
			end))
		end
	end))

	Track(button.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragInput = input
		end
	end))

	Track(UIS.InputChanged:Connect(function(input)
		if not dragging or input ~= dragInput or not dragStart or not startPosition then
			return
		end

		local delta = input.Position-dragStart

		if delta.Magnitude >= 4 then
			moved = true
		end

		if moved then
			button.Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset+delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset+delta.Y
			)
		end
	end))
end


--============================================================
-- 5) AFTER EACH SHOOT BUTTON IS CREATED, CALL THE HELPER.
--============================================================

-- After:
-- MM2.UI.FloatingShootButton = FloatingShootButton
--
-- add:
-- MakeShootButtonMovable(FloatingShootButton)

-- After:
-- MM2.UI.FloatingLegitShootButton = FloatingLegitShootButton
--
-- add:
-- MakeShootButtonMovable(FloatingLegitShootButton)


--============================================================
-- 6) AT THE START OF BOTH MouseButton1Click CALLBACKS,
--    add this guard so releasing a drag doesn't also shoot.
--============================================================

-- if FloatingShootButton:GetAttribute("_JustDragged") then return end

-- and for Legit:

-- if FloatingLegitShootButton:GetAttribute("_JustDragged") then return end


--============================================================
-- 7) EXACT BUTTON TEXT NAMES
--============================================================

-- Rage:
-- FloatingShootButton.Text = "Shoot Murderer (Rage)"
-- reset text after click to "Shoot Murderer (Rage)"

-- Legit:
-- FloatingLegitShootButton.Text = "Shoot Murderer (Legit)"
-- reset text after click to "Shoot Murderer (Legit)"

--============================================================
-- END PATCH
--============================================================
