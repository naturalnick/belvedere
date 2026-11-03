# Belvedere

Follow Nick's global guidelines in `/Users/nick/.codex/AGENTS.md`.

First-person 3D sliding-room puzzle. Godot 4.7, Compatibility renderer. Spec: `docs/SPEC.md`; amendments and decisions: `docs/DECISIONS.md`; art: `docs/STYLE.md`.

Commands (kept in `tools/`; update this list when scripts change):
- Run: `tools/run.sh`
- Rule + solver tests (headless): `tools/test.sh`
- Classic-mode fun-test bots + geometry probes (headless): `tools/fun_test.sh` → `docs/FUNTEST.md`
- Screenshots: `tools/capture.sh [title|coins|fall|trees|furnishings|stage3|objectives|single-gap|courtyard|solve|review] [seed] [out_dir] [extra flags]`
  Furnishing captures accept `--rooms=5,7` to inspect selected rooms.
- Door-frame close-up pixel check (real window): `tools/check_doors.sh [out_dir]`
- Render submission benchmark (real window): `tools/profile.sh [output_json]`
- Web build (local zip, never uploaded): `tools/build_itch.sh`
- Read-only export scope/identity preflight: `python3 tools/check_export_identity.py`
- Regenerate `assets/audio/` from the CC0 sources in `tools/audio_sources/` (needs ffmpeg + oggenc): `tools/gen_audio.sh`

Controls: WASD/mouse; hold left mouse or E on the lever, push mouse/WASD, release. Default seed A opens on the Bedroom wall title; Play captures the pointer and starts from that same viewpoint. Escape releases it and shows the pause play icon. `tools/run.sh` starts eight rooms and one gap on the 3×3 grid, using seed A with lawn access through the gap. The permanent Bedroom wall fixture is a spaced 3×3 grid: nine squares in one textured warm-gray color, with the target room’s current board position light blue (initially lower-left). The wall grid has west at the top to match the viewing direction; the marker updates when the target changes or its room moves. The large wall title and Play button fade out together over 0.55 seconds when starting; no title backdrop. Alternate seeds and legacy modes retain their original spawn positions. Seven room objectives award blue Bel coins, each presented with a solid stamped bell emblem before entering the HUD wallet. The small HUD coin is unlettered; coins have no glow or halo. Start with no coins: the already-home Laundry is the first blue target in seed A, and entering it starts a one-time guided look: gently face the blue lamp, hold, show it turn warm, then present the opening coin and return control once it reaches the wallet. Escape pauses the sequence. E or left mouse inserts one coin into the Foyer cabinet; seven deposits release the trophy and a Thanks for Playing screen (Keep Playing / Quit to Menu). Blue light and a subtly blue shade mark the target room (including the already-home opening target); warm room/Foyer lights track current placement. Earned coins remain owned when rooms move. Placing all eight rooms home still unlocks the separate front-door ending. Walking off the meadow gives a fifteen-second fall, then a fade back to the current Bedroom bedside with progress retained. `--seed=B|C|random|<index>` selects other original starts. `--courtyard` retains the earlier six-room/three-gap experiment. `tools/run.sh --classic --seed=A` selects the old eight-room jam layout (`--classic` alone selects a random accepted state); `--invert-y` inverts mouse Y.

The macOS Unsigned Test preset is authorized only for local unsigned/unnotarized testing in Stage 8; run the identity preflight first.

Rules: the title screen may show “Belvedere”; the authorized additional text is the coin HUD count, cabinet number-only remaining-coins readout, and Thanks for Playing with Keep Playing / Quit to Menu. Otherwise no visible instruction text, labels, room names, counters or taglines. Title and pause have persistent sound on/off and settings icons. Settings cover FOV, sensitivity, invert-Y, and master/effects/music volumes. Audio is quiet and physical: footsteps, lever, doors, room slides, coin insertion, distant birds outdoors only (no wind, no room loops, no completion chime), and a replaceable music loop at `assets/audio/manor_theme.ogg`. All visible text uses bundled Fondamento Regular (SIL OFL 1.1). All other art and audio original or CC0 with entries in `docs/CREDITS.md`. Never push or publish.
