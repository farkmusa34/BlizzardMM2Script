--============================================================
-- MM2 V8.5 SPLIT BUILD - Main.lua
--
-- Load order:
-- 1. Shared.lua
-- 2. UI.lua
-- 3. Visuals.lua
-- 4. Combat.lua
-- 5. AutoFarm.lua
-- 6. Player.lua
-- 7. Fling.lua
-- 8. Main.lua
--============================================================

local MM2 = getgenv and getgenv().MM2_V85_SPLIT or _G.MM2_V85_SPLIT
assert(MM2, "Shared.lua must load first")

local Players = MM2.Services.Players
local RunService = MM2.Services.RunService
local LocalPlayer = MM2.LocalPlayer
local Flags = MM2.Flags
local Track = MM2.Track

task.spawn(function()
	while MM2.Running do
		MM2.UpdateServerRoles()
		task.wait(0.2)
	end
end)

task.spawn(function()
	while MM2.Running do
		task.wait(0.08)

		MM2.UpdateRoundReset()

		if MM2.Functions.UpdatePlayerESP then
			MM2.Functions.UpdatePlayerESP()
		end

		if MM2.Functions.UpdateGunESP then
			MM2.Functions.UpdateGunESP()
		end

		if MM2.Functions.UpdateAutoGrab then
			MM2.Functions.UpdateAutoGrab()
		end

		if MM2.Functions.UpdateAutoFarm then
			MM2.Functions.UpdateAutoFarm()
		end

		local _,humanoid = MM2.GetLocalCharacter()
		if humanoid then
			if math.abs(humanoid.WalkSpeed - MM2.PlayerSettings.WalkSpeed) > 0.01 then
				humanoid.WalkSpeed = MM2.PlayerSettings.WalkSpeed
			end

			humanoid.UseJumpPower = true

			if math.abs(humanoid.JumpPower - MM2.PlayerSettings.JumpPower) > 0.01 then
				humanoid.JumpPower = MM2.PlayerSettings.JumpPower
			end
		end
	end
end)

Track(Players.PlayerRemoving:Connect(function(player)
	if MM2.Functions.RemovePlayerESP then
		MM2.Functions.RemovePlayerESP(player)
	end

	if MM2.Functions.RemoveTracer then
		MM2.Functions.RemoveTracer(player)
	end

	MM2.State.ServerRolesCache[player.Name] = nil
	MM2.State.RecentRespawns[player.Name] = nil
	MM2.State.PlayerOutOfRound[player.Name] = nil

	if MM2.State.SelectedFlingTarget == player then
		MM2.State.SelectedFlingTarget = nil
		if MM2.UI.TargetStatus then
			MM2.UI.TargetStatus.Text = "None"
		end
	end
end))

Track(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	if workspace.CurrentCamera then
		MM2.Camera = workspace.CurrentCamera
	end
end))

function MM2.Cleanup()
	if not MM2.Running then return end

	MM2.Running = false
	MM2.State.Is_Picking_Up = false

	Flags.AutoGrab = false
	Flags.AutoFarm = false
	Flags.Fly = false
	Flags.Noclip = false

	if MM2.Functions.StopFling then
		MM2.Functions.StopFling()
	end

	if MM2.Functions.StopAutoFarm then
		MM2.Functions.StopAutoFarm()
	end

	if MM2.Functions.StopFly then
		MM2.Functions.StopFly()
	end

	if MM2.Functions.StopPlayerNoclip then
		MM2.Functions.StopPlayerNoclip()
	end

	pcall(function()
		RunService:UnbindFromRenderStep("MM2_V8_CombatFeatures")
	end)

	for _,conn in ipairs(MM2.Connections) do
		pcall(function()
			conn:Disconnect()
		end)
	end

	if MM2.Functions.ClearPlayerESP then
		MM2.Functions.ClearPlayerESP()
	end

	if MM2.Functions.ClearGunESP then
		MM2.Functions.ClearGunESP()
	end

	if MM2.Functions.ClearTracers then
		MM2.Functions.ClearTracers()
	end

	if MM2.UI.ScreenGui then
		MM2.UI.ScreenGui:Destroy()
	end

	if MM2.UI.ToolbarGui then
		MM2.UI.ToolbarGui:Destroy()
	end

	if MM2.UI.TracerGui then
		MM2.UI.TracerGui:Destroy()
	end

	if getgenv then
		getgenv().MM2_V85_SPLIT = nil
	else
		_G.MM2_V85_SPLIT = nil
	end
end

if getgenv then
	getgenv().MM2_V8_Cleanup = MM2.Cleanup
end

MM2.UI.ShowPage("Visuals")
MM2.Notify("Murder Mystery 2 Script V8.5 split build loaded",2)

print("[MM2 V8.5 SPLIT] ALL MODULES LOADED")
