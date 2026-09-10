--============================================================
-- Blizzard MM2 V8.8.4 VISUALS - Visuals.lua[span_0](start_span)[span_0](end_span)
-- Native WindUI UI + existing visual feature logic[span_1](start_span)[span_1](end_span)
-- Match ESP, Gun ESP, Coin ESP, Tracers, Round Timer.[span_2](start_span)[span_2](end_span)
--============================================================

local MM2 = getgenv and getgenv().MM2_V85_SPLIT or _G.MM2_V85_SPLIT[span_3](start_span)[span_3](end_span)
assert(MM2 and MM2.UI and MM2.UI.WindTabs and MM2.UI.WindTabs.Visuals,[span_4](start_span)[span_4](end_span)
	"Load Shared.lua + native WindUI UI.lua first")[span_5](start_span)[span_5](end_span)

local Players = MM2.Services.Players[span_6](start_span)[span_6](end_span)
local RunService = MM2.Services.RunService[span_7](start_span)[span_7](end_span)
local LocalPlayer = MM2.LocalPlayer[span_8](start_span)[span_8](end_span)
local Flags = MM2.Flags[span_9](start_span)[span_9](end_span)
local UI = MM2.UI[span_10](start_span)[span_10](end_span)
local Track = MM2.Track[span_11](start_span)[span_11](end_span)
local ReplicatedStorage = game:GetService("ReplicatedStorage")[span_12](start_span)[span_12](end_span)

local VisualsTab = UI.WindTabs.Visuals[span_13](start_span)[span_13](end_span)
print("[Blizzard Visuals] Native module started; VisualsTab =", VisualsTab)[span_14](start_span)[span_14](end_span)

--============================================================
-- NATIVE WINDUI HELPERS
--============================================================

UI.ToggleRegistry = UI.ToggleRegistry or {}[span_15](start_span)[span_15](end_span)

local function CreateNativeToggle(title, desc, flagName, callback)[span_16](start_span)[span_16](end_span)
	Flags[flagName] = Flags[flagName] == true[span_17](start_span)[span_17](end_span)

	local control[span_18](start_span)[span_18](end_span)
	local suppressCallback = false[span_19](start_span)[span_19](end_span)

	local createOK, createResult = pcall(function()[span_20](start_span)[span_20](end_span)
		return VisualsTab:Toggle({[span_21](start_span)[span_21](end_span)
			Title = title,[span_22](start_span)[span_22](end_span)
			Desc = desc,[span_23](start_span)[span_23](end_span)
			Value = Flags[flagName],[span_24](start_span)[span_24](end_span)
			Callback = function(value)[span_25](start_span)[span_25](end_span)
				value = value == true[span_26](start_span)[span_26](end_span)
				Flags[flagName] = value[span_27](start_span)[span_27](end_span)

				if suppressCallback then[span_28](start_span)[span_28](end_span)
					return[span_29](start_span)[span_29](end_span)
				end[span_30](start_span)[span_30](end_span)

				if callback then[span_31](start_span)[span_31](end_span)
					local ok, err = pcall(callback, value)[span_32](start_span)[span_32](end_span)
					if not ok then[span_33](start_span)[span_33](end_span)
						warn("[Blizzard Visuals] Toggle callback error:", flagName, err)[span_34](start_span)[span_34](end_span)
					end[span_35](start_span)[span_35](end_span)
				end[span_36](start_span)[span_36](end_span)
			end,[span_37](start_span)[span_37](end_span)
		})[span_38](start_span)[span_38](end_span)
	end)[span_39](start_span)[span_39](end_span)

	if createOK then[span_40](start_span)[span_40](end_span)
		control = createResult[span_41](start_span)[span_41](end_span)
		print("[Blizzard Visuals] Added:", title)[span_42](start_span)[span_42](end_span)
	else[span_43](start_span)[span_43](end_span)
		warn("[Blizzard Visuals] Toggle failed:", title, createResult)[span_44](start_span)[span_44](end_span)
	end[span_45](start_span)[span_45](end_span)

	local function render(value, runCallback)[span_46](start_span)[span_46](end_span)
		value = value == true[span_47](start_span)[span_47](end_span)
		Flags[flagName] = value[span_48](start_span)[span_48](end_span)

		if control and control.Set then[span_49](start_span)[span_49](end_span)
			suppressCallback = true[span_50](start_span)[span_50](end_span)
			pcall(function()[span_51](start_span)[span_51](end_span)
				control:Set(value)[span_52](start_span)[span_52](end_span)
			end)[span_53](start_span)[span_53](end_span)
			suppressCallback = false[span_54](start_span)[span_54](end_span)
		end[span_55](start_span)[span_55](end_span)

		if runCallback and callback then[span_56](start_span)[span_56](end_span)
			pcall(callback, value)[span_57](start_span)[span_57](end_span)
		end[span_58](start_span)[span_58](end_span)
	end[span_59](start_span)[span_59](end_span)

	UI.ToggleRegistry[flagName] = {[span_60](start_span)[span_60](end_span)
		Control = control,[span_61](start_span)[span_61](end_span)
		Render = render,[span_62](start_span)[span_62](end_span)
		Callback = callback,[span_63](start_span)[span_63](end_span)
	}[span_64](start_span)[span_64](end_span)

	return control, control, render[span_65](start_span)[span_65](end_span)
end[span_66](start_span)[span_66](end_span)

local function AddHeading(title, desc)[span_67](start_span)[span_67](end_span)
	local ok, result = pcall(function()[span_68](start_span)[span_68](end_span)
		return VisualsTab:Section({[span_69](start_span)[span_69](end_span)
			Title = title,[span_70](start_span)[span_70](end_span)
			Desc = desc or "",[span_71](start_span)[span_71](end_span)
			Opened = true,[span_72](start_span)[span_72](end_span)
		})[span_73](start_span)[span_73](end_span)
	end)[span_74](start_span)[span_74](end_span)

	if ok then[span_75](start_span)[span_75](end_span)
		print("[Blizzard Visuals] Section added:", title)[span_76](start_span)[span_76](end_span)
	else[span_77](start_span)[span_77](end_span)
		warn("[Blizzard Visuals] Section failed:", title, result)[span_78](start_span)[span_78](end_span)
	end[span_79](start_span)[span_79](end_span)

	return result[span_80](start_span)[span_80](end_span)
end[span_81](start_span)[span_81](end_span)

--============================================================
-- VISUALS UI - DIRECT WINDUI
-- Same style as the original working visual prototype:
-- Section heading, then controls directly on the tab.
--============================================================

AddHeading("Visuals", "ESP controls")[span_82](start_span)[span_82](end_span)

CreateNativeToggle([span_83](start_span)[span_83](end_span)
	"Coin ESP",[span_84](start_span)[span_84](end_span)
	"Highlight uncollected coins",[span_85](start_span)[span_85](end_span)
	"CoinESP",[span_86](start_span)[span_86](end_span)
	function(on)[span_87](start_span)[span_87](end_span)
		if not on and MM2.Functions.ClearCoinESP then[span_88](start_span)[span_88](end_span)
			MM2.Functions.ClearCoinESP()[span_89](start_span)[span_89](end_span)
		end[span_90](start_span)[span_90](end_span)
	end[span_91](start_span)[span_91](end_span)
)[span_92](start_span)[span_92](end_span)

CreateNativeToggle([span_93](start_span)[span_93](end_span)
	"Match ESP",[span_94](start_span)[span_94](end_span)
	"Highlight players using detected roles",[span_95](start_span)[span_95](end_span)
	"MatchESP",[span_96](start_span)[span_96](end_span)
	function(on)[span_97](start_span)[span_97](end_span)
		if not on and MM2.Functions.ClearPlayerESP then[span_98](start_span)[span_98](end_span)
			MM2.Functions.ClearPlayerESP()[span_99](start_span)[span_99](end_span)
		end[span_100](start_span)[span_100](end_span)
	end[span_101](start_span)[span_101](end_span)
)[span_102](start_span)[span_102](end_span)

CreateNativeToggle([span_103](start_span)[span_103](end_span)
	"Gun ESP",[span_104](start_span)[span_104](end_span)
	"Highlight the dropped gun",[span_105](start_span)[span_105](end_span)
	"GunESP",[span_106](start_span)[span_106](end_span)
	function(on)[span_107](start_span)[span_107](end_span)
		if not on and MM2.Functions.ClearGunESP then[span_108](start_span)[span_108](end_span)
			MM2.Functions.ClearGunESP()[span_109](start_span)[span_109](end_span)
		end[span_110](start_span)[span_110](end_span)
	end[span_111](start_span)[span_111](end_span)
)[span_112](start_span)[span_112](end_span)

--============================================================
-- ROUND TIMER UI
--============================================================

Flags.RoundTimer = Flags.RoundTimer == true[span_113](start_span)[span_113](end_span)

AddHeading("Round", "Round information")[span_114](start_span)[span_114](end_span)

CreateNativeToggle([span_115](start_span)[span_115](end_span)
	"Round Timer",[span_116](start_span)[span_116](end_span)
	"Shows the remaining time in the current round",[span_117](start_span)[span_117](end_span)
	"RoundTimer",[span_118](start_span)[span_118](end_span)
	function(on)[span_119](start_span)[span_119](end_span)
		if not on and MM2.Functions.HideRoundTimer then[span_120](start_span)[span_120](end_span)
			MM2.Functions.HideRoundTimer()[span_121](start_span)[span_121](end_span)
		elseif on and MM2.Functions.RefreshRoundTimer then[span_122](start_span)[span_122](end_span)
			MM2.Functions.RefreshRoundTimer()[span_123](start_span)[span_123](end_span)
		end[span_124](start_span)[span_124](end_span)
	end[span_125](start_span)[span_125](end_span)
)[span_126](start_span)[span_126](end_span)

--============================================================
-- TRACERS UI
--============================================================

AddHeading("Tracers", "Role-based screen tracers")[span_127](start_span)[span_127](end_span)

for _, item in ipairs({[span_128](start_span)[span_128](end_span)
	{"Murderer Tracer", "Track the murderer", "MurdererTracer"},[span_129](start_span)[span_129](end_span)
	{"Sheriff Tracer", "Track the sheriff", "SheriffTracer"},[span_130](start_span)[span_130](end_span)
	{"Hero Tracer", "Track the hero", "HeroTracer"},[span_131](start_span)[span_131](end_span)
	{"Innocent Tracer", "Track innocents", "InnocentTracer"},[span_132](start_span)[span_132](end_span)
}) do[span_133](start_span)[span_133](end_span)
	CreateNativeToggle([span_134](start_span)[span_134](end_span)
		item[1],[span_135](start_span)[span_135](end_span)
		item[2],[span_136](start_span)[span_136](end_span)
		item[3],[span_137](start_span)[span_137](end_span)
		function(on)[span_138](start_span)[span_138](end_span)
			if not on and MM2.Functions.ClearTracers then[span_139](start_span)[span_139](end_span)
				MM2.Functions.ClearTracers()[span_140](start_span)[span_140](end_span)
			end[span_141](start_span)[span_141](end_span)
		end[span_142](start_span)[span_142](end_span)
	)[span_143](start_span)[span_143](end_span)
end[span_144](start_span)[span_144](end_span)

--============================================================
-- PLAYER ESP
--============================================================

local function RemovePlayerESP(player)[span_145](start_span)[span_145](end_span)
	local char = player.Character[span_146](start_span)[span_146](end_span)
	if not char then return end[span_147](start_span)[span_147](end_span)

	local highlight = char:FindFirstChild("MM2_MatchESP")[span_148](start_span)[span_148](end_span)
	if highlight then highlight:Destroy() end[span_149](start_span)[span_149](end_span)

	local head = char:FindFirstChild("Head")[span_150](start_span)[span_150](end_span)
	if head then[span_151](start_span)[span_151](end_span)
		local tag = head:FindFirstChild("MM2_NameTag")[span_152](start_span)[span_152](end_span)
		if tag then tag:Destroy() end[span_153](start_span)[span_153](end_span)
	end[span_154](start_span)[span_154](end_span)
end[span_155](start_span)[span_155](end_span)

MM2.Functions.RemovePlayerESP = RemovePlayerESP[span_156](start_span)[span_156](end_span)

MM2.Functions.ClearPlayerESP = function()[span_157](start_span)[span_157](end_span)
	for _, player in ipairs(Players:GetPlayers()) do[span_158](start_span)[span_158](end_span)
		RemovePlayerESP(player)[span_159](start_span)[span_159](end_span)
	end[span_160](start_span)[span_160](end_span)
end[span_161](start_span)[span_161](end_span)

MM2.Functions.UpdatePlayerESP = function()[span_162](start_span)[span_162](end_span)
	if not Flags.MatchESP then return end[span_163](start_span)[span_163](end_span)

	for _, player in ipairs(Players:GetPlayers()) do[span_164](start_span)[span_164](end_span)
		if player == LocalPlayer then[span_165](start_span)[span_165](end_span)
			RemovePlayerESP(player)[span_166](start_span)[span_166](end_span)
			continue[span_167](start_span)[span_167](end_span)
		end[span_168](start_span)[span_168](end_span)

		local char = player.Character[span_169](start_span)[span_169](end_span)
		local head = char and char:FindFirstChild("Head")[span_170](start_span)[span_170](end_span)
		local hrp = char and char:FindFirstChild("HumanoidRootPart")[span_171](start_span)[span_171](end_span)

		if not char or not head or not hrp[span_172](start_span)[span_172](end_span)
			or not MM2.IsPositionWithinESPDistance(hrp.Position)[span_173](start_span)[span_173](end_span)
		then[span_174](start_span)[span_174](end_span)
			RemovePlayerESP(player)[span_175](start_span)[span_175](end_span)
			continue[span_176](start_span)[span_176](end_span)
		end[span_177](start_span)[span_177](end_span)

		local role = MM2.GetPlayerRole(player)[span_178](start_span)[span_178](end_span)

		if role == "None" then[span_179](start_span)[span_179](end_span)
			RemovePlayerESP(player)[span_180](start_span)[span_180](end_span)
			continue[span_181](start_span)[span_181](end_span)
		end[span_182](start_span)[span_182](end_span)

		local color = MM2.GetRoleColor(role)[span_183](start_span)[span_183](end_span)
		local highlight = char:FindFirstChild("MM2_MatchESP")[span_184](start_span)[span_184](end_span)

		if not highlight then[span_185](start_span)[span_185](end_span)
			highlight = Instance.new("Highlight")[span_186](start_span)[span_186](end_span)
			highlight.Name = "MM2_MatchESP[span_187](start_span)"[span_187](end_span)
			highlight.Adornee = char[span_188](start_span)[span_188](end_span)
			highlight.FillTransparency = 0.5[span_189](start_span)[span_189](end_span)
			highlight.OutlineTransparency = 0[span_190](start_span)[span_190](end_span)
			highlight.Parent = char[span_191](start_span)[span_191](end_span)
		end[span_192](start_span)[span_192](end_span)

		highlight.FillColor = color[span_193](start_span)[span_193](end_span)
		highlight.OutlineColor = color[span_194](start_span)[span_194](end_span)

		local tag = head:FindFirstChild("MM2_NameTag")[span_195](start_span)[span_195](end_span)

		if not tag then[span_196](start_span)[span_196](end_span)
			tag = Instance.new("BillboardGui")[span_197](start_span)[span_197](end_span)
			tag.Name = "MM2_NameTag[span_198](start_span)"[span_198](end_span)
			tag.Adornee = head[span_199](start_span)[span_199](end_span)
			tag.Size = UDim2.new(0,160,0,40)[span_200](start_span)[span_200](end_span)
			tag.StudsOffset = Vector3.new(0,2.5,0)[span_201](start_span)[span_201](end_span)
			tag.AlwaysOnTop = true[span_202](start_span)[span_202](end_span)
			tag.Parent = head[span_203](start_span)[span_203](end_span)

			local text = Instance.new("TextLabel")[span_204](start_span)[span_204](end_span)
			text.Name = "TagText[span_205](start_span)"[span_205](end_span)
			text.Size = UDim2.new(1,0,1,0)[span_206](start_span)[span_206](end_span)
			text.BackgroundTransparency = 1[span_207](start_span)[span_207](end_span)
			text.Font = Enum.Font.GothamBold[span_208](start_span)[span_208](end_span)
			text.TextSize = 12[span_209](start_span)[span_209](end_span)
			text.TextStrokeTransparency = 0.5[span_210](start_span)[span_210](end_span)
			text.Parent = tag[span_211](start_span)[span_211](end_span)
		end[span_212](start_span)[span_212](end_span)

		local text = tag:FindFirstChild("TagText")[span_213](start_span)[span_213](end_span)

		if text then[span_214](start_span)[span_214](end_span)
			text.Text = player.Name[span_215](start_span)[span_215](end_span)
			text.TextColor3 = color[span_216](start_span)[span_216](end_span)
		end[span_217](start_span)[span_217](end_span)
	end[span_218](start_span)[span_218](end_span)
end[span_219](start_span)[span_219](end_span)

--============================================================
-- COIN ESP
--============================================================

MM2.State.CoinHighlights = MM2.State.CoinHighlights or {}[span_220](start_span)[span_220](end_span)

local function IsAvailableCoin(obj)[span_221](start_span)[span_221](end_span)
	if not obj or not obj.Parent or not obj:IsA("BasePart") then[span_222](start_span)[span_222](end_span)
		return false[span_223](start_span)[span_223](end_span)
	end[span_224](start_span)[span_224](end_span)

	if obj.Name ~= "Coin_Server" and obj:GetAttribute("CoinID") == nil then[span_225](start_span)[span_225](end_span)
		return false[span_226](start_span)[span_226](end_span)
	end[span_227](start_span)[span_227](end_span)

	local collected = obj:GetAttribute("Collected")[span_228](start_span)[span_228](end_span)

	return collected ~= true and collected ~= "true[span_229](start_span)"[span_229](end_span)
end[span_230](start_span)[span_230](end_span)

local function GetCoinAdornee(coin)[span_231](start_span)[span_231](end_span)
	local visual = coin:FindFirstChild("CoinVisual")[span_232](start_span)[span_232](end_span)

	if visual then[span_233](start_span)[span_233](end_span)
		return visual:FindFirstChild("MainCoin") or visual[span_234](start_span)[span_234](end_span)
	end[span_235](start_span)[span_235](end_span)

	return coin[span_236](start_span)[span_236](end_span)
end[span_237](start_span)[span_237](end_span)

MM2.Functions.ClearCoinESP = function()[span_238](start_span)[span_238](end_span)
	for coin,highlight in pairs(MM2.State.CoinHighlights) do[span_239](start_span)[span_239](end_span)
		if highlight then[span_240](start_span)[span_240](end_span)
			pcall(function()[span_241](start_span)[span_241](end_span)
				highlight:Destroy()[span_242](start_span)[span_242](end_span)
			end)[span_243](start_span)[span_243](end_span)
		end[span_244](start_span)[span_244](end_span)

		MM2.State.CoinHighlights[coin] = nil[span_245](start_span)[span_245](end_span)
	end[span_246](start_span)[span_246](end_span)
end[span_247](start_span)[span_247](end_span)

MM2.Functions.UpdateCoinESP = function()[span_248](start_span)[span_248](end_span)
	if not Flags.CoinESP then return end[span_249](start_span)[span_249](end_span)

	local seen = {}[span_250](start_span)[span_250](end_span)
	local container = workspace:FindFirstChild("CoinContainer",true)[span_251](start_span)[span_251](end_span)

	if container then[span_252](start_span)[span_252](end_span)
		for _,coin in ipairs(container:GetChildren()) do[span_253](start_span)[span_253](end_span)
			if IsAvailableCoin(coin) then[span_254](start_span)[span_254](end_span)
				seen[coin] = true[span_255](start_span)[span_255](end_span)

				if not MM2.State.CoinHighlights[coin] then[span_256](start_span)[span_256](end_span)
					local h = Instance.new("Highlight")[span_257](start_span)[span_257](end_span)
					h.Name = "MM2_CoinESP[span_258](start_span)"[span_258](end_span)
					h.Adornee = GetCoinAdornee(coin)[span_259](start_span)[span_259](end_span)
					h.FillColor = Color3.fromRGB(255,205,55)[span_260](start_span)[span_260](end_span)
					h.OutlineColor = Color3.fromRGB(255,235,150)[span_261](start_span)[span_261](end_span)
					h.FillTransparency = 0.25[span_262](start_span)[span_262](end_span)
					h.OutlineTransparency = 0[span_263](start_span)[span_263](end_span)
					h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop[span_264](start_span)[span_264](end_span)
					h.Parent = coin[span_265](start_span)[span_265](end_span)

					MM2.State.CoinHighlights[coin] = h[span_266](start_span)[span_266](end_span)
				end[span_267](start_span)[span_267](end_span)
			end[span_268](start_span)[span_268](end_span)
		end[span_269](start_span)[span_269](end_span)
	end[span_270](start_span)[span_270](end_span)

	for coin,highlight in pairs(MM2.State.CoinHighlights) do[span_271](start_span)[span_271](end_span)
		if not seen[coin] or not coin.Parent then[span_272](start_span)[span_272](end_span)
			if highlight then[span_273](start_span)[span_273](end_span)
				pcall(function()[span_274](start_span)[span_274](end_span)
					highlight:Destroy()[span_275](start_span)[span_275](end_span)
				end)[span_276](start_span)[span_276](end_span)
			end[span_277](start_span)[span_277](end_span)

			MM2.State.CoinHighlights[coin] = nil[span_278](start_span)[span_278](end_span)
		end[span_279](start_span)[span_279](end_span)
	end[span_280](start_span)[span_280](end_span)
end[span_281](start_span)[span_281](end_span)

task.spawn(function()[span_282](start_span)[span_282](end_span)
	while MM2.Running do[span_283](start_span)[span_283](end_span)
		if Flags.CoinESP then[span_284](start_span)[span_284](end_span)
			MM2.Functions.UpdateCoinESP()[span_285](start_span)[span_285](end_span)
		elseif next(MM2.State.CoinHighlights) then[span_286](start_span)[span_286](end_span)
			MM2.Functions.ClearCoinESP()[span_287](start_span)[span_287](end_span)
		end[span_288](start_span)[span_288](end_span)

		task.wait(0.15)[span_289](start_span)[span_289](end_span)
	end[span_290](start_span)[span_290](end_span)

	MM2.Functions.ClearCoinESP()[span_291](start_span)[span_291](end_span)
end)[span_292](start_span)[span_292](end_span)

--============================================================
-- GUN ESP
--============================================================

MM2.State.CachedGunDrop = workspace:FindFirstChild("GunDrop",true)[span_293](start_span)[span_293](end_span)
MM2.State.CachedGunPart = nil[span_294](start_span)[span_294](end_span)
MM2.State.GunHighlight = nil[span_295](start_span)[span_295](end_span)
MM2.State.GunTag = nil[span_296](start_span)[span_296](end_span)
MM2.State.HighlightedGun = nil[span_297](start_span)[span_297](end_span)
MM2.State.HighlightedGunPart = nil[span_298](start_span)[span_298](end_span)

local function GetGunPart(gun)[span_299](start_span)[span_299](end_span)
	if not gun then return nil end[span_300](start_span)[span_300](end_span)

	if gun:IsA("BasePart") then[span_301](start_span)[span_301](end_span)
		return gun[span_302](start_span)[span_302](end_span)
	end[span_303](start_span)[span_303](end_span)

	return gun:FindFirstChildWhichIsA("BasePart",true)[span_304](start_span)[span_304](end_span)
end[span_305](start_span)[span_305](end_span)

local function RefreshGunPart()[span_306](start_span)[span_306](end_span)
	MM2.State.CachedGunPart = GetGunPart([span_307](start_span)[span_307](end_span)
		MM2.State.CachedGunDrop[span_308](start_span)[span_308](end_span)
	)[span_309](start_span)[span_309](end_span)
end[span_310](start_span)[span_310](end_span)

RefreshGunPart()[span_311](start_span)[span_311](end_span)

Track(workspace.DescendantAdded:Connect(function(obj)[span_312](start_span)[span_312](end_span)
	if obj.Name == "GunDrop" then[span_313](start_span)[span_313](end_span)
		MM2.State.CachedGunDrop = obj[span_314](start_span)[span_314](end_span)
		RefreshGunPart()[span_315](start_span)[span_315](end_span)
		MM2.State.GunDroppedThisRound = true[span_316](start_span)[span_316](end_span)
	end[span_317](start_span)[span_317](end_span)
end))[span_318](start_span)[span_318](end_span)

Track(workspace.DescendantRemoving:Connect(function(obj)[span_319](start_span)[span_319](end_span)
	if obj == MM2.State.CachedGunDrop[span_320](start_span)[span_320](end_span)
		or obj == MM2.State.CachedGunPart[span_321](start_span)[span_321](end_span)
	then[span_322](start_span)[span_322](end_span)
		MM2.State.CachedGunDrop = nil[span_323](start_span)[span_323](end_span)
		MM2.State.CachedGunPart = nil[span_324](start_span)[span_324](end_span)

		if MM2.Functions.ClearGunESP then[span_325](start_span)[span_325](end_span)
			MM2.Functions.ClearGunESP()[span_326](start_span)[span_326](end_span)
		end[span_327](start_span)[span_327](end_span)
	end[span_328](start_span)[span_328](end_span)
end))[span_329](start_span)[span_329](end_span)

MM2.Functions.ClearGunESP = function()[span_330](start_span)[span_330](end_span)
	if MM2.State.GunHighlight then[span_331](start_span)[span_331](end_span)
		MM2.State.GunHighlight:Destroy()[span_332](start_span)[span_332](end_span)
		MM2.State.GunHighlight = nil[span_333](start_span)[span_333](end_span)
	end[span_334](start_span)[span_334](end_span)

	if MM2.State.GunTag then[span_335](start_span)[span_335](end_span)
		MM2.State.GunTag:Destroy()[span_336](start_span)[span_336](end_span)
		MM2.State.GunTag = nil[span_337](start_span)[span_337](end_span)
	end[span_338](start_span)[span_338](end_span)

	MM2.State.HighlightedGun = nil[span_339](start_span)[span_339](end_span)
	MM2.State.HighlightedGunPart = nil[span_340](start_span)[span_340](end_span)
end[span_341](start_span)[span_341](end_span)

MM2.Functions.UpdateGunESP = function()[span_342](start_span)[span_342](end_span)
	if not Flags.GunESP then return end[span_343](start_span)[span_343](end_span)

	if not MM2.State.CachedGunDrop[span_344](start_span)[span_344](end_span)
		or not MM2.State.CachedGunDrop.Parent[span_345](start_span)[span_345](end_span)
	then[span_346](start_span)[span_346](end_span)
		MM2.State.CachedGunDrop =[span_347](start_span)[span_347](end_span)
			workspace:FindFirstChild("GunDrop",true)[span_348](start_span)[span_348](end_span)

		RefreshGunPart()[span_349](start_span)[span_349](end_span)
	end[span_350](start_span)[span_350](end_span)

	local gun = MM2.State.CachedGunDrop[span_351](start_span)[span_351](end_span)
	local part = MM2.State.CachedGunPart[span_352](start_span)[span_352](end_span)

	if not gun[span_353](start_span)[span_353](end_span)
		or not gun.Parent[span_354](start_span)[span_354](end_span)
		or not part[span_355](start_span)[span_355](end_span)
		or not part.Parent[span_356](start_span)[span_356](end_span)
	then[span_357](start_span)[span_357](end_span)
		MM2.Functions.ClearGunESP()[span_358](start_span)[span_358](end_span)
		return[span_359](start_span)[span_359](end_span)
	end[span_360](start_span)[span_360](end_span)

	if not MM2.IsPositionWithinESPDistance(part.Position) then[span_361](start_span)[span_361](end_span)
		MM2.Functions.ClearGunESP()[span_362](start_span)[span_362](end_span)
		return[span_363](start_span)[span_363](end_span)
	end[span_364](start_span)[span_364](end_span)

	if MM2.State.HighlightedGun ~= gun[span_365](start_span)[span_365](end_span)
		or MM2.State.HighlightedGunPart ~= part[span_366](start_span)[span_366](end_span)
	then[span_367](start_span)[span_367](end_span)
		MM2.Functions.ClearGunESP()[span_368](start_span)[span_368](end_span)

		MM2.State.HighlightedGun = gun[span_369](start_span)[span_369](end_span)
		MM2.State.HighlightedGunPart = part[span_370](start_span)[span_370](end_span)
	end[span_371](start_span)[span_371](end_span)

	if not MM2.State.GunHighlight then[span_372](start_span)[span_372](end_span)
		local h = Instance.new("Highlight")[span_373](start_span)[span_373](end_span)
		h.Name = "MM2_GunESP[span_374](start_span)"[span_374](end_span)
		h.Adornee = part[span_375](start_span)[span_375](end_span)
		h.FillColor = Color3.fromRGB(255,215,0)[span_376](start_span)[span_376](end_span)
		h.OutlineColor = Color3.fromRGB(255,180,0)[span_377](start_span)[span_377](end_span)
		h.FillTransparency = 0.25[span_378](start_span)[span_378](end_span)
		h.OutlineTransparency = 0[span_379](start_span)[span_379](end_span)
		h.Parent = part[span_380](start_span)[span_380](end_span)

		MM2.State.GunHighlight = h[span_381](start_span)[span_381](end_span)
	end[span_382](start_span)[span_382](end_span)

	if not MM2.State.GunTag then[span_383](start_span)[span_383](end_span)
		local tag = Instance.new("BillboardGui")[span_384](start_span)[span_384](end_span)
		tag.Name = "MM2_GunTag[span_385](start_span)"[span_385](end_span)
		tag.Adornee = part[span_386](start_span)[span_386](end_span)
		tag.Size = UDim2.new(0,180,0,40)[span_387](start_span)[span_387](end_span)
		tag.StudsOffset = Vector3.new(0,1.5,0)[span_388](start_span)[span_388](end_span)
		tag.AlwaysOnTop = true[span_389](start_span)[span_389](end_span)
		tag.Parent = part[span_390](start_span)[span_390](end_span)

		local text = Instance.new("TextLabel")[span_391](start_span)[span_391](end_span)
		text.Name = "TagText[span_392](start_span)"[span_392](end_span)
		text.Size = UDim2.new(1,0,1,0)[span_393](start_span)[span_393](end_span)
		text.BackgroundTransparency = 1[span_394](start_span)[span_394](end_span)
		text.Font = Enum.Font.GothamBold[span_395](start_span)[span_395](end_span)
		text.TextSize = 12[span_396](start_span)[span_396](end_span)
		text.TextColor3 = Color3.fromRGB(255,215,0)[span_397](start_span)[span_397](end_span)
		text.TextStrokeTransparency = 0.5[span_398](start_span)[span_398](end_span)
		text.Text = "[DROPPED GUN][span_399](start_span)"[span_399](end_span)
		text.Parent = tag[span_400](start_span)[span_400](end_span)

		MM2.State.GunTag = tag[span_401](start_span)[span_401](end_span)
	end[span_402](start_span)[span_402](end_span)
end[span_403](start_span)[span_403](end_span)

--============================================================
-- TRACERS
--============================================================

local TracerGui = Instance.new("ScreenGui")[span_404](start_span)[span_404](end_span)
TracerGui.Name = "MM2_V8_TracerGui[span_405](start_span)"[span_405](end_span)
TracerGui.ResetOnSpawn = false[span_406](start_span)[span_406](end_span)
TracerGui.IgnoreGuiInset = true[span_407](start_span)[span_407](end_span)
TracerGui.DisplayOrder = 5[span_408](start_span)[span_408](end_span)
TracerGui.Parent = MM2.PlayerGui[span_409](start_span)[span_409](end_span)

MM2.UI.TracerGui = TracerGui[span_410](start_span)[span_410](end_span)
MM2.State.TracerLines = {}[span_411](start_span)[span_411](end_span)

local function ShouldShowTracer(role)[span_412](start_span)[span_412](end_span)
	if role == "Murderer" then[span_413](start_span)[span_413](end_span)
		return Flags.MurdererTracer[span_414](start_span)[span_414](end_span)
	elseif role == "Sheriff" then[span_415](start_span)[span_415](end_span)
		return Flags.SheriffTracer[span_416](start_span)[span_416](end_span)
	elseif role == "Hero" then[span_417](start_span)[span_417](end_span)
		return Flags.HeroTracer[span_418](start_span)[span_418](end_span)
	elseif role == "Innocent" then[span_419](start_span)[span_419](end_span)
		return Flags.InnocentTracer[span_420](start_span)[span_420](end_span)
	end[span_421](start_span)[span_421](end_span)

	return false[span_422](start_span)[span_422](end_span)
end[span_423](start_span)[span_423](end_span)

local function GetTracerTargetPart(char)[span_424](start_span)[span_424](end_span)
	if not char then return nil end[span_425](start_span)[span_425](end_span)

	return char:FindFirstChild("UpperTorso")[span_426](start_span)[span_426](end_span)
		or char:FindFirstChild("Torso")[span_427](start_span)[span_427](end_span)
		or char:FindFirstChild("HumanoidRootPart")[span_428](start_span)[span_428](end_span)
end[span_429](start_span)[span_429](end_span)

local function CreateTracer(player)[span_430](start_span)[span_430](end_span)
	local line = Instance.new("Frame")[span_431](start_span)[span_431](end_span)
	line.Name = "Tracer_" .. player.Name[span_432](start_span)[span_432](end_span)
	line.AnchorPoint = Vector2.new(0.5,0.5)[span_433](start_span)[span_433](end_span)
	line.BorderSizePixel = 0[span_434](start_span)[span_434](end_span)
	line.Size = UDim2.fromOffset(0,2)[span_435](start_span)[span_435](end_span)
	line.Visible = false[span_436](start_span)[span_436](end_span)
	line.ZIndex = 20[span_437](start_span)[span_437](end_span)
	line.Parent = TracerGui[span_438](start_span)[span_438](end_span)

	MM2.State.TracerLines[player] = line[span_439](start_span)[span_439](end_span)

	return line[span_440](start_span)[span_440](end_span)
end[span_441](start_span)[span_441](end_span)

MM2.Functions.RemoveTracer = function(player)[span_442](start_span)[span_442](end_span)
	local line = MM2.State.TracerLines[player][span_443](start_span)[span_443](end_span)

	if line then[span_444](start_span)[span_444](end_span)
		line:Destroy()[span_445](start_span)[span_445](end_span)
	end[span_446](start_span)[span_446](end_span)

	MM2.State.TracerLines[player] = nil[span_447](start_span)[span_447](end_span)
end[span_448](start_span)[span_448](end_span)

MM2.Functions.ClearTracers = function()[span_449](start_span)[span_449](end_span)
	for player,line in pairs(MM2.State.TracerLines) do[span_450](start_span)[span_450](end_span)
		if line then[span_451](start_span)[span_451](end_span)
			line:Destroy()[span_452](start_span)[span_452](end_span)
		end[span_453](start_span)[span_453](end_span)

		MM2.State.TracerLines[player] = nil[span_454](start_span)[span_454](end_span)
	end[span_455](start_span)[span_455](end_span)
end[span_456](start_span)[span_456](end_span)

local function DrawTracer(line,from,to,color)[span_457](start_span)[span_457](end_span)
	local delta = to-from[span_458](start_span)[span_458](end_span)
	local length = delta.Magnitude[span_459](start_span)[span_459](end_span)

	if length < 2 then[span_460](start_span)[span_460](end_span)
		line.Visible = false[span_461](start_span)[span_461](end_span)
		return[span_462](start_span)[span_462](end_span)
	end[span_463](start_span)[span_463](end_span)

	local midpoint = from+delta/2[span_464](start_span)[span_464](end_span)

	line.Position = UDim2.fromOffset([span_465](start_span)[span_465](end_span)
		midpoint.X,[span_466](start_span)[span_466](end_span)
		midpoint.Y[span_467](start_span)[span_467](end_span)
	)[span_468](start_span)[span_468](end_span)

	line.Size = UDim2.fromOffset([span_469](start_span)[span_469](end_span)
		length,[span_470](start_span)[span_470](end_span)
		2[span_471](start_span)[span_471](end_span)
	)[span_472](start_span)[span_472](end_span)

	line.Rotation = math.deg([span_473](start_span)[span_473](end_span)
		math.atan2(delta.Y,delta.X)[span_474](start_span)[span_474](end_span)
	)[span_475](start_span)[span_475](end_span)

	line.BackgroundColor3 = color[span_476](start_span)[span_476](end_span)
	line.Visible = true[span_477](start_span)[span_477](end_span)
end[span_478](start_span)[span_478](end_span)

local function GetTracerOriginPart()[span_479](start_span)[span_479](end_span)
	local spectated = MM2.GetSpectatedPlayer()[span_480](start_span)[span_480](end_span)

	if spectated then[span_481](start_span)[span_481](end_span)
		return GetTracerTargetPart([span_482](start_span)[span_482](end_span)
			spectated.Character[span_483](start_span)[span_483](end_span)
		)[span_484](start_span)[span_484](end_span)
	end[span_485](start_span)[span_485](end_span)

	return GetTracerTargetPart([span_486](start_span)[span_486](end_span)
		LocalPlayer.Character[span_487](start_span)[span_487](end_span)
	)[span_488](start_span)[span_488](end_span)
end[span_489](start_span)[span_489](end_span)

MM2.Functions.UpdateTracers = function()[span_490](start_span)[span_490](end_span)
	local Camera = workspace.CurrentCamera[span_491](start_span)[span_491](end_span)

	if not Camera then return end[span_492](start_span)[span_492](end_span)

	local viewport = Camera.ViewportSize[span_493](start_span)[span_493](end_span)
	local originTorso = GetTracerOriginPart()[span_494](start_span)[span_494](end_span)

	if not originTorso then[span_495](start_span)[span_495](end_span)
		for _,line in pairs(MM2.State.TracerLines) do[span_496](start_span)[span_496](end_span)
			line.Visible = false[span_497](start_span)[span_497](end_span)
		end[span_498](start_span)[span_498](end_span)

		return[span_499](start_span)[span_499](end_span)
	end[span_500](start_span)[span_500](end_span)

	local originScreenPos =[span_501](start_span)[span_501](end_span)
		Camera:WorldToViewportPoint([span_502](start_span)[span_502](end_span)
			originTorso.Position[span_503](start_span)[span_503](end_span)
		)[span_504](start_span)[span_504](end_span)

	local startPoint[span_505](start_span)[span_505](end_span)

	if originScreenPos.Z > 0 then[span_506](start_span)[span_506](end_span)
		startPoint = Vector2.new([span_507](start_span)[span_507](end_span)
			math.clamp([span_508](start_span)[span_508](end_span)
				originScreenPos.X,[span_509](start_span)[span_509](end_span)
				2,[span_510](start_span)[span_510](end_span)
				viewport.X-2[span_511](start_span)[span_511](end_span)
			),[span_512](start_span)[span_512](end_span)
			math.clamp([span_513](start_span)[span_513](end_span)
				originScreenPos.Y,[span_514](start_span)[span_514](end_span)
				2,[span_515](start_span)[span_515](end_span)
				viewport.Y-2[span_516](start_span)[span_516](end_span)
			)[span_517](start_span)[span_517](end_span)
		)[span_518](start_span)[span_518](end_span)
	else[span_519](start_span)[span_519](end_span)
		startPoint = Vector2.new([span_520](start_span)[span_520](end_span)
			viewport.X/2,[span_521](start_span)[span_521](end_span)
			viewport.Y*0.75[span_522](start_span)[span_522](end_span)
		)[span_523](start_span)[span_523](end_span)
	end[span_524](start_span)[span_524](end_span)

	for _,player in ipairs(Players:GetPlayers()) do[span_525](start_span)[span_525](end_span)
		if player == LocalPlayer then[span_526](start_span)[span_526](end_span)
			local line =[span_527](start_span)[span_527](end_span)
				MM2.State.TracerLines[player][span_528](start_span)[span_528](end_span)

			if line then[span_529](start_span)[span_529](end_span)
				line.Visible = false[span_530](start_span)[span_530](end_span)
			end[span_531](start_span)[span_531](end_span)

			continue[span_532](start_span)[span_532](end_span)
		end[span_533](start_span)[span_533](end_span)

		local char = player.Character[span_534](start_span)[span_534](end_span)

		local humanoid =[span_535](start_span)[span_535](end_span)
			char[span_536](start_span)[span_536](end_span)
			and char:FindFirstChildOfClass([span_537](start_span)[span_537](end_span)
				"Humanoid[span_538](start_span)"[span_538](end_span)
			)[span_539](start_span)[span_539](end_span)

		local targetPart =[span_540](start_span)[span_540](end_span)
			GetTracerTargetPart(char)[span_541](start_span)[span_541](end_span)

		local role =[span_542](start_span)[span_542](end_span)
			MM2.GetPlayerRole(player)[span_543](start_span)[span_543](end_span)

		local line =[span_544](start_span)[span_544](end_span)
			MM2.State.TracerLines[player][span_545](start_span)[span_545](end_span)

		if targetPart[span_546](start_span)[span_546](end_span)
			and humanoid[span_547](start_span)[span_547](end_span)
			and humanoid.Health > 0[span_548](start_span)[span_548](end_span)
			and MM2.IsWithinESPDistance(player)[span_549](start_span)[span_549](end_span)
			and ShouldShowTracer(role)[span_550](start_span)[span_550](end_span)
		then[span_551](start_span)[span_551](end_span)

			local targetScreenPos =[span_552](start_span)[span_552](end_span)
				Camera:WorldToViewportPoint([span_553](start_span)[span_553](end_span)
					targetPart.Position[span_554](start_span)[span_554](end_span)
				)[span_555](start_span)[span_555](end_span)

			local targetPoint[span_556](start_span)[span_556](end_span)

			if targetScreenPos.Z > 0 then[span_557](start_span)[span_557](end_span)
				targetPoint = Vector2.new([span_558](start_span)[span_558](end_span)
					math.clamp([span_559](start_span)[span_559](end_span)
						targetScreenPos.X,[span_560](start_span)[span_560](end_span)
						2,[span_561](start_span)[span_561](end_span)
						viewport.X-2[span_562](start_span)[span_562](end_span)
					),[span_563](start_span)[span_563](end_span)
					math.clamp([span_564](start_span)[span_564](end_span)
						targetScreenPos.Y,[span_565](start_span)[span_565](end_span)
						2,[span_566](start_span)[span_566](end_span)
						viewport.Y-2[span_567](start_span)[span_567](end_span)
					)[span_568](start_span)[span_568](end_span)
				)[span_569](start_span)[span_569](end_span)
			else[span_570](start_span)[span_570](end_span)
				local localPos =[span_571](start_span)[span_571](end_span)
					Camera.CFrame:[span_572](start_span)[span_572](end_span)
					PointToObjectSpace([span_573](start_span)[span_573](end_span)
						targetPart.Position[span_574](start_span)[span_574](end_span)
					)[span_575](start_span)[span_575](end_span)

				targetPoint =[span_576](start_span)[span_576](end_span)
					localPos.X < 0[span_577](start_span)[span_577](end_span)
					and Vector2.new([span_578](start_span)[span_578](end_span)
						2,[span_579](start_span)[span_579](end_span)
						viewport.Y/2[span_580](start_span)[span_580](end_span)
					)[span_581](start_span)[span_581](end_span)
					or Vector2.new([span_582](start_span)[span_582](end_span)
						viewport.X-2,[span_583](start_span)[span_583](end_span)
						viewport.Y/2[span_584](start_span)[span_584](end_span)
					)[span_585](start_span)[span_585](end_span)
			end[span_586](start_span)[span_586](end_span)

			line = line[span_587](start_span)[span_587](end_span)
				or CreateTracer(player)[span_588](start_span)[span_588](end_span)

			DrawTracer([span_589](start_span)[span_589](end_span)
				line,[span_590](start_span)[span_590](end_span)
				startPoint,[span_591](start_span)[span_591](end_span)
				targetPoint,[span_592](start_span)[span_592](end_span)
				MM2.GetRoleColor(role)[span_593](start_span)[span_593](end_span)
			)[span_594](start_span)[span_594](end_span)

		elseif line then[span_595](start_span)[span_595](end_span)
			line.Visible = false[span_596](start_span)[span_596](end_span)
		end[span_597](start_span)[span_597](end_span)
	end[span_598](start_span)[span_598](end_span)
end[span_599](start_span)[span_599](end_span)

--============================================================
-- ROUND TIMER
--============================================================

local ROUND_LENGTH = 180[span_600](start_span)[span_600](end_span)
local ROUND_WEAPON_LOSS_GRACE = 0.35[span_601](start_span)[span_601](end_span)

local RoundTimerRunning = false[span_602](start_span)[span_602](end_span)
local RoundTimerStartedAt = nil[span_603](start_span)[span_603](end_span)
local RoundTimerLastWeaponTime = 0[span_604](start_span)[span_604](end_span)
local RoundTimerArmed = false[span_605](start_span)[span_605](end_span)

MM2.State.RoundTimerRunning = false[span_606](start_span)[span_606](end_span)
MM2.State.RoundTimerStartedAt = nil[span_607](start_span)[span_607](end_span)

-- Native WindUI uses its own opener, so the legacy toolbar is hidden.
-- Keep the timer as its own small visible overlay instead.
local RoundTimerHolder = Instance.new("Frame")[span_608](start_span)[span_608](end_span)
RoundTimerHolder.Name = "RoundTimerHolder[span_609](start_span)"[span_609](end_span)
RoundTimerHolder.AnchorPoint = Vector2.new(0.5,0)[span_610](start_span)[span_610](end_span)
RoundTimerHolder.Position = UDim2.new(0.5,0,0,66)[span_611](start_span)[span_611](end_span)
RoundTimerHolder.Size = UDim2.fromOffset(88,28)[span_612](start_span)[span_612](end_span)
RoundTimerHolder.BackgroundColor3 = Color3.fromRGB(14,18,26)[span_613](start_span)[span_613](end_span)
RoundTimerHolder.BackgroundTransparency = 0.12[span_614](start_span)[span_614](end_span)
RoundTimerHolder.BorderSizePixel = 0[span_615](start_span)[span_615](end_span)
RoundTimerHolder.Visible = false[span_616](start_span)[span_616](end_span)
RoundTimerHolder.ZIndex = 150[span_617](start_span)[span_617](end_span)
RoundTimerHolder.Parent = UI.ScreenGui[span_618](start_span)[span_618](end_span)

local timerCorner = Instance.new("UICorner")[span_619](start_span)[span_619](end_span)
timerCorner.CornerRadius = UDim.new(1,0)[span_620](start_span)[span_620](end_span)
timerCorner.Parent = RoundTimerHolder[span_621](start_span)[span_621](end_span)

if UI.CreateBlueCyanStroke then[span_622](start_span)[span_622](end_span)
	UI.CreateBlueCyanStroke([span_623](start_span)[span_623](end_span)
		RoundTimerHolder,[span_624](start_span)[span_624](end_span)
		1.4,[span_625](start_span)[span_625](end_span)
		0.10[span_626](start_span)[span_626](end_span)
	)[span_627](start_span)[span_627](end_span)
else[span_628](start_span)[span_628](end_span)
	local stroke = Instance.new("UIStroke")[span_629](start_span)[span_629](end_span)
	stroke.Color = Color3.fromRGB(45,140,255)[span_630](start_span)[span_630](end_span)
	stroke.Thickness = 1.4[span_631](start_span)[span_631](end_span)
	stroke.Transparency = 0.10[span_632](start_span)[span_632](end_span)
	stroke.Parent = RoundTimerHolder[span_633](start_span)[span_633](end_span)
end[span_634](start_span)[span_634](end_span)

local RoundTimerLabel = Instance.new("TextLabel")[span_635](start_span)[span_635](end_span)
RoundTimerLabel.Name = "Timer[span_636](start_span)"[span_636](end_span)
RoundTimerLabel.Size = UDim2.fromScale(1,1)[span_637](start_span)[span_637](end_span)
RoundTimerLabel.BackgroundTransparency = 1[span_638](start_span)[span_638](end_span)
RoundTimerLabel.Text = "3:00[span_639](start_span)"[span_639](end_span)
RoundTimerLabel.TextColor3 =[span_640](start_span)[span_640](end_span)
	(UI.COLORS and UI.COLORS.Text)[span_641](start_span)[span_641](end_span)
	or Color3.fromRGB(238,241,248)[span_642](start_span)[span_642](end_span)

RoundTimerLabel.TextSize = 12[span_643](start_span)[span_643](end_span)
RoundTimerLabel.Font = Enum.Font.GothamBold[span_644](start_span)[span_644](end_span)
RoundTimerLabel.TextXAlignment = Enum.TextXAlignment.Center[span_645](start_span)[span_645](end_span)
RoundTimerLabel.TextYAlignment = Enum.TextYAlignment.Center[span_646](start_span)[span_646](end_span)
RoundTimerLabel.ZIndex = 151[span_647](start_span)[span_647](end_span)
RoundTimerLabel.Parent = RoundTimerHolder[span_648](start_span)[span_648](end_span)

UI.RoundTimerHolder = RoundTimerHolder[span_649](start_span)[span_649](end_span)
UI.RoundTimerLabel = RoundTimerLabel[span_650](start_span)[span_650](end_span)

local function IsRoundWeapon(tool)[span_651](start_span)[span_651](end_span)
	if not tool or not tool:IsA("Tool") then[span_652](start_span)[span_652](end_span)
		return false[span_653](start_span)[span_653](end_span)
	end[span_654](start_span)[span_654](end_span)

	if tool.Name == "Knife[span_655](start_span)"[span_655](end_span)
		or tool.Name == "Gun[span_656](start_span)"[span_656](end_span)
		or tool.Name == "Revolver[span_657](start_span)"[span_657](end_span)
	then[span_658](start_span)[span_658](end_span)
		return true[span_659](start_span)[span_659](end_span)
	end[span_660](start_span)[span_660](end_span)

	if tool:GetAttribute("IsKnife") == true[span_661](start_span)[span_661](end_span)
		or tool:GetAttribute("IsGun") == true[span_662](start_span)[span_662](end_span)
	then[span_663](start_span)[span_663](end_span)
		return true[span_664](start_span)[span_664](end_span)
	end[span_665](start_span)[span_665](end_span)

	return false[span_666](start_span)[span_666](end_span)
end[span_667](start_span)[span_667](end_span)

local function ContainerHasRoundWeapon(container)[span_668](start_span)[span_668](end_span)
	if not container then[span_669](start_span)[span_669](end_span)
		return false[span_670](start_span)[span_670](end_span)
	end[span_671](start_span)[span_671](end_span)

	for _,obj in ipairs(container:GetChildren()) do[span_672](start_span)[span_672](end_span)
		if IsRoundWeapon(obj) then[span_673](start_span)[span_673](end_span)
			return true[span_674](start_span)[span_674](end_span)
		end[span_675](start_span)[span_675](end_span)
	end[span_676](start_span)[span_676](end_span)

	return false[span_677](start_span)[span_677](end_span)
end[span_678](start_span)[span_678](end_span)

local function PlayerHasRoundWeapon(player)[span_679](start_span)[span_679](end_span)
	if not player then[span_680](start_span)[span_680](end_span)
		return false[span_681](start_span)[span_681](end_span)
	end[span_682](start_span)[span_682](end_span)

	local character = player.Character[span_683](start_span)[span_683](end_span)
	local backpack =[span_684](start_span)[span_684](end_span)
		player:FindFirstChildOfClass([span_685](start_span)[span_685](end_span)
			"Backpack[span_686](start_span)"[span_686](end_span)
		)[span_687](start_span)[span_687](end_span)

	if ContainerHasRoundWeapon(character) then[span_688](start_span)[span_688](end_span)
		return true[span_689](start_span)[span_689](end_span)
	end[span_690](start_span)[span_690](end_span)

	if ContainerHasRoundWeapon(backpack) then[span_691](start_span)[span_691](end_span)
		return true[span_692](start_span)[span_692](end_span)
	end[span_693](start_span)[span_693](end_span)

	return false[span_694](start_span)[span_694](end_span)
end[span_695](start_span)[span_695](end_span)

local function AnyLivePlayerHasRoundWeapon()[span_696](start_span)[span_696](end_span)
	for _,player in ipairs(Players:GetPlayers()) do[span_697](start_span)[span_697](end_span)
		local character = player.Character[span_698](start_span)[span_698](end_span)

		local humanoid =[span_699](start_span)[span_699](end_span)
			character[span_700](start_span)[span_700](end_span)
			and character:FindFirstChildOfClass([span_701](start_span)[span_701](end_span)
				"Humanoid[span_702](start_span)"[span_702](end_span)
			)[span_703](start_span)[span_703](end_span)

		if humanoid[span_704](start_span)[span_704](end_span)
			and humanoid.Health > 0[span_705](start_span)[span_705](end_span)
			and PlayerHasRoundWeapon(player)[span_706](start_span)[span_706](end_span)
		then[span_707](start_span)[span_707](end_span)
			return true[span_708](start_span)[span_708](end_span)
		end[span_709](start_span)[span_709](end_span)
	end[span_710](start_span)[span_710](end_span)

	return false[span_711](start_span)[span_711](end_span)
end[span_712](start_span)[span_712](end_span)

local function FormatRoundTime(seconds)[span_713](start_span)[span_713](end_span)
	seconds = math.max([span_714](start_span)[span_714](end_span)
		0,[span_715](start_span)[span_715](end_span)
		math.ceil(seconds)[span_716](start_span)[span_716](end_span)
	)[span_717](start_span)[span_717](end_span)

	local minutes =[span_718](start_span)[span_718](end_span)
		math.floor(seconds/60)[span_719](start_span)[span_719](end_span)

	local secs =[span_720](start_span)[span_720](end_span)
		seconds%60[span_721](start_span)[span_721](end_span)

	return string.format([span_722](start_span)[span_722](end_span)
		"%d:%02d",[span_723](start_span)[span_723](end_span)
		minutes,[span_724](start_span)[span_724](end_span)
		secs[span_725](start_span)[span_725](end_span)
	)[span_726](start_span)[span_726](end_span)
end[span_727](start_span)[span_727](end_span)

local function HideRoundTimer()[span_728](start_span)[span_728](end_span)
	if RoundTimerHolder then[span_729](start_span)[span_729](end_span)
		RoundTimerHolder.Visible = false[span_730](start_span)[span_730](end_span)
	end[span_731](start_span)[span_731](end_span)
end[span_732](start_span)[span_732](end_span)

local function StopRoundTimer()[span_733](start_span)[span_733](end_span)
	RoundTimerRunning = false[span_734](start_span)[span_734](end_span)
	RoundTimerStartedAt = nil[span_735](start_span)[span_735](end_span)
	RoundTimerLastWeaponTime = 0[span_736](start_span)[span_736](end_span)

	MM2.State.RoundTimerRunning = false[span_737](start_span)[span_737](end_span)
	MM2.State.RoundTimerStartedAt = nil[span_738](start_span)[span_738](end_span)

	HideRoundTimer()[span_739](start_span)[span_739](end_span)
end[span_740](start_span)[span_740](end_span)

local function StartRoundTimer()[span_741](start_span)[span_741](end_span)
	if RoundTimerRunning then[span_742](start_span)[span_742](end_span)
		return[span_743](start_span)[span_743](end_span)
	end[span_744](start_span)[span_744](end_span)

	RoundTimerRunning = true[span_745](start_span)[span_745](end_span)
	RoundTimerStartedAt = os.clock()[span_746](start_span)[span_746](end_span)
	RoundTimerLastWeaponTime = os.clock()[span_747](start_span)[span_747](end_span)
	RoundTimerArmed = false[span_748](start_span)[span_748](end_span)

	MM2.State.RoundTimerRunning = true[span_749](start_span)[span_749](end_span)
	MM2.State.RoundTimerStartedAt =[span_750](start_span)[span_750](end_span)
		RoundTimerStartedAt[span_751](start_span)[span_751](end_span)

	if RoundTimerLabel then[span_752](start_span)[span_752](end_span)
		RoundTimerLabel.Text = "3:00[span_753](start_span)"[span_753](end_span)
	end[span_754](start_span)[span_754](end_span)

	if RoundTimerHolder then[span_755](start_span)[span_755](end_span)
		RoundTimerHolder.Visible =[span_756](start_span)[span_756](end_span)
			Flags.RoundTimer == true[span_757](start_span)[span_757](end_span)
	end[span_758](start_span)[span_758](end_span)
end[span_759](start_span)[span_759](end_span)

MM2.Functions.HideRoundTimer = HideRoundTimer[span_760](start_span)[span_760](end_span)
MM2.Functions.StopRoundTimer = StopRoundTimer[span_761](start_span)[span_761](end_span)
MM2.Functions.StartRoundTimer = StartRoundTimer[span_762](start_span)[span_762](end_span)

MM2.Functions.RefreshRoundTimer =[span_763](start_span)[span_763](end_span)
	function()[span_764](start_span)[span_764](end_span)
		if not RoundTimerHolder then[span_765](start_span)[span_765](end_span)
			return[span_766](start_span)[span_766](end_span)
		end[span_767](start_span)[span_767](end_span)

		RoundTimerHolder.Visible =[span_768](start_span)[span_768](end_span)
			Flags.RoundTimer == true[span_769](start_span)[span_769](end_span)
			and RoundTimerRunning[span_770](start_span)[span_770](end_span)
	end[span_771](start_span)[span_771](end_span)

local function ArmRoundTimer()[span_772](start_span)[span_772](end_span)
	if RoundTimerRunning then[span_773](start_span)[span_773](end_span)
		StopRoundTimer()[span_774](start_span)[span_774](end_span)
	end[span_775](start_span)[span_775](end_span)

	RoundTimerArmed = true[span_776](start_span)[span_776](end_span)
end[span_777](start_span)[span_777](end_span)

--============================================================
-- ROUND EVENT CONNECTIONS
--============================================================

local GameplayRemotes =[span_778](start_span)[span_778](end_span)
	ReplicatedStorage:[span_779](start_span)[span_779](end_span)
	FindFirstChild("Remotes")[span_780](start_span)[span_780](end_span)

GameplayRemotes =[span_781](start_span)[span_781](end_span)
	GameplayRemotes[span_782](start_span)[span_782](end_span)
	and GameplayRemotes:[span_783](start_span)[span_783](end_span)
	FindFirstChild("Gameplay")[span_784](start_span)[span_784](end_span)

local RoundStartRemote =[span_785](start_span)[span_785](end_span)
	GameplayRemotes[span_786](start_span)[span_786](end_span)
	and GameplayRemotes:[span_787](start_span)[span_787](end_span)
	FindFirstChild("RoundStart")[span_788](start_span)[span_788](end_span)

local CoinsStartedRemote =[span_789](start_span)[span_789](end_span)
	GameplayRemotes[span_790](start_span)[span_790](end_span)
	and GameplayRemotes:[span_791](start_span)[span_791](end_span)
	FindFirstChild("CoinsStarted")[span_792](start_span)[span_792](end_span)

local VictoryScreenRemote =[span_793](start_span)[span_793](end_span)
	GameplayRemotes[span_794](start_span)[span_794](end_span)
	and GameplayRemotes:[span_795](start_span)[span_795](end_span)
	FindFirstChild("VictoryScreen")[span_796](start_span)[span_796](end_span)

if RoundStartRemote[span_797](start_span)[span_797](end_span)
	and RoundStartRemote:IsA("RemoteEvent")[span_798](start_span)[span_798](end_span)
then[span_799](start_span)[span_799](end_span)
	Track([span_800](start_span)[span_800](end_span)
		RoundStartRemote.OnClientEvent:[span_801](start_span)[span_801](end_span)
		Connect(function()[span_802](start_span)[span_802](end_span)
			ArmRoundTimer()[span_803](start_span)[span_803](end_span)
		end)[span_804](start_span)[span_804](end_span)
	)[span_805](start_span)[span_805](end_span)
end[span_806](start_span)[span_806](end_span)

if CoinsStartedRemote[span_807](start_span)[span_807](end_span)
	and CoinsStartedRemote:IsA("RemoteEvent")[span_808](start_span)[span_808](end_span)
then[span_809](start_span)[span_809](end_span)
	Track([span_810](start_span)[span_810](end_span)
		CoinsStartedRemote.OnClientEvent:[span_811](start_span)[span_811](end_span)
		Connect(function()[span_812](start_span)[span_812](end_span)
			if not RoundTimerRunning then[span_813](start_span)[span_813](end_span)
				RoundTimerArmed = true[span_814](start_span)[span_814](end_span)
			end[span_815](start_span)[span_815](end_span)
		end)[span_816](start_span)[span_816](end_span)
	)[span_817](start_span)[span_817](end_span)
end[span_818](start_span)[span_818](end_span)

if VictoryScreenRemote[span_819](start_span)[span_819](end_span)
	and VictoryScreenRemote:IsA("RemoteEvent")[span_820](start_span)[span_820](end_span)
then[span_821](start_span)[span_821](end_span)
	Track([span_822](start_span)[span_822](end_span)
		VictoryScreenRemote.OnClientEvent:[span_823](start_span)[span_823](end_span)
		Connect(function()[span_824](start_span)[span_824](end_span)
			RoundTimerArmed = false[span_825](start_span)[span_825](end_span)
			StopRoundTimer()[span_826](start_span)[span_826](end_span)
		end)[span_827](start_span)[span_827](end_span)
	)[span_828](start_span)[span_828](end_span)
end[span_829](start_span)[span_829](end_span)

--============================================================
-- ROUND TIMER UPDATE LOOP
--============================================================

task.spawn(function()[span_830](start_span)[span_830](end_span)
	local hadRoundWeapon = false[span_831](start_span)[span_831](end_span)

	while MM2.Running do[span_832](start_span)[span_832](end_span)
		local hasRoundWeapon =[span_833](start_span)[span_833](end_span)
			AnyLivePlayerHasRoundWeapon()[span_834](start_span)[span_834](end_span)

		if hasRoundWeapon then[span_835](start_span)[span_835](end_span)
			RoundTimerLastWeaponTime =[span_836](start_span)[span_836](end_span)
				os.clock()[span_837](start_span)[span_837](end_span)

			if not RoundTimerRunning then[span_838](start_span)[span_838](end_span)
				if RoundTimerArmed[span_839](start_span)[span_839](end_span)
					or not hadRoundWeapon[span_840](start_span)[span_840](end_span)
				then[span_841](start_span)[span_841](end_span)
					StartRoundTimer()[span_842](start_span)[span_842](end_span)
				end[span_843](start_span)[span_843](end_span)
			end[span_844](start_span)[span_844](end_span)
		end[span_845](start_span)[span_845](end_span)

		if RoundTimerRunning then[span_846](start_span)[span_846](end_span)
			local elapsed =[span_847](start_span)[span_847](end_span)
				os.clock()[span_848](start_span)[span_848](end_span)
				- RoundTimerStartedAt[span_849](start_span)[span_849](end_span)

			local remaining =[span_850](start_span)[span_850](end_span)
				ROUND_LENGTH[span_851](start_span)[span_851](end_span)
				- elapsed[span_852](start_span)[span_852](end_span)

			if remaining <= 0 then[span_853](start_span)[span_853](end_span)
				StopRoundTimer()[span_854](start_span)[span_854](end_span)

			elseif not hasRoundWeapon[span_855](start_span)[span_855](end_span)
				and os.clock()[span_856](start_span)[span_856](end_span)
				- RoundTimerLastWeaponTime[span_857](start_span)[span_857](end_span)
				>= ROUND_WEAPON_LOSS_GRACE[span_858](start_span)[span_858](end_span)
			then[span_859](start_span)[span_859](end_span)
				StopRoundTimer()[span_860](start_span)[span_860](end_span)

			else[span_861](start_span)[span_861](end_span)
				if RoundTimerLabel then[span_862](start_span)[span_862](end_span)
					RoundTimerLabel.Text =[span_863](start_span)[span_863](end_span)
						FormatRoundTime([span_864](start_span)[span_864](end_span)
							remaining[span_865](start_span)[span_865](end_span)
						)[span_866](start_span)[span_866](end_span)
				end[span_867](start_span)[span_867](end_span)

				if RoundTimerHolder then[span_868](start_span)[span_868](end_span)
					RoundTimerHolder.Visible =[span_869](start_span)[span_869](end_span)
						Flags.RoundTimer[span_870](start_span)[span_870](end_span)
						== true[span_871](start_span)[span_871](end_span)
				end[span_872](start_span)[span_872](end_span)
			end[span_873](start_span)[span_873](end_span)
		else[span_874](start_span)[span_874](end_span)
			HideRoundTimer()[span_875](start_span)[span_875](end_span)
		end[span_876](start_span)[span_876](end_span)

		hadRoundWeapon = hasRoundWeapon[span_877](start_span)[span_877](end_span)

		task.wait(0.10)[span_878](start_span)[span_878](end_span)
	end[span_879](start_span)[span_879](end_span)

	StopRoundTimer()[span_880](start_span)[span_880](end_span)
end)[span_881](start_span)[span_881](end_span)

--============================================================
-- RENDER CONNECTIONS
--============================================================

Track([span_882](start_span)[span_882](end_span)
	RunService.RenderStepped:[span_883](start_span)[span_883](end_span)
	Connect([span_884](start_span)[span_884](end_span)
		MM2.Functions.UpdateTracers[span_885](start_span)[span_885](end_span)
	)[span_886](start_span)[span_886](end_span)
)[span_887](start_span)[span_887](end_span)

return MM2[span_888](start_span)[span_888](end_span)
