# Belvedere — current design

This file holds the current design and the reasons behind non-obvious choices. Edit sections in place when the design changes; do not append history. Exact values live in code; numbers here are the ones Nick chose deliberately.

## Conventions
- Slot index = row*3 + col; row 0 = north, col 0 = west; slot 4 = center.
- Room id = home slot: 0 Bedroom, 1 Bathroom, 2 Study, 3 Kitchen, 5 Living, 6 Dining, 7 Foyer, 8 Laundry; -1 = empty slot (gap).
- Directions N=0 E=1 S=2 W=3. A room side is a doorway if it is interior in the solved layout, otherwise a window. Foyer south is the front door and blocks walking like a window.

## Board and rules
- 3×3 grid, eight rooms, one gap. Rooms never rotate. 6 m interiors, 0.25 m walls (two 0.125 m halves, one per room, so faces never coincide), 6.25 m slot pitch, 3 m ceilings, eye height 1.65 m, 3 m/s walking.
- Glazed double doors open automatically when the facing side is the gap or another room's doorway; otherwise they stay shut and both leaves rattle on use. Windows never allow walking, but slides are legal across any side.
- Lever: hold E or left mouse on it, push mouse/WASD (view-relative, converted to world axes), release. Into the gap = the whole room slides with the player riding; otherwise a wooden clunk. Slide = 1.6 s (0.09 s take-up, 1.43 s travel with half-second braking, 0.08 s docking), no overshoot or shake; input is locked and board state commits once on docking. Doors close in transit and re-evaluate on landing.
- The gap is dark concrete with flush crossing tracks, recessed 2 cm to avoid coplanar faces with passing rooms. When the gap is on the perimeter you can walk out onto the lawn and back in through it. Exterior doors stay blocked.
- Every room carries its furniture, fixtures, clues and floor patterns when it slides.

## Starts and modes
- Default launch = seed A `[6,2,5,0,1,3,7,-1,8]`. The game opens on the Bedroom wall title. Other seeds keep their original spawns, 1.7 m behind the lever facing the gap.
- `--seed=B|C|random|<index>` picks from `data/accepted_14_20.json`: 1,816 states that are 14–20 optimal slides from solved, with the player's room having a doorway open to the gap. The spec's random-walk scramble was replaced because simulation (`tools/sim/`) showed random walks barely leave solved. Only 7% of boards are reachable; there are no dead states.
- `--classic` = the original single-goal jam puzzle with a perimeter barrier (random accepted start unless `--seed`). `--courtyard` = archived six-room/three-gap experiment. Both keep their tests; don't extend them.
- `--invert-y`, `--web-entry` (exercises the web play-gesture path natively).

## Rooms and furnishings
Accent colours: Bedroom dusty blue, Bathroom sea-glass, Study deep green, Kitchen mustard, Living terracotta, Dining plum, Foyer cream/wood with a checker floor, Laundry slate blue. The accent goes on one wall and on the door casings, so a room can be identified through any neighbour's glass.
- Static, original low-poly furniture with simple colliders. Keep a 1.2 m ring clear around each lever and clear approaches to all four sides. Exceptions: Bedroom (0.75 m ring; the bed is centered under the northwest window with the bedside table on its west side) and Dining (a 2.3 m table 1.55 m west of the lever, with an aisle around both ends). Tall storage stays on solid walls; window sightlines stay clear.
- Foyer: trophy cabinet NW, bench NE, coat and umbrella stands SE, console/mirror SW. Study safe under the east windows between the globe and reading chair. The tub is pulled out of its NW corner.
- Decorative lamps and the fireplace stay unlit, so only objective fixtures signal game state. Mirrors are painted highlights, not reflections.
- Budgets: ≤60 furniture/trim meshes in Bedroom and ≤90 in other rooms.

## Objectives, coins, trophy
- Seven objective rooms (all except Foyer) award one blue Bel coin each, in sequence. The next target is the unfinished room with the fewest legal slides from the current layout (forward 0–1 BFS: slides cost 1, walks 0), computed only when a target activates or completes. Rooms already home are credited during selection. Completion is permanent and never locks a room in place.
- Seed A: Laundry is already home and is the first target. Entering it triggers a one-time guided look: the camera eases to the blue lamp, holds, shows the lamp turning warm, then presents the coin. Later targets never take the camera.
- Lights: the target's pendant is steady blue `#6EBFFF` with a blue-tinted shade. Other objective rooms that are home are warm white `#FFF0DA`. Everything else is off. The seven Foyer chandelier lights show which objective rooms are currently home, not coins.
- Rewards (coins, binoculars) fly to a presentation in front of the camera and stay until any fresh key, mouse button or gamepad button is pressed. That press is consumed. Presses made while the reward is still arriving are swallowed. Mouse motion and the wheel never accept. Each queued reward needs its own press. Presentations wait during pause, slides, recovery and binocular use. The large coin has a stamped bell emblem; the HUD coin is unlettered; nothing glows.
- The Foyer cabinet takes one coin per fresh E/click, with a visible insertion and recorded clink. Its readout shows only the number of coins still needed. The seventh deposit releases the trophy and opens Thanks for Playing (Keep Playing / Quit to Menu). Keep Playing retains all state.

## Assembled-house ending (independent of coins)
All eight rooms home opens the red front door (3.5 s; it blocks until fully open), lights its house emblem and awards any outstanding coins. Crossing the doorway eases the camera 20 s along a red carpet under a pastel rainbow, then holds 18 s and fades to title. Plain white Fondamento text without outlines: "Belvedere" (1.8 m high, fades in over the first 10 s); on arrival "A game by Nick Schaefer" (4 s fade), a 3 s wait, "Thank you for playing" (4 s fade), then a 7 s hold. The lower two lines sit closer to the camera so the three lines have equal visible gaps. Stemless flowers sprout every 0.15 s, only inside the camera frustum, 2.5–12 m ahead, from a 160-instance MultiMesh without shadows. Escape pauses everything; Resume continues the same timeline.

## Study safe and fruit clues
- Four plain buttons count fresh taps independently and in any order: red 3, yellow 2, orange 4, green 1. Turning the handle checks the counts. A wrong attempt rattles and clears all taps; a correct one opens the door and presents the binoculars. No digits, tallies or labels. Safe state survives slides and falls.
- Clues: 3 apples on the Kitchen prep table, 2 separate bananas on the lower shelf of Dining's china cabinet, 4 oranges on Living's 0.90 m sideboard, 1 pear on the Bedroom dresser. Each clue renders only on pixels whose camera ray enters its own room through a window or a fully closed glass door. It is never visible indoors, through open or moving doors, or from above. No outline or shadow pass, which would leak it. Fruit stays out of static batches so its mask follows slides.

## Binoculars
B raises them along one arc, cuts through dark to a north-up orthographic overview of the live manor, and B again returns to the exact first-person view. Overview only: room-coloured roofs replace ceilings, carrying home-order numbers 1 2 3 / 4 · 5 / 6 7 8 that move with the rooms. Door lintels are hidden. Window-wall tops get black 0.34 m borders; doorways and the front door get none. A small cream dot marks the player. Shadows stay on. Movement, interaction and slides are locked while viewing. The player starts without them; opening the Study safe is the only way to earn them.

## Exterior and fall
- A meadow with low hills. 15 near trees, eight mixed broadleaf/pine groves plus four lone trees, and a hazy 88–104 m treeline with a gap behind the rainbow. All are composed for views from the house. Keep the Bedroom window tree at (-17, -6.9), the current minimum clearance from the house, and an open south carpet approach.
- Walking off the meadow edge gives a ~15 s fall past a flat dark casing whose underside carries a large unlit QR code (https://puzzaholics.com/belvedere-assembly, error correction Q, `tools/gen_qr.sh`). The QR fills an exact opening in the casing, not a coplanar backing, which flickered. Then the screen fades and the player wakes near the foot of the bed in the Bedroom's current position with all progress kept.

## Title, pause, menus
- The seed A title is painted on the Bedroom's west wall: large "Belvedere" and "Play" in ink, with no backdrop. Both fade over 0.55 s when Play captures the pointer; control returns at the same view. The 3D scene fades in over 1.4 s on launch while the menu stays visible.
- The permanent wall fixture is a spaced 3×3 grid of warm-gray squares. The target room's current board slot is light blue. The grid shows west at the top and north to the right, matching the view of this wall. It updates on target changes and slides, rides with the Bedroom, and shows no blue once all objectives are done.
- Escape or P pauses (Controls shows "Esc / P"), and the same key resumes from the pause menu, not from Settings or Controls. Reward presentations never accept either key. Web exception: Escape does not resume, because browsers never grant pointer lock from Escape (it is not a user-activation key) and the menu would bounce back; P and Resume do.
- Web: losing pointer lock during play opens the pause menu, because browsers end the lock themselves (Escape, tab switches, clicks outside the canvas) without passing Escape to the game. Lock requests resolve after the click, so only a granted lock that ends, or a request still unmet after 1 s, pauses. Slides and falls finish first, matching Escape. `tests/pointer_tests.gd` covers this with `--web-entry`.
- Title and pause have Play/Resume, Controls, Settings and Sound: On/Off. Controls lists Move, Look, Interact, Pull lever and Pause, plus Binoculars — B only while owned. Settings: FOV 60–100, sensitivity, invert-Y, master/effects/music volume, persisted in `user://settings.cfg`.
- Buttons are plain lettering: hover/focus tints the word and pressing lowers it 2 px. Focus tints appear only after keyboard input, and hover never moves focus (Enter after hovering Quit must not quit).

## Audio
- Recorded CC0 foley shaped by `tools/gen_audio.sh`, kept at natural speed (pitch-stretching sounded synthetic). Three footstep sounds every 1.05 m: soft (wood rooms, rugs, carpet), normal (tile rooms, gap) and grass (quiet). Lever grab/return clicks and a blocked clunk. One 2 s slide sound that lands on docking; music ducks 6 dB. Only the nearest opening and nearest closing door are voiced. Locked-door rattle = handle catch plus one push. Coin acquisition and insertion clinks.
- A distant bird loop plays only outdoors (gap or lawn), very quiet (−33 dB). Menu presses (never hover) play one brass latch click (`ManorAudio.MENU_CLICK`), deferred so muting is silent and unmuting is audible.
- Music: replaceable loop `assets/audio/manor_theme.ogg` (an original felt-piano loop) at 35%. It starts after 3 s and fades in over 5 s, multiplied by slide ducking.
- Web: the Effects and Music buses must exist in `default_bus_layout.tres`, because non-threaded web audio ignores buses added at runtime. Music fade follows the heard playback position because browsers hold audio until the first input. Headless runs skip playback but emit `ManorAudio.cued` for tests.

## Art and rendering
- Late-afternoon warm light, cream plaster, warm wood, one strong accent per room, chunky readable furniture and little clutter. Flat-shaded low poly, original geometry generated in code; no downloaded models or textures. No reference images are stored.
- Godot 4.7 Compatibility renderer, so web matches desktop. One shared toon shader (`shaders/toon.gdshader`): 3-band ramp, room shadow tint and a faint paper grain. Inverted-hull warm-brown ink outlines, never black. The grain, outline wobble, planks and tiles are sampled in mesh-local space, because world-space sampling made surfaces swim during slides. No post-processing, bloom or fog.
- Sun `#FFD9A8`, pitch −28°, yaw 235°, 2 PSSM splits, 40 m shadows; sun patches on floors are a key image. Wall corners are butt-jointed and trims sit on their owner's interior side: no coplanar opaque faces with different colours (tested). No hull expansion on adjoining wall planes or thin door joinery, which caused detached ink strips.

## Performance
Most cost is the sun's shadow pass. Batched outline shells are separate non-casting geometry. Furniture the fixed sun can never reach through its own room's openings casts no shadow (`scripts/manor_sun_reach.gd`, ray-checked by `tests/shadow_tests.gd`). Repeated opaque pieces are batched per rigid assembly and room shell; glass stays separate. Foliage is unshaded vertex colour, merged into one mesh per 32 m cell or treeline sector; only trees within 46 m cast shadows. Because unshaded foliage can't darken, shrubs and casting grove trees sit outside tree and house shadows. MultiMesh batches keep custom bounds. Godot's dummy renderer doesn't store MultiMesh transforms, so headless geometry checks keep their own. Untried next steps: per-material merging of room singletons, and portal culling. Measure with `tools/profile.sh`.

## Rejected — don't reintroduce
Camera shake (and its setting); pulsing, scaling or animated objective indicators; floor targets, arrows and check marks; a target diagram in the overview; completion chimes; outdoor wind, per-room ambient loops and a front-door creak; a separate rug footstep; tonal or bright hard-floor steps; birds indoors; digits or tally marks on the safe; menu hover pills, a circular Play icon and ornamental diamonds; a smiley meadow underside; billboard or pancake trees and evenly scattered trees; doorway borders in the overview; lit decorative lamps.

## Open items
- A five-person human playtest is still owed. The original pass bar: at least 4/5 testers make their first slide within 90 s and solve in 5–20 minutes. The bot proxy in `docs/FUNTEST.md` covers classic mode only.
- The objective guidance has not been validated with human players.

## Exports and notices
- Web: a local itch zip via `tools/build_itch.sh`, never uploaded. macOS Unsigned Test preset: bundle id `com.puzzaholics.shiftingmanor`, signing and notarization off, local testing only. No production signing identity exists. `apple-identity.json` + `tools/check_export_identity.py` are the read-only baseline and preflight.
- Ownership notice: `LICENSE.txt` (packed), `Manor.NOTICE`, `application/config/description`, prepended to the web `index.html`/`index.js` by `build_itch.sh`, and the macOS copyright. This is a deterrent, not protection.
