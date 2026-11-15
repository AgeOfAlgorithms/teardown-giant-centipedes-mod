-- WormView: what each machine draws and hears of the worms (PROJECT.md: Interfaces). Every client spawns its own
-- body parts (static bodies in WORM_LAYER, colliding with nothing) and poses them along the trail the server
-- publishes in shared.worms, 1/PUBLISH_HZ s in the past so it can blend between two updates. On top, per machine:
-- the life in it (a writhe along the body and twitches and ripples, stronger when it stands still, the legs'
-- walking wave or scrabbling, antennae probing and flicking, the head looking round in jerks, the claws flicking),
-- an erratic tremor (worse when it hunts), the glow pulses travelling along its patterns (SetShapeEmissiveScale per
-- part plus a few point lights), the death throes, and the sounds.

WormView = {}

VIEW_PARK = Vec(0, -1000, 0)
WV_ZERO = {0, 0, 0}             -- (read only)
SOUND_KINDS = {"chitter", "click", "hiss", "shriek", "snap", "slither", "growl", "grab", "hurt", "death", "idle"}

local function dist(a, b) return VecLength(VecSub(a, b)) end

function wvLoadSounds()
	wvSnd = {}
	local S = WORM_SOUNDS or {}
	for _, k in ipairs(SOUND_KINDS) do
		wvSnd[k] = {}
		for _, f in ipairs(S[k] or {}) do
			if k == "slither" or k == "idle" then wvSnd[k][#wvSnd[k] + 1] = LoadLoop(f) else wvSnd[k][#wvSnd[k] + 1] = LoadSound(f) end
		end
	end
end

function wvPlay(kind, pos, vol)
	local l = wvSnd[kind]
	if not l or #l == 0 then return end
	PlaySound(l[math.random(#l)], pos, vol or 1, false, 0.88 + math.random() * 0.24)
end

-- a limb model placed with its pivot on hinge (both in the part's local metres, scaled by sc): the <vox> element and, once
-- spawned, the record that turns it about the hinge (wvLimb)
local function limbXml(d, hinge, tag, sc, variant)
	sc = sc or 1.0
	return string.format("<vox tags='nocull unbreakable %s' file='%s' scale='%.2f' pos='%.3f %.3f %.3f'/>", tag, wvVoxFile(d.file, variant), sc,
		(hinge[1] - d.pivot[1]) * sc, (hinge[2] - d.pivot[2]) * sc, (hinge[3] - d.pivot[3]) * sc)
end

local function limbsOf(body, defs)
	local out = {}
	for _, s in ipairs(GetBodyShapes(body)) do
		for _, d in ipairs(defs) do
			if HasTag(s, d.tag) then
				out[#out + 1] = {shape = s, rest = GetShapeLocalTransform(s), hinge = Vec(d.hinge[1], d.hinge[2], d.hinge[3]),
					sign = d.sign, k = d.k, tw = 0, twA = 0, twB = 0}
			end
		end
	end
	return out
end

-- turn a limb about its hinge by R (rotations in its part's frame)
function wvLimb(l, R)
	SetShapeLocalTransform(l.shape, Transform(VecAdd(l.hinge, QuatRotateVec(R, VecSub(l.rest.pos, l.hinge))),
		QuatRotateQuat(R, l.rest.rot)))
end

-- the parts of one worm: {head = body, jaws, ants = {limb}, segs = {{body, shapes, arc, len, legs = {limb}}}}
-- Juveniles (isBaby = true) are spawned at 20% of the adult's size (sc = 0.20)
function wvVoxFile(path, variant)
	if variant == "ignitus" and path then
		return string.gsub(path, "MOD/vox/", "MOD/vox_ignitus/")
	elseif variant == "machina" and path then
		return string.gsub(path, "MOD/vox/", "MOD/vox_machina/")
	elseif variant == "machina_hostile" and path then
		return string.gsub(path, "MOD/vox/", "MOD/vox_machina_hostile/")
	elseif variant == "seismica" and path then
		return string.gsub(path, "MOD/vox/", "MOD/vox_seismica/")
	end
	return path
end

-- the Machina pulse and the Seismica quake rings add their particles at most this often (the pack: every frame,
-- so ~4,700 particles a quake at 144 fps)
WV_RING_DT = 1 / 30

function wvSpawn(isBaby, variant, customScale)
	variant = variant or "acidica"
	local P = WORM_PARTS
	local sc = customScale or (isBaby and 0.20 or 1.0)
	local v = {baby = isBaby and true or false, variant = variant, scale = sc, segs = {}, jaws = {}, ants = {}, phase = math.random() * 100,
		flick = {}, travel = 0, idlePh = 0, still = 0, tw = {}, look = {y = 0, p = 0, ty = 0, tp = 0, next = 0}}
	local function spawnBody(xml)
		local ents = Spawn(xml, Transform(VIEW_PARK), true)
		for _, e in ipairs(ents or {}) do
			if GetEntityType(e) == "body" then
				for _, s in ipairs(GetBodyShapes(e)) do SetShapeCollisionFilter(s, WORM_LAYER, 0) end
				return e
			end
		end
		return 0
	end
	if P then
		local h = P.head
		local xml = string.format("<body tags='silkmawview nocull'><vox tags='nocull unbreakable bobhead' file='%s' scale='%.2f'/>", wvVoxFile(h.file, variant), sc)
		local jawDefs, antDefs = {}, {}
		for _, side in ipairs({"l", "r"}) do
			local sign = side == "l" and 1 or -1
			local j, hinge = P["jaw_" .. side], h["hinge_" .. side]
			if j and hinge then
				local shinge = {hinge[1] * sc, hinge[2] * sc, hinge[3] * sc}
				xml = xml .. limbXml(j, hinge, "bobjaw" .. side, sc, variant)
				jawDefs[#jawDefs + 1] = {tag = "bobjaw" .. side, hinge = shinge, sign = sign}
			end
			local a, sock = P["antenna_" .. side], h["ant_" .. side]
			if a and sock then
				local ssock = {sock[1] * sc, sock[2] * sc, sock[3] * sc}
				xml = xml .. limbXml(a, sock, "bobant" .. side, sc, variant)
				antDefs[#antDefs + 1] = {tag = "bobant" .. side, hinge = ssock, sign = sign}
			end
		end
		v.head = spawnBody(xml .. "</body>")
		v.headLen = (h.len or 1) * sc
		v.jaws = limbsOf(v.head, jawDefs)
		v.ants = limbsOf(v.head, antDefs)
		local arc = v.headLen / 2
		local list = {}
		if isBaby then
			-- Juveniles have 50% the number of segments as adults (20 vs 40), sampling 2 per taper class so the body still tapers smoothly
			local totalSegs = #P.segments
			for i = 1, totalSegs, 4 do
				if P.segments[i] then list[#list + 1] = P.segments[i] end
				if P.segments[i + 1] then list[#list + 1] = P.segments[i + 1] end
			end
		else
			for _, s in ipairs(P.segments) do list[#list + 1] = s end
		end
		if P.tail then list[#list + 1] = P.tail end
		local pair = 0
		for i, s in ipairs(list) do
			local slen = s.len * sc
			arc = arc + slen / 2
			local xml = string.format("<body tags='silkmawview nocull'><vox tags='nocull unbreakable' file='%s' scale='%.2f'/>", wvVoxFile(s.file, variant), sc)
			local defs = {}
			local L, R = nil, nil
			if s.leg and P.legs and P.legs[s.leg] then L, R = P.legs[s.leg].l, P.legs[s.leg].r end
			if s.ult_l then L, R = s.ult_l, s.ult_r end
			if L and s.hip then
				pair = pair + 1
				local hl, hr = s.hip, {-s.hip[1], s.hip[2], s.hip[3]}
				local shl = {hl[1] * sc, hl[2] * sc, hl[3] * sc}
				local shr = {hr[1] * sc, hr[2] * sc, hr[3] * sc}
				xml = xml .. limbXml(L, hl, "boblegl", sc, variant) .. limbXml(R, hr, "boblegr", sc, variant)
				defs = {{tag = "boblegl", hinge = shl, sign = 1, k = pair}, {tag = "boblegr", hinge = shr, sign = -1, k = pair}}
			end
			local b = spawnBody(xml .. "</body>")
			v.segs[i] = {body = b, shapes = GetBodyShapes(b), arc = arc, len = slen, r = (s.radius or 0.25) * sc,
				legs = limbsOf(b, defs), ult = s.ult_l ~= nil}
			arc = arc + slen / 2
		end
	else                                                         -- (no model: plain boxes, for tests)
		v.head = spawnBody("<body tags='silkmawview'><voxbox size='6 6 10' pos='-0.3 -0.3 -0.5' color='0.1 0.05 0.12'/></body>")
		v.headLen = 1 * sc
		local arc = 0.5 * sc
		for i = 1, (isBaby and 20 or 40) do
			arc = arc + 0.19 * sc
			local b = spawnBody("<body tags='silkmawview'><voxbox size='5 5 4' pos='-0.25 -0.25 -0.2' color='0.1 0.05 0.12'/></body>")
			v.segs[i] = {body = b, shapes = GetBodyShapes(b), arc = arc, len = 0.38 * sc, r = 0.25 * sc}
			arc = arc + 0.19 * sc
		end
	end
	for i = 1, #v.segs do v.flick[i] = {phase = math.random() * 6.28, off = 0} end
	return v
end

function wvDelete(v)
	if v.head and v.head ~= 0 then Delete(v.head) end
	for _, s in ipairs(v.segs) do if s.body ~= 0 then Delete(s.body) end end
end

-- position and forward (toward the head) at arc length s along a flat trail list
function wvAt(tr, s)
	local n = #tr / 3
	if n < 2 then
		local p = Vec(tr[1] or 0, tr[2] or 0, tr[3] or 0)
		return p, Vec(0, 0, 1)
	end
	local acc = 0
	for k = 1, n - 1 do
		local a = Vec(tr[3 * k - 2], tr[3 * k - 1], tr[3 * k])
		local b = Vec(tr[3 * k + 1], tr[3 * k + 2], tr[3 * k + 3])
		local l = dist(a, b)
		if acc + l >= s or k == n - 1 then
			local f = l > 0.0001 and math.min(1, math.max(0, (s - acc) / l)) or 0
			local fw = l > 0.0001 and VecScale(VecSub(a, b), 1 / l) or Vec(0, 0, 1)
			return VecLerp(a, b, f), fw
		end
		acc = acc + l
	end
end

-- a rotation whose local +z is fwd (the models' front) and local +y is aligned to the surface normal `up`, rolled by `roll` radians
function wvRot(fwd, roll, up)
	local fx, fy, fz = fwd[1], fwd[2], fwd[3]
	local ux, uy, uz = 0, 1, 0
	if up then ux, uy, uz = up[1], up[2], up[3] end
	-- x = normalize(up x fwd)
	local x1, x2, x3 = uy * fz - uz * fy, uz * fx - ux * fz, ux * fy - uy * fx
	local l = math.sqrt(x1 * x1 + x2 * x2 + x3 * x3)
	if l < 1e-4 then
		if math.abs(fy) > 0.97 then x1, x2, x3 = 0, -fz, fy else x1, x2, x3 = fz, 0, -fx end
		l = math.sqrt(x1 * x1 + x2 * x2 + x3 * x3)
		if l < 1e-9 then l = 1 end
	end
	x1, x2, x3 = x1 / l, x2 / l, x3 / l
	local y1, y2, y3 = fy * x3 - fz * x2, fz * x1 - fx * x3, fx * x2 - fy * x1
	local c, s = math.cos(roll), math.sin(roll)
	return QuatAlignXZ({x1 * c + y1 * s, x2 * c + y2 * s, x3 * c + y3 * s}, fwd)
end

-- The trail walked once per frame for every body part (wvAt started at the head again for each of the 42 parts
-- and made vectors at every step: the biggest share of the pose's cost, measured in-game 2026-11-11): wvWalk
-- measures the trail's legs once, wvAtW keeps its place between calls (the parts come in rising arc length; a
-- smaller s starts over). Position and forward (toward the head) at arc length s, as wvAt gives them.
function wvWalk(tr, nm)
	local n = math.floor(#tr / 3)
	local L = {}
	for k = 1, n - 1 do
		local i = 3 * k
		local dx, dy, dz = tr[i - 2] - tr[i + 1], tr[i - 1] - tr[i + 2], tr[i] - tr[i + 3]
		L[k] = math.sqrt(dx * dx + dy * dy + dz * dz)
	end
	return {tr = tr, nm = nm, n = n, L = L, k = 1, acc = 0}
end

function wvAtW(wk, s)
	local tr, nm, n, L = wk.tr, wk.nm, wk.n, wk.L
	if n < 2 then
		local u = (nm and #nm >= 3) and {nm[1], nm[2], nm[3]} or {0, 1, 0}
		return {tr[1] or 0, tr[2] or 0, tr[3] or 0}, {0, 0, 1}, u
	end
	if s < wk.acc then wk.k, wk.acc = 1, 0 end
	local k, acc = wk.k, wk.acc
	while k < n - 1 and acc + L[k] < s do
		acc = acc + L[k]
		k = k + 1
	end
	wk.k, wk.acc = k, acc
	local l = L[k]
	local i = 3 * k
	local ax, ay, az, bx, by, bz = tr[i - 2], tr[i - 1], tr[i], tr[i + 1], tr[i + 2], tr[i + 3]
	local f = l > 0.0001 and ((s - acc) / l) or 0
	if f < 0 then f = 0 end
	local ux, uy, uz = 0, 1, 0
	if nm and #nm >= i + 3 then
		ux = nm[i - 2] + (nm[i + 1] - nm[i - 2]) * f
		uy = nm[i - 1] + (nm[i + 2] - nm[i - 1]) * f
		uz = nm[i] + (nm[i + 3] - nm[i]) * f
		local ul = math.sqrt(ux * ux + uy * uy + uz * uz)
		if ul > 1e-4 then ux, uy, uz = ux / ul, uy / ul, uz / ul else ux, uy, uz = 0, 1, 0 end
	end
	if l <= 0.0001 then return {ax, ay, az}, {0, 0, 1}, {ux, uy, uz} end
	return {ax + (bx - ax) * f, ay + (by - ay) * f, az + (bz - az) * f}, {(ax - bx) / l, (ay - by) / l, (az - bz) / l}, {ux, uy, uz}
end

-- wvAtW without tables: x, y, z, fx, fy, fz, ux, uy, uz
function wvAtN(wk, s)
	local tr, nm, n, L = wk.tr, wk.nm, wk.n, wk.L
	if n < 2 then
		local ux, uy, uz = 0, 1, 0
		if nm and #nm >= 3 then ux, uy, uz = nm[1], nm[2], nm[3] end
		return tr[1] or 0, tr[2] or 0, tr[3] or 0, 0, 0, 1, ux, uy, uz
	end
	if s < wk.acc then wk.k, wk.acc = 1, 0 end
	local k, acc = wk.k, wk.acc
	while k < n - 1 and acc + L[k] < s do
		acc = acc + L[k]
		k = k + 1
	end
	wk.k, wk.acc = k, acc
	local l = L[k]
	local i = 3 * k
	local ax, ay, az, bx, by, bz = tr[i - 2], tr[i - 1], tr[i], tr[i + 1], tr[i + 2], tr[i + 3]
	local f = l > 0.0001 and ((s - acc) / l) or 0
	if f < 0 then f = 0 end
	local ux, uy, uz = 0, 1, 0
	if nm and #nm >= i + 3 then
		ux = nm[i - 2] + (nm[i + 1] - nm[i - 2]) * f
		uy = nm[i - 1] + (nm[i + 2] - nm[i - 1]) * f
		uz = nm[i] + (nm[i + 3] - nm[i]) * f
		local ul = math.sqrt(ux * ux + uy * uy + uz * uz)
		if ul > 1e-4 then ux, uy, uz = ux / ul, uy / ul, uz / ul else ux, uy, uz = 0, 1, 0 end
	end
	if l <= 0.0001 then return ax, ay, az, 0, 0, 1, ux, uy, uz end
	return ax + (bx - ax) * f, ay + (by - ay) * f, az + (bz - az) * f, (ax - bx) / l, (ay - by) / l, (az - bz) / l, ux, uy, uz
end

-- blend two published trails (same order: head first)
function wvBlend(a, b, f)
	if not a then return b end
	local out = {}
	for i = 1, #b do
		local x = a[i]
		out[i] = x and (x + (b[i] - x) * f) or b[i]
	end
	return out
end

function WormView.clientInit()
	wvViews = {}
	wvLastN = -1
	wvW, wvTook, wvFrame, wvCam = false, false, 0, Vec(0, 0, 0)
	wvSnaps = {}
	wvLoadSounds()
end

-- the trail's surface normals come one number each (wormPackNormals, octahedral, 8 bits a side): back to a flat
-- x, y, z list as the pose reads it. Done once per snapshot, not per frame.
function wvUnpackNormals(p)
	local out = {}
	local abs, sqrt, floor = math.abs, math.sqrt, math.floor
	for i = 1, #p do
		local q = p[i]
		local u = floor(q / 256) / 255 * 2 - 1
		local v = (q % 256) / 255 * 2 - 1
		local y = 1 - abs(u) - abs(v)
		if y < 0 then
			u, v = (1 - abs(v)) * (u >= 0 and 1 or -1), (1 - abs(u)) * (v >= 0 and 1 or -1)
		end
		local l = sqrt(u * u + y * y + v * v)
		if l < 1e-6 then u, y, v, l = 0, 1, 0, 1 end
		local k = 3 * i
		out[k - 2], out[k - 1], out[k] = u / l, y / l, v / l
	end
	return out
end

function wvTake()
	wvTook = false
	if shared.wormsN == wvLastN then return end                  -- (a number: reading shared.worms copies all of it)
	local W = shared.worms   -- (the one read of the table, when it changed)
	if not W or W.n == wvLastN then return end
	wvLastN = W.n
	wvW, wvTook = W, true
	local t = GetTime()
	for i = 1, #W do
		local w = W[i]
		local s = wvSnaps[w.id] or {}
		s.prev = s.cur
		s.prevT = s.curT
		local c = {}
		for k, x in pairs(w) do c[k] = x end                       -- (copy: shared hands out copies, keep ours)
		if type(c.norms) == "table" then c.norms = wvUnpackNormals(c.norms) end
		s.cur = c
		s.curT = t
		s.seen = t
		wvSnaps[w.id] = s
	end
end

function wvSounds(v, w, s, head, dt)
	local t = GetTime()
	local prev = v.ev or {}
	local function fired(k) return (w[k] or 0) > (prev[k] or 0) end
	if v.ev then
		if fired("bite") then
			wvPlay("snap", head, 1)
			local d = dist(GetCameraTransform().pos, head)
			if d < 12 then ShakeCamera(0.5 * (1 - d / 12)) end
		end
		if fired("lunge") then wvPlay("shriek", head, 1) end
		if fired("spit") then wvPlay("hiss", head, 1.0); wvPlay("snap", head, 0.8) end
		if fired("hiss") then wvPlay("hiss", head, 0.9) end
		if fired("grabs") then wvPlay("grab", head, 1) end
		if fired("hurts") and t - (v.hurtSndT or 0) > 0.3 then v.hurtSndT = t; wvPlay("hurt", head, 0.9) end
		if fired("die") then wvPlay("death", head, 1) end
	end
	v.ev = {bite = w.bite, lunge = w.lunge, hiss = w.hiss, grabs = w.grabs, hurts = w.hurts, die = w.die, spit = w.spit}
	if not w.alive then return end
	local loop = wvSnd.slither and wvSnd.slither[1]
	if loop then PlayLoop(loop, head, math.min(1, 0.15 + (w.speed or 0) / 8), false) end
	local idle = wvSnd.idle and wvSnd.idle[1]
	if idle then PlayLoop(idle, head, w.variant == "machina" and 0.85 or 0.5, false) end
	if w.variant == "machina" then
		local spd = w.speed or 0
		local chugGap = math.max(0.11, 0.42 - spd * 0.045)
		if t > (v.chugT or 0) then
			v.chugT = t + chugGap
			wvPlay("click", head, math.min(1.0, 0.45 + spd * 0.08))
			if math.random() < 0.35 then wvPlay("chitter", head, 0.4) end
		end
	end
	if t > (v.nextVoice or 0) then
		local st = w.state
		local gap = st == "lurk" and 4 + math.random() * 8 or (st == "stalk" and 2 + math.random() * 3 or 1 + math.random() * 2)
		v.nextVoice = t + gap
		local r = math.random()
		if st == "lurk" and r < 0.12 then wvPlay("growl", head, 1)
		elseif r < 0.55 then wvPlay("chitter", head, st == "lurk" and 0.6 or 0.85)
		else wvPlay("click", head, st == "lurk" and 0.55 or 0.8) end
	end
end

-- a puff of its green ichor where it was hit (bigger for a bigger hit): a faintly glowing cloud that swells and
-- hangs in the water, and a spray of droplets
local function rnd() return Vec(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) end

function wvIchor(pos, dmg, variant)
	local k = math.min(1, 0.3 + dmg / 30)
	local isIgn = (variant == "ignitus")
	local isMach = (variant == "machina")
	local isSeis = (variant == "seismica")
	ParticleReset()
	ParticleType("smoke")
	if isSeis then
		ParticleColor(0.45, 0.36, 0.25, 0.22, 0.18, 0.13)
	elseif isMach then
		ParticleColor(0.18, 0.20, 0.22, 0.05, 0.05, 0.06)
	elseif isIgn then
		ParticleColor(1.0, 0.35, 0.08, 0.25, 0.06, 0.02)
	else
		ParticleColor(0.2, 0.6, 0.12, 0.04, 0.14, 0.03)
	end
	ParticleRadius(0.12 + 0.15 * k, 0.4 + 0.5 * k, "easeout")
	ParticleAlpha(0.9, 0, "easein")
	ParticleEmissive(0.5, 0, "easeout")
	ParticleGravity(-0.1)
	ParticleDrag(0.7)
	ParticleCollide(0)
	for _ = 1, math.floor(4 + 8 * k) do
		SpawnParticle(VecAdd(pos, VecScale(rnd(), 0.3)), VecScale(rnd(), 1.5 + 2 * k), 2 + 2.5 * math.random())
	end
	ParticleReset()
	ParticleType("plain")
	if isSeis then
		ParticleColor(1.0, 0.78, 0.22, 0.55, 0.38, 0.12)
	elseif isMach then
		ParticleColor(0.35, 0.92, 1.0, 1.0, 0.75, 0.2)
	elseif isIgn then
		ParticleColor(1.0, 0.55, 0.1, 0.6, 0.12, 0.02)
	else
		ParticleColor(0.3, 0.9, 0.2, 0.05, 0.25, 0.04)
	end
	ParticleRadius(0.035, 0.015)
	ParticleAlpha(1, 0)
	ParticleEmissive(1, 0)
	ParticleGravity(-2.5)
	ParticleDrag(0.4)
	for _ = 1, math.floor(6 + 14 * k) do
		SpawnParticle(pos, VecScale(rnd(), 4 + 6 * k), 0.5 + 0.7 * math.random())
	end
end

-- the hits since the last snapshot (the server keeps the last few: hits = {seq, x, y, z, damage, ...})
function wvHits(v, w)
	local h = w.hits
	if not h then v.hitSeq = v.hitSeq or 0; return end
	local last = v.hitSeq or -1
	for i = 1, #h, 5 do
		if h[i] > last then
			if v.hitSeq then wvIchor(Vec(h[i + 1], h[i + 2], h[i + 3]), h[i + 4], w.variant) end   -- (none for hits from before we came)
			last = math.max(last, h[i])
		end
	end
	v.hitSeq = math.max(last, v.hitSeq or 0)
end

-- a burst of life somewhere along the body: a jerk sideways or up that snaps out and eases back, or (run > 0) a
-- bulge rippling toward the tail
function wvNewTwitch(v, len, still, agit)
	local tw = {c = 0.3 + math.random() * math.max(0.5, len - 0.3), wd = 0.9 + math.random() * 2.0,
		amp = (0.02 + math.random() * 0.045) * (0.5 + 0.5 * still + 0.3 * agit), a = math.random() * 6.283,
		t0 = GetTime(), dur = 0.25 + math.random() * 0.4, run = 0}
	if math.random() < 0.3 then
		tw.run = 4 + math.random() * 5
		tw.c = math.random() * 2
		tw.dur = math.max(0.5, len - tw.c) / tw.run
	end
	v.tw[#v.tw + 1] = tw
end

function wvTwitchAt(tw, s, t)
	local u = (t - tw.t0) / tw.dur
	if u < 0 or u > 1 then return 0 end
	local e = (s - tw.c - tw.run * (t - tw.t0)) / tw.wd
	if e > 3 or e < -3 then return 0 end
	local f
	if tw.run > 0 then f = math.sin(math.pi * u) elseif u < 0.2 then f = u / 0.2 else f = ((1 - u) / 0.8) ^ 2 end
	return tw.amp * f * math.exp(-e * e)
end

-- a ring's legs: a walking wave along the body driven by how far it has moved; when it stands still (stuck,
-- frozen, waiting) the legs keep scrabbling, faster when it hunts; single legs jerk on their own; the tail's long
-- ultimate legs sway; dead, they flail and then curl under
WV_LEG_STEPS = 64                                              -- steps of the baked walking cycle
WV_LEG_K = WV_LEG_STEPS / (2 * math.pi)
WV_JIT = {}                                                    -- baked jitter offsets (a ring picks one per pose)
for k = 1, 256 do
	local a = 6.28 * math.random()
	WV_JIT[k] = {math.cos(a) * math.random(), math.random() - 0.5, math.sin(a) * math.random()}
end

function wvLegs(v, s, t, dt, agit, still, dead, thrash, slump)
	for _, l in ipairs(s.legs) do
		local sg = l.sign
		local sweep, lift
		if s.ult then
			sweep = 8 * math.sin(t * 1.1 + sg) + 6 * math.sin(t * 2.7 + sg * 2) * (0.3 + agit)
			lift = 4 * math.sin(t * 0.8 + sg)
		else
			local ph = v.travel * 2.8 + v.idlePh - l.k * 0.7 + (sg < 0 and math.pi or 0)
			l.ph = ph
			if t < l.tw or dead then                                   -- (only the live path needs the angles)
				sweep = 22 * math.sin(ph)
				lift = 13 * math.max(0, math.cos(ph)) - 2
			end
		end
		local live = s.ult or dead
		if t < l.tw then
			sweep = sweep + l.twA; lift = lift + l.twB
			live = true
		elseif math.random() < dt * (0.15 + 1.2 * still + 0.6 * agit) then
			l.tw = t + 0.08 + math.random() * 0.22; l.twA = (math.random() - 0.5) * 50; l.twB = 10 + math.random() * 30
		end
		if dead then
			sweep = 35 * thrash * math.sin(t * 23 + l.k * 1.3 + sg)
			lift = -40 * slump + 25 * thrash * math.sin(t * 17 + l.k)
		end
		if live then
			-- (+sweep = forward: the left leg (+x) turns toward +z about -y; +lift = up)
			wvLimb(l, QuatRotateQuat(QuatEuler(0, -sg * sweep, 0), QuatEuler(0, 0, sg * lift)))
		else
			-- the walking cycle replayed: this leg's finished transform at each of WV_LEG_STEPS steps of the cycle,
			-- made the first time the step comes up (the maths and seven engine calls a leg, once instead of every pose)
			local idx = math.floor(l.ph * WV_LEG_K) % WV_LEG_STEPS
			local bk = l.bake
			if not bk then bk = {}; l.bake = bk end
			local T = bk[idx]
			if not T then
				local ph = (idx + 0.5) / WV_LEG_K
				local R = QuatRotateQuat(QuatEuler(0, -sg * 22 * math.sin(ph), 0), QuatEuler(0, 0, sg * (13 * math.max(0, math.cos(ph)) - 2)))
				T = Transform(VecAdd(l.hinge, QuatRotateVec(R, VecSub(l.rest.pos, l.hinge))), QuatRotateQuat(R, l.rest.rot))
				bk[idx] = T
			end
			SetShapeLocalTransform(l.shape, T)
		end
	end
end

-- side and up vectors of a part facing fwd (as wvRot builds them)
local function sideUp(f, u)
	local fx, fy, fz = f[1], f[2], f[3]
	local ux, uy, uz = 0, 1, 0
	if u then ux, uy, uz = u[1], u[2], u[3] end
	local x1, x2, x3 = uy * fz - uz * fy, uz * fx - ux * fz, ux * fy - uy * fx
	local l = math.sqrt(x1 * x1 + x2 * x2 + x3 * x3)
	if l < 1e-4 then
		if math.abs(fy) > 0.97 then x1, x2, x3 = 0, -fz, fy else x1, x2, x3 = fz, 0, -fx end
		l = math.sqrt(x1 * x1 + x2 * x2 + x3 * x3)
		if l < 1e-9 then l = 1 end
	end
	x1, x2, x3 = x1 / l, x2 / l, x3 / l
	return {x1, x2, x3}, {fy * x3 - fz * x2, fz * x1 - fx * x3, fx * x2 - fy * x1}
end

function wvPose(v, w, tr, dt, nm)
	local t = GetTime()
	v.poseN = (v.poseN or 0) + 1                                 -- (poses of this worm: far ones skip frames)
	local speed = w.speed or 0
	v.phase = v.phase + dt * (0.8 + speed * 0.6)
	local agit = (w.state == "chase" or w.state == "drag" or w.state == "windup" or w.state == "lunge") and 1 or
		(w.state == "stalk" and 0.5 or 0.15)
	local dead = not w.alive
	local dt0 = dead and (t - (v.diedT or t)) or 0
	if dead and not v.diedT then v.diedT = t end
	local thrash = dead and math.max(0, 1 - dt0 / 3.5) or 0
	local slump = dead and math.min(1, math.max(0, (dt0 - 2.5) / 4)) or 0
	local len = w.len or 0
	-- standing still (stuck, frozen, waiting) the body comes alive instead of freezing
	v.still = v.still + ((speed < 0.6 and 1 or 0) - v.still) * math.min(1, dt * 2.5)
	local still = dead and 0 or v.still
	v.travel = v.travel + speed * dt
	v.idlePh = v.idlePh + dt * (0.6 + 6 * agit) * still
	if not dead and t > (v.nextTw or 0) then
		v.nextTw = t + (0.15 + math.random() * 0.9) / (0.4 + still + 0.5 * agit)
		wvNewTwitch(v, len, still, agit)
	end
	for k = #v.tw, 1, -1 do if t > v.tw[k].t0 + v.tw[k].dur then table.remove(v.tw, k) end end
	-- the head
	local walk = wvWalk(tr, nm)
	local hp, hf, hu = wvAtW(walk, 0)
	if w.fx then hf = VecNormalize(Vec(w.fx, w.fy, w.fz)) end
	if w.ux then hu = VecNormalize(Vec(w.ux, w.uy, w.uz)) end
	local camD = dist(wvCam, hp)
	local limbs = camD < 80                                    -- (limbs only move where someone could see them)
	local legEvery = camD < 25 and 1 or 2                      -- (farther off the legs turn every 2nd frame, ring by ring)
	if v.baby then legEvery = 2 end                                -- (juveniles: legs every 2nd pose)
	local sc = v.scale or 1.0
	local jit = (0.001 + 0.003 * agit) * math.min(1.5, sc)
	local function shake(i)
		local a = 6.28 * math.random()
		return {math.cos(a) * jit * math.random(), (math.random() - 0.5) * jit, math.sin(a) * jit * math.random()}
	end
	local function fall(p, i)
		if slump <= 0 then return p end
		v.ground = v.ground or {}
		if not v.ground[i] then
			QueryCollisionMask(WORM_QUERY_MASK)
			local hit, d = QueryRaycast(p, Vec(0, -1, 0), 40)
			v.ground[i] = hit and (p[2] - d + 0.25 * sc) or (p[2] - 2)
		end
		return Vec(p[1], p[2] + (v.ground[i] - p[2]) * slump, p[3])
	end
	local thr = function(i)
		if thrash <= 0 then return WV_ZERO end
		local a = math.sin(t * 17 + i * 0.9) * thrash * 0.35 * sc
		return Vec(a * math.cos(i), math.sin(t * 13 + i) * thrash * 0.2 * sc, a * math.sin(i))
	end
	-- a slow sinuous writhe along the body (stronger when still) plus the twitches, at arc length s
	local undA = (0.03 + 0.07 * still + 0.02 * agit) * sc
	local undW = 1.4 + 2.2 * agit + 0.8 * still
	local function life(s, f)
		if dead then return WV_ZERO end
		local x, y = sideUp(f, hu)
		local env = math.min(1, s / 1.2)
		local a = undA * env * math.sin(s * 2.1 - t * undW)
		local b = 0.4 * undA * env * math.sin(s * 1.3 + t * 1.1)
		for _, tw in ipairs(v.tw) do
			local m = wvTwitchAt(tw, s, t)
			if m ~= 0 then a, b = a + math.cos(tw.a) * m, b + math.sin(tw.a) * m end
		end
		return {x[1] * a + y[1] * b, x[2] * a + y[2] * b, x[3] * a + y[3] * b}
	end
	local headPos = fall(VecAdd(VecAdd(VecAdd(hp, shake(0)), thr(0)), life(0.25, hf)), 0)
	-- it looks around in jerks (more when still; not while it strikes)
	local L = v.look
	local aim = w.state == "windup" or w.state == "lunge" or w.state == "drag"
	if t > L.next or (aim and L.ty ~= 0) then
		local k = (dead or aim) and 0 or (0.25 + 0.75 * still)
		L.ty = (math.random() - 0.5) * 70 * k
		L.tp = (math.random() - 0.5) * 36 * k
		L.next = t + 0.2 + math.random() * (0.4 + 0.8 * (1 - agit))
	end
	local kk = math.min(1, dt * 16)
	L.y = L.y + (L.ty - L.y) * kk
	L.p = L.p + (L.tp - L.p) * kk
	local roll0 = math.sin(v.phase * 1.3) * 0.12 * agit + (math.random() - 0.5) * 0.05 * agit
	SetBodyTransform(v.head, Transform(headPos, QuatRotateQuat(wvRot(hf, roll0, hu), QuatEuler(L.p, L.y, 0))))
	-- the venom claws: as the server says, plus small flicks of their own
	local open = math.max(0, math.min(1, w.mouth or 0))
	if w.state == "windup" then open = math.min(1, open + 0.15 * math.sin(t * 40)) end
	if not dead then
		if t > (v.jawNext or 0) then
			v.jawNext = t + 0.4 + math.random() * (2.5 - 1.8 * still)
			v.jawTw = t + 0.08 + math.random() * 0.15
			v.jawTwA = 0.15 + math.random() * 0.45
		end
		if t < (v.jawTw or 0) then open = math.max(open, v.jawTwA) end
	else
		open = 0.6 * thrash + 0.25
	end
	for _, j in ipairs(v.jaws) do wvLimb(j, QuatEuler(0, j.sign * open * 45, 0)) end
	-- the antennae: probing sweeps, sudden flicks, drooping when dead (+pitch = down)
	if limbs then
		for _, a in ipairs(v.ants) do
			local sg = a.sign
			local spd = 1 + 2 * agit + still
			local yaw = 6 + 16 * math.sin(t * 1.3 * spd + sg * 1.7) + 8 * math.sin(t * 3.1 * spd + sg)
			local pitch = -4 - 12 * math.sin(t * 0.9 * spd + sg * 2.3)
			if t < a.tw then
				yaw = yaw + a.twA; pitch = pitch + a.twB
			elseif math.random() < dt * (0.6 + 2.5 * still + 2 * agit) then
				a.tw = t + 0.08 + math.random() * 0.2; a.twA = (math.random() - 0.5) * 70; a.twB = (math.random() - 0.5) * 50
			end
			if dead then yaw = 10 + 25 * thrash * math.sin(t * 19 + sg); pitch = 15 + 30 * slump end
			wvLimb(a, QuatRotateQuat(QuatEuler(0, sg * yaw, 0), QuatEuler(pitch, 0, 0)))
		end
	end
	-- the body: positions first, then each ring faces along its neighbours (so writhes and twitches bend it)
	local glowBase = w.glow or 0
	if dead then glowBase = 0 end
	local speedW = (w.state == "lurk") and 2.2 or (w.state == "stalk" and 4 or 7.5)
	local pos = {}
	local fw = v.fw
	if not fw then fw = {}; v.fw = fw end                        -- (each ring's forward along the trail, flat, kept)
	local upv = v.upv
	if not upv then upv = {}; v.upv = upv end                    -- (each ring's surface normal along the trail, flat, kept)
	local strobe = w.state == "windup" or w.state == "lunge"
	-- what all rings share this pose: the writhe's two waves at this time, and the twitches under way
	-- (sin(a - b) = sin a cos b - cos a sin b: each ring keeps the sines of its own place, made once)
	local sU, cU = math.sin(t * undW), math.cos(t * undW)
	local sV, cV = math.sin(t * 1.1), math.cos(t * 1.1)
	local twC, twW, twA, twB = v.twC, v.twW, v.twA, v.twB
	if not twC then twC, twW, twA, twB = {}, {}, {}, {}; v.twC, v.twW, v.twA, v.twB = twC, twW, twA, twB end
	local nTw = 0
	if not dead then
		for _, tw in ipairs(v.tw) do
			local u = (t - tw.t0) / tw.dur
			if u >= 0 and u <= 1 then
				local f
				if tw.run > 0 then f = math.sin(math.pi * u) elseif u < 0.2 then f = u / 0.2 else f = ((1 - u) / 0.8) ^ 2 end
				local m = tw.amp * f
				nTw = nTw + 1
				twC[nTw], twW[nTw], twA[nTw], twB[nTw] = tw.c + tw.run * (t - tw.t0), tw.wd, math.cos(tw.a) * m, math.sin(tw.a) * m
			end
		end
	end
	local exp, abs, sqrt, random = math.exp, math.abs, math.sqrt, math.random
	for i, s in ipairs(v.segs) do
		local arc = s.arc
		if arc > len + 0.3 * sc and not dead then
			if not s.parked then SetBodyTransform(s.body, Transform(VIEW_PARK)); s.parked = true end
		else
			s.parked = false
			local px, py, pz, fx, fy, fz, ux, uy, uz = wvAtN(walk, arc)
			fw[3 * i - 2], fw[3 * i - 1], fw[3 * i] = fx, fy, fz
			upv[3 * i - 2], upv[3 * i - 1], upv[3 * i] = ux, uy, uz
			local jv = WV_JIT[random(256)]
			px, py, pz = px + jv[1] * jit, py + jv[2] * jit, pz + jv[3] * jit
			if dead then
				if thrash > 0 then
					local th = thr(i)
					px, py, pz = px + th[1], py + th[2], pz + th[3]
				end
			else
				if not s.s21 then
					s.s21, s.c21, s.s13, s.c13 = math.sin(arc * 2.1), math.cos(arc * 2.1), math.sin(arc * 1.3), math.cos(arc * 1.3)
					s.env = math.min(1, arc / 1.2)
				end
				local a = undA * s.env * (s.s21 * cU - s.c21 * sU)
				local b = 0.4 * undA * s.env * (s.s13 * cV + s.c13 * sV)
				for j = 1, nTw do
					local e = (arc - twC[j]) / twW[j]
					if e < 3 and e > -3 then
						local g = exp(-e * e)
						a, b = a + twA[j] * g, b + twB[j] * g
					end
				end
				-- side (x) and up (y) of a part facing f with surface normal u
				local x1, x2, x3 = uy * fz - uz * fy, uz * fx - ux * fz, ux * fy - uy * fx
				local l = sqrt(x1 * x1 + x2 * x2 + x3 * x3)
				if l < 1e-4 then
					if abs(fy) > 0.97 then x1, x2, x3 = 0, -fz, fy else x1, x2, x3 = fz, 0, -fx end
					l = sqrt(x1 * x1 + x2 * x2 + x3 * x3)
					if l < 1e-9 then l = 1 end
				end
				x1, x2, x3 = x1 / l, x2 / l, x3 / l
				px = px + x1 * a + (fy * x3 - fz * x2) * b
				py = py + x2 * a + (fz * x1 - fx * x3) * b
				pz = pz + x3 * a + (fx * x2 - fy * x1) * b
			end
			local p = {px, py, pz}
			if slump > 0 then p = fall(p, i) end
			pos[i] = p
		end
	end
	local sP, cP = math.sin(v.phase * 1.3), math.cos(v.phase * 1.3)
	local rollA = 0.06 + 0.14 * agit
	for i, s in ipairs(v.segs) do
		if pos[i] then
			local a = (i == 1) and headPos or pos[i - 1]
			local fx, fy, fz = fw[3 * i - 2], fw[3 * i - 1], fw[3 * i]
			if a and pos[i + 1] then
				local q = pos[i + 1]
				local dx, dy, dz = a[1] - q[1], a[2] - q[2], a[3] - q[3]
				local dl = sqrt(dx * dx + dy * dy + dz * dz)
				if dl > 0.01 then fx, fy, fz = dx / dl, dy / dl, dz / dl end
			end
			if not s.rs then s.rs, s.rc = math.sin(i * 0.35), math.cos(i * 0.35) end
			local roll = (sP * s.rc - cP * s.rs) * rollA + (random() - 0.5) * 0.04 * agit
			-- (wvRot with surface normal upv: x = normalize(up x fwd), y = fwd x x, rolled)
			local ux, uy, uz = upv[3 * i - 2] or 0, upv[3 * i - 1] or 1, upv[3 * i] or 0
			local x1, x2, x3 = uy * fz - uz * fy, uz * fx - ux * fz, ux * fy - uy * fx
			local xl = sqrt(x1 * x1 + x2 * x2 + x3 * x3)
			if xl < 1e-4 then
				if abs(fy) > 0.97 then x1, x2, x3 = 0, -fz, fy else x1, x2, x3 = fz, 0, -fx end
				xl = sqrt(x1 * x1 + x2 * x2 + x3 * x3)
				if xl < 1e-9 then xl = 1 end
			end
			x1, x2, x3 = x1 / xl, x2 / xl, x3 / xl
			local y1, y2, y3 = fy * x3 - fz * x2, fz * x1 - fx * x3, fx * x2 - fy * x1
			local rc, rs = math.cos(roll), math.sin(roll)
			SetBodyTransform(s.body, Transform(pos[i], QuatAlignXZ({x1 * rc + y1 * rs, x2 * rc + y2 * rs, x3 * rc + y3 * rs}, {fx, fy, fz})))
			if limbs and s.legs and #s.legs > 0 and (legEvery == 1 or (v.poseN + i) % 2 == 0) then
				wvLegs(v, s, t, dt * legEvery, agit, still, dead, thrash, slump)
			end
			-- glow: a pulse running down the body, each part flickering on its own
			-- (every 3rd frame per ring, the rings taking turns; every frame while it strobes before a strike)
			if strobe or (wvFrame + i) % 3 == 0 then
				local fl = v.flick[i]
				if math.random() < 0.03 * (1 + 3 * agit) then fl.off = t + 0.05 + math.random() * 0.25 end
				local wave = math.max(0, math.sin(t * speedW - i * 0.45 + fl.phase * 0.15)) ^ 4
				local g = glowBase * (0.3 + 0.9 * wave)
				if w.state == "windup" or w.state == "lunge" then g = (math.floor(t * 18 + i * 0.5) % 2 == 0) and 1.6 or 0.2 end
				if t < fl.off then g = g * 0.05 end
				if WV_NOGLOW then g = 0 end
				for _, sh in ipairs(s.shapes) do SetShapeEmissiveScale(sh, g) end
			end
		end
	end
	if strobe or wvFrame % 3 == 0 then
		local hg = (glowBase > 0.01 and not WV_NOGLOW) and (0.5 + 0.8 * glowBase) or 0
		for _, sh in ipairs(GetBodyShapes(v.head)) do SetShapeEmissiveScale(sh, hg) end
	end
	-- Burning visual effects (flames + smoke + orange firelight along the body)
	if w.burning and not dead then
		PointLight(headPos, 1.0, 0.45, 0.1, 3.5 + math.sin(t * 25) * 1.0)
		if math.random() < 0.85 then
			ParticleReset()
			ParticleType("smoke")
			ParticleColor(1.0, 0.45, 0.1, 0.2, 0.2, 0.2)
			ParticleRadius(0.18, 0.45, "easeout")
			ParticleAlpha(0.95, 0, "easein")
			ParticleEmissive(4.0, 0, "easeout")
			ParticleGravity(2.5)
			ParticleDrag(0.3)
			ParticleCollide(0)
			for k = 1, #v.segs, 4 do
				if pos[k] and math.random() < 0.45 then
					SpawnParticle(VecAdd(pos[k], VecScale(rnd(), 0.25)), Vec(0, 1.2 + math.random(), 0), 0.45 + math.random() * 0.35)
				end
			end
		end
	end
	-- Clockwork Machina: dense chugging smog exhaust & expanding electronic wave pulse (cyan when ally, crimson red when hostile to humans)
	if w.variant == "machina" and not dead and camD < 95 then
		local lr, lg, lb = 0.2, 0.85, 1.0
		if w.hostile then lr, lg, lb = 1.0, 0.12, 0.10 end
		PointLight(headPos, lr, lg, lb, 1.4 + 0.5 * math.sin(t * 18))
		-- (smog puffs: 3 vents, every 0.08-0.15 s, within 60 m - the pack's 6 vents every 0.04-0.09 s kept 100+ smoke
		--  particles alive per Machina on every machine)
		if camD < 60 and t > (v.smogT or 0) then
			local spd = w.speed or 0
			v.smogT = t + math.max(0.08, 0.15 - spd * 0.008)
			ParticleReset()
			ParticleType("smoke")
			ParticleColor(0.14, 0.14, 0.16, 0.05, 0.05, 0.06)
			ParticleRadius(0.28, 0.95, "easeout")
			ParticleAlpha(0.92, 0.0, "easeout")
			ParticleGravity(0.85)
			ParticleDrag(0.55)
			ParticleCollide(0)
			-- Chug dense smog from head vents and exhaust segments along the chassis
			SpawnParticle(VecAdd(headPos, Vec(0, 0.22, 0)), VecAdd(VecScale(hf, -1.2), Vec(0, 1.8 + math.random() * 0.8, 0)), 1.6 + math.random() * 0.7)
			for _, segIdx in ipairs({8, 20, 32}) do
				local pSeg = pos[segIdx]
				if pSeg and math.random() < 0.65 then
					SpawnParticle(VecAdd(pSeg, Vec(0, 0.2, 0)), Vec((math.random() - 0.5) * 0.8, 1.4 + math.random() * 0.9, (math.random() - 0.5) * 0.8), 1.8 + math.random() * 0.8)
				end
			end
			-- Occasional clockwork electric arc spark (cyan or hostile red)
			if math.random() < 0.35 then
				ParticleReset()
				ParticleType("plain")
				if w.hostile then
					ParticleColor(1.0, 0.22, 0.15, 0.85, 0.05, 0.05)
				else
					ParticleColor(0.3, 0.92, 1.0, 0.1, 0.5, 1.0)
				end
				ParticleRadius(0.06, 0.01)
				ParticleAlpha(1.0, 0.0)
				ParticleEmissive(6.0, 1.0)
				ParticleGravity(-1.0)
				ParticleDrag(0.2)
				ParticleCollide(0)
				SpawnParticle(VecAdd(headPos, VecScale(rnd(), 0.45)), VecScale(rnd(), 5.5), 0.22)
			end
		end
		local empAge = (w.t or 0) - (w.empT or -100)
		if empAge >= 0 and empAge < 1.1 and t >= (v.empFxT or 0) then
			v.empFxT = t + WV_RING_DT
			local waveFrac = empAge / 1.1
			local waveR = 1.0 + waveFrac * 11.5
			PointLight(headPos, lr, lg, lb, 8.0 * (1 - waveFrac))
			ParticleReset()
			ParticleType("plain")
			if w.hostile then
				ParticleColor(1.0, 0.25, 0.18, 0.9, 0.06, 0.06)
			else
				ParticleColor(0.35, 0.95, 1.0, 0.1, 0.45, 1.0)
			end
			ParticleRadius(0.18, 0.05)
			ParticleAlpha(0.95 * (1 - waveFrac), 0)
			ParticleEmissive(8.0, 1.5)
			ParticleGravity(0)
			ParticleDrag(0.1)
			ParticleCollide(0)
			for k = 1, 12 do
				local ang = (k / 12) * 6.283185 + empAge * 4.0
				local rp = VecAdd(headPos, Vec(math.cos(ang) * waveR, (math.random() - 0.5) * 0.4, math.sin(ang) * waveR))
				SpawnParticle(rp, Vec(math.cos(ang) * 4.0, (math.random() - 0.5) * 1.5, math.sin(ang) * 4.0), 0.16)
			end
		end
	end
	-- Seismica: expanding tectonic shockwave ring, flying rock debris, and heavy camera tremor scaling with growth size
	if w.variant == "seismica" and not dead then
		local seisAge = (w.t or 0) - (w.seismicT or -100)
		if seisAge >= 0 and seisAge < 1.25 then
			local pow = math.min(4.5, sc)
			local waveFrac = seisAge / 1.25
			local maxR = 6.5 * pow
			local waveR = 0.8 + waveFrac * maxR
			if camD < maxR * 2.2 then
				ShakeCamera((1 - waveFrac) * math.min(1.2, 0.35 * pow) * math.max(0.15, 1 - camD / (maxR * 2.2)))
			end
			PointLight(headPos, 1.0, 0.72, 0.18, 7.5 * pow * (1 - waveFrac))
			if t >= (v.seisFxT or 0) then
				v.seisFxT = t + WV_RING_DT
				ParticleReset()
				ParticleType("smoke")
				ParticleColor(0.52, 0.42, 0.28, 0.28, 0.22, 0.15)
				ParticleRadius(0.35 * pow, 0.95 * pow, "easeout")
				ParticleAlpha(0.88 * (1 - waveFrac), 0, "easeout")
				ParticleGravity(-0.4)
				ParticleDrag(0.45)
				ParticleCollide(0)
				for k = 1, 10 do
					local ang = (k / 10) * 6.283185 + seisAge * 1.5
					local rp = VecAdd(headPos, Vec(math.cos(ang) * waveR, (math.random() - 0.5) * 0.35, math.sin(ang) * waveR))
					SpawnParticle(rp, Vec(math.cos(ang) * 3.5 * pow, 1.2 + math.random() * 1.8, math.sin(ang) * 3.5 * pow), 0.45)
				end
				ParticleReset()
				ParticleType("plain")
				ParticleColor(1.0, 0.78, 0.22, 0.65, 0.45, 0.15)
				ParticleRadius(0.10 * pow, 0.03 * pow)
				ParticleAlpha(1.0, 0)
				ParticleEmissive(5.0, 0.5)
				ParticleGravity(-6.5)
				ParticleDrag(0.15)
				ParticleCollide(0)
				for k = 1, 6 do
					local ang = math.random() * 6.283185
					local rp = VecAdd(headPos, Vec(math.cos(ang) * waveR * 0.85, 0.2, math.sin(ang) * waveR * 0.85))
					SpawnParticle(rp, Vec(math.cos(ang) * 5.0, 3.5 + math.random() * 4.5, math.sin(ang) * 5.0), 0.35)
				end
			end
		end
	end
	-- light on its surroundings: the head, the mouth, three spots along the body
	if glowBase > 0.02 and not WV_NOLIGHTS then
		local hpos = GetBodyTransform(v.head).pos
		local isIgn = (w.variant == "ignitus")
		local isMach = (w.variant == "machina")
		local isSeis = (w.variant == "seismica")
		local mr, mg, mb = 0.2, 0.88, 1.0
		if isMach and w.hostile then mr, mg, mb = 1.0, 0.12, 0.10 end
		if isMach then
			PointLight(hpos, mr, mg, mb, 0.5 + 0.8 * glowBase)
		elseif isSeis then
			PointLight(hpos, 1.0, 0.75, 0.20, (0.4 + 0.75 * glowBase) * math.min(2.5, sc))
		elseif isIgn then
			PointLight(hpos, 1.0, 0.28, 0.06, 0.35 + 0.65 * glowBase)
		else
			PointLight(hpos, 0.75, 1.0, 0.15, 0.25 + 0.5 * glowBase)
		end
		if open > 0.15 then
			if isMach then
				PointLight(VecAdd(hpos, VecScale(hf, 0.5)), mr, mg, mb, 3 * open)
			else
				PointLight(VecAdd(hpos, VecScale(hf, 0.5)), 1.0, 0.25, 0.05, 3 * open)
			end
		end
		for _, k in ipairs({8, 18, 30}) do
			local s = v.segs[k]
			if s and not s.parked then
				local pulse = math.max(0, math.sin(t * speedW - k * 0.45)) ^ 3
				if isMach then
					PointLight(GetBodyTransform(s.body).pos, mr, mg, mb, glowBase * (0.35 + 1.2 * pulse))
				else
					PointLight(GetBodyTransform(s.body).pos, 1.0, isIgn and 0.25 or 0.6, 0.08, glowBase * (0.3 + 1.2 * pulse))
				end
			end
		end
	end
	return headPos
end

function WormView.clientTick(dt)
	wvTake()
	local t = GetTime()
	wvFrame = wvFrame + 1
	wvCam = GetCameraTransform().pos
	for id, s in pairs(wvSnaps) do
		if t - (s.seen or 0) > 3 then                              -- (gone from the server's list)
			if wvViews[id] then wvDelete(wvViews[id]); wvViews[id] = nil end
			wvSnaps[id] = nil
		else
			local w = s.cur
			local v = wvViews[id]
			local isBaby = w.baby and true or false
			local variant = w.variant or "acidica"
			local wScale = w.scale or (isBaby and 0.20 or 1.0)
			if variant == "machina" and w.hostile then variant = "machina_hostile" end
			if v and (v.baby ~= isBaby or v.variant ~= variant or math.abs((v.scale or 1.0) - wScale) > 0.02) then
				wvDelete(v)
				v = nil
				wvViews[id] = nil
			end
			if not v then v = wvSpawn(isBaby, variant, wScale); wvViews[id] = v end
			local f = 1
			if s.prev and s.prevT and s.curT > s.prevT then f = math.min(1, math.max(0, (t - s.curT) / (s.curT - s.prevT))) end
			-- Linear constant-velocity interpolation between snapshots so motion never pulses at the server publish rate
			f = math.min(1, math.max(0, f))
			-- far from the camera the body is posed every 2nd / 4th frame (the pose is Lua maths for every ring)
			local hd = dist(wvCam, Vec(w.trail[1] or 0, w.trail[2] or 0, w.trail[3] or 0))
			local every = hd < 70 and 1 or (hd < 140 and 2 or 4)
			if v.baby then every = hd < 25 and 2 or 4 end             -- (juveniles: small, many, and as dear to pose as an adult)
			v.lodDt = (v.lodDt or 0) + dt
			local head = v.headPos
			if not head or every == 1 or (wvFrame + id) % every == 0 then
				local tr = wvBlend(s.prev and s.prev.trail, w.trail, f)
				local nm = wvBlend(s.prev and s.prev.norms, w.norms, f)
				head = wvPose(v, w, tr, v.lodDt, nm)
				v.headPos, v.lodDt = head, 0
			end
			wvSounds(v, w, s, head, dt)
			wvHits(v, w)
		end
	end
	-- Render active acid spit droplets and egg nests published by the server
	local W = wvW
	if W then
		if W.acids and #W.acids > 0 then
			for _, a in ipairs(W.acids) do
				local ap = Vec(a.x, a.y, a.z)
				ParticleReset()
				if a.kind == "seismic" then
					ParticleType("smoke")
					ParticleColor(0.65, 0.50, 0.28, 0.35, 0.28, 0.16)
					ParticleRadius(0.18, 0.36, "easeout")
					ParticleAlpha(0.95, 0)
					ParticleEmissive(2.5, 0.2)
					ParticleGravity(-2.5)
					ParticleDrag(0.2)
					ParticleCollide(0)
					SpawnParticle(ap, VecScale(rnd(), 0.8), 0.22)
					PointLight(ap, 1.0, 0.72, 0.18, 1.1)
				elseif a.kind == "shock" or a.kind == "shock_red" then
					local isRed = (a.kind == "shock_red")
					ParticleType("plain")
					if isRed then
						ParticleColor(1.0, 0.22, 0.16, 0.85, 0.05, 0.05)
					else
						ParticleColor(0.35, 0.95, 1.0, 0.15, 0.55, 1.0)
					end
					ParticleRadius(0.15, 0.04, "easeout")
					ParticleAlpha(0.98, 0)
					ParticleEmissive(7.0, 1.5)
					ParticleGravity(0)
					ParticleDrag(0.15)
					ParticleCollide(0)
					SpawnParticle(ap, VecScale(rnd(), 1.6), 0.18)
					if isRed then
						PointLight(ap, 1.0, 0.15, 0.12, 1.6)
					else
						PointLight(ap, 0.25, 0.9, 1.0, 1.6)
					end
				elseif a.kind == "fire" then
					ParticleType("smoke")
					ParticleColor(1.0, 0.5, 0.1, 0.8, 0.15, 0.02)
					ParticleRadius(0.16, 0.32, "easeout")
					ParticleAlpha(0.95, 0)
					ParticleEmissive(4.5, 0.5)
					ParticleGravity(1.5)
					ParticleDrag(0.25)
					ParticleCollide(0)
					SpawnParticle(ap, VecScale(rnd(), 0.9), 0.24)
					PointLight(ap, 1.0, 0.38, 0.08, 1.2)
				else
					ParticleType("plain")
					ParticleColor(0.35, 1.0, 0.15, 0.15, 0.7, 0.1)
					ParticleRadius(0.11, 0.04)
					ParticleAlpha(0.95, 0)
					ParticleEmissive(3.5, 0.5)
					ParticleGravity(-2.0)
					ParticleDrag(0.2)
					ParticleCollide(0)
					SpawnParticle(ap, VecScale(rnd(), 0.6), 0.18)
					PointLight(ap, 0.3, 1.0, 0.15, 0.8)
				end
			end
		end
		if W.nests and #W.nests > 0 then
			local nestPulse = 0.80 + 0.20 * math.sin(t * 2.2)
			wvNestFogT = wvNestFogT or 0
			local emitFog = (t >= wvNestFogT)
			if emitFog then wvNestFogT = t + 0.2 end
			for _, ns in ipairs(W.nests) do
				local np = Vec(ns.x, ns.y, ns.z)
				local isIgnNest = (ns.variant == "ignitus")
				if isIgnNest then
					PointLight(VecAdd(np, Vec(0, 0.8, 0)), 0.75, 0.42, 0.22, 0.55 * nestPulse)
				else
					PointLight(VecAdd(np, Vec(0, 0.8, 0)), 0.92, 0.96, 0.94, 0.75 * nestPulse)
				end
				-- Performant low-lying ground fog that scales in radius and density with nest expansion tier (1..5)
				if emitFog and dist(wvCam, np) < 85 then
					local tier = math.max(1, math.min(5, ns.tier or 1))
					local fogR = 4.8 * (0.75 + 0.25 * tier)
					local alpha0 = math.min(0.34, 0.09 + 0.048 * tier)
					local puffs = 1 + math.floor(tier * 0.6)
					ParticleReset()
					ParticleType("smoke")
					if isIgnNest then
						ParticleColor(0.38, 0.33, 0.30, 0.26, 0.24, 0.23)
					else
						ParticleColor(0.88, 0.94, 0.89, 0.74, 0.82, 0.76)
					end
					ParticleRadius(0.55 + 0.08 * tier, 1.25 + 0.18 * tier, "easeout")
					ParticleAlpha(alpha0, 0, "easeout")
					ParticleGravity(-0.015)
					ParticleDrag(0.92)
					ParticleCollide(0)
					for _ = 1, puffs do
						local ang = math.random() * 6.283185
						local r = math.sqrt(math.random()) * fogR
						local fp = VecAdd(np, Vec(math.cos(ang) * r, -0.18 + math.random() * 0.32, math.sin(ang) * r))
						SpawnParticle(fp, Vec((math.random() - 0.5) * 0.22, 0.02 + math.random() * 0.04, (math.random() - 0.5) * 0.22), 2.8 + math.random() * 1.0)
					end
				end
				if ns.repairing then
					PointLight(VecAdd(np, Vec(0, 0.9, 0)), 0.95, 0.98, 0.94, 1.8)
					ParticleReset()
					ParticleType("plain")
					ParticleColor(0.96, 0.99, 0.95, 0.85, 0.90, 0.84)
					ParticleRadius(0.08, 0.03)
					ParticleAlpha(0.90, 0)
					ParticleEmissive(1.4, 0.2)
					ParticleGravity(-1.8)
					ParticleDrag(0.35)
					for _ = 1, 5 do
						local ang = math.random() * 6.283
						local rad = 0.4 + math.random() * 4.5
						local sp = VecAdd(np, Vec(math.cos(ang) * rad, 0.35 + math.random() * 0.9, math.sin(ang) * rad))
						SpawnParticle(sp, Vec(math.cos(ang) * 2.2, -0.8 + math.random() * 1.2, math.sin(ang) * 2.2), 0.55)
					end
				end
			end
		end
		if W.eggs and #W.eggs > 0 then
			local pulse = 0.6 + 0.4 * math.sin(t * 4.5)
			for _, e in ipairs(W.eggs) do
				local ep = Vec(e.x, e.y, e.z)
				local isIgn = (e.variant == "ignitus")
				if isIgn then
					PointLight(ep, 1.0, 0.35, 0.08, 1.4 * pulse)
				else
					PointLight(ep, 0.25, 0.95, 0.3, 1.4 * pulse)
				end
				if math.random() < 0.15 then
					ParticleReset()
					ParticleType("smoke")
					if isIgn then
						ParticleColor(1.0, 0.4, 0.1, 0.5, 0.15, 0.02)
					else
						ParticleColor(0.2, 0.85, 0.25, 0.1, 0.4, 0.1)
					end
					ParticleRadius(0.08, 0.22)
					ParticleAlpha(0.6, 0)
					ParticleEmissive(1.5, 0)
					ParticleGravity(0.4)
					SpawnParticle(VecAdd(ep, Vec(0, 0.15, 0)), VecScale(rnd(), 0.3), 0.8)
				end
			end
		end
	end
	-- the server's list no longer has it: published lists are complete, so drop ids not in the newest one
	if W and wvTook then
		local live = {}
		for i = 1, #W do live[W[i].id] = true end
		for id in pairs(wvViews) do
			if not live[id] then wvDelete(wvViews[id]); wvViews[id] = nil; wvSnaps[id] = nil end
		end
	end
end

-- The inside of a cocoon over the whole view: a wall of crossing silk strands (pale for Acidica, dark brown & grey for Ignitus)
function wvSilkWall(variant)
	local sw, sh = UiWidth(), UiHeight()
	local t = GetTime()
	local isIgn = (variant == "ignitus")
	UiPush()
	UiAlign("left top")
	if isIgn then
		UiColor(0.22, 0.17, 0.14, 0.985)
	else
		UiColor(0.78, 0.82, 0.76, 0.985)
	end
	UiRect(sw, sh)
	UiAlign("center middle")
	for k = 1, 80 do
		local h = math.sin(k * 12.9898) * 43758.5453
		h = h - math.floor(h)
		local function f(m) local x = h * m; return x - math.floor(x) end
		UiPush()
		UiTranslate(f(1) * sw, f(7.31) * sh)
		UiRotate((f(3.7) - 0.5) * 80 + 2.5 * math.sin(t * 0.6 + k))
		if isIgn then
			local mix = f(2.9)
			local d = (f(4.3) - 0.5) * 0.08
			local r = math.max(0.12, math.min(0.44, 0.24 + 0.08 * mix + d))
			local g = math.max(0.10, math.min(0.40, 0.17 + 0.13 * mix + d * 0.9))
			local b = math.max(0.08, math.min(0.38, 0.12 + 0.17 * mix + d * 0.85))
			UiColor(r, g, b, 0.88)
		else
			local shade = 0.66 + 0.32 * f(2.9)
			UiColor(shade, shade * 1.02, shade * 0.96, 0.85)
		end
		UiRect(250 + f(5.3) * 900, 4 + f(9.1) * 14)
		UiPop()
	end
	UiPop()
end

function WormView.clientDraw()
	local me = GetLocalPlayer()
	local W = wvW
	if not W then return end
	-- the spawn menu's markers: the seconds until a worm comes out
	local marks = W.marks
	if marks then
		for i = 1, #marks, 4 do
			local x, y, d = UiWorldToPixel(Vec(marks[i], marks[i + 1] + 0.7, marks[i + 2]))
			if d > 0 and d < 80 then
				UiPush()
				UiTranslate(x, y)
				UiAlign("center middle")
				UiFont("bold.ttf", 44)
				UiColor(0, 0, 0, 0.8)
				UiTranslate(2, 2)
				UiText(tostring(math.ceil(marks[i + 3])))
				UiTranslate(-2, -2)
				UiColor(0.85, 1, 0.3, 0.6 + 0.4 * math.sin(GetTime() * 8))
				UiText(tostring(math.ceil(marks[i + 3])))
				UiPop()
			end
		end
	end
	local pc = W.pc or {}
	for i = 1, #pc, 5 do
		if pc[i] == me and me ~= 0 then
			local cVar = (W.pcVar and W.pcVar[me]) or "acidica"
			-- first person: the silk wall; third person: the game's own camera looks at the cocoon from outside
			if VecLength(VecSub(GetPlayerCameraTransform(me).pos, GetPlayerEyeTransform(me).pos)) < 0.6 then wvSilkWall(cVar) end
			UiPush()
			UiTranslate(UiCenter(), UiHeight() * 0.8)
			UiAlign("center middle")
			UiFont("bold.ttf", 30)
			if cVar == "ignitus" then
				UiColor(0.88, 0.82, 0.76, 0.92)
			else
				UiColor(0.25, 0.22, 0.2, 0.9)
			end
			UiText(string.format("COCOONED - %d s - SOMEONE HAS TO CUT YOU OUT", math.ceil(pc[i + 4] or 0)))
			UiPop()
		end
	end
	if me ~= 0 and GetPlayerHealth(me) > 0 then                   -- (someone else's cocoon in front of you: the prompt)
		local mine = false
		for i = 1, #pc, 5 do if pc[i] == me then mine = true end end
		for i = 1, #pc, 5 do
			if not mine and pc[i] ~= me and wormCanCut(me, Vec(pc[i + 1], pc[i + 2] + 0.4, pc[i + 3])) then
				UiPush()
				UiTranslate(UiCenter(), UiMiddle() + 80)
				UiAlign("center middle")
				UiFont("bold.ttf", 30)
				UiColor(0, 0, 0, 0.6)
				UiRect(420, 46)
				UiColor(0.85, 1, 0.3, 1)
				UiText(string.format("[E]  CUT THEM FREE  (%d s left)", math.ceil(pc[i + 4] or 0)))
				UiPop()
				break
			end
		end
	end
	local free = W.free or {}
	for i = 1, #free, 2 do
		if free[i] == me and me ~= 0 then
			UiPush()
			UiTranslate(UiCenter(), UiHeight() * 0.8)
			UiAlign("center middle")
			UiFont("bold.ttf", 30)
			UiColor(0.85, 1, 0.3, 0.9)
			UiText(string.format("FREE - RUN - IT HUNTS YOU AGAIN IN %d s", math.ceil(free[i + 1] or 0)))
			UiPop()
		end
	end
	for i = 1, #W do
		local w = W[i]
		if w.alive and w.grab == me and me ~= 0 then
			UiPush()
			UiTranslate(UiCenter(), UiHeight() * 0.72)
			UiAlign("center middle")
			UiFont("bold.ttf", 34)
			UiColor(1, 0.25, 0.2, 0.75 + 0.25 * math.sin(GetTime() * 12))
			UiText("SEIZED - HURT IT TO BREAK FREE")
			UiTranslate(0, 40)
			UiColor(0, 0, 0, 0.6)
			UiRect(420, 16)
			UiAlign("left middle")
			UiTranslate(-210, 0)
			UiColor(1, 0.3, 0.2, 0.9)
			UiRect(420 * math.min(1, w.esc or 0), 16)               -- (the damage taken while it holds you)
			UiPop()
			ShakeCamera(0.25)
		end
	end
end
