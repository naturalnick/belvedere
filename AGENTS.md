# Shifting Manor

Follow Nick's global guidelines in `/Users/nick/.codex/AGENTS.md`.

First-person 3D sliding-room puzzle. Godot 4.7, Compatibility renderer. Spec: `docs/SPEC.md`; amendments and decisions: `docs/DECISIONS.md`; art: `docs/STYLE.md`.

Commands (kept in `tools/`; update this list when scripts change):
- Run: `tools/run.sh`
- Rule + solver tests (headless): `tools/test.sh`
- Classic-mode fun-test bots + geometry probes (headless): `tools/fun_test.sh` → `docs/FUNTEST.md`
- Screenshots: `tools/capture.sh [fall|trees|furnishings|stage3|objectives|single-gap|courtyard|solve|review] [seed] [out_dir] [extra flags]`
- Door-frame close-up pixel check (real window): `tools/check_doors.sh [out_dir]`
- Render submission benchmark (real window): `tools/profile.sh [output_json]`
- Web build (local zip, never uploaded): `tools/build_itch.sh`
- Read-only export scope/identity preflight: `python3 tools/check_export_identity.py`
- Regenerate `assets/audio/` from the CC0 sources in `tools/audio_sources/` (needs ffmpeg + oggenc): `tools/gen_audio.sh`

Controls: WASD/mouse; hold left mouse or E on the lever, push mouse/WASD, release. Desktop captures the pointer on launch; Escape releases it and shows the play icon. `tools/run.sh` starts eight rooms and one gap on the 3×3 grid, using seed A with lawn access through the gap. Seven room-light objectives give the main win; placing all eight rooms home gives the bonus exit. Completed objectives remain earned when moved. Walking off the meadow gives a fifteen-second fall, then a fade back to the current Bedroom bedside with progress retained. `--seed=B|C|random|<index>` selects other original starts. `--courtyard` retains the earlier six-room/three-gap experiment. `tools/run.sh --classic --seed=A` selects the old eight-room jam layout (`--classic` alone selects a random accepted state); `--invert-y` inverts mouse Y.

The macOS Unsigned Test preset is authorized only for local unsigned/unnotarized testing in Stage 8; run the identity preflight first.

Rules: the title screen may show “Shifting Manor”; otherwise no visible instruction text, labels, room names, counters or taglines. Title and pause have persistent sound on/off and settings icons. Settings cover FOV, sensitivity, invert-Y, and master/effects/music volumes. Audio is quiet and physical: footsteps, lever, doors, room slides, distant birds outdoors only (no wind, no room loops, no completion chime), and a replaceable music loop at `assets/audio/manor_theme.ogg`. All art and audio original or CC0 with entries in `docs/CREDITS.md`. Never push or publish.
