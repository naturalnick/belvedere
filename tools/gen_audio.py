#!/usr/bin/env python3
"""Shape CC0 recorded foley and prepare the main theme for the game.
Sources and hashes live beside the recordings in audio_sources/sources.json.
"""
from pathlib import Path
import hashlib
import json
import argparse
import subprocess
import wave
import numpy as np
from scipy import signal

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / 'tools/audio_sources'
OUT = ROOT / 'assets/audio'
RATE = 44100
RNG = np.random.default_rng(73104)
REPORT = {}


def read(path, channels=1, rate=RATE):
    raw = subprocess.check_output(['ffmpeg', '-v', 'error', '-i', str(path), '-f', 'f32le', '-ac', str(channels), '-ar', str(rate), '-'])
    x = np.frombuffer(raw, dtype='<f4').astype(np.float64)
    return x if channels == 1 else x.reshape(-1, channels)


def filt(x, cutoff, kind='lowpass', order=2, rate=RATE):
    return signal.sosfilt(signal.butter(order, cutoff, kind, fs=rate, output='sos'), x, axis=0)


def fade(x, attack=.004, release=.04):
    x = x.copy()
    a, b = min(len(x), int(attack * RATE)), min(len(x), int(release * RATE))
    if a: x[:a] *= np.linspace(0, 1, a).reshape((-1,) + (1,) * (x.ndim - 1)) ** 2
    if b: x[-b:] *= np.linspace(1, 0, b).reshape((-1,) + (1,) * (x.ndim - 1)) ** 2
    return x


def norm(x, peak=1.):
    return x * peak / max(np.max(np.abs(x)), 1e-8)


def trim(x, threshold=.003):
    # Remove recording lead-in, retaining the heel/handle attack and a short natural tail.
    active = np.flatnonzero(np.abs(x) > max(np.max(np.abs(x)) * threshold, 1e-6))
    if not len(active): return x
    return x[max(0, active[0] - 100):min(len(x), active[-1] + int(.05 * RATE))]


def source(folder, name, speed=1., cutoff=6500):
    x = trim(read(SOURCE / folder / (name + '.ogg')))
    if speed != 1:
        x = signal.resample_poly(x, 1000, round(speed * 1000))
    return norm(filt(filt(x, 45, 'highpass'), cutoff))


def mix(length, layers):
    result = np.zeros(int(length * RATE))
    for start, x, gain in layers:
        offset = int(start * RATE)
        count = min(len(x), len(result) - offset)
        if count > 0: result[offset:offset + count] += x[:count] * gain
    return result


def write(name, x, peak, attack=.004, release=.04, ogg=False, rate=RATE):
    if rate == RATE:
        x = fade(filt(x, 25, 'highpass'), attack, release)
    x = norm(x, peak)
    path = OUT / (name + '.wav')
    with wave.open(str(path), 'wb') as f:
        f.setnchannels(1 if x.ndim == 1 else x.shape[1]);f.setsampwidth(2);f.setframerate(rate)
        f.writeframes(np.round(np.clip(x, -1, 1) * 32767).astype('<i2').tobytes())
    if ogg:
        target = path.with_suffix('.ogg')
        # Homebrew ffmpeg lacks libvorbis; oggenc is the reference encoder.
        subprocess.run(['oggenc', '--quiet', '--serial', '1', '-q', '5', '-o', str(target), str(path)], check=True)
        path.unlink();path = target
    REPORT[name] = {'seconds': round(len(x)/rate, 3), 'peak_dbfs': round(20*np.log10(np.max(abs(x))), 2), 'rms_dbfs': round(20*np.log10(np.sqrt(np.mean(x*x))), 2), 'bytes': path.stat().st_size}


def effects():
    # Three step sounds only: soft wood, normal shoe-on-tile, and grass.
    for surface in ['wood', 'grass']:
        for i in range(5):
            x = source('impact', f'footstep_{surface}_{i:03}', cutoff=4300 if surface == 'wood' else 3800)
            # Grass is brighter than the low wood thump, so it sits well below it at equal peak.
            write(f'step_{surface}_{i}', x, .12 if surface == 'grass' else .32, release=.035)
    # Hard floors use the RPG pack's heel-and-toe shoe steps. Kenney's concrete takes all ring
    # at ~258 Hz and read as tapping; 05/06 are similarly tonal and 07/08 carry a bright tick.
    for i, number in enumerate([0, 1, 2, 3, 4, 9]):
        write(f'step_tile_{i}', source('rpg', f'footstep{number:02}', cutoff=3500), .17, release=.035)
    for i in range(3):
        metal = source('rpg', 'metalClick', .94 + i*.025, 4200)
        wood = source('impact', 'impactWood_light_000', .94 + i*.03, 2200)
        write(f'lever_grab_{i}', mix(.22, [(0, metal, .7), (.012, wood, .2)]), .25, release=.05)
        write(f'lever_blocked_{i}', mix(.30, [(0, wood, .7), (.04, metal, .3)]), .34)
        # Locked door: a muted handle catch, then the leaves pushing once against the bolt.
        # Repeated light knocks read as someone knocking, so there is a single heavy contact.
        handle = source('rpg', 'metalLatch', .88 + i*.03, 3000)
        bolt = source('rpg', 'doorClose_4', [1., .94, 1.05][i], 2200)
        write(f'door_rattle_{i}', mix(.62, [(0, handle, .28), (.035, bolt, 1.)]), .34, release=.12)
    for i in range(2):
        # Natural speed: squeezing the recordings into the 0.45 s swing raised them over an octave.
        hinge = source('rpg', f'doorOpen_{i+1}', cutoff=3800)[:int(.95 * RATE)]
        close = source('rpg', f'doorClose_{i+1}', cutoff=3000)
        write(f'door_open_{i}', hinge, .26, release=.18)
        write(f'door_close_{i}', close, .30, release=.07)
    coin_effects()
    menu_effects()
    write('wake', source('rpg', 'cloth2', .9, 4200), .20, .025, .12)
    for variant in range(3):
        length = 2.05
        n = int(length * RATE);t = np.arange(n) / RATE
        # A low, irregular rolling texture under real creaking wood, without a motor tone.
        rolling = rolling_texture(n, RNG)
        u = np.clip((t-.09) / 1.43, 0, 1)
        velocity = np.ones(n)
        velocity[u < .224] = .5 - .5*np.cos(np.pi*u[u < .224]/.224)
        velocity[u > .64] = .5 - .5*np.cos(np.pi*(1-u[u > .64])/.36)
        rolling *= velocity ** .8
        # Two sparse natural-speed timber creaks; stretching one across the slide sounded synthetic.
        creak = fade(source('rpg', f'creak{variant+1}', .86, 2600), .02, .08)
        settle = fade(source('rpg', f'creak{(variant+1)%3+1}', .92, 2600), .02, .08)
        landing = source('impact', 'impactWood_heavy_002', .67 + variant*.015, 1000)
        latch = source('rpg', 'metalLatch', .85, 3400)
        takeup = source('impact', 'impactPlank_medium_000', .8, 1500)
        x = mix(length, [(0, rolling, .55 / 4), (.20, creak, .17 / 12), (.95, settle, .11 / 12), (.015, takeup, .13), (1.52, landing, .44), (1.54, latch, .07)])
        write(f'slide_{variant}', x, .63, .008, .18)


def rolling_texture(n, rng):
    noise = filt(rng.normal(size=n), 320)
    texture = filt(rng.normal(size=n), [180, 1300], 'bandpass')
    modulation = .7 + .3 * norm(filt(rng.normal(size=n), 17))
    return norm(noise) * .65 + norm(texture) * modulation * .18


def conservatory_effects():
    # Reuse the room shift's rolling layer, without either timber-creak recording.
    # A separate seed keeps these clips stable without changing the existing foley.
    rng = np.random.default_rng(73105)
    for name, seconds, peak, cutoff in [('gap_retract', 2.2, .18, 500), ('conservatory_rise', 5.5, .42, 1300)]:
        n = int(seconds * RATE)
        t = np.arange(n) / RATE
        velocity = np.sin(np.pi * t / seconds) ** .8
        rolling = filt(rolling_texture(n, rng), cutoff, order=4) * velocity
        layers = [(0, rolling, .55)]
        if name == 'conservatory_rise':
            takeup = source('impact', 'impactPlank_medium_000', cutoff=500)
            landing = source('impact', 'impactWood_heavy_002', cutoff=650)
            layers += [(0, takeup, .035), (seconds - .12, landing, .10)]
        write(name + '_0', mix(seconds + .2, layers), peak, .12, .2)


def menu_effects():
    # Menu presses: a small brass latch click, shorter and well below the lever grab.
    # ui_tap (a muted wooden tap) is the alternative; ManorAudio.MENU_CLICK selects one.
    for i in range(3):
        click = source('rpg', 'metalClick', 1.0 + i*.035, 5000)[:int(.16 * RATE)]
        write(f'ui_click_{i}', click, .16, .002, .06)
        tap = source('impact', 'impactWood_light_000', 1.02 + i*.035, 3200)[:int(.16 * RATE)]
        # The tap carries more body than the click; this peak matches their loudness.
        write(f'ui_tap_{i}', tap, .085, .002, .06)


def coin_effects():
    # A single soft coin contact marks arrival in the wallet, distinct from the cabinet latch.
    contact = source('rpg', 'handleCoins2', 1.08, 5800)
    write('coin_acquired_0', contact[:int(.48 * RATE)], .24, .003, .10)
    # Recorded coin contacts keep the bright attack and natural metallic decay.
    for i, name in enumerate(('handleCoins', 'handleCoins2')):
        coins = source('rpg', name, cutoff=8500)
        latch = source('rpg', 'metalClick', cutoff=3800)
        write(f'coin_insert_{i}', mix(max(.65, len(coins) / RATE + .12),
              [(0, latch, .14), (.10, coins, 1.)]), .34, .002, .06)
    # A drawer's lock releasing as its room comes home: the real latch, with a light knock of the drawer front.
    latch = source('rpg', 'metalLatch', cutoff=5000)
    knock = source('impact', 'impactWood_light_000', 1.1, 2400)
    write('drawer_unlock_0', mix(max(.4, len(latch) / RATE + .05), [(0, latch, 1.), (.03, knock, .25)]), .36, .002, .08)


def bell_effects():
    # RP1312's single small-bell strike, at its natural length.
    ring = trim(filt(read(SOURCE / 'small-bell-350616.mp3'), 45, 'highpass'), .002)
    write('bell_clear', ring, .60, .001, .25, ogg=True)
    # A wrong ring is the same recording a semitone flat and slightly darker, not a separate failure sound.
    write('bell_off', filt(signal.resample_poly(ring, 100, 94), 3200), .60, .001, .25, ogg=True)


PIANO_SONGS = ('piano-placeholder-sugerencia.ogg', 'piano-drifting-piano.mp3', 'piano-game-travel-1-piano.mp3',
               'piano-ondrosik-pilgrimage.mp3', 'piano-ondrosik-sunday-evening.mp3', 'piano-ondrosik-whispered.mp3',
               'piano-ondrosik-fairitale-2.mp3')


def piano_sources_present():
    return all((SOURCE / name).exists() for name in PIANO_SONGS)


def piano_songs():
    # The stand-in recordings stay out of git (sources.json has their links and hashes); without
    # them the committed piano_song files are kept as they are.
    if not piano_sources_present():
        print('Piano sources missing; keeping the existing piano_song files.')
        return
    # One song per token, in this order; the game plays whichever piano_song_N exist.
    for i, name in enumerate(PIANO_SONGS):
        # Mono: the piano is a single point in the room, and it halves the download and web memory.
        x = read(SOURCE / name)
        active = np.flatnonzero(np.abs(x) > .003)
        x = x[active[0]:]
        if len(x) > 60 * RATE:
            # Each token buys under a minute, so longer pieces end at their quietest half-second between 45 and 57 s.
            window = int(.5 * RATE)
            energy = [np.mean(x[t:t + window] ** 2) for t in range(45 * RATE, 57 * RATE, window // 2)]
            x = fade(x[:45 * RATE + int(np.argmin(energy)) * (window // 2) + window], 0, 3.)
        # Matched loudness so no token sounds louder than the last, without letting a peak clip.
        x = x * min(10 ** (-24.5 / 20) / np.sqrt(np.mean(x * x)), .9 / np.max(np.abs(x)))
        write(f'piano_song_{i}', x, np.max(np.abs(x)), 0, .05, ogg=True)


def birds():
    # Magnesus's seamless forest loop, kept at its native 48 kHz so resampling cannot mark the seam.
    rate = 48000
    x = read(SOURCE / 'forest-birds-723913.ogg', 2, rate)
    # Remove the steady sub-300 Hz rumble (no wind outside) and soften the top slightly for distance.
    # Filtering a wrapped copy carries the filter state across the loop point, keeping it seamless.
    warm = rate
    wrapped = np.concatenate([x[-warm:], x])
    wrapped = filt(filt(wrapped, 380, 'highpass', 4, rate), 9000, 'lowpass', 2, rate)
    write('birds_loop', wrapped[warm:], .25, ogg=True, rate=rate)


def lufs(x, rate):
    # ffmpeg's EBU R128 meter, so the target matches what was measured on the previous theme.
    raw = np.ascontiguousarray(x, dtype='<f4').tobytes()
    out = subprocess.run(['ffmpeg', '-hide_banner', '-nostats', '-f', 'f32le', '-ar', str(rate), '-ac', str(x.shape[1]), '-i', '-',
                          '-af', 'ebur128', '-f', 'null', '-'], input=raw, capture_output=True, check=True).stderr.decode()
    return float(out[out.rindex('I:'):].split()[1])


def main_theme():
    # Kept at its native 48 kHz and in stereo, as mixed. The game plays it once, then rests in silence.
    rate = 48000
    x = read(SOURCE / 'main-theme.mp3', 2, rate)
    # The piece swells in and decays on its own; only the silent end is cut, with a short fade.
    active = np.flatnonzero(np.abs(x).max(axis=1) > 10 ** (-80 / 20))
    x = x[:active[-1] + 1]
    release = int(.25 * rate)
    x[-release:] *= np.linspace(1, 0, release)[:, None] ** 2
    # The previous felt-piano loop sat at -21 LUFS against the foley; match it so the mix holds.
    x = x * 10 ** ((-21 - lufs(x, rate)) / 20)
    write('main_theme', x, np.max(np.abs(x)), ogg=True, rate=rate)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--conservatory-only', action='store_true', help='Regenerate only the creak-free slab and lift sounds')
    parser.add_argument('--bells-only', action='store_true', help='Regenerate only the bells and the player-piano songs')
    parser.add_argument('--theme-only', action='store_true', help='Regenerate only the main theme')
    args = parser.parse_args()
    manifest=json.loads((SOURCE/'sources.json').read_text())
    for name, digest in manifest['sha256'].items():
        if name in PIANO_SONGS and not (SOURCE/name).exists(): continue
        assert hashlib.sha256((SOURCE/name).read_bytes()).hexdigest() == digest, name
    OUT.mkdir(parents=True, exist_ok=True)
    if args.conservatory_only:
        conservatory_effects()
    elif args.bells_only:
        bell_effects();piano_songs()
    elif args.theme_only:
        main_theme()
    else:
        for stale in list(OUT.glob('*.wav')) + list(OUT.glob('*.ogg')):
            if not (stale.name.startswith('piano_song_') and not piano_sources_present()): stale.unlink()
        effects();birds();main_theme();conservatory_effects();bell_effects();piano_songs()
    for orphan in OUT.glob('*.import'):
        if not orphan.with_suffix('').exists(): orphan.unlink()
    target=ROOT/'build/audio-metrics.json'
    metrics = json.loads(target.read_text()) if (args.conservatory_only or args.bells_only or args.theme_only) and target.exists() else {}
    metrics.update(REPORT)
    target.write_text(json.dumps(metrics,indent=2)+'\n')
    print(f'Prepared {len(REPORT)} assets; {sum(x["bytes"] for x in REPORT.values()) / 1e6:.2f} MB. Metrics: {target}')
