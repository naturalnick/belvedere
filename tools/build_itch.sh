#!/bin/sh
# Builds only local files. No upload or publishing step.
set -eu
cd "$(dirname "$0")/.."
python3 tools/check_export_identity.py
mkdir -p build/itch
STAGING="$(mktemp -d "$(pwd)/build/itch/staging.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT HUP INT TERM
godot --headless --path . --import
godot --headless --path . --export-release Web "$STAGING/index.html"
python3 - "$STAGING" <<'PY'
from pathlib import Path
import hashlib
import sys
import zipfile

source = Path(sys.argv[1])
(source / 'LICENSE.txt').write_bytes(Path('LICENSE.txt').read_bytes())
(source / 'CREDITS.md').write_bytes(Path('docs/CREDITS.md').read_bytes())
font_license = source / 'assets/fonts/Fondamento-OFL.txt'
font_license.parent.mkdir(parents=True, exist_ok=True)
font_license.write_bytes(Path('assets/fonts/Fondamento-OFL.txt').read_bytes())
for name in ('index.html', 'index.js', 'index.wasm', 'index.pck'):
    assert (source / name).stat().st_size > 0, f'Missing or empty export: {name}'
files = sorted(path for path in source.rglob('*') if path.is_file())
assert len(files) <= 1000 and sum(p.stat().st_size for p in files) <= 500_000_000
assert all(p.stat().st_size <= 200_000_000 for p in files)
output = Path('build/itch/belvedere-web.zip')
with zipfile.ZipFile(output.with_suffix('.zip.tmp'), 'w', zipfile.ZIP_DEFLATED) as archive:
    for path in files:
        archive.write(path, path.relative_to(source).as_posix())
output.with_suffix('.zip.tmp').replace(output)
output.with_suffix('.zip.sha256').write_text(hashlib.sha256(output.read_bytes()).hexdigest() + '  ' + output.name + '\n')
print(f'Built {output.resolve()} ({output.stat().st_size / 1_000_000:.1f} MB)')
PY
rm -rf build/itch/web
mv "$STAGING" build/itch/web
