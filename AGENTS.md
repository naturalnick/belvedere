# Shifting Manor

Follow Nick's global guidelines in `/Users/nick/.codex/AGENTS.md`.

First-person 3D sliding-room puzzle. Godot 4.7, Compatibility renderer. Spec: `docs/SPEC.md`; amendments and decisions: `docs/DECISIONS.md`; art: `docs/STYLE.md`.

Commands (kept in `tools/`; update this list when scripts change):
- Run: `tools/run.sh`
- Rule + solver tests (headless): `tools/test.sh`
- Fun-test bots + geometry probes (headless): `tools/fun_test.sh` → `docs/FUNTEST.md`
- Screenshots: `tools/capture.sh [mode] [seed] [out_dir]`
- Web build (local zip, never uploaded): `tools/build_itch.sh`
- Read-only export scope/identity preflight: `python3 tools/check_export_identity.py`

Stage 1 controls: WASD/mouse; hold left mouse or E on the lever, push mouse/WASD, release. Escape releases the pointer. `tools/run.sh --seed=A` selects the jam layout (default: random accepted state); `--invert-y` inverts mouse Y.

Rules: no visible instruction text, labels, room names, counters or taglines. All art and audio original or CC0 with entries in `docs/CREDITS.md`. Never push or publish.
