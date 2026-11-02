#!/usr/bin/env python3
"""Write the reproducible proxy report; censored runs never enter solve medians."""
from pathlib import Path
import json
import statistics

ROOT = Path(__file__).resolve().parents[2]
raw = json.loads((ROOT / 'build/fun/benchmark.json').read_text())
probes = json.loads((ROOT / 'build/fun/probes.json').read_text())
results = raw['results']
BOTS = ('random', 'greedy', 'planner', 'optimal')
NAMES = {'random': 'Random legal', 'greedy': 'Local greedy', 'planner': 'Informed planner', 'optimal': 'Optimal solver'}
assert len(results) == 203 * len(BOTS)
assert all({'solved', 'slides', 'walks', 'motion_seconds', 'human_seconds'} <= r.keys() for r in results)
assert len({r['seed'] for r in results if r['seed'] not in ('A', 'B', 'C')}) == 200
assert all(r['slides'] + r['walks'] == raw['cap'] for r in results if not r['solved'])
assert all(r['search_depth'] <= 5 and r['search_nodes'] <= 1200 for r in results if r['bot'] == 'planner')
assert not probes['failures'], f"Geometry probes failed: {len(probes['failures'])}"


def median(rows, key, scale=1):
    values = [r[key] / scale for r in rows if r['solved']]
    return statistics.median(values) if values else None


def fmt(value):
    return '—' if value is None else f'{value:,.1f}'


def table(rows):
    lines = ['| Bot | Solved | Slides, median | Walks, median | Motion, min | With think time, min |',
             '|---|---:|---:|---:|---:|---:|']
    for bot in BOTS:
        group = [r for r in rows if r['bot'] == bot]
        count = sum(r['solved'] for r in group)
        lines.append(f"| {NAMES[bot]} | {count}/{len(group)} ({count/len(group):.1%}) | {fmt(median(group, 'slides'))} | {fmt(median(group, 'walks'))} | {fmt(median(group, 'motion_seconds', 60))} | {fmt(median(group, 'human_seconds', 60))} |")
    return '\n'.join(lines)


all_planner = [r for r in results if r['bot'] == 'planner']
human_median = median(all_planner, 'human_seconds', 60)
assert human_median is not None and 8 <= human_median <= 20, 'Planner moved outside retained band: re-evaluate difficulty decision before reporting'
planner_minutes = sorted(r['human_seconds'] / 60 for r in all_planner if r['solved'])
randoms = [r for r in results if r['seed'] not in ('A', 'B', 'C')]
lines = [
    '# Fun-test proxy — Stage 2', '',
    '**A real five-person human playtest is still owed to Nick.** Pass bar: at least 4/5 solve in 5–20 minutes and make their first slide within 90 seconds. Bot results cannot establish this.', '',
    'Run `tools/fun_test.sh` from any working directory. It runs entirely headlessly and regenerates this report. Raw per-run results and probe failures are local files in `build/fun/` (git-ignored).', '',
    '## Method', '',
    f"- Cohort: A, B, C plus 200 distinct accepted-state indices sampled without replacement from {raw['table_size']:,} entries. Sampling RNG seed: `{raw['sample_seed']}`; per-run RNG seed: sampling seed + cohort position × 31. All bots receive the same starts.",
    f"- Cap: {raw['cap']:,} legal actions (walks + slides) for every bot. Capped runs are failures and are **excluded from every median**. Rates always retain the full denominator. Successful-run medians can be strongly biased when most runs fail.",
    '- Motion estimate = `1.4 × slides + 3 × walks` seconds. Think-inclusive estimate = `6.4 × slides + 3 × walks` seconds (5 seconds thinking per slide). Medians are calculated per run, not by adding separate move-count medians.',
    '- Random: uniformly chooses among currently legal walk/slide actions.',
    '- Greedy: receives only the current room id and the four adjacent observations (room id, gap or outside). Starts with an empty relative map; infers north/west bounds from outside edges. Explores remembered reachable frontiers, then selects a single slide by Manhattan distance plus misplaced-room count. Local heuristic learning and revisit penalties resist loops. It never receives the true board, absolute player slot, accepted-state index, solver table or optimal path.',
    '- Informed planner: the same observations and memory as greedy. Until all nine cells are observed and the map is anchored, it uses the same exploration. Then it searches at most five future slides (1,200-node safety limit) on its **believed** board, using the same heuristic and a revisit penalty. It executes only the first slide and replans. Walking routes use remembered doors. No true-board or optimal-solver lookup is available to it.',
    '- Optimal: the existing reverse 0–1 BFS policy minimizes slides, with walks costing zero. It does not minimize elapsed time or walks among equally slide-optimal routes; this is an ideal-information reference, not a guaranteed time lower bound.',
    '- Identity, compass orientation, remembering an observation perfectly, and knowing each room’s home are granted to the informed bots. Recognizing furniture/accents and discovering the puzzle’s rules are not modeled. The proxy can overestimate or underestimate actual human performance.', '',
    '## All 203 starts', '', table(results), '',
    '## The 200 random accepted starts', '', table(randoms), '',
    '## Curated starts', '',
    '| Seed | Bot | Result | Slides | Walks | Motion, min | With think time, min |',
    '|---|---|---|---:|---:|---:|---:|',
]
for name in ('A', 'B', 'C'):
    for r in [r for r in results if r['seed'] == name]:
        lines.append(f"| {name} | {NAMES[r['bot']]} | {'Solved' if r['solved'] else 'CAPPED — failure'} | {r['slides']:,} | {r['walks']:,} | {r['motion_seconds']/60:.1f} | {r['human_seconds']/60:.1f} |")
lines += ['', 'Capped rows above show time **spent before the cap**, not a time-to-solve estimate.', '',
          '## Human estimate and difficulty decision', '',
          f"The informed planner’s solved-run median is **{fmt(human_median)} minutes**; it solves **{sum(r['solved'] for r in all_planner)}/203** starts. The optimal and greedy solved-run medians are reference bounds: **{fmt(median([r for r in results if r['bot'] == 'optimal'], 'human_seconds', 60))}–{fmt(median([r for r in results if r['bot'] == 'greedy'], 'human_seconds', 60))} minutes**. These are algorithmic comparisons, not a human confidence interval.", '',
          f"Planner solved-run spread: 10th–90th percentile **{planner_minutes[int((len(planner_minutes)-1)*0.1)]:.1f}–{planner_minutes[int((len(planner_minutes)-1)*0.9)]:.1f} min**; minimum **{min(planner_minutes):.1f}**, maximum **{max(planner_minutes):.1f} min**. A passing median does not mean every start meets the target.", '',
          'Retain **14–20 optimal slides** and the existing accepted table: the planner median is inside the requested 8–20 minute range. **Seed A remains the jam seed.** No data regeneration or curated-seed substitution is warranted. The weak greedy result is not used to re-band.', '',
          '## Spawn and sight checks', '',
          '| Check | Pass | Evidence |', '|---|---:|---|',
          f"| Gap visible through open spawn doorway | {probes['spawn_pass']:,}/{probes['accepted']:,} | Live spawn pose; camera frustum plus unobstructed optical ray to gap slab; max horizontal turn {probes['spawn_turn_max']:.1f}° |",
          f"| First lever reachable within 3 s walking | {probes['lever_pass']:,}/{probes['accepted']:,} | Gameplay interaction ray hits the current room’s lever from spawn; max required walk {probes['lever_walk_max']:.1f} s (looking down still required) |",
          f"| Side-view classification | {probes['view_pass']:,}/{probes['view_total']:,} | All four sides at every accepted spawn, plus all rooms for every 50th accepted state |", '',
          '| Side / expected view | Probes |', '|---|---:|']
for key, count in sorted(probes['view_counts'].items()):
    lines.append(f'| {key} | {count:,} |')
lines += ['',
          'Optical rays use temporary, test-only trimesh colliders derived from the live opaque render meshes. Transparent glass and invisible movement boundaries are omitted. The first hit is classified by its room, gap slab or exterior ownership. Window/door pane scans originate at eye height 1.65 m from reachable positions inside the room. These checks validate geometry and distinguish edge/neighbour/empty; they do **not** validate human colour recognition, lighting, or whether the unseen neighbour’s identity is visually unambiguous through an opaque wall.', '',
          'No direct Stage 1 gameplay-rule changes are made by this report. The only shared scene seam extracts the existing spawn placement into a callable function so probes exercise the live spawn code.']
text = '\n'.join(lines) + '\n'
(ROOT / 'docs/FUNTEST.md').write_text(text)
print(table(results))
print(f'Planner human estimate: {fmt(human_median)} minutes; geometry failures: {len(probes["failures"])}')
