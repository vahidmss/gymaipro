"""Generate soft Telegram-like chat UI sound assets."""

from __future__ import annotations

import math
import os
import struct
import wave

OUT_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sounds')


def write_wav(path: str, samples: list[float], rate: int = 44100) -> None:
    with wave.open(path, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        frames = b''.join(
            struct.pack(
                '<h',
                max(-32767, min(32767, int(s * 32767))),
            )
            for s in samples
        )
        w.writeframes(frames)


def envelope(t: float, attack: float, release: float, total: float) -> float:
    if t < attack:
        return t / attack if attack > 0 else 1.0
    if t > total - release:
        return max(0.0, (total - t) / release) if release > 0 else 0.0
    return 1.0


def tone_burst(
    freq: float,
    dur: float,
    *,
    vol: float = 0.28,
    attack: float = 0.004,
    release: float = 0.04,
    rate: int = 44100,
    freq_end: float | None = None,
) -> list[float]:
    n = int(rate * dur)
    samples: list[float] = []
    for i in range(n):
        t = i / rate
        f = freq if freq_end is None else freq + (freq_end - freq) * (t / dur)
        env = envelope(t, attack, release, dur)
        s = math.sin(2 * math.pi * f * t) * 0.85 + math.sin(
            4 * math.pi * f * t,
        ) * 0.15
        samples.append(s * env * vol)
    return samples


def main() -> None:
    out_dir = os.path.abspath(OUT_DIR)
    os.makedirs(out_dir, exist_ok=True)

    # Soft ascending pop for send
    sent = tone_burst(
        620,
        0.055,
        vol=0.22,
        attack=0.002,
        release=0.035,
        freq_end=980,
    )
    overtone = tone_burst(
        1240,
        0.035,
        vol=0.12,
        attack=0.001,
        release=0.025,
    )
    if len(overtone) < len(sent):
        overtone = overtone + [0.0] * (len(sent) - len(overtone))
    sent = [a + b for a, b in zip(sent, overtone)]
    sent_path = os.path.join(out_dir, 'message_sent.wav')
    write_wav(sent_path, sent)

    # Soft double-tick for receive
    recv1 = tone_burst(
        880,
        0.045,
        vol=0.20,
        attack=0.002,
        release=0.03,
        freq_end=720,
    )
    gap = [0.0] * int(44100 * 0.028)
    recv2 = tone_burst(
        660,
        0.055,
        vol=0.24,
        attack=0.002,
        release=0.04,
        freq_end=540,
    )
    recv_path = os.path.join(out_dir, 'message_received.wav')
    write_wav(recv_path, recv1 + gap + recv2)

    print(f'wrote {sent_path} ({os.path.getsize(sent_path)} bytes)')
    print(f'wrote {recv_path} ({os.path.getsize(recv_path)} bytes)')


if __name__ == '__main__':
    main()
