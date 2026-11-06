#!/usr/bin/env python3
"""Package the approved PNG artwork as native icons using macOS tools."""
from pathlib import Path
import struct
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
ICONS = ROOT / "assets/icons"


def resize(source: Path, destination: Path, size: int) -> None:
    subprocess.run(
        ["sips", "-z", str(size), str(size), str(source), "--out", str(destination)],
        check=True, stdout=subprocess.DEVNULL,
    )


def main() -> None:
    with tempfile.TemporaryDirectory(prefix="belvedere-icons-") as directory:
        work = Path(directory)
        iconset = work / "Belvedere.iconset"
        iconset.mkdir()
        for size in (16, 32, 128, 256, 512):
            for scale in (1, 2):
                suffix = "@2x" if scale == 2 else ""
                resize(ICONS / "belvedere-macos.png",
                       iconset / f"icon_{size}x{size}{suffix}.png", size * scale)
        subprocess.run(
            ["iconutil", "-c", "icns", str(iconset), "-o", str(ICONS / "belvedere.icns")],
            check=True,
        )

        # Include every default Godot icon size so no executable resource retains its logo.
        sizes = (16, 32, 48, 64, 128, 256)
        entries = bytearray(struct.pack("<HHH", 0, 1, len(sizes)))
        payloads = bytearray()
        offset = 6 + 16 * len(sizes)
        for size in sizes:
            png = work / f"windows-{size}.png"
            resize(ICONS / "belvedere-windows.png", png, size)
            data = png.read_bytes()
            entries.extend(struct.pack("<BBBBHHII", size % 256, size % 256,
                                       0, 0, 1, 32, len(data), offset))
            payloads.extend(data)
            offset += len(data)
        (ICONS / "belvedere.ico").write_bytes(entries + payloads)
    print("Generated assets/icons/belvedere.icns and belvedere.ico")


if __name__ == "__main__":
    main()
