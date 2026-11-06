# Belvedere

Follow Nick's global guidelines in `/Users/nick/.codex/AGENTS.md`.

First-person 3D sliding-room puzzle in Godot 4.7 (Compatibility renderer). The current design, reasons and rejected ideas are in `docs/SPEC.md`. Keep it current by editing in place; don't add history or changelog sections. Asset licences: `docs/CREDITS.md` (packed into builds).

## Commands
Kept in `tools/`; update this list when the scripts change.
- Run: `tools/run.sh [--seed=A|B|C|random|<index>]`
- Conservatory playtest (one final Foyer shift south reveals the room): `tools/try_conservatory.sh`
- Stopwatch playtest (starts on the lawn beside the reachable hatch): `tools/try_stopwatch.sh`
- Rule, solver and scene tests (headless): `tools/test.sh`
- Screenshots (real window): `tools/capture.sh [title|coins|drawers|safe|binoculars|stopwatch|sleep|fall|trees|exterior|furnishings|stage3|objectives|single-gap|conservatory] [seed] [out_dir] [extra flags]`; furnishings accepts `--rooms=5,7`.
- QR flicker check: `tools/check_qr.sh`. Door close-up pixel check: `tools/check_doors.sh [out_dir]`. Render benchmark: `tools/profile.sh [output_json]`.
- Web build (local zip, never uploaded): `tools/build_itch.sh`
- Windows test build (local unsigned zip, never uploaded): `tools/build_windows.sh`
- macOS test build (local unsigned zip, never uploaded): `tools/build_macos.sh`
- macOS release build (Developer ID signed and notarized zip, never uploaded): `tools/build_macos_release.sh`
- Underside QR generate/verify: `tools/gen_qr.sh` (macOS)
- Laundry wall plan: `python3 tools/gen_plan.py` writes `assets/house_plan.svg`
- Export scope/identity preflight (read-only): `python3 tools/check_export_identity.py`
- Regenerate `assets/audio/` from `tools/audio_sources/` (needs ffmpeg + oggenc): `tools/gen_audio.sh [--conservatory-only]`

## Rules
- Visible text is limited to: the title "Belvedere" and "Play"; short functional title/pause/settings/controls labels (Binoculars — B and Stopwatch — T only while owned); the binocular reward's "Binoculars" and "Press B to use"; the token reward's "Token" and "Collect them all"; the stopwatch reward's "Stopwatch", "Shows the fewest shifts needed for assembly." and "Press T to use"; the red key reward’s “Red Key” and “To your success”; the stopwatch's number-only readout; the bed confirmation’s “Start over?”, “Sleep to reset the rooms. Keep your tokens and items.”, “Sleep” and “Cancel”; the coin HUD count; the period-key frame-rate readout ("60 FPS"); the cabinet's number-only readout; Thanks for Playing with Keep Playing / Quit to Menu; the eight overview roof numbers; the three ending lines; and the final run totals labeled “Shifts”, “Sleeps” (with a trailing asterisk when falls are included), “Time”, and “Any key to continue”. No other instructions, room names, counters or taglines. All text uses bundled Fondamento Regular.
- Audio stays quiet and physical, within the scope listed in SPEC.
- All art and audio must be original or CC0, with an entry in `docs/CREDITS.md`.
- Never push or publish.
- The macOS Unsigned Test preset is authorized only for local unsigned/unnotarized testing. Run the identity preflight first.
- The macOS Release preset is authorized for Developer ID signing and notarization with team `ULBH832X6Q` only. Uploading the result is Nick's.
- The Windows Test preset is authorized only for local unsigned testing.
