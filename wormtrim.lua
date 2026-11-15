-- The body is shorter than the model was made (wormparts.lua: 40 rings, 4 of each size class): the rings of
-- WORM_DROP are taken out here, in pairs (a ring with legs and the one behind it without), so the legs still
-- alternate and the taper stays. Included right after wormparts.lua, on the server and the clients alike.
WORM_DROP = {3, 4, 7, 8, 19, 20, 23, 24, 31, 32, 39, 40}      -- (28 of 40 rings: 12.1 m; the user, 2026-11-13: 20 % longer than 9.9 m)

do
	local drop, keep = {}, {}
	for _, i in ipairs(WORM_DROP) do drop[i] = true end
	for i, s in ipairs(WORM_PARTS.segments) do
		if not drop[i] then keep[#keep + 1] = s end
	end
	WORM_PARTS.segments = keep
end
