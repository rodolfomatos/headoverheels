#!/usr/bin/env python3
"""Counts what a browser capture of a game actually shows.

The question this answers is the one a screenshot cannot: is anything drawn, and
where. It reads a PNG, counts the pixels that differ from the background, and
prints the box around them, so "the room is in the corner" and "the room fills
the view" are two different numbers.

    python3 scripts/browser_pixels.py build/browser/hoh_*.png [--region x,y,w,h]
"""

import argparse
import collections
import pathlib
import struct
import sys
import zlib


def decode(path):
    """A PNG as (width, height, channels, pixels). RGBA and RGB, 8 bits."""
    data = pathlib.Path(path).read_bytes()
    pos = 8
    idat = b""
    width = height = 0
    channels = 4
    while pos < len(data):
        length = struct.unpack(">I", data[pos : pos + 4])[0]
        kind = data[pos + 4 : pos + 8]
        chunk = data[pos + 8 : pos + 8 + length]
        if kind == b"IHDR":
            width, height, depth, colour = struct.unpack(">IIBB", chunk[:10])
            if depth != 8:
                raise SystemExit(f"{path}: only 8 bits per channel is supported")
            channels = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[colour]
        elif kind == b"IDAT":
            idat += chunk
        pos += 12 + length

    raw = zlib.decompress(idat)
    stride = width * channels
    out = bytearray()
    previous = bytearray(stride)
    i = 0
    for _ in range(height):
        filt = raw[i]
        i += 1
        line = bytearray(raw[i : i + stride])
        i += stride
        if filt == 1:
            for x in range(channels, stride):
                line[x] = (line[x] + line[x - channels]) & 0xFF
        elif filt == 2:
            for x in range(stride):
                line[x] = (line[x] + previous[x]) & 0xFF
        elif filt == 3:
            for x in range(stride):
                a = line[x - channels] if x >= channels else 0
                line[x] = (line[x] + ((a + previous[x]) >> 1)) & 0xFF
        elif filt == 4:
            for x in range(stride):
                a = line[x - channels] if x >= channels else 0
                b = previous[x]
                c = previous[x - channels] if x >= channels else 0
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pred = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                line[x] = (line[x] + pred) & 0xFF
        out += line
        previous = line
    return width, height, channels, bytes(out)


def measure(path, background=None, region=None):
    width, height, channels, pixels = decode(path)
    stride = width * channels
    x0, y0, x1, y1 = 0, 0, width, height
    if region:
        x0, y0, w, h = region
        x1, y1 = x0 + w, y0 + h

    if background is None:
        # The most common colour in the region is the backdrop: a game's
        # background is by far the largest single thing in the frame.
        tally = collections.Counter()
        for y in range(y0, y1, 2):
            for x in range(x0, x1, 2):
                o = y * stride + x * channels
                tally[(pixels[o], pixels[o + 1], pixels[o + 2])] += 1
        background = tally.most_common(1)[0][0]

    counts = collections.Counter()
    min_x = width
    min_y = height
    max_x = -1
    max_y = -1
    ink = 0
    total = 0
    for y in range(y0, y1):
        for x in range(x0, x1):
            o = y * stride + x * channels
            colour = (pixels[o], pixels[o + 1], pixels[o + 2])
            total += 1
            if colour == background:
                continue
            counts[colour] += 1
            ink += 1
            if x < min_x:
                min_x = x
            if y < min_y:
                min_y = y
            if x > max_x:
                max_x = x
            if y > max_y:
                max_y = y

    return {
        "file": str(path),
        "size": [width, height],
        "region": [x0, y0, x1, y1],
        "background": "#%02x%02x%02x" % background,
        "ink": ink,
        "of": total,
        "colours": len(counts),
        "box": [min_x, min_y, max_x + 1, max_y + 1] if max_x >= 0 else None,
        "box_fraction": None
        if max_x < 0
        else [
            round((max_x + 1 - min_x) / width, 3),
            round((max_y + 1 - min_y) / height, 3),
        ],
        "top": [
            ["#%02x%02x%02x" % c, n] for c, n in counts.most_common(5)
        ],
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("png", nargs="+")
    ap.add_argument("--region", default="0,0,0,0", help="x,y,w,h")
    ap.add_argument("--background", default=None, help="#rrggbb")
    args = ap.parse_args()

    region = None
    if args.region != "0,0,0,0":
        region = [int(v) for v in args.region.split(",")]
    background = None
    if args.background:
        h = args.background.lstrip("#")
        background = (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))

    for path in args.png:
        print(measure(path, background, region))


if __name__ == "__main__":
    sys.exit(main())
