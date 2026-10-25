#!/usr/bin/env python3
"""Procedurally synthesizes every music loop and sound effect used by Squelch.

Usage:  python3 tools/make_audio.py
Needs numpy and ffmpeg (with libvorbis) on PATH. Writes into audio/music and audio/sfx.
Everything is deterministic (seeded), so re-running produces the same files.
"""
import os
import subprocess
import wave

import numpy as np

SR = 22050
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MUSIC_DIR = os.path.join(ROOT, "audio", "music")
SFX_DIR = os.path.join(ROOT, "audio", "sfx")


def hz(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)


# ---------------------------------------------------------------- oscillators
def phase(f, n):
    f = np.broadcast_to(np.asarray(f, dtype=np.float64), (n,))
    return np.cumsum(f) / SR


def wave_of(kind, f, n):
    ph = phase(f, n)
    fr = ph % 1.0
    if kind == "sine":
        return np.sin(2 * np.pi * ph)
    if kind == "square":
        return np.where(fr < 0.5, 1.0, -1.0) * 0.6
    if kind == "pulse":
        return np.where(fr < 0.25, 1.0, -1.0) * 0.55
    if kind == "saw":
        return (2 * fr - 1) * 0.7
    if kind == "tri":
        return 4 * np.abs(fr - 0.5) - 1
    if kind == "organ":
        return (np.sin(2 * np.pi * ph) + 0.5 * np.sin(4 * np.pi * ph) + 0.3 * np.sin(6 * np.pi * ph)
                + 0.15 * np.sin(8 * np.pi * ph)) * 0.5
    if kind == "brass":
        return lowpass(2 * fr - 1, 3) * 0.8
    if kind == "sax":
        return lowpass(np.where(fr < 0.35, 1.0, -1.0), 4) * 0.6 + np.sin(2 * np.pi * ph) * 0.3
    if kind == "accordion":
        ph2 = phase(np.asarray(f) * 1.006, n)
        return (np.where(fr < 0.3, 1.0, -1.0) + np.where((ph2 % 1) < 0.3, 1.0, -1.0)) * 0.3
    if kind == "vibes":
        t = np.arange(n) / SR
        return np.sin(2 * np.pi * ph) * (0.75 + 0.25 * np.sin(2 * np.pi * 5.5 * t)) + 0.2 * np.sin(8 * np.pi * ph)
    if kind == "flute":
        t = np.arange(n) / SR
        ph = phase(np.asarray(f) * (1 + 0.006 * np.sin(2 * np.pi * 5 * t)), n)
        return np.sin(2 * np.pi * ph) + 0.08 * np.random.default_rng(1).standard_normal(n)
    raise ValueError(kind)


def lowpass(x, k):
    if k <= 1:
        return x
    kern = np.ones(int(k)) / int(k)
    return np.convolve(x, kern, mode="same")


def env(n, a=0.01, d=0.1, s=0.7, r=0.08, hold=None):
    """ADSR envelope; `hold` is the gate length in samples (defaults to n - release)."""
    a_n = max(1, int(a * SR))
    d_n = max(1, int(d * SR))
    r_n = max(1, int(r * SR))
    if hold is None:
        hold = max(a_n + d_n, n - r_n)
    e = np.full(n, s, dtype=np.float64)
    e[:a_n] = np.linspace(0, 1, a_n)[: min(a_n, n)] if a_n <= n else np.linspace(0, 1, n)
    end_d = min(n, a_n + d_n)
    if end_d > a_n:
        e[a_n:end_d] = np.linspace(1, s, d_n)[: end_d - a_n]
    if hold < n:
        rl = n - hold
        e[hold:] = np.linspace(e[hold - 1] if hold > 0 else s, 0, rl)
    return e


# ---------------------------------------------------------------- instruments
INSTR = {
    # name: (wave, attack, decay, sustain, release, gain, lowpass)
    "lead_square": ("square", 0.005, 0.08, 0.6, 0.05, 0.35, 2),
    "lead_pulse": ("pulse", 0.005, 0.1, 0.5, 0.05, 0.35, 2),
    "sax": ("sax", 0.03, 0.1, 0.8, 0.08, 0.45, 1),
    "pluck": ("saw", 0.002, 0.25, 0.0, 0.05, 0.5, 5),
    "pizz": ("tri", 0.002, 0.18, 0.0, 0.04, 0.6, 1),
    "vibes": ("vibes", 0.004, 0.6, 0.25, 0.3, 0.35, 1),
    "organ": ("organ", 0.03, 0.05, 0.9, 0.12, 0.3, 1),
    "brass": ("brass", 0.04, 0.1, 0.8, 0.08, 0.45, 1),
    "accordion": ("accordion", 0.02, 0.05, 0.85, 0.06, 0.35, 2),
    "flute": ("flute", 0.05, 0.1, 0.8, 0.1, 0.35, 1),
    "strings": ("saw", 0.08, 0.1, 0.85, 0.15, 0.25, 6),
    "sitar": ("saw", 0.002, 0.5, 0.1, 0.2, 0.4, 3),
    "bass_tri": ("tri", 0.005, 0.1, 0.7, 0.04, 0.55, 1),
    "bass_saw": ("saw", 0.005, 0.1, 0.6, 0.04, 0.4, 6),
    "bass_pluck": ("tri", 0.002, 0.3, 0.1, 0.05, 0.65, 1),
    "pad": ("saw", 0.25, 0.3, 0.7, 0.3, 0.09, 10),
    "pad_organ": ("organ", 0.15, 0.1, 0.8, 0.2, 0.14, 1),
    "stab": ("pulse", 0.003, 0.08, 0.0, 0.03, 0.16, 3),
    "arp": ("square", 0.002, 0.07, 0.0, 0.02, 0.13, 2),
}


def render_note(instr, midi_note, dur_s, vel=1.0):
    w, a, d, s, r, g, lp = INSTR[instr]
    gate = int(dur_s * SR)
    n = gate + int(r * SR) + 1
    f = hz(midi_note)
    sig = wave_of(w, f, n)
    if lp > 1:
        sig = lowpass(sig, lp)
    return sig * env(n, a, d, s, r, hold=gate) * g * vel


# ---------------------------------------------------------------- drums
_rng = np.random.default_rng(7)


def kick(gain=0.9):
    n = int(0.3 * SR)
    t = np.arange(n) / SR
    f = 45 + 110 * np.exp(-t * 30)
    return np.sin(2 * np.pi * phase(f, n)) * np.exp(-t * 12) * gain


def snare(gain=0.5):
    n = int(0.22 * SR)
    t = np.arange(n) / SR
    nz = _rng.standard_normal(n)
    return (nz * 0.7 + np.sin(2 * np.pi * 185 * t) * 0.5) * np.exp(-t * 20) * gain


def hat(gain=0.18, length=0.05):
    n = int(length * SR)
    t = np.arange(n) / SR
    nz = _rng.standard_normal(n)
    nz = nz - lowpass(nz, 4)
    return nz * np.exp(-t * 60) * gain


def brush(gain=0.15):
    n = int(0.15 * SR)
    t = np.arange(n) / SR
    nz = lowpass(_rng.standard_normal(n), 2)
    return nz * np.exp(-t * 18) * gain


def tabla(pitch=1.0, gain=0.5):
    n = int(0.25 * SR)
    t = np.arange(n) / SR
    f = (180 + 140 * np.exp(-t * 25)) * pitch
    return np.sin(2 * np.pi * phase(f, n)) * np.exp(-t * 14) * gain


def timpani(gain=0.6):
    n = int(0.8 * SR)
    t = np.arange(n) / SR
    f = 70 + 20 * np.exp(-t * 6)
    return (np.sin(2 * np.pi * phase(f, n)) + 0.2 * lowpass(_rng.standard_normal(n), 8)) * np.exp(-t * 4) * gain


# ---------------------------------------------------------------- composition
CHORDS = {
    "M": [0, 4, 7], "m": [0, 3, 7], "7": [0, 4, 7, 10], "m7": [0, 3, 7, 10],
    "M7": [0, 4, 7, 11], "dim": [0, 3, 6], "sus": [0, 5, 7],
}
SCALES = {
    "major": [0, 2, 4, 5, 7, 9, 11], "minor": [0, 2, 3, 5, 7, 8, 10],
    "harm": [0, 2, 3, 5, 7, 8, 11], "phryg": [0, 1, 4, 5, 7, 8, 10],
    "dorian": [0, 2, 3, 5, 7, 9, 10], "blues": [0, 3, 5, 6, 7, 10],
}
RHYTHMS4 = [
    [1, 1, 1, 1], [0.5, 0.5, 1, 0.5, 0.5, 1], [1.5, 0.5, 1, 1], [2, 1, 1], [1, 0.5, 0.5, 2],
    [0.5, 0.5, 0.5, 0.5, 1, 1], [-1, 1, 1, 1], [1, 1, 2], [0.75, 0.25, 0.75, 0.25, 2],
    [-0.5, 0.5, 0.5, 0.5, -0.5, 0.5, 1], [3, 1], [0.5, 1, 0.5, 2],
]
RHYTHMS3 = [[1, 1, 1], [2, 1], [1, 0.5, 0.5, 1], [3], [0.5, 0.5, 1, 1], [-1, 1, 1]]


class Song:
    def __init__(self, bpm, beats, bars):
        self.bpm = bpm
        self.beats = beats
        self.bars = bars
        self.spb = 60.0 / bpm
        self.length = int(round(bars * beats * self.spb * SR))
        self.buf = np.zeros(self.length + SR * 3)

    def add(self, sig, beat, gain=1.0):
        i = int(round(beat * self.spb * SR))
        if i < 0:
            return
        j = min(len(self.buf), i + len(sig))
        self.buf[i:j] += sig[: j - i] * gain

    def note(self, instr, m, beat, dur_beats, vel=1.0):
        self.add(render_note(instr, m, dur_beats * self.spb * 0.95, vel), beat)

    def finish(self, loop=True, peak=0.85):
        out = self.buf[: self.length].copy()
        tail = self.buf[self.length:]
        if loop:
            k = min(len(tail), len(out))
            out[:k] += tail[:k]
        else:
            out = self.buf.copy()
            nz = np.nonzero(np.abs(out) > 1e-4)[0]
            out = out[: (nz[-1] + 1) if len(nz) else 1]
        m = np.max(np.abs(out)) or 1.0
        return out / m * peak


def make_song(spec, seed):
    rng = np.random.default_rng(seed)
    beats = spec.get("beats", 4)
    prog = spec["prog"]
    reps = spec.get("reps", 2)
    bars = len(prog) * reps
    song = Song(spec["bpm"], beats, bars)
    key = spec["key"]
    scale = SCALES[spec.get("scale", "major")]
    rhythms = RHYTHMS4 if beats == 4 else RHYTHMS3
    lead = spec.get("lead")
    swing = spec.get("swing", 0.0)

    def sw(b):
        # push off-beat eighths late for a swing feel
        frac = b % 1.0
        return b + (swing if abs(frac - 0.5) < 1e-6 else 0.0)

    scale_notes = sorted({key + 12 + o + 12 * k for k in range(-1, 3) for o in scale})
    lo, hi = key + 10, key + 26

    def nearest_idx(m):
        return int(np.argmin([abs(x - m) for x in scale_notes]))

    # build a melody for the length of one progression pass, made of phrase A and its variation
    phrase_len = max(1, len(prog) // 2)

    def gen_phrase(bar_offset):
        notes = []
        cur = key + 16
        for b in range(phrase_len):
            root, q = prog[(bar_offset + b) % len(prog)]
            tones = [key + root + c for c in CHORDS[q]]
            rh = rhythms[int(rng.integers(len(rhythms)))]
            beat = 0.0
            for d in rh:
                if d < 0:
                    beat += -d
                    continue
                if beat == 0 or rng.random() < 0.35:
                    cand = [t + 12 * k for t in tones for k in range(0, 3) if lo <= t + 12 * k <= hi]
                    cur = min(cand, key=lambda x: abs(x - cur) + rng.random() * 3)
                else:
                    i = nearest_idx(cur) + int(rng.choice([-2, -1, -1, 1, 1, 2]))
                    i = max(0, min(len(scale_notes) - 1, i))
                    cur = scale_notes[i]
                    if cur > hi:
                        cur -= 12
                    if cur < lo:
                        cur += 12
                notes.append((b * beats + beat, d, cur))
                beat += d
        return notes

    phrase_a = gen_phrase(0)
    phrase_b = gen_phrase(phrase_len)

    for rep in range(reps):
        base_bar = rep * len(prog)
        # melody (second pass of the A phrase gets a slightly different last bar)
        if lead:
            for i, ph in enumerate([phrase_a, phrase_b]):
                for (bt, d, m) in ph:
                    beat = (base_bar + i * phrase_len) * beats + bt
                    song.note(lead, m + spec.get("lead_oct", 0), sw(beat), d, 0.9)
        for bi, (root, q) in enumerate(prog):
            bar = base_bar + bi
            b0 = bar * beats
            tones = [key + root + c for c in CHORDS[q]]
            # ---- bass
            bass = spec.get("bass")
            bi_name = spec.get("bass_instr", "bass_tri")
            r = key + root - 12
            if bass == "root8":
                for k in range(beats * 2):
                    song.note(bi_name, r + (12 if k % 4 == 3 else 0), sw(b0 + k * 0.5), 0.45)
            elif bass == "walk":
                nxt = key + prog[(bi + 1) % len(prog)][0] - 12
                line = [r, r + CHORDS[q][1], r + 7, nxt + (1 if rng.random() < 0.5 else -1)]
                for k in range(beats):
                    song.note(bi_name, line[k % 4], b0 + k, 0.9)
            elif bass == "oompah":
                song.note(bi_name, r, b0, 0.9)
                for k in range(1, beats):
                    if beats == 3:
                        for t in tones:
                            song.note("stab", t, b0 + k, 0.5, 0.8)
                    else:
                        song.note(bi_name, r + (7 if k % 2 == 0 else 0), b0 + k, 0.9) if k == 2 else None
                        for t in tones:
                            song.note("stab", t, b0 + k, 0.4, 0.7)
            elif bass == "pulse":
                for k in range(beats):
                    song.note(bi_name, r, b0 + k, 0.8)
            elif bass == "drone":
                song.note(bi_name, key - 12, b0, beats)
                song.note(bi_name, key - 5, b0, beats, 0.5)
            elif bass == "bossa":
                for (o, dur, dn) in [(0, 1.5, 0), (1.5, 0.5, 7), (2, 1.5, 7), (3.5, 0.5, 0)]:
                    song.note(bi_name, r + dn, b0 + o, dur, 0.9)
            # ---- harmony
            harm = spec.get("harm")
            if harm == "pad":
                for t in tones:
                    song.note("pad", t, b0, beats)
            elif harm == "organ":
                for t in tones:
                    song.note("pad_organ", t, b0, beats)
            elif harm == "stab":
                for k in range(beats):
                    for t in tones:
                        song.note("stab", t, sw(b0 + k + 0.5), 0.3)
            elif harm == "arp":
                seq = tones + [tones[0] + 12]
                for k in range(beats * 4):
                    song.note("arp", seq[k % len(seq)] + 12, b0 + k * 0.25, 0.25)
            elif harm == "arp8":
                seq = tones + [tones[1] + 12]
                for k in range(beats * 2):
                    song.note("arp", seq[k % len(seq)], sw(b0 + k * 0.5), 0.5)
            elif harm == "strings":
                for t in tones:
                    song.note("strings", t, b0, beats)
            # ---- drums
            dr = spec.get("drums")
            if dr == "rock":
                for k in range(beats):
                    song.add(kick() if k % 2 == 0 else snare(), b0 + k)
                for k in range(beats * 2):
                    song.add(hat(), sw(b0 + k * 0.5))
            elif dr == "fast":
                for k in range(beats):
                    song.add(kick(), b0 + k)
                    if k % 2 == 1:
                        song.add(snare(0.55), b0 + k)
                for k in range(beats * 4):
                    song.add(hat(0.12), b0 + k * 0.25)
            elif dr == "swing":
                for k in range(beats):
                    song.add(hat(0.14, 0.12), b0 + k)
                    if k % 2 == 1:
                        song.add(brush(0.2), b0 + k)
                        song.add(hat(0.08, 0.06), b0 + k + 0.5 + swing)
                if bi % 2 == 0:
                    song.add(kick(0.5), b0)
            elif dr == "brush":
                for k in range(beats):
                    song.add(brush(0.12 if k % 2 == 0 else 0.2), b0 + k)
            elif dr == "bossa":
                for o in [0, 1.5, 2, 3.5]:
                    song.add(kick(0.55), b0 + o)
                for o in [0, 0.75, 1.5, 2.5, 3.0]:
                    song.add(hat(0.12, 0.03), b0 + o)
                for k in range(beats * 2):
                    song.add(hat(0.06), b0 + k * 0.5)
            elif dr == "waltz":
                song.add(kick(0.6), b0)
                song.add(hat(0.12), b0 + 1)
                song.add(hat(0.12), b0 + 2)
            elif dr == "march":
                song.add(kick(0.7), b0)
                song.add(kick(0.7), b0 + 2)
                for o in [1, 3, 3.5, 3.75]:
                    song.add(snare(0.35), b0 + o)
            elif dr == "tabla":
                for k in range(beats):
                    song.add(tabla(0.7, 0.6), b0 + k)
                    song.add(tabla(1.6, 0.25), b0 + k + 0.5)
            elif dr == "timpani":
                if bi % 2 == 0:
                    song.add(timpani(), b0)
            elif dr == "tick":
                for k in range(beats):
                    song.add(hat(0.1, 0.03), b0 + k)
    return song.finish()


MUSIC = {
    "title": dict(bpm=104, key=57, scale="minor", prog=[(0, "m"), (0, "m"), (5, "m"), (0, "m"), (8, "M"), (7, "7"), (0, "m"), (7, "7")],
                  lead="sax", bass="walk", harm="stab", drums="swing", swing=0.12),
    "intro": dict(bpm=76, key=48, scale="minor", prog=[(0, "m7"), (5, "m7"), (8, "M7"), (7, "7")],
                  lead="sax", bass="walk", harm="pad", drums="brush", reps=2),
    "board": dict(bpm=94, key=53, scale="major", prog=[(0, "M7"), (9, "m7"), (2, "m7"), (7, "7"), (4, "m7"), (9, "7"), (2, "m7"), (7, "7")],
                  lead="vibes", bass="bossa", harm="pad", drums="bossa"),
    "party": dict(bpm=138, key=60, scale="major", prog=[(0, "M"), (5, "M"), (7, "M"), (0, "M"), (9, "m"), (5, "M"), (7, "7"), (0, "M")],
                  lead="lead_square", bass="oompah", harm="arp8", drums="rock", lead_oct=0),
    "elevator": dict(bpm=100, key=51, scale="major", prog=[(0, "M7"), (5, "M7"), (2, "m7"), (7, "7")],
                     lead="vibes", bass="bossa", harm="pad", drums="bossa", reps=4),
    "library": dict(bpm=84, key=50, scale="minor", prog=[(0, "m"), (0, "m"), (3, "M"), (7, "7"), (8, "M"), (5, "m"), (7, "7"), (0, "m")],
                    lead="pizz", bass="walk", bass_instr="bass_pluck", harm=None, drums="tick"),
    "yoga": dict(bpm=90, key=52, scale="phryg", prog=[(0, "sus"), (1, "M"), (0, "sus"), (10, "m")],
                 lead="sitar", bass="drone", harm="pad", drums="tabla", reps=4),
    "restaurant": dict(bpm=168, beats=3, key=55, scale="major", prog=[(0, "M"), (0, "M"), (7, "7"), (7, "7"), (7, "7"), (7, "7"), (0, "M"), (0, "M"),
                                                                     (5, "M"), (5, "M"), (0, "M"), (9, "m"), (2, "7"), (7, "7"), (0, "M"), (0, "M")],
                       lead="accordion", bass="oompah", drums="waltz"),
    "wedding": dict(bpm=78, key=53, scale="major", prog=[(0, "M"), (5, "M"), (7, "M"), (0, "M"), (9, "m"), (2, "m"), (7, "7"), (0, "M")],
                    lead="organ", bass="pulse", bass_instr="bass_tri", harm="organ", drums="timpani"),
    "getaway": dict(bpm=168, key=52, scale="minor", prog=[(0, "m"), (0, "m"), (8, "M"), (10, "M"), (0, "m"), (0, "m"), (3, "M"), (2, "dim")],
                    lead="lead_pulse", bass="root8", bass_instr="bass_saw", harm="stab", drums="fast"),
    "orchestra": dict(bpm=120, beats=3, key=62, scale="major", prog=[(0, "M"), (7, "M"), (0, "M"), (7, "7"), (5, "M"), (0, "M"), (7, "7"), (0, "M")],
                      lead="strings", bass="oompah", bass_instr="bass_pluck", harm=None, drums=None),
    "royal": dict(bpm=112, key=58, scale="major", prog=[(0, "M"), (5, "M"), (0, "M"), (7, "M"), (0, "M"), (5, "M"), (7, "7"), (0, "M")],
                  lead="brass", bass="oompah", bass_instr="bass_tri", harm=None, drums="march"),
    "heist": dict(bpm=124, key=48, scale="harm", prog=[(0, "m"), (0, "m"), (8, "M"), (7, "7"), (0, "m"), (5, "m"), (8, "M"), (7, "7")],
                  lead="lead_square", lead_oct=-12, bass="root8", bass_instr="bass_saw", harm="arp", drums="rock"),
    "finale": dict(bpm=120, key=50, scale="harm", prog=[(0, "m"), (10, "M"), (8, "M"), (7, "7"), (0, "m"), (5, "m"), (7, "7"), (7, "7")],
                   lead="brass", bass="root8", bass_instr="bass_saw", harm="strings", drums="timpani"),
    "credits": dict(bpm=126, key=53, scale="major", prog=[(0, "M"), (9, "m"), (5, "M"), (7, "7"), (0, "M"), (4, "m"), (5, "M"), (7, "7")],
                    lead="flute", bass="bossa", harm="arp8", drums="rock", swing=0.08),
}


# ---------------------------------------------------------------- sound effects
def fart(dur=0.6, f0=80.0, f1=55.0, wet=0.3, wobble=12.0, seed=0, flutter=8.0):
    rng = np.random.default_rng(seed)
    n = int(dur * SR)
    t = np.arange(n) / SR
    jitter = lowpass(rng.standard_normal(n), 300) * wobble * 6
    f = np.geomspace(f0, f1, n) + jitter + np.sin(2 * np.pi * flutter * t) * f0 * 0.15
    f = np.clip(f, 20, 2000)
    ph = phase(f, n) % 1.0
    # flappy pulse train: a sharp attack per cycle that decays inside the cycle
    flap = np.exp(-ph * 5.0) * 2 - 0.6
    buzz = lowpass(flap, 3)
    noise = lowpass(rng.standard_normal(n), 3) * (0.4 + 0.6 * (ph < 0.3))
    sig = buzz * (1 - wet) + noise * wet
    amp = np.minimum(1, t / 0.02) * np.minimum(1, (dur - t) / 0.08)
    amp *= 0.75 + 0.25 * np.sin(2 * np.pi * (flutter * 0.5) * t + rng.random() * 6)
    return sig * amp


def tone(f, dur, kind="sine", a=0.005, r=0.1, gain=0.6):
    n = int(dur * SR)
    return wave_of(kind, f, n) * env(n, a, 0.05, 0.8, r) * gain


def sweep(f0, f1, dur, kind="sine", gain=0.5):
    n = int(dur * SR)
    f = np.geomspace(f0, f1, n)
    return wave_of(kind, f, n) * env(n, 0.005, 0.05, 0.8, dur * 0.3) * gain


def noise_burst(dur, lp=1, decay=8.0, gain=0.5, seed=3):
    rng = np.random.default_rng(seed)
    n = int(dur * SR)
    t = np.arange(n) / SR
    return lowpass(rng.standard_normal(n), lp) * np.exp(-t * decay) * gain


def seq(parts, gap=0.0):
    out = []
    for p in parts:
        out.append(p)
        if gap:
            out.append(np.zeros(int(gap * SR)))
    return np.concatenate(out)


def mix(*sigs):
    n = max(len(s) for s in sigs)
    out = np.zeros(n)
    for s in sigs:
        out[: len(s)] += s
    return out


def arpeggio(notes, step, instr="arp", hold=0.25):
    total = np.zeros(int((len(notes) * step + hold + 0.5) * SR))
    for i, m in enumerate(notes):
        sig = render_note(instr, m, hold)
        j = int(i * step * SR)
        total[j: j + len(sig)] += sig[: len(total) - j]
    return total


def crowd(dur, seed, cheer=True):
    rng = np.random.default_rng(seed)
    n = int(dur * SR)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for _ in range(14):
        f = rng.uniform(180, 420) if cheer else rng.uniform(90, 160)
        vib = np.sin(2 * np.pi * rng.uniform(4, 7) * t) * f * 0.04
        drift = (np.geomspace(1.0, rng.uniform(0.8, 1.25), n)) * f
        out += wave_of("saw", drift + vib, n) * rng.uniform(0.3, 1.0)
    out = lowpass(out, 6) + lowpass(rng.standard_normal(n), 4) * 2
    return out * env(n, 0.08, 0.1, 0.8, dur * 0.4)


def sad_trombone():
    parts = []
    for m, d in [(58, 0.35), (57, 0.35), (56, 0.35)]:
        parts.append(render_note("brass", m, d))
    n = int(1.1 * SR)
    t = np.arange(n) / SR
    f = hz(55) * (1 + 0.025 * np.sin(2 * np.pi * 6 * t))
    parts.append(wave_of("brass", f, n) * env(n, 0.02, 0.1, 0.8, 0.4) * 0.45)
    return seq(parts)


def babble(seed):
    rng = np.random.default_rng(seed)
    parts = []
    for _ in range(5):
        f = rng.uniform(170, 260)
        parts.append(sweep(f, f * rng.uniform(0.8, 1.3), rng.uniform(0.06, 0.11), "tri", 0.4))
        parts.append(np.zeros(int(0.03 * SR)))
    return seq(parts)


def make_sfx():
    s = {}
    s["fart1"] = fart(0.45, 95, 70, 0.25, seed=1)
    s["fart2"] = fart(0.8, 75, 50, 0.35, seed=2, flutter=6)
    s["fart3"] = fart(0.3, 130, 90, 0.2, seed=3, flutter=14)
    s["fart_wet"] = fart(0.7, 70, 45, 0.7, seed=4, flutter=5)
    s["fart_huge"] = mix(fart(1.8, 70, 38, 0.4, seed=5, flutter=4, wobble=20), fart(1.6, 52, 35, 0.5, seed=6) * 0.6)
    s["fart_squeak"] = fart(0.55, 260, 420, 0.1, seed=7, flutter=20, wobble=4)
    s["fart_tiny"] = fart(0.18, 180, 150, 0.15, seed=8)
    s["fart_note"] = fart(0.55, hz(48), hz(48), 0.12, seed=9, wobble=1.5, flutter=5)
    s["hiss"] = noise_burst(0.9, 2, 3.5, 0.35) * np.minimum(1, np.arange(int(0.9 * SR)) / (0.2 * SR))
    s["sniff"] = seq([noise_burst(0.12, 1, 14, 0.3, 4), np.zeros(int(0.05 * SR)), noise_burst(0.18, 1, 10, 0.35, 5)])
    s["ding"] = mix(tone(hz(84), 1.2, "sine", r=1.0, gain=0.5), tone(hz(96), 1.2, "sine", r=1.0, gain=0.2))
    s["click"] = tone(1200, 0.03, "square", r=0.02, gain=0.3)
    s["select"] = seq([tone(hz(76), 0.06, "square", gain=0.3), tone(hz(83), 0.09, "square", gain=0.3)])
    s["buzzer"] = tone(110, 0.45, "saw", r=0.05, gain=0.5)
    s["whoosh"] = noise_burst(0.5, 5, 5, 0.6) * np.sin(np.linspace(0, np.pi, int(0.5 * SR)))
    n = int(1.5 * SR)
    tt = np.arange(n) / SR
    s["siren"] = wave_of("square", 700 + 250 * np.sin(2 * np.pi * 1.6 * tt), n) * 0.25 * env(n, 0.05, 0.1, 0.9, 0.3)
    s["gong"] = mix(*[tone(f, 3.0, "sine", r=2.8, gain=g) for f, g in [(110, 0.5), (173, 0.3), (231, 0.25), (297, 0.18), (420, 0.1)]])
    s["boom"] = mix(kick(1.0), noise_burst(1.2, 6, 3.5, 0.9, 11))
    s["pop"] = sweep(400, 1200, 0.08, "sine", 0.5)
    s["honk"] = seq([tone(330, 0.18, "square", gain=0.35), np.zeros(int(0.05 * SR)), tone(330, 0.3, "square", gain=0.35)])
    s["crash"] = noise_burst(0.8, 1, 5, 0.7, 12)
    s["cheer"] = crowd(2.2, 13, True) * 0.5
    s["boo"] = crowd(1.8, 14, False) * 0.5
    s["gasp"] = sweep(500, 900, 0.25, "tri", 0.35)
    s["sparkle"] = arpeggio([84, 88, 91, 96, 100, 103], 0.06, "arp", 0.2)
    s["win"] = arpeggio([60, 64, 67, 72, 67, 72, 76, 79], 0.1, "lead_square", 0.18)
    s["egg"] = mix(arpeggio([79, 83, 86, 91, 95, 98, 103], 0.07, "vibes", 0.4), np.concatenate([np.zeros(int(0.55 * SR)), fart(0.4, 220, 330, 0.1, seed=15) * 0.7]))
    s["lose"] = sad_trombone()
    s["step"] = noise_burst(0.06, 2, 40, 0.2, 16)
    s["coin"] = seq([tone(hz(83), 0.07, "square", gain=0.3), tone(hz(88), 0.25, "square", r=0.2, gain=0.3)])
    s["chair"] = sweep(300, 180, 0.15, "saw", 0.3)
    s["splash"] = noise_burst(0.6, 3, 6, 0.5, 17)
    s["thud"] = kick(0.8)
    for i in range(3):
        s["babble%d" % (i + 1)] = babble(20 + i)
    for i, m in enumerate([60, 62, 64, 65, 67]):
        s["tuba%d" % i] = fart(0.5, hz(m - 24), hz(m - 24), 0.12, seed=30 + i, wobble=1, flutter=5)
    return s


# ---------------------------------------------------------------- writers
def write_wav(path, x):
    x = np.clip(x, -1, 1)
    pcm = (x * 32000).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def main():
    os.makedirs(MUSIC_DIR, exist_ok=True)
    os.makedirs(SFX_DIR, exist_ok=True)
    for i, (name, spec) in enumerate(MUSIC.items()):
        data = make_song(spec, seed=100 + i)
        tmp = os.path.join(MUSIC_DIR, name + ".tmp.wav")
        write_wav(tmp, data)
        out = os.path.join(MUSIC_DIR, name + ".ogg")
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", "3", out], check=True)
        os.remove(tmp)
        print("music", name, "%.1fs" % (len(data) / SR))
    for name, data in make_sfx().items():
        m = np.max(np.abs(data)) or 1
        write_wav(os.path.join(SFX_DIR, name + ".wav"), data / m * 0.9)
    print("sfx done")


if __name__ == "__main__":
    main()
