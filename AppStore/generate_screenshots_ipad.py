"""
Salah Clarity — iPad App Store screenshot generator.

Produces 2064×2752 PNGs (iPad 13" — Apple's currently required iPad size)
for English and Russian. Reuses the copy dict from the iPhone generator so
the wording stays in sync.

Layout strategy: the iPad canvas is much wider than iPhone, so rather than
stretching iPhone-sized cards we center a 1600-px-wide content column and
let the gold theme gradient breathe on the sides. Captions get a larger
font size to match.

Run:

    python3 generate_screenshots_ipad.py

Outputs to screenshots/ipad-<lang>/NN-<slug>.png.
"""

from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

# Reuse the text dict from the iPhone generator so copy stays in sync.
from generate_screenshots import COPY  # noqa: E402

# ----------------------------- canvas --------------------------------------

W, H = 2064, 2752

# Centered content column — leaves ~232 px on each side.
CONTENT_X = 232
CONTENT_W = W - 2 * CONTENT_X  # 1600

# Theme colors (match Theme.swift, same as iPhone script)
BG_TOP        = (10, 15, 12)
BG_BOTTOM     = (15, 30, 25)
SURFACE       = (20, 28, 23)
GOLD          = (214, 176, 87)
TEXT          = (255, 255, 255)
TEXT_MUTED    = (166, 166, 166)

# ----------------------------- fonts ---------------------------------------

FONT_REG  = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
FONT_BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FONT_SRF  = "/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf"
FONT_MONO = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"

def f(path: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, size)

# ----------------------------- helpers -------------------------------------

def vertical_gradient(img: Image.Image) -> None:
    draw = ImageDraw.Draw(img)
    for y in range(H):
        t = y / (H - 1)
        r = int(BG_TOP[0] + (BG_BOTTOM[0] - BG_TOP[0]) * t)
        g = int(BG_TOP[1] + (BG_BOTTOM[1] - BG_TOP[1]) * t)
        b = int(BG_TOP[2] + (BG_BOTTOM[2] - BG_TOP[2]) * t)
        draw.line([(0, y), (W, y)], fill=(r, g, b))

def wrap_lines(draw: ImageDraw.ImageDraw, text: str,
               font: ImageFont.FreeTypeFont, max_width: int) -> list[str]:
    words, lines, cur = text.split(), [], ""
    for w in words:
        trial = (cur + " " + w).strip()
        if draw.textlength(trial, font=font) <= max_width or not cur:
            cur = trial
        else:
            lines.append(cur); cur = w
    if cur: lines.append(cur)
    return lines

def center_text(draw: ImageDraw.ImageDraw,
                text: str, y: int, font: ImageFont.FreeTypeFont,
                fill: tuple, max_width: int | None = None) -> int:
    max_width = max_width if max_width else W - 200
    ascent, descent = font.getmetrics()
    line_h = ascent + descent + 14
    for i, line in enumerate(wrap_lines(draw, text, font, max_width)):
        tw = draw.textlength(line, font=font)
        draw.text(((W - tw) / 2, y + i * line_h), line, font=font, fill=fill)
    return y + (len(wrap_lines(draw, text, font, max_width))) * line_h

def card(draw: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int,
         radius: int = 40, fill: tuple | None = None) -> None:
    draw.rounded_rectangle([x, y, x + w, y + h],
                           radius=radius, fill=fill or SURFACE,
                           outline=GOLD, width=2)

def brand_footer(draw: ImageDraw.ImageDraw) -> None:
    label = "Salah Clarity"
    font = f(FONT_SRF, 66)
    tw = draw.textlength(label, font=font)
    y = H - 200
    draw.line([(W // 2 - 300, y - 36), (W // 2 - 150, y - 36)],
              fill=GOLD, width=2)
    draw.line([(W // 2 + 150, y - 36), (W // 2 + 300, y - 36)],
              fill=GOLD, width=2)
    dcx, dcy = W // 2, y - 36
    draw.polygon([(dcx, dcy - 14), (dcx + 14, dcy),
                  (dcx, dcy + 14),  (dcx - 14, dcy)], fill=GOLD)
    draw.text(((W - tw) / 2, y), label, font=font, fill=GOLD)


# ----------------------------- screens -------------------------------------

def screen_prayer_times(strings: dict) -> Image.Image:
    img = Image.new("RGB", (W, H), BG_TOP); vertical_gradient(img)
    draw = ImageDraw.Draw(img)

    # Caption
    center_text(draw, strings["cap1"], 220, f(FONT_BOLD, 120), TEXT,
                max_width=W - 400)

    # Hijri date card
    cy = 700
    card(draw, CONTENT_X, cy, CONTENT_W, 240, radius=40)
    tw = draw.textlength(strings["hijri"], font=f(FONT_SRF, 76))
    draw.text((CONTENT_X + (CONTENT_W - tw) / 2, cy + 50),
              strings["hijri"], font=f(FONT_SRF, 76), fill=GOLD)
    tw = draw.textlength(strings["today"], font=f(FONT_REG, 46))
    draw.text((CONTENT_X + (CONTENT_W - tw) / 2, cy + 150),
              strings["today"], font=f(FONT_REG, 46), fill=TEXT_MUTED)

    # Next-prayer hero
    ny = cy + 240 + 50
    nh = 540
    card(draw, CONTENT_X, ny, CONTENT_W, nh, radius=40)
    label = strings["next"]
    tw = draw.textlength(label, font=f(FONT_REG, 46))
    draw.text((CONTENT_X + (CONTENT_W - tw) / 2, ny + 55), label.upper(),
              font=f(FONT_REG, 46), fill=TEXT_MUTED)

    big = strings["prayer_asr"]
    tw = draw.textlength(big, font=f(FONT_SRF, 230))
    draw.text((CONTENT_X + (CONTENT_W - tw) / 2, ny + 140),
              big, font=f(FONT_SRF, 230), fill=GOLD)

    remain = strings["remaining"]
    tw = draw.textlength(remain, font=f(FONT_REG, 58))
    draw.text((CONTENT_X + (CONTENT_W - tw) / 2, ny + 420),
              remain, font=f(FONT_REG, 58), fill=TEXT)

    # Prayer list
    ly = ny + nh + 50
    prayers = strings["prayers"]
    row_h = 130
    list_h = 50 + row_h * len(prayers) + 50
    card(draw, CONTENT_X, ly, CONTENT_W, list_h, radius=40)
    for i, (name, time, active) in enumerate(prayers):
        ry = ly + 50 + i * row_h
        if i > 0:
            draw.line([(CONTENT_X + 50, ry - 12),
                       (CONTENT_X + CONTENT_W - 50, ry - 12)],
                      fill=GOLD, width=1)
        draw.text((CONTENT_X + 70, ry + 30),
                  name, font=f(FONT_REG, 52),
                  fill=GOLD if active else TEXT)
        tw = draw.textlength(time, font=f(FONT_MONO, 52))
        draw.text((CONTENT_X + CONTENT_W - tw - 70, ry + 30),
                  time, font=f(FONT_MONO, 52),
                  fill=GOLD if active else TEXT)
    brand_footer(draw)
    return img


def screen_qibla(strings: dict) -> Image.Image:
    img = Image.new("RGB", (W, H), BG_TOP); vertical_gradient(img)
    draw = ImageDraw.Draw(img)

    center_text(draw, strings["cap2"], 220, f(FONT_BOLD, 120), TEXT,
                max_width=W - 400)

    # Compass
    cx, cy, sz = W // 2, 1440, 1100
    draw.ellipse([cx - sz // 2, cy - sz // 2, cx + sz // 2, cy + sz // 2],
                 outline=GOLD, width=5)
    draw.ellipse([cx - sz // 2 + 100, cy - sz // 2 + 100,
                  cx + sz // 2 - 100, cy + sz // 2 - 100],
                 outline=GOLD, width=2)
    for tick in range(0, 360, 15):
        a = math.radians(tick - 90)
        r1 = sz // 2 - 22
        r2 = sz // 2 - (60 if tick % 45 == 0 else 40)
        draw.line([(cx + r1 * math.cos(a), cy + r1 * math.sin(a)),
                   (cx + r2 * math.cos(a), cy + r2 * math.sin(a))],
                  fill=GOLD, width=3)
    for ad, lbl in [(0, "N"), (90, "E"), (180, "S"), (270, "W")]:
        a = math.radians(ad - 90)
        lx = cx + int((sz // 2 - 200) * math.cos(a))
        ly = cy + int((sz // 2 - 200) * math.sin(a))
        tw = draw.textlength(lbl, font=f(FONT_BOLD, 68))
        draw.text((lx - tw / 2, ly - 40), lbl,
                  font=f(FONT_BOLD, 68),
                  fill=GOLD if lbl == "N" else TEXT_MUTED)

    # Qibla arrow at 47° east of north
    qa = math.radians(47 - 90)
    tip_x = cx + int((sz // 2 - 120) * math.cos(qa))
    tip_y = cy + int((sz // 2 - 120) * math.sin(qa))
    base_angle = qa + math.pi
    b1 = (cx + int(90 * math.cos(base_angle - 0.22)),
          cy + int(90 * math.sin(base_angle - 0.22)))
    b2 = (cx + int(90 * math.cos(base_angle + 0.22)),
          cy + int(90 * math.sin(base_angle + 0.22)))
    draw.polygon([(tip_x, tip_y), b1, b2], fill=GOLD)

    kaaba = strings["kaaba"]
    klx = cx + int((sz // 2 + 80) * math.cos(qa))
    kly = cy + int((sz // 2 + 80) * math.sin(qa))
    ktw = draw.textlength(kaaba, font=f(FONT_BOLD, 58))
    draw.text((klx - ktw / 2, kly - 36), kaaba,
              font=f(FONT_BOLD, 58), fill=GOLD)

    # Distance
    dist_y = cy + sz // 2 + 120
    tw = draw.textlength(strings["distance"], font=f(FONT_SRF, 78))
    draw.text(((W - tw) / 2, dist_y),
              strings["distance"], font=f(FONT_SRF, 78), fill=TEXT)

    center_text(draw, strings["calibrate"], dist_y + 140,
                f(FONT_REG, 46), TEXT_MUTED, max_width=W - 400)
    brand_footer(draw)
    return img


def screen_qaza(strings: dict) -> Image.Image:
    img = Image.new("RGB", (W, H), BG_TOP); vertical_gradient(img)
    draw = ImageDraw.Draw(img)

    center_text(draw, strings["cap3"], 220, f(FONT_BOLD, 120), TEXT,
                max_width=W - 400)

    # Streak card
    cy = 700
    card(draw, CONTENT_X, cy, CONTENT_W, 400, radius=44)
    tw = draw.textlength(strings["streak_label"], font=f(FONT_REG, 50))
    draw.text((CONTENT_X + (CONTENT_W - tw) / 2, cy + 50),
              strings["streak_label"].upper(),
              font=f(FONT_REG, 50), fill=TEXT_MUTED)
    tw = draw.textlength(strings["streak_value"], font=f(FONT_SRF, 200))
    draw.text((CONTENT_X + (CONTENT_W - tw) / 2, cy + 130),
              strings["streak_value"],
              font=f(FONT_SRF, 200), fill=GOLD)

    bar_y = cy + 360
    draw.rounded_rectangle([CONTENT_X + 80, bar_y,
                            CONTENT_X + CONTENT_W - 80, bar_y + 18],
                           radius=9, fill=(40, 50, 42))
    draw.rounded_rectangle(
        [CONTENT_X + 80, bar_y,
         CONTENT_X + 80 + int((CONTENT_W - 160) * 0.62), bar_y + 18],
        radius=9, fill=GOLD)

    # Per-prayer list
    rows = strings["qaza_rows"]
    ly = cy + 480
    row_h = 130
    list_h = 50 + row_h * len(rows) + 50
    card(draw, CONTENT_X, ly, CONTENT_W, list_h, radius=40)
    for i, (name, progress) in enumerate(rows):
        ry = ly + 50 + i * row_h
        if i > 0:
            draw.line([(CONTENT_X + 50, ry - 12),
                       (CONTENT_X + CONTENT_W - 50, ry - 12)],
                      fill=GOLD, width=1)
        draw.text((CONTENT_X + 70, ry + 30), name,
                  font=f(FONT_REG, 52), fill=TEXT)
        tw = draw.textlength(progress, font=f(FONT_MONO, 48))
        draw.text((CONTENT_X + CONTENT_W - tw - 70, ry + 38),
                  progress, font=f(FONT_MONO, 48), fill=TEXT_MUTED)

    # CTA
    cta_y = ly + list_h + 60
    cta = strings["cta_mark"]
    draw.rounded_rectangle([CONTENT_X + 80, cta_y,
                            CONTENT_X + CONTENT_W - 80, cta_y + 140],
                           radius=70, fill=GOLD)
    tw = draw.textlength(cta, font=f(FONT_BOLD, 56))
    draw.text((CONTENT_X + (CONTENT_W - tw) / 2, cta_y + 40),
              cta, font=f(FONT_BOLD, 56), fill=(10, 15, 12))

    # Tagline
    center_text(draw, strings["qaza_tagline"], cta_y + 280,
                f(FONT_SRF, 64), TEXT, max_width=W - 400)
    brand_footer(draw)
    return img


def screen_reminders(strings: dict) -> Image.Image:
    img = Image.new("RGB", (W, H), BG_TOP); vertical_gradient(img)
    draw = ImageDraw.Draw(img)

    center_text(draw, strings["cap4"], 220, f(FONT_BOLD, 120), TEXT,
                max_width=W - 400)

    # Hadith hero card (sized to content)
    body_font = f(FONT_REG, 52)
    body_lines = wrap_lines(draw, strings["hadith_body"],
                            body_font, CONTENT_W - 160)
    card_h = 70 + 60 + 100 + 60 + len(body_lines) * 78 + 70 + 50
    cy = 720
    card(draw, CONTENT_X, cy, CONTENT_W, card_h, radius=44)

    draw.text((CONTENT_X + 70, cy + 60),
              strings["hadith_label"].upper(),
              font=f(FONT_BOLD, 44), fill=GOLD)
    draw.text((CONTENT_X + 70, cy + 150),
              strings["hadith_title"],
              font=f(FONT_SRF, 92), fill=TEXT)

    body_y = cy + 300
    for ln in body_lines:
        tw = draw.textlength(ln, font=body_font)
        draw.text((CONTENT_X + (CONTENT_W - tw) / 2, body_y),
                  ln, font=body_font, fill=TEXT)
        body_y += 78

    draw.text((CONTENT_X + 70, body_y + 30),
              strings["hadith_source"],
              font=f(FONT_REG, 42), fill=TEXT_MUTED)

    # Chip row
    cy_chip = cy + card_h + 60
    x = CONTENT_X
    for label, active in strings["chips"]:
        w_label = int(draw.textlength(label, font=f(FONT_REG, 46))) + 100
        draw.rounded_rectangle([x, cy_chip, x + w_label, cy_chip + 106],
                                radius=53,
                                fill=GOLD if active else (30, 40, 32),
                                outline=GOLD, width=2)
        draw.text((x + 50, cy_chip + 28), label,
                  font=f(FONT_REG, 46),
                  fill=(10, 15, 12) if active else TEXT)
        x += w_label + 24

    # Secondary cards
    ly = cy_chip + 200
    for i, item in enumerate(strings["more_reminders"]):
        card(draw, CONTENT_X, ly + i * 240, CONTENT_W, 200, radius=36)
        draw.text((CONTENT_X + 70, ly + i * 240 + 50),
                  item["title"], font=f(FONT_BOLD, 56), fill=TEXT)
        draw.text((CONTENT_X + 70, ly + i * 240 + 130),
                  item["body"], font=f(FONT_REG, 42), fill=TEXT_MUTED)

    tag_y = ly + 240 * len(strings["more_reminders"]) + 40
    center_text(draw, strings["reminders_tagline"], tag_y,
                f(FONT_SRF, 60), TEXT, max_width=W - 400)
    brand_footer(draw)
    return img


def screen_privacy(strings: dict) -> Image.Image:
    img = Image.new("RGB", (W, H), BG_TOP); vertical_gradient(img)
    draw = ImageDraw.Draw(img)

    center_text(draw, strings["cap5"], 220, f(FONT_BOLD, 120), TEXT,
                max_width=W - 400)

    # Lock
    cx, cy, r = W // 2, 1180, 320
    draw.ellipse([cx - r, cy - r, cx + r, cy + r],
                 outline=GOLD, width=8)
    body_w, body_h = 290, 220
    draw.rounded_rectangle(
        [cx - body_w // 2, cy - body_h // 2 + 40,
         cx + body_w // 2, cy + body_h // 2 + 40],
        radius=22, fill=GOLD)
    draw.arc([cx - 100, cy - 180, cx + 100, cy + 60],
             start=180, end=360, fill=GOLD, width=28)

    # Three principles
    principles = strings["principles"]
    ly = cy + r + 200
    for i, p in enumerate(principles):
        row_y = ly + i * 240
        # Checkmark
        draw.ellipse([CONTENT_X, row_y, CONTENT_X + 110, row_y + 110],
                     outline=GOLD, width=4)
        draw.line([(CONTENT_X + 28, row_y + 58),
                   (CONTENT_X + 54, row_y + 84)], fill=GOLD, width=8)
        draw.line([(CONTENT_X + 54, row_y + 84),
                   (CONTENT_X + 88, row_y + 38)], fill=GOLD, width=8)
        draw.text((CONTENT_X + 160, row_y + 10),
                  p["title"], font=f(FONT_BOLD, 62), fill=TEXT)
        draw.text((CONTENT_X + 160, row_y + 90),
                  p["body"], font=f(FONT_REG, 44), fill=TEXT_MUTED)

    brand_footer(draw)
    return img


SCREENS = [
    ("01-prayer-times", screen_prayer_times),
    ("02-qibla",        screen_qibla),
    ("03-qaza",         screen_qaza),
    ("04-reminders",    screen_reminders),
    ("05-privacy",      screen_privacy),
]


def main() -> None:
    out_root = Path(__file__).parent / "screenshots"
    for lang in ("en", "ru"):
        out_dir = out_root / f"ipad-{lang}"
        out_dir.mkdir(parents=True, exist_ok=True)
        strings = COPY[lang]
        for slug, fn in SCREENS:
            img = fn(strings)
            out_path = out_dir / f"{slug}.png"
            img.save(out_path, "PNG", optimize=True)
            print(f"  wrote {out_path.relative_to(out_root.parent)}")
    print("\nDone. Upload the 5 files per language to App Store Connect "
          "→ iPad 13\" Display.")


if __name__ == "__main__":
    main()
