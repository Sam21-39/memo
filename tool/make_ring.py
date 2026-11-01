"""Builds the Memō ring: Android res/raw/memo_ring.wav, iOS memo_ring.caf.

Two soft bell notes, high then low, like the logo's dot settling on its
ring. Three rings with rests, ~7 s, well under iOS's 30 s cap. Sine
partials with exponential decay; no samples, no dependencies.

    python3 tool/make_ring.py && afconvert -f caff -d LEI16 \
        android/app/src/main/res/raw/memo_ring.wav ios/Runner/memo_ring.caf
"""
import math
import struct
import wave

RATE = 44100
OUT = "android/app/src/main/res/raw/memo_ring.wav"


def bell(freq, seconds, gain):
    # Fundamental plus two inharmonic partials gives a soft bell, not a beep.
    partials = [(1.0, 1.0), (2.76, 0.35), (5.4, 0.12)]
    n = int(RATE * seconds)
    out = []
    for i in range(n):
        t = i / RATE
        attack = min(1.0, t / 0.008)
        env = attack * math.exp(-t * 3.2)
        s = sum(a * math.sin(2 * math.pi * freq * m * t) for m, a in partials)
        out.append(gain * env * s / 1.47)
    return out


def ring():
    hi = bell(1046.5, 1.1, 0.55)  # C6
    lo = bell(784.0, 1.4, 0.5)    # G5
    gap = int(RATE * 0.18)
    buf = hi[:gap] + [a + b for a, b in zip(hi[gap:], lo)] + lo[len(hi) - gap:]
    return buf


def main():
    samples = []
    for _ in range(3):
        samples += ring() + [0.0] * int(RATE * 0.6)
    with wave.open(OUT, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(
            struct.pack("<h", int(max(-1, min(1, s)) * 32000)) for s in samples
        ))
    print(f"wrote {OUT}: {len(samples) / RATE:.1f}s")


if __name__ == "__main__":
    main()
