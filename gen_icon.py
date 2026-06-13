#!/usr/bin/env python3
"""Generate the LiveEarth app icon (1024x1024) as a PNG using only the stdlib.
A glowing blue globe with a soft atmosphere halo and an amber radar sweep,
on a deep-navy space background — matching the web app's palette."""
import struct, zlib, math

N = 1024
cx = cy = N / 2.0

def lerp(a, b, t): return a + (b - a) * t
def mix(c1, c2, t): return tuple(lerp(c1[i], c2[i], t) for i in range(3))
def clamp(v, lo=0.0, hi=255.0): return max(lo, min(hi, v))

# palette
SPACE_TOP = (11, 23, 48)     # #0b1730
SPACE_BOT = (4, 6, 14)       # #04060e
GLOBE_LIGHT = (140, 205, 255)
GLOBE_MID = (45, 130, 220)
GLOBE_DARK = (10, 40, 90)
GLOBE_LIMB = (6, 22, 55)
AMBER = (255, 180, 84)
HALO = (61, 168, 255)

R = N * 0.36                 # globe radius
# light direction (upper-left)
lx, ly, lz = -0.5, -0.55, 0.67
ll = math.sqrt(lx*lx+ly*ly+lz*lz); lx,ly,lz = lx/ll, ly/ll, lz/ll

rows = bytearray()
for y in range(N):
    rows.append(0)  # filter byte 0 per scanline
    ny = (y - cy)
    for x in range(N):
        nx = (x - cx)
        d = math.sqrt(nx*nx + ny*ny)

        # background radial gradient
        bg_t = clamp(d / (N*0.72), 0, 1) / 255.0 * 255.0
        bt = clamp(d / (N*0.72)) if False else min(1.0, d/(N*0.72))
        r, g, b = mix(SPACE_TOP, SPACE_BOT, bt)

        # atmosphere halo just outside the globe
        if d > R*0.86:
            glow = math.exp(-((d - R) / (R*0.20))**2)
            if d < R: glow *= 0.6
            r = clamp(r + HALO[0]*glow*0.55)
            g = clamp(g + HALO[1]*glow*0.55)
            b = clamp(b + HALO[2]*glow*0.55)

        a = 255.0
        if d <= R:
            # sphere normal
            nz = math.sqrt(max(0.0, R*R - d*d)) / R
            sx, sy = nx / R, ny / R
            diff = max(0.0, sx*lx + sy*ly + nz*lz)
            shade = 0.18 + 0.82 * diff
            # base sphere color from dark -> mid by shade
            col = mix(GLOBE_DARK, GLOBE_MID, shade)
            # specular highlight
            spec = max(0.0, diff) ** 14
            col = mix(col, GLOBE_LIGHT, min(1.0, spec*0.9))
            # limb darkening near edge
            edge = clamp((d - R*0.82) / (R*0.18)) if d > R*0.82 else 0.0
            col = mix(col, GLOBE_LIMB, edge*0.8)

            # subtle latitude bands for a planetary feel
            band = 0.5 + 0.5*math.sin((sy)*9.0)
            col = mix(col, GLOBE_LIGHT, 0.05*band*diff)

            # amber radar sweep wedge (lower-right)
            ang = math.atan2(sy, sx)
            sweep_c = -0.7
            dwedge = abs(((ang - sweep_c + math.pi) % (2*math.pi)) - math.pi)
            if dwedge < 0.36:
                w = (1 - dwedge/0.36) ** 1.5
                # fade the sweep from bright leading edge outward along radius
                radial = clamp(d / (R*0.92))
                col = mix(col, AMBER, 0.6*w*radial*(0.4+0.6*diff))

            r, g, b = col

            # antialias the globe edge
            if d > R - 1.5:
                a = clamp((R - d + 1.5) / 1.5 * 255.0)

        rows.append(int(clamp(r)))
        rows.append(int(clamp(g)))
        rows.append(int(clamp(b)))
        rows.append(int(clamp(a)))

def chunk(typ, data):
    c = struct.pack(">I", len(data)) + typ + data
    return c + struct.pack(">I", zlib.crc32(typ + data) & 0xffffffff)

png = b"\x89PNG\r\n\x1a\n"
png += chunk(b"IHDR", struct.pack(">IIBBBBB", N, N, 8, 6, 0, 0, 0))  # 8-bit RGBA
png += chunk(b"IDAT", zlib.compress(bytes(rows), 9))
png += chunk(b"IEND", b"")

with open("LiveEarth/Assets.xcassets/AppIcon.appiconset/AppIcon.png", "wb") as f:
    f.write(png)
print("wrote AppIcon.png", len(png), "bytes")
