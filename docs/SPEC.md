CURRENT GAME (2026-11-03): Eight rooms and one gap on the 3×3 grid, default seed A [6,2,5,0,1,3,7,-1,8], player in Bedroom facing its west wall between the windows. Dark gray concrete and two perpendicular pairs of flush crossing tracks mark the gap. A perimeter gap leads onto the lawn and allows reentry; ordinary exterior-facing doors and windows remain blocked.

SLIDE FEEL: Total 1.4 seconds: 0.09-second take-up, 1.23-second travel with smooth acceleration and firmer braking, then 0.08-second docking. No overshoot, camera shake or extra lever animation. Input remains locked until docking finishes.

ROOM OBJECTIVES / TROPHY ENDING: Seven sequential room objectives, excluding Foyer, award blue Bel coins. Bringing the active room home earns one permanent coin; the first target is an already-home room when one exists, and entering it starts a one-time guided look: gently face the blue lamp, hold, show it turn warm, then present the opening coin and return control once it reaches the wallet. Escape pauses the sequence. The player starts with no coins or pending rewards. Later already-home rooms are credited when choosing the next target. Earned coins are presented prominently one at a time with a solid stamped bell emblem, then travel into the on-screen wallet count with a short, soft coin-acquired sound on arrival. The small HUD coin is unlettered, and neither coin display has a glow or halo; no pickup is required. The next unfinished target is selected from the current arrangement using the fewest legal slides, with door restrictions respected. Each room can award only one coin, even after it moves away and returns. A brass-and-wood trophy cabinet in the Foyer accepts one coin per fresh E or left-mouse press, animates its insertion and plays recorded coin clinks. Its readout shows only the number of coins still required, without words. The seventh deposit releases a visible trophy and opens a “Thanks for Playing” screen with “Keep Playing” and “Quit to Menu”. Collecting all coins alone does not open an ending screen or unlock the front door. Continuing retains the trophy, deposits and room state.

PLACEMENT LIGHTS: The active target pendant is steady blue (#6EBFFF), with a lightly blue-tinted shade and unchanged brass stem. Blue takes priority over placement until that target completes. Any non-target objective room currently home has a warm-white pendant (#FFF0DA); a room that is neither targeted nor home is unlit. The seven warm-white Foyer chandelier globes correspond only to the seven objective rooms currently home, never to targets, collected coins or deposits. Moving a room away extinguishes its placement lights without removing its earned coin. No floor targets or animated objective indicators.

BONUS WIN: All eight rooms home simultaneously. This also earns any remaining room coins, but the trophy still requires all seven deposits. The solid, opaque red Foyer front door opens over 3.5 seconds, blocking passage until fully open; its house emblem lights, the carpet appears and a rainbow fades in. Crossing that doorway eases the camera along the carpet over 20 seconds, with small flowers continually sprouting on nearby grass, then holds for 18 seconds before fading to the title screen. Plain white Fondamento “Belvedere” lettering without an outline spans 8 m beneath the rainbow at 1.8 m above ground, fading in over the first ten seconds of the walk. After stopping, “A game by Nick Schaefer” fades in below it over four seconds, followed by a three-second wait, a four-second fade of “Thank you for playing”, and a seven-second final hold. Escape pauses the movement, text fades, flower spawning and growth, and final fade; Resume continues from the same point. The coin trophy leaves that door locked until the entire house is assembled.

FURNISHINGS: All eight rooms are furnished with original static geometry. Bedroom: bed centered beneath the northwest window with bedside cabinet on its west side, wardrobe, dresser/mirror, reading chair and rug. Bathroom: slightly enlarged clawfoot tub pulled away from the northwest corner, washstand/mirror, towels, stool and hamper. Study: writing desk/chair, bookcase, globe and reading chair. Kitchen: sink counter, range/counter, fridge and preparation table. Living: sofa/rug, coffee table, fireplace, inward-facing southwest armchair and sideboard. Dining: central six-seat table west of the lever, sideboard, china cabinet and serving table. Foyer: trophy cabinet northwest, entry bench northeast, coat stand beside the umbrella stand southeast, and console/mirror southwest. Laundry: washer/dryer, utility sink, boot bench/coats and folding table. Keep levers and doorway approaches clear, with a 1.2 m walking ring except in Bedroom (0.75 m radius around the lever clears the centered bed) and Dining (an aisle passes around the longer table to the west windows). Decorative lamps and fireplace remain unlit; only objective fixtures signal game state. Bathroom/Kitchen/Laundry have shader tile floors; Foyer has the specified checker floor. Wood floors have faint plank joins. Furniture and floor patterns ride with their rooms.

STUDY SAFE: A low iron safe sits against the east window wall, between the globe stand and reading chair, away from the desk. Four plain red/yellow/orange/green buttons accept independent fresh E/left-mouse taps, in any order, with physical depression and quiet clicks. The required counts are 3/2/4/1; there are no printed digits, tally indicators, labels or puzzle HUD. The handle checks the attempt: wrong counts rattle and reset all taps; correct counts unlock and swing the door open. The compartment holds binoculars. After the door opens they automatically fly out, present in front of the player, then shrink toward an unlettered binocular HUD icon; no pickup input is needed. The safe and its state move with Study and survive falls; a new game resets them. Pause suspends feedback and opening animations.

BINOCULARS: B toggles the owned item. A physical raise animation brings the binoculars to the eyes, briefly fades through dark, and reveals a centered, north-up orthographic view of the live manor. B again restores the original first-person camera and lowers the binoculars. Keep normal shadows. In overview only, replace ceilings with room-colored roofs labeled 1–8 in Fondamento: the home arrangement is 1 2 3 / 4 gap 5 / 6 7 8. Numbers belong to rooms and travel with them. No target diagram is shown. Hide normal-door lintels; show only black window-wall borders. Roof color extends to the room edges, covering doorway and front-door wall tops without borders. A small cream player-position dot supplies location context. The full 3×3 board fits with a margin based on the viewport aspect. No room names, instructions or remote controls are added. Movement, interactions and slides are locked during use/reward presentation, while Escape pauses as usual. Pending coin presentations wait until binocular use finishes. Fruit clues is hidden in the overview. Ownership is retained through room moves and falls. For this first testing pass binoculars are granted at startup; `--earn-binoculars` exercises the normal locked-safe progression.

WINDOW FRUIT CLUES: Kitchen has 3 red apples on the preparation table; Dining has 2 separate yellow bananas on the china cabinet’s lower shelf, replacing its three bowls; the upper shelf retains its bowls; Living has 4 oranges on the sideboard; Bedroom has 1 green pear on the dresser beside the mirror. Each fruit has a distinct silhouette and clear spacing. The bananas sit on the 0.68 m shelf and are visible through the south window. Living’s sideboard has a 0.90 m top to keep clues above the window-sill sightline, with its books behind the oranges. Each clue renders only where the camera-to-fruit ray enters its own room through a window aperture or a fully closed glass door. It is invisible indoors and through open or moving doors, with no leaked outline or shadow. Clues ride with their rooms and can be seen through windows from a neighboring room, the gap or lawn.

TITLE/PAUSE: Default seed A starts in the Bedroom facing the west wall between its two windows. Large dark Fondamento “Belvedere” lettering and a Play icon sit on the wall without a cover backdrop; both fade out together over 0.55 seconds when Play captures the pointer, then control is released at the same viewpoint. Above them is a permanent, slightly spaced 3×3 fixture of nine squares. All non-target squares share one textured warm-gray color (#877D6D); the active target room’s current board position is light blue (lower-left initially). Orient only the wall grid with west at the top and north to the right, matching the player facing this wall. Update the marker when the target changes or its room slides; this guides the player to the blue lamp, not its eventual home. No square is blue after all objectives complete. The fixture rides with the Bedroom. Returning to the menu restores the wall view; playing again starts a fresh game. Alternate seeds and archived modes retain their original spawns. The 3D scene fades in over 1.4 seconds on launch while menu controls stay fully visible. Both title and pause offer labeled Play/Resume, Controls, Settings and Sound: On/Off buttons. Controls list Move (WASD), Look (Mouse), Interact (E / Left click), Pull lever (Hold E + WASD), and Pause (Esc). Binoculars (B) appears only while owned, including the temporary testing grant. Settings labels identify FOV (60–100), sensitivity, invert-Y, and master/effects/music volumes; all persist across launches. There is no camera shake, so there is no shake preference. Audio scope is amended in DECISIONS.md (Audio pass).

Run tools/run.sh. --courtyard retains the six-room/three-gap experiment; --classic retains the original single-objective rules and perimeter barrier. The historical specification below describes the earlier design; docs/DECISIONS.md records amendments.

BELVEDERE — BUILD SPEC v1 (from Game Design Lab, Nov 2 2026). Godot 4, first-person 3D. (est.) = design picks.

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
- Flat-shaded low-poly, clean silhouettes, little texture noise. Own palette: late-afternoon warm light, cream plaster walls, warm wood floors, one strong accent per room. Exterior: soft green meadow, low golden sun, pale sky, and trees composed for house-window views: 15 near trees, eight mixed broadleaf/pine groves with four lone trees, leafy shrubs in sunlight, and a hazy woodland band near the meadow edge that leaves the sky behind the rainbow open. No tree is closer to the house than the original closest tree. The meadow’s flat dark casing has a large white-backed QR underneath linking to https://puzzaholics.com/belvedere-assembly, visible during the fifteen-second fall; no smiley or underside collider. Empty slot floor: pale stone with faint inset border.

8. AUDIO
- Outdoor bed (birds, wind) louder near outside-facing windows (edge cue).
- Per-room low loops: bedroom clock tick, bathroom drip, study page rustle, kitchen fridge hum, living fire crackle, dining cutlery, foyer wind under door, laundry dryer tumble.
- Music: sparse piano/strings, low under SFX (~30-40% of SFX), ducks during slides.
- SFX: lever lock, lever clunk, door rattle, door swing, slide grind + thud, solve chime, front door creak.

9. UI (Nick's no-slop rule)
- No in-world instruction text, tutorial popups, room names, move counter, or minimap. Menu controls and settings use short functional labels; the controls list hides the binoculars binding until owned.
- Center dot reticle; ring when looking at interactable. Lever shows four faint arrows only while held; valid direction glows.
- Title: logo + labeled Play icon. Pause: labeled Resume icon. Both have Controls, Settings and Sound buttons. Settings: labeled sliders and invert-Y toggle.

10. FUN TEST (bar before polish)
- Greybox. Pass if 4/5 fresh testers solve in 5-20 min and make first slide within 90 s. Fail: >2 min wandering without lever; solves <3 min.
