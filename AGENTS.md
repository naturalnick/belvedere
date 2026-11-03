# Shifting Manor

Follow Nick's global guidelines in `/Users/nick/.codex/AGENTS.md`.

First-person 3D sliding-room puzzle. Godot 4.7, Compatibility renderer. Spec: `docs/SPEC.md`; amendments and decisions: `docs/DECISIONS.md`; art: `docs/STYLE.md`.

Commands (kept in `tools/`; update this list when scripts change):
- Run: `tools/run.sh`
- Rule + solver tests (headless): `tools/test.sh`
- Classic-mode fun-test bots + geometry probes (headless): `tools/fun_test.sh` → `docs/FUNTEST.md`
- Screenshots: `tools/capture.sh [stage3|objectives|single-gap|courtyard|solve|review] [seed] [out_dir] [extra flags]`
- Web build (local zip, never uploaded): `tools/build_itch.sh`
- Read-only export scope/identity preflight: `python3 tools/check_export_identity.py`

Controls: WASD/mouse; hold left mouse or E on the lever, push mouse/WASD, release. Desktop captures the pointer on launch; Escape releases it and shows the play icon. `tools/run.sh` starts eight rooms and one gap on the 3×3 grid, using seed A with lawn access through the gap. Seven room-light objectives give the main win; placing all eight rooms home gives the bonus exit. Completed objectives remain earned when moved. `--seed=B|C|random|<index>` selects other original starts. `--courtyard` retains the earlier six-room/three-gap experiment. `tools/run.sh --classic --seed=A` selects the old eight-room jam layout (`--classic` alone selects a random accepted state); `--invert-y` inverts mouse Y.

The macOS Unsigned Test preset is authorized only for local unsigned/unnotarized testing in Stage 8; run the identity preflight first.

Rules: the title screen may show “Shifting Manor”; otherwise no visible instruction text, labels, room names, counters or taglines. Title and pause have persistent sound on/off and settings icons. Settings cover FOV, sensitivity, invert-Y, camera shake (off by default), and master/effects/music volumes. Audio remains deferred. All art and audio original or CC0 with entries in `docs/CREDITS.md`. Never push or publish.
