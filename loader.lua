--============================================================
-- MM2 V8.5 SPLIT BUILD - MASTER BOOTSTRAP LOADER
--============================================================
print("[MM2 LOADER] Initiating secure multi-file bootstrap sequence...")

-- 1. Corrected base URL pointing directly to your raw repository path
local BaseURL = "https://raw.githubusercontent.com/farkmusa34/BlizzardMM2Script/refs/heads/main/"

-- 2. Clean up any leftover active instances before booting up
if _G.MM2_V85_SPLIT and _G.MM2_V85_SPLIT.Cleanup then
    pcall(_G.MM2_V85_SPLIT.Cleanup)
    task.wait(0.3)
end

-- 3. Sequentially download and execute every single module in your exact load order
local function LoadModule(fileName)
    local targetURL = BaseURL .. fileName
    local success, scriptContent = pcall(function()
        return game:HttpGet(targetURL)
    end)
    
    if success and scriptContent and scriptContent ~= "404: Not Found" then
        local fn, err = loadstring(scriptContent)
        if fn then
            fn()
            print("[MM2 LOADER] Successfully synced: " .. fileName)
        else
            warn("[MM2 LOADER] SYNTAX/COMPILE ERROR IN " .. fileName .. ": " .. tostring(err))
        end
    else
        warn("[MM2 LOADER] FAILED TO SYNC REQUIRED CLASS: " .. fileName .. " (URL: " .. targetURL .. ")")
    end
end

-- Your exact structural sequential load order map
LoadModule("Shared.lua")   -- Must execute first to initialize global tables
LoadModule("UI.lua")       -- Mounts UI classes
LoadModule("Visuals.lua")  -- Attaches ESP tracking algorithms
LoadModule("Combat.lua")   -- Mounts hit detection wrappers
LoadModule("AutoFarm.lua") -- Injects position farming logic
LoadModule("Player.lua")   -- Custom walkspeed hooks
LoadModule("Fling.lua")    -- Physics exploits
LoadModule("Misc.lua")
LoadModule("Main.lua")     -- Spawns runtime environment loops

print("[MM2 LOADER] Bootstrap sequence complete.")