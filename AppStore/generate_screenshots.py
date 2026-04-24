"""
Salah Clarity — App Store screenshot generator.

Produces 1320x2868 PNG screenshots (iPhone 6.9" — Apple's primary iPhone size)
for English, Russian, and Kyrgyz. Each screenshot has:

  - A calm caption band at the top (matches app theme: dark gradient + gold).
  - A stylized "phone screen" showing the feature being pitched, rounded.
  - Five shots per language: Prayer Times, Qibla, Qaza, Reminders, Privacy.

Run from the AppStore/ directory:

    python3 generate_screenshots.py

Outputs to screenshots/<lang>/NN-<slug>.png.
"""

from __future__ import annotations

import math
import os
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

# ----------------------------- canvas --------------------------------------

W, H = 1320, 2868

# App theme colors (match Theme.swift)
BG_TOP        = (10, 15, 12)
BG_BOTTOM     = (15, 30, 25)
SURFACE       = (20, 28, 23)
SURFACE_BRDR  = (214, 176, 87, 40)    # gold 15%
GOLD          = (214, 176, 87)
GOLD_SOFT     = (158, 133, 71)
GREEN         = (10, 74, 56)
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

def vertical_gradient(img: Image.Image, top: tuple, bottom: tuple) -> None:
    """Paint a smooth top→bottom gradient across the whole canvas."""
    draw = ImageDraw.Draw(img)
    for y in range(H):
        t = y / (H - 1)
        r = int(top[0] + (bottom[0] - top[0]) * t)
        g = int(top[1] + (bottom[1] - top[1]) * t)
        b = int(top[2] + (bottom[2] - top[2]) * t)
        draw.line([(0, y), (W, y)], fill=(r, g, b))

def center_text(draw: ImageDraw.ImageDraw,
                text: str, y: int, font: ImageFont.FreeTypeFont,
                fill: tuple, max_width: int = W - 160) -> int:
    """Draw text horizontally centered; wrap if it's wider than max_width.
    Returns the y position just below the drawn block."""
    words = text.split()
    lines: list[str] = []
    cur = ""
    for w in words:
        trial = (cur + " " + w).strip()
        if draw.textlength(trial, font=font) <= max_width or not cur:
            cur = trial
        else:
            lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)

    ascent, descent = font.getmetrics()
    line_h = ascent + descent + 12
    for i, line in enumerate(lines):
        tw = draw.textlength(line, font=font)
        draw.text(((W - tw) / 2, y + i * line_h), line, font=font, fill=fill)
    return y + len(lines) * line_h

def card(draw: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int,
         radius: int = 32, fill: tuple | None = None) -> None:
    """Theme surface card — translucent dark with a 1px gold stroke."""
    fill = fill or SURFACE
    draw.rounded_rectangle([x, y, x + w, y + h],
                           radius=radius, fill=fill,
                           outline=(GOLD[0], GOLD[1], GOLD[2]),
                           width=2)

def mosque_arch(draw: ImageDraw.ImageDraw, cx: int, cy: int, r: int,
                color: tuple = GOLD, alpha: int = 70) -> None:
    """Decorative Moorish arch silhouette, drawn faintly for ambience."""
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    c = (color[0], color[1], color[2], alpha)
    od.pieslice([cx - r, cy - r, cx + r, cy + r],
                start=180, end=360, fill=c)
    od.rectangle([cx - r, cy, cx + r, cy + int(r * 0.6)], fill=c)
    return overlay

# ----------------------------- screens -------------------------------------

def brand_footer(draw: ImageDraw.ImageDraw) -> None:
    """Small gold wordmark at the very bottom of every shot — ties the
    series together and prevents an empty bottom when content is short."""
    label = "Salah Clarity"
    font = f(FONT_SRF, 56)
    tw = draw.textlength(label, font=font)
    y = H - 160
    # Separator ornament
    draw.line([(W // 2 - 240, y - 30), (W // 2 - 120, y - 30)],
              fill=GOLD, width=2)
    draw.line([(W // 2 + 120, y - 30), (W // 2 + 240, y - 30)],
              fill=GOLD, width=2)
    # Tiny diamond
    dcx, dcy = W // 2, y - 30
    draw.polygon([(dcx, dcy - 12), (dcx + 12, dcy),
                  (dcx, dcy + 12),  (dcx - 12, dcy)], fill=GOLD)
    # Wordmark
    draw.text(((W - tw) / 2, y), label, font=font, fill=GOLD)


def screen_prayer_times(lang_code: str, strings: dict) -> Image.Image:
    img = Image.new("RGB", (W, H), BG_TOP)
    vertical_gradient(img, BG_TOP, BG_BOTTOM)
    draw = ImageDraw.Draw(img)

    # Caption at the top (2 lines max)
    y = 180
    y = center_text(draw, strings["cap1"], y, f(FONT_BOLD, 92), TEXT)

    # Hijri date card
    cx, cy, cw, ch = 100, 620, W - 200, 220
    card(draw, cx, cy, cw, ch, radius=36)
    tw = draw.textlength(strings["hijri"], font=f(FONT_SRF, 64))
    draw.text((cx + (cw - tw) / 2, cy + 40), strings["hijri"],
              font=f(FONT_SRF, 64), fill=GOLD)
    tw = draw.textlength(strings["today"], font=f(FONT_REG, 42))
    draw.text((cx + (cw - tw) / 2, cy + 130), strings["today"],
              font=f(FONT_REG, 42), fill=TEXT_MUTED)

    # Next-prayer card (hero)
    nx, ny, nw, nh = cx, cy + ch + 40, cw, 500
    card(draw, nx, ny, nw, nh, radius=36)
    label = strings["next"]
    tw = draw.textlength(label, font=f(FONT_REG, 42))
    draw.text((nx + (nw - tw) / 2, ny + 50), label.upper(),
              font=f(FONT_REG, 42), fill=TEXT_MUTED)

    big = strings["prayer_asr"]
    tw = draw.textlength(big, font=f(FONT_SRF, 200))
    draw.text((nx + (nw - tw) / 2, ny + 130), big,
              font=f(FONT_SRF, 200), fill=GOLD)

    remain = strings["remaining"]
    tw = draw.textlength(remain, font=f(FONT_REG, 52))
    draw.text((nx + (nw - tw) / 2, ny + 380), remain,
              font=f(FONT_REG, 52), fill=TEXT)

    # Prayer list
    lx, ly, lw = cx, ny + nh + 40, cw
    prayers = strings["prayers"]
    row_h = 120
    list_h = 40 + row_h * len(prayers) + 40
    card(draw, lx, ly, lw, list_h, radius=36)
    for i, (name, time, active) in enumerate(prayers):
        ry = ly + 40 + i * row_h
        if i > 0:
            draw.line([(lx + 40, ry - 10), (lx + lw - 40, ry - 10)],
                      fill=(GOLD[0], GOLD[1], GOLD[2]), width=1)
        draw.text((lx + 60, ry + 30), name, font=f(FONT_REG, 48),
                  fill=GOLD if active else TEXT)
        tw = draw.textlength(time, font=f(FONT_MONO, 48))
        draw.text((lx + lw - tw - 60, ry + 30), time,
                  font=f(FONT_MONO, 48),
                  fill=GOLD if active else TEXT)
    brand_footer(draw)
    return img


def screen_qibla(lang_code: str, strings: dict) -> Image.Image:
    img = Image.new("RGB", (W, H), BG_TOP)
    vertical_gradient(img, BG_TOP, BG_BOTTOM)
    draw = ImageDraw.Draw(img)

    y = 180
    y = center_text(draw, strings["cap2"], y, f(FONT_BOLD, 92), TEXT)

    # Compass — moved up so it's closer to the caption (was floating)
    cx, cy, sz = W // 2, 1380, 900
    # Outer ring
    draw.ellipse([cx - sz // 2, cy - sz // 2, cx + sz // 2, cy + sz // 2],
                 outline=GOLD, width=4)
    # Inner ring
    draw.ellipse([cx - sz // 2 + 80, cy - sz // 2 + 80,
                  cx + sz // 2 - 80, cy + sz // 2 - 80],
                 outline=(GOLD[0], GOLD[1], GOLD[2]), width=2)
    # Tick marks every 15°
    for tick in range(0, 360, 15):
        a = math.radians(tick - 90)
        r1 = sz // 2 - 20
        r2 = sz // 2 - (50 if tick % 45 == 0 else 34)
        draw.line([(cx + r1 * math.cos(a), cy + r1 * math.sin(a)),
                   (cx + r2 * math.cos(a), cy + r2 * math.sin(a))],
                  fill=(GOLD[0], GOLD[1], GOLD[2]), width=3)
    # Cardinal marks — pulled in further to leave room for the Makkah label
    for angle_deg, label in [(0, "N"), (90, "E"), (180, "S"), (270, "W")]:
        a = math.radians(angle_deg - 90)
        lx = cx + int((sz // 2 - 170) * math.cos(a))
        ly = cy + int((sz // 2 - 170) * math.sin(a))
        tw = draw.textlength(label, font=f(FONT_BOLD, 56))
        draw.text((lx - tw / 2, ly - 32), label, font=f(FONT_BOLD, 56),
                  fill=GOLD if label == "N" else TEXT_MUTED)

    # Qibla arrow (~47° east of north — clears the N cardinal)
    qa = math.radians(47 - 90)
    tip_x = cx + int((sz // 2 - 90) * math.cos(qa))
    tip_y = cy + int((sz // 2 - 90) * math.sin(qa))
    base_angle = qa + math.pi
    b1 = (cx + int(70 * math.cos(base_angle - 0.22)),
          cy + int(70 * math.sin(base_angle - 0.22)))
    b2 = (cx + int(70 * math.cos(base_angle + 0.22)),
          cy + int(70 * math.sin(base_angle + 0.22)))
    draw.polygon([(tip_x, tip_y), b1, b2], fill=GOLD)

    # Makkah label — offset outside the ring along the arrow's direction
    kaaba = strings["kaaba"]
    klx = cx + int((sz // 2 + 60) * math.cos(qa))
    kly = cy + int((sz // 2 + 60) * math.sin(qa))
    ktw = draw.textlength(kaaba, font=f(FONT_BOLD, 46))
    draw.text((klx - ktw / 2, kly - 30), kaaba,
              font=f(FONT_BOLD, 46), fill=GOLD)

    # Distance row
    dist = strings["distance"]
    dist_y = cy + sz // 2 + 100
    tw = draw.textlength(dist, font=f(FONT_SRF, 62))
    draw.text(((W - tw) / 2, dist_y), dist, font=f(FONT_SRF, 62), fill=TEXT)

    # Calibrate hint
    center_text(draw, strings["calibrate"], dist_y + 110,
                f(FONT_REG, 38), TEXT_MUTED, max_width=W - 260)
    brand_footer(draw)
    return img


def screen_qaza(lang_code: str, strings: dict) -> Image.Image:
    img = Image.new("RGB", (W, H), BG_TOP)
    vertical_gradient(img, BG_TOP, BG_BOTTOM)
    draw = ImageDraw.Draw(img)

    y = 180
    y = center_text(draw, strings["cap3"], y, f(FONT_BOLD, 92), TEXT)

    # Streak / progress card
    px, py, pw = 90, 560, W - 180
    card(draw, px, py, pw, 340, radius=40)
    streak_lbl = strings["streak_label"]
    tw = draw.textlength(streak_lbl, font=f(FONT_REG, 40))
    draw.text((px + (pw - tw) / 2, py + 40), streak_lbl.upper(),
              font=f(FONT_REG, 40), fill=TEXT_MUTED)
    streak_val = strings["streak_value"]
    tw = draw.textlength(streak_val, font=f(FONT_SRF, 168))
    draw.text((px + (pw - tw) / 2, py + 110), streak_val,
              font=f(FONT_SRF, 168), fill=GOLD)

    # Progress bar
    bar_y = py + 320
    draw.rounded_rectangle([px + 60, bar_y, px + pw - 60, bar_y + 14],
                            radius=7, fill=(40, 50, 42))
    draw.rounded_rectangle([px + 60, bar_y,
                             px + 60 + int((pw - 120) * 0.62), bar_y + 14],
                            radius=7, fill=GOLD)

    # Per-prayer list
    lx, ly, lw = px, py + 400, pw
    rows = strings["qaza_rows"]
    card(draw, lx, ly, lw, 110 * len(rows) + 80, radius=36)
    row_h = 110
    for i, (name, progress) in enumerate(rows):
        ry = ly + 40 + i * row_h
        if i > 0:
            draw.line([(lx + 40, ry - 10), (lx + lw - 40, ry - 10)],
                      fill=(GOLD[0], GOLD[1], GOLD[2]), width=1)
        draw.text((lx + 60, ry + 30), name, font=f(FONT_REG, 44), fill=TEXT)
        tw = draw.textlength(progress, font=f(FONT_MONO, 40))
        draw.text((lx + lw - tw - 60, ry + 36), progress,
                  font=f(FONT_MONO, 40), fill=TEXT_MUTED)

    # CTA (mark 1 prayed)
    cta_y = ly + 110 * len(rows) + 130
    cta = strings["cta_mark"]
    draw.rounded_rectangle([px + 60, cta_y, px + pw - 60, cta_y + 120],
                            radius=60, fill=GOLD)
    tw = draw.textlength(cta, font=f(FONT_BOLD, 48))
    draw.text((px + (pw - tw) / 2, cta_y + 34), cta,
              font=f(FONT_BOLD, 48), fill=(10, 15, 12))

    # Gentle tagline to fill the bottom third
    tag_y = cta_y + 260
    center_text(draw, strings["qaza_tagline"], tag_y,
                f(FONT_SRF, 58), TEXT, max_width=W - 260)
    brand_footer(draw)
    return img


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


def screen_reminders(lang_code: str, strings: dict) -> Image.Image:
    img = Image.new("RGB", (W, H), BG_TOP)
    vertical_gradient(img, BG_TOP, BG_BOTTOM)
    draw = ImageDraw.Draw(img)

    y = 180
    y = center_text(draw, strings["cap4"], y, f(FONT_BOLD, 92), TEXT)

    # Hadith card (sized to content)
    px, py, pw = 100, 620, W - 200
    body_font = f(FONT_REG, 44)
    body_lines = wrap_lines(draw, strings["hadith_body"], body_font, pw - 120)
    card_h = 60 + 90 + 120 + len(body_lines) * 66 + 80 + 40
    card(draw, px, py, pw, card_h, radius=40)

    # ribbon
    ribbon = strings["hadith_label"]
    draw.text((px + 60, py + 50), ribbon.upper(),
              font=f(FONT_BOLD, 36), fill=GOLD)

    # Title
    draw.text((px + 60, py + 130),
              strings["hadith_title"], font=f(FONT_SRF, 76), fill=TEXT)

    # Body (center-aligned, wrapped)
    body_y = py + 250
    for ln in body_lines:
        tw = draw.textlength(ln, font=body_font)
        draw.text((px + (pw - tw) / 2, body_y), ln, font=body_font, fill=TEXT)
        body_y += 66

    # Source (muted, indented)
    draw.text((px + 60, body_y + 30),
              strings["hadith_source"], font=f(FONT_REG, 34),
              fill=TEXT_MUTED)

    # Chip row (categories)
    cy_chip = py + card_h + 50
    x = px
    for label, active in strings["chips"]:
        w_label = int(draw.textlength(label, font=f(FONT_REG, 38))) + 80
        draw.rounded_rectangle([x, cy_chip, x + w_label, cy_chip + 86],
                                radius=43,
                                fill=GOLD if active else (30, 40, 32),
                                outline=GOLD, width=2)
        draw.text((x + 40, cy_chip + 24), label,
                  font=f(FONT_REG, 38),
                  fill=(10, 15, 12) if active else TEXT)
        x += w_label + 20

    # Secondary reminder cards
    lx, ly = px, cy_chip + 160
    for i, item in enumerate(strings["more_reminders"]):
        card(draw, lx, ly + i * 210, pw, 180, radius=32)
        draw.text((lx + 60, ly + i * 210 + 40),
                  item["title"], font=f(FONT_BOLD, 48), fill=TEXT)
        draw.text((lx + 60, ly + i * 210 + 110),
                  item["body"], font=f(FONT_REG, 36), fill=TEXT_MUTED)

    # Tagline under the cards so there's no empty strip above the footer
    tag_y = ly + 210 * len(strings["more_reminders"]) + 60
    center_text(draw, strings["reminders_tagline"], tag_y,
                f(FONT_SRF, 52), TEXT, max_width=W - 260)
    brand_footer(draw)
    return img


def screen_privacy(lang_code: str, strings: dict) -> Image.Image:
    img = Image.new("RGB", (W, H), BG_TOP)
    vertical_gradient(img, BG_TOP, BG_BOTTOM)
    draw = ImageDraw.Draw(img)

    y = 180
    y = center_text(draw, strings["cap5"], y, f(FONT_BOLD, 92), TEXT)

    # Decorative lock circle
    cx, cy = W // 2, 1100
    r = 240
    draw.ellipse([cx - r, cy - r, cx + r, cy + r],
                 outline=GOLD, width=6)
    # Padlock glyph (drawn manually)
    # Body
    body_w, body_h = 220, 170
    draw.rounded_rectangle(
        [cx - body_w // 2, cy - body_h // 2 + 30,
         cx + body_w // 2, cy + body_h // 2 + 30],
        radius=18, fill=GOLD)
    # Shackle
    draw.arc([cx - 80, cy - 140, cx + 80, cy + 40],
             start=180, end=360, fill=GOLD, width=22)

    # Three principle rows
    principles = strings["principles"]
    ly = cy + r + 120
    for i, p in enumerate(principles):
        row_y = ly + i * 180
        # Check mark disc
        draw.ellipse([120, row_y, 200, row_y + 80],
                     outline=GOLD, width=3)
        draw.line([(140, row_y + 42), (160, row_y + 62)],
                  fill=GOLD, width=6)
        draw.line([(160, row_y + 62), (185, row_y + 28)],
                  fill=GOLD, width=6)
        draw.text((240, row_y + 12), p["title"],
                  font=f(FONT_BOLD, 48), fill=TEXT)
        draw.text((240, row_y + 72), p["body"],
                  font=f(FONT_REG, 36), fill=TEXT_MUTED)

    brand_footer(draw)
    return img


# ----------------------------- copy ---------------------------------------

COPY = {
    "en": {
        "cap1": "Your five prayers, exactly where you are.",
        "cap2": "Always facing Makkah.",
        "cap3": "Make up missed prayers, quietly.",
        "cap4": "A short reminder for every day.",
        "cap5": "Private by design. Nothing leaves your device.",
        # Prayer Times
        "hijri": "15 Shawwal 1447",
        "today": "Friday, 24 April 2026",
        "next": "Next prayer",
        "prayer_asr": "Asr",
        "remaining": "in 1 h 12 min",
        "prayers": [
            ("Fajr",    "04:52", False),
            ("Sunrise", "06:18", False),
            ("Dhuhr",   "12:41", False),
            ("Asr",     "16:24", True),
            ("Maghrib", "19:04", False),
            ("Isha",    "20:32", False),
        ],
        # Qibla
        "kaaba": "Makkah",
        "distance": "4,124 km to Makkah",
        "calibrate": "Move your phone in a figure-8 to calibrate the compass.",
        # Qaza
        "streak_label": "Streak",
        "streak_value": "12 days",
        "qaza_rows": [
            ("Fajr",    "18 / 30"),
            ("Dhuhr",   "22 / 30"),
            ("Asr",     "19 / 30"),
            ("Maghrib", "24 / 30"),
            ("Isha",    "21 / 30"),
        ],
        "cta_mark": "Mark 1 prayed",
        "qaza_tagline": "One prayer a day. No shame, no pressure.",
        "reminders_tagline": "Hundred hadiths. Azkar, morning and evening.",
        # Reminders
        "hadith_label": "Hadith of the day",
        "hadith_title": "The believer's affair",
        "hadith_body":  "How wonderful is the affair of the believer — his matter is all good, and that is for no one except the believer.",
        "hadith_source": "— Muslim",
        "chips": [("Hadith", True), ("Morning", False), ("Evening", False), ("After prayer", False)],
        "more_reminders": [
            {"title": "Morning azkar", "body": "Ayat al-Kursi · Three Quls · SubhanAllah ×100"},
            {"title": "After prayer",  "body": "Astaghfirullah ×3 · Tasbih 33/33/34"},
        ],
        # Privacy
        "principles": [
            {"title": "No account",   "body": "Sign in? Never. There's nothing to sign into."},
            {"title": "No servers",   "body": "Times, Qibla, and Qaza are all computed on device."},
            {"title": "No tracking",  "body": "Location is used once to calculate. Then it stays with you."},
        ],
    },
    "ru": {
        "cap1": "Пять намазов — именно для вас.",
        "cap2": "Всегда лицом к Мекке.",
        "cap3": "Возмещайте каза спокойно.",
        "cap4": "Короткое напоминание каждый день.",
        "cap5": "Приватно по умолчанию. Ничего не покидает устройство.",
        "hijri": "15 Шавваля 1447",
        "today": "Пятница, 24 апреля 2026",
        "next": "Следующий намаз",
        "prayer_asr": "Аср",
        "remaining": "через 1 ч 12 мин",
        "prayers": [
            ("Фаджр",   "04:52", False),
            ("Восход",  "06:18", False),
            ("Зухр",    "12:41", False),
            ("Аср",     "16:24", True),
            ("Магриб",  "19:04", False),
            ("Иша",     "20:32", False),
        ],
        "kaaba": "Мекка",
        "distance": "4 124 км до Мекки",
        "calibrate": "Поверните телефон восьмёркой, чтобы откалибровать компас.",
        "streak_label": "Подряд",
        "streak_value": "12 дней",
        "qaza_rows": [
            ("Фаджр",   "18 / 30"),
            ("Зухр",    "22 / 30"),
            ("Аср",     "19 / 30"),
            ("Магриб",  "24 / 30"),
            ("Иша",     "21 / 30"),
        ],
        "cta_mark": "Отметить 1 прочитан",
        "qaza_tagline": "Один намаз в день. Без стыда и без давления.",
        "reminders_tagline": "Сто хадисов. Азкары — утренние и вечерние.",
        "hadith_label": "Хадис дня",
        "hadith_title": "Положение верующего",
        "hadith_body":  "Удивительно положение верующего — всё для него благо, и так только у верующего.",
        "hadith_source": "— Муслим",
        "chips": [("Хадис", True), ("Утренние", False), ("Вечерние", False), ("После намаза", False)],
        "more_reminders": [
            {"title": "Утренние азкары", "body": "Аят аль-Курси · Три «Куль» · СубханАллах ×100"},
            {"title": "После намаза",    "body": "Астагфируллах ×3 · Тасбих 33/33/34"},
        ],
        "principles": [
            {"title": "Без аккаунта",  "body": "Регистрация? Никогда. Здесь некуда входить."},
            {"title": "Без серверов",  "body": "Время, кибла, каза — всё считается на устройстве."},
            {"title": "Без слежки",    "body": "Локация используется один раз. Затем остаётся с вами."},
        ],
    },
    "ky": {
        "cap1": "Беш убак намаз — сиз үчүн так.",
        "cap2": "Дайыма Меккеге карап.",
        "cap3": "Каза намаздарды тынч кайтарыңыз.",
        "cap4": "Күн сайын кыска эскертүү.",
        "cap5": "Купуялык — түпкү жөндөө. Эч нерсе чыкпайт.",
        "hijri": "15 Шаууал 1447",
        "today": "Жума, 24 апрель 2026",
        "next": "Кийинки намаз",
        "prayer_asr": "Аср",
        "remaining": "1 с 12 мүн кийин",
        "prayers": [
            ("Багымдат",  "04:52", False),
            ("Күн чыгуу", "06:18", False),
            ("Бешим",     "12:41", False),
            ("Аср",       "16:24", True),
            ("Шам",       "19:04", False),
            ("Куптан",    "20:32", False),
        ],
        "kaaba": "Мекке",
        "distance": "Меккеге чейин 4 124 км",
        "calibrate": "Компасты калибрлөө үчүн телефонду сегиздей жылдырыңыз.",
        "streak_label": "Удаа",
        "streak_value": "12 күн",
        "qaza_rows": [
            ("Багымдат", "18 / 30"),
            ("Бешим",    "22 / 30"),
            ("Аср",      "19 / 30"),
            ("Шам",      "24 / 30"),
            ("Куптан",   "21 / 30"),
        ],
        "cta_mark": "1 намаз окулду",
        "qaza_tagline": "Күнүнө бир намаз. Уят жок, басым жок.",
        "reminders_tagline": "Жүз хадис. Эртеңки жана кечки азкарлар.",
        "hadith_label": "Күндүн хадиси",
        "hadith_title": "Мусулмандын абалы",
        "hadith_body":  "Мусулмандын абалы таң калыштуу: ал үчүн баары жакшы, бул бир гана мусулманга таандык.",
        "hadith_source": "— Муслим",
        "chips": [("Хадис", True), ("Эртеңки", False), ("Кечки", False), ("Намаздан кийин", False)],
        "more_reminders": [
            {"title": "Эртеңки зикирлер", "body": "Аят аль-Курси · Үч «Куль» · СубханАллах ×100"},
            {"title": "Намаздан кийин",   "body": "Астагфируллах ×3 · Тасбих 33/33/34"},
        ],
        "principles": [
            {"title": "Аккаунт жок",  "body": "Каттоо? Эч качан. Кире турган жер жок."},
            {"title": "Сервер жок",   "body": "Убак, кыбыла, каза — бардыгы телефондо эсептелет."},
            {"title": "Көз салуу жок", "body": "Локация бир жолу гана колдонулат. Анан сизде калат."},
        ],
    },
}

SCREENS = [
    ("01-prayer-times", screen_prayer_times),
    ("02-qibla",        screen_qibla),
    ("03-qaza",         screen_qaza),
    ("04-reminders",    screen_reminders),
    ("05-privacy",      screen_privacy),
]


def main() -> None:
    out_root = Path(__file__).parent / "screenshots"
    for lang, strings in COPY.items():
        out_dir = out_root / lang
        out_dir.mkdir(parents=True, exist_ok=True)
        for slug, fn in SCREENS:
            img = fn(lang, strings)
            out_path = out_dir / f"{slug}.png"
            img.save(out_path, "PNG", optimize=True)
            print(f"  wrote {out_path.relative_to(out_root.parent)}")
    print("\nDone. Upload the 5 files per language to App Store Connect.")


if __name__ == "__main__":
    main()
