"""
SilentAlpha app icon generator.
Outputs: assets/icon/app_icon.png (1024x1024)
"""
from PIL import Image, ImageDraw, ImageFilter, ImageFont
import math, os

SIZE = 1024
HALF = SIZE // 2

# ── Palette ──────────────────────────────────────────────────────────────────
BG       = (6, 6, 18)         # #060612  near-black navy
PURPLE   = (108, 99, 255)     # #6C63FF  brand primary
GOLD     = (255, 210, 60)     # #FFD23C  warm gold
SILVER   = (200, 210, 230)    # #C8D2E6  star/dust colour

# ── Helpers ───────────────────────────────────────────────────────────────────

def make_radial_glow(size, colour, radius_frac=0.48, max_alpha=200):
    """Soft radial gradient circle, ready to alpha-composite."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d   = ImageDraw.Draw(img)
    cx = cy = size // 2
    steps = 60
    for i in range(steps, 0, -1):
        r     = int(cx * radius_frac * i / steps)
        alpha = int(max_alpha * (1 - i / steps) ** 1.4)
        d.ellipse([cx - r, cy - r, cx + r, cy + r],
                  fill=(*colour, alpha))
    return img.filter(ImageFilter.GaussianBlur(radius=40))


def load_font(size):
    candidates = [
        r"C:\Windows\Fonts\segoeuib.ttf",
        r"C:\Windows\Fonts\arialbd.ttf",
        r"C:\Windows\Fonts\timesbd.ttf",
        r"C:\Windows\Fonts\calibrib.ttf",
    ]
    for path in candidates:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                continue
    return ImageFont.load_default()


def draw_stars(draw, count=220, seed=7):
    import random
    rng = random.Random(seed)
    for _ in range(count):
        x = rng.randint(0, SIZE)
        y = rng.randint(0, SIZE)
        r = rng.choice([1, 1, 1, 2])
        a = rng.randint(60, 200)
        draw.ellipse([x - r, y - r, x + r, y + r],
                     fill=(*SILVER, a))


def draw_constellation(draw):
    """Six bright 'star' nodes connected by faint lines — market-data feel."""
    nodes = [
        (160, 200), (310, 130), (700, 160),
        (870, 280), (780, 820), (200, 760),
    ]
    for a, b in [(0,1),(1,2),(2,3),(3,4),(4,5),(5,0),(1,3)]:
        draw.line([nodes[a], nodes[b]], fill=(*PURPLE, 35), width=2)
    for (x, y) in nodes:
        r = 5
        draw.ellipse([x-r, y-r, x+r, y+r], fill=(*SILVER, 160))


def draw_chart_wave(draw):
    """Faint rising chart line at the bottom-third."""
    import math
    pts = []
    n = 32
    for i in range(n):
        t  = i / (n - 1)
        px = int(SIZE * 0.08 + t * SIZE * 0.84)
        py = int(SIZE * 0.82
                 - t * SIZE * 0.08
                 + math.sin(t * math.pi * 4) * SIZE * 0.025
                 + math.sin(t * math.pi * 9) * SIZE * 0.010)
        pts.append((px, py))
    for i in range(len(pts) - 1):
        prog  = i / (n - 2)
        r = int(PURPLE[0] * (1 - prog) + GOLD[0] * prog)
        g = int(PURPLE[1] * (1 - prog) + GOLD[1] * prog)
        b = int(PURPLE[2] * (1 - prog) + GOLD[2] * prog)
        draw.line([pts[i], pts[i + 1]], fill=(r, g, b, 90), width=3)


def draw_alpha_gradient(base, font):
    """Render the α glyph: gold fill + purple shadow + inner highlight."""
    char = 'α'  # α

    # Measure
    tmp  = ImageDraw.Draw(base)
    bbox = tmp.textbbox((0, 0), char, font=font)
    tw   = bbox[2] - bbox[0]
    th   = bbox[3] - bbox[1]
    tx   = HALF - tw // 2 - bbox[0]
    ty   = HALF - th // 2 - bbox[1] - SIZE // 30   # nudge up slightly

    # ── Layer 1: deep purple shadow (offset) ────────────────────────────────
    shadow = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.text((tx + 14, ty + 14), char, font=font, fill=(*PURPLE, 180))
    shadow = shadow.filter(ImageFilter.GaussianBlur(22))
    base = Image.alpha_composite(base, shadow)

    # ── Layer 2: outer purple glow ───────────────────────────────────────────
    glow = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.text((tx, ty), char, font=font, fill=(*PURPLE, 255))
    glow = glow.filter(ImageFilter.GaussianBlur(18))
    base = Image.alpha_composite(base, glow)

    # ── Layer 3: gold fill ───────────────────────────────────────────────────
    gold_layer = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    gld = ImageDraw.Draw(gold_layer)
    gld.text((tx, ty), char, font=font, fill=(*GOLD, 255))
    base = Image.alpha_composite(base, gold_layer)

    # ── Layer 4: white inner highlight (top-left shimmer) ────────────────────
    hi = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    hd = ImageDraw.Draw(hi)
    hd.text((tx - 3, ty - 3), char, font=font, fill=(255, 255, 255, 60))
    hi = hi.filter(ImageFilter.GaussianBlur(6))
    base = Image.alpha_composite(base, hi)

    return base


def draw_ring(draw):
    """Thin gradient ring around the icon perimeter."""
    margin = 28
    ring_w = 8
    for i in range(360):
        angle = math.radians(i)
        # Gradient: purple → gold → purple
        t = (math.sin(angle) + 1) / 2
        r = int(PURPLE[0] * (1 - t) + GOLD[0] * t)
        g = int(PURPLE[1] * (1 - t) + GOLD[1] * t)
        b = int(PURPLE[2] * (1 - t) + GOLD[2] * t)
        for w in range(ring_w):
            rad = HALF - margin - w
            x = HALF + int(rad * math.cos(angle))
            y = HALF + int(rad * math.sin(angle))
            draw.point((x, y), fill=(r, g, b, 180))


# ── Compose ───────────────────────────────────────────────────────────────────

def build():
    # Background
    canvas = Image.new('RGBA', (SIZE, SIZE), (*BG, 255))

    # Radial purple glow in centre
    glow = make_radial_glow(SIZE, PURPLE, radius_frac=0.52, max_alpha=160)
    canvas = Image.alpha_composite(canvas, glow)

    # Secondary gold accent glow (softer, smaller)
    glow2 = make_radial_glow(SIZE, GOLD, radius_frac=0.22, max_alpha=55)
    canvas = Image.alpha_composite(canvas, glow2)

    # Background details
    d = ImageDraw.Draw(canvas)
    draw_stars(d)
    draw_constellation(d)
    draw_chart_wave(d)
    draw_ring(d)

    # Load font — try large size first, fall back smaller
    font = None
    for pt in [680, 580, 480]:
        f = load_font(pt)
        # Check it can actually render α (non-default fonts only)
        if hasattr(f, 'getbbox'):
            font = f
            break
    if font is None:
        font = load_font(580)

    # Alpha character (main centrepiece)
    canvas = draw_alpha_gradient(canvas, font)

    # Flatten to RGB for saving
    out = Image.new('RGB', (SIZE, SIZE), BG)
    out.paste(canvas, mask=canvas.split()[3])

    os.makedirs('assets/icon', exist_ok=True)
    out.save('assets/icon/app_icon.png', 'PNG')
    print(f"Saved assets/icon/app_icon.png ({SIZE}x{SIZE})")


if __name__ == '__main__':
    build()
