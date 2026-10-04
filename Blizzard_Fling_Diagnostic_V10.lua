--============================================================
-- BLIZZARD FLING DIAGNOSTIC V10
-- SUCCESSFUL TRANSFER DISCRIMINATOR
-- READ ONLY
--
-- Built from V9's transfer-gap approach.
-- V10 focuses on comparing unsuccessful overlap frames with the
-- first target-response frame.
--
-- READ ONLY:
--   Does NOT assign CFrame, velocity, angular velocity, humanoid
--   state, or any other character physics property.
--============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--============================================================
-- CONFIG
--============================================================

local LOCK_DISTANCE = 12
local CONTACT_DISTANCE = 4.5
local MAX_CAPTURE_SECONDS = 8.0
local PRE_EVENT_SECONDS = 2.0
local POST_EVENT_SECONDS = 1.75
local MAX_STORED_SAMPLES = 1800

local EXTREME_LINEAR = 1000
local EXTREME_ANGULAR = 1000

local TARGET_DELTA_LEVELS = {0.25,0.5,1,2,5,10,25,50,100}
local TARGET_SPEED_LEVELS = {1,2,5,10,25,50,100}

local FIRST_RESPONSE_DELTA = 0.25
local FIRST_RESPONSE_SPEED = 1.0
local CRITICAL_RADIUS = 20

--============================================================
-- REMOVE OLD GUI
--============================================================

for i = 4, 10 do
	local old = PlayerGui:FindFirstChild("BlizzardFlingDiagnosticV" .. i)
	if old then old:Destroy() end
end

--============================================================
-- STATE
--============================================================

local recording = false
local captureStart = 0
local lockedPlayer, lockedCharacter

local samples = {}
local events = {}
local previousSample = nil
local absoluteFrame = 0

local totalFrames, totalDt, maxDt = 0, 0, 0
local minDt = math.huge

local minimumClosestDistance = math.huge
local minimumSurfaceGap = math.huge
local closestApproachTime, closestApproachFrame
local closestApproachLocalPart, closestApproachTargetPart = "NONE","NONE"

local firstOverlapTime, firstOverlapFrame
local lastOverlapTime, lastOverlapFrame
local overlapEnterCount, overlapExitCount = 0,0
local everOverlapped = false

local firstExtremeLinearTime, firstExtremeLinearFrame
local firstExtremeAngularTime, firstExtremeAngularFrame
local extremeLinearActive, extremeAngularActive = false,false

local firstTargetResponseTime, firstTargetResponseFrame
local firstMeaningfulTargetMotionTime, firstMeaningfulTargetMotionFrame

local deltaThresholds = {}
local speedThresholds = {}

local peakTargetVelocityDelta = 0
local peakTargetVelocityDeltaFrame
local peakTargetVelocityDeltaVector = Vector3.zero
local peakTargetAcceleration = 0
local peakTargetAccelerationFrame
local peakTargetSpeed = 0
local peakTargetSpeedFrame

local pairAges = {}
local previousPairSet = {}

local eventDetected = false
local finishTime = nil

--============================================================
-- HELPERS
--============================================================

local function now()
	return os.clock() - captureStart
end

local function num(v)
	return v == nil and "NONE" or string.format("%.6f",v)
end

local function vec(v)
	if not v then return "(NONE)" end
	return string.format("(%.4f, %.4f, %.4f)",v.X,v.Y,v.Z)
end

local function addEvent(text)
	table.insert(events,string.format("[%.6f F=%d] %s",now(),absoluteFrame,text))
end

local function rotationDegrees(cf)
	local x,y,z = cf:ToOrientation()
	return Vector3.new(math.deg(x),math.deg(y),math.deg(z))
end

local function safeDot(a,b)
	if a.Magnitude <= 1e-6 or b.Magnitude <= 1e-6 then return 0 end
	return a.Unit:Dot(b.Unit)
end

local function getCharacterInfo(character)
	if not character then return nil end
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then return nil end
	return {
		root=root,
		humanoid=humanoid,
		cframe=root.CFrame,
		position=root.Position,
		orientation=rotationDegrees(root.CFrame),
		velocity=root.AssemblyLinearVelocity,
		angular=root.AssemblyAngularVelocity,
		speed=root.AssemblyLinearVelocity.Magnitude,
		angularSpeed=root.AssemblyAngularVelocity.Magnitude,
		state=tostring(humanoid:GetState())
	}
end

local function getCharacterParts(character)
	local out = {}
	if not character then return out end
	for _,obj in ipairs(character:GetChildren()) do
		if obj:IsA("BasePart") then table.insert(out,obj) end
	end
	return out
end

local function findClosestPlayer()
	local li = getCharacterInfo(LocalPlayer.Character)
	if not li then return nil,math.huge end
	local best,bestD=nil,math.huge
	for _,p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			local ti=getCharacterInfo(p.Character)
			if ti then
				local d=(ti.position-li.position).Magnitude
				if d < bestD then best,bestD=p,d end
			end
		end
	end
	return best,bestD
end

local function closestPartData(aChar,bChar)
	local bestCenter,bestSurface=math.huge,math.huge
	local ca,cb,sa,sb="NONE","NONE","NONE","NONE"
	for _,a in ipairs(getCharacterParts(aChar)) do
		for _,b in ipairs(getCharacterParts(bChar)) do
			local d=(a.Position-b.Position).Magnitude
			if d < bestCenter then bestCenter,ca,cb=d,a.Name,b.Name end
			local ra=a.Size.Magnitude*.5
			local rb=b.Size.Magnitude*.5
			local gap=math.max(0,d-ra-rb)
			if gap < bestSurface then bestSurface,sa,sb=gap,a.Name,b.Name end
		end
	end
	return bestCenter,ca,cb,bestSurface,sa,sb
end

local function getOverlapData(localCharacter,targetCharacter,dt)
	local pairs={}
	local pairSet={}
	local targetParts={}
	for _,p in ipairs(getCharacterParts(targetCharacter)) do targetParts[p]=true end

	local params=OverlapParams.new()
	params.FilterType=Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances={localCharacter}
	params.MaxParts=100

	for _,lp in ipairs(getCharacterParts(localCharacter)) do
		local ok,touching=pcall(function()
			return workspace:GetPartsInPart(lp,params)
		end)
		if ok then
			for _,tp in ipairs(touching) do
				if targetParts[tp] then
					local key=lp.Name.."<->"..tp.Name
					if not pairSet[key] then
						pairSet[key]=true

						local centerVector=tp.Position-lp.Position
						local centerDirection=centerVector.Magnitude > 1e-6 and centerVector.Unit or Vector3.zero
						local relativeVelocity=lp.AssemblyLinearVelocity-tp.AssemblyLinearVelocity
						local closingSpeed=relativeVelocity:Dot(centerDirection)

						local localOffset=tp.Position-lp.AssemblyCenterOfMass
						local targetOffset=lp.Position-tp.AssemblyCenterOfMass
						local localRotational=lp.AssemblyAngularVelocity:Cross(localOffset)
						local targetRotational=tp.AssemblyAngularVelocity:Cross(targetOffset)
						local estimatedRelativeContactVelocity=
							(lp.AssemblyLinearVelocity+localRotational)-
							(tp.AssemblyLinearVelocity+targetRotational)

						local old=pairAges[key]
						local ageFrames=(old and old.frames or 0)+1
						local ageSeconds=(old and old.seconds or 0)+dt
						pairAges[key]={frames=ageFrames,seconds=ageSeconds}

						table.insert(pairs,{
							key=key,
							localName=lp.Name,
							targetName=tp.Name,
							ageFrames=ageFrames,
							ageSeconds=ageSeconds,
							centerDistance=centerVector.Magnitude,
							relativeVelocity=relativeVelocity,
							relativeSpeed=relativeVelocity.Magnitude,
							closingSpeed=closingSpeed,
							localAngular=lp.AssemblyAngularVelocity,
							targetAngular=tp.AssemblyAngularVelocity,
							localRotational=localRotational,
							targetRotational=targetRotational,
							estimatedRelativeContactVelocity=estimatedRelativeContactVelocity,
							localMass=lp.AssemblyMass,
							targetMass=tp.AssemblyMass,
							localCOM=lp.AssemblyCenterOfMass,
							targetCOM=tp.AssemblyCenterOfMass,
							localAnchored=lp.Anchored,
							targetAnchored=tp.Anchored,
							localCanCollide=lp.CanCollide,
							targetCanCollide=tp.CanCollide,
							localMassless=lp.Massless,
							targetMassless=tp.Massless,
							localRootPriority=lp.RootPriority,
							targetRootPriority=tp.RootPriority
						})
					end
				end
			end
		end
	end

	for key in pairs(pairAges) do
		if not pairSet[key] then pairAges[key]=nil end
	end

	local added,removed={},{}
	for key in pairs(pairSet) do
		if not previousPairSet[key] then table.insert(added,key) end
	end
	for key in pairs(previousPairSet) do
		if not pairSet[key] then table.insert(removed,key) end
	end
	table.sort(added)
	table.sort(removed)
	previousPairSet=pairSet

	return #pairs>0,pairs,added,removed
end

local function pairKeys(pairs)
	local t={}
	for _,p in ipairs(pairs or {}) do table.insert(t,p.key) end
	table.sort(t)
	return #t>0 and table.concat(t,", ") or "NONE"
end

local function clearCaptureState()
	recording=false
	captureStart=0
	lockedPlayer=nil
	lockedCharacter=nil
	samples={}
	events={}
	previousSample=nil
	absoluteFrame=0
	totalFrames,totalDt,maxDt=0,0,0
	minDt=math.huge
	minimumClosestDistance=math.huge
	minimumSurfaceGap=math.huge
	closestApproachTime,closestApproachFrame=nil,nil
	closestApproachLocalPart,closestApproachTargetPart="NONE","NONE"
	firstOverlapTime,firstOverlapFrame=nil,nil
	lastOverlapTime,lastOverlapFrame=nil,nil
	overlapEnterCount,overlapExitCount=0,0
	everOverlapped=false
	firstExtremeLinearTime,firstExtremeLinearFrame=nil,nil
	firstExtremeAngularTime,firstExtremeAngularFrame=nil,nil
	extremeLinearActive,extremeAngularActive=false,false
	firstTargetResponseTime,firstTargetResponseFrame=nil,nil
	firstMeaningfulTargetMotionTime,firstMeaningfulTargetMotionFrame=nil,nil
	peakTargetVelocityDelta=0
	peakTargetVelocityDeltaFrame=nil
	peakTargetVelocityDeltaVector=Vector3.zero
	peakTargetAcceleration=0
	peakTargetAccelerationFrame=nil
	peakTargetSpeed=0
	peakTargetSpeedFrame=nil
	pairAges={}
	previousPairSet={}
	eventDetected=false
	finishTime=nil
	deltaThresholds={}
	speedThresholds={}
	for _,v in ipairs(TARGET_DELTA_LEVELS) do deltaThresholds[v]={hit=false,time=nil,frame=nil} end
	for _,v in ipairs(TARGET_SPEED_LEVELS) do speedThresholds[v]={hit=false,time=nil,frame=nil} end
end
clearCaptureState()

local function trimBuffer()
	if eventDetected then
		while #samples>MAX_STORED_SAMPLES do table.remove(samples,1) end
		return
	end
	local cutoff=now()-PRE_EVENT_SECONDS
	while #samples>0 and samples[1].time<cutoff do table.remove(samples,1) end
end

local function captureSample(dt)
	if not recording then return end
	local elapsed=now()
	if elapsed>=MAX_CAPTURE_SECONDS then
		recording=false
		addEvent("CAPTURE TIMEOUT")
		return
	end

	local li=getCharacterInfo(LocalPlayer.Character)
	if not li then return end

	if not lockedPlayer then
		local p,d=findClosestPlayer()
		if p and d<=LOCK_DISTANCE then
			lockedPlayer=p
			lockedCharacter=p.Character
			addEvent(string.format("TARGET LOCKED %s Distance=%.4f",p.Name,d))
		else
			return
		end
	end

	if not lockedPlayer.Parent then recording=false addEvent("TARGET LEFT GAME") return end
	if lockedPlayer.Character~=lockedCharacter then recording=false addEvent("TARGET CHARACTER CHANGED") return end

	local ti=getCharacterInfo(lockedCharacter)
	if not ti then return end

	absoluteFrame+=1
	totalFrames+=1
	totalDt+=dt
	minDt=math.min(minDt,dt)
	maxDt=math.max(maxDt,dt)

	local relativeWorld=ti.position-li.position
	local rootDistance=relativeWorld.Magnitude
	local relativeLocal=li.cframe:PointToObjectSpace(ti.position)

	local closestDistance,closestLP,closestTP,surfaceGap,surfaceLP,surfaceTP=
		closestPartData(LocalPlayer.Character,lockedCharacter)

	local overlapping,overlapPairs,addedPairs,removedPairs=
		getOverlapData(LocalPlayer.Character,lockedCharacter,dt)

	if overlapping then
		everOverlapped=true
		lastOverlapTime=elapsed
		lastOverlapFrame=absoluteFrame
		if not firstOverlapTime then
			firstOverlapTime=elapsed
			firstOverlapFrame=absoluteFrame
		end
	end

	local localDV,targetDV=Vector3.zero,Vector3.zero
	local localDA,targetDA=Vector3.zero,Vector3.zero
	local localStep,targetStep=0,0
	local orientationDelta=Vector3.zero

	if previousSample then
		localDV=li.velocity-previousSample.localVelocity
		targetDV=ti.velocity-previousSample.targetVelocity
		localDA=li.angular-previousSample.localAngular
		targetDA=ti.angular-previousSample.targetAngular
		localStep=(li.position-previousSample.localPosition).Magnitude
		targetStep=(ti.position-previousSample.targetPosition).Magnitude
		orientationDelta=li.orientation-previousSample.localOrientation
	end

	local localAccel=dt>0 and localDV.Magnitude/dt or 0
	local targetAccel=dt>0 and targetDV.Magnitude/dt or 0

	local overlapTransition=false
	if previousSample and overlapping~=previousSample.overlapping then
		overlapTransition=true
		if overlapping then
			overlapEnterCount+=1
			addEvent("*** OVERLAP ENTER *** Pairs="..pairKeys(overlapPairs))
		else
			overlapExitCount+=1
			addEvent("*** OVERLAP EXIT ***")
		end
	end

	if #addedPairs>0 then addEvent("PAIR ADDED "..table.concat(addedPairs,", ")) end
	if #removedPairs>0 then addEvent("PAIR REMOVED "..table.concat(removedPairs,", ")) end

	if closestDistance<minimumClosestDistance then
		minimumClosestDistance=closestDistance
		closestApproachTime=elapsed
		closestApproachFrame=absoluteFrame
		closestApproachLocalPart=closestLP
		closestApproachTargetPart=closestTP
	end
	minimumSurfaceGap=math.min(minimumSurfaceGap,surfaceGap)

	local extremeLinear=li.speed>=EXTREME_LINEAR
	local extremeAngular=li.angularSpeed>=EXTREME_ANGULAR

	if extremeLinear and not firstExtremeLinearTime then
		firstExtremeLinearTime=elapsed
		firstExtremeLinearFrame=absoluteFrame
		addEvent(string.format("LOCAL EXTREME LINEAR FIRST Speed=%.4f",li.speed))
	end
	if extremeAngular and not firstExtremeAngularTime then
		firstExtremeAngularTime=elapsed
		firstExtremeAngularFrame=absoluteFrame
		addEvent(string.format("LOCAL EXTREME ANGULAR FIRST Angular=%.4f",li.angularSpeed))
	end
	extremeLinearActive=extremeLinear
	extremeAngularActive=extremeAngular

	if targetDV.Magnitude>peakTargetVelocityDelta then
		peakTargetVelocityDelta=targetDV.Magnitude
		peakTargetVelocityDeltaFrame=absoluteFrame
		peakTargetVelocityDeltaVector=targetDV
	end
	if targetAccel>peakTargetAcceleration then
		peakTargetAcceleration=targetAccel
		peakTargetAccelerationFrame=absoluteFrame
	end
	if ti.speed>peakTargetSpeed then
		peakTargetSpeed=ti.speed
		peakTargetSpeedFrame=absoluteFrame
	end

	local deltaHit=nil
	for _,threshold in ipairs(TARGET_DELTA_LEVELS) do
		local r=deltaThresholds[threshold]
		if not r.hit and targetDV.Magnitude>=threshold then
			r.hit=true r.time=elapsed r.frame=absoluteFrame
			deltaHit=deltaHit or threshold
			addEvent(string.format("TARGET DELTA >= %.2f DeltaV=%.4f",threshold,targetDV.Magnitude))
		end
	end

	local speedHit=nil
	for _,threshold in ipairs(TARGET_SPEED_LEVELS) do
		local r=speedThresholds[threshold]
		if not r.hit and ti.speed>=threshold then
			r.hit=true r.time=elapsed r.frame=absoluteFrame
			speedHit=speedHit or threshold
			addEvent(string.format("TARGET SPEED >= %.2f Speed=%.4f",threshold,ti.speed))
		end
	end

	local responseTransition=false
	if not firstTargetResponseTime and previousSample and
		(targetDV.Magnitude>=FIRST_RESPONSE_DELTA or ti.speed>=FIRST_RESPONSE_SPEED) then
		firstTargetResponseTime=elapsed
		firstTargetResponseFrame=absoluteFrame
		responseTransition=true
		addEvent(string.format("*** FIRST TARGET RESPONSE *** Speed=%.4f DeltaV=%.4f Overlap=%s Pairs=%s",
			ti.speed,targetDV.Magnitude,tostring(overlapping),pairKeys(overlapPairs)))
		eventDetected=true
		finishTime=elapsed+POST_EVENT_SECONDS
	end

	local meaningfulTransition=false
	if not firstMeaningfulTargetMotionTime and (targetDV.Magnitude>=5 or ti.speed>=10) then
		firstMeaningfulTargetMotionTime=elapsed
		firstMeaningfulTargetMotionFrame=absoluteFrame
		meaningfulTransition=true
	end

	local sample={
		frame=absoluteFrame,time=elapsed,dt=dt,
		localPosition=li.position,localOrientation=li.orientation,
		localOrientationDelta=orientationDelta,
		localVelocity=li.velocity,localAngular=li.angular,
		localSpeed=li.speed,localAngularSpeed=li.angularSpeed,localState=li.state,
		targetPosition=ti.position,targetOrientation=ti.orientation,
		targetVelocity=ti.velocity,targetAngular=ti.angular,
		targetSpeed=ti.speed,targetAngularSpeed=ti.angularSpeed,targetState=ti.state,
		rootDistance=rootDistance,relativeWorld=relativeWorld,relativeLocal=relativeLocal,
		closestDistance=closestDistance,closestLocalPart=closestLP,closestTargetPart=closestTP,
		surfaceGap=surfaceGap,surfaceLocalPart=surfaceLP,surfaceTargetPart=surfaceTP,
		overlapping=overlapping,overlapPairs=overlapPairs,
		addedPairs=addedPairs,removedPairs=removedPairs,
		localStep=localStep,targetStep=targetStep,
		localVelocityDelta=localDV,targetVelocityDelta=targetDV,
		localAngularDelta=localDA,targetAngularDelta=targetDA,
		localAcceleration=localAccel,targetAcceleration=targetAccel,
		overlapTransition=overlapTransition,
		firstTargetResponseTransition=responseTransition,
		firstMeaningfulTransition=meaningfulTransition,
		deltaThresholdHit=deltaHit,speedThresholdHit=speedHit
	}

	table.insert(samples,sample)
	previousSample=sample
	trimBuffer()

	if eventDetected and finishTime and elapsed>=finishTime then
		recording=false
		addEvent("POST-EVENT WINDOW COMPLETE")
	end
end

local function findFrame(frame)
	if not frame then return nil end
	for _,s in ipairs(samples) do
		if s.frame==frame then return s end
	end
end

local function pairLine(p)
	return string.format(
		"%s Age=%df/%.6fs Dist=%.6f RelVel=%s RelSpeed=%.6f Closing=%.6f LocalAng=%s TargetAng=%s ContactRelVel=%s LocalMass=%.4f TargetMass=%.4f LocalAnchored=%s TargetAnchored=%s LocalCollide=%s TargetCollide=%s LocalMassless=%s TargetMassless=%s LocalRootPriority=%d TargetRootPriority=%d",
		p.key,p.ageFrames,p.ageSeconds,p.centerDistance,vec(p.relativeVelocity),
		p.relativeSpeed,p.closingSpeed,vec(p.localAngular),vec(p.targetAngular),
		vec(p.estimatedRelativeContactVelocity),p.localMass,p.targetMass,
		tostring(p.localAnchored),tostring(p.targetAnchored),
		tostring(p.localCanCollide),tostring(p.targetCanCollide),
		tostring(p.localMassless),tostring(p.targetMassless),
		p.localRootPriority,p.targetRootPriority
	)
end

local function addFrameOutput(lines,s)
	if not s then
		table.insert(lines,"FRAME=UNAVAILABLE")
		return
	end
	table.insert(lines,string.format("--- FRAME %d t=%.6f dt=%.6f ---",s.frame,s.time,s.dt))
	table.insert(lines,"LOCAL POS="..vec(s.localPosition).." ROT="..vec(s.localOrientation).." ROT_DELTA="..vec(s.localOrientationDelta))
	table.insert(lines,"LOCAL VEL="..vec(s.localVelocity).." SPEED="..num(s.localSpeed).." ANG="..vec(s.localAngular))
	table.insert(lines,"TARGET POS="..vec(s.targetPosition).." VEL="..vec(s.targetVelocity).." SPEED="..num(s.targetSpeed))
	table.insert(lines,"TARGET ΔV="..vec(s.targetVelocityDelta).." |Mag|="..num(s.targetVelocityDelta.Magnitude).." ACCEL="..num(s.targetAcceleration))
	table.insert(lines,"DIST Root="..num(s.rootDistance).." Closest="..num(s.closestDistance).." SurfaceGap="..num(s.surfaceGap))
	table.insert(lines,"OVERLAP="..tostring(s.overlapping).." PAIRS="..pairKeys(s.overlapPairs))
	table.insert(lines,"ADDED_PAIRS="..(#s.addedPairs>0 and table.concat(s.addedPairs,", ") or "NONE"))
	table.insert(lines,"REMOVED_PAIRS="..(#s.removedPairs>0 and table.concat(s.removedPairs,", ") or "NONE"))
	for _,p in ipairs(s.overlapPairs) do
		table.insert(lines,"PAIR "..pairLine(p))
	end
	table.insert(lines,"")
end

local function buildOutput()
	local lines={}
	local function add(x) table.insert(lines,x) end
	local avg=totalFrames>0 and totalDt/totalFrames or 0

	add("BLIZZARD FLING DIAGNOSTIC V10")
	add("Mode=READ ONLY / SUCCESSFUL TRANSFER DISCRIMINATOR")
	add("Target="..(lockedPlayer and lockedPlayer.Name or "NONE"))
	add("Samples="..#samples.." AbsoluteFrames="..absoluteFrame)
	add("AverageDt="..num(avg).." ApproxHz="..(avg>0 and num(1/avg) or "NONE"))
	add("MinDt="..(minDt<math.huge and num(minDt) or "NONE").." MaxDt="..num(maxDt))
	add("")

	add("================ V9 TRANSFER SUMMARY ================")
	add("FirstExtremeLinear="..num(firstExtremeLinearTime).." Frame="..tostring(firstExtremeLinearFrame or "NONE"))
	add("FirstExtremeAngular="..num(firstExtremeAngularTime).." Frame="..tostring(firstExtremeAngularFrame or "NONE"))
	add("ClosestApproach="..num(closestApproachTime).." Frame="..tostring(closestApproachFrame or "NONE"))
	add("ClosestCenterDistance="..(minimumClosestDistance<math.huge and num(minimumClosestDistance) or "NONE"))
	add("ClosestCenterPair="..closestApproachLocalPart.." <-> "..closestApproachTargetPart)
	add("MinimumSurfaceGapEstimate="..(minimumSurfaceGap<math.huge and num(minimumSurfaceGap) or "NONE"))
	add("EverOverlapped="..tostring(everOverlapped))
	add("FirstOverlap="..num(firstOverlapTime).." Frame="..tostring(firstOverlapFrame or "NONE"))
	add("LastOverlap="..num(lastOverlapTime).." Frame="..tostring(lastOverlapFrame or "NONE"))
	add("FirstTargetResponse="..num(firstTargetResponseTime).." Frame="..tostring(firstTargetResponseFrame or "NONE"))
	add("FirstMeaningfulTargetMotion="..num(firstMeaningfulTargetMotionTime).." Frame="..tostring(firstMeaningfulTargetMotionFrame or "NONE"))
	add("")

	add("================ TARGET DELTA THRESHOLDS ================")
	for _,v in ipairs(TARGET_DELTA_LEVELS) do
		local r=deltaThresholds[v]
		add(string.format("DeltaV>=%.2f Hit=%s Time=%s Frame=%s",v,tostring(r.hit),num(r.time),tostring(r.frame or "NONE")))
	end
	add("")
	add("================ TARGET SPEED THRESHOLDS ================")
	for _,v in ipairs(TARGET_SPEED_LEVELS) do
		local r=speedThresholds[v]
		add(string.format("Speed>=%.2f Hit=%s Time=%s Frame=%s",v,tostring(r.hit),num(r.time),tostring(r.frame or "NONE")))
	end
	add("")

	add("================ PEAKS ================")
	add("PeakTargetVelocityDelta="..num(peakTargetVelocityDelta).." Frame="..tostring(peakTargetVelocityDeltaFrame or "NONE"))
	add("PeakTargetVelocityDeltaVector="..vec(peakTargetVelocityDeltaVector))
	add("PeakTargetAcceleration="..num(peakTargetAcceleration).." Frame="..tostring(peakTargetAccelerationFrame or "NONE"))
	add("PeakTargetSpeed="..num(peakTargetSpeed).." Frame="..tostring(peakTargetSpeedFrame or "NONE"))
	add("")

	add("================ EVENTS ================")
	for _,e in ipairs(events) do add(e) end
	add("")

	add("================ SUCCESSFUL TRANSFER DISCRIMINATOR ================")
	if not firstTargetResponseFrame then
		add("FIRST RESPONSE FRAME: NONE")
		add("No target response crossed the configured detection threshold.")
	else
		add("FIRST RESPONSE FRAME: "..firstTargetResponseFrame)

		local success=findFrame(firstTargetResponseFrame)
		local previous=findFrame(firstTargetResponseFrame-1)

		local lastUnsuccessful=nil
		for i=#samples,1,-1 do
			local s=samples[i]
			if s.frame<firstTargetResponseFrame and s.overlapping then
				lastUnsuccessful=s
				break
			end
		end

		add("")
		add("LAST UNSUCCESSFUL OVERLAP:")
		addFrameOutput(lines,lastUnsuccessful)

		add("IMMEDIATELY PRECEDING FRAME:")
		addFrameOutput(lines,previous)

		add("SUCCESSFUL RESPONSE FRAME:")
		addFrameOutput(lines,success)

		add("CHANGES ON SUCCESS FRAME:")
		if success and previous then
			add("TargetDeltaVChange="..num(success.targetVelocityDelta.Magnitude-previous.targetVelocityDelta.Magnitude))
			add("TargetSpeedChange="..num(success.targetSpeed-previous.targetSpeed))
			add("LocalAngularSpeedChange="..num(success.localAngularSpeed-previous.localAngularSpeed))
			add("LocalOrientationDelta="..vec(success.localOrientationDelta))
			add("AddedPairs="..(#success.addedPairs>0 and table.concat(success.addedPairs,", ") or "NONE"))
			add("RemovedPairs="..(#success.removedPairs>0 and table.concat(success.removedPairs,", ") or "NONE"))
		else
			add("UNAVAILABLE")
		end

		add("")
		add("SUCCESS WINDOW -5 THROUGH +3:")
		for f=firstTargetResponseFrame-5,firstTargetResponseFrame+3 do
			addFrameOutput(lines,findFrame(f))
		end
	end

	add("================ ABSOLUTE-FRAME CRITICAL WINDOW ================")
	local include={}
	local function around(frame,radius)
		if not frame then return end
		for f=frame-radius,frame+radius do include[f]=true end
	end
	around(firstExtremeLinearFrame,CRITICAL_RADIUS)
	around(firstExtremeAngularFrame,CRITICAL_RADIUS)
	around(closestApproachFrame,CRITICAL_RADIUS)
	around(firstOverlapFrame,CRITICAL_RADIUS)
	around(lastOverlapFrame,CRITICAL_RADIUS)
	around(firstTargetResponseFrame,CRITICAL_RADIUS)
	around(firstMeaningfulTargetMotionFrame,CRITICAL_RADIUS)
	around(peakTargetVelocityDeltaFrame,CRITICAL_RADIUS)
	around(peakTargetAccelerationFrame,CRITICAL_RADIUS)
	around(peakTargetSpeedFrame,CRITICAL_RADIUS)

	for _,s in ipairs(samples) do
		if include[s.frame] or s.overlapTransition or s.firstTargetResponseTransition then
			addFrameOutput(lines,s)
		end
	end

	add("============================================================")
	add("END V10")
	add("============================================================")
	return table.concat(lines,"\n")
end

--============================================================
-- GUI
--============================================================

local gui=Instance.new("ScreenGui")
gui.Name="BlizzardFlingDiagnosticV10"
gui.ResetOnSpawn=false
gui.DisplayOrder=999999
gui.Parent=PlayerGui

local main=Instance.new("Frame")
main.Size=UDim2.new(0,360,0,205)
main.Position=UDim2.new(.5,-180,.5,-102)
main.BackgroundColor3=Color3.fromRGB(20,20,20)
main.BorderSizePixel=0
main.Active=true
main.Draggable=true
main.Parent=gui

local corner=Instance.new("UICorner")
corner.CornerRadius=UDim.new(0,10)
corner.Parent=main

local title=Instance.new("TextLabel")
title.Size=UDim2.new(1,-20,0,35)
title.Position=UDim2.new(0,10,0,5)
title.BackgroundTransparency=1
title.Text="BLIZZARD FLING DIAGNOSTIC V10"
title.TextColor3=Color3.new(1,1,1)
title.TextScaled=true
title.Font=Enum.Font.GothamBold
title.Parent=main

local status=Instance.new("TextLabel")
status.Size=UDim2.new(1,-20,0,50)
status.Position=UDim2.new(0,10,0,42)
status.BackgroundTransparency=1
status.TextColor3=Color3.new(1,1,1)
status.TextWrapped=true
status.TextScaled=true
status.Font=Enum.Font.Gotham
status.Text="Ready — V10 discriminator"
status.Parent=main

local startButton=Instance.new("TextButton")
startButton.Size=UDim2.new(.46,0,0,42)
startButton.Position=UDim2.new(.03,0,0,100)
startButton.Text="START"
startButton.TextScaled=true
startButton.Font=Enum.Font.GothamBold
startButton.Parent=main

local copyButton=Instance.new("TextButton")
copyButton.Size=UDim2.new(.46,0,0,42)
copyButton.Position=UDim2.new(.51,0,0,100)
copyButton.Text="COPY LOGS"
copyButton.TextScaled=true
copyButton.Font=Enum.Font.GothamBold
copyButton.Parent=main

local stopButton=Instance.new("TextButton")
stopButton.Size=UDim2.new(.94,0,0,34)
stopButton.Position=UDim2.new(.03,0,0,154)
stopButton.Text="STOP + CLEAR"
stopButton.TextScaled=true
stopButton.Font=Enum.Font.GothamBold
stopButton.Parent=main

startButton.MouseButton1Click:Connect(function()
	clearCaptureState()
	recording=true
	captureStart=os.clock()
	addEvent("CAPTURE STARTED")
	status.Text="Recording | waiting for transfer"
end)

stopButton.MouseButton1Click:Connect(function()
	clearCaptureState()
	status.Text="Stopped + cleared | Samples=0"
end)

copyButton.MouseButton1Click:Connect(function()
	local output=buildOutput()
	if setclipboard then
		setclipboard(output)
		status.Text="Logs copied | Samples="..#samples
	else
		print(output)
		status.Text="Clipboard unavailable — printed logs"
	end
end)

RunService.Heartbeat:Connect(function(dt)
	if not recording then return end
	captureSample(dt)
	if not recording then
		status.Text="Capture complete | Samples="..#samples
		return
	end

	local targetName=lockedPlayer and lockedPlayer.Name or "waiting"
	local phase="WATCHING"
	if firstExtremeLinearTime or firstExtremeAngularTime then phase="LOCAL EXTREME" end
	if firstOverlapTime then phase="OVERLAP" end
	if firstTargetResponseTime then phase="TARGET RESPONSE" end
	if deltaThresholds[5] and deltaThresholds[5].hit then phase="TARGET MOTION" end
	if deltaThresholds[50] and deltaThresholds[50].hit then phase="STRONG TRANSFER" end
	if speedThresholds[50] and speedThresholds[50].hit then phase="TARGET LAUNCH" end

	status.Text=phase.." | "..targetName.." | F="..absoluteFrame
end)
