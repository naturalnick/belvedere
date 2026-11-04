#!/usr/bin/env python3
"""Write assets/house_plan.svg: the wordless floor plan on the Laundry's east wall.

The plan hangs on an east wall, so it is drawn with the direction the viewer faces at the top:
east up, south to the right (the Bedroom wall grid follows the same convention). No room names
or colours: it shows only that windows face out, doors face in, and where the front door is.
"""
from pathlib import Path

SIZE = 2048
MARGIN = 170
CELL = (SIZE - 2 * MARGIN) / 3
# Wall, window and door widths are exaggerated from true scale so they read at a distance.
WALL = 68
WINDOW = 170
WINDOW_OFFSET = 150
DOOR_LEAF = 125

PAPER = "#F5F8FD"
GRID_MINOR = "#E2EAF6"
GRID_MAJOR = "#CFDCF0"
DIMENSION = "#93AEDA"
TRACK = "#BCCDE8"
INK = "#3F68B2"
WALL_FILL = "#BACCEA"
GLASS = "#FBFDFF"
FRONT_DOOR = "#22417F"
CENTER = SIZE / 2

out: list[str] = []


def line(x0, y0, x1, y1, color, width):
    out.append(f'<line x1="{x0:.1f}" y1="{y0:.1f}" x2="{x1:.1f}" y2="{y1:.1f}" stroke="{color}" stroke-width="{width}"/>')


def rect(x0, y0, x1, y1, fill):
    out.append(f'<rect x="{x0:.1f}" y="{y0:.1f}" width="{x1 - x0:.1f}" height="{y1 - y0:.1f}" fill="{fill}"/>')


def hatch(x0, y0, x1, y1, spacing=26):
    """Diagonal lines on a shared lattice, so hatching runs unbroken across wall pieces."""
    k = int((x0 + y0) // spacing) * spacing
    segments = []
    while k <= x1 + y1:
        ax, ay = (k - y0, y0) if k - y0 <= x1 else (x1, k - x1)
        bx, by = (x0, k - x0) if k - x0 <= y1 else (k - y1, y1)
        if ax >= x0 and by >= y0:
            segments.append(f"M{ax:.1f} {ay:.1f}L{bx:.1f} {by:.1f}")
        k += spacing
    return "".join(segments)


def to_screen(horizontal, fixed, along, across=0.0):
    """A point on a wall line: `along` runs the line, `across` steps off it."""
    return (fixed + across, along) if not horizontal else (along, fixed + across)


# Each boundary: horizontal?, fixed coordinate, start of its span, and its contents.
boundaries = []
for i in range(4):
    for j in range(3):
        kind = "window" if i in (0, 3) else "door"
        boundaries.append((True, MARGIN + i * CELL, MARGIN + j * CELL, kind))
        # Screen right is south, and the middle of that edge is the Foyer's south side.
        front = i == 3 and j == 1
        boundaries.append((False, MARGIN + i * CELL, MARGIN + j * CELL, "front" if front else kind))

wall_pieces = []
for horizontal, fixed, start, kind in boundaries:
    mid = start + CELL / 2
    if kind == "window":
        gaps = [(mid - WINDOW_OFFSET - WINDOW / 2, mid - WINDOW_OFFSET + WINDOW / 2),
                (mid + WINDOW_OFFSET - WINDOW / 2, mid + WINDOW_OFFSET + WINDOW / 2)]
    else:
        gaps = [(mid - DOOR_LEAF, mid + DOOR_LEAF)]
    edges = [start - WALL / 2] + [edge for gap in gaps for edge in gap] + [start + CELL + WALL / 2]
    for a, b in zip(edges[::2], edges[1::2]):
        p0 = to_screen(horizontal, fixed, a, -WALL / 2)
        p1 = to_screen(horizontal, fixed, b, WALL / 2)
        wall_pieces.append((p0[0], p0[1], p1[0], p1[1]))

rect(0, 0, SIZE, SIZE, PAPER)
for i in range(0, SIZE + 1, 64):
    major = i % 256 == 0
    line(i, 0, i, SIZE, GRID_MAJOR if major else GRID_MINOR, 3 if major else 2)
    line(0, i, SIZE, i, GRID_MAJOR if major else GRID_MINOR, 3 if major else 2)

# The empty middle carries the same crossing tracks as the real gap.
rail = 1.65 / 6.25 * CELL
low, high = MARGIN + CELL + WALL / 2, MARGIN + 2 * CELL - WALL / 2
for offset in (-rail, rail):
    for width in (-9, 9):
        line(low, CENTER + offset + width, high, CENTER + offset + width, TRACK, 5)
        line(CENTER + offset + width, low, CENTER + offset + width, high, TRACK, 5)

# Wordless dimension lines give the sheet its drafting character.
reach = MARGIN - 100
for i in range(4):
    at = MARGIN + i * CELL
    for near, far in ((MARGIN - 44, reach - 22), (SIZE - MARGIN + 44, SIZE - reach + 22)):
        line(at, near, at, far, DIMENSION, 4)
        line(near, at, far, at, DIMENSION, 4)
        for x, y in ((at, far + (22 if far < CENTER else -22)), (far + (22 if far < CENTER else -22), at)):
            line(x - 13, y + 13, x + 13, y - 13, INK, 6)
for fixed in (reach, SIZE - reach):
    line(MARGIN, fixed, SIZE - MARGIN, fixed, DIMENSION, 4)
    line(fixed, MARGIN, fixed, SIZE - MARGIN, DIMENSION, 4)

# Stroking every piece before any fill leaves an outline only around the joined wall shape.
for x0, y0, x1, y1 in wall_pieces:
    out.append(f'<rect x="{x0:.1f}" y="{y0:.1f}" width="{x1 - x0:.1f}" height="{y1 - y0:.1f}" fill="none" stroke="{INK}" stroke-width="14"/>')
for x0, y0, x1, y1 in wall_pieces:
    rect(x0, y0, x1, y1, WALL_FILL)
out.append(f'<path d="{"".join(hatch(*piece) for piece in wall_pieces)}" stroke="{INK}" stroke-width="5" fill="none"/>')

for horizontal, fixed, start, kind in boundaries:
    mid = start + CELL / 2
    if kind == "window":
        for center in (mid - WINDOW_OFFSET, mid + WINDOW_OFFSET):
            a, b = center - WINDOW / 2, center + WINDOW / 2
            p0, p1 = to_screen(horizontal, fixed, a, -WALL / 2), to_screen(horizontal, fixed, b, WALL / 2)
            rect(p0[0], p0[1], p1[0], p1[1], GLASS)
            for across, width in ((-WALL / 2, 14), (0, 5), (WALL / 2, 14)):
                line(*to_screen(horizontal, fixed, a, across), *to_screen(horizontal, fixed, b, across), INK, width)
    elif kind == "door":
        # Leaves swing away from the plan's centre, which keeps the empty middle clean.
        swing = 1 if fixed > CENTER else -1
        for hinge_along in (mid - DOOR_LEAF, mid + DOOR_LEAF):
            hinge = to_screen(horizontal, fixed, hinge_along)
            tip = to_screen(horizontal, fixed, hinge_along, swing * DOOR_LEAF)
            meet = to_screen(horizontal, fixed, mid)
            line(*hinge, *tip, INK, 12)
            cross = (tip[0] - hinge[0]) * (meet[1] - hinge[1]) - (tip[1] - hinge[1]) * (meet[0] - hinge[0])
            out.append(f'<path d="M{tip[0]:.1f} {tip[1]:.1f}A{DOOR_LEAF} {DOOR_LEAF} 0 0 {1 if cross > 0 else 0} {meet[0]:.1f} {meet[1]:.1f}" fill="none" stroke="{INK}" stroke-width="7"/>')
    else:
        # The closed, solid front door and its outside step are the plan's only asymmetry.
        rect(fixed + WALL / 2 + 7, mid - DOOR_LEAF - 34, fixed + WALL / 2 + 58, mid + DOOR_LEAF + 34, PAPER)
        out.append(f'<rect x="{fixed + WALL / 2 + 7:.1f}" y="{mid - DOOR_LEAF - 34:.1f}" width="51" height="{2 * DOOR_LEAF + 68}" fill="none" stroke="{INK}" stroke-width="10"/>')
        rect(fixed - WALL / 2, mid - DOOR_LEAF, fixed + WALL / 2, mid + DOOR_LEAF, FRONT_DOOR)
        line(fixed - WALL / 2, mid, fixed + WALL / 2, mid, PAPER, 8)

svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 {SIZE} {SIZE}">'
       + "".join(out) + "</svg>\n")
Path(__file__).resolve().parent.parent.joinpath("assets/house_plan.svg").write_text(svg)
