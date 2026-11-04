# Belvedere

Follow Nick's global guidelines in `/Users/nick/.codex/AGENTS.md`.

First-person 3D sliding-room puzzle in Godot 4.7 (Compatibility renderer). The current design, reasons and rejected ideas are in `docs/SPEC.md`. Keep it current by editing in place; don't add history or changelog sections. Asset licences: `docs/CREDITS.md` (packed into builds). `docs/FUNTEST.md` is generated.

## Commands
Kept in `tools/`; update this list when the scripts change.
- Run: `tools/run.sh [--seed=A|B|C|random|<index>] [--classic|--courtyard] [--invert-y]`
- Rule, solver and scene tests (headless): `tools/test.sh`
- Classic-mode bots and geometry probes (headless): `tools/fun_test.sh` → `docs/FUNTEST.md`
- Screenshots (real window): `tools/capture.sh [title|coins|safe|binoculars|fall|trees|exterior|furnishings|stage3|objectives|single-gap|courtyard|solve|review] [seed] [out_dir] [extra flags]`; furnishings accepts `--rooms=5,7`.
- QR flicker check: `tools/check_qr.sh`. Door close-up pixel check: `tools/check_doors.sh [out_dir]`. Render benchmark: `tools/profile.sh [output_json]`.
- Web build (local zip, never uploaded): `tools/build_itch.sh`
- Underside QR generate/verify: `tools/gen_qr.sh` (macOS)
- Export scope/identity preflight (read-only): `python3 tools/check_export_identity.py`
- Regenerate `assets/audio/` from `tools/audio_sources/` (needs ffmpeg + oggenc): `tools/gen_audio.sh`

## Rules
- Visible text is limited to: the title "Belvedere" and "Play"; short functional title/pause/settings/controls labels (Binoculars — B only while owned); the binocular reward's "Binoculars" and "Press B to use"; the token reward's "Token" and "Collect them all"; the coin HUD count; the cabinet's number-only readout; Thanks for Playing with Keep Playing / Quit to Menu; the eight overview roof numbers; and the three ending lines. No other instructions, room names, counters or taglines. All text uses bundled Fondamento Regular.
- Audio stays quiet and physical, within the scope listed in SPEC.
- All art and audio must be original or CC0, with an entry in `docs/CREDITS.md`.
- Never push or publish.
- The macOS Unsigned Test preset is authorized only for local unsigned/unnotarized testing in Stage 8. Run the identity preflight first.
