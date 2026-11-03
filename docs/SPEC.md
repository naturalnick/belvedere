CURRENT GAME (2026-11-02): Eight rooms and one gap on the 3×3 grid, default seed A [6,2,5,0,1,3,7,-1,8], player in Foyer. Dark gray concrete and two perpendicular pairs of flush crossing tracks mark the gap. A perimeter gap leads onto the lawn and allows reentry; ordinary exterior-facing doors and windows remain blocked.

MAIN WIN: Seven room objectives, excluding Foyer. Only the current room has a lit warm-white pendant. The simple shaded pendants stay open and fixed in size; waiting and completed room lamps are off. There are no floor targets or animated objective indicators. Bring that room home to earn its objective permanently. Completion switches that pendant off and adds a permanent light to the Foyer chandelier, then lights the next room. Moving a completed room does not remove its earned light. The next unfinished target is selected from the current arrangement using the fewest legal slides, with door restrictions respected. Already-home targets are credited automatically. A separate seven-light Foyer chandelier records completion. Completing all seven brightens the house and shows wordless continue/return-to-title buttons.

BONUS WIN: All eight rooms home simultaneously. This also awards the main win if it has not happened yet. The solid, opaque Foyer front door unlocks; its house emblem lights, the carpet appears and a rainbow fades in. Crossing that doorway eases the camera along the carpet, with small flowers continually sprouting on nearby grass, then fades to the title screen. The main win alone leaves that door locked.

FURNISHINGS: All eight rooms are furnished with original static geometry. Bedroom: bed, bedside cabinet, wardrobe, dresser/mirror, reading chair and rug. Bathroom: clawfoot tub, washstand/mirror, towels, stool and hamper. Study: writing desk/chair, bookcase, globe and reading chair. Kitchen: sink counter, range/counter, fridge and preparation table. Living: sofa/rug, coffee table, fireplace, armchair and sideboard. Dining: compact six-seat table, sideboard, china cabinet and serving table. Foyer: entry bench, coat stand, console/mirror and umbrella stand. Laundry: washer/dryer, utility sink, boot bench/coats and folding table. Keep the central lever, 1.2 m walking ring and four side approaches clear. Decorative lamps and fireplace remain unlit; only objective fixtures signal game state. Bathroom/Kitchen/Laundry have shader tile floors; Foyer has the specified checker floor. Furniture and floor patterns ride with their rooms.

TITLE/PAUSE: The title screen shows “Shifting Manor” above the play icon; pause retains icons only. Both offer a speaker toggle and gear icon for settings. Icon-only settings provide FOV (60–100), sensitivity, invert-Y, camera-shake preference (off by default), and master/effects/music volumes; all persist across launches. Shake effects themselves remain deferred to the feel pass. The game is currently silent; audio will be added later.

Run tools/run.sh. --courtyard retains the six-room/three-gap experiment; --classic retains the original single-objective rules and perimeter barrier. The historical specification below describes the earlier design; docs/DECISIONS.md records amendments.

SHIFTING MANOR — BUILD SPEC v1 (from Game Design Lab, Nov 2 2026). Godot 4, first-person 3D. (est.) = design picks.

1. GRID AND RULES
- 3x3 house. Slots (col,row) with row 0 = north. Solved: 8 rooms in home slots, center (1,1) empty.
- Each room's 4 sides are fixed to the room (rooms never rotate). A side is WINDOW if it faces outside the house in the solved layout, else DOORWAY. Corners: 2 windows + 2 doorways. Edge-middles: 1 window + 3 doorways. Exception: Foyer's south side is the FRONT DOOR (exit), treated as a window for walking.
- Doorways are glazed double doors (see-through). A doorway opens and is walkable only if the facing side is the empty slot or another room's doorway. Facing a window or outside the house: stays shut, rattles on use (no text). Windows never walkable.
- Empty slot = clean room-sized open floor, no walls/rails/ceiling, sky visible. Walkable when reached through an open doorway.
- Slide: lever in the room you are in. Push lever toward a direction: if adjacent slot is empty, the whole room (player parented) slides into it. Otherwise lever clunks back. Only usable inside a room.
- Player re-reads position through windows (outside view = house edge, window-to-window = see into neighbour, glass against a wall = interior).

2. SOLVED LAYOUT AND ROOMS (home slot, accent colour, key furniture)
- (0,0) Bedroom, dusty blue: bed, nightstand + lamp, wardrobe, rug.
- (1,0) Bathroom, sea-glass green: clawfoot tub, sink + mirror, tile floor, towel rail.
- (2,0) Study, deep green: desk + chair, bookshelf wall, globe, reading lamp.
- (0,1) Kitchen, mustard: counter run, stove, fridge (hum), table island (lever offset off the island).
- (2,1) Living Room, terracotta: sofa, armchair, coffee table, fireplace, standing lamp.
- (0,2) Dining Room, plum: long table + 6 chairs, sideboard, pendant light (lever at table end).
- (1,2) Foyer, cream/wood: coat stand, bench, umbrella stand, framed mirror, FRONT DOOR on south wall.
- (2,2) Laundry/Mudroom, slate blue: washer/dryer, boots rack, utility sink, hanging coats.
Distinct floor material + accent wall colour per room, identifiable from a neighbour's window. 1.2 m clear ring around lever; clear paths to all 4 sides.

3. LEVER
- Floor-mounted brass joystick lever on short pedestal, 4 directions. Default room center; nudge up to 1.5 m off center. Look + hold interact, move mouse/WASD toward a direction, release. Valid: lever locks over, slide begins. Invalid: spring-back + dull clunk.

4. EXIT AND FINALE
- Trigger: all 8 rooms home (forces center empty). Check after every slide.
- On solve: soft chime, every doorway swings open, Foyer front door unlocks and swings open (when Foyer is out of place it remains solid and locked).
- Finale: walk through front door onto red carpet across a lawn, rainbow mesh fades in, camera stops at carpet end, fade to title. Cut rainbow if short on time.

5. START STATE AND SCRAMBLE
- Generate by random legal PLAYER moves from solved (walk / slide). All moves reversible => solvable. Spawn player where scramble walk ended.
- BFS true optimum under walking rules (state = room permutation + player cell). Accept only if optimal solve is 14-20 slides (est.).
- Spawn room must have an open doorway facing the empty slot. Reject otherwise.
- Random seed per launch; plus a fixed curated seed for the jam build.

6. SCALE AND FEEL (est.)
- Room interior 6x6 m, walls 0.25 m, ceiling 3.0 m. Doorways 1.2 x 2.2 m. Windows 1.4 m wide, sill 0.9 m.
- Eye height 1.65 m, walk 3.0 m/s, no sprint/jump/crouch. Accel ~0.1 s, head-bob off by default.
- FOV 75 (setting 60-100). Raw mouse, invert-Y option. Controller nice-to-have.
- Slide: 1.4 s ease-in-out, 0.1 s anticipation shudder, stone-grind loop, heavy thud + 0.15 s small camera shake on landing. Input locked during slide.

7. ART DIRECTION
- Flat-shaded low-poly, clean silhouettes, little texture noise. Own palette: late-afternoon warm light, cream plaster walls, warm wood floors, one strong accent per room. Exterior: soft green meadow, low golden sun, pale sky. Empty slot floor: pale stone with faint inset border.

8. AUDIO
- Outdoor bed (birds, wind) louder near outside-facing windows (edge cue).
- Per-room low loops: bedroom clock tick, bathroom drip, study page rustle, kitchen fridge hum, living fire crackle, dining cutlery, foyer wind under door, laundry dryer tumble.
- Music: sparse piano/strings, low under SFX (~30-40% of SFX), ducks during slides.
- SFX: lever lock, lever clunk, door rattle, door swing, slide grind + thud, solve chime, front door creak.

9. UI (Nick's no-slop rule)
- No instruction text, tutorial popups, labels, room names, move counter, or minimap.
- Center dot reticle; ring when looking at interactable. Lever shows four faint arrows only while held; valid direction glows.
- Title: logo + play icon. Pause: icon buttons. Settings: icons/sliders, minimal words.

10. FUN TEST (bar before polish)
- Greybox. Pass if 4/5 fresh testers solve in 5-20 min and make first slide within 90 s. Fail: >2 min wandering without lever; solves <3 min.
