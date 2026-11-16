-- Worm: the abyssipedes' brains and bodies on the server (PROJECT.md: Interfaces). Each worm is a head that moves
-- along physical surfaces (and can bridge across gaps shorter than its body length) and a trail of the head's past
-- positions that the body lies along, so the body never passes through anything the head did not.

Worm = {}

WORM_LAYER = 64               -- the hit boxes' and the drawn body's collision layer (nothing collides with them;
WORM_QUERY_MASK = 63          -- players' CollisionMask leaves it out); our queries skip it and Dive's fish (128)
WORM_MAX = 10                 -- worms at most (including hatched juveniles)
TRAIL_STEP = 0.15             -- m between recorded head positions
TRAIL_PUB = 0.5               -- m between the published trail's points
TRAIL_SPARE = 6               -- m of trail kept behind the tail (for recoils)
PUBLISH_HZ = 12
HEAD_R = 0.24                 -- m: the head's clearance in its own moves (sphere casts)
TIGHT_R = 0.12                -- m: ... on legs through gaps players proved passable (Nav's tight legs: 0.15 m clear)
BODY_LEN = 16                 -- m (from WORM_PARTS when present)
BABY_BODY_LEN = 1.82          -- m (50% segment count at BABY_SCALE, computed from WORM_PARTS on init)
BABY_SEG_RATIO = 0.50         -- juveniles have 50% the number of segments as an adult
HP = 160
SENSE_HZ = 5
-- Player detection ranges:
NEAR_SENSE = 18               -- m: felt whatever it does (vibrations / air movement)
MOVE_SENSE = 35               -- m: felt when a player moves around
LIGHT_SENSE = 65              -- m: a flashlight in its line of sight
DARK_SIGHT = 24               -- m: seen without light
HEAR_K = 95                   -- m of hearing per unit of GetLastSound volume
FORGET_T = 25                 -- s: a stalk gives up this long after the last sensing
LUNGE_RANGE = 4.5
LUNGE_SPEED = 17
LUNGE_T = 0.45
WINDUP_T = 0.38
LUNGE_CD = 2.4
GRAB_R = 1.35
DRAG_SPEED = 4.2
DRAG_MAX = 16                 -- s until a dragged Living Humans person is cocooned, if home is not reached first (players: no limit)
DRAG_HURT = 0.035             -- health per second while held (no floor: a long drag can kill)
BABY_BITE = 0.12              -- a juvenile's bite (it can't seize anyone): health off a player / a Living Humans person
VEHICLE_BITE = 0.22           -- an adult's bite at someone in a vehicle (it can't pull them out)
RELEASE_DMG = 26              -- damage taken during a drag that makes it let go
BITE_CD = 1.2
HARD_BITE = 25                -- voxels: a bite cutting fewer met something it can't bite (and backs out)
HARD_BACK = 2.5               -- m it backs out along its body
BITE_R = {2.1, 1.35, 0.0}     -- MakeHole radii (soft, medium, hard=0): breaks dirt, wood, vegetation, glass, plaster, plastic; cannot break stone/masonry/metal
STUCK_T = 0.5
RESPAWN_T = 150
CORPSE_T = 25
SPAWN_DELAY = 18
SPAWN_GRACE = 3.0             -- s after spawning before the centipede's brains and senses wake up

-- Flammability constants (Acidica takes light, capped fire damage with cooldown; Ignitus is 100% fireproof):
BURN_DURATION = 4.0           -- s Acidica stays Singed/Burning before self-extinguishing
BURN_DPS = 0.8                -- gentle fire DPS (at most ~3.2 HP per ignition, never lethal on its own)
FIRE_IMMUNE_T = 12.0          -- s of fire immunity after burning ends so Acidica can escape without re-igniting
BURN_MIN_HP_RATIO = 0.25      -- fire damage alone cannot reduce Acidica below 25% max HP

-- Acid spit constants:
SPIT_MIN_R = 2.8              -- m: minimum distance to spit acid/fire
SPIT_MAX_R = 22.0             -- m: maximum distance to spit acid/fire
SPIT_CD = 3.8                 -- s: cooldown between spit volleys
SPIT_SPEED = 18.0             -- m/s: speed of droplets
SPIT_PELLETS = 9              -- droplets per spray
ACID_HOLE_R = {0.55, 0.40, 0.0}  -- limited voxel dissolution (soft & medium only; 0 hard radius so stone/metal are unharmed)
ACID_DMG = 0.16               -- player health damage per nearby droplet impact
ACID_WEAK_DMG = 22.0          -- acid droplet impact damage against Silkmaw (Ignitus)
FIRE_PELLET_DMG = 7.5         -- fire droplet impact damage against rival Silkmaw (Acidica)
RIVAL_AVOID_R = 38.0          -- m: distance within which Acidica and Ignitus sense and avoid each other's territory
RIVAL_FIGHT_R = 15.0          -- m: close-quarters threshold (or nest intrusion) where avoidance turns into a fight to the death
RIVAL_BITE_DMG = 28.0         -- base damage dealt per lunge/bite in a territorial fight between variants

-- Silken Nest, Periodic Return, Egg Laying & Offspring Maturation constants:
NEST_VISIT_MIN = 180          -- s: minimum interval between periodic returns to inspect/expand its nest (3+ min)
NEST_VISIT_MAX = 260          -- s: maximum interval between periodic returns to its nest
NEST_SURVIVE_T = 300          -- s (5 minutes) of survival required before returning to the silken nest to lay eggs
EGG_COUNT = 3                 -- eggs per clutch
EGG_HATCH_T = 20.0            -- s until laid eggs hatch into juvenile centipedes
BABY_GROW_T = 600             -- s (10 minutes) until young offspring mature into full-size adults
BABY_SCALE = 0.20             -- juveniles are 20% the size of an adult (with 50% segment count)
BABY_NEST_RADIUS = 8.0        -- m: maximum distance juveniles wander from their mother's nest
BABY_NPC_BITE_R = 1.75        -- m: reach within which a juvenile bites a nearby NPC
BABY_NPC_CHASE_R = 10.0       -- m: distance within which a juvenile actively approaches nearby NPCs to bite or feed
BABY_BITE_CD = 1.5            -- s: cooldown between juvenile bites on nearby living NPCs
ADULT_DISPERSE_MIN = 30.0     -- m: minimum distance away from mother's nest when matured offspring seek their own nest
ADULT_DISPERSE_MAX = 55.0     -- m: maximum search radius for matured offspring seeking their own nest
NEST_MAX_HP = 300.0           -- high structural durability across the procedural silk vein network
NEST_RADIUS = 5.6             -- m: base radius (11.2m diameter) of the procedural surface-sprayed silk vein network
-- Seismica grows in 4 steps of 25% (to 2x) every 150 s: the same size at the same 10 minutes as the pack's 10 steps of
-- 10% a minute, but every client re-spawns the drawn body (~60 bodies) on each step, so 4 times instead of 10
SEIS_GROW_T = 150.0
SEIS_GROW_STEP = 0.25
SEIS_GROW_STAGES = 4
SEIS_SLOW = 0.2              -- speed / (1 + SEIS_SLOW * step): 1.8x slower at full size, as in the pack
NEST_MAX_TIER = 10            -- the nest grows a ring on a return visit, up to 10 rings (rings are cheap since 1.2: grown over
                              -- frames, repaired piece by piece, painted into few shapes - NEST_PAINT). The options menu sets
                              -- 3 to 10 (savegame.mod.nestrings, read by the host in Worm.serverInit; 0 = not set = 10)
NEST_BUILD_DURATION = 15.0    -- s the centipede spends spraying its 6-layer silk vein network across surfaces
NEST_BUILD_STAGES = 6         -- 6 progressive layers of silk veins & webbing built up on surfaces
NEST_REPAIR_DURATION = 4.5    -- s the centipede spends spraying fresh silk to repair a damaged nest
NEST_DESTROY_RATIO = 0.12     -- below 12% remaining voxels or 0 HP, the nest is beyond repair and must be rebuilt elsewhere
NEST_DAMAGED_RATIO = 0.94     -- below 94% remaining voxels/HP, the centipede will repair the nest when visiting/returning

SPEED = {lurk = 2.6, roam = 6.5, stalk = 4.2, chase = 6.0, drag = 4.2, flee = 8.5}
ROAM_D = 45                   -- m: farther than this from every player, a lurking worm roams toward them
WATER_SLOW = 0.8              -- in water a bit slower (divers swim ~3 m/s)
-- erratic tempo: {weight, speed factor, min s, max s} per state
TEMPO = {
	lurk = {{0.25, 0.72, 1.8, 3.5}, {0.50, 0.95, 2.2, 4.5}, {0.25, 1.15, 1.5, 3.0}}, -- smooth, continuous prowling without jerky stops
	stalk = {{0.30, 0.80, 1.4, 2.8}, {0.45, 1.05, 1.6, 3.2}, {0.25, 1.30, 1.0, 2.2}},
	chase = {{0.45, 1.05, 1.2, 2.5}, {0.55, 1.35, 1.0, 2.2}},
	drag = {{0.30, 0.85, 1.2, 2.5}, {0.70, 1.05, 1.5, 3.0}},
	flee = {{1.0, 1.15, 1.5, 3.0}},
}
TWITCH = {lurk = 0.0, stalk = 0.25, chase = 0.25, drag = 0.2, flee = 0.15}  -- minimal lateral twitch for fluid motion

local function now() return GetTime() end
local function vlen(v) return VecLength(v) end
local function dist(a, b) return VecLength(VecSub(a, b)) end

function wormFilter()
	QueryRequire("physical static")
	QueryCollisionMask(WORM_QUERY_MASK)
end

-- sphere cast from a to b; true when clear
function wormClear(a, b, r)
	local d = VecSub(b, a)
	local l = VecLength(d)
	if l < 0.001 then return true end
	wormFilter()
	local hit = QueryRaycast(a, VecScale(d, 1 / l), l, r or HEAD_R)
	return not hit
end

function wormFree(p, r)
	wormFilter()
	local hit = QueryClosestPoint(p, r)
	return not hit
end

SURF_R = 1.7         -- Max distance from a surface when not bridging a gap
CLING_DIST = 0.38    -- Desired distance from the surface skin
GRAVITY_SPEED = 14.0 -- Fall speed when detached in mid-air beyond body reach

-- Finds nearest physical surface within r; returns hit, closestPoint, distance, normal
-- Water: it swims on the surface only. The water's top within r of p (over it or under it) is a surface, reported
-- so that the cling (CLING_DIST from the surface point) holds it WATER_RIDE under the top, its back awash; under
-- water with the top farther than r overhead there is no surface at all, the sea floor included (wormMove heads up).
WATER_RIDE = 0.1     -- m under the water's top a swimming Silkmaw rides
WATER_WADE = 0.6     -- m under the water's top down to which it still crawls on solid things (banks, shallows)

-- y of the water's top if it is within r over or under p; nil, true = under water deeper than r
function wormWaterTop(p, r)
	r = r or SURF_R
	local x, y, z = p[1], p[2], p[3]
	if IsPointInWater(p) then
		if IsPointInWater(Vec(x, y + r, z)) then return nil, true end
		local lo, hi = 0, r                                         -- (in water at lo, out at hi)
		for _ = 1, 4 do
			local m = (lo + hi) * 0.5
			if IsPointInWater(Vec(x, y + m, z)) then lo = m else hi = m end
		end
		return y + (lo + hi) * 0.5
	end
	if not IsPointInWater(Vec(x, y - r, z)) then return nil end
	local lo, hi = 0, r                                             -- (out at lo, in water at hi, going down)
	for _ = 1, 4 do
		local m = (lo + hi) * 0.5
		if IsPointInWater(Vec(x, y - m, z)) then hi = m else lo = m end
	end
	return y - (lo + hi) * 0.5
end

function wormSurface(p, r)
	local top, deep = wormWaterTop(p, r)
	if deep then return false end
	local inWater = top and top > p[2]
	-- solid things come first out of the water, and in it down to WATER_WADE under the top: there it still crawls
	-- on the bank or the bed (swimming, the water's top was its only surface: it could not climb a bank out of a
	-- pond, seen in-game 2026-11-12). Deeper, the water's top is the surface, whatever is near.
	if not inWater or top - p[2] <= WATER_WADE then
		wormFilter()
		local hit, cp, normal = QueryClosestPoint(p, r or SURF_R)
		if hit then return true, cp, dist(p, cp), normal end
		if not top then return false end
	end
	-- the water: a point straight below, as far as the cling wants it when p is at the ride height
	local d = math.max(0.01, CLING_DIST + (p[2] - (top - WATER_RIDE)))
	return true, Vec(p[1], p[2] - d, p[3]), d, Vec(0, 1, 0)
end

-- Checks if a straight path from a to b is clear AND any gap between surfaces is shorter than maxBridge
function wormBridgeClear(a, b, r, maxBridge)
	local d = VecSub(b, a)
	local L = VecLength(d)
	local maxB = maxBridge or (BODY_LEN * 0.88)
	if L > maxB then return false end                           -- (before the sphere cast: most goals are out of reach)
	if not wormClear(a, b, r) then return false end
	local steps = math.floor(L / 0.6)
	local airRun = 0
	for i = 1, steps do
		local p = VecLerp(a, b, i / (steps + 1))
		if not wormSurface(p, SURF_R) then
			airRun = airRun + 0.6
			if airRun > maxB * 0.85 then return false end
		else
			airRun = 0
		end
	end
	return true
end

-- True when the worm's rear body is still anchored on a surface behind it (within bodyLen) AND it is reaching
-- across a gap (< bodyLen) toward a surface or waypoint ahead
function wormCanBridge(w, nxtPos, aim)
	local maxReach = (w.bodyLen or BODY_LEN) * 0.88
	-- Check if anchorPos or any point along the body trail is still touching a surface within maxReach
	local anchored = false
	local anchorDist = 1e9
	if w.anchorPos then
		anchorDist = dist(nxtPos, w.anchorPos)
		if anchorDist < maxReach then anchored = true end
	end
	if not anchored then
		local t = w.trail
		local stepBack = math.max(1, math.floor(#t / 6))
		for i = #t, 1, -stepBack do
			local d = dist(nxtPos, t[i])
			if d < maxReach and wormSurface(t[i], SURF_R) then
				anchored = true
				anchorDist = d
				w.anchorPos = VecCopy(t[i])
				break
			end
		end
	end
	if not anchored then return false end
	local remReach = math.max(1.5, maxReach - anchorDist + 1.5)
	if aim then
		local toAim = VecSub(aim, nxtPos)
		local aimD = vlen(toAim)
		if aimD <= remReach and wormSurface(aim, SURF_R * 1.4) then
			return true
		end
		if aimD > 0.05 then
			wormFilter()
			local hit = QueryRaycast(nxtPos, VecScale(toAim, 1 / aimD), math.min(remReach, aimD + 2.0), 0.15)
			if hit then return true end
		end
	end
	wormFilter()
	local hitFwd = QueryRaycast(nxtPos, w.fwd, remReach, 0.15)
	return hitFwd
end

function wormChest(p)
	return VecAdd(GetPlayerTransform(p).pos, Vec(0, 1.1, 0))
end

local function pick(list)
	local r, acc = math.random(), 0
	for _, e in ipairs(list) do
		acc = acc + e[1]
		if r <= acc then return e end
	end
	return list[#list]
end

----- trail: trail[1] oldest .. trail[#trail] newest (next to the head) -----

function wormTrailLen(w)
	local L, t = 0, w.trail
	for i = #t, 2, -1 do L = L + dist(t[i], t[i - 1]) end
	return L + dist(w.pos, t[#t])
end

function wormRecord(w)
	local t = w.trail
	local tn = w.trailNorm
	local d = dist(w.pos, t[#t])
	if d >= TRAIL_STEP then
		t[#t + 1] = VecCopy(w.pos)
		if tn then tn[#tn + 1] = VecCopy(w.up or Vec(0, 1, 0)) end
		w.trailLen = w.trailLen + d
		local keep = (w.bodyLen or BODY_LEN) + TRAIL_SPARE
		while #t > 2 and w.trailLen > keep do
			w.trailLen = w.trailLen - dist(t[1], t[2])
			table.remove(t, 1)
			if tn and #tn > #t then table.remove(tn, 1) end
		end
	end
end

-- Smoothly absorb combat recoil, while backing out along the trail when physically wedged (d > 1.6)
function wormRecoil(w, d)
	local t = w.trail
	local tn = w.trailNorm
	local up = w.up or Vec(0, 1, 0)
	w.speed = math.min(w.speed or 0, 1.0)
	if (d or 0) > 1.6 and #t > 2 then
		local back = math.min(d * 0.35, 1.1)
		while back > 0 and #t > 2 do
			local last = t[#t]
			local step = dist(w.pos, last)
			if step > back then
				w.pos = VecAdd(w.pos, VecScale(VecNormalize(VecSub(last, w.pos)), back))
				back = 0
			else
				w.pos = VecCopy(last)
				back = back - step
				t[#t] = nil
				if tn and #tn > #t then tn[#tn] = nil end
				w.trailLen = math.max(0, w.trailLen - step)
			end
		end
	end
	local side = VecNormalize(VecCross(up, w.fwd or Vec(1, 0, 0)))
	if vlen(side) < 0.1 then side = Vec(0, 0, 1) end
	local turnSign = ((w.id or 1) % 2 == 0) and 1 or -1
	if math.random() < 0.35 then turnSign = -turnSign end
	w.fwd = VecNormalize(VecAdd(VecScale(w.fwd, 0.65), VecScale(side, 0.75 * turnSign)))
	-- Guarantee the tail end of the trail is always at least bodyLen long
	local bLen = w.bodyLen or BODY_LEN
	local curLen = wormTrailLen(w)
	if curLen < bLen and #t >= 2 then
		local tailDir = VecNormalize(VecSub(t[1], t[2]))
		if vlen(tailDir) < 0.1 then tailDir = VecScale(w.fwd, -1) end
		local need = bLen - curLen
		local tailN = (tn and tn[1]) or up
		local segs = math.max(1, math.ceil(need / TRAIL_PUB))
		local stepD = need / segs
		for _ = 1, segs do
			local newOldest = VecAdd(t[1], VecScale(tailDir, stepD))
			table.insert(t, 1, newOldest)
			if tn then table.insert(tn, 1, VecCopy(tailN)) end
			w.trailLen = w.trailLen + stepD
		end
	end
end

-- points along the body from the head back, every `step` m, up to `len` m (flat x, y, z list)
function wormSample(w, step, len, withNorms)
	local out = {w.pos[1], w.pos[2], w.pos[3]}
	local u0 = w.up or Vec(0, 1, 0)
	local norms = withNorms and {u0[1], u0[2], u0[3]} or nil
	local t = w.trail
	local tn = w.trailNorm
	local prev, prevN, want, acc = w.pos, u0, step, 0
	for i = #t, 1, -1 do
		local q = t[i]
		local qn = (tn and tn[i]) or u0
		local seg = dist(prev, q)
		while seg > 0 and acc + seg >= want and want <= len do
			local f = (want - acc) / seg
			local p = VecLerp(prev, q, f)
			out[#out + 1] = p[1]; out[#out + 1] = p[2]; out[#out + 1] = p[3]
			if norms then
				local n = VecNormalize(VecLerp(prevN, qn, f))
				norms[#norms + 1] = n[1]; norms[#norms + 1] = n[2]; norms[#norms + 1] = n[3]
			end
			want = want + step
		end
		acc = acc + seg
		prev = q
		prevN = qn
		if want > len then break end
	end
	if want <= len then
		local tailDir = (#t >= 2) and VecNormalize(VecSub(t[1], t[2])) or VecScale(w.fwd or Vec(1, 0, 0), -1)
		if vlen(tailDir) < 0.1 then tailDir = Vec(-1, 0, 0) end
		while want <= len do
			local extra = want - acc
			local p = VecAdd(prev, VecScale(tailDir, extra))
			out[#out + 1] = p[1]; out[#out + 1] = p[2]; out[#out + 1] = p[3]
			if norms then
				norms[#norms + 1] = prevN[1]; norms[#norms + 1] = prevN[2]; norms[#norms + 1] = prevN[3]
			end
			want = want + step
		end
	end
	return out, norms
end

----- Procedural Surface-Sprayed White Silk Vein Nest (<= 2 Voxels Thick, 6 Progressive Layers) -----

NEST_CLEAR_R = 1.65           -- m: minimum core floor radius to start spraying the silk vein network (veins climb nearby walls/pillars/ceilings)
NEST_CLEAR_H = 1.85           -- m: minimum vertical headroom at the central brood hub

-- Queries all physical geometry (both static walls/floors AND dynamic objects/props/vehicles)
-- while ignoring WORM_LAYER and Living Humans ragdolls
function wormNestFilter()
	QueryRequire("physical")
	QueryCollisionMask(WORM_QUERY_MASK)
	for _, b in ipairs(FindBodies("livinghuman", true) or {}) do
		if IsHandleValid(b) then QueryRejectBody(b) end
	end
end

-- Verifies that a candidate point `p` lies inside the playable map (not out-of-bounds beyond perimeter walls)
function wormPointInsideMap(p, refOrigin)
	if IsPointInWater(p) then return false end
	local ref = refOrigin or p
	if math.abs(p[2] - ref[2]) > 28.0 or p[2] < -25.0 or p[2] > 65.0 then
		return false
	end
	wormFilter()
	local downHit, downD, downN = QueryRaycast(VecAdd(p, Vec(0, 1.5, 0)), Vec(0, -1, 0), 6.0)
	if not downHit or (downN and downN[2] < 0.45) then
		return false
	end
	-- Must have static map geometry in at least 3 of 8 compass directions within 55m, including opposing hemispheres
	local hits = 0
	local posX, negX, posZ, negZ = false, false, false, false
	for i = 1, 8 do
		local ang = (i / 8) * 6.283185
		local dx, dz = math.cos(ang), math.sin(ang)
		wormFilter()
		local hit, hd = QueryRaycast(VecAdd(p, Vec(0, 1.0, 0)), Vec(dx, 0, dz), 55.0)
		if hit and hd < 55.0 then
			hits = hits + 1
			if dx > 0.2 then posX = true elseif dx < -0.2 then negX = true end
			if dz > 0.2 then posZ = true elseif dz < -0.2 then negZ = true end
		end
	end
	if hits < 3 then return false end
	if not ((posX and negX) or (posZ and negZ) or hits >= 5) then
		return false
	end
	return true
end

-- Checks whether a point p has a solid ceiling/overhang directly above it and angled sky cover
function wormHasOverheadCover(p, maxCeilH)
	local maxH = maxCeilH or 16.0
	local origin = VecAdd(p, Vec(0, 0.35, 0))
	wormFilter()
	local upHit, upDist = QueryRaycast(origin, Vec(0, 1, 0), maxH)
	if not upHit or upDist < NEST_CLEAR_H then
		return false, upDist or 99, 0
	end
	local skyDirs = {
		VecNormalize(Vec(0.38, 1, 0)),
		VecNormalize(Vec(-0.38, 1, 0)),
		VecNormalize(Vec(0, 1, 0.38)),
		VecNormalize(Vec(0, 1, -0.38)),
	}
	local skyHits = 0
	for _, d in ipairs(skyDirs) do
		wormFilter()
		local sh, sd = QueryRaycast(origin, d, maxH + 3.0)
		if sh and sd > 1.8 then skyHits = skyHits + 1 end
	end
	return true, upDist, skyHits
end

-- Verifies that `baseP` is inside the playable map, has a solid floor for the central brood hub,
-- and has surrounding surfaces (floors, walls, pillars, ceilings) to spray the white silk vein network onto.
function wormNestSpaceClear(baseP, clearR, clearH, refOrigin)
	local r = clearR or NEST_CLEAR_R
	local h = clearH or NEST_CLEAR_H
	if IsPointInWater(baseP) or IsPointInWater(VecAdd(baseP, Vec(0, 1.0, 0))) then
		return false
	end
	if not wormPointInsideMap(baseP, refOrigin) then
		return false
	end
	-- Check central floor support around baseP
	local footCheckOffsets = {
		Vec(0.95, 0, 0), Vec(-0.95, 0, 0), Vec(0, 0, 0.95), Vec(0, 0, -0.95),
	}
	for _, off in ipairs(footCheckOffsets) do
		wormFilter()
		local fHit, fDist = QueryRaycast(VecAdd(baseP, VecAdd(off, Vec(0, 1.1, 0))), Vec(0, -1, 0), 2.3)
		if not fHit or math.abs(fDist - 1.1) > 0.75 then
			return false
		end
	end
	-- Check vertical headroom above the central brood hub
	wormNestFilter()
	local uHit, uDist = QueryRaycast(VecAdd(baseP, Vec(0, 0.25, 0)), Vec(0, 1, 0), h)
	if uHit and uDist < (h - 0.25) then
		return false
	end
	-- Ensure the central hub itself isn't embedded inside a solid wall/prop
	wormNestFilter()
	local hitCore = QueryClosestPoint(VecAdd(baseP, Vec(0, 0.85, 0)), 0.70)
	if hitCore then return false end
	-- Ensure at least 3 horizontal directions have open room to crawl in/out
	local openDirs = 0
	for i = 1, 8 do
		local ang = (i / 8) * 6.283185
		local dir = Vec(math.cos(ang), 0, math.sin(ang))
		wormNestFilter()
		local hit, hd = QueryRaycast(VecAdd(baseP, Vec(0, 0.65, 0)), dir, r)
		if not hit or hd >= r then
			openDirs = openDirs + 1
		end
	end
	return openDirs >= 3
end

-- Checks if any active point/spot light or flashlight illuminates point p
function wormLightPenaltyAt(p)
	local penalty = 0
	local lights = wormLightList or (FindLights and FindLights("", true)) or {}   -- (a nest search lists them once)
	for _, l in ipairs(lights) do
		if IsHandleValid(l) and IsLightActive(l) then
			local lt = GetLightTransform(l)
			local d = dist(lt.pos, p)
			if d < 18.0 and wormClear(lt.pos, VecAdd(p, Vec(0, 0.5, 0)), 0.02) then
				penalty = penalty + math.max(2.0, (18.0 - d) * 1.25)
			end
		end
	end
	return penalty
end

-- Evaluates how dark, sheltered, and surface-rich a point `p` is for spraying the procedural white silk vein nest
function wormDarkSpotScore(p, requireCover, refOrigin)
	if IsPointInWater(p) then return -1 end
	wormFilter()
	local down, dd = QueryRaycast(VecAdd(p, Vec(0, 2.2, 0)), Vec(0, -1, 0), 14.0)
	if not down then return -1 end
	local baseP = VecAdd(p, Vec(0, 2.2 - dd, 0))
	local navP = VecAdd(baseP, Vec(0, 0.45, 0))
	if IsPointInWater(baseP) or not wormFree(navP, HEAD_R) then return -1 end

	local okNav = Nav.free(navP)
	if not okNav then return -1 end

	if not wormNestSpaceClear(baseP, NEST_CLEAR_R, NEST_CLEAR_H, refOrigin) then
		return -1
	end

	local hasCeil, ceilDist, skyHits = wormHasOverheadCover(baseP, 16.5)
	if requireCover and (not hasCeil or skyHits < 2) then
		return -1
	end

	local score = 0
	if hasCeil then
		score = score + 18.0 + math.max(0, (16.5 - ceilDist) * 0.85) + skyHits * 3.5
		if ceilDist >= 2.2 and ceilDist <= 8.5 then
			score = score + 6.0
		end
	else
		score = score - 12.0
	end

	-- Reward nearby walls/pillars (between 1.7m and 9m) that the procedural silk vein network can climb and coat
	local wallDirs = {
		Vec(1, 0, 0), Vec(-1, 0, 0), Vec(0, 0, 1), Vec(0, 0, -1),
		Vec(0.707, 0, 0.707), Vec(-0.707, 0, 0.707), Vec(0.707, 0, -0.707), Vec(-0.707, 0, -0.707),
	}
	local wallHits = 0
	local openWays = 0
	for _, d in ipairs(wallDirs) do
		wormFilter()
		local hit, hd = QueryRaycast(VecAdd(baseP, Vec(0, 1.0, 0)), d, 9.5)
		if hit then
			if hd < 1.15 then
				return -1
			end
			wallHits = wallHits + 1
			score = score + 2.2 + math.max(0, (9.5 - hd) * 0.35)
		else
			openWays = openWays + 1
		end
	end
	if openWays == 0 then return -1 end
	if wallHits >= 3 then score = score + 6.0 end
	if requireCover and wallHits < 2 then return -1 end

	local lightPen = wormLightPenaltyAt(navP)
	if requireCover and lightPen > 6.0 then return -1 end
	score = score - lightPen

	for _, q in ipairs(GetAllPlayers()) do
		if GetPlayerHealth(q) > 0 then
			local eye = GetPlayerEyeTransform(q).pos
			local d = dist(eye, navP)
			if d < 12 then return -1 end
			if d < 60 and wormClear(eye, navP, 0.05) then
				score = score - 8.0
				local fl = GetFlashlight(q)
				if fl ~= 0 and IsLightActive(fl) then return -1 end
			else
				score = score + math.min(d, 60) * 0.06
			end
		end
	end
	return score, navP
end

-- Finds a dark, ceiling-covered location strictly inside the map for the centipede to spray its silk vein nest.
-- The search is spread over frames (testing every candidate at once cost thousands of queries in one frame: a
-- hitch for the host and, in multiplayer, everyone): this only collects the candidates and starts the job
-- (w.nestSearch); wormNestSearchStep tests NEST_SEARCH_PER_TICK of them per call and returns the site when done.
-- Returns nil (callers store it in w.nestTarget: wormGoal waits for the job and sets the target).
NEST_SEARCH_PER_TICK = 3

function wormFindDarkNestSite(w, avoidPos, minR, maxR)
	local rMin = minR or 8.0
	local rMax = maxR or 44.0
	local origin = avoidPos or w.pos
	local cands = {}

	-- Pass 1A: Raycast horizontally and only test points BEFORE hitting a wall (never step blindly through outer map walls!)
	for i = 1, 24 do
		local ang = (i / 24) * 6.283 + (math.random() - 0.5) * 0.15
		local dir = Vec(math.cos(ang), 0, math.sin(ang))
		for _, hOff in ipairs({0.8, 3.0, -1.5}) do
			local rayOrig = VecAdd(w.pos, Vec(0, hOff, 0))
			wormFilter()
			local hit, hd = QueryRaycast(rayOrig, dir, rMax)
			if hit and hd > 4.5 then
				cands[#cands + 1] = {VecAdd(rayOrig, VecScale(dir, hd - 2.4)), true}
				if hd > 9.0 then
					cands[#cands + 1] = {VecAdd(rayOrig, VecScale(dir, hd * 0.55)), true}
				end
			end
		end
	end

	-- Pass 1B: Radial sampling bounded by raycasts from origin so candidates stay inside the map
	for i = 1, 64 do
		local r = rMin + math.random() * math.max(6.0, rMax - rMin)
		local ang = math.random() * 6.283
		local dir = Vec(math.cos(ang), 0, math.sin(ang))
		local dy = (i % 4 == 0) and (-1.5 - math.random() * 4.0) or ((math.random() - 0.35) * 8.0)
		local startP = VecAdd(origin, Vec(0, dy, 0))
		wormFilter()
		local hit, hd = QueryRaycast(VecAdd(startP, Vec(0, 1.0, 0)), dir, r)
		local safeR = (hit and hd > 3.5) and (hd - 2.0) or r
		cands[#cands + 1] = {VecAdd(startP, VecScale(dir, safeR)), true}
	end

	w.nestSearch = {
		cands = cands, i = 1, avoidPos = avoidPos, minAvoid = minR or 14.0, origin = origin,
		refOrigin = w.lair or w.pos, rMin = rMin, rMax = rMax, bestP = nil, bestSc = -1000, fallback = false,
		lights = FindLights and FindLights("", true) or {},      -- (the map's lights, listed once for the whole search)
	}
	return nil
end

-- Advances a nest-site search; returns the site once every candidate is tested (nil while it runs or when none runs)
function wormNestSearchStep(w)
	local s = w.nestSearch
	if not s then return nil end
	wormLightList = s.lights
	local found = nil
	for _ = 1, NEST_SEARCH_PER_TICK do
		local c = s.cands[s.i]
		if c then
			s.i = s.i + 1
			local cand, strictCover = c[1], c[2]
			local farEnough = (not s.avoidPos) or (dist(cand, s.avoidPos) >= s.minAvoid)
			if farEnough then
				for _, ns in ipairs(wormNests) do
					if dist(cand, ns.pos) < math.min(s.minAvoid, 22.0) then
						farEnough = false
						break
					end
				end
			end
			if farEnough then
				local sc, snapped = wormDarkSpotScore(cand, strictCover, s.refOrigin)
				if sc and sc > 0 and snapped and (not s.avoidPos or dist(snapped, s.avoidPos) >= s.minAvoid * 0.8) then
					local totalSc = sc - dist(w.pos, snapped) * 0.09
					if totalSc > s.bestSc then
						s.bestSc, s.bestP = totalSc, snapped
					end
				end
			end
		elseif not s.bestP and not s.fallback then
			-- Pass 2: Fallback if the map has few enclosed ceilings, still enforcing wormPointInsideMap
			s.fallback = true
			for _ = 1, 40 do
				local r = s.rMin + math.random() * math.max(4.0, s.rMax - s.rMin)
				local ang = math.random() * 6.283
				s.cands[#s.cands + 1] = {VecAdd(s.origin, Vec(math.cos(ang) * r, (math.random() - 0.35) * 6.0, math.sin(ang) * r)), false}
			end
		else
			found = s.bestP or VecCopy(w.pos)
			w.nestSearch = nil
			break
		end
	end
	wormLightList = nil
	return found
end

-- Checks if a point is close to any active nest so the centipede's own bites/acid never damage its nest
function wormNearAnyNest(p, rad)
	for _, ns in ipairs(wormNests) do
		local r = rad or ((ns.extent or NEST_RADIUS) + 1.0)
		if dist(p, ns.pos) < r then return true end
	end
	return false
end

-- Sums voxels across all shapes of a body using Teardown's GetShapeVoxelCount(shape) API
function wormBodyVoxelCount(body)
	if not body or body == 0 or not IsHandleValid(body) then return 0 end
	local total = 0
	for _, sh in ipairs(GetBodyShapes(body) or {}) do
		if GetShapeVoxelCount then
			total = total + (GetShapeVoxelCount(sh) or 0)
		else
			total = total + 100
		end
	end
	return total
end

-- A nest is several bodies (one per sprayed layer: w.nestBodies; a repair that had to respray leaves one): their
-- voxels in all, and whether every one of them still stands
function wormNestBodiesState(bodies)
	if not bodies or #bodies == 0 then return 0, false end
	local total = 0
	for _, b in ipairs(bodies) do
		-- (a broken body still counts: the silk is plaster now and breaks piece by piece - with IsBodyBroken here
		--  the first hole of any kind was the end of the whole nest; the voxels left decide)
		if b == 0 or not IsHandleValid(b) then return 0, false end
		total = total + wormBodyVoxelCount(b)
	end
	return total, true
end

-- Deletes a nest's bodies (the list itself is kept: wormNests shares it)
function wormNestDeleteBodies(w)
	local list = w.nestBodies or {}
	for i = #list, 1, -1 do
		local b = list[i]
		if b ~= 0 and IsHandleValid(b) then
			for _, sh in ipairs(GetBodyShapes(b) or {}) do wormNestShapes[sh] = nil end
			Delete(b)
		end
		list[i] = nil
	end
	w.nestBody = 0
	w.nestIntegT = nil
	w.nestPieces = {}
	w.nestGrow = nil
end

-- Returns the nest's current structural integrity ratio (0.0 to 1.0) combining voxel count and structural HP.
-- Counted at most twice a second per nest (it reads every shape of the nest; it was asked several times a frame):
-- whatever changes it (damage, a repair, a rebuild) clears w.nestIntegT.
function wormNestIntegrity(w)
	if not w.nestBuilt then return 0 end
	local t = now()
	if w.nestIntegT and t < w.nestIntegT then return w.nestInteg or 0 end
	local v = 0
	local curVox, ok = wormNestBodiesState(w.nestBodies)
	if ok then
		local initVox = math.max(100, wormNestInitVox(w))
		local voxRatio = curVox / initVox
		local maxHp = w.nestMaxHp or NEST_MAX_HP
		local hpRatio = math.max(0, (w.nestHp or maxHp) / maxHp)
		if curVox > 0 and voxRatio >= NEST_DESTROY_RATIO and hpRatio > 0 then
			v = math.min(voxRatio, hpRatio)
		end
	end
	w.nestInteg, w.nestIntegT = v, t + 0.5
	return v
end

-- True when the nest still stands (above the 12% destruction threshold)
function wormIsNestIntact(w)
	return wormNestIntegrity(w) >= NEST_DESTROY_RATIO
end

-- True when the nest is intact but has suffered damage (< 94% integrity) and needs repair
function wormIsNestDamaged(w)
	local integ = wormNestIntegrity(w)
	return integ >= NEST_DESTROY_RATIO and integ < NEST_DAMAGED_RATIO
end

-- Generates a subtle, deterministic organic shade variation around a base RGB silk color
-- (For Ignitus nests, blends a charred mixture of dark brown and ash grey)
local function wormSilkShade(r, g, b, seed, amp, variant)
	local a = amp or 0.036
	local n = math.sin(seed * 12.9898 + 78.233) * 43758.5453
	n = n - math.floor(n)
	if variant == "ignitus" then
		local mix = math.sin(seed * 7.19 + 1.3) * 0.5 + 0.5
		-- Mix between dark charred brown (0.25, 0.17, 0.12) and dark slate/ash grey (0.31, 0.30, 0.29)
		local br = 0.23 + 0.09 * mix + (r - 0.88) * 0.22
		local bg = 0.16 + 0.14 * mix + (g - 0.92) * 0.18
		local bb = 0.11 + 0.18 * mix + (b - 0.88) * 0.18
		local d = (n - 0.5) * 2.0 * a
		local cr = math.max(0.12, math.min(0.45, br + d))
		local cg = math.max(0.10, math.min(0.42, bg + d * 0.9))
		local cb = math.max(0.08, math.min(0.40, bb + d * 0.85))
		return string.format("%.3f %.3f %.3f", cr, cg, cb)
	elseif variant == "seismica" then
		local mix = math.sin(seed * 5.83 + 0.7) * 0.5 + 0.5
		-- Mix between warm tectonic ochre/sandstone (0.48, 0.38, 0.24) and granite/slate (0.34, 0.31, 0.27)
		local br = 0.34 + 0.15 * mix + (r - 0.88) * 0.25
		local bg = 0.29 + 0.11 * mix + (g - 0.92) * 0.20
		local bb = 0.22 + 0.06 * mix + (b - 0.88) * 0.15
		local d = (n - 0.5) * 2.0 * a
		local cr = math.max(0.20, math.min(0.62, br + d))
		local cg = math.max(0.16, math.min(0.52, bg + d * 0.9))
		local cb = math.max(0.11, math.min(0.40, bb + d * 0.8))
		return string.format("%.3f %.3f %.3f", cr, cg, cb)
	end
	local d = (n - 0.5) * 2.0 * a
	local m = math.sin(seed * 4.13) * (a * 0.48)
	local cr = math.max(0.72, math.min(1.0, r + d + m * 0.45))
	local cg = math.max(0.75, math.min(1.0, g + d + m * 0.20))
	local cb = math.max(0.70, math.min(1.0, b + d - m * 0.45))
	return string.format("%.3f %.3f %.3f", cr, cg, cb)
end

-- Steps a surface-hugging silk vein from (curP, curN) along tangent direction `dir` by `stepLen` metres,
-- smoothly climbing walls, pillars, slopes, or ceilings encountered within the nest zone.
local function wormStepSurfaceVein(curP, curN, dir, stepLen)
	local tang = VecSub(dir, VecScale(curN, VecDot(dir, curN)))
	if vlen(tang) < 0.05 then
		tang = VecCross(curN, math.abs(curN[2]) < 0.9 and Vec(0, 1, 0) or Vec(1, 0, 0))
	end
	tang = VecNormalize(tang)

	-- 1. Check if the vein meets an adjacent wall / pillar / ceiling corner straight ahead
	local liftOrig = VecAdd(curP, VecScale(curN, 0.16))
	wormFilter()
	local fHit, fDist, fNorm = QueryRaycast(liftOrig, tang, stepLen + 0.12)
	if fHit and fNorm and vlen(fNorm) > 0.5 then
		local hitP = VecAdd(liftOrig, VecScale(tang, math.max(0.05, fDist - 0.02)))
		local newTang = VecSub(curN, VecScale(fNorm, VecDot(curN, fNorm)))
		if vlen(newTang) < 0.1 then newTang = VecAdd(tang, VecScale(fNorm, -VecDot(tang, fNorm))) end
		return hitP, VecNormalize(fNorm), VecNormalize(newTang)
	end

	-- 2. Advance along the tangent and project back onto the underlying surface
	local probeOrig = VecAdd(liftOrig, VecScale(tang, stepLen))
	wormFilter()
	local sHit, sDist, sNorm = QueryRaycast(probeOrig, VecScale(curN, -1), 0.95)
	if sHit and sNorm and vlen(sNorm) > 0.5 then
		local hitP = VecAdd(probeOrig, VecScale(curN, -sDist))
		local newTang = VecSub(tang, VecScale(sNorm, VecDot(tang, sNorm)))
		if vlen(newTang) < 0.05 then newTang = tang end
		return hitP, VecNormalize(sNorm), VecNormalize(newTang)
	end

	-- 3. Fallback: wrap around convex ledges/corners using QueryClosestPoint
	local candP = VecAdd(curP, VecScale(tang, stepLen))
	wormFilter()
	local cpHit, cpPt, cpNorm = QueryClosestPoint(candP, 0.85)
	if cpHit and cpPt and cpNorm and vlen(cpNorm) > 0.5 then
		local newTang = VecSub(tang, VecScale(cpNorm, VecDot(tang, cpNorm)))
		if vlen(newTang) < 0.05 then newTang = tang end
		return cpPt, VecNormalize(cpNorm), VecNormalize(newTang)
	end
	return nil, nil, nil
end

-- Helper to register one surface-conforming silk <voxbox> segment (never thicker than 2 voxels: hVox = 1 or 2)
local function wormAddSilkSurfaceBox(segList, baseP, p0, p1, surfNorm, wVox, hVox, col, isGlow, minStage)
	local d = VecSub(p1, p0)
	local len = vlen(d)
	if len < 0.08 then return end
	local clampedH = math.max(1, math.min(2, hVox)) -- Strictly 1 or 2 voxels thick!
	local zAxis = VecScale(d, 1 / len)
	local n = surfNorm or Vec(0, 1, 0)
	local yAxis = VecSub(n, VecScale(zAxis, VecDot(n, zAxis)))
	if vlen(yAxis) < 0.05 then
		yAxis = VecCross(zAxis, math.abs(zAxis[2]) < 0.9 and Vec(0, 1, 0) or Vec(1, 0, 0))
	end
	yAxis = VecNormalize(yAxis)
	if VecDot(yAxis, n) < 0 then yAxis = VecScale(yAxis, -1) end
	local xAxis = VecNormalize(VecCross(yAxis, zAxis))
	yAxis = VecCross(zAxis, xAxis)

	local lVox = math.max(2, math.floor((len + 0.08) * 10 + 0.5))
	local worldCorner = VecAdd(
		p0,
		VecAdd(
			VecScale(xAxis, -0.5 * wVox * 0.1),
			VecAdd(VecScale(yAxis, -0.015), VecScale(zAxis, -0.04))
		)
	)
	local localCorner = VecSub(worldCorner, baseP)
	local rot = QuatAlignXZ(xAxis, zAxis)

	segList[#segList + 1] = {
		wVox = wVox,
		hVox = clampedH,
		lVox = lVox,
		col = col,
		isGlow = isGlow,
		minStage = minStage,
		localTr = Transform(localCorner, rot),
		localPos = localCorner,
		midWorld = VecLerp(p0, p1, 0.5),
		norm = n,
		p0 = VecCopy(p0), p1 = VecCopy(p1),
	}
end

-- Helper for cocoons: appends a short catenary silk anchor strand in local coordinates
local function wormAddOrganicTendril(parts, x1, y1, z1, x2, y2, z2, sagY, baseThickVox, r, g, b, seed, isGlow, variant)
	local segs = 2
	local tagStr = isGlow and "tags='nocull nestglow' " or "tags='nocull' "
	local mat = "hardmasonry"                                  -- (as Silkmaw 1.0.3, every kind)
	for s = 1, segs do
		local t0 = (s - 1) / segs
		local t1 = s / segs
		local s0 = 4.0 * t0 * (1.0 - t0) * sagY
		local s1 = 4.0 * t1 * (1.0 - t1) * sagY
		local p0 = Vec(x1 + (x2 - x1) * t0, y1 + (y2 - y1) * t0 + s0, z1 + (z2 - z1) * t0)
		local p1 = Vec(x1 + (x2 - x1) * t1, y1 + (y2 - y1) * t1 + s1, z1 + (z2 - z1) * t1)
		if p1[2] < p0[2] then p0, p1 = p1, p0 end
		local dx = p1[1] - p0[1]
		local dy = math.max(0.15, p1[2] - p0[2])
		local dz = p1[3] - p0[3]
		local len = math.sqrt(dx * dx + dy * dy + dz * dz)
		local hVox = math.max(4, math.floor(len * 10.8 + 0.5))
		local th = math.max(1, math.min(2, baseThickVox))
		local rzDeg = -math.asin(math.max(-1, math.min(1, dx / len))) * 57.29578
		local rxDeg = -math.atan2(dz, dy) * 57.29578
		local col = wormSilkShade(r, g, b, seed * 23 + s * 7, 0.038, variant)
		parts[#parts + 1] = string.format(
			"<voxbox %smaterial='" .. mat .. "' pos='%.3f %.3f %.3f' rot='%.1f 0.0 %.1f' size='%d %d %d' color='%s'/>",
			tagStr, p0[1] - th * 0.05, p0[2], p0[3] - th * 0.05, rxDeg, rzDeg, th, hVox, th, col
		)
	end
end

-- Procedurally traces the 6-layer network of white silk veins & webbing over the surfaces around `baseP`
function wormTraceSilkNetwork(baseP, variant)
	local segList = {}
	local silkFloorNodes = { {pos = VecCopy(baseP), norm = Vec(0, 1, 0)} }
	local numArteries = NEST_SPOKES
	local stepsPerArtery = 8
	local stepLen = 0.68 -- 8 * 0.68m = ~5.45m radius (~11m diameter)

	-- 1. Central silk brood hub (Layer 1: 1-voxel base plates + 2-voxel raised central vein cross)
	for i = 1, 5 do
		local ang = (i / 5) * 3.141593
		local dir = Vec(math.cos(ang), 0, math.sin(ang))
		local p0 = VecAdd(baseP, VecScale(dir, -0.85))
		local p1 = VecAdd(baseP, VecScale(dir,  0.85))
		wormAddSilkSurfaceBox(segList, baseP, p0, p1, Vec(0, 1, 0), 6, 1, wormSilkShade(0.85, 0.89, 0.84, i * 7, 0.025, variant), false, 1)
		wormAddSilkSurfaceBox(segList, baseP, p0, p1, Vec(0, 1, 0), 2, 2, wormSilkShade(0.96, 0.99, 0.95, i * 13, 0.020, variant), true,  1)
	end

	-- 2. Trace NEST_SPOKES (10; the pack: 14) primary arterial veins radiating outward across floor, walls, and ceiling
	local arteries = {}
	for a = 1, numArteries do
		local angBase = ((a - 0.5) / numArteries) * 6.283185
		local curP = VecCopy(baseP)
		local curN = Vec(0, 1, 0)
		local curDir = Vec(math.cos(angBase), 0, math.sin(angBase))
		arteries[a] = { {pos = curP, norm = curN, dir = curDir} }

		for s = 1, stepsPerArtery do
			local side = VecNormalize(VecCross(curN, curDir))
			local wave = math.sin(a * 2.1 + s * 1.15) * 0.24
			local steerDir = VecNormalize(VecAdd(curDir, VecScale(side, wave)))
			local nxtP, nxtN, nxtDir = wormStepSurfaceVein(curP, curN, steerDir, stepLen)
			if not nxtP then break end

			arteries[a][s + 1] = {pos = nxtP, norm = nxtN, dir = nxtDir}
			if nxtN[2] > 0.55 then
				silkFloorNodes[#silkFloorNodes + 1] = {pos = VecCopy(nxtP), norm = VecCopy(nxtN)}
			end

			local st = (s <= 3) and 1 or ((s <= 5) and 2 or 3)
			local hVox = (s <= 6) and 2 or 1
			local wVox = (s <= 3) and 3 or 2
			local col = wormSilkShade(0.94, 0.98, 0.93, a * 31 + s * 11, 0.030, variant)
			wormAddSilkSurfaceBox(segList, baseP, curP, nxtP, nxtN, wVox, hVox, col, s <= 5, st)

			curP, curN, curDir = nxtP, nxtN, nxtDir
		end
	end

	-- 3. Secondary bifurcating veins branching off the primary arteries (Stages 2 & 4)
	for a = 1, numArteries do
		local chain = arteries[a]
		for _, branchStep in ipairs({3, 5}) do
			local node = chain[branchStep]
			if node then
				local bStage = (branchStep == 3) and 2 or 4
				local sign = (a % 2 == 0) and 1 or -1
				local side = VecNormalize(VecCross(node.norm, node.dir))
				local bDir = VecNormalize(VecAdd(VecScale(node.dir, 0.78), VecScale(side, 0.62 * sign)))
				local bP, bN = node.pos, node.norm
				for bs = 1, 3 do
					local nP, nN, nD = wormStepSurfaceVein(bP, bN, bDir, 0.58)
					if not nP then break end
					local hVox = (bs == 1) and 2 or 1
					local col = wormSilkShade(0.91, 0.95, 0.89, a * 53 + branchStep * 17 + bs, 0.032, variant)
					wormAddSilkSurfaceBox(segList, baseP, bP, nP, nN, 2, hVox, col, bs == 1, bStage)
					if nN[2] > 0.55 then
						silkFloorNodes[#silkFloorNodes + 1] = {pos = VecCopy(nP), norm = VecCopy(nN)}
					end
					bP, bN, bDir = nP, nN, nD
				end
			end
		end
	end

	-- 4. Anastomosing cross-veins connecting adjacent primary arteries into a webbed vein network (Stages 3 & 4)
	for _, ringStep in ipairs({2, 4, 6}) do
		local cStage = (ringStep <= 4) and 3 or 4
		local hVox = (ringStep == 2) and 2 or 1
		for a = 1, numArteries do
			local aNext = (a % numArteries) + 1
			local n1 = arteries[a] and arteries[a][ringStep]
			local n2 = arteries[aNext] and arteries[aNext][ringStep + ((a % 2 == 0) and 1 or 0)] or (arteries[aNext] and arteries[aNext][ringStep])
			if n1 and n2 and dist(n1.pos, n2.pos) < 2.8 then
				local midP = VecLerp(n1.pos, n2.pos, 0.5)
				wormFilter()
				local cpHit, cpPt, cpNorm = QueryClosestPoint(midP, 0.65)
				if cpHit and cpPt and cpNorm then
					local col1 = wormSilkShade(0.90, 0.94, 0.88, a * 41 + ringStep * 7, 0.030, variant)
					local col2 = wormSilkShade(0.90, 0.94, 0.88, a * 41 + ringStep * 7 + 3, 0.030, variant)
					wormAddSilkSurfaceBox(segList, baseP, n1.pos, cpPt, cpNorm, 2, hVox, col1, ringStep == 2, cStage)
					wormAddSilkSurfaceBox(segList, baseP, cpPt, n2.pos, cpNorm, 2, hVox, col2, ringStep == 2, cStage)
					if cpNorm[2] > 0.55 then
						silkFloorNodes[#silkFloorNodes + 1] = {pos = VecCopy(cpPt), norm = VecCopy(cpNorm)}
					end
				end
			end
		end
	end

	-- 5. Layer 5: 1-voxel-thick silk membrane/sheet patches sprayed between the raised 2-voxel veins (Stage 5)
	for _, ringStep in ipairs({2, 3, 5}) do
		for a = 1, numArteries do
			local aNext = (a % numArteries) + 1
			local n1 = arteries[a] and arteries[a][ringStep]
			local n2 = arteries[aNext] and arteries[aNext][ringStep]
			if n1 and n2 and dist(n1.pos, n2.pos) < 2.5 then
				local avgN = VecNormalize(VecAdd(n1.norm, n2.norm))
				local col = wormSilkShade(0.83, 0.88, 0.82, 500 + a * 19 + ringStep, 0.035, variant)
				wormAddSilkSurfaceBox(segList, baseP, n1.pos, n2.pos, avgN, 5, 1, col, false, 5)
			end
		end
	end

	-- 6. Layer 6: Fine 1-voxel outer capillary tendrils & 2-voxel luminous brood-node pads at vein junctions (Stage 6)
	for a = 1, numArteries do
		local chain = arteries[a]
		local tip = chain[#chain]
		if tip and #chain >= 5 then
			for _, sideSign in ipairs({-1, 1}) do
				local side = VecNormalize(VecCross(tip.norm, tip.dir))
				local cDir = VecNormalize(VecAdd(VecScale(tip.dir, 0.72), VecScale(side, 0.68 * sideSign)))
				local nP, nN = wormStepSurfaceVein(tip.pos, tip.norm, cDir, 0.62)
				if nP then
					local col = wormSilkShade(0.88, 0.92, 0.86, 700 + a * 11 + sideSign, 0.035, variant)
					wormAddSilkSurfaceBox(segList, baseP, tip.pos, nP, nN, 1, 1, col, false, 6)
				end
			end
		end
		local broodNode = chain[3] or chain[2]
		if broodNode and (a % 2 == 1) then
			local p0 = VecAdd(broodNode.pos, VecScale(broodNode.dir, -0.25))
			local p1 = VecAdd(broodNode.pos, VecScale(broodNode.dir,  0.25))
			local col = wormSilkShade(0.98, 1.00, 0.97, 900 + a, 0.015, variant)
			wormAddSilkSurfaceBox(segList, baseP, p0, p1, broodNode.norm, 4, 2, col, true, 6)
		end
	end

	local arteryTips = {}
	for a = 1, numArteries do
		local chain = arteries[a]
		arteryTips[a] = chain[#chain]
	end
	return segList, silkFloorNodes, arteryTips
end

-- One expansion ring (tier 2..NEST_MAX_TIER), traced a few strands a frame (wormNestGrowStep) and spawned as one piece
-- when done (the pack traced a whole ring in one frame, ~410 engine queries, and spawned ~235 shapes at once). The nest
-- grows like a plant, not a wheel: of its open tips (ring 1's NEST_SPOKES spoke ends, then every branch end) only
-- RING_GROW_TIPS are picked each ring and grow a branch; some branches fork, and the fork's end is a new open tip.
-- Tips not picked wait for a later ring. So every ring costs the same, however many rings there are.
NEST_SPOKES = 12              -- spokes of ring 1 (the pack: 14)
RING_GROW_TIPS = 6            -- tips that grow a branch each ring
RING_STEPS = 5                -- strips along each branch (the pack: 8 of 0.68 m)
RING_STEP_LEN = 1.1           -- m per strip
RING_FORK_P = 0.5             -- chance that a branch forks (after RING_FORK_AT strips) into a second, shorter one
RING_FORK_AT = 3
RING_FORK_STEPS = 3
RING_FORK_LEN = 1.0
RING_CROSS_R = 4.0            -- two new branches whose middles are this close get a strand of webbing between them
RING_LADDER_R = 3.2           -- ...and a few straight threads between their nodes this close (web ladders, no queries)
RING_HAIRS = 2                -- fine threads off each strip of a branch (alternating sides; drawn into the same shapes)
RING_HAIR_LEN = 0.75          -- m
RING_MAX_TIPS = 40            -- open tips kept (the innermost go first)
GROW_BRANCHES_PER_STEP = 2    -- branches traced per frame

-- the open tips: picks RING_GROW_TIPS of them, the ones nearest the middle first (with some chance for the others),
-- so the nest fills in round its middle instead of running out in long tendrils (seen in-game when the outer tips won)
RING_SHORT_BIAS = 1.2         -- added to a tip's random 0..1 score: all of it at the middle, none at the outermost tip
local function pickTips(tips, baseP, n)
	local far = 0.1
	for _, t in ipairs(tips) do far = math.max(far, dist(t.pos, baseP)) end
	local pool = {}
	for i, t in ipairs(tips) do
		pool[#pool + 1] = {i = i, w = math.random() + RING_SHORT_BIAS * (1 - dist(t.pos, baseP) / far)}
	end
	table.sort(pool, function(x, y) return x.w > y.w end)
	local out = {}
	for k = 1, math.min(n, #pool) do out[k] = pool[k].i end
	return out
end

function wormNestGrowStart(w, tier)
	local tips = {}
	for _, t in ipairs(w.nestArteryTips or {}) do tips[#tips + 1] = t end
	local baseP = w.nestTr.pos
	if #tips == 0 then                                         -- (no tips kept: spokes from the middle)
		for a = 1, NEST_SPOKES do
			local ang = ((a - 0.5) / NEST_SPOKES) * 6.283185
			local dir = Vec(math.cos(ang), 0, math.sin(ang))
			tips[a] = {pos = VecAdd(baseP, VecScale(dir, NEST_RADIUS * 0.85)), norm = Vec(0, 1, 0), dir = dir}
		end
	end
	return {tier = tier, baseP = baseP, variant = w.variant, phase = "branches", k = 1, sk = 1, segs = {}, nodes = {},
		tips = tips, pick = pickTips(tips, baseP, RING_GROW_TIPS), grown = {}, newTips = {}, used = {},
		oldNodes = w.nestSilkNodes or {}, extent = w.nestExtent or NEST_RADIUS}
end

-- one strand of silk from a node: n strips of len m, wandering a little; returns its chain of nodes
local function growStrand(g, node, dir, n, len, thick, seed)
	local curP, curN, curDir = node.pos, node.norm, dir
	local chain = { {pos = curP, norm = curN, dir = curDir} }
	for s = 1, n do
		local side = VecNormalize(VecCross(curN, curDir))
		local wave = math.sin(seed * 2.1 + (s + g.tier * 8) * 1.15) * 0.24
		local nxtP, nxtN, nxtDir = wormStepSurfaceVein(curP, curN, VecNormalize(VecAdd(curDir, VecScale(side, wave))), len)
		if not nxtP then break end
		chain[#chain + 1] = {pos = nxtP, norm = nxtN, dir = nxtDir}
		if nxtN[2] > 0.55 then g.nodes[#g.nodes + 1] = {pos = VecCopy(nxtP), norm = VecCopy(nxtN)} end
		local col = wormSilkShade(0.93, 0.97, 0.92, g.tier * 131 + seed * 31 + s * 11, 0.030, g.variant)
		wormAddSilkSurfaceBox(g.segs, g.baseP, curP, nxtP, nxtN, (thick and s <= 1) and 3 or 2, (thick and s <= 2) and 2 or 1,
			col, thick and s <= 2, 6)
		for hk = 1, RING_HAIRS do                              -- (fine threads off the strand: fuller, no engine queries)
			local sgn = ((s + hk + seed) % 2 == 0) and 1 or -1
			local at = VecLerp(curP, nxtP, (hk - 0.5) / RING_HAIRS)
			local hl = RING_HAIR_LEN * (0.6 + 0.4 * math.random())
			local hd = VecNormalize(VecAdd(VecScale(nxtDir, 0.55), VecScale(side, 0.83 * sgn)))
			local hcol = wormSilkShade(0.90, 0.95, 0.89, g.tier * 37 + seed * 17 + s * 7 + hk, 0.035, g.variant)
			wormAddSilkSurfaceBox(g.segs, g.baseP, at, VecAdd(at, VecScale(hd, hl)), nxtN, 1, 1, hcol, false, 6)
		end
		curP, curN, curDir = nxtP, nxtN, nxtDir
	end
	return chain
end

-- grows the k-th picked tip: a branch outward, maybe a fork; the branch's end (and the fork's) become open tips
local function growBranch(g, k)
	local ti = g.pick[k]
	local tip = g.tips[ti]
	if not tip then return end
	g.used[ti] = true
	local out = VecSub(tip.pos, g.baseP)
	out[2] = 0
	out = VecLength(out) > 0.3 and VecNormalize(out) or tip.dir
	local dir = VecNormalize(VecAdd(VecScale(tip.dir, 0.6), VecScale(out, 0.4)))   -- (onward, bent outward)
	local chain = growStrand(g, tip, dir, RING_STEPS, RING_STEP_LEN, true, ti)
	if #chain < 2 then g.newTips[#g.newTips + 1] = tip; return end   -- (nowhere to go: stays open)
	g.grown[#g.grown + 1] = chain
	g.newTips[#g.newTips + 1] = chain[#chain]
	local fn = chain[math.min(#chain, RING_FORK_AT + 1)]
	if #chain > RING_FORK_AT and math.random() < RING_FORK_P then
		local side = VecNormalize(VecCross(fn.norm, fn.dir))
		local sign = (math.random() < 0.5) and 1 or -1
		local fDir = VecNormalize(VecAdd(VecScale(fn.dir, 0.76), VecScale(side, 0.64 * sign)))
		local fork = growStrand(g, fn, fDir, RING_FORK_STEPS, RING_FORK_LEN, false, ti + 50)
		if #fork >= 2 then g.newTips[#g.newTips + 1] = fork[#fork] end
	end
end

-- Sprouts: besides the tips, a ring may start a new branch off silk already laid, into the barest side round it, so
-- gaps between the branches fill in. A few old silk nodes are looked at; round each, the silk within RING_SPROUT_R is
-- counted in 8 directions along its surface (Lua only, no engine queries) and the emptiest direction wins, the more
-- so if the sprout stays inside the nest (outward is always bare at the edge; the tips already grow outward).
RING_SPROUTS = 2              -- tries per ring
RING_SPROUT_P = 0.6           -- chance of each try
RING_SPROUT_STEPS = 4         -- strips of a sprout (RING_STEP_LEN each)
RING_SPROUT_R = 3.0           -- m: silk round a node counted to find its bare side
RING_SPROUT_LOOKS = 10        -- old nodes looked at per sprout
RING_SPROUT_FULL = 4          -- a side with this much silk (weighted count) is not bare: no sprout there
local function sproutBranch(g, k)
	local pool = g.oldNodes
	if #pool == 0 or math.random() >= RING_SPROUT_P then return end
	local lists = {pool, g.nodes, g.tips, g.newTips}
	local reach = RING_SPROUT_STEPS * RING_STEP_LEN
	local best, bestS, bestDir = nil, 1e9, nil
	for _ = 1, RING_SPROUT_LOOKS do
		local c = pool[math.random(#pool)]
		local n = c.norm
		local t1 = VecCross(n, Vec(0, 0, 1))
		if VecLength(t1) < 0.2 then t1 = VecCross(n, Vec(1, 0, 0)) end
		t1 = VecNormalize(t1)
		local t2 = VecCross(n, t1)
		local bins = {0, 0, 0, 0, 0, 0, 0, 0}
		for _, list in ipairs(lists) do
			for _, o in ipairs(list) do
				local d = VecSub(o.pos, c.pos)
				local l = VecLength(d)
				if l > 0.3 and l < RING_SPROUT_R then
					local a = math.atan2(VecDot(d, t2), VecDot(d, t1))
					local b = math.floor(a / 6.283185 * 8 + 8.5) % 8 + 1
					bins[b] = bins[b] + 1
				end
			end
		end
		for b = 1, 8 do
			local s = bins[b] + 0.5 * (bins[(b % 8) + 1] + bins[((b + 6) % 8) + 1])
			if s < RING_SPROUT_FULL then
				local ang = (b - 1) / 8 * 6.283185
				local dir = VecAdd(VecScale(t1, math.cos(ang)), VecScale(t2, math.sin(ang)))
				local over = dist(VecAdd(c.pos, VecScale(dir, reach)), g.baseP) - g.extent   -- (past the nest's edge)
				s = s + math.max(0, over) * 0.8 + math.random() * 0.6
				if s < bestS then best, bestS, bestDir = c, s, dir end
			end
		end
	end
	if not best then return end
	local chain = growStrand(g, best, bestDir, RING_SPROUT_STEPS, RING_STEP_LEN, false, 200 + k * 13)
	if #chain < 2 then return end
	g.grown[#g.grown + 1] = chain
	g.newTips[#g.newTips + 1] = chain[#chain]
	g.sprouts = (g.sprouts or 0) + 1
end

-- webbing between new branches that run close to each other
local function growCross(g)
	for i = 1, #g.grown do
		for j = i + 1, #g.grown do
			local c1, c2 = g.grown[i], g.grown[j]
			local n1, n2 = c1[math.ceil(#c1 / 2) + 1] or c1[#c1], c2[math.ceil(#c2 / 2) + 1] or c2[#c2]
			if dist(n1.pos, n2.pos) < RING_CROSS_R then
				wormFilter()
				local cpHit, cpPt, cpNorm = QueryClosestPoint(VecLerp(n1.pos, n2.pos, 0.5), 0.75)
				if cpHit and cpPt and cpNorm then
					local col = wormSilkShade(0.89, 0.94, 0.87, g.tier * 71 + i * 41 + j, 0.030, g.variant)
					wormAddSilkSurfaceBox(g.segs, g.baseP, n1.pos, cpPt, cpNorm, 2, 1, col, false, 6)
					wormAddSilkSurfaceBox(g.segs, g.baseP, cpPt, n2.pos, cpNorm, 2, 1, col, false, 6)
					if cpNorm[2] > 0.55 then g.nodes[#g.nodes + 1] = {pos = VecCopy(cpPt), norm = VecCopy(cpNorm)} end
				end
			end
			local rungs = 0
			for k = 2, math.min(#c1, #c2) do                   -- (rungs between matching nodes on the same surface)
				local a, b = c1[k], c2[k]
				if rungs < 3 and dist(a.pos, b.pos) < RING_LADDER_R and VecDot(a.norm, b.norm) > 0.9 then
					local col = wormSilkShade(0.88, 0.93, 0.86, g.tier * 53 + i * 19 + j * 7 + k, 0.035, g.variant)
					wormAddSilkSurfaceBox(g.segs, g.baseP, a.pos, b.pos, a.norm, 1, 1, col, false, 6)
					rungs = rungs + 1
				end
			end
		end
	end
end

-- the tips after a ring: the ones not picked, then the new branch ends; the innermost go if there are too many
local function nextTips(g)
	local all = {}
	for i, t in ipairs(g.tips) do if not g.used[i] then all[#all + 1] = t end end
	for _, t in ipairs(g.newTips) do all[#all + 1] = t end
	if #all > RING_MAX_TIPS then
		table.sort(all, function(x, y) return dist(x.pos, g.baseP) > dist(y.pos, g.baseP) end)
		for i = #all, RING_MAX_TIPS + 1, -1 do all[i] = nil end
	end
	return all
end

-- how far the nest's silk reaches from its middle (checks round the nest use it, not the ring count)
function wormNestExtent(w)
	local c = (w.nestTr and w.nestTr.pos) or w.nestPos
	if not c then return NEST_RADIUS end
	local r = NEST_RADIUS
	for _, nd in ipairs(w.nestSilkNodes or {}) do r = math.max(r, dist(nd.pos, c)) end
	for _, t in ipairs(w.nestArteryTips or {}) do r = math.max(r, dist(t.pos, c)) end
	return r
end

-- one frame's share of a growing ring; spawns it and finishes when done
function wormNestGrowStep(w)
	local g = w.nestGrow
	if not g then return end
	if not w.nestBuilt or not w.nestTr then w.nestGrow = nil; return end   -- (the nest was destroyed meanwhile)
	if g.phase == "branches" then
		for _ = 1, GROW_BRANCHES_PER_STEP do
			if g.k > #g.pick then break end
			growBranch(g, g.k)
			g.k = g.k + 1
		end
		if g.k > #g.pick then g.phase = "sprouts" end
	elseif g.phase == "sprouts" then                               -- (one a frame)
		if g.sk <= RING_SPROUTS then sproutBranch(g, g.sk) end
		g.sk = g.sk + 1
		if g.sk > RING_SPROUTS then g.phase = "cross" end
	elseif g.phase == "cross" then
		growCross(g)
		g.phase = "spawn"
	else
		w.nestGrow = nil
		w.nestTier = g.tier
		w.nestArteryTips = nextTips(g)
		w.nestSprouts = (w.nestSprouts or 0) + (g.sprouts or 0)    -- (counted for the tests)
		w.nestSegs = w.nestSegs or {}
		for _, seg in ipairs(g.segs) do w.nestSegs[#w.nestSegs + 1] = seg end
		w.nestSilkNodes = w.nestSilkNodes or {}
		for _, nd in ipairs(g.nodes) do w.nestSilkNodes[#w.nestSilkNodes + 1] = nd end
		wormNestSpawnPiece(w, "r" .. g.tier, g.segs)
		w.nestExtent = wormNestExtent(w)
		w.nestMaxHp = NEST_MAX_HP                              -- (the same 300 at any size: as easy to wreck as 1.0.3's)
		w.nestHp = w.nestMaxHp
		w.nestIntegT = nil
		w.repairingNestUntil = now() + 2.0
		for _, ns in ipairs(wormNests) do
			if ns.owner == w.id then
				ns.bodies = w.nestBodies
				ns.tier = g.tier
				ns.extent = w.nestExtent
				ns.repairing = true
			end
		end
	end
end

-- Grows the nest by one ring (up to NEST_MAX_TIER): started here, traced over the next frames (wormNestGrowStep).
-- instant = true: all of it now (tests).
function wormExpandSilkNest(w, instant)
	if not w.nestBuilt or not w.nestTr or not w.nestPos then return false end
	if not w.nestGrow then
		if (w.nestTier or 1) >= NEST_MAX_TIER then return false end
		w.nestGrow = wormNestGrowStart(w, (w.nestTier or 1) + 1)
		w.mouth = 0.9
		w.ev.spit = (w.ev.spit or 0) + 1
		w.ev.hiss = w.ev.hiss + 1
	elseif not instant then
		return false
	end
	if instant then
		for _ = 1, 64 do
			if not w.nestGrow then break end
			wormNestGrowStep(w)
		end
	end
	return true
end

-- Picks a floor/surface node directly on the sprayed white silk layer for placing eggs or cocoons
function wormPickSilkSurfacePos(w, minDistFromCenter, maxDistFromCenter)
	local baseP = (w.nestTr and w.nestTr.pos) or w.nestPos or w.lair or w.pos
	local nodes = w.nestSilkNodes
	if nodes and #nodes > 0 then
		local valid = {}
		for _, nd in ipairs(nodes) do
			local d = dist(nd.pos, baseP)
			local maxR = maxDistFromCenter or (w.nestExtent or NEST_RADIUS)
			if d >= (minDistFromCenter or 0.0) and d <= maxR then
				valid[#valid + 1] = nd
			end
		end
		if #valid > 0 then
			local chosen = valid[math.random(#valid)]
			return VecCopy(chosen.pos), VecCopy(chosen.norm)
		end
		local fallback = nodes[math.random(#nodes)]
		return VecCopy(fallback.pos), VecCopy(fallback.norm)
	end
	return VecCopy(baseP), Vec(0, 1, 0)
end

-- A nest is made of PIECES (w.nestPieces[key] = {i, segs, initVox, spawnT}): ring 1's six build layers ("s1".."s6") and
-- every outer ring ("r2".."r5"), each its own body in w.nestBodies (at index i). A repair resprays only the pieces
-- that lost silk (the pack resprayed the whole nest: ~1,300 shapes to every client at 5 rings). No "nocull" on nest
-- silk: far away the engine may fade it like any small thing.
NEST_PAINT = true             -- the silk painted into a few shapes per piece (wormPaintSilkBody); false: one voxbox per strip

-- the segments of ring 1's build layer st
function wormNestStageSegs(w, st)
	local out = {}
	for _, seg in ipairs(w.nestSegs or {}) do
		if not seg.ring and seg.minStage == st then out[#out + 1] = seg end
	end
	return out
end

-- one voxbox per strip (the pack's way; NEST_PAINT = false)
function wormSpawnSilkBoxes(w, segs)
	local parts = {"<body tags='silkmawnest' dynamic='false'>"}
	for idx, seg in ipairs(segs) do
		parts[#parts + 1] = string.format(
			"<voxbox tags='%ssv=%d' material='plaster' pos='%.3f %.3f %.3f' size='%d %d %d' color='%s'/>",
			seg.isGlow and "nestglow " or "", idx, seg.localPos[1], seg.localPos[2], seg.localPos[3], seg.wVox, seg.hVox, seg.lVox, seg.col)
	end
	parts[#parts + 1] = "</body>"
	local body = 0
	for _, e in ipairs(Spawn(table.concat(parts), w.nestTr, true) or {}) do
		if GetEntityType(e) == "body" then
			body = e
			SetBodyDynamic(body, false)
			SetBodyTransform(body, w.nestTr)
			for _, sh in ipairs(GetBodyShapes(e)) do
				local sIdx = tonumber(GetTagValue(sh, "sv"))
				if sIdx and segs[sIdx] then SetShapeLocalTransform(sh, segs[sIdx].localTr) end
				SetShapeCollisionFilter(sh, WORM_LAYER, 255 - WORM_LAYER)
				SetShapeEmissiveScale(sh, HasTag(sh, "nestglow") and 0.24 or 0.08)
				wormNestShapes[sh] = w
			end
		end
	end
	return body
end

-- The silk painted into a few shapes per piece (NEST_PAINT): the piece's strips are grouped by their angle round the
-- nest into sections at most PAINT_SECTION m on any axis (glowing strips apart), and each section is ONE shape
-- (CreateShape with the silk palette vox/silkpal.vox, plaster rows 105-120) with every strip drawn into it as voxel
-- lines (SetBrush + DrawShapeLine), as thick and as wide as its box was. ~235 shapes a ring become ~20. Any engine
-- call failing (pcall) leaves the boxes instead.
SILK_PAL_FILE = "MOD/vox/silkpal.vox"
PAINT_SECTION = 6.0           -- m: a painted shape covers at most this on each axis
PAINT_LIFT = 0.08             -- m per voxel of thickness: a strand's middle above the surface (0.05 left them in the ground)
SILK_PAL = {                  -- the palette rows (vox/silkpal.vox, made by giantcentipedes/tools/make_silkpal.py)
	acidica = {105, {{0.97, 0.99, 0.96}, {0.94, 0.97, 0.93}, {0.91, 0.95, 0.90}, {0.88, 0.92, 0.87},
		{0.85, 0.89, 0.84}, {0.82, 0.87, 0.82}, {0.79, 0.84, 0.79}, {0.76, 0.81, 0.76}}},
	ignitus = {113, {{0.38, 0.34, 0.31}, {0.32, 0.27, 0.24}, {0.27, 0.22, 0.19}, {0.22, 0.18, 0.15}}},
	seismica = {117, {{0.56, 0.46, 0.31}, {0.49, 0.40, 0.28}, {0.43, 0.37, 0.29}, {0.36, 0.32, 0.27}}},
}

-- the palette index nearest a strip's colour ("r g b"), in its kind's rows
function wormSilkPalIndex(variant, col)
	local set = SILK_PAL[variant] or SILK_PAL.acidica
	local r, g, b = string.match(col or "", "([%d%.]+) ([%d%.]+) ([%d%.]+)")
	r, g, b = tonumber(r) or 0.9, tonumber(g) or 0.9, tonumber(b) or 0.9
	local best, bd = set[1], 1e9
	for i, c in ipairs(set[2]) do
		local d = (c[1] - r) ^ 2 + (c[2] - g) ^ 2 + (c[3] - b) ^ 2
		if d < bd then best, bd = set[1] + i - 1, d end
	end
	return best
end

local function paintSection(w, body, group, lo, hi, glow)
	local m = 0.3
	local ox, oy, oz = math.floor((lo[1] - m) * 10) / 10, math.floor((lo[2] - m) * 10) / 10, math.floor((lo[3] - m) * 10) / 10
	local nx = math.min(128, math.ceil((hi[1] + m - ox) * 10) + 1)
	local ny = math.min(128, math.ceil((hi[2] + m - oy) * 10) + 1)
	local nz = math.min(128, math.ceil((hi[3] + m - oz) * 10) + 1)
	local sh = CreateShape(body, Transform(Vec(ox, oy, oz)), SILK_PAL_FILE)
	if not sh or sh == 0 then error("CreateShape failed") end
	ResizeShape(sh, 0, 0, 0, nx - 1, ny - 1, nz - 1)
	for _, e in ipairs(group) do
		local seg, a, b = e[1], e[2], e[3]
		local th = math.max(1, math.min(2, seg.hVox or 1))
		local lines = math.max(1, math.ceil((seg.wVox or th) / th))
		local d = VecSub(b, a)
		local n = seg.norm or Vec(0, 1, 0)
		local side = VecCross(n, d)
		side = VecLength(side) > 1e-4 and VecNormalize(side) or Vec(1, 0, 0)
		local lift = VecScale(n, PAINT_LIFT * th)
		SetBrush("cube", th, wormSilkPalIndex(w.variant, seg.col))
		for k = 1, lines do
			local off = VecAdd(lift, VecScale(side, (k - (lines + 1) / 2) * 0.1 * th))
			local p0, p1 = VecAdd(a, off), VecAdd(b, off)
			DrawShapeLine(sh, (p0[1] - ox) * 10, (p0[2] - oy) * 10, (p0[3] - oz) * 10, (p1[1] - ox) * 10, (p1[2] - oy) * 10, (p1[3] - oz) * 10)
		end
	end
	SetShapeCollisionFilter(sh, WORM_LAYER, 255 - WORM_LAYER)
	SetShapeEmissiveScale(sh, glow and 0.24 or 0.08)
	SetTag(sh, "nocull")                  -- (seen in-game: without it the 1-voxel strands faded out past ~15 m and left
	if glow then SetTag(sh, "nestglow") end   -- only their shadows; a nest is a few dozen shapes now, so it is cheap)
	wormNestShapes[sh] = w
end

-- a piece's silk painted into a fresh static body at the nest (0 when it could not be: the boxes are used then)
function wormPaintSilkBody(w, segs)
	if not (CreateShape and ResizeShape and SetBrush and DrawShapeLine) or not w.nestTr then return 0 end
	-- (on the world's 0.1 m voxel grid: at the nest's exact spot the voxels sat across the ground's, and the 1-voxel
	--  strands half inside the ground came out dark - seen in-game)
	local tp = w.nestTr.pos
	local tr = Transform(Vec(math.floor(tp[1] * 10 + 0.5) / 10, math.floor(tp[2] * 10 + 0.5) / 10, math.floor(tp[3] * 10 + 0.5) / 10),
		w.nestTr.rot)
	local body = 0
	for _, e in ipairs(Spawn("<body tags='silkmawnest' dynamic='false'/>", tr, true) or {}) do
		if GetEntityType(e) == "body" then body = e end
	end
	if body == 0 then return 0 end
	local ok, err = pcall(function()
		SetBodyDynamic(body, false)
		SetBodyTransform(body, tr)
		local c = tr.pos
		for _, glow in ipairs({false, true}) do
			local list = {}
			for _, seg in ipairs(segs) do
				if (seg.isGlow and true or false) == glow and seg.p0 and seg.p1 then
					local mid = VecLerp(seg.p0, seg.p1, 0.5)
					list[#list + 1] = {seg, VecSub(seg.p0, c), VecSub(seg.p1, c), math.atan2(mid[3] - c[3], mid[1] - c[1])}
				end
			end
			table.sort(list, function(x, y) return x[4] < y[4] end)
			local group, lo, hi = {}, nil, nil
			for _, e in ipairs(list) do
				local a, b = e[2], e[3]
				local slo = Vec(math.min(a[1], b[1]), math.min(a[2], b[2]), math.min(a[3], b[3]))
				local shi = Vec(math.max(a[1], b[1]), math.max(a[2], b[2]), math.max(a[3], b[3]))
				if lo then
					local nlo = Vec(math.min(lo[1], slo[1]), math.min(lo[2], slo[2]), math.min(lo[3], slo[3]))
					local nhi = Vec(math.max(hi[1], shi[1]), math.max(hi[2], shi[2]), math.max(hi[3], shi[3]))
					if nhi[1] - nlo[1] > PAINT_SECTION or nhi[2] - nlo[2] > PAINT_SECTION or nhi[3] - nlo[3] > PAINT_SECTION then
						paintSection(w, body, group, lo, hi, glow)
						group, lo, hi = {}, nil, nil
					else
						lo, hi = nlo, nhi
					end
				end
				if not lo then lo, hi = slo, shi end
				group[#group + 1] = e
			end
			if #group > 0 then paintSection(w, body, group, lo, hi, glow) end
		end
	end)
	if not ok then
		wormNestPaintError = tostring(err)                    -- (for the TEST panel: why the boxes were used)
		for _, sh in ipairs(GetBodyShapes(body) or {}) do wormNestShapes[sh] = nil end
		Delete(body)
		return 0
	end
	return body
end

-- spawn (or respray) piece `key` from `segs`; returns its body (0: nothing to spawn)
function wormNestSpawnPiece(w, key, segs)
	w.nestPieces = w.nestPieces or {}
	w.nestBodies = w.nestBodies or {}
	if not segs or #segs == 0 then return 0 end
	for _, seg in ipairs(segs) do seg.ring = seg.ring or (string.sub(key, 1, 1) == "r") end
	local body = 0
	if NEST_PAINT then body = wormPaintSilkBody(w, segs) end
	if body == 0 then body = wormSpawnSilkBoxes(w, segs) end
	local piece = w.nestPieces[key] or {}
	piece.segs, piece.initVox, piece.spawnT = segs, nil, now()
	if piece.i then w.nestBodies[piece.i] = body else w.nestBodies[#w.nestBodies + 1] = body; piece.i = #w.nestBodies end
	w.nestPieces[key] = piece
	w.nestBody = w.nestBodies[1] or 0
	w.nestIntegT = nil
	return body
end

-- the nest's voxels when whole: each piece's count, taken once it has settled (0.3 s after its spawn)
function wormNestInitVox(w)
	local total = 0
	for _, piece in pairs(w.nestPieces or {}) do
		local b = w.nestBodies and w.nestBodies[piece.i]
		if not piece.initVox and b and b ~= 0 and IsHandleValid(b) and now() - (piece.spawnT or 0) > 0.3 then
			piece.initVox = wormBodyVoxelCount(b)
		end
		total = total + (piece.initVox or (b and b ~= 0 and IsHandleValid(b) and wormBodyVoxelCount(b) or 0))
	end
	return total
end

-- Finds the nearest floor point around `prefP` that is strictly inside the playable map and suitable for spraying silk
function wormResolveClearNestBase(w, prefP)
	local refOrigin = w.lair or w.pos
	local candidates = {prefP, w.pos}
	for i = 1, 24 do
		local r = 0.8 + (i / 24) * 5.5
		local ang = i * 2.39996
		candidates[#candidates + 1] = VecAdd(prefP, Vec(math.cos(ang) * r, 0, math.sin(ang) * r))
	end
	for _, c in ipairs(candidates) do
		wormFilter()
		local hitDown, dDown = QueryRaycast(VecAdd(c, Vec(0, 2.0, 0)), Vec(0, -1, 0), 10.0)
		if hitDown then
			local bp = VecAdd(c, Vec(0, 2.0 - dDown, 0))
			if wormNestSpaceClear(bp, NEST_CLEAR_R, NEST_CLEAR_H, refOrigin) then
				return bp
			end
		end
	end
	return nil
end

-- Starts or advances the progressive 6-layer procedural silk vein spraying over NEST_BUILD_DURATION (15s)
function wormBuildSilkNest(w)
	if w.nestBuilt or w.variant == "machina" then w.nestBuilt = true; return end
	local t = now()

	-- Phase 1: Initialize the nest site, trace the surface vein network, and spray Stage 1
	if not w.buildingNest then
		local prefSite = (w.nestTarget and dist(w.pos, w.nestTarget) < 5.0) and w.nestTarget or w.pos
		local baseP = wormResolveClearNestBase(w, prefSite)
		if not baseP then
			if (w.nestRetries or 0) < 4 then
				w.nestRetries = (w.nestRetries or 0) + 1
				w.nestTarget = wormFindDarkNestSite(w, w.motherNestPos, 6.0, 44.0)
				w.nestStartT = t
				w.path = nil
				w.planGoal = nil
				return
			end
			wormFilter()
			local hitDown, dDown = QueryRaycast(VecAdd(w.pos, Vec(0, 1.5, 0)), Vec(0, -1, 0), 10.0)
			baseP = hitDown and VecAdd(w.pos, Vec(0, 1.5 - dDown, 0)) or VecCopy(w.pos)
		end

		local interiorP = VecAdd(baseP, Vec(0, 0.45, 0))
		local nestTr = Transform(baseP, Quat())

		w.buildingNest = true
		w.nestBuildStartT = t
		w.nestBuildStage = 1
		w.nestPos = VecCopy(interiorP)
		w.lair = VecCopy(interiorP)
		w.nestTr = nestTr
		w.nestSegs, w.nestSilkNodes, w.nestArteryTips = wormTraceSilkNetwork(baseP, w.variant)
		w.nestExtent = wormNestExtent(w)
		w.nestTier = 1
		w.nestMaxHp = NEST_MAX_HP
		w.nestHp = NEST_MAX_HP
		w.mouth = 0.85
		w.ev.hiss = w.ev.hiss + 1

		w.nestBodies, w.nestPieces, w.nestGrow = {}, {}, nil
		local body = wormNestSpawnPiece(w, "s1", wormNestStageSegs(w, 1))
		w.nestBody = body
		w.nestIntegT = nil
		w.nestInitVox = math.max(100, wormBodyVoxelCount(body))
		wormNests[#wormNests + 1] = {
			pos = interiorP, tr = nestTr, body = body, bodies = w.nestBodies, initVox = w.nestInitVox,
			owner = w.id, repairing = true, tier = 1, variant = w.variant or "acidica", extent = w.nestExtent,
		}
		return
	end

	-- Phase 2: Progressively spray layers 1..6 over NEST_BUILD_DURATION seconds
	local elapsed = t - (w.nestBuildStartT or t)
	local frac = math.min(1.0, elapsed / NEST_BUILD_DURATION)
	local wantStage = math.min(NEST_BUILD_STAGES, math.floor(frac * NEST_BUILD_STAGES) + 1)

	if wantStage > (w.nestBuildStage or 1) then
		-- each new layer is a body of its own, added to the ones already there (deleting the nest and spawning all of
		-- it again per layer sent ~370 shapes to every client six times)
		local baseP = (w.nestTr and w.nestTr.pos) or VecSub(w.nestPos, Vec(0, 0.45, 0))
		w.nestBodies = w.nestBodies or {}
		for st = (w.nestBuildStage or 1) + 1, wantStage do
			wormNestSpawnPiece(w, "s" .. st, wormNestStageSegs(w, st))
		end
		w.nestBuildStage = wantStage
		w.nestBody = w.nestBodies[1] or 0
		w.nestInitVox = math.max(100, (wormNestBodiesState(w.nestBodies)))
		w.nestIntegT = nil
		w.mouth = 0.9
		if wantStage % 2 == 1 then w.ev.spit = (w.ev.spit or 0) + 1 end
		for _, ns in ipairs(wormNests) do
			if ns.owner == w.id then
				ns.body = w.nestBody
				ns.bodies = w.nestBodies
				ns.initVox = w.nestInitVox
				ns.repairing = true
			end
		end
	end

	-- Complete construction once NEST_BUILD_DURATION has elapsed
	if elapsed >= NEST_BUILD_DURATION then
		w.buildingNest = false
		w.nestBuilt = true
		w.nestIntegT = nil
		w.visitingNest = false
		w.repairingNestUntil = 0
		w.hidingInNest = 0
		w.nextNestVisit = t + NEST_VISIT_MIN + math.random() * (NEST_VISIT_MAX - NEST_VISIT_MIN)
		w.ev.hiss = w.ev.hiss + 1
		for _, ns in ipairs(wormNests) do
			if ns.owner == w.id then ns.repairing = false end
		end
	end
end

-- Re-sprays damaged silk veins when the centipede returns to repair its nest
function wormRepairSilkNest(w)
	if not w.nestBuilt or not w.nestTr or not w.nestPos then return end
	-- the silk is sprayed again only when voxels are really gone; a nest that only lost structural HP keeps its
	-- bodies (a respray is ~370 shapes sent to every client)
	-- (only the pieces that lost silk are sprayed again: the pack deleted and resent the whole nest)
	wormNestInitVox(w)
	local resprayed = 0
	for key, piece in pairs(w.nestPieces or {}) do
		local b = w.nestBodies[piece.i]
		local ok = b and b ~= 0 and IsHandleValid(b)
		if not ok or wormBodyVoxelCount(b) < (piece.initVox or 0) then
			if ok then
				for _, sh in ipairs(GetBodyShapes(b) or {}) do wormNestShapes[sh] = nil end
				Delete(b)
			end
			wormNestSpawnPiece(w, key, piece.segs)
			resprayed = resprayed + 1
		end
	end
	w.nestResprayed = resprayed
	w.nestInitVox = math.max(100, wormNestInitVox(w))
	-- (the nest keeps its tier: the respray above puts back every ring it has. The pack set the tier back to 1 here
	--  while the outer rings stayed, so each repair + visit added a ring past the cap - 3,900 shapes after 12 visits)
	w.nestMaxHp = NEST_MAX_HP
	w.nestHp = w.nestMaxHp
	w.nestIntegT = nil
	w.repairingNestUntil = now() + NEST_REPAIR_DURATION
	w.mouth = 0.9
	w.ev.hiss = w.ev.hiss + 1
	for _, ns in ipairs(wormNests) do
		if ns.owner == w.id then
			ns.body = w.nestBody
			ns.bodies = w.nestBodies
			ns.initVox = w.nestInitVox
			ns.repairing = true
		end
	end
end

----- Water Search (when burning) -----

function wormFindWater(fromPos)
	if IsPointInWater(fromPos) and wormFree(fromPos, 0.2) then return VecCopy(fromPos) end
	local bestP, bestD = nil, 1e9
	-- Sample radial directions to find the closest water surface/shoreline on the map
	for i = 1, 24 do
		local r = (i <= 8) and (4 + i * 3) or (15 + (i - 8) * 6)
		local ang = (i * 2.39996) % 6.283
		local testP = VecAdd(fromPos, Vec(math.cos(ang) * r, 2, math.sin(ang) * r))
		for dy = 0, -14, -2 do
			local p = VecAdd(testP, Vec(0, dy, 0))
			if IsPointInWater(p) then
				-- up to the water's top (it swims on the surface)
				while IsPointInWater(VecAdd(p, Vec(0, 0.4, 0))) and (p[2] - fromPos[2]) < 10 do
					p = VecAdd(p, Vec(0, 0.4, 0))
				end
				-- open water only: the game also calls the inside of the ground below sea level water (measured on
				-- Isla Estocastica: "water" 0.8 m under a worm on dry land), so it ran to a spot on land and burned
				-- there. Nothing solid at the top, and nothing over it for 2 m.
				if wormFree(p, 0.35) and wormClear(VecAdd(p, Vec(0, 2.0, 0)), VecAdd(p, Vec(0, 0.3, 0)), 0.2) then
					local d = dist(fromPos, p)
					if d < bestD then bestD, bestP = d, p end
				end
				break
			end
		end
	end
	return bestP
end

----- Spawning & Juvenile Maturation -----

function wormNew(lair, isBaby, motherId, variant)
	local scale = isBaby and BABY_SCALE or 1.0
	local bLen = isBaby and BABY_BODY_LEN or BODY_LEN
	local initTrail = {}
	local initSteps = 6
	local initNorms = {}
	for k = initSteps, 1, -1 do
		initTrail[#initTrail + 1] = VecAdd(lair, Vec(-(bLen * (k / initSteps)), 0, 0))
		initNorms[#initNorms + 1] = Vec(0, 1, 0)
	end
	initTrail[#initTrail + 1] = VecCopy(lair)
	initNorms[#initNorms + 1] = Vec(0, 1, 0)
	local isMachina = (variant == "machina")
	local maxHp = HP * (isBaby and 0.25 or 1.0)
	local w = {
		id = wormNextId, pos = VecCopy(lair), fwd = Vec(1, 0, 0), up = Vec(0, 1, 0), vel = Vec(0, 0, 0), speed = 0,
		trail = initTrail, trailNorm = initNorms, trailLen = bLen, lair = VecCopy(lair),
		anchorPos = VecCopy(lair),
		alive = true, hp = maxHp, maxHp = maxHp, bodyLen = bLen, scale = scale, baby = isBaby and true or false,
		growthStage = 0, nextGrowT = (variant == "seismica") and (now() + SEIS_GROW_T) or 1e12,
		motherId = motherId or nil, variant = variant or "acidica",
		state = "lurk", t0 = now(), stateT = now(), wakeT = isBaby and (now() + 0.6) or (now() + SPAWN_GRACE),
		tempo = nil, tempoUntil = 0, twitchUntil = 0, twitchDir = nil,
		target = 0, known = nil, knownT = -100, aware = {},
		goal = nil, path = nil, pathI = 1, planT = -100, planGoal = nil, digs = nil,
		lungeCd = 0, spitCd = now() + 2.0, biteT = -100, stuckT = now(), stuckD = 1e9,
		circlePos = VecCopy(lair), circleT = now(),
		burnUntil = 0, burnTickT = 0, waterGoal = nil, waterSearchT = 0,
		nestBuilt = (isBaby or isMachina) and true or false, buildingNest = false, nestBuildStartT = 0, nestBuildStage = 0, nestTarget = nil,
		nestPos = isBaby and VecCopy(lair) or nil,
		motherNestPos = isBaby and VecCopy(lair) or nil,
		nestBody = 0, nestInitVox = 0, nestTier = 1, nestMaxHp = NEST_MAX_HP,
		hidingInNest = 0, visitingNest = false, nextNestVisit = isMachina and 1e12 or (now() + NEST_VISIT_MIN + math.random() * (NEST_VISIT_MAX - NEST_VISIT_MIN)),
		laidNest = (isBaby or isMachina) and true or false, returningToLay = false,
		hostileToHumans = false,
		grab = 0, grabT = 0, dmgInDrag = 0,
		mouth = 0, glow = 0.3, hurtT = -100, ev = {bite = 0, lunge = 0, hiss = 0, grab = 0, hurt = 0, die = 0, spit = 0},
		boxes = {}, deadT = 0, wanderT = 0, hits = {}, hitSeq = 0,
	}
	wormNextId = wormNextId + 1
	wormBoxesSpawn(w)
	return w
end

-- Ages a juvenile centipede into a full-size adult after 10 minutes (BABY_GROW_T = 600s)
function wormMatureToAdult(w)
	local motherNest = w.motherNestPos or w.nestPos or w.lair
	w.baby = false
	w.scale = 1.0
	w.growthStage = 0
	w.nextGrowT = (w.variant == "seismica") and (now() + SEIS_GROW_T) or 1e12
	w.bodyLen = BODY_LEN
	w.maxHp = HP
	w.hp = HP
	w.t0 = now()                -- Reset survival timer so as an adult it can lay eggs after 5 more minutes
	w.nestBuilt = false         -- Must first seek out its own nest spot far from its mother's nest before hunting
	w.buildingNest = false
	w.nestBuildStartT = 0
	w.nestBuildStage = 0
	w.nestSegs = nil
	w.nestSilkNodes = nil
	w.nestExtent = nil
	w.nestPos = nil
	w.nestBody = 0
	w.nestBodies, w.nestPieces, w.nestGrow = nil, nil, nil
	w.nestTarget = wormFindDarkNestSite(w, motherNest, ADULT_DISPERSE_MIN, ADULT_DISPERSE_MAX)
	w.nestStartT = now()
	w.goal = nil
	w.path = nil
	w.planGoal = nil
	w.visitingNest = false
	w.nextNestVisit = now() + NEST_VISIT_MIN + math.random() * (NEST_VISIT_MAX - NEST_VISIT_MIN)
	w.laidNest = false
	w.returningToLay = false
	w.ev.hiss = w.ev.hiss + 1
	wormBoxesDelete(w)
	wormBoxesSpawn(w)
end

----- hit boxes (server): invisible, flammable wood in WORM_LAYER, mask 0 -----

HIT_BOXES = 14                -- (9 boxes 1.8 m apart left 1.2 m gaps a weapon passed through)
HIT_SPACING = 1.15
MELEE_BASE = 10               -- a blow: this + MELEE_VOX per voxel it took out of the hit boxes, at most MELEE_MAX
MELEE_VOX = 0.3
MELEE_MAX = 40                -- (x 1.5 on the head; RELEASE_DMG 26 makes it let go, HP 160)

-- A hole in the hit boxes that is not its own bite or acid, a bullet, a blast, a sledge or fire (those are counted
-- where they happen) is a blow from some mod's weapon (they MakeHole where the weapon meets something): damage by
-- the voxels gone. Judged 0.15 s after it is seen, so a bullet's own event is in first. The boxes are made anew
-- after every hole of any kind (they used to stay eaten away).
function wormBoxesParkAll()
	for _, w in ipairs(wormList or {}) do
		for _, b in ipairs(w.boxes or {}) do
			if IsHandleValid(b) then
				SetBodyTransform(b, Transform(Vec(0, -500, 0)))
			end
		end
	end
end

function wormBoxesRestoreAll()
	for _, w in ipairs(wormList or {}) do
		if w.alive and w.boxPts then
			local pts = w.boxPts
			for i, b in ipairs(w.boxes or {}) do
				if IsHandleValid(b) then
					local k = (i - 1) * 3
					local p = pts[k + 1] and Vec(pts[k + 1], pts[k + 2], pts[k + 3]) or Vec(0, -500, 0)
					SetBodyTransform(b, Transform(p))
				end
			end
		end
	end
end

function wormSweepOrphanHitboxes()
	local active = {}
	for _, w in ipairs(wormList or {}) do
		for _, b in ipairs(w.boxes or {}) do
			active[b] = true
		end
	end
	for _, b in ipairs(FindBodies("silkmawhit", true) or {}) do
		if not active[b] and IsHandleValid(b) then
			for _, sh in ipairs(GetBodyShapes(b) or {}) do wormHitShapes[sh] = nil end
			Delete(b)
		end
	end
	for _, sh in ipairs(FindShapes("silkmawhitshape", true) or {}) do
		local sb = GetShapeBody(sh)
		if not active[sb] and IsHandleValid(sh) then
			wormHitShapes[sh] = nil
			Delete(sh)
		end
	end
end

function wormBoxesCheck(w)
	local t = now()
	if #w.boxes == 0 or t - (w.boxT or t) < 0.5 then return end
	if not w.boxFull then                                       -- (not in the spawn frame: the count can read 0 there)
		w.boxFull = {}
		for i, b in ipairs(w.boxes) do w.boxFull[i] = wormBodyVoxelCount(b) end
		return
	end
	local lost, at, head = 0, nil, false
	local nearFire = false
	for i, b in ipairs(w.boxes) do
		local l = w.boxFull[i] - wormBodyVoxelCount(b)
		if l > 0 then
			lost = lost + l
			local bp = GetBodyTransform(b).pos
			if not at then at, head = bp, i == 1 end
			if QueryClosestFire and QueryClosestFire(bp, 6.0) then nearFire = true end
		end
	end
	if lost <= 0 then w.boxLossT = nil; return end
	if not w.boxLossT then w.boxLossT = t; return end
	if t - w.boxLossT < 0.15 then return end
	local t0 = w.boxLossT - 0.3
	local isIgn = (w.variant == "ignitus" or w.variant == "machina")
	local counted = isIgn or (wormOwnHoleT or -1e9) > t0 or (w.evDmgT or -1e9) > t0 or t < (w.burnUntil or 0) + 4.0 or t < (w.fireImmuneUntil or 0) or nearFire
	w.boxLossT = nil
	wormBoxesDelete(w)
	wormBoxesSpawn(w)
	wormBoxesMove(w)
	if not counted then
		wormDamage(w, math.min(MELEE_MAX, MELEE_BASE + lost * MELEE_VOX) * (head and 1.5 or 1), "melee", at)
	end
end

function wormBoxesSpawn(w)
	w.boxes = {}
	w.boxT, w.boxFull, w.boxLossT = now(), nil, nil
	local sc = w.scale or (w.baby and BABY_SCALE or 1.0)
	local count = w.baby and 4 or HIT_BOXES
	for i = 1, count do
		local s = i == 1 and 8 or 6
		s = math.max(2, math.floor(s * sc + 0.5))
		-- (plaster: it does not burn, as the pack's rock did not, but other mods' weapons that cut voxels still cut it;
		--  bullets count through projectilehit events whatever the material, the creature's own holes park the boxes)
		local xml = string.format("<body tags='silkmawhit'><voxbox tags='invisible silkmawhitshape' material='plaster' pos='%.2f %.2f %.2f' size='%d %d %d' color='0 0 0'/></body>",
			-s * 0.05, -s * 0.05, -s * 0.05, s, s, s)
		local ents = Spawn(xml, Transform(Vec(0, -500, 0)))
		for _, e in ipairs(ents or {}) do
			if GetEntityType(e) == "body" then
				for _, sh in ipairs(GetBodyShapes(e)) do
					SetShapeCollisionFilter(sh, WORM_LAYER, 0)
					wormHitShapes[sh] = {w = w, head = i == 1}
				end
				w.boxes[#w.boxes + 1] = e
			end
		end
	end
end

function wormBoxesDelete(w)
	for _, b in ipairs(w.boxes) do
		if IsHandleValid(b) then
			for _, sh in ipairs(GetBodyShapes(b)) do wormHitShapes[sh] = nil end
			Delete(b)
		end
	end
	w.boxes = {}
end

function wormBoxesMove(w)
	local sc = w.scale or (w.baby and BABY_SCALE or 1.0)
	local sp = HIT_SPACING * sc
	local pts = wormSample(w, sp, sp * (#w.boxes - 1))
	for i, b in ipairs(w.boxes) do
		local k = (i - 1) * 3
		local p = pts[k + 1] and Vec(pts[k + 1], pts[k + 2], pts[k + 3]) or Vec(0, -500, 0)
		SetBodyTransform(b, Transform(p))
	end
	w.boxPts = pts
end

----- the registry API (any mod; PROJECT.md: Interfaces) -----

API_HIT_R = {0.6, 0.5}
API_DAMAGE_D = 1.5
API_DAMAGE_MAX = 32

function wormPublishHitpoints()
	local out, n = {}, 0
	for _, w in ipairs(wormList) do
		local pts = w.alive and w.boxPts
		if pts then
			for k = 1, math.min(#pts, #w.boxes * 3), 3 do
				n = n + 1
				local head = k == 1
				out[n] = string.format("%d %.2f %.2f %.2f %.2f %d;", w.id, pts[k], pts[k + 1], pts[k + 2],
					API_HIT_R[head and 1 or 2], head and 1 or 0)
			end
		end
	end
	local s = table.concat(out)
	if s ~= wormHitpointsLast then
		SetString("silkmaw.hitpoints", s)
		wormHitpointsLast = s
	end
end

local function finite(x) return x and x == x and x > -1e9 and x < 1e9 end

function wormTakeApiDamage()
	local q = GetString("silkmaw.damage")
	if q == "" then return end
	SetString("silkmaw.damage", "")
	local taken = 0
	for entry in string.gmatch(q, "[^;]+") do
		if taken >= API_DAMAGE_MAX then break end
		taken = taken + 1
		local x, y, z, a = string.match(entry, "^%s*(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s*$")
		x, y, z, a = tonumber(x), tonumber(y), tonumber(z), tonumber(a)
		if finite(x) and finite(y) and finite(z) and finite(a) and a > 0 then
			local p = Vec(x, y, z)
			local best, bestD = nil, API_DAMAGE_D
			for _, w in ipairs(wormList) do
				if w.alive then
					local pts = wormSample(w, 0.5, w.bodyLen or BODY_LEN)
					for k = 1, #pts, 3 do
						local d = dist(p, Vec(pts[k], pts[k + 1], pts[k + 2]))
						if d < bestD then best, bestD = w, d end
					end
				end
			end
			if best then wormDamage(best, math.min(a, HP), "api", p) end
		end
	end
end

----- damage & flammability (seeks water when burning) -----

HITS_KEPT = 6

function wormIgnite(w, dur)
	if not w or not w.alive or w.variant == "ignitus" or w.variant == "machina" or IsPointInWater(w.pos) then
		if w and (w.variant == "ignitus" or w.variant == "machina") then
			w.burnUntil = 0
			w.waterGoal = nil
		end
		return
	end
	local t = now()
	if t < (w.fireImmuneUntil or 0) or t < (w.burnUntil or 0) then return end
	w.burnUntil = t + (dur or BURN_DURATION)
	w.fireImmuneUntil = w.burnUntil + FIRE_IMMUNE_T             -- (fires around it don't light it again at once)
	if not wormIsWormTarget(w.target) then
		if w.grab ~= 0 then wormRelease(w) end
		w.waterGoal = wormFindWater(w.pos)
		w.waterSearchT = t + 2.5
		w.path = nil
		w.planGoal = nil
	end
end

function wormDamage(w, d, kind, point, attackerW)
	if not w.alive or d <= 0 then return end
	if (w.variant == "ignitus" or w.variant == "machina") and (kind == "fire" or kind == "burn") then return end
	-- If Clockwork Machina is attacked by a player or NPC (no attackerW), it turns hostile to players and NPCs and its cyan lighting turns red!
	if w.variant == "machina" and not attackerW and kind ~= "fire" and kind ~= "burn" then
		if not w.hostileToHumans then
			w.hostileToHumans = true
			w.ev.shriek = (w.ev.shriek or 0) + 1
			w.ev.hiss = (w.ev.hiss or 0) + 1
		end
	end
	if kind == "fire" then
		-- Fire damage on Acidica is non-lethal on its own (floors at BURN_MIN_HP_RATIO) and never causes recoil/trail loss
		local minHp = (w.maxHp or HP) * BURN_MIN_HP_RATIO
		if w.hp <= minHp then return end
		w.hp = math.max(minHp, w.hp - d)
		w.hurtT = now()
		return
	end
	if attackerW and attackerW.alive and attackerW ~= w and not w.baby then
		if w.grab ~= 0 then wormRelease(w) end
		w.target = "w:" .. tostring(attackerW.id)
		w.known = VecCopy(attackerW.pos)
		w.knownT = now()
		w.seeing = true
		if w.state ~= "windup" and w.state ~= "lunge" then wormSetState(w, "chase") end
	end
	local p = point or w.pos
	w.hidingInNest = 0
	w.hitSeq = w.hitSeq + 1
	local h = w.hits
	h[#h + 1] = w.hitSeq; h[#h + 1] = p[1]; h[#h + 1] = p[2]; h[#h + 1] = p[3]; h[#h + 1] = d
	while #h > HITS_KEPT * 5 do
		for _ = 1, 5 do table.remove(h, 1) end
	end
	w.ev.hurt = w.ev.hurt + 1
	w.hp = w.hp - d
	w.hurtT = now()
	if kind ~= "melee" then w.evDmgT = now() end                 -- (wormBoxesCheck: this hole is counted)
	if w.state == "drag" then w.dmgInDrag = w.dmgInDrag + d end
	if w.hp <= 0 then
		wormDie(w)
	elseif d >= 6 and w.state ~= "drag" and now() > (w.recoilCd or 0) then
		w.recoilCd = now() + 0.65
		local rec = wormIsWormTarget(w.target) and math.min(0.6, 0.2 + d * 0.015) or math.min(1.5, 0.4 + d * 0.04)
		wormRecoil(w, rec)
		if w.hp < (w.maxHp or HP) * 0.3 and w.state ~= "flee" and not wormIsWormTarget(w.target) then wormSetState(w, "flee") end
	end
end

-- Gold for the McPuppet Inventory System: a dead creature drops coins where it dies. Written to the Inventory's
-- inventory.dropgold ("x,y,z,amount" entries, space separated; it reads and clears the key every tick) on the host, only
-- when that mod is running (inventory.present). Nothing happens without it.
GOLD_DROP = {acidica = 300, ignitus = 350, machina = 400, juvenile = 30}
GOLD_SEISMICA = {200, 150}     -- 200 + 150 for each 1.0 of its size (300 small, up to 500 grown to double)

function wormGoldFor(w)
	if w.baby then return GOLD_DROP.juvenile end
	if w.variant == "seismica" then return math.floor(GOLD_SEISMICA[1] + GOLD_SEISMICA[2] * (w.scale or 1.0) + 0.5) end
	return GOLD_DROP[w.variant or "acidica"] or GOLD_DROP.acidica
end

function wormDropGold(w)
	if not GetBool("inventory.present") then return end
	local amount = wormGoldFor(w)
	if amount <= 0 then return end
	local p = VecAdd(w.pos, Vec(0, 0.3, 0))
	local s = GetString("inventory.dropgold")
	SetString("inventory.dropgold", (s == "" and "" or s .. " ") .. string.format("%.2f,%.2f,%.2f,%d", p[1], p[2], p[3], amount))
end

function wormDie(w)
	if w.grab ~= 0 then wormRelease(w) end
	w.alive = false
	w.state = "dead"
	w.deadT = now()
	w.burnUntil = 0
	w.ev.die = w.ev.die + 1
	wormDropGold(w)
	wormBoxesDelete(w)
	Nav.cancel(w.id)
end

function wormTakeFire(dt)
	local t = now()
	-- Check blowtorch usage by players
	for _, q in ipairs(GetAllPlayers()) do
		if GetPlayerTool(q) == "blowtorch" and InputDown("usetool", q) and GetPlayerHealth(q) > 0 then
			local eye = GetPlayerEyeTransform(q)
			local fwd = TransformToParentVec(eye, Vec(0, 0, -1))
			for _, w in ipairs(wormList) do
				if w.alive and w.variant ~= "ignitus" and w.variant ~= "machina" then
					local pts = wormSample(w, 1.2, w.bodyLen or BODY_LEN)
					for k = 1, #pts, 3 do
						local bp = Vec(pts[k], pts[k + 1], pts[k + 2])
						local to = VecSub(bp, eye.pos)
						local d = vlen(to)
						if d < 4.5 and VecDot(VecScale(to, 1 / math.max(0.01, d)), fwd) > 0.75 then
							wormIgnite(w, BURN_DURATION)
							break
						end
					end
				end
			end
		end
	end
	-- Check environment fires near each worm and process active burning + water-seeking
	for _, w in ipairs(wormList) do
		if w.alive and (w.variant == "ignitus" or w.variant == "machina") then
			w.burnUntil = 0
			w.waterGoal = nil
		elseif w.alive then
			-- Check if head or any body segment is in water to extinguish fire
			local inWater = IsPointInWater(w.pos)
			if not inWater and t < (w.burnUntil or 0) then
				local pts = wormSample(w, 2.0, w.bodyLen or BODY_LEN)
				for k = 1, #pts, 3 do
					if IsPointInWater(Vec(pts[k], pts[k + 1], pts[k + 2])) then
						inWater = true
						break
					end
				end
			end
			if inWater then
				w.burnUntil = 0
				w.waterGoal = nil
			else
				if QueryClosestFire and t > (w.fireCheckT or 0) and t >= (w.burnUntil or 0) and t >= (w.fireImmuneUntil or 0) then
					w.fireCheckT = t + 0.4
					local pts = wormSample(w, 2.0, w.bodyLen or BODY_LEN)
					for k = 1, #pts, 3 do
						local p = Vec(pts[k], pts[k + 1], pts[k + 2])
						if QueryClosestFire(p, 1.3) then
							wormIgnite(w, BURN_DURATION)
							break
						end
					end
				end
				if t < (w.burnUntil or 0) then
					wormDamage(w, BURN_DPS * dt, "fire", w.pos)
					if t > (w.waterSearchT or 0) then
						w.waterSearchT = t + 2.5
						w.waterGoal = wormFindWater(w.pos)
					end
					if t > (w.burnTickT or 0) then
						w.burnTickT = t + 1.2
						if math.random() < 0.2 then w.ev.hurt = w.ev.hurt + 1 end
					end
				elseif w.waterGoal then
					w.waterGoal = nil
				end
			end
		end
	end
end

function wormDamageNest(w, dmg, hitPos, holeR)
	if not w or not w.nestBuilt or not w.nestBody or w.nestBody == 0 or not IsHandleValid(w.nestBody) then return end
	w.nestHp = math.max(0, (w.nestHp or NEST_MAX_HP) - dmg)
	w.nestIntegT = nil
	if hitPos and holeR and holeR > 0 then
		MakeHole(hitPos, holeR, holeR * 0.85, 0, true)
	end
	-- If the centipede is lurking elsewhere and the nest took heavy damage (< 75% integrity), alert it to return
	if w.alive and w.state == "lurk" and wormNestIntegrity(w) < 0.75 then
		w.visitingNest = true
	end
end

function wormTakeHits()
	for i = 1, GetEventCount("projectilehit") do
		local shape, point = GetEvent("projectilehit", i)
		local h = wormHitShapes[shape]
		if h then
			wormDamage(h.w, h.head and 7 or 3, "bullet", point)
		elseif wormNestShapes and wormNestShapes[shape] then
			wormDamageNest(wormNestShapes[shape], 10.0, point, 0)
		end
	end
	for i = 1, GetEventCount("explosion") do
		local point, strength = GetEvent("explosion", i)
		strength = strength or 1
		for _, w in ipairs(wormList) do
			if w.alive then
				local pts = wormSample(w, 1.0, w.bodyLen or BODY_LEN)
				local best, bestP = 1e9, nil
				for k = 1, #pts, 3 do
					local q = Vec(pts[k], pts[k + 1], pts[k + 2])
					local d = dist(point, q)
					if d < best then best, bestP = d, q end
				end
				local r = 3.5 * strength
				if best < r then
					wormDamage(w, 70 * strength * (1 - best / r), "explosion", bestP)
					wormIgnite(w, BURN_DURATION)
				end
			end
			if w.nestBuilt and w.nestPos then
				local dn = dist(point, w.nestPos)
				local nr = 4.5 * strength
				if dn < nr then
					wormDamageNest(w, 110.0 * strength * (1 - dn / nr), point, 0.95 * strength)
				end
			end
		end
	end
	for _, q in ipairs(GetAllPlayers()) do                      -- sledge swings at the head or at a nest
		if GetPlayerTool(q) == "sledge" and InputPressed("usetool", q) and GetPlayerHealth(q) > 0 then
			local eye = GetPlayerEyeTransform(q)
			local fwd = TransformToParentVec(eye, Vec(0, 0, -1))
			for _, w in ipairs(wormList) do
				if w.alive then
					local v = VecSub(w.pos, eye.pos)
					local d = vlen(v)
					if d < 3 and VecDot(VecScale(v, 1 / math.max(d, 0.01)), fwd) > 0.6 then
						wormDamage(w, 10, "sledge", w.pos)
					end
				end
				if w.nestBuilt and w.nestPos and dist(eye.pos, w.nestPos) < 5.5 then
					local strikeP = VecAdd(eye.pos, VecScale(fwd, 2.0))
					if dist(strikeP, w.nestPos) < 3.8 then
						wormDamageNest(w, 60.0, strikeP, 0.55)
					end
				end
			end
		end
	end
end

----- vehicles driven into it -----

-- Nothing of a Silkmaw collides with a vehicle (its hit boxes collide with nothing, the body is drawn by the clients),
-- so a ram is worked out here: a vehicle faster than RAM_MIN whose box reaches a point of the body hurts it by
-- RAM_DMG per m/s, knocks it back along its trail and loses RAM_SLOW of its own speed. The same vehicle inside a
-- nest's silk takes RAM_NEST per m/s off the nest (the silk is hard masonry: no car breaks it by itself).
RAM_MIN = 4.0                 -- m/s (14 km/h)
RAM_DMG = 3.0                 -- damage per m/s: 30 at 36 km/h, 60 at 72 km/h (HP 160)
RAM_NEST = 8.0                -- nest damage per m/s: 80 at 36 km/h (NEST_MAX_HP 300; the car also breaks the plaster
                              -- silk itself. At 30 two rams at 30 km/h took the whole nest away: seen in game)
RAM_SLOW = 0.5                -- of its speed the vehicle keeps
RAM_CD = 0.6                  -- s between two rams of one vehicle

function wormTakeVehicles()
	local t = now()
	if t >= (wormVehT or 0) then
		wormVehT = t + 1.0
		wormVehicles = FindVehicles("", true) or {}
	end
	wormRamT = wormRamT or {}
	for _, v in ipairs(wormVehicles or {}) do
		local body = IsHandleValid(v) and GetVehicleBody(v) or 0
		if body ~= 0 and t >= (wormRamT[v] or 0) then
			local vel = GetBodyVelocity(body)
			local speed = vlen(vel)
			if speed >= RAM_MIN then
				local lo, hi = GetBodyBounds(body)
				local c = VecLerp(lo, hi, 0.5)
				local reach = math.min(4, 0.5 * math.max(hi[1] - lo[1], hi[3] - lo[3])) + 0.7
				local hit, nest = false, false
				for _, w in ipairs(wormList) do
					if w.alive then
						local pts = wormSample(w, 1.0, w.bodyLen or BODY_LEN)
						local best, bestP = 1e9, nil
						for k = 1, #pts, 3 do
							local q = Vec(pts[k], pts[k + 1], pts[k + 2])
							local d = dist(c, q)
							if d < best then best, bestP = d, q end
						end
						if best < reach then
							wormDamage(w, RAM_DMG * speed, "ram", bestP)
							if w.alive and w.state ~= "drag" then wormRecoil(w, math.min(3, speed * 0.15)) end
							hit = true
						end
					end
					if w.nestBuilt and w.nestPos and dist(c, w.nestPos) < NEST_RADIUS + reach - 0.7 then
						wormDamageNest(w, RAM_NEST * speed, nil, 0)
						nest = true
					end
				end
				if hit or nest then wormRamT[v] = t + RAM_CD end
				if hit then SetBodyVelocity(body, VecScale(vel, RAM_SLOW)) end   -- (the silk stops a car by itself)
			end
		end
	end
end

----- Acid Spit Spray -----

function wormSpitAcid(w, targetPos)
	if w.baby then return end
	w.spitCd = now() + SPIT_CD
	w.mouth = 1.0
	w.ev.spit = (w.ev.spit or 0) + 1
	w.ev.hiss = w.ev.hiss + 1
	local jaw = wormJaw(w)
	local to = VecSub(targetPos, jaw)
	local d = vlen(to)
	local aimDir = VecNormalize(VecAdd(to, Vec(0, math.min(2.5, d * 0.12), 0)))
	local right = VecNormalize(VecCross(aimDir, Vec(0, 1, 0)))
	if vlen(right) < 0.2 then right = Vec(1, 0, 0) end
	local up = VecNormalize(VecCross(right, aimDir))
	local isFire = (w.variant == "ignitus")
	local isShock = (w.variant == "machina")
	local isSeis = (w.variant == "seismica")
	local sc = w.scale or 1.0
	local count = isShock and 7 or (isSeis and 6 or SPIT_PELLETS)
	local volley = {hits = {}, fired = false}                  -- (shared by its pellets: hits per creature, one fire)
	for i = 1, count do
		local spreadR = isShock and (((i - 4) / 3) * 0.32) or ((math.random() - 0.5) * 0.28)
		local spreadU = isShock and ((math.random() - 0.5) * 0.08) or ((math.random() - 0.5) * 0.22)
		local pDir = VecNormalize(VecAdd(aimDir, VecAdd(VecScale(right, spreadR), VecScale(up, spreadU))))
		local spd = (isShock and (SPIT_SPEED * 1.25) or SPIT_SPEED) * (0.9 + math.random() * 0.2)
		local shockKind = (w.hostileToHumans and "shock_red" or "shock")
		wormAcids[#wormAcids + 1] = {
			pos = VecCopy(jaw),
			vel = VecScale(pDir, spd),
			t0 = now(),
			owner = w.id,
			scale = sc,
			volley = volley,
			kind = isSeis and "seismic" or (isShock and shockKind or (isFire and "fire" or "acid")),
		}
	end
end

-- a creature's body points for the pellets of this tick, made once per creature per tick (the pack traced every
-- other creature's whole body for every pellet, every tick)
local acidBodies, acidBodiesT = {}, -1
local function wormAcidBody(ow, t)
	if acidBodiesT ~= t then acidBodies, acidBodiesT = {}, t end
	local pts = acidBodies[ow]
	if not pts then
		pts = wormSample(ow, 1.0, ow.bodyLen or BODY_LEN)
		acidBodies[ow] = pts
	end
	return pts
end

function wormAcidTick(dt)
	local t = now()
	for i = #wormAcids, 1, -1 do
		local a = wormAcids[i]
		if t - a.t0 > 3.0 then
			table.remove(wormAcids, i)
		else
			a.vel = VecAdd(a.vel, Vec(0, -9.8 * dt, 0))
			local step = VecScale(a.vel, dt)
			local len = vlen(step)
			local hit, hitDist = false, len
			if len > 0.001 then
				wormFilter()
				hit, hitDist = QueryRaycast(a.pos, VecScale(step, 1 / len), len, 0.08)
			end
			local nextPos = hit and VecAdd(a.pos, VecScale(VecNormalize(step), hitDist)) or VecAdd(a.pos, step)
			local hitPlayer = false
			local ownerW = wormById(a.owner)
			local canHurtHumans = (a.kind ~= "shock" and a.kind ~= "shock_red") or (ownerW and ownerW.hostileToHumans)
			local hitR = (a.kind == "shock" or a.kind == "shock_red") and 1.85 or 1.15
			if canHurtHumans then
				for _, p in ipairs(GetAllPlayers()) do
					if GetPlayerHealth(p) > 0 then
						local pc = wormChest(p)
						local pf = GetPlayerTransform(p).pos
						if dist(nextPos, pc) < hitR or dist(nextPos, pf) < hitR then
							if a.kind == "shock" then
								SetPlayerHealth(math.max(0.0, GetPlayerHealth(p) - 0.16), p)
								local pushDir = VecNormalize(VecAdd(VecSub(pc, nextPos), Vec(0, 0.45, 0)))
								SetPlayerVelocity(VecAdd(GetPlayerVelocity(p), VecScale(pushDir, 7.5)), p)
							else
								SetPlayerHealth(math.max(0, GetPlayerHealth(p) - ACID_DMG), p)
							end
							hitPlayer = true
						end
					end
				end
				for _, v in ipairs(wormVlList) do                     -- villagers: as players
					if not wormVlCocoons[v.id] and (dist(nextPos, v.chest) < hitR or dist(nextPos, v.pos) < hitR) then
						if a.kind == "shock" or a.kind == "shock_red" then wormVlHurt(v.id, 0.16, ownerW, nextPos, 7.5)
						else wormVlHurt(v.id, ACID_DMG, ownerW, nextPos, 0) end
						hitPlayer = true
					end
				end
				for _, n in ipairs(wormNpcList) do
					if n.alive and dist(nextPos, n.pos) < hitR then
						if a.kind == "shock" then
							wormEcoHit(n.hid, 0.85, "shock", nextPos, VecNormalize(a.vel), "silkmaw_" .. tostring(a.owner or 1))
						else
							wormEcoHit(n.hid, 0.25, "bite", nextPos, VecNormalize(a.vel), "silkmaw_" .. tostring(a.owner or 1))
						end
						hitPlayer = true
					end
				end
			end
			-- Check impact against rival Silkmaws (balanced so Acidica and Ignitus have a fair shot at defeating Machina)
			local hitWorm = false
			local hitRW = (a.kind == "shock" or a.kind == "shock_red") and 1.85 or 1.45
			local hr2 = hitRW * hitRW
			local nx, ny, nz = nextPos[1], nextPos[2], nextPos[3]
			for _, ow in ipairs(wormList) do
				-- (only creatures whose body could reach the pellet: within its length of the head)
				if ow.alive and ow.id ~= a.owner and dist(nextPos, ow.pos) < (ow.bodyLen or BODY_LEN) + hitRW + 1 then
					local pts = wormAcidBody(ow, t)
					for k = 1, #pts, 3 do
						local dx, dy, dz = nx - pts[k], ny - pts[k + 1], nz - pts[k + 2]
						if dx * dx + dy * dy + dz * dz < hr2 then
							hitWorm = true
							local vh = a.volley and a.volley.hits or {}
							local hitsSoFar = vh[ow.id] or 0
							if hitsSoFar < 3 then
								vh[ow.id] = hitsSoFar + 1
								if a.kind == "fire" then
									if ow.variant == "machina" then
										-- Ignitus's molten fire spit superheats Machina's clockwork gears
										wormDamage(ow, 18.0, "bullet", nextPos, ownerW)
									elseif ow.variant ~= "ignitus" then
										wormDamage(ow, FIRE_PELLET_DMG, "bullet", nextPos, ownerW)
										wormIgnite(ow, BURN_DURATION)
									end
								elseif a.kind == "shock" or a.kind == "shock_red" then
									wormDamage(ow, 11.0, "shock", nextPos, ownerW)
								else
									-- Acidica's acid corrodes Machina's brass/iron mechanisms (22 dmg) and Ignitus's shell (ACID_WEAK_DMG)
									local acidDmg = (ow.variant == "ignitus" and ACID_WEAK_DMG) or (ow.variant == "machina" and 22.0) or 14.0
									wormDamage(ow, acidDmg, "acid", nextPos, ownerW)
								end
							end
							break
						end
					end
					if hitWorm then break end
				end
			end
			if hit or hitPlayer or hitWorm then
				if a.kind == "fire" then
					local farFromSelf = (not ownerW) or (dist(nextPos, ownerW.pos) > 2.6)
					if farFromSelf and not wormNearAnyNest(nextPos, 3.2) and not wormNearPod(nextPos, 2.5) then
						-- one fire per volley, where its first pellet lands (the pack lit 3 per pellet: up to 27 a
						-- volley every 3.8 s, and fire spreads - the host simulates it and every client gets the burn)
						local vol = a.volley
						if not vol or not vol.fired then
							if vol then vol.fired = true end
							SpawnFire(nextPos)
						end
						wormOwnHoleT = now()
						wormBoxesParkAll()
						MakeHole(nextPos, ACID_HOLE_R[1] * 0.65, ACID_HOLE_R[2] * 0.5, 0, true)
						wormBoxesRestoreAll()
						Nav.forget(nextPos, 1.2)
					end
				elseif a.kind == "seismic" then
					if not wormNearAnyNest(nextPos, 3.5) and not wormNearPod(nextPos, 2.8) then
						local sc = math.min(4.0, a.scale or 1.0)
						wormOwnHoleT = now()
						wormBoxesParkAll()
						MakeHole(nextPos, 0.85 * sc, 0.65 * sc, 0, true)
						wormBoxesRestoreAll()
						Nav.forget(nextPos, 2.0 * sc)
					end
				else
					if not wormNearAnyNest(nextPos, 3.2) and not wormNearPod(nextPos, 2.5) then
						wormOwnHoleT = now()
						wormBoxesParkAll()
						MakeHole(nextPos, ACID_HOLE_R[1], ACID_HOLE_R[2], 0, true)
						wormBoxesRestoreAll()
						Nav.forget(nextPos, 1.5)
					end
				end
				table.remove(wormAcids, i)
			else
				a.pos = nextPos
			end
		end
	end
end

----- Egg Laying Inside Silken Nest (after 5 min) & Juvenile Aging (after 10 min) -----

function wormLayEggsInNest(w)
	w.laidNest = true
	w.returningToLay = false
	w.ev.hiss = w.ev.hiss + 1
	for i = 1, EGG_COUNT do
		local silkP = wormPickSilkSurfacePos(w, 0.15, 1.85)
		local ep = VecAdd(silkP, Vec(0, 0.14, 0))
		local eggCol = (w.variant == "ignitus" and "0.95 0.35 0.1") or (w.variant == "seismica" and "0.95 0.72 0.18") or "0.25 0.85 0.3"
		local xml = string.format("<body tags='silkmawegg nocull' dynamic='false'><voxbox tags='nocull' material='foliage' pos='-0.15 -0.15 -0.15' size='3 4 3' color='%s'/></body>", eggCol)
		local ents = Spawn(xml, Transform(ep), true)
		local body = 0
		for _, e in ipairs(ents or {}) do
			if GetEntityType(e) == "body" then
				body = e
				SetTag(body, "nocull")
				SetBodyDynamic(body, false)
				for _, sh in ipairs(GetBodyShapes(e)) do
					SetTag(sh, "nocull")
					SetShapeCollisionFilter(sh, WORM_LAYER, 255 - WORM_LAYER)
					SetShapeEmissiveScale(sh, 1.2)
				end
			end
		end
		wormEggs[#wormEggs + 1] = {
			pos = ep,
			body = body,
			hatchAt = now() + EGG_HATCH_T + (i - 1) * 1.5,
			motherId = w.id,
			variant = w.variant or "acidica",
			alive = true,
		}
	end
end

-- Triggers a rebuild when the centipede returns to its nest and discovers it has been completely destroyed
function wormTriggerNestRebuild(w)
	local oldPos = w.nestPos and VecCopy(w.nestPos) or nil
	wormNestDeleteBodies(w)
	for i = #wormNests, 1, -1 do
		if wormNests[i].owner == w.id then table.remove(wormNests, i) end
	end
	w.nestBody = 0
	w.nestBodies, w.nestPieces, w.nestGrow = nil, nil, nil
	w.nestBuilt = false
	w.buildingNest = false
	w.nestBuildStartT = 0
	w.nestBuildStage = 0
	w.nestSegs = nil
	w.nestSilkNodes = nil
	w.nestExtent = nil
	w.nestPos = nil
	w.nestTr = nil
	w.visitingNest = false
	w.repairingNestUntil = 0
	w.hidingInNest = 0
	w.nestRetries = 0
	w.nestTarget = wormFindDarkNestSite(w, oldPos)
	w.nestStartT = now()
	w.path = nil
	w.planGoal = nil
	w.ev.hiss = w.ev.hiss + 1
end

function wormLifecycleTick()
	local t = now()
	if t < (wormLifeT or 0) then return end                     -- (4 times a second is plenty: timers of seconds)
	wormLifeT = t + 0.25
	for _, w in ipairs(wormList) do
		if w.alive then
			-- 1. Juvenile offspring age up into full adults after 10 minutes (BABY_GROW_T = 600s)
			if w.baby and (t - w.t0) >= BABY_GROW_T then
				wormMatureToAdult(w)
			end
			-- 1b. Seismica grows SEIS_GROW_STEP every SEIS_GROW_T s, up to 2x (SEIS_GROW_STAGES steps)
			if w.variant == "seismica" and (w.growthStage or 0) < SEIS_GROW_STAGES and t >= (w.nextGrowT or 0) then
				w.growthStage = (w.growthStage or 0) + 1
				w.nextGrowT = t + SEIS_GROW_T
				local baseSc = w.baby and BABY_SCALE or 1.0
				local baseLen = w.baby and BABY_BODY_LEN or BODY_LEN
				local mult = math.min(2.0, 1.0 + SEIS_GROW_STEP * w.growthStage)
				w.scale = baseSc * mult
				w.bodyLen = baseLen * mult
				local newMaxHp = HP * (w.baby and 0.25 or 1.0) * mult
				local hpRatio = (w.maxHp and w.maxHp > 0) and (w.hp / w.maxHp) or 1.0
				w.maxHp = newMaxHp
				w.hp = math.min(newMaxHp, math.max(w.hp, newMaxHp * hpRatio))
				w.ev.hiss = (w.ev.hiss or 0) + 1
				wormBoxesDelete(w)
				wormBoxesSpawn(w)
				wormBoxesMove(w)
			end
			-- 2. Periodic return to the silk nest, repairing damage, or rebuilding if completely destroyed
			if not w.baby and w.variant ~= "machina" and w.nestBuilt and w.nestPos then
				if (t >= (w.nextNestVisit or 0) or wormIsNestDamaged(w)) and w.state == "lurk" then
					w.visitingNest = true
				end
				local dNest = dist(w.pos, w.nestPos)
				if dNest < 4.5 then
					if not wormIsNestIntact(w) then
						wormTriggerNestRebuild(w)
					elseif wormIsNestDamaged(w) and dNest < 3.4 and t >= (w.repairingNestUntil or 0) then
						wormRepairSilkNest(w)
						if w.visitingNest then
							wormExpandSilkNest(w)
						end
						w.visitingNest = false
						w.hidingInNest = 0
						w.goal = nil
						w.nextNestVisit = t + NEST_VISIT_MIN + math.random() * (NEST_VISIT_MAX - NEST_VISIT_MIN)
					elseif w.visitingNest and dNest < 3.2 then
						wormExpandSilkNest(w)
						w.visitingNest = false
						w.hidingInNest = 0
						w.goal = nil
						w.nextNestVisit = t + NEST_VISIT_MIN + math.random() * (NEST_VISIT_MAX - NEST_VISIT_MIN)
					end
				end
			end
			-- 3. Adult centipedes that survive 5+ minutes return to their nest and lay eggs on the white silk
			if not w.baby and w.variant ~= "machina" and not w.laidNest and (t - w.t0) >= NEST_SURVIVE_T then
				if w.nestBuilt then
					w.returningToLay = true
					local nestP = w.nestPos or w.lair
					if dist(w.pos, nestP) < 3.8 then
						if not wormIsNestIntact(w) then
							wormTriggerNestRebuild(w)
						else
							if wormIsNestDamaged(w) then
								wormRepairSilkNest(w)
							end
							if dist(w.pos, nestP) < 2.8 then
								wormExpandSilkNest(w)
								wormLayEggsInNest(w)
								w.hidingInNest = 0
								w.goal = nil
								w.nextNestVisit = t + NEST_VISIT_MIN + math.random() * (NEST_VISIT_MAX - NEST_VISIT_MIN)
							end
						end
					end
				end
			end
		end
	end
	-- Update active eggs
	for i = #wormEggs, 1, -1 do
		local egg = wormEggs[i]
		if egg.body ~= 0 and IsHandleValid(egg.body) and not IsBodyBroken(egg.body) then
			if t >= egg.hatchAt then
				local p = VecAdd(egg.pos, Vec(0, 0.25, 0))
				local mId = egg.motherId
				Delete(egg.body)
				table.remove(wormEggs, i)
				local alive = 0
				for _, w in ipairs(wormList) do if w.alive then alive = alive + 1 end end
				if alive < WORM_MAX then
					local baby = wormNew(p, true, mId, egg.variant)
					wormList[#wormList + 1] = baby
				end
			end
		else
			if egg.body ~= 0 and IsHandleValid(egg.body) then Delete(egg.body) end
			table.remove(wormEggs, i)
		end
	end
	-- Clean up destroyed nests from the published list
	for i = #wormNests, 1, -1 do
		local n = wormNests[i]
		local vox, ok = wormNestBodiesState(n.bodies)
		if not ok or vox < (n.initVox or 100) * NEST_DESTROY_RATIO then
			table.remove(wormNests, i)
		else
			local ownerW = nil
			for _, w in ipairs(wormList) do if w.id == n.owner then ownerW = w; break end end
			n.repairing = (ownerW and ownerW.alive and (ownerW.buildingNest or t < (ownerW.repairingNestUntil or 0))) and true or false
		end
	end
end

----- the bite (breaks dirt, wood, foliage, glass, plaster, plastic, ice/snow) -----

-- Materials the centipede CAN break (explicitly including dirt/soil, foliage, wood, plaster, plastic, glass, ice)
BREAKABLE_MATS = {
	dirt = true, foliage = true, glass = true, wood = true,
	plastic = true, plaster = true, ice = true, snow = true, weakmetal = true,
}

-- Materials stronger than dirt/wood/plastic/glass/vegetation that the centipede cannot break
UNBREAKABLE_MATS = {
	rock = true, masonry = true, hardmasonry = true,
	metal = true, hardmetal = true, heavymetal = true, unphysical = true,
}

-- Returns true if a shape or its parent body is tagged unbreakable / map boundary
function wormShapeIsUnbreakableTag(shape)
	if not shape or shape == 0 then return false end
	if HasTag(shape, "unbreakable") or HasTag(shape, "boundary") or HasTag(shape, "silkmawnest") or HasTag(shape, "silkpod") then
		return true
	end
	local b = GetShapeBody and GetShapeBody(shape) or 0
	if b and b ~= 0 and (HasTag(b, "unbreakable") or HasTag(b, "boundary") or HasTag(b, "silkmawnest")) then
		return true
	end
	return false
end

-- Checks if there is breakable material (dirt, wood, foliage, plaster, glass, plastic) ahead
-- and rejects unbreakable map voxels/boundaries (rock, masonry, metal, or tagged unbreakable)
function wormCanBreakAt(pos, dir)
	local foundBreakable = false
	-- Cast a thin ray straight ahead first so we don't accidentally snag the floor/wall the worm is clinging to
	wormFilter()
	local hit, distHit, norm, shape = QueryRaycast(pos, dir, 2.3, 0.02)
	if hit and shape and shape ~= 0 then
		if wormShapeIsUnbreakableTag(shape) then
			return false, false
		end
		local hp = VecAdd(pos, VecScale(dir, distHit))
		local mat = GetShapeMaterialAtPosition(shape, hp)
		if mat == "dirt" or (mat and BREAKABLE_MATS[mat]) then
			return true, mat == "dirt"
		elseif mat and UNBREAKABLE_MATS[mat] then
			return false, false
		end
	end
	-- Sample points in the bite volume in case a breakable door/wall is right beside a frame
	local offsets = {
		VecScale(dir, 0.75),
		VecScale(dir, 1.35),
		VecAdd(VecScale(dir, 0.95), Vec(0, 0.35, 0)),
		VecAdd(VecScale(dir, 0.95), Vec(0, -0.35, 0)),
	}
	for _, off in ipairs(offsets) do
		wormFilter()
		local cpHit, cpPt, cpNorm, cpShape = QueryClosestPoint(VecAdd(pos, off), 0.75)
		if cpHit and cpShape and cpShape ~= 0 then
			if not wormShapeIsUnbreakableTag(cpShape) then
				local mat = GetShapeMaterialAtPosition(cpShape, cpPt)
				if mat == "dirt" then
					return true, true
				elseif mat and BREAKABLE_MATS[mat] then
					foundBreakable = true
				end
			end
		end
	end
	return foundBreakable, false
end

NIBBLE_R = {0.95, 0.6}        -- the bite near a nest (soft, medium): a way through for the body, no more
STUCK_BITE_N = 3              -- stuck checks in a row (STUCK_T apart) after which it bites whatever its state
STUCK_BACK_N = 6              -- ... after which it backs out STUCK_BACK m the way it came
STUCK_BACK = 4.0

function wormBite(w, dir)
	-- Juveniles cannot damage any blocks
	if w.baby then return false end
	if now() - w.biteT < BITE_CD then return false end
	local d = dir or w.fwd
	local p = VecAdd(w.pos, VecScale(d, 0.8))
	-- Near a nest: a nibble only (one small hole, just wide enough for the body; the nest mends its silk when the
	-- worm visits). It used to be no bite at all there - and no marking of hard walls, no backing out either: a
	-- Silkmaw wedged against a wall by its own nest had nothing left to try. Never into a cocoon.
	local nibble = wormNearAnyNest(w.pos, 3.6) or wormNearAnyNest(p, 3.6) or wormNearPod(p, 3.5)
	if nibble and wormNearPod(p, 1.8) then return false end
	w.biteT = now()
	w.mouth = 1
	w.ev.bite = w.ev.bite + 1
	local cut = 0
	local canBreak, isDirt = wormCanBreakAt(w.pos, d)
	if canBreak then
		local scale = w.baby and 0.65 or math.min(3.0, w.scale or 1.0)
		local softR = BITE_R[1] * scale * (isDirt and 1.22 or 1.0)
		local medR = BITE_R[2] * scale
		-- Third radius (hard materials: stone/rock/heavymetal) is 0; softR breaks dirt/foliage/glass/ice, medR breaks wood/plastic/plaster
		wormOwnHoleT = now()
		if nibble then softR, medR = NIBBLE_R[1], NIBBLE_R[2] end
		wormBoxesParkAll()
		cut = (MakeHole(p, softR, medR, 0, true) or 0)
		if not nibble then
			cut = cut + (MakeHole(VecAdd(p, VecScale(d, 0.95)), softR * 0.88, medR * 0.82, 0, true) or 0)
		end
		if isDirt and not nibble then
			cut = cut + (MakeHole(VecAdd(p, VecScale(d, 1.55)), softR * 0.75, medR * 0.5, 0, true) or 0)
		end
		wormBoxesRestoreAll()
		if cut > 0 then Nav.forget(p, 3.5) end
	end
	if cut < (nibble and 6 or HARD_BITE) and not wormClear(w.pos, VecAdd(p, VecScale(d, 1.0)), HEAD_R * 0.8) then
		Nav.markHard(VecAdd(p, VecScale(d, 0.5)), 1.4)
		wormRecoil(w, HARD_BACK)
		w.goal, w.path, w.planGoal = nil, nil, nil
		w.ev.hard = (w.ev.hard or 0) + 1
	end
	return true
end

function wormFloorBelow(p, dir)
	if dir then
		local canB, isDirt = wormCanBreakAt(p, dir)
		if canB and isDirt then return true end
	end
	wormFilter()
	local hit, d, norm, shape = QueryRaycast(p, Vec(0, -1, 0), 6, 0)
	if not hit then return false end
	if shape and shape ~= 0 then
		local mat = GetShapeMaterialAtPosition(shape, VecAdd(p, Vec(0, -d, 0)))
		if mat == "dirt" then return true end
	end
	for _, extra in ipairs({1.0, 2.0}) do
		local q = VecAdd(p, Vec(0, -(d + extra), 0))
		if wormFree(q, 0.6) then return true end
	end
	return false
end

----- Living Humans Mod Integration (Targeting, Dragging, Cocooning, Juvenile Feeding & Weapon Damage) -----

LH_REG = "level.livinghumans"
ECO_REG = "level.eco"
COCOON_FEED_CD = 3.5          -- s between juvenile feeding bites on a cocooned NPC
COCOON_FEED_GROW = 15.0       -- s of maturation time gained per juvenile feeding bite

function wormIsNpcTarget(tgt)
	return type(tgt) == "string" and string.sub(tgt, 1, 2) == "h:"
end

function wormNpcId(tgt)
	return string.sub(tgt, 3)
end

function wormIsWormTarget(tgt)
	return type(tgt) == "string" and string.sub(tgt, 1, 2) == "w:"
end

function wormById(id)
	local num = tonumber(id)
	for _, o in ipairs(wormList or {}) do
		if o.id == num then return o end
	end
	return nil
end

function wormNpcAlive(hid)
	if not hid or hid == "" then return false end
	local base = LH_REG .. "." .. hid
	if not HasKey(base .. ".status") then return false end
	return GetString(base .. ".status") ~= "dead"
end

-- True when the NPC exists in the level (either alive, unconscious, or dead with intact ragdoll bodies)
function wormNpcExists(hid)
	if not hid or hid == "" then return false end
	local base = LH_REG .. "." .. hid
	if not HasKey(base .. ".status") then return false end
	local anim = tonumber(hid)
	if anim and IsHandleValid(anim) then return true end
	return #wormNpcBodies(hid) > 0
end

-- Adults target both living and dead un-cocooned NPCs so dead NPCs are also dragged back to the nest and cocooned
function wormNpcTargetable(hid)
	if not wormNpcExists(hid) then return false end
	if wormGrabbed["h:" .. hid] or (wormCocoons and wormCocoons[hid]) then return false end
	return true
end

function wormNpcPos(hid)
	local base = LH_REG .. "." .. hid
	if HasKey(base .. ".x") then
		return Vec(GetFloat(base .. ".x"), GetFloat(base .. ".y"), GetFloat(base .. ".z"))
	end
	local anim = tonumber(hid)
	if anim and IsHandleValid(anim) then
		return VecAdd(GetAnimatorTransform(anim).pos, Vec(0, 1.0, 0))
	end
	return nil
end

function wormNpcBodies(hid)
	local out = {}
	local seen = {}
	local anim = tonumber(hid)
	if anim and IsHandleValid(anim) and GetBoneBody then
		local bones = {
			"pelvis", "stomach", "chest", "neck", "head",
			"shoulder_l", "arm_upper_l", "arm_lower_l", "hand_l",
			"shoulder_r", "arm_upper_r", "arm_lower_r", "hand_r",
			"leg_upper_l", "leg_lower_l", "foot_l", "toes_l",
			"leg_upper_r", "leg_lower_r", "foot_r", "toes_r",
		}
		for _, n in ipairs(bones) do
			local b = GetBoneBody(anim, n)
			if b and b ~= 0 and IsHandleValid(b) and not seen[b] then
				seen[b] = true
				out[#out + 1] = b
			end
		end
	end
	for _, b in ipairs(FindBodies("livinghuman", true) or {}) do
		if IsHandleValid(b) and GetTagValue(b, "livinghuman") == tostring(hid) and not seen[b] then
			seen[b] = true
			out[#out + 1] = b
		end
	end
	return out
end

function wormNpcVel(hid)
	local chestBody = GetInt(ECO_REG .. ".human_" .. hid .. ".body")
	if chestBody and chestBody ~= 0 and IsHandleValid(chestBody) then
		return GetBodyVelocity(chestBody)
	end
	return Vec(0, 0, 0)
end

function wormTargetValid(tgt)
	if not tgt or tgt == 0 then return false end
	if type(tgt) == "number" then
		return IsPlayerValid(tgt) and GetPlayerHealth(tgt) > 0
	elseif wormIsVlTarget(tgt) then
		return wormVlAlive(wormVlId(tgt))
	elseif wormIsNpcTarget(tgt) then
		return wormNpcExists(wormNpcId(tgt))
	elseif wormIsWormTarget(tgt) then
		local rw = wormById(string.sub(tgt, 3))
		return rw ~= nil and rw.alive
	end
	return false
end

function wormTargetPos(tgt)
	if type(tgt) == "number" then
		return wormChest(tgt)
	elseif wormIsVlTarget(tgt) then
		return wormVlChest(wormVlId(tgt))
	elseif wormIsNpcTarget(tgt) then
		return wormNpcPos(wormNpcId(tgt)) or Vec(0, 0, 0)
	elseif wormIsWormTarget(tgt) then
		local rw = wormById(string.sub(tgt, 3))
		return (rw and VecCopy(rw.pos)) or Vec(0, 0, 0)
	end
	return Vec(0, 0, 0)
end

-- Sends a bite or concussion hit to a Living Humans NPC via level.eco.human_<hid>.hits
function wormEcoHit(hid, dmg, kind, pos, dir, byUid)
	local uid = "human_" .. tostring(hid)
	local kBase = ECO_REG .. "." .. uid
	if not HasKey(kBase .. ".kind") then return end
	local n = GetInt(kBase .. ".hitN") + 1
	local base = kBase .. ".hits." .. (n % 8)
	local p = pos or wormNpcPos(hid) or Vec()
	local d = dir or Vec(0, 1, 0)
	SetFloat(base .. ".dmg", dmg or 0.15)
	SetString(base .. ".kind", kind or "bite")
	SetFloat(base .. ".x", p[1])
	SetFloat(base .. ".y", p[2])
	SetFloat(base .. ".z", p[3])
	SetFloat(base .. ".dx", d[1])
	SetFloat(base .. ".dy", d[2])
	SetFloat(base .. ".dz", d[3])
	SetString(base .. ".by", byUid or "silkmaw_1")
	SetInt(kBase .. ".hitN", n)
end

-- Publishes each living Abyssipede (and cocoon holder) into level.eco so Living Humans NPCs react, scream, flee, and fire at it
function wormEcoPublishTick()
	local t = now()
	if t < (wormEcoT or 0) then return end                      -- (10 times a second: Living Humans calls an entry
	wormEcoT = t + 0.1                                          -- stale after 3 s without a beat)
	local cKey = ECO_REG .. ".silkmaw_cocoon"
	SetString(cKey .. ".kind", "silkmaw_cocoon")
	SetString(cKey .. ".faction", "silkmaw")
	SetBool(cKey .. ".prey", false)
	SetBool(cKey .. ".alive", true)
	SetFloat(cKey .. ".threat", 0)
	SetBool(cKey .. ".hidden", true)
	SetInt(cKey .. ".beat", GetInt(cKey .. ".beat") + 1)

	for _, w in ipairs(wormList) do
		local uid = "silkmaw_" .. tostring(w.id)
		local k = ECO_REG .. "." .. uid
		if w.alive then
			local pubPos = VecAdd(w.pos, Vec(0, 0.35, 0))
			local isFriendlyMachina = (w.variant == "machina" and not w.hostileToHumans)
			local threat = isFriendlyMachina and 0.0 or (w.baby and 0.45 or ((w.state == "chase" or w.state == "lunge" or w.state == "windup" or w.state == "drag") and 1.0 or 0.92))
			SetString(k .. ".kind", isFriendlyMachina and "clockwork_ally" or "silkmaw")
			SetString(k .. ".faction", isFriendlyMachina and "human" or "silkmaw")
			SetBool(k .. ".prey", false)
			SetBool(k .. ".alive", true)
			SetFloat(k .. ".x", pubPos[1])
			SetFloat(k .. ".y", pubPos[2])
			SetFloat(k .. ".z", pubPos[3])
			SetFloat(k .. ".size", w.baby and 1.2 or 4.5)
			SetInt(k .. ".body", (w.boxes and w.boxes[1]) or 0)
			SetString(k .. ".status", w.state)
			SetFloat(k .. ".threat", threat)
			local hiding = w.state == "lurk" and now() < (w.hidingInNest or 0)
			SetBool(k .. ".hidden", hiding)                         -- (was `not hiding`: hidden while hunting, plain to see in its nest)
			SetInt(k .. ".beat", GetInt(k .. ".beat") + 1)
			for _, b in ipairs(w.boxes or {}) do
				if IsHandleValid(b) and GetTagValue(b, "eco") ~= uid then
					SetTag(b, "eco", uid)
				end
			end
		else
			ClearKey(k)
		end
	end
end

-- Reads Living Humans NPC gunshots (level.lhshot) and melee swings (level.lhswing) and routes hits to silkmaw.damage
function wormTakeNpcAttacks()
	local dmgEntries = {}
	local shotSeq = GetInt("level.lhshot.seq")
	local lastShot = wormLastLhShotSeq or shotSeq
	wormLastLhShotSeq = shotSeq
	if shotSeq > lastShot then
		for s = math.max(lastShot + 1, shotSeq - 63), shotSeq do
			local b = "level.lhshot." .. (s % 64)
			local ox, oy, oz = GetFloat(b .. ".ox"), GetFloat(b .. ".oy"), GetFloat(b .. ".oz")
			local dx, dy, dz = GetFloat(b .. ".dx"), GetFloat(b .. ".dy"), GetFloat(b .. ".dz")
			local wcls = GetString(b .. ".w")
			local r = math.max(GetFloat(b .. ".r"), 25)
			-- .hd: how far the shot got before it hit something (Living Humans' own ray): nothing behind a wall is hurt
			local hd = GetFloat(b .. ".hd")
			if hd > 0 then r = math.min(r, hd + 1.0) end
			local k = math.max(GetFloat(b .. ".k"), 1)
			local o = Vec(ox, oy, oz)
			local d = VecNormalize(Vec(dx, dy, dz))
			local baseDmg = (wcls == "rifle" and 22) or (wcls == "shotgun" and 18) or (wcls == "rocket" and 55) or 10
			baseDmg = baseDmg * k
			local bestW, bestPt, bestDist = nil, nil, 1e9
			for _, w in ipairs(wormList) do
				if w.alive then
					local pts = wormSample(w, 0.7, w.bodyLen or BODY_LEN)
					local hitR = w.baby and 0.45 or 0.95
					for idx = 1, #pts, 3 do
						local q = Vec(pts[idx], pts[idx + 1], pts[idx + 2])
						local v = VecSub(q, o)
						local along = VecDot(v, d)
						if along > 0 and along <= r then
							local perp = vlen(VecSub(v, VecScale(d, along)))
							if perp <= hitR and along < bestDist then
								bestDist = along
								bestW = w
								bestPt = q
							end
						end
					end
				end
			end
			if bestW and bestPt then
				dmgEntries[#dmgEntries + 1] = string.format("%.2f %.2f %.2f %.1f;", bestPt[1], bestPt[2], bestPt[3], baseDmg)
			end
		end
	end

	local swSeq = GetInt("level.lhswing.seq")
	local lastSw = wormLastLhSwingSeq or swSeq
	wormLastLhSwingSeq = swSeq
	if swSeq > lastSw then
		for s = math.max(lastSw + 1, swSeq - 15), swSeq do
			local b = "level.lhswing." .. (s % 16)
			local ox, oy, oz = GetFloat(b .. ".ox"), GetFloat(b .. ".oy"), GetFloat(b .. ".oz")
			local fx, fz = GetFloat(b .. ".fx"), GetFloat(b .. ".fz")
			local reach = math.max(GetFloat(b .. ".r"), 1.8) + 0.8
			local o = Vec(ox, oy + 0.9, oz)
			local f = VecNormalize(Vec(fx, 0, fz))
			for _, w in ipairs(wormList) do
				if w.alive then
					local pts = wormSample(w, 0.7, w.bodyLen or BODY_LEN)
					for idx = 1, #pts, 3 do
						local q = Vec(pts[idx], pts[idx + 1], pts[idx + 2])
						local to = VecSub(q, o)
						local distQ = vlen(to)
						if distQ <= reach and (distQ < 0.8 or VecDot(VecScale(to, 1 / distQ), f) > 0.25) then
							dmgEntries[#dmgEntries + 1] = string.format("%.2f %.2f %.2f %.1f;", q[1], q[2], q[3], 14.0)
							break
						end
					end
				end
			end
		end
	end

	if #dmgEntries > 0 then
		SetString("silkmaw.damage", GetString("silkmaw.damage") .. table.concat(dmgEntries))
	end
end

-- The cocoon's body (a pod of silk layers with anchor strands) at cocoonPos; hid seeds its shades
function wormCocoonBody(hid, cocoonPos, tall, variant)
	local seed = tonumber(hid) or 17
	local podMat = (variant == "ignitus") and "plaster" or "foliage"   -- (Ignitus: fireproof but breakable; rock was not)
	local cParts = {"<body tags='silkmawcocoon nocull' dynamic='false'>"}
	-- Build a rounded, tapered 8-layer organic silk cocoon pod using rotated overlapping octant layers
	local cLayers = {
		-- {y, hVox, spanVox, baseR, baseG, baseB}
		{-0.48, 2,  7, 0.79, 0.84, 0.77},
		{-0.32, 3,  9, 0.82, 0.87, 0.80},
		{-0.08, 3, 11, 0.86, 0.90, 0.84},
		{ 0.18, 4, 12, 0.89, 0.93, 0.87},
		{ 0.50, 3, 11, 0.91, 0.95, 0.89},
		{ 0.76, 3, 10, 0.93, 0.96, 0.91},
		{ 1.00, 2,  8, 0.95, 0.98, 0.94},
		{ 1.16, 2,  6, 0.97, 0.99, 0.96},
	}
	if tall then                                                -- (round a standing player: 2.5 m, clear of the head)
		cLayers = {
			{-0.48, 2,  7, 0.79, 0.84, 0.77},
			{-0.32, 3,  9, 0.82, 0.87, 0.80},
			{-0.08, 4, 11, 0.85, 0.89, 0.83},
			{ 0.28, 5, 12, 0.87, 0.91, 0.85},
			{ 0.74, 4, 12, 0.89, 0.93, 0.87},
			{ 1.10, 3, 11, 0.91, 0.95, 0.89},
			{ 1.36, 3, 10, 0.93, 0.96, 0.91},
			{ 1.62, 2,  8, 0.95, 0.98, 0.94},
			{ 1.80, 2,  6, 0.97, 0.99, 0.96},
		}
	end
	for lIdx, cl in ipairs(cLayers) do
		local y, hVox, sVox, br, bg, bb = cl[1], cl[2], cl[3], cl[4], cl[5], cl[6]
		local halfS = (sVox * 0.1) * 0.5
		for k = 1, 3 do
			local yawDeg = (k - 1) * 30.0 + lIdx * 11.0
			local yawRad = yawDeg / 57.29578
			local cosY, sinY = math.cos(yawRad), math.sin(yawRad)
			local ox = -(cosY * halfS + sinY * halfS)
			local oz = -(-sinY * halfS + cosY * halfS)
			local col = wormSilkShade(br, bg, bb, seed * 19 + lIdx * 7 + k, 0.032, variant)
			cParts[#cParts + 1] = string.format(
				"<voxbox tags='nocull silkpod' material='" .. podMat .. "' pos='%.3f %.3f %.3f' rot='0.0 %.1f 0.0' size='%d %d %d' color='%s'/>",
				ox, y, oz, yawDeg, sVox, hVox, sVox, col
			)
		end
	end
	-- Splayed organic silk anchor strands binding the cocoon base to the floor
	for i = 1, 4 do
		local a = (i / 4) * 6.283185 + 0.4
		wormAddOrganicTendril(
			cParts,
			math.sin(a) * 0.82, -0.48, math.cos(a) * 0.82,
			math.sin(a) * 0.48,  0.35, math.cos(a) * 0.48,
			-0.06, 2, 0.82, 0.87, 0.80, seed + i * 13, false, variant
		)
	end
	cParts[#cParts + 1] = "</body>"
	local xml = table.concat(cParts)
	local ents = Spawn(xml, Transform(cocoonPos), true)
	local cBody = 0
	for _, e in ipairs(ents or {}) do
		if GetEntityType(e) == "body" then
			cBody = e
			SetTag(cBody, "nocull")
			SetBodyDynamic(cBody, false)
			for _, sh in ipairs(GetBodyShapes(e)) do
				SetTag(sh, "nocull")
				SetTag(sh, "silkpod")                                  -- (the anchor strands too: wormPodSweep)
				if tall then SetTag(sh, "unbreakable") end             -- (a player's: only wormPlayerCocoonTick opens it)
				SetShapeCollisionFilter(sh, WORM_LAYER, 255 - WORM_LAYER)
				SetShapeEmissiveScale(sh, 0.16)
			end
		end
	end

	return cBody
end

-- Spawns a larger, tapered, multi-layered organic silken cocoon around a dragged Living Humans NPC (living or dead) at the nest
function wormCocoonNpc(w, hid, nestPos)
	if not wormNpcExists(hid) or not wormNpcAlive(hid) then return end   -- (a cocoon is for the living: it goes when they die)
	local silkP = wormPickSilkSurfacePos(w, 0.50, 3.60)
	local cocoonPos = VecAdd(silkP, Vec(0, 0.48, 0))
	wormFilter()
	local hitDown, dDown = QueryRaycast(VecAdd(silkP, Vec(0, 1.2, 0)), Vec(0, -1, 0), 4.0)
	if hitDown then
		cocoonPos = VecAdd(silkP, Vec(0, 1.2 - dDown + 0.48, 0))
	end

	local cBody = wormCocoonBody(hid, cocoonPos, false, w.variant)

	local bodies = wormNpcBodies(hid)
	local offsets = {}
	local chestPos = wormNpcPos(hid) or cocoonPos
	for _, b in ipairs(bodies) do
		local bt = GetBodyTransform(b)
		local rel = VecSub(bt.pos, chestPos)
		local len = vlen(rel)
		if len > 1.00 then rel = VecScale(rel, 1.00 / len) end
		offsets[b] = { pos = rel, rot = bt.rot }
	end

	SetString(ECO_REG .. ".human_" .. hid .. ".heldBy", "silkmaw_cocoon")
	SetBool(LH_REG .. "." .. hid .. ".cocooned", true)
	-- (wrapping someone up does them no harm: no hit here - 1.0.3 bit them for 0.35 as it spun the cocoon)

	wormCocoons[hid] = {
		hid = hid,
		pos = cocoonPos,
		body = cBody,
		bodies = bodies,
		offsets = offsets,
		lastSedateT = now(),
		nestOwner = w.id,
	}
end

-- What is left of a broken cocoon goes after COCOON_PIECE_T s: the shapes tagged silkpod that belong to no cocoon
-- in use (a cocoon's record is dropped the moment it breaks; the pieces broken off keep the tag).
COCOON_PIECE_T = 4

function wormPodSweep()
	local t = now()
	if t < (wormPodT or 0) then return end
	wormPodT = t + 1.0
	local live = {}
	for _, c in pairs(wormCocoons) do live[c.body] = true end
	for _, c in pairs(wormPlayerCocoons) do live[c.body] = true end
	for _, c in pairs(wormVlCocoons) do live[c.body] = true end
	local seen = {}
	wormPodOrphans = wormPodOrphans or {}
	for _, sh in ipairs(FindShapes("silkpod", true) or {}) do
		if not live[GetShapeBody(sh)] then
			seen[sh] = true
			local t0 = wormPodOrphans[sh]
			if not t0 then
				wormPodOrphans[sh] = t
			elseif t - t0 >= COCOON_PIECE_T then
				Delete(sh)
				wormPodOrphans[sh] = nil
			end
		end
	end
	for sh in pairs(wormPodOrphans) do
		if not seen[sh] then wormPodOrphans[sh] = nil end
	end
end

function wormCocoonTick(dt)
	for hid, c in pairs(wormCocoons) do
		local exists = wormNpcExists(hid)
		local alive = exists and wormNpcAlive(hid)
		local intact = c.body ~= 0 and IsHandleValid(c.body) and not IsBodyBroken(c.body)
		if not alive or not intact then
			if exists then
				SetString(ECO_REG .. ".human_" .. hid .. ".heldBy", "")
				SetBool(LH_REG .. "." .. hid .. ".cocooned", false)
			end
			-- (the person inside died, or is gone: the cocoon goes with them, and a body falls free)
			if c.body ~= 0 and IsHandleValid(c.body) and not alive then
				Delete(c.body)
			end
			wormCocoons[hid] = nil
		else
			SetString(ECO_REG .. ".human_" .. hid .. ".heldBy", "silkmaw_cocoon")
			SetBool(LH_REG .. "." .. hid .. ".cocooned", true)
			SetFloat(LH_REG .. "." .. hid .. ".x", c.pos[1])
			SetFloat(LH_REG .. "." .. hid .. ".y", c.pos[2])
			SetFloat(LH_REG .. "." .. hid .. ".z", c.pos[3])
			for _, b in ipairs(c.bodies or {}) do
				if IsHandleValid(b) then
					local off = c.offsets and c.offsets[b]
					local targetP = off and VecAdd(c.pos, off.pos) or c.pos
					local targetR = off and off.rot or Quat()
					SetBodyTransform(b, Transform(targetP, targetR))
					SetBodyVelocity(b, Vec(0, 0, 0))
					SetBodyAngularVelocity(b, Vec(0, 0, 0))
				end
			end
		end
	end
end

-- The Living Humans NPCs, listed once every NPC_SCAN_DT for every worm (each juvenile used to read them all from
-- the registry four times a frame, each acid droplet once a frame): wormNpcList = {{hid, pos, alive}, ...} for
-- every NPC that exists (alive, unconscious or a corpse), wormNpcKnown[hid] the same by id.
NPC_SCAN_DT = 0.1

function wormNpcScan()
	local t = now()
	if t < (wormNpcScanT or 0) then return end
	wormNpcScanT = t + NPC_SCAN_DT
	local list, known = {}, {}
	local owners = nil
	for _, hid in ipairs(ListKeys(LH_REG) or {}) do
		local anim = tonumber(hid)
		local base = LH_REG .. "." .. hid
		if anim and HasKey(base .. ".status") then
			local exists = IsHandleValid(anim)
			if not exists then                                       -- (no animator left: any of its bodies still there?)
				if not owners then
					owners = {}
					for _, b in ipairs(FindBodies("livinghuman", true) or {}) do owners[GetTagValue(b, "livinghuman")] = true end
				end
				exists = owners[tostring(hid)] == true
			end
			local pos = exists and wormNpcPos(hid)
			if pos then
				local n = {hid = hid, pos = pos, alive = GetString(base .. ".status") ~= "dead"}
				list[#list + 1] = n
				known[hid] = n
			end
		end
	end
	wormNpcList, wormNpcKnown = list, known
end

-- a listed NPC no worm holds and that is not in a cocoon
function wormNpcFree(n)
	return not wormGrabbed["h:" .. n.hid] and not (wormCocoons and wormCocoons[n.hid])
end

-- Finds the closest cocooned NPC (living or dead) OR un-cocooned dead NPC near `pos` for juveniles to feed on
function wormFindCocoonNear(pos, maxD)
	local best, bestD = nil, maxD or 12.0
	for _, c in pairs(wormCocoons or {}) do
		if wormNpcKnown[c.hid] then
			local d = dist(pos, c.pos)
			if d < bestD then
				best, bestD = {hid = c.hid, pos = c.pos, cocoon = true}, d
			end
		end
	end
	for _, n in ipairs(wormNpcList) do
		if not n.alive and not (wormCocoons and wormCocoons[n.hid]) then
			local d = dist(pos, n.pos)
			if d < bestD then
				best, bestD = {hid = n.hid, pos = n.pos, cocoon = false}, d
			end
		end
	end
	return best
end

-- Finds a nearby living NPC for a juvenile centipede to bite
function wormFindNearbyLivingNpc(pos, maxD)
	local bestHid, bestPos, bestD = nil, nil, maxD or BABY_NPC_CHASE_R
	for _, n in ipairs(wormNpcList) do
		if n.alive and not (wormCocoons and wormCocoons[n.hid]) then
			local d = dist(pos, n.pos)
			if d < bestD then
				bestHid, bestPos, bestD = n.hid, n.pos, d
			end
		end
	end
	return bestHid, bestPos, bestD
end

----- players in cocoons -----

-- A player dragged all the way to the nest is spun into a cocoon alive (they used to die there): held inside it,
-- unable to move or use tools, their health running down to nothing over COCOON_TIME s, until someone breaks the cocoon
-- (bullets and blasts break its voxels; a sledge swing at it by another player) or they die. Worms ignore them
-- meanwhile (wormGrabbed). Published to the clients in shared.worms.pc = {player, x, y, z, seconds left, ...} for the view.
COCOON_TIME = 30              -- s a cocooned player lives unless someone cuts them out (the user, 2026-11-11)
COCOON_CUT_R = 2.6            -- m from a rescuer's eyes to the cocoon's middle for E to cut the one inside free

-- true when player q is close to the cocoon whose middle is mid and looking at it (server and clients alike)
function wormCanCut(q, mid)
	local eye = GetPlayerEyeTransform(q)
	local v = VecSub(mid, eye.pos)
	local d = VecLength(v)
	return d < COCOON_CUT_R and VecDot(VecScale(v, 1 / math.max(d, 0.01)), TransformToParentVec(eye, Vec(0, 0, -1))) > 0.55
end
COCOON_FREE_T = 5             -- s the Silkmaws leave a player alone whose cocoon broke (wormGrabbed[p] stays set, as
                              -- true: without it the one at the nest grabbed them again at once, cocoon after cocoon)

-- a cocoon in use within r of p (the Silkmaw's own bites and acid make no holes there)
function wormNearPod(p, r)
	for _, c in pairs(wormPlayerCocoons or {}) do
		if VecLength(VecSub(c.pos, p)) < r then return true end
	end
	for _, c in pairs(wormCocoons or {}) do
		if VecLength(VecSub(c.pos, p)) < r then return true end
	end
	return false
end

function wormCocoonPlayer(w, p)
	local silkP = wormPickSilkSurfacePos(w, 0.50, 3.60)
	local pos = VecAdd(silkP, Vec(0, 0.48, 0))
	wormFilter()
	local hitDown, dDown = QueryRaycast(VecAdd(silkP, Vec(0, 1.2, 0)), Vec(0, -1, 0), 4.0)
	if hitDown then pos = VecAdd(silkP, Vec(0, 1.2 - dDown + 0.48, 0)) end
	wormPlayerCocoons[p] = {body = wormCocoonBody("p" .. tostring(p), pos, true, w.variant), pos = pos, t0 = GetTime(), h0 = GetPlayerHealth(p), variant = w.variant or "acidica"}
	wormGrabbed[p] = w
	w.ev.hiss = w.ev.hiss + 1
end

function wormPlayerCocoonTick(dt)
	for p, t in pairs(wormFreed) do                             -- the time after a broken cocoon is over
		if GetTime() >= t then
			wormFreed[p] = nil
			if not wormPlayerCocoons[p] and wormGrabbed[p] == true then wormGrabbed[p] = nil end
		end
	end
	for p, c in pairs(wormPlayerCocoons) do
		local ok = IsPlayerValid(p) and GetPlayerHealth(p) > 0
		local intact = c.body ~= 0 and IsHandleValid(c.body) and not IsBodyBroken(c.body)
		local mid = VecAdd(c.pos, Vec(0, 0.4, 0))
		if ok and intact then
			-- (the cocoon is unbreakable: whatever the one inside does with whatever mod's attack, nothing happens.
			--  Another player close by and looking at it cuts them free with E)
			for _, q in ipairs(GetAllPlayers()) do
				if q ~= p and not wormPlayerCocoons[q] and GetPlayerHealth(q) > 0 and InputPressed("interact", q)
					and wormCanCut(q, mid) then
					c.cut = true
				end
			end
			if c.cut then
				for _, sh in ipairs(GetBodyShapes(c.body) or {}) do RemoveTag(sh, "unbreakable") end
				wormOwnHoleT = now()                                   -- (not a blow on a Silkmaw beside it)
				MakeHole(mid, 0.9, 0.9, 0.5, true)
				intact = false
			end
		end
		if not ok or not intact then
			wormPlayerCocoons[p] = nil
			wormGrabbed[p] = nil
			if ok then                                               -- broken open: free, and left alone for a while
				wormGrabbed[p] = true
				wormFreed[p] = GetTime() + COCOON_FREE_T
			end
			if not ok and c.body ~= 0 and IsHandleValid(c.body) then Delete(c.body) end
		else
			SetPlayerTransform(Transform(VecAdd(c.pos, Vec(0, -0.4, 0)), GetPlayerTransform(p).rot), p)
			SetPlayerVelocity(Vec(0, 0, 0), p)
			SetPlayerHealth(c.h0 * math.max(0, 1 - (GetTime() - c.t0) / COCOON_TIME), p)
			if GetPlayerTool(p) ~= "none" then SetPlayerTool("none", p) end
			ReleasePlayerGrab(p)
			DisablePlayerInput(p)                              -- (their own attack broke the cocoon from inside)
		end
	end
end

----- grab and drag (Players and Living Humans NPCs) -----

function wormGrab(w, tgt)
	w.grab = tgt
	w.grabT = now()
	w.dmgInDrag = 0
	w.ev.grab = w.ev.grab + 1
	w.mouth = 0.35
	wormGrabbed[tgt] = w
	if wormIsNpcTarget(tgt) then
		local hid = wormNpcId(tgt)
		SetString(ECO_REG .. ".human_" .. hid .. ".heldBy", "silkmaw_" .. tostring(w.id))
		w.grabBodies = wormNpcBodies(hid)
		local chestP = wormNpcPos(hid) or wormJaw(w)
		w.grabOffsets = {}
		for _, b in ipairs(w.grabBodies) do
			if IsHandleValid(b) then
				local bt = GetBodyTransform(b)
				local rel = VecSub(bt.pos, chestP)
				local len = vlen(rel)
				if len > 0.9 then rel = VecScale(rel, 0.9 / len) end
				w.grabOffsets[b] = { pos = rel, rot = bt.rot }
			end
		end
		wormEcoHit(hid, 0.22, "bite", wormJaw(w), w.fwd, "silkmaw_" .. tostring(w.id))
	end
	wormSetState(w, "drag")
end

function wormRelease(w)
	if w.grab ~= 0 then
		if wormIsVlTarget(w.grab) and not wormVlCocoons[wormVlId(w.grab)] then wormVlDrop(wormVlId(w.grab)) end
		if wormIsNpcTarget(w.grab) then
			local hid = wormNpcId(w.grab)
			if not (wormCocoons and wormCocoons[hid]) then
				SetString(ECO_REG .. ".human_" .. hid .. ".heldBy", "")
			end
		end
		wormGrabbed[w.grab] = nil
	end
	w.grab = 0
	w.grabBodies = nil
	w.grabOffsets = nil
	w.mouth = 1
	w.lungeCd = now() + 3
	wormRecoil(w, 2)
end

function wormJaw(w)
	local sc = w.scale or (w.baby and BABY_SCALE or 1.0)
	return VecAdd(w.pos, VecScale(w.fwd, 0.55 * sc))
end

----- states -----

function wormSetState(w, s)
	if w.state == s then return end
	if (s == "chase" and w.state ~= "windup" and w.state ~= "lunge") then w.ev.hiss = w.ev.hiss + 1 end
	w.state = s
	w.stateT = now()
	w.tempoUntil = 0
	w.path = nil
	w.planGoal = nil
end

-- how strongly it wants prey at c moving at speed (a player or a Living Humans person alike): felt within NEAR_SENSE,
-- moving within MOVE_SENSE, seen within DARK_SIGHT (or LIGHT_SENSE with a lit flashlight) with nothing in between;
-- nearer counts a little more
PREY_MOVING = 1.5             -- m/s: moving about (felt from MOVE_SENSE)

function wormPreyScore(w, c, speed, lit)
	local d = dist(c, w.pos)
	local s = 0
	if d < NEAR_SENSE then s = 3 end
	if d < MOVE_SENSE and speed > PREY_MOVING then s = math.max(s, 2.5) end
	if s < 3 and (d < DARK_SIGHT or (lit and d < LIGHT_SENSE)) and wormClear(w.pos, c, 0.05) then s = 3 end
	if s > 0 then s = s + 1 / (1 + d) end
	return s
end

function wormSense(w)
	if now() < (w.wakeT or 0) then return end
	-- Juveniles do not target players or free NPCs (they stay near their nest for 10 min and feed on cocooned NPCs),
	-- and adults only hunt after building their nest
	if w.baby or not w.nestBuilt then
		w.target = 0
		w.seeing = false
		if w.state ~= "lurk" and w.state ~= "flee" then
			wormSetState(w, "lurk")
		end
		return
	end
	-- prey that another worm holds, or that sits in a cocoon, is not prey: give it up (it is sensed again like
	-- anyone else once it is free)
	local tg = w.target
	if tg and tg ~= 0 and w.grab ~= tg and (wormGrabbed[tg] or (wormIsNpcTarget(tg) and not wormNpcTargetable(wormNpcId(tg)))) then
		w.target, w.seeing = 0, false
		w.knownT = -1e9
		if w.state == "chase" or w.state == "stalk" or w.state == "windup" or w.state == "lunge" then wormSetState(w, "lurk") end
	end
	local best, bestS = 0, 0
	local huntsHumans = (w.variant ~= "machina") or w.hostileToHumans
	if huntsHumans then
		local vol, spos
		local heard = wormHeard
		vol, spos = heard and heard.vol, heard and heard.pos
		local own = false
		if vol and spos then
			for _, o in ipairs(wormList) do if o.alive and dist(spos, o.pos) < 4 then own = true end end
		end
		if vol and vol > 0.03 and spos and not own then
			local d = dist(spos, w.pos)
			if d < vol * HEAR_K then
				w.known = VecCopy(spos)
				w.knownT = now()
				if w.state == "lurk" and w.nestBuilt and not w.returningToLay then wormSetState(w, "stalk") end
			end
		end
		-- Players and Living Humans people are scored the same way (wormPreyScore): the same distance, movement and
		-- sight count the same for both. A lit flashlight lets it see a player from farther (LIGHT_SENSE), but no
		-- higher score than seeing someone (the pack gave a lit player 4 to everyone else's 3: players were always
		-- chosen over people)
		for _, p in ipairs(GetAllPlayers()) do
			if GetPlayerHealth(p) > 0 and not wormGrabbed[p] then
				local fl = GetFlashlight(p)
				local s = wormPreyScore(w, wormChest(p), vlen(GetPlayerVelocity(p)), fl ~= 0 and IsLightActive(fl))
				if s > bestS then best, bestS = p, s end
			end
		end
		for _, v in ipairs(wormVlList) do                          -- villagers: the same rule (they carry no flashlight)
			if wormVlFree(v) then
				local s = wormPreyScore(w, v.chest, v.speed, false)
				if s > bestS then best, bestS = "v:" .. v.id, s end
				if v.noise > 0 and dist(v.chest, w.pos) < v.noise * VL_NOISE_VOL * HEAR_K then   -- (heard, as a sound)
					w.known = VecCopy(v.chest)
					w.knownT = now()
					if w.state == "lurk" and w.nestBuilt and not w.returningToLay then wormSetState(w, "stalk") end
				end
			end
		end
		-- Sense Living Humans NPCs (both living NPCs to hunt and dead NPCs to drag back & cocoon)
		for _, n in ipairs(wormNpcList) do
			local hid = n.hid
			if wormNpcFree(n) then
				local c = n.pos
				if c then
					local d = dist(c, w.pos)
					local s = 0
					if n.alive then s = wormPreyScore(w, c, vlen(wormNpcVel(hid)), false) end
					-- (the dead are not fetched any more: a cocoon goes when the one inside dies, so a body carried home
					--  would fall out again and be fetched again; juveniles still feed on bodies they come across)
					if s > bestS then best, bestS = "h:" .. hid, s end
				end
			end
		end
	end
	-- Territorial Rivalry between Silkmaw (Acidica) and Silkmaw (Ignitus):
	-- If already locked in a fight to the death with a rival, stay locked until one dies!
	if wormIsWormTarget(w.target) and wormTargetValid(w.target) then
		local rw = wormById(string.sub(w.target, 3))
		if rw and rw.alive then
			w.known = VecCopy(rw.pos)
			w.knownT = now()
			w.seeing = true
			if w.state ~= "chase" and w.state ~= "windup" and w.state ~= "lunge" then
				wormSetState(w, "chase")
			end
			return
		end
	end
	-- Check for rival Silkmaws:
	-- Clockwork Machina is a dedicated Silkmaw hunter that actively tracks and hunts all non-machina Silkmaws across the map (up to 90m).
	-- Biological Silkmaws (Acidica & Ignitus) engage Machina within 28m (or immediately when targeted) so they fight back on equal footing!
	local fightRival, fightDist = nil, 1e9
	for _, rw in ipairs(wormList) do
		if rw ~= w and rw.alive and (rw.variant or "acidica") ~= (w.variant or "acidica") then
			local rd = dist(w.pos, rw.pos)
			if w.variant == "machina" then
				if rd < 90.0 and rd < fightDist then
					fightRival, fightDist = rw, rd
				end
			elseif not rw.baby then
				local nearMyNest = w.nestPos and dist(rw.pos, w.nestPos) < ((w.nestExtent or NEST_RADIUS) + 8.0)
				local rivalTargetingMe = (rw.target == "w:" .. tostring(w.id))
				local engageR = (rw.variant == "machina") and 28.0 or RIVAL_FIGHT_R
				if (rd < engageR or nearMyNest or rivalTargetingMe) and rd < fightDist then
					fightRival, fightDist = rw, rd
				end
			end
		end
	end
	if fightRival then
		best = "w:" .. tostring(fightRival.id)
		bestS = 10.0
	end
	if best ~= 0 then
		w.target = best
		w.known = wormTargetPos(best)
		w.knownT = now()
		local busyNesting = w.returningToLay
		if not busyNesting or dist(w.known, w.pos) < 9.0 then
			w.hidingInNest = 0
			if bestS >= 2.5 and (w.state == "lurk" or w.state == "stalk") then
				wormSetState(w, "chase")
			elseif w.state == "lurk" then
				wormSetState(w, "stalk")
			end
		end
		w.seeing = bestS >= 3
	else
		w.seeing = false
		if (w.state == "chase" or w.state == "stalk") and now() - w.knownT > FORGET_T then
			wormSetState(w, "lurk")
		elseif w.state == "chase" and now() - w.knownT > 4.0 then
			wormSetState(w, "stalk")
		end
	end
end

-- a goal it may wander to: free and attached to a physical surface
function wormGoalOk(g)
	local ok, rep = Nav.free(g)
	if not ok then return false end
	return wormSurface(rep or g, SURF_R)
end

-- a lurk goal: juveniles stay within BABY_NEST_RADIUS of their nest (biting nearby living NPCs and feeding on dead/cocooned NPCs);
-- adults occasionally hide in their nest or prowl toward players/NPCs (exact v12 exploration logic)
function wormWanderGoal(w)
	local home = w.nestPos or w.motherNestPos or w.lair
	if w.baby then
		local npcHid, npcPos = wormFindNearbyLivingNpc(w.pos, BABY_NPC_CHASE_R)
		if npcPos and dist(npcPos, home) <= BABY_NEST_RADIUS + 5.0 then
			return VecCopy(npcPos)
		end
		local food = wormFindCocoonNear(home, BABY_NEST_RADIUS + 6.0)
		if food and math.random() < 0.75 then
			return VecCopy(food.pos)
		end
		if dist(w.pos, home) > BABY_NEST_RADIUS or math.random() < 0.42 then
			return VecCopy(home)
		end
		for _ = 1, 10 do
			local ang = math.random() * 6.283
			local r = 1.0 + math.random() * (BABY_NEST_RADIUS - 1.0)
			local g = VecAdd(home, Vec(math.cos(ang) * r, (math.random() - 0.5) * 2.5, math.sin(ang) * r))
			if wormGoalOk(g) then return g end
		end
		return VecCopy(home)
	end
	-- Natural, wide-ranging exploration across the map when no prey is detected:
	local angBase = w.exploreAng or (math.random() * 6.283)
	-- Strongly bias exploration away from its own nest when within 35m so it ventures far across the map
	if home and dist(w.pos, home) < 35.0 then
		angBase = math.atan2(w.pos[3] - home[3], w.pos[1] - home[1]) + (math.random() - 0.5) * 1.1
	end
	for _, rw in ipairs(wormList) do
		if rw ~= w and rw.alive and (rw.variant or "acidica") ~= (w.variant or "acidica") then
			local rd = dist(w.pos, rw.pos)
			if w.variant == "machina" then
				-- Machina prowls toward the nearest biological Silkmaw on the map
				angBase = math.atan2(rw.pos[3] - w.pos[3], rw.pos[1] - w.pos[1]) + (math.random() - 0.5) * 0.45
				break
			elseif not rw.baby and rw.variant ~= "machina" and rd < RIVAL_AVOID_R * 1.25 then
				angBase = math.atan2(w.pos[3] - rw.pos[3], w.pos[1] - rw.pos[1]) + (math.random() - 0.5) * 0.9
				break
			end
		end
	end
	w.exploreAng = angBase + (math.random() - 0.5) * 0.85

	-- Pass 1: Long-range exploration through available open tunnels/corridors and across the map (18m to 60m)
	for attempt = 1, 24 do
		local ang = (attempt <= 10) and (w.exploreAng + (math.random() - 0.5) * 0.9) or (math.random() * 6.283)
		local stepDist = 18.0 + math.random() * 42.0
		local dy = (math.random() - 0.48) * 5.0
		local dir = VecNormalize(Vec(math.cos(ang), dy / stepDist, math.sin(ang)))
		wormFilter()
		local hit, hd, _, hitShape = QueryRaycast(VecAdd(w.pos, Vec(0, 0.4, 0)), dir, stepDist)
		-- In tunnels: if a ray hits a wall close by (< 6.5m), skip that direction so we pick goals down open passages!
		if not (hit and hd < 6.5 and attempt <= 18) then
			local g = hit and VecAdd(w.pos, VecScale(dir, math.max(4.5, hd - 1.2))) or VecAdd(w.pos, VecScale(dir, stepDist))
			local ok, rep = Nav.free(g)
			local cand = (ok and rep) or g
		local farFromNest = (not home) or (dist(cand, home) > math.min(28.0, dist(w.pos, home) + 6.0))
		if ok and wormSurface(cand, SURF_R) and dist(cand, w.pos) > 8.0 and (farFromNest or attempt > 14) then
			local nearFire = (w.variant ~= "ignitus" and w.variant ~= "machina" and QueryClosestFire and QueryClosestFire(cand, 4.5)) or false
			local rivalBad = false
			if w.variant ~= "machina" then
				for _, rw in ipairs(wormList) do
					if rw ~= w and rw.alive and not rw.baby and rw.variant ~= "machina" and (rw.variant or "acidica") ~= (w.variant or "acidica") then
						local curRD = dist(w.pos, rw.pos)
						local nxtRD = dist(cand, rw.pos)
						if (nxtRD < RIVAL_AVOID_R and nxtRD < curRD - 1.0) or (rw.nestPos and dist(cand, rw.nestPos) < RIVAL_FIGHT_R + 6.0) then
							rivalBad = true
							break
						end
					end
				end
			end
			if not nearFire and not rivalBad then
				w.exploreAng = ang
				return VecCopy(cand)
			end
		end
		end
	end

	-- Pass 2: Medium-range fallback (12..28m)
	for _ = 1, 12 do
		local ang = w.exploreAng + (math.random() - 0.5) * 1.8
		local r = 12.0 + math.random() * 16.0
		local g = VecAdd(w.pos, Vec(math.cos(ang) * r, (math.random() - 0.5) * 4.0, math.sin(ang) * r))
		local ok, rep = Nav.free(g)
		if ok and wormSurface(rep or g, SURF_R) and dist(rep or g, w.pos) > 6.0 then
			w.exploreAng = ang
			return VecCopy(rep or g)
		end
	end
	return VecAdd(w.pos, Vec(math.cos(w.exploreAng) * 18.0, 0, math.sin(w.exploreAng) * 18.0))
end

-- the current goal per state (prioritizing: 1. Water when burning, 2. Building/rebuilding silken nest, 3. Juvenile staying near nest, 4. Egg laying / periodic visit)
function wormGoal(w)
	if w.variant ~= "ignitus" and w.variant ~= "machina" and now() < (w.burnUntil or 0) and w.waterGoal and not wormIsWormTarget(w.target) then
		return w.waterGoal
	end
	if w.baby then
		local home = w.nestPos or w.motherNestPos or w.lair
		local npcHid, npcPos = wormFindNearbyLivingNpc(w.pos, BABY_NPC_CHASE_R)
		if npcPos and dist(npcPos, home) <= BABY_NEST_RADIUS + 5.0 then
			return VecCopy(npcPos)
		end
		local food = wormFindCocoonNear(home, BABY_NEST_RADIUS + 6.0)
		if food and now() > (w.feedCd or 0) then
			return VecCopy(food.pos)
		end
		if dist(w.pos, home) > BABY_NEST_RADIUS + 1.0 then
			w.goal = VecCopy(home)
			return w.goal
		end
		if not w.goal or now() > w.wanderT or dist(w.goal, w.pos) < 0.8 then
			w.goal = wormWanderGoal(w)
			w.wanderT = now() + 4 + math.random() * 8
		end
		return w.goal
	end
	if not w.nestBuilt then
		if w.buildingNest and w.nestPos then
			wormBuildSilkNest(w)
			-- Crawl across the expanding procedural silk vein network while spraying layers 1..6
			local elapsed = now() - (w.nestBuildStartT or now())
			local frac = math.min(1.0, elapsed / NEST_BUILD_DURATION)
			local ang = now() * 1.85 + w.id
			local sprayR = 1.0 + 3.6 * (0.5 + 0.5 * math.sin(now() * 0.9)) * (0.35 + 0.65 * frac)
			return VecAdd(w.nestPos, Vec(math.cos(ang) * sprayR, 0.25 * math.sin(now() * 2.4), math.sin(ang) * sprayR))
		end
		if not w.nestTarget then
			if not w.nestSearch then
				wormFindDarkNestSite(w, w.motherNestPos)
				w.nestRetries = w.nestRetries or 0
			end
			local site = wormNestSearchStep(w)
			if not site then
				-- Keep prowling while the background nest search evaluates candidates
				if not w.goal or now() > w.wanderT or dist(w.goal, w.pos) < 2.2 then
					w.goal = wormWanderGoal(w)
					w.wanderT = now() + 6 + math.random() * 8
				end
				return w.goal
			end
			w.nestTarget = site
			w.nestStartT = now()
		end
		local maxTravelT = w.motherNestPos and 35.0 or 22.0
		if dist(w.pos, w.nestTarget) < 3.2 or (now() - (w.nestStartT or w.t0)) > maxTravelT then
			wormBuildSilkNest(w)
			return w.nestPos or w.nestTarget or w.pos
		end
		return w.nestTarget
	end
	if w.returningToLay and (w.nestPos or w.lair) then
		return w.nestPos or w.lair
	end
	if w.visitingNest and w.nestPos and w.state == "lurk" then
		return w.nestPos
	end
	if w.state == "lurk" then
		if not w.goal or now() > w.wanderT or dist(w.goal, w.pos) < 2.2 then
			w.goal = wormWanderGoal(w)
			w.wanderT = now() + 8 + math.random() * 14
		end
		return w.goal
	elseif w.state == "stalk" or w.state == "chase" then
		return w.known or w.pos
	elseif w.state == "drag" or w.state == "flee" then
		return w.nestPos or w.lair
	end
	return w.pos
end

-- Probes radial directions to find the clearest open tunnel/corridor heading when direct line-of-sight to `goal` is blocked by a wall
function wormFollowOpenTunnel(w, goal)
	local toG = VecSub(goal, w.pos)
	local toGLen = vlen(toG)
	local goalDir = toGLen > 0.05 and VecScale(toG, 1 / toGLen) or w.fwd
	local bestPt, bestScore = nil, -1e9
	local up = w.up or Vec(0, 1, 0)
	local fwd = VecNormalize(VecSub(w.fwd, VecScale(up, VecDot(w.fwd, up))))
	if vlen(fwd) < 0.1 then fwd = w.fwd end
	local side = VecNormalize(VecCross(up, fwd))
	if vlen(side) < 0.1 then side = Vec(1, 0, 0) end

	for _, pitch in ipairs({0.0, 0.28, -0.28}) do
		for i = 1, 16 do
			local ang = ((i - 1) / 16) * 6.283185
			local ca, sa = math.cos(ang), math.sin(ang)
			local flatDir = VecAdd(VecScale(fwd, ca), VecScale(side, sa))
			local candDir = VecNormalize(VecAdd(flatDir, VecScale(up, pitch)))
			wormFilter()
			local hit, hd = QueryRaycast(w.pos, candDir, 8.0, (w.legR or HEAD_R) * 0.7)
			local clearD = hit and hd or 8.0
			if clearD > 1.1 then
				local stepP = VecAdd(w.pos, VecScale(candDir, math.min(2.6, clearD - 0.3)))
				if wormSurface(stepP, SURF_R * 1.45) then
					local alignFwd = VecDot(candDir, w.fwd)
					local alignGoal = VecDot(candDir, goalDir)
					local uTurnPenalty = (alignFwd < -0.25) and -8.0 or 0.0
					local sc = clearD * 1.4 + alignFwd * 4.2 + alignGoal * 2.8 + uTurnPenalty
					if sc > bestScore then
						bestScore = sc
						bestPt = stepP
					end
				end
			end
		end
		if bestPt then break end
	end
	return bestPt or VecAdd(w.pos, VecScale(w.fwd, 2.5))
end

-- plan to the goal (Nav), straight when clear (including bridging across gaps shorter than bodyLen)
function wormSteerTarget(w, goal)
	w.legR = w.baby and (HEAD_R * 0.5) or HEAD_R
	local maxBridge = (w.bodyLen or BODY_LEN) * 0.88
	-- the straight-line test (a sphere cast and a surface probe every 0.6 m) only for goals within reach, and at
	-- most 10 times a second per worm unless the goal moved (it ran every frame)
	if dist(goal, w.pos) < maxBridge then
		if now() >= (w.bridgeT or 0) or not w.bridgeGoal or dist(w.bridgeGoal, goal) > 0.5 then
			w.bridgeOk = wormBridgeClear(w.pos, goal, w.legR, maxBridge)
			w.bridgeT = now() + 0.1
			w.bridgeGoal = VecCopy(goal)
		end
		if w.bridgeOk then
			w.path = nil
			return goal
		end
	end
	local replan = not w.planGoal or dist(w.planGoal, goal) > math.max(3, 0.15 * dist(goal, w.pos)) or now() - w.planT > 3.5
	if replan and now() >= (w.planHold or 0) then
		local returningHome = (w.nestPos and dist(goal, w.nestPos) < 3.5) and true or false
		-- Only allow Nav to plan dig legs when actively hunting/dragging/returning home, never while casually lurking
		local allowDig = (not w.baby) and (w.state ~= "lurk" or returningHome or not w.nestBuilt)
		Nav.request(w.id, w.pos, goal, {maxBridge = maxBridge, dig = allowDig, maxNodes = returningHome and 10000 or nil})
		w.planGoal = VecCopy(goal)
		w.planT = now()
		w.planning = true
	end
	if w.planning then
		local r = Nav.result(w.id)
		if r then
			w.planning = false
			w.planInfo = (r.source or "?") .. (r.ok and "" or "-x") .. (r.partial and "-part" or "") .. (r.dig and "-dig" or "")
			w.path = r.points
			w.pathI = 1
			w.digs = {}
			for _, i in ipairs(r.digs or {}) do w.digs[i] = true end
			w.tight = r.tight or {}
			local useful = false
			for _, p in ipairs(r.points or {}) do if dist(p, w.pos) > 1.1 then useful = true end end
			if not useful then
				w.path = nil
				w.planHold = now() + 1.0
				if w.state == "lurk" then w.goal = nil end
			end
		end
	end
	if w.path then
		local reachR = 1.35 * math.max(1.0, (w.scale or 1.0) * 0.65)
		while w.pathI <= #w.path do
			local wp0 = w.path[w.pathI]
			local d0 = dist(wp0, w.pos)
			-- Advance if within reachR, OR if an intermediate waypoint is close and already behind the head's forward direction (prevents looping back)
			local behind = (w.pathI < #w.path and d0 < reachR * 1.85 and VecDot(VecSub(wp0, w.pos), w.fwd) < -0.15)
			if d0 < reachR or behind then
				w.pathI = w.pathI + 1
			else
				break
			end
		end
		local wp = w.path[w.pathI]
		if wp then
			local leg = w.pathI - 1
			w.legR = (w.tight and w.tight[leg]) and TIGHT_R or HEAD_R
			if w.digs[leg] and not wormClear(w.pos, wp, w.legR) then
				local bDir = VecNormalize(VecSub(wp, w.pos))
				if wormCanBreakAt(w.pos, bDir) then
					wormBite(w, bDir)
				else
					-- Unbreakable tunnel wall on a planned dig leg: mark it hard and replan through open space!
					Nav.markHard(VecAdd(w.pos, VecScale(bDir, 0.8)), 1.6)
					w.path, w.planGoal, w.planHold = nil, nil, 0
				end
			end
			return wp
		end
		w.path = nil
		w.planGoal = nil
	end
	-- When waiting for a 3D path (or if a path ended early), NEVER steer blindly through a tunnel wall toward `goal`!
	-- First check if the immediate step toward `goal` is clear; if blocked by a wall, steer along the open tunnel corridor.
	local toG = VecSub(goal, w.pos)
	local toL = vlen(toG)
	if toL > 0.2 and wormClear(w.pos, VecAdd(w.pos, VecScale(toG, math.min(2.8, toL) / toL)), w.legR) then
		return goal
	end
	-- (the probe is up to 48 sphere casts: its answer is kept 0.4 s, or until the head is close to it, instead of
	--  probing again every frame while a path is being planned)
	local tunnelWp = w.tunnelWp
	if not tunnelWp or now() > (w.tunnelT or 0) or dist(tunnelWp, w.pos) < 0.8 then
		tunnelWp = wormFollowOpenTunnel(w, goal)
		w.tunnelWp, w.tunnelT = tunnelWp, now() + 0.4
	end
	if tunnelWp then
		w.exploreAng = math.atan2(tunnelWp[3] - w.pos[3], tunnelWp[1] - w.pos[1])
		return tunnelWp
	end
	return goal
end

function wormTempo(w)
	if w.buildingNest then return 0.85 end
	if now() < (w.burnUntil or 0) or (not w.baby and (not w.nestBuilt or w.returningToLay or w.visitingNest)) then return 1.35 end
	if now() < (w.repairingNestUntil or 0) then
		return 0.15
	end
	if w.state == "lurk" and now() < (w.hidingInNest or 0) and w.nestPos and dist(w.pos, w.nestPos) < 1.6 then
		return 0
	end
	local tab = TEMPO[w.state]
	if not tab then return 1 end
	if now() >= w.tempoUntil then
		local e = pick(tab)
		w.tempo = e[2]
		w.tempoUntil = now() + e[3] + math.random() * (e[4] - e[3])
	end
	return w.tempo
end

-- metres to the nearest living player or targetable NPC
function wormNearest(w)
	local best = 1e9
	for _, p in ipairs(GetAllPlayers()) do
		if GetPlayerHealth(p) > 0 then best = math.min(best, dist(wormChest(p), w.pos)) end
	end
	for _, n in ipairs(wormNpcList) do
		if wormNpcFree(n) then best = math.min(best, dist(n.pos, w.pos)) end
	end
	for _, v in ipairs(wormVlList) do
		if wormVlFree(v) then best = math.min(best, dist(v.chest, w.pos)) end
	end
	return best
end

function wormMove(w, dt)
	local goal = wormGoal(w)
	w.creep = false
	local aim = wormSteerTarget(w, goal)

	local inWater = IsPointInWater(w.pos)
	local onSurf, surfPt, surfDist, surfNorm = wormSurface(w.pos, SURF_R)
	if onSurf and surfNorm and vlen(surfNorm) > 0.1 then
		w.up = VecNormalize(VecLerp(w.up or Vec(0, 1, 0), surfNorm, math.min(1, 12 * dt)))
	elseif inWater then
		w.up = VecNormalize(VecLerp(w.up or Vec(0, 1, 0), Vec(0, 1, 0), math.min(1, 8 * dt)))
	end
	if onSurf or inWater then
		w.anchorPos = VecCopy(w.pos)
	end
	local bridging = (not onSurf) and (not inWater) and wormCanBridge(w, w.pos, aim)

	if not onSurf and not bridging and not inWater then
		local fallStep = GRAVITY_SPEED * dt
		wormFilter()
		local hit, d = QueryRaycast(w.pos, Vec(0, -1, 0), fallStep + CLING_DIST)
		if hit then
			w.pos = VecAdd(w.pos, Vec(0, -math.max(0, d - CLING_DIST), 0))
			w.anchorPos = VecCopy(w.pos)
		else
			w.pos = VecAdd(w.pos, Vec(0, -fallStep, 0))
		end
		w.fwd = VecNormalize(VecLerp(w.fwd, Vec(0, -1, 0), math.min(1, 8 * dt)))
		wormRecord(w)
		return
	end

	local base = SPEED[w.state] or 0
	if now() < (w.burnUntil or 0) then base = SPEED.flee end
	if not w.baby and w.state == "lurk" and (not w.nestBuilt or w.returningToLay or w.visitingNest) then base = SPEED.roam end
	if w.baby then base = SPEED.lurk * 0.75 end
	-- Seismica moves progressively slower with each minute it grows (up to 10 stages / 200% size)
	if w.variant == "seismica" and (w.growthStage or 0) > 0 then
		base = base / (1.0 + SEIS_SLOW * (w.growthStage or 0))
	end
	if IsPointInWater(w.pos) then base = base * WATER_SLOW end
	if w.creep then base = base * 0.55 end
	local curTempo = wormTempo(w)
	w.smoothTempo = (w.smoothTempo or curTempo) + (curTempo - (w.smoothTempo or curTempo)) * math.min(1, 3.5 * dt)
	local want = aim and base * w.smoothTempo or 0
	local tw = TWITCH[w.state] or 0
	if now() > w.twitchUntil and math.random() < tw * dt then
		local side = VecNormalize(VecCross(w.fwd, surfNorm or Vec(0, 1, 0)))
		if vlen(side) < 0.5 then side = Vec(1, 0, 0) end
		w.twitchDir = VecNormalize(VecAdd(w.fwd, VecScale(side, (math.random() < 0.5 and -1 or 1) * (0.18 + math.random() * 0.22))))
		w.twitchUntil = now() + 0.12 + math.random() * 0.18
	end
	local k = want > w.speed and 6.0 or 8.5
	w.speed = w.speed + (want - w.speed) * math.min(1, k * dt)
	local dir = w.fwd
	local turnDot = 1.0
	if aim then
		local to = VecSub(aim, w.pos)
		local toLen = vlen(to)
		if toLen > 0.05 then
			local d = VecScale(to, 1 / toLen)
			turnDot = VecDot(w.fwd, d)
			-- Prevent U-turning directly back over its own neck/body segments: deflect sharp backward targets into a wide arc
			if turnDot < -0.25 and not bridging then
				local upV = surfNorm or w.up or Vec(0, 1, 0)
				local sideV = VecNormalize(VecCross(upV, w.fwd))
				if vlen(sideV) < 0.1 then sideV = Vec(1, 0, 0) end
				local sign = VecDot(d, sideV) >= 0 and 1 or -1
				d = VecNormalize(VecAdd(VecScale(w.fwd, 0.35), VecScale(sideV, 0.94 * sign)))
				turnDot = VecDot(w.fwd, d)
			end
			local sizeSlowTurn = (w.variant == "seismica" and (w.scale or 1.0) > 1.0) and (1 / math.sqrt(w.scale)) or 1.0
			local rate = ((turnDot < 0.35 or toLen < 4.0 or bridging) and 9.5 or 6.8) * sizeSlowTurn
			dir = VecNormalize(VecLerp(w.fwd, d, math.min(1, rate * dt)))
		end
	end
	-- Self-overlap avoidance: if steering toward its own body trail ahead, gently veer sideways so it doesn't coil over itself
	if #w.trail > 8 and not bridging then
		local probeAhead = VecAdd(w.pos, VecScale(dir, 1.6 * math.max(1.0, (w.scale or 1.0) * 0.6)))
		local maxIdx = math.max(1, #w.trail - 6)
		for ti = maxIdx, 1, -3 do
			local tp = w.trail[ti]
			if tp and dist(probeAhead, tp) < 1.15 * math.max(1.0, (w.scale or 1.0) * 0.5) then
				local awayT = VecSub(probeAhead, tp)
				local upV = surfNorm or w.up or Vec(0, 1, 0)
				awayT = VecSub(awayT, VecScale(upV, VecDot(awayT, upV)))
				if vlen(awayT) > 0.05 then
					dir = VecNormalize(VecAdd(dir, VecScale(VecNormalize(awayT), 0.65)))
				end
				break
			end
		end
	end
	if turnDot < 0.20 and not bridging then
		w.speed = w.speed * math.max(0.35, (turnDot + 1.0) * 0.55)
	end
	if now() < w.twitchUntil and w.twitchDir and not bridging and w.state ~= "lurk" then
		dir = VecNormalize(VecLerp(dir, w.twitchDir, 0.12))
	end

	-- Territorial Avoidance (biological variants only; Machina actively hunts other Silkmaws):
	if w.variant ~= "machina" and w.state == "lurk" and aim and not w.visitingNest and not w.returningToLay and now() > (w.rivalCheckT or 0) then
		w.rivalCheckT = now() + 0.6
		for _, rw in ipairs(wormList) do
			if rw ~= w and rw.alive and not rw.baby and (rw.variant or "acidica") ~= (w.variant or "acidica") then
				local rd = dist(w.pos, rw.pos)
				if rd > RIVAL_FIGHT_R and rd < RIVAL_AVOID_R and dist(aim, rw.pos) < rd then
					w.exploreAng = math.atan2(w.pos[3] - rw.pos[3], w.pos[1] - rw.pos[1]) + (math.random() - 0.5) * 0.8
					w.goal = wormWanderGoal(w)
					w.path, w.planGoal, w.planHold = nil, nil, 0
					break
				end
			end
		end
	end

	-- Active Fire Avoidance (Acidica only; Ignitus is impervious to fire): sense fires ahead or nearby and steer away (unless locked in rival combat)
	if w.variant ~= "ignitus" and w.variant ~= "machina" and not wormIsWormTarget(w.target) and QueryClosestFire and now() >= (w.burnUntil or 0) then
		local probeP = VecAdd(w.pos, VecScale(dir, 2.2))
		local hasFire, fireP = QueryClosestFire(probeP, 4.8)
		if not hasFire then
			hasFire, fireP = QueryClosestFire(w.pos, 3.6)
		end
		if hasFire and fireP then
			local away = VecSub(w.pos, fireP)
			local awayD = vlen(away)
			away = awayD > 0.01 and VecScale(away, 1 / awayD) or Vec(0, 1, 0)
			if surfNorm then
				local tangAway = VecSub(away, VecScale(surfNorm, VecDot(away, surfNorm)))
				if vlen(tangAway) > 0.1 then away = VecNormalize(tangAway) end
			end
			dir = VecNormalize(VecAdd(VecScale(dir, 0.2), VecScale(away, 1.6)))
			w.speed = math.max(w.speed, SPEED.flee * 0.85)
			if awayD < 2.2 and now() > (w.fireRecoilCd or 0) then
				w.fireRecoilCd = now() + 1.5
				wormRecoil(w, 1.2)
				w.exploreAng = math.atan2(away[3], away[1])
				w.path, w.planGoal, w.goal = nil, nil, nil
			end
		end
	end

	local toSurf = Vec(0, -1, 0)
	if onSurf and surfPt then
		toSurf = surfDist > 0.001 and VecScale(VecSub(surfPt, w.pos), 1 / surfDist) or Vec(0, -1, 0)
		local launching = aim and dist(aim, surfPt) > surfDist + 1.2 and wormCanBridge(w, w.pos, aim)
		if not launching then
			local pull = math.max(-0.25, math.min(0.85, (surfDist - CLING_DIST) * 2.2))
			dir = VecNormalize(VecAdd(dir, VecScale(toSurf, pull)))
		end
	end

	if w.state == "lurk" and now() < (w.hidingInNest or 0) and w.nestPos and dist(w.pos, w.nestPos) < 1.6 then
		w.vel = Vec(0, 0, 0)
		w.circleT = now()
		w.circlePos = VecCopy(w.pos)
		return
	end

	if now() - (w.circleT or 0) > 2.0 then
		if dist(w.pos, w.circlePos or w.pos) < 1.4 then
			if w.path and w.pathI <= #w.path then
				w.pathI = w.pathI + 1
			else
				w.path = nil
				w.planGoal = nil
				w.planHold = 0
				if not w.nestBuilt and not w.buildingNest then
					w.nestTarget = wormWanderGoal(w)
				else
					w.goal = wormWanderGoal(w)
				end
				if w.state ~= "lurk" and aim then
					local bd = VecNormalize(VecSub(aim, w.pos))
					if (bd[2] > -0.6 or wormFloorBelow(w.pos, bd)) and wormCanBreakAt(w.pos, bd) then
						wormBite(w, bd)
					else
						Nav.markHard(VecAdd(w.pos, VecScale(bd, 0.8)), 1.5)
						wormRecoil(w, 2.2)
					end
				else
					wormRecoil(w, 2.0)
				end
			end
		end
		w.circleT = now()
		w.circlePos = VecCopy(w.pos)
	end

	local step = math.max(w.speed * dt, 0.015)

	local moved = false
	local tang = VecSub(dir, VecScale(toSurf, VecDot(dir, toSurf)))
	if vlen(tang) > 0.1 then tang = VecNormalize(tang) else tang = dir end
	local sideVec = VecNormalize(VecCross(dir, toSurf))
	local tries = {
		dir,
		tang,
		VecNormalize(VecAdd(tang, VecScale(sideVec, 0.6))),
		VecNormalize(VecAdd(tang, VecScale(sideVec, -0.6))),
		VecNormalize(VecAdd(tang, VecScale(toSurf, 0.8))),
		VecNormalize(VecAdd(tang, VecScale(toSurf, -0.7))),
		VecNormalize(VecAdd(tang, Vec(0, 0.9, 0))),
		VecNormalize(VecAdd(tang, Vec(0, -0.9, 0))),
		toSurf,
	}

	local r = w.legR or HEAD_R
	wormFilter()
	local hit, cp = QueryClosestPoint(w.pos, r)
	local touch = nil
	if hit then
		touch = dist(cp, w.pos)
		r = math.max(0.01, touch - 0.02)
		local away = VecNormalize(VecSub(w.pos, cp))
		if vlen(away) > 0.5 then table.insert(tries, 2, VecNormalize(VecAdd(dir, VecScale(away, 1.2)))) end
	end
	if inWater and not onSurf then                               -- (deep under water: up to the surface)
		dir = VecNormalize(VecAdd(VecScale(dir, 0.4), Vec(0, 1, 0)))
		tries[1] = dir
	end
	for idx, d0 in ipairs(tries) do
		local s = idx == 1 and step or step * 0.75
		local nxt = VecAdd(w.pos, VecScale(d0, s))
		local fireSafe = true
		if w.variant ~= "ignitus" and w.variant ~= "machina" and not wormIsWormTarget(w.target) and QueryClosestFire and now() >= (w.burnUntil or 0) then
			local hf, fp = QueryClosestFire(nxt, 2.2)
			if hf and fp and dist(nxt, fp) < dist(w.pos, fp) then fireSafe = false end
		end
		if fireSafe and wormClear(w.pos, nxt, r) and (wormSurface(nxt, SURF_R) or (inWater and not onSurf) or (onSurf and surfPt and dist(nxt, surfPt) < surfDist) or wormCanBridge(w, nxt, aim)) then
			w.vel = VecScale(d0, s / dt)
			w.pos = nxt
			local fwdBlend = (idx == 1) and math.min(1, 14 * dt) or math.min(1, 7 * dt)
			w.fwd = VecNormalize(VecLerp(w.fwd, d0, fwdBlend))
			wormRecord(w)
			moved = true
			break
		end
	end
	w.touch = touch
	w.blocked = not moved
	if not moved then
		w.vel = Vec(0, 0, 0)
		w.speed = w.speed * 0.3
	end
	local d = aim and dist(aim, w.pos) or 0
	if aim and d < w.stuckD - 0.3 then
		w.stuckD = d
		w.stuckT = now()
		w.stuckN = 0
	elseif aim and want > 0.5 and now() - w.stuckT > STUCK_T then
		local bd = VecNormalize(VecSub(aim, w.pos))
		w.stuckN = (w.stuckN or 0) + 1
		if w.stuckN >= STUCK_BACK_N then                            -- (nothing helped: back out the way it came)
			w.stuckN = 0
			wormRecoil(w, STUCK_BACK)
			w.goal, w.path = nil, nil
		elseif (w.state ~= "lurk" or w.stuckN >= STUCK_BITE_N) and (bd[2] > -0.6 or wormFloorBelow(w.pos, bd)) and wormCanBreakAt(w.pos, bd) then
			wormBite(w, bd)
		else
			Nav.markHard(VecAdd(w.pos, VecScale(bd, 0.8)), 1.5)
			w.path = nil
			if w.state == "lurk" then w.goal = nil end
		end
		w.stuckT = now()
		w.stuckD = 1e9
		w.planGoal = nil
	end
	if aim and d > w.stuckD + 2 then w.stuckD = d end
end

-- Triggers the Seismica variant's tectonic shockwave attack, shattering nearby objects/voxels and hurling dynamic props
-- with radius, destructive hole size, and impulse scaling with its current growth size (w.scale)
QUAKE_CD = 8.0                -- s between quakes (the pack: 5.5)
QUAKE_RING_HOLES = 3          -- holes round it besides the one under it (the pack: 8-10; every hole goes to every client)
QUAKE_FLING_MAX = 16          -- loose bodies it throws, the nearest first (the pack: every one in a ~26 m box)
QUAKE_FLING_MASS = 4          -- kg: lighter pieces (debris) are left alone

function wormSeismicAttack(w)
	local sc = w.scale or 1.0
	local pow = math.min(2.0, sc)
	local radius = 6.5 * pow
	w.seismicCd = now() + QUAKE_CD
	w.seismicT = now()
	w.mouth = 1.0
	w.ev.bite = (w.ev.bite or 0) + 1
	w.ev.shriek = (w.ev.shriek or 0) + 1

	-- 1. The ground breaks under it and in a few places round it (soft and medium materials only)
	wormOwnHoleT = now()
	wormBoxesParkAll()
	local softR = math.min(2.4, 1.2 * pow)
	local medR = math.min(1.8, 0.85 * pow)
	if not wormNearAnyNest(w.pos, radius + 2.0) and not wormNearPod(w.pos, radius + 2.0) then
		MakeHole(w.pos, softR, medR, 0, false)
	end
	local a0 = math.random() * 6.283185
	for i = 1, QUAKE_RING_HOLES do
		local ang = a0 + (i / QUAKE_RING_HOLES) * 6.283185 + (math.random() - 0.5) * 0.5
		local distR = (2.0 + math.random() * 2.0) * pow
		local dir = VecNormalize(Vec(math.cos(ang), -0.15 + (math.random() - 0.5) * 0.4, math.sin(ang)))
		wormFilter()
		local o = VecAdd(w.pos, Vec(0, 0.5, 0))
		local hit, hd, _, hitShape = QueryRaycast(o, dir, distR + 1.5)
		local p = hit and VecAdd(o, VecScale(dir, hd)) or VecAdd(w.pos, VecScale(dir, distR))
		if (not hit or not wormShapeIsUnbreakableTag(hitShape)) and not wormNearAnyNest(p, 3.8) and not wormNearPod(p, 3.2) then
			MakeHole(p, softR * 0.8, medR * 0.75, 0, true)
		end
	end
	wormBoxesRestoreAll()
	Nav.forget(w.pos, radius * 0.7)

	-- 2. Loose things are thrown: the nearest QUAKE_FLING_MAX of them, no light debris (each thrown body is physics on
	--    the host and a moving body sent to every client)
	QueryRequire("physical dynamic")
	QueryCollisionMask(WORM_QUERY_MASK)
	local mins = VecAdd(w.pos, Vec(-radius, -radius * 0.6, -radius))
	local maxs = VecAdd(w.pos, Vec(radius, radius * 0.8, radius))
	local near = {}
	for _, b in ipairs(QueryAabbBodies(mins, maxs) or {}) do
		if IsHandleValid(b) and not HasTag(b, "silkmawhit") and not HasTag(b, "silkmawview") and not HasTag(b, "silkmawnest") and not HasTag(b, "silkmawcocoon")
			and GetBodyMass(b) >= QUAKE_FLING_MASS then
			local d = dist(GetBodyTransform(b).pos, w.pos)
			if d < radius then near[#near + 1] = {b = b, d = d} end
		end
	end
	table.sort(near, function(x, y) return x.d < y.d end)
	for i = 1, math.min(#near, QUAKE_FLING_MAX) do
		local b, d = near[i].b, near[i].d
		local falloff = 1 - (d / radius) * 0.7
		local pushDir = VecNormalize(VecAdd(VecSub(GetBodyTransform(b).pos, w.pos), Vec(0, 0.55, 0)))
		SetBodyVelocity(b, VecAdd(GetBodyVelocity(b), VecScale(pushDir, (7.0 + 4.5 * pow) * falloff)))
		SetBodyAngularVelocity(b, Vec((math.random() - 0.5) * 8 * falloff, (math.random() - 0.5) * 8 * falloff, (math.random() - 0.5) * 8 * falloff))
	end

	-- 3. Concuss and knock back nearby players, NPCs, and rival Silkmaws
	for _, p in ipairs(GetAllPlayers()) do
		if GetPlayerHealth(p) > 0 and not wormPlayerCocoons[p] then
			local pc = wormChest(p)
			local dp = dist(pc, w.pos)
			if dp < radius then
				local falloff = 1 - (dp / radius) * 0.65
				SetPlayerHealth(math.max(0, GetPlayerHealth(p) - 0.14 * pow * falloff), p)
				local push = VecNormalize(VecAdd(VecSub(pc, w.pos), Vec(0, 0.5, 0)))
				SetPlayerVelocity(VecAdd(GetPlayerVelocity(p), VecScale(push, (6.5 + 3.5 * pow) * falloff)), p)
			end
		end
	end
	for _, v in ipairs(wormVlList) do                            -- villagers: as players
		local dv = dist(v.chest, w.pos)
		if dv < radius and not wormVlCocoons[v.id] then
			local falloff = 1 - (dv / radius) * 0.65
			wormVlHurt(v.id, 0.14 * pow * falloff, w, w.pos, (6.5 + 3.5 * pow) * falloff)
		end
	end
	for _, n in ipairs(wormNpcList) do
		if n.alive and dist(n.pos, w.pos) < radius and not (wormCocoons and wormCocoons[n.hid]) then
			local push = VecNormalize(VecAdd(VecSub(n.pos, w.pos), Vec(0, 0.45, 0)))
			local falloff = 1 - (dist(n.pos, w.pos) / radius) * 0.65
			wormEcoHit(n.hid, 0.14 * pow * falloff, "bite", n.pos, push, "silkmaw_" .. tostring(w.id))
		end
	end
	for _, ow in ipairs(wormList) do                           -- (rivals only: not its own kind, not its own young)
		if ow.alive and ow ~= w and ow.variant ~= w.variant and dist(ow.pos, w.pos) < radius then
			wormDamage(ow, 16.0 * pow, "explosion", ow.pos, w)
		end
	end
end

function wormUpdate(w, dt)
	if not w.alive then return end
	w.mouth = math.max(0, w.mouth - dt * 1.6)
	if now() < (w.wakeT or 0) then
		w.speed = 0
		w.vel = Vec(0, 0, 0)
		local onSurf = wormSurface(w.pos, SURF_R)
		if not onSurf and not IsPointInWater(w.pos) then
			local fallStep = GRAVITY_SPEED * dt
			wormFilter()
			local hit, d = QueryRaycast(w.pos, Vec(0, -1, 0), fallStep + CLING_DIST)
			if hit then
				w.pos = VecAdd(w.pos, Vec(0, -math.max(0, d - CLING_DIST), 0))
				w.anchorPos = VecCopy(w.pos)
			else
				w.pos = VecAdd(w.pos, Vec(0, -fallStep, 0))
			end
		end
		return
	end
	-- Juveniles bite nearby living NPCs and feed on dead or cocooned NPCs
	if w.baby then
		local npcHid, npcPos, npcD = wormFindNearbyLivingNpc(w.pos, BABY_NPC_BITE_R)
		if npcHid and npcPos and now() > (w.biteNpcCd or 0) then
			w.biteNpcCd = now() + BABY_BITE_CD
			w.mouth = 1.0
			w.ev.bite = w.ev.bite + 1
			local bDir = VecNormalize(VecSub(npcPos, w.pos))
			w.fwd = VecNormalize(VecLerp(w.fwd, bDir, 0.6))
			wormEcoHit(npcHid, BABY_BITE, "bite", w.pos, w.fwd, "silkmaw_" .. tostring(w.id))
			w.hp = math.min(w.maxHp or HP, w.hp + 5.0)
			w.t0 = w.t0 - (COCOON_FEED_GROW * 0.5)
		end
		local food = wormFindCocoonNear(w.pos, 1.85)
		if food and now() > (w.feedCd or 0) then
			w.feedCd = now() + COCOON_FEED_CD
			w.mouth = 0.95
			w.ev.bite = w.ev.bite + 1
			wormEcoHit(food.hid, 0.12, "bite", w.pos, w.fwd, "silkmaw_" .. tostring(w.id))
			w.hp = math.min(w.maxHp or HP, w.hp + 8.0)
			w.t0 = w.t0 - COCOON_FEED_GROW
		end
	end
	if w.state == "windup" then
		w.mouth = math.min(1, 0.2 + (now() - w.stateT) / WINDUP_T)
		w.speed = 0
		if wormTargetValid(w.target) then
			w.fwd = VecNormalize(VecLerp(w.fwd, VecNormalize(VecSub(wormTargetPos(w.target), w.pos)), math.min(1, 10 * dt)))
		end
		if now() - w.stateT > WINDUP_T then
			wormSetState(w, "lunge")
			w.ev.lunge = w.ev.lunge + 1
		end
		return
	elseif w.state == "lunge" then
		w.mouth = 1
		local tgt = wormTargetValid(w.target) and wormTargetPos(w.target) or VecAdd(w.pos, w.fwd)
		local d = VecNormalize(VecSub(tgt, w.pos))
		w.fwd = VecNormalize(VecLerp(w.fwd, d, math.min(1, 6 * dt)))
		local lungeSpd = (w.variant == "seismica" and (w.growthStage or 0) > 0) and (LUNGE_SPEED / (1.0 + SEIS_SLOW * w.growthStage)) or LUNGE_SPEED
		local nxt = VecAdd(w.pos, VecScale(w.fwd, lungeSpd * dt))
		if not wormSurface(nxt, SURF_R * 1.5) and not wormCanBridge(w, nxt, tgt) then
			nxt = VecAdd(nxt, Vec(0, -GRAVITY_SPEED * 0.5 * dt, 0))
		end
		if wormClear(w.pos, nxt, HEAD_R * 0.8) then
			w.pos = nxt
			wormRecord(w)
		else
			wormBite(w, w.fwd)
		end
		local hitTarget = false
		if wormTargetValid(w.target) and not wormGrabbed[w.target] then
			if wormIsWormTarget(w.target) then
				local rw = wormById(string.sub(w.target, 3))
				if rw and rw.alive then
					local jaw = wormJaw(w)
					local rpts = wormSample(rw, 1.0, rw.bodyLen or BODY_LEN)
					for k = 1, #rpts, 3 do
						if dist(jaw, Vec(rpts[k], rpts[k + 1], rpts[k + 2])) < GRAB_R + 0.45 then
							hitTarget = true
							break
						end
					end
				end
			elseif dist(wormJaw(w), tgt) < GRAB_R then
				hitTarget = true
			end
		end
		if hitTarget then
			if type(w.target) == "number" then
				if w.variant == "machina" then
					SetPlayerHealth(math.max(0.0, GetPlayerHealth(w.target) - 0.35), w.target)
					SetPlayerVelocity(VecAdd(GetPlayerVelocity(w.target), VecAdd(VecScale(w.fwd, 9.0), Vec(0, 4.0, 0))), w.target)
					wormBite(w, w.fwd)
					w.ev.bite = w.ev.bite + 1
					w.lungeCd = now() + LUNGE_CD * 0.75
					wormSetState(w, "chase")
				elseif GetPlayerVehicle(w.target) ~= 0 or w.baby then
					SetPlayerHealth(math.max(0, GetPlayerHealth(w.target) - (w.baby and BABY_BITE or VEHICLE_BITE)), w.target)
					wormBite(w, w.fwd)
					wormSetState(w, "chase")
				else
					wormGrab(w, w.target)
				end
			elseif wormIsVlTarget(w.target) then                      -- a villager: as a player
				local id = wormVlId(w.target)
				if w.variant == "machina" then
					wormVlHurt(id, 0.35, w, w.pos, 9.0)
					wormBite(w, w.fwd)
					w.ev.bite = w.ev.bite + 1
					w.lungeCd = now() + LUNGE_CD * 0.75
					wormSetState(w, "chase")
				elseif w.baby then
					wormVlHurt(id, BABY_BITE, w, w.pos, 0)
					wormBite(w, w.fwd)
					wormSetState(w, "chase")
				else
					wormGrab(w, w.target)
				end
			elseif wormIsNpcTarget(w.target) then
				local hid = wormNpcId(w.target)
				if w.variant == "machina" then
					wormEcoHit(hid, 1.1, "shock", wormJaw(w), w.fwd, "silkmaw_" .. tostring(w.id))
					wormEcoHit(hid, 0.65, "bite", wormJaw(w), w.fwd, "silkmaw_" .. tostring(w.id))
					wormBite(w, w.fwd)
					w.ev.bite = w.ev.bite + 1
					w.lungeCd = now() + LUNGE_CD * 0.75
					wormSetState(w, "chase")
				elseif w.baby or GetInt(LH_REG .. "." .. hid .. ".inveh") ~= 0 then
					wormEcoHit(hid, w.baby and BABY_BITE or VEHICLE_BITE, "bite", wormJaw(w), w.fwd, "silkmaw_" .. tostring(w.id))
					wormSetState(w, "chase")
				else
					wormGrab(w, w.target)
				end
			elseif wormIsWormTarget(w.target) then
				local rw = wormById(string.sub(w.target, 3))
				if rw and rw.alive then
					local biteDmg = RIVAL_BITE_DMG
					if w.variant == "machina" then
						biteDmg = RIVAL_BITE_DMG * 0.75
					elseif rw.variant == "machina" then
						-- Biological Silkmaws tear into Machina's clockwork joints with extra crushing force
						biteDmg = RIVAL_BITE_DMG * 1.35
					elseif w.variant == "acidica" and rw.variant == "ignitus" then
						biteDmg = RIVAL_BITE_DMG * 1.35
					else
						biteDmg = RIVAL_BITE_DMG * 0.85
					end
					wormDamage(rw, biteDmg, "bite", wormJaw(w), w)
					if w.variant == "ignitus" then wormIgnite(rw, BURN_DURATION) end
					w.ev.bite = w.ev.bite + 1
					w.lungeCd = now() + LUNGE_CD * (w.variant == "machina" and 0.90 or 0.65)
					wormSetState(w, "chase")
					wormRecoil(w, 1.0)
				end
			end
		elseif now() - w.stateT > LUNGE_T then
			if w.variant == "seismica" and now() > (w.seismicCd or 0) then
				wormSeismicAttack(w)
			end
			w.ev.bite = w.ev.bite + 1
			w.lungeCd = now() + LUNGE_CD
			wormSetState(w, "chase")
			wormRecoil(w, 1.5 + math.random() * 1.5)
		end
		return
	elseif w.state == "drag" then
		local p = w.grab
		local home = w.nestPos or w.lair
		if not wormTargetValid(p) then
			wormRelease(w)
			wormSetState(w, "lurk")
		elseif type(p) == "number" then
			SetPlayerHealth(math.max(0, GetPlayerHealth(p) - DRAG_HURT * dt), p)
			if w.dmgInDrag >= RELEASE_DMG then
				wormRelease(w)
				wormSetState(w, "flee")
			elseif dist(w.pos, home) < 2.5 then
				-- (home reached alive: a cocoon. Nothing else kills a dragged player but the drag's own damage,
				-- DRAG_HURT, running their health out on the way - there is no time limit any more)
				w.ev.bite = w.ev.bite + 1
				wormRelease(w)
				wormCocoonPlayer(w, p)
				wormSetState(w, "lurk")
				w.tempoUntil = 0
				w.goal = nil
			end
		elseif wormIsVlTarget(p) then                                 -- a villager: as a player
			local id = wormVlId(p)
			w.vlDragHurt = (w.vlDragHurt or 0) + DRAG_HURT * dt
			if w.vlDragHurt * VL_HP >= 1 then wormVlHurt(id, w.vlDragHurt, w, w.pos, 0); w.vlDragHurt = 0 end
			if w.dmgInDrag >= RELEASE_DMG then
				wormRelease(w)
				wormSetState(w, "flee")
			elseif dist(w.pos, home) < 2.5 then
				w.ev.bite = w.ev.bite + 1
				wormRelease(w)
				wormCocoonVillager(w, id)
				wormSetState(w, "lurk")
				w.tempoUntil = 0
				w.goal = nil
			end
		elseif wormIsNpcTarget(p) then
			local hid = wormNpcId(p)
			if w.dmgInDrag >= RELEASE_DMG then
				wormRelease(w)
				wormSetState(w, "flee")
			elseif not wormNpcAlive(hid) then                        -- (died on the way: dropped, no cocoon)
				wormRelease(w)
				wormSetState(w, "lurk")
			elseif dist(w.pos, home) < 2.8 or now() - w.grabT > DRAG_MAX then
				wormCocoonNpc(w, hid, home)
				w.ev.bite = w.ev.bite + 1
				wormRelease(w)
				wormSetState(w, "lurk")
				w.tempoUntil = 0
				w.goal = nil
			end
		end
	elseif w.state == "flee" then
		if dist(w.pos, w.nestPos or w.lair) < 3 then
			wormSetState(w, "lurk")
			w.hidingInNest = now() + 8.0
		end
	elseif w.state == "lurk" then
		w.hp = math.min(w.maxHp or HP, w.hp + 1.5 * dt)
	end
	if (w.state == "chase" or w.state == "stalk") and (now() >= (w.burnUntil or 0) or wormIsWormTarget(w.target)) and not w.returningToLay
		and wormTargetValid(w.target) and w.seeing then
		local c = wormTargetPos(w.target)
		local td = dist(c, w.pos)
		local isRival = wormIsWormTarget(w.target)
		local lungeR = isRival and (LUNGE_RANGE + 1.2) or LUNGE_RANGE
		if w.state == "chase" and td < lungeR and now() > w.lungeCd and (isRival or wormClear(w.pos, c, 0.1)) then
			wormSetState(w, "windup")
			return
		elseif w.variant == "seismica" and td <= (7.5 * math.min(3.5, w.scale or 1.0)) and now() > (w.seismicCd or 0) then
			wormSeismicAttack(w)
		elseif w.variant == "machina" and td <= 12.5 and now() > (w.empCd or 0) then
			-- Clockwork Machina Electronic Wave Pulse (expanding electromagnetic shockwave ring + arc volley)
			w.empCd = now() + 7.0
			w.empT = now()
			w.ev.spit = (w.ev.spit or 0) + 1
			w.ev.shriek = (w.ev.shriek or 0) + 1
			w.mouth = 1.0
			local waveR = 11.5
			if w.hostileToHumans then
				for _, p in ipairs(GetAllPlayers()) do
					if GetPlayerHealth(p) > 0 then
						local pc = wormChest(p)
						local dp = dist(pc, w.pos)
						if dp < waveR then
							local falloff = 1 - (dp / waveR) * 0.65
							SetPlayerHealth(math.max(0.0, GetPlayerHealth(p) - 0.22 * falloff), p)
							local push = VecNormalize(VecAdd(VecSub(pc, w.pos), Vec(0, 0.45, 0)))
							SetPlayerVelocity(VecAdd(GetPlayerVelocity(p), VecScale(push, 10.0 * falloff)), p)
						end
					end
				end
				for _, v in ipairs(wormVlList) do                     -- villagers: as players
					local dv = dist(v.chest, w.pos)
					if dv < waveR and not wormVlCocoons[v.id] then
						local falloff = 1 - (dv / waveR) * 0.65
						wormVlHurt(v.id, 0.22 * falloff, w, w.pos, 10.0 * falloff)
					end
				end
				for _, n in ipairs(wormNpcList) do
					if n.alive and dist(n.pos, w.pos) < waveR then
						local push = VecNormalize(VecAdd(VecSub(n.pos, w.pos), Vec(0, 0.35, 0)))
						wormEcoHit(n.hid, 0.95, "shock", n.pos, push, "silkmaw_" .. tostring(w.id))
					end
				end
			end
			for _, ow in ipairs(wormList) do                       -- (rivals only: other Machinas are left alone)
				if ow.alive and ow ~= w and ow.variant ~= w.variant and dist(ow.pos, w.pos) < waveR then
					wormDamage(ow, 16.0, "shock", ow.pos, w)
				end
			end
			wormSpitAcid(w, c)
		elseif td >= SPIT_MIN_R and td <= SPIT_MAX_R and now() > (w.spitCd or 0) and (isRival or wormClear(w.pos, c, 0.08)) then
			wormSpitAcid(w, c)
		end
	end
	wormMove(w, dt)
end

-- the victim (Player or Living Humans NPC) is held in the jaws
function wormHold(w)
	local tgt = w.grab
	if not tgt or tgt == 0 then return end
	local jaw = wormJaw(w)
	if type(tgt) == "number" then
		if not IsPlayerValid(tgt) then return end
		local t = GetPlayerTransform(tgt)
		local feet = VecSub(jaw, Vec(0, 1.1, 0))
		SetPlayerTransform(Transform(feet, t.rot), tgt)
		SetPlayerVelocity(w.vel, tgt)
	elseif wormIsVlTarget(tgt) then                                -- a villager: the point they hang from
		wormVlCarry(wormVlId(tgt), jaw, w)
	elseif wormIsNpcTarget(tgt) then
		local hid = wormNpcId(tgt)
		if not wormNpcExists(hid) then return end
		if not w.grabBodies or #w.grabBodies == 0 then
			w.grabBodies = wormNpcBodies(hid)
		end
		for _, b in ipairs(w.grabBodies or {}) do
			if IsHandleValid(b) then
				local off = w.grabOffsets and w.grabOffsets[b]
				local p = off and VecAdd(jaw, off.pos) or jaw
				local r = off and off.rot or Quat()
				SetBodyTransform(b, Transform(p, r))
				SetBodyVelocity(b, w.vel)
				SetBodyAngularVelocity(b, Vec(0, 0, 0))
			end
		end
	end
end

----- Villagers of Dunmarrow (its API is host registry keys: nothing reads them when that mod is not running) -----
-- Each centipede is a "thing" for the villagers (villagers.thing.<id>.*: its kind, where it is, what it is doing), so they
-- can see it, fear it and run from it; the kinds are described once at init. API: villagers/mods/villagers/API.md.

VL_KINDS = {
	-- kind id = {name, feel, danger, note, sound, hear}
	gcacidica = {"a giant acid-spitting centipede", "fear", 0.85,
		"as long as a house is wide; it spits acid that eats walls, drags people off to a silk nest and wraps them in cocoons",
		"a dry clicking", 25},
	gcignitus = {"a giant fire-spitting centipede", "fear", 0.9,
		"as long as a house is wide, red as embers and fireproof; it spits fire and drags people off to a charred nest",
		"a crackling hiss", 25},
	gcseismica = {"a huge ground-shaking centipede", "fear", 0.95,
		"it grows ever bigger; when it stamps the ground breaks, things fly and people are knocked flat",
		"a low rumbling", 35},
	gcmachina = {"a giant clockwork centipede", "like", 0,
		"a brass machine as long as a house that hunts the other giant centipedes and protects people; it only turns on people if they hurt it",
		"the grinding of gears", 30},
	gcmachinared = {"a giant clockwork centipede with red eyes", "fear", 0.9,
		"a brass machine as long as a house, its lights gone red: it was hurt and now it attacks people too",
		"the grinding of gears", 30},
	gcjuvenile = {"a small centipede", "wary", 0.3,
		"a young giant centipede, as long as a man, that bites; there are always more near the nest",
		"a skittering", 10},
}

function wormVillagersInit()
	for k, v in pairs(VL_KINDS) do
		local b = "villagers.kind." .. k .. "."
		SetString(b .. "name", v[1]); SetString(b .. "feel", v[2]); SetFloat(b .. "danger", v[3])
		SetString(b .. "note", v[4]); SetString(b .. "sound", v[5]); SetFloat(b .. "hear", v[6])
		-- (no feelings per villager: each villager judges a kind for themselves from its note and danger)
	end
end

local VL_DOING = {lurk = "crawling about", stalk = "creeping closer", chase = "charging", windup = "rearing up to strike",
	lunge = "lunging", drag = "dragging someone off", flee = "fleeing", dead = "dead"}

function wormVillagersTick()
	local t = now()
	if t < (wormVlT or 0) then return end
	wormVlT = t + 0.5
	for _, w in ipairs(wormList) do
		local b = "villagers.thing.gc" .. tostring(w.id) .. "."
		if w.alive then
			local kind = w.baby and "gcjuvenile"
				or (w.variant == "machina" and (w.hostileToHumans and "gcmachinared" or "gcmachina"))
				or ("gc" .. (w.variant or "acidica"))
			SetString(b .. "kind", kind)
			SetFloat(b .. "x", w.pos[1]); SetFloat(b .. "y", w.pos[2]); SetFloat(b .. "z", w.pos[3])
			SetString(b .. "doing", VL_DOING[w.state] or "crawling about")
		elseif not w.vlGone then
			w.vlGone = true
			SetBool(b .. "gone", true)
		end
	end
end

function wormVillagersClear(w)
	ClearKey("villagers.thing.gc" .. tostring(w.id))
end

-- Villagers as prey, exactly like players (the user, 2026-11-15): the same senses (wormPreyScore; their noise level is
-- a sound it hears), the same choice of target, the same attacks (spit, lunge, quake, pulse), seized and dragged home
-- in its jaws (villagers.carry.<id>, written every tick), cocooned there with the same 30 s to live, cut free by a
-- player with E, and their punches hurt it (villagers.strike). Damage in player health (0..1) times VL_HP. A target is
-- "v:<villager id>". Nothing happens without the Villagers mod (villagers.present is false).
VL_HP = 100                   -- a villager's whole health (a player's is 1)
VL_NOISE_VOL = 0.2            -- a villager's noise (0..1) as a sound's volume: yelling 0.2 (heard ~19 m), walking 0.06
VL_STRIKE_K = 0.5             -- a villager's blow (8-20 a punch, on their 100 scale) times this hurts a centipede

function wormIsVlTarget(tgt) return type(tgt) == "string" and string.sub(tgt, 1, 2) == "v:" end
function wormVlId(tgt) return string.sub(tgt, 3) end
function wormVlAlive(id) return GetBool("villagers.v." .. id .. ".alive") end
function wormVlChest(id)
	local b = "villagers.v." .. id .. "."
	return Vec(GetFloat(b .. "x"), GetFloat(b .. "y") + 1.0, GetFloat(b .. "z"))
end

-- the villagers alive, every 0.1 s: {id, pos (feet), chest, speed (from their last place), noise, carried}
function wormVlScan()
	local t = now()
	if t < (wormVlScanT or 0) then return end
	wormVlScanT = t + 0.1
	local list, known = {}, {}
	if GetBool("villagers.present") then
		for id in string.gmatch(GetString("villagers.list"), "[^,]+") do
			local b = "villagers.v." .. id .. "."
			if GetBool(b .. "alive") then
				local pos = Vec(GetFloat(b .. "x"), GetFloat(b .. "y"), GetFloat(b .. "z"))
				local old = wormVlKnown[id]
				local speed = 0
				if old and t > old.t then speed = 0.5 * old.speed + 0.5 * dist(pos, old.pos) / (t - old.t) end
				local v = {id = id, pos = pos, chest = VecAdd(pos, Vec(0, 1.0, 0)), speed = speed, t = t,
					noise = GetFloat(b .. "noise"), carried = GetBool(b .. "carried")}
				list[#list + 1] = v
				known[id] = v
			end
		end
	end
	wormVlList, wormVlKnown = list, known
end

-- prey nobody holds (its own carry counts as held: wormGrabbed)
function wormVlFree(v)
	return not wormGrabbed["v:" .. v.id] and not v.carried
end

function wormVlName(w)
	local kind = w.baby and "gcjuvenile" or (w.variant == "machina" and (w.hostileToHumans and "gcmachinared" or "gcmachina"))
		or ("gc" .. (w.variant or "acidica"))
	return VL_KINDS[kind] and VL_KINDS[kind][1] or "a giant centipede"
end

-- hurt a villager by `amount` of a player's health (0..1), from `from`, knocked back at `knock` m/s
function wormVlHurt(id, amount, w, from, knock)
	if amount <= 0 then return end
	local n = GetInt("villagers.hurt.last") + 1
	local b = "villagers.hurt." .. (n % 16) .. "."
	local f = from or (w and w.pos) or wormVlChest(id)
	SetString(b .. "target", id)
	SetString(b .. "shape", "")
	SetFloat(b .. "amount", amount * VL_HP)
	SetString(b .. "by", w and wormVlName(w) or "a giant centipede")
	SetFloat(b .. "x", f[1]); SetFloat(b .. "y", f[2]); SetFloat(b .. "z", f[3])
	SetFloat(b .. "knock", knock or 0)
	SetInt("villagers.hurt.last", n)
end

function wormVlCarry(id, p, w)
	local b = "villagers.carry." .. id .. "."
	SetFloat(b .. "x", p[1]); SetFloat(b .. "y", p[2]); SetFloat(b .. "z", p[3])
	SetString(b .. "by", w and wormVlName(w) or "a giant centipede")
end

function wormVlDrop(id) ClearKey("villagers.carry." .. id) end

-- a villager spun into a cocoon at the nest: held there, 30 s to live (as a player), cut free by a player with E
function wormCocoonVillager(w, id)
	local silkP = wormPickSilkSurfacePos(w, 0.50, 3.60)
	local pos = VecAdd(silkP, Vec(0, 0.48, 0))
	wormFilter()
	local hitDown, dDown = QueryRaycast(VecAdd(silkP, Vec(0, 1.2, 0)), Vec(0, -1, 0), 4.0)
	if hitDown then pos = VecAdd(silkP, Vec(0, 1.2 - dDown + 0.48, 0)) end
	local hp = GetFloat("villagers.v." .. id .. ".hp")
	wormVlCocoons[id] = {body = wormCocoonBody("v" .. id, pos, true, w.variant), pos = pos, t0 = GetTime(),
		hp0 = hp > 0 and hp or VL_HP, by = wormVlName(w), w = w}
	wormGrabbed["v:" .. id] = w
	w.ev.hiss = w.ev.hiss + 1
end

function wormVlCocoonTick(dt)
	local t = GetTime()
	for id, c in pairs(wormVlCocoons) do
		local alive = wormVlAlive(id)
		local intact = c.body ~= 0 and IsHandleValid(c.body) and not IsBodyBroken(c.body)
		local mid = VecAdd(c.pos, Vec(0, 0.4, 0))
		if alive and intact then
			for _, q in ipairs(GetAllPlayers()) do                  -- (a player cuts them free with E, as a cocooned player)
				if not wormPlayerCocoons[q] and GetPlayerHealth(q) > 0 and InputPressed("interact", q) and wormCanCut(q, mid) then
					for _, sh in ipairs(GetBodyShapes(c.body) or {}) do RemoveTag(sh, "unbreakable") end
					wormOwnHoleT = now()
					MakeHole(mid, 0.9, 0.9, 0.5, true)
					intact = false
					break
				end
			end
		end
		if not alive or not intact then
			wormVlCocoons[id] = nil
			wormVlDrop(id)
			wormGrabbed["v:" .. id] = nil
			if alive then                                            -- broken open: free, and left alone for a while
				wormGrabbed["v:" .. id] = true
				wormFreed["v:" .. id] = t + COCOON_FREE_T
			elseif c.body ~= 0 and IsHandleValid(c.body) then
				Delete(c.body)                                       -- (the one inside died: the cocoon goes)
			end
		else
			wormVlCarry(id, mid, c.w)
			if t >= (c.hurtT or 0) then                              -- (their health runs out over COCOON_TIME)
				c.hurtT = t + 0.5
				local want = c.hp0 * math.max(0, 1 - (t - c.t0) / COCOON_TIME)
				local hp = GetFloat("villagers.v." .. id .. ".hp")
				if hp - want > 0.5 or want <= 0 then
					local n = GetInt("villagers.hurt.last") + 1
					local b = "villagers.hurt." .. (n % 16) .. "."
					SetString(b .. "target", id); SetString(b .. "shape", "")
					SetFloat(b .. "amount", math.max(1, hp - want)); SetString(b .. "by", c.by)
					SetFloat(b .. "x", mid[1]); SetFloat(b .. "y", mid[2]); SetFloat(b .. "z", mid[3]); SetFloat(b .. "knock", 0)
					SetInt("villagers.hurt.last", n)
				end
			end
		end
	end
end

-- villagers' blows on a centipede (villagers.strike ring): hurt it as a player's would (a friendly Machina turns)
function wormVlStrikes()
	local last = GetInt("villagers.strike.last")
	while (wormVlStrikeSeen or last) < last do
		wormVlStrikeSeen = (wormVlStrikeSeen or last) + 1
		local b = "villagers.strike." .. (wormVlStrikeSeen % 16) .. "."
		local id = tonumber(string.match(GetString(b .. "thing"), "^gc(%d+)$") or "")
		local w = id and wormById(id)
		if w and w.alive then
			wormDamage(w, GetFloat(b .. "amount") * VL_STRIKE_K, "melee", Vec(GetFloat(b .. "x"), GetFloat(b .. "y"), GetFloat(b .. "z")))
		end
	end
	wormVlStrikeSeen = last
end

----- publishing -----

-- the trail's surface normals, one number each instead of three (octahedral: 8 bits a side, ~1 degree): the pack sent
-- 3 floats per trail point, doubling every creature's share of shared.worms (12 times a second, to every client).
-- WormView's wvUnpackNormals reads them back.
function wormPackNormals(n)
	local out = {}
	local abs, floor = math.abs, math.floor
	for i = 1, math.floor(#n / 3) do
		local k = 3 * i
		local x, y, z = n[k - 2], n[k - 1], n[k]
		local l = abs(x) + abs(y) + abs(z)
		if l < 1e-6 then x, y, z, l = 0, 1, 0, 1 end
		local u, v = x / l, z / l
		if y < 0 then
			u, v = (1 - abs(v)) * (u >= 0 and 1 or -1), (1 - abs(u)) * (v >= 0 and 1 or -1)
		end
		out[i] = floor((u * 0.5 + 0.5) * 255 + 0.5) * 256 + floor((v * 0.5 + 0.5) * 255 + 0.5)
	end
	return out
end

function wormPublish()
	wormSeq = wormSeq + 1
	local out = {n = wormSeq, acids = {}, eggs = {}, nests = {}, pc = {}, free = {}, marks = wormMarks or {}}
	for p, t in pairs(wormFreed) do
		out.free[#out.free + 1] = p
		out.free[#out.free + 1] = math.max(0, t - GetTime())
	end
	out.pcVar = {}
	for p, c in pairs(wormPlayerCocoons) do
		local k = #out.pc
		out.pc[k + 1], out.pc[k + 2], out.pc[k + 3], out.pc[k + 4], out.pc[k + 5] = p, c.pos[1], c.pos[2], c.pos[3], math.max(0, COCOON_TIME - (GetTime() - c.t0))
		out.pcVar[p] = c.variant or "acidica"
	end
	for i, a in ipairs(wormAcids) do
		out.acids[i] = {x = a.pos[1], y = a.pos[2], z = a.pos[3], kind = a.kind or "acid"}
	end
	for i, e in ipairs(wormEggs) do
		out.eggs[i] = {x = e.pos[1], y = e.pos[2], z = e.pos[3], variant = e.variant or "acidica"}
	end
	for i, ns in ipairs(wormNests) do
		out.nests[i] = {x = ns.pos[1], y = ns.pos[2], z = ns.pos[3], repairing = ns.repairing and true or false, tier = ns.tier or 1, variant = ns.variant or "acidica"}
	end
	for i, w in ipairs(wormList) do
		-- Stealth bioluminescence: completely dark (0) while lurking, stalking, chasing, or dragging;
		-- only glows when winding up / lunging or spitting acid
		local glow = 0
		local spittingNow = ((w.spitCd or 0) - now()) > (SPIT_CD - 0.65)
		if w.alive then
			if w.variant == "machina" then
				glow = (w.state == "windup" or w.state == "lunge" or spittingNow or w.hostileToHumans) and 1.0 or 0.65
			elseif w.state == "windup" or w.state == "lunge" or spittingNow or (now() - (w.seismicT or -100) < 1.2) then
				glow = 1.0
			end
		end
		local maxL = w.bodyLen or BODY_LEN
		local trPts, trNorms = wormSample(w, TRAIL_PUB, maxL + 1, true)
		trNorms = wormPackNormals(trNorms)
		local u = w.up or Vec(0, 1, 0)
		out[i] = {id = w.id, alive = w.alive, state = w.state, trail = trPts, norms = trNorms,
			len = maxL, mouth = w.mouth, glow = glow,
			hurt = w.hurtT, grab = type(w.grab) == "number" and w.grab or 0, t = now(), speed = w.speed, deadT = w.deadT,
			burning = (w.variant ~= "ignitus" and w.variant ~= "machina" and now() < (w.burnUntil or 0)), baby = w.baby and true or false, variant = w.variant or "acidica",
			scale = w.scale or (w.baby and BABY_SCALE or 1.0), growthStage = w.growthStage or 0,
			hostile = w.hostileToHumans and true or false,
			bite = w.ev.bite, lunge = w.ev.lunge, hiss = w.ev.hiss, grabs = w.ev.grab, hurts = w.ev.hurt,
			die = w.ev.die, spit = w.ev.spit or 0, empT = w.empT or -100, seismicT = w.seismicT or -100, fx = w.fwd[1], fy = w.fwd[2], fz = w.fwd[3],
			ux = u[1], uy = u[2], uz = u[3],
			esc = w.dmgInDrag / RELEASE_DMG, hits = w.hits or {}}
	end
	shared.worms = out
	shared.wormsN = wormSeq                                    -- (the clients read the table only when this changed)
end

----- callbacks -----

function Worm.serverInit()
	local rings = GetInt("savegame.mod.nestrings")
	if rings >= 3 and rings <= 10 then NEST_MAX_TIER = rings end
	wormList = {}
	wormHitShapes = {}
	wormNestShapes = {}
	wormGrabbed = {}
	wormCocoons = {}
	wormPlayerCocoons = {}
	wormFreed = {}
	wormAcids = {}
	wormEggs = {}
	wormNests = {}
	wormNextId = 1
	wormSeq = 0
	wormPubT = 0
	wormSenseT = 0
	wormMaskT = 0
	wormLearnT = 0
	wormSpawnSearch = nil
	wormRespawnAt = {}
	wormSpawnerTrack = {}
	wormLastMenuSpawnT = -100
	wormHitpointsLast = nil
	wormLastLhShotSeq = nil
	wormLastLhSwingSeq = nil
	wormNpcList, wormNpcKnown, wormNpcScanT = {}, {}, 0
	wormLifeT, wormEcoT = 0, 0
	wormLightList = nil
	SetString("silkmaw.hitpoints", "")
	SetString("silkmaw.damage", "")
	wormVillagersInit()
	wormVlT = 0
	wormVlCocoons, wormVlList, wormVlKnown, wormVlScanT = {}, {}, {}, 0
	wormVlStrikeSeen = GetInt("villagers.strike.last")
	WORM_COUNT = 0
	if WORM_PARTS then
		local L = WORM_PARTS.head.len or 1
		for _, s in ipairs(WORM_PARTS.segments) do L = L + s.len end
		local tailL = (WORM_PARTS.tail and WORM_PARTS.tail.len) or 0
		BODY_LEN = L + tailL
		HIT_BOXES = math.max(4, math.ceil(BODY_LEN / HIT_SPACING))   -- (the hit boxes as long as the body)
		-- Juveniles have 50% the number of segments as adults (20 vs 40), scaled by BABY_SCALE
		local babyL = (WORM_PARTS.head.len or 1) + tailL
		local totalSegs = #WORM_PARTS.segments
		for i = 1, totalSegs, 4 do
			if WORM_PARTS.segments[i] then babyL = babyL + WORM_PARTS.segments[i].len end
			if WORM_PARTS.segments[i + 1] then babyL = babyL + WORM_PARTS.segments[i + 1].len end
		end
		BABY_BODY_LEN = babyL * BABY_SCALE
	end
	for _, b in ipairs(FindBodies("silkmawhit", true) or {}) do Delete(b) end
	for _, b in ipairs(FindBodies("silkmawegg", true) or {}) do Delete(b) end
	for _, b in ipairs(FindBodies("silkmawnest", true) or {}) do Delete(b) end
	for _, b in ipairs(FindBodies("silkmawcocoon", true) or {}) do Delete(b) end
	-- (the pathfinding's per-frame budget and search limits as in Silkmaw 1.0.3 / Abyssipede: the pack's 40-50% larger
	--  budget and 6x detours cost the host more every frame; the dearer dig (28) stays: fewer bites, fewer holes to sync)
	Nav.init({cell = 0.5, radius = 0.3, budget = 300, maxNodes = 6000, digCost = 28, mask = WORM_QUERY_MASK})
	shared.worms = {n = 0, acids = {}, eggs = {}, nests = {}}
	shared.wormsN = 0
end

function wormSpawnTick()
	-- Automatic spawning disabled: centipedes only spawn when placed via the Spawn Menu (or hatched from nests)
end

SPAWN_MARK_T = 7              -- s from the spawn menu's marker appearing to the worm coming out of it

-- spawn-menu worms: the marker (prefab/spawner.xml) stays where it was put, and after SPAWN_MARK_T s a worm comes
-- out of it there (wherever it has rolled to by then). wormMarks = {x, y, z, seconds left, ...} goes to the clients
-- with shared.worms, for the countdown over each marker.
function wormSpawnMenu()
	local t = now()
	local seen, marks = {}, {}
	for _, b in ipairs(FindBodies("silkmawspawn", true) or {}) do
		seen[b] = true
		-- (the spawn menu's preview before the click is a marker too: the menu spawns it with its shapes on collision
		--  layer 0, mask 0, and the click spawns the real one (mask 255). The countdown starts on the real one.)
		local m = wormSpawnerTrack[b]
		if not m then
			m = {}
			wormSpawnerTrack[b] = m
		end
		if not m.t0 then
			local shapes = GetBodyShapes(b) or {}
			local preview = #shapes > 0
			for _, sh in ipairs(shapes) do
				local _, mask = GetShapeCollisionFilter(sh)
				if (mask or 0) ~= 0 then preview = false end
			end
			if not preview then m.t0 = t end
		end
		local pos = GetBodyTransform(b).pos
		local left = SPAWN_MARK_T - (t - (m.t0 or t))
		if not m.t0 then
			-- (a preview: nothing yet)
		elseif left <= 0 then
			local isIgnitus = HasTag(b, "silkmawspawn_ignitus")
			local isMachina = HasTag(b, "silkmawspawn_machina")
			local isSeismica = HasTag(b, "silkmawspawn_seismica")
			if not isIgnitus and not isMachina and not isSeismica then
				for _, sh in ipairs(GetBodyShapes(b) or {}) do
					if HasTag(sh, "silkmawspawn_ignitus") then isIgnitus = true; break end
					if HasTag(sh, "silkmawspawn_machina") then isMachina = true; break end
					if HasTag(sh, "silkmawspawn_seismica") then isSeismica = true; break end
				end
			end
			Delete(b)
			wormSpawnerTrack[b] = nil
			local alive = 0
			for _, w in ipairs(wormList) do if w.alive then alive = alive + 1 end end
			if alive < WORM_MAX then
				local var = isSeismica and "seismica" or (isMachina and "machina" or (isIgnitus and "ignitus" or "acidica"))
				wormList[#wormList + 1] = wormNew(VecAdd(pos, Vec(0, 0.55, 0)), false, nil, var)
			end
		else
			local k = #marks
			marks[k + 1], marks[k + 2], marks[k + 3], marks[k + 4] = pos[1], pos[2], pos[3], left
		end
	end
	for b in pairs(wormSpawnerTrack) do
		if not seen[b] then wormSpawnerTrack[b] = nil end
	end
	wormMarks = marks
end

function Worm.serverTick(dt)
	local t = now()
	Nav.tick()
	wormNpcScan()
	wormVlScan()
	wormVlStrikes()
	local tenth = math.floor(t * 10) ~= math.floor((t - dt) * 10)
	if tenth then wormSpawnMenu() end
	-- (pieces of broken hit boxes: a search of the whole scene, so every 2 s, not 10 times a second)
	if math.floor(t * 0.5) ~= math.floor((t - dt) * 0.5) then wormSweepOrphanHitboxes() end
	wormTakeHits()
	wormTakeVehicles()
	wormTakeFire(dt)
	wormTakeNpcAttacks()
	wormTakeApiDamage()
	wormAcidTick(dt)
	wormLifecycleTick()
	for _, w in ipairs(wormList) do if w.nestGrow then wormNestGrowStep(w) end end   -- (rings grow over frames)
	wormCocoonTick(dt)
	wormPlayerCocoonTick(dt)
	wormVlCocoonTick(dt)
	wormPodSweep()
	wormEcoPublishTick()
	local sv, sp = GetLastSound()
	if sv and sv > 0.03 and sp and (not wormHeard or sv > wormHeard.vol) then wormHeard = {vol = sv, pos = VecCopy(sp)} end
	local sense = t - wormSenseT > 1 / SENSE_HZ
	if sense then wormSenseT = t end
	for i = #wormList, 1, -1 do
		local w = wormList[i]
		if w.alive then
			if sense then
				wormSense(w)
				w.far = wormNearest(w)
			end
			wormBoxesMove(w)
			if tenth then
				wormBoxesCheck(w)
				if not w.baby then Nav.markFree(w.pos) end
			end
		elseif t - w.deadT > CORPSE_T then
			ClearKey(ECO_REG .. ".silkmaw_" .. tostring(w.id))
			wormVillagersClear(w)
			table.remove(wormList, i)
		end
	end
	if sense then wormHeard = nil end
	wormPublishHitpoints()
	if t - wormMaskT > 0.25 then
		wormMaskT = t
		for _, p in ipairs(GetAllPlayers()) do
			local m = GetPlayerParam("CollisionMask", p)
			if type(m) == "number" and math.floor(m / WORM_LAYER) % 2 == 1 then SetPlayerParam("CollisionMask", m - WORM_LAYER, p) end
		end
	end
	if t - wormLearnT > 0.5 then
		wormLearnT = t
		for _, p in ipairs(GetAllPlayers()) do
			if GetPlayerHealth(p) > 0 and GetPlayerVehicle(p) == 0 then Nav.markFree(wormChest(p)) end
		end
	end
	if t - wormPubT >= 1 / PUBLISH_HZ then
		wormPubT = t
		wormPublish()
	end
	wormVillagersTick()
end

-- A juvenile's movement costs as much as an adult's (about 7 engine queries a step, measured), and there are many of
-- them: they are stepped every BABY_UPDATE_EVERY-th update with the time of all of them, each on its own turn.
BABY_UPDATE_EVERY = 3

function Worm.serverUpdate(dt)
	wormUpdN = (wormUpdN or 0) + 1
	for _, w in ipairs(wormList) do
		if not w.baby then
			wormUpdate(w, dt)
		elseif (wormUpdN + w.id) % BABY_UPDATE_EVERY == 0 then
			wormUpdate(w, dt * BABY_UPDATE_EVERY)
		end
	end
end

function Worm.serverPostUpdate()
	for _, w in ipairs(wormList) do
		if w.alive and w.grab ~= 0 then wormHold(w) end
	end
end
