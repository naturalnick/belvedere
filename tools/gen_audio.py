#!/usr/bin/env python3
"""Shape CC0 recorded foley and synthesize the original sparse piano sketch.
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
    # A separate seed keeps these clips stable without changing the existing foley or music.
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


def piano_note(midi, velocity, duration=8.):
    n = int(duration*RATE);t=np.arange(n)/RATE;f=440*2**((midi-69)/12)
    note=np.zeros(n)
    # Felt piano: damped upper partials that die quickly, unison beating, and a padded attack.
    for partial in range(1, 12):
        frequency=f*partial*np.sqrt(1 + .00009*partial*partial)
        decay=(3.0 + (65-midi)*.03)/(partial**.95)
        amplitude=np.exp(-partial*.48)/partial**1.2
        for cents, gain in [(-.65,.23), (0,.54), (.85,.23)]:
            note += gain*amplitude*np.sin(2*np.pi*frequency*2**(cents/1200)*t)*np.exp(-t/decay)
    note *= (1-np.exp(-t/.022))*velocity
    # A low, soft felt thump in place of a bright hammer click.
    thump=filt(RNG.normal(size=n), [45, 380], 'bandpass')*np.exp(-t/.03)*.05*velocity
    return fade(note+thump, .006, .5)


def music():
    duration=96.; stereo=np.zeros((int(duration*RATE), 2))
    # Original, unhurried voicings with rests; no looping arpeggiator or retro waveform.
    # Each phrase is root, fifth, then the third above; leaving the phrase there gives more space.
    phrases=[(0,[48,55,64]), (12,[45,52,60]), (24,[41,48,57]), (36,[43,50,59]),
             (48,[48,55,64]), (60,[45,52,60]), (72,[41,48,57]), (84,[43,50,59])]

    def place(sound, when, pan):
        at=int(when*RATE);count=min(len(sound),len(stereo)-at)
        gains=np.array([np.sqrt((1-pan)/2), np.sqrt((1+pan)/2)])
        stereo[at:at+count] += sound[:count,None]*gains
        # Notes ringing past the end continue from the start, so the loop has no seam.
        stereo[:len(sound)-count] += sound[count:,None]*gains

    for start, notes in phrases:
        # A soft bass note an octave below grounds each phrase.
        place(piano_note(notes[0]-12, .30*RNG.uniform(.92,1.04), 11.), start+.66, -.1)
        for k, note in enumerate(notes):
            when=start+[.7, 2.15, 4.9][k]+RNG.uniform(-.10,.10)
            sound=piano_note(note, [.44,.36,.29][k]*RNG.uniform(.9,1.05))
            place(sound, when, np.clip((note-56)/38, -.45,.45))
    # Baked warm hall: ~4 s decay with darker tail; avoids a heavy live reverb on the music bus.
    ir_n=int(4.5*RATE); t=np.arange(ir_n)/RATE
    for channel in range(2):
        ir=filt(RNG.normal(size=ir_n), 1700)*np.exp(-t/0.62) + filt(RNG.normal(size=ir_n), 4000)*np.exp(-t/0.18)*.35
        ir[:int(.03*RATE)] = 0
        ir *= .22 / np.sqrt(np.sum(ir*ir))
        for time_value, level in [(.037,.08),(.061,.06),(.093,.04)]:
            ir[int((time_value+channel*.003)*RATE)] += level
        tail=signal.fftconvolve(stereo[:,channel], ir)
        # Fold the reverb tail into the start for an exact seamless loop boundary.
        stereo[:,channel] += tail[:len(stereo)]
        stereo[:len(tail)-len(stereo),channel] += tail[len(stereo):]
    write('manor_theme', filt(stereo, 5200), .34, 0, 0, ogg=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--conservatory-only', action='store_true', help='Regenerate only the creak-free slab and lift sounds')
    args = parser.parse_args()
    manifest=json.loads((SOURCE/'sources.json').read_text())
    for name, digest in manifest['sha256'].items():
        assert hashlib.sha256((SOURCE/name).read_bytes()).hexdigest() == digest, name
    OUT.mkdir(parents=True, exist_ok=True)
    if args.conservatory_only:
        conservatory_effects()
    else:
        for stale in list(OUT.glob('*.wav')) + list(OUT.glob('*.ogg')):
            stale.unlink()
        effects();birds();music();conservatory_effects()
    for orphan in OUT.glob('*.import'):
        if not orphan.with_suffix('').exists(): orphan.unlink()
    target=ROOT/'build/audio-metrics.json'
    metrics = json.loads(target.read_text()) if args.conservatory_only and target.exists() else {}
    metrics.update(REPORT)
    target.write_text(json.dumps(metrics,indent=2)+'\n')
    print(f'Prepared {len(REPORT)} assets; {sum(x["bytes"] for x in REPORT.values()) / 1e6:.2f} MB. Metrics: {target}')
